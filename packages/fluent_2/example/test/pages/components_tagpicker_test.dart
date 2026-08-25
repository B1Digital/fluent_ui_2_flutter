import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// TagPicker is thirteen demos of one control, and every one of them is a
/// promise that a list of employees can be turned into chips. So the shape of
/// this suite is: prove the popup opens, prove picking a row commits a chip,
/// prove removing a chip gives the row back — and then prove that each
/// section's own axis (size, appearance, grouping, truncation, single-select,
/// the secondary action) changes what is on screen rather than only what is in
/// a constructor.
void main() {
  const String page = 'components-tagpicker';

  group('default', () {
    final DocsSection section = sectionOf('components-tagpicker--default');

    testWidgets('the popup lists the employees and a pick commits a chip', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.byType(FluentInteractionTag), findsNothing);

      await openPopup(tester);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Maria Rossi'), findsOneWidget);

      await tapAndSettle(tester, find.text('Jane Doe').last, what: 'a row');
      // The popup closed with the commit, so nothing but the chip is left.
      expect(find.text('John Doe'), findsNothing);
      expect(find.byType(FluentInteractionTag), findsOneWidget);
      expect(find.text('Jane Doe'), findsOneWidget);

      await openPopup(tester);
      expect(find.text('John Doe'), findsOneWidget);
      // Still one: a chosen value leaves the list rather than appearing twice.
      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.byType(FluentInteractionTag), findsOneWidget);
    });

    // The regression this page cares about most: the control's tap used to
    // only call `_focusNode.requestFocus`, so a pointer could focus the picker
    // but never open its popup — and the field's own selection gestures win
    // the arena over any ancestor tap, so the click never even got that far.
    // Every section on this page is "choose an employee from the list", and
    // with a mouse there was no list.
    testWidgets('a real mouse click opens the option list', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await mouseClick(tester, find.byType(FluentTagPicker<String>));
      expect(
        find.text('John Doe'),
        findsOneWidget,
        reason:
            'clicking the control is the only way a pointer user has of '
            'reaching the list this page is entirely about',
      );
    });

    testWidgets("a chip's dismiss half puts its option back on the list", (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await openPopup(tester);
      await tapAndSettle(tester, find.text('Jane Doe').last, what: 'a row');
      expect(find.byType(FluentInteractionTag), findsOneWidget);

      await tapAndSettle(
        tester,
        find.byType(FluentTagDismissGlyph),
        what: "the chip's dismiss half",
      );
      expect(find.byType(FluentInteractionTag), findsNothing);

      await openPopup(tester);
      expect(
        find.text('Jane Doe'),
        findsOneWidget,
        reason: 'removing a chip has to hand its option back to the popup',
      );
    });

    testWidgets('backspace on an empty field removes the last chip', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      for (final String name in <String>['John Doe', 'Jane Doe']) {
        await openPopup(tester);
        await tapAndSettle(tester, find.text(name).last, what: 'the $name row');
      }
      expect(find.byType(FluentInteractionTag), findsNWidgets(2));

      // Documented keyboard behaviour, and the only chip removal that needs no
      // pointer at all.
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await settle(tester);
      expect(find.byType(FluentInteractionTag), findsOneWidget);
      expect(find.text('Jane Doe'), findsNothing);
      expect(find.text('John Doe'), findsOneWidget);
    });
  });

  group('button', () {
    testWidgets('the button demo picks like the ordinary control it is', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-tagpicker--button'));

      await openPopup(tester);
      await tapAndSettle(
        tester,
        find.text('Pierre Dupont').last,
        what: 'a row',
      );
      expect(find.byType(FluentInteractionTag), findsOneWidget);
      expect(find.text('Pierre Dupont'), findsOneWidget);
    });
  });

  group('filtering', () {
    final DocsSection section = sectionOf('components-tagpicker--filtering');

    testWidgets('a query narrows the list, and clearing it restores', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await tester.enterText(_field(), 'mario');
      await settle(tester);
      // No tap first: `enterText` focuses the field, and the list is rebuilt
      // from the query on the way in, so opening now is what shows the filter.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await settle(tester);
      expect(find.text('Mario Rossi'), findsOneWidget);
      expect(
        find.text('Maria Rossi'),
        findsNothing,
        reason: 'the filter is a contains() over the name, not a fuzzy match',
      );
      expect(find.text('John Doe'), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle(tester);
      await tester.enterText(_field(), '');
      await settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await settle(tester);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Mario Rossi'), findsOneWidget);
    });

    testWidgets('a query with no matches says so, and offers nothing to pick', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await tester.enterText(_field(), 'zzz');
      await settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await settle(tester);

      expect(find.text("We couldn't find any matches"), findsOneWidget);
      // The message row is disabled, so committing the active option cannot
      // turn the apology itself into a chip.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settle(tester);
      expect(find.byType(FluentInteractionTag), findsNothing);
    });
  });

  group('size', () {
    testWidgets('each control takes its documented height and chip ramp', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-tagpicker--size'));

      final Finder pickers = find.byType(FluentTagPicker<String>);
      expect(pickers, findsNWidgets(3));
      // Declared extra-large first, and the chip ramp moves with the control:
      // medium picks a small tag, the two taller ones a medium tag.
      for (final (int index, double height, double chip)
          in <(int, double, double)>[(0, 48, 32), (1, 40, 32), (2, 32, 24)]) {
        expect(
          tester.getSize(pickers.at(index)).height,
          height,
          reason: 'control $index',
        );
        expect(
          tester
              .getSize(
                find.descendant(
                  of: pickers.at(index),
                  matching: find.byType(FluentInteractionTag),
                ),
              )
              .height,
          chip,
          reason: 'chip in control $index',
        );
      }
    });
  });

  group('appearance', () {
    testWidgets('each appearance paints its own fill and border', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-tagpicker--appearance'));

      final Finder pickers = find.byType(FluentTagPicker<String>);
      expect(pickers, findsNWidgets(4));
      final FluentThemeData theme = FluentTheme.of(
        tester.element(pickers.first),
      );
      final BoxDecoration outline = fillOf(tester, pickers.at(0))!;
      final BoxDecoration underline = fillOf(tester, pickers.at(1))!;
      final BoxDecoration filledDarker = fillOf(tester, pickers.at(2))!;
      final BoxDecoration filledLighter = fillOf(tester, pickers.at(3))!;

      // Outline is the only one with a box border; the underline variant has
      // no box at all, only the bottom rule every non-filled appearance keeps.
      expect(outline.color, theme.colors.neutralBackground1);
      expect(
        (outline.border! as Border).top.color,
        theme.colors.neutralStroke1,
      );
      expect(underline.color, theme.colors.transparentBackground);
      expect(underline.border, isNull);
      expect(filledDarker.color, theme.colors.neutralBackground3);
      expect(filledLighter.color, theme.colors.neutralBackground1);
      // Invisible in light and dark, opaque in high contrast — never absent,
      // or a filled control would vanish into the surface there.
      for (final BoxDecoration box in <BoxDecoration>[
        filledDarker,
        filledLighter,
      ]) {
        expect(
          (box.border! as Border).top.color,
          theme.colors.transparentStrokeInteractive,
        );
      }
    });
  });

  group('disabled', () {
    testWidgets('a disabled picker keeps its chips and refuses everything', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-tagpicker--disabled'));

      final Finder picker = find.byType(FluentTagPicker<String>);
      final FluentThemeData theme = FluentTheme.of(tester.element(picker));
      expect(find.byType(FluentInteractionTag), findsNWidgets(4));
      expect(
        fillOf(tester, picker)!.color,
        theme.colors.neutralBackgroundDisabled,
      );
      // Disabling drops the dismiss half rather than greying it: there is no
      // `onChanged` to report a removal to.
      expect(find.byType(FluentTagDismissGlyph), findsNothing);
      // `::after { content: unset }` — a disabled control has no accent bar at
      // all, not a hidden one.
      expect(find.byType(FluentInputFocusUnderline), findsNothing);

      await tester.tap(picker, warnIfMissed: false);
      await settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await settle(tester);
      expect(
        find.text('Pierre Dupont'),
        findsNothing,
        reason: 'a disabled picker must never open its popup',
      );
      expectClean(tester, 'driving the disabled picker');
    });
  });

  group('expand icon', () {
    testWidgets('the chevron rides in the trailing slot', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-tagpicker--expand-icon'));

      final Finder icon = find.byType(Icon);
      expect(tester.widget<Icon>(icon).icon, FluentIcons.arrow_down_20_filled);
      // Trailing, past the chip: `secondaryAction` is the only slot on the
      // control that sits after the wrapping strip.
      expect(
        tester.getRect(icon).left,
        greaterThan(tester.getRect(find.byType(FluentInteractionTag)).right),
      );
    });
  });

  group('secondary action', () {
    testWidgets('All Clear empties the picker and it keeps working after', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-tagpicker--secondary-action'),
      );
      expect(find.byType(FluentInteractionTag), findsOneWidget);

      await mouseClick(tester, find.text('All Clear'));
      expect(
        find.byType(FluentInteractionTag),
        findsNothing,
        reason: 'the secondary action has to clear the selection it names',
      );

      await openPopup(tester);
      await tapAndSettle(tester, find.text('Jane Doe').last, what: 'a row');
      expect(find.byType(FluentInteractionTag), findsOneWidget);
      expect(find.text('Jane Doe'), findsOneWidget);
    });
  });

  group('grouped', () {
    testWidgets('the headers name their groups and leave when emptied', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-tagpicker--grouped'));

      await openPopup(tester);
      expect(find.text('Managers'), findsOneWidget);
      expect(find.text('Devs'), findsOneWidget);

      const List<String> managers = <String>[
        'John Doe',
        'Jane Doe',
        'Max Mustermann',
        'Erika Mustermann',
      ];
      for (final String name in managers) {
        // Committing closes the popup, so each pick needs its own open.
        await openPopup(tester);
        await tapAndSettle(tester, find.text(name).last, what: 'the $name row');
      }
      expect(find.byType(FluentInteractionTag), findsNWidgets(4));

      await openPopup(tester);
      expect(
        find.text('Managers'),
        findsNothing,
        reason: 'a header with nothing left under it must not render',
      );
      expect(find.text('Devs'), findsOneWidget);
    });
  });

  group('truncated text', () {
    testWidgets('both truncation strategies clamp their chip', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-tagpicker--truncated-text'),
      );
      expect(find.byType(FluentInteractionTag), findsNWidgets(9));

      expect(
        tester
            .getSize(
              find.text(
                'This tag has text truncation based on a fixed width of 50px',
              ),
            )
            .width,
        lessThanOrEqualTo(50),
      );
      expect(
        tester
            .getSize(
              find.textContaining('truncation based on its container width'),
            )
            .width,
        lessThanOrEqualTo(240),
      );
      // Every chip still fits inside the 400-wide control: a label that ignored
      // its bound would overflow the field rather than ellipsise.
      final double right = tester
          .getRect(find.byType(FluentTagPicker<String>))
          .right;
      for (int i = 0; i < 9; i++) {
        expect(
          tester.getRect(find.byType(FluentInteractionTag).at(i)).right,
          lessThanOrEqualTo(right),
          reason: 'chip $i',
        );
      }
    });
  });

  group('single select', () {
    testWidgets('a second pick replaces the first chip', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-tagpicker--single-select'),
      );

      await openPopup(tester);
      await tapAndSettle(tester, find.text('John Doe').last, what: 'a row');
      expect(find.byType(FluentInteractionTag), findsOneWidget);

      await openPopup(tester);
      await tapAndSettle(tester, find.text('Jane Doe').last, what: 'a row');
      expect(
        find.byType(FluentInteractionTag),
        findsOneWidget,
        reason: 'this demo keeps only the value that was just added',
      );
      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('John Doe'), findsNothing);
    });
  });

  group('no popover', () {
    testWidgets('Enter turns the typed text into a chip, once', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-tagpicker--no-popover'));
      expect(find.byType(FluentInteractionTag), findsNothing);

      await _submit(tester, 'Ada Lovelace');
      expect(find.byType(FluentInteractionTag), findsOneWidget);
      expect(find.text('Ada Lovelace'), findsOneWidget);
      expect(
        editedText(tester, find.byType(FluentInput)),
        isEmpty,
        reason: 'committing a tag has to clear the field it came from',
      );

      await _submit(tester, 'Ada Lovelace');
      expect(
        find.byType(FluentInteractionTag),
        findsOneWidget,
        reason: 'the demo refuses a duplicate rather than stacking two chips',
      );

      await _submit(tester, 'Grace Hopper');
      expect(find.byType(FluentInteractionTag), findsNWidgets(2));

      await tapAndSettle(
        tester,
        find.descendant(
          of: find.widgetWithText(FluentInteractionTag, 'Ada Lovelace'),
          matching: find.byType(FluentTagDismissGlyph),
        ),
        what: "Ada Lovelace's dismiss half",
      );
      expect(find.text('Ada Lovelace'), findsNothing);
      expect(find.byType(FluentInteractionTag), findsOneWidget);
    });
  });

  group('single line', () {
    testWidgets('the chevron flips with focus and flips back', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-tagpicker--single-line'));
      expect(
        tester.widget<Icon>(find.byType(Icon)).icon,
        FluentIcons.chevron_down_20_regular,
      );

      await mouseClick(tester, _field());
      expect(
        tester.widget<Icon>(find.byType(Icon)).icon,
        FluentIcons.chevron_up_20_regular,
        reason:
            'focus is the closest signal this control exposes to "expanded", '
            'and the chevron is the only thing that reports it',
      );

      FocusManager.instance.primaryFocus?.unfocus();
      await settle(tester);
      expect(
        tester.widget<Icon>(find.byType(Icon)).icon,
        FluentIcons.chevron_down_20_regular,
      );
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

/// The editable inside the [index]-th picker on screen.
Finder _field({int index = 0}) => find.byType(EditableText).at(index);

/// Focuses the field and opens the popup the way the widget documents: the
/// keyboard.
///
/// A pointer opens it too — see the default group's mouse test — but every
/// assertion about what the popup *contains* gets there by key, or it would be
/// testing two things at once and reporting the wrong one.
Future<void> openPopup(WidgetTester tester) async {
  await tester.tap(_field(), warnIfMissed: false);
  await settle(tester);
  await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
  await settle(tester);
}

/// Types [value] into the first field and submits it, as pressing Enter does.
Future<void> _submit(WidgetTester tester, String value) async {
  await tester.enterText(_field(), value);
  await settle(tester);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await settle(tester);
}
