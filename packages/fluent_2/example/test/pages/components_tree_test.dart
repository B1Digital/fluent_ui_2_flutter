import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Tree's page is twenty-three sections and almost every one is a claim about
/// which rows are *visible*: an open set, a default open set, a controlled one,
/// a lazily loaded subtree, a reordered one. `FluentTree` builds only the rows
/// its open set makes visible and keys each one by its value, so "is this row in
/// the tree" is both the honest reading of what a user can see and a finder that
/// does not go stale when a label repeats — and eight of these sections repeat
/// their labels deliberately.
void main() {
  const String page = 'components-tree';

  group('default', () {
    final DocsSection section = sectionOf('components-tree--default');

    testWidgets('a real mouse click opens a branch and closes it again', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Uncontrolled and nothing open: three roots, no descendants.
      expect(treeRow('1'), findsOneWidget);
      expect(treeRow('1-1'), findsNothing);

      await mouseClick(tester, find.text('level 1, item 1'));
      for (final String value in <String>['1-1', '1-2', '1-3']) {
        expect(treeRow(value), findsOneWidget, reason: '$value stayed hidden');
      }
      expect(
        treeRow('2-1'),
        findsNothing,
        reason: 'opening one branch must not open its sibling',
      );

      await tapAndSettle(tester, find.text('level 1, item 1'));
      expect(treeRow('1-1'), findsNothing);
    });

    testWidgets('a leaf draws no chevron and a branch turns its own', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Two branches and one leaf at the root, so two chevrons.
      expect(chevrons, findsNWidgets(2));
      expect(
        find.descendant(of: treeRow('3'), matching: chevrons),
        findsNothing,
        reason: 'level 1, item 3 has no children to open',
      );

      final double closed = chevronTurn(
        tester,
        find.descendant(of: treeRow('1'), matching: chevrons),
      );
      await tapAndSettle(tester, find.text('level 1, item 1'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        chevronTurn(
          tester,
          find.descendant(of: treeRow('1'), matching: chevrons),
        ),
        isNot(closeTo(closed, 0.01)),
        reason: 'the chevron is the only thing that says a branch is open',
      );
      expect(
        chevronTurn(
          tester,
          find.descendant(of: treeRow('2'), matching: chevrons),
        ),
        closeTo(closed, 0.01),
        reason: 'the sibling branch is still closed and must not have turned',
      );
    });
  });

  group('size', () {
    final DocsSection section = sectionOf('components-tree--size');

    testWidgets('the small tree draws shorter rows in a smaller type', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.byType(FluentTree), findsNWidgets(2));

      final double small = tester.getRect(rowInTree(0, '1')).height;
      final double medium = tester.getRect(rowInTree(1, '1')).height;
      expect(
        small,
        lessThan(medium),
        reason: 'Figma gives a small row 24 against medium\'s 32',
      );

      final double? smallText = textStyleOf(
        tester,
        find.text('Small size tree'),
      )?.fontSize;
      expect(smallText, isNotNull);
      expect(
        textStyleOf(tester, find.text('Medium size tree'))?.fontSize,
        greaterThan(smallText!),
        reason: 'the size axis is caption1 against body1, not padding alone',
      );
    });

    testWidgets('both trees open on their own', (WidgetTester tester) async {
      await pumpSection(tester, section);

      await mouseClick(tester, find.text('Small size tree'));
      expect(find.descendant(of: tree(0), matching: treeRow('1-1')), findsOne);
      expect(
        find.descendant(of: tree(1), matching: treeRow('1-1')),
        findsNothing,
        reason: 'the two trees share no open set',
      );
    });
  });

  group('appearance', () {
    final DocsSection section = sectionOf('components-tree--appearance');

    testWidgets('the three appearances hover to three different fills', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // At rest all three resolve the fully transparent stop of their family,
      // which is the point: the tree shows the surface behind it until it is
      // hovered. So the appearance axis is only readable under a pointer, and a
      // synthetic tap would never see it.
      final List<Color?> hovered = <Color?>[
        for (int i = 0; i < 3; i++)
          await whileHovering(
            tester,
            rowInTree(i, '1'),
            () => decorationUnder(tester, rowInTree(i, '1')).color,
          ),
      ];
      expect(
        hovered.toSet(),
        hasLength(3),
        reason: 'subtle, subtle-alpha and transparent hover apart: $hovered',
      );
    });

    testWidgets('the persona trees carry an avatar in the leading slot', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.byType(FluentTree), findsNWidgets(6));

      // Trees 0..2 are TreeItemLayout and trees 3..5 are the persona variant,
      // whose media slot lands in FluentTreeItem.icon.
      expect(
        find.descendant(of: tree(0), matching: find.byType(FluentAvatar)),
        findsNothing,
      );
      expect(
        find.descendant(of: tree(3), matching: find.byType(FluentAvatar)),
        findsOneWidget,
      );

      await mouseClick(tester, find.text('Default appearance').last);
      expect(
        find.descendant(of: tree(3), matching: find.byType(FluentAvatar)),
        findsNWidgets(3),
        reason: 'the two children carry avatars of their own',
      );
    });
  });

  group('layouts', () {
    final DocsSection section = sectionOf('components-tree--layouts');

    testWidgets('the persona layout adds a description and can drop its media', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(
        find.descendant(of: tree(0), matching: find.byType(FluentPersona)),
        findsNothing,
        reason: 'the first tree is the plain TreeItemLayout',
      );

      await mouseClick(tester, find.text('Tree using TreeItemPersonaLayout'));
      expect(find.text('with description'), findsOneWidget);
      expect(find.text('square shape media'), findsOneWidget);
      expect(find.text('without media'), findsOneWidget);

      // `presenceOnly` with no status is how a persona renders "without media":
      // the media slot resolves to nothing at all, not to an empty avatar.
      expect(
        find.descendant(
          of: treeRow('1-1'),
          matching: find.byType(FluentAvatar),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: treeRow('1-3'),
          matching: find.byType(FluentAvatar),
        ),
        findsNothing,
      );
    });
  });

  group('expand icon', () {
    final DocsSection section = sectionOf('components-tree--expand-icon');

    testWidgets('the plus/minus glyph tracks the controlled open set', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(find.byIcon(FluentIcons.add_square_16_regular), findsNWidgets(2));
      expect(find.byIcon(FluentIcons.subtract_square_16_regular), findsNothing);

      await mouseClick(tester, find.text('level 1, item 1'));
      expect(treeRow('tree-item-3'), findsOneWidget);
      expect(
        find.descendant(
          of: treeRow('tree-item-2'),
          matching: find.byIcon(FluentIcons.subtract_square_16_regular),
        ),
        findsOneWidget,
        reason: 'the opened branch swaps its own glyph',
      );
      expect(
        find.descendant(
          of: treeRow('tree-item-1'),
          matching: find.byIcon(FluentIcons.add_square_16_regular),
        ),
        findsOneWidget,
        reason: 'the closed branch keeps the plus',
      );

      await tapAndSettle(tester, find.text('level 1, item 1'));
      expect(treeRow('tree-item-3'), findsNothing);
      expect(find.byIcon(FluentIcons.subtract_square_16_regular), findsNothing);
    });
  });

  group('icon before and after', () {
    final DocsSection section = sectionOf(
      'components-tree--icon-before-and-after',
    );

    testWidgets('the leading icon precedes the label and the trailing one ends '
        'the row', (WidgetTester tester) async {
      await pumpSection(tester, section);

      final Rect before = tester.getRect(
        find.descendant(
          of: treeRow('1'),
          matching: find.byIcon(FluentIcons.image_20_regular),
        ),
      );
      final Rect label = tester.getRect(
        find.descendant(
          of: treeRow('1'),
          matching: find.text('level 1, item 1'),
        ),
      );
      final Rect after = tester.getRect(
        find.descendant(
          of: treeRow('1'),
          matching: find.byIcon(FluentIcons.lock_closed_20_regular),
        ),
      );
      expect(before.right, lessThanOrEqualTo(label.left));
      expect(label.right, lessThanOrEqualTo(after.left));

      await mouseClick(tester, find.text('level 1, item 2'));
      expect(
        find.descendant(
          of: treeRow('2-1'),
          matching: find.byIcon(FluentIcons.warning_20_regular),
        ),
        findsOneWidget,
        reason: 'the child row carries its own icon-after',
      );
    });
  });

  group('aside', () {
    final DocsSection section = sectionOf('components-tree--aside');

    testWidgets('the aside rides on the row and follows it open', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Both roots are important and both carry a count.
      expect(find.byIcon(FluentIcons.important_16_regular), findsNWidgets(2));
      expect(find.byType(FluentBadge), findsNWidgets(2));
      expect(
        find.descendant(of: treeRow('1'), matching: find.text('3')),
        findsOneWidget,
      );

      await mouseClick(tester, find.text('level 1, item 1'));
      expect(
        find.descendant(
          of: treeRow('1-1'),
          matching: find.byIcon(FluentIcons.important_16_regular),
        ),
        findsOneWidget,
        reason: 'child 1-1 is important and has no count',
      );
      expect(
        find.descendant(of: treeRow('1-1'), matching: find.byType(FluentBadge)),
        findsNothing,
      );
      expect(
        find.descendant(of: treeRow('1-2'), matching: find.text('2')),
        findsOneWidget,
      );
    });
  });

  group('actions', () {
    final DocsSection section = sectionOf('components-tree--actions');

    testWidgets('the overflow menu opens without opening the row under it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(
        find.byIcon(FluentIcons.more_horizontal_20_regular),
        findsNWidgets(2),
      );

      // A real press, because the actions slot is a pointer affordance sitting
      // inside a row that is itself one big hit target: the inner button has to
      // win the gesture arena, or the tree opens instead of the menu.
      await mouseClick(
        tester,
        find.descendant(
          of: treeRow('item 1'),
          matching: find.byIcon(FluentIcons.more_horizontal_20_regular),
        ),
      );

      expect(find.text('New Window'), findsOneWidget);
      expect(
        treeRow('item 1-1'),
        findsNothing,
        reason: 'the press belonged to the button, not to the row behind it',
      );

      // The disabled row is upstream's, and `enabled: false` has to reach the
      // paint rather than only swallowing the press.
      expect(
        textStyleOf(tester, find.text('Open File'))?.color,
        isNot(textStyleOf(tester, find.text('New Window'))?.color),
      );
    });

    testWidgets('the row still opens when the click misses the actions', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await mouseClick(tester, find.text('item 1'));
      expect(treeRow('item 1-1'), findsOneWidget);
      expect(
        find.descendant(
          of: treeRow('item 1-1'),
          matching: find.byIcon(FluentIcons.edit_20_regular),
        ),
        findsOneWidget,
        reason: 'every row composes the same actions',
      );
    });
  });

  group('navigation mode tree grid', () {
    final DocsSection section = sectionOf(
      'components-tree--navigation-mode-tree-grid',
    );

    testWidgets('the arrow keys walk the rows and open what they land on', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // A pointer press focuses the row as well as toggling it, which is what
      // puts the keyboard in reach without a synthetic focus request.
      await tapAndSettle(tester, find.text('item 1'));
      expect(treeRow('item 1-1'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await settle(tester);
      expect(
        treeRow('item 1-1-1'),
        findsOneWidget,
        reason: 'Down moved onto item 1-1 and Right had to expand it',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await settle(tester);
      expect(
        treeRow('item 1-1-1'),
        findsNothing,
        reason: 'Left collapses the branch the focus is standing on',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await settle(tester);
      expect(
        treeRow('item 1-1'),
        findsNothing,
        reason: 'Left again walks to the parent and then closes it',
      );
    });
  });

  group('default open', () {
    final DocsSection section = sectionOf('components-tree--default-open');

    testWidgets('the three named branches start open and nothing else does', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(treeRow('1-1'), findsOneWidget);
      expect(
        treeRow('2-1-1'),
        findsOneWidget,
        reason: 'the default set names a branch two levels down as well',
      );

      // A default is a seed, not a pin: the tree is still uncontrolled.
      await mouseClick(tester, find.text('level 1, item 1'));
      expect(treeRow('1-1'), findsNothing);
      expect(treeRow('2-1-1'), findsOneWidget);
    });
  });

  group('open items controlled', () {
    final DocsSection section = sectionOf(
      'components-tree--open-items-controlled',
    );

    testWidgets('onOpenChange is what opens the rows', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(treeRow('1-1'), findsNothing);

      // The tree never changes a controlled set itself, so a row that opens
      // here proves the callback round trip landed.
      await mouseClick(tester, find.text('level 1, item 1'));
      expect(treeRow('1-1'), findsOneWidget);

      await tapAndSettle(tester, find.text('level 1, item 2'));
      expect(treeRow('tree-item-3'), findsOneWidget);
      expect(
        treeRow('1-1'),
        findsOneWidget,
        reason: 'the set accumulates: opening a second branch keeps the first',
      );
    });
  });

  group('open item controlled', () {
    final DocsSection section = sectionOf(
      'components-tree--open-item-controlled',
    );

    testWidgets('the seeded branch starts open and still closes', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(treeRow('1-1'), findsOneWidget);
      expect(treeRow('tree-item-3'), findsNothing);

      await mouseClick(tester, find.text('level 1, item 1'));
      expect(treeRow('1-1'), findsNothing);

      await tapAndSettle(tester, find.text('level 1, item 1'));
      expect(treeRow('1-1'), findsOneWidget);
    });
  });

  group('customizing interaction', () {
    final DocsSection section = sectionOf(
      'components-tree--customizing-interaction',
    );

    testWidgets('a row reports through onInvoke as well as opening', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text('click on item'), findsNothing);

      await mouseClick(tester, find.text('level 1, item 1'));
      expect(
        find.text('click on item'),
        findsOneWidget,
        reason: 'onInvoke is what stands in for upstream\'s alert()',
      );
      expect(
        treeRow('1-1'),
        findsOneWidget,
        reason: 'the same press must still open the branch',
      );
    });
  });

  group('inline styling tree item level', () {
    final DocsSection section = sectionOf(
      'components-tree--inline-styling-tree-item-level',
    );

    testWidgets('every level is inset by the style\'s own indent', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text('level 2, item 1'), findsNothing);

      for (int level = 1; level < 12; level++) {
        await tapAndSettle(
          tester,
          find.text('level $level, item 1'),
          what: 'level $level',
        );
      }

      // Twelve levels, past the ten upstream generates static styles for, and
      // `FluentTreeItemStyle.indent` is overridden to 12 — so a tree that fell
      // back to the 24 default, or stopped indenting past some level, is what
      // this catches.
      final List<double> lefts = <double>[
        for (int level = 1; level <= 12; level++)
          tester.getRect(find.text('level $level, item 1')).left,
      ];
      for (int i = 1; i < lefts.length - 1; i++) {
        expect(
          lefts[i] - lefts[i - 1],
          closeTo(12, 0.5),
          reason: 'level ${i + 1} is not one indent past level $i: $lefts',
        );
      }
      // The twelfth row is the only leaf in the chain, and a leaf takes one
      // step MORE than a branch at its level because it has no chevron column
      // to fill — upstream's `calc(var(--level) * XXL)` against a branch's
      // `calc((var(--level) - 1) * XXL)`. So the last gap is two steps, and a
      // tree that indented leaves like branches would leave it at one.
      expect(
        lefts.last - lefts[lefts.length - 2],
        closeTo(24, 0.5),
        reason: 'the leaf ramp is one step deeper than the branch ramp: $lefts',
      );
    });
  });

  group('flat tree', () {
    final DocsSection section = sectionOf('components-tree--flat-tree');

    testWidgets('the flattened items still nest under their parents', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(treeRow('1-1'), findsNothing);

      await mouseClick(tester, find.text('Item 1, level 1').first);
      expect(treeRow('1-1'), findsOneWidget);
      expect(treeRow('1-2'), findsOneWidget);
      expect(
        treeRow('2-1'),
        findsNothing,
        reason: 'the second root is a separate branch',
      );
    });
  });

  group('use headless flat tree', () {
    final DocsSection section = sectionOf(
      'components-tree--use-headless-flat-tree',
    );

    testWidgets('the parentValue chain folds into four real levels', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The flat list is the point of the story, so the assertion is that its
      // `parentValue` links became depth: 2 owns 2-1 owns 2-1-1 owns 2-1-1-1.
      await mouseClick(tester, find.text('Level 1, item 2'));
      await tapAndSettle(tester, find.text('Level 2, item 1'));
      await tapAndSettle(tester, find.text('Level 3, item 1'));

      expect(treeRow('2-1-1-1'), findsOneWidget);
      final double depth1 = tester.getRect(find.text('Level 1, item 2')).left;
      final double depth4 = tester.getRect(find.text('Level 4, item 1')).left;
      expect(
        depth4,
        greaterThan(depth1),
        reason: 'aria-level falls out of the structure as a real indent',
      );
    });
  });

  group('selection', () {
    final DocsSection section = sectionOf('components-tree--selection');

    testWidgets('the checkboxes accumulate a multi-selection', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(checkedIn(tester, treeRow('1-2')), isTrue);
      expect(checkedIn(tester, treeRow('1-1')), isFalse);

      // A real press: the selector sits inside a row that is one hit target, so
      // the checkbox has to win the arena the way the actions slot does.
      await mouseClick(
        tester,
        find.descendant(
          of: treeRow('1-1'),
          matching: find.byType(FluentCheckbox),
        ),
      );
      expect(checkedIn(tester, treeRow('1-1')), isTrue);
      expect(
        checkedIn(tester, treeRow('1-2')),
        isTrue,
        reason: 'multiselect adds to the set rather than replacing it',
      );

      await mouseClick(
        tester,
        find.descendant(
          of: treeRow('1-2'),
          matching: find.byType(FluentCheckbox),
        ),
      );
      expect(checkedIn(tester, treeRow('1-2')), isFalse);
      expect(checkedIn(tester, treeRow('1-1')), isTrue);
    });

    testWidgets('a selected row paints the Selected ramp', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(
        decorationUnder(tester, treeRow('1-2')).color,
        isNot(decorationUnder(tester, treeRow('1-1')).color),
        reason: 'selection is a design state, not only a checkbox glyph',
      );
    });
  });

  group('manipulation', () {
    final DocsSection section = sectionOf('components-tree--manipulation');

    testWidgets('the add row appends and the delete action removes', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(treeRow('1-3'), findsNothing);

      await mouseClick(tester, find.text('Add new item').first);
      expect(
        treeRow('1-3'),
        findsOneWidget,
        reason: 'the add row invokes with 1-btn and numbers off the last child',
      );
      expect(find.text('New item 1-3'), findsOneWidget);
      expect(
        treeRow('2-2'),
        findsNothing,
        reason: 'the two subtrees are manipulated independently',
      );

      await mouseClick(
        tester,
        find.descendant(
          of: treeRow('1-1'),
          matching: find.byIcon(FluentIcons.delete_20_regular),
        ),
      );
      expect(treeRow('1-1'), findsNothing);
      expect(find.text('Item 1-1'), findsNothing);
      expect(
        treeRow('1-2'),
        findsOneWidget,
        reason: 'only the row whose button was pressed goes',
      );
    });
  });

  group('lazy loading', () {
    final DocsSection section = sectionOf('components-tree--lazy-loading');

    testWidgets('opening a branch shows a spinner and then the rows', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.byType(FluentSpinner), findsNothing);

      await tester.tap(find.text('People'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.byType(FluentSpinner),
        findsOneWidget,
        reason: 'the spinner stands in for the expand icon while in flight',
      );
      expect(
        find.text('...'),
        findsOneWidget,
        reason: 'the placeholder row holds the branch open until data arrives',
      );

      // Never pumpAndSettle here: FluentSpinner animates forever, so a settle
      // would hang rather than wait. The fetch is a one second Future, so the
      // clock is advanced past it explicitly.
      await tester.pump(const Duration(milliseconds: 1100));
      expect(find.byType(FluentSpinner), findsNothing);
      expect(find.text('People 1'), findsOneWidget);
      expect(find.text('People 3'), findsOneWidget);
      expect(find.text('...'), findsNothing);
      expect(
        treeRow('Planet'),
        findsOneWidget,
        reason: 'the sibling branches are untouched and still closed',
      );
      expectClean(tester, 'the lazy load');
    });
  });

  group('infinite scrolling', () {
    final DocsSection section = sectionOf(
      'components-tree--infinite-scrolling',
    );

    testWidgets('reaching the end of the box pages in ten more people', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text('Person 10'), findsOneWidget);
      expect(find.text('Person 11'), findsNothing);

      // The inner 400px viewport, not the page's own scroll view: the page-in
      // hangs off this one's ScrollNotification.
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -3000));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));

      expect(
        find.text('Person 11'),
        findsOneWidget,
        reason: 'hitting maxScrollExtent has to fetch the next page',
      );
      expect(find.text('Person 20'), findsOneWidget);
      expectClean(tester, 'the page-in');
    });
  });

  group('virtualization', () {
    final DocsSection section = sectionOf('components-tree--virtualization');

    testWidgets('a closed branch costs nothing and an open one is all there', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(treeRow('flatTreeItem_lvl-1_item-1--child:0'), findsNothing);

      await tapAndSettle(tester, find.text('Level 1, item 1'));
      expect(treeRow('flatTreeItem_lvl-1_item-1--child:0'), findsOneWidget);
      expect(
        treeRow('flatTreeItem_lvl-1_item-1--child:299'),
        findsOneWidget,
        reason: 'all 300 rows are real; the 300x300 viewport just scrolls them',
      );
      expect(
        treeRow('flatTreeItem_lvl-1_item-2--child:0'),
        findsNothing,
        reason: 'the second branch is still closed and costs nothing',
      );
    });
  });

  group('drag and drop', () {
    final DocsSection section = sectionOf('components-tree--drag-and-drop');

    testWidgets('the move actions reorder the leaves', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(labelOfRow(tester, '1-1'), 'Sortable item 1');
      expect(labelOfRow(tester, '1-2'), 'Sortable item 2');
      expect(
        moveButton(tester, '1-1', FluentIcons.arrow_up_20_regular).onPressed,
        isNull,
        reason: 'the first leaf has nowhere to move up to',
      );
      expect(
        moveButton(tester, '1-8', FluentIcons.arrow_down_20_regular).onPressed,
        isNull,
        reason: 'the last leaf has nowhere to move down to',
      );

      await mouseClick(
        tester,
        find.descendant(
          of: treeRow('1-1'),
          matching: find.byIcon(FluentIcons.arrow_down_20_regular),
        ),
      );
      expect(labelOfRow(tester, '1-1'), 'Sortable item 2');
      expect(labelOfRow(tester, '1-2'), 'Sortable item 1');

      // Round trip: the item that just moved down moves back up.
      await mouseClick(
        tester,
        find.descendant(
          of: treeRow('1-2'),
          matching: find.byIcon(FluentIcons.arrow_up_20_regular),
        ),
      );
      expect(labelOfRow(tester, '1-1'), 'Sortable item 1');
      expect(labelOfRow(tester, '1-2'), 'Sortable item 2');
    });
  });

  group('motion custom', () {
    final DocsSection section = sectionOf('components-tree--motion-custom');

    testWidgets('the three teams open onto their personas', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.byType(FluentPersona), findsNothing);

      await mouseClick(tester, find.text('Team A'));
      expect(find.byType(FluentPersona), findsNWidgets(3));
      expect(find.text('Kevin Sturgis'), findsOneWidget);

      await tapAndSettle(tester, find.text('Team C'));
      expect(
        find.byType(FluentPersona),
        findsNWidgets(9),
        reason: 'Team C carries all six, and the open set accumulates',
      );

      await tapAndSettle(tester, find.text('Team A'));
      await tapAndSettle(tester, find.text('Team C'));
      expect(find.byType(FluentPersona), findsNothing);
    });

    testWidgets('the motion knobs drive the subtree they claim to', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Both controls are live — the label under the slider tracks it and the
      // switch flips — so the question is only whether the tree hears them.
      await dropSliderAt(tester, find.byType(FluentSlider), 1);
      expect(find.text('Duration: 2000ms'), findsOneWidget);
      final Finder switchFinder = find.byType(FluentSwitch);
      expect(tester.widget<FluentSwitch>(switchFinder).checked, isTrue);

      final double closed = tester.getRect(find.byType(FluentTree)).height;
      await tester.tap(find.text('Team A'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      final double partWay = tester.getRect(find.byType(FluentTree)).height;
      await tester.pump(const Duration(seconds: 3));
      final double settled = tester.getRect(find.byType(FluentTree)).height;

      expect(settled, greaterThan(closed));
      expect(
        partWay,
        lessThan(settled),
        reason:
            'the duration slider is upstream\'s collapseMotion.duration: at '
            '2000ms the subtree cannot already be at its full height 150ms in. '
            'FluentTree exposes no motion hook, so the rows appear instantly '
            'and neither the slider nor the animate-opacity switch is heard.',
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

/// The row `FluentTree` built for [value].
///
/// Every row is keyed by its item's value, which is the only finder that stays
/// honest on this page: eight sections repeat their labels across branches on
/// purpose, so `find.text` would match two rows in half of them.
Finder treeRow(Object value) => find.byKey(ValueKey<Object>(value));

/// The [index]-th tree in the demo, in tree order.
Finder tree(int index) => find.byType(FluentTree).at(index);

/// The row for [value] inside the [index]-th tree, for the sections that render
/// several trees over the same values.
Finder rowInTree(int index, Object value) =>
    find.descendant(of: tree(index), matching: treeRow(value));

/// Every tree chevron in the tree, in order.
Finder get chevrons => find.byIcon(FluentIcons.chevron_right_12_regular);

/// Whether the selection control inside [row] is ticked.
bool? checkedIn(WidgetTester tester, Finder row) => tester
    .widget<FluentCheckbox>(
      find.descendant(of: row, matching: find.byType(FluentCheckbox)),
    )
    .checked;

/// The text the row keyed [value] is currently labelled with.
///
/// The reorder sections keep the row keys fixed and move the *labels* between
/// them, so this pairing is the only thing that can tell a reorder from a
/// rebuild that changed nothing.
String? labelOfRow(WidgetTester tester, Object value) => tester
    .widget<Text>(
      find.descendant(of: treeRow(value), matching: find.byType(Text)).first,
    )
    .data;

/// The reorder button carrying [icon] inside the row keyed [value].
FluentButton moveButton(WidgetTester tester, Object value, IconData icon) =>
    tester.widget<FluentButton>(
      find
          .ancestor(
            of: find.descendant(
              of: treeRow(value),
              matching: find.byIcon(icon),
            ),
            matching: find.byType(FluentButton),
          )
          .first,
    );
