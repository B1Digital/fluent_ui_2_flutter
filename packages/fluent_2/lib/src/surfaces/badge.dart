import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import '../internal/interaction.dart';
import 'badge_style.dart';

/// The semantic colour family a badge carries. Figma's `Color` axis.
///
/// These are the first components in this package to consume the `Status/*`
/// layer ported into core, so every mapping is asserted token-by-token in
/// `test/surfaces/badge_test.dart` rather than eyeballed.
enum FluentBadgeColor {
  /// Brand fill. The default.
  brand,

  /// `Status/Danger/*` — red.
  danger,

  /// `Status/Warning/*` — orange.
  warning,

  /// `Status/Success/*` — green.
  success,

  /// Inverted neutral: the darkest neutral foreground used as a fill.
  important,

  /// Quiet neutral, for counts and metadata.
  informative,

  /// The quietest neutral, for badges over an image or a coloured surface.
  subtle,
}

/// Badge height and type ramp. Figma's `Size` axis.
enum FluentBadgeSize {
  /// 16 high, caption2 type, 12 icon.
  small,

  /// 20 high, caption2 type, 12 icon.
  medium,

  /// 24 high, caption1 type, 16 icon.
  large,

  /// 32 high, caption1 type, 20 icon.
  extraLarge,
}

/// How a badge is filled and outlined. Figma's `Appearance` axis.
enum FluentBadgeAppearance {
  /// Solid fill in the badge colour. The default.
  filled,

  /// Pale fill with a matching border.
  tint,

  /// No fill, coloured border.
  outline,

  /// No fill and no border; the label alone carries the colour.
  ///
  /// Named after Figma's `Appearance=Subtle`, which upstream React calls
  /// `ghost`. Not to be confused with [FluentBadgeColor.subtle].
  subtle,
}

/// Which side of the label the icon sits on.
enum FluentBadgeIconPosition {
  /// Before the label in reading order. The default.
  before,

  /// After the label in reading order.
  after,
}

/// Everything needed to render a badge, independent of colour, size and
/// appearance.
///
/// The counterpart of `FluentButtonBaseState`, and what makes "Fluent's state,
/// my own styling, Fluent's rendering" a supported path rather than a fork.
/// There is deliberately no `enabled` flag: Fluent gives Badge no disabled
/// variant, and inventing one would be a visual treatment pretending to be a
/// state.
@immutable
class FluentBadgeBaseState {
  /// Creates a base state.
  const FluentBadgeBaseState({
    required this.iconPosition,
    this.icon,
    this.label,
  });

  /// Which side the icon sits on.
  final FluentBadgeIconPosition iconPosition;

  /// The icon, if any.
  final Widget? icon;

  /// The label, if any. A badge with neither is a bare dot.
  final Widget? label;
}

/// A badge's fully resolved state, including the design axes.
///
/// The counterpart of `FluentButtonState`: base state plus exactly `color`,
/// `size` and `appearance`.
@immutable
class FluentBadgeState extends FluentBadgeBaseState {
  /// Creates a resolved state.
  const FluentBadgeState({
    required super.iconPosition,
    required this.color,
    required this.size,
    required this.appearance,
    super.icon,
    super.label,
  });

  /// Semantic colour family.
  final FluentBadgeColor color;

  /// Height and type ramp.
  final FluentBadgeSize size;

  /// Fill and outline treatment.
  final FluentBadgeAppearance appearance;
}

