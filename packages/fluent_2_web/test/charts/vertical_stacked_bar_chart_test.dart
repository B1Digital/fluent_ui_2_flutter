import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/cartesian/cartesian_chart.dart';
import 'package:fluent_2_web/src/charts/cartesian/cartesian_chart_props.dart';
import 'package:fluent_2_web/src/charts/cartesian/cartesian_layout.dart';
import 'package:fluent_2_web/src/charts/cartesian/cartesian_series_delegate.dart';
import 'package:fluent_2_web/src/charts/internal/chart_colors.dart';
import 'package:fluent_2_web/src/charts/internal/chart_text_measurer.dart';
import 'package:fluent_2_web/src/charts/internal/chart_text_styles.dart';
import 'package:fluent_2_web/src/charts/internal/chart_utils.dart';
import 'package:fluent_2_web/src/charts/internal/d3/scale.dart';
import 'package:fluent_2_web/src/charts/internal/d3/scale_band.dart';
import 'package:fluent_2_web/src/charts/internal/d3/scale_linear.dart';
import 'package:fluent_2_web/src/charts/internal/data_viz_palette.dart';
import 'package:fluent_2_web/src/charts/model/bar_data.dart';
import 'package:fluent_2_web/src/charts/model/chart_common.dart';
import 'package:fluent_2_web/src/charts/model/chart_value.dart';
import 'package:fluent_2_web/src/charts/model/line_options.dart';
import 'package:fluent_2_web/src/charts/vertical_stacked_bar_chart.dart';
import 'package:fluent_2_web/src/charts/vertical_stacked_bar_chart_style.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/oracle_fixture.dart';

/// The captured bar width of every VerticalStackedBarChart story, which is also
/// the `minBarLabelWidth` threshold (`VerticalStackedBarChart.tsx:1200`).
const double _kOracleBarWidth = 16;

/// `barGapMax` as the captured stories were rendered with it — every adjacent
/// pair of segments in them is exactly 2px apart.
const double _kOracleBarGapMax = 2;

/// `lineOptions.lineBorderWidth` as the secondary-y-axis story was rendered
/// with it.
///
/// Hand-derived, because no story source was captured: the halo's stroke width
/// is `3 + lineBorderWidth * 2` (`VerticalStackedBarChart.tsx:601`) and the
/// capture's border lines are 7px, so the prop can only have been 2.
const double _kOracleLineBorderWidth = 2;

/// The segment rects of [story], grouped by their `x` and ordered top-down
/// within each group.
List<List<OracleElement>> _oracleStacks(OracleStory story) {
  final byX = <double, List<OracleElement>>{};
  for (final rect in story.byTag('rect')) {
    if (rect.width != _kOracleBarWidth) {
      continue;
    }
    byX.putIfAbsent(rect.x!, () => <OracleElement>[]).add(rect);
  }
  expect(
    byX,
    isNotEmpty,
    reason:
        '${story.id} captured no ${_kOracleBarWidth}px-wide rect, so the loop '
        'below would assert nothing',
  );
  final xs = byX.keys.toList()..sort();
  return <List<OracleElement>>[
    for (final x in xs) byX[x]!..sort((a, b) => a.y!.compareTo(b.y!)),
  ];
}

/// A y scale whose pixel span between `0` and `100` is exactly [span], which is
/// what `_getBarGapAndScale` measures at `VerticalStackedBarChart.tsx:827-828`.
Scale _magnitudeScale({required List<double> domain, required double span}) =>
    scaleLinear()
      ..domainOf(domain)
      // A y range runs top-down, so the larger domain value maps to 0.
      ..rangeOf(<double>[span, 0]);

Scale _bandScale({
  required List<String> domain,
  required List<double> range,
  required double innerPadding,
  required double outerPadding,
}) => scaleBand()
  ..domainOf(domain)
  ..rangeOf(range)
  ..paddingInner(innerPadding)
  ..paddingOuter(outerPadding);

List<FluentStackedBarDatum> _segments(List<double> values) =>
    <FluentStackedBarDatum>[
      for (final (int i, double v) in values.indexed)
        FluentStackedBarDatum(data: v, legend: 'series $i'),
    ];

List<FluentStackedBarDatum> _stringSegments(List<String> values) =>
    <FluentStackedBarDatum>[
      for (final (int i, String v) in values.indexed)
        FluentStackedBarDatum(data: v, legend: 'series $i'),
    ];

