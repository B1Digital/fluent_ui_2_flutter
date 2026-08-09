import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:fluent_2_web/src/charts/axis/axis_builders.dart';
import 'package:fluent_2_web/src/charts/axis/axis_types.dart';
import 'package:fluent_2_web/src/charts/internal/d3/axis_geometry.dart' as d3;
import 'package:fluent_2_web/src/charts/model/chart_common.dart';
import 'package:flutter_test/flutter_test.dart';

const _margins = FluentChartMargins(left: 40, right: 20, top: 20, bottom: 35);

/// The agreed geometry tolerance for Oracle B, in logical pixels.
///
/// `kOracleGeometryTolerance` from `test/support/oracle_fixture.dart`, restated
/// here because that shared loader is not on disk yet.
const double _oracleTolerance = 0.01;

FluentXAxisParams _numericParams({
  double dStart = 0,
  double dEnd = 100,
  bool hideTickOverlap = false,
  double Function(List<String>)? calcMaxLabelWidth,
  int? xAxisCount,
  bool showRoundOff = true,
}) {
  return FluentXAxisParams(
    domainNRangeValues: FluentChartDomainRange(
      dStartValue: dStart,
      dEndValue: dEnd,
      rStartValue: 40,
      rEndValue: 680,
    ),
    containerHeight: 300,
    containerWidth: 700,
    margins: _margins,
    showRoundOffXTickValues: showRoundOff,
    hideTickOverlap: hideTickOverlap,
    calcMaxLabelWidth: calcMaxLabelWidth,
    xAxisCount: xAxisCount,
  );
}

/// Reads one Oracle B story fixture.
///
/// `test/support/oracle_fixture.dart` does not exist on disk yet, so this walks
/// up from [Directory.current] to the corpus exactly as
/// `test/charts/axis/tick_values_test.dart` does, and should be replaced by the
/// shared loader once that lands.
Map<String, dynamic> _loadOracleStory(String id) {
  const relative = 'test/fixtures/charts/oracle_b';
  var directory = Directory.current;
  while (true) {
    final candidate = File('${directory.path}/$relative/$id.json');
    if (candidate.existsSync()) {
      return jsonDecode(candidate.readAsStringSync()) as Map<String, dynamic>;
    }
    final parent = directory.parent;
    // Reaching the filesystem root leaves parent == directory.
    if (parent.path == directory.path) {
      throw StateError(
        'No $relative/$id.json found in ${Directory.current.path} or any '
        'ancestor.',
      );
    }
    directory = parent;
  }
}

List<Map<String, dynamic>> _elements(Map<String, dynamic> story) =>
    (((story['svgs'] as List<dynamic>).first
                as Map<String, dynamic>)['elements']
            as List<dynamic>)
        .cast<Map<String, dynamic>>();

/// Every number in an SVG `transform` or path attribute, in source order.
List<double> _numbers(String source) => RegExp(r'-?\d+(?:\.\d+)?')
    .allMatches(source)
    .map((match) => double.parse(match.group(0)!))
    .toList(growable: false);

/// The first number in an SVG `transform` or path-like attribute.
double _firstNumber(String source) {
  final all = _numbers(source);
  if (all.isEmpty) {
    throw StateError('No number in "$source".');
  }
  return all.first;
}

/// One captured axis: the group's own `transform`, its domain path and its
/// per-tick groups.
///
/// The bottom axis is the one root group `d3AxisBottom` emits — middle-anchored
/// text (`d3-axis/src/axis.js:111`) inside a group the shell translates down the
/// plot height (`CartesianChart.tsx` renders it at `translate(0, y)`).
class _CapturedAxis {
  _CapturedAxis(this.story) {
    final elements = _elements(story);
    final root = elements.firstWhere(
      (element) =>
          element['parent'] == -1 &&
          element['tag'] == 'g' &&
          element['textAnchor'] == 'middle' &&
          (element['transform'] as String?)?.startsWith('translate(0,') == true,
    );
    domainPath =
        elements.firstWhere(
              (element) =>
                  element['parent'] == root['index'] &&
                  element['tag'] == 'path',
            )['d']
            as String;
    for (final group in elements.where(
      (element) => element['parent'] == root['index'] && element['tag'] == 'g',
    )) {
      final children = elements.where(
        (element) => element['parent'] == group['index'],
      );
      tickOffsets.add(_firstNumber(group['transform'] as String));
      tickLabels.add(
        children.firstWhere((child) => child['tag'] == 'text')['text']
            as String,
      );
      tickLabelOffsets.add(
        (children.firstWhere((child) => child['tag'] == 'text')['y'] as num)
            .toDouble(),
      );
      tickLineLengths.add(
        (children.firstWhere((child) => child['tag'] == 'line')['y2'] as num)
            .toDouble(),
      );
    }
  }

