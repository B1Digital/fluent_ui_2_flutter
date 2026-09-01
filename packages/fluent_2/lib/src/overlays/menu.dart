import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show clampDouble, lerpDouble;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../internal/anchor_metrics.dart';
import '../internal/animated_style.dart';
import '../internal/defer.dart';
import '../internal/input_modality.dart';
import '../internal/interaction.dart';
import 'menu_item.dart';
import 'menu_item_style.dart';
import 'menu_style.dart';

/// The menu surface arriving.
///
/// The same spec as the popover surface — [FluentMotionSpec.popover],
/// `durationSlower` (400) on `curveDecelerateMid` — which is what
/// `Menu/MenuSurfaceMotion.ts` builds its enter out of.
///
/// **Enter only.** There is no exit transition: a dismissed menu is gone on the
/// next frame. Do not pair this with an exit spec to "finish" it; the asymmetry
/// is upstream's (`exit: []`).
///
/// Neither `useMenuPopoverStyles.styles.ts` nor
/// `usePopoverSurfaceStyles.styles.ts` declares a `transition`, an `animation`
/// or a `motionTokens` reference — the timing lives in the presence component
/// those styles are mounted inside, which is where this pair comes from.
const FluentMotionSpec fluentMenuSurfaceEnter = FluentMotionSpec.popover;

/// How far the surface travels along its opening axis as it arrives.
///
/// `MenuSurfaceMotion` pairs its fade with a `slideAtom` whose `distance`
/// defaults to 10, moving from `direction * 10` to 0 — the direction being the
/// `--fui-positioning-slide-direction-{x,y}` pair the positioning layer writes,
/// which is `-1` on the axis the surface opens along. So a menu below its
/// trigger drops in from 10px above, and a submenu slides in from 10px behind
/// its opening edge.
const double _menuSurfaceSlide = 10;

/// How long a pointer must rest on a row before its submenu opens.
///
/// `useMenu.tsx` defaults `hoverDelay = 500`. Keyboard opening — Right arrow,
/// Enter, Space — never waits; upstream passes `ignoreHoverDelay` there.
const Duration fluentMenuHoverDelay = Duration(milliseconds: 500);

/// Everything needed to render a menu surface, independent of the design axis.
///
/// The counterpart of `FluentButtonBaseState`. [buildFluentMenu] takes this
/// rather than [FluentMenuState], which is what makes "Fluent's state, my own
/// styling, Fluent's rendering" a supported path rather than a fork.
@immutable
class FluentMenuBaseState {
  /// Creates a base state.
  const FluentMenuBaseState({required this.children});

  /// The rows, in order. Already built — the surface only stacks and insets
  /// them.
  final List<Widget> children;
}

/// A menu surface's fully resolved state, including the design axis.
@immutable
class FluentMenuState extends FluentMenuBaseState {
  /// Creates a resolved state.
  const FluentMenuState({required super.children, required this.custom});

  /// Whether the surface holds arbitrary content rather than menu rows.
  ///
  /// Figma's `Custom menu` axis. Both variants of `Menu/Menu` resolve to the
  /// same numbers — 4 padding, 2 gap, `Corner-radius/Modal/Medium` and
  /// `Corner-radius/40` are both 4, and `Spacing/List/Section/Gap` and
  /// `Web/Spacing/XXS` are both 2 — so this changes nothing about the surface
  /// and exists so a caller can say which one they are building.
  final bool custom;
}

