import 'dart:math' as math;

import '../internal/d3/axis_geometry.dart' as d3;
import '../internal/d3/format.dart' as d3;
import '../internal/d3/scale_continuous.dart' as d3;
import '../internal/d3/scale_linear.dart' as d3;
import '../internal/d3/scale_log.dart' as d3;
import '../internal/d3/scale_time.dart' as d3;
import '../internal/d3/time_format.dart' as d3;
import '../model/chart_common.dart';
import 'axis_types.dart';
import 'tick_format.dart';
import 'tick_values.dart';

/// The x-axis `tickPadding` the shell hands the axis builders.
///
/// Ports `CartesianChart.tsx:215`, which reads
/// `tickPadding: props.tickPadding || props.showXAxisLablesTooltip ? 5 : 10`.
///
/// parity: JavaScript binds `||` tighter than `?:`, so that line parses as
/// `(props.tickPadding || props.showXAxisLablesTooltip) ? 5 : 10` and the
/// user's own `tickPadding` is only ever used as a *truth test* — a caller
/// asking for 25 gets 5. The author plainly meant
/// `props.tickPadding ?? (props.showXAxisLablesTooltip ? 5 : 10)`. The defect is
/// reproduced rather than corrected, because the captured geometry the port is
/// held against was rendered by the defective code
/// (`charts-verticalbarchart--vertical-bar-axis-tooltip` puts its x labels at
/// `y = 11`, which is `max(6, 0) + 5`).
///
/// [tickPadding] follows JavaScript truthiness, so an explicit `0` is falsy and
/// falls through to the else branch. 5 and 10 are the two literals at `:215`.
double resolveShellXAxisTickPadding({
  double? tickPadding,
  bool showXAxisLablesTooltip = false,
}) => (tickPadding != null && tickPadding != 0) || showXAxisLablesTooltip
    ? 5
    : 10;

/// A linear scale, or a log one when [scaleType] says so.
///
/// Ports `createNumericScale` (`utilities.ts:2224-2230`).
d3.ScaleContinuous _createNumericScale(FluentAxisScaleType? scaleType) =>
    scaleType == FluentAxisScaleType.log ? d3.scaleLog() : d3.scaleLinear();

