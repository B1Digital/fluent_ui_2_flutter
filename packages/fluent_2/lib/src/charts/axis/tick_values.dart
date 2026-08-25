import 'dart:math' as math;

import '../internal/d3/array_stats.dart' as d3;
import '../internal/d3/js_math.dart' as d3;
import '../internal/d3/ticks.dart' as d3;
import '../model/chart_common.dart';

/// Matches either the trailing zeros of an integer (group 1) or the digits
/// after a decimal point (group 2). Transcribed from `utilities.ts:2537`.
final RegExp _precisionPattern = RegExp(r'[1-9]([0]+$)|\.([0-9]*)');

/// Snaps a value that is within `1e-6` of an integer onto that integer.
///
/// Ports `handleFloatingPointPrecisionError` (`utilities.ts:651-654`, and
/// duplicated verbatim at
/// `chart-utilities/packages/charts/chart-utilities/src/formatter.ts:9-12`).
double handleFloatingPointPrecisionError(double n) {
  // 1e-6 is the epsilon at utilities.ts:653.
  final rounded = d3.jsRound(n);
  return (n - rounded).abs() < 1e-6 ? rounded : n;
}

/// Whether [n] is an exact power of ten.
///
/// Ports `isPowerOf10` (`utilities.ts:645-648`). Returns `false` for `0` and for
/// every negative, because `log10` yields `-Infinity` or `NaN` there and
/// `NaN % 1 == 0` is false in both languages.
bool isPowerOf10(double n) {
  final logged = d3.log10(handleFloatingPointPrecisionError(n));
  if (!logged.isFinite) {
    return false;
  }
  // 1 is the modulus at utilities.ts:647: a whole log10 means a whole decade.
  return logged % 1 == 0;
}

/// The number of digits [value] is meaningful to.
///
/// Ports `calculatePrecision` (`utilities.ts:2530-2548`). Trailing zeros on an
/// integer give a **negative** precision (`:2541-2542`), digits after a decimal
/// point give a positive one (`:2544-2545`), and anything else gives `0`
/// (`:2547`). Accepts [num] or [String], as the upstream union does.
///
/// The [num] branch renders through [d3.jsNumberToString] rather than
/// [Object.toString]: Dart prints `100.0` for the double `100`, which would
/// match the decimal group and answer `1` where upstream answers `-2`.
int calculatePrecision(Object value) {
  final text = value is num
      ? d3.jsNumberToString(value.toDouble())
      : value.toString();
  final match = _precisionPattern.firstMatch(text);
  if (match == null) {
    return 0;
  }
  final trailingZeros = match.group(1);
  if (trailingZeros != null && trailingZeros.isNotEmpty) {
    return -trailingZeros.length;
  }
  final decimals = match.group(2);
  if (decimals != null && decimals.isNotEmpty) {
    return decimals.length;
  }
  return 0;
}

/// Rounds [value] to [precision] digits, accepting a negative precision.
///
/// Ports `precisionRound` (`utilities.ts:2555-2558`). Named
/// `precisionRoundValue` so it does not collide with d3-format's own
/// `precisionRound`, which answers a different question. Rounds through
/// [d3.jsRound] because JavaScript rounds half-up while Dart rounds
/// half-away-from-zero.
double precisionRoundValue(double value, int precision, [int base = 10]) {
  // 10 is the default base at utilities.ts:2555; that branch goes through
  // [d3.pow10] because Dart's integer `math.pow` is exact where JavaScript's
  // `10 ** 23` is the double 1e23.
  final exp = base == 10
      ? d3.pow10(precision)
      : math.pow(base, precision).toDouble();
  return d3.jsRound(value * exp) / exp;
}

/// The rounded tick set used when `roundOffTickValues` is on.
///
/// Ports `calculateRoundedTicks` (`utilities.ts:663-672`). A degenerate extent
/// is floored or ceiled at zero depending on its sign, then d3's [d3.nice] and
/// [d3.ticks] do the work; the final tick is dropped when it overshoots a
/// maximum that is itself a power of ten.
List<double> calculateRoundedTicks(
  double minVal,
  double maxVal,
  int splitInto,
) {
  final finalYmin = minVal >= 0 && minVal == maxVal ? 0.0 : minVal;
  final finalYmax = minVal < 0 && minVal == maxVal ? 0.0 : maxVal;
  final ticksInterval = d3.nice(finalYmin, finalYmax, splitInto.toDouble());
  // `.toList()` is not cosmetic: [d3.ticks] builds its result with
  // `List.filled`, which is fixed-length, so [List.removeLast] below would throw
  // an UnsupportedError on it.
  final values = d3
      .ticks(ticksInterval.first, ticksInterval.last, splitInto.toDouble())
      .toList();
  if (values.isNotEmpty && values.last > finalYmax && isPowerOf10(finalYmax)) {
    values.removeLast();
  }
  return values;
}

