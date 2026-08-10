import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/gauge_chart_style.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/oracle_fixture.dart';

/// The outer radius every captured gauge story renders at.
///
/// Read off the `A62,62` command of each segment path rather than hard-coded:
/// see the `arc radii` test, which asserts it against the corpus.
const double _oracleOuterRadius = 62;

/// The inner radius of those same arcs, from their `A50,50` command.
const double _oracleInnerRadius = 50;

/// The two radii of an arc path, largest first.
///
/// `shape_arc` emits `A<r>,<r>,0,<large>,<sweep>,<x>,<y>` for both edges of the
/// band, so the distinct radius arguments of a gauge segment are exactly the
/// outer and the inner radius.
(double, double) _arcRadii(String d) {
  final tokens = tokeniseSvgPath(d);
  final radii = <double>{};
  for (var i = 0; i < tokens.length; i++) {
    if (tokens[i] == 'A') {
      radii.add(double.parse(tokens[i + 1]));
    }
  }
  final sorted = radii.toList()..sort();
  return (sorted.last, sorted.first);
}

List<OracleElement> _segments(OracleStory story) => story.elements
    .where((element) => element.tag == 'path' && (element.d ?? '').isNotEmpty)
    .where((element) => element.strokeWidth == 0)
    .toList();

OracleElement _needle(OracleStory story) =>
    story.soleElement('path', where: (element) => element.strokeWidth > 0);