/// Builds a numeric x axis.
///
/// Ports `createNumericXAxis` (`utilities.ts:251-332`). Notes worth carrying:
///
/// * `xMinValue` and `xMaxValue` can only *widen* the domain — upstream uses
///   `Math.min` and `Math.max` against the data extent (`:278-279`);
/// * `nice()` runs only when `showRoundOffXTickValues` is set (`:283`), but the
///   shell passes `?? true` (`CartesianChart.tsx:212`), so it is on for every
///   shell-driven numeric x axis;
/// * `hideTickOverlap` measures the longest label at d3's default ten ticks,
///   adds [kHideTickOverlapNumericPad] and clamps the result to
///   [kHideTickOverlapMaxTicks] (`:296-301`). The clamped value is a *target*
///   handed to `d3.ticks`, which returns whichever round step best fits it, so
///   the returned tick list is routinely one longer than the count;
/// * HorizontalBarChartWithAxis and GanttChart get a negative inner tick size,
///   which is a full-height gridline (`:308-310`);
/// * [FluentAxisSpec.tickPadding] is carried through untouched. The shell has
///   already collapsed it to 5 or 10 by then — see
///   [resolveShellXAxisTickPadding] for the precedence defect that does so.
///
/// The upstream `_useRtl` parameter is declared and never read (`:257`); RTL
/// reaches this builder only through an already-reversed domain, so it is not
/// part of the Dart signature.
FluentAxisSpec createNumericXAxis(
  FluentXAxisParams xAxisParams,
  FluentTickParams tickParams,
  FluentChartType chartType, {
  String? culture,
  FluentAxisScaleType? scaleType,
}) {
  final domainNRange = xAxisParams.domainNRangeValues;
  final dStartValue = (domainNRange.dStartValue as num).toDouble();
  final dEndValue = (domainNRange.dEndValue as num).toDouble();
  final finalXmin = xAxisParams.xMinValue != null
      ? math.min(dStartValue, xAxisParams.xMinValue!)
      : dStartValue;
  final finalXmax = xAxisParams.xMaxValue != null
      ? math.max(dEndValue, xAxisParams.xMaxValue!)
      : dEndValue;

  final scale = _createNumericScale(scaleType)
    ..domainOf(<double>[finalXmin, finalXmax])
    ..rangeOf(<double>[domainNRange.rStartValue, domainNRange.rEndValue]);
  if (xAxisParams.showRoundOffXTickValues) {
    // `nice` is declared on the two concrete scales rather than on
    // [d3.ScaleContinuous], because the linear one takes a tick count — left at
    // d3's own default of 10 here, as at utilities.ts:283 — and the log one
    // takes none.
    if (scale is d3.ScaleLinear) {
      scale.nice();
    } else if (scale is d3.ScaleLog) {
      scale.nice();
    }
  }

  // 6 is the default tick count at utilities.ts:285.
  var tickCount = xAxisParams.xAxisCount ?? 6;

  String formatTick(
    Object value,
    int index, [
    String Function(Object)? defaultFormat,
  ]) {
    final tickText = xAxisParams.tickText;
    if (tickParams.tickValues != null &&
        tickText != null &&
        index < tickText.length) {
      return tickText[index];
    }
    final specifier = tickParams.tickFormat;
    if (specifier != null) {
      return d3.format(specifier)(value as num);
    }
    // The empty-string short-circuit exists for log scales, where d3 blanks the
    // ticks between decades (utilities.ts:294).
    if (defaultFormat != null && defaultFormat(value) == '') {
      return '';
    }
    return formatToLocaleString(value, culture: culture);
  }

  if (xAxisParams.hideTickOverlap) {
    final measure = xAxisParams.calcMaxLabelWidth;
    final probeLabels = <String>[
      for (final (i, v) in scale.ticks().indexed) formatTick(v, i),
    ];
    // Upstream calls `calcMaxLabelWidth` unguarded (`:298`) and throws when the
    // caller left it out; 0 stands in here, which leaves the pad alone as the
    // per-label budget.
    final longestLabelWidth =
        (measure?.call(probeLabels) ?? 0) + kHideTickOverlapNumericPad;
    final range = scale.range;
    final span = (range.last - range.first).abs();
    tickCount = math.min(
      // 1 is the floor at utilities.ts:300, which keeps a range narrower than
      // one label from asking for zero ticks.
      math.max(1, (span / longestLabelWidth).floor()),
      kHideTickOverlapMaxTicks,
    );
  }

  var tickSizeInner = xAxisParams.xAxistickSize;
  if (chartType == FluentChartType.horizontalBarChartWithAxis ||
      chartType == FluentChartType.ganttChart) {
    // 0 stands in for an absent top margin, as upstream's `margins.top!`
    // asserts one is always resolved by then (`:309`).
    tickSizeInner =
        -(xAxisParams.containerHeight - (xAxisParams.margins.top ?? 0));
  }

  List<Object>? customTickValues;
  if (tickParams.tickValues != null) {
    customTickValues = tickParams.tickValues;
  } else if (xAxisParams.tickStep != null) {
    // Upstream's guard is `else if (tickStep)` (`:314`), so a 0 or empty-string
    // step is skipped there and admitted here; `generateNumericTicks` returns
    // null for both, which lands on the same generated ticks either way.
    customTickValues = generateNumericTicks(
      scaleType,
      xAxisParams.tickStep!,
      xAxisParams.tick0,
      scale.domain.map((d) => (d as num).toDouble()).toList(),
    );
  }

  final tickValues = customTickValues ?? scale.ticks(tickCount);
  final defaultFormat = scale.tickFormat(tickCount);
  final tickLabels = <String>[
    for (final (i, v) in tickValues.indexed) formatTick(v, i, defaultFormat),
  ];

  return FluentAxisSpec(
    scale: scale,
    tickValues: tickValues,
    tickLabels: tickLabels,
    orientation: d3.FluentAxisOrientation.bottom,
    tickSizeInner: tickSizeInner,
    // d3-axis leaves tickSizeOuter at 6 unless a caller changes it, and no
    // caller here does (utilities.ts:303-307).
    tickSizeOuter: 6,
    tickPadding: xAxisParams.tickPadding,
  );
}

