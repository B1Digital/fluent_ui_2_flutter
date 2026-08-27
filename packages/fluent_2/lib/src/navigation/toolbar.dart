import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../internal/interaction.dart';
import '../surfaces/divider.dart';
import 'toolbar_style.dart';

/// Toolbar padding ramp. Figma's `Size` axis.
///
/// The axis moves the toolbar's **own** inset and nothing else. Every Figma
/// variant, at all three sizes, holds 32-high medium buttons, and upstream's
/// `useToolbarButton` hard-codes `size: 'medium'` — so a small toolbar is a
/// tighter frame around the same controls, not a smaller set of them.
enum FluentToolbarSize {
  /// `0 4`. 32 high around a medium button.
  small,

  /// `4 8`. 40 high. The default.
  medium,

  /// `8 20`. 48 high.
  large,
}

/// Whether the toolbar sits in the page or floats over it. Figma's `Type` axis.
enum FluentToolbarType {
  /// Flat, no elevation. Figma calls this `Static`. The default.
  standard,

  /// The same surface lifted onto `FluentElevation.shadow8`. Figma's
  /// `Contextual (floating)`.
  floating,
}

/// Everything needed to render a toolbar, independent of size and type.
///
/// The counterpart of `FluentButtonBaseState`. [buildFluentToolbar] takes this
/// rather than [FluentToolbarState], which is what makes "Fluent's state, my own
/// styling, Fluent's rendering" a supported path rather than a fork.
@immutable
class FluentToolbarBaseState {
  /// Creates a base state.
  const FluentToolbarBaseState({required this.items});

  /// The row's children, in order, already wrapped for roving focus by
  /// [FluentToolbar]. Dividers are ordinary members of this list.
  final List<Widget> items;
}

/// A toolbar's fully resolved state, including the design axes.
@immutable
class FluentToolbarState extends FluentToolbarBaseState {
  /// Creates a resolved state.
  const FluentToolbarState({
    required super.items,
    required this.size,
    required this.type,
  });

  /// How far the surface is inset from its content.
  final FluentToolbarSize size;

  /// Whether the surface is elevated.
  final FluentToolbarType type;
}

/// Builds the state a toolbar will be styled and rendered from.
///
/// The first of the three-function recomposition contract.
FluentToolbarState resolveFluentToolbarState({
  required List<Widget> items,
  FluentToolbarSize size = FluentToolbarSize.medium,
  FluentToolbarType type = FluentToolbarType.standard,
}) => FluentToolbarState(items: items, size: size, type: type);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes. Every value comes from a Fluent token; nothing
/// here computes a colour.
///
/// Token sources are the Figma `Toolbar` set (page `8934:24`, set
/// `9383:24495`, 6 variants), extracted into `test/fixtures/toolbar.json` and
/// asserted variant-by-variant in the tests. All six variants bind the identical
/// surface — `Neutral/Background/1/Rest` over `Neutral/Stroke/Transparent/Rest`
/// at `Stroke width/Thin`, `Corner-radius/Modal/Medium` — so `Type` changes
/// exactly one thing, the elevation, and `Size` exactly one, the padding.
FluentToolbarStyle resolveFluentToolbarStyle(
  FluentToolbarState state,
  FluentThemeData theme,
) {
  final c = theme.colors;

  // Read off the `Start-content` / `End-content` frames, which is where Figma
  // puts the inset: the variant frame itself binds Spacing/None on all four
  // sides and the two content frames carry the real numbers, mirrored.
  final (horizontal, vertical) = switch (state.size) {
    FluentToolbarSize.small => (FluentSpacing.xs, FluentSpacing.none),
    FluentToolbarSize.medium => (FluentSpacing.s, FluentSpacing.xs),
    FluentToolbarSize.large => (FluentSpacing.xl, FluentSpacing.s),
  };

  return FluentToolbarStyle(
    backgroundColor: FluentStateColor.tokens(rest: c.neutralBackground1),
    // Not null and not `Colors.transparent`: `transparentStroke` is invisible in
    // light and dark and turns opaque in high contrast, where it is the only
    // thing separating the toolbar from the page behind it.
    borderColor: FluentStateColor.tokens(rest: c.transparentStroke),
    borderWidth: const WidgetStatePropertyAll<double?>(FluentStroke.thin),
    borderRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allMedium,
    ),
    padding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
    ),
    gap: const WidgetStatePropertyAll<double?>(FluentSpacing.none),
    shadow: WidgetStatePropertyAll<List<BoxShadow>?>(switch (state.type) {
      FluentToolbarType.standard => null,
      // The two `Shadow/Key` + `Shadow/Ambient` effects the three floating
      // variants bind: ambient (0,0) blur 2 at 12%, key (0,4) blur 8 at 14%.
      FluentToolbarType.floating => theme.shadow(FluentElevation.shadow8),
    }),
    dividerWidth: const WidgetStatePropertyAll<double?>(FluentSize.size240),
    dividerPadding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.symmetric(vertical: FluentSpacing.sNudge),
    ),
  );
}

