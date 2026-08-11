import 'dart:math' as math;

import '../../axis/tick_values.dart'
    show calculatePrecision, precisionRoundValue;
import '../d3/array_stats.dart' as d3;
import '../d3/bin.dart' as d3;
import '../d3/ticks.dart' as d3;
import 'predicates.dart';

/// Reads one datum as a `double` for `d3.Binner`.
///
/// The kernel's default accessor is `d as double` (`internal/d3/bin.dart:69`),
/// which throws on an `int`; every value reaching here has already been
/// filtered to a [num] by [createBins].
double _asDouble(Object d) => (d as num).toDouble();

/// Finds the bin a value falls in, or -1 (`PlotlySchemaAdapter.ts:3364-3380`).
///
/// The last bin is closed on both sides and every earlier bin is half-open
/// (`:3378`), which is what stops the maximum datum landing outside every bin.
int findBinIndex(List<Object> bins, Object? value, {required bool isString}) {
  if (value == null) {
    // `PlotlySchemaAdapter.ts:3369-3371`.
    return -1;
  }

  if (isString) {
    // `PlotlySchemaAdapter.ts:3374`: each bin is a `String` list.
    for (var index = 0; index < bins.length; index++) {
      final bin = bins[index];
      if (bin is List<Object?> && bin.contains(value)) {
        return index;
      }
    }
    return -1;
  }

  // `PlotlySchemaAdapter.ts:3375-3379` casts blindly to number; a non-numeric
  // value fails every comparison in JavaScript, which is -1 here.
  if (value is! num) {
    return -1;
  }
  for (var index = 0; index < bins.length; index++) {
    final bin = bins[index];
    if (bin is! d3.Bin) {
      continue;
    }
    // 1 turns the length into the last index (`:3378`).
    final isLast = index == bins.length - 1;
    if (value >= bin.x0 && (isLast ? value <= bin.x1 : value < bin.x1)) {
      return index;
    }
  }
  return -1;
}

/// The width of one numeric bin (`PlotlySchemaAdapter.ts:3382-3384`).
double getBinSize(d3.Bin bin) => bin.x1 - bin.x0;

/// The centre of one numeric bin (`PlotlySchemaAdapter.ts:3386-3388`).
///
/// 2 is the divisor of a midpoint, at `:3387`.
double getBinCenter(d3.Bin bin) => (bin.x1 + bin.x0) / 2;

