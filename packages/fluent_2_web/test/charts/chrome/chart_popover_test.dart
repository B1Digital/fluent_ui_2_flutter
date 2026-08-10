import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/chrome/chart_popover_style.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  group('chart popover constants', () {
    test('the anchor offset is 20, not the package default of zero', () {
      expect(
        kChartPopoverAnchorOffset,
        20,
        reason:
            'ChartPopover.tsx:48 passes `offset: 20`, where FluentPopover '
            'defaults to FluentSpacing.none (overlays/popover.dart:239).',
      );
    });

    test('the accent bar is 4px with an 11px top margin', () {
      expect(
        kChartPopoverAccentBarWidth,
        4,
        reason: 'ChartPopover.tsx:74 — `borderInlineStart: 4px solid`.',
      );
      expect(
        kChartPopoverAccentBarMarginTop,
        11,
        reason: 'ChartPopover.tsx:75 — `marginTop: 11px`.',
      );
    });

    test('the single-value Y is 28px, overriding its own class', () {
      expect(
        kChartPopoverValueFontSize,
        28,
        reason:
            'ChartPopover.tsx:86 sets an inline fontSize of fontSizeHero700 '
            '(28px), which beats calloutContentY\'s subtitle2Stronger for the '
            'cartesian case and title2 for the non-cartesian one '
            '(useChartPopoverStyles.styles.ts:79-84). The multi-value path at '
            ':229 does NOT set it.',
      );
    });

    test('the subcount header is 12pt expressed in pixels', () {
      expect(
        kChartPopoverSubHeaderFontSize,
        16,
        reason:
            'ChartPopover.tsx:195 and :245 set `fontSize: 12pt`, and CSS pt is '
            '1/72 inch against a 96dpi reference pixel, so 12 * 96 / 72 = 16. '
            'The accompanying ms-fontWeight-semibold class is a v8 name with no '
            'v9 rule, so only the size lands.',
      );
    });

    test('multi-value spacing', () {
      expect(
        kChartPopoverColumnGap,
        16,
        reason:
            'ChartPopover.tsx:187 — `marginRight: 16px` on every non-last '
            'column.',
      );
      expect(
        kChartPopoverRowMarginTop,
        13,
        reason:
            'ChartPopover.tsx:226 — `marginTop: xValue ? 13px : unset`, and '
            'xValue is always truthy, so it is always 13.',
      );
      expect(
        kChartPopoverRowPaddingBottom,
        10,
        reason: 'ChartPopover.tsx:147 — 10px below a row that draws its rule.',
      );
    });
  });

  group('resolveFluentChartPopoverStyle', () {
    test('inherits the package popover surface', () {
      final style = resolveFluentChartPopoverStyle(theme);
      expect(
        style.surfacePadding!.resolve(<WidgetState>{}),
        const EdgeInsets.all(FluentSpacing.l),
        reason:
            'PopoverSurface is used bare at ChartPopover.tsx:52, so the surface '
            'takes the package medium popover padding of 16 '
            '(overlays/popover.dart:213-217, :228).',
      );
      expect(
        style.surfaceColor!.resolve(<WidgetState>{})!.toARGB32(),
        theme.colors.neutralBackground1.toARGB32(),
        reason:
            'useChartPopoverStyles.styles.ts:36 paints calloutContentRoot with '
            'colorNeutralBackground1.',
      );
    });

    test('the description rule is neutralStroke2', () {
      expect(
        resolveFluentChartPopoverStyle(
          theme,
        ).descriptionDividerColor!.resolve(<WidgetState>{})!.toARGB32(),
        theme.colors.neutralStroke2.toARGB32(),
        reason:
            'useChartPopoverStyles.styles.ts:90 — `borderTop: 1px solid '
            'colorNeutralStroke2`.',
      );
    });

    test('equal styles compare equal, shadows and all', () {
      final shadows = resolveFluentChartPopoverStyle(
        theme,
      ).surfaceShadow!.resolve(<WidgetState>{})!;
      expect(
        shadows,
        hasLength(2),
        reason:
            'FluentElevation.shadow16 is an ambient plus a key shadow '
            '(tokens/elevation.dart:33-36), so the equality spread over the '
            'shadow list is not vacuous.',
      );
      expect(
        resolveFluentChartPopoverStyle(theme),
        resolveFluentChartPopoverStyle(theme),
        reason:
            'theme.shadow() returns a fresh List per call (theme.dart:139) and '
            'List has no value equality, which is why the shadows are spread '
            'into the field list rather than compared as a property.',
      );
    });

    test('equal styles hash equally', () {
      expect(
        resolveFluentChartPopoverStyle(theme).hashCode,
        resolveFluentChartPopoverStyle(theme).hashCode,
        reason:
            'Twenty-three fields exceed Object.hash\'s twenty-argument limit, '
            'so this must be Object.hashAll and must still be stable.',
      );
    });
  });
}
