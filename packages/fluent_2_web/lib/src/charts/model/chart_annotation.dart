import 'package:flutter/widgets.dart';

/// Which y scale an annotation's data coordinate is resolved against.
///
/// Ports `yAxis?: 'primary' | 'secondary'` (`types/ChartAnnotation.ts:12`).
enum FluentAnnotationYAxis {
  /// The chart's main y scale.
  primary,

  /// The secondary y scale, where the chart has one.
  secondary,
}

/// The space one coordinate of an annotation is expressed in.
///
/// Ports `'data' | 'relative' | 'pixel'` (`types/ChartAnnotation.ts:33-34`).
enum FluentCoordinateSpace {
  /// The data domain, resolved through the chart's scale.
  data,

  /// A fraction of the plot area, 0 to 1.
  relative,

  /// Logical pixels from the plot origin.
  pixel,
}

/// Horizontal placement of an annotation relative to its anchor.
///
/// Ports `ChartAnnotationHorizontalAlign` (`types/ChartAnnotation.ts:41`).
enum FluentChartAnnotationAlign {
  /// Left edge on the anchor.
  start,

  /// Centred on the anchor. The default (`ChartAnnotationLayer.tsx:26`).
  center,

  /// Right edge on the anchor.
  end,
}

/// Vertical placement of an annotation relative to its anchor.
///
/// Ports `ChartAnnotationVerticalAlign` (`types/ChartAnnotation.ts:42`).
enum FluentChartAnnotationVerticalAlign {
  /// Top edge on the anchor.
  top,

  /// Centred on the anchor. The default (`ChartAnnotationLayer.tsx:27`).
  middle,

  /// Bottom edge on the anchor.
  bottom,
}

/// Where a connector's arrow head is drawn.
///
/// Ports `ChartAnnotationArrowHead` (`types/ChartAnnotation.ts:44`).
enum FluentChartAnnotationArrowHead {
  /// No head at either end.
  none,

  /// A head at the annotation end.
  start,

  /// A head at the anchor end. The default
  /// (`useChartAnnotationLayer.styles.ts:32`).
  end,

  /// A head at both ends.
  both,
}

/// How an annotation's border is stroked.
///
/// `types/ChartAnnotation.ts:88` types this as the whole CSS `borderStyle`
/// property. The four values the annotation layer actually paints are collapsed
/// into an enum here, because a free string cannot be turned into a dash list
/// without a parser nothing else needs.
enum FluentChartAnnotationBorderStyle {
  /// An unbroken stroke.
  solid,

  /// A dashed stroke.
  dashed,

  /// A dotted stroke.
  dotted,

  /// No border at all.
  none,
}

/// Where an annotation is anchored.
///
/// Ports `ChartAnnotationCoordinate` (`types/ChartAnnotation.ts:3-39`), a
/// four-arm discriminated union.
sealed class FluentChartAnnotationCoordinate {
  /// Allows subclasses to be const.
  const FluentChartAnnotationCoordinate();
}

/// `type: 'data'` — both coordinates run through the chart's scales.
final class FluentDataCoordinate extends FluentChartAnnotationCoordinate {
  /// Creates a data-space anchor.
  const FluentDataCoordinate({
    required this.x,
    required this.y,
    this.yAxis = FluentAnnotationYAxis.primary,
  }) : assert(
         x is num || x is String || x is DateTime,
         'types/ChartAnnotation.ts:8 — `number | string | Date`.',
       ),
       assert(
         y is num || y is String || y is DateTime,
         'types/ChartAnnotation.ts:10 — `number | string | Date`.',
       );

  /// The x value in the data domain.
  final Object x;

  /// The y value in the data domain.
  final Object y;

  /// Which y scale [y] is resolved against.
  final FluentAnnotationYAxis yAxis;
}

/// `type: 'relative'` — both coordinates are fractions of the plot area.
final class FluentRelativeCoordinate extends FluentChartAnnotationCoordinate {
  /// Creates a relative anchor.
  const FluentRelativeCoordinate({required this.x, required this.y});

  /// The fractional x position, 0 at the left of the plot area.
  final double x;

  /// The fractional y position, 0 at the top of the plot area.
  final double y;
}

/// `type: 'pixel'` — both coordinates are logical pixels from the plot origin.
final class FluentPixelCoordinate extends FluentChartAnnotationCoordinate {
  /// Creates a pixel anchor.
  const FluentPixelCoordinate({required this.x, required this.y});

  /// Horizontal offset from the plot origin.
  final double x;

  /// Vertical offset from the plot origin.
  final double y;
}

