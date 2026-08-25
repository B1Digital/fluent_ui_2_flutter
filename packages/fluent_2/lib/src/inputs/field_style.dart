import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentField`.
///
/// The same shape as `FluentButtonStyle`: every visual property is a
/// [WidgetStateProperty], so the disabled value lives on the property rather
/// than being branched on at build time. A field is not interactive — the
/// control it wraps is — so the only state it ever resolves against is
/// [WidgetState.disabled]. It resolves it the same way every other Fluent
/// component does, which is what keeps `disabled` a real state instead of a
/// visual treatment.
///
/// The label's own type ramp is deliberately **not** here. `FluentField`
/// composes a real `FluentLabel`, which resolves its own style from the theme,
/// so the middle rung for the label is `FluentLabelTheme` rather than this
/// class. Restyling the label through the field would mean two places to look
/// when a label goes wrong.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the size and validation-state defaults derived from the theme
/// 2. the nearest `FluentFieldTheme`
/// 3. the widget's own `style`
///
/// The consumer's own style therefore wins, matching upstream's rule that
/// `props.className` is passed last to `mergeClasses`.
@immutable
class FluentFieldStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentFieldStyle({
    this.labelPadding,
    this.secondaryTextPadding,
    this.secondaryTextStyle,
    this.hintColor,
    this.validationMessageColor,
    this.validationMessageIconColor,
    this.validationMessageIconPadding,
    this.validationMessageIconSize,
    this.gap,
  });

  /// Inset around the label row.
  ///
  /// Figma binds only `paddingBottom` on the `Label + Icon` frame — 2 at small
  /// and medium, 4 at large — so the default carries a bottom edge and nothing
  /// else. React additionally pads the label 2 above and below (1 at large);
  /// see `doc/token-divergences.md`.
  final WidgetStateProperty<EdgeInsetsGeometry?>? labelPadding;

  /// Inset around the hint row and the validation-message row.
  ///
  /// One property for both, because upstream gives them one class:
  /// `useSecondaryTextBaseClassName` sets `marginTop: spacingVerticalXXS` for
  /// the hint and the validation message alike, and Figma's `Helper text` and
  /// `Status text` frames both bind `Spacing/Vertical/XXS` on `paddingTop`.
  final WidgetStateProperty<EdgeInsetsGeometry?>? secondaryTextPadding;

  /// The type ramp of the hint and the validation message.
  ///
  /// Shared for the same reason as [secondaryTextPadding], and size-invariant:
  /// all three Figma variants draw both rows at 12/16 regardless of the field's
  /// own size. Its colour is overridden per row by [hintColor] and
  /// [validationMessageColor].
  final WidgetStateProperty<TextStyle?>? secondaryTextStyle;

  /// Hint text colour.
  final WidgetStateProperty<Color?>? hintColor;

  /// Validation message text colour.
  ///
  /// A separate property from [validationMessageIconColor] on purpose: upstream
  /// recolours the message text only in the `error` state, while the glyph
  /// takes a tint in all three. Folding them into one would silently turn a
  /// warning's message amber.
  final WidgetStateProperty<Color?>? validationMessageColor;

  /// Validation message glyph colour.
  final WidgetStateProperty<Color?>? validationMessageIconColor;

  /// Inset above the validation message glyph.
  ///
  /// The optical nudge that drops a 12px glyph onto the 16px line box of the
  /// message beside it — Figma's `Icon` frame binds `Spacing/Vertical/XXS` on
  /// `paddingTop`, upstream writes `verticalAlign: -1px`. Kept adjustable
  /// because a caller who swaps in a differently-sized glyph needs to retune it.
  final WidgetStateProperty<EdgeInsetsGeometry?>? validationMessageIconPadding;

  /// Validation message glyph edge length.
  final WidgetStateProperty<double?>? validationMessageIconSize;

  /// Space between the validation message glyph and its text.
  final WidgetStateProperty<double?>? gap;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only [gap] keeps every
  /// resolved colour. This is what makes a partial override useful.
  FluentFieldStyle merge(FluentFieldStyle? other) {
    if (other == null) return this;
    return FluentFieldStyle(
      labelPadding: other.labelPadding ?? labelPadding,
      secondaryTextPadding: other.secondaryTextPadding ?? secondaryTextPadding,
      secondaryTextStyle: other.secondaryTextStyle ?? secondaryTextStyle,
      hintColor: other.hintColor ?? hintColor,
      validationMessageColor:
          other.validationMessageColor ?? validationMessageColor,
      validationMessageIconColor:
          other.validationMessageIconColor ?? validationMessageIconColor,
      validationMessageIconPadding:
          other.validationMessageIconPadding ?? validationMessageIconPadding,
      validationMessageIconSize:
          other.validationMessageIconSize ?? validationMessageIconSize,
      gap: other.gap ?? gap,
    );
  }

  /// This style with the given properties replaced.
  FluentFieldStyle copyWith({
    WidgetStateProperty<EdgeInsetsGeometry?>? labelPadding,
    WidgetStateProperty<EdgeInsetsGeometry?>? secondaryTextPadding,
    WidgetStateProperty<TextStyle?>? secondaryTextStyle,
    WidgetStateProperty<Color?>? hintColor,
    WidgetStateProperty<Color?>? validationMessageColor,
    WidgetStateProperty<Color?>? validationMessageIconColor,
    WidgetStateProperty<EdgeInsetsGeometry?>? validationMessageIconPadding,
    WidgetStateProperty<double?>? validationMessageIconSize,
    WidgetStateProperty<double?>? gap,
  }) => FluentFieldStyle(
    labelPadding: labelPadding ?? this.labelPadding,
    secondaryTextPadding: secondaryTextPadding ?? this.secondaryTextPadding,
    secondaryTextStyle: secondaryTextStyle ?? this.secondaryTextStyle,
    hintColor: hintColor ?? this.hintColor,
    validationMessageColor:
        validationMessageColor ?? this.validationMessageColor,
    validationMessageIconColor:
        validationMessageIconColor ?? this.validationMessageIconColor,
    validationMessageIconPadding:
        validationMessageIconPadding ?? this.validationMessageIconPadding,
    validationMessageIconSize:
        validationMessageIconSize ?? this.validationMessageIconSize,
    gap: gap ?? this.gap,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`. Use the constructor directly
  /// when a property genuinely differs per state.
  static FluentFieldStyle from({
    EdgeInsetsGeometry? labelPadding,
    EdgeInsetsGeometry? secondaryTextPadding,
    TextStyle? secondaryTextStyle,
    Color? hintColor,
    Color? validationMessageColor,
    Color? validationMessageIconColor,
    EdgeInsetsGeometry? validationMessageIconPadding,
    double? validationMessageIconSize,
    double? gap,
  }) => FluentFieldStyle(
    labelPadding: _all(labelPadding),
    secondaryTextPadding: _all(secondaryTextPadding),
    secondaryTextStyle: _all(secondaryTextStyle),
    hintColor: _all(hintColor),
    validationMessageColor: _all(validationMessageColor),
    validationMessageIconColor: _all(validationMessageIconColor),
    validationMessageIconPadding: _all(validationMessageIconPadding),
    validationMessageIconSize: _all(validationMessageIconSize),
    gap: _all(gap),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentFieldStyle &&
      other.labelPadding == labelPadding &&
      other.secondaryTextPadding == secondaryTextPadding &&
      other.secondaryTextStyle == secondaryTextStyle &&
      other.hintColor == hintColor &&
      other.validationMessageColor == validationMessageColor &&
      other.validationMessageIconColor == validationMessageIconColor &&
      other.validationMessageIconPadding == validationMessageIconPadding &&
      other.validationMessageIconSize == validationMessageIconSize &&
      other.gap == gap;

  @override
  int get hashCode => Object.hash(
    labelPadding,
    secondaryTextPadding,
    secondaryTextStyle,
    hintColor,
    validationMessageColor,
    validationMessageIconColor,
    validationMessageIconPadding,
    validationMessageIconSize,
    gap,
  );
}
