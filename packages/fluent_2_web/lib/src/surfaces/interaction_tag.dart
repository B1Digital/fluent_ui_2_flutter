import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import '../internal/focus_ring.dart';
import '../internal/interaction.dart';
import '../l10n/l10n.dart';
import 'tag.dart';
import 'tag_style.dart';

/// Everything needed to resolve an interaction tag's style, independent of the
/// design axes.
///
/// [buildFluentInteractionTag] and [buildFluentInteractionTagDismiss] take this
/// rather than [FluentInteractionTagState], so a consumer can substitute their
/// own styling without forking either renderer.
@immutable
class FluentInteractionTagBaseState extends FluentTagBaseState {
  /// Creates a base state.
  const FluentInteractionTagBaseState({
    required super.enabled,
    required this.dismissible,
    super.label,
    super.secondaryLabel,
    super.icon,
  });

  /// Whether a dismiss half follows the primary one.
  ///
  /// The primary half needs to know: it squares off its right corners and
  /// hands its right border over to the divider.
  final bool dismissible;
}

/// An interaction tag's fully resolved state, including the design axes.
@immutable
class FluentInteractionTagState extends FluentInteractionTagBaseState {
  /// Creates a resolved state.
  const FluentInteractionTagState({
    required super.enabled,
    required super.dismissible,
    required this.appearance,
    required this.size,
    required this.selected,
    super.label,
    super.secondaryLabel,
    super.icon,
  });

  /// Fill and outline treatment.
  final FluentTagAppearance appearance;

  /// Height and type ramp.
  final FluentTagSize size;

  /// Whether the tag is chosen. See [FluentTagState.selected] for why this is
  /// an axis rather than a [WidgetState].
  final bool selected;
}

