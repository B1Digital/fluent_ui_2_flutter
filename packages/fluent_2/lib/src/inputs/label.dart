import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import '../internal/interaction.dart';
import 'label_style.dart';

/// Label type ramp step. Figma's `Size` axis.
enum FluentLabelSize {
  /// 12/16 caption type.
  small,

  /// 14/20 body type. The default.
  medium,

  /// 16/22 subtitle type.
  large,
}

/// Label font weight. Figma's `Type` axis, values verbatim.
enum FluentLabelWeight {
  /// Regular (400). The default.
  regular,

  /// Semibold (600), for the field name above an input.
  semibold,
}

/// Everything needed to resolve a label's style, independent of size and
/// weight.
///
/// The Dart counterpart of upstream's `LabelState` minus its design axes.
/// [buildFluentLabel] takes this rather than [FluentLabelState], which is what
/// makes "Fluent's state, my own styling, Fluent's rendering" a supported path
/// rather than a fork.
@immutable
class FluentLabelBaseState {
  /// Creates a base state.
  const FluentLabelBaseState({
    required this.enabled,
    this.required = false,
    this.label,
  });

  /// Whether the label renders in its enabled colour.
  ///
  /// A label is not interactive, so this is the only interaction state it has —
  /// and it is a real one: [resolveFluentLabelStyle] selects
  /// `neutralForegroundDisabled` for it rather than fading the enabled colour.
  final bool enabled;

  /// Whether the required-field asterisk is rendered after the label.
  final bool required;

  /// The label text, if any.
  final Widget? label;
}

/// A label's fully resolved state, including the design axes.
///
/// The counterpart of upstream's `LabelState`: base state plus exactly `size`
/// and `weight`.
@immutable
class FluentLabelState extends FluentLabelBaseState {
  /// Creates a resolved state.
  const FluentLabelState({
    required super.enabled,
    required this.size,
    required this.weight,
    super.required,
    super.label,
  });

  /// Type ramp step.
  final FluentLabelSize size;

  /// Font weight.
  final FluentLabelWeight weight;
}

