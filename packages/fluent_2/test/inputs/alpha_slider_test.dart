import 'dart:ui' as ui;

import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// `FluentAlphaSlider` is `FluentColorSlider` on the alpha channel — upstream's
/// `useAlphaSliderStyles_unstable` ends by *calling*
/// `useColorSliderStyles_unstable`, and `AlphaSliderSlots` is a type alias for
/// `ColorSliderSlots`. `color_slider_test.dart` therefore carries the shared
/// machinery; this file asserts only what alpha adds: the checkerboard, the
/// visible rail border, the translucent thumb, and the `transparency` flag.
void main() {
  const key = Key('alpha');

  FluentThemeData light() =>
      FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  Future<void> pump(
    WidgetTester tester,
    Widget rail, {
    FluentThemeData? theme,
    double? width = 300,
    double? height,
    TextDirection direction = TextDirection.ltr,
  }) => tester.pumpWidget(
    FluentApp(
      theme: theme ?? light(),
      home: Directionality(
        textDirection: direction,
        child: Center(
          child: SizedBox(width: width, height: height, child: rail),
        ),
      ),
    ),
  );

  FluentColorSliderPainter painterOf(WidgetTester tester) => tester
      .widgetList<CustomPaint>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(CustomPaint),
        ),
      )
      .map((paint) => paint.painter)
      .whereType<FluentColorSliderPainter>()
      .first;

  const half = HSVColor.fromAHSV(0.5, 200, 1, 1);

  group('the checkerboard', () {
    test('is 6px squares, dark at the top left, alternating', () async {
      final recorder = ui.PictureRecorder();
      const FluentColorSliderPainter(
        fraction: 0,
        // A fully transparent ramp, so only the checkerboard shows through.
        railColors: <Color>[Color(0x00000000), Color(0x00000000)],
        checkered: true,
        vertical: false,
        anchor: Alignment.centerLeft,
        thumbColor: Color(0xFF000000),
        railThickness: 20,
        railRadius: BorderRadius.zero,
        railBorderWidth: 0,
        thumbSize: 0,
        thumbBorderWidth: 0,
        thumbInnerWidth: 0,
      ).paint(ui.Canvas(recorder), const Size(60, 20));
      final image = await recorder.endRecording().toImage(60, 20);
      addTearDown(image.dispose);
      final bytes = (await image.toByteData())!.buffer.asUint8List();

      Color at(int x, int y) {
        final i = (y * 60 + x) * 4;
        return Color.fromARGB(
          bytes[i + 3],
          bytes[i],
          bytes[i + 1],
          bytes[i + 2],
        );
      }

      // Square (column, row) is dark when column + row is even, exactly as the
      // decoded 12x12 tile of Fabric's transparent-pattern.png is.
      expect(at(3, 3), kFluentAlphaCheckerDark, reason: 'column 0, row 0');
      expect(at(9, 3), kFluentAlphaCheckerLight, reason: 'column 1, row 0');
      expect(at(3, 9), kFluentAlphaCheckerLight, reason: 'column 0, row 1');
      expect(at(9, 9), kFluentAlphaCheckerDark, reason: 'column 1, row 1');
      expect(at(15, 3), kFluentAlphaCheckerDark, reason: 'column 2, row 0');
      expect(at(3, 15), kFluentAlphaCheckerDark, reason: 'column 0, row 2');
    });

    test('its colours and square are upstream\'s decoded PNG', () {
      expect(kFluentAlphaCheckerLight, const Color(0xFFFFFFFF));
      expect(kFluentAlphaCheckerDark, const Color(0xFFCCCCCC));
      expect(kFluentAlphaCheckerSquare, 6);
    });

    testWidgets('only an alpha rail draws one', (tester) async {
      await pump(
        tester,
        const FluentAlphaSlider(key: key, color: half, semanticLabel: 'Alpha'),
      );
      expect(painterOf(tester).checkered, isTrue);

      await pump(
        tester,
        const FluentColorSlider(key: key, color: half, semanticLabel: 'Hue'),
      );
      expect(painterOf(tester).checkered, isFalse);
    });

    test('the gradient is painted over it, never under', () async {
      final recorder = ui.PictureRecorder();
      const FluentColorSliderPainter(
        fraction: 1,
        // A fully OPAQUE ramp: if the checkerboard were painted last it would
        // cover this.
        railColors: <Color>[Color(0xFFFF0000), Color(0xFFFF0000)],
        checkered: true,
        vertical: false,
        anchor: Alignment.centerLeft,
        thumbColor: Color(0xFF000000),
        railThickness: 20,
        railRadius: BorderRadius.zero,
        railBorderWidth: 0,
        thumbSize: 0,
        thumbBorderWidth: 0,
        thumbInnerWidth: 0,
      ).paint(ui.Canvas(recorder), const Size(60, 20));
      final image = await recorder.endRecording().toImage(60, 20);
      addTearDown(image.dispose);
      final bytes = (await image.toByteData())!.buffer.asUint8List();
      expect(
        Color.fromARGB(bytes[3], bytes[0], bytes[1], bytes[2]),
        const Color(0xFFFF0000),
      );
    });
  });

  group('the rail', () {
    testWidgets('outlines in neutralStroke1, not colorTransparentStroke', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentAlphaSlider(key: key, color: half, semanticLabel: 'Alpha'),
      );
      final painter = painterOf(tester);
      expect(
        painter.railBorderColor,
        light().colors.neutralStroke1,
        reason:
            'useAlphaSliderStyles.styles.ts adds `border: 1px solid '
            'colorNeutralStroke1` so the checkerboard reads as part of the '
            'control',
      );
      expect(painter.railBorderWidth, FluentStroke.thin);
    });

    testWidgets('stays 20 deep, so it lines up with a hue rail above it', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentAlphaSlider(key: key, color: half, semanticLabel: 'Alpha'),
      );
      expect(
        painterOf(tester).railThickness,
        20,
        reason:
            'upstream leaves the alpha rail content-box, so its border makes '
            'it 22 and it sits a pixel proud of the hue rail. Deliberate '
            'deviation: the border is painted inside.',
      );
    });

    testWidgets('fades from transparent to the opaque colour', (tester) async {
      await pump(
        tester,
        const FluentAlphaSlider(key: key, color: half, semanticLabel: 'Alpha'),
      );
      final ramp = painterOf(tester).railColors;
      const opaque = Color(0xFF00AAFF);
      expect(ramp.last, opaque);
      expect(
        ramp.first,
        opaque.withAlpha(0),
        reason:
            'the transparent stop carries the opaque colour\'s RGB. Flutter '
            'interpolates unpremultiplied, so a transparent black stop would '
            'drag the ramp towards grey instead of fading cleanly.',
      );
    });
  });

  group('the thumb', () {
    testWidgets('shows the colour at its alpha, over the surface', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentAlphaSlider(key: key, color: half, semanticLabel: 'Alpha'),
      );
      expect(
        painterOf(tester).thumbColor,
        Color.alphaBlend(
          const Color(0x8000AAFF),
          light().colors.neutralBackground1,
        ),
        reason:
            'upstream\'s ::before sits inside the thumb, whose own background '
            'is colorNeutralBackground1 — so a translucent colour composites '
            'over the surface, not over the rail\'s checkerboard',
      );
    });
  });

  group('transparency', () {
    FluentColorSliderBaseState state({
      required bool transparency,
      double alpha = 0.5,
    }) => FluentColorSliderBaseState(
      color: HSVColor.fromAHSV(alpha, 200, 1, 1),
      channel: FluentColorChannel.alpha,
      vertical: false,
      transparency: transparency,
      enabled: true,
    );

    test('inverts the announced value', () {
      expect(state(transparency: false).channelValue, 50);
      expect(state(transparency: true).channelValue, 50);
      expect(state(transparency: false, alpha: 0.3).channelValue, 30);
      expect(
        state(transparency: true, alpha: 0.3).channelValue,
        70,
        reason: '30% opaque is 70% transparent',
      );
    });

    test('does not double-invert', () {
      // Drop the rail to 30 with transparency on: the reported colour is 70%
      // opaque, and the rail still announces 30.
      final next = state(transparency: true, alpha: 0.3).colorAt(30);
      expect(next.alpha, closeTo(0.7, 1e-9));
      expect(
        state(transparency: true, alpha: next.alpha).channelValue,
        30,
        reason: 'the value goes out as it came in',
      );
    });

    test('reverses the ramp rather than the anchor', () {
      const opaque = Color(0xFF00AAFF);
      expect(state(transparency: false).railColors, <Color>[
        opaque.withAlpha(0),
        opaque,
      ]);
      expect(
        state(transparency: true).railColors,
        <Color>[opaque, opaque.withAlpha(0)],
        reason:
            'upstream flips a CSS angle instead, and gets the RTL + '
            'transparency cell wrong (getSliderDirection emits -90deg twice). '
            'Reversing the stops around a fixed anchor is right in all four.',
      );
    });

    testWidgets('all four direction cells agree with the thumb', (
      tester,
    ) async {
      for (final direction in TextDirection.values) {
        for (final transparency in <bool>[false, true]) {
          await pump(
            tester,
            FluentAlphaSlider(
              key: key,
              color: half,
              transparency: transparency,
              semanticLabel: 'Alpha',
            ),
            direction: direction,
          );
          final painter = painterOf(tester);
          final anchor = fluentColorRailAnchor(
            vertical: false,
            textDirection: direction,
          );
          expect(painter.anchor, anchor, reason: '$direction $transparency');
          // fraction is measured from the anchor, and the ramp starts there,
          // so the colour under the thumb is the colour the value means.
          expect(
            painter.railColors.first.a,
            transparency ? 1.0 : 0.0,
            reason:
                'at the anchor, transparency mode starts opaque and opacity '
                'mode starts transparent ($direction)',
          );
        }
      }
    });

    testWidgets('a vertical alpha rail anchors at the bottom either way', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentAlphaSlider(
          key: key,
          color: half,
          vertical: true,
          semanticLabel: 'Alpha',
        ),
        width: null,
        height: 280,
        direction: TextDirection.rtl,
      );
      expect(painterOf(tester).anchor, Alignment.bottomCenter);
    });
  });

  group('the widget is the colour slider with a name', () {
    testWidgets('it forwards every argument to the alpha channel', (
      tester,
    ) async {
      final reported = <HSVColor>[];
      await pump(
        tester,
        FluentAlphaSlider(
          key: key,
          color: half,
          onChanged: reported.add,
          shape: FluentColorPickerShape.square,
          semanticLabel: 'Alpha',
        ),
        width: 300,
      );
      final painter = painterOf(tester);
      expect(painter.checkered, isTrue);
      expect(painter.railRadius, BorderRadius.zero);

      final rail = tester.getRect(find.byKey(key));
      await tester.tapAt(Offset(rail.left + 75, rail.center.dy));
      await tester.pump();
      expect(reported.single.alpha, closeTo(0.25, 1e-9));
      expect(reported.single.hue, 200, reason: 'alpha edits only alpha');
    });
  });
}
