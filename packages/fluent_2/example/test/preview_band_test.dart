import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:fluent_2_example/shell/widgets/preview_band.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The preview band repaints Storybook's `.docs-story` box: the backgrounds
/// addon's colour and grid, under the story.
///
/// Every expected value is a pixel measured on upstream
/// (`FC/d2-grid-white.png`, `FC/d4-grid-dark.png`, `s4-bg-dark.png`), read back
/// here from a 1:1 raster of a band that starts on a whole pixel, over a white
/// page. ±2 absorbs the 8-bit rounding of the premultiplied round trip.
void main() {
  const Size bandSize = Size(240, 160);
  final GlobalKey boundary = GlobalKey();

  Future<void> pumpBand(
    WidgetTester tester, {
    required bool grid,
    required PreviewBackground? background,
    bool disableAnimations = false,
    Widget child = const SizedBox.expand(),
  }) {
    return tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: boundary,
              // The page the band sits on: upstream's docs body is white.
              child: ColoredBox(
                color: const Color(0xFFFFFFFF),
                child: SizedBox.fromSize(
                  size: bandSize,
                  child: PreviewBand(
                    grid: grid,
                    background: background,
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Rasterises the band at 1 image pixel per logical pixel. Inside `runAsync`
  /// because `toImage` completes on the real event loop.
  Future<ByteData> raster(WidgetTester tester) async {
    final RenderRepaintBoundary box = tester.renderObject(find.byKey(boundary));
    final ByteData? data = await tester.runAsync(() async {
      final ui.Image image = await box.toImage();
      final ByteData? bytes = await image.toByteData();
      image.dispose();
      return bytes!;
    });
    return data!;
  }

  /// The red channel at ([x], [y]). Every colour here is a neutral grey.
  int grey(ByteData data, int x, int y) =>
      data.getUint8((y * bandSize.width.toInt() + x) * 4);

  // Sample points. x = 0 is a minor vertical line (x ≡ 0 mod 20) and x = 20 a
  // major one (20 + 100k); y = 10 sits between horizontal lines, so each of
  // these is one line over the band, not a crossing. (10, 0) and (10, 20) are
  // the horizontal equivalents; (10, 10) is plain band.
  const (int, int) minorV = (0, 10);
  const (int, int) majorV = (20, 10);
  const (int, int) minorH = (10, 0);
  const (int, int) majorH = (10, 20);
  const (int, int) plain = (10, 10);
  int at(ByteData data, (int, int) p) => grey(data, p.$1, p.$2);

  testWidgets('grid off and no background leaves the page untouched', (
    WidgetTester tester,
  ) async {
    await pumpBand(tester, grid: false, background: null);
    final ByteData data = await raster(tester);
    for (final (int, int) p in <(int, int)>[
      minorV,
      majorV,
      minorH,
      majorH,
      plain,
    ]) {
      expect(at(data, p), 255, reason: 'pixel $p must be the white page');
    }
  });

  testWidgets('the grid over no background matches upstream on white', (
    WidgetTester tester,
  ) async {
    await pumpBand(tester, grid: true, background: null);
    final ByteData data = await raster(tester);
    // Minor: rgba(130,130,130,.25) over the empty group, composited on white.
    expect(at(data, minorV), closeTo(223, 2));
    expect(at(data, minorH), closeTo(223, 2));
    // Major: the .5 line blends `difference` with the minor line under it
    // INSIDE the group, and only then lands on white. Blending straight onto
    // the page (no saveLayer) gives 157, which this bound rejects.
    expect(at(data, majorV), closeTo(160, 2));
    expect(at(data, majorH), closeTo(160, 2));
    expect(at(data, plain), 255);
  });

  testWidgets('the grid over dark blends with the band colour', (
    WidgetTester tester,
  ) async {
    await pumpBand(tester, grid: true, background: PreviewBackground.dark);
    final ByteData data = await raster(tester);
    // |51 - 130| = 79 at .25 over #333 → 58; the major line then differences
    // against 58 → 65, LIGHTER than minor, as measured upstream. Painting the
    // colour outside the grid's group gives 70 here.
    expect(at(data, minorV), closeTo(58, 2));
    expect(at(data, minorH), closeTo(58, 2));
    expect(at(data, majorV), closeTo(65, 2));
    expect(at(data, majorH), closeTo(65, 2));
    expect(at(data, plain), 51);
  });

  testWidgets('the light background paints #F8F8F8', (
    WidgetTester tester,
  ) async {
    await pumpBand(tester, grid: false, background: PreviewBackground.light);
    final ByteData data = await raster(tester);
    expect(at(data, plain), 248);
    expect(at(data, minorV), 248, reason: 'no grid, so no lines');
  });

  testWidgets('the story paints over the grid', (WidgetTester tester) async {
    // Upstream's story wrapper is an opaque nb2 box inset by the 38px band.
    await pumpBand(
      tester,
      grid: true,
      background: null,
      child: const Padding(
        padding: EdgeInsets.all(38),
        child: ColoredBox(color: Color(0xFFFAFAFA)),
      ),
    );
    final ByteData data = await raster(tester);
    expect(at(data, (40, 10)), closeTo(223, 2), reason: 'band: line shows');
    expect(grey(data, 40, 50), 250, reason: 'x = 40 is a line, but covered');
    expect(grey(data, 120, 60), 250, reason: 'x = 120 is major, but covered');
  });

  testWidgets('Reset snaps: dark to no background is instant', (
    WidgetTester tester,
  ) async {
    await pumpBand(tester, grid: false, background: PreviewBackground.dark);
    expect(at(await raster(tester), plain), 51);
    await pumpBand(tester, grid: false, background: null);
    expect(at(await raster(tester), plain), 255);
    expect(tester.binding.hasScheduledFrame, isFalse, reason: 'no fade runs');
  });

  testWidgets('light to dark fades over 300ms with CSS ease', (
    WidgetTester tester,
  ) async {
    await pumpBand(tester, grid: false, background: PreviewBackground.light);
    await pumpBand(tester, grid: false, background: PreviewBackground.dark);
    expect(at(await raster(tester), plain), 248, reason: 'the fade starts');
    await tester.pump(const Duration(milliseconds: 150));
    final double t = Curves.ease.transform(0.5);
    expect(at(await raster(tester), plain), closeTo(248 + (51 - 248) * t, 2));
    await tester.pumpAndSettle();
    expect(at(await raster(tester), plain), 51);
  });

  testWidgets('fading in from no background never dips below the colour', (
    WidgetTester tester,
  ) async {
    // CSS interpolates premultiplied, so none → light is #F8F8F8 gaining
    // alpha. A plain Color.lerp from transparent black would pass through a
    // grey near 210 on the way.
    await pumpBand(tester, grid: false, background: null);
    await pumpBand(tester, grid: false, background: PreviewBackground.light);
    await tester.pump(const Duration(milliseconds: 150));
    expect(at(await raster(tester), plain), inInclusiveRange(248, 255));
    await tester.pumpAndSettle();
    expect(at(await raster(tester), plain), 248);
  });

  testWidgets('reduced motion snaps light to dark', (
    WidgetTester tester,
  ) async {
    await pumpBand(
      tester,
      grid: false,
      background: PreviewBackground.light,
      disableAnimations: true,
    );
    await pumpBand(
      tester,
      grid: false,
      background: PreviewBackground.dark,
      disableAnimations: true,
    );
    expect(at(await raster(tester), plain), 51);
    expect(tester.binding.hasScheduledFrame, isFalse, reason: 'no fade runs');
  });

  test('the two backgrounds are upstream\'s, in order', () {
    expect(
      PreviewBackground.values.map((PreviewBackground b) => (b.label, b.color)),
      <(String, Color)>[
        ('light', const Color(0xFFF8F8F8)),
        ('dark', const Color(0xFF333333)),
      ],
    );
  });
}
