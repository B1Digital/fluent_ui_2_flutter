import 'package:fluent_2/src/charts/axis/axis_types.dart';
import 'package:fluent_2/src/charts/model/chart_common.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the constant block carries the upstream literals', () {
    expect(kMinDomainMargin, 8, reason: 'utilities.ts:89 — MIN_DOMAIN_MARGIN.');
    expect(kMinDonutRadius, 1, reason: 'utilities.ts:90 — MIN_DONUT_RADIUS.');
    expect(kDefaultDateString, '2000-01-01', reason: 'utilities.ts:91.');
    expect(kDefaultWrapWidth, 10, reason: 'utilities.ts:1110.');
    // kDefaultBarWidth and kMinBarWidth are NOT asserted here — plan 02 owns
    // them in internal/chart_utils.dart and asserts them there.
    expect(kDefaultMarginWithTicks, 40, reason: 'CartesianChart.tsx:41.');
    expect(kDefaultMarginNoTicks, 20, reason: 'CartesianChart.tsx:42.');
    expect(
      kHorizontalMarginForYAxisTitle,
      24,
      reason: 'CartesianChart.tsx:38.',
    );
    expect(kVerticalMarginForXAxisTitle, 20, reason: 'CartesianChart.tsx:39.');
    expect(kAxisTitlePadding, 8, reason: 'CartesianChart.tsx:40.');
    expect(kMinLegendContainerHeight, 40, reason: 'CartesianChart.tsx:54.');
    expect(kHideTickOverlapNumericPad, 20, reason: 'utilities.ts:298 adds 20.');
    expect(kHideTickOverlapDatePad, 40, reason: 'utilities.ts:519 adds 40.');
    expect(
      kBandSweepGap,
      10,
      reason: 'utilities.ts:616 backs off by half-width + 10.',
    );
    expect(
      kHideTickOverlapMaxTicks,
      10,
      reason: 'utilities.ts:300 and :521 clamp to 10.',
    );
  });

  test('FluentChartType has the nine upstream members', () {
    expect(
      FluentChartType.values.length,
      9,
      reason:
          'ChartTypes at utilities.ts:98-108 declares exactly nine members.',
    );
    expect(
      FluentChartType.values.contains(FluentChartType.ganttChart),
      isTrue,
      reason:
          'GanttChart is the ninth member and gates the date-axis '
          'gridlines.',
    );
  });

  test('FluentXAxisParams reproduces the destructured defaults', () {
    const params = FluentXAxisParams(
      domainNRangeValues: FluentChartDomainRange(
        dStartValue: 0,
        dEndValue: 100,
        rStartValue: 40,
        rEndValue: 680,
      ),
      containerHeight: 300,
      containerWidth: 700,
      margins: FluentChartMargins(left: 40, right: 20, top: 20, bottom: 35),
    );
    expect(
      params.showRoundOffXTickValues,
      isFalse,
      reason: 'utilities.ts:265 destructures showRoundOffXTickValues = false.',
    );
    expect(params.xAxistickSize, 6, reason: 'utilities.ts:266 destructures 6.');
    expect(params.tickPadding, 10, reason: 'utilities.ts:267 destructures 10.');
    expect(
      params.hideTickOverlap,
      isFalse,
      reason: 'undefined is falsy upstream.',
    );
    expect(
      params.tickLayout,
      FluentTickLayout.defaultLayout,
      reason:
          "props.xAxis.tickLayout is only 'auto' when set "
          '(CartesianChart.tsx:282).',
    );
  });

  test('FluentYAxisParams reproduces the destructured defaults', () {
    const params = FluentYAxisParams(
      margins: FluentChartMargins(left: 40, right: 20, top: 20, bottom: 35),
      containerWidth: 700,
      containerHeight: 300,
    );
    expect(
      params.yAxisTickCount,
      4,
      reason: 'utilities.ts:811 destructures yAxisTickCount = 4.',
    );
    expect(
      params.tickPadding,
      12,
      reason:
          'utilities.ts:808 destructures 12, even though '
          'CartesianChart.tsx:304 always passes 10.',
    );
    expect(params.yMaxValue, 0, reason: 'utilities.ts:803.');
    expect(params.yMinValue, 0, reason: 'utilities.ts:804.');
    expect(params.maxOfYVal, 0, reason: 'utilities.ts:809.');
    expect(
      params.yAxisPadding,
      0,
      reason: 'utilities.ts:964 destructures yAxisPadding = 0.',
    );
    expect(
      params.yMinMaxValues.startValue,
      0,
      reason: 'utilities.ts:801 destructures { startValue: 0, endValue: 0 }.',
    );
  });

  test('FluentAxisData is mutable and starts empty', () {
    final data = FluentAxisData();
    expect(
      data.yAxisDomainValues,
      isEmpty,
      reason: 'CartesianChart.tsx:320 seeds both lists empty.',
    );
    data.yAxisDomainValues = <double>[0, 100];
    data.yAxisTickText = <String>['0', '100'];
    expect(
      data.yAxisTickText,
      <String>['0', '100'],
      reason:
          'createNumericYAxis writes into the caller-owned object '
          '(utilities.ts:889-890).',
    );
  });
}
