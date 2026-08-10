import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'axis/tick_format.dart';
import 'internal/d3/shape_pie.dart' as d3;
import 'internal/data_viz_palette.dart';
import 'model/bar_data.dart';

/// Ordering applied to a donut's legend (`DonutChart.tsx:107-111`).
enum FluentDonutOrder {
  /// Input order. Upstream's `'default'`, renamed because `default` is a Dart
  /// keyword.
  byDefault,

  /// Descending by value.
  sorted,
}

/// One arc of a donut, after elevation, filtering and the pie layout.
@immutable
class FluentDonutSlice {
  /// Creates a slice.
  const FluentDonutSlice({
    required this.point,
    required this.index,
    required this.value,
    required this.startAngle,
    required this.endAngle,
    required this.padAngle,
    required this.colour,
  });

  /// The datum, with any elevation already applied.
  final FluentChartDataPoint point;

  /// Position in the filtered list the pie ran over.
  final int index;

  /// The value the layout used — the elevated one, not the caller's.
  final double value;

  /// Start angle in d3's convention: zero at twelve o'clock, increasing
  /// clockwise. `Arc` subtracts a further quarter turn internally.
  final double startAngle;

  /// End angle, same convention.
  final double endAngle;

  /// The pad angle carried on the datum, which is what `Arc`'s default
  /// accessor reads.
  final double padAngle;

  /// Resolved fill.
  final Color colour;
}

/// The resolved geometry of one donut.
///
/// Kept pure so the order of operations — colours, sort, elevate, filter, pie —
/// can be asserted without a widget. Getting that order wrong moves every
/// angle.
@immutable
class FluentDonutLayout {
  const FluentDonutLayout._({
    required this.slices,
    required this.legendPoints,
    required this.outerRadius,
    required this.innerRadius,
    required this.total,
    required this.centre,
  });

  /// Runs the full pipeline.
  static FluentDonutLayout compute({
    required List<FluentChartDataPoint> points,
    required FluentDonutOrder order,
    required Size size,
    required double innerRadius,
    required bool hideLabels,
    required double titleHeight,
    required double labelMarginHorizontal,
    required double labelMarginVertical,
    required double padAngle,
    required bool isDark,
  }) {
    // Step 1 — colours, by position in the ORIGINAL list
    // (`DonutChart.tsx:257-269`, `:327`).
    //
    // parity note: upstream writes the resolved colour to a `defaultColor`
    // field, but `Pie.tsx:61` reads `d.data.color`, so an uncoloured slice
    // renders with `fill: undefined` — SVG black. Reproducing that would make
    // every default donut monochrome, which is a total loss of information
    // rather than a pixel difference, so the colour is assigned to the field
    // the renderer actually reads.
    // ponytail: DonutChart.tsx:265 writes the wrong field; assigning the right
    // one is the whole point of the function.
    final coloured = <FluentChartDataPoint>[
      for (var i = 0; i < points.length; i++)
        points[i].color != null
            ? points[i]
            : points[i].copyWithColor(
                FluentDataVizPalette.next(i, isDark: isDark),
              ),
    ];

    // Step 2 — the legend list. `DonutChart.tsx:331` passes
    // `points.filter(d => d.data >= 0)`, which is a NEW list, and the
    // descending sort at `:108` mutates only that copy. The arcs below
    // therefore keep the input order even when `order` is sorted.
    final legendPoints = <FluentChartDataPoint>[
      for (final point in coloured)
        if ((point.data ?? 0) >= 0) point,
    ];
    if (order == FluentDonutOrder.sorted) {
      legendPoints.sort((a, b) => (b.data ?? 0).compareTo(a.data ?? 0));
    }

    // Step 3 — elevation (`DonutChart.tsx:85-105`). minPercent is 0.01 and the
    // comparison is strict, so a value exactly at the threshold is untouched.
    var sumOfData = 0.0;
    for (final point in coloured) {
      sumOfData += point.data ?? 0;
    }
    // `DonutChart.tsx:86`.
    const minPercent = 0.01;
    final elevated = <FluentChartDataPoint>[
      for (final point in coloured)
        if (minPercent * sumOfData > (point.data ?? 0) && (point.data ?? 0) > 0)
          point.copyWithElevatedData(
            minPercent * sumOfData,
            // `:98` — `item.data!.toLocaleString()`, which groups.
            point.yAxisCalloutData ?? formatToLocaleString(point.data),
          )
        else
          point,
    ];

    // Step 4 — the arc filter is `!== 0`, not `>= 0` (`Pie.tsx:90`), so a
    // negative value survives into the layout.
    final forPie = <FluentChartDataPoint>[
      for (final point in elevated)
        if ((point.data ?? 0) != 0) point,
    ];

    // Step 5 — d3.pie with sort(null) and the caller's pad angle
    // (`Pie.tsx:94-98`).
    final arcs = d3.Pie<FluentChartDataPoint>(
      value: (d) => d.data ?? 0,
      padAngle: padAngle,
    )(forPie);

    // DonutChart.tsx:332-335.
    final outerRadius =
        math.min(
          size.width - (hideLabels ? 0 : labelMarginHorizontal),
          size.height - (hideLabels ? 0 : labelMarginVertical) - titleHeight,
        ) /
        2;

    // `Pie.tsx:52-58` sums `props.data`, the list before the `!== 0` filter, so
    // zeroes are included — they contribute nothing, but the percentage labels
    // are documented against the full list.
    var total = 0.0;
    for (final point in elevated) {
      total += point.data ?? 0;
    }

    return FluentDonutLayout._(
      slices: <FluentDonutSlice>[
        for (var i = 0; i < arcs.length; i++)
          FluentDonutSlice(
            point: forPie[i],
            index: i,
            value: arcs[i].value,
            startAngle: arcs[i].startAngle,
            endAngle: arcs[i].endAngle,
            padAngle: arcs[i].padAngle,
            colour: forPie[i].color!,
          ),
      ],
      legendPoints: legendPoints,
      outerRadius: outerRadius,
      innerRadius: innerRadius,
      total: total,
      // Pie.tsx:99 — translate(width / 2, height / 2).
      centre: Offset(size.width / 2, size.height / 2),
    );
  }

  /// The arcs, in the order they are painted.
  final List<FluentDonutSlice> slices;

  /// The legend entries, which may disagree with [slices] in both membership
  /// and order.
  final List<FluentChartDataPoint> legendPoints;

  /// Outer radius in logical pixels.
  final double outerRadius;

  /// Inner radius in logical pixels — an absolute value, not a fraction
  /// (`DonutChart.tsx:34`).
  final double innerRadius;

  /// Sum over the slices the pie ran on.
  final double total;

  /// Centre of the plot in painter coordinates.
  final Offset centre;

  /// Radius at which arc labels sit — `max(inner, outer) + offset`
  /// (`Arc.tsx:79`, where the offset is the literal 2).
  double labelRadius(double offset) =>
      math.max(innerRadius, outerRadius) + offset;
}
