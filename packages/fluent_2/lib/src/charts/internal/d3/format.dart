import 'dart:math' as math;

import 'format_spec.dart';
import 'js_math.dart';

/// Formats a number as a string.
typedef NumberFormatter = String Function(num value);

/// The SI prefix ladder (`d3-format/src/locale.js:11`), indexed
/// `siPrefixes[8 + exponent ~/ 3]`.
///
/// Index 6 is U+00B5 MICRO SIGN, not U+03BC GREEK SMALL LETTER MU. They render
/// alike and compare unequal.
const List<String> siPrefixes = <String>[
  'y',
  'z',
  'a',
  'f',
  'p',
  'n',
  'µ',
  'm',
  '',
  'k',
  'M',
  'G',
  'T',
  'P',
  'E',
  'Z',
  'Y',
];

/// U+2212 MINUS SIGN, the default locale's negative marker
/// (`d3-format/src/locale.js:20`). It is **not** ASCII hyphen-minus, and the
/// default locale (`d3-format/src/defaultLocale.js:7-11`) does not override it.
const String minusSign = '−';

// The default locale sets only thousands, grouping and currency
// (`defaultLocale.js:7-11`); every other field keeps the `locale.js:14-21`
// default. `numerals` stays the identity function, so there is nothing to port
// for it.
const String _thousands = ',';
const List<int> _grouping = <int>[3];
const String _currencyPrefix = r'$';
const String _currencySuffix = '';
const String _decimal = '.';
const String _percent = '%';
const String _nan = 'NaN';

/// U+221E INFINITY, which `Number.prototype.toLocaleString('en')` returns for a
/// non-finite number. `formatDecimal.js:2-3` routes every magnitude at or above
/// 1e21 through `toLocaleString`, and `Math.round(Infinity)` is `Infinity`, so
/// `format('d')(Infinity)` is `'∞'` rather than `'Infinity'` — confirmed
/// against the pinned d3-format 3.1.2 in the golden corpus.
const String _infinity = '∞';

/// The threshold at which `Number.prototype.toFixed` and `toString` give up on
/// positional notation (ECMA-262 §21.1.3.3 step 8, and `formatDecimal.js:2`).
const double _positionalLimit = 1e21;

/// `d3-format/src/formatDecimal.js:10-19` — the decimal coefficient digits and
/// exponent of a positive [x] at [p] significant digits.
///
/// Returns null for NaN, either infinity and either zero, exactly as the
/// `!isFinite(x) || x === 0` guard on `:11` does. A [p] of zero means "as many
/// digits as it takes", because upstream tests `p ?` and `0` is falsy in
/// JavaScript — `formatPrefixAuto.js:15` really does pass zero.
(String, int)? _decimalParts(double x, [int? p]) {
  if (!x.isFinite || x == 0) {
    return null;
  }
  final text = p == null || p == 0
      ? x.toStringAsExponential()
      : x.toStringAsExponential(p - 1);
  final i = text.indexOf('e');
  final coefficient = text.substring(0, i);
  return (
    // "1.2e+3" yields "12"; "1e+3" has no point to drop.
    coefficient.length > 1
        ? coefficient[0] + coefficient.substring(2)
        : coefficient,
    int.parse(text.substring(i + 1)),
  );
}

/// `d3-format/src/exponent.js:3-5` — the base-ten exponent of [x], or NaN when
/// [x] is zero or non-finite.
double _exponent(double x) {
  final parts = _decimalParts(x.abs());
  return parts == null ? double.nan : parts.$2.toDouble();
}

/// `d3-format/src/formatDecimal.js:1-5` — the `d` type.
///
/// The `toLocaleString('en')` branch on `:3` strips the group separators again
/// straight afterwards, so all it contributes is positional notation for
/// magnitudes Dart's `toString` would write exponentially. ICU expands the
/// shortest round-trip digits, which is what [_decimalParts] returns.
String _formatDecimal(double x) {
  final rounded = jsRound(x);
  if (rounded.abs() >= _positionalLimit) {
    if (rounded.isInfinite) {
      return _infinity;
    }
    final parts = _decimalParts(rounded)!;
    // One digit sits before the point, so the exponent is the number of digits
    // that must follow it.
    return parts.$1 + '0' * (parts.$2 - parts.$1.length + 1);
  }
  return jsNumberToString(rounded);
}

