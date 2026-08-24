import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The SankeyChart docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage sankeyChartPage = DocsPage(
  id: 'charts-sankeychart',
  title: 'SankeyChart',
  description:
      'A Sankey chart visualizes a flow from one entity to another. Its '
      'goal is to clearly show the path of a depicted property. By '
      'hovering over a path, the user can highlight the source and '
      'destination of flow of this information. The height of each '
      'column is proportional to the size of data, similar to a pie '
      'chart. Sankey also utilizes streams to visualize relationships '
      'between different column groups and their associated values. '
      'Sankey charts are best used to visualize important relationships '
      'in a multi-level flow and help to investigate and monitor flow '
      'of information within workflows. Eg - Flow of mail data through '
      'different ip addresses.',
  source: 'lib/pages/charts_sankeychart.dart',
  prose: <ProseBlock>[
    ProseBlock(
      title: 'Layout',
      body:
          'Sankey charts require a minimum of 2 layers/ column groups '
          'to compare and can go up to a maximum of 4. More than 4 '
          'layers start making the chart overwhelming.\n',
    ),
    ProseBlock(
      title: 'Content',
      body:
          '- Node with title of data\n'
          '- Stream representing value connecting boxes.\n'
          '- Streams have a color gradient from their source to the '
          'destination.\n'
          '- Hover states over both nodes and streams\n',
    ),
    ProseBlock(
      title: 'Accessibility',
      body:
          'In the case where data equates to 1 (which is 4px) the node '
          'does not show content. The text is shown when a user hovers '
          'over the node.\n'
          'In the case where the node height reaches a minimum of 24 '
          'pixels, the title and number are on the same line. If the '
          'title is longer it is truncated.\n',
    ),
    ProseBlock(
      title: 'Do\'s',
      body:
          '- Use sankey charts sparingly. They are complex and need '
          'time and explanation to be understood by the user.\n'
          '- Aggregate the data to fit into a simpler sankey chart when '
          'there are lot of layers involved.\n',
    ),
    ProseBlock(
      title: 'Don\'ts',
      body: '- Avoid having more than 4 layers in the Sankey chart.\n',
    ),
  ],
  sections: <DocsSection>[
    DocsSection(
      id: 'charts-sankeychart--sankey-chart-basic',
      title: 'Sankey Chart Basic',
      builder: _sankeyChartBasic,
    ),
    DocsSection(
      id: 'charts-sankeychart--sankey-chart-inbox',
      title: 'Sankey Chart Inbox',
      builder: _sankeyChartInbox,
    ),
    DocsSection(
      id: 'charts-sankeychart--sankey-chart-rebalance',
      title: 'Sankey Chart Rebalance',
      builder: _sankeyChartRebalance,
    ),
    DocsSection(
      id: 'charts-sankeychart--sankey-chart-responsive',
      title: 'Sankey Chart Responsive',
      builder: _sankeyChartResponsive,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'data',
      type: 'FluentSankeyChartData',
      description: 'Nodes and links.',
    ),
    PropRow(
      name: 'chartTitle',
      type: 'String?',
      defaultValue: 'null',
      description: 'Title drawn above the diagram.',
    ),
    PropRow(
      name: 'titleFontSize',
      type: 'double?',
      defaultValue: 'null',
      description: 'Title font size, which also sets the top margin.',
    ),
    PropRow(
      name: 'hideTitle',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether the title is suppressed.',
    ),
    PropRow(
      name: 'colorsForNodes',
      type: 'List<Color>?',
      defaultValue: 'null',
      description: 'Node fills. Used only together with borderColorsForNodes.',
    ),
    PropRow(
      name: 'borderColorsForNodes',
      type: 'List<Color>?',
      defaultValue: 'null',
      description: 'Node borders. Used only together with colorsForNodes.',
    ),
    PropRow(
      name: 'numberFormat',
      type: 'NumberFormat?',
      defaultValue: 'null',
      description: "Formatter for every weight. Null renders value.toString().",
    ),
    PropRow(
      name: 'linkFromLabel',
      type: 'String',
      defaultValue: "'From {0}'",
      description: "Template for the popover's description line.",
    ),
    PropRow(
      name: 'emptySemanticLabel',
      type: 'String',
      defaultValue: "'Graph has no data to display'",
      description: 'Announced when there is nothing to draw.',
    ),
    PropRow(
      name: 'nodeSemanticLabel',
      type: 'String',
      defaultValue: "'node {0} with weight {1}'",
      description: "Template for a node's label.",
    ),
    PropRow(
      name: 'linkSemanticLabel',
      type: 'String',
      defaultValue: "'link from {0} to {1} with weight {2}'",
      description: "Template for a stream's label.",
    ),
    PropRow(
      name: 'reflowMode',
      type: 'FluentSankeyReflowMode',
      defaultValue: 'FluentSankeyReflowMode.none',
      description:
          "Behaviour when the container is narrower than the diagram's "
          'minimum width.',
    ),
    PropRow(
      name: 'controller',
      type: 'FluentChartController?',
      defaultValue: 'null',
      description: 'Imperative handle exposing toImage.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentSankeyChartStyle?',
      defaultValue: 'null',
      description: "Style override, layered over the theme's.",
    ),
  ],
);

