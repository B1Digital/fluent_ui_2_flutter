import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import '../internal/anchor_metrics.dart';
import '../internal/defer.dart';
import '../internal/focus_ring.dart';
import '../internal/interaction.dart';
import 'info_button_style.dart';

/// Below this much room above the trigger, an info tip flips underneath.
///
/// A tip squeezed into a sliver of space is worse than one on the other side:
/// it wraps to a column of single words. 64 is two lines of `caption1` plus the
/// surface inset.
const double _kMinUsableTip = 64;

/// Trigger box and glyph size. Figma's `Size` axis on the `.Info button` set.
///
/// The box does *not* ramp with the glyph: [medium] and [large] are both 24
/// squares, and large simply spends less of that box on padding.
enum FluentInfoButtonSize {
  /// A 20 box holding a 12 glyph, inset 4.
  small,

  /// A 24 box holding a 16 glyph, inset 4. The default.
  medium,

  /// A 24 box holding a 20 glyph, inset 2.
  large,
}

/// Everything needed to render an info button, independent of size.
///
/// The Dart counterpart of upstream's `InfoButtonState` minus its design axis.
/// [buildFluentInfoButton] takes this rather than [FluentInfoButtonState],
/// which is what makes "Fluent's state, my own styling, Fluent's rendering" a
/// supported path rather than a fork.
@immutable
class FluentInfoButtonBaseState {
  /// Creates a base state.
  const FluentInfoButtonBaseState({
    required this.enabled,
    required this.icon,
    required this.activeIcon,
    required this.info,
  });

  /// Whether the trigger responds to input.
  final bool enabled;

  /// The resting glyph. `Info{12,16,20}Regular` unless the caller supplied one.
  final Widget icon;

  /// The glyph shown while hovered, pressed or open.
  ///
  /// A second widget rather than a filter over [icon] because upstream swaps
  /// icon *components*: `useInfoButtonStyles` renders both the regular and the
  /// filled glyph and shows one or the other, and Figma agrees — the `Shape`
  /// vector under a Rest variant is a different component from the one under
  /// Hover, Pressed and Selected.
  final Widget activeIcon;

  /// The tip body, shown while the button is open.
  final Widget info;
}

/// An info button's fully resolved state, including the design axis.
///
/// The counterpart of `FluentButtonState`: base state plus exactly `size`.
@immutable
class FluentInfoButtonState extends FluentInfoButtonBaseState {
  /// Creates a resolved state.
  const FluentInfoButtonState({
    required super.enabled,
    required super.icon,
    required super.activeIcon,
    required super.info,
    required this.size,
  });

  /// Trigger box and glyph size.
  final FluentInfoButtonSize size;
}

/// The default resting glyph for [size]. `Info{12,16,20}Regular`.
IconData fluentInfoButtonIcon(FluentInfoButtonSize size) => switch (size) {
  FluentInfoButtonSize.small => FluentIcons.info_12_regular,
  FluentInfoButtonSize.medium => FluentIcons.info_16_regular,
  FluentInfoButtonSize.large => FluentIcons.info_20_regular,
};

/// The default hovered, pressed and open glyph for [size].
/// `Info{12,16,20}Filled`.
IconData fluentInfoButtonActiveIcon(FluentInfoButtonSize size) =>
    switch (size) {
      FluentInfoButtonSize.small => FluentIcons.info_12_filled,
      FluentInfoButtonSize.medium => FluentIcons.info_16_filled,
      FluentInfoButtonSize.large => FluentIcons.info_20_filled,
    };

/// Builds the state an info button will be styled and rendered from.
///
/// The first of the three-function recomposition contract, and the only place
/// the glyph pair is chosen — exactly as `useInfoButton_unstable` picks its
/// icon component before styling runs. Passing [icon] without [activeIcon]
/// suppresses the swap, which is what upstream's single `icon` slot does too.
FluentInfoButtonState resolveFluentInfoButtonState({
  required Widget info,
  bool enabled = true,
  FluentInfoButtonSize size = FluentInfoButtonSize.medium,
  Widget? icon,
  Widget? activeIcon,
}) {
  final resting = icon ?? Icon(fluentInfoButtonIcon(size));
  return FluentInfoButtonState(
    enabled: enabled,
    size: size,
    info: info,
    icon: resting,
    activeIcon:
        activeIcon ??
        (icon == null ? Icon(fluentInfoButtonActiveIcon(size)) : resting),
  );
}