/// Builds the state an interaction tag will be styled and rendered from.
///
/// The first of the three-function recomposition contract.
FluentInteractionTagState resolveFluentInteractionTagState({
  bool enabled = true,
  bool dismissible = false,
  FluentTagAppearance appearance = FluentTagAppearance.filled,
  FluentTagSize size = FluentTagSize.medium,
  bool selected = false,
  Widget? label,
  Widget? secondaryLabel,
  Widget? icon,
}) => FluentInteractionTagState(
  enabled: enabled,
  dismissible: dismissible,
  appearance: appearance,
  size: size,
  selected: selected,
  label: label,
  secondaryLabel: secondaryLabel,
  icon: icon,
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract. Geometry, type and
/// glyph sizes are [resolveFluentTagStyle]'s — the two components share every
/// number in the Figma file — and everything below replaces the colour table
/// with the interactive one.
///
/// Token sources are the Figma `Interaction tag` set (`9112:9659`, 168
/// variants) plus the three `.Secondary action` sets that carry the dismiss
/// half's own hover and press, extracted into
/// `test/fixtures/interaction_tag.json`.
FluentTagStyle resolveFluentInteractionTagStyle(
  FluentInteractionTagState state,
  FluentThemeData theme,
) {
  final c = theme.colors;

  final background = state.selected
      // Selected erases the appearance: Filled, Outline and Brand all bind the
      // `Brand/Background/1` ramp.
      ? FluentStateColor.tokens(
          rest: c.brandBackground,
          hover: c.brandBackgroundHover,
          pressed: c.brandBackgroundPressed,
          disabled: c.neutralBackgroundDisabled,
        )
      : switch (state.appearance) {
          FluentTagAppearance.filled => FluentStateColor.tokens(
            rest: c.neutralBackground3,
            hover: c.neutralBackground3Hover,
            pressed: c.neutralBackground3Pressed,
            disabled: c.neutralBackgroundDisabled,
          ),
          FluentTagAppearance.brand => FluentStateColor.tokens(
            rest: c.brandBackground2,
            hover: c.brandBackground2Hover,
            pressed: c.brandBackground2Pressed,
            disabled: c.neutralBackgroundDisabled,
          ),
          FluentTagAppearance.outline => FluentStateColor.tokens(
            rest: c.subtleBackground,
            hover: c.subtleBackgroundHover,
            pressed: c.subtleBackgroundPressed,
            // Figma contradicts itself here: the dismissible Outline disabled
            // variants paint no fill and keep the border, the non-dismissible
            // ones paint `Neutral/Background/Disabled`. The border-only form is
            // the one the inert `Tag` set agrees with, so it wins.
            disabled: c.transparentBackground,
          ),
        };

  final foreground = state.selected
      ? FluentStateColor.tokens(
          rest: c.neutralForegroundOnBrand,
          disabled: c.neutralForegroundDisabled,
        )
      : switch (state.appearance) {
          FluentTagAppearance.filled ||
          FluentTagAppearance.outline => FluentStateColor.tokens(
            rest: c.neutralForeground2,
            hover: c.neutralForeground2Hover,
            pressed: c.neutralForeground2Pressed,
            disabled: c.neutralForegroundDisabled,
          ),
          FluentTagAppearance.brand => FluentStateColor.tokens(
            rest: c.brandForeground2,
            hover: c.brandForeground2Hover,
            pressed: c.brandForeground2Pressed,
            disabled: c.neutralForegroundDisabled,
          ),
        };

  final border =
      state.appearance == FluentTagAppearance.outline && !state.selected
      ? FluentStateColor.tokens(
          rest: c.neutralStroke1,
          hover: c.neutralStroke1Hover,
          pressed: c.neutralStroke1Pressed,
          disabled: c.neutralStrokeDisabled,
        )
      // Invisible in light and dark, opaque in high contrast. Figma paints this
      // on the dismiss half but leaves the primary half's top, left and bottom
      // bare; carrying that through would leave a filled tag with no outline at
      // all in high contrast, so the two halves are squared up here. Recorded
      // in doc/token-divergences.md.
      : FluentStateColor.tokens(rest: c.transparentStrokeInteractive);

  final divider = state.selected
      ? FluentStateColor.tokens(
          rest: c.neutralStrokeOnBrand2,
          disabled: c.neutralStrokeDisabled,
        )
      : switch (state.appearance) {
          FluentTagAppearance.filled => FluentStateColor.tokens(
            rest: c.neutralStroke2,
            disabled: c.neutralStrokeDisabled,
          ),
          FluentTagAppearance.brand => FluentStateColor.tokens(
            rest: c.brandStroke2,
            disabled: c.neutralStrokeDisabled,
          ),
          // The outline tag's divider is simply its own border carried across
          // the seam, so it ramps where the other two hold still.
          FluentTagAppearance.outline => FluentStateColor.tokens(
            rest: c.neutralStroke1,
            hover: c.neutralStroke1Hover,
            pressed: c.neutralStroke1Pressed,
            disabled: c.neutralStrokeDisabled,
          ),
        };

  // The dismiss glyph takes BRAND colour on hover and press, which is how an
  // interaction tag distinguishes "dismiss this" from "open this" while both
  // halves sit on the same fill.
  final dismissForeground = state.selected
      ? FluentStateColor.tokens(
          rest: c.neutralForegroundOnBrand,
          disabled: c.neutralForegroundDisabled,
        )
      : switch (state.appearance) {
          FluentTagAppearance.filled ||
          FluentTagAppearance.outline => FluentStateColor.tokens(
            rest: c.neutralForeground2,
            hover: c.neutralForeground2BrandHover,
            pressed: c.neutralForeground2BrandPressed,
            disabled: c.neutralForegroundDisabled,
          ),
          FluentTagAppearance.brand => FluentStateColor.tokens(
            rest: c.brandForeground2,
            hover: c.brandForeground2Hover,
            pressed: c.brandForeground2Pressed,
            disabled: c.neutralForegroundDisabled,
          ),
        };

  final dismissSize = switch (state.size) {
    FluentTagSize.extraSmall => const Size(24, 20),
    FluentTagSize.small => const Size(24, 24),
    FluentTagSize.medium => const Size(32, 32),
  };

  return resolveFluentTagStyle(
    FluentTagState(
      enabled: state.enabled,
      appearance: state.appearance,
      size: state.size,
      selected: state.selected,
      label: state.label,
      secondaryLabel: state.secondaryLabel,
      icon: state.icon,
    ),
    theme,
  ).copyWith(
    backgroundColor: background,
    foregroundColor: foreground,
    dismissForegroundColor: dismissForeground,
    borderColor: border,
    dividerColor: divider,
    dismissSize: WidgetStatePropertyAll<Size?>(dismissSize),
    mouseCursor: const WidgetStatePropertyAll<MouseCursor?>(
      SystemMouseCursors.click,
    ),
  );
}

/// Renders an interaction tag's pressable half from a resolved [state] and
/// [style].
///
/// The third of the three-function recomposition contract, and the counterpart
/// of upstream's `InteractionTagPrimary`. Reuses [buildFluentTag] outright: the
/// two components lay their content out identically, and only the shape of the
/// box around it differs.
Widget buildFluentInteractionTag(
  FluentInteractionTagBaseState state,
  FluentTagStyle style,
  Set<WidgetState> states,
) {
  final radius = style.borderRadius?.resolve(states) ?? FluentRadius.allMedium;
  final color = style.borderColor?.resolve(states);
  final divider = style.dividerColor?.resolve(states);
  final half = state.dismissible
      ? BorderRadius.only(
          topLeft: radius.topLeft,
          bottomLeft: radius.bottomLeft,
        )
      : radius;

  var primary = buildFluentTag(state, style, states, borderRadius: half);

  // The seam, drawn over the primary half's right edge — where Figma puts it;
  // React draws the same pixel as the secondary half's left border. A
  // square-cornered overlay rather than a fourth side of the surface border,
  // because Flutter will not paint a rounded rect whose sides disagree.
  //
  // Skipped when the divider and the border are the same tone, which is the
  // outline tag: there the dismiss half's own left border already draws the
  // seam, and a second rule beside it would read as 2px.
  if (state.dismissible && divider != null && divider != color) {
    primary = DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: divider, width: FluentStroke.thin),
        ),
      ),
      child: primary,
    );
  }

  return FluentFocusRing(
    visible: states.contains(WidgetState.focused),
    borderRadius: half,
    child: primary,
  );
}