// #docregion charts-sankeychart--sankey-chart-basic
Widget _sankeyChartBasic(BuildContext context) => const _SankeyChartBasic();

class _SankeyChartBasic extends StatefulWidget {
  const _SankeyChartBasic();

  @override
  State<_SankeyChartBasic> createState() => _SankeyChartBasicState();
}

class _SankeyChartBasicState extends State<_SankeyChartBasic> {
  double _width = 820;
  double _height = 412;

  @override
  Widget build(BuildContext context) {
    final FluentSankeyChartData data = FluentSankeyChartData(
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
      links: <FluentSankeyLink>[
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

    // Upstream drives the demo from two `<input type="range">` controls; the
    // nearest Fluent widget is FluentSlider, and its `semanticLabel` carries the
    // `aria-label` upstream sets. The chart box is a fixed pixel `<div>` upstream,
    // so it is wrapped in a horizontal scroller here rather than overflowing a
    // narrower docs column.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('Change Width:'),
            SizedBox(
              width: 140,
              child: FluentSlider(
                value: _width,
                min: 400,
                max: 1000,
                semanticLabel: 'Change Width',
                onChanged: (double value) => setState(() => _width = value),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Change Height:'),
            SizedBox(
              width: 140,
              child: FluentSlider(
                value: _height,
                min: 312,
                max: 400,
                semanticLabel: 'Change Height',
                onChanged: (double value) => setState(() => _height = value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: _width,
            height: _height,
            child: FluentSankeyChart(
              data: data,
              chartTitle: 'Sankey Chart',
              reflowMode: FluentSankeyReflowMode.minWidth,
            ),
          ),
        ),
      ],
    );
  }
}
// #enddocregion charts-sankeychart--sankey-chart-basic

// #docregion charts-sankeychart--sankey-chart-inbox
Widget _sankeyChartInbox(BuildContext context) => const _SankeyChartInbox();

class _SankeyChartInbox extends StatefulWidget {
  const _SankeyChartInbox();

  @override
  State<_SankeyChartInbox> createState() => _SankeyChartInboxState();
}

class _SankeyChartInboxState extends State<_SankeyChartInbox> {
  double _width = 820;
  double _height = 400;

  @override
  Widget build(BuildContext context) {
    final FluentSankeyChartData data = FluentSankeyChartData(
      nodes: <FluentSankeyNode>[
        FluentSankeyNode(
          nodeId: 0,
          name: '192.168.42.72',
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
          borderColor: FluentDataVizPalette.resolve(FluentDataVizToken.color22),
        ),
        FluentSankeyNode(
          nodeId: 1,
          name: '172.152.48.13',
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
          borderColor: FluentDataVizPalette.resolve(FluentDataVizToken.color22),
        ),
        FluentSankeyNode(
          nodeId: 2,
          name: '124.360.55.1',
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
          borderColor: FluentDataVizPalette.resolve(FluentDataVizToken.color22),
        ),
        FluentSankeyNode(
          nodeId: 3,
          name: '192.564.10.2',
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
          borderColor: FluentDataVizPalette.resolve(FluentDataVizToken.color22),
        ),
        FluentSankeyNode(
          nodeId: 4,
          name: '124.124.50.1',
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
          borderColor: FluentDataVizPalette.resolve(FluentDataVizToken.color22),
        ),
        FluentSankeyNode(
          nodeId: 5,
          name: '172.630.89.4',
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
          borderColor: FluentDataVizPalette.resolve(FluentDataVizToken.color22),
        ),
        FluentSankeyNode(
          nodeId: 6,
          name: 'inbox',
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color7),
          borderColor: FluentDataVizPalette.resolve(FluentDataVizToken.color27),
        ),
        FluentSankeyNode(
          nodeId: 7,
          name: 'Junk Folder',
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color7),
          borderColor: FluentDataVizPalette.resolve(FluentDataVizToken.color27),
        ),
        FluentSankeyNode(
          nodeId: 8,
          name: 'Deleted Folder',
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color7),
          borderColor: FluentDataVizPalette.resolve(FluentDataVizToken.color27),
        ),
        FluentSankeyNode(
          nodeId: 9,
          name: 'Clicked',
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color8),
          borderColor: FluentDataVizPalette.resolve(FluentDataVizToken.color28),
        ),
        FluentSankeyNode(
          nodeId: 10,
          name: 'Opened',
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color8),
          borderColor: FluentDataVizPalette.resolve(FluentDataVizToken.color28),
        ),
        FluentSankeyNode(
          nodeId: 11,
          name: ' No further action  required',
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color8),
          borderColor: FluentDataVizPalette.resolve(FluentDataVizToken.color28),
        ),
      ],
      links: <FluentSankeyLink>[
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

    // Upstream drives the demo from two `<input type="range">` controls; the
    // nearest Fluent widget is FluentSlider, and its `semanticLabel` carries the
    // `aria-label` upstream sets. The chart box is a fixed pixel `<div>` upstream,
    // so it is wrapped in a horizontal scroller here rather than overflowing a
    // narrower docs column.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('change Width:'),
            SizedBox(
              width: 140,
              child: FluentSlider(
                value: _width,
                min: 400,
                max: 1600,
                semanticLabel: 'Change Width',
                onChanged: (double value) => setState(() => _width = value),
              ),
            ),
            const SizedBox(width: 12),
            const Text('change Height:'),
            SizedBox(
              width: 140,
              child: FluentSlider(
                value: _height,
                min: 312,
                max: 400,
                semanticLabel: 'Change Height',
                onChanged: (double value) => setState(() => _height = value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: _width,
            height: _height,
            child: FluentSankeyChart(
              data: data,
              chartTitle: 'Sankey Chart',
              linkFromLabel: 'from category {0}',
              emptySemanticLabel: 'Graph has no data to display',
              nodeSemanticLabel: 'Category {0} with email count {1}',
              linkSemanticLabel: '{2} items moved from category {0} to {1}',
              reflowMode: FluentSankeyReflowMode.minWidth,
            ),
          ),
        ),
      ],
    );
  }
}
// #enddocregion charts-sankeychart--sankey-chart-inbox

