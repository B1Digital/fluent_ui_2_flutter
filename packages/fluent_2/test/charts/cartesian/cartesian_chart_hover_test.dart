/// How the shell turns pointer, touch and keyboard input into a hovered or
/// focused region: hit shapes, the delegate's own hover hook, marks that open
/// no callout, the one-pixel re-anchor threshold and the touch tap.
library;

import 'package:fluent_2/src/charts/cartesian/cartesian_chart.dart';
import 'package:fluent_2/src/charts/cartesian/cartesian_chart_props.dart';
import 'package:fluent_2/src/charts/cartesian/cartesian_layout.dart';
import 'package:fluent_2/src/charts/cartesian/cartesian_painter.dart';
import 'package:fluent_2/src/charts/cartesian/cartesian_series_delegate.dart';
import 'package:fluent_2/src/charts/chrome/chart_popover.dart';
import 'package:fluent_2/src/charts/chrome/legend.dart';
import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/stub_cartesian_delegate.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget chart) => tester.pumpWidget(
    FluentApp(
      theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      home: Center(child: SizedBox(width: 400, height: 260, child: chart)),
    ),
  );

  Offset origin(WidgetTester tester) =>
      tester.getTopLeft(find.byType(FluentCartesianChart));

  Future<TestGesture> mouseAt(WidgetTester tester, Offset local) async {
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(origin(tester) + local);
    await tester.pump();
    return gesture;
  }

  String? shownX(WidgetTester tester) {
    final popovers = find.byType(FluentChartPopover);
    return popovers.evaluate().isEmpty
        ? null
        : tester.widget<FluentChartPopover>(popovers).data.xValue;
  }

  Offset anchorOf(WidgetTester tester) =>
      tester.widget<FluentChartPopover>(find.byType(FluentChartPopover)).anchor;

  group('hit shapes', () {
    testWidgets('a circle is hovered and clicked as a circle', (tester) async {
      final delegate = _ShapedDelegate();
      await pump(
        tester,
        FluentCartesianChart(
          delegate: delegate,
          props: const FluentCartesianChartProps(hideLegend: true),
          legends: const <FluentChartLegendItem>[],
        ),
      );
      // The circle sits in LTWH(40, 20, 20, 20); (41, 21) is inside that
      // square and 8.5px outside the circle's 10px radius.
      final gesture = await mouseAt(tester, const Offset(41, 21));
      expect(
        shownX(tester),
        isNull,
        reason:
            'SVG hit-tests the painted <circle>, not the square around it '
            '(ScatterChart.tsx:445-466)',
      );
      await gesture.down(origin(tester) + const Offset(41, 21));
      await gesture.up();
      await tester.pump();
      expect(delegate.clicks, isEmpty, reason: 'nor is a click in the corner');

      await gesture.moveTo(origin(tester) + const Offset(50, 30));
      await tester.pump();
      expect(shownX(tester), 'circle');
    });

    testWidgets('the delegate names the hovered region on the same move', (
      tester,
    ) async {
      final moves = <Offset>[];
      await pump(
        tester,
        FluentCartesianChart(
          delegate: _ShapedDelegate(),
          props: const FluentCartesianChartProps(hideLegend: true),
          legends: const <FluentChartLegendItem>[],
          onPointerMoveInPlot: (local, _) => moves.add(local),
        ),
      );
      // x 160..200 is no region's area, and the delegate hovers the third
      // region from it, as LineChart's segment hovers its start point
      // (LineChart.tsx:1251-1278).
      await mouseAt(tester, const Offset(170, 100));
      expect(moves, <Offset>[const Offset(170, 100)]);
      expect(
        shownX(tester),
        'normal',
        reason:
            'the callout opens on the event that activates the mark, not on '
            'the move after it',
      );
    });
  });

  group('a mark with no reading', () {
    testWidgets('closes the callout but still clicks', (tester) async {
      final delegate = _ShapedDelegate();
      await pump(
        tester,
        FluentCartesianChart(
          delegate: delegate,
          props: const FluentCartesianChartProps(hideLegend: true),
          legends: const <FluentChartLegendItem>[],
        ),
      );
      final gesture = await mouseAt(tester, const Offset(130, 100));
      expect(shownX(tester), 'normal');
      await gesture.moveTo(origin(tester) + const Offset(90, 100));
      await tester.pump();
      expect(
        find.byType(FluentChartPopover),
        findsNothing,
        reason:
            'a bar another legend dims runs setPopoverOpen(false) on hover '
            '(VerticalBarChart.tsx:479)',
      );
      await gesture.down(origin(tester) + const Offset(90, 100));
      await gesture.up();
      await tester.pump();
      expect(
        delegate.clicks,
        <String>['dimmed'],
        reason: 'and keeps onClick={point.onClick} (VerticalBarChart.tsx:674)',
      );
    });

    testWidgets('takes no keyboard stop', (tester) async {
      final handle = tester.ensureSemantics();
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentCartesianChart(
          delegate: _ShapedDelegate(),
          props: const FluentCartesianChartProps(hideLegend: true),
          legends: const <FluentChartLegendItem>[],
          focusNode: node,
        ),
      );
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(
        find.bySemanticsLabel('normal'),
        findsOneWidget,
        reason:
            'tabIndex={shouldHighlight ? 0 : undefined} '
            '(VerticalBarChart.tsx:682): the second step skips the dimmed bar',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(find.bySemanticsLabel('circle'), findsOneWidget);
      handle.dispose();
    });
  });

  group('the re-anchor threshold', () {
    Widget stub({bool follows = false}) => FluentCartesianChart(
      delegate: StubCartesianDelegate(),
      props: FluentCartesianChartProps(
        hideLegend: true,
        popoverFollowsPointer: follows,
      ),
      legends: const <FluentChartLegendItem>[],
    );

    testWidgets('a following callout stays within a pixel', (tester) async {
      await pump(tester, stub(follows: true));
      final gesture = await mouseAt(tester, const Offset(45, 100));
      await gesture.moveTo(origin(tester) + const Offset(46, 100));
      await tester.pump();
      expect(
        anchorOf(tester),
        const Offset(45, 100),
        reason:
            '`if (distance > threshold)` with `const threshold = 1` '
            '(ScatterChart.tsx:168-178)',
      );
      await gesture.moveTo(origin(tester) + const Offset(47, 101));
      await tester.pump();
      expect(anchorOf(tester), const Offset(47, 101));
    });

    testWidgets('entering the next mark a pixel on keeps the anchor', (
      tester,
    ) async {
      await pump(tester, stub());
      // The stub's first two regions meet at x = 60.
      final gesture = await mouseAt(tester, const Offset(59, 100));
      expect(shownX(tester), '0');
      await gesture.moveTo(origin(tester) + const Offset(60, 100));
      await tester.pump();
      expect(shownX(tester), '1');
      expect(
        anchorOf(tester),
        const Offset(59, 100),
        reason:
            'onMouseOver runs the same updatePosition '
            '(VerticalBarChart.tsx:475-478, :1111)',
      );
    });
  });

  testWidgets('a region can follow the pointer on its own', (tester) async {
    await pump(
      tester,
      FluentCartesianChart(
        delegate: _FollowingDelegate(),
        props: const FluentCartesianChartProps(hideLegend: true),
        legends: const <FluentChartLegendItem>[],
      ),
    );
    final gesture = await mouseAt(tester, const Offset(45, 100));
    await gesture.moveTo(origin(tester) + const Offset(48, 110));
    await tester.pump();
    expect(
      anchorOf(tester),
      const Offset(48, 110),
      reason:
          'VerticalStackedBarChart moves its callout on a bar\'s onMouseMove '
          'and not on a line point\'s, so the choice is per mark '
          '(VerticalStackedBarChart.tsx:622, :1044-1045)',
    );
  });

  group('a touch tap', () {
    testWidgets('hovers what it lands on until a tap lands elsewhere', (
      tester,
    ) async {
      final moves = <Offset>[];
      var leaves = 0;
      await pump(
        tester,
        FluentCartesianChart(
          delegate: StubCartesianDelegate(),
          props: const FluentCartesianChartProps(hideLegend: true),
          legends: const <FluentChartLegendItem>[],
          onPointerMoveInPlot: (local, _) => moves.add(local),
          onChartMouseLeave: () => leaves++,
        ),
      );
      await tester.tapAt(origin(tester) + const Offset(50, 100));
      await tester.pump();
      expect(
        moves,
        <Offset>[const Offset(50, 100)],
        reason:
            'Chrome follows a tap with the compatibility mousemove and '
            "mouseover, which run the chart's own hover: marker, rule, dot",
      );
      expect(shownX(tester), '0');

      await tester.tapAt(const Offset(5, 5));
      await tester.pump();
      expect(
        shownX(tester),
        isNull,
        reason: 'the next tap elsewhere is the tapped chart\'s mouseleave',
      );
      expect(leaves, 1, reason: 'CartesianChart.tsx:749');

      await tester.tapAt(const Offset(5, 5));
      await tester.pump();
      expect(leaves, 1, reason: 'a chart no tap is on does not leave again');
    });
  });

  group('text measurement', () {
    FluentCartesianChartPainter painterOf(WidgetTester tester) => tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((c) => c.painter)
        .whereType<FluentCartesianChartPainter>()
        .single;

    testWidgets('survives a rebuild and not a font load', (tester) async {
      Widget chart(double yMaxValue) => FluentCartesianChart(
        delegate: StubCartesianDelegate(),
        props: FluentCartesianChartProps(
          hideLegend: true,
          yMaxValue: yMaxValue,
        ),
        legends: const <FluentChartLegendItem>[],
      );
      await pump(tester, chart(0));
      final measurer = painterOf(tester).measurer
        ..measure('probe', const TextStyle(fontSize: 13));
      final cached = measurer.cachedCount;

      await pump(tester, chart(1));
      expect(
        painterOf(tester).measurer.cachedCount,
        cached,
        reason:
            'the cache is keyed on the text and the resolved style, so a '
            'rebuild — every hover move — has nothing to re-measure',
      );

      await PaintingBinding.instance.handleSystemMessage(<String, Object?>{
        'type': 'fontsChange',
      });
      await tester.pump();
      expect(
        painterOf(tester).measurer.cachedCount,
        cached - 1,
        reason: 'a font that finished loading re-measures everything',
      );
    });
  });
}

