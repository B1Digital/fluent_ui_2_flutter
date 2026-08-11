import 'dart:math' as math;

import '../internal/d3/axis_geometry.dart' as d3;
import '../internal/d3/format.dart' as d3;
import '../internal/d3/scale_band.dart' as d3;
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

/// Builds a band x axis.
///
/// Ports `createStringXAxis` (`utilities.ts:559-638`). Both the `culture` and
/// `_useRtl` parameters are unread upstream; [culture] is kept on the Dart
/// signature because the cross-plan contract declares it, and RTL arrives as a
/// descending range rather than a flag.
///
/// The anti-collision sweep at `:595-621` runs right to left, keeping a label
/// only when its half-width clears both the running boundary and the container
/// edge, then backing the boundary off by that half-width plus
/// [kBandSweepGap].
FluentAxisSpec createStringXAxis(
  FluentXAxisParams xAxisParams,
  FluentTickParams tickParams,
  List<String> dataset, {
  String? culture,
}) {
  final domainNRange = xAxisParams.domainNRangeValues;
  // 0.1 is the shorthand padding default at utilities.ts:574.
  final shorthandPadding = xAxisParams.xAxisPadding ?? 0.1;
  final scale = d3.scaleBand()
    ..domainOf(dataset.cast<Object>())
    ..rangeOf(<double>[domainNRange.rStartValue, domainNRange.rEndValue])
    ..paddingInner(xAxisParams.xAxisInnerPadding ?? shorthandPadding)
    ..paddingOuter(xAxisParams.xAxisOuterPadding ?? shorthandPadding);

  var tickValues = <String>[
    ...(tickParams.tickValues?.cast<String>() ?? dataset),
  ];

  if (xAxisParams.hideTickOverlap) {
    final measure = xAxisParams.calcMaxLabelWidth;
    // Upstream calls `calcMaxLabelWidth` unguarded (`:597`) and throws when the
    // caller left it out; 0 stands in here, which keeps every label zero-width
    // and so keeps every tick.
    final tickSizes = <double>[
      for (final value in tickValues) measure?.call(<String>[value]) ?? 0,
    ];
    // 0 and containerWidth are the LTR boundaries at utilities.ts:599-600.
    var start = 0.0;
    var end = xAxisParams.containerWidth;
    var sign = 1.0;
    final range = scale.range;
    if (range[1] - range[0] < 0) {
      // utilities.ts:603-607 — a descending range is RTL, so the sweep starts
      // at the right-hand container edge and walks the other way.
      start = xAxisParams.containerWidth;
      end = 0;
      sign = -1;
    }
    final kept = <String>[];
    for (var i = tickValues.length - 1; i >= 0; i--) {
      // parity: utilities.ts:610 reads the band's LEADING edge here, while
      // d3-axis draws the tick at leadingEdge + bandwidth / 2, so every
      // collision test is systematically half a band out. `autoLayoutXAxisLabels`
      // at `:2597` adds `scale.bandwidth() / 2` for the same decision, so the
      // two label-fitting passes disagree about where a band label sits.
      final position = scale(tickValues[i]);
      if (position == null) {
        // Unreachable while the tick values come from the domain; upstream's
        // non-null assertion at `:610` would give NaN and fail both tests.
        continue;
      }
      // utilities.ts:612-613 writes `(sign * tickSizes[i]) / 2`, so the signed
      // half-width is subtracted on the leading side and added on the trailing
      // one — which under RTL swaps which side is which.
      final halfWidth = sign * tickSizes[i] / 2;
      if (sign * (position - halfWidth - start) >= 0 &&
          sign * (position + halfWidth - end) <= 0) {
        kept.add(tickValues[i]);
        end = position - sign * (tickSizes[i] / 2 + kBandSweepGap);
      }
    }
    // utilities.ts:619 reverses the right-to-left accumulation back into
    // domain order.
    tickValues = kept.reversed.toList();
  }

  final tickText = xAxisParams.tickText;
  final tickLabels = <String>[
    for (final (i, value) in tickValues.indexed)
      // parity: utilities.ts:590 with :637 — after the sweep the index is a
      // position in the FILTERED list, so tickText no longer lines up with the
      // categories the caller supplied it for.
      if (tickParams.tickValues != null &&
          tickText != null &&
          i < tickText.length)
        tickText[i]
      else
        value,
  ];

  return FluentAxisSpec(
    scale: scale,
    tickValues: tickValues.cast<Object>(),
    tickLabels: tickLabels,
    orientation: d3.FluentAxisOrientation.bottom,
    tickSizeInner: xAxisParams.xAxistickSize,
    // d3-axis leaves tickSizeOuter at 6 unless a caller changes it, and
    // utilities.ts:623-627 changes only the inner size and the padding.
    tickSizeOuter: 6,
    tickPadding: xAxisParams.tickPadding,
  );
}