/// The y-axis tick set, and the domain the scale is built from.
///
/// Ports `prepareDatapoints` (`utilities.ts:683-723`). Three consequences worth
/// stating, all load-bearing for the charts:
///
/// * when the data straddles zero, `0` is always a tick, because the walk starts
///   there and runs outwards in both directions;
/// * the last entry is greater than or equal to [maxVal], so the domain top is
///   stretched to the next whole interval;
/// * [splitInto] is a *target* interval count, so the returned length is at
///   least `splitInto + 1` and often more.
List<double> prepareDatapoints(
  double maxVal,
  double minVal,
  int splitInto, {
  required bool isIntegralDataset,
  bool roundedTicks = false,
}) {
  if (roundedTicks) {
    return calculateRoundedTicks(minVal, maxVal, splitInto);
  }
  final rawInterval = (maxVal - minVal) / splitInto;
  // A non-integral dataset keeps a sub-unit interval fractional and rounds
  // anything else up; 1 is the threshold at utilities.ts:695.
  final val = isIntegralDataset
      ? rawInterval.ceilToDouble()
      : (rawInterval >= 1 ? rawInterval.ceilToDouble() : rawInterval);

  final straddlesZero = minVal < 0 && maxVal >= 0;
  final points = <double>[straddlesZero ? 0 : minVal];
  // For an all-positive or all-negative dataset the seed is minVal itself, so a
  // second entry is pushed to guarantee at least one interval
  // (utilities.ts:710-711).
  if (points.first == minVal) {
    points.add(minVal + val);
  }
  if (straddlesZero) {
    while (points.last > minVal) {
      points.add(points.last - val);
    }
    final reversed = points.reversed.toList();
    points
      ..clear()
      ..addAll(reversed);
  }
  while (points.last < maxVal) {
    points.add(points.last + val);
  }
  return points;
}

/// Every multiple of [tickStep] anchored at [tick0] that lies inside
/// [scaleDomain].
///
/// Ports `generateLinearTicks` (`utilities.ts:2406-2420`). The domain is read
/// through [d3.min]/[d3.max], so a descending (right-to-left) domain works
/// unchanged. Both ends are rounded at
/// `max(calculatePrecision(tick0), calculatePrecision(tickStep))` to keep the
/// emitted values free of binary-floating-point dust.
///
/// That rounding is applied to the *index* bounds as well as to the values
/// (`:2411-2412`), which occasionally emits a tick outside the domain: with
/// `tick0` 0, `tickStep` 100 and a domain of `[10, 20]` the precision is 0, so
/// both `0.1` and `0.2` round to `0` and the single tick `0` comes back. That is
/// upstream behaviour and is reproduced rather than corrected.
List<double> generateLinearTicks(
  double tick0,
  double tickStep,
  List<double> scaleDomain,
) {
  final domainMin = d3.min<double>(scaleDomain)!;
  final domainMax = d3.max<double>(scaleDomain)!;
  final precision = math.max(
    calculatePrecision(tick0),
    calculatePrecision(tickStep),
  );

  final start = precisionRoundValue(
    (domainMin - tick0) / tickStep,
    precision,
  ).ceil();
  final end = precisionRoundValue(
    (domainMax - tick0) / tickStep,
    precision,
  ).floor();

  final ticks = <double>[];
  for (var i = start; i <= end; i++) {
    ticks.add(precisionRoundValue(tick0 + i * tickStep, precision));
  }
  return ticks;
}

/// Raises [t] to a power of ten the way JavaScript's `10 ** t` does.
///
/// Integral exponents go through [d3.pow10], which builds the value from its
/// decimal string and is therefore exact at every decade; anything else falls
/// back to [math.pow] (spec section 4.2, risk 1).
double _pow10Of(double t) =>
    t == t.roundToDouble() ? d3.pow10(t.toInt()) : math.pow(10, t).toDouble();

