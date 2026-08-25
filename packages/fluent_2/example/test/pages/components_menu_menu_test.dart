import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Menu's page is 28 demos of a single widget, so what is worth proving is not
/// the widget count but the contract every section leans on: a trigger raises a
/// surface, a row runs its own callback and takes the surface down with it, an
/// inert row does neither, and a row with a submenu opens a second level instead
/// of firing. `render_test.dart` already proves the *trigger* renders — none of
/// these demos shows a single row until something is pressed, so a page that
/// mounted 28 dead buttons would pass it untouched.
void main() {
  const String page = 'components-menu-menu';

  group('default', () {
    final DocsSection section = sectionOf('components-menu-menu--default');

    testWidgets('the trigger raises the surface and a row takes it down', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(
        find.text('New '),
        findsNothing,
        reason: 'a closed menu must render none of its rows',
      );

      await openOverlay(tester, find.text('Toggle menu'));
      expect(openLevels(tester), 1);
      expect(find.text('New '), findsOneWidget);
      expect(find.text('Open File'), findsOneWidget);

      await tapAndSettle(tester, find.text('New Window'), what: 'New Window');
      expect(
        openLevels(tester),
        0,
        reason: 'activating a leaf row must close the whole chain',
      );
    });

    testWidgets('the disabled row neither fires nor dismisses', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await openOverlay(tester, find.text('Toggle menu'));

      // 'Open File' is `enabled: false`. A row that swallowed the press and
      // closed the menu anyway would look identical to a working one in a
      // screenshot, and is the failure `FluentMenuItem.selectable` exists to
      // prevent.
      await tapAndSettle(
        tester,
        find.text('Open File'),
        what: 'the disabled row',
        warnIfMissed: false,
      );
      expect(openLevels(tester), 1);
      expect(find.text('New '), findsOneWidget);
    });

    testWidgets('clicking the scenery dismisses the surface', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await openOverlay(tester, find.text('Toggle menu'));
      await dismissOverlay(tester);
      expect(openLevels(tester), 0);
    });
  });

  group('interaction', () {
    final DocsSection section = sectionOf('components-menu-menu--interaction');

    testWidgets('each row reports its own message', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text('Cut to clipboard'), findsNothing);

      await openOverlay(tester, find.text('Edit content'));
      await tapAndSettle(tester, find.text('Cut'), what: 'the Cut row');
      expect(find.text('Cut to clipboard'), findsOneWidget);

      await openOverlay(tester, find.text('Edit content'));
      await tapAndSettle(tester, find.text('Copy'), what: 'the Copy row');
      expect(find.text('Copied to clipboard'), findsOneWidget);
      expect(
        find.text('Cut to clipboard'),
        findsNothing,
        reason: 'the message is replaced, not appended',
      );

      await openOverlay(tester, find.text('Edit content'));
      await tapAndSettle(tester, find.text('Paste'), what: 'the Paste row');
      expect(find.text('Pasted from clipboard'), findsOneWidget);
    });

    testWidgets('a row commits under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The whole point of a menu is a click on a row, and a real pointer is the
      // only way to catch a surface that opens but whose rows are unreachable —
      // swallowed by a drag recogniser, or covered by the dismiss barrier the
      // root level paints behind itself.
      await mouseClick(tester, find.text('Edit content'));
      await settle(tester, frames: 10);
      expect(find.text('Copy'), findsOneWidget);

      await mouseClick(tester, find.text('Copy'));
      expect(
        find.text('Copied to clipboard'),
        findsOneWidget,
        reason: 'a mouse press on a row must invoke it, not merely dismiss',
      );
      expect(openLevels(tester), 0);
    });

    testWidgets('the arrow keys walk the rows and Enter invokes one', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await openOverlay(tester, find.text('Edit content'));

      // Focus moves *into* the surface when it opens, so the arrows reach it
      // with no click first. A menu whose rows are only pointer-reachable looks
      // identical on screen and is unusable without a mouse.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settle(tester);
      expect(
        find.text('Copied to clipboard'),
        findsOneWidget,
        reason: 'Down starts on Cut and Enter must invoke Copy',
      );
      expect(openLevels(tester), 0);
    });

    testWidgets('typeahead jumps to the row that starts with the key', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await openOverlay(tester, find.text('Edit content'));

      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settle(tester);
      expect(find.text('Pasted from clipboard'), findsOneWidget);
    });

    testWidgets('Escape closes the surface without invoking anything', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await openOverlay(tester, find.text('Edit content'));

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle(tester);
      expect(openLevels(tester), 0);
      expect(
        find.textContaining('clipboard'),
        findsNothing,
        reason: 'Escape must dismiss, never commit the active row',
      );
    });
  });

  group('menu item link navigation', () {
    testWidgets('every link row is reachable and closes the menu', (
      WidgetTester tester,
    ) async {
      final DocsSection section = sectionOf(
        'components-menu-menu--menu-item-link-navigation',
      );
      await pumpSection(tester, section);

      for (final String label in <String>[
        'Home',
        'Online shop',
        'Contact us',
        'About',
      ]) {
        await openOverlay(tester, find.text('Navigation menu'));
        expect(find.text(label), findsOneWidget);
        await tapAndSettle(tester, find.text(label), what: 'the $label row');
        expect(openLevels(tester), 0, reason: '$label left the menu open');
      }
    });
  });

  group('menu items with icons', () {
    testWidgets('every row carries its glyph', (WidgetTester tester) async {
      await pumpSection(
        tester,
        sectionOf('components-menu-menu--menu-items-with-icons'),
      );
      await openOverlay(tester, find.text('Toggle menu'));

      expect(find.byIcon(FluentIcons.cut_20_regular), findsOneWidget);
      expect(
        find.byIcon(FluentIcons.clipboard_paste_20_regular),
        findsOneWidget,
      );
      expect(find.byIcon(FluentIcons.edit_20_regular), findsOneWidget);
    });
  });

  group('aligning with icons', () {
    testWidgets('the glyphless rows keep the icon column', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-menu-menu--aligning-with-icons'),
      );
      await openOverlay(tester, find.text('Toggle menu'));

      // The section's whole claim: only 'Paste' has an icon, yet all three
      // labels line up. Without the reserved column 'Cut' and 'Edit' would start
      // 24px to the left of it, which is exactly what upstream's `hasIcons` flag
      // exists to prevent — and what this page has no flag to set.
      final double paste = tester.getRect(find.text('Paste')).left;
      expect(tester.getRect(find.text('Cut')).left, closeTo(paste, 0.5));
      expect(tester.getRect(find.text('Edit')).left, closeTo(paste, 0.5));
      expect(
        paste,
        greaterThan(tester.getRect(find.byType(FluentButton)).left + 10),
        reason: 'a reserved column must actually inset the labels',
      );
    });
  });

  group('aligning with selectable items', () {
    final DocsSection section = sectionOf(
      'components-menu-menu--aligning-with-selectable-items',
    );

    testWidgets('the selectable row reserves the column for its neighbours', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await openOverlay(tester, find.text('Toggle menu'));

      // Only one of the three rows is selectable, and it is the one that puts
      // the leading column there. Its two plain neighbours have to follow it, or
      // the list reads as two ragged left edges.
      final double checkbox = tester.getRect(find.text('Checkbox item')).left;
      final Finder plain = find.text('Menu item');
      expect(plain, findsNWidgets(2));
      for (int i = 0; i < 2; i++) {
        expect(tester.getRect(plain.at(i)).left, closeTo(checkbox, 0.5));
      }
    });

    testWidgets('pressing the selectable row ticks it, and unticks it again', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await openOverlay(tester, find.text('Toggle menu'));
      expect(find.byIcon(fluentMenuCheckmark), findsNothing);

      // Activating a row closes the menu, so the tick can only be read on the
      // way back in — which is also the only way a user ever sees it.
      await tapAndSettle(tester, find.text('Checkbox item'), what: 'the row');
      await openOverlay(tester, find.text('Toggle menu'));
      expect(find.byIcon(fluentMenuCheckmark), findsOneWidget);
      expect(
        find.byIcon(FluentIcons.cut_20_regular),
        findsNothing,
        reason: 'the checkmark shares the leading slot with the icon',
      );

      await tapAndSettle(tester, find.text('Checkbox item'), what: 'the row');
      await openOverlay(tester, find.text('Toggle menu'));
      expect(find.byIcon(fluentMenuCheckmark), findsNothing);
      expect(find.byIcon(FluentIcons.cut_20_regular), findsOneWidget);
    });
  });

  group('secondary content for menu items', () {
    testWidgets('the shortcut sits after the label, on every row', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-menu-menu--secondary-content-for-menu-items'),
      );
      await openOverlay(tester, find.text('Toggle menu'));

      const Map<String, String> rows = <String, String>{
        'New File': 'Ctrl+N',
        'New Window': 'Ctrl+Shift+N',
        'New Tab': 'Ctrl+T',
        'Open File': 'Ctrl+O',
      };
      rows.forEach((String label, String shortcut) {
        expect(
          find.text(shortcut),
          findsOneWidget,
          reason: '$label lost $shortcut',
        );
        expect(
          tester.getRect(find.text(shortcut)).left,
          greaterThan(tester.getRect(find.text(label)).right),
          reason: '$shortcut must trail $label, not overlap it',
        );
      });
    });
  });

  group('multiline items', () {
    testWidgets('the second line sits under the label, not beside it', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-menu-menu--multiline-items'),
      );
      await openOverlay(tester, find.text('Multiline items'));

      final Rect label = tester.getRect(find.text('Cut'));
      final Rect secondary = tester.getRect(find.text('Cut to clipboard'));
      expect(secondary.top, greaterThanOrEqualTo(label.bottom - 1));
      expect(secondary.left, closeTo(label.left, 0.5));
    });
  });

  group('controlling open and close', () {
    final DocsSection section = sectionOf(
      'components-menu-menu--controlling-open-and-close',
    );

    testWidgets('the Open checkbox raises the surface, and unticks again', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder checkbox = find.byType(FluentCheckbox);
      expect(tester.widget<FluentCheckbox>(checkbox).checked, isFalse);
      expect(openLevels(tester), 0);

      await tapAndSettle(tester, checkbox, what: 'the Open checkbox');
      expect(tester.widget<FluentCheckbox>(checkbox).checked, isTrue);
      expect(
        openLevels(tester),
        1,
        reason: 'the checkbox is the knob — its own value moving is not enough',
      );
      expect(find.text('New Window'), findsOneWidget);

      // The close direction cannot be driven from the checkbox: an open menu
      // paints an opaque dismiss barrier over the whole page, so the click that
      // would untick the box is spent taking the menu down instead. The page
      // says as much — `FluentMenu` is uncontrolled and has no `onOpenChange` to
      // report that dismissal back — so the round trip goes through the barrier
      // and only claims the knob returns to rest.
      await dismissOverlay(tester);
      expect(openLevels(tester), 0);
      await tapAndSettle(
        tester,
        checkbox,
        what: 'the Open checkbox',
        warnIfMissed: false,
      );
      expect(tester.widget<FluentCheckbox>(checkbox).checked, isFalse);
    });

    testWidgets('the Open checkbox drives the surface under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder checkbox = find.byType(FluentCheckbox);

      await mouseClick(tester, checkbox);
      await settle(tester, frames: 10);
      expect(tester.widget<FluentCheckbox>(checkbox).checked, isTrue);
      expect(find.text('New Window'), findsOneWidget);
    });

    testWidgets('the trigger keeps the checkbox in step', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder checkbox = find.byType(FluentCheckbox);

      await openOverlay(tester, find.text('Toggle menu'));
      expect(
        tester.widget<FluentCheckbox>(checkbox).checked,
        isTrue,
        reason: 'the trigger reports through the same state the checkbox holds',
      );
      expect(openLevels(tester), 1);
    });
  });

  group('grouping items', () {
    testWidgets('the headers caption the groups and are inert', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-menu-menu--grouping-items'),
      );
      await openOverlay(tester, find.text('Toggle menu'));

      expect(find.text('Section header'), findsNWidgets(2));
      expect(find.text('Cut'), findsNWidgets(2));

      // A header is not a command: pressing it must neither fire nor dismiss.
      // `FluentMenuItem.header` says so; only a press proves it.
      await tapAndSettle(
        tester,
        find.text('Section header'),
        what: 'a group header',
        warnIfMissed: false,
      );
      expect(openLevels(tester), 1);
    });
  });

  group('visual divider only', () {
    testWidgets('both halves of the divided list render', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-menu-menu--visual-divider-only'),
      );
      await openOverlay(tester, find.text('Toggle menu'));

      for (final String label in <String>['Cut', 'Paste', 'Edit']) {
        expect(find.text(label), findsNWidgets(2));
      }
      expect(find.text('Section header'), findsNothing);
    });
  });

  group('checkbox items', () {
    testWidgets('each row ticks independently', (WidgetTester tester) async {
      await pumpSection(
        tester,
        sectionOf('components-menu-menu--checkbox-items'),
      );

      await openOverlay(tester, find.text('Toggle menu'));
      await tapAndSettle(tester, find.text('Cut'), what: 'Cut');
      await openOverlay(tester, find.text('Toggle menu'));
      expect(find.byIcon(fluentMenuCheckmark), findsOneWidget);

      await tapAndSettle(tester, find.text('Paste'), what: 'Paste');
      await openOverlay(tester, find.text('Toggle menu'));
      expect(
        find.byIcon(fluentMenuCheckmark),
        findsNWidgets(2),
        reason: 'a checkbox group accumulates rather than replacing',
      );

      await tapAndSettle(tester, find.text('Cut'), what: 'Cut');
      await openOverlay(tester, find.text('Toggle menu'));
      expect(find.byIcon(fluentMenuCheckmark), findsOneWidget);
    });
  });

  group('switch item', () {
    testWidgets('pressing the row flips the switch in its trailing slot', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-menu-menu--switch-item'));
      await openOverlay(tester, find.text('Toggle menu'));

      final Finder toggle = find.byType(FluentSwitch);
      expect(toggle, findsOneWidget);
      expect(tester.widget<FluentSwitch>(toggle).checked, isFalse);

      // The switch is deliberately `IgnorePointer`, so the row underneath is the
      // only thing that can move it — press the switch itself and the row must
      // still take the hit. `warnIfMissed` is off because missing the switch is
      // precisely what is being asserted.
      await tapAndSettle(
        tester,
        toggle,
        what: 'the Try V2 row',
        warnIfMissed: false,
      );
      await openOverlay(tester, find.text('Toggle menu'));
      expect(
        tester.widget<FluentSwitch>(find.byType(FluentSwitch)).checked,
        isTrue,
      );

      await tapAndSettle(tester, find.text('Try V2'), what: 'the Try V2 row');
      await openOverlay(tester, find.text('Toggle menu'));
      expect(
        tester.widget<FluentSwitch>(find.byType(FluentSwitch)).checked,
        isFalse,
      );
    });
  });

  group('radio items', () {
    testWidgets('the tick moves rather than accumulating', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-menu-menu--radio-items'));

      await openOverlay(tester, find.text('Toggle menu'));
      expect(find.byIcon(fluentMenuCheckmark), findsNothing);

      await tapAndSettle(tester, find.text('Segoe'), what: 'Segoe');
      await openOverlay(tester, find.text('Toggle menu'));
      expectTickedRow(tester, 'Segoe');

      await tapAndSettle(tester, find.text('Calibri'), what: 'Calibri');
      await openOverlay(tester, find.text('Toggle menu'));
      expectTickedRow(tester, 'Calibri');
    });
  });

  group('controlled checkbox items', () {
    testWidgets('the demo opens with two rows already ticked', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-menu-menu--controlled-checkbox-items'),
      );
      await openOverlay(tester, find.text('Toggle menu'));
      expect(find.byIcon(fluentMenuCheckmark), findsNWidgets(2));

      await tapAndSettle(tester, find.text('Cut'), what: 'Cut');
      await openOverlay(tester, find.text('Toggle menu'));
      expect(find.byIcon(fluentMenuCheckmark), findsOneWidget);
      expect(find.byIcon(FluentIcons.cut_20_regular), findsOneWidget);
    });
  });

  group('controlled radio items', () {
    testWidgets('the demo opens on Calibri and moves off it', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-menu-menu--controlled-radio-items'),
      );
      await openOverlay(tester, find.text('Toggle menu'));
      expectTickedRow(tester, 'Calibri');

      await tapAndSettle(tester, find.text('Arial'), what: 'Arial');
      await openOverlay(tester, find.text('Toggle menu'));
      expectTickedRow(tester, 'Arial');
    });
  });

  group('selection group', () {
    final DocsSection section = sectionOf(
      'components-menu-menu--selection-group',
    );

    testWidgets('the checkbox half and the radio half do not interfere', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await openOverlay(tester, find.text('Toggle menu'));
      expect(find.text('Checkbox group'), findsOneWidget);
      expect(find.text('Radio group'), findsOneWidget);

      await tapAndSettle(
        tester,
        find.text('Show Menu Bar'),
        what: 'a checkbox',
      );
      await openOverlay(tester, find.text('Toggle menu'));
      expect(find.byIcon(fluentMenuCheckmark), findsOneWidget);

      await tapAndSettle(tester, find.text('Segoe'), what: 'a radio row');
      await openOverlay(tester, find.text('Toggle menu'));
      expect(
        find.byIcon(fluentMenuCheckmark),
        findsNWidgets(2),
        reason: 'picking a font must not clear the checkbox group',
      );

      await tapAndSettle(tester, find.text('Arial'), what: 'a radio row');
      await openOverlay(tester, find.text('Toggle menu'));
      expect(find.byIcon(fluentMenuCheckmark), findsNWidgets(2));
    });

    testWidgets('the disabled checkbox never joins the group', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await openOverlay(tester, find.text('Toggle menu'));

      await tapAndSettle(
        tester,
        find.text('Show Debug Panel'),
        what: 'the disabled row',
        warnIfMissed: false,
      );
      expect(openLevels(tester), 1);
      expect(find.byIcon(fluentMenuCheckmark), findsNothing);
    });
  });

  for (final String id in <String>[
    'components-menu-menu--nested-submenus',
    'components-menu-menu--nested-submenus-controlled',
  ]) {
    group(id.split('--').last, () {
      final DocsSection section = sectionOf(id);

      testWidgets('a submenu row opens a second level instead of firing', (
        WidgetTester tester,
      ) async {
        await pumpSection(tester, section);
        await openOverlay(tester, find.text('Toggle menu'));
        expect(find.byIcon(fluentMenuSubmenuChevron), findsOneWidget);

        await tapAndSettle(
          tester,
          find.text('Preferences'),
          what: 'Preferences',
        );
        await settle(tester, frames: 10);
        expect(openLevels(tester), 2);
        expect(find.text('Settings'), findsOneWidget);
        expect(
          find.text('New Window'),
          findsOneWidget,
          reason: 'the parent level stays up under its submenu',
        );
      });

      testWidgets('a submenu opens on hover alone', (
        WidgetTester tester,
      ) async {
        await pumpSection(tester, section);
        await openOverlay(tester, find.text('Toggle menu'));

        // `hoverDelay` is 500ms and nothing is pressed. A mouse is the only
        // input that can reach this at all — the whole affordance is invisible
        // to `tester.tap`.
        await hoverOver(tester, find.text('Preferences'));
        expect(openLevels(tester), 2);
        expect(find.text('Settings'), findsOneWidget);
      });

      testWidgets('hovering a sibling abandons the open submenu', (
        WidgetTester tester,
      ) async {
        await pumpSection(tester, section);
        await openOverlay(tester, find.text('Toggle menu'));
        await tapAndSettle(
          tester,
          find.text('Preferences'),
          what: 'Preferences',
        );
        await settle(tester, frames: 10);
        expect(find.text('Settings'), findsOneWidget);

        await hoverOver(tester, find.text('New Window'));
        expect(openLevels(tester), 1);
        expect(find.text('Settings'), findsNothing);
      });

      testWidgets('a third level opens and a leaf closes the whole chain', (
        WidgetTester tester,
      ) async {
        await pumpSection(tester, section);
        await openOverlay(tester, find.text('Toggle menu'));
        await tapAndSettle(
          tester,
          find.text('Preferences'),
          what: 'Preferences',
        );
        await settle(tester, frames: 10);

        await tapAndSettle(tester, find.text('Appearance'), what: 'Appearance');
        await settle(tester, frames: 10);
        expect(openLevels(tester), 3);
        expect(find.text('Centered Layout'), findsOneWidget);

        await tapAndSettle(tester, find.text('Zen'), what: 'Zen');
        expect(
          openLevels(tester),
          0,
          reason: 'a leaf three levels down still dismisses every level',
        );
      });
    });
  }

  group('nested submenus responsiveness', () {
    final DocsSection section = sectionOf(
      'components-menu-menu--nested-submenus-responsiveness',
    );

    testWidgets('the corner grip resizes the box, and back again', (
      WidgetTester tester,
    ) async {
      // `loose`, because the box's own width is the subject: a bare scroll view
      // hands its child a TIGHT width, which `SizedBox` cannot shrink below, so
      // the demo would measure 1600 wide and the horizontal half of the knob
      // would move nothing. The showroom aligns each demo instead.
      await pumpSection(tester, section, loose: true);

      // The grip is the only knob on this section, and the box is the only thing
      // it moves — read on both axes, since the trigger inside is parked at 40%
      // of the width and would drift on a box that merely repainted.
      final Finder grip = find.byWidgetPredicate(
        (Widget w) => w is SizedBox && w.width == 20 && w.height == 20,
      );
      expect(grip, findsOneWidget);
      final double menuBefore = tester.getRect(find.text('Menu')).left;
      final Rect gripBefore = tester.getRect(grip);

      // `warnIfMissed` is off because the grip is an empty `SizedBox`, which
      // never appears in a hit-test result of its own — the `GestureDetector`
      // wrapping it is what takes the drag.
      await tester.drag(grip, const Offset(120, 60), warnIfMissed: false);
      await settle(tester);
      final double widened = tester.getRect(grip).left - gripBefore.left;
      expect(widened, greaterThan(0), reason: 'the grip never widened the box');
      expect(
        tester.getRect(grip).top - gripBefore.top,
        greaterThan(0),
        reason: 'the grip never heightened the box',
      );
      expect(
        tester.getRect(find.text('Menu')).left - menuBefore,
        closeTo(widened * 0.4, 1),
        reason: 'the trigger is parked at 40% of the width and must follow it',
      );

      await tester.drag(grip, const Offset(-120, -60), warnIfMissed: false);
      await settle(tester);
      expect(tester.getRect(find.text('Menu')).left, closeTo(menuBefore, 0.5));
      expect(tester.getRect(grip), gripBefore);
    });

    testWidgets('the menu inside the box opens and nests', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await openOverlay(tester, find.text('Menu'));
      expect(find.text('Open Folder'), findsOneWidget);

      await tapAndSettle(
        tester,
        find.text('Toggle menu'),
        what: 'the nested row',
      );
      await settle(tester, frames: 10);
      expect(openLevels(tester), 2);
      expect(find.text('Open Folder'), findsNWidgets(2));
    });
  });

  group('anchor to custom target', () {
    final DocsSection section = sectionOf(
      'components-menu-menu--anchor-to-custom-target',
    );

    testWidgets('the outside button opens a surface hung off the target', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder opener = buttonAround('Open menu');
      final Finder target = buttonAround('Custom target');
      final double openerLeft = tester.getRect(opener).left;
      final double targetLeft = tester.getRect(target).left;
      expect(
        targetLeft,
        greaterThan(openerLeft + 8),
        reason: 'the two buttons must be distinguishable by position',
      );

      await openOverlay(tester, find.text('Open menu'));
      expect(find.text('New Window'), findsOneWidget);
      // The section's whole claim is that the surface hangs off the *other*
      // widget. A menu that opened under the button that was pressed would pass
      // every "did it open" assertion and still be the wrong demo. Measured on
      // the surface rather than the follower: a `RenderFollowerLayer` applies
      // its transform to its child, so its own box still reads (0, 0).
      expect(tester.getRect(menuSurface).left, closeTo(targetLeft, 0.5));
    });

    testWidgets('the custom target toggles the same surface', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await openOverlay(tester, find.text('Custom target'));
      expect(openLevels(tester), 1);
    });
  });

  group('custom trigger', () {
    testWidgets('the hand-written trigger opens the menu', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-menu-menu--custom-trigger'),
      );
      await openOverlay(tester, find.text('Custom Trigger'));
      expect(find.text('Open Folder'), findsOneWidget);
    });
  });

  group('render function trigger', () {
    testWidgets('only the chevron half of the trigger opens the menu', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-menu-menu--render-function-trigger'),
      );

      // The section exists to show that a builder can return a whole subtree of
      // which only part is the affordance. If the label opened the menu too, the
      // demo would be showing the opposite of what it says.
      await tapAndSettle(
        tester,
        find.text('Custom Trigger'),
        what: 'the label half',
      );
      expect(openLevels(tester), 0);

      await openOverlay(
        tester,
        find.byIcon(FluentIcons.chevron_down_20_regular),
      );
      expect(openLevels(tester), 1);
      expect(find.text('Open Folder'), findsOneWidget);
    });
  });

  group('memoized menu items', () {
    testWidgets('every row still ticks after the list is rebuilt', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-menu-menu--memoized-menu-items'),
      );

      await openOverlay(tester, find.text('Toggle menu'));
      await tapAndSettle(tester, find.text('Segoe'), what: 'Segoe');
      await openOverlay(tester, find.text('Toggle menu'));
      expectTickedRow(tester, 'Segoe');

      // The claim under test is that rebuilding the list does not stale the
      // untouched rows: a second pick has to land while the first is still lit.
      await tapAndSettle(tester, find.text('Arial'), what: 'Arial');
      await openOverlay(tester, find.text('Toggle menu'));
      expectTickedRow(tester, 'Segoe', of: 2);
      expectTickedRow(tester, 'Arial', of: 2);
    });
  });

  group('split menu item', () {
    testWidgets('the split row opens its submenu', (WidgetTester tester) async {
      await pumpSection(
        tester,
        sectionOf('components-menu-menu--split-menu-item'),
      );
      await openOverlay(tester, find.text('Toggle menu'));
      expect(find.byIcon(fluentMenuSubmenuChevron), findsOneWidget);

      await tapAndSettle(tester, find.text('Open'), what: 'the split row');
      await settle(tester, frames: 10);
      expect(openLevels(tester), 2);
      expect(find.text('In browser'), findsOneWidget);
      expect(find.text('In desktop app'), findsOneWidget);
    });
  });

  group('menu trigger with tooltip', () {
    final DocsSection section = sectionOf(
      'components-menu-menu--menu-trigger-with-tooltip',
    );

    testWidgets('hovering the trigger raises the tooltip', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text('This is a tooltip'), findsNothing);

      await hoverOver(tester, find.text('Toggle menu'));
      expect(
        find.text('This is a tooltip'),
        findsWidgets,
        reason: 'the tooltip is the only thing this section adds',
      );
    });

    testWidgets('the tooltip does not cost the trigger its menu', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await openOverlay(tester, find.text('Toggle menu'));
      expect(find.text('Open Folder'), findsOneWidget);
    });
  });

  for (final String id in <String>[
    'components-menu-menu--motion-custom',
    'components-menu-menu--motion-disabled',
  ]) {
    group(id.split('--').last, () {
      testWidgets('the surface arrives and settles opaque and in place', (
        WidgetTester tester,
      ) async {
        await pumpSection(tester, sectionOf(id));
        await openOverlay(tester, find.text('Toggle menu'));
        expect(find.text('New'), findsOneWidget);

        // The entrance is a fade paired with a 10px slide. Once it has run, the
        // surface must be fully opaque — a demo stuck mid-tween looks fine in a
        // screenshot taken at the wrong moment and is unusable in the browser.
        final Opacity fade = tester.widget<Opacity>(
          find
              .descendant(
                of: find.byType(CompositedTransformFollower),
                matching: find.byType(Opacity),
              )
              .first,
        );
        expect(fade.opacity, closeTo(1, 0.001));
      });
    });
  }

  group('every section', () {
    testWidgets('opens its surface from its own trigger', (
      WidgetTester tester,
    ) async {
      for (final DocsSection section in sectionsOf(page)) {
        final Finder? trigger = _triggers[section.id];
        expect(
          trigger,
          isNotNull,
          reason: 'no trigger recorded for ${section.id}',
        );
        await pumpSection(tester, section);
        expect(
          openLevels(tester),
          0,
          reason: '${section.id} opened unprompted',
        );

        await openOverlay(tester, trigger!);
        expect(
          openLevels(tester),
          1,
          reason: "${section.id}'s trigger raised no surface",
        );
        await dismissOverlay(tester);
        expect(
          openLevels(tester),
          0,
          reason: '${section.id} could not be dismissed',
        );
      }
    });

    testWidgets('unmounts without throwing, open or closed', (
      WidgetTester tester,
    ) async {
      for (final DocsSection section in sectionsOf(page)) {
        // Unmounted with the chain still up: an OverlayEntry, a focus node and a
        // hover Timer are all live at that moment, and a leak in any of them
        // only ever surfaces here.
        await pumpSection(tester, section);
        await openOverlay(tester, _triggers[section.id]!);
        await expectCleanTeardown(tester, section.id);
      }
    });
  });
}

