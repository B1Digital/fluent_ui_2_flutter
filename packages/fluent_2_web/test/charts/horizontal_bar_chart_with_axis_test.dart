import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/horizontal_bar_chart_with_axis.dart';
import 'package:fluent_2_web/src/charts/horizontal_bar_chart_with_axis_style.dart';
import 'package:fluent_2_web/src/charts/internal/d3/scale_linear.dart';
import 'package:fluent_2_web/src/charts/model/bar_data.dart';
import 'package:fluent_2_web/src/charts/model/chart_common.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/oracle_fixture.dart';

ScaleLinear _linearScale({
  required List<double> domain,
  required List<double> range,
}) => ScaleLinear()
  ..domainOf(domain)
  ..rangeOf(range);

List<FluentHorizontalBarChartWithAxisDataPoint> _group(
  List<double> xs,
) => <FluentHorizontalBarChartWithAxisDataPoint>[
  for (final x in xs) FluentHorizontalBarChartWithAxisDataPoint(x: x, y: 'a'),
];

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
}
