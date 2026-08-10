import 'package:flutter/widgets.dart';

import 'area_chart_style.dart';
import 'axis/axis_builders.dart' as axis;
import 'axis/axis_types.dart';
import 'axis/domain_range.dart';
import 'cartesian/cartesian_layout.dart';
import 'cartesian/cartesian_series_delegate.dart';
import 'chrome/chart_popover.dart';
import 'internal/chart_colors.dart';
import 'internal/chart_text_measurer.dart';
import 'internal/chart_utils.dart';
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
  });

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

  // `mode === 'tozeroy' || _shouldFillToZeroY()` (`:296`, `:1065-1067`).
  final toZero = mode == FluentAreaChartMode.toZeroY || hasSecondaryYScale;
  final List<List<d3.StackPoint>> layers;
  final double maxOfYVal;
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

  /// Whole-layer opacity — 0.8 in tozeroy mode, else the series opacity
  /// (`AreaChart.tsx:685`).
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
          layerOpacity: mode == FluentAreaChartMode.toZeroY
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
  }

  @override
  List<FluentChartHitRegion> buildHitRegions(
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
  ) {
    if (dataSet.rows.isEmpty || series.isEmpty) {
      return const <FluentChartHitRegion>[];
    }
    final radius = style.pointRadius!.resolve(<WidgetState>{})!;
    return <FluentChartHitRegion>[
      for (var j = 0; j < dataSet.rows.length; j++)
        FluentChartHitRegion(
          bounds: Rect.fromCenter(
            center: Offset(
              context.xScale(dataSet.rows[j].xValue)!,
              context.yScalePrimary(dataSet.layers.last[j].hi)!,
            ),
            width: radius * 2,
            height: radius * 2,
          ),
          index: j,
          legend: series.last.legend,
          popoverData: FluentChartPopoverData(
            xValue: '${dataSet.rows[j].xValue}',
            isCalloutForStack: true,
            yValues: <FluentYValueHover>[
              for (var i = 0; i < series.length; i++)
                FluentYValueHover(
                  legend: series[i].legend,
                  y: dataSet.rows[j].values[i],
                  color: dataSet.colours[i],
                ),
            ],
          ),
        ),
    ];
  }
}
