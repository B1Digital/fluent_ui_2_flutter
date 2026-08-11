import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The width and height a [FluentResponsiveChartHost] measured for its child.
///
/// Upstream's `ResponsiveContainer` clones each child with `width`, `height`
/// and `shouldResize` props (`ResponsiveContainer.tsx:80-84`); this class is
/// that injected triple.
@immutable
class FluentResponsiveChartMetrics {
  /// Creates a metrics record. Both dimensions are null before the first
  /// measurement, mirroring the empty `size` state at
  /// `ResponsiveContainer.tsx:18`.
  const FluentResponsiveChartMetrics({this.width, this.height});

  /// The measured width, floored, or null when the parent is unbounded.
  final double? width;

  /// The measured height, floored, or null when the parent is unbounded.
  final double? height;

  /// The scalar `SankeyChart` watches to decide it must re-layout.
  ///
  /// Upstream computes `(calculatedWidth ?? 0) + (calculatedHeight ?? 0)`
  /// (`ResponsiveContainer.tsx:84`) and `SankeyChart.tsx:608` uses it as an
  /// effect dependency. Reproduced verbatim, including the fact that it
  /// collides for any two sizes with the same sum.
  double get shouldResize => (width ?? 0) + (height ?? 0);
}

/// Measures its own constraints and hands them to [builder].
///
/// Private to the package: only the two declarative adapters mount it, because
/// they are the only place a chart's pixel size arrives from a schema rather
/// than from the widget tree. A directly-mounted Fluent chart honours its own
/// `BoxConstraints` and never sees this host — see the design document,
/// section 5.1. (`FluentDeclarativeChart` is deliberately unbracketed:
/// `comment_references` is an error and this file imports nothing from
/// `declarative_chart.dart`.)
///
/// Diverges from the frozen contract §4.8, which sketches a `StatefulWidget`
/// whose builder takes `(BuildContext, double, double, double)`: `width` and
/// `height` must be nullable, because `ResponsiveContainer.tsx:80-84` forwards
/// `undefined` before the first measurement, and `shouldResize` is derived from
/// them rather than injected. Recorded here as well as in the plan so the
/// divergence is visible from the code.
///
/// `LayoutBuilder` replaces the upstream `ResizeObserver` plus
/// `requestAnimationFrame` throttle (`ResponsiveContainer.tsx:23-61`) outright:
/// Flutter already delivers exactly one rebuild per constraint change.
class FluentResponsiveChartHost extends StatelessWidget {
  /// Creates a responsive host.
  const FluentResponsiveChartHost({
    super.key,
    required this.builder,
    this.aspect,
    this.width,
    this.height,
    this.minWidth,
    this.minHeight,
    this.maxHeight,
  });

  /// Builds the chart from the measured metrics.
  final Widget Function(
    BuildContext context,
    FluentResponsiveChartMetrics metrics,
  )
  builder;

  /// Width-to-height ratio. When positive it derives whichever dimension the
  /// parent left unbounded (`ResponsiveContainer.tsx:67-72`).
  final double? aspect;

  /// Explicit width. Null means 100% of the parent, matching the
  /// `props.width ?? '100%'` default at `ResponsiveContainer.tsx:98`.
  final double? width;

  /// Explicit height. Null means 100% of the parent
  /// (`ResponsiveContainer.tsx:99`).
  final double? height;

  /// Lower bound on the reported width (`ResponsiveContainer.tsx:100`).
  final double? minWidth;

  /// Lower bound on the reported height (`ResponsiveContainer.tsx:101`).
  final double? minHeight;

  /// Upper bound on the reported height (`ResponsiveContainer.tsx:102`), also
  /// applied to the aspect-derived height at `:74-76`.
  final double? maxHeight;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      var measuredWidth =
          width ??
          (constraints.hasBoundedWidth
              ? constraints.maxWidth.floorToDouble()
              : null);
      var measuredHeight =
          height ??
          (constraints.hasBoundedHeight
              ? constraints.maxHeight.floorToDouble()
              : null);

      final ratio = aspect;
      if (ratio != null && ratio > 0) {
        if (measuredWidth != null) {
          measuredHeight = measuredWidth / ratio;
        } else if (measuredHeight != null) {
          measuredWidth = measuredHeight * ratio;
        }
        final cap = maxHeight;
        if (cap != null && measuredHeight != null && measuredHeight > cap) {
          measuredHeight = cap;
        }
      }

      if (measuredWidth != null && minWidth != null) {
        measuredWidth = math.max(measuredWidth, minWidth!);
      }
      if (measuredHeight != null && minHeight != null) {
        measuredHeight = math.max(measuredHeight, minHeight!);
      }
      if (measuredHeight != null && maxHeight != null) {
        measuredHeight = math.min(measuredHeight, maxHeight!);
      }

      return builder(
        context,
        FluentResponsiveChartMetrics(
          width: measuredWidth,
          height: measuredHeight,
        ),
      );
    },
  );
}
