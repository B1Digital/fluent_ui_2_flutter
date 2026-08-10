import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:fluent_2_web/src/charts/internal/d3/scale_band.dart' as d3;
import 'package:fluent_2_web/src/charts/internal/d3/scale_linear.dart' as d3;
import 'package:fluent_2_web/src/charts/internal/marker_geometry.dart';
import 'package:fluent_2_web/src/charts/scatter_chart.dart';
import 'package:fluent_2_web/src/charts/scatter_chart_style.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/oracle_fixture.dart';

/// The four captured ScatterChart stories. Every one of them passes a
/// `markerSize` on every point, so none of them witnesses the bare 4/6 radii —
/// those are asserted against `ScatterChart.tsx:427-428` instead. What they do
/// witness is the paint: the circle stroke width, and the dashed vertical hover
/// rule that upstream renders once per chart with `visibility: hidden`.
const List<String> _scatterStories = <String>[
  'charts-scatterchart--scatter-chart-default',
  'charts-scatterchart--scatter-chart-string',
  'charts-scatterchart--scatter-chart-date',
  'charts-scatterchart--scatter-chart-log-axis-example',
];

void main() {
  const states = <WidgetState>{};
  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  group('FluentScatterChartStyle', () {
    test("resolves the ScatterChart marker radii, not LineChart's", () {
      final style = resolveFluentScatterChartStyle(theme);
      expect(
        style.markerRadius!.resolve(states),
        4.0,
        reason: 'ScatterChart.tsx:427 passes defaultRadius 4',
      );
      expect(
        style.markerRadius!.resolve(<WidgetState>{WidgetState.hovered}),
        6.0,
        reason: 'ScatterChart.tsx:428 passes activeRadius 6',
      );
    });

    test('dims a deselected marker to one tenth', () {
      final style = resolveFluentScatterChartStyle(theme);
      expect(
        style.markerOpacity!.resolve(<WidgetState>{WidgetState.disabled}),
        0.1,
        reason: 'ScatterChart.tsx:473 uses opacity 0.1 for a dimmed marker',
      );
      expect(
        style.markerOpacity!.resolve(states),
        1.0,
        reason: 'ScatterChart.tsx:473 — a selected marker is fully opaque',
      );
    });

    test('the hover rule is a hard-coded hex upstream, not a token', () {
      final style = resolveFluentScatterChartStyle(theme);
      expect(
        style.hoverLineColor!.resolve(states)!.toARGB32(),
        0xFF323130,
        reason: "ScatterChart.tsx:756 hard-codes stroke='#323130'",
      );
    });

    test('Oracle B: every captured story paints that same hover rule', () {
      final style = resolveFluentScatterChartStyle(theme);
      var asserted = 0;
      for (final id in _scatterStories) {
        final story = loadOracleStory(id);
        final rules = story
            .byTag('line')
            .where((e) => e.strokeDasharray != 'none')
            .toList();
        expect(
          rules,
          hasLength(1),
          reason:
              '$id must capture exactly one dashed line — the hover rule '
              'at ScatterChart.tsx:750-759',
        );
        final rule = rules.single;
        expectOracleColour(
          '$id hover rule stroke',
          rule.stroke,
          style.hoverLineColor!.resolve(states),
        );
        expectOracleNumber(
          '$id hover rule stroke width',
          rule.strokeWidth,
          style.hoverLineWidth!.resolve(states)!,
        );
        expect(
          rule.strokeDasharray,
          '5px, 5px',
          reason: '$id — ScatterChart.tsx:759 sets strokeDasharray 5,5',
        );
        expect(
          style.hoverLineDashPattern!.resolve(states),
          <double>[5, 5],
          reason: '$id — the port must carry that same dash pattern',
        );
        asserted++;
      }
      expect(
        asserted,
        _scatterStories.length,
        reason: 'every listed story must have been asserted, not skipped',
      );
    });

    test('Oracle B: a marker circle is stroked one pixel wide', () {
      final style = resolveFluentScatterChartStyle(theme);
      var asserted = 0;
      for (final id in _scatterStories) {
        final story = loadOracleStory(id);
        final circles = story.byTag('circle');
        expect(
          circles,
          isNotEmpty,
          reason: '$id must capture at least one marker circle',
        );
        for (final circle in circles) {
          expectOracleNumber(
            '$id marker stroke width',
            circle.strokeWidth,
            style.markerStrokeWidth!.resolve(states)!,
          );
          expectOracleNumber(
            '$id marker opacity',
            circle.opacity,
            style.markerOpacity!.resolve(states)!,
          );
          asserted++;
        }
      }
      expect(
        asserted,
        greaterThanOrEqualTo(_scatterStories.length),
        reason: 'at least one circle per story must have been asserted',
      );
    });

    test('the active marker inverts to the canvas colour', () {
      final style = resolveFluentScatterChartStyle(theme);
      expect(
        style.activeMarkerFillColor!.resolve(<WidgetState>{
          WidgetState.hovered,
        }),
        theme.colors.neutralBackground1,
        reason:
            'ScatterChart.tsx:356-358 returns colorNeutralBackground1 for '
            'the active point rather than growing a ring',
      );
    });

    test('merge lets the caller win field by field', () {
      final base = resolveFluentScatterChartStyle(theme);
      final merged = base.merge(
        FluentScatterChartStyle.from(markerStrokeWidth: 4),
      );
      expect(
        merged.markerStrokeWidth!.resolve(states),
        4.0,
        reason: 'the overriding style must win',
      );
      expect(
        merged.markerRadius!.resolve(states),
        4.0,
        reason: 'fields absent from the override must be inherited',
      );
    });

    test('equal styles compare equal and hash equal', () {
      final a = FluentScatterChartStyle.from(markerRadius: 4);
      final b = FluentScatterChartStyle.from(markerRadius: 4);
      expect(
        a,
        b,
        reason: 'value equality is part of the house style contract',
      );
      expect(a.hashCode, b.hashCode, reason: 'hashCode must agree with ==');
    });

    test('copyWith replaces only the named field', () {
      final base = resolveFluentScatterChartStyle(theme);
      final copy = base.copyWith(
        markerLabelGap: const WidgetStatePropertyAll<double?>(20),
      );
      expect(
        copy.markerLabelGap!.resolve(states),
        20.0,
        reason: 'the named field must be replaced',
      );
      expect(
        copy.markerLabelMinGap!.resolve(states),
        16.0,
        reason: 'ScatterChart.tsx:484 — the unnamed floor must survive',
      );
    });
  });

  group('FluentScatterChartDelegate', () {
    test('numeric x, numeric y: the centre is the raw scale value', () {
      final delegate = _delegate(
        xValues: <Object>[1, 2, 3],
        yValues: <Object>[10, 20, 30],
      );
      final ctx = _numericContext();
      final marks = delegate.marksFor(ctx);
      expect(
        marks.first.centre.dx,
        ctx.xScale(1),
        reason:
            'ScatterChart.tsx:442 adds _xBandwidth, which is 0 off a string '
            'axis',
      );
      expect(
        marks.first.centre.dy,
        ctx.yScalePrimary(10),
        reason: 'ScatterChart.tsx:412 uses the raw y for a numeric y axis',
      );
    });

    test('string x shifts the centre by half a band', () {
      final delegate = _delegate(
        xValues: <Object>['a', 'b'],
        yValues: <Object>[10, 20],
      );
      final ctx = _bandXContext(<String>['a', 'b']);
      final marks = delegate.marksFor(ctx);
      expect(
        marks.first.centre.dx,
        ctx.xScale('a')! + ctx.xScale.bandwidth / 2,
        reason:
            '_xBandwidth = xScale.bandwidth() / 2 at ScatterChart.tsx:372-373',
      );
    });

    test('string y shifts the centre by half a band too', () {
      final delegate = _delegate(
        xValues: <Object>[1, 2],
        yValues: <Object>['low', 'high'],
      );
      final ctx = _bandYContext(<String>['low', 'high']);
      final marks = delegate.marksFor(ctx);
      expect(
        delegate.yAxisType,
        FluentChartAxisType.category,
        reason:
            'ScatterChart.tsx:124-132 reads the first point of the first '
            'series and calls a String y a band axis',
      );
      expect(
        marks.first.centre.dy,
        ctx.yScalePrimary('low')! + ctx.yScalePrimary.bandwidth / 2,
        reason: 'ScatterChart.tsx:410-412 centres inside the y band',
      );
    });

    test('a non-plottable point is skipped, not drawn at NaN', () {
      final delegate = _delegate(
        xValues: <Object>[1, double.nan, 3],
        yValues: <Object>[10, 20, 30],
      );
      expect(
        delegate.marksFor(_numericContext()).length,
        2,
        reason: 'isPlottable gates the push at ScatterChart.tsx:414-416',
      );
    });

    test('series paint back to front so series 0 lands on top', () {
      final delegate = _delegateOf(<FluentScatterChartSeries>[
        _series('S0', <Object>[1, 2], <Object>[10, 20]),
        _series('S1', <Object>[1, 2], <Object>[30, 40]),
      ]);
      final marks = delegate.marksFor(_numericContext());
      expect(
        marks.first.seriesIndex,
        1,
        reason:
            'ScatterChart.tsx:399 iterates i from _points.length - 1 down to 0',
      );
    });

    test('the y domain carries exactly ONE ten-percent pad', () {
      final delegate = _delegate(
        xValues: <Object>[1, 2],
        yValues: <Object>[10, 90],
      );
      final minMax = delegate.resolveYMinMax();
      expect(
        minMax.startValue,
        closeTo(2, 1e-9),
        reason:
            '10 - 0.1 * (90 - 10) == 2; ScatterChart.tsx:180-190 pads once and '
            'utilities.ts:825-831 is DEAD, adding nothing',
      );
      expect(
        minMax.endValue,
        closeTo(98, 1e-9),
        reason: '90 + 0.1 * (90 - 10) == 98, a single pad only',
      );
    });

    test('the numeric x domain always carries the marker pad', () {
      final delegate = _delegate(
        xValues: <Object>[10, 90],
        yValues: <Object>[1, 2],
      );
      final range = delegate.resolveXDomainRange(
        margins: const FluentChartMargins(left: 64, right: 20),
        containerWidth: 650,
        isRtl: false,
        barWidth: null,
        tickValues: null,
      );
      expect(
        range.dStartValue,
        closeTo(2, 1e-9),
        reason:
            'ScatterChart.tsx:211 hard-codes hasMarkersMode true, so the '
            'numeric x domain is always padded by a tenth of its extent',
      );
      expect(
        range.dEndValue,
        closeTo(98, 1e-9),
        reason: 'the same tenth at the top end',
      );
    });

    test('a date x axis pads in milliseconds', () {
      final delegate = _delegate(
        xValues: <Object>[DateTime.utc(2020), DateTime.utc(2020, 1, 11)],
        yValues: <Object>[1, 2],
      );
      expect(
        delegate.xAxisType,
        FluentChartAxisType.date,
        reason: 'getTypeOfAxis reads the first point of the first series',
      );
      final range = delegate.resolveXDomainRange(
        margins: const FluentChartMargins(left: 64, right: 20),
        containerWidth: 650,
        isRtl: false,
        barWidth: null,
        tickValues: null,
      );
      expect(
        range.dStartValue,
        DateTime.utc(2019, 12, 31),
        reason:
            'utilities.ts:1538 pads a scatter date domain by a tenth of the '
            'ten-day span, which is one day',
      );
      expect(
        range.dEndValue,
        DateTime.utc(2020, 1, 12),
        reason: 'and one day past the last point',
      );
    });

    test('the label baseline is radius + 12 floored at 16', () {
      final delegate = _delegate(
        xValues: <Object>[1],
        yValues: <Object>[10],
        text: 'hello',
      );
      final marks = delegate.marksFor(_numericContext());
      expect(
        marks.single.labelBaselineOffset,
        16,
        reason: 'max(4 + 12, 16) == 16 at ScatterChart.tsx:484',
      );
      expect(
        marks.single.label,
        'hello',
        reason: 'ScatterChart.tsx:480 paints the point text below the marker',
      );
    });

    test('the text-mode guard is wired but typed data cannot trip it', () {
      final delegate = _delegate(xValues: <Object>[1], yValues: <Object>[10]);
      expect(
        isTextMode(delegate.data.scatterChartData!),
        isFalse,
        reason:
            'ScatterChart.tsx:435 guards the whole push on !_isTextMode, but '
            'utilities.ts:2219 reads lineOptions through an `as any` cast and '
            'types/DataPoint.ts:1033-1071 declares no lineOptions on '
            'ScatterChartPoints, so no typed scatter series is in text mode',
      );
      expect(
        delegate.marksFor(_numericContext()),
        hasLength(1),
        reason: 'the guard therefore never suppresses a typed series',
      );
    });

    test('a default string-y order reverses the series traversal', () {
      final delegate = _delegateOf(<FluentScatterChartSeries>[
        _series('S1', <Object>[1, 2], <Object>['s1y1', 's2y1']),
        _series('S2', <Object>[1, 2], <Object>['s2y1', 's2y2']),
      ]);
      expect(
        delegate.orderedYAxisLabels,
        <String>['s2y1', 's2y2', 's1y1'],
        reason:
            'ScatterChart.tsx:299-315 walks series backwards, points '
            'forwards, keeping first-seen order',
      );
    });

    test('a non-default string-y order defers to sortAxisCategories', () {
      final delegate = _delegateOf(<FluentScatterChartSeries>[
        _series('S1', <Object>[1, 2], <Object>['b', 'a']),
      ], order: FluentAxisCategoryOrder.categoryAscending);
      expect(
        delegate.orderedYAxisLabels,
        <String>['a', 'b'],
        reason: 'ScatterChart.tsx:318 delegates any non-default order',
      );
    });

    test('the x categories are collected series- and point-forward', () {
      final delegate = _delegateOf(<FluentScatterChartSeries>[
        _series('S1', <Object>['b', 'a'], <Object>[1, 2]),
        _series('S2', <Object>['a', 'c'], <Object>[3, 4]),
      ]);
      expect(
        delegate.xAxisCategories,
        <String>['b', 'a', 'c'],
        reason:
            'ScatterChart.tsx:710-714 pushes every unique string x in data '
            'order, forwards through both loops',
      );
      expect(
        delegate.datasetForXAxisDomain,
        <String>['b', 'a', 'c'],
        reason: 'CartesianChart.tsx:264 takes that list as the band domain',
      );
    });

    test('a hit region is exactly the circle it was painted from', () {
      final delegate = _delegate(xValues: <Object>[1], yValues: <Object>[10]);
      final ctx = _numericContext();
      final mark = delegate.marksFor(ctx).single;
      final regions = delegate.buildHitRegions(ctx, _layout());
      expect(
        regions.single.bounds,
        Rect.fromCircle(center: mark.centre, radius: mark.radius),
        reason:
            'the circle a user hovers must be the circle that was painted, '
            'so both come from one marksFor call',
      );
      expect(
        regions.single.semanticsLabel,
        '1. S0, 10.',
        reason:
            'ScatterChart.tsx:647-656 joins the x, the legend and the y with '
            '". " and ", " and ends with a full stop',
      );
    });

    test('high contrast flattens the fill and the halo to different slots', () {
      final hc = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      final colours = FluentChartColors.of(hc);
      final delegate = _delegateOf(<FluentScatterChartSeries>[
        _series(
          'S0',
          <Object>[1],
          <Object>[10],
          colour: const Color(0xFF2AA0A4),
        ),
      ], colors: colours);
      final mark = delegate.marksFor(_numericContext()).single;
      expect(
        mark.colour,
        colours.flattenMark(const Color(0xFF2AA0A4)),
        reason:
            'spec §5.3 — a series fill flattens to the system foreground '
            'under forced colours',
      );
      expect(
        mark.strokeColour,
        colours.flattenMarkStroke(const Color(0xFF2AA0A4)),
        reason:
            'spec §5.3 — the halo flattens to the canvas instead, so adjacent '
            'markers stay separable',
      );
      expect(
        mark.colour,
        isNot(mark.strokeColour),
        reason:
            'sending both to CanvasText would merge the circle into its own '
            'outline',
      );
    });

    test('Oracle B: the string story band centres, radii and z-order', () {
      final story = loadOracleStory(
        'charts-scatterchart--scatter-chart-string',
      );
      final circles = story.byTag('circle');
      expect(
        circles,
        hasLength(10),
        reason: 'ScatterChartString draws two series of five points',
      );
      // The categories in the captured x-axis tick order.
      const categories = <String>[
        'Electronics',
        'Furniture',
        'Clothing',
        'Toys',
        'Books',
      ];
      // The band scale the capture was drawn with: the range the captured
      // domain path `M64.5,6V0.5H630.5V6` encodes once the 0.5 crispness
      // offset is removed, at the 0.1 shorthand padding of utilities.ts:574.
      final xScale = d3.scaleBand()
        ..domainOf(categories)
        ..rangeOf(<double>[64, 630])
        ..paddingInner(0.1)
        ..paddingOuter(0.1);
      for (final (i, category) in categories.indexed) {
        final tick = story.elements.firstWhere(
          (element) =>
              element.tag == 'text' &&
              element.text == category &&
              element.parent >= 0,
        );
        expectOracleNumber(
          'x tick $category',
          story.absoluteTranslate(story.parentOf(tick)!).dx,
          xScale(category)! + xScale.bandwidth / 2,
        );
        expect(
          i,
          lessThan(categories.length),
          reason: 'every captured tick must have been asserted',
        );
      }
      // The y scale: 0 at pixel 255 and 65.2k at pixel 20, read off the
      // captured y-axis tick transforms with the same 0.5 offset removed.
      final yScale = d3.scaleLinear()
        ..domainOf(<double>[0, 65200])
        ..rangeOf(<double>[255, 20]);
      // Marker sizes are recoverable only up to an affine transform, because
      // `calculateMarkerRadius`'s band branch normalises them into [4, 16]
      // (`utilities.ts:2352`). This set — min 1, max 13 — is the one that
      // reproduces every captured radius exactly.
      final delegate = _delegateOf(<FluentScatterChartSeries>[
        _series(
          'Store B',
          categories,
          <Object>[50000, 30000, 20000, 15000, 10000],
          colour: const Color(0xFF2AA0A4),
          markerSizes: <double>[10.5, 8, 5.5, 3, 2],
        ),
        _series(
          'Store A',
          categories,
          <Object>[60000, 25000, 22000, 12000, 8000],
          colour: const Color(0xFF9373C0),
          markerSizes: <double>[13, 7, 6, 4, 1],
        ),
      ]);
      final marks = delegate.marksFor(
        FluentCartesianChildContext(
          xScale: xScale,
          yScalePrimary: yScale,
          containerWidth: 650,
          containerHeight: 310,
        ),
      );
      expect(
        marks,
        hasLength(circles.length),
        reason: 'one mark per captured circle',
      );
      var asserted = 0;
      for (final (i, circle) in circles.indexed) {
        expectOracleOffset(
          'circle $i centre',
          Offset(circle.cx!, circle.cy!),
          marks[i].centre,
        );
        expectOracleNumber('circle $i radius', circle.r!, marks[i].radius);
        expectOracleColour('circle $i stroke', circle.stroke, marks[i].colour);
        asserted++;
      }
      expect(
        asserted,
        circles.length,
        reason: 'every captured circle must have been asserted, not skipped',
      );
      expect(
        marks.first.seriesIndex,
        1,
        reason:
            'the capture paints the LAST series first — ScatterChart.tsx:399 '
            'counts down, so series 0 ends up on top',
      );
    });
  });
}

