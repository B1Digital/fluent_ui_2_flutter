import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import 'axis/axis_builders.dart' as builders;
import 'axis/axis_types.dart';
import 'axis/domain_range.dart';
import 'axis/tick_format.dart';
import 'cartesian/cartesian_chart.dart';
import 'cartesian/cartesian_chart_props.dart';
import 'cartesian/cartesian_layout.dart';
import 'cartesian/cartesian_series_delegate.dart';
import 'chrome/legend.dart';
import 'internal/chart_colors.dart';
import 'internal/chart_text_measurer.dart';
import 'internal/chart_text_styles.dart';
import 'internal/chart_utils.dart';
import 'internal/d3/array_stats.dart' as d3;
import 'internal/d3/scale.dart';
import 'internal/d3/scale_linear.dart';
import 'model/bar_data.dart';
import 'model/chart_common.dart';
import 'model/chart_value.dart';
import 'model/line_options.dart';
import 'vertical_stacked_bar_chart_style.dart';

/// Fraction of a stack's height that may be spent on gaps
/// (`VerticalStackedBarChart.tsx:64`).
const double kBarGapMultiplier = 0.2;

/// Floor on a gap once gaps are enabled (`VerticalStackedBarChart.tsx:65`).
const double kBarGapMin = 1;

/// The y value a numeric stack is measured from — `Y_ORIGIN`, which upstream
/// fixes at 0 (`VerticalStackedBarChart.tsx:118`).
const double kStackedBarYOrigin = 0;

/// The output of the vertical stacked bar chart's gap-and-scale solve.
@immutable
class FluentStackedBarGapMetrics {
  /// Creates the metrics.
  const FluentStackedBarGapMetrics({
    required this.gapHeight,
    required this.heightValueScale,
    required this.absStackTotal,
  });

  /// Pixels between adjacent segments, 0 when `barGapMax` is 0.
  final double gapHeight;

  /// Pixels per data unit once the gaps have been deducted. Always 0 on a
  /// category y axis.
  final double heightValueScale;

  /// The sum of the segments' absolute values, 0 on a category y axis.
  final double absStackTotal;
}

/// Ports `_getBarGapAndScale` (`VerticalStackedBarChart.tsx:806-847`).
///
/// The subtle part is the one-percent floor: each segment's share is raised to
/// 1% **before** the shares are summed (`:829-835`), so `scalingRatio` can
/// exceed 1 and shrink every segment in the stack. A share of exactly 0 is
/// exempt, which is why the guard reads `v < 1 && v !== 0`.
///
/// [defaultTotalHeight] overrides the height measured through [yBarScale], as
/// upstream's `defaultTotalHeight ??` arms do (`:821-822`, `:827-828`).
FluentStackedBarGapMetrics computeFluentStackedBarGapMetrics({
  required List<FluentStackedBarDatum> bars,
  required Scale yBarScale,
  required bool isStringYAxis,
  required double barGapMax,
  double? defaultTotalHeight,
}) {
  double totalData = 0;
  final double totalHeight;
  double scalingRatio = 1;

  if (isStringYAxis) {
    totalHeight =
        defaultTotalHeight ??
        bars.fold<double>(
          0,
          (double acc, FluentStackedBarDatum b) =>
              acc + (yBarScale(b.data) ?? 0),
        );
  } else {
    for (final b in bars) {
      totalData += (b.data as num).toDouble().abs();
    }
    totalHeight =
        defaultTotalHeight ??
        ((yBarScale(totalData) ?? 0) - (yBarScale(kStackedBarYOrigin) ?? 0))
            .abs();
    double sumOfPercent = 0;
    for (final b in bars) {
      // `:830` — the share as a percentage, then the floor at `:831-833`.
      var value = ((b.data as num).toDouble().abs() / totalData) * 100;
      if (value < 1 && value != 0) {
        value = 1;
      }
      sumOfPercent += value;
    }
    scalingRatio = sumOfPercent != 0 ? sumOfPercent / 100 : 1;
  }

  // `gaps = barGapMax && bars.length - 1` (`:838`) — JS `&&` yields 0, not
  // false, when barGapMax is 0.
  final gaps = barGapMax == 0 ? 0.0 : (bars.length - 1).toDouble();
  final gapHeight = gaps == 0
      ? 0.0
      : math.max(
          kBarGapMin,
          math.min(barGapMax, (totalHeight * kBarGapMultiplier) / gaps),
        );
  return FluentStackedBarGapMetrics(
    gapHeight: gapHeight,
    heightValueScale: isStringYAxis
        ? 0
        : (totalHeight - gapHeight * gaps) / (totalData * scalingRatio),
    absStackTotal: totalData,
  );
}

/// One placed stack segment.
@immutable
class FluentStackedBarSegmentLayout {
  /// Creates a segment layout.
  const FluentStackedBarSegmentLayout({
    required this.rect,
    required this.colour,
    required this.opacity,
    required this.stackIndex,
    required this.segmentIndex,
    required this.isLast,
    this.roundedTopPath,
  });

  /// The segment's rectangle.
  final Rect rect;

  /// Resolved fill, already flattened for high contrast.
  final Color colour;

  /// 1 highlighted, 0.1 dimmed (`VerticalStackedBarChart.tsx:1101`).
  final double opacity;

  /// Index of the owning stack.
  final int stackIndex;

  /// Index inside the filtered segment list.
  final int segmentIndex;

  /// Whether this is the topmost drawn segment of its stack.
  final bool isLast;

  /// The arc-topped path used instead of a plain rect when the stack corner
  /// radius applies (`VerticalStackedBarChart.tsx:1092-1098`).
  final Path? roundedTopPath;
}

/// One stack's total label.
@immutable
class FluentStackedBarTotalLabel {
  /// Creates a label.
  const FluentStackedBarTotalLabel({
    required this.text,
    required this.anchor,
    required this.stackIndex,
  });

  /// The rendered string.
  final String text;

  /// The point the text is centred on, on its alphabetic baseline —
  /// `text-anchor="middle"` at `VerticalStackedBarChart.tsx:1205`.
  final Offset anchor;

  /// Index of the owning stack in `stacks`.
  final int stackIndex;
}

