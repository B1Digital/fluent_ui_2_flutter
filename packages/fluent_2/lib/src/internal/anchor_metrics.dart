import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The anchor's rectangle in screen coordinates, or null while it has no
/// geometry.
///
/// Every popup in this package caps its height at the room left below (or
/// above) the thing it hangs off, and to do that it has to know where on the
/// *screen* that thing is. [LayerLink.leader] looks like the answer and mostly
/// behaves like one, but a `LeaderLayer` records the offset it was painted at
/// **inside its own layer** — so an anchor under a scrolled page reports its
/// position in the content instead. A trigger 4900px down a docs page therefore
/// measured as 4900px down the *screen*, `viewportHeight - that` clamped to
/// zero, and the popup opened with no height at all: focus moved, nothing
/// appeared.
///
/// [context] is the anchor widget's own context — the element whose render box
/// wraps its `CompositedTransformTarget`.
Rect? fluentAnchorRect(BuildContext context) {
  final object = context.findRenderObject();
  if (object is! RenderBox || !object.attached || !object.hasSize) return null;
  return object.localToGlobal(Offset.zero) & object.size;
}

/// Vertical room left for a popup hanging off [context]'s anchor.
///
/// `below` is the distance from the anchor's bottom edge to the bottom of the
/// viewport, `above` the distance from its top edge to the top; both are
/// clamped at zero. Compare them to decide which way a popup should open —
/// upstream's positioning layer flips on the same test.
///
/// Both are [double.infinity] when the anchor has no geometry yet or there is
/// no [MediaQuery] in scope. That matters: a popup opened in the same frame as
/// its trigger has no render box to measure, and returning zero there would
/// clamp it to nothing on its very first build. Unconstrained-then-correct is
/// the recoverable failure; collapsed-to-zero is the one that reads as "the
/// control does nothing".
({double below, double above}) fluentAnchorRoom(BuildContext context) {
  final anchor = fluentAnchorRect(context);
  final viewport = MediaQuery.maybeSizeOf(context)?.height;
  if (anchor == null || viewport == null) {
    return (below: double.infinity, above: double.infinity);
  }
  return (
    below: math.max(viewport - anchor.bottom, 0),
    above: math.max(anchor.top, 0),
  );
}
