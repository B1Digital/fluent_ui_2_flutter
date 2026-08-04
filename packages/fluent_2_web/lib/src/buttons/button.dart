import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import '../internal/animated_style.dart';
import '../internal/focus_ring.dart';
import '../internal/interaction.dart';
import 'button_style.dart';

/// How a button is filled and outlined.
///
/// Names and defaults follow the Figma `Style` axis verbatim.
enum FluentButtonAppearance {
  /// Neutral fill with a border. The default.
  secondary,

  /// Brand fill, used for the single primary action in a view.
  primary,

  /// Transparent fill with a border.
  outline,

  /// No border; the fill appears only on hover.
  subtle,

  /// No border and no fill in any state; the label picks up brand colour on
  /// hover.
  transparent,
}

/// Button height and type ramp. Figma's `Size` axis.
enum FluentButtonSize {
  /// 24 high, caption type.
  small,

  /// 32 high, body type. The default.
  medium,

  /// 40 high, subtitle type.
  large,
}

/// Corner treatment. Figma's `Shape` variable collection.
enum FluentButtonShape {
  /// `FluentRadius.medium`. The default.
  rounded,

  /// Fully rounded ends.
  circular,

  /// Square corners.
  square,
}

/// Which side of the label the icon sits on.
enum FluentButtonIconPosition {
  /// Before the label in reading order. The default.
  before,

  /// After the label in reading order.
  after,
}

/// Everything needed to resolve a button's style, independent of appearance,
/// size and shape.
///
/// The Dart counterpart of upstream's `ButtonBaseState`. [buildFluentButton]
/// takes this rather than [FluentButtonState], which is what makes "Fluent's
/// state, my own styling, Fluent's rendering" a supported path rather than a
/// fork.
@immutable
class FluentButtonBaseState {
  /// Creates a base state.
  const FluentButtonBaseState({
    required this.enabled,
    required this.iconPosition,
    this.icon,
    this.label,
  });

  /// Whether the button responds to input.
  final bool enabled;

  /// Which side the icon sits on.
  final FluentButtonIconPosition iconPosition;

  /// The icon, if any.
  final Widget? icon;

  /// The label, if any. A button with no label is an icon-only button.
  final Widget? label;

  /// Whether this renders as an icon-only button.
  bool get iconOnly => label == null && icon != null;
}

/// A button's fully resolved state, including the design axes.
///
/// The counterpart of upstream's `ButtonState`: base state plus exactly
/// `appearance`, `size` and `shape`.
@immutable
class FluentButtonState extends FluentButtonBaseState {
  /// Creates a resolved state.
  const FluentButtonState({
    required super.enabled,
    required super.iconPosition,
    required this.appearance,
    required this.size,
    required this.shape,
    super.icon,
    super.label,
  });

  /// Fill and outline treatment.
  final FluentButtonAppearance appearance;

  /// Height and type ramp.
  final FluentButtonSize size;

  /// Corner treatment.
  final FluentButtonShape shape;
}