void main() {
  group('computeFluentStackedBarGapMetrics', () {
    final yBarScale = _magnitudeScale(domain: <double>[0, 100], span: 295);

    test('a clean stack keeps scalingRatio at exactly 1', () {
      final m = computeFluentStackedBarGapMetrics(
        bars: _segments(<double>[1, 1, 98]),
        yBarScale: yBarScale,
        isStringYAxis: false,
        barGapMax: 4,
      );
      expect(m.absStackTotal, 100, reason: 'totalData is the sum of |data|');
      expect(
        m.gapHeight,
        4,
        reason:
            'min(barGapMax 4, 295 * 0.2 / 2 = 29.5) == 4, '
            'VerticalStackedBarChart.tsx:839',
      );
      expect(
        m.heightValueScale,
        closeTo((295 - 4 * 2) / 100, 1e-9),
        reason:
            '(totalHeight - gapHeight * gaps) / (totalData * scalingRatio), '
            'VerticalStackedBarChart.tsx:840-841',
      );
    });

    test('the one-percent floor inflates scalingRatio above 1', () {
      final m = computeFluentStackedBarGapMetrics(
        bars: _segments(<double>[0.5, 0.5, 99]),
        yBarScale: yBarScale,
        isStringYAxis: false,
        barGapMax: 0,
      );
      // percentages 0.5, 0.5, 99 floor to 1, 1, 99 -> sumOfPercent 101
      expect(
        m.heightValueScale,
        closeTo(295 / (100 * 1.01), 1e-9),
        reason:
            'each value below 1% is raised to 1 BEFORE summing, '
            'VerticalStackedBarChart.tsx:829-835',
      );
    });

    test('a zero percentage is left alone by the floor', () {
      final m = computeFluentStackedBarGapMetrics(
        bars: _segments(<double>[0, 100]),
        yBarScale: yBarScale,
        isStringYAxis: false,
        barGapMax: 0,
      );
      expect(
        m.heightValueScale,
        closeTo(295 / 100, 1e-9),
        reason: 'the guard is `v < 1 && v !== 0`, so 0 stays 0 at :831',
      );
    });

    test('barGapMax 0 disables gaps entirely', () {
      final m = computeFluentStackedBarGapMetrics(
        bars: _segments(<double>[50, 50]),
        yBarScale: yBarScale,
        isStringYAxis: false,
        barGapMax: 0,
      );
      expect(
        m.gapHeight,
        0,
        reason:
            '`gaps = barGapMax && bars.length - 1` is 0 when barGapMax is '
            '0, VerticalStackedBarChart.tsx:838',
      );
    });

    test('a tiny stack falls back to the 1px minimum gap', () {
      final ten = _magnitudeScale(domain: <double>[0, 100], span: 10);
      expect(
        computeFluentStackedBarGapMetrics(
          bars: _segments(<double>[50, 50]),
          yBarScale: ten,
          isStringYAxis: false,
          barGapMax: 4,
        ).gapHeight,
        2,
        reason:
            'max(barGapMin 1, min(4, 10 * 0.2 / 1 = 2)) — the 2 wins at :839',
      );
      final two = _magnitudeScale(domain: <double>[0, 100], span: 2);
      expect(
        computeFluentStackedBarGapMetrics(
          bars: _segments(<double>[50, 50]),
          yBarScale: two,
          isStringYAxis: false,
          barGapMax: 4,
        ).gapHeight,
        1,
        reason:
            'min(4, 2 * 0.2 / 1 = 0.4) is below barGapMin, so the 1px floor '
            'at :839 wins',
      );
    });

    test('a string y axis sums scaled positions and zeroes the scale', () {
      final band = _bandScale(
        domain: <String>['', 'low', 'mid', 'high'],
        range: <double>[315, 20],
        innerPadding: 1,
        outerPadding: 0,
      );
      final m = computeFluentStackedBarGapMetrics(
        bars: _stringSegments(<String>['low', 'mid']),
        yBarScale: band,
        isStringYAxis: true,
        barGapMax: 0,
      );
      expect(
        m.heightValueScale,
        0,
        reason: 'the string branch returns 0, VerticalStackedBarChart.tsx:841',
      );
      expect(
        m.absStackTotal,
        0,
        reason: 'totalData is never accumulated on the string path, :820-822',
      );
    });

    test('a defaultTotalHeight overrides the measured span', () {
      final m = computeFluentStackedBarGapMetrics(
        bars: _segments(<double>[50, 50]),
        yBarScale: yBarScale,
        isStringYAxis: false,
        barGapMax: 4,
        defaultTotalHeight: 40,
      );
      expect(
        m.heightValueScale,
        closeTo((40 - 4) / 100, 1e-9),
        reason:
            'the `defaultTotalHeight ??` arm at :827 replaces the measured '
            'span, and the single gap is still deducted from it',
      );
    });
  });

  group('Oracle B — charts-verticalstackedbarchart--vertical-stacked-bar-*', () {
    test('every captured segment gap is the 2px the port computes', () {
      final story = loadOracleStory(
        'charts-verticalstackedbarchart--vertical-stacked-bar-default',
      );
      // Unused by the gap arm once defaultTotalHeight is supplied, but the
      // parameter is required because the numeric branch measures through it.
      final unused = _magnitudeScale(domain: <double>[0, 100], span: 295);
      final stacks = _oracleStacks(story);
      expect(stacks.length, 6, reason: 'the default story draws six stacks');
      var gapsChecked = 0;
      for (final stack in stacks) {
        for (var i = 0; i < stack.length - 1; i++) {
          expectOracleNumber(
            '${story.id} gap below segment $i',
            _kOracleBarGapMax,
            stack[i + 1].y! - (stack[i].y! + stack[i].height!),
          );
          gapsChecked++;
        }
        // The stack's full extent, which is what `_getBarGapAndScale` measures
        // through the y scale at `VerticalStackedBarChart.tsx:827-828`.
        final extent = stack.last.y! + stack.last.height! - stack.first.y!;
        expectOracleNumber(
          '${story.id} gapHeight for a ${stack.length}-segment stack',
          _kOracleBarGapMax,
          computeFluentStackedBarGapMetrics(
            bars: _segments(List<double>.filled(stack.length, 1)),
            yBarScale: unused,
            isStringYAxis: false,
            barGapMax: _kOracleBarGapMax,
            defaultTotalHeight: extent,
          ).gapHeight,
        );
        expect(
          extent * kBarGapMultiplier / (stack.length - 1),
          greaterThan(_kOracleBarGapMax),
          reason:
              'the barGapMultiplier arm at :839 must not be the binding one '
              'here, otherwise the assertion above would pass for the wrong '
              'reason',
        );
      }
      expect(
        gapsChecked,
        33,
        reason: 'six stacks of 10, 3, 3, 10, 3 and 10 segments — 33 gaps',
      );
    });

    test('a stack-total label clears the stack by 6 above and 12 below', () {
      final positive = loadOracleStory(
        'charts-verticalstackedbarchart--vertical-stacked-bar-default',
      );
      final style = resolveFluentVerticalStackedBarChartStyle(
        FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      );
      final above = style.barLabelGapAbove!.resolve(<WidgetState>{})!;
      var labelsChecked = 0;
      for (final stack in _oracleStacks(positive)) {
        final label = positive.soleElement(
          'text',
          where: (e) => e.x == stack.first.x! + _kOracleBarWidth / 2,
        );
        expectOracleNumber(
          '${positive.id} label baseline above the stack',
          stack.first.y! - above,
          label.y!,
        );
        labelsChecked++;
      }
      expect(labelsChecked, 6, reason: 'one label per stack');

      // The only captured stack whose total is negative, so the only one that
      // exercises the `yPoint + heightOfLastBar + 12` arm at :1204.
      final negative = loadOracleStory(
        'charts-verticalstackedbarchart--vertical-stacked-bar-negative',
      );
      final below = style.barLabelGapBelow!.resolve(<WidgetState>{})!;
      final stack = _oracleStacks(negative)[1];
      final label = negative.soleElement(
        'text',
        where: (e) => e.x == stack.first.x! + _kOracleBarWidth / 2,
      );
      expect(
        label.text,
        '−90',
        reason: 'the second stack of the negative story totals -90',
      );
      expectOracleNumber(
        '${negative.id} label baseline below the stack',
        stack.last.y! + stack.last.height! + below,
        label.y!,
      );
    });
  });

  group('resolveFluentVerticalStackedBarChartStyle', () {
    const rest = <WidgetState>{};
    final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
    final style = resolveFluentVerticalStackedBarChartStyle(theme);

    test('a dimmed segment is exactly one tenth opaque', () {
      expect(
        style.barOpacity!.resolve(rest),
        1.0,
        reason: 'VerticalStackedBarChart.tsx:1101 is `shouldHighlight ? 1 : …`',
      );
      expect(
        style.barOpacity!.resolve(<WidgetState>{WidgetState.disabled}),
        0.1,
        reason: 'VerticalStackedBarChart.tsx:1101 dims to 0.1',
      );
    });

    test('the rounded-corner radius is 3 and the stack radius 0', () {
      expect(
        style.barCornerRadius!.resolve(rest),
        3.0,
        reason: '`rx = props.roundCorners ? 3 : 0`, :1102',
      );
      expect(
        style.stackCornerRadius!.resolve(rest),
        0.0,
        reason: '`const { barCornerRadius = 0 } = props`, :986',
      );
      expect(
        style.barMinimumHeight!.resolve(rest),
        0.0,
        reason: '`const { barMinimumHeight = 0 } = props`, :986',
      );
      expect(
        style.barGapMax!.resolve(rest),
        0.0,
        reason: '`const { barGapMax = 0 } = props`, :815',
      );
    });

    test('the bar label gaps straddle the stack', () {
      expect(
        style.barLabelGapAbove!.resolve(rest),
        6.0,
        reason: 'a non-negative total labels at `yPoint - 6`, :1204',
      );
      expect(
        style.barLabelGapBelow!.resolve(rest),
        12.0,
        reason: 'a negative total labels at `… + heightOfLastBar + 12`, :1204',
      );
      expect(
        style.minBarLabelWidth!.resolve(rest),
        16.0,
        reason: '`_barWidth >= 16` gates the label, :1200',
      );
      expect(
        style.barLabelStyle!.resolve(rest),
        theme.typography.caption1Strong.copyWith(
          color: theme.colors.neutralForeground1,
        ),
        reason: 'getBarLabelStyle, utilities/Common.styles.ts:64-70',
      );
    });

    test('the line palette is the five DataViz tokens in upstream order', () {
      expect(
        style.linePalette!.resolve(rest),
        <Color>[
          FluentDataVizPalette.resolve(FluentDataVizToken.color6),
          FluentDataVizPalette.resolve(FluentDataVizToken.color1),
          FluentDataVizPalette.resolve(FluentDataVizToken.color5),
          FluentDataVizPalette.resolve(FluentDataVizToken.color7),
          FluentDataVizPalette.resolve(FluentDataVizToken.color10),
        ],
        reason:
            'color6, color1, color5, color7, color10 — not sorted, '
            'VerticalStackedBarChart.tsx:316-322',
      );
    });

    test('the line dot radius is 8 on the active x and 0.3 elsewhere', () {
      expect(
        style.lineDotRadius!.resolve(<WidgetState>{WidgetState.hovered}),
        8.0,
        reason: 'the active x returns `{ opacity: 1, radius: 8 }`, :687',
      );
      expect(
        style.lineDotRadius!.resolve(rest),
        0.3,
        reason:
            'a highlighted but inactive x keeps r 0.3 so it stays '
            'focusable, :689',
      );
      expect(
        style.lineStrokeWidth!.resolve(rest),
        3.0,
        reason: '`strokeWidth={… ?? 3}`, :617',
      );
      expect(
        style.lineDotStrokeWidth!.resolve(rest),
        3.0,
        reason: 'the dot is stroked at 3, :649',
      );
      expect(
        style.lineDotFillColor!.resolve(rest),
        theme.colors.neutralBackground1,
        reason: '`fill={tokens.colorNeutralBackground1}`, :648',
      );
    });

    test('merge, copyWith, from and equality follow the house template', () {
      const overlay = FluentVerticalStackedBarChartStyle(
        lineStrokeWidth: WidgetStatePropertyAll<double?>(9),
      );
      expect(
        style.merge(overlay).lineStrokeWidth!.resolve(rest),
        9.0,
        reason: 'merge layers the non-null properties of the argument on top',
      );
      expect(
        style.merge(overlay).barCornerRadius,
        style.barCornerRadius,
        reason: 'a null property in the overlay inherits',
      );
      expect(style.merge(null), style, reason: 'merging null is the identity');
      expect(
        FluentVerticalStackedBarChartStyle.from(lineStrokeWidth: 9),
        overlay,
        reason: '`from` wraps each value in a WidgetStatePropertyAll',
      );
      expect(
        FluentVerticalStackedBarChartStyle.from(lineStrokeWidth: 9).hashCode,
        overlay.hashCode,
        reason: 'equal styles hash equally',
      );
      expect(
        style.copyWith(lineStrokeWidth: overlay.lineStrokeWidth),
        style.merge(overlay),
        reason: 'copyWith of one property matches merging that property',
      );
    });
  });

  group('VSBC numeric stacking', () {
    test('the running heights and gaps land on the expected pixels', () {
      final d = _vsbcDelegate(
        stacks: <List<double>>[
          <double>[1, 1, 98],
        ],
        barGapMax: 4,
        yMax: 100,
      );
      final segs = d.segmentsFor(_vsbcContext(), _layout(height: 350));
      // heightValueScale == (295 - 8) / 100 == 2.87. The tolerance is there
      // because `yBarScale(100)` lands a few ulps off 295, not because the
      // expectation is approximate.
      expect(
        segs.map((s) => s.rect.height).toList(),
        <Matcher>[
          closeTo(2.87, 1e-9),
          closeTo(2.87, 1e-9),
          closeTo(281.26, 1e-9),
        ],
        reason:
            'barHeight = |heightValueScale * data|, '
            'VerticalStackedBarChart.tsx:1068',
      );
      expect(
        segs.last.rect.top,
        closeTo(315 - 2.87 - 2.87 - 4 - 281.26 - 4, 1e-6),
        reason:
            'yPositiveStart -= barHeight + gapOffset for each segment, '
            'VerticalStackedBarChart.tsx:1074-1076',
      );
    });

    test('a segment below the stack minimum is raised', () {
      final d = _vsbcDelegate(
        stacks: <List<double>>[
          <double>[0.1, 99.9],
        ],
        barGapMax: 0,
        yMax: 100,
      );
      final segs = d.segmentsFor(_vsbcContext(), _layout(height: 350));
      expect(
        segs.first.rect.height,
        greaterThanOrEqualTo(2.9),
        reason:
            'minHeight = max(heightValueScale * absStackTotal / 100, '
            'barMinimumHeight) lifts a 0.1-unit segment, '
            'VerticalStackedBarChart.tsx:1070',
      );
      expect(
        segs.first.rect.height,
        closeTo(295 / 1.009 / 100, 1e-9),
        reason:
            'the one-percent floor has already inflated scalingRatio to '
            '1.009, so the minimum is 295 / 1.009 / 100',
      );
    });

    test('a zero or empty-string segment is filtered out of the stack', () {
      final d = _vsbcDelegate(
        stacks: <List<double>>[
          <double>[0, 50, 50],
        ],
        barGapMax: 0,
        yMax: 100,
      );
      expect(
        d.segmentsFor(_vsbcContext(), _layout(height: 350)).length,
        2,
        reason:
            "barsToDisplay filters data !== 0 && data !== '' at "
            'VerticalStackedBarChart.tsx:1006-1014',
      );
    });

    test('a stack with nothing to display is skipped entirely', () {
      final d = _vsbcDelegate(
        stacks: <List<double>>[
          <double>[0, 0],
          <double>[50],
        ],
        barGapMax: 0,
        yMax: 100,
      );
      expect(
        d
            .segmentsFor(_vsbcContext(), _layout(height: 350))
            .map((s) => s.stackIndex)
            .toSet(),
        <int>{1},
        reason: 'the whole stack returns undefined and is filtered at :1222',
      );
    });

    test('a negative segment grows downwards from the baseline', () {
      final d = _vsbcDelegate(
        stacks: <List<double>>[
          <double>[-50],
        ],
        barGapMax: 0,
        yMax: 0,
        yMin: -50,
      );
      final seg = d.segmentsFor(_vsbcContext(), _layout(height: 350)).single;
      expect(
        seg.rect.top,
        closeTo(315 - 295, 1e-9),
        reason:
            'the domain is [-50, 0], so yBarScale(0) is the full 295 and the '
            'baseline sits at the plot ceiling, '
            'VerticalStackedBarChart.tsx:1026-1029',
      );
      expect(
        seg.rect.height,
        closeTo(295, 1e-9),
        reason:
            'yPoint = yNegativeStart + gapOffset then yNegativeStart = yPoint '
            '+ barHeight, VerticalStackedBarChart.tsx:1078-1079',
      );
    });

    test('a dimmed segment resolves the disabled opacity', () {
      final d = _vsbcDelegate(
        stacks: <List<double>>[
          <double>[50, 50],
        ],
        barGapMax: 0,
        yMax: 100,
        selectedLegends: <String>['series 1'],
      );
      expect(
        d
            .segmentsFor(_vsbcContext(), _layout(height: 350))
            .map((s) => s.opacity)
            .toList(),
        <double>[0.1, 1.0],
        reason:
            'opacity={shouldHighlight ? 1 : 0.1}, '
            'VerticalStackedBarChart.tsx:1101',
      );
    });

    test('segment colours cycle the five-token palette by stack position', () {
      final d = _vsbcDelegate(
        stacks: <List<double>>[
          <double>[10, 10, 10, 10, 10, 10],
        ],
        barGapMax: 0,
        yMax: 100,
      );
      final segs = d.segmentsFor(_vsbcContext(), _layout(height: 350));
      expect(
        segs[5].colour.toARGB32(),
        segs[0].colour.toARGB32(),
        reason:
            'ponytail: upstream `_colors[index]` is undefined for a sixth '
            'segment (VerticalStackedBarChart.tsx:316-322); the port wraps at '
            'index % 5 so the bar is never unpainted',
      );
      expect(
        segs.take(5).map((s) => s.colour.toARGB32()).toList(),
        _palette.map((c) => c.toARGB32()).toList(),
        reason: 'the first five take the five tokens in upstream order',
      );
    });

    test('the palette index is deterministic across renders', () {
      const datum = FluentStackedBarDatum(data: 1, legend: 'series 0');
      final d = _vsbcDelegate(
        stacks: <List<double>>[
          <double>[10, 10],
        ],
        barGapMax: 0,
        yMax: 100,
      );
      expect(
        <int>{
          for (var i = 0; i < 8; i++)
            d.segmentPaletteColour(datum, 1).toARGB32(),
        },
        <int>{_palette[1].toARGB32()},
        reason:
            'ponytail: VerticalStackedBarChart.tsx:167 re-rolls '
            '`defaultPalette[Math.floor(Math.random() * 4 + 1)]` on every '
            'render, which no golden can pin; the port indexes by position',
      );
      expect(
        d.segmentPaletteColour(datum, 0).toARGB32(),
        _palette[0].toARGB32(),
        reason:
            'ponytail: `Math.random() * 4 + 1` can never yield 0, so upstream '
            'never shows the first token in a legend swatch',
      );
      expect(
        d.segmentsFor(_vsbcContext(), _layout(height: 350)).first.colour,
        d.segmentPaletteColour(datum, 0),
        reason: 'the marks and the legend read one rule, not two',
      );
    });

    test('a mark flattens under high contrast while the legend does not', () {
      final contrast = _vsbcDelegate(
        stacks: <List<double>>[
          <double>[50, 50],
        ],
        barGapMax: 0,
        yMax: 100,
        isHighContrast: true,
      );
      const datum = FluentStackedBarDatum(data: 50, legend: 'series 0');
      expect(
        contrast
            .segmentsFor(_vsbcContext(), _layout(height: 350))
            .map((s) => s.colour)
            .toSet(),
        <Color>{_canvasText},
        reason:
            'spec section 5.3 — every mark fill routes through flattenMark, '
            'so forced colours collapse the palette to the system foreground',
      );
      expect(
        contrast.segmentPaletteColour(datum, 0),
        _palette[0],
        reason: 'the legend keeps its palette, spec section 5.3',
      );
    });
  });

  group('VSBC rounded top', () {
    test('the last segment gets an arc path when the radius fits', () {
      final p = FluentVerticalStackedBarChartDelegate.roundedTopPath(
        x: 100,
        y: 200,
        width: 24,
        height: 40,
        radius: 6,
      );
      expect(
        p.getBounds(),
        const Rect.fromLTWH(100, 200, 24, 40),
        reason:
            'the six verbs at VerticalStackedBarChart.tsx:1092-1098 close '
            'exactly on the rect',
      );
      expect(
        p.contains(const Offset(100.5, 200.5)),
        isFalse,
        reason: 'the top-left corner is cut away by the first arc, :1092-1093',
      );
      expect(
        p.contains(const Offset(101, 239)),
        isTrue,
        reason: 'the bottom-left corner is square, :1096-1097',
      );
    });

    test('the last segment of a stack carries the arc', () {
      final d = _vsbcDelegate(
        stacks: <List<double>>[
          <double>[50, 50],
        ],
        barGapMax: 0,
        yMax: 100,
        barCornerRadius: 6,
      );
      final segs = d.segmentsFor(_vsbcContext(), _layout(height: 350));
      expect(
        <bool>[for (final s in segs) s.roundedTopPath != null],
        <bool>[false, true],
        reason:
            'the guard ends with `index === barsToDisplay.length - 1`, '
            'VerticalStackedBarChart.tsx:1086',
      );
      expect(
        segs.last.roundedTopPath!.getBounds(),
        // Path bounds are float32, so the epsilon is the storage width and not
        // a slack in the geometry.
        rectMoreOrLessEquals(segs.last.rect, epsilon: 1e-4),
        reason: 'the arc path spans exactly the segment it replaces',
      );
    });

    test('no arc path when the radius exceeds the segment height', () {
      final d = _vsbcDelegate(
        stacks: <List<double>>[
          <double>[100, 0.5],
        ],
        barGapMax: 0,
        yMax: 100,
        barCornerRadius: 20,
      );
      expect(
        d.segmentsFor(_vsbcContext(), _layout(height: 350)).last.roundedTopPath,
        isNull,
        reason:
            'the guard is barCornerRadius && barHeight > barCornerRadius, '
            'VerticalStackedBarChart.tsx:1086',
      );
    });
  });

  group(
    'Oracle B — charts-verticalstackedbarchart--vertical-stacked-bar-default '
    'segment placement',
    () {
      test('a numeric-axis segment is drawn half a bar left of its x', () {
        final story = loadOracleStory(
          'charts-verticalstackedbarchart--vertical-stacked-bar-default',
        );
        final barWidth = getBarWidth(null, 24);
        expect(
          barWidth,
          _kOracleBarWidth,
          reason:
              'the story passes no barWidth, so getBarWidth falls to '
              'min(DEFAULT_BAR_WIDTH, DEFAULT_BAR_WIDTH), utilities.ts:1906',
        );
        final stacks = _oracleStacks(story);
        expect(stacks.length, 6, reason: 'the default story draws six stacks');
        // Every captured segment carries `transform="translate(-8, 0)"`, so the
        // rect's own `x` is the unshifted `xBarScale(xAxisPoint)`.
        final xValues = <Object>[for (final stack in stacks) stack.first.x!];
        final delegate = _vsbcDelegate(
          stacks: <List<double>>[
            for (final _ in stacks) <double>[50],
          ],
          barGapMax: 0,
          yMax: 50,
          xPoints: xValues,
        );
        expect(
          delegate.xAxisType,
          FluentChartAxisType.numeric,
          reason:
              'a numeric xAxisPoint takes the `-_barWidth / 2` arm at :1003',
        );
        // An identity scale, so the delegate's translate is the only thing that
        // moves a segment off its x.
        final identity = scaleLinear()
          ..domainOf(<double>[stacks.first.first.x!, stacks.last.first.x!])
          ..rangeOf(<double>[stacks.first.first.x!, stacks.last.first.x!]);
        final segments = delegate.segmentsFor(
          FluentCartesianChildContext(
            xScale: identity,
            yScalePrimary: _magnitudeScale(domain: <double>[0, 50], span: 295),
            containerWidth: 650,
            containerHeight: 350,
          ),
          _layout(height: 350),
        );
        expect(
          segments.length,
          stacks.length,
          reason: 'one segment per captured stack, or the loop asserts nothing',
        );
        for (final (i, stack) in stacks.indexed) {
          expectOracleNumber(
            '${story.id} stack $i translate',
            -barWidth / 2,
            stack.first.ctm![4],
          );
          expectOracleNumber(
            '${story.id} stack $i drawn left edge',
            stack.first.x! + stack.first.ctm![4],
            segments[i].rect.left,
          );
          expectOracleNumber(
            '${story.id} stack $i width',
            _kOracleBarWidth,
            segments[i].rect.width,
          );
        }
        // The tick under a stack sits on the bar's centre, offset by the half
        // pixel the capture bakes into every axis line.
        final ticks = <double>[
          for (final line in story.byTag('line'))
            if (line.y2 == 6) line.ctm![4],
        ];
        expect(
          ticks.length,
          11,
          reason: 'the captured x axis has eleven tick marks',
        );
        for (final stack in stacks) {
          final centre = stack.first.x! + story.crispOffset;
          final nearest = ticks.reduce(
            (a, b) => (a - centre).abs() < (b - centre).abs() ? a : b,
          );
          expectOracleNumber(
            '${story.id} tick over a segment centre',
            centre,
            nearest,
          );
        }
      });
    },
  );

  group('VSBC axis wiring', () {
    test('the x axis type follows the first stack point', () {
      expect(
        _vsbcDelegate(
          stacks: <List<double>>[
            <double>[1],
          ],
          barGapMax: 0,
          yMax: 1,
        ).xAxisType,
        FluentChartAxisType.category,
        reason:
            'the fixtures label their stacks, and `getTypeOfAxis` maps a '
            'string to a band axis, VerticalStackedBarChart.tsx:325-326',
      );
    });

    test('the y extent is the stack totals, not the segment values', () {
      final minMax = _vsbcDelegate(
        stacks: <List<double>>[
          <double>[10, 20],
          <double>[-5, -5],
        ],
        barGapMax: 0,
        yMax: 0,
      ).resolveYMinMax();
      expect(
        <double>[minMax.startValue, minMax.endValue],
        <double>[-10, 30],
        reason:
            '_createDataSetLayer sums each stack before findVSBCNumericMinMaxOfY '
            'reads it, VerticalStackedBarChart.tsx:344-352',
      );
    });
  });

  // None of the eight captured VerticalStackedBarChart stories puts the chart
  // on a category y axis, so the numbers below are derived from
  // `VerticalStackedBarChart.tsx` rather than from a fixture.
  group('VSBC category y axis', () {
    test('the band domain is prefixed with an empty label', () {
      final d = _vsbcStringYDelegate(labels: <String>['low', 'mid', 'high']);
      expect(
        d.stringDatasetForYAxisDomain,
        <String>['', 'low', 'mid', 'high'],
        reason: "VerticalStackedBarChart.tsx:1401 passes ['', ..._yAxisLabels]",
      );
    });

    test('the y axis type falls back to the line data', () {
      final d = _vsbcStringYDelegate(
        labels: <String>['low'],
        stackLabelIndices: <List<int>>[<int>[]],
      );
      expect(
        d.yAxisType,
        FluentChartAxisType.category,
        reason:
            'with no segments in the first stack, _initYAxisParams reads '
            '_lineObject[legend][0].y instead, '
            'VerticalStackedBarChart.tsx:1250-1256',
      );
      expect(
        d.stringDatasetForYAxisDomain,
        <String>[''],
        reason:
            'the fallback never adds the line value to _yAxisLabels, which '
            '_mapCategoryToValues builds from chartData alone, :1309-1327',
      );
    });

    test('the y domain margin inflates the top by the label surplus', () {
      final d = _vsbcStringYDelegate(
        labels: <String>['low', 'mid', 'high'],
        // Two stacks: the first names 'low' so the band domain covers all
        // three labels, the second index-sums to 5 label units.
        stackLabelIndices: <List<int>>[
          <int>[1],
          <int>[2, 3],
        ],
      );
      // totalHeight = 350 - 35 - 20 = 295 ; maxBarHeightInLabels = 5
      // yAxisLabelHeight = 59 ; tickMarginTop = 59 * (5 - 3) = 118
      expect(
        d.yDomainMargins(350)!.top,
        closeTo(20 + 118, 1e-9),
        reason: 'VerticalStackedBarChart.tsx:1261-1291',
      );
    });

    test('a zero maxBarHeightInLabels leaves the margin alone', () {
      final d = _vsbcStringYDelegate(
        labels: <String>['low'],
        stackLabelIndices: <List<int>>[<int>[]],
      );
      expect(
        d.yDomainMargins(350)!.top,
        closeTo(20, 1e-9),
        reason: 'yAxisLabelHeight is 0 when maxBarHeightInLabels is 0, :1283',
      );
    });

    test('a numeric y axis declines the margin override entirely', () {
      expect(
        _vsbcDelegate(
          stacks: <List<double>>[
            <double>[50],
          ],
          barGapMax: 0,
          yMax: 50,
        ).yDomainMargins(350),
        isNull,
        reason:
            'the StringAxis guard at :1271 leaves yAxisTickMarginTop at 0, '
            "which the shell spells as 'keep your own margins'",
      );
    });

    test('a category segment measures from the band centre', () {
      final d = _vsbcStringYDelegate(
        labels: <String>['low', 'mid', 'high'],
        stackLabelIndices: <List<int>>[
          <int>[2],
        ],
      );
      final ctx = _vsbcBandYContext();
      final seg = d.categorySegmentsFor(ctx, _layout(height: 350)).single;
      expect(
        seg.rect.height,
        closeTo(
          315 - (ctx.yScalePrimary('mid')! + ctx.yScalePrimary.bandwidth / 2),
          1e-9,
        ),
        reason:
            'barHeight = H - bottom - (yScale(data) + bandwidth/2) - gap, '
            'VerticalStackedBarChart.tsx:1057-1064',
      );
      expect(
        ctx.yScalePrimary.bandwidth,
        0,
        reason:
            'createStringYAxis forces paddingInner(1) for VSBC, so the '
            'bandwidth is zero, utilities.ts:973-975',
      );
      expect(
        seg.rect.bottom,
        closeTo(315, 1e-9),
        reason:
            'the string branch drops the Y_ORIGIN term, so every stack grows '
            'off the plot floor, VerticalStackedBarChart.tsx:1026-1029',
      );
      expect(
        seg.colour,
        _palette.first,
        reason: 'the first segment takes _colors[0] through flattenMark, :1036',
      );
    });

    test('a segment outside the band domain is filtered out', () {
      final d = _vsbcStringYDelegate(
        labels: <String>['low', 'unlabelled'],
        stackLabelIndices: <List<int>>[
          <int>[1, 2],
        ],
      );
      final segs = d.categorySegmentsFor(
        _vsbcBandYContext(),
        _layout(height: 350),
      );
      expect(
        segs.length,
        1,
        reason:
            'barsToDisplay drops a data whose band is undefined, '
            'VerticalStackedBarChart.tsx:1006-1014',
      );
    });

    test('paintSeries places the stacks with the CATEGORY solve', () {
      final d = _vsbcStringYDelegate(
        labels: const <String>['low', 'mid', 'high'],
      );
      final context = _vsbcBandYContext();
      expect(
        _paintDelegate(d, context).rects.map((r) => r.rect).toList(),
        d
            .categorySegmentsFor(context, _layout(height: 350))
            .map((s) => s.rect)
            .toList(),
        reason:
            '_getGraphData hands _createBar the shell y scale on a string y '
            'axis and its own yBarScale otherwise (:392-396). The numeric '
            'solve casts `data` to num, so a paintSeries that never branches '
            'throws on a labelled segment rather than mislaying it',
      );
    });
  });

  group('VSBC line overlay', () {
    test('the dot radius table covers all four states', () {
      final d = _vsbcWithLines();
      expect(
        d.lineDotRadiusFor(highlighted: true, isActiveX: true),
        8,
        reason: 'VerticalStackedBarChart.tsx:687',
      );
      expect(
        d.lineDotRadiusFor(highlighted: true, isActiveX: false),
        0.3,
        reason:
            'a highlighted legend at another x keeps a focusable stub, :689',
      );
      expect(
        d.lineDotRadiusFor(highlighted: false, isActiveX: true),
        0,
        reason: 'a dimmed legend hides the dot entirely, :691',
      );
      expect(
        d.lineDotRadiusFor(
          highlighted: true,
          isActiveX: false,
          noneHighlighted: true,
        ),
        8,
        reason:
            'with nothing highlighted every dot keeps r 8 and is hidden by '
            'opacity instead, VerticalStackedBarChart.tsx:694-699',
      );
    });

    test('the line takes the DESTINATION point colour', () {
      final d = _vsbcWithLines(
        colours: <Color>[const Color(0xFF111111), const Color(0xFF222222)],
      );
      final strokes = _paintDelegate(d, _vsbcContext()).lines;
      expect(
        strokes,
        hasLength(1),
        reason: 'two line points make one segment, and no halo is configured',
      );
      expect(
        strokes.single.colour,
        0xFF222222,
        reason:
            'parity: `stroke = lineObject[item][i].color` reads the '
            'segment END, VerticalStackedBarChart.tsx:620',
      );
    });

    test('high contrast flattens the line and its halo to opposite slots', () {
      final d = _vsbcWithLines(
        isHighContrast: true,
        activeXAxisDataPoint: _stackLabels[0],
        lineOptions: const FluentLineOptions(lineBorderWidth: 2),
      );
      final recorder = _paintDelegate(d, _vsbcContext());
      final halo = recorder.lines.where((l) => l.strokeWidth == 7).toList();
      final ink = recorder.lines.where((l) => l.strokeWidth == 3).toList();
      expect(
        (halo.length, ink.length),
        (1, 1),
        reason:
            'lineBorderWidth 2 gives a 3 + 2 * 2 = 7px halo under a 3px line '
            '(VerticalStackedBarChart.tsx:601 and :617)',
      );
      expect(
        ink.single.colour,
        _canvasText.toARGB32(),
        reason:
            'spec section 5.3 — the line is the mark itself, so it routes '
            'through flattenMark and lands on CanvasText',
      );
      expect(
        halo.single.colour,
        _canvas.toARGB32(),
        reason:
            'the halo is what holds the line off the stacks it crosses, so it '
            'routes through flattenMarkStroke and lands on Canvas — with both '
            'on CanvasText the line would vanish into bars that flattened to '
            'the same colour',
      );
      expect(
        recorder.circles.map((c) => (c.style, c.colour)).toList(),
        <(PaintingStyle, int)>[
          (PaintingStyle.fill, _canvas.toARGB32()),
          (PaintingStyle.stroke, _canvasText.toARGB32()),
        ],
        reason:
            'the dot is a fill under a ring (:648 then :647); flattening both '
            'the same way would erase it',
      );
    });

    test('the line is shifted half a band on a category x axis', () {
      final band = _vsbcWithLines(xPoints: _stackLabels.take(2).toList());
      expect(
        band.xAxisType,
        FluentChartAxisType.category,
        reason: 'the helper labels its stacks, so the x axis is a band axis',
      );
      final ctx = _vsbcContext();
      expect(
        _paintDelegate(band, ctx).lines.single.a.dx,
        closeTo(ctx.xScale(_stackLabels[0])! + ctx.xScale.bandwidth / 2, 1e-9),
        reason:
            'xScaleBandwidthTranslate is bandwidth/2 on a string x axis, '
            'VerticalStackedBarChart.tsx:569',
      );
    });

    test('a legend selected elsewhere dims the line to one tenth', () {
      final d = _vsbcWithLines(
        selectedLegends: const <String>['series 0'],
        lineOptions: const FluentLineOptions(lineBorderWidth: 2),
      );
      final alphas = _paintDelegate(
        d,
        _vsbcContext(),
      ).lines.map((l) => (l.colour >>> 24) / 255).toList();
      expect(
        alphas,
        everyElement(closeTo(0.1, 1 / 255)),
        reason:
            'opacity={shouldHighlight ? 1 : 0.1} on the halo (:600) and on the '
            'line (:616), and `line 0` is not the selected legend. The tenth '
            'of 255 is 25.5, so the packed byte can only be within half a '
            'step of it',
      );
      expect(alphas, hasLength(2), reason: 'one halo and one line');
    });

    test('the line uses the secondary y scale only when the point asks', () {
      Offset firstVertex({required bool useSecondaryYScale}) => _paintDelegate(
        _vsbcWithLines(useSecondaryYScale: useSecondaryYScale),
        _twoScaleContext(),
      ).lines.single.a;
      expect(
        firstVertex(useSecondaryYScale: true).dy,
        isNot(firstVertex(useSecondaryYScale: false).dy),
        reason:
            'VerticalStackedBarChart.tsx:577-587 plots a segment against '
            'yScaleSecondary when both of its endpoints ask for it; two scales '
            'with different domains cannot agree on the same y',
      );
      expect(
        firstVertex(useSecondaryYScale: true).dy,
        closeTo(_twoScaleContext().yScaleSecondary!(10)!, 1e-9),
        reason: 'the secondary scale is the one at :580',
      );
    });
  });

  group('Oracle B — charts-verticalstackedbarchart--vertical-stacked-bar-'
      'secondary-y-axis', () {
    /// The three captured `<line>` elements of the overlaid series, left to
    /// right. Their stroke is the only purple in the capture.
    List<OracleElement> lineSegments(OracleStory story) {
      final segments =
          story
              .byTag('line')
              .where((e) => e.stroke == const Color(0xFFB146C2))
              .toList()
            ..sort((a, b) => a.x1!.compareTo(b.x1!));
      expect(
        segments.length,
        3,
        reason:
            '${story.id} captured four line points and therefore three '
            'segments, or the assertions below check nothing',
      );
      return segments;
    }

    /// The delegate and context the capture's four line points feed, with the
    /// halo width [_kOracleLineBorderWidth] the capture's stroke implies.
    (FluentVerticalStackedBarChartDelegate, FluentCartesianChildContext)
    replayLine(List<OracleElement> segments) {
      final xs = <Object>[segments.first.x1!, for (final s in segments) s.x2!];
      final ys = <double>[segments.first.y1!, for (final s in segments) s.y2!];
      return (
        _vsbcWithLines(
          xPoints: xs,
          lineYs: ys,
          useSecondaryYScale: true,
          lineOptions: const FluentLineOptions(
            lineBorderWidth: _kOracleLineBorderWidth,
          ),
        ),
        _identityContext(xs, ys),
      );
    }

    test('the overlaid line visits every captured vertex', () {
      final story = loadOracleStory(
        'charts-verticalstackedbarchart--vertical-stacked-bar-secondary-y-axis',
      );
      final segments = lineSegments(story);
      for (final s in segments) {
        expectOracleOffset(
          '${story.id} line segment translate',
          Offset.zero,
          Offset(s.ctm![4], s.ctm![5]),
          tolerance: kOracleMeasuredTolerance,
        );
      }
      final (d, context) = replayLine(segments);
      final drawn = _paintDelegate(
        d,
        context,
        height: 260,
      ).lines.where((l) => l.strokeWidth == 3).toList();
      expect(
        drawn,
        hasLength(segments.length),
        reason:
            '${story.id} draws one <line> per segment (:609-625), and the port '
            'has to emit the same count rather than one joined polyline',
      );
      for (final (i, s) in segments.indexed) {
        expectOracleOffset(
          '${story.id} line segment $i start',
          Offset(s.x1!, s.y1!),
          drawn[i].a,
        );
        expectOracleOffset(
          '${story.id} line segment $i end',
          Offset(s.x2!, s.y2!),
          drawn[i].b,
        );
      }
    });

    test('the captured halo is a 7px run of the neutral background', () {
      final story = loadOracleStory(
        'charts-verticalstackedbarchart--vertical-stacked-bar-secondary-y-axis',
      );
      final segments = lineSegments(story);
      final captured =
          story.byTag('line').where((e) => e.strokeWidth == 7).toList()
            ..sort((a, b) => a.x1!.compareTo(b.x1!));
      expect(
        captured,
        hasLength(segments.length),
        reason:
            '${story.id} strokes one border line under each of its three line '
            'segments (:592-608), or the widths below check nothing',
      );
      final (d, context) = replayLine(segments);
      final drawn = _paintDelegate(
        d,
        context,
        height: 260,
      ).lines.where((l) => l.strokeWidth != 3).toList();
      expect(
        drawn.map((l) => l.strokeWidth).toSet(),
        <double>{7},
        reason:
            'the captured 7px stroke is `3 + lineBorderWidth * 2` (:601) at '
            'lineBorderWidth $_kOracleLineBorderWidth — the only value that '
            'produces it, and the story prop it pins down',
      );
      for (final (i, c) in captured.indexed) {
        expect(
          drawn[i].colour,
          c.stroke!.toARGB32(),
          reason:
              '${story.id} strokes the halo with colorNeutralBackground1 '
              '(:604), which the light theme resolves to white',
        );
        expectOracleOffset(
          '${story.id} halo segment $i start',
          Offset(c.x1!, c.y1!),
          drawn[i].a,
        );
      }
      expect(
        drawn.map((l) => l.order).reduce(math.max),
        lessThan(
          _paintDelegate(d, context, height: 260).lines
              .where((l) => l.strokeWidth == 3)
              .map((l) => l.order)
              .reduce(math.min),
        ),
        reason:
            'every borderForLines entry is emitted before every line entry '
            '(:672-673), so the halo can never paint over its own line',
      );
    });

    test('an unhighlighted dot keeps the 8px radius the capture shows', () {
      final story = loadOracleStory(
        'charts-verticalstackedbarchart--vertical-stacked-bar-secondary-y-axis',
      );
      final dots = story.byTag('circle');
      expect(
        dots.length,
        4,
        reason: '${story.id} captured one dot per line point',
      );
      final d = _vsbcWithLines();
      for (final dot in dots) {
        expectOracleNumber(
          '${story.id} dot radius with nothing highlighted',
          dot.r!,
          d.lineDotRadiusFor(
            highlighted: true,
            // The story sets no activeXAxisDataPoint, so no dot is active.
            isActiveX: false,
            noneHighlighted: true,
          ),
        );
        expect(
          dot.opacity,
          0,
          reason:
              'the capture proves the r-8 dot is hidden by opacity, not by '
              'radius, so it stays focusable, '
              'VerticalStackedBarChart.tsx:694-698',
        );
      }
      expect(
        _paintDelegate(d, _vsbcContext()).circles,
        isEmpty,
        reason:
            'ponytail: an opacity-0 dot exists upstream only to hold a tab '
            'stop (:650-652), and this delegate emits no hit regions at all, '
            'so the port skips the paint instead of drawing four invisible '
            'circles',
      );
    });
  });

  group('FluentVerticalStackedBarChart', () {
    Future<void> pump(WidgetTester tester, Widget chart) => tester.pumpWidget(
      FluentApp(
        theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
        home: Center(child: SizedBox(width: 800, height: 350, child: chart)),
      ),
    );

    /// Runs the plot painter the widget itself mounted over a recorder.
    ///
    /// The plot is the first [CustomPaint] under the shell: the column puts it
    /// ahead of the legend (`cartesian_chart.dart:370-382`) and builds it with
    /// `painter: FluentCartesianChartPainter` (`:542-543`). Reading the paint
    /// back from *this* painter is the only thing that proves a delegate helper
    /// is reached from `FluentVerticalStackedBarChart.build` rather than from a
    /// hand-built delegate in a unit test.
    _VsbcRecorder paintPlot(WidgetTester tester) {
      final plot = find
          .descendant(
            of: find.byType(FluentCartesianChart),
            matching: find.byType(CustomPaint),
          )
          .first;
      final recorder = _VsbcRecorder();
      tester
          .widget<CustomPaint>(plot)
          .painter!
          .paint(recorder, tester.getSize(plot));
      return recorder;
    }

    testWidgets('the mounted chart really paints its line overlay', (
      tester,
    ) async {
      await pump(
        tester,
        FluentVerticalStackedBarChart(data: _vsbcLineOverlayStacks()),
      );
      final recorder = paintPlot(tester);
      final ink = recorder.lines
          .where((l) => l.colour == _kLineInk.toARGB32())
          .toList();
      expect(
        ink,
        hasLength(2),
        reason:
            'three line points make two <line> elements '
            '(VerticalStackedBarChart.tsx:573-620); zero means paintSeries '
            'never reaches linePathsFor from the mounted widget',
      );
      expect(
        ink.map((l) => l.strokeWidth).toList(),
        const <double>[3, 3],
        reason:
            'strokeWidth={lineObject[item][0].lineOptions?.strokeWidth ?? 3} '
            '(VerticalStackedBarChart.tsx:617)',
      );
      expect(
        ink.map((l) => l.cap).toList(),
        const <StrokeCap>[StrokeCap.round, StrokeCap.round],
        reason:
            "strokeLinecap={… ?? 'round'} (VerticalStackedBarChart.tsx:618)",
      );
      expect(
        recorder.rects.map((r) => r.order).reduce(math.max),
        lessThan(ink.map((l) => l.order).reduce(math.min)),
        reason:
            'the overlay is a sibling <g> AFTER the one holding the bars '
            '(VerticalStackedBarChart.tsx:1407-1417), so a line always crosses '
            'over the stacks and never under them',
      );
      final plot = Offset.zero & tester.getSize(find.byType(CustomPaint).first);
      for (final segment in ink) {
        expect(
          plot.contains(segment.a) && plot.contains(segment.b),
          isTrue,
          reason: 'a line drawn outside $plot is not on the plot',
        );
      }
    });

    testWidgets('the mounted chart really paints its line halo', (
      tester,
    ) async {
      await pump(
        tester,
        FluentVerticalStackedBarChart(
          data: _vsbcLineOverlayStacks(),
          lineOptions: const FluentLineOptions(
            lineBorderWidth: _kOracleLineBorderWidth,
          ),
        ),
      );
      final halo = paintPlot(
        tester,
      ).lines.where((l) => l.strokeWidth == 7).toList();
      expect(
        halo,
        hasLength(2),
        reason:
            'props.lineOptions.lineBorderWidth (:566-568) is the only source '
            'of the halo, so an unforwarded prop leaves the 3 + 2 * 2 = 7px '
            'run (:601) unpainted',
      );
      expect(
        halo.map((l) => l.colour).toSet(),
        <int>{0xFFFFFFFF},
        reason:
            'stroke={tokens.colorNeutralBackground1} (:604), which the light '
            'theme resolves to white',
      );
    });

    testWidgets('the legend colour is deterministic, not random', (
      tester,
    ) async {
      await pump(tester, FluentVerticalStackedBarChart(data: _vsbcStacks()));
      final first = tester
          .widget<FluentCartesianChart>(find.byType(FluentCartesianChart))
          .legends;
      await tester.pumpWidget(const SizedBox.shrink());
      await pump(tester, FluentVerticalStackedBarChart(data: _vsbcStacks()));
      final second = tester
          .widget<FluentCartesianChart>(find.byType(FluentCartesianChart))
          .legends;
      expect(
        first.map((l) => l.color.toARGB32()).toList(),
        second.map((l) => l.color.toARGB32()).toList(),
        reason:
            'ponytail: VerticalStackedBarChart.tsx:167 picks '
            'defaultPalette[Math.floor(Math.random() * 4 + 1)], re-rolled on '
            'every render. Spec 5.2 exception 1 fixes non-determinism, so the '
            'port uses defaultPalette[index % 5] — the same colour the segment '
            'itself paints.',
      );
    });

    testWidgets('the legend swatch matches the segment it stands for', (
      tester,
    ) async {
      await pump(tester, FluentVerticalStackedBarChart(data: _vsbcStacks()));
      final shell = tester.widget<FluentCartesianChart>(
        find.byType(FluentCartesianChart),
      );
      final d = shell.delegate as FluentVerticalStackedBarChartDelegate;
      expect(
        shell.legends.first.color.toARGB32(),
        d.palette[0].toARGB32(),
        reason:
            'the deterministic replacement makes the swatch and the bar '
            'agree, which the random pick could never guarantee',
      );
    });

    testWidgets('isCalloutForStack switches focus to the whole stack', (
      tester,
    ) async {
      await pump(
        tester,
        FluentVerticalStackedBarChart(
          data: _vsbcStacks(),
          isCalloutForStack: true,
        ),
      );
      final shell = tester.widget<FluentCartesianChart>(
        find.byType(FluentCartesianChart),
      );
      expect(
        shell.props.hitRegionGranularity,
        FluentChartHitGranularity.group,
        reason:
            '_toFocusWholeStack at VerticalStackedBarChart.tsx:486-489 '
            'moves the focus props from each rect onto the stack group',
      );
    });

    testWidgets('line legends follow the bar legends', (tester) async {
      await pump(
        tester,
        FluentVerticalStackedBarChart(data: _vsbcStacksWithLine()),
      );
      final legends = tester
          .widget<FluentCartesianChart>(find.byType(FluentCartesianChart))
          .legends;
      expect(
        legends.last.isLineLegendInBarChart,
        isTrue,
        reason:
            'VerticalStackedBarChart.tsx:207 appends line legends, the '
            'reverse of GroupedVerticalBarChart',
      );
    });

    testWidgets('allowHoverOnLegend false removes the hover handlers', (
      tester,
    ) async {
      await pump(
        tester,
        FluentVerticalStackedBarChart(
          data: _vsbcStacks(),
          allowHoverOnLegend: false,
        ),
      );
      final legends = tester
          .widget<FluentCartesianChart>(find.byType(FluentCartesianChart))
          .legends;
      expect(
        legends.first.onHoverAction,
        isNull,
        reason: 'VerticalStackedBarChart.tsx:164 omits the handlers entirely',
      );
    });

    testWidgets('the semantic title counts stacks and lines', (tester) async {
      await pump(
        tester,
        FluentVerticalStackedBarChart(
          data: _vsbcStacksWithLine(),
          chartTitle: 'Spend',
        ),
      );
      expect(
        tester
            .widget<FluentCartesianChart>(find.byType(FluentCartesianChart))
            .props
            .chartTitleForSemantics,
        'Spend. Vertical bar chart with 3 stacked bars and 1 lines. ',
        reason:
            'VerticalStackedBarChart.tsx:968-977 — note the unpluralised '
            '"1 lines", reproduced',
      );
    });

    testWidgets('an all-empty dataset renders the no-data live region', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentVerticalStackedBarChart(
          data: <FluentVerticalStackedBarGroup>[],
        ),
      );
      expect(
        find.byType(FluentCartesianChart),
        findsNothing,
        reason:
            'VerticalStackedBarChart.tsx:893-899 short-circuits before the '
            'shell when no stack carries chartData or lineData',
      );
    });

    testWidgets('selecting a legend reaches the delegate', (tester) async {
      await pump(tester, FluentVerticalStackedBarChart(data: _vsbcStacks()));
      final shell = tester.widget<FluentCartesianChart>(
        find.byType(FluentCartesianChart),
      );
      shell.onLegendChange!(<String>['series 0']);
      await tester.pump();
      final d =
          tester
                  .widget<FluentCartesianChart>(
                    find.byType(FluentCartesianChart),
                  )
                  .delegate
              as FluentVerticalStackedBarChartDelegate;
      expect(
        d.selectedLegends,
        <String>['series 0'],
        reason:
            'the legend selection has to reach the segment dimming at '
            'VerticalStackedBarChart.tsx:1038, which reads _selectedLegends',
      );
    });
  });
}

