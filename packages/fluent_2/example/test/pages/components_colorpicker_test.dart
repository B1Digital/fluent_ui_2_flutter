import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// ColorPicker's eight sections are one colour shared by four painted
/// controls, so every assertion here reads the **paint** — the colour area's
/// `saturation` and `value`, a rail's `fraction`, a preview box's fill — and
/// never the demo's own `HSVColor`. A picker that updates its state and never
/// repaints its gradient is exactly the bug a state-only assertion misses.
///
/// Every gesture is a real mouse. `dropSliderAt` in the harness is
/// `tester.tapAt`, i.e. a synthesised *touch*, which cannot see the arena
/// failure these controls are most exposed to — a drag on a rail inside a
/// scrolling docs page — so the rails get a mouse-driven `mouseAtFraction`
/// instead.
void main() {
  const String page = 'components-colorpicker';

  FluentColorAreaPainter area(WidgetTester tester) =>
      paintersOf<FluentColorAreaPainter>(tester).first;

  List<FluentColorSliderPainter> rails(WidgetTester tester) =>
      paintersOf<FluentColorSliderPainter>(tester);

  /// The fill of the demo's `.previewColor` box, read off the widget tree.
  Color previewFill(WidgetTester tester, {int index = 0}) {
    final Iterable<Container> boxes = tester
        .widgetList<Container>(find.byType(Container))
        .where((Container c) {
          final Decoration? d = c.decoration;
          return d is BoxDecoration && d.borderRadius == FluentRadius.allMedium;
        });
    return ((boxes.elementAt(index).decoration! as BoxDecoration).color)!;
  }

  /// Presses a rail with a real mouse at [t] of its length, then releases.
  Future<void> mouseAtFraction(
    WidgetTester tester,
    Finder rail,
    double t,
  ) async {
    await tester.ensureVisible(rail.first);
    await settle(tester);
    final Rect box = tester.getRect(rail.first);
    // Half a pixel inside: a Rect is exclusive at its right edge, so t = 1
    // lands on the first pixel that hit-tests to nothing.
    await mouseClickAt(
      tester,
      Offset(
        (box.left + t * box.width).clamp(box.left + 0.5, box.right - 0.5),
        box.center.dy,
      ),
      what: 'the rail at $t',
    );
  }

  group('default', () {
    final DocsSection section = sectionOf('components-colorpicker--default');

    testWidgets('the area, both rails and the preview share one colour', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Upstream's DEFAULT_COLOR_HSV: h 109, s 1, v 0.9.
      expect(area(tester).saturation, 1);
      expect(area(tester).value, closeTo(0.9, 0.001));
      expect(rails(tester).first.fraction, closeTo(109 / 360, 0.001));
      expect(
        previewFill(tester),
        const HSVColor.fromAHSV(1, 109, 1, 0.9).toColor(),
      );
      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('a real mouse press on the hue rail repaints everything', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await mouseAtFraction(tester, find.byType(FluentColorSlider).first, 0.75);

      final double hue = rails(tester).first.fraction * 360;
      expect(hue, closeTo(270, 4));
      expect(
        area(tester).hueColor,
        HSVColor.fromAHSV(1, hue.roundToDouble(), 1, 1).toColor(),
        reason: 'the square repainted, not just the rail',
      );
      expect(
        previewFill(tester),
        HSVColor.fromAHSV(1, hue.roundToDouble(), 1, 0.9).toColor(),
        reason: 'and so did the preview',
      );
      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('a real mouse press on the square moves the thumb', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Rect box = tester.getRect(find.byType(FluentColorArea));

      await mouseClickAt(
        tester,
        Offset(box.left + box.width * 0.25, box.top + box.height * 0.25),
        what: 'the colour area',
      );

      expect(area(tester).saturation, closeTo(0.25, 0.02));
      expect(
        area(tester).value,
        closeTo(0.75, 0.02),
        reason: 'the square measures value up from the bottom',
      );
      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('the hex field drives the picker', (WidgetTester tester) async {
      await pumpSection(tester, section);

      await tester.enterText(find.byType(FluentInput).first, '#FF0000');
      await settle(tester);

      expect(rails(tester).first.fraction, 0, reason: 'red is hue 0');
      expect(area(tester).saturation, 1);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('color picker shape', () {
    final DocsSection section = sectionOf(
      'components-colorpicker--color-picker-shape',
    );

    testWidgets('the two pickers differ only in their corners', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final List<FluentColorAreaPainter> squares =
          paintersOf<FluentColorAreaPainter>(tester);
      expect(squares, hasLength(2));
      expect(squares[0].borderRadius, FluentRadius.allMedium);
      expect(squares[1].borderRadius, BorderRadius.zero);

      final List<FluentColorSliderPainter> all = rails(tester);
      expect(all, hasLength(4), reason: 'hue and alpha in each picker');
      expect(all[0].railRadius, FluentRadius.allMedium);
      expect(all[2].railRadius, BorderRadius.zero);
      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('each picker moves on its own', (WidgetTester tester) async {
      await pumpSection(tester, section);

      await mouseAtFraction(tester, find.byType(FluentColorSlider).first, 0.25);

      expect(rails(tester)[0].fraction, closeTo(0.25, 0.02));
      expect(
        rails(tester)[2].fraction,
        closeTo(109 / 360, 0.001),
        reason: 'the square picker below still holds its own colour',
      );
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('color area default', () {
    final DocsSection section = sectionOf(
      'components-colorpicker--color-area-default',
    );

    testWidgets('Reset puts the thumb back', (WidgetTester tester) async {
      await pumpSection(tester, section);

      expect(area(tester).saturation, closeTo(0.5, 0.001));
      expect(area(tester).value, closeTo(0.5, 0.001));

      final Rect box = tester.getRect(find.byType(FluentColorArea));
      await mouseClickAt(
        tester,
        Offset(box.left + box.width * 0.9, box.top + box.height * 0.1),
        what: 'the colour area',
      );
      expect(area(tester).saturation, greaterThan(0.8));

      await mouseClick(tester, find.text('Reset'));
      expect(area(tester).saturation, closeTo(0.5, 0.001));
      expect(area(tester).value, closeTo(0.5, 0.001));
      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('both axes announce both channels', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpSection(tester, section);

      expect(
        tester.getSemantics(find.bySemanticsLabel('Saturation')).value,
        'Saturation 50, Brightness: 50',
        reason:
            'upstream builds one aria-valuetext from both channels and hands '
            'it to inputX and inputY alike',
      );
      handle.dispose();
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('color slider default', () {
    final DocsSection section = sectionOf(
      'components-colorpicker--color-slider-default',
    );

    testWidgets('the horizontal and vertical rails stay in step', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final List<FluentColorSliderPainter> both = rails(tester);
      expect(both, hasLength(2));
      expect(both[1].vertical, isTrue);

      await mouseAtFraction(tester, find.byType(FluentColorSlider).first, 0.5);
      expect(rails(tester)[0].fraction, closeTo(0.5, 0.02));
      expect(
        rails(tester)[1].fraction,
        closeTo(0.5, 0.02),
        reason: 'both read the same colour',
      );
      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('the vertical rail puts its minimum at the bottom', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder vertical = find.byType(FluentColorSlider).at(1);
      final Rect box = tester.getRect(vertical);
      await mouseClickAt(
        tester,
        Offset(box.center.dx, box.bottom - 1),
        what: 'the bottom of the vertical rail',
      );

      expect(
        rails(tester)[1].fraction,
        lessThan(0.02),
        reason: 'hue 0 lives at the bottom, as Fluent\'s vertical sliders do',
      );
      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('the announced value carries the degree sign', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpSection(tester, section);
      expect(tester.getSemantics(find.bySemanticsLabel('Hue')).value, '109°');
      handle.dispose();
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('color slider channels', () {
    final DocsSection section = sectionOf(
      'components-colorpicker--color-slider-channels',
    );

    testWidgets('hue, saturation and value each ramp differently', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final List<FluentColorSliderPainter> three = rails(tester);
      expect(three, hasLength(3));
      expect(three[0].railColors, hasLength(7), reason: 'the hue ramp');
      expect(three[1].railColors.first, const Color(0xFF808080));
      expect(three[2].railColors.first, const Color(0xFF000000));
      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('moving saturation leaves hue where it was', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final double hue = rails(tester)[0].fraction;

      await mouseAtFraction(tester, find.byType(FluentColorSlider).at(1), 0.25);

      expect(rails(tester)[1].fraction, closeTo(0.25, 0.02));
      expect(rails(tester)[0].fraction, hue, reason: 'hue is untouched');
      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('Reset restores #2be700', (WidgetTester tester) async {
      await pumpSection(tester, section);
      final double hue = rails(tester)[0].fraction;

      await mouseAtFraction(tester, find.byType(FluentColorSlider).first, 0.9);
      expect(rails(tester)[0].fraction, isNot(hue));

      await mouseClick(tester, find.text('Reset'));
      expect(rails(tester)[0].fraction, hue);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('alpha slider default', () {
    final DocsSection section = sectionOf(
      'components-colorpicker--alpha-slider-default',
    );

    testWidgets('the opacity and transparency rails run opposite ways', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final List<FluentColorSliderPainter> four = rails(tester);
      expect(four, hasLength(4));
      for (final FluentColorSliderPainter rail in four) {
        expect(rail.checkered, isTrue, reason: 'every one is an alpha rail');
      }
      // The first two are opacity, the last two transparency: at the anchor
      // edge, opacity starts transparent and transparency starts opaque.
      expect(four[0].railColors.first.a, 0);
      expect(four[2].railColors.first.a, 1);
      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('a transparency rail at 30 reports a 70 percent colour', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpSection(tester, section);

      await mouseAtFraction(tester, find.byType(FluentAlphaSlider).at(2), 0.3);

      // Read the announced transparency rather than assuming the pixel the
      // mouse landed on — `mouseClick` travels two pixels between press and
      // release, which is the point of it — then assert the invariant: the
      // preview is the colour at exactly the complementary opacity.
      final double transparency = double.parse(
        tester
            .getSemantics(find.bySemanticsLabel('Alpha').at(1))
            .value
            .replaceAll('%', ''),
      );
      expect(transparency, closeTo(30, 2));
      expect(
        previewFill(tester, index: 1).a * 100,
        closeTo(100 - transparency, 0.6),
        reason: 'transparency inverts the value, exactly once',
      );
      handle.dispose();
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('color and swatch picker', () {
    final DocsSection section = sectionOf(
      'components-colorpicker--color-and-swatch-picker',
    );

    testWidgets('Add new color appends the dialled-in colour', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(find.byType(FluentSwatch), findsNWidgets(8));

      await mouseAtFraction(tester, find.byType(FluentColorSlider).first, 0.5);
      final Color dialled = previewFill(tester);

      await mouseClick(tester, find.text('Add new color'));
      await settle(tester);

      final Iterable<FluentSwatch> swatches = tester
          .widgetList<FluentSwatch>(find.byType(FluentSwatch))
          .where((FluentSwatch s) => s.color != null);
      expect(swatches, hasLength(1));
      expect(swatches.single.color, dialled);
      expect(
        find.byType(FluentSwatch),
        findsNWidgets(8),
        reason: 'one empty slot gave way, so the row is still eight long',
      );
      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('Reset example empties the row again', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await mouseClick(tester, find.text('Add new color'));
      await settle(tester);
      expect(
        tester
            .widgetList<FluentSwatch>(find.byType(FluentSwatch))
            .where((FluentSwatch s) => s.color != null),
        hasLength(1),
      );

      await mouseClick(tester, find.text('Reset example'));
      await settle(tester);
      expect(
        tester
            .widgetList<FluentSwatch>(find.byType(FluentSwatch))
            .where((FluentSwatch s) => s.color != null),
        isEmpty,
      );
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('color picker popup', () {
    final DocsSection section = sectionOf(
      'components-colorpicker--color-picker-popup',
    );

    testWidgets('Choose color opens a picker, Ok commits it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.byType(FluentColorArea), findsNothing);

      await mouseClick(tester, find.text('Choose color'));
      await settle(tester);
      expect(
        find.byType(FluentColorArea),
        findsOneWidget,
        reason:
            'the popover lays its content out fully unbounded, which is what '
            'buildFluentColorPicker\'s IntrinsicWidth is there for',
      );

      await mouseAtFraction(tester, find.byType(FluentColorSlider).first, 0.5);
      // Index 1, not 0: the overlay is a separate branch of the tree that
      // comes after the page, so while the popover is open the *page's*
      // committed preview is still first and the popover's live one is second.
      final Color dialled = previewFill(tester, index: 1);
      expect(
        dialled,
        isNot(previewFill(tester)),
        reason: 'nothing committed yet',
      );

      await mouseClick(tester, find.text('Ok'));
      await settle(tester);

      expect(find.byType(FluentColorArea), findsNothing);
      expect(previewFill(tester), dialled, reason: 'Ok committed the colour');
      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('Cancel closes it and leaves the colour alone', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Color before = previewFill(tester);

      await mouseClick(tester, find.text('Choose color'));
      await settle(tester);
      await mouseAtFraction(tester, find.byType(FluentColorSlider).first, 0.9);
      await mouseClick(tester, find.text('Cancel'));
      await settle(tester);

      expect(find.byType(FluentColorArea), findsNothing);
      expect(previewFill(tester), before);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('keyboard', () {
    testWidgets('a focused rail answers the arrow keys', (
      WidgetTester tester,
    ) async {
      final DocsSection section = sectionOf(
        'components-colorpicker--color-slider-default',
      );
      await pumpSection(tester, section);

      // Nothing here takes focus on a press — upstream preventDefaults its
      // mousedown — so focus is placed explicitly, which is what a Tab does.
      await focusOn(tester, find.byType(FluentColorSlider).first);
      final double before = rails(tester)[0].fraction;

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await settle(tester);

      expect(
        rails(tester)[0].fraction,
        closeTo(before + 1 / 360, 0.0001),
        reason: 'one degree, as a native range input steps',
      );
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('layout', () {
    testWidgets('no section spills out of upstream\'s 300-wide column', (
      WidgetTester tester,
    ) async {
      // `loose: true` matters: pumpSection's default hands the demo a *tight*
      // viewport width, and a SizedBox cannot shrink under tight constraints —
      // so `_Example`'s 300 box renders 1600 wide and nothing is ever too wide
      // for it. That is why the suite did not catch the hex + RGB row growing
      // to 306 and spilling out of the column in the browser. The real docs
      // page constrains loosely, which is what this reproduces.
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section, loose: true);

        final Finder column = find.byWidgetPredicate(
          (Widget w) => w is SizedBox && w.width == 300,
        );
        expect(column, findsWidgets, reason: '${section.id}: no 300 column');
        expect(
          tester.getSize(column.first).width,
          300.0,
          reason:
              '${section.id}: the column is not actually 300 wide, so nothing '
              'below can be too wide for it and this test proves nothing',
        );

        // Rows are the only thing that can outgrow it — everything else is a
        // fixed box. The test font is far wider than Selawik, which is a
        // feature here: it exercises a field label wider than its field.
        final Finder rows = find.descendant(
          of: column.first,
          matching: find.byType(Row),
        );
        for (int i = 0; i < rows.evaluate().length; i += 1) {
          expect(
            tester.getRect(rows.at(i)).width,
            lessThanOrEqualTo(300.0),
            reason:
                '${section.id}: Row $i is wider than the 300 column it sits '
                'in. Make one child Flexible so it gives way, the way a CSS '
                'flex item shrinks.',
          );
        }
      }
    });
  });

  group('lifecycle', () {
    testWidgets('every section unmounts without throwing', (
      WidgetTester tester,
    ) async {
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section);
        await expectCleanTeardown(tester, section.id);
      }
    });
  });
}
