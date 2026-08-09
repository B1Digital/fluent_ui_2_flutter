import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/internal/chart_text_styles.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
  final styles = FluentChartTextStyles.of(theme);

  group('FluentChartTextStyles.of', () {
    test('axisTick is caption2Strong at 10/14 semibold', () {
      expect(
        styles.axisTick.fontSize,
        10,
        reason:
            'useCartesianChartStyles.styles.ts:64 uses caption2Strong, which '
            'the web ramp defines as s(10, 14, semibold) — the canvas fallback '
            "font at utilities.ts:1267 is '600 10px \"Segoe UI\"'.",
      );
      expect(
        styles.axisTick.fontWeight,
        theme.typography.caption2Strong.fontWeight,
        reason: 'Same token, same weight.',
      );
      expect(
        styles.axisTick.color?.toARGB32(),
        theme.colors.neutralForeground1.toARGB32(),
        reason: 'useCartesianChartStyles.styles.ts:63 fill.',
      );
    });

    test('axisTitle and axisAnnotation resolve to the same style', () {
      expect(
        styles.axisAnnotation,
        styles.axisTitle,
        reason:
            'useCartesianChartStyles.styles.ts:59-60 assigns '
            'getAxisTitleStyle() to both slots.',
      );
      expect(
        styles.axisTitle.fontSize,
        theme.typography.caption2Strong.fontSize,
        reason: 'Common.styles.ts:53.',
      );
    });

    test('barLabel is caption1Strong', () {
      expect(
        styles.barLabel.fontSize,
        theme.typography.caption1Strong.fontSize,
        reason: 'Common.styles.ts:66.',
      );
      expect(
        styles.barLabel.color?.toARGB32(),
        theme.colors.neutralForeground1.toARGB32(),
        reason: 'Common.styles.ts:67 fill.',
      );
    });

    test('markerLabel and tooltip are body1', () {
      expect(
        styles.markerLabel.fontSize,
        theme.typography.body1.fontSize,
        reason: 'Common.styles.ts:74.',
      );
      expect(
        styles.tooltip.fontSize,
        theme.typography.body1.fontSize,
        reason: 'Common.styles.ts:38.',
      );
    });

    test('chartTitle is caption2Strong', () {
      expect(
        styles.chartTitle.fontSize,
        theme.typography.caption2Strong.fontSize,
        reason: 'Common.styles.ts:85.',
      );
    });

    test('legendLabel is caption1 at foreground1', () {
      expect(
        styles.legendLabel.fontSize,
        theme.typography.caption1.fontSize,
        reason: 'useLegendsStyles.styles.ts:98.',
      );
      expect(
        styles.legendLabel.color?.toARGB32(),
        theme.colors.neutralForeground1.toARGB32(),
        reason: 'useLegendsStyles.styles.ts:99.',
      );
    });

    test('popoverX is caption1 at foreground2 with 0.8 opacity baked in', () {
      expect(
        styles.popoverX.fontSize,
        theme.typography.caption1.fontSize,
        reason: 'useChartPopoverStyles.styles.ts:45.',
      );
      expect(
        styles.popoverX.color?.a,
        closeTo(0.8, 1e-6),
        reason: 'useChartPopoverStyles.styles.ts:46 opacity 0.8.',
      );
    });

    test('popoverY is subtitle2Stronger, the cartesian arm', () {
      expect(
        styles.popoverY.fontSize,
        theme.typography.subtitle2Stronger.fontSize,
        reason:
            'useChartPopoverStyles.styles.ts:79-81 calloutContentYCartesian. '
            'The non-cartesian arm at :82-84 is title2 and is applied by the '
            'popover itself.',
      );
    });

    test(
      'popoverLegend and popoverDescription are caption1 at foreground2',
      () {
        expect(
          styles.popoverLegend.color?.toARGB32(),
          theme.colors.neutralForeground2.toARGB32(),
          reason: 'useChartPopoverStyles.styles.ts:72.',
        );
        expect(
          styles.popoverDescription.color?.toARGB32(),
          theme.colors.neutralForeground2.toARGB32(),
          reason: 'useChartPopoverStyles.styles.ts:87.',
        );
      },
    );

    test('both ratio slots are caption2Strong at foreground1', () {
      expect(
        styles.popoverRatioNumerator.fontSize,
        theme.typography.caption2Strong.fontSize,
        reason: 'useChartPopoverStyles.styles.ts:98.',
      );
      expect(
        styles.popoverRatioDenominator.fontSize,
        theme.typography.caption2Strong.fontSize,
        reason: 'useChartPopoverStyles.styles.ts:101.',
      );
      expect(
        styles.popoverRatioNumerator.color?.toARGB32(),
        theme.colors.neutralForeground1.toARGB32(),
        reason:
            'Both spans inherit the colour of the ratio container at '
            'useChartPopoverStyles.styles.ts:95.',
      );
    });
  });

  group('kChartTitlePadding', () {
    test('is 20', () {
      expect(
        kChartTitlePadding,
        20,
        reason: 'CHART_TITLE_PADDING (Common.styles.ts:10).',
      );
    });
  });
}
