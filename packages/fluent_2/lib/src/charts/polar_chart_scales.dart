import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'axis/domain_range.dart';
import 'axis/tick_format.dart';
import 'axis/tick_values.dart';
import 'internal/d3/array_stats.dart' as d3;
import 'internal/d3/format.dart' as d3;
import 'internal/d3/js_math.dart' as d3;
import 'internal/d3/scale.dart';
import 'internal/d3/scale_band.dart' as d3;
import 'internal/d3/scale_linear.dart' as d3;
import 'internal/d3/scale_log.dart' as d3;
import 'internal/d3/scale_time.dart' as d3;
import 'internal/d3/time_format.dart' as d3;
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

/// Default number of radial ticks (`PolarChart.utils.ts:76`).
const int kPolarRadialTickCount = 4;

/// A resolved radial axis: the scale plus its tick values and rendered labels.
@immutable
class FluentPolarRadialScale {
  /// Creates a resolved radial axis.
  const FluentPolarRadialScale({
    required this.kind,
    required this.scale,
    required this.tickValues,
    required this.tickLabels,
  });

  /// Which scale family [scale] belongs to.
  final FluentPolarScaleKind kind;

  /// The underlying d3 scale, mapping a datum to a radius in device pixels.
  final Scale scale;

  /// Values the radial grid rings and tick marks are drawn at.
  final List<Object> tickValues;

  /// Rendered label per entry of [tickValues], same length and order.
  final List<String> tickLabels;

  /// Radius of [value], or `null` when it is outside a band domain.
  double? radiusOf(Object value) => scale(value);
}