// #docregion charts-sankeychart--sankey-chart-rebalance
Widget _sankeyChartRebalance(BuildContext context) =>
    const _SankeyChartRebalance();

class _SankeyChartRebalance extends StatefulWidget {
  const _SankeyChartRebalance();

  @override
  State<_SankeyChartRebalance> createState() => _SankeyChartRebalanceState();
}

class _SankeyChartRebalanceState extends State<_SankeyChartRebalance> {
  double _width = 820;
  double _height = 400;
  bool _simple = true;

  FluentSankeyChartData get _dataSimple => FluentSankeyChartData(
    nodes: <FluentSankeyNode>[
      FluentSankeyNode(
        nodeId: 0,
        name: 'Large Source',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color11),
        borderColor: FluentDataVizPalette.resolve(FluentDataVizToken.color21),
      ),
      FluentSankeyNode(
        nodeId: 1,
        name: 'Tiny Source',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color12),
        borderColor: FluentDataVizPalette.resolve(FluentDataVizToken.color22),
      ),
      FluentSankeyNode(
        nodeId: 2,
        name: 'Large Target',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color13),
        borderColor: FluentDataVizPalette.resolve(FluentDataVizToken.color23),
      ),
      FluentSankeyNode(
        nodeId: 3,
        name: 'Tiny Target',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color14),
        borderColor: FluentDataVizPalette.resolve(FluentDataVizToken.color24),
      ),
    ],
    links: <FluentSankeyLink>[
      FluentSankeyLink(source: 0, target: 2, value: 10000),
      FluentSankeyLink(source: 1, target: 2, value: 1),
      FluentSankeyLink(source: 0, target: 3, value: 1),
      FluentSankeyLink(source: 1, target: 3, value: 1),
    ],
  );

  static const FluentSankeyChartData _dataComplex = FluentSankeyChartData(
    nodes: <FluentSankeyNode>[
      FluentSankeyNode(nodeId: 0, name: 'Location 1'),
      FluentSankeyNode(nodeId: 1, name: 'Location 2'),
      FluentSankeyNode(nodeId: 2, name: 'Location 3'),
      FluentSankeyNode(nodeId: 3, name: 'Location 4'),
      FluentSankeyNode(nodeId: 4, name: 'Location 5'),
      FluentSankeyNode(nodeId: 5, name: 'Location 6'),
      FluentSankeyNode(nodeId: 6, name: 'Location 7'),
      FluentSankeyNode(nodeId: 7, name: 'Location 8'),
      FluentSankeyNode(nodeId: 8, name: 'Other'),
      FluentSankeyNode(nodeId: 9, name: 'Location 9'),
      FluentSankeyNode(nodeId: 10, name: 'Location 10'),
      FluentSankeyNode(nodeId: 11, name: 'Location 11'),
      FluentSankeyNode(nodeId: 12, name: 'Location 12'),
      FluentSankeyNode(nodeId: 13, name: 'Location 13'),
      FluentSankeyNode(nodeId: 14, name: 'Location 14'),
      FluentSankeyNode(nodeId: 15, name: 'Device 1'),
      FluentSankeyNode(nodeId: 16, name: 'Device 2'),
      FluentSankeyNode(nodeId: 17, name: 'Device 3'),
      FluentSankeyNode(nodeId: 18, name: 'Device 4'),
      FluentSankeyNode(nodeId: 19, name: 'Other'),
      FluentSankeyNode(nodeId: 20, name: 'Device 5'),
      FluentSankeyNode(nodeId: 21, name: 'Device 6'),
      FluentSankeyNode(nodeId: 22, name: 'Device 7'),
      FluentSankeyNode(nodeId: 23, name: 'Device 8'),
      FluentSankeyNode(nodeId: 24, name: 'Device 9'),
      FluentSankeyNode(
        nodeId: 25,
        name: 'Application 1 (00000000-0000-0000-0000-000000000001)',
      ),
      FluentSankeyNode(
        nodeId: 26,
        name: 'Application 2 (00000000-0000-0000-0000-000000000002)',
      ),
      FluentSankeyNode(nodeId: 27, name: 'Application 3'),
      FluentSankeyNode(
        nodeId: 28,
        name: 'Application 4 with a long trimmed name',
      ),
      FluentSankeyNode(nodeId: 29, name: 'Application 5'),
      FluentSankeyNode(nodeId: 30, name: 'Other'),
      FluentSankeyNode(nodeId: 31, name: 'Application 6'),
      FluentSankeyNode(
        nodeId: 32,
        name: 'Application 7 with an even longer trimmed name',
      ),
      FluentSankeyNode(nodeId: 33, name: 'Application 8'),
      FluentSankeyNode(nodeId: 34, name: 'Application 9'),
      FluentSankeyNode(
        nodeId: 35,
        name: 'Application 10 with some extraneous text',
      ),
      FluentSankeyNode(
        nodeId: 36,
        name: 'Application 11 which is also trimmed',
      ),
      FluentSankeyNode(nodeId: 37, name: 'Application 12'),
      FluentSankeyNode(
        nodeId: 38,
        name: 'Application 13 and which is longer than any other title',
      ),
      FluentSankeyNode(nodeId: 39, name: 'Application 14'),
      FluentSankeyNode(nodeId: 40, name: 'Conditional access not applied'),
      FluentSankeyNode(
        nodeId: 41,
        name: 'All conditional access controls not satisfied',
      ),
      FluentSankeyNode(
        nodeId: 42,
        name: 'All conditional access controls satisfied',
      ),
    ],
    links: <FluentSankeyLink>[
      FluentSankeyLink(source: 0, target: 15, value: 26),
      FluentSankeyLink(source: 0, target: 16, value: 5),
      FluentSankeyLink(source: 0, target: 18, value: 43),
      FluentSankeyLink(source: 0, target: 21, value: 390),
      FluentSankeyLink(source: 0, target: 22, value: 6),
      FluentSankeyLink(source: 1, target: 15, value: 5739),
      FluentSankeyLink(source: 1, target: 16, value: 2642),
      FluentSankeyLink(source: 1, target: 17, value: 2818),
      FluentSankeyLink(source: 1, target: 18, value: 5177),
      FluentSankeyLink(source: 1, target: 19, value: 937),
      FluentSankeyLink(source: 1, target: 20, value: 481),
      FluentSankeyLink(source: 1, target: 21, value: 116477),
      FluentSankeyLink(source: 1, target: 22, value: 7180),
      FluentSankeyLink(source: 1, target: 23, value: 69),
      FluentSankeyLink(source: 2, target: 15, value: 2792),
      FluentSankeyLink(source: 2, target: 16, value: 1866),
      FluentSankeyLink(source: 2, target: 18, value: 1711),
      FluentSankeyLink(source: 2, target: 19, value: 517),
      FluentSankeyLink(source: 2, target: 20, value: 1270),
      FluentSankeyLink(source: 2, target: 21, value: 53190),
      FluentSankeyLink(source: 2, target: 17, value: 66),
      FluentSankeyLink(source: 3, target: 15, value: 42472),
      FluentSankeyLink(source: 3, target: 16, value: 2656),
      FluentSankeyLink(source: 3, target: 17, value: 1409),
      FluentSankeyLink(source: 3, target: 18, value: 2881),
      FluentSankeyLink(source: 3, target: 19, value: 595),
      FluentSankeyLink(source: 3, target: 20, value: 188),
      FluentSankeyLink(source: 3, target: 21, value: 93512),
      FluentSankeyLink(source: 3, target: 22, value: 8979),
      FluentSankeyLink(source: 3, target: 23, value: 329),
      FluentSankeyLink(source: 4, target: 15, value: 2860),
      FluentSankeyLink(source: 4, target: 16, value: 1871),
      FluentSankeyLink(source: 4, target: 18, value: 6179),
      FluentSankeyLink(source: 4, target: 19, value: 423),
      FluentSankeyLink(source: 4, target: 20, value: 377),
      FluentSankeyLink(source: 4, target: 21, value: 243939),
      FluentSankeyLink(source: 4, target: 17, value: 169),
      FluentSankeyLink(source: 4, target: 22, value: 5),
      FluentSankeyLink(source: 4, target: 23, value: 15),
      FluentSankeyLink(source: 5, target: 15, value: 662),
      FluentSankeyLink(source: 5, target: 16, value: 455),
      FluentSankeyLink(source: 5, target: 18, value: 520),
      FluentSankeyLink(source: 5, target: 21, value: 22372),
      FluentSankeyLink(source: 5, target: 17, value: 7),
      FluentSankeyLink(source: 5, target: 19, value: 14),
      FluentSankeyLink(source: 5, target: 20, value: 4),
      FluentSankeyLink(source: 5, target: 23, value: 8),
      FluentSankeyLink(source: 6, target: 15, value: 4151),
      FluentSankeyLink(source: 6, target: 16, value: 1119),
      FluentSankeyLink(source: 6, target: 18, value: 1428),
      FluentSankeyLink(source: 6, target: 21, value: 139402),
      FluentSankeyLink(source: 6, target: 17, value: 109),
      FluentSankeyLink(source: 6, target: 19, value: 141),
      FluentSankeyLink(source: 6, target: 20, value: 365),
      FluentSankeyLink(source: 6, target: 22, value: 3),
      FluentSankeyLink(source: 7, target: 15, value: 1819),
      FluentSankeyLink(source: 7, target: 16, value: 655),
      FluentSankeyLink(source: 7, target: 18, value: 2120),
      FluentSankeyLink(source: 7, target: 19, value: 304),
      FluentSankeyLink(source: 7, target: 20, value: 215),
      FluentSankeyLink(source: 7, target: 21, value: 64271),
      FluentSankeyLink(source: 7, target: 17, value: 119),
      FluentSankeyLink(source: 7, target: 22, value: 18),
      FluentSankeyLink(source: 8, target: 15, value: 4132),
      FluentSankeyLink(source: 8, target: 16, value: 2530),
      FluentSankeyLink(source: 8, target: 17, value: 917),
      FluentSankeyLink(source: 8, target: 18, value: 4972),
      FluentSankeyLink(source: 8, target: 19, value: 333),
      FluentSankeyLink(source: 8, target: 20, value: 168),
      FluentSankeyLink(source: 8, target: 21, value: 107869),
      FluentSankeyLink(source: 8, target: 22, value: 119),
      FluentSankeyLink(source: 8, target: 23, value: 1007),
      FluentSankeyLink(source: 8, target: 24, value: 13),
      FluentSankeyLink(source: 9, target: 15, value: 807),
      FluentSankeyLink(source: 9, target: 16, value: 101),
      FluentSankeyLink(source: 9, target: 18, value: 138),
      FluentSankeyLink(source: 9, target: 19, value: 9),
      FluentSankeyLink(source: 9, target: 20, value: 8),
      FluentSankeyLink(source: 9, target: 21, value: 6467),
      FluentSankeyLink(source: 9, target: 22, value: 4),
      FluentSankeyLink(source: 10, target: 15, value: 1360),
      FluentSankeyLink(source: 10, target: 16, value: 4616),
      FluentSankeyLink(source: 10, target: 17, value: 132),
      FluentSankeyLink(source: 10, target: 18, value: 1042),
      FluentSankeyLink(source: 10, target: 20, value: 99),
      FluentSankeyLink(source: 10, target: 21, value: 41812),
      FluentSankeyLink(source: 10, target: 22, value: 76),
      FluentSankeyLink(source: 10, target: 19, value: 72),
      FluentSankeyLink(source: 11, target: 15, value: 2215),
      FluentSankeyLink(source: 11, target: 16, value: 546),
      FluentSankeyLink(source: 11, target: 17, value: 165),
      FluentSankeyLink(source: 11, target: 18, value: 327),
      FluentSankeyLink(source: 11, target: 19, value: 19),
      FluentSankeyLink(source: 11, target: 20, value: 37),
      FluentSankeyLink(source: 11, target: 21, value: 19043),
      FluentSankeyLink(source: 11, target: 22, value: 7),
      FluentSankeyLink(source: 11, target: 23, value: 2455),
      FluentSankeyLink(source: 12, target: 15, value: 1041),
      FluentSankeyLink(source: 12, target: 16, value: 450),
      FluentSankeyLink(source: 12, target: 17, value: 6),
      FluentSankeyLink(source: 12, target: 18, value: 945),
      FluentSankeyLink(source: 12, target: 19, value: 41),
      FluentSankeyLink(source: 12, target: 20, value: 41),
      FluentSankeyLink(source: 12, target: 21, value: 19337),
      FluentSankeyLink(source: 12, target: 22, value: 6),
      FluentSankeyLink(source: 13, target: 15, value: 204),
      FluentSankeyLink(source: 13, target: 16, value: 71),
      FluentSankeyLink(source: 13, target: 17, value: 29),
      FluentSankeyLink(source: 13, target: 18, value: 58),
      FluentSankeyLink(source: 13, target: 21, value: 5171),
      FluentSankeyLink(source: 13, target: 22, value: 51),
      FluentSankeyLink(source: 13, target: 23, value: 12),
      FluentSankeyLink(source: 14, target: 15, value: 103),
      FluentSankeyLink(source: 14, target: 16, value: 40),
      FluentSankeyLink(source: 14, target: 18, value: 4),
      FluentSankeyLink(source: 14, target: 20, value: 5),
      FluentSankeyLink(source: 14, target: 21, value: 4958),
      FluentSankeyLink(source: 15, target: 25, value: 387),
      FluentSankeyLink(source: 15, target: 26, value: 752),
      FluentSankeyLink(source: 15, target: 27, value: 3750),
      FluentSankeyLink(source: 15, target: 28, value: 20),
      FluentSankeyLink(source: 15, target: 30, value: 28987),
      FluentSankeyLink(source: 15, target: 35, value: 35959),
      FluentSankeyLink(source: 15, target: 36, value: 229),
      FluentSankeyLink(source: 15, target: 37, value: 37),
      FluentSankeyLink(source: 15, target: 38, value: 242),
      FluentSankeyLink(source: 15, target: 32, value: 17),
      FluentSankeyLink(source: 15, target: 39, value: 3),
      FluentSankeyLink(source: 16, target: 25, value: 223),
      FluentSankeyLink(source: 16, target: 26, value: 816),
      FluentSankeyLink(source: 16, target: 27, value: 3527),
      FluentSankeyLink(source: 16, target: 28, value: 5),
      FluentSankeyLink(source: 16, target: 30, value: 12394),
      FluentSankeyLink(source: 16, target: 35, value: 2210),
      FluentSankeyLink(source: 16, target: 36, value: 185),
      FluentSankeyLink(source: 16, target: 37, value: 36),
      FluentSankeyLink(source: 16, target: 38, value: 218),
      FluentSankeyLink(source: 16, target: 39, value: 9),
      FluentSankeyLink(source: 17, target: 25, value: 16),
      FluentSankeyLink(source: 17, target: 28, value: 2),
      FluentSankeyLink(source: 17, target: 29, value: 23),
      FluentSankeyLink(source: 17, target: 30, value: 4858),
      FluentSankeyLink(source: 17, target: 35, value: 981),
      FluentSankeyLink(source: 17, target: 26, value: 15),
      FluentSankeyLink(source: 17, target: 36, value: 5),
      FluentSankeyLink(source: 17, target: 37, value: 40),
      FluentSankeyLink(source: 17, target: 38, value: 6),
      FluentSankeyLink(source: 18, target: 25, value: 4131),
      FluentSankeyLink(source: 18, target: 26, value: 1163),
      FluentSankeyLink(source: 18, target: 27, value: 1080),
      FluentSankeyLink(source: 18, target: 28, value: 29),
      FluentSankeyLink(source: 18, target: 29, value: 5),
      FluentSankeyLink(source: 18, target: 30, value: 15157),
      FluentSankeyLink(source: 18, target: 32, value: 3445),
      FluentSankeyLink(source: 18, target: 36, value: 248),
      FluentSankeyLink(source: 18, target: 37, value: 1768),
      FluentSankeyLink(source: 18, target: 38, value: 471),
      FluentSankeyLink(source: 18, target: 35, value: 48),
      FluentSankeyLink(source: 19, target: 25, value: 63),
      FluentSankeyLink(source: 19, target: 30, value: 3331),
      FluentSankeyLink(source: 19, target: 26, value: 11),
      FluentSankeyLink(source: 20, target: 25, value: 218),
      FluentSankeyLink(source: 20, target: 28, value: 3),
      FluentSankeyLink(source: 20, target: 29, value: 12),
      FluentSankeyLink(source: 20, target: 30, value: 2989),
      FluentSankeyLink(source: 20, target: 26, value: 7),
      FluentSankeyLink(source: 20, target: 27, value: 16),
      FluentSankeyLink(source: 20, target: 36, value: 10),
      FluentSankeyLink(source: 20, target: 31, value: 3),
      FluentSankeyLink(source: 21, target: 25, value: 57044),
      FluentSankeyLink(source: 21, target: 26, value: 32830),
      FluentSankeyLink(source: 21, target: 27, value: 21688),
      FluentSankeyLink(source: 21, target: 28, value: 334),
      FluentSankeyLink(source: 21, target: 29, value: 441),
      FluentSankeyLink(source: 21, target: 30, value: 382230),
      FluentSankeyLink(source: 21, target: 31, value: 96755),
      FluentSankeyLink(source: 21, target: 32, value: 224816),
      FluentSankeyLink(source: 21, target: 33, value: 7449),
      FluentSankeyLink(source: 21, target: 34, value: 26682),
      FluentSankeyLink(source: 21, target: 35, value: 22242),
      FluentSankeyLink(source: 21, target: 36, value: 25911),
      FluentSankeyLink(source: 21, target: 37, value: 17637),
      FluentSankeyLink(source: 21, target: 38, value: 17163),
      FluentSankeyLink(source: 21, target: 39, value: 4988),
      FluentSankeyLink(source: 22, target: 25, value: 5825),
      FluentSankeyLink(source: 22, target: 26, value: 3232),
      FluentSankeyLink(source: 22, target: 27, value: 22),
      FluentSankeyLink(source: 22, target: 30, value: 6278),
      FluentSankeyLink(source: 22, target: 36, value: 22),
      FluentSankeyLink(source: 22, target: 37, value: 850),
      FluentSankeyLink(source: 22, target: 38, value: 36),
      FluentSankeyLink(source: 22, target: 35, value: 187),
      FluentSankeyLink(source: 22, target: 39, value: 2),
      FluentSankeyLink(source: 23, target: 25, value: 851),
      FluentSankeyLink(source: 23, target: 30, value: 2916),
      FluentSankeyLink(source: 23, target: 26, value: 66),
      FluentSankeyLink(source: 23, target: 27, value: 2),
      FluentSankeyLink(source: 23, target: 36, value: 7),
      FluentSankeyLink(source: 23, target: 37, value: 23),
      FluentSankeyLink(source: 23, target: 38, value: 23),
      FluentSankeyLink(source: 23, target: 35, value: 7),
      FluentSankeyLink(source: 24, target: 37, value: 1),
      FluentSankeyLink(source: 24, target: 30, value: 12),
      FluentSankeyLink(source: 25, target: 40, value: 3584),
      FluentSankeyLink(source: 25, target: 41, value: 9118),
      FluentSankeyLink(source: 25, target: 42, value: 56056),
      FluentSankeyLink(source: 26, target: 40, value: 1070),
      FluentSankeyLink(source: 26, target: 41, value: 2326),
      FluentSankeyLink(source: 26, target: 42, value: 35496),
      FluentSankeyLink(source: 27, target: 40, value: 2644),
      FluentSankeyLink(source: 27, target: 41, value: 12690),
      FluentSankeyLink(source: 27, target: 42, value: 14751),
      FluentSankeyLink(source: 28, target: 40, value: 10),
      FluentSankeyLink(source: 28, target: 41, value: 21),
      FluentSankeyLink(source: 28, target: 42, value: 362),
      FluentSankeyLink(source: 29, target: 40, value: 18),
      FluentSankeyLink(source: 29, target: 41, value: 126),
      FluentSankeyLink(source: 29, target: 42, value: 337),
      FluentSankeyLink(source: 30, target: 40, value: 32459),
      FluentSankeyLink(source: 30, target: 41, value: 46566),
      FluentSankeyLink(source: 30, target: 42, value: 380127),
      FluentSankeyLink(source: 31, target: 40, value: 3012),
      FluentSankeyLink(source: 31, target: 42, value: 93746),
      FluentSankeyLink(source: 32, target: 40, value: 1675),
      FluentSankeyLink(source: 32, target: 41, value: 106838),
      FluentSankeyLink(source: 32, target: 42, value: 119765),
      FluentSankeyLink(source: 33, target: 40, value: 17),
      FluentSankeyLink(source: 33, target: 41, value: 306),
      FluentSankeyLink(source: 33, target: 42, value: 7126),
      FluentSankeyLink(source: 34, target: 40, value: 209),
      FluentSankeyLink(source: 34, target: 42, value: 26471),
      FluentSankeyLink(source: 34, target: 41, value: 2),
      FluentSankeyLink(source: 35, target: 40, value: 10112),
      FluentSankeyLink(source: 35, target: 41, value: 19924),
      FluentSankeyLink(source: 35, target: 42, value: 31598),
      FluentSankeyLink(source: 36, target: 40, value: 519),
      FluentSankeyLink(source: 36, target: 41, value: 1024),
      FluentSankeyLink(source: 36, target: 42, value: 25074),
      FluentSankeyLink(source: 37, target: 40, value: 720),
      FluentSankeyLink(source: 37, target: 41, value: 3592),
      FluentSankeyLink(source: 37, target: 42, value: 16080),
      FluentSankeyLink(source: 38, target: 40, value: 194),
      FluentSankeyLink(source: 38, target: 41, value: 508),
      FluentSankeyLink(source: 38, target: 42, value: 17457),
      FluentSankeyLink(source: 39, target: 40, value: 285),
      FluentSankeyLink(source: 39, target: 41, value: 3),
      FluentSankeyLink(source: 39, target: 42, value: 4714),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final FluentSankeyChartData data = _simple ? _dataSimple : _dataComplex;

    // Upstream drives the demo from two `<input type="range">` controls; the
    // nearest Fluent widget is FluentSlider, and its `semanticLabel` carries the
    // `aria-label` upstream sets. The chart box is a fixed pixel `<div>` upstream,
    // so it is wrapped in a horizontal scroller here rather than overflowing a
    // narrower docs column.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FluentSwitch(
          checked: _simple,
          label: Text('Data Source: ${_simple ? 'simple' : 'complex'}'),
          onChanged: (bool value) => setState(() => _simple = value),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('change Width:'),
            SizedBox(
              width: 140,
              child: FluentSlider(
                value: _width,
                min: 400,
                max: 1600,
                semanticLabel: 'Change Width',
                onChanged: (double value) => setState(() => _width = value),
              ),
            ),
            const SizedBox(width: 12),
            const Text('change Height:'),
            SizedBox(
              width: 140,
              child: FluentSlider(
                value: _height,
                min: 312,
                max: 400,
                semanticLabel: 'Change Height',
                onChanged: (double value) => setState(() => _height = value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: _width,
            height: _height,
            child: FluentSankeyChart(
              data: data,
              chartTitle: 'Sankey Chart',
              linkFromLabel: 'from {0}',
              emptySemanticLabel: 'Graph has no data to display',
              nodeSemanticLabel: '{0} with {1} sign-ins',
              linkSemanticLabel: '{2} sign-ins from {0} and {1}',
              reflowMode: FluentSankeyReflowMode.minWidth,
            ),
          ),
        ),
      ],
    );
  }
}
// #enddocregion charts-sankeychart--sankey-chart-rebalance