/// `d3-format/src/formatRounded.js:3-11` — the `r` type, and `p` after the
/// multiplication by a hundred.
String _formatRounded(double x, int p) {
  final parts = _decimalParts(x, p);
  if (parts == null) {
    return jsNumberToString(x);
  }
  final coefficient = parts.$1;
  final exponent = parts.$2;
  if (exponent < 0) {
    // `new Array(-exponent).join("0")` on `:8` emits one zero FEWER than
    // `-exponent`, because a join of n array slots produces n - 1 separators.
    // The leading "0." already accounts for the missing one.
    return '0.${'0' * (-exponent - 1)}$coefficient';
  }
  if (coefficient.length > exponent + 1) {
    return '${coefficient.substring(0, exponent + 1)}'
        '.${coefficient.substring(exponent + 1)}';
  }
  // `new Array(exponent - length + 2).join("0")` on `:10` is one fewer again.
  return coefficient + '0' * (exponent - coefficient.length + 1);
}

/// `d3-format/src/formatPrefixAuto.js:5-16` — the `s` type.
///
/// d3 stores the chosen exponent in the module-global `prefixExponent` which
/// `locale.js:90` then reads. A Dart top-level mutable would be a data race in
/// waiting, so it is returned alongside the text instead; null is the
/// `prefixExponent = undefined` of `:7`, which suppresses the suffix.
(String, int?) _formatPrefixAuto(double x, int p) {
  final parts = _decimalParts(x, p);
  if (parts == null) {
    return (x.toStringAsPrecision(p), null);
  }
  final coefficient = parts.$1;
  final exponent = parts.$2;
  // The ladder runs from yocto to yotta, so the exponent is clamped to ±8
  // groups of three (`:10`).
  final prefixExponent = math.max(-8, math.min(8, (exponent / 3).floor())) * 3;
  final i = exponent - prefixExponent + 1;
  final n = coefficient.length;
  if (i == n) {
    return (coefficient, prefixExponent);
  }
  if (i > n) {
    return (coefficient + '0' * (i - n), prefixExponent);
  }
  if (i > 0) {
    return (
      '${coefficient.substring(0, i)}.${coefficient.substring(i)}',
      prefixExponent,
    );
  }
  // Below 1y, where the coefficient has to be re-derived at a lower precision.
  final tail = _decimalParts(x, math.max(0, p + i - 1))!.$1;
  return ('0.${'0' * -i}$tail', prefixExponent);
}

/// `d3-format/src/formatTrim.js:2-11` — drops insignificant zeros for `~`.
String _formatTrim(String s) {
  final n = s.length;
  // i0 is where the trimmable run starts, -1 until a point is seen and 0 while
  // a significant digit has been seen since the last run of zeros.
  var i0 = -1;
  var i1 = 0;
  for (var i = 1; i < n; i++) {
    final c = s[i];
    if (c == '.') {
      i0 = i1 = i;
    } else if (c == '0') {
      if (i0 == 0) {
        i0 = i;
      }
      i1 = i;
    } else {
      // `!+s[i]` on `:7` stops at anything that is not a non-zero digit: the
      // `e` of an exponent, a sign, a space.
      final digit = int.tryParse(c);
      if (digit == null || digit == 0) {
        break;
      }
      if (i0 > 0) {
        i0 = 0;
      }
    }
  }
  return i0 > 0 ? s.substring(0, i0) + s.substring(i1 + 1) : s;
}

/// `d3-format/src/formatGroup.js:2-17` — inserts [_thousands] every
/// [_grouping] digits, right to left, within at most [width] characters.
String _group(String value, int width) {
  var i = value.length;
  final parts = <String>[];
  var j = 0;
  var g = _grouping[0];
  var length = 0;
  while (i > 0 && g > 0) {
    if (length + g + 1 > width) {
      g = math.max(1, width - length);
    }
    i -= g;
    // `value.substring(i -= g, i + g)` on `:11`, where JavaScript clamps a
    // negative start to zero. The last group is usually shorter than three, so
    // this is the common path, not an edge case.
    parts.add(value.substring(math.max(0, i), i + g));
    length += g + 1;
    if (length > width) {
      break;
    }
    j = (j + 1) % _grouping.length;
    g = _grouping[j];
  }
  return parts.reversed.join(_thousands);
}