void main() {
  const states = <WidgetState>{};
  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  test('the six breakpoints are transcribed exactly and in order', () {
    expect(
      kFluentGaugeBreakpoints
          .map((b) => (b.minRadius, b.arcWidth, b.fontSize))
          .toList(),
      const <(double, double, double)>[
        (52, 12, 20),
        (70, 16, 24),
        (88, 20, 32),
        (106, 24, 32),
        (124, 28, 40),
        (142, 32, 40),
      ],
      reason:
          'GaugeChart.tsx:35-42 — the order matters because '
          '_getStylesBasedOnBreakpoint (:167-180) scans from index 5 down to 0 '
          'and takes the first whose minRadius the outer radius reaches.',
    );
  });

  test('the module constants', () {
    final style = resolveFluentGaugeChartStyle(theme);
    expect(
      style.gaugeMargin!.resolve(states),
      16.0,
      reason: 'GaugeChart.tsx:28 — GAUGE_MARGIN.',
    );
    expect(
      style.labelWidth!.resolve(states),
      36.0,
      reason: 'GaugeChart.tsx:29 — LABEL_WIDTH.',
    );
    expect(
      style.labelHeight!.resolve(states),
      16.0,
      reason: 'GaugeChart.tsx:30 — LABEL_HEIGHT.',
    );
    expect(
      style.labelOffset!.resolve(states),
      4.0,
      reason: 'GaugeChart.tsx:31 — LABEL_OFFSET.',
    );
    expect(
      style.titleOffset!.resolve(states),
      11.0,
      reason: 'GaugeChart.tsx:32 — TITLE_OFFSET.',
    );
    expect(
      style.extraNeedleLength!.resolve(states),
      4.0,
      reason: 'GaugeChart.tsx:33 — EXTRA_NEEDLE_LENGTH.',
    );
    expect(
      style.arcPadding!.resolve(states),
      2.0,
      reason:
          'GaugeChart.tsx:34 — ARC_PADDING, exported and reused as the '
          'focus stroke width at :643.',
    );
    expect(
      style.legendsHeight!.resolve(states),
      32.0,
      reason: 'GaugeChart.tsx:119 — 32 unless hideLegend.',
    );
  });

  test('the intrinsic minimum is 140 by 70 before margins', () {
    final style = resolveFluentGaugeChartStyle(theme);
    expect(
      style.intrinsicWidth!.resolve(states),
      140.0,
      reason:
          'GaugeChart.tsx:126 seeds the width state with 140 plus the '
          'left and right margins.',
    );
    expect(
      style.intrinsicHeight!.resolve(states),
      70.0,
      reason:
          'GaugeChart.tsx:127 seeds the height state with 70 plus the top '
          'and bottom margins and the legend height.',
    );
  });

  test('the rounded-corner radius is 3 and the chart-value inset is 24', () {
    final style = resolveFluentGaugeChartStyle(theme);
    expect(
      style.cornerRadius!.resolve(states),
      3.0,
      reason:
          'GaugeChart.tsx:216 — .cornerRadius(roundCorners ? 3 : 0). '
          'Unlike DonutChart this prop is live.',
    );
    expect(
      style.chartValueInset!.resolve(states),
      24.0,
      reason:
          'GaugeChart.tsx:681 — the chart value truncates at '
          'innerRadius * 2 - 24.',
    );
  });

  test('the dimmed opacity is 0.1', () {
    expect(
      resolveFluentGaugeChartStyle(theme).dimmedOpacity!.resolve(states),
      0.1,
      reason:
          'GaugeChart.tsx:646 — a segment that is neither highlighted nor '
          'part of an unhighlighted chart drops to 0.1.',
    );
  });

  test('the needle is foreground1 filled, background1 stroked, 2 wide', () {
    final style = resolveFluentGaugeChartStyle(theme);
    expect(
      style.needleFill!.resolve(states)!.toARGB32(),
      theme.colors.neutralForeground1.toARGB32(),
      reason:
          'useGaugeChartStyles.styles.ts:63 — the needle slot fills with '
          'colorNeutralForeground1.',
    );
    expect(
      style.needleStroke!.resolve(states)!.toARGB32(),
      theme.colors.neutralBackground1.toARGB32(),
      reason:
          'useGaugeChartStyles.styles.ts:64 — the same slot strokes with '
          'colorNeutralBackground1, which is what separates the needle from '
          'the arc beneath it.',
    );
    expect(
      style.needleStrokeWidth!.resolve(states),
      2.0,
      reason:
          'GaugeChart.tsx:251 — strokeWidth is the literal 2, and every '
          'needle path radius derives from halfStrokeWidth.',
    );
  });

  test('the focus indicator is a two-pixel strokeFocus2 outline', () {
    final style = resolveFluentGaugeChartStyle(theme);
    expect(
      style.segmentFocusStrokeColor!.resolve(states)!.toARGB32(),
      theme.colors.strokeFocus2.toARGB32(),
      reason:
          'useGaugeChartStyles.styles.ts:73-76 — the segment slot always sets '
          'the stroke colour; only the width toggles between 0 and '
          'ARC_PADDING at GaugeChart.tsx:643.',
    );
  });

  test('the filler segment gets a real colour rather than upstream black', () {
    expect(
      resolveFluentGaugeChartStyle(
        theme,
      ).unknownSegmentColor!.resolve(states)!.toARGB32(),
      theme.colors.neutralBackground4.toARGB32(),
      reason:
          'GaugeChart.tsx:208 sets the auto-appended Unknown segment to '
          "the raw string 'neutralLight', which never goes through "
          'getColorFromToken and is not a legal CSS colour, so the browser '
          'falls back to black. A black filler on a dark theme is invisible, '
          'so the port resolves a real token and documents the divergence.',
    );
  });

  test('merge, copyWith and from layer without dropping a field', () {
    final base = resolveFluentGaugeChartStyle(theme);
    expect(
      base.merge(null),
      same(base),
      reason: 'A null overlay is the identity, as in badge_style.dart.',
    );
    expect(
      base.copyWith(),
      base,
      reason:
          'An empty copyWith must round-trip through all 22 fields, so a '
          'field missing from merge or _fields would show up here.',
    );
    expect(
      base.copyWith().hashCode,
      base.hashCode,
      reason: 'Object.hashAll over the same 22 fields.',
    );
    final overlaid = base.merge(FluentGaugeChartStyle.from(gaugeMargin: 99));
    expect(
      overlaid.gaugeMargin!.resolve(states),
      99.0,
      reason: 'The overlay wins where it is non-null.',
    );
    expect(
      overlaid.labelWidth!.resolve(states),
      base.labelWidth!.resolve(states),
      reason: 'And loses where it is null.',
    );
    expect(
      overlaid == base,
      isFalse,
      reason: 'One differing field is enough to break equality.',
    );
  });

  group('the captured gauge stories', () {
    test('the corpus holds the three stories these tests read', () {
      expect(
        oracleStoryIds(component: 'GaugeChart'),
        containsAll(<String>[
          'charts-gaugechart--gauge-chart-basic',
          'charts-gaugechart--gauge-chart-single-segment',
          'charts-gaugechart--gauge-chart-responsive',
        ]),
        reason:
            'Every assertion below indexes one of these by id, so a renamed '
            'or dropped fixture must fail loudly rather than silently skip.',
      );
    });

    test('arc radii pin the first breakpoint row', () {
      final story = loadOracleStory('charts-gaugechart--gauge-chart-basic');
      final segments = _segments(story);
      expect(
        segments.length,
        3,
        reason:
            'The basic story renders three segments; a zero count would make '
            'the loop below vacuous.',
      );
      for (final segment in segments) {
        final (outer, inner) = _arcRadii(segment.d!);
        expectOracleNumber('outer radius', _oracleOuterRadius, outer);
        expectOracleNumber('inner radius', _oracleInnerRadius, inner);
      }
      final breakpoint = kFluentGaugeBreakpoints.first;
      expect(
        breakpoint.minRadius <= _oracleOuterRadius &&
            kFluentGaugeBreakpoints[1].minRadius > _oracleOuterRadius,
        isTrue,
        reason:
            'GaugeChart.tsx:167-180 scans downwards, so a 62px outer radius '
            'stops on row 0 (52 <= 62 < 70).',
      );
      expect(
        breakpoint.arcWidth,
        _oracleOuterRadius - _oracleInnerRadius,
        reason:
            'Row 0 supplies arcWidth 12, and the corpus band is exactly '
            '62 - 50.',
      );
      expect(
        story.soleElement('text', where: (e) => e.text == '50%').fontSize,
        breakpoint.fontSize,
        reason:
            'GaugeChart.tsx:678 sets the chart value font size from the same '
            'row, and the corpus renders it at 20px.',
      );
    });

    test('the pad offset is half of arcPadding at both edges', () {
      final story = loadOracleStory('charts-gaugechart--gauge-chart-basic');
      final padding = resolveFluentGaugeChartStyle(
        theme,
      ).arcPadding!.resolve(states)!;
      // GaugeChart.tsx:217-218 sets padAngle to ARC_PADDING / outerRadius with
      // padRadius = outerRadius, so the linear gap is ARC_PADDING, split half
      // to each neighbour. The first and last segment abut the horizontal
      // diameter, so their y ordinate there is exactly -padding / 2.
      final first = _segments(story).first;
      final numbers = svgPathNumbers(first.d!);
      expectOracleNumber(
        'pad offset at the outer edge',
        -padding / 2,
        numbers[1],
      );
      expect(
        numbers[0].abs() < _oracleOuterRadius,
        isTrue,
        reason:
            'The x ordinate is pulled inside the outer radius by the same pad, '
            'so it must be under 62 — it reads ${numbers[0]}.',
      );
    });

    test('the needle geometry pins strokeWidth 2 and extraNeedleLength 4', () {
      final story = loadOracleStory('charts-gaugechart--gauge-chart-basic');
      final needle = _needle(story);
      final style = resolveFluentGaugeChartStyle(theme);
      final strokeWidth = style.needleStrokeWidth!.resolve(states)!;
      expectOracleNumber(
        'needle stroke width',
        strokeWidth,
        needle.strokeWidth,
      );
      expectOracleColour(
        'needle fill',
        style.needleFill!.resolve(states),
        needle.fill,
      );
      expectOracleColour(
        'needle stroke',
        style.needleStroke!.resolve(states),
        needle.stroke,
      );
      final numbers = svgPathNumbers(needle.d!);
      // GaugeChart.tsx:259-263 — the path opens at `M 0,-halfStrokeWidth - 3`
      // and runs back to `L -needleLength, ...`, with needleLength defined at
      // :253 as outerRadius - innerRadius + EXTRA_NEEDLE_LENGTH.
      expectOracleNumber(
        'needle tip ordinate',
        -strokeWidth / 2 - 3,
        numbers[1],
      );
      expectOracleNumber(
        'needle length',
        -(_oracleOuterRadius -
            _oracleInnerRadius +
            style.extraNeedleLength!.resolve(states)!),
        numbers[2],
      );
    });

    test(
      'the untitled gauge margins pin gaugeMargin and extraNeedleLength',
      () {
        final story = loadOracleStory('charts-gaugechart--gauge-chart-basic');
        final style = resolveFluentGaugeChartStyle(theme);
        final margin = style.gaugeMargin!.resolve(states)!;
        final centre = story.absoluteTranslate(story.elements.first);
        // GaugeChart.tsx:112-115 — no title, no sublabel, min/max shown.
        expectOracleNumber('bottom margin', margin, story.height - centre.dy);
        expectOracleNumber(
          'top margin',
          margin + style.extraNeedleLength!.resolve(states)! / 2,
          centre.dy - _oracleOuterRadius,
        );
        expectOracleNumber(
          'left margin',
          margin +
              style.labelOffset!.resolve(states)! +
              style.labelWidth!.resolve(states)!,
          centre.dx - style.intrinsicWidth!.resolve(states)! / 2,
        );
        expectOracleNumber(
          'seeded width',
          style.intrinsicWidth!.resolve(states)! +
              2 *
                  (margin +
                      style.labelOffset!.resolve(states)! +
                      style.labelWidth!.resolve(states)!),
          story.width,
        );
      },
    );

    test('the min and max labels sit labelOffset beyond the arc', () {
      final story = loadOracleStory('charts-gaugechart--gauge-chart-basic');
      final style = resolveFluentGaugeChartStyle(theme);
      final offset = style.labelOffset!.resolve(states)!;
      final max = story.soleElement('text', where: (e) => e.text == '100');
      expectOracleNumber('max label x', _oracleOuterRadius + offset, max.x!);
      expectOracleNumber(
        'limits font size',
        style.limitsTextStyle!.resolve(states)!.fontSize!,
        max.fontSize,
      );
      expectOracleColour(
        'limits fill',
        style.limitsTextStyle!.resolve(states)!.color,
        max.fill,
      );
    });

    test('a titled, sublabelled gauge pins titleOffset and labelHeight', () {
      final story = loadOracleStory(
        'charts-gaugechart--gauge-chart-single-segment',
      );
      final style = resolveFluentGaugeChartStyle(theme);
      final margin = style.gaugeMargin!.resolve(states)!;
      final labelHeight = style.labelHeight!.resolve(states)!;
      final labelOffset = style.labelOffset!.resolve(states)!;
      final titleOffset = style.titleOffset!.resolve(states)!;
      final centre = story.absoluteTranslate(story.elements.first);
      // GaugeChart.tsx:114-115 with both chartTitle and sublabel supplied.
      expectOracleNumber(
        'top margin',
        margin + titleOffset + labelHeight,
        centre.dy - _oracleOuterRadius,
      );
      expectOracleNumber(
        'bottom margin',
        margin + labelOffset + labelHeight,
        story.height - centre.dy,
      );
      final title = story.soleElement(
        'text',
        where: (e) => e.text == 'Storage capacity',
      );
      expectOracleNumber(
        'title ordinate',
        -(_oracleOuterRadius + titleOffset),
        title.y!,
      );
      expectOracleNumber(
        'title font size',
        style.titleTextStyle!.resolve(states)!.fontSize!,
        title.fontSize,
      );
      final sublabel = story.soleElement(
        'text',
        where: (e) => e.text == 'used',
      );
      expectOracleNumber('sublabel ordinate', labelOffset, sublabel.y!);
      expectOracleNumber(
        'sublabel font size',
        style.sublabelTextStyle!.resolve(states)!.fontSize!,
        sublabel.fontSize,
      );
    });

    test('every captured legend strip is exactly legendsHeight tall', () {
      final height = resolveFluentGaugeChartStyle(
        theme,
      ).legendsHeight!.resolve(states)!;
      final ids = oracleStoryIds(component: 'GaugeChart');
      expect(
        ids.length,
        3,
        reason: 'A zero count would make the loop below vacuous.',
      );
      for (final id in ids) {
        final legends = loadOracleStory(id).boxes('fui-legend__root');
        expect(
          legends.length,
          1,
          reason: '$id renders one legend strip; none would prove nothing.',
        );
        expectOracleNumber(
          '$id legend height',
          height,
          legends.single.rect.height,
        );
      }
    });
  });
}
