// Pixel parity for SankeyChart's inbox, rebalance and responsive stories,
// against the live @fluentui/react-charts render.
//
// Every input below is transcribed from the story's own source, recovered from
// the storybook runtime by `capture_png.mjs` into
// `crawlers/storybooks-fluentui/out/stories/<story-id>.tsx`. Nothing here is
// invented or rounded. SankeyChartBasic lives in
// `sankey_and_gantt_parity_test.dart`.
//
// Every story reads its title from `data.chartTitle`, which SankeyChart paints
// (`SankeyChart.tsx:1159-1161`); here it is the widget's `chartTitle`. The
// `width`, `height` and `shouldResize` props are replaced by the box the
// harness mounts at, which is each story's initial slider value.
//
// See `support/react_parity.dart` for why text is masked and why the tolerance
// is not zero.
import 'package:fluent_2/src/charts/internal/data_viz_palette.dart';
import 'package:fluent_2/src/charts/model/sankey_data.dart';
import 'package:fluent_2/src/charts/sankey_chart.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/react_parity.dart';

/// A node with the story's `getColorFromToken(fill)` and
/// `getColorFromToken(border)`.
FluentSankeyNode _node(
  int id,
  String name,
  FluentDataVizToken fill,
  FluentDataVizToken border,
) => FluentSankeyNode(
  nodeId: id,
  name: name,
  color: FluentDataVizPalette.resolve(fill),
  borderColor: FluentDataVizPalette.resolve(border),
);