/// Renders a toolbar from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentToolbarBaseState] rather than [FluentToolbarState] on purpose: it
/// never reads the size or the type, so a consumer can supply their own style
/// and still use Fluent's layout.
///
/// ## Motion: none, and that is the spec
///
/// `useToolbarStyles.styles.ts` and `useToolbarDividerStyles.styles.ts` on
/// `microsoft/fluentui@master` declare **no transition, no animation and no
/// `motionTokens` reference at all**. A change of size or type therefore lands
/// on the next frame, exactly like `FluentDivider` and `FluentCheckbox`. There
/// is no [AnimationController] here and nothing for
/// `MediaQuery.disableAnimationsOf` to shorten — a toolbar is already correct
/// under reduced motion because it never moves. The buttons inside it animate
/// their own surfaces through `FluentAnimatedStyle`, which handles reduced
/// motion itself.
///
/// [states] exists for symmetry with the interactive components and is normally
/// empty — a toolbar is a container and reports no interaction state of its own.
/// It is still honoured, so a caller passing a state-dependent style gets what
/// they asked for.
Widget buildFluentToolbar(
  FluentToolbarBaseState state,
  FluentToolbarStyle style,
  Set<WidgetState> states,
) {
  final radius = style.borderRadius?.resolve(states) ?? FluentRadius.allMedium;
  final borderWidth = style.borderWidth?.resolve(states) ?? FluentStroke.none;
  final borderColor = style.borderColor?.resolve(states);
  final padding = style.padding?.resolve(states) ?? EdgeInsets.zero;
  final gap = style.gap?.resolve(states) ?? FluentSpacing.none;

  return DecoratedBox(
    decoration: BoxDecoration(
      color: style.backgroundColor?.resolve(states),
      borderRadius: radius,
      border: borderWidth > 0 && borderColor != null
          ? Border.all(color: borderColor, width: borderWidth)
          : null,
      boxShadow: style.shadow?.resolve(states),
    ),
    child: Padding(
      padding: padding,
      // ponytail: IntrinsicHeight is what lets a divider span exactly the item
      // row rather than a hard-coded 32 — it is the only way a Row can tell a
      // child "be as tall as your tallest sibling". A toolbar holds a handful of
      // shallow items so the extra layout pass is not worth optimising; if a
      // toolbar ever holds a deep subtree, pin `dividerPadding` and give the
      // divider a fixed height instead.
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: gap,
          children: state.items,
        ),
      ),
    ),
  );
}

/// Overrides the toolbar style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`. [FluentToolbarDivider] reads it too, so restyling a
/// subtree restyles the rules along with the surface.
class FluentToolbarTheme extends InheritedTheme {
  /// Applies [style] to every `FluentToolbar` in [child].
  const FluentToolbarTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the size and type defaults.
  final FluentToolbarStyle style;

  /// The nearest toolbar style, or null.
  static FluentToolbarStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentToolbarTheme>()?.style;

