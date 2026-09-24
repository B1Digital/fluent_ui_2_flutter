import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import '../l10n/l10n.dart';
import 'axis/axis_builders.dart' as builders;
import 'axis/axis_types.dart';
import 'axis/domain_range.dart';
import 'axis/tick_format.dart';
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
  /// It formats the popover's x reading
  /// (`formatDateToLocaleString(x, props.culture, …)`, `ScatterChart.tsx:535`
  /// and `:568`) and its y readings (`culture: props.culture`, `:696`), and
  /// the delegate hands it to the shell for the x-axis tick labels.
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

  /// `hoverXValue` and `yValueHover` (`ScatterChart.tsx:90-92`): the reading
  /// the callout shows, whichever circle it opens over.
  ///
  /// Upstream keeps it in state that only a hovered circle writes (`:581-584`)
  /// and nothing clears, so a keyboard focus (`:533`) or a pointer that leaves
  /// and comes back shows the last circle hovered.
  ///
  /// Null until a circle is hovered, which hands every region its own
  /// reading. parity: upstream starts from `hoverXValue: ''` and no rows
  /// (`:90`, `:92`), so a focus before any hover opens an empty 34px surface
  /// there; here it opens on the focused circle's reading, and a pointer that
  /// meets a region's square corner before its circle shows no empty card
  /// either.
  FluentChartPopoverData? _reading;

  /// Where d3 last left `#verticalLine`, or null while it is hidden.
  ///
  /// A hovered circle writes `translate(x, yScale(y))` (`ScatterChart.tsx:574`)
  /// and a focused one `translate(x, 0)` (`:541`), so a null `y` is the focus
  /// placement.
  ({Object x, Object? y})? _rule;

  /// The y whose `lineHeight - yScale(y)` is the rule's `y2` (`:576`), or null
  /// before any hover, when `y2` is still the `containerHeight` it renders
  /// with (`:755`).
  ///
  /// d3 writes `y2` on hover only, and React never resets it because the prop
  /// never changes, so a focused rule keeps the last hover's length.
  Object? _ruleLengthY;
  FluentScatterChartDelegate? _delegate;
  late FluentChartTextMeasurer _measurer;

  /// `useUTC` is `string | boolean` upstream and is read as a JS truthy value
  /// (`CartesianChart.types.ts:448`), so an empty string is false.
  bool get _useUtc =>
      widget.props.useUTC == true ||
      (widget.props.useUTC is String && (widget.props.useUTC! as String) != '');

  @override
  void initState() {
    super.initState();
    _measurer = FluentChartTextMeasurer();
  }

  @override
  void dispose() {
    _measurer.invalidate();
    super.dispose();
  }

  /// `_handleFocus` (`ScatterChart.tsx:519-556`), for the circle under the
  /// shell's roving index, or `onBlur` (`:471`) when [index] is null.
  ///
  /// Focus opens the callout: `updatePosition(cx, cy)` (`:533`) sets
  /// `isPopoverOpen` at the circle's centre, which is where the shell puts a
  /// focused region's callout, over [_reading]. When the x has callout points
  /// it shows the rule from the top of the chart (`:540-542`) and grows
  /// nothing, because the `setActivePoint` at `:550` sits in a
  /// `_refArray.forEach` whose array is never pushed to (`:81`); only an x
  /// without callout points grows the circle (`:554`). Blur hides the rule and
  /// nothing else.
  ///
  /// Region i is mark i ([FluentScatterChartDelegate.buildHitRegions]), so the
  /// first stop is the last series' first point, as the circles render from
  /// `:399`. A Tab lands on the plot and an arrow picks a circle.
  void _handleFocusedRegionChange(
    int? index,
    FluentCartesianChildContext context,
  ) {
    final delegate = _delegate;
    if (delegate == null) {
      return;
    }
    if (index == null) {
      if (_rule != null) {
        setState(() => _rule = null);
      }
      return;
    }
    final mark = delegate.marksFor(context)[index];
    final point = _pointOf(mark);
    final found = delegate.popoverFor(mark) != null;
    setState(() {
      if (found) {
        _rule = (x: point.x, y: null);
      } else {
        _activePointId = '${mark.seriesIndex}_${mark.pointIndex}';
      }
    });
  }

  /// `_handleHover` (`ScatterChart.tsx:558-590`), bound to the circle's own
  /// `onMouseMove`/`onMouseOver` (`:445-466`) rather than to the plot, so it
  /// resolves the circle under the pointer first.
  ///
  /// The callout's placement is the shell's: it follows the pointer
  /// ([FluentCartesianChartProps.popoverFollowsPointer]) because
  /// `_uniqueCallOutID` is a `let` in the component body (`:80`), reset on the
  /// render every hover triggers, so `updatePosition` runs on every move
  /// (`:578-580`). What this sets is the rest: the reading, the grown circle
  /// and the rule. Leaving a circle is `_handleMouseOut` (`:606-608`), which
  /// only hides the rule, so the callout keeps the last circle's reading until
  /// the pointer leaves the chart (`:610-616`).
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
      // Nothing but the position changes while the pointer stays on the
      // circle, and the shell moves the callout itself.
      if (id == _activePointId && _rule?.y != null) {
        return;
      }
      final point = _pointOf(mark);
      // `findCalloutPoints` (`:569`): an x whose every point hides its callout
      // grows the circle and nothing else (`:587-588`).
      final reading = delegate.popoverFor(mark);
      setState(() {
        _activePointId = id;
        if (reading != null) {
          _reading = reading;
          _rule = (x: point.x, y: point.y);
          _ruleLengthY = point.y;
        }
      });
      return;
    }
    if (_rule?.y != null) {
      setState(() => _rule = null);
    }
  }

  /// `_handleChartMouseLeave` (`ScatterChart.tsx:610-616`).
  ///
  /// Upstream leaves the rule to the circle's `onMouseOut`, which has always
  /// fired by now; a hovered rule the pointer outran goes here instead. A
  /// focused rule stays, as upstream's does.
  void _handleChartMouseLeave() => setState(() {
    _activePointId = null;
    if (_rule?.y != null) {
      _rule = null;
    }
  });

  FluentScatterChartDataPoint _pointOf(FluentScatterMark mark) =>
      widget.data.scatterChartData![mark.seriesIndex].data[mark.pointIndex];

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
        label: fluentL10n(context).chartNoData,
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
      popoverReading: _reading,
      hoverRule: switch (_rule) {
        final rule? => (x: rule.x, y: rule.y, lengthY: _ruleLengthY),
        null => null,
      },
      xScaleType: widget.props.xScaleType,
      yScaleType: widget.props.yScaleType,
      xMinValue: widget.props.xMinValue,
      xMaxValue: widget.props.xMaxValue,
      yAxisCategoryOrder: widget.props.yAxisCategoryOrder,
      culture: widget.culture,
      useUtc: _useUtc,
    );
    return FluentCartesianChart(
      focusNode: widget.focusNode,
      // parity: ScatterChart.tsx:722 passes the title through UNADORNED — no
      // 'Scatter chart with N series' suffix, unlike Area (`:1012`) and Line
      // (`:1843-1846`). It still has to be handed over explicitly: neither this
      // widget's props nor FluentScatterChartDelegate sets a title otherwise,
      // so the shell would fall all the way through to the generic 'Chart. '
      // prefix in buildFluentCartesianChartDescription.
      props: widget.props.copyWith(
        chartTitleForSemantics: widget.data.chartTitle,
        // `updatePosition(mouseEvent.clientX, clientY)` on every move over a
        // circle (`ScatterChart.tsx:578-580`); see [_handlePointerMove].
        popoverFollowsPointer: true,
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
      delegate: delegate,
      onPointerMoveInPlot: _handlePointerMove,
      onFocusedRegionChange: _handleFocusedRegionChange,
      onChartMouseLeave: _handleChartMouseLeave,
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
    this.popoverReading,
    this.hoverRule,
    this.xScaleType,
    this.yScaleType,
    this.xMinValue,
    this.xMaxValue,
    this.yAxisCategoryOrder,
    this.culture,
    this.useUtc = false,
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

  /// The reading every region's callout shows, or null for each circle's own
  /// [popoverFor].
  ///
  /// Upstream's callout reads chart state, not the circle it opens over
  /// (`ScatterChart.tsx:683-704`), so a chart that has been hovered hands the
  /// last reading to a focused circle too.
  final FluentChartPopoverData? popoverReading;

  /// The dashed rule `#verticalLine` (`ScatterChart.tsx:751-760`), or null
  /// while it is hidden.
  ///
  /// It stands at `xScale(x) + bandwidth / 2` and starts at `yScale(y)`, or at
  /// the top when `y` is null (`:541`, `:574`). It runs `lineHeight -
  /// yScale(lengthY)` down from there (`:576`), or `containerHeight` when
  /// `lengthY` is null (`:755`).
  final ({Object x, Object? y, Object? lengthY})? hoverRule;

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

  /// BCP-47 locale for the popover's readings (`props.culture`).
  ///
  /// Overrides the base getter, so the shell formats this chart's tick labels
  /// with it too: `ScatterChart.tsx:721` spreads `props` into `CartesianChart`,
  /// which hands `culture` to the x axis builders (`CartesianChart.tsx:237-277`).
  @override
  final String? culture;

  /// Whether a date reading is formatted in UTC (`props.useUTC`).
  final bool useUtc;

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
    // The rule's `<line>` comes before the series `<g>` (`ScatterChart.tsx:750-
    // 761`), so the circles paint over it.
    _paintHoverRule(canvas, context, layout);
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

  /// Paints [hoverRule]: `stroke="#323130"`, `strokeDasharray="5,5"` and the
  /// SVG default width of 1 (`ScatterChart.tsx:751-760`).
  void _paintHoverRule(
    Canvas canvas,
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
  ) {
    final rule = hoverRule;
    if (rule == null) {
      return;
    }
    const states = <WidgetState>{};
    final xBandwidth = xAxisType == FluentChartAxisType.category
        ? context.xScale.bandwidth / 2
        : 0.0;
    final x = context.xScale(rule.x);
    // `_yAxisScale(y)` with no half band (`:574`), unlike the circle's own
    // centre at `:410-412`.
    final y = rule.y;
    final top = y == null ? 0.0 : context.yScalePrimary(y);
    // `verticaLineHeight` (`:404`): 6px past the x axis.
    final lineHeight =
        context.containerHeight - (layout.margins.bottom ?? 0) + 6;
    final lengthY = rule.lengthY;
    final length = lengthY == null
        ? context.containerHeight
        : lineHeight - (context.yScalePrimary(lengthY) ?? double.nan);
    if (x == null || top == null || !(x + top + length).isFinite) {
      return;
    }
    final paint = Paint()
      ..color = style.hoverLineColor!.resolve(states)!
      ..strokeWidth = style.hoverLineWidth!.resolve(states)!;
    final from = Offset(x + xBandwidth, top);
    final to = from.translate(0, length);
    final dashes = style.hoverLineDashPattern!.resolve(states) ?? <double>[];
    if (dashes.fold<double>(0, (sum, run) => sum + run) <= 0) {
      canvas.drawLine(from, to, paint);
      return;
    }
    // SVG starts the dash at the line's own start, `y1 = 0`, and a negative
    // `y2` runs it upwards.
    final direction = length.sign;
    var travelled = 0.0;
    for (var i = 0; travelled < length.abs(); i++) {
      final run = math.min(dashes[i % dashes.length], length.abs() - travelled);
      if (i.isEven) {
        canvas.drawLine(
          from.translate(0, direction * travelled),
          from.translate(0, direction * (travelled + run)),
          paint,
        );
      }
      travelled += run;
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
        popoverData: popoverReading ?? popoverFor(mark) ?? _emptyReading,
        semanticsLabel: mark.semanticsLabel,
        // `_getClickHandler(onDataPointClick)` (`ScatterChart.tsx:472`).
        onActivate:
            _series[mark.seriesIndex].data[mark.pointIndex].onDataPointClick,
      ),
  ];

  /// `hoverXValue: ''` and `yValueHover: []` (`ScatterChart.tsx:90-92`), the
  /// callout before any circle has written it.
  ///
  /// ponytail: only reached by a circle whose x hides every callout point
  /// before any other circle has been hovered, where upstream opens nothing.
  static const FluentChartPopoverData _emptyReading = FluentChartPopoverData(
    isCalloutForStack: true,
  );

  /// The callout reading for [mark] (`ScatterChart.tsx:568-586`, read at
  /// `:683-704`), or null when no point at its x shows a callout.
  ///
  /// The rows are `findCalloutPoints(calloutPointsRef.current, x).values`
  /// (`:569`): every series' point at the hovered x, not the hovered point
  /// alone, which is two rows on the string and date stories.
  FluentChartPopoverData? popoverFor(FluentScatterMark mark) {
    final point = _series[mark.seriesIndex].data[mark.pointIndex];
    // `calloutData(pointsRef.current)` (`:144`), over every series whatever
    // the legend selection, because `selectedLegendPoints` is never set
    // (`:94`, `:249`).
    final rows = findCalloutPoints(
      calloutData(<FluentLineChartSeries>[
        for (final series in _series)
          FluentLineChartSeries(legend: series.legend, data: series.data),
      ]),
      point.x,
      isXAxisDate: point.x is DateTime,
    );
    if (rows == null) {
      return null;
    }
    return FluentChartPopoverData(
      // `xAxisCalloutData ? … : '' + formattedData` (`:581`), a date going
      // through `formatDateToLocaleString(x, props.culture, props.useUTC)`
      // (`:568`), then `ChartPopover.tsx:128` formats the reading once more,
      // which is what groups a numeric x.
      xValue:
          point.xAxisCalloutData ??
          formatToLocaleString(point.x, culture: culture, useUtc: useUtc),
      // ScatterChart.tsx:695 always sets isCalloutForStack, so the multi-value
      // popover body is used even for a single marker.
      isCalloutForStack: true,
      culture: culture,
      yValues: <FluentYValueHover>[
        for (final row in rows)
          FluentYValueHover(
            legend: row.legend,
            // `calloutData` carries a category y as NaN beside its text.
            y: row.y.isNaN ? null : row.y,
            // The series colour `_injectIndexPropertyInScatterChartData`
            // resolves (`:153-158`), as the circle is painted.
            color: colors.flattenMark(
              _series[row.index!].color ??
                  FluentDataVizPalette.next(row.index!),
            ),
            yAxisCalloutText: row.yAxisCalloutText,
            yAxisCalloutBreakdown: row.yAxisCalloutBreakdown,
            // `_injectIndexPropertyInScatterChartData` sets `index: -1` on
            // every series (`:161`), so ChartPopover.tsx:188 draws the 4px
            // accent bar rather than a legend shape.
            index: -1,
          ),
      ],
    );
  }
}
