import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// DataGrid's fifteen sections have no dropdowns and no switches: every one of
/// them is driven by the grid itself — a sort control in a header, a checkbox
/// or radio in the selection column, a row that toggles when its body is
/// pressed, a header that opens a menu on a right-click.
///
/// So the assertions here are almost all about *rows moving*. A sort control
/// whose arrow flips while the rows stay put is the exact failure this page can
/// have, and it is invisible to a mounting test — as is the one this page's
/// Default and Custom Row Id sections are actually about: a selection keyed on
/// the data rather than on the row index, which has to survive a re-sort.
void main() {
  const String page = 'components-datagrid';

  group('default', () {
    final DocsSection section = sectionOf('components-datagrid--default');

    testWidgets('the File header sorts, then flips, under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(_fileOrder(tester), _declared);

      await mouseClick(tester, _sortControls().at(0));
      expect(
        _fileOrder(tester),
        <String>[
          'Meeting notes',
          'Purchase order',
          'Thursday presentation',
          'Training recording',
        ],
        reason: 'the first press must order the rows, not only draw an arrow',
      );

      await tapAndSettle(tester, _sortControls().at(0), what: 'the File sort');
      expect(
        _fileOrder(tester),
        <String>[
          'Training recording',
          'Thursday presentation',
          'Purchase order',
          'Meeting notes',
        ],
        reason: 'a second press on the same column reverses it',
      );
    });

    testWidgets('the arrow follows the direction it sorted in', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(
        find.byIcon(FluentIcons.arrow_down_20_regular),
        findsNothing,
        reason: 'nothing is sorted, so no column may claim descending',
      );

      await tapAndSettle(tester, _sortControls().at(0), what: 'the File sort');
      expect(_labelOf(tester, 0), 'Sorted ascending');
      expect(find.byIcon(FluentIcons.arrow_down_20_regular), findsNothing);

      await tapAndSettle(tester, _sortControls().at(0), what: 'the File sort');
      expect(_labelOf(tester, 0), 'Sorted descending');
      expect(
        find.byIcon(FluentIcons.arrow_down_20_regular),
        findsOneWidget,
        reason: 'only the sorted column draws the down arrow',
      );

      await tapAndSettle(
        tester,
        _sortControls().at(1),
        what: 'the Author sort',
      );
      expect(
        _labelOf(tester, 0),
        'Sort',
        reason: 'moving the sort must release the column that had it',
      );
      expect(_labelOf(tester, 1), 'Sorted ascending');
    });

    testWidgets('a selected row keeps its tick across a re-sort', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The whole point of the section's `getRowId` port: the demo holds file
      // names and maps them onto indices on the way in and out. A grid that
      // kept the index would move the tick to whichever row landed in slot 3.
      await tapAndSettle(
        tester,
        _selectionBoxes().at(4),
        what: "the Purchase order row's checkbox",
      );
      expect(_checkedFiles(tester), <String>{'Purchase order'});

      await tapAndSettle(tester, _sortControls().at(0), what: 'the File sort');
      expect(_fileOrder(tester).indexOf('Purchase order'), 1);
      expect(
        _checkedFiles(tester),
        <String>{'Purchase order'},
        reason: 'the tick belongs to the file, not to the slot it was in',
      );
    });

    testWidgets('select-all goes mixed, then whole, then empty', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder all = _selectionBoxes().at(0);
      expect(tester.widget<FluentCheckbox>(all).checked, isFalse);

      await tapAndSettle(tester, _selectionBoxes().at(1), what: 'a row box');
      expect(
        tester.widget<FluentCheckbox>(all).checked,
        isNull,
        reason: 'some-but-not-all is the checkbox mixed state',
      );

      await tapAndSettle(tester, all, what: 'select all');
      expect(_checkedFiles(tester), _declared.toSet());
      expect(tester.widget<FluentCheckbox>(all).checked, isTrue);

      await tapAndSettle(tester, all, what: 'select all');
      expect(_checkedFiles(tester), isEmpty);
      expect(tester.widget<FluentCheckbox>(all).checked, isFalse);
    });
  });

  group('composite navigation', () {
    final DocsSection section = sectionOf(
      'components-datagrid--composite-navigation',
    );

    testWidgets('no column offers a sort control', (WidgetTester tester) async {
      await pumpSection(tester, section);
      // Upstream's composite-navigation story is the Default grid with sorting
      // off, so a sort control here would be a copy-paste of the wrong section.
      expect(_sortControls(), findsNothing);
      expect(_fileOrder(tester), _declared);
    });

    testWidgets("pressing a row's body toggles it", (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(_checkedFiles(tester), isEmpty);

      // The selection cell is 16 wide out of a full-width row; if only that cell
      // carried the gesture the rest of the row would be dead space.
      await mouseClick(tester, find.text('Training recording'));
      expect(_checkedFiles(tester), <String>{'Training recording'});

      await tapAndSettle(
        tester,
        find.text('Training recording'),
        what: 'the row',
      );
      expect(_checkedFiles(tester), isEmpty);
    });
  });

  group('focusable elements in cells', () {
    final DocsSection section = sectionOf(
      'components-datagrid--focusable-elements-in-cells',
    );

    testWidgets('only the File column can be sorted', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(_sortControls(), findsOneWidget);

      await mouseClick(tester, _sortControls().at(0));
      expect(_fileOrder(tester), <String>[
        'Meeting notes',
        'Purchase order',
        'Thursday presentation',
        'Training recording',
      ]);
    });

    testWidgets("the Author header's menu opens", (WidgetTester tester) async {
      await pumpSection(tester, section);
      expect(find.text('Delete column'), findsNothing);

      // The header cell holds two controls beside its label — upstream's
      // `focusMode="group"`. The menu trigger is the only more-horizontal glyph
      // on this grid, so finding it by icon says which one is being pressed.
      await tapAndSettle(
        tester,
        find.byIcon(FluentIcons.more_horizontal_20_regular),
        what: "the Author header's menu",
      );
      expect(find.text('Delete column'), findsOneWidget);
      expect(find.text('Create new author'), findsOneWidget);
    });

    testWidgets('every row carries its own three controls', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      // One Open, one Edit and one Delete per row, plus the Edit in the header.
      expect(find.byIcon(FluentIcons.open_20_regular), findsNWidgets(4));
      expect(find.byIcon(FluentIcons.delete_20_regular), findsNWidgets(4));
      expect(find.byIcon(FluentIcons.edit_20_regular), findsNWidgets(5));
    });
  });

  group('sort', () {
    final DocsSection section = sectionOf('components-datagrid--sort');

    testWidgets('the column without a compare has no control', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text('Not sortable'), findsOneWidget);
      expect(
        _sortControls(),
        findsNWidgets(3),
        reason: 'three of the four columns are sortable',
      );
    });

    testWidgets('the section opens already sorted, and reverses', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // `defaultSortState`: file, ascending. Which is *not* the declaration
      // order, so a grid that ignored it would be visibly wrong on arrival.
      const List<String> ascending = <String>[
        'Meeting notes',
        'Purchase order',
        'Thursday presentation',
        'Training recording',
      ];
      expect(_fileOrder(tester), ascending);
      expect(_labelOf(tester, 0), 'Sorted ascending');

      await mouseClick(tester, _sortControls().at(0));
      expect(_fileOrder(tester), ascending.reversed.toList());

      await tapAndSettle(tester, _sortControls().at(0), what: 'the File sort');
      expect(_fileOrder(tester), ascending);
    });

    testWidgets('sorting by Author reorders on a different key', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await tapAndSettle(
        tester,
        _sortControls().at(1),
        what: 'the Author sort',
      );
      expect(_fileOrder(tester), <String>[
        'Thursday presentation',
        'Purchase order',
        'Training recording',
        'Meeting notes',
      ], reason: 'Erika, Jane, John, Max');
      expect(_labelOf(tester, 0), 'Sort');
    });
  });

  group('sort controlled', () {
    final DocsSection section = sectionOf(
      'components-datagrid--sort-controlled',
    );

    testWidgets('the caller-owned sort state drives the rows', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      const List<String> byFile = <String>[
        'Meeting notes',
        'Purchase order',
        'Thursday presentation',
        'Training recording',
      ];
      expect(_fileOrder(tester), byFile);

      await mouseClick(tester, _sortControls().at(1));
      expect(_fileOrder(tester), <String>[
        'Thursday presentation',
        'Purchase order',
        'Training recording',
        'Meeting notes',
      ]);

      await tapAndSettle(tester, _sortControls().at(0), what: 'the File sort');
      expect(_fileOrder(tester), byFile);
    });

    testWidgets('all four columns are sortable here', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(_sortControls(), findsNWidgets(4));
    });
  });

  group('multiple select', () {
    final DocsSection section = sectionOf(
      'components-datagrid--multiple-select',
    );

    testWidgets('the default selection is honoured and stays additive', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(_checkedFiles(tester), <String>{
        'Thursday presentation',
      }, reason: "upstream's defaultSelectedItems is row 2");

      await mouseClick(tester, _selectionBoxes().at(1));
      expect(_checkedFiles(tester), <String>{
        'Meeting notes',
        'Thursday presentation',
      });

      await tapAndSettle(tester, _selectionBoxes().at(2), what: 'a row box');
      expect(_checkedFiles(tester), <String>{'Meeting notes'});
    });
  });

  group('multiple select controlled', () {
    final DocsSection section = sectionOf(
      'components-datagrid--multiple-select-controlled',
    );

    testWidgets('select-all reaches every row and clears them again', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(_checkedFiles(tester), <String>{'Thursday presentation'});

      await mouseClick(tester, _selectionBoxes().at(0));
      expect(_checkedFiles(tester), _declared.toSet());

      await tapAndSettle(tester, _selectionBoxes().at(0), what: 'select all');
      expect(_checkedFiles(tester), isEmpty);
    });
  });

  group('single select', () {
    final DocsSection section = sectionOf('components-datagrid--single-select');

    testWidgets('the radio moves rather than accumulating', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(_selectionRadios(), findsNWidgets(4));
      expect(_group(tester), 1);

      await mouseClick(tester, _selectionRadios().at(0));
      expect(
        _group(tester),
        0,
        reason: 'a single-select grid holds one row, not two',
      );
    });

    testWidgets('the header has no select-all, and re-pressing keeps it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      // A radio group cannot express "all", so Figma leaves the header's
      // selection slot empty rather than drawing a checkbox that lies.
      expect(
        find.descendant(
          of: find.byType(FluentDataGrid),
          matching: find.byType(FluentCheckbox),
        ),
        findsNothing,
      );

      await tapAndSettle(
        tester,
        _selectionRadios().at(1),
        what: 'the selected row',
      );
      expect(
        _group(tester),
        1,
        reason: 'a Fluent radio cannot be un-selected by re-pressing it',
      );
    });
  });

  group('single select controlled', () {
    final DocsSection section = sectionOf(
      'components-datagrid--single-select-controlled',
    );

    testWidgets("pressing a row's body moves the radio", (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(_group(tester), 1);

      await mouseClick(tester, find.text('Purchase order'));
      expect(_group(tester), 3);
    });
  });

  group('subtle selection', () {
    final DocsSection section = sectionOf(
      'components-datagrid--subtle-selection',
    );

    testWidgets('the selection column is drawn at rest in this port', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Documented divergence: upstream hides the control until the row is
      // hovered, focused or checked, and neither Figma nor `FluentDataGrid` has
      // a mode for that. Asserting it *at rest* is what pins the port down — if
      // a subtle mode ever lands, this is the test that has to be revisited
      // rather than the one that quietly starts passing for a new reason.
      expect(_selectionBoxes(), findsNWidgets(5));
      expect(_checkedFiles(tester), <String>{'Thursday presentation'});

      await mouseClick(tester, _selectionBoxes().at(4));
      expect(_checkedFiles(tester), <String>{
        'Thursday presentation',
        'Purchase order',
      });
    });
  });

  group('selection appearance', () {
    final DocsSection section = sectionOf(
      'components-datagrid--selection-appearance',
    );

    testWidgets('a selected row is painted differently from a plain one', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The whole subject of the section is the *fill*, so a `selectedRows`
      // assertion would prove nothing: this reads what actually reached the
      // DecoratedBox.
      final List<Color?> selected = _rowFills(tester, 'Thursday presentation');
      final List<Color?> plain = _rowFills(tester, 'Meeting notes');
      expect(
        selected,
        isNot(plain),
        reason: 'the neutral selected fill must differ from the row default',
      );

      await mouseClick(tester, _selectionBoxes().at(1));
      expect(
        _rowFills(tester, 'Meeting notes'),
        selected,
        reason: 'selecting the second row must give it the same fill',
      );
    });
  });

  group('resizable columns', () {
    final DocsSection section = sectionOf(
      'components-datagrid--resizable-columns',
    );

    testWidgets('the stated widths are the widths laid out', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Every header label sits at the same inset inside its own cell, so the
      // gap between two of them is the first one's column width.
      final double file = tester.getTopLeft(find.text('File')).dx;
      final double author = tester.getTopLeft(find.text('Author')).dx;
      final double updated = tester.getTopLeft(find.text('Last updated')).dx;
      expect(author - file, 120);
      expect(updated - author, 180);
    });

    testWidgets('a right-click on a header opens the resize menu', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text('Keyboard Column Resizing'), findsNothing);

      // Upstream's keyboard escape hatch is `Menu openOnContext`; the port keeps
      // the gesture, which means a primary press must *not* open it.
      await tapAndSettle(tester, find.text('File'), what: 'the File header');
      expect(find.text('Keyboard Column Resizing'), findsNothing);

      await _secondaryTap(tester, find.text('File'));
      expect(find.text('Keyboard Column Resizing'), findsOneWidget);
    });

    testWidgets('the sized columns still sort', (WidgetTester tester) async {
      await pumpSection(tester, section);
      expect(_fileOrder(tester), _declared);

      await mouseClick(tester, _sortControls().at(0));
      expect(_fileOrder(tester), <String>[
        'Meeting notes',
        'Purchase order',
        'Thursday presentation',
        'Training recording',
      ]);
    });
  });

  group('resizable columns disable auto-fit', () {
    final DocsSection section = sectionOf(
      'components-datagrid--resizable-columns-disable-auto-fit',
    );

    testWidgets('the grid overflows its container and the container scrolls', (
      WidgetTester tester,
    ) async {
      // Narrower than the grid on purpose: at the harness's default 1600 the
      // 1100 grid fits and there would be nothing to scroll, which is exactly
      // the behaviour this section exists to show.
      await pumpSection(
        tester,
        section,
        size: const Size(800, 1000),
        scroll: false,
      );

      expect(tester.getSize(find.byType(FluentDataGrid)).width, 1100);
      final double before = tester.getTopLeft(find.text('File')).dx;

      await tester.drag(find.text('Author'), const Offset(-200, 0));
      await settle(tester);
      expect(
        tester.getTopLeft(find.text('File')).dx,
        lessThan(before - 100),
        reason: 'the wrapper is what makes an over-wide grid reachable',
      );
    });

    testWidgets('its headers keep the context menu and the sort', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Sorted before the menu is opened, not after: the open menu lays a
      // dismiss layer over the whole grid, so a press aimed at a sort control
      // while it is up reaches the layer instead — and a test that ran in the
      // other order would report "the sort did nothing".
      await mouseClick(tester, _sortControls().at(1));
      expect(_fileOrder(tester), <String>[
        'Thursday presentation',
        'Purchase order',
        'Training recording',
        'Meeting notes',
      ]);

      await _secondaryTap(tester, find.text('Last update'));
      expect(find.text('Keyboard Column Resizing'), findsOneWidget);
    });
  });

  group('virtualization', () {
    final DocsSection section = sectionOf(
      'components-datagrid--virtualization',
    );

    testWidgets('forty rows are laid out inside a 500-high scroller', (
      WidgetTester tester,
    ) async {
      // The demo brings its own viewport; the harness's scroller would make
      // "which one moved?" unanswerable.
      await pumpSection(tester, section, scroll: false);

      expect(
        find.text('Meeting notes'),
        findsNWidgets(10),
        reason: 'the four upstream rows are repeated to fill the scroller',
      );
      expect(
        find.byType(FluentCheckbox),
        findsNothing,
        reason: 'this section declares no selection mode',
      );

      final double top = tester.getTopLeft(find.text('Meeting notes').first).dy;
      await tester.drag(
        find.text('Meeting notes').first,
        const Offset(0, -250),
      );
      await settle(tester);
      expect(
        tester.getTopLeft(find.text('Meeting notes').first).dy,
        lessThan(top),
      );
    });
  });

  group('custom row id', () {
    final DocsSection section = sectionOf('components-datagrid--custom-row-id');

    testWidgets('the mirror list tracks the selection by file name', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(_mirror(tester, 'Thursday presentation'), isTrue);
      expect(_mirror(tester, 'Meeting notes'), isFalse);

      await mouseClick(tester, _selectionBoxes().at(1));
      expect(
        _mirror(tester, 'Meeting notes'),
        isTrue,
        reason: 'the read-only list above the grid is the whole story here',
      );
      expect(_mirror(tester, 'Thursday presentation'), isTrue);

      await tapAndSettle(tester, _selectionBoxes().at(2), what: 'a row box');
      expect(_mirror(tester, 'Thursday presentation'), isFalse);
    });

    testWidgets('the mirror itself is read-only', (WidgetTester tester) async {
      await pumpSection(tester, section);

      // The mirror's checkboxes carry no `onChanged`, so pressing one must not
      // move the grid — it is a report, not a second control.
      await tapAndSettle(
        tester,
        find.widgetWithText(FluentCheckbox, 'Meeting notes'),
        what: 'a mirror row',
        warnIfMissed: false,
      );
      expect(_mirror(tester, 'Meeting notes'), isFalse);
      expect(_mirror(tester, 'Thursday presentation'), isTrue);
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

    testWidgets('an open header menu unmounts without throwing', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-datagrid--resizable-columns'),
      );
      await _secondaryTap(tester, find.text('Author'));
      expect(find.text('Keyboard Column Resizing'), findsOneWidget);
      await expectCleanTeardown(tester, 'the grid with its header menu open');
    });
  });
}

