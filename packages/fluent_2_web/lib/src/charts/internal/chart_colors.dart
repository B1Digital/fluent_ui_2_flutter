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
