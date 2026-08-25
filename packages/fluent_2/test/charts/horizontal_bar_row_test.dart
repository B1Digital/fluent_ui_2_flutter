import 'dart:ui' as ui;

import 'package:fluent_2/src/charts/horizontal_bar_chart.dart';
import 'package:fluent_2/src/charts/internal/chart_colors.dart';
import 'package:fluent_2/src/charts/internal/chart_text_measurer.dart';
import 'package:fluent_2/src/charts/model/bar_data.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/oracle_fixture.dart';

/// Records the draw calls a [CustomPainter] makes.
///
/// The two things worth asserting about the strip painter — which rectangles it
/// fills, in what colour, and where it puts the absolute-scale label — are
/// invisible to a widget finder and only approximately visible in a raster, so
/// the calls themselves are captured instead. Everything the painter does not
/// call is absorbed by [noSuchMethod].
class _RecordingCanvas implements Canvas {
  final List<Rect> rects = <Rect>[];
  final List<Color> fills = <Color>[];
  final List<Offset> paragraphs = <Offset>[];

  @override
  void drawRect(Rect rect, Paint paint) {
    rects.add(rect);
    fills.add(paint.color);
  }

  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) =>
      paragraphs.add(offset);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// The two painters are asserted three ways: by rasterising them and reading