/// Three two-segment stacks, the shape every widget test above measures.
List<FluentVerticalStackedBarGroup> _vsbcStacks() =>
    <FluentVerticalStackedBarGroup>[
      for (var i = 0; i < 3; i++)
        FluentVerticalStackedBarGroup(
          chartData: _segments(<double>[10.0 + i, 20.0 + i]),
          xAxisPoint: _stackLabels[i],
        ),
    ];

/// The overlaid line's ink, chosen as the purple the secondary-y-axis capture
/// strokes its line with so nothing else in the plot can share it.
const Color _kLineInk = Color(0xFFB146C2);

/// Three single-segment stacks under one three-point line legend.
///
/// The segments are a flat 50 so the bars cannot move a line point, and the
/// line ys rise, fall and rise so a collapsed polyline is not mistakable for a
/// correct one.
List<FluentVerticalStackedBarGroup> _vsbcLineOverlayStacks() =>
    <FluentVerticalStackedBarGroup>[
      for (final (i, y) in <double>[25, 40, 30].indexed)
        FluentVerticalStackedBarGroup(
          chartData: _segments(<double>[50]),
          xAxisPoint: _stackLabels[i],
          lineData: <FluentStackedBarLineDatum>[
            FluentStackedBarLineDatum(y: y, color: _kLineInk, legend: 'line 0'),
          ],
        ),
    ];

