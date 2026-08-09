import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

/// The gap below a chart title, in logical pixels.
///
/// `CHART_TITLE_PADDING` (`utilities/Common.styles.ts:10`), which is 20.
const double kChartTitlePadding = 20;

/// Every text style a chart needs, resolved once from a theme.
///
/// Fourteen slots, each transcribed from the upstream rule named on its field.
@immutable
class FluentChartTextStyles {
  /// Creates a resolved slot set.
  const FluentChartTextStyles({
    required this.axisTick,
    required this.axisTitle,
    required this.axisAnnotation,
    required this.barLabel,
    required this.markerLabel,
    required this.chartTitle,
    required this.tooltip,
    required this.legendLabel,
    required this.popoverX,
    required this.popoverY,
    required this.popoverLegend,
    required this.popoverRatioNumerator,
    required this.popoverRatioDenominator,
    required this.popoverDescription,
  });

  /// Resolves every slot from [theme].
  factory FluentChartTextStyles.of(FluentThemeData theme) {
    final type = theme.typography;
    final colors = theme.colors;
    final foreground1 = colors.neutralForeground1;
    final foreground2 = colors.neutralForeground2;
    // utilities/Common.styles.ts:51-62 — one style serves both the axis title
    // and the axis annotation, because
    // useCartesianChartStyles.styles.ts:59-60 assigns getAxisTitleStyle() to
    // both slots. The SVG `fill` at :57 wins over the `color` at :56 for a text
    // element, so foreground1 is right and not foreground2.
    final axisTitleStyle = type.caption2Strong.copyWith(color: foreground1);
    return FluentChartTextStyles(
      // useCartesianChartStyles.styles.ts:62-66 and :78-82.
      axisTick: type.caption2Strong.copyWith(color: foreground1),
      axisTitle: axisTitleStyle,
      axisAnnotation: axisTitleStyle,
      // utilities/Common.styles.ts:64-70.
      barLabel: type.caption1Strong.copyWith(color: foreground1),
      // utilities/Common.styles.ts:72-81.
      markerLabel: type.body1.copyWith(color: foreground1),
      // utilities/Common.styles.ts:83-91.
      chartTitle: type.caption2Strong.copyWith(color: foreground1),
      // utilities/Common.styles.ts:36-49.
      tooltip: type.body1.copyWith(color: foreground1),
      // useLegendsStyles.styles.ts:97-101.
      legendLabel: type.caption1.copyWith(color: foreground1),
      // useChartPopoverStyles.styles.ts:44-48 — caption1 at foreground2, with
      // the rule's own `opacity: 0.8` folded into the colour, because Flutter
      // has no per-span opacity. The 0.8 is that literal opacity.
      popoverX: type.caption1.copyWith(
        color: foreground2.withValues(alpha: 0.8),
      ),
      // useChartPopoverStyles.styles.ts:79-81, the cartesian arm. The
      // non-cartesian arm at :82-84 is title2 and the popover picks it itself.
      // The colour is inherited from calloutBlockContainer at :50.
      popoverY: type.subtitle2Stronger.copyWith(color: foreground2),
      // useChartPopoverStyles.styles.ts:70-75.
      popoverLegend: type.caption1.copyWith(color: foreground2),
      // useChartPopoverStyles.styles.ts:97-99, inheriting the colour of the
      // ratio container at :92-96.
      popoverRatioNumerator: type.caption2Strong.copyWith(color: foreground1),
      // useChartPopoverStyles.styles.ts:100-102, same container.
      popoverRatioDenominator: type.caption2Strong.copyWith(color: foreground1),
      // useChartPopoverStyles.styles.ts:85-91.
      popoverDescription: type.caption1.copyWith(color: foreground2),
    );
  }

  /// Axis tick labels.
  final TextStyle axisTick;

  /// Axis titles.
  final TextStyle axisTitle;

  /// Axis annotations.
  final TextStyle axisAnnotation;

  /// Text drawn on a bar.
  final TextStyle barLabel;

  /// Text drawn beside a marker.
  final TextStyle markerLabel;

  /// The chart title.
  final TextStyle chartTitle;

  /// The axis-label tooltip.
  final TextStyle tooltip;

  /// A legend's label.
  final TextStyle legendLabel;

  /// The x value at the top of a popover.
  final TextStyle popoverX;

  /// A y value in a popover.
  final TextStyle popoverY;

  /// A series name in a popover.
  final TextStyle popoverLegend;

  /// The numerator of a popover ratio.
  final TextStyle popoverRatioNumerator;

  /// The denominator of a popover ratio.
  final TextStyle popoverRatioDenominator;

  /// A popover's trailing description line.
  final TextStyle popoverDescription;
}