/// The four upstream rows, in the order the sections declare them.
const List<String> _declared = <String>[
  'Meeting notes',
  'Thursday presentation',
  'Training recording',
  'Purchase order',
];

/// Every sort control on the grid, in column order.
///
/// Matched on the label the grid gives the control rather than on the button
/// type, so the demos' own Edit, Delete, Open and menu buttons — which live in
/// the same headers and cells — cannot be mistaken for one.
Finder _sortControls() => find.byWidgetPredicate(
  (Widget widget) =>
      widget is FluentButton &&
      const <String>{
        'Sort',
        'Sorted ascending',
        'Sorted descending',
      }.contains(widget.semanticLabel),
  description: 'sort control',
);

/// What the [column]-th sort control announces: `Sort` until it holds the sort.
String? _labelOf(WidgetTester tester, int column) =>
    tester.widget<FluentButton>(_sortControls().at(column)).semanticLabel;

/// The grid's selection checkboxes: index 0 is select-all, then one per row.
Finder _selectionBoxes() => find.descendant(
  of: find.byType(FluentDataGrid),
  matching: find.byType(FluentCheckbox),
);

/// The grid's selection radios, one per row.
Finder _selectionRadios() => find.descendant(
  of: find.byType(FluentDataGrid),
  matching: find.byType(FluentRadio<int>),
);

