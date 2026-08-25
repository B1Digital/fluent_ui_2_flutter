import 'package:fluent_2/src/charts/chart_table.dart';
import 'package:fluent_2/src/charts/internal/chart_colors.dart';
import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/oracle_fixture.dart';

/// The contrast numbers below were computed from `utilities/colors.ts:149-169`
/// — sRGB linearisation `v <= 0.04045 ? v/12.92 : ((v+0.055)/1.055)^2.4`,
/// luminance `0.2126r + 0.7152g + 0.0722b`, ratio `(max+0.05)/(min+0.05)` —
/// and not from the recon brief, whose worked examples for both the
/// shared-background and the double-failure branch were arithmetically wrong.
void main() {
  const key = Key('table');
  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  // The CSS named colours the upstream example uses. There is no d3-colour
  // parse step in the Dart port: a caller hands over a Color, so the only part
  // of `d3.color(x)?.formatHex()` that survives is the alpha drop.
  const dimgray = Color(0xFF696969);
  const gray = Color(0xFF808080);
  const white = Color(0xFFFFFFFF);

  Future<void> pump(
    WidgetTester tester,
    Widget table, {
    FluentThemeData? themeData,
  }) => tester.pumpWidget(
    FluentApp(
      theme: themeData ?? theme,
      home: Center(child: table),
    ),
  );

  group('contrast maths', () {
    test('white on gray clears the threshold of 3', () {
      expect(
        fluentColorContrast(white, gray),
        closeTo(3.9494396480491156, 1e-9),
        reason:
            'utilities/colors.ts:165-169 — this is the value that makes '
            'the shared-background heuristic accept #808080.',
      );
    });

    test('gray on near-gray fails, and so does its inversion', () {
      expect(
        fluentColorContrast(gray, const Color(0xFF7F7F7F)),
        closeTo(1.013841788566826, 1e-9),
        reason:
            'Below the threshold of 3, so getSafeBackgroundColor '
            '(ChartTable.tsx:23-47) tries the inversion.',
      );
      expect(
        fluentColorContrast(gray, gray),
        closeTo(1.0, 1e-12),
        reason:
            'invertHexColor(#7f7f7f) is #808080 (ChartTable.tsx:14-21), '
            'so the inverted attempt is a colour against itself.',
      );
    });
  });

  group('fluentChartTableSafeBackground', () {
    test('keeps a background that already clears 3', () {
      expect(
        fluentChartTableSafeBackground(
          foreground: white,
          background: gray,
          colors: theme.colors,
        ).toARGB32(),
        gray.toARGB32(),
        reason:
            'ChartTable.tsx:41-43 returns the background unchanged when '
            'the contrast is at least 3.',
      );
    });

    test('inverts a failing background when the inversion clears 3', () {
      // #FFFFFF against #EEEEEE is 1.16; the inversion #111111 is 18.9.
      expect(
        fluentChartTableSafeBackground(
          foreground: white,
          background: const Color(0xFFEEEEEE),
          colors: theme.colors,
        ).toARGB32(),
        const Color(0xFF111111).toARGB32(),
        reason:
            'ChartTable.tsx:45-46 inverts each channel as 255 - c and '
            'accepts the inversion when it clears 3.',
      );
    });

    test('falls back to a resolved colour when both attempts fail', () {
      expect(
        fluentChartTableSafeBackground(
          foreground: gray,
          background: const Color(0xFF7F7F7F),
          colors: theme.colors,
        ).toARGB32(),
        theme.colors.neutralBackground1.toARGB32(),
        reason:
            'ChartTable.tsx:47 returns the RAW TOKEN STRING here, which is '
            'an invalid CSS value and renders transparent. The Dart port '
            'returns the resolved colorNeutralBackground1 instead; the '
            'divergence is deliberate and documented in the source.',
      );
    });

    test('null foreground and background take the token defaults', () {
      expect(
        fluentChartTableSafeBackground(
          foreground: null,
          background: null,
          colors: theme.colors,
        ).toARGB32(),
        theme.colors.neutralBackground1.toARGB32(),
        reason:
            'ChartTable.tsx:24-25 and :30-31 substitute colorNeutralForeground1 '
            'and colorNeutralBackground1 for a missing side before measuring, '
            'and that pair clears 3 in the light theme.',
      );
    });

    test('exactly 3.0 takes the accepting branch', () {
      // The >= comparison is bracketed rather than hit exactly: no 8-bit grey
      // lands on 3.0 against white, so the pair immediately above it is
      // asserted to survive unchanged.
      const boundary = Color(0xFF8E8E8E);
      expect(
        fluentColorContrast(white, boundary),
        greaterThanOrEqualTo(3.0),
        reason: 'Bracketing the >= 3 comparison at ChartTable.tsx:40.',
      );
      expect(
        fluentChartTableSafeBackground(
          foreground: white,
          background: boundary,
          colors: theme.colors,
        ).toARGB32(),
        boundary.toARGB32(),
        reason: 'A pair at or above 3 is kept.',
      );
    });
  });

  group('shared header background', () {
    test('two distinct backgrounds pick the SECOND in insertion order', () {
      final resolved =
          FluentChartTableHeaderColours.resolve(const <FluentChartTableCell>[
            FluentChartTableCell(
              value: 'A',
              textStyle: TextStyle(color: white),
              backgroundColor: dimgray,
            ),
            FluentChartTableCell(
              value: 'B',
              textStyle: TextStyle(color: white),
              backgroundColor: gray,
            ),
            FluentChartTableCell(
              value: 'C',
              textStyle: TextStyle(color: white),
              backgroundColor: gray,
            ),
          ], theme.colors);
      expect(
        resolved.useShared,
        isTrue,
        reason:
            'ChartTable.tsx:81-90 runs the heuristic for a set of size 1 '
            'or 2 and stops at the first header whose foreground clears 3.',
      );
      expect(
        resolved.shared!.toARGB32(),
        gray.toARGB32(),
        reason:
            'ChartTable.tsx:82 takes element [1] for a set of size 2 — '
            'the SECOND distinct colour encountered, not the first. Column 0 '
            'asked for dimgray and gets gray anyway.',
      );
    });

    test('three distinct backgrounds skip the heuristic entirely', () {
      final resolved =
          FluentChartTableHeaderColours.resolve(const <FluentChartTableCell>[
            FluentChartTableCell(backgroundColor: dimgray),
            FluentChartTableCell(backgroundColor: gray),
            FluentChartTableCell(backgroundColor: Color(0xFF404040)),
          ], theme.colors);
      expect(
        resolved.useShared,
        isFalse,
        reason:
            'ChartTable.tsx:81 gates the heuristic on size 1 or 2; above '
            'that upstream deliberately lets the contrast fail (:78-79).',
      );
    });

    test('a set of size one takes element [0]', () {
      final resolved =
          FluentChartTableHeaderColours.resolve(const <FluentChartTableCell>[
            FluentChartTableCell(
              textStyle: TextStyle(color: white),
              backgroundColor: gray,
            ),
          ], theme.colors);
      expect(
        resolved.shared!.toARGB32(),
        gray.toARGB32(),
        reason: 'ChartTable.tsx:82 takes element [0] for a set of size 1.',
      );
    });

    test('no header foreground means no shared background', () {
      final resolved =
          FluentChartTableHeaderColours.resolve(const <FluentChartTableCell>[
            FluentChartTableCell(backgroundColor: gray),
            FluentChartTableCell(backgroundColor: gray),
          ], theme.colors);
      expect(
        resolved.useShared,
        isFalse,
        reason:
            'ChartTable.tsx:84 requires a truthy foreground before it '
            'measures the contrast.',
      );
    });

    test('alpha is dropped before the set is built', () {
      final resolved =
          FluentChartTableHeaderColours.resolve(const <FluentChartTableCell>[
            FluentChartTableCell(
              textStyle: TextStyle(color: white),
              backgroundColor: Color(0x40808080),
            ),
            FluentChartTableCell(
              textStyle: TextStyle(color: white),
              backgroundColor: gray,
            ),
          ], theme.colors);
      expect(
        resolved.shared!.toARGB32(),
        gray.toARGB32(),
        reason:
            'ChartTable.tsx:63 normalises through `formatHex`, which discards '
            'alpha, so a translucent and an opaque #808080 are ONE entry and '
            'the set has size 1 rather than 2.',
      );
    });
  });

  group('widget', () {
    const headers = <FluentChartTableCell>[
      FluentChartTableCell(value: 'One'),
      FluentChartTableCell(value: 'Two'),
      FluentChartTableCell(value: 'Three'),
    ];
    const rows = <List<FluentChartTableCell>>[
      <FluentChartTableCell>[
        FluentChartTableCell(value: 1),
        FluentChartTableCell(value: 2),
        FluentChartTableCell(value: 3),
      ],
      <FluentChartTableCell>[
        FluentChartTableCell(value: 4),
        FluentChartTableCell(value: 5),
        FluentChartTableCell(value: 6),
      ],
    ];

    testWidgets('adjacent columns are separated by ONE border, not two', (
      tester,
    ) async {
      await pump(
        tester,
        const SizedBox(
          width: 600,
          child: FluentChartTable(
            key: key,
            headers: headers,
            rows: rows,
            columnWidth: 100,
          ),
        ),
      );
      final first = tester.getTopLeft(find.text('One'));
      final second = tester.getTopLeft(find.text('Two'));
      expect(
        second.dx - first.dx,
        closeTo(102, 0.01),
        reason:
            'border-collapse (useChartTableStyles.styles.ts:29) merges the '
            'adjacent 2px cell edges into one 2px grid line, so the column '
            'pitch is 100 + 2. A Row of DecoratedBoxes would give 100 + 4.',
      );
    });

    testWidgets('cell content is inset by 8 on every side', (tester) async {
      await pump(
        tester,
        const SizedBox(
          width: 600,
          child: FluentChartTable(
            key: key,
            headers: headers,
            rows: rows,
            columnWidth: 100,
          ),
        ),
      );
      final cell = tester.getRect(
        find
            .ancestor(of: find.text('One'), matching: find.byType(Padding))
            .first,
      );
      final text = tester.getRect(find.text('One'));
      expect(
        text.left - cell.left,
        closeTo(8, 0.01),
        reason:
            'useChartTableStyles.styles.ts:36 pads every cell by '
            'spacingHorizontalS on all four sides.',
      );
    });

    /// The grid's own box — the [Table] plus the right and bottom lines no
    /// cell owns.
    Rect gridRect(WidgetTester tester) => tester.getRect(
      find
          .ancestor(of: find.byType(Table), matching: find.byType(Container))
          .first,
    );

    testWidgets('the collapsed grid line is laid out, not drawn over the top', (
      tester,
    ) async {
      await pump(
        tester,
        const SizedBox(
          width: 600,
          child: FluentChartTable(key: key, headers: headers, rows: rows),
        ),
      );
      final grid = gridRect(tester);
      expect(
        tester.getTopLeft(find.text('1')).dy -
            tester.getTopLeft(find.text('One')).dy,
        closeTo(34, 0.01),
        reason:
            'border-collapse (useChartTableStyles.styles.ts:29) merges the '
            'adjacent 2px edges into ONE line that still occupies 2px of the '
            'table box, so the row pitch is 8 + 16 + 8 + 2. The capture agrees: '
            'the reference PNG for charts-charttable--chart-table-basic puts '
            'its horizontal lines on rows 0, 34, 68, 102, 136 and 170. '
            'TableBorder cannot produce this — RenderTable\'s border appears '
            'in neither _computeColumnWidths nor performLayout, so it strokes '
            'a boundary that took no space and every row comes out 32.',
      );
      expect(
        tester.getTopLeft(find.text('One')).dx - grid.left,
        closeTo(10, 0.01),
        reason:
            'Same rule across: the cell\'s 8px padding starts AFTER its 2px '
            'line, so the first column\'s text sits 10 inside the grid. The '
            'capture puts it at x = 10 with the line on 0 and 1.',
      );
      expect(
        grid.height,
        closeTo(3 * 34 + 2, 0.01),
        reason:
            'Three rows of 34 plus the bottom line, which is the one no cell '
            'owns. The capture\'s five-row grid is 5 x 34 + 2 = 172 tall.',
      );
    });

    testWidgets('the grid fills its box, splitting the surplus in proportion '
        'to content rather than equally', (tester) async {
      // One long heading against two short ones. The surplus is large enough
      // that the two distributions are nowhere near each other: proportional
      // gives roughly 550/75/75, an equal split of the same surplus gives
      // 347/176/176, and a flat share gives 233/233/233.
      await pump(
        tester,
        const SizedBox(
          width: 700,
          child: FluentChartTable(
            key: key,
            headers: <FluentChartTableCell>[
              FluentChartTableCell(value: 'wwwwwwwwwwwwwwwwwwww'),
              FluentChartTableCell(value: 'w'),
              FluentChartTableCell(value: 'w'),
            ],
          ),
        ),
      );
      final grid = gridRect(tester);
      expect(
        grid.width,
        closeTo(700, 0.01),
        reason:
            'ChartTable.tsx:127-131 puts the width on the <table>, defaulting '
            'to 100%, so the grid fills its box. With the width on the outer '
            'box instead and IntrinsicColumnWidth inside a horizontal '
            'viewport, the table sees an unbounded constraint and shrink-wraps '
            'to its content — which is how the six-column capture came out '
            '376px wide against upstream\'s 700.',
      );
      final long = tester.getTopLeft(find.text('wwwwwwwwwwwwwwwwwwww')).dx;
      final short = tester.getTopLeft(find.text('w').at(0)).dx;
      final shorter = tester.getTopLeft(find.text('w').at(1)).dx;
      expect(
        (shorter - short) * 3,
        lessThan(short - long),
        reason:
            'Chromium hands the surplus to the columns in proportion to their '
            'max-content width. Equal shares would put the two short columns '
            'within a factor of two of the long one; proportional shares keep '
            'them a factor of seven apart.',
      );
    });

    testWidgets('a caller width lands on the grid, not on the root', (
      tester,
    ) async {
      await pump(
        tester,
        const SizedBox(
          width: 600,
          child: FluentChartTable(
            key: key,
            headers: headers,
            rows: rows,
            width: 400,
          ),
        ),
      );
      expect(
        gridRect(tester).width,
        closeTo(400, 0.01),
        reason:
            'ChartTable.tsx:130 sets `width` on the <table> element. The '
            'capture proves the root is not the thing being sized: its '
            'fui-ChartTable__root box is 944 wide (100% of the parent) while '
            'the table inside it is exactly the 700 the story asked for.',
      );
    });

    testWidgets('every cell is a tab stop, header row first', (tester) async {
      await pump(
        tester,
        const SizedBox(
          width: 600,
          child: FluentChartTable(key: key, headers: headers, rows: rows),
        ),
      );
      expect(
        find.descendant(of: find.byKey(key), matching: find.byType(Focus)),
        findsNWidgets(9),
        reason:
            'ChartTable.tsx:147 and :166 give every th and td '
            'tabIndex={0}; a 3x2 table is 3 + 6 = 9 stops.',
      );
    });

    testWidgets('the header row carries header semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        const SizedBox(
          width: 600,
          child: FluentChartTable(key: key, headers: headers, rows: rows),
        ),
      );
      expect(
        tester.getSemantics(find.text('One')),
        isSemantics(isHeader: true),
        reason:
            'A <th> carries native header semantics upstream; canvas-free '
            'Flutter needs it declared, and the recon brief calls it out.',
      );
      expect(
        tester.getSemantics(find.text('1')),
        isSemantics(isHeader: false),
        reason: 'A <td> (ChartTable.tsx:166) is not a header.',
      );
      handle.dispose();
    });

    testWidgets('no headers renders the plain no-data text', (tester) async {
      await pump(
        tester,
        const FluentChartTable(key: key, headers: <FluentChartTableCell>[]),
      );
      expect(
        find.text('No data available'),
        findsOneWidget,
        reason:
            'ChartTable.tsx:56-58 returns a bare <div>No data available'
            '</div> — plain text, deliberately NOT a role="alert", unlike '
            'every other chart in this family.',
      );
    });

    testWidgets('a body with no rows still renders the header', (tester) async {
      await pump(
        tester,
        const SizedBox(
          width: 600,
          child: FluentChartTable(key: key, headers: headers),
        ),
      );
      expect(
        find.text('One'),
        findsOneWidget,
        reason: 'ChartTable.tsx:154 gates only the tbody on rows.length > 0.',
      );
    });

    testWidgets('null and false render as nothing', (tester) async {
      await pump(
        tester,
        const SizedBox(
          width: 600,
          child: FluentChartTable(
            key: key,
            headers: <FluentChartTableCell>[
              FluentChartTableCell(),
              FluentChartTableCell(value: false),
              FluentChartTableCell(value: 0),
            ],
          ),
        ),
      );
      expect(
        find.text(''),
        findsNWidgets(2),
        reason:
            'React renders null and false as nothing but 0 as "0"; '
            'ChartTable.tsx:148 interpolates header.value directly.',
      );
      expect(
        find.text('0'),
        findsOneWidget,
        reason: 'Zero is not falsy for a React text child.',
      );
    });

    testWidgets('the shared background overrides a column that asked for '
        'another', (tester) async {
      await pump(
        tester,
        const SizedBox(
          width: 600,
          child: FluentChartTable(
            key: key,
            headers: <FluentChartTableCell>[
              FluentChartTableCell(
                value: 'A',
                textStyle: TextStyle(color: white),
                backgroundColor: dimgray,
              ),
              FluentChartTableCell(
                value: 'B',
                textStyle: TextStyle(color: white),
                backgroundColor: gray,
              ),
            ],
          ),
        ),
      );
      final painted = tester
          .widgetList<ColoredBox>(
            find.descendant(
              of: find.byKey(key),
              matching: find.byType(ColoredBox),
            ),
          )
          .map((box) => box.color.toARGB32())
          .toList();
      expect(
        painted,
        <int>[gray.toARGB32(), gray.toARGB32()],
        reason:
            'ChartTable.tsx:141-142 assigns sharedBackgroundColor to every '
            'header, so column 0 loses the dimgray it asked for.',
      );
    });

    testWidgets('a cell that names neither colour never enters the pass', (
      tester,
    ) async {
      await pump(
        tester,
        const SizedBox(
          width: 600,
          child: FluentChartTable(key: key, headers: headers, rows: rows),
        ),
      );
      final painted = tester
          .widgetList<ColoredBox>(
            find.descendant(
              of: find.byKey(key),
              matching: find.byType(ColoredBox),
            ),
          )
          .map((box) => box.color.toARGB32())
          .toList();
      expect(
        painted,
        List<int>.filled(3, theme.colors.neutralBackground3.toARGB32()),
        reason:
            'ChartTable.tsx:143 gates getSafeBackgroundColor on `fg || bg`, so '
            'the three plain headers keep the class default '
            '(useChartTableStyles.styles.ts:34) and the six plain body cells '
            'paint no fill at all (:44-53 declares none).',
      );
    });

    testWidgets('high contrast drops every caller colour', (tester) async {
      final highContrast = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      await pump(
        tester,
        const SizedBox(
          width: 600,
          child: FluentChartTable(
            key: key,
            headers: <FluentChartTableCell>[
              FluentChartTableCell(
                value: 'A',
                textStyle: TextStyle(color: white),
                backgroundColor: dimgray,
              ),
            ],
            rows: <List<FluentChartTableCell>>[
              <FluentChartTableCell>[
                FluentChartTableCell(
                  value: 'a',
                  textStyle: TextStyle(color: white),
                  backgroundColor: dimgray,
                ),
              ],
            ],
          ),
        ),
        themeData: highContrast,
      );
      final painted = tester
          .widgetList<ColoredBox>(
            find.descendant(
              of: find.byKey(key),
              matching: find.byType(ColoredBox),
            ),
          )
          .map((box) => box.color.toARGB32())
          .toList();
      expect(
        painted,
        <int>[highContrast.colors.neutralBackground3.toARGB32()],
        reason:
            'useChartTableStyles.styles.ts:39-42 rewrites the header fill to '
            'the system Window colour under forced colours, and the body cell '
            'loses its fill entirely (:50-52 sets only a colour), so the one '
            'painted fill left is the header default.',
      );
      expect(
        tester.widget<Text>(find.text('A')).style!.color!.toARGB32(),
        highContrast.colors.neutralForeground1.toARGB32(),
        reason:
            'useChartTableStyles.styles.ts:41 forces WindowText over the '
            'caller white; a per-cell colour cannot survive forced colours.',
      );
      expect(
        tester.widget<Text>(find.text('a')).style!.color!.toARGB32(),
        highContrast.colors.neutralForeground1.toARGB32(),
        reason: 'useChartTableStyles.styles.ts:51, the body half of the rule.',
      );
    });

    testWidgets('the title takes its own band out of the total height', (
      tester,
    ) async {
      await pump(
        tester,
        const SizedBox(
          width: 600,
          child: FluentChartTable(
            key: key,
            headers: headers,
            rows: rows,
            height: 200,
            chartTitle: 'Sales',
          ),
        ),
      );
      expect(
        tester.getSize(find.byKey(key)).height,
        closeTo(200, 0.01),
        reason:
            'ChartTable.tsx:94 and :106 — the root box is the total height.',
      );
      expect(
        find.text('Sales'),
        findsOneWidget,
        reason: 'ChartTable.tsx:109-118 renders the ChartTitle when set.',
      );
    });
  });

  group('Oracle B — charts-charttable--chart-table-basic', () {
    final story = loadOracleStory('charts-charttable--chart-table-basic');

    test('the capture is the six-column, four-row grid the port models', () {
      expect(
        story.byTag('TH').length,
        6,
        reason:
            'Upstream captured six <th>; the Dart port emits one cell widget '
            'per header for the same shape.',
      );
      expect(
        story.byTag('TD').length,
        24,
        reason: 'Four <tr> of six <td> each, so 24 body cells.',
      );
      expect(
        story.childrenOf(story.soleElement('TBODY')).length,
        4,
        reason: 'ChartTable.tsx:156 maps one <tr> per row.',
      );
    });

    test('header type is semibold over a regular body, both at 12', () {
      final headerCells = story.byTag('TH');
      final bodyCells = story.byTag('TD');
      expect(
        headerCells.length + bodyCells.length,
        30,
        reason:
            'Count guard: the two filtered loops below must see every cell of '
            'the capture, not a subset.',
      );
      for (final cell in headerCells) {
        expectOracleNumber('TH #${cell.index} fontSize', 12, cell.fontSize);
        expect(
          cell.fontWeight,
          '600',
          reason:
              'useChartTableStyles.styles.ts:32-33 spreads caption1 and then '
              'overrides the weight, which is what resolveFluentChartTableStyle '
              'reproduces.',
        );
      }
      for (final cell in bodyCells) {
        expectOracleNumber('TD #${cell.index} fontSize', 12, cell.fontSize);
        expect(
          cell.fontWeight,
          '400',
          reason:
              'useChartTableStyles.styles.ts:45 spreads caption1 with no '
              'weight override.',
        );
      }
    });

    test('a story with no chartTitle gives the grid the whole height', () {
      final host = story.soleElement('foreignObject');
      expectOracleNumber('foreignObject.y', 0, host.y!);
      expectOracleNumber('foreignObject.height', story.height, host.height!);
      expect(
        story.height,
        200,
        reason:
            'ChartTable.tsx:93-95 — titleHeight is 0 without a title, so the '
            'table band is the full 200 the story passed as `height`, which is '
            'what the Dart Column reproduces with no title SizedBox.',
      );
    });

    testWidgets('the port emits the capture\'s 30 tab stops', (tester) async {
      final headerCount = story.byTag('TH').length;
      final rowCount = story.childrenOf(story.soleElement('TBODY')).length;
      await pump(
        tester,
        SizedBox(
          width: story.width,
          child: FluentChartTable(
            key: key,
            height: story.height,
            headers: <FluentChartTableCell>[
              for (var i = 0; i < headerCount; i++)
                FluentChartTableCell(value: 'h$i'),
            ],
            rows: <List<FluentChartTableCell>>[
              for (var r = 0; r < rowCount; r++)
                <FluentChartTableCell>[
                  for (var c = 0; c < headerCount; c++)
                    FluentChartTableCell(value: 'r${r}c$c'),
                ],
            ],
          ),
        ),
      );
      expect(
        find.descendant(of: find.byKey(key), matching: find.byType(Focus)),
        findsNWidgets(story.byTag('TH').length + story.byTag('TD').length),
        reason:
            'Every th and td upstream carries tabIndex={0} '
            '(ChartTable.tsx:147, :166), so the capture\'s 6 + 24 cells are 30 '
            'Flutter tab stops.',
      );
    });
  });
}