/// Renders an interaction tag's dismiss half.
///
/// Upstream's `InteractionTagSecondary`: its own button, its own focus ring,
/// its own hover and press. It shares the primary half's fill *ramp* but
/// resolves it against [states] of its own, which is why hovering one half
/// leaves the other alone.
Widget buildFluentInteractionTagDismiss(
  FluentTagStyle style,
  Set<WidgetState> states, {
  required Widget icon,
}) {
  final radius = style.borderRadius?.resolve(states) ?? FluentRadius.allMedium;
  final width = style.borderWidth?.resolve(states) ?? FluentStroke.none;
  final color = style.borderColor?.resolve(states);
  final size = style.dismissSize?.resolve(states) ?? const Size(32, 32);
  final side = width > 0 && color != null
      ? BorderSide(color: color, width: width)
      : BorderSide.none;
  final half = BorderRadius.only(
    topRight: radius.topRight,
    bottomRight: radius.bottomRight,
  );

  return FluentFocusRing(
    visible: states.contains(WidgetState.focused),
    borderRadius: half,
    child: ConstrainedBox(
      constraints: BoxConstraints(minWidth: size.width, minHeight: size.height),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: style.backgroundColor?.resolve(states),
          borderRadius: half,
          // Uniform, so the rounded end can be painted at all. Figma leaves the
          // left side off; here it lands exactly under the primary half's
          // divider, invisible on every appearance whose border is the
          // transparent token and identical in tone on the one whose is not.
          border: side == BorderSide.none ? null : Border.fromBorderSide(side),
        ),
        child: Center(
          child: IconTheme.merge(
            data: IconThemeData(
              color: style.dismissForegroundColor?.resolve(states),
              size: style.iconSize?.resolve(states) ?? FluentSize.size200,
            ),
            child: icon,
          ),
        ),
      ),
    ),
  );
}

/// Overrides the interaction tag style for a subtree.
class FluentInteractionTagTheme extends InheritedTheme {
  /// Applies [style] to every [FluentInteractionTag] in [child].
  const FluentInteractionTagTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the appearance and size defaults.
  final FluentTagStyle style;

  /// The nearest interaction tag style, or null.
  static FluentTagStyle? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FluentInteractionTagTheme>()
      ?.style;

