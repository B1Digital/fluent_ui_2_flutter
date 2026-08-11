import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/axis/axis_types.dart';
import 'package:fluent_2_web/src/charts/cartesian/cartesian_chart.dart';
import 'package:fluent_2_web/src/charts/cartesian/cartesian_chart_props.dart';
import 'package:fluent_2_web/src/charts/cartesian/cartesian_layout.dart';
import 'package:fluent_2_web/src/charts/cartesian/cartesian_painter.dart';
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
import 'package:fluent_2_web/src/charts/model/line_options.dart';
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

  // `_createLine` destructures `lineLegendColor = tokens
  // .colorPaletteYellowBackground1` once (`VerticalBarChart.tsx:165`) and
  // spends it on BOTH the polyline (`:214`) and every dot ring (`:244`). The
  // port used to spend `props.lineLegendColor` on the legend swatch alone, so
  // `charts-verticalbarchart--vertical-bar-default` — which asks for brown —
  // painted a #FFFEF5 line the capture strokes rgb(165, 42, 42).
  group('FluentVerticalBarChartDelegate line ink', () {
    const brown = Color(0xFFA52A2A);
    final style = resolveFluentVerticalBarChartStyle(_delegateTheme);

    _RecordingCanvas paint({
      Color? lineLegendColor,
      FluentLineOptions? lineOptions,
    }) {
      final delegate = _stringDelegateWithLine(
        categories: <String>['a', 'b'],
        ys: <double>[10, 20],
        lineYs: <double>[5, 15],
        lineLegendColor: lineLegendColor,
        lineOptions: lineOptions,
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

    test('lineLegendColor strokes the polyline and the dot rings', () {
      final canvas = paint(lineLegendColor: brown);
      expect(
        canvas.pathStrokes.map(_argb).toList(),
        <int>[_argb(brown)],
        reason:
            'stroke={lineLegendColor} on the line path, '
            'VerticalBarChart.tsx:214',
      );
      expect(
        canvas.circleStrokes.map(_argb).toSet(),
        <int>{_argb(brown)},
        reason:
            'and on every dot, VerticalBarChart.tsx:244 — one destructured '
            'value, two consumers',
      );
    });

    test('no lineLegendColor leaves the line on its own yellow token', () {
      expect(
        paint().pathStrokes.map(_argb).toList(),
        <int>[_argb(style.lineColor!.resolve(<WidgetState>{})!)],
        reason:
            'the default is colorPaletteYellowBackground1 '
            '(VerticalBarChart.tsx:165), which is NOT the '
            'colorPaletteYellowForeground1 the legend swatch falls back to '
            '(`:826`)',
      );
    });

    test('lineOptions.lineBorderWidth runs a halo under the line', () {
      final canvas = paint(
        lineLegendColor: brown,
        lineOptions: const FluentLineOptions(lineBorderWidth: 2),
      );
      expect(
        canvas.pathStrokeWidths,
        <double>[7, 3],
        reason:
            'the halo is `3 + lineBorderWidth * 2` and is pushed FIRST so the '
            'line draws over it, VerticalBarChart.tsx:190-215. Oracle B '
            'records exactly this pair on the Default story: a 7px '
            'rgb(255, 255, 255) path under a 3px rgb(165, 42, 42) one',
      );
      expect(
        _argb(canvas.pathStrokes.first),
        _argb(style.lineDotFillColor!.resolve(<WidgetState>{})!),
        reason:
            'classes.lineBorder is stroke: tokens.colorNeutralBackground1 '
            '(useVerticalBarChartStyles.styles.ts:36-41), the same token the '
            'dot fill takes',
      );
    });

    test('no lineOptions draws the line alone', () {
      expect(
        paint(lineLegendColor: brown).pathStrokeWidths,
        <double>[3],
        reason:
            'the halo is gated on `lineBorderWidth > 0`, '
            'VerticalBarChart.tsx:190',
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

    testWidgets('the chartAxisTypeOf fallthrough is unreachable from a '
        'mounted chart', (tester) async {
      // `chartAxisTypeOf`'s `_` arm (model/chart_value.dart:34) reports a date
      // for anything that is neither a String nor a num, reproducing the
      // `default:` at utilities.ts:1693. `FluentVerticalBarChartProps.xAxisType`
      // (vertical_bar_chart.dart:674) is this chart's only route into that arm,
      // and it reads `points.first.x` — so the datum's own constructor assert
      // is what decides whether the arm can ever be handed a non-date.
      expect(
        chartAxisTypeOf(const <int>[]),
        FluentChartAxisType.date,
        reason: 'utilities.ts:1693 `default: return XAxisTypes.DateAxis`.',
      );
      expect(
        () => FluentVerticalBarChartDataPoint(x: const <int>[], y: 1),
        throwsA(isA<AssertionError>()),
        reason:
            'types/DataPoint.ts:170 `number | string | Date` — the value the '
            'arm above would mislabel cannot be built into a datum at all, so '
            'it never reaches vertical_bar_chart.dart:674.',
      );
      await pump(
        tester,
        FluentVerticalBarChart(
          data: <FluentVerticalBarChartDataPoint>[
            // Two bars, because one is enough to type the axis but not to draw
            // a band; the heights are any two non-zero values, which is all
            // VerticalBarChart.tsx:1076-1078 asks to avoid the empty state.
            FluentVerticalBarChartDataPoint(x: DateTime.utc(2024), y: 1),
            FluentVerticalBarChartDataPoint(x: DateTime.utc(2024, 2), y: 2),
          ],
        ),
      );
      expect(
        tester
            .widget<FluentCartesianChart>(find.byType(FluentCartesianChart))
            .delegate
            .xAxisType,
        FluentChartAxisType.date,
        reason:
            'the arm stays reachable for a real DateTime, which is the only '
            'kind of value the guard admits into it.',
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

  // The gate on `_getDomainMargins` reaching the shell at all
  // (`CartesianChart.tsx:195`). Every assertion above this group builds its own
  // child context by hand, so all of them pass with
  // `FluentVerticalBarChartGeometry.solveDomainMargin` uncalled from `lib/`,
  // which is what it was for four waves.
  group('FluentVerticalBarChartDelegate domain-margin wiring', () {
    // `charts-verticalbarchart--vertical-bar-dynamic` is the only captured
    // VerticalBarChart story whose numeric bar width is NOT the 16px default:
    // it is 4, which only `calculateAppropriateBarWidth` produces
    // (`VerticalBarChart.tsx:1045-1053`). Recovered below from the capture,
    // whose x scale is `[0, 80] -> [52, 618]` — eight ticks of 10 at
    // `translate(52.5,0)` … `translate(618.5,0)`.
    const dynamicXs = <double>[35, 4, 1, 71, 72];
    // The y values only order the bars; the story sets `yMaxValue: 100`, which
    // the delegate has no hook for, so bar HEIGHTS are deliberately not
    // asserted here — [barsFor]'s heights are pinned by the default-story test
    // above.
    const dynamicYs = <double>[51, 9, 10, 8, 72];

    /// The `[rangeStart, rangeEnd]` of [story]'s x axis, read off the domain
    /// path `M<x0+crisp>,6V<crisp>H<x1+crisp>V6` (`d3-axis/src/axis.js:80`).
    (double, double) xRangeOf(OracleStory story) {
      final domainPath = story.soleElement(
        'path',
        where: (element) =>
            (element.d ?? '').contains('V${story.crispOffset}H'),
      );
      final numbers = svgPathNumbers(domainPath.d!);
      // The path emits x0, 6, crisp, x1, 6, so index 3 is the far end.
      return (numbers[0] - story.crispOffset, numbers[3] - story.crispOffset);
    }

    test('a numeric axis widens the shell margins by the solved margin', () {
      final story = loadOracleStory(
        'charts-verticalbarchart--vertical-bar-dynamic',
      );
      final (rangeStart, rangeEnd) = xRangeOf(story);
      final solved = _numericDelegate(
        xs: dynamicXs,
        ys: dynamicYs,
      ).domainMargins(story.width, _margins);
      expect(
        solved,
        isNotNull,
        reason:
            'CartesianChart.tsx:195 uses the plain margins when getDomainMargins '
            'is absent, so a null here is the shell laying the bars out with no '
            'domain margin at all',
      );
      expectOracleNumber('dynamic x range start', rangeStart, solved!.left!);
      expectOracleNumber(
        'dynamic x range end',
        rangeEnd,
        story.width - solved.right!,
      );
      expect(
        solved.top,
        _margins.top,
        reason:
            'VerticalBarChart.tsx:1060-1063 spreads the incoming margins and '
            'replaces only left and right',
      );
      expect(
        solved.bottom,
        _margins.bottom,
        reason: 'the same spread at VerticalBarChart.tsx:1060',
      );
    });

    test('a numeric bar takes the width the domain-margin solve wrote', () {
      final story = loadOracleStory(
        'charts-verticalbarchart--vertical-bar-dynamic',
      );
      final (rangeStart, rangeEnd) = xRangeOf(story);
      final captured = story.byTag('rect');
      expect(captured.length, 5, reason: 'the story draws five bars');
      final bars = _numericDelegate(xs: dynamicXs, ys: dynamicYs).barsFor(
        FluentCartesianChildContext(
          // The captured ticks run 0..80 in steps of 10, which is the data
          // extent 1..72 after `.nice()` (VerticalBarChart.tsx:594-596).
          xScale: ScaleLinear()
            ..domainOf(<double>[0, 80])
            ..rangeOf(<double>[rangeStart, rangeEnd]),
          yScalePrimary: _positionScale(containerHeight: story.height),
          containerWidth: story.width,
          containerHeight: story.height,
        ),
        _layout(width: story.width, height: story.height),
      );
      expect(bars.length, 5, reason: 'a count guard');
      for (var i = 0; i < bars.length; i++) {
        expectOracleNumber(
          'dynamic bar $i width',
          captured[i].width!,
          bars[i].rect.width,
        );
        expectOracleNumber(
          'dynamic bar $i left',
          captured[i].x!,
          bars[i].rect.left,
        );
      }
    });

    test('a category axis widens the shell margins by the solved margin', () {
      final story = loadOracleStory(
        'charts-verticalbarchart--vertical-bar-rotate-labels',
      );
      final bars = story.byTag('rect');
      expect(bars.length, 4, reason: 'a filtered count guard');
      final solved = _stringDelegate(
        // Four single-character categories, so the band count is what the
        // solver reads and the labels are what it would measure.
        categories: const <String>['a', 'b', 'c', 'd'],
        ys: const <double>[10, 20, 30, 40],
      ).domainMargins(story.width, _margins);
      expect(
        solved,
        isNotNull,
        reason: 'the same null-means-unwired check as the numeric test above',
      );
      // Every bar sits in a `g` at `translate(0, 0)`, so rect.x IS the band
      // start — `margins.left + _domainMargin` (VerticalBarChart.tsx:614).
      expectOracleNumber(
        'rotate-labels band start',
        bars.first.x!,
        solved!.left!,
      );
      expectOracleNumber(
        'rotate-labels band end',
        bars.last.x! + bars.last.width!,
        story.width - solved.right!,
      );
    });

    // The delegate must DERIVE `isOuterPaddingDefined` from its own props.
    // Asserting `solveDomainMargin(isOuterPaddingDefined: true)` returns 0 —
    // which the unit group above already does — proves nothing about the
    // wiring: a delegate that hard-coded `false` passes that and still ignores
    // the caller's padding, which is how `isScalePaddingDefined` spent four
    // waves on the orphan allowlist.
    test('a defined outer padding leaves the shell margins alone', () {
      const categories = <String>['a', 'b', 'c', 'd'];
      const ys = <double>[10, 20, 30, 40];
      final withPadding = _delegateOver(<FluentVerticalBarChartDataPoint>[
        for (var i = 0; i < categories.length; i++)
          FluentVerticalBarChartDataPoint(x: categories[i], y: ys[i]),
      ], xAxisOuterPadding: 0.1).domainMargins(650, _margins);
      expect(
        withPadding!.left,
        _margins.left,
        reason:
            'VerticalBarChart.tsx:993-996 zeroes _domainMargin outright once '
            'xAxisOuterPadding is defined, because the band scale now owns the '
            'space before the first bar',
      );
      expect(
        withPadding.right,
        _margins.right,
        reason: 'the same zero on the other end',
      );
      expect(
        _stringDelegate(
          categories: categories,
          ys: ys,
        ).domainMargins(650, _margins)!.left,
        greaterThan(_margins.left!),
        reason:
            'a control: without the padding the same data DOES widen the '
            'margins, so the assertion above is about the prop and not about '
            'these four categories',
      );
    });

    // The plotly arm (`VerticalBarChart.tsx:1010-1025`) is the only one that
    // reads `calculateLongestLabelWidth(uniqueX)`, and no captured story sets
    // `mode: 'plotly'`, so this is asserted relatively rather than against a
    // number: `flutter test` resolves a different font from the capture
    // browser, and a hard-coded width would pin the harness, not the port.
    test('a longer category label narrows the plotly domain margin', () {
      FluentChartMargins marginsFor(List<String> categories) => _delegateOver(
        <FluentVerticalBarChartDataPoint>[
          for (final category in categories)
            FluentVerticalBarChartDataPoint(x: category, y: 10),
        ],
        // `:1000` claims every barWidth that is not `auto`, so the plotly arm
        // is unreachable without it.
        barWidthProp: 'auto',
        mode: 'plotly',
      ).domainMargins(650, _margins)!;

      final short = marginsFor(const <String>['a', 'b', 'c', 'd']);
      final long = marginsFor(const <String>[
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
        'cccccccccccccccccccccccccccccc',
        'dddddddddddddddddddddddddddddd',
      ]);
      expect(
        long.left,
        lessThan(short.left!),
        reason:
            'margin2 is `(totalWidth - (n - innerPadding) * (longest + 20)) / 2` '
            '(VerticalBarChart.tsx:1020-1022) and the min at :1025 takes it, so '
            'a wider label leaves less room before the first bar. A delegate '
            'that passed 0 for the measured width makes these two equal.',
      );
      expect(
        long.left,
        greaterThanOrEqualTo(_margins.left! + kMinDomainMargin),
        reason:
            'the max(0, …) at :1025 floors the added margin, so even labels '
            'wide enough to make margin2 negative keep MIN_DOMAIN_MARGIN',
      );
    });

    // The solve sizes the band range to `reqWidth` at the resolved paddings
    // (`VerticalBarChart.tsx:1000-1006`); the shell then pads the band scale
    // from the delegate's own hooks. If those two disagree the centring is
    // wrong by construction — the bars no longer fill the range they were
    // centred in — so the hand-off is asserted through a mounted chart rather
    // than through the getters alone.
    testWidgets('the shell band scale is padded with the resolved values', (
      tester,
    ) async {
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: Center(
            // 260x180 is a box, not a ported constant: it is the golden grid's
            // own cell size, so this pins what the goldens capture.
            child: SizedBox(
              width: 260,
              height: 180,
              child: FluentVerticalBarChart(data: _points()),
            ),
          ),
        ),
      );
      final painter = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((widget) => widget.painter)
          .whereType<FluentCartesianChartPainter>()
          .first;
      final delegate = painter.delegate as FluentVerticalBarChartDelegate;
      final scale = painter.xAxis.scale;
      final rangeStart = delegate
          .domainMargins(painter.layout.size.width, painter.layout.margins)!
          .left!;
      expect(
        scale('a'),
        closeTo(rangeStart, 1e-9),
        reason:
            'the resolved outer padding is 0 (`VerticalBarChart.tsx:323`), so '
            'the first band starts exactly where the domain margin put the '
            'range. Handing createStringXAxis a null lets it fall back to its '
            'own xAxisPadding of 0.1 (utilities.ts:574, spent at :586) and inset '
            'the band.',
      );
      // The band step, which the styled story pins at 58.702703 against a
      // bandwidth of 19.567568 — a ratio of exactly 1 - 2/3.
      final step = scale('b')! - scale('a')!;
      expect(
        scale.bandwidth / step,
        closeTo(1 - _defaultInnerPadding, 1e-9),
        reason:
            'the resolved inner padding is 2/3 (`:315-322`), and d3 defines '
            'paddingInner as gap / step, so this ratio IS 1 - innerPadding',
      );
      expect(
        scale.bandwidth,
        closeTo(kDefaultBarWidth, 1e-9),
        reason:
            'the solve sized the range so three 16px bars at 2/3 inner padding '
            'exactly fill it (:1000-1006), so a band is one bar wide',
      );
    });

    test('an explicit zero outer padding still zeroes the margin', () {
      expect(
        _delegateOver(const <FluentVerticalBarChartDataPoint>[
          FluentVerticalBarChartDataPoint(x: 'a', y: 10),
          FluentVerticalBarChartDataPoint(x: 'b', y: 20),
        ], xAxisOuterPadding: 0).domainMargins(650, _margins)!.left,
        _margins.left,
        reason:
            'isScalePaddingDefined is `typeof prop === "number"` '
            '(utilities.ts:1922), so an explicit 0 is defined — which is the '
            'whole reason the flag exists beside getScalePadding',
      );
    });
  });

  group('FluentVerticalBarChart showRoundOffXTickValues', () {
    /// The props the widget hands the shell, which is where
    /// `VerticalBarChart.tsx:1181-1184` lands.
    Future<FluentCartesianChartProps> propsOf(
      WidgetTester tester,
      FluentVerticalBarChart chart,
    ) async {
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: Center(child: SizedBox(width: 400, height: 300, child: chart)),
        ),
      );
      return tester
          .widget<FluentCartesianChart>(find.byType(FluentCartesianChart))
          .props;
    }

    testWidgets('is on by default', (tester) async {
      final props = await propsOf(
        tester,
        FluentVerticalBarChart(data: _points()),
      );
      expect(
        props.showRoundOffXTickValues,
        isTrue,
        reason:
            'neither padding is defined and the mode is not histogram, so '
            'VerticalBarChart.tsx:1182-1183 is true and the numeric x scale '
            'still nices',
      );
    });

    testWidgets('a defined inner padding turns it off', (tester) async {
      final props = await propsOf(
        tester,
        FluentVerticalBarChart(data: _points(), xAxisInnerPadding: 0.2),
      );
      expect(
        props.showRoundOffXTickValues,
        isFalse,
        reason:
            'isScalePaddingDefined(props.xAxisInnerPadding, props.xAxisPadding) '
            'is true, so VerticalBarChart.tsx:1183 negates to false',
      );
    });

    testWidgets('the xAxisPadding shorthand turns it off too', (tester) async {
      final props = await propsOf(
        tester,
        FluentVerticalBarChart(data: _points(), xAxisPadding: 0.2),
      );
      expect(
        props.showRoundOffXTickValues,
        isFalse,
        reason:
            'the shorthand is the second argument of isScalePaddingDefined '
            '(utilities.ts:1921-1922), so it defines the padding on its own',
      );
    });

    testWidgets('histogram mode turns it off with no padding at all', (
      tester,
    ) async {
      final props = await propsOf(
        tester,
        FluentVerticalBarChart(data: _points(), mode: 'histogram'),
      );
      expect(
        props.showRoundOffXTickValues,
        isFalse,
        reason:
            "the `&& props.mode !== 'histogram'` half of "
            'VerticalBarChart.tsx:1183',
      );
    });
  });

  // The histogram arm of `_getDomainMargins` (`VerticalBarChart.tsx:1028-1035`)
  // centres the bars inside exactly `calcRequiredWidth(maxBarWidth, n,
  // innerPadding)` of plot width, and `calculateAppropriateBarWidth`
  // (`vbc-utils.ts:25-40`) then solves the bar width from that reserved width.
  // The bars only fit it if the range keeps HALF a bar of inset at each end,
  // which is what that formula is derived for; the whole-bar inset upstream
  // takes leaves one bar width too little, and at two bins there is nothing
  // left at all.
  //
  // Mounted rather than solved by hand: the collapse is only visible once the
  // shell has built the x scale from the delegate's own domain margins
  // (`CartesianChart.tsx:195`), which is the hand-off `solveDomainMargin`
  // spent four waves not being part of.
  group('FluentVerticalBarChart histogram numeric x range', () {
    /// The x range the shell built for a mounted chart, and the bar width the
    /// delegate solved beside the domain margin that positioned it.
    Future<({double rangeWidth, double barWidth, double marginLeft})> solveOf(
      WidgetTester tester, {
      required List<double> xs,
      required String? mode,
      // 24 is `VerticalBarChart.tsx:69`'s own default, and 50 is what the
      // Plotly histogram transformer sets (`PlotlySchemaAdapter.ts:1895`).
      double maxBarWidth = 24,
    }) async {
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: Center(
            // 400x300 is a box, not a ported constant.
            child: SizedBox(
              width: 400,
              height: 300,
              child: FluentVerticalBarChart(
                mode: mode,
                maxBarWidth: maxBarWidth,
                data: <FluentVerticalBarChartDataPoint>[
                  for (final x in xs)
                    // The y values only give the bars a height; nothing here
                    // reads them. 10 is an arbitrary positive value.
                    FluentVerticalBarChartDataPoint(x: x, y: 10),
                ],
              ),
            ),
          ),
        ),
      );
      final painter = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((widget) => widget.painter)
          .whereType<FluentCartesianChartPainter>()
          .first;
      final delegate = painter.delegate as FluentVerticalBarChartDelegate;
      final solved = delegate.solveDomainMargin(
        painter.layout.size.width,
        painter.layout.margins,
      );
      final range = painter.xAxis.scale.range;
      return (
        rangeWidth: (range.last - range.first).abs(),
        barWidth: solved.barWidth,
        marginLeft: (painter.layout.margins.left ?? 0) + solved.domainMargin,
      );
    }

    testWidgets('three numeric bars stay one bar apart', (tester) async {
      const xs = <double>[1, 2, 3];
      final histogram = await solveOf(tester, xs: xs, mode: 'histogram');
      expect(
        histogram.rangeWidth,
        // 1 is the fewer gaps than bars: n centres span n - 1 steps.
        closeTo((xs.length - 1) * histogram.barWidth, 1e-9),
        reason:
            'the bars are centred on the range ends, so n adjacent bars of w '
            'need a range of (n - 1) * w — the width '
            '`calculateAppropriateBarWidth` (vbc-utils.ts:36-38) solves for. A '
            'narrower range overlaps every bar with its neighbour.',
      );
    });

    testWidgets('a two-bin histogram keeps a range at all', (tester) async {
      // The two bin centres the shipped Plotly route produces for the `xbins`
      // figure pinned in declarative/declarative_chart_test.dart: (0 + 5) / 2
      // and (5 + 10) / 2 (`PlotlySchemaAdapter.ts:1876`).
      const centres = <double>[2.5, 7.5];
      final histogram = await solveOf(
        tester,
        xs: centres,
        mode: 'histogram',
        maxBarWidth: 50,
      );
      expect(
        histogram.rangeWidth,
        greaterThan(0),
        reason:
            'a zero-width x range maps both bin centres to the same pixel, so '
            'the chart draws one bar where the histogram has two and the axis '
            'keeps a single tick — the whole plot collapsed',
      );
      expect(
        histogram.rangeWidth,
        closeTo(histogram.barWidth, 1e-9),
        reason:
            'two centres span one bar step, so the range is exactly one bar '
            'wide once the two half-bar insets are taken',
      );
    });

    testWidgets('a plain numeric axis keeps the whole-bar inset', (
      tester,
    ) async {
      final plain = await solveOf(tester, xs: <double>[1, 2, 3], mode: null);
      expect(
        plain.marginLeft,
        closeTo(_margins.left! + kMinDomainMargin + plain.barWidth, 1e-9),
        reason:
            'VerticalBarChart.tsx:1055-1056 are two identical lines, so a '
            'chart in no mode insets by a WHOLE bar. Oracle B pins it: '
            'charts-verticalbarchart--vertical-bar-dynamic solves 12 = 8 + 4 '
            'against a 4px bar, never 8 + 2 — so the doubling is reproduced '
            'outside histogram mode and only the histogram arm above departs '
            'from it.',
      );
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
  final List<double> pathStrokeWidths = <double>[];
  final List<Color> circleFills = <Color>[];
  final List<Color> circleStrokes = <Color>[];
  final List<double> circleRadii = <double>[];

  @override
  void drawRect(Rect rect, Paint paint) => rectFills.add(paint.color);

  @override
  void drawRRect(RRect rrect, Paint paint) => rectFills.add(paint.color);

  @override
  void drawPath(Path path, Paint paint) {
    pathStrokes.add(paint.color);
    pathStrokeWidths.add(paint.strokeWidth);
  }

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

/// A colour as one packed int.
///
/// `Paint.color` comes back through `Color.withValues`, whose float channels
/// are not bit-identical to a `Color(0xFF……)` literal's even when both paint
/// the same pixel, so `==` on the `Color` itself compares storage rather than
/// ink.
int _argb(Color colour) => colour.toARGB32();

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
  Color? lineLegendColor,
  FluentLineOptions? lineOptions,
  Object? activeXDataPoint,
  bool isHighContrast = false,
  bool hideLabels = false,
  double? xAxisOuterPadding,
  String? mode,
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
  lineLegendColor: lineLegendColor,
  lineOptions: lineOptions,
  xAxisOuterPadding: xAxisOuterPadding,
  mode: mode,
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
  Color? lineLegendColor,
  FluentLineOptions? lineOptions,
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
  lineLegendColor: lineLegendColor,
  lineOptions: lineOptions,
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
