import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/semantics.dart' show SemanticsRole;
import 'package:flutter/widgets.dart';

import '../internal/interaction.dart';
import 'status_indicator_style.dart';

/// Which token family tints the glyph. Figma's `Category` axis.
///
/// Only [success], [error] and [warning] reach the STATUS layer. The other two
/// are the reason this enum exists rather than a `statusSevere*` alias lookup:
/// Figma binds them to the neutral and brand families instead.
enum FluentStatusIndicatorCategory {
  /// Figma `Informational/Neutral`, bound to `Neutral/Foreground/3/Rest`.
  informational,

  /// Figma `Success`, bound to `Status/Success/Foreground/1/Rest`.
  success,

  /// Figma `Error`, bound to `Status/Danger/Foreground/1/Rest`. Note the axis
  /// value is `Error` while the token family is `Danger`.
  error,

  /// Figma `Active/ In Progress`, bound to `Brand/Foreground/1/Rest` — brand,
  /// not status: work in flight is the product acting, not a condition report.
  active,

  /// Figma `Warning`, bound to `Status/Warning/Foreground/1/Rest`.
  warning,
}

/// Glyph edge length and type ramp. Figma's `Size` axis.
enum FluentStatusIndicatorSize {
  /// 12 glyph in a 16 line box, caption type.
  small,

  /// 16 glyph in a 20 line box, body type. The default.
  medium,

  /// 20 glyph in a 24 line box, larger body type.
  large,
}

/// The status being reported. Figma's `Message` axis.
///
/// In Figma this axis pairs a glyph with a label and pins a
/// [FluentStatusIndicatorCategory]: 16 messages times 3 sizes is exactly the 48
/// variants in the set, so no message ever appears under a second category.
/// That pairing is [category], and it is the only thing this enum decides —
/// the glyph itself is supplied by the caller, since Fluent's icon set is not
/// part of this package.
enum FluentStatusIndicatorMessage {
  /// Figma `Archived`. Arrow Circle Down Right.
  archived,

  /// Figma `Cancelled`. Subtract Circle.
  cancelled,

  /// Figma `Draft`. Circle Half Fill.
  draft,

  /// Figma `Failed`. Diamond Dismiss.
  failed,

  /// Figma `InProgress`. Circle Half Fill.
  inProgress,

  /// Figma `New`. Circle.
  ///
  /// Not named `new`, which is a Dart reserved word.
  newItem,

  /// Figma `Not started`. Circle.
  notStarted,

  /// Figma `Pause`. Pause Circle.
  pause,

  /// Figma `Pending`. Arrow Clockwise Dashes.
  pending,

  /// Figma `Scheduled`. Clock.
  scheduled,

  /// Figma `Success`. Checkmark Circle.
  success,

  /// Figma `Synced`. Arrow Sync.
  synced,

  /// Figma `Syncing`. Arrow Sync.
  syncing,

  /// Figma `Unknown`. Question Circle.
  unknown,

  /// Figma `Warning`. Warning.
  warning,

  /// Figma `Generic information`. Info.
  genericInformation;

  /// The category Figma pairs this message with.
  ///
  /// Overridable on the widget, because a host app that reuses `synced` for a
  /// stale-cache warning needs the amber glyph without inventing a message.
  FluentStatusIndicatorCategory get category => switch (this) {
    success || synced => FluentStatusIndicatorCategory.success,
    failed || cancelled => FluentStatusIndicatorCategory.error,
    warning => FluentStatusIndicatorCategory.warning,
    newItem || syncing || inProgress => FluentStatusIndicatorCategory.active,
    archived ||
    draft ||
    genericInformation ||
    notStarted ||
    pause ||
    pending ||
    scheduled ||
    unknown => FluentStatusIndicatorCategory.informational,
  };
}

/// Everything needed to render a status indicator, independent of category and
/// size.
///
/// The counterpart of `FluentButtonBaseState`: what
/// [buildFluentStatusIndicator] reads, and nothing more, which is what lets a
/// consumer keep Fluent's rendering while substituting their own styling.
@immutable
class FluentStatusIndicatorBaseState {
  /// Creates a base state.
  const FluentStatusIndicatorBaseState({required this.icon, this.label});

  /// The glyph. Required: a status indicator with no glyph is a line of text.
  final Widget icon;

  /// The label, if any. Null renders the glyph alone.
  final Widget? label;
}

/// A status indicator's fully resolved state, including the design axes.
///
/// The counterpart of `FluentButtonState`: base state plus exactly `message`,
/// `category` and `size`.
@immutable
class FluentStatusIndicatorState extends FluentStatusIndicatorBaseState {
  /// Creates a resolved state.
  const FluentStatusIndicatorState({
    required super.icon,
    required this.message,
    required this.category,
    required this.size,
    super.label,
  });

  /// The status being reported.
  final FluentStatusIndicatorMessage message;

  /// The token family tinting the glyph, already resolved from [message] or
  /// from the caller's override.
  final FluentStatusIndicatorCategory category;

  /// Glyph size and type ramp.
  final FluentStatusIndicatorSize size;
}