/// Builds the bins a histogram trace implies
/// (`PlotlySchemaAdapter.ts:3391-3441`).
///
/// Returns a `List<List<String>>` for a string column and a `List<d3.Bin>` for
/// a numeric one, hence the `List<Object>` return type. Date axes are
/// unsupported upstream too (`:3390`'s `TODO`).
///
/// [binStart], [binEnd] and [binSize] are `Object?` because the schema declares
/// them as `number | string` and upstream honours **only** the numeric form
/// (`typeof … === 'number'` at `:3403-3405`, `:3415-3416`, `:3420`); a string
/// bin setting is silently ignored. // parity: PlotlySchemaAdapter.ts:3403
List<Object> createBins(
  Object? data, {
  Object? binStart,
  Object? binEnd,
  Object? binSize,
}) {
  // `PlotlySchemaAdapter.ts:3397-3399`.
  if (data is! List<Object?> || data.isEmpty) {
    return const <Object>[];
  }

  if (isStringArray(data)) {
    // `PlotlySchemaAdapter.ts:3401-3407`.
    final categories = <String>{for (final value in data) '$value'}.toList();
    // 0 is the default start at `:3403`.
    final start = binStart is num ? binStart.ceilToDouble() : 0.0;
    // `:3404` adds one because `slice` is exclusive of its end.
    final stop = binEnd is num
        ? binEnd.floorToDouble() + 1
        : categories.length.toDouble();
    // 1 is the default step at `:3405`.
    final step = binSize is num ? binSize.toDouble() : 1.0;
    return <Object>[
      for (final offset in d3.range(start, stop, step))
        // `slice` clamps a negative or overlong index; `sublist` throws, so the
        // clamp is written out. 0 and `categories.length` are the bounds
        // `Array.prototype.slice` applies. This is not full `slice` parity — a
        // negative index counts from the end there — but a negative `binStart`
        // is not a bin specification any histogram means, and a RangeError
        // reaching a consumer's build method is the worse failure.
        categories.sublist(
          offset.toInt().clamp(0, categories.length),
          (offset + step).toInt().clamp(0, categories.length),
        ),
    ];
  }

  final numbers = <Object>[
    for (final value in data)
      if (value is num) value,
  ];

  if (numbers.isEmpty) {
    // Neither a string array nor a numeric one — an array of objects or
    // booleans, which only untrusted JSON produces. Upstream hands d3-bin a
    // NaN domain here and gets one degenerate bin back; this returns none,
    // because the downstream `findBinIndex` answers -1 for every datum either
    // way and a NaN domain is one `.floor()` away from a Dart-only crash.
    return const <Object>[];
  }

  // `PlotlySchemaAdapter.ts:3410-3413`.
  // ponytail: `d3.nice` is d3-array's unbounded loop; `ScaleLinear.nice` is the
  // same algorithm capped at ten iterations. They agree on every finite domain,
  // and this avoids constructing a scale purely to read its domain back.
  final (low, high) = d3.extent<num>(numbers);
  // 10 is `scaleLinear.nice()`'s default tick count (`d3-scale/src/linear.js`),
  // which `:3412` takes by calling `nice` with no argument.
  final niced = d3.nice((low ?? 0).toDouble(), (high ?? 0).toDouble(), 10);

  // `PlotlySchemaAdapter.ts:3415-3416`.
  final minVal = binStart is num ? binStart.toDouble() : niced[0];
  final maxVal = binEnd is num ? binEnd.toDouble() : niced[1];

  if (binSize is num && binSize > 0) {
    // `PlotlySchemaAdapter.ts:3420-3438`.
    final size = binSize.toDouble();
    final thresholds = <double>[];
    // `:3422`: the coarser of the two precisions, so `0.1` steps from `-0.3` do
    // not accumulate a binary-floating-point drift into the last threshold.
    final precision = math.max(
      calculatePrecision(minVal),
      calculatePrecision(size),
    );
    var threshold = precisionRoundValue(minVal, precision);
    final limit = precisionRoundValue(maxVal + size, precision);
    while (threshold < limit) {
      thresholds.add(threshold);
      threshold = precisionRoundValue(threshold + size, precision);
    }

    if (thresholds.isEmpty) {
      // `:3430-3431` would index `undefined` here and hand d3-bin a NaN domain,
      // which yields no bins at all. Returning empty is the same outcome
      // without a Dart range error.
      return const <Object>[];
    }

    final bins = d3
        .bin()
        .domain(thresholds.first, thresholds.last)
        .thresholdsList(thresholds)
        .call(numbers, value: _asDouble);

    // `PlotlySchemaAdapter.ts:3434-3437`, verbatim: "When the domain ends at
    // the last threshold (maxVal), d3Bin creates an extra final bin where both
    // x0 and x1 are equal to maxVal and inclusive. The previous bin also has x1
    // equal to maxVal, but it is exclusive. To maintain consistent bin widths,
    // remove the final bin, making the previous bin the last one, with both x0
    // and x1 inclusive."
    //
    // `[].slice(0, -1)` is `[]` at `:3438`, so an empty result passes straight
    // through. 1 is that single trailing bin.
    return bins.isEmpty
        ? const <Object>[]
        : <Object>[...bins.sublist(0, bins.length - 1)];
  }

  // `PlotlySchemaAdapter.ts:3440`. Upstream leaves d3-bin's default threshold
  // function in place, which is Sturges' rule — `d3-array/src/bin.js:13`. The
  // port's `Binner` requires a threshold list or count (`internal/d3/bin.dart:
  // 30-34` states the automatic path is unported), so the rule is applied here
  // rather than being silently skipped: without it `Binner.call` throws on a
  // null count and every histogram with no explicit `binSize` fails.
  //
  // `d3-array/src/threshold/sturges.js:4` is
  // `max(1, ceil(log(count(values)) / LN2) + 1)`, where `count` skips
  // non-numeric data — which `numbers` has already dropped, so the length is
  // that count. 1 is the floor, and 1 is also the constant Sturges adds.
  final sturges = math.max(1, (math.log(numbers.length) / math.ln2).ceil() + 1);
  return <Object>[
    ...d3
        .bin()
        .domain(minVal, maxVal)
        .thresholdCount(sturges)
        .call(numbers, value: _asDouble),
  ];
}

/// Reduces one bin's members to a single value
/// (`PlotlySchemaAdapter.ts:3443-3456`).
///
/// The default arm is the **count**, not a sum, so an absent `histfunc` counts
/// (`:3453-3454`).
double calculateHistFunc(String? histfunc, List<double> bin) {
  switch (histfunc) {
    case 'sum':
      // `:3446`. `d3.sum` skips falsy coerced values, including 0.
      return d3.sum(bin);
    case 'avg':
      // `:3448`. 0 is the empty-bin answer, not NaN.
      return bin.isEmpty ? 0 : d3.sum(bin) / bin.length;
    case 'min':
      // `:3450`. 0 is the `??` fallback for an empty bin.
      return d3.min<num>(bin)?.toDouble() ?? 0;
    case 'max':
      // `:3452`. 0 as above.
      return d3.max<num>(bin)?.toDouble() ?? 0;
    default:
      // `:3454`.
      return bin.length.toDouble();
  }
}

/// Normalises one bin's value (`PlotlySchemaAdapter.ts:3458-3477`).
///
/// [dy] is 1 for a one-dimensional histogram and the second bin width for a
/// `histogram2d` heatmap (`:3463`).
double calculateHistNorm(
  String? histnorm,
  double value,
  double total,
  double dx, [
  double dy = 1,
]) {
  switch (histnorm) {
    case 'percent':
      // `:3467`. 0 guards the empty figure; 100 is the percentage scale.
      return total == 0 ? 0 : (value / total) * 100;
    case 'probability':
      // `:3469`.
      return total == 0 ? 0 : value / total;
    case 'density':
      // `:3471`.
      return dx * dy == 0 ? 0 : value / (dx * dy);
    case 'probability density':
      // `:3473`.
      return total * dx * dy == 0 ? 0 : value / (total * dx * dy);
    default:
      // `:3475`.
      return value;
  }
}
