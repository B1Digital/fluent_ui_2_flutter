import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/heat_map_chart.dart';
import 'package:fluent_2_web/src/charts/heat_map_chart_style.dart';
import 'package:fluent_2_web/src/charts/internal/chart_colors.dart';
import 'package:fluent_2_web/src/charts/model/chart_common.dart';
import 'package:fluent_2_web/src/charts/model/heatmap_data.dart';
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
typedef _OracleCell = ({String x, String y, Color? fill, double? value});

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
