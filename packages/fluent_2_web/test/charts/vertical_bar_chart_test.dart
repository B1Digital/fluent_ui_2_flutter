import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/axis/axis_types.dart';
import 'package:fluent_2_web/src/charts/cartesian/cartesian_chart.dart';
import 'package:fluent_2_web/src/charts/cartesian/cartesian_layout.dart';
import 'package:fluent_2_web/src/charts/cartesian/cartesian_series_delegate.dart';
import 'package:fluent_2_web/src/charts/chrome/chart_popover.dart';
import 'package:fluent_2_web/src/charts/internal/chart_colors.dart';
import 'package:fluent_2_web/src/charts/internal/chart_text_measurer.dart';
import 'package:fluent_2_web/src/charts/internal/chart_text_styles.dart';
import 'package:fluent_2_web/src/charts/internal/chart_utils.dart';
import 'package:fluent_2_web/src/charts/internal/d3/scale.dart';
import 'package:fluent_2_web/src/charts/internal/d3/scale_band.dart';
import 'package:fluent_2_web/src/charts/internal/d3/scale_linear.dart';
import 'package:fluent_2_web/src/charts/model/bar_data.dart';
import 'package:fluent_2_web/src/charts/model/chart_common.dart';
import 'package:fluent_2_web/src/charts/model/chart_value.dart';
import 'package:fluent_2_web/src/charts/vertical_bar_chart.dart';
import 'package:fluent_2_web/src/charts/vertical_bar_chart_style.dart';
import 'package:flutter/gestures.dart';
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
    // 6 above the top and 12 below the FOOT, VerticalBarChart.tsx:658-663
    // and :965 — `yPoint` is the rect's bottom edge for a negative bar.
    final labelDy = isNegative ? adjusted + 12.0 : -6.0;
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
        closeTo(315 - 147.5 + 73.75 + 12, 1e-9),
        reason:
            'a negative bar labels 12px below yPoint, and :658-663 makes '
            "yPoint the bar's foot rather than its top",
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

  group('FluentVerticalBarChartDelegate', () {
    test(
      'a string x axis offsets the group by half the leftover bandwidth',
      () {
        final delegate = _stringDelegate(
          categories: <String>['a', 'b', 'c'],
          ys: <double>[10, 20, 30],
        );
        final ctx = _bandContext(<String>['a', 'b', 'c'], width: 800);
        final bars = delegate.barsFor(ctx, _layout(width: 800, height: 350));
        expect(
          bars.length,
          3,
          reason: 'a count guard before the geometry assertion',
        );
        expect(
          bars.first.rect.left,
          closeTo(
            ctx.xScale('a')! + 0.5 * (ctx.xScale.bandwidth - kDefaultBarWidth),
            1e-9,
          ),
          reason:
              'VerticalBarChart.tsx:722-725 translates the whole bar group by '
              '0.5 * (bandwidth - _barWidth)',
        );
      },
    );

    test('a numeric x axis centres the bar on its scale value', () {
      final delegate = _numericDelegate(
        xs: <double>[1, 2, 3],
        ys: <double>[10, 20, 30],
      );
      final ctx = _linearContext(width: 800);
      final bars = delegate.barsFor(ctx, _layout(width: 800, height: 350));
      expect(bars.length, 3, reason: 'a count guard');
      expect(
        bars.first.rect.left,
        closeTo(ctx.xScale(1)! - kDefaultBarWidth / 2, 1e-9),
        reason: 'VerticalBarChart.tsx:656 subtracts _barWidth / 2',
      );
    });

    test('bar labels sit 6px above a positive bar and 12px below a negative '
        'one', () {
      final delegate = _numericDelegate(
        xs: <double>[1, 2],
        ys: <double>[50, -50],
      );
      final bars = delegate.barsFor(
        _linearContext(width: 800),
        _layout(width: 800, height: 350),
      );
      expect(bars.length, 2, reason: 'a count guard');
      expect(
        bars[0].labelAnchor.dy,
        closeTo(bars[0].rect.top - 6, 1e-9),
        reason: 'VerticalBarChart.tsx:965 uses yPoint - 6 for a positive bar',
      );
      expect(
        bars[1].labelAnchor.dy,
        closeTo(bars[1].rect.bottom + 12, 1e-9),
        reason:
            'VerticalBarChart.tsx:658-663 sets yPoint to '
            '`containerHeight - bottom + adjustedBarHeight - yBarScale(ref)` '
            'for a negative bar, which is the rect BOTTOM, and :965 then adds '
            '12 to it — pinned by three Oracle B stories in the group below',
      );
    });

    test('the overlaid line centres on the band for a string axis', () {
      final delegate = _stringDelegateWithLine(
        categories: <String>['a', 'b'],
        ys: <double>[10, 20],
        lineYs: <double>[5, 15],
      );
      final ctx = _bandContext(<String>['a', 'b'], width: 800);
      final dots = delegate.lineDotsFor(ctx);
      expect(dots.length, 2, reason: 'a count guard');
      expect(
        dots.first.dx,
        closeTo(ctx.xScale('a')! + 0.5 * ctx.xScale.bandwidth, 1e-9),
        reason: 'VerticalBarChart.tsx:184 adds 0.5 * bandwidth',
      );
      expect(
        dots.first.dy,
        closeTo(ctx.yScalePrimary(5)!, 1e-9),
        reason: 'VerticalBarChart.tsx:186 reads the primary y position scale',
      );
      expect(
        delegate.linePathFor(ctx),
        isNotNull,
        reason: 'both points carry lineData, so the path exists',
      );
    });

    test('a dimmed bar keeps its rect but loses its label', () {
      final delegate = _numericDelegate(
        xs: <double>[1, 2],
        ys: <double>[50, 60],
        legends: <String>['a', 'b'],
        selectedLegends: <String>['a'],
      );
      final bars = delegate.barsFor(
        _linearContext(width: 800),
        _layout(width: 800, height: 350),
      );
      expect(bars.length, 2, reason: 'a count guard');
      expect(
        bars[1].opacity,
        0.1,
        reason: 'VerticalBarChart.tsx:687 dims a non-highlighted bar',
      );
      expect(
        delegate.shouldPaintLabel(bars[1]),
        isFalse,
        reason:
            'VerticalBarChart.tsx:950 suppresses the label when the legend is '
            'neither highlighted nor unhighlighted-everywhere',
      );
      expect(
        delegate.shouldPaintLabel(bars[0]),
        isTrue,
        reason: 'the selected legend keeps its label',
      );
    });

    test('labels vanish once the bar is narrower than 16px', () {
      final delegate = _numericDelegate(
        xs: <double>[1],
        ys: <double>[50],
        barWidth: 15,
      );
      final bars = delegate.barsFor(
        _linearContext(width: 800),
        _layout(width: 800, height: 350),
      );
      expect(bars.length, 1, reason: 'a count guard');
      expect(
        delegate.shouldPaintLabel(bars.single),
        isFalse,
        reason: 'VerticalBarChart.tsx:950 tests _barWidth < 16',
      );
    });

    test('hideLabels suppresses every label', () {
      final delegate = _delegateOver(const <FluentVerticalBarChartDataPoint>[
        FluentVerticalBarChartDataPoint(x: 1, y: 50),
      ], hideLabels: true);
      final bars = delegate.barsFor(
        _linearContext(width: 800),
        _layout(width: 800, height: 350),
      );
      expect(bars.length, 1, reason: 'a count guard');
      expect(
        delegate.shouldPaintLabel(bars.single),
        isFalse,
        reason: 'VerticalBarChart.tsx:950 short-circuits on props.hideLabels',
      );
    });

    test('a zero-height bar is absent, not zero-height', () {
      final delegate = _numericDelegate(
        xs: <double>[1, 2],
        ys: <double>[0, 50],
      );
      final bars = delegate.barsFor(
        _linearContext(width: 800),
        _layout(width: 800, height: 350),
      );
      expect(
        bars.map((FluentVerticalBarRect b) => b.index).toList(),
        <int>[1],
        reason:
            'VerticalBarChart.tsx:648-651 returns an empty fragment, so the '
            'bar never reaches the DOM',
      );
    });

    test('a hit region carries the bar rect and the composed aria label', () {
      final delegate = _delegateOver(const <FluentVerticalBarChartDataPoint>[
        FluentVerticalBarChartDataPoint(x: 1, y: 50, legend: 'a'),
      ]);
      final ctx = _linearContext(width: 800);
      final layout = _layout(width: 800, height: 350);
      final regions = delegate.buildHitRegions(ctx, layout);
      expect(regions.length, 1, reason: 'a count guard');
      expect(
        regions.single.bounds,
        delegate.barsFor(ctx, layout).single.rect,
        reason: 'the region a user hovers is the rect that was painted',
      );
      expect(
        regions.single.semanticsLabel,
        '1. a, 50.0.',
        reason: 'VerticalBarChart.tsx:936-938 composes `x. legend, y.`',
      );
    });
  });

  group('FluentVerticalBarChartDelegate under forced colours', () {
    _RecordingCanvas paint({required bool isHighContrast}) {
      final delegate = _stringDelegateWithLine(
        categories: <String>['a', 'b'],
        ys: <double>[10, 20],
        lineYs: <double>[5, 15],
        isHighContrast: isHighContrast,
      );
      final canvas = _RecordingCanvas();
      delegate.paintSeries(
        canvas,
        _bandContext(<String>['a', 'b'], width: 800),
        _layout(width: 800, height: 350),
        delegate.colors,
      );
      return canvas;
    }

    // The alpha channel carries the legend dimming, which the tests above
    // already pin, so the flattening assertions compare the RGB triple only.
    int rgb(Color colour) => colour.toARGB32() & 0x00FFFFFF;

    final style = resolveFluentVerticalBarChartStyle(_delegateTheme);

    test('an ordinary theme keeps the series and line colours', () {
      final canvas = paint(isHighContrast: false);
      expect(canvas.rectFills.length, 2, reason: 'a count guard');
      expect(
        rgb(canvas.rectFills.first),
        rgb(
          FluentVerticalBarChartGeometry.colourFor(
            10,
            palette: style.palette!.resolve(<WidgetState>{})!,
            yMax: 20,
          ),
        ),
        reason: 'flattenMark is the identity outside high contrast',
      );
      expect(
        rgb(canvas.circleStrokes.first),
        rgb(style.lineColor!.resolve(<WidgetState>{})!),
        reason: 'and so is flattenMarkStroke on the line dot halo',
      );
    });

    test('high contrast flattens the bars and the line', () {
      final canvas = paint(isHighContrast: true);
      expect(canvas.rectFills.length, 2, reason: 'a count guard');
      expect(
        canvas.rectFills.map(rgb).toSet(),
        <int>{rgb(_canvasTextColour)},
        reason:
            'design spec section 5.3: a forced-colours browser rewrites every '
            'series fill to CanvasText, so FluentChartColors.flattenMark must '
            'be on every bar fill',
      );
      expect(
        canvas.pathStrokes.map(rgb).toSet(),
        <int>{rgb(_canvasTextColour)},
        reason: 'the overlaid line is a series mark and flattens with them',
      );
      expect(
        canvas.circleStrokes.map(rgb).toSet(),
        <int>{rgb(_canvasColour)},
        reason:
            'FluentChartColors.flattenMarkStroke sends the dot halo to Canvas '
            'instead, which is the only thing keeping the dot from '
            'disappearing into the flattened line beneath it',
      );
    });
  });

  group('FluentVerticalBarChartDelegate against Oracle B', () {
    // `VerticalBarChartBasic`'s data, recovered below from the captured tick
    // positions and bar heights.
    const storyXs = <double>[
      0,
      10000,
      25000,
      40000,
      52000,
      68000,
      80000,
      92000,
    ];
    const storyYs = <double>[
      10000,
      50000,
      30000,
      13000,
      43000,
      30000,
      20000,
      45000,
    ];

    /// The eight bars of a VerticalBarChart story, paired with their labels.
    List<(OracleElement, OracleElement)> barsAndLabels(OracleStory story) {
      final out = <(OracleElement, OracleElement)>[];
      for (final rect in story.byTag('rect')) {
        final parent = story.parentOf(rect);
        if (parent == null || parent.tag != 'g') {
          continue;
        }
        final labels = story
            .childrenOf(parent)
            .where((OracleElement e) => e.tag == 'text')
            .toList();
        if (labels.length == 1) {
          out.add((rect, labels.single));
        }
      }
      return out;
    }

    test('the default story x scale is the numeric domain margin', () {
      final story = loadOracleStory(
        'charts-verticalbarchart--vertical-bar-default',
      );
      // The x-axis tick labels carry no `x` attribute; the y-axis ones sit at
      // x = -10, which is what separates them.
      final zeroTick = story.soleElement(
        'text',
        where: (OracleElement e) => e.text == '0' && e.x == null,
      );
      final group = story.parentOf(zeroTick)!;
      expectOracleNumber(
        'x scale range start',
        _margins.left! + kMinDomainMargin + kDefaultBarWidth,
        group.translate!.dx - story.crispOffset,
      );
    });

    test('reproduces every bar rect of the default story', () {
      final story = loadOracleStory(
        'charts-verticalbarchart--vertical-bar-default',
      );
      final captured = barsAndLabels(story);
      expect(captured.length, 8, reason: 'the story draws eight bars');
      final delegate = _delegateOver(<FluentVerticalBarChartDataPoint>[
        for (var i = 0; i < storyXs.length; i++)
          FluentVerticalBarChartDataPoint(x: storyXs[i], y: storyYs[i]),
      ]);
      final ctx = FluentCartesianChildContext(
        // `.nice()` rounds the 0..92000 data extent up to 0..100000
        // (VerticalBarChart.tsx:594-596); the range is the one the test above
        // recovers from the captured ticks.
        xScale: ScaleLinear()
          ..domainOf(<double>[0, 100000])
          ..rangeOf(<double>[
            _margins.left! + kMinDomainMargin + kDefaultBarWidth,
            story.width - _margins.right! - kMinDomainMargin - kDefaultBarWidth,
          ]),
        yScalePrimary: _positionScale(containerHeight: story.height),
        containerWidth: story.width,
        containerHeight: story.height,
      );
      final bars = delegate.barsFor(
        ctx,
        _layout(width: story.width, height: story.height),
      );
      expect(bars.length, 8, reason: 'a count guard');
      for (var i = 0; i < bars.length; i++) {
        expectOracleRect('bar $i', captured[i].$1.rect, bars[i].rect);
      }
    });

    test('reproduces the default story bar label anchors', () {
      final story = loadOracleStory(
        'charts-verticalbarchart--vertical-bar-default',
      );
      final captured = barsAndLabels(story);
      expect(captured.length, 8, reason: 'a count guard');
      for (final (rect, label) in captured) {
        expectOracleOffset(
          'label anchor over ${label.text}',
          Offset(label.x!, label.y!),
          Offset(rect.rect.center.dx, rect.rect.top - 6),
        );
      }
    });

    test('a negative bar anchors its label below the bar, not below the '
        'baseline', () {
      // The mixed-sign story is already covered by the style group above; this
      // pins the all-negative one, where EVERY bar hangs from the baseline.
      final story = loadOracleStory(
        'charts-verticalbarchart--vertical-bar-all-negative',
      );
      final captured = barsAndLabels(story);
      expect(captured.length, 8, reason: 'the story draws eight bars');
      for (final (rect, label) in captured) {
        expectOracleOffset(
          'label anchor over ${label.text}',
          Offset(label.x!, label.y!),
          Offset(rect.rect.center.dx, rect.rect.bottom + 12),
        );
      }
    });
  });

  group('FluentVerticalBarChart', () {
    Future<void> pump(WidgetTester tester, Widget chart) => tester.pumpWidget(
      FluentApp(
        theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
        home: Center(child: SizedBox(width: 800, height: 350, child: chart)),
      ),
    );

    testWidgets('the line legend is unshifted to the front of the legend row', (
      tester,
    ) async {
      await pump(
        tester,
        FluentVerticalBarChart(
          data: _pointsWithLine(),
          lineLegendText: 'Trend',
        ),
      );
      final legends = tester
          .widget<FluentCartesianChart>(find.byType(FluentCartesianChart))
          .legends;
      expect(
        legends.first.title,
        'Trend',
        reason: 'VerticalBarChart.tsx:862 unshifts the line legend',
      );
      expect(
        legends.first.isLineLegendInBarChart,
        isTrue,
        reason: 'a line legend swatch is 4px tall, Legends.tsx:296',
      );
    });

    testWidgets('leaving a bar does not close the popover', (tester) async {
      await pump(tester, FluentVerticalBarChart(data: _points(), barWidth: 60));
      final g = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await g.addPointer(location: Offset.zero);
      addTearDown(g.removePointer);
      await g.moveTo(tester.getCenter(find.byType(FluentCartesianChart)));
      await tester.pumpAndSettle();
      expect(
        find.byType(FluentChartPopover),
        findsOneWidget,
        reason: 'a count guard: the hover must have landed on a bar first',
      );
      await g.moveTo(
        tester.getTopLeft(find.byType(FluentCartesianChart)) +
            const Offset(2, 2),
      );
      await tester.pumpAndSettle();
      expect(
        find.byType(FluentChartPopover),
        findsOneWidget,
        reason:
            'parity: _onBarLeave is a no-op at VerticalBarChart.tsx:496-498; '
            'only leaving the whole chart closes the popover',
      );
    });

    testWidgets('an all-zero dataset renders the empty state', (tester) async {
      await pump(
        tester,
        const FluentVerticalBarChart(
          data: <FluentVerticalBarChartDataPoint>[
            FluentVerticalBarChartDataPoint(x: 'a', y: 0),
            FluentVerticalBarChartDataPoint(x: 'b', y: 0),
          ],
        ),
      );
      expect(
        find.byType(FluentCartesianChart),
        findsNothing,
        reason:
            'VerticalBarChart.tsx:1076-1078 treats an all-zero, lineless '
            'dataset as empty',
      );
    });

    testWidgets('the semantic title names the bars and the line', (
      tester,
    ) async {
      await pump(
        tester,
        FluentVerticalBarChart(
          data: _pointsWithLine(),
          chartTitle: 'Revenue',
          lineLegendText: 'Trend',
        ),
      );
      expect(
        tester
            .widget<FluentCartesianChart>(find.byType(FluentCartesianChart))
            .props
            .chartTitleForSemantics,
        'Revenue. Vertical bar chart with 3 bars and 1 line. ',
        reason: 'VerticalBarChart.tsx:1066-1074',
      );
    });
  });

  group('FluentVerticalBarChart against Oracle B', () {
    // The only captured VerticalBarChart story that carries an overlaid line
    // AND a `lineLegendText`, so it is the only one whose legend row can show
    // where the line legend landed.
    final story = loadOracleStory(
      'charts-verticalbarchart--vertical-bar-secondary-y-axis',
    );
    // The last two rows of this capture sit at (-16, -16) with a 0x0 box: they
    // are the overflow-menu items the legend row could not fit, which the
    // overflow container parks off screen. Only the laid-out rows carry
    // geometry worth asserting.
    final swatches = story
        .boxes('fui-legend__rect')
        .where((box) => box.rect.width > 0)
        .toList(growable: false);
    final labels = story
        .boxes('fui-legend__text')
        .where((box) => box.rect.width > 0)
        .toList(growable: false);

    test('the captured legend row leads with the line legend', () {
      expect(
        swatches.length,
        greaterThan(1),
        reason:
            'a count guard: without at least two swatches the ordering below '
            'is vacuous',
      );
      expect(
        labels.first.text,
        'just line',
        reason:
            'the story names its line legend `just line` and upstream '
            'unshifts it (VerticalBarChart.tsx:862), so it is captured first '
            'in DOM order — which is what '
            'FluentVerticalBarChart._legends reproduces with insert(0, …)',
      );
    });

    test('the captured line swatch is short and the bar swatches square', () {
      expectOracleNumber('line swatch width', 14, swatches.first.rect.width);
      expectOracleNumber(
        'line swatch height',
        // 4px of `isLineLegendInBarChart` content plus the 1px border on each
        // edge that also widens the 12px square to 14 (`Legends.tsx:296`,
        // `useLegendsStyles.styles.ts`).
        6,
        swatches.first.rect.height,
      );
      for (final swatch in swatches.skip(1)) {
        expectOracleNumber('bar swatch height', 14, swatch.rect.height);
      }
    });
  });
}

