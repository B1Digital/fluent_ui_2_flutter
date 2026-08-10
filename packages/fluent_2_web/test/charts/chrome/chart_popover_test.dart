import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/chrome/chart_popover.dart';
import 'package:fluent_2_web/src/charts/chrome/chart_popover_style.dart';
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
}
