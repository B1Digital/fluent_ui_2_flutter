// The axis engine end to end. Every symbol below except `axis_geometry.dart`
// arrives through `package:fluent_2_web/fluent_2_web.dart`, so a missing export
// line in the barrel fails compilation rather than an assertion — which is half
// of what this file is for. The other half is the Oracle B group at the bottom,
// the first check in the programme that runs the real chain (domain resolution
// -> builder -> label layout -> painter) against geometry captured from the live
// React implementation, rather than checking each stage against itself.
//
// `src/charts/internal/d3/axis_geometry.dart` is deep imported because
// `src/charts/internal/d3/**` is deliberately not exported (see the comment
// above the charts block in `lib/fluent_2_web.dart`, and
// `test/charts/d3/kernel_boundaries_test.dart`, which enforces it).
import 'dart:ui' as ui;

import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:fluent_2_web/src/charts/internal/d3/axis_geometry.dart' as d3;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/oracle_fixture.dart';

/// The metrics Chrome recorded for one captured `text` element.
///
/// [OracleElement.bbox] is the box `getBBox()` returned in the tick group's
/// space and [OracleElement.y] is the SVG anchor, so the distance from the box
/// top to the alphabetic baseline is `y + 0.71 * fontSize - bbox.top`. Reading it
/// back out of the capture is what lets the painter be checked against the
/// browser's own line box without Segoe UI installed.
FluentChartTextMetrics _metricsOf(OracleElement text) {
  final bbox = text.bbox!;
  final fontSize = text.fontSize;
  // 0.71 is the bottom-axis `dy` of d3-axis/src/axis.js:72.
  final ascent = text.y! + 0.71 * fontSize - bbox.top;
  return FluentChartTextMetrics(
    width: bbox.width,
    height: bbox.height,
    ascent: ascent,
    descent: bbox.height - ascent,
    xHeight: fontSize * FluentChartTextMetrics.xHeightRatio,
  );
}

/// Replays the glyph metrics Chrome recorded for one Oracle B label.
///
/// Not a second measurer: the production measurer is the only thing that ever
/// measures text, and under `flutter test` it cannot reproduce the Segoe UI
/// stack the capture resolved because that font is not installed. Feeding it the
/// captured advance width and baseline distance is what lets the whole chain be
/// compared against the live browser rather than against itself. An unknown
/// label throws, so a re-capture that changes the tick set fails loudly instead
/// of quietly measuring zero.
class _ReplayedMeasurer extends FluentChartTextMeasurer {
  _ReplayedMeasurer(this.captured);

  /// Metrics by label text.
  final Map<String, FluentChartTextMetrics> captured;

  @override
  FluentChartTextMetrics measure(String text, TextStyle style) {
    final metrics = captured[text];
    if (metrics == null) {
      throw StateError('No captured metrics for "$text".');
    }
    return metrics;
  }
}

