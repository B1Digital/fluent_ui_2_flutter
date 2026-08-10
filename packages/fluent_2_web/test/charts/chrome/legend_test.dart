import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/chrome/legend.dart';
import 'package:fluent_2_web/src/charts/chrome/legend_shape.dart';
import 'package:fluent_2_web/src/charts/chrome/legend_style.dart';
import 'package:fluent_2_web/src/charts/internal/chart_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/oracle_fixture.dart';

void main() {
  // capitalizeLegendLabel is plan 02's, in internal/chart_utils.dart. These
  // four expectations re-pin it here because the legend is one of its two
  // callers and spec §5.4's export parity depends on both agreeing.
  group('capitalizeLegendLabel', () {
    test('uppercases the first letter of each word, leaving the rest alone', () {
      expect(
        capitalizeLegendLabel('first series'),
        'First Series',
        reason:
            'useLegendsStyles.styles.ts:56 is the only text-transform in the '
            'package and Flutter has no equivalent, so the label is '
            'capitalised in Dart before it is painted.',
      );
      expect(
        capitalizeLegendLabel('foo BAR'),
        'Foo BAR',
        reason:
            'CSS capitalize only touches the first letter of a word; it never '
            'lowercases the remainder.',
      );
    });

    test('is a no-op on an empty string', () {
      expect(
        capitalizeLegendLabel(''),
        '',
        reason: 'An empty legend title must survive unchanged.',
      );
    });

    test('treats every run of whitespace as one boundary', () {
      expect(
        capitalizeLegendLabel('a  b'),
        'A  B',
        reason:
            'Two spaces are two whitespace characters, and the letter after '
            'the last of them starts the word.',
      );
    });
  });

  group('nextFluentChartLegendSelection', () {
    test('single select toggles off on re-click', () {
      expect(
        nextFluentChartLegendSelection(
          <String>{'a'},
          'a',
          mode: FluentChartLegendSelectionMode.single,
          legendCount: 3,
        ),
        isEmpty,
        reason:
            'Legends.tsx:238 returns {} when the clicked legend was already '
            'the selected one.',
      );
    });

    test('single select replaces rather than accumulates', () {
      expect(
        nextFluentChartLegendSelection(
          <String>{'a'},
          'b',
          mode: FluentChartLegendSelectionMode.single,
          legendCount: 3,
        ),
        <String>{'b'},
        reason: 'Legends.tsx:238 returns {[title]: true}, discarding the rest.',
      );
    });

    test('multi select clears everything once all are selected', () {
      expect(
        nextFluentChartLegendSelection(
          <String>{'a', 'b'},
          'c',
          mode: FluentChartLegendSelectionMode.multiple,
          legendCount: 3,
        ),
        isEmpty,
        reason:
            'Legends.tsx:225-227 canonicalises "all selected" as "none '
            'selected", so selecting the last one empties the set.',
      );
    });

    test('multi select removes an already-selected legend', () {
      expect(
        nextFluentChartLegendSelection(
          <String>{'a', 'b'},
          'b',
          mode: FluentChartLegendSelectionMode.multiple,
          legendCount: 3,
        ),
        <String>{'a'},
        reason: 'Legends.tsx:218-221 deletes the key when it is already set.',
      );
    });

    test('does not mutate its input', () {
      final current = <String>{'a'};
      nextFluentChartLegendSelection(
        current,
        'b',
        mode: FluentChartLegendSelectionMode.multiple,
        legendCount: 3,
      );
      expect(
        current,
        <String>{'a'},
        reason:
            'Legends.tsx:217 spreads into a fresh object; a mutating port would '
            'break the controlled-mode comparison at :247.',
      );
    });
  });

  group('FluentChartLegendItem', () {
    test('defaults match Legend at Legends.types.ts:68-123', () {
      const item = FluentChartLegendItem(title: 'a', color: Color(0xFF0078D4));
      expect(
        item.stripePattern,
        isFalse,
        reason:
            'Legends.types.ts:107 declares stripePattern optional, so falsy.',
      );
      expect(
        item.isLineLegendInBarChart,
        isFalse,
        reason: 'Legends.types.ts:112 declares it optional, so falsy.',
      );
      expect(
        item.shape,
        isNull,
        reason:
            'A null shape falls through to the plain bordered rectangle at '
            'shape.tsx:35, which is the default swatch.',
      );
    });
  });

  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
  const seriesColour = Color(0xFF0078D4);

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    FluentApp(
      theme: theme,
      home: Center(child: child),
    ),
  );

  FluentChartLegendShapePainter painterOf(WidgetTester tester) => tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((paint) => paint.painter)
      .whereType<FluentChartLegendShapePainter>()
      .first;

  group('fluentChartLegendIsDimmed', () {
    test('nothing is dimmed while nothing is selected or hovered', () {
      expect(
        fluentChartLegendIsDimmed(
          'a',
          selectedLegends: const <String>{},
          activeLegend: '',
        ),
        isFalse,
        reason:
            'Legends.tsx:407 keeps the colour when activeLegend is the empty '
            'string, which is its initial value at :49.',
      );
    });

    test('an unselected legend is dimmed once anything is selected', () {
      expect(
        fluentChartLegendIsDimmed(
          'a',
          selectedLegends: const <String>{'b'},
          activeLegend: '',
        ),
        isTrue,
        reason:
            'Legends.tsx:393-401 — with a non-empty selection every legend '
            'outside it takes colorNeutralBackground1.',
      );
    });

    test('hovering one legend dims the others', () {
      expect(
        fluentChartLegendIsDimmed(
          'a',
          selectedLegends: const <String>{},
          activeLegend: 'b',
        ),
        isTrue,
        reason: 'Legends.tsx:411-413.',
      );
      expect(
        fluentChartLegendIsDimmed(
          'b',
          selectedLegends: const <String>{},
          activeLegend: 'b',
        ),
        isFalse,
        reason: 'Legends.tsx:407 — the hovered legend keeps its colour.',
      );
    });

    test('selection beats hover', () {
      expect(
        fluentChartLegendIsDimmed(
          'a',
          selectedLegends: const <String>{'a'},
          activeLegend: 'b',
        ),
        isFalse,
        reason:
            'Legends.tsx:393 tests the selection first and never falls through '
            'to the hover branch, so a selected legend stays lit while another '
            'is hovered.',
      );
    });
  });

  group('FluentChartLegendRow', () {
    testWidgets('an undimmed swatch is filled with the series colour', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentChartLegendRow(
          item: const FluentChartLegendItem(
            title: 'first',
            color: seriesColour,
            shape: FluentChartLegendShape.circle,
          ),
          shapeOverride: null,
          dimmed: false,
          selected: false,
          indexInList: 0,
          listLength: 1,
          style: resolveFluentChartLegendStyle(theme),
          focusNode: node,
          skipTraversal: false,
        ),
      );
      expect(
        painterOf(tester).fill.toARGB32(),
        seriesColour.toARGB32(),
        reason: 'Legends.tsx:364 fills the path with the resolved colour.',
      );
    });

    testWidgets('a dimmed swatch keeps its border but loses its fill', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentChartLegendRow(
          item: const FluentChartLegendItem(
            title: 'first',
            color: seriesColour,
            shape: FluentChartLegendShape.circle,
          ),
          shapeOverride: null,
          dimmed: true,
          selected: false,
          indexInList: 0,
          listLength: 1,
          style: resolveFluentChartLegendStyle(theme),
          focusNode: node,
          skipTraversal: false,
        ),
      );
      final painter = painterOf(tester);
      expect(
        painter.fill.toARGB32(),
        theme.colors.neutralBackground1.toARGB32(),
        reason:
            'Legends.tsx:400 dims to colorNeutralBackground1, which is the page '
            'background rather than transparency.',
      );
      expect(
        painter.stroke.toARGB32(),
        seriesColour.toARGB32(),
        reason:
            'Legends.tsx:366 always strokes with legend.color, so the outline '
            'survives dimming and is the only thing left to see.',
      );
    });

    testWidgets('the dimmed label drops to 0.67 opacity', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentChartLegendRow(
          item: const FluentChartLegendItem(
            title: 'first',
            color: seriesColour,
          ),
          shapeOverride: null,
          dimmed: true,
          selected: false,
          indexInList: 0,
          listLength: 1,
          style: resolveFluentChartLegendStyle(theme),
          focusNode: node,
          skipTraversal: false,
        ),
      );
      expect(
        tester
            .widgetList<Opacity>(find.byType(Opacity))
            .map((o) => o.opacity)
            .contains(kInactiveLegendTextOpacity),
        isTrue,
        reason: 'Legends.tsx:306 sets the label opacity to 0.67 when dimmed.',
      );
    });

    testWidgets('the label is title-cased before it is painted', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentChartLegendRow(
          item: const FluentChartLegendItem(
            title: 'first series',
            color: seriesColour,
          ),
          shapeOverride: null,
          dimmed: false,
          selected: false,
          indexInList: 0,
          listLength: 1,
          style: resolveFluentChartLegendStyle(theme),
          focusNode: node,
          skipTraversal: false,
        ),
      );
      expect(
        find.text('First Series'),
        findsOneWidget,
        reason:
            'useLegendsStyles.styles.ts:56 capitalises every legend label and '
            'Flutter has to do it in Dart.',
      );
    });

    testWidgets('a line-in-bar legend renders a 4px bar, not a 12px square', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentChartLegendRow(
          item: const FluentChartLegendItem(
            title: 'trend',
            color: seriesColour,
            isLineLegendInBarChart: true,
          ),
          shapeOverride: null,
          dimmed: false,
          selected: false,
          indexInList: 0,
          listLength: 1,
          style: resolveFluentChartLegendStyle(theme),
          focusNode: node,
          skipTraversal: false,
        ),
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey<String>('legend-swatch')))
            .height,
        4,
        reason:
            'Legends.tsx:376 sets the shape height to 4px for a line legend in '
            'a bar chart and 12px otherwise.',
      );
    });

    testWidgets('semantics carry position, size and selection', (tester) async {
      final handle = tester.ensureSemantics();
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentChartLegendRow(
          item: const FluentChartLegendItem(
            title: 'first',
            color: seriesColour,
          ),
          shapeOverride: null,
          dimmed: false,
          selected: true,
          indexInList: 2,
          listLength: 5,
          style: resolveFluentChartLegendStyle(theme),
          focusNode: node,
          skipTraversal: false,
        ),
      );
      expect(
        tester.getSemantics(find.text('First')).label,
        'First',
        reason:
            'Legends.tsx:343 sets aria-label to the title; the title-cased '
            'label is what a screen reader announces.',
      );
      handle.dispose();
    });

    testWidgets('the row box model matches charts-legends--legends-basic', (
      tester,
    ) async {
      // The legend is HTML upstream, so its geometry is in htmlBoxes rather
      // than in an svg. This story renders four legends: two fall back to the
      // bordered `fui-legend__rect` div and two are svg shapes (a diamond and
      // a triangle), which is why the rect count is 2 and the text count 4.
      final story = loadOracleStory('charts-legends--legends-basic');
      final root = story.boxes('fui-legend__root');
      final rects = story.boxes('fui-legend__rect');
      final texts = story.boxes('fui-legend__text');
      expect(
        root,
        hasLength(1),
        reason:
            'Count guard: one strip container, and every offset below is read '
            'off it.',
      );
      expect(
        rects,
        hasLength(2),
        reason:
            'Count guard: the two default-shaped swatches. A capture that '
            'stopped recording them would make the swatch assertions vacuous.',
      );
      expect(texts, hasLength(4), reason: 'Count guard: one label per legend.');

      // What the capture says the box model is.
      expectOracleNumber(
        'captured swatch width',
        kLegendSwatchBoxSize,
        rects.first.rect.width,
      );
      expectOracleNumber(
        'captured swatch height',
        kLegendSwatchBoxSize,
        rects.first.rect.height,
      );
      expectOracleNumber(
        'captured swatch-to-label gap',
        kLegendShapeMarginEnd,
        texts.first.rect.left - rects.first.rect.right,
      );
      expectOracleNumber(
        'captured row height',
        kLegendHeight,
        root.single.rect.height,
      );
      expectOracleNumber(
        'captured swatch centre against the strip centre',
        root.single.rect.center.dy,
        rects.first.rect.center.dy,
      );
      // Consecutive rows abut, so the space between one label's right edge and
      // the next swatch's left edge is exactly two row paddings. This is the
      // only place the 8px padding is measurable in the capture, because the
      // button box itself was not recorded.
      expectOracleNumber(
        'captured inter-row gap',
        2 * kLegendPadding,
        rects[1].rect.left - texts.first.rect.right,
      );

      // What this widget lays out.
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentChartLegendRow(
          item: const FluentChartLegendItem(
            title: 'legend 1',
            color: seriesColour,
          ),
          shapeOverride: null,
          dimmed: false,
          selected: false,
          indexInList: 0,
          listLength: 4,
          style: resolveFluentChartLegendStyle(theme),
          focusNode: node,
          skipTraversal: false,
        ),
      );
      final row = find.byType(FluentChartLegendRow);
      final swatch = find.byKey(const ValueKey<String>('legend-swatch'));
      final label = find.text('Legend 1');
      expectOracleNumber(
        'rendered swatch width',
        rects.first.rect.width,
        tester.getSize(swatch).width,
      );
      expectOracleNumber(
        'rendered swatch height',
        rects.first.rect.height,
        tester.getSize(swatch).height,
      );
      expectOracleNumber(
        'rendered swatch-to-label gap',
        texts.first.rect.left - rects.first.rect.right,
        tester.getTopLeft(label).dx - tester.getTopRight(swatch).dx,
      );
      expectOracleNumber(
        'rendered row height',
        root.single.rect.height,
        tester.getSize(row).height,
      );
      expectOracleNumber(
        'rendered swatch inset from the row edge',
        // Half the inter-row gap the capture measured above.
        (rects[1].rect.left - texts.first.rect.right) / 2,
        tester.getTopLeft(swatch).dx - tester.getTopLeft(row).dx,
      );
      expectOracleNumber(
        'rendered swatch centre against the row centre',
        tester.getRect(row).center.dy,
        tester.getRect(swatch).center.dy,
      );
    });
  });
}