/// Builds the state a label will be styled and rendered from.
///
/// Separated so a consumer can reuse Fluent's state resolution while
/// substituting their own styling — the first of the three-function
/// recomposition contract.
FluentLabelState resolveFluentLabelState({
  bool enabled = true,
  FluentLabelSize size = FluentLabelSize.medium,
  FluentLabelWeight weight = FluentLabelWeight.regular,
  bool required = false,
  Widget? label,
}) => FluentLabelState(
  enabled: enabled,
  size: size,
  weight: weight,
  required: required,
  label: label,
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes. Every value comes from a Fluent token; nothing
/// here computes a colour — in particular, disabled is
/// `neutralForegroundDisabled`, never the enabled colour at reduced opacity.
///
/// Token sources are the Figma `Label` component set, extracted into
/// `test/fixtures/label.json` and asserted variant-by-variant in the tests.
FluentLabelStyle resolveFluentLabelStyle(
  FluentLabelState state,
  FluentThemeData theme,
) {
  final c = theme.colors;
  final t = theme.typography;

  // The whole component, really: six ramp steps from two axes. Figma binds
  // Typography/Font size/{200,300,400} against the matching Line height and
  // Weight variable, which is exactly one ramp style each.
  //
  // Large + Regular is the one pair Figma does not ship (the set has 10
  // variants, not 12) — Large exists only as Semibold. `body2` is the 16/22
  // regular step, so the extrapolation is unambiguous, but it IS an
  // extrapolation; the tests say so out loud.
  final textStyle = switch ((state.size, state.weight)) {
    (FluentLabelSize.small, FluentLabelWeight.regular) => t.caption1,
    (FluentLabelSize.small, FluentLabelWeight.semibold) => t.caption1Strong,
    (FluentLabelSize.medium, FluentLabelWeight.regular) => t.body1,
    (FluentLabelSize.medium, FluentLabelWeight.semibold) => t.body1Strong,
    (FluentLabelSize.large, FluentLabelWeight.regular) => t.body2,
    (FluentLabelSize.large, FluentLabelWeight.semibold) => t.subtitle2,
  };

  return FluentLabelStyle(
    foregroundColor: FluentStateColor.tokens(
      rest: c.neutralForeground1,
      disabled: c.neutralForegroundDisabled,
    ),
    // Figma greys the asterisk along with the label; React leaves it red. See
    // doc/token-divergences.md.
    requiredColor: FluentStateColor.tokens(
      rest: c.statusDangerForeground3,
      disabled: c.neutralForegroundDisabled,
    ),
    textStyle: WidgetStatePropertyAll<TextStyle?>(textStyle),
    gap: const WidgetStatePropertyAll<double?>(FluentSpacing.xs),
  );
}

/// Renders a label from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentLabelBaseState] rather than [FluentLabelState] on purpose: it never
/// reads size or weight, so a consumer can supply their own style and still use
/// Fluent's rendering.
///
/// [states] is the interaction set — for a label, `{WidgetState.disabled}` or
/// nothing at all.
///
/// Nothing here animates. Neither Figma nor upstream's `useLabelStyles`
/// declares a transition on Label, so the disabled colour lands on the frame
/// the state changes.
Widget buildFluentLabel(
  FluentLabelBaseState state,
  FluentLabelStyle style,
  Set<WidgetState> states,
) {
  final textStyle = style.textStyle?.resolve(states);
  final foreground = style.foregroundColor?.resolve(states);
  final requiredColor = style.requiredColor?.resolve(states);
  final gap = style.gap?.resolve(states) ?? FluentSpacing.xs;

  final label = state.label;

  Widget content = Row(
    mainAxisSize: MainAxisSize.min,
    // Figma's auto-layout counter-axis alignment is MAX: the asterisk sits on
    // the label's baseline-ish bottom edge, which matters the moment a caller
    // overrides the asterisk to a different size.
    crossAxisAlignment: CrossAxisAlignment.end,
    spacing: label != null && state.required ? gap : 0,
    children: <Widget>[
      ?label,
      if (state.required)
        DefaultTextStyle.merge(
          style: TextStyle(color: requiredColor),
          // Excluded from semantics: "Label*" is not what a screen reader
          // should announce. Required-ness belongs to the field, which marks
          // itself, not to the text of its label.
          child: const ExcludeSemantics(child: Text('*')),
        ),
    ],
  );

  if (textStyle != null || foreground != null) {
    content = DefaultTextStyle.merge(
      style: (textStyle ?? const TextStyle()).copyWith(color: foreground),
      child: content,
    );
  }
  return content;
}

/// Overrides the label style for a subtree.
///
/// The counterpart of Material's `TextTheme` for one component, and the middle
/// rung of the resolution order: theme defaults, then this, then the widget's
/// own `style`.
class FluentLabelTheme extends InheritedTheme {
  /// Applies [style] to every `FluentLabel` in [child].
  const FluentLabelTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the size and weight defaults.
  final FluentLabelStyle style;

  /// The nearest label style, or null.
  static FluentLabelStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentLabelTheme>()?.style;

  @override
  bool updateShouldNotify(FluentLabelTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentLabelTheme(style: style, child: child);
}

/// A Fluent 2 label — the text naming a form field.
///
/// ```dart
/// FluentLabel(
///   weight: FluentLabelWeight.semibold,
///   required: true,
///   child: Text('Email address'),
/// )
/// ```
///
/// Non-interactive, but [disabled] is a real state rather than a visual
/// treatment: the colour is resolved from `neutralForegroundDisabled`, so it
/// stays correct on any background and in high contrast, where fading the
/// enabled colour would not.
///
/// Customisation follows the same three rungs Microsoft documents for the React
/// original. [style] is merged last and wins; [FluentLabelTheme] restyles a
/// subtree; and for anything further, [resolveFluentLabelState],
/// [resolveFluentLabelStyle] and [buildFluentLabel] are public so any one of
/// them can be replaced without forking this widget.
class FluentLabel extends StatelessWidget {
  /// Creates a label for [child].
  const FluentLabel({
    super.key,
    required this.child,
    this.size = FluentLabelSize.medium,
    this.weight = FluentLabelWeight.regular,
    this.required = false,
    this.disabled = false,
    this.style,
  });

  /// The label text.
  final Widget child;

  /// Type ramp step.
  final FluentLabelSize size;

  /// Font weight.
  final FluentLabelWeight weight;

  /// Whether to render the required-field asterisk after [child].
  final bool required;

  /// Whether the label renders in its disabled colour.
  ///
  /// Named after Figma's `Disabled` axis and React's `disabled` prop. The
  /// state objects carry the inverse, `enabled`, matching every other Fluent
  /// component.
  final bool disabled;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentLabelStyle? style;

  @override
  Widget build(BuildContext context) {
    final state = resolveFluentLabelState(
      enabled: !disabled,
      size: size,
      weight: weight,
      required: required,
      label: child,
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentLabelStyle(
      state,
      FluentTheme.of(context),
    ).merge(FluentLabelTheme.maybeOf(context)).merge(style);

    return buildFluentLabel(state, resolved, <WidgetState>{
      if (disabled) WidgetState.disabled,
    });
  }
}