/// Records every line and paragraph the painter draws, so the test can assert
/// geometry rather than pixels.
class _RecordingCanvas implements Canvas {
  final List<(Offset, Offset)> lines = <(Offset, Offset)>[];
  final List<Offset> paragraphOffsets = <Offset>[];

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) => lines.add((p1, p2));

  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) =>
      paragraphOffsets.add(offset);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  // The measurer builds a TextPainter, which needs a binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  const margins = FluentChartMargins(left: 40, right: 20, top: 20, bottom: 35);

  test('a numeric x axis flows from domain resolution to a painted geometry', () {
    final series = <Object>[
      const FluentLineChartSeries(
        legend: 'a',
        data: <Object>[
          FluentLineChartDataPoint(x: 0, y: 5),
          FluentLineChartDataPoint(x: 100, y: 95),
        ],
      ),
    ];

    final domain = domainRangeOfNumericForAreaLineScatterCharts(
      series,
      margins,
      700,
      isRtl: false,
    );
    expect(
      domain.rEndValue,
      680,
      reason: 'utilities.ts:1372 — width 700 minus the right margin 20.',
    );

    final spec = createNumericXAxis(
      FluentXAxisParams(
        domainNRangeValues: domain,
        containerHeight: 300,
        containerWidth: 700,
        margins: margins,
        showRoundOffXTickValues: true,
      ),
      const FluentTickParams(),
      FluentChartType.lineChart,
    );
    expect(
      spec.tickLabels,
      <String>['0', '20', '40', '60', '80', '100'],
      reason: 'the whole chain resolves to d3 ticks formatted for the locale.',
    );

    final geometry = d3.FluentAxisGeometry(
      orientation: spec.orientation,
      scale: spec.scale,
      tickValues: spec.tickValues,
      tickLabels: spec.tickLabels,
      // flutter test runs at devicePixelRatio 1, so d3-axis picks 0.5.
      offset: 0.5,
      tickSizeInner: spec.tickSizeInner,
      tickSizeOuter: spec.tickSizeOuter,
      tickPadding: spec.tickPadding,
    );
    expect(
      geometry.ticks.first.position,
      40.5,
      reason:
          'the range starts at the left margin 40 and d3-axis adds the crisp '
          'offset of 0.5 once (d3-axis/src/axis.js:98).',
    );
    expect(
      geometry.spacing,
      16,
      reason:
          'max(tickSizeInner 6, 0) + tickPadding 10, so the label baseline sits '
          '16 below the axis line.',
    );
  });

  test(
    'a numeric y axis writes its resolved domain into the shared axis data',
    () {
      final axisData = FluentAxisData();
      final spec = createNumericYAxis(
        const FluentYAxisParams(
          margins: margins,
          containerWidth: 700,
          containerHeight: 300,
          yMinMaxValues: FluentChartMinMax(startValue: 0, endValue: 100),
          tickPadding: 10,
        ),
        axisData,
        isRtl: false,
        isIntegralDataset: true,
        chartType: FluentChartType.lineChart,
      );
      expect(
        axisData.yAxisTickText,
        spec.tickLabels,
        reason:
            'utilities.ts:890 keeps the two in step for the popover and export.',
      );
      expect(
        spec.tickSizeInner,
        lessThan(0),
        reason:
            'a numeric y axis always draws full-width gridlines '
            '(utilities.ts:851).',
      );
    },
  );

  test('a band x axis with auto layout reserves height for its labels', () {
    final spec = createStringXAxis(
      const FluentXAxisParams(
        domainNRangeValues: FluentChartDomainRange(
          dStartValue: 0,
          dEndValue: 0,
          rStartValue: 40,
          rEndValue: 200,
        ),
        containerHeight: 300,
        containerWidth: 240,
        margins: margins,
        xAxisInnerPadding: 0,
        xAxisOuterPadding: 0,
      ),
      const FluentTickParams(),
      <String>['New South Wales', 'Victoria', 'Queensland'],
    );
    final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
    final layout = autoLayoutXAxisLabels(
      spec.tickValues,
      spec.tickLabels,
      spec.scale,
      240,
      measurer: FluentChartTextMeasurer(),
      style: FluentChartTextStyles.of(theme).axisTick,
    );
    expect(
      layout.reserveHeight,
      greaterThan(0),
      reason:
          'three long names in 240 logical pixels cannot all fit, so the auto '
          'layout wraps or staggers and charges the plot for the extra height.',
    );
    expect(
      layout.labels.length,
      3,
      reason: 'one laid-out label per tick, in tick order.',
    );
  });

  test('every axis symbol is reachable from the package barrel', () {
    // The imports at the head of this file are all from the barrel except the
    // one internal d3 import, so a missing export line fails compilation rather
    // than an assertion. This test states the intent so the reason survives.
    expect(
      FluentChartType.values.isNotEmpty,
      isTrue,
      reason:
          'axis_types, tick_values, tick_format, domain_range, axis_builders, '
          'axis_label_layout and axis_painter each carry one flat export line '
          'in lib/fluent_2_web.dart, alphabetically ordered inside the charts '
          'block.',
    );
  });

  group('Oracle B — the whole chain against charts-areachart--area-chart-basic', () {
    // A 700x260 AreaChart whose x-axis group carries `translate(0, 205)`. Every
    // number below is read out of the fixture rather than typed in, so a
    // re-capture that moves the axis fails these tests instead of silently
    // disagreeing with them.
    const storyId = 'charts-areachart--area-chart-basic';
    final story = loadOracleStory(storyId);
    final width = story.width;
    final crispOffset = story.crispOffset;
    // Element 0 is the x-axis group and element 1 its domain path; every tick is
    // a `g` child of element 0 holding one `line` and one `text`.
    final tickGroups = <OracleElement>[
      for (final element in story.byTag('g'))
        if (element.parent == 0) element,
    ];
    OracleElement childOf(OracleElement group, String tag) =>
        story.childrenOf(group).firstWhere((child) => child.tag == tag);
    // `translate(64.5,0)` -> 64.5.
    double translateX(OracleElement group) => group.translate!.dx;
    final capturedLabels = <String>[
      for (final group in tickGroups) childOf(group, 'text').text!,
    ];
    final capturedMetrics = <String, FluentChartTextMetrics>{
      for (final group in tickGroups)
        childOf(group, 'text').text!: _metricsOf(childOf(group, 'text')),
    };
    final measurer = _ReplayedMeasurer(capturedMetrics);
    final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
    final style = FluentChartTextStyles.of(theme).axisTick;

    // The domain path is `M64.5,6V0.5H680.5V6`: the two verticals are the
    // tickSizeOuter end caps and the horizontal runs the range, offset by the
    // crispness half-pixel. Reading the range back off it is what fixes the
    // margins below, rather than guessing at the shell's margin solver.
    final domainPath = story
        .soleElement('path', where: (element) => element.parent == 0)
        .d!;
    final domainEnds = RegExp(
      r'^M([-\d.]+),[-\d.]+V[-\d.]+H([-\d.]+)',
    ).firstMatch(domainPath)!;
    final rStart = double.parse(domainEnds.group(1)!) - crispOffset;
    final rEnd = double.parse(domainEnds.group(2)!) - crispOffset;
    // rStart is the left margin and rEnd is the width less the right margin
    // (`utilities.ts:1371-1372`), so the two invert to the margins the capture
    // was laid out with. 20 is DEFAULT_MARGIN_NO_TICKS (`CartesianChart.tsx:42`)
    // and 35 the bottom margin of an x axis with labels and no title; neither is
    // read by a numeric x axis of a line-family chart, and both are named here
    // only so the params bag is honest.
    final capturedMargins = FluentChartMargins(
      left: rStart,
      right: width - rEnd,
      top: 20,
      bottom: 35,
    );

    /// The resolved domain, as the shell would resolve it.
    ///
    /// The fixture pins the *resolved* domain — its first and last tick sit
    /// exactly on the range ends — not the raw series, so the two points below
    /// are the minimal series with that extent. Only the extent reaches
    /// `getScatterXDomainExtent` (`utilities.ts:2282-2300`), and
    /// `nice()` is a no-op on a domain that is already a multiple of the tick
    /// step, so this reproduces the captured axis whatever the story's
    /// intermediate x values were.
    FluentChartDomainRange resolvedDomain() =>
        domainRangeOfNumericForAreaLineScatterCharts(
          <Object>[
            FluentLineChartSeries(
              legend: capturedLabels.first,
              data: <Object>[
                FluentLineChartDataPoint(
                  x: double.parse(capturedLabels.first),
                  y: 0,
                ),
                FluentLineChartDataPoint(
                  x: double.parse(capturedLabels.last),
                  y: 0,
                ),
              ],
            ),
          ],
          capturedMargins,
          width,
          isRtl: false,
        );

    /// The axis the builders resolve from that domain.
    ///
    /// `hideTickOverlap` defaults to true in the shell
    /// (`CartesianChart.tsx:51`) and `showRoundOffXTickValues` to true
    /// (`CartesianChart.tsx:212`), and `calcMaxLabelWidth` is wired to
    /// `calcMaxLabelWidthWithTransform` (`CartesianChart.tsx:221`) — which is
    /// what turns the six-tick default into the ten the capture shows.
    FluentAxisSpec resolvedSpec() => createNumericXAxis(
      FluentXAxisParams(
        domainNRangeValues: resolvedDomain(),
        containerHeight: story.height,
        containerWidth: width,
        margins: capturedMargins,
        showRoundOffXTickValues: true,
        hideTickOverlap: true,
        calcMaxLabelWidth: (labels) => calcMaxLabelWidthWithTransform(
          labels,
          measurer: measurer,
          style: style,
          xAxisType: FluentChartAxisType.numeric,
        ),
      ),
      const FluentTickParams(),
      FluentChartType.areaChart,
    );

    d3.FluentAxisGeometry geometryOf(FluentAxisSpec spec) =>
        d3.FluentAxisGeometry(
          orientation: spec.orientation,
          scale: spec.scale,
          tickValues: spec.tickValues,
          tickLabels: spec.tickLabels,
          offset: crispOffset,
          tickSizeInner: spec.tickSizeInner,
          tickSizeOuter: spec.tickSizeOuter,
          tickPadding: spec.tickPadding,
        );

    test('the fixture is the axis these tests believe it is', () {
      expect(
        story.deviceScaleFactor,
        1,
        reason:
            'a capture at any other device scale factor would carry a crispness '
            'offset of 0, and every tick position below would be half a pixel '
            'out.',
      );
      expect(
        tickGroups.length,
        15,
        reason:
            '$storyId captured fifteen x ticks, 20 through 90 in steps of five. '
            'A renamed or re-captured element set that matched nothing would '
            'otherwise leave every loop below asserting on zero ticks.',
      );
      expect(
        <double>[rStart, rEnd],
        <double>[64, 680],
        reason:
            'the domain path $domainPath pins the range, and the margins these '
            'tests hand the domain resolver are that range inverted.',
      );
    });

    test('domain resolution reproduces the captured domain and range', () {
      final domain = resolvedDomain();
      expect(
        <Object>[domain.dStartValue, domain.dEndValue],
        <double>[20, 90],
        reason:
            'utilities.ts:1377 — the x extent, ascending in LTR, is the 20..90 '
            'the captured first and last labels name.',
      );
      expect(
        <double>[domain.rStartValue, domain.rEndValue],
        <double>[rStart, rEnd],
        reason:
            'utilities.ts:1371-1372 — the range is the left margin to the width '
            'less the right margin, which is the captured domain path.',
      );
    });

    test('the builder reproduces the captured tick values and labels', () {
      final spec = resolvedSpec();
      expect(
        spec.tickValues,
        <double>[for (var v = 20.0; v <= 90.0; v += 5.0) v],
        reason:
            'the widest label ceils to 12 and utilities.ts:298 adds 20, so '
            'floor(616 / 32) is 19, clamped to the ten-tick ceiling at :300. '
            'ticks(20, 90, 10) steps by five.',
      );
      expect(
        spec.tickLabels,
        capturedLabels,
        reason:
            'formatToLocaleString groups only from 10000 up '
            '(`chart-utilities/formatter.ts:40`), so these are plain integers.',
      );
    });

    test('the geometry reproduces the captured tick transforms', () {
      final geometry = geometryOf(resolvedSpec());
      final ticks = geometry.ticks;
      expect(
        ticks.length,
        tickGroups.length,
        reason: 'one resolved tick per captured tick group.',
      );
      for (var i = 0; i < tickGroups.length; i++) {
        expect(
          ticks[i].position,
          closeTo(translateX(tickGroups[i]), kOracleGeometryTolerance),
          reason:
              'axis_geometry adds the crispness offset once to position(d) '
              '(`d3-axis/src/axis.js:76`), so tick $i must land on the captured '
              'translate.',
        );
      }
      expect(
        geometry.spacing,
        closeTo(childOf(tickGroups.first, 'text').y!, kOracleGeometryTolerance),
        reason:
            'max(tickSizeInner, 0) + tickPadding (`d3-axis/src/axis.js:46`) is '
            'the captured text y.',
      );
    });

    test('auto layout leaves a comfortable numeric axis alone', () {
      final spec = resolvedSpec();
      final layout = autoLayoutXAxisLabels(
        spec.tickValues,
        spec.tickLabels,
        spec.scale,
        width,
        measurer: measurer,
        style: style,
      );
      expect(
        layout.labels.map((l) => l.lines.single.text).toList(),
        capturedLabels,
        reason:
            'a two-character label in a 44-pixel slot fits, so utilities.ts:2641 '
            'returns the labels untouched, one line each.',
      );
      expect(
        <Object>[layout.reserveHeight, layout.rotationRadians],
        <double>[0, 0],
        reason:
            'nothing wrapped, staggered or rotated, so the plot is charged no '
            'extra height — upstream returns the bare 0 at utilities.ts:2641, '
            'and the Dart port spells that as reserveHeight 0 with no rotation.',
      );
      expect(
        layout.labels.every((l) => !l.truncated),
        isTrue,
        reason: 'no label needed truncating.',
      );
    });

    test('the painter lands on the captured lines and label boxes', () {
      final spec = resolvedSpec();
      final geometry = geometryOf(spec);
      final layout = autoLayoutXAxisLabels(
        spec.tickValues,
        spec.tickLabels,
        spec.scale,
        width,
        measurer: measurer,
        style: style,
      );
      final canvas = _RecordingCanvas();
      FluentAxisPainter(
        geometry: geometry,
        labelLayout: layout,
        textStyles: FluentChartTextStyles.of(theme),
        colors: FluentChartColors.of(theme),
        measurer: measurer,
        isRtl: false,
      ).paint(canvas, Size(width, geometry.spacing + 14));
      expect(
        canvas.lines.length,
        tickGroups.length,
        reason: 'one painted line per captured tick, and no domain path.',
      );
      for (var i = 0; i < tickGroups.length; i++) {
        final expectedX = translateX(tickGroups[i]);
        final tickHeight = childOf(tickGroups[i], 'line').y2!;
        expect(
          canvas.lines[i].$1,
          within(
            distance: kOracleGeometryTolerance,
            from: Offset(expectedX, 0),
          ),
          reason:
              'the captured line has no y1, so tick $i starts on the axis at '
              'its own translate.',
        );
        expect(
          canvas.lines[i].$2,
          within(
            distance: kOracleGeometryTolerance,
            from: Offset(expectedX, tickHeight),
          ),
          reason:
              'the captured line has no x2 and ends at y2 $tickHeight, which is '
              "the axis's tickSizeInner below it.",
        );
        // The bbox is [x, y, width, height] in the tick group's own space, so
        // the absolute origin adds the group's translate.
        final bbox = childOf(tickGroups[i], 'text').bbox!;
        expect(
          canvas.paragraphOffsets[i],
          within(
            distance: kOracleGeometryTolerance,
            from: Offset(expectedX + bbox.left, bbox.top),
          ),
          reason:
              'text-anchor is middle (d3-axis/src/axis.js:111) and dy is 0.71em '
              '(:72), so label $i of width ${bbox.width} starts there.',
        );
      }
    });
  });
}
