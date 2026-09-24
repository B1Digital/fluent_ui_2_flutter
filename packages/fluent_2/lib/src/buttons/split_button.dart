import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import '../internal/animated_style.dart';
import '../internal/interaction.dart';
import '../internal/menu_trigger_scope.dart';
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
///   menuIcon: fluentMenuChevron,
///   onPressed: () {},
///   child: const Text('Menu'),
/// )
/// ```
///
/// Deliberately sizeless, so it inherits the menu icon size the button's own
/// size ramp resolved — 12, or 16 at large — rather than pinning one of its
/// own.
const Widget fluentMenuChevron = Icon(FluentIcons.chevron_down_20_regular);

/// The chevron half's minimum width, at every size.
///
/// WCAG 2.2's minimum target size for a pointer target immediately adjacent to
/// another one; upstream names it `MIN_TARGET_SIZE` in
/// `useSplitButtonStyles.styles.ts`, citing that guideline. It is a floor, not
/// a width: small and medium land on it, large grows past it to 31.
const double _menuMinWidth = FluentSize.size240;

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

  /// Colour of the 1px rule between the two halves, or null where upstream's
  /// rule is transparent — enabled subtle and transparent split buttons.
  ///
  /// Not derivable from [FluentButtonStyle.borderColor]: on the primary
  /// appearance the surrounding button has no border at all, yet the rule is
  /// there, in `neutralStrokeOnBrand`.
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
    super.menuIcon,
  });

  /// Whether the chevron half responds to input.
  final bool menuEnabled;

  /// The base state of one [side], as `FluentButton` would see it.
  FluentButtonBaseState half(FluentSplitButtonSide side) => switch (side) {
    FluentSplitButtonSide.primaryAction => FluentButtonBaseState(
      enabled: enabled,
      iconPosition: iconPosition,
      icon: icon,
      label: label,
    ),
    // Upstream's chevron half is a `MenuButton` with no label and no icon, so
    // the chevron is its `menuIcon` — in the label's colour, which keeps it
    // out of subtle's brand icon ramp.
    FluentSplitButtonSide.menu => FluentButtonBaseState(
      enabled: menuEnabled,
      iconPosition: iconPosition,
      menuIcon: menuIcon ?? fluentMenuChevron,
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
      menuIcon: base.menuIcon,
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
    // Upstream's chevron half is a `MenuButton` with no label, so it takes the
    // icon-only padding — 1, 5 or 7 — around its `menuIcon` of 12, 12 or 16,
    // and `useSplitButtonStyles` swaps icon-only's square width for a
    // `minWidth` of 24. Large therefore comes out 31 wide, not 24.
    //
    // It has no leading border (`borderLeftWidth: 0`), so only the other three
    // sides add a border to the inset — 1px, or the 3px an open outline menu
    // takes, which widens the half by the difference as it does upstream.
    final inset = switch (state.size) {
      FluentButtonSize.small => 1.0,
      FluentButtonSize.medium => 5.0,
      FluentButtonSize.large => 7.0,
    };
    final borderWidth = button.borderWidth;
    final minimumSize = button.minimumSize;
    button = button.copyWith(
      padding: WidgetStateProperty.resolveWith<EdgeInsetsGeometry?>((states) {
        final edge =
            inset +
            math.max(borderWidth?.resolve(states) ?? 0, FluentStroke.thin);
        return EdgeInsetsDirectional.fromSTEB(inset, edge, edge, edge);
      }),
      // The focus ring is the border plus a 1px inset shadow, so on the seam,
      // where this half has no border, only the shadow's pixel is left.
      focusRingInsets: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
        EdgeInsetsDirectional.fromSTEB(1, 2, 2, 2),
      ),
      minimumSize: WidgetStateProperty.resolveWith<Size?>(
        (states) =>
            Size(_menuMinWidth, minimumSize?.resolve(states)?.height ?? 0),
      ),
    );
  }

  // The divider is the primary half's `borderRightColor`; the chevron half has
  // `borderLeftWidth: 0`, so the rule is drawn exactly once. Per
  // `useSplitButtonStyles`: colorNeutralStrokeOnBrand on primary in every
  // state, transparent on subtle and transparent, the button's own border on
  // secondary and outline — and colorNeutralStrokeDisabled on every appearance
  // once disabled, so a disabled subtle split button still shows its seam.
  final border = button.borderColor;
  final divider = WidgetStateProperty.resolveWith<Color?>((states) {
    if (states.contains(WidgetState.disabled)) return c.neutralStrokeDisabled;
    // A focused primary half's whole border — the rule included — is the focus
    // ring's outer pixel, on every appearance.
    if (states.contains(WidgetState.focused)) return c.strokeFocus2;
    return switch (state.appearance) {
      FluentButtonAppearance.primary => c.neutralStrokeOnBrand,
      FluentButtonAppearance.secondary ||
      FluentButtonAppearance.outline => border?.resolve(states),
      FluentButtonAppearance.subtle ||
      FluentButtonAppearance.transparent => null,
    };
  });

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
    // Upstream's rule is transparent rather than absent on enabled subtle and
    // transparent, so it fades in with the border transition when the half is
    // disabled; standing null in as transparent does the same, and keeps the
    // painter — and so the half's subtree — mounted across the change.
    const clear = Color(0x00000000);
    final borderColor = button.borderColor?.resolve(states) ?? clear;
    final dividerColor = style.dividerColor?.resolve(states) ?? clear;

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
    // own decoration: it is painted together with the rule between the halves,
    // whose colour is styled on its own, and a Border under a border radius
    // accepts only one visible colour.
    final half = buildFluentButton(
      state.half(side),
      button.copyWith(
        borderRadius: WidgetStatePropertyAll<BorderRadius?>(halfRadius),
        borderWidth: const WidgetStatePropertyAll<double?>(FluentStroke.none),
      ),
      states,
    );

    return FluentAnimatedStyle<FluentSplitButtonEdgeColors>(
      // Upstream transitions `border` alongside `background` and `color` on the
      // button root, at the same duration and curve — the divider is part of
      // that border, so it tweens with the surface rather than snapping.
      value: FluentSplitButtonEdgeColors(
        border: borderColor,
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
/// A painter rather than a [Border] on the half's [BoxDecoration] because the
/// rule has a colour of its own — [FluentSplitButtonStyle.dividerColor] — and a
/// [Border] under a border radius accepts only one visible colour. The three
/// outer sides still go through the framework's
/// [BoxBorder.paintNonUniformBorder], so their corners are exactly the ones
/// `FluentButton`'s own border draws.
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
      // The framework's own border geometry, which is CSS's: an oversized
      // radius scales every corner by one factor, so circular's 9999 lands on a
      // semicircle, and the open edge takes no border while the top and bottom
      // still run the full width to the seam.
      final edge = BorderSide(color: borderColor, width: borderWidth);
      BoxBorder.paintNonUniformBorder(
        canvas,
        Offset.zero & size,
        borderRadius: radius,
        textDirection: null,
        top: edge,
        bottom: edge,
        left: roundsLeft ? edge : BorderSide.none,
        right: roundsLeft ? BorderSide.none : edge,
        color: borderColor,
      );
    }

    if (side == FluentSplitButtonSide.primaryAction && dividerWidth > 0) {
      // The rule is the primary button's own border on the inner edge, which
      // is whichever one the corners did not take. CSS mitres a border side
      // into its neighbours, and upstream's top and bottom are 1px even where
      // they are transparent, as on primary — so the rule's ends are cut at
      // 45° inside that pixel instead of running square through the outline.
      // The unpainted sides are there only for their width.
      final rule = BorderSide(color: dividerColor, width: dividerWidth);
      final seam = BorderSide(
        width: math.max(borderWidth, FluentStroke.thin),
        style: BorderStyle.none,
      );
      paintBorder(
        canvas,
        Offset.zero & size,
        top: seam,
        bottom: seam,
        right: roundsLeft ? rule : BorderSide.none,
        left: roundsLeft ? BorderSide.none : rule,
      );
    }
  }

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
/// The chevron half is never narrower than [FluentSize.size240], WCAG 2.2's
/// minimum target size for adjacent targets.
///
/// Inside a `FluentMenu`'s trigger the chevron half shows the menu's open state
/// by itself, as upstream's does when handed `MenuTrigger`'s props; set
/// [menuExpanded] to drive it from anything else.
class FluentSplitButton extends StatelessWidget {
  /// Creates a split button.
  const FluentSplitButton({
    super.key,
    required this.menuSemanticLabel,
    this.child,
    this.onPressed,
    this.onMenuPressed,
    this.appearance = FluentButtonAppearance.secondary,
    this.size = FluentButtonSize.medium,
    this.shape = FluentButtonShape.rounded,
    this.iconPosition = FluentButtonIconPosition.before,
    this.icon,
    this.menuIcon,
    this.menuExpanded,
    this.style,
    this.focusNode,
    this.menuFocusNode,
    this.autofocus = false,
    this.semanticLabel,
  }) : assert(
         child != null || (icon != null && semanticLabel != null),
         'An icon-only split button needs an icon and a semanticLabel.',
       );

