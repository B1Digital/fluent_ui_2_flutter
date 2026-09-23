import 'dart:convert';
import 'dart:ui' as ui;

import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every literal here is from `image-export-utils.ts:304-392` and
/// `useLegendsStyles.styles.ts:10-21`.
void main() {
  final measurer = FluentChartTextMeasurer();
  const textStyle = TextStyle(fontSize: 10);

  FluentSynthesisedLegendLayout layoutOf(
    List<String> titles, {
    double svgWidth = 400,
    Set<String> selected = const <String>{},
    bool centre = false,
    bool rtl = false,
  }) => FluentSynthesisedLegendLayout.compute(
    legends: <FluentChartLegendItem>[
      for (var i = 0; i < titles.length; i++)
        FluentChartLegendItem(
          title: titles[i],
          color: Color(0xFF000000 + i),
          shape: FluentChartLegendShape.triangle,
          stripePattern: true,
        ),
    ],
    svgWidth: svgWidth,
    measurer: measurer,
    textStyle: textStyle,
    selectedLegends: selected,
    centerLegends: centre,
    isRtl: rtl,
  );

  test('labels are capitalised before they are measured or drawn', () {
    expect(
      capitalizeLegendLabel('first quarter'),
      'First Quarter',
      reason:
          'useLegendsStyles.styles.ts:56 sets text-transform: capitalize, and '
          'measureTextWithDOM (utilities.ts:2137-2144) copies it — spec section 8',
    );
    expect(
      layoutOf(<String>['first quarter']).items.first.label,
      'First Quarter',
      reason: 'the exported strip draws the capitalised label',
    );
  });

  test('the first swatch sits at the container start plus one padding', () {
    final item = layoutOf(<String>['A']).items.first;
    expect(
      item.swatchRect.left,
      kLegendContainerMarginStart + kLegendPadding,
      reason: 'image-export-utils.ts:305, 333 — 12 + 8',
    );
    expect(
      item.swatchRect.top,
      kLegendContainerMarginTop + kLegendPadding,
      reason: 'image-export-utils.ts:306, 334 — 8 + 8',
    );
    expect(
      item.swatchRect.size,
      const Size(kLegendShapeSize, kLegendShapeSize),
      reason:
          'image-export-utils.ts:335-336 — always 13 x 13, never the real shape',
    );
    expect(
      item.textTopLeft.dx - kLegendContainerMarginStart,
      kLegendPadding + kLegendShapeSize + kLegendShapeMarginEnd,
      reason: 'image-export-utils.ts:313 — textOffset is 8 + 13 + 8 = 29',
    );
    expect(
      item.textTopLeft.dy,
      kLegendContainerMarginTop + kLegendPadding,
      reason:
          'image-export-utils.ts:344-345 hangs the text from the same y as the '
          'swatch top',
    );
  });

  test('a single line is 8 plus one legend height tall', () {
    expect(
      layoutOf(<String>['A', 'B']).size.height,
      kLegendContainerMarginTop + kLegendHeight,
      reason:
          'image-export-utils.ts:355, 384 — legendY starts at 8, then += 32',
    );
  });

  test('the strip is at least as wide as the chart', () {
    expect(
      layoutOf(<String>['A'], svgWidth: 400).size.width,
      400,
      reason: 'image-export-utils.ts:383 — max(svgWidth, ...lineWidths)',
    );
  });

  test('items wrap once the running x exceeds the chart width', () {
    final layout = layoutOf(<String>[
      'Alpha',
      'Bravo',
      'Charlie',
      'Delta',
      'Echo',
      'Foxtrot',
    ], svgWidth: 160);
    final rows = layout.items.map((i) => i.swatchRect.top).toSet();
    expect(
      rows.length,
      greaterThan(1),
      reason: 'image-export-utils.ts:319-327 wraps to a new line',
    );
    expect(
      rows.toList()..sort(),
      containsAllInOrder(<double>[
        kLegendContainerMarginTop + kLegendPadding,
        kLegendContainerMarginTop + kLegendHeight + kLegendPadding,
      ]),
      reason: 'each wrap advances legendY by exactly LEGEND_HEIGHT',
    );
  });

  test('a lone over-wide legend does not wrap', () {
    final layout = layoutOf(<String>[
      'An extremely long single legend title',
    ], svgWidth: 20);
    expect(
      layout.items.first.swatchRect.top,
      kLegendContainerMarginTop + kLegendPadding,
      reason:
          'image-export-utils.ts:319 requires legendLine.length > 1, so the first '
          'item on a line never wraps',
    );
  });

  test('a dimmed swatch is transparent and its text drops to 0.67', () {
    final layout = layoutOf(<String>['A', 'B'], selected: <String>{'A'});
    expect(
      layout.items[0].isActive,
      isTrue,
      reason: 'image-export-utils.ts:329 — A is in the selection',
    );
    expect(
      layout.items[1].isActive,
      isFalse,
      reason: 'B is not, and the selection is non-empty',
    );
  });

  test('an empty selection makes every legend active', () {
    final layout = layoutOf(<String>['A', 'B']);
    expect(
      layout.items.every((i) => i.isActive),
      isTrue,
      reason: 'image-export-utils.ts:310, 329 — noLegendsSelected',
    );
  });

  test('centring shifts a short line to the middle of the chart', () {
    final layout = layoutOf(<String>['A'], centre: true, svgWidth: 400);
    final lineWidth =
        kLegendPadding +
        kLegendShapeSize +
        kLegendShapeMarginEnd +
        measurer.width('A', textStyle) +
        kLegendPadding;
    expect(
      layout.items.first.swatchRect.left,
      closeTo((400 - lineWidth) / 2 + kLegendPadding, 1e-9),
      reason:
          'image-export-utils.ts:357-368 — centred lines start at 0, then shift '
          'by max((svgWidth - lineWidth) / 2, 0)',
    );
  });

  test('RTL mirrors the swatch inside its own legend box', () {
    final layout = layoutOf(<String>['A', 'B'], rtl: true, centre: true);
    final first = layout.items.first;
    expect(
      first.swatchRect.left,
      greaterThan(first.textTopLeft.dx),
      reason:
          'image-export-utils.ts:333, 343 put the swatch after the text under RTL',
    );
  });

  // The plan's suite stops at the layout, so the painter — where spec section
  // 5.4's "worse than the live legend on purpose" claim actually cashes out —
  // has no check at all. One is enough: the dimmed swatch is CSS `transparent`
  // and not `colorNeutralBackground1`, while its border stays the series
  // colour.
  test('the dimmed swatch is filled with transparent, bordered in its colour', () {
    final layout = layoutOf(<String>['A', 'B'], selected: <String>{'A'});
    final painter = FluentSynthesisedLegendPainter(
      layout: layout,
      textStyle: textStyle,
      measurer: measurer,
    );
    expect(
      (Canvas canvas) => painter.paint(canvas, layout.size),
      paints
        // A is selected, so its 13x13 square is filled with its own colour.
        ..rect(color: const Color(0xFF000000), style: PaintingStyle.fill)
        ..rect(
          color: const Color(0xFF000000),
          style: PaintingStyle.stroke,
          strokeWidth: kLegendShapeBorder,
        )
        // B is not, so `image-export-utils.ts:337` fills it with `transparent`.
        ..rect(color: const Color(0x00000000), style: PaintingStyle.fill)
        // `:339` — the stroke is the series colour whether or not it is dimmed.
        ..rect(
          color: const Color(0xFF000001),
          style: PaintingStyle.stroke,
          strokeWidth: kLegendShapeBorder,
        ),
      reason:
          'image-export-utils.ts:337-339 — a dimmed swatch is transparent, not '
          'a theme surface, and its border never dims',
    );
  });

  test('an empty legend list produces an empty strip', () {
    final layout = layoutOf(const <String>[]);
    expect(
      layout.size,
      Size.zero,
      reason: 'image-export-utils.ts:295-301 returns a null node',
    );
    expect(layout.items, isEmpty, reason: 'nothing to draw');
  });

  group('FluentChartImageExporter', () {
    final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

    Future<GlobalKey> pumpBoundary(
      WidgetTester tester, {
      Size size = const Size(200, 100),
    }) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        FluentApp(
          theme: theme,
          home: Center(
            child: RepaintBoundary(
              key: key,
              child: Container(
                width: size.width,
                height: size.height,
                color: const Color(0xFF3366CC),
              ),
            ),
          ),
        ),
      );
      return key;
    }

    /// Runs [exporter] outside the fake-async zone.
    ///
    /// `RenderRepaintBoundary.toImage` and `Image.toByteData` are serviced by
    /// the engine's task runner, which the widget tester's fake clock never
    /// pumps, so the returned future only completes inside
    /// [WidgetTester.runAsync].
    Future<String> exportOf(
      WidgetTester tester,
      FluentChartImageExporter exporter, [
      FluentChartImageExportOptions options =
          const FluentChartImageExportOptions(),
    ]) async {
      final url = await tester.runAsync(() => exporter.toImage(options));
      expect(url, isNotNull, reason: 'runAsync only returns null on failure');
      return url!;
    }

    /// Decodes the base64 payload and reads the PNG IHDR width and height.
    (int width, int height) pngSize(String dataUrl) {
      expect(
        dataUrl.startsWith('data:image/png;base64,'),
        isTrue,
        reason: 'image-export-utils.ts:458 returns a png data url',
      );
      final bytes = base64Decode(dataUrl.split(',').last);
      int be32(int at) =>
          (bytes[at] << 24) |
          (bytes[at + 1] << 16) |
          (bytes[at + 2] << 8) |
          bytes[at + 3];
      // An 8-byte signature and an 8-byte chunk header precede the IHDR
      // payload, whose first two big-endian 32-bit fields are the dimensions.
      return (be32(16), be32(20));
    }

    testWidgets('a chart with no legends exports at its own size', (
      tester,
    ) async {
      final key = await pumpBoundary(tester);
      final url = await exportOf(
        tester,
        FluentChartImageExporter(
          boundaryKey: key,
          legends: const <FluentChartLegendItem>[],
        ),
      );
      expect(
        pngSize(url),
        (200, 100),
        reason:
            'image-export-utils.ts:424-429 — with no options the scale factors '
            'are both 1',
      );
    });

    testWidgets('the legend strip is stacked under the chart', (tester) async {
      final key = await pumpBoundary(tester);
      final url = await exportOf(
        tester,
        FluentChartImageExporter(
          boundaryKey: key,
          legends: const <FluentChartLegendItem>[
            FluentChartLegendItem(title: 'A', color: Color(0xFFFF0000)),
          ],
        ),
      );
      final (width, height) = pngSize(url);
      expect(
        width,
        200,
        reason: 'image-export-utils.ts:416 — the row widths are both 200',
      );
      expect(
        height,
        100 + (kLegendContainerMarginTop + kLegendHeight).toInt(),
        reason:
            'image-export-utils.ts:417 stacks the legend row under the chart row',
      );
    });

    testWidgets('scaleX and scaleY are independent, so a target distorts', (
      tester,
    ) async {
      final key = await pumpBoundary(tester);
      final url = await exportOf(
        tester,
        FluentChartImageExporter(
          boundaryKey: key,
          legends: const <FluentChartLegendItem>[],
        ),
        const FluentChartImageExportOptions(width: 400, height: 100),
      );
      expect(
        pngSize(url),
        (400, 100),
        reason:
            'image-export-utils.ts:426-427 computes scaleX and scaleY separately, '
            'so a non-square target stretches the chart rather than letterboxing '
            'it — parity, spec section 5.4',
      );
    });

    testWidgets('scale multiplies both axes', (tester) async {
      final key = await pumpBoundary(tester);
      final url = await exportOf(
        tester,
        FluentChartImageExporter(
          boundaryKey: key,
          legends: const <FluentChartLegendItem>[],
        ),
        const FluentChartImageExportOptions(scale: 2),
      );
      expect(pngSize(url), (
        400,
        200,
      ), reason: 'image-export-utils.ts:423, 428-429');
    });

    /// Decodes [dataUrl] and returns a reader of straight-alpha RGBA pixels.
    Future<({int width, int height, int Function(int x, int y) rgba})> pixelsOf(
      WidgetTester tester,
      String dataUrl,
    ) async {
      final decoded = await tester.runAsync(() async {
        final codec = await ui.instantiateImageCodec(
          base64Decode(dataUrl.split(',').last),
        );
        final image = (await codec.getNextFrame()).image;
        final data = await image.toByteData(
          format: ui.ImageByteFormat.rawStraightRgba,
        );
        final result = (image.width, image.height, data!);
        image.dispose();
        codec.dispose();
        return result;
      });
      final (width, height, data) = decoded!;
      return (
        width: width,
        height: height,
        rgba: (int x, int y) => data.getUint32((y * width + x) * 4),
      );
    }

    testWidgets('a scaled export is rendered at its scale, not stretched', (
      tester,
    ) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        FluentApp(
          theme: theme,
          home: Center(
            child: RepaintBoundary(
              key: key,
              child: const SizedBox(
                width: 200,
                height: 100,
                child: Align(
                  alignment: Alignment.topLeft,
                  // The right edge lands half-way through a logical pixel.
                  child: SizedBox(
                    width: 100.5,
                    height: 100,
                    child: ColoredBox(color: Color(0xFF000000)),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final pixels = await pixelsOf(
        tester,
        await exportOf(
          tester,
          FluentChartImageExporter(
            boundaryKey: key,
            legends: const <FluentChartLegendItem>[],
          ),
          const FluentChartImageExportOptions(scale: 2),
        ),
      );
      // At 2x the edge falls exactly between output pixels 200 and 201. A 1x
      // capture stretched twice instead smears one half-covered pixel over
      // both — the 5x5 blocks of blur the showroom's exports had.
      expect(
        pixels.rgba(200, 50) & 0xFF,
        0xFF,
        reason: 'image-export-utils.ts:449 draws the vector at the output size',
      );
      expect(pixels.rgba(201, 50) & 0xFF, 0x00);
    });

    testWidgets('an export the browser could not rasterise is fitted inside '
        'the caps', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        FluentApp(
          theme: theme,
          home: SingleChildScrollView(
            child: Center(
              child: RepaintBoundary(
                key: key,
                child: Container(
                  width: 400,
                  height: 4000,
                  color: const Color(0xFF3366CC),
                ),
              ),
            ),
          ),
        ),
      );
      final (width, height) = pngSize(
        await exportOf(
          tester,
          FluentChartImageExporter(
            boundaryKey: key,
            legends: const <FluentChartLegendItem>[],
          ),
          const FluentChartImageExportOptions(scale: 5),
        ),
      );
      // Asked for 2000x20000; Chromium would silently shrink that drawing
      // buffer and leave a transparent band, so the output is scaled down to
      // 8192 on its long side with the aspect ratio kept.
      expect(height, inInclusiveRange(8191, 8192));
      expect(width, inInclusiveRange(818, 820));
      expect(width * height, lessThanOrEqualTo(4096 * 4096));
    });

    testWidgets('a zero scale or length is unset, as upstream reads it', (
      tester,
    ) async {
      final key = await pumpBoundary(tester);
      final url = await exportOf(
        tester,
        FluentChartImageExporter(
          boundaryKey: key,
          legends: const <FluentChartLegendItem>[],
        ),
        const FluentChartImageExportOptions(scale: 0, width: 0, height: 0),
      );
      expect(pngSize(url), (
        200,
        100,
      ), reason: 'image-export-utils.ts:423-425 — `opts.scale || 1`');
    });

    testWidgets('a clipped boundary continues with a second one below it', (
      tester,
    ) async {
      final head = GlobalKey();
      final tail = GlobalKey();
      await tester.pumpWidget(
        FluentApp(
          theme: theme,
          home: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                RepaintBoundary(
                  key: head,
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SizedBox(
                        width: 200,
                        height: 60,
                        child: ColoredBox(color: Color(0xFFFF0000)),
                      ),
                      // What the clip drops: the stand-in for a live legend or
                      // a scroll viewport's window.
                      SizedBox(
                        width: 200,
                        height: 40,
                        child: ColoredBox(color: Color(0xFF00FF00)),
                      ),
                    ],
                  ),
                ),
                RepaintBoundary(
                  key: tail,
                  child: const SizedBox(
                    width: 150,
                    height: 300,
                    child: ColoredBox(color: Color(0xFF0000FF)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      final pixels = await pixelsOf(
        tester,
        await exportOf(
          tester,
          FluentChartImageExporter(
            boundaryKey: head,
            legends: const <FluentChartLegendItem>[],
            clipHeight: 60,
            continuationKey: tail,
            continuationX: 20,
          ),
        ),
      );
      expect(
        (pixels.width, pixels.height),
        (200, 360),
        reason: 'the kept 60 of the head plus the whole 300 of the tail',
      );
      expect(pixels.rgba(10, 30), 0xFF0000FF, reason: 'the kept head');
      expect(pixels.rgba(10, 80), 0x00000000, reason: 'the green band is cut');
      expect(pixels.rgba(30, 80), 0x0000FFFF, reason: 'the tail, 20 in');
      expect(pixels.rgba(30, 359), 0x0000FFFF, reason: 'all of the tail');
    });

    /// A 200-wide red head over a 40-high green band, and a 150x300 blue tail.
    Future<(GlobalKey, GlobalKey)> pumpHeadAndTail(WidgetTester tester) async {
      final head = GlobalKey();
      final tail = GlobalKey();
      await tester.pumpWidget(
        FluentApp(
          theme: theme,
          home: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                RepaintBoundary(
                  key: head,
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SizedBox(
                        width: 200,
                        height: 60,
                        child: ColoredBox(color: Color(0xFFFF0000)),
                      ),
                      SizedBox(
                        width: 200,
                        height: 40,
                        child: ColoredBox(color: Color(0xFF00FF00)),
                      ),
                    ],
                  ),
                ),
                RepaintBoundary(
                  key: tail,
                  child: const SizedBox(
                    width: 150,
                    height: 300,
                    child: ColoredBox(color: Color(0xFF0000FF)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return (head, tail);
    }

    testWidgets('the cut and the continuation are placed at the output scale', (
      tester,
    ) async {
      final (head, tail) = await pumpHeadAndTail(tester);
      final pixels = await pixelsOf(
        tester,
        await exportOf(
          tester,
          FluentChartImageExporter(
            boundaryKey: head,
            legends: const <FluentChartLegendItem>[],
            clipHeight: 60,
            continuationKey: tail,
            continuationX: 20,
          ),
          const FluentChartImageExportOptions(scale: 2),
        ),
      );
      expect((pixels.width, pixels.height), (400, 720));
      expect(pixels.rgba(10, 119), 0xFF0000FF, reason: 'the last kept row');
      expect(pixels.rgba(10, 121), 0x00000000, reason: 'the band is cut');
      expect(pixels.rgba(39, 300), 0x00000000, reason: 'left of the tail');
      expect(pixels.rgba(40, 120), 0x0000FFFF, reason: 'the tail, 20 * 2 in');
      expect(pixels.rgba(339, 719), 0x0000FFFF, reason: 'all of the tail');
    });

    testWidgets('a continuation overhanging the left edge shifts everything '
        'right', (tester) async {
      final (head, tail) = await pumpHeadAndTail(tester);
      final pixels = await pixelsOf(
        tester,
        await exportOf(
          tester,
          FluentChartImageExporter(
            boundaryKey: head,
            legends: const <FluentChartLegendItem>[],
            clipHeight: 60,
            continuationKey: tail,
            // A right-to-left viewport 100 wide, its 150-wide content anchored
            // at the viewport's right edge.
            continuationX: -50,
          ),
        ),
      );
      expect((pixels.width, pixels.height), (250, 360));
      expect(pixels.rgba(10, 30), 0x00000000, reason: 'the head moved right');
      expect(pixels.rgba(60, 30), 0xFF0000FF, reason: 'the head, 50 in');
      expect(pixels.rgba(0, 100), 0x0000FFFF, reason: 'the tail at the left');
      expect(pixels.rgba(160, 100), 0x00000000, reason: 'the tail ends at 150');
    });

    testWidgets('a large near-square export is fitted inside the area cap', (
      tester,
    ) async {
      final key = await pumpBoundary(tester, size: const Size(800, 600));
      final (width, height) = pngSize(
        await exportOf(
          tester,
          FluentChartImageExporter(
            boundaryKey: key,
            legends: const <FluentChartLegendItem>[],
          ),
          const FluentChartImageExportOptions(scale: 6),
        ),
      );
      // 4800x3600 asked for; 4096² is iOS Safari's canvas area limit.
      expect(width * height, lessThanOrEqualTo(4096 * 4096));
      expect(width, inInclusiveRange(4727, 4730));
      expect(height, inInclusiveRange(3545, 3548));
    });

    testWidgets('a stretched export does not capture past the caps', (
      tester,
    ) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        FluentApp(
          theme: theme,
          home: Center(
            child: _SpyBoundary(
              key: key,
              child: const SizedBox(width: 200, height: 100),
            ),
          ),
        ),
      );
      final (width, height) = pngSize(
        await exportOf(
          tester,
          FluentChartImageExporter(
            boundaryKey: key,
            legends: const <FluentChartLegendItem>[],
          ),
          // x scales 40 times and y half: the output is small, but a capture
          // at the larger ratio would be 8000x4000.
          const FluentChartImageExportOptions(width: 8000, height: 50),
        ),
      );
      // A capture at x's ratio of 40 would be 8000x4000, past both caps, so the
      // whole export shrinks to fit it — keeping the asked-for aspect, and
      // sharp — rather than capturing smaller and stretching.
      expect(width, inInclusiveRange(5790, 5794));
      expect(height, 36);
      final ratio = tester
          .renderObject<_RenderSpyBoundary>(find.byKey(key))
          .capturedAt!;
      expect(200 * ratio * 100 * ratio, lessThanOrEqualTo(4096 * 4096));
      expect(200 * ratio, lessThanOrEqualTo(8192));
    });

    testWidgets('an unmounted boundary throws the upstream error', (
      tester,
    ) async {
      await expectLater(
        FluentChartImageExporter(
          boundaryKey: GlobalKey(),
          legends: const <FluentChartLegendItem>[],
        ).toImage(),
        throwsStateError,
        reason:
            'image-export-utils.ts:152-154 throws when there is no container',
      );
    });

    testWidgets('a controller forwards to its attached exporter', (
      tester,
    ) async {
      final key = await pumpBoundary(tester);
      final controller = FluentChartController();
      expect(
        controller.isAttached,
        isFalse,
        reason: 'a fresh controller has no chart',
      );
      await expectLater(
        controller.toImage(),
        throwsStateError,
        reason:
            'calling toImage before the chart mounts is a programming error',
      );
      controller.attach(
        FluentChartImageExporter(
          boundaryKey: key,
          legends: const <FluentChartLegendItem>[],
        ),
      );
      final url = await tester.runAsync(controller.toImage);
      expect(
        url!.startsWith('data:image/png;base64,'),
        isTrue,
        reason: "the controller is upstream's componentRef (hooks.ts:23-41)",
      );
      controller.detach();
      expect(controller.isAttached, isFalse, reason: 'detach clears it');
    });
  });
}

/// A [RepaintBoundary] that records the ratio it was last captured at.
class _SpyBoundary extends SingleChildRenderObjectWidget {
  const _SpyBoundary({super.key, super.child});

  @override
  _RenderSpyBoundary createRenderObject(BuildContext context) =>
      _RenderSpyBoundary();
}

class _RenderSpyBoundary extends RenderRepaintBoundary {
  double? capturedAt;

  @override
  Future<ui.Image> toImage({double pixelRatio = 1.0}) {
    capturedAt = pixelRatio;
    return super.toImage(pixelRatio: pixelRatio);
  }
}