/// Width at which tip content wraps.
///
/// `useInfoButtonStyles.styles.ts` says `maxWidth: '264px'` on the popover
/// slot. There is no token for it, so the number is transcribed.
const double _infoMaxWidth = 264;

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axis. Every colour comes from a Fluent token selected
/// through [FluentStateColor]; nothing here computes one.
///
/// The trigger's table is the **transparent button's**, token for token:
/// `Neutral/Background/Transparent/{Rest,Hover,Pressed,Selected}` behind
/// `Neutral/Foreground/2/Rest` going brand on interaction. That is not a
/// coincidence to be refactored away — it is what the Figma `.Info button` set
/// binds on all 15 variants, and `test/fixtures/info_button.json` asserts it
/// variant by variant.
///
/// **Disabled is an extrapolation.** Neither the Figma set nor
/// `useInfoButtonStyles.styles.ts` has a disabled state at all — the `State`
/// axis is Rest, Hover, Pressed, Selected and Focus. The fill stays on the rest
/// token (the button paints nothing at rest, so there is nothing to grey) and
/// the glyph takes `neutralForegroundDisabled`, matching every other component
/// in this package.
///
/// The `info*` half describes the tip surface. `usePopoverSurfaceStyles`
/// supplies the surface itself — `neutralBackground1`, a thin
/// `transparentStroke`, `borderRadiusMedium` and `shadow16` — while
/// `useInfoButtonStyles` supplies the two values that depend on the button's
/// own size: the padding (12 at small and medium, 16 at large, since the button
/// maps its three sizes onto the popover's `small` and `medium`) and the type
/// ramp.
FluentInfoButtonStyle resolveFluentInfoButtonStyle(
  FluentInfoButtonState state,
  FluentThemeData theme,
) {
  final c = theme.colors;

  final (padding, iconSize, infoPadding, infoTextStyle) = switch (state.size) {
    FluentInfoButtonSize.small => (
      FluentSpacing.xs,
      FluentSize.size120,
      FluentSpacing.m,
      theme.typography.caption1,
    ),
    FluentInfoButtonSize.medium => (
      FluentSpacing.xs,
      FluentSize.size160,
      FluentSpacing.m,
      theme.typography.caption1,
    ),
    FluentInfoButtonSize.large => (
      FluentSpacing.xxs,
      FluentSize.size200,
      FluentSpacing.l,
      theme.typography.body1,
    ),
  };

  return FluentInfoButtonStyle(
    backgroundColor: FluentStateColor.tokens(
      rest: c.transparentBackground,
      hover: c.transparentBackgroundHover,
      pressed: c.transparentBackgroundPressed,
      selected: c.transparentBackgroundSelected,
      // The rest token, not a disabled one: the trigger paints no surface at
      // rest, so there is nothing for a disabled fill to dim. Still a real
      // token — a hardcoded transparent would stay invisible in high contrast,
      // where this one turns opaque.
      disabled: c.transparentBackground,
    ),
    foregroundColor: FluentStateColor.tokens(
      rest: c.neutralForeground2,
      hover: c.neutralForeground2BrandHover,
      pressed: c.neutralForeground2BrandPressed,
      selected: c.neutralForeground2BrandSelected,
      disabled: c.neutralForegroundDisabled,
    ),
    borderRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allMedium,
    ),
    padding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.all(padding),
    ),
    iconSize: WidgetStatePropertyAll<double?>(iconSize),
    mouseCursor: const WidgetStatePropertyAll<MouseCursor?>(
      SystemMouseCursors.click,
    ),
    infoBackgroundColor: FluentStateColor.tokens(rest: c.neutralBackground1),
    infoForegroundColor: FluentStateColor.tokens(rest: c.neutralForeground1),
    // Transparent, not absent: this turns into canvasText in high contrast,
    // which is the only thing separating the surface from the page there.
    infoBorderColor: FluentStateColor.tokens(rest: c.transparentStroke),
    infoBorderWidth: const WidgetStatePropertyAll<double?>(FluentStroke.thin),
    infoBorderRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allMedium,
    ),
    infoPadding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.all(infoPadding),
    ),
    infoMaxWidth: const WidgetStatePropertyAll<double?>(_infoMaxWidth),
    infoTextStyle: WidgetStatePropertyAll<TextStyle?>(infoTextStyle),
    infoShadow: WidgetStatePropertyAll<List<BoxShadow>?>(
      theme.shadow(FluentElevation.shadow16),
    ),
    infoOffset: const WidgetStatePropertyAll<double?>(FluentSpacing.xs),
  );
}