void main() {
  setUpAll(loadParityFonts);

  testWidgets('SankeyChartInbox', (tester) async {
    // `const data: ChartProps` in charts-sankeychart--sankey-chart-inbox.tsx.
    // Node 11's name keeps the source's leading and doubled spaces.
    const c2 = FluentDataVizToken.color2;
    const c22 = FluentDataVizToken.color22;
    const c7 = FluentDataVizToken.color7;
    const c27 = FluentDataVizToken.color27;
    const c8 = FluentDataVizToken.color8;
    const c28 = FluentDataVizToken.color28;
    final data = FluentSankeyChartData(
      nodes: <FluentSankeyNode>[
        _node(0, '192.168.42.72', c2, c22),
        _node(1, '172.152.48.13', c2, c22),
        _node(2, '124.360.55.1', c2, c22),
        _node(3, '192.564.10.2', c2, c22),
        _node(4, '124.124.50.1', c2, c22),
        _node(5, '172.630.89.4', c2, c22),
        _node(6, 'inbox', c7, c27),
        _node(7, 'Junk Folder', c7, c27),
        _node(8, 'Deleted Folder', c7, c27),
        _node(9, 'Clicked', c8, c28),
        _node(10, 'Opened', c8, c28),
        _node(11, ' No further action  required', c8, c28),
      ],
      links: const <FluentSankeyLink>[
        FluentSankeyLink(source: 0, target: 6, value: 80),
        FluentSankeyLink(source: 1, target: 6, value: 50),
        FluentSankeyLink(source: 1, target: 7, value: 28),
        FluentSankeyLink(source: 2, target: 7, value: 14),
        FluentSankeyLink(source: 3, target: 7, value: 7),
        FluentSankeyLink(source: 3, target: 8, value: 20),
        FluentSankeyLink(source: 4, target: 7, value: 10),
        FluentSankeyLink(source: 5, target: 7, value: 10),
        FluentSankeyLink(source: 6, target: 9, value: 30),
        FluentSankeyLink(source: 6, target: 10, value: 55),
        FluentSankeyLink(source: 7, target: 11, value: 60),
        FluentSankeyLink(source: 8, target: 11, value: 2),
      ],
    );

    await expectReactParity(
      tester,
      'charts-sankeychart--sankey-chart-inbox',
      FluentSankeyChart(
        data: data,
        chartTitle: 'Sankey Chart',
        // `strings` and `accessibility` reach the popover and the semantics
        // tree only; transcribed because the story sets them.
        linkFromLabel: 'from category {0}',
        emptySemanticLabel: 'Graph has no data to display',
        nodeSemanticLabel: 'Category {0} with email count {1}',
        linkSemanticLabel: '{2} items moved from category {0} to {1}',
        reflowMode: FluentSankeyReflowMode.minWidth,
      ),
      // Measured 0.072% — 228 of 315,162 px, aligned. Every node rect lands on
      // the capture; all 228 px sit on the 2px ribbon borders between the
      // first two columns (x 180-260), where a border runs within 2 px of
      // horizontal and Skia and Chromium flatten the same cubic a few tenths
      // of a pixel apart. Rasteriser noise, as in SankeyChartBasic.
      //
      // Not counted, because it is inside the text mask: node 11 reads "No
      // further action requi..." upstream, where SVG collapses the name's
      // leading and doubled spaces before measuring, and "No further action
      // req..." here, where `truncateSankeyText` keeps them.
      maxMismatch: 0.08,
    );
  });

  testWidgets('SankeyChartRebalance', (tester) async {
    // `const dataSimple` in charts-sankeychart--sankey-chart-rebalance.tsx: the
    // story's `useState<DataSouce>(DataSouce.Simple)` starts on it, so
    // `dataComplex` is never on screen in the capture.
    final data = FluentSankeyChartData(
      nodes: <FluentSankeyNode>[
        _node(
          0,
          'Large Source',
          FluentDataVizToken.color11,
          FluentDataVizToken.color21,
        ),
        _node(
          1,
          'Tiny Source',
          FluentDataVizToken.color12,
          FluentDataVizToken.color22,
        ),
        _node(
          2,
          'Large Target',
          FluentDataVizToken.color13,
          FluentDataVizToken.color23,
        ),
        _node(
          3,
          'Tiny Target',
          FluentDataVizToken.color14,
          FluentDataVizToken.color24,
        ),
      ],
      links: const <FluentSankeyLink>[
        FluentSankeyLink(source: 0, target: 2, value: 10000),
        FluentSankeyLink(source: 1, target: 2, value: 1),
        FluentSankeyLink(source: 0, target: 3, value: 1),
        FluentSankeyLink(source: 1, target: 3, value: 1),
      ],
    );

    await expectReactParity(
      tester,
      'charts-sankeychart--sankey-chart-rebalance',
      FluentSankeyChart(
        data: data,
        chartTitle: 'Sankey Chart',
        linkFromLabel: 'from {0}',
        emptySemanticLabel: 'Graph has no data to display',
        nodeSemanticLabel: '{0} with {1} sign-ins',
        linkSemanticLabel: '{2} sign-ins from {0} and {1}',
        reflowMode: FluentSankeyReflowMode.minWidth,
      ),
      // Measured 0.047% — 153 of 323,521 px, aligned: the same near-horizontal
      // ribbon borders as SankeyChartInbox, and nothing else.
      maxMismatch: 0.055,
    );
  });

  testWidgets('SankeyChartResponsive', (tester) async {
    // The `data` built inside SankeyChartResponsive in
    // charts-sankeychart--sankey-chart-responsive.tsx. The story wraps the
    // chart in a `ResponsiveContainer` and passes no size and no
    // `reflowProps`; the capture's 944 x 468 box is what that container
    // resolved to, and this port fills its constraints the same way.
    final data = FluentSankeyChartData(
      nodes: <FluentSankeyNode>[
        _node(
          0,
          'node0',
          FluentDataVizToken.color11,
          FluentDataVizToken.color21,
        ),
        _node(
          1,
          'node1',
          FluentDataVizToken.color12,
          FluentDataVizToken.color22,
        ),
        _node(
          2,
          'node2',
          FluentDataVizToken.color13,
          FluentDataVizToken.color23,
        ),
        _node(
          3,
          'node3',
          FluentDataVizToken.color14,
          FluentDataVizToken.color24,
        ),
        _node(
          4,
          'node4',
          FluentDataVizToken.color2,
          FluentDataVizToken.color22,
        ),
        _node(
          5,
          'node5',
          FluentDataVizToken.color15,
          FluentDataVizToken.color25,
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
      'charts-sankeychart--sankey-chart-responsive',
      FluentSankeyChart(data: data, chartTitle: 'Sankey Chart'),
      // Measured 0.045% — 197 of 436,578 px, aligned: near-horizontal ribbon
      // borders only, as in SankeyChartInbox.
      maxMismatch: 0.055,
    );
  });
}