/// Builds the state a status indicator will be styled and rendered from.
///
/// The first of the three-function recomposition contract, and the only place
/// the message-to-category pairing is applied: `category` overrides
/// [FluentStatusIndicatorMessage.category] when given.
FluentStatusIndicatorState resolveFluentStatusIndicatorState({
  required FluentStatusIndicatorMessage message,
  required Widget icon,
  FluentStatusIndicatorCategory? category,
  FluentStatusIndicatorSize size = FluentStatusIndicatorSize.medium,
  Widget? label,
}) => FluentStatusIndicatorState(
  message: message,
  category: category ?? message.category,
  size: size,
  icon: icon,
  label: label,
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes. Every value comes from a Fluent token; nothing
/// here computes a colour.
///
/// Token sources are the Figma `.StatusIndicator` component set, extracted into
/// `test/fixtures/status_indicator.json` and asserted variant-by-variant in the
/// tests. The glyph tint is the one binding the fixture cannot carry — it lives
/// on the `IconHolder > Shape` vector two levels inside each variant — so it is
/// transcribed onto [FluentStatusIndicatorCategory] and asserted against the
/// named alias getters instead of against hex.
///
/// The alias getters (`colors.statusSuccessForeground1`) are used rather than
/// the Figma-shaped `colors.statusSuccessForeground1`: only the alias layer
/// is reached by `FluentThemeOverride` and overridden by the high contrast
/// palette. In light mode the two agree on every token this component touches.
FluentStatusIndicatorStyle resolveFluentStatusIndicatorStyle(
  FluentStatusIndicatorState state,
  FluentThemeData theme,
) {
  final c = theme.colors;

  // Rest only. The Figma set has no State axis, so there is no hover, pressed,
  // selected or disabled token to select between.
  final icon = FluentStateColor.tokens(
    rest: switch (state.category) {
      FluentStatusIndicatorCategory.informational => c.neutralForeground3,
      FluentStatusIndicatorCategory.success => c.statusSuccessForeground1,
      FluentStatusIndicatorCategory.error => c.statusDangerForeground1,
      FluentStatusIndicatorCategory.active => c.brandForeground1,
      FluentStatusIndicatorCategory.warning => c.statusWarningForeground1,
    },
  );

  // Geometry, verbatim from the Figma .StatusIndicator set. `height` is the
  // IconHolder box, which is taller than the large size's 22px line so that a
  // 20px glyph still centres against it.
  final (gap, iconSize, height, textStyle) = switch (state.size) {
    FluentStatusIndicatorSize.small => (
      FluentSpacing.xs,
      FluentSize.size120,
      FluentSize.size160,
      theme.typography.caption1,
    ),
    FluentStatusIndicatorSize.medium => (
      FluentSpacing.sNudge,
      FluentSize.size160,
      FluentSize.size200,
      theme.typography.body1,
    ),
    FluentStatusIndicatorSize.large => (
      FluentSpacing.sNudge,
      FluentSize.size200,
      FluentSize.size240,
      theme.typography.body2,
    ),
  };

  return FluentStatusIndicatorStyle(
    iconColor: icon,
    foregroundColor: FluentStateColor.tokens(rest: c.neutralForeground1),
    textStyle: WidgetStatePropertyAll<TextStyle?>(textStyle),
    padding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(EdgeInsets.zero),
    gap: WidgetStatePropertyAll<double?>(gap),
    iconSize: WidgetStatePropertyAll<double?>(iconSize),
    minimumSize: WidgetStatePropertyAll<Size?>(Size(0, height)),
  );
}

/// Renders a status indicator from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentStatusIndicatorBaseState] rather than [FluentStatusIndicatorState] on
/// purpose: it never reads category or size, so a consumer can supply their own
/// style and still use Fluent's layout.
///
/// [states] is accepted for symmetry with the rest of the library and is always
/// empty here — see [FluentStatusIndicatorStyle].
///
/// Nothing animates. The Figma set has no State axis and upstream ships no
/// transition, so a category change lands on the next frame, which also makes
/// this trivially correct under `MediaQuery.disableAnimationsOf`.
Widget buildFluentStatusIndicator(
  FluentStatusIndicatorBaseState state,
  FluentStatusIndicatorStyle style,
  Set<WidgetState> states,
) {
  final iconColor = style.iconColor?.resolve(states);
  final foreground = style.foregroundColor?.resolve(states);
  final textStyle = style.textStyle?.resolve(states);
  final padding = style.padding?.resolve(states) ?? EdgeInsets.zero;
  final gap = style.gap?.resolve(states) ?? FluentSpacing.sNudge;
  final iconSize = style.iconSize?.resolve(states) ?? FluentSize.size160;
  final minimumSize = style.minimumSize?.resolve(states) ?? Size.zero;
  // Figma's IconHolder is exactly the row's line box, never shorter than the
  // glyph it holds.
  final holder = minimumSize.height < iconSize ? iconSize : minimumSize.height;

  // Figma aligns the row to its top and centres the glyph inside its holder,
  // which is only distinguishable in the large size (24 box, 22 line, 20 glyph).
  Widget content = Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: state.label != null ? gap : 0,
    children: <Widget>[
      SizedBox(
        width: iconSize,
        height: holder,
        child: Center(
          child: IconTheme.merge(
            data: IconThemeData(color: iconColor, size: iconSize),
            child: state.icon,
          ),
        ),
      ),
      if (state.label != null) state.label!,
    ],
  );

  if (textStyle != null || foreground != null) {
    content = DefaultTextStyle.merge(
      style: (textStyle ?? const TextStyle()).copyWith(color: foreground),
      child: content,
    );
  }

  return ConstrainedBox(
    constraints: BoxConstraints(
      minHeight: minimumSize.height,
      minWidth: minimumSize.width,
    ),
    child: Padding(padding: padding, child: content),
  );
}

