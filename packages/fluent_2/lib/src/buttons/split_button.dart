import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import '../internal/animated_style.dart';
import '../internal/interaction.dart';
import 'button.dart';
import 'button_style.dart';

/// The chevron every Fluent menu affordance uses.
///
/// A **menu button** is not a component of its own — Figma documents it as a
/// `Button` carrying this chevron, and so does upstream's `MenuButton`, which
/// renders `<Button menuIcon={<ChevronDownRegular />}>`. Write one as:
///
/// ```dart
/// FluentButton(
///   icon: fluentMenuChevron,
///   iconPosition: FluentButtonIconPosition.after,
///   onPressed: () {},
///   child: const Text('Menu'),
/// )
/// ```
///
/// Deliberately sizeless, so it inherits the icon size the button's own size
/// ramp resolved rather than pinning one of its own.
const Widget fluentMenuChevron = Icon(FluentIcons.chevron_down_20_regular);

/// The chevron half's width, at every size.
///
/// Figma pins it: `.Secondary action` (component set `9026:1241`) has no size
/// axis at all and measures 24 wide in all 25 variants, and every `Split button`
/// variant embeds it unresized — 24 next to a 40-high Large half just as much as
/// next to a 24-high Small one.
///
/// It is also, not by accident, WCAG 2.2's minimum target size for a pointer
/// target immediately adjacent to another one; upstream names the same 24 as
/// `MIN_TARGET_SIZE` in `useSplitButtonStyles.styles.ts`, citing that guideline.
const double _menuWidth = FluentSize.size240;

/// The chevron's own size.
///
/// 12, not the button ramp's 20: Figma draws the chevron half as 6px of padding,
/// a 12px glyph and 6px more, which is exactly [_menuWidth].
const double _menuIconSize = FluentSize.size120;

/// Which half of a split button is being rendered.
///
/// The two halves are separate hit targets with separate interaction states —
/// hovering the chevron must not light up the primary action — so every part of
/// the rendering path is told which one it is drawing.
enum FluentSplitButtonSide {
  /// The wide half carrying the label. Rounded on the leading edge, and the
  /// owner of the divider drawn on its trailing edge.
  primaryAction,

  /// The narrow chevron half. Rounded on the trailing edge, and never drawing a
  /// leading border — the divider already occupies that pixel.
  menu,
}

/// The visual configuration of a `FluentSplitButton`.
///
/// A split button's two halves *are* buttons, so everything they need lives on
/// [button] rather than being restated here. Only the divider is new.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the appearance/size defaults derived from the theme
/// 2. the nearest `FluentSplitButtonTheme`
/// 3. the widget's own `style`
@immutable
class FluentSplitButtonStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentSplitButtonStyle({this.button, this.dividerColor});

  /// Everything both halves share with `FluentButton`.
  ///
  /// [FluentButtonStyle.borderRadius] is the whole component's radius; each
  /// half squares off the two corners it does not own.
  final FluentButtonStyle? button;

  /// Colour of the 1px rule between the two halves, or null where Figma paints
  /// no rule at all — the subtle and transparent appearances, and primary while
  /// disabled.
  ///
  /// Not derivable from [FluentButtonStyle.borderColor]: on the primary
  /// appearance the surrounding button has no border at all, yet the rule is
  /// there, in `neutralStrokeOnBrand2` and its hover, pressed and selected
  /// steps.
  final WidgetStateProperty<Color?>? dividerColor;

  /// This style with the non-null properties of [other] layered on top.
  FluentSplitButtonStyle merge(FluentSplitButtonStyle? other) {
    if (other == null) return this;
    return FluentSplitButtonStyle(
      button: button?.merge(other.button) ?? other.button,
      dividerColor: other.dividerColor ?? dividerColor,
    );
  }

  /// This style with the given properties replaced.
  FluentSplitButtonStyle copyWith({
    FluentButtonStyle? button,
    WidgetStateProperty<Color?>? dividerColor,
  }) => FluentSplitButtonStyle(
    button: button ?? this.button,
    dividerColor: dividerColor ?? this.dividerColor,
  );

  /// Convenience for the common case of one value across every state.
  static FluentSplitButtonStyle from({
    FluentButtonStyle? button,
    Color? dividerColor,
  }) => FluentSplitButtonStyle(
    button: button,
    dividerColor: dividerColor == null
        ? null
        : WidgetStatePropertyAll<Color?>(dividerColor),
  );

  @override
  bool operator ==(Object other) =>
      other is FluentSplitButtonStyle &&
      other.button == button &&
      other.dividerColor == dividerColor;

  @override
  int get hashCode => Object.hash(button, dividerColor);
}

