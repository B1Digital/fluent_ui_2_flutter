/// The shell replaces `_fitParentContainer` (`CartesianChart.tsx:497-528`) with
/// `BoxConstraints`: the legend is a `Column` sibling, so its height is taken
/// out of the plot by Flutter's own layout rather than by measuring a div.
library;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/axis/axis_types.dart';
import 'package:fluent_2_web/src/charts/cartesian/cartesian_chart.dart';
import 'package:fluent_2_web/src/charts/cartesian/cartesian_chart_props.dart';
import 'package:fluent_2_web/src/charts/cartesian/cartesian_chart_style.dart';
import 'package:fluent_2_web/src/charts/cartesian/cartesian_layout.dart';
import 'package:fluent_2_web/src/charts/cartesian/cartesian_painter.dart';
import 'package:fluent_2_web/src/charts/cartesian/cartesian_series_delegate.dart';
import 'package:fluent_2_web/src/charts/chrome/annotation_layer.dart';
import 'package:fluent_2_web/src/charts/chrome/chart_popover.dart';
import 'package:fluent_2_web/src/charts/chrome/legend.dart';
import 'package:fluent_2_web/src/charts/model/chart_annotation.dart';
import 'package:fluent_2_web/src/charts/model/chart_value.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/oracle_fixture.dart';
import 'support/stub_cartesian_delegate.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget chart, {
    FluentThemeData? theme,
    TextDirection direction = TextDirection.ltr,
  }) => tester.pumpWidget(
    FluentApp(
      theme:
          theme ?? FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      home: Directionality(
        textDirection: direction,
        child: Center(child: chart),
      ),
    ),
  );

  Widget chart({
    StubCartesianDelegate? delegate,
    FluentCartesianChartProps props = const FluentCartesianChartProps(),
    List<FluentChartLegendItem> legends = const <FluentChartLegendItem>[],
    double? width = 400,
    double? height = 260,
  }) => SizedBox(
    width: width,
    height: height,
    child: FluentCartesianChart(
      delegate: delegate ?? StubCartesianDelegate(),
      props: props,
      legends: legends,
    ),
  );

  FluentCartesianChartPainter painterOf(WidgetTester tester) => tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((c) => c.painter)
      .whereType<FluentCartesianChartPainter>()
      .single;

  Widget stacked({
    FocusNode? node,
    FluentChartHitGranularity granularity = FluentChartHitGranularity.mark,
  }) => SizedBox(
    width: 400,
    height: 260,
    child: FluentCartesianChart(
      delegate: _StackedStubDelegate(),
      props: FluentCartesianChartProps(
        hideLegend: true,
        hitRegionGranularity: granularity,
      ),
      legends: const <FluentChartLegendItem>[],
      focusNode: node,
    ),
  );

  Widget anchored({required bool anchorsToRegion}) => SizedBox(
    width: 400,
    height: 260,
    child: FluentCartesianChart(
      delegate: StubCartesianDelegate(),
      props: FluentCartesianChartProps(
        hideLegend: true,
        popoverAnchorsToRegion: anchorsToRegion,
      ),
      legends: const <FluentChartLegendItem>[],
    ),
  );

  /// Hovers the centre-left of the stub's first region: 50 across and 100 down
  /// from the chart's top-left corner, which the default margins put inside
  /// LTWH(40, 20, 20, 205).
  Future<TestGesture> hoverFirstStubRegion(WidgetTester tester) async {
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(
      tester.getTopLeft(find.byType(FluentCartesianChart)) +
          const Offset(50, 100),
    );
    await tester.pump();
    return gesture;
  }

  testWidgets('solves a layout from the incoming constraints', (tester) async {
    await pump(tester, chart());
    final layout = painterOf(tester).layout;
    expect(
      layout.size,
      const Size(400, 260),
      reason:
          'an empty legend list contributes no row, so the plot keeps the '
          'whole box',
    );
    expect(
      layout.margins.left,
      40,
      reason: 'the default left margin, CartesianChart.tsx:679',
    );
  });

  testWidgets('unbounded height falls back to 350', (tester) async {
    await pump(
      tester,
      SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FluentCartesianChart(
              delegate: StubCartesianDelegate(),
              props: const FluentCartesianChartProps(hideLegend: true),
              legends: const <FluentChartLegendItem>[],
            ),
          ],
        ),
      ),
    );
    expect(
      painterOf(tester).layout.size.height,
      kFluentCartesianChartFallbackHeight,
      reason:
          'the Flutter analogue of `rect.height > legendHeight ? … : 350` '
          '(CartesianChart.tsx:516-519)',
    );
  });

  testWidgets('hideLegend removes the legend row entirely', (tester) async {
    await pump(
      tester,
      chart(
        props: const FluentCartesianChartProps(hideLegend: true),
        legends: const <FluentChartLegendItem>[
          FluentChartLegendItem(title: 'A', color: Color(0xFF0078D4)),
        ],
      ),
    );
    expect(
      find.byType(FluentChartLegend),
      findsNothing,
      reason: 'CartesianChart.tsx:912 gates the whole container',
    );
    expect(
      painterOf(tester).layout.size.height,
      260,
      reason: 'with no legend the plot takes the full height',
    );
  });

  testWidgets('the legend row eats vertical space from the plot', (
    tester,
  ) async {
    await pump(
      tester,
      chart(
        legends: const <FluentChartLegendItem>[
          FluentChartLegendItem(title: 'A', color: Color(0xFF0078D4)),
        ],
      ),
    );
    expect(
      find.byType(FluentChartLegend),
      findsOneWidget,
      reason: 'CartesianChart.tsx:912-921',
    );
    expect(
      painterOf(tester).layout.size.height,
      lessThan(260),
      reason:
          'the legend is a Column sibling, so Flutter subtracts it instead of '
          'getBoundingClientRect',
    );
  });

  testWidgets('the crispness offset is 0.5 at device pixel ratio 1', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pump(tester, chart());
    expect(
      painterOf(tester).crispOffset,
      loadOracleStory('charts-linechart--line-chart-basic').crispOffset,
      reason:
          'd3-axis/src/axis.js:38, and Oracle B captures at scale 1 too — the '
          'fixture is the authority on the value',
    );
  });

  testWidgets('a high device pixel ratio drops the offset to zero', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await pump(tester, chart());
    expect(
      painterOf(tester).crispOffset,
      0,
      reason: 'the other arm of d3-axis/src/axis.js:38',
    );
  });

  testWidgets('right-to-left swaps the margins before painting', (
    tester,
  ) async {
    await pump(tester, chart(), direction: TextDirection.rtl);
    final layout = painterOf(tester).layout;
    expect(
      layout.isRtl,
      isTrue,
      reason: 'Directionality replaces useRtl(), utilities.ts:640-643',
    );
    expect(
      layout.margins.left,
      20,
      reason: '_swapRtlMargins at CartesianChart.tsx:713-719',
    );
  });

  testWidgets('showYAxisLables widens the left margin in the same frame', (
    tester,
  ) async {
    await pump(
      tester,
      chart(props: const FluentCartesianChartProps(showYAxisLables: true)),
    );
    expect(
      painterOf(tester).layout.startFromX,
      greaterThan(0),
      reason:
          'the y tick text is measured and fed back into the margin solve '
          'inside one build, instead of over two renders as at '
          'CartesianChart.tsx:91-98',
    );
  });

  testWidgets('the chart narrates itself with one Semantics node', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      chart(props: const FluentCartesianChartProps(xAxisTitle: 'Time')),
    );
    expect(
      find.bySemanticsLabel(RegExp('The X axis displays Time')),
      findsOneWidget,
      reason:
          '_getChartDescription at CartesianChart.tsx:552-561, on exactly one '
          'node — design spec section 5.7',
    );
    handle.dispose();
  });

  testWidgets('onChartMouseLeave fires when the pointer exits the root', (
    tester,
  ) async {
    var left = 0;
    await pump(
      tester,
      SizedBox(
        width: 400,
        height: 260,
        child: FluentCartesianChart(
          delegate: StubCartesianDelegate(),
          props: const FluentCartesianChartProps(),
          legends: const <FluentChartLegendItem>[],
          onChartMouseLeave: () => left += 1,
        ),
      ),
    );
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(
      location: tester.getCenter(find.byType(FluentCartesianChart)),
    );
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.moveTo(Offset.zero);
    await tester.pump();
    expect(
      left,
      1,
      reason: 'onMouseLeave on the root div, CartesianChart.tsx:749',
    );
  });

  group('min-width reflow', () {
    Widget narrow({
      required FluentChartReflowMode mode,
      FluentChartType chartType = FluentChartType.lineChart,
    }) => SizedBox(
      width: 200,
      height: 260,
      child: FluentCartesianChart(
        delegate: StubCartesianDelegate(
          xAxisType: FluentChartAxisType.category,
          chartType: chartType,
          categories: const <String>[
            'January',
            'February',
            'March',
            'April',
            'May',
            'June',
            'July',
          ],
        ),
        // The overlap cull is what a narrow box normally reaches for; turning
        // it off (`CartesianChart.tsx:220`) leaves all seven months on the
        // axis, which is the state min-width reflow exists to serve.
        props: FluentCartesianChartProps(
          hideLegend: true,
          hideTickOverlap: false,
          reflowMode: mode,
        ),
        legends: const <FluentChartLegendItem>[],
      ),
    );

    testWidgets('none keeps the chart inside its box', (tester) async {
      await pump(tester, narrow(mode: FluentChartReflowMode.none));
      expect(
        find.byType(SingleChildScrollView),
        findsNothing,
        reason:
            "reflowProps.mode defaults to 'none', CartesianChart.types.ts:417",
      );
      expect(
        painterOf(tester).layout.size.width,
        200,
        reason: 'the chart shrinks with its box',
      );
    });

    testWidgets('minWidth scrolls instead of shrinking', (tester) async {
      await pump(tester, narrow(mode: FluentChartReflowMode.minWidth));
      expect(
        find.byType(SingleChildScrollView),
        findsOneWidget,
        reason:
            'upstream pairs min-width with chartWrapperMinWidth '
            '{ overflow: auto } (useCartesianChartStyles.styles.ts:51-52); '
            'Flutter needs the scroller spelled out — design spec section 5.1',
      );
      expect(
        painterOf(tester).layout.size.width,
        greaterThan(200),
        reason:
            'the chart is re-solved at _calculateChartMinWidth, '
            'CartesianChart.tsx:534-550',
      );
    });

    testWidgets('the three vertical bar types add 16 to the minimum', (
      tester,
    ) async {
      await pump(tester, narrow(mode: FluentChartReflowMode.minWidth));
      final line = painterOf(tester).layout.size.width;
      await pump(
        tester,
        narrow(
          mode: FluentChartReflowMode.minWidth,
          chartType: FluentChartType.verticalBarChart,
        ),
      );
      expect(
        painterOf(tester).layout.size.width - line,
        16,
        reason:
            'minDomainMargin * 2 for GroupedVerticalBarChart, VerticalBarChart '
            'and VerticalStackedBarChart, CartesianChart.tsx:540-547',
      );
    });

    testWidgets('a box already wider than the minimum does not scroll', (
      tester,
    ) async {
      await pump(
        tester,
        SizedBox(
          // 700 rather than the 1000 the plan wrote: the default test surface
          // is 800 wide, so a 1000-wide box is squeezed back to 800 by the
          // constraints and the assertion measures the surface, not the reflow.
          width: 700,
          height: 260,
          child: FluentCartesianChart(
            delegate: StubCartesianDelegate(),
            props: const FluentCartesianChartProps(
              hideLegend: true,
              reflowMode: FluentChartReflowMode.minWidth,
            ),
            legends: const <FluentChartLegendItem>[],
          ),
        ),
      );
      expect(
        find.byType(SingleChildScrollView),
        findsNothing,
        reason: 'no scroller when the box already clears the minimum',
      );
      expect(
        painterOf(tester).layout.size.width,
        700,
        reason: 'Math.max(rect.width, minWidth) at CartesianChart.tsx:513-515',
      );
    });
  });

  group('keyboard traversal', () {
    Widget focusable(FocusNode node) => SizedBox(
      width: 400,
      height: 260,
      child: FluentCartesianChart(
        delegate: StubCartesianDelegate(),
        props: const FluentCartesianChartProps(hideLegend: true),
        legends: const <FluentChartLegendItem>[],
        focusNode: node,
      ),
    );

    testWidgets('the whole plot is one focus stop', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(tester, focusable(node));
      // Scoped to the chart: FluentApp's own shell already mounts eight Focus
      // widgets of its own, so the plan's unscoped `lessThan(4)` could never
      // pass — what section 5.7 constrains is the chart's contribution.
      expect(
        find
            .descendant(
              of: find.byType(FluentCartesianChart),
              matching: find.byType(Focus),
            )
            .evaluate()
            .length,
        1,
        reason:
            'design spec section 5.7 — one node for the plot, not 500 invisible '
            'focusable boxes for a 500-point series',
      );
    });

    testWidgets('right arrow moves the label onto the first mark', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(tester, focusable(node));
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(
        find.bySemanticsLabel('Point 0'),
        findsOneWidget,
        reason:
            'the single Semantics node tracks the focused mark, because canvas '
            'text produces no node of its own',
      );
      handle.dispose();
    });

    testWidgets('arrow traversal is circular in both directions', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(tester, focusable(node));
      node.requestFocus();
      await tester.pump();
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      }
      await tester.pump();
      expect(
        find.bySemanticsLabel('Point 0'),
        findsOneWidget,
        reason:
            'useArrowNavigationGroup({ circular: true }) at '
            'CartesianChart.tsx:87 — four steps over three marks wraps to the '
            'first',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(
        find.bySemanticsLabel('Point 2'),
        findsOneWidget,
        reason: 'stepping left off the start wraps to the last',
      );
      handle.dispose();
    });

    testWidgets('the vertical arrows are left for the scroller', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(tester, focusable(node));
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(
        find.bySemanticsLabel(RegExp('The X axis displays')),
        findsOneWidget,
        reason:
            "axis: 'horizontal' at CartesianChart.tsx:87 — Down changes "
            'nothing, so the description still stands',
      );
      handle.dispose();
    });

    testWidgets('losing focus clears the roving index', (tester) async {
      final handle = tester.ensureSemantics();
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(tester, focusable(node));
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      node.unfocus();
      // Two frames, not the plan's one: FocusManager applies a blur in a
      // microtask, so the first pump only delivers the notification and the
      // setState it triggers builds on the second.
      await tester.pump();
      await tester.pump();
      expect(
        find.bySemanticsLabel(RegExp('The X axis displays')),
        findsOneWidget,
        reason: 'the label falls back to the chart description on blur',
      );
      handle.dispose();
    });
  });

  group('popover', () {
    Widget plot({bool hideTooltip = false}) => SizedBox(
      width: 400,
      height: 260,
      child: FluentCartesianChart(
        delegate: StubCartesianDelegate(),
        props: FluentCartesianChartProps(
          hideLegend: true,
          hideTooltip: hideTooltip,
        ),
        legends: const <FluentChartLegendItem>[],
      ),
    );

    // The plan's `find.byType(CustomPaint).first` matches the app shell's own
    // 800x260 painterless CustomPaint, whose top-left is the screen origin, so
    // every offset below it landed outside the chart. Filter by painter, as
    // `painterOf` above already does.
    final plotPaint = find.byWidgetPredicate(
      (widget) =>
          widget is CustomPaint &&
          widget.painter is FluentCartesianChartPainter,
    );

    Future<TestGesture> hoverFirstRegion(WidgetTester tester) async {
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      // The stub's first region starts at the plot's left edge, which the
      // default margins put at x = 40, and spans 20px.
      await gesture.moveTo(
        tester.getTopLeft(plotPaint) + const Offset(50, 100),
      );
      await tester.pump();
      return gesture;
    }

    testWidgets('hovering a region opens the popover', (tester) async {
      await pump(tester, plot());
      await hoverFirstRegion(tester);
      expect(
        find.byType(FluentChartPopover),
        findsOneWidget,
        reason:
            '`!hideTooltip && calloutProps.isPopoverOpen` at '
            'CartesianChart.tsx:444-446',
      );
    });

    testWidgets('hideTooltip suppresses it', (tester) async {
      await pump(tester, plot(hideTooltip: true));
      await hoverFirstRegion(tester);
      expect(
        find.byType(FluentChartPopover),
        findsNothing,
        reason: 'the first operand at CartesianChart.tsx:444',
      );
    });

    testWidgets('leaving the plot closes it', (tester) async {
      await pump(tester, plot());
      final gesture = await hoverFirstRegion(tester);
      await gesture.moveTo(Offset.zero);
      await tester.pump();
      expect(
        find.byType(FluentChartPopover),
        findsNothing,
        reason: 'the popover follows the pointer, not the last mark touched',
      );
    });

    testWidgets('hovering the gap between regions keeps the popover put', (
      tester,
    ) async {
      await pump(tester, plot());
      final gesture = await hoverFirstRegion(tester);
      await gesture.moveTo(
        tester.getTopLeft(plotPaint) + const Offset(350, 100),
      );
      await tester.pump();
      expect(
        find.byType(FluentChartPopover),
        findsOneWidget,
        reason:
            'the per-mark leave handler is an empty stub in every chart but '
            'one — VerticalBarChart.tsx:496-498, '
            'VerticalStackedBarChart.tsx:802-804 — so nothing fires in the gap '
            'and the callout stays on the last mark',
      );
    });

    testWidgets('closePopoverOnRegionExit closes it in the gap', (
      tester,
    ) async {
      await pump(
        tester,
        SizedBox(
          width: 400,
          height: 260,
          child: FluentCartesianChart(
            delegate: StubCartesianDelegate(),
            props: const FluentCartesianChartProps(
              hideLegend: true,
              closePopoverOnRegionExit: true,
            ),
            legends: const <FluentChartLegendItem>[],
          ),
        ),
      );
      final gesture = await hoverFirstRegion(tester);
      await gesture.moveTo(
        tester.getTopLeft(plotPaint) + const Offset(350, 100),
      );
      await tester.pump();
      expect(
        find.byType(FluentChartPopover),
        findsNothing,
        reason:
            'HorizontalBarChartWithAxis alone closes the callout on bar leave, '
            '.tsx:266-268',
      );
    });

    testWidgets('a tap opens it, for touch and pen', (tester) async {
      await pump(tester, plot());
      await tester.tapAt(tester.getTopLeft(plotPaint) + const Offset(50, 100));
      await tester.pump();
      expect(
        find.byType(FluentChartPopover),
        findsOneWidget,
        reason:
            'the React charts open the callout on click as well as hover; '
            'without it a touch user has no route to the values',
      );
    });

    testWidgets('keyboard focus opens it too', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        SizedBox(
          width: 400,
          height: 260,
          child: FluentCartesianChart(
            delegate: StubCartesianDelegate(),
            props: const FluentCartesianChartProps(hideLegend: true),
            legends: const <FluentChartLegendItem>[],
            focusNode: node,
          ),
        ),
      );
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(
        find.byType(FluentChartPopover),
        findsOneWidget,
        reason:
            'upstream keeps the callout mounted "for narration" '
            '(CartesianChart.tsx:922); a keyboard user must reach the same '
            'values a mouse user does',
      );
    });
  });

  group('Oracle B: charts-linechart--line-chart-basic', () {
    const storyId = 'charts-linechart--line-chart-basic';

    /// The one box of [slot] in [story], with a count guard so a renamed slot
    /// cannot make the assertion pass having measured nothing.
    OracleHtmlBox box(OracleStory story, String slot) {
      final matches = story.boxes(slot);
      expect(
        matches.length,
        1,
        reason: '$storyId must capture exactly one $slot box',
      );
      return matches.single;
    }

    test('the legend row sits below the plot at the captured inset', () {
      final story = loadOracleStory(storyId);
      final wrapper = box(story, 'fui-cart__chartWrapper');
      final legend = box(story, 'fui-legend__root');
      final padding =
          resolveFluentCartesianChartStyle(
                FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
              ).legendRowPadding!
              .resolve(const <WidgetState>{})!
              .resolve(TextDirection.ltr);

      expectOracleNumber(
        '$storyId gap between the chart wrapper and the legend root',
        legend.rect.top - wrapper.rect.bottom,
        padding.top,
      );
      expectOracleNumber(
        '$storyId legend start inset from the chart wrapper',
        legend.rect.left - wrapper.rect.left,
        padding.left,
      );
    });
  });

  group('Oracle B: charts-linechart--line-chart-secondary-y-axis', () {
    // The one captured story that renders all three axis groups, so a single
    // pump pins the whole pipeline: constraints, margin solve, layout, painter.
    const storyId = 'charts-linechart--line-chart-secondary-y-axis';

    /// The translated top-level `<g>` groups of [story], in document order: the
    /// x axis first (`CartesianChart.tsx:762-769`), the primary y next
    /// (`:836-842`).
    List<OracleElement> topLevelGroups(OracleStory story) => story
        .byTag('g')
        .where((g) => g.parent == -1 && g.translate != null)
        .toList();

    testWidgets('the solved layout lands on the captured axis transforms', (
      tester,
    ) async {
      final story = loadOracleStory(storyId);
      final groups = topLevelGroups(story);
      expect(
        groups.length,
        greaterThanOrEqualTo(2),
        reason:
            '$storyId must expose the x and primary y groups; a filtered loop '
            'that matched fewer would assert nothing',
      );
      // The secondary group hangs off a bare transformless wrapper (`:845-851`),
      // which is what separates it from the tick groups.
      final secondary = story.soleElement(
        'g',
        where: (g) {
          final parent = story.parentOf(g);
          return g.translate != null &&
              parent != null &&
              parent.transform == null &&
              parent.parent == -1;
        },
      );

      await pump(
        tester,
        chart(
          width: story.width,
          height: story.height,
          props: const FluentCartesianChartProps(
            hideLegend: true,
            secondaryYScaleOptions: FluentSecondaryYScaleOptions(),
          ),
        ),
      );
      final layout = painterOf(tester).layout;

      expectOracleNumber(
        '$storyId xAxisGElement translate y',
        story.absoluteTranslate(groups[0]).dy,
        layout.xAxisTranslateY,
      );
      expectOracleNumber(
        '$storyId yAxisGElement translate x',
        story.absoluteTranslate(groups[1]).dx,
        layout.yAxisTranslateX,
      );
      expectOracleNumber(
        '$storyId yAxisGElementSecondary translate x',
        story.absoluteTranslate(secondary).dx,
        layout.secondaryYAxisTranslateX,
      );
    });
  });

  group('annotation layer', () {
    Widget plot(List<FluentChartAnnotation> annotations) => SizedBox(
      width: 400,
      height: 260,
      child: FluentCartesianChart(
        delegate: StubCartesianDelegate(),
        props: FluentCartesianChartProps(
          hideLegend: true,
          annotations: annotations,
        ),
        legends: const <FluentChartLegendItem>[],
      ),
    );

    FluentChartAnnotationLayer layerOf(WidgetTester tester) =>
        tester.widget<FluentChartAnnotationLayer>(
          find.byType(FluentChartAnnotationLayer),
        );

    // The plan writes `FluentChartAnnotation(text: 'Peak')`; `coordinates` is
    // required (`chart_annotation.dart:387`), so the anchor is spelled out.
    const peak = FluentChartAnnotation(
      text: 'Peak',
      coordinates: FluentRelativeCoordinate(x: 0.5, y: 0.5),
    );

    testWidgets('no annotations means no layer', (tester) async {
      await pump(tester, plot(const <FluentChartAnnotation>[]));
      expect(
        find.byType(FluentChartAnnotationLayer),
        findsNothing,
        reason:
            '`hasAnnotations && annotationContext` at CartesianChart.tsx:903 '
            'builds the context only when the list is non-empty (:463-474)',
      );
    });

    testWidgets('one annotation mounts the layer over the marks', (
      tester,
    ) async {
      await pump(tester, plot(const <FluentChartAnnotation>[peak]));
      expect(
        find.byType(FluentChartAnnotationLayer),
        findsOneWidget,
        reason: 'CartesianChart.tsx:903-909, outside the svg and above it',
      );
    });

    testWidgets('the context carries the plot rect and the chart size', (
      tester,
    ) async {
      await pump(tester, plot(const <FluentChartAnnotation>[peak]));
      final context = layerOf(tester).context;
      expect(
        context.plotRect,
        const Rect.fromLTWH(40, 20, 340, 205),
        reason: 'plotRect at CartesianChart.tsx:456-461',
      );
      expect(
        context.plotRect,
        painterOf(tester).layout.plotRect,
        reason: 'the layer resolves against the very box the marks paint in',
      );
      expect(
        context.chartSize,
        const Size(400, 260),
        reason: 'svgRect at CartesianChart.tsx:468',
      );
      expect(context.isRtl, isFalse, reason: 'CartesianChart.tsx:469');
    });

    testWidgets('the context carries the same scales the painter has', (
      tester,
    ) async {
      await pump(tester, plot(const <FluentChartAnnotation>[peak]));
      final painter = painterOf(tester);
      expect(
        layerOf(tester).context.xScale,
        same(painter.xAxis.scale),
        reason:
            'annotations position against the same scales the marks do '
            '(CartesianChart.tsx:470-472)',
      );
      expect(
        layerOf(tester).context.yScalePrimary,
        same(painter.yAxisPrimary.scale),
        reason: 'the primary y scale is the same object too (:471)',
      );
    });
  });

  group('the plan-07 shell hooks', () {
    testWidgets(
      'overlayBuilder mounts a widget layer with context and layout',
      (tester) async {
        FluentCartesianLayout? seenLayout;
        FluentCartesianChildContext? seenContext;
        await pump(
          tester,
          SizedBox(
            width: 400,
            height: 260,
            child: FluentCartesianChart(
              delegate: StubCartesianDelegate(),
              props: const FluentCartesianChartProps(hideLegend: true),
              legends: const <FluentChartLegendItem>[],
              overlayBuilder: (context, childContext, layout) {
                seenLayout = layout;
                seenContext = childContext;
                return const SizedBox.expand(key: ValueKey<String>('overlay'));
              },
            ),
          ),
        );
        expect(
          find.byKey(const ValueKey<String>('overlay')),
          findsOneWidget,
          reason:
              'the event-annotation band is a widget layer over the marks — '
              'LineChart.tsx:1954-1961',
        );
        expect(
          seenLayout?.margins.top,
          20,
          reason:
              'chartYTop is `margins.top + eventLabelHeight` '
              '(LineChart.tsx:1958), so the builder needs the resolved margins',
        );
        expect(
          seenContext?.xScale,
          isNotNull,
          reason:
              'and `scale={props.xScale}` (:1957), so it needs the same scale '
              'the marks were painted with',
        );
      },
    );

    testWidgets('onPointerMoveInPlot reports the raw position and the scales', (
      tester,
    ) async {
      Offset? seen;
      FluentCartesianChildContext? seenContext;
      await pump(
        tester,
        SizedBox(
          width: 400,
          height: 260,
          child: FluentCartesianChart(
            delegate: StubCartesianDelegate(),
            props: const FluentCartesianChartProps(hideLegend: true),
            legends: const <FluentChartLegendItem>[],
            onPointerMoveInPlot: (local, childContext) {
              seen = local;
              seenContext = childContext;
            },
          ),
        ),
      );
      await hoverFirstStubRegion(tester);
      expect(
        seen,
        const Offset(50, 100),
        reason:
            'AreaChart.tsx:191 needs the analogue of `pointer(mouseEvent)[0]` '
            'to invert through the x scale. Here that is `event.localPosition` '
            '— CHART-local, origin at the chart top-left, not plot-relative — '
            'because the shell xScale range is built from '
            'FluentChartDomainRange.rStartValue/rEndValue, which are '
            'chart-space pixels. The left margin must NOT be subtracted',
      );
      expect(
        seenContext?.xScale.invert(seen!.dx),
        isNotNull,
        reason:
            'and it inverts that x through the scale before bisecting the '
            'series (:191-192)',
      );
    });

    testWidgets('chartTitleForSemantics wins over the delegate title', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        SizedBox(
          width: 400,
          height: 260,
          child: FluentCartesianChart(
            delegate: StubCartesianDelegate(),
            props: const FluentCartesianChartProps(
              hideLegend: true,
              chartTitleForSemantics: 'Line chart with 2 lines. ',
            ),
            legends: const <FluentChartLegendItem>[],
          ),
        ),
      );
      expect(
        find.bySemanticsLabel(RegExp('^Line chart with 2 lines[.] ')),
        findsOneWidget,
        reason:
            'the chart composes the prefix and the shell prepends it, '
            'CartesianChart.tsx:553 with LineChart.tsx:1843-1846',
      );
      expect(
        find.bySemanticsLabel(RegExp('Stub chart')),
        findsNothing,
        reason: "the delegate's own title is the fallback, not an addition",
      );
      handle.dispose();
    });

    testWidgets('mark granularity gives every segment its own stop', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(tester, stacked(node: node));
      node.requestFocus();
      await tester.pump();
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      }
      await tester.pump();
      expect(
        find.bySemanticsLabel('Segment 1 of stack 1'),
        findsOneWidget,
        reason:
            'four steps over four segment regions land on the last, which is '
            'the per-rect focus of VerticalStackedBarChart.tsx:1030-1042',
      );
      handle.dispose();
    });

    testWidgets('group granularity roves whole stacks', (tester) async {
      final handle = tester.ensureSemantics();
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        stacked(node: node, granularity: FluentChartHitGranularity.group),
      );
      node.requestFocus();
      await tester.pump();
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      }
      await tester.pump();
      expect(
        find.bySemanticsLabel('Stack 1'),
        findsOneWidget,
        reason:
            'the two segments of a stack merge into one stop, so four circular '
            'steps over two stops land on the second — '
            'VerticalStackedBarChart.tsx:1141-1153',
      );
      handle.dispose();
    });

    testWidgets('a merged group hovers over the union of its segments', (
      tester,
    ) async {
      await pump(tester, stacked(granularity: FluentChartHitGranularity.group));
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      // 45 logical pixels below the plot's top edge, which is inside the
      // SECOND segment of the first stack — LTWH(40, 50, 40, 30) — and outside
      // the first, so only the merged bounds can contain it.
      await gesture.moveTo(
        tester.getTopLeft(find.byType(FluentCartesianChart)) +
            const Offset(60, 65),
      );
      await tester.pump();
      expect(
        tester
            .widget<FluentChartPopover>(find.byType(FluentChartPopover))
            .data
            .xValue,
        'Stack 0',
        reason:
            'the first region of a group carries the group-wide callout, which '
            'is what `_getAriaLabel(singleChartData)` and the stack-wide '
            'YValueHover give it (VerticalStackedBarChart.tsx:1146, :281-292)',
      );
    });

    testWidgets('the popover anchors to the pointer by default', (
      tester,
    ) async {
      await pump(tester, anchored(anchorsToRegion: false));
      await hoverFirstStubRegion(tester);
      expect(
        tester
            .widget<FluentChartPopover>(find.byType(FluentChartPopover))
            .anchor,
        const Offset(50, 100),
        reason:
            'the zero-size virtual element at the cursor, '
            'ChartPopover.tsx:23-40',
      );
    });

    testWidgets('popoverAnchorsToRegion anchors to the region centre', (
      tester,
    ) async {
      await pump(tester, anchored(anchorsToRegion: true));
      await hoverFirstStubRegion(tester);
      expect(
        tester
            .widget<FluentChartPopover>(find.byType(FluentChartPopover))
            .anchor,
        // The first stub region is 20 logical pixels wide at the plot's left
        // edge and as tall as the plot: LTWH(40, 20, 20, 205), so its centre is
        // (50, 122.5).
        const Offset(50, 122.5),
        reason:
            'GroupedVerticalBarChart hands Popover the bar element itself, '
            '.tsx:437 and :970',
      );
    });

    testWidgets('popoverBuilder replaces the popover body', (tester) async {
      await pump(
        tester,
        SizedBox(
          width: 400,
          height: 260,
          child: FluentCartesianChart(
            delegate: StubCartesianDelegate(),
            props: FluentCartesianChartProps(
              hideLegend: true,
              popoverBuilder: (context) => const Text('custom'),
            ),
            legends: const <FluentChartLegendItem>[],
          ),
        ),
      );
      await hoverFirstStubRegion(tester);
      expect(
        find.text('custom'),
        findsOneWidget,
        reason:
            'customizedCallout is rendered in place of the default body, '
            'ChartPopover.tsx:54',
      );
      expect(
        find.byType(FluentChartPopover),
        findsNothing,
        reason:
            'and the two default bodies are both suppressed by it (:56, :60)',
      );
    });

    testWidgets('hideTooltip suppresses a custom body too', (tester) async {
      await pump(
        tester,
        SizedBox(
          width: 400,
          height: 260,
          child: FluentCartesianChart(
            delegate: StubCartesianDelegate(),
            props: FluentCartesianChartProps(
              hideLegend: true,
              hideTooltip: true,
              popoverBuilder: (context) => const Text('custom'),
            ),
            legends: const <FluentChartLegendItem>[],
          ),
        ),
      );
      await hoverFirstStubRegion(tester);
      expect(
        find.text('custom'),
        findsNothing,
        reason:
            'the first operand of CartesianChart.tsx:444 gates the whole '
            'callout, custom body included',
      );
    });

    testWidgets('eventLabelHeight reserves no plot space', (tester) async {
      await pump(
        tester,
        SizedBox(
          width: 400,
          height: 260,
          child: FluentCartesianChart(
            delegate: StubCartesianDelegate(),
            props: const FluentCartesianChartProps(hideLegend: true),
            legends: const <FluentChartLegendItem>[],
          ),
        ),
      );
      final plain = painterOf(tester).layout.plotRect;
      await pump(
        tester,
        SizedBox(
          width: 400,
          height: 260,
          child: FluentCartesianChart(
            delegate: StubCartesianDelegate(),
            props: const FluentCartesianChartProps(
              hideLegend: true,
              eventLabelHeight: 36,
            ),
            legends: const <FluentChartLegendItem>[],
          ),
        ),
      );
      expect(
        painterOf(tester).layout.plotRect,
        plain,
        reason:
            'parity: CartesianChart.tsx:295-312 never puts eventLabelHeight '
            'into YAxisParams, so the reserve at utilities.ts:848 is dead and '
            "LineChart's event labels overlap the top of the plot",
      );
    });
  });
}

