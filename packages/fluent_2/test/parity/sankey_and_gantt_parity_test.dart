// Pixel parity for SankeyChart and GanttChart, against the live
// @fluentui/react-charts render.
//
// Every input below is transcribed from the story's own source, recovered from
// the storybook runtime by `capture_png.mjs` into
// `crawlers/storybooks-fluentui/out/stories/<story-id>.tsx`.
//
// See `support/react_parity.dart` for why text is masked and why the tolerance
// is not zero.
import 'package:fluent_2/src/charts/cartesian/cartesian_chart_props.dart';
import 'package:fluent_2/src/charts/gantt_chart.dart';
import 'package:fluent_2/src/charts/internal/data_viz_palette.dart';
import 'package:fluent_2/src/charts/model/bar_data.dart';
import 'package:fluent_2/src/charts/model/sankey_data.dart';
import 'package:fluent_2/src/charts/sankey_chart.dart';
import 'package:flutter/widgets.dart' show Color;
import 'package:flutter_test/flutter_test.dart';

import 'support/react_parity.dart';

void main() {
  setUpAll(loadParityFonts);

  testWidgets('SankeyChartBasic', (tester) async {
    // `const data: ChartProps` in charts-sankeychart--sankey-chart-basic.tsx.
    final data = FluentSankeyChartData(
      nodes: <FluentSankeyNode>[
        FluentSankeyNode(
          nodeId: 0,
          name: 'node0',
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
          borderColor: FluentDataVizPalette.resolve(FluentDataVizToken.color22),
        ),
        FluentSankeyNode(
          nodeId: 1,
          name: 'node1',
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color7),
          borderColor: FluentDataVizPalette.resolve(FluentDataVizToken.color27),
        ),
        FluentSankeyNode(
          nodeId: 2,
          name: 'node2',
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color8),
          borderColor: FluentDataVizPalette.resolve(FluentDataVizToken.color28),
        ),
        FluentSankeyNode(
          nodeId: 3,
          name: 'node3',
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color9),
          borderColor: FluentDataVizPalette.resolve(FluentDataVizToken.color29),
        ),
        FluentSankeyNode(
          nodeId: 4,
          name: 'node4',
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color11),
          borderColor: FluentDataVizPalette.resolve(FluentDataVizToken.color8),
        ),
        FluentSankeyNode(
          nodeId: 5,
          name: 'node5',
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color12),
          borderColor: FluentDataVizPalette.resolve(FluentDataVizToken.color24),
        ),
      ],
      links: const <FluentSankeyLink>[
        FluentSankeyLink(source: 0, target: 2, value: 2),
        FluentSankeyLink(source: 1, target: 2, value: 2),
        FluentSankeyLink(source: 1, target: 3, value: 2),
        FluentSankeyLink(source: 0, target: 4, value: 2),
        FluentSankeyLink(source: 2, target: 3, value: 2),
        FluentSankeyLink(source: 2, target: 4, value: 2),
        FluentSankeyLink(source: 3, target: 4, value: 4),
        FluentSankeyLink(source: 3, target: 5, value: 4),
      ],
    );

    await expectReactParity(
      tester,
      'charts-sankeychart--sankey-chart-basic',
      // The story's sliders start at width 820 / height 412, which is exactly
      // the box the harness mounts from the manifest, so `shouldResize` — which
      // this port replaces with the widget's own constraints — has nothing to
      // do. `reflowProps={{mode: 'min-width'}}` is transcribed even though it
      // is inert at this size: four columns put the minimum at
      // 48+48+4*124+3*62 = 778px, under the 820 available, so the branch that
      // re-solves and scrolls never fires.
      FluentSankeyChart(
        data: data,
        chartTitle: 'Sankey Chart',
        reflowMode: FluentSankeyReflowMode.minWidth,
      ),
      // Measured 0.064% — 212 pixels of 332,688, aligned at shift (0,0).
      maxMismatch: 0.09,
    );
  });

  testWidgets('GanttChartBasic', (tester) async {
    // `const data: GanttChartDataPoint[]` in
    // charts-ganttchart--gantt-chart-basic.tsx. `new Date("2009-01-01")` is an
    // ISO date-only string, which JS parses as UTC.
    final data = <FluentGanttChartDataPoint>[
      FluentGanttChartDataPoint(
        x: FluentGanttSpan(
          start: DateTime.utc(2009, 1, 1),
          end: DateTime.utc(2009, 2, 28),
        ),
        y: 'Job A',
        legend: 'Alex',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
        gradient: const (Color(0xFF4760D5), Color(0xFF637CEF)),
      ),
      FluentGanttChartDataPoint(
        x: FluentGanttSpan(
          start: DateTime.utc(2009, 3, 5),
          end: DateTime.utc(2009, 4, 15),
        ),
        y: 'Job B',
        legend: 'Alex',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
        gradient: const (Color(0xFF4760D5), Color(0xFF637CEF)),
      ),
      FluentGanttChartDataPoint(
        x: FluentGanttSpan(
          start: DateTime.utc(2009, 2, 20),
          end: DateTime.utc(2009, 5, 30),
        ),
        y: 'Job C',
        legend: 'Max',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
        gradient: const (Color(0xFFE61C99), Color(0xFFEE5FB7)),
      ),
    ];

    await expectReactParity(
      tester,
      'charts-ganttchart--gantt-chart-basic',
      FluentGanttChart(
        data: data,
        // Both Switches start unchecked, so the reference was captured with
        // gradients and rounded corners off.
        props: const FluentCartesianChartProps(showYAxisLables: true),
      ),
      // Measured 0.098% — 200 pixels of 203,099, aligned at shift (0,0).
      maxMismatch: 0.12,
    );
  });
}
