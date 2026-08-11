import 'package:flutter/widgets.dart';

import '../../model/line_options.dart';
import '../d3/format.dart' as d3;
import '../d3/js_math.dart' as d3;
import 'predicates.dart';

/// One entry of `dashOptions` (`PlotlySchemaAdapter.ts:136-173`).
///
/// The four members are kept as the strings upstream writes into SVG
/// attributes, because that is the contract the table states and because
/// [getLineOptions] is the only reader — it converts them once, on the way into
/// [FluentLineOptions].
@immutable
class FluentPlotlyDash {
  /// Creates a preset. Every upstream entry sets all four.
  const FluentPlotlyDash({
    required this.strokeDasharray,
    required this.strokeLinecap,
    required this.strokeWidth,
    required this.lineBorderWidth,
  });

  /// The SVG `stroke-dasharray` (`PlotlySchemaAdapter.ts:138`).
  final String strokeDasharray;

  /// The SVG `stroke-linecap` (`PlotlySchemaAdapter.ts:139`), `'round'` on the
  /// dot preset and `'butt'` on the other five.
  final String strokeLinecap;

  /// The SVG `stroke-width` (`PlotlySchemaAdapter.ts:140`), `'2'` throughout.
  final String strokeWidth;

  /// The halo width behind the stroke (`PlotlySchemaAdapter.ts:141`), `'4'`
  /// throughout.
  final String lineBorderWidth;
}

/// The six Plotly dash presets (`PlotlySchemaAdapter.ts:136-173`).
///
/// Insertion order is upstream's declaration order, which is also the order the
/// `dash` enum is documented in.
const Map<String, FluentPlotlyDash> kDashOptions = <String, FluentPlotlyDash>{
  // `PlotlySchemaAdapter.ts:137-142`.
  'dot': FluentPlotlyDash(
    strokeDasharray: '1, 5',
    strokeLinecap: 'round',
    strokeWidth: '2',
    lineBorderWidth: '4',
  ),
  // `PlotlySchemaAdapter.ts:143-148`.
  'dash': FluentPlotlyDash(
    strokeDasharray: '5, 5',
    strokeLinecap: 'butt',
    strokeWidth: '2',
    lineBorderWidth: '4',
  ),
  // `PlotlySchemaAdapter.ts:149-154`.
  'longdash': FluentPlotlyDash(
    strokeDasharray: '10, 5',
    strokeLinecap: 'butt',
    strokeWidth: '2',
    lineBorderWidth: '4',
  ),
  // `PlotlySchemaAdapter.ts:155-160`.
  'dashdot': FluentPlotlyDash(
    strokeDasharray: '5, 5, 1, 5',
    strokeLinecap: 'butt',
    strokeWidth: '2',
    lineBorderWidth: '4',
  ),
  // `PlotlySchemaAdapter.ts:161-166`.
  'longdashdot': FluentPlotlyDash(
    strokeDasharray: '10, 5, 1, 5',
    strokeLinecap: 'butt',
    strokeWidth: '2',
    lineBorderWidth: '4',
  ),
  // `PlotlySchemaAdapter.ts:167-172`.
  'solid': FluentPlotlyDash(
    strokeDasharray: '0',
    strokeLinecap: 'butt',
    strokeWidth: '2',
    lineBorderWidth: '4',
  ),
};

/// The four presentation members a Plotly object title carries
/// (`TitleStyles`, `utilities/Common.styles.ts:17-35`, filled at
/// `PlotlySchemaAdapter.ts:183-188`).
///
/// [font] and [pad] stay as the raw Plotly maps. Resolving a Plotly font to a
/// `TextStyle` needs the CSS colour parser and the theme, neither of which
/// belongs to a schema helper; the adapter that renders the title does that
/// conversion.
@immutable
class FluentPlotlyTitleStyle {
  /// Creates a title style. Every member is optional, exactly as the four
  /// conditional spreads at `PlotlySchemaAdapter.ts:184-187` are.
  const FluentPlotlyTitleStyle({
    this.font,
    this.xAnchor,
    this.yAnchor,
    this.pad,
  });