/// A stub whose two stacks each contribute two segment regions sharing one
/// index — the shape `VerticalStackedBarChart` emits when `isCalloutForStack`
/// moves the focus props from each rect onto the stack group
/// (`VerticalStackedBarChart.tsx:1141-1153`). The lower segment comes first and
/// carries the stack-wide callout and narration, exactly as
/// `_getAriaLabel(singleChartData)` does at `:1146`.
class _StackedStubDelegate extends StubCartesianDelegate {
  _StackedStubDelegate() : super(hitRegionCount: 0);

  @override
  List<FluentChartHitRegion> buildHitRegions(
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
  ) => <FluentChartHitRegion>[
    for (var stack = 0; stack < 2; stack++)
      for (var segment = 0; segment < 2; segment++)
        FluentChartHitRegion(
          // Two 40x30 segments stacked at the top of the plot, the first stack
          // at the plot's left edge and the second 40px to its right.
          bounds: Rect.fromLTWH(
            layout.plotRect.left + stack * 40,
            layout.plotRect.top + segment * 30,
            40,
            30,
          ),
          index: stack,
          legend: 'Segment $segment',
          popoverData: FluentChartPopoverData(
            xValue: segment == 0 ? 'Stack $stack' : 'Segment $segment',
            legend: 'Segment $segment',
            yValue: '10',
          ),
          semanticsLabel: segment == 0
              ? 'Stack $stack'
              : 'Segment $segment of stack $stack',
        ),
  ];
}
