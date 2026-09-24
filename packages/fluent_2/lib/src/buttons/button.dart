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
    this.activeIcon,
    this.label,
    this.menuIcon,
  });

  /// Whether the button responds to input.
  final bool enabled;

  /// Which side the icon sits on.
  final FluentButtonIconPosition iconPosition;

  /// The icon, if any.
  final Widget? icon;

  /// Shown in place of [icon] while the button is hovered or pressed, or null
  /// to keep [icon] throughout.
  ///
  /// Upstream's `bundleIcon(Filled, Regular)`: a subtle or transparent button
  /// displays the Filled glyph under `:hover` and `:hover:active`
  /// (`useButtonStyles.styles.ts`, `iconFilledClassName`), so pass the filled
  /// counterpart of [icon] here. [resolveFluentButtonState] keeps it on those
  /// two appearances only, as upstream does.
  final Widget? activeIcon;

  /// The label, if any. A button with no label is an icon-only button.
  final Widget? label;

  /// A menu affordance after the label — upstream `MenuButton`'s `menuIcon`
  /// slot, which `fluentMenuChevron` fills. Unlike [icon] it keeps the label's
  /// colour and never swaps glyphs, since upstream styles it as neither
  /// `.fui-Button__icon` nor a bundled icon.
  final Widget? menuIcon;

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
    super.activeIcon,
    super.label,
    super.menuIcon,
  });

  /// Fill and outline treatment.
  final FluentButtonAppearance appearance;

  /// Height and type ramp.
  final FluentButtonSize size;

  /// Corner treatment.
  final FluentButtonShape shape;
}

