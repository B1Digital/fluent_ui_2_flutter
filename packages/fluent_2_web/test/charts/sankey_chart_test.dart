import 'dart:convert';
import 'dart:ui' show PathMetric, Shader;

import 'package:fluent_2_web/fluent_2_web.dart';
// The d3 kernel is deliberately never barrel-exported, so this one stays deep.
import 'package:fluent_2_web/src/charts/internal/d3/sankey.dart';
// The image exporter is not barrel-exported either: `lib/fluent_2_web.dart` is
// owned by the integration task.
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

    testWidgets('the controller exports the diagram with no legend strip', (
      tester,
    ) async {
      final controller = FluentChartController();
      await pump(
        tester,
        FluentSankeyChart(data: graph, controller: controller),
      );
      // `RenderRepaintBoundary.toImage` and `Image.toByteData` are serviced by
      // the engine, which a fake-async widget test never pumps.
      final bytes = base64Decode(
        (await tester.runAsync(controller.toImage))!.split(',').last,
      );

      /// The PNG IHDR chunk starts at byte 8; its width and height are the two
      /// big-endian 32-bit words at 16 and 20 (PNG spec, 11.2.2).
      int be32(int at) =>
          (bytes[at] << 24) |
          (bytes[at + 1] << 16) |
          (bytes[at + 2] << 8) |
          bytes[at + 3];
      expect(
        be32(16),
        tester.getSize(find.byType(FluentSankeyChart)).width.toInt(),
        reason:
            'the export is the full chart width — 800 here rather than the '
            '912 of SankeyChart.tsx:571, because the 800x600 test surface '
            'constrains the box `pump` asks for',
      );
      expect(
        be32(20),
        468,
        reason:
            'SankeyChart.tsx:548 calls useImageExport with hideLegends true, so '
            'the sankey export never gains a legend strip',
      );
    });
  });

  // `SankeyChart.tsx:1160-1166` renders `<ChartTitle>` with no `y`, so the
  // title's baseline is `ChartTitle.tsx:80-87` — the one place in the port
  // where that default is reached, every other `<ChartTitle>` caller either
  // passing an explicit `y` (`GaugeChart.tsx:604`, `DonutChart.tsx:364`) or
  // being laid out as a widget rather than painted.
  group('the chart title', () {
    final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
    final story = loadOracleStory('charts-sankeychart--sankey-chart-basic');
    // The one `<text>` the story's chartTitle produced. Its `y` is what
    // `ChartTitle.tsx:80-87` resolved to with no `titleStyles` passed, and its
    // `fontSize` is what the class rendered — 10 against a `y` solved from the
    // literal 13 of `:83`. The two disagree upstream, which is why the
    // placement cannot be read off the title's own text style.
    final captured = story.soleElement(
      'text',
      where: (element) => element.text == 'Sankey Chart',
    );

    /// Mounts a titled sankey and replays its painter, so the anchor the title
    /// is drawn about can be read back off the canvas.
    Future<_RecordingCanvas> paintTitled(
      WidgetTester tester, {
      double? titleFontSize,
    }) async {
      await tester.pumpWidget(
        FluentApp(
          theme: theme,
          home: Center(
            child: SizedBox(
              // The captured svg's own box. The 800x600 test surface narrows
              // it, which is why the x below is read off the solved layout
              // rather than off the fixture.
              width: story.width,
              height: story.height,
              child: FluentSankeyChart(
                data: data,
                chartTitle: captured.text,
                titleFontSize: titleFontSize,
              ),
            ),
          ),
        ),
      );
      return _replay(tester);
    }

    testWidgets('with no font size it sits where the capture put it', (
      tester,
    ) async {
      final recorded = await paintTitled(tester);
      expect(
        recorded.translates,
        hasLength(1),
        reason:
            'the title block is the painter\'s only translate, so a second one '
            'would mean the assertion below reads a different anchor',
      );
      final state = tester.state<FluentSankeyChartState>(
        find.byType(FluentSankeyChart),
      );
      expect(
        recorded.translates.single,
        Offset(state.layout.size.width / 2, captured.y!),
        reason:
            'SankeyChart.tsx:1162 centres the title on the container and '
            'passes no y, so ChartTitle.tsx:80-87 places it — ${captured.y} in '
            'the capture, against a title the same capture renders at '
            '${captured.fontSize}px',
      );
    });

    testWidgets('a title font size moves it down with the band it sits in', (
      tester,
    ) async {
      // 24 is the oversized title sankey_chart_layout_test.dart:318 already
      // reserves a band for; no captured story passes titleStyles, so the
      // font-size arm of the formula has no fixture and is derived here.
      const fontSize = 24.0;
      final recorded = await paintTitled(tester, titleFontSize: fontSize);
      expect(
        recorded.translates.single.dy,
        fontSize + kChartTitleAxisPadding,
        reason:
            'ChartTitle.tsx:80-87 solves max(titleFont.size + '
            'AXIS_TITLE_PADDING, CHART_TITLE_PADDING - AXIS_TITLE_PADDING) = '
            '32, while SankeyChart.tsx:554-560 grows the reserved band to 44. '
            'A title pinned at the default 21 sits high of its own band.',
      );
    });

    test('a title font size is the size the title is laid out at', () {
      const fontSize = 24.0;
      final spy = _SpyMeasurer();
      FluentSankeyChartPainter(
        layout: layout,
        // Empty, so the only string this painter lays out is its title.
        visuals: const <FluentSankeyNodeVisual>[],
        order: const <FluentSankeyDomItem>[],
        selection: FluentSankeySelection.none,
        style: resolveFluentSankeyChartStyle(theme),
        states: const <WidgetState>{},
        measurer: spy,
        colors: FluentChartColors.of(theme),
        isRtl: false,
        chartTitle: 'Flow',
        titleFontSize: fontSize,
      ).paint(_RecordingCanvas(), layout.size);
      expect(
        spy.sizes,
        // Two entries, both the title's: `FluentChartTitlePainter.paint`
        // measures and then lays out, through the one factory.
        hasLength(2),
        reason:
            'an empty list would pass the set comparison below having measured '
            'nothing at all',
      );
      expect(
        spy.sizes.toSet(),
        <double>{fontSize},
        reason:
            'ChartTitle.tsx:106 hands titleFont to getChartTitleInlineStyles, '
            'whose Common.styles.ts:113 writes fontSize onto the <text>, so '
            'the same number that moved the baseline sizes the glyphs',
      );
    });
  });

  group('high contrast flattening (spec 5.3)', () {
    final light = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
    final highContrast = FluentThemeData.highContrast(
      fontPlatform: FluentFontPlatform.web,
    );
    // `FluentChartColors.flattenMark` sends a mark fill to `axisText`, which is
    // `colorNeutralForeground1`; `flattenMarkStroke` sends a stroke to
    // `surface`, which is `colorNeutralBackground1`. Under the high-contrast
    // palette those are the system CanvasText and Canvas.
    final canvasText = highContrast.colors.neutralForeground1;
    final canvas = highContrast.colors.neutralBackground1;

    /// A → B and A → C, the second link carrying its own colour so the
    /// selected-stream fill arm (`SankeyChart.tsx:947-949`) is reachable.
    const coloured = FluentSankeyChartData(
      nodes: <FluentSankeyNode>[
        FluentSankeyNode(nodeId: 0, name: 'A'),
        FluentSankeyNode(nodeId: 1, name: 'B'),
        FluentSankeyNode(nodeId: 2, name: 'C'),
      ],
      links: <FluentSankeyLink>[
        FluentSankeyLink(source: 0, target: 1, value: 5),
        FluentSankeyLink(
          source: 0,
          target: 2,
          value: 5,
          color: Color(0xFFE3008C),
        ),
      ],
    );

    /// Pumps [graph] under [themeData] and replays the painter it built onto a
    /// recording canvas, which is the only way to read a resolved paint back.
    Future<_RecordingCanvas> paint(
      WidgetTester tester,
      FluentThemeData themeData, {
      FluentSankeyChartData graph = data,
    }) async {
      await tester.pumpWidget(
        FluentApp(
          theme: themeData,
          home: Center(
            child: SizedBox(
              // 560x300 is the golden's cell, which fits the 800x600 test
              // surface so a hover lands on screen.
              width: 560,
              height: 300,
              child: FluentSankeyChart(data: graph),
            ),
          ),
        ),
      );
      return _replay(tester);
    }

    /// Moves a mouse onto the midline of link [index] and replays the painter
    /// the resulting selection built.
    Future<_RecordingCanvas> hoverLink(WidgetTester tester, int index) async {
      final state = tester.state<FluentSankeyChartState>(
        find.byType(FluentSankeyChart),
      );
      final link = state.layout.links[index];
      final origin = tester.getTopLeft(find.byType(FluentSankeyChart));
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer();
      addTearDown(gesture.removePointer);
      // 2 averages the ribbon's two ends onto its midline, which
      // `sankeyLinkPath` covers for any curve of the bump-x family.
      await gesture.moveTo(
        origin +
            Offset(
              (link.source.x1 + link.target.x0) / 2,
              (link.y0 + link.y1) / 2,
            ),
      );
      await tester.pump();
      expect(
        state.selection.linkUsesGradient(index),
        isTrue,
        reason:
            'the hover must have landed on the ribbon, or the gradient arm '
            'below is never exercised (SankeyChart.tsx:957)',
      );
      return _replay(tester);
    }

    testWidgets('an ordinary theme keeps every node in its palette colour', (
      tester,
    ) async {
      final recorded = await paint(tester, light);
      final state = tester.state<FluentSankeyChartState>(
        find.byType(FluentSankeyChart),
      );
      expect(
        recorded.fills(recorded.rects),
        hasLength(state.layout.nodes.length),
        reason: 'one filled rect per node, or the sets below prove nothing',
      );
      expect(
        recorded.fills(recorded.rects).map((c) => c.toARGB32()).toSet(),
        <int>{for (final c in state.layout.nodeColors) c.toARGB32()},
        reason:
            'flattenMark is the identity outside high contrast, so the ten '
            'pairs of SankeyChart.tsx:41-52 must survive untouched',
      );
      expect(
        recorded.strokes(recorded.rects).map((c) => c.toARGB32()).toSet(),
        <int>{for (final c in state.layout.nodeBorderColors) c.toARGB32()},
        reason: 'and so must every node border',
      );
      expect(
        recorded.strokes(recorded.paths).map((c) => c.toARGB32()).toSet(),
        <int>{kSankeyNonSelectedColor.toARGB32()},
        reason:
            'SankeyChart.tsx:953-954 strokes an unselected stream in '
            'NON_SELECTED_NODE_AND_STREAM_COLOR',
      );
    });

    testWidgets('high contrast flattens every node fill and border', (
      tester,
    ) async {
      final recorded = await paint(tester, highContrast);
      expect(
        recorded.fills(recorded.rects),
        isNotEmpty,
        reason: 'a chart that painted no node rect would pass vacuously',
      );
      expect(
        recorded.fills(recorded.rects).map((c) => c.toARGB32()).toSet(),
        <int>{canvasText.toARGB32()},
        reason:
            'spec 5.3: the rect at SankeyChart.tsx:811 carries its own fill '
            'attribute, so a forced-colours browser rewrites it to CanvasText '
            'and the forty-colour palette disappears — FluentChartColors.'
            'flattenMark is what does that here',
      );
      expect(
        recorded.strokes(recorded.rects).map((c) => c.toARGB32()).toSet(),
        <int>{canvas.toARGB32()},
        reason:
            'flattenMarkStroke sends a mark border to Canvas instead, which is '
            'the documented deviation that keeps two touching nodes apart '
            '(chart_colors.dart, spec 5.2)',
      );
    });

    testWidgets('high contrast keeps the stream hollow and inks its border', (
      tester,
    ) async {
      final recorded = await paint(tester, highContrast);
      expect(
        recorded.fills(recorded.paths),
        isNotEmpty,
        reason: 'a chart that painted no ribbon would pass vacuously',
      );
      expect(
        recorded.fills(recorded.paths).map((c) => c.toARGB32()).toSet(),
        <int>{canvas.toARGB32()},
        reason:
            'useSankeyChartStyles.styles.ts:34-36 forces the stream fill to '
            'Canvas under high contrast, which colorNeutralBackground1 already '
            'resolves to — running it through flattenMark would paint every '
            'ribbon solid CanvasText and swallow the diagram',
      );
      expect(
        recorded.strokes(recorded.paths).map((c) => c.toARGB32()).toSet(),
        <int>{canvasText.toARGB32()},
        reason:
            'the ribbon is hollow, so its stroke (SankeyChart.tsx:763) is the '
            'only ink it has: it flattens to CanvasText like a fill, not to '
            'the Canvas flattenMarkStroke would give',
      );
    });

    testWidgets('an ordinary theme still strokes the hovered stream with a '
        'gradient', (tester) async {
      await paint(tester, light);
      final recorded = await hoverLink(tester, 1);
      final state = tester.state<FluentSankeyChartState>(
        find.byType(FluentSankeyChart),
      );
      final gradientLinks = <int>[
        for (var i = 0; i < state.layout.links.length; i++)
          if (state.selection.linkUsesGradient(i)) i,
      ];
      expect(
        gradientLinks,
        isNotEmpty,
        reason: 'the hover must select at least one stream to stroke',
      );
      expect(
        recorded.shaders(recorded.paths),
        hasLength(gradientLinks.length),
        reason:
            'SankeyChart.tsx:754-757 builds one linearGradient per selected '
            'stream, from the source node colour to the target node colour',
      );
    });

    testWidgets('high contrast collapses the gradient stroke to a flat one', (
      tester,
    ) async {
      await paint(tester, highContrast);
      final recorded = await hoverLink(tester, 1);
      expect(
        recorded.shaders(recorded.paths),
        isEmpty,
        reason:
            'both stops of SankeyChart.tsx:755-756 are node fills, so both '
            'flatten to CanvasText and the gradient is a flat stroke; painting '
            'a shader with two identical stops would only cost an allocation',
      );
      expect(
        recorded
            .strokes(recorded.paths)
            // The alpha is the selection's own dimming — 0.5 on the stream
            // outside the hovered path (`SankeyChart.tsx:986-988`) — and is
            // orthogonal to which colour the flattening chose.
            .map((c) => c.withValues(alpha: 1).toARGB32())
            .toSet(),
        <int>{canvasText.toARGB32()},
        reason: 'and the flat stroke is that same CanvasText',
      );
    });

    /// A painter over the shared [layout], with [textMeasurer] spying on the
    /// styles it lays out. The visuals get their own measurer so the spy sees
    /// only what the painter draws.
    FluentSankeyChartPainter painterFor(
      FluentThemeData themeData,
      FluentChartTextMeasurer textMeasurer,
    ) {
      const states = <WidgetState>{};
      final style = resolveFluentSankeyChartStyle(themeData);
      return FluentSankeyChartPainter(
        layout: layout,
        visuals: computeSankeyNodeVisuals(
          layout: layout,
          measurer: FluentChartTextMeasurer(),
          nameStyle: style.nameTextStyle!.resolve(states)!,
          weightMeasurementStyle: style.weightMeasurementTextStyle!.resolve(
            states,
          )!,
          formatNumber: (value) => '$value',
          nodeSemanticLabel: (name, weight) => '$name $weight',
        ),
        order: sankeyDomOrder(layout),
        selection: FluentSankeySelection.none,
        style: style,
        states: states,
        measurer: textMeasurer,
        colors: FluentChartColors.of(themeData),
        isRtl: false,
      );
    }

    test('an ordinary theme draws the node text white', () {
      final spy = _SpyMeasurer();
      painterFor(light, spy).paint(_RecordingCanvas(), layout.size);
      expect(
        spy.colours,
        isNotEmpty,
        reason:
            'every node must clear MIN_HEIGHT_FOR_TYPE, or no text is laid out '
            'and the set below is vacuous (SankeyChart.tsx:823)',
      );
      expect(
        spy.colours.toSet(),
        <int>{kSankeyNonSelectedTextColor.toARGB32()},
        reason:
            'SankeyChart.tsx:524-530 draws the idle node text in white, and '
            'flattenMarkStroke is the identity outside high contrast',
      );
    });

    test('high contrast flattens the node text off the flattened fill', () {
      final spy = _SpyMeasurer();
      painterFor(highContrast, spy).paint(_RecordingCanvas(), layout.size);
      expect(
        spy.colours,
        isNotEmpty,
        reason: 'as above — no text laid out would pass vacuously',
      );
      expect(
        canvas.toARGB32(),
        isNot(canvasText.toARGB32()),
        reason:
            'the assertion below only means anything while the two system '
            'colours differ',
      );
      expect(
        spy.colours.toSet(),
        <int>{canvas.toARGB32()},
        reason:
            'the fill under it is now CanvasText, so the CanvasText of '
            'useSankeyChartStyles.styles.ts:46-50 would be invisible; spec 5.2 '
            'exempts an accessibility defect from bug fidelity, so the text '
            'takes Canvas — the other half of the pair :40-42 was after',
      );
    });

    testWidgets('high contrast flattens a selected stream fill', (
      tester,
    ) async {
      await paint(tester, highContrast, graph: coloured);
      final recorded = await hoverLink(tester, 1);
      expect(
        recorded.fills(recorded.paths).map((c) => c.toARGB32()),
        contains(
          canvasText
              .withValues(alpha: canvasText.a * kSankeySelectedStreamOpacity)
              .toARGB32(),
        ),
        reason:
            'SankeyChart.tsx:947-949 gives a selected stream the link colour as '
            'a real fill attribute, which forced colours rewrites to CanvasText '
            'at the 0.3 of :979',
      );
    });
  });
}