/// Three bars, one legend each, no overlaid line.
List<FluentVerticalBarChartDataPoint> _points() =>
    const <FluentVerticalBarChartDataPoint>[
      FluentVerticalBarChartDataPoint(x: 'a', y: 10, legend: 'Alpha'),
      FluentVerticalBarChartDataPoint(x: 'b', y: 40, legend: 'Beta'),
      FluentVerticalBarChartDataPoint(x: 'c', y: 25, legend: 'Gamma'),
    ];

/// [_points] with a line value on every bar, which is what makes
/// `_isHavingLine` true upstream (`VerticalBarChart.tsx:1091`).
List<FluentVerticalBarChartDataPoint> _pointsWithLine() =>
    const <FluentVerticalBarChartDataPoint>[
      FluentVerticalBarChartDataPoint(
        x: 'a',
        y: 10,
        legend: 'Alpha',
        lineData: FluentBarLineDatum(y: 8),
      ),
      FluentVerticalBarChartDataPoint(
        x: 'b',
        y: 40,
        legend: 'Beta',
        lineData: FluentBarLineDatum(y: 30),
      ),
      FluentVerticalBarChartDataPoint(
        x: 'c',
        y: 25,
        legend: 'Gamma',
        lineData: FluentBarLineDatum(y: 20),
      ),
    ];