/// Builds the radial axis.
///
/// Ports `createRadialScale` (`PolarChart.utils.ts:30-134`). A categorical axis is
/// a [d3.ScaleBand] with `paddingInner(1)` (`:51-54`), which gives zero bandwidth
/// and puts category *i* at `inner + i * step`. Every other kind is a continuous
/// scale that is `nice()`d in place (`:72-74`) before its ticks are read.
///
/// [tickStep] is the `number | string` union at `:41` and [tick0] the
/// `number | Date` union at `:42`, so both arrive as [Object].
FluentPolarRadialScale createPolarRadialScale(
  FluentPolarScaleKind kind,
  List<Object> domain,
  List<double> range, {
  bool useUtc = false,
  int? tickCount,
  List<Object>? tickValues,
  List<String>? tickText,
  String? tickFormat,
  String? culture,
  Object? tickStep,
  Object? tick0,
  FluentDateTimeFormatOptions? dateLocalizeOptions,
}) {
  // `:57-59` — a custom label is used only when BOTH `tickValues` and `tickText`
  // were supplied and the entry at that index is usable.
  String? customLabel(int index) {
    if (tickValues == null || tickText == null) {
      return null;
    }
    // JavaScript reads a past-the-end index as `undefined`, which
    // `isInvalidValue` rejects; Dart would throw, so the bound is explicit.
    if (index >= tickText.length) {
      return null;
    }
    if (isInvalidChartValue(tickText[index])) {
      return null;
    }
    return tickText[index];
  }

  if (kind == FluentPolarScaleKind.category) {
    final band = d3.scaleBand()
      ..domainOf(domain)
      ..rangeOf(range)
      // 1 is the literal `paddingInner(1)` of `:54`.
      ..paddingInner(1);
    final values = tickValues ?? domain;
    return FluentPolarRadialScale(
      kind: kind,
      scale: band,
      tickValues: values,
      tickLabels: <String>[
        for (var i = 0; i < values.length; i++)
          customLabel(i) ?? values[i].toString(),
      ],
    );
  }

  // `:65-74` — pick the scale, then domain, then range, then nice(), in that
  // order. The three families are separated here rather than behind a `dynamic`
  // call because `domainOf` is typed per family.
  final Scale scale;
  if (kind == FluentPolarScaleKind.date) {
    final timeScale = useUtc ? d3.scaleUtc() : d3.scaleTime();
    timeScale
      ..domainOfDates(domain.cast<DateTime>())
      ..rangeOf(range)
      ..nice();
    scale = timeScale;
  } else {
    final numericDomain = <double>[
      for (final value in domain) (value as num).toDouble(),
    ];
    if (kind == FluentPolarScaleKind.log) {
      final logScale = d3.scaleLog();
      logScale
        ..domainOf(numericDomain)
        ..rangeOf(range)
        ..nice();
      scale = logScale;
    } else {
      final linearScale = d3.scaleLinear();
      linearScale
        ..domainOf(numericDomain)
        ..rangeOf(range)
        ..nice();
      scale = linearScale;
    }
  }

  final count = tickCount ?? kPolarRadialTickCount;
  // `:78` — an explicit tick list seeds the custom values and a tick step then
  // overwrites it.
  var customTickValues = tickValues;
  final String Function(Object value, int index) format;

  if (kind == FluentPolarScaleKind.date) {
    // `:80-91` — scan the *unparameterised* ticks to find the format level span.
    // 100 and -1 are the sentinels of `:80-81`, chosen to lie outside the 0-7
    // level range so an empty tick list leaves them untouched.
    var lowest = 100;
    var highest = -1;
    for (final tick in scale.ticks()) {
      final level = getDateFormatLevel(tick as DateTime, useUtc: useUtc);
      if (level > highest) {
        highest = level;
      }
      if (level < lowest) {
        lowest = level;
      }
    }
    final options =
        dateLocalizeOptions ?? multiLevelDateTimeFormatOptions(lowest, highest);
    final strftime = tickFormat == null
        ? null
        : (useUtc ? d3.utcFormat(tickFormat) : d3.timeFormat(tickFormat));
    format = (Object value, int index) {
      final custom = customLabel(index);
      if (custom != null) {
        return custom;
      }
      // `:98` — a d3 strftime string only applies when no culture was given.
      if (isInvalidChartValue(culture) && strftime != null) {
        return strftime(value as DateTime);
      }
      return formatDateToLocaleString(
        value as DateTime,
        culture: culture,
        useUtc: useUtc,
        showTZname: false,
        options: options,
      );
    };
    if (tickStep != null) {
      customTickValues = generateDateTicks(
        tickStep,
        tick0,
        scale.domain.cast<DateTime>(),
        useUtc: useUtc,
      )?.cast<Object>();
    }
  } else {
    // `:111` captures the scale's own formatter ONCE, before any custom values.
    final defaultFormat = scale.tickFormat(count);
    final numberFormat = tickFormat == null ? null : d3.format(tickFormat);
    format = (Object value, int index) {
      final custom = customLabel(index);
      if (custom != null) {
        return custom;
      }
      if (numberFormat != null) {
        return numberFormat(value as num);
      }
      // `:120` — a blanked tick (a log sub-tick) stays blank; everything else
      // goes through the locale formatter rather than the d3 one.
      return defaultFormat(value) == ''
          ? ''
          : formatToLocaleString(value, culture: culture);
    };
    if (tickStep != null) {
      customTickValues = generateNumericTicks(
        // `:124` casts the raw scale type across, so only `log` is ever
        // recognised by the tick generator.
        kind == FluentPolarScaleKind.log ? FluentAxisScaleType.log : null,
        tickStep,
        tick0,
        <double>[for (final v in scale.domain) (v as num).toDouble()],
      )?.cast<Object>();
    }
  }

  // `:131` — the generated values only apply when a custom list is absent.
  final values = customTickValues ?? scale.ticks(count);
  return FluentPolarRadialScale(
    kind: kind,
    scale: scale,
    tickValues: values,
    tickLabels: <String>[
      for (var i = 0; i < values.length; i++) format(values[i], i),
    ],
  );
}

/// Default number of angular ticks (`PolarChart.utils.ts:239`).
const int kPolarAngularTickCount = 8;

/// A resolved angular axis: the datum-to-radians mapping plus its ticks.
@immutable
class FluentPolarAngularScale {
  /// Creates a resolved angular axis.
  const FluentPolarAngularScale({
    required this.radiansOf,
    required this.tickValues,
    required this.tickLabels,
  });

