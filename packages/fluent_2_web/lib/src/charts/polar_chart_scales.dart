import 'dart:math' as math;

import 'axis/domain_range.dart';
import 'axis/tick_values.dart';
import 'internal/d3/array_stats.dart' as d3;
import 'internal/d3/js_math.dart' as d3;
import 'model/chart_common.dart';
import 'model/chart_value.dart';

/// Shape of a polar chart's grid rings (`PolarChart.types.ts:121-123`).
enum FluentPolarShape {
  /// Concentric circles. The upstream default.
  circle,

  /// Polygons whose vertices sit on the angular ticks.
  polygon,
}

/// Sweep direction of the angular axis (`PolarChart.types.ts:127-129`).
enum FluentPolarDirection {
  /// Datum 0 sits at twelve o'clock and angles increase clockwise.
  clockwise,

  /// Datum 0 sits at three o'clock and angles increase anti-clockwise. Default.
  counterclockwise,
}

/// Unit the angular tick labels are formatted in (`PolarChart.types.ts:141-144`).
enum FluentPolarAngularUnit {
  /// `45°`. The upstream default.
  degrees,

  /// `0.25π`.
  radians,
}

/// Which d3 scale family a polar axis resolves to (`PolarChart.utils.ts:136-154`).
enum FluentPolarScaleKind {
  /// A `ScaleBand` over string categories.
  category,

  /// A `ScaleLinear`.
  linear,

  /// A `ScaleLog`, base 10.
  log,

  /// A `ScaleTime` or `ScaleUtc`.
  date,
}

/// The tolerance every polar angle comparison uses (`PolarChart.utils.ts:28`).
const double kPolarEpsilon = 1e-6;

/// Infers the scale family for a polar axis from its values.
///
/// Ports `getScaleType` (`PolarChart.utils.ts:136-154`). Only `values[0]` is
/// inspected — a mixed series therefore takes the kind of whichever point
/// happens to come first. Reproduced verbatim: this is what makes a leading
/// string collapse a numeric axis to categories.
FluentPolarScaleKind polarScaleTypeOf(
  List<Object?> values, {
  FluentAxisScaleType? scaleType,
  bool supportsLog = false,
}) {
  final first = values.isEmpty ? null : values.first;
  if (first is num) {
    // `:145` — `supportsLog` is only passed by the radial axis.
    if (supportsLog && scaleType == FluentAxisScaleType.log) {
      return FluentPolarScaleKind.log;
    }
    return FluentPolarScaleKind.linear;
  }
  if (first is DateTime) {
    return FluentPolarScaleKind.date;
  }
  return FluentPolarScaleKind.category;
}

/// Computes the two-element domain of a continuous polar axis.
///
/// Ports `getContinuousScaleDomain` (`PolarChart.utils.ts:156-179`): values
/// invalid for the scale kind are filtered out, a **linear** domain is then
/// extended so that it always contains 0 (`:165-167`), and [rangeStart] /
/// [rangeEnd] override the respective end. Returns an empty list when either end
/// is unusable (`:175-177`).
List<Object> polarContinuousDomain(
  FluentPolarScaleKind kind,
  List<Object?> values, {
  Object? rangeStart,
  Object? rangeEnd,
}) {
  final scaleType = kind == FluentPolarScaleKind.log
      ? FluentAxisScaleType.log
      : null;
  final usable = values
      .where((v) => v != null && isValidDomainValue(v, scaleType))
      .cast<Object>()
      .toList();
  final (lo, hi) = d3.extent<Comparable<Object>>(usable);
  Object? min = lo;
  Object? max = hi;
  if (kind == FluentPolarScaleKind.linear) {
    // `:166` runs the extent again over [min, max, 0], which is what guarantees
    // a polar radial axis starts at the origin.
    final (lo2, hi2) = d3.extent<Comparable<Object>>(<Object>[?min, ?max, 0]);
    min = lo2;
    max = hi2;
  }
  if (!isInvalidChartValue(rangeStart)) {
    min = rangeStart;
  }
  if (!isInvalidChartValue(rangeEnd)) {
    max = rangeEnd;
  }
  if (isInvalidChartValue(min) || isInvalidChartValue(max)) {
    return const <Object>[];
  }
  return <Object>[min!, max!];
}

/// Converts degrees to radians (`PolarChart.utils.ts:181`).
double polarDegreesToRadians(double degrees) => degrees * math.pi / 180;

/// Converts radians to degrees (`PolarChart.utils.ts:183`).
double polarRadiansToDegrees(double radians) => radians * 180 / math.pi;

/// Folds a datum angle in degrees into the `[0, 360)` screen angle.
///
/// Ports `normalizeAngle` (`PolarChart.utils.ts:185-186`). A clockwise chart
/// uses the datum degrees directly; a counter-clockwise one reflects them
/// through 450, which is what puts datum 0 at three o'clock. The doubled modulo
/// is kept because it is what makes a negative input land in range.
double normalizePolarAngle(double degrees, FluentPolarDirection direction) {
  final raw = direction == FluentPolarDirection.clockwise
      ? degrees
      : 450 - degrees;
  return ((raw % 360) + 360) % 360;
}

/// Formats an angular value for a tick label or a popover.
///
/// Ports `formatAngle` (`PolarChart.utils.ts:248-256`). A [String] value passes
/// through untouched; a number is rounded to six decimal places by
/// [precisionRoundValue] (`utilities.ts:2555-2558`) and suffixed with `π` after
/// division by 180 in radian mode, or with `°` otherwise.
String formatPolarAngle(Object value, FluentPolarAngularUnit unit) {
  if (value is String) {
    return value;
  }
  final v = (value as num).toDouble();
  if (unit == FluentPolarAngularUnit.radians) {
    // 6 decimal places, matching `precisionRound(value / 180, 6)`.
    return '${d3.jsNumberToString(precisionRoundValue(v / 180, 6))}π';
  }
  return '${d3.jsNumberToString(precisionRoundValue(v, 6))}°';
}
