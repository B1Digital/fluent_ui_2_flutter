import 'package:flutter/widgets.dart';

import 'rating.dart';

/// The visual configuration of a `FluentRating`.
///
/// Shaped like `FluentButtonStyle`: every visual property is a
/// [WidgetStateProperty], so hover, focus and disabled values live on the
/// property rather than being branched on at build time.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the type/size/shape/colour defaults derived from the theme
/// 2. the nearest [FluentRatingTheme]
/// 3. the widget's own `style`
///
/// [shape] lives here rather than on the state for the same reason
/// `FluentButtonStyle.borderRadius` does: it is the geometry the renderer
/// draws, so a consumer replacing the style must be able to replace it too.
@immutable
class FluentRatingStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentRatingStyle({
    this.itemSize,
    this.shape,
    this.gap,
    this.selectedColor,
    this.unselectedColor,
    this.unselectedStrokeColor,
    this.strokeWidth,
    this.mouseCursor,
  });

  /// Edge length of one shape's box. 12, 16, 20 or 28 per the size ramp.
  final WidgetStateProperty<double?>? itemSize;

  /// Which of the three silhouettes is drawn.
  final WidgetStateProperty<FluentRatingShape?>? shape;

  /// Space between two boxes. `FluentSpacing.xxs` by default, which is what
  /// Figma's shape row binds its item spacing to at every size.
  final WidgetStateProperty<double?>? gap;

  /// Fill of the selected portion of a shape.
  final WidgetStateProperty<Color?>? selectedColor;

  /// Fill of the unselected portion.
  ///
  /// Null and transparent are different, and the difference is the whole point
  /// here: an interactive rating draws its unselected shapes as *outlines* with
  /// no fill at all, which is null. A fully transparent token would instead
  /// turn opaque in high contrast and paint over the shape.
  final WidgetStateProperty<Color?>? unselectedColor;

  /// Outline of the unselected portion.
  ///
  /// For a display rating this is Fluent's `transparentStroke`, which is
  /// invisible in light and dark and becomes the canvas text colour in high
  /// contrast — the only thing keeping a canvas-coloured shape legible there.
  final WidgetStateProperty<Color?>? unselectedStrokeColor;

  /// Outline width. Zero means no outline, which is not the same as a
  /// transparent one — a zero-width outline cannot become visible in high
  /// contrast.
  final WidgetStateProperty<double?>? strokeWidth;

  /// Cursor while hovering.
  final WidgetStateProperty<MouseCursor?>? mouseCursor;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only [itemSize] keeps
  /// every resolved colour.
  FluentRatingStyle merge(FluentRatingStyle? other) {
    if (other == null) return this;
    return FluentRatingStyle(
      itemSize: other.itemSize ?? itemSize,
      shape: other.shape ?? shape,
      gap: other.gap ?? gap,
      selectedColor: other.selectedColor ?? selectedColor,
      unselectedColor: other.unselectedColor ?? unselectedColor,
      unselectedStrokeColor:
          other.unselectedStrokeColor ?? unselectedStrokeColor,
      strokeWidth: other.strokeWidth ?? strokeWidth,
      mouseCursor: other.mouseCursor ?? mouseCursor,
    );
  }

  /// This style with the given properties replaced.
  FluentRatingStyle copyWith({
    WidgetStateProperty<double?>? itemSize,
    WidgetStateProperty<FluentRatingShape?>? shape,
    WidgetStateProperty<double?>? gap,
    WidgetStateProperty<Color?>? selectedColor,
    WidgetStateProperty<Color?>? unselectedColor,
    WidgetStateProperty<Color?>? unselectedStrokeColor,
    WidgetStateProperty<double?>? strokeWidth,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
  }) => FluentRatingStyle(
    itemSize: itemSize ?? this.itemSize,
    shape: shape ?? this.shape,
    gap: gap ?? this.gap,
    selectedColor: selectedColor ?? this.selectedColor,
    unselectedColor: unselectedColor ?? this.unselectedColor,
    unselectedStrokeColor: unselectedStrokeColor ?? this.unselectedStrokeColor,
    strokeWidth: strokeWidth ?? this.strokeWidth,
    mouseCursor: mouseCursor ?? this.mouseCursor,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// Use the constructor directly when a property genuinely differs per state —
  /// which, for a rating, is only ever the colours.
  static FluentRatingStyle from({
    double? itemSize,
    FluentRatingShape? shape,
    double? gap,
    Color? selectedColor,
    Color? unselectedColor,
    Color? unselectedStrokeColor,
    double? strokeWidth,
    MouseCursor? mouseCursor,
  }) => FluentRatingStyle(
    itemSize: _all(itemSize),
    shape: _all(shape),
    gap: _all(gap),
    selectedColor: _all(selectedColor),
    unselectedColor: _all(unselectedColor),
    unselectedStrokeColor: _all(unselectedStrokeColor),
    strokeWidth: _all(strokeWidth),
    mouseCursor: _all(mouseCursor),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentRatingStyle &&
      other.itemSize == itemSize &&
      other.shape == shape &&
      other.gap == gap &&
      other.selectedColor == selectedColor &&
      other.unselectedColor == unselectedColor &&
      other.unselectedStrokeColor == unselectedStrokeColor &&
      other.strokeWidth == strokeWidth &&
      other.mouseCursor == mouseCursor;

  @override
  int get hashCode => Object.hash(
    itemSize,
    shape,
    gap,
    selectedColor,
    unselectedColor,
    unselectedStrokeColor,
    strokeWidth,
    mouseCursor,
  );
}
