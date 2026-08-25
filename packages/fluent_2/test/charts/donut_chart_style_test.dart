import 'dart:math' as math;

import 'package:fluent_2/src/charts/donut_chart_style.dart';
import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/oracle_fixture.dart';

/// `cornerRadius` is 0 and stays 0. `DonutChart.types.ts:129` declares a
/// `roundCorners` prop, but `DonutChart` never forwards it to `Pie` and `Pie`
/// never forwards it to `Arc` (`Pie.tsx:62-84`), so `Arc.tsx:114` always
/// evaluates `props.roundCorners ? 3 : 0` against undefined. Grep across
/// `components/DonutChart/` finds only the two type declarations and that one
/// line: the prop is dead.
void main() {
  const states = <WidgetState>{};
  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  test('the pie pad angle is 0.02 radians and the corner radius is 0', () {
    final style = resolveFluentDonutChartStyle(theme);
    expect(
      style.padAngle!.resolve(states),
      0.02,
      reason: 'Pie.tsx:98 sets .padAngle(0.02) on the layout.',
    );
    expect(
      style.cornerRadius!.resolve(states),
      0.0,
      reason:
          'Arc.tsx:114 — roundCorners never reaches Arc, so the corner '
          'radius is always zero for the donut.',
    );
  });

  test('each slice carries a one-pixel background-coloured outline', () {
    final style = resolveFluentDonutChartStyle(theme);
    expect(
      style.arcStrokeWidth!.resolve(states),
      1.0,
      reason:
          'useArcStyles.styles.ts:22-31 declares a stroke but no '
          'stroke-width, so SVG applies its default of 1.',
    );
    expect(
      style.arcStrokeColor!.resolve(states)!.toARGB32(),
      theme.colors.neutralBackground1.toARGB32(),
      reason:
          'useArcStyles.styles.ts:25 strokes with '
          'colorNeutralBackground1.',
    );
  });

  test('the focus ring is four pixels of strokeFocus2', () {
    final style = resolveFluentDonutChartStyle(theme);
    expect(
      style.focusRingWidth!.resolve(states),
      4.0,
      reason: 'useArcStyles.styles.ts:34 uses strokeWidthThickest, which is 4.',
    );
    expect(
      style.focusRingColor!.resolve(states)!.toARGB32(),
      theme.colors.strokeFocus2.toARGB32(),
      reason: 'useArcStyles.styles.ts:33.',
    );
  });

  test('the label margins and the minimum sweep', () {
    final style = resolveFluentDonutChartStyle(theme);
    expect(
      style.labelMarginHorizontal!.resolve(states),
      80.0,
      reason: 'DonutChart.tsx:332 — 80 when labels are shown, 0 when hidden.',
    );
    expect(
      style.labelMarginVertical!.resolve(states),
      40.0,
      reason: 'DonutChart.tsx:333.',
    );
    expect(
      style.labelRadiusOffset!.resolve(states),
      2.0,
      reason: 'Arc.tsx:79 — max(innerRadius, outerRadius) + 2.',
    );
    expect(
      style.minLabelSweep!.resolve(states),
      closeTo(math.pi / 12, 1e-12),
      reason:
          'Arc.tsx:71 hides a label whose sweep is under PI/12, i.e. 15 '
          'degrees.',
    );
  });

  test('the title height floor is 36 with a fallback font size of 13', () {
    final style = resolveFluentDonutChartStyle(theme);
    expect(
      style.titleHeightMin!.resolve(states),
      36.0,
      reason: 'DonutChart.tsx:276-284 — max(fontSize + 20, 36).',
    );
    expect(
      style.titleFontFallbackSize!.resolve(states),
      13.0,
      reason:
          'DonutChart.tsx:279 falls back to 13 when titleFont.size is not '
          'a number.',
    );
  });

  test('the centre value is title2 and the wrap padding is 5', () {
    final style = resolveFluentDonutChartStyle(theme);
    expect(
      style.centreValueTextStyle!.resolve(states)!.fontSize,
      28.0,
      reason:
          'usePieStyles.styles.ts:23 gives insideDonutString '
          'typographyStyles.title2, which is 28/36 semibold.',
    );
    expect(
      style.centreTextPadding!.resolve(states),
      5.0,
      reason:
          'Pie.tsx:24 wraps at innerRadius * 2 - TEXT_PADDING, and '
          'TEXT_PADDING is 5 (Pie.tsx:14).',
    );
    expect(
      style.centreTextBaselineOffset!.resolve(states),
      5.0,
      reason:
          'Pie.tsx:107 places the centre text at y = 5 with '
          'dominant-baseline middle.',
    );
  });

  test('an unhighlighted slice is one tenth opaque', () {
    expect(
      resolveFluentDonutChartStyle(theme).dimmedOpacity!.resolve(states),
      0.1,
      reason: 'Arc.tsx:112-113.',
    );
  });

  test('the legend sits a spacingVerticalL below the donut', () {
    expect(
      resolveFluentDonutChartStyle(theme).legendGap!.resolve(states),
      16.0,
      reason:
          'useDonutChartStyles.styles.ts:42-45 — legendContainer has '
          'paddingTop: spacingVerticalL, which is 16.',
    );
  });

  test('the minimum donut radius that shows a centre value is 1', () {
    expect(
      resolveFluentDonutChartStyle(theme).minDonutRadius!.resolve(states),
      1.0,
      reason:
          'utilities.ts:90 declares MIN_DONUT_RADIUS = 1, and '
          'DonutChart.tsx:337-338 shows the centre value only when '
          'innerRadius exceeds it.',
    );
  });

  test('merge and equality behave like FluentBadgeStyle', () {
    final base = FluentDonutChartStyle.from(padAngle: 0.02, dimmedOpacity: 0.1);
    expect(
      base
          .merge(FluentDonutChartStyle.from(dimmedOpacity: 0.5))
          .padAngle!
          .resolve(states),
      0.02,
      reason: 'merge is per-property.',
    );
    expect(
      base
          .merge(FluentDonutChartStyle.from(dimmedOpacity: 0.5))
          .dimmedOpacity!
          .resolve(states),
      0.5,
      reason: 'and the non-null property of the other style wins.',
    );
    expect(
      FluentDonutChartStyle.from(padAngle: 0.02),
      FluentDonutChartStyle.from(padAngle: 0.02),
      reason: 'Equality is per-property, as on FluentBadgeStyle.',
    );
    expect(
      FluentDonutChartStyle.from(padAngle: 0.02).hashCode,
      FluentDonutChartStyle.from(padAngle: 0.02).hashCode,
      reason:
          'Equal styles hash equally; with 20 fields the implementation '
          'uses Object.hashAll rather than Object.hash.',
    );
    expect(
      FluentDonutChartStyle.from(padAngle: 0.02)
          .copyWith(cornerRadius: const WidgetStatePropertyAll<double?>(3))
          .cornerRadius!
          .resolve(states),
      3.0,
      reason: 'copyWith replaces only the named property.',
    );
  });

  // Oracle B. The captured donut stories carry the resolved paint and the
  // rendered geometry of the live component, so the literals above are checked
  // against what upstream actually drew rather than only against the source.
  group('against the captured DonutChart stories', () {
    test('the corpus still holds the two stories these assertions read', () {
      expect(
        oracleStoryIds(component: 'DonutChart'),
        containsAll(<String>[
          'charts-donutchart--donut-chart-basic',
          'charts-donutchart--donut-chart-dynamic',
        ]),
        reason:
            'A renamed or dropped fixture must fail loudly rather than '
            'silently stop checking the arc paint.',
      );
    });

    test('every captured arc is stroked 1px in neutralBackground1', () {
      final story = loadOracleStory('charts-donutchart--donut-chart-basic');
      final style = resolveFluentDonutChartStyle(theme);
      final arcs = story.byTag('path');
      expect(
        arcs.length,
        2,
        reason:
            'The basic story has two slices; a different count means the '
            'fixture changed and the loop below would assert nothing.',
      );
      for (final arc in arcs) {
        expectOracleNumber(
          'arc #${arc.index} stroke width',
          arc.strokeWidth,
          style.arcStrokeWidth!.resolve(states)!,
        );
        expectOracleColour(
          'arc #${arc.index} stroke',
          arc.stroke,
          style.arcStrokeColor!.resolve(states),
        );
      }
    });

    test('the centre value is drawn at y = 5 in 28px semibold', () {
      final story = loadOracleStory('charts-donutchart--donut-chart-basic');
      final style = resolveFluentDonutChartStyle(theme);
      final centre = story.soleElement(
        'text',
        where: (element) => element.text == '35,000',
      );
      expectOracleNumber(
        'centre value baseline offset',
        centre.y!,
        style.centreTextBaselineOffset!.resolve(states)!,
      );
      expectOracleNumber(
        'centre value font size',
        centre.fontSize,
        style.centreValueTextStyle!.resolve(states)!.fontSize!,
      );
      expect(
        style.centreValueTextStyle!.resolve(states)!.fontWeight,
        FluentFontWeight.semibold,
        reason: 'The capture reports font-weight 600 for the centre value.',
      );
      expectOracleColour(
        'centre value fill',
        centre.fill,
        style.centreValueTextStyle!.resolve(states)!.color,
      );
    });

    test('the chart title is drawn in 10px semibold', () {
      final story = loadOracleStory('charts-donutchart--donut-chart-basic');
      final style = resolveFluentDonutChartStyle(theme);
      final title = story.soleElement(
        'text',
        where: (element) => element.text == 'Donut chart basic example',
      );
      expectOracleNumber(
        'chart title font size',
        title.fontSize,
        style.titleTextStyle!.resolve(states)!.fontSize!,
      );
      expectOracleColour(
        'chart title fill',
        title.fill,
        style.titleTextStyle!.resolve(states)!.color,
      );
    });

    test('the arc labels are caption1Strong on the label radius', () {
      final story = loadOracleStory('charts-donutchart--donut-chart-dynamic');
      final style = resolveFluentDonutChartStyle(theme);
      // Every arc in the dynamic story is drawn with the same radii, so the
      // first one carries them for all four. `svgPathNumbers` flattens
      // `M x,y A rx,ry …` — index 2 is the outer rx, and index 11 the inner rx
      // of the closing arc that walks back along the hole.
      final arcs = story.byTag('path');
      expect(
        arcs.length,
        4,
        reason:
            'The dynamic story has four slices; a different count means the '
            'radii read below come from something else.',
      );
      final numbers = svgPathNumbers(arcs.first.d!);
      final outerRadius = numbers[2];
      final innerRadius = numbers[11];
      expect(
        <double>[outerRadius, innerRadius],
        <double>[86, 35],
        reason:
            'The dynamic story renders an 86/35 donut; the label-radius '
            'assertion below is meaningless if these are not the radii.',
      );

      final labels = story
          .byTag('text')
          .where((element) => element.fontSize == 12)
          .toList();
      expect(
        labels.length,
        4,
        reason: 'One arc label per slice, all four sweeps exceeding PI/12.',
      );
      final labelRadius =
          math.max(outerRadius, innerRadius) +
          style.labelRadiusOffset!.resolve(states)!;
      for (final label in labels) {
        expectOracleNumber(
          'arc label "${label.text}" distance from the centre',
          math.sqrt(label.x! * label.x! + label.y! * label.y!),
          labelRadius,
        );
        expectOracleNumber(
          'arc label "${label.text}" font size',
          label.fontSize,
          style.arcLabelTextStyle!.resolve(states)!.fontSize!,
        );
        expectOracleColour(
          'arc label "${label.text}" fill',
          label.fill,
          style.arcLabelTextStyle!.resolve(states)!.color,
        );
      }
    });

    test('the pad angle explains where the first slice starts', () {
      final story = loadOracleStory('charts-donutchart--donut-chart-dynamic');
      final style = resolveFluentDonutChartStyle(theme);
      final first = story.byTag('path').first;
      final numbers = svgPathNumbers(first.d!);
      final outerRadius = numbers[2];
      final innerRadius = numbers[11];
      // `d3-shape/src/arc.js:96-112`: with a pad angle and no explicit pad
      // radius the generator pads by `sqrt(r0² + r1²) * sin(padAngle / 2)` of
      // arc length, so the outer start point of the first slice — whose
      // unpadded start angle is 0, i.e. twelve o'clock — lands at
      // (rp·sin(p), −r1·cos(asin(rp·sin(p) / r1))) for p = padAngle / 2.
      final halfPad = style.padAngle!.resolve(states)! / 2;
      final padRadius = math.sqrt(
        innerRadius * innerRadius + outerRadius * outerRadius,
      );
      final dx = padRadius * math.sin(halfPad);
      expectOracleOffset(
        'the first slice outer start point',
        Offset(numbers[0], numbers[1]),
        Offset(dx, -outerRadius * math.cos(math.asin(dx / outerRadius))),
      );
    });
  });
}
