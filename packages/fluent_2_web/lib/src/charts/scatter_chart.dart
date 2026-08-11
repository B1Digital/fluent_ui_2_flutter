import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import 'axis/axis_builders.dart' as builders;
import 'axis/axis_types.dart';
import 'axis/domain_range.dart';
import 'cartesian/cartesian_chart.dart';
import 'cartesian/cartesian_chart_props.dart';
import 'cartesian/cartesian_layout.dart';
import 'cartesian/cartesian_series_delegate.dart';
import 'chrome/chart_popover.dart';
import 'chrome/legend.dart';
import 'internal/chart_colors.dart';
import 'internal/chart_text_measurer.dart';
import 'internal/chart_text_styles.dart';
import 'internal/chart_utils.dart';
import 'internal/data_viz_palette.dart';
import 'internal/marker_geometry.dart';
import 'internal/scatter_polar.dart';
import 'model/callout_data.dart';
import 'model/cartesian_series.dart';
import 'model/chart_common.dart';
import 'model/chart_value.dart';
import 'scatter_chart_style.dart';

/// A Fluent 2 scatter chart.
///
/// Ports `ScatterChart.tsx`. Renders through [FluentCartesianChart], which owns
/// the margins, axes, legend row, popover host and annotation layer; this
/// widget owns only the marker geometry, the legend selection state and the
/// hover/focus model.
class FluentScatterChart extends StatefulWidget {
  /// Creates a scatter chart over [data].
  const FluentScatterChart({
    super.key,
    required this.data,
    this.props = const FluentCartesianChartProps(),
    this.culture,
    this.style,
    this.legendSelectionMode = FluentChartLegendSelectionMode.single,
    this.focusNode,
  });

  /// The data bundle. Only `scatterChartData` and `chartTitle` are read.
  final FluentChartData data;

  /// Shell configuration shared by every cartesian chart.
  final FluentCartesianChartProps props;

  /// BCP-47 locale used to format popover values.
  ///
  /// ponytail: declared, not yet consumed. Upstream spends it in exactly one
  /// place — `formatDateToLocaleString(x, props.culture, …)` at
  /// `ScatterChart.tsx:568` and `:534`, which formats a *date* x value for the
  /// popover header. [FluentScatterChartDelegate.popoverFor] prints the raw x,
  /// so wiring this means teaching that method to format, which is the same
  /// change every cartesian chart needs and is better made once.
  final String? culture;

  /// Style override, highest precedence.
  final FluentScatterChartStyle? style;

  /// Whether the legend allows more than one selection at a time.
  final FluentChartLegendSelectionMode legendSelectionMode;

  /// The chart's single focus node. One node roves over the markers, per
  /// spec section 5.7.
  final FocusNode? focusNode;

  @override
  State<FluentScatterChart> createState() => _FluentScatterChartState();
}

class _FluentScatterChartState extends State<FluentScatterChart> {
  /// The legend selection the shell's legend row reports back.
  ///
  /// [FluentCartesianChartProps] has NO `selectedLegends` field — the frozen
  /// props bag never carried one (contract 7.1) — so there is nothing to seed
  /// from and no `didUpdateWidget` sync to write. The selection enters through
  /// [FluentCartesianChart.onLegendChange] and is handed to the delegate for
  /// dimming, which is all `ScatterChart.tsx:106-114`'s effect does once the
  /// legend row lives in the shell.
  List<String> _selectedLegends = const <String>[];
  String? _activeLegend;
  String? _activePointId;
  FluentChartPopoverData? _popoverData;
  Offset? _popoverAnchor;
  FocusNode? _internalFocusNode;
  FluentScatterChartDelegate? _delegate;
  late FluentChartTextMeasurer _measurer;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _measurer = FluentChartTextMeasurer();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(FluentScatterChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      (oldWidget.focusNode ?? _internalFocusNode)?.removeListener(
        _handleFocusChange,
      );
      _focusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _internalFocusNode?.dispose();
    _measurer.invalidate();
    super.dispose();
  }