  /// Maps a datum theta — a category name or a number of degrees — to screen
  /// radians.
  final double Function(Object value) radiansOf;

  /// Values the spokes and angular labels are drawn at, always in datum units.
  final List<Object> tickValues;

  /// Rendered label per entry of [tickValues], same length and order.
  final List<String> tickLabels;
}

/// Builds the angular axis.
///
/// Ports `createAngularScale` (`PolarChart.utils.ts:188-246`). A categorical
/// axis divides the full turn into `360 / domain.length` and places category
/// *i* at `i * period` (`:208-217`). A numeric axis ignores its domain entirely
/// and maps the raw datum degrees (`:242`) — the domain is computed upstream
/// only so that `getScaleType` can classify it.
///
/// [tickStep] is the `number | string` union at `:197` and [tick0] the
/// `number | Date` union at `:198`, so both arrive as [Object].
FluentPolarAngularScale createPolarAngularScale(
  FluentPolarScaleKind kind,
  List<Object> domain, {
  int? tickCount,
  List<Object>? tickValues,
  List<String>? tickText,
  String? tickFormat,
  Object? tickStep,
  Object? tick0,
  FluentPolarDirection direction = FluentPolarDirection.counterclockwise,
  FluentPolarAngularUnit unit = FluentPolarAngularUnit.degrees,
}) {
  // `:211` / `:225` — a custom label is used only when BOTH `tickValues` and
  // `tickText` were supplied and the entry at that index is usable.
  String? customLabel(int index) {
    if (tickValues == null || tickText == null) {
      return null;
    }
    // JavaScript reads a past-the-end index as `undefined`, which
    // `isInvalidValue` rejects; Dart would throw, so the bound is explicit.
    if (index >= tickText.length) {
      return null;
    }
    if (isInvalidChartValue(tickText[index])) {
      return null;
    }
    return tickText[index];
  }

  if (kind == FluentPolarScaleKind.category) {
    final indexOf = <Object, int>{
      for (var i = 0; i < domain.length; i++) domain[i]: i,
    };
    // `:208` — an empty domain divides by zero here exactly as upstream does;
    // the resulting NaN angle is filtered out later by `isPlottable`.
    final period = 360 / domain.length;
    final values = tickValues ?? domain;
    return FluentPolarAngularScale(
      // `:217` — a category the domain never saw indexes to `undefined`, and
      // `undefined * period` is NaN, which `isPlottable` later filters out.
      radiansOf: (value) => polarDegreesToRadians(
        normalizePolarAngle(
          (indexOf[value]?.toDouble() ?? double.nan) * period,
          direction,
        ),
      ),
      tickValues: values,
      tickLabels: <String>[
        for (var i = 0; i < values.length; i++)
          customLabel(i) ?? values[i].toString(),
      ],
    );
  }

  var customTickValues = tickValues;
  if (tickStep != null) {
    // `:234-237` — the generated domain is a full turn minus one epsilon so
    // that the closing tick is not duplicated, and radian steps come back as
    // degrees.
    final radians = unit == FluentPolarAngularUnit.radians;
    final generated = generateNumericTicks(null, tickStep, tick0, <double>[
      0,
      (radians ? 2 * math.pi : 360) - kPolarEpsilon,
    ]);
    customTickValues = generated
        ?.map<Object>((v) => radians ? polarRadiansToDegrees(v) : v)
        .toList();
  }
  // `:239` — the default of eight ticks puts a spoke every 45 degrees.
  final values =
      customTickValues ??
      d3
          .range(0, 360, 360 / (tickCount ?? kPolarAngularTickCount))
          .cast<Object>();

  final numberFormat = tickFormat == null ? null : d3.format(tickFormat);
  return FluentPolarAngularScale(
    radiansOf: (value) => polarDegreesToRadians(
      normalizePolarAngle((value as num).toDouble(), direction),
    ),
    tickValues: values,
    tickLabels: <String>[
      for (var i = 0; i < values.length; i++)
        customLabel(i) ??
            (numberFormat != null
                ? numberFormat(values[i] as num)
                : formatPolarAngle(values[i], unit)),
    ],
  );
}
