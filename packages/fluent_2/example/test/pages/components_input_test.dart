import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Input's page carries exactly one knob — the Disabled section's switch — and
/// nine sections whose claim is a difference between fields. So the switch gets
/// the real-mouse treatment, and every other section is driven with real
/// keystrokes and measured, because "an input can have X" is only true if X
/// reaches the value, the box or the paint.
void main() {
  const String page = 'components-input';

  /// The [at]-th input in the mounted section.
  Finder inputAt(int at) => find.byType(FluentInput).at(at);

  /// What the [at]-th input actually PAINTS, obscuring applied.
  ///
  /// `editedText` reads the controller, which holds the plaintext whether or
  /// not the field masks it — so only the render object can answer "is this
  /// password on screen in the clear".
  String paintedText(WidgetTester tester, int at) => tester
      .state<EditableTextState>(
        find.descendant(of: inputAt(at), matching: find.byType(EditableText)),
      )
      .renderEditable
      .text!
      .toPlainText();

  group('default', () {
    final DocsSection section = sectionOf('components-input--default');

    testWidgets('the field takes text', (WidgetTester tester) async {
      await pumpSection(tester, section);

      expect(find.text('Sample input'), findsOneWidget);
      await tester.enterText(find.byType(FluentInput), 'hello');
      await settle(tester);
      expect(editedText(tester, find.byType(FluentInput)), 'hello');
    });
  });

  group('appearance', () {
    final DocsSection section = sectionOf('components-input--appearance');

    testWidgets('the four fields carry the four appearances', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(
        tester
            .widgetList<FluentInput>(find.byType(FluentInput))
            .map((FluentInput i) => i.appearance),
        <FluentInputAppearance>[
          FluentInputAppearance.outline,
          FluentInputAppearance.underline,
          FluentInputAppearance.filledLighter,
          FluentInputAppearance.filledDarker,
        ],
      );
    });

    testWidgets('the appearances reach the paint, not just the property', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The section's whole point is the contrast between the fills, so a
      // ramp that resolved four appearances to one colour would leave the page
      // saying nothing while every property assertion still passed.
      final Set<Color?> fills = <Color?>{
        for (int i = 0; i < 4; i++) decorationUnder(tester, inputAt(i)).color,
      };
      expect(
        fills.length,
        greaterThan(1),
        reason: 'four appearances must not all paint the same fill',
      );
    });

    testWidgets('each field owns its own value', (WidgetTester tester) async {
      await pumpSection(tester, section);

      await tester.enterText(inputAt(2), 'lighter only');
      await settle(tester);
      expect(editedText(tester, inputAt(2)), 'lighter only');
      for (final int other in <int>[0, 1, 3]) {
        expect(
          editedText(tester, inputAt(other)),
          isEmpty,
          reason: 'field $other must not share a controller with field 2',
        );
      }
    });
  });

  group('content before/after', () {
    final DocsSection section = sectionOf(
      'components-input--content-before-after',
    );

    testWidgets('both slots render inside the field border', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The description promises these "are displayed inside the input
      // border". A slot laid out beside the field instead of within it is a
      // silent layout regression that no property assertion would notice.
      final Rect first = tester.getRect(inputAt(0));
      expect(
        first.contains(
          tester.getRect(find.byIcon(FluentIcons.person_20_regular)).center,
        ),
        isTrue,
        reason: 'the contentBefore icon must sit inside the first field',
      );

      final Rect third = tester.getRect(inputAt(2));
      for (final String presentational in <String>[r'$', '.00']) {
        expect(
          third.contains(tester.getRect(find.text(presentational)).center),
          isTrue,
          reason: '"$presentational" must sit inside the third field',
        );
      }
      // contentBefore leads and contentAfter trails, in reading order.
      expect(
        tester.getRect(find.text(r'$')).left,
        lessThan(tester.getRect(find.text('.00')).left),
      );
    });

    testWidgets('the contentAfter button is live and reachable', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder mic = find.byType(FluentButton);
      expect(tester.widget<FluentButton>(mic).onPressed, isNotNull);

      // warnIfMissed is the assertion here: the field's own tap-to-focus
      // gesture covers the whole box, so a button in the contentAfter slot
      // that lost the hit test would be unclickable while still looking live.
      await tapAndSettle(tester, mic, what: 'the voice button');
      expect(editedText(tester, inputAt(1)), isEmpty);
    });
  });

  group('disabled', () {
    final DocsSection section = sectionOf('components-input--disabled');

    testWidgets('the switch enables all four fields and puts them back', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder toggle = find.byType(FluentSwitch);
      Iterable<bool> enabledFlags() => tester
          .widgetList<FluentInput>(find.byType(FluentInput))
          .map((FluentInput i) => i.enabled);

      expect(tester.widget<FluentSwitch>(toggle).checked, isTrue);
      expect(enabledFlags(), everyElement(isFalse));

      // The page's only knob, so it is the one that gets a real pointer: a
      // switch that commits under `tester.tap` and does nothing under a mouse
      // press is a defect a synthetic-only suite cannot see.
      await mouseClick(tester, toggle);
      expect(tester.widget<FluentSwitch>(toggle).checked, isFalse);
      expect(
        enabledFlags(),
        everyElement(isTrue),
        reason: 'unchecking Disabled must reach every one of the four fields',
      );

      // Enabled is not a colour: the field has to start accepting text too.
      await tester.enterText(inputAt(0), 'now editable');
      await settle(tester);
      expect(editedText(tester, inputAt(0)), 'now editable');

      await mouseClick(tester, toggle);
      expect(tester.widget<FluentSwitch>(toggle).checked, isTrue);
      expect(enabledFlags(), everyElement(isFalse));
      expect(
        tester
            .widgetList<EditableText>(find.byType(EditableText))
            .map((EditableText e) => e.readOnly),
        everyElement(isTrue),
        reason: 'disabled must be a real state, not a grey treatment',
      );
    });

    testWidgets('the seeded value survives the round trip', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(editedText(tester, inputAt(0)), 'disabled value');

      await tapAndSettle(tester, find.byType(FluentSwitch));
      await tapAndSettle(tester, find.byType(FluentSwitch));
      // The four controllers belong to the demo's State, so toggling must not
      // rebuild them from scratch and lose what they held.
      expect(editedText(tester, inputAt(3)), 'disabled value');
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('inline', () {
    final DocsSection section = sectionOf('components-input--inline');

    testWidgets('both inline fields keep their explicit width', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(find.byType(FluentInput), findsNWidgets(2));
      // The comment above the demo says an inline field is given an explicit
      // width because Flutter's field otherwise fills its box — so a field
      // that came back the full 1600 wide means the SizedBox stopped biting.
      expect(tester.getSize(inputAt(0)).width, 160);
      expect(tester.getSize(inputAt(1)).width, 160);
    });

    testWidgets('the second field sits within its paragraph', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder paragraph = find.byType(Text).last;
      expect(
        tester.getRect(paragraph).contains(tester.getRect(inputAt(1)).center),
        isTrue,
        reason:
            'the WidgetSpan field must be laid out inside the paragraph, which '
            'is the entire claim of an inline input',
      );
    });
  });

  group('placeholder', () {
    final DocsSection section = sectionOf('components-input--placeholder');

    testWidgets('the placeholder yields to typed text and comes back', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text('This is a placeholder'), findsOneWidget);

      await tester.enterText(find.byType(FluentInput), 'a');
      await settle(tester);
      expect(
        find.text('This is a placeholder'),
        findsNothing,
        reason: 'a placeholder left behind the value is unreadable overprint',
      );

      await tester.enterText(find.byType(FluentInput), '');
      await settle(tester);
      expect(find.text('This is a placeholder'), findsOneWidget);
    });
  });

  group('size', () {
    final DocsSection section = sectionOf('components-input--size');

    testWidgets('the three sizes step up in height', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(
        tester
            .widgetList<FluentInput>(find.byType(FluentInput))
            .map((FluentInput i) => i.size),
        <FluentInputSize>[
          FluentInputSize.small,
          FluentInputSize.medium,
          FluentInputSize.large,
        ],
      );

      // Fluent pins 24/32/40 for the three sizes, so this is an exact ramp
      // rather than an ordering — a size axis that only moved the type would
      // still leave three identical boxes.
      expect(tester.getSize(inputAt(0)).height, 24);
      expect(tester.getSize(inputAt(1)).height, 32);
      expect(tester.getSize(inputAt(2)).height, 40);
    });
  });

  group('type', () {
    final DocsSection section = sectionOf('components-input--type');

    testWidgets('email and url ask for their own keyboards', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(
        tester.widget<FluentInput>(inputAt(0)).keyboardType,
        TextInputType.emailAddress,
      );
      expect(
        tester.widget<FluentInput>(inputAt(1)).keyboardType,
        TextInputType.url,
      );
    });

    testWidgets('the password field is masked on screen', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(editedText(tester, inputAt(2)), 'password');
      // The one assertion that matters: the value is in the controller and NOT
      // on the glass. Reading `obscureText` off the widget would pass even if
      // the flag never reached the editor.
      expect(paintedText(tester, 2), '•' * 'password'.length);

      await tester.enterText(inputAt(2), 'longerpassword');
      await settle(tester);
      expect(paintedText(tester, 2), '•' * 'longerpassword'.length);
    });
  });

  group('uncontrolled', () {
    final DocsSection section = sectionOf('components-input--uncontrolled');

    testWidgets('the seeded value edits and every edit reaches onChanged', (
      WidgetTester tester,
    ) async {
      // The demo's only output besides the value is its console line, so the
      // console is where the assertion has to look. Restored inside the body:
      // the binding checks the foundation debug variables between the body and
      // the tearDowns, and a still-hooked debugPrint fails the test there.
      final List<String> printed = <String>[];
      final DebugPrintCallback original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) =>
          printed.add(message ?? '');

      await pumpSection(tester, section);
      final Finder field = find.byType(FluentInput);
      expect(editedText(tester, field), 'default value');

      await tester.enterText(field, 'edited value');
      await settle(tester);
      debugPrint = original;

      expect(editedText(tester, field), 'edited value');
      expect(printed, contains('New value: "edited value"'));
    });
  });

  group('controlled', () {
    final DocsSection section = sectionOf('components-input--controlled');

    testWidgets('the field refuses the 21st character', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder field = find.byType(FluentInput);
      expect(editedText(tester, field), 'initial value');

      await tester.enterText(field, 'twenty characters!!!');
      await settle(tester);
      expect(
        editedText(tester, field),
        'twenty characters!!!',
        reason: 'exactly 20 is inside the limit and must be accepted',
      );

      // Flutter has already applied the edit by the time onChanged runs, so
      // "refusing" means the demo putting the last accepted value back. If it
      // ever stopped, the field would quietly grow past its stated limit.
      await tester.enterText(field, 'twenty one characters');
      await settle(tester);
      expect(editedText(tester, field), 'twenty characters!!!');
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