// #docregion charts-sankeychart--sankey-chart-responsive
Widget _sankeyChartResponsive(BuildContext context) {
  final FluentSankeyChartData data = FluentSankeyChartData(
    nodes: <FluentSankeyNode>[
      FluentSankeyNode(
        nodeId: 0,
        name: 'node0',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color11),
        borderColor: FluentDataVizPalette.resolve(FluentDataVizToken.color21),
      ),
      FluentSankeyNode(
        nodeId: 1,
        name: 'node1',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color12),
        borderColor: FluentDataVizPalette.resolve(FluentDataVizToken.color22),
      ),
      FluentSankeyNode(
        nodeId: 2,
        name: 'node2',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color13),
        borderColor: FluentDataVizPalette.resolve(FluentDataVizToken.color23),
      ),
      FluentSankeyNode(
        nodeId: 3,
        name: 'node3',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color14),
        borderColor: FluentDataVizPalette.resolve(FluentDataVizToken.color24),
      ),
      FluentSankeyNode(
        nodeId: 4,
        name: 'node4',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
        borderColor: FluentDataVizPalette.resolve(FluentDataVizToken.color22),
      ),
      FluentSankeyNode(
        nodeId: 5,
        name: 'node5',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color15),
        borderColor: FluentDataVizPalette.resolve(FluentDataVizToken.color25),
      ),
    ],
    links: <FluentSankeyLink>[
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

  // Upstream wraps this in a `ResponsiveContainer`. FluentSankeyChart already
  // fills whatever box it is given and falls back to its own default size on an
  // unbounded constraint, so the container is just the box.
  return FluentSankeyChart(data: data, chartTitle: 'Sankey Chart');
}

// #enddocregion charts-sankeychart--sankey-chart-responsive