/// Everything needed to render a split button, independent of appearance, size
/// and shape.
///
/// [FluentButtonBaseState.enabled] describes the **primary action** half only;
/// the chevron has its own [menuEnabled]. Two halves, two callbacks, two
/// disabled states — a split button whose menu is available while its default
/// action is not is a real and common arrangement.
@immutable
class FluentSplitButtonBaseState extends FluentButtonBaseState {
  /// Creates a base state.
  const FluentSplitButtonBaseState({
    required super.enabled,
    required super.iconPosition,
    required this.menuEnabled,
    super.icon,
    super.label,
    this.menuIcon,
  });

  /// Whether the chevron half responds to input.
  final bool menuEnabled;

  /// The chevron. Defaults to [fluentMenuChevron] when null.
  final Widget? menuIcon;

  /// The base state of one [side], as `FluentButton` would see it.
  FluentButtonBaseState half(FluentSplitButtonSide side) => switch (side) {
    FluentSplitButtonSide.primaryAction => FluentButtonBaseState(
      enabled: enabled,
      iconPosition: iconPosition,
      icon: icon,
      label: label,
    ),
    FluentSplitButtonSide.menu => FluentButtonBaseState(
      enabled: menuEnabled,
      iconPosition: iconPosition,
      icon: menuIcon ?? fluentMenuChevron,
    ),
  };
}

/// A split button's fully resolved state, including the design axes.
@immutable
class FluentSplitButtonState extends FluentSplitButtonBaseState {
  /// Creates a resolved state.
  const FluentSplitButtonState({
    required super.enabled,
    required super.iconPosition,
    required super.menuEnabled,
    required this.appearance,
    required this.size,
    required this.shape,
    super.icon,
    super.label,
    super.menuIcon,
  });

  /// Fill and outline treatment. Shared verbatim with `FluentButton`.
  final FluentButtonAppearance appearance;

  /// Height and type ramp. Shared verbatim with `FluentButton`.
  final FluentButtonSize size;

  /// Corner treatment. Shared verbatim with `FluentButton`.
  final FluentButtonShape shape;

  /// The button state one [side] styles its surface from.
  FluentButtonState buttonState(FluentSplitButtonSide side) {
    final base = half(side);
    return FluentButtonState(
      enabled: base.enabled,
      iconPosition: base.iconPosition,
      appearance: appearance,
      size: size,
      shape: shape,
      icon: base.icon,
      label: base.label,
    );
  }
}

/// Builds the state a split button will be styled and rendered from.
FluentSplitButtonState resolveFluentSplitButtonState({
  bool enabled = true,
  bool menuEnabled = true,
  FluentButtonAppearance appearance = FluentButtonAppearance.secondary,
  FluentButtonSize size = FluentButtonSize.medium,
  FluentButtonShape shape = FluentButtonShape.rounded,
  FluentButtonIconPosition iconPosition = FluentButtonIconPosition.before,
  Widget? icon,
  Widget? label,
  Widget? menuIcon,
}) => FluentSplitButtonState(
  enabled: enabled,
  menuEnabled: menuEnabled,
  appearance: appearance,
  size: size,
  shape: shape,
  iconPosition: iconPosition,
  icon: icon,
  label: label,
  menuIcon: menuIcon,
);

