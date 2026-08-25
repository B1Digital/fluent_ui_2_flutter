import 'dart:math' as math;

import 'package:fluent_2/src/charts/cartesian/cartesian_chart.dart';
import 'package:fluent_2/src/charts/cartesian/cartesian_chart_props.dart';
import 'package:fluent_2/src/charts/cartesian/cartesian_layout.dart';
import 'package:fluent_2/src/charts/cartesian/cartesian_series_delegate.dart';
import 'package:fluent_2/src/charts/chrome/chart_popover.dart';
import 'package:fluent_2/src/charts/heat_map_chart.dart';
import 'package:fluent_2/src/charts/heat_map_chart_style.dart';
import 'package:fluent_2/src/charts/internal/chart_colors.dart';
import 'package:fluent_2/src/charts/internal/chart_text_measurer.dart';
import 'package:fluent_2/src/charts/internal/d3/scale_band.dart' as d3;
import 'package:fluent_2/src/charts/model/chart_common.dart';
import 'package:fluent_2/src/charts/model/chart_value.dart';
import 'package:fluent_2/src/charts/model/heatmap_data.dart';
import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/oracle_fixture.dart';

/// The captured HeatMapChart story whose grid this file asserts against.
///
/// The corpus holds two (`_manifest.json`, `capturedPerComponent.HeatMapChart`
/// is 2). Only the basic one is usable as a colour oracle: the custom
/// accessibility story overrides every cell's `rectText` with a formatted
/// string ('696.8M'), so the capture no longer carries the numeric value the
/// colour scale was fed.
const String _basicStory = 'charts-heatmapchart--heat-map-chart-basic';

/// The colour scale the basic story passes to `domainValuesForColorScale` and
/// `rangeValuesForColorScale`.
///
/// The storybook sources are not in the crawl, so these were recovered from the
/// capture itself: the 26 distinct cell values fall on three straight lines
/// meeting at exactly 200 and 400, and the four endpoint colours are palette
/// entries `'5'`, `'6'`, `'3'` and `'10'` of `utilities/colors.ts:62-72`. The
/// recovery is only as good as the fit, which is why
/// `every cell fill is the scale evaluated at its value` checks all 28 painted
/// cells rather than a sample — a wrong domain or range fails on most of them.
const List<double> _basicDomain = <double>[0, 200, 400, 600];

/// See [_basicDomain].
const List<Color> _basicRange = <Color>[
  Color(0xFF13A10E), // colors.ts:67 — lightGreen.primary.
  Color(0xFF3A96DD), // colors.ts:68 — lightBlue.primary.
  Color(0xFF2AA0A4), // colors.ts:65 — teal.tint20.
  Color(0xFFAE8C00), // colors.ts:72 — gold.shade10.
];

/// The basic story's 5 rows by 7 columns.
const int _basicRows = 5;

/// See [_basicRows].
const int _basicColumns = 7;

/// The cells the story paints; the remaining seven are `fill="transparent"`
/// placeholders (`HeatMapChart.tsx:272-276`).
const int _basicPaintedCells = 28;

FluentHeatMapChartData _series(
  String legend,
  List<(Object, Object, double)> cells,
) => FluentHeatMapChartData(
  legend: legend,
  value: 0,
  data: <FluentHeatMapChartDataPoint>[
    for (final (Object x, Object y, double value) in cells)
      FluentHeatMapChartDataPoint(x: x, y: y, value: value),
  ],
);

/// Two rows by two columns with `(b, row2)` missing.
List<FluentHeatMapChartData> _heatMapWithHole() => <FluentHeatMapChartData>[
  _series('legend', <(Object, Object, double)>[
    ('a', 'row1', 1),
    ('b', 'row1', 2),
    ('a', 'row2', 3),
  ]),
];

/// `row1` skips `b`, so a cursor that advanced on every column would report
/// row1's `c` value under `b`.
List<FluentHeatMapChartData> _heatMapSparse() => <FluentHeatMapChartData>[
  _series('legend', <(Object, Object, double)>[
    ('a', 'row1', 1),
    ('c', 'row1', 3),
    ('a', 'row2', 4),
    ('b', 'row2', 5),
    ('c', 'row2', 6),
  ]),
];

List<FluentHeatMapChartData> _heatMapCategories(List<String> xs) =>
    <FluentHeatMapChartData>[
      _series('legend', <(Object, Object, double)>[
        for (final String x in xs) (x, 'row1', 1),
      ]),
    ];

List<FluentHeatMapChartData> _heatMapDates() => <FluentHeatMapChartData>[
  _series('legend', <(Object, Object, double)>[
    (DateTime(2020, 3, 15), 'row1', 1),
    (DateTime(2020, 3, 16), 'row1', 2),
  ]),
];

