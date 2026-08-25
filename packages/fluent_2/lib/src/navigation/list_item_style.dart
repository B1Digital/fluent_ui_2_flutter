import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentListItem`.
///
/// Shaped like `FluentButtonStyle`: every visual property is a
/// [WidgetStateProperty], so hover, pressed, selected and disabled values live
/// on the property rather than being branched on at build time.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the size/line-count defaults derived from the theme
/// 2. the nearest `FluentListItemTheme`
/// 3. the list's own `style`
/// 4. the item's own `style`
///
/// Three text ramps rather than one: a list item's title, its second line and
/// its trailing metadata are independently sized and independently coloured in
/// the Figma set, and flattening them into a single `textStyle` would make the
/// second line unstateable.
@immutable
class FluentListItemStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentListItemStyle({
    this.backgroundColor,
    this.primaryTextColor,
    this.secondaryTextColor,
    this.tertiaryTextColor,
    this.primaryTextStyle,
    this.secondaryTextStyle,
    this.tertiaryTextStyle,
    this.borderRadius,
    this.padding,
    this.contentPadding,
    this.mediaPadding,
    this.tertiaryPadding,
    this.selectionPadding,
    this.selectionSize,
    this.minimumSize,
    this.mouseCursor,
  });

  /// Row fill. `Neutral/Background/Subtle/*`, or
  /// `Neutral/Background/Disabled/Rest` while disabled.
  final WidgetStateProperty<Color?>? backgroundColor;

  /// Title colour.
  final WidgetStateProperty<Color?>? primaryTextColor;

  /// Second-line colour.
  final WidgetStateProperty<Color?>? secondaryTextColor;

  /// Trailing-metadata colour.
  final WidgetStateProperty<Color?>? tertiaryTextColor;

  /// Title type ramp. Its colour is overridden by [primaryTextColor].
  final WidgetStateProperty<TextStyle?>? primaryTextStyle;

  /// Second-line type ramp. Its colour is overridden by [secondaryTextColor].
  final WidgetStateProperty<TextStyle?>? secondaryTextStyle;

  /// Trailing-metadata type ramp. Its colour is overridden by
  /// [tertiaryTextColor].
  final WidgetStateProperty<TextStyle?>? tertiaryTextStyle;

  /// Corner radius of the row. `Corner-radius/List/Default`.
  final WidgetStateProperty<BorderRadius?>? borderRadius;

  /// Inset between the row's edge and its content.
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;

  /// Inset around the text column. Its `left` is also the gap between the media
  /// slot and the title.
  final WidgetStateProperty<EdgeInsetsGeometry?>? contentPadding;

  /// Inset around the leading media slot.
  final WidgetStateProperty<EdgeInsetsGeometry?>? mediaPadding;

  /// Inset around the trailing metadata. Its `left` is also the gap between the
  /// title and the metadata.
  final WidgetStateProperty<EdgeInsetsGeometry?>? tertiaryPadding;

  /// Inset around the selection affordance, which is what centres it on the
  /// row.
  final WidgetStateProperty<EdgeInsetsGeometry?>? selectionPadding;

  /// Edge length of the selection affordance's box. Figma's `.Selection` frame
  /// is 24 at every list-item size.
  final WidgetStateProperty<double?>? selectionSize;

  /// Minimum row size. Its height is the Figma variant's frame height.
  final WidgetStateProperty<Size?>? minimumSize;

  /// Cursor while hovering an enabled row.
  final WidgetStateProperty<MouseCursor?>? mouseCursor;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, so overriding only `borderRadius` keeps every
  /// resolved colour.
  FluentListItemStyle merge(FluentListItemStyle? other) {
    if (other == null) return this;
    return FluentListItemStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      primaryTextColor: other.primaryTextColor ?? primaryTextColor,
      secondaryTextColor: other.secondaryTextColor ?? secondaryTextColor,
      tertiaryTextColor: other.tertiaryTextColor ?? tertiaryTextColor,
      primaryTextStyle: other.primaryTextStyle ?? primaryTextStyle,
      secondaryTextStyle: other.secondaryTextStyle ?? secondaryTextStyle,
      tertiaryTextStyle: other.tertiaryTextStyle ?? tertiaryTextStyle,
      borderRadius: other.borderRadius ?? borderRadius,
      padding: other.padding ?? padding,
      contentPadding: other.contentPadding ?? contentPadding,
      mediaPadding: other.mediaPadding ?? mediaPadding,
      tertiaryPadding: other.tertiaryPadding ?? tertiaryPadding,
      selectionPadding: other.selectionPadding ?? selectionPadding,
      selectionSize: other.selectionSize ?? selectionSize,
      minimumSize: other.minimumSize ?? minimumSize,
      mouseCursor: other.mouseCursor ?? mouseCursor,
    );
  }

  /// This style with the given properties replaced.
  FluentListItemStyle copyWith({
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? primaryTextColor,
    WidgetStateProperty<Color?>? secondaryTextColor,
    WidgetStateProperty<Color?>? tertiaryTextColor,
    WidgetStateProperty<TextStyle?>? primaryTextStyle,
    WidgetStateProperty<TextStyle?>? secondaryTextStyle,
    WidgetStateProperty<TextStyle?>? tertiaryTextStyle,
    WidgetStateProperty<BorderRadius?>? borderRadius,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<EdgeInsetsGeometry?>? contentPadding,
    WidgetStateProperty<EdgeInsetsGeometry?>? mediaPadding,
    WidgetStateProperty<EdgeInsetsGeometry?>? tertiaryPadding,
    WidgetStateProperty<EdgeInsetsGeometry?>? selectionPadding,
    WidgetStateProperty<double?>? selectionSize,
    WidgetStateProperty<Size?>? minimumSize,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
  }) => FluentListItemStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    primaryTextColor: primaryTextColor ?? this.primaryTextColor,
    secondaryTextColor: secondaryTextColor ?? this.secondaryTextColor,
    tertiaryTextColor: tertiaryTextColor ?? this.tertiaryTextColor,
    primaryTextStyle: primaryTextStyle ?? this.primaryTextStyle,
    secondaryTextStyle: secondaryTextStyle ?? this.secondaryTextStyle,
    tertiaryTextStyle: tertiaryTextStyle ?? this.tertiaryTextStyle,
    borderRadius: borderRadius ?? this.borderRadius,
    padding: padding ?? this.padding,
    contentPadding: contentPadding ?? this.contentPadding,
    mediaPadding: mediaPadding ?? this.mediaPadding,
    tertiaryPadding: tertiaryPadding ?? this.tertiaryPadding,
    selectionPadding: selectionPadding ?? this.selectionPadding,
    selectionSize: selectionSize ?? this.selectionSize,
    minimumSize: minimumSize ?? this.minimumSize,
    mouseCursor: mouseCursor ?? this.mouseCursor,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// Use the constructor directly when a property genuinely differs per state.
  static FluentListItemStyle from({
    Color? backgroundColor,
    Color? primaryTextColor,
    Color? secondaryTextColor,
    Color? tertiaryTextColor,
    TextStyle? primaryTextStyle,
    TextStyle? secondaryTextStyle,
    TextStyle? tertiaryTextStyle,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? contentPadding,
    EdgeInsetsGeometry? mediaPadding,
    EdgeInsetsGeometry? tertiaryPadding,
    EdgeInsetsGeometry? selectionPadding,
    double? selectionSize,
    Size? minimumSize,
    MouseCursor? mouseCursor,
  }) => FluentListItemStyle(
    backgroundColor: _all(backgroundColor),
    primaryTextColor: _all(primaryTextColor),
    secondaryTextColor: _all(secondaryTextColor),
    tertiaryTextColor: _all(tertiaryTextColor),
    primaryTextStyle: _all(primaryTextStyle),
    secondaryTextStyle: _all(secondaryTextStyle),
    tertiaryTextStyle: _all(tertiaryTextStyle),
    borderRadius: _all(borderRadius),
    padding: _all(padding),
    contentPadding: _all(contentPadding),
    mediaPadding: _all(mediaPadding),
    tertiaryPadding: _all(tertiaryPadding),
    selectionPadding: _all(selectionPadding),
    selectionSize: _all(selectionSize),
    minimumSize: _all(minimumSize),
    mouseCursor: _all(mouseCursor),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentListItemStyle &&
      other.backgroundColor == backgroundColor &&
      other.primaryTextColor == primaryTextColor &&
      other.secondaryTextColor == secondaryTextColor &&
      other.tertiaryTextColor == tertiaryTextColor &&
      other.primaryTextStyle == primaryTextStyle &&
      other.secondaryTextStyle == secondaryTextStyle &&
      other.tertiaryTextStyle == tertiaryTextStyle &&
      other.borderRadius == borderRadius &&
      other.padding == padding &&
      other.contentPadding == contentPadding &&
      other.mediaPadding == mediaPadding &&
      other.tertiaryPadding == tertiaryPadding &&
      other.selectionPadding == selectionPadding &&
      other.selectionSize == selectionSize &&
      other.minimumSize == minimumSize &&
      other.mouseCursor == mouseCursor;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    primaryTextColor,
    secondaryTextColor,
    tertiaryTextColor,
    primaryTextStyle,
    secondaryTextStyle,
    tertiaryTextStyle,
    borderRadius,
    padding,
    contentPadding,
    mediaPadding,
    tertiaryPadding,
    selectionPadding,
    selectionSize,
    minimumSize,
    mouseCursor,
  );
}
