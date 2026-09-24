/// Pixel parity against the live `@fluentui/react-charts` render.
///
/// ## Why this exists next to Oracle B
///
/// `test/support/oracle_fixture.dart` compares SVG geometry as numbers and
/// says why: "the capture browser resolves different fonts than `flutter test`
/// does, and Skia's antialiasing does not match Chromium's, so a pixel diff
/// would fail on machines that are perfectly correct." That is still true of a
/// *naive* pixel diff, and this harness does not overturn it. It removes the
/// two named causes instead, and what is left is the thing numbers are worst
/// at: whether the whole picture looks the same.
///
/// A numeric oracle only checks what someone wrote an assertion for. 22 of the
/// 90 captured stories are asserted by nothing at all
/// (`test/charts/oracle_b/oracle_b_fixture_usage_test.dart`), and an assertion
/// that exists still only covers the elements it names — a mark drawn in the
/// wrong colour, a layer painted in the wrong order, or a whole element that
/// was never drawn all pass a geometry test that did not think to look.
///
/// ### Cause 1: fonts — removed, then masked anyway
///
/// The storybook does not fall back to a system font. It loads the genuine
/// Segoe UI as a webfont from `c.s-microsoft.com/static/fonts/segoe-ui/…`
/// (measured 2026-08-11 via `CSS.getPlatformFontsForNode`: `Segoe UI
/// Semibold`, `isCustomFont: true`). The bundled open-source Selawik that
/// [loadParityFonts] registers here is metric-compatible with it, and measured
/// against `canvas.measureText` in that same browser it is **exact** at weight
/// 400 — 0.00% across every probe string at 10px and 12px.
///
/// Weight 600 is not exact: Selawik Semibold runs up to 3.87% wide of Segoe UI
/// Semibold ("Mar 03, 12 AM" at 10px: 67.993 against 65.459). Axis tick labels
/// are 10px/600, so a chart whose margins are solved from the widest tick label
/// can sit up to a fraction of a pixel out. That is the residual this harness
/// cannot remove without shipping a proprietary font, and it is why
/// [kDefaultMismatchTolerance] is not zero. Selawik's digits are also tabular
/// where Segoe UI's are proportional, so a right-anchored "111" grows a few
/// pixels left out of its mask. And Selawik has no U+2212 MINUS SIGN at all;
/// [loadParityFonts] gives it a real fallback glyph (see there).
///
/// Text pixels are excluded regardless. Even with identical metrics, Skia and
/// Chromium hint and rasterise glyphs differently, so every text rectangle the
/// capture recorded is painted out on **both** images, one pixel of slop on
/// each side, before they are compared. Those rectangles are the svg `<text>`
/// and `<tspan>` boxes, the leaf `fui-` HTML labels, and every other rendered
/// text node's line boxes — ChartTable's cells inside a `<foreignObject>`, the
/// legend's `+N more` button, annotation HTML, nested bar titles, story prose
/// inside the clip. The last kind was re-measured on 2026-09-24 without
/// re-capturing a pixel, and adopted only where the live render provably is
/// the committed one; `test/fixtures/charts/react_png/README.md` says which
/// stories and how. The mask is the reference's own text rectangles, so a
/// Flutter chart that draws a label somewhere upstream does not is *not*
/// excused by it — the extra glyphs land outside the mask and count as
/// mismatch.
///
/// ### Cause 2: antialiasing — absorbed by a tolerance, not by equality
///
/// A pixel counts as mismatched only when a channel differs by more than
/// [_channelTolerance]. The edge pixels of a correctly placed mark differ by a
/// few levels between the two rasterisers; a mark in the wrong place, the wrong
/// colour or missing differs by hundreds. The threshold is on the *count* of
/// such pixels, expressed as a percentage of the unmasked area.
///
/// ### What else the render is held to
///
/// Shadows are real: the test binding's `debugDisableShadows` paints every
/// BoxShadow as a hard slab Chromium never draws, so [expectReactParity] turns
/// it off for the pump and the capture. The surface under the chart is white,
/// not the capture page's #FAFAFA, on purpose — see `_pumpChart`.
///
/// ## Using it
///
/// ```dart
/// void main() {
///   setUpAll(loadParityFonts);
///   testWidgets('LineChartBasic', (tester) async {
///     await expectReactParity(
///       tester,
///       'charts-linechart--line-chart-basic',
///       const MyChart(),
///       maxMismatch: 1.2,
///     );
///   });
/// }
/// ```
///
/// Every run writes `<id>.png` — reference, Flutter, and a diff mask
/// side by side — into `test/parity/out/`, which is gitignored. Look at it.
/// A number going green is not the point; the image is.
///
/// The reference corpus is captured by
/// `crawlers/storybooks-fluentui/capture_png.mjs`.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Per-channel difference, 0-255, below which two pixels are the same pixel.
///
/// Chosen against the measured noise floor, not picked round: an unmoved mark's
/// antialiased edge differs between Skia and Chromium by single-digit levels,
/// while `FluentDataVizPalette`'s adjacent entries differ by more than 60 in at
/// least one channel — so a series painted in the neighbouring colour is still
/// caught. Raising this past ~40 starts excusing real colour errors.
const int _channelTolerance = 24;