/// The row index a single-select grid currently holds.
int? _group(WidgetTester tester) =>
    tester.widget<FluentRadio<int>>(_selectionRadios().first).groupValue;

/// The File column, top to bottom, as the grid has it laid out right now.
///
/// Read off the geometry rather than the demo's own list: a sort that reordered
/// its state but not its rows would pass any assertion made against the state.
List<String> _fileOrder(WidgetTester tester) {
  final List<(double, String)> rows = <(double, String)>[
    for (final String file in _declared)
      if (find.text(file).evaluate().isNotEmpty)
        (tester.getTopLeft(find.text(file)).dy, file),
  ];
  rows.sort(((double, String) a, (double, String) b) => a.$1.compareTo(b.$1));
  return <String>[for (final (double, String) row in rows) row.$2];
}

/// The files whose row is ticked, whatever order the grid is in.
///
/// The row boxes are in row order and so is [_fileOrder], so zipping them says
/// which *file* is selected — which is the only question the getRowId sections
/// are asking.
Set<String> _checkedFiles(WidgetTester tester) {
  final List<String> order = _fileOrder(tester);
  final Finder boxes = _selectionBoxes();
  return <String>{
    for (int i = 0; i < order.length; i++)
      if (tester.widget<FluentCheckbox>(boxes.at(i + 1)).checked ?? false)
        order[i],
  };
}

