import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:fluent_2_web/src/charts/internal/plotly/color_adapter.dart';
import 'package:fluent_2_web/src/charts/internal/plotly/transform_bar.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FluentGanttChart build(Map<String, Object?> input) => transformPlotlyToGantt(
    input,
    isMultiPlot: false,
    colorMap: <String, String>{},
    colorwayType: FluentPlotlyColorway.byDefault,
    isDark: false,
  );

  test('a bar-with-base gantt reads its span from base and x', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'bar',
          'orientation': 'h',
          'base': <Object?>[10],
          'x': <Object?>[5],
          'y': <Object?>['task'],
        },
      ],
    });
    final span = chart.data.single.x;
    expect(
      span.start,
      10,
      reason: 'PlotlySchemaAdapter.ts:2342: base is the span start.',
    );
    expect(
      span.end,
      15,
      reason: 'PlotlySchemaAdapter.ts:2343: x is the duration, added to base.',
    );
  });

  test(
    'a scatter-derived gantt walks y with stride five and averages the corner '
    'rows',
    () {
      final chart = build(<String, Object?>{
        'data': <Object?>[
          <String, Object?>{
            'type': 'scatter',
            'mode': 'none',
            'fill': 'toself',
            // Two closed rectangles, five points each. The second sits on
            // negative rows, which is the only midpoint where JavaScript's
            // half-up Math.round and Dart's half-away-from-zero `round()`
            // disagree — without it the assertion below cannot tell them apart.
            'x': <Object?>[0, 5, 5, 0, null, 0, 5, 5, 0, null],
            'y': <Object?>[1, 1, 2, 2, null, -2, -2, -1, -1, null],
          },
        ],
      });
      expect(
        chart.data.map((FluentGanttChartDataPoint p) => p.y).toList(),
        <num>[2, -1],
        reason:
            'PlotlySchemaAdapter.ts:2371 computes Math.round((y[i] + y[i + 3]) '
            '/ 2), so (1 + 2) / 2 = 1.5 rounds half-UP to 2 and '
            '(-2 + -1) / 2 = -1.5 rounds half-UP to -1 under jsRound — Dart\'s '
            'own round() would give -2.',
      );
      final span = chart.data.first.x;
      expect(
        <Object>[span.start, span.end],
        <Object>[0, 5],
        reason:
            'PlotlySchemaAdapter.ts:2361-2362 and :2368-2369: the span runs '
            'from the first corner to the second, with no duration addition.',
      );
    },
  );

  test('the injected scalar defaults', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'bar',
          'orientation': 'h',
          'base': <Object?>[0],
          'x': <Object?>[1],
          'y': <Object?>['a'],
        },
      ],
    });
    expect(
      chart.props.hideTickOverlap,
      isTrue,
      reason: 'PlotlySchemaAdapter.ts:2384.',
    );
    expect(
      chart.props.noOfCharsToTruncate,
      20,
      reason: 'PlotlySchemaAdapter.ts:2386.',
    );
    expect(
      chart.props.showYAxisLables,
      isTrue,
      reason: 'PlotlySchemaAdapter.ts:2381.',
    );
    expect(
      chart.props.showYAxisLablesTooltip,
      isTrue,
      reason: 'PlotlySchemaAdapter.ts:2387.',
    );
    expect(chart.roundCorners, isTrue, reason: 'PlotlySchemaAdapter.ts:2388.');
    expect(
      chart.useUtc,
      isFalse,
      reason:
          'PlotlySchemaAdapter.ts:2389, the chart-level flag the Gantt '
          'render path reads (gantt_chart.dart:219).',
    );
    expect(
      chart.props.useUTC,
      isFalse,
      reason:
          'PlotlySchemaAdapter.ts:2389 again, for the shared cartesian '
          'shell (cartesian_chart.dart:755).',
    );
  });

  test('date bases produce DateTime spans', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'bar',
          'orientation': 'h',
          'base': <Object?>['2024-01-01'],
          'x': <Object?>[86400000],
          'y': <Object?>['task'],
        },
      ],
      // The plan's fixture omits this, and without it `getAxisType` infers a
      // LINEAR x axis from the numeric `x` column (`:4163`) — a date base then
      // resolves to null and collapses to 0 at `:2310`. The declared type is
      // what makes `:2312`'s `isXDate` true.
      'layout': <String, Object?>{
        'xaxis': <String, Object?>{'type': 'date'},
      },
    });
    expect(
      chart.data.single.x.start,
      isA<DateTime>(),
      reason:
          'A date base yields a date span, which is what the gantt axis '
          'expects (PlotlySchemaAdapter.ts:2347).',
    );
    expect(
      (chart.data.single.x.end as DateTime).difference(
        chart.data.single.x.start as DateTime,
      ),
      const Duration(days: 1),
      reason:
          'PlotlySchemaAdapter.ts:2348 adds the duration in milliseconds to '
          'the epoch base, so 86400000 is exactly one day.',
    );
  });

  test(
    'a marker-only scatter overlay is dropped before the legend is built',
    () {
      final chart = build(<String, Object?>{
        'data': <Object?>[
          <String, Object?>{
            'type': 'scatter',
            'mode': 'markers',
            'x': <Object?>[1],
            'y': <Object?>[1],
          },
          <String, Object?>{
            'type': 'bar',
            'orientation': 'h',
            'name': 'kept',
            'base': <Object?>[0],
            'x': <Object?>[1],
            'y': <Object?>['a'],
          },
        ],
      });
      expect(
        chart.data.single.legend,
        'kept',
        reason:
            'PlotlySchemaAdapter.ts:2303 filters the milestone overlay before '
            ':2304 builds the names, so the bar is the only trace and '
            "getLegendProps takes the single-trace branch (`data[0].name || ''` "
            'at :3572). Unfiltered it would be trace 1 of 2 and read '
            "'Series 2' (:3575).",
      );
    },
  );

  testWidgets('a transformed figure mounts and reaches the render delegate', (
    tester,
  ) async {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'bar',
          'orientation': 'h',
          'name': 'planned',
          'base': <Object?>[0],
          'x': <Object?>[5],
          'y': <Object?>['design'],
        },
        <String, Object?>{
          'type': 'bar',
          'orientation': 'h',
          'name': 'active',
          'base': <Object?>[5],
          'x': <Object?>[5],
          'y': <Object?>['build'],
        },
      ],
    });
    await tester.pumpWidget(
      FluentApp(
        theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
        home: Center(
          // Large enough that the plot area survives the legend and axis
          // reservations rather than collapsing to nothing.
          child: SizedBox(width: 500, height: 400, child: chart),
        ),
      ),
    );
    final delegate =
        tester
                .widget<FluentCartesianChart>(find.byType(FluentCartesianChart))
                .delegate
            as FluentGanttChartDelegate;
    expect(
      delegate.points.map((FluentGanttChartDataPoint p) => p.legend).toList(),
      <String>['planned', 'active'],
      reason:
          'the legend names this transformer copies off the traces '
          '(PlotlySchemaAdapter.ts:2315 onto :2351) reach the delegate a real '
          'mounted FluentGanttChart paints from. Task 28 owns the production '
          'call site, so this is the proof the produced widget is consumable '
          'rather than a shape only a unit test ever reads.',
    );
  });
}