/// Default ceiling, in percent of unmasked pixels, for a story with no measured
/// figure of its own.
///
/// Not a target. Each story pins its own measured number so that an
/// *improvement* also fails and has to be re-pinned deliberately; this is only
/// what a new story starts at before anyone has looked at its image.
const double kDefaultMismatchTolerance = 2.0;

/// Below this fraction of its pin a story has measurably improved and the pin
/// is stale, so the doc above — an *improvement* also fails — is enforced, not
/// just promised. Exempt for [kDefaultMismatchTolerance]: a brand new story has
/// no measured figure yet and would fail on its very first run.
const double _mismatchFloorRatio = 0.5;

const String _pngDir = 'test/fixtures/charts/react_png';
const String _outDir = 'test/parity/out';

/// Off only for the harness's own tests, which measure a reference against
/// itself: their triptych and printed figure would otherwise overwrite the
/// real story's, and a 0.000% line is exactly what a re-pin must not read.
@visibleForTesting
bool debugWriteParityOutput = true;

/// The masked-out text colour. Nothing is compared here, so the value only has
/// to be visible in the written triptych — a reviewer needs to see *what* was
/// excluded, or a mask covering the whole chart would read as a pass.
const Color _maskColor = Color(0xFFEC4899);

Map<String, dynamic>? _manifestCache;
final Map<String, ui.Image> _referenceCache = <String, ui.Image>{};

/// Registers the bundled Selawik so text lays out at Segoe UI's metrics.
///
/// `flutter test` otherwise substitutes a placeholder font whose every glyph is
/// the same box: measured, it makes "Mar 03, 12 AM" 130px wide against Segoe
/// UI's 65.5px, which moves any margin solved from a label width by tens of
/// pixels. Call from `setUpAll`.
///
/// Selawik has no U+2212 MINUS SIGN, which d3-format writes on every negative
/// tick and bar label (`internal/d3/format.dart`). The browser draws Segoe
/// UI's own glyph, 6.84px wide at 10px/400 and 6.95px at 10px/600 (measured
/// in the live storybook on 2026-09-24; `CSS.getPlatformFontsForNode` names
/// Segoe UI and Segoe UI Semibold). `flutter test` fell through to the
/// placeholder's 1em box, 10px wide, and that box stuck out of the text mask
/// on every negative label in the corpus. So Roboto — the only real
/// sans-serif the SDK ships, with a 5.56px minus at 10px — is registered under
/// the FIRST name of [FluentFontFamily.baseFallback]: that is where Selawik's
/// missing glyphs are looked up next. It is not Segoe's width, only nearer
/// (1.4px narrow where the box was 3px wide), so a negative label now ends
/// inside its mask. Registering it as 'Roboto' does nothing, because
/// flutter_tester maps that name to the placeholder itself.
Future<void> loadParityFonts() async {
  final loader = FontLoader(FluentFontFamily.base);
  for (final file in <String>[
    'selawk.ttf',
    'selawksb.ttf',
    'selawkb.ttf',
    'selawkl.ttf',
    'selawksl.ttf',
  ]) {
    final bytes = File(
      '../fluent_2_fonts_web/lib/fonts/$file',
    ).readAsBytesSync();
    loader.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  }
  await loader.load();

  final fallback = FontLoader(FluentFontFamily.baseFallback.first);
  final fonts = '${_flutterRoot()}/bin/cache/artifacts/material_fonts';
  for (final weight in <String>['Regular', 'Medium', 'Bold']) {
    final bytes = File('$fonts/Roboto-$weight.ttf').readAsBytesSync();
    fallback.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  }
  await fallback.load();
}

