import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/chrome/legend_style.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  group('legend layout constants', () {
    test('match useLegendsStyles.styles.ts:10-21 exactly', () {
      expect(
        kLegendContainerMarginTop,
        8,
        reason: 'useLegendsStyles.styles.ts:10.',
      );
      expect(kLegendContainerMarginStart, 12, reason: ':11.');
      expect(kLegendPadding, 8, reason: ':12.');
      expect(kLegendHeight, 32, reason: ':13.');
      expect(kLegendShapeBorder, 1, reason: ':14.');
      expect(
        kLegendShapeSize,
        13,
        reason:
            ':19 is LEGEND_SHAPE_SIZE_WITHOUT_BORDER (12) + LEGEND_SHAPE_BORDER '
            '(1); the comment at :16-18 explains that the SVG is grown by the '
            'full border so the filled area stays 12.',
      );
      expect(kLegendShapeMarginEnd, 8, reason: ':20.');
      expect(kInactiveLegendTextOpacity, 0.67, reason: ':21.');
    });

    test('the high contrast swatch opacity is 0.6, not 0.67', () {
      expect(
        kInactiveLegendSwatchOpacityHc,
        0.6,
        reason:
            'Legends.tsx:383 sets --rect-opacity-high-contrast to 0.6 while '
            ':306 sets the label opacity to 0.67. They are different numbers '
            'and collapsing them changes the high contrast rendering.',
      );
    });

    test('kLegendHeight is consistent with the box model', () {
      expect(
        kLegendPadding * 2 +
            theme.typography.caption1.height! *
                theme.typography.caption1.fontSize!,
        kLegendHeight,
        reason:
            '8 padding + 16 caption1 line height + 8 padding = 32, which is '
            'what useLegendsStyles.styles.ts:13 hard-codes.',
      );
    });
  });

  group('resolveFluentChartLegendStyle', () {
    test('dims the swatch to the page background, not to transparent', () {
      final style = resolveFluentChartLegendStyle(theme);
      expect(
        style.dimmedSwatchColor!.resolve(<WidgetState>{})!.toARGB32(),
        theme.colors.neutralBackground1.toARGB32(),
        reason:
            'Legends.tsx:400 and :412 both assign tokens.colorNeutralBackground1 '
            'as the dimmed swatch colour — the swatch becomes the page, leaving '
            'only its 1px border in the series colour visible.',
      );
    });

    test('only high contrast dims the swatch by opacity', () {
      expect(
        resolveFluentChartLegendStyle(
          theme,
        ).dimmedSwatchOpacity!.resolve(<WidgetState>{}),
        1,
        reason:
            'Legends.tsx:383 emits --rect-opacity-high-contrast, which '
            'useLegendsStyles.styles.ts:78 only reads inside the '
            'HighContrastSelector block (:76). Outside forced colours the '
            'swatch is dimmed by swapping its fill (:400, :412), so any '
            'opacity here would dim it twice.',
      );
      expect(
        resolveFluentChartLegendStyle(
          FluentThemeData.highContrast(fontPlatform: FluentFontPlatform.web),
        ).dimmedSwatchOpacity!.resolve(<WidgetState>{}),
        kInactiveLegendSwatchOpacityHc,
        reason:
            'Guard on the branch itself, not just the constant: the resolver '
            'reads FluentChartColors.isHighContrast, and an inverted ternary '
            'passes every other test in this file.',
      );
    });

    test('the swatch footprint is 14, the export footprint is 13', () {
      expect(
        kLegendSwatchBoxSize,
        14,
        reason:
            'Both render paths are 14 wide on screen: the SVG viewport is 14 '
            '(shape.tsx:39-40, :46-49) and the fallback div is 12 of content '
            'plus two 1px borders (useLegendsStyles.styles.ts:80-82). The '
            'synthesised export legend uses 13 instead '
            '(image-export-utils.ts:333-336), which is an upstream '
            'inconsistency the export path keeps.',
      );
    });

    test('merge is per property', () {
      final base = resolveFluentChartLegendStyle(theme);
      final merged = base.merge(
        FluentChartLegendStyle.from(dimmedLabelOpacity: 0.5),
      );
      expect(
        merged.dimmedLabelOpacity!.resolve(<WidgetState>{}),
        0.5,
        reason: 'The override must win for the property it names.',
      );
      expect(
        merged.rowHeight!.resolve(<WidgetState>{}),
        base.rowHeight!.resolve(<WidgetState>{}),
        reason: 'Every property the override omits must survive the merge.',
      );
    });

    test('equal styles hash equally', () {
      expect(
        resolveFluentChartLegendStyle(theme) ==
            resolveFluentChartLegendStyle(theme),
        isTrue,
        reason: 'Two resolutions of one theme must compare equal.',
      );
      expect(
        resolveFluentChartLegendStyle(theme).hashCode,
        resolveFluentChartLegendStyle(theme).hashCode,
        reason:
            'Equal styles must hash equally so InheritedTheme can diff them.',
      );
    });
  });
}