FluentScatterChartSeries _series(
  String legend,
  List<Object> xValues,
  List<Object> yValues, {
  Color? colour,
  List<double>? markerSizes,
}) => FluentScatterChartSeries(
  legend: legend,
  color: colour,
  data: <FluentScatterChartDataPoint>[
    for (var i = 0; i < xValues.length; i++)
      FluentScatterChartDataPoint(
        x: xValues[i],
        y: yValues[i],
        markerSize: markerSizes?[i],
      ),
  ],
);

FluentScatterChartDelegate _delegateOf(
  List<FluentScatterChartSeries> series, {
  FluentChartColors? colors,
  FluentAxisCategoryOrder order = FluentAxisCategoryOrder.defaultOrder,
}) {
  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
  return FluentScatterChartDelegate(
    data: FluentChartData(scatterChartData: series),
    style: resolveFluentScatterChartStyle(theme),
    colors: colors ?? FluentChartColors.of(theme),
    textStyles: FluentChartTextStyles.of(theme),
    measurer: FluentChartTextMeasurer(),
    selectedLegends: const <String>[],
    yAxisCategoryOrder: order,
  );
}

FluentScatterChartDelegate _delegate({
  required List<Object> xValues,
  required List<Object> yValues,
  String? text,
}) => _delegateOf(<FluentScatterChartSeries>[
  FluentScatterChartSeries(
    legend: 'S0',
    data: <FluentScatterChartDataPoint>[
      for (var i = 0; i < xValues.length; i++)
        FluentScatterChartDataPoint(x: xValues[i], y: yValues[i], text: text),
    ],
  ),
]);