/// The width standing in for `Infinity` at `locale.js:107,114`.
///
/// `_group` compares `length + g + 1` against it, so any value larger than the
/// longest digit string a double can produce is equivalent; 2^30 is that with
/// room to spare and stays an `int` on the web.
const int _unboundedWidth = 1 << 30;

/// The keys of `d3-format/src/formatTypes.js:5-19`. Anything else — including
/// the empty type and an upper-case `D` — takes the `.12~g` alias on
/// `locale.js:41`.
const Set<String> _knownTypes = <String>{
  '%',
  'b',
  'c',
  'd',
  'e',
  'f',
  'g',
  'o',
  'p',
  'r',
  's',
  'X',
  'x',
};

/// `Number.prototype.toString(radix)` for the `b`, `o`, `x` and `X` types
/// (`formatTypes.js:7,13,17,18`).
///
/// `BigInt` rather than `int.toRadixString`: `Math.round(x)` can exceed the
/// 64-bit range — `format('x')(1e21)` is `'3635c9adc5dea00000'`, seventy bits —
/// and `double.toInt()` saturates there instead of widening. JavaScript prints
/// the exact binary value of an integral double, which is what `BigInt.from`
/// preserves.
String _radix(double x, int radix) {
  final rounded = jsRound(x);
  if (!rounded.isFinite) {
    // `(Infinity).toString(16)` is "Infinity"; the `X` type upper-cases it.
    return jsNumberToString(rounded);
  }
  return BigInt.from(rounded).toRadixString(radix);
}

/// `d3-format/src/formatTypes.js:5-19` applied to a non-negative [x].
///
/// The second field is the SI exponent that `locale.js:90` needs, and is null
/// for every type but `s`. [x] is already `Math.abs`-ed by the caller, which is
/// why the rounding types round half **up** rather than half away from zero:
/// `format('d')(-0.5)` is `'−1'` because the type function only ever sees 0.5.
(String, int?) _applyType(String type, double x, int precision) =>
    switch (type) {
      '%' => ((x * 100).toStringAsFixed(precision), null),
      'b' => (_radix(x, 2), null),
      'c' => (jsNumberToString(x), null),
      'd' => (_formatDecimal(x), null),
      'e' => (x.toStringAsExponential(precision), null),
      'f' => (x.toStringAsFixed(precision), null),
      'g' => (x.toStringAsPrecision(precision), null),
      'o' => (_radix(x, 8), null),
      'p' => (_formatRounded(x * 100, precision), null),
      'r' => (_formatRounded(x, precision), null),
      's' => _formatPrefixAuto(x, precision),
      'X' => (_radix(x, 16).toUpperCase(), null),
      'x' => (_radix(x, 16), null),
      _ => throw StateError('unreachable format type "$type"'),
    };

