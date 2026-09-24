import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import '../../surfaces/tooltip.dart';
import '../internal/chart_text_styles.dart';

/// Shows an axis label's untruncated text on hover, and only when it was
/// actually truncated.
///
/// A [FluentTooltip] over [child], as `SVGTooltipText` hangs a Tooltip off its
/// `<text>`. The cartesian axes do not use it: `tooltipOfAxislabels`
/// (`utilities.ts:1284-1324`) shows a plain [FluentChartTooltipBox] instead.
/// What it shares with that helper is the suppression: it **skips any tick
/// whose rendered text equals its `data-full` attribute** (`:1302-1304`), so
/// an axis label that fits has no hover affordance, and this widget disables
/// the tooltip rather than showing a duplicate of what is already on screen.
///
/// Composes [FluentTooltip] rather than reimplementing a surface, so there is
/// no style file. Two upstream behaviours do not survive the composition and
/// are recorded here rather than faked:
///
/// * **Delay.** `SVGTooltipText` defaults `delay = 0` (`:29`) and leaves
///   `closeDelay` undefined, so its tooltip is instant both ways.
///   [FluentTooltip] hard-codes 250ms (`surfaces/tooltip.dart:130`). The
///   package's timing wins, because a per-widget timer override is not part of
///   its API and forking the tooltip for 250ms is a bad trade.
/// * **Escape and Ctrl dismiss.** `SVGTooltipText.tsx:155-164` hides on
///   Escape *or any Ctrl chord*. [FluentTooltip] has no counterpart. Dropped.
class FluentAxisLabelTooltip extends StatelessWidget {
  /// Wraps [child] with the tooltip.
  const FluentAxisLabelTooltip({
    super.key,
    required this.fullText,
    required this.renderedText,
    required this.child,
  });

  /// The label before truncation — upstream's `data-full` (`utilities.ts:1150`,
  /// `:1220`).
  final String fullText;

  /// The label as it is actually painted.
  final String renderedText;

  /// The painted label.
  final Widget child;

  @override
  Widget build(BuildContext context) => FluentTooltip(
    content: Text(fullText),
    // utilities.ts:1302-1304 — no tooltip when nothing was cut.
    enabled: fullText != renderedText,
    // SVGTooltipText.tsx:187 forces the arrow on after the props spread.
    withArrow: true,
    child: child,
  );
}

/// The box a chart shows a cut-short label's whole text in.
///
/// Upstream's is a bare `div` styled by `getTooltipStyle`
/// (`Common.styles.ts:36-49`): body1 in `colorNeutralForeground1`, centred, on
/// `colorNeutralBackground1` with `borderRadiusSmall` corners and
/// `spacingHorizontalS` padding, drawn at `opacity: 0.9`
/// (`utilities.ts:1318`). `tooltipOfAxislabels` fills `fui-cart__tooltip`
/// with it (`useCartesianChartStyles.styles.ts:115`) and SankeyChart its
/// `fui-sc__toolTip` (`useSankeyChartStyles.styles.ts:44`). It is not a
/// Tooltip: no arrow, no shadow, no delay. The caller places it and decides
/// when it shows.
class FluentChartTooltipBox extends StatelessWidget {
  /// Creates a box showing [text].
  const FluentChartTooltipBox({
    super.key,
    required this.text,
    this.textStyle,
    this.backgroundColor,
    this.borderRadius,
  });

  /// The whole label.
  final String text;

  /// The label's style. Defaults to [FluentChartTextStyles.tooltip].
  final TextStyle? textStyle;

  /// The fill. Defaults to `colorNeutralBackground1`.
  final Color? backgroundColor;

  /// The corners. Defaults to `borderRadiusSmall`.
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Opacity(
      opacity: 0.9,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor ?? theme.colors.neutralBackground1,
          borderRadius:
              borderRadius ?? const BorderRadius.all(FluentRadius.small),
        ),
        child: Padding(
          padding: const EdgeInsets.all(FluentSpacing.s),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: textStyle ?? FluentChartTextStyles.of(theme).tooltip,
          ),
        ),
      ),
    );
  }
}
