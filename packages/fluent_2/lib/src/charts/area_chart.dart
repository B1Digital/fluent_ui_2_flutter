import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import 'area_chart_style.dart';
import 'axis/axis_builders.dart' as axis;
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
import 'internal/chart_utils.dart';
import 'internal/d3/array_stats.dart' as d3;
import 'internal/d3/curves.dart' as d3;
import 'internal/d3/path_sink.dart' as d3;
import 'internal/d3/scale.dart' as d3;
import 'internal/d3/shape_line_area.dart' as d3;
import 'internal/d3/shape_stack.dart' as d3;
import 'internal/data_viz_palette.dart';
import 'model/callout_data.dart';
import 'model/cartesian_series.dart';
import 'model/chart_common.dart';
import 'model/chart_value.dart';

/// A Fluent 2 stacked area chart.
///
/// Ports `AreaChart.tsx`. Hover selection follows upstream exactly: the pointer
/// x is inverted through the x scale, a bisector runs over **series 0 only**
/// (`AreaChart.tsx:194`) and the winner is chosen by absolute distance. Any
/// move over the plot does this, not only a move over a mark, and the callout
/// opens at the pointer (`:185-277`).
class FluentAreaChart extends StatefulWidget {
  /// Creates an area chart over [data].
  const FluentAreaChart({
    super.key,
    required this.data,
    this.props = const FluentCartesianChartProps(),
    this.mode = FluentAreaChartMode.toNextY,
    this.enableGradient = false,
    this.culture,
    this.style,
    this.legendSelectionMode = FluentChartLegendSelectionMode.single,
    this.selectedLegends,
    this.onLegendChange,
    this.focusNode,
  });

  /// The data bundle. Only [FluentChartData.lineChartData],
  /// [FluentChartData.markerRadius] and [FluentChartData.chartTitle] are read.
  final FluentChartData data;

  /// Shell configuration.
  final FluentCartesianChartProps props;

  /// Baseline mode, default `toNextY` (`AreaChart.types.ts:68`).
  final FluentAreaChartMode mode;

  /// Whether the fill fades to transparent downwards (`AreaChart.types.ts:63`).
  final bool enableGradient;

  /// BCP-47 locale for popover formatting.
  final String? culture;

  /// Style override, highest precedence.
  final FluentAreaChartStyle? style;

  /// Whether the legend allows more than one selection.
  final FluentChartLegendSelectionMode legendSelectionMode;

  /// The legend titles the chart's owner has selected — `legendProps
  /// .selectedLegends` (`AreaChart.tsx:121`), spelled as a parameter because
  /// [FluentCartesianChartProps] carries no legend bag.
  ///
  /// Null is "the caller said nothing": the legend row runs uncontrolled and
  /// the stack keeps its `renderPoints.length > 1` multi-stack test. A list —
  /// **empty included** — is a caller that owns the selection, and it flips
  /// that test to `>= 1`, which is exactly what upstream's truthiness check on
  /// the array does at `AreaChart.tsx:328-330`.
  ///
  /// The value seeds this widget's own selection (`:121`) and is re-read
  /// whenever it changes (`:141-142`), which is what dims every unselected
  /// series and fills only the selected legend's swatch.
  final List<String>? selectedLegends;

  /// Called with the new selection when a legend row is clicked — upstream's
  /// `legendProps.onChange` (`AreaChart.tsx:608`), which is what lets an owner
  /// that passes [selectedLegends] echo the click back instead of fighting it.
  ///
  /// Without it a controlled owner — `FluentDeclarativeChart`, which feeds
  /// `selectedLegends` from the schema — never learns the selection moved, so
  /// its `onSchemaChange` never fires and the next rebuild snaps the chart back
  /// to the stale schema selection.
  final void Function(List<String> selected)? onLegendChange;

  /// The chart's single focus node.
  final FocusNode? focusNode;

  @override
  State<FluentAreaChart> createState() => FluentAreaChartState();
}

/// State for [FluentAreaChart]. Public only so widget tests can reach the
/// hover helpers, which is the same shape `FluentSliderState` uses.
class FluentAreaChartState extends State<FluentAreaChart> {
  List<String> _selectedLegends = const <String>[];
  String? _activeLegend;
  String? _activePointId;
  Object? _nearestX;
  bool _isCircleClicked = false;
  bool _isPopoverOpen = false;

  /// Whether the shell's roving keyboard index is on a stop, which moves the
  /// popover from the pointer to the focused circle.
  bool _keyboardFocused = false;
  late final FluentChartTextMeasurer _measurer = FluentChartTextMeasurer();

  List<FluentLineChartSeries> get _series =>
      widget.data.lineChartData ?? const <FluentLineChartSeries>[];

  /// The x value nearest the pointer, currently highlighted.
  Object? get nearestX => _nearestX;

  /// `useUTC` is `string | boolean` upstream and is read as a JS truthy value
  /// (`CartesianChart.types.ts:448`), so an empty string is false.
  bool get _useUtc =>
      widget.props.useUTC == true ||
      (widget.props.useUTC is String && (widget.props.useUTC! as String) != '');

  late FluentAreaChartDataSet _dataSet;

  @override
  void initState() {
    super.initState();
    // `AreaChart.tsx:121`.
    _selectedLegends = widget.selectedLegends ?? const <String>[];
    _rebuildDataSet();
  }

