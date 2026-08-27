import 'package:flutter/widgets.dart';

/// The [TapRegion] group an overlay opened from inside another overlay joins.
///
/// Every Fluent popup dismisses itself through a `TapRegion` group: its trigger
/// and its surface share a `groupId`, so a pointer landing on either counts as
/// "inside" and only a tap on neither closes it.
///
/// That breaks down the moment one popup opens another. The inner popup's
/// surface is inflated into its own [OverlayEntry], which is a sibling of the
/// outer one rather than a descendant — so the inner surface is *outside* the
/// outer group, and merely opening it made the outer popup dismiss itself and
/// unmount the subtree the inner one was living in. The whole chain collapsed
/// on the second click.
///
/// The fix is for the inner popup to join the outer popup's group instead of
/// starting its own. A surface publishes its group id to whatever it contains;
/// a popup reads it at its trigger's context and, when it finds one, adopts it.
/// One group then covers the entire chain: a click anywhere inside it keeps
/// every level open, and a click outside dismisses all of them at once, which
/// is what upstream's document-level `useOnClickOutside` does.
///
/// ponytail: one shared id for the whole chain, not a nested list of them.
/// The refinement it gives up is closing *only* the inner levels when the click
/// lands on an outer surface — rare, and it costs a `TapRegion` per level to
/// express. Nest the ids if a design ever asks for it.
class FluentTapGroup extends InheritedWidget {
  /// Publishes [groupId] to everything built inside a popup surface.
  const FluentTapGroup({
    required this.groupId,
    required super.child,
    super.key,
  });

  /// The group every popup in this chain shares.
  final Object groupId;

  /// The enclosing chain's group, or null at the top level.
  ///
  /// Read this at the *trigger's* context, not inside an [OverlayEntry] builder
  /// — an entry is inflated in the [Overlay]'s branch and inherits nothing from
  /// the widget that inserted it. Cache the result in `didChangeDependencies`
  /// and hand the cached value to the entry.
  static Object? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentTapGroup>()?.groupId;

  @override
  bool updateShouldNotify(FluentTapGroup oldWidget) =>
      groupId != oldWidget.groupId;
}
