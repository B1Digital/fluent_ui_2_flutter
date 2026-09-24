import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import '../internal/interaction.dart';
import 'button.dart';
import 'button_style.dart';

/// The visual configuration of a `FluentCompoundButton`.
///
/// A compound button *is* a button, so everything a button already has lives on
/// [button] rather than being restated here. Only the second line is new, and it
/// needs exactly two properties of its own: its colour and its type ramp.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the appearance/size defaults derived from the theme
/// 2. the nearest `FluentCompoundButtonTheme`
/// 3. the widget's own `style`
@immutable
class FluentCompoundButtonStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentCompoundButtonStyle({
    this.button,
    this.secondaryColor,
    this.secondaryTextStyle,
  });

  /// Everything the surface and the primary line share with `FluentButton`.
  final FluentButtonStyle? button;

  /// Colour of the second line.
  ///
  /// A separate property rather than a tint of the primary foreground: upstream
  /// selects `neutralForeground2*` for the second line while the first stays on
  /// `neutralForeground1*`, and on the primary appearance the two are the same
  /// token. Neither is derivable from the other.
  final WidgetStateProperty<Color?>? secondaryColor;

  /// Type ramp of the second line. Its colour is overridden by
  /// [secondaryColor].
  final WidgetStateProperty<TextStyle?>? secondaryTextStyle;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// [button] merges per-property too, so overriding only the compound's
  /// secondary colour keeps every resolved button value.
  FluentCompoundButtonStyle merge(FluentCompoundButtonStyle? other) {
    if (other == null) return this;
    return FluentCompoundButtonStyle(
      button: button?.merge(other.button) ?? other.button,
      secondaryColor: other.secondaryColor ?? secondaryColor,
      secondaryTextStyle: other.secondaryTextStyle ?? secondaryTextStyle,
    );
  }

  /// This style with the given properties replaced.
  FluentCompoundButtonStyle copyWith({
    FluentButtonStyle? button,
    WidgetStateProperty<Color?>? secondaryColor,
    WidgetStateProperty<TextStyle?>? secondaryTextStyle,
  }) => FluentCompoundButtonStyle(
    button: button ?? this.button,
    secondaryColor: secondaryColor ?? this.secondaryColor,
    secondaryTextStyle: secondaryTextStyle ?? this.secondaryTextStyle,
  );

  /// Convenience for the common case of one value across every state.
  static FluentCompoundButtonStyle from({
    FluentButtonStyle? button,
    Color? secondaryColor,
    TextStyle? secondaryTextStyle,
  }) => FluentCompoundButtonStyle(
    button: button,
    secondaryColor: secondaryColor == null
        ? null
        : WidgetStatePropertyAll<Color?>(secondaryColor),
    secondaryTextStyle: secondaryTextStyle == null
        ? null
        : WidgetStatePropertyAll<TextStyle?>(secondaryTextStyle),
  );

  @override
  bool operator ==(Object other) =>
      other is FluentCompoundButtonStyle &&
      other.button == button &&
      other.secondaryColor == secondaryColor &&
      other.secondaryTextStyle == secondaryTextStyle;

  @override
  int get hashCode => Object.hash(button, secondaryColor, secondaryTextStyle);
}

/// Everything needed to render a compound button, independent of appearance,
/// size and shape.
///
/// Extends [FluentButtonBaseState] with the second line, so
/// [buildFluentCompoundButton] can be typed against a state that provably
/// carries no design axes.
@immutable
class FluentCompoundButtonBaseState extends FluentButtonBaseState {
  /// Creates a base state.
  const FluentCompoundButtonBaseState({
    required super.enabled,
    required super.iconPosition,
    super.icon,
    super.activeIcon,
    super.label,
    this.secondaryLabel,
  });

  /// The second, quieter line under [FluentButtonBaseState.label].
  ///
  /// Null renders exactly a `FluentButton` with compound geometry, which is what
  /// upstream does when `secondaryContent` is omitted.
  final Widget? secondaryLabel;
}

