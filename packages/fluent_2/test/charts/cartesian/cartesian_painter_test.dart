// `CartesianChart.tsx:753-902` paints in a fixed order: x axis, x title,
// x annotation, y axis with its gridlines, the secondary y axis and title,
// **then** the series, then the y title and y annotation. Gridlines sit under
// the marks and the y title sits over them.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:fluent_2/src/charts/axis/axis_types.dart';
import 'package:fluent_2/src/charts/cartesian/cartesian_chart_props.dart';
import 'package:fluent_2/src/charts/cartesian/cartesian_chart_style.dart';
import 'package:fluent_2/src/charts/cartesian/cartesian_layout.dart';
import 'package:fluent_2/src/charts/cartesian/cartesian_painter.dart';
import 'package:fluent_2/src/charts/internal/chart_colors.dart';
import 'package:fluent_2/src/charts/internal/chart_text_measurer.dart';
import 'package:fluent_2/src/charts/internal/chart_text_styles.dart';
import 'package:fluent_2/src/charts/model/chart_common.dart';
import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/oracle_fixture.dart';
import 'support/stub_cartesian_delegate.dart';

/// The two stories whose captured document order **is** the z-order under test:
/// SVG paints in document order, so an element's index in the capture is its
/// paint rank.
const String _lineStory = 'charts-linechart--line-chart-basic';
const String _secondaryStory = 'charts-areachart--area-chart-secondary-y-axis';