/// Renders an info button's trigger from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentInfoButtonBaseState] rather than [FluentInfoButtonState] on purpose:
/// it never reads the size, so a consumer can supply their own style and still
/// use Fluent's layout, focus ring and glyph swap.
///
/// **Nothing animates, deliberately.** `useInfoButtonStyles.styles.ts` and
/// `useInfoLabelStyles.styles.ts` contain no `transition`, no `motionTokens`
/// reference and no duration of any kind, so the fill and the glyph change on
/// the frame the pointer arrives. That also makes this trivially correct under
/// `MediaQuery.disableAnimationsOf`: there is no animation to shorten.
///
/// [states] is the live interaction set from [FluentInteractive], plus
/// [WidgetState.selected] while the tip is open — which is a *real* Fluent
/// Selected token here (`Neutral/Background/Transparent/Selected`), not focus
/// borrowing the slot.
Widget buildFluentInfoButton(
  FluentInfoButtonBaseState state,
  FluentInfoButtonStyle style,
  Set<WidgetState> states,
) {
  final radius = style.borderRadius?.resolve(states) ?? FluentRadius.allMedium;
  final background = style.backgroundColor?.resolve(states);
  final foreground = style.foregroundColor?.resolve(states);
  final padding = style.padding?.resolve(states) ?? EdgeInsets.zero;
  final iconSize = style.iconSize?.resolve(states) ?? FluentSize.size160;

  final active =
      states.contains(WidgetState.hovered) ||
      states.contains(WidgetState.pressed) ||
      states.contains(WidgetState.selected);

  return FluentFocusRing(
    visible: states.contains(WidgetState.focused),
    borderRadius: radius,
    child: DecoratedBox(
      decoration: BoxDecoration(color: background, borderRadius: radius),
      child: Padding(
        padding: padding,
        child: SizedBox(
          width: iconSize,
          height: iconSize,
          child: IconTheme.merge(
            data: IconThemeData(color: foreground, size: iconSize),
            child: active ? state.activeIcon : state.icon,
          ),
        ),
      ),
    ),
  );
}

/// Renders the tip surface from a resolved [state] and [style].
///
/// **Provisional.** `FluentPopover` does not exist yet; when it lands in Wave 4
/// it owns the *positioning, dismissal and focus management* of this surface
/// and this function goes away. The numbers do not move with it — upstream
/// keeps `maxWidth` and the type ramp in `useInfoButtonStyles.styles.ts`, on
/// the info button's own `popover` slot, which is why they live on
/// [FluentInfoButtonStyle] rather than in a popover API invented here.
///
/// Deliberately paints no arrow. Upstream passes `withArrow` to `Popover`, so
/// the arrow is the popover's, not the info button's.
Widget buildFluentInfoTip(
  FluentInfoButtonBaseState state,
  FluentInfoButtonStyle style,
  Set<WidgetState> states,
) {
  final background = style.infoBackgroundColor?.resolve(states);
  final foreground = style.infoForegroundColor?.resolve(states);
  final borderColor = style.infoBorderColor?.resolve(states);
  final borderWidth =
      style.infoBorderWidth?.resolve(states) ?? FluentStroke.none;
  final radius =
      style.infoBorderRadius?.resolve(states) ?? FluentRadius.allMedium;
  final padding = style.infoPadding?.resolve(states) ?? EdgeInsets.zero;
  final maxWidth = style.infoMaxWidth?.resolve(states) ?? double.infinity;
  final textStyle = style.infoTextStyle?.resolve(states);

  var content = state.info;
  if (textStyle != null || foreground != null) {
    content = DefaultTextStyle.merge(
      style: (textStyle ?? const TextStyle()).copyWith(color: foreground),
      child: content,
    );
  }

  return ConstrainedBox(
    constraints: BoxConstraints(maxWidth: maxWidth),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: radius,
        border: borderWidth > 0 && borderColor != null
            ? Border.all(color: borderColor, width: borderWidth)
            : null,
        boxShadow: style.infoShadow?.resolve(states),
      ),
      child: Padding(padding: padding, child: content),
    ),
  );
}

/// Overrides the info button style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`.
class FluentInfoButtonTheme extends InheritedTheme {
  /// Applies [style] to every [FluentInfoButton] in [child].
  const FluentInfoButtonTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the size defaults.
  final FluentInfoButtonStyle style;

  /// The nearest info button style, or null.
  static FluentInfoButtonStyle? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FluentInfoButtonTheme>()
      ?.style;

