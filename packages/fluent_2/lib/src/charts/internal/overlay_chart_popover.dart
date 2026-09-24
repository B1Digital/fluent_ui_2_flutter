import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../chrome/chart_popover.dart';

/// A chart popover floated in the app's [Overlay], for the charts whose
/// `ChartPopover` sits in a root that does not clip it, so that its boundary
/// is the viewport rather than the chart (`DonutChart.tsx:391-414`,
/// `GaugeChart.tsx:703-711`, `FunnelChart.tsx:515`, `PolarChart.tsx:677`,
/// `HorizontalBarChart.tsx:465`).
///
/// Build it from an [OverlayPortal.overlayChildBuilder] with that builder's
/// [context]. [anchorRect] is in the coordinates of [anchorContext]'s render
/// box, or on the screen when [anchorContext] is null. It takes no pointer,
/// so the pointer stays over the chart that opened it rather than leaving it
/// for the surface, and a surface flipped over a mark does not pull the
/// pointer off it.
///
/// With a [link] whose `CompositedTransformTarget` wraps [anchorContext]'s
/// box, the popover keeps to the box when the page moves it: it is laid out
/// in the overlay against the box as it sits now, and the follower paints in
/// the box's space as it sits when painted, which leaves only how far the page
/// has moved it since. A scroll under a resting pointer sends no hover, so
/// nothing rebuilds this.
///
/// ponytail: flip and shift are decided at build, as FluentPopover's are, so
/// a popover scrolled to an edge is not pushed back in until its chart
/// rebuilds it; without a [link] it is also left where it opened.
Widget buildFluentOverlayChartPopover(
  BuildContext context, {
  required FluentChartPopoverData data,
  required Rect anchorRect,
  BuildContext? anchorContext,
  LayerLink? link,
}) {
  final overlay = Overlay.of(context).context.findRenderObject();
  final box = anchorContext?.findRenderObject();
  if (overlay is! RenderBox ||
      !overlay.attached ||
      (anchorContext != null && (box is! RenderBox || !box.attached))) {
    return const SizedBox.shrink();
  }
  final toOverlay = box is RenderBox
      ? box.getTransformTo(overlay)
      : Matrix4.tryInvert(overlay.getTransformTo(null));
  if (toOverlay == null) {
    return const SizedBox.shrink();
  }
  final target = MatrixUtils.transformRect(toOverlay, anchorRect);
  final popover = IgnorePointer(
    child: FluentChartPopover(
      data: data,
      anchor: target.center,
      anchorRect: target,
    ),
  );
  if (link == null) {
    return popover;
  }
  final toBox = Matrix4.tryInvert(toOverlay);
  if (toBox == null) {
    return const SizedBox.shrink();
  }
  return CompositedTransformFollower(
    link: link,
    showWhenUnlinked: false,
    child: Transform(transform: toBox, child: popover),
  );
}

/// [path]'s tight bounding box: SVG's `getBBox`, which is what
/// `getBoundingClientRect` hands a popover's `positioning.target`.
///
/// [Path.getBounds] also takes in the control points of the conics Skia
/// splits an arc into, and those run far past any arc that does not start on
/// an axis: DonutChart's basic story measured a 229-degree slice at 382..580 x
/// 82..304 against Chrome's 420..581 x 82..266.
///
/// ponytail: sampled every half pixel along the outline, which is exact to
/// well under a pixel for a popover anchor and costs O(perimeter).
Rect fluentTightPathBounds(Path path) {
  Rect? bounds;
  for (final metric in path.computeMetrics()) {
    for (var distance = 0.0; ; distance += 0.5) {
      final point = metric
          .getTangentForOffset(math.min(distance, metric.length))!
          .position;
      final dot = Rect.fromPoints(point, point);
      bounds = bounds?.expandToInclude(dot) ?? dot;
      if (distance >= metric.length) break;
    }
  }
  return bounds ?? Rect.zero;
}