FluentCartesianChildContext _numericContext() => FluentCartesianChildContext(
  xScale: d3.scaleLinear()
    ..domainOf(<double>[0, 10])
    ..rangeOf(<double>[64, 630]),
  yScalePrimary: d3.scaleLinear()
    ..domainOf(<double>[0, 100])
    ..rangeOf(<double>[255, 20]),
  containerWidth: 650,
  containerHeight: 310,
);

FluentCartesianChildContext _bandXContext(List<String> categories) =>
    FluentCartesianChildContext(
      xScale: d3.scaleBand()
        ..domainOf(categories)
        ..rangeOf(<double>[64, 630])
        ..paddingInner(0.1)
        ..paddingOuter(0.1),
      yScalePrimary: d3.scaleLinear()
        ..domainOf(<double>[0, 100])
        ..rangeOf(<double>[255, 20]),
      containerWidth: 650,
      containerHeight: 310,
    );

FluentCartesianChildContext _bandYContext(List<String> categories) =>
    FluentCartesianChildContext(
      xScale: d3.scaleLinear()
        ..domainOf(<double>[0, 10])
        ..rangeOf(<double>[64, 630]),
      yScalePrimary: d3.scaleBand()
        ..domainOf(categories)
        ..rangeOf(<double>[255, 20])
        ..paddingInner(0.1)
        ..paddingOuter(0.1),
      containerWidth: 650,
      containerHeight: 310,
    );

FluentCartesianLayout _layout() => FluentCartesianLayout.resolve(
  size: const Size(650, 310),
  margins: const FluentChartMargins(top: 20, bottom: 55, left: 64, right: 20),
  xAxisLabelReserve: 0,
  isRtl: false,
  startFromX: 0,
);