  @override
  bool updateShouldNotify(FluentToolbarTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentToolbarTheme(style: style, child: child);
}

/// Moves the roving focus by [FluentToolbarMoveIntent.delta] items.
///
/// Public so an app can rebind the arrow keys — or bind more of them — without
/// forking [FluentToolbar].
class FluentToolbarMoveIntent extends Intent {
  /// Creates an intent to move the roving focus.
  const FluentToolbarMoveIntent(this.delta);

  /// How many items to move. Negative walks towards the start of the row. In an
  /// RTL subtree the horizontal arrows are swapped before this is dispatched,
  /// so `1` always means "towards the end of the item list".
  final int delta;
}

/// The vertical rule that separates groups of toolbar items.
///
/// A thin wrapper around [FluentDivider], not a reimplementation: the rule, its
/// `Neutral/Stroke/2/Rest` token and its hairline thickness are all the
/// divider's. This adds only the slot geometry Figma puts around it — 24 wide,
/// inset 6 from the top and bottom of the item row.
///
/// It is an ordinary member of [FluentToolbar.items] and carries no focusable
/// descendant, so the arrow keys step straight over it.
class FluentToolbarDivider extends StatelessWidget {
  /// Creates a toolbar divider.
  const FluentToolbarDivider({super.key, this.style});

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentToolbarStyle? style;

  @override
  Widget build(BuildContext context) {
    // Size and type do not reach the divider — all six Figma variants draw the
    // identical 24 x (row - 12) slot — so the base state is enough to resolve
    // the two properties this reads.
    final resolved = resolveFluentToolbarStyle(
      resolveFluentToolbarState(items: const <Widget>[]),
      FluentTheme.of(context),
    ).merge(FluentToolbarTheme.maybeOf(context)).merge(style);

    const states = <WidgetState>{};
    final width = resolved.dividerWidth?.resolve(states) ?? FluentSize.size240;
    final padding = resolved.dividerPadding?.resolve(states) ?? EdgeInsets.zero;

    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        // Fills the row's height, which `buildFluentToolbar`'s IntrinsicHeight
        // has already made finite.
        height: double.infinity,
        child: Padding(
          padding: padding,
          child: const FluentDivider(vertical: true),
        ),
      ),
    );
  }
}

/// A Fluent 2 toolbar: a row of buttons, toggles and dividers on one surface.
///
/// ```dart
/// FluentToolbar(
///   items: <Widget>[
///     FluentButton.icon(
///       icon: const Icon(FluentIcons.text_bold_20_regular),
///       semanticLabel: 'Bold',
///       appearance: FluentButtonAppearance.subtle,
///       onPressed: () {},
///     ),
///     const FluentToolbarDivider(),
///     FluentButton.icon(
///       icon: const Icon(FluentIcons.link_20_regular),
///       semanticLabel: 'Link',
///       appearance: FluentButtonAppearance.subtle,
///       onPressed: () {},
///     ),
///   ],
/// )
/// ```
///
/// The toolbar composes rather than wraps: [items] are whatever widgets you
/// pass, normally `FluentButton`s with
/// `appearance: FluentButtonAppearance.subtle` — which is what all six Figma
/// variants use — and [FluentToolbarDivider]s between groups. There is no
/// `FluentToolbarButton`, because upstream's is a `Button` with `subtle` and
/// `size: 'medium'` pinned and nothing else.
///
/// ## Keyboard: one tab stop, arrows inside
///
/// The whole toolbar is a single stop in the Tab order (upstream's roving
/// tabindex, via `useArrowNavigationGroup`). Tab moves in and straight back out;
/// Left and Right — and Up and Down, matching upstream's `axis: 'both'` — move
/// between items and **wrap around**, matching upstream's `circular: true`. The
/// index is remembered, so Tabbing away and back returns to the item you left.
///
/// Items with nothing focusable under them are skipped: a divider, and a
/// disabled `FluentButton`, which refuses focus outright rather than merely
/// looking greyed out.
///
/// Escape is deliberately **not** handled. A toolbar has nothing to dismiss, so
/// the key travels on to whatever dialog, drawer or popover contains it.
///
/// ## Overflow is not modelled
///
/// The Figma set has no overflow affordance — no "more" button, no menu, no
/// hidden-item count on any of the six variants — and upstream's overflow is a
/// separate `react-overflow` package a consumer composes in. Rather than invent
/// one, [FluentToolbar] lays its items out in a row that hugs its content;
/// wrap it in a `SingleChildScrollView` or supply your own overflow menu as the
/// last item.
///
/// ## Motion
///
/// None. See [buildFluentToolbar].
///
/// Customisation follows the usual three rungs. [style] is merged last and
/// wins; [FluentToolbarTheme] restyles a subtree; and for anything further,
/// [resolveFluentToolbarState], [resolveFluentToolbarStyle] and
/// [buildFluentToolbar] are public so any one of them can be replaced without
/// forking this widget.
class FluentToolbar extends StatefulWidget {
  /// Creates a toolbar over [items].
  const FluentToolbar({
    super.key,
    required this.items,
    this.size = FluentToolbarSize.medium,
    this.type = FluentToolbarType.standard,
    this.style,
    this.semanticLabel,
  });

