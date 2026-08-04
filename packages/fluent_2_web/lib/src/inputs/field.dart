import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import '../internal/interaction.dart';
import 'field_style.dart';
import 'label.dart';

/// Label ramp and label-to-control gap. Figma's `Size` axis, and the only axis
/// the `Field` component set has.
enum FluentFieldSize {
  /// 12/16 label over a 2px gap.
  small,

  /// 14/20 label over a 2px gap. The default.
  medium,

  /// 16/22 **semibold** label over a 4px gap.
  large,
}

/// What the field is reporting about the value of the control it wraps.
///
/// **Upstream-only as an axis.** The Figma `Field` set has no validation
/// property: all three variants draw one error message, bound to
/// `Status/Danger/Foreground/1/Rest`. [error] is therefore design-verified and
/// [warning] and [success] are transcribed from
/// `useFieldStyles.styles.ts`, mapped onto this port's status alias layer.
enum FluentFieldValidationState {
  /// No condition is being reported. The validation message, if any, reads as
  /// a second hint. The default.
  none,

  /// The value is invalid. The only state Figma draws.
  error,

  /// The value is accepted but questionable.
  warning,

  /// The value has been confirmed good.
  success,
}

/// Everything needed to render a field, independent of size and validation
/// state.
///
/// The Dart counterpart of upstream's `FieldState` minus its design axes.
/// [buildFluentField] takes this rather than [FluentFieldState], which is what
/// makes "Fluent's state, my own styling, Fluent's rendering" a supported path
/// rather than a fork.
///
/// [label] is a **finished widget**, not a string: by the time
/// [resolveFluentFieldState] has run it is already a [FluentLabel] carrying the
/// size, weight, required-asterisk and disabled treatment the field's own size
/// implies. A consumer building this state by hand can put any widget there.
@immutable
class FluentFieldBaseState {
  /// Creates a base state.
  const FluentFieldBaseState({
    required this.enabled,
    this.label,
    this.hint,
    this.validationMessage,
    this.validationMessageIcon,
    this.child,
  });

  /// Whether the field renders in its enabled colours.
  ///
  /// A field is not interactive — the control inside it is — so this is the
  /// only interaction state it has, and it is a real one:
  /// [resolveFluentFieldStyle] selects `neutralForegroundDisabled` for it
  /// rather than fading the enabled colours.
  final bool enabled;

  /// The label above the control, if any.
  final Widget? label;

  /// The hint below the control, if any. Upstream's `hint` slot; Figma's
  /// `Helper text` row.
  final Widget? hint;

  /// The validation message below the control, if any.
  final Widget? validationMessage;

  /// The glyph beside [validationMessage], if any.
  ///
  /// Supplied by the caller — Fluent's icon set is not part of this package,
  /// the same call `FluentStatusIndicator` makes — and tinted and sized through
  /// [IconTheme], so any [Icon]-shaped widget picks the right values up
  /// automatically. Upstream defaults it to `ErrorCircle12Filled`,
  /// `Warning12Filled` and `CheckmarkCircle12Filled` per validation state.
  final Widget? validationMessageIcon;

  /// The control being wrapped. Any widget: the field never inspects it.
  final Widget? child;
}

/// A field's fully resolved state, including the design axes.
///
/// The counterpart of upstream's `FieldState`: base state plus exactly `size`
/// and `validationState`.
@immutable
class FluentFieldState extends FluentFieldBaseState {
  /// Creates a resolved state.
  const FluentFieldState({
    required super.enabled,
    required this.size,
    required this.validationState,
    super.label,
    super.hint,
    super.validationMessage,
    super.validationMessageIcon,
    super.child,
  });

  /// Label ramp and label-to-control gap.
  final FluentFieldSize size;

  /// What the field is reporting.
  final FluentFieldValidationState validationState;
}

