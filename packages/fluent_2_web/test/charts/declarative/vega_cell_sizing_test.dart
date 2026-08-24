// Which routed kinds take their cell size from the spec, and where the lifted
// legend row comes out of — mounted rather than reasoned about
// (`VegaDeclarativeChart.tsx:151-160`, `vega_declarative_chart.dart`'s
// `kVegaDefaultCellHeight` and `_withSharedLegend`).
//
// It lives beside the Plotly adapter's tests rather than in `test/charts/vega/`
// because that directory was outside the change this file guards; the subject
// is `FluentVegaDeclarativeChart` and it belongs there whenever the two can be
// moved together.
//
// The rule under test is membership, not arithmetic. Upstream's transformers
// disagree about `width`/`height`: `transformVegaLiteToScatterChartProps`
// (`VegaLiteSchemaAdapter.ts:3191-3231`) returns neither, and
// `ScatterChart.tsx:137-139` says why — "height and width are not used to
// resize or set as dimesions of the chart" — while stacked bar (`:2711-2712`)
// and heatmap (`:3509-3510`) return both, defaulting to `DEFAULT_CHART_HEIGHT`.
// A port that reads `spec['height']` for every kind invents a box the browser
// never draws, which is exactly how the captured scatter story came out 400
// tall against upstream's 350.
//
// The two halves of that are separated deliberately, because each hides the
// other. In a box SHORTER than the declared height the flexible cell clamps a
// wrong 400 down to something that looks right; in a box TALLER than it the
// wrong 400 stops short of the space upstream fills. Only the pair pins both.
import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/chrome/legend.dart';
import 'package:fluent_2_web/src/charts/scatter_chart.dart';
import 'package:fluent_2_web/src/charts/vega_declarative_chart.dart';
import 'package:fluent_2_web/src/charts/vertical_stacked_bar_chart.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child, {double height = 351}) =>
      tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: Center(
            child: SizedBox(width: 600, height: height, child: child),
          ),
        ),
      );

  const rows = <Object?>[
    <String, Object?>{'x': 1, 'y': 2, 'g': 'p'},
    <String, Object?>{'x': 2, 'y': 3, 'g': 'q'},
  ];

  Map<String, Object?> spec(String mark) => <String, Object?>{
    'mark': mark,
    'data': <String, Object?>{'values': rows},
    'encoding': <String, Object?>{
      'x': <String, Object?>{'field': 'x', 'type': 'quantitative'},
      'y': <String, Object?>{'field': 'y', 'type': 'quantitative'},
      'color': <String, Object?>{'field': 'g', 'type': 'nominal'},
    },
    // The two Input controls of `charts-vegadeclarativechart--default`, spread
    // over the parsed spec at `:1691`.
    'width': 600,
    'height': 400,
  };

  /// The box that story was captured at, so the numbers here are its own.
  const double capturedHeight = 351;

  testWidgets('a point spec ignores the declared height and takes the box it '
      'is given', (tester) async {
    // Taller than the declared 400 on purpose: a cell still sized from
    // `spec['height']` stops at 400 here, where upstream's `height: 100%`
    // container (`ResponsiveContainer.tsx:96`) fills the parent.
    await pump(
      tester,
      FluentVegaDeclarativeChart(
        chartSchema: FluentVegaSchema(vegaLiteSpec: spec('point')),
      ),
      height: 600,
    );
    expect(
      find.byType(FluentScatterChart),
      findsOneWidget,
      reason: 'VegaLiteSchemaAdapter.ts:1700 routes a point mark to scatter.',
    );
    expect(
      tester.getSize(find.byType(FluentScatterChart)).height,
      600,
      reason:
          'the scatter transformer forwards no dimensions, so the cell is the '
          'whole box it is given — never the spec’s 400. The legend strip comes '
          'out of it INSIDE the chart, because a single spec keeps the chart’s '
          'own legend (VegaDeclarativeChart.tsx:494 renders the shared one in '
          'the concat branch only).',
    );
  });

  testWidgets('a single spec keeps the chart’s own legend and never lifts one', (
    tester,
  ) async {
    await pump(
      tester,
      FluentVegaDeclarativeChart(
        chartSchema: FluentVegaSchema(vegaLiteSpec: spec('point')),
      ),
    );
    expect(
      find.descendant(
        of: find.byType(FluentScatterChart),
        matching: find.byType(FluentChartLegend),
      ),
      findsOneWidget,
      reason:
          'VegaDeclarativeChart.tsx:494 renders the shared <Legends> inside the '
          'CONCAT branch, and :472 is the sole writer of the _hideLegend flag '
          ':238 reads, so a single spec renders through renderSingleChart with '
          'the chart’s own legend intact — circular swatches for a scatter '
          '(ScatterChart.tsx:279), left-aligned, in series order.',
    );
    expect(
      find.byType(FluentChartLegend),
      findsOneWidget,
      reason: 'exactly one strip is drawn, not the chart’s plus a lifted row.',
    );
    expect(
      tester.getSize(find.byType(FluentScatterChart)).height,
      capturedHeight,
      reason:
          'the chart takes the whole box and CartesianChart.tsx:499-508 '
          'subtracts the strip from it internally: Oracle B records svg 600x310 '
          'with the 32-tall legend root eight pixels under it, 350 in total.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a stacked bar spec still takes the height it declares', (
    tester,
  ) async {
    await pump(
      tester,
      FluentVegaDeclarativeChart(
        chartSchema: FluentVegaSchema(
          vegaLiteSpec: <String, Object?>{...spec('bar'), 'height': 300},
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(FluentVerticalStackedBarChart)).height,
      300,
      reason:
          'VegaLiteSchemaAdapter.ts:2712 DOES return a height, so dropping the '
          'spec’s size for every kind would be the opposite error.',
    );
  });
}
