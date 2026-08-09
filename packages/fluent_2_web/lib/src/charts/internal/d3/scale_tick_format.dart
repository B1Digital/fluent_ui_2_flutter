import 'dart:math' as math;

import 'format.dart' as fmt;
import 'format_spec.dart';
import 'ticks.dart' as numeric;

/// A formatter sized to the tick step over `[start, stop]`
/// (`d3-scale/src/tickFormat.js:4-29`).
///
/// This is what `scale.tickFormat(count)` returns, and `utilities.ts:307` and
/// `:878` both call it, so it draws the tick labels of every numeric axis that
/// does not supply its own formatter.
///
/// [count] is the requested tick count, forwarded to
/// [numeric.tickStep]; [specifier] defaults to `,f` per `:7`. The returned
/// closure accepts an [Object] to match the contract, and casts to [num] — the
/// only thing a numeric axis ever passes.
String Function(Object value) scaleTickFormat(
  double start,
  double stop,
  int count, [
  String? specifier,
]) {
  final step = numeric.tickStep(start, stop, count.toDouble());
  final spec = formatSpecifier(specifier ?? ',f');
  switch (spec.type) {
    case 's':
      final value = math.max(start.abs(), stop.abs());
      if (spec.precision == null) {
        // `:11`. The precision helpers are typed `double` because the
        // `exponent()` behind them answers NaN for zero and non-finite input,
        // so the guard is live rather than dead code.
        final precision = fmt.precisionPrefix(step, value);
        if (!precision.isNaN) {
          spec.precision = precision.toInt();
        }
      }
      // `:12` hands the mutated specifier to formatPrefix; ours takes the
      // string form, which round-trips through FormatSpecifier.toString.
      final f = fmt.formatPrefix(spec.toString(), value);
      return (Object v) => f(v as num);
    case '':
    case 'e':
    case 'g':
    case 'p':
    case 'r':
      if (spec.precision == null) {
        // `:19`, where `precision - (specifier.type === "e")` subtracts the
        // coerced boolean: one significant digit goes to the exponent itself.
        final precision = fmt.precisionRound(
          step,
          math.max(start.abs(), stop.abs()),
        );
        if (!precision.isNaN) {
          spec.precision = precision.toInt() - (spec.type == 'e' ? 1 : 0);
        }
      }
    case 'f':
    case '%':
      if (spec.precision == null) {
        // `:24` subtracts two for `%`, because scaling by a hundred shifts the
        // decimal point two places left.
        final precision = fmt.precisionFixed(step);
        if (!precision.isNaN) {
          spec.precision = precision.toInt() - (spec.type == '%' ? 2 : 0);
        }
      }
  }
  // `:28`. FormatSpecifier.toString clamps a negative precision back to zero
  // on the way out, which is what makes the `%` subtraction safe.
  final f = fmt.formatFrom(spec);
  return (Object v) => f(v as num);
}
