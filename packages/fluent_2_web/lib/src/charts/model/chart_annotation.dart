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
