import 'package:fluent_2/src/charts/chrome/legend.dart';
import 'package:fluent_2/src/charts/line_chart.dart';
import 'package:fluent_2/src/charts/vega_declarative_chart.dart';
import 'package:fluent_2/src/charts/vertical_stacked_bar_chart.dart';
import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The concat grid of `FluentVegaDeclarativeChart`
/// (`VegaDeclarativeChart.tsx:105-149` and `:430-497`).
///
/// Every assertion runs against a MOUNTED widget: a merge rule that is right in
/// isolation and reached by nothing is the failure mode this wave keeps
/// shipping, and `find.byType` is only satisfied when the dispatch really
/// happened.
///
/// There is no captured VegaDeclarativeChart story in Oracle B, so every
/// expectation below is hand-derived from the upstream file named beside it.
void main() {
  /// The whole test surface, 800 by 600: wide enough that a two-column
  /// `hconcat` leaves each cell a real width, and deep enough for one 300-tall
  /// cell plus the lifted legend row. A `vconcat` of two DEFAULT-height cells
  /// is 616 tall before the legend and would overflow, so the two-cell columns
  /// below declare shorter heights.
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    FluentApp(
      theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      home: Center(child: SizedBox(width: 800, height: 600, child: child)),
    ),
  );

  const rows = <Object?>[
    <String, Object?>{'c': 'a', 'v': 1, 'g': 'p'},
    <String, Object?>{'c': 'b', 'v': 2, 'g': 'q'},
  ];

  /// A colour channel and no `xOffset`, which
  /// `VegaLiteSchemaAdapter.ts:1710-1714` routes to the stacked bar.
  const sharedEncoding = <String, Object?>{
    'x': <String, Object?>{'field': 'c', 'type': 'nominal'},
    'y': <String, Object?>{'field': 'v', 'type': 'quantitative'},
    'color': <String, Object?>{'field': 'g', 'type': 'nominal'},
  };

  testWidgets('hconcat lays its sub-charts out in one row', (tester) async {
    await pump(
      tester,
      const FluentVegaDeclarativeChart(
        chartSchema: FluentVegaSchema(
          vegaLiteSpec: <String, Object?>{
            'data': <String, Object?>{'values': rows},
            'encoding': sharedEncoding,
            'hconcat': <Object?>[
              <String, Object?>{'mark': 'bar'},
              <String, Object?>{'mark': 'line'},
            ],
          },
        ),
      ),
    );
    expect(
      find.byType(FluentVerticalStackedBarChart),
      findsOneWidget,
      reason:
          'VegaDeclarativeChart.tsx:489 routes each merged sub-spec on its '
          'own, so the bar cell answers to the bar ladder.',
    );
    expect(
      find.byType(FluentLineChart),
      findsOneWidget,
      reason: 'VegaDeclarativeChart.tsx:489: and the line cell to `line`.',
    );
    final bar = tester.getTopLeft(find.byType(FluentVerticalStackedBarChart));
    final line = tester.getTopLeft(find.byType(FluentLineChart));
    expect(
      bar.dy,
      line.dy,
      reason: 'VegaDeclarativeChart.tsx:475: hconcat puts every cell on row 1.',
    );
    expect(
      line.dx,
      greaterThan(bar.dx),
      reason: 'VegaDeclarativeChart.tsx:476: the column is index + 1.',
    );
  });

  testWidgets('vconcat stacks its sub-charts in one column', (tester) async {
    await pump(
      tester,
      const FluentVegaDeclarativeChart(
        chartSchema: FluentVegaSchema(
          vegaLiteSpec: <String, Object?>{
            'data': <String, Object?>{'values': rows},
            'encoding': sharedEncoding,
            // 150 apiece so the column, its gap and its legend fit the 600-tall
            // box; the fallback to 300 is test five's job.
            'vconcat': <Object?>[
              <String, Object?>{'mark': 'bar', 'height': 150},
              <String, Object?>{'mark': 'line', 'height': 150},
            ],
          },
        ),
      ),
    );
    final bar = tester.getTopLeft(find.byType(FluentVerticalStackedBarChart));
    final line = tester.getTopLeft(find.byType(FluentLineChart));
    expect(
      bar.dx,
      line.dx,
      reason:
          'VegaDeclarativeChart.tsx:476: vconcat puts every cell in '
          'column 1.',
    );
    expect(
      line.dy,
      greaterThan(bar.dy),
      reason: 'VegaDeclarativeChart.tsx:475: the row is index + 1.',
    );
  });

  testWidgets('the sixteen-pixel gap separates the cells', (tester) async {
    await pump(
      tester,
      const FluentVegaDeclarativeChart(
        chartSchema: FluentVegaSchema(
          vegaLiteSpec: <String, Object?>{
            'data': <String, Object?>{'values': rows},
            'encoding': sharedEncoding,
            'vconcat': <Object?>[
              // 100 is an arbitrary declared height, small enough that two
              // cells and the gap fit the 600-tall box with room to spare.
              <String, Object?>{'mark': 'bar', 'height': 100},
              <String, Object?>{'mark': 'bar', 'height': 100},
            ],
          },
        ),
      ),
    );
    final cells = tester.widgetList<FluentVerticalStackedBarChart>(
      find.byType(FluentVerticalStackedBarChart),
    );
    expect(cells, hasLength(2), reason: 'Two sub-specs.');
    final first = tester.getRect(
      find.byType(FluentVerticalStackedBarChart).first,
    );
    final second = tester.getRect(
      find.byType(FluentVerticalStackedBarChart).last,
    );
    expect(
      second.top - first.bottom,
      16,
      reason: "VegaDeclarativeChart.tsx:451 sets gap: '16px'.",
    );
  });

  testWidgets('a sub-spec inherits data and encoding from the parent, per '
      'channel', (tester) async {
    await pump(
      tester,
      const FluentVegaDeclarativeChart(
        chartSchema: FluentVegaSchema(
          vegaLiteSpec: <String, Object?>{
            'data': <String, Object?>{'values': rows},
            'encoding': sharedEncoding,
            'hconcat': <Object?>[
              <String, Object?>{
                'mark': 'bar',
                'encoding': <String, Object?>{
                  'y': <String, Object?>{
                    'field': 'v',
                    'type': 'quantitative',
                    'title': 'Own',
                  },
                },
              },
            ],
          },
        ),
      ),
    );
    final chart = tester.widget<FluentVerticalStackedBarChart>(
      find.byType(FluentVerticalStackedBarChart),
    );
    expect(
      chart.props.yAxisTitle,
      'Own',
      reason:
          'VegaDeclarativeChart.tsx:466-469 spreads the child encoding over the '
          'parent, so the child wins per channel.',
    );
    expect(
      chart.data,
      isNotEmpty,
      reason:
          'VegaDeclarativeChart.tsx:465: the child declares no data, so it '
          "inherits the parent's rows.",
    );
  });

  testWidgets(
    'the sub-chart height falls back through parent, child, then three hundred',
    (tester) async {
      await pump(
        tester,
        const FluentVegaDeclarativeChart(
          chartSchema: FluentVegaSchema(
            vegaLiteSpec: <String, Object?>{
              'data': <String, Object?>{'values': rows},
              'encoding': sharedEncoding,
              'vconcat': <Object?>[
                <String, Object?>{'mark': 'bar'},
              ],
            },
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(FluentVerticalStackedBarChart)).height,
        300,
        reason:
            'VegaDeclarativeChart.tsx:456-461, the final arm — and NOT the '
            'stacked bar’s own 350 default, because the merge at :470 '
            'always writes a number into the sub-spec.',
      );
    },
  );

  testWidgets('every sub-chart hides its own legend and one shared legend is '
      'drawn', (tester) async {
    await pump(
      tester,
      const FluentVegaDeclarativeChart(
        chartSchema: FluentVegaSchema(
          vegaLiteSpec: <String, Object?>{
            'data': <String, Object?>{'values': rows},
            'encoding': sharedEncoding,
            'hconcat': <Object?>[
              <String, Object?>{'mark': 'bar'},
              <String, Object?>{'mark': 'bar'},
            ],
          },
        ),
      ),
    );
    final charts = tester.widgetList<FluentVerticalStackedBarChart>(
      find.byType(FluentVerticalStackedBarChart),
    );
    expect(charts, hasLength(2), reason: 'Two sub-specs, two cells.');
    for (final chart in charts) {
      expect(
        chart.props.hideLegend,
        isTrue,
        reason:
            'VegaDeclarativeChart.tsx:472 marks every sub-spec '
            '_hideLegend.',
      );
    }
    expect(
      find.byType(FluentChartLegend),
      findsOneWidget,
      reason:
          'VegaDeclarativeChart.tsx:494 draws one shared legend below the '
          'grid.',
    );
  });

  testWidgets('no colour field means no shared legend at all', (tester) async {
    await pump(
      tester,
      const FluentVegaDeclarativeChart(
        chartSchema: FluentVegaSchema(
          vegaLiteSpec: <String, Object?>{
            'data': <String, Object?>{'values': rows},
            'encoding': <String, Object?>{
              'x': <String, Object?>{'field': 'c', 'type': 'nominal'},
              'y': <String, Object?>{'field': 'v', 'type': 'quantitative'},
            },
            'hconcat': <Object?>[
              <String, Object?>{'mark': 'bar'},
            ],
          },
        ),
      ),
    );
    expect(
      find.byType(FluentChartLegend),
      findsNothing,
      reason:
          'VegaDeclarativeChart.tsx:494 gates on legends.length > 0, and '
          'VegaLiteSchemaAdapter.ts:2010-2017 returns none without a colour '
          'field.',
    );
  });
}