/// [_vsbcStacks] with one line legend laid over it, so the semantic title has
/// both counts to report.
List<FluentVerticalStackedBarGroup> _vsbcStacksWithLine() =>
    <FluentVerticalStackedBarGroup>[
      for (final (i, stack) in _vsbcStacks().indexed)
        FluentVerticalStackedBarGroup(
          chartData: stack.chartData,
          xAxisPoint: stack.xAxisPoint,
          lineData: <FluentStackedBarLineDatum>[
            FluentStackedBarLineDatum(
              y: 25 + i,
              color: _palette[0],
              legend: 'line 0',
            ),
          ],
        ),
    ];

/// The five DataViz tokens VSBC falls back to, in upstream order
/// (`VerticalStackedBarChart.tsx:316-322`).
final List<Color> _palette = <Color>[
  FluentDataVizPalette.resolve(FluentDataVizToken.color6),
  FluentDataVizPalette.resolve(FluentDataVizToken.color1),
  FluentDataVizPalette.resolve(FluentDataVizToken.color5),
  FluentDataVizPalette.resolve(FluentDataVizToken.color7),
  FluentDataVizPalette.resolve(FluentDataVizToken.color10),
];

const _placeholder = Color(0xFF010203);
const _canvasText = Color(0xFFFFFFFF);
const _canvas = Color(0xFF000000);