/// The SDK checkout running this test. `flutter test` exports FLUTTER_ROOT to
/// the tester; when something else launched it, the tester binary itself lives
/// at `<root>/bin/cache/artifacts/engine/<platform>/flutter_tester`.
String _flutterRoot() {
  final env = Platform.environment['FLUTTER_ROOT'];
  if (env != null && env.isNotEmpty) return env;
  var dir = File(Platform.resolvedExecutable).parent;
  while (dir.parent.path != dir.path) {
    if (Directory('${dir.path}/bin/cache/artifacts').existsSync()) {
      return dir.path;
    }
    dir = dir.parent;
  }
  throw StateError(
    'cannot find the Flutter SDK from ${Platform.resolvedExecutable}; set '
    'FLUTTER_ROOT.',
  );
}

/// One story's entry in the capture manifest.
@immutable
class ReactReference {
  const ReactReference({
    required this.id,
    required this.component,
    required this.size,
    required this.textRects,
  });

  final String id;
  final String component;

  /// The clip the reference was screenshotted at, in logical pixels at DPR 1.
  /// Mount the Flutter chart at exactly this size or the comparison is a
  /// comparison of two different layouts.
  final Size size;

  /// Every recorded run of text — svg `<text>`, HTML labels, and any other
  /// text node the capture found inside the clip — relative to [size]. Masked
  /// on both images before comparing.
  final List<Rect> textRects;
}

/// Reads `<id>`'s entry from the capture manifest.
ReactReference loadReactReference(String id) {
  final manifest = _manifestCache ??=
      jsonDecode(File('$_pngDir/_manifest.json').readAsStringSync())
          as Map<String, dynamic>;
  final stories = (manifest['stories'] as List<dynamic>)
      .cast<Map<String, dynamic>>();
  final entry = stories.firstWhere(
    (s) => s['id'] == id,
    orElse: () => throw StateError(
      'no story "$id" in $_pngDir/_manifest.json. Story ids are enumerated '
      'from the live index and never constructed — five naming conventions '
      'are in use upstream. Read the manifest for the real id.',
    ),
  );
  return ReactReference(
    id: id,
    component: entry['component'] as String,
    size: Size(
      (entry['width'] as num).toDouble(),
      (entry['height'] as num).toDouble(),
    ),
    textRects: <Rect>[
      for (final r in (entry['textRects'] as List<dynamic>))
        Rect.fromLTWH(
          ((r as List<dynamic>)[0] as num).toDouble(),
          (r[1] as num).toDouble(),
          (r[2] as num).toDouble(),
          (r[3] as num).toDouble(),
        ),
    ],
  );
}

/// What [expectReactParity] measured.
@immutable
class ParityResult {
  const ParityResult({
    required this.id,
    required this.mismatchPercent,
    required this.mismatchedPixels,
    required this.comparedPixels,
    required this.maskedPixels,
    required this.bestShift,
    required this.shiftedMismatchPercent,
  });

  final String id;

  /// Mismatched pixels as a percentage of [comparedPixels].
  final double mismatchPercent;
  final int mismatchedPixels;

  /// Unmasked pixels — the denominator.
  final int comparedPixels;
  final int maskedPixels;

  /// The translation that would have minimised the mismatch, for diagnosis
  /// only. `(0, 0)` means no shift helps and the marks themselves differ.
  final ({int dx, int dy}) bestShift;

  /// What the mismatch would have been at [bestShift].
  final double shiftedMismatchPercent;

  @override
  String toString() {
    final shift = bestShift.dx == 0 && bestShift.dy == 0
        ? 'aligned'
        : 'shift(${bestShift.dx},${bestShift.dy}) would give '
              '${shiftedMismatchPercent.toStringAsFixed(3)}%';
    return '$id: ${mismatchPercent.toStringAsFixed(3)}% '
        '($mismatchedPixels/$comparedPixels px differ, $maskedPixels masked, '
        '$shift)';
  }
}