  @override
  bool updateShouldNotify(FluentInfoButtonTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentInfoButtonTheme(style: style, child: child);
}

/// A Fluent 2 info button — the ⓘ that opens a tip beside a label.
///
/// ```dart
/// FluentInfoButton(
///   semanticLabel: 'About the retention period',
///   info: const Text('Deleted items are kept for 30 days.'),
/// )
/// ```
///
/// Toggles on click and on Space or Enter, and closes on Escape or on a tap
/// outside itself and the tip. Open is a *real* Fluent Selected state, not a
/// visual flag: the trigger resolves
/// `Neutral/Background/Transparent/Selected` and the brand Selected foreground
/// while the tip is up, which is what the Figma `State=Selected (Popover open)`
/// variants bind.
///
/// ## The tip is provisional
///
/// `FluentPopover` lands in Wave 4 and will own this surface — its positioning,
/// its arrow, its dismissal and its focus trap. Until then the tip is a plain
/// [OverlayEntry] anchored with [CompositedTransformFollower], placed above and
/// start-aligned, which is upstream's `positioning: 'above-start'`. The
/// *trigger contract* — [info], [onOpenChanged], open as a Selected state — is
/// what Wave 4 will keep; do not build on the overlay itself.
///
/// ## No motion
///
/// Verified against `useInfoButtonStyles.styles.ts` and
/// `useInfoLabelStyles.styles.ts` on `microsoft/fluentui@master`: neither
/// declares a transition, a duration or a curve. The fill, the glyph and the
/// tip all change on the frame the state does. See [buildFluentInfoButton].
///
/// Customisation follows the usual three rungs. [style] is merged last and
/// wins; [FluentInfoButtonTheme] restyles a subtree; and
/// [resolveFluentInfoButtonState], [resolveFluentInfoButtonStyle],
/// [buildFluentInfoButton] and [buildFluentInfoTip] are public so any one of
/// them can be replaced without forking this widget.
class FluentInfoButton extends StatefulWidget {
  /// Creates an info button showing [info] when opened.
  const FluentInfoButton({
    super.key,
    required this.info,
    required this.semanticLabel,
    this.size = FluentInfoButtonSize.medium,
    this.icon,
    this.activeIcon,
    this.enabled = true,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.onOpenChanged,
  });

  /// The tip body. Wraps at 264 logical pixels.
  final Widget info;

  /// Announced by assistive technology.
  ///
  /// Required, not optional: the trigger is a glyph with no text, so without
  /// this a screen reader announces an unlabelled button. Upstream's
  /// `InfoButton` defaults it to "information"; naming the subject it explains
  /// is better.
  final String semanticLabel;

  /// Trigger box and glyph size.
  final FluentInfoButtonSize size;

  /// Overrides the resting glyph. Suppresses the filled swap unless
  /// [activeIcon] is also given.
  final Widget? icon;

  /// Overrides the hovered, pressed and open glyph.
  final Widget? activeIcon;

  /// Whether the button responds to input.
  ///
  /// False is a real state, not a greyed-out one: the button stops reporting
  /// hover and press, refuses focus, closes an open tip and never opens
  /// another.
  final bool enabled;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentInfoButtonStyle? style;

  /// Focus node to use. One is created internally when omitted.
  final FocusNode? focusNode;

  /// Whether to take focus on mount.
  final bool autofocus;

  /// Called with the new open state whenever the tip opens or closes.
  final ValueChanged<bool>? onOpenChanged;

  @override
  State<FluentInfoButton> createState() => _FluentInfoButtonState();
}

class _FluentInfoButtonState extends State<FluentInfoButton> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;

  late FluentThemeData _theme;
  FluentInfoButtonStyle? _themeStyle;