  /// `layout.title.font` (`PlotlySchemaAdapter.ts:178`) — `family`, `size` and
  /// `color`.
  final Map<String, Object?>? font;

  /// `layout.title.xanchor` (`PlotlySchemaAdapter.ts:179`): `'auto'`, `'left'`,
  /// `'center'` or `'right'`.
  final String? xAnchor;

  /// `layout.title.yanchor` (`PlotlySchemaAdapter.ts:180`): `'auto'`, `'top'`,
  /// `'middle'` or `'bottom'`.
  final String? yAnchor;

  /// `layout.title.pad` (`PlotlySchemaAdapter.ts:181`) — `t`, `b`, `l`, `r`.
  final Map<String, Object?>? pad;

  /// Whether none of the four members was present, which is the condition
  /// `PlotlySchemaAdapter.ts:192` tests before it spreads the record at all.
  bool get isEmpty =>
      font == null && xAnchor == null && yAnchor == null && pad == null;
}

/// The titles a Plotly layout declares (`PlotlySchemaAdapter.ts:175-198`).
@immutable
class FluentPlotlyTitles {
  /// Creates a title set. The three axis-independent strings default to empty,
  /// which is what `?? ''` gives upstream.
  const FluentPlotlyTitles({
    this.chartTitle = '',
    this.xAxisTitle = '',
    this.yAxisTitle = '',
    this.secondaryYAxisTitle,
    this.titleStyle,
  });

  /// `layout.title` as a string, else `layout.title.text`
  /// (`PlotlySchemaAdapter.ts:177`).
  final String chartTitle;

  /// `layout.xaxis.title` in either form (`PlotlySchemaAdapter.ts:193`).
  final String xAxisTitle;

  /// `layout.yaxis.title` in either form (`PlotlySchemaAdapter.ts:194`).
  final String yAxisTitle;

  /// `layout.yaxis2.title` in either form, null when absent.
  ///
  /// **Deviation:** upstream's `getTitles` has no such member — it is read
  /// separately, by `getSecondaryYAxisValues` at
  /// `PlotlySchemaAdapter.ts:343-349`, whose expression this reproduces
  /// including its `undefined` for a missing title. It is consolidated here
  /// because this task's contract declares it, and because a caller that wants
  /// one axis title wants all of them.
  final String? secondaryYAxisTitle;

  /// The chart title's font and anchors, or null when the title declared none —
  /// the empty-record test at `PlotlySchemaAdapter.ts:192`.
  final FluentPlotlyTitleStyle? titleStyle;
}

/// Reads a Plotly title, which is either a string or `{text}`
/// (`PlotlySchemaAdapter.ts:177`, `:193`, `:194`).
String _titleText(Object? title) {
  if (title is String) return title;
  if (title is Map<String, Object?>) {
    final text = title['text'];
    if (text is String) return text;
  }
  return '';
}

/// The nullable form of [_titleText], for `PlotlySchemaAdapter.ts:344-349`
/// where a missing title stays `undefined` rather than collapsing to `''`.
String? _optionalTitleText(Object? title) {
  if (title is String) return title;
  if (title is Map<String, Object?>) {
    final text = title['text'];
    if (text is String) return text;
  }
  return null;
}

/// Reads [value] as a map, or an empty one, so every lookup below can be a
/// plain index.
Map<String, Object?> _mapOf(Object? value) =>
    value is Map<String, Object?> ? value : const <String, Object?>{};