void main() {
  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
  const size = Size(400, 260);
  const margins = FluentChartMargins(left: 40, right: 20, top: 20, bottom: 35);

  FluentCartesianChartPainter build(
    StubCartesianDelegate delegate, {
    FluentCartesianChartProps props = const FluentCartesianChartProps(),
    Size chartSize = size,
    FluentChartMargins chartMargins = margins,
    bool withSecondary = false,
  }) {
    final layout = FluentCartesianLayout.resolve(
      size: chartSize,
      margins: chartMargins,
      xAxisLabelReserve: 0,
      isRtl: false,
      startFromX: 0,
    );
    final axisData = FluentAxisData();
    final yAxis = delegate.createYAxis(
      FluentYAxisParams(
        margins: chartMargins,
        containerWidth: chartSize.width,
        containerHeight: chartSize.height,
      ),
      axisData,
      isRtl: false,
      isIntegralDataset: true,
    );
    return FluentCartesianChartPainter(
      layout: layout,
      delegate: delegate,
      xAxis: yAxis,
      yAxisPrimary: yAxis,
      yAxisSecondary: withSecondary ? yAxis : null,
      xLabelLayout: null,
      style: resolveFluentCartesianChartStyle(theme),
      colors: FluentChartColors.of(theme),
      textStyles: FluentChartTextStyles.of(theme),
      measurer: FluentChartTextMeasurer(),
      // The corpus is captured at deviceScaleFactor 1 and `flutter test` runs
      // at DPR 1, so both sides sit on d3-axis's 0.5 (design spec §5.5).
      crispOffset: loadOracleStory(_lineStory).crispOffset,
      props: props,
    );
  }

  Future<ByteData> render(FluentCartesianChartPainter painter) async {
    final recorder = ui.PictureRecorder();
    painter.paint(Canvas(recorder), size);
    final image = await recorder.endRecording().toImage(
      size.width.round(),
      size.height.round(),
    );
    final bytes = await image.toByteData();
    image.dispose();
    return bytes!;
  }

  int pixelAt(ByteData bytes, int x, int y) =>
      bytes.getUint32((y * size.width.round() + x) * 4);

  // Every `translate` the painter issued, in order. The axis helper translates
  // to the axis group's origin and the title painter translates to the title's
  // anchor, so this list is the painter's own z-order made readable.
  List<Offset> translatesOf(FluentCartesianChartPainter painter, Size target) {
    final canvas = TestRecordingCanvas();
    painter.paint(canvas, target);
    return <Offset>[
      for (final record in canvas.invocations)
        if (record.invocation.memberName == #translate)
          Offset(
            record.invocation.positionalArguments[0] as double,
            record.invocation.positionalArguments[1] as double,
          ),
    ];
  }

  test(
    'the series is painted exactly once, with the resolved layout',
    () async {
      final delegate = StubCartesianDelegate();
      final painter = build(delegate);
      await render(painter);
      expect(
        delegate.paintCount,
        1,
        reason: 'paintSeries replaces props.children, CartesianChart.tsx:436',
      );
      expect(
        delegate.lastLayout!.plotRect,
        const Rect.fromLTWH(40, 20, 340, 205),
        reason: 'the layout travels with the paint call',
      );
    },
  );

  test('the child context carries the FULL container height', () async {
    final delegate = StubCartesianDelegate();
    await render(build(delegate));
    expect(
      delegate.lastContext!.containerHeight,
      260,
      reason:
          'children() receives containerHeight (CartesianChart.tsx:440) while '
          'getGraphData receives containerHeight - reserve (:425); the '
          'asymmetry is reproduced',
    );
    expect(
      delegate.lastContext!.containerWidth,
      400,
      reason: 'CartesianChart.tsx:441',
    );
  });

  test('the y-axis title paints OVER the series', () async {
    final delegate = StubCartesianDelegate(fillWholeCanvas: true);
    final painter = build(
      delegate,
      props: const FluentCartesianChartProps(yAxisTitle: 'Value'),
    );
    final bytes = await render(painter);
    // The y title anchors at x = 16 (HORIZONTAL_MARGIN_FOR_YAXIS_TITLE minus
    // AXIS_TITLE_PADDING, CartesianChart.tsx:482) and paints a backing rect,
    // so that pixel must not be the series colour.
    expect(
      pixelAt(bytes, 16, 130) == 0xFF0000FF,
      isFalse,
      reason:
          'the y title is emitted after {children} at CartesianChart.tsx:871, '
          'so it covers the marks',
    );
  });

  test('the gridlines paint UNDER the series', () async {
    final delegate = StubCartesianDelegate(fillWholeCanvas: true);
    final bytes = await render(build(delegate));
    expect(
      pixelAt(bytes, 200, 130),
      0xFF0000FF,
      reason:
          'the y-axis group is emitted at CartesianChart.tsx:836, before '
          '{children} at :870, so the marks cover its gridlines',
    );
  });

  test('shouldRepaint reacts to a changed layout', () {
    final a = build(StubCartesianDelegate());
    final b = FluentCartesianChartPainter(
      layout: FluentCartesianLayout.resolve(
        size: size,
        margins: margins,
        xAxisLabelReserve: 18,
        isRtl: false,
        startFromX: 0,
      ),
      delegate: a.delegate,
      xAxis: a.xAxis,
      yAxisPrimary: a.yAxisPrimary,
      xLabelLayout: null,
      style: a.style,
      colors: a.colors,
      textStyles: a.textStyles,
      measurer: a.measurer,
      crispOffset: a.crispOffset,
      props: a.props,
    );
    expect(b.shouldRepaint(a), isTrue, reason: 'a moved x axis must repaint');
    expect(
      a.shouldRepaint(a),
      isFalse,
      reason: 'an unchanged painter must not repaint',
    );
  });

  group('Oracle B — $_lineStory', () {
    final story = loadOracleStory(_lineStory);
    // The chart svg's direct children, in document order. Slot 0 is the x-axis
    // group (`translate(0, 205)`), 23/24 the x title's backing rect and text,
    // 26 the y-axis group (`translate(64, 0)`), 43 the series group, and 96/97
    // the y title's backing rect and text — the exact eight-layer order of
    // `CartesianChart.tsx:762-884`.
    final roots = story.elements
        .where((element) => element.parent < 0)
        .toList();

    // The story's own margins, read off the two axis groups rather than
    // assumed: the y-axis group translates by margins.left and the x-axis group
    // by height - margins.bottom - reserve, and this chart's numeric x axis
    // reserves nothing.
    final storyMargins = FluentChartMargins(
      left: story
          .soleElement(
            'g',
            where: (element) =>
                element.parent < 0 &&
                (element.translate?.dy ?? -1) == 0 &&
                (element.translate?.dx ?? 0) > 0,
          )
          .translate!
          .dx,
      right: 20,
      top: 20,
      bottom:
          story.height -
          story
              .soleElement(
                'g',
                where: (element) =>
                    element.parent < 0 && (element.translate?.dx ?? -1) == 0,
              )
              .translate!
              .dy,
    );

    test('the capture really does order the layers this way', () {
      final tags = roots.map((element) => element.tag).toList();
      expect(
        tags.length,
        greaterThanOrEqualTo(7),
        reason:
            'a guard on the filtered scan: fewer roots than layers means the '
            'ordering below was read off a capture that never rendered them',
      );
      final xAxisGroup = roots.indexWhere(
        (element) => (element.translate?.dx ?? -1) == 0,
      );
      final xTitle = roots.indexWhere(
        (element) => element.tag == 'text' && element.transform == null,
      );
      final yAxisGroup = roots.indexWhere(
        (element) =>
            element.tag == 'g' &&
            (element.translate?.dx ?? 0) == storyMargins.left,
      );
      final yTitle = roots.indexWhere(
        (element) =>
            element.tag == 'text' &&
            (element.transform ?? '').contains('rotate'),
      );
      final series = roots.indexWhere(
        (element) => element.tag == 'g' && element.transform == null,
      );
      expect(
        <int>[xAxisGroup, xTitle, yAxisGroup, series, yTitle],
        <int>[0, 2, 4, 5, 7],
        reason:
            'document order is paint order in SVG, and CartesianChart.tsx '
            'emits :762 the x axis, :771 its title, :836 the y axis, :870 the '
            'children and :871 the y title',
      );
    });

    test('the two axis-title anchors match the captured ones', () {
      final xTitle = story.soleElement(
        'text',
        where: (element) => element.parent < 0 && element.transform == null,
      );
      final yTitle = story.soleElement(
        'text',
        where: (element) =>
            element.parent < 0 && (element.transform ?? '').contains('rotate'),
      );
      final painter = build(
        StubCartesianDelegate(),
        props: FluentCartesianChartProps(
          xAxisTitle: xTitle.text,
          yAxisTitle: yTitle.text,
        ),
        chartSize: Size(story.width, story.height),
        chartMargins: storyMargins,
      );
      final translates = translatesOf(painter, Size(story.width, story.height));
      // Four translates: the x-axis group, the x title, the y-axis group, the
      // y title. Indices 1 and 3 are the two titles.
      expect(
        translates.length,
        4,
        reason:
            'a count guard: two axis groups and two titles, so a missing layer '
            'cannot be read as a passing anchor',
      );
      expectOracleOffset(
        'x-axis title anchor',
        Offset(xTitle.x!, xTitle.y!),
        translates[1],
      );
      expectOracleOffset(
        'y-axis title anchor',
        Offset(yTitle.x!, yTitle.y!),
        translates[3],
      );
    });
  });

  test('the secondary y-axis title paints BEFORE the series', () {
    final story = loadOracleStory(_secondaryStory);
    final secondaryTitle = story.soleElement(
      'text',
      where: (element) =>
          element.parent >= 0 && (element.transform ?? '').contains('rotate'),
    );
    final primaryTitle = story.soleElement(
      'text',
      where: (element) =>
          element.parent < 0 && (element.transform ?? '').contains('rotate'),
    );
    expect(
      secondaryTitle.index < primaryTitle.index,
      isTrue,
      reason:
          'CartesianChart.tsx:853 nests the secondary title in the secondary '
          'axis group, which closes at :866, four layers before :871',
    );

    final delegate = StubCartesianDelegate();
    final painter = build(
      delegate,
      props: FluentCartesianChartProps(
        secondaryYAxisTitle: secondaryTitle.text,
        // Suppressed by the secondary title at CartesianChart.tsx:887, so it
        // must contribute no translate at all.
        yAxisAnnotation: 'Hidden',
      ),
      chartSize: Size(story.width, story.height),
      chartMargins: const FluentChartMargins(
        left: 64,
        right: 64,
        top: 20,
        bottom: 55,
      ),
      withSecondary: true,
    );
    final canvas = TestRecordingCanvas();
    painter.paint(canvas, Size(story.width, story.height));
    final names = canvas.invocations
        .map((record) => record.invocation.memberName)
        .toList();
    final translates = translatesOf(painter, Size(story.width, story.height));
    expect(
      translates.length,
      4,
      reason:
          'the x axis, the primary y axis, the secondary y axis and its title '
          '— the suppressed y annotation adds none',
    );
    expectOracleNumber(
      'secondary y-axis title anchor x',
      secondaryTitle.x!,
      translates[3].dx,
    );
    expectOracleNumber(
      'secondary y-axis title anchor y',
      secondaryTitle.y!,
      translates[3].dy,
    );
    expect(
      names.indexOf(#rotate) < names.lastIndexOf(#drawRect),
      isTrue,
      reason:
          'the only rotate is the secondary title and the last drawRect is the '
          'stub series, so the title precedes the marks',
    );
  });

  test('a y-axis title longer than the plot is shaved to fit it', () async {
    // Every one of the shell's five SVGTooltipTexts carries a maxWidth —
    // `yAxisTitleMaxHeight` for the three rotated ones (`CartesianChart.tsx:865`,
    // `:882`, `:899`) — and SVGTooltipText shortens the content to it
    // (`SVGTooltipText.tsx:49` calling `wrapContent`, `utilities.ts:1232-1248`).
    //
    // The layout solved that bound from the start and the painter read neither
    // it nor `xAxisTitleMaxWidth`, so the title was painted at full length and
    // simply overran the chart. Caught as a pixel difference against the live
    // render of `charts-linechart--line-chart-basic`, whose 68-character y
    // title ran off both ends of a 300px-tall chart while upstream showed
    // "Different categories of mail flow ea...".
    //
    // The band: `titleMaxHeight` is height - bottom - top - reserve - 2*pad =
    // 260 - 35 - 20 - 0 - 16 = 189, centred on top + pad + 189/2 = 122.5, so a
    // fitted title lives inside y 28..217 and nothing may be painted outside
    // it. The column is `kHorizontalMarginForYAxisTitle - kAxisTitlePadding`
    // = 16, and the glyphs of a rotated line straddle it by half their height.
    //
    // The probed rows dodge the y tick labels, which share that column: the
    // stub's scale puts 100 at y 20, 50 at y ~122 and 0 at y ~225, each label
    // a line box tall, and a row landing on one reports painted whatever the
    // title does.
    const longTitle =
        'Different categories of mail flow each of which are categorized '
        'into different categories';
    final bytes = await render(
      build(
        StubCartesianDelegate(),
        props: const FluentCartesianChartProps(yAxisTitle: longTitle),
      ),
    );
    bool painted(int x, int y) => pixelAt(bytes, x, y) & 0xFF000000 != 0;

    for (var x = 10; x <= 22; x++) {
      for (final y in <int>[1, 4, 8, 246, 250, 254, 258]) {
        expect(
          painted(x, y),
          isFalse,
          reason:
              'the title may not paint at ($x, $y) — that is outside the '
              '28..217 band yAxisTitleMaxHeight allows',
        );
      }
    }
    // The positive control. Without it a title that stopped rendering at all
    // would pass every assertion above.
    expect(
      <bool>[for (var y = 40; y < 200; y++) painted(16, y)].any((p) => p),
      isTrue,
      reason: 'the shaved title is still painted inside the band',
    );
  });
}
