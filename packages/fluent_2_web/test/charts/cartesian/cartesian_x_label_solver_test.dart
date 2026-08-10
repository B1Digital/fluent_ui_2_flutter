import 'dart:math' as math;

import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:fluent_2_web/src/charts/internal/d3/axis_geometry.dart';
import 'package:fluent_2_web/src/charts/internal/d3/scale_band.dart' as d3;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/oracle_fixture.dart';

/// A measurer that replays metrics captured from the browser, so a layout can
/// be compared against Oracle B without depending on the host's font stack.
class _ReplayedMeasurer extends FluentChartTextMeasurer {
  _ReplayedMeasurer(this.captured);

  /// Metrics by label text.
  final Map<String, FluentChartTextMetrics> captured;

  @override
  FluentChartTextMetrics measure(String text, TextStyle style) {
    final metrics = captured[text];
    if (metrics == null) {
      throw StateError('No captured metrics for "$text".');
    }
    return metrics;
  }
}

/// `_transformXAxisLabels` (`CartesianChart.tsx:614-653`) plus the automatic
/// branch at `:282-293`. The ordering is the behaviour: both the wrap branch
/// and the rotate branch can run, and the rotate branch **overwrites** the
/// reserve rather than adding to it, while the automatic layout replaces both.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
  final measurer = FluentChartTextMeasurer();
  final textStyle = FluentChartTextStyles.of(theme).axisTick;

  FluentAxisSpec bandAxis(List<String> categories, double width) {
    final scale = d3.scaleBand()
      ..domainOf(List<Object>.of(categories))
      ..rangeOf(<double>[0, width]);
    return FluentAxisSpec(
      scale: scale,
      tickValues: List<Object>.of(categories),
      tickLabels: categories,
      orientation: FluentAxisOrientation.bottom,
      // d3-axis's own defaults (`d3-axis/src/axis.js:41-43`), which the shell
      // never overrides on a bottom axis.
      tickSizeInner: 6,
      tickSizeOuter: 6,
      tickPadding: 10,
    );
  }

  FluentXAxisLabelLayout? solve(
    FluentCartesianChartProps props, {
    required List<String> categories,
    double containerWidth = 400,
    double marginBottom = 35,
    FluentTickLayout tickLayout = FluentTickLayout.defaultLayout,
  }) => solveFluentCartesianXAxisLabels(
    props: props,
    xAxis: bandAxis(categories, containerWidth),
    xAxisType: FluentChartAxisType.category,
    tickLayout: tickLayout,
    datasetForXAxisDomain: categories,
    containerWidth: containerWidth,
    marginBottom: marginBottom,
    textStyle: textStyle,
    measurer: measurer,
  );

  const categories = <String>['Alpha beta', 'Gamma delta', 'Epsilon zeta'];

  test('no transformation prop returns null, so the reserve is zero', () {
    expect(
      solve(const FluentCartesianChartProps(), categories: categories),
      isNull,
      reason:
          '_removalValueForTextTuncate stays at its reset value of 0 when '
          'neither wrap, tooltip nor rotate is set (CartesianChart.tsx:615)',
    );
  });

  test('rotation adds the bottom margin to the rotated height', () {
    final rotated = rotateXAxisLabels(
      categories,
      style: textStyle,
      measurer: measurer,
    );
    final layout = solve(
      const FluentCartesianChartProps(rotateXAxisLables: true),
      categories: categories,
    );
    expect(
      layout,
      isNotNull,
      reason: 'the rotate branch always produces a layout',
    );
    expect(
      layout!.reserveHeight,
      // 35 is the `marginBottom` the local `solve` helper passes.
      rotated.reserveHeight + 35,
      reason:
          'CartesianChart.tsx:651 reuses margins.bottom as padding on top of '
          'the rotated height',
    );
    expect(
      layout.rotationRadians,
      closeTo(-math.pi / 4, 1e-12),
      reason: 'rotateXAxisLabels writes rotate(-45), utilities.ts:1815',
    );
  });

  test('rotation is skipped when wrapping is also on', () {
    final layout = solve(
      const FluentCartesianChartProps(
        wrapXAxisLables: true,
        rotateXAxisLables: true,
      ),
      categories: categories,
    );
    expect(
      layout!.rotationRadians,
      0,
      reason:
          'the rotate guard at CartesianChart.tsx:644 is '
          '`!wrapXAxisLables && rotateXAxisLables`',
    );
  });

  test('rotation is skipped on a non-category x axis', () {
    final layout = solveFluentCartesianXAxisLabels(
      props: const FluentCartesianChartProps(rotateXAxisLables: true),
      xAxis: bandAxis(categories, 400),
      xAxisType: FluentChartAxisType.numeric,
      tickLayout: FluentTickLayout.defaultLayout,
      datasetForXAxisDomain: categories,
      containerWidth: 400,
      marginBottom: 35,
      textStyle: textStyle,
      measurer: measurer,
    );
    expect(
      layout,
      isNull,
      reason:
          'the same guard requires XAxisTypes.StringAxis '
          '(CartesianChart.tsx:644)',
    );
  });

  test('the automatic tick layout replaces both branches', () {
    final layout = solve(
      const FluentCartesianChartProps(rotateXAxisLables: true),
      categories: categories,
      tickLayout: FluentTickLayout.auto,
    );
    expect(
      layout!.rotationRadians,
      0,
      reason:
          'CartesianChart.tsx:282-293 takes the auto branch instead of calling '
          '_transformXAxisLabels at all',
    );
  });

  test(
    'a multi-category band wraps at the step, a single one at the width',
    () {
      final narrow = solve(
        const FluentCartesianChartProps(wrapXAxisLables: true),
        categories: categories,
        containerWidth: 90,
      );
      final wide = solve(
        const FluentCartesianChartProps(wrapXAxisLables: true),
        categories: const <String>['Alpha beta'],
        containerWidth: 900,
      );
      expect(
        narrow!.labels.first.lines.length,
        greaterThan(1),
        reason:
            'with more than one category the wrap width is _xScale.step() '
            '(CartesianChart.tsx:627), which is about 30px here',
      );
      expect(
        wide!.labels.first.lines.length,
        1,
        reason:
            'with a single category the wrap width is containerWidth '
            '(CartesianChart.tsx:629)',
      );
    },
  );

  group('Oracle B — charts-verticalbarchart--vertical-bar-rotate-labels', () {
    // The one captured story that sets `rotateXAxisLables`. It pins the whole
    // chain this solver closes: the rotated tick geometry upstream measured,
    // the margin the solver adds to it, and the y the x-axis group was finally
    // translated to.
    const storyId = 'charts-verticalbarchart--vertical-bar-rotate-labels';

    test('the reserve places the x axis where the browser placed it', () {
      final story = loadOracleStory(storyId);

      bool isRotated(OracleElement? element) =>
          (element?.transform ?? '').contains('rotate(-45)');

      final tickTexts = <OracleElement>[
        for (final element in story.byTag('text'))
          if (isRotated(story.parentOf(element))) element,
      ];

      // Count guard: the story has four categories, so a re-capture that lost
      // the rotated x axis would leave the replayed metrics below empty and
      // every assertion vacuous.
      expect(
        tickTexts,
        hasLength(4),
        reason:
            '$storyId captured four rotated x-axis tick labels; a different '
            'count means the fixture no longer describes the axis this test '
            'reads.',
      );

      // The tick text's `y` is d3-axis's `spacing` and its `dy` is 0.71em
      // (`d3-axis/src/axis.js:46`, `:72`), so the alphabetic baseline sits at
      // `y + 0.71 * fontSize` and the captured getBBox top and bottom give the
      // ascent and descent Chrome resolved for 10px Segoe UI.
      const fontSize = 10.0;
      const baseDyEm = 0.71;
      final captured = <String, FluentChartTextMetrics>{};
      final labels = <String>[];
      for (final text in tickTexts) {
        final label = text.text!;
        final bbox = text.bbox!;
        final baseline = text.y! + baseDyEm * fontSize;
        labels.add(label);
        captured[label] = FluentChartTextMetrics(
          width: bbox.width,
          height: bbox.height,
          ascent: baseline - bbox.top,
          descent: bbox.bottom - baseline,
          xHeight: fontSize * FluentChartTextMetrics.xHeightRatio,
        );
      }

      const props = FluentCartesianChartProps(rotateXAxisLables: true);
      // The story draws no axis title and no annotation, and its y tick labels
      // are narrow enough to leave the left default in force, so the solved
      // bottom is the untouched default rather than a number this test picked.
      final marginBottom = FluentCartesianMarginSolver.solve(
        props: props,
        startFromX: 0,
        isRtl: false,
      ).bottom!;
      expectOracleNumber('solved bottom margin', 35, marginBottom);

      final layout = solveFluentCartesianXAxisLabels(
        props: props,
        xAxis: FluentAxisSpec(
          scale: d3.scaleBand()
            ..domainOf(List<Object>.of(labels))
            ..rangeOf(<double>[0, story.width]),
          tickValues: List<Object>.of(labels),
          tickLabels: labels,
          orientation: FluentAxisOrientation.bottom,
          tickSizeInner: 6,
          tickSizeOuter: 6,
          tickPadding: 10,
        ),
        xAxisType: FluentChartAxisType.category,
        tickLayout: FluentTickLayout.defaultLayout,
        datasetForXAxisDomain: labels,
        containerWidth: story.width,
        marginBottom: marginBottom,
        textStyle: const TextStyle(fontSize: fontSize),
        measurer: _ReplayedMeasurer(captured),
      );

      // The x-axis group is the rotated ticks' grandparent: `<g class=xAxis>`
      // holds one `<g class=tick>` per category and each tick holds the text.
      final xAxisGroup = story.parentOf(story.parentOf(tickTexts.first)!)!;
      final translate = xAxisGroup.translate;
      expect(
        translate,
        isNotNull,
        reason:
            'the x-axis group carries a pure translate; a compound transform '
            'means the fixture changed shape',
      );

      // `CartesianChart.tsx:768` renders the x axis at
      // `translate(0, svgDimensions.height - margins.bottom - removalValue)`,
      // and `svgDimensions.height` is the captured svg height.
      expectOracleNumber(
        'x-axis group translate y',
        translate!.dy,
        story.height - marginBottom - layout!.reserveHeight,
      );
    });
  });
}