/// Pulls the chart and axis titles out of a Plotly layout
/// (`PlotlySchemaAdapter.ts:175-198`).
///
/// The font and the two anchors are read only when the title is an object,
/// because a string title has nowhere to declare them
/// (`PlotlySchemaAdapter.ts:178-181`).
///
/// **Not ported:** the `xAxisAnnotation: chartTitle` member at
/// `PlotlySchemaAdapter.ts:195`. It is the same string under a second name, and
/// no ported chart takes an `xAxisAnnotation` prop; a caller that needs it
/// reads [FluentPlotlyTitles.chartTitle].
FluentPlotlyTitles getTitles(Map<String, Object?>? layout) {
  final titleObj = layout?['title'];
  final titleMap = titleObj is Map<String, Object?>
      ? titleObj
      : const <String, Object?>{};
  final style = FluentPlotlyTitleStyle(
    font: titleMap['font'] is Map<String, Object?>
        ? titleMap['font']! as Map<String, Object?>
        : null,
    xAnchor: titleMap['xanchor'] is String
        ? titleMap['xanchor']! as String
        : null,
    yAnchor: titleMap['yanchor'] is String
        ? titleMap['yanchor']! as String
        : null,
    pad: titleMap['pad'] is Map<String, Object?>
        ? titleMap['pad']! as Map<String, Object?>
        : null,
  );
  return FluentPlotlyTitles(
    chartTitle: _titleText(titleObj),
    xAxisTitle: _titleText(_mapOf(layout?['xaxis'])['title']),
    yAxisTitle: _titleText(_mapOf(layout?['yaxis'])['title']),
    secondaryYAxisTitle: _optionalTitleText(_mapOf(layout?['yaxis2'])['title']),
    titleStyle: style.isEmpty ? null : style,
  );
}

/// The first of the month [value] names in [year], or null when it names no
/// month.
///
/// Upstream asks `isDate('${value} 01, ${year}')` and then parses that string
/// (`PlotlySchemaAdapter.ts:269-272`), which works because JavaScript's date
/// parser knows the long and three-letter English month names. Dart's
/// `DateTime.parse` knows neither, so the port matches against
/// [kMonthNames] and [kShortMonthNames] — the same two tables `isPlotlyMonth`
/// uses to decide the column was month-shaped in the first place.
DateTime? _monthStart(Object? value, int year) {
  if (value is! String) return null;
  final name = value.trim().toLowerCase();
  var index = kMonthNames.indexOf(name);
  if (index < 0) index = kShortMonthNames.indexOf(name);
  if (index < 0) return null;
  return DateTime(year, index + 1);
}

/// Rewrites a column of month names into `'<month> 01, <year>'` strings whose
/// years ascend (`PlotlySchemaAdapter.ts:264-298`).
///
/// Every entry starts in the current year; the walk then runs backwards from
/// the last parseable entry, and each time the earlier month is not strictly
/// before the later one it drops a year. `'Dec', 'Jan'` therefore becomes
/// December of last year followed by January of this one.
///
/// Entries that name no month come back as null, keeping the positions of the
/// input (`PlotlySchemaAdapter.ts:291-296`).
///
/// Throws an `ArgumentError` for a 2-D column, upstream's
/// `updateXValues:: 2D array not supported` at `PlotlySchemaAdapter.ts:266-268`
/// — an `Error` there, and the nearest Dart equivalent for a caller that passed
/// the wrong shape.
List<Object?> correctYearMonth(Object? xValues) {
  final values = xValues is List<Object?> ? xValues : const <Object?>[];
  if (values.isNotEmpty && values.first is List) {
    throw ArgumentError.value(
      xValues,
      'xValues',
      'updateXValues:: 2D array not supported',
    );
  }
  final presentYear = DateTime.now().year;
  final dates = <DateTime?>[
    for (final value in values) _monthStart(value, presentYear),
  ];
  // `PlotlySchemaAdapter.ts:273-276`: the walk visits parseable entries only,
  // remembering where each came from.
  final pairs = <(DateTime, int)>[
    for (var index = 0; index < dates.length; index++)
      if (dates[index] != null) (dates[index]!, index),
  ];
  for (var i = pairs.length - 1; i > 0; i--) {
    final current = pairs[i].$1;
    final (previous, previousIndex) = pairs[i - 1];
    var updated = previous;
    if (previous.month >= current.month) {
      // `:284-285`.
      updated = DateTime(current.year - 1, previous.month);
    } else if (previous.year > current.year) {
      // `:286-287`.
      updated = DateTime(current.year, previous.month);
    }
    // `:289`, and the mutation at `:285` that the next iteration reads back.
    pairs[i - 1] = (updated, previousIndex);
    dates[previousIndex] = updated;
  }
  return <Object?>[
    for (var index = 0; index < values.length; index++)
      if (dates[index] == null)
        null
      else
        '${values[index]} 01, ${dates[index]!.year}',
  ];
}

