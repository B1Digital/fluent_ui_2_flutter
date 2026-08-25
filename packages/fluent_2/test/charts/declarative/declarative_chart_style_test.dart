import 'package:fluent_2/src/charts/declarative_chart_style.dart';
import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The plan's Step 1 test imports the barrel. `lib/fluent_2.dart` is owned
/// by task 54 and does not export this file yet, so the import is the direct
/// source path every other chart style test already uses
/// (`donut_chart_style_test.dart:3`).
void main() {
  const states = <WidgetState>{};
  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  test('the resolved title spacing is the Fluent vertical S token', () {
    final style = resolveFluentDeclarativeChartStyle(theme);
    expect(
      style.titleBottomSpacing!.resolve(states),
      8,
      reason:
          'DeclarativeChart.tsx:553 sets marginBottom to spacingVerticalS, '
          'which Fluent 2 defines as 8 px.',
    );
  });

  test('the resolved title colour is neutral foreground 1', () {
    final style = resolveFluentDeclarativeChartStyle(theme);
    expect(
      style.titleTextStyle!.resolve(states)!.color!.toARGB32(),
      theme.colors.neutralForeground1.toARGB32(),
      reason: 'DeclarativeChart.tsx:551.',
    );
  });

  test('the default export scale is five', () {
    final style = resolveFluentDeclarativeChartStyle(theme);
    expect(
      style.exportScale!.resolve(states),
      5,
      reason:
          'DeclarativeChart.tsx:441 spreads caller options AFTER the defaults, '
          'so 5 is the fallback rather than a floor.',
    );
  });

  test('the widget style wins over the theme style, per property', () {
    final style = resolveFluentDeclarativeChartStyle(
      theme,
      themeStyle: FluentDeclarativeChartStyle(
        titleBottomSpacing: WidgetStateProperty.all(20),
        exportScale: WidgetStateProperty.all(2),
      ),
      widgetStyle: FluentDeclarativeChartStyle(
        titleBottomSpacing: WidgetStateProperty.all(30),
      ),
    );
    expect(
      style.titleBottomSpacing!.resolve(states),
      30,
      reason: 'The widget style has the highest precedence.',
    );
    expect(
      style.exportScale!.resolve(states),
      2,
      reason:
          'Merging is per property: an unset widget property keeps the theme '
          'value.',
    );
  });

  test('equal styles compare equal and hash equal', () {
    final a = FluentDeclarativeChartStyle(
      titleBottomSpacing: WidgetStateProperty.all(8),
    );
    final b = FluentDeclarativeChartStyle(
      titleBottomSpacing: a.titleBottomSpacing,
    );
    expect(a, b, reason: 'Value equality, as FluentBadgeStyle defines it.');
    expect(a.hashCode, b.hashCode, reason: 'Hash follows equality.');
  });

  test('the resolved error text style is the danger foreground', () {
    final style = resolveFluentDeclarativeChartStyle(theme);
    expect(
      style.errorTextStyle!.resolve(states)!.color!.toARGB32(),
      theme.colors.statusDangerForeground1.toARGB32(),
      reason:
          'Upstream throws at DeclarativeChart.tsx:364 and :370 instead of '
          'rendering, so this port has no captured colour to copy; the danger '
          'ramp is the Fluent slot for a failure message.',
    );
  });

  test('the resolved export background is neutral background 1', () {
    final style = resolveFluentDeclarativeChartStyle(theme);
    expect(
      style.exportBackgroundColor!.resolve(states)!.toARGB32(),
      theme.colors.neutralBackground1.toARGB32(),
      reason:
          'DeclarativeChart.tsx:440 resolves colorNeutralBackground1 out of '
          'the live CSS variables before handing it to the exporter.',
    );
  });

  test(
    'copyWith replaces only the named property and from lifts plain values',
    () {
      final base = FluentDeclarativeChartStyle.from(
        titleBottomSpacing: 8,
        exportScale: 5,
      );
      final copy = base.copyWith(exportScale: WidgetStateProperty.all(3));
      expect(
        copy.exportScale!.resolve(states),
        3,
        reason: 'copyWith replaces the property it is given.',
      );
      expect(
        copy.titleBottomSpacing!.resolve(states),
        8,
        reason: 'copyWith leaves every other property alone.',
      );
      expect(
        FluentDeclarativeChartStyle.from().titleTextStyle,
        isNull,
        reason:
            'from maps a null value to a null property, which means inherit.',
      );
    },
  );
}
