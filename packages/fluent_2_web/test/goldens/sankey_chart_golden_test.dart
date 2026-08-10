import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Two cells: a plain three-column flow, and the same flow with a title and one node
/// carrying under one percent of its column, which is what exercises the value
/// normalisation and the single-line node text.
void main() {
  const flow = FluentSankeyChartData(
    nodes: <FluentSankeyNode>[
      FluentSankeyNode(nodeId: 0, name: 'Inbox'),
      FluentSankeyNode(nodeId: 1, name: 'Archive'),
      FluentSankeyNode(nodeId: 2, name: 'Deleted'),
      FluentSankeyNode(nodeId: 3, name: 'Retained forever'),
    ],
    links: <FluentSankeyLink>[
      FluentSankeyLink(source: 0, target: 1, value: 700),
      FluentSankeyLink(source: 0, target: 2, value: 300),
      FluentSankeyLink(source: 1, target: 3, value: 700),
      FluentSankeyLink(source: 2, target: 3, value: 300),
    ],
  );

  const skewed = FluentSankeyChartData(
    nodes: <FluentSankeyNode>[
      FluentSankeyNode(nodeId: 0, name: 'Bulk'),
      FluentSankeyNode(nodeId: 1, name: 'Trickle'),
      FluentSankeyNode(nodeId: 2, name: 'Sink'),
    ],
    links: <FluentSankeyLink>[
      FluentSankeyLink(source: 0, target: 2, value: 5000),
      FluentSankeyLink(source: 1, target: 2, value: 3),
    ],
  );

  goldenGridTest(
    'sankey_chart',
    () => goldenGrid(<Widget>[
      const SizedBox(
        width: 560,
        height: 300,
        child: FluentSankeyChart(data: flow),
      ),
      const SizedBox(
        width: 560,
        height: 300,
        child: FluentSankeyChart(data: skewed, chartTitle: 'Message flow'),
      ),
    ], columns: 1),
    surfaceSize: const Size(600, 660),
  );
}