  /// `_handleFocus` (`ScatterChart.tsx:519-556`).
  ///
  /// Upstream's every-circle `onFocus` runs the callout branch at `:543-552`
  /// under `_refArray.forEach`, and `_refArray` is declared at `:81` and never
  /// pushed to — so the loop body is dead and focus reaches only the
  /// `setActivePoint(circleId)` at `:554`. The popover therefore never opens on
  /// focus, which the widget reproduces by suppressing the shell's popover
  /// layer outright and rendering its own on hover instead.
  ///
  /// ponytail: the active point pins to the first marker rather than following
  /// the roving index, because the shell's index is private and it reports no
  /// focus-change callback. Upgrade path: add one to
  /// [FluentCartesianChart] — plan 05 owns that file — and set the id from it.
  void _handleFocusChange() {
    final hasFocus = _focusNode.hasFocus;
    setState(() => _activePointId = hasFocus ? '0_0' : null);
  }

  /// `_handleHover` (`ScatterChart.tsx:558-590`), bound to the circle's own
  /// `onMouseMove`/`onMouseOver` (`:465-466`) rather than to the plot, so it
  /// resolves the marker under the pointer first and does nothing in the gaps.
  ///
  /// Leaving a marker is deliberately not a reset: `_handleMouseOut` (`:606`)
  /// only hides the vertical rule, so the callout stays where the last marker
  /// put it until the pointer leaves the chart entirely (`:610-616`).
  void _handlePointerMove(Offset local, FluentCartesianChildContext context) {
    final delegate = _delegate;
    if (delegate == null) {
      return;
    }
    // `marksFor` walks the series backwards so series 0 paints last; the
    // topmost circle is therefore the last one, so the hit test runs in
    // reverse.
    for (final mark in delegate.marksFor(context).reversed) {
      if ((mark.centre - local).distance > mark.radius) {
        continue;
      }
      final id = '${mark.seriesIndex}_${mark.pointIndex}';
      // `if (_uniqueCallOutID !== circleId)` (`:577`) — re-entering the same
      // circle changes nothing.
      if (id == _activePointId && _popoverData != null) {
        return;
      }
      setState(() {
        _activePointId = id;
        _popoverAnchor = local;
        _popoverData = delegate.popoverFor(mark);
      });
      return;
    }
  }

