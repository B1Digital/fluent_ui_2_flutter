import 'package:fluent_2/src/charts/declarative_chart.dart';
import 'package:fluent_2/src/charts/gauge_chart.dart';
import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// An `indicator` trace routes to the gauge (`PlotlySchemaConverter.ts:516`)
/// and `transformPlotlyToGauge` hands the chart `layout.height ?? 220`. The
/// declarative widget stacks its cells in a `Column`, so the gauge receives an
/// unbounded height; it has to size itself from that `height` rather than
/// throwing a flex error that `errorBuilder` never sees.
void main() {
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

  testWidgets('an indicator trace renders a gauge without a layout error', (
    tester,
  ) async {
    await pump(tester, <String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'indicator',
          'mode': 'gauge+number',
          'value': 72,
          'gauge': <String, Object?>{
            'axis': <String, Object?>{
              'range': <Object?>[0, 100],
            },
          },
        },
      ],
      'layout': <String, Object?>{'title': 'Occupancy'},
    });
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(FluentGaugeChart), findsOneWidget);
  });

  testWidgets('layout.height becomes the gauge arc height', (tester) async {
    await pump(tester, <String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'indicator',
          'mode': 'gauge',
          'value': 40,
          'gauge': <String, Object?>{
            'axis': <String, Object?>{
              'range': <Object?>[0, 100],
            },
            'steps': <Object?>[
              <String, Object?>{
                'range': <Object?>[0, 50],
                'name': 'Low',
              },
              <String, Object?>{
                'range': <Object?>[50, 100],
                'name': 'High',
              },
            ],
          },
        },
      ],
      'layout': <String, Object?>{'height': 260},
    });
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(FluentGaugeChart)).height,
      greaterThanOrEqualTo(260),
    );
  });
}
