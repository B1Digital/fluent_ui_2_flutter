import 'package:fluent_2/src/charts/annotation_only_chart_style.dart';
import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const states = <WidgetState>{};
  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  test('the shell defaults come straight from the two upstream files', () {
    final style = resolveFluentAnnotationOnlyChartStyle(theme);
    expect(
      style.rowGap!.resolve(states),
      8.0,
      reason:
          'useAnnotationOnlyChartStyles.styles.ts:11 sets rowGap to 8px, '
          'which is what separates the title from the content box.',
    );
    expect(
      style.contentRadius!.resolve(states),
      4.0,
      reason:
          'useAnnotationOnlyChartStyles.styles.ts:20 uses '
          'borderRadiusMedium, which is 4.',
    );
    expect(
      style.defaultHeight!.resolve(states),
      650.0,
      reason: 'AnnotationOnlyChart.tsx:11 declares DEFAULT_HEIGHT = 650.',
    );
    expect(
      style.fallbackWidth!.resolve(states),
      400.0,
      reason:
          'AnnotationOnlyChart.tsx:12 declares FALLBACK_WIDTH = 400, used '
          'at :91 when nothing has been measured yet.',
    );
  });

  test('the plot background is transparent and the paper is background1', () {
    final style = resolveFluentAnnotationOnlyChartStyle(theme);
    expect(
      style.plotBackgroundColor!.resolve(states)!.toARGB32(),
      0x00000000,
      reason:
          'useAnnotationOnlyChartStyles.styles.ts:19 sets the content box '
          'to transparent; only a plotBackgroundColor prop overrides it.',
    );
    expect(
      style.paperBackgroundColor!.resolve(states)!.toARGB32(),
      theme.colors.neutralBackground1.toARGB32(),
      reason: 'useAnnotationOnlyChartStyles.styles.ts:12.',
    );
    expect(
      style.foregroundColor!.resolve(states)!.toARGB32(),
      theme.colors.neutralForeground1.toARGB32(),
      reason: 'useAnnotationOnlyChartStyles.styles.ts:13.',
    );
  });

  test('the title inherits the body1 family with centred alignment', () {
    expect(
      resolveFluentAnnotationOnlyChartStyle(
        theme,
      ).titleTextStyle!.resolve(states)!.fontFamily,
      theme.typography.body1.fontFamily,
      reason:
          'useAnnotationOnlyChartStyles.styles.ts:14 sets the root font '
          'family from typographyStyles.body1, and the .title rule at :23-25 '
          'adds nothing but text-align: center.',
    );
  });

  test('merge and equality behave like FluentBadgeStyle', () {
    final base = FluentAnnotationOnlyChartStyle.from(rowGap: 8);
    expect(
      base
          .merge(FluentAnnotationOnlyChartStyle.from(rowGap: 12))
          .rowGap!
          .resolve(states),
      12.0,
      reason: 'The argument wins for the property it sets.',
    );
    expect(
      FluentAnnotationOnlyChartStyle.from(rowGap: 8),
      equals(FluentAnnotationOnlyChartStyle.from(rowGap: 8)),
      reason: 'Value equality is required by the theme.',
    );
  });
}
