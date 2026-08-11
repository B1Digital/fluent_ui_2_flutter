import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import 'axis/axis_builders.dart';
import 'axis/axis_types.dart';
import 'axis/domain_range.dart';
import 'axis/tick_format.dart';
import 'cartesian/cartesian_chart.dart';
import 'cartesian/cartesian_chart_props.dart';
import 'cartesian/cartesian_layout.dart';
import 'cartesian/cartesian_series_delegate.dart';
import 'chrome/chart_popover.dart';
import 'chrome/legend.dart';
import 'gantt_chart_style.dart';
import 'internal/chart_colors.dart';
import 'internal/chart_text_measurer.dart';
import 'internal/chart_utils.dart';
import 'internal/d3/stable_sort.dart';
import 'internal/data_viz_palette.dart';
import 'model/bar_data.dart';
import 'model/chart_common.dart';
import 'model/chart_value.dart';

/// The bar height a Gantt chart starts from before any clamp.
///
/// `DEFAULT_BAR_HEIGHT` (`GanttChart.tsx:41`). Fed to the clamp directly on the
/// render path (`:570`) and used as the numeric-y-axis bar height, where there
/// is no bandwidth to measure.
const double kGanttDefaultBarHeight = 24;

/// A Fluent 2 Gantt chart.
///
/// Ports `GanttChart.tsx`. Each data point is a span on a numeric or date x
/// axis at a category or numeric y position.
class FluentGanttChart extends StatefulWidget {
  /// Creates a Gantt chart over [data].
  const FluentGanttChart({
    super.key,
    required this.data,
    this.props = const FluentCartesianChartProps(),
    this.barHeight,
    this.maxBarHeight = kGanttDefaultBarHeight,
    this.chartTitle,
    this.culture,
    this.yAxisPadding = 0.5,
    this.enableGradient = false,
    this.roundCorners = false,
    this.useUtc = true,
    this.yAxisCategoryOrder,
    this.popoverBuilder,
    this.style,
    this.legendSelectionMode = FluentChartLegendSelectionMode.single,
    this.focusNode,
  });

  /// The spans, in author order.
  final List<FluentGanttChartDataPoint> data;

  /// Shell configuration.
  final FluentCartesianChartProps props;

  /// Explicit bar height, overriding the auto solve.
  final double? barHeight;

  /// Bar height ceiling — 24 (`GanttChart.tsx:45`).
  final double maxBarHeight;

  /// Human title, folded into the accessible description.
  final String? chartTitle;

  /// BCP-47 locale for date formatting.
  final String? culture;

  /// Band padding, default 0.5 (`GanttChart.tsx:44`).
  final double yAxisPadding;

  /// Whether each legend paints a left-to-right gradient.
  final bool enableGradient;

  /// Whether bars get a 3px corner radius.
  final bool roundCorners;

  /// Whether dates are formatted in UTC — default true.
  final bool useUtc;

  /// Ordering applied to a category y axis, or null when the caller named none.
  ///
  /// Null and [FluentAxisCategoryOrder.defaultOrder] mean the same thing here,
  /// unlike on HeatMapChart or ScatterChart: `yAxisCategoryOrder = 'default'`
  /// (`GanttChart.tsx:45`) is a **destructuring** default, so upstream really
  /// does see `'default'` when the prop is absent and takes the reversed
  /// insertion order at `:156`.
  final FluentAxisCategoryOrder? yAxisCategoryOrder;

  /// Replaces the popover body.
  ///
  /// ponytail: upstream declares `onRenderCalloutPerDataPoint` and hands the
  /// result to `CartesianChart` as a top-level `customizedCallout` prop
  /// (`GanttChart.tsx:604`) that `CartesianChart.tsx` never reads — every other
  /// chart puts it in `calloutProps.customCallout.customizedCallout`. Wiring it
  /// correctly is a smaller change than reproducing a prop that does nothing,
  /// and the divergence is recorded here.
  final WidgetBuilder? popoverBuilder;

  /// Style override, highest precedence.
  final FluentGanttChartStyle? style;

  /// Whether the legend allows more than one selection.
  final FluentChartLegendSelectionMode legendSelectionMode;

  /// The chart's single focus node.
  final FocusNode? focusNode;

  @override
  State<FluentGanttChart> createState() => _FluentGanttChartState();
}

class _FluentGanttChartState extends State<FluentGanttChart> {
  List<String> _selectedLegends = const <String>[];
  String? _hoveredLegend;
  final FluentChartTextMeasurer _measurer = FluentChartTextMeasurer();

