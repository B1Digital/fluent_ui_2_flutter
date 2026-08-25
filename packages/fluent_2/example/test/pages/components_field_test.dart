import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Field is chrome around somebody else's control, so "does it work" splits in
/// two. The layout half — label above, message under the control, hint under
/// that, asterisk after the label — is only checkable as geometry, because
/// every one of those slots renders the same kind of `Text` and a suite that
/// merely found the strings would pass with them stacked in any order. The
/// wiring half is the Component Examples section, where eight different
/// controls each have to still take input through the wrapper.
void main() {
  const String page = 'components-field';

  group('default', () {
    final DocsSection section = sectionOf('components-field--default');

    testWidgets('label, control and message stack in that order', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final double label = tester.getRect(find.text('Example field')).bottom;
      final Rect control = tester.getRect(find.byType(FluentInput));
      final double message = tester
          .getRect(find.text('This is a success message.'))
          .top;

      expect(label, lessThanOrEqualTo(control.top));
      expect(
        message,
        greaterThanOrEqualTo(control.bottom),
        reason: 'the validation message belongs under the control it judges',
      );
      expect(
        find.byIcon(FluentIcons.checkmark_circle_12_filled),
        findsOneWidget,
      );
    });

    testWidgets('the wrapped control still takes text', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder input = find.byType(FluentInput);

      await tester.enterText(input, 'hello');
      await settle(tester);
      expect(
        editedText(tester, input),
        'hello',
        reason: 'Field must not swallow the keystrokes of what it wraps',
      );
    });

    testWidgets('unmounts cleanly', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('horizontal orientation', () {
    final DocsSection section = sectionOf('components-field--horizontal');

    testWidgets('the label sits beside the control at a third of the width', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Rect label = tester.getRect(find.text('Horizontal'));
      final Rect control = tester.getRect(find.byType(FluentInput));
      expect(
        label.right,
        lessThanOrEqualTo(control.left),
        reason: 'horizontal means beside, not above',
      );
      // The section's description commits to the ratio: "the label width is a
      // fixed 33% of the width of the field". A fraction rather than a pixel
      // count because the demo's own 400px box is a story decorator, and a
      // full-width viewport stretches it.
      final double total = control.right - label.left;
      expect((control.left - label.left) / total, closeTo(0.33, 0.005));
    });

    testWidgets('the hint stays under the control', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(
        tester
            .getRect(
              find.text('Validation message and hint are below the input.'),
            )
            .top,
        greaterThanOrEqualTo(tester.getRect(find.byType(FluentInput)).bottom),
      );
    });

    testWidgets('unmounts cleanly', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('required', () {
    final DocsSection section = sectionOf('components-field--required');

    testWidgets('the asterisk is drawn after the label', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(find.text('*'), findsOneWidget);
      expect(
        tester.getRect(find.text('*')).left,
        greaterThanOrEqualTo(tester.getRect(find.text('Required field')).right),
        reason: 'the asterisk marks the end of the label, not the start',
      );
      expect(
        textStyleOf(tester, find.text('*'))?.color,
        isNot(textStyleOf(tester, find.text('Required field'))?.color),
        reason: 'the section promises a *red* asterisk',
      );
    });

    testWidgets('unmounts cleanly', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('info button', () {
    final DocsSection section = sectionOf('components-field--info');

    testWidgets('the trigger opens and closes the tip', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text('Example info'), findsNothing);

      // A real mouse: the trigger is a 16px glyph inside a label, and it is the
      // only thing on this page that has to survive a press landing on the
      // label's own text region rather than on the button.
      await mouseClick(tester, find.byType(FluentInfoButton));
      expect(
        find.text('Example info'),
        findsOneWidget,
        reason: 'the info button exists to show exactly this',
      );

      await mouseClick(tester, find.byType(FluentInfoButton));
      expect(
        find.text('Example info'),
        findsNothing,
        reason: 'a second press on the trigger closes what the first opened',
      );
    });

    testWidgets('the label reads as a label, asterisk-free', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text('Field with an info button'), findsOneWidget);
      expect(find.text('*'), findsNothing);
    });

    testWidgets('unmounts cleanly', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('disabled control', () {
    final DocsSection section = sectionOf('components-field--disabled');

    testWidgets('the control is disabled and the label is not', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: find.byType(FluentInput),
                matching: find.byType(EditableText),
              ),
            )
            .readOnly,
        isTrue,
        reason: 'a disabled input must refuse the caret, not merely grey out',
      );
      // The whole point of the section: "the label should not be marked
      // disabled. This ensures the label remains readable to users."
      expect(
        textStyleOf(tester, find.text('Field with disabled control'))?.color,
        isNot(colorsOf(tester).neutralForegroundDisabled),
      );
    });

    testWidgets('unmounts cleanly', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('size', () {
    final DocsSection section = sectionOf('components-field--size');

    testWidgets('the size prop scales both the label and the control', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final List<double?> labels = <double?>[
        for (final String label in <String>[
          'Size small',
          'Size medium',
          'Size large',
        ])
          textStyleOf(tester, find.text(label))?.fontSize,
      ];
      for (int i = 1; i < labels.length; i++) {
        expect(
          labels[i],
          greaterThan(labels[i - 1]!),
          reason: 'the label ramp is what FluentField.size moves',
        );
      }

      final Finder inputs = find.byType(FluentInput);
      expect(inputs, findsNWidgets(3));
      for (int i = 1; i < 3; i++) {
        expect(
          tester.getSize(inputs.at(i)).height,
          greaterThan(tester.getSize(inputs.at(i - 1)).height),
          reason: 'each control was given the matching FluentInputSize by hand',
        );
      }
    });

    testWidgets('unmounts cleanly', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('validation message', () {
    final DocsSection section = sectionOf(
      'components-field--validation-message',
    );

    testWidgets('the four states tint their glyphs four different ways', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final List<Color?> tints = <Color?>[
        for (final IconData glyph in <IconData>[
          FluentIcons.error_circle_12_filled,
          FluentIcons.warning_12_filled,
          FluentIcons.checkmark_circle_12_filled,
          FluentIcons.sparkle_20_filled,
        ])
          IconTheme.of(tester.element(find.byIcon(glyph))).color,
      ];
      expect(
        tints.toSet(),
        hasLength(4),
        reason:
            'validationState is supposed to colour the glyph; two states '
            'sharing a tint means the prop never reached the resolver',
      );
    });

    testWidgets('only the error state recolours the message text', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Color? error = textStyleOf(
        tester,
        find.text('This is an error message.'),
      )?.color;
      for (final String message in <String>[
        'This is a warning message.',
        'This is a success message.',
        'This is a custom message.',
      ]) {
        expect(
          textStyleOf(tester, find.text(message))?.color,
          isNot(error),
          reason: 'upstream keeps "$message" on the neutral ramp',
        );
      }
    });

    testWidgets('the error field paints a different border', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder inputs = find.byType(FluentInput);
      expect(tester.widget<FluentInput>(inputs.at(0)).error, isTrue);

      expect(
        decorationUnder(tester, inputs.at(0)).border,
        isNot(decorationUnder(tester, inputs.at(1)).border),
        reason:
            'the description promises aria-invalid "adds a red border to some '
            'field components (such as Input)"',
      );
    });

    testWidgets('unmounts cleanly', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('hint', () {
    final DocsSection section = sectionOf('components-field--hint');

    testWidgets('the hint renders under the control, smaller than the label', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(
        tester.getRect(find.text('Sample hint text.')).top,
        greaterThanOrEqualTo(tester.getRect(find.byType(FluentInput)).bottom),
      );
      expect(
        textStyleOf(tester, find.text('Sample hint text.'))?.fontSize,
        lessThan(
          textStyleOf(tester, find.text('Example with hint'))!.fontSize!,
        ),
        reason: 'the hint is caption1 under a body1 label',
      );
    });

    testWidgets('unmounts cleanly', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('component examples', () {
    final DocsSection section = sectionOf(
      'components-field--component-examples',
    );

    testWidgets('the input and the textarea take text', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await tester.enterText(find.byType(FluentInput), 'typed');
      await settle(tester);
      expect(editedText(tester, find.byType(FluentInput)), 'typed');

      await tester.enterText(find.byType(FluentTextarea), 'several\nlines');
      await settle(tester);
      expect(editedText(tester, find.byType(FluentTextarea)), 'several\nlines');
    });

    testWidgets('the combobox commits a pick', (WidgetTester tester) async {
      await pumpSection(tester, section);
      final Finder dropdown = find.byType(FluentDropdown<String>);
      expect(tester.widget<FluentDropdown<String>>(dropdown).value, isNull);

      expect(
        await pickDropdown<String>(tester, dropdown, 'Option 2'),
        'Option 2',
      );
      // The radio group below offers the same three labels, so this also
      // proves the pick landed in the listbox rather than on a radio.
      expect(tester.widget<FluentRadioGroup<String>>(radioGroup).value, isNull);
    });

    testWidgets('the spin button steps', (WidgetTester tester) async {
      await pumpSection(tester, section);
      final Finder spin = find.byType(FluentSpinButton);
      expect(tester.widget<FluentSpinButton>(spin).value, 0);

      // The increase half is the first of the two in tree order.
      await tapAndSettle(
        tester,
        find.byType(FluentSpinButtonStepper).first,
        what: 'the spin button up stepper',
      );
      expect(tester.widget<FluentSpinButton>(spin).value, 1);
      expect(editedText(tester, spin), '1');
    });

    testWidgets('the checkbox and the switch round-trip', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder checkbox = find.byType(FluentCheckbox);
      final Finder toggle = find.byType(FluentSwitch);

      await mouseClick(tester, checkbox);
      expect(tester.widget<FluentCheckbox>(checkbox).checked, isTrue);
      await mouseClick(tester, checkbox);
      expect(tester.widget<FluentCheckbox>(checkbox).checked, isFalse);

      await mouseClick(tester, toggle);
      expect(tester.widget<FluentSwitch>(toggle).checked, isTrue);
      await mouseClick(tester, toggle);
      expect(tester.widget<FluentSwitch>(toggle).checked, isFalse);
    });

    testWidgets('the slider moves both ways', (WidgetTester tester) async {
      await pumpSection(tester, section);
      final Finder slider = find.byType(FluentSlider);
      expect(tester.widget<FluentSlider>(slider).value, 25);

      final Rect rail = tester.getRect(slider);
      await mouseClickAt(
        tester,
        Offset(rail.right - 8, rail.center.dy),
        what: 'the right end of the slider',
      );
      final double high = tester.widget<FluentSlider>(slider).value;
      expect(high, greaterThan(25));

      await mouseClickAt(
        tester,
        Offset(rail.left + 8, rail.center.dy),
        what: 'the left end of the slider',
      );
      expect(tester.widget<FluentSlider>(slider).value, lessThan(high));
    });

    testWidgets('the radio group commits a choice', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(tester.widget<FluentRadioGroup<String>>(radioGroup).value, isNull);

      await mouseClick(
        tester,
        find.descendant(of: radioGroup, matching: find.text('Option 3')),
      );
      expect(
        tester.widget<FluentRadioGroup<String>>(radioGroup).value,
        'Option 3',
      );
    });

    testWidgets('the checkbox row labels itself instead of the field', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      // The demo says so in its own hint, and the arrangement is the claim:
      // the checkbox's label is beside it, not stacked above the row.
      expect(
        find.text('Checkboxes use their own label instead of the Field label.'),
        findsOneWidget,
      );
      final Rect label = tester.getRect(find.text('Checkbox'));
      final Rect box = tester.getRect(find.byType(FluentCheckbox));
      expect(label.left, greaterThan(box.left));
    });

    testWidgets('unmounts cleanly', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('third party controls a Field', () {
    final DocsSection section = sectionOf('components-field--render-function');

    testWidgets('the third-party row keeps its glyph and its input', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.byIcon(FluentIcons.animal_cat_24_regular), findsOneWidget);

      await tester.enterText(find.byType(FluentInput), 'Mittens');
      await settle(tester);
      expect(
        editedText(tester, find.byType(FluentInput)),
        'Mittens',
        reason: 'a control Field knows nothing about must still take input',
      );
    });

    testWidgets('the label and the hint bracket the control', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Rect control = tester.getRect(find.byType(FluentInput));

      expect(
        tester.getRect(find.text('Third party input')).bottom,
        lessThanOrEqualTo(control.top),
      );
      expect(
        tester
            .getRect(
              find.text(
                'Use a render function to properly associate the label with '
                'the control.',
              ),
            )
            .top,
        greaterThanOrEqualTo(control.bottom),
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

/// The Component Examples section's radio group.
final Finder radioGroup = find.byType(FluentRadioGroup<String>);

/// The palette the mounted section resolved against.
///
/// Read from the tree rather than rebuilt from `FluentThemeData`: the assertion
/// that matters is "not the disabled token *this* field is using", and a second
/// theme built by the test could disagree with the first.
FluentColors colorsOf(WidgetTester tester) =>
    FluentTheme.of(tester.element(find.byType(FluentField).first)).colors;
