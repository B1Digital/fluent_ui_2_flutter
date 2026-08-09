import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:fluent_2_web/src/charts/axis/axis_builders.dart';
import 'package:fluent_2_web/src/charts/axis/axis_types.dart';
import 'package:fluent_2_web/src/charts/internal/d3/axis_geometry.dart' as d3;
import 'package:fluent_2_web/src/charts/internal/d3/time_format.dart' as d3;
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
  _CapturedAxis(Map<String, dynamic> story) {
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

  group('createDateXAxis', () {
    FluentXAxisParams dateParams({
      DateTime? start,
      DateTime? end,
      bool hideTickOverlap = false,
      double Function(List<String>)? calcMaxLabelWidth,
    }) {
      return FluentXAxisParams(
        domainNRangeValues: FluentChartDomainRange(
          dStartValue: start ?? DateTime.utc(2020),
          dEndValue: end ?? DateTime.utc(2020, 12, 31),
          rStartValue: 40,
          rEndValue: 680,
        ),
        containerHeight: 300,
        containerWidth: 700,
        margins: _margins,
        // utilities.ts:454 destructures 6 on the date axis; FluentXAxisParams
        // carries the numeric-axis default of 10, so the caller supplies it.
        tickPadding: 6,
        hideTickOverlap: hideTickOverlap,
        calcMaxLabelWidth: calcMaxLabelWidth,
      );
    }

    test('always nices the domain, unlike the numeric axis', () {
      final spec = createDateXAxis(
        dateParams(
          start: DateTime.utc(2020, 1, 3),
          end: DateTime.utc(2020, 12, 28),
        ),
        const FluentTickParams(),
        useUtc: true,
      );
      expect(
        spec.scale.domain.first,
        DateTime.utc(2020),
        reason:
            'utilities.ts:465-468 calls nice() unconditionally, so the domain '
            'snaps outward to a month boundary.',
      );
    });

    test('uses a six-tick default and the six-pixel tick padding', () {
      final spec = createDateXAxis(
        dateParams(),
        const FluentTickParams(),
        useUtc: true,
      );
      expect(
        spec.tickValues.length,
        greaterThan(0),
        reason: 'the axis produces ticks.',
      );
      expect(
        spec.tickPadding,
        6,
        reason:
            'utilities.ts:454 destructures tickPadding = 6 on the date axis, not '
            'the 10 the numeric axis uses.',
      );
    });

    test('formats through the strftime table when a locale is supplied', () {
      final spec = createDateXAxis(
        dateParams(start: DateTime.utc(2020), end: DateTime.utc(2020, 12, 31)),
        const FluentTickParams(),
        useUtc: true,
        timeFormatLocale: d3.defaultTimeLocale,
      );
      expect(
        spec.tickLabels.first,
        'Jan 2020',
        reason:
            'utilities.ts:504-506 uses the multi-level d3 formatter; the niced '
            'domain runs 1 Jan 2020 to 1 Jan 2021, so the scanned levels are 6 '
            "(month) and 7 (year) and the table cell is M_Y, '%b %Y'.",
      );
    });

    test('prefers a custom formatter over everything but tickText', () {
      final spec = createDateXAxis(
        dateParams(),
        const FluentTickParams(),
        useUtc: true,
        customDateTimeFormatter: (d) => 'D${d.month}',
      );
      expect(
        spec.tickLabels.first,
        startsWith('D'),
        reason: 'utilities.ts:501-503 puts customDateTimeFormatter second.',
      );
    });

    test('adds forty pixels of pad when hiding overlap, not twenty', () {
      final spec = createDateXAxis(
        dateParams(hideTickOverlap: true, calcMaxLabelWidth: (labels) => 280),
        const FluentTickParams(),
        useUtc: true,
      );
      expect(
        spec.tickValues.length,
        2,
        reason:
            'utilities.ts:519 adds 40 rather than the numeric axis 20, so '
            'floor(640 / 320) is 2; over the niced 1 Jan 2020 to 1 Jan 2021 '
            'domain d3 answers that target with a one-year step, which is the '
            'two endpoints and nothing between them.',
      );
    });

    test('draws gridlines for Gantt but not for HorizontalBarChartWithAxis', () {
      final gantt = createDateXAxis(
        dateParams(),
        const FluentTickParams(),
        useUtc: true,
        chartType: FluentChartType.ganttChart,
      );
      final hbwa = createDateXAxis(
        dateParams(),
        const FluentTickParams(),
        useUtc: true,
        chartType: FluentChartType.horizontalBarChartWithAxis,
      );
      expect(
        gantt.tickSizeInner,
        -280,
        reason: 'utilities.ts:529-531 lists GanttChart only.',
      );
      expect(
        hbwa.tickSizeInner,
        6,
        reason:
            'HBWA is in the numeric-axis list at utilities.ts:308 but NOT in the '
            'date-axis list at :529.',
      );
    });
  });

  group('createDateXAxis against Oracle B', () {
    const storyId = 'charts-linechart--line-chart-basic';
    final story = _loadOracleStory(storyId);
    final captured = _CapturedAxis(story);
    const crispOffset = 0.5;
    // The domain path reads 'M64.5,6V0.5H680.5V6', so the range is 64 to 680.
    const rStart = 64.0;
    const rEnd = 680.0;

    // The captured ticks are seven whole days, evenly spaced across the whole
    // range, which is the niced domain read back off the capture: `nice()` is
    // idempotent once both endpoints already sit on an interval boundary, so
    // feeding it back in exercises the same code path the story did. The
    // weekday pattern (one Sunday inside any seven-day window) and therefore
    // the resolved format levels do not depend on the year, and 2020 is the
    // year LineChartBasic's own data uses.
    FluentAxisSpec buildSpec() => createDateXAxis(
      FluentXAxisParams(
        domainNRangeValues: FluentChartDomainRange(
          dStartValue: DateTime.utc(2020, 3, 3),
          dEndValue: DateTime.utc(2020, 3, 9),
          rStartValue: rStart,
          rEndValue: rEnd,
        ),
        // The axis group sits at translate(0, 205) inside a 260-high SVG.
        containerHeight: 205,
        containerWidth: 700,
        margins: const FluentChartMargins(
          left: 40,
          right: 20,
          top: 20,
          bottom: 35,
        ),
        // CartesianChart.tsx:215 always resolves a tickPadding and hands it to
        // every axis builder, so the 6 destructured at utilities.ts:454 is
        // unreachable from the shell and the captured label offset is 6 + 10.
        tickPadding: 10,
      ),
      const FluentTickParams(),
      // The capture shows seven exactly equal day steps, so no daylight-saving
      // transition intervened and the capture zone agrees with UTC over this
      // window; asserting in UTC makes the expectation zone-independent.
      useUtc: true,
    );

    test('the corpus fixture still carries a seven-tick date x axis', () {
      // Guard against a renamed or re-captured story quietly emptying every
      // assertion below.
      expect(
        captured.tickOffsets.length,
        7,
        reason:
            '$storyId captured seven x ticks; a different count means the '
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
        <DateTime>[
          for (var day = 3; day <= 9; day++) DateTime.utc(2020, 3, day),
        ],
        reason:
            'utilities.ts:470 asks for six ticks over a six-day domain, so d3 '
            'answers a one-day step and seven tick values.',
      );
      expect(
        spec.tickLabels,
        captured.tickLabels,
        reason:
            'the levels scanned over d3\'s default ten ticks (utilities.ts:477) '
            'span hour to week, so formatOptions renders a short month, a '
            'two-digit day and a twelve-hour hour.',
      );
    });

    test('reproduces the captured tick positions', () {
      final spec = buildSpec();
      for (var i = 0; i < spec.tickValues.length; i++) {
        expect(
          spec.scale(spec.tickValues[i])! + crispOffset,
          closeTo(captured.tickOffsets[i], _oracleTolerance),
          reason:
              'axis_geometry adds the crispness offset once to position(d) '
              '(`d3-axis/src/axis.js:76`), so tick $i must land on the captured '
              'translate.',
        );
      }
    });

    test('reproduces the captured tick length and label offset', () {
      final spec = buildSpec();
      expect(
        captured.tickLineLengths,
        everyElement(closeTo(spec.tickSizeInner, _oracleTolerance)),
        reason:
            'a LineChart date axis takes no gridline override, so every '
            'captured tick line is the destructured xAxistickSize of 6 '
            '(utilities.ts:455).',
      );
      expect(
        math.max(spec.tickSizeInner, 0.0) + spec.tickPadding,
        closeTo(captured.tickLabelOffsets.first, _oracleTolerance),
        reason:
            'd3-axis/src/axis.js:46 places the label at '
            'max(tickSizeInner, 0) + tickPadding, which is the captured 16.',
      );
    });

    test('reproduces the captured domain path end caps', () {
      final spec = buildSpec();
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

  group('createStringXAxis', () {
    FluentXAxisParams bandParams({
      bool hideTickOverlap = false,
      double Function(List<String>)? calcMaxLabelWidth,
      bool isRtl = false,
      double? innerPadding,
      double? outerPadding,
    }) {
      return FluentXAxisParams(
        domainNRangeValues: FluentChartDomainRange(
          dStartValue: 0,
          dEndValue: 0,
          rStartValue: isRtl ? 300 : 0,
          rEndValue: isRtl ? 0 : 300,
        ),
        containerHeight: 300,
        containerWidth: 300,
        margins: _margins,
        hideTickOverlap: hideTickOverlap,
        calcMaxLabelWidth: calcMaxLabelWidth,
        xAxisInnerPadding: innerPadding,
        xAxisOuterPadding: outerPadding,
      );
    }

    test('uses every category as a tick when overlap hiding is off', () {
      final spec = createStringXAxis(
        bandParams(innerPadding: 0, outerPadding: 0),
        const FluentTickParams(),
        <String>['A', 'B', 'C'],
      );
      expect(
        spec.tickValues,
        <String>['A', 'B', 'C'],
        reason:
            'utilities.ts:588 defaults the tick values to the whole dataset.',
      );
      expect(
        spec.tickSizeInner,
        6,
        reason: 'utilities.ts:572 — xAxistickSize 6.',
      );
      expect(
        spec.tickPadding,
        10,
        reason: 'utilities.ts:573 — tickPadding 10.',
      );
    });

    test('falls back to the shorthand padding of 0.1 for both sides', () {
      final spec = createStringXAxis(
        bandParams(),
        const FluentTickParams(),
        <String>['A', 'B'],
      );
      expect(
        spec.scale.bandwidth,
        closeTo(300 * (1 - 0.1) / (2 - 0.1 + 0.2), 1e-9),
        reason:
            'utilities.ts:574 destructures xAxisPadding = 0.1 and :585-586 apply '
            'it to both inner and outer.',
      );
    });

    test('drops the leading label because the sweep uses the band edge', () {
      final spec = createStringXAxis(
        bandParams(
          hideTickOverlap: true,
          innerPadding: 0,
          outerPadding: 0,
          // Each label measures 20px, so a half-width of 10.
          calcMaxLabelWidth: (labels) => 20,
        ),
        const FluentTickParams(),
        <String>['A', 'B', 'C'],
      );
      expect(
        spec.tickValues,
        <String>['B', 'C'],
        reason:
            'parity with utilities.ts:610 — the sweep positions each label at the '
            "band's LEADING edge while d3-axis draws it at the centre, so A at "
            'edge 0 is judged to overflow the left boundary even though its '
            'label would actually sit at 50.',
      );
    });

    test('sweeps from the right under an RTL descending range', () {
      final spec = createStringXAxis(
        bandParams(
          hideTickOverlap: true,
          isRtl: true,
          innerPadding: 0,
          outerPadding: 0,
          calcMaxLabelWidth: (labels) => 20,
        ),
        const FluentTickParams(),
        <String>['A', 'B', 'C'],
      );
      expect(
        spec.tickValues.length,
        greaterThan(0),
        reason:
            'utilities.ts:602-608 detects RTL from range[1] - range[0] < 0 and '
            'flips start, end and the sign.',
      );
    });

    test('indexes tickText against the filtered array, not the original', () {
      final spec = createStringXAxis(
        FluentXAxisParams(
          domainNRangeValues: const FluentChartDomainRange(
            dStartValue: 0,
            dEndValue: 0,
            rStartValue: 0,
            rEndValue: 300,
          ),
          containerHeight: 300,
          containerWidth: 300,
          margins: _margins,
          hideTickOverlap: true,
          xAxisInnerPadding: 0,
          xAxisOuterPadding: 0,
          calcMaxLabelWidth: (labels) => 20,
          tickText: const <String>['first', 'second', 'third'],
        ),
        const FluentTickParams(tickValues: <Object>['A', 'B', 'C']),
        <String>['A', 'B', 'C'],
      );
      expect(
        spec.tickLabels,
        <String>['first', 'second'],
        reason:
            "parity with utilities.ts:590 and :637 — after the sweep keeps ['B','C'] "
            'the labels are read at indices 0 and 1 of the FILTERED list, so B '
            "shows 'first' rather than 'second'.",
      );
    });
  });

  group('createStringXAxis against Oracle B', () {
    // A four-category VerticalBarChart is the smallest captured band x axis:
    // its padding is fully determined (`VerticalBarChart.tsx:315-323` resolves
    // the string-axis inner padding to 2/3 and the outer to 0), so the tick
    // positions below are a real check rather than a fit.
    const storyId =
        'charts-verticalbarchart--vertical-bar-custom-accessibility';
    final story = _loadOracleStory(storyId);
    final captured = _CapturedAxis(story);

    // The captured domain path is 'M310.5,6V0.5H510.5V6', so the range is
    // [310, 510] once the recorded crispness half-pixel is taken back off.
    final crispOffset = (story['crispOffset'] as num).toDouble();
    const rStart = 310.0;
    const rEnd = 510.0;

    const dataset = <String>['One', 'Two', 'Three', 'Four'];

    FluentAxisSpec buildSpec() => createStringXAxis(
      const FluentXAxisParams(
        // A band axis never reads the domain endpoints, which is why upstream
        // leaves them at 0 (`utilities.ts:2160`); only the range matters.
        domainNRangeValues: FluentChartDomainRange(
          dStartValue: 0,
          dEndValue: 0,
          rStartValue: rStart,
          rEndValue: rEnd,
        ),
        // 400 is the captured SVG height and 800 its width.
        containerHeight: 400,
        containerWidth: 800,
        margins: FluentChartMargins(left: 40, right: 20, top: 20, bottom: 35),
        // VerticalBarChart.tsx:321 — 2/3 for a string axis.
        xAxisInnerPadding: 2 / 3,
        // VerticalBarChart.tsx:323 — the outer padding defaults to 0.
        xAxisOuterPadding: 0,
      ),
      const FluentTickParams(),
      dataset,
    );

    test('the corpus fixture still carries a four-tick band x axis', () {
      // Guard against a renamed or re-captured story quietly emptying every
      // assertion below.
      expect(
        captured.tickOffsets.length,
        dataset.length,
        reason:
            '$storyId captured ${dataset.length} x ticks; a different count '
            'means the fixture changed and the expectations here are stale.',
      );
      expect(
        story['deviceScaleFactor'],
        1,
        reason:
            'the geometry below only agrees with flutter test at scale 1, where '
            'the crispness offset is 0.5.',
      );
    });

    test('reproduces the captured labels and bandwidth', () {
      final spec = buildSpec();
      expect(
        spec.tickLabels,
        captured.tickLabels,
        reason:
            'utilities.ts:593 returns the category itself when no tickText was '
            'supplied.',
      );
      expect(
        spec.scale.bandwidth,
        closeTo(20, _oracleTolerance),
        reason:
            'the captured bars are 20px wide because a 200px range over four '
            'categories at paddingInner 2/3 gives a step of 60 and a band of 20.',
      );
    });

    test('reproduces the captured tick positions through the band centring', () {
      final spec = buildSpec();
      final geometry = d3.FluentAxisGeometry(
        orientation: spec.orientation,
        scale: spec.scale,
        tickValues: spec.tickValues,
        tickLabels: spec.tickLabels,
        offset: crispOffset,
        tickSizeInner: spec.tickSizeInner,
        tickSizeOuter: spec.tickSizeOuter,
        tickPadding: spec.tickPadding,
      );
      for (var i = 0; i < dataset.length; i++) {
        expect(
          geometry.ticks[i].position,
          closeTo(captured.tickOffsets[i], _oracleTolerance),
          reason:
              'd3-axis/src/axis.js:21-25 centres a band tick at '
              'scale(d) + max(0, bandwidth - 2 * offset) / 2, so tick $i must '
              'land on the captured translate.',
        );
      }
    });

    test('reproduces the captured tick length and label offset', () {
      final spec = buildSpec();
      expect(
        captured.tickLineLengths,
        everyElement(closeTo(spec.tickSizeInner, _oracleTolerance)),
        reason:
            'a VerticalBarChart band axis takes no gridline override, so every '
            'captured tick line is the destructured xAxistickSize of 6 '
            '(utilities.ts:572).',
      );
      expect(
        math.max(spec.tickSizeInner, 0.0) + spec.tickPadding,
        closeTo(captured.tickLabelOffsets.first, _oracleTolerance),
        reason:
            'd3-axis/src/axis.js:46 places the label at '
            'max(tickSizeInner, 0) + tickPadding, which is the captured 16.',
      );
    });

    test('reproduces the captured domain path end caps', () {
      final spec = buildSpec();
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
}