List<FluentHeatMapChartData> _heatMapNumbers(List<double> xs) =>
    <FluentHeatMapChartData>[
      _series('legend', <(Object, Object, double)>[
        for (final double x in xs) (x, 'row1', 1),
      ]),
    ];

/// One cell of the captured grid: where it sits, what it was painted, and the
/// value its `<text>` reports — null for a placeholder, which carries no text.
typedef _OracleCell = ({
  String x,
  String y,
  Color? fill,
  double? value,
  Rect rect,
});

/// Reads the basic story's grid out of the capture.
///
/// The x tick labels all sit on the same baseline, the y tick labels all sit on
/// the same left edge, and every cell rect is a full band, so a cell is matched
/// to its row and column by its centre landing on a tick.
({List<String> xLabels, List<String> yLabels, List<_OracleCell> cells})
_readOracleGrid() {
  final story = loadOracleStory(_basicStory);
  // 10px is the axis tick type; cell text is the 14px body1Strong of
  // useHeatMapChartStyles.styles.ts:31-34.
  final ticks = story
      .byTag('text')
      .where((element) => element.fontSize == 10)
      .toList();
  expect(
    ticks.length,
    _basicRows + _basicColumns,
    reason: '$_basicStory must carry one tick label per row and column',
  );
  final baseline = ticks
      .map((element) => story.absoluteTranslate(element).dy)
      .reduce(math.max);
  final xTicks =
      ticks
          .where((element) => story.absoluteTranslate(element).dy == baseline)
          .toList()
        ..sort(
          (a, b) => story
              .absoluteTranslate(a)
              .dx
              .compareTo(story.absoluteTranslate(b).dx),
        );
  // Descending dy: a d3 band scale over a reversed range puts domain[0] at the
  // bottom, which is the order the y axis emits its ticks in.
  final yTicks =
      ticks
          .where((element) => story.absoluteTranslate(element).dy != baseline)
          .toList()
        ..sort(
          (a, b) => story
              .absoluteTranslate(b)
              .dy
              .compareTo(story.absoluteTranslate(a).dy),
        );
  expect(
    xTicks.length,
    _basicColumns,
    reason: 'the x axis of $_basicStory has $_basicColumns date ticks',
  );

  final rects = story.byTag('rect');
  expect(
    rects.length,
    _basicRows * _basicColumns,
    reason:
        'upstream emits one rect per grid position, matched or not '
        '(HeatMapChart.tsx:191-193)',
  );
  final cells = <_OracleCell>[];
  for (final rect in rects) {
    final origin = story.absoluteTranslate(rect);
    final centre = origin.translate(rect.width! / 2, rect.height! / 2);
    final column = xTicks.firstWhere(
      (tick) =>
          (story.absoluteTranslate(tick).dx - centre.dx).abs() <
          kOracleGeometryTolerance,
    );
    final row = yTicks.firstWhere(
      (tick) =>
          (story.absoluteTranslate(tick).dy - centre.dy).abs() <
          kOracleGeometryTolerance,
    );
    final texts = story
        .childrenOf(story.parentOf(rect)!)
        .where((element) => element.tag == 'text')
        .toList();
    cells.add((
      x: column.text!,
      y: row.text!,
      fill: rect.fill,
      value: texts.isEmpty ? null : double.parse(texts.single.text!),
      rect: Rect.fromLTWH(origin.dx, origin.dy, rect.width!, rect.height!),
    ));
  }
  return (
    xLabels: <String>[for (final tick in xTicks) tick.text!],
    yLabels: <String>[for (final tick in yTicks) tick.text!],
    cells: cells,
  );
}

