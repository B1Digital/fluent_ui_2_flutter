import 'package:flutter/widgets.dart';

/// The gap between the chart's outer box and its plot area, in logical pixels.
///
/// Ports `Margins` (`types/DataPoint.ts:37-54`). Upstream documents defaults of
/// left 40, right 20, top 20, bottom 35 on `IMargins` (`utilities.ts:141-162`),
/// but the defaults are applied by each chart's margin solve rather than by the
/// type, so every side stays null here.
///
/// This lives in `model/` and not in `axis/` or `cartesian/` because `margins`
/// is a public prop on every upstream chart, so the data model owns it and both
/// solvers import it.
@immutable
class FluentChartMargins {
  /// Creates a margin set. An omitted side is decided by the margin solve.
  const FluentChartMargins({this.left, this.right, this.top, this.bottom});

  /// The gap on the physical left edge.
  final double? left;

  /// The gap on the physical right edge.
  final double? right;

  /// The gap above the plot area.
  final double? top;

  /// The gap below the plot area.
  final double? bottom;

  /// This margin set with the named sides replaced.
  FluentChartMargins copyWith({
    double? left,
    double? right,
    double? top,
    double? bottom,
  }) => FluentChartMargins(
    left: left ?? this.left,
    right: right ?? this.right,
    top: top ?? this.top,
    bottom: bottom ?? this.bottom,
  );

  /// This margin set with [left] and [right] exchanged.
  ///
  /// Applied at step 4 of the five-step margin solve, **before** the user's own
  /// margins are merged over the result (spec section 3.3), so a right-to-left
  /// chart mirrors the computed reservation but honours an explicit user value
  /// on the side the user named.
  FluentChartMargins get mirrored =>
      FluentChartMargins(left: right, right: left, top: top, bottom: bottom);

  /// This margin set with every non-null side of [other] laid over it.
  ///
  /// The Dart spelling of `{...computed, ...props.margins}`: a side the caller
  /// left null keeps the computed value.
  FluentChartMargins mergeOverride(FluentChartMargins? other) {
    if (other == null) return this;
    return FluentChartMargins(
      left: other.left ?? left,
      right: other.right ?? right,
      top: other.top ?? top,
      bottom: other.bottom ?? bottom,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FluentChartMargins &&
      other.left == left &&
      other.right == right &&
      other.top == top &&
      other.bottom == bottom;

  @override
  int get hashCode => Object.hash(left, right, top, bottom);
}