  /// The primary action's label. Null makes the primary half icon-only, which
  /// then needs [icon] and [semanticLabel].
  final Widget? child;

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

  /// Whether the menu the chevron half opens is open, which upstream draws in
  /// the half's `Selected` tokens and announces as `aria-expanded`.
  ///
  /// Null follows the enclosing `FluentMenu`, if the split button is its
  /// trigger, and is otherwise closed.
  final bool? menuExpanded;

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
    final expanded =
        menuExpanded ?? FluentMenuTriggerScope.maybeIsOpenOf(context) ?? false;

    Widget half(FluentSplitButtonSide side) {
      // Lowest to highest: defaults, subtree theme, then the caller's own
      // style.
      final resolved = resolveFluentSplitButtonStyle(
        state,
        theme,
        side: side,
      ).merge(FluentSplitButtonTheme.maybeOf(context)).merge(style);
      final isMenu = side == FluentSplitButtonSide.menu;
      final onSide = isMenu ? onMenuPressed : onPressed;

      return Semantics(
        button: true,
        enabled: onSide != null,
        expanded: isMenu ? expanded : null,
        label: isMenu ? menuSemanticLabel : semanticLabel,
        child: FluentInteractive(
          onPressed: onSide,
          enabled: onSide != null,
          focusNode: isMenu ? menuFocusNode : focusNode,
          autofocus: autofocus && !isMenu,
          // Both halves are Buttons, pressed under `:hover:active`.
          pressedRequiresHover: true,
          // An open menu is the chevron half's `Selected` step, below hover
          // and press exactly as upstream's `aria-expanded` rule sits below
          // `:hover` — so pointing at an open menu's chevron still lights it.
          builder: (context, states, _) => buildFluentSplitButton(
            state,
            resolved,
            isMenu && expanded ? {...states, WidgetState.selected} : states,
            side: side,
          ),
        ),
      );
    }

    // Chrome snaps a box's edges to whole device pixels; Flutter lays a label
    // out at its fractional width, which leaves the seam — and the 1px rule on
    // it — smeared across two pixels. Rounding the primary half up to a whole
    // device pixel puts the seam back on one.
    final primary = IntrinsicWidth(
      stepWidth: 1 / (MediaQuery.maybeDevicePixelRatioOf(context) ?? 1),
      child: half(FluentSplitButtonSide.primaryAction),
    );

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
        children: <Widget>[primary, half(FluentSplitButtonSide.menu)],
      ),
    );
  }
}