/// Builds the state a menu surface will be styled and rendered from.
///
/// The first of the three-function recomposition contract.
FluentMenuState resolveFluentMenuState({
  required List<Widget> children,
  bool custom = false,
}) => FluentMenuState(children: children, custom: custom);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract. Every value comes
/// from a Fluent token; nothing here computes a colour.
///
/// Token sources are the Figma `Menu/Menu` set (`9121:6579`, extracted to
/// `test/fixtures/menu.json`) reconciled against
/// `useMenuPopoverStyles.styles.ts`. They agree on the fill
/// (`Neutral/Background/1/Rest` / `colorNeutralBackground1`), the radius
/// (`borderRadiusMedium`, 4), the 4px inset and the `shadow16` pair — Figma's
/// two effects are ambient `(0,0)` blur 2 at 12% and key `(0,8)` blur 16 at
/// 14%, which is `shadow16` exactly.
///
/// **The border follows React.** Figma paints no stroke on either variant;
/// upstream declares `1px solid colorTransparentStroke`. That border is
/// invisible in light and dark and *opaque* in high contrast, where it is the
/// only thing separating the surface from the page behind it — so it ships,
/// the same call `FluentSwitch`'s checked track already makes.
///
/// **The width rule is React's.** Figma's frames are a fixed 260 with
/// placeholder content, which is a canvas size rather than a constraint;
/// `useMenuPopoverStyles.styles.ts` states the real rule —
/// `width: 'max-content'` clamped to `[138, 300]`, which is [buildFluentMenu]'s
/// `IntrinsicWidth` between [FluentMenuStyle.minWidth] and
/// [FluentMenuStyle.maxWidth].
FluentMenuStyle resolveFluentMenuStyle(
  FluentMenuState state,
  FluentThemeData theme,
) {
  final c = theme.colors;
  return FluentMenuStyle(
    backgroundColor: FluentStateColor.tokens(rest: c.neutralBackground1),
    borderColor: FluentStateColor.tokens(rest: c.transparentStroke),
    borderWidth: const WidgetStatePropertyAll<double?>(FluentStroke.thin),
    borderRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allMedium,
    ),
    padding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.all(FluentSpacing.xs),
    ),
    gap: const WidgetStatePropertyAll<double?>(FluentSpacing.xxs),
    minWidth: const WidgetStatePropertyAll<double?>(138),
    maxWidth: const WidgetStatePropertyAll<double?>(300),
    // Deliberately null. Neither Figma nor `useMenuPopoverStyles.styles.ts`
    // states a maximum height, because upstream's positioning layer writes one
    // inline from the space left below the anchor and recomputes it on every
    // reposition. `FluentMenu` reproduces that at build time; a non-null value
    // here — or on `FluentMenuTheme`, or on the widget's own `style` — is the
    // caller's override and wins.
    maxHeight: null,
    // Figma stacks the surface flush against its anchor.
    offset: const WidgetStatePropertyAll<double?>(FluentSpacing.none),
    shadow: WidgetStatePropertyAll<List<BoxShadow>?>(
      theme.shadow(FluentElevation.shadow16),
    ),
  );
}