/// Whether [appearance] swaps its icon for the active one on hover and press.
///
/// Only subtle and transparent do upstream: `useButtonStyles.styles.ts` hides
/// `iconRegularClassName` and shows `iconFilledClassName` under their `:hover`
/// and `:hover:active` rules and nowhere else.
bool _swapsIcon(FluentButtonAppearance appearance) =>
    appearance == FluentButtonAppearance.subtle ||
    appearance == FluentButtonAppearance.transparent;

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
  Widget? activeIcon,
  Widget? label,
  Widget? menuIcon,
}) => FluentButtonState(
  enabled: enabled,
  appearance: appearance,
  size: size,
  shape: shape,
  iconPosition: iconPosition,
  icon: icon,
  activeIcon: _swapsIcon(appearance) ? activeIcon : null,
  label: label,
  menuIcon: menuIcon,
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes. Every value comes from a Fluent token; nothing
/// here computes a colour.
///
/// Colour tokens come from the Figma `Button` component set, extracted into
/// `test/fixtures/button.json` and asserted variant-by-variant in the tests.
/// Geometry and focus follow `useButtonStyles.styles.ts` as Chrome renders it.
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
      // `Selected` is upstream's open-menu (`aria-expanded`) and checked-toggle
      // colour, in its own token rather than the pressed one.
      selected: c.neutralForeground1Selected,
      disabled: c.neutralForegroundDisabled,
    ),
    FluentButtonAppearance.subtle => FluentStateColor.tokens(
      rest: c.neutralForeground2,
      hover: c.neutralForeground1Hover,
      pressed: c.neutralForeground1Pressed,
      selected: c.neutralForeground2Selected,
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

  // Subtle is the one appearance whose icon parts company with its label:
  // `useButtonStyles.subtle` recolours `.fui-Button__icon` brand under `:hover`
  // and `:hover:active` while the label stays neutral, and an open subtle
  // MenuButton (`useIconExpandedStyles.subtle`) or a checked subtle
  // ToggleButton (`useIconCheckedStyles`) holds it at BrandSelected. Anywhere
  // else the icon inherits the label colour, so it resolves to null there and
  // follows [FluentButtonStyle.foregroundColor] — an override included.
  final icon = state.appearance == FluentButtonAppearance.subtle
      ? WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.disabled)) return null;
          if (states.contains(WidgetState.pressed)) {
            return c.neutralForeground2BrandPressed;
          }
          if (states.contains(WidgetState.hovered)) {
            return c.neutralForeground2BrandHover;
          }
          if (states.contains(WidgetState.selected)) {
            return c.neutralForeground2BrandSelected;
          }
          return null;
        })
      : null;

  final primary = state.appearance == FluentButtonAppearance.primary;
  final bordered =
      state.appearance == FluentButtonAppearance.secondary ||
      state.appearance == FluentButtonAppearance.outline;

  final strokes = FluentStateColor.tokens(
    rest: c.neutralStroke1,
    hover: c.neutralStroke1Hover,
    pressed: c.neutralStroke1Pressed,
    selected: c.neutralStroke1Selected,
    disabled: c.neutralStrokeDisabled,
  );
  // The focus indicator turns the border `strokeFocus2`, and keeps it so under
  // `:hover` — measured in Chrome. It is the ring's outer pixel, which matters
  // wherever the border is painted over the ring, as on a split button's half.
  final border = bordered
      ? WidgetStateProperty.resolveWith<Color?>(
          (states) => states.contains(WidgetState.focused)
              ? c.strokeFocus2
              : strokes.resolve(states),
        )
      : null;

  // Geometry, as `useButtonStyles.styles.ts` lays it out. Every appearance
  // there keeps a 1px border — transparent where it is not seen — and a CSS
  // border takes layout space, so each inset below is upstream's padding plus
  // that pixel: `3px 8px` at small (`1px` vertical beside an icon), `5px 12px`
  // at medium, `8px 16px` at large (`7px`). Figma strokes sit inside the frame
  // without moving the content, so its fixture reads one less across.
  //
  // A labelled button is floored at `minWidth` 64 (small) or 96. An icon-only
  // one takes `useRootIconOnlyStyles` instead: padding 1, 5 or 7 and a square
  // 24, 32 or 40 — the height, which the padding and glyph add up to exactly.
  final withIcon = state.icon != null;
  final (
    inset,
    iconOnlyInset,
    gap,
    height,
    iconSize,
    textStyle,
    floor,
  ) = switch (state.size) {
    FluentButtonSize.small => (
      EdgeInsets.symmetric(horizontal: 9, vertical: withIcon ? 2 : 4),
      2.0,
      FluentSpacing.xs,
      24.0,
      FluentSize.size200,
      theme.typography.caption1,
      64.0,
    ),
    FluentButtonSize.medium => (
      const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      6.0,
      FluentSpacing.sNudge,
      32.0,
      FluentSize.size200,
      theme.typography.body1Strong,
      96.0,
    ),
    FluentButtonSize.large => (
      EdgeInsets.symmetric(horizontal: 17, vertical: withIcon ? 8 : 9),
      8.0,
      FluentSpacing.sNudge,
      40.0,
      FluentSize.size240,
      theme.typography.subtitle2,
      96.0,
    ),
  };
  final padding = state.iconOnly ? EdgeInsets.all(iconOnlyInset) : inset;
  final minimumWidth = state.iconOnly ? height : floor;
  // `useMenuIconStyles`: 12, 12 and 16, whatever the icon beside it.
  final menuIconSize = state.size == FluentButtonSize.large
      ? FluentSize.size160
      : FluentSize.size120;

  // Selected outline thickens to `strokeWidthThicker`, as both an open
  // MenuButton and a checked ToggleButton do upstream.
  bool thickened(Set<WidgetState> states) =>
      state.appearance == FluentButtonAppearance.outline &&
      states.contains(WidgetState.selected);

  // A keyboard-focused button takes the size's own radius — `useRootFocusStyles`
  // gives small `borderRadiusSmall` and large `borderRadiusLarge` — unless its
  // shape already fixes one, which is why only `rounded` varies.
  final focusRadius = switch (state.size) {
    FluentButtonSize.small => FluentRadius.allSmall,
    FluentButtonSize.medium => FluentRadius.allMedium,
    FluentButtonSize.large => FluentRadius.allLarge,
  };
  final radius = switch (state.shape) {
    FluentButtonShape.rounded => WidgetStateProperty.resolveWith<BorderRadius?>(
      (states) => states.contains(WidgetState.focused)
          ? focusRadius
          : FluentRadius.allMedium,
    ),
    FluentButtonShape.circular => const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allCircular,
    ),
    FluentButtonShape.square => const WidgetStatePropertyAll<BorderRadius?>(
      BorderRadius.zero,
    ),
  };

  return FluentButtonStyle(
    backgroundColor: background,
    foregroundColor: foreground,
    iconColor: icon,
    borderColor: border,
    borderWidth: WidgetStateProperty.resolveWith<double?>(
      (states) => !bordered
          ? FluentStroke.none
          : thickened(states)
          ? FluentStroke.thicker
          : FluentStroke.thin,
    ),
    borderRadius: radius,
    textStyle: WidgetStatePropertyAll<TextStyle?>(textStyle),
    // The thicker border takes layout space as the 1px one does, so the
    // content keeps its inset and the button grows: a checked outline toggle
    // is 36 high where its unchecked self is 32, as Chrome renders
    // togglebutton--appearance.
    padding: WidgetStateProperty.resolveWith<EdgeInsetsGeometry?>(
      (states) => thickened(states)
          ? padding +
                const EdgeInsets.all(FluentStroke.thicker - FluentStroke.thin)
          : padding,
    ),
    gap: WidgetStatePropertyAll<double?>(gap),
    iconSize: WidgetStatePropertyAll<double?>(iconSize),
    menuIconSize: WidgetStatePropertyAll<double?>(menuIconSize),
    minimumSize: WidgetStatePropertyAll<Size?>(Size(minimumWidth, height)),
    // Primary's focus indicator (`useRootFocusStyles.primary`) adds `shadow2`
    // outside and a white 2px inset shadow under the 1px black one — seen as a
    // 1px white ring inside the black — and drops the white while hovered.
    focusRingInnerColor: primary
        ? WidgetStateProperty.resolveWith<Color?>(
            (states) =>
                states.contains(WidgetState.focused) &&
                    !states.contains(WidgetState.hovered)
                ? c.neutralForegroundOnBrand
                : null,
          )
        : null,
    shadow: primary
        ? WidgetStateProperty.resolveWith<List<BoxShadow>?>(
            (states) => states.contains(WidgetState.focused)
                ? FluentElevation.shadow2.shadows(
                    ambient: c.neutralShadowAmbient,
                    key: c.neutralShadowKey,
                  )
                : null,
          )
        : null,
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
  const clear = Color(0x00000000);
  final radius = style.borderRadius?.resolve(states) ?? FluentRadius.allMedium;
  final borderWidth = style.borderWidth?.resolve(states) ?? FluentStroke.none;
  final borderColor = style.borderColor?.resolve(states);
  final padding = style.padding?.resolve(states) ?? EdgeInsets.zero;
  final gap = style.gap?.resolve(states) ?? FluentSpacing.sNudge;
  final iconSize = style.iconSize?.resolve(states) ?? FluentSize.size200;
  final menuIconSize =
      style.menuIconSize?.resolve(states) ?? FluentSize.size120;
  final minimumSize = style.minimumSize?.resolve(states) ?? Size.zero;
  final textStyle = style.textStyle?.resolve(states);
  // Not animated: upstream sets it on the icon span, which declares no
  // transition of its own, so it lands on the frame the state changes.
  final iconColor = style.iconColor?.resolve(states);
  final icon =
      states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.pressed)
      ? state.activeIcon ?? state.icon
      : state.icon;

  Widget buildContent(Color? foreground) {
    final children = <Widget>[
      if (icon != null)
        IconTheme.merge(
          data: IconThemeData(color: iconColor ?? foreground, size: iconSize),
          child: icon,
        ),
      if (state.label != null) state.label!,
    ];

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: icon != null && state.label != null ? gap : 0,
      children: switch (state.iconPosition) {
        FluentButtonIconPosition.before => children,
        FluentButtonIconPosition.after => children.reversed.toList(),
      },
    );

    final menuIcon = state.menuIcon;
    if (menuIcon != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          content,
          // `useMenuIconStyles.notIconOnly`: `marginLeft:
          // spacingHorizontalXS`, beside a label only.
          if (state.label != null) const SizedBox(width: FluentSpacing.xs),
          IconTheme.merge(
            // The label's colour: upstream's `menuIcon` span is not a
            // `.fui-Button__icon`, so subtle's brand icon rule passes it by.
            data: IconThemeData(color: foreground, size: menuIconSize),
            // The span keeps a 16 (22) line height, and the inline svg in it
            // sits on that line's baseline — 1px below the span at every size,
            // as Chrome renders it. Painted, not laid out, lower, exactly as
            // the overflowing svg is.
            child: Transform.translate(
              offset: const Offset(0, 1),
              child: menuIcon,
            ),
          ),
        ],
      );
    }

    if (textStyle != null || foreground != null) {
      content = DefaultTextStyle.merge(
        style: (textStyle ?? const TextStyle()).copyWith(color: foreground),
        child: content,
      );
    }
    return content;
  }

  // The surface, its border and its label animate together; the focus ring
  // does not. Upstream's Button declares `transition: background, border,
  // color` at durationFaster/curveEasyEase, and its focus indicator is a
  // box-shadow, which that list leaves out.
  return FluentAnimatedStyle<_ButtonInk>(
    value: (
      style.backgroundColor?.resolve(states) ?? clear,
      borderColor ?? clear,
      style.foregroundColor?.resolve(states),
    ),
    spec: switch (style.animationDuration) {
      null => FluentMotionSpec.buttonSurface,
      final duration => FluentMotionSpec(
        duration: duration,
        curve: FluentMotionSpec.buttonSurface.curve,
      ),
    },
    lerp: _lerpButtonInk,
    builder: (context, ink) => FluentFocusRing.inset(
      visible: states.contains(WidgetState.focused),
      borderRadius: radius,
      insets:
          style.focusRingInsets?.resolve(states) ??
          const EdgeInsets.all(FluentStroke.thick),
      innerColor: style.focusRingInnerColor?.resolve(states),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: minimumSize.height,
          minWidth: minimumSize.width,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ink.$1,
            borderRadius: radius,
            border: borderWidth > 0 && borderColor != null
                ? Border.all(color: ink.$2, width: borderWidth)
                : null,
            boxShadow: style.shadow?.resolve(states),
          ),
          child: Padding(padding: padding, child: buildContent(ink.$3)),
        ),
      ),
    ),
  );
}

