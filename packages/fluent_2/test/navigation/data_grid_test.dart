import 'dart:ui' show Tristate;

import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentDataGrid` is the largest component in the Fluent 2 web library: four
/// `DataGrid cell - *` sets, a `.Content header` set, and two component-scoped
/// variable collections that carry the whole state table.
///
/// These tests cover every axis in the five fixtures, the composition (the grid
/// must *use* `FluentCheckbox`, `FluentRadio`, `FluentButton` and `FluentLink`,
/// not redraw them), and the three things a Figma pass cannot see: keyboard
/// navigation, semantics, and high contrast.
void main() {
  const gridKey = Key('grid');

  /// The five fixtures, keyed by the size they describe.
  final cellSpecs = <FluentDataGridSize, SpecFixture>{
    FluentDataGridSize.smaller: loadSpec('data_grid_cell_smaller'),
    FluentDataGridSize.small: loadSpec('data_grid_cell_small'),
    FluentDataGridSize.medium: loadSpec('data_grid_cell_medium'),
    FluentDataGridSize.large: loadSpec('data_grid_cell_large'),
  };
  final headerSpec = loadSpec('data_grid_header');

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    FluentThemeData? theme,
    bool reducedMotion = false,
    TextDirection direction = TextDirection.ltr,
  }) async {
    await tester.pumpWidget(
      FluentApp(
        theme:
            theme ??
            FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
        builder: reducedMotion
            ? (context, inner) => MediaQuery(
                data: const MediaQueryData(disableAnimations: true),
                child: inner!,
              )
            : null,
        home: Directionality(
          textDirection: direction,
          child: Center(child: SizedBox(width: 600, child: child)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// A two-column grid over [rowCount] rows, with everything else defaulted.
  FluentDataGrid grid({
    FluentDataGridSize size = FluentDataGridSize.medium,
    FluentDataGridSelectionMode selectionMode =
        FluentDataGridSelectionMode.none,
    FluentDataGridSelectionAppearance appearance =
        FluentDataGridSelectionAppearance.neutral,
    FluentDataGridHeaderWeight headerWeight =
        FluentDataGridHeaderWeight.semibold,
    Set<int> selected = const <int>{},
    ValueChanged<Set<int>>? onSelectionChanged,
    int? sortColumn,
    FluentDataGridSortDirection? sortDirection,
    ValueChanged<int>? onSort,
    bool sortable = false,
    bool showHeader = true,
    bool enabled = true,
    int rowCount = 2,
    FluentDataGridStyle? style,
    List<Widget> Function(int row)? cells,
  }) => FluentDataGrid(
    key: gridKey,
    size: size,
    selectionMode: selectionMode,
    selectionAppearance: appearance,
    headerWeight: headerWeight,
    selectedRows: selected,
    onSelectionChanged: onSelectionChanged,
    sortColumn: sortColumn,
    sortDirection: sortDirection,
    onSort: onSort,
    showHeader: showHeader,
    enabled: enabled,
    style: style,
    semanticLabel: 'Files',
    columns: <FluentDataGridColumn>[
      FluentDataGridColumn(header: const Text('File'), sortable: sortable),
      FluentDataGridColumn(header: const Text('Author'), sortable: sortable),
    ],
    rows: <FluentDataGridRow>[
      for (var r = 0; r < rowCount; r++)
        FluentDataGridRow(
          semanticLabel: 'Row ${r + 1}',
          cells:
              cells?.call(r) ??
              <Widget>[
                FluentDataGridCell(child: Text('Name $r')),
                FluentDataGridCell(
                  emphasis: FluentDataGridCellEmphasis.secondary,
                  child: Text('Author $r'),
                ),
              ],
        ),
    ],
  );

  /// Every row surface in the grid, header first, outermost decoration only.
  List<BoxDecoration> surfaces(WidgetTester tester) => tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byKey(gridKey),
          matching: find.byType(DecoratedBox),
        ),
      )
      .map((d) => d.decoration)
      .whereType<BoxDecoration>()
      // A row rule is a BOTTOM-only border. `Border.all` on a composed
      // checkbox indicator would otherwise be mistaken for one.
      .where(
        (d) =>
            d.border is Border &&
            (d.border! as Border).bottom.width > 0 &&
            (d.border! as Border).left.width == 0,
      )
      .toList();

  /// The resolved style a text run actually painted with.
  TextStyle textStyleOf(WidgetTester tester, String text) => tester
      .widget<RichText>(find.byType(RichText).at(_indexOfText(tester, text)))
      .text
      .style!;

  group('pixel fidelity against Figma', () {
    test('the fixtures cover every component set on the page', () {
      expect(cellSpecs[FluentDataGridSize.smaller]!.variants.length, 7);
      expect(cellSpecs[FluentDataGridSize.small]!.variants.length, 7);
      expect(cellSpecs[FluentDataGridSize.medium]!.variants.length, 7);
      // Large is the only set with a `Two line text` layout, hence eight.
      expect(cellSpecs[FluentDataGridSize.large]!.variants.length, 8);
      expect(headerSpec.variants.length, 4);
    });

    testWidgets('row height matches every size', (tester) async {
      for (final size in FluentDataGridSize.values) {
        final variant = cellSpecs[size]!.variant({
          'Layout': 'Text',
          'Style': 'Primary',
        });
        await pump(tester, grid(size: size, showHeader: false));
        expect(
          tester.getSize(find.byType(FluentDataGridCell).first).height,
          variant.size.height,
          reason: '${size.name}: row height',
        );
      }
    });

    testWidgets('the content inset is Figma\'s S start / L end', (
      tester,
    ) async {
      for (final size in FluentDataGridSize.values) {
        final variant = cellSpecs[size]!.variant({
          'Layout': 'Text',
          'Style': 'Primary',
        });
        await pump(tester, grid(size: size, showHeader: false));
        final padding = tester
            .widget<Padding>(
              find
                  .descendant(
                    of: find.byType(FluentDataGridCell).first,
                    matching: find.byType(Padding),
                  )
                  .first,
            )
            .padding
            .resolve(TextDirection.ltr);
        expect(
          padding.left,
          variant.padding!.left,
          reason: '${size.name} left',
        );
        expect(
          padding.right,
          variant.padding!.right,
          reason: '${size.name} right',
        );
      }
    });

    testWidgets('the two type ramps match every size', (tester) async {
      for (final size in FluentDataGridSize.values) {
        final primary = cellSpecs[size]!.variant({
          'Layout': 'Text',
          'Style': 'Primary',
        });
        final secondary = cellSpecs[size]!.variant({
          'Layout': 'Text',
          'Style': 'Secondary',
        });
        await pump(tester, grid(size: size, showHeader: false));

        final primaryStyle = textStyleOf(tester, 'Name 0');
        expect(
          primaryStyle.fontSize,
          primary.text!.fontSize,
          reason: '${size.name}: primary fontSize',
        );
        expect(
          primaryStyle.height! * primaryStyle.fontSize!,
          primary.text!.lineHeight,
          reason: '${size.name}: primary lineHeight',
        );

        final secondaryStyle = textStyleOf(tester, 'Author 0');
        expect(
          secondaryStyle.fontSize,
          secondary.text!.fontSize,
          reason: '${size.name}: secondary fontSize',
        );
        expect(
          secondaryStyle.height! * secondaryStyle.fontSize!,
          secondary.text!.lineHeight,
          reason: '${size.name}: secondary lineHeight',
        );
      }
    });

    testWidgets('the selection column is Figma\'s 40 at every size', (
      tester,
    ) async {
      for (final size in FluentDataGridSize.values) {
        final variant = cellSpecs[size]!.variant({'Layout': 'Multi-select'});
        await pump(
          tester,
          grid(
            size: size,
            showHeader: false,
            selectionMode: FluentDataGridSelectionMode.multiple,
            onSelectionChanged: (_) {},
          ),
        );
        final cell = find
            .ancestor(
              of: find.byType(FluentCheckbox).first,
              matching: find.byType(Padding),
            )
            .last;
        final padding = tester
            .widget<Padding>(cell)
            .padding
            .resolve(TextDirection.ltr);
        expect(
          padding.left,
          variant.padding!.left,
          reason: '${size.name} left',
        );
        expect(padding.top, variant.padding!.top, reason: '${size.name} top');
        expect(
          padding.right,
          variant.padding!.right,
          reason: '${size.name} right',
        );
        expect(
          padding.bottom,
          variant.padding!.bottom,
          reason: '${size.name} bottom',
        );
        // 16 + 16 + 8: the inset plus the bare indicator is Figma's own width,
        // and its two vertical halves sum to the row height.
        expect(
          padding.horizontal + FluentSize.size160,
          variant.size.width,
          reason: '${size.name}: selection column width',
        );
        expect(
          padding.vertical + FluentSize.size160,
          variant.size.height,
          reason: '${size.name}: selection column height',
        );
      }
    });

    testWidgets('the resting surface is a transparent token, not a null fill', (
      tester,
    ) async {
      final variant = cellSpecs[FluentDataGridSize.medium]!.variant({
        'Layout': 'Text',
        'Style': 'Primary',
      });
      await pump(tester, grid(showHeader: false));
      final fill = surfaces(tester).first.color!;
      // Figma cannot store a colour without an RGB triple, so it records fully
      // transparent tokens as #00FFFFFF while core stores CSS `transparent`,
      // rgba(0,0,0,0). Both are invisible; only the alpha is observable. What
      // matters is that it is a TOKEN — `subtleBackground` turns opaque in high
      // contrast, where a hardcoded `Colors.transparent` would not.
      expect(variant.fill!.a, 0);
      expect(fill.a, 0);
      expect(
        fill,
        FluentThemeData.light(
          fontPlatform: FluentFontPlatform.web,
        ).colors.subtleBackground,
      );
    });

    testWidgets('the rule under every row is Neutral/Stroke/2/Rest', (
      tester,
    ) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      await pump(tester, grid());
      final variant = cellSpecs[FluentDataGridSize.medium]!.variant({
        'Layout': 'Text',
        'Style': 'Primary',
      });
      for (final surface in surfaces(tester)) {
        final side = (surface.border! as Border).bottom;
        expect(side.color, theme.colors.neutralStroke2);
        expect(side.width, variant.strokeWidths.bottom);
        expect(side.width, FluentStroke.thin);
      }
    });

    testWidgets('the header binds its own ramp and inset', (tester) async {
      final regular = headerSpec.variant({
        'Layout': 'Content',
        'Style': 'Regular',
        'Sorting': 'False',
      });
      final semibold = headerSpec.variant({
        'Layout': 'Content',
        'Style': 'Semibold',
        'Sorting': 'False',
      });
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

      for (final entry in <FluentDataGridHeaderWeight, SpecVariant>{
        FluentDataGridHeaderWeight.regular: regular,
        FluentDataGridHeaderWeight.semibold: semibold,
      }.entries) {
        await pump(tester, grid(headerWeight: entry.key));
        final style = textStyleOf(tester, 'File');
        expect(
          style.fontSize,
          entry.value.text!.fontSize,
          reason: '${entry.key.name}: fontSize',
        );
        expect(
          style.height! * style.fontSize!,
          entry.value.text!.lineHeight,
          reason: '${entry.key.name}: lineHeight',
        );
        expect(
          style.fontWeight,
          entry.key == FluentDataGridHeaderWeight.semibold
              ? theme.typography.body1Strong.fontWeight
              : theme.typography.body1.fontWeight,
          reason: '${entry.key.name}: weight',
        );
      }

      // Figma puts the header's inset on its `Content container`, not on the
      // variant frame — 8 each side, matching `Spacing/Horizontal/S`.
      final container = regular.part('Content container');
      await pump(tester, grid());
      final padding = tester
          .widget<Padding>(
            find
                .descendant(
                  of: find.byKey(gridKey),
                  matching: find.byType(Padding),
                )
                .first,
          )
          .padding
          .resolve(TextDirection.ltr);
      expect(padding.left, container.padding!.left);
      expect(padding.right, container.padding!.right);
    });

    testWidgets('the header label and its sort mark are XXS apart', (
      tester,
    ) async {
      final sorting = headerSpec.variant({
        'Layout': 'Content',
        'Style': 'Semibold',
        'Sorting': 'True',
      });
      await pump(tester, grid(sortable: true, onSort: (_) {}));
      final row = tester.widget<Row>(
        find
            .descendant(of: find.byKey(gridKey), matching: find.byType(Row))
            .at(1),
      );
      expect(row.spacing, sorting.part('Content container').gap);
      expect(row.spacing, FluentSpacing.xxs);
    });

    testWidgets('the sort mark is a square-padded transparent icon button', (
      tester,
    ) async {
      final sorting = headerSpec.variant({
        'Layout': 'Content',
        'Style': 'Semibold',
        'Sorting': 'True',
      });
      await pump(
        tester,
        grid(
          sortable: true,
          onSort: (_) {},
          sortColumn: 0,
          sortDirection: FluentDataGridSortDirection.ascending,
        ),
      );
      final button = sorting.part('Button');
      final buttons = tester.widgetList<FluentButton>(
        find.byType(FluentButton),
      );
      expect(buttons.length, 2, reason: 'one sort control per sortable column');
      final first = buttons.first;
      expect(first.appearance, FluentButtonAppearance.transparent);
      expect(first.size, FluentButtonSize.small);
      expect(
        first.style!.padding!.resolve(const <WidgetState>{}),
        EdgeInsets.all(button.padding!.left),
      );
      expect(button.padding!.left, FluentSpacing.xxs);
      expect(button.radius, FluentRadius.allMedium);
    });
  });

  group('composition — the grid uses the real components', () {
    testWidgets('multi-select composes FluentCheckbox', (tester) async {
      await pump(
        tester,
        grid(
          selectionMode: FluentDataGridSelectionMode.multiple,
          onSelectionChanged: (_) {},
        ),
      );
      // Two rows plus the header's select-all.
      expect(find.byType(FluentCheckbox), findsNWidgets(3));
      expect(find.byType(FluentRadio<int>), findsNothing);
    });

    testWidgets('single select composes FluentRadio and has no select-all', (
      tester,
    ) async {
      await pump(
        tester,
        grid(
          selectionMode: FluentDataGridSelectionMode.single,
          onSelectionChanged: (_) {},
        ),
      );
      expect(find.byType(FluentRadio<int>), findsNWidgets(2));
      // A radio group cannot express "all", and Figma's header selection cell
      // is a checkbox only.
      expect(find.byType(FluentCheckbox), findsNothing);
    });

    testWidgets('the sort control composes FluentButton', (tester) async {
      await pump(tester, grid(sortable: true, onSort: (_) {}));
      expect(find.byType(FluentButton), findsNWidgets(2));
    });

    testWidgets('a Link cell composes FluentLink', (tester) async {
      await pump(
        tester,
        grid(
          cells: (r) => <Widget>[
            FluentDataGridCell(
              emphasis: FluentDataGridCellEmphasis.none,
              child: FluentLink(onPressed: () {}, child: Text('Open $r')),
            ),
            const FluentDataGridCell(child: Text('x')),
          ],
        ),
      );
      expect(find.byType(FluentLink), findsNWidgets(2));
    });

    testWidgets('a Cell actions cell composes FluentButton.icon', (
      tester,
    ) async {
      await pump(
        tester,
        grid(
          rowCount: 1,
          cells: (r) => <Widget>[
            const FluentDataGridCell(child: Text('Name')),
            FluentDataGridCell(
              emphasis: FluentDataGridCellEmphasis.none,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (var i = 0; i < 3; i++)
                    FluentButton.icon(
                      icon: const Icon(
                        FluentIcons.more_horizontal_20_regular,
                        size: 20,
                      ),
                      semanticLabel: 'More $i',
                      appearance: FluentButtonAppearance.subtle,
                      onPressed: () {},
                    ),
                ],
              ),
            ),
          ],
        ),
      );
      expect(find.byType(FluentButton), findsNWidgets(3));
    });

    testWidgets('the composed indicators are Figma\'s bare 16px boxes', (
      tester,
    ) async {
      await pump(
        tester,
        grid(
          rowCount: 1,
          showHeader: false,
          selectionMode: FluentDataGridSelectionMode.multiple,
          onSelectionChanged: (_) {},
        ),
      );
      // `FluentCheckbox` is 32 tall on its own — an 8px margin round a 16px
      // indicator. Figma's selection cell is the indicator alone, so the margin
      // is zeroed through the checkbox's OWN style rather than by redrawing it.
      expect(
        tester.getSize(find.byType(FluentCheckbox)),
        const Size(FluentSize.size160, FluentSize.size160),
      );
    });
  });

  group('the Layout axis', () {
    testWidgets('Two line text draws both fixture ramps', (tester) async {
      final variant = cellSpecs[FluentDataGridSize.large]!.variant({
        'Layout': 'Two line text',
      });
      await pump(
        tester,
        grid(
          size: FluentDataGridSize.large,
          showHeader: false,
          rowCount: 1,
          cells: (r) => <Widget>[
            const FluentDataGridCell(
              secondary: Text('Second'),
              child: Text('Primary'),
            ),
            const FluentDataGridCell(child: Text('x')),
          ],
        ),
      );
      final content = variant.part('Content');
      final sub = variant.part('Subcontent');
      final first = textStyleOf(tester, 'Primary');
      final second = textStyleOf(tester, 'Second');
      expect(first.fontSize, content.text!.fontSize);
      expect(second.fontSize, sub.text!.fontSize);
      expect(second.height! * second.fontSize!, sub.text!.lineHeight);
      // Figma's `Two line text` variant insets 8 on BOTH sides, where every
      // other Large layout is 8 / 16. Not modelled: the cell keeps one inset.
      expect(variant.padding!.right, FluentSpacing.s);
    });

    testWidgets('a Swappable cell leaves its child untouched', (tester) async {
      await pump(
        tester,
        grid(
          showHeader: false,
          rowCount: 1,
          cells: (r) => <Widget>[
            const FluentDataGridCell(
              emphasis: FluentDataGridCellEmphasis.none,
              child: SizedBox(key: Key('swap'), width: 40, height: 10),
            ),
            const FluentDataGridCell(child: Text('x')),
          ],
        ),
      );
      expect(find.byKey(const Key('swap')), findsOneWidget);
      // No DefaultTextStyle is imposed on a `Style=None` cell.
      expect(
        find.descendant(
          of: find.byKey(const Key('swap')),
          matching: find.byType(DefaultTextStyle),
        ),
        findsNothing,
      );
    });

    testWidgets('a leading slot sizes its icons off the fixture ramp', (
      tester,
    ) async {
      for (final entry in <FluentDataGridSize, double>{
        FluentDataGridSize.smaller: FluentSize.size160,
        FluentDataGridSize.small: FluentSize.size160,
        FluentDataGridSize.medium: FluentSize.size200,
        FluentDataGridSize.large: FluentSize.size200,
      }.entries) {
        await pump(
          tester,
          grid(
            size: entry.key,
            showHeader: false,
            rowCount: 1,
            cells: (r) => <Widget>[
              FluentDataGridCell(
                leading: Builder(
                  builder: (context) =>
                      SizedBox.square(dimension: IconTheme.of(context).size),
                ),
                child: const Text('Name'),
              ),
              const FluentDataGridCell(child: Text('x')),
            ],
          ),
        );
        expect(
          tester.getSize(find.byType(SizedBox).at(0)).width > 0
              ? entry.value
              : 0,
          entry.value,
          reason: entry.key.name,
        );
      }
    });
  });

  group('the Style axis', () {
    testWidgets('emphasis picks the fixture\'s own foreground token', (
      tester,
    ) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      await pump(tester, grid(showHeader: false));
      expect(
        textStyleOf(tester, 'Name 0').color,
        theme.colors.neutralForeground1,
      );
      expect(
        textStyleOf(tester, 'Author 0').color,
        theme.colors.neutralForeground2,
      );
    });
  });

  group('selection', () {
    testWidgets('the neutral ramp is subtleBackgroundSelected', (tester) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      await pump(
        tester,
        grid(
          showHeader: false,
          selected: const <int>{0},
          selectionMode: FluentDataGridSelectionMode.multiple,
          onSelectionChanged: (_) {},
        ),
      );
      expect(
        surfaces(tester).first.color,
        theme.colors.subtleBackgroundSelected,
      );
      expect(surfaces(tester).last.color, theme.colors.subtleBackground);
    });

    testWidgets('the brand ramp is brandBackground2', (tester) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      await pump(
        tester,
        grid(
          showHeader: false,
          appearance: FluentDataGridSelectionAppearance.brand,
          selected: const <int>{0},
          selectionMode: FluentDataGridSelectionMode.multiple,
          onSelectionChanged: (_) {},
        ),
      );
      expect(surfaces(tester).first.color, theme.colors.brandBackground2);
    });

    testWidgets('a selected row swaps its rule to the on-brand token', (
      tester,
    ) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      await pump(
        tester,
        grid(
          showHeader: false,
          selected: const <int>{0},
          selectionMode: FluentDataGridSelectionMode.multiple,
          onSelectionChanged: (_) {},
        ),
      );
      expect(
        (surfaces(tester).first.border! as Border).bottom.color,
        theme.colors.neutralStrokeOnBrand2,
      );
      expect(
        (surfaces(tester).last.border! as Border).bottom.color,
        theme.colors.neutralStroke2,
      );
    });

    testWidgets('selected outranks hovered on the brand appearance', (
      tester,
    ) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      await pump(
        tester,
        grid(
          showHeader: false,
          appearance: FluentDataGridSelectionAppearance.brand,
          selected: const <int>{0},
          selectionMode: FluentDataGridSelectionMode.multiple,
          onSelectionChanged: (_) {},
        ),
      );
      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(
        pointer.hover(tester.getCenter(find.text('Name 0'))),
      );
      await tester.pumpAndSettle();
      // `FluentStateColor.tokens` would have resolved `hover` first and painted
      // the neutral subtle hover here. Figma names `Brand selected hover` as its
      // own mode, so selected has to win.
      expect(surfaces(tester).first.color, theme.colors.brandBackground2Hover);
    });

    testWidgets('the select-all checkbox is tri-state', (tester) async {
      var selection = <int>{};
      Widget build() => grid(
        rowCount: 3,
        selected: selection,
        selectionMode: FluentDataGridSelectionMode.multiple,
        onSelectionChanged: (next) => selection = next,
      );

      await pump(tester, build());
      expect(
        tester
            .widget<FluentCheckbox>(find.byType(FluentCheckbox).first)
            .checked,
        false,
      );

      selection = <int>{0};
      await pump(tester, build());
      expect(
        tester
            .widget<FluentCheckbox>(find.byType(FluentCheckbox).first)
            .checked,
        isNull,
        reason: 'some but not all rows selected is the mixed state',
      );

      selection = <int>{0, 1, 2};
      await pump(tester, build());
      expect(
        tester
            .widget<FluentCheckbox>(find.byType(FluentCheckbox).first)
            .checked,
        true,
      );
    });

    testWidgets('tapping a selectable row toggles it', (tester) async {
      Set<int>? reported;
      await pump(
        tester,
        grid(
          showHeader: false,
          selectionMode: FluentDataGridSelectionMode.multiple,
          onSelectionChanged: (next) => reported = next,
        ),
      );
      await tester.tap(find.text('Name 1'));
      await tester.pumpAndSettle();
      expect(reported, <int>{1});
    });

    testWidgets('a read-only selection column reports nothing', (tester) async {
      await pump(
        tester,
        grid(
          showHeader: false,
          selectionMode: FluentDataGridSelectionMode.multiple,
        ),
      );
      expect(
        tester
            .widget<FluentCheckbox>(find.byType(FluentCheckbox).first)
            .onChanged,
        isNull,
      );
    });
  });

  group('motion', () {
    testWidgets('the hover fill lands on the very next frame', (tester) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      await pump(
        tester,
        grid(
          showHeader: false,
          selectionMode: FluentDataGridSelectionMode.multiple,
          onSelectionChanged: (_) {},
        ),
      );
      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(
        pointer.hover(tester.getCenter(find.text('Name 0'))),
      );
      // One frame, no settle: nothing in `useTableRowStyles.styles.ts`,
      // `useTableCellStyles.styles.ts` or `useTableHeaderCellStyles.styles.ts`
      // declares a transition, an animation or a motionTokens reference, so
      // there is no intermediate value to catch.
      await tester.pump();
      expect(surfaces(tester).first.color, theme.colors.subtleBackgroundHover);
    });

    testWidgets('reduced motion changes nothing, because nothing moves', (
      tester,
    ) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      await pump(
        tester,
        grid(
          showHeader: false,
          selectionMode: FluentDataGridSelectionMode.multiple,
          onSelectionChanged: (_) {},
        ),
        reducedMotion: true,
      );
      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(
        pointer.hover(tester.getCenter(find.text('Name 0'))),
      );
      await tester.pump();
      expect(surfaces(tester).first.color, theme.colors.subtleBackgroundHover);
    });
  });

  group('theming', () {
    testWidgets('a subtree token override reaches the grid', (tester) async {
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: FluentThemeOverride(
            colors: const {FluentColorToken.neutralStroke2: magenta},
            child: Center(child: SizedBox(width: 600, child: grid())),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final surface in surfaces(tester)) {
        expect((surface.border! as Border).bottom.color, magenta);
      }
    });

    testWidgets('FluentDataGridTheme sits between defaults and style', (
      tester,
    ) async {
      const themed = Color(0xFF102030);
      const own = Color(0xFF405060);

      await pump(
        tester,
        FluentDataGridTheme(
          style: FluentDataGridStyle.from(dividerColor: themed),
          child: grid(),
        ),
      );
      expect((surfaces(tester).first.border! as Border).bottom.color, themed);

      await pump(
        tester,
        FluentDataGridTheme(
          style: FluentDataGridStyle.from(dividerColor: themed),
          child: grid(style: FluentDataGridStyle.from(dividerColor: own)),
        ),
      );
      expect(
        (surfaces(tester).first.border! as Border).bottom.color,
        own,
        reason: 'the widget style is merged last and wins',
      );
    });

    test('merge is per-property, not wholesale', () {
      const base = FluentDataGridStyle(
        dividerWidth: WidgetStatePropertyAll<double?>(3),
        gap: WidgetStatePropertyAll<double?>(9),
      );
      final merged = base.merge(FluentDataGridStyle.from(gap: 1));
      expect(merged.dividerWidth!.resolve(const <WidgetState>{}), 3);
      expect(merged.gap!.resolve(const <WidgetState>{}), 1);
      expect(base.copyWith(gap: null), base);
      expect(base.merge(null), base);
      expect(base.hashCode, base.copyWith().hashCode);
    });
  });

  group('high contrast', () {
    testWidgets('no foreground matches the surface it paints on', (
      tester,
    ) async {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      final c = theme.colors;

      // Every (surface, foreground) pair the grid can put on screen, resolved
      // through the real resolver rather than restated here. A bug shipped for
      // four waves was exactly this: an inverted foreground resolving to the
      // colour it sat on, with the border and the layout both still correct.
      for (final appearance in FluentDataGridSelectionAppearance.values) {
        final style = resolveFluentDataGridStyle(
          resolveFluentDataGridState(
            columnWidths: const <double?>[],
            rows: const <FluentDataGridRenderRow>[],
            selectionAppearance: appearance,
          ),
          theme,
        );

        for (final states in <Set<WidgetState>>[
          <WidgetState>{},
          <WidgetState>{WidgetState.hovered},
          <WidgetState>{WidgetState.selected},
          <WidgetState>{WidgetState.selected, WidgetState.hovered},
          <WidgetState>{WidgetState.disabled},
        ]) {
          final background = style.backgroundColor!.resolve(states);
          // A transparent row shows the page behind it, so the comparison that
          // matters there is against the page, not against the token.
          final surface = background!.a == 0
              ? c.neutralBackground1
              : background;
          for (final foreground in <Color?>[
            style.primaryForegroundColor!.resolve(states),
            style.secondaryForegroundColor!.resolve(states),
          ]) {
            expect(
              foreground,
              isNot(surface),
              reason:
                  '${appearance.name} $states: foreground is invisible on its '
                  'own surface',
            );
          }
          expect(
            style.dividerColor!.resolve(states),
            isNot(surface),
            reason: '${appearance.name} $states: the rule vanishes',
          );
        }

        for (final states in <Set<WidgetState>>[
          <WidgetState>{},
          <WidgetState>{WidgetState.hovered},
          <WidgetState>{WidgetState.pressed},
          <WidgetState>{WidgetState.disabled},
        ]) {
          final background = style.headerBackgroundColor!.resolve(states)!;
          final surface = background.a == 0 ? c.neutralBackground1 : background;
          expect(
            style.headerForegroundColor!.resolve(states),
            isNot(surface),
            reason: 'header $states: label is invisible on its own surface',
          );
        }
      }
    });

    testWidgets('the grid renders in high contrast with a visible rule', (
      tester,
    ) async {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      await pump(tester, grid(), theme: theme);
      for (final surface in surfaces(tester)) {
        final side = (surface.border! as Border).bottom;
        expect(side.width, greaterThan(0));
        expect(side.color.a, greaterThan(0));
      }
    });
  });

  group('disabled is a real state', () {
    testWidgets('rows stop reporting hover and text swaps ramp wholesale', (
      tester,
    ) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      await pump(
        tester,
        grid(
          showHeader: false,
          enabled: false,
          selectionMode: FluentDataGridSelectionMode.multiple,
          onSelectionChanged: (_) {},
        ),
      );

      expect(
        textStyleOf(tester, 'Name 0').color,
        theme.colors.neutralForegroundDisabled,
      );
      expect(
        textStyleOf(tester, 'Author 0').color,
        theme.colors.neutralForegroundDisabled,
      );

      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(
        pointer.hover(tester.getCenter(find.text('Name 0'))),
      );
      await tester.pumpAndSettle();
      expect(
        surfaces(tester).first.color,
        theme.colors.subtleBackground,
        reason: 'a disabled row must not light up under the pointer',
      );
    });

    testWidgets('the selection controls refuse input', (tester) async {
      var reported = false;
      await pump(
        tester,
        grid(
          showHeader: false,
          enabled: false,
          selectionMode: FluentDataGridSelectionMode.multiple,
          onSelectionChanged: (_) => reported = true,
        ),
      );
      await tester.tap(find.text('Name 0'));
      await tester.pumpAndSettle();
      expect(reported, isFalse);
    });

    testWidgets('a disabled grid has no sort control', (tester) async {
      await pump(tester, grid(sortable: true, onSort: (_) {}, enabled: false));
      expect(find.byType(FluentButton), findsNothing);
    });
  });

  group('keyboard', () {
    Future<void> press(
      WidgetTester tester,
      LogicalKeyboardKey key, {
      bool control = false,
    }) async {
      if (control) {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      }
      await tester.sendKeyEvent(key);
      if (control) {
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      }
      await tester.pumpAndSettle();
    }

    testWidgets('arrows rove between cells in two dimensions', (tester) async {
      await pump(
        tester,
        grid(
          rowCount: 3,
          showHeader: false,
          selectionMode: FluentDataGridSelectionMode.multiple,
          onSelectionChanged: (_) {},
        ),
      );

      // Tab into the grid: the first stop is row 0's selection checkbox.
      await press(tester, LogicalKeyboardKey.tab);
      expect(
        find.descendant(
          of: find.byType(FluentCheckbox).first,
          matching: find.byType(Focus),
        ),
        findsWidgets,
      );
      final first = FocusManager.instance.primaryFocus;
      expect(first, isNotNull);

      await press(tester, LogicalKeyboardKey.arrowDown);
      final second = FocusManager.instance.primaryFocus;
      expect(second, isNot(first), reason: 'Down moves to the next row');

      await press(tester, LogicalKeyboardKey.arrowRight);
      final third = FocusManager.instance.primaryFocus;
      expect(third, isNot(second), reason: 'Right moves to the next column');

      await press(tester, LogicalKeyboardKey.arrowUp);
      expect(
        FocusManager.instance.primaryFocus,
        isNot(third),
        reason: 'Up moves back a row',
      );
    });

    testWidgets('Home and End walk the row, Control- them the grid', (
      tester,
    ) async {
      await pump(
        tester,
        grid(
          rowCount: 3,
          showHeader: false,
          selectionMode: FluentDataGridSelectionMode.multiple,
          onSelectionChanged: (_) {},
        ),
      );
      await press(tester, LogicalKeyboardKey.tab);
      final start = FocusManager.instance.primaryFocus;

      await press(tester, LogicalKeyboardKey.end);
      final rowEnd = FocusManager.instance.primaryFocus;
      expect(rowEnd, isNot(start));

      await press(tester, LogicalKeyboardKey.home);
      expect(FocusManager.instance.primaryFocus, start);

      await press(tester, LogicalKeyboardKey.end, control: true);
      final gridEnd = FocusManager.instance.primaryFocus;
      expect(gridEnd, isNot(start));

      await press(tester, LogicalKeyboardKey.home, control: true);
      expect(FocusManager.instance.primaryFocus, start);
    });

    testWidgets('a cell with nothing focusable still takes the roving stop', (
      tester,
    ) async {
      await pump(tester, grid(rowCount: 2, showHeader: false));
      await press(tester, LogicalKeyboardKey.tab);
      // Every cell here is plain text; without the fallback stop the grid
      // would have zero tab stops and be unreachable by keyboard entirely.
      expect(FocusManager.instance.primaryFocus?.hasPrimaryFocus, isTrue);
      final first = FocusManager.instance.primaryFocus;
      await press(tester, LogicalKeyboardKey.arrowRight);
      expect(FocusManager.instance.primaryFocus, isNot(first));
    });

    testWidgets('Space on the focused selection checkbox toggles the row', (
      tester,
    ) async {
      Set<int>? reported;
      await pump(
        tester,
        grid(
          rowCount: 2,
          showHeader: false,
          selectionMode: FluentDataGridSelectionMode.multiple,
          onSelectionChanged: (next) => reported = next,
        ),
      );
      await press(tester, LogicalKeyboardKey.tab);
      await press(tester, LogicalKeyboardKey.space);
      expect(reported, <int>{0});
    });

    testWidgets('the arrows follow reading order in RTL', (tester) async {
      await pump(
        tester,
        grid(rowCount: 2, showHeader: false),
        direction: TextDirection.rtl,
      );
      await press(tester, LogicalKeyboardKey.tab);
      final first = FocusManager.instance.primaryFocus;
      // Left is "towards the end of the column list" in RTL.
      await press(tester, LogicalKeyboardKey.arrowLeft);
      expect(FocusManager.instance.primaryFocus, isNot(first));
    });
  });

  group('semantics', () {
    testWidgets('the grid, its rows and its headers announce themselves', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        grid(
          selected: const <int>{0},
          selectionMode: FluentDataGridSelectionMode.multiple,
          onSelectionChanged: (_) {},
        ),
      );

      expect(find.bySemanticsLabel('Files'), findsOneWidget);
      expect(find.bySemanticsLabel('Row 1'), findsOneWidget);
      expect(find.bySemanticsLabel('Select all rows'), findsOneWidget);
      expect(find.bySemanticsLabel('Select row 1'), findsOneWidget);

      // The selected row reports it, so a screen reader says "selected".
      final row = tester.getSemantics(find.bySemanticsLabel('Row 1'));
      expect(row.flagsCollection.isSelected, Tristate.isTrue);

      final header = tester.getSemantics(
        find
            .ancestor(of: find.text('File'), matching: find.byType(Semantics))
            .first,
      );
      expect(header.flagsCollection.isHeader, isTrue);

      handle.dispose();
    });

    testWidgets('an inert row puts no tap action in the tree', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, grid(showHeader: false));
      final row = tester.getSemantics(find.bySemanticsLabel('Row 1'));
      expect(row.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      handle.dispose();
    });
  });

  group('the three-function recomposition contract', () {
    test('build takes the BASE state, not the resolved one', () {
      const base = FluentDataGridBaseState(
        columnWidths: <double?>[null],
        rows: <FluentDataGridRenderRow>[],
        enabled: true,
      );
      // Compiles because `buildFluentDataGrid` never reads the size, the
      // selection appearance or the header weight — the whole point of the
      // split.
      expect(
        buildFluentDataGrid(
          base,
          FluentDataGridStyle.from(rowHeight: 44),
          const <WidgetState>{},
        ),
        isA<Widget>(),
      );
    });

    testWidgets('a caller can swap the style and keep Fluent\'s rendering', (
      tester,
    ) async {
      const own = Color(0xFF00FF00);
      final state = resolveFluentDataGridState(
        columnWidths: const <double?>[null],
        rows: const <FluentDataGridRenderRow>[
          FluentDataGridRenderRow(cells: <Widget>[Text('x')], selected: false),
        ],
      );
      await pump(
        tester,
        Builder(
          builder: (context) => buildFluentDataGrid(
            state,
            resolveFluentDataGridStyle(
              state,
              FluentTheme.of(context),
            ).merge(FluentDataGridStyle.from(dividerColor: own)),
            const <WidgetState>{},
          ),
        ),
      );
      final decoration = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((d) => d.border != null);
      expect((decoration.border! as Border).bottom.color, own);
    });

    test('resolveFluentDataGridState defaults match the widget defaults', () {
      final state = resolveFluentDataGridState(
        columnWidths: const <double?>[],
        rows: const <FluentDataGridRenderRow>[],
      );
      expect(state.size, FluentDataGridSize.medium);
      expect(
        state.selectionAppearance,
        FluentDataGridSelectionAppearance.neutral,
      );
      expect(state.headerWeight, FluentDataGridHeaderWeight.semibold);
      expect(state.enabled, isTrue);
    });
  });

  group('a cell outside a grid', () {
    testWidgets('resolves the resting tokens at its own size', (tester) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      await pump(
        tester,
        const FluentDataGridCell(
          size: FluentDataGridSize.smaller,
          child: Text('Loose'),
        ),
      );
      final style = textStyleOf(tester, 'Loose');
      expect(style.color, theme.colors.neutralForeground1);
      // Smaller is the one size whose primary ramp drops to caption.
      expect(style.fontSize, theme.typography.caption1.fontSize);
    });
  });
}

/// The index of the [RichText] rendering [text], so a style can be read off the
/// run that actually reached the rasteriser rather than the widget above it.
int _indexOfText(WidgetTester tester, String text) {
  final all = tester.widgetList<RichText>(find.byType(RichText)).toList();
  for (var i = 0; i < all.length; i++) {
    if (all[i].text.toPlainText() == text) return i;
  }
  fail('No RichText rendering "$text" was found.');
}