/// The eleven-field colour set, so `isHighContrast` can be flipped without a
/// second [FluentThemeData].
FluentChartColors _colours({bool isHighContrast = false}) => FluentChartColors(
  axisText: _canvasText,
  axisTick: _placeholder,
  axisTitle: _placeholder,
  gridLine: _placeholder,
  markStroke: _placeholder,
  surface: _canvas,
  popoverSurface: _placeholder,
  tooltipSurface: _placeholder,
  legendDimmed: _placeholder,
  isHighContrast: isHighContrast,
);

/// The margins the shell defaults to (`CartesianChart.tsx:41-42`), so a 350px
/// layout leaves exactly 295px of plot.
const _margins = FluentChartMargins(left: 40, right: 20, top: 20, bottom: 35);

FluentCartesianLayout _layout({required double height}) =>
    FluentCartesianLayout.resolve(
      size: Size(640, height),
      margins: _margins,
      xAxisLabelReserve: 0,
      isRtl: false,
      startFromX: 0,
    );

/// The stack labels `_vsbcDelegate` names its groups with. Eight is more than
/// any fixture below needs, so the band scale never misses.
const List<String> _stackLabels = <String>[
  'stack 0',
  'stack 1',
  'stack 2',
  'stack 3',
  'stack 4',
  'stack 5',
  'stack 6',
  'stack 7',
];

