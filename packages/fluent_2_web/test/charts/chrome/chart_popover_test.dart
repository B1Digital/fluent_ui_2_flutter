import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/chrome/chart_popover.dart';
import 'package:fluent_2_web/src/charts/chrome/chart_popover_style.dart';
import 'package:fluent_2_web/src/charts/chrome/legend_shape.dart';
import 'package:fluent_2_web/src/charts/model/callout_data.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  group('chart popover constants', () {
    test('the anchor offset is 20, not the package default of zero', () {
      expect(
        kChartPopoverAnchorOffset,
        20,
        reason:
            'ChartPopover.tsx:48 passes `offset: 20`, where FluentPopover '
            'defaults to FluentSpacing.none (overlays/popover.dart:239).',
      );
    });

    test('the accent bar is 4px with an 11px top margin', () {
      expect(
        kChartPopoverAccentBarWidth,
        4,
        reason: 'ChartPopover.tsx:74 — `borderInlineStart: 4px solid`.',
      );
      expect(
        kChartPopoverAccentBarMarginTop,
        11,
        reason: 'ChartPopover.tsx:75 — `marginTop: 11px`.',
      );
    });

    test('the single-value Y is 28px, overriding its own class', () {
      expect(
        kChartPopoverValueFontSize,
        28,
        reason:
            'ChartPopover.tsx:86 sets an inline fontSize of fontSizeHero700 '
            '(28px), which beats calloutContentY\'s subtitle2Stronger for the '
            'cartesian case and title2 for the non-cartesian one '
            '(useChartPopoverStyles.styles.ts:79-84). The multi-value path at '
            ':229 does NOT set it.',
      );
    });

    test('the subcount header is 12pt expressed in pixels', () {
      expect(
        kChartPopoverSubHeaderFontSize,
        16,
        reason:
            'ChartPopover.tsx:195 and :245 set `fontSize: 12pt`, and CSS pt is '
            '1/72 inch against a 96dpi reference pixel, so 12 * 96 / 72 = 16. '
            'The accompanying ms-fontWeight-semibold class is a v8 name with no '
            'v9 rule, so only the size lands.',
      );
    });

    test('multi-value spacing', () {
      expect(
        kChartPopoverColumnGap,
        16,
        reason:
            'ChartPopover.tsx:187 — `marginRight: 16px` on every non-last '
            'column.',
      );
      expect(
        kChartPopoverRowMarginTop,
        13,
        reason:
            'ChartPopover.tsx:226 — `marginTop: xValue ? 13px : unset`, and '
            'xValue is always truthy, so it is always 13.',
      );
      expect(
        kChartPopoverRowPaddingBottom,
        10,
        reason: 'ChartPopover.tsx:147 — 10px below a row that draws its rule.',
      );
    });
  });

  group('resolveFluentChartPopoverStyle', () {
    test('inherits the package popover surface', () {
      final style = resolveFluentChartPopoverStyle(theme);
      expect(
        style.surfacePadding!.resolve(<WidgetState>{}),
        const EdgeInsets.all(FluentSpacing.l),
        reason:
            'PopoverSurface is used bare at ChartPopover.tsx:52, so the surface '
            'takes the package medium popover padding of 16 '
            '(overlays/popover.dart:213-217, :228).',
      );
      expect(
        style.surfaceColor!.resolve(<WidgetState>{})!.toARGB32(),
        theme.colors.neutralBackground1.toARGB32(),
        reason:
            'useChartPopoverStyles.styles.ts:36 paints calloutContentRoot with '
            'colorNeutralBackground1.',
      );
    });

    test('the description rule is neutralStroke2', () {
      expect(
        resolveFluentChartPopoverStyle(
          theme,
        ).descriptionDividerColor!.resolve(<WidgetState>{})!.toARGB32(),
        theme.colors.neutralStroke2.toARGB32(),
        reason:
            'useChartPopoverStyles.styles.ts:90 — `borderTop: 1px solid '
            'colorNeutralStroke2`.',
      );
    });

    test('equal styles compare equal, shadows and all', () {
      final shadows = resolveFluentChartPopoverStyle(
        theme,
      ).surfaceShadow!.resolve(<WidgetState>{})!;
      expect(
        shadows,
        hasLength(2),
        reason:
            'FluentElevation.shadow16 is an ambient plus a key shadow '
            '(tokens/elevation.dart:33-36), so the equality spread over the '
            'shadow list is not vacuous.',
      );
      expect(
        resolveFluentChartPopoverStyle(theme),
        resolveFluentChartPopoverStyle(theme),
        reason:
            'theme.shadow() returns a fresh List per call (theme.dart:139) and '
            'List has no value equality, which is why the shadows are spread '
            'into the field list rather than compared as a property.',
      );
    });

    test('equal styles hash equally', () {
      expect(
        resolveFluentChartPopoverStyle(theme).hashCode,
        resolveFluentChartPopoverStyle(theme).hashCode,
        reason:
            'Twenty-three fields exceed Object.hash\'s twenty-argument limit, '
            'so this must be Object.hashAll and must still be stable.',
      );
    });
  });

  group('the single-value popover body', () {
    const seriesColour = Color(0xFF0078D4);

    Future<void> pump(WidgetTester tester, FluentChartPopoverData data) =>
        tester.pumpWidget(
          FluentApp(
            theme: theme,
            home: Center(
              child: buildFluentChartPopoverSingleValue(
                data,
                resolveFluentChartPopoverStyle(theme),
                theme.colors.neutralForeground1,
              ),
            ),
          ),
        );

    TextStyle styleOfText(WidgetTester tester, String data) =>
        tester.widget<Text>(find.text(data)).style!;

    testWidgets('the y reading takes the inline 28px override', (tester) async {
      await pump(
        tester,
        const FluentChartPopoverData(
          xValue: 'Jan',
          legend: 'alpha',
          yValue: '42',
          color: seriesColour,
        ),
      );
      expect(
        styleOfText(tester, '42').fontSize,
        kChartPopoverValueFontSize,
        reason:
            'ChartPopover.tsx:86 sets fontSize inline, beating calloutContentY\'s '
            'own subtitle2Stronger class.',
      );
    });

    testWidgets('the y reading takes the series colour', (tester) async {
      await pump(
        tester,
        const FluentChartPopoverData(
          xValue: 'Jan',
          legend: 'alpha',
          yValue: '42',
          color: seriesColour,
        ),
      );
      expect(
        styleOfText(tester, '42').color!.toARGB32(),
        seriesColour.toARGB32(),
        reason:
            'ChartPopover.tsx:85 — `color: props.color ? props.color : '
            'colorNeutralForeground1`.',
      );
    });

    testWidgets('a colourless popover falls back to neutralForeground1', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentChartPopoverData(
          xValue: 'Jan',
          legend: 'alpha',
          yValue: '42',
        ),
      );
      expect(
        styleOfText(tester, '42').color!.toARGB32(),
        theme.colors.neutralForeground1.toARGB32(),
        reason: 'ChartPopover.tsx:85, the false arm.',
      );
    });

    testWidgets('the accent bar is 4px in the series colour', (tester) async {
      await pump(
        tester,
        const FluentChartPopoverData(
          xValue: 'Jan',
          legend: 'alpha',
          yValue: '42',
          color: seriesColour,
        ),
      );
      final bar = tester.widget<Container>(
        find.byKey(const ValueKey<String>('popover-accent-bar')),
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey<String>('popover-accent-bar')))
            .width,
        kChartPopoverAccentBarWidth,
        reason:
            'ChartPopover.tsx:74 — `borderInlineStart: 4px solid props.color`.',
      );
      expect(
        (bar.decoration! as BoxDecoration).color!.toARGB32(),
        seriesColour.toARGB32(),
        reason:
            'The bar is the only thing carrying the series colour structurally.',
      );
    });

    testWidgets('the accent bar spans the block it borders', (tester) async {
      await pump(
        tester,
        const FluentChartPopoverData(
          xValue: 'Jan',
          legend: 'alpha',
          yValue: '42',
          color: seriesColour,
        ),
      );
      final barHeight = tester
          .getSize(find.byKey(const ValueKey<String>('popover-accent-bar')))
          .height;
      expect(
        barHeight,
        greaterThan(kChartPopoverValueFontSize),
        reason:
            'ChartPopover.tsx:74 puts the 4px border on calloutInfoContainer '
            'itself, not on a child, so it always spans the container — which '
            'is at least as tall as the 28px y reading at :86.',
      );
      expect(
        barHeight,
        tester.getSize(find.text('42')).height +
            tester.getSize(find.text('alpha')).height,
        reason:
            'The container is exactly the legend plus the y reading tall '
            '(ChartPopover.tsx:78-91), with no other flex child taller.',
      );
    });

    testWidgets('the ratio renders numerator, slash, denominator', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentChartPopoverData(
          xValue: 'Jan',
          legend: 'alpha',
          yValue: '42',
          ratio: (42, 100),
        ),
      );
      expect(
        find.text('42'),
        findsNWidgets(2),
        reason:
            'ChartPopover.tsx:96 renders the numerator as well as the y reading, '
            'and both read 42 in this fixture.',
      );
      expect(
        find.text('/'),
        findsOneWidget,
        reason: 'ChartPopover.tsx:98 puts a bare slash between the two spans.',
      );
      expect(
        find.text('100'),
        findsOneWidget,
        reason: 'ChartPopover.tsx:100 renders the denominator.',
      );
    });

    testWidgets('a ratio sits flush with the bottom of the block', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentChartPopoverData(
          xValue: 'Jan',
          legend: 'alpha',
          yValue: '42',
          ratio: (42, 100),
        ),
      );
      expect(
        tester.getBottomLeft(find.text('100')).dy,
        moreOrLessEquals(
          tester
              .getBottomLeft(
                find.byKey(const ValueKey<String>('popover-accent-bar')),
              )
              .dy,
          epsilon: 0.01,
        ),
        reason:
            'ChartPopover.tsx:70-73 — a ratio switches the container to '
            '`alignItems: flex-end`, which bottom-aligns the ratio against the '
            'container the border spans.',
      );
    });

    testWidgets('the description sits under a 1px rule', (tester) async {
      await pump(
        tester,
        const FluentChartPopoverData(
          xValue: 'Jan',
          legend: 'alpha',
          yValue: '42',
          descriptionMessage: 'trailing note',
        ),
      );
      final divider = tester.widget<Container>(
        find.byKey(const ValueKey<String>('popover-description-rule')),
      );
      expect(
        ((divider.decoration! as BoxDecoration).border! as Border).top.color
            .toARGB32(),
        theme.colors.neutralStroke2.toARGB32(),
        reason:
            'useChartPopoverStyles.styles.ts:90 — borderTop 1px solid '
            'colorNeutralStroke2.',
      );
    });

    testWidgets('no description means no rule', (tester) async {
      await pump(
        tester,
        const FluentChartPopoverData(
          xValue: 'Jan',
          legend: 'alpha',
          yValue: '42',
        ),
      );
      expect(
        find.byKey(const ValueKey<String>('popover-description-rule')),
        findsNothing,
        reason:
            'ChartPopover.tsx:106 gates the whole block on descriptionMessage.',
      );
    });
  });

  Future<void> pumpMulti(WidgetTester tester, FluentChartPopoverData data) =>
      tester.pumpWidget(
        FluentApp(
          theme: theme,
          home: Center(
            child: buildFluentChartPopoverMultiValue(
              data,
              resolveFluentChartPopoverStyle(theme),
              theme.colors.neutralForeground1,
            ),
          ),
        ),
      );

  group('fluentChartPopoverShapeForIndex', () {
    test('the modulus is 8, so dottedLine is unreachable', () {
      expect(
        fluentChartPopoverShapeForIndex(8),
        FluentChartLegendShape.circle,
        reason:
            'ChartPopover.tsx:216 is `Points[index % Object.keys(pointTypes).length]` '
            'and pointTypes has eight keys (utilities.ts:1747-1772), so index 8 '
            'wraps to the first Points member.',
      );
      expect(
        List<FluentChartLegendShape>.generate(
          32,
          fluentChartPopoverShapeForIndex,
        ).contains(FluentChartLegendShape.dottedLine),
        isFalse,
        reason:
            'dottedLine is a CustomPoints member with no pointTypes entry, so '
            'the popover can never index onto it.',
      );
    });
  });

  group('fluentChartPopoverHasSubCounts', () {
    test('is true only for a non-string breakdown', () {
      expect(
        fluentChartPopoverHasSubCounts(const <FluentYValueHover>[
          FluentYValueHover(legend: 'a', y: 1, yAxisCalloutText: 'one'),
        ]),
        isFalse,
        reason:
            'ChartPopover.tsx:176 requires `typeof yAxisCalloutData !== '
            '"string"`, and the contract splits that union into '
            'yAxisCalloutText for the string arm.',
      );
      expect(
        fluentChartPopoverHasSubCounts(const <FluentYValueHover>[
          FluentYValueHover(
            legend: 'a',
            y: 1,
            yAxisCalloutBreakdown: <String, double>{'x': 1},
          ),
        ]),
        isTrue,
        reason: 'ChartPopover.tsx:176, the record arm.',
      );
    });
  });

  group('the multi-value body', () {
    testWidgets('a shape is drawn only when the index is set and not -1', (
      tester,
    ) async {
      await pumpMulti(
        tester,
        const FluentChartPopoverData(
          isCalloutForStack: true,
          xValue: 'Jan',
          yValues: <FluentYValueHover>[
            FluentYValueHover(legend: 'a', y: 1, index: 0),
            FluentYValueHover(legend: 'b', y: 2, index: -1),
          ],
        ),
      );
      expect(
        tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .where((p) => p.painter is FluentChartLegendShapePainter)
            .length,
        1,
        reason:
            'ChartPopover.tsx:188 — `toDrawShape = index !== undefined && '
            'index !== -1`, so the -1 row falls back to the accent bar.',
      );
    });

    testWidgets('the popover swatch box is the shape viewport, not the legend '
        "row's border box", (tester) async {
      await pumpMulti(
        tester,
        const FluentChartPopoverData(
          isCalloutForStack: true,
          xValue: 'Jan',
          yValues: <FluentYValueHover>[
            FluentYValueHover(legend: 'a', y: 1, index: 0),
          ],
        ),
      );
      final box = tester.getSize(
        find.ancestor(
          of: find.byWidgetPredicate(
            (widget) =>
                widget is CustomPaint &&
                widget.painter is FluentChartLegendShapePainter,
          ),
          matching: find.byType(SizedBox),
        ),
      );
      expect(
        box,
        const Size(kLegendShapeViewportSize, kLegendShapeViewportSize),
        reason:
            'ChartPopover.tsx:211-217 renders the same <Shape> the legend does, '
            'and shape.tsx:39-40 and :46-49 size that svg themselves, so the '
            "box is the shape's own viewport. kLegendSwatchBoxSize is the "
            'legend row border box (useLegendsStyles.styles.ts:80-82) and is '
            'only equal to it while the swatch border is 1px.',
      );
    });

    testWidgets('the popover swatch has no stroke, unlike the legend', (
      tester,
    ) async {
      await pumpMulti(
        tester,
        const FluentChartPopoverData(
          isCalloutForStack: true,
          xValue: 'Jan',
          yValues: <FluentYValueHover>[
            FluentYValueHover(
              legend: 'a',
              y: 1,
              index: 0,
              color: Color(0xFF0078D4),
            ),
          ],
        ),
      );
      expect(
        tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((p) => p.painter)
            .whereType<FluentChartLegendShapePainter>()
            .first
            .strokeWidth,
        0,
        reason:
            'ChartPopover.tsx:215 passes only `fill`, where the legend at '
            'Legends.tsx:365 also sets strokeWidth: 2.',
      );
    });

    testWidgets('the last row never draws its bottom rule', (tester) async {
      await pumpMulti(
        tester,
        const FluentChartPopoverData(
          isCalloutForStack: true,
          xValue: 'Jan',
          yValues: <FluentYValueHover>[
            FluentYValueHover(legend: 'a', y: 1, index: 0),
            FluentYValueHover(legend: 'b', y: 2, index: 1),
          ],
        ),
      );
      expect(
        find.byKey(const ValueKey<String>('popover-row-rule')),
        findsNothing,
        reason:
            'ChartPopover.tsx:135 forces shouldDrawBorderBottom to false on the '
            'last row, and the contract carries no per-row flag, so no row in '
            'a two-row popover draws one.',
      );
    });

    testWidgets('a subcount group gets a 16px header', (tester) async {
      await pumpMulti(
        tester,
        const FluentChartPopoverData(
          isCalloutForStack: true,
          xValue: 'Jan',
          yValues: <FluentYValueHover>[
            FluentYValueHover(
              legend: 'alpha',
              y: 3,
              index: 0,
              yAxisCalloutBreakdown: <String, double>{'north': 1, 'south': 2},
            ),
          ],
        ),
      );
      expect(
        tester.widget<Text>(find.text('alpha (3)')).style!.fontSize,
        kChartPopoverSubHeaderFontSize,
        reason:
            'ChartPopover.tsx:245-247 renders `{legend} ({y})` at an inline '
            '12pt, which is 16 logical pixels.',
      );
      expect(
        find.text('north'),
        findsOneWidget,
        reason: 'ChartPopover.tsx:251-254 renders one block per subcount key.',
      );
    });

    testWidgets('the accent bar spans exactly the block it borders', (
      tester,
    ) async {
      await pumpMulti(
        tester,
        const FluentChartPopoverData(
          isCalloutForStack: true,
          xValue: 'Jan',
          yValues: <FluentYValueHover>[
            FluentYValueHover(legend: 'a', y: 1, color: Color(0xFF0078D4)),
          ],
        ),
      );
      final bar = find.byKey(const ValueKey<String>('popover-row-accent-bar'));
      expect(
        tester.getSize(bar).width,
        kChartPopoverAccentBarWidth,
        reason: 'ChartPopover.tsx:205 — `borderInlineStart: 4px solid`.',
      );
      expect(
        tester.getSize(bar).height,
        tester.getSize(find.text('a')).height +
            tester.getSize(find.text('1')).height +
            kChartPopoverRowMarginTop,
        reason:
            'ChartPopover.tsx:205 puts the border on the outer '
            'calloutBlockContainer, so it spans the inner block — the legend '
            'plus the reading, offset by the 13px marginTop at :226 — and '
            'nothing taller.',
      );
    });

    testWidgets('a subcount row reads its own value, not the shared y', (
      tester,
    ) async {
      await pumpMulti(
        tester,
        const FluentChartPopoverData(
          isCalloutForStack: true,
          xValue: 'Jan',
          yValues: <FluentYValueHover>[
            FluentYValueHover(
              legend: 'alpha',
              y: 3,
              index: 0,
              yAxisCalloutBreakdown: <String, double>{'north': 1, 'south': 2},
            ),
          ],
        ),
      );
      expect(
        find.text('2'),
        findsOneWidget,
        reason:
            'ChartPopover.tsx:259 formats subcounts[subcountName], so the south '
            'block reads 2 while the header reads the row total of 3.',
      );
      expect(
        tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .where((p) => p.painter is FluentChartLegendShapePainter),
        isEmpty,
        reason:
            'ChartPopover.tsx:243-265, the subcount arm, renders neither a '
            'Shape nor an accent bar — only the header and the blocks.',
      );
    });

    testWidgets('the x reading only clears 11px when subcounts exist', (
      tester,
    ) async {
      const plain = FluentChartPopoverData(
        isCalloutForStack: true,
        xValue: 'Jan',
        yValues: <FluentYValueHover>[
          FluentYValueHover(legend: 'a', y: 1, index: 0),
        ],
      );
      await pumpMulti(tester, plain);
      expect(
        tester.getTopLeft(find.text('a')).dy -
            tester.getBottomLeft(find.text('Jan')).dy,
        moreOrLessEquals(kChartPopoverRowMarginTop, epsilon: 0.01),
        reason:
            'ChartPopover.tsx:122 leaves the date container marginless without '
            'subcounts, so the only gap is the 13px block marginTop at :226.',
      );
      await pumpMulti(
        tester,
        const FluentChartPopoverData(
          isCalloutForStack: true,
          xValue: 'Jan',
          yValues: <FluentYValueHover>[
            FluentYValueHover(
              legend: 'a',
              y: 1,
              index: 0,
              yAxisCalloutBreakdown: <String, double>{'north': 1},
            ),
          ],
        ),
      );
      expect(
        tester.getTopLeft(find.text('a (1)')).dy -
            tester.getBottomLeft(find.text('Jan')).dy,
        moreOrLessEquals(kChartPopoverAccentBarMarginTop, epsilon: 0.01),
        reason:
            'ChartPopover.tsx:122 — `marginBottom: 11px` on the date container '
            'once yValueHoverSubCountsExists, and the subcount arm at :244-247 '
            'starts with the header, carrying no marginTop of its own.',
      );
    });
  });

  group('FluentChartPopoverLayoutDelegate', () {
    const size = Size(400, 300);
    const child = Size(120, 80);

    test('sits below the cursor at the 20px offset', () {
      const delegate = FluentChartPopoverLayoutDelegate(
        anchor: Offset(100, 50),
        offset: kChartPopoverAnchorOffset,
      );
      expect(
        delegate.getPositionForChild(size, child).dy,
        50 + kChartPopoverAnchorOffset,
        reason:
            'ChartPopover.tsx:48 sets `coverTarget: false` with `offset: 20`, '
            'so the surface clears the zero-size virtual target by 20.',
      );
      expect(
        delegate.getPositionForChild(size, child).dx,
        100,
        reason:
            'The virtual element is zero-width (ChartPopover.tsx:31-32), so the '
            'surface starts at the cursor.',
      );
    });

    test('flips above when there is no room below', () {
      const delegate = FluentChartPopoverLayoutDelegate(
        anchor: Offset(100, 280),
        offset: kChartPopoverAnchorOffset,
      );
      expect(
        delegate.getPositionForChild(size, child).dy,
        280 - kChartPopoverAnchorOffset - 80,
        reason:
            'Below the cursor there are only 20 pixels, so the surface flips '
            'above and keeps the same 20px clearance.',
      );
    });

    test('shifts inside the box rather than overflowing it', () {
      const delegate = FluentChartPopoverLayoutDelegate(
        anchor: Offset(390, 50),
        offset: kChartPopoverAnchorOffset,
      );
      expect(
        delegate.getPositionForChild(size, child).dx,
        400 - 120,
        reason:
            'A surface that would leave the plot is shifted back to its edge, '
            'never clipped.',
      );
    });

    test('autoSize always caps the surface at the available box', () {
      const delegate = FluentChartPopoverLayoutDelegate(
        anchor: Offset(10, 10),
        offset: kChartPopoverAnchorOffset,
      );
      expect(
        delegate.getConstraintsForChild(BoxConstraints.tight(size)).maxWidth,
        size.width,
        reason:
            "ChartPopover.tsx:48 passes `autoSize: 'always'`, which caps the "
            'surface at the viewport rather than letting it overflow.',
      );
    });

    test('relayouts when the cursor moves', () {
      const a = FluentChartPopoverLayoutDelegate(
        anchor: Offset(10, 10),
        offset: kChartPopoverAnchorOffset,
      );
      expect(
        a.shouldRelayout(
          const FluentChartPopoverLayoutDelegate(
            anchor: Offset(11, 10),
            offset: kChartPopoverAnchorOffset,
          ),
        ),
        isTrue,
        reason:
            'The popover follows the hovered datum, so a moved anchor must '
            'relayout.',
      );
    });
  });

  group('FluentChartPopover', () {
    testWidgets('a custom body replaces both default branches', (tester) async {
      await tester.pumpWidget(
        FluentApp(
          theme: theme,
          home: FluentChartPopover(
            anchor: const Offset(10, 10),
            data: FluentChartPopoverData(
              xValue: 'Jan',
              yValue: '42',
              customContentBuilder: (context) => const Text('bespoke'),
            ),
          ),
        ),
      );
      expect(
        find.text('bespoke'),
        findsOneWidget,
        reason: 'ChartPopover.tsx:54.',
      );
      expect(
        find.text('42'),
        findsNothing,
        reason:
            'ChartPopover.tsx:56 and :60 both gate the default branches on the '
            'custom body being absent.',
      );
    });

    testWidgets('isCalloutForStack selects the multi-value body', (
      tester,
    ) async {
      await tester.pumpWidget(
        FluentApp(
          theme: theme,
          home: const FluentChartPopover(
            anchor: Offset(10, 10),
            data: FluentChartPopoverData(
              isCalloutForStack: true,
              xValue: 'Jan',
              yValues: <FluentYValueHover>[
                FluentYValueHover(legend: 'a', y: 1, index: 0),
              ],
            ),
          ),
        ),
      );
      expect(
        find.text('a'),
        findsOneWidget,
        reason: 'ChartPopover.tsx:57 routes to _multiValueCallout.',
      );
    });

    testWidgets('anchors the surface below the cursor', (tester) async {
      await tester.pumpWidget(
        FluentApp(
          theme: theme,
          home: const FluentChartPopover(
            anchor: Offset(10, 10),
            data: FluentChartPopoverData(xValue: 'Jan', yValue: '42'),
          ),
        ),
      );
      expect(
        tester
            .getTopLeft(
              find.descendant(
                of: find.byType(FluentChartPopover),
                matching: find.byType(ExcludeFocus),
              ),
            )
            .dy,
        moreOrLessEquals(10 + kChartPopoverAnchorOffset, epsilon: 0.01),
        reason:
            'The surface is laid out by the delegate against the anchor, so the '
            'widget carries the same 20px clearance the delegate computes.',
      );
    });

    testWidgets('takes no focus', (tester) async {
      await tester.pumpWidget(
        FluentApp(
          theme: theme,
          home: const FluentChartPopover(
            anchor: Offset(10, 10),
            data: FluentChartPopoverData(xValue: 'Jan', yValue: '42'),
          ),
        ),
      );
      final node = Focus.of(tester.element(find.text('42')));
      expect(
        node.canRequestFocus,
        isFalse,
        reason:
            'ChartPopover has no focus trap, no dismiss and no onOpenChange — '
            'CartesianChart.tsx:923 mounts it purely for narration, which is '
            'why FluentPopover cannot be reused wholesale.',
      );
      expect(
        node.descendantsAreFocusable,
        isFalse,
        reason:
            'Stealing focus from the chart would break the chart\'s own '
            'keyboard traversal, so nothing inside the surface is reachable.',
      );
    });
  });
}
