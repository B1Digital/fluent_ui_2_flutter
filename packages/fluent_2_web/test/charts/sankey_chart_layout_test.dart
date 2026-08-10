import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:fluent_2_web/src/charts/internal/d3/sankey.dart';
import 'package:fluent_2_web/src/charts/sankey_chart_layout.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'd3/golden_support.dart';

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

  group('computeFluentSankeyLayout', () {
    const chain = FluentSankeyChartData(
      nodes: <FluentSankeyNode>[
        FluentSankeyNode(nodeId: 0, name: 'A'),
        FluentSankeyNode(nodeId: 1, name: 'B'),
        FluentSankeyNode(nodeId: 2, name: 'C'),
      ],
      links: <FluentSankeyLink>[
        FluentSankeyLink(source: 0, target: 1, value: 10),
        FluentSankeyLink(source: 1, target: 2, value: 10),
      ],
    );

    const skewed = FluentSankeyChartData(
      nodes: <FluentSankeyNode>[
        FluentSankeyNode(nodeId: 0, name: 'Big'),
        FluentSankeyNode(nodeId: 1, name: 'Tiny'),
        FluentSankeyNode(nodeId: 2, name: 'Sink'),
      ],
      links: <FluentSankeyLink>[
        FluentSankeyLink(source: 0, target: 2, value: 1000),
        FluentSankeyLink(source: 1, target: 2, value: 1),
      ],
    );

    test('the title height floors at 36 and grows with the font', () {
      expect(
        sankeyTitleHeight(),
        36,
        reason: 'SankeyChart.tsx:554-560 — no title still reserves 36',
      );
      expect(
        sankeyTitleHeight(chartTitle: 'Flow'),
        36,
        reason: 'max(13 + CHART_TITLE_PADDING 20, 36) = max(33, 36)',
      );
      expect(
        sankeyTitleHeight(chartTitle: 'Flow', titleFontSize: 24),
        44,
        reason: 'max(24 + 20, 36)',
      );
    });

    test('the extent uses the fixed margins and the node width is 124', () {
      final layout = computeFluentSankeyLayout(
        data: chain,
        size: const Size(912, 468),
        titleHeight: 36,
        isRtl: false,
      );
      expect(
        layout.nodes.first.x0,
        48,
        reason: 'SankeyChart.tsx:561 pins the left margin at 48',
      );
      expect(
        layout.nodes.first.x1 - layout.nodes.first.x0,
        kSankeyNodeWidth,
        reason: 'SankeyChart.tsx:337 sets nodeWidth to 124',
      );
      expect(
        layout.nodes.last.x1,
        closeTo(912 - 48, 1e-9),
        reason: 'the rightmost column ends on the right margin',
      );
      expect(
        layout.columnCount,
        3,
        reason: 'a three-node chain lays out in three columns',
      );
      expect(
        layout.size,
        const Size(912, 468),
        reason:
            'preRenderLayout (SankeyChart.tsx:344) returns the container size, '
            'not the plot size',
      );
    });

    test('every node lands inside the vertical margins', () {
      final layout = computeFluentSankeyLayout(
        data: chain,
        size: const Size(912, 468),
        titleHeight: 36,
        isRtl: false,
      );
      for (final node in layout.nodes) {
        expect(
          node.y0,
          greaterThanOrEqualTo(36 - 1e-6),
          reason: 'the top margin is the title height',
        );
        expect(
          node.y1,
          lessThanOrEqualTo(468 - 32 + 1e-6),
          reason: 'SankeyChart.tsx:561 pins the bottom margin at 32',
        );
      }
    });

    test('actual values come from the FIRST pass, not the second', () {
      final layout = computeFluentSankeyLayout(
        data: skewed,
        size: const Size(912, 468),
        titleHeight: 36,
        isRtl: false,
      );
      expect(
        layout.nodeActualValues[1],
        1,
        reason:
            'SankeyChart.tsx:243-252 writes back the values captured before '
            'the one-percent normalisation',
      );
      expect(
        layout.linkUnnormalisedValues[1],
        1,
        reason: "SankeyChart.tsx:245-247 keeps the caller's link weight",
      );
    });

    test('the sub-one-percent node is drawn taller than its weight', () {
      final layout = computeFluentSankeyLayout(
        data: skewed,
        size: const Size(912, 468),
        titleHeight: 36,
        isRtl: false,
      );
      final tinyHeight = layout.nodes[1].y1 - layout.nodes[1].y0;
      final bigHeight = layout.nodes[0].y1 - layout.nodes[0].y0;
      expect(
        tinyHeight / bigHeight,
        greaterThan(1 / 1000),
        reason:
            'SankeyChart.tsx:197-199 lifts a sub-one-percent node so it stays '
            'visible; without the second sankey() pass the lift would be lost',
      );
    });

    test('RTL swaps the alignment function only', () {
      final ltr = computeFluentSankeyLayout(
        data: chain,
        size: const Size(912, 468),
        titleHeight: 36,
        isRtl: false,
      );
      final rtl = computeFluentSankeyLayout(
        data: chain,
        size: const Size(912, 468),
        titleHeight: 36,
        isRtl: true,
      );
      expect(
        rtl.nodes.first.x0,
        ltr.nodes.first.x0,
        reason:
            'SankeyChart.tsx:342 swaps sankeyJustify for sankeyRight; the '
            'layout itself is not mirrored',
      );
    });

    test('an empty graph reports itself empty and lays nothing out', () {
      final layout = computeFluentSankeyLayout(
        data: const FluentSankeyChartData(
          nodes: <FluentSankeyNode>[],
          links: <FluentSankeyLink>[],
        ),
        size: const Size(912, 468),
        titleHeight: 36,
        isRtl: false,
      );
      expect(
        layout.isEmpty,
        isTrue,
        reason: 'SankeyChart.tsx:675-678 needs both lists non-empty',
      );
      expect(layout.nodes, isEmpty, reason: 'nothing to lay out');
    });

    test('a circular graph throws the upstream error', () {
      expect(
        () => computeFluentSankeyLayout(
          data: const FluentSankeyChartData(
            nodes: <FluentSankeyNode>[
              FluentSankeyNode(nodeId: 0, name: 'A'),
              FluentSankeyNode(nodeId: 1, name: 'B'),
            ],
            links: <FluentSankeyLink>[
              FluentSankeyLink(source: 0, target: 1, value: 1),
              FluentSankeyLink(source: 1, target: 0, value: 1),
            ],
          ),
          size: const Size(912, 468),
          titleHeight: 36,
          isRtl: false,
        ),
        throwsStateError,
        reason: 'sankey.js:169 throws "circular link"',
      );
    });

    test('the two-pass pipeline reproduces the d3 golden corpus', () async {
      // The corpus solves the bare kernel on `[[0, 0], [800, 400]]`
      // (`crawlers/d3-golden/generate.mjs:492-499`). Every formula in
      // `sankey.js` reads the extent only through `x1 - x0` and `y1 - y0` or as
      // an offset from `x0`/`y0`, so the layout is a pure translation: giving
      // the pipeline a 896 x 468 container with the fixed 48/32 margins and a
      // 36pt title band puts the extent at `[[48, 36], [848, 436]]`, the corpus
      // shifted by exactly the margin.
      //
      // Nothing in this graph falls under one percent of its column and no
      // column is sparse enough to retune the padding, so the second pass is a
      // no-op and the corpus numbers must survive the whole pipeline. That is
      // the assertion: the two-pass wrapper must not perturb a layout the
      // kernel already gets right.
      const dx = kSankeyMarginHorizontal;
      const dy = 36.0;
      const width = 800 + 2 * kSankeyMarginHorizontal;
      const height = 400 + dy + kSankeyMarginBottom;
      const sample = FluentSankeyChartData(
        nodes: <FluentSankeyNode>[
          FluentSankeyNode(nodeId: 'a', name: 'a'),
          FluentSankeyNode(nodeId: 'b', name: 'b'),
          FluentSankeyNode(nodeId: 'c', name: 'c'),
          FluentSankeyNode(nodeId: 'd', name: 'd'),
          FluentSankeyNode(nodeId: 'e', name: 'e'),
        ],
        links: <FluentSankeyLink>[
          FluentSankeyLink(source: 0, target: 2, value: 10),
          FluentSankeyLink(source: 1, target: 2, value: 5),
          FluentSankeyLink(source: 0, target: 3, value: 3),
          FluentSankeyLink(source: 2, target: 4, value: 12),
          FluentSankeyLink(source: 3, target: 4, value: 3),
        ],
      );

      final corpus = await loadD3Golden();
      final cases = goldenCases(corpus, 'sankey');
      expect(
        cases,
        hasLength(6),
        reason: 'the corpus holds six sankey vectors',
      );
      // Only the two vectors generated with the chart's own nodeWidth 124,
      // nodePadding 8 and six iterations are reachable through the pipeline;
      // the other four vary knobs `preRenderLayout` never exposes.
      final reachable = cases
          .where(
            (Map<String, dynamic> c) =>
                c['nodeWidth'] == 124 &&
                c['nodePadding'] == 8 &&
                c['iterations'] == 6 &&
                (c['extent']! as List<Object?>).toString() ==
                    '[[0, 0], [800, 400]]',
          )
          .toList(growable: false);
      expect(
        reachable,
        hasLength(2),
        reason:
            'vectors 0 and 1 are the justify and right runs at the chart '
            "settings; a smaller count means the corpus moved and this test's "
            'translation argument no longer applies',
      );

      // The translation is exact in real arithmetic, but subtracting the margin
      // back off is one more rounding: `283.1111111111112 + 36 - 36` lands on
      // `283.1111111111111`, one ulp low. 1e-9 is four orders of magnitude over
      // an ulp at this scale and still a ten-thousandth of a device pixel.
      Matcher closeToShifted(Object? want) =>
          closeTo((want! as num).toDouble(), 1e-9);

      for (final c in reachable) {
        final layout = computeFluentSankeyLayout(
          data: sample,
          size: const Size(width, height),
          titleHeight: dy,
          isRtl: c['align'] == 'right',
        );
        final label = 'sankey vector align=${c['align']}';
        final wantNodes = (c['nodes']! as List<Object?>)
            .cast<Map<String, dynamic>>();
        expect(
          layout.nodes,
          hasLength(wantNodes.length),
          reason: '$label: node count',
        );
        for (var i = 0; i < wantNodes.length; i++) {
          final n = layout.nodes[i];
          expect(
            n.layer,
            wantNodes[i]['layer'],
            reason: '$label: node $i layer',
          );
          expect(
            n.value,
            closeToJs(wantNodes[i]['value']),
            reason: '$label: node $i value',
          );
          expect(
            n.x0 - dx,
            closeToShifted(wantNodes[i]['x0']),
            reason: '$label: node $i x0',
          );
          expect(
            n.x1 - dx,
            closeToShifted(wantNodes[i]['x1']),
            reason: '$label: node $i x1',
          );
          expect(
            n.y0 - dy,
            closeToShifted(wantNodes[i]['y0']),
            reason: '$label: node $i y0',
          );
          expect(
            n.y1 - dy,
            closeToShifted(wantNodes[i]['y1']),
            reason: '$label: node $i y1',
          );
        }
        final wantLinks = (c['links']! as List<Object?>)
            .cast<Map<String, dynamic>>();
        expect(
          layout.links,
          hasLength(wantLinks.length),
          reason: '$label: link count',
        );
        for (var i = 0; i < wantLinks.length; i++) {
          final l = layout.links[i];
          expect(
            l.width,
            closeToJs(wantLinks[i]['width']),
            reason: '$label: link $i width',
          );
          expect(
            l.y0 - dy,
            closeToShifted(wantLinks[i]['y0']),
            reason: '$label: link $i y0',
          );
          expect(
            l.y1 - dy,
            closeToShifted(wantLinks[i]['y1']),
            reason: '$label: link $i y1',
          );
        }
      }
    });
  });

  group('node visuals', () {
    final measurer = FluentChartTextMeasurer();
    const nameStyle = TextStyle(fontSize: 10);
    const weightStyle = TextStyle(fontSize: 14);

    test('a name that fits is returned unchanged', () {
      expect(
        truncateSankeyText('Hi', 1000, measurer: measurer, style: nameStyle),
        'Hi',
        reason: 'SankeyChart.tsx:395-397 returns early when it fits',
      );
    });

    test('a name that overflows gains an ellipsis', () {
      final result = truncateSankeyText(
        'A very long node name indeed',
        40,
        measurer: measurer,
        style: nameStyle,
      );
      expect(
        result.endsWith(kSankeyEllipsis),
        isTrue,
        reason: 'SankeyChart.tsx:411-412 drops the last char and appends "..."',
      );
      expect(
        result.length,
        lessThan('A very long node name indeed'.length),
        reason: 'the result is shorter than the input',
      );
      expect(
        measurer.width(result, nameStyle),
        lessThanOrEqualTo(40),
        reason: 'the truncated string fits the budget',
      );
    });

    test('a tall node budgets 108px and reports no weight offset', () {
      const data = FluentSankeyChartData(
        nodes: <FluentSankeyNode>[
          FluentSankeyNode(nodeId: 0, name: 'Source'),
          FluentSankeyNode(nodeId: 1, name: 'Target'),
        ],
        links: <FluentSankeyLink>[
          FluentSankeyLink(source: 0, target: 1, value: 500),
        ],
      );
      final layout = computeFluentSankeyLayout(
        data: data,
        size: const Size(912, 468),
        titleHeight: 36,
        isRtl: false,
      );
      final visuals = computeSankeyNodeVisuals(
        layout: layout,
        measurer: measurer,
        nameStyle: nameStyle,
        weightMeasurementStyle: weightStyle,
        formatNumber: (v) => v.toStringAsFixed(0),
        nodeSemanticLabel: (name, weight) => 'node $name with weight $weight',
      );
      expect(
        visuals.first.height,
        greaterThan(kSankeyMinHeightForDoubleLine),
        reason: 'a single 500-weight link fills the column',
      );
      expect(
        visuals.first.weightOffset,
        0,
        reason:
            'SankeyChart.tsx:637 only measures the weight when the node is short, '
            'so a tall node leaves textLengthForNodeWeight at 0',
      );
      expect(
        visuals.first.semanticLabel,
        'node Source with weight 500',
        reason: 'SankeyChart.tsx:1055 formats the node aria template',
      );
      expect(
        visuals.first.weightText,
        '500',
        reason: 'SankeyChart.tsx:855 formats the actual value',
      );
    });

    test('a short node subtracts the measured weight from the name budget', () {
      const data = FluentSankeyChartData(
        nodes: <FluentSankeyNode>[
          FluentSankeyNode(nodeId: 0, name: 'Wide'),
          FluentSankeyNode(nodeId: 1, name: 'Narrow node name'),
          FluentSankeyNode(nodeId: 2, name: 'Sink'),
        ],
        links: <FluentSankeyLink>[
          FluentSankeyLink(source: 0, target: 2, value: 10000),
          FluentSankeyLink(source: 1, target: 2, value: 1),
        ],
      );
      final layout = computeFluentSankeyLayout(
        data: data,
        size: const Size(912, 468),
        titleHeight: 36,
        isRtl: false,
      );
      final visuals = computeSankeyNodeVisuals(
        layout: layout,
        measurer: measurer,
        nameStyle: nameStyle,
        weightMeasurementStyle: weightStyle,
        formatNumber: (v) => v.toStringAsFixed(0),
        nodeSemanticLabel: (name, weight) => 'node $name with weight $weight',
      );
      final narrow = visuals[1];
      expect(
        narrow.height,
        lessThan(kSankeyMinHeightForDoubleLine),
        reason: 'the one-percent node stays short',
      );
      expect(
        narrow.weightOffset,
        measurer.width('1', weightStyle),
        reason:
            'SankeyChart.tsx:641-644 measures the weight with NO font-size '
            'override, so it inherits body1 at 14px REGULAR even though the '
            'painted weight is bold — parity, SankeyChart.tsx:849',
      );
    });

    test('a zero weight renders the raw zero, not a formatted string', () {
      const data = FluentSankeyChartData(
        nodes: <FluentSankeyNode>[
          FluentSankeyNode(nodeId: 0, name: 'A'),
          FluentSankeyNode(nodeId: 1, name: 'B'),
        ],
        links: <FluentSankeyLink>[
          FluentSankeyLink(source: 0, target: 1, value: 0),
        ],
      );
      final layout = computeFluentSankeyLayout(
        data: data,
        size: const Size(912, 468),
        titleHeight: 36,
        isRtl: false,
      );
      final visuals = computeSankeyNodeVisuals(
        layout: layout,
        measurer: measurer,
        nameStyle: nameStyle,
        weightMeasurementStyle: weightStyle,
        formatNumber: (v) => 'FORMATTED',
        nodeSemanticLabel: (name, weight) => weight,
      );
      expect(
        visuals.first.weightText,
        '0',
        reason:
            'SankeyChart.tsx:855 — `actualValue ? format(actualValue) : actualValue`, '
            'and a falsy 0 renders as the raw 0',
      );
    });
  });
}
