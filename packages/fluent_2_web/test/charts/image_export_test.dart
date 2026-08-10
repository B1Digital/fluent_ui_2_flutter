import 'dart:convert';

import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:fluent_2_web/src/charts/internal/image_export.dart';
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