/// A child context whose x scale is the band scale a category axis builds, and
/// whose y scale is unread by the numeric segment solve — that one builds its
/// own `yBarScale` (`VerticalStackedBarChart.tsx:850-853`).
FluentCartesianChildContext _vsbcContext() => FluentCartesianChildContext(
  xScale: _bandScale(
    domain: _stackLabels,
    range: <double>[40, 620],
    // getScalePadding's category default (VerticalStackedBarChart.tsx:329).
    innerPadding: 2 / 3,
    outerPadding: 0,
  ),
  yScalePrimary: _magnitudeScale(domain: <double>[0, 100], span: 295),
  containerWidth: 640,
  containerHeight: 350,
);

FluentVerticalStackedBarChartDelegate _vsbcDelegate({
  required List<List<double>> stacks,
  required double barGapMax,
  required double yMax,
  double yMin = 0,
  double barMinimumHeight = 0,
  double barCornerRadius = 0,
  List<String> selectedLegends = const <String>[],
  bool isHighContrast = false,
  List<Object>? xPoints,
}) {
  expect(
    stacks.length,
    lessThanOrEqualTo(xPoints?.length ?? _stackLabels.length),
    reason: 'the x domain has to cover every stack, or xScale returns null',
  );
  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
  return FluentVerticalStackedBarChartDelegate(
    stacks: <FluentVerticalStackedBarGroup>[
      for (final (i, values) in stacks.indexed)
        FluentVerticalStackedBarGroup(
          chartData: _segments(values),
          xAxisPoint: xPoints?[i] ?? _stackLabels[i],
        ),
    ],
    style: resolveFluentVerticalStackedBarChartStyle(theme),
    colors: _colours(isHighContrast: isHighContrast),
    measurer: FluentChartTextMeasurer(),
    textStyles: FluentChartTextStyles.of(theme),
    selectedLegends: selectedLegends,
    palette: _palette,
    barGapMax: barGapMax,
    barCornerRadius: barCornerRadius,
    barMinimumHeight: barMinimumHeight,
    yMinValue: yMin,
    yMaxValue: yMax,
  );
}

