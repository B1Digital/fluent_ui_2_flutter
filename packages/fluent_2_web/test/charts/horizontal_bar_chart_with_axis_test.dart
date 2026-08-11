import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/axis/axis_types.dart';
import 'package:fluent_2_web/src/charts/cartesian/cartesian_chart.dart';
import 'package:fluent_2_web/src/charts/cartesian/cartesian_layout.dart';
import 'package:fluent_2_web/src/charts/cartesian/cartesian_series_delegate.dart';
import 'package:fluent_2_web/src/charts/chrome/chart_popover.dart';
import 'package:fluent_2_web/src/charts/horizontal_bar_chart_with_axis.dart';
import 'package:fluent_2_web/src/charts/horizontal_bar_chart_with_axis_style.dart';
import 'package:fluent_2_web/src/charts/internal/chart_colors.dart';
import 'package:fluent_2_web/src/charts/internal/chart_text_measurer.dart';
import 'package:fluent_2_web/src/charts/internal/chart_text_styles.dart';
import 'package:fluent_2_web/src/charts/internal/d3/scale.dart';
import 'package:fluent_2_web/src/charts/internal/d3/scale_band.dart';
import 'package:fluent_2_web/src/charts/internal/d3/scale_linear.dart';
import 'package:fluent_2_web/src/charts/internal/data_viz_palette.dart';
import 'package:fluent_2_web/src/charts/model/bar_data.dart';
import 'package:fluent_2_web/src/charts/model/chart_common.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/oracle_fixture.dart';

ScaleLinear _linearScale({
  required List<double> domain,
  required List<double> range,
}) => ScaleLinear()
  ..domainOf(domain)
  ..rangeOf(range);

/// A delegate over one point per entry of [yValues].
///
/// [xValues] defaults to a flat 10 per point, which is enough for every test
/// that only asks about the y solve.
FluentHorizontalBarChartWithAxisDelegate _hbwaDelegate({
  required List<Object> yValues,
  double yAxisPadding = 0.5,
  List<double>? xValues,
  FluentAxisCategoryOrder yAxisCategoryOrder =
      FluentAxisCategoryOrder.defaultOrder,
  bool hideLabels = false,
}) {
  final theme = FluentThemeData.light();
  return FluentHorizontalBarChartWithAxisDelegate(
    points: <FluentHorizontalBarChartWithAxisDataPoint>[
      for (final (i, y) in yValues.indexed)
        FluentHorizontalBarChartWithAxisDataPoint(
          // 10 is an arbitrary non-zero bar length; no y assertion reads it.
          x: xValues == null ? 10 : xValues[i],
          y: y,
        ),
    ],
    style: resolveFluentHorizontalBarChartWithAxisStyle(theme),
    colors: FluentChartColors.of(theme),
    measurer: FluentChartTextMeasurer(),
    textStyles: FluentChartTextStyles.of(theme),
    selectedLegends: const <String>[],
    yAxisPadding: yAxisPadding,
    yAxisCategoryOrder: yAxisCategoryOrder,
    hideLabels: hideLabels,
  );
}

/// The layout the shell would hand [FluentHorizontalBarChartWithAxisDelegate]
/// once the margins are solved.
FluentCartesianLayout _layout({
  required double height,
  double width = 800,
  FluentChartMargins margins = const FluentChartMargins(
    left: 40,
    right: 20,
    top: 28,
    bottom: 43,
  ),
}) => FluentCartesianLayout.resolve(
  size: Size(width, height),
  margins: margins,
  xAxisLabelReserve: 0,
  isRtl: false,
  startFromX: 0,
);

/// The child context the shell builds for [delegate]: the y scale is the one
/// [FluentHorizontalBarChartWithAxisDelegate.solveYDomainMargins] implies, and
/// [rangeTop] overrides its top edge so a test can push a band off the canvas.
FluentCartesianChildContext _hbwaContext(
  FluentHorizontalBarChartWithAxisDelegate delegate, {
  double height = 350,
  double width = 800,
  double? rangeTop,
  Scale? xScale,
}) {
  final solved = delegate.solveYDomainMargins(height);
  final bottom = height - solved.margins.bottom!;
  final top = rangeTop ?? solved.margins.top!;
  final labels = delegate.stringDatasetForYAxisDomain;
  final yScale = labels == null
      // The floor `createYAxisForHorizontalBarChartWithAxis` clamps to
      // (`utilities.ts:750`) and the data ceiling, which is what that builder
      // resolves for every dataset this file feeds it.
      ? (_linearScale(
          domain: <double>[
            0,
            delegate.points
                .map((point) => (point.y as num).toDouble())
                .reduce((a, b) => a > b ? a : b),
          ],
          range: <double>[bottom, top],
        ))
      : (ScaleBand()
          ..domainOf(labels.cast<Object>())
          ..rangeOf(<double>[bottom, top])
          // The same 1 -> 0.99 clamp `createStringYAxisForHorizontalBarChart
          // WithAxis` applies (`utilities.ts:920`).
          ..padding(delegate.yAxisPadding == 1 ? 0.99 : delegate.yAxisPadding));
  return FluentCartesianChildContext(
    // 100 spans every x the non-oracle tests feed the delegate.
    xScale:
        xScale ??
        _linearScale(domain: <double>[0, 100], range: <double>[40, width - 20]),
    yScalePrimary: yScale,
    containerWidth: width,
    containerHeight: height,
  );
}

