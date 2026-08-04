import 'package:flutter/widgets.dart';

import 'input_style.dart';

/// The visual configuration of a `FluentTagPicker`.
///
/// Shaped like Material's `ButtonStyle` and like every other style in this
/// package: each visual property is a [WidgetStateProperty], so hover, pressed
/// and disabled values live on the property rather than being branched on at
/// build time.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the appearance/size defaults derived from the theme
/// 2. the nearest `FluentTagPickerTheme`
/// 3. the widget's own `style`
///
/// The chrome half of this struct is deliberately a superset of
/// [FluentInputStyle]'s: `FluentTagPicker` draws the surface itself and hands
/// the composed `FluentInput` a *stripped* style, so the two never paint the
/// same pixel twice. See [strippedInputStyle].
@immutable
class FluentTagPickerStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentTagPickerStyle({
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.underlineColor,
    this.underlineWidth,
    this.accentColor,
    this.accentWidth,
    this.foregroundColor,
    this.placeholderColor,
    this.secondaryColor,
    this.textStyle,
    this.secondaryTextStyle,
    this.padding,
    this.contentPadding,
    this.tagSpacing,
    this.fieldWidth,
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

  /// Surface fill of the control.
  final WidgetStateProperty<Color?>? backgroundColor;

  /// Box border colour. Null and transparent are different: Fluent's
  /// `transparentStroke` becomes opaque in high contrast.
  final WidgetStateProperty<Color?>? borderColor;

  /// Box border width. Zero means no border, which is not the same as a
  /// transparent one — a zero-width border cannot reappear in high contrast.
  final WidgetStateProperty<double?>? borderWidth;

  /// Corner radius of the control.
  final WidgetStateProperty<BorderRadius?>? borderRadius;

  /// The resting rule along the bottom edge. Null on the filled appearances,
  /// which draw none.
  final WidgetStateProperty<Color?>? underlineColor;

  /// Thickness of the resting bottom rule.
  final WidgetStateProperty<double?>? underlineWidth;

  /// The brand bar that grows across the bottom on focus. Null while disabled,
  /// matching upstream's `::after { content: unset }`.
  final WidgetStateProperty<Color?>? accentColor;

  /// Thickness of the brand bar.
  final WidgetStateProperty<double?>? accentWidth;

  /// Colour of the typed value.
  final WidgetStateProperty<Color?>? foregroundColor;

  /// Colour of the placeholder.
  final WidgetStateProperty<Color?>? placeholderColor;

  /// Colour of the trailing secondary action.
  final WidgetStateProperty<Color?>? secondaryColor;

  /// Type ramp of the typed value and the placeholder.
  final WidgetStateProperty<TextStyle?>? textStyle;

  /// Type ramp of the trailing secondary action.
  final WidgetStateProperty<TextStyle?>? secondaryTextStyle;

  /// Horizontal inset from the border to the content.
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;

  /// Vertical inset around the tag strip and the field.
  final WidgetStateProperty<EdgeInsetsGeometry?>? contentPadding;

  /// Space between the tags, and between a tag and the field.
  final WidgetStateProperty<double?>? tagSpacing;

  /// Width the text field takes once at least one tag is present.
  final WidgetStateProperty<double?>? fieldWidth;

  /// Minimum size of the control.
  final WidgetStateProperty<Size?>? minimumSize;

  /// Cursor while hovering the control.
  final WidgetStateProperty<MouseCursor?>? mouseCursor;

  /// Popup surface fill.
  final WidgetStateProperty<Color?>? surfaceColor;

  /// Popup surface border colour.
  final WidgetStateProperty<Color?>? surfaceBorderColor;

  /// Popup surface border width.
  final WidgetStateProperty<double?>? surfaceBorderWidth;

  /// Popup surface corner radius.
  final WidgetStateProperty<BorderRadius?>? surfaceRadius;

  /// Popup surface padding.
  final WidgetStateProperty<EdgeInsetsGeometry?>? surfacePadding;

  /// Space between popup rows.
  final WidgetStateProperty<double?>? surfaceGap;

  /// Popup surface shadow.
  final WidgetStateProperty<List<BoxShadow>?>? surfaceShadow;

  /// Maximum popup height before the list scrolls.
  final WidgetStateProperty<double?>? surfaceMaxHeight;

  /// Vertical gap between the control and the popup.
  final WidgetStateProperty<double?>? surfaceOffset;

  /// The style handed to the composed `FluentInput`.
  ///
  /// Every piece of chrome is explicitly switched **off** rather than left to
  /// inherit: a `WidgetStatePropertyAll<Color?>(null)` resolves to null, which
  /// is how `buildFluentInput` is told to skip a fill, a border, the resting
  /// rule and the focus bar. `FluentTagPicker` draws all four itself, because
  /// its content is a wrapping tag strip rather than the single row an input
  /// lays out.
  ///
  /// What the composed input keeps is everything worth reusing: the
  /// [EditableText], the placeholder, the caret and selection colours, the
  /// disabled ramp and the text type ramp.
  FluentInputStyle strippedInputStyle() => FluentInputStyle(
    backgroundColor: const WidgetStatePropertyAll<Color?>(null),
    borderColor: const WidgetStatePropertyAll<Color?>(null),
    borderWidth: const WidgetStatePropertyAll<double?>(0),
    bottomBorderColor: const WidgetStatePropertyAll<Color?>(null),
    bottomBorderWidth: const WidgetStatePropertyAll<double?>(0),
    focusUnderlineColor: const WidgetStatePropertyAll<Color?>(null),
    foregroundColor: foregroundColor,
    placeholderColor: placeholderColor,
    textStyle: textStyle,
    padding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(EdgeInsets.zero),
    contentPadding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.zero,
    ),
    minimumSize: const WidgetStatePropertyAll<Size?>(Size.zero),
  );

  /// This style with the non-null properties of [other] layered on top.
  FluentTagPickerStyle merge(FluentTagPickerStyle? other) {
    if (other == null) return this;
    return FluentTagPickerStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      underlineColor: other.underlineColor ?? underlineColor,
      underlineWidth: other.underlineWidth ?? underlineWidth,
      accentColor: other.accentColor ?? accentColor,
      accentWidth: other.accentWidth ?? accentWidth,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      placeholderColor: other.placeholderColor ?? placeholderColor,
      secondaryColor: other.secondaryColor ?? secondaryColor,
      textStyle: other.textStyle ?? textStyle,
      secondaryTextStyle: other.secondaryTextStyle ?? secondaryTextStyle,
      padding: other.padding ?? padding,
      contentPadding: other.contentPadding ?? contentPadding,
      tagSpacing: other.tagSpacing ?? tagSpacing,
      fieldWidth: other.fieldWidth ?? fieldWidth,
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
  FluentTagPickerStyle copyWith({
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? borderColor,
    WidgetStateProperty<double?>? borderWidth,
    WidgetStateProperty<BorderRadius?>? borderRadius,
    WidgetStateProperty<Color?>? underlineColor,
    WidgetStateProperty<double?>? underlineWidth,
    WidgetStateProperty<Color?>? accentColor,
    WidgetStateProperty<double?>? accentWidth,
    WidgetStateProperty<Color?>? foregroundColor,
    WidgetStateProperty<Color?>? placeholderColor,
    WidgetStateProperty<Color?>? secondaryColor,
    WidgetStateProperty<TextStyle?>? textStyle,
    WidgetStateProperty<TextStyle?>? secondaryTextStyle,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<EdgeInsetsGeometry?>? contentPadding,
    WidgetStateProperty<double?>? tagSpacing,
    WidgetStateProperty<double?>? fieldWidth,
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
  }) => FluentTagPickerStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    borderRadius: borderRadius ?? this.borderRadius,
    underlineColor: underlineColor ?? this.underlineColor,
    underlineWidth: underlineWidth ?? this.underlineWidth,
    accentColor: accentColor ?? this.accentColor,
    accentWidth: accentWidth ?? this.accentWidth,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    placeholderColor: placeholderColor ?? this.placeholderColor,
    secondaryColor: secondaryColor ?? this.secondaryColor,
    textStyle: textStyle ?? this.textStyle,
    secondaryTextStyle: secondaryTextStyle ?? this.secondaryTextStyle,
    padding: padding ?? this.padding,
    contentPadding: contentPadding ?? this.contentPadding,
    tagSpacing: tagSpacing ?? this.tagSpacing,
    fieldWidth: fieldWidth ?? this.fieldWidth,
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
  static FluentTagPickerStyle from({
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    Color? underlineColor,
    double? underlineWidth,
    Color? accentColor,
    double? accentWidth,
    Color? foregroundColor,
    Color? placeholderColor,
    Color? secondaryColor,
    TextStyle? textStyle,
    TextStyle? secondaryTextStyle,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? contentPadding,
    double? tagSpacing,
    double? fieldWidth,
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
  }) => FluentTagPickerStyle(
    backgroundColor: _all(backgroundColor),
    borderColor: _all(borderColor),
    borderWidth: _all(borderWidth),
    borderRadius: _all(borderRadius),
    underlineColor: _all(underlineColor),
    underlineWidth: _all(underlineWidth),
    accentColor: _all(accentColor),
    accentWidth: _all(accentWidth),
    foregroundColor: _all(foregroundColor),
    placeholderColor: _all(placeholderColor),
    secondaryColor: _all(secondaryColor),
    textStyle: _all(textStyle),
    secondaryTextStyle: _all(secondaryTextStyle),
    padding: _all(padding),
    contentPadding: _all(contentPadding),
    tagSpacing: _all(tagSpacing),
    fieldWidth: _all(fieldWidth),
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
      other is FluentTagPickerStyle &&
      other.backgroundColor == backgroundColor &&
      other.borderColor == borderColor &&
      other.borderWidth == borderWidth &&
      other.borderRadius == borderRadius &&
      other.underlineColor == underlineColor &&
      other.underlineWidth == underlineWidth &&
      other.accentColor == accentColor &&
      other.accentWidth == accentWidth &&
      other.foregroundColor == foregroundColor &&
      other.placeholderColor == placeholderColor &&
      other.secondaryColor == secondaryColor &&
      other.textStyle == textStyle &&
      other.secondaryTextStyle == secondaryTextStyle &&
      other.padding == padding &&
      other.contentPadding == contentPadding &&
      other.tagSpacing == tagSpacing &&
      other.fieldWidth == fieldWidth &&
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
    borderColor,
    borderWidth,
    borderRadius,
    underlineColor,
    underlineWidth,
    accentColor,
    accentWidth,
    foregroundColor,
    placeholderColor,
    secondaryColor,
    textStyle,
    secondaryTextStyle,
    padding,
    contentPadding,
    tagSpacing,
    fieldWidth,
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