/// A delegate whose primary y axis is categorical.
///
/// Each entry of [stackLabelIndices] is one stack, spelled as the **one-based**
/// positions of its segments' labels within [labels] — which is exactly the
/// quantity `_yAxisLabels.indexOf(`${bar.data}`) + 1` sums at
/// `VerticalStackedBarChart.tsx:1278`. The default gives one stack per label,
/// so the band domain covers every entry of [labels].
///
/// Every stack carries one line point, because `_initYAxisParams` falls back to
/// the line data to type the y axis when the first stack has no segments
/// (`VerticalStackedBarChart.tsx:1250-1256`).
FluentVerticalStackedBarChartDelegate _vsbcStringYDelegate({
  required List<String> labels,
  List<List<int>>? stackLabelIndices,
}) {
  final indices =
      stackLabelIndices ??
      <List<int>>[
        for (var i = 1; i <= labels.length; i++) <int>[i],
      ];
  expect(
    indices.length,
    lessThanOrEqualTo(_stackLabels.length),
    reason: 'the x domain has to cover every stack, or xScale returns null',
  );
  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
  return FluentVerticalStackedBarChartDelegate(
    stacks: <FluentVerticalStackedBarGroup>[
      for (final (i, positions) in indices.indexed)
        FluentVerticalStackedBarGroup(
          chartData: <FluentStackedBarDatum>[
            for (final p in positions)
              FluentStackedBarDatum(data: labels[p - 1], legend: 'series $p'),
          ],
          xAxisPoint: _stackLabels[i],
          lineData: <FluentStackedBarLineDatum>[
            FluentStackedBarLineDatum(
              y: labels.first,
              color: _palette.first,
              legend: 'line',
            ),
          ],
        ),
    ],
    style: resolveFluentVerticalStackedBarChartStyle(theme),
    colors: _colours(),
    measurer: FluentChartTextMeasurer(),
    textStyles: FluentChartTextStyles.of(theme),
    selectedLegends: const <String>[],
    palette: _palette,
  );
}