/// Renders stacked vertical bars into the shared cartesian shell.
///
/// Ports `VerticalStackedBarChart.tsx` (1426 lines) — the largest of the bar
/// charts and the only one supporting a category y axis.
class FluentVerticalStackedBarChartDelegate
    extends FluentCartesianSeriesDelegate {
  /// Creates a delegate.
  const FluentVerticalStackedBarChartDelegate({
    required this.stacks,
    required this.style,
    required this.colors,
    required this.measurer,
    required this.textStyles,
    required this.selectedLegends,
    required this.palette,
    this.activeLegend,
    this.activeXAxisDataPoint,
    this.barWidthProp,
    this.maxBarWidth = 24,
    this.barGapMax = 0,
    this.barCornerRadius = 0,
    this.barMinimumHeight = 0,
    this.hideLabels = false,
    this.roundCorners = false,
    this.mode,
    this.useUtc = false,
    this.lineOptions,
    this.yMinValue,
    this.yMaxValue,
    // Stored raw and resolved by [innerPadding] and [outerPadding]; the shell
    // reads the resolved overrides below. A named parameter cannot be a private
    // initialising formal, hence the explicit assignment — the same shape
    // VerticalBarChart uses.
    double? xAxisInnerPadding,
    double? xAxisOuterPadding,
    this.xAxisPadding,
    this.hideTickOverlap = true,
    this.xAxisCategoryOrder,
    this.yAxisCategoryOrder,
    this.yAxisTickFormat,
    // ignore: prefer_initializing_formals
  }) : _xAxisInnerPadding = xAxisInnerPadding,
       // ignore: prefer_initializing_formals
       _xAxisOuterPadding = xAxisOuterPadding;

  /// The stacks, in author order.
  final List<FluentVerticalStackedBarGroup> stacks;

  /// The resolved style.
  final FluentVerticalStackedBarChartStyle style;

  /// Resolved chart colours.
  final FluentChartColors colors;

  /// The chart subtree's single text measurer.
  final FluentChartTextMeasurer measurer;

  /// Resolved chart text styles.
  final FluentChartTextStyles textStyles;

  /// Legend titles selected by the user.
  final List<String> selectedLegends;

  /// The five-token segment palette (`VerticalStackedBarChart.tsx:316-322`).
  final List<Color> palette;

  /// Legend title currently hovered.
  final String? activeLegend;

  /// The x value whose line dot is enlarged.
  final Object? activeXAxisDataPoint;

  /// `number | 'default' | 'auto'`.
  final Object? barWidthProp;

  /// Bar width ceiling — 24 (`VerticalStackedBarChart.tsx:90`).
  final double maxBarWidth;

  /// Maximum gap between segments — 0 disables gaps
  /// (`VerticalStackedBarChart.tsx:815`).
  final double barGapMax;

  /// Corner radius applied to the topmost segment only
  /// (`VerticalStackedBarChart.tsx:986`).
  final double barCornerRadius;

  /// Floor on a segment's height (`VerticalStackedBarChart.tsx:986`).
  final double barMinimumHeight;

  /// Whether the stack total labels are suppressed.
  final bool hideLabels;

  /// Whether segments get a 3px corner radius.
  final bool roundCorners;

  /// `'plotly'` or null.
  final String? mode;

  /// Whether a date x axis uses UTC. VSBC branches here where
  /// VerticalBarChart always uses UTC (`VerticalStackedBarChart.tsx:873`).
  final bool useUtc;

  /// The chart-level line configuration, `props.lineOptions`.
  ///
  /// `_createLines` reads exactly one field off it — `lineBorderWidth`
  /// (`VerticalStackedBarChart.tsx:566-568`) — and takes every other stroke
  /// property off the legend's **first point** instead (`:617-619`), so a
  /// width, cap or dash set here is inert by design and not by omission.
  final FluentLineOptions? lineOptions;

  /// The caller's y floor, `props.yMinValue` (`VerticalStackedBarChart.tsx:404`).
  final double? yMinValue;

  /// The caller's y ceiling, `props.yMaxValue`
  /// (`VerticalStackedBarChart.tsx:403`).
  final double? yMaxValue;

  /// Band inner padding as the caller gave it, before [innerPadding] resolves
  /// it. Kept raw because an explicit 0 and an absent value make different
  /// charts — see [isScalePaddingDefined].
  final double? _xAxisInnerPadding;

  /// Band outer padding as the caller gave it. Raw for the same reason.
  final double? _xAxisOuterPadding;

  /// Legacy shorthand feeding both paddings.
  @override
  final double? xAxisPadding;

  /// `props.hideTickOverlap`, read only by the `'plotly'` arm of
  /// [solveDomainMargin] (`VerticalStackedBarChart.tsx:941`).
  final bool hideTickOverlap;

  /// Resolved inner padding: 2/3 on a category axis, 1/2 otherwise
  /// (`VerticalStackedBarChart.tsx:327-331`).
  double get innerPadding => getScalePadding(
    _xAxisInnerPadding,
    xAxisPadding,
    xAxisType == FluentChartAxisType.category ? 2 / 3 : 1 / 2,
  );

  /// Resolved outer padding, default 0 (`:332`).
  double get outerPadding =>
      getScalePadding(_xAxisOuterPadding, xAxisPadding, 0);

  /// The inner padding the **shell's** band scale is built with.
  ///
  /// Resolved, not raw, and only on a category axis: `:1395-1397` spreads
  /// `_xAxisInnerPadding` and `_xAxisOuterPadding` into `CartesianChart` behind
  /// an `_xAxisType === XAxisTypes.StringAxis` guard, so the band scale is
  /// padded with the same numbers [solveDomainMargin] sized the range against.
  /// Handing the raw null instead lets `createStringXAxis` fall back to its own
  /// `xAxisPadding = 0.1` (`utilities.ts:574`) and the stacks then no longer
  /// fill the range the domain margin centred them in.
  @override
  double? get xAxisInnerPadding => xAxisType == FluentChartAxisType.category
      ? innerPadding
      : _xAxisInnerPadding;

  /// The outer padding the shell's band scale is built with. See
  /// [xAxisInnerPadding].
  @override
  double? get xAxisOuterPadding => xAxisType == FluentChartAxisType.category
      ? outerPadding
      : _xAxisOuterPadding;

  /// Ordering applied to a category x axis, or null when the caller named none.
  ///
  /// Null and [FluentAxisCategoryOrder.defaultOrder] mean the same thing here:
  /// `xAxisCategoryOrder: 'default'` sits in the object upstream spreads
  /// `_props` over (`VerticalStackedBarChart.tsx:87-91`), and both reach
  /// `sortAxisCategories`' insertion-order arm regardless.
  final FluentAxisCategoryOrder? xAxisCategoryOrder;

  /// Ordering applied to a category y axis, or null when the caller named none.
  ///
  /// See [xAxisCategoryOrder]: null and
  /// [FluentAxisCategoryOrder.defaultOrder] are interchangeable on this chart.
  final FluentAxisCategoryOrder? yAxisCategoryOrder;

  /// Caller-supplied y tick formatter, reused for total labels.
  final String Function(double value)? yAxisTickFormat;

  @override
  FluentChartType get chartType => FluentChartType.verticalStackedBarChart;

  @override
  FluentChartAxisType get xAxisType => stacks.isEmpty
      // `_adjustProps` (`VerticalStackedBarChart.tsx:325-326`) — an absent or
      // invalid first x makes the axis categorical.
      ? FluentChartAxisType.category
      : isInvalidChartValue(stacks.first.xAxisPoint)
      ? FluentChartAxisType.category
      : getTypeOfAxis(stacks.first.xAxisPoint, isXAxis: true);

  @override
  FluentChartAxisType get yAxisType {
    // `_initYAxisParams` (`VerticalStackedBarChart.tsx:1247-1258`).
    if (stacks.isNotEmpty && stacks.first.chartData.isNotEmpty) {
      return getTypeOfAxis(stacks.first.chartData.first.data, isXAxis: false);
    }
    // `:1250-1256` — a `forEach` over the line legends, so the **last**
    // non-secondary legend wins rather than the first.
    var resolved = FluentChartAxisType.numeric;
    for (final points in _lineObject.values) {
      if (!points.first.point.useSecondaryYScale) {
        resolved = getTypeOfAxis(points.first.point.y, isXAxis: false);
      }
    }
    return resolved;
  }

  /// The line points grouped by legend, in first-appearance order.
  ///
  /// Ports `_getFormattedLineData` (`VerticalStackedBarChart.tsx:520-540`),
  /// whose `LineObject` is a plain object and therefore enumerates in insertion
  /// order — as a Dart [Map] does. Each entry carries the stack the point was
  /// declared on, which is upstream's `xItem`.
  Map<String, List<({Object xAxisPoint, FluentStackedBarLineDatum point})>>
  get _lineObject {
    final byLegend =
        <
          String,
          List<({Object xAxisPoint, FluentStackedBarLineDatum point})>
        >{};
    for (final stack in stacks) {
      for (final line
          in stack.lineData ?? const <FluentStackedBarLineDatum>[]) {
        (byLegend[line.legend] ??=
                <({Object xAxisPoint, FluentStackedBarLineDatum point})>[])
            .add((xAxisPoint: stack.xAxisPoint, point: line));
      }
    }
    return byLegend;
  }

  /// The colour segment [index] of a stack draws in, before high-contrast
  /// flattening. The legend reads this too, so a swatch and its segments can
  /// never disagree.
  ///
  /// ponytail: `_getLegendData` picks this with
  /// `defaultPalette[Math.floor(Math.random() * 4 + 1)]`
  /// (`VerticalStackedBarChart.tsx:167`), re-rolled on every render and never
  /// yielding entry 0, so a legend swatch changes colour on an unrelated state
  /// change and never matches its own bars. Spec section 5.2 exception 1
  /// exempts non-determinism from bug fidelity: no golden can pin a random
  /// colour. The deterministic rule below is the same one the marks use
  /// upstream, `_colors[index]` (`:1036`), extended with `% length` because
  /// that index is `undefined` from the sixth segment on and leaves the bar
  /// unpainted.
  Color segmentPaletteColour(FluentStackedBarDatum datum, int index) =>
      datum.color ?? palette[index % palette.length];

  /// The `{ x, y }` row per stack that the axis solves read.
  ///
  /// Ports `_createDataSetLayer` (`VerticalStackedBarChart.tsx:337-354`): the y
  /// is the stack total, or 0 on a category y axis.
  List<Object> get dataset => <Object>[
    for (final stack in stacks)
      if (stack.xAxisPoint is DateTime)
        FluentVerticalStackedBarDataPoint(
          x: stack.xAxisPoint,
          y: _stackTotal(stack),
        )
      else
        FluentChartXYPoint(x: stack.xAxisPoint, y: _stackTotal(stack)),
  ];

  double _stackTotal(FluentVerticalStackedBarGroup stack) {
    if (yAxisType == FluentChartAxisType.category) {
      // VerticalStackedBarChart.tsx:338-342.
      return 0;
    }
    var total = 0.0;
    for (final segment in stack.chartData) {
      total += (segment.data as num).toDouble();
    }
    return total;
  }

  /// `_getDomainMargins(containerWidth)` bound to this delegate's own props
  /// (`VerticalStackedBarChart.tsx:913-965`).
  ///
  /// Returns the bar width too, because upstream writes `_domainMargin` and
  /// `_barWidth` into the same closure and the two are mutually dependent: on a
  /// continuous axis the margin is half a bar wide, and the bar width is solved
  /// against the width the margin leaves. [segmentsFor] needs the second —
  /// `_createBar` re-derives it from the bandwidth on a category axis (`:990`)
  /// and otherwise reads the one solved here.
  ///
  /// [margins] are the shell's, which upstream reads off the closure the
  /// `getmargins` callback filled (`CartesianChart.tsx:180`).
  ({double barWidth, double domainMargin}) solveDomainMargin(
    double containerWidth,
    FluentChartMargins margins,
  ) {
    // VerticalStackedBarChart.tsx:914.
    var domainMargin = kMinDomainMargin;
    var barWidth = getBarWidth(barWidthProp, maxBarWidth);
    // `calcTotalWidth(containerWidth, _margins, MIN_DOMAIN_MARGIN)` (`:916`) —
    // one MIN_DOMAIN_MARGIN per side, taken out up front.
    final totalWidth = calcTotalWidth(
      containerWidth,
      margins,
      kMinDomainMargin,
    );

    if (xAxisType == FluentChartAxisType.category) {
      final labels = orderedXAxisLabels;
      if (isScalePaddingDefined(_xAxisOuterPadding, xAxisPadding)) {
        // `:919-922` — xAxisOuterPadding now does this job.
        domainMargin = 0;
      } else if (barWidthProp != 'auto') {
        // `:925`.
        barWidth = getBarWidth(barWidthProp, maxBarWidth);
        final requiredWidth = calcRequiredWidth(
          barWidth,
          labels.length,
          innerPadding,
        );
        // `:930-933`.
        if (totalWidth >= requiredWidth) {
          domainMargin = kMinDomainMargin + (totalWidth - requiredWidth) / 2;
        }
      } else if (mode == 'plotly' && labels.length > 1) {
        // `:934-949`. The 1 is upstream's own `_xAxisLabels.length > 1`.
        final bandwidth = calcBandwidth(
          totalWidth,
          labels.length,
          innerPadding,
        );
        // `const barWidth` at `:937` SHADOWS the closure's `_barWidth`, so this
        // arm sizes its margin from a width the bars never see. Reproduced: the
        // local below is deliberately not written back to [barWidth].
        final localBarWidth = getBarWidth(
          barWidthProp,
          maxBarWidth,
          adjustedValue: bandwidth,
        );
        var requiredWidth = calcRequiredWidth(
          localBarWidth,
          labels.length,
          innerPadding,
        );
        final margin1 = (totalWidth - requiredWidth) / 2;
        // `Number.POSITIVE_INFINITY` at `:942`, the seed a `Math.min` fold
        // needs.
        var margin2 = double.infinity;
        if (!hideTickOverlap) {
          // +20 is the label breathing room at `:945`.
          final step = measurer.longestWidth(labels, textStyles.axisTick) + 20;
          requiredWidth = (labels.length - innerPadding) * step;
          margin2 = (totalWidth - requiredWidth) / 2;
        }
        // `:949`. The 0 is upstream's own floor.
        domainMargin =
            kMinDomainMargin + math.max(0.0, math.min(margin1, margin2));
      }
    } else {
      // `:952-958` — the continuous arm, which is the only place
      // `calculateAppropriateBarWidth` runs for this chart.
      barWidth = getBarWidth(
        barWidthProp,
        maxBarWidth,
        adjustedValue: calculateAppropriateBarWidth(
          <Object>[for (final stack in stacks) stack.xAxisPoint],
          totalWidth,
          innerPadding,
        ),
      );
      // `:958` — half a bar at each end, so the outermost bars sit inside the
      // plot rather than straddling its edges. VerticalBarChart takes the inset
      // twice here; this chart takes it once.
      domainMargin = kMinDomainMargin + barWidth / 2;
    }
    return (barWidth: barWidth, domainMargin: domainMargin);
  }

  @override
  FluentChartMargins? domainMargins(
    double containerWidth,
    FluentChartMargins margins,
  ) {
    final margin = solveDomainMargin(containerWidth, margins).domainMargin;
    // `{..._margins, left: …, right: …}`
    // (`VerticalStackedBarChart.tsx:960-964`) — top and bottom pass through.
    return margins.copyWith(
      left: (margins.left ?? 0) + margin,
      right: (margins.right ?? 0) + margin,
    );
  }

  /// Builds the six-verb rounded-top path.
  ///
  /// `M x (y+r) a r r 0 0 1 r -r h (w-2r) a r r 0 0 1 r r v (h-r) h -w z`
  /// (`VerticalStackedBarChart.tsx:1092-1098`).
  static Path roundedTopPath({
    required double x,
    required double y,
    required double width,
    required double height,
    required double radius,
  }) => Path()
    ..moveTo(x, y + radius)
    ..arcToPoint(Offset(x + radius, y), radius: Radius.circular(radius))
    // The 2 is the two corners the straight top run has to clear.
    ..relativeLineTo(width - 2 * radius, 0)
    ..arcToPoint(Offset(x + width, y + radius), radius: Radius.circular(radius))
    ..relativeLineTo(0, height - radius)
    ..relativeLineTo(-width, 0)
    ..close();

  /// Resolves every stack segment.
  ///
  /// Ports `_createBar` (`VerticalStackedBarChart.tsx:980-1223`) for the
  /// numeric y axis. The category y branch is [categorySegmentsFor], and
  /// `paintSeries` picks between the two the way `_getGraphData` picks the
  /// scale it hands `_createBar` (`:392-396`).
  List<FluentStackedBarSegmentLayout> segmentsFor(
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
  ) {
    if (stacks.isEmpty) {
      return const <FluentStackedBarSegmentLayout>[];
    }
    final isBandX = xAxisType == FluentChartAxisType.category;
    // `VerticalStackedBarChart.tsx:989-991` — only the band axis re-solves the
    // width against the bandwidth; the continuous arms keep the `_barWidth`
    // `_getDomainMargins` solved at `:952-957`, which is the only place
    // `calculateAppropriateBarWidth` runs. [layout] carries the shell's own
    // margins, so the solve here sees exactly what the shell handed
    // [domainMargins].
    final barWidth = isBandX
        ? getBarWidth(
            barWidthProp,
            maxBarWidth,
            adjustedValue: context.xScale.bandwidth,
          )
        : solveDomainMargin(layout.size.width, layout.margins).barWidth;
    // `stringXAxis ? (bandwidth - _barWidth) / 2 : -_barWidth / 2`
    // (`:1002-1003`); both 2s centre the bar on its x.
    final translate = isBandX
        ? (context.xScale.bandwidth - barWidth) / 2
        : -barWidth / 2;
    final bottom = layout.margins.bottom ?? 0;
    final top = layout.margins.top ?? 0;
    // `_getAxisData` (`:400-406`) then `_getScales` (`:849-853`).
    //
    // `_yMin` and `_yMax` are the ends of the **resolved** y-axis domain, not
    // the data extent: `yAxisDomainValues` is assigned `yAxisScale.domain()`
    // (`utilities.ts:889`), so upstream reads back exactly the domain
    // `prepareDatapoints` niced the ticks onto. This port takes it off the
    // scale the shell already built rather than routing it through a callback.
    // Standing the data extent in instead scales every stack by
    // dataMax/tickMax — for the Default story, 140/150, which is a 7% error on
    // every segment height in the chart.
    final domain = context.yScalePrimary.domain;
    final yMin = math.min(
      _domainEnd(domain.firstOrNull),
      yMinValue ?? kStackedBarYOrigin,
    );
    final yMax = math.max(
      _domainEnd(domain.lastOrNull),
      yMaxValue ?? kStackedBarYOrigin,
    );
    final yBarScale = scaleLinear()
      ..domainOf(<double>[
        math.min(kStackedBarYOrigin, yMin),
        math.max(kStackedBarYOrigin, yMax),
      ])
      ..rangeOf(<double>[0, layout.size.height - bottom - top]);
    final dim = style.barOpacity!.resolve(<WidgetState>{WidgetState.disabled})!;
    // `_noLegendHighlighted` (`:421-423`).
    final noneHighlighted =
        selectedLegends.isEmpty &&
        (activeLegend == null || activeLegend!.isEmpty);

    final out = <FluentStackedBarSegmentLayout>[];
    for (var si = 0; si < stacks.length; si++) {
      final stack = stacks[si];
      // `barsToDisplay` (`:1006-1014`).
      final visible = stack.chartData
          .where((segment) => segment.data != 0 && segment.data != '')
          .toList(growable: false);
      if (visible.isEmpty) {
        // `:1016-1018` returns undefined, and `:1222` filters the stack out.
        continue;
      }
      final metrics = computeFluentStackedBarGapMetrics(
        bars: visible,
        yBarScale: yBarScale,
        isStringYAxis: false,
        barGapMax: barGapMax,
      );
      if (metrics.heightValueScale < 0) {
        // VerticalStackedBarChart.tsx:1021-1023.
        continue;
      }
      // `:1026-1029` — the pixel the stack grows out of, in both directions.
      final baseline =
          layout.size.height - bottom - (yBarScale(kStackedBarYOrigin) ?? 0);
      var positiveStart = baseline;
      var negativeStart = baseline;
      final x = context.xScale(stack.xAxisPoint)! + translate;
      for (var k = 0; k < visible.length; k++) {
        final value = (visible[k].data as num).toDouble();
        final gapOffset = k > 0 ? metrics.gapHeight : 0.0;
        // VerticalStackedBarChart.tsx:1068.
        var height = (metrics.heightValueScale * value).abs();
        // `max(heightValueScale * absStackTotal / 100, barMinimumHeight)`
        // (`:1070`); the 100 turns the stack total into one percent of itself.
        final minHeight = math.max(
          metrics.heightValueScale * metrics.absStackTotal / 100.0,
          barMinimumHeight,
        );
        if (height < minHeight) {
          height = minHeight;
        }
        final double topEdge;
        if (value >= kStackedBarYOrigin) {
          // VerticalStackedBarChart.tsx:1074-1076.
          positiveStart -= height + gapOffset;
          topEdge = positiveStart;
        } else {
          // VerticalStackedBarChart.tsx:1078-1079.
          topEdge = negativeStart + gapOffset;
          negativeStart = topEdge + height;
        }
        // `_isLegendHighlighted(...) || _noLegendHighlighted()` (`:1038`).
        final highlighted =
            noneHighlighted ||
            isLegendHighlightedMulti(
              visible[k].legend,
              selectedLegends: selectedLegends,
              activeLegend: activeLegend,
            );
        final isLast = k == visible.length - 1;
        out.add(
          FluentStackedBarSegmentLayout(
            rect: Rect.fromLTWH(x, topEdge, barWidth, height),
            colour: colors.flattenMark(segmentPaletteColour(visible[k], k)),
            opacity: highlighted ? 1 : dim,
            stackIndex: si,
            segmentIndex: k,
            isLast: isLast,
            // `barCornerRadius && barHeight > barCornerRadius &&
            // index === barsToDisplay.length - 1` (`:1086`).
            roundedTopPath:
                isLast && barCornerRadius > 0 && height > barCornerRadius
                ? roundedTopPath(
                    x: x,
                    y: topEdge,
                    width: barWidth,
                    height: height,
                    radius: barCornerRadius,
                  )
                : null,
          ),
        );
      }
    }
    return out;
  }

  @override
  FluentChartDomainRange resolveXDomainRange({
    required FluentChartMargins margins,
    required double containerWidth,
    required bool isRtl,
    required double? barWidth,
    required List<Object>? tickValues,
  }) => switch (xAxisType) {
    // VerticalStackedBarChart.tsx:501-517.
    FluentChartAxisType.numeric => domainRangeOfVSBCNumeric(
      dataset,
      margins,
      containerWidth,
      isRtl: isRtl,
    ),
    FluentChartAxisType.date =>
      domainRangeOfDateForAreaLineScatterVerticalBarCharts(
        dataset,
        margins,
        containerWidth,
        isRtl: isRtl,
        chartType: FluentChartType.verticalStackedBarChart,
        tickValues: tickValues?.cast<DateTime>() ?? const <DateTime>[],
      ),
    FluentChartAxisType.category => domainRangeOfXStringAxis(
      margins,
      containerWidth,
      isRtl: isRtl,
    ),
  };

  @override
  FluentChartMinMax resolveYMinMax({bool useSecondaryYScale = false}) {
    if (useSecondaryYScale) {
      // VerticalStackedBarChart.tsx:1234-1244 — only lines reach the secondary
      // scale in this chart.
      final values = <double>[
        for (final stack in stacks)
          for (final line
              in stack.lineData ?? const <FluentStackedBarLineDatum>[])
            if (line.useSecondaryYScale && line.y is num)
              (line.y as num).toDouble(),
      ];
      return FluentChartMinMax(
        startValue: d3.min<double>(values) ?? double.nan,
        endValue: d3.max<double>(values) ?? double.nan,
      );
    }
    // `findVSBCNumericMinMaxOfY` reads `y` alone (`utilities.ts:1620-1625`),
    // and [FluentChartXYPoint] rejects a [DateTime] x (`types/DataPoint.ts:64`)
    // which [dataset] may carry, so the stack's own index stands in for it.
    return findVSBCNumericMinMaxOfY(<Object>[
      for (final (index, stack) in stacks.indexed)
        FluentChartXYPoint(x: index, y: _stackTotal(stack)),
    ]);
  }

  @override
  FluentAxisSpec createYAxis(
    FluentYAxisParams params,
    FluentAxisData axisData, {
    required bool isRtl,
    required bool isIntegralDataset,
    bool useSecondaryYScale = false,
  }) => builders.createNumericYAxis(
    params,
    axisData,
    isRtl: isRtl,
    isIntegralDataset: isIntegralDataset,
    chartType: FluentChartType.verticalStackedBarChart,
    useSecondaryYScale: useSecondaryYScale,
  );

  @override
  FluentAxisSpec createStringYAxis(
    FluentYAxisParams params,
    List<String> dataPoints,
    FluentAxisData axisData, {
    required bool isRtl,
  }) =>
      // The VSBC arm of `createStringYAxis` forces `paddingInner(1)` and
      // `paddingOuter(0)`, collapsing the bandwidth to zero
      // (`utilities.ts:973-975`).
      builders.createStringYAxis(
        params,
        dataPoints,
        axisData,
        isRtl: isRtl,
        chartType: FluentChartType.verticalStackedBarChart,
      );

  /// The category x labels, in the order [xAxisCategoryOrder] asks for.
  ///
  /// Ports `_getOrderedXAxisLabels` (`VerticalStackedBarChart.tsx:1293-1299`)
  /// over `_mapCategoryToValues()` (`:1309-1336`): the category is the stack's
  /// x and the values pushed under it are its segment values and its line ys,
  /// so an aggregate order such as `'mean ascending'` sorts the stacks by
  /// magnitude. A non-numeric value contributes nothing, which is upstream's
  /// `typeof value === 'number'` guard at `:1325` and `:1332`.
  ///
  /// The entry is only created from inside the segment and line loops, so a
  /// stack carrying neither never reaches the domain — upstream's structure
  /// at `:1312-1334`, not an accident.
  List<String> get orderedXAxisLabels {
    if (xAxisType != FluentChartAxisType.category) {
      // VerticalStackedBarChart.tsx:1294-1296.
      return const <String>[];
    }
    final categoryToValues = <String, List<double>>{};
    for (final stack in stacks) {
      final category = '${stack.xAxisPoint}';
      for (final segment in stack.chartData) {
        final values = categoryToValues.putIfAbsent(category, () => <double>[]);
        if (segment.data is num) {
          values.add((segment.data as num).toDouble());
        }
      }
      for (final line
          in stack.lineData ?? const <FluentStackedBarLineDatum>[]) {
        final values = categoryToValues.putIfAbsent(category, () => <double>[]);
        if (line.y is num) {
          values.add((line.y as num).toDouble());
        }
      }
    }
    return sortAxisCategories(categoryToValues, xAxisCategoryOrder);
  }

  @override
  List<String>? get datasetForXAxisDomain =>
      // `datasetForXAxisDomain={_xAxisLabels}` (`.tsx:1384`), which is
      // `_getOrderedXAxisLabels()` (`:353`) and empty off a non-category axis.
      xAxisType == FluentChartAxisType.category ? orderedXAxisLabels : null;

  /// The category y labels, in the order [yAxisCategoryOrder] asks for.
  ///
  /// Ports `_getOrderedYAxisLabels` (`VerticalStackedBarChart.tsx:1301-1307`)
  /// over `_mapCategoryToValues(true)` (`:1309-1327`): the category is the
  /// segment's `data` and the value pushed under it is the **stack's x**, so an
  /// aggregate order such as `'mean ascending'` sorts the categories by where
  /// they appear along the x axis. A non-numeric x contributes no value, which
  /// is upstream's `typeof value === 'number'` guard at `:1325`.
  List<String> get orderedYAxisLabels {
    if (yAxisType != FluentChartAxisType.category) {
      // VerticalStackedBarChart.tsx:1302-1304.
      return const <String>[];
    }
    final categoryToValues = <String, List<double>>{};
    for (final stack in stacks) {
      for (final segment in stack.chartData) {
        final values = categoryToValues.putIfAbsent(
          '${segment.data}',
          () => <double>[],
        );
        if (stack.xAxisPoint is num) {
          values.add((stack.xAxisPoint as num).toDouble());
        }
      }
    }
    return sortAxisCategories(categoryToValues, yAxisCategoryOrder);
  }

  @override
  List<String>? get stringDatasetForYAxisDomain =>
      yAxisType == FluentChartAxisType.category
      // The leading '' is deliberate: it reserves the baseline band, which
      // every stack is measured down to (`VerticalStackedBarChart.tsx:1401`).
      ? <String>['', ...orderedYAxisLabels]
      : null;

  @override
  FluentChartMargins? yDomainMargins(double containerHeight) {
    // `_getYDomainMargins` (`VerticalStackedBarChart.tsx:1261-1291`) returns
    // `{..._margins, top: _margins.top + 0}` off the string branch, which is
    // the shell's own margins; null is how the delegate spells that.
    if (yAxisType != FluentChartAxisType.category) {
      return null;
    }
    // Defaults from CartesianChart.tsx:41-42, the margins the shell has
    // already written into `_margins` by the time `:1268` reads them.
    const marginTop = 20.0;
    const marginBottom = 35.0;
    final totalHeight = containerHeight - marginBottom - marginTop;
    final labels = orderedYAxisLabels;
    var maxBarHeightInLabels = 0.0;
    for (final stack in stacks) {
      var barHeightInLabels = 0.0;
      for (final segment in stack.chartData) {
        // `:1278` — one label unit per band the segment sits above, so a
        // segment on the lowest category counts once.
        barHeightInLabels += labels.indexOf('${segment.data}') + 1;
      }
      maxBarHeightInLabels = math.max(maxBarHeightInLabels, barHeightInLabels);
    }
    // `:1283` — the guard is there because the division would otherwise be by
    // zero for a chart whose stacks are all empty.
    final yAxisLabelHeight = maxBarHeightInLabels == 0
        ? 0.0
        : totalHeight / maxBarHeightInLabels;
    return FluentChartMargins(
      // `:1284` — negative when the stacks are shorter than the label column,
      // which pulls the top margin back in.
      top:
          marginTop + yAxisLabelHeight * (maxBarHeightInLabels - labels.length),
    );
  }

  /// Resolves every stack segment on a category y axis.
  ///
  /// Ports the string branch of `_createBar`
  /// (`VerticalStackedBarChart.tsx:1056-1065`), where a segment's height is
  /// measured from the plot floor to the **centre** of its label's band. The
  /// band has zero width because `createStringYAxis` forces `paddingInner(1)`
  /// for this chart (`utilities.ts:973-975`), so the centring term is zero in
  /// practice; it is kept because upstream writes it and a padding change would
  /// need it.
  ///
  /// Two things the numeric [segmentsFor] does are absent here, both because
  /// upstream skips them on this branch: there is no `Y_ORIGIN` term in the
  /// baseline (`:1026-1029`), and there is no negative direction — every
  /// segment grows upwards off the floor.
  List<FluentStackedBarSegmentLayout> categorySegmentsFor(
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
  ) {
    if (stacks.isEmpty) {
      return const <FluentStackedBarSegmentLayout>[];
    }
    final isBandX = xAxisType == FluentChartAxisType.category;
    final barWidth = isBandX
        ? getBarWidth(
            barWidthProp,
            maxBarWidth,
            adjustedValue: context.xScale.bandwidth,
          )
        : solveDomainMargin(layout.size.width, layout.margins).barWidth;
    // VerticalStackedBarChart.tsx:1002-1003.
    final translate = isBandX
        ? (context.xScale.bandwidth - barWidth) / 2
        : -barWidth / 2;
    final floor = layout.size.height - (layout.margins.bottom ?? 0);
    final dim = style.barOpacity!.resolve(<WidgetState>{WidgetState.disabled})!;
    // `_noLegendHighlighted` (`:421-423`).
    final noneHighlighted =
        selectedLegends.isEmpty &&
        (activeLegend == null || activeLegend!.isEmpty);

    final out = <FluentStackedBarSegmentLayout>[];
    for (var si = 0; si < stacks.length; si++) {
      final stack = stacks[si];
      // `barsToDisplay` (`:1006-1014`) — the third clause is the string-axis
      // one, which drops a segment whose label is not in the band domain.
      final visible = stack.chartData
          .where(
            (segment) =>
                segment.data != 0 &&
                segment.data != '' &&
                context.yScalePrimary(segment.data) != null,
          )
          .toList(growable: false);
      if (visible.isEmpty) {
        // `:1016-1018` returns undefined, and `:1222` filters the stack out.
        continue;
      }
      final metrics = computeFluentStackedBarGapMetrics(
        bars: visible,
        yBarScale: context.yScalePrimary,
        isStringYAxis: true,
        barGapMax: barGapMax,
      );
      var positiveStart = floor;
      final x = context.xScale(stack.xAxisPoint)! + translate;
      for (var k = 0; k < visible.length; k++) {
        final gapOffset = k > 0 ? metrics.gapHeight : 0.0;
        // `Math.max(…, barMinimumHeight, 1)` at `:1057-1064` takes three
        // arguments; the trailing 1 keeps a segment on the baseline band
        // visible rather than collapsing it to nothing.
        final height = math.max(
          math.max(
            floor -
                (context.yScalePrimary(visible[k].data)! +
                    context.yScalePrimary.bandwidth / 2) -
                gapOffset,
            barMinimumHeight,
          ),
          1.0,
        );
        positiveStart -= height + gapOffset;
        // `_isLegendHighlighted(...) || _noLegendHighlighted()` (`:1038`).
        final highlighted =
            noneHighlighted ||
            isLegendHighlightedMulti(
              visible[k].legend,
              selectedLegends: selectedLegends,
              activeLegend: activeLegend,
            );
        out.add(
          FluentStackedBarSegmentLayout(
            rect: Rect.fromLTWH(x, positiveStart, barWidth, height),
            colour: colors.flattenMark(segmentPaletteColour(visible[k], k)),
            opacity: highlighted ? 1 : dim,
            stackIndex: si,
            segmentIndex: k,
            isLast: k == visible.length - 1,
          ),
        );
      }
    }
    return out;
  }

  /// The total label sitting over each stack in [segments].
  ///
  /// Ports the label arm of `_createBar`
  /// (`VerticalStackedBarChart.tsx:1155-1215`). Three things it is easy to get
  /// wrong, all upstream's:
  ///
  ///  * the label is the **total** of the stack, not of any one segment, and
  ///    with a legend selected it is the total of the *selected* segments only
  ///    (`:1170-1178`);
  ///  * a caller's own `barLabel` replaces that total, but only when exactly one
  ///    segment in the stack carries one (`:1165-1168`) — two of them and the
  ///    numeric total wins;
  ///  * the side is chosen by the **selected** total rather than by the drawn
  ///    one (`:1204`), so a stack whose selection sums negative labels below
  ///    itself even when its full total is positive.
  ///
  /// [segments] is the output of [segmentsFor]; its `isLast` member is
  /// upstream's `index === barsToDisplay.length - 1`, which is what carries
  /// `yPoint` and `heightOfLastBar` out of the segment loop.
  List<FluentStackedBarTotalLabel> totalLabelsFor(
    List<FluentStackedBarSegmentLayout> segments,
  ) {
    // `!props.hideLabels && _yAxisType !== YAxisType.StringAxis` (`:1160`).
    if (hideLabels || yAxisType == FluentChartAxisType.category) {
      return const <FluentStackedBarTotalLabel>[];
    }
    // `_barWidth >= 16` (`:1200`).
    final minWidth = style.minBarLabelWidth!.resolve(const <WidgetState>{})!;
    final gapAbove = style.barLabelGapAbove!.resolve(const <WidgetState>{})!;
    final gapBelow = style.barLabelGapBelow!.resolve(const <WidgetState>{})!;
    // `_noLegendHighlighted` (`:421-423`).
    final noneHighlighted =
        selectedLegends.isEmpty &&
        (activeLegend == null || activeLegend!.isEmpty);
    bool highlighted(FluentStackedBarDatum p) => isLegendHighlightedMulti(
      p.legend,
      selectedLegends: selectedLegends,
      activeLegend: activeLegend,
    );

    final out = <FluentStackedBarTotalLabel>[];
    for (final last in segments) {
      if (!last.isLast || last.rect.width < minWidth) {
        continue;
      }
      // `barsToDisplay` (`:1006-1014`), numeric-y arm.
      final visible = stacks[last.stackIndex].chartData
          .where((segment) => segment.data != 0 && segment.data != '')
          .toList(growable: false);
      // `:1162-1168` — one labelled segment, or none at all.
      final labelled = visible
          .where(
            (p) => p.barLabel != null && (noneHighlighted || highlighted(p)),
          )
          .toList(growable: false);
      final custom = labelled.length == 1 ? labelled.single.barLabel : null;

      var show = false;
      var selectedTotal = 0.0;
      String? text;
      if (noneHighlighted) {
        // `:1169-1173`.
        show = true;
        for (final p in visible) {
          selectedTotal += (p.data as num).toDouble();
        }
        text = custom ?? _formatTotal(selectedTotal);
      } else {
        // `:1174-1181`.
        for (final p in visible) {
          if (highlighted(p)) {
            show = true;
            selectedTotal += (p.data as num).toDouble();
          }
        }
        text = custom ?? _formatTotal(selectedTotal);
      }
      if (!show) {
        continue;
      }
      out.add(
        FluentStackedBarTotalLabel(
          text: text,
          // `x={xPoint + _barWidth / 2}` under the same
          // `translate(xScaleBandwidthTranslate, 0)` the rects carry (`:1202`,
          // `:1207`), which is the drawn rect's own centre.
          anchor: Offset(
            last.rect.center.dx,
            // `:1204`.
            selectedTotal >= kStackedBarYOrigin
                ? last.rect.top - gapAbove
                : last.rect.bottom + gapBelow,
          ),
          stackIndex: last.stackIndex,
        ),
      );
    }
    return out;
  }

  /// One end of the primary y scale's domain as a number.
  ///
  /// `Y_ORIGIN` for anything else, which is upstream's `_yMin`/`_yMax` seed
  /// when `_getAxisData` never fires (`VerticalStackedBarChart.tsx:113-114`) —
  /// a category y axis, whose domain is a list of labels, is the only way to
  /// get here with a non-numeric end.
  static double _domainEnd(Object? value) =>
      value is num ? value.toDouble() : kStackedBarYOrigin;

  /// `props.yAxisTickFormat(barLabel)` or `formatScientificLimitWidth`
  /// (`VerticalStackedBarChart.tsx:1210-1214`).
  String _formatTotal(double value) =>
      yAxisTickFormat?.call(value) ?? formatScientificLimitWidth(value);

  /// Ports the radius arm of `_getCircleOpacityAndRadius`
  /// (`VerticalStackedBarChart.tsx:681-700`).
  ///
  /// A dimmed dot is drawn at opacity 0 rather than hidden, so that it stays
  /// focusable (`:650-652`); this returns 0 for that case, and the painter
  /// skips it outright because this delegate emits no hit regions for a dot to
  /// keep.
  ///
  /// [noneHighlighted] is upstream's `_noLegendHighlighted()`, whose arm at
  /// `:694-699` keeps every dot at radius 8 and hides the inactive ones with
  /// opacity alone. Without it a chart with no legend selection would draw
  /// 0.3px dots where the capture shows 8px ones.
  double lineDotRadiusFor({
    required bool highlighted,
    required bool isActiveX,
    bool noneHighlighted = false,
  }) {
    if (noneHighlighted) {
      return style.lineDotRadius!.resolve(<WidgetState>{WidgetState.hovered})!;
    }
    if (!highlighted) {
      return 0;
    }
    return isActiveX
        ? style.lineDotRadius!.resolve(<WidgetState>{WidgetState.hovered})!
        : style.lineDotRadius!.resolve(const <WidgetState>{})!;
  }

  /// The fill of an overlaid line's dot, and the stroke of the halo run under
  /// the line itself — upstream spells `tokens.colorNeutralBackground1` for
  /// both (`VerticalStackedBarChart.tsx:648` and `:604`).
  ///
  /// Routed through [FluentChartColors.flattenMarkStroke] rather than
  /// [FluentChartColors.flattenMark], so forced colours send it to `Canvas`
  /// while the line and the dot's ring go to `CanvasText` — flattening both the
  /// same way would erase the dot and sink the line into the stacks it is drawn
  /// over (spec section 5.3).
  Color get lineDotFillColour => colors.flattenMarkStroke(
    style.lineDotFillColor!.resolve(const <WidgetState>{})!,
  );

  /// The pixel a line point sits at on the scale [useSecondary] selects.
  ///
  /// `xScaleBandwidthTranslate` (`VerticalStackedBarChart.tsx:569`) and
  /// `yScaleBandwidthTranslate` (`:588-591` for a segment end, `:629-632` for a
  /// dot) are `transform` attributes upstream and are folded into the
  /// coordinate here.
  Offset _lineVertex(
    FluentCartesianChildContext context,
    ({Object xAxisPoint, FluentStackedBarLineDatum point}) p, {
    required bool useSecondary,
    required double xShift,
  }) {
    final scale = useSecondary
        ? context.yScaleSecondary!
        : context.yScalePrimary;
    // `:589` — the half band is only ever added on the PRIMARY category scale.
    final yShift = !useSecondary && yAxisType == FluentChartAxisType.category
        ? context.yScalePrimary.bandwidth / 2
        : 0.0;
    return Offset(
      context.xScale(p.xAxisPoint)! + xShift,
      // `:582` plots `.y`. The `data` that `_onStackHover` assigns at `:276` —
      // this port's [FluentStackedBarLineDatum.resolvedData] — is the callout's
      // value and never the plotted one.
      scale(p.point.y)! + yShift,
    );
  }

  /// Paints the line overlay (`_createLines`,
  /// `VerticalStackedBarChart.tsx:556-679`).
  ///
  /// One legend at a time, and inside a legend upstream's own order — every
  /// halo, then every line, then every dot (`:672-674`) — so a legend's dots sit
  /// above its own line and below the next legend's halo.
  void _paintLines(Canvas canvas, FluentCartesianChildContext context) {
    final byLegend = _lineObject;
    if (byLegend.isEmpty) {
      return;
    }
    final full = style.barOpacity!.resolve(const <WidgetState>{})!;
    final dim = style.barOpacity!.resolve(<WidgetState>{WidgetState.disabled})!;
    final strokeWidth = style.lineStrokeWidth!.resolve(const <WidgetState>{})!;
    final dotStrokeWidth = style.lineDotStrokeWidth!.resolve(
      const <WidgetState>{},
    )!;
    // `:566-568` — the halo width is a CHART prop, while every other stroke
    // property below comes off the legend's first point.
    final border = lineOptions?.lineBorderWidth ?? 0;
    // `:569`.
    final xShift = xAxisType == FluentChartAxisType.category
        ? context.xScale.bandwidth / 2
        : 0.0;
    // `_noLegendHighlighted` (`:421-423`).
    final noneHighlighted =
        selectedLegends.isEmpty &&
        (activeLegend == null || activeLegend!.isEmpty);

    for (final entry in byLegend.entries) {
      final points = entry.value;
      // `:574`.
      final highlighted =
          noneHighlighted ||
          isLegendHighlightedMulti(
            entry.key,
            selectedLegends: selectedLegends,
            activeLegend: activeLegend,
          );
      // `opacity={shouldHighlight ? 1 : 0.1}` (`:600` and `:616`).
      final opacity = highlighted ? full : dim;
      final segments = <(Offset, Offset)>[];
      for (var i = 1; i < points.length; i++) {
        // `:577-578` — the secondary scale is chosen per SEGMENT and from both
        // of its endpoints, so a line crossing between the two scales draws its
        // crossing segment entirely on the primary one.
        final useSecondary =
            points[i - 1].point.useSecondaryYScale &&
            points[i].point.useSecondaryYScale &&
            context.yScaleSecondary != null;
        segments.add((
          _lineVertex(
            context,
            points[i - 1],
            useSecondary: useSecondary,
            xShift: xShift,
          ),
          _lineVertex(
            context,
            points[i],
            useSecondary: useSecondary,
            xShift: xShift,
          ),
        ));
      }
      // `:592` gates the halo on a positive border width.
      if (border > 0) {
        final halo = Paint()
          ..style = PaintingStyle.stroke
          ..color = lineDotFillColour.withValues(alpha: opacity)
          // `3 + lineBorderWidth * 2` (`:601`): the 3 is a literal upstream and
          // not the point's own `strokeWidth`, and the 2 is the two sides of
          // the line the halo has to clear.
          ..strokeWidth = strokeWidth + border * 2
          // `:603`.
          ..strokeCap = StrokeCap.round;
        for (final (a, b) in segments) {
          canvas.drawLine(a, b, halo);
        }
      }
      // `:617-619` read the FIRST point's options for every segment of the
      // legend, not each segment's own.
      final options = points.first.point.lineOptions;
      for (var i = 0; i < segments.length; i++) {
        canvas.drawLine(
          segments[i].$1,
          segments[i].$2,
          Paint()
            ..style = PaintingStyle.stroke
            // `// parity:` `stroke={lineObject[item][i].color}` (`:620`) reads
            // the segment's **destination** point, so a colour change takes
            // effect one segment early.
            ..color = colors
                .flattenMark(points[i + 1].point.color)
                .withValues(alpha: opacity)
            ..strokeWidth = options?.strokeWidth ?? strokeWidth
            ..strokeCap = options?.strokeLinecap ?? StrokeCap.round,
        );
      }
      // ponytail: `strokeDasharray` (`:619`) is dropped, exactly as
      // GroupedVerticalBarChart drops it
      // (`grouped_vertical_bar_chart.dart:762`). Dashing a polyline needs the
      // path-metrics walk LineChart carries at `line_chart.dart:1887`; lift
      // that helper here if a caller asks for a dashed overlay.
      for (final p in points) {
        // `activeXAxisDataPoint === xAxisPoint` (`:686` and `:695`).
        final isActiveX = activeXAxisDataPoint == p.xAxisPoint;
        // The opacity arm of `_getCircleOpacityAndRadius` (`:681-699`): with
        // nothing highlighted only the dot on the active x is opaque, and
        // otherwise every dot of a highlighted legend is.
        //
        // ponytail: upstream paints the transparent ones anyway, so that they
        // keep a tab stop (`:650-652`). This delegate emits no hit regions at
        // all — `buildHitRegions` returns a const empty list — so there is no
        // focus to preserve and the paint is skipped. Draw them again, at
        // opacity 0, when the regions land.
        if (!(noneHighlighted ? isActiveX : highlighted)) {
          continue;
        }
        final centre = _lineVertex(
          context,
          p,
          // `:639` — a dot picks its scale from its OWN point, where a segment
          // needs both of its endpoints to agree.
          useSecondary:
              p.point.useSecondaryYScale && context.yScaleSecondary != null,
          xShift: xShift,
        );
        final radius = lineDotRadiusFor(
          highlighted: highlighted,
          isActiveX: isActiveX,
          noneHighlighted: noneHighlighted,
        );
        canvas
          // `fill={tokens.colorNeutralBackground1}` (`:648`).
          ..drawCircle(centre, radius, Paint()..color = lineDotFillColour)
          ..drawCircle(
            centre,
            radius,
            Paint()
              ..style = PaintingStyle.stroke
              // `stroke={circlePoint.color}` (`:647`) is the point's own ink,
              // which is why it flattens the way the line does and not the way
              // the fill under it does.
              ..color = colors.flattenMark(p.point.color)
              // `strokeWidth={3}` (`:649`).
              ..strokeWidth = dotStrokeWidth,
          );
      }
    }
  }

  @override
  void paintSeries(
    Canvas canvas,
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
    FluentChartColors colors,
  ) {
    // `_getGraphData` (`:384-397`) hands `_createBar` the shell's own y scale
    // on a category y axis and its private `yBarScale` otherwise; this port
    // splits that branch into two solves rather than one.
    final segments = yAxisType == FluentChartAxisType.category
        ? categorySegmentsFor(context, layout)
        : segmentsFor(context, layout);
    for (final segment in segments) {
      final paint = Paint()
        ..color = segment.colour.withValues(
          alpha: segment.colour.a * segment.opacity,
        );
      final path = segment.roundedTopPath;
      if (path != null) {
        canvas.drawPath(path, paint);
        continue;
      }
      // `rx = props.roundCorners ? 3 : 0` (`VerticalStackedBarChart.tsx:1102`).
      final radius = roundCorners
          ? style.barCornerRadius!.resolve(const <WidgetState>{})!
          : 0.0;
      if (radius > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(segment.rect, Radius.circular(radius)),
          paint,
        );
      } else {
        canvas.drawRect(segment.rect, paint);
      }
    }
    // The `<text>` is a sibling of the stack's own `<g>` and comes after it
    // (`:1183-1216`), so a label sits over its stack and under the overlay.
    final labelStyle = style.barLabelStyle!.resolve(const <WidgetState>{})!;
    for (final label in totalLabelsFor(segments)) {
      final painter = measurer.layoutPainter(label.text, labelStyle);
      final metrics = measurer.measure(label.text, labelStyle);
      painter.paint(
        canvas,
        // `text-anchor: middle` on an alphabetic baseline (`:1205`).
        Offset(
          label.anchor.dx - metrics.width / 2,
          label.anchor.dy - metrics.ascent,
        ),
      );
      painter.dispose();
    }
    // The overlay is a sibling `<g>` AFTER the one holding the bars
    // (`:1407-1417`), so a line always crosses over the stacks.
    _paintLines(canvas, context);
  }

  /// No regions yet.
  ///
  /// A [FluentChartHitRegion] carries a `FluentChartPopoverData`, which this
  /// chart composes out of its callout props — so the widget declares them.
  @override
  List<FluentChartHitRegion> buildHitRegions(
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
  ) => const <FluentChartHitRegion>[];
}

