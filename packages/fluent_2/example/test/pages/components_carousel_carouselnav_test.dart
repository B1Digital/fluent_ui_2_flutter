import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// CarouselNav is one section with two things in it that have to move: a switch
/// that swaps every dot for a thumbnail, and five steps that own the selection
/// between them.
///
/// Both are easy to get almost right. A step's hit target is 24x24 whether or
/// not it is selected — Fluent keeps the target constant and grows the *mark*
/// inside it — so "the button changed size" is not available as a signal and
/// every assertion here reads the mark itself. And the selected step is the
/// only one carrying a `style` override, so a selection that moved the flag
/// without moving the tint would still look selected in the widget tree and
/// wrong on the screen.
void main() {
  const String page = 'components-carousel-carouselnav';
  final DocsSection section = sectionOf(
    'components-carousel-carouselnav--default',
  );

  /// The dot or pill [step] is drawing, or null when it is showing a thumbnail.
  ///
  /// A step is two decorated boxes deep: the button surface, rounded to
  /// `FluentRadius.allMedium`, and the mark inside it, rounded fully. The radius
  /// is what tells them apart without reaching into either private widget, and
  /// with a preview the mark is an image and there is no fully rounded box at
  /// all.
  ({Size size, Color? color})? markOf(WidgetTester tester, Finder step) {
    final Finder boxes = find.descendant(
      of: step,
      matching: find.byType(DecoratedBox),
    );
    for (int i = 0; i < boxes.evaluate().length; i++) {
      final BoxDecoration decoration =
          tester.widget<DecoratedBox>(boxes.at(i)).decoration as BoxDecoration;
      if (decoration.borderRadius == FluentRadius.allCircular) {
        return (size: tester.getSize(boxes.at(i)), color: decoration.color);
      }
    }
    return null;
  }

  /// The index of the step that currently holds focus, or null.
  ///
  /// Read by walking up from the focus node rather than by comparing focus
  /// nodes: the node belongs to the `FluentButton` a step composes, several
  /// elements below the step itself, and the semantic label is the only thing
  /// on the way up that says which one this is.
  int? focusedStep(WidgetTester tester) {
    final Element? focused = primaryFocus?.context as Element?;
    if (focused == null) return null;
    String? label;
    focused.visitAncestorElements((Element element) {
      if (element.widget is FluentCarouselStep) {
        label = (element.widget as FluentCarouselStep).semanticLabel;
        return false;
      }
      return true;
    });
    return label == null ? null : int.tryParse(label!.split(' ').last);
  }

  /// Which of the five steps is currently drawing the wide pill.
  ///
  /// Returned as a list rather than an index so a demo that lit two steps — or
  /// none — fails on the count instead of quietly reporting the first.
  List<int> selected(WidgetTester tester) => <int>[
    for (int i = 0; i < 5; i++)
      if (markOf(tester, find.byType(FluentCarouselStep).at(i))!.size.width > 8)
        i,
  ];

  group('image button switch', () {
    testWidgets('it swaps every dot for a thumbnail, and back again', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder steps = find.byType(FluentCarouselStep);
      expect(steps, findsNWidgets(5));
      expect(find.text('CarouselNavImageButton'), findsOneWidget);
      expect(markOf(tester, steps.at(1))!.size, const Size(8, 8));
      expect(find.byType(Image), findsNothing);

      final Finder toggle = find.byType(FluentSwitch);
      await tapAndSettle(tester, toggle, what: 'the image button switch');

      // The switch's own `checked` moving proves nothing: what it claims is
      // that every step swaps its dot for a 40 thumbnail — and the selected one
      // for a 48.
      expect(tester.widget<FluentSwitch>(toggle).checked, isTrue);
      expect(find.byType(Image), findsNWidgets(5));
      expect(markOf(tester, steps.at(1)), isNull);
      expect(tester.getSize(steps.at(1)), const Size(40, 40));
      expect(tester.getSize(steps.at(0)), const Size(48, 48));

      await tapAndSettle(tester, toggle, what: 'the image button switch');
      expect(tester.widget<FluentSwitch>(toggle).checked, isFalse);
      expect(find.byType(Image), findsNothing);
      expect(
        markOf(tester, steps.at(1))!.size,
        const Size(8, 8),
        reason: 'turning the switch back must restore the dot strip',
      );

      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('it commits under a real mouse', (WidgetTester tester) async {
      await pumpSection(tester, section);

      // The two pixels of travel between press and release are the point: a
      // scrollable that claimed the mouse as a drag device would swallow the
      // click, and this page's only knob would be dead to every pointer user
      // while passing every synthetic tap.
      await mouseClick(tester, find.byType(FluentSwitch));
      expect(
        tester.widget<FluentSwitch>(find.byType(FluentSwitch)).checked,
        isTrue,
      );
      expect(find.byType(Image), findsNWidgets(5));
    });
  });

  group('steps', () {
    testWidgets('pressing a step moves the selection onto it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder steps = find.byType(FluentCarouselStep);
      expect(selected(tester), <int>[0]);

      await tapAndSettle(tester, steps.at(3), what: 'the fourth step');

      // Exclusive, and both halves of the swap: the pressed step grows into the
      // pill and the one that had it shrinks back. A demo that only ever added
      // to `_index` would light two.
      expect(selected(tester), <int>[3]);
      expect(markOf(tester, steps.at(3))!.size, const Size(16, 8));
      expect(markOf(tester, steps.at(0))!.size, const Size(8, 8));

      await tapAndSettle(tester, steps.at(0), what: 'the first step');
      expect(selected(tester), <int>[
        0,
      ], reason: 'the selection must be able to come back');

      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('the selected step takes the brand tint and the rest do not', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder steps = find.byType(FluentCarouselStep);
      final FluentColors colors = FluentTheme.of(
        tester.element(steps.first),
      ).colors;

      // `appearance="brand"` has no Dart axis, so the demo tints the selected
      // step through `FluentCarouselStyle.stepColor`. That override reaches the
      // mark through the button's IconTheme — several hops — and a step that
      // grew the pill without taking the tint is the failure that leaves.
      expect(markOf(tester, steps.at(0))!.color, colors.brandBackground);
      for (int i = 1; i < 5; i++) {
        expect(
          markOf(tester, steps.at(i))!.color,
          colors.neutralForeground2,
          reason: 'step $i is not the selected one and must stay neutral',
        );
      }

      await tapAndSettle(tester, steps.at(2), what: 'the third step');
      expect(markOf(tester, steps.at(2))!.color, colors.brandBackground);
      expect(markOf(tester, steps.at(0))!.color, colors.neutralForeground2);
    });

    testWidgets('a real mouse press selects a step too', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await mouseClick(tester, find.byType(FluentCarouselStep).at(4));
      expect(selected(tester), <int>[4]);
    });

    testWidgets('a resting pointer ramps the step it is over', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder steps = find.byType(FluentCarouselStep);
      final FluentColors colors = FluentTheme.of(
        tester.element(steps.first),
      ).colors;
      expect(markOf(tester, steps.at(2))!.color, colors.neutralForeground2);

      // The step tracks no state of its own — the mark reads whatever the
      // button's IconTheme resolved — so hover is the one axis that cannot be
      // reached with `tester.tap`, and an unreachable hover is a strip that
      // gives no feedback at all under a pointer.
      final TestGesture mouse = await mouseHover(tester, steps.at(2));
      expect(
        markOf(tester, steps.at(2))!.color,
        colors.neutralForeground2Hover,
        reason: 'the mark must ramp while the pointer rests on it',
      );
      expect(
        markOf(tester, steps.at(3))!.color,
        colors.neutralForeground2,
        reason: 'only the step under the pointer may ramp',
      );

      await mouseAway(tester, mouse);
      expect(markOf(tester, steps.at(2))!.color, colors.neutralForeground2);
    });

    testWidgets('Tab walks the strip and Space activates a step', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The props table promises activation "on tap and on Space or Enter", and
      // the strip is the whole of this page's navigation — a pagination that
      // only answers a mouse is unusable without one. Tab order matters as much
      // as the key: the steps must come in reading order, not in whatever order
      // the Stack painted them.
      for (int i = 0; i < 10 && focusedStep(tester) != 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await settle(tester);
      }
      expect(focusedStep(tester), 3, reason: 'Tab must reach the fourth step');

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await settle(tester);
      expect(selected(tester), <int>[3]);
    });

    testWidgets('the selection survives the swap to image buttons', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder steps = find.byType(FluentCarouselStep);
      await tapAndSettle(tester, steps.at(2), what: 'the third step');
      await tapAndSettle(tester, find.byType(FluentSwitch), what: 'the switch');

      // The two knobs share one State. Rebuilding the strip with previews must
      // not reset `_index` — a pagination that jumped back to slide one every
      // time the indicator style changed would be a real defect, and the only
      // visible trace of it is which thumbnail is the big one.
      expect(tester.getSize(steps.at(2)), const Size(48, 48));
      expect(tester.getSize(steps.at(0)), const Size(40, 40));

      await tapAndSettle(tester, steps.at(4), what: 'the fifth thumbnail');
      expect(
        tester.getSize(steps.at(4)),
        const Size(48, 48),
        reason: 'a thumbnail must be pressable, not just decorative',
      );
      expect(tester.getSize(steps.at(2)), const Size(40, 40));
    });
  });

  group('lifecycle', () {
    testWidgets('every section unmounts without throwing', (
      WidgetTester tester,
    ) async {
      for (final DocsSection each in sectionsOf(page)) {
        await pumpSection(tester, each);
        await expectCleanTeardown(tester, each.id);
      }
    });
  });
}