  @override
  void dispose() {
    _measurer.invalidate();
    super.dispose();
  }

  /// One entry per unique legend string, in first-appearance order, with the
  /// colour assigned by `getNextColor(colorIndex, 0)` (`GanttChart.tsx:72-100`).
  ///
  /// A null legend becomes the literal `"undefined"` upstream; this port keeps
  /// the same grouping by interpolating the same way. Recomputed per build
  /// rather than memoised, because the memo upstream is keyed on `props.data`
  /// and `props.enableGradient` and every other pass over the points — the
  /// bars, the hit regions — already runs per frame.
  Map<String, (Color, Color)> _legendColours() {
    final map = <String, (Color, Color)>{};
    for (final point in widget.data) {
      final key = '${point.legend}';
      if (map.containsKey(key)) {
        continue;
      }
      final start = point.color ?? FluentDataVizPalette.next(map.length);
      map[key] = widget.enableGradient && point.gradient != null
          ? point.gradient!
          : (start, start);
    }
    return map;
  }

  /// `props.data` rewritten with the legend's colour, as the `_points` memo
  /// does at `GanttChart.tsx:94-99` before anything reads a point.
  List<FluentGanttChartDataPoint> _resolvedPoints(
    Map<String, (Color, Color)> legendColours,
  ) => <FluentGanttChartDataPoint>[
    for (final point in widget.data)
      if (legendColours['${point.legend}'] case final (Color, Color) colours)
        FluentGanttChartDataPoint(
          x: point.x,
          y: point.y,
          legend: point.legend,
          color: colours.$1,
          gradient: widget.enableGradient ? colours : point.gradient,
          xAxisCalloutData: point.xAxisCalloutData,
          yAxisCalloutData: point.yAxisCalloutData,
          onClick: point.onClick,
          callOutSemantics: point.callOutSemantics,
        ),
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      // `GanttChart.tsx:612-615` — an empty `role="alert"` div carrying only
      // the label.
      return Semantics(
        container: true,
        liveRegion: true,
        label: 'Graph has no data to display',
        child: const SizedBox.shrink(),
      );
    }
    final theme = FluentTheme.of(context);
    final style = resolveFluentGanttChartStyle(
      theme,
    ).merge(FluentGanttChartTheme.maybeOf(context)).merge(widget.style);
    final legendColours = _legendColours();
    return FluentCartesianChart(
      focusNode: widget.focusNode,
      legendSelectionMode: widget.legendSelectionMode,
      selectedLegends: _selectedLegends,
      onLegendChange: (selected) => setState(() => _selectedLegends = selected),
      props: widget.props.copyWith(
        // `Gantt chart with ${n} data points. ` (`GanttChart.tsx:517-519`).
        chartTitleForSemantics:
            '${widget.chartTitle == null ? '' : '${widget.chartTitle}. '}'
            'Gantt chart with ${widget.data.length} data points. ',
        popoverBuilder: widget.popoverBuilder,
      ),
      legends: <FluentChartLegendItem>[
        for (final e in legendColours.entries)
          FluentChartLegendItem(
            title: e.key,
            color: e.value.$1,
            onHoverAction: () => setState(() => _hoveredLegend = e.key),
            onMouseOutAction: ({required bool isLegendFocused}) =>
                setState(() => _hoveredLegend = null),
          ),
      ],
      delegate: FluentGanttChartDelegate(
        points: _resolvedPoints(legendColours),
        style: style,
        colors: FluentChartColors.of(theme),
        measurer: _measurer,
        selectedLegends: _selectedLegends,
        hoveredLegend: _hoveredLegend,
        barHeightProp: widget.barHeight,
        maxBarHeight: widget.maxBarHeight,
        yAxisPadding: widget.yAxisPadding,
        enableGradient: widget.enableGradient,
        roundCorners: widget.roundCorners,
        useUtc: widget.useUtc,
        culture: widget.culture,
        yAxisCategoryOrder: widget.yAxisCategoryOrder,
      ),
      onChartMouseLeave: () => setState(() => _hoveredLegend = null),
    );
  }
}

/// Applies a [FluentGanttChartStyle] to every Gantt chart below it.
class FluentGanttChartTheme extends InheritedTheme {
  /// Applies [style] to every Gantt chart in `child`.
  const FluentGanttChartTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the derived defaults.
  final FluentGanttChartStyle style;