/// A Fluent 2 stacked vertical bar chart.
///
/// Ports `VerticalStackedBarChart.tsx`. Supports a numeric or a category y
/// axis, an optional line overlay, and two mutually exclusive focus models
/// selected by [isCalloutForStack].
class FluentVerticalStackedBarChart extends StatefulWidget {
  /// Creates a stacked bar chart over [data].
  const FluentVerticalStackedBarChart({
    super.key,
    required this.data,
    this.props = const FluentCartesianChartProps(),
    this.barWidth,
    this.maxBarWidth = 24,
    this.barGapMax = 0,
    this.barCornerRadius = 0,
    this.barMinimumHeight = 0,
    this.chartTitle,
    this.isCalloutForStack = false,
    this.allowHoverOnLegend = true,
    this.onBarClick,
    this.culture,
    this.xAxisPadding,
    this.hideLabels = false,
    this.roundCorners = false,
    this.mode,
    this.lineOptions,
    this.xAxisInnerPadding,
    this.xAxisOuterPadding,
    this.xAxisCategoryOrder,
    this.yAxisCategoryOrder,
    this.style,
    this.legendSelectionMode = FluentChartLegendSelectionMode.single,
    this.focusNode,
  });

  /// The stacks, in author order.
  final List<FluentVerticalStackedBarGroup> data;

