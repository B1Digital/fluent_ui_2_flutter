import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/widgets/story_outlines.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every role colour, as 0xRRGGBB, for "is this pixel an outline" checks.
final Set<int> _outlineColours = <int>{
  for (final Color c in <Color>[
    StoryOutlines.boxColor,
    StoryOutlines.buttonColor,
    StoryOutlines.textColor,
    StoryOutlines.inputColor,
    StoryOutlines.imageColor,
  ])
    c.toARGB32() & 0xFFFFFF,
};

/// A captured frame, read back pixel by pixel.
class _Shot {
  _Shot(this.width, this.height, this.bytes);

  final int width;
  final int height;
  final ByteData bytes;

  /// The pixel at logical ([x], [y]) as 0xRRGGBB (DPR 1, so logical = device).
  int at(double x, double y) {
    final int i = (y.floor() * width + x.floor()) * 4;
    return (bytes.getUint8(i) << 16) |
        (bytes.getUint8(i + 1) << 8) |
        bytes.getUint8(i + 2);
  }

  /// How many pixels pass [test], optionally only those outside [outside].
  int count(bool Function(int rgb) test, {Rect? outside}) {
    int n = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (outside != null && outside.contains(Offset(x + .5, y + .5))) {
          continue;
        }
        if (test(at(x.toDouble(), y.toDouble()))) {
          n++;
        }
      }
    }
    return n;
  }
}

final GlobalKey _frame = GlobalKey();

/// Mounts [story] 20px into a white 400x300 capture frame.
Future<void> _pump(WidgetTester tester, Widget story) async {
  tester.view.physicalSize = const Size(400, 300);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    FluentApp(
      debugShowCheckedModeBanner: false,
      home: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: _frame,
          child: ColoredBox(
            color: const Color(0xFFFFFFFF),
            child: SizedBox(
              width: 400,
              height: 300,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Align(alignment: Alignment.topLeft, child: story),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  // FluentApp renders nothing until its font future resolves.
  await tester.pumpAndSettle();
}

/// Rasterises the capture frame. `toImage` completes on the real event loop,
/// hence `runAsync`.
Future<_Shot> _grab(WidgetTester tester) async {
  final RenderRepaintBoundary boundary =
      _frame.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final ui.Image image = (await tester.runAsync(() => boundary.toImage()))!;
  addTearDown(image.dispose);
  final ByteData bytes = (await tester.runAsync<ByteData?>(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  return _Shot(image.width, image.height, bytes);
}

int _rgb(Color c) => c.toARGB32() & 0xFFFFFF;

bool _isOutline(int rgb) => _outlineColours.contains(rgb);

void main() {
  testWidgets('disabled adds no render object and paints no outline', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      StoryOutlines(
        enabled: false,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: FluentButton(onPressed: () {}, child: const Text('Example')),
        ),
      ),
    );

    // The first render object under StoryOutlines is the story's own Padding.
    expect(
      tester.renderObject(find.byType(StoryOutlines)),
      isA<RenderPadding>(),
    );
    final _Shot shot = await _grab(tester);
    expect(shot.count(_isOutline), 0);
  });

  testWidgets('a button gets the button ring, its Padding the box ring', (
    WidgetTester tester,
  ) async {
    final GlobalKey pad = GlobalKey();
    await _pump(
      tester,
      StoryOutlines(
        enabled: true,
        child: Padding(
          key: pad,
          padding: const EdgeInsets.all(10),
          child: FluentButton(onPressed: () {}, child: const Text('Example')),
        ),
      ),
    );

    final Rect button = tester.getRect(find.byType(FluentButton));
    final Rect box = tester.getRect(find.byKey(pad));
    final _Shot shot = await _grab(tester);
    // CSS `outline: 1px solid`, offset 0: the ring is the pixel row/column
    // just OUTSIDE the box, never on its edge pixels.
    expect(
      shot.at(button.center.dx, button.top - 1),
      _rgb(StoryOutlines.buttonColor),
    );
    expect(
      shot.at(button.center.dx, button.bottom),
      _rgb(StoryOutlines.buttonColor),
    );
    expect(
      shot.at(button.right, button.center.dy),
      _rgb(StoryOutlines.buttonColor),
    );
    expect(shot.at(box.left - 1, box.center.dy), _rgb(StoryOutlines.boxColor));
    expect(shot.at(box.center.dx, box.top - 1), _rgb(StoryOutlines.boxColor));
    expect(shot.at(box.center.dx, box.bottom), _rgb(StoryOutlines.boxColor));
    // Between the rings is the white 10px padding.
    expect(shot.at(box.left + 5, box.center.dy), 0xFFFFFF);
  });

  testWidgets('the ring follows a Transform.scale zoom', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      StoryOutlines(
        enabled: true,
        child: Transform.scale(
          scale: 2,
          alignment: Alignment.topLeft,
          child: FluentButton(onPressed: () {}, child: const Text('Example')),
        ),
      ),
    );

    final Rect button = tester.getRect(find.byType(FluentButton));
    final _Shot shot = await _grab(tester);
    // The scaled far edges: an unscaled mapping would put them at half-size.
    expect(
      shot.at(button.right, button.center.dy),
      _rgb(StoryOutlines.buttonColor),
    );
    expect(
      shot.at(button.center.dx, button.bottom),
      _rgb(StoryOutlines.buttonColor),
    );
  });

  testWidgets(
    'a scrolling list clips its outlines and repaints them on scroll',
    (WidgetTester tester) async {
      final ScrollController controller = ScrollController();
      addTearDown(controller.dispose);
      await _pump(
        tester,
        StoryOutlines(
          enabled: true,
          child: SizedBox(
            width: 100,
            height: 20,
            child: ListView(
              controller: controller,
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                for (int i = 0; i < 10; i++)
                  SizedBox(width: 60, child: Text('item $i')),
              ],
            ),
          ),
        ),
      );

      final Rect list = tester.getRect(find.byType(ListView));
      _Shot shot = await _grab(tester);
      // The list's own ring sits 1px outside it; nothing may sit beyond that.
      // Items 1..5 are laid out (cache extent) far past the right edge.
      expect(shot.count(_isOutline, outside: list.inflate(1)), 0);
      // Item 1 starts at 60: its ring is the column at 59.
      expect(_isOutline(shot.at(list.left + 59, list.center.dy)), isTrue);
      expect(_isOutline(shot.at(list.left + 9, list.center.dy)), isFalse);

      controller.jumpTo(50);
      await tester.pump();
      shot = await _grab(tester);
      // Item 1 now starts at 10.
      expect(_isOutline(shot.at(list.left + 9, list.center.dy)), isTrue);
      expect(_isOutline(shot.at(list.left + 59, list.center.dy)), isFalse);
      expect(shot.count(_isOutline, outside: list.inflate(1)), 0);
    },
  );

  testWidgets('an icon glyph gets no text ring', (WidgetTester tester) async {
    await _pump(
      tester,
      const StoryOutlines(
        enabled: true,
        child: Icon(FluentIcons.add_20_regular, size: 20),
      ),
    );

    final _Shot shot = await _grab(tester);
    expect(shot.count((int rgb) => rgb == _rgb(StoryOutlines.textColor)), 0);
    // The Icon's own SizedBox is still a box, like the <svg>'s parent element.
    expect(
      shot.count((int rgb) => rgb == _rgb(StoryOutlines.boxColor)),
      greaterThan(0),
    );
  });
}