  @override
  void didUpdateWidget(FluentAreaChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // `:139-143`: the effect compares the two arrays, so a new list holding the
    // same titles does not discard a selection the user has since changed.
    final selectionChanged = !areArraysEqual(
      oldWidget.selectedLegends,
      widget.selectedLegends,
    );
    if (selectionChanged) {
      _selectedLegends = widget.selectedLegends ?? const <String>[];
    }
    if (selectionChanged ||
        oldWidget.data != widget.data ||
        oldWidget.mode != widget.mode ||
        (oldWidget.props.secondaryYScaleOptions == null) !=
            (widget.props.secondaryYScaleOptions == null)) {
      _rebuildDataSet();
    }
  }

  void _rebuildDataSet() {
    _dataSet = buildFluentAreaChartDataSet(
      series: _series,
      mode: widget.mode,
      hasSecondaryYScale: widget.props.secondaryYScaleOptions != null,
      // The WIDGET's list, not this State's: `AreaChart.tsx:328` reads
      // `props.legendProps?.selectedLegends` and tests the array's presence,
      // never its length, so a selection the user makes by clicking does not
      // move this flag and an empty list from the owner does.
      hasSelectedLegends: widget.selectedLegends != null,
    );
  }

  @override
  void dispose() {
    _measurer.invalidate();
    super.dispose();
  }

  /// The index in series 0 nearest an inverted x value.
  ///
  /// Ports the bisect-plus-distance tie-break at `AreaChart.tsx:194-215`.
  int nearestIndexForInverted(num invertedX) {
    final data = _series.first.data.cast<FluentLineChartDataPoint>();
    final i = d3
        .bisector<FluentLineChartDataPoint>(
          (d) => _xOrder(d.x) as Comparable<Object>,
        )
        .left(data, invertedX);
    if (i <= 0) {
      return 0;
    }
    if (i >= data.length) {
      return data.length - 1;
    }
    final d0 = _xOrder(data[i - 1].x);
    final d1 = _xOrder(data[i].x);
    // `x - d0.x > d1.x - x ? d1 : d0` — the tie keeps d0.
    return (invertedX - d0) > (d1 - invertedX) ? i : i - 1;
  }

  /// The x value nearest an inverted pointer position.
  Object nearestXValueForInverted(num invertedX) =>
      (_series.first.data[nearestIndexForInverted(invertedX)]
              as FluentLineChartDataPoint)
          .x;