  /// The nearest Gantt chart style, or null.
  static FluentGanttChartStyle? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FluentGanttChartTheme>()
      ?.style;

  @override
  bool updateShouldNotify(FluentGanttChartTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentGanttChartTheme(style: style, child: child);
}

/// One resolved Gantt bar.
@immutable
class FluentGanttBar {
  /// Creates a bar.
  const FluentGanttBar({
    required this.rect,
    required this.startColour,
    required this.endColour,
    required this.opacity,
    required this.index,
  });

  /// The bar's rectangle in plot coordinates.
  final Rect rect;

  /// Gradient start, or the flat fill when it equals [endColour].
  final Color startColour;

  /// Gradient end.
  final Color endColour;

  /// 1 highlighted, 0.1 dimmed (`GanttChart.tsx:421`).
  final double opacity;

  /// Index into the delegate's [FluentGanttChartDelegate.points].
  final int index;
}

/// Renders Gantt spans into the shared cartesian shell.
///
/// Ports `GanttChart.tsx` (620 lines). `useGanttChartStyles` is inert upstream
/// — every class name resolves to the empty string — so no visual property is
/// inherited from it.
///
/// [points] arrive with their colours already assigned: upstream's `_points`
/// memo (`GanttChart.tsx:72-100`) walks the data once, mints one palette colour
/// per **legend**, and rewrites every point's `color` before the chart ever
/// draws. The widget owns that pass, so this delegate only falls back to the
/// palette for a point that still has no colour.
class FluentGanttChartDelegate extends FluentCartesianSeriesDelegate {
  /// Creates a delegate.
  const FluentGanttChartDelegate({
    required this.points,
    required this.style,
    required this.colors,
    required this.measurer,
    required this.selectedLegends,
    this.hoveredLegend,
    this.barHeightProp,
    this.maxBarHeight = kGanttDefaultBarHeight,
    this.yAxisPadding = 0.5,
    this.enableGradient = false,
    this.roundCorners = false,
    this.useUtc = true,
    this.culture,
    this.yAxisCategoryOrder,
  });

  /// The spans, in author order, with colours already assigned.
  final List<FluentGanttChartDataPoint> points;

  /// The resolved style.
  final FluentGanttChartStyle style;

  /// Resolved chart colours.
  final FluentChartColors colors;

  /// The chart subtree's single text measurer.
  final FluentChartTextMeasurer measurer;

  /// Legend titles selected by the user.
  final List<String> selectedLegends;

  /// Legend title currently hovered.
  final String? hoveredLegend;

  /// Explicit bar height, overriding the auto solve (`GanttChart.tsx:336`).
  final double? barHeightProp;

  /// Bar height ceiling — 24 (`GanttChart.tsx:45`).
  final double maxBarHeight;

  /// Band padding, already resolved by `getScalePadding`
  /// (`GanttChart.tsx:116-118`).
  @override
  final double yAxisPadding;

  /// Whether each legend paints a left-to-right gradient.
  final bool enableGradient;

  /// Whether bars get a 3px corner radius.
  final bool roundCorners;

  /// Whether dates are formatted in UTC — default true (`GanttChart.tsx:45`).
  final bool useUtc;

  /// BCP-47 locale for date formatting.
  @override
  final String? culture;

  /// Ordering applied to a category y axis, or null when the caller named none.
  ///
  /// Null and [FluentAxisCategoryOrder.defaultOrder] mean the same thing here,
  /// unlike on HeatMapChart or ScatterChart: `yAxisCategoryOrder = 'default'`
  /// (`GanttChart.tsx:45`) is a **destructuring** default, so upstream really
  /// does see `'default'` when the prop is absent and takes the reversed
  /// insertion order at `:156`.
  final FluentAxisCategoryOrder? yAxisCategoryOrder;

  @override
  FluentChartType get chartType => FluentChartType.ganttChart;

  @override
  FluentChartAxisType get xAxisType => points.isEmpty
      // parity: GanttChart.tsx:102-107 falls back to a date axis when empty.
      ? FluentChartAxisType.date
      : getTypeOfAxis(points.first.x.start, isXAxis: true);

  @override
  FluentChartAxisType get yAxisType => points.isEmpty
      ? FluentChartAxisType.category
      : getTypeOfAxis(points.first.y, isXAxis: false);