  final Map<String, dynamic> story;
  late final String domainPath;
  final List<double> tickOffsets = <double>[];
  final List<String> tickLabels = <String>[];
  final List<double> tickLabelOffsets = <double>[];
  final List<double> tickLineLengths = <double>[];
}

void main() {
  group('createNumericXAxis', () {
    test('produces d3 ticks at the default count of six', () {
      final spec = createNumericXAxis(
        _numericParams(),
        const FluentTickParams(),
        FluentChartType.lineChart,
      );
      expect(
        spec.tickValues,
        <double>[0, 20, 40, 60, 80, 100],
        reason:
            'utilities.ts:285 defaults the count to 6, and d3 ticks(0,100,6) '
            'steps by 20.',
      );
      expect(
        spec.tickLabels,
        <String>['0', '20', '40', '60', '80', '100'],
        reason: 'utilities.ts:294 formats through formatToLocaleString.',
      );
      expect(
        spec.orientation,
        d3.FluentAxisOrientation.bottom,
        reason: 'utilities.ts:303 uses d3AxisBottom.',
      );
      expect(
        spec.tickSizeInner,
        6,
        reason: 'utilities.ts:266 — xAxistickSize 6.',
      );
      expect(
        spec.tickSizeOuter,
        6,
        reason: "d3-axis's own default outer size.",
      );
      expect(
        spec.tickPadding,
        10,
        reason: 'utilities.ts:267 — tickPadding 10.',
      );
    });

    test('widens the domain with a user minimum but never narrows it', () {
      final spec = createNumericXAxis(
        const FluentXAxisParams(
          domainNRangeValues: FluentChartDomainRange(
            dStartValue: 0,
            dEndValue: 100,
            rStartValue: 40,
            rEndValue: 680,
          ),
          containerHeight: 300,
          containerWidth: 700,
          margins: _margins,
          xMinValue: 50,
        ),
        const FluentTickParams(),
        FluentChartType.lineChart,
      );
      expect(
        spec.scale.domain.first,
        0,
        reason:
            'utilities.ts:278 uses Math.min, so a user minimum above the data '
            'minimum is ignored.',
      );
    });

    test('draws full-height gridlines for HorizontalBarChartWithAxis', () {
      final spec = createNumericXAxis(
        _numericParams(),
        const FluentTickParams(),
        FluentChartType.horizontalBarChartWithAxis,
      );
      expect(
        spec.tickSizeInner,
        -280,
        reason:
            'utilities.ts:308-310 — -(containerHeight 300 - margins.top 20). A '
            'negative inner size is a gridline.',
      );
    });

    test('leaves a line chart without gridlines on the x axis', () {
      final spec = createNumericXAxis(
        _numericParams(),
        const FluentTickParams(),
        FluentChartType.lineChart,
      );
      expect(
        spec.tickSizeInner,
        6,
        reason: 'only HBWA and Gantt take the override at utilities.ts:308.',
      );
    });

    test('reduces the tick count when hideTickOverlap is on', () {
      final spec = createNumericXAxis(
        _numericParams(
          hideTickOverlap: true,
          // 200px per label plus the +20 pad gives 220px, and the 640px range
          // therefore admits floor(640 / 220) == 2 ticks.
          calcMaxLabelWidth: (labels) => 200,
        ),
        const FluentTickParams(),
        FluentChartType.lineChart,
      );
      expect(
        spec.tickValues.length,
        lessThanOrEqualTo(kHideTickOverlapMaxTicks),
        reason: 'utilities.ts:300 clamps the reduced count to 10.',
      );
      expect(
        spec.tickValues,
        <double>[0, 50, 100],
        reason:
            'd3 ticks(0,100,2) steps by 50 — tickIncrement(0,100,2) is 50 '
            'because the error 5 clears e5 (d3-array/src/ticks.js:36).',
      );
    });

    test('clamps the reduced tick count to ten', () {
      final spec = createNumericXAxis(
        _numericParams(
          hideTickOverlap: true,
          // A zero-width label leaves only the +20 pad, so floor(640 / 20) is
          // 32 and the clamp is what keeps the axis readable.
          calcMaxLabelWidth: (labels) => 0,
        ),
        const FluentTickParams(),
        FluentChartType.lineChart,
      );
      expect(
        spec.tickValues.length,
        11,
        reason:
            'utilities.ts:300 clamps the count to 10, and d3 ticks(0,100,10) '
            'steps by 10 for 11 values; the unclamped 32 would have stepped by '
            '2 for 51.',
      );
    });

    test('honours explicit tick values and their text overrides', () {
      final spec = createNumericXAxis(
        const FluentXAxisParams(
          domainNRangeValues: FluentChartDomainRange(
            dStartValue: 0,
            dEndValue: 100,
            rStartValue: 40,
            rEndValue: 680,
          ),
          containerHeight: 300,
          containerWidth: 700,
          margins: _margins,
          tickText: <String>['low', 'high'],
        ),
        const FluentTickParams(tickValues: <Object>[0, 100]),
        FluentChartType.lineChart,
      );
      expect(
        spec.tickValues,
        <Object>[0, 100],
        reason: 'utilities.ts:312-313 — tickParams.tickValues wins.',
      );
      expect(
        spec.tickLabels,
        <String>['low', 'high'],
        reason: 'utilities.ts:287-289 — tickText is indexed positionally.',
      );
    });

    test('generates stepped ticks when tickStep is set', () {
      final spec = createNumericXAxis(
        const FluentXAxisParams(
          domainNRangeValues: FluentChartDomainRange(
            dStartValue: 0,
            dEndValue: 100,
            rStartValue: 40,
            rEndValue: 680,
          ),
          containerHeight: 300,
          containerWidth: 700,
          margins: _margins,
          tickStep: 50,
          tick0: 0,
        ),
        const FluentTickParams(),
        FluentChartType.lineChart,
      );
      expect(
        spec.tickValues,
        <double>[0, 50, 100],
        reason: 'utilities.ts:314-316 routes tickStep to generateNumericTicks.',
      );
    });

    test('applies a d3 format specifier from tickParams', () {
      final spec = createNumericXAxis(
        _numericParams(xAxisCount: 2),
        const FluentTickParams(tickFormat: '.1f'),
        FluentChartType.lineChart,
      );
      expect(
        spec.tickLabels.first,
        '0.0',
        reason: "utilities.ts:290-292 runs the value through d3Format('.1f').",
      );
    });
  });

  group('createNumericXAxis against Oracle B', () {
    // HorizontalBarChartWithAxis is the one captured component whose numeric
    // axis is the *x* axis, so it is the only fixture `createNumericXAxis` can
    // be held against. Its capture also exercises the gridline branch at
    // utilities.ts:308-310, the domain path and the label offset in one go.
    const storyId =
        'charts-horizontalbarchartwithaxis--horizontal-bar-with-axis-basic';
    final story = _loadOracleStory(storyId);
    final captured = _CapturedAxis(story);

    // The captured domain path is 'M40.5,6V0.5H630.5V6': the two verticals are
    // the tickSizeOuter 6 end caps and the horizontal runs the range, offset by
    // the crispness half-pixel the capture records as crispOffset.
    final crispOffset = (story['crispOffset'] as num).toDouble();
    // 40 and 630 are the range read back off that path.
    const rStart = 40.0;
    const rEnd = 630.0;

    FluentAxisSpec buildSpec() => createNumericXAxis(
      const FluentXAxisParams(
        // The domain endpoints the captured first and last labels imply; the
        // tick *positions* below are what actually holds this to the capture.
        domainNRangeValues: FluentChartDomainRange(
          dStartValue: 0,
          dEndValue: 40000,
          rStartValue: rStart,
          rEndValue: rEnd,
        ),
        // 310 is the captured SVG height and 20 is DEFAULT_MARGIN_NO_TICKS
        // (`CartesianChart.tsx:42`), the top margin of a chart with no x-axis
        // title.
        containerHeight: 310,
        containerWidth: 650,
        margins: FluentChartMargins(left: 40, right: 20, top: 20, bottom: 35),
        // CartesianChart.tsx:212 passes `?? true`.
        showRoundOffXTickValues: true,
      ),
      const FluentTickParams(),
      FluentChartType.horizontalBarChartWithAxis,
    );

    test('the corpus fixture still carries a nine-tick numeric x axis', () {
      // Guard against a renamed or re-captured story quietly emptying every
      // assertion below.
      expect(
        captured.tickOffsets.length,
        9,
        reason:
            '$storyId captured nine x ticks; a different count means the '
            'fixture changed and the expectations here are stale.',
      );
      expect(
        story['deviceScaleFactor'],
        1,
        reason:
            'the geometry below only agrees with flutter test at scale 1, where '
            'the crispness offset is 0.5.',
      );
    });

    test('reproduces the captured tick values and labels', () {
      final spec = buildSpec();
      expect(
        spec.tickValues,
        <double>[0, 5000, 10000, 15000, 20000, 25000, 30000, 35000, 40000],
        reason:
            'd3 ticks(0,40000,6) steps by 5000, which is what the capture shows.',
      );
      expect(
        spec.tickLabels,
        captured.tickLabels,
        reason:
            'formatToLocaleString groups only from 10000 up '
            '(`chart-utilities/formatter.ts:40`), which is why the capture reads '
            "'5000' but '10,000'.",
      );
    });

    test('reproduces the captured tick positions', () {
      final spec = buildSpec();
      for (var i = 0; i < spec.tickValues.length; i++) {
        expect(
          spec.scale(spec.tickValues[i])! + crispOffset,
          closeTo(captured.tickOffsets[i], _oracleTolerance),
          reason:
              'axis_geometry adds the crispness offset once to '
              'position(d) (`d3-axis/src/axis.js:76`), so tick $i must land on '
              'the captured translate.',
        );
      }
    });

    test('reproduces the captured gridline length and label offset', () {
      final spec = buildSpec();
      expect(
        spec.tickSizeInner,
        -290,
        reason:
            'utilities.ts:308-310 — -(310 - 20), which is the captured line y2.',
      );
      expect(
        captured.tickLineLengths,
        everyElement(closeTo(spec.tickSizeInner, _oracleTolerance)),
        reason: 'every captured gridline is that same length.',
      );
      expect(
        math.max(spec.tickSizeInner, 0.0) + spec.tickPadding,
        closeTo(captured.tickLabelOffsets.first, _oracleTolerance),
        reason:
            'd3-axis/src/axis.js:46 — a negative inner size contributes nothing '
            'to the label spacing, so the captured text y is the tickPadding '
            'alone.',
      );
    });

    test('reproduces the captured domain path end caps', () {
      final spec = buildSpec();
      // 'M40.5,6V0.5H630.5V6' in the order the numbers appear: the start cap's
      // x and its tickSizeOuter, the crisp y of the spine, the end cap's x and
      // its tickSizeOuter again. Compared as numbers because the same path
      // written from Dart doubles reads '6.0'.
      expect(
        _numbers(captured.domainPath),
        <double>[
          rStart + crispOffset,
          spec.tickSizeOuter,
          crispOffset,
          rEnd + crispOffset,
          spec.tickSizeOuter,
        ],
        reason:
            'd3-axis/src/axis.js:88 draws the outer caps at tickSizeOuter, so '
            'the captured path pins tickSizeOuter to 6.',
      );
    });
  });

  group('resolveShellXAxisTickPadding', () {
    test('discards a user-supplied tickPadding', () {
      expect(
        resolveShellXAxisTickPadding(tickPadding: 25),
        5,
        reason:
            'CartesianChart.tsx:215 parses as '
            '`(tickPadding || showXAxisLablesTooltip) ? 5 : 10`, so any truthy '
            'user value selects 5 and the 25 is discarded.',
      );
    });

    test('treats an explicit zero as JavaScript-falsy', () {
      expect(
        resolveShellXAxisTickPadding(tickPadding: 0),
        10,
        reason:
            '0 is falsy in JavaScript, so `props.tickPadding || …` skips it and '
            'CartesianChart.tsx:215 falls to the 10 branch.',
      );
    });

    test('picks 5 for the tooltip branch alone', () {
      expect(
        resolveShellXAxisTickPadding(showXAxisLablesTooltip: true),
        5,
        reason:
            'the second operand of the `||` at CartesianChart.tsx:215 is the '
            'branch the author actually intended.',
      );
    });

    test('defaults to 10', () {
      expect(
        resolveShellXAxisTickPadding(),
        10,
        reason: 'neither operand is truthy, so :215 yields 10.',
      );
    });

    test('agrees with Oracle B on both branches', () {
      // Neither branch's *input* is visible in a capture, but its output is: the
      // x tick label's `y` is `max(tickSizeInner, 0) + tickPadding`
      // (`d3-axis/src/axis.js:46`).
      final plain = _CapturedAxis(
        _loadOracleStory('charts-linechart--line-chart-basic'),
      );
      expect(
        plain.tickLabelOffsets,
        everyElement(
          closeTo(6 + resolveShellXAxisTickPadding(), _oracleTolerance),
        ),
        reason:
            'LineChart sets neither tickPadding nor showXAxisLablesTooltip, so '
            'its labels sit 6 + 10 below the axis.',
      );
      final tooltip = _CapturedAxis(
        _loadOracleStory('charts-verticalbarchart--vertical-bar-axis-tooltip'),
      );
      expect(
        tooltip.tickLabelOffsets,
        everyElement(
          closeTo(
            6 + resolveShellXAxisTickPadding(showXAxisLablesTooltip: true),
            _oracleTolerance,
          ),
        ),
        reason:
            'the axis-tooltip story sets showXAxisLablesTooltip, so its labels '
            'sit 6 + 5 below the axis. No captured story supplies a tickPadding '
            'of its own, so the corpus can confirm both outputs of :215 but not '
            'the discarded input.',
      );
      expect(
        plain.tickLabelOffsets.length + tooltip.tickLabelOffsets.length,
        greaterThan(1),
        reason: 'both fixtures must have contributed at least one label.',
      );
    });
  });
}
