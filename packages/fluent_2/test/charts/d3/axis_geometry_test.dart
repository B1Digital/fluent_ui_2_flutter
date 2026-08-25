import 'dart:math' as math;

import 'package:fluent_2/src/charts/internal/d3/axis_geometry.dart';
import 'package:fluent_2/src/charts/internal/d3/scale.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_support.dart';

/// A continuous scale stub.
///
/// The plan's Step 1 test imported `scale_linear.dart` and `scale_band.dart`.
/// Neither is this task's file, `scale_linear.dart` does not exist yet, and
/// `FluentAxisGeometry` depends on nothing but the [Scale] interface — so the
/// unit is exercised through stubs, the pattern `scale_test.dart` already
/// establishes. The band positions are not invented: they are read from the
/// `scaleBand` section of the d3 corpus below.
class _Linear implements Scale {
  _Linear(this._domain, this._range);

  final List<double> _domain;
  final List<double> _range;

  @override
  double? call(Object value) {
    if (value is! num) {
      // `d3-scale/src/continuous.js:86` — a non-numeric input is undefined.
      return null;
    }
    final t =
        (value.toDouble() - _domain.first) / (_domain.last - _domain.first);
    return _range.first + t * (_range.last - _range.first);
  }

  @override
  List<Object> get domain => _domain;

  @override
  List<double> get range => _range;

  @override
  double get bandwidth => 0;

  @override
  double get step => _range.last - _range.first;

  @override
  Object? invert(double pixel) => null;

  @override
  List<Object> ticks([int? count]) => _domain;

  @override
  String Function(Object value) tickFormat([int? count, String? specifier]) =>
      (Object value) => '$value';
}

/// A band scale stub, built from one `scaleBand` corpus case.
class _Band implements Scale {
  _Band({
    required this.domain,
    required this.range,
    required this.at,
    required this.bandwidth,
    required this.step,
  });

  /// Builds a stub from a corpus case's `domain`, `range`, `atInputs`/`at`,
  /// `bandwidth` and `step`.
  factory _Band.fromGolden(Map<String, dynamic> testCase) {
    final inputs = (testCase['atInputs']! as List<Object?>).cast<Object>();
    final outputs = jsNums(testCase['at']);
    return _Band(
      domain: (testCase['domain']! as List<Object?>).cast<Object>(),
      range: jsNums(testCase['range']).cast<double>(),
      at: <Object, double?>{
        for (var i = 0; i < inputs.length; i++) inputs[i]: outputs[i],
      },
      bandwidth: jsNum(testCase['bandwidth'])!,
      step: jsNum(testCase['step'])!,
    );
  }

  /// The corpus case's `at` map, keyed by `atInputs`.
  final Map<Object, double?> at;

  @override
  final List<Object> domain;

  @override
  final List<double> range;

  @override
  final double bandwidth;

  @override
  final double step;

  @override
  double? call(Object value) => at[value];

  @override
  Object? invert(double pixel) => null;

  @override
  List<Object> ticks([int? count]) => domain;

  @override
  String Function(Object value) tickFormat([int? count, String? specifier]) =>
      (Object value) => '$value';
}

