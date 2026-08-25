import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import '../internal/interaction.dart';
import 'link_style.dart';

/// How a link is coloured.
///
/// Names follow the Figma `Style` axis, except that `Default` is a Dart
/// reserved word and is spelled [standard] here.
enum FluentLinkAppearance {
  /// Brand-coloured link text. Figma's `Default`.
  standard,

  /// Neutral link text, for links inside dense or already-coloured content.
  subtle,

  /// Inverted link text, for links sitting on a brand-filled surface.
  overBrand,
}

/// Everything needed to render a link, independent of appearance.
///
/// The counterpart of `FluentButtonBaseState`. [buildFluentLink] takes this
/// rather than [FluentLinkState], which is what makes "Fluent's state, my own
/// styling, Fluent's rendering" a supported path rather than a fork.
@immutable
class FluentLinkBaseState {
  /// Creates a base state.
  const FluentLinkBaseState({
    required this.enabled,
    required this.label,
    this.icon,
  });

  /// Whether the link responds to input.
  final bool enabled;

  /// The link text. Always present — Figma's `Text#41437:0` property is not
  /// optional, and a link with no text has nothing to activate.
  final Widget label;

  /// Optional trailing icon. Figma's `Show Icon#23193:0` boolean, which places
  /// it after the label in reading order.
  final Widget? icon;
}

/// A link's fully resolved state, including the design axes.
///
/// The counterpart of `FluentButtonState`: base state plus exactly [appearance]
/// and [inline].
@immutable
class FluentLinkState extends FluentLinkBaseState {
  /// Creates a resolved state.
  const FluentLinkState({
    required super.enabled,
    required super.label,
    required this.appearance,
    required this.inline,
    super.icon,
  });

  /// Colour treatment.
  final FluentLinkAppearance appearance;

  /// Whether the link is underlined at rest.
  ///
  /// Figma's `Inline style#23206:31` boolean, and React's `inline` prop. Set it
  /// for a link inside a paragraph, where colour alone is not enough to
  /// distinguish it from the prose around it.
  final bool inline;
}