/// Renders [chart] at the reference's size and compares the two images.
///
/// Fails when more than [maxMismatch] percent of the unmasked pixels differ, and
/// writes `test/parity/out/<id>.png` either way.
///
/// [logicalSize] is the box the BROWSER laid the chart out in, when that is not
/// the size of the PNG. A capture whose root box starts at a fractional y —
/// `charts-heatmapchart--heat-map-chart-basic` sits at y 125.21875 — spans one
/// more device row than its own height, and the screenshot rounds outward. Pass
/// the true box size from Oracle B's `htmlBoxes` in that case; handing the chart
/// the PNG's height instead gives it a pixel the browser never had, and every
/// band scale inside divides it out across the plot. Only three captures in the
/// corpus need it, and each is one row tall in the difference.
///
/// [logicalOffset] is which row inside the PNG that box paints from. Chromium
/// SNAPS a box origin to a whole device pixel rather than translating it
/// fractionally, so this is the rounded fraction, not the fraction: the heat
/// map's y 125.21875 rounds down to the capture's first row and needs 0, while
/// the vega capture's y 339.5 rounds up to the second and needs 1. Measured
/// both ways — passing the raw fraction instead costs the heat map 2.3 points.
Future<ParityResult> expectReactParity(
  WidgetTester tester,
  String id,
  Widget chart, {
  double maxMismatch = kDefaultMismatchTolerance,
  FluentThemeData? theme,
  Size? logicalSize,
  Offset logicalOffset = Offset.zero,
}) async {
  final reference = loadReactReference(id);
  // The test binding sets `debugDisableShadows`, which paints every BoxShadow
  // as a hard unblurred slab — a card's shadow16 becomes a grey bar that
  // Chromium never draws. Real shadows for the pump and the capture, and the
  // flag restored in the body rather than in a tearDown: the binding checks
  // it when the test body ends, before any tearDown runs.
  final shadowsWereDisabled = debugDisableShadows;
  debugDisableShadows = false;
  final ParityResult? result;
  try {
    await _pumpChart(
      tester,
      reference,
      chart,
      theme,
      logicalSize,
      logicalOffset,
    );

    // Everything from here down is engine work — `instantiateImageCodec`,
    // `RenderRepaintBoundary.toImage`, `decodeImageFromPixels`,
    // `Picture.toImage` — and every one of them completes on a real task
    // runner that the fake-async zone a `testWidgets` body runs in never
    // pumps. Measured: awaiting `instantiateImageCodec` outside `runAsync`
    // hangs the test until the 10-minute pumpAndSettle-scale timeout, with the
    // process idle at 0% CPU. It reads exactly like a slow chart and is not
    // one.
    result = await tester.runAsync(() async {
      final referenceImage = await _decodeReference(id);
      if (referenceImage.width != reference.size.width.round() ||
          referenceImage.height != reference.size.height.round()) {
        throw StateError(
          '$id: manifest says ${reference.size} but the PNG is '
          '${referenceImage.width}x${referenceImage.height}. The corpus is '
          'half-regenerated — re-run capture_png.mjs.',
        );
      }
      final object =
          tester.renderObject(find.byKey(_boundaryKey))
              as RenderRepaintBoundary;
      final actual = await object.toImage();
      return _compare(reference, referenceImage, actual);
    });
  } finally {
    debugDisableShadows = shadowsWereDisabled;
  }
  if (result == null) {
    throw StateError('$id: runAsync returned before the comparison finished');
  }

  expect(
    result.mismatchPercent,
    lessThanOrEqualTo(maxMismatch),
    reason:
        '$result\nLook at $_outDir/$id.png — reference, Flutter, diff. A '
        'number is not a diagnosis.',
  );
  if (maxMismatch != kDefaultMismatchTolerance) {
    expect(
      result.mismatchPercent,
      greaterThanOrEqualTo(maxMismatch * _mismatchFloorRatio),
      reason:
          '$result\n$id improved past its pin. Re-pin it deliberately with '
          'the measured figure — a stale ceiling hides the next regression.',
    );
  }
  return result;
}

Future<ui.Image> _decodeReference(String id) async {
  final cached = _referenceCache[id];
  if (cached != null) return cached;
  final file = File('$_pngDir/$id.png');
  if (!file.existsSync()) {
    throw StateError(
      'no reference png at ${file.path}. Regenerate the corpus with '
      '`node crawlers/storybooks-fluentui/capture_png.mjs`.',
    );
  }
  final codec = await ui.instantiateImageCodec(file.readAsBytesSync());
  final frame = await codec.getNextFrame();
  return _referenceCache[id] = frame.image;
}

const Key _boundaryKey = Key('parity-boundary');