/// What opens each section's menu.
///
/// Almost every section hangs its menu off a labelled button, so the label is
/// the trigger. Render Function Trigger is the deliberate exception: it splits
/// the label off the affordance, and only the chevron beside it opens anything.
final Map<String, Finder> _triggers = <String, Finder>{
  'components-menu-menu--default': find.text('Toggle menu'),
  'components-menu-menu--interaction': find.text('Edit content'),
  'components-menu-menu--menu-item-link-navigation': find.text(
    'Navigation menu',
  ),
  'components-menu-menu--menu-items-with-icons': find.text('Toggle menu'),
  'components-menu-menu--aligning-with-icons': find.text('Toggle menu'),
  'components-menu-menu--aligning-with-selectable-items': find.text(
    'Toggle menu',
  ),
  'components-menu-menu--secondary-content-for-menu-items': find.text(
    'Toggle menu',
  ),
  'components-menu-menu--multiline-items': find.text('Multiline items'),
  'components-menu-menu--controlling-open-and-close': find.text('Toggle menu'),
  'components-menu-menu--grouping-items': find.text('Toggle menu'),
  'components-menu-menu--visual-divider-only': find.text('Toggle menu'),
  'components-menu-menu--checkbox-items': find.text('Toggle menu'),
  'components-menu-menu--switch-item': find.text('Toggle menu'),
  'components-menu-menu--radio-items': find.text('Toggle menu'),
  'components-menu-menu--controlled-checkbox-items': find.text('Toggle menu'),
  'components-menu-menu--controlled-radio-items': find.text('Toggle menu'),
  'components-menu-menu--selection-group': find.text('Toggle menu'),
  'components-menu-menu--nested-submenus': find.text('Toggle menu'),
  'components-menu-menu--nested-submenus-controlled': find.text('Toggle menu'),
  'components-menu-menu--nested-submenus-responsiveness': find.text('Menu'),
  'components-menu-menu--anchor-to-custom-target': find.text('Custom target'),
  'components-menu-menu--custom-trigger': find.text('Custom Trigger'),
  'components-menu-menu--render-function-trigger': find.byIcon(
    FluentIcons.chevron_down_20_regular,
  ),
  'components-menu-menu--memoized-menu-items': find.text('Toggle menu'),
  'components-menu-menu--split-menu-item': find.text('Toggle menu'),
  'components-menu-menu--menu-trigger-with-tooltip': find.text('Toggle menu'),
  'components-menu-menu--motion-custom': find.text('Toggle menu'),
  'components-menu-menu--motion-disabled': find.text('Toggle menu'),
};