/// Records the colour, the paint style and the shader of every mark the sankey
/// painter draws, so a test can read a resolved paint without a raster.
///
/// [noSuchMethod] absorbs the rest of [Canvas] — the text goes through
/// `drawParagraph`, which none of these tests asserts on.
class _RecordingCanvas implements Canvas {
  /// One entry per `drawRect`, in paint order: the node rectangles.
  final List<(Color, PaintingStyle, Shader?)> rects =
      <(Color, PaintingStyle, Shader?)>[];

  /// One entry per `drawPath`, in paint order: the stream ribbons.
  final List<(Color, PaintingStyle, Shader?)> paths =
      <(Color, PaintingStyle, Shader?)>[];

  /// One entry per `translate`, in paint order. Nodes and links are drawn in
  /// absolute coordinates, so the chart title's anchor is the only one.
  final List<Offset> translates = <Offset>[];

  /// The colour of every filled draw among [recorded].
  Iterable<Color> fills(List<(Color, PaintingStyle, Shader?)> recorded) =>
      recorded.where((r) => r.$2 == PaintingStyle.fill).map((r) => r.$1);

  /// The colour of every stroked draw among [recorded].
  Iterable<Color> strokes(List<(Color, PaintingStyle, Shader?)> recorded) =>
      recorded.where((r) => r.$2 == PaintingStyle.stroke).map((r) => r.$1);