  @override
  bool updateShouldNotify(FluentInteractionTagTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentInteractionTagTheme(style: style, child: child);
}

/// A Fluent 2 interaction tag: a tag that is also a control.
///
/// ```dart
/// FluentInteractionTag(
///   selected: filters.contains(tag),
///   onPressed: () => toggle(tag),
///   onDismiss: () => remove(tag),
///   child: const Text('Design'),
/// )
/// ```
///
/// Where `FluentTag` labels something, this one acts. The two halves are
/// **independently interactive** — hovering the dismiss half does not light the
/// primary one, and each takes focus and Space/Enter on its own — which is why
/// each gets its own [FluentInteractive] rather than sharing one surface.
///
/// Pass `onPressed: null` to disable it: the tag stops reporting hover and
/// press, refuses focus on both halves, and never invokes either callback.
///
/// Nothing animates. All three upstream styles files — `useTagStyles`,
/// `useInteractionTagPrimaryStyles` and `useInteractionTagSecondaryStyles` —
/// declare no transition at all, so the fill changes on the frame the pointer
/// arrives.
class FluentInteractionTag extends StatelessWidget {
  /// Creates an interaction tag labelled [child].
  const FluentInteractionTag({
    super.key,
    required this.child,
    this.onPressed,
    this.secondaryChild,
    this.icon,
    this.appearance = FluentTagAppearance.filled,
    this.size = FluentTagSize.medium,
    this.selected = false,
    this.onDismiss,
    this.dismissIcon,
    this.dismissSemanticLabel,
    this.style,
    this.focusNode,
    this.dismissFocusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  /// The primary line.
  final Widget child;

  /// Invoked on tap and on Space or Enter. Null disables the whole tag.
  final VoidCallback? onPressed;

  /// The second line. Figma only draws two lines at [FluentTagSize.medium].
  final Widget? secondaryChild;

  /// Leading media — an avatar or an icon.
  final Widget? icon;

  /// Fill and outline treatment.
  final FluentTagAppearance appearance;

  /// Height and type ramp.
  final FluentTagSize size;

  /// Whether the tag is chosen. Selected overrides [appearance]: all three
  /// render as a brand-filled tag.
  final bool selected;

  /// Invoked when the dismiss half is activated. Null omits that half.
  final VoidCallback? onDismiss;

  /// Replaces the built-in [FluentTagDismissGlyph].
  final Widget? dismissIcon;

  /// Announced for the dismiss half, which has no text of its own.
  ///
  /// Null takes the wording from the ambient [FluentLocalizations],
  /// which falls back to English when no delegate is installed.
  final String? dismissSemanticLabel;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentTagStyle? style;

  /// Focus node for the primary half.
  final FocusNode? focusNode;

  /// Focus node for the dismiss half.
  final FocusNode? dismissFocusNode;

  /// Whether the primary half takes focus on mount.
  final bool autofocus;

  /// Announced by assistive technology in place of the label.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final state = resolveFluentInteractionTagState(
      enabled: enabled,
      dismissible: onDismiss != null,
      appearance: appearance,
      size: size,
      selected: selected,
      label: child,
      secondaryLabel: secondaryChild,
      icon: icon,
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentInteractionTagStyle(
      state,
      FluentTheme.of(context),
    ).merge(FluentInteractionTagTheme.maybeOf(context)).merge(style);

    final primary = Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: semanticLabel,
      child: FluentInteractive(
        onPressed: onPressed,
        enabled: enabled,
        focusNode: focusNode,
        autofocus: autofocus,
        mouseCursor:
            resolved.mouseCursor?.resolve(const <WidgetState>{}) ??
            SystemMouseCursors.click,
        builder: (context, states, _) {
          final half = buildFluentInteractionTag(state, resolved, states);
          if (!state.dismissible || !states.contains(WidgetState.focused)) {
            return half;
          }
          // `useInteractionTagPrimaryStyles` raises the focused half's outline
          // with `zIndex: 1`, so its right band lands *on top of* the dismiss
          // half and the seam reads as a solid 2px bar. Flutter's Row paints
          // siblings in order and the dismiss half's opaque fill would swallow
          // that band, so the same 2px of `strokeFocus2` is drawn inside the
          // primary's own box instead — one ring-width to the left of where the
          // browser puts it, and the only way to get it without a Stack that
          // would have to re-measure both halves every frame.
          return DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: FluentTheme.of(context).colors.strokeFocus2,
                  width: FluentStroke.thick,
                ),
              ),
            ),
            child: half,
          );
        },
      ),
    );

    if (onDismiss == null) return primary;

    return IntrinsicHeight(
      // Stretch, so the shorter half grows to the taller one and the two round
      // ends line up; IntrinsicHeight is what gives the row a height to stretch
      // to, since neither half has one of its own.
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          primary,
          Semantics(
            button: true,
            enabled: enabled,
            label: dismissSemanticLabel ?? fluentL10n(context).dismiss,
            child: FluentInteractive(
              onPressed: onDismiss,
              enabled: enabled,
              focusNode: dismissFocusNode,
              builder: (context, states, _) => buildFluentInteractionTagDismiss(
                resolved,
                states,
                icon: dismissIcon ?? const FluentTagDismissGlyph(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