/// Builds the state a link will be styled and rendered from.
///
/// Separated so a consumer can reuse Fluent's state resolution while
/// substituting their own styling — the first of the three-function
/// recomposition contract.
FluentLinkState resolveFluentLinkState({
  required Widget label,
  bool enabled = true,
  FluentLinkAppearance appearance = FluentLinkAppearance.standard,
  bool inline = false,
  Widget? icon,
}) => FluentLinkState(
  enabled: enabled,
  appearance: appearance,
  inline: inline,
  icon: icon,
  label: label,
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes. Every value comes from a Fluent token; nothing
/// here computes a colour.
///
/// Token sources are the Figma `Link` component set, extracted into
/// `test/fixtures/link.json` and asserted variant-by-variant in the tests.
FluentLinkStyle resolveFluentLinkStyle(
  FluentLinkState state,
  FluentThemeData theme,
) {
  final c = theme.colors;

  // Figma's State axis is `Rest/Visited` — a visited link is NOT styled
  // separately, so there is no visited token to select and no history to track.
  final foreground = switch (state.appearance) {
    FluentLinkAppearance.standard => FluentStateColor.tokens(
      rest: c.brandForegroundLink,
      hover: c.brandForegroundLinkHover,
      pressed: c.brandForegroundLinkPressed,
      disabled: c.neutralForegroundDisabled,
    ),
    FluentLinkAppearance.subtle => FluentStateColor.tokens(
      rest: c.neutralForeground2Link,
      hover: c.neutralForeground2LinkHover,
      pressed: c.neutralForeground2LinkPressed,
      disabled: c.neutralForegroundDisabled,
    ),
    FluentLinkAppearance.overBrand => FluentStateColor.tokens(
      rest: c.neutralForegroundInvertedLink,
      hover: c.neutralForegroundInvertedLinkHover,
      pressed: c.neutralForegroundInvertedLinkPressed,
      disabled: c.neutralForegroundDisabled,
    ),
  };

  // The focused underline is the odd one out. Default and Subtle recolour it to
  // the focus stroke; OverBrand keeps its own resting ink, because a black
  // focus stroke on a brand fill would disappear.
  final focusInk = switch (state.appearance) {
    FluentLinkAppearance.standard ||
    FluentLinkAppearance.subtle => c.strokeFocus2,
    FluentLinkAppearance.overBrand => c.neutralForegroundInvertedLink,
  };

  final inline = state.inline;

  return FluentLinkStyle(
    foregroundColor: foreground,
    decoration: WidgetStateProperty.resolveWith<TextDecoration?>(
      (states) => inline || _interacting(states)
          ? TextDecoration.underline
          : TextDecoration.none,
    ),
    // FluentStateColor.tokens has no focused slot — Fluent ships no `*Focus`
    // colour variants, because focus is normally a ring rather than a recolour.
    // A link is the exception, so the focused branch is selected here and the
    // rest of the set still comes from the token property above.
    decorationColor: WidgetStateProperty.resolveWith<Color?>(
      (states) => _focusOnly(states) ? focusInk : foreground.resolve(states),
    ),
    decorationStyle: WidgetStateProperty.resolveWith<TextDecorationStyle?>(
      (states) => _focusOnly(states)
          ? TextDecorationStyle.double
          : TextDecorationStyle.solid,
    ),
    decorationThickness: const WidgetStatePropertyAll<double?>(
      FluentStroke.thin,
    ),
    textStyle: WidgetStatePropertyAll<TextStyle?>(theme.typography.body1),
    padding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(EdgeInsets.zero),
    gap: const WidgetStatePropertyAll<double?>(FluentSpacing.xs),
    iconSize: const WidgetStatePropertyAll<double?>(FluentSize.size200),
    mouseCursor: const WidgetStatePropertyAll<MouseCursor?>(
      SystemMouseCursors.click,
    ),
  );
}

/// Whether the link is being hovered, pressed or keyboard-focused.
///
/// All three underline in Figma; rest and disabled do not.
bool _interacting(Set<WidgetState> states) =>
    states.contains(WidgetState.hovered) ||
    states.contains(WidgetState.pressed) ||
    states.contains(WidgetState.focused);

/// Whether focus is the only thing the underline should answer to.
///
/// A focused link that is also hovered or pressed shows the interaction ink:
/// Figma has no combined variant, and the pointer is the more immediate signal.
bool _focusOnly(Set<WidgetState> states) =>
    states.contains(WidgetState.focused) &&
    !states.contains(WidgetState.disabled) &&
    !states.contains(WidgetState.pressed) &&
    !states.contains(WidgetState.hovered);

/// Renders a link from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentLinkBaseState] rather than [FluentLinkState] on purpose: it never
/// reads appearance or inline, so a consumer can supply their own style and
/// still use Fluent's rendering and interaction.
///
/// [states] is the live interaction set from [FluentInteractive].
///
/// There is no `FluentFocusRing` here and no animation, and both absences are
/// deliberate. Figma draws the Link focus indicator as a doubled underline
/// under the text rather than a ring around it, and neither Figma nor upstream
/// declares a transition on the set — see `doc/token-divergences.md`.
Widget buildFluentLink(
  FluentLinkBaseState state,
  FluentLinkStyle style,
  Set<WidgetState> states,
) {
  final foreground = style.foregroundColor?.resolve(states);
  final textStyle = style.textStyle?.resolve(states);
  final padding = style.padding?.resolve(states) ?? EdgeInsets.zero;
  final gap = style.gap?.resolve(states) ?? FluentSpacing.xs;
  final iconSize = style.iconSize?.resolve(states) ?? FluentSize.size200;

  final label = DefaultTextStyle.merge(
    style: (textStyle ?? const TextStyle()).copyWith(
      color: foreground,
      decoration: style.decoration?.resolve(states),
      decorationColor: style.decorationColor?.resolve(states),
      decorationStyle: style.decorationStyle?.resolve(states),
      decorationThickness: style.decorationThickness?.resolve(states),
    ),
    child: state.label,
  );

  final icon = state.icon;
  final content = icon == null
      ? label
      : Row(
          mainAxisSize: MainAxisSize.min,
          // Figma's counterAxisAlignItems is MIN: the icon sits on the text's
          // cap line, not on its optical centre.
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: gap,
          children: <Widget>[
            label,
            IconTheme.merge(
              data: IconThemeData(color: foreground, size: iconSize),
              child: icon,
            ),
          ],
        );

  return Padding(padding: padding, child: content);
}

/// Overrides the link style for a subtree.
///
/// The counterpart of `FluentButtonTheme`, and the middle rung of the
/// resolution order: theme defaults, then this, then the widget's own `style`.
class FluentLinkTheme extends InheritedTheme {
  /// Applies [style] to every `FluentLink` in [child].
  const FluentLinkTheme({super.key, required this.style, required super.child});

  /// The style layered over the appearance defaults.
  final FluentLinkStyle style;

  /// The nearest link style, or null.
  static FluentLinkStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentLinkTheme>()?.style;

  @override
  bool updateShouldNotify(FluentLinkTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentLinkTheme(style: style, child: child);
}

/// A Fluent 2 link.
///
/// ```dart
/// FluentLink(
///   onPressed: () => open(uri),
///   icon: const Icon(FluentIcons.open_20_regular),
///   child: const Text('Fluent 2 docs'),
/// )
/// ```
///
/// Underlined on hover, press and keyboard focus; underlined at rest only when
/// [inline] is set. Focus doubles the underline and recolours it, which is
/// Figma's focus indicator for this component — a link does not take a focus
/// ring.
///
/// Figma's State axis is `Rest/Visited`, so a visited link is **not** styled
/// separately and this widget tracks no history.
///
/// Pass `onPressed: null` to disable it — disabled is a real state here, not a
/// visual treatment: the link stops reporting hover and press, refuses focus,
/// and never invokes the callback.
///
/// Customisation follows the same three rungs Microsoft documents for the React
/// original. [style] is merged last and wins; [FluentLinkTheme] restyles a
/// subtree; and for anything further, [resolveFluentLinkState],
/// [resolveFluentLinkStyle] and [buildFluentLink] are public so any one of them
/// can be replaced without forking this widget.
class FluentLink extends StatelessWidget {
  /// Creates a link with a [child] label and an optional trailing [icon].
  const FluentLink({
    super.key,
    required this.child,
    this.onPressed,
    this.appearance = FluentLinkAppearance.standard,
    this.inline = false,
    this.icon,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  /// The link text.
  final Widget child;

  /// Invoked on tap and on Space or Enter. Null disables the link.
  ///
  /// There is no `href` here on purpose: this package does not depend on a URL
  /// launcher, and a link that scrolls, routes or opens a dialog is just as
  /// legitimate as one that navigates.
  final VoidCallback? onPressed;

  /// Colour treatment.
  final FluentLinkAppearance appearance;

  /// Whether to underline at rest, for a link sitting inside prose.
  final bool inline;

  /// Optional trailing icon.
  final Widget? icon;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentLinkStyle? style;

  /// Focus node to use. One is created internally when omitted.
  final FocusNode? focusNode;

  /// Whether to take focus on mount.
  final bool autofocus;

  /// Announced by assistive technology **in place of** the label text.
  ///
  /// Useful when the visible text is "here" or "read more" and the destination
  /// is only clear from the surrounding prose. Setting it excludes the label's
  /// own semantics, the way `Text.semanticsLabel` does — otherwise a screen
  /// reader would read the override and the visible text one after the other.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final state = resolveFluentLinkState(
      enabled: onPressed != null,
      appearance: appearance,
      inline: inline,
      icon: icon,
      label: semanticLabel == null ? child : ExcludeSemantics(child: child),
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentLinkStyle(
      state,
      FluentTheme.of(context),
    ).merge(FluentLinkTheme.maybeOf(context)).merge(style);

    return Semantics(
      link: true,
      enabled: onPressed != null,
      label: semanticLabel,
      child: FluentInteractive(
        onPressed: onPressed,
        enabled: onPressed != null,
        focusNode: focusNode,
        autofocus: autofocus,
        // FluentInteractive takes a plain cursor rather than a property, so the
        // resting one is what it gets; a per-state cursor would need the state
        // set that only exists inside the builder.
        mouseCursor:
            resolved.mouseCursor?.resolve(const <WidgetState>{}) ??
            SystemMouseCursors.click,
        builder: (context, states, _) =>
            buildFluentLink(state, resolved, states),
      ),
    );
  }
}