/// The three colours upstream's `transition: background, border, color`
/// moves together, as one value on one ticker. The foreground is nullable: a
/// style without one leaves the label's own colour alone.
typedef _ButtonInk = (Color background, Color border, Color? foreground);

_ButtonInk? _lerpButtonInk(_ButtonInk? a, _ButtonInk? b, double t) {
  if (a == null || b == null) return b ?? a;
  return (
    // fluentLerpColor, not Color.lerp: a subtle surface is transparent black at
    // rest, and Color.lerp would drag its RGB through the fade.
    fluentLerpColor(a.$1, b.$1, t)!,
    fluentLerpColor(a.$2, b.$2, t)!,
    fluentLerpColor(a.$3, b.$3, t),
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
    this.activeIcon,
    this.menuIcon,
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
    this.activeIcon,
    this.onPressed,
    this.appearance = FluentButtonAppearance.secondary,
    this.size = FluentButtonSize.medium,
    this.shape = FluentButtonShape.rounded,
    this.style,
    this.focusNode,
    this.autofocus = false,
  }) : child = null,
       menuIcon = null,
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

  /// Shown in place of [icon] while a subtle or transparent button is hovered
  /// or pressed — upstream's `bundleIcon`, which swaps the Regular glyph for
  /// its Filled one there. Pass the filled counterpart of [icon]:
  ///
  /// ```dart
  /// FluentButton(
  ///   appearance: FluentButtonAppearance.subtle,
  ///   icon: const Icon(FluentIcons.calendar_month_20_regular),
  ///   activeIcon: const Icon(FluentIcons.calendar_month_20_filled),
  ///   onPressed: () {},
  ///   child: const Text('Schedule'),
  /// )
  /// ```
  ///
  /// Ignored on the other appearances, which never swap upstream.
  final Widget? activeIcon;

  /// A menu affordance after the label, which makes this upstream's
  /// `MenuButton`:
  ///
  /// ```dart
  /// FluentButton(
  ///   menuIcon: fluentMenuChevron,
  ///   onPressed: () {},
  ///   child: const Text('Menu'),
  /// )
  /// ```
  ///
  /// Drawn 12 (16 at large) and 4 after the label, in the label's colour.
  final Widget? menuIcon;

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
    // A declared `semanticLabel` *names* the button, it does not prefix it:
    // the Semantics below would otherwise concatenate with the label's own
    // text and the node would read "Install\nInstall". Same rule and same fix
    // as a breadcrumb crumb's label. `FluentButton.icon` has no label to
    // exclude, which is why only that constructor already came out right.
    final label = child;
    final state = resolveFluentButtonState(
      enabled: onPressed != null,
      appearance: appearance,
      size: size,
      shape: shape,
      iconPosition: iconPosition,
      icon: icon,
      activeIcon: activeIcon,
      label: label != null && semanticLabel != null
          ? ExcludeSemantics(child: label)
          : label,
      menuIcon: menuIcon,
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
