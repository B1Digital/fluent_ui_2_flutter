import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/chart_table_style.dart';
import 'package:fluent_2_web/src/charts/internal/chart_text_styles.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every default here comes from `useChartTableStyles.styles.ts:28-53` and
/// `ChartTable.tsx:93-94`. The header weight is the interesting one: the slot
/// spreads `typographyStyles.caption1` (12/16 **regular**) and then overrides
/// `fontWeight` with `fontWeightSemibold` on the very next line, so the header
/// is 12/16 semibold while the body stays 12/16 regular.
void main() {
  const states = <WidgetState>{};
  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  test('header type is caption1 metrics at semibold', () {
    final style = resolveFluentChartTableStyle(theme);
    final header = style.headerTextStyle!.resolve(states)!;
    expect(
      header.fontSize,
      12.0,
      reason:
          'useChartTableStyles.styles.ts:32 spreads typographyStyles.'
          'caption1, which is 12/16.',
    );
    expect(
      header.fontWeight,
      FluentFontWeight.semibold,
      reason:
          'useChartTableStyles.styles.ts:33 overrides fontWeight with '
          'fontWeightSemibold immediately after the caption1 spread.',
    );
  });

  test('body type keeps caption1 regular', () {
    final body = resolveFluentChartTableStyle(
      theme,
    ).bodyTextStyle!.resolve(states);
    expect(
      body!.fontWeight,
      FluentFontWeight.regular,
      reason:
          'useChartTableStyles.styles.ts:45 spreads caption1 with no '
          'weight override.',
    );
  });

  test('borders are 2px in colorNeutralStroke2 and cells are padded 8 all '
      'round', () {
    final style = resolveFluentChartTableStyle(theme);
    expect(
      style.borderWidth!.resolve(states),
      2.0,
      reason:
          'useChartTableStyles.styles.ts:38 uses strokeWidthThick, which '
          'is 2.',
    );
    expect(
      style.borderColor!.resolve(states)!.toARGB32(),
      theme.colors.neutralStroke2.toARGB32(),
      reason:
          'useChartTableStyles.styles.ts:38 strokes with '
          'colorNeutralStroke2.',
    );
    expect(
      style.cellPadding!.resolve(states),
      const EdgeInsets.all(8),
      reason:
          'useChartTableStyles.styles.ts:36 sets `padding: '
          'spacingHorizontalS` as a single-value shorthand, so all four sides '
          'get 8.',
    );
    expect(
      style.headerBackgroundColor!.resolve(states)!.toARGB32(),
      theme.colors.neutralBackground3.toARGB32(),
      reason: 'useChartTableStyles.styles.ts:34.',
    );
  });

  test('the default height is 650 and the title reserves 30', () {
    final style = resolveFluentChartTableStyle(theme);
    expect(
      style.defaultHeight!.resolve(states),
      650.0,
      reason: 'ChartTable.tsx:94 falls back to 650 for a non-numeric height.',
    );
    expect(
      style.titleHeight!.resolve(states),
      30.0,
      reason:
          'ChartTable.tsx:93 reserves 30 when chartTitle is set and 0 '
          'otherwise.',
    );
  });

  test('the title slot matches the shared chart-title type and background', () {
    final style = resolveFluentChartTableStyle(theme);
    expect(
      style.titleTextStyle!.resolve(states),
      FluentChartTextStyles.of(theme).chartTitle,
      reason:
          'useChartTableStyles.styles.ts:54 assigns getChartTitleStyles() '
          'verbatim, which is the shared chartTitle slot.',
    );
    expect(
      style.titleBackgroundColor!.resolve(states)!.toARGB32(),
      theme.colors.neutralBackground1.toARGB32(),
      reason:
          'useChartTableStyles.styles.ts:55-56 fills the svgTooltip slot '
          'with colorNeutralBackground1.',
    );
    expect(
      style.cellForegroundColor!.resolve(states)!.toARGB32(),
      theme.colors.neutralForeground1.toARGB32(),
      reason:
          'useChartTableStyles.styles.ts:35 and :48 both use '
          'colorNeutralForeground1.',
    );
  });

  test('merge, copyWith and equality behave like FluentBadgeStyle', () {
    final base = FluentChartTableStyle.from(borderWidth: 2, titleHeight: 30);
    final merged = base.merge(FluentChartTableStyle.from(borderWidth: 1));
    expect(
      merged.borderWidth!.resolve(states),
      1.0,
      reason: 'The argument wins for the property it sets.',
    );
    expect(
      merged.titleHeight!.resolve(states),
      30.0,
      reason: 'merge is per-property.',
    );
    expect(
      base.copyWith(borderWidth: null),
      equals(base),
      reason: 'copyWith(null) is the identity for that property.',
    );
    expect(
      base.merge(null),
      same(base),
      reason: 'merge(null) returns the receiver untouched.',
    );
    expect(
      FluentChartTableStyle.from(borderWidth: 2).hashCode,
      FluentChartTableStyle.from(borderWidth: 2).hashCode,
      reason: 'Equal styles hash equally.',
    );
  });
}