void main() {
  test('the defaults are 6 / 6 / 3', () {
    final geometry = FluentAxisGeometry(
      orientation: FluentAxisOrientation.bottom,
      scale: _Linear(<double>[0, 1], <double>[0, 100]),
      tickValues: const <Object>[0, 1],
      tickLabels: const <String>['0', '1'],
      offset: 0.5,
    );
    expect(geometry.tickSizeInner, 6.0, reason: 'd3-axis/src/axis.js:35');
    expect(geometry.tickSizeOuter, 6.0, reason: 'axis.js:36');
    expect(geometry.tickPadding, 3.0, reason: 'axis.js:37');
    expect(
      geometry.spacing,
      9.0,
      reason: 'axis.js:46, max(inner, 0) + padding',
    );
  });

  test('spacing floors a negative inner tick size at zero', () {
    final geometry = FluentAxisGeometry(
      orientation: FluentAxisOrientation.bottom,
      scale: _Linear(<double>[0, 1], <double>[0, 100]),
      tickValues: const <Object>[],
      tickLabels: const <String>[],
      offset: 0.5,
      tickSizeInner: -10,
    );
    expect(
      geometry.spacing,
      3.0,
      reason:
          'axis.js:46 is Math.max(tickSizeInner, 0) + tickPadding, so an '
          'inward tick drawn outward still leaves the label 3px clear',
    );
  });

  test('k is -1 for top and left, +1 for right and bottom', () {
    FluentAxisGeometry at(FluentAxisOrientation o) => FluentAxisGeometry(
      orientation: o,
      scale: _Linear(<double>[0, 1], <double>[0, 100]),
      tickValues: const <Object>[],
      tickLabels: const <String>[],
      offset: 0.5,
    );
    expect(at(FluentAxisOrientation.top).k, -1, reason: 'axis.js:39');
    expect(at(FluentAxisOrientation.left).k, -1, reason: 'axis.js:39');
    expect(at(FluentAxisOrientation.right).k, 1, reason: 'axis.js:39');
    expect(at(FluentAxisOrientation.bottom).k, 1, reason: 'axis.js:39');
  });

  test('the tick transform adds offset ONCE, not half of it', () {
    final geometry = FluentAxisGeometry(
      orientation: FluentAxisOrientation.bottom,
      scale: _Linear(<double>[0, 100], <double>[0, 100]),
      tickValues: const <Object>[50],
      tickLabels: const <String>['50'],
      offset: 0.5,
    );
    expect(
      geometry.ticks.single.position,
      50.5,
      reason:
          'd3-axis/src/axis.js:98 is transform(position(d) + offset). The '
          'cartesian recon wrote 0.5 * offset, which is a quarter-pixel error '
          'on every tick at 1x DPR — design spec §5.5',
    );
    expect(
      geometry.positionOf('not a number'),
      isNaN,
      reason:
          'axis.js:18 is `+scale(d)`, and JavaScript coerces undefined to NaN '
          'rather than throwing',
    );
  });

  test('band centring is max(0, bandwidth - 2 * offset) / 2', () async {
    final cases = goldenCases(await loadD3Golden(), 'scaleBand');
    expect(
      cases,
      isNotEmpty,
      reason: 'the scaleBand section supplies the real d3 band positions',
    );
    var checked = 0;
    for (final testCase in cases) {
      if (testCase['at'] == null) {
        // The last case records only padding, bandwidth and step — it has no
        // `at`/`atInputs` pair to build a stub from.
        continue;
      }
      checked++;
      final band = _Band.fromGolden(testCase);
      final first = band.domain.first;
      final start = band(first)!;

      final crisp = FluentAxisGeometry(
        orientation: FluentAxisOrientation.bottom,
        scale: band,
        tickValues: <Object>[first],
        tickLabels: const <String>['a'],
        offset: 0.5,
      );
      expect(
        crisp.positionOf(first),
        start + math.max(0.0, band.bandwidth - 2 * 0.5) / 2,
        reason:
            'd3-axis/src/axis.js:22 — NOT bandwidth / 2; the recon\'s '
            '"= scale(d) + bandwidth/2" annotation is wrong even though its '
            'formula was right. Domain ${band.domain}, bandwidth '
            '${band.bandwidth}',
      );

      final exact = FluentAxisGeometry(
        orientation: FluentAxisOrientation.bottom,
        scale: band,
        tickValues: <Object>[first],
        tickLabels: const <String>['a'],
        offset: 0,
      );
      expect(
        exact.positionOf(first),
        start + band.bandwidth / 2,
        reason:
            'axis.js:22 collapses to scale(d) + bandwidth / 2 only at '
            'offset == 0, which is the devicePixelRatio > 1 branch of '
            'axis.js:38',
      );
      if (band.bandwidth > 1) {
        expect(
          crisp.positionOf(first),
          isNot(exact.positionOf(first)),
          reason: 'the two agree only when offset == 0',
        );
      }
    }
    expect(
      checked,
      6,
      reason:
          'six of the seven scaleBand cases carry positions, and one of those '
          'has bandwidth 0 — which is why the expectation above needs the '
          'max(0, ...) clamp of axis.js:22 rather than a bare subtraction',
    );
  });

  test('the first scaleBand corpus case centres at 49.5, not 50', () async {
    final band = _Band.fromGolden(
      goldenCases(await loadD3Golden(), 'scaleBand').first,
    );
    expect(
      band.bandwidth,
      100.0,
      reason: 'corpus scaleBand[0]: domain a/b/c over range 0..300, no padding',
    );
    final geometry = FluentAxisGeometry(
      orientation: FluentAxisOrientation.bottom,
      scale: band,
      tickValues: <Object>['a'],
      tickLabels: const <String>['a'],
      offset: 0.5,
    );
    expect(
      geometry.positionOf('a'),
      49.5,
      reason:
          'max(0, 100 - 2 * 0.5) / 2 = 49.5. Hand-computed from axis.js:22 so '
          'the assertion is not a restatement of the implementation',
    );
    expect(
      geometry.ticks.single.position,
      50.0,
      reason: 'axis.js:98 then adds the offset once: 49.5 + 0.5',
    );
  });

  test('a bandwidth narrower than 2 * offset clamps at zero', () {
    // Three bands over two pixels: bandwidth 2 / 3, narrower than 2 * 0.5.
    final band = _Band(
      domain: <Object>['a', 'b', 'c'],
      range: <double>[0, 2],
      at: <Object, double?>{'a': 0, 'b': 2 / 3, 'c': 4 / 3},
      bandwidth: 2 / 3,
      step: 2 / 3,
    );
    final geometry = FluentAxisGeometry(
      orientation: FluentAxisOrientation.bottom,
      scale: band,
      tickValues: const <Object>['a'],
      tickLabels: const <String>['a'],
      offset: 0.5,
    );
    expect(
      geometry.positionOf('a'),
      band('a'),
      reason: 'axis.js:22 wraps the subtraction in Math.max(0, ...)',
    );
  });

  test('a band-domain miss is NaN, not null', () {
    final band = _Band(
      domain: <Object>['a'],
      range: <double>[0, 10],
      at: <Object, double?>{'a': 0},
      bandwidth: 10,
      step: 10,
    );
    final geometry = FluentAxisGeometry(
      orientation: FluentAxisOrientation.bottom,
      scale: band,
      tickValues: const <Object>['zzz'],
      tickLabels: const <String>['zzz'],
      offset: 0.5,
    );
    expect(
      geometry.positionOf('zzz'),
      isNaN,
      reason:
          'axis.js:24 is `+scale(d) + offset`; a scale.dart null becomes NaN '
          'so a caller filters on isFinite the way axis.js:82 does',
    );
  });

  test('the baseline dy and text anchor per orientation', () {
    FluentAxisTickGeometry tick(FluentAxisOrientation o) => FluentAxisGeometry(
      orientation: o,
      scale: _Linear(<double>[0, 1], <double>[0, 100]),
      tickValues: const <Object>[0],
      tickLabels: const <String>['0'],
      offset: 0.5,
    ).ticks.single;
    expect(
      tick(FluentAxisOrientation.bottom).baselineDyEm,
      0.71,
      reason: 'd3-axis/src/axis.js:72',
    );
    expect(
      tick(FluentAxisOrientation.left).baselineDyEm,
      0.32,
      reason: 'axis.js:72',
    );
    expect(
      tick(FluentAxisOrientation.right).baselineDyEm,
      0.32,
      reason: 'axis.js:72 — right shares the side value with left',
    );
    expect(
      tick(FluentAxisOrientation.top).baselineDyEm,
      0.0,
      reason: 'axis.js:72, "0em"',
    );
    expect(
      tick(FluentAxisOrientation.left).textAlign,
      FluentAxisTextAnchor.end,
      reason: 'axis.js:111',
    );
    expect(
      tick(FluentAxisOrientation.right).textAlign,
      FluentAxisTextAnchor.start,
      reason: 'axis.js:111',
    );
    expect(
      tick(FluentAxisOrientation.bottom).textAlign,
      FluentAxisTextAnchor.middle,
      reason: 'axis.js:111',
    );
    expect(
      tick(FluentAxisOrientation.top).textAlign,
      FluentAxisTextAnchor.middle,
      reason: 'axis.js:111 — only right and left are special-cased',
    );
  });

  test('the tick mark and label run along y below and along x at the side', () {
    final scale = _Linear(<double>[0, 100], <double>[0, 100]);
    final bottom = FluentAxisGeometry(
      orientation: FluentAxisOrientation.bottom,
      scale: scale,
      tickValues: const <Object>[50],
      tickLabels: const <String>['50'],
      offset: 0.5,
    ).ticks.single;
    expect(
      <Offset>[bottom.lineStart, bottom.lineEnd, bottom.labelAnchor],
      <Offset>[
        const Offset(50.5, 0),
        const Offset(50.5, 6),
        const Offset(50.5, 9),
      ],
      reason:
          'axis.js:41 picks translateX for top and bottom, and axis.js:40 '
          'makes the varying attribute "y", so the mark is k * 6 down and the '
          'label anchor k * spacing down',
    );

    final left = FluentAxisGeometry(
      orientation: FluentAxisOrientation.left,
      scale: scale,
      tickValues: const <Object>[50],
      tickLabels: const <String>['50'],
      offset: 0.5,
    ).ticks.single;
    expect(
      <Offset>[left.lineStart, left.lineEnd, left.labelAnchor],
      <Offset>[
        const Offset(0, 50.5),
        const Offset(-6, 50.5),
        const Offset(-9, 50.5),
      ],
      reason:
          'axis.js:40-41 swap both axes for left and right, and k is -1 at '
          'axis.js:39',
    );
  });

  test('a tick with no matching label falls back to the empty string', () {
    final geometry = FluentAxisGeometry(
      orientation: FluentAxisOrientation.bottom,
      scale: _Linear(<double>[0, 100], <double>[0, 100]),
      tickValues: const <Object>[0, 50],
      tickLabels: const <String>['0'],
      offset: 0.5,
    );
    expect(
      geometry.ticks.map((FluentAxisTickGeometry t) => t.label),
      <String>['0', ''],
      reason:
          'tickLabels is parallel to tickValues; a short list must not throw '
          'mid-paint',
    );
  });

  test('the domain path carries the offset at both ends', () {
    final geometry = FluentAxisGeometry(
      orientation: FluentAxisOrientation.bottom,
      scale: _Linear(<double>[0, 1], <double>[64, 680]),
      tickValues: const <Object>[],
      tickLabels: const <String>[],
      offset: 0.5,
    );
    expect(
      geometry.domainPath.first.dx,
      64.5,
      reason:
          'd3-axis/src/axis.js:48 — range0 = range[0] + offset. The live '
          'AreaChart basic story renders M64.5,6V0.5H680.5V6, which is this '
          'number (design spec §4.3)',
    );
    expect(geometry.domainPath.last.dx, 680.5, reason: 'axis.js:49');
    expect(
      geometry.domainPath,
      <Offset>[
        const Offset(64.5, 6),
        const Offset(64.5, 0.5),
        const Offset(680.5, 0.5),
        const Offset(680.5, 6),
      ],
      reason:
          'axis.js:94 for a bottom axis is '
          'M range0,k*outer V offset H range1 V k*outer — the whole of '
          'M64.5,6V0.5H680.5V6',
    );
  });

  test('the domain path transposes for a left axis', () {
    final geometry = FluentAxisGeometry(
      orientation: FluentAxisOrientation.left,
      scale: _Linear(<double>[0, 1], <double>[300, 0]),
      tickValues: const <Object>[],
      tickLabels: const <String>[],
      offset: 0.5,
    );
    expect(
      geometry.domainPath,
      <Offset>[
        const Offset(-6, 300.5),
        const Offset(0.5, 300.5),
        const Offset(0.5, 0.5),
        const Offset(-6, 0.5),
      ],
      reason:
          'axis.js:93 — M k*outer,range0 H offset V range1 H k*outer, with '
          'k == -1 from axis.js:39 and the inverted range a value axis uses',
    );
  });
}
