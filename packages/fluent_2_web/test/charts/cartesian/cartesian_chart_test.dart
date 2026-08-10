/// The shell replaces `_fitParentContainer` (`CartesianChart.tsx:497-528`) with
/// `BoxConstraints`: the legend is a `Column` sibling, so its height is taken
/// out of the plot by Flutter's own layout rather than by measuring a div.
library;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/cartesian/cartesian_chart.dart';
import 'package:fluent_2_web/src/charts/cartesian/cartesian_chart_props.dart';
import 'package:fluent_2_web/src/charts/cartesian/cartesian_chart_style.dart';
import 'package:fluent_2_web/src/charts/cartesian/cartesian_painter.dart';
import 'package:fluent_2_web/src/charts/chrome/legend.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
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
}
