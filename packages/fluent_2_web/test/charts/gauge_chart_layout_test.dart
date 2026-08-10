import 'package:fluent_2_web/src/charts/gauge_chart.dart';
import 'package:fluent_2_web/src/charts/internal/data_viz_palette.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/oracle_fixture.dart';

/// The chain is margins → outer radius → breakpoint → arc width → inner radius
/// → chart-value font size, and one wrong margin flips a whole tier: 12px arcs
/// become 16px and 20px text becomes 24px. Every tuple below is transcribed
/// from `GaugeChart.tsx:109-143` and `:167-179`.
void main() {
  const segments = <FluentGaugeChartSegment>[
    FluentGaugeChartSegment(legend: 'A', size: 50),
    FluentGaugeChartSegment(legend: 'B', size: 50),
  ];

  FluentGaugeLayout layoutOf(
    Size size, {
    bool hasTitle = false,
    bool hasSublabel = false,
    bool hideMinMax = false,
    bool hideLegend = false,
    double minValue = 0,
    double? maxValue,
    List<FluentGaugeChartSegment> data = segments,
  }) => FluentGaugeLayout.compute(
    size: size,
    segments: data,
    minValue: minValue,
    maxValue: maxValue,
    hasTitle: hasTitle,
    hasSublabel: hasSublabel,
    hideMinMax: hideMinMax,
    hideLegend: hideLegend,
    gaugeMargin: 16,
    labelWidth: 36,
    labelHeight: 16,
    labelOffset: 4,
    titleOffset: 11,
    extraNeedleLength: 4,
    legendsHeight: 32,
    unknownColour: const Color(0xFF7A7574),
    isDark: false,
  );

  group('margins', () {
    test('the default gauge reserves 56 each side and 18 above, 16 below', () {
      expect(
        layoutOf(const Size(400, 300)).margins,
        const EdgeInsets.fromLTRB(56, 18, 56, 16),
        reason:
            'GaugeChart.tsx:110-115 — 4 + 36 + 16 horizontally, and '
            'EXTRA_NEEDLE_LENGTH / 2 + 16 above when there is no title.',
      );
    });

    test('hiding the min and max labels drops each side to 16', () {
      expect(
        layoutOf(const Size(400, 300), hideMinMax: true).margins,
        const EdgeInsets.fromLTRB(16, 18, 16, 16),
        reason:
            'GaugeChart.tsx:112-113 — the label term collapses to 0, '
            'leaving GAUGE_MARGIN.',
      );
    });

    test('a title raises the top margin to 43', () {
      expect(
        layoutOf(const Size(400, 300), hasTitle: true).margins.top,
        43.0,
        reason:
            'GaugeChart.tsx:114 — TITLE_OFFSET 11 plus LABEL_HEIGHT 16 '
            'plus GAUGE_MARGIN 16.',
      );
    });

    test('a sublabel raises the bottom margin to 36', () {
      expect(
        layoutOf(const Size(400, 300), hasSublabel: true).margins.bottom,
        36.0,
        reason:
            'GaugeChart.tsx:115 — LABEL_OFFSET 4 plus LABEL_HEIGHT 16 plus '
            'GAUGE_MARGIN 16.',
      );
    });
  });

  group('the radius is width-halved and height-whole', () {
    test('a wide box is limited by the halved width', () {
      expect(
        layoutOf(const Size(400, 300)).outerRadius,
        144.0,
        reason:
            'GaugeChart.tsx:138-141 — min((400 - 112) / 2, '
            '300 - (18 + 16 + 32)) is min(144, 234). The gauge is a half disc, '
            'so it spans 2R horizontally but only R vertically, which is why '
            'only the width term is halved.',
      );
    });

    test('a short box is limited by the whole height', () {
      expect(
        layoutOf(const Size(400, 100)).outerRadius,
        34.0,
        reason: 'min(144, 100 - 66) is 34.',
      );
    });

    test('hiding the legend returns its 32 pixels to the height budget', () {
      expect(
        layoutOf(const Size(400, 100), hideLegend: true).outerRadius,
        66.0,
        reason:
            'GaugeChart.tsx:119 zeroes the legend height, so the height '
            'term becomes 100 - 34.',
      );
    });
  });

  group('breakpoints', () {
    // Widths chosen so (w - 112) / 2 lands exactly on each minRadius.
    const cases = <(double, double, double, double)>[
      // width, expected outer radius, arc width, chart value font size
      (216, 52, 12, 20),
      (252, 70, 16, 24),
      (288, 88, 20, 32),
      (324, 106, 24, 32),
      (360, 124, 28, 40),
      (396, 142, 32, 40),
    ];

    for (final (width, radius, arcWidth, fontSize) in cases) {
      test('an outer radius of exactly $radius takes its own tier', () {
        final layout = layoutOf(Size(width, 400));
        expect(layout.outerRadius, radius, reason: 'GaugeChart.tsx:138-141.');
        expect(
          layout.arcWidth,
          arcWidth,
          reason:
              'GaugeChart.tsx:169 is a >= comparison, so a radius exactly '
              'at minRadius belongs to that tier and not the one below.',
        );
        expect(
          layout.chartValueFontSize,
          fontSize,
          reason: 'GaugeChart.tsx:172.',
        );
        expect(
          layout.innerRadius,
          radius - arcWidth,
          reason: 'GaugeChart.tsx:143.',
        );
      });
    }

    test('below the smallest tier the table falls back to entry zero', () {
      final layout = layoutOf(const Size(200, 400));
      expect(
        layout.outerRadius,
        44.0,
        reason: '(200 - 112) / 2 is 44, below the first minRadius of 52.',
      );
      expect(
        (layout.arcWidth, layout.chartValueFontSize),
        (12.0, 20.0),
        reason:
            'GaugeChart.tsx:176-179 falls back to BREAKPOINTS[0] rather '
            'than to nothing.',
      );
    });
  });

  test('the origin sits above the bottom by the margin plus the legend', () {
    expect(
      layoutOf(const Size(400, 300)).origin,
      const Offset(200, 252),
      reason:
          'GaugeChart.tsx:599 is translate(_width / 2, _height - '
          '(margins.bottom + legendsHeight)) — and it uses the LOGICAL height, '
          'not the svg height at :594, which is already 32 shorter.',
    );
  });

  group('segments', () {
    test(
      'start and end are offset by minValue because total seeds with it',
      () {
        final layout = layoutOf(const Size(400, 300), minValue: 20);
        expect(
          (layout.segments.first.start, layout.segments.first.end),
          (20.0, 70.0),
          reason:
              'GaugeChart.tsx:185 seeds total with minValue, so a gauge '
              'starting at 20 labels its first segment 20 to 70.',
        );
        expect(
          layout.maxValue,
          120.0,
          reason:
              'GaugeChart.tsx:206 — the resolved maximum is the running '
              'total, which includes the seed.',
        );
      },
    );

    test('a negative size is clamped to zero', () {
      final layout = layoutOf(
        const Size(400, 300),
        data: const <FluentGaugeChartSegment>[
          FluentGaugeChartSegment(legend: 'A', size: -5),
          FluentGaugeChartSegment(legend: 'B', size: 50),
        ],
      );
      expect(
        layout.segments.first.size,
        0.0,
        reason: 'GaugeChart.tsx:191 — Math.max(segment.size, 0).',
      );
    });

    test('a maxValue above the total appends an Unknown filler', () {
      final layout = layoutOf(const Size(400, 300), maxValue: 150);
      expect(
        layout.segments.length,
        3,
        reason:
            'GaugeChart.tsx:204-213 appends the filler when the total '
            'falls short.',
      );
      expect(
        (layout.segments.last.legend, layout.segments.last.size),
        ('Unknown', 50.0),
        reason: 'The filler spans maxValue minus the running total.',
      );
    });

    test('a maxValue at or below the total appends nothing', () {
      expect(
        layoutOf(const Size(400, 300), maxValue: 100).segments.length,
        2,
        reason: 'GaugeChart.tsx:204 is a strict `total < maxValue`.',
      );
    });

    test('an uncoloured segment takes the next qualitative colour', () {
      final layout = layoutOf(const Size(400, 300));
      expect(
        layout.segments[1].colour.toARGB32(),
        FluentDataVizPalette.next(1).toARGB32(),
        reason:
            'GaugeChart.tsx:196 — getNextColor(index, 0, false), with the '
            'isDark flag left false by every imperative chart.',
      );
    });
  });

  group('needle rotation', () {
    test('the value maps linearly across 180 degrees', () {
      expect(
        FluentGaugeLayout.needleRotation(50, 0, 100),
        90.0,
        reason: 'GaugeChart.tsx:45 — (value - min) / (max - min) * 180.',
      );
    });

    test('below the minimum it clamps to zero', () {
      expect(
        FluentGaugeLayout.needleRotation(-10, 0, 100),
        0.0,
        reason: 'GaugeChart.tsx:46-48.',
      );
    });

    test('above the maximum it clamps to 180', () {
      expect(
        FluentGaugeLayout.needleRotation(110, 0, 100),
        180.0,
        reason: 'GaugeChart.tsx:48-50.',
      );
    });
  });

  test('the needle is the arc width plus four', () {
    final layout = layoutOf(const Size(288, 400));
    expect(
      layout.needleLength,
      24.0,
      reason:
          'GaugeChart.tsx:253 — outerRadius - innerRadius + '
          'EXTRA_NEEDLE_LENGTH, and the first two terms are the arc width.',
    );
  });

  group('Oracle B', () {
    // The capture records the svg box, and `GaugeChart.tsx:594` draws that svg
    // one legend shorter than the root it measured at `:151-152`. The logical
    // height the layout works in is therefore the captured height plus the
    // legend, and all three gauge stories show their legend.
    const legendsHeight = 32.0;

    // Every gauge segment is drawn as `M<outer arc> L <inner arc> Z`, so the
    // arc generator emits the outer radius as the third number of the path and
    // the inner radius as the twelfth (`GaugeChart.tsx:220-225`).
    const outerRadiusIndex = 2;
    const innerRadiusIndex = 11;

    void checkStory(
      String id, {
      required bool hasTitle,
      required bool hasSublabel,
      required Offset expectedOrigin,
    }) {
      final story = loadOracleStory(id);
      final logical = Size(story.width, story.height + legendsHeight);
      final layout = layoutOf(
        logical,
        hasTitle: hasTitle,
        hasSublabel: hasSublabel,
      );

      final root = story.byTag('g').first;
      expectOracleOffset(
        '$id root translate',
        story.absoluteTranslate(root),
        layout.origin,
      );
      expect(
        layout.origin,
        expectedOrigin,
        reason:
            'GaugeChart.tsx:599 against the logical height '
            '${logical.height}, not the captured svg height ${story.height}.',
      );

      final arcs = story.byTag('path').where((path) => path.d != null).toList();
      expect(
        arcs.length,
        greaterThanOrEqualTo(2),
        reason:
            '$id must have captured at least the two segment arcs and the '
            'needle for the radius read below to mean anything.',
      );
      final numbers = svgPathNumbers(arcs.first.d!);
      expect(
        numbers.length,
        greaterThan(innerRadiusIndex),
        reason:
            '$id first segment path is shorter than the M-A-L-A-Z form the '
            'radius indices assume.',
      );
      expectOracleNumber(
        '$id outer radius',
        numbers[outerRadiusIndex],
        layout.outerRadius,
      );
      expectOracleNumber(
        '$id inner radius',
        numbers[innerRadiusIndex],
        layout.innerRadius,
      );

      // The centred chart value is the only `text-anchor: middle` node that
      // sits on the origin's own baseline (`GaugeChart.tsx:640` places it at
      // y = 0); the title sits above it and the sublabel below.
      final value = story
          .byTag('text')
          .where((text) => text.textAnchor == 'middle' && text.y == 0)
          .toList();
      expect(
        value.length,
        1,
        reason: '$id must have captured exactly one centred chart value.',
      );
      expectOracleNumber(
        '$id chart value font size',
        value.single.fontSize,
        layout.chartValueFontSize,
      );
    }

    test('GaugeChartBasic', () {
      checkStory(
        'charts-gaugechart--gauge-chart-basic',
        hasTitle: false,
        hasSublabel: false,
        expectedOrigin: const Offset(126, 80),
      );
    });

    test('GaugeChartResponsive', () {
      checkStory(
        'charts-gaugechart--gauge-chart-responsive',
        hasTitle: false,
        hasSublabel: false,
        expectedOrigin: const Offset(472, 80),
      );
    });

    test('GaugeChartSingleSegment', () {
      checkStory(
        'charts-gaugechart--gauge-chart-single-segment',
        hasTitle: true,
        hasSublabel: true,
        expectedOrigin: const Offset(126, 105),
      );
    });

    test('every captured gauge story is covered', () {
      expect(
        oracleStoryIds(component: 'GaugeChart'),
        <String>[
          'charts-gaugechart--gauge-chart-basic',
          'charts-gaugechart--gauge-chart-responsive',
          'charts-gaugechart--gauge-chart-single-segment',
        ],
        reason:
            'A re-capture that adds a gauge story must add a case above '
            'rather than silently widen the corpus.',
      );
    });

    test('the needle rotation matches every captured rotate()', () {
      // The three stories draw 50%, 75% and 50/100 against a 0..100 gauge.
      const values = <String, double>{
        'charts-gaugechart--gauge-chart-basic': 50,
        'charts-gaugechart--gauge-chart-responsive': 75,
        'charts-gaugechart--gauge-chart-single-segment': 50,
      };
      for (final entry in values.entries) {
        final story = loadOracleStory(entry.key);
        final rotate = story
            .byTag('g')
            .where((group) => (group.transform ?? '').startsWith('rotate('));
        expect(
          rotate.length,
          1,
          reason: '${entry.key} must have captured exactly one needle group.',
        );
        final captured = double.parse(
          RegExp(
            r'rotate\(\s*([-0-9.]+)',
          ).firstMatch(rotate.first.transform!)!.group(1)!,
        );
        expectOracleNumber(
          '${entry.key} needle rotation',
          captured,
          FluentGaugeLayout.needleRotation(entry.value, 0, 100),
        );
      }
    });
  });
}