/// Whether the read-only mirror row for [file] is ticked.
bool? _mirror(WidgetTester tester, String file) => tester
    .widget<FluentCheckbox>(find.widgetWithText(FluentCheckbox, file))
    .checked;

/// Every fill painted around the cell showing [file].
///
/// A selected row differs from a plain one only in what it painted, so the
/// widget tree cannot answer this — the decoration can.
List<Color?> _rowFills(WidgetTester tester, String file) => tester
    .widgetList<DecoratedBox>(
      find.ancestor(of: find.text(file), matching: find.byType(DecoratedBox)),
    )
    .map(
      (DecoratedBox box) => box.decoration is BoxDecoration
          ? (box.decoration as BoxDecoration).color
          : null,
    )
    .toList();

/// Right-clicks [finder] with a real mouse.
///
/// The header menus on the resizable sections open on `onSecondaryTap` and on
/// nothing else, so a primary tap — and every synthetic `tester.tap` — misses
/// them entirely.
Future<void> _secondaryTap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder.first);
  await settle(tester);
  final Offset target = tester.getCenter(finder.first);
  final TestGesture mouse = await tester.createGesture(
    kind: PointerDeviceKind.mouse,
    buttons: kSecondaryButton,
  );
  // Added and removed inside one call, for the reason `mouseClick` records:
  // MouseTracker asserts a device is removed before the next one is added, and
  // `tester.tapAt` leaves its mouse in place.
  await mouse.addPointer(location: target);
  await settle(tester);
  await mouse.down(target);
  await tester.pump(const Duration(milliseconds: 16));
  await mouse.up();
  await settle(tester);
  await mouse.removePointer();
  await settle(tester);
  expectClean(tester, 'right-clicking ${finder.describeMatch(Plurality.one)}');
}
