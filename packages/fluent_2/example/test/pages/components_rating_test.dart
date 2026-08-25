import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Rating draws its whole row — five shapes, their half fills, the gaps — with
/// a single [FluentRatingPainter], so nothing about what a reader actually sees
/// is on the widget tree. Every assertion here therefore reads the painter's
/// own fills and tokens rather than the `value` the demo happens to hold: a
/// rating that reports 4 through `onChanged` and paints three stars is a real
/// failure mode, and it is invisible to a suite that only checks the value.
void main() {
  const String page = 'components-rating';

  group('default', () {
    final DocsSection section = sectionOf('components-rating--default');

    testWidgets('a click fills up to the shape under the pointer', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder rating = find.byType(FluentRating);
      expect(fills(tester, rating), <double>[0, 0, 0, 0, 0]);

      // The centre of the painted row is the middle of the third shape, so a
      // real mouse click there commits 3. Clicking rather than tapping matters:
      // the value is captured by a Listener on pointer-down and committed by a
      // separate tap recogniser, so a press the arena never resolves would
      // leave the demo untouched.
      await mouseClick(tester, row(rating));
      expect(tester.widget<FluentRating>(rating).value, 3);
      expect(fills(tester, rating), <double>[1, 1, 1, 0, 0]);

      await mouseClickAt(
        tester,
        shapePoint(tester, rating, 0),
        what: 'shape 1',
      );
      expect(fills(tester, rating), <double>[1, 0, 0, 0, 0]);
    });

    testWidgets('hovering previews without committing', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder rating = find.byType(FluentRating);

      final TestGesture mouse = await mouseHover(tester, row(rating));
      expect(
        fills(tester, rating),
        <double>[1, 1, 1, 0, 0],
        reason: 'the shapes under the pointer must preview the value',
      );
      expect(
        tester.widget<FluentRating>(rating).value,
        0,
        reason: 'a preview is not a commit — nothing was pressed',
      );

      await mouseAway(tester, mouse);
      expect(
        fills(tester, rating),
        <double>[0, 0, 0, 0, 0],
        reason: 'the preview must be given back when the pointer leaves',
      );
    });

    testWidgets('a hover previews exactly what a click there commits', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder rating = find.byType(FluentRating);

      // Hover and press are two readings of the same pointer position, so
      // whatever the row previews under the cursor is the only thing a click
      // in that spot is allowed to leave behind. This section hands
      // `FluentRating` straight to the page, so it takes the whole content
      // width while the shapes it paints are ~148 wide, and the centre of the
      // control is empty space well past the last one.
      final TestGesture mouse = await mouseHover(tester, rating);
      final List<double> previewed = fills(tester, rating);
      await mouseAway(tester, mouse);

      await mouseClick(tester, rating);
      expect(
        previewed,
        fills(tester, rating),
        reason:
            'the pointer previewed one rating and committed another: a reader '
            'is shown five filled shapes and gets none of them',
      );
    });

    testWidgets('the arrow keys move the value one step each way', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder rating = find.byType(FluentRating);
      await mouseClick(tester, row(rating));
      expect(tester.widget<FluentRating>(rating).value, 3);

      focus(tester, rating);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await settle(tester);
      expect(fills(tester, rating), <double>[1, 1, 0, 0, 0]);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await settle(tester);
      expect(
        fills(tester, rating),
        <double>[1, 1, 1, 0, 0],
        reason: 'right after left must land back where it started',
      );
    });

    testWidgets('unmounts cleanly', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('controlled value', () {
    final DocsSection section = sectionOf(
      'components-rating--controlled-value',
    );

    testWidgets('Clear Rating empties the row and a click refills it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder rating = find.byType(FluentRating);
      expect(fills(tester, rating), <double>[1, 1, 1, 1, 0]);

      await mouseClick(tester, find.text('Clear Rating'));
      expect(
        fills(tester, rating),
        <double>[0, 0, 0, 0, 0],
        reason: 'the button the section ships must actually clear the row',
      );
      expect(tester.widget<FluentRating>(rating).value, 0);

      await mouseClickAt(
        tester,
        shapePoint(tester, rating, 3),
        what: 'shape 4',
      );
      expect(fills(tester, rating), <double>[
        1,
        1,
        1,
        1,
        0,
      ], reason: 'a cleared rating must still take input');
    });

    testWidgets('unmounts cleanly', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('step', () {
    final DocsSection section = sectionOf('components-rating--step');

    testWidgets('the left half of a shape commits a half value', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder rating = find.byType(FluentRating);
      expect(fills(tester, rating), <double>[1, 1, 1, 0.5, 0]);

      // A quarter of the way into the fifth shape: `step: 0.5` is the only
      // reason this is 4.5 rather than 5, so a step the control ignored shows
      // up as a whole shape filling.
      await mouseClickAt(
        tester,
        shapePoint(tester, rating, 4, within: 0.25),
        what: 'the left half of shape 5',
      );
      expect(tester.widget<FluentRating>(rating).value, 4.5);
      expect(fills(tester, rating), <double>[1, 1, 1, 1, 0.5]);

      await mouseClickAt(
        tester,
        shapePoint(tester, rating, 4, within: 0.75),
        what: 'the right half of shape 5',
      );
      expect(fills(tester, rating), <double>[1, 1, 1, 1, 1]);
    });

    testWidgets('the arrow keys move by the half step too', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder rating = find.byType(FluentRating);

      focus(tester, rating);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await settle(tester);
      expect(
        tester.widget<FluentRating>(rating).value,
        4,
        reason: 'a half-step rating must step by 0.5, not by 1',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await settle(tester);
      expect(tester.widget<FluentRating>(rating).value, 3.5);
    });

    testWidgets('unmounts cleanly', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('max', () {
    final DocsSection section = sectionOf('components-rating--max');

    testWidgets('ten shapes are drawn and the tenth is reachable', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder rating = find.byType(FluentRating);
      final FluentRatingPainter painted = painter(tester, rating);
      expect(
        painted.fills.length,
        10,
        reason: 'max is the number of shapes, so it has to reach the painter',
      );
      expect(painted.fills, <double>[1, 1, 1, 1, 1, 0, 0, 0, 0, 0]);
      expect(
        tester.getSize(row(rating)).width,
        closeTo(10 * painted.itemSize + 9 * painted.gap, 0.01),
        reason: 'the row must be as wide as the ten shapes it holds',
      );

      await mouseClickAt(
        tester,
        shapePoint(tester, rating, 9),
        what: 'shape 10',
      );
      expect(tester.widget<FluentRating>(rating).value, 10);
      expect(fills(tester, rating), List<double>.filled(10, 1));
    });

    testWidgets('unmounts cleanly', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('size', () {
    final DocsSection section = sectionOf('components-rating--size');

    testWidgets('the four sizes draw four different shape boxes', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder rating = find.byType(FluentRating);
      expect(rating, findsNWidgets(4));

      final List<double> boxes = <double>[
        for (int i = 0; i < 4; i++) painter(tester, rating.at(i)).itemSize,
      ];
      // Declaration order is small, medium, large, extra large.
      for (int i = 1; i < boxes.length; i++) {
        expect(
          boxes[i],
          greaterThan(boxes[i - 1]),
          reason: 'row $i must be drawn larger than row ${i - 1}',
        );
      }
      expect(
        tester.getSize(row(rating.at(0))).width,
        lessThan(tester.getSize(row(rating.at(3))).width),
      );
    });

    testWidgets('each row keeps its own value', (WidgetTester tester) async {
      await pumpSection(tester, section);
      final Finder rating = find.byType(FluentRating);

      await mouseClickAt(
        tester,
        shapePoint(tester, rating.at(1), 4),
        what: 'the last shape of the medium row',
      );
      expect(fills(tester, rating.at(1)), <double>[1, 1, 1, 1, 1]);
      for (final int other in <int>[0, 2, 3]) {
        expect(
          fills(tester, rating.at(other)),
          <double>[1, 1, 1, 0, 0],
          reason: 'the demo keeps one value per row; row $other moved too',
        );
      }
    });

    testWidgets('unmounts cleanly', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('color', () {
    final DocsSection section = sectionOf('components-rating--color');

    testWidgets('neutral, brand and marigold resolve three different tones', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder rating = find.byType(FluentRating);
      expect(rating, findsNWidgets(3));

      final List<Color?> tones = <Color?>[
        for (int i = 0; i < 3; i++) painter(tester, rating.at(i)).selected,
      ];
      expect(
        tones.toSet(),
        hasLength(3),
        reason:
            'the colour axis is the whole section — two rows sharing a tone '
            'means the prop never reached the style resolver',
      );
    });

    testWidgets('each row keeps its own value', (WidgetTester tester) async {
      await pumpSection(tester, section);
      final Finder rating = find.byType(FluentRating);

      await mouseClickAt(
        tester,
        shapePoint(tester, rating.at(2), 0),
        what: 'the first shape of the marigold row',
      );
      expect(fills(tester, rating.at(2)), <double>[1, 0, 0, 0, 0]);
      expect(fills(tester, rating.at(0)), <double>[1, 1, 1, 0, 0]);
      expect(fills(tester, rating.at(1)), <double>[1, 1, 1, 0, 0]);
    });

    testWidgets('unmounts cleanly', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('shape', () {
    final DocsSection section = sectionOf('components-rating--shape');

    testWidgets('the two rows draw two different silhouettes', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder rating = find.byType(FluentRating);
      expect(rating, findsNWidgets(2));

      expect(painter(tester, rating.at(0)).shape, FluentRatingShape.circle);
      expect(painter(tester, rating.at(1)).shape, FluentRatingShape.square);
    });

    testWidgets('both rows take half values independently', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder rating = find.byType(FluentRating);
      expect(fills(tester, rating.at(0)), <double>[0, 0, 0, 0, 0]);

      await mouseClickAt(
        tester,
        shapePoint(tester, rating.at(0), 0, within: 0.25),
        what: 'the left half of the first circle',
      );
      expect(fills(tester, rating.at(0)), <double>[
        0.5,
        0,
        0,
        0,
        0,
      ], reason: 'this row is built with step 0.5');
      expect(
        fills(tester, rating.at(1)),
        <double>[0, 0, 0, 0, 0],
        reason: 'the square row has its own value and must not follow',
      );
    });

    testWidgets('unmounts cleanly', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('lifecycle', () {
    testWidgets('every section mounts and unmounts without throwing', (
      WidgetTester tester,
    ) async {
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section);
        await expectCleanTeardown(tester, section.id);
      }
    });
  });
}

/// The painter that drew the first rating under [rating].
FluentRatingPainter painter(WidgetTester tester, Finder rating) =>
    paintersOf<FluentRatingPainter>(tester, rating).first;

/// How full each shape of [rating] is: 0, 0.5 or 1, in row order.
List<double> fills(WidgetTester tester, Finder rating) =>
    painter(tester, rating).fills;

/// The box the row of shapes occupies.
///
/// Scoped to the painted [CustomPaint] rather than to the `FluentRating`
/// element: the control's own box is a `Stack` with `clipBehavior: none` whose
/// focus ring is allowed to sit outside it.
Finder row(Finder rating) => find.descendant(
  of: rating,
  matching: find.byWidgetPredicate(
    (Widget widget) =>
        widget is CustomPaint && widget.painter is FluentRatingPainter,
  ),
);

/// A point inside shape [index] of [rating], [within] of the way across it.
///
/// Rating is one hit target for the whole row — which shape a press lands on is
/// decided from the offset — so a click has to be aimed, not centred. [within]
/// below 0.5 is the half-value side of a `step: 0.5` shape.
Offset shapePoint(
  WidgetTester tester,
  Finder rating,
  int index, {
  double within = 0.5,
}) {
  final FluentRatingPainter painted = painter(tester, rating);
  final Rect box = tester.getRect(row(rating).first);
  return box.topLeft +
      Offset(
        index * (painted.itemSize + painted.gap) + painted.itemSize * within,
        box.height / 2,
      );
}

/// Gives [rating] keyboard focus.
///
/// Fluent deliberately does not focus a control on click — `FluentInteractive`
/// calls `onPressed` and nothing else — so the arrow keys are only reachable
/// through the node the control published.
void focus(WidgetTester tester, Finder rating) => tester
    .widget<FocusableActionDetector>(
      find
          .descendant(
            of: rating,
            matching: find.byType(FocusableActionDetector),
          )
          .first,
    )
    .focusNode!
    .requestFocus();