/// Coerces one x value to the type its axis was typed as
/// (`PlotlySchemaAdapter.ts:368-406`).
///
/// **Deviation, signature:** upstream takes five arguments —
/// `isXYearCategory`, `isXString`, `isXDate`, `isXNumber`. This task's contract
/// declares two, so the port drops the first and folds the second into
/// `x is String`, which is what the `isXString` branch guards in every call
/// upstream makes. The consequence is that the year-category arm at `:378-380`
/// — a numeric year rendered as a category, `x.toString()` — has no switch here
/// and a caller with a year category must stringify the value itself.
///
/// **Deviation, failure:** `parseFloat` and `new Date` return NaN and an
/// Invalid Date for an unparseable string; Dart has neither, so an unparseable
/// string comes back unchanged. Both flags are whole-column verdicts, so a
/// column that reached this has already been checked.
Object? resolveXAxisPoint(
  Object? x, {
  required bool isDate,
  required bool isNumeric,
}) {
  // `:375-377`.
  if (x == null) return '';
  if (x is String) {
    // `:382-385`.
    if (isDate) return DateTime.tryParse(x) ?? x;
    // `:386-388`.
    if (isNumeric) return _parseFloat(x) ?? x;
    // `:389`.
    return x;
  }
  // `:391`.
  return x;
}

/// The prefix JavaScript's `parseFloat` would consume: leading space, an
/// optional sign, digits with an optional fraction, and an optional exponent.
///
/// `Infinity` is not accepted. `parseFloat('Infinity')` is `Infinity` in
/// JavaScript, which every caller here immediately rejects as non-finite or
/// formats as `'∞'`; neither is a value a Plotly schema carries.
final RegExp _leadingNumber = RegExp(
  r'^\s*[+-]?(?:\d+(?:\.\d+)?|\.\d+)(?:[eE][+-]?\d+)?',
);

/// `parseFloat` (`PlotlySchemaAdapter.ts:416`, `:387`), with null for the NaN
/// JavaScript returns when nothing parses.
double? _parseFloat(String value) {
  final match = _leadingNumber.firstMatch(value);
  return match == null ? null : double.tryParse(match[0]!.trim());
}

/// `String(value)` with JavaScript's number formatting, so an integral double
/// prints as `3` rather than `3.0`.
String _jsString(Object? value) =>
    value is num ? d3.jsNumberToString(value.toDouble()) : '$value';

/// The `%{text}` or `%{text:spec}` placeholder and whatever literal follows it
/// (`PlotlySchemaAdapter.ts:424`).
final RegExp _textTemplatePattern = RegExp(r'%\{text(?::([^}]+))?\}(.*)$');

/// The precision an unparseable specifier still betrays
/// (`PlotlySchemaAdapter.ts:448`).
final RegExp _precisionPattern = RegExp(r'\.(\d+)[f%]');

