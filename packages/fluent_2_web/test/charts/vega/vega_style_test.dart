import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/vega_declarative_chart_style.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The plan's Step 1 test imports the barrel. `lib/fluent_2_web.dart` is owned
/// by task 54 and does not export this file yet, so the import is the direct
/// source path every other chart style test already uses
/// (`declarative/declarative_chart_style_test.dart:2`).
void main() {
  const states = <WidgetState>{};
  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  test(
    'the concat gap is sixteen pixels, which the Plotly grid does NOT have',
    () {
      expect(
        resolveFluentVegaDeclarativeChartStyle(
          theme,
        ).concatGap!.resolve(states),
        16,
        reason:
            "VegaDeclarativeChart.tsx:451 sets gap: '16px'; the Plotly grid at "
            'DeclarativeChart.tsx:562-569 declares only display, gridTemplateRows '
            'and gridTemplateColumns and no gap at all, so the two grids '
            'genuinely differ and this is not a shared token.',
      );
    },
  );

  test('the default sub-chart height is three hundred', () {
    expect(
      resolveFluentVegaDeclarativeChartStyle(
        theme,
      ).defaultSubChartHeight!.resolve(states),
      300,
      reason:
          'VegaDeclarativeChart.tsx:456-461, the last arm of the '
          'defaultSubHeight chain: the top-level height wins, then the '
          "sub-spec's own, then 300.",
    );
  });

  test('the resolved error text style is the danger foreground', () {
    expect(
      resolveFluentVegaDeclarativeChartStyle(
        theme,
      ).errorTextStyle!.resolve(states)!.color!.toARGB32(),
      theme.colors.statusDangerForeground1.toARGB32(),
      reason:
          'Upstream re-throws at VegaDeclarativeChart.tsx:523 instead of '
          'rendering, so this port has no captured colour to copy; the danger '
          'ramp is the Fluent slot for a failure message, and it is the same '
          'slot FluentDeclarativeChartStyle already resolves.',
    );
  });

  test('the widget style wins per property', () {
    final style = resolveFluentVegaDeclarativeChartStyle(
      theme,
      themeStyle: FluentVegaDeclarativeChartStyle(
        concatGap: WidgetStateProperty.all(4),
        defaultSubChartHeight: WidgetStateProperty.all(100),
      ),
      widgetStyle: FluentVegaDeclarativeChartStyle(
        concatGap: WidgetStateProperty.all(24),
      ),
    );
    expect(
      style.concatGap!.resolve(states),
      24,
      reason: 'The widget style has the highest precedence.',
    );
    expect(
      style.defaultSubChartHeight!.resolve(states),
      100,
      reason: 'An unset widget property keeps the theme value.',
    );
  });

  test('equal styles compare and hash equal', () {
    final a = FluentVegaDeclarativeChartStyle(
      concatGap: WidgetStateProperty.all(16),
    );
    final b = FluentVegaDeclarativeChartStyle(concatGap: a.concatGap);
    expect(a, b, reason: 'Value equality, as FluentBadgeStyle defines it.');
    expect(a.hashCode, b.hashCode, reason: 'Hash follows equality.');
  });

  test(
    'copyWith replaces only the named property and from lifts plain values',
    () {
      final base = FluentVegaDeclarativeChartStyle.from(
        concatGap: 16,
        defaultSubChartHeight: 300,
      );
      final copy = base.copyWith(concatGap: WidgetStateProperty.all(0));
      expect(
        copy.concatGap!.resolve(states),
        0,
        reason: 'copyWith replaces the property it is given.',
      );
      expect(
        copy.defaultSubChartHeight!.resolve(states),
        300,
        reason: 'copyWith leaves every other property alone.',
      );
      expect(
        FluentVegaDeclarativeChartStyle.from().errorTextStyle,
        isNull,
        reason:
            'from maps a null value to a null property, which means inherit.',
      );
    },
  );
}
