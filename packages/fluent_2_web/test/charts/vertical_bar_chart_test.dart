import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/internal/d3/scale.dart';
import 'package:fluent_2_web/src/charts/internal/d3/scale_linear.dart';
import 'package:fluent_2_web/src/charts/model/chart_common.dart';
import 'package:fluent_2_web/src/charts/model/chart_value.dart';
import 'package:fluent_2_web/src/charts/vertical_bar_chart.dart';
import 'package:fluent_2_web/src/charts/vertical_bar_chart_style.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/oracle_fixture.dart';

/// `yBarScale` as `_getScales` builds it (`VerticalBarChart.tsx:584-586`):
/// the data domain mapped onto `[0, plotHeight]`, so the scale returns a
/// magnitude in pixels rather than a plot coordinate.
Scale _magnitudeScale({required List<double> domain, required double span}) =>
    ScaleLinear()
      ..domainOf(domain)
      ..rangeOf(<double>[0, span]);

/// The chart-wide margins every VerticalBarChart story was captured with —
/// recovered in the oracle group below from the band-scale range of
/// `charts-verticalbarchart--vertical-bar-styled`.
const FluentChartMargins _margins = FluentChartMargins(
  top: 20,
  bottom: 35,
  left: 40,
  right: 20,
);

/// `_xAxisInnerPadding`'s default for a string axis
/// (`VerticalBarChart.tsx:315-322`), confirmed against the oracle: the styled
/// story's band step is 58.702703 and its bandwidth 19.567568, whose ratio is
/// exactly `1 - 2/3`.
const double _defaultInnerPadding = 2 / 3;

/// Reproduces the bar loop of `_createStringBars`
/// (`VerticalBarChart.tsx:693-755`) over the geometry this task owns, so the
/// quantisation that [FluentVerticalBarChartGeometry.minBarHeight] drives is
/// asserted without a canvas. The delegate that ports the loop into production
/// lands in the next task.
List<FluentVerticalBarRect> _bars({
  required List<double> ys,
  required double yMin,
  required double yMax,
  required double containerHeight,
}) {
  final yBarScale = _magnitudeScale(
    domain: <double>[yMin, yMax],
    span: containerHeight - _margins.top! - _margins.bottom!,
  );
  // `_yMax < 0 ? _yMax : 0` (VerticalBarChart.tsx:638).
  final yReference = yMax < 0 ? yMax : 0.0;
  final floor = FluentVerticalBarChartGeometry.minBarHeight(
    yMin: yMin,
    yMax: yMax,
    yReferencePoint: yReference,
    yBarScale: yBarScale,
  );
  final baseline = containerHeight - _margins.bottom! - yBarScale(yReference)!;
  final out = <FluentVerticalBarRect>[];
  for (var i = 0; i < ys.length; i++) {
    var height = yBarScale(ys[i])! - yBarScale(yReference)!;
    final isNegative = height < 0;
    height = height.abs();
    if (height == 0) {
      // VerticalBarChart.tsx:649-651 returns an empty fragment.
      continue;
    }
    final adjusted = height <= floor ? floor : height;
    final top = isNegative ? baseline : baseline - adjusted;
    // 16 is `_barWidth`'s default (`DEFAULT_BAR_WIDTH`, utilities.ts:1891).
    const barWidth = 16.0;
    // 6 above and 12 below, VerticalBarChart.tsx:965.
    final labelDy = isNegative ? 12.0 : -6.0;
    out.add(
      FluentVerticalBarRect(
        rect: Rect.fromLTWH(i * barWidth, top, barWidth, adjusted),
        colour: FluentVerticalBarChartGeometry.colourFor(
          ys[i],
          palette: const <Color>[Color(0xFF1E90FF)],
          yMax: yMax,
        ),
        opacity: 1,
        index: i,
        isNegative: isNegative,
        labelAnchor: Offset(i * barWidth + barWidth / 2, top + labelDy),
      ),
    );
  }
  return out;
}