  /// The row's children, in order. Dividers are ordinary members.
  final List<Widget> items;

  /// How far the surface is inset from its content.
  final FluentToolbarSize size;

  /// Whether the surface is elevated.
  final FluentToolbarType type;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentToolbarStyle? style;

  /// Announced by assistive technology as the name of the group.
  final String? semanticLabel;

  @override
  State<FluentToolbar> createState() => _FluentToolbarState();
}

class _FluentToolbarState extends State<FluentToolbar> {
  /// One node per item, wrapping it. None of these can take focus itself; they
  /// exist so the toolbar can find the item's own focusable descendant and can
  /// gate the item's subtree out of the Tab order.
  final List<FocusNode> _wrappers = <FocusNode>[];

  /// The item that currently owns the toolbar's single tab stop.
  int _active = 0;

  @override
  void initState() {
    super.initState();
    _syncWrappers();
    // The focus tree does not exist until the first build, so "is item 0
    // actually focusable" cannot be answered before then.
    WidgetsBinding.instance.addPostFrameCallback((_) => _settleActive());
  }

  @override
  void didUpdateWidget(FluentToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.length != oldWidget.items.length) _syncWrappers();
    // Not gated on the length: disabling the item that holds the tab stop
    // leaves the list exactly as long and the toolbar with zero tab stops.
    // The settle is cheap and idempotent — it early-returns unless the active
    // item has actually lost its focusable descendant.
    WidgetsBinding.instance.addPostFrameCallback((_) => _settleActive());
  }

  @override
  void dispose() {
    for (final node in _wrappers) {
      node.dispose();
    }
    super.dispose();
  }

  void _syncWrappers() {
    while (_wrappers.length < widget.items.length) {
      _wrappers.add(
        FocusNode(debugLabel: 'FluentToolbar item ${_wrappers.length}'),
      );
    }
    while (_wrappers.length > widget.items.length) {
      _wrappers.removeLast().dispose();
    }
    if (_active >= widget.items.length) _active = 0;
  }

  /// The item's own focusable node — a `FluentButton`'s, normally.
  ///
  /// Null for a divider, and null for a disabled control, which is what makes
  /// both skippable without the toolbar having to be told which is which.
  FocusNode? _focusable(int index) {
    if (index < 0 || index >= _wrappers.length) return null;
    for (final node in _wrappers[index].descendants) {
      if (node.canRequestFocus) return node;
    }
    return null;
  }

  /// The first focusable item at or after [from], walking by [delta] and
  /// wrapping around. Null when no item can take focus at all.
  int? _seek(int from, int delta) {
    final count = widget.items.length;
    if (count == 0) return null;
    for (var step = 0; step < count; step++) {
      final index = (from + delta * step) % count;
      if (_focusable(index) != null) return index;
    }
    return null;
  }

  /// Parks the tab stop on an item that can actually receive it.
  ///
  /// Without this a toolbar whose first item is a divider or a disabled button
  /// would have zero tab stops instead of one.
  void _settleActive() {
    if (!mounted) return;
    if (_focusable(_active) == null) {
      final target = _seek(_active, 1);
      if (target != null && target != _active) setState(() => _active = target);
    }
    _unlatch();
  }

  /// Clears the `skipTraversal` the active item latched onto its own node while
  /// its gate was shut.
  ///
  /// Re-parking the index is not enough on its own. `Focus.skipTraversal` falls
  /// back to `focusNode.skipTraversal` when the widget passes none, and *that*
  /// getter is derived: it reports true while any ancestor has
  /// `descendantsAreTraversable: false`. An item built on
  /// `FocusableActionDetector` passes none, so the first shut gate makes the
  /// item write the derived true back onto its own node as a hard flag, and the
  /// item then stays out of the Tab order for good, gate or no gate. One
  /// assignment per settle undoes it, and the item's next build writes the
  /// cleared value straight back, so it sticks. `_FluentNavState._unlatch` is
  /// the same fix for the same framework behaviour.
  void _unlatch() => _focusable(_active)?.skipTraversal = false;

  void _move(int delta) {
    final target = _seek(_active + delta, delta);
    if (target == null || target == _active) return;
    _focusable(target)?.requestFocus();
    setState(() => _active = target);
  }

  /// Keeps the roving index on whichever item the user actually reached, so a
  /// click and an arrow press leave the toolbar in the same state.
  void _handleFocusChange(int index, {required bool hasFocus}) {
    if (hasFocus && _active != index && mounted) {
      setState(() => _active = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Arrow keys are physical; the item list is logical. In an RTL subtree the
    // two disagree, and it is the arrows that must bend.
    final rtl = Directionality.of(context) == TextDirection.rtl;

    final wrapped = <Widget>[
      for (var i = 0; i < widget.items.length; i++)
        Focus(
          focusNode: _wrappers[i],
          // This node is a handle, not a stop: it never takes focus itself, and
          // it hides its subtree from Tab unless it holds the roving index.
          // That — one traversable subtree at a time — is what a roving
          // tabindex *is*.
          canRequestFocus: false,
          skipTraversal: true,
          descendantsAreTraversable: i == _active,
          onFocusChange: (value) => _handleFocusChange(i, hasFocus: value),
          child: widget.items[i],
        ),
    ];

    final state = resolveFluentToolbarState(
      items: wrapped,
      size: widget.size,
      type: widget.type,
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentToolbarStyle(
      state,
      FluentTheme.of(context),
    ).merge(FluentToolbarTheme.maybeOf(context)).merge(widget.style);

    return Semantics(
      container: true,
      label: widget.semanticLabel,
      child: Shortcuts(
        shortcuts: <ShortcutActivator, Intent>{
          const SingleActivator(LogicalKeyboardKey.arrowRight):
              FluentToolbarMoveIntent(rtl ? -1 : 1),
          const SingleActivator(LogicalKeyboardKey.arrowLeft):
              FluentToolbarMoveIntent(rtl ? 1 : -1),
          // Upstream's arrow navigation group is `axis: 'both'`, so the vertical
          // arrows walk the same row.
          const SingleActivator(LogicalKeyboardKey.arrowDown):
              const FluentToolbarMoveIntent(1),
          const SingleActivator(LogicalKeyboardKey.arrowUp):
              const FluentToolbarMoveIntent(-1),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            FluentToolbarMoveIntent: CallbackAction<FluentToolbarMoveIntent>(
              onInvoke: (intent) {
                _move(intent.delta);
                return null;
              },
            ),
          },
          child: buildFluentToolbar(state, resolved, const <WidgetState>{}),
        ),
      ),
    );
  }
}