/// Builds a date x axis.
///
/// Ports `createDateXAxis` (`utilities.ts:441-546`). Differences from the
/// numeric axis that are easy to lose:
///
/// * `nice()` is **unconditional** here (`:468`), where the numeric axis gates
///   it on [FluentXAxisParams.showRoundOffXTickValues];
/// * the destructured `tickPadding` default is `6`, not `10` (`:454`);
/// * `hideTickOverlap` pads by [kHideTickOverlapDatePad], twice the numeric pad
///   (`:519`);
/// * only [FluentChartType.ganttChart] gets the gridline override (`:529-531`) —
///   [FluentChartType.horizontalBarChartWithAxis] does not, even though it does
///   on the numeric axis (`:308`);
/// * there is no `isRtl` parameter at all; RTL arrives as a reversed domain.
///
/// The format levels are scanned over d3's own default ten ticks (`:477`), and
/// the two derived formatters are independent: the strftime one is used only
/// when [timeFormatLocale] is supplied, the Intl one otherwise.
///
/// One shared-type consequence: [FluentXAxisParams.tickPadding] carries the
/// numeric-axis default of `10`, so a caller who wants the date axis's own
/// destructured `6` has to pass it. Upstream gets that for free because each
/// builder destructures its own default out of the same bag, and the port has
/// one class and therefore one default. In practice the difference is invisible
/// from the shell, which always resolves a `tickPadding` of its own
/// (`CartesianChart.tsx:215`) and so never lets either default apply — the
/// captured LineChart date axis puts its labels at `y = 16`, which is
/// `max(6, 0) + 10`.
///
/// [useUtc] is upstream's `string | boolean` union (`:448`), so it arrives as an
/// [Object].
FluentAxisSpec createDateXAxis(
  FluentXAxisParams xAxisParams,
  FluentTickParams tickParams, {
  String? culture,
  FluentDateTimeFormatOptions? options,
  d3.TimeLocaleDefinition? timeFormatLocale,
  String Function(DateTime)? customDateTimeFormatter,
  Object? useUtc,
  FluentChartType? chartType,
}) {
  final domainNRange = xAxisParams.domainNRangeValues;
  // utilities.ts:463 accepts the boolean true or the string 'utc'.
  final isUtcSet = useUtc == true || useUtc == 'utc';
  final scale = isUtcSet ? d3.scaleUtc() : d3.scaleTime();
  scale
    ..domainOfDates(<DateTime>[
      domainNRange.dStartValue as DateTime,
      domainNRange.dEndValue as DateTime,
    ])
    ..rangeOf(<double>[domainNRange.rStartValue, domainNRange.rEndValue])
    ..nice();

  // 6 is the default tick count at utilities.ts:470.
  var tickCount = xAxisParams.xAxisCount ?? 6;

  // 100 and -1 are the sentinels at utilities.ts:472-473; they survive when the
  // scale produces no ticks, which is why the Intl table is total.
  var lowestFormatLevel = 100;
  var highestFormatLevel = -1;
  for (final tick in scale.ticks()) {
    final level = getDateFormatLevel(tick as DateTime, useUtc: isUtcSet);
    if (level > highestFormatLevel) {
      highestFormatLevel = level;
    }
    if (level < lowestFormatLevel) {
      lowestFormatLevel = level;
    }
  }

  final formatOptions =
      options ??
      multiLevelDateTimeFormatOptions(lowestFormatLevel, highestFormatLevel);
  final locale = timeFormatLocale != null
      ? d3.timeFormatLocale(timeFormatLocale)
      : null;
  String Function(DateTime)? localeFormat;
  if (locale != null) {
    // utilities.ts:490-495 builds this formatter unconditionally, so an empty
    // tick list would index the table with the sentinels and throw there;
    // building it only under a locale keeps the one reachable call in range.
    final specifier = multiLevelD3DateFormat(
      lowestFormatLevel,
      highestFormatLevel,
    );
    localeFormat = isUtcSet
        ? locale.utcFormat(specifier)
        : locale.format(specifier);
  }

  String formatTick(DateTime value, int index) {
    final tickText = xAxisParams.tickText;
    if (tickParams.tickValues != null &&
        tickText != null &&
        index < tickText.length) {
      return tickText[index];
    }
    if (customDateTimeFormatter != null) {
      return customDateTimeFormatter(value);
    }
    if (localeFormat != null) {
      return localeFormat(value);
    }
    final specifier = tickParams.tickFormat;
    if (culture == null && specifier != null) {
      // utilities.ts:509 branches on `useUTC`'s truthiness rather than on
      // `isUtcSet`, so any non-empty string picks the UTC formatter.
      return _isUtcTruthy(useUtc)
          ? d3.utcFormat(specifier)(value)
          : d3.timeFormat(specifier)(value);
    }
    // utilities.ts:515 passes showTZname false — the one caller that does.
    return formatDateToLocaleString(
      value,
      culture: culture,
      useUtc: _isUtcTruthy(useUtc),
      showTZname: false,
      options: formatOptions,
    );
  }

  if (xAxisParams.hideTickOverlap) {
    final measure = xAxisParams.calcMaxLabelWidth;
    final probeLabels = <String>[
      for (final (i, v) in scale.ticks().indexed) formatTick(v as DateTime, i),
    ];
    // Upstream calls `calcMaxLabelWidth` unguarded (`:519`) and throws when the
    // caller left it out; 0 stands in here, which leaves the pad alone as the
    // per-label budget.
    final longestLabelWidth =
        (measure?.call(probeLabels) ?? 0) + kHideTickOverlapDatePad;
    final range = scale.range;
    final span = (range.last - range.first).abs();
    tickCount = math.min(
      // 1 is the floor at utilities.ts:521, which keeps a range narrower than
      // one label from asking for zero ticks.
      math.max(1, (span / longestLabelWidth).floor()),
      kHideTickOverlapMaxTicks,
    );
  }

  var tickSizeInner = xAxisParams.xAxistickSize;
  if (chartType == FluentChartType.ganttChart) {
    // 0 stands in for an absent top margin, as upstream's `margins.top!`
    // asserts one is always resolved by then (`:530`).
    tickSizeInner =
        -(xAxisParams.containerHeight - (xAxisParams.margins.top ?? 0));
  }

  List<Object>? customTickValues;
  if (tickParams.tickValues != null) {
    customTickValues = tickParams.tickValues;
  } else if (xAxisParams.tickStep != null) {
    // Upstream's guard is `else if (tickStep)` (`:536`), so a 0 or empty-string
    // step is skipped there and admitted here; `generateDateTicks` returns null
    // for both, which lands on the same generated ticks either way.
    //
    // parity: upstream hands `useUTC as boolean` straight through (`:537`),
    // which for a truthy string other than 'utc' would put the ticks in UTC
    // while the scale itself stayed local. [isUtcSet] keeps the two agreed,
    // and the two values coincide over the documented `true | 'utc'` union.
    customTickValues = generateDateTicks(
      xAxisParams.tickStep!,
      xAxisParams.tick0,
      scale.domain.cast<DateTime>(),
      useUtc: isUtcSet,
    );
  }

  final tickValues = customTickValues ?? scale.ticks(tickCount);
  final tickLabels = <String>[
    for (final (i, v) in tickValues.indexed) formatTick(v as DateTime, i),
  ];

  return FluentAxisSpec(
    scale: scale,
    tickValues: tickValues,
    tickLabels: tickLabels,
    orientation: d3.FluentAxisOrientation.bottom,
    tickSizeInner: tickSizeInner,
    // d3-axis leaves tickSizeOuter at 6 unless a caller changes it, and no
    // caller here does (utilities.ts:524-528).
    tickSizeOuter: 6,
    tickPadding: xAxisParams.tickPadding,
  );
}

/// Whether [useUtc] would be truthy in JavaScript.
///
/// `utilities.ts:509` and `:515` test `useUTC` itself rather than the narrowed
/// `isUtcSet`, so the string `'utc'` and any other non-empty string both count
/// while `false`, `undefined` and `''` do not.
bool _isUtcTruthy(Object? useUtc) =>
    useUtc != null && useUtc != false && useUtc != '';