  @override
  String? get chartTitle =>
      // GanttChart.tsx:517-519. The caller's own title is prefixed by the
      // widget, which owns `FluentCartesianChartProps.chartTitleForSemantics`.
      'Gantt chart with ${points.length} data points. ';

  /// Ports `_getBarHeight` (`GanttChart.tsx:333-348`).
  ///
  /// [barHeightProp] replaces [adjustedValue] entirely, then the ceiling and
  /// the 1px floor are applied in that order.
  double barHeightFor(double adjustedValue) {
    var height = barHeightProp ?? adjustedValue;
    height = math.min(height, maxBarHeight);
    return math.max(
      height,
      // MIN_BAR_HEIGHT (`GanttChart.tsx:42`).
      style.minBarHeight!.resolve(const <WidgetState>{})!,
    );
  }

  Map<String, List<double>> _yToDurations() {
    final out = <String, List<double>>{};
    for (final point in points) {
      (out['${point.y}'] ??= <double>[]).add(
        _asNum(point.x.end) - _asNum(point.x.start),
      );
    }
    return out;
  }

  /// The y-axis labels in band order — bottom of the plot first.
  ///
  /// Ports `_getOrderedYAxisLabels` (`GanttChart.tsx:148-159`): numeric
  /// ascending off a non-string axis, insertion order **reversed** for the
  /// default string order, `sortAxisCategories` otherwise.
  List<String> get orderedYAxisLabels {
    final map = _yToDurations();
    if (yAxisType != FluentChartAxisType.category) {
      return stableSort(
        map.keys.toList(),
        (String a, String b) => double.parse(a).compareTo(double.parse(b)),
      );
    }
    // Null is the absent prop, which `GanttChart.tsx:45` fills in with
    // `'default'` before `:155` ever sees it.
    if (yAxisCategoryOrder == null ||
        yAxisCategoryOrder == FluentAxisCategoryOrder.defaultOrder) {
      return map.keys.toList().reversed.toList(growable: false);
    }
    return sortAxisCategories(map, yAxisCategoryOrder);
  }

  @override
  List<String>? get stringDatasetForYAxisDomain =>
      yAxisType == FluentChartAxisType.category ? orderedYAxisLabels : null;

  /// The `(min, max)` date-format levels across every start and end.
  ///
  /// Ports `_dateFormatOptions` (`GanttChart.tsx:120-135`). The seeds are
  /// upstream's 100 and -1, clamped here to the eight levels the table has,
  /// because [multiLevelDateTimeFormatOptions] guards the same range.
  (int, int) get dateFormatLevels {
    // 7 is the coarsest level, 0 the finest (`utilities.ts:410-433`).
    var lowest = 7;
    var highest = 0;
    for (final point in points) {
      for (final value in <Object>[point.x.start, point.x.end]) {
        if (value is! DateTime) {
          continue;
        }
        final level = getDateFormatLevel(value, useUtc: useUtc);
        lowest = math.min(lowest, level);
        highest = math.max(highest, level);
      }
    }
    return (lowest, highest);
  }

  /// `"<start> - <end>"` (`GanttChart.tsx:196-224`).
  String formattedSpan(FluentGanttChartDataPoint point) {
    if (point.x.start is! DateTime) {
      return '${point.x.start} - ${point.x.end}';
    }
    final levels = dateFormatLevels;
    final options = multiLevelDateTimeFormatOptions(levels.$1, levels.$2);
    String format(Object value) => formatDateToLocaleString(
      value as DateTime,
      culture: culture,
      useUtc: useUtc,
      // `showTZname` is explicitly false here (`GanttChart.tsx:206`, `:213`).
      showTZname: false,
      options: options,
    );
    return '${format(point.x.start)} - ${format(point.x.end)}';
  }

  @override
  FluentChartMargins? yDomainMargins(double containerHeight) {
    // Defaults from CartesianChart.tsx:41-42, the margins the shell has
    // already written into `_margins.current` by the time :525 reads them.
    const marginTop = 20.0;
    const marginBottom = 35.0;
    var domainMargin = kMinDomainMargin;
    if (yAxisType != FluentChartAxisType.category) {
      final totalHeight =
          containerHeight -
          (marginTop + kMinDomainMargin) -
          (marginBottom + kMinDomainMargin);
      final uniqueY = <Object>{
        for (final point in points) point.y,
      }.toList(growable: false);
      domainMargin +=
          barHeightFor(
            calculateAppropriateBarWidth(
              uniqueY,
              totalHeight,
              getScalePadding(yAxisPadding, null, 0.5),
            ),
          ) /
          2;
    }
    return FluentChartMargins(
      top: marginTop + domainMargin,
      bottom: marginBottom + domainMargin,
    );
  }