  /// `_handleChartMouseLeave` (`ScatterChart.tsx:610-616`).
  void _handleChartMouseLeave() => setState(() {
    _activePointId = null;
    _popoverData = null;
    _popoverAnchor = null;
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final style = resolveFluentScatterChartStyle(
      theme,
    ).merge(FluentScatterChartTheme.maybeOf(context)).merge(widget.style);
    final series =
        widget.data.scatterChartData ?? const <FluentScatterChartSeries>[];
    // `_isChartEmpty` (`ScatterChart.tsx:658-665`), gating the whole render at
    // `:719`: a chart with no series, or with none that holds a point, renders
    // the bare alert node at `:768` instead of a shell. Without the gate the
    // band scale is handed an empty domain and the axis painter draws a NaN.
    if (!series.any((series) => series.data.isNotEmpty)) {
      return Semantics(
        container: true,
        liveRegion: true,
        label: 'Graph has no data to display',
        child: const SizedBox.shrink(),
      );
    }
    final delegate = _delegate = FluentScatterChartDelegate(
      data: widget.data,
      style: style,
      colors: FluentChartColors.of(theme),
      textStyles: FluentChartTextStyles.of(theme),
      measurer: _measurer,
      selectedLegends: _selectedLegends,
      activeLegend: _activeLegend,
      activePointId: _activePointId,
      xScaleType: widget.props.xScaleType,
      yScaleType: widget.props.yScaleType,
      xMinValue: widget.props.xMinValue,
      xMaxValue: widget.props.xMaxValue,
      yAxisCategoryOrder: widget.props.yAxisCategoryOrder,
    );
    return FluentCartesianChart(
      focusNode: _focusNode,
      // parity: ScatterChart.tsx:722 passes the title through UNADORNED — no
      // 'Scatter chart with N series' suffix, unlike Area (`:1012`) and Line
      // (`:1843-1846`). It still has to be handed over explicitly: neither this
      // widget's props nor FluentScatterChartDelegate sets a title otherwise,
      // so the shell would fall all the way through to the generic 'Chart. '
      // prefix in buildFluentCartesianChartDescription.
      props: widget.props.copyWith(
        chartTitleForSemantics: widget.data.chartTitle,
        // The shell opens its popover for the focused region as readily as for
        // the hovered one, and upstream's focus path cannot open one at all
        // (see [_handleFocusChange]). Replacing the shell's layer with an empty
        // one leaves this widget the only thing that can raise a popover, which
        // it does from [_handlePointerMove] through `overlayBuilder`.
        popoverBuilder: (context) => const SizedBox.shrink(),
        // `{...(_isScatterPolarRef.current ? { yMaxValue: 1, yMinValue: -1 }
        // : {})}` (`ScatterChart.tsx:742`), spread after `{...props}` at `:723`
        // so it overrides a caller's own bounds. The polar transform writes
        // onto the unit circle (`scatterpolar-utils.tsx:41-42`), so without
        // this the ring and the data are scaled by whatever extent the data
        // happens to have.
        yMinValue: delegate.isScatterPolar ? -1 : null,
        yMaxValue: delegate.isScatterPolar ? 1 : null,
      ),
      legendSelectionMode: widget.legendSelectionMode,
      selectedLegends: null,
      onLegendChange: (selected) => setState(() => _selectedLegends = selected),
      // parity: ScatterChart.tsx:680 hides the legend entirely in text mode.
      legends: isTextMode(series)
          ? const <FluentChartLegendItem>[]
          : <FluentChartLegendItem>[
              for (var i = 0; i < series.length; i++)
                FluentChartLegendItem(
                  title: series[i].legend,
                  color: series[i].color ?? FluentDataVizPalette.next(i),
                  shape: series[i].legendShape,
                  // `hoverAction` runs `_handleChartMouseLeave()` first
                  // (`ScatterChart.tsx:273-275`), so hovering a legend closes
                  // whatever callout a marker had open.
                  onHoverAction: () {
                    _handleChartMouseLeave();
                    setState(() => _activeLegend = series[i].legend);
                  },
                  onMouseOutAction: ({required bool isLegendFocused}) =>
                      setState(() => _activeLegend = null),
                ),
            ],
      delegate: _delegate!,
      overlayBuilder: _buildPopoverLayer,
      onPointerMoveInPlot: _handlePointerMove,
      onChartMouseLeave: _handleChartMouseLeave,
    );
  }

  Widget _buildPopoverLayer(
    BuildContext context,
    FluentCartesianChildContext childContext,
    FluentCartesianLayout layout,
  ) {
    final data = _popoverData;
    final anchor = _popoverAnchor;
    if (data == null || anchor == null || widget.props.hideTooltip) {
      return const SizedBox.shrink();
    }
    // The shell narrates the focused hit region on its own Semantics node, so
    // the popover's text would be read a second time if it were not excluded.
    return IgnorePointer(
      child: ExcludeSemantics(
        child: FluentChartPopover(data: data, anchor: anchor),
      ),
    );
  }
}

/// One painted scatter marker, resolved against the live scales.
///
/// Produced by [FluentScatterChartDelegate.marksFor] and consumed both by the
/// painter and by the hit-region builder, so the circle a user hovers is
/// guaranteed to be the circle that was painted.
@immutable
class FluentScatterMark {
  /// Creates a mark.
  const FluentScatterMark({
    required this.centre,
    required this.radius,
    required this.colour,
    required this.strokeColour,
    required this.opacity,
    required this.isActive,
    required this.seriesIndex,
    required this.pointIndex,
    required this.labelBaselineOffset,
    required this.semanticsLabel,
    this.label,
  });

  /// Circle centre in chart coordinates.
  final Offset centre;

