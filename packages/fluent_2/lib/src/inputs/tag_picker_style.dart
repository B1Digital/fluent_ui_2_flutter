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
    this.expandIconColor,
    this.expandIconSize,
    this.expandIconPadding,
    this.padding,
    this.contentPadding,
    this.tagSpacing,
    this.tagRunSpacing,
    this.tagPadding,
    this.fieldSpacing,
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

  /// The control's bottom border side, when it differs from [borderColor].
  ///
  /// A side of the box border that joins the others on the CSS corner
  /// diagonal, not an overlay. Null means the bottom follows [borderColor]
  /// like the other three sides, which is what the filled appearances do.
  final WidgetStateProperty<Color?>? underlineColor;

  /// Width of the bottom border side. Like [borderWidth], it insets the
  /// content.
  final WidgetStateProperty<double?>? underlineWidth;

  /// The brand bar that grows across the bottom on focus. Null while disabled,
  /// because a disabled control cannot take focus.
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

  /// Tone of the expand chevron.
  final WidgetStateProperty<Color?>? expandIconColor;

  /// Edge length of the expand chevron.
  final WidgetStateProperty<double?>? expandIconSize;

  /// Inset around the expand chevron. Its vertical half centres the glyph in
  /// the control's first line, which is where upstream's aside pins it.
  final WidgetStateProperty<EdgeInsetsGeometry?>? expandIconPadding;

  /// Inset from the inside of the border to the content and the expand
  /// chevron.
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;

  /// Inset around the field — upstream's `TagPickerInput` padding, which is
  /// what sets the control's height while it has no tags.
  final WidgetStateProperty<EdgeInsetsGeometry?>? contentPadding;

  /// Space between the tags on a row — upstream's `TagGroup` `columnGap`.
  final WidgetStateProperty<double?>? tagSpacing;

  /// Space between rows of tags — upstream's `TagPickerGroup` row `gap`.
  /// Falls back to [tagSpacing].
  final WidgetStateProperty<double?>? tagRunSpacing;

  /// Inset around the tags — upstream's `TagPickerGroup` padding. Falls back
  /// to [contentPadding].
  final WidgetStateProperty<EdgeInsetsGeometry?>? tagPadding;

  /// Space between the tags and a field on the same line — the control's
  /// `columnGap`.
  final WidgetStateProperty<double?>? fieldSpacing;

  /// Narrowest the field may be beside the tags — upstream's `minWidth`.
  ///
  /// The field fills whatever the tags leave of their line, as upstream's
  /// `flexGrow: 1` input does, while that is at least this wide and its text
  /// fits; otherwise it takes a line of its own below them.
  final WidgetStateProperty<double?>? fieldWidth;

  /// Minimum size of the control.
  final WidgetStateProperty<Size?>? minimumSize;

  /// Cursor while hovering the control.
  final WidgetStateProperty<MouseCursor?>? mouseCursor;

  /// Popup surface fill.
  final WidgetStateProperty<Color?>? surfaceColor;

  /// Popup outline colour, painted outside the surface like upstream's CSS
  /// `outline`.
  final WidgetStateProperty<Color?>? surfaceBorderColor;

  /// Popup outline width.
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
  /// is how `buildFluentInput` is told to skip a fill, a border, the bottom
  /// border and the focus bar. `FluentTagPicker` draws all four itself, because
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
      expandIconColor: other.expandIconColor ?? expandIconColor,
      expandIconSize: other.expandIconSize ?? expandIconSize,
      expandIconPadding: other.expandIconPadding ?? expandIconPadding,
      padding: other.padding ?? padding,
      contentPadding: other.contentPadding ?? contentPadding,
      tagSpacing: other.tagSpacing ?? tagSpacing,
      tagRunSpacing: other.tagRunSpacing ?? tagRunSpacing,
      tagPadding: other.tagPadding ?? tagPadding,
      fieldSpacing: other.fieldSpacing ?? fieldSpacing,
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
    WidgetStateProperty<Color?>? expandIconColor,
    WidgetStateProperty<double?>? expandIconSize,
    WidgetStateProperty<EdgeInsetsGeometry?>? expandIconPadding,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<EdgeInsetsGeometry?>? contentPadding,
    WidgetStateProperty<double?>? tagSpacing,
    WidgetStateProperty<double?>? tagRunSpacing,
    WidgetStateProperty<EdgeInsetsGeometry?>? tagPadding,
    WidgetStateProperty<double?>? fieldSpacing,
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
    expandIconColor: expandIconColor ?? this.expandIconColor,
    expandIconSize: expandIconSize ?? this.expandIconSize,
    expandIconPadding: expandIconPadding ?? this.expandIconPadding,
    padding: padding ?? this.padding,
    contentPadding: contentPadding ?? this.contentPadding,
    tagSpacing: tagSpacing ?? this.tagSpacing,
    tagRunSpacing: tagRunSpacing ?? this.tagRunSpacing,
    tagPadding: tagPadding ?? this.tagPadding,
    fieldSpacing: fieldSpacing ?? this.fieldSpacing,
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
    Color? expandIconColor,
    double? expandIconSize,
    EdgeInsetsGeometry? expandIconPadding,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? contentPadding,
    double? tagSpacing,
    double? tagRunSpacing,
    EdgeInsetsGeometry? tagPadding,
    double? fieldSpacing,
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
    expandIconColor: _all(expandIconColor),
    expandIconSize: _all(expandIconSize),
    expandIconPadding: _all(expandIconPadding),
    padding: _all(padding),
    contentPadding: _all(contentPadding),
    tagSpacing: _all(tagSpacing),
    tagRunSpacing: _all(tagRunSpacing),
    tagPadding: _all(tagPadding),
    fieldSpacing: _all(fieldSpacing),
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
      other.expandIconColor == expandIconColor &&
      other.expandIconSize == expandIconSize &&
      other.expandIconPadding == expandIconPadding &&
      other.padding == padding &&
      other.contentPadding == contentPadding &&
      other.tagSpacing == tagSpacing &&
      other.tagRunSpacing == tagRunSpacing &&
      other.tagPadding == tagPadding &&
      other.fieldSpacing == fieldSpacing &&
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
    expandIconColor,
    expandIconSize,
    expandIconPadding,
    padding,
    contentPadding,
    tagSpacing,
    tagRunSpacing,
    tagPadding,
    fieldSpacing,
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
