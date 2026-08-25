import 'package:flutter/widgets.dart';

import '../../surfaces/tooltip.dart';

/// Shows an axis label's untruncated text on hover, and only when it was
/// actually truncated.
///
/// Replaces `tooltipOfAxislabels` (`utilities.ts:1284-1324`), which appends one
/// shared `div` to the chart root, walks every tick, and **skips any tick whose
/// rendered text equals its `data-full` attribute** (`:1302-1304`). That
/// suppression is the whole behaviour: an axis label that fits has no hover
/// affordance, so this widget disables the tooltip rather than showing a
/// duplicate of what is already on screen.
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
