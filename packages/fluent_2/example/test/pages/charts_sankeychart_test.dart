import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// SankeyChart's page carries four demos: three with a pair of size sliders,
/// one of which also swaps its whole data set from a switch, and one that takes
/// whatever box it is given.
///
/// A Sankey diagram is one `CustomPaint` — nodes, streams, names and weights
/// all — so every assertion below reads the solved layout and the live
/// selection off the chart's own state, which is what the canvas is driven
/// from. `FluentSankeyChartState` is public for exactly this: it stands in for
/// upstream's `componentRef`.
void main() {
  const String page = 'charts-sankeychart';

  group('sankey chart basic', () {
    final DocsSection section = sectionOf(
      'charts-sankeychart--sankey-chart-basic',
    );

    testWidgets('the width slider re-solves the diagram', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(_sankey(tester).layout.size.width, 820);
      expect(_sankey(tester).layout.nodes, hasLength(6));
      expect(_sankey(tester).layout.links, hasLength(8));

      await dropSliderAt(tester, find.byType(FluentSlider).first, 1);
      expect(_sankey(tester).layout.size.width, 1000);
      final double wide = _columnSpan(tester);

      // The far end of the rail is 400, which is narrower than four columns of
      // nodes can be drawn in, so `reflowMode: minWidth` floors the diagram
      // there rather than crushing it — and the floor is still narrower than
      // the box the demo opened at.
      await dropSliderAt(tester, find.byType(FluentSlider).first, 0);
      expect(
        _sankey(tester).layout.size.width,
        calculateSankeyChartMinWidth(_sankey(tester).layout.columnCount),
      );
      expect(_columnSpan(tester), lessThan(wide));

      // Round trip through the end of the rail, the one fraction that names an
      // exact value through the rail's own 8px inset.
      await dropSliderAt(tester, find.byType(FluentSlider).first, 1);
      expect(_sankey(tester).layout.size.width, 1000);
      expect(_columnSpan(tester), closeTo(wide, 0.01));
    });

    testWidgets('the width slider commits under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The rail sits between the story's vertical scroller and the diagram's
      // sideways one, and a scrollable that claims a mouse drag after a single
      // pixel of travel would swallow the press. `tester.tap` never sees that
      // arena at all.
      await mouseClick(tester, find.byType(FluentSlider).first);
      expect(
        _sankey(tester).layout.size.width,
        isNot(820),
        reason: 'a mouse press on the rail must move the width',
      );
    });

    testWidgets('the height slider re-solves the node heights', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final double tall = _nodeSpan(tester);

      await dropSliderAt(tester, find.byType(FluentSlider).at(1), 0);
      expect(_sankey(tester).layout.size.height, 312);
      final double short = _nodeSpan(tester);
      expect(
        short,
        lessThan(tall),
        reason: 'a shorter box must shorten the nodes it stacks',
      );

      await dropSliderAt(tester, find.byType(FluentSlider).at(1), 1);
      // The far end of this rail is the height the demo opens at — see the next
      // test, which is why it is 412 and not the 400 the two sibling demos stop
      // at.
      expect(_sankey(tester).layout.size.height, 412);
      expect(_nodeSpan(tester), greaterThan(short));
    });

    testWidgets('the height slider can reach the height the demo opens at', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final double opening = _sankey(tester).layout.size.height;
      expect(opening, 412);

      // Upstream stops this rail at 400 while opening the demo at 412, which
      // leaves the height off the end of its own control: the thumb is pinned
      // at the maximum while the diagram is 12px taller than that maximum
      // claims, and the first touch of the rail — even at the very end the
      // thumb already appears to sit on — shrinks the diagram with no way back.
      // The rail is carried to 412 here; the two sibling demos open at 400,
      // which is where their rails end.
      await dropSliderAt(tester, find.byType(FluentSlider).at(1), 1);
      expect(
        _sankey(tester).layout.size.height,
        opening,
        reason: 'a slider must be able to express the value its demo starts at',
      );
    });

    testWidgets('hovering a node highlights it and everything it flows to', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(_sankey(tester).selection.active, isFalse);

      final layout = _sankey(tester).layout;
      final node = layout.nodes[0];
      final TestGesture mouse = await hoverAt(
        tester,
        tester.getTopLeft(_plot()) +
            Rect.fromLTRB(node.x0, node.y0, node.x1, node.y1).center,
        what: 'a Sankey node',
      );

      // node0 feeds node2 and node4, and those two go on to feed node3 and
      // node5 — the whole reachable set lights up, which is the page's own
      // "highlight the source and destination of flow" rule.
      expect(_sankey(tester).selection.selectedNode, 0);
      expect(_sankey(tester).selection.nodeIndices, contains(0));
      expect(_sankey(tester).selection.linkIndices, isNotEmpty);

      await mouseAway(tester, mouse);
      expect(
        _sankey(tester).selection.active,
        isFalse,
        reason: 'leaving the diagram must drop the highlight',
      );
    });

    testWidgets('hovering a stream highlights it and names its target', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final layout = _sankey(tester).layout;
      final link = layout.links[0];
      // The ribbon is a cubic whose two ends are centred on y0 and y1, so its
      // midpoint is the one place its centre line can be named without
      // sampling. The containment check is what stops a bad guess from quietly
      // turning this into a test of the background.
      final Offset midpoint = Offset(
        (link.source.x1 + link.target.x0) / 2,
        (link.y0 + link.y1) / 2,
      );
      expect(
        sankeyLinkPath(link).contains(midpoint),
        isTrue,
        reason: 'the sampled point is not on the ribbon',
      );

      final TestGesture mouse = await hoverAt(
        tester,
        tester.getTopLeft(_plot()) + midpoint,
        what: 'a Sankey stream',
      );

      // A stream selection deliberately leaves `selectedNode` null — that is
      // what switches the ribbon onto its gradient treatment.
      expect(_sankey(tester).selection.linkIndices, contains(0));
      expect(_sankey(tester).selection.selectedNode, isNull);
      expect(find.byType(FluentChartPopover), findsOneWidget);
      expect(
        find.text(layout.data.nodes[link.target.index].name),
        findsOneWidget,
        reason: "the popover header is the stream's destination",
      );

      await mouseAway(tester, mouse);
      expect(find.byType(FluentChartPopover), findsNothing);
    });
  });

  group('sankey chart inbox', () {
    final DocsSection section = sectionOf(
      'charts-sankeychart--sankey-chart-inbox',
    );

    testWidgets('the custom label templates reach the narration', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final FluentSankeyChartState state = _sankey(tester);
      expect(state.layout.nodes, hasLength(12));
      expect(state.layout.links, hasLength(12));

      // The demo overrides `nodeSemanticLabel`; the default reads "node {0}
      // with weight {1}", so a template that never reached the visuals would
      // narrate that instead.
      expect(
        state.visuals[0].semanticLabel,
        'Category 192.168.42.72 with email count 80',
      );
    });

    testWidgets('the width slider re-solves this diagram too', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(_sankey(tester).layout.size.width, 820);
      final double span = _columnSpan(tester);

      await dropSliderAt(tester, find.byType(FluentSlider).first, 1);
      expect(_sankey(tester).layout.size.width, 1600);
      expect(_columnSpan(tester), greaterThan(span));

      await dropSliderAt(tester, find.byType(FluentSlider).first, 0);
      expect(
        _sankey(tester).layout.size.width,
        calculateSankeyChartMinWidth(_sankey(tester).layout.columnCount),
      );
    });
  });

  group('sankey chart rebalance', () {
    final DocsSection section = sectionOf(
      'charts-sankeychart--sankey-chart-rebalance',
    );

    testWidgets('the data-source switch swaps the whole diagram', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text('Data Source: simple'), findsOneWidget);
      expect(_sankey(tester).layout.nodes, hasLength(4));
      expect(_sankey(tester).layout.columnCount, 2);

      // A real mouse, because this is the demo's primary knob and the switch
      // sits inside the story's scroller.
      await mouseClick(tester, find.byType(FluentSwitch));
      expect(find.text('Data Source: complex'), findsOneWidget);
      expect(_sankey(tester).layout.nodes, hasLength(43));
      expect(_sankey(tester).layout.columnCount, 4);

      await mouseClick(tester, find.byType(FluentSwitch));
      expect(find.text('Data Source: simple'), findsOneWidget);
      expect(_sankey(tester).layout.nodes, hasLength(4));
    });

    testWidgets('a node too short to hold its own text names itself on hover', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final layout = _sankey(tester).layout;
      // "Tiny Source" carries 2 against "Large Source"'s 10001, so it is drawn
      // at the 4px floor — the case the page's Accessibility note is about:
      // "the node does not show content. The text is shown when a user hovers
      // over the node."
      final int tiny = layout.data.nodes.indexWhere(
        (FluentSankeyNode node) => node.name == 'Tiny Source',
      );
      final node = layout.nodes[tiny];
      expect(node.y1 - node.y0, lessThan(kSankeyMinHeightForType));

      final TestGesture mouse = await hoverAt(
        tester,
        tester.getTopLeft(_plot()) +
            Rect.fromLTRB(node.x0, node.y0, node.x1, node.y1).center,
        what: 'the tiny node',
      );
      expect(find.byType(FluentChartPopover), findsOneWidget);
      expect(find.text('Tiny Source'), findsOneWidget);

      await mouseAway(tester, mouse);
      expect(find.byType(FluentChartPopover), findsNothing);
    });

    testWidgets('the size sliders drive the rebalance demo', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(_sankey(tester).layout.size, const Size(820, 400));

      await dropSliderAt(tester, find.byType(FluentSlider).first, 1);
      expect(_sankey(tester).layout.size.width, 1600);

      await dropSliderAt(tester, find.byType(FluentSlider).at(1), 0);
      expect(_sankey(tester).layout.size.height, 312);
    });
  });

  group('sankey chart responsive', () {
    final DocsSection section = sectionOf(
      'charts-sankeychart--sankey-chart-responsive',
    );

    testWidgets('an unboxed chart fills its width and falls back on height', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final FluentSankeyChartState state = _sankey(tester);

      expect(state.layout.nodes, hasLength(6));
      expect(state.layout.links, hasLength(8));
      // The story's scroller gives an unbounded height and the full width, and
      // the chart is documented to fall back to its own default on an
      // unbounded constraint rather than collapsing.
      expect(state.layout.size.width, 1600);
      expect(state.layout.size.height, kSankeyDefaultHeight);
      expect(
        state.visuals.map((FluentSankeyNodeVisual v) => v.semanticLabel),
        everyElement(contains('node')),
      );
    });

    testWidgets('every node is still reachable with a pointer', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final layout = _sankey(tester).layout;
      final node = layout.nodes.last;

      final TestGesture mouse = await hoverAt(
        tester,
        tester.getTopLeft(_plot()) +
            Rect.fromLTRB(node.x0, node.y0, node.x1, node.y1).center,
        what: 'the last node',
      );
      expect(_sankey(tester).selection.selectedNode, node.index);
      await mouseAway(tester, mouse);
      expect(_sankey(tester).selection.active, isFalse);
    });
  });

  group('lifecycle', () {
    testWidgets('every section unmounts without throwing', (
      WidgetTester tester,
    ) async {
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section);
        await expectCleanTeardown(tester, section.id);
      }
    });
  });
}

