import 'package:fluent_2/src/charts/internal/plotly/router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, Object?> figure(
    List<Map<String, Object?>> data, [
    Map<String, Object?>? layout,
  ]) => <String, Object?>{'data': data, 'layout': ?layout};

  test('pie routes to donut', () {
    final route = mapFluentChart(
      figure(<Map<String, Object?>>[
        <String, Object?>{
          'type': 'pie',
          'labels': <Object?>['a'],
          'values': <Object?>[1],
        },
      ]),
    );
    expect(
      route.kind,
      FluentPlotlyChartKind.donut,
      reason: 'PlotlySchemaConverter.ts:507-508.',
    );
  });

  test('a vertical bar with barmode group routes to grouped, not stacked', () {
    final route = mapFluentChart(
      figure(
        <Map<String, Object?>>[
          <String, Object?>{
            'type': 'bar',
            'x': <Object?>['a'],
            'y': <Object?>[1],
          },
        ],
        <String, Object?>{'barmode': 'group'},
      ),
    );
    expect(
      route.kind,
      FluentPlotlyChartKind.groupedVerticalBar,
      reason:
          "PlotlySchemaConverter.ts:536-541 routes barmode 'group' and "
          "'overlay' to GVBC.",
    );
  });

  test('a vertical bar with object-array y routes to grouped '
      'regardless of barmode', () {
    final route = mapFluentChart(
      figure(<Map<String, Object?>>[
        <String, Object?>{
          'type': 'bar',
          'x': <Object?>['a'],
          'y': <Object?>[
            <String, Object?>{'v': 1},
          ],
        },
      ]),
    );
    expect(
      route.kind,
      FluentPlotlyChartKind.groupedVerticalBar,
      reason:
          'PlotlySchemaConverter.ts:531-534 checks isObjectArray before '
          'barmode.',
    );
  });

  test('a horizontal bar with a numeric base routes to gantt', () {
    final route = mapFluentChart(
      figure(<Map<String, Object?>>[
        <String, Object?>{
          'type': 'bar',
          'orientation': 'h',
          'x': <Object?>[5],
          'y': <Object?>['task'],
          'base': <Object?>[1],
        },
      ]),
    );
    expect(
      route.kind,
      FluentPlotlyChartKind.gantt,
      reason: 'PlotlySchemaConverter.ts:525-529.',
    );
  });

  test('funnel and funnelarea route to funnel', () {
    for (final type in const <String>['funnel', 'funnelarea']) {
      final route = mapFluentChart(
        figure(<Map<String, Object?>>[
          <String, Object?>{
            'type': type,
            'x': <Object?>[1],
            'y': <Object?>['a'],
          },
        ]),
      );
      expect(
        route.kind,
        FluentPlotlyChartKind.funnel,
        reason: 'PlotlySchemaConverter.ts:544-546 maps both to funnel.',
      );
    }
  });

  test('lines plus stacked bars resolve to fallback, lines plus grouped bars '
      'to grouped', () {
    final withStacked = mapFluentChart(
      figure(<Map<String, Object?>>[
        <String, Object?>{
          'type': 'bar',
          'x': <Object?>['a'],
          'y': <Object?>[1],
        },
        <String, Object?>{
          'type': 'scatter',
          'mode': 'lines',
          'x': <Object?>[1],
          'y': <Object?>[2],
        },
      ]),
    );
    expect(
      withStacked.kind,
      FluentPlotlyChartKind.fallback,
      reason:
          'PlotlySchemaConverter.ts:611-616 falls back when any trace is a '
          'stacked bar.',
    );

    final withGrouped = mapFluentChart(
      figure(
        <Map<String, Object?>>[
          <String, Object?>{
            'type': 'bar',
            'x': <Object?>['a'],
            'y': <Object?>[1],
          },
          <String, Object?>{
            'type': 'scatter',
            'mode': 'lines',
            'x': <Object?>[1],
            'y': <Object?>[2],
          },
        ],
        <String, Object?>{'barmode': 'group'},
      ),
    );
    expect(
      withGrouped.kind,
      FluentPlotlyChartKind.groupedVerticalBar,
      reason:
          'PlotlySchemaConverter.ts:611-616 keeps GVBC when no stacked bar is '
          'present.',
    );
  });

  test('two unrelated kinds resolve to composite', () {
    final route = mapFluentChart(
      figure(<Map<String, Object?>>[
        <String, Object?>{
          'type': 'pie',
          'labels': <Object?>['a'],
          'values': <Object?>[1],
        },
        <String, Object?>{'type': 'sankey'},
      ]),
    );
    expect(
      route.kind,
      FluentPlotlyChartKind.composite,
      reason:
          'PlotlySchemaConverter.ts:628-636 when more than one unique kind '
          'survives.',
    );
  });

  test('an invalid trace is dropped, not fatal, when a sibling survives', () {
    final route = mapFluentChart(
      figure(<Map<String, Object?>>[
        <String, Object?>{
          'type': 'bar',
          'orientation': 'h',
          'x': <Object?>['a'],
          'y': <Object?>[1],
        },
        <String, Object?>{
          'type': 'pie',
          'labels': <Object?>['a'],
          'values': <Object?>[1],
        },
      ]),
    );
    expect(
      route.isValid,
      isTrue,
      reason: 'PlotlySchemaConverter.ts:594-595 filters invalid traces.',
    );
    expect(
      route.traces.single.index,
      1,
      reason:
          'validTracesInfo carries the ORIGINAL trace index '
          '(PlotlySchemaConverter.ts:600).',
    );
  });

  test(
    'a figure with no traces but layout annotations routes to annotation',
    () {
      final route = mapFluentChart(<String, Object?>{
        'data': <Object?>[],
        'layout': <String, Object?>{
          'annotations': <Object?>[
            <String, Object?>{'text': 'hi'},
          ],
        },
      });
      expect(
        route.kind,
        FluentPlotlyChartKind.annotation,
        reason: 'PlotlySchemaConverter.ts:498-500.',
      );
      expect(
        route.traces,
        isEmpty,
        reason: 'PlotlySchemaConverter.ts:499 returns an empty trace list.',
      );
    },
  );

  test('an empty figure with no annotations is invalid', () {
    final route = mapFluentChart(<String, Object?>{'data': <Object?>[]});
    expect(
      route.isValid,
      isFalse,
      reason: 'PlotlySchemaConverter.ts:242 throws on empty data.',
    );
    expect(
      route.errorMessage,
      contains('Plotly input data is empty'),
      reason: 'PlotlySchemaConverter.ts:242 message, wrapped at :246.',
    );
  });
}