List<FluentHorizontalBarChartWithAxisDataPoint> _group(
  List<double> xs,
) => <FluentHorizontalBarChartWithAxisDataPoint>[
  for (final x in xs) FluentHorizontalBarChartWithAxisDataPoint(x: x, y: 'a'),
];

/// Records the fills
/// [FluentHorizontalBarChartWithAxisDelegate.paintSeries] draws with, which is
/// the only way to see a colour that never reaches a widget.
class _RecordingCanvas implements Canvas {
  final List<Rect> rects = <Rect>[];
  final List<Color> fills = <Color>[];

  @override
  void drawRect(Rect rect, Paint paint) {
    rects.add(rect);
    fills.add(paint.color);
  }

  @override
  void drawRRect(RRect rrect, Paint paint) {
    rects.add(rrect.outerRect);
    fills.add(paint.color);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// The x scale of a captured HorizontalBarChartWithAxis story, rebuilt from its
/// own tick groups: each `<g transform="translate(x,0)">` under the x axis
/// carries a `<text>` with the tick's domain value, and `x` is the scaled pixel
/// plus the story's crisp offset.
({ScaleLinear scale, double containerWidth, FluentChartMargins margins})
_scaleFromStory(OracleStory story) {
  final tickGroups = story
      .byTag('g')
      .where(
        (g) =>
            g.translate != null &&
            g.translate!.dy == 0 &&
            g.translate!.dx != 0 &&
            story.childrenOf(g).any((child) => child.tag == 'text'),
      )
      .toList();
  expect(
    tickGroups.length,
    greaterThanOrEqualTo(2),
    reason:
        '${story.id} must expose at least two x-axis tick groups for the '
        'scale to be rebuilt from the capture rather than hard-coded',
  );
  ({double px, double value}) tick(int index) {
    final group = tickGroups[index];
    final label = story
        .childrenOf(group)
        .firstWhere((child) => child.tag == 'text');
    return (
      px: story.absoluteTranslate(group).dx - story.crispOffset,
      // Upstream formats the tick with a thousands separator; the domain value
      // behind it is the same number without the group separators.
      value: double.parse(label.text!.replaceAll(',', '')),
    );
  }

  final first = tick(0);
  final last = tick(tickGroups.length - 1);
  return (
    scale: _linearScale(
      domain: <double>[first.value, last.value],
      range: <double>[first.px, last.px],
    ),
    containerWidth: story.primary.width,
    // The axis range starts at the left margin and ends `right` short of the
    // container, which is how `_getMargins` fed the range in the first place
    // (`HorizontalBarChartWithAxis.tsx:336-340`).
    margins: FluentChartMargins(
      left: first.px,
      right: story.primary.width - last.px,
    ),
  );
}

void main() {
  group('FluentHorizontalBarChartGeometry.layOutGroup', () {
    // xDomain [-20, 80] over range [40, 780]; 100 units == 740 px, so 7.4 px
    // per unit and xBarScale(0) == 188.
    final scale = _linearScale(
      domain: <double>[-20, 80],
      range: <double>[40, 780],
    );
    const margins = FluentChartMargins(left: 40, right: 20);

    test('the running offsets stack a mixed group left to right', () {
      final segs = FluentHorizontalBarChartGeometry.layOutGroup(
        group: _group(<double>[40, -10, 25, -5]),
        xBarScale: scale,
        containerWidth: 800,
        margins: margins,
        isRtl: false,
      );
      expect(
        segs[0].xStart,
        closeTo(188, 1e-6),
        reason:
            'the first bar contributes no offset — prevPoint starts at 0, '
            'HorizontalBarChartWithAxis.tsx:392, :431-433',
      );
      expect(
        segs[0].width,
        closeTo(40 * 7.4 - 2, 1e-6),
        reason: 'currentWidth 296 minus the 2px gap, .tsx:436-442, :457',
      );
      expect(
        segs[2].xStart,
        closeTo(188 + 40 * 7.4, 1e-6),
        reason:
            'the third bar is offset by the accumulated positive width, '
            'which lags one iteration behind, .tsx:450-455',
      );
    });

    test('the last positive bar gets no trailing gap', () {
      final segs = FluentHorizontalBarChartGeometry.layOutGroup(
        group: _group(<double>[40, 25]),
        xBarScale: scale,
        containerWidth: 800,
        margins: margins,
        isRtl: false,
      );
      expect(
        segs.last.width,
        closeTo(25 * 7.4, 1e-6),
        reason:
            'currPositiveCounter == totalPositiveBars suppresses the gap, '
            '.tsx:437-439',
      );
    });

    test('a bar narrower than 2px never gets a gap', () {
      final segs = FluentHorizontalBarChartGeometry.layOutGroup(
        group: _group(<double>[0.1, 40]),
        xBarScale: scale,
        containerWidth: 800,
        margins: margins,
        isRtl: false,
      );
      expect(
        segs.first.width,
        closeTo(0.74, 1e-6),
        reason: 'the `currentWidth > 2` guard at .tsx:438',
      );
    });

    test('RTL mirrors the origin and keeps its own gap rule', () {
      final ltr = FluentHorizontalBarChartGeometry.layOutGroup(
        group: _group(<double>[40, -10]),
        xBarScale: scale,
        containerWidth: 800,
        margins: margins,
        isRtl: false,
      );
      final rtl = FluentHorizontalBarChartGeometry.layOutGroup(
        group: _group(<double>[40, -10]),
        xBarScale: scale,
        containerWidth: 800,
        margins: margins,
        isRtl: true,
      );
      expect(
        rtl.first.xStart,
        isNot(closeTo(ltr.first.xStart, 1e-6)),
        reason: 'barStartX has a distinct RTL formula at .tsx:415-418',
      );
      expect(
        rtl.first.xStart,
        closeTo(800 - (20 + 40 * 7.4 + 188 - 40), 1e-6),
        reason:
            'containerWidth - (right + max(scale(x), scale(0)) - left), '
            '.tsx:415-418',
      );
      expect(
        ltr.first.width,
        closeTo(40 * 7.4, 1e-6),
        reason: 'gapWidthLTR is 0 for the last positive bar, .tsx:436-442',
      );
      expect(
        rtl.first.width,
        closeTo(40 * 7.4 - 2, 1e-6),
        reason:
            'gapWidthRTL charges the same bar a gap, because its positive '
            'arm asks for `totalNegativeBars !== 0` rather than for the last '
            'positive bar — .tsx:443-448',
      );
    });

    test('barEndX is the trailing edge in the value direction', () {
      final segs = FluentHorizontalBarChartGeometry.layOutGroup(
        group: _group(<double>[40, -10]),
        xBarScale: scale,
        containerWidth: 800,
        margins: margins,
        isRtl: false,
      );
      expect(
        segs[0].endX,
        closeTo(segs[0].xStart + segs[0].width, 1e-6),
        reason: 'x >= 0 ends at xStart + barWidth, .tsx:458-464',
      );
      expect(
        segs[1].endX,
        closeTo(segs[1].xStart, 1e-6),
        reason: 'a negative bar ends at xStart',
      );
      final rtl = FluentHorizontalBarChartGeometry.layOutGroup(
        group: _group(<double>[40, -10]),
        xBarScale: scale,
        containerWidth: 800,
        margins: margins,
        isRtl: true,
      );
      expect(
        rtl[0].endX,
        closeTo(rtl[0].xStart, 1e-6),
        reason: 'RTL flips the two arms, .tsx:458-464',
      );
      expect(
        rtl[1].endX,
        closeTo(rtl[1].xStart + rtl[1].width, 1e-6),
        reason: 'a negative RTL bar ends at xStart + barWidth',
      );
    });
  });

  group('FluentHorizontalBarChartGeometry.totalsFor', () {
    test('a positive total labels the last positive bar', () {
      final t = FluentHorizontalBarChartGeometry.totalsFor(
        _group(<double>[40, -10]),
      );
      expect(t.total, 30, reason: 'the group total is the plain sum');
      expect(
        t.showLabelOnLastPositive,
        isTrue,
        reason:
            'HorizontalBarChartWithAxis.tsx:345-369 labels the last '
            'positive bar when the total is non-negative',
      );
    });

    test('a negative total labels the last negative bar', () {
      expect(
        FluentHorizontalBarChartGeometry.totalsFor(
          _group(<double>[10, -40]),
        ).showLabelOnLastPositive,
        isFalse,
        reason: 'a negative total moves the label to the last negative bar',
      );
    });
  });

  group('Oracle B — HorizontalBarChartWithAxis', () {
    test('the negative story\'s eight stacked bars land on the capture', () {
      final story = loadOracleStory(
        'charts-horizontalbarchartwithaxis--horizontal-bar-with-axis-negative',
      );
      final axis = _scaleFromStory(story);
      final rects = story.byTag('rect');
      expect(
        rects.length,
        40,
        reason:
            '${story.id} draws five groups of eight bars; a different '
            'count means the fixture changed shape',
      );
      // The story feeds each category ±10, ±20, ±30, ±40, interleaved. The
      // group label reads "0", which is that sum, and the last positive bar —
      // the only one upstream leaves ungapped — measures 39.333px against
      // 0.98333px per unit, i.e. exactly 40.
      final segs = FluentHorizontalBarChartGeometry.layOutGroup(
        group: _group(<double>[10, -10, 20, -20, 30, -30, 40, -40]),
        xBarScale: axis.scale,
        containerWidth: axis.containerWidth,
        margins: axis.margins,
        isRtl: false,
      );
      for (var i = 0; i < segs.length; i++) {
        expectOracleNumber('bar $i x', rects[i].x!, segs[i].xStart);
        expectOracleNumber('bar $i width', rects[i].width!, segs[i].width);
      }
      final labels = story
          .byTag('text')
          .where((element) => element.x != null && element.text == '0')
          .toList();
      expect(
        labels.length,
        5,
        reason: 'one group total label per category, each reading 0',
      );
      final labelled = segs.singleWhere((seg) => seg.showLabel);
      expect(
        labelled.index,
        6,
        reason:
            'the total is 0, so the label goes on the last positive bar, '
            'the seventh of the eight',
      );
      expectOracleNumber('group label anchor', labels.first.x!, labelled.endX);
    });

    test('the basic story leaves a lone positive bar ungapped', () {
      final story = loadOracleStory(
        'charts-horizontalbarchartwithaxis--horizontal-bar-with-axis-basic',
      );
      final axis = _scaleFromStory(story);
      final rects = story.byTag('rect');
      expect(
        rects.length,
        4,
        reason: '${story.id} draws one bar per category, four in all',
      );
      // Pixels per domain unit, read off the rebuilt scale rather than typed
      // in, so the bar's domain value can be recovered from its width.
      final unit = axis.scale(1)! - axis.scale(0)!;
      // One bar per group, so every group is its own last positive bar.
      for (final rect in rects) {
        final segs = FluentHorizontalBarChartGeometry.layOutGroup(
          group: _group(<double>[rect.width! / unit]),
          xBarScale: axis.scale,
          containerWidth: axis.containerWidth,
          margins: axis.margins,
          isRtl: false,
        );
        expectOracleNumber('lone bar x', rect.x!, segs.single.xStart);
        expectOracleNumber('lone bar width', rect.width!, segs.single.width);
      }
    });
  });

  group('HBWA y domain margins', () {
    test('five string categories at padding 0.5 fill the plot exactly', () {
      final d = _hbwaDelegate(
        yValues: <Object>['a', 'b', 'c', 'd', 'e'],
        yAxisPadding: 0.5,
      );
      final solved = d.solveYDomainMargins(350);
      // totalHeight = 350 - (20 + 8) - (35 + 8) = 279
      // barGapRate = 0.5 / 0.5 = 1 ; numBars = 5 + 4 * 1 = 9
      expect(
        solved.barHeight,
        closeTo(31, 1e-9),
        reason: '279 / 9 == 31, HorizontalBarChartWithAxis.tsx:543',
      );
      expect(
        solved.margins.top,
        closeTo(28, 1e-9),
        reason: 'reqHeight == totalHeight so the margin stays at 8, :549',
      );
    });

    test('a padding of exactly 1 is coerced to 0.99', () {
      final d = _hbwaDelegate(
        yValues: <Object>['a', 'b', 'c', 'd', 'e'],
        yAxisPadding: 1,
      );
      // barGapRate = 0.99 / 0.01 = 99 ; numBars = 5 + 4 * 99 = 401
      expect(
        d.solveYDomainMargins(350).barHeight,
        closeTo(279 / 401, 1e-9),
        reason: 'the 1 -> 0.99 coercion at :531 and again at utilities.ts:920',
      );
    });

    test('a numeric y axis grows the margin by half a bar', () {
      final d = _hbwaDelegate(
        yValues: <Object>[0, 10, 20, 30],
        yAxisPadding: 0.5,
      );
      final solved = d.solveYDomainMargins(350);
      expect(
        solved.margins.top,
        closeTo(20 + kMinDomainMargin + solved.barHeight / 2, 1e-9),
        reason: 'HorizontalBarChartWithAxis.tsx:540-541',
      );
    });

    test('appropriateBarHeight widens the range by the data max first', () {
      final d = _hbwaDelegate(
        yValues: <Object>[0, 10, 20, 30],
        yAxisPadding: 0.5,
      );
      expect(
        d.appropriateBarHeight(<Object>[0, 10, 20, 30], 279, 0.5),
        (279 * 10 * 0.5 / (30 + 10 * 0.5)).floorToDouble(),
        reason: 'the extra `range = max(range, d3Max(y))` step at :508-525',
      );
    });
  });

  group('HBWA the barHeight position guard', () {
    test('a category whose band position is under 1px is dropped', () {
      final d = _hbwaDelegate(
        yValues: <Object>['a', 'b', 'c'],
        yAxisPadding: 0.5,
      );
      // The band start solves to `top + (307 - top) / 7`, so a top edge of -80
      // puts the first band at -24.7 — the only way to reach the guard, since
      // an in-plot layout never places a band above the top margin.
      expect(
        d
            .placeBars(_hbwaContext(d, rangeTop: -80), _layout(height: 350))
            .length,
        lessThan(3),
        reason:
            'parity: `const barHeight = max(yBarScale(y), 0); if '
            '(barHeight < 1) return` at :419-422 is a POSITION test, not a '
            'height test, so it silently drops top-most categories',
      );
    });

    test('an ordinary layout keeps every category', () {
      final d = _hbwaDelegate(
        yValues: <Object>['a', 'b', 'c'],
        yAxisPadding: 0.5,
      );
      expect(
        d.placeBars(_hbwaContext(d), _layout(height: 350)).length,
        3,
        reason:
            'the topmost band position is 67.86, comfortably above 1 — the '
            'band start is 28 + (307 - 28) / 7',
      );
    });
  });

  group('HBWA label ordering', () {
    test('the default order reverses the data and keeps duplicates', () {
      final d = _hbwaDelegate(
        yValues: <Object>['a', 'b', 'a'],
        yAxisPadding: 0.5,
      );
      expect(
        d.stringDatasetForYAxisDomain,
        <String>['a', 'b', 'a'],
        reason:
            'parity: the legacy branch at :819-829 does NOT de-duplicate, '
            'so the band range is sized for every point',
      );
    });

    test('a non-default category order accumulates every x per category', () {
      final d = _hbwaDelegate(
        yValues: <Object>['a', 'b', 'a'],
        xValues: <double>[1, 5, 9],
        yAxisCategoryOrder: FluentAxisCategoryOrder.sumAscending,
      );
      expect(
        d.stringDatasetForYAxisDomain,
        <String>['b', 'a'],
        reason:
            'a sums to 10 and b to 5, so a sorts last; a map literal keyed by '
            'category would have dropped the first a and put a first, '
            'HorizontalBarChartWithAxis.tsx:832-838',
      );
    });
  });

  group('Oracle B — HorizontalBarChartWithAxis geometry solve', () {
    test('the basic story pins the numeric bar height and both margins', () {
      final story = loadOracleStory(
        'charts-horizontalbarchartwithaxis--horizontal-bar-with-axis-basic',
      );
      final axis = _scaleFromStory(story);
      final rects = story.byTag('rect');
      expect(
        rects.length,
        4,
        reason: '${story.id} draws one bar per numeric y, four in all',
      );
      // The capture's own y ticks, in tick order: 0 at the plot floor and 50000
      // at its ceiling. d3-axis offsets a tick by the crisp half pixel, so the
      // scale's own pixels are the translate minus `crispOffset`.
      final yTicks = story
          .byTag('g')
          .where(
            (g) =>
                g.translate != null &&
                g.translate!.dx == 0 &&
                g.translate!.dy != 0 &&
                story.childrenOf(g).any((child) => child.tag == 'text'),
          )
          .toList();
      expect(
        yTicks.length,
        6,
        reason: '${story.id} captures six y ticks, 0 through 50k',
      );
      final unit = axis.scale(1)! - axis.scale(0)!;
      // The four points, recovered from the capture: the bar length is its
      // width in domain units and the y value is the band centre read back
      // through the y tick scale.
      final delegate = _hbwaDelegate(
        yValues: const <Object>[5000, 13000, 30000, 50000],
        xValues: <double>[
          for (final rect in rects) (rect.width! / unit).roundToDouble(),
        ],
      );
      final solved = delegate.solveYDomainMargins(story.primary.height);
      expectOracleNumber(
        'numeric bar height',
        rects.first.height!,
        solved.barHeight,
      );
      final spec = delegate.createYAxis(
        FluentYAxisParams(
          margins: FluentChartMargins(
            left: axis.margins.left,
            right: axis.margins.right,
            top: solved.margins.top,
            bottom: solved.margins.bottom,
          ),
          containerWidth: story.primary.width,
          containerHeight: story.primary.height,
          yMinMaxValues: delegate.resolveYMinMax(),
        ),
        FluentAxisData(),
        isRtl: false,
        isIntegralDataset: true,
      );
      for (final tick in yTicks) {
        final label = story
            .childrenOf(tick)
            .firstWhere((child) => child.tag == 'text');
        // "10k" and friends; the domain value is the label with its SI suffix
        // expanded, and 1000 is what a `k` stands for.
        final text = label.text!;
        final value = text.endsWith('k')
            ? double.parse(text.substring(0, text.length - 1)) * 1000
            : double.parse(text);
        expectOracleNumber(
          'y tick $text',
          story.absoluteTranslate(tick).dy - story.crispOffset,
          spec.scale(value)!,
        );
      }
      final placed = delegate.placeBars(
        FluentCartesianChildContext(
          xScale: axis.scale,
          yScalePrimary: spec.scale,
          containerWidth: story.primary.width,
          containerHeight: story.primary.height,
        ),
        _layout(
          height: story.primary.height,
          width: story.primary.width,
          margins: FluentChartMargins(
            left: axis.margins.left,
            right: axis.margins.right,
            top: solved.margins.top,
            bottom: solved.margins.bottom,
          ),
        ),
      );
      expect(
        placed.length,
        rects.length,
        reason: 'every captured bar must be placed',
      );
      for (var i = 0; i < rects.length; i++) {
        expectOracleNumber('bar $i x', rects[i].x!, placed[i].rect.left);
        expectOracleNumber('bar $i y', rects[i].y!, placed[i].rect.top);
        expectOracleNumber(
          'bar $i width',
          rects[i].width!,
          placed[i].rect.width,
        );
        expectOracleNumber(
          'bar $i height',
          rects[i].height!,
          placed[i].rect.height,
        );
      }
    });

    test('the string-axis story pins the band bar height and placement', () {
      final story = loadOracleStory(
        'charts-horizontalbarchartwithaxis--'
        'horizontal-bar-with-axis-string-axis-tooltip',
      );
      final axis = _scaleFromStory(story);
      final rects = story.byTag('rect');
      expect(
        rects.length,
        4,
        reason: '${story.id} draws one bar per string category, four in all',
      );
      final unit = axis.scale(1)! - axis.scale(0)!;
      final delegate = _hbwaDelegate(
        yValues: const <Object>['one', 'two', 'three', 'four'],
        xValues: <double>[
          for (final rect in rects) (rect.width! / unit).roundToDouble(),
        ],
      );
      final solved = delegate.solveYDomainMargins(story.primary.height);
      expectOracleNumber(
        'band bar height',
        rects.first.height!,
        solved.barHeight,
      );
      final placed = delegate.placeBars(
        _hbwaContext(
          delegate,
          height: story.primary.height,
          width: story.primary.width,
          xScale: axis.scale,
        ),
        _layout(
          height: story.primary.height,
          width: story.primary.width,
          margins: FluentChartMargins(
            left: axis.margins.left,
            right: axis.margins.right,
            top: solved.margins.top,
            bottom: solved.margins.bottom,
          ),
        ),
      );
      // The captured rect carries the half-leftover-bandwidth shift as a
      // `transform`, which this port folds into the rect's own top.
      final capturedTops = <double>[
        for (final rect in rects) rect.y! + rect.translate!.dy,
      ]..sort();
      // parity: which category lands at which band is the one thing the
      // capture and `_getOrderedYAxisLabels` disagree about — see the note on
      // [FluentHorizontalBarChartWithAxisDelegate.stringDatasetForYAxisDomain]
      // — so the tops are compared as a set, which pins the whole band solve
      // without asserting an order the fixture contradicts.
      final actualTops = <double>[for (final bar in placed) bar.rect.top]
        ..sort();
      for (var i = 0; i < capturedTops.length; i++) {
        expectOracleNumber('band top $i', capturedTops[i], actualTops[i]);
      }
      final capturedWidths = <double>[for (final rect in rects) rect.width!]
        ..sort();
      final actualWidths = <double>[for (final bar in placed) bar.rect.width]
        ..sort();
      for (var i = 0; i < capturedWidths.length; i++) {
        expectOracleNumber('band width $i', capturedWidths[i], actualWidths[i]);
      }
    });

    test('the negative story pins the bar height of a 40-point dataset', () {
      final story = loadOracleStory(
        'charts-horizontalbarchartwithaxis--horizontal-bar-with-axis-negative',
      );
      final rects = story.byTag('rect');
      expect(
        rects.length,
        40,
        reason: '${story.id} draws five groups of eight bars',
      );
      // Five categories of eight points each: the solve reads the *unique* y
      // values, so 40 points still divide the plot into nine bar units.
      final delegate = _hbwaDelegate(
        yValues: <Object>[
          for (final category in <String>['A', 'B', 'C', 'D', 'E'])
            for (var i = 0; i < 8; i++) category,
        ],
      );
      expectOracleNumber(
        'stacked bar height',
        rects.first.height!,
        delegate.solveYDomainMargins(story.primary.height).barHeight,
      );
    });
  });

  group('HBWA high contrast', () {
    // The bar fill is the only mark HBWA paints, and upstream's rects carry no
    // forced-color-adjust, so a forced-colours browser repaints them all in
    // CanvasText — design spec section 5.3. Nothing else in the slot set is
    // read here, so the rest are placeholders.
    const canvasText = Color(0xFFFFFFFF);
    const placeholder = Color(0xFF010203);
    FluentChartColors colours({required bool isHighContrast}) =>
        FluentChartColors(
          axisText: canvasText,
          axisTick: placeholder,
          axisTitle: placeholder,
          gridLine: placeholder,
          markStroke: placeholder,
          surface: placeholder,
          popoverSurface: placeholder,
          tooltipSurface: placeholder,
          legendDimmed: placeholder,
          isHighContrast: isHighContrast,
        );

    List<Color> paint({required bool isHighContrast}) {
      final d = _hbwaDelegate(yValues: <Object>['a', 'b', 'c']);
      final canvas = _RecordingCanvas();
      d.paintSeries(
        canvas,
        _hbwaContext(d),
        _layout(height: 350),
        colours(isHighContrast: isHighContrast),
      );
      return canvas.fills;
    }

    test('the palette survives an ordinary theme', () {
      expect(
        paint(isHighContrast: false).map((fill) => fill.toARGB32()),
        <int>[
          for (var i = 0; i < 3; i++)
            // One point per category, so every bar is its group's index 0.
            FluentDataVizPalette.next(0).toARGB32(),
        ],
        reason: 'flattenMark returns the series colour outside high contrast',
      );
    });

    test('every bar flattens to the system colour', () {
      expect(
        paint(isHighContrast: true).map((fill) => fill.toARGB32()),
        <int>[for (var i = 0; i < 3; i++) canvasText.toARGB32()],
        reason:
            'the series fill must route through FluentChartColors.flattenMark, '
            'design spec section 5.3',
      );
    });
  });

  group('FluentHorizontalBarChartWithAxisStyle', () {
    final theme = FluentThemeData.light();

    test('the resolver carries the upstream literals', () {
      final style = resolveFluentHorizontalBarChartWithAxisStyle(theme);
      expect(
        style.barHeight!.resolve(<WidgetState>{}),
        32,
        reason: 'HorizontalBarChartWithAxis.tsx:111',
      );
      expect(
        style.maxBarHeight,
        isNull,
        reason: 'upstream caps the horizontal bar height nowhere',
      );
      expect(
        style.segmentGap!.resolve(<WidgetState>{}),
        2,
        reason: 'HorizontalBarChartWithAxis.tsx:438',
      );
      expect(
        style.barOpacity!.resolve(<WidgetState>{WidgetState.disabled}),
        0.1,
        reason: 'HorizontalBarChartWithAxis.tsx:489',
      );
      expect(
        style.barOpacity!.resolve(<WidgetState>{}),
        1,
        reason: 'the highlighted arm of the same expression',
      );
      expect(
        style.minBarLabelHeight!.resolve(<WidgetState>{}),
        16,
        reason: 'HorizontalBarChartWithAxis.tsx:794',
      );
    });

    test('merge lets the override win and equality is by value', () {
      final base = resolveFluentHorizontalBarChartWithAxisStyle(theme);
      final merged = base.merge(
        FluentHorizontalBarChartWithAxisStyle.from(barHeight: 48),
      );
      expect(
        merged.barHeight!.resolve(<WidgetState>{}),
        48,
        reason: 'the non-null property of the argument wins',
      );
      expect(
        merged.barCornerRadius,
        base.barCornerRadius,
        reason: 'an omitted property inherits',
      );
      expect(
        FluentHorizontalBarChartWithAxisStyle.from(barLabelInset: 4),
        FluentHorizontalBarChartWithAxisStyle.from(barLabelInset: 4),
        reason: 'the template compares by field, as FluentBadgeStyle does',
      );
    });
  });

  group('FluentHorizontalBarChartWithAxis', () {
    Future<void> pump(WidgetTester tester, Widget chart) => tester.pumpWidget(
      FluentApp(
        theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
        home: Center(child: SizedBox(width: 800, height: 350, child: chart)),
      ),
    );

    testWidgets('leaving a bar DOES close the popover here', (tester) async {
      await pump(tester, FluentHorizontalBarChartWithAxis(data: _hbwaPoints()));
      final g = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await g.addPointer(location: Offset.zero);
      addTearDown(g.removePointer);
      await g.moveTo(tester.getCenter(find.byType(FluentCartesianChart)));
      await tester.pumpAndSettle();
      expect(
        find.byType(FluentChartPopover),
        findsOneWidget,
        reason: 'hover opens it',
      );
      await g.moveTo(
        tester.getTopLeft(find.byType(FluentCartesianChart)) +
            const Offset(1, 1),
      );
      await tester.pumpAndSettle();
      expect(
        find.byType(FluentChartPopover),
        findsNothing,
        reason:
            'HBWA is the only shell chart whose _onBarLeave actually '
            'closes the popover, HorizontalBarChartWithAxis.tsx:266-268',
      );
    });

    testWidgets('the popover swaps the axes: X shows the category', (
      tester,
    ) async {
      await pump(tester, FluentHorizontalBarChartWithAxis(data: _hbwaPoints()));
      final g = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await g.addPointer(location: Offset.zero);
      addTearDown(g.removePointer);
      await g.moveTo(tester.getCenter(find.byType(FluentCartesianChart)));
      await tester.pumpAndSettle();
      final popover = tester.widget<FluentChartPopover>(
        find.byType(FluentChartPopover),
      );
      expect(
        popover.data.xValue,
        'beta',
        reason:
            'xCalloutValue = yAxisCalloutData || String(point.y), '
            'HorizontalBarChartWithAxis.tsx:255',
      );
    });

    testWidgets('the legend swatch matches the bar it stands for', (
      tester,
    ) async {
      await pump(tester, FluentHorizontalBarChartWithAxis(data: _hbwaPoints()));
      final legends = tester
          .widget<FluentCartesianChart>(find.byType(FluentCartesianChart))
          .legends;
      expect(
        legends.first.color.toARGB32(),
        FluentDataVizPalette.next(0).toARGB32(),
        reason:
            'ponytail: upstream leaves the swatch undefined when '
            'useSingleColor is false and the point has no colour '
            '(HorizontalBarChartWithAxis.tsx:693-731); the port derives it '
            'from the same getNextColor(index, 0) the bar uses',
      );
    });

    testWidgets('a group label is suppressed below a 16px bar', (tester) async {
      await pump(
        tester,
        FluentHorizontalBarChartWithAxis(data: _hbwaPoints(), barHeight: 10),
      );
      final d =
          tester
                  .widget<FluentCartesianChart>(
                    find.byType(FluentCartesianChart),
                  )
                  .delegate
              as FluentHorizontalBarChartWithAxisDelegate;
      expect(
        d.shouldPaintGroupLabel(10),
        isFalse,
        reason:
            '_renderBarLabel suppresses below _barHeight 16, '
            'HorizontalBarChartWithAxis.tsx:790',
      );
    });

    testWidgets('an all-zero dataset is NOT empty here', (tester) async {
      await pump(
        tester,
        const FluentHorizontalBarChartWithAxis(
          data: <FluentHorizontalBarChartWithAxisDataPoint>[
            FluentHorizontalBarChartWithAxisDataPoint(x: 0, y: 'a'),
          ],
        ),
      );
      expect(
        find.byType(FluentCartesianChart),
        findsOneWidget,
        reason:
            'emptiness is `!(data && data.length > 0)` only, '
            'HorizontalBarChartWithAxis.tsx:842-844 — unlike VerticalBarChart',
      );
    });

    testWidgets('an empty dataset renders the alert node instead of a shell', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentHorizontalBarChartWithAxis(
          data: <FluentHorizontalBarChartWithAxisDataPoint>[],
        ),
      );
      expect(
        find.byType(FluentCartesianChart),
        findsNothing,
        reason: '`!(data && data.length > 0)` is true for the empty list',
      );
    });

    testWidgets('the accessible description counts POINTS, not groups', (
      tester,
    ) async {
      await pump(
        tester,
        FluentHorizontalBarChartWithAxis(
          data: _hbwaPoints(),
          chartTitle: 'Sales',
        ),
      );
      final props = tester
          .widget<FluentCartesianChart>(find.byType(FluentCartesianChart))
          .props;
      expect(
        props.chartTitleForSemantics,
        'Sales. Horizontal bar chart with 2 bars. ',
        reason:
            'the two points share one category yet count twice, '
            'HorizontalBarChartWithAxis.tsx:814-817',
      );
      expect(
        props.closePopoverOnRegionExit,
        isTrue,
        reason: '_onBarLeave closes it, HorizontalBarChartWithAxis.tsx:266-268',
      );
    });
  });