/// The custom tick values for a numeric axis, or `null` when [tickStep] does
/// not describe one.
///
/// Ports `generateNumericTicks` (`utilities.ts:2465-2496`). On a log scale a
/// numeric step is a step *in log space* — `tickStep` 2 puts ticks at 1, 100,
/// 10000 (`types/DataPoint.ts:1099-1101`) — while a `'L<f>'` string step is a
/// step in value space (`:1103`).
///
/// [tickStep] is the `string | number | undefined` union at `:2468` and [tick0]
/// the `number | Date | undefined` union at `:2469`, so both arrive as [Object].
List<double>? generateNumericTicks(
  FluentAxisScaleType? scaleType,
  Object tickStep,
  Object? tick0,
  List<double> scaleDomain,
) {
  final refTick = tick0 is num ? tick0.toDouble() : 0.0;

  if (scaleType == FluentAxisScaleType.log) {
    if (tickStep is num && tickStep > 0) {
      return generateLinearTicks(
        refTick,
        tickStep.toDouble(),
        scaleDomain.map(d3.log10).toList(),
      ).map(_pow10Of).toList();
    }
    // The emptiness test is not in the upstream condition at :2482: JavaScript
    // reads `''[0]` as `undefined`, where Dart's [String.operator []] throws.
    if (tickStep is String && tickStep.isNotEmpty) {
      final prefix = tickStep[0];
      // 0 is the fallback at :2484 for a tail that is not a number, and it
      // fails the `> 0` test below. `isFinite` stands in for the `isFinite`
      // half of upstream's `isNumber`
      // (`chart-utilities/packages/charts/chart-utilities/src/PlotlySchemaConverter.ts:41`),
      // which Dart's [double.tryParse] does not apply of its own accord.
      final stepValue = double.tryParse(tickStep.substring(1)) ?? 0.0;
      if (prefix == 'L' && stepValue > 0 && stepValue.isFinite) {
        return generateLinearTicks(refTick, stepValue, scaleDomain);
      }
    }
    return null;
  }

  if (tickStep is num && tickStep > 0) {
    return generateLinearTicks(refTick, tickStep.toDouble(), scaleDomain);
  }
  return null;
}

/// Rebuilds [source] with [month] as its one-based month, matching JavaScript's
/// `Date.prototype.setMonth` overflow semantics: month 13 becomes January of the
/// next year, month 0 December of the previous one, and day 31 in a 30-day month
/// rolls into the next month.
DateTime _withMonth(DateTime source, int month, {required bool useUtc}) {
  return useUtc
      ? DateTime.utc(
          source.year,
          month,
          source.day,
          source.hour,
          source.minute,
          source.second,
          source.millisecond,
          source.microsecond,
        )
      : DateTime(
          source.year,
          month,
          source.day,
          source.hour,
          source.minute,
          source.second,
          source.millisecond,
          source.microsecond,
        );
}

/// The last day of the month before [source]'s, keeping its time of day —
/// JavaScript's `setDate(0)`, which Dart spells as day zero.
DateTime _toPreviousMonthEnd(DateTime source, {required bool useUtc}) {
  return useUtc
      ? DateTime.utc(
          source.year,
          source.month,
          0,
          source.hour,
          source.minute,
          source.second,
          source.millisecond,
          source.microsecond,
        )
      : DateTime(
          source.year,
          source.month,
          0,
          source.hour,
          source.minute,
          source.second,
          source.millisecond,
          source.microsecond,
        );
}