/// Resolves the tick label for a y axis, shared by the y builders.
///
/// Ports the `tickFormat` closure at `utilities.ts:865-877`: an explicit
/// [tickText] entry wins, then a caller function, then a d3 format specifier,
/// then the default SI formatter with the log-scale blanking short-circuit.
///
/// [yAxisTickFormat] is upstream's `string | function` union
/// (`CartesianChart.types.ts` via `utilities.ts:810`), so it arrives as an
/// [Object]; a callable is recognised only at the exact shape
/// `String Function(Object value, int index)`.
String _formatYTick(
  Object value,
  int index, {
  required List<Object>? tickValues,
  required List<String>? tickText,
  required Object? yAxisTickFormat,
  String Function(Object)? defaultFormat,
}) {
  if (tickValues != null && tickText != null && index < tickText.length) {
    return tickText[index];
  }
  if (yAxisTickFormat is String Function(Object, int)) {
    return yAxisTickFormat(value, index);
  }
  if (yAxisTickFormat is String) {
    return d3.format(yAxisTickFormat)(value as num);
  }
  // The empty-string short-circuit exists for log scales, where d3 blanks the
  // ticks between decades (utilities.ts:876).
  if (defaultFormat != null && defaultFormat(value) == '') {
    return '';
  }
  return defaultYAxisTickFormatter((value as num).toDouble());
}