/// `type: 'mixed'` — each axis names its own space.
final class FluentMixedCoordinate extends FluentChartAnnotationCoordinate {
  /// Creates a mixed anchor.
  const FluentMixedCoordinate({
    required this.xSpace,
    required this.ySpace,
    required this.x,
    required this.y,
    this.yAxis = FluentAnnotationYAxis.primary,
  }) : assert(
         x is num || x is String || x is DateTime,
         'types/ChartAnnotation.ts:35 — `number | string | Date`.',
       ),
       assert(
         y is num || y is String || y is DateTime,
         'types/ChartAnnotation.ts:36 — `number | string | Date`.',
       );

  /// The space [x] is expressed in.
  final FluentCoordinateSpace xSpace;

  /// The space [y] is expressed in.
  final FluentCoordinateSpace ySpace;

  /// The x value.
  final Object x;

  /// The y value.
  final Object y;

  /// Which y scale [y] is resolved against, when [ySpace] is
  /// [FluentCoordinateSpace.data].
  final FluentAnnotationYAxis yAxis;
}

/// The width a chart reserves for an annotation when none is given.
///
/// `DEFAULT_FOREIGN_OBJECT_WIDTH` (`ChartAnnotationLayer.tsx:28`).
const double kDefaultForeignObjectWidth = 180;

/// The height a chart reserves for an annotation when none is given.
///
/// `DEFAULT_FOREIGN_OBJECT_HEIGHT` (`ChartAnnotationLayer.tsx:29`).
const double kDefaultForeignObjectHeight = 60;

/// The line drawn from an annotation to its anchor.
///
/// Ports `ChartAnnotationConnectorProps` (`types/ChartAnnotation.ts:46-59`). The
/// defaults are the constants at `useChartAnnotationLayer.styles.ts:29-32`,
/// which are compile-time and so belong on the constructor; the connector's
/// stroke colour is theme-resolved (`getDefaultConnectorStrokeColor`) and stays
/// null here.
@immutable
class FluentChartAnnotationConnector {
  /// Creates a connector.
  const FluentChartAnnotationConnector({
    this.startPadding = 12,
    this.endPadding = 0,
    this.strokeColor,
    this.strokeWidth = 2,
    this.dashArray,
    this.arrow = FluentChartAnnotationArrowHead.end,
  });

  /// Gap between the annotation box and the start of the line, in logical
  /// pixels. 12 (`useChartAnnotationLayer.styles.ts:29`).
  final double startPadding;

  /// Gap between the anchor and the end of the line, in logical pixels. 0
  /// (`useChartAnnotationLayer.styles.ts:30`).
  final double endPadding;

  /// The line's colour. Null resolves against the theme.
  final Color? strokeColor;

  /// The line's width, in logical pixels. 2
  /// (`useChartAnnotationLayer.styles.ts:31`).
  final double strokeWidth;

  /// An SVG `stroke-dasharray` string, parsed into a dash list at paint time.
  final String? dashArray;

  /// Where the arrow head is drawn.
  final FluentChartAnnotationArrowHead arrow;
}

/// Where an annotation box sits relative to its anchor.
///
/// Ports `ChartAnnotationLayoutProps` (`types/ChartAnnotation.ts:61-76`), minus
/// `className`, which has no Flutter analogue.
@immutable
class FluentChartAnnotationLayout {
  /// Creates a layout.
  const FluentChartAnnotationLayout({
    this.align = FluentChartAnnotationAlign.center,
    this.verticalAlign = FluentChartAnnotationVerticalAlign.middle,
    this.offsetX = 0,
    this.offsetY = 0,
    this.maxWidth,
    this.clipToBounds,
  });

  /// Horizontal placement. `DEFAULT_HORIZONTAL_ALIGN`
  /// (`ChartAnnotationLayer.tsx:26`).
  final FluentChartAnnotationAlign align;

  /// Vertical placement. `DEFAULT_VERTICAL_ALIGN`
  /// (`ChartAnnotationLayer.tsx:27`).
  final FluentChartAnnotationVerticalAlign verticalAlign;

  /// Horizontal nudge applied after alignment, in logical pixels.
  final double offsetX;

  /// Vertical nudge applied after alignment, in logical pixels.
  final double offsetY;

  /// The width text wraps at. Null uses [kDefaultForeignObjectWidth].
  final double? maxWidth;

  /// Whether the annotation is kept inside the plot area.
  ///
  /// Deliberately tri-state. `ChartAnnotationLayer.tsx:385` clamps the anchor
  /// point only when this is truthy, while `:544` picks the clamping viewport
  /// with `!= false`, so a null behaves like neither `true` nor `false`. Read it
  /// through [clampsAnchor] and [clampsViewport] rather than directly.
  final bool? clipToBounds;