  @override
  FluentChartDomainRange resolveXDomainRange({
    required FluentChartMargins margins,
    required double containerWidth,
    required bool isRtl,
    required double? barWidth,
    required List<Object>? tickValues,
  }) {
    // Chart-local, not one of the shared six (`GanttChart.tsx:163-190`): the
    // exact data extent, with no padding and no nice().
    var lo = double.infinity;
    var hi = double.negativeInfinity;
    Object? loValue;
    Object? hiValue;
    for (final point in points) {
      for (final value in <Object>[point.x.start, point.x.end]) {
        final number = _asNum(value);
        if (number < lo) {
          lo = number;
          loValue = value;
        }
        if (number > hi) {
          hi = number;
          hiValue = value;
        }
      }
    }
    // parity: `d3Min(...) || 0` (`:179-180`) swallows a **falsy** minimum, so
    // a numeric 0 is replaced by the identical 0 and a Date is never replaced
    // at all — `new Date(0)` is an object, and every object is truthy.
    final start = loValue == null || (loValue is num && loValue == 0)
        ? 0
        : loValue;
    final end = hiValue == null || (hiValue is num && hiValue == 0)
        ? 0
        : hiValue;
    return FluentChartDomainRange(
      dStartValue: isRtl ? end : start,
      dEndValue: isRtl ? start : end,
      rStartValue: margins.left ?? 0,
      rEndValue: containerWidth - (margins.right ?? 0),
    );
  }

  @override
  FluentChartMinMax resolveYMinMax({bool useSecondaryYScale = false}) =>
      findHBCWANumericMinMaxOfY(points, yAxisType);

  @override
  FluentAxisSpec createYAxis(
    FluentYAxisParams params,
    FluentAxisData axisData, {
    required bool isRtl,
    required bool isIntegralDataset,
    bool useSecondaryYScale = false,
  }) =>
      createYAxisForHorizontalBarChartWithAxis(params, axisData, isRtl: isRtl);

  @override
  FluentAxisSpec createStringYAxis(
    FluentYAxisParams params,
    List<String> dataPoints,
    FluentAxisData axisData, {
    required bool isRtl,
  }) => createStringYAxisForHorizontalBarChartWithAxis(
    params,
    dataPoints,
    axisData,
    isRtl: isRtl,
  );

  /// Resolves every bar, in draw order.
  ///
  /// Ports `_getOrderedDataPoints` (`GanttChart.tsx:350-369`) and `_createBars`
  /// (`:371-453`). [layout] is unread: every coordinate a bar needs is on the
  /// two scales, and the shell has already sized them.
  List<FluentGanttBar> barsFor(
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
  ) {
    final isCategoryAxis = yAxisType == FluentChartAxisType.category;
    // A continuous scale reports a zero bandwidth, so the centring term below
    // collapses to `-barHeight / 2` exactly as `:408` does upstream.
    final bandwidth = isCategoryAxis ? context.yScalePrimary.bandwidth : 0.0;
    final barHeight = barHeightFor(
      // `:400` measures the band; `:570` seeds the numeric axis with
      // DEFAULT_BAR_HEIGHT before the render.
      isCategoryAxis ? bandwidth : kGanttDefaultBarHeight,
    );
    final dimmed = style.barOpacity!.resolve(<WidgetState>{
      WidgetState.disabled,
    })!;
    final minWidth = style.minBarWidth!.resolve(const <WidgetState>{})!;
    final labels = orderedYAxisLabels;
    final bars = <FluentGanttBar>[];
    // `:361` walks the labels last to first, so the bottom row is drawn first.
    for (var label = labels.length - 1; label >= 0; label--) {
      final indices = stableSort(
        <int>[
          for (var i = 0; i < points.length; i++)
            if ('${points[i].y}' == labels[label]) i,
        ],
        // `:364` — `+a.x.start - +b.x.start`, a stable sort in JavaScript, so
        // two bars starting together keep their author order.
        (int a, int b) =>
            _asNum(points[a].x.start).compareTo(_asNum(points[b].x.start)),
      );
      for (final index in indices) {
        final point = points[index];
        final x1 = context.xScale(point.x.start)!;
        final x2 = context.xScale(point.x.end)!;
        final top =
            context.yScalePrimary(point.y)! + (bandwidth - barHeight) / 2;
        final fallback = point.color ?? FluentDataVizPalette.next(index);
        // parity: with `enableGradient` set and no gradient on the point,
        // `:84-85` assigns `undefined` to both stops and the bar renders with
        // no fill; the `?? fallback` keeps a colour instead, because an
        // invisible bar is an accessibility defect (spec section 5.2).
        final gradient = enableGradient ? point.gradient : null;
        bars.add(
          FluentGanttBar(
            rect: Rect.fromLTWH(
              math.min(x1, x2),
              top,
              math.max((x2 - x1).abs(), minWidth),
              barHeight,
            ),
            startColour: colors.flattenMark(gradient?.$1 ?? fallback),
            endColour: colors.flattenMark(gradient?.$2 ?? fallback),
            opacity: _isHighlighted(point) ? 1 : dimmed,
            index: index,
          ),
        );
      }
    }
    return bars;
  }

