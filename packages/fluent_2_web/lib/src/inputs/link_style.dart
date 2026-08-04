import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentLink`.
///
/// Deliberately shaped like `FluentButtonStyle`: every visual property is a
/// [WidgetStateProperty], so hover, pressed, focused and disabled values live on
/// the property rather than being branched on at build time.
///
/// A link is text, not a surface. Figma's Link set paints no fill and no
/// stroke on the component frame — `"fill": null, "stroke": null` on all 15
/// variants — so there is deliberately no `backgroundColor`, `borderColor`,
/// `borderWidth` or `borderRadius` here. Nothing to paint means nothing to
/// hardcode a transparent colour into.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the appearance defaults derived from the theme
/// 2. the nearest `FluentLinkTheme`
/// 3. the widget's own `style`
///
/// The consumer's own style therefore wins, matching upstream's rule that
/// `props.className` is passed last to `mergeClasses`.
@immutable
class FluentLinkStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentLinkStyle({
    this.foregroundColor,
    this.decoration,
    this.decorationColor,
    this.decorationStyle,
    this.decorationThickness,
    this.textStyle,
    this.padding,
    this.gap,
    this.iconSize,
    this.mouseCursor,
  });

  /// Label and icon colour.
  final WidgetStateProperty<Color?>? foregroundColor;

  /// Whether the label is underlined.
  ///
  /// `TextDecoration.none` and null are different: null inherits whatever the
  /// ambient `DefaultTextStyle` carries, `none` states that this link is not
  /// underlined in this state.
  final WidgetStateProperty<TextDecoration?>? decoration;

  /// Underline colour. Tracks [foregroundColor] in every state except focus,
  /// where Figma recolours it to the focus stroke.
  final WidgetStateProperty<Color?>? decorationColor;

  /// Underline style. Figma draws two lines under a focused link and one
  /// everywhere else, which is `TextDecorationStyle.double` and
  /// `TextDecorationStyle.solid` respectively.
  final WidgetStateProperty<TextDecorationStyle?>? decorationStyle;

  /// Underline width, in logical pixels.
  final WidgetStateProperty<double?>? decorationThickness;

  /// Label text style. Its colour and decoration are overridden by
  /// [foregroundColor] and the `decoration*` properties.
  final WidgetStateProperty<TextStyle?>? textStyle;

  /// Padding around the label and icon.
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;

  /// Space between label and icon.
  final WidgetStateProperty<double?>? gap;

  /// Icon edge length.
  final WidgetStateProperty<double?>? iconSize;

  /// Cursor while hovering.
  final WidgetStateProperty<MouseCursor?>? mouseCursor;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only `gap` keeps every
  /// resolved colour. This is what makes a partial override useful.
  FluentLinkStyle merge(FluentLinkStyle? other) {
    if (other == null) return this;
    return FluentLinkStyle(
      foregroundColor: other.foregroundColor ?? foregroundColor,
      decoration: other.decoration ?? decoration,
      decorationColor: other.decorationColor ?? decorationColor,
      decorationStyle: other.decorationStyle ?? decorationStyle,
      decorationThickness: other.decorationThickness ?? decorationThickness,
      textStyle: other.textStyle ?? textStyle,
      padding: other.padding ?? padding,
      gap: other.gap ?? gap,
      iconSize: other.iconSize ?? iconSize,
      mouseCursor: other.mouseCursor ?? mouseCursor,
    );
  }

  /// This style with the given properties replaced.
  FluentLinkStyle copyWith({
    WidgetStateProperty<Color?>? foregroundColor,
    WidgetStateProperty<TextDecoration?>? decoration,
    WidgetStateProperty<Color?>? decorationColor,
    WidgetStateProperty<TextDecorationStyle?>? decorationStyle,
    WidgetStateProperty<double?>? decorationThickness,
    WidgetStateProperty<TextStyle?>? textStyle,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<double?>? gap,
    WidgetStateProperty<double?>? iconSize,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
  }) => FluentLinkStyle(
    foregroundColor: foregroundColor ?? this.foregroundColor,
    decoration: decoration ?? this.decoration,
    decorationColor: decorationColor ?? this.decorationColor,
    decorationStyle: decorationStyle ?? this.decorationStyle,
    decorationThickness: decorationThickness ?? this.decorationThickness,
    textStyle: textStyle ?? this.textStyle,
    padding: padding ?? this.padding,
    gap: gap ?? this.gap,
    iconSize: iconSize ?? this.iconSize,
    mouseCursor: mouseCursor ?? this.mouseCursor,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`. Use the constructor directly
  /// when a property genuinely differs per state — which, for a link, most of
  /// them do.
  static FluentLinkStyle from({
    Color? foregroundColor,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
    double? gap,
    double? iconSize,
    MouseCursor? mouseCursor,
  }) => FluentLinkStyle(
    foregroundColor: _all(foregroundColor),
    decoration: _all(decoration),
    decorationColor: _all(decorationColor),
    decorationStyle: _all(decorationStyle),
    decorationThickness: _all(decorationThickness),
    textStyle: _all(textStyle),
    padding: _all(padding),
    gap: _all(gap),
    iconSize: _all(iconSize),
    mouseCursor: _all(mouseCursor),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentLinkStyle &&
      other.foregroundColor == foregroundColor &&
      other.decoration == decoration &&
      other.decorationColor == decorationColor &&
      other.decorationStyle == decorationStyle &&
      other.decorationThickness == decorationThickness &&
      other.textStyle == textStyle &&
      other.padding == padding &&
      other.gap == gap &&
      other.iconSize == iconSize &&
      other.mouseCursor == mouseCursor;

  @override
  int get hashCode => Object.hash(
    foregroundColor,
    decoration,
    decorationColor,
    decorationStyle,
    decorationThickness,
    textStyle,
    padding,
    gap,
    iconSize,
    mouseCursor,
  );
}
