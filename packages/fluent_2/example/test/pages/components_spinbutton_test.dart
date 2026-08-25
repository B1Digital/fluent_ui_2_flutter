import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// SpinButton's page is ten demos of one control, so nearly every assertion
/// here reads the same two things at once: the number the field prints and the
/// value the demo's own state holds. They have to move together. A stepper that
/// reports through `onChanged` but leaves the old number in the field, or one
/// that re-seats the field without telling the demo, renders perfectly and is
/// still broken — which is exactly what `render_test` cannot see.
void main() {
  const String page = 'components-spinbutton';

  group('default', () {
    final DocsSection section = sectionOf('components-spinbutton--default');

    testWidgets('the steppers move the value and the field together', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder spin = find.byType(FluentSpinButton);
      expect(spin, findsOneWidget);
      expect(editedText(tester, spin), '10');

      // A real mouse on the primary affordance: the stepper is a bare
      // CustomPaint under a FluentInteractive, so a synthetic tap that lands on
      // the control's own opaque detector instead of the stepper's would only
      // move focus, and the value would sit still.
      await mouseClick(tester, stepper(spin, up));
      expect(tester.widget<FluentSpinButton>(spin).value, 11);
      expect(editedText(tester, spin), '11');

      await tapAndSettle(tester, stepper(spin, down), what: 'the down stepper');
      expect(
        tester.widget<FluentSpinButton>(spin).value,
        10,
        reason: 'one step down must land back on the seed value',
      );
      expect(editedText(tester, spin), '10');
    });

    testWidgets('unmounts cleanly', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('controlled', () {
    final DocsSection section = sectionOf('components-spinbutton--controlled');

    testWidgets('typing a number commits it through onChanged', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder spin = find.byType(FluentSpinButton);
      expect(tester.widget<FluentSpinButton>(spin).value, 10);

      await tester.enterText(spin, '42.7');
      await settle(tester);
      // The demo is only told about the value once the commit lands, so the
      // typed text must NOT have moved it yet — a control that reported on
      // every keystroke would fire `onChanged` with half-typed numbers.
      expect(tester.widget<FluentSpinButton>(spin).value, 10);

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester);
      expectClean(tester, 'committing a typed value');
      // step is 1, so precision is 0: the commit rounds before it reports.
      expect(tester.widget<FluentSpinButton>(spin).value, 43);
      expect(editedText(tester, spin), '43');
    });

    testWidgets('clearing the field reports a null value', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder spin = find.byType(FluentSpinButton);

      await tester.enterText(spin, '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester);
      expect(tester.widget<FluentSpinButton>(spin).value, isNull);
      expect(editedText(tester, spin), '');
    });

    testWidgets('unmounts cleanly', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('uncontrolled', () {
    final DocsSection section = sectionOf(
      'components-spinbutton--uncontrolled',
    );

    testWidgets('the demo owns the value the steppers move', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder spin = find.byType(FluentSpinButton);
      expect(editedText(tester, spin), '10');

      await tapAndSettle(tester, stepper(spin, up), what: 'the up stepper');
      expect(tester.widget<FluentSpinButton>(spin).value, 11);

      await tapAndSettle(tester, stepper(spin, down), what: 'the down stepper');
      expect(tester.widget<FluentSpinButton>(spin).value, 10);
    });

    testWidgets('unmounts cleanly', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('bounds', () {
    final DocsSection section = sectionOf('components-spinbutton--bounds');

    testWidgets('End jumps to max, Home jumps to min', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder spin = find.byType(FluentSpinButton);
      // The section prints its own bounds, so the demo is self-describing and
      // the numbers below are the ones a reader is promised.
      expect(find.text('min: 0, max: 20'), findsOneWidget);

      await tester.tap(spin);
      await settle(tester);

      // Home and End are bound above the field on purpose, so they must beat
      // the framework's own caret-to-line-end shortcut.
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await settle(tester);
      expect(tester.widget<FluentSpinButton>(spin).value, 20);
      expect(editedText(tester, spin), '20');

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await settle(tester);
      expect(tester.widget<FluentSpinButton>(spin).value, 0);
      expect(editedText(tester, spin), '0');
    });

    testWidgets('the steppers clamp at both ends of the range', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder spin = find.byType(FluentSpinButton);

      await tester.tap(spin);
      await settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await settle(tester);

      await tapAndSettle(tester, stepper(spin, up), what: 'the up stepper');
      expect(
        tester.widget<FluentSpinButton>(spin).value,
        20,
        reason: 'stepping past max must clamp, not run past the declared bound',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await settle(tester);
      await tapAndSettle(tester, stepper(spin, down), what: 'the down stepper');
      expect(tester.widget<FluentSpinButton>(spin).value, 0);
    });

    testWidgets('unmounts cleanly', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('display value', () {
    final DocsSection section = sectionOf(
      'components-spinbutton--display-value',
    );

    testWidgets('a step re-formats the display value, not just the number', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder spin = find.byType(FluentSpinButton);
      expect(editedText(tester, spin), r'$1');

      await mouseClick(tester, stepper(spin, up));
      expect(tester.widget<FluentSpinButton>(spin).value, 2);
      expect(
        editedText(tester, spin),
        r'$2',
        reason: 'the field must re-read the demo\'s formatter, not print "2"',
      );

      await tapAndSettle(tester, stepper(spin, down), what: 'the down stepper');
      expect(editedText(tester, spin), r'$1');
    });

    testWidgets('clearing the field shows the demo\'s null rendering', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder spin = find.byType(FluentSpinButton);

      await tester.enterText(spin, '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester);
      expect(tester.widget<FluentSpinButton>(spin).value, isNull);
      expect(editedText(tester, spin), '(null)');
    });

    testWidgets('unmounts cleanly', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('step', () {
    final DocsSection section = sectionOf('components-spinbutton--step');

    testWidgets('the stepper travels by step and Page keys by pageStep', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder spin = find.byType(FluentSpinButton);
      expect(editedText(tester, spin), '10');

      await mouseClick(tester, stepper(spin, up));
      expect(
        tester.widget<FluentSpinButton>(spin).value,
        12,
        reason: 'step is 2, so a single stepper press must not move by 1',
      );

      await tester.tap(spin);
      await settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await settle(tester);
      expect(
        tester.widget<FluentSpinButton>(spin).value,
        32,
        reason: 'pageStep is 20 — the section exists to demonstrate the jump',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await settle(tester);
      expect(tester.widget<FluentSpinButton>(spin).value, 12);
    });

    testWidgets('unmounts cleanly', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('size', () {
    final DocsSection section = sectionOf('components-spinbutton--size');

    testWidgets('small is shorter than medium', (WidgetTester tester) async {
      await pumpSection(tester, section);
      final Finder spin = find.byType(FluentSpinButton);
      expect(spin, findsNWidgets(2));

      expect(
        tester.getSize(spin.at(0)).height,
        lessThan(tester.getSize(spin.at(1)).height),
        reason: 'the size axis is the whole point of this section',
      );
    });

    testWidgets('each field steps on its own', (WidgetTester tester) async {
      await pumpSection(tester, section);
      final Finder spin = find.byType(FluentSpinButton);
      // Both start empty, so a shared value would be immediately visible as
      // the other field filling in too.
      expect(editedText(tester, spin.at(0)), '');
      expect(editedText(tester, spin.at(1)), '');

      await mouseClick(tester, stepper(spin.at(0), up));
      expect(editedText(tester, spin.at(0)), '1');
      expect(
        editedText(tester, spin.at(1)),
        '',
        reason: 'the demo keeps one value per row; they must not be shared',
      );
    });

    testWidgets('unmounts cleanly', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('appearance', () {
    final DocsSection section = sectionOf('components-spinbutton--appearance');

    testWidgets('the four appearances paint four different chromes', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder spin = find.byType(FluentSpinButton);
      expect(spin, findsNWidgets(4));

      // Declaration order: outline, underline, filled lighter, filled darker.
      expect(
        decorationUnder(tester, spin.at(0)).border,
        isNotNull,
        reason: 'outline is the only appearance with a box border',
      );
      expect(
        decorationUnder(tester, spin.at(1)).border,
        isNull,
        reason: 'underline is a bottom rule and nothing else',
      );
      expect(
        decorationUnder(tester, spin.at(2)).color,
        isNot(decorationUnder(tester, spin.at(3)).color),
        reason:
            'filled lighter and filled darker differ only in fill, so an '
            'appearance the resolver ignored would make them identical',
      );
    });

    testWidgets('each appearance steps its own value', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder spin = find.byType(FluentSpinButton);

      await mouseClick(tester, stepper(spin.at(1), up));
      expect(editedText(tester, spin.at(1)), '1');
      for (final int other in <int>[0, 2, 3]) {
        expect(
          editedText(tester, spin.at(other)),
          '',
          reason: 'the demo keys its values by appearance; row $other moved',
        );
      }
    });

    testWidgets('unmounts cleanly', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('disabled', () {
    final DocsSection section = sectionOf('components-spinbutton--disabled');

    testWidgets('both steppers are inert', (WidgetTester tester) async {
      await pumpSection(tester, section);
      final Finder spin = find.byType(FluentSpinButton);
      expect(tester.widget<FluentSpinButton>(spin).onChanged, isNull);

      await tapAndSettle(tester, stepper(spin, up), what: 'the up stepper');
      await tapAndSettle(tester, stepper(spin, down), what: 'the down stepper');
      expect(
        editedText(tester, spin),
        '',
        reason: 'a disabled spin button must not step',
      );
    });

    testWidgets('unmounts cleanly', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('read only', () {
    final DocsSection section = sectionOf('components-spinbutton--read-only');

    testWidgets('takes focus but refuses to change', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder spin = find.byType(FluentSpinButton);
      // The whole distinction the section draws is disabled-versus-read-only:
      // the handler stays wired, so the control is still focusable.
      expect(tester.widget<FluentSpinButton>(spin).onChanged, isNotNull);

      await tester.tap(spin);
      await settle(tester);
      expect(
        tester.widget<EditableText>(editable(spin)).focusNode.hasFocus,
        isTrue,
        reason: 'read-only must still be reachable by assistive technology',
      );

      await mouseClick(tester, stepper(spin, up));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await settle(tester);
      expect(
        editedText(tester, spin),
        '',
        reason:
            'neither the stepper nor the arrow keys may edit a read-only '
            'value',
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

/// The increase half of a stepper column.
const FluentSpinButtonStepperDirection up =
    FluentSpinButtonStepperDirection.increase;

/// The decrease half of a stepper column.
const FluentSpinButtonStepperDirection down =
    FluentSpinButtonStepperDirection.decrease;

/// The [direction] half of the stepper column belonging to [spinButton].
///
/// Matched on the widget rather than on semantics: the column is wrapped in
/// `ExcludeSemantics`, because the control already publishes increase and
/// decrease actions of its own.
Finder stepper(Finder spinButton, FluentSpinButtonStepperDirection direction) =>
    find.descendant(
      of: spinButton,
      matching: find.byWidgetPredicate(
        (Widget widget) =>
            widget is FluentSpinButtonStepper && widget.direction == direction,
      ),
    );

/// The editable inside [spinButton].
Finder editable(Finder spinButton) =>
    find.descendant(of: spinButton, matching: find.byType(EditableText));