  /// Shell configuration.
  final FluentCartesianChartProps props;

  /// `number | 'default' | 'auto'`.
  final Object? barWidth;

  /// Bar width ceiling — 24 (`VerticalStackedBarChart.tsx:90`).
  final double maxBarWidth;

  /// Maximum gap between segments; 0 disables gaps
  /// (`VerticalStackedBarChart.tsx:986`).
  final double barGapMax;

  /// Corner radius applied to the topmost segment
  /// (`VerticalStackedBarChart.tsx:986`).
  final double barCornerRadius;

  /// Floor on a segment's height (`VerticalStackedBarChart.tsx:986`).
  final double barMinimumHeight;

  /// Human title, folded into the accessible description.
  final String? chartTitle;

  /// Whether hover and focus address the whole stack instead of one segment
  /// (`VerticalStackedBarChart.tsx:486-489`).
  final bool isCalloutForStack;

  /// Whether the legend responds to hover — default true
  /// (`VerticalStackedBarChart.tsx:164`).
  final bool allowHoverOnLegend;

  /// Called with the segment, or the whole stack when [isCalloutForStack].
  final void Function(Object data)? onBarClick;

  /// BCP-47 locale for popover formatting.
  final String? culture;

  /// Legacy shorthand feeding both band paddings.
  final double? xAxisPadding;