  /// Circle radius from [calculateMarkerRadius].
  final double radius;

  /// The series colour, already flattened by [FluentChartColors.flattenMark].
  ///
  /// The point's own `markerColor` is deliberately ignored: ScatterChart reads
  /// only `series.color` (`ScatterChart.tsx:474`).
  final Color colour;

  /// The halo colour, flattened by [FluentChartColors.flattenMarkStroke].
  ///
  /// Upstream strokes the circle with the same series colour it fills with
  /// (`ScatterChart.tsx:475`); the two only diverge under forced colours, where
  /// sending both to the system foreground would erase the outline (spec
  /// section 5.3).
  final Color strokeColour;

  /// 1 when the mark's legend owns the highlight, 0.1 otherwise.
  final double opacity;

  /// Whether this is the active point, which inverts the fill.
  final bool isActive;

  /// Index of the owning series in the original, unreversed order.
  final int seriesIndex;

  /// Index of the point inside its series.
  final int pointIndex;

  /// `max(radius + 12, 16)` — the label baseline drop (`ScatterChart.tsx:484`).
  final double labelBaselineOffset;

  /// The accessible name for this mark.
  final String semanticsLabel;

  /// The point's own `text`, painted below the marker when present.
  final String? label;
}

/// Renders `data.scatterChartData` into the shared cartesian shell.
///
/// Ports `ScatterChart.tsx` (771 lines). The 3x2 axis-type matrix — x numeric,
/// date or category against y numeric or category — is resolved once in
/// [xAxisType] / [yAxisType] and then only changes two things: whether a half
/// bandwidth is added to a centre, and whether the marker sizes are scaled to
/// the plot (`isContinuousXY`) or normalised into `[4, 16]`.
class FluentScatterChartDelegate extends FluentCartesianSeriesDelegate {
  /// Creates a delegate over [data].
  const FluentScatterChartDelegate({
    required this.data,
    required this.style,
    required this.colors,
    required this.textStyles,
    required this.measurer,
    required this.selectedLegends,
    this.activeLegend,
    this.activePointId,
    this.xScaleType,
    this.yScaleType,
    this.xMinValue,
    this.xMaxValue,
    this.yAxisCategoryOrder,
  });

  /// The chart's data bundle. Only [FluentChartData.scatterChartData] is read.
  final FluentChartData data;

  /// The resolved style.
  final FluentScatterChartStyle style;

  /// Resolved chart colours, which also carry the high-contrast flattening.
  final FluentChartColors colors;

  /// Resolved chart text styles.
  final FluentChartTextStyles textStyles;

  /// The chart subtree's single text measurer.
  final FluentChartTextMeasurer measurer;

  /// Legend titles selected by the user.
  final List<String> selectedLegends;

  /// Legend title currently hovered, if any.
  final String? activeLegend;

  /// Identifier of the active point, `"<series>_<point>"`.
  final String? activePointId;

  /// Optional log scaling on x.
  final FluentAxisScaleType? xScaleType;

  /// Optional log scaling on y.
  final FluentAxisScaleType? yScaleType;

  /// User-supplied x domain floor.
  final double? xMinValue;

  /// User-supplied x domain ceiling.
  final double? xMaxValue;

  /// Ordering applied to a category y axis, or null when the caller named none.
  ///
  /// ScatterChart sets no default for the prop (`ScatterChart.tsx:68`), so an
  /// absent one is `undefined`, `undefined !== 'default'` at `:301` is true and
  /// the labels come back in insertion order — **not** in the reverse-series
  /// order the explicit [FluentAxisCategoryOrder.defaultOrder] selects.
  final FluentAxisCategoryOrder? yAxisCategoryOrder;

  List<FluentScatterChartSeries> get _series =>
      data.scatterChartData ?? const <FluentScatterChartSeries>[];

  @override
  FluentChartType get chartType => FluentChartType.scatterChart;