/// Builds a numeric y axis.
///
/// Ports `createNumericYAxis` (`utilities.ts:789-893`). Four behaviours that are
/// easy to get wrong:
///
/// * the ceiling is `maxOfYVal || endValue || 0` (`:821`), which uses JavaScript
///   truthiness, so a caller-supplied `0` falls through to the data extent;
/// * the floor is `min(startValue || 0, yMinValue || 0)` (`:823`), so a series
///   of entirely positive values still anchors at zero;
/// * `prepareDatapoints`'s output becomes the literal tick set unless the scale
///   is logarithmic (`:862`), in which case d3's own log ticks apply;
/// * the inner tick size is negative, spanning the plot as a gridline (`:851`),
///   while the outer size stays at d3's default 6.
///
/// Lines `825-831` compute a ScatterChart y padding and then never read it —
/// `:832` rebuilds the domain from `domainValues`. That block is dead and is not
/// ported; the real scatter padding lives in the chart, at
/// `ScatterChart.tsx:188-191`. [chartType] is therefore read nowhere in this
/// body, and is kept only because the cross-plan contract declares it and the
/// sibling builders take it.
///
/// The secondary axis's `text-anchor` is set to the boolean `false` upstream
/// (`:886`), which the browser rejects, so the secondary axis keeps d3-axis's
/// own `start` anchor. The port reproduces that by simply not overriding the
/// anchor derived from the orientation.
///
/// The upstream `_useRtl` parameter (`:798`) only ever picks between the two
/// `text-anchor` values at `:886`, both of which d3-axis already derives from
/// the orientation, so it is not part of the Dart signature.
FluentAxisSpec createNumericYAxis(
  FluentYAxisParams yAxisParams,
  FluentAxisData axisData, {
  required bool isRtl,
  required bool isIntegralDataset,
  required FluentChartType chartType,
  bool useSecondaryYScale = false,
  FluentAxisScaleType? scaleType,
}) {
  final minMax = yAxisParams.yMinMaxValues;
  // parity: utilities.ts:821 uses || rather than ??, so a legitimate zero in
  // maxOfYVal or endValue is discarded in favour of the next term. 0 is the
  // final fallback that line spells out.
  final tempVal = yAxisParams.maxOfYVal != 0
      ? yAxisParams.maxOfYVal
      : (minMax.endValue != 0 ? minMax.endValue : 0.0);
  final finalYmax = tempVal > yAxisParams.yMaxValue
      ? tempVal
      : yAxisParams.yMaxValue;
  // utilities.ts:823 — the same `|| 0` truthiness on both arms, so a floor of
  // exactly 0 and an absent floor are indistinguishable.
  final finalYmin = math.min(
    minMax.startValue != 0 ? minMax.startValue : 0.0,
    yAxisParams.yMinValue != 0 ? yAxisParams.yMinValue : 0.0,
  );

  final domainValues = prepareDatapoints(
    finalYmax,
    finalYmin,
    yAxisParams.yAxisTickCount,
    isIntegralDataset: isIntegralDataset,
    roundedTicks: yAxisParams.roundedTicks,
  );
  var scaleDomain = <double>[domainValues.first, domainValues.last];

  if (scaleType == FluentAxisScaleType.log) {
    // utilities.ts:835-836 starts from the raw extent, so the prepared domain is
    // discarded entirely here; 0 at `:837` and `:840` is the "no user bound"
    // sentinel [FluentYAxisParams.yMinValue] and
    // [FluentYAxisParams.yMaxValue] default to.
    var domainStart = minMax.startValue;
    var domainEnd = minMax.endValue;
    if (yAxisParams.yMinValue > 0) {
      domainStart = math.min(domainStart, yAxisParams.yMinValue);
    }
    if (yAxisParams.yMaxValue > 0) {
      domainEnd = math.max(domainEnd, yAxisParams.yMaxValue);
    }
    scaleDomain = <double>[domainStart, domainEnd];
  }

  // The range is inverted — the domain floor sits at the bottom of the plot.
  // 0 stands in for the margins upstream asserts are always resolved by then
  // (`:848`) and for the event-label height it gates on `eventAnnotationProps`
  // being present, which the port folds into nullability.
  final scale = _createNumericScale(scaleType)
    ..domainOf(scaleDomain)
    ..rangeOf(<double>[
      yAxisParams.containerHeight - (yAxisParams.margins.bottom ?? 0),
      (yAxisParams.margins.top ?? 0) + (yAxisParams.eventLabelHeight ?? 0),
    ]);

  final orientation =
      (!isRtl && useSecondaryYScale) || (isRtl && !useSecondaryYScale)
      ? d3.FluentAxisOrientation.right
      : d3.FluentAxisOrientation.left;

  List<Object>? customTickValues;
  if (yAxisParams.tickValues != null) {
    customTickValues = yAxisParams.tickValues;
  } else if (yAxisParams.tickStep != null) {
    // Upstream's guard is `else if (tickStep)` (`:855`), so a 0 or empty-string
    // step is skipped there and admitted here; `generateNumericTicks` returns
    // null for both, which lands on the same generated ticks either way.
    customTickValues = generateNumericTicks(
      scaleType,
      yAxisParams.tickStep!,
      yAxisParams.tick0,
      scale.domain.map((d) => (d as num).toDouble()).toList(),
    );
  }

  // utilities.ts:860 assigns axisData.yAxisDomainValues here and :889 overwrites
  // it unconditionally, so that assignment is dead and is not ported.
  final tickValues =
      customTickValues ??
      (scaleType != FluentAxisScaleType.log
          ? domainValues.cast<Object>()
          : scale.ticks(yAxisParams.yAxisTickCount));

  final defaultFormat = scale.tickFormat(yAxisParams.yAxisTickCount);
  final tickLabels = <String>[
    for (final (i, value) in tickValues.indexed)
      _formatYTick(
        value,
        i,
        tickValues: yAxisParams.tickValues,
        tickText: yAxisParams.tickText,
        yAxisTickFormat: yAxisParams.yAxisTickFormat,
        defaultFormat: defaultFormat,
      ),
  ];

  axisData
    ..yAxisDomainValues = scale.domain
        .map((d) => (d as num).toDouble())
        .toList()
    ..yAxisTickText = tickLabels;

  return FluentAxisSpec(
    scale: scale,
    tickValues: tickValues,
    tickLabels: tickLabels,
    orientation: orientation,
    tickSizeInner:
        -(yAxisParams.containerWidth -
            (yAxisParams.margins.left ?? 0) -
            (yAxisParams.margins.right ?? 0)),
    // d3-axis leaves tickSizeOuter at 6 unless a caller changes it, and
    // utilities.ts:851 changes only the padding and the inner size.
    tickSizeOuter: 6,
    tickPadding: yAxisParams.tickPadding,
  );
}

