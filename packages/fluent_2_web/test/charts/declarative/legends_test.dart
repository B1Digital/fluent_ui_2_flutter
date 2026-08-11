import 'dart:ui' show Color;

import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:fluent_2_web/src/charts/internal/plotly/color_adapter.dart';
import 'package:fluent_2_web/src/charts/internal/plotly/legends.dart';
import 'package:fluent_2_web/src/charts/internal/plotly/router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dash, dashdot and dot all draw a dotted-line swatch', () {
    for (final dash in <String>['dot', 'dash', 'dashdot']) {
      expect(
        getLegendShape(<String, Object?>{
          'line': <String, Object?>{'dash': dash},
        }),
        FluentChartLegendShape.dottedLine,
        reason: 'PlotlySchemaAdapter.ts:3481-3482.',
      );
    }
  });

  test('longdash is NOT a dotted line', () {
    expect(
      getLegendShape(<String, Object?>{
        'line': <String, Object?>{'dash': 'longdash'},
      }),
      FluentChartLegendShape.defaultShape,
      reason:
          'PlotlySchemaAdapter.ts:3481 lists only dot, dash and dashdot; '
          "'longdash' and 'longdashdot' fall through. // parity",
    );
  });

  test('a markers mode draws a circle', () {
    expect(
      getLegendShape(<String, Object?>{'mode': 'lines+markers'}),
      FluentChartLegendShape.circle,
      reason: 'PlotlySchemaAdapter.ts:3484.',
    );
  });

  test('the all-up legend is empty when every trace opts out', () {
    final props = getAllupLegendsProps(
      <Object?>[
        <String, Object?>{'showlegend': false, 'name': 'a'},
      ],
      <String, Object?>{},
      <FluentPlotlyTraceInfo>[
        const FluentPlotlyTraceInfo(index: 0, kind: FluentPlotlyChartKind.line),
      ],
      <String, String>{},
      colorwayType: FluentPlotlyColorway.byDefault,
      isDark: false,
    );
    expect(
      props.legends,
      isEmpty,
      reason:
          'PlotlySchemaAdapter.ts:3498-3502 requires at least one showlegend '
          'true-or-absent.',
    );
  });

  test('a plot trace contributes one legend per legendgroup and none without '
      'one', () {
    final props = getAllupLegendsProps(
      <Object?>[
        <String, Object?>{'name': 'a', 'legendgroup': 'g1'},
        <String, Object?>{'name': 'b', 'legendgroup': 'g1'},
        <String, Object?>{'name': 'c'},
      ],
      <String, Object?>{},
      <FluentPlotlyTraceInfo>[
        const FluentPlotlyTraceInfo(index: 0, kind: FluentPlotlyChartKind.line),
        const FluentPlotlyTraceInfo(index: 1, kind: FluentPlotlyChartKind.line),
        const FluentPlotlyTraceInfo(index: 2, kind: FluentPlotlyChartKind.line),
      ],
      <String, String>{},
      colorwayType: FluentPlotlyColorway.byDefault,
      isDark: false,
    );
    expect(
      props.legends.map((l) => l.title).toList(),
      <String>['g1'],
      reason:
          'PlotlySchemaAdapter.ts:3540 keys plot legends on legendgroup, '
          'dedupes at :3550, and a trace with no legendgroup contributes '
          'nothing.',
    );
  });

  test('the all-up legend always centres, wraps and multi-selects', () {
    final props = getAllupLegendsProps(
      <Object?>[
        <String, Object?>{'name': 'a', 'legendgroup': 'g'},
      ],
      <String, Object?>{},
      <FluentPlotlyTraceInfo>[
        const FluentPlotlyTraceInfo(index: 0, kind: FluentPlotlyChartKind.line),
      ],
      <String, String>{},
      colorwayType: FluentPlotlyColorway.byDefault,
      isDark: false,
    );
    expect(props.centerLegends, isTrue, reason: 'PlotlySchemaAdapter.ts:3563.');
    expect(
      props.enabledWrapLines,
      isTrue,
      reason: 'PlotlySchemaAdapter.ts:3564.',
    );
    expect(
      props.canSelectMultipleLegends,
      isTrue,
      reason: 'PlotlySchemaAdapter.ts:3565.',
    );
  });

  test('a per-chart legend hides on a single trace and names it from '
      'data[0]', () {
    final legend = getLegendProps(
      <Object?>[
        <String, Object?>{'name': 'only'},
      ],
      null,
      isMultiPlot: false,
    );
    expect(
      legend.hideLegend,
      isTrue,
      reason:
          'PlotlySchemaAdapter.ts:3580 hides when fewer than two legends and '
          'showlegend is not explicitly true, and :3584 folds that into '
          'hideLegend.',
    );
    expect(legend.names, <String>[
      'only',
    ], reason: 'PlotlySchemaAdapter.ts:3572.');
  });

  test('a per-chart legend names unnamed series Series N, one-based', () {
    final legend = getLegendProps(
      <Object?>[<String, Object?>{}, <String, Object?>{}],
      <String, Object?>{'showlegend': true},
      isMultiPlot: false,
    );
    expect(legend.names, <String>[
      'Series 1',
      'Series 2',
    ], reason: 'PlotlySchemaAdapter.ts:3575.');
    expect(
      legend.hideLegend,
      isFalse,
      reason: 'showlegend true forces the legend on.',
    );
  });

  test('multi-plot always hides the per-chart legend', () {
    final legend = getLegendProps(
      <Object?>[
        <String, Object?>{'name': 'a'},
        <String, Object?>{'name': 'b'},
      ],
      <String, Object?>{'showlegend': true},
      isMultiPlot: true,
    );
    expect(
      legend.hideLegend,
      isTrue,
      reason: 'PlotlySchemaAdapter.ts:3584 short-circuits on isMultiPlot.',
    );
  });

  test('an unparseable declared colour seeds the colour map and paints from '
      'it', () {
    final colorMap = <String, String>{};
    final props = getAllupLegendsProps(
      <Object?>[
        <String, Object?>{
          'legendgroup': 'g',
          'line': <String, Object?>{'color': 'not-a-colour'},
        },
      ],
      <String, Object?>{},
      <FluentPlotlyTraceInfo>[
        const FluentPlotlyTraceInfo(index: 0, kind: FluentPlotlyChartKind.line),
      ],
      colorMap,
      colorwayType: FluentPlotlyColorway.byDefault,
      isDark: false,
    );
    expect(
      colorMap,
      <String, String>{'Label_0': '#637cef'},
      reason:
          'PlotlyColorAdapter.ts:167-168 hands an unparseable single colour to '
          "getColor under `Label_0`, so this legend consumes the map's first "
          'qualitative slot before any transformer runs — the ordering '
          'DeclarativeChart.tsx:535 depends on, and the thing that silently '
          'shifts every downstream series colour if a lookup is added here',
    );
    expect(
      props.legends.single.color,
      const Color(0xFF637CEF),
      reason:
          'internal/data_viz_palette.dart:173, cornflower.tint10 — the swatch '
          'is the same colour the map now holds, parsed by the shared '
          'parseCssColour (internal/plotly/common.dart:17), not a second '
          "reading of the palette that could drift from the chart's",
    );
  });
}