  @override
  FluentChartAxisType get xAxisType =>
      _series.isEmpty || _series.first.data.isEmpty
      // parity: ScatterChart.tsx:116-122 falls back to a category axis.
      ? FluentChartAxisType.category
      : getTypeOfAxis(_series.first.data.first.x, isXAxis: true);

  @override
  FluentChartAxisType get yAxisType =>
      _series.isEmpty || _series.first.data.isEmpty
      // parity: ScatterChart.tsx:124-132 falls back to numeric, not category.
      ? FluentChartAxisType.numeric
      : _series.first.data.first.y is String
      ? FluentChartAxisType.category
      : FluentChartAxisType.numeric;

  /// Whether neither axis is a band scale (`ScatterChart.tsx:388`).
  bool get isContinuousXy =>
      xAxisType != FluentChartAxisType.category &&
      yAxisType != FluentChartAxisType.category;

  /// Whether this is a scatterpolar chart (`ScatterChart.tsx:244`).
  ///
  /// The same `isScatterPolarSeries` (`utilities.ts:2204-2209`) the line chart
  /// asks, which compares the **whole** mode literal rather than testing for a
  /// substring, so `FluentLineMode.upstreamName` and not the three flags is
  /// what carries it.
  bool get isScatterPolar => _series.any(
    (series) => series.lineOptions?.mode?.upstreamName == 'scatterpolar',
  );

