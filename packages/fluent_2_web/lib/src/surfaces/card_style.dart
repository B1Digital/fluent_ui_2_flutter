import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentCard`.
///
/// Deliberately shaped like Material's `ButtonStyle`: every visual property is a
/// [WidgetStateProperty], so hover, pressed, selected and disabled values live
/// on the property rather than being branched on at build time. A Flutter
/// developer already knows how to read and override this.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the appearance/size defaults derived from the theme
/// 2. the nearest `FluentCardTheme`
/// 3. the widget's own `style`
///
/// The consumer's own style therefore wins, matching upstream's rule that
/// `props.className` is passed last to `mergeClasses`.
@immutable
class FluentCardStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentCardStyle({
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.padding,
    this.gap,
    this.shadow,
    this.mouseCursor,
  });

  /// Surface fill.
  final WidgetStateProperty<Color?>? backgroundColor;

  /// Colour inherited by the slots' text and icons. Upstream sets only the
  /// colour on the card root — never a font — so neither does this.
  final WidgetStateProperty<Color?>? foregroundColor;

  /// Border colour. Null and transparent are different: Fluent's
  /// `transparentStroke` becomes opaque in high contrast.
  final WidgetStateProperty<Color?>? borderColor;

  /// Border width. Zero means no border, which is not the same as a transparent
  /// one — a zero-width border cannot become visible in high contrast.
  ///
  /// The border is painted as a *foreground* decoration, so it never consumes
  /// layout: content starts at [padding] from the outer edge, matching Figma's
  /// and CSS's `border-box`. Upstream achieves the same thing with an `::after`
  /// pseudo-element, which also lets the preview slot bleed under it.
  final WidgetStateProperty<double?>? borderWidth;

  /// Corner radius. The surface, the border and the clip all share it.
  final WidgetStateProperty<BorderRadius?>? borderRadius;

  /// Inset around every slot except the preview, which bleeds to the edge.
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;

  /// Space between slots. Upstream drives padding and gap from one CSS
  /// variable, so they are equal at every size — but they are separate
  /// properties here so either can be overridden alone.
  final WidgetStateProperty<double?>? gap;

  /// Elevation shadow cast by the surface.
  final WidgetStateProperty<List<BoxShadow>?>? shadow;

  /// Cursor while hovering. Only consulted on an interactive card.
  final WidgetStateProperty<MouseCursor?>? mouseCursor;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only `borderRadius`
  /// keeps every resolved colour. This is what makes a partial override useful.
  FluentCardStyle merge(FluentCardStyle? other) {
    if (other == null) return this;
    return FluentCardStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      padding: other.padding ?? padding,
      gap: other.gap ?? gap,
      shadow: other.shadow ?? shadow,
      mouseCursor: other.mouseCursor ?? mouseCursor,
    );
  }

  /// This style with the given properties replaced.
  FluentCardStyle copyWith({
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? foregroundColor,
    WidgetStateProperty<Color?>? borderColor,
    WidgetStateProperty<double?>? borderWidth,
    WidgetStateProperty<BorderRadius?>? borderRadius,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<double?>? gap,
    WidgetStateProperty<List<BoxShadow>?>? shadow,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
  }) => FluentCardStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    borderRadius: borderRadius ?? this.borderRadius,
    padding: padding ?? this.padding,
    gap: gap ?? this.gap,
    shadow: shadow ?? this.shadow,
    mouseCursor: mouseCursor ?? this.mouseCursor,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`. Use the constructor directly
  /// when a property genuinely differs per state.
  static FluentCardStyle from({
    Color? backgroundColor,
    Color? foregroundColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    double? gap,
    List<BoxShadow>? shadow,
    MouseCursor? mouseCursor,
  }) => FluentCardStyle(
    backgroundColor: _all(backgroundColor),
    foregroundColor: _all(foregroundColor),
    borderColor: _all(borderColor),
    borderWidth: _all(borderWidth),
    borderRadius: _all(borderRadius),
    padding: _all(padding),
    gap: _all(gap),
    shadow: _all(shadow),
    mouseCursor: _all(mouseCursor),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentCardStyle &&
      other.backgroundColor == backgroundColor &&
      other.foregroundColor == foregroundColor &&
      other.borderColor == borderColor &&
      other.borderWidth == borderWidth &&
      other.borderRadius == borderRadius &&
      other.padding == padding &&
      other.gap == gap &&
      other.shadow == shadow &&
      other.mouseCursor == mouseCursor;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    foregroundColor,
    borderColor,
    borderWidth,
    borderRadius,
    padding,
    gap,
    shadow,
    mouseCursor,
  );
}