  /// Whether the stack total labels are suppressed.
  final bool hideLabels;

  /// Whether segments get a 3px corner radius.
  final bool roundCorners;

  /// `'plotly'` or null.
  final String? mode;

  /// The chart-level line configuration, `props.lineOptions`.
  ///
  /// Only `lineBorderWidth` is read (`VerticalStackedBarChart.tsx:566-568`);
  /// the overlay's width, cap and dash come off each legend's first line point
  /// (`:617-619`).
  final FluentLineOptions? lineOptions;

  /// Band inner padding override.
  final double? xAxisInnerPadding;

  /// Band outer padding override.
  final double? xAxisOuterPadding;

  /// Ordering applied to a category x axis, or null when the caller named none.
  ///
  /// Null and [FluentAxisCategoryOrder.defaultOrder] mean the same thing here:
  /// `xAxisCategoryOrder: 'default'` sits in the object upstream spreads
  /// `_props` over (`VerticalStackedBarChart.tsx:87-91`), and both reach
  /// `sortAxisCategories`' insertion-order arm regardless.
  final FluentAxisCategoryOrder? xAxisCategoryOrder;

  /// Ordering applied to a category y axis, or null when the caller named none.
  ///
  /// See [xAxisCategoryOrder]: null and
  /// [FluentAxisCategoryOrder.defaultOrder] are interchangeable on this chart.
  final FluentAxisCategoryOrder? yAxisCategoryOrder;