Future<void> _pumpChart(
  WidgetTester tester,
  ReactReference reference,
  Widget chart,
  FluentThemeData? theme,
  Size? logicalSize,
  Offset logicalOffset,
) async {
  tester.view.physicalSize = reference.size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final data =
      theme ?? FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
  await tester.pumpWidget(
    FluentApp(
      theme: data,
      debugShowCheckedModeBanner: false,
      home: RepaintBoundary(
        key: _boundaryKey,
        // The storybook screenshots the chart over the page background, so an
        // unpainted Flutter surface would differ from it everywhere. The
        // capture surface is #FAFAFA — grey98, i.e. neutralBackground2
        // (`global_colors.dart:208`, `alias_colors.dart:713-714`; the most
        // common colour of 88 of the 90 PNGs) — not the neutralBackground1
        // painted here; the 5-per-channel delta is under `_channelTolerance`.
        //
        // Deliberately NOT the capture's colour. Measured over the whole
        // suite on 2026-09-24, #FAFAFA lowers the total by 5.5k px (24
        // stories better, 30 worse), and 5.3k of that is real defects it
        // hides: upstream's light gridlines and table rules (#E0E0E0-#E6E6E6)
        // sit 25-27 levels from white but only 20-22 from #FAFAFA. The
        // scatter log axis's 38 missing gridlines lose 4.2k px of their
        // count, ChartTable's misplaced column rules 384, a half-pixel axis
        // line in vertical-bar-rotate-labels all 526. On white a missing
        // hairline still counts.
        child: ColoredBox(
          color: data.colors.neutralBackground1,
          // Top-left plus an explicit [logicalOffset], because a capture whose
          // box starts at a fractional pixel paints from the row Chromium
          // rounds that origin to, which is not always the PNG's first row.
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: EdgeInsets.only(
                left: logicalOffset.dx,
                top: logicalOffset.dy,
              ),
              child: SizedBox(
                width: (logicalSize ?? reference.size).width,
                height: (logicalSize ?? reference.size).height,
                child: chart,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<ParityResult> _compare(
  ReactReference reference,
  ui.Image referenceImage,
  ui.Image actualImage,
) async {
  final width = referenceImage.width;
  final height = referenceImage.height;
  if (actualImage.width != width || actualImage.height != height) {
    throw StateError(
      '${reference.id}: rendered ${actualImage.width}x${actualImage.height} '
      'against a ${width}x$height reference. The chart did not fill the box.',
    );
  }

  final expectedPixels = await _rgba(referenceImage);
  final actualPixels = await _rgba(actualImage);
  final mask = _maskBitmap(reference, width, height);

  final diff = Uint8List(width * height * 4);
  var mismatched = 0;
  var compared = 0;
  var masked = 0;
  for (var i = 0; i < width * height; i++) {
    final o = i * 4;
    if (mask[i]) {
      masked++;
      diff[o] = (_maskColor.r * 0xFF).round();
      diff[o + 1] = (_maskColor.g * 0xFF).round();
      diff[o + 2] = (_maskColor.b * 0xFF).round();
      diff[o + 3] = 0xFF;
      continue;
    }
    compared++;
    var worst = 0;
    for (var c = 0; c < 4; c++) {
      final delta = (expectedPixels[o + c] - actualPixels[o + c]).abs();
      if (delta > worst) worst = delta;
    }
    if (worst > _channelTolerance) {
      mismatched++;
      diff[o] = 0xFF;
      diff[o + 1] = 0x00;
      diff[o + 2] = 0x00;
      diff[o + 3] = 0xFF;
    } else {
      // Keep the unchanged pixels faintly visible so the diff reads as a chart
      // with red on it, not as red dust on nothing.
      final grey = 0xFF - ((0xFF - expectedPixels[o + 1]) >> 2);
      diff[o] = grey;
      diff[o + 1] = grey;
      diff[o + 2] = grey;
      diff[o + 3] = 0xFF;
    }
  }

  final best = _bestShift(expectedPixels, actualPixels, mask, width, height);
  final result = ParityResult(
    id: reference.id,
    mismatchPercent: compared == 0 ? 0 : mismatched / compared * 100,
    mismatchedPixels: mismatched,
    comparedPixels: compared,
    maskedPixels: masked,
    bestShift: best.shift,
    shiftedMismatchPercent: compared == 0
        ? 0
        : best.mismatched / compared * 100,
  );
  if (debugWriteParityOutput) {
    await _writeTriptych(reference, referenceImage, actualImage, diff, result);
  }
  return result;
}

/// The whole-image translation that would minimise the mismatch.
///
/// A diagnosis, never a correction: nothing is shifted before the reported
/// number is computed. A chart whose marks are all correct but whose plot rect
/// sits a pixel low produces the same wall of red as one drawing the wrong
/// shape, and the two need completely different fixes. If `(0, 0)` wins, the
/// difference is in the marks; if `(0, -1)` cuts the mismatch by most of it,
/// the difference is one rounding step in the layout and the marks are right.
///
/// Bounded at [_maxProbedShift] because beyond a few pixels a "better" offset
/// is coincidence — a chart of horizontal gridlines will always find some
/// vertical shift that lines two of them up.
({({int dx, int dy}) shift, int mismatched}) _bestShift(
  Uint8List expected,
  Uint8List actual,
  List<bool> mask,
  int width,
  int height,
) {
  var bestCount = -1;
  var bestDx = 0;
  var bestDy = 0;
  for (var dy = -_maxProbedShift; dy <= _maxProbedShift; dy++) {
    for (var dx = -_maxProbedShift; dx <= _maxProbedShift; dx++) {
      var count = 0;
      for (var y = 0; y < height; y++) {
        final sy = y + dy;
        if (sy < 0 || sy >= height) continue;
        for (var x = 0; x < width; x++) {
          final sx = x + dx;
          if (sx < 0 || sx >= width) continue;
          if (mask[y * width + x] || mask[sy * width + sx]) continue;
          final a = (y * width + x) * 4;
          final b = (sy * width + sx) * 4;
          var worst = 0;
          for (var c = 0; c < 4; c++) {
            final delta = (expected[a + c] - actual[b + c]).abs();
            if (delta > worst) worst = delta;
          }
          if (worst > _channelTolerance) count++;
        }
      }
      if (bestCount < 0 || count < bestCount) {
        bestCount = count;
        bestDx = dx;
        bestDy = dy;
      }
    }
  }
  return (shift: (dx: bestDx, dy: bestDy), mismatched: bestCount);
}

/// Radius, in pixels, of the shift search in [_bestShift].
const int _maxProbedShift = 3;

Future<Uint8List> _rgba(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return data!.buffer.asUint8List();
}

List<bool> _maskBitmap(ReactReference reference, int width, int height) {
  final mask = List<bool>.filled(width * height, false);
  for (final rect in reference.textRects) {
    // One pixel of slop on every side: a glyph's antialiased fringe reaches
    // just outside the box the browser reports for it, and an unmasked fringe
    // is a row of mismatched pixels along every label in the chart.
    final left = (rect.left - 1).floor().clamp(0, width);
    final top = (rect.top - 1).floor().clamp(0, height);
    final right = (rect.right + 1).ceil().clamp(0, width);
    final bottom = (rect.bottom + 1).ceil().clamp(0, height);
    for (var y = top; y < bottom; y++) {
      for (var x = left; x < right; x++) {
        mask[y * width + x] = true;
      }
    }
  }
  return mask;
}

Future<void> _writeTriptych(
  ReactReference reference,
  ui.Image referenceImage,
  ui.Image actualImage,
  Uint8List diff,
  ParityResult result,
) async {
  final width = referenceImage.width;
  final height = referenceImage.height;
  const gap = 8;
  final diffImage = await _imageFromRgba(diff, width, height);

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, (width * 3 + gap * 2).toDouble(), height.toDouble()),
    ui.Paint()..color = const Color(0xFF9CA3AF),
  );
  canvas.drawImage(referenceImage, Offset.zero, ui.Paint());
  canvas.drawImage(
    actualImage,
    Offset((width + gap).toDouble(), 0),
    ui.Paint(),
  );
  canvas.drawImage(
    diffImage,
    Offset((width * 2 + gap * 2).toDouble(), 0),
    ui.Paint(),
  );
  final picture = recorder.endRecording();
  final composite = await picture.toImage(width * 3 + gap * 2, height);
  final png = await composite.toByteData(format: ui.ImageByteFormat.png);

  Directory(_outDir).createSync(recursive: true);
  File(
    '$_outDir/${reference.id}.png',
  ).writeAsBytesSync(png!.buffer.asUint8List());
  // The Flutter render on its own as well. The triptych is three panels wide,
  // so any viewer scales it down by a third before a human sees it, and a
  // one-line-versus-two-line difference in a rotated axis title is invisible
  // at that scale. This is the panel you actually read.
  final actualPng = await actualImage.toByteData(
    format: ui.ImageByteFormat.png,
  );
  File(
    '$_outDir/${reference.id}.flutter.png',
  ).writeAsBytesSync(actualPng!.buffer.asUint8List());
  // ignore: avoid_print
  print(result);
}

Future<ui.Image> _imageFromRgba(Uint8List rgba, int width, int height) {
  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    rgba,
    width,
    height,
    ui.PixelFormat.rgba8888,
    completer.complete,
  );
  return completer.future;
}
