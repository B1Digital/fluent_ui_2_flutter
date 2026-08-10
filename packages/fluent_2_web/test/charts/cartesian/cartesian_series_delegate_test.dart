import 'dart:ui' show PictureRecorder;

import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/stub_cartesian_delegate.dart';

/// The delegate replaces `props.children(ChildProps)` plus the four scale
/// factories on `ModifiedCartesianChartProps`. Nine further members carry the
/// pull-style configuration the shell reads off the chart
/// (`CartesianChart.tsx:193-224`, `:296-313`); each defaults to upstream's
/// own default so a chart that does not care writes nothing.
void main() {
  const margins = FluentChartMargins(left: 40, right: 20, top: 20, bottom: 35);
  const size = Size(400, 260);
  const yParams = FluentYAxisParams(
    margins: margins,
    containerWidth: 400,
    containerHeight: 260,
  );

  final layout = FluentCartesianLayout.resolve(
    size: size,
    margins: margins,
    xAxisLabelReserve: 0,
    isRtl: false,
    startFromX: 0,
  );

  /// A child context built the way the shell builds one: the same scale object
  /// the axis was created from, and the **unreduced** container height.
  FluentCartesianChildContext contextFor(StubCartesianDelegate delegate) {
    final scale = delegate
        .createYAxis(
          yParams,
          FluentAxisData(),
          isRtl: false,
          isIntegralDataset: true,
        )
        .scale;
    return FluentCartesianChildContext(
      xScale: scale,
      yScalePrimary: scale,
      containerWidth: 400,
      containerHeight: 260,
    );
  }

  test('the optional pull-hooks default to upstream absence', () {
    final delegate = StubCartesianDelegate();
    expect(
      delegate.domainMargins(400),
      isNull,
      reason:
          'null means "use the shell margins", which is the `? :` at '
          'CartesianChart.tsx:195',
    );
    expect(
      delegate.yDomainMargins(260),
      isNull,
      reason: 'the same shape at CartesianChart.tsx:296',
    );
    expect(
      delegate.datasetForXAxisDomain,
      isNull,
      reason: 'CartesianChart.tsx:264 forwards undefined',
    );
    expect(
      delegate.stringDatasetForYAxisDomain,
      isNull,
      reason: 'CartesianChart.tsx:324 forwards undefined',
    );
    expect(
      delegate.maxOfYVal,
      isNull,
      reason: 'CartesianChart.tsx:305 forwards undefined',
    );
    expect(
      delegate.barWidth,
      isNull,
      reason: 'CartesianChart.tsx:200 forwards props.barwidth',
    );
    expect(
      delegate.isIntegralDataset,
      isTrue,
      reason:
          'CartesianChart.tsx:66-68 computes `!points.some(...)`, which is true '
          'for an empty series',
    );
    expect(
      delegate.xAxisTickLayout,
      FluentTickLayout.defaultLayout,
      reason: "props.xAxis?.tickLayout defaults to 'default'",
    );
    expect(
      delegate.yAxisPadding,
      isNull,
      reason: 'CartesianChart.tsx:310 reads `props.yAxisPadding || 0`',
    );
    expect(
      delegate.xAxisPadding,
      isNull,
      reason: 'CartesianChart.tsx:216 forwards props.xAxisPadding',
    );
    expect(
      delegate.xAxisInnerPadding,
      isNull,
      reason: 'CartesianChart.tsx:217 forwards props.xAxisInnerPadding',
    );
    expect(
      delegate.xAxisOuterPadding,
      isNull,
      reason: 'CartesianChart.tsx:218 forwards props.xAxisOuterPadding',
    );
    expect(
      delegate.culture,
      isNull,
      reason: 'CartesianChart.tsx:169 forwards an undefined culture',
    );
    expect(
      delegate.tickParams.tickValues,
      isNull,
      reason: 'CartesianChart.tsx:241 forwards `props.tickParams!` unfilled',
    );
  });

  test('paintSeries receives the resolved layout, not just scales', () {
    final delegate = StubCartesianDelegate();
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final context = contextFor(delegate);

    delegate.paintSeries(
      canvas,
      context,
      layout,
      FluentChartColors.of(
        FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      ),
    );
    recorder.endRecording().dispose();

    expect(
      delegate.paintCount,
      1,
      reason: 'the delegate is callable with no widget tree mounted',
    );
    expect(
      delegate.lastLayout,
      same(layout),
      reason:
          'the layout travels with the context, removing the getmargins '
          'closure channel of HorizontalBarChartWithAxis.tsx:121-123',
    );
    expect(
      delegate.lastContext?.containerHeight,
      260,
      reason:
          'children() is handed the unreduced containerHeight at '
          'CartesianChart.tsx:440, unlike getGraphData at :212',
    );
    expect(
      delegate.lastContext?.yScaleSecondary,
      isNull,
      reason: 'no secondaryYScaleOptions means no secondary scale, :341-352',
    );
  });

  test('createYAxis writes its tick text into the shared axis data', () {
    final axisData = FluentAxisData();
    StubCartesianDelegate().createYAxis(
      yParams,
      axisData,
      isRtl: false,
      isIntegralDataset: true,
    );
    expect(
      axisData.yAxisTickText,
      <String>['0', '50', '100'],
      reason:
          'IAxisData is mutable and is the channel startFromX reads from '
          '(CartesianChart.tsx:375)',
    );
  });

  test('hit regions compare by value', () {
    final delegate = StubCartesianDelegate();
    final regions = delegate.buildHitRegions(contextFor(delegate), layout);
    expect(regions.length, 3, reason: 'the stub declares three regions');
    expect(
      regions.first.semanticsLabel,
      'Point 0',
      reason:
          'canvas text produces no semantics node, so the label must be '
          'supplied explicitly — design spec section 5.7',
    );
    expect(
      regions,
      StubCartesianDelegate().buildHitRegions(contextFor(delegate), layout),
      reason:
          'two delegates over the same layout produce equal regions, so a '
          'rebuild that changes nothing does not invalidate the hit map',
    );
    expect(
      regions.first == regions[1],
      isFalse,
      reason: 'index and bounds both participate in equality',
    );
  });
}
