import 'package:fluent_2/fluent_2.dart';
import 'package:flutter_test/flutter_test.dart';

/// The barrel is the package's published surface. Every entry below is a
/// compile-time reference, so a missing `export` line fails this file rather
/// than an assertion inside it.
void main() {
  test('the public declarative symbols reach a barrel consumer', () {
    expect(
      <Type>[
        FluentDeclarativeChart,
        FluentDeclarativeChartStyle,
        FluentDeclarativeChartTheme,
        FluentDeclarativeChartController,
        FluentPlotlySchema,
        FluentVegaDeclarativeChart,
        FluentVegaDeclarativeChartStyle,
        FluentVegaDeclarativeChartTheme,
        FluentVegaSchema,
      ],
      hasLength(9),
      reason:
          'A missing barrel line fails to compile this list rather than '
          'failing an assertion. Nine is the count of public types the four '
          'declarative files declare.',
    );
    expect(
      FluentPlotlyColorway.byDefault,
      isNotNull,
      reason:
          'The colourway enum is public because it is a widget prop '
          '(`DeclarativeChart.tsx:132`), so it must reach the barrel even '
          'though it is declared under `internal/plotly/`.',
    );
  });
}