/// A compound button's fully resolved state, including the design axes.
@immutable
class FluentCompoundButtonState extends FluentCompoundButtonBaseState {
  /// Creates a resolved state.
  const FluentCompoundButtonState({
    required super.enabled,
    required super.iconPosition,
    required this.appearance,
    required this.size,
    required this.shape,
    super.icon,
    super.activeIcon,
    super.label,
    super.secondaryLabel,
  });

  /// Fill and outline treatment. Shared verbatim with `FluentButton`.
  final FluentButtonAppearance appearance;

  /// Height and type ramp. Shared verbatim with `FluentButton`.
  final FluentButtonSize size;

  /// Corner treatment. Shared verbatim with `FluentButton`.
  final FluentButtonShape shape;

  /// The button state this compound button styles its surface from.
  FluentButtonState get buttonState => FluentButtonState(
    enabled: enabled,
    iconPosition: iconPosition,
    appearance: appearance,
    size: size,
    shape: shape,
    icon: icon,
    activeIcon: activeIcon,
    label: label,
  );
}

/// Builds the state a compound button will be styled and rendered from.
FluentCompoundButtonState resolveFluentCompoundButtonState({
  bool enabled = true,
  FluentButtonAppearance appearance = FluentButtonAppearance.secondary,
  FluentButtonSize size = FluentButtonSize.medium,
  FluentButtonShape shape = FluentButtonShape.rounded,
  FluentButtonIconPosition iconPosition = FluentButtonIconPosition.before,
  Widget? icon,
  Widget? activeIcon,
  Widget? label,
  Widget? secondaryLabel,
}) => FluentCompoundButtonState(
  enabled: enabled,
  appearance: appearance,
  size: size,
  shape: shape,
  iconPosition: iconPosition,
  icon: icon,
  // The button's own rule: only subtle and transparent swap their glyph.
  activeIcon:
      appearance == FluentButtonAppearance.subtle ||
          appearance == FluentButtonAppearance.transparent
      ? activeIcon
      : null,
  label: label,
  secondaryLabel: secondaryLabel,
);