void main() {
  group('buildFluentHeatMapDataSet', () {
    test('every (x, y) miss becomes a placeholder cell', () {
      final set = buildFluentHeatMapDataSet(
        data: _heatMapWithHole(),
        xAxisCategoryOrder: FluentAxisCategoryOrder.defaultOrder,
        yAxisCategoryOrder: FluentAxisCategoryOrder.defaultOrder,
        alphabeticalSort: true,
      );
      expect(
        set.cellAt('b', 'row2')!.isPlaceholder,
        isTrue,
        reason:
            'HeatMapChart.tsx:250-278 synthesises a NaN cell with the text '
            '"No data available"',
      );
      expect(
        set.cellAt('b', 'row2')!.rectText,
        'No data available',
        reason: 'HeatMapChart.tsx:255',
      );
    });

    test('the cursor only advances on a match, so cells stay aligned', () {
      final set = buildFluentHeatMapDataSet(
        data: _heatMapSparse(),
        xAxisCategoryOrder: FluentAxisCategoryOrder.defaultOrder,
        yAxisCategoryOrder: FluentAxisCategoryOrder.defaultOrder,
        alphabeticalSort: true,
      );
      expect(
        set.cellAt('c', 'row1')!.value,
        3,
        reason:
            'the cursor at HeatMapChart.tsx:197 advances only on a match, '
            'so a hole does not shift later values left',
      );
    });

    test('alphabetical sorting is case-insensitive', () {
      final set = buildFluentHeatMapDataSet(
        data: _heatMapCategories(<String>['Beta', 'alpha']),
        xAxisCategoryOrder: FluentAxisCategoryOrder.defaultOrder,
        yAxisCategoryOrder: FluentAxisCategoryOrder.defaultOrder,
        alphabeticalSort: true,
      );
      expect(
        set.xAxisPoints,
        <String>['alpha', 'Beta'],
        reason:
            'HeatMapChart.tsx:648 compares a.toLowerCase() > b.toLowerCase()',
      );
    });

    test('sortOrder none preserves insertion order', () {
      final set = buildFluentHeatMapDataSet(
        data: _heatMapCategories(<String>['Beta', 'alpha']),
        xAxisCategoryOrder: FluentAxisCategoryOrder.defaultOrder,
        yAxisCategoryOrder: FluentAxisCategoryOrder.defaultOrder,
        alphabeticalSort: false,
      );
      expect(
        set.xAxisPoints,
        <String>['Beta', 'alpha'],
        reason:
            'the comparator returns 0 when sortOrder is none, and the '
            'sort must be stable to preserve insertion order',
      );
    });

    test('date keys are formatted with the default %b/%d', () {
      final set = buildFluentHeatMapDataSet(
        data: _heatMapDates(),
        xAxisCategoryOrder: FluentAxisCategoryOrder.defaultOrder,
        yAxisCategoryOrder: FluentAxisCategoryOrder.defaultOrder,
        alphabeticalSort: true,
      );
      expect(
        set.xAxisPoints.first,
        'Mar/15',
        reason:
            "HeatMapChart.tsx:595 defaults xAxisDateFormatString to '%b/%d'",
      );
    });

    test('numeric keys are formatted with the default .2~s', () {
      final set = buildFluentHeatMapDataSet(
        data: _heatMapNumbers(<double>[1500, 2500000]),
        xAxisCategoryOrder: FluentAxisCategoryOrder.defaultOrder,
        yAxisCategoryOrder: FluentAxisCategoryOrder.defaultOrder,
        alphabeticalSort: true,
      );
      expect(
        set.xAxisPoints,
        <String>['1.5k', '2.5M'],
        reason: "HeatMapChart.tsx:599 defaults the number format to '.2~s'",
      );
    });

    test('an explicit category order routes through sortAxisCategories', () {
      final set = buildFluentHeatMapDataSet(
        data: _heatMapCategories(<String>['alpha', 'Beta']),
        xAxisCategoryOrder: const FluentAxisCategoryOrder.explicit(<String>[
          'Beta',
          'alpha',
        ]),
        yAxisCategoryOrder: FluentAxisCategoryOrder.defaultOrder,
        alphabeticalSort: true,
      );
      expect(
        set.xAxisPoints,
        <String>['Beta', 'alpha'],
        reason:
            'HeatMapChart.tsx:653 hands a non-default categoryOrder to '
            'sortAxisCategories, which emits the caller order first',
      );
    });
  });

  group('fluentHeatMapColourAt', () {
    test('two stops interpolate in sRGB', () {
      expect(
        fluentHeatMapColourAt(
          50,
          domain: <double>[0, 100],
          range: <Color>[const Color(0xFF000000), const Color(0xFFFFFFFF)],
        ).toARGB32(),
        const Color(0xFF808080).toARGB32(),
        reason: 'd3 dispatches string ranges to interpolateRgb with gamma 1',
      );
    });

    test(
      'the scale is unclamped, so values outside the domain extrapolate',
      () {
        expect(
          fluentHeatMapColourAt(
            150,
            domain: <double>[0, 100],
            range: <Color>[const Color(0xFF000000), const Color(0xFF808080)],
          ).toARGB32(),
          const Color(0xFFC0C0C0).toARGB32(),
          reason:
              'the colour scale carries no clamp at HeatMapChart.tsx:351-356',
        );
      },
    );

    test('a three-stop range is piecewise, not a single lerp', () {
      expect(
        fluentHeatMapColourAt(
          25,
          domain: <double>[0, 50, 100],
          range: <Color>[
            const Color(0xFF000000),
            const Color(0xFFFF0000),
            const Color(0xFFFFFFFF),
          ],
        ).toARGB32(),
        const Color(0xFF800000).toARGB32(),
        reason: 'the piecewise branch pairs adjacent stops',
      );
    });
  });

  group('HeatMap cell foreground', () {
    test('the text inverts once the contrast drops below three', () {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      const pale = Color(0xFFF5F5F5);
      expect(
        fluentColorContrast(theme.colors.neutralForeground1, pale) >= 3,
        isTrue,
        reason: 'dark text on a pale fill has plenty of contrast',
      );
      const dark = Color(0xFF1A1A1A);
      expect(
        fluentColorContrast(theme.colors.neutralForeground1, dark) < 3,
        isTrue,
        reason:
            'dark text on a dark fill trips the threshold at '
            'HeatMapChart.tsx:211, which swaps to colorNeutralBackground1',
      );
    });
  });

  group('Oracle B: $_basicStory', () {
    test('the date columns format and order as the capture renders them', () {
      final grid = _readOracleGrid();
      final set = buildFluentHeatMapDataSet(
        data: <FluentHeatMapChartData>[
          _series('legend', <(Object, Object, double)>[
            for (var column = 0; column < _basicColumns; column++)
              (DateTime(2020, 3, 3 + column), 'row', 1),
          ]),
        ],
        xAxisCategoryOrder: FluentAxisCategoryOrder.defaultOrder,
        yAxisCategoryOrder: FluentAxisCategoryOrder.defaultOrder,
        alphabeticalSort: true,
      );
      expect(
        set.xAxisPoints,
        grid.xLabels,
        reason:
            'the story feeds seven consecutive March dates and the capture '
            'renders them through the %b/%d default of HeatMapChart.tsx:595',
      );
    });

    test('every hole in the capture comes back as a placeholder cell', () {
      final grid = _readOracleGrid();
      final set = _oracleDataSet(grid);
      expect(
        set.xAxisPoints.toSet(),
        grid.xLabels.toSet(),
        reason: 'the grid spans every column the capture drew',
      );
      expect(
        set.yAxisPoints.toSet(),
        grid.yLabels.toSet(),
        reason: 'and every row',
      );
      var placeholders = 0;
      for (final cell in grid.cells) {
        final ported = set.cellAt(cell.x, cell.y);
        expect(
          ported,
          isNotNull,
          reason: 'the capture drew a rect at (${cell.x}, ${cell.y})',
        );
        if (cell.value == null) {
          placeholders++;
          expect(
            ported!.isPlaceholder,
            isTrue,
            reason:
                '(${cell.x}, ${cell.y}) is a transparent rect upstream '
                '(HeatMapChart.tsx:272-276), so the port must synthesise it',
          );
          expect(
            ported.value.isNaN,
            isTrue,
            reason: 'HeatMapChart.tsx:254 sets the placeholder value to NaN',
          );
        } else {
          expect(
            ported!.value,
            cell.value,
            reason: 'the value the capture drew at (${cell.x}, ${cell.y})',
          );
          expect(
            ported.isPlaceholder,
            isFalse,
            reason: 'a matched cell is not a placeholder',
          );
        }
      }
      expect(
        grid.cells.length - placeholders,
        _basicPaintedCells,
        reason:
            'the story paints $_basicPaintedCells cells and leaves the other '
            'seven transparent; a capture that changed would silently weaken '
            'this loop',
      );
    });

    test('every cell fill is the scale evaluated at its value', () {
      final grid = _readOracleGrid();
      var painted = 0;
      for (final cell in grid.cells) {
        if (cell.value == null) {
          expectOracleColour(
            'placeholder (${cell.x}, ${cell.y}) fill',
            const Color(0x00000000),
            cell.fill,
          );
          continue;
        }
        painted++;
        expectOracleColour(
          '(${cell.x}, ${cell.y}) = ${cell.value} fill',
          cell.fill,
          fluentHeatMapColourAt(
            cell.value!,
            domain: _basicDomain,
            range: _basicRange,
          ),
        );
      }
      expect(
        painted,
        _basicPaintedCells,
        reason: 'all $_basicPaintedCells painted cells were compared',
      );
    });
  });

  group('FluentHeatMapChartStyle', () {
    test('the resolved defaults carry upstream every token', () {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      final style = resolveFluentHeatMapChartStyle(theme);
      expect(
        style.cellTextStyle!.resolve(<WidgetState>{}),
        theme.typography.body1Strong,
        reason: 'useHeatMapChartStyles.styles.ts:32 spreads body1Strong',
      );
      expect(
        style.cellOpacity!.resolve(<WidgetState>{}),
        1,
        reason: 'HeatMapChart.tsx:129 — 1 while nothing else is highlighted',
      );
      expect(
        style.cellOpacity!.resolve(<WidgetState>{WidgetState.disabled}),
        0.1,
        reason:
            'HeatMapChart.tsx:129 — 0.1 once another legend owns the '
            'highlight',
      );
      expect(
        style.popoverMaxWidth!.resolve(<WidgetState>{}),
        238,
        reason: 'useHeatMapChartStyles.styles.ts:36 — maxWidth 238px',
      );
      expect(
        style.contrastThreshold!.resolve(<WidgetState>{}),
        3,
        reason: 'HeatMapChart.tsx:211 inverts the text below a ratio of 3',
      );
      expect(
        style.placeholderText!.resolve(<WidgetState>{}),
        'No data available',
        reason: 'HeatMapChart.tsx:255',
      );
    });

    test('merge and copyWith layer field by field', () {
      const base = FluentHeatMapChartStyle(
        contrastThreshold: WidgetStatePropertyAll<double?>(3),
        placeholderText: WidgetStatePropertyAll<String?>('a'),
      );
      const other = FluentHeatMapChartStyle(
        placeholderText: WidgetStatePropertyAll<String?>('b'),
      );
      final merged = base.merge(other);
      expect(
        merged.placeholderText!.resolve(<WidgetState>{}),
        'b',
        reason: 'the argument wins where it is non-null',
      );
      expect(
        merged.contrastThreshold!.resolve(<WidgetState>{}),
        3,
        reason: 'and the receiver survives where it is null',
      );
      expect(
        base.merge(null),
        base,
        reason: 'merging nothing is identity, and == compares field by field',
      );
      expect(
        base.copyWith(
          placeholderText: const WidgetStatePropertyAll<String?>('b'),
        ),
        merged,
        reason: 'copyWith and merge agree, so hashCode must too',
      );
      expect(
        base
            .copyWith(
              placeholderText: const WidgetStatePropertyAll<String?>('b'),
            )
            .hashCode,
        merged.hashCode,
        reason: 'equal styles hash equally',
      );
      expect(
        FluentHeatMapChartStyle.from(
          placeholderText: 'b',
        ).placeholderText!.resolve(<WidgetState>{}),
        'b',
        reason: 'from lifts a plain value into every state',
      );
    });
  });

  group('FluentHeatMapChart', () {
    Future<void> pump(
      WidgetTester tester,
      Widget chart, {
      FluentThemeData? theme,
    }) => tester.pumpWidget(
      FluentApp(
        theme:
            theme ??
            FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
        home: Center(
          child: SizedBox.fromSize(size: _fixtureSize, child: chart),
        ),
      ),
    );

    FluentHeatMapChartDelegate delegateOf(WidgetTester tester) =>
        tester
                .widget<FluentCartesianChart>(find.byType(FluentCartesianChart))
                .delegate
            as FluentHeatMapChartDelegate;

    testWidgets('the shell is configured with 0.02 padding on both axes', (
      tester,
    ) async {
      await pump(tester, _heatMapWidget());
      final shell = tester.widget<FluentCartesianChart>(
        find.byType(FluentCartesianChart),
      );
      // The two paddings are DELEGATE pull-hooks, not props — neither the
      // contract's props bag (§7.1) nor plan 05 Task 14's `copyWith` declares
      // them, and the shell reads them off the delegate.
      final delegate = shell.delegate as FluentHeatMapChartDelegate;
      expect(delegate.xAxisPadding, 0.02, reason: 'HeatMapChart.tsx:807');
      expect(delegate.yAxisPadding, 0.02, reason: 'HeatMapChart.tsx:808');
      expect(
        shell.props.xAxistickSize,
        0,
        reason: 'HeatMapChart.tsx:806 suppresses the x tick marks',
      );
      expect(
        shell.delegate.xAxisType,
        FluentChartAxisType.category,
        reason: 'HeatMapChart.tsx:797 passes XAxisTypes.StringAxis',
      );
      expect(
        shell.delegate.yAxisType,
        FluentChartAxisType.category,
        reason:
            'and HeatMapChart.tsx:798 YAxisType.StringAxis, which is what '
            'routes the shell to createStringYAxis',
      );
    });

    testWidgets('cells fill their whole band with no gap or radius', (
      tester,
    ) async {
      await pump(tester, _heatMapWidget());
      final context = _heatMapContext();
      final cell = delegateOf(tester).cellsFor(context).first;
      expect(
        cell.rect.width,
        closeTo(context.xScale.bandwidth, 1e-9),
        reason: 'HeatMapChart.tsx:231 uses the full bandwidth',
      );
      expect(
        cell.rect.height,
        closeTo(context.yScalePrimary.bandwidth, 1e-9),
        reason: 'and HeatMapChart.tsx:232 the full y bandwidth',
      );
    });

    testWidgets('rows paint top-first, matching the reversed DOM order', (
      tester,
    ) async {
      await pump(tester, _heatMapWidget());
      final delegate = delegateOf(tester);
      final ys = delegate
          .cellsFor(_heatMapContext())
          .map((cell) => cell.cell.y)
          .toList();
      expect(
        ys.first,
        delegate.dataSet.yAxisPoints.last,
        reason:
            'HeatMapChart.tsx:186 reverses the y list so the top row is '
            'emitted first, which is what the grid arrow navigation expects',
      );
    });

    testWidgets('a placeholder cell is transparent and carries no text', (
      tester,
    ) async {
      await pump(tester, _heatMapWidget(withHole: true));
      final miss = delegateOf(tester)
          .cellsFor(_heatMapContext())
          .firstWhere((cell) => cell.cell.isPlaceholder);
      expect(
        miss.fill.a,
        0,
        reason: 'HeatMapChart.tsx:273 fills the miss rect with transparent',
      );
      expect(
        miss.opacity,
        1,
        reason:
            'the miss group carries NO fillOpacity attribute at :262-277, so '
            'a dimmed legend does not dim the placeholders',
      );
    });

    testWidgets('a dimmed legend drops both the cell opacity and its region', (
      tester,
    ) async {
      await pump(tester, _heatMapWidget(twoLegends: true));
      await tester.tap(find.text('One'));
      await tester.pumpAndSettle();
      final delegate = delegateOf(tester);
      final context = _heatMapContext();
      final dimmed = delegate
          .cellsFor(context)
          .firstWhere((cell) => cell.cell.legend == 'Two');
      expect(
        dimmed.opacity,
        0.1,
        reason: 'HeatMapChart.tsx:129 dims every unhighlighted legend to 0.1',
      );
      expect(
        delegate
            .buildHitRegions(context, _heatMapLayout())
            .map((region) => region.legend)
            .toSet(),
        <String>{'One'},
        reason:
            'isPopoverOpen is `selectedLegend === "" || selectedLegend === '
            'data.legend` at HeatMapChart.tsx:154, and the same predicate '
            'takes the dimmed rect out of the tab order at :224',
      );
    });

    testWidgets('hovering a dimmed cell opens nothing', (tester) async {
      await pump(tester, _heatMapWidget(twoLegends: true));
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      final probe =
          tester.getTopLeft(find.byType(FluentCartesianChart)) +
          const Offset(560, 100);
      await gesture.moveTo(probe);
      await tester.pumpAndSettle();
      expect(
        find.byType(FluentChartPopover),
        findsOneWidget,
        reason:
            'the probe must land on a cell of the second legend while nothing '
            'is selected, or the assertion below would pass vacuously',
      );
      await gesture.moveTo(Offset.zero);
      await tester.tap(find.text('One'));
      await tester.pumpAndSettle();
      await gesture.moveTo(probe);
      await tester.pumpAndSettle();
      expect(
        find.byType(FluentChartPopover),
        findsNothing,
        reason:
            'isPopoverOpen is `selectedLegend === "" || selectedLegend === '
            'data.legend` at HeatMapChart.tsx:154',
      );
    });

    testWidgets('the semantic title counts data points', (tester) async {
      await pump(tester, _heatMapWidget(chartTitle: 'Occupancy'));
      expect(
        tester
            .widget<FluentCartesianChart>(find.byType(FluentCartesianChart))
            .props
            .chartTitleForSemantics,
        'Occupancy. Heat map chart with 6 data points. ',
        reason: 'HeatMapChart.tsx:635-639',
      );
    });

    testWidgets('a cell narrates its position, legend and value', (
      tester,
    ) async {
      await pump(tester, _heatMapWidget());
      final regions = delegateOf(
        tester,
      ).buildHitRegions(_heatMapContext(), _heatMapLayout());
      expect(
        regions.first.semanticsLabel,
        'a, row2. One, 4.',
        reason:
            '_getAriaLabel (HeatMapChart.tsx:620-632) joins the x, the y, the '
            'legend and the rect text, and the reversed row order at :186 '
            'puts the top row first. A JavaScript 4 prints as "4"',
      );
    });

    testWidgets('empty data renders the alert instead of a chart', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentHeatMapChart(
          data: <FluentHeatMapChartData>[],
          domainValuesForColorScale: <double>[0, 1],
          rangeValuesForColorScale: <Color>[
            Color(0xFF000000),
            Color(0xFFFFFFFF),
          ],
        ),
      );
      expect(
        find.byType(FluentCartesianChart),
        findsNothing,
        reason:
            'HeatMapChart.tsx:820 renders the empty-chart div in place of the '
            'shell',
      );
    });

    test('a cell fill flattens to the system colour under high contrast', () {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      final cell = _delegate(
        colors: FluentChartColors.of(theme),
      ).cellsFor(_heatMapContext()).first;
      expect(
        cell.fill.toARGB32(),
        theme.colors.neutralForeground1.toARGB32(),
        reason:
            'spec §5.3: a series mark carries no forced-color-adjust upstream, '
            'so the browser rewrites its fill to CanvasText',
      );
      expect(
        cell.foreground.toARGB32(),
        theme.colors.neutralBackground1.toARGB32(),
        reason:
            'the flattened fill is the foreground colour itself, so the '
            'contrast ratio is 1 and HeatMapChart.tsx:211 inverts the text',
      );
    });
  });

  group('Oracle B: $_basicStory cell geometry', () {
    test('every cell rect is the band the capture drew', () {
      final grid = _readOracleGrid();
      final context = _oracleContext(grid);
      final cells = _delegate(dataSet: _oracleDataSet(grid)).cellsFor(context);
      expect(
        cells.length,
        _basicRows * _basicColumns,
        reason: 'one cell per grid position, placeholders included',
      );
      for (final cell in cells) {
        final captured = grid.cells.singleWhere(
          (candidate) =>
              candidate.x == cell.cell.x && candidate.y == cell.cell.y,
        );
        expectOracleRect(
          'the rect at (${cell.cell.x}, ${cell.cell.y}), which sits at the '
          'band origin and spans the full bandwidth on both axes '
          '(HeatMapChart.tsx:226-233)',
          captured.rect,
          cell.rect,
        );
      }
    });
  });
}