/// Builds the state a button will be styled and rendered from.
///
/// Separated so a consumer can reuse Fluent's state resolution while
/// substituting their own styling — the first of the three-function
/// recomposition contract.
FluentButtonState resolveFluentButtonState({
  bool enabled = true,
  FluentButtonAppearance appearance = FluentButtonAppearance.secondary,
  FluentButtonSize size = FluentButtonSize.medium,
  FluentButtonShape shape = FluentButtonShape.rounded,
  FluentButtonIconPosition iconPosition = FluentButtonIconPosition.before,
  Widget? icon,
  Widget? label,
}) => FluentButtonState(
  enabled: enabled,
  appearance: appearance,
  size: size,
  shape: shape,
  iconPosition: iconPosition,
  icon: icon,
  label: label,
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes. Every value comes from a Fluent token; nothing
/// here computes a colour.
///
/// Token sources are the Figma `Button` component set, extracted into
/// `test/fixtures/button.json` and asserted variant-by-variant in the tests.
FluentButtonStyle resolveFluentButtonStyle(
  FluentButtonState state,
  FluentThemeData theme,
) {
  final c = theme.colors;

  final background = switch (state.appearance) {
    FluentButtonAppearance.primary => FluentStateColor.tokens(
      rest: c.brandBackground,
      hover: c.brandBackgroundHover,
      pressed: c.brandBackgroundPressed,
      selected: c.brandBackgroundSelected,
      disabled: c.neutralBackgroundDisabled,
    ),
    FluentButtonAppearance.secondary => FluentStateColor.tokens(
      rest: c.neutralBackground1,
      hover: c.neutralBackground1Hover,
      pressed: c.neutralBackground1Pressed,
      selected: c.neutralBackground1Selected,
      disabled: c.neutralBackgroundDisabled,
    ),
    FluentButtonAppearance.outline ||
    FluentButtonAppearance.transparent => FluentStateColor.tokens(
      rest: c.transparentBackground,
      hover: c.transparentBackgroundHover,
      pressed: c.transparentBackgroundPressed,
      selected: c.transparentBackgroundSelected,
      // `transparentBackground`, not `transparentStroke`: the stroke token is
      // deliberately OPAQUE in high contrast (`canvasText`), so using it as a
      // fill painted a disabled outline button solid in the text colour and
      // hid its own label. `useRootDisabledStyles.outline` upstream keeps
      // `colorTransparentBackground` here, and so does the subtle branch below.
      disabled: c.transparentBackground,
    ),
    FluentButtonAppearance.subtle => FluentStateColor.tokens(
      rest: c.subtleBackground,
      hover: c.subtleBackgroundHover,
      pressed: c.subtleBackgroundPressed,
      selected: c.subtleBackgroundSelected,
      disabled: c.transparentBackground,
    ),
  };

  final foreground = switch (state.appearance) {
    FluentButtonAppearance.primary => FluentStateColor.tokens(
      rest: c.neutralForegroundOnBrand,
      disabled: c.neutralForegroundDisabled,
    ),
    FluentButtonAppearance.secondary ||
    FluentButtonAppearance.outline => FluentStateColor.tokens(
      rest: c.neutralForeground1,
      hover: c.neutralForeground1Hover,
      pressed: c.neutralForeground1Pressed,
      selected: c.neutralForeground1Pressed,
      disabled: c.neutralForegroundDisabled,
    ),
    FluentButtonAppearance.subtle => FluentStateColor.tokens(
      rest: c.neutralForeground2,
      hover: c.neutralForeground1Hover,
      pressed: c.neutralForeground1Pressed,
      selected: c.neutralForeground1Pressed,
      disabled: c.neutralForegroundDisabled,
    ),
    // Transparent is the odd one: its label takes BRAND colour on interaction,
    // which is why it cannot share the subtle mapping.
    FluentButtonAppearance.transparent => FluentStateColor.tokens(
      rest: c.neutralForeground2,
      hover: c.neutralForeground2BrandHover,
      pressed: c.neutralForeground2BrandPressed,
      selected: c.neutralForeground2BrandSelected,
      disabled: c.neutralForegroundDisabled,
    ),
  };

  final bordered =
      state.appearance == FluentButtonAppearance.secondary ||
      state.appearance == FluentButtonAppearance.outline;

  final border = bordered
      ? FluentStateColor.tokens(
          rest: c.neutralStroke1,
          hover: c.neutralStroke1Hover,
          pressed: c.neutralStroke1Pressed,
          selected: c.neutralStroke1Selected,
          disabled: c.neutralStrokeDisabled,
        )
      : null;

  // Geometry, verbatim from the Figma Button set — except the Large glyph,
  // which Figma models as an instance rather than a token. That one comes from
  // `useIconStyles.large { fontSize/height/width: '24px' }` against 20 at the
  // other two sizes, and is what makes a Large icon-and-label button 40 high on
  // 8px of vertical padding.
  final (padding, gap, height, iconSize, textStyle) = switch (state.size) {
    FluentButtonSize.small => (
      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      FluentSpacing.xs,
      24.0,
      FluentSize.size200,
      theme.typography.caption1,
    ),
    FluentButtonSize.medium => (
      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      FluentSpacing.sNudge,
      32.0,
      FluentSize.size200,
      theme.typography.body1Strong,
    ),
    FluentButtonSize.large => (
      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      FluentSpacing.sNudge,
      40.0,
      FluentSize.size240,
      theme.typography.subtitle2,
    ),
  };

  final radius = switch (state.shape) {
    FluentButtonShape.rounded => FluentRadius.allMedium,
    FluentButtonShape.circular => FluentRadius.allCircular,
    FluentButtonShape.square => BorderRadius.zero,
  };

  return FluentButtonStyle(
    backgroundColor: background,
    foregroundColor: foreground,
    borderColor: border,
    borderWidth: WidgetStatePropertyAll<double?>(
      bordered ? FluentStroke.thin : FluentStroke.none,
    ),
    borderRadius: WidgetStatePropertyAll<BorderRadius?>(radius),
    textStyle: WidgetStatePropertyAll<TextStyle?>(textStyle),
    padding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(padding),
    gap: WidgetStatePropertyAll<double?>(gap),
    iconSize: WidgetStatePropertyAll<double?>(iconSize),
    // DIVERGENCE, reported rather than followed: `useButtonStyles.styles.ts`
    // floors a labelled button at `minWidth: '96px'` (64 at small), and a live
    // probe renders a text-only Medium at exactly 96x32. Figma states no floor
    // — its frames hug their contents — so the two do not actually conflict,
    // and the floor was briefly adopted here.
    //
    // It is reverted because it does not stand alone. React can afford 96 in a
    // TeachingPopover footer only because that surface is 320 wide; Figma's is
    // 288 (`_contentWidth`, test-guarded), and two floored buttons plus the
    // carousel overflow it. Adopting the floor therefore requires adopting
    // React's 320 as well — one decision, not two. Until that is made, the
    // width stays content-driven.
    minimumSize: WidgetStatePropertyAll<Size?>(Size(0, height)),
    mouseCursor: const WidgetStatePropertyAll<MouseCursor?>(
      SystemMouseCursors.click,
    ),
  );
}

/// Renders a button from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentButtonBaseState] rather than [FluentButtonState] on purpose: it never
/// reads appearance, size or shape, so a consumer can supply their own style
/// and still use Fluent's rendering, focus ring and animation.
///
/// [states] is the live interaction set from [FluentInteractive].
Widget buildFluentButton(
  FluentButtonBaseState state,
  FluentButtonStyle style,
  Set<WidgetState> states,
) {
  final radius = style.borderRadius?.resolve(states) ?? FluentRadius.allMedium;
  final borderWidth = style.borderWidth?.resolve(states) ?? FluentStroke.none;
  final borderColor = style.borderColor?.resolve(states);
  final foreground = style.foregroundColor?.resolve(states);
  final padding = style.padding?.resolve(states) ?? EdgeInsets.zero;
  final gap = style.gap?.resolve(states) ?? FluentSpacing.sNudge;
  final iconSize = style.iconSize?.resolve(states) ?? FluentSize.size200;
  final minimumSize = style.minimumSize?.resolve(states) ?? Size.zero;
  final textStyle = style.textStyle?.resolve(states);

  final children = <Widget>[
    if (state.icon != null)
      IconTheme.merge(
        data: IconThemeData(color: foreground, size: iconSize),
        child: state.icon!,
      ),
    if (state.label != null) state.label!,
  ];

  Widget content = switch (state.iconPosition) {
    FluentButtonIconPosition.before => Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: state.icon != null && state.label != null ? gap : 0,
      children: children,
    ),
    FluentButtonIconPosition.after => Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: state.icon != null && state.label != null ? gap : 0,
      children: children.reversed.toList(),
    ),
  };

  if (textStyle != null || foreground != null) {
    content = DefaultTextStyle.merge(
      style: (textStyle ?? const TextStyle()).copyWith(color: foreground),
      child: content,
    );
  }

  // The surface animates; the focus ring does not. Upstream's Button declares
  // `transition: background, border, color` at durationFaster/curveEasyEase and
  // has no transition on focus at all.
  return FluentAnimatedStyle<Color>(
    value: style.backgroundColor?.resolve(states) ?? const Color(0x00000000),
    spec: FluentMotionSpec.buttonSurface,
    lerp: fluentLerpColor,
    builder: (context, background) => FluentFocusRing(
      visible: states.contains(WidgetState.focused),
      borderRadius: radius,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: minimumSize.height,
          minWidth: minimumSize.width,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: radius,
            border: borderWidth > 0 && borderColor != null
                ? Border.all(color: borderColor, width: borderWidth)
                : null,
          ),
          child: Padding(padding: padding, child: content),
        ),
      ),
    ),
  );
}