/// Resolves the default style for [state] against [theme].
///
/// The surface comes straight from [resolveFluentButtonStyle] — a compound
/// button's fill, border and focus ring are a button's, and duplicating those
/// tables is how two components drift apart. Only the geometry a second line
/// forces, and the second line's own colour, are resolved here.
///
/// Every value comes from a Fluent token; nothing here computes a colour.
FluentCompoundButtonStyle resolveFluentCompoundButtonStyle(
  FluentCompoundButtonState state,
  FluentThemeData theme,
) {
  final c = theme.colors;

  // The first line keeps the button's own foreground table. Figma's set puts
  // it on neutralForeground1 at rest even on subtle and transparent, but the
  // storybook renders those two at neutralForeground2 (#424242) and darkens
  // them on hover exactly as a plain button's label does — measured with
  // getComputedStyle on compoundbutton--appearance — and React wins.
  //
  // The second line sits on neutralForeground2* — one step quieter than the
  // first on secondary and outline — EXCEPT on primary, where both lines sit on
  // the brand fill and share neutralForegroundOnBrand.
  final secondary = switch (state.appearance) {
    FluentButtonAppearance.primary => FluentStateColor.tokens(
      rest: c.neutralForegroundOnBrand,
      disabled: c.neutralForegroundDisabled,
    ),
    FluentButtonAppearance.secondary ||
    FluentButtonAppearance.outline ||
    FluentButtonAppearance.subtle => FluentStateColor.tokens(
      rest: c.neutralForeground2,
      hover: c.neutralForeground2Hover,
      pressed: c.neutralForeground2Pressed,
      selected: c.neutralForeground2Selected,
      disabled: c.neutralForegroundDisabled,
    ),
    FluentButtonAppearance.transparent => FluentStateColor.tokens(
      rest: c.neutralForeground2,
      hover: c.neutralForeground2BrandHover,
      pressed: c.neutralForeground2BrandPressed,
      selected: c.neutralForeground2BrandSelected,
      disabled: c.neutralForegroundDisabled,
    ),
  };

  // Compound geometry is genuinely its own: the icon is 40 rather than 20, and
  // the height is content-driven because two lines do not fit a button's
  // ramp. `useCompoundButtonStyles` pads `8px 8px 10px`, `14px 12px 16px` and
  // `18px 16px 20px` — two more below than above — inside the 1px border every
  // button keeps, which takes layout space here as it does on `FluentButton`,
  // and spaces the icon `spacingHorizontalM` from the text at every size.
  //
  // The type moves with the size too: 14/20 over 12 at small and medium, 16/22
  // over 14 at large, the first line regular at small (the button's own
  // `small` weight, which the compound size rule leaves alone) and semibold
  // otherwise, the second `lineHeight: 100%`. All of it is 60, 72 and 80 high
  // round the 40px icon and 52, 64 and 76 without one, as Chrome renders
  // compoundbutton--size. Figma's set holds 14/20 Semibold over 12/16 at every
  // size with a uniform S/M/L inset doubling as the gap; React wins.
  final t = theme.typography;
  final (
    side,
    top,
    bottom,
    primaryStyle,
    secondaryStyle,
  ) = switch (state.size) {
    FluentButtonSize.small => (
      FluentSpacing.s,
      FluentSpacing.s,
      10.0,
      t.body1,
      t.caption1,
    ),
    FluentButtonSize.medium => (
      FluentSpacing.m,
      14.0,
      FluentSpacing.l,
      t.body1Strong,
      t.caption1,
    ),
    FluentButtonSize.large => (
      FluentSpacing.l,
      18.0,
      FluentSpacing.xl,
      t.subtitle2,
      t.body1,
    ),
  };
  const border = FluentStroke.thin;

  return FluentCompoundButtonStyle(
    button: resolveFluentButtonStyle(state.buttonState, theme).copyWith(
      textStyle: WidgetStatePropertyAll<TextStyle?>(primaryStyle),
      padding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
        EdgeInsets.fromLTRB(
          side + border,
          top + border,
          side + border,
          bottom + border,
        ),
      ),
      gap: const WidgetStatePropertyAll<double?>(FluentSpacing.m),
      iconSize: const WidgetStatePropertyAll<double?>(FluentSize.size400),
      // `height: auto` upstream: two lines make the button's own height ramp
      // meaningless, so the content decides. The width is content-driven too,
      // for the reason recorded on `FluentButton`'s `minimumSize`: React's 96
      // floor only works alongside its wider TeachingPopover surface.
      minimumSize: const WidgetStatePropertyAll<Size?>(Size.zero),
    ),
    secondaryColor: secondary,
    secondaryTextStyle: WidgetStatePropertyAll<TextStyle?>(
      secondaryStyle.copyWith(height: 1),
    ),
  );
}

/// Renders a compound button from a resolved [state] and [style].
///
/// Delegates the surface to [buildFluentButton] with a two-line label rather
/// than reimplementing it, so the focus ring, the surface tween and the icon
/// theme are the button's own, not a copy that will drift.
///
/// [states] is the live interaction set from [FluentInteractive].
Widget buildFluentCompoundButton(
  FluentCompoundButtonBaseState state,
  FluentCompoundButtonStyle style,
  Set<WidgetState> states,
) {
  final secondaryLabel = state.secondaryLabel;
  final primaryLabel = state.label;

  var label = primaryLabel;
  if (secondaryLabel != null) {
    final secondaryStyle =
        style.secondaryTextStyle?.resolve(states) ?? const TextStyle();
    label = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ?primaryLabel,
        DefaultTextStyle.merge(
          style: secondaryStyle.copyWith(
            color: style.secondaryColor?.resolve(states),
          ),
          child: secondaryLabel,
        ),
      ],
    );
  }

  return buildFluentButton(
    FluentButtonBaseState(
      enabled: state.enabled,
      iconPosition: state.iconPosition,
      icon: state.icon,
      activeIcon: state.activeIcon,
      label: label,
    ),
    style.button ?? const FluentButtonStyle(),
    states,
  );
}

