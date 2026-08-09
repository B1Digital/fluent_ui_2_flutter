import 'dart:math' as math;

/// `[[fill]align][sign][symbol][0][width][,][.precision][~][type]`
/// (`d3-format/src/formatSpecifier.js:2`).
///
/// Every group is optional, so this matches the empty string and yields a
/// specifier of pure defaults. Case-insensitive because the type group is
/// written `[a-z%]` upstream yet must still accept `X`, the upper-case
/// hexadecimal type.
final RegExp _re = RegExp(
  r'^(?:(.)?([<>=^]))?([+\-( ])?([$#])?(0)?(\d+)?(,)?(\.\d+)?(~)?([a-z%])?$',
  caseSensitive: false,
);

/// A parsed number-format specifier
/// (`d3-format/src/formatSpecifier.js:23-34`).
///
/// The fields are mutable because `d3-scale/src/tickFormat.js:11,19,24` and
/// `d3-scale/src/log.js:113` both parse a specifier and then write `precision`
/// or `trim` back into it before formatting.
class FormatSpecifier {
  /// Creates a specifier, applying d3's defaults for anything omitted.
  FormatSpecifier({
    this.fill = ' ',
    this.align = '>',
    this.sign = '-',
    this.symbol = '',
    this.zero = false,
    this.width,
    this.comma = false,
    this.precision,
    this.trim = false,
    this.type = '',
  });

  /// The padding character.
  String fill;

  /// One of `<`, `>`, `=` or `^`.
  String align;

  /// One of `-`, `+`, `(` or a space.
  String sign;

  /// `$` for currency or `#` for a base prefix.
  String symbol;

  /// Whether zero-padding is requested.
  bool zero;

  /// The minimum field width, or `null`.
  int? width;

  /// Whether group separators are inserted.
  bool comma;

  /// The requested precision, or `null`.
  int? precision;

  /// Whether insignificant trailing zeros are trimmed — the `~` flag.
  bool trim;

  /// The one-character type, or the empty string.
  String type;

  @override
  String toString() {
    // `formatSpecifier.js:42` clamps the width to at least 1 and `:44` the
    // precision to at least 0, on the way out only — the parsed fields keep
    // whatever a caller wrote into them.
    final w = width == null ? '' : '${math.max(1, width!)}';
    final p = precision == null ? '' : '.${math.max(0, precision!)}';
    return '$fill$align$sign$symbol${zero ? '0' : ''}$w'
        '${comma ? ',' : ''}$p${trim ? '~' : ''}$type';
  }
}

/// Parses [specifier] (`d3-format/src/formatSpecifier.js:4-19`).
///
/// Throws a `FormatException` whose message is `invalid format: $specifier`,
/// matching d3's `Error("invalid format: " + specifier)`. Three upstream call
/// sites catch it and fall back — `PlotlySchemaAdapter.ts:443`, `:2865` and
/// `VegaLiteSchemaAdapter.ts:1079` — so returning `null` instead would change
/// three adapter code paths.
FormatSpecifier formatSpecifier(String specifier) {
  final match = _re.firstMatch(specifier);
  if (match == null) {
    throw FormatException('invalid format: $specifier', specifier);
  }
  // Group 8 is the `.precision` group including its dot, which upstream slices
  // off at `formatSpecifier.js:15`. Group numbers 1-10 are the ten groups of
  // `_re`, in the order they appear in the grammar comment above.
  final precision = match.group(8);
  final width = match.group(6);
  return FormatSpecifier(
    fill: match.group(1) ?? ' ',
    align: match.group(2) ?? '>',
    sign: match.group(3) ?? '-',
    symbol: match.group(4) ?? '',
    zero: match.group(5) != null,
    width: width == null ? null : int.parse(width),
    comma: match.group(7) != null,
    precision: precision == null ? null : int.parse(precision.substring(1)),
    trim: match.group(9) != null,
    type: match.group(10) ?? '',
  );
}