/// Builds a formatter from an already-parsed [specifier]
/// (`d3-format/src/locale.js:23-132`).
///
/// [suffixExtra] is the `options.suffix` of `:49`, which only [formatPrefix]
/// passes. `d3-scale/src/tickFormat.js:28` and `d3-scale/src/log.js:114` both
/// mutate a [FormatSpecifier] and pass the object, which is why this exists
/// alongside [format].
NumberFormatter formatFrom(
  FormatSpecifier specifier, {
  String suffixExtra = '',
}) {
  var fill = specifier.fill;
  var align = specifier.align;
  final sign = specifier.sign;
  final symbol = specifier.symbol;
  var zero = specifier.zero;
  final width = specifier.width;
  var precision = specifier.precision;
  var trim = specifier.trim;
  var type = specifier.type;

  // `:38` — the "n" type is an alias for ",g", so it groups as well.
  final comma = specifier.comma || type == 'n';
  if (type == 'n') {
    type = 'g';
  } else if (!_knownTypes.contains(type)) {
    // `:41` — the "" type, and any invalid type, is an alias for ".12~g".
    // Twelve significant digits is d3's own choice of "enough".
    precision ??= 12;
    trim = true;
    type = 'g';
  }
  if (zero || (fill == '0' && align == '=')) {
    // `:44` — zero fill puts the padding after the sign and before the digits.
    zero = true;
    fill = '0';
    align = '=';
  }

  // `:48-49`.
  final prefix = symbol == r'$'
      ? _currencyPrefix
      : symbol == '#' && _basePrefixed.hasMatch(type)
      ? '0${type.toLowerCase()}'
      : '';
  final suffix =
      (symbol == r'$'
          ? _currencySuffix
          : _percentTypes.hasMatch(type)
          ? _percent
          : '') +
      suffixExtra;
  final maybeSuffix = _mayHaveSuffix.hasMatch(type);

  // `:61-63` — six significant digits by default; significant precision is
  // clamped to [1, 21] and fixed precision to [0, 20], the ranges
  // `toPrecision` and `toFixed` accept.
  final effectivePrecision = precision == null
      ? 6
      : _significantTypes.hasMatch(type)
      ? math.max(1, math.min(21, precision))
      : math.max(0, math.min(20, precision));

  return (num raw) {
    var valuePrefix = prefix;
    var valueSuffix = suffix;
    String value;

    if (type == 'c') {
      // `:70-72` — the "c" type emits the value verbatim, sign and all, and
      // leaves nothing to group or pad on the digit side.
      valueSuffix = jsNumberToString(raw.toDouble()) + valueSuffix;
      value = '';
    } else {
      final x = raw.toDouble();
      // `:77` — -0 is not less than 0, but 1 / -0 is.
      var negative = x < 0 || (x == 0 && x.isNegative);
      int? prefixExponent;
      if (x.isNaN) {
        // `:80` short-circuits before the type function, which is why
        // `format('#x')(double.nan)` is "0xNaN".
        value = _nan;
      } else {
        final applied = _applyType(type, x.abs(), effectivePrecision);
        value = applied.$1;
        prefixExponent = applied.$2;
      }
      if (trim) {
        value = _formatTrim(value);
      }
      // `:86` — a negative value that rounded to zero loses its sign unless a
      // plus was asked for. `+value` on the FORMATTED string, so "0.0" counts.
      if (negative &&
          (double.tryParse(value) ?? double.nan) == 0 &&
          sign != '+') {
        negative = false;
      }
      // `:89`.
      valuePrefix =
          (negative
              ? (sign == '(' ? sign : minusSign)
              : sign == '-' || sign == '('
              ? ''
              : sign) +
          valuePrefix;
      // `:90` — `!isNaN(value)` there is a test on the string, so a NaN input
      // keeps no SI suffix even though the module global still holds the
      // previous call's exponent.
      valueSuffix =
          (type == 's' && !x.isNaN && prefixExponent != null
              ? siPrefixes[8 + prefixExponent ~/ 3]
              : '') +
          valueSuffix +
          (negative && sign == '(' ? ')' : '');
      if (maybeSuffix) {
        // `:94-103` — only the leading run of ASCII digits can be grouped; a
        // point, an exponent or a "∞" ends it.
        for (var i = 0; i < value.length; i++) {
          final c = value.codeUnitAt(i);
          // 48 is "0" and 57 is "9"; 46 is ".".
          if (c < 48 || c > 57) {
            valueSuffix =
                (c == 46
                    ? _decimal + value.substring(i + 1)
                    : value.substring(i)) +
                valueSuffix;
            value = value.substring(0, i);
            break;
          }
        }
      }
    }

    // `:107` — with a non-zero fill, grouping happens before padding.
    if (comma && !zero) {
      value = _group(value, _unboundedWidth);
    }
    // `:110-111`.
    final length = valuePrefix.length + value.length + valueSuffix.length;
    var padding = width != null && length < width
        ? fill * (width - length)
        : '';
    // `:114` — with a zero fill the padding is grouped along with the digits.
    if (comma && zero) {
      value = _group(
        padding + value,
        padding.isNotEmpty ? width! - valueSuffix.length : _unboundedWidth,
      );
      padding = '';
    }
    // `:117-122`.
    return switch (align) {
      '<' => '$valuePrefix$value$valueSuffix$padding',
      '=' => '$valuePrefix$padding$value$valueSuffix',
      '^' =>
        padding.substring(0, padding.length >> 1) +
            valuePrefix +
            value +
            valueSuffix +
            padding.substring(padding.length >> 1),
      _ => '$padding$valuePrefix$value$valueSuffix',
    };
  };
}

