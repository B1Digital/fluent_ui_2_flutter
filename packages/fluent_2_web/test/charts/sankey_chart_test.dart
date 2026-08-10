import 'dart:ui' show PathMetric;

import 'package:fluent_2_web/fluent_2_web.dart';
// The d3 kernel is deliberately never barrel-exported, so this one stays deep.
import 'package:fluent_2_web/src/charts/internal/d3/sankey.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../support/oracle_fixture.dart';

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

  test('two selections built from the same node compare equal', () {
    expect(
      FluentSankeySelection.forNode(layout.nodes[0]),
      FluentSankeySelection.forNode(layout.nodes[0]),
      reason:
          'FluentSankeyChartPainter.shouldRepaint compares selections by value, '
          'so a rebuild that reproduces the same hover must not repaint',
    );
    expect(
      FluentSankeySelection.forNode(layout.nodes[0]),
      isNot(FluentSankeySelection.forNode(layout.nodes[3])),
      reason: 'a different hovered node is a different selection',
    );
  });

  group('dom order and link geometry', () {
    /// A → B → C, one stream per hop, so both links share a width and a y.
    const data = FluentSankeyChartData(
      nodes: <FluentSankeyNode>[
        FluentSankeyNode(nodeId: 0, name: 'A'),
        FluentSankeyNode(nodeId: 1, name: 'B'),
        FluentSankeyNode(nodeId: 2, name: 'C'),
      ],
      links: <FluentSankeyLink>[
        FluentSankeyLink(source: 0, target: 1, value: 5),
        FluentSankeyLink(source: 1, target: 2, value: 5),
      ],
    );
    final layout = computeFluentSankeyLayout(
      data: data,
      // 912x468 are the upstream container defaults (`SankeyChart.tsx:571-572`).
      size: const Size(912, 468),
      titleHeight: kSankeyMinTitleHeight,
      isRtl: false,
    );

    test('every node and link appears exactly once', () {
      final order = sankeyDomOrder(layout);
      expect(
        order.where((item) => item.isNode).length,
        3,
        reason: 'SankeyChart.tsx:1101-1103 pushes one entry per node',
      );
      expect(
        order.where((item) => !item.isNode).length,
        2,
        reason: 'SankeyChart.tsx:1112-1114 pushes one entry per link',
      );
    });

    test('layers ascend and nodes precede links within a layer', () {
      final order = sankeyDomOrder(layout);
      for (var i = 1; i < order.length; i++) {
        expect(
          order[i].layer,
          greaterThanOrEqualTo(order[i - 1].layer),
          reason: 'SankeyChart.tsx:1116-1118 sorts by layer ascending',
        );
        if (order[i].layer == order[i - 1].layer) {
          expect(
            order[i - 1].isNode || !order[i].isNode,
            isTrue,
            reason:
                'SankeyChart.tsx:1120-1123 — "node" > "link" returns -1, so nodes '
                'come first within a layer and links never paint under them',
          );
        }
      }
    });

    test('a link path is the two-point bump-x area, closed', () {
      final path = sankeyLinkPath(layout.links.first);
      final link = layout.links.first;
      final metrics = path.computeMetrics().toList();
      expect(
        metrics.length,
        1,
        reason: 'SankeyChart.tsx:514-518 emits a single closed area',
      );
      expect(metrics.first.isClosed, isTrue, reason: 'd3 area appends Z');
      final bounds = path.getBounds();
      expect(
        bounds.left,
        // 1e-6 is float noise on a coordinate the layout computed exactly.
        closeTo(link.source.x1, 1e-6),
        reason: 'SankeyChart.tsx:509 anchors the left edge at source.x1',
      );
      expect(
        bounds.right,
        closeTo(link.target.x0, 1e-6),
        reason: 'SankeyChart.tsx:510 anchors the right edge at target.x0',
      );
      expect(
        bounds.height,
        closeTo(link.width, 1e-6),
        reason:
            'SankeyChart.tsx:505 — the band is link.width, half above and half '
            'below link.y0 / link.y1',
      );
    });

    test('the control points sit on the horizontal midpoint', () {
      final link = layout.links.first;
      final path = sankeyLinkPath(link);
      // 2 averages the two anchored edges.
      final mid = (link.source.x1 + link.target.x0) / 2;
      // curveBumpX pins both control points to the midpoint x, so the path
      // crosses that x at exactly the average of the two endpoints' y.
      expect(
        path.contains(Offset(mid, (link.y0 + link.y1) / 2)),
        isTrue,
        reason: 'the ribbon covers its own midline',
      );
      expect(
        path.contains(Offset(mid, (link.y0 + link.y1) / 2 - link.width)),
        isFalse,
        reason: 'a point a full band above the midline is outside',
      );
    });
  });

  group('Oracle B: every captured stream path', () {
    // The two Sankey stories whose streams are not all horizontal, so a wrong
    // curve family cannot hide in a straight line.
    for (final id in <String>[
      'charts-sankeychart--sankey-chart-basic',
      'charts-sankeychart--sankey-chart-inbox',
    ]) {
      test('$id reproduces the shipped ribbon geometry', () {
        final story = loadOracleStory(id);
        final paths = story.byTag('path');
        expect(
          paths.length,
          greaterThan(0),
          reason: '$id must capture at least one stream path to assert against',
        );
        for (final element in paths) {
          final numbers = svgPathNumbers(element.d!);
          expect(
            numbers.length,
            16,
            reason:
                'SankeyChart.tsx:514-518 emits M, one cubic, L, one cubic, Z — '
                'two coordinates for the move, six for each cubic and two for '
                'the line',
          );
          // Index map of the emitted `d`: 0-1 the source top corner, 6-7 the
          // target top corner, 8-9 the target bottom corner, 14-15 the source
          // bottom corner. The control points at 2-5 and 10-13 are the curve
          // itself and are deliberately NOT read back — they are what this test
          // is checking.
          final source = SankeyLayoutNode()..x1 = numbers[0];
          final target = SankeyLayoutNode()..x0 = numbers[6];
          // 2 averages the band's two edges back onto its centre line.
          final link =
              SankeyLayoutLink(source: source, target: target, value: 0)
                ..y0 = (numbers[1] + numbers[15]) / 2
                ..y1 = (numbers[7] + numbers[9]) / 2
                ..width = numbers[15] - numbers[1];
          final expected = Path()
            ..moveTo(numbers[0], numbers[1])
            ..cubicTo(
              numbers[2],
              numbers[3],
              numbers[4],
              numbers[5],
              numbers[6],
              numbers[7],
            )
            ..lineTo(numbers[8], numbers[9])
            ..cubicTo(
              numbers[10],
              numbers[11],
              numbers[12],
              numbers[13],
              numbers[14],
              numbers[15],
            )
            ..close();
          final actual = sankeyLinkPath(link);
          final wanted = expected.computeMetrics().single;
          final got = actual.computeMetrics().single;
          expect(
            got.length,
            closeTo(wanted.length, kOracleGeometryTolerance),
            reason:
                'the ported ribbon must have the same perimeter as the captured '
                'one — a different curve family would not (${element.d})',
          );
          // 16 samples per perimeter: dense enough that a curve that agreed
          // only at the ends and the middle would still be caught, cheap enough
          // to run over all twenty captured streams.
          const samples = 16;
          for (var i = 0; i <= samples; i++) {
            final t = wanted.length * i / samples;
            expectOracleOffset(
              'sample $i of ${element.d}',
              _pointAt(wanted, t),
              _pointAt(got, got.length * i / samples),
            );
          }
        }
      });
    }
  });

  group('FluentSankeyChart', () {
    final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

    Future<void> pump(WidgetTester tester, Widget chart, {Size? size}) =>
        tester.pumpWidget(
          FluentApp(
            theme: theme,
            home: Center(
              child: SizedBox.fromSize(
                // 912x468 are the upstream container defaults
                // (`SankeyChart.tsx:571-572`).
                size: size ?? const Size(912, 468),
                child: chart,
              ),
            ),
          ),
        );

    const graph = FluentSankeyChartData(
      nodes: <FluentSankeyNode>[
        FluentSankeyNode(nodeId: 0, name: 'Inbox'),
        FluentSankeyNode(nodeId: 1, name: 'Archive'),
        FluentSankeyNode(nodeId: 2, name: 'Deleted'),
      ],
      links: <FluentSankeyLink>[
        FluentSankeyLink(source: 0, target: 1, value: 70),
        FluentSankeyLink(source: 0, target: 2, value: 30),
      ],
    );

    testWidgets('paints one painter with the whole diagram', (tester) async {
      await pump(tester, const FluentSankeyChart(data: graph));
      expect(
        tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((c) => c.painter)
            .whereType<FluentSankeyChartPainter>(),
        hasLength(1),
        reason: 'the whole svg is one canvas',
      );
    });

    testWidgets('the chart announces its node and link counts', (tester) async {
      await pump(tester, const FluentSankeyChart(data: graph));
      expect(
        tester
            .widgetList<Semantics>(find.byType(Semantics))
            .any(
              (s) =>
                  s.properties.label == 'Sankey chart with 3 nodes and 2 links',
            ),
        isTrue,
        reason: 'SankeyChart.tsx:1157',
      );
    });

    testWidgets('an empty graph renders the alert instead', (tester) async {
      await pump(
        tester,
        const FluentSankeyChart(
          data: FluentSankeyChartData(
            nodes: <FluentSankeyNode>[],
            links: <FluentSankeyLink>[],
          ),
        ),
      );
      expect(
        tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((c) => c.painter)
            .whereType<FluentSankeyChartPainter>(),
        isEmpty,
        reason: 'SankeyChart.tsx:1197 replaces the whole chart',
      );
      expect(
        tester
            .widgetList<Semantics>(find.byType(Semantics))
            .any((s) => s.properties.label == 'Graph has no data to display'),
        isTrue,
        reason: 'SankeyChart.tsx:1047 is the default empty label',
      );
    });

    testWidgets('hovering a node selects its path and keeps the popover shut', (
      tester,
    ) async {
      await pump(tester, const FluentSankeyChart(data: graph));
      final state = tester.state<FluentSankeyChartState>(
        find.byType(FluentSankeyChart),
      );
      final node = state.layout.nodes[0];
      final origin = tester.getTopLeft(find.byType(FluentSankeyChart));
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer();
      addTearDown(gesture.removePointer);
      // 2 halves the node box to hit its centre.
      await gesture.moveTo(
        origin + Offset((node.x0 + node.x1) / 2, (node.y0 + node.y1) / 2),
      );
      await tester.pump();
      expect(state.selection.selectedNode, 0, reason: 'SankeyChart.tsx:883');
      expect(
        find.byType(FluentChartPopover),
        findsNothing,
        reason:
            'SankeyChart.tsx:885 only opens the callout for a node shorter than '
            'MIN_HEIGHT_FOR_TYPE, and this one fills its column',
      );
    });

    testWidgets('hovering a stream opens the popover with the From message', (
      tester,
    ) async {
      await pump(tester, const FluentSankeyChart(data: graph));
      final state = tester.state<FluentSankeyChartState>(
        find.byType(FluentSankeyChart),
      );
      final link = state.layout.links[0];
      final origin = tester.getTopLeft(find.byType(FluentSankeyChart));
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer();
      addTearDown(gesture.removePointer);
      // 2 takes the ribbon's midpoint, which curveBumpX puts on its centre
      // line.
      await gesture.moveTo(
        origin +
            Offset(
              (link.source.x1 + link.target.x0) / 2,
              (link.y0 + link.y1) / 2,
            ),
      );
      await tester.pump();
      final popover = tester.widget<FluentChartPopover>(
        find.byType(FluentChartPopover),
      );
      expect(
        popover.data.xValue,
        'Archive',
        reason: 'SankeyChart.tsx:670 puts the TARGET name in XValue',
      );
      expect(
        popover.data.yValue,
        '70',
        reason: 'SankeyChart.tsx:671 formats the unnormalised link value',
      );
      expect(
        popover.data.descriptionMessage,
        'From Inbox',
        reason: 'SankeyChart.tsx:1036, 1040 — the linkFrom template',
      );
    });

    testWidgets('leaving the chart closes the popover', (tester) async {
      await pump(tester, const FluentSankeyChart(data: graph));
      final state = tester.state<FluentSankeyChartState>(
        find.byType(FluentSankeyChart),
      );
      final link = state.layout.links[0];
      final origin = tester.getTopLeft(find.byType(FluentSankeyChart));
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer();
      addTearDown(gesture.removePointer);
      // 2 takes the ribbon's midpoint, as above.
      await gesture.moveTo(
        origin +
            Offset(
              (link.source.x1 + link.target.x0) / 2,
              (link.y0 + link.y1) / 2,
            ),
      );
      await tester.pump();
      await gesture.moveTo(Offset.zero);
      await tester.pump();
      expect(
        find.byType(FluentChartPopover),
        findsNothing,
        reason: 'SankeyChart.tsx:1143 closes the callout on the root leave',
      );
    });

    testWidgets('a number format is applied to weights and aria labels', (
      tester,
    ) async {
      await pump(
        tester,
        FluentSankeyChart(data: graph, numberFormat: NumberFormat('#,##0.00')),
      );
      final state = tester.state<FluentSankeyChartState>(
        find.byType(FluentSankeyChart),
      );
      expect(
        state.visuals.first.weightText,
        '100.00',
        reason:
            'SankeyChart.tsx:612-613 routes through toLocaleString when '
            'formatNumberOptions is set',
      );
    });

    testWidgets('without a format the weight uses the JS toString', (
      tester,
    ) async {
      await pump(tester, const FluentSankeyChart(data: graph));
      final state = tester.state<FluentSankeyChartState>(
        find.byType(FluentSankeyChart),
      );
      expect(
        state.visuals.first.weightText,
        '100',
        reason:
            'SankeyChart.tsx:614 falls back to value.toString(), which prints an '
            'integral double without a decimal point',
      );
    });

    testWidgets('min-width reflow wraps the chart in a horizontal scroller', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentSankeyChart(
          data: graph,
          reflowMode: FluentSankeyReflowMode.minWidth,
        ),
        // 300 is narrower than the two-column minimum of 406.
        size: const Size(300, 468),
      );
      final scroller = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(
        scroller.scrollDirection,
        Axis.horizontal,
        reason:
            'useSankeyChartStyles.styles.ts:86 sets overflow auto; Flutter needs '
            'an explicit scroll view (spec 5.1)',
      );
      final state = tester.state<FluentSankeyChartState>(
        find.byType(FluentSankeyChart),
      );
      expect(
        state.layout.size.width,
        calculateSankeyChartMinWidth(state.layout.columnCount),
        reason: 'SankeyChart.tsx:590-592 widens the container to the minimum',
      );
    });

    testWidgets('an unbounded box falls back to 912 by 468', (tester) async {
      await tester.pumpWidget(
        FluentApp(
          theme: theme,
          home: const SingleChildScrollView(
            child: FluentSankeyChart(data: graph),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(FluentSankeyChart)).height,
        kSankeyDefaultHeight,
        reason:
            'SankeyChart.tsx:571-572 initialises the container to 912 x 468',
      );
    });
  });
}

/// The point [distance] along [metric], which
/// [PathMetric.getTangentForOffset] returns as a tangent.
Offset _pointAt(PathMetric metric, double distance) =>
    metric.getTangentForOffset(distance)!.position;
