import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// ChartTable's page is one section carrying four knobs — two size sliders, a
/// data-set radio pair and a styled-cells switch — over a grid that is a plain
/// [Table], not a painter. So every assertion below reads the grid itself:
/// its measured box, its column count, the labels in its header row and the
/// [ColoredBox] each styled cell mints. A knob that moved the demo's own field
/// without reaching the grid would satisfy none of them.
void main() {
  const String page = 'charts-charttable';
  final DocsSection section = sectionOf('charts-charttable--chart-table-basic');

  group('size', () {
    testWidgets('the width slider resizes the grid and its readout', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(_tableSize(tester).width, 700);
      expect(find.text('700px'), findsOneWidget);

      await dropSliderAt(tester, _slider('Change Width'), 1);
      expect(
        _tableSize(tester).width,
        1200,
        reason: 'the width slider must reach the grid, not just the readout',
      );
      expect(find.text('1200px'), findsOneWidget);

      await dropSliderAt(tester, _slider('Change Width'), 0);
      expect(_tableSize(tester).width, 300);
      expect(find.text('300px'), findsOneWidget);
      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('the width slider commits under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The primary knob of the page, driven the way a browser drives it. The
      // rail sits inside a horizontally scrollable demo, and a press whose
      // two-pixel travel is claimed by a scrollable's drag recogniser never
      // reaches the slider at all — a defect `tester.tap` cannot see.
      await mouseClick(tester, _slider('Change Width'));
      final double width = _tableSize(tester).width;
      expect(
        width,
        greaterThan(700),
        reason: 'a mouse press near the middle of the rail must raise 700',
      );
      expect(find.text('${width.round()}px'), findsOneWidget);
    });

    testWidgets('the height slider resizes the grid and its readout', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(_tableSize(tester).height, 200);
      expect(find.text('200px'), findsOneWidget);

      await dropSliderAt(tester, _slider('Change Height'), 1);
      expect(_tableSize(tester).height, 800);
      expect(find.text('800px'), findsOneWidget);

      await dropSliderAt(tester, _slider('Change Height'), 0);
      expect(_tableSize(tester).height, 200);
    });
  });

  group('table type', () {
    testWidgets('the radio pair swaps the whole data set', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(find.text('Product'), findsOneWidget);
      expect(find.text('Q1 Sales'), findsOneWidget);
      expect(_columnCount(tester), 6);

      await mouseClick(tester, find.text('Financial Data Example'));
      expect(
        find.text('Product'),
        findsNothing,
        reason: 'the sales headers must leave with the sales rows',
      );
      expect(find.text('Metric'), findsOneWidget);
      expect(find.text('Revenue (\$M)'), findsOneWidget);
      expect(
        _columnCount(tester),
        5,
        reason: 'the financial set is five columns wide, not six',
      );

      await mouseClick(tester, find.text('Sales Data Example'));
      expect(find.text('Product'), findsOneWidget);
      expect(_columnCount(tester), 6);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('styled cells', () {
    testWidgets('the switch paints a background behind every value cell', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Six: one per header. A body cell of the plain set asks for neither a
      // colour nor a fill, and `cellBackground` leaves it unpainted.
      expect(_paintedCells(tester), 6);

      await tapAndSettle(tester, _switch, what: 'the styled-cells switch');
      expect(
        _paintedCells(tester),
        26,
        reason:
            'the styled set fills the four sales columns and the total of '
            'each of the four rows — twenty cells on top of the six headers',
      );

      await tapAndSettle(tester, _switch, what: 'the styled-cells switch');
      expect(
        _paintedCells(tester),
        6,
        reason: 'turning the switch back must strip the fills again',
      );
    });

    testWidgets('the financial set disables the switch rather than hiding it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await tapAndSettle(tester, _switch, what: 'the styled-cells switch');
      expect(find.text('Styled cells ON'), findsOneWidget);

      await mouseClick(tester, find.text('Financial Data Example'));
      expect(
        tester.widget<FluentSwitch>(_switch).onChanged,
        isNull,
        reason: 'upstream disables the switch on the financial data set',
      );

      // The switch is still checked, so a demo that merely stopped reading it
      // would keep the styled sales rows on screen; the financial rows are how
      // we know the data set won.
      await tapAndSettle(
        tester,
        _switch,
        what: 'the disabled styled-cells switch',
        warnIfMissed: false,
      );
      expect(find.text('Styled cells ON'), findsOneWidget);
      expect(find.text('Revenue (\$M)'), findsOneWidget);
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

/// The slider whose `semanticLabel` is [semanticLabel].
///
/// The demo declares two identical-looking rails; an index would silently
/// follow a reordering of the control strip, and the semantic label is the one
/// thing about a rail that names which number it drives.
Finder _slider(String semanticLabel) => find.byWidgetPredicate(
  (Widget widget) =>
      widget is FluentSlider && widget.semanticLabel == semanticLabel,
  description: 'FluentSlider("$semanticLabel")',
);

Finder get _switch => find.byType(FluentSwitch);

/// The measured box of the grid, which is what the two sliders claim to move.
Size _tableSize(WidgetTester tester) =>
    tester.getSize(find.byType(FluentChartTable));

/// How many columns the rendered grid actually has.
int _columnCount(WidgetTester tester) => tester
    .widget<Table>(
      find.descendant(
        of: find.byType(FluentChartTable),
        matching: find.byType(Table),
      ),
    )
    .children
    .first
    .children
    .length;

/// How many cells reached the screen with a fill behind them.
///
/// `FluentChartTable` wraps a cell in a [ColoredBox] only when the contrast
/// pass resolved a background for it, so this counts exactly the cells the
/// styled-cells knob is supposed to touch.
int _paintedCells(WidgetTester tester) => find
    .descendant(
      of: find.byType(FluentChartTable),
      matching: find.byType(ColoredBox),
    )
    .evaluate()
    .length;