void main() {
  const states = <WidgetState>{};
  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
  final palette = theme.colors.palette;

  group('FluentVerticalBarChartStyle', () {
    test('carries the five-token default palette in source order', () {
      final style = resolveFluentVerticalBarChartStyle(theme);
      final ramp = style.palette!.resolve(states)!;
      expect(
        ramp.length,
        5,
        reason: 'VerticalBarChart.tsx:306-312 lists exactly five tokens',
      );
      expect(
        ramp.first.toARGB32(),
        palette.foreground2Rest(FluentPaletteFamily.blue).toARGB32(),
        reason: 'the first default colour is colorPaletteBlueForeground2',
      );
      expect(
        ramp.last.toARGB32(),
        palette.foreground2Rest(FluentPaletteFamily.darkOrange).toARGB32(),
        reason:
            'the fifth and last is colorPaletteDarkOrangeForeground2 '
            '(VerticalBarChart.tsx:311)',
      );
    });

    test(
      'the line legend swatch colour differs from the drawn line colour',
      () {
        final style = resolveFluentVerticalBarChartStyle(theme);
        expect(
          style.lineColor!.resolve(states)!.toARGB32(),
          palette.background1Rest(FluentPaletteFamily.yellow)!.toARGB32(),
          reason:
              'parity: VerticalBarChart.tsx:165 draws with '
              'colorPaletteYellowBackground1',
        );
        expect(
          style.lineLegendSwatchColor!.resolve(states)!.toARGB32(),
          palette.foreground1Rest(FluentPaletteFamily.yellow)!.toARGB32(),
          reason:
              'parity: VerticalBarChart.tsx:826 uses '
              'colorPaletteYellowForeground1 for the swatch — a real upstream '
              'inconsistency, reproduced',
        );
      },
    );

    test('the line dot radii come in three values', () {
      final style = resolveFluentVerticalBarChartStyle(theme);
      expect(
        style.lineDotRadius!.resolve(<WidgetState>{WidgetState.hovered}),
        8.0,
        reason: 'VerticalBarChart.tsx:278 uses r 8 for the active x',
      );
      expect(
        style.lineDotRadius!.resolve(states),
        0.3,
        reason:
            'VerticalBarChart.tsx:282 keeps r 0.3 so the dot stays focusable',
      );
    });

    test('the rounded-corner radius is 3 and the dim opacity 0.1', () {
      final style = resolveFluentVerticalBarChartStyle(theme);
      expect(
        style.barCornerRadius!.resolve(states),
        3.0,
        reason: 'rx = 3 when roundCorners, VerticalBarChart.tsx:684',
      );
      expect(
        style.barOpacity!.resolve(<WidgetState>{WidgetState.disabled}),
        0.1,
        reason: 'VerticalBarChart.tsx:683 dims to 0.1',
      );
    });

    test('merge lets the other style win field by field', () {
      final base = resolveFluentVerticalBarChartStyle(theme);
      final merged = base.merge(
        FluentVerticalBarChartStyle.from(barCornerRadius: 0),
      );
      expect(
        merged.barCornerRadius!.resolve(states),
        0.0,
        reason: 'roundCorners off is rx = 0, and merge must let it through',
      );
      expect(
        merged.lineStrokeWidth!.resolve(states),
        base.lineStrokeWidth!.resolve(states),
        reason: 'a null slot in the overlay keeps the derived default',
      );
      expect(
        base.copyWith(barCornerRadius: merged.barCornerRadius),
        merged,
        reason: 'copyWith and merge agree, so == and hashCode are structural',
      );
    });
  });

  group('FluentVerticalBarChartStyle against oracle B', () {
    // The label gaps and the minimum labelled bar width are the only style
    // slots the corpus paints: every VerticalBarChart story overrides the
    // series colours per point, so no capture exercises the default ramp.
    test(
      'bar labels sit 6 above a positive bar and 12 below a negative one',
      () {
        final style = resolveFluentVerticalBarChartStyle(theme);
        final above = style.barLabelGapAbove!.resolve(states)!;
        final below = style.barLabelGapBelow!.resolve(states)!;
        var positives = 0;
        var negatives = 0;
        for (final storyId in <String>[
          'charts-verticalbarchart--vertical-bar-default',
          'charts-verticalbarchart--vertical-bar-negative',
        ]) {
          final story = loadOracleStory(storyId);
          // Both stories draw 8 bars; the negative one also draws two wide
          // tooltip backgrounds, which the width filter drops.
          final bars = story
              .byTag('rect')
              .where((rect) => rect.width == 16)
              .toList();
          expect(
            bars.length,
            8,
            reason: '$storyId must contribute 8 bars, not an empty selection',
          );
          for (final bar in bars) {
            final group = story.parentOf(bar)!;
            final labels = story
                .childrenOf(group)
                .where((child) => child.tag == 'text')
                .toList();
            expect(
              labels.length,
              1,
              reason: '$storyId: each bar group holds exactly one bar label',
            );
            final label = labels.single;
            if (label.y! < bar.y!) {
              positives++;
              expect(
                bar.y! - label.y!,
                closeTo(above, kOracleGeometryTolerance),
                reason:
                    '$storyId: VerticalBarChart.tsx:965 places a positive '
                    "bar's label at yPoint - 6",
              );
            } else {
              negatives++;
              expect(
                label.y! - (bar.y! + bar.height!),
                closeTo(below, kOracleGeometryTolerance),
                reason:
                    '$storyId: VerticalBarChart.tsx:965 places a negative '
                    "bar's label at yPoint + 12, yPoint being the bar's foot",
              );
            }
          }
        }
        expect(
          positives,
          12,
          reason: 'both gaps must be measured, not just the positive one',
        );
        expect(
          negatives,
          4,
          reason: 'the negative story contributes four downward labels',
        );
      },
    );

    test('a bar narrower than the minimum carries no label at all', () {
      final style = resolveFluentVerticalBarChartStyle(theme);
      final minimum = style.minBarLabelWidth!.resolve(states)!;
      final story = loadOracleStory(
        'charts-verticalbarchart--vertical-bar-dynamic',
      );
      final bars = story.byTag('rect');
      expect(bars.length, 5, reason: 'the dynamic story draws five bars');
      for (final bar in bars) {
        expect(
          bar.width,
          lessThan(minimum),
          reason: 'every dynamic-story bar is 4 wide, under the 16 threshold',
        );
      }
      final labelStyle = style.barLabelStyle!.resolve(states)!;
      expect(
        story
            .byTag('text')
            .where((text) => text.fontSize == labelStyle.fontSize)
            .toList(),
        isEmpty,
        reason:
            'VerticalBarChart.tsx:950 returns null below _barWidth 16, so no '
            'caption1Strong text is painted — only 10px axis ticks',
      );
    });

    test('the bar label is caption1Strong at colorNeutralForeground1', () {
      final labelStyle = resolveFluentVerticalBarChartStyle(
        theme,
      ).barLabelStyle!.resolve(states)!;
      final story = loadOracleStory(
        'charts-verticalbarchart--vertical-bar-default',
      );
      final labels = story
          .byTag('text')
          .where((text) => text.fontSize == 12)
          .toList();
      expect(
        labels.length,
        8,
        reason: 'the default story labels all eight of its bars',
      );
      expect(
        labelStyle.fontSize,
        12.0,
        reason: 'the captured bar labels render at 12px (caption1Strong)',
      );
      expect(
        labelStyle.fontWeight,
        theme.typography.caption1Strong.fontWeight,
        reason: 'the captured bar labels render at font-weight 600',
      );
      expect(
        labels.first.fontWeight,
        '600',
        reason: 'guards the line above against a stale capture',
      );
      expect(
        labelStyle.color!.toARGB32(),
        labels.first.fill!.toARGB32(),
        reason:
            'Common.styles.ts:64-70 fills the label with '
            'colorNeutralForeground1, captured as rgb(36, 36, 36)',
      );
    });
  });

  group('FluentVerticalBarChartGeometry.minBarHeight', () {
    test('is ceil(scaled max deviation / 100)', () {
      // plotHeight 295 == 350 - 20 top - 35 bottom; domain [0, 100].
      final yBarScale = _magnitudeScale(domain: <double>[0, 100], span: 295);
      expect(
        FluentVerticalBarChartGeometry.minBarHeight(
          yMin: 0,
          yMax: 100,
          yReferencePoint: 0,
          yBarScale: yBarScale,
        ),
        3,
        reason: 'ceil(295 / 100) == 3, VerticalBarChart.tsx:626-632',
      );
    });

    test('an all-negative dataset measures from yMin only', () {
      final yBarScale = _magnitudeScale(domain: <double>[-100, 0], span: 295);
      expect(
        FluentVerticalBarChartGeometry.minBarHeight(
          yMin: -100,
          yMax: -10,
          yReferencePoint: -10,
          yBarScale: yBarScale,
        ),
        6,
        reason:
            'yMax < 0 takes the |yMin - reference| branch at :627-629: '
            '|-100 - -10| == 90, which the scale maps to 560.5 because a '
            'magnitude is fed to a domain starting at -100 — upstream '
            'extrapolation, reproduced. ceil(560.5 / 100) == 6',
      );
      expect(
        FluentVerticalBarChartGeometry.minBarHeight(
          yMin: -100,
          yMax: -10,
          yReferencePoint: -300,
          yBarScale: yBarScale,
        ),
        9,
        reason:
            'pins the branch itself: |−100 − −300| == 200 maps to 885, so 9, '
            'where the yMax >= 0 arm would take max(290, 200) == 290 and give '
            '12. Upstream only ever passes `_yMax < 0 ? _yMax : 0` (:638), '
            'under which the two arms always agree, so :627-629 is '
            'unreachable-distinct in production',
      );
    });
  });

  group('VerticalBarChart bar rects', () {
    test('quantises small bars and drops zero-height ones', () {
      final bars = _bars(
        ys: <double>[0, 0.4, 1, 50, 100],
        yMin: 0,
        yMax: 100,
        containerHeight: 350,
      );
      expect(
        bars.length,
        4,
        reason:
            'barHeight == 0 renders an empty fragment, '
            'VerticalBarChart.tsx:649-651',
      );
      expect(
        bars.map((FluentVerticalBarRect b) => b.rect.height).toList(),
        <double>[3, 3, 147.5, 295],
        reason: 'heights below minBarHeight 3 snap up, :652-654',
      );
      expect(
        bars.map((FluentVerticalBarRect b) => b.rect.top).toList(),
        <double>[312, 312, 167.5, 20],
        reason:
            'yPoint = H - bottom - adjustedHeight - yBarScale(reference); '
            'H 350, bottom 35, yBarScale(0) 0, so a 3px bar sits at 312',
      );
    });

    test('a negative bar hangs from the baseline', () {
      final bars = _bars(
        ys: <double>[-50],
        yMin: -100,
        yMax: 100,
        containerHeight: 350,
      );
      expect(
        bars.single.isNegative,
        isTrue,
        reason: 'barHeight < 0 sets isHeightNegative at :643',
      );
      expect(
        bars.single.rect.top,
        closeTo(315 - 147.5, 1e-9),
        reason: 'rect.y is the baseline for a negative bar, :668',
      );
      expect(
        bars.single.labelAnchor.dy,
        closeTo(315 - 147.5 + 12, 1e-9),
        reason: 'a negative bar labels 12px below yPoint, :965',
      );
    });
  });

  group('VerticalBarChart domain margin', () {
    test('a string axis centres the band group inside the plot', () {
      final solved = FluentVerticalBarChartGeometry.solveDomainMargin(
        xAxisType: FluentChartAxisType.category,
        uniqueXCount: 7,
        containerWidth: 800,
        margins: const FluentChartMargins(left: 40, right: 20),
        barWidthProp: 'default',
        maxBarWidth: 24,
        innerPadding: 2 / 3,
        outerPadding: 0,
        isOuterPaddingDefined: false,
        mode: null,
        longestLabelWidth: 0,
        sortedXValues: const <Object>[],
      );
      expect(
        solved.barWidth,
        16,
        reason:
            'getBarWidth("default", 24) == min(16, 16) == 16, '
            'utilities.ts:1906',
      );
      // requiredWidth = 16 * (7 + 6 * (2/3) / (1 - 2/3)) == 16 * 19 == 304
      // totalWidth = 800 - 40 - 20 - 16 == 724
      expect(
        solved.domainMargin,
        closeTo(8 + (724 - 304) / 2, 1e-9),
        reason: 'VerticalBarChart.tsx:1006 centres the surplus',
      );
    });

    test('the numeric branch adds half a bar width TWICE', () {
      final solved = FluentVerticalBarChartGeometry.solveDomainMargin(
        xAxisType: FluentChartAxisType.numeric,
        uniqueXCount: 5,
        containerWidth: 800,
        margins: const FluentChartMargins(left: 40, right: 20),
        barWidthProp: 16,
        maxBarWidth: 24,
        innerPadding: 0.5,
        outerPadding: 0,
        isOuterPaddingDefined: false,
        mode: null,
        longestLabelWidth: 0,
        sortedXValues: const <Object>[1, 2, 3, 4, 5],
      );
      expect(
        solved.domainMargin,
        closeTo(8 + solved.barWidth, 1e-9),
        reason:
            'parity: VerticalBarChart.tsx:1055-1056 are two identical '
            '`_domainMargin += _barWidth / 2` lines',
      );
    });

    test('a defined outer padding zeroes the margin', () {
      final solved = FluentVerticalBarChartGeometry.solveDomainMargin(
        xAxisType: FluentChartAxisType.category,
        uniqueXCount: 7,
        containerWidth: 800,
        margins: const FluentChartMargins(left: 40, right: 20),
        barWidthProp: 'default',
        maxBarWidth: 24,
        innerPadding: 2 / 3,
        outerPadding: 0.1,
        isOuterPaddingDefined: true,
        mode: null,
        longestLabelWidth: 0,
        sortedXValues: const <Object>[],
      );
      expect(
        solved.domainMargin,
        0,
        reason: 'VerticalBarChart.tsx:996 sets _domainMargin to 0',
      );
    });
  });

  group('VerticalBarChart colour ramp', () {
    test('interpolates between adjacent stops, not across the whole ramp', () {
      const ramp = <Color>[
        Color(0xFF000000),
        Color(0xFF808080),
        Color(0xFFFFFFFF),
      ];
      expect(
        FluentVerticalBarChartGeometry.colourFor(
          25,
          palette: ramp,
          yMax: 100,
        ).toARGB32(),
        const Color(0xFF404040).toARGB32(),
        reason:
            'domain is [0, 50, 100]; 25 sits halfway into the first segment',
      );
    });

    test('a single-colour palette is constant', () {
      const ramp = <Color>[Color(0xFF123456)];
      expect(
        FluentVerticalBarChartGeometry.colourFor(
          99,
          palette: ramp,
          yMax: 100,
        ).toARGB32(),
        0xFF123456,
        reason: 'increment is 1 for a one-entry ramp, VerticalBarChart.tsx:399',
      );
    });
  });

  group('VerticalBarChart domain margin against Oracle B', () {
    test('reproduces the rotate-labels story band-scale offset', () {
      final story = loadOracleStory(
        'charts-verticalbarchart--vertical-bar-rotate-labels',
      );
      final bars = story.byTag('rect');
      expect(
        bars.length,
        4,
        reason: 'the story draws four bars; a filtered count guard',
      );
      expect(
        bars.every((OracleElement r) => r.width == 16),
        isTrue,
        reason:
            'every bar is 16px wide, so `barWidth` resolved to DEFAULT_BAR_WIDTH',
      );
      // Every bar sits in a `g` with transform="translate(0, 0)", so
      // `0.5 * (bandwidth - barWidth)` is 0 and rect.x IS the band start,
      // which is `margins.left + _domainMargin` (VerticalBarChart.tsx:614).
      final solved = FluentVerticalBarChartGeometry.solveDomainMargin(
        xAxisType: FluentChartAxisType.category,
        uniqueXCount: bars.length,
        containerWidth: story.width,
        margins: _margins,
        barWidthProp: 'default',
        maxBarWidth: 24,
        innerPadding: _defaultInnerPadding,
        outerPadding: 0,
        isOuterPaddingDefined: false,
        mode: null,
        longestLabelWidth: 0,
        sortedXValues: const <Object>[],
      );
      expectOracleNumber(
        'rotate-labels band start',
        bars.first.x!,
        _margins.left! + solved.domainMargin,
      );
      expectOracleNumber(
        'rotate-labels band end',
        bars.last.x! + bars.last.width!,
        story.width - _margins.right! - solved.domainMargin,
      );
    });

    test('clamps to MIN_DOMAIN_MARGIN on the styled story', () {
      final story = loadOracleStory(
        'charts-verticalbarchart--vertical-bar-styled',
      );
      final bars = story.byTag('rect');
      expect(
        bars.length,
        13,
        reason: 'the story draws thirteen bars; a filtered count guard',
      );
      expect(
        bars.every((OracleElement r) => r.width == 20),
        isTrue,
        reason: 'the story sets barWidth to 20',
      );
      final solved = FluentVerticalBarChartGeometry.solveDomainMargin(
        xAxisType: FluentChartAxisType.category,
        uniqueXCount: bars.length,
        containerWidth: story.width,
        margins: _margins,
        barWidthProp: 20,
        maxBarWidth: 24,
        innerPadding: _defaultInnerPadding,
        outerPadding: 0,
        isOuterPaddingDefined: false,
        mode: null,
        longestLabelWidth: 0,
        sortedXValues: const <Object>[],
      );
      expect(
        solved.domainMargin,
        8,
        reason:
            'reqWidth 20 * 37 == 740 exceeds totalWidth 724, so :1005 never '
            'fires and the margin stays at MIN_DOMAIN_MARGIN',
      );
      // rect.x here is the band start; the `g` carries the -0.216216 half-gap.
      expectOracleNumber(
        'styled band start',
        bars.first.x!,
        _margins.left! + solved.domainMargin,
      );
    });

    test('minBarHeight over the styled story plot height is 4', () {
      final story = loadOracleStory(
        'charts-verticalbarchart--vertical-bar-styled',
      );
      final bars = story.byTag('rect');
      expect(bars.length, 13, reason: 'a filtered count guard');
      final plotHeight = story.height - _margins.top! - _margins.bottom!;
      expectOracleNumber(
        'styled plot height == tallest bar',
        bars
            .map((OracleElement r) => r.height!)
            .reduce((double a, double b) => a > b ? a : b),
        plotHeight,
      );
      expect(
        FluentVerticalBarChartGeometry.minBarHeight(
          yMin: 0,
          yMax: 100,
          yReferencePoint: 0,
          yBarScale: _magnitudeScale(
            domain: <double>[0, 100],
            span: plotHeight,
          ),
        ),
        4,
        reason: 'ceil(345 / 100) == 4 over the story real plot height',
      );
    });
  });
}