  group('HBWA group total label', () {
    test('hideLabels suppresses the label at any height', () {
      final d = _hbwaDelegate(yValues: <Object>['a'], hideLabels: true);
      expect(
        d.shouldPaintGroupLabel(32),
        isFalse,
        reason:
            '`props.hideLabels ||` is the first arm of the same guard, '
            'HorizontalBarChartWithAxis.tsx:790',
      );
      expect(
        _hbwaDelegate(yValues: <Object>['a']).shouldPaintGroupLabel(16),
        isTrue,
        reason: 'the guard is `< 16`, so 16 itself is labelled',
      );
    });

    test('the negative story pins the label baseline to the bar centre', () {
      final story = loadOracleStory(
        'charts-horizontalbarchartwithaxis--horizontal-bar-with-axis-negative',
      );
      final rects = story.byTag('rect');
      final labels = story
          .byTag('text')
          .where((element) => element.x != null && element.text == '0')
          .toList();
      expect(
        labels.length,
        5,
        reason: 'one group total label per category, each reading 0',
      );
      // `y={yPosition + _barHeight / 2}` (`.tsx:801`) with
      // `dominantBaseline="central"`, so the label's own y is the bar's
      // vertical centre — which is what
      // `FluentHorizontalBarChartWithAxisDelegate.paintSeries` centres the
      // measured label on. The string variant leaves the rect's `y` attribute
      // at the raw band top and carries the `0.5 * (bandwidth - _barHeight)`
      // centring in the rect's own transform (`.tsx:649`), so the painted top
      // is the attribute plus that translate. It is negative in this story,
      // the 31px bar being taller than its 25.36px band. Every bar of a group
      // shares the centre, so the first rect of each group recovers it.
      final perGroup = rects.length ~/ labels.length;
      for (var i = 0; i < labels.length; i++) {
        final rect = rects[i * perGroup];
        expectOracleNumber(
          'group $i label centre',
          labels[i].y!,
          rect.y! + (rect.translate?.dy ?? 0) + rect.height! / 2,
        );
      }
    });
  });
}

/// Two points sharing the category `beta`, so the middle of an 800x350 chart
/// lands inside the group's first segment.
List<FluentHorizontalBarChartWithAxisDataPoint>
_hbwaPoints() => const <FluentHorizontalBarChartWithAxisDataPoint>[
  FluentHorizontalBarChartWithAxisDataPoint(x: 100, y: 'beta', legend: 'first'),
  FluentHorizontalBarChartWithAxisDataPoint(x: 50, y: 'beta', legend: 'second'),
];
