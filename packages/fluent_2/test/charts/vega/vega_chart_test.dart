import 'package:fluent_2/src/charts/chrome/legend.dart';
import 'package:fluent_2/src/charts/grouped_vertical_bar_chart.dart';
import 'package:fluent_2/src/charts/line_chart.dart';
import 'package:fluent_2/src/charts/vega_declarative_chart.dart';
import 'package:fluent_2/src/charts/vertical_bar_chart.dart';
import 'package:fluent_2/src/charts/vertical_stacked_bar_chart.dart';
import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The single-spec render path of `FluentVegaDeclarativeChart`
/// (`VegaDeclarativeChart.tsx:389-528`), mounted rather than called: guard the
/// depth, clone, auto-correct, route, dispatch.
///
/// Every assertion runs against a MOUNTED widget, because the defect this wave
/// keeps shipping is a transformer that is green in isolation and reached by
/// nothing — `find.byType(FluentVerticalBarChart)` is only satisfied if the
/// dispatch really happened.
///
/// There is no captured VegaDeclarativeChart story in Oracle B, so every
/// expectation below is hand-derived from the upstream file named beside it.
void main() {
  /// 400 is deep enough for one 350-tall stacked-bar cell plus the lifted
  /// legend row; an unsized kind takes the whole box.
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    FluentApp(
      theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      home: Center(child: SizedBox(width: 700, height: 400, child: child)),
    ),
  );

  const barSpec = <String, Object?>{
    'mark': 'bar',
    'data': <String, Object?>{
      'values': <Object?>[
        <String, Object?>{'c': 'a', 'v': 1},
        <String, Object?>{'c': 'b', 'v': 2},
      ],
    },
    'encoding': <String, Object?>{
      'x': <String, Object?>{'field': 'c', 'type': 'nominal'},
      'y': <String, Object?>{'field': 'v', 'type': 'quantitative'},
    },
  };

  /// A colour-encoded bar spec with two distinct categories, which
  /// `VegaLiteSchemaAdapter.ts:1710-1714` routes to the stacked bar because it
  /// declares a colour channel and no `xOffset`.
  const colouredBarSpec = <String, Object?>{
    'mark': 'bar',
    'data': <String, Object?>{
      'values': <Object?>[
        <String, Object?>{'c': 'a', 'v': 1, 'g': 'p'},
        <String, Object?>{'c': 'b', 'v': 2, 'g': 'q'},
      ],
    },
    'encoding': <String, Object?>{
      'x': <String, Object?>{'field': 'c', 'type': 'nominal'},
      'y': <String, Object?>{'field': 'v', 'type': 'quantitative'},
      'color': <String, Object?>{'field': 'g', 'type': 'nominal'},
    },
  };

  testWidgets('a bar spec renders a vertical bar chart', (tester) async {
    await pump(
      tester,
      const FluentVegaDeclarativeChart(
        chartSchema: FluentVegaSchema(vegaLiteSpec: barSpec),
      ),
    );
    expect(
      find.byType(FluentVerticalBarChart),
      findsOneWidget,
      reason:
          'VegaDeclarativeChart.tsx:191 maps the bar kind to the vertical bar '
          'chart.',
    );
  });

  testWidgets('the caller spec is never mutated by auto-correction', (
    tester,
  ) async {
    final spec = <String, Object?>{
      'mark': 'bar',
      'data': <String, Object?>{
        'values': <Object?>[
          <String, Object?>{'c': 'text', 'v': 1},
        ],
      },
      'encoding': <String, Object?>{
        'x': <String, Object?>{'field': 'c', 'type': 'quantitative'},
        'y': <String, Object?>{'field': 'v', 'type': 'quantitative'},
      },
    };
    await pump(
      tester,
      FluentVegaDeclarativeChart(
        chartSchema: FluentVegaSchema(vegaLiteSpec: spec),
      ),
    );
    expect(
      ((spec['encoding']! as Map<String, Object?>)['x']!
          as Map<String, Object?>)['type'],
      'quantitative',
      reason:
          'hardened: VegaLiteSchemaAdapter.ts:1553 mutates the spec it is '
          'handed; the widget clones first so the caller object survives a '
          'rebuild unchanged.',
    );
  });

  testWidgets('a spec deeper than fifteen levels renders the error builder', (
    tester,
  ) async {
    Object? nested = 'leaf';
    for (var i = 0; i < 20; i++) {
      nested = <String, Object?>{'k': nested};
    }
    await pump(
      tester,
      FluentVegaDeclarativeChart(
        chartSchema: FluentVegaSchema(
          vegaLiteSpec: <String, Object?>{'mark': 'bar', 'deep': nested},
        ),
        errorBuilder: (context, message) => Text('failed: $message'),
      ),
    );
    expect(
      find.textContaining('Maximum JSON depth exceeded'),
      findsOneWidget,
      reason: 'VegaDeclarativeChart.tsx:398, :51.',
    );
  });

  testWidgets('an unroutable spec renders the error builder', (tester) async {
    await pump(
      tester,
      FluentVegaDeclarativeChart(
        chartSchema: const FluentVegaSchema(
          vegaLiteSpec: <String, Object?>{'mark': 'bar'},
        ),
        errorBuilder: (context, message) => Text('failed: $message'),
      ),
    );
    expect(
      find.textContaining('No valid unit specs'),
      findsOneWidget,
      reason:
          'VegaLiteSchemaAdapter.ts:1166 throws for a spec that normalises to '
          'nothing and VegaDeclarativeChart.tsx:523 re-throws it; a Flutter '
          'build() must not, so the message routes to errorBuilder.',
    );
  });

  testWidgets('the spec description becomes a semantics label', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      const FluentVegaDeclarativeChart(
        chartSchema: FluentVegaSchema(
          vegaLiteSpec: <String, Object?>{
            ...barSpec,
            'description': 'Sales by region',
          },
        ),
      ),
    );
    expect(
      tester
          .getSemantics(find.byType(FluentVegaDeclarativeChart))
          .label
          .contains('Sales by region'),
      isTrue,
      reason:
          'accessibility: VegaLiteTypes.ts:697 declares description and the '
          'adapter never reads it. Mapping it to Semantics(label:) is a cheap, '
          'real accessibility win and falls under the spec section 5.2 '
          'exception.',
    );
    handle.dispose();
  });

  testWidgets('a single spec keeps the chart-owned legend, and the selection '
      'does NOT round-trip through onSchemaChange', (tester) async {
    var fired = false;
    await pump(
      tester,
      FluentVegaDeclarativeChart(
        chartSchema: const FluentVegaSchema(vegaLiteSpec: colouredBarSpec),
        onSchemaChange: (schema) => fired = true,
      ),
    );
    expect(
      find.byType(FluentVerticalStackedBarChart),
      findsOneWidget,
      reason:
          'VegaLiteSchemaAdapter.ts:1714 stacks a colour-encoded bar with no '
          'xOffset.',
    );
    // `VegaDeclarativeChart.tsx:494` renders the shared `<Legends>` inside the
    // CONCAT branch, and `:472` is the sole writer of the `_hideLegend` flag
    // `:238` reads — so a single spec goes through `renderSingleChart` and
    // keeps the chart's own legend. This widget used to lift one here, which
    // drew the wrong strip: square swatches in first-seen order, centred.
    expect(
      find.descendant(
        of: find.byType(FluentVerticalStackedBarChart),
        matching: find.byType(FluentChartLegend),
      ),
      findsOneWidget,
      reason: 'the chart-owned legend is the only one, and it is inside it.',
    );
    await tester.tap(find.text('P'));
    await tester.pumpAndSettle();

    // GAP, deliberate and measured — see the parity pin on
    // `charts-vegadeclarativechart--default`. Upstream gets this round-trip for
    // free by spreading `legendProps` into the chart it renders (`:243`); here
    // only `FluentAreaChart` and `FluentPolarChart` take `selectedLegends` at
    // all, so a stacked bar's own legend has nowhere to report to. Closing it
    // is that parameter on eight widgets plus a pass-through in eleven
    // transformers — not a change to this file. Asserted rather than deleted so
    // the day it starts working is a failing test and not a silent change.
    expect(
      fired,
      isFalse,
      reason:
          'the tap selects inside the chart. When the eight widgets grow '
          '`selectedLegends`, wire it back to `onSchemaChange` and flip this.',
    );
  });

  testWidgets('a grouped bar spec keeps its own legend and grows no second', (
    tester,
  ) async {
    await pump(
      tester,
      const FluentVegaDeclarativeChart(
        chartSchema: FluentVegaSchema(
          vegaLiteSpec: <String, Object?>{
            'mark': 'bar',
            'data': <String, Object?>{
              'values': <Object?>[
                <String, Object?>{'c': 'a', 'v': 1, 'g': 'p'},
                <String, Object?>{'c': 'b', 'v': 2, 'g': 'q'},
              ],
            },
            'encoding': <String, Object?>{
              'x': <String, Object?>{'field': 'c', 'type': 'nominal'},
              'y': <String, Object?>{'field': 'v', 'type': 'quantitative'},
              'color': <String, Object?>{'field': 'g', 'type': 'nominal'},
              'xOffset': <String, Object?>{'field': 'g'},
            },
          },
        ),
      ),
    );
    expect(
      find.byType(FluentGroupedVerticalBarChart),
      findsOneWidget,
      reason: 'VegaLiteSchemaAdapter.ts:1712, an xOffset channel groups.',
    );
    expect(
      find.byType(FluentChartLegend),
      findsOneWidget,
      reason:
          'transformVegaToGroupedBar never sets hideLegend '
          '(VegaLiteSchemaAdapter.ts:2819-2828 passes none), so the widget '
          'leaves the legend to the chart rather than drawing a second one.',
    );
  });

  testWidgets('a changed selectedLegends list resets the selection', (
    tester,
  ) async {
    const a = FluentVegaSchema(
      vegaLiteSpec: barSpec,
      selectedLegends: <String>['x'],
    );
    const b = FluentVegaSchema(vegaLiteSpec: barSpec);
    await pump(tester, const FluentVegaDeclarativeChart(chartSchema: a));
    final state = tester.state<State<FluentVegaDeclarativeChart>>(
      find.byType(FluentVegaDeclarativeChart),
    );
    expect(
      (state as dynamic).activeLegends,
      <String>['x'],
      reason:
          'VegaDeclarativeChart.tsx:404 seeds the state from selectedLegends, '
          'so the reset below is a change and not a no-op.',
    );
    await pump(tester, const FluentVegaDeclarativeChart(chartSchema: b));
    expect(
      (state as dynamic).activeLegends,
      isEmpty,
      reason:
          'VegaDeclarativeChart.tsx:413-415 watches '
          'chartSchema.selectedLegends alone, not the whole schema — a '
          'narrower dependency than the Plotly '
          'widget uses.',
    );
  });

  testWidgets(
    'a layered spec that is not a bar-plus-line combo renders only the first '
    'layer',
    (tester) async {
      await pump(
        tester,
        const FluentVegaDeclarativeChart(
          chartSchema: FluentVegaSchema(
            vegaLiteSpec: <String, Object?>{
              'layer': <Object?>[
                <String, Object?>{'mark': 'line'},
                <String, Object?>{'mark': 'area'},
              ],
              'data': <String, Object?>{
                'values': <Object?>[
                  <String, Object?>{'x': 1, 'y': 2},
                ],
              },
              'encoding': <String, Object?>{
                'x': <String, Object?>{'field': 'x', 'type': 'quantitative'},
                'y': <String, Object?>{'field': 'y', 'type': 'quantitative'},
              },
            },
          ),
        ),
      );
      expect(
        find.byType(FluentLineChart),
        findsOneWidget,
        reason:
            'VegaDeclarativeChart.tsx:500-512 detects the case and '
            'deliberately does nothing, so the first layer alone is rendered. '
            '// parity',
      );
    },
  );
}
