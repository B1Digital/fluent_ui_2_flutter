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
