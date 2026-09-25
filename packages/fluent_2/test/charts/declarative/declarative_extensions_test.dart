import 'package:fluent_2/src/charts/declarative_chart.dart';
import 'package:fluent_2/src/charts/horizontal_bar_chart.dart';
import 'package:fluent_2/src/charts/internal/plotly/router.dart';
import 'package:fluent_2/src/charts/sparkline.dart';
import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The two declarative routes this port adds beyond upstream
/// (`PlotlySchemaConverter.ts` has no arm for either): a trace whose Plotly
/// `meta.fluentChart` names `sparkline` or `horizontalBarChart` renders
/// `FluentSparkline` / `FluentHorizontalBarChart`, the two Fluent charts that
/// no declarative schema could reach. Without the marker every trace routes
/// exactly as upstream does.
void main() {
  Map<String, Object?> figure(
    List<Map<String, Object?>> data, [
    Map<String, Object?>? layout,
  ]) => <String, Object?>{'data': data, 'layout': ?layout};

  Map<String, Object?> sparklineTrace({Map<String, Object?>? meta}) =>
      <String, Object?>{
        'type': 'scatter',
        'mode': 'lines',
        'name': '89.7',
        'x': <Object?>[1, 2, 3, 4],
        'y': <Object?>[58.13, 140.98, 20, 89.7],
        'meta': ?meta,
      };

  List<Map<String, Object?>> partToWholeTraces({Map<String, Object?>? meta}) =>
      <Map<String, Object?>>[
        <String, Object?>{
          'type': 'bar',
          'orientation': 'h',
          'name': 'Economy',
          'y': <Object?>['TK1', 'TK2'],
          'x': <Object?>[120, 90],
          'meta': ?meta,
        },
        <String, Object?>{
          'type': 'bar',
          'orientation': 'h',
          'name': 'Business',
          'y': <Object?>['TK1', 'TK2'],
          'x': <Object?>[20, 15],
          'meta': ?meta,
        },
      ];

  group('routing', () {
    test('meta.fluentChart sparkline routes a lines scatter to sparkline', () {
      final route = mapFluentChart(
        figure(<Map<String, Object?>>[
          sparklineTrace(meta: <String, Object?>{'fluentChart': 'sparkline'}),
        ]),
      );
      expect(route.isValid, isTrue);
      expect(route.kind, FluentPlotlyChartKind.sparkline);
    });

    test('without the marker the same trace still routes to line', () {
      final route = mapFluentChart(
        figure(<Map<String, Object?>>[sparklineTrace()]),
      );
      expect(route.kind, FluentPlotlyChartKind.line);
    });

    test('meta.fluentChart horizontalBarChart routes horizontal bars', () {
      final route = mapFluentChart(
        figure(
          partToWholeTraces(
            meta: <String, Object?>{'fluentChart': 'horizontalBarChart'},
          ),
        ),
      );
      expect(route.isValid, isTrue);
      expect(route.kind, FluentPlotlyChartKind.horizontalBarChart);
    });

    test(
      'without the marker horizontal bars still route to the axis chart',
      () {
        final route = mapFluentChart(figure(partToWholeTraces()));
        expect(route.kind, FluentPlotlyChartKind.horizontalBar);
      },
    );

    test('a marker on a trace type it cannot describe is ignored', () {
      final route = mapFluentChart(
        figure(<Map<String, Object?>>[
          <String, Object?>{
            'type': 'pie',
            'labels': <Object?>['a'],
            'values': <Object?>[1],
            'meta': <String, Object?>{'fluentChart': 'sparkline'},
          },
        ]),
      );
      expect(route.kind, FluentPlotlyChartKind.donut);
    });
  });

  group('rendering', () {
    Future<void> pump(WidgetTester tester, Map<String, Object?> schema) =>
        tester.pumpWidget(
          FluentApp(
            theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
            home: Center(
              child: SizedBox(
                width: 700,
                height: 400,
                child: FluentDeclarativeChart(
                  chartSchema: FluentPlotlySchema(plotlySchema: schema),
                ),
              ),
            ),
          ),
        );

    testWidgets('a sparkline trace renders FluentSparkline', (tester) async {
      await pump(
        tester,
        figure(
          <Map<String, Object?>>[
            sparklineTrace(meta: <String, Object?>{'fluentChart': 'sparkline'}),
          ],
          <String, Object?>{'width': 120, 'height': 30, 'showlegend': true},
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final chart = tester.widget<FluentSparkline>(
        find.byType(FluentSparkline),
      );
      final series = chart.data.lineChartData!.single;
      expect(series.legend, '89.7');
      expect(
        <double>[for (final p in series.data.cast<dynamic>()) p.y as double],
        <double>[58.13, 140.98, 20, 89.7],
      );
      expect(chart.width, 120);
      expect(chart.height, 30);
      expect(chart.showLegend, isTrue);
    });

    testWidgets('sparkline defaults to 80 x 20 with no legend', (tester) async {
      await pump(
        tester,
        figure(<Map<String, Object?>>[
          sparklineTrace(meta: <String, Object?>{'fluentChart': 'sparkline'}),
        ]),
      );
      await tester.pumpAndSettle();

      final chart = tester.widget<FluentSparkline>(
        find.byType(FluentSparkline),
      );
      expect(chart.width, 80);
      expect(chart.height, 20);
      expect(chart.showLegend, isFalse);
    });

    testWidgets(
      'horizontal bar traces render one FluentHorizontalBarChart row per y',
      (tester) async {
        await pump(
          tester,
          figure(
            partToWholeTraces(
              meta: <String, Object?>{'fluentChart': 'horizontalBarChart'},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final chart = tester.widget<FluentHorizontalBarChart>(
          find.byType(FluentHorizontalBarChart),
        );
        expect(chart.variant, FluentHorizontalBarChartVariant.partToWhole);
        expect(
          <String?>[for (final row in chart.data) row.chartTitle],
          <String>['TK1', 'TK2'],
        );
        expect(
          <List<(String?, double)>>[
            for (final row in chart.data)
              <(String?, double)>[
                for (final point in row.chartData!)
                  (point.legend, point.horizontalBarChartData!.x),
              ],
          ],
          <List<(String?, double)>>[
            <(String?, double)>[('Economy', 120), ('Business', 20)],
            <(String?, double)>[('Economy', 90), ('Business', 15)],
          ],
        );
      },
    );

    testWidgets('meta.totals sets each row total and absoluteScale variant', (
      tester,
    ) async {
      await pump(
        tester,
        figure(<Map<String, Object?>>[
          <String, Object?>{
            'type': 'bar',
            'orientation': 'h',
            'name': 'Hazır',
            'y': <Object?>['TK1', 'TK2'],
            'x': <Object?>[1543, 800],
            'meta': <String, Object?>{
              'fluentChart': 'horizontalBarChart',
              'variant': 'absoluteScale',
              'totals': <Object?>[15000, 15000],
            },
          },
        ]),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final chart = tester.widget<FluentHorizontalBarChart>(
        find.byType(FluentHorizontalBarChart),
      );
      expect(chart.variant, FluentHorizontalBarChartVariant.absoluteScale);
      expect(
        <double?>[
          for (final row in chart.data)
            row.chartData!.single.horizontalBarChartData!.total,
        ],
        <double>[15000, 15000],
      );
    });
  });
}