  bool _open = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Resolved here rather than in the overlay's builder: the overlay sits
    // outside this subtree, so a FluentThemeOverride or FluentInfoButtonTheme
    // wrapping the trigger would otherwise be invisible to it.
    _theme = FluentTheme.of(context);
    _themeStyle = FluentInfoButtonTheme.maybeOf(context);
    deferOrRun(() => _entry?.markNeedsBuild());
  }

  @override
  void didUpdateWidget(FluentInfoButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _open) {
      // No setState: a widget update has already scheduled this rebuild, and
      // setState from didUpdateWidget would mark an element dirty that is
      // being rebuilt right now.
      _open = false;
      widget.onOpenChanged?.call(false);
    }
    deferOrRun(() {
      _entry?.markNeedsBuild();
      _syncEntry();
    });
  }

  @override
  void dispose() {
    _removeEntry();
    super.dispose();
  }

  void _toggle() => _setOpen(open: !_open);

  void _close() => _setOpen(open: false);

  void _setOpen({required bool open}) {
    final next = open && widget.enabled;
    if (next == _open) return;
    setState(() => _open = next);
    widget.onOpenChanged?.call(next);
    _syncEntry();
  }

  /// Brings the [Overlay] in line with [_open].
  void _syncEntry() {
    if (_open == (_entry != null)) return;
    if (!_open) {
      _removeEntry();
      return;
    }
    final overlay = Overlay.of(context, debugRequiredFor: widget);
    // FluentTheme is an InheritedTheme, so this carries it — and any other
    // InheritedTheme between here and the overlay — across the boundary.
    // ponytail: captured once, at show time. The resolved style is refreshed on
    // every dependency change, so a theme swap while open still repaints; only
    // a theme read by `info` itself would go stale.
    final captured = InheritedTheme.capture(from: context, to: overlay.context);
    _entry = OverlayEntry(builder: (_) => captured.wrap(_buildFollower()));
    overlay.insert(_entry!);
  }

  void _removeEntry() {
    final entry = _entry;
    if (entry == null) return;
    _entry = null;
    entry
      ..remove()
      ..dispose();
  }

  Widget _buildFollower() {
    final state = _resolveState();
    final style = _resolveStyle(state);
    const states = <WidgetState>{};
    final offset = style.infoOffset?.resolve(states) ?? FluentSpacing.none;

    // Upstream's `positioning: 'above-start'` is a *preference*, not a fixed
    // side — its positioning layer flips to below when the tip would be clipped.
    // Hardcoding above meant an info button near the top of the page opened its
    // tip off-screen entirely. `_kMinUsableTip` keeps a tip from flipping into a
    // sliver of room; `autocomplete.dart:614-618` uses the same heuristic.
    final room = fluentAnchorRoom(context);
    final below = room.above < _kMinUsableTip && room.below > room.above;

    return Positioned(
      left: 0,
      top: 0,
      child: CompositedTransformFollower(
        link: _link,
        showWhenUnlinked: false,
        targetAnchor: below ? Alignment.bottomLeft : Alignment.topLeft,
        followerAnchor: below ? Alignment.topLeft : Alignment.bottomLeft,
        offset: Offset(0, below ? offset : -offset),
        // Same group as the trigger, so tapping the tip does not dismiss it.
        child: TapRegion(
          groupId: this,
          child: Semantics(
            container: true,
            child: buildFluentInfoTip(state, style, states),
          ),
        ),
      ),
    );
  }

  FluentInfoButtonState _resolveState() => resolveFluentInfoButtonState(
    enabled: widget.enabled,
    size: widget.size,
    info: widget.info,
    icon: widget.icon,
    activeIcon: widget.activeIcon,
  );

  /// Lowest to highest: defaults, subtree theme, then the caller's own style.
  FluentInfoButtonStyle _resolveStyle(FluentInfoButtonState state) =>
      resolveFluentInfoButtonStyle(
        state,
        _theme,
      ).merge(_themeStyle).merge(widget.style);

  @override
  Widget build(BuildContext context) {
    final state = _resolveState();
    final resolved = _resolveStyle(state);

    final button = FluentInteractive(
      onPressed: widget.enabled ? _toggle : null,
      enabled: widget.enabled,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      mouseCursor:
          resolved.mouseCursor?.resolve(const <WidgetState>{}) ??
          SystemMouseCursors.click,
      builder: (context, states, _) => buildFluentInfoButton(state, resolved, {
        ...states,
        if (_open) WidgetState.selected,
      }),
    );

    return Semantics(
      button: true,
      enabled: widget.enabled,
      expanded: _open,
      label: widget.semanticLabel,
      child: TapRegion(
        groupId: this,
        // Registered only while open, so Escape keeps whatever meaning the
        // surrounding app gives it the rest of the time.
        onTapOutside: _open ? (_) => _close() : null,
        child: Actions(
          actions: <Type, Action<Intent>>{
            if (_open)
              DismissIntent: CallbackAction<DismissIntent>(
                onInvoke: (_) {
                  _close();
                  return null;
                },
              ),
          },
          child: CompositedTransformTarget(link: _link, child: button),
        ),
      ),
    );
  }
}