/// The colour ramp the synthetic fixtures below are scaled against.
const List<double> _fixtureDomain = <double>[0, 6];

/// See [_fixtureDomain].
const List<Color> _fixtureRange = <Color>[Color(0xFF000000), Color(0xFFFFFFFF)];

/// The three-by-two grid every widget test in this file renders.
///
/// [twoLegends] splits it so column `a` belongs to `One` and columns `b` and
/// `c` to `Two`; [withHole] drops `(b, row2)` so the port has to synthesise a
/// placeholder there.
List<FluentHeatMapChartData> _heatMapData({
  bool twoLegends = false,
  bool withHole = false,
}) {
  const cells = <(Object, Object, double)>[
    ('a', 'row1', 1),
    ('b', 'row1', 2),
    ('c', 'row1', 3),
    ('a', 'row2', 4),
    ('b', 'row2', 5),
    ('c', 'row2', 6),
  ];
  final kept = <(Object, Object, double)>[
    for (final cell in cells)
      if (!withHole || cell.$1 != 'b' || cell.$2 != 'row2') cell,
  ];
  if (!twoLegends) {
    return <FluentHeatMapChartData>[_series('One', kept)];
  }
  return <FluentHeatMapChartData>[
    _series('One', <(Object, Object, double)>[
      for (final cell in kept)
        if (cell.$1 == 'a') cell,
    ]),
    _series('Two', <(Object, Object, double)>[
      for (final cell in kept)
        if (cell.$1 != 'a') cell,
    ]),
  ];
}

