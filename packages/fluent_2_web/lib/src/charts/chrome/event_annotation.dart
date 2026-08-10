import 'package:flutter/widgets.dart';

/// Slack added to the label width before packing. `EventAnnotation.tsx:20`.
const double kEventAnnotationTextPadding = 5;

/// Line height of a wrapped event label, in raw pixels.
///
/// `EventAnnotation.tsx:21`. `Textbox.tsx:40` uses it as a bare `dy` attribute
/// rather than an em value, and `:44` lifts the whole block by
/// `-numLines * 18`, which is what bottom-aligns it.
const double kEventAnnotationLineHeight = 18;

/// Default label width. `EventAnnotation.tsx:17`.
///
/// The packer is fed `labelWidth + kEventAnnotationTextPadding` (`:37`), so its
/// working width is 110 — a different number that must not be confused with
/// this one.
const double kEventAnnotationDefaultLabelWidth = 105;

/// How far above the plot top the label baseline sits.
/// `EventAnnotation.tsx:18`.
const double kEventAnnotationTextTopOffset = 20;

/// How far above the plot top each dashed rule starts.
///
/// `EventAnnotation.tsx:19` is `textY + 7`, and `textY` is `chartYTop - 20`, so
/// the rule begins 13 above the plot.
const double kEventAnnotationLineTopOffset = 13;

/// Dash pattern of the vertical rules. `EventAnnotation.tsx:34`.
///
/// SVG's `stroke-dasharray="8"` is a single value, which means 8 on and 8 off.
const List<double> kEventAnnotationDashArray = <double>[8];

/// Which end of an event label sits on its rule.
enum FluentEventLabelAnchor {
  /// The label extends to the right of its rule. `EventAnnotation.tsx:81`.
  start,

  /// The label extends to the left of its rule. `EventAnnotation.tsx:79`.
  end,
}

/// One packed event label.
@immutable
class FluentEventLabelPlacement {
  /// Creates a placement.
  const FluentEventLabelPlacement({
    required this.x,
    required this.anchor,
    required this.aggregatedIndices,
  });

  /// The rule this label sits on.
  final double x;

  /// Which side of [x] the text extends.
  final FluentEventLabelAnchor anchor;

  /// Every event index this label speaks for.
  ///
  /// More than one means the label reads `mergedLabel(count)` instead of a
  /// single event's own text (`LabelLink.tsx:66-70`).
  final List<int> aggregatedIndices;
}

/// Packs event labels along the x axis without overprinting.
///
/// Ports `calculateLabels` (`EventAnnotation.tsx:61-119`) — a recursive greedy
/// packer. [positions] must already be sorted ascending by date
/// (`:27`). [textWidth] is the label width **plus**
/// [kEventAnnotationTextPadding], as `:37` passes it.
///
/// Written iteratively rather than recursively: the upstream `backtrack` always
/// tail-calls `calculateLabel` and unshifts onto the result, so the recursion is
/// a loop with an accumulator and a 500-event series would otherwise blow the
/// stack.
List<FluentEventLabelPlacement> fluentPackEventAnnotationLabels(
  List<double> positions,
  double textWidth,
  double maxX,
  double minX,
) {
  final placements = <FluentEventLabelPlacement>[];
  var lastX = minX;
  var index = 0;

  while (index < positions.length) {
    final x = positions[index];
    final leftBoundary = x - textWidth;

    // EventAnnotation.tsx:72-74 — cannot render on top of the previous label.
    if (x < lastX) {
      break;
    }

    // EventAnnotation.tsx:77-85 — the last event has no successor to fold into.
    if (index == positions.length - 1) {
      if (lastX < leftBoundary) {
        placements.add(
          FluentEventLabelPlacement(
            x: x,
            anchor: FluentEventLabelAnchor.end,
            aggregatedIndices: <int>[index],
          ),
        );
      } else if (x + textWidth < maxX) {
        placements.add(
          FluentEventLabelPlacement(
            x: x,
            anchor: FluentEventLabelAnchor.start,
            aggregatedIndices: <int>[index],
          ),
        );
      }
      break;
    }

    // EventAnnotation.tsx:87-93.
    final anchor = lastX < leftBoundary
        ? FluentEventLabelAnchor.end
        : FluentEventLabelAnchor.start;
    // EventAnnotation.tsx:97 — the boundary the next label must clear.
    final boundary = anchor == FluentEventLabelAnchor.end ? x : x + textWidth;

    // EventAnnotation.tsx:99-106 — the first later event with room of its own.
    var next = positions.length;
    for (var scan = index + 1; scan < positions.length; scan++) {
      final candidate = positions[scan];
      if (candidate > boundary &&
          (candidate - textWidth >= boundary || candidate + textWidth < maxX)) {
        next = scan;
        break;
      }
    }

    placements.add(
      FluentEventLabelPlacement(
        x: x,
        anchor: anchor,
        // EventAnnotation.tsx:108-111.
        aggregatedIndices: <int>[for (var i = index; i < next; i++) i],
      ),
    );
    lastX = boundary;
    index = next;
  }

  return placements;
}