  /// The shader of every draw among [recorded] that carried one.
  Iterable<Shader> shaders(List<(Color, PaintingStyle, Shader?)> recorded) =>
      recorded.map((r) => r.$3).whereType<Shader>();

  @override
  void drawRect(Rect rect, Paint paint) =>
      rects.add((paint.color, paint.style, paint.shader));

  @override
  void drawPath(Path path, Paint paint) =>
      paths.add((paint.color, paint.style, paint.shader));

  @override
  void translate(double dx, double dy) => translates.add(Offset(dx, dy));

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Records the colour of every string the sankey painter lays out.
///
/// A `ui.Paragraph` exposes no colour, so the style handed to [layoutPainter]
/// is the only place a text colour can be read back without a raster.
class _SpyMeasurer extends FluentChartTextMeasurer {
  /// The packed ARGB of every style laid out, in paint order.
  final List<int> colours = <int>[];

  /// The font size of every style laid out, in paint order.
  final List<double> sizes = <double>[];

  @override
  TextPainter layoutPainter(String text, TextStyle style) {
    colours.add(style.color!.toARGB32());
    sizes.add(style.fontSize!);
    return super.layoutPainter(text, style);
  }
}

/// Replays the sankey painter currently in the tree onto a recording canvas.
_RecordingCanvas _replay(WidgetTester tester) {
  final painter = tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((c) => c.painter)
      .whereType<FluentSankeyChartPainter>()
      .single;
  final recorded = _RecordingCanvas();
  painter.paint(recorded, painter.layout.size);
  return recorded;
}

/// The point [distance] along [metric], which
/// [PathMetric.getTangentForOffset] returns as a tangent.
Offset _pointAt(PathMetric metric, double distance) =>
    metric.getTangentForOffset(distance)!.position;
