import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2/src/charts/internal/d3/axis_geometry.dart';
import 'package:fluent_2/src/charts/internal/d3/scale_linear.dart' as d3;
import 'package:flutter/widgets.dart';

/// A minimal concrete delegate: one linear x scale, one linear y scale, and a
/// series that paints [markColour] over the whole canvas.
///
/// Every shell test needs a delegate, and the shell's contract is that a
/// delegate is exercisable with no widget tree. This class is that contract's
/// smallest witness.
class StubCartesianDelegate extends FluentCartesianSeriesDelegate {
  /// Creates a stub over [categories] when [xAxisType] is
  /// `FluentChartAxisType.category`, and over 0..10 otherwise.
  StubCartesianDelegate({
    this.categories = const <String>['A', 'B', 'C'],
    this.xAxisType = FluentChartAxisType.numeric,
    this.chartType = FluentChartType.lineChart,
    this.markColour = const Color(0xFFFF0000),
    this.fillWholeCanvas = false,
    this.hitRegionCount = 3,
  });

  /// The band domain used when the x axis is categorical.
  final List<String> categories;

  @override
  final FluentChartAxisType xAxisType;

  @override
  final FluentChartType chartType;

  /// The colour `paintSeries` fills with.
  final Color markColour;

  /// Whether `paintSeries` covers the whole canvas rather than the plot rect.
  /// Used by the painter's z-order test.
  final bool fillWholeCanvas;

  /// How many hit regions `buildHitRegions` returns.
  final int hitRegionCount;

  /// The layout the last `paintSeries` call received, for assertions.
  FluentCartesianLayout? lastLayout;

  /// The child context the last `paintSeries` call received.
  FluentCartesianChildContext? lastContext;

  /// How many times `paintSeries` has run.
  int paintCount = 0;

  @override
  FluentChartAxisType get yAxisType => FluentChartAxisType.numeric;

  @override
  List<String>? get datasetForXAxisDomain =>
      xAxisType == FluentChartAxisType.category ? categories : null;

  @override
  String? get chartTitle => 'Stub chart. ';

  @override
  FluentChartDomainRange resolveXDomainRange({
    required FluentChartMargins margins,
    required double containerWidth,
    required bool isRtl,
    required double? barWidth,
    required List<Object>? tickValues,
  }) => FluentChartDomainRange(
    dStartValue: 0,
    dEndValue: 10,
    rStartValue: margins.left ?? 0,
    rEndValue: containerWidth - (margins.right ?? 0),
  );

  @override
  FluentChartMinMax resolveYMinMax({bool useSecondaryYScale = false}) =>
      const FluentChartMinMax(startValue: 0, endValue: 100);

  @override
  FluentAxisSpec createYAxis(
    FluentYAxisParams params,
    FluentAxisData axisData, {
    required bool isRtl,
    required bool isIntegralDataset,
    bool useSecondaryYScale = false,
  }) {
    final scale = d3.scaleLinear()
      ..domainOf(<double>[0, 100])
      ..rangeOf(<double>[
        params.containerHeight - (params.margins.bottom ?? 0),
        params.margins.top ?? 0,
      ]);
    axisData
      ..yAxisDomainValues = <double>[0, 50, 100]
      ..yAxisTickText = <String>['0', '50', '100'];
    return FluentAxisSpec(
      scale: scale,
      tickValues: const <Object>[0, 50, 100],
      tickLabels: const <String>['0', '50', '100'],
      orientation: isRtl
          ? FluentAxisOrientation.right
          : FluentAxisOrientation.left,
      tickSizeInner: 6,
      tickSizeOuter: 6,
      tickPadding: params.tickPadding,
    );
  }

  @override
  FluentAxisSpec createStringYAxis(
    FluentYAxisParams params,
    List<String> dataPoints,
    FluentAxisData axisData, {
    required bool isRtl,
  }) => createYAxis(params, axisData, isRtl: isRtl, isIntegralDataset: true);

  @override
  void paintSeries(
    Canvas canvas,
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
    FluentChartColors colors,
  ) {
    paintCount += 1;
    lastLayout = layout;
    lastContext = context;
    canvas.drawRect(
      fillWholeCanvas ? Offset.zero & layout.size : layout.plotRect,
      Paint()..color = markColour,
    );
  }

  @override
  List<FluentChartHitRegion> buildHitRegions(
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
  ) => <FluentChartHitRegion>[
    for (var i = 0; i < hitRegionCount; i++)
      FluentChartHitRegion(
        bounds: Rect.fromLTWH(
          layout.plotRect.left + i * 20,
          layout.plotRect.top,
          20,
          layout.plotRect.height,
        ),
        index: i,
        legend: 'Series $i',
        popoverData: FluentChartPopoverData(
          xValue: '$i',
          legend: 'Series $i',
          yValue: '${i * 10}',
        ),
        semanticsLabel: 'Point $i',
      ),
  ];
}
