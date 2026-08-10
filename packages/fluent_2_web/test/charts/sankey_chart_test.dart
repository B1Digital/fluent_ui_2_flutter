import 'package:fluent_2_web/fluent_2_web.dart';
// `sankey_chart.dart` and `sankey_chart_layout.dart` are not barrel-exported yet
// — the integration task owns `lib/fluent_2_web.dart`, so the test reaches for
// the libraries directly, exactly as `sankey_chart_layout_test.dart` does.
import 'package:fluent_2_web/src/charts/sankey_chart.dart';
import 'package:fluent_2_web/src/charts/sankey_chart_layout.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// `SankeyChart.tsx:65-158` builds the selection sets and `:933-991` turns them into
/// colours and opacities. The matrix is small and every arm is reachable.
void main() {
  /// A → B → C plus a skip link A → C, so a node hover has something to exclude.
  const data = FluentSankeyChartData(
    nodes: <FluentSankeyNode>[
      FluentSankeyNode(nodeId: 0, name: 'A'),
      FluentSankeyNode(nodeId: 1, name: 'B'),
      FluentSankeyNode(nodeId: 2, name: 'C'),
      FluentSankeyNode(nodeId: 3, name: 'D'),
    ],
    links: <FluentSankeyLink>[
      FluentSankeyLink(source: 0, target: 1, value: 5),
      FluentSankeyLink(source: 1, target: 2, value: 5),
      FluentSankeyLink(source: 3, target: 2, value: 5),
    ],
  );

  final layout = computeFluentSankeyLayout(
    data: data,
    // 912x468 are the upstream container defaults (`SankeyChart.tsx:571-572`).
    size: const Size(912, 468),
    titleHeight: kSankeyMinTitleHeight,
    isRtl: false,
  );

  test('hovering a node selects its whole connected path', () {
    final selection = FluentSankeySelection.forNode(layout.nodes[0]);
    expect(
      selection.linkIndices,
      <int>{0, 1},
      reason:
          'SankeyChart.tsx:82-96 walks forward through sourceLinks, so A picks up '
          'A->B and B->C but not D->C',
    );
    expect(
      selection.nodeIndices,
      <int>{0, 1, 2},
      reason: 'SankeyChart.tsx:65-75 plus the hovered node itself at :879',
    );
    expect(
      selection.selectedNode,
      0,
      reason: 'SankeyChart.tsx:883 records the hovered node',
    );
  });

  test('hovering a downstream node also walks backwards', () {
    final selection = FluentSankeySelection.forNode(layout.nodes[2]);
    expect(
      selection.linkIndices,
      <int>{0, 1, 2},
      reason:
          'SankeyChart.tsx:98-114 walks backwards through targetLinks, so C '
          'reaches every upstream link',
    );
  });

  test('hovering a stream leaves selectedNode unset', () {
    final selection = FluentSankeySelection.forLink(layout.links[1]);
    expect(
      selection.selectedNode,
      isNull,
      reason:
          'SankeyChart.tsx:891-900 never calls setSelectedNode, which is what '
          'switches the whole visual resolution into gradient mode',
    );
    expect(
      selection.linkIndices,
      <int>{0, 1},
      reason:
          'SankeyChart.tsx:119-152 walks upstream from the source and downstream '
          'from the target of the hovered link',
    );
    expect(
      selection.nodeIndices,
      <int>{0, 1, 2},
      reason: 'the touched nodes are collected on both walks',
    );
  });

  test('the idle state paints every node in its own colours', () {
    expect(
      FluentSankeySelection.none.nodeFill(0, layout).toARGB32(),
      layout.nodeColors[0].toARGB32(),
      reason: 'SankeyChart.tsx:934-935',
    );
    expect(
      FluentSankeySelection.none.linkFill(0, layout),
      isNull,
      reason:
          'SankeyChart.tsx:946-950 returns undefined, so the stream inherits the '
          'group fill from the stylesheet',
    );
    expect(
      FluentSankeySelection.none.linkBorder(0, layout).toARGB32(),
      kSankeyNonSelectedColor.toARGB32(),
      reason: 'SankeyChart.tsx:953-954',
    );
    expect(
      FluentSankeySelection.none.linkFillOpacity(0),
      1,
      reason: 'SankeyChart.tsx:982 — REST_STREAM_OPACITY',
    );
    expect(
      FluentSankeySelection.none.nodeTextColor(0).toARGB32(),
      kSankeyNonSelectedTextColor.toARGB32(),
      reason: 'SankeyChart.tsx:524-530 — the idle state draws white text',
    );
  });

  test('a node hover greys everything outside the path', () {
    final selection = FluentSankeySelection.forNode(layout.nodes[0]);
    expect(
      selection.nodeFill(0, layout).toARGB32(),
      layout.nodeColors[0].toARGB32(),
      reason:
          'SankeyChart.tsx:937-938 repaints every node in the path with the '
          "HOVERED node's colour, and node 0 is the hovered one",
    );
    expect(
      selection.nodeFill(1, layout).toARGB32(),
      layout.nodeColors[0].toARGB32(),
      reason: "a downstream node in the path takes the hovered node's colour",
    );
    expect(
      selection.nodeFill(3, layout).toARGB32(),
      kSankeyNonSelectedColor.toARGB32(),
      reason: 'SankeyChart.tsx:942 greys a node outside the path',
    );
    expect(
      selection.nodeTextColor(3).toARGB32(),
      kSankeyDefaultTextColor.toARGB32(),
      reason: 'SankeyChart.tsx:524-530 — an excluded node gets dark text',
    );
    expect(
      selection.linkFillOpacity(0),
      1,
      reason:
          'SankeyChart.tsx:978 — with a selectedNode set the stream keeps full '
          'opacity even inside the path',
    );
    expect(
      selection.linkBorderOpacity(2),
      1,
      reason:
          'SankeyChart.tsx:986 needs selectedNode to be UNSET before it dims an '
          'excluded stream border',
    );
  });

  test('a stream hover fades the path and dims the rest', () {
    final selection = FluentSankeySelection.forLink(layout.links[1]);
    expect(
      selection.linkFillOpacity(1),
      kSankeySelectedStreamOpacity,
      reason: 'SankeyChart.tsx:979 — 0.3 when no node is selected',
    );
    expect(
      selection.linkFillOpacity(2),
      1,
      reason: 'SankeyChart.tsx:977 — a stream outside the path stays opaque',
    );
    expect(
      selection.linkBorderOpacity(2),
      kSankeyNonSelectedStreamBorderOpacity,
      reason: 'SankeyChart.tsx:986-988 — 0.5 for an excluded border',
    );
    expect(
      selection.linkUsesGradient(1),
      isTrue,
      reason:
          'SankeyChart.tsx:957 hands the gradient url to the stroke when there '
          'is no selectedNode',
    );
    expect(
      selection.linkUsesGradient(2),
      isFalse,
      reason: 'an excluded stream keeps the flat grey border',
    );
  });

  test('an excluded node keeps its own coloured border', () {
    final selection = FluentSankeySelection.forNode(layout.nodes[0]);
    expect(
      selection.nodeBorder(3, layout).toARGB32(),
      layout.nodeBorderColors[3].toARGB32(),
      reason:
          'SankeyChart.tsx:963-972 returns singleNode.borderColor on every arm '
          'but the in-path one, so a greyed node keeps its coloured outline',
    );
    expect(
      selection.nodeBorder(1, layout).toARGB32(),
      layout.nodeBorderColors[0].toARGB32(),
      reason: 'SankeyChart.tsx:967 — an in-path node takes the hovered border',
    );
  });
}
