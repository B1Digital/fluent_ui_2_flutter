import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Textarea's page carries no knobs at all — every section is a field, or a row
/// of fields, whose whole claim is "this one behaves differently from that
/// one". So each test below drives the fields with real keystrokes and asserts
/// the difference the section's title promises: a disabled field refuses text,
/// a placeholder yields to it, a pinned field does not grow with it, and a
/// 50-character field stops accepting it.
void main() {
  const String page = 'components-textarea';

  /// The height of the [at]-th textarea in the mounted section.
  double heightOf(WidgetTester tester, int at) =>
      tester.getRect(find.byType(FluentTextarea).at(at)).height;

  group('default', () {
    final DocsSection section = sectionOf('components-textarea--default');

    testWidgets('the field takes text and grows with it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder field = find.byType(FluentTextarea);
      final double twoLines = heightOf(tester, 0);

      await tester.enterText(field, 'one');
      await settle(tester);
      expect(editedText(tester, field), 'one');
      expect(
        heightOf(tester, 0),
        twoLines,
        reason: 'one line must still fit the two-line minimum without growing',
      );

      // maxLines defaults to null on FluentTextarea, so the default field is the
      // one that grows without bound. A field that clamped here would silently
      // hide everything the user typed past line two.
      await tester.enterText(field, 'one\ntwo\nthree\nfour\nfive');
      await settle(tester);
      expect(heightOf(tester, 0), greaterThan(twoLines));
    });

    testWidgets('the label names the field', (WidgetTester tester) async {
      await pumpSection(tester, section);
      expect(find.text('Default Textarea'), findsOneWidget);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('appearance', () {
    final DocsSection section = sectionOf('components-textarea--appearance');

    testWidgets('the three fields carry the three appearances', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(
        tester
            .widgetList<FluentTextarea>(find.byType(FluentTextarea))
            .map((FluentTextarea t) => t.appearance),
        <FluentTextareaAppearance>[
          FluentTextareaAppearance.outline,
          FluentTextareaAppearance.filledDarker,
          FluentTextareaAppearance.filledLighter,
        ],
      );
    });

    testWidgets('each field owns its own value', (WidgetTester tester) async {
      await pumpSection(tester, section);

      final Finder fields = find.byType(FluentTextarea);
      await tester.enterText(fields.at(1), 'darker only');
      await settle(tester);

      // A demo that let three const fields share one internally-created
      // controller would echo this into all three, and the two idle fields
      // would drop their placeholder along with it.
      expect(editedText(tester, fields.at(1)), 'darker only');
      expect(editedText(tester, fields.at(0)), isEmpty);
      expect(editedText(tester, fields.at(2)), isEmpty);
      expect(
        find.text('type here...'),
        findsNWidgets(2),
        reason: 'the two untouched fields must still show their placeholder',
      );
    });
  });

  group('disabled', () {
    final DocsSection section = sectionOf('components-textarea--disabled');

    testWidgets('the disabled field refuses text and refuses focus', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder field = find.byType(FluentTextarea);
      final Finder editable = find.descendant(
        of: field,
        matching: find.byType(EditableText),
      );
      expect(
        tester.widget<EditableText>(editable).readOnly,
        isTrue,
        reason: 'enabled: false must reach the editor, not only the paint',
      );

      // `enabled: false` is documented as a real state rather than a treatment,
      // so a pointer landing on it must not put a caret in it either.
      await mouseClick(tester, field);
      expect(
        tester.widget<EditableText>(editable).focusNode.hasFocus,
        isFalse,
        reason: 'a disabled field must stay out of the focus chain',
      );
      expect(editedText(tester, field), isEmpty);
    });
  });

  group('placeholder', () {
    final DocsSection section = sectionOf('components-textarea--placeholder');

    testWidgets('the placeholder yields to typed text and comes back', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder field = find.byType(FluentTextarea);
      expect(find.text('type here...'), findsOneWidget);

      await tester.enterText(field, 'a');
      await settle(tester);
      expect(
        find.text('type here...'),
        findsNothing,
        reason: 'a placeholder left behind the value is unreadable overprint',
      );

      // The round trip: the placeholder is a function of the value, not a
      // one-way latch cleared on first edit.
      await tester.enterText(field, '');
      await settle(tester);
      expect(find.text('type here...'), findsOneWidget);
    });
  });

  group('resize', () {
    final DocsSection section = sectionOf('components-textarea--resize');

    testWidgets('the pinned fields hold their height and the free ones grow', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder fields = find.byType(FluentTextarea);
      expect(fields, findsNWidgets(4));
      final List<double> before = <double>[
        for (int i = 0; i < 4; i++) heightOf(tester, i),
      ];

      const String tall = 'one\ntwo\nthree\nfour\nfive\nsix';
      for (int i = 0; i < 4; i++) {
        await tester.enterText(fields.at(i), tall);
        await settle(tester);
      }

      // 0 and 2 are the "none" and "horizontal" variants, pinned at
      // `maxLines: 2`; 1 and 3 are "vertical" and "both", which grow. If the
      // cap ever stopped biting, all four would read the same and the section
      // would be four copies of one field.
      expect(heightOf(tester, 0), before[0]);
      expect(heightOf(tester, 2), before[2]);
      expect(heightOf(tester, 1), greaterThan(before[1]));
      expect(heightOf(tester, 3), greaterThan(before[3]));
    });
  });

  group('size', () {
    final DocsSection section = sectionOf('components-textarea--size');

    testWidgets('the three sizes step up in height', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(
        tester
            .widgetList<FluentTextarea>(find.byType(FluentTextarea))
            .map((FluentTextarea t) => t.size),
        <FluentTextareaSize>[
          FluentTextareaSize.small,
          FluentTextareaSize.medium,
          FluentTextareaSize.large,
        ],
      );

      // A textarea has no height floor: its box is two lines of the size's type
      // ramp plus a flat 6 of inset, so the whole size axis arrives as
      // geometry and reading the three heights is the only way to prove the
      // axis points the right way.
      final double small = heightOf(tester, 0);
      final double medium = heightOf(tester, 1);
      final double large = heightOf(tester, 2);
      expect(small, lessThan(medium));
      expect(
        medium,
        lessThan(large),
        reason:
            'large binds typography.body2 and medium binds body1, which the '
            'mobile ramps order the other way round — so Large renders '
            'SHORTER than Medium wherever the iOS or Android ramp is in play',
      );
    });
  });

  group('uncontrolled', () {
    final DocsSection section = sectionOf('components-textarea--uncontrolled');

    testWidgets('every edit reaches onChanged', (WidgetTester tester) async {
      // The demo's only observable output is the console line its hint points
      // at, so the console is where the assertion has to look. Restored inside
      // the body rather than in a tearDown: the binding checks the foundation
      // debug variables between the body and the tearDowns, and a still-hooked
      // debugPrint fails the test there.
      final List<String> printed = <String>[];
      final DebugPrintCallback original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) =>
          printed.add(message ?? '');

      await pumpSection(tester, section);
      final Finder field = find.byType(FluentTextarea);

      await tester.enterText(field, 'hello');
      await settle(tester);
      debugPrint = original;

      expect(editedText(tester, field), 'hello');
      expect(printed, contains('New value: "hello"'));
    });
  });

  group('controlled', () {
    final DocsSection section = sectionOf('components-textarea--controlled');

    testWidgets('the field starts seeded and stops at 50 characters', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder field = find.byType(FluentTextarea);
      expect(editedText(tester, field), 'initial value');

      await tester.enterText(field, 'x' * 80);
      await settle(tester);
      // maxLength stands in for the length check upstream runs inside onChange,
      // so the cap has to be enforced on the value, not merely announced in the
      // label.
      expect(editedText(tester, field), 'x' * 50);

      await tester.enterText(field, 'short');
      await settle(tester);
      expect(editedText(tester, field), 'short');
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
