import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import '../internal/interaction.dart';
import 'divider_style.dart';

/// How strongly a divider reads against its surface.
///
/// The Figma `Divider` set has no `Appearance` variant axis. It expresses this
/// as the four modes of the `Divider appearance` variable collection, bound onto
/// the component's `Stroke color` and `Content color` variables — the same four
/// values React ships as its `appearance` prop.
enum FluentDividerAppearance {
  /// `Neutral/Stroke/2/Rest` over `Neutral/Foreground/2/Rest`. Figma calls this
  /// mode `Default`, which is a Dart reserved word. The default.
  standard,

  /// The faintest rule: `Neutral/Stroke/3/Rest` over
  /// `Neutral/Foreground/3/Rest`.
  subtle,

  /// The heaviest neutral rule: `Neutral/Stroke/1/Rest` over
  /// `Neutral/Foreground/1/Rest`.
  strong,

  /// Brand-coloured rule and label.
  brand,
}

/// Where the label sits along the divider. Figma's `Layout` axis.
enum FluentDividerAlignment {
  /// Label against the leading edge, behind a fixed-length rule. Figma's
  /// `Start`.
  start,

  /// Label centred, both rules equal. The default.
  center,

  /// Label against the trailing edge, ahead of a fixed-length rule. Figma's
  /// `End`.
  end,
}

/// Everything needed to render a divider, independent of appearance and inset.
///
/// The counterpart of `FluentButtonBaseState`. [buildFluentDivider] takes this
/// rather than [FluentDividerState], which is what makes "Fluent's state, my own
/// styling, Fluent's rendering" a supported path rather than a fork.
@immutable
class FluentDividerBaseState {
  /// Creates a base state.
  const FluentDividerBaseState({
    required this.vertical,
    required this.alignment,
    this.icon,
    this.label,
  });

  /// Whether the rule runs top to bottom rather than left to right. Figma's
  /// `Vertical` axis.
  final bool vertical;

  /// Where the label sits along the rule.
  final FluentDividerAlignment alignment;

  /// The icon, if any.
  final Widget? icon;

  /// The label, if any. A divider with neither icon nor label is a single
  /// uninterrupted rule.
  final Widget? label;

  /// Whether anything at all sits between the two rules.
  bool get hasContent => icon != null || label != null;
}

/// A divider's fully resolved state, including the design axes.
///
/// The counterpart of `FluentButtonState`: base state plus exactly `appearance`
/// and `inset`, the two axes Figma models as variable collection modes rather
/// than variant properties.
@immutable
class FluentDividerState extends FluentDividerBaseState {
  /// Creates a resolved state.
  const FluentDividerState({
    required super.vertical,
    required super.alignment,
    required this.appearance,
    required this.inset,
    super.icon,
    super.label,
  });

  /// How strongly the rule and label read.
  final FluentDividerAppearance appearance;

  /// Whether the whole divider is inset from its container. Selects the `Inset`
  /// mode of Figma's `Divider padding` collection over the default `Full`.
  final bool inset;
}

