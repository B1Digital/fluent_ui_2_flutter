import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:fluent_2_example/shell/vision_filter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// [VisionFilter] against the pixels Chrome paints for the same filters.
///
/// The oracle is headless Chrome 153 (`--force-color-profile=srgb`, DPR 1) on
/// a #0078D4 square over white, read back from a screenshot: the SVG
/// `feColorMatrix` protanopia filter upstream's a11y addon renders gives
/// `rgb(81, 81, 195)`, CSS `grayscale(100%)` gives `rgb(101, 101, 101)`, and
/// `blur(2px)` gives `rgb(102, 174, 229)` on the square's first column. 101 is
/// the Filter Effects grayscale matrix applied to the *sRGB* values
/// (.7152 * 120 + .0722 * 212 = 101.1); in linearRGB it would be 118. The
/// protanopia value is the matrix in linearRGB; in sRGB it would be #3435BE.
void main() {
  const Color blue = Color(0xFF0078D4);
  const Color white = Color(0xFFFFFFFF);

  test('the filters, their labels and shares follow the addon', () {
    // `addons/a11y` `VisionSimulator.tsx`, the `Bl` list in the bundle: lower
    // case in the source, capitalised on screen by `text-transform`.
    expect(VisionFilter.values.map((VisionFilter f) => f.label), <String>[
      'Blurred Vision',
      'Deuteranomaly',
      'Deuteranopia',
      'Protanomaly',
      'Protanopia',
      'Tritanomaly',
      'Tritanopia',
      'Achromatopsia',
      'Grayscale',
    ]);
    expect(VisionFilter.values.map((VisionFilter f) => f.share), <String?>[
      '22.9%',
      '2.7%',
      '0.56%',
      '0.66%',
      '0.59%',
      '0.01%',
      '0.016%',
      '0.0001%',
      null,
    ]);
  });

  test(
    'protanopia runs its matrix in linearRGB, as feColorMatrix does',
    () async {
      final _Pixels pixels = await _paint(VisionFilter.protanopia, blue);
      _expectNear(pixels.at(20, 20), const Color(0xFF5151C3));
    },
  );

  test('grayscale is the CSS function, in sRGB', () async {
    final _Pixels pixels = await _paint(VisionFilter.grayscale, blue);
    _expectNear(pixels.at(20, 20), const Color(0xFF656565));
  });

  test('blurred vision softens an edge by a 2px standard deviation', () async {
    // The square spans x 20..60 of an 80px strip; x 20 is its first column.
    // Chrome paints rgb(102, 174, 229) there and Skia rgb(105, 176, 230);
    // the bound is the property, not the exact kernel.
    final _Pixels pixels = await _paint(
      VisionFilter.blurredVision,
      blue,
      square: const Rect.fromLTWH(20, 0, 40, 40),
      size: const Size(80, 40),
    );
    final Color edge = pixels.at(20, 20);
    expect(edge.r, inExclusiveRange(blue.r, white.r), reason: '$edge');
    expect(edge.g, inExclusiveRange(blue.g, white.g), reason: '$edge');
    expect(edge.b, inExclusiveRange(blue.b, white.b), reason: '$edge');
    // The square's middle is out of the blur's reach and stays put.
    _expectNear(pixels.at(40, 20), blue);
  });
}

/// Paints [square] in [color] over white inside a layer carrying [filter]'s
/// [VisionFilter.imageFilter], the way `ImageFiltered` would, and reads the
/// result back.
Future<_Pixels> _paint(
  VisionFilter filter,
  Color color, {
  Rect square = const Rect.fromLTWH(0, 0, 40, 40),
  Size size = const Size(40, 40),
}) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  final Rect bounds = Offset.zero & size;
  canvas
    ..saveLayer(bounds, Paint()..imageFilter = filter.imageFilter)
    ..drawRect(bounds, Paint()..color = const Color(0xFFFFFFFF))
    ..drawRect(square, Paint()..color = color)
    ..restore();
  final ui.Image image = await recorder.endRecording().toImage(
    size.width.toInt(),
    size.height.toInt(),
  );
  final ByteData data = (await image.toByteData())!;
  image.dispose();
  return _Pixels(data, size.width.toInt());
}

class _Pixels {
  const _Pixels(this._data, this._stride);

  final ByteData _data;
  final int _stride;

  Color at(int x, int y) {
    final int o = (y * _stride + x) * 4;
    return Color.fromARGB(
      _data.getUint8(o + 3),
      _data.getUint8(o),
      _data.getUint8(o + 1),
      _data.getUint8(o + 2),
    );
  }
}

/// Every channel within 2/255 of [expected]: the rounding slack between
/// Skia's and Chrome's filter pipelines.
void _expectNear(Color actual, Color expected) {
  int byte(double v) => (v * 255).round();
  for (final (double a, double e) in <(double, double)>[
    (actual.r, expected.r),
    (actual.g, expected.g),
    (actual.b, expected.b),
    (actual.a, expected.a),
  ]) {
    expect(
      (byte(a) - byte(e)).abs(),
      lessThanOrEqualTo(2),
      reason: 'got $actual, want $expected',
    );
  }
}