/// Builds the state a field will be styled and rendered from.
///
/// The first of the three-function recomposition contract, and the only place
/// the label is composed: `label` goes in as its own content and comes out
/// wrapped in a [FluentLabel] whose size and weight are read off [size].
///
/// The weight is not a free choice. Figma's `Size=Large` variant draws its
/// label 16/22 **semibold**, and upstream's `useLabelStyles` gives `large` the
/// same `typographyStyles.subtitle2`. `FluentLabel` reaches that ramp step
/// only as `large` + `semibold` — `large` + `regular` is `body2`, the 16/22
/// regular step Figma's Label set does not ship at all.
FluentFieldState resolveFluentFieldState({
  bool enabled = true,
  FluentFieldSize size = FluentFieldSize.medium,
  FluentFieldValidationState validationState = FluentFieldValidationState.none,
  bool required = false,
  Widget? label,
  Widget? hint,
  Widget? validationMessage,
  Widget? validationMessageIcon,
  Widget? child,
}) {
  final (labelSize, labelWeight) = switch (size) {
    FluentFieldSize.small => (FluentLabelSize.small, FluentLabelWeight.regular),
    FluentFieldSize.medium => (
      FluentLabelSize.medium,
      FluentLabelWeight.regular,
    ),
    FluentFieldSize.large => (
      FluentLabelSize.large,
      FluentLabelWeight.semibold,
    ),
  };

  return FluentFieldState(
    enabled: enabled,
    size: size,
    validationState: validationState,
    label: label == null
        ? null
        : FluentLabel(
            size: labelSize,
            weight: labelWeight,
            required: required,
            disabled: !enabled,
            child: label,
          ),
    hint: hint,
    validationMessage: validationMessage,
    validationMessageIcon: validationMessageIcon,
    child: child,
  );
}

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes. Every value comes from a Fluent token; nothing
/// here computes a colour.
///
/// Token sources are the Figma `Field` component set, extracted into
/// `test/fixtures/field.json` and asserted variant-by-variant in the tests.
/// Two readings deserve to be stated out loud, because both look like bugs to
/// anyone diffing against `useFieldStyles.styles.ts`:
///
/// * **Only `error` recolours the message text.** Upstream applies
///   `secondaryTextStyles.error` when `validationState === 'error'` and nothing
///   at all for `warning` and `success`, whose messages stay
///   `colorNeutralForeground3`. The *glyph* takes a tint in all three. That
///   asymmetry is reproduced verbatim below.
/// * **Status, not palette.** Upstream names `colorPaletteRedForeground1`,
///   `colorPaletteDarkOrangeForeground1` and `colorPaletteGreenForeground1`.
///   Figma binds the error text to `Status/Danger/Foreground/1/Rest`, whose
///   light value `#B10E1C` is exactly this port's `statusDangerForeground1`, so
///   the status alias family is what the whole table selects. Only the alias
///   layer is reached by `FluentThemeOverride` and replaced by the
///   high-contrast palette.
FluentFieldStyle resolveFluentFieldStyle(
  FluentFieldState state,
  FluentThemeData theme,
) {
  final c = theme.colors;

  // Disabled is a separate ramp on every row rather than a treatment applied
  // over the enabled one. Neither Figma nor upstream states it — Figma's set
  // has no Disabled axis and React's Field has no `disabled` prop — so this is
  // the same call `FluentRadio` makes for its label: `neutralForegroundDisabled`
  // is what every other component in this port greys down to.
  final hint = FluentStateColor.tokens(
    rest: c.neutralForeground3,
    disabled: c.neutralForegroundDisabled,
  );

  final message = FluentStateColor.tokens(
    rest: state.validationState == FluentFieldValidationState.error
        ? c.statusDangerForeground1
        : c.neutralForeground3,
    disabled: c.neutralForegroundDisabled,
  );

  final icon = FluentStateColor.tokens(
    rest: switch (state.validationState) {
      FluentFieldValidationState.none => c.neutralForeground3,
      FluentFieldValidationState.error => c.statusDangerForeground1,
      FluentFieldValidationState.warning => c.statusWarningForeground1,
      FluentFieldValidationState.success => c.statusSuccessForeground1,
    },
    disabled: c.neutralForegroundDisabled,
  );

  // The gap under the label, verbatim from the `Label + Icon` frame's
  // paddingBottom. Small leaves it unbound at 2, medium binds
  // `Spacing/Horizontal/XXS` (an axis slip in the file — the value is 2 either
  // way) and large binds `Spacing/Vertical/XS`.
  final labelGap = switch (state.size) {
    FluentFieldSize.small || FluentFieldSize.medium => FluentSpacing.xxs,
    FluentFieldSize.large => FluentSpacing.xs,
  };

  return FluentFieldStyle(
    hintColor: hint,
    validationMessageColor: message,
    validationMessageIconColor: icon,
    labelPadding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.only(bottom: labelGap),
    ),
    secondaryTextPadding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.only(top: FluentSpacing.xxs),
    ),
    // Size-invariant: all three variants draw the hint and the validation
    // message at 12/16, which is `caption1`. The Size axis moves the label
    // ramp and the label gap, nothing else.
    secondaryTextStyle: WidgetStatePropertyAll<TextStyle?>(
      theme.typography.caption1,
    ),
    validationMessageIconPadding:
        const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
          EdgeInsets.only(top: FluentSpacing.xxs),
        ),
    validationMessageIconSize: const WidgetStatePropertyAll<double?>(
      FluentSize.size120,
    ),
    gap: const WidgetStatePropertyAll<double?>(FluentSpacing.xs),
  );
}

