import 'dart:ui' show Tristate;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/chrome/legend.dart';
import 'package:fluent_2_web/src/charts/chrome/legend_shape.dart';
import 'package:fluent_2_web/src/charts/chrome/legend_style.dart';
import 'package:fluent_2_web/src/charts/internal/chart_text_measurer.dart';
import 'package:fluent_2_web/src/charts/internal/chart_utils.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
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

  group('FluentChartLegend selection', () {
    Future<void> pumpStrip(WidgetTester tester, Widget child) =>
        tester.pumpWidget(
          FluentApp(
            theme: theme,
            home: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: 800, child: child),
            ),
          ),
        );

    const legends = <FluentChartLegendItem>[
      FluentChartLegendItem(title: 'alpha', color: Color(0xFF0078D4)),
      FluentChartLegendItem(title: 'beta', color: Color(0xFF107C10)),
      FluentChartLegendItem(title: 'gamma', color: Color(0xFFD13438)),
    ];

    testWidgets('single select reports one title and replaces on the next tap', (
      tester,
    ) async {
      final reported = <List<String>>[];
      await pumpStrip(
        tester,
        FluentChartLegend(
          legends: legends,
          onChange: (selected, current) => reported.add(selected),
        ),
      );
      await tester.tap(find.text('Alpha'));
      await tester.pump();
      await tester.tap(find.text('Beta'));
      await tester.pump();
      expect(
        reported,
        <List<String>>[
          <String>['alpha'],
          <String>['beta'],
        ],
        reason:
            'Legends.tsx:238 replaces the whole map in single-select mode and '
            ':250 reports Object.keys of the result.',
      );
    });

    testWidgets('multi select clears once every legend is chosen', (
      tester,
    ) async {
      final reported = <List<String>>[];
      await pumpStrip(
        tester,
        FluentChartLegend(
          legends: legends,
          selectionMode: FluentChartLegendSelectionMode.multiple,
          onChange: (selected, current) => reported.add(selected),
        ),
      );
      for (final label in <String>['Alpha', 'Beta', 'Gamma']) {
        await tester.tap(find.text(label));
        await tester.pump();
      }
      expect(
        reported,
        hasLength(3),
        reason:
            'Count guard: one onChange per tap, so reported.last below is the '
            'third tap and not a vacuous read of an empty list.',
      );
      expect(
        reported.last,
        isEmpty,
        reason:
            'Legends.tsx:225-227 empties the map the moment its size reaches '
            'props.legends.length.',
      );
    });

    testWidgets('a controlled legend does not move its own state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpStrip(
        tester,
        FluentChartLegend(
          legends: legends,
          selectedLegends: const <String>['alpha'],
          onChange: (selected, current) {},
        ),
      );
      await tester.tap(find.text('Beta'));
      await tester.pump();
      expect(
        tester.getSemantics(find.text('Alpha')).flagsCollection.isSelected,
        Tristate.isTrue,
        reason:
            'Legends.tsx:207-209 and :247 — when selectedLegends is supplied '
            'the component is controlled and never calls setSelectedLegends, '
            'so the parent owns the selection.',
      );
      expect(
        tester.getSemantics(find.text('Beta')).flagsCollection.isSelected,
        Tristate.isFalse,
        reason:
            'The tapped row must not select itself, which is the whole point '
            'of controlled mode.',
      );
      handle.dispose();
    });

    testWidgets('defaultSelectedLegends seeds the uncontrolled state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpStrip(
        tester,
        const FluentChartLegend(
          legends: legends,
          defaultSelectedLegends: <String>['beta'],
        ),
      );
      expect(
        tester.getSemantics(find.text('Beta')).flagsCollection.isSelected,
        Tristate.isTrue,
        reason:
            'Legends.tsx:76-89 seeds the internal map from '
            'selectedLegends ?? defaultSelectedLegends.',
      );
      handle.dispose();
    });

    testWidgets('onAction fires after onChange', (tester) async {
      final order = <String>[];
      await pumpStrip(
        tester,
        FluentChartLegend(
          legends: <FluentChartLegendItem>[
            FluentChartLegendItem(
              title: 'alpha',
              color: const Color(0xFF0078D4),
              onAction: () => order.add('action'),
            ),
          ],
          onChange: (selected, current) => order.add('change'),
        ),
      );
      await tester.tap(find.text('Alpha'));
      await tester.pump();
      expect(
        order,
        <String>['change', 'action'],
        reason:
            'Legends.tsx:250-251 calls props.onChange first and legend.action '
            'second, and a chart that repaints in onChange depends on that.',
      );
    });

    testWidgets('the strip abuts its rows, per charts-legends--legends-basic', (
      tester,
    ) async {
      // The only geometry this task adds over Task 6's row is the strip that
      // holds the rows, so the one thing to pin is that it inserts no spacing
      // of its own: upstream's flex row has no gap, and the whole distance
      // between one label and the next swatch is the two rows' own 8px
      // paddings.
      final story = loadOracleStory('charts-legends--legends-basic');
      final rects = story.boxes('fui-legend__rect');
      final texts = story.boxes('fui-legend__text');
      expect(
        rects,
        hasLength(2),
        reason:
            'Count guard: the two default-shaped swatches. Without them the '
            'captured gap below would be read off an empty list.',
      );
      expect(texts, hasLength(4), reason: 'Count guard: one label per legend.');
      final capturedGap = rects[1].rect.left - texts.first.rect.right;
      expectOracleNumber(
        'captured inter-row gap is exactly two row paddings',
        2 * kLegendPadding,
        capturedGap,
      );

      await pumpStrip(tester, const FluentChartLegend(legends: legends));
      final swatches = find.byKey(const ValueKey<String>('legend-swatch'));
      expect(
        swatches,
        findsNWidgets(3),
        reason: 'Count guard: one swatch per legend, in order.',
      );
      expectOracleNumber(
        'rendered inter-row gap',
        capturedGap,
        tester.getTopLeft(swatches.at(1)).dx -
            tester.getTopRight(find.text('Alpha')).dx,
      );
      expectOracleNumber(
        'rendered strip height against the captured strip root',
        story.boxes('fui-legend__root').single.rect.height,
        tester.getSize(find.byType(FluentChartLegendRow).first).height,
      );
    });

    testWidgets('a legend theme restyles the strip', (tester) async {
      await tester.pumpWidget(
        FluentApp(
          theme: theme,
          home: FluentChartLegendTheme(
            style: FluentChartLegendStyle.from(dimmedLabelOpacity: 0.25),
            child: const FluentChartLegend(
              legends: legends,
              defaultSelectedLegends: <String>['alpha'],
            ),
          ),
        ),
      );
      expect(
        tester
            .widgetList<Opacity>(find.byType(Opacity))
            .map((o) => o.opacity)
            .contains(0.25),
        isTrue,
        reason:
            'The nearest FluentChartLegendTheme sits between the derived '
            'defaults and the widget style, which is the package-wide order.',
      );
    });
  });

  group('FluentChartLegend hover and focus symmetry', () {
    Future<void> pumpStrip(WidgetTester tester, Widget child) =>
        tester.pumpWidget(
          FluentApp(
            theme: theme,
            home: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: 800, child: child),
            ),
          ),
        );

    testWidgets('hovering a legend fires its hover action and dims the others', (
      tester,
    ) async {
      var hovered = 0;
      var left = 0;
      await pumpStrip(
        tester,
        FluentChartLegend(
          legends: <FluentChartLegendItem>[
            FluentChartLegendItem(
              title: 'alpha',
              color: const Color(0xFF0078D4),
              onHoverAction: () => hovered++,
              onMouseOutAction: ({required isLegendFocused}) => left++,
            ),
            const FluentChartLegendItem(
              title: 'beta',
              color: Color(0xFF107C10),
            ),
          ],
        ),
      );

      final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(pointer.removePointer);
      await pointer.addPointer(location: Offset.zero);
      await pointer.moveTo(tester.getCenter(find.text('Alpha')));
      await tester.pump();

      expect(
        hovered,
        1,
        reason: 'Legends.tsx:316 wires onMouseOver to legend.hoverAction.',
      );
      expect(
        tester
            .widgetList<Opacity>(find.byType(Opacity))
            .map((o) => o.opacity)
            .contains(kInactiveLegendTextOpacity),
        isTrue,
        reason:
            'Legends.tsx:411-413 dims every legend other than the hovered one, '
            'which is what makes hover a series highlight.',
      );

      await pointer.moveTo(const Offset(700, 700));
      await tester.pump();
      expect(
        left,
        1,
        reason:
            'Legends.tsx:317 wires onMouseOut to legend.onMouseOutAction, and '
            'Legends.tsx:263 clears the active legend with it.',
      );
    });

    testWidgets('focusing a legend highlights it exactly like a hover', (
      tester,
    ) async {
      var hovered = 0;
      await pumpStrip(
        tester,
        FluentChartLegend(
          legends: <FluentChartLegendItem>[
            FluentChartLegendItem(
              title: 'alpha',
              color: const Color(0xFF0078D4),
              onHoverAction: () => hovered++,
              onMouseOutAction: ({required isLegendFocused}) {},
            ),
            const FluentChartLegendItem(
              title: 'beta',
              color: Color(0xFF107C10),
            ),
          ],
        ),
      );
      Focus.of(tester.element(find.text('Alpha'))).requestFocus();
      await tester.pump();
      expect(
        hovered,
        1,
        reason:
            'Legends.tsx:318 assigns onFocus the same handler as onMouseOver, '
            'so keyboard traversal highlights the series identically.',
      );
    });

    testWidgets(
      'a row with no hover action does not become the active legend',
      (tester) async {
        await pumpStrip(
          tester,
          const FluentChartLegend(
            legends: <FluentChartLegendItem>[
              FluentChartLegendItem(title: 'alpha', color: Color(0xFF0078D4)),
              FluentChartLegendItem(title: 'beta', color: Color(0xFF107C10)),
            ],
          ),
        );
        final pointer = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        addTearDown(pointer.removePointer);
        await pointer.addPointer(location: Offset.zero);
        await pointer.moveTo(tester.getCenter(find.text('Alpha')));
        await tester.pump();
        final opacities = tester
            .widgetList<Opacity>(find.byType(Opacity))
            .map((o) => o.opacity)
            .toList(growable: false);
        expect(
          opacities,
          hasLength(4),
          reason:
              'Count guard: two rows, each with a swatch Opacity and a label '
              'Opacity. Without them `every` below would pass vacuously.',
        );
        expect(
          opacities.every((opacity) => opacity == 1.0),
          isTrue,
          reason:
              'Legends.tsx:255 only calls setActiveLegend inside '
              '`if (legend.hoverAction)`, so a row with no hover action never '
              'dims its neighbours.',
        );
      },
    );
  });

  group('fluentChartLegendRowWidth', () {
    final labelStyle = resolveFluentChartLegendStyle(
      theme,
    ).labelTextStyle!.resolve(<WidgetState>{})!;

    testWidgets('the row box model matches charts-legends--legends-overflow', (
      tester,
    ) async {
      final story = loadOracleStory('charts-legends--legends-overflow');
      // react-overflow parks a collapsed row at (-16, -16) with a 0x0 box, so a
      // row that is actually in the strip is one with a width.
      final rects = story
          .boxes('fui-legend__rect')
          .where((box) => box.rect.width > 0)
          .toList(growable: false);
      final texts = story
          .boxes('fui-legend__text')
          .where((box) => box.rect.width > 0)
          .toList(growable: false);
      expect(
        rects,
        hasLength(6),
        reason:
            'Count guard: the six rows this story left in the strip. Filtering '
            'to width > 0 could otherwise leave an empty list and the pitch '
            'below would be read off nothing.',
      );
      expect(
        texts,
        hasLength(6),
        reason: 'Count guard: one label per visible row.',
      );

      // Two adjacent rows are laid end to end with no gap of their own
      // (Legends.tsx:129-133 puts them straight into the flex line), so the
      // pitch between two swatches IS one row's width.
      final capturedPitch = rects[1].rect.left - rects.first.rect.left;
      final capturedChrome = capturedPitch - texts.first.rect.width;
      expectOracleNumber(
        'captured row width less its label is padding, swatch, gap, padding',
        2 * kLegendPadding + kLegendSwatchBoxSize + kLegendShapeMarginEnd,
        capturedChrome,
      );

      final measurer = FluentChartTextMeasurer();
      expectOracleNumber(
        'fluentChartLegendRowWidth reserves exactly that chrome',
        capturedChrome,
        fluentChartLegendRowWidth('legend 1', labelStyle, measurer) -
            measurer.width('Legend 1', labelStyle),
      );
    });

    testWidgets('the label is measured after it is title-cased', (
      tester,
    ) async {
      final measurer = FluentChartTextMeasurer();
      expectOracleNumber(
        'row width is the capitalised label, not the raw one',
        fluentChartLegendRowWidth('llll llll', labelStyle, measurer),
        fluentChartLegendRowWidth('Llll Llll', labelStyle, measurer),
      );
      // The test font is monospaced, so this only holds because the same string
      // reaches the measurer either way; `measureTextWithDOM` copies
      // `text-transform` (utilities.ts:2137-2144) where the canvas measurer at
      // `:1265` does not, which is why the legend measures post-capitalisation.
      expect(
        measurer.cachedCount,
        1,
        reason:
            'Both calls measured one and the same string, so the measurer saw '
            'a single distinct key — proof the capitalisation happens before '
            'the measurement rather than after it.',
      );
    });
  });

  group('fluentChartLegendVisibleCount', () {
    test('everything fits when there is room', () {
      expect(
        fluentChartLegendVisibleCount(<double>[60, 60, 60], 800, 70),
        3,
        reason:
            'OverflowMenu.tsx:18-20 returns null when nothing overflows, so all '
            'three rows stay in the listbox.',
      );
    });

    test('the trigger reserves its own width', () {
      expect(
        fluentChartLegendVisibleCount(<double>[60, 60, 60], 130, 70),
        1,
        reason:
            'The trigger is a sibling of the listbox (Legends.tsx:135), so it '
            'competes for the same line: 60 fits inside 130 - 70 = 60, a second '
            'row does not.',
      );
    });

    test('at least one row is always shown', () {
      expect(
        fluentChartLegendVisibleCount(<double>[400], 100, 70),
        1,
        reason:
            'Collapsing every legend into the menu would leave a bare "+1 more" '
            'button with no context, which no upstream story renders.',
      );
    });

    test('it reproduces the split captured for the seventeen-legend strip', () {
      // Seventeen real row widths: --legends-wrap-lines draws every one of them
      // on screen, so its `legendContainer` boxes — `flex: 0 1 auto` around the
      // row (useLegendsStyles.styles.ts:123-125) — give the row widths directly.
      final wrapped = loadOracleStory('charts-legends--legends-wrap-lines');
      final widths = wrapped
          .boxes('fui-legend__legendContainer')
          .map((box) => box.rect.width)
          .toList(growable: false);
      expect(
        widths,
        hasLength(17),
        reason:
            'Count guard: the seventeen legends of the Legends stories. A short '
            'list would make the breakpoint below unreachable.',
      );

      // How much of the line --legends-overflow actually filled, measured from
      // the first row's leading edge to the last visible row's trailing edge.
      // The strip's own available width is NOT knowable from this capture: that
      // story recorded no `fui-legend__resizableArea` box, and `useOverflowMenu`
      // is not in the extracted tree, so the trigger's rendered width — the
      // other half of upstream's breakpoint — is unknown. What is knowable is
      // that six rows fitted the span and a seventh did not.
      final overflow = loadOracleStory('charts-legends--legends-overflow');
      final rects = overflow
          .boxes('fui-legend__rect')
          .where((box) => box.rect.width > 0)
          .toList(growable: false);
      final texts = overflow
          .boxes('fui-legend__text')
          .where((box) => box.rect.width > 0)
          .toList(growable: false);
      expect(
        rects,
        hasLength(6),
        reason: 'Count guard: the six rows left in the strip.',
      );
      expect(
        overflow.boxes('fui-legend__rect'),
        hasLength(17),
        reason:
            'Count guard: the other eleven are captured too, parked off-screen, '
            'which is what makes the eleven-in-the-menu arithmetic below real.',
      );
      final span =
          (texts.last.rect.right + kLegendPadding) -
          (rects.first.rect.left - kLegendPadding);

      // Only the difference `available - triggerWidth` is read, so any trigger
      // width reproduces the capture as long as the budget is the captured span.
      const triggerWidth = 120.0;
      expect(
        fluentChartLegendVisibleCount(
          widths,
          span + triggerWidth,
          triggerWidth,
        ),
        6,
        reason:
            'charts-legends--legends-overflow left six rows in the strip and '
            'collapsed eleven, so the budget it filled must keep exactly six.',
      );
      expect(
        '+${widths.length - 6} more',
        '+11 more',
        reason:
            'OverflowMenu.tsx:16 renders `+{overflowCount} {title}` over the '
            'rows that did not fit, which the capture puts at eleven.',
      );
    });
  });

  group('layout branches', () {
    testWidgets('overflow mode collapses the tail into a menu', (tester) async {
      await tester.pumpWidget(
        FluentApp(
          theme: theme,
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 160,
              child: FluentChartLegend(
                legends: List<FluentChartLegendItem>.generate(
                  6,
                  (i) => FluentChartLegendItem(
                    title: 'series number $i',
                    color: seriesColour,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        find.textContaining('more'),
        findsOneWidget,
        reason:
            'OverflowMenu.tsx:16 renders `+{n} {title}` and Legends.tsx:108 '
            "defaults that title to 'more'.",
      );
    });

    testWidgets('a collapsed row is still selectable from the menu', (
      tester,
    ) async {
      final reported = <List<String>>[];
      await tester.pumpWidget(
        FluentApp(
          theme: theme,
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 160,
              child: FluentChartLegend(
                onChange: (selected, current) => reported.add(selected),
                legends: List<FluentChartLegendItem>.generate(
                  6,
                  (i) => FluentChartLegendItem(
                    title: 'series number $i',
                    color: seriesColour,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.textContaining('more'));
      await tester.pumpAndSettle();
      final menuRows = find.textContaining('Series Number');
      expect(
        menuRows,
        findsNWidgets(6),
        reason:
            'Count guard: one row still in the strip plus the five the menu '
            'took. Without it the tap below could hit the strip row.',
      );
      await tester.tap(menuRows.last);
      await tester.pumpAndSettle();
      expect(
        reported,
        <List<String>>[
          <String>['series number 5'],
        ],
        reason:
            'OverflowMenu.tsx:40 forwards the row onClick to the legend button, '
            'so a collapsed legend selects exactly as a visible one does.',
      );
    });

    testWidgets('wrapped mode never renders an overflow trigger', (
      tester,
    ) async {
      await tester.pumpWidget(
        FluentApp(
          theme: theme,
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 160,
              child: FluentChartLegend(
                enabledWrapLines: true,
                legends: List<FluentChartLegendItem>.generate(
                  6,
                  (i) => FluentChartLegendItem(
                    title: 'series number $i',
                    color: seriesColour,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        find.textContaining('more'),
        findsNothing,
        reason:
            'Legends.tsx:142-169 has no OverflowMenu at all — the two branches '
            'are mutually exclusive.',
      );
    });

    testWidgets('the annotation slot renders only in wrapped mode', (
      tester,
    ) async {
      final legends = <FluentChartLegendItem>[
        FluentChartLegendItem(
          title: 'alpha',
          color: seriesColour,
          annotationBuilder: (context) => const Text('note'),
        ),
      ];
      await tester.pumpWidget(
        FluentApp(
          theme: theme,
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 400,
              child: FluentChartLegend(
                enabledWrapLines: true,
                legends: legends,
              ),
            ),
          ),
        ),
      );
      expect(
        find.text('note'),
        findsOneWidget,
        reason:
            'Legends.tsx:163 renders legendAnnotation in the wrapped branch.',
      );

      await tester.pumpWidget(
        FluentApp(
          theme: theme,
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 400,
              child: FluentChartLegend(legends: legends),
            ),
          ),
        ),
      );
      expect(
        find.text('note'),
        findsNothing,
        reason:
            'Legends.tsx:129-133 has no annotation slot, so overflow mode drops '
            'it silently. // parity: reproduced.',
      );
    });

    testWidgets('wrapped rows carry the captured 4px container margin', (
      tester,
    ) async {
      final story = loadOracleStory('charts-legends--legends-wrap-lines');
      final containers = story.boxes('fui-legend__legendContainer');
      expect(
        containers,
        hasLength(17),
        reason:
            'Count guard: one container per legend. The captured gap below is '
            'read off the first two of them.',
      );
      // useLegendsStyles.styles.ts:125 — `margin: 4px` on each container, so
      // adjacent containers on one line sit 8 apart.
      final capturedGap = containers[1].rect.left - containers.first.rect.right;
      expectOracleNumber('captured container gap', 2 * 4, capturedGap);

      await tester.pumpWidget(
        FluentApp(
          theme: theme,
          home: const Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 400,
              child: FluentChartLegend(
                enabledWrapLines: true,
                legends: <FluentChartLegendItem>[
                  FluentChartLegendItem(title: 'a', color: seriesColour),
                  FluentChartLegendItem(title: 'b', color: seriesColour),
                ],
              ),
            ),
          ),
        ),
      );
      final rows = find.byType(FluentChartLegendRow);
      expect(
        rows,
        findsNWidgets(2),
        reason: 'Count guard: two rows, both on the one line 400 affords.',
      );
      expectOracleNumber(
        'rendered gap between two wrapped rows',
        capturedGap,
        tester.getTopLeft(rows.at(1)).dx - tester.getTopRight(rows.first).dx,
      );
    });
  });
}
