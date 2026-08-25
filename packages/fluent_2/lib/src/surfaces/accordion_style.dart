import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentAccordionItem`.
///
/// Shaped exactly like `FluentButtonStyle`: every visual property is a
/// [WidgetStateProperty], so hover, pressed and disabled values live on the
/// property rather than being branched on at build time.
///
/// The properties describe the item's **header** — the interactive row Fluent
/// calls `AccordionHeader` — plus [panelPadding], the one number the collapsing
/// panel needs. `FluentAccordion` itself has no style: upstream's
/// `useAccordionItemStyles` and `useAccordionStyles` set no visual property at
/// all, so there would be nothing to put in one.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the size defaults derived from the theme
/// 2. the nearest `FluentAccordionItemTheme`
/// 3. the widget's own `style`
@immutable
class FluentAccordionItemStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentAccordionItemStyle({
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
    this.textStyle,
    this.padding,
    this.gap,
    this.expandIconSize,
    this.minimumSize,
    this.panelPadding,
    this.mouseCursor,
  });

  /// Header surface fill.
  ///
  /// Upstream is `colorTransparentBackground` in every state, so this is the
  /// property most likely to be overridden — see `FluentAccordionItem` for why
  /// the default is not a hover highlight.
  final WidgetStateProperty<Color?>? backgroundColor;

  /// Header label, leading icon and chevron colour.
  final WidgetStateProperty<Color?>? foregroundColor;

  /// Header corner radius. Also the radius the focus ring is drawn on.
  final WidgetStateProperty<BorderRadius?>? borderRadius;

  /// Header label text style. Its colour is overridden by [foregroundColor].
  final WidgetStateProperty<TextStyle?>? textStyle;

  /// Padding inside the header.
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;

  /// Space between the chevron, the leading icon and the label.
  final WidgetStateProperty<double?>? gap;

  /// Chevron edge length.
  final WidgetStateProperty<double?>? expandIconSize;

  /// Minimum header size. Fluent specifies the height only.
  final WidgetStateProperty<Size?>? minimumSize;

  /// Padding around the panel content while it is expanded.
  final WidgetStateProperty<EdgeInsetsGeometry?>? panelPadding;

  /// Cursor while hovering an enabled header.
  final WidgetStateProperty<MouseCursor?>? mouseCursor;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only `backgroundColor`
  /// keeps every resolved metric.
  FluentAccordionItemStyle merge(FluentAccordionItemStyle? other) {
    if (other == null) return this;
    return FluentAccordionItemStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      borderRadius: other.borderRadius ?? borderRadius,
      textStyle: other.textStyle ?? textStyle,
      padding: other.padding ?? padding,
      gap: other.gap ?? gap,
      expandIconSize: other.expandIconSize ?? expandIconSize,
      minimumSize: other.minimumSize ?? minimumSize,
      panelPadding: other.panelPadding ?? panelPadding,
      mouseCursor: other.mouseCursor ?? mouseCursor,
    );
  }

  /// This style with the given properties replaced.
  FluentAccordionItemStyle copyWith({
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? foregroundColor,
    WidgetStateProperty<BorderRadius?>? borderRadius,
    WidgetStateProperty<TextStyle?>? textStyle,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<double?>? gap,
    WidgetStateProperty<double?>? expandIconSize,
    WidgetStateProperty<Size?>? minimumSize,
    WidgetStateProperty<EdgeInsetsGeometry?>? panelPadding,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
  }) => FluentAccordionItemStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    borderRadius: borderRadius ?? this.borderRadius,
    textStyle: textStyle ?? this.textStyle,
    padding: padding ?? this.padding,
    gap: gap ?? this.gap,
    expandIconSize: expandIconSize ?? this.expandIconSize,
    minimumSize: minimumSize ?? this.minimumSize,
    panelPadding: panelPadding ?? this.panelPadding,
    mouseCursor: mouseCursor ?? this.mouseCursor,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`. Use the constructor directly
  /// when a property genuinely differs per state.
  static FluentAccordionItemStyle from({
    Color? backgroundColor,
    Color? foregroundColor,
    BorderRadius? borderRadius,
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
    double? gap,
    double? expandIconSize,
    Size? minimumSize,
    EdgeInsetsGeometry? panelPadding,
    MouseCursor? mouseCursor,
  }) => FluentAccordionItemStyle(
    backgroundColor: _all(backgroundColor),
    foregroundColor: _all(foregroundColor),
    borderRadius: _all(borderRadius),
    textStyle: _all(textStyle),
    padding: _all(padding),
    gap: _all(gap),
    expandIconSize: _all(expandIconSize),
    minimumSize: _all(minimumSize),
    panelPadding: _all(panelPadding),
    mouseCursor: _all(mouseCursor),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentAccordionItemStyle &&
      other.backgroundColor == backgroundColor &&
      other.foregroundColor == foregroundColor &&
      other.borderRadius == borderRadius &&
      other.textStyle == textStyle &&
      other.padding == padding &&
      other.gap == gap &&
      other.expandIconSize == expandIconSize &&
      other.minimumSize == minimumSize &&
      other.panelPadding == panelPadding &&
      other.mouseCursor == mouseCursor;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    foregroundColor,
    borderRadius,
    textStyle,
    padding,
    gap,
    expandIconSize,
    minimumSize,
    panelPadding,
    mouseCursor,
  );
}