  /// The scatterpolar category labels, one ring per series.
  ///
  /// Ports the call at `ScatterChart.tsx:495-504`, which sits inside the
  /// per-series loop opened at `:399` and pushes onto `pointsForSeries`, after
  /// that series' circles. It differs from the line chart's twin
  /// (`LineChart.tsx:1346-1355`) in exactly one thing: `:499` passes the
  /// chart's single `_yAxisScale`, where `:1350` passes the series' own
  /// `yScale`, which may be the secondary one.
  List<({int seriesIndex, FluentScatterPolarLabel label})>
  scatterPolarLabelsFor(FluentCartesianChildContext context) {
    if (!isScatterPolar) {
      return const <({int seriesIndex, FluentScatterPolarLabel label})>[];
    }
    final out = <({int seriesIndex, FluentScatterPolarLabel label})>[];
    for (var i = _series.length - 1; i >= 0; i--) {
      for (final label in scatterPolarLabelsForSeries(
        options: _series[i].polarLineOptions,
        xScale: context.xScale,
        yScale: context.yScalePrimary,
      )) {
        out.add((seriesIndex: i, label: label));
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
    FluentChartAxisType.numeric => domainRangeOfNumericForAreaLineScatterCharts(
      _series,
      margins,
      containerWidth,
      isRtl: isRtl,
      scaleType: xScaleType,
      // ScatterChart.tsx:211 hard-codes hasMarkersMode true, so the numeric
      // x domain ALWAYS carries the ten-percent marker pad.
      hasMarkersMode: true,
      xMinVal: xMinValue,
      xMaxVal: xMaxValue,
    ),
    FluentChartAxisType.date =>
      domainRangeOfDateForAreaLineScatterVerticalBarCharts(
        _series,
        margins,
        containerWidth,
        isRtl: isRtl,
        tickValues: tickValues?.whereType<DateTime>().toList() ?? _noDates,
        chartType: FluentChartType.scatterChart,
      ),
    FluentChartAxisType.category => domainRangeOfXStringAxis(
      margins,
      containerWidth,
      isRtl: isRtl,
    ),
  };

  static const List<DateTime> _noDates = <DateTime>[];

  @override
  FluentChartMinMax resolveYMinMax({bool useSecondaryYScale = false}) {
    final raw = findNumericMinMaxOfY(
      _series,
      useSecondaryYScale: useSecondaryYScale,
      scaleType: yScaleType,
    );
    final pad = getDomainPaddingForMarkers(
      raw.startValue,
      raw.endValue,
      scaleType: yScaleType,
    );
    // ponytail: exactly one pad, at `ScatterChart.tsx:180-190`.
    // `utilities.ts:825-831` computes a second one into locals that `:832`
    // never reads, so reproducing it would be a bug, not parity. Contract §1.
    return FluentChartMinMax(
      startValue: raw.startValue - pad.start,
      endValue: raw.endValue + pad.end,
    );
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
    chartType: FluentChartType.scatterChart,
    useSecondaryYScale: useSecondaryYScale,
    scaleType: yScaleType,
  );

  @override
  FluentAxisSpec createStringYAxis(
    FluentYAxisParams params,
    List<String> dataPoints,
    FluentAxisData axisData, {
    required bool isRtl,
  }) => builders.createStringYAxis(
    params,
    dataPoints,
    axisData,
    isRtl: isRtl,
    chartType: FluentChartType.scatterChart,
  );

  @override
  List<String>? get datasetForXAxisDomain =>
      xAxisType == FluentChartAxisType.category ? xAxisCategories : null;

  @override
  List<String>? get stringDatasetForYAxisDomain =>
      yAxisType == FluentChartAxisType.category ? orderedYAxisLabels : null;

  @override
  bool get isIntegralDataset => !_series.any(
    (FluentScatterChartSeries series) => series.data.any(
      (FluentScatterChartDataPoint point) =>
          point.y is num && (point.y as num) % 1 != 0,
    ),
  );

  /// The unique category x values, in series-forward, point-forward order
  /// (`ScatterChart.tsx:710-714`).
  List<String> get xAxisCategories {
    final seen = <String>{};
    for (final series in _series) {
      for (final point in series.data) {
        if (point.x is String) {
          seen.add(point.x as String);
        }
      }
    }
    return seen.toList(growable: false);
  }

  /// The category y labels.
  ///
  /// With the default order upstream walks the **series backwards** and the
  /// points forwards, keeping first-seen order in that reversed traversal
  /// (`ScatterChart.tsx:299-315`); any other order delegates to
  /// [sortAxisCategories].
  List<String> get orderedYAxisLabels {
    if (yAxisCategoryOrder != FluentAxisCategoryOrder.defaultOrder) {
      return sortAxisCategories(_categoryToValues(), yAxisCategoryOrder);
    }
    final seen = <String>{};
    for (var i = _series.length - 1; i >= 0; i--) {
      for (final point in _series[i].data) {
        if (point.y is String) {
          seen.add(point.y as String);
        }
      }
    }
    return seen.toList(growable: false);
  }

  /// `_mapCategoryToValues` (`ScatterChart.tsx:321-337`): only a **numeric** x
  /// joins the bucket, so a category-against-category chart sorts on empty
  /// lists.
  Map<String, List<double>> _categoryToValues() {
    final out = <String, List<double>>{};
    for (final series in _series) {
      for (final point in series.data) {
        if (point.y is String) {
          final bucket = out[point.y as String] ??= <double>[];
          if (point.x is num) {
            bucket.add((point.x as num).toDouble());
          }
        }
      }
    }
    return out;
  }

  /// Resolves every marker for [context].
  ///
  /// Series are walked from last to first so that series 0 paints last and
  /// therefore sits on top (`ScatterChart.tsx:399`).
  List<FluentScatterMark> marksFor(FluentCartesianChildContext context) {
    // parity: ScatterChart.tsx:435 suppresses every circle and label in text
    // mode. `isTextMode` reads `lineOptions` through an `as any` cast
    // (`utilities.ts:2219`) and `ScatterChartPoints` declares no such member
    // (`types/DataPoint.ts:1033-1075`), so this can only fire if the model ever
    // grows one. It is kept because the widget's legend is gated on the same
    // predicate (`ScatterChart.tsx:680`).
    if (isTextMode(_series)) {
      return const <FluentScatterMark>[];
    }
    final xBandwidth = xAxisType == FluentChartAxisType.category
        ? context.xScale.bandwidth / 2
        : 0.0;
    final (minSize, maxSize) = _markerSizeExtent();
    final extraMaxPixels = isContinuousXy
        ? getRangeForScatterMarkerSize(
            points: _series,
            xScale: context.xScale,
            yScalePrimary: context.yScalePrimary,
            yScaleSecondary: context.yScaleSecondary,
            xScaleType: xScaleType,
            yScaleType: yScaleType,
          )
        : 0.0;
    final defaultRadius = style.markerRadius!.resolve(<WidgetState>{})!;
    final activeRadius = style.markerRadius!.resolve(<WidgetState>{
      WidgetState.hovered,
    })!;
    final dimOpacity = style.markerOpacity!.resolve(<WidgetState>{
      WidgetState.disabled,
    })!;
    final fullOpacity = style.markerOpacity!.resolve(<WidgetState>{})!;
    final labelGap = style.markerLabelGap!.resolve(<WidgetState>{})!;
    final labelMinGap = style.markerLabelMinGap!.resolve(<WidgetState>{})!;

    final marks = <FluentScatterMark>[];
    for (var i = _series.length - 1; i >= 0; i--) {
      final series = _series[i];
      final highlighted = isLegendHighlightedMulti(
        series.legend,
        selectedLegends: selectedLegends,
        activeLegend: activeLegend,
      );
      // `_noLegendHighlighted` (`ScatterChart.tsx:639-641`), read at `:431`,
      // whose activeLegend arm
      // is an emptiness test rather than a null test upstream.
      final noneHighlighted =
          selectedLegends.isEmpty &&
          (activeLegend == null || activeLegend!.isEmpty);
      final selected = highlighted || noneHighlighted;
      final rawColour = series.color ?? FluentDataVizPalette.next(i);
      final colour = colors.flattenMark(rawColour);
      final strokeColour = colors.flattenMarkStroke(rawColour);
      for (var j = 0; j < series.data.length; j++) {
        final point = series.data[j];
        final rawX = context.xScale(point.x);
        final scaledY = context.yScalePrimary(point.y);
        final rawY =
            yAxisType == FluentChartAxisType.category && scaledY != null
            ? scaledY + context.yScalePrimary.bandwidth / 2
            : scaledY;
        if (!isPlottable(rawX, rawY)) {
          continue;
        }
        final isActive = activePointId == '${i}_$j';
        final radius = calculateMarkerRadius(
          pointMarkerSize: point.markerSize,
          minMarkerSize: minSize,
          maxMarkerSize: maxSize,
          extraMaxPixels: extraMaxPixels,
          isContinuousXY: isContinuousXy,
          isActive: isActive,
          defaultRadius: defaultRadius,
          activeRadius: activeRadius,
        );
        // `currentPointHidden` (`ScatterChart.tsx:433`).
        final hidden = series.hideInactiveDots && !isActive;
        marks.add(
          FluentScatterMark(
            centre: Offset(rawX! + xBandwidth, rawY!),
            radius: radius,
            colour: colour,
            strokeColour: strokeColour,
            opacity: selected && !hidden ? fullOpacity : dimOpacity,
            isActive: isActive,
            seriesIndex: i,
            pointIndex: j,
            labelBaselineOffset: radius + labelGap > labelMinGap
                ? radius + labelGap
                : labelMinGap,
            semanticsLabel: _semanticsLabelFor(series, point),
            label: point.text,
          ),
        );
      }
    }
    return marks;
  }

  /// `_getAriaLabel` (`ScatterChart.tsx:647-656`).
  String _semanticsLabelFor(
    FluentScatterChartSeries series,
    FluentScatterChartDataPoint point,
  ) =>
      point.callOutSemantics?.label ??
      '${point.xAxisCalloutData ?? point.x}. ${series.legend}, '
          '${point.yAxisCalloutText ?? point.y}.';

  (double, double) _markerSizeExtent() {
    double? lo;
    double? hi;
    for (final series in _series) {
      for (final point in series.data) {
        final size = point.markerSize;
        if (size == null) {
          continue;
        }
        lo = lo == null || size < lo ? size : lo;
        hi = hi == null || size > hi ? size : hi;
      }
    }
    // `?? 0` reproduces `d3Min(...) ?? 0` at ScatterChart.tsx:377 and :383.
    return (lo ?? 0, hi ?? 0);
  }

  @override
  void paintSeries(
    Canvas canvas,
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
    FluentChartColors colours,
  ) {
    final strokeWidth = style.markerStrokeWidth!.resolve(<WidgetState>{})!;
    final activeFill = style.activeMarkerFillColor!.resolve(<WidgetState>{})!;
    final labelStyle = style.markerLabelStyle!.resolve(<WidgetState>{})!;
    // `marksFor` already walks the series last to first, so grouping and then
    // counting back down reproduces its order exactly — it only makes the
    // series boundary visible, which is where `:496` pushes the ring.
    final marks = <int, List<FluentScatterMark>>{};
    for (final mark in marksFor(context)) {
      (marks[mark.seriesIndex] ??= <FluentScatterMark>[]).add(mark);
    }
    final rings = <int, List<FluentScatterPolarLabel>>{};
    for (final placed in scatterPolarLabelsFor(context)) {
      (rings[placed.seriesIndex] ??= <FluentScatterPolarLabel>[]).add(
        placed.label,
      );
    }
    for (var i = _series.length - 1; i >= 0; i--) {
      for (final mark in marks[i] ?? const <FluentScatterMark>[]) {
        // `_getPointFill` (`ScatterChart.tsx:354-360`) inverts the active
        // marker to the canvas colour rather than growing a ring.
        canvas
          ..drawCircle(
            mark.centre,
            mark.radius,
            Paint()
              ..color = (mark.isActive ? activeFill : mark.colour).withValues(
                alpha: mark.opacity,
              ),
          )
          ..drawCircle(
            mark.centre,
            mark.radius,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..color = mark.strokeColour.withValues(alpha: mark.opacity),
          );
        final label = mark.label;
        if (label == null) {
          continue;
        }
        // `text-anchor: middle` on an alphabetic baseline
        // (`ScatterChart.tsx:481-488`, `Common.styles.ts:72-81`).
        final painter = measurer.layoutPainter(label, labelStyle);
        final metrics = measurer.measure(label, labelStyle);
        painter.paint(
          canvas,
          Offset(
            mark.centre.dx - metrics.width / 2,
            mark.centre.dy + mark.labelBaselineOffset - metrics.ascent,
          ),
        );
        painter.dispose();
      }
      for (final label in rings[i] ?? const <FluentScatterPolarLabel>[]) {
        paintScatterPolarLabel(
          canvas,
          label,
          measurer: measurer,
          style: labelStyle,
        );
      }
    }
  }

  @override
  List<FluentChartHitRegion> buildHitRegions(
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
  ) => <FluentChartHitRegion>[
    for (final mark in marksFor(context))
      FluentChartHitRegion(
        bounds: Rect.fromCircle(center: mark.centre, radius: mark.radius),
        index: mark.pointIndex,
        legend: _series[mark.seriesIndex].legend,
        popoverData: popoverFor(mark),
        semanticsLabel: mark.semanticsLabel,
      ),
  ];

  /// The popover reading for [mark] (`ScatterChart.tsx:686-698`).
  FluentChartPopoverData popoverFor(FluentScatterMark mark) {
    final series = _series[mark.seriesIndex];
    final point = series.data[mark.pointIndex];
    return FluentChartPopoverData(
      xValue: point.xAxisCalloutData ?? '${point.x}',
      // ScatterChart.tsx:695 always sets isCalloutForStack, so the multi-value
      // popover body is used even for a single marker.
      isCalloutForStack: true,
      yValues: <FluentYValueHover>[
        FluentYValueHover(
          legend: series.legend,
          y: point.y is num ? (point.y as num).toDouble() : null,
          color: mark.colour,
          yAxisCalloutText:
              point.yAxisCalloutText ??
              (point.y is String ? point.y as String : null),
          yAxisCalloutBreakdown: point.yAxisCalloutBreakdown,
          index: mark.seriesIndex,
          shape: series.legendShape,
        ),
      ],
    );
  }
}