/// How many levels of the menu chain are up: 0 closed, 1 the root, 2 a submenu.
///
/// Each level is one [OverlayEntry] anchored with a [CompositedTransformFollower],
/// so counting followers counts levels — and unlike a text search it can tell a
/// submenu apart from a root menu that happens to repeat its parent's labels.
int openLevels(WidgetTester tester) =>
    find.byType(CompositedTransformFollower).evaluate().length;

/// The button whose label reads [label].
Finder buttonAround(String label) => find
    .ancestor(of: find.text(label), matching: find.byType(FluentButton))
    .first;

/// The card the open root menu draws its rows on.
///
/// The first [DecoratedBox] under the follower is the surface itself; the rows'
/// own boxes are deeper, so pre-order puts this one first.
final Finder menuSurface = find
    .descendant(
      of: find.byType(CompositedTransformFollower),
      matching: find.byType(DecoratedBox),
    )
    .first;

/// Asserts [of] rows are ticked and that one of them is the row named [label].
///
/// Counting checkmarks alone would pass a radio group that ticked the wrong row
/// — the failure that actually looks broken on screen — so the tick is matched
/// back to its label by the row it shares a centre line with.
void expectTickedRow(WidgetTester tester, String label, {int of = 1}) {
  final Finder ticks = find.byIcon(fluentMenuCheckmark);
  expect(ticks, findsNWidgets(of), reason: 'expected $of ticked rows');
  // Vertical overlap rather than a pixel tolerance: the 16px tick is centred in
  // a 20px slot and the label's own box is 24 tall, so their centres are two
  // pixels apart on a correctly rendered row — while consecutive rows are 38
  // apart, which is what makes this unambiguous.
  final Rect row = tester.getRect(find.text(label));
  expect(
    List<int>.generate(of, (int i) => i).any((int i) {
      final double dy = tester.getRect(ticks.at(i)).center.dy;
      return dy >= row.top && dy <= row.bottom;
    }),
    isTrue,
    reason: 'no tick sits on the "$label" row',
  );
}
