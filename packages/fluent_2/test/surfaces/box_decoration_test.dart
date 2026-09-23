import 'dart:typed_data';

import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Upstream shadows transparent boxes all the time — `boxShadow: shadow16` and
/// no background — and CSS paints an outer shadow only outside the border box.
/// A plain `BoxDecoration` paints it under the whole box: an opaque fill hides
/// that, a transparent box shows it as a grey wash. The CarouselNav demo washed
/// to #c1 where upstream shows the stage. These read rasterised pixels, because
/// the difference exists nowhere else.
void main() {
  const stage = Color(0xFFFAFAFA);
  const scene = Key('scene');
  final shadow16 = FluentThemeData.light(
    fontPlatform: FluentFontPlatform.web,
  ).shadow(FluentElevation.shadow16);

  /// Paints [decoration] on a 200x120 box centred on a 400x300 stage — so the
  /// box spans (100,90) to (300,210) — and returns the stage's RGBA bytes.
  Future<ByteData> paint(WidgetTester tester, Decoration decoration) async {
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          key: scene,
          child: Container(
            width: 400,
            height: 300,
            color: stage,
            alignment: Alignment.center,
            child: DecoratedBox(
              decoration: decoration,
              child: const SizedBox(width: 200, height: 120),
            ),
          ),
        ),
      ),
    );
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(scene),
    );
    return (await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData();
      image.dispose();
      return bytes!;
    }))!;
  }

  Color at(ByteData bytes, int x, int y) {
    final i = (y * 400 + x) * 4;
    return Color.fromARGB(
      bytes.getUint8(i + 3),
      bytes.getUint8(i),
      bytes.getUint8(i + 1),
      bytes.getUint8(i + 2),
    );
  }

  testWidgets('a transparent box keeps its shadow outside it, as CSS does', (
    tester,
  ) async {
    final washed = await paint(tester, BoxDecoration(boxShadow: shadow16));
    expect(
      at(washed, 200, 150),
      isNot(stage),
      reason:
          'the control: BoxDecoration paints the blurred shadow under the '
          'box, which is the wash this class exists to avoid',
    );

    final css = await paint(tester, FluentBoxDecoration(boxShadow: shadow16));
    expect(at(css, 200, 150), stage, reason: 'the middle of the box');
    expect(
      at(css, 200, 92),
      stage,
      reason: 'just inside the top edge, where the 8px key offset left a band',
    );
    expect(
      at(css, 200, 212).r,
      lessThan(stage.r),
      reason: 'the shadow itself must still fall below the box',
    );
  });

  testWidgets('it still paints its own fill', (tester) async {
    const fill = Color(0xFF0F6CBD);
    final bytes = await paint(
      tester,
      FluentBoxDecoration(
        color: fill,
        borderRadius: FluentRadius.allXLarge,
        boxShadow: shadow16,
      ),
    );
    expect(at(bytes, 200, 150), fill);
    expect(at(bytes, 200, 212).r, lessThan(stage.r));
  });
}