  /// Style override, highest precedence.
  final FluentVerticalStackedBarChartStyle? style;

  /// Whether the legend allows more than one selection.
  final FluentChartLegendSelectionMode legendSelectionMode;

  /// The chart's single focus node.
  final FocusNode? focusNode;

  @override
  State<FluentVerticalStackedBarChart> createState() =>
      _FluentVerticalStackedBarChartState();
}

class _FluentVerticalStackedBarChartState
    extends State<FluentVerticalStackedBarChart> {
  List<String> _selectedLegends = const <String>[];
  String? _activeLegend;
  Object? _activeXAxisDataPoint;
  final FluentChartTextMeasurer _measurer = FluentChartTextMeasurer();

  int get _lineCount => <String>{
    for (final stack in widget.data)
      for (final line in stack.lineData ?? const <FluentStackedBarLineDatum>[])
        line.legend,
  }.length;

  /// `useUTC` is `string | boolean` upstream and is read as a JS truthy value
  /// (`CartesianChart.types.ts:448`), so an empty string is false.
  bool get _useUtc =>
      widget.props.useUTC == true ||
      (widget.props.useUTC is String && (widget.props.useUTC! as String) != '');

  @override
  void dispose() {
    _measurer.invalidate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Emptiness: no stack with chartData or lineData
    // (`VerticalStackedBarChart.tsx:893-899`).
    if (widget.data.every(
      (stack) => stack.chartData.isEmpty && (stack.lineData?.isEmpty ?? true),
    )) {
      return Semantics(
        container: true,
        liveRegion: true,
        label: 'Graph has no data to display',
        child: const SizedBox.shrink(),
      );
    }
    final theme = FluentTheme.of(context);
    final style = resolveFluentVerticalStackedBarChartStyle(theme)
        .merge(FluentVerticalStackedBarChartTheme.maybeOf(context))
        .merge(widget.style);
    final palette = style.linePalette!.resolve(const <WidgetState>{})!;
    return FluentCartesianChart(
      focusNode: widget.focusNode,
      legendSelectionMode: widget.legendSelectionMode,
      selectedLegends: _selectedLegends,
      onLegendChange: (selected) => setState(() => _selectedLegends = selected),
      props: widget.props.copyWith(
        // `isCalloutForStack` moves the focus props off each rect and onto the
        // stack group (`VerticalStackedBarChart.tsx:486-489`), which is the
        // shell's group granularity.
        hitRegionGranularity: widget.isCalloutForStack
            ? FluentChartHitGranularity.group
            : FluentChartHitGranularity.mark,
        // `Vertical bar chart with N stacked bars` + ` and M lines`
        // (`VerticalStackedBarChart.tsx:968-977`).
        // parity: upstream never pluralises "lines".
        chartTitleForSemantics:
            '${widget.chartTitle == null ? '' : '${widget.chartTitle}. '}'
            'Vertical bar chart with ${widget.data.length} stacked bars'
            '${_lineCount > 0 ? ' and $_lineCount lines' : ''}. ',
      ),
      legends: _legends(palette),
      delegate: FluentVerticalStackedBarChartDelegate(
        stacks: widget.data,
        style: style,
        colors: FluentChartColors.of(theme),
        measurer: _measurer,
        textStyles: FluentChartTextStyles.of(theme),
        selectedLegends: _selectedLegends,
        palette: palette,
        activeLegend: _activeLegend,
        activeXAxisDataPoint: _activeXAxisDataPoint,
        barWidthProp: widget.barWidth,
        maxBarWidth: widget.maxBarWidth,
        barGapMax: widget.barGapMax,
        barCornerRadius: widget.barCornerRadius,
        barMinimumHeight: widget.barMinimumHeight,
        hideLabels: widget.hideLabels,
        roundCorners: widget.roundCorners,
        mode: widget.mode,
        useUtc: _useUtc,
        lineOptions: widget.lineOptions,
        xAxisInnerPadding: widget.xAxisInnerPadding,
        xAxisOuterPadding: widget.xAxisOuterPadding,
        xAxisPadding: widget.xAxisPadding,
        hideTickOverlap: widget.props.hideTickOverlap,
        xAxisCategoryOrder: widget.xAxisCategoryOrder,
        yAxisCategoryOrder: widget.yAxisCategoryOrder,
        yAxisTickFormat: widget.props.yAxisTickFormat,
      ),
      onChartMouseLeave: () => setState(() => _activeXAxisDataPoint = null),
    );
  }

  List<FluentChartLegendItem> _legends(List<Color> palette) {
    final out = <FluentChartLegendItem>[];
    final seen = <String>{};
    for (final stack in widget.data) {
      for (var k = 0; k < stack.chartData.length; k++) {
        final datum = stack.chartData[k];
        // ponytail: upstream deduplicates on the (title, colour) PAIR while
        // the colour is `defaultPalette[Math.floor(Math.random() * 4 + 1)]`
        // (`VerticalStackedBarChart.tsx:167-169`), so a legend could appear
        // several times with different swatches. Spec section 5.2 exception 1
        // fixes non-determinism: the colour is the same value the segment
        // paints, and deduplication is by title alone as a result.
        final colour = datum.color ?? palette[k % palette.length];
        if (!seen.add(datum.legend)) {
          continue;
        }
        out.add(
          FluentChartLegendItem(
            title: datum.legend,
            color: colour,
            onHoverAction: widget.allowHoverOnLegend
                ? () => setState(() {
                    // `hoverAction` clears the x hover first (`.tsx:159-162`).
                    _activeXAxisDataPoint = null;
                    _activeLegend = datum.legend;
                  })
                : null,
            onMouseOutAction: widget.allowHoverOnLegend
                ? ({required bool isLegendFocused}) =>
                      setState(() => _activeLegend = null)
                : null,
          ),
        );
      }
    }
    // Line legends are appended AFTER the bar legends
    // (`VerticalStackedBarChart.tsx:207`).
    final lineSeen = <String>{};
    for (final stack in widget.data) {
      for (final line
          in stack.lineData ?? const <FluentStackedBarLineDatum>[]) {
        if (!lineSeen.add(line.legend)) {
          continue;
        }
        out.add(
          FluentChartLegendItem(
            title: line.legend,
            color: line.color,
            shape: line.legendShape,
            isLineLegendInBarChart: true,
            onHoverAction: widget.allowHoverOnLegend
                ? () => setState(() => _activeLegend = line.legend)
                : null,
            onMouseOutAction: widget.allowHoverOnLegend
                ? ({required bool isLegendFocused}) =>
                      setState(() => _activeLegend = null)
                : null,
          ),
        );
      }
    }
    return out;
  }
}

/// Applies a [FluentVerticalStackedBarChartStyle] to every stacked vertical bar
/// chart below it.
class FluentVerticalStackedBarChartTheme extends InheritedTheme {
  /// Applies [style] to every stacked vertical bar chart in `child`.
  const FluentVerticalStackedBarChartTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the derived defaults.
  final FluentVerticalStackedBarChartStyle style;

  /// The nearest stacked vertical bar chart style, or null.
  static FluentVerticalStackedBarChartStyle? maybeOf(
    BuildContext context,
  ) => context
      .dependOnInheritedWidgetOfExactType<FluentVerticalStackedBarChartTheme>()
      ?.style;

  @override
  bool updateShouldNotify(FluentVerticalStackedBarChartTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentVerticalStackedBarChartTheme(style: style, child: child);
}
