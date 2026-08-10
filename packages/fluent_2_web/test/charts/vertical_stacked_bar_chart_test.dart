import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/internal/d3/scale.dart';
import 'package:fluent_2_web/src/charts/internal/d3/scale_band.dart';
import 'package:fluent_2_web/src/charts/internal/d3/scale_linear.dart';
import 'package:fluent_2_web/src/charts/internal/data_viz_palette.dart';
import 'package:fluent_2_web/src/charts/model/bar_data.dart';
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
}