/// Renders a field from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentFieldBaseState] rather than [FluentFieldState] on purpose: it never
/// reads size or validation state, so a consumer can supply their own style and
/// still use Fluent's layout.
///
/// [states] is the interaction set — for a field, `{WidgetState.disabled}` or
/// nothing at all.
///
/// **Nothing animates, deliberately.** `useFieldStyles.styles.ts` contains no
/// `transition`, no `animation` and no `motionTokens` reference of any kind, so
/// a validation message appears, disappears and recolours on the frame the
/// state changes. This is the Checkbox and Tag category, not an omission — and
/// it makes the component trivially correct under
/// `MediaQuery.disableAnimationsOf`, because there is nothing to shorten.
///
/// The children are stretched to the field's own width, which is what upstream's
/// `display: grid` root does. A field therefore needs a bounded width, exactly
/// as a block-level `<div>` does.
Widget buildFluentField(
  FluentFieldBaseState state,
  FluentFieldStyle style,
  Set<WidgetState> states,
) {
  final labelPadding = style.labelPadding?.resolve(states) ?? EdgeInsets.zero;
  final secondaryPadding =
      style.secondaryTextPadding?.resolve(states) ?? EdgeInsets.zero;
  final secondaryStyle = style.secondaryTextStyle?.resolve(states);
  final hintColor = style.hintColor?.resolve(states);
  final messageColor = style.validationMessageColor?.resolve(states);
  final iconColor = style.validationMessageIconColor?.resolve(states);
  final iconPadding =
      style.validationMessageIconPadding?.resolve(states) ?? EdgeInsets.zero;
  final iconSize =
      style.validationMessageIconSize?.resolve(states) ?? FluentSize.size120;
  final gap = style.gap?.resolve(states) ?? FluentSpacing.xs;

  Widget secondary(Widget content, Color? color) => DefaultTextStyle.merge(
    style: (secondaryStyle ?? const TextStyle()).copyWith(color: color),
    child: Padding(padding: secondaryPadding, child: content),
  );

  Widget? validation;
  final validationMessage = state.validationMessage;
  if (validationMessage != null) {
    final icon = state.validationMessageIcon;
    validation = secondary(
      icon == null
          ? validationMessage
          : Row(
              // Start, not centre: the glyph belongs beside the FIRST line of a
              // message that wraps, and `iconPadding` already places it against
              // that line's box.
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: gap,
              children: <Widget>[
                Padding(
                  padding: iconPadding,
                  child: IconTheme.merge(
                    data: IconThemeData(color: iconColor, size: iconSize),
                    child: icon,
                  ),
                ),
                // Flexible so a long message wraps inside the row rather than
                // overflowing it.
                Flexible(child: validationMessage),
              ],
            ),
      messageColor,
    );
    // The closest thing Flutter has to upstream's `role="alert"`: a message
    // that appears after the fact is announced, rather than sitting silently
    // under a control the user has already left. `container` is what keeps it
    // a node of its own — without it the flag would merge upwards and turn the
    // entire field into a live region.
    validation = Semantics(
      container: true,
      liveRegion: true,
      child: validation,
    );
  }

  // Figma's order, and upstream's render order: label, control, validation
  // message, hint.
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      if (state.label != null)
        Padding(padding: labelPadding, child: state.label),
      ?state.child,
      ?validation,
      if (state.hint != null) secondary(state.hint!, hintColor),
    ],
  );
}

/// Overrides the field style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`.
class FluentFieldTheme extends InheritedTheme {
  /// Applies [style] to every `FluentField` in [child].
  const FluentFieldTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the size and validation-state defaults.
  final FluentFieldStyle style;