/// Builds the numeric y axis of HorizontalBarChartWithAxis and GanttChart.
///
/// Ports `createYAxisForHorizontalBarChartWithAxis` (`utilities.ts:725-787`).
/// It differs from [createNumericYAxis] in three ways worth stating: there is no
/// `prepareDatapoints` pass and no `nice()`, so the domain is the raw extent
/// (`:751-753`); the tick sizes stay at d3's default six, so this axis draws no
/// gridlines (`:754-755`); and the floor rule is
/// `startValue < yMinValue ? min(0, startValue) : yMinValue` (`:750`), a
/// different shape from the other builder's `min(startValue || 0, yMinValue || 0)`.
///
/// The `tickStep` path hard-wires `scaleType` to `undefined` upstream (`:775`),
/// which makes the `'L<f>'` log step form unreachable here.
///
/// Upstream takes `isRtl` as its second positional parameter and [axisData] as
/// its third (`:726-728`); the port keeps [axisData] positional, to match
/// [createNumericYAxis], and makes [isRtl] a named requirement.
FluentAxisSpec createYAxisForHorizontalBarChartWithAxis(
  FluentYAxisParams yAxisParams,
  FluentAxisData axisData, {
  required bool isRtl,
}) {
  final minMax = yAxisParams.yMinMaxValues;
  // parity: utilities.ts:748 uses || with no trailing `|| 0`, unlike :821, so a
  // chart-computed ceiling of exactly 0 falls through to the data extent.
  final tempVal = yAxisParams.maxOfYVal != 0
      ? yAxisParams.maxOfYVal
      : minMax.endValue;
  final finalYmax = tempVal > yAxisParams.yMaxValue
      ? tempVal
      : yAxisParams.yMaxValue;
  // utilities.ts:750 — 0 is the literal floor that line clamps against, so a
  // data floor above the user's still anchors no higher than zero.
  final finalYmin = minMax.startValue < yAxisParams.yMinValue
      ? math.min<double>(0, minMax.startValue)
      : yAxisParams.yMinValue;

  // The range is inverted — the domain floor sits at the bottom of the plot. 0
  // stands in for the margins upstream asserts are always resolved by then
  // (`:753`).
  final scale = d3.scaleLinear()
    ..domainOf(<double>[finalYmin, finalYmax])
    ..rangeOf(<double>[
      yAxisParams.containerHeight - (yAxisParams.margins.bottom ?? 0),
      yAxisParams.margins.top ?? 0,
    ]);

  List<Object>? customTickValues;
  if (yAxisParams.tickValues != null) {
    customTickValues = yAxisParams.tickValues;
  } else if (yAxisParams.tickStep != null) {
    // Upstream's guard is `else if (tickStep)` (`:774`), so a 0 or empty-string
    // step is skipped there and admitted here; `generateNumericTicks` returns
    // null for both, which lands on the same generated ticks either way.
    //
    // parity: utilities.ts:775 passes `undefined` for scaleType.
    customTickValues = generateNumericTicks(
      null,
      yAxisParams.tickStep!,
      yAxisParams.tick0,
      scale.domain.map((d) => (d as num).toDouble()).toList(),
    );
  }

  // utilities.ts:784 falls back to `yAxisScale.ticks(yAxisTickCount)` when no
  // custom set was installed, which is the same list `.ticks(yAxisTickCount)` at
  // `:755` already put on the axis.
  final tickValues =
      customTickValues ?? scale.ticks(yAxisParams.yAxisTickCount);
  // There is no log-blanking short-circuit in this builder's `tickFormat`
  // (`:756-768`), so no default formatter is handed to [_formatYTick].
  final tickLabels = <String>[
    for (final (i, value) in tickValues.indexed)
      _formatYTick(
        value,
        i,
        tickValues: yAxisParams.tickValues,
        tickText: yAxisParams.tickText,
        yAxisTickFormat: yAxisParams.yAxisTickFormat,
      ),
  ];

  axisData
    ..yAxisDomainValues = scale.domain
        .map((d) => (d as num).toDouble())
        .toList()
    ..yAxisTickText = tickLabels;

  return FluentAxisSpec(
    scale: scale,
    tickValues: tickValues,
    tickLabels: tickLabels,
    orientation: isRtl
        ? d3.FluentAxisOrientation.right
        : d3.FluentAxisOrientation.left,
    // Both sizes stay at d3-axis's own default of 6, because utilities.ts:755
    // sets only the padding and the tick count.
    tickSizeInner: 6,
    tickSizeOuter: 6,
    tickPadding: yAxisParams.tickPadding,
  );
}