/// The types `locale.js:48` gives a base prefix to when `#` is asked for.
final RegExp _basePrefixed = RegExp('[boxX]');

/// The types `locale.js:49` appends the percent sign to.
final RegExp _percentTypes = RegExp('[%p]');

/// The types `locale.js:55` allows a fractional or exponential tail on.
final RegExp _mayHaveSuffix = RegExp('[defgprs%]');

/// The types whose precision counts significant digits (`locale.js:62`).
final RegExp _significantTypes = RegExp('[gprs]');

/// A formatter for [specifier] (`d3-format/src/locale.js:23`).
NumberFormatter format(String specifier) =>
    formatFrom(formatSpecifier(specifier));

/// A formatter that scales every input by the SI prefix chosen for [value]
/// (`d3-format/src/locale.js:134-141`).
///
/// This is the default y-axis tick formatter for the whole library:
/// `utilities.ts:218` calls `formatPrefix('.2~', value)` and
/// `utilities.ts:242-244` exposes it as `defaultYAxisTickFormatter`.
///
/// A [value] of zero has no exponent, so `:135-136` computes a NaN scale factor
/// and `:49` drops the undefined suffix: the resulting formatter answers `NaN`
/// for everything. That is upstream's behaviour, verified against the pinned
/// d3-format, and not something to "fix" here.
NumberFormatter formatPrefix(String specifier, num value) {
  final exponent = _exponent(value.toDouble());
  // Clamped to ±8 groups of three, the span of [siPrefixes].
  final e = exponent.isNaN
      ? double.nan
      : math.max(-8.0, math.min(8.0, (exponent / 3).floorToDouble())) * 3;
  // `Math.pow(10, -e)` on `:136`, which is exact at every decade in range.
  final k = math.pow(10.0, -e).toDouble();
  final spec = formatSpecifier(specifier)..type = 'f';
  final f = formatFrom(
    spec,
    suffixExtra: e.isNaN ? '' : siPrefixes[8 + e.toInt() ~/ 3],
  );
  return (num v) => f(k * v);
}

/// The digits after the decimal point needed to show [step]
/// (`d3-format/src/precisionFixed.js:3-5`).
///
/// NaN when [step] is zero, because `exponent(0)` is NaN
/// (`formatDecimal.js:11`). `d3-scale/src/tickFormat.js:24` guards on exactly
/// that to leave the precision unset, so this returns `double` where the
/// frozen contract said `int` — an `int` cannot carry the answer, and the
/// golden corpus records NaN for nine of its forty-five cases.
double precisionFixed(double step) {
  final e = _exponent(step.abs());
  // Written out rather than leaning on `math.max`'s NaN propagation, which is
  // documented for neither argument position.
  return e.isNaN ? double.nan : math.max(0.0, -e);
}

/// The precision an SI-prefixed [step] needs at [value]'s magnitude
/// (`d3-format/src/precisionPrefix.js:3-5`).
///
/// NaN when either argument is zero; see [precisionFixed] on the return type.
double precisionPrefix(double step, double value) {
  final ev = _exponent(value);
  final es = _exponent(step.abs());
  if (ev.isNaN || es.isNaN) {
    return double.nan;
  }
  // Groups of three, clamped to the span of [siPrefixes].
  final prefixExponent =
      math.max(-8.0, math.min(8.0, (ev / 3).floorToDouble())) * 3;
  return math.max(0.0, prefixExponent - es);
}

/// The significant digits [step] needs across `[0, max]`
/// (`d3-format/src/precisionRound.js:3-6`).
///
/// NaN when `|max| - |step|` is zero — a single-tick domain — see
/// [precisionFixed] on the return type.
double precisionRound(double step, double max) {
  final s = step.abs();
  final em = _exponent(max.abs() - s);
  final es = _exponent(s);
  if (em.isNaN || es.isNaN) {
    return double.nan;
  }
  // The `+ 1` on `:5` turns a digit span into a digit count.
  return math.max(0.0, em - es) + 1;
}