Widget _heatMapWidget({
  String? chartTitle,
  bool twoLegends = false,
  bool withHole = false,
}) => FluentHeatMapChart(
  data: _heatMapData(twoLegends: twoLegends, withHole: withHole),
  domainValuesForColorScale: _fixtureDomain,
  rangeValuesForColorScale: _fixtureRange,
  chartTitle: chartTitle,
);

FluentHeatMapDataSet _fixtureDataSet({
  bool twoLegends = false,
  bool withHole = false,
}) => buildFluentHeatMapDataSet(
  data: _heatMapData(twoLegends: twoLegends, withHole: withHole),
  xAxisCategoryOrder: FluentAxisCategoryOrder.defaultOrder,
  yAxisCategoryOrder: FluentAxisCategoryOrder.defaultOrder,
  alphabeticalSort: true,
);

/// A delegate over [dataSet], resolved against [colors].
FluentHeatMapChartDelegate _delegate({
  FluentChartColors? colors,
  FluentHeatMapDataSet? dataSet,
  String selectedLegend = '',
}) {
  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
  return FluentHeatMapChartDelegate(
    dataSet: dataSet ?? _fixtureDataSet(),
    style: resolveFluentHeatMapChartStyle(theme),
    colors: colors ?? FluentChartColors.of(theme),
    measurer: FluentChartTextMeasurer(),
    domainValues: _fixtureDomain,
    rangeValues: _fixtureRange,
    selectedLegend: selectedLegend,
  );
}