/// Builds a band y axis for every chart except HorizontalBarChartWithAxis.
///
/// Ports `createStringYAxis` (`utilities.ts:950-996`). The chain ends with
/// `tickSize(0)` (`:987`), which zeroes both the inner and outer sizes, so this
/// axis normally draws no tick line at all, and its domain path is the bare
/// spine with no end caps. VerticalStackedBarChart then takes two overrides:
/// `paddingInner(1).paddingOuter(0)` (`:973-975`), which collapses the band to a
/// point position, and an inner tick size spanning the plot (`:988-990`) —
/// leaving the final geometry at inner `-(plotWidth)` with outer still `0`.
///
/// Unlike [createNumericYAxis] this builder writes only
/// [FluentAxisData.yAxisTickText] (`:993`); there is no counterpart to the
/// `yAxisDomainValues` assignment at `:889`, because a band domain is not a
/// numeric pair.
///
/// The upstream `barWidth` parameter (`:955`) is never read and is not ported.
FluentAxisSpec createStringYAxis(
  FluentYAxisParams yAxisParams,
  List<String> dataPoints,
  FluentAxisData axisData, {
  required bool isRtl,
  FluentChartType? chartType,
}) {
  // 0 stands in for the margins upstream asserts are always resolved by then
  // (`:971`).
  final scale = d3.scaleBand()
    ..domainOf(dataPoints.cast<Object>())
    ..rangeOf(<double>[
      yAxisParams.containerHeight - (yAxisParams.margins.bottom ?? 0),
      yAxisParams.margins.top ?? 0,
    ])
    ..padding(yAxisParams.yAxisPadding);
  if (chartType == FluentChartType.verticalStackedBarChart) {
    scale
      ..paddingInner(1)
      ..paddingOuter(0);
  }

  final tickValues = <Object>[
    ...(yAxisParams.tickValues ?? dataPoints.cast<Object>()),
  ];
  final tickLabels = <String>[
    for (final (i, value) in tickValues.indexed)
      _formatBandTick(
        value,
        i,
        tickValues: yAxisParams.tickValues,
        tickText: yAxisParams.tickText,
        yAxisTickFormat: yAxisParams.yAxisTickFormat,
      ),
  ];

  axisData.yAxisTickText = tickLabels;

  // tickSize(0) zeroes both sizes (utilities.ts:987); VSBC then re-sets only the
  // inner one (:988-990).
  final tickSizeInner = chartType == FluentChartType.verticalStackedBarChart
      ? -(yAxisParams.containerWidth -
            (yAxisParams.margins.left ?? 0) -
            (yAxisParams.margins.right ?? 0))
      : 0.0;

  return FluentAxisSpec(
    scale: scale,
    tickValues: tickValues,
    tickLabels: tickLabels,
    orientation: isRtl
        ? d3.FluentAxisOrientation.right
        : d3.FluentAxisOrientation.left,
    tickSizeInner: tickSizeInner,
    tickSizeOuter: 0,
    tickPadding: yAxisParams.tickPadding,
  );
}