/// Formats a value through a Plotly `texttemplate`
/// (`PlotlySchemaAdapter.ts:408-461`).
///
/// [textTemplate] is a template string, or a list of them indexed by [index]
/// (`:420`). A null or empty template, a non-numeric [textValue], or a template
/// with no `%{text}` placeholder all return `String(textValue)` — `:413-419`
/// and `:460`.
///
/// With a placeholder and no specifier the number is written as it stands,
/// except that a suffix beginning with `%` triggers one decimal place
/// (`:432-438`). With a specifier the value goes through `d3.format`, and if
/// that refuses the specifier the fallback at `:446-456` takes the precision
/// out of the specifier — defaulting to **2** — and multiplies by a hundred
/// when the specifier mentions a percentage.
String formatTextWithTemplate(
  Object textValue,
  Object? textTemplate, [
  int index = 0,
]) {
  // `:413-415`: `!textTemplate` is true for null and for the empty string.
  if (textTemplate == null ||
      (textTemplate is String && textTemplate.isEmpty)) {
    return _jsString(textValue);
  }
  // `:416-419`.
  final numVal = textValue is num
      ? textValue.toDouble()
      : _parseFloat(_jsString(textValue));
  if (numVal == null || numVal.isNaN) return _jsString(textValue);

  // `:420`: an index past the end of the list gives undefined, and `|| ''`
  // turns that into a template that matches nothing.
  var template = '';
  if (textTemplate is String) {
    template = textTemplate;
  } else if (textTemplate is List<Object?> &&
      index >= 0 &&
      index < textTemplate.length) {
    final entry = textTemplate[index];
    if (entry is String) template = entry;
  }

  final match = _textTemplatePattern.firstMatch(template);
  // `:460`.
  if (match == null) return _jsString(textValue);

  final formatSpec = match.group(1);
  final suffix = match.group(2) ?? '';

  if (formatSpec == null || formatSpec.isEmpty) {
    // `:432-435`.
    if (suffix.startsWith('%')) return '${numVal.toStringAsFixed(1)}$suffix';
    // `:438`.
    return '${_jsString(numVal)}$suffix';
  }

  try {
    // `:441-445`.
    return '${d3.format(formatSpec)(numVal)}$suffix';
  } on FormatException {
    // `:446-456`. Only `formatSpecifier` throws, and only a `FormatException`
    // (`d3/format_spec.dart:86-89`), so this catch is as narrow as the failure.
    final precisionMatch = _precisionPattern.firstMatch(formatSpec);
    // `:449`: 2 when the specifier names no precision the regex can see.
    final precision = precisionMatch == null
        ? 2
        : int.parse(precisionMatch.group(1)!);
    if (formatSpec.contains('%')) {
      // `:452-453`.
      return '${(numVal * 100).toStringAsFixed(precision)}%$suffix';
    }
    // `:456`.
    return '${numVal.toStringAsFixed(precision)}$suffix';
  }
}

/// Flattens nested maps into dotted keys (`PlotlySchemaAdapter.ts:520-540`).
///
/// A list, a `DateTime` and a null are leaves, matching the
/// `!Array.isArray(value) && !(value instanceof Date)` guard at `:528`.
Map<String, Object?> flattenObject(
  Map<String, Object?> obj, [
  String prefix = '',
]) {
  final flattened = <String, Object?>{};
  obj.forEach((key, value) {
    // `:525`.
    final newKey = prefix.isEmpty ? key : '$prefix.$key';
    if (value is Map<String, Object?>) {
      // `:530`.
      flattened.addAll(flattenObject(value, newKey));
    } else {
      // `:532`.
      flattened[newKey] = value;
    }
  });
  return flattened;
}

/// Reads a Plotly `line` block as stroke options
/// (`PlotlySchemaAdapter.ts:3332-3361`).
///
/// **Deviation:** `spline` sets `d3.curveCardinal.tension(1 - smoothing / 1.3)`
/// upstream (`:3344-3346`), a tension of 0.23076923076923073 at the default
/// smoothing of 1. [FluentLineCurve] is frozen cross-plan contract with five
/// arms and no tension-carrying cardinal — `model/line_options.dart:9-24`
/// records that the sixth upstream arm, a caller-supplied curve factory, has no
/// member — so a spline lands on [FluentLineCurve.natural], the one arm that is
/// a smooth interpolating spline. A spline is therefore drawn slightly tauter
/// than upstream draws it, and `line.smoothing` is inert. Widening the enum, or
/// giving [FluentLineOptions] a curve-factory door, is what would close this.
FluentLineOptions? getLineOptions(Map<String, Object?>? line) {
  // `:3333-3335`.
  if (line == null) return null;

  // `:3338-3340`: an unknown dash name indexes to undefined and spreading that
  // contributes nothing.
  final dash = line['dash'] is String ? kDashOptions[line['dash']] : null;

  return FluentLineOptions(
    strokeWidth: dash == null ? null : double.parse(dash.strokeWidth),
    strokeDasharray: dash?.strokeDasharray,
    strokeLinecap: switch (dash?.strokeLinecap) {
      'round' => StrokeCap.round,
      'butt' => StrokeCap.butt,
      _ => null,
    },
    lineBorderWidth: dash == null ? null : double.parse(dash.lineBorderWidth),
    // `:3342-3358`.
    curve: switch (line['shape']) {
      'spline' => FluentLineCurve.natural,
      'hv' => FluentLineCurve.stepAfter,
      'vh' => FluentLineCurve.stepBefore,
      'hvh' => FluentLineCurve.step,
      _ => FluentLineCurve.linear,
    },
  );
}