/// Three regions over the plot's top-left, plus a hover band only the
/// delegate knows about:
///
/// * `circle` — a 10px-radius circle in LTWH(40, 20, 20, 20);
/// * `dimmed` — LTWH(80, 20, 20, 100), with no reading and no tab stop but a
///   click;
/// * `normal` — LTWH(120, 20, 20, 100), which x 160..200 also hovers.
class _ShapedDelegate extends StubCartesianDelegate {
  _ShapedDelegate() : super(hitRegionCount: 0);

  final List<String> clicks = <String>[];

  @override
  List<FluentChartHitRegion> buildHitRegions(
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
  ) {
    final plot = layout.plotRect;
    final centre = plot.topLeft + const Offset(10, 10);
    return <FluentChartHitRegion>[
      FluentChartHitRegion(
        bounds: Rect.fromCircle(center: centre, radius: 10),
        hitTest: (position) => (position - centre).distance <= 10,
        index: 0,
        legend: 'A',
        popoverData: const FluentChartPopoverData(xValue: 'circle'),
        semanticsLabel: 'circle',
        onActivate: () => clicks.add('circle'),
      ),
      FluentChartHitRegion(
        bounds: Rect.fromLTWH(plot.left + 40, plot.top, 20, 100),
        index: 1,
        legend: 'B',
        popoverData: null,
        focusable: false,
        semanticsLabel: 'dimmed',
        onActivate: () => clicks.add('dimmed'),
      ),
      FluentChartHitRegion(
        bounds: Rect.fromLTWH(plot.left + 80, plot.top, 20, 100),
        index: 2,
        legend: 'C',
        popoverData: const FluentChartPopoverData(xValue: 'normal'),
        semanticsLabel: 'normal',
      ),
    ];
  }

  @override
  int? hoveredRegionAt(
    FluentCartesianChildContext context,
    List<FluentChartHitRegion> regions,
    Offset position,
  ) {
    final band = Rect.fromLTWH(
      regions[2].bounds.left + 40,
      regions[2].bounds.top,
      40,
      100,
    );
    return band.contains(position) ? 2 : null;
  }
}

/// The stub's regions, each following the pointer in a chart that does not.
class _FollowingDelegate extends StubCartesianDelegate {
  @override
  List<FluentChartHitRegion> buildHitRegions(
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
  ) => <FluentChartHitRegion>[
    for (final region in super.buildHitRegions(context, layout))
      FluentChartHitRegion(
        bounds: region.bounds,
        index: region.index,
        legend: region.legend,
        popoverData: region.popoverData,
        followsPointer: true,
      ),
  ];
}
