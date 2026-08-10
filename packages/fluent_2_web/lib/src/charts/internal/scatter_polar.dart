import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../model/chart_value.dart';
import 'd3/curves.dart';
import 'd3/path_sink.dart';
import 'd3/shape_line_area.dart';

/// Fill opacity of a `fill: 'toself'` scatterpolar area (`LineChart.tsx:1336`).
const double kScatterPolarFillOpacity = 0.5;

/// Stroke width of a `fill: 'toself'` scatterpolar area (`LineChart.tsx:1338`).
const double kScatterPolarFillStrokeWidth = 2;

/// Stroke opacity of a `fill: 'toself'` scatterpolar area
/// (`LineChart.tsx:1339`).
const double kScatterPolarFillStrokeOpacity = 0.8;

/// Minimum number of data points before a `toself` fill is drawn at all
/// (`LineChart.tsx:1318`). Two points enclose no area, so upstream skips them.
const int kScatterPolarMinFillPoints = 3;

/// Radius, in domain units, of the ring the category labels sit on
/// (`scatterpolar-utils.tsx:31`).
const double kScatterPolarLabelRadius = 0.7;

/// Minimum pixel separation between two placed category labels
/// (`scatterpolar-utils.tsx:14`).
const double kScatterPolarLabelMinPixelGap = 40;

/// Builds the closed path Plotly's `fill: 'toself'` paints for a scatterpolar
/// trace.
///
/// [points] are already in device pixels. A point with a non-finite component
/// is treated as undefined, exactly as [isPlottable] (`utilities.ts:2278-2280`)
/// does at `LineChart.tsx:1326`, so a gap splits the path into separate
/// sub-paths instead of drawing a straight line through it.
///
/// Returns `null` when there are fewer than [kScatterPolarMinFillPoints]
/// points, which is the guard at `LineChart.tsx:1318`. The caller owns the
/// other three conditions of that guard — `fill === 'toself'`, the legend
/// selection and `_isScatterPolar` — because none of them is geometry.
Path? scatterPolarFillPath({
  required List<Offset> points,
  D3CurveFactory curve = curveLinear,
}) {
  if (points.length < kScatterPolarMinFillPoints) {
    return null;
  }
  final sink = UiPathSink();
  Line<Offset>(
    x: (d, i, data) => d.dx,
    y: (d, i, data) => d.dy,
    defined: (d, i, data) => isPlottable(d.dx, d.dy),
    curve: curve,
  )(points, sink);
  // `LineChart.tsx:1334` appends a literal 'Z' to the generated `d` string,
  // which closes the LAST sub-path only — as `Path.close` does here.
  return sink.path..close();
}

/// One category label placed around a scatterpolar trace.
@immutable
class FluentScatterPolarLabel {
  /// Creates a placed label.
  const FluentScatterPolarLabel({required this.text, required this.position});

  /// The label text, taken verbatim from `lineOptions.axisLabel`.
  final String text;

  /// Centre of the label in device pixels.
  final Offset position;
}

/// Places one label per entry of [labels] at equal angles around the origin.
///
/// Ports `renderScatterPolarCategoryLabels` (`scatterpolar-utils.tsx:9-66`).
/// Labels are spaced by `2*pi / labels.length` starting at [rotationDegrees],
/// sweeping counter-clockwise unless [direction] is `'clockwise'` (`:35`). Each
/// candidate is kept only when the accumulated list is empty or the candidate
/// clears every already-placed label by [minPixelGap] (`:45-47`) — note that
/// the first label is kept unconditionally, which is why a degenerate scale
/// collapses the whole ring to one label.
List<FluentScatterPolarLabel> scatterPolarCategoryLabels({
  required List<String> labels,
  required double Function(double value) xScale,
  required double Function(double value) yScale,
  String? direction,
  double rotationDegrees = 0,
  double originXOffset = 0,
  double minPixelGap = kScatterPolarLabelMinPixelGap,
}) {
  final placed = <Offset>[];
  final result = <FluentScatterPolarLabel>[];
  // `scatterpolar-utils.tsx:35` — anything other than the literal 'clockwise'
  // sweeps counter-clockwise, including a null or misspelled value.
  final dirMultiplier = direction == 'clockwise' ? -1.0 : 1.0;
  // `scatterpolar-utils.tsx:36` — degrees to radians, so 180 degrees is pi.
  final rotationRad = rotationDegrees * math.pi / 180;
  for (var i = 0; i < labels.length; i++) {
    // `scatterpolar-utils.tsx:39` — one full turn (2*pi) shared equally.
    final angle =
        rotationRad + dirMultiplier * (2 * math.pi / labels.length) * i;
    // `scatterpolar-utils.tsx:41` — the offset is halved, centring the ring.
    final x = xScale(
      kScatterPolarLabelRadius * math.cos(angle) - originXOffset / 2,
    );
    final y = yScale(kScatterPolarLabelRadius * math.sin(angle));
    // `scatterpolar-utils.tsx:45` — Euclidean distance against every placed
    // label, not just the previous one.
    final isFarEnough = placed.every(
      (p) => (Offset(x, y) - p).distance >= minPixelGap,
    );
    if (result.isEmpty || isFarEnough) {
      result.add(
        FluentScatterPolarLabel(text: labels[i], position: Offset(x, y)),
      );
      placed.add(Offset(x, y));
    }
  }
  return result;
}