/// A band scale over [domain] whose bands start at [firstStart] and step by
/// [step], reversed when [descending] — the y range runs bottom to top.
///
/// The 0.02 is the padding HeatMapChart.tsx:807-808 hands the shell, and d3
/// centres the leftover `paddingOuter * 2 * step` about the range
/// (`d3-scale/src/band.js:25-28`), which is what puts the first band 0.02 of a
/// step inside the range.
d3.ScaleBand _bandScale(
  List<String> domain, {
  required double firstStart,
  required double step,
  bool descending = false,
}) {
  final lo = firstStart - 0.02 * step;
  final hi = lo + step * (domain.length + 0.02);
  return d3.scaleBand()
    ..domainOf(domain.cast<Object>())
    ..rangeOf(descending ? <double>[hi, lo] : <double>[lo, hi])
    ..padding(0.02);
}

/// The size every widget test in this file gives the chart.
const Size _fixtureSize = Size(700, 350);

/// A layout of the fixture size under the shell's own default margins. The
/// heat-map delegate reads nothing off it — every cell is placed by the scales
/// — but the shell contract passes one.
FluentCartesianLayout _heatMapLayout() => FluentCartesianLayout.resolve(
  size: _fixtureSize,
  margins: FluentCartesianMarginSolver.solve(
    props: const FluentCartesianChartProps(),
    startFromX: 0,
    isRtl: false,
  ),
  xAxisLabelReserve: 0,
  isRtl: false,
  startFromX: 0,
);

