import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Spinner's page has no knobs and nothing to press: four sections whose whole
/// content is a ring that must be *turning*, at the size, in the colours and
/// beside the label its section named. None of that is in the widget tree —
/// the ring is one `CustomPaint`, so the painter's own fields are the only
/// honest answer to what reached the screen — and the motion cannot be settled
/// for, because it repeats forever. Every test below reads
/// [FluentSpinnerPainter] directly and, where the claim is motion, samples it
/// across pumped frames.
void main() {
  const String page = 'components-spinner';

  group('default', () {
    final DocsSection section = sectionOf('components-spinner--default');

    testWidgets('the bare ring keeps turning', (WidgetTester tester) async {
      await pumpSection(tester, section);

      expect(ringFinder(), findsOneWidget);
      expect(
        find.byType(Text),
        findsNothing,
        reason: 'the default spinner is a bare ring',
      );

      // Four samples inside one 1.5s cycle, so a wrap back to zero cannot be
      // mistaken for a stalled controller or the other way round.
      final List<FluentSpinnerPose> poses = <FluentSpinnerPose>[];
      for (int i = 0; i < 4; i++) {
        poses.add(painters(tester).single.pose);
        await tester.pump(const Duration(milliseconds: 300));
      }
      for (int i = 1; i < poses.length; i++) {
        expect(
          poses[i].rotation,
          greaterThan(poses[i - 1].rotation),
          reason: 'sample $i did not turn: the ring is frozen',
        );
      }
      // The tail travels along the track on its own curve alongside the
      // rotation; a spinner that only rotated a fixed arc would keep every
      // rotation assertion above and still be the wrong animation.
      for (int i = 1; i < poses.length; i++) {
        expect(
          poses[i].tailStart,
          greaterThan(poses[i - 1].tailStart),
          reason: 'sample $i left the tail where it was',
        );
      }
      // Not "every sample differs": the two keyframes bounding the second half
      // of the cycle carry the same 90-unit dash, so the sweep is deliberately
      // constant there. What must be true is that it grew at all.
      expect(
        poses.map((FluentSpinnerPose p) => p.tailSweep).toSet().length,
        greaterThan(1),
      );
      expect(
        poses.first.tailSweep,
        isNot(closeTo(FluentSpinnerPose.resting.tailSweep, 0.0001)),
        reason:
            'the resting pose is what reduced motion paints, not what a '
            'running spinner holds',
      );
    });

    testWidgets('the default ring is the medium 32px one', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(tester.getRect(ringFinder()).size, const Size(32, 32));
      expect(painters(tester).single.strokeWidth, FluentStroke.thicker);
    });
  });

  group('appearance', () {
    final DocsSection section = sectionOf('components-spinner--appearance');

    testWidgets('primary and inverted take different token triples', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final FluentColors colors = themeOf(tester).colors;
      final List<FluentSpinnerPainter> rings = painters(tester);
      expect(rings, hasLength(2));

      expect(rings[0].trackColor, colors.brandStroke2Contrast);
      expect(rings[0].indicatorColor, colors.brandStroke1);
      expect(rings[1].trackColor, colors.neutralStrokeAlpha2);
      expect(rings[1].indicatorColor, colors.neutralStrokeOnBrand2);
      expect(
        rings[0].trackColor,
        isNot(rings[1].trackColor),
        reason: 'two appearances that resolve to one ring show nothing',
      );

      // The inverted label is coloured for the brand fill it sits on, not for
      // the page behind it — that is the whole reason the demo paints a solid
      // background under the second spinner.
      expect(
        textStyleOf(tester, find.text('Primary Spinner'))?.color,
        colors.neutralForeground1,
      );
      expect(
        textStyleOf(tester, find.text('Inverted Spinner'))?.color,
        colors.neutralForegroundStaticInverted,
      );
    });

    testWidgets('appearance moves colour and nothing else', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(
        tester.getRect(ringAt(0)).size,
        tester.getRect(ringAt(1)).size,
        reason: 'the appearance axis must not resize the ring',
      );
      expect(painters(tester)[0].strokeWidth, painters(tester)[1].strokeWidth);
    });
  });

  group('labels', () {
    final DocsSection section = sectionOf('components-spinner--labels');

    testWidgets('each label position puts the label where it says', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Rect beforeRing = tester.getRect(ringAt(0));
      final Rect before = tester.getRect(find.text('Label Position Before...'));
      expect(before.right, lessThanOrEqualTo(beforeRing.left));
      expect(before.center.dy, closeTo(beforeRing.center.dy, 1));

      final Rect afterRing = tester.getRect(ringAt(1));
      final Rect after = tester.getRect(find.text('Label Position After...'));
      expect(after.left, greaterThanOrEqualTo(afterRing.right));
      expect(after.center.dy, closeTo(afterRing.center.dy, 1));

      final Rect aboveRing = tester.getRect(ringAt(2));
      final Rect above = tester.getRect(find.text('Label Position Above...'));
      expect(above.bottom, lessThanOrEqualTo(aboveRing.top));
      expect(above.center.dx, closeTo(aboveRing.center.dx, 1));

      final Rect belowRing = tester.getRect(ringAt(3));
      final Rect below = tester.getRect(find.text('Label Position Below...'));
      expect(below.top, greaterThanOrEqualTo(belowRing.bottom));
      expect(below.center.dx, closeTo(belowRing.center.dx, 1));
    });

    testWidgets('the gap is the same token on every axis', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Figma binds `Spacing/Horizontal/S` on all 64 variants, the vertical
      // layouts included — so a layout that reached for a vertical ramp on the
      // above/below cases would diverge from the file.
      expect(
        tester.getRect(ringAt(0)).left -
            tester.getRect(find.text('Label Position Before...')).right,
        closeTo(FluentSpacing.s, 0.01),
      );
      expect(
        tester.getRect(find.text('Label Position Below...')).top -
            tester.getRect(ringAt(3)).bottom,
        closeTo(FluentSpacing.s, 0.01),
      );
    });
  });

  group('size', () {
    final DocsSection section = sectionOf('components-spinner--size');

    testWidgets('the eight sizes are the eight diameters', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      const List<double> diameters = <double>[16, 20, 24, 28, 32, 36, 40, 44];
      expect(ringFinder(), findsNWidgets(diameters.length));
      for (int i = 0; i < diameters.length; i++) {
        expect(
          tester.getRect(ringAt(i)).size,
          Size.square(diameters[i]),
          reason: 'ring $i is not the diameter its size names',
        );
      }
    });

    testWidgets('size ramps the stroke and the type alongside the diameter', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Three things move on this one axis, and only the diameter is visible
      // in the layout: a size that reached the box but not the painter would
      // draw a 44px ring with a 2px hairline.
      const List<double> strokes = <double>[2, 2, 2, 2, 3, 3, 3, 4];
      final List<FluentSpinnerPainter> rings = painters(tester);
      for (int i = 0; i < strokes.length; i++) {
        expect(rings[i].strokeWidth, strokes[i], reason: 'ring $i stroke');
      }

      final FluentTypography type = themeOf(tester).typography;
      const List<String> labels = <String>[
        'Extra Tiny Spinner',
        'Tiny Spinner',
        'Extra Small Spinner',
        'Small Spinner',
        'Medium Spinner',
        'Large Spinner',
        'Extra Large Spinner',
        'Huge Spinner',
      ];
      final List<TextStyle> ramp = <TextStyle>[
        type.body1,
        type.body1,
        type.body1,
        type.body1,
        type.subtitle2,
        type.subtitle2,
        type.subtitle2,
        type.subtitle1,
      ];
      for (int i = 0; i < labels.length; i++) {
        expect(
          textStyleOf(tester, find.text(labels[i]))?.fontSize,
          ramp[i].fontSize,
          reason: '${labels[i]} took the wrong ramp stop',
        );
      }
      // Read off the theme rather than hard-coded, because the native ramps do
      // not order the way the web ones do — but they must still be three
      // *different* stops, or the ramp never reached the label.
      expect(ramp.map((TextStyle s) => s.fontSize).toSet(), hasLength(3));
    });
  });

  group('pointer', () {
    testWidgets('a real mouse over a spinner changes nothing but time', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-spinner--appearance'));

      final FluentSpinnerPainter resting = painters(tester).first;
      final Size size = tester.getRect(ringAt(0)).size;
      // A spinner is output, not a control: the Figma set carries no State
      // axis, so there is nothing to hover. The pose is exempt — it moves on
      // its own clock — but the colours and the geometry must not.
      final FluentSpinnerPainter hovered = await whileHovering(
        tester,
        ringAt(0),
        () => painters(tester).first,
      );
      expect(hovered.trackColor, resting.trackColor);
      expect(hovered.indicatorColor, resting.indicatorColor);
      expect(hovered.strokeWidth, resting.strokeWidth);
      expect(tester.getRect(ringAt(0)).size, size);

      // A press is not an interaction either: there is nothing to activate on
      // a spinner, so a real click must leave the ring exactly as it was.
      await mouseClick(tester, ringAt(0));
      expect(painters(tester).first.trackColor, resting.trackColor);
      expect(painters(tester).first.indicatorColor, resting.indicatorColor);
      expect(tester.getRect(ringAt(0)).size, size);
    });
  });

  group('lifecycle', () {
    testWidgets('every section unmounts without throwing', (
      WidgetTester tester,
    ) async {
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section);
        // Every spinner owns a repeating AnimationController, so a ticker that
        // outlived its element would surface here and nowhere else.
        await expectCleanTeardown(tester, section.id);
      }
    });
  });
}

/// Every spinner ring on the mounted section, in declaration order.
///
/// Matched on the painter rather than on `CustomPaint` alone: a label, a focus
/// ring or a scrollbar would all answer to the bare type.
Finder ringFinder() => find.byWidgetPredicate(
  (Widget widget) =>
      widget is CustomPaint && widget.painter is FluentSpinnerPainter,
  description: 'spinner ring',
);

/// The [index]-th ring on the mounted section.
Finder ringAt(int index) => ringFinder().at(index);

/// The painters actually drawing, in tree order.
List<FluentSpinnerPainter> painters(WidgetTester tester) =>
    paintersOf<FluentSpinnerPainter>(tester);

/// The theme the mounted section resolved against.
FluentThemeData themeOf(WidgetTester tester) =>
    FluentTheme.of(tester.element(find.byType(FluentSpinner).first));
