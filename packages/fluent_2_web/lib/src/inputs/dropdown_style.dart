import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentDropdown` — trigger *and* popup.
///
/// Shaped like `FluentButtonStyle`: every visual property is a
/// [WidgetStateProperty], so hover, pressed and disabled values live on the
/// property rather than being branched on at build time.
///
/// The popup surface is styled from the same struct rather than a second one.
/// Upstream does the same — `useDropdownStyles.styles.ts` and
/// `useListboxStyles.styles.ts` are two files but one component contract — and a
/// caller restyling a dropdown almost always wants both halves to move together.
/// Popup fields are prefixed `surface`.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the appearance/size defaults derived from the theme
/// 2. the nearest `FluentDropdownTheme`
/// 3. the widget's own `style`
@immutable
class FluentDropdownStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentDropdownStyle({
    this.backgroundColor,
    this.foregroundColor,
    this.placeholderColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.underlineColor,
    this.accentColor,
    this.accentWidth,
    this.textStyle,
    this.padding,
    this.gap,
    this.chevronColor,
    this.chevronSize,
    this.chevronPadding,
    this.minimumSize,
    this.mouseCursor,
    this.surfaceColor,
    this.surfaceBorderColor,
    this.surfaceBorderWidth,
    this.surfaceRadius,
    this.surfacePadding,
    this.surfaceGap,
    this.surfaceShadow,
    this.surfaceMaxHeight,
    this.surfaceOffset,
  });

  /// Trigger fill.
  final WidgetStateProperty<Color?>? backgroundColor;

  /// Colour of the selected value's text.
  final WidgetStateProperty<Color?>? foregroundColor;

  /// Colour of the placeholder, shown while nothing is selected. A separate
  /// ramp, not a dimmed [foregroundColor]: Figma binds the trigger's text to
  /// `Neutral/Foreground/4/Rest` and upstream's `.placeholder` rule agrees.
  final WidgetStateProperty<Color?>? placeholderColor;

  /// Trigger border colour. Null and transparent are different: Fluent's
  /// `transparentStroke` becomes opaque in high contrast.
  final WidgetStateProperty<Color?>? borderColor;

  /// Trigger border width.
  final WidgetStateProperty<double?>? borderWidth;

  /// Trigger corner radius.
  final WidgetStateProperty<BorderRadius?>? borderRadius;

  /// The 1px rule along the bottom edge at rest.
  ///
  /// Null means the appearance draws none, which is a different claim from a
  /// transparent one — `Fill lighter` and `Fill darker` genuinely have no rule.
  final WidgetStateProperty<Color?>? underlineColor;

  /// The brand rule that grows across the bottom edge while the dropdown is
  /// focused or open. Upstream's `::after`, Figma's `InFocus` rectangle.
  final WidgetStateProperty<Color?>? accentColor;

  /// Height of the accent rule. `FluentStroke.thick` (2) per Figma and React.
  final WidgetStateProperty<double?>? accentWidth;

  /// Value and placeholder text style. Its colour is overridden by
  /// [foregroundColor] / [placeholderColor].
  final WidgetStateProperty<TextStyle?>? textStyle;

  /// Horizontal inset of the value text inside the trigger.
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;

  /// Space between the value text and the chevron slot.
  final WidgetStateProperty<double?>? gap;

  /// Chevron tone.
  final WidgetStateProperty<Color?>? chevronColor;

  /// Chevron edge length.
  final WidgetStateProperty<double?>? chevronSize;

  /// Inset around the chevron inside its slot.
  final WidgetStateProperty<EdgeInsetsGeometry?>? chevronPadding;

  /// Minimum trigger size. Only the height is meaningful; a dropdown takes its
  /// width from its parent.
  final WidgetStateProperty<Size?>? minimumSize;

  /// Cursor while hovering the trigger.
  final WidgetStateProperty<MouseCursor?>? mouseCursor;

  /// Popup fill.
  final WidgetStateProperty<Color?>? surfaceColor;

  /// Popup border colour.
  final WidgetStateProperty<Color?>? surfaceBorderColor;

  /// Popup border width.
  final WidgetStateProperty<double?>? surfaceBorderWidth;

  /// Popup corner radius.
  final WidgetStateProperty<BorderRadius?>? surfaceRadius;

  /// Inset between the popup edge and its options.
  final WidgetStateProperty<EdgeInsetsGeometry?>? surfacePadding;

  /// Space between two options.
  final WidgetStateProperty<double?>? surfaceGap;

  /// Popup elevation.
  final WidgetStateProperty<List<BoxShadow>?>? surfaceShadow;

  /// Tallest the popup grows before its options scroll.
  final WidgetStateProperty<double?>? surfaceMaxHeight;

  /// Vertical distance between the trigger's bottom edge and the popup.
  final WidgetStateProperty<double?>? surfaceOffset;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only `surfaceRadius`
  /// keeps every resolved colour.
  FluentDropdownStyle merge(FluentDropdownStyle? other) {
    if (other == null) return this;
    return FluentDropdownStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      placeholderColor: other.placeholderColor ?? placeholderColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      underlineColor: other.underlineColor ?? underlineColor,
      accentColor: other.accentColor ?? accentColor,
      accentWidth: other.accentWidth ?? accentWidth,
      textStyle: other.textStyle ?? textStyle,
      padding: other.padding ?? padding,
      gap: other.gap ?? gap,
      chevronColor: other.chevronColor ?? chevronColor,
      chevronSize: other.chevronSize ?? chevronSize,
      chevronPadding: other.chevronPadding ?? chevronPadding,
      minimumSize: other.minimumSize ?? minimumSize,
      mouseCursor: other.mouseCursor ?? mouseCursor,
      surfaceColor: other.surfaceColor ?? surfaceColor,
      surfaceBorderColor: other.surfaceBorderColor ?? surfaceBorderColor,
      surfaceBorderWidth: other.surfaceBorderWidth ?? surfaceBorderWidth,
      surfaceRadius: other.surfaceRadius ?? surfaceRadius,
      surfacePadding: other.surfacePadding ?? surfacePadding,
      surfaceGap: other.surfaceGap ?? surfaceGap,
      surfaceShadow: other.surfaceShadow ?? surfaceShadow,
      surfaceMaxHeight: other.surfaceMaxHeight ?? surfaceMaxHeight,
      surfaceOffset: other.surfaceOffset ?? surfaceOffset,
    );
  }

  /// This style with the given properties replaced.
  FluentDropdownStyle copyWith({
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? foregroundColor,
    WidgetStateProperty<Color?>? placeholderColor,
    WidgetStateProperty<Color?>? borderColor,
    WidgetStateProperty<double?>? borderWidth,
    WidgetStateProperty<BorderRadius?>? borderRadius,
    WidgetStateProperty<Color?>? underlineColor,
    WidgetStateProperty<Color?>? accentColor,
    WidgetStateProperty<double?>? accentWidth,
    WidgetStateProperty<TextStyle?>? textStyle,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<double?>? gap,
    WidgetStateProperty<Color?>? chevronColor,
    WidgetStateProperty<double?>? chevronSize,
    WidgetStateProperty<EdgeInsetsGeometry?>? chevronPadding,
    WidgetStateProperty<Size?>? minimumSize,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
    WidgetStateProperty<Color?>? surfaceColor,
    WidgetStateProperty<Color?>? surfaceBorderColor,
    WidgetStateProperty<double?>? surfaceBorderWidth,
    WidgetStateProperty<BorderRadius?>? surfaceRadius,
    WidgetStateProperty<EdgeInsetsGeometry?>? surfacePadding,
    WidgetStateProperty<double?>? surfaceGap,
    WidgetStateProperty<List<BoxShadow>?>? surfaceShadow,
    WidgetStateProperty<double?>? surfaceMaxHeight,
    WidgetStateProperty<double?>? surfaceOffset,
  }) => FluentDropdownStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    placeholderColor: placeholderColor ?? this.placeholderColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    borderRadius: borderRadius ?? this.borderRadius,
    underlineColor: underlineColor ?? this.underlineColor,
    accentColor: accentColor ?? this.accentColor,
    accentWidth: accentWidth ?? this.accentWidth,
    textStyle: textStyle ?? this.textStyle,
    padding: padding ?? this.padding,
    gap: gap ?? this.gap,
    chevronColor: chevronColor ?? this.chevronColor,
    chevronSize: chevronSize ?? this.chevronSize,
    chevronPadding: chevronPadding ?? this.chevronPadding,
    minimumSize: minimumSize ?? this.minimumSize,
    mouseCursor: mouseCursor ?? this.mouseCursor,
    surfaceColor: surfaceColor ?? this.surfaceColor,
    surfaceBorderColor: surfaceBorderColor ?? this.surfaceBorderColor,
    surfaceBorderWidth: surfaceBorderWidth ?? this.surfaceBorderWidth,
    surfaceRadius: surfaceRadius ?? this.surfaceRadius,
    surfacePadding: surfacePadding ?? this.surfacePadding,
    surfaceGap: surfaceGap ?? this.surfaceGap,
    surfaceShadow: surfaceShadow ?? this.surfaceShadow,
    surfaceMaxHeight: surfaceMaxHeight ?? this.surfaceMaxHeight,
    surfaceOffset: surfaceOffset ?? this.surfaceOffset,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`. Use the constructor directly
  /// when a property genuinely differs per state.
  static FluentDropdownStyle from({
    Color? backgroundColor,
    Color? foregroundColor,
    Color? placeholderColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    Color? underlineColor,
    Color? accentColor,
    double? accentWidth,
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
    double? gap,
    Color? chevronColor,
    double? chevronSize,
    EdgeInsetsGeometry? chevronPadding,
    Size? minimumSize,
    MouseCursor? mouseCursor,
    Color? surfaceColor,
    Color? surfaceBorderColor,
    double? surfaceBorderWidth,
    BorderRadius? surfaceRadius,
    EdgeInsetsGeometry? surfacePadding,
    double? surfaceGap,
    List<BoxShadow>? surfaceShadow,
    double? surfaceMaxHeight,
    double? surfaceOffset,
  }) => FluentDropdownStyle(
    backgroundColor: _all(backgroundColor),
    foregroundColor: _all(foregroundColor),
    placeholderColor: _all(placeholderColor),
    borderColor: _all(borderColor),
    borderWidth: _all(borderWidth),
    borderRadius: _all(borderRadius),
    underlineColor: _all(underlineColor),
    accentColor: _all(accentColor),
    accentWidth: _all(accentWidth),
    textStyle: _all(textStyle),
    padding: _all(padding),
    gap: _all(gap),
    chevronColor: _all(chevronColor),
    chevronSize: _all(chevronSize),
    chevronPadding: _all(chevronPadding),
    minimumSize: _all(minimumSize),
    mouseCursor: _all(mouseCursor),
    surfaceColor: _all(surfaceColor),
    surfaceBorderColor: _all(surfaceBorderColor),
    surfaceBorderWidth: _all(surfaceBorderWidth),
    surfaceRadius: _all(surfaceRadius),
    surfacePadding: _all(surfacePadding),
    surfaceGap: _all(surfaceGap),
    surfaceShadow: _all(surfaceShadow),
    surfaceMaxHeight: _all(surfaceMaxHeight),
    surfaceOffset: _all(surfaceOffset),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentDropdownStyle &&
      other.backgroundColor == backgroundColor &&
      other.foregroundColor == foregroundColor &&
      other.placeholderColor == placeholderColor &&
      other.borderColor == borderColor &&
      other.borderWidth == borderWidth &&
      other.borderRadius == borderRadius &&
      other.underlineColor == underlineColor &&
      other.accentColor == accentColor &&
      other.accentWidth == accentWidth &&
      other.textStyle == textStyle &&
      other.padding == padding &&
      other.gap == gap &&
      other.chevronColor == chevronColor &&
      other.chevronSize == chevronSize &&
      other.chevronPadding == chevronPadding &&
      other.minimumSize == minimumSize &&
      other.mouseCursor == mouseCursor &&
      other.surfaceColor == surfaceColor &&
      other.surfaceBorderColor == surfaceBorderColor &&
      other.surfaceBorderWidth == surfaceBorderWidth &&
      other.surfaceRadius == surfaceRadius &&
      other.surfacePadding == surfacePadding &&
      other.surfaceGap == surfaceGap &&
      other.surfaceShadow == surfaceShadow &&
      other.surfaceMaxHeight == surfaceMaxHeight &&
      other.surfaceOffset == surfaceOffset;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    backgroundColor,
    foregroundColor,
    placeholderColor,
    borderColor,
    borderWidth,
    borderRadius,
    underlineColor,
    accentColor,
    accentWidth,
    textStyle,
    padding,
    gap,
    chevronColor,
    chevronSize,
    chevronPadding,
    minimumSize,
    mouseCursor,
    surfaceColor,
    surfaceBorderColor,
    surfaceBorderWidth,
    surfaceRadius,
    surfacePadding,
    surfaceGap,
    surfaceShadow,
    surfaceMaxHeight,
    surfaceOffset,
  ]);
}
