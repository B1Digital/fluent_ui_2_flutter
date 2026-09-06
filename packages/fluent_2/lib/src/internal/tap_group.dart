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
/// `FluentPopover` does that by *replacing* its own id with the enclosing one.
/// Every other popup — dropdown, tag picker, date and time picker, info button,
/// menu, breadcrumb overflow — instead keeps its own id and ADDS the enclosing
/// one around it, via [adoptFluentTapGroup]. Both keep the chain alive; only
/// the second also keeps per-level dismissal, and the note there says why.
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

/// Registers a popup surface in the enclosing chain's group as well as its own.
///
/// Wrap the popup's existing `TapRegion(groupId: this, …)` in this. Both
/// regions then sit on the same hit-test path, and
/// `RenderTapRegionSurface._classifyRegions` unions the groups of every region
/// it hits — so one pointer-down produces all three behaviours at once:
///
///  * on this popup — inside for BOTH groups, so neither level dismisses;
///  * on the host popover's own surface — inside for the host's group only, so
///    this popup closes and the host stays. That is the refinement a bare
///    `groupId: [groupId] ?? this` throws away, and it is not cosmetic: it is
///    what closes an open dropdown when the user clicks the panel behind it;
///  * outside everything — inside is empty, so every level dismisses together.
///
/// Two placement rules, both of which fail SILENTLY:
///
///  * This must sit immediately outside the popup's own `TapRegion` and
///    **inside** the `CompositedTransformFollower` that positions the surface.
///    Above the follower, `RenderFollowerLayer.hitTest` forwards through the
///    layer transform while a proxy above it tests `size.contains(position)`
///    against its untransformed rect at `Positioned(left: 0, top: 0)` — the
///    region is never hit, and every existing test still passes.
///  * [groupId] must come from [FluentTapGroup.maybeOf] read at the TRIGGER's
///    context and cached. An [OverlayEntry] is inflated in the [Overlay]'s
///    branch, and `FluentTapGroup` is a plain [InheritedWidget], so it is not
///    carried across by the `InheritedTheme.capture` that wraps the entry.
///
/// Returns [child] untouched at the top level. A `groupId: null` region would
/// still register with the surface and pay a register/unregister cycle per
/// layout to do nothing.
///
/// ponytail: adoption only — the popup does not republish. That covers a
/// two-level chain, which is every case in the library today. A third level
/// would need [FluentTapGroup] to carry a LIST of ids, because publishing
/// `this` from here would drop the host's group and collapse it again.
Widget adoptFluentTapGroup(Object? groupId, Widget child) =>
    groupId == null ? child : TapRegion(groupId: groupId, child: child);
