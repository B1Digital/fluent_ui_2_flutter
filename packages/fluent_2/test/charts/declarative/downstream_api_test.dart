import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Compile-time pin on the 16 chart constructors the declarative adapters call.
///
/// The adapters in `internal/plotly/transform_*.dart` and
/// `internal/vega/transform_*.dart` construct these widgets directly. If a
/// chart plan renames a parameter, this file stops compiling — which is the
/// point. Every named argument below is one the adapters actually set.
///
/// Reconciled against the shipped chart API on 2026-08-11. **No corrections
/// were needed**: the pin as the plan wrote it compiles unaltered against the
/// charts plans 06–08 shipped, so every later task in this plan inherits the
/// argument spellings below verbatim. The pin was mutation-checked — renaming
/// `FluentHorizontalBarChartWithAxis.barHeight` fails compilation with
/// `No named parameter with the name 'barHeightXX'`, so the file is a live
/// gate and not dead weight.
///
/// Three standing rules the plan's Global Constraints derive and this file
/// demonstrates; tasks 17–26 and 43–49 must honour them:
/// - **No `roundCorners` on [FluentDonutChart].** The original pin passed one.
///   `DonutChart.tsx`'s own `roundCorners` is dead (recorded by plan 06), so
///   the transformer drops the directive rather than forwarding it.
/// - **The nine shell charts and [FluentSankeyChart] take no `width`/`height`.**
///   Plotly's layout dimensions become an enclosing `SizedBox` in every
///   transformer. [FluentDonutChart], [FluentGaugeChart], [FluentFunnelChart],
///   [FluentChartTable], [FluentPolarChart] and [FluentAnnotationOnlyChart] do
///   take them directly, as the calls below show.
/// - **Every cartesian axis, tick and label setting goes inside
///   [FluentCartesianChartProps]**, never as a flat argument.
///
/// Two type facts the adapters must satisfy before constructing, both visible
/// in the calls below:
/// - [FluentHeatMapChart.rangeValuesForColorScale] takes `List<Color>`, not
///   `List<String>` — upstream passes CSS strings
///   (`PlotlySchemaAdapter.ts:2564`), so colour resolution happens in the
///   adapter, not in the chart.
/// - [FluentSankeyChart] takes [FluentSankeyChartData], not [FluentChartData];
///   the transformer passes `chartData.sankeyData`.
void main() {
  test('every downstream chart the adapters construct exists', () {
    final widgets = <Widget>[
      const FluentDonutChart(
        data: FluentChartData(
          chartTitle: 't',
          chartData: <FluentChartDataPoint>[],
        ),
        height: 220,
        innerRadius: 1,
        hideLabels: false,
        showLabelsInPercent: true,
      ),
      const FluentVerticalStackedBarChart(
        data: <FluentVerticalStackedBarGroup>[],
        barWidth: 'auto',
        mode: 'plotly',
        barGapMax: 2,
        roundCorners: true,
        props: FluentCartesianChartProps(
          hideTickOverlap: true,
          showYAxisLables: true,
          noOfCharsToTruncate: 20,
          showYAxisLablesTooltip: true,
          roundedTicks: true,
        ),
      ),
      const FluentGroupedVerticalBarChart(
        data: <FluentGroupedVerticalBarChartData>[],
        props: FluentCartesianChartProps(hideTickOverlap: true),
      ),
      const FluentVerticalBarChart(
        data: <FluentVerticalBarChartDataPoint>[],
        maxBarWidth: 50,
        props: FluentCartesianChartProps(hideTickOverlap: true),
      ),
      const FluentLineChart(data: FluentChartData(chartTitle: 't')),
      const FluentAreaChart(data: FluentChartData(chartTitle: 't')),
      const FluentScatterChart(data: FluentChartData(chartTitle: 't')),
      const FluentHorizontalBarChartWithAxis(
        data: <FluentHorizontalBarChartWithAxisDataPoint>[],
        barHeight: 20,
      ),
      const FluentGanttChart(data: <FluentGanttChartDataPoint>[]),
      const FluentHeatMapChart(
        data: <FluentHeatMapChartData>[],
        domainValuesForColorScale: <double>[0, 1],
        rangeValuesForColorScale: <Color>[Color(0xFF000000), Color(0xFFFFFFFF)],
      ),
      const FluentSankeyChart(
        data: FluentSankeyChartData(
          nodes: <FluentSankeyNode>[],
          links: <FluentSankeyLink>[],
        ),
      ),
      const FluentGaugeChart(
        segments: <FluentGaugeChartSegment>[],
        chartValue: 0,
        height: 220,
      ),
      const FluentFunnelChart(data: <FluentFunnelDataPoint>[]),
      const FluentChartTable(
        headers: <FluentChartTableCell>[],
        rows: <List<FluentChartTableCell>>[],
      ),
      const FluentPolarChart(data: <FluentPolarSeries>[], height: 400),
      const FluentAnnotationOnlyChart(annotations: <FluentChartAnnotation>[]),
    ];
    expect(
      widgets.length,
      16,
      reason:
          'The Plotly router maps to 16 concrete charts (the chartMap at '
          'DeclarativeChart.tsx:262-338 has 17 keys but 16 distinct renderers — '
          'ResponsiveVerticalStackedBarChart is both the vsbc key and the '
          'fallback); all 16 must be constructible with the arguments the '
          'adapters pass.',
    );
  });

  test('the chart handle and export options the controller needs exist', () {
    const opts = FluentChartImageExportOptions(scale: 5);
    expect(
      opts.scale,
      5,
      reason: 'exportAsImage defaults scale to 5 (DeclarativeChart.tsx:441).',
    );
    expect(
      FluentChartHandle,
      isNotNull,
      reason:
          'The controller holds one handle per rendered cell (DeclarativeChart.tsx:385).',
    );
  });
}