/// Resolves the default style of one [side] for [state] against [theme].
///
/// The surface comes straight from [resolveFluentButtonStyle] — a split
/// button's halves are buttons, and duplicating the appearance and size tables
/// is how two components drift apart. Only what a divided container forces is
/// resolved here: the chevron half's WCAG minimum width, and the divider.
///
/// Every value comes from a Fluent token; nothing here computes a colour.
FluentSplitButtonStyle resolveFluentSplitButtonStyle(
  FluentSplitButtonState state,
  FluentThemeData theme, {
  required FluentSplitButtonSide side,
}) {
  final c = theme.colors;
  var button = resolveFluentButtonStyle(state.buttonState(side), theme);

  if (side == FluentSplitButtonSide.menu) {
    final minimum =
        button.minimumSize?.resolve(const <WidgetState>{}) ?? Size.zero;
    button = button.copyWith(
      // The chevron half does NOT take the button's size ramp. It is its own
      // Figma component and carries its own numbers: 6px of horizontal padding,
      // none vertical, no gap, a 12px chevron, 24 wide. Only the height is the
      // ramp's, which is what keeps the two halves the same height.
      padding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
        EdgeInsets.symmetric(horizontal: FluentSpacing.sNudge),
      ),
      gap: const WidgetStatePropertyAll<double?>(FluentSpacing.none),
      iconSize: const WidgetStatePropertyAll<double?>(_menuIconSize),
      minimumSize: WidgetStatePropertyAll<Size?>(
        Size(math.max(_menuWidth, minimum.width), minimum.height),
      ),
    );
  }

  // The divider is the primary half's `borderRightColor` — Figma gives the
  // chevron half `strokeLeftWeight: 0` in every bordered variant so the rule is
  // drawn exactly once.
  //
  // It exists only where Figma paints a stroke. Upstream sets a transparent
  // `borderRightColor` on Subtle and Transparent too; the Figma file paints no
  // stroke there at all, on either half, in any state — so neither do we.
  final onBrand = FluentStateColor.tokens(
    rest: c.neutralStrokeOnBrand2,
    hover: c.neutralStrokeOnBrand2Hover,
    pressed: c.neutralStrokeOnBrand2Pressed,
    selected: c.neutralStrokeOnBrand2Selected,
  );
  final divider = switch (state.appearance) {
    // Primary loses the rule entirely when disabled: both halves fall to
    // neutralBackgroundDisabled and Figma paints nothing between them. Selecting
    // a stroke token for that state would invent a line the spec has not got.
    FluentButtonAppearance.primary => WidgetStateProperty.resolveWith<Color?>(
      (states) => states.contains(WidgetState.disabled)
          ? null
          : onBrand.resolve(states),
    ),
    FluentButtonAppearance.secondary ||
    FluentButtonAppearance.outline => FluentStateColor.tokens(
      rest: c.neutralStroke1,
      hover: c.neutralStroke1Hover,
      pressed: c.neutralStroke1Pressed,
      selected: c.neutralStroke1Selected,
      disabled: c.neutralStrokeDisabled,
    ),
    FluentButtonAppearance.subtle || FluentButtonAppearance.transparent => null,
  };

  return FluentSplitButtonStyle(button: button, dividerColor: divider);
}

/// Renders **one half** of a split button from a resolved [state] and [style].
///
/// One half rather than the pair, because the halves are siblings with
/// independent interaction states: nesting one interaction surface inside the
/// other would make hovering the chevron light up the primary action too.
/// `FluentSplitButton` calls this twice, once per [side], and lays the results
/// out in a row.
///
/// Takes [FluentSplitButtonBaseState] rather than [FluentSplitButtonState] on
/// purpose: it never reads appearance, size or shape, so a consumer can supply
/// their own style and still use Fluent's rendering.
///
/// [states] is the live interaction set of **this half** from
/// [FluentInteractive].
Widget buildFluentSplitButton(
  FluentSplitButtonBaseState state,
  FluentSplitButtonStyle style,
  Set<WidgetState> states, {
  required FluentSplitButtonSide side,
}) => Builder(
  // The reading direction is read here rather than taken as an argument: the
  // pair mirrors under RTL and every caller would otherwise have to know that.
  builder: (BuildContext context) {
    final roundsLeft = _roundsLeft(side, Directionality.of(context));
    final button = style.button ?? const FluentButtonStyle();
    final radius =
        button.borderRadius?.resolve(states) ?? FluentRadius.allMedium;
    final borderWidth =
        button.borderWidth?.resolve(states) ?? FluentStroke.none;
    final borderColor = button.borderColor?.resolve(states);
    final dividerColor = style.dividerColor?.resolve(states);

    // Each half keeps only the two corners on its own outer edge. The inner
    // edge is square, which is what makes the pair read as one container.
    final halfRadius = roundsLeft
        ? BorderRadius.only(
            topLeft: radius.topLeft,
            bottomLeft: radius.bottomLeft,
          )
        : BorderRadius.only(
            topRight: radius.topRight,
            bottomRight: radius.bottomRight,
          );

    // The border is painted by FluentSplitButtonEdgePainter, not by the half's
    // own decoration: three sides plus two rounded corners is not a shape
    // BoxDecoration can express — Flutter requires a uniform border before it
    // will accept a border radius.
    final half = buildFluentButton(
      state.half(side),
      button.copyWith(
        borderRadius: WidgetStatePropertyAll<BorderRadius?>(halfRadius),
        borderWidth: const WidgetStatePropertyAll<double?>(FluentStroke.none),
      ),
      states,
    );

    // No rule means nothing for the painter to draw: every appearance Figma
    // leaves undivided — subtle, transparent, and primary while disabled — is
    // also unbordered, so the half's own decoration is the whole picture.
    if (dividerColor == null) return half;

    return FluentAnimatedStyle<FluentSplitButtonEdgeColors>(
      // Upstream transitions `border` alongside `background` and `color` on the
      // button root, at the same duration and curve — the divider is part of
      // that border, so it tweens with the surface rather than snapping.
      value: FluentSplitButtonEdgeColors(
        // borderWidth is zero on exactly the appearances whose borderColor is
        // null, so this stand-in is never painted. Keeping the pair non-null
        // keeps the tween a single value rather than two nested animations.
        border: borderColor ?? dividerColor,
        divider: dividerColor,
      ),
      spec: FluentMotionSpec.buttonSurface,
      lerp: FluentSplitButtonEdgeColors.lerp,
      builder: (_, colors) => CustomPaint(
        foregroundPainter: FluentSplitButtonEdgePainter(
          side: side,
          borderColor: colors.border,
          borderWidth: borderWidth,
          dividerColor: colors.divider,
          radius: halfRadius,
          roundsLeft: roundsLeft,
        ),
        child: half,
      ),
    );
  },
);