  /// Whether the anchor point itself is clamped into the plot area.
  ///
  /// The truthiness test at `ChartAnnotationLayer.tsx:385`.
  bool get clampsAnchor => clipToBounds ?? false;

  /// Whether the plot area, rather than the whole chart, is the clamping
  /// viewport.
  ///
  /// The `!= false` test at `ChartAnnotationLayer.tsx:544`.
  bool get clampsViewport => clipToBounds != false;
}

/// How an annotation box is painted.
///
/// Ports `ChartAnnotationStyleProps` (`types/ChartAnnotation.ts:78-105`), minus
/// `className`. CSS shorthand strings become Flutter types: `padding` is an
/// [EdgeInsets], `boxShadow` a list of [BoxShadow], `fontWeight` a [FontWeight].
@immutable
class FluentChartAnnotationStyle {
  /// Creates an annotation style.
  const FluentChartAnnotationStyle({
    this.textColor,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderStyle,
    this.borderRadius,
    this.boxShadow,
    this.fontSize,
    this.fontWeight,
    this.padding,
    this.opacity = 0.8,
    this.rotation,
  });

  /// The text colour. Null resolves against the theme.
  final Color? textColor;

  /// The box fill. Null resolves against the theme.
  final Color? backgroundColor;

  /// The border colour.
  final Color? borderColor;

  /// The border width in logical pixels.
  final double? borderWidth;

  /// How the border is stroked.
  final FluentChartAnnotationBorderStyle? borderStyle;

  /// The corner radius in logical pixels.
  final double? borderRadius;

  /// Shadows painted under the box.
  final List<BoxShadow>? boxShadow;

  /// The text size in logical pixels.
  final double? fontSize;

  /// The text weight.
  final FontWeight? fontWeight;

  /// Padding inside the box. `DEFAULT_ANNOTATION_PADDING` is `'4px 8px'`
  /// (`useChartAnnotationLayer.styles.ts:28`), which is
  /// `EdgeInsets.symmetric(vertical: 4, horizontal: 8)`.
  final EdgeInsets? padding;

  /// The box's opacity. `DEFAULT_ANNOTATION_BACKGROUND_OPACITY` is 0.8
  /// (`useChartAnnotationLayer.styles.ts:27`).
  final double opacity;

  /// Rotation of the box, in degrees (`types/ChartAnnotation.ts:104`).
  final double? rotation;
}

/// Accessible naming for one annotation.
///
/// Ports `ChartAnnotationAccessibilityProps`
/// (`types/ChartAnnotation.ts:107-114`).
@immutable
class FluentChartAnnotationSemantics {
  /// Creates an annotation's accessible naming.
  const FluentChartAnnotationSemantics({
    this.label,
    this.describedBy,
    this.role = 'note',
  });

  /// The announced label.
  final String? label;

  /// The id of an element describing this annotation.
  final String? describedBy;

  /// The ARIA role. `'note'` is what the layer applies when the caller names
  /// none (`types/ChartAnnotation.ts:113`).
  final String role;
}

/// One annotation drawn over a chart.
///
/// Ports `ChartAnnotation` (`types/ChartAnnotation.ts:116-133`).
@immutable
class FluentChartAnnotation {
  /// Creates an annotation.
  const FluentChartAnnotation({
    required this.text,
    required this.coordinates,
    this.id,
    this.layout,
    this.style,
    this.connector,
    this.semantics,
    this.data,
  });

  /// The annotation's text. Simple `<b>`, `<i>` and `<br>` markup is understood
  /// by the annotation layer at stage 6.
  final String text;

  /// Where the annotation is anchored.
  final FluentChartAnnotationCoordinate coordinates;

  /// A stable identity for the annotation.
  final String? id;

  /// Where the box sits relative to the anchor.
  final FluentChartAnnotationLayout? layout;

  /// How the box is painted.
  final FluentChartAnnotationStyle? style;

  /// The line from the box to the anchor.
  final FluentChartAnnotationConnector? connector;

  /// Accessible naming.
  final FluentChartAnnotationSemantics? semantics;

  /// Caller metadata, carried through untouched.
  final Map<String, Object?>? data;
}

/// A dated marker drawn on a time axis.
///
/// Ports `EventAnnotation` (`types/EventAnnotation.ts:3-7`). Upstream's
/// `onRenderCard` becomes [cardBuilder].
@immutable
class FluentEventAnnotation {
  /// Creates an event annotation.
  const FluentEventAnnotation({
    required this.date,
    required this.event,
    this.cardBuilder,
  });

  /// The instant the marker sits at.
  final DateTime date;

  /// The label shown beside the marker.
  final String event;

  /// Builds the card shown when the marker is activated. Null draws the default
  /// card.
  final WidgetBuilder? cardBuilder;
}