/// Builds the state a badge will be styled and rendered from.
///
/// The first of the three-function recomposition contract.
FluentBadgeState resolveFluentBadgeState({
  FluentBadgeColor color = FluentBadgeColor.brand,
  FluentBadgeSize size = FluentBadgeSize.medium,
  FluentBadgeAppearance appearance = FluentBadgeAppearance.filled,
  FluentBadgeIconPosition iconPosition = FluentBadgeIconPosition.before,
  Widget? icon,
  Widget? label,
}) => FluentBadgeState(
  color: color,
  size: size,
  appearance: appearance,
  iconPosition: iconPosition,
  icon: icon,
  label: label,
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes. Every value comes from a Fluent token; nothing
/// here computes a colour, and nothing derives one appearance from another.
///
/// Token sources are the Figma `Badge` component set, extracted into
/// `test/fixtures/badge.json` and asserted for all 28 colour/appearance pairs.
///
/// Two Figma readings are worth flagging, because both look like mistakes when
/// diffed against `@fluentui/react-components` and neither is ours:
///
/// * Only `Brand` + `Filled` carries a border, bound to `Brand/Stroke/1/Rest`
///   — the same colour as its fill, so it is invisible. React gives every badge
///   a `colorTransparentStroke` border instead. Figma wins here, so the other
///   six filled colours get no border at all.
/// * `Warning` + `Outline` strokes with `Status/Warning/Foreground/2/Rest`
///   rather than the `Stroke/2` its Danger and Success siblings use.
FluentBadgeStyle resolveFluentBadgeStyle(
  FluentBadgeState state,
  FluentThemeData theme,
) {
  final c = theme.colors;

  final background = switch (state.appearance) {
    FluentBadgeAppearance.filled => switch (state.color) {
      FluentBadgeColor.brand => c.brandBackground,
      FluentBadgeColor.danger => c.statusDangerBackground3,
      FluentBadgeColor.warning => c.statusWarningBackground3,
      FluentBadgeColor.success => c.statusSuccessBackground3,
      FluentBadgeColor.important => c.neutralForeground1,
      FluentBadgeColor.informative => c.neutralBackground5,
      FluentBadgeColor.subtle => c.neutralBackground5,
    },
    FluentBadgeAppearance.tint => switch (state.color) {
      FluentBadgeColor.brand => c.brandBackground2,
      FluentBadgeColor.danger => c.statusDangerBackground1,
      FluentBadgeColor.warning => c.statusWarningBackground1,
      FluentBadgeColor.success => c.statusSuccessBackground1,
      FluentBadgeColor.important => c.neutralForeground3,
      FluentBadgeColor.informative => c.neutralBackground4,
      FluentBadgeColor.subtle => c.neutralBackground1,
    },
    // Figma paints no fill on these two. The token, not a literal: Fluent's
    // transparent tokens turn opaque in high contrast.
    FluentBadgeAppearance.outline ||
    FluentBadgeAppearance.subtle => c.transparentBackground,
  };

  final foreground = switch (state.appearance) {
    FluentBadgeAppearance.filled => switch (state.color) {
      FluentBadgeColor.brand ||
      FluentBadgeColor.danger ||
      FluentBadgeColor.success => c.neutralForegroundOnBrand,
      // Orange is light enough that white fails contrast, so Warning takes the
      // theme-independent dark foreground instead.
      FluentBadgeColor.warning => c.neutralForeground1Static,
      FluentBadgeColor.important => c.neutralBackground1,
      FluentBadgeColor.informative => c.neutralForeground3,
      FluentBadgeColor.subtle => c.neutralForeground1,
    },
    FluentBadgeAppearance.tint => switch (state.color) {
      FluentBadgeColor.brand => c.brandForeground2,
      FluentBadgeColor.danger => c.statusDangerForeground1,
      FluentBadgeColor.warning => c.statusWarningForeground2,
      FluentBadgeColor.success => c.statusSuccessForeground1,
      FluentBadgeColor.important => c.neutralBackground1,
      FluentBadgeColor.informative => c.neutralForeground3,
      FluentBadgeColor.subtle => c.neutralForeground3,
    },
    // Outline and Subtle share a label ramp in Figma, variant for variant.
    FluentBadgeAppearance.outline ||
    FluentBadgeAppearance.subtle => switch (state.color) {
      FluentBadgeColor.brand => c.brandForeground1,
      FluentBadgeColor.danger => c.statusDangerForeground3,
      FluentBadgeColor.warning => c.statusWarningForeground2,
      FluentBadgeColor.success => c.statusSuccessForeground3,
      FluentBadgeColor.important => c.neutralForeground3,
      FluentBadgeColor.informative => c.neutralForeground3,
      FluentBadgeColor.subtle => c.neutralForegroundOnBrand,
    },
  };

  final border = switch (state.appearance) {
    FluentBadgeAppearance.filled =>
      state.color == FluentBadgeColor.brand ? c.brandStroke1 : null,
    FluentBadgeAppearance.tint => switch (state.color) {
      FluentBadgeColor.brand => c.brandStroke2,
      FluentBadgeColor.danger => c.statusDangerBorder1,
      FluentBadgeColor.warning => c.statusWarningBorder1,
      FluentBadgeColor.success => c.statusSuccessBorder1,
      FluentBadgeColor.important => c.neutralStrokeAccessible,
      FluentBadgeColor.informative => c.neutralStroke2,
      FluentBadgeColor.subtle => c.neutralStroke2,
    },
    FluentBadgeAppearance.outline => switch (state.color) {
      FluentBadgeColor.brand => c.brandStroke1,
      FluentBadgeColor.danger => c.statusDangerBorder2,
      FluentBadgeColor.warning => c.statusWarningForeground2,
      FluentBadgeColor.success => c.statusSuccessBorder2,
      FluentBadgeColor.important => c.neutralStrokeAccessible,
      FluentBadgeColor.informative => c.neutralStroke2,
      FluentBadgeColor.subtle => c.neutralForegroundOnBrand,
    },
    FluentBadgeAppearance.subtle => null,
  };

  // Geometry, verbatim from the Figma Badge set.
  final (height, horizontal, gap, iconSize, textStyle) = switch (state.size) {
    FluentBadgeSize.small => (
      16.0,
      FluentSpacing.xxs,
      FluentSpacing.none,
      FluentSize.size120,
      theme.typography.caption2Strong,
    ),
    FluentBadgeSize.medium => (
      20.0,
      FluentSpacing.xs,
      FluentSpacing.none,
      FluentSize.size120,
      theme.typography.caption2Strong,
    ),
    FluentBadgeSize.large => (
      24.0,
      FluentSpacing.xs,
      FluentSpacing.xxs,
      FluentSize.size160,
      theme.typography.caption1Strong,
    ),
    FluentBadgeSize.extraLarge => (
      32.0,
      FluentSpacing.sNudge,
      FluentSpacing.xxs,
      FluentSize.size200,
      theme.typography.caption1Strong,
    ),
  };

  return FluentBadgeStyle(
    backgroundColor: FluentStateColor.tokens(rest: background),
    foregroundColor: FluentStateColor.tokens(rest: foreground),
    borderColor: border == null ? null : FluentStateColor.tokens(rest: border),
    borderWidth: WidgetStatePropertyAll<double?>(
      border == null ? FluentStroke.none : FluentStroke.thin,
    ),
    // Every size binds the same 4px radius in Figma. The Badge set has no
    // Shape axis at all, so there is nothing here to switch on.
    borderRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allMedium,
    ),
    textStyle: WidgetStatePropertyAll<TextStyle?>(textStyle),
    padding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.symmetric(horizontal: horizontal),
    ),
    gap: WidgetStatePropertyAll<double?>(gap),
    iconSize: WidgetStatePropertyAll<double?>(iconSize),
    minimumSize: WidgetStatePropertyAll<Size?>(Size(height, height)),
  );
}