/// The mounted chart's state, which carries the layout it last painted.
FluentSankeyChartState _sankey(WidgetTester tester) =>
    tester.state<FluentSankeyChartState>(find.byType(FluentSankeyChart));

/// The diagram's canvas, which the layout's coordinates are local to.
Finder _plot() => find.byWidgetPredicate(
  (Widget widget) =>
      widget is CustomPaint && widget.painter is FluentSankeyChartPainter,
);

/// The horizontal distance from the first column's left edge to the last
/// column's right edge.
///
/// The node width is a constant, so a wider box can only show itself in the
/// gaps between columns — comparing one node's width would compare two
/// constants.
double _columnSpan(WidgetTester tester) {
  // `SankeyLayoutNode` is deliberately not exported, so it is used by inference
  // rather than named: the layout result is public, its element type is not.
  final nodes = _sankey(tester).layout.nodes;
  double left = double.infinity;
  double right = double.negativeInfinity;
  for (final node in nodes) {
    left = node.x0 < left ? node.x0 : left;
    right = node.x1 > right ? node.x1 : right;
  }
  return right - left;
}

/// The vertical extent every node in the first column occupies together.
double _nodeSpan(WidgetTester tester) {
  final nodes = _sankey(tester).layout.nodes;
  double top = double.infinity;
  double bottom = double.negativeInfinity;
  for (final node in nodes) {
    top = node.y0 < top ? node.y0 : top;
    bottom = node.y1 > bottom ? node.y1 : bottom;
  }
  return bottom - top;
}