/// Overrides the compound button style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`.
class FluentCompoundButtonTheme extends InheritedTheme {
  /// Applies [style] to every `FluentCompoundButton` in [child].
  const FluentCompoundButtonTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the appearance and size defaults.
  final FluentCompoundButtonStyle style;

  /// The nearest compound button style, or null.
  static FluentCompoundButtonStyle? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FluentCompoundButtonTheme>()
      ?.style;

  @override
  bool updateShouldNotify(FluentCompoundButtonTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentCompoundButtonTheme(style: style, child: child);
}

/// A Fluent 2 compound button: a button with a second, explanatory line.
///
/// ```dart
/// FluentCompoundButton(
///   secondaryContent: const Text('This is a description'),
///   onPressed: () {},
///   child: const Text('Button'),
/// )
/// ```
///
/// The appearance, size and shape axes are `FluentButton`'s own — the same
/// enums, the same five fills. What a compound button adds is the second line,
/// the geometry two lines force — a uniform inset of 8, 12 or 16 that doubles as
/// the icon gap, a 40px icon, and a content-driven height instead of the
/// button's 24/32/40 ramp — and a foreground table one step louder than the
/// button's.
///
/// Pass `onPressed: null` to disable it — disabled is a real state, not a
/// visual treatment: the button stops reporting hover and press, refuses focus,
/// and never invokes the callback.
///
/// Customisation follows the same three rungs as `FluentButton`. [style] is
/// merged last and wins; [FluentCompoundButtonTheme] restyles a subtree; and
/// [resolveFluentCompoundButtonState], [resolveFluentCompoundButtonStyle] and
/// [buildFluentCompoundButton] are public so any one of them can be replaced
/// without forking this widget.
class FluentCompoundButton extends StatelessWidget {
  /// Creates a compound button with a [child] label and a [secondaryContent]
  /// second line.
  const FluentCompoundButton({
    super.key,
    required this.child,
    this.secondaryContent,
    this.onPressed,
    this.appearance = FluentButtonAppearance.secondary,
    this.size = FluentButtonSize.medium,
    this.shape = FluentButtonShape.rounded,
    this.iconPosition = FluentButtonIconPosition.before,
    this.icon,
    this.activeIcon,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  /// The first, louder line.
  final Widget child;

  /// The second, quieter line. Null renders a plain button with compound
  /// geometry.
  final Widget? secondaryContent;

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

  /// Optional leading or trailing icon, rendered at 40 logical pixels.
  final Widget? icon;

  /// Shown in place of [icon] while a subtle or transparent compound button is
  /// hovered or pressed — upstream's `bundleIcon` Filled glyph. See
  /// `FluentButton.activeIcon`.
  final Widget? activeIcon;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentCompoundButtonStyle? style;

  /// Focus node to use. One is created internally when omitted.
  final FocusNode? focusNode;

  /// Whether to take focus on mount.
  final bool autofocus;

  /// Announced by assistive technology.
  ///
  /// Optional: both lines are read by default, which is usually what the
  /// second line is for. Set it when the pair reads badly out of context.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final state = resolveFluentCompoundButtonState(
      enabled: onPressed != null,
      appearance: appearance,
      size: size,
      shape: shape,
      iconPosition: iconPosition,
      icon: icon,
      activeIcon: activeIcon,
      label: child,
      secondaryLabel: secondaryContent,
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentCompoundButtonStyle(
      state,
      FluentTheme.of(context),
    ).merge(FluentCompoundButtonTheme.maybeOf(context)).merge(style);

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      child: FluentInteractive(
        onPressed: onPressed,
        enabled: onPressed != null,
        focusNode: focusNode,
        autofocus: autofocus,
        // `:hover:active`, as `useCompoundButtonStyles.styles.ts` writes it.
        pressedRequiresHover: true,
        builder: (context, states, _) =>
            buildFluentCompoundButton(state, resolved, states),
      ),
    );
  }
}
