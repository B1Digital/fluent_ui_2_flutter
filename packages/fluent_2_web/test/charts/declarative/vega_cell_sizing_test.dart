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
    final legend = tester.getSize(find.byType(FluentChartLegend)).height;
    expect(
      tester.getSize(find.byType(FluentScatterChart)).height,
      600 - legend,
      reason:
          'the scatter transformer forwards no dimensions, so the cell is the '
          'box it is given less the legend strip — never the spec’s 400.',
    );
  });

  testWidgets('the lifted legend row comes out of the chart’s own box, not out '
      'from under it', (tester) async {
    await pump(
      tester,
      FluentVegaDeclarativeChart(
        chartSchema: FluentVegaSchema(vegaLiteSpec: spec('point')),
      ),
    );
    final legend = tester.getSize(find.byType(FluentChartLegend)).height;
    expect(
      tester.getSize(find.byType(FluentScatterChart)).height,
      capturedHeight - legend,
      reason:
          'CartesianChart.tsx:499-508 subtracts the legend strip from the '
          'container height BEFORE the svg is sized, and Oracle B records the '
          'result: svg 600x310 with the 32-tall legend root eight pixels under '
          'it, 350 in total.',
    );
    expect(
      tester.takeException(),
      isNull,
      reason:
          'a chart that keeps the whole box and puts the legend below it '
          'overflows by exactly the strip.',
    );
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