/// Renders a badge from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentBadgeBaseState] rather than [FluentBadgeState] on purpose: it never
/// reads colour, size or appearance, so a consumer can supply their own style
/// and still use Fluent's rendering.
///
/// [states] is accepted for symmetry with the interactive components and for
/// badges composed into a surface that does have interaction states. A
/// standalone [FluentBadge] always passes an empty set — Fluent ships no
/// hover, pressed or disabled Badge tokens, and there is **no transition**
/// here either: upstream declares none, so a colour change lands on the frame.
Widget buildFluentBadge(
  FluentBadgeBaseState state,
  FluentBadgeStyle style,
  Set<WidgetState> states,
) {
  final radius = style.borderRadius?.resolve(states) ?? FluentRadius.allMedium;
  final borderWidth = style.borderWidth?.resolve(states) ?? FluentStroke.none;
  final borderColor = style.borderColor?.resolve(states);
  final background = style.backgroundColor?.resolve(states);
  final foreground = style.foregroundColor?.resolve(states);
  final padding = style.padding?.resolve(states) ?? EdgeInsets.zero;
  final gap = style.gap?.resolve(states) ?? FluentSpacing.none;
  final iconSize = style.iconSize?.resolve(states) ?? FluentSize.size120;
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

  Widget content = Row(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    spacing: state.icon != null && state.label != null ? gap : 0,
    children: switch (state.iconPosition) {
      FluentBadgeIconPosition.before => children,
      FluentBadgeIconPosition.after => children.reversed.toList(),
    },
  );

  if (textStyle != null || foreground != null) {
    content = DefaultTextStyle.merge(
      style: (textStyle ?? const TextStyle()).copyWith(color: foreground),
      child: content,
    );
  }

  return ConstrainedBox(
    constraints: BoxConstraints(
      minWidth: minimumSize.width,
      minHeight: minimumSize.height,
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
  );
}

/// Overrides the badge style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`.
class FluentBadgeTheme extends InheritedTheme {
  /// Applies [style] to every `FluentBadge` in [child].
  const FluentBadgeTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the colour, size and appearance defaults.
  final FluentBadgeStyle style;

  /// The nearest badge style, or null.
  static FluentBadgeStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentBadgeTheme>()?.style;

  @override
  bool updateShouldNotify(FluentBadgeTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentBadgeTheme(style: style, child: child);
}

/// A Fluent 2 badge: a small, non-interactive status or count marker.
///
/// ```dart
/// FluentBadge(
///   color: FluentBadgeColor.danger,
///   appearance: FluentBadgeAppearance.tint,
///   icon: const Icon(FluentIcons.alert_20_filled),
///   child: const Text('9'),
/// )
/// ```
///
/// Both [icon] and [child] are optional; with neither, the badge is a bare dot
/// sized to its own height.
///
/// It is a marker, not a control: there is no `onPressed`, no focus ring, and
/// no hover, pressed or disabled treatment, because Fluent ships no such
/// tokens for Badge. Wrap it in your own gesture surface if a badge has to be
/// tappable, so the affordance is visible in the call site rather than hidden
/// in here.
///
/// Customisation follows the same three rungs as `FluentButton`. [style] is
/// merged last and wins; [FluentBadgeTheme] restyles a subtree; and
/// [resolveFluentBadgeState], [resolveFluentBadgeStyle] and [buildFluentBadge]
/// are public so any one of them can be replaced without forking this widget.
class FluentBadge extends StatelessWidget {
  /// Creates a badge with an optional [icon] and [child] label.
  const FluentBadge({
    super.key,
    this.child,
    this.icon,
    this.color = FluentBadgeColor.brand,
    this.size = FluentBadgeSize.medium,
    this.appearance = FluentBadgeAppearance.filled,
    this.iconPosition = FluentBadgeIconPosition.before,
    this.style,
    this.semanticLabel,
  });

  /// The label. Null for an icon-only or empty badge.
  final Widget? child;

  /// Optional leading or trailing icon.
  final Widget? icon;

  /// Semantic colour family.
  final FluentBadgeColor color;

  /// Height and type ramp.
  final FluentBadgeSize size;

  /// Fill and outline treatment.
  final FluentBadgeAppearance appearance;

  /// Which side of the label the icon sits on.
  final FluentBadgeIconPosition iconPosition;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentBadgeStyle? style;

  /// Announced by assistive technology.
  ///
  /// Worth setting whenever the badge's meaning is not carried by [child] —
  /// `'3 unread'` reads better than `'3'`, and a dot badge has nothing to
  /// announce at all without one.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final state = resolveFluentBadgeState(
      color: color,
      size: size,
      appearance: appearance,
      iconPosition: iconPosition,
      icon: icon,
      label: child,
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentBadgeStyle(
      state,
      FluentTheme.of(context),
    ).merge(FluentBadgeTheme.maybeOf(context)).merge(style);

    final badge = buildFluentBadge(state, resolved, const <WidgetState>{});
    if (semanticLabel == null) return badge;
    // Replaces the label rather than prefixing it, matching upstream's
    // `aria-label`: a badge reading "3 unread" must not also announce "3".
    return Semantics(
      label: semanticLabel,
      container: true,
      excludeSemantics: true,
      child: badge,
    );
  }
}
