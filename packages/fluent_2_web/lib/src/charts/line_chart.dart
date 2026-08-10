import 'package:flutter/widgets.dart';

import 'line_chart_style.dart';

/// The eight LineChart marker shapes.
///
/// Ports `_getPointPath` (`LineChart.tsx:82-137`) verbatim, including all
/// twenty-four hand-tuned coefficients. The shapes are authored about the
/// centre `(x, y)` with a nominal box width `w`; the three wide shapes are
/// narrowed by their `widthRatio` at the call site (`LineChart.tsx:494`), not
/// here.
abstract final class FluentLineMarkerPainter {
  /// Box width of an active point (`PointSize.hoverSize`,
  /// `LineChart.tsx:64`).
  static const double kHoverSize = 11;

  /// Box width of an inactive point (`PointSize.invisibleSize`,
  /// `LineChart.tsx:65`).
  static const double kInvisibleSize = 1;

  /// "A shape must be 2.5 times bigger than the stroke width"
  /// (`LineChart.tsx:73`).
  static const double kPathMultiplySize = 2.5;

  /// The fallback stroke width (`DEFAULT_LINE_STROKE_SIZE`,
  /// `LineChart.tsx:71`).
  static const double kDefaultLineStrokeSize = 4;

  /// Builds the path for [shapeIndex] (0 circle … 7 octagon) centred on
  /// [centre] with box width [w].
  static Path pathFor(int shapeIndex, Offset centre, double w) {
    final x = centre.dx;
    final y = centre.dy;
    final p = Path();
    switch (shapeIndex) {
      case 0:
        // Two 180° arcs from x-w/2 to x+w/2 (`LineChart.tsx:85-88`). The chord
        // equals the diameter, so upstream's large-arc flag is degenerate and
        // only the sweep direction distinguishes the two halves.
        p
          ..moveTo(x - w / 2, y)
          ..arcToPoint(
            Offset(x + w / 2, y),
            radius: Radius.circular(w / 2),
            clockwise: false,
          )
          ..moveTo(x - w / 2, y)
          ..arcToPoint(Offset(x + w / 2, y), radius: Radius.circular(w / 2));
      case 1:
        // LineChart.tsx:91-95.
        p
          ..moveTo(x - w / 2, y - w / 2)
          ..lineTo(x + w / 2, y - w / 2)
          ..lineTo(x + w / 2, y + w / 2)
          ..lineTo(x - w / 2, y + w / 2)
          ..close();
      case 2:
        // 0.2886 and 0.5774 are the incentre offsets of an equilateral
        // triangle of side w (`LineChart.tsx:97-99`). Upstream's second segment
        // is an `H` command, which is a horizontal `lineTo`.
        p
          ..moveTo(x - w / 2, y - 0.2886 * w)
          ..lineTo(x + w / 2, y - 0.2886 * w)
          ..lineTo(x, y + 0.5774 * w)
          ..close();
      case 3:
        // LineChart.tsx:101-105.
        p
          ..moveTo(x, y - w / 2)
          ..lineTo(x + w / 2, y)
          ..lineTo(x, y + w / 2)
          ..lineTo(x - w / 2, y)
          ..close();
      case 4:
        // LineChart.tsx:107-109.
        p
          ..moveTo(x, y - 0.5774 * w)
          ..lineTo(x + w / 2, y + 0.2886 * w)
          ..lineTo(x - w / 2, y + 0.2886 * w)
          ..close();
      case 5:
        // 0.866 == sin(60°) (`LineChart.tsx:111-117`).
        p
          ..moveTo(x - 0.5 * w, y - 0.866 * w)
          ..lineTo(x + 0.5 * w, y - 0.866 * w)
          ..lineTo(x + w, y)
          ..lineTo(x + 0.5 * w, y + 0.866 * w)
          ..lineTo(x - 0.5 * w, y + 0.866 * w)
          ..lineTo(x - w, y)
          ..close();
      case 6:
        // LineChart.tsx:119-124.
        p
          ..moveTo(x, y - 0.851 * w)
          ..lineTo(x + 0.6884 * w, y - 0.2633 * w)
          ..lineTo(x + 0.5001 * w, y + 0.6884 * w)
          ..lineTo(x - 0.5001 * w, y + 0.6884 * w)
          ..lineTo(x - 0.6884 * w, y - 0.2633 * w)
          ..close();
      case 7:
        // 1.207 == (1 + sqrt(2)) / 2 (`LineChart.tsx:126-133`).
        p
          ..moveTo(x - 0.5001 * w, y - 1.207 * w)
          ..lineTo(x + 0.5001 * w, y - 1.207 * w)
          ..lineTo(x + 1.207 * w, y - 0.5001 * w)
          ..lineTo(x + 1.207 * w, y + 0.5001 * w)
          ..lineTo(x + 0.5001 * w, y + 1.207 * w)
          ..lineTo(x - 0.5001 * w, y + 1.207 * w)
          ..lineTo(x - 1.207 * w, y + 0.5001 * w)
          ..lineTo(x - 1.207 * w, y - 0.5001 * w)
          ..close();
      default:
        throw ArgumentError.value(shapeIndex, 'shapeIndex', 'must be 0..7');
    }
    return p;
  }

  /// Ports `_getBoxWidthOfShape` (`LineChart.tsx:463-480`).
  ///
  /// Note the asymmetry: the first/last exemption only exists inside the
  /// `allowMultipleShapesForPoints` branch (`LineChart.tsx:465-472`), so an
  /// ordinary line's points are 1px boxes until hovered.
  ///
  /// [isActive] is upstream's `activePoint === pointId`, [isFirstOrLast] its
  /// `pointIndex === 1 || isLastPoint`.
  static double boxWidthFor({
    required bool allowMultipleShapes,
    required bool isActive,
    required bool isFirstOrLast,
    required double strokeWidth,
  }) {
    if (isActive) {
      return kHoverSize;
    }
    if (allowMultipleShapes && isFirstOrLast) {
      return strokeWidth * kPathMultiplySize;
    }
    return kInvisibleSize;
  }
}

/// Applies a [FluentLineChartStyle] to every line chart below it.
class FluentLineChartTheme extends InheritedTheme {
  /// Applies [style] to every line chart in `child`.
  const FluentLineChartTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the derived defaults.
  final FluentLineChartStyle style;

  /// The nearest line chart style, or null.
  static FluentLineChartStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentLineChartTheme>()?.style;

  @override
  bool updateShouldNotify(FluentLineChartTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentLineChartTheme(style: style, child: child);
}