/// Whether [side] rounds its **left** corners under [textDirection].
///
/// One bit the whole divided container falls out of: the rounded corners are
/// the primary half's leading edge and the menu half's trailing edge, the
/// divider sits on whichever edge is left over, and under RTL the row lays the
/// two halves out reversed so both swap physical sides.
bool _roundsLeft(FluentSplitButtonSide side, TextDirection textDirection) =>
    (side == FluentSplitButtonSide.primaryAction) ==
    (textDirection == TextDirection.ltr);

/// The two colours [FluentSplitButtonEdgePainter] tweens together.
///
/// A pair rather than two nested [FluentAnimatedStyle]s: they are driven by one
/// interaction state and one upstream transition, so they are one value.
@immutable
class FluentSplitButtonEdgeColors {
  /// Creates a colour pair.
  const FluentSplitButtonEdgeColors({
    required this.border,
    required this.divider,
  });

  /// The outer border of this half.
  final Color border;

  /// The rule between the two halves.
  final Color divider;

  /// Interpolates both colours with [fluentLerpColor], which is what a
  /// transparent Fluent token needs — see `doc/token-divergences.md`.
  static FluentSplitButtonEdgeColors? lerp(
    FluentSplitButtonEdgeColors? a,
    FluentSplitButtonEdgeColors? b,
    double t,
  ) {
    if (a == null || b == null) return b ?? a;
    return FluentSplitButtonEdgeColors(
      border: fluentLerpColor(a.border, b.border, t)!,
      divider: fluentLerpColor(a.divider, b.divider, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FluentSplitButtonEdgeColors &&
      other.border == border &&
      other.divider == divider;

  @override
  int get hashCode => Object.hash(border, divider);
}

/// Paints one half's border and, on the primary action half, the divider.
///
/// A painter rather than a [BoxDecoration] because the shape is an *open*
/// rounded path: three sides and two corners. [Border] refuses a border radius
/// unless all four sides are uniform, so composing this out of decorations is
/// not possible at all — this is the case the "CustomPaint where painting beats
/// composition" rule exists for.
///
/// Every input is a public field so tests can assert the tones and widths
/// directly instead of diffing pixels.
class FluentSplitButtonEdgePainter extends CustomPainter {
  /// Creates a painter for one half.
  const FluentSplitButtonEdgePainter({
    required this.side,
    required this.borderColor,
    required this.borderWidth,
    required this.dividerColor,
    required this.radius,
    required this.roundsLeft,
    this.dividerWidth = FluentStroke.thin,
  });

  /// Which half is being painted.
  final FluentSplitButtonSide side;

  /// Whether this half's rounded corners — and so its closed border edge — are
  /// on the left. False on the primary half under RTL, and on the menu half
  /// under LTR: the outer edge is a *leading* one for the primary action and a
  /// *trailing* one for the menu, and both mirror with the reading direction.
  final bool roundsLeft;

  /// Colour of the three outer sides.
  final Color borderColor;

  /// Width of the three outer sides. Zero on the unbordered appearances, where
  /// nothing outside the divider is drawn.
  final double borderWidth;

  /// Colour of the rule between the halves. Painted only on
  /// [FluentSplitButtonSide.primaryAction] — upstream gives the chevron half
  /// `borderLeftWidth: 0` so the rule is drawn exactly once.
  final Color dividerColor;

  /// This half's corner radius, already squared off on the inner edge.
  final BorderRadius radius;

  /// Width of the rule. [FluentStroke.thin], matching upstream's
  /// `strokeWidthThin` border.
  final double dividerWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (borderWidth > 0) {
      // Fluent borders sit inside the box, as CSS `border-box` does and as
      // Flutter's own `Border.all` does, so a centred stroke of width w runs
      // along the rect deflated by w/2.
      final rect = (Offset.zero & size).deflate(borderWidth / 2);
      canvas.drawPath(
        _outline(rect),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth
          ..color = borderColor,
      );
    }

    if (side == FluentSplitButtonSide.primaryAction && dividerWidth > 0) {
      // The rule sits on the inner edge, which is whichever one the corners
      // did not take.
      final x = roundsLeft ? size.width - dividerWidth / 2 : dividerWidth / 2;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..strokeWidth = dividerWidth
          ..color = dividerColor,
      );
    }
  }

  /// The open three-sided path, rounded on this half's outer edge only.
  ///
  /// Keyed off [roundsLeft] rather than [side]: the geometry is the same
  /// three-sided shape either way, and only which physical edge it opens on
  /// changes — which is exactly what mirrors under RTL.
  Path _outline(Rect rect) {
    final path = Path();
    if (roundsLeft) {
      final top = _clamp(radius.topLeft, rect);
      final bottom = _clamp(radius.bottomLeft, rect);
      path.moveTo(rect.right, rect.top);
      path.lineTo(rect.left + top.x, rect.top);
      if (top != Radius.zero) {
        path.arcToPoint(
          Offset(rect.left, rect.top + top.y),
          radius: top,
          clockwise: false,
        );
      }
      path.lineTo(rect.left, rect.bottom - bottom.y);
      if (bottom != Radius.zero) {
        path.arcToPoint(
          Offset(rect.left + bottom.x, rect.bottom),
          radius: bottom,
          clockwise: false,
        );
      }
      path.lineTo(rect.right, rect.bottom);
    } else {
      final top = _clamp(radius.topRight, rect);
      final bottom = _clamp(radius.bottomRight, rect);
      path.moveTo(rect.left, rect.top);
      path.lineTo(rect.right - top.x, rect.top);
      if (top != Radius.zero) {
        path.arcToPoint(
          Offset(rect.right, rect.top + top.y),
          radius: top,
          clockwise: true,
        );
      }
      path.lineTo(rect.right, rect.bottom - bottom.y);
      if (bottom != Radius.zero) {
        path.arcToPoint(
          Offset(rect.right - bottom.x, rect.bottom),
          radius: bottom,
          clockwise: true,
        );
      }
      path.lineTo(rect.left, rect.bottom);
    }
    return path;
  }

  /// Caps a corner at the half's own box, so `FluentButtonShape.circular`'s
  /// 9999 becomes a real semicircle rather than an arc Skia cannot draw.
  static Radius _clamp(Radius radius, Rect rect) => Radius.elliptical(
    math.min(radius.x, rect.width),
    math.min(radius.y, rect.height / 2),
  );

  @override
  bool shouldRepaint(FluentSplitButtonEdgePainter oldDelegate) =>
      oldDelegate.side != side ||
      oldDelegate.roundsLeft != roundsLeft ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.borderWidth != borderWidth ||
      oldDelegate.dividerColor != dividerColor ||
      oldDelegate.dividerWidth != dividerWidth ||
      oldDelegate.radius != radius;
}

/// Overrides the split button style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`.
class FluentSplitButtonTheme extends InheritedTheme {
  /// Applies [style] to every `FluentSplitButton` in [child].
  const FluentSplitButtonTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the appearance and size defaults.
  final FluentSplitButtonStyle style;

