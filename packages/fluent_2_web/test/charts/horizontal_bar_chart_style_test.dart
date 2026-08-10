import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/horizontal_bar_chart_style.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/oracle_fixture.dart';

/// `barHeight` is the value the documentation and the code disagree about:
/// `HorizontalBarChart.types.ts:25` documents 15, `HorizontalBarChart.tsx:106`
/// runs `props.barHeight || 12`. The code wins.
void main() {
  const states = <WidgetState>{};
  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  test('the runtime bar height is 12, not the documented 15', () {
    expect(
      resolveFluentHorizontalBarChartStyle(theme).barHeight!.resolve(states),
      12.0,
      reason:
          'HorizontalBarChart.tsx:106 is `props.barHeight || 12`; the 15 '
          'at HorizontalBarChart.types.ts:25 is documentation only.',
    );
  });

  test('the inter-bar gap is 3 logical pixels', () {
    expect(
      resolveFluentHorizontalBarChartStyle(theme).barGap!.resolve(states),
      3.0,
      reason: 'HorizontalBarChart.tsx:364 declares MARGIN_WIDTH_IN_PX = 3.',
    );
  });

  test('a dimmed bar is exactly one tenth opaque', () {
    expect(
      resolveFluentHorizontalBarChartStyle(
        theme,
      ).dimmedOpacity!.resolve(states),
      0.1,
      reason:
          'HorizontalBarChart.tsx:327 is `opacity={isLegendSelected ? 1 '
          ': 0.1}` — there is no third state.',
    );
  });

  test(
    'row spacing switches on the triangle and the absolute-scale variant',
    () {
      final style = resolveFluentHorizontalBarChartStyle(theme);
      expect(
        style.rowSpacing!.resolve(states),
        10.0,
        reason:
            'useHorizontalBarChartStyles.styles.ts:40 uses '
            'spacingVerticalMNudge, which is 10.',
      );
      expect(
        style.rowSpacingWithTriangle!.resolve(states),
        16.0,
        reason:
            'useHorizontalBarChartStyles.styles.ts:43 uses spacingVerticalL, '
            'which is 16, and :121-123 selects it when showTriangle or the '
            'AbsoluteScale variant is set.',
      );
    },
  );

  test('the row title spacings are 5 normally and 4 on the absolute scale', () {
    final style = resolveFluentHorizontalBarChartStyle(theme);
    expect(
      style.titleBottomSpacing!.resolve(states),
      5.0,
      reason:
          'useHorizontalBarChartStyles.styles.ts:68 is `marginBottom: 5px`.',
    );
    expect(
      style.titleBottomSpacingAbsolute!.resolve(states),
      4.0,
      reason:
          'useHorizontalBarChartStyles.styles.ts:65 is `marginBottom: 4px`, '
          'selected at :132 for the AbsoluteScale variant.',
    );
  });

  test('the absolute-scale bar label sits 4 past the bar start', () {
    expect(
      resolveFluentHorizontalBarChartStyle(
        theme,
      ).barLabelOffset!.resolve(states),
      4.0,
      reason:
          'HorizontalBarChart.tsx:297 is '
          r'`transform={`translate(${_isRTL ? -4 : 4})`}`.',
    );
  });

  test('the legend strip is pushed down by spacingVerticalL', () {
    expect(
      resolveFluentHorizontalBarChartStyle(
        theme,
      ).legendTopPadding!.resolve(states),
      16.0,
      reason:
          'useHorizontalBarChartStyles.styles.ts:107 is '
          '`legendContainer: { paddingTop: tokens.spacingVerticalL }`.',
    );
  });

  test('the benchmark triangle is 8 wide by 7 tall in blue stroke-active', () {
    final style = resolveFluentHorizontalBarChartStyle(theme);
    expect(
      style.benchmarkWidth!.resolve(states),
      8.0,
      reason:
          'useHorizontalBarChartStyles.styles.ts:87-88 — 4px transparent '
          'left border plus 4px transparent right border.',
    );
    expect(
      style.benchmarkHeight!.resolve(states),
      7.0,
      reason: 'useHorizontalBarChartStyles.styles.ts:89 — 7px top border.',
    );
    expect(
      style.benchmarkColor!.resolve(states)!.toARGB32(),
      theme.colors.palette
          .strokeActiveRest(FluentPaletteFamily.blue)
          .toARGB32(),
      reason:
          'useHorizontalBarChartStyles.styles.ts:90 uses '
          'colorPaletteBlueBorderActive.',
    );
  });

  test('the default palette is the five foreground2 ramp entries in order', () {
    final palette = resolveFluentHorizontalBarChartStyle(
      theme,
    ).defaultPalette!.resolve(states)!;
    expect(
      palette.map((c) => c.toARGB32()).toList(),
      <int>[
        theme.colors.palette
            .foreground2Rest(FluentPaletteFamily.blue)
            .toARGB32(),
        theme.colors.palette
            .foreground2Rest(FluentPaletteFamily.cornflower)
            .toARGB32(),
        theme.colors.palette
            .foreground2Rest(FluentPaletteFamily.darkGreen)
            .toARGB32(),
        theme.colors.palette
            .foreground2Rest(FluentPaletteFamily.navy)
            .toARGB32(),
        theme.colors.palette
            .foreground2Rest(FluentPaletteFamily.darkOrange)
            .toARGB32(),
      ],
      reason:
          'HorizontalBarChart.tsx:223-229 lists the five defaultColors in '
          'this order.',
    );
  });

  test('the placeholder bar is the overlay token', () {
    expect(
      resolveFluentHorizontalBarChartStyle(
        theme,
      ).placeholderColor!.resolve(states)!.toARGB32(),
      theme.colors.backgroundOverlay.toARGB32(),
      reason:
          'HorizontalBarChart.tsx:411 fills the synthesised remainder bar '
          'with colorBackgroundOverlay.',
    );
  });

  test('the four type ramps come from the theme', () {
    final style = resolveFluentHorizontalBarChartStyle(theme);
    expect(
      style.titleTextStyle!.resolve(states)!.fontSize,
      theme.typography.caption1.fontSize,
      reason: 'useHorizontalBarChartStyles.styles.ts:53 spreads caption1.',
    );
    expect(
      style.valueTextStyle!.resolve(states)!.fontWeight,
      theme.typography.body1Strong.fontWeight,
      reason: 'useHorizontalBarChartStyles.styles.ts:71 spreads body1Strong.',
    );
    expect(
      style.denominatorTextStyle!.resolve(states)!.fontSize,
      theme.typography.body1.fontSize,
      reason: 'useHorizontalBarChartStyles.styles.ts:75 spreads body1.',
    );
    expect(
      style.barLabelTextStyle!.resolve(states)!.color!.toARGB32(),
      theme.colors.neutralForeground1.toARGB32(),
      reason:
          'useHorizontalBarChartStyles.styles.ts:95-96 spreads caption1Strong '
          'and fills with colorNeutralForeground1.',
    );
  });

  // Oracle B. The captured stories carry the rendered box model, so the
  // literals above are checked against what the browser actually laid out
  // rather than only against the stylesheet they were read from.
  group('against the captured HorizontalBarChart stories', () {
    final style = resolveFluentHorizontalBarChartStyle(theme);
    final basic = loadOracleStory(
      'charts-horizontalbarchart--horizontal-bar-basic',
    );
    final absolute = loadOracleStory(
      'charts-horizontalbarchart--horizontal-bar-absolute-scale',
    );

    /// The `fui-hbc__chartTitle` boxes only — [OracleStory.boxes] matches by
    /// prefix, so it would also return `chartTitleLeft` and `chartTitleRight`.
    List<OracleHtmlBox> titles(OracleStory story) => story.htmlBoxes
        .where((box) => box.slot == 'fui-hbc__chartTitle')
        .toList();

    test('every captured bar rect and chart svg is barHeight tall', () {
      final rects = <OracleElement>[
        for (final svg in basic.svgs)
          ...svg.elements.where((element) => element.tag == 'rect'),
      ];
      expect(
        rects.length,
        16,
        reason: 'The basic story is eight rows of bar + placeholder.',
      );
      final barHeight = style.barHeight!.resolve(states)!;
      for (final rect in rects) {
        expectOracleNumber('rect height', barHeight, rect.height!);
      }
      for (final svg in basic.svgs) {
        expectOracleNumber('svg height', barHeight, svg.height);
      }
    });

    test('consecutive bars are barGap apart in rendered pixels', () {
      final gaps = <double>[
        for (final svg in basic.svgs)
          if (svg.elements.where((e) => e.tag == 'rect').length == 2)
            svg.elements.where((e) => e.tag == 'rect').last.bbox!.left -
                svg.elements.where((e) => e.tag == 'rect').first.bbox!.right,
      ];
      expect(
        gaps.length,
        8,
        reason: 'All eight rows of the basic story hold exactly two rects.',
      );
      final barGap = style.barGap!.resolve(states)!;
      for (final gap in gaps) {
        expectOracleNumber('inter-bar gap', barGap, gap);
      }
    });

    test('the synthesised remainder bar is painted in placeholderColor', () {
      final placeholders = <OracleElement>[
        for (final svg in basic.svgs)
          svg.elements.where((element) => element.tag == 'rect').last,
      ];
      expect(placeholders.length, 8, reason: 'One placeholder per row.');
      for (final rect in placeholders) {
        expectOracleColour(
          'placeholder fill',
          style.placeholderColor!.resolve(states),
          rect.fill,
        );
      }
    });

    test('the row pitch is title + bar + rowSpacing', () {
      final boxes = titles(basic);
      expect(boxes.length, 8, reason: 'Eight titled rows.');
      final expected =
          boxes.first.rect.height +
          style.barHeight!.resolve(states)! +
          style.rowSpacing!.resolve(states)!;
      for (var i = 1; i < boxes.length; i++) {
        expectOracleNumber(
          'row $i pitch',
          expected,
          boxes[i].rect.top - boxes[i - 1].rect.top,
        );
      }
    });

    test('the absolute-scale row pitch uses the 4/16 pair', () {
      final boxes = titles(absolute);
      final lefts = absolute.boxes('fui-hbc__chartTitleLeft');
      expect(boxes.length, 8, reason: 'Eight titled rows.');
      expect(lefts.length, 8, reason: 'One title label per row.');
      // The title row is a flex column of the label plus its bottom margin —
      // useHorizontalBarChartStyles.styles.ts:65 — and there is no right-hand
      // value in this variant (HorizontalBarChart.tsx:415-417), so the label
      // height alone sets the box.
      expectOracleNumber(
        'title box height',
        lefts.first.rect.height +
            style.titleBottomSpacingAbsolute!.resolve(states)!,
        boxes.first.rect.height,
      );
      final expected =
          boxes.first.rect.height +
          style.barHeight!.resolve(states)! +
          style.rowSpacingWithTriangle!.resolve(states)!;
      for (var i = 1; i < boxes.length; i++) {
        expectOracleNumber(
          'absolute row $i pitch',
          expected,
          boxes[i].rect.top - boxes[i - 1].rect.top,
        );
      }
    });

    test('the absolute-scale bar label is translated by barLabelOffset', () {
      final labels = <OracleElement>[
        for (final svg in absolute.svgs)
          ...svg.elements.where((element) => element.tag == 'text'),
      ];
      expect(labels.length, 8, reason: 'One bar label per row.');
      final offset = style.barLabelOffset!.resolve(states)!;
      final fontSize = style.barLabelTextStyle!.resolve(states)!.fontSize;
      for (final label in labels) {
        expectOracleNumber('label translate.dx', offset, label.translate!.dx);
        expectOracleNumber('label font size', fontSize!, label.fontSize);
      }
    });

    test('the title and value type sizes match the captured boxes', () {
      expectOracleNumber(
        'title font size',
        style.titleTextStyle!.resolve(states)!.fontSize!,
        titles(basic).first.fontSize,
      );
      final rights = basic.boxes('fui-hbc__chartTitleRight');
      expect(rights.length, 8, reason: 'One value per row.');
      expectOracleNumber(
        'value font size',
        style.valueTextStyle!.resolve(states)!.fontSize!,
        rights.first.fontSize,
      );
    });
  });

  test('merge and equality behave like FluentBadgeStyle', () {
    final base = FluentHorizontalBarChartStyle.from(barHeight: 12, barGap: 3);
    expect(
      base
          .merge(FluentHorizontalBarChartStyle.from(barGap: 4))
          .barHeight!
          .resolve(states),
      12.0,
      reason: 'merge is per-property.',
    );
    expect(
      FluentHorizontalBarChartStyle.from(barHeight: 12),
      equals(FluentHorizontalBarChartStyle.from(barHeight: 12)),
      reason: 'Value equality is required by the theme.',
    );
    expect(
      FluentHorizontalBarChartStyle.from(barHeight: 12).hashCode,
      FluentHorizontalBarChartStyle.from(barHeight: 12).hashCode,
      reason: 'hashCode must agree with ==.',
    );
    expect(
      base
          .copyWith(barGap: const WidgetStatePropertyAll<double?>(4))
          .barGap!
          .resolve(states),
      4.0,
      reason: 'copyWith replaces exactly the named property.',
    );
    expect(
      base.merge(null),
      same(base),
      reason: 'merging null is the identity.',
    );
  });
}