/// A child context whose y scale is the zero-bandwidth band a category y axis
/// builds (`utilities.ts:973-975`), so a 350px layout leaves the plot floor at
/// 315 and the ceiling at 20.
FluentCartesianChildContext _vsbcBandYContext() => FluentCartesianChildContext(
  xScale: _bandScale(
    domain: _stackLabels,
    range: <double>[40, 620],
    innerPadding: 2 / 3,
    outerPadding: 0,
  ),
  yScalePrimary: _bandScale(
    domain: <String>['', 'low', 'mid', 'high'],
    range: <double>[315, 20],
    innerPadding: 1,
    outerPadding: 0,
  ),
  containerWidth: 640,
  containerHeight: 350,
);

/// A context whose scales are the identity over [xs] and [ys], so a captured
/// pixel feeds straight back in as a domain value.
FluentCartesianChildContext _identityContext(List<Object> xs, List<double> ys) {
  final xValues = xs.cast<double>();
  final identityX = scaleLinear()
    ..domainOf(<double>[xValues.reduce(math.min), xValues.reduce(math.max)])
    ..rangeOf(<double>[xValues.reduce(math.min), xValues.reduce(math.max)]);
  final identityY = scaleLinear()
    ..domainOf(<double>[ys.reduce(math.min), ys.reduce(math.max)])
    ..rangeOf(<double>[ys.reduce(math.min), ys.reduce(math.max)]);
  return FluentCartesianChildContext(
    xScale: identityX,
    yScalePrimary: identityY,
    yScaleSecondary: identityY,
    containerWidth: 700,
    containerHeight: 260,
  );
}

/// A delegate carrying one line legend, `'line 0'`, with one point per stack.
FluentVerticalStackedBarChartDelegate _vsbcWithLines({
  List<Color>? colours,
  List<double> lineYs = const <double>[10, 20],
  List<Object>? xPoints,
  bool isHighContrast = false,
  bool useSecondaryYScale = false,
  List<String> selectedLegends = const <String>[],
  Object? activeXAxisDataPoint,
  FluentLineOptions? lineOptions,
}) {
  final palette = colours ?? _palette;
  expect(
    lineYs.length,
    lessThanOrEqualTo(xPoints?.length ?? _stackLabels.length),
    reason: 'the x domain has to cover every stack, or xScale returns null',
  );
  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
  return FluentVerticalStackedBarChartDelegate(
    stacks: <FluentVerticalStackedBarGroup>[
      for (final (i, y) in lineYs.indexed)
        FluentVerticalStackedBarGroup(
          chartData: _segments(<double>[50]),
          xAxisPoint: xPoints?[i] ?? _stackLabels[i],
          lineData: <FluentStackedBarLineDatum>[
            FluentStackedBarLineDatum(
              y: y,
              color: palette[i % palette.length],
              legend: 'line 0',
              useSecondaryYScale: useSecondaryYScale,
            ),
          ],
        ),
    ],
    style: resolveFluentVerticalStackedBarChartStyle(theme),
    colors: _colours(isHighContrast: isHighContrast),
    measurer: FluentChartTextMeasurer(),
    textStyles: FluentChartTextStyles.of(theme),
    selectedLegends: selectedLegends,
    activeXAxisDataPoint: activeXAxisDataPoint,
    lineOptions: lineOptions,
    palette: _palette,
  );
}

/// A context carrying two numeric y scales with disjoint outputs, so a vertex
/// on one can never coincide with the same value on the other.
FluentCartesianChildContext _twoScaleContext() => FluentCartesianChildContext(
  xScale: _bandScale(
    domain: _stackLabels,
    range: <double>[40, 620],
    innerPadding: 2 / 3,
    outerPadding: 0,
  ),
  yScalePrimary: _magnitudeScale(domain: <double>[0, 100], span: 295),
  yScaleSecondary: _magnitudeScale(domain: <double>[0, 1000], span: 295),
  containerWidth: 640,
  containerHeight: 350,
);

/// Runs [d]'s own `paintSeries` over a recorder.
///
/// `paintSeries` is the delegate's whole painting surface — the axes and their
/// labels are the shell's — so every stroke, rect and circle a recorder driven
/// this way collects belongs to the stacks or to the line overlay.
_VsbcRecorder _paintDelegate(
  FluentVerticalStackedBarChartDelegate d,
  FluentCartesianChildContext context, {
  double height = 350,
}) {
  final recorder = _VsbcRecorder();
  d.paintSeries(recorder, context, _layout(height: height), d.colors);
  return recorder;
}

/// A [Canvas] that logs every stroke, fill and rect the plot painter emits.
///
/// Colours are stored as `toARGB32` because a [Paint] colour has been through
/// `withValues(alpha: …)` by the time it lands here, and the packed integer is
/// the comparison that survives that round trip unambiguously.
class _VsbcRecorder implements Canvas {
  /// Every [Canvas.drawLine], in paint order.
  final List<
    ({
      Offset a,
      Offset b,
      int colour,
      double strokeWidth,
      StrokeCap cap,
      int order,
    })
  >
  lines =
      <
        ({
          Offset a,
          Offset b,
          int colour,
          double strokeWidth,
          StrokeCap cap,
          int order,
        })
      >[];

  /// Every [Canvas.drawRect] and [Canvas.drawRRect], in paint order.
  final List<({Rect rect, int colour, int order})> rects =
      <({Rect rect, int colour, int order})>[];

  /// Every [Canvas.drawCircle], in paint order.
  final List<
    ({Offset centre, double radius, int colour, PaintingStyle style, int order})
  >
  circles =
      <
        ({
          Offset centre,
          double radius,
          int colour,
          PaintingStyle style,
          int order,
        })
      >[];

  int _order = 0;

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) => lines.add((
    a: p1,
    b: p2,
    colour: paint.color.toARGB32(),
    strokeWidth: paint.strokeWidth,
    cap: paint.strokeCap,
    order: _order++,
  ));

  @override
  void drawRect(Rect rect, Paint paint) =>
      rects.add((rect: rect, colour: paint.color.toARGB32(), order: _order++));

  @override
  void drawRRect(RRect rrect, Paint paint) => rects.add((
    rect: rrect.outerRect,
    colour: paint.color.toARGB32(),
    order: _order++,
  ));

  @override
  void drawCircle(Offset c, double radius, Paint paint) => circles.add((
    centre: c,
    radius: radius,
    colour: paint.color.toARGB32(),
    style: paint.style,
    order: _order++,
  ));

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