// ---------------------------------------------------------------------------
// The delegate.
// ---------------------------------------------------------------------------

/// Records only what the delegate's fills and strokes carry.
class _RecordingCanvas implements Canvas {
  final List<Color> rectFills = <Color>[];
  final List<Color> pathStrokes = <Color>[];
  final List<Color> circleFills = <Color>[];
  final List<Color> circleStrokes = <Color>[];
  final List<double> circleRadii = <double>[];

  @override
  void drawRect(Rect rect, Paint paint) => rectFills.add(paint.color);

  @override
  void drawRRect(RRect rrect, Paint paint) => rectFills.add(paint.color);

  @override
  void drawPath(Path path, Paint paint) => pathStrokes.add(paint.color);

  @override
  void drawCircle(Offset c, double radius, Paint paint) {
    circleRadii.add(radius);
    (paint.style == PaintingStyle.stroke ? circleStrokes : circleFills).add(
      paint.color,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// The single measurer the whole subtree shares, as the chart-invariants gate
/// requires.
final _measurer = FluentChartTextMeasurer();

final _delegateTheme = FluentThemeData.light(
  fontPlatform: FluentFontPlatform.web,
);

const _placeholderColour = Color(0xFF010203);
const _canvasTextColour = Color(0xFFFFFFFF);
const _canvasColour = Color(0xFF000000);

/// The ten-slot colour set, so `isHighContrast` can be flipped without a
/// second [FluentThemeData].
FluentChartColors _colours({bool isHighContrast = false}) => FluentChartColors(
  axisText: _canvasTextColour,
  axisTick: _placeholderColour,
  axisTitle: _placeholderColour,
  gridLine: _placeholderColour,
  markStroke: _placeholderColour,
  surface: _canvasColour,
  popoverSurface: _placeholderColour,
  tooltipSurface: _placeholderColour,
  legendDimmed: _placeholderColour,
  isHighContrast: isHighContrast,
);

FluentVerticalBarChartDelegate _delegateOver(
  List<FluentVerticalBarChartDataPoint> points, {
  Object? barWidthProp,
  List<String> selectedLegends = const <String>[],
  String? activeLegend,
  String? lineLegendText,
  Object? activeXDataPoint,
  bool isHighContrast = false,
  bool hideLabels = false,
}) => FluentVerticalBarChartDelegate(
  points: points,
  style: resolveFluentVerticalBarChartStyle(_delegateTheme),
  colors: _colours(isHighContrast: isHighContrast),
  measurer: _measurer,
  textStyles: FluentChartTextStyles.of(_delegateTheme),
  selectedLegends: selectedLegends,
  activeLegend: activeLegend,
  activeXDataPoint: activeXDataPoint,
  barWidthProp: barWidthProp,
  hideLabels: hideLabels,
  lineLegendText: lineLegendText,
);

FluentVerticalBarChartDelegate _stringDelegate({
  required List<String> categories,
  required List<double> ys,
}) => _delegateOver(<FluentVerticalBarChartDataPoint>[
  for (var i = 0; i < categories.length; i++)
    FluentVerticalBarChartDataPoint(x: categories[i], y: ys[i]),
]);

FluentVerticalBarChartDelegate _numericDelegate({
  required List<double> xs,
  required List<double> ys,
  List<String>? legends,
  List<String> selectedLegends = const <String>[],
  Object? barWidth,
  bool isHighContrast = false,
}) => _delegateOver(
  <FluentVerticalBarChartDataPoint>[
    for (var i = 0; i < xs.length; i++)
      FluentVerticalBarChartDataPoint(x: xs[i], y: ys[i], legend: legends?[i]),
  ],
  barWidthProp: barWidth,
  selectedLegends: selectedLegends,
  isHighContrast: isHighContrast,
);

FluentVerticalBarChartDelegate _stringDelegateWithLine({
  required List<String> categories,
  required List<double> ys,
  required List<double> lineYs,
  String? lineLegendText,
  bool isHighContrast = false,
}) => _delegateOver(
  <FluentVerticalBarChartDataPoint>[
    for (var i = 0; i < categories.length; i++)
      FluentVerticalBarChartDataPoint(
        x: categories[i],
        y: ys[i],
        lineData: FluentBarLineDatum(y: lineYs[i]),
      ),
  ],
  lineLegendText: lineLegendText,
  isHighContrast: isHighContrast,
);

/// The primary y position scale, which only the overlaid line reads: the bars
/// build their own magnitude scale (`VerticalBarChart.tsx:584-586`).
Scale _positionScale({required double containerHeight, double yMax = 100}) =>
    ScaleLinear()
      ..domainOf(<double>[0, yMax])
      ..rangeOf(<double>[containerHeight - _margins.bottom!, _margins.top!]);

/// The band x scale `_getScales` builds for a string axis
/// (`VerticalBarChart.tsx:608-616`), at [kMinDomainMargin].
FluentCartesianChildContext _bandContext(
  List<String> categories, {
  required double width,
  double containerHeight = 350,
}) => FluentCartesianChildContext(
  xScale: ScaleBand()
    ..domainOf(categories.cast<Object>())
    ..rangeOf(<double>[
      _margins.left! + kMinDomainMargin,
      width - _margins.right! - kMinDomainMargin,
    ])
    ..paddingInner(_defaultInnerPadding),
  yScalePrimary: _positionScale(containerHeight: containerHeight),
  containerWidth: width,
  containerHeight: containerHeight,
);

/// The linear x scale `_getScales` builds for a numeric axis
/// (`VerticalBarChart.tsx:590-596`).
FluentCartesianChildContext _linearContext({
  required double width,
  double xMin = 1,
  double xMax = 3,
  double containerHeight = 350,
  double domainMargin = kMinDomainMargin,
}) => FluentCartesianChildContext(
  xScale: ScaleLinear()
    ..domainOf(<double>[xMin, xMax])
    ..rangeOf(<double>[
      _margins.left! + domainMargin,
      width - _margins.right! - domainMargin,
    ]),
  yScalePrimary: _positionScale(containerHeight: containerHeight),
  containerWidth: width,
  containerHeight: containerHeight,
);

FluentCartesianLayout _layout({
  required double width,
  required double height,
  FluentChartMargins margins = _margins,
}) => FluentCartesianLayout.resolve(
  size: Size(width, height),
  margins: margins,
  xAxisLabelReserve: 0,
  isRtl: false,
  startFromX: 0,
);
