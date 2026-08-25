import 'package:flutter/widgets.dart';

import '../chrome/legend_shape.dart';

/// One series' contribution to a callout at a single x.
///
/// Ports `CustomizedCalloutDataPoint` (`types/DataPoint.ts:815-821`). Upstream's
/// `yAxisCalloutData?: string | { [id: string]: number }` is split into
/// [yAxisCalloutText] and [yAxisCalloutBreakdown], because a Dart union field
/// would force every one of the thirteen call sites to type-test.
@immutable
class FluentCustomizedCalloutDataPoint {
  /// Creates one callout row.
  const FluentCustomizedCalloutDataPoint({
    required this.legend,
    required this.y,
    required this.color,
    this.xAxisCalloutData,
    this.yAxisCalloutText,
    this.yAxisCalloutBreakdown,
    this.index,
  });

  /// The series name this row belongs to.
  final String legend;

  /// The series' value at this x.
  final double y;

  /// The series colour, used for the row's swatch.
  final Color color;

  /// Replacement text for the x value shown at the top of the callout.
  final String? xAxisCalloutData;

  /// Replacement text for the y value, the `string` arm of
  /// `types/DataPoint.ts:310`.
  final String? yAxisCalloutText;

  /// A named breakdown shown instead of a single y, the `{[id]: number}` arm of
  /// `types/DataPoint.ts:310`.
  final Map<String, double>? yAxisCalloutBreakdown;

  /// The series' index in the chart's series list, or null when the chart does
  /// not number its series.
  ///
  /// `utilities.ts:1053` copies it into every callout point and
  /// `ChartPopover.tsx:188` draws a shape swatch only when it is neither absent
  /// nor `-1`, choosing the shape with `Points[index % 8]` at `:216`. It is an
  /// addition to the cross-plan contract's field list, recorded in this plan's
  /// preamble.
  final int? index;
}

/// Every series' value at one x, ready for a callout.
///
/// Ports `CustomizedCalloutData` (`types/DataPoint.ts:828-831`).
@immutable
class FluentCustomizedCalloutData {
  /// Creates a callout stack.
  const FluentCustomizedCalloutData({required this.x, required this.values})
    : assert(
        x is num || x is String || x is DateTime,
        'types/DataPoint.ts:829 — `number | string | Date`.',
      );

  /// The x this stack sits at: a number, a category or a [DateTime].
  final Object x;

  /// One row per series that has a value at [x].
  final List<FluentCustomizedCalloutDataPoint> values;
}

/// A single hovered value as the popover renders it.
///
/// Ports the `YValueHover` shape (`types/DataPoint.ts:17`, widened by the
/// popover's own props). Every field is optional because the charts assemble it
/// piecemeal.
@immutable
class FluentYValueHover {
  /// Creates a hovered value.
  const FluentYValueHover({
    this.legend,
    this.y,
    this.color,
    this.yAxisCalloutText,
    this.yAxisCalloutBreakdown,
    this.index,
    this.shape,
  });

  /// The series name.
  final String? legend;

  /// The value.
  final double? y;

  /// The series colour.
  final Color? color;

  /// Replacement text for the value.
  final String? yAxisCalloutText;

  /// A named breakdown shown instead of a single value.
  final Map<String, double>? yAxisCalloutBreakdown;

  /// The series index, which gates the swatch (`ChartPopover.tsx:188`).
  final int? index;

  /// The swatch shape, when the chart names one rather than deriving it from
  /// [index].
  final FluentChartLegendShape? shape;
}
