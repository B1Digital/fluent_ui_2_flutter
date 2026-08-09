import '../internal/d3/format.dart' as d3;

/// Formats a y-axis value with an SI prefix.
///
/// Ports `yAxisTickFormatterInternal` (`utilities.ts:216-235`). The default is
/// `formatPrefix('.2~', value)` — two decimals with insignificant zeros trimmed,
/// scaled by whichever SI prefix suits the value. Two overrides apply: values
/// below one drop out of SI notation entirely because it reads badly there, and
/// when [limitWidth] is set a value of a thousand or more falls back to one
/// decimal. Finally `G` becomes `B` from `1e9` up, which is the commoner
/// convention for money and counts.
String yAxisTickFormatterInternal(double value, {bool limitWidth = false}) {
  var formatter = d3.formatPrefix('.2~', value);
  if (value.abs() < 1) {
    formatter = d3.format('.2~g');
  } else if (limitWidth && value.abs() >= 1000) {
    // 1000 is the threshold at utilities.ts:223.
    formatter = d3.formatPrefix('.1~', value);
  }
  final formatted = formatter(value);
  // 1e9 is the threshold at utilities.ts:230.
  if (value.abs() >= 1e9) {
    return formatted.replaceAll('G', 'B');
  }
  return formatted;
}

/// The default y-axis tick label formatter.
///
/// Ports `defaultYAxisTickFormatter` (`utilities.ts:242-244`).
String defaultYAxisTickFormatter(double value) =>
    yAxisTickFormatterInternal(value);

/// The width-constrained variant used for bar value labels, for example at
/// `VerticalBarChart.tsx:960`.
///
/// Ports `formatScientificLimitWidth` (`utilities.ts:1887-1889`).
String formatScientificLimitWidth(double value) =>
    yAxisTickFormatterInternal(value, limitWidth: true);
