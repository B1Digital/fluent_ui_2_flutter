import 'dart:math' as math;

import 'js_math.dart';
import 'scale.dart';

/// An ordinal scale with a uniform band per domain entry
/// (`d3-scale/src/band.js:5-83`).
class ScaleBand implements Scale {
  /// Creates a band scale with an empty domain and the unit range.
  ScaleBand();

  final List<Object> _domain = <Object>[];
  final Map<Object, int> _index = <Object, int>{};
  List<double> _positions = <double>[];
  double _r0 = 0;
  // The unit range, as `d3-scale/src/band.js:8` initialises it.
  double _r1 = 1;
  double _step = 0;
  double _bandwidth = 0;
  bool _round = false;
  double _paddingInner = 0;
  double _paddingOuter = 0;
  // `d3-scale/src/band.js:11` centres the bands by default.
  double _align = 0.5;

  /// The inner padding, a fraction of [step].
  double get paddingInnerValue => _paddingInner;

  /// The outer padding, a fraction of [step]. Unlike the inner padding this is
  /// **not** clamped (`d3-scale/src/band.js:67`).
  double get paddingOuterValue => _paddingOuter;

  /// The alignment of the bands within the range, 0–1.
  double get alignValue => _align;

  /// Replaces the domain. Duplicates keep their first position, as d3's ordinal
  /// index map does.
  ScaleBand domainOf(List<Object> values) {
    _domain.clear();
    _index.clear();
    for (final value in values) {
      if (_index.containsKey(value)) {
        continue;
      }
      _index[value] = _domain.length;
      _domain.add(value);
    }
    return _rescale();
  }

  /// Replaces the range.
  ScaleBand rangeOf(List<double> values) {
    _r0 = values.first;
    _r1 = values.last;
    return _rescale();
  }

  /// Sets the inner padding, clamped to at most 1 (`d3-scale/src/band.js:63`).
  ScaleBand paddingInner(double p) {
    // The clamp is upstream's `Math.min(1, _)`; a fraction above 1 would give a
    // negative bandwidth.
    _paddingInner = math.min(1, p);
    return _rescale();
  }

  /// Sets the outer padding, unclamped (`d3-scale/src/band.js:67`).
  ScaleBand paddingOuter(double p) {
    _paddingOuter = p;
    return _rescale();
  }

  /// Sets **both** paddings (`d3-scale/src/band.js:59`).
  ///
  /// The inner is `min(1, p)` and the outer is the raw `p`, so
  /// `padding(1.4)` leaves them at 1 and 1.4 respectively. Reading this as
  /// "one padding" is the standard misreading.
  ScaleBand padding(double p) {
    _paddingOuter = p;
    _paddingInner = math.min(1, p);
    return _rescale();
  }

  /// Sets the alignment, clamped to 0–1 (`d3-scale/src/band.js:71`).
  ScaleBand align(double a) {
    // Upstream's `Math.max(0, Math.min(1, _))`: an alignment is a fraction of
    // the leftover range, so anything outside 0–1 would push bands out of it.
    _align = math.max(0, math.min(1, a));
    return _rescale();
  }

  /// Rounds the step and bandwidth to integers
  /// (`d3-scale/src/band.js:26,29`). The charts never set it; kept for parity.
  // ignore: avoid_positional_boolean_parameters
  ScaleBand round(bool value) {
    _round = value;
    return _rescale();
  }

  ScaleBand _rescale() {
    // band.js:20-32.
    final n = _domain.length;
    final reverse = _r1 < _r0;
    var start = reverse ? _r1 : _r0;
    final stop = reverse ? _r0 : _r1;
    // band.js:25. The `max(1, …)` guards a single-entry domain with padding
    // large enough to make the divisor zero or negative.
    _step = (stop - start) / math.max(1, n - _paddingInner + _paddingOuter * 2);
    if (_round) {
      _step = _step.floorToDouble();
    }
    start += (stop - start - _step * (n - _paddingInner)) * _align;
    // band.js:28. The inner padding is the fraction of the step left blank.
    _bandwidth = _step * (1 - _paddingInner);
    if (_round) {
      start = jsRound(start);
      _bandwidth = jsRound(_bandwidth);
    }
    final values = List<double>.generate(
      n,
      // `start + step * i`, not a running sum: upstream's `range(n).map` does
      // the multiplication, and a running sum accumulates a different error.
      (int i) => start + _step * i,
      growable: false,
    );
    _positions = reverse ? values.reversed.toList(growable: false) : values;
    return this;
  }

  @override
  double? call(Object value) {
    final i = _index[value];
    // d3's ordinal scale grows an implicit domain on a miss. This port returns
    // null instead: a chart that silently reflows because one category was
    // mistyped is harder to debug than a null.
    // ponytail: no implicit domain growth.
    return i == null ? null : _positions[i];
  }

  @override
  List<Object> get domain => List<Object>.of(_domain);

  @override
  List<double> get range => <double>[_r0, _r1];

  @override
  double get bandwidth => _bandwidth;

  @override
  double get step => _step;

  @override
  Object? invert(double pixel) => null;

  @override
  List<Object> ticks([int? count]) => domain;

  @override
  String Function(Object value) tickFormat([int? count, String? specifier]) =>
      (Object value) => '$value';
}

/// A new [ScaleBand] (`d3-scale/src/band.js:5`).
ScaleBand scaleBand() => ScaleBand();
