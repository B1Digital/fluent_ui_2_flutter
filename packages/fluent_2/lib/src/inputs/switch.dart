import 'dart:ui' show lerpDouble;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import '../internal/animated_style.dart';
import '../internal/focus_ring.dart';
import '../internal/interaction.dart';
import 'switch_style.dart';

/// Track height and type ramp. Figma's `Size` axis, upstream's `size` prop.
enum FluentSwitchSize {
  /// 40x20 track, body type. The default.
  medium,

  /// 32x16 track, caption type.
  small,
}

/// Where the label sits relative to the track.
enum FluentSwitchLabelPosition {
  /// After the track in reading order. The default.
  after,

  /// Before the track in reading order.
  before,

  /// Above the track, with the whole control stacked vertically.
  above,
}

// Geometry. Medium is verified against the Figma `Switch` set, extracted into
// `test/fixtures/switch.json`; small has no Figma counterpart at all — the set
// has no Size axis — so it stays at upstream's numbers.
//
// Figma draws the medium thumb as a plain 14px ellipse. Upstream renders it as
// a `CircleFilled` glyph at `fontSize: trackHeight - 2` whose 20-unit viewBox
// paints 0.8 of the glyph box, i.e. 14.4 — so React is 0.4 wider than the
// design. Figma wins. The small thumb's 11.2 survives that correction because
// it is the same 0.7 of its track height that Figma's 14 is of 20.
const Size _trackMedium = Size(40, 20);
const Size _trackSmall = Size(32, 16);
const double _thumbMedium = 14;
const double _thumbSmall = 11.2;

// Upstream writes these as literal `translateX(20px)` / `translateX(16px)`
// (trackWidth - glyphBox - 2), never as a percentage, and griffel mirrors them
// under RTL — hence the directional inset in [buildFluentSwitch].
const double _travelMedium = 20;
const double _travelSmall = 16;

/// Everything needed to render a switch, independent of size.
///
/// The counterpart of `FluentButtonBaseState`. [buildFluentSwitch] takes this
/// rather than [FluentSwitchState], which is what makes "Fluent's state, my own
/// styling, Fluent's rendering" a supported path rather than a fork.
@immutable
class FluentSwitchBaseState {
  /// Creates a base state.
  const FluentSwitchBaseState({
    required this.enabled,
    required this.checked,
    required this.labelPosition,
    this.label,
  });

  /// Whether the switch responds to input.
  final bool enabled;

  /// Whether the switch is on.
  ///
  /// Not a [WidgetState]: [WidgetState.selected] is reserved for Fluent's real
  /// `*Selected` tokens, and a checked switch reaches for a different family
  /// entirely. See `FluentSwitchStyle` for the full argument.
  final bool checked;

  /// Where the label sits relative to the track.
  final FluentSwitchLabelPosition labelPosition;

  /// The label, if any.
  final Widget? label;
}

/// A switch's fully resolved state, including the design axes.
///
/// The counterpart of `FluentButtonState`: base state plus exactly [size].
@immutable
class FluentSwitchState extends FluentSwitchBaseState {
  /// Creates a resolved state.
  const FluentSwitchState({
    required super.enabled,
    required super.checked,
    required super.labelPosition,
    required this.size,
    super.label,
  });

  /// Track height and type ramp.
  final FluentSwitchSize size;
}

