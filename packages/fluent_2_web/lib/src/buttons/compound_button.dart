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
  Widget? label,
  Widget? secondaryLabel,
}) => FluentCompoundButtonState(
  enabled: enabled,
  appearance: appearance,
  size: size,
  shape: shape,
  iconPosition: iconPosition,
  icon: icon,
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

  // A compound button's foreground table is NOT the button's, which is the one
  // place the two components genuinely part company. The louder first line takes
  // neutralForeground1 at rest even on subtle and transparent, where a plain
  // button's label sits on neutralForeground2; and Selected resolves to the real
  // `Selected` step rather than borrowing Pressed the way the button set does.
  final primaryColor = switch (state.appearance) {
    FluentButtonAppearance.primary => FluentStateColor.tokens(
      rest: c.neutralForegroundOnBrand,
      disabled: c.neutralForegroundDisabled,
    ),
    FluentButtonAppearance.secondary ||
    FluentButtonAppearance.outline ||
    FluentButtonAppearance.subtle => FluentStateColor.tokens(
      rest: c.neutralForeground1,
      hover: c.neutralForeground1Hover,
      pressed: c.neutralForeground1Pressed,
      selected: c.neutralForeground1Selected,
      disabled: c.neutralForegroundDisabled,
    ),
    // Transparent is the odd one, as it is on the button: its label takes BRAND
    // colour on interaction.
    FluentButtonAppearance.transparent => FluentStateColor.tokens(
      rest: c.neutralForeground1,
      hover: c.neutralForeground2BrandHover,
      pressed: c.neutralForeground2BrandPressed,
      selected: c.neutralForeground2BrandSelected,
      disabled: c.neutralForegroundDisabled,
    ),
  };

  // The second line is the first line one step quieter — neutralForeground2*
  // against neutralForeground1* — EXCEPT on primary, where both lines sit on the
  // brand fill and share neutralForegroundOnBrand.
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

  // Compound geometry is genuinely its own: the inset is uniform and equal to
  // the icon gap, the icon is 40 rather than 20, and the height is
  // content-driven because two lines do not fit a button's ramp. The type ramp
  // is NOT its own — both lines hold body1Strong over caption1 at all three
  // sizes, so only the inset moves.
  final (inset, primaryStyle, secondaryStyle) = switch (state.size) {
    FluentButtonSize.small => (
      FluentSpacing.s,
      theme.typography.body1Strong,
      theme.typography.caption1,
    ),
    FluentButtonSize.medium => (
      FluentSpacing.m,
      theme.typography.body1Strong,
      theme.typography.caption1,
    ),
    FluentButtonSize.large => (
      FluentSpacing.l,
      theme.typography.body1Strong,
      theme.typography.caption1,
    ),
  };

  return FluentCompoundButtonStyle(
    button: resolveFluentButtonStyle(state.buttonState, theme).copyWith(
      foregroundColor: primaryColor,
      textStyle: WidgetStatePropertyAll<TextStyle?>(primaryStyle),
      padding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
        EdgeInsets.all(inset),
      ),
      gap: WidgetStatePropertyAll<double?>(inset),
      iconSize: const WidgetStatePropertyAll<double?>(FluentSize.size400),
      // `height: auto` upstream: two lines make the button's own height ramp
      // meaningless, so the content decides. The width is content-driven too,
      // for the reason recorded on `FluentButton`'s `minimumSize`: React's 96
      // floor only works alongside its wider TeachingPopover surface.
      minimumSize: const WidgetStatePropertyAll<Size?>(Size.zero),
    ),
    secondaryColor: secondary,
    secondaryTextStyle: WidgetStatePropertyAll<TextStyle?>(secondaryStyle),
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
        builder: (context, states, _) =>
            buildFluentCompoundButton(state, resolved, states),
      ),
    );
  }
}