/// Builds the state a divider will be styled and rendered from.
///
/// Separated so a consumer can reuse Fluent's state resolution while
/// substituting their own styling — the first of the three-function
/// recomposition contract.
FluentDividerState resolveFluentDividerState({
  bool vertical = false,
  bool inset = false,
  FluentDividerAlignment alignment = FluentDividerAlignment.center,
  FluentDividerAppearance appearance = FluentDividerAppearance.standard,
  Widget? icon,
  Widget? label,
}) => FluentDividerState(
  vertical: vertical,
  inset: inset,
  alignment: alignment,
  appearance: appearance,
  icon: icon,
  label: label,
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes. Every value comes from a Fluent token; nothing
/// here computes a colour.
///
/// Token sources are the Figma `Divider` component set (node `9000:6131`) plus
/// its two component-scoped variable collections, extracted into
/// `test/fixtures/divider.json` and asserted in the tests.
FluentDividerStyle resolveFluentDividerStyle(
  FluentDividerState state,
  FluentThemeData theme,
) {
  final c = theme.colors;

  // The four modes of Figma's `Divider appearance` collection, each a pair of
  // aliases. Both members of a pair are selected together — never mixed.
  final (line, content) = switch (state.appearance) {
    FluentDividerAppearance.standard => (
      c.neutralStroke2,
      c.neutralForeground2,
    ),
    FluentDividerAppearance.subtle => (c.neutralStroke3, c.neutralForeground3),
    FluentDividerAppearance.strong => (c.neutralStroke1, c.neutralForeground1),
    FluentDividerAppearance.brand => (c.brandStroke1, c.brandForeground1),
  };

  // `Divider padding`: Full is Spacing/*/None, Inset is Spacing/*/M. The axis
  // follows the divider, which is why Figma keeps two variables rather than one.
  final outer = state.inset ? FluentSpacing.m : FluentSpacing.none;

  return FluentDividerStyle(
    lineColor: FluentStateColor.tokens(rest: line),
    lineThickness: const WidgetStatePropertyAll<double?>(FluentStroke.thin),
    shortLineLength: const WidgetStatePropertyAll<double?>(FluentSpacing.s),
    contentColor: FluentStateColor.tokens(rest: content),
    textStyle: WidgetStatePropertyAll<TextStyle?>(theme.typography.caption1),
    padding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      state.vertical
          ? EdgeInsets.symmetric(vertical: outer)
          : EdgeInsets.symmetric(horizontal: outer),
    ),
    contentPadding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      state.vertical
          ? const EdgeInsets.symmetric(vertical: FluentSpacing.m)
          : const EdgeInsets.symmetric(horizontal: FluentSpacing.m),
    ),
    contentMinimumSize: WidgetStatePropertyAll<Size?>(
      state.vertical ? Size.zero : const Size(0, FluentSize.size200),
    ),
    gap: const WidgetStatePropertyAll<double?>(FluentSpacing.sNudge),
    iconSize: const WidgetStatePropertyAll<double?>(FluentSize.size200),
  );
}

/// Renders a divider from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentDividerBaseState] rather than [FluentDividerState] on purpose: it
/// never reads appearance or inset, so a consumer can supply their own style and
/// still use Fluent's rendering.
///
/// [states] exists for symmetry with the interactive components and is always
/// empty in practice — a divider has no interaction states to report. It is
/// still honoured, so a caller passing a state-dependent style gets what they
/// asked for.
Widget buildFluentDivider(
  FluentDividerBaseState state,
  FluentDividerStyle style,
  Set<WidgetState> states,
) {
  final lineColor = style.lineColor?.resolve(states);
  final thickness = style.lineThickness?.resolve(states) ?? FluentStroke.thin;
  final shortLength = style.shortLineLength?.resolve(states) ?? FluentSpacing.s;
  final contentColor = style.contentColor?.resolve(states);
  final textStyle = style.textStyle?.resolve(states);
  final padding = style.padding?.resolve(states) ?? EdgeInsets.zero;
  final contentPadding =
      style.contentPadding?.resolve(states) ?? EdgeInsets.zero;
  final contentMinimum = style.contentMinimumSize?.resolve(states) ?? Size.zero;
  final gap = style.gap?.resolve(states) ?? FluentSpacing.sNudge;
  final iconSize = style.iconSize?.resolve(states) ?? FluentSize.size200;
  final vertical = state.vertical;

  // A hairline that stretches on one axis and is pinned on the other. The
  // colour is only painted when a token was actually resolved: an absent colour
  // must leave the rule unpainted rather than fall back to a literal
  // transparent, which would stay invisible in high contrast where Fluent's
  // transparent tokens turn opaque.
  Widget rule({required bool flexible}) {
    final line = SizedBox(
      width: vertical ? thickness : (flexible ? null : shortLength),
      height: vertical ? (flexible ? null : shortLength) : thickness,
      child: lineColor == null ? null : ColoredBox(color: lineColor),
    );
    return flexible ? Expanded(child: line) : line;
  }

  Widget? content;
  if (state.hasContent) {
    Widget row = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: state.icon != null && state.label != null ? gap : 0,
      children: <Widget>[
        if (state.icon != null)
          IconTheme.merge(
            data: IconThemeData(color: contentColor, size: iconSize),
            child: state.icon!,
          ),
        if (state.label != null) state.label!,
      ],
    );
    if (textStyle != null || contentColor != null) {
      row = DefaultTextStyle.merge(
        style: (textStyle ?? const TextStyle()).copyWith(color: contentColor),
        child: row,
      );
    }
    content = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: contentMinimum.width,
        minHeight: contentMinimum.height,
      ),
      child: Padding(padding: contentPadding, child: row),
    );
  }

  // With no label there is nothing to align around, so the single rule spans the
  // whole divider whatever `alignment` says.
  final children = content == null
      ? <Widget>[rule(flexible: true)]
      : <Widget>[
          rule(flexible: state.alignment != FluentDividerAlignment.start),
          content,
          rule(flexible: state.alignment != FluentDividerAlignment.end),
        ];

  return Padding(
    padding: padding,
    child: vertical
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: children,
          )
        : Row(mainAxisAlignment: MainAxisAlignment.center, children: children),
  );
}

