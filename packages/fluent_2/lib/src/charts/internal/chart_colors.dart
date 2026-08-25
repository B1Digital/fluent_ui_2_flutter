import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

/// The WCAG contrast ratio between [a] and [b].
///
/// Ports `getColorContrast` (`colors.ts:165-169`):
/// `(max(l1, l2) + 0.05) / (min(l1, l2) + 0.05)`, where each `l` is the
/// relative luminance defined at
/// <https://www.w3.org/TR/WCAG/#dfn-contrast-ratio>.
///
/// [Color.computeLuminance] is the same computation. Its sRGB knee sits at
/// 0.03928 where `colors.ts:150` uses 0.04045; those two thresholds bracket
/// only channel values strictly between `10/255` and `10.31/255`, and no 8-bit
/// channel lands there, so the two are bit-identical for every colour a chart
/// can hold.
///
/// 0.05 is the WCAG constant, not a tuning value.
double fluentColorContrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// The opposite of [color] within the neutral pair drawn from [colors].
///
/// Ports `getInvertedTextColor` (`colors.ts:171-173`):
/// `colorNeutralForeground1` maps to `colorNeutralBackground1`, and anything
/// else maps to `colorNeutralForeground1`. Upstream's `isDarkTheme` parameter
/// is read by nothing in the body and is not ported.
Color fluentInvertedTextColor(Color color, FluentColors colors) =>
    color == colors.neutralForeground1
    ? colors.neutralBackground1
    : colors.neutralForeground1;

/// A readable text colour for text sitting on [background], drawn from
/// [colors].
///
/// Ports `getContrastTextColor` (`colors.ts:175-182`): start from
/// `colorNeutralForeground1` and invert it when the contrast is below 3.
///
/// 3 is upstream's threshold at `colors.ts:178`. It is the WCAG 2.1 minimum
/// for large text and for non-text contrast, not the 4.5 minimum for body
/// text.
Color fluentContrastTextColor(Color background, FluentColors colors) {
  final textColor = colors.neutralForeground1;
  if (fluentColorContrast(textColor, background) < 3) {
    return fluentInvertedTextColor(textColor, colors);
  }
  return textColor;
}

/// Every colour a chart's chrome needs, resolved once from a theme.
///
/// Each slot names the upstream rule it comes from. Building this once per chart
/// and passing it down keeps painters free of theme lookups.
@immutable
class FluentChartColors {
  /// Creates a resolved slot set.
  const FluentChartColors({
    required this.axisText,
    required this.axisTick,
    required this.axisTitle,
    required this.gridLine,
    required this.markStroke,
    required this.surface,
    required this.popoverSurface,
    required this.tooltipSurface,
    required this.legendDimmed,
    required this.isHighContrast,
  });

  /// Resolves every slot from [theme].
  factory FluentChartColors.of(FluentThemeData theme) {
    final colors = theme.colors;
    // useCartesianChartStyles.styles.ts:67-72 and :83-87 — one `& line` rule
    // serves both the tick marks and the grid lines, at opacity 0.2 over
    // colorNeutralForeground1.
    final line = colors.neutralForeground1.withValues(alpha: 0.2);
    return FluentChartColors(
      // :63 and :80 — `fill: tokens.colorNeutralForeground1` on axis text.
      axisText: colors.neutralForeground1,
      axisTick: line,
      // Common.styles.ts:57 — the SVG `fill`, which wins over the `color` at
      // :56 for a text element.
      axisTitle: colors.neutralForeground1,
      gridLine: line,
      // The halo stroked behind a line or a marker. types/DataPoint.ts:439
      // documents white; every runtime call site passes colorNeutralBackground1.
      markStroke: colors.neutralBackground1,
      // useCartesianChartStyles.styles.ts:107 — the svgTooltip fill.
      surface: colors.neutralBackground1,
      // useChartPopoverStyles.styles.ts:36.
      popoverSurface: colors.neutralBackground1,
      // Common.styles.ts:44.
      tooltipSurface: colors.neutralBackground1,
      // Legends.tsx:306 detects a dimmed legend by comparing its swatch colour
      // against colorNeutralBackground1.
      legendDimmed: colors.neutralBackground1,
      // The package's own high-contrast test, as used at acrylic.dart:56 and
      // rating.dart:230. Brightness cannot serve: FluentHighContrastColors is
      // itself Brightness.dark.
      isHighContrast: colors is FluentHighContrastColors,
    );
  }

  /// Axis tick label colour.
  final Color axisText;

  /// Axis tick mark colour, already at its 0.2 opacity.
  final Color axisTick;

  /// Axis title colour.
  final Color axisTitle;

  /// Grid line colour, already at its 0.2 opacity.
  final Color gridLine;

  /// The halo stroked behind a series mark.
  final Color markStroke;

  /// The chart's own background.
  final Color surface;

  /// The popover's background.
  final Color popoverSurface;

  /// The axis-label tooltip's background.
  final Color tooltipSurface;

  /// The swatch colour that marks a legend as dimmed.
  final Color legendDimmed;

  /// Whether the theme is the high-contrast palette.
  final bool isHighContrast;

  /// [seriesColour], or the flattened system colour under high contrast.
  ///
  /// Spec section 5.3: upstream's series marks carry no `forced-color-adjust`,
  /// so in forced-colours mode the browser rewrites every `fill` to
  /// `CanvasText` and the forty-colour palette disappears. Flutter does nothing
  /// here unless told to, so this is explicit code, and it is what every
  /// `*.high_contrast.png` golden encodes.
  Color flattenMark(Color seriesColour) =>
      isHighContrast ? axisText : seriesColour;

  /// [seriesColour], or the flattened system colour under high contrast.
  ///
  /// The stroke flattens to the **canvas** colour, not to `CanvasText`. A
  /// literal transliteration would send both fill and stroke to `CanvasText`,
  /// merging adjacent bars into one indistinguishable block; spec section 5.2
  /// exempts accessibility defects from bug fidelity, so the hairline is kept.
  Color flattenMarkStroke(Color seriesColour) =>
      isHighContrast ? surface : seriesColour;
}