/// Builds the state a switch will be styled and rendered from.
///
/// Separated so a consumer can reuse Fluent's state resolution while
/// substituting their own styling — the first of the three-function
/// recomposition contract.
FluentSwitchState resolveFluentSwitchState({
  bool enabled = true,
  bool checked = false,
  FluentSwitchSize size = FluentSwitchSize.medium,
  FluentSwitchLabelPosition labelPosition = FluentSwitchLabelPosition.after,
  Widget? label,
}) => FluentSwitchState(
  enabled: enabled,
  checked: checked,
  size: size,
  labelPosition: labelPosition,
  label: label,
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes. Every value comes from a Fluent token; nothing
/// here computes a colour.
///
/// Token sources are the Figma `Switch` component set, extracted into
/// `test/fixtures/switch.json` and asserted variant-by-variant in the tests.
/// That set carries no Size axis, so only the medium ramp is design-verified;
/// small comes from upstream's `useSwitchStyles.styles.ts`.
FluentSwitchStyle resolveFluentSwitchStyle(
  FluentSwitchState state,
  FluentThemeData theme,
) {
  final c = theme.colors;
  final checked = state.checked;

  // Unchecked has no fill at all upstream, which is CSS `transparent` — a real
  // token here, never `Colors.transparent`, because Fluent's transparent
  // tokens turn opaque in high contrast.
  final track = checked
      ? FluentStateColor.tokens(
          rest: c.compoundBrandBackground,
          hover: c.compoundBrandBackgroundHover,
          pressed: c.compoundBrandBackgroundPressed,
          disabled: c.neutralBackgroundDisabled,
        )
      : FluentStateColor.tokens(rest: c.transparentBackground);

  // Figma paints NO stroke at all on a checked track outside Disabled, where it
  // uses `transparentStrokeDisabled`. React declares `border: 1px solid` with a
  // transparent token in every state, which is pixel-identical in a normal
  // theme and the only thing that outlines a brand-filled switch in high
  // contrast, where the token turns opaque. React wins here on purpose — see
  // doc/token-divergences.md.
  final border = checked
      ? FluentStateColor.tokens(
          rest: c.transparentStroke,
          hover: c.transparentStrokeInteractive,
          pressed: c.transparentStrokeInteractive,
          disabled: c.transparentStrokeDisabled,
        )
      : FluentStateColor.tokens(
          rest: c.neutralStrokeAccessible,
          hover: c.neutralStrokeAccessibleHover,
          pressed: c.neutralStrokeAccessiblePressed,
          disabled: c.neutralStrokeDisabled,
        );

  // The thumb is painted with the indicator's `color`, so unchecked it tracks
  // the outline through hover and press; checked it is a fixed inverted ink,
  // because the brand fill behind it does the moving.
  final thumb = checked
      ? FluentStateColor.tokens(
          rest: c.neutralForegroundInverted,
          disabled: c.neutralForegroundDisabled,
        )
      : FluentStateColor.tokens(
          rest: c.neutralStrokeAccessible,
          hover: c.neutralStrokeAccessibleHover,
          pressed: c.neutralStrokeAccessiblePressed,
          disabled: c.neutralForegroundDisabled,
        );

  final (trackSize, thumbSize, travel, textStyle) = switch (state.size) {
    FluentSwitchSize.medium => (
      _trackMedium,
      _thumbMedium,
      _travelMedium,
      theme.typography.body1,
    ),
    FluentSwitchSize.small => (
      _trackSmall,
      _thumbSmall,
      _travelSmall,
      theme.typography.caption1,
    ),
  };

  // Figma's `.SwitchBase` is 56x36 in every one of the 40 variants, label above
  // included, so the indicator's margin is a uniform `spacingVerticalS
  // spacingHorizontalS` and never shrinks. Upstream zeroes the top margin in the
  // `above` layout; that would make the stacked switch 56 tall where Figma is
  // 60, so the design wins and the extra 4 lives above the label instead.
  const trackPadding = EdgeInsets.all(FluentSpacing.s);

  // The label's padding shrinks on whichever side faces the track. Directional,
  // because upstream's `before` / `after` are reading-order, not left/right.
  final labelPadding = switch (state.labelPosition) {
    FluentSwitchLabelPosition.after => const EdgeInsetsDirectional.fromSTEB(
      FluentSpacing.xs,
      FluentSpacing.s,
      FluentSpacing.s,
      FluentSpacing.s,
    ),
    FluentSwitchLabelPosition.before => const EdgeInsetsDirectional.fromSTEB(
      FluentSpacing.s,
      FluentSpacing.s,
      FluentSpacing.xs,
      FluentSpacing.s,
    ),
    // Figma's `Horizontal labels` frame carries a 4 top inset and nothing
    // below, so the label sits 4 under the row above it and butts straight onto
    // the indicator's own 8.
    FluentSwitchLabelPosition.above => const EdgeInsets.fromLTRB(
      FluentSpacing.s,
      FluentSpacing.xs,
      FluentSpacing.s,
      0,
    ),
  };

  return FluentSwitchStyle(
    trackColor: track,
    trackBorderColor: border,
    trackBorderWidth: const WidgetStatePropertyAll<double?>(FluentStroke.thin),
    trackBorderRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allCircular,
    ),
    thumbColor: thumb,
    labelColor: FluentStateColor.tokens(
      rest: c.neutralForeground1,
      disabled: c.neutralForegroundDisabled,
    ),
    textStyle: WidgetStatePropertyAll<TextStyle?>(textStyle),
    trackSize: WidgetStatePropertyAll<Size?>(trackSize),
    thumbSize: WidgetStatePropertyAll<double?>(thumbSize),
    thumbTravel: WidgetStatePropertyAll<double?>(travel),
    trackPadding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      trackPadding,
    ),
    labelPadding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(labelPadding),
    mouseCursor: const WidgetStatePropertyAll<MouseCursor?>(
      SystemMouseCursors.click,
    ),
  );
}