  /// The nearest split button style, or null.
  static FluentSplitButtonStyle? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FluentSplitButtonTheme>()
      ?.style;

  @override
  bool updateShouldNotify(FluentSplitButtonTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentSplitButtonTheme(style: style, child: child);
}

/// A Fluent 2 split button: a default action and a menu, in one container.
///
/// ```dart
/// FluentSplitButton(
///   menuSemanticLabel: 'More send options',
///   onPressed: send,
///   onMenuPressed: openMenu,
///   child: const Text('Send'),
/// )
/// ```
///
/// The two halves are genuinely separate controls — separate hit targets,
/// separate focus stops, separate hover and press states, and separate
/// callbacks. They share one visual container: the outer corners are rounded,
/// the inner ones are square, and a 1px divider sits between them.
///
/// Disabling is per half: `onPressed: null` disables the action while leaving
/// the menu reachable, which is a real arrangement, and passing null to both
/// disables the pair. Disabled is a real state, not a visual treatment — a
/// disabled half stops reporting hover and press, refuses focus, and never
/// invokes its callback.
///
/// The chevron half is [FluentSize.size240] wide at every size — Figma draws it
/// from a component with no size axis — which is also WCAG 2.2's minimum target
/// size for adjacent targets.
class FluentSplitButton extends StatelessWidget {
  /// Creates a split button.
  const FluentSplitButton({
    super.key,
    required this.child,
    required this.menuSemanticLabel,
    this.onPressed,
    this.onMenuPressed,
    this.appearance = FluentButtonAppearance.secondary,
    this.size = FluentButtonSize.medium,
    this.shape = FluentButtonShape.rounded,
    this.iconPosition = FluentButtonIconPosition.before,
    this.icon,
    this.menuIcon,
    this.style,
    this.focusNode,
    this.menuFocusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  /// The primary action's label.
  final Widget child;

  /// Announced for the chevron half, which has no text of its own.
  ///
  /// Required, for the same reason `FluentButton.icon` requires one: a control
  /// a screen reader announces as an unnamed button is a dead end.
  final String menuSemanticLabel;

  /// Invoked on tap and on Space or Enter on the primary half. Null disables
  /// that half.
  final VoidCallback? onPressed;

  /// Invoked on tap and on Space or Enter on the chevron half. Null disables
  /// that half.
  final VoidCallback? onMenuPressed;

  /// Fill and outline treatment.
  final FluentButtonAppearance appearance;

  /// Height and type ramp.
  final FluentButtonSize size;

  /// Corner treatment. Applies to the pair's outer corners only.
  final FluentButtonShape shape;

  /// Which side of the label the primary half's icon sits on.
  final FluentButtonIconPosition iconPosition;

  /// Optional icon on the primary half.
  final Widget? icon;

  /// The chevron. Defaults to [fluentMenuChevron].
  final Widget? menuIcon;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentSplitButtonStyle? style;

  /// Focus node for the primary half. One is created internally when omitted.
  final FocusNode? focusNode;

  /// Focus node for the chevron half. One is created internally when omitted.
  final FocusNode? menuFocusNode;

  /// Whether the primary half takes focus on mount.
  final bool autofocus;

  /// Announced for the primary half. Optional; the label already carries the
  /// meaning.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final state = resolveFluentSplitButtonState(
      enabled: onPressed != null,
      menuEnabled: onMenuPressed != null,
      appearance: appearance,
      size: size,
      shape: shape,
      iconPosition: iconPosition,
      icon: icon,
      label: child,
      menuIcon: menuIcon,
    );
    final theme = FluentTheme.of(context);

    Widget half(FluentSplitButtonSide side) {
      // Lowest to highest: defaults, subtree theme, then the caller's own
      // style.
      final resolved = resolveFluentSplitButtonStyle(
        state,
        theme,
        side: side,
      ).merge(FluentSplitButtonTheme.maybeOf(context)).merge(style);
      final onSide = side == FluentSplitButtonSide.primaryAction
          ? onPressed
          : onMenuPressed;

      return Semantics(
        button: true,
        enabled: onSide != null,
        label: side == FluentSplitButtonSide.primaryAction
            ? semanticLabel
            : menuSemanticLabel,
        child: FluentInteractive(
          onPressed: onSide,
          enabled: onSide != null,
          focusNode: side == FluentSplitButtonSide.primaryAction
              ? focusNode
              : menuFocusNode,
          autofocus: autofocus && side == FluentSplitButtonSide.primaryAction,
          builder: (context, states, _) =>
              buildFluentSplitButton(state, resolved, states, side: side),
        ),
      );
    }

    // Upstream is a flexbox, so `align-items: stretch` gives the chevron half
    // the container's height for free. Flutter's Row cannot both size itself to
    // its children and stretch them, so the height is measured first: without
    // it a wrapped label makes the primary half taller and the chevron half is
    // left floating at the size ramp's height, which is what the `With long
    // text` story shows.
    return IntrinsicHeight(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          half(FluentSplitButtonSide.primaryAction),
          half(FluentSplitButtonSide.menu),
        ],
      ),
    );
  }
}