  void _handlePointerMove(Offset local, FluentCartesianChildContext context) {
    final inverted = context.xScale.invert(local.dx);
    if (inverted == null || _series.isEmpty || _series.first.data.isEmpty) {
      return;
    }
    // The plot `<rect>` that listens has no `x`: it runs from the chart's left
    // edge to the last tick (`AreaChart.tsx:1127-1141`), the largest x left to
    // right and the smallest right to left, so right of the rightmost x
    // nothing hears the move, which is where the delegate's hover bands stop
    // too.
    // ponytail: upstream's rect ends at the extreme *tick* and the area paths
    // carry the listener on to the x itself; the two only differ when a date or
    // numeric domain does not end on a tick.
    final first = context.xScale(_dataSet.rows.first.xValue)!;
    final last = context.xScale(_dataSet.rows.last.xValue)!;
    if (local.dx > math.max(first, last)) {
      return;
    }
    final candidate = nearestXValueForInverted(_xOrder(inverted));
    final found = findCalloutPoints(
      _dataSet.calloutPoints,
      candidate,
      isXAxisDate: candidate is DateTime,
    );
    setState(() {
      if (found == null || found.isEmpty) {
        _isPopoverOpen = false;
        _nearestX = null;
        return;
      }
      _nearestX = candidate;
      _isCircleClicked = false;
      _activePointId = null;
      // `_updatePosition` opens it on every move (`AreaChart.tsx:275`), and
      // `_getLineOpacity` reads that state as it is (`:633`). Duplicate or
      // missing x values only gate what reaches the callout (`:1093`), which
      // `build` does through an empty `popoverBuilder`.
      _isPopoverOpen = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final style = resolveFluentAreaChartStyle(
      theme,
    ).merge(FluentAreaChartTheme.maybeOf(context)).merge(widget.style);
    return FluentCartesianChart(
      focusNode: widget.focusNode,
      legendSelectionMode: widget.legendSelectionMode,
      props: widget.props.copyWith(
        chartTitleForSemantics: widget.data.chartTitle == null
            ? null
            // `${chartTitle}. Area chart with ${n} data series. ` (`:1012`).
            : '${widget.data.chartTitle}. Area chart with '
                  '${_series.length} data series. ',
        // The delegate's regions are one hover band per x plus the circles a
        // click lands on; grouping merges them into one stop per x.
        hitRegionGranularity: FluentChartHitGranularity.group,
        // `_updatePosition` re-anchors on every move (`:267-277`).
        // ponytail: its 1px dead zone is not reproduced.
        popoverFollowsPointer: true,
        // `isPopoverOpen && !_hasDuplicateXValues && !_hasMissingXValues`
        // (`:1093`) closes the callout, custom body included, for good. An
        // empty body is how the shell is told, as ScatterChart does.
        popoverBuilder:
            _dataSet.hasDuplicateXValues || _dataSet.hasMissingXValues
            ? (context) => const SizedBox.shrink()
            : null,
      ),
      legends: <FluentChartLegendItem>[
        for (var i = 0; i < _series.length; i++)
          FluentChartLegendItem(
            title: _series[i].legend,
            color: _dataSet.colours[i],
            shape: _series[i].legendShape,
            onHoverAction: () => setState(() {
              _nearestX = null;
              _isPopoverOpen = false;
              _activeLegend = _series[i].legend;
            }),
            onMouseOutAction: ({required bool isLegendFocused}) =>
                setState(() => _activeLegend = null),
          ),
      ],
      // `:589`'s spread controls the row from `props.legendProps
      // .selectedLegends`, and upstream can afford that because `:608` echoes
      // every click back to the owner, which re-sends the prop. An owner that
      // ignores [FluentAreaChart.onLegendChange] would freeze the row if it
      // were controlled by the prop alone, so the row is controlled by this
      // State instead: seeded from the prop and re-seeded when it changes, the
      // first frame is identical and the click behaves as upstream's echo makes
      // it behave whether or not the owner is listening.
      selectedLegends: _selectedLegends,
      onLegendChange: (selected) {
        // `_onLegendSelectionChange` (`:597-609`) only moves this state;
        // `_isMultiStackChart` is read off the prop, so the dataset stands.
        setState(() => _selectedLegends = selected);
        // `:608`'s echo. Report after the local move, so an owner that
        // re-sends the same list through `selectedLegends` is a no-op rather
        // than a second rebuild.
        widget.onLegendChange?.call(selected);
      },
      delegate: FluentAreaChartDelegate(
        series: _series,
        dataSet: _dataSet,
        style: style,
        colors: FluentChartColors.of(theme),
        measurer: _measurer,
        selectedLegends: _selectedLegends,
        activeLegend: _activeLegend,
        activePointId: _activePointId,
        nearestX: _nearestX,
        isCircleClicked: _isCircleClicked,
        isPopoverOpen: _isPopoverOpen,
        mode: widget.mode,
        enableGradient: widget.enableGradient,
        markerRadius: widget.data.markerRadius,
        xScaleType: widget.props.xScaleType,
        yScaleType: widget.props.yScaleType,
        xMinValue: widget.props.xMinValue,
        xMaxValue: widget.props.xMaxValue,
        culture: widget.culture,
        useUtc: _useUtc,
        keyboardFocused: _keyboardFocused,
      ),
      onPointerMoveInPlot: _handlePointerMove,
      // `_handleFocus` (`AreaChart.tsx:939-968`) grows the focused circle
      // through `activePoint` and opens the callout; `_handleBlur` (`:977-984`)
      // undoes both. The stop is the top layer's circle at that x.
      onFocusedRegionChange: (index, _) => setState(() {
        _keyboardFocused = index != null;
        _activePointId = index == null ? null : '${_series.length - 1}_$index';
        _isPopoverOpen = index != null;
      }),
      onChartMouseLeave: () => setState(() {
        // `_handleChartMouseLeave` resets everything (`:279-289`).
        _nearestX = null;
        _activePointId = null;
        _isPopoverOpen = false;
      }),
    );
  }
}

/// How an area layer's baseline is chosen.
enum FluentAreaChartMode {
  /// Every layer sits on zero (`AreaChart.tsx:296-310`).
  toZeroY,

  /// Layers stack on one another via `d3.stack` — the default (`:312-320`).
  toNextY,
}

/// One row of the reshaped dataset: an x value with one y per series.
@immutable
class FluentAreaChartRow {
  /// Creates a row.
  const FluentAreaChartRow({required this.xValue, required this.values});

  /// The shared x value. Dates are compared by their epoch milliseconds, which
  /// is the Dart equivalent of upstream's `toLocaleString()` key (`:358`).
  final Object xValue;

  /// One y per series, indexed by series position.
  final List<double> values;
}

/// The output of AreaChart's data pipeline.
@immutable
class FluentAreaChartDataSet {
  /// Creates a dataset.
  const FluentAreaChartDataSet({
    required this.rows,
    required this.layers,
    required this.colours,
    required this.opacities,
    required this.maxOfYVal,
    required this.isMultiStack,
    required this.hasDuplicateXValues,
    required this.hasMissingXValues,
    required this.calloutPoints,
    this.fillsToZero = false,
  });

  /// Whether every layer sits on zero rather than on the one below it —
  /// `_shouldFillToZeroY()` (`AreaChart.tsx:1065-1067`): tozeroy mode, or a
  /// secondary y axis, which forces it.
  final bool fillsToZero;

  /// One row per distinct x, ascending.
  final List<FluentAreaChartRow> rows;

  /// One layer per series; each entry is the `(lo, hi)` pair for a row.
  final List<List<d3.StackPoint>> layers;

  /// Resolved colour per series.
  final List<Color> colours;

  /// Resolved opacity per series — `singleChartPoint.opacity || 1` (`:352`).
  final List<double> opacities;

  /// The y-axis ceiling handed to the shell.
  final double maxOfYVal;

  /// Whether the multi-stack opacity table applies (`:328-330`).
  final bool isMultiStack;

  /// Whether any series repeats an x value; suppresses the popover (`:1093`).
  final bool hasDuplicateXValues;

  /// Whether the series disagree on their x sets; suppresses the popover and
  /// the click handlers (`:846-853`).
  final bool hasMissingXValues;

  /// The deduplicated hover index built by [calloutData].
  final List<FluentCustomizedCalloutData> calloutPoints;
}

/// Ports `_addDefaultColors` (`AreaChart.tsx:891-937`), `_createDataSet`
/// (`:340-467`) and `_getDataPoints` (`:292-338`) as one pure function.
///
/// Upstream mutates the caller's data when back-filling missing x values
/// (`:909-921`): it pushes a `y: 0` point for every x the series is missing and
/// re-sorts. This port keys the rows by x instead and reads a missing y as 0,
/// which produces the same rows in the same ascending order without copying or
/// mutating the caller's series. Recorded divergence.
///
/// [hasSecondaryYScale] is whether `secondaryYScaleOptions` was given; the
/// layers only fill to zero once a series is also plotted against it.
FluentAreaChartDataSet buildFluentAreaChartDataSet({
  required List<FluentLineChartSeries> series,
  required FluentAreaChartMode mode,
  required bool hasSecondaryYScale,
  required bool hasSelectedLegends,
}) {
  var hasDuplicates = false;
  final keysPerSeries = <Set<Object>>[];
  // One key-to-y map per series. A repeated x keeps the FIRST point's y, which
  // is what upstream's `filter(...)[0]` reads at `:428-437`.
  final yPerSeries = <Map<Object, double>>[];
  final keyToX = <Object, Object>{};
  for (final s in series) {
    final keys = <Object>{};
    final ys = <Object, double>{};
    for (final datum in s.data.cast<FluentLineChartDataPoint>()) {
      final key = _xKey(datum.x);
      if (!keys.add(key)) {
        hasDuplicates = true;
      }
      ys.putIfAbsent(key, () => datum.y);
      keyToX[key] = datum.x;
    }
    keysPerSeries.add(keys);
    yPerSeries.add(ys);
  }

  final union = <Object>{for (final keys in keysPerSeries) ...keys};
  // `:1049-1060` — a series is missing an x as soon as it does not carry every
  // x in the union.
  final hasMissing = keysPerSeries.any((keys) => keys.length != union.length);

  final orderedKeys = union.toList(growable: false)
    ..sort((a, b) => _xOrder(keyToX[a]!).compareTo(_xOrder(keyToX[b]!)));
  final rows = <FluentAreaChartRow>[
    for (final key in orderedKeys)
      FluentAreaChartRow(
        xValue: keyToX[key]!,
        values: <double>[for (final ys in yPerSeries) ys[key] ?? 0],
      ),
  ];

  // `_containsSecondaryYAxis` (`:1072`): the options alone are not enough, a
  // series must also be plotted against them.
  final containsSecondaryYAxis =
      hasSecondaryYScale && series.any((s) => s.useSecondaryYScale);
  // `mode === 'tozeroy' || _shouldFillToZeroY()` (`:296`, `:1065-1067`).
  final toZero = mode == FluentAreaChartMode.toZeroY || containsSecondaryYAxis;
  final List<List<d3.StackPoint>> layers;
  double maxOfYVal;
  if (toZero) {
    layers = <List<d3.StackPoint>>[
      for (var i = 0; i < series.length; i++)
        <d3.StackPoint>[for (final r in rows) d3.StackPoint(0, r.values[i], r)],
    ];
    maxOfYVal = rows.isEmpty || series.isEmpty
        ? 0
        : rows.expand((r) => r.values).reduce((a, b) => a > b ? a : b);
  } else {
    layers = d3.stack(rows, <String>[
      for (var i = 0; i < series.length; i++) '$i',
    ], value: (d, key) => (d as FluentAreaChartRow).values[int.parse(key)]);
    maxOfYVal = layers.isEmpty || layers.last.isEmpty
        ? 0
        : layers.last.map((p) => p.hi).reduce((a, b) => a > b ? a : b);
  }
  if (containsSecondaryYAxis) {
    // `:336` — the ceiling is the primary axis's alone, so it is taken over
    // the primary series only (`findNumericMinMaxOfY` keeps
    // `!useSecondaryYScale`, `utilities.ts:1599`). With no primary series it
    // is `undefined`, which `createNumericYAxis` defaults to 0
    // (`utilities.ts:809`).
    final primaryMax = findNumericMinMaxOfY(series).endValue;
    maxOfYVal = primaryMax.isNaN ? 0 : primaryMax;
  }

  return FluentAreaChartDataSet(
    rows: rows,
    layers: layers,
    colours: <Color>[
      for (var i = 0; i < series.length; i++)
        series[i].color ?? FluentDataVizPalette.next(i),
    ],
    opacities: <double>[
      // parity: `singleChartPoint.opacity || 1` (`:352`) swallows a real 0.
      for (final s in series)
        (s.opacity == null || s.opacity == 0) ? 1 : s.opacity!,
    ],
    maxOfYVal: maxOfYVal,
    // `selectedLegends ? layers.length >= 1 : layers.length > 1` (`:328-330`).
    isMultiStack: hasSelectedLegends ? layers.isNotEmpty : layers.length > 1,
    hasDuplicateXValues: hasDuplicates,
    hasMissingXValues: hasMissing,
    calloutPoints: calloutData(series),
    fillsToZero: toZero,
  );
}

/// The map key an x value is grouped by (`AreaChart.tsx:358`).
Object _xKey(Object x) => x is DateTime ? x.millisecondsSinceEpoch : x;

/// The sort key an x value is ordered by (`AreaChart.tsx:918-919`).
num _xOrder(Object x) => x is DateTime ? x.millisecondsSinceEpoch : x as num;

/// One resolved area layer.
@immutable
class FluentAreaChartLayer {
  /// Creates a layer.
  const FluentAreaChartLayer({
    required this.index,
    required this.areaPath,
    required this.linePath,
    required this.colour,
    required this.strokeColour,
    required this.layerOpacity,
    required this.fillOpacity,
    required this.lineOpacity,
    this.singlePointCentre,
  });

  /// Index of the owning series.
  final int index;

  /// The filled body. Empty when [singlePointCentre] is set.
  final Path areaPath;

  /// The top edge, stroked separately so it can carry its own opacity.
  final Path linePath;

  /// Resolved series colour, flattened through
  /// [FluentChartColors.flattenMark].
  final Color colour;

  /// The same series colour flattened through
  /// [FluentChartColors.flattenMarkStroke] instead.
  ///
  /// Outside forced colours this equals [colour]. Inside it, sending the top
  /// edge to `Canvas` rather than `CanvasText` is the only thing that keeps two
  /// stacked areas — both flattened to `CanvasText` — from merging into one
  /// indistinguishable block (design spec section 5.3).
  final Color strokeColour;

  /// Whole-layer opacity — 0.8 once the layers fill to zero, whether by mode or
  /// by a secondary axis, else the series opacity (`AreaChart.tsx:685`).
  final double layerOpacity;

  /// Fill opacity from `_getOpacity` (`AreaChart.tsx:619-626`).
  final double fillOpacity;

  /// Stroke opacity from `_getLineOpacity` (`AreaChart.tsx:628-641`).
  final double lineOpacity;

  /// When the layer holds exactly one datum, upstream paints a circle instead
  /// of a path (`AreaChart.tsx:711-725`); this is its centre.
  final Offset? singlePointCentre;
}

/// Renders stacked areas into the shared cartesian shell.
///
/// Ports `AreaChart.tsx` (1155 lines).
class FluentAreaChartDelegate extends FluentCartesianSeriesDelegate {
  /// Creates a delegate.
  const FluentAreaChartDelegate({
    required this.series,
    required this.dataSet,
    required this.style,
    required this.colors,
    required this.measurer,
    required this.selectedLegends,
    this.activeLegend,
    this.activePointId,
    this.nearestX,
    this.isCircleClicked = false,
    this.isPopoverOpen = false,
    this.mode = FluentAreaChartMode.toNextY,
    this.enableGradient = false,
    this.markerRadius,
    this.xScaleType,
    this.yScaleType,
    this.xMinValue,
    this.xMaxValue,
    this.culture,
    this.useUtc = false,
    this.keyboardFocused = false,
  });

  /// The input series.
  final List<FluentLineChartSeries> series;

  /// The reshaped dataset from [buildFluentAreaChartDataSet].
  final FluentAreaChartDataSet dataSet;

  /// The resolved style.
  final FluentAreaChartStyle style;

  /// Resolved chart colours.
  final FluentChartColors colors;

  /// The chart subtree's single text measurer.
  final FluentChartTextMeasurer measurer;

  /// Legend titles selected by the user.
  final List<String> selectedLegends;

  /// Legend title currently hovered.
  final String? activeLegend;

  /// Identifier of the focused circle, spelled `layerIndex_pointIndex`.
  final String? activePointId;

  /// The x value nearest the pointer, if any.
  final Object? nearestX;

  /// Whether the highlighted circle has been clicked, shrinking it to 1.
  final bool isCircleClicked;

  /// Whether the popover is open, which lifts a multi-stack line to 1.
  final bool isPopoverOpen;

  /// Baseline mode.
  final FluentAreaChartMode mode;

  /// Whether the fill fades to transparent downwards
  /// (`AreaChart.tsx:688-695`).
  final bool enableGradient;

  /// `pointOptions.r`, default 8 (`AreaChart.tsx:749`).
  final double? markerRadius;

  /// Optional log scaling on x.
  final FluentAxisScaleType? xScaleType;

  /// Optional log scaling on y.
  final FluentAxisScaleType? yScaleType;

  /// User-supplied x domain floor.
  final double? xMinValue;

  /// User-supplied x domain ceiling.
  final double? xMaxValue;

  /// BCP-47 locale for the popover's readings (`props.culture`).
  ///
  /// Overrides the base getter, so the shell formats this chart's tick labels
  /// with it too: `AreaChart.tsx:1105` spreads `props` into `CartesianChart`,
  /// which hands `culture` to the x axis builders (`CartesianChart.tsx:237-277`).
  @override
  final String? culture;

  /// Whether a date reading is formatted in UTC (`props.useUTC`).
  final bool useUtc;

  /// Whether the keyboard is on one of the chart's stops, which anchors the
  /// popover to the top circle at that x — `_handleFocus` positions it at the
  /// focused circle (`AreaChart.tsx:948-951`) — rather than to the pointer.
  final bool keyboardFocused;

  @override
  FluentChartType get chartType => FluentChartType.areaChart;

  @override
  FluentChartAxisType get xAxisType =>
      // `getXAxisType` reproduces the non-breaking forEach: the LAST non-empty
      // series wins (`utilities.ts:1330-1341`).
      getXAxisType(series)
      ? FluentChartAxisType.date
      : FluentChartAxisType.numeric;

  @override
  FluentChartAxisType get yAxisType => FluentChartAxisType.numeric;

  /// The curve every layer is drawn with.
  ///
  /// parity: `AreaChart.tsx:7` imports `curveMonotoneX` under the alias
  /// `d3CurveBasis`, so the AreaChart default is monotone-cubic, NOT linear and
  /// NOT a basis spline.
  d3.D3CurveFactory get curveFactory => getCurveFactory(
    series.isEmpty ? null : series.first.lineOptions?.curve,
    d3.curveMonotoneX,
  );

  bool get _noneHighlighted =>
      selectedLegends.isEmpty && (activeLegend?.isEmpty ?? true);

  bool _highlighted(String legend) => isLegendHighlightedMulti(
    legend,
    selectedLegends: selectedLegends,
    activeLegend: activeLegend,
  );

  /// Ports `_getOpacity` (`AreaChart.tsx:619-626`).
  double fillOpacityFor(String legend) {
    final base = style.areaOpacity!.resolve(<WidgetState>{})!;
    if (!dataSet.isMultiStack) {
      return base;
    }
    return _highlighted(legend) || _noneHighlighted
        ? base
        : style.areaOpacity!.resolve(<WidgetState>{WidgetState.disabled})!;
  }

  /// Ports `_getLineOpacity` (`AreaChart.tsx:628-641`).
  ///
  /// Note the highlighted branch returns **0**: upstream deliberately hides the
  /// stroke and lets the fill carry the highlight.
  double lineOpacityFor(String legend) {
    if (!dataSet.isMultiStack) {
      // AreaChart.tsx:630.
      return 1;
    }
    // AreaChart.tsx:632.
    var opacity = style.lineOpacityMultiStack!.resolve(<WidgetState>{})!;
    if (isPopoverOpen) {
      // AreaChart.tsx:634.
      opacity = style.lineOpacityMultiStack!.resolve(<WidgetState>{
        WidgetState.selected,
      })!;
    }
    if (!_noneHighlighted) {
      // AreaChart.tsx:637.
      opacity = style.lineOpacityMultiStack!.resolve(<WidgetState>{
        _highlighted(legend) ? WidgetState.hovered : WidgetState.disabled,
      })!;
    }
    return opacity;
  }

  /// Ports `_getCircleRadius` (`AreaChart.tsx:855-868`).
  double circleRadiusFor(int layerIndex, int pointIndex) {
    final legend = series[layerIndex].legend;
    if (!_noneHighlighted && !_highlighted(legend)) {
      return 0;
    }
    final rowX = dataSet.rows[pointIndex].xValue;
    final isNearest = nearestX != null && _xKey(nearestX!) == _xKey(rowX);
    if (isCircleClicked && isNearest) {
      return style.clickedPointRadius!.resolve(<WidgetState>{})!;
    }
    if (isNearest || activePointId == '${layerIndex}_$pointIndex') {
      return markerRadius ?? style.pointRadius!.resolve(<WidgetState>{})!;
    }
    return 0;
  }

  /// The y scale layer [index] is plotted against (`AreaChart.tsx:667`).
  d3.Scale _yScaleFor(int index, FluentCartesianChildContext context) =>
      series[index].useSecondaryYScale && context.yScaleSecondary != null
      ? context.yScaleSecondary!
      : context.yScalePrimary;

  /// Resolves every layer for [context].
  List<FluentAreaChartLayer> layersFor(FluentCartesianChildContext context) {
    final curve = curveFactory;
    final out = <FluentAreaChartLayer>[];
    for (var i = 0; i < dataSet.layers.length; i++) {
      final layer = dataSet.layers[i];
      final yScale = _yScaleFor(i, context);
      double xOf(d3.StackPoint _, int j, List<d3.StackPoint> _) =>
          context.xScale(dataSet.rows[j].xValue)!;
      final Path areaPath;
      final Offset? singleCentre;
      if (layer.length == 1) {
        areaPath = Path();
        singleCentre = Offset(
          context.xScale(dataSet.rows.first.xValue)!,
          yScale(layer.first.hi)!,
        );
      } else {
        final areaSink = d3.UiPathSink();
        d3.Area<d3.StackPoint>(
          x0: xOf,
          y0: (p, _, _) => yScale(p.lo)!,
          y1: (p, _, _) => yScale(p.hi)!,
          curve: curve,
        )(layer, areaSink);
        areaPath = areaSink.path;
        singleCentre = null;
      }
      final lineSink = d3.UiPathSink();
      d3.Line<d3.StackPoint>(
        x: xOf,
        y: (p, _, _) => yScale(p.hi)!,
        curve: curve,
      )(layer, lineSink);

      out.add(
        FluentAreaChartLayer(
          index: i,
          areaPath: areaPath,
          linePath: lineSink.path,
          colour: colors.flattenMark(dataSet.colours[i]),
          strokeColour: colors.flattenMarkStroke(dataSet.colours[i]),
          // `_shouldFillToZeroY() ? 0.8 : _opacity[index]` (`:685`).
          layerOpacity: dataSet.fillsToZero
              ? style.areaOpacityToZeroY!.resolve(<WidgetState>{})!
              : dataSet.opacities[i],
          fillOpacity: fillOpacityFor(series[i].legend),
          lineOpacity: lineOpacityFor(series[i].legend),
          singlePointCentre: singleCentre,
        ),
      );
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
  }) => xAxisType == FluentChartAxisType.date
      ? domainRangeOfDateForAreaLineScatterVerticalBarCharts(
          series,
          margins,
          containerWidth,
          isRtl: isRtl,
          tickValues:
              tickValues?.whereType<DateTime>().toList(growable: false) ??
              const <DateTime>[],
          chartType: FluentChartType.areaChart,
        )
      : domainRangeOfNumericForAreaLineScatterCharts(
          series,
          margins,
          containerWidth,
          isRtl: isRtl,
          scaleType: xScaleType,
          // AreaChart omits hasMarkersMode entirely (`AreaChart.tsx:164`), so
          // the numeric x domain carries no marker padding.
          hasMarkersMode: false,
          xMinVal: xMinValue,
          xMaxVal: xMaxValue,
        );

  @override
  FluentChartMinMax resolveYMinMax({bool useSecondaryYScale = false}) =>
      findNumericMinMaxOfY(
        series,
        useSecondaryYScale: useSecondaryYScale,
        scaleType: yScaleType,
      );

  @override
  double? get maxOfYVal => dataSet.maxOfYVal;

  @override
  FluentAxisSpec createYAxis(
    FluentYAxisParams params,
    FluentAxisData axisData, {
    required bool isRtl,
    required bool isIntegralDataset,
    bool useSecondaryYScale = false,
  }) => axis.createNumericYAxis(
    params,
    axisData,
    isRtl: isRtl,
    isIntegralDataset: isIntegralDataset,
    chartType: FluentChartType.areaChart,
    useSecondaryYScale: useSecondaryYScale,
    scaleType: yScaleType,
  );

  @override
  FluentAxisSpec createStringYAxis(
    FluentYAxisParams params,
    List<String> dataPoints,
    FluentAxisData axisData, {
    required bool isRtl,
  }) => axis.createStringYAxis(
    params,
    dataPoints,
    axisData,
    isRtl: isRtl,
    chartType: FluentChartType.areaChart,
  );

  @override
  void paintSeries(
    Canvas canvas,
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
    FluentChartColors colors,
  ) {
    final layers = layersFor(context);
    final lineWidth = style.lineStrokeWidth!.resolve(<WidgetState>{})!;
    // Pass 1: the top edge, then the body (`AreaChart.tsx:668-744`).
    for (final layer in layers) {
      canvas.drawPath(
        layer.linePath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth =
              series[layer.index].lineOptions?.strokeWidth ?? lineWidth
          ..color = layer.strokeColour.withValues(alpha: layer.lineOpacity),
      );
      final centre = layer.singlePointCentre;
      if (centre != null) {
        final r = style.singlePointRadius!.resolve(<WidgetState>{})!;
        canvas
          ..drawCircle(
            centre,
            r,
            Paint()..color = layer.colour.withValues(alpha: layer.fillOpacity),
          )
          ..drawCircle(
            centre,
            r,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = style.singlePointStrokeWidth!.resolve(
                <WidgetState>{},
              )!
              ..color = layer.strokeColour.withValues(
                alpha: layer.layerOpacity,
              ),
          );
        continue;
      }
      final fill = Paint()
        ..color = layer.colour.withValues(
          alpha: layer.layerOpacity * layer.fillOpacity,
        );
      if (enableGradient) {
        fill.shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[layer.colour, layer.colour.withValues(alpha: 0)],
        ).createShader(layer.areaPath.getBounds());
      }
      canvas.drawPath(layer.areaPath, fill);
    }
    // Pass 2: the data-point circles, above every fill (`:751-826`).
    final activeFill = style.activePointFillColor!.resolve(<WidgetState>{})!;
    for (final layer in layers) {
      final yScale = _yScaleFor(layer.index, context);
      for (var j = 0; j < dataSet.rows.length; j++) {
        final r = circleRadiusFor(layer.index, j);
        if (r == 0) {
          continue;
        }
        final centre = Offset(
          context.xScale(dataSet.rows[j].xValue)!,
          yScale(dataSet.layers[layer.index][j].hi)!,
        );
        // `_updateCircleFillColor` (`:643-652`) inverts the marker under the
        // pointer to the canvas colour unless it has been clicked.
        final inverted = !isCircleClicked;
        canvas
          ..drawCircle(
            centre,
            r,
            Paint()..color = inverted ? activeFill : layer.colour,
          )
          ..drawCircle(
            centre,
            r,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = style.pointStrokeWidth!.resolve(<WidgetState>{})!
              ..color = layer.colour,
          );
      }
    }
    // Pass 3: the vertical rule at the nearest x, pushed after every circle
    // (`:827-842`). It spans `getGraphData`'s height, 0 to the plot's content
    // height, in `lineColor` — which the circle loop leaves on the last series,
    // so it takes the circles' ring colour, not the hairline's `Canvas` one
    // that would vanish on a forced-colours background.
    final nearest = nearestX;
    // A nearest x left over from data of another axis type has no place.
    final x = nearest == null ? null : context.xScale(nearest);
    if (x == null || layers.isEmpty) {
      return;
    }
    final bottom = layout.plotContentHeight;
    final pattern = style.hoverLineDashPattern!.resolve(<WidgetState>{})!;
    final rule = Paint()
      ..strokeWidth = style.hoverLineWidth!.resolve(<WidgetState>{})!
      ..color = layers.last.colour.withValues(
        alpha: style.hoverLineOpacity!.resolve(<WidgetState>{}),
      );
    // SVG repeats an odd-length dash array to make it even, which is what
    // walking it with the index parity does.
    if (pattern.fold<double>(0, (sum, run) => sum + run) <= 0) {
      canvas.drawLine(Offset(x, 0), Offset(x, bottom), rule);
      return;
    }
    var y = 0.0;
    for (var i = 0; y < bottom; i++) {
      final run = pattern[i % pattern.length];
      if (i.isEven) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x, math.min(y + run, bottom)),
          rule,
        );
      }
      y += run;
    }
  }

  @override
  List<FluentChartHitRegion> buildHitRegions(
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
  ) {
    final rows = dataSet.rows;
    if (rows.isEmpty || series.isEmpty) {
      return const <FluentChartHitRegion>[];
    }
    // One band per x: the stretch of the plot the bisector at
    // `AreaChart.tsx:193-228` resolves to it, cut at the midpoints of its
    // neighbours in data space. The listening `<rect>` has no `x`, so it runs
    // from the chart's left edge to the last tick (`:1127-1141`), and right to
    // left the last tick is the smallest: either way the leftmost band reaches
    // the edge and the rightmost x ends the span, as `FluentAreaChartState`
    // does.
    // ponytail: the rect stops `margins.top` short of the bottom (`:1129`),
    // inside the x tick labels; the bands run the full height.
    //
    // `Rect.contains` gives a shared edge to the band on its right, while the
    // bisector keeps the lower x on a tie (`:215`) and the rect holds the
    // rightmost x itself. Left to right, both sit on a band's right edge, so
    // they move on by a hair; right to left only the rightmost x does.
    final rtl = layout.isRtl;
    final last = rows.length - 1;
    final nudge = rtl ? 0.0 : 1e-9;
    double cut(int j) =>
        nudge +
        context.xScale(
          (_xOrder(rows[j].xValue) + _xOrder(rows[j + 1].xValue)) / 2,
        )!;
    final end = 1e-9 + context.xScale(rows[rtl ? 0 : last].xValue)!;
    final bands = <Rect>[
      for (var j = 0; j <= last; j++)
        Rect.fromPoints(
          Offset(j == 0 ? (rtl ? end : 0) : cut(j - 1), 0),
          Offset(j == last ? (rtl ? 0 : end) : cut(j), context.containerHeight),
        ),
    ];
    Offset circle(int layer, int j) => Offset(
      context.xScale(rows[j].xValue)!,
      _yScaleFor(layer, context)(dataSet.layers[layer][j].hi)!,
    );

    // The header is series 0's own point at that x — `lineChartData[0]
    // .data[index]` (`:231`) — and its truthy `xAxisCalloutData` wins over
    // the formatted x (`:250`).
    final firstByX = <Object, FluentLineChartDataPoint>{
      for (final point in series.first.data.cast<FluentLineChartDataPoint>())
        _xKey(point.x): point,
    };
    // `findCalloutPoints(_calloutPoints, x)` (`:236`), keyed once rather than
    // scanned per x, since every hover move rebuilds these.
    final calloutByX = <Object, List<FluentCustomizedCalloutDataPoint>>{
      for (final entry in dataSet.calloutPoints) _xKey(entry.x): entry.values,
    };
    final popovers = <FluentChartPopoverData>[
      for (final row in rows)
        FluentChartPopoverData(
          xValue: switch (firstByX[_xKey(row.xValue)]?.xAxisCalloutData) {
            final String text when text.isNotEmpty => text,
            // `formatDateToLocaleString(x, props.culture, props.useUTC)`
            // (`AreaChart.tsx:234`), then `ChartPopover.tsx:128` formats the
            // reading once more, which is what groups a numeric x.
            _ => formatToLocaleString(
              row.xValue,
              culture: culture,
              useUtc: useUtc,
            ),
          },
          isCalloutForStack: true,
          // parity: the calloutProps at `AreaChart.tsx:1087` carry no
          // `culture`, so upstream's rows fall back to the runtime locale.
          // The prop is documented as the popover's locale, so the port
          // hands it on.
          culture: culture,
          // The callout points at x, narrowed to the highlighted legends by
          // `_getFilteredLegendValues` (`:971-975`). The rows carry no
          // `index`, as AreaChart's points never set one, so they draw the
          // accent bar rather than a shape (`ChartPopover.tsx:188`).
          yValues: <FluentYValueHover>[
            for (final value
                in calloutByX[_xKey(row.xValue)] ??
                    const <FluentCustomizedCalloutDataPoint>[])
              if (_noneHighlighted || _highlighted(value.legend))
                FluentYValueHover(
                  legend: value.legend,
                  y: value.y,
                  // `calloutData(points)` runs on `_addDefaultColors`' output
                  // (`:1071-1074`), so an uncoloured series reads its palette
                  // colour here too.
                  color: dataSet.colours[value.index!],
                  yAxisCalloutText: value.yAxisCalloutText,
                  yAxisCalloutBreakdown: value.yAxisCalloutBreakdown,
                ),
          ],
        ),
    ];

    final regions = <FluentChartHitRegion>[
      for (var j = 0; j < rows.length; j++)
        FluentChartHitRegion(
          bounds: bands[j],
          index: j,
          legend: series.last.legend,
          popoverData: popovers[j],
          // A keyboard stop has no pointer; the shell would otherwise take
          // the middle of the band.
          popoverAnchor: keyboardFocused
              ? Rect.fromCenter(
                  center: circle(series.length - 1, j),
                  width: 0,
                  height: 0,
                )
              : null,
        ),
    ];
    // `_getOnClickHandler` (`:846-853`) clicks a circle only while no x
    // repeats or goes missing. Every visible circle at the hovered x takes the
    // click for its own point, so each is a mark of its band's index, after
    // every band so that it wins the press. Clipped to its band, so the merged
    // hover target stays the bisector's.
    // parity: `_onDataPointClick` (`:612-617`) also flags the circle clicked,
    // which shrinks it; not reproduced.
    if (dataSet.hasDuplicateXValues || dataSet.hasMissingXValues) {
      return regions;
    }
    final radius = markerRadius ?? style.pointRadius!.resolve(<WidgetState>{})!;
    for (var layer = 0; layer < series.length; layer++) {
      // `_getCircleRadius` hides a dimmed legend's circles (`:857-859`).
      if (!_noneHighlighted && !_highlighted(series[layer].legend)) {
        continue;
      }
      final onClickByX = <Object, VoidCallback?>{
        for (final point in series[layer].data.cast<FluentLineChartDataPoint>())
          _xKey(point.x): point.onDataPointClick,
      };
      for (var j = 0; j < rows.length; j++) {
        final onClick = onClickByX[_xKey(rows[j].xValue)];
        if (onClick == null) {
          continue;
        }
        regions.add(
          FluentChartHitRegion(
            bounds: Rect.fromCenter(
              center: circle(layer, j),
              width: radius * 2,
              height: radius * 2,
            ).intersect(bands[j]),
            index: j,
            legend: series[layer].legend,
            popoverData: popovers[j],
            onActivate: onClick,
          ),
        );
      }
    }
    return regions;
  }
}
