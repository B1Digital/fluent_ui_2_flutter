import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentCheckbox`.
///
/// Shaped exactly like `FluentButtonStyle`: every visual property is a
/// [WidgetStateProperty], so hover, pressed and disabled values live on the
/// property rather than being branched on at build time.
///
/// The three indicator colours are separate properties rather than one, because
/// upstream drives them through three separate CSS custom properties
/// (`--fui-Checkbox__indicator--color`, `--backgroundColor`, `--borderColor`)
/// and the Status axis moves them independently: `mixed` recolours the border
/// and the glyph while leaving the fill alone.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the size/shape/status defaults derived from the theme
/// 2. the nearest `FluentCheckboxTheme`
/// 3. the widget's own `style`
@immutable
class FluentCheckboxStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentCheckboxStyle({
    this.indicatorColor,
    this.indicatorBackgroundColor,
    this.indicatorBorderColor,
    this.foregroundColor,
    this.borderWidth,
    this.borderRadius,
    this.textStyle,
    this.indicatorMargin,
    this.labelPadding,
    this.indicatorSize,
    this.glyphSize,
    this.minimumSize,
    this.mouseCursor,
  });

  /// The checkmark, mixed square or mixed circle colour.
  final WidgetStateProperty<Color?>? indicatorColor;

  /// The indicator box fill. Fluent's `transparentBackground` in every state
  /// except checked — never `Colors.transparent`, which stays transparent in
  /// high contrast where the token turns opaque.
  final WidgetStateProperty<Color?>? indicatorBackgroundColor;

  /// The indicator box border colour.
  final WidgetStateProperty<Color?>? indicatorBorderColor;

  /// Label colour. Upstream sets this on the root and lets the label inherit.
  final WidgetStateProperty<Color?>? foregroundColor;

  /// Indicator border width. Zero means no border, which is not the same as a
  /// transparent one — a zero-width border cannot become visible in high
  /// contrast.
  final WidgetStateProperty<double?>? borderWidth;

  /// Indicator corner radius.
  final WidgetStateProperty<BorderRadius?>? borderRadius;

  /// Label text style. Its colour is overridden by [foregroundColor].
  final WidgetStateProperty<TextStyle?>? textStyle;

  /// Inset around the indicator box. This is the click target upstream builds
  /// by oversizing the hidden `<input>`, so it is padding rather than margin
  /// here: it is inside the hit area.
  final WidgetStateProperty<EdgeInsetsGeometry?>? indicatorMargin;

  /// Inset around the label, tight on the side facing the indicator.
  final WidgetStateProperty<EdgeInsetsGeometry?>? labelPadding;

  /// Indicator box edge length, border included.
  final WidgetStateProperty<double?>? indicatorSize;

  /// Glyph box edge length. Upstream expresses this as the indicator's
  /// `fontSize`, since the glyph is an icon font-sized inside the box.
  final WidgetStateProperty<double?>? glyphSize;

  /// Minimum size of the whole control.
  final WidgetStateProperty<Size?>? minimumSize;

  /// Cursor while hovering.
  final WidgetStateProperty<MouseCursor?>? mouseCursor;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only `borderRadius`
  /// keeps every resolved colour.
  FluentCheckboxStyle merge(FluentCheckboxStyle? other) {
    if (other == null) return this;
    return FluentCheckboxStyle(
      indicatorColor: other.indicatorColor ?? indicatorColor,
      indicatorBackgroundColor:
          other.indicatorBackgroundColor ?? indicatorBackgroundColor,
      indicatorBorderColor: other.indicatorBorderColor ?? indicatorBorderColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      textStyle: other.textStyle ?? textStyle,
      indicatorMargin: other.indicatorMargin ?? indicatorMargin,
      labelPadding: other.labelPadding ?? labelPadding,
      indicatorSize: other.indicatorSize ?? indicatorSize,
      glyphSize: other.glyphSize ?? glyphSize,
      minimumSize: other.minimumSize ?? minimumSize,
      mouseCursor: other.mouseCursor ?? mouseCursor,
    );
  }

  /// This style with the given properties replaced.
  FluentCheckboxStyle copyWith({
    WidgetStateProperty<Color?>? indicatorColor,
    WidgetStateProperty<Color?>? indicatorBackgroundColor,
    WidgetStateProperty<Color?>? indicatorBorderColor,
    WidgetStateProperty<Color?>? foregroundColor,
    WidgetStateProperty<double?>? borderWidth,
    WidgetStateProperty<BorderRadius?>? borderRadius,
    WidgetStateProperty<TextStyle?>? textStyle,
    WidgetStateProperty<EdgeInsetsGeometry?>? indicatorMargin,
    WidgetStateProperty<EdgeInsetsGeometry?>? labelPadding,
    WidgetStateProperty<double?>? indicatorSize,
    WidgetStateProperty<double?>? glyphSize,
    WidgetStateProperty<Size?>? minimumSize,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
  }) => FluentCheckboxStyle(
    indicatorColor: indicatorColor ?? this.indicatorColor,
    indicatorBackgroundColor:
        indicatorBackgroundColor ?? this.indicatorBackgroundColor,
    indicatorBorderColor: indicatorBorderColor ?? this.indicatorBorderColor,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    borderWidth: borderWidth ?? this.borderWidth,
    borderRadius: borderRadius ?? this.borderRadius,
    textStyle: textStyle ?? this.textStyle,
    indicatorMargin: indicatorMargin ?? this.indicatorMargin,
    labelPadding: labelPadding ?? this.labelPadding,
    indicatorSize: indicatorSize ?? this.indicatorSize,
    glyphSize: glyphSize ?? this.glyphSize,
    minimumSize: minimumSize ?? this.minimumSize,
    mouseCursor: mouseCursor ?? this.mouseCursor,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`. Use the constructor directly
  /// when a property genuinely differs per state.
  static FluentCheckboxStyle from({
    Color? indicatorColor,
    Color? indicatorBackgroundColor,
    Color? indicatorBorderColor,
    Color? foregroundColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    TextStyle? textStyle,
    EdgeInsetsGeometry? indicatorMargin,
    EdgeInsetsGeometry? labelPadding,
    double? indicatorSize,
    double? glyphSize,
    Size? minimumSize,
    MouseCursor? mouseCursor,
  }) => FluentCheckboxStyle(
    indicatorColor: _all(indicatorColor),
    indicatorBackgroundColor: _all(indicatorBackgroundColor),
    indicatorBorderColor: _all(indicatorBorderColor),
    foregroundColor: _all(foregroundColor),
    borderWidth: _all(borderWidth),
    borderRadius: _all(borderRadius),
    textStyle: _all(textStyle),
    indicatorMargin: _all(indicatorMargin),
    labelPadding: _all(labelPadding),
    indicatorSize: _all(indicatorSize),
    glyphSize: _all(glyphSize),
    minimumSize: _all(minimumSize),
    mouseCursor: _all(mouseCursor),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentCheckboxStyle &&
      other.indicatorColor == indicatorColor &&
      other.indicatorBackgroundColor == indicatorBackgroundColor &&
      other.indicatorBorderColor == indicatorBorderColor &&
      other.foregroundColor == foregroundColor &&
      other.borderWidth == borderWidth &&
      other.borderRadius == borderRadius &&
      other.textStyle == textStyle &&
      other.indicatorMargin == indicatorMargin &&
      other.labelPadding == labelPadding &&
      other.indicatorSize == indicatorSize &&
      other.glyphSize == glyphSize &&
      other.minimumSize == minimumSize &&
      other.mouseCursor == mouseCursor;

  @override
  int get hashCode => Object.hash(
    indicatorColor,
    indicatorBackgroundColor,
    indicatorBorderColor,
    foregroundColor,
    borderWidth,
    borderRadius,
    textStyle,
    indicatorMargin,
    labelPadding,
    indicatorSize,
    glyphSize,
    minimumSize,
    mouseCursor,
  );
}