  /// The nearest field style, or null.
  static FluentFieldStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentFieldTheme>()?.style;

  @override
  bool updateShouldNotify(FluentFieldTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentFieldTheme(style: style, child: child);
}

/// A Fluent 2 field: the label, hint and validation message around a control.
///
/// ```dart
/// FluentField(
///   label: const Text('Email address'),
///   required: true,
///   validationState: FluentFieldValidationState.error,
///   validationMessage: const Text('That address is already registered'),
///   validationMessageIcon: const Icon(FluentIcons.error_circle_12_filled),
///   child: myTextInput,
/// )
/// ```
///
/// A pure wrapper: [child] is any widget and the field never inspects it, so
/// this composes with a text input, a slider, a radio group or a control that
/// does not exist yet. It is block-level — the children are stretched to the
/// field's own width, matching upstream's `display: grid` root — so give it a
/// bounded width.
///
/// [validationState] tints the message and its glyph; it does **not** touch the
/// control. Wiring a red border onto an invalid input is the input's own job,
/// which is exactly how upstream splits it.
///
/// [enabled] is a real state rather than a visual treatment: every colour is
/// resolved from `neutralForegroundDisabled` rather than faded, so it stays
/// correct on any background and in high contrast, and the label greys through
/// [FluentLabel]'s own disabled token. It does not disable [child] — a wrapper
/// that reached into an arbitrary widget to switch it off would be guessing.
///
/// **Nothing animates.** See [buildFluentField].
///
/// Customisation follows the usual three rungs. [style] is merged last and
/// wins; [FluentFieldTheme] restyles a subtree; and for anything further,
/// [resolveFluentFieldState], [resolveFluentFieldStyle] and [buildFluentField]
/// are public so any one of them can be replaced without forking this widget.
/// The label is the one exception: it is a real [FluentLabel], so
/// [FluentLabelTheme] is what restyles it.
class FluentField extends StatelessWidget {
  /// Creates a field around [child].
  const FluentField({
    super.key,
    this.child,
    this.label,
    this.hint,
    this.validationMessage,
    this.validationMessageIcon,
    this.validationState = FluentFieldValidationState.none,
    this.size = FluentFieldSize.medium,
    this.required = false,
    this.enabled = true,
    this.style,
  });

  /// The control being wrapped.
  final Widget? child;

  /// The label content. Wrapped in a [FluentLabel] sized from [size].
  final Widget? label;

  /// The hint below the control. Upstream's `hint` slot.
  final Widget? hint;

  /// The validation message below the control.
  final Widget? validationMessage;

  /// The glyph beside [validationMessage]. Tinted and sized through
  /// [IconTheme]; see [FluentFieldBaseState.validationMessageIcon].
  final Widget? validationMessageIcon;

  /// What the field is reporting about [child]'s value.
  final FluentFieldValidationState validationState;

  /// Label ramp and label-to-control gap.
  final FluentFieldSize size;

  /// Whether to render the required-field asterisk after [label].
  ///
  /// Also marks the field itself required in the semantics tree, which is where
  /// the meaning belongs: [FluentLabel] excludes its asterisk from semantics on
  /// purpose, because "Label*" is not what a screen reader should announce.
  final bool required;

  /// Whether the field renders in its enabled colours.
  final bool enabled;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentFieldStyle? style;

  @override
  Widget build(BuildContext context) {
    final state = resolveFluentFieldState(
      enabled: enabled,
      size: size,
      validationState: validationState,
      required: required,
      label: label,
      hint: hint,
      validationMessage: validationMessage,
      validationMessageIcon: validationMessageIcon,
      child: child,
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentFieldStyle(
      state,
      FluentTheme.of(context),
    ).merge(FluentFieldTheme.maybeOf(context)).merge(style);

    return Semantics(
      // One node, so assistive technology reads the label, the control and the
      // message as one field rather than three unrelated fragments — the port
      // of upstream's `aria-describedby` wiring. Deliberately `container` and
      // not `MergeSemantics`: flattening a text input into its label would
      // destroy the editing semantics the input publishes.
      container: true,
      enabled: enabled,
      // Required-ness belongs to the field, not to the text of its label —
      // which is exactly why `FluentLabel` excludes its asterisk from
      // semantics.
      isRequired: required,
      child: buildFluentField(state, resolved, <WidgetState>{
        if (!enabled) WidgetState.disabled,
      }),
    );
  }
}