/// Ticks every [months] months from [tick0], clipped to [domain].
///
/// Ports `generateMonthlyTicks` (`utilities.ts:2423-2463`), including the
/// rollover guard at `:2450-2452`: when adding whole months to a month-end
/// anchor lands in the following month, the tick is snapped back to the previous
/// month's last day, so a January 31 anchor gives February 29 in a leap year.
///
/// The anchor is normalised to the clock [useUtc] selects before anything is
/// read from it, because upstream pairs `getUTCMonth` with `setUTCMonth`
/// (`:2432-2433`) and so reads every field of the date on one clock.
///
/// [months] must be positive; upstream neither checks nor survives a
/// non-positive step, because the walk at `:2437-2440` would never advance.
List<DateTime> generateMonthlyTicks(
  DateTime tick0,
  int months,
  List<DateTime> domain, {
  bool useUtc = false,
}) {
  assert(months > 0, 'A monthly tick step of $months would never terminate.');
  final domainMin = d3.min<DateTime>(domain)!.millisecondsSinceEpoch;
  final domainMax = d3.max<DateTime>(domain)!.millisecondsSinceEpoch;
  final anchor = useUtc ? tick0.toUtc() : tick0.toLocal();

  // The earliest tick index at or before domainMin (`:2436-2440`). Stepping the
  // running date rather than the anchor is upstream's own formulation, and it
  // matters: [_withMonth] normalises an overflowing day as it goes.
  var start = 0;
  var firstTick = anchor;
  while (firstTick.millisecondsSinceEpoch > domainMin) {
    firstTick = _withMonth(firstTick, firstTick.month - months, useUtc: useUtc);
    start -= months;
  }

  // Zero-based, as `getMonth` is, so that the modular comparison below reads the
  // same as `:2450`.
  final baseMonth = anchor.month - 1;
  final ticks = <DateTime>[];
  for (var i = start; ; i += months) {
    var tickDate = _withMonth(anchor, baseMonth + i + 1, useUtc: useUtc);
    // 12 is the month count at `:2450`; the doubled modulus is upstream's way of
    // making a negative index land in `0..11`, which Dart's own `%` would do
    // unaided but is kept for transcription fidelity.
    final expectedMonth = ((baseMonth + i) % 12 + 12) % 12;
    if (tickDate.month - 1 != expectedMonth) {
      tickDate = _toPreviousMonthEnd(tickDate, useUtc: useUtc);
    }
    if (tickDate.millisecondsSinceEpoch > domainMax) {
      break;
    }
    if (tickDate.millisecondsSinceEpoch >= domainMin) {
      ticks.add(tickDate);
    }
  }
  return ticks;
}

/// The custom tick values for a date axis, or `null` when [tickStep] does not
/// describe one.
///
/// Ports `generateDateTicks` (`utilities.ts:2498-2521`). A numeric step is a
/// millisecond interval (`:2506-2511`); a `'M<n>'` string step is a whole-month
/// interval (`:2514-2519`). The fallback anchor is `DEFAULT_DATE_STRING`
/// (`:2504`, the constant at `:91`) read as **UTC** midnight, which is how
/// JavaScript parses a bare `YYYY-MM-DD` and why this is built with
/// [DateTime.utc] rather than [DateTime.parse].
///
/// The millisecond branch inherits [generateLinearTicks]' precision quirk, and
/// at epoch magnitudes that quirk is severe: a step of 86 400 000 has precision
/// -5, which rounds every index bound of a few-day domain to zero and yields one
/// tick, a millisecond below the anchor. That is upstream behaviour, verified by
/// running a transcription of `:2406-2421` under node, and is reproduced rather
/// than corrected. Each tick is truncated towards zero rather than rounded,
/// because that is what `new Date(t)` does to a fractional millisecond
/// (`TimeClip`, ECMA-262 21.4.1.31).
///
/// [tickStep] is the `string | number | undefined` union at `:2499` and [tick0]
/// the `number | Date | undefined` union at `:2500`, so both arrive as [Object].
List<DateTime>? generateDateTicks(
  Object tickStep,
  Object? tick0,
  List<DateTime> domain, {
  bool useUtc = false,
}) {
  final refTick = tick0 is DateTime ? tick0 : DateTime.utc(2000);

  if (tickStep is num && tickStep > 0) {
    return generateLinearTicks(
          refTick.millisecondsSinceEpoch.toDouble(),
          tickStep.toDouble(),
          domain.map((d) => d.millisecondsSinceEpoch.toDouble()).toList(),
        )
        .map(
          (ms) =>
              DateTime.fromMillisecondsSinceEpoch(ms.truncate(), isUtc: useUtc),
        )
        .toList();
  }

  // The emptiness test is not in the upstream condition at `:2514`: JavaScript
  // reads `''[0]` as `undefined`, where Dart's [String.operator []] throws.
  if (tickStep is String && tickStep.isNotEmpty) {
    final prefix = tickStep[0];
    // 0 is the fallback at `:2516` for a tail that is not a number. `isFinite`
    // stands in for the `isFinite` half of upstream's `isNumber`
    // (`chart-utilities/packages/charts/chart-utilities/src/PlotlySchemaConverter.ts:41`),
    // which Dart's [double.tryParse] does not apply of its own accord and
    // without which `'MInfinity'` would reach [double.toInt] and throw.
    final count = double.tryParse(tickStep.substring(1)) ?? 0;
    if (prefix == 'M' &&
        count > 0 &&
        count.isFinite &&
        count == count.roundToDouble()) {
      return generateMonthlyTicks(
        refTick,
        count.toInt(),
        domain,
        useUtc: useUtc,
      );
    }
  }
  return null;
}
