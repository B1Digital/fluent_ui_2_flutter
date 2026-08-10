import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:fluent_2_web/src/charts/internal/d3/sankey.dart';
import 'package:fluent_2_web/src/charts/sankey_chart_layout.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// `SankeyChart.tsx:180-216` is the value-normalisation pass that runs between the two
/// `sankey()` calls; every literal in it changes the rendered node heights.
void main() {
  SankeyLayoutNode nodeWith(double value, {double y0 = 0, double y1 = 0}) =>
      SankeyLayoutNode()
        ..value = value
        ..y0 = y0
        ..y1 = y1;

  test('the palette is the ten upstream fill and border pairs', () {
    expect(
      kSankeyDefaultNodeColors.length,
      10,
      reason: 'SankeyChart.tsx:41-52',
    );
    expect(
      kSankeyDefaultNodeColors.first.$1.toARGB32(),
      0xFF00758F,
      reason: 'SankeyChart.tsx:42 fillColor',
    );
    expect(
      kSankeyDefaultNodeColors.first.$2.toARGB32(),
      0xFF002E39,
      reason: 'SankeyChart.tsx:42 borderColor',
    );
    expect(
      kSankeyDefaultNodeColors.last.$2.toARGB32(),
      0xFF6D4123,
      reason: 'SankeyChart.tsx:51',
    );
  });

  test('the module constants come from SankeyChart.tsx:23-62', () {
    expect(kSankeyNodeWidth, 124, reason: 'SankeyChart.tsx:62');
    expect(kSankeyMinHeightForType, 24, reason: 'SankeyChart.tsx:55');
    expect(kSankeyMinHeightForDoubleLine, 36, reason: 'SankeyChart.tsx:54');
    expect(kSankeyPaddingPercentage, 0.3, reason: 'SankeyChart.tsx:23');
    expect(kSankeySelectedStreamOpacity, 0.3, reason: 'SankeyChart.tsx:58');
    expect(
      kSankeyNonSelectedStreamBorderOpacity,
      0.5,
      reason: 'SankeyChart.tsx:59',
    );
    expect(
      kSankeyNonSelectedColor.toARGB32(),
      0xFF757575,
      reason: 'SankeyChart.tsx:40',
    );
    expect(
      kSankeyDefaultTextColor.toARGB32(),
      0xFF323130,
      reason: 'SankeyChart.tsx:60',
    );
    expect(
      kSankeyNonSelectedTextColor.toARGB32(),
      0xFFFFFFFF,
      reason: 'SankeyChart.tsx:61',
    );
    expect(kSankeyNodeStrokeWidth, 2, reason: 'SankeyChart.tsx:817');
    expect(kSankeyLinkStrokeWidth, 2, reason: 'SankeyChart.tsx:764');
    expect(kSankeyMarginHorizontal, 48, reason: 'SankeyChart.tsx:561');
    expect(kSankeyMarginBottom, 32, reason: 'SankeyChart.tsx:561');
    expect(kSankeyMinTitleHeight, 36, reason: 'SankeyChart.tsx:554-560');
    expect(
      kSankeyBorderOnlyFill.toARGB32(),
      0xFFF5F5F5,
      reason: 'SankeyChart.tsx:375',
    );
  });

  test('nodes group by their layer', () {
    final a = SankeyLayoutNode()..layer = 0;
    final b = SankeyLayoutNode()..layer = 1;
    final c = SankeyLayoutNode()..layer = 0;
    final columns = groupSankeyNodesByColumn(<SankeyLayoutNode>[a, b, c]);
    expect(columns.keys.toList()..sort(), <int>[0, 1], reason: 'two layers');
    expect(
      columns[0],
      <SankeyLayoutNode>[a, c],
      reason: 'SankeyChart.tsx:166-173 preserves node order within a column',
    );
  });

  test('a sub-one-percent node is lifted to exactly one percent', () {
    final small = nodeWith(0.3);
    final big = nodeWith(99.7);
    final columns = <int, List<SankeyLayoutNode>>{
      0: <SankeyLayoutNode>[small, big],
    };
    final actual = <double>[0, 0];
    small.index = 0;
    big.index = 1;
    adjustSankeyOnePercentHeightNodes(
      columns: columns,
      nodeValues: <double>[0.3, 99.7],
      linkValues: <double>[],
      actualValues: actual,
      unnormalisedValues: <double?>[],
    );
    expect(
      actual[0],
      0.3,
      reason: 'SankeyChart.tsx:195 records the pre-normalisation value',
    );
    // totalPercentage = 1 + 99.7 = 100.7, scalingRatio = 1.007.
    expect(
      small.value,
      closeTo(1.0 / 1.007, 1e-12),
      reason:
          'SankeyChart.tsx:198 raises it to 0.01 * 100 = 1, then :210 divides by '
          'the scaling ratio of 100.7 / 100',
    );
    expect(
      big.value,
      closeTo(99.7 / 1.007, 1e-12),
      reason: 'every node in the column is scaled, not just the lifted one',
    );
  });

  test('a column that already sums under 100 percent is left alone', () {
    final a = nodeWith(50)..index = 0;
    final b = nodeWith(50)..index = 1;
    adjustSankeyOnePercentHeightNodes(
      columns: <int, List<SankeyLayoutNode>>{
        0: <SankeyLayoutNode>[a, b],
      },
      nodeValues: <double>[50, 50],
      linkValues: <double>[],
      actualValues: <double>[0, 0],
      unnormalisedValues: <double?>[],
    );
    expect(
      a.value,
      50,
      reason: 'SankeyChart.tsx:206 only scales when the ratio exceeds 1',
    );
  });

  test('link values follow their node up, taking the larger of the two', () {
    final small = nodeWith(0.3)..index = 0;
    final big = nodeWith(99.7)..index = 1;
    final link = SankeyLayoutLink(source: small, target: big, value: 0.3)
      ..index = 0;
    small.sourceLinks.add(link);
    big.targetLinks.add(link);
    final unnormalised = <double?>[null];
    adjustSankeyOnePercentHeightNodes(
      columns: <int, List<SankeyLayoutNode>>{
        0: <SankeyLayoutNode>[small, big],
      },
      nodeValues: <double>[0.3, 99.7],
      linkValues: <double>[0.3],
      actualValues: <double>[0, 0],
      unnormalisedValues: unnormalised,
    );
    expect(
      unnormalised[0],
      0.3,
      reason: 'SankeyChart.tsx:231 records the original link value',
    );
    expect(
      link.value,
      closeTo(1.0 / 1.007, 1e-12),
      reason:
          'SankeyChart.tsx:233 — max(normalisedNodeValue * linkRatio, link.value) '
          'with a ratio of 1 lifts the link to the normalised node value',
    );
  });

  test('padding shrinks only when the column is crowded', () {
    final sankey = Sankey()..nodePadding(8);
    final crowded = <SankeyLayoutNode>[
      for (var i = 0; i < 5; i++) nodeWith(1, y1: 19),
    ];
    // height 100, occupied 5 * 19 = 95, free 5; minPadding = 30 > 5 so no change.
    adjustSankeyPadding(sankey, 100, <int, List<SankeyLayoutNode>>{0: crowded});
    expect(
      sankey.currentNodePadding,
      8,
      reason:
          'SankeyChart.tsx:265 only tightens when minPadding is below the free '
          'space in the column',
    );

    final sparse = <SankeyLayoutNode>[
      for (var i = 0; i < 5; i++) nodeWith(1, y1: 2),
    ];
    final sankey2 = Sankey()..nodePadding(8);
    // free space 90 > minPadding 30, so padding drops to 30 / 4 = 7.5.
    adjustSankeyPadding(sankey2, 100, <int, List<SankeyLayoutNode>>{0: sparse});
    expect(
      sankey2.currentNodePadding,
      closeTo(7.5, 1e-12),
      reason: 'SankeyChart.tsx:268 — min(8, 0.3 * 100 / (5 - 1))',
    );
  });

  test('a one-node column divides by zero and keeps the default padding', () {
    final sankey = Sankey()..nodePadding(8);
    adjustSankeyPadding(sankey, 100, <int, List<SankeyLayoutNode>>{
      0: <SankeyLayoutNode>[nodeWith(1, y1: 2)],
    });
    expect(
      sankey.currentNodePadding,
      8,
      reason:
          'SankeyChart.tsx:268 divides by column.length - 1, which is 0 here; '
          'Infinity loses the Math.min and 8 survives',
    );
  });

  test('node colours cycle, and a half-specified pair is completed', () {
    final result = assignSankeyNodeColors(const <FluentSankeyNode>[
      FluentSankeyNode(nodeId: 0, name: 'a'),
      FluentSankeyNode(nodeId: 1, name: 'b', color: Color(0xFF112233)),
      FluentSankeyNode(nodeId: 2, name: 'c', borderColor: Color(0xFF445566)),
    ]);
    expect(
      result.fills[0].toARGB32(),
      kSankeyDefaultNodeColors[0].$1.toARGB32(),
      reason: 'SankeyChart.tsx:369-371 takes the pair at the current index',
    );
    expect(
      result.borders[1].toARGB32(),
      0xFF757575,
      reason: 'SankeyChart.tsx:373 — a fill without a border gets #757575',
    );
    expect(
      result.fills[2].toARGB32(),
      0xFFF5F5F5,
      reason: 'SankeyChart.tsx:375 — a border without a fill gets #F5F5F5',
    );
  });

  test('a custom palette is used only when both lists are supplied', () {
    final partial = assignSankeyNodeColors(
      const <FluentSankeyNode>[FluentSankeyNode(nodeId: 0, name: 'a')],
      colorsForNodes: const <Color>[Color(0xFF010203)],
    );
    expect(
      partial.fills.first.toARGB32(),
      kSankeyDefaultNodeColors[0].$1.toARGB32(),
      reason:
          'SankeyChart.tsx:360-366 needs BOTH arrays or it uses the defaults',
    );
  });

  test('the minimum chart width scales with the column count', () {
    expect(
      calculateSankeyChartMinWidth(3),
      48 + 48 + 3 * 124 + 2 * 62,
      reason: 'SankeyChart.tsx:1012-1021 — NODE_WIDTH / 2 is the column gap',
    );
  });

  test('the template formatter drops missing arguments', () {
    expect(
      formatSankeyTemplate('link from {0} to {1} with weight {2}', <Object?>[
        'A',
        'B',
        '7',
      ]),
      'link from A to B with weight 7',
      reason: 'utilities/string.ts:21-37',
    );
    expect(
      formatSankeyTemplate('From {0}', <Object?>[null]),
      'From ',
      reason: 'utilities/string.ts:30-32 substitutes an empty string for null',
    );
  });
}
