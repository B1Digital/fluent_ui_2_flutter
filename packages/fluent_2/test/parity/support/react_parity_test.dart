import 'dart:io';
import 'dart:ui' as ui;

import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'react_parity.dart';

/// The harness's own guarantees. A parity figure is only as honest as the
/// render it measures, so each of these is something that silently made the
/// Flutter side differ from what a browser draws.
void main() {
  setUpAll(loadParityFonts);

  test('U+2212 MINUS SIGN lays out as a glyph, not a placeholder box', () {
    // d3-format writes every negative label with U+2212 and Selawik has no
    // glyph for it. Before the fallback was registered this measured 10.0 —
    // the placeholder's 1em box — against Segoe UI's ~5.6.
    final style = FluentThemeData.light(
      fontPlatform: FluentFontPlatform.web,
    ).typography.caption2Strong.copyWith(fontSize: 10);
    final painter = TextPainter(
      text: TextSpan(text: '−', style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    addTearDown(painter.dispose);
    expect(painter.width, closeTo(5.56, 0.5));
  });

  test('the manifest masks HTML text, not only svg <text>', () {
    // ChartTable's cells are a <table> inside a <foreignObject>, and the
    // legend's '+10 Overflow Items' is a text node beside the MenuButton's
    // icon. The capture used to record neither, so their glyphs were compared
    // pixel for pixel (ChartTable measured 4.07% on text alone).
    expect(
      loadReactReference('charts-charttable--chart-table-basic').textRects,
      hasLength(30),
    );
    final overflowLabel = loadReactReference(
      'charts-legends--legends-overflow',
    ).textRects.where((r) => r.contains(const Offset(755, 15)));
    expect(overflowLabel, isNotEmpty);
  });

  testWidgets('paints real shadows while measuring, then restores the flag', (
    tester,
  ) async {
    // The reference mounted as the "chart": it must measure exactly 0%, and
    // the Builder sees the shadow flag the chart is painted under.
    const id = 'charts-legends--legends-basic';
    final bytes = File(
      'test/fixtures/charts/react_png/$id.png',
    ).readAsBytesSync();
    final image = await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(bytes);
      return (await codec.getNextFrame()).image;
    });
    bool? shadowsDisabledWhilePainting;
    debugWriteParityOutput = false;
    addTearDown(() => debugWriteParityOutput = true);
    final result = await expectReactParity(
      tester,
      id,
      Builder(
        builder: (context) {
          shadowsDisabledWhilePainting = debugDisableShadows;
          return RawImage(image: image, filterQuality: FilterQuality.none);
        },
      ),
    );
    expect(shadowsDisabledWhilePainting, isFalse);
    expect(debugDisableShadows, isTrue);
    expect(result.mismatchedPixels, 0);
  });
}