/// pixels back, because a dimmed bar landing on alpha 26 is a blend the paint
/// object alone does not prove; by recording the draw calls, because the
/// absolute-scale label's origin is a number no finder exposes; and against
/// oracle B, because upstream captured both.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  FluentChartDataPoint point(double x) => FluentChartDataPoint(
    legend: 'x$x',
    horizontalBarChartData: FluentHorizontalDataPoint(x: x, total: 100),
  );

  Future<ui.Image> raster(CustomPainter painter, Size size) async {
    final recorder = ui.PictureRecorder();
    painter.paint(Canvas(recorder), size);
    return recorder.endRecording().toImage(
      size.width.ceil(),
      size.height.ceil(),
    );
  }

  Future<int> pixelAt(ui.Image image, int x, int y) async {
    final data = await image.toByteData();
    final offset = (y * image.width + x) * 4;
    return data!.getUint32(offset);
  }

  _RecordingCanvas record(CustomPainter painter, Size size) {
    final canvas = _RecordingCanvas();
    painter.paint(canvas, size);
    return canvas;
  }

  test('a dimmed bar rasterises to alpha 26', () async {
    final layout = FluentHorizontalBarRowLayout.compute(
      points: <FluentChartDataPoint>[point(100)],
      rowWidth: 100,
      barGap: 3,
      isRtl: false,
    );
    final image = await raster(
      FluentHorizontalBarStripPainter(
        layout: layout,
        fills: const <Color>[Color(0xFF000000)],
        opacities: const <double>[0.1],
        barHeight: 12,
        textDirection: TextDirection.ltr,
      ),
      const Size(100, 12),
    );
    final rgba = await pixelAt(image, 50, 6);
    expect(
      rgba & 0xFF,
      26,
      reason:
          'HorizontalBarChart.tsx:327 dims to opacity 0.1, and '
          '(0.1 * 255).round() is 26.',
    );
  });

  test('a highlighted bar rasterises fully opaque', () async {
    final layout = FluentHorizontalBarRowLayout.compute(
      points: <FluentChartDataPoint>[point(100)],
      rowWidth: 100,
      barGap: 3,
      isRtl: false,
    );
    final image = await raster(
      FluentHorizontalBarStripPainter(
        layout: layout,
        fills: const <Color>[Color(0xFF000000)],
        opacities: const <double>[1],
        barHeight: 12,
        textDirection: TextDirection.ltr,
      ),
      const Size(100, 12),
    );
    expect(
      await pixelAt(image, 50, 6) & 0xFF,
      255,
      reason: 'HorizontalBarChart.tsx:327 — the only other state is 1.',
    );
  });

  // `opacity` is an SVG presentation attribute: it composites the element at
  // that factor, so it MULTIPLIES the fill's own alpha. Only the synthesised
  // remainder bar is translucent today — `colorBackgroundOverlay`, rgba(0, 0,
  // 0, 0.4) (`HorizontalBarChart.tsx:411`) — and it is the whole reason this
  // matters: a painter that REPLACES the alpha turns the reference's grey into
  // opaque black in the undimmed state, which is what
  // `charts-horizontalbarchart--horizontal-bar-basic` measured at 53.841%.
  group('a translucent fill keeps its own alpha', () {
    // 0x66 is 102/255 — exactly the 0.4 of colorBackgroundOverlay.
    const overlay = Color(0x66000000);

    Future<int> alphaAt(double opacity) async {
      final layout = FluentHorizontalBarRowLayout.compute(
        points: <FluentChartDataPoint>[point(100)],
        rowWidth: 100,
        barGap: 3,
        isRtl: false,
      );
      final image = await raster(
        FluentHorizontalBarStripPainter(
          layout: layout,
          fills: const <Color>[overlay],
          opacities: <double>[opacity],
          barHeight: 12,
          textDirection: TextDirection.ltr,
        ),
        const Size(100, 12),
      );
      return await pixelAt(image, 50, 6) & 0xFF;
    }

    test('undimmed it stays at 0.4, not 1', () async {
      expect(
        await alphaAt(1),
        102,
        reason:
            'opacity=1 multiplies rgba(0,0,0,0.4) by one and leaves it at '
            '0.4 — over the page it is the reference\'s grey, not black.',
      );
    });

    test('dimmed the two multiply to 0.04', () async {
      expect(
        await alphaAt(0.1),
        10,
        reason:
            'HorizontalBarChart.tsx:327 dims to 0.1, and 0.4 * 0.1 * 255 '
            'rounds to 10 — replacing the alpha would give 26.',
      );
    });
  });

  test('the painter draws every bar, including the one past the edge', () {
    final layout = FluentHorizontalBarRowLayout.compute(
      points: <FluentChartDataPoint>[point(30), point(40), point(30)],
      rowWidth: 400,
      barGap: 3,
      isRtl: false,
    );
    expect(
      layout.rectOf(2, 12).right,
      greaterThan(400),
      reason:
          'The painter must not clip: '
          'useHorizontalBarChartStyles.styles.ts:49 is overflow: visible, so '
          'the overflow is part of the rendering.',
    );
    final canvas = record(
      FluentHorizontalBarStripPainter(
        layout: layout,
        fills: const <Color>[
          Color(0xFF111111),
          Color(0xFF222222),
          Color(0xFF333333),
        ],
        opacities: const <double>[1, 1, 1],
        barHeight: 12,
        textDirection: TextDirection.ltr,
      ),
      const Size(400, 12),
    );
    expect(
      canvas.rects,
      <Rect>[layout.rectOf(0, 12), layout.rectOf(1, 12), layout.rectOf(2, 12)],
      reason:
          'HorizontalBarChart.tsx:306-330 returns one rect per point in data '
          'order, and there is no clip or intersect anywhere in the tree.',
    );
  });

  group('high contrast flattens every bar', () {
    // FluentChartColors.flattenMark rewrites a series fill to the axis-text
    // colour under the high-contrast palette (design spec section 5.3):
    // upstream's rects carry no forced-color-adjust, so a forced-colours
    // browser paints them all in CanvasText. Nothing else in the slot set is
    // read here, so the rest are placeholders.
    const canvasText = Color(0xFFFFFFFF);
    const placeholder = Color(0xFF010203);
    FluentChartColors colours({required bool isHighContrast}) =>
        FluentChartColors(
          axisText: canvasText,
          axisTick: placeholder,
          axisTitle: placeholder,
          gridLine: placeholder,
          markStroke: placeholder,
          surface: placeholder,
          popoverSurface: placeholder,
          tooltipSurface: placeholder,
          legendDimmed: placeholder,
          isHighContrast: isHighContrast,
        );

    final layout = FluentHorizontalBarRowLayout.compute(
      points: <FluentChartDataPoint>[point(30), point(70)],
      rowWidth: 400,
      barGap: 3,
      isRtl: false,
    );
    const palette = <Color>[Color(0xFF637CEF), Color(0xFFE3008C)];

    test('the palette survives an ordinary theme', () {
      final canvas = record(
        FluentHorizontalBarStripPainter(
          layout: layout,
          fills: palette,
          opacities: const <double>[1, 1],
          barHeight: 12,
          textDirection: TextDirection.ltr,
          colors: colours(isHighContrast: false),
        ),
        const Size(400, 12),
      );
      expect(
        canvas.fills.map((fill) => fill.toARGB32()),
        palette.map((fill) => fill.toARGB32()),
        reason:
            'FluentChartColors.flattenMark returns the series colour '
            'unchanged whenever isHighContrast is false.',
      );
    });

    test('every fill collapses to the axis-text colour under high contrast', () {
      final canvas = record(
        FluentHorizontalBarStripPainter(
          layout: layout,
          fills: palette,
          opacities: const <double>[1, 0.1],
          barHeight: 12,
          textDirection: TextDirection.ltr,
          colors: colours(isHighContrast: true),
        ),
        const Size(400, 12),
      );
      expect(
        canvas.fills.map((fill) => fill.withValues(alpha: 1).toARGB32()),
        everyElement(canvasText.toARGB32()),
        reason:
            'Design spec section 5.3: the forty-colour palette is invisible in '
            'forced-colours mode because upstream sets no forced-color-adjust, '
            'so every bar flattens to the system foreground.',
      );
      expect(
        canvas.fills[1].a,
        closeTo(0.1, 1 / 255),
        reason:
            'Flattening replaces the hue, not the highlight state — '
            'HorizontalBarChart.tsx:327 still dims the unhighlighted bar.',
      );
    });
  });

  test('the benchmark triangle points down and centres on the ratio', () {
    const painter = FluentBenchmarkTrianglePainter(
      ratio: 0.25,
      colour: Color(0xFF0078D4),
      triangleWidth: 8,
      triangleHeight: 7,
    );
    final path = painter.buildPath(const Size(200, 7));
    final bounds = path.getBounds();
    expect(
      bounds.center.dx,
      closeTo(50, 1e-9),
      reason:
          'HorizontalBarChart.tsx:201 positions the triangle absolutely at '
          '`calc(ratio% - 4px)` and the div is 8 wide, so its centre lands on '
          'the ratio; 25% of 200 is 50.',
    );
    expect(
      bounds.width,
      closeTo(8, 1e-9),
      reason:
          'The 4px transparent left and right borders make the base 8 '
          'wide (useHorizontalBarChartStyles.styles.ts:87-88).',
    );
    expect(
      bounds.height,
      closeTo(7, 1e-9),
      reason:
          'The 7px top border is the height '
          '(useHorizontalBarChartStyles.styles.ts:89).',
    );
    expect(
      path.contains(const Offset(50, 6.5)),
      isTrue,
      reason:
          'A border-top triangle has its apex at the BOTTOM centre — the '
          'top edge is the wide base.',
    );
    expect(
      path.contains(const Offset(46.5, 6.5)),
      isFalse,
      reason: 'The bottom corners are outside the triangle.',
    );
  });

  test('the benchmark ratio is a rounded integer percentage', () {
    expect(
      FluentBenchmarkTrianglePainter.ratioFor(benchmark: 37.4, total: 100),
      closeTo(0.37, 1e-12),
      reason:
          'HorizontalBarChart.tsx:198 is '
          'Math.round(data / total * 100), so the position quantises to whole '
          'percentage points.',
    );
    expect(
      FluentBenchmarkTrianglePainter.ratioFor(benchmark: 37.5, total: 100),
      closeTo(0.38, 1e-12),
      reason:
          'JavaScript rounds a half up; the js_math helper from plan 01 '
          'is what makes a negative half agree too.',
    );
    expect(
      FluentBenchmarkTrianglePainter.ratioFor(benchmark: 5, total: 0),
      0,
      reason:
          'A zero total is `Math.round(5 / 0 * 100)`, which is Infinity in '
          'JavaScript; the guard keeps the marker at the origin instead of '
          'propagating a non-finite offset into a Path.',
    );
  });

  group('oracle B: the absolute-scale rows', () {
    // The one HorizontalBarChart story whose placeholder point renders as a
    // <text> instead of a second rect (`HorizontalBarChart.tsx:284-304`), so it
    // is the only capture that pins the label's origin.
    const storyId = 'charts-horizontalbarchart--horizontal-bar-absolute-scale';

    // `MARGIN_WIDTH_IN_PX` (`HorizontalBarChart.tsx:364`).
    const barGap = 3.0;

    // `transform={`translate(${_isRTL ? -4 : 4})`}`
    // (`HorizontalBarChart.tsx:297`).
    const labelOffset = 4.0;

    test('the story is in the corpus', () {
      expect(
        oracleStoryIds(component: 'HorizontalBarChart'),
        contains(storyId),
        reason:
            'The loop below skips silently if the id drifts; this guard is '
            'what fails instead.',
      );
    });

    test('every captured row places its bar and its label', () {
      final story = loadOracleStory(storyId);
      expect(
        story.svgs,
        isNotEmpty,
        reason: '$storyId must have captured at least one row svg.',
      );
      var rowsChecked = 0;
      for (final svg in story.svgs) {
        final rect = svg.elements.singleWhere(
          (element) => element.tag == 'rect',
        );
        final text = svg.elements.singleWhere(
          (element) => element.tag == 'text',
        );

        // Upstream writes `x` and `width` as percentage strings
        // (`HorizontalBarChart.tsx:309-315`), so the captured share is the
        // point's percentage of the total and feeding it back in with a total
        // of 100 reconstructs the input. The second point is the placeholder
        // upstream synthesises as `total - x` (`:400-413`).
        final share = rect.width!;
        final layout = FluentHorizontalBarRowLayout.compute(
          points: <FluentChartDataPoint>[
            FluentChartDataPoint(
              horizontalBarChartData: FluentHorizontalDataPoint(
                x: share,
                total: 100,
              ),
            ),
            FluentChartDataPoint(
              horizontalBarChartData: FluentHorizontalDataPoint(
                x: 100 - share,
                total: 100,
              ),
            ),
          ],
          rowWidth: svg.width,
          barGap: barGap,
          isRtl: false,
        );

        final canvas = record(
          FluentHorizontalBarStripPainter(
            layout: layout,
            fills: const <Color>[Color(0xFF9A3D0C), Color(0xFF000000)],
            opacities: const <double>[1, 1],
            barHeight: rect.height!,
            textDirection: TextDirection.ltr,
            absoluteLabel: text.text,
            absoluteLabelStyle: const TextStyle(fontSize: 12),
            absoluteLabelOffset: labelOffset,
            absoluteLabelIndex: 1,
          ),
          Size(svg.width, rect.height!),
        );

        expect(
          canvas.rects,
          hasLength(1),
          reason:
              '$storyId row $rowsChecked: HorizontalBarChart.tsx:284 returns a '
              '<text> for the placeholder under the absolute-scale variant, so '
              'the placeholder rect is never drawn.',
        );
        expectOracleRect(
          '$storyId row $rowsChecked: the value bar',
          rect.bbox!,
          canvas.rects.single,
        );
        expect(
          canvas.paragraphs,
          hasLength(1),
          reason: '$storyId row $rowsChecked draws exactly one label.',
        );
        expectOracleNumber(
          '$storyId row $rowsChecked: the label origin',
          text.bbox!.left + labelOffset,
          canvas.paragraphs.single.dx,
        );
        rowsChecked++;
      }
      expect(
        rowsChecked,
        story.svgs.length,
        reason: 'Every captured row of $storyId must have been asserted.',
      );
      expect(
        rowsChecked,
        greaterThan(1),
        reason:
            'A single row would not exercise the label at a share of 100%, '
            'where the origin lands past the row edge.',
      );
    });
  });

  test('the label is vertically centred on half the bar height', () {
    final layout = FluentHorizontalBarRowLayout.compute(
      points: <FluentChartDataPoint>[point(30), point(70)],
      rowWidth: 400,
      barGap: 3,
      isRtl: false,
    );
    const barHeight = 12.0;
    const style = TextStyle(fontSize: 12);
    final canvas = record(
      FluentHorizontalBarStripPainter(
        layout: layout,
        fills: const <Color>[Color(0xFF111111), Color(0xFF222222)],
        opacities: const <double>[1, 1],
        barHeight: barHeight,
        textDirection: TextDirection.ltr,
        absoluteLabel: '1.5k',
        absoluteLabelStyle: style,
        absoluteLabelIndex: 1,
      ),
      const Size(400, barHeight),
    );
    final height = FluentChartTextMeasurer().measure('1.5k', style).height;
    expect(
      canvas.paragraphs.single.dy + height / 2,
      closeTo(barHeight / 2, 1e-9),
      reason:
          'HorizontalBarChart.tsx:295-296 puts the label at y = barHeight / 2 '
          'with dominant-baseline "central", which centres the em box on that '
          'y — the same offset FluentChartTextMetrics.centralOffset exposes.',
    );
  });

  test('right-to-left mirrors the label anchor and the translate sign', () {
    final layout = FluentHorizontalBarRowLayout.compute(
      points: <FluentChartDataPoint>[point(30), point(70)],
      rowWidth: 400,
      barGap: 3,
      isRtl: true,
    );
    final canvas = record(
      FluentHorizontalBarStripPainter(
        layout: layout,
        fills: const <Color>[Color(0xFF111111), Color(0xFF222222)],
        opacities: const <double>[1, 1],
        barHeight: 12,
        textDirection: TextDirection.rtl,
        absoluteLabel: '1.5k',
        absoluteLabelStyle: const TextStyle(fontSize: 12),
        absoluteLabelIndex: 1,
      ),
      const Size(400, 12),
    );
    expect(
      canvas.paragraphs.single.dx,
      closeTo(400 * 0.7 - 4, 1e-9),
      reason:
          'HorizontalBarChart.tsx:294 anchors the label at '
          '`100 - startingPoint[index]` under RTL — the starting point is 30, '
          'so the anchor is 70% — and :297 flips the translate to -4.',
    );
  });
}