/// Overrides the button style for a subtree.
///
/// The counterpart of Material's `ElevatedButtonTheme`, and the middle rung of
/// the resolution order: theme defaults, then this, then the widget's own
/// `style`.
class FluentButtonTheme extends InheritedTheme {
  /// Applies [style] to every `FluentButton` in [child].
  const FluentButtonTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the appearance and size defaults.
  final FluentButtonStyle style;

  /// The nearest button style, or null.
  static FluentButtonStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentButtonTheme>()?.style;

  @override
  bool updateShouldNotify(FluentButtonTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentButtonTheme(style: style, child: child);
}

/// A Fluent 2 button.
///
/// ```dart
/// FluentButton(
///   appearance: FluentButtonAppearance.primary,
///   icon: const Icon(FluentIcons.add_20_regular),
///   onPressed: () {},
///   child: const Text('Add'),
/// )
/// ```
///
/// Pass `onPressed: null` to disable it — disabled is a real state here, not a
/// visual treatment: the button stops reporting hover and press, refuses focus,
/// and never invokes the callback.
///
/// Customisation follows the same three rungs Microsoft documents for the React
/// original. [style] is merged last and wins; [FluentButtonTheme] restyles a
/// subtree; and for anything further, [resolveFluentButtonState],
/// [resolveFluentButtonStyle] and [buildFluentButton] are public so any one of
/// them can be replaced without forking this widget.
class FluentButton extends StatelessWidget {
  /// Creates a button with an optional [icon] and a [child] label.
  const FluentButton({
    super.key,
    required this.child,
    this.onPressed,
    this.appearance = FluentButtonAppearance.secondary,
    this.size = FluentButtonSize.medium,
    this.shape = FluentButtonShape.rounded,
    this.iconPosition = FluentButtonIconPosition.before,
    this.icon,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  /// Creates an icon-only button.
  ///
  /// A named constructor rather than a `layout` flag, because the two have
  /// genuinely different requirements: this one needs a [semanticLabel], since
  /// there is no text for a screen reader to announce.
  const FluentButton.icon({
    super.key,
    required Widget this.icon,
    required String this.semanticLabel,
    this.onPressed,
    this.appearance = FluentButtonAppearance.secondary,
    this.size = FluentButtonSize.medium,
    this.shape = FluentButtonShape.rounded,
    this.style,
    this.focusNode,
    this.autofocus = false,
  }) : child = null,
       iconPosition = FluentButtonIconPosition.before;

  /// The label. Null for an icon-only button.
  final Widget? child;

  /// Invoked on tap and on Space or Enter. Null disables the button.
  final VoidCallback? onPressed;

  /// Fill and outline treatment.
  final FluentButtonAppearance appearance;

  /// Height and type ramp.
  final FluentButtonSize size;

  /// Corner treatment.
  final FluentButtonShape shape;

  /// Which side of the label the icon sits on.
  final FluentButtonIconPosition iconPosition;

  /// Optional leading or trailing icon.
  final Widget? icon;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentButtonStyle? style;

  /// Focus node to use. One is created internally when omitted.
  final FocusNode? focusNode;

  /// Whether to take focus on mount.
  final bool autofocus;

  /// Announced by assistive technology.
  ///
  /// Required for `FluentButton.icon`, which has no text to announce; optional
  /// otherwise, where the label already carries the meaning.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final state = resolveFluentButtonState(
      enabled: onPressed != null,
      appearance: appearance,
      size: size,
      shape: shape,
      iconPosition: iconPosition,
      icon: icon,
      label: child,
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentButtonStyle(
      state,
      FluentTheme.of(context),
    ).merge(FluentButtonTheme.maybeOf(context)).merge(style);

    final button = FluentInteractive(
      onPressed: onPressed,
      enabled: onPressed != null,
      focusNode: focusNode,
      autofocus: autofocus,
      builder: (context, states, _) =>
          buildFluentButton(state, resolved, states),
    );

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      child: button,
    );
  }
}
