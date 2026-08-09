/// The three axis kinds a chart value can drive, and the predicates that decide
/// which one a runtime value belongs to.
library;

/// The kind of scale an axis needs for the values plotted along it.
///
/// Ports **both** `XAxisTypes` (`utilities.ts:110-114`) and `YAxisType`
/// (`utilities.ts:116-120`). The two upstream enums are byte-identical, carry
/// the same ordinals, and `getTypeOfAxis` (`:1686-1706`) differs only in which
/// of them it names, so they collapse to one type here.
enum FluentChartAxisType {
  /// `NumericAxis` — a linear or logarithmic scale over numbers.
  numeric,

  /// `DateAxis` — a time scale.
  date,

  /// `StringAxis` — a band scale over categories.
  category,
}

/// The axis kind [value] belongs to.
///
/// Ports the body of `getTypeOfAxis` (`utilities.ts:1687-1705`), including its
/// `default:` arm: anything that is neither a string nor a number is reported as
/// a date, even when it is neither.
///
/// `// parity:` the `default:` fallthrough at `utilities.ts:1693` and `:1701` is
/// reproduced rather than tightened, because charts pass their first data point
/// through it unvalidated and a throw here would change which charts render.
FluentChartAxisType chartAxisTypeOf(Object value) => switch (value) {
  String() => FluentChartAxisType.category,
  num() => FluentChartAxisType.numeric,
  _ => FluentChartAxisType.date,
};

/// Whether [value] is one of the three types a chart axis accepts.
bool isChartAxisValue(Object? value) =>
    value is num || value is String || value is DateTime;

/// Whether [value] can drive a continuous axis — a number or a date.
bool isNumericOrDate(Object? value) => value is num || value is DateTime;

/// Whether [value] can drive a numeric or a band axis — a number or a category.
bool isNumericOrCategory(Object? value) => value is num || value is String;

/// Whether [value] is unusable as a coordinate.
///
/// Ports `isInvalidValue` (`chart-utilities/PlotlySchemaConverter.ts:172`):
/// null, or a number that is not finite. It deliberately does **not** reject the
/// empty string — upstream does not, and `''` is a meaningful "no bar" marker on
/// a stacked bar (`VerticalStackedBarChart.tsx:1008-1009`).
bool isInvalidChartValue(Object? value) =>
    value == null || (value is num && !value.isFinite);

/// Whether the pair ([x], [y]) can be drawn.
///
/// Ports `isPlottable` (`utilities.ts:2278-2280`). This is the predicate the
/// four `defined` overrides pass to d3's line and area generators
/// (`LineChart.tsx:678`, `:1326`, `PolarChart.tsx:450`, `:473`).
bool isPlottable(Object? x, Object? y) =>
    !isInvalidChartValue(x) && !isInvalidChartValue(y);

/// Whether [value] reads as a finite number.
///
/// Ports `isNumber` (`chart-utilities/PlotlySchemaConverter.ts:41`), which is
/// `!isNaN(parseFloat(value)) && isFinite(value)`. JS `isFinite` coerces its
/// argument with `Number()`, which — unlike `parseFloat` — rejects any trailing
/// rubbish, so `'12abc'` is **not** number-like even though `parseFloat` returns
/// 12 for it. `num.tryParse` has exactly `Number()`'s strictness, so the two
/// halves of the upstream expression collapse into one call here.
bool isNumberLike(Object? value) {
  if (value is num) return value.isFinite;
  if (value is! String) return false;
  final parsed = num.tryParse(value.trim());
  return parsed != null && parsed.isFinite;
}

/// Whether [value] reads as a date.
///
/// Ports `isDate` (`chart-utilities/PlotlySchemaConverter.ts:44-60`) including
/// both guards:
///
/// * a number-like value is rejected outright (`:47-49`), because milliseconds
///   and a bare year cannot be told apart without extra context;
/// * a value that parses but whose parsed year is 2000 or 2001 while the input
///   carries no four-digit year is rejected (`:55-58`), which is how a bare
///   month name such as `'March'` is kept off a date axis.
bool isDateLike(Object? value) {
  if (value is DateTime) return true;
  if (isNumberLike(value)) return false;
  if (value is! String) return false;
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return false;
  // `\b\d{4}\b` — the exact expression at PlotlySchemaConverter.ts:56.
  final hasFourDigitYear = RegExp(r'\b\d{4}\b').hasMatch(value);
  // 2000 and 2001 are the two years JS's Date parser invents for an input that
  // names no year at all (PlotlySchemaConverter.ts:57).
  if (!hasFourDigitYear && (parsed.year == 2000 || parsed.year == 2001)) {
    return false;
  }
  return true;
}