/// Builds the band y axis of HorizontalBarChartWithAxis.
///
/// Ports `createStringYAxisForHorizontalBarChartWithAxis`
/// (`utilities.ts:901-942`). A padding of exactly `1` is rewritten to `0.99`
/// (`:920`) so the bandwidth — and therefore every bar's height — never
/// collapses to zero; the same clamp is duplicated at
/// `HorizontalBarChartWithAxis.tsx:531`.
///
/// parity: `:919` reads `yAxisPadding ?? 0.5`, a default this port does not
/// repeat, because [FluentYAxisParams.yAxisPadding] is not nullable and falls
/// back to `0` (`utilities.ts:964`). The arm is unreachable upstream anyway —
/// this builder is wired in by HorizontalBarChartWithAxis alone
/// (`HorizontalBarChartWithAxis.tsx:920`), and `:77` has already resolved
/// `props.yAxisPadding ?? 0.5` before `:907` passes it down — so a caller that
/// wants the upstream default passes `0.5` itself.
///
/// Unlike [createStringYAxis] the tick sizes are left at d3's default six
/// (`:936` sets only the padding, the tick values and the format), so this axis
/// draws a short tick line and its domain path keeps both end caps. The upstream
/// `barWidth` parameter (`:906`) is never read and is not ported.
FluentAxisSpec createStringYAxisForHorizontalBarChartWithAxis(
  FluentYAxisParams yAxisParams,
  List<String> dataPoints,
  FluentAxisData axisData, {
  required bool isRtl,
}) {
  // 0.99 is the anti-collapse clamp at utilities.ts:920.
  var padding = yAxisParams.yAxisPadding;
  if (padding == 1) {
    padding = 0.99;
  }

  // 0 stands in for the margins upstream asserts are always resolved by then
  // (`:923`).
  final scale = d3.scaleBand()
    ..domainOf(dataPoints.cast<Object>())
    ..rangeOf(<double>[
      yAxisParams.containerHeight - (yAxisParams.margins.bottom ?? 0),
      yAxisParams.margins.top ?? 0,
    ])
    ..padding(padding);

  final tickValues = <Object>[
    ...(yAxisParams.tickValues ?? dataPoints.cast<Object>()),
  ];
  final tickLabels = <String>[
    for (final (i, value) in tickValues.indexed)
      _formatBandTick(
        value,
        i,
        tickValues: yAxisParams.tickValues,
        tickText: yAxisParams.tickText,
        yAxisTickFormat: yAxisParams.yAxisTickFormat,
      ),
  ];

  axisData.yAxisTickText = tickLabels;

  return FluentAxisSpec(
    scale: scale,
    tickValues: tickValues,
    tickLabels: tickLabels,
    orientation: isRtl
        ? d3.FluentAxisOrientation.right
        : d3.FluentAxisOrientation.left,
    // Both sizes stay at d3-axis's default 6 (utilities.ts:936).
    tickSizeInner: 6,
    tickSizeOuter: 6,
    tickPadding: yAxisParams.tickPadding,
  );
}

/// Resolves a band y tick label.
///
/// Ports the `tickFormat` closure at `utilities.ts:978-986` and `:927-935`:
/// [tickText] wins, then a caller function, then the raw category string. There
/// is no d3-format arm and no blanking short-circuit on a band axis.
///
/// [yAxisTickFormat] carries the same `string | function` union as on
/// [FluentYAxisParams.yAxisTickFormat], but only the function arm is reachable
/// here (`:982`), so a specifier string falls through to the category itself.
String _formatBandTick(
  Object value,
  int index, {
  required List<Object>? tickValues,
  required List<String>? tickText,
  required Object? yAxisTickFormat,
}) {
  if (tickValues != null && tickText != null && index < tickText.length) {
    return tickText[index];
  }
  if (yAxisTickFormat is String Function(Object, int)) {
    return yAxisTickFormat(value, index);
  }
  return value.toString();
}

/// Whether [useUtc] would be truthy in JavaScript.
///
/// `utilities.ts:509` and `:515` test `useUTC` itself rather than the narrowed
/// `isUtcSet`, so the string `'utc'` and any other non-empty string both count
/// while `false`, `undefined` and `''` do not.
bool _isUtcTruthy(Object? useUtc) =>
    useUtc != null && useUtc != false && useUtc != '';
