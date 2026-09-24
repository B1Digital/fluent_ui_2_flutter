import 'dart:math';

import 'package:fluent_2/src/charts/chrome/chart_popover.dart';
import 'package:fluent_2/src/charts/chrome/chart_popover_style.dart';
import 'package:fluent_2/src/charts/chrome/legend_shape.dart';
import 'package:fluent_2/src/charts/model/callout_data.dart';
import 'package:fluent_2_core/fluent_2_core.dart';
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

    Future<void> pump(
      WidgetTester tester,
      FluentChartPopoverData data, {
      bool isCartesian = true,
    }) => tester.pumpWidget(
      FluentApp(
        theme: theme,
        home: Center(
          child: buildFluentChartPopoverSingleValue(
            data,
            resolveFluentChartPopoverStyle(theme, isCartesian: isCartesian),
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
            FluentSpacing.xs +
            tester.getSize(find.text('alpha')).height,
        reason:
            'The container is exactly the legend, its 4px marginBottom '
            '(useChartPopoverStyles.styles.ts:74) and the y reading tall '
            '(ChartPopover.tsx:78-91), with no other flex child taller.',
      );
    });

    testWidgets('the 28px y reading keeps its class line height', (
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
        tester.getSize(find.text('42')).height,
        moreOrLessEquals(22, epsilon: 0.01),
        reason:
            'ChartPopover.tsx:86 sets only an inline fontSize; the cartesian '
            'class keeps subtitle2Stronger\'s 22px line-height '
            '(useChartPopoverStyles.styles.ts:79-81), which does not scale '
            'with the font the way a 1.375 multiplier does (38.5px).',
      );
      expect(
        styleOfText(tester, '42').fontWeight,
        theme.typography.subtitle2Stronger.fontWeight,
        reason: 'subtitle2Stronger is weight 700.',
      );
    });

    testWidgets('a non-cartesian y reading is title2 on its 36px line', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentChartPopoverData(
          xValue: 'Jan',
          legend: 'alpha',
          yValue: '42',
          isCartesian: false,
        ),
        isCartesian: false,
      );
      expect(
        styleOfText(tester, '42').fontWeight,
        theme.typography.title2.fontWeight,
        reason:
            'HorizontalBarChart, DonutChart and FunnelChart pass '
            'isCartesian={false} (HorizontalBarChart.tsx:483, '
            'DonutChart.tsx:413, FunnelChart.tsx:525), so calloutContentY is '
            'title2 at weight 600 (useChartPopoverStyles.styles.ts:82-84).',
      );
      expect(
        tester.getSize(find.text('42')).height,
        moreOrLessEquals(36, epsilon: 0.01),
        reason:
            'title2 is 28px on a 36px line; the inline 28px changes '
            'nothing.',
      );
    });

    testWidgets('the legend sits 4px above the y reading', (tester) async {
      await pump(
        tester,
        const FluentChartPopoverData(
          xValue: 'Jan',
          legend: 'alpha',
          yValue: '42',
        ),
      );
      expect(
        tester.getTopLeft(find.text('42')).dy -
            tester.getBottomLeft(find.text('alpha')).dy,
        moreOrLessEquals(FluentSpacing.xs, epsilon: 0.01),
        reason:
            'calloutLegendText carries marginBottom spacingVerticalXS '
            '(useChartPopoverStyles.styles.ts:70-75).',
      );
    });

    testWidgets('an absent x reading and legend take no line', (tester) async {
      await pump(tester, const FluentChartPopoverData(yValue: '42'));
      expect(
        find.text(''),
        findsNothing,
        reason:
            'ChartPopover.tsx:63 renders `{props.XValue} ` and :79-81 an empty '
            'legend; a div of collapsible whitespace lays out no line box.',
      );
      final bar = find.byKey(const ValueKey<String>('popover-accent-bar'));
      expect(
        tester.getSize(bar).height,
        moreOrLessEquals(
          FluentSpacing.xs + tester.getSize(find.text('42')).height,
          epsilon: 0.01,
        ),
        reason:
            'Only the empty legend\'s 4px margin is left above the reading: '
            'upstream measures the calloutInfoContainer at 26px '
            '(VerticalBarChart axis-tooltip story).',
      );
      final body = find.byWidgetPredicate(
        (widget) => widget is Column && widget.mainAxisSize == MainAxisSize.min,
      );
      expect(
        tester.getTopLeft(bar).dy - tester.getTopLeft(body.first).dy,
        moreOrLessEquals(kChartPopoverAccentBarMarginTop, epsilon: 0.01),
        reason:
            'With no x row the accent bar\'s 11px marginTop is all that sits '
            'above it (ChartPopover.tsx:75).',
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
            FluentYValueHover(
              legend: 'a',
              y: 1,
              index: 0,
              shouldDrawBorderBottom: true,
            ),
            FluentYValueHover(
              legend: 'b',
              y: 2,
              index: 1,
              shouldDrawBorderBottom: true,
            ),
          ],
        ),
      );
      expect(
        find.byKey(const ValueKey<String>('popover-row-rule')),
        findsOneWidget,
        reason:
            'ChartPopover.tsx:135 forces shouldDrawBorderBottom to false on the '
            'last row, so of two flagged rows only the first draws one.',
      );
    });

    testWidgets('a flagged row is ruled off 10px below its bar', (
      tester,
    ) async {
      await pumpMulti(
        tester,
        const FluentChartPopoverData(
          isCalloutForStack: true,
          xValue: 'Jan',
          yValues: <FluentYValueHover>[
            FluentYValueHover(
              legend: 'line',
              y: 1,
              color: Color(0xFF0078D4),
              shouldDrawBorderBottom: true,
            ),
            FluentYValueHover(legend: 'bar', y: 2, color: Color(0xFF0078D4)),
          ],
        ),
      );
      final rule = tester.widget<Container>(
        find.byKey(const ValueKey<String>('popover-row-rule')),
      );
      final side =
          ((rule.decoration! as BoxDecoration).border! as Border).bottom;
      expect(
        side.color.toARGB32(),
        theme.colors.neutralStroke2.toARGB32(),
        reason:
            'ChartPopover.tsx:151 — `borderBottom: 1px solid '
            'colorNeutralStroke2`.',
      );
      final bars = find.byKey(const ValueKey<String>('popover-row-accent-bar'));
      expect(
        tester.getTopLeft(bars.at(1)).dy - tester.getBottomLeft(bars.at(0)).dy,
        moreOrLessEquals(
          kChartPopoverRowPaddingBottom +
              FluentStroke.thin +
              kChartPopoverRowMarginTop,
          epsilon: 0.01,
        ),
        reason:
            'ChartPopover.tsx:152 pads the ruled row 10px, the rule is 1px, '
            'and the next row\'s 13px marginTop follows (:226): a 66px row '
            'pitch upstream in the VerticalStackedBarChart callout story.',
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey<String>('popover-row-rule')))
            .width,
        moreOrLessEquals(
          tester.getSize(find.byType(IntrinsicWidth)).width,
          epsilon: 0.01,
        ),
        reason:
            'calloutContentRoot is a grid (useChartPopoverStyles.styles.ts:34), '
            'so the row wrapper, and its rule, span the whole body.',
      );
    });

    testWidgets('the x reading is shown as the chart formatted it', (
      tester,
    ) async {
      await pumpMulti(
        tester,
        const FluentChartPopoverData(
          isCalloutForStack: true,
          xValue: '15.000',
          culture: 'de-DE',
          yValues: <FluentYValueHover>[FluentYValueHover(legend: 'a', y: 1)],
        ),
      );
      expect(
        find.text('15.000'),
        findsOneWidget,
        reason:
            'ChartPopover.tsx:128 formats hoverXValue once, and the chart has '
            'already done that; a second pass reads de-DE 15.000 back as 15.',
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
            FluentSpacing.xs +
            tester.getSize(find.text('1')).height,
        reason:
            'ChartPopover.tsx:205 puts the border on the outer '
            'calloutBlockContainer, so it spans the inner block — the legend, '
            'its 4px marginBottom and the reading, 42px upstream — and nothing '
            'taller: the 13px marginTop at :226 collapses through the outer '
            'block, which has no top border or padding, and sits above the '
            'bar.',
      );
      expect(
        tester.getTopLeft(bar).dy,
        moreOrLessEquals(tester.getTopLeft(find.text('a')).dy, epsilon: 0.01),
        reason: 'The bar starts at the legend, not 13px above it.',
      );
    });

    testWidgets('consecutive bars are 13px apart, not touching', (
      tester,
    ) async {
      await pumpMulti(
        tester,
        const FluentChartPopoverData(
          isCalloutForStack: true,
          xValue: 'Jan',
          yValues: <FluentYValueHover>[
            FluentYValueHover(legend: 'a', y: 1, color: Color(0xFF0078D4)),
            FluentYValueHover(legend: 'b', y: 2, color: Color(0xFFD13438)),
          ],
        ),
      );
      final bars = find.byKey(const ValueKey<String>('popover-row-accent-bar'));
      expect(
        tester.getTopLeft(bars.at(1)).dy - tester.getBottomLeft(bars.at(0)).dy,
        moreOrLessEquals(kChartPopoverRowMarginTop, epsilon: 0.01),
        reason:
            'Each row\'s 13px marginTop (ChartPopover.tsx:226) lands outside '
            'its bar, so the VerticalStackedBarChart callout shows separate '
            '42px bars 13px apart rather than one multicolour stripe.',
      );
    });

    testWidgets('an empty legend leaves a barred row nothing', (tester) async {
      await pumpMulti(
        tester,
        const FluentChartPopoverData(
          isCalloutForStack: true,
          xValue: 'Jan',
          yValues: <FluentYValueHover>[FluentYValueHover(y: 7)],
        ),
      );
      expect(
        tester
            .getSize(
              find.byKey(const ValueKey<String>('popover-row-accent-bar')),
            )
            .height,
        moreOrLessEquals(tester.getSize(find.text('7')).height, epsilon: 0.01),
        reason:
            'ChartPopover.tsx:228 renders ` {legend}`; with no legend the div '
            'is empty, so its 4px margin collapses through it into the 13px '
            'row margin. Chrome measures the bar at 22px, the reading alone.',
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

  group('placement', () {
    // The positioning boundary: the chart root upstream.
    const box = Size(400, 300);
    const reading = FluentChartPopoverData(
      xValue: 'Jan',
      legend: 'alpha',
      yValue: '42',
    );

    Finder surface() => find.descendant(
      of: find.byType(FluentChartPopover),
      matching: find.byType(ExcludeFocus),
    );

    /// The surface's rect inside a [size] box pinned to the screen origin.
    Future<Rect> place(
      WidgetTester tester, {
      Offset anchor = Offset.zero,
      Rect? anchorRect,
      FluentChartPopoverData data = reading,
      Size size = box,
      TextDirection direction = TextDirection.ltr,
    }) async {
      await tester.pumpWidget(
        FluentApp(
          theme: theme,
          home: Directionality(
            textDirection: direction,
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox.fromSize(
                size: size,
                child: FluentChartPopover(
                  anchor: anchor,
                  anchorRect: anchorRect,
                  data: data,
                ),
              ),
            ),
          ),
        ),
      );
      return tester.getRect(surface());
    }

    testWidgets('sits above the cursor, centred on it, 20px clear', (
      tester,
    ) async {
      // Mid-box, where the surface fits on either side.
      final rect = await place(tester, anchor: const Offset(200, 150));
      expect(
        rect.bottom,
        moreOrLessEquals(150 - kChartPopoverAnchorOffset, epsilon: 0.5),
        reason:
            'ChartPopover.tsx:48 passes no position, so Popover\'s default '
            '`above` applies (usePopover.js:240-245) with `offset: 20`.',
      );
      expect(
        rect.center.dx,
        moreOrLessEquals(200, epsilon: 0.5),
        reason:
            'and its default `align: center` centres the surface on the '
            'zero-width virtual element (ChartPopover.tsx:23-34).',
      );
    });

    testWidgets('flips below when there is no room above', (tester) async {
      final rect = await place(tester, anchor: const Offset(200, 30));
      expect(
        rect.top,
        moreOrLessEquals(30 + kChartPopoverAnchorOffset, epsilon: 0.5),
        reason:
            'flip.js tries the opposite side when the surface overflows the '
            'top of the boundary.',
      );
      expect(rect.center.dx, moreOrLessEquals(200, epsilon: 0.5));
    });

    testWidgets('takes the roomier side, capped, when neither fits', (
      tester,
    ) async {
      final natural = (await place(
        tester,
        anchor: const Offset(200, 200),
      )).height;
      // A box too short for the surface on either side of the cursor.
      final short = Size(400, natural + 2 * kChartPopoverAnchorOffset);
      final below = await place(
        tester,
        anchor: Offset(200, short.height * 0.4),
        size: short,
      );
      final roomBelow =
          short.height - short.height * 0.4 - kChartPopoverAnchorOffset;
      expect(
        below.top,
        moreOrLessEquals(
          short.height * 0.4 + kChartPopoverAnchorOffset,
          epsilon: 0.5,
        ),
        reason:
            "fallbackStrategy 'bestFit' (flip.js:21) keeps the side that "
            'overflows less, here below.',
      );
      expect(
        below.height,
        moreOrLessEquals(roomBelow, epsilon: 0.5),
        reason:
            "autoSize: 'always' caps max-height at the room on that side "
            '(maxSize.js:46-63), so the surface ends at the boundary instead '
            'of sliding over its own target.',
      );
      expect(tester.takeException(), isNull);

      final above = await place(
        tester,
        anchor: Offset(200, short.height * 0.6),
        size: short,
      );
      expect(
        above.top,
        moreOrLessEquals(0, epsilon: 0.5),
        reason: 'The mirror case keeps the top and caps it there.',
      );
      expect(
        above.bottom,
        moreOrLessEquals(
          short.height * 0.6 - kChartPopoverAnchorOffset,
          epsilon: 0.5,
        ),
      );

      final tie = await place(
        tester,
        anchor: Offset(200, short.height / 2),
        size: short,
      );
      expect(
        tie.bottom,
        moreOrLessEquals(
          short.height / 2 - kChartPopoverAnchorOffset,
          epsilon: 0.5,
        ),
        reason:
            'On a tie the stable sort in flip.js keeps the initial `top` '
            'placement.',
      );
    });

    testWidgets('shifts inside the box at both edges', (tester) async {
      final left = await place(tester, anchor: const Offset(5, 200));
      expect(
        left.left,
        moreOrLessEquals(0, epsilon: 0.01),
        reason:
            'shift() clamps the centred surface into the boundary rather than '
            'letting it leave the chart root.',
      );
      final right = await place(tester, anchor: const Offset(395, 200));
      expect(
        right.right,
        moreOrLessEquals(box.width, epsilon: 0.5),
        reason:
            'The clamped offset is still rounded to the device pixel grid '
            '(writeContainerupdates.js:28-29), so a fractional width leaves '
            'the right edge within a pixel of the boundary.',
      );
    });

    testWidgets('places the same under RTL', (tester) async {
      final ltr = await place(tester, anchor: const Offset(5, 200));
      final rtl = await place(
        tester,
        anchor: const Offset(5, 200),
        direction: TextDirection.rtl,
      );
      expect(
        rtl.topLeft,
        ltr.topLeft,
        reason:
            "toFloatingUIPlacement('center', 'above', isRtl) is `top` either "
            'way, and floating-ui clamps in physical coordinates.',
      );
    });

    testWidgets('centres on a mark and clears its edge', (tester) async {
      const bar = Rect.fromLTWH(100, 150, 20, 100);
      final above = await place(tester, anchorRect: bar);
      expect(
        above.center.dx,
        moreOrLessEquals(bar.center.dx, epsilon: 0.5),
        reason:
            'GroupedVerticalBarChart hands the bar element to '
            '`positioning.target` (GroupedVerticalBarChart.tsx:437).',
      );
      expect(
        above.bottom,
        moreOrLessEquals(bar.top - kChartPopoverAnchorOffset, epsilon: 0.5),
        reason: 'An element target is cleared from its top edge above it …',
      );
      const low = Rect.fromLTWH(100, 20, 20, 60);
      final below = await place(tester, anchorRect: low);
      expect(
        below.top,
        moreOrLessEquals(low.bottom + kChartPopoverAnchorOffset, epsilon: 0.5),
        reason: '… and from its bottom edge below it.',
      );
    });

    testWidgets('a callout taller than the box never overflows', (
      tester,
    ) async {
      await place(
        tester,
        anchor: const Offset(200, 150),
        size: const Size(700, 300),
        data: FluentChartPopoverData(
          isCalloutForStack: true,
          xValue: 'Jan',
          yValues: <FluentYValueHover>[
            for (var i = 0; i < 14; i++)
              FluentYValueHover(
                legend: 'series $i',
                y: i.toDouble(),
                color: const Color(0xFF0078D4),
              ),
          ],
        ),
      );
      expect(
        tester.takeException(),
        isNull,
        reason:
            'The 14-row line-chart-multiple callout threw "A RenderFlex '
            'overflowed by 454 pixels"; upstream caps the surface and scrolls '
            "it (autoSize: 'always', maxSize.js:53-58).",
      );
      final rect = tester.getRect(surface());
      expect(
        const Rect.fromLTWH(0, 0, 700, 300).intersect(rect),
        rect,
        reason: 'The capped surface stays inside the boundary.',
      );
    });

    testWidgets('contentMaxWidth caps the body inside the padding', (
      tester,
    ) async {
      final rect = await place(
        tester,
        anchor: const Offset(200, 290),
        data: const FluentChartPopoverData(
          legend:
              'A description long enough to need far more than two hundred '
              'and thirty-eight pixels on one line',
          yValue: '433',
          contentMaxWidth: 238,
        ),
      );
      final padding = resolveFluentChartPopoverStyle(theme).surfacePadding!
          .resolve(const <WidgetState>{})!
          .resolve(TextDirection.ltr);
      expect(
        rect.width,
        moreOrLessEquals(238 + padding.horizontal, epsilon: 0.01),
        reason:
            'HeatMapChart puts maxWidth 238 on calloutContentRoot '
            '(useHeatMapChartStyles.styles.ts:35-37), inside the 16px surface '
            'padding.',
      );
    });

    testWidgets('re-lays out when the anchor moves', (tester) async {
      final a = await place(tester, anchor: const Offset(200, 200));
      final b = await place(tester, anchor: const Offset(220, 200));
      expect(
        b.left - a.left,
        moreOrLessEquals(20, epsilon: 0.5),
        reason: 'A new anchor must reach the render object.',
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

    testWidgets('flips below a cursor too near the top', (tester) async {
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
            'Ten pixels leave no room above, so the surface flips below and '
            'keeps the same 20px clearance.',
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

  group('the popover surface width', () {
    // The defect: a Sankey link popover holding three short readings rendered
    // the full plot width. Any box far wider than the content reproduces it —
    // 760 is the widest that leaves the 800x600 test surface room for the
    // anchor offset, and 500 is taller than the popover can grow, so the
    // delegate never flips it.
    const plotWidth = 760.0;
    const longLegend =
        'A very long series name that goes on and on and on and should '
        'eventually have to wrap somewhere rather than run forever';

    Finder surface() => find.descendant(
      of: find.byType(FluentChartPopover),
      matching: find.byType(ExcludeFocus),
    );

    Future<void> pump(WidgetTester tester, String legend) => tester.pumpWidget(
      FluentApp(
        theme: theme,
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: plotWidth,
            height: 500,
            child: FluentChartPopover(
              anchor: Offset.zero,
              data: FluentChartPopoverData(
                xValue: 'node4',
                legend: legend,
                yValue: '2',
              ),
            ),
          ),
        ),
      ),
    );

    testWidgets('the surface measures its content, not the plot box', (
      tester,
    ) async {
      await pump(tester, 'From node0');
      final resolved = resolveFluentChartPopoverStyle(theme);
      final padding = resolved.surfacePadding!
          .resolve(const <WidgetState>{})!
          .resolve(TextDirection.ltr);
      // PopoverSurface's `1px solid transparent` border takes layout space on
      // both sides (usePopoverSurfaceStyles.styles.raw.js:20).
      final border = resolved.surfaceBorderWidth!.resolve(
        const <WidgetState>{},
      )!;
      // The widest of the two stacked bodies: the bare x reading, or the
      // accent bar plus its gap plus the taller block beside it.
      final content =
          padding.horizontal +
          2 * border +
          max(
            tester.getSize(find.text('node4')).width,
            kChartPopoverAccentBarWidth +
                FluentSpacing.s +
                max(
                  tester.getSize(find.text('From node0')).width,
                  tester.getSize(find.text('2')).width,
                ),
          );
      expect(
        tester.getSize(surface()).width,
        moreOrLessEquals(content, epsilon: 0.01),
        reason:
            'useChartPopoverStyles.styles.ts:33-107 sets no width, min-width '
            'or max-width on any slot, so the surface is shrink-to-fit and '
            "`autoSize: 'always'` (ChartPopover.tsx:48) only caps it. A body "
            'left on the MainAxisSize.max default reports the loose box the '
            'layout delegate hands down instead — the whole plot width.',
      );
    });

    testWidgets('a long series name wraps instead of running past the '
        'surface', (tester) async {
      await pump(tester, longLegend);
      expect(
        tester.getSize(find.text(longLegend)).width,
        lessThanOrEqualTo(plotWidth),
        reason:
            'calloutBlockContainer is a block-level div '
            '(useChartPopoverStyles.styles.ts:49-52) inside a grid root that '
            'clips (:35), so upstream wraps at the cap. A Row lays a '
            'non-flexible child out with an unbounded main axis, so without '
            'Flexible the legend is laid out at its full intrinsic width and '
            'RenderFlex overflows the surface.',
      );
    });
  });
}