/// The scales the fixture grid is laid out through, over the plot of
/// [_heatMapLayout]. The y range runs bottom to top, as `createStringYAxis`
/// builds it (`utilities.ts:968-970`).
FluentCartesianChildContext _heatMapContext() {
  final plot = _heatMapLayout().plotRect;
  return FluentCartesianChildContext(
    xScale: d3.scaleBand()
      ..domainOf(const <String>['a', 'b', 'c'].cast<Object>())
      ..rangeOf(<double>[plot.left, plot.right])
      ..padding(0.02),
    yScalePrimary: d3.scaleBand()
      ..domainOf(const <String>['row1', 'row2'].cast<Object>())
      ..rangeOf(<double>[plot.bottom, plot.top])
      ..padding(0.02),
    containerWidth: _fixtureSize.width,
    containerHeight: _fixtureSize.height,
  );
}

/// Rebuilds the capture's own two band scales from the rects it drew.
///
/// The step is recovered from the span between the first and the last band
/// rather than from `bandwidth / (1 - paddingInner)`, because the span divides
/// the capture's rounding error by the number of columns instead of
/// multiplying it.
FluentCartesianChildContext _oracleContext(
  ({List<String> xLabels, List<String> yLabels, List<_OracleCell> cells}) grid,
) {
  double firstStart(Iterable<double> starts) => starts.reduce(math.min);
  double lastStart(Iterable<double> starts) => starts.reduce(math.max);
  final lefts = grid.cells.map((cell) => cell.rect.left);
  final tops = grid.cells.map((cell) => cell.rect.top);
  return FluentCartesianChildContext(
    xScale: _bandScale(
      grid.xLabels,
      firstStart: firstStart(lefts),
      step: (lastStart(lefts) - firstStart(lefts)) / (grid.xLabels.length - 1),
    ),
    yScalePrimary: _bandScale(
      grid.yLabels,
      firstStart: firstStart(tops),
      step: (lastStart(tops) - firstStart(tops)) / (grid.yLabels.length - 1),
      descending: true,
    ),
    containerWidth: _fixtureSize.width,
    containerHeight: _fixtureSize.height,
  );
}

/// The capture's own cells, fed back through the port.
FluentHeatMapDataSet _oracleDataSet(
  ({List<String> xLabels, List<String> yLabels, List<_OracleCell> cells}) grid,
) => buildFluentHeatMapDataSet(
  data: <FluentHeatMapChartData>[
    FluentHeatMapChartData(
      legend: 'legend',
      value: 0,
      data: <FluentHeatMapChartDataPoint>[
        for (final cell in grid.cells)
          if (cell.value != null)
            FluentHeatMapChartDataPoint(
              x: cell.x,
              y: cell.y,
              value: cell.value!,
            ),
      ],
    ),
  ],
  xAxisCategoryOrder: FluentAxisCategoryOrder.defaultOrder,
  yAxisCategoryOrder: FluentAxisCategoryOrder.defaultOrder,
  alphabeticalSort: true,
);