/// Overrides the divider style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`.
class FluentDividerTheme extends InheritedTheme {
  /// Applies [style] to every `FluentDivider` in [child].
  const FluentDividerTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the appearance and inset defaults.
  final FluentDividerStyle style;

  /// The nearest divider style, or null.
  static FluentDividerStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentDividerTheme>()?.style;

  @override
  bool updateShouldNotify(FluentDividerTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentDividerTheme(style: style, child: child);
}

/// A Fluent 2 divider: a hairline rule, optionally interrupted by a label.
///
/// ```dart
/// const FluentDivider(child: Text('Recent'))
/// ```
///
/// Non-interactive by design. There is no hover, no press, no focus ring, no
/// `onPressed` and — the part most often "improved" by mistake — no transition:
/// a change of [appearance] lands on the next frame. Upstream declares none, so
/// neither does this, which also makes it trivially correct under reduced
/// motion.
///
/// A horizontal divider stretches across the width it is given and hugs its
/// height; a vertical one does the reverse, so it needs a parent that bounds its
/// height (a `Row`, an `IntrinsicHeight`, a `SizedBox`).
///
/// Customisation follows the same three rungs as every other component. [style]
/// is merged last and wins; [FluentDividerTheme] restyles a subtree; and for
/// anything further, [resolveFluentDividerState], [resolveFluentDividerStyle]
/// and [buildFluentDivider] are public so any one of them can be replaced
/// without forking this widget.
class FluentDivider extends StatelessWidget {
  /// Creates a divider with an optional [icon] and [child] label.
  const FluentDivider({
    super.key,
    this.child,
    this.icon,
    this.appearance = FluentDividerAppearance.standard,
    this.alignment = FluentDividerAlignment.center,
    this.vertical = false,
    this.inset = false,
    this.style,
  });

  /// The label sitting between the two rules. Null for a plain rule.
  final Widget? child;

  /// Optional icon, placed before the label in reading order.
  final Widget? icon;

  /// How strongly the rule and label read.
  final FluentDividerAppearance appearance;

  /// Where the label sits along the rule. Ignored when there is no label.
  final FluentDividerAlignment alignment;

  /// Whether the rule runs top to bottom rather than left to right.
  final bool vertical;

  /// Whether the whole divider is inset from its container.
  final bool inset;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentDividerStyle? style;

  @override
  Widget build(BuildContext context) {
    final state = resolveFluentDividerState(
      vertical: vertical,
      inset: inset,
      alignment: alignment,
      appearance: appearance,
      icon: icon,
      label: child,
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentDividerStyle(
      state,
      FluentTheme.of(context),
    ).merge(FluentDividerTheme.maybeOf(context)).merge(style);

    return buildFluentDivider(state, resolved, const <WidgetState>{});
  }
}