  @override
  void paintSeries(
    Canvas canvas,
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
    FluentChartColors colors,
  ) {
    final radius = roundCorners
        ? style.barCornerRadius!.resolve(const <WidgetState>{})!
        : 0.0;
    for (final bar in barsFor(context, layout)) {
      Color fade(Color colour) =>
          colour.withValues(alpha: colour.a * bar.opacity);
      final paint = Paint();
      if (bar.startColour == bar.endColour) {
        paint.color = fade(bar.startColour);
      } else {
        // `:389-392` is a left-to-right linearGradient with the two stops at
        // offsets 0 and 1. The opacity is folded into the stops, because a
        // shader ignores `Paint.color`.
        paint.shader = LinearGradient(
          colors: <Color>[fade(bar.startColour), fade(bar.endColour)],
        ).createShader(bar.rect);
      }
      if (radius == 0) {
        canvas.drawRect(bar.rect, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(bar.rect, Radius.circular(radius)),
          paint,
        );
      }
    }
  }

  @override
  List<FluentChartHitRegion> buildHitRegions(
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
  ) {
    final regions = <FluentChartHitRegion>[];
    for (final bar in barsFor(context, layout)) {
      final point = points[bar.index];
      // `:427` gives an unhighlighted rect `tabIndex={-1}` and `:285` returns
      // before opening its callout, so it is not an interactive area at all.
      if (!_isHighlighted(point)) {
        continue;
      }
      final xValue = point.xAxisCalloutData ?? formattedSpan(point);
      final yValue = point.yAxisCalloutData ?? '${point.y}';
      regions.add(
        FluentChartHitRegion(
          bounds: bar.rect,
          index: regions.length,
          legend: '${point.legend}',
          popoverData: FluentChartPopoverData(
            // `:298-299` — the row on top, the span underneath.
            xValue: yValue,
            yValue: xValue,
            legend: point.legend,
            color: bar.startColour,
            // parity: `_getCustomizedCallout` (`:226-245`) is handed to
            // `CartesianChart` as a top-level `customizedCallout` prop
            // (`:604`), and `CartesianChart.tsx:444-445` renders `calloutProps`
            // alone, so it never reaches `ChartPopover.tsx:54`. A Gantt
            // `onRenderCalloutPerDataPoint` therefore has no effect upstream
            // and none here: no custom body is ever built.
          ),
          // `:247-257`.
          semanticsLabel:
              point.callOutSemantics?.label ??
              '$yValue. '
                  '${point.legend != null ? '${point.legend}, ' : ''}'
                  '$xValue.',
        ),
      );
    }
    return regions;
  }

  /// `_noLegendHighlighted() || _legendHighlighted(legend)`
  /// (`GanttChart.tsx:259-281`, applied at `:410`).
  bool _isHighlighted(FluentGanttChartDataPoint point) {
    final noneHighlighted =
        selectedLegends.isEmpty &&
        (hoveredLegend == null || hoveredLegend!.isEmpty);
    return noneHighlighted ||
        isLegendHighlightedMulti(
          // `:271` interpolates, so a point with no legend compares as the
          // string 'null' — 'undefined' upstream.
          '${point.legend}',
          selectedLegends: selectedLegends,
          activeLegend: hoveredLegend,
        );
  }

  static double _asNum(Object value) => switch (value) {
    final num n => n.toDouble(),
    final DateTime d => d.millisecondsSinceEpoch.toDouble(),
    _ => double.nan,
  };
}