/// Overrides the status indicator style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`.
class FluentStatusIndicatorTheme extends InheritedTheme {
  /// Applies [style] to every `FluentStatusIndicator` in [child].
  const FluentStatusIndicatorTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the category and size defaults.
  final FluentStatusIndicatorStyle style;

  /// The nearest status indicator style, or null.
  static FluentStatusIndicatorStyle? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FluentStatusIndicatorTheme>()
      ?.style;

  @override
  bool updateShouldNotify(FluentStatusIndicatorTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentStatusIndicatorTheme(style: style, child: child);
}

/// A Fluent 2 status indicator: a tinted glyph and a label reporting the state
/// of something.
///
/// ```dart
/// FluentStatusIndicator(
///   message: FluentStatusIndicatorMessage.synced,
///   icon: const Icon(FluentIcons.arrow_sync_16_regular),
///   label: const Text('Synced'),
/// )
/// ```
///
/// Non-interactive by design: it takes no callback, never reports hover, press
/// or focus, and has no disabled rendering — the Figma set has no `State` axis
/// at all, so a disabled treatment would be an invention rather than a port.
/// Wrap it in a button if the status needs to be actionable.
///
/// [message] picks the glyph tint through
/// [FluentStatusIndicatorMessage.category]; pass [category] to override that
/// pairing. The glyph itself is supplied by the caller — Fluent's icon set is
/// not part of this package — and is tinted and sized through [IconTheme], so
/// any [Icon]-shaped widget picks the right values up automatically.
///
/// Customisation follows the usual three rungs. [style] is merged last and
/// wins; [FluentStatusIndicatorTheme] restyles a subtree; and for anything
/// further, [resolveFluentStatusIndicatorState],
/// [resolveFluentStatusIndicatorStyle] and [buildFluentStatusIndicator] are
/// public so any one of them can be replaced without forking this widget.
class FluentStatusIndicator extends StatelessWidget {
  /// Creates a status indicator for [message], drawn with [icon].
  const FluentStatusIndicator({
    super.key,
    required this.message,
    required this.icon,
    this.label,
    this.category,
    this.size = FluentStatusIndicatorSize.medium,
    this.style,
    this.semanticLabel,
  });

  /// The status being reported.
  final FluentStatusIndicatorMessage message;

  /// The glyph. Tinted and sized through [IconTheme].
  final Widget icon;

  /// The label. Null renders the glyph alone, in which case [semanticLabel]
  /// carries the meaning.
  final Widget? label;

  /// Overrides the category [message] would otherwise select.
  final FluentStatusIndicatorCategory? category;

  /// Glyph size and type ramp.
  final FluentStatusIndicatorSize size;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentStatusIndicatorStyle? style;

  /// Announced by assistive technology in place of the subtree's own
  /// semantics.
  ///
  /// Colour is not information: in high contrast every category collapses onto
  /// `canvasText`, so a glyph-only indicator conveys nothing without this.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final state = resolveFluentStatusIndicatorState(
      message: message,
      category: category,
      size: size,
      icon: icon,
      label: label,
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentStatusIndicatorStyle(
      state,
      FluentTheme.of(context),
    ).merge(FluentStatusIndicatorTheme.maybeOf(context)).merge(style);

    final indicator = buildFluentStatusIndicator(
      state,
      resolved,
      const <WidgetState>{},
    );

    if (semanticLabel == null) return indicator;
    return Semantics(
      label: semanticLabel,
      // The component reports a state that changes without the user acting, so
      // upstream gives it `role="status"`. No `liveRegion` here — a node cannot
      // carry both (3.41.0 `semantics.dart:176-177`, `_noLiveRegion`).
      role: SemanticsRole.status,
      // `container` is load-bearing, not tidiness. Without it this annotation
      // is not a semantic boundary, so an ancestor `Semantics(liveRegion: true)`
      // absorbs the role into its own node — `isCompatibleWith` rejects two
      // roles or two values but says nothing about a role meeting a live region
      // (`semantics.dart:6776`) — and the framework then throws
      // "A node can not have SemanticsRole.status and be live region at the same
      // time". `FluentField` wraps its `validationMessage` in exactly such a
      // node (`inputs/field.dart:345-349`), which is where this bit first.
      // `FluentPresenceBadge` already carries `container` for the same reason.
      container: true,
      child: ExcludeSemantics(child: indicator),
    );
  }
}
