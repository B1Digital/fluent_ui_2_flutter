import 'package:fluent_2/src/charts/declarative_chart.dart';
import 'package:fluent_2/src/charts/funnel_chart.dart';
import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// `sanitizePlotlyJson` entity-encodes every string, as upstream does before
/// the DOM (`PlotlySchemaConverter.ts:185-186`), and the DOM decodes it on the
/// way in. Flutter's `Text` does not, so the port decodes once, before the
/// transformers: `R&D` and `Don't` must reach the widget as typed, not as
/// `R&amp;D` / `Don&#39;t`.
void main() {
  testWidgets('labels reach the chart decoded, exactly as typed', (
    tester,
  ) async {
    await tester.pumpWidget(
      FluentApp(
        theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
        home: const Center(
          child: SizedBox(
            width: 700,
            height: 400,
            child: SingleChildScrollView(
              child: FluentDeclarativeChart(
                chartSchema: FluentPlotlySchema(
                  plotlySchema: <String, Object?>{
                    'data': <Object?>[
                      <String, Object?>{
                        'type': 'funnel',
                        'y': <Object?>['R&D', "TK'nin", 'a<b', '"q"'],
                        'x': <Object?>[4, 3, 2, 1],
                      },
                    ],
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final chart = tester.widget<FluentFunnelChart>(
      find.byType(FluentFunnelChart),
    );
    expect(
      <Object>[for (final p in chart.data) p.stage],
      <Object>['R&D', "TK'nin", 'a<b', '"q"'],
    );
  });
}