/// The bar geometry props a Plotly layout implies.
///
/// Upstream returns one of two disjoint `Pick<>` slices
/// (`PlotlySchemaAdapter.ts:3888-3889`); Dart gets one record with both halves
/// nullable, plus [isEmpty] for the `return {}` case at `:3917-3919`.
@immutable
class FluentPlotlyBarProps {
  /// Creates a bar-props record. All fields null means "inject nothing".
  const FluentPlotlyBarProps({
    this.barWidth,
    this.maxBarWidth,
    this.xAxisInnerPadding,
    this.xAxisOuterPadding,
    this.maxBarHeight,
    this.yAxisPadding,
  });

  /// `'auto'` on the vertical branch (`PlotlySchemaAdapter.ts:3929`).
  final String? barWidth;

  /// 1000 on the vertical branch (`PlotlySchemaAdapter.ts:3930`).
  final double? maxBarWidth;

  /// Band inner padding (`PlotlySchemaAdapter.ts:3931`).
  final double? xAxisInnerPadding;

  /// Band outer padding — always half the inner one
  /// (`PlotlySchemaAdapter.ts:3932`).
  final double? xAxisOuterPadding;

  /// 1000 on the horizontal branch (`PlotlySchemaAdapter.ts:3923`).
  final double? maxBarHeight;

  /// Band padding on the horizontal branch
  /// (`PlotlySchemaAdapter.ts:3924`).
  final double? yAxisPadding;

  /// Whether the layout implied no bar geometry at all.
  bool get isEmpty =>
      barWidth == null &&
      maxBarWidth == null &&
      xAxisInnerPadding == null &&
      xAxisOuterPadding == null &&
      maxBarHeight == null &&
      yAxisPadding == null;
}

/// Derives bar padding from `layout.bargap` and per-trace `width`
/// (`PlotlySchemaAdapter.ts:3883-3934`).
///
/// An out-of-range `bargap` clamps to **0.2**, Plotly's documented default. The
/// comment at `:3896-3898` is explicit that 0.2 is *not* used as this library's
/// default because it makes bars disproportionately wide in a large container —
/// it is only the out-of-range fallback, and the port keeps that distinction.
FluentPlotlyBarProps getBarProps(
  List<Object?> data,
  Map<String, Object?>? layout, {
  bool isHorizontal = false,
}) {
  double? padding;
  final bargap = layout?['bargap'];
  if (bargap is num) {
    padding = bargap >= 0 && bargap <= 1 ? bargap.toDouble() : 0.2;
  }

  final widths = <double>[];
  for (final trace in data) {
    if (trace is! Map<String, Object?> || trace['type'] != 'bar') continue;
    final w = trace['width'];
    if (w is num) widths.add(w.toDouble());
    if (w is List<Object?>) {
      for (final item in w) {
        if (item is num) widths.add(item.toDouble());
      }
    }
  }
  if (widths.isNotEmpty) {
    final maxWidth = widths.reduce((a, b) => a > b ? a : b);
    padding = (1 - maxWidth).clamp(0.0, 1.0);
  }

  if (padding == null) return const FluentPlotlyBarProps();
  if (isHorizontal) {
    return FluentPlotlyBarProps(maxBarHeight: 1000, yAxisPadding: padding);
  }
  return FluentPlotlyBarProps(
    barWidth: 'auto',
    maxBarWidth: 1000,
    xAxisInnerPadding: padding,
    xAxisOuterPadding: padding / 2,
  );
}