/// Renders a menu surface from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentMenuBaseState] rather than [FluentMenuState] on purpose: it never
/// reads the design axis, so a consumer can supply their own style and still
/// use Fluent's surface.
///
/// [states] is present for symmetry with the rest of the package. A menu
/// surface is never hovered, pressed or focused — its *rows* are — so callers
/// normally pass an empty set.
Widget buildFluentMenu(
  FluentMenuBaseState state,
  FluentMenuStyle style,
  Set<WidgetState> states,
) {
  final radius = style.borderRadius?.resolve(states) ?? FluentRadius.allMedium;
  final borderWidth = style.borderWidth?.resolve(states) ?? FluentStroke.none;
  final borderColor = style.borderColor?.resolve(states);
  final minWidth = style.minWidth?.resolve(states) ?? 0;
  final maxWidth = style.maxWidth?.resolve(states) ?? double.infinity;
  final maxHeight = style.maxHeight?.resolve(states) ?? double.infinity;
  final gap = style.gap?.resolve(states) ?? FluentSpacing.xxs;

  return ConstrainedBox(
    constraints: BoxConstraints(
      minWidth: minWidth,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    ),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: style.backgroundColor?.resolve(states),
        borderRadius: radius,
        border: borderWidth > 0 && borderColor != null
            ? Border.all(color: borderColor, width: borderWidth)
            : null,
        boxShadow: style.shadow?.resolve(states),
      ),
      child: Padding(
        padding: style.padding?.resolve(states) ?? EdgeInsets.zero,
        // The surface is `width: max-content` upstream — not trigger-matched
        // and not stretched to the cap. The overlay hands this subtree LOOSE
        // constraints, so without IntrinsicWidth the CrossAxisAlignment.stretch
        // below would fill the whole 300 whatever the rows measure.
        // IntrinsicWidth sizes the column to its widest row and lets `stretch`
        // fill that, which is what keeps hover fills spanning the surface.
        child: IntrinsicWidth(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: gap,
              children: state.children,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Overrides the menu surface style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`. An [InheritedTheme], so it survives the hop into the
/// [Overlay] the menu is rendered in.
class FluentMenuTheme extends InheritedTheme {
  /// Applies [style] to every [FluentMenu] in [child].
  const FluentMenuTheme({super.key, required this.style, required super.child});

  /// The style layered over the theme defaults.
  final FluentMenuStyle style;

  /// The nearest menu style, or null.
  static FluentMenuStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentMenuTheme>()?.style;

  @override
  bool updateShouldNotify(FluentMenuTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentMenuTheme(style: style, child: child);
}

/// Builds a menu's trigger.
///
/// [toggle] opens the menu, or closes it if it is already open.
typedef FluentMenuTriggerBuilder =
    Widget Function(BuildContext context, VoidCallback toggle);

/// A Fluent 2 menu.
///
/// ```dart
/// FluentMenu(
///   items: <FluentMenuItem>[
///     FluentMenuItem(label: const Text('Cut'), onPressed: cut),
///     FluentMenuItem(label: const Text('Copy'), onPressed: copy),
///     const FluentMenuItem.divider(),
///     FluentMenuItem(
///       label: const Text('Paste special'),
///       submenu: <FluentMenuItem>[
///         FluentMenuItem(label: const Text('Values'), onPressed: pasteValues),
///       ],
///     ),
///   ],
///   builder: (context, toggle) =>
///       FluentButton(onPressed: toggle, child: const Text('Edit')),
/// )
/// ```
///
/// ## Keyboard
///
/// | Key | Effect |
/// |---|---|
/// | Down / Up | moves the active row, wrapping at the ends |
/// | Home / End | jumps to the first / last row |
/// | Enter / Space | invokes the active row, or opens its submenu |
/// | Right | opens the active row's submenu |
/// | Left | closes a submenu and returns to its parent row |
/// | Escape | closes the current level; from the root, closes the menu |
/// | Tab | closes the whole menu and moves on |
/// | a–z, 0–9 | jumps to the next row whose text starts with that character |
///
/// Focus moves **into** the open menu — each level owns a focus node, and the
/// active row is marked with [WidgetState.focused] because that is what
/// keyboard-visible focus means to the user. Closing the menu returns focus to
/// whatever inside the trigger had it when the menu opened. Tab is deliberately
/// not trapped: a menu is dismissed by moving on, unlike a dialog.
///
/// ## Motion
///
/// The surface fades in over [fluentMenuSurfaceEnter] while sliding 10px along
/// its opening axis, and is simply gone on close. Under
/// [MediaQuery.disableAnimationsOf] it arrives fully opaque and in place on the
/// frame it is inserted — [FluentAnimatedStyle] clamps the duration to zero, so
/// reduced motion is honoured without a second code path.
///
/// ## Dismissal
///
/// A pointer landing outside the trigger and every open level closes the whole
/// chain — and *still reaches whatever it landed on*. There is no invisible
/// full-screen barrier: upstream's `useOnClickOutside` is a document-level
/// listener, so in React the click that dismisses a menu also presses the
/// button under it. A [TapRegion] group reproduces that; an opaque
/// [Positioned.fill] barrier, which is what this used to paint, swallowed every
/// click, hover and scroll behind an open menu and cost the user a second
/// click.
///
/// Two consequences of that trade, both deliberate:
///
/// * **A [TapRegionSurface] ancestor is required.** [WidgetsApp] installs one
///   (`widgets/app.dart:1836`) and `FluentApp` wraps [WidgetsApp], so an app
///   and its tests are fine. A menu mounted under a bare [Overlay] with no
///   [WidgetsApp] above it simply never dismisses on an outside tap — Escape
///   and the trigger still close it.
/// * **A touch or trackpad drag-scroll outside the menu dismisses it.**
///   `RenderTapRegionSurface` "does not participate in the gesture
///   disambiguation system" (`widgets/tap_region.dart:189-193`), so a pointer
///   down that later becomes a drag still counts as an outside tap. A mouse
///   wheel does not — `FluentScrollBehavior` deliberately keeps
///   `PointerDeviceKind.mouse` out of `dragDevices`
///   (`fluent_2_core/lib/src/app.dart:434`), so a wheel scroll sends no pointer
///   down at all.
///
/// ## Positioning
///
/// Each level is an [OverlayEntry] anchored with
/// [CompositedTransformFollower], so it escapes any ancestor clip and follows
/// the trigger as it moves. `FluentTheme` is an [InheritedTheme], and every
/// theme between this widget and the overlay is captured on the way in, so
/// tokens resolve against the trigger's theme rather than the app root's.
///
/// Customisation follows the usual three rungs. [style] and [itemStyle] are
/// merged last and win; [FluentMenuTheme] and [FluentMenuItemTheme] restyle a
/// subtree; and [resolveFluentMenuState], [resolveFluentMenuStyle] and
/// [buildFluentMenu] — with their `FluentMenuItem` counterparts — are public so
/// any one of them can be replaced without forking this widget.
class FluentMenu extends StatefulWidget {
  /// Creates a menu over [items] triggered by [builder]'s widget.
  const FluentMenu({
    super.key,
    required this.items,
    required this.builder,
    this.style,
    this.itemStyle,
    this.hoverDelay = fluentMenuHoverDelay,
    this.semanticLabel,
  });

  /// The rows, in order. An empty list means the menu never opens.
  final List<FluentMenuItem> items;

  /// Builds the widget the menu hangs off.
  final FluentMenuTriggerBuilder builder;

  /// Surface overrides layered over the theme defaults. Merged last, so it wins.
  final FluentMenuStyle? style;

  /// Row overrides layered over the theme defaults. Merged last, so it wins.
  final FluentMenuItemStyle? itemStyle;

  /// How long a pointer rests on a row before its submenu opens.
  final Duration hoverDelay;

  /// Announced by assistive technology as the menu's own name.
  final String? semanticLabel;

  @override
  State<FluentMenu> createState() => _FluentMenuState();
}

/// One open level of the menu chain: the root, or a submenu.
class _MenuLevel {
  _MenuLevel({
    required this.items,
    required this.anchorLink,
    required this.submenu,
    this.anchorKey,
  });

  final List<FluentMenuItem> items;

  /// What this level is anchored to — the trigger for the root, the parent
  /// row for a submenu.
  final LayerLink anchorLink;

  /// The parent row's element, for a submenu. Null on the root.
  ///
  /// [anchorLink] positions this level but cannot measure it:
  /// `LeaderLayer.offset` is recorded inside the leader's own layer, and a
  /// row's layer is its surface's follower — so the offset is where the row
  /// sits *within the parent menu*, not on the screen. Reading it as a screen
  /// position made every submenu overhang the bottom of the viewport by exactly
  /// the parent surface's own `y`. A key gives the render box, which
  /// [fluentAnchorRect] turns into real screen coordinates.
  final GlobalKey? anchorKey;

  /// Whether this level opens beside its anchor rather than below it.
  final bool submenu;

  final FocusNode focusNode = FocusNode(debugLabel: 'FluentMenu');
  final Map<int, LayerLink> rowLinks = <int, LayerLink>{};
  final Map<int, GlobalKey> rowKeys = <int, GlobalKey>{};

  OverlayEntry? entry;
  int? active;
  Timer? hoverTimer;

  void dispose() {
    hoverTimer?.cancel();
    entry
      ?..remove()
      ..dispose();
    entry = null;
    focusNode.dispose();
  }
}

class _FluentMenuState extends State<FluentMenu> {
  final LayerLink _triggerLink = LayerLink();
  final FocusNode _triggerFocus = FocusNode(debugLabel: 'FluentMenuTrigger');
  final List<_MenuLevel> _levels = <_MenuLevel>[];

  FocusNode? _restore;
  ScrollPosition? _scrollPosition;

  /// Re-measures every open level against the room left after the page moved.
  ///
  /// A menu caps each level's height at the space beside its anchor, so a page
  /// scrolling under an open chain leaves that measurement stale — the surface
  /// follows its trigger up the viewport keeping the height it was given when
  /// the trigger sat near the bottom. Upstream `@fluentui/react-positioning`
  /// repositions rather than closing; `raw_menu_anchor.dart:543-551` uses this
  /// same notifier to CLOSE, which would be wrong for a menu whose submenu the
  /// user is reaching for.
  ///
  /// Deferred because `isScrollingNotifier` can flip during layout — a viewport
  /// whose content shrinks goes ballistic from `applyContentDimensions` — and
  /// invalidating an entry is a `setState` on the Overlay.
  void _handleScroll() {
    for (final level in _levels) {
      deferOrRun(() => level.entry?.markNeedsBuild());
    }
  }

  bool get _isOpen => _levels.isNotEmpty;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // An open level reads its theme and its reading direction from THIS
    // context inside the entry's builder, but `build` below returns only the
    // trigger — so a dependency change marks this element dirty and stops
    // there, never reaching the entry over in the Overlay's branch. A theme or
    // direction swap driven from inside an open menu would otherwise keep
    // rendering the old one until it was reopened. `dialog.dart:651` and
    // `drawer.dart:619` repaint the same way.
    for (final level in _levels) {
      deferOrRun(() => level.entry?.markNeedsBuild());
    }

    // Attached here rather than at open so a Scrollable swapped under the
    // trigger is picked up for free.
    //
    // ponytail: gated on `isScrollingNotifier`, so heights re-measure when a
    // scroll starts and stops rather than on every frame between — a long menu
    // would otherwise rebuild every row for the length of a fling. Wheel and
    // trackpad flip the notifier once per tick
    // (scroll_position_with_single_context.dart:222-235), so the desktop and web
    // case this package targets re-measures continuously anyway; a programmatic
    // `jumpTo` flips it not at all.
    _scrollPosition?.isScrollingNotifier.removeListener(_handleScroll);
    _scrollPosition = Scrollable.maybeOf(context)?.position;
    _scrollPosition?.isScrollingNotifier.addListener(_handleScroll);
  }

  @override
  void didUpdateWidget(FluentMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isOpen) return;
    // `List` has no value equality and `FluentMenuItem` declares no `==`, so
    // `widget.items != oldWidget.items` was true on *every* parent rebuild that
    // passed a fresh list literal — which is all but 6 of the 104 call sites in
    // the example app. Every unrelated rebuild collapsed the open submenu.
    //
    // ponytail: the length is the gate because it is what actually invalidates
    // an open submenu — the submenu is keyed to an index. A same-length swap
    // with different content still rebuilds the root but keeps the submenu
    // open; give the items real value equality if that ever matters.
    if (widget.items.length != oldWidget.items.length) {
      deferOrRun(() {
        if (widget.items.isEmpty) {
          _closeAll();
        } else {
          _closeFrom(1);
          _levels.first.entry?.markNeedsBuild();
        }
      });
      return;
    }
    deferOrRun(() => _levels.firstOrNull?.entry?.markNeedsBuild());
  }

  @override
  void dispose() {
    _scrollPosition?.isScrollingNotifier.removeListener(_handleScroll);
    for (final level in _levels) {
      level.dispose();
    }
    _levels.clear();
    _triggerFocus.dispose();
    super.dispose();
  }

  // --- opening and closing -------------------------------------------------

  void _toggle() => _isOpen ? _closeAll() : _openRoot();

  void _openRoot() {
    if (_isOpen || widget.items.isEmpty) return;
    // Remembered so that closing returns the keyboard where it was. Taken from
    // the trigger's own descendants rather than from `primaryFocus` at large,
    // which also proves the node is still live when it is restored.
    _restore = null;
    for (final node in _triggerFocus.descendants) {
      if (node.hasPrimaryFocus) {
        _restore = node;
        break;
      }
    }
    _push(
      _MenuLevel(items: widget.items, anchorLink: _triggerLink, submenu: false),
    );
  }

  void _push(_MenuLevel level) {
    final overlay = Overlay.of(context, debugRequiredFor: widget);
    // FluentTheme is an InheritedTheme, so this carries it — and any other
    // InheritedTheme between here and the overlay, including FluentMenuTheme
    // and FluentMenuItemTheme — across the boundary.
    final captured = InheritedTheme.capture(from: context, to: overlay.context);
    final depth = _levels.length;
    level.active = _seek(level, 0, 1);
    level.entry = OverlayEntry(
      builder: (_) => captured.wrap(_buildLevel(depth)),
    );
    _levels.add(level);
    overlay.insert(level.entry!);
    // Post-frame, not now: `requestFocus` on a node no `Focus` widget has
    // attached yet is silently dropped, and the entry has not been built. An
    // `autofocus: true` would be dropped too — the overlay's scope already has
    // a focused child whenever a submenu opens.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && _levels.contains(level)) level.focusNode.requestFocus();
    });
    setState(() {});
  }

  /// Removes every level from [depth] down, and hands focus back to the level
  /// above it.
  void _closeFrom(int depth) {
    if (depth >= _levels.length) return;
    final removed = _levels.sublist(depth);
    _levels.removeRange(depth, _levels.length);
    for (final level in removed) {
      level.dispose();
    }
    // Removing an entry rebuilds the [Overlay], and with it every entry left —
    // which is what repaints the parent row once it stops owning a submenu.
    if (_levels.isNotEmpty) _levels.last.focusNode.requestFocus();
    if (mounted) setState(() {});
  }

  void _closeAll() {
    if (!_isOpen) return;
    _closeFrom(0);
    final target = _restore;
    _restore = null;
    // The membership test is what makes this safe: a node that has left the
    // tree is no longer a descendant, so a disposed node is never asked to take
    // focus.
    if (target != null && _triggerFocus.descendants.contains(target)) {
      target.requestFocus();
    } else {
      _triggerFocus.requestFocus();
    }
  }

  void _openSubmenu(int depth, int index) {
    if (depth >= _levels.length) return;
    final level = _levels[depth];
    final item = level.items[index];
    if (!item.hasSubmenu || !item.enabled) return;
    _closeFrom(depth + 1);
    level.active = index;
    level.entry?.markNeedsBuild();
    _push(
      _MenuLevel(
        items: item.submenu,
        anchorLink: level.rowLinks.putIfAbsent(index, LayerLink.new),
        anchorKey: level.rowKeys.putIfAbsent(index, GlobalKey.new),
        submenu: true,
      ),
    );
  }

  void _activate(int depth, int index) {
    if (depth >= _levels.length) return;
    final item = _levels[depth].items[index];
    if (!item.selectable) return;
    if (item.hasSubmenu) {
      _openSubmenu(depth, index);
      return;
    }
    final onPressed = item.onPressed!;
    _closeAll();
    onPressed();
  }

  // --- the active row ------------------------------------------------------

  /// The first selectable row at or after [from], walking by [delta].
  int? _seek(_MenuLevel level, int from, int delta) {
    for (var i = from; i >= 0 && i < level.items.length; i += delta) {
      if (level.items[i].selectable) return i;
    }
    return null;
  }

  void _setActive(int depth, int? index) {
    if (index == null || depth >= _levels.length) return;
    final level = _levels[depth];
    if (level.active == index) return;
    level.active = index;
    level.entry?.markNeedsBuild();
    // Moving the keyboard off a row abandons whatever submenu it had opened.
    _closeFrom(depth + 1);
  }

  void _move(int depth, int delta) {
    final level = _levels[depth];
    final from =
        (level.active ?? (delta > 0 ? -1 : level.items.length)) + delta;
    // Wrapping, which is what upstream's MenuList does at both ends.
    _setActive(
      depth,
      _seek(level, from, delta) ??
          _seek(level, delta > 0 ? 0 : level.items.length - 1, delta),
    );
  }

  void _edge(int depth, {required bool last}) {
    final level = _levels[depth];
    _setActive(
      depth,
      last ? _seek(level, level.items.length - 1, -1) : _seek(level, 0, 1),
    );
  }

  /// Moves to the next selectable row whose text starts with [character].
  ///
  /// Single character, no buffer and no timer: it is the cheap 90% of
  /// typeahead, and a second press of the same key steps to the next match
  /// because the search starts one past the active row.
  bool _typeahead(int depth, String character) {
    final level = _levels[depth];
    final needle = character.toLowerCase();
    final start = (level.active ?? -1) + 1;
    for (var n = 0; n < level.items.length; n++) {
      final index = (start + n) % level.items.length;
      final item = level.items[index];
      if (!item.selectable) continue;
      if (_textOf(item).toLowerCase().startsWith(needle)) {
        _setActive(depth, index);
        return true;
      }
    }
    return false;
  }

  static String _textOf(FluentMenuItem item) {
    final text = item.text;
    if (text != null) return text;
    final label = item.label;
    return label is Text ? (label.data ?? '') : '';
  }

  // --- pointer -------------------------------------------------------------

  void _hoverRow(int depth, int index) {
    if (depth >= _levels.length) return;
    final level = _levels[depth];
    level.hoverTimer?.cancel();
    if (level.active != index) {
      level.active = index;
      level.entry?.markNeedsBuild();
      _closeFrom(depth + 1);
    }
    final item = level.items[index];
    if (!item.selectable || !item.hasSubmenu) return;
    level.hoverTimer = Timer(widget.hoverDelay, () {
      if (!mounted || depth >= _levels.length) return;
      if (_levels[depth].active == index) _openSubmenu(depth, index);
    });
  }

  // --- keyboard ------------------------------------------------------------

  KeyEventResult _handleKey(int depth, KeyEvent event) {
    if (event is KeyUpEvent || depth >= _levels.length) {
      return KeyEventResult.ignored;
    }
    final level = _levels[depth];
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowDown) {
      _move(depth, 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _move(depth, -1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home) {
      _edge(depth, last: false);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end) {
      _edge(depth, last: true);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      final active = level.active;
      if (active != null) _activate(depth, active);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      final active = level.active;
      if (active != null && level.items[active].hasSubmenu) {
        _openSubmenu(depth, active);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      if (depth == 0) return KeyEventResult.ignored;
      _closeFrom(depth);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      if (depth == 0) {
        _closeAll();
      } else {
        _closeFrom(depth);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.tab) {
      // Not trapped: a menu is dismissed by moving on. Reported as ignored so
      // the traversal still happens, from the trigger focus has just returned
      // to.
      _closeAll();
      return KeyEventResult.ignored;
    }

    final character = event.character;
    if (character != null &&
        character.length == 1 &&
        character.trim().isNotEmpty) {
      return _typeahead(depth, character)
          ? KeyEventResult.handled
          : KeyEventResult.ignored;
    }
    return KeyEventResult.ignored;
  }

  // --- building ------------------------------------------------------------

  FluentMenuStyle _surfaceStyle(FluentMenuState state, FluentThemeData theme) =>
      resolveFluentMenuStyle(
        state,
        theme,
      ).merge(FluentMenuTheme.maybeOf(context)).merge(widget.style);

  Widget _buildLevel(int depth) {
    final level = _levels[depth];
    final theme = FluentTheme.of(context);
    final itemThemeStyle = FluentMenuItemTheme.maybeOf(context);
    // One column of leading glyphs for the whole level, so labels line up
    // whether or not their own row has an icon.
    final reserveLeading = level.items.any(
      (item) => item.icon != null || item.checked,
    );

    final rows = <Widget>[
      for (var i = 0; i < level.items.length; i++)
        _buildRow(
          depth,
          i,
          theme,
          itemThemeStyle,
          reserveLeading: reserveLeading,
        ),
    ];

    final state = resolveFluentMenuState(children: rows);
    var style = _surfaceStyle(state, theme);
    const surfaceStates = <WidgetState>{};
    final offset = style.offset?.resolve(surfaceStates) ?? FluentSpacing.none;

    // Upstream's positioning layer writes `max-height` inline from the space
    // left below the anchor and recomputes it on every reposition; a fixed
    // number here would clip a menu on a tall screen and overflow a short one.
    // A root level opens under its trigger, so it starts at the anchor's bottom
    // edge plus the gap; a submenu opens beside its row, top-aligned with it,
    // so it starts at the anchor's top.
    // Whether this level opens upward instead of downward. Only the root can:
    // a submenu top-aligns with its row and flipping it would uncouple the two.
    var flipUp = false;
    if (style.maxHeight == null) {
      // Both levels are measured off a render box. A submenu's leader offset
      // looks like a screen position and is not — `LeaderLayer.offset` is
      // recorded inside its own layer, and a row's layer is its surface's
      // follower, so the value is where the row sits *within the parent menu*.
      // Every submenu therefore overhung the bottom of the viewport by exactly
      // the parent surface's own `y`. See [_MenuLevel.anchorKey].
      final anchorContext = level.submenu
          ? (level.anchorKey?.currentContext ?? context)
          : context;
      final anchor = fluentAnchorRect(anchorContext);
      final viewport = MediaQuery.sizeOf(context).height;

      // A submenu opens beside its row, top-aligned with it; a root level opens
      // below its trigger, so it starts at the anchor's bottom plus the gap.
      final below = level.submenu
          ? math.max(viewport - (anchor?.top ?? 0), 0.0)
          : math.max(viewport - ((anchor?.bottom ?? 0) + offset), 0.0);
      final above = level.submenu
          ? 0.0
          : math.max((anchor?.top ?? 0) - offset, 0.0);

      // `max(viewport - top, 0)` on its own gave a trigger at the bottom edge a
      // menu of height ZERO: focus moved into it, Escape bound to it, and
      // nothing painted. Upstream's positioning layer flips rather than
      // collapsing, and so does this.
      flipUp = above > below;
      style = style.copyWith(
        maxHeight: WidgetStatePropertyAll<double?>(flipUp ? above : below),
      );
    }

    final direction = Directionality.of(context);
    final (target, follower, shift, slide) = level.submenu
        ? (
            AlignmentDirectional.topEnd.resolve(direction),
            AlignmentDirectional.topStart.resolve(direction),
            Offset(offset, 0),
            // A submenu opens beside its parent row, so it travels along x —
            // mirrored in RTL, where `topEnd` is the left edge.
            Offset(
              direction == TextDirection.rtl
                  ? _menuSurfaceSlide
                  : -_menuSurfaceSlide,
              0,
            ),
          )
        : (
            (flipUp
                    ? AlignmentDirectional.topStart
                    : AlignmentDirectional.bottomStart)
                .resolve(direction),
            (flipUp
                    ? AlignmentDirectional.bottomStart
                    : AlignmentDirectional.topStart)
                .resolve(direction),
            Offset(0, flipUp ? -offset : offset),
            // The surface always travels *from* its anchor, so a menu opening
            // upward slides down into place rather than up.
            Offset(0, flipUp ? _menuSurfaceSlide : -_menuSurfaceSlide),
          );

    // Every level joins the TRIGGER's group. `groupId: this` is the one
    // `_FluentMenuState` that builds all of them, so a tap on a submenu row is
    // "inside" the same region as the root surface and the trigger, and
    // dismisses nothing. Grouping per level instead would make a submenu click
    // an outside tap for the root and collapse the chain under the pointer.
    final surface = TapRegion(
      groupId: this,
      // Opaque, not the default `deferToChild`: the surface is a solid panel,
      // but the only hit-testable things inside it are the rows — so a click on
      // the 4px inset or a 2px row gap would otherwise classify as an OUTSIDE
      // tap and dismiss the menu the user is aiming at.
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        container: true,
        label: depth == 0 ? widget.semanticLabel : null,
        child: _FluentMenuEntrance(
          from: slide,
          child: buildFluentMenu(state, style, surfaceStates),
        ),
      ),
    );

    // `direction` above is the TRIGGER's, read from this State's context, but
    // the entry is inflated in the Overlay's branch where that value does not
    // reach — Directionality is NOT an InheritedTheme, so the capture at :456
    // leaves it behind. Without this the anchors are resolved against one
    // direction and the surface laid out under another, so an RTL app got an
    // LTR menu whose submenus opened off the wrong edge of their rows. Same
    // fix, same reason, as `drawer.dart:765`.
    return Directionality(
      textDirection: direction,
      child: Stack(
        children: <Widget>[
          // No dismiss barrier. Outside taps are handled by the `TapRegion`
          // group in `build`, which does not consume the pointer — see the
          // class dartdoc.
          Positioned(
            left: 0,
            top: 0,
            child: CompositedTransformFollower(
              link: level.anchorLink,
              showWhenUnlinked: false,
              targetAnchor: target,
              followerAnchor: follower,
              offset: shift,
              child: Focus(
                focusNode: level.focusNode,
                onKeyEvent: (_, event) => _handleKey(depth, event),
                child: surface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    int depth,
    int index,
    FluentThemeData theme,
    FluentMenuItemStyle? themeStyle, {
    required bool reserveLeading,
  }) {
    final level = _levels[depth];
    final item = level.items[index];
    final state = resolveFluentMenuItemState(
      label: item.label,
      enabled: item.enabled,
      checked: item.checked,
      hasSubmenu: item.hasSubmenu,
      reserveLeading: reserveLeading,
      type: item.type,
      icon: item.icon,
      secondary: item.secondary,
      trailing: item.trailing,
    );
    final style = resolveFluentMenuItemStyle(
      state,
      theme,
    ).merge(themeStyle).merge(widget.itemStyle);

    if (item.type == FluentMenuItemType.divider) {
      return ExcludeSemantics(
        child: buildFluentMenuItem(state, style, const <WidgetState>{}),
      );
    }
    if (item.type == FluentMenuItemType.header) {
      return Semantics(
        header: true,
        child: buildFluentMenuItem(state, style, const <WidgetState>{}),
      );
    }

    // Whether this row's own submenu is the level below. Read here rather than
    // in the builder because the level's entry is rebuilt whenever the chain
    // changes, which is exactly when this can flip.
    final submenuOpen =
        item.hasSubmenu && level.active == index && _levels.length > depth + 1;

    final row = MouseRegion(
      onEnter: (_) => _hoverRow(depth, index),
      child: CompositedTransformTarget(
        key: level.rowKeys.putIfAbsent(index, GlobalKey.new),
        link: level.rowLinks.putIfAbsent(index, LayerLink.new),
        child: FluentInteractive(
          enabled: item.selectable,
          onPressed: item.selectable ? () => _activate(depth, index) : null,
          // The rows are outside the traversal order on purpose: the level's
          // own node holds focus, so Tab never walks a menu row by row.
          mouseCursor:
              style.mouseCursor?.resolve(const <WidgetState>{}) ??
              SystemMouseCursors.click,
          builder: (context, states, _) => ValueListenableBuilder<bool>(
            valueListenable: FluentInputModality.keyboard,
            builder: (context, keyboard, _) =>
                buildFluentMenuItem(state, style, <WidgetState>{
                  ...states,
                  // The active row is where the keyboard is, even though the
                  // framework's focus sits on the level rather than the row.
                  // `level.active` is set by hover too (`_hoverRow`), so on its
                  // own it means "active descendant" — upstream's
                  // `data-activedescendant`. The ring belongs to its
                  // focus-visible sibling, which is this AND.
                  if (level.active == index && keyboard) WidgetState.focused,
                  // Upstream's `submenuOpen` class paints the hover ramp —
                  // fill, label and icon — on the row whose submenu is showing,
                  // however it was opened. A pointer already brings the hover
                  // state with it; a keyboard-opened row would not.
                  if (submenuOpen) WidgetState.hovered,
                  if (item.selected) WidgetState.selected,
                }),
          ),
        ),
      ),
    );

    // No `label:`. The row's own label widget is already in the tree and merges
    // into this node, so naming it here made a screen reader say it twice — the
    // same call `FluentDropdown` makes about its trigger. `checked` and
    // `selected` are null rather than false when they do not apply, because
    // passing false would announce every plain command as a checkable one.
    return Semantics(
      button: true,
      enabled: item.enabled,
      checked: item.checked ? true : null,
      selected: item.selected ? true : null,
      child: ExcludeFocus(child: row),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      expanded: _isOpen,
      child: TapRegion(
        groupId: this,
        // Registered only while open, so nothing is listening for outside taps
        // the rest of the time. A tap on the trigger itself is INSIDE this
        // group, so it never runs — it reaches `_toggle` instead, which closes
        // the chain exactly once.
        onTapOutside: _isOpen ? (_) => _closeAll() : null,
        child: CompositedTransformTarget(
          link: _triggerLink,
          child: Focus(
            focusNode: _triggerFocus,
            // Not a Tab stop of its own — the trigger inside it already is. The
            // node exists so the menu knows which of its descendants to hand
            // focus back to.
            skipTraversal: true,
            child: Builder(
              builder: (context) => widget.builder(context, _toggle),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fades a menu surface in on the frame after it is inserted.
///
/// A private widget rather than an [AnimationController] on the state:
/// [FluentAnimatedStyle] already clamps its duration to zero under
/// [MediaQuery.disableAnimationsOf], so reduced motion needs no second code
/// path here.
class _FluentMenuEntrance extends StatefulWidget {
  const _FluentMenuEntrance({required this.from, required this.child});

  /// Where the surface starts, relative to where it lands.
  final Offset from;

  final Widget child;

  @override
  State<_FluentMenuEntrance> createState() => _FluentMenuEntranceState();
}

class _FluentMenuEntranceState extends State<_FluentMenuEntrance> {
  bool _entered = false;

  @override
  void initState() {
    super.initState();
    // Post-frame, so the first build paints the `from` value and the tween has
    // somewhere to travel from. Under reduced motion the same flip lands on 1
    // immediately, because the clamped duration is zero.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _entered = true);
    });
  }

  @override
  Widget build(BuildContext context) => FluentAnimatedStyle<double>(
    value: _entered ? 1 : 0,
    spec: fluentMenuSurfaceEnter,
    lerp: lerpDouble,
    builder: (context, value) {
      final t = clampDouble(value, 0, 1);
      // One tween for both atoms, which is what `MenuSurfaceMotion` does: its
      // fade and slide share `durationSlower` and `curveDecelerateMid`.
      return Transform.translate(
        offset: widget.from * (1 - t),
        child: Opacity(opacity: t, child: widget.child),
      );
    },
  );
}
