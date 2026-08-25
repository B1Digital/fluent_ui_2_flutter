import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Dropdown's page is fourteen variations on one control, so nearly every
/// section's knob IS the dropdown: open it, pick a row, and the trigger has to
/// change. The tests below drive that loop on each section and then press on
/// the things each individual section adds — a disabled row that must refuse a
/// pick, a group header that must not commit, a clear button that must only be
/// live once there is something to clear, a checkbox that claims to open the
/// list.
void main() {
  const String page = 'components-dropdown';

  /// The [at]-th dropdown in the mounted section.
  Finder dropdownAt(int at) => find.byType(FluentDropdown<String>).at(at);

  /// The one dropdown in a single-dropdown section.
  Finder theDropdown() => find.byType(FluentDropdown<String>);

  /// The value the [at]-th dropdown currently holds.
  String? valueAt(WidgetTester tester, int at) =>
      tester.widget<FluentDropdown<String>>(dropdownAt(at)).value;

  /// Opens [dropdown] without picking anything.
  Future<void> open(WidgetTester tester, Finder dropdown) async {
    await tester.ensureVisible(dropdown);
    await settle(tester);
    await tester.tap(dropdown, warnIfMissed: false);
    await settle(tester);
  }

  group('default', () {
    final DocsSection section = sectionOf('components-dropdown--default');

    testWidgets('picking a row replaces the placeholder with the value', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(find.text('Select an animal'), findsOneWidget);
      expect(
        await pickDropdown<String>(tester, theDropdown(), 'Corgi'),
        'Corgi',
      );
      expect(
        find.text('Select an animal'),
        findsNothing,
        reason:
            'a trigger showing both the placeholder and the value is a '
            'trigger that never read its own value',
      );
      expect(find.text('Corgi'), findsOneWidget);
    });

    testWidgets('the trigger opens and commits under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The dropdown is this page's primary knob, so it gets the real pointer.
      // A popup that dismisses under a mouse press instead of committing is a
      // defect only this path can see.
      await mouseClick(tester, theDropdown());
      expect(
        find.text('Chupacabra'),
        findsOneWidget,
        reason: 'a mouse press on the trigger must open the listbox',
      );

      await mouseClick(tester, find.text('Chupacabra').last);
      expect(
        valueAt(tester, 0),
        'Chupacabra',
        reason: 'a mouse press on a row must commit, not merely dismiss',
      );
    });

    testWidgets('the disabled row refuses the pick', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await open(tester, theDropdown());

      await tapAndSettle(
        tester,
        find.text('Ferret'),
        what: 'the disabled Ferret row',
        warnIfMissed: false,
      );
      expect(
        valueAt(tester, 0),
        isNull,
        reason: 'Ferret is declared enabled: false and must not commit',
      );
      expect(
        find.text('Ferret'),
        findsOneWidget,
        reason: 'a disabled row absorbs its own press, so the list stays open',
      );
    });
  });

  group('appearance', () {
    final DocsSection section = sectionOf('components-dropdown--appearance');

    testWidgets('the four triggers carry the four appearances', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(
        tester
            .widgetList<FluentDropdown<String>>(
              find.byType(FluentDropdown<String>),
            )
            .map((FluentDropdown<String> d) => d.appearance),
        <FluentDropdownAppearance>[
          FluentDropdownAppearance.outline,
          FluentDropdownAppearance.transparent,
          FluentDropdownAppearance.fillDarker,
          FluentDropdownAppearance.fillLighter,
        ],
      );
    });

    testWidgets('each trigger keeps its own selection', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The demo keys one map by appearance, so a pick landing in the wrong
      // bucket would move a trigger the user never touched.
      expect(await pickDropdown<String>(tester, dropdownAt(2), 'Bird'), 'Bird');
      expect(valueAt(tester, 0), isNull);
      expect(valueAt(tester, 1), isNull);
      expect(valueAt(tester, 3), isNull);
      expect(
        find.text('-'),
        findsNWidgets(3),
        reason: 'the three untouched triggers must still show the placeholder',
      );
    });
  });

  group('with field', () {
    final DocsSection section = sectionOf('components-dropdown--with-field');

    testWidgets('the field labels the dropdown and the dropdown still picks', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final FluentField field = tester.widget<FluentField>(
        find.byType(FluentField),
      );
      expect(field.required, isTrue);
      expect(find.text('Best pet'), findsOneWidget);
      expect(find.text("Try picking 'Cat'"), findsOneWidget);

      // Wrapping a control in a Field must not cost it its behaviour.
      expect(await pickDropdown<String>(tester, theDropdown(), 'Cat'), 'Cat');
      expect(find.text('Select an animal'), findsNothing);
    });
  });

  group('grouped', () {
    final DocsSection section = sectionOf('components-dropdown--grouped');

    testWidgets('a group header is inert but a row under it commits', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await open(tester, theDropdown());

      expect(find.text('Land'), findsOneWidget);
      expect(find.text('Sea'), findsOneWidget);

      await tapAndSettle(
        tester,
        find.text('Land'),
        what: 'the Land group header',
        warnIfMissed: false,
      );
      expect(
        valueAt(tester, 0),
        isNull,
        reason: 'a header carries no value and must never become one',
      );
      expect(
        find.text('Fish'),
        findsOneWidget,
        reason:
            'the header absorbs its own press, so a misclick on a group label '
            'must not throw the list away either',
      );

      // Picked from the list that is already open rather than through
      // pickDropdown, which would toggle the trigger and close it first.
      await tapAndSettle(
        tester,
        find.text('Octopus'),
        what: 'the Octopus row',
        warnIfMissed: false,
      );
      expect(valueAt(tester, 0), 'Octopus');
    });

    testWidgets('the group rule opens a gap above the second header', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await open(tester, theDropdown());

      // Upstream draws a rule plus 4 of inset either side above every group but
      // the first. That is the only thing separating two flat lists of rows
      // into two groups, so it has to arrive as real space.
      final double betweenRows =
          tester.getRect(find.text('Dog')).top -
          tester.getRect(find.text('Cat')).bottom;
      final double aboveGroup =
          tester.getRect(find.text('Sea')).top -
          tester.getRect(find.text('Hamster')).bottom;
      expect(aboveGroup, greaterThan(betweenRows));
    });
  });

  group('clearable', () {
    final DocsSection section = sectionOf('components-dropdown--clearable');

    testWidgets('the clear button wakes on a selection and undoes it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder clear = find.byType(FluentButton);
      expect(
        tester.widget<FluentButton>(clear).onPressed,
        isNull,
        reason: 'nothing is selected yet, so there is nothing to clear',
      );

      expect(
        await pickDropdown<String>(tester, theDropdown(), 'Green'),
        'Green',
      );
      expect(tester.widget<FluentButton>(clear).onPressed, isNotNull);

      await mouseClick(tester, clear);
      expect(valueAt(tester, 0), isNull);
      expect(
        find.text('Select a color'),
        findsOneWidget,
        reason: 'clearing must put the placeholder back, not blank the trigger',
      );
      expect(tester.widget<FluentButton>(clear).onPressed, isNull);
    });
  });

  group('complex options', () {
    final DocsSection section = sectionOf(
      'components-dropdown--complex-options',
    );

    testWidgets('the trigger renders the whole persona it was given', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(
        await pickDropdown<String>(tester, theDropdown(), 'Wanda Howard'),
        'Wanda Howard',
      );
      // The label is a FluentPersona, not a string, and the comment above the
      // demo says the trigger renders the label rather than the `text`. If it
      // fell back to the plain text the secondary line would be gone.
      expect(find.text('Wanda Howard'), findsOneWidget);
      expect(find.text('Out of office'), findsOneWidget);
      expect(find.byType(FluentPersona), findsOneWidget);
    });
  });

  group('custom options', () {
    final DocsSection section = sectionOf(
      'components-dropdown--custom-options',
    );

    testWidgets('the listbox honours its 200px cap and still picks', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await open(tester, theDropdown());

      // The demo passes `surfaceMaxHeight: 200` to reproduce griffel's
      // `maxHeight: 200px`. Seven rows of 24px icons do not fit in that, so an
      // unclamped surface would run down the page instead of scrolling.
      expect(
        tester.getRect(find.byType(ExcludeFocus)).height,
        lessThanOrEqualTo(200),
      );

      await tapAndSettle(
        tester,
        find.text('Rabbit'),
        what: 'the Rabbit row',
        warnIfMissed: false,
      );
      expect(valueAt(tester, 0), 'Rabbit');
      expect(
        find.byIcon(FluentIcons.animal_rabbit_24_filled),
        findsOneWidget,
        reason: 'the custom row icon must travel into the trigger with it',
      );
    });
  });

  group('controlled', () {
    final DocsSection section = sectionOf('components-dropdown--controlled');

    testWidgets('both dropdowns start seeded and move independently', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(valueAt(tester, 0), 'eatkins');
      expect(valueAt(tester, 1), 'eatkins');
      expect(
        find.text('Elvia Atkins'),
        findsNWidgets(2),
        reason: 'a seeded value has to reach the trigger before it is opened',
      );

      expect(
        await pickDropdown<String>(tester, dropdownAt(0), 'Katri Athokas'),
        'kathok',
      );
      expect(
        valueAt(tester, 1),
        'eatkins',
        reason: 'two dropdowns over one const option list must not share state',
      );
    });
  });

  group('multiselect', () {
    final DocsSection section = sectionOf('components-dropdown--multiselect');

    testWidgets('picks accumulate in the trigger and pick again to remove', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text('Select an animal'), findsOneWidget);

      await pickDropdown<String>(tester, theDropdown(), 'Cat');
      expect(find.text('Cat'), findsOneWidget);

      await pickDropdown<String>(tester, theDropdown(), 'Dog');
      expect(
        find.text('Cat, Dog'),
        findsOneWidget,
        reason: 'the trigger joins the whole set, not the last pick',
      );

      // The round trip: this dropdown toggles membership rather than replacing
      // a value, so picking a chosen animal has to take it back out.
      await pickDropdown<String>(tester, theDropdown(), 'Cat');
      expect(find.text('Dog'), findsOneWidget);
      expect(find.text('Cat, Dog'), findsNothing);
    });

    testWidgets('the row glyph tracks membership', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await open(tester, theDropdown());
      expect(
        find.byIcon(FluentIcons.checkbox_checked_24_regular),
        findsNothing,
      );

      await tapAndSettle(
        tester,
        find.text('Fish'),
        what: 'the Fish row',
        warnIfMissed: false,
      );
      await open(tester, theDropdown());
      // Six rows, one of them now ticked: the glyph is the only thing telling a
      // user which animals are in the set while the list is open.
      expect(
        find.byIcon(FluentIcons.checkbox_checked_24_regular),
        findsOneWidget,
      );
      expect(
        find.byIcon(FluentIcons.checkbox_unchecked_24_regular),
        findsNWidgets(5),
      );
    });

    testWidgets('the disabled row stays out of the set', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await open(tester, theDropdown());

      await tapAndSettle(
        tester,
        find.text('Ferret'),
        what: 'the disabled Ferret row',
        warnIfMissed: false,
      );
      expect(
        find.text('Select an animal'),
        findsOneWidget,
        reason: 'Ferret is enabled: false and must never join the join',
      );
    });
  });

  group('size', () {
    final DocsSection section = sectionOf('components-dropdown--size');

    testWidgets('the three triggers step up in height', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(
        tester
            .widgetList<FluentDropdown<String>>(
              find.byType(FluentDropdown<String>),
            )
            .map((FluentDropdown<String> d) => d.size),
        <FluentDropdownSize>[
          FluentDropdownSize.small,
          FluentDropdownSize.medium,
          FluentDropdownSize.large,
        ],
      );
      // Fluent pins 24/32/40, so this is an exact ramp rather than an ordering:
      // a size axis that only moved the type would leave three identical boxes.
      expect(tester.getSize(dropdownAt(0)).height, 24);
      expect(tester.getSize(dropdownAt(1)).height, 32);
      expect(tester.getSize(dropdownAt(2)).height, 40);
    });

    testWidgets('each size keeps its own selection', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(await pickDropdown<String>(tester, dropdownAt(2), 'Cat'), 'Cat');
      expect(valueAt(tester, 0), isNull);
      expect(valueAt(tester, 1), isNull);
    });
  });

  group('disabled', () {
    final DocsSection section = sectionOf('components-dropdown--disabled');

    testWidgets('the trigger never opens', (WidgetTester tester) async {
      await pumpSection(tester, section);

      await open(tester, theDropdown());
      expect(
        find.text('Cat'),
        findsNothing,
        reason: 'onChanged: null is a real disabled state — no popup at all',
      );

      // And not only under a synthetic tap: a mouse press must be refused too.
      await mouseClick(tester, theDropdown());
      expect(find.text('Cat'), findsNothing);
      expect(find.text('Select an animal'), findsOneWidget);
    });
  });

  group('truncated value', () {
    final DocsSection section = sectionOf(
      'components-dropdown--truncated-value',
    );

    testWidgets('the long seeded value stays on one line', (
      WidgetTester tester,
    ) async {
      // The only section on this page whose subject is its own width, so the
      // only one that has to be mounted the way the story stage mounts it.
      await pumpSection(tester, section, loose: true);

      expect(
        valueAt(tester, 0),
        'Screaming hairy armadillo (Chaetophractus vellerosus)',
      );
      // 200 wide and a 53-character value: the trigger has to clamp and
      // ellipsize rather than wrap, or the section's whole point is lost.
      final Size trigger = tester.getSize(theDropdown());
      expect(trigger.width, lessThanOrEqualTo(200));
      expect(
        trigger.height,
        32,
        reason: 'a wrapped value would push the medium trigger past 32',
      );
    });

    testWidgets('the listbox caps its height and rows wrap inside it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, loose: true);
      await open(tester, theDropdown());

      expect(
        tester.getRect(find.byType(ExcludeFocus)).height,
        lessThanOrEqualTo(200),
      );
      // Rows wrap where the trigger clamps — upstream's `overflowWrap` — so the
      // longest option is taller than a one-line row inside a 200px listbox.
      final double longRow = tester
          .getRect(
            find.text(
              'SuperLongName_123456789_SomeMoreStuffToMakeItLonger@fluentui.dev',
            ),
          )
          .height;
      expect(longRow, greaterThan(tester.getRect(find.text('Dog')).height));
    });
  });

  group('active option change', () {
    final DocsSection section = sectionOf(
      'components-dropdown--active-option-change',
    );

    testWidgets('the line above the field reports the committed option', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text('Cameron Evans'), findsNothing);

      expect(
        await pickDropdown<String>(tester, theDropdown(), 'Cameron Evans'),
        'Cameron Evans',
      );
      // Twice: once in the report line the demo prints above the field, once in
      // the persona the trigger now renders. A demo whose report never updated
      // would show it only once.
      expect(find.text('Cameron Evans'), findsNWidgets(2));
      expect(find.text('Away'), findsOneWidget);
    });
  });

  group('controlling open and close', () {
    final DocsSection section = sectionOf(
      'components-dropdown--controlling-open-and-close',
    );

    testWidgets('the open checkbox opens the list', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder checkbox = find.byType(FluentCheckbox);
      expect(find.text('Caterpillar'), findsNothing);

      await mouseClick(tester, checkbox);
      expect(tester.widget<FluentCheckbox>(checkbox).checked, isTrue);
      expect(
        find.text('Caterpillar'),
        findsOneWidget,
        reason:
            'the section is titled "Controlling Open And Close" and the only '
            'control on it is a checkbox labelled "open" — checking it has to '
            'open the listbox, or the knob drives nothing',
      );
    });

    testWidgets('the trigger still opens and commits on its own', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(await pickDropdown<String>(tester, theDropdown(), 'Fox'), 'Fox');
      expect(find.text('Select an animal'), findsNothing);
      await expectCleanTeardown(tester, section.id);
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

    testWidgets('a section unmounts cleanly with its popup still open', (
      WidgetTester tester,
    ) async {
      // The popup is an OverlayEntry in a different branch of the tree, so
      // unmounting mid-flight is where a leaked entry or a double dispose
      // shows up — and every one of these demos can be navigated away from
      // with the list open.
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section);
        await open(tester, find.byType(FluentDropdown<String>).first);
        await expectCleanTeardown(tester, '${section.id} with an open popup');
      }
    });
  });
}