/// The three colours upstream transitions together on the indicator.
///
/// `transitionProperty: 'background, border, color'` is one declaration, so
/// these interpolate as one value on one ticker rather than three.
typedef _SwitchInk = (Color track, Color border, Color thumb);

_SwitchInk? _lerpSwitchInk(_SwitchInk? a, _SwitchInk? b, double t) {
  if (a == null || b == null) return b ?? a;
  return (
    // fluentLerpColor, not Color.lerp: an unchecked track is fully transparent,
    // and Color.lerp would drag its RGB through the fade to brand.
    fluentLerpColor(a.$1, b.$1, t)!,
    fluentLerpColor(a.$2, b.$2, t)!,
    fluentLerpColor(a.$3, b.$3, t)!,
  );
}

/// Renders a switch from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentSwitchBaseState] rather than [FluentSwitchState] on purpose: it never
/// reads the size axis, so a consumer can supply their own style and still use
/// Fluent's rendering, focus ring and animation.
///
/// [states] is the live interaction set from [FluentInteractive].
Widget buildFluentSwitch(
  FluentSwitchBaseState state,
  FluentSwitchStyle style,
  Set<WidgetState> states,
) {
  const clear = Color(0x00000000);
  final trackSize = style.trackSize?.resolve(states) ?? _trackMedium;
  final thumbSize = style.thumbSize?.resolve(states) ?? _thumbMedium;
  final travel = style.thumbTravel?.resolve(states) ?? _travelMedium;
  final radius =
      style.trackBorderRadius?.resolve(states) ?? FluentRadius.allCircular;
  final borderWidth =
      style.trackBorderWidth?.resolve(states) ?? FluentStroke.none;
  final borderColor = style.trackBorderColor?.resolve(states);
  final bordered = borderWidth > 0 && borderColor != null;
  final labelColor = style.labelColor?.resolve(states);
  final textStyle = style.textStyle?.resolve(states);
  final trackPadding = style.trackPadding?.resolve(states) ?? EdgeInsets.zero;
  final labelPadding = style.labelPadding?.resolve(states) ?? EdgeInsets.zero;

  // Centring the thumb vertically also gives its resting inset from the leading
  // edge, and 2 x inset + thumb + travel is exactly the track width — which is
  // what makes the two end positions symmetric.
  final inset = (trackSize.height - thumbSize) / 2;

  final indicator = Padding(
    padding: trackPadding,
    child: SizedBox.fromSize(
      size: trackSize,
      child: FluentAnimatedStyle<_SwitchInk>(
        value: (
          style.trackColor?.resolve(states) ?? clear,
          borderColor ?? clear,
          style.thumbColor?.resolve(states) ?? clear,
        ),
        spec: FluentMotionSpec.switchTrack,
        lerp: _lerpSwitchInk,
        builder: (context, ink) => DecoratedBox(
          decoration: BoxDecoration(
            color: ink.$1,
            borderRadius: radius,
            border: bordered
                ? Border.all(color: ink.$2, width: borderWidth)
                : null,
          ),
          child: FluentAnimatedStyle<double>(
            value: state.checked ? travel : 0,
            spec: FluentMotionSpec.switchThumb,
            lerp: lerpDouble,
            // PositionedDirectional rather than a Transform: griffel mirrors
            // the translate under RTL, so the thumb must travel toward the
            // trailing edge in an RTL subtree. A Stack rather than a Padding,
            // because the track's constraints are tight and a padded child
            // would be stretched to fill whatever is left of them.
            builder: (context, offset) => Stack(
              children: <Widget>[
                PositionedDirectional(
                  start: inset + offset,
                  top: inset,
                  width: thumbSize,
                  height: thumbSize,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: ink.$3,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  final label = state.label;
  // A `Row`, even with nothing but the track in it — the same shape
  // `buildFluentCheckbox` uses for the same reason (`inputs/checkbox.dart:393`).
  // The track is a `SizedBox.fromSize`, so a parent that hands down a TIGHT
  // width stretches it: `FluentField` lays its children out with
  // `CrossAxisAlignment.stretch` (matching upstream's `display: grid` root), and
  // an unlabelled switch inside one rendered a 584px-wide track instead of 40.
  // A `mainAxisSize: min` row is still forced to the tight width, but it packs
  // its child at the start and leaves the track its own size — which is what
  // upstream's `display: inline-flex` root does.
  Widget content = Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[indicator],
  );
  if (label != null) {
    final text = Padding(
      padding: labelPadding,
      child: DefaultTextStyle.merge(
        style: (textStyle ?? const TextStyle()).copyWith(color: labelColor),
        child: label,
      ),
    );
    // Upstream's root is `align-items: flex-start`, so a label that wraps to
    // two lines grows downward and leaves the track where it was.
    content = switch (state.labelPosition) {
      FluentSwitchLabelPosition.after => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[indicator, text],
      ),
      FluentSwitchLabelPosition.before => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[text, indicator],
      ),
      FluentSwitchLabelPosition.above => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[text, indicator],
      ),
    };
  }

  // Upstream puts the focus outline on the ROOT with a `focus-within` selector,
  // so the ring surrounds the label as well as the track.
  return FluentFocusRing(
    visible: states.contains(WidgetState.focused),
    child: content,
  );
}

/// Overrides the switch style for a subtree.
///
/// The counterpart of `FluentButtonTheme`, and the middle rung of the
/// resolution order: theme defaults, then this, then the widget's own `style`.
class FluentSwitchTheme extends InheritedTheme {
  /// Applies [style] to every `FluentSwitch` in [child].
  const FluentSwitchTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the size and checked defaults.
  final FluentSwitchStyle style;

  /// The nearest switch style, or null.
  static FluentSwitchStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentSwitchTheme>()?.style;

  @override
  bool updateShouldNotify(FluentSwitchTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentSwitchTheme(style: style, child: child);
}

/// A Fluent 2 switch.
///
/// ```dart
/// FluentSwitch(
///   checked: wifi,
///   onChanged: (value) => setState(() => wifi = value),
///   label: const Text('Wi-Fi'),
/// )
/// ```
///
/// Controlled only, like every other Flutter selection control: [checked] is
/// the truth and [onChanged] reports the requested change. There is no
/// uncontrolled `defaultChecked` counterpart to upstream's, because a widget
/// that owns its own value cannot participate in a form.
///
/// Pass `onChanged: null` to disable it — disabled is a real state here, not a
/// visual treatment: the switch stops reporting hover and press, refuses focus,
/// and never invokes the callback.
///
/// Customisation follows the same three rungs Microsoft documents for the React
/// original. [style] is merged last and wins; [FluentSwitchTheme] restyles a
/// subtree; and for anything further, [resolveFluentSwitchState],
/// [resolveFluentSwitchStyle] and [buildFluentSwitch] are public so any one of
/// them can be replaced without forking this widget.
class FluentSwitch extends StatelessWidget {
  /// Creates a switch with an optional [label].
  const FluentSwitch({
    super.key,
    this.checked = false,
    this.onChanged,
    this.size = FluentSwitchSize.medium,
    this.labelPosition = FluentSwitchLabelPosition.after,
    this.label,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  /// Whether the switch is on.
  final bool checked;

  /// Invoked with the requested value on tap and on Space or Enter. Null
  /// disables the switch.
  final ValueChanged<bool>? onChanged;

  /// Track height and type ramp.
  final FluentSwitchSize size;

  /// Where the label sits relative to the track.
  final FluentSwitchLabelPosition labelPosition;

  /// The label. Optional — a switch inside a settings row often has its text
  /// somewhere else entirely.
  final Widget? label;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentSwitchStyle? style;

  /// Focus node to use. One is created internally when omitted.
  final FocusNode? focusNode;

  /// Whether to take focus on mount.
  final bool autofocus;

  /// Announced by assistive technology **in place of** the label text.
  ///
  /// Setting it excludes the label's own semantics, the way
  /// `Text.semanticsLabel` does — otherwise a screen reader would read the
  /// override and the visible text one after the other.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final labelWidget = label;
    final state = resolveFluentSwitchState(
      enabled: onChanged != null,
      checked: checked,
      size: size,
      labelPosition: labelPosition,
      label: labelWidget == null || semanticLabel == null
          ? labelWidget
          : ExcludeSemantics(child: labelWidget),
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentSwitchStyle(
      state,
      FluentTheme.of(context),
    ).merge(FluentSwitchTheme.maybeOf(context)).merge(style);

    final callback = onChanged;

    // Merged, so a screen reader announces "Wi-Fi, on" as one control rather
    // than reading the label and the toggle as two separate nodes.
    return MergeSemantics(
      child: Semantics(
        toggled: checked,
        enabled: callback != null,
        label: semanticLabel,
        child: FluentInteractive(
          onPressed: callback == null ? null : () => callback(!checked),
          enabled: callback != null,
          focusNode: focusNode,
          autofocus: autofocus,
          // FluentInteractive takes a plain cursor rather than a property, so
          // the resting one is what it gets; a per-state cursor would need the
          // state set that only exists inside the builder.
          mouseCursor:
              resolved.mouseCursor?.resolve(const <WidgetState>{}) ??
              SystemMouseCursors.click,
          builder: (context, states, _) =>
              buildFluentSwitch(state, resolved, states),
        ),
      ),
    );
  }
}
