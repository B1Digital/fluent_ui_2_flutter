import 'dart:ui' as ui;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/axis/axis_label_layout.dart';
import 'package:fluent_2_web/src/charts/axis/axis_painter.dart';
import 'package:fluent_2_web/src/charts/internal/chart_colors.dart';
import 'package:fluent_2_web/src/charts/internal/chart_text_measurer.dart';
import 'package:fluent_2_web/src/charts/internal/chart_text_styles.dart';
import 'package:fluent_2_web/src/charts/internal/d3/axis_geometry.dart' as d3;
import 'package:fluent_2_web/src/charts/internal/d3/scale_linear.dart' as d3;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/oracle_fixture.dart';

/// Records every line and paragraph the painter draws, so the test can assert
/// geometry rather than pixels.
class _RecordingCanvas implements Canvas {
  final List<(Offset, Offset, Paint)> lines = <(Offset, Offset, Paint)>[];
  final List<Offset> paragraphOffsets = <Offset>[];

  int get paragraphCount => paragraphOffsets.length;

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) =>
      lines.add((p1, p2, paint));

  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) =>
      paragraphOffsets.add(offset);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Replays the glyph metrics Chrome recorded for one Oracle B label.
///
/// Not a second measurer: the production measurer is the only thing that ever
/// measures text, and under `flutter test` it cannot reproduce the Segoe UI
/// stack the capture resolved because that font is not installed. Feeding it the
/// captured advance width and baseline distance is what lets the painted label
/// origin be compared against the live browser rather than against itself.
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  d3.FluentAxisGeometry bottomGeometry() {
    final scale = d3.scaleLinear()
      ..domainOf(<double>[0, 100])
      ..rangeOf(<double>[0, 200]);
    return d3.FluentAxisGeometry(
      orientation: d3.FluentAxisOrientation.bottom,
      scale: scale,
      tickValues: <Object>[0, 50, 100],
      tickLabels: const <String>['0', '50', '100'],
      // flutter test runs at devicePixelRatio 1, so d3-axis picks 0.5.
      offset: 0.5,
      tickSizeInner: 6,
      tickSizeOuter: 6,
      tickPadding: 10,
    );
  }

  test('draws one line per tick and no domain path', () {
    final canvas = _RecordingCanvas();
    FluentAxisPainter(
      geometry: bottomGeometry(),
      labelLayout: null,
      textStyles: FluentChartTextStyles.of(theme),
      colors: FluentChartColors.of(theme),
      measurer: FluentChartTextMeasurer(),
      isRtl: false,
    ).paint(canvas, const Size(200, 40));
    expect(
      canvas.lines.length,
      3,
      reason:
          'three ticks and no domain path — useCartesianChartStyles.styles.ts:73-75 '
          'hides the path with display: none.',
    );
  });

  test('paints tick lines at twenty per cent opacity', () {
    final canvas = _RecordingCanvas();
    final colors = FluentChartColors.of(theme);
    FluentAxisPainter(
      geometry: bottomGeometry(),
      labelLayout: null,
      textStyles: FluentChartTextStyles.of(theme),
      colors: colors,
      measurer: FluentChartTextMeasurer(),
      isRtl: false,
    ).paint(canvas, const Size(200, 40));
    expect(
      canvas.lines.first.$3.color.toARGB32(),
      colors.axisTick.withValues(alpha: 0.2).toARGB32(),
      reason:
          'useCartesianChartStyles.styles.ts:67-72 sets opacity 0.2 on every '
          'axis line, stroked with colorNeutralForeground1.',
    );
    expect(
      canvas.lines.first.$3.strokeWidth,
      1,
      reason:
          "the CSS declares width: '1px', which is not a stroke property and is "
          'dropped, leaving the SVG default stroke-width of 1.',
    );
  });

  test('places the first tick at the range start plus the crisp offset', () {
    final canvas = _RecordingCanvas();
    FluentAxisPainter(
      geometry: bottomGeometry(),
      labelLayout: null,
      textStyles: FluentChartTextStyles.of(theme),
      colors: FluentChartColors.of(theme),
      measurer: FluentChartTextMeasurer(),
      isRtl: false,
    ).paint(canvas, const Size(200, 40));
    expect(
      canvas.lines.first.$1.dx,
      0.5,
      reason:
          'd3-axis/src/axis.js:98 adds the offset ONCE, so a tick at 0 lands at '
          '0.5 on a one-times display. Not 0.25.',
    );
  });

  test('paints one paragraph per tick label', () {
    final canvas = _RecordingCanvas();
    FluentAxisPainter(
      geometry: bottomGeometry(),
      labelLayout: null,
      textStyles: FluentChartTextStyles.of(theme),
      colors: FluentChartColors.of(theme),
      measurer: FluentChartTextMeasurer(),
      isRtl: false,
    ).paint(canvas, const Size(200, 40));
    expect(
      canvas.paragraphCount,
      3,
      reason: 'one label per tick, painted through a TextPainter.',
    );
  });

  test('paints every line of a wrapped label', () {
    final canvas = _RecordingCanvas();
    const layout = FluentXAxisLabelLayout(
      labels: <FluentAxisTickLabel>[
        FluentAxisTickLabel(
          lines: <FluentAxisLabelLine>[
            FluentAxisLabelLine(text: 'New', dyEm: 0.71),
            FluentAxisLabelLine(text: 'South', dyEm: 1.81),
          ],
          fullText: 'New South',
          truncated: true,
        ),
        FluentAxisTickLabel(
          lines: <FluentAxisLabelLine>[
            FluentAxisLabelLine(text: 'Vic', dyEm: 0.71),
          ],
          fullText: 'Vic',
          truncated: false,
        ),
        FluentAxisTickLabel(
          lines: <FluentAxisLabelLine>[
            FluentAxisLabelLine(text: 'Qld', dyEm: 0.71),
          ],
          fullText: 'Qld',
          truncated: false,
        ),
      ],
      reserveHeight: 12,
      rotationRadians: 0,
    );
    FluentAxisPainter(
      geometry: bottomGeometry(),
      labelLayout: layout,
      textStyles: FluentChartTextStyles.of(theme),
      colors: FluentChartColors.of(theme),
      measurer: FluentChartTextMeasurer(),
      isRtl: false,
    ).paint(canvas, const Size(200, 40));
    expect(
      canvas.paragraphCount,
      4,
      reason: 'two lines on the first label plus one each on the other two.',
    );
  });

  test('repaints when the geometry changes and not otherwise', () {
    final painter = FluentAxisPainter(
      geometry: bottomGeometry(),
      labelLayout: null,
      textStyles: FluentChartTextStyles.of(theme),
      colors: FluentChartColors.of(theme),
      measurer: FluentChartTextMeasurer(),
      isRtl: false,
    );
    expect(
      painter.shouldRepaint(painter),
      isFalse,
      reason: 'an identical delegate carries identical geometry.',
    );
  });

  group('Oracle B — charts-areachart--area-chart-basic x axis', () {
    // The story is a 700x260 AreaChart whose x-axis group carries
    // `translate(0, 205)`; every number below is read out of the fixture rather
    // than typed in, so a re-capture that moves the axis fails this test instead
    // of silently disagreeing with it.
    final story = loadOracleStory('charts-areachart--area-chart-basic');
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
    final domainPathElement = story.soleElement(
      'path',
      where: (element) => element.parent == 0,
    );

    /// The captured axis, rebuilt from the fixture's own numbers.
    ///
    /// The domain is the story's 20..90 value range and the range the plot's
    /// 64..680 band, which are what produce the captured `translate` values; the
    /// tick length is the `y2` of every captured tick line and the label gap the
    /// captured text `y` minus that length.
    d3.FluentAxisGeometry capturedGeometry() {
      final line = childOf(tickGroups.first, 'line');
      final text = childOf(tickGroups.first, 'text');
      final tickSizeInner = line.y2!;
      final scale = d3.scaleLinear()
        ..domainOf(<double>[20, 90])
        ..rangeOf(<double>[64, 680]);
      return d3.FluentAxisGeometry(
        orientation: d3.FluentAxisOrientation.bottom,
        scale: scale,
        tickValues: <Object>[for (var v = 20.0; v <= 90.0; v += 5.0) v],
        tickLabels: <String>[
          for (final group in tickGroups) childOf(group, 'text').text!,
        ],
        // The fixture records deviceScaleFactor 1 and crispOffset 0.5.
        offset: story.crispOffset,
        tickSizeInner: tickSizeInner,
        tickSizeOuter: 6,
        tickPadding: text.y! - tickSizeInner,
      );
    }

    test('the fixture is the axis this test believes it is', () {
      expect(
        story.deviceScaleFactor,
        1,
        reason:
            'a capture at any other device scale factor would carry a crispness '
            'offset of 0, and every tick position below would be half a pixel out.',
      );
      expect(
        tickGroups.length,
        15,
        reason:
            'the story renders ticks 20 through 90 in steps of five. A renamed '
            'or re-captured element set that matched nothing would otherwise '
            'leave the loops below asserting on zero ticks.',
      );
      expect(
        domainPathElement.d,
        'M64.5,6V0.5H680.5V6',
        reason:
            'the domain path pins the range ends and the crispness offset, which '
            'is what makes 64..680 the right range to rebuild the scale over.',
      );
    });

    test('the painted tick lines land on the captured tick transforms', () {
      final canvas = _RecordingCanvas();
      FluentAxisPainter(
        geometry: capturedGeometry(),
        labelLayout: null,
        textStyles: FluentChartTextStyles.of(theme),
        colors: FluentChartColors.of(theme),
        measurer: _ReplayedMeasurer(<String, FluentChartTextMetrics>{
          for (final group in tickGroups)
            childOf(group, 'text').text!: _metricsOf(childOf(group, 'text')),
        }),
        isRtl: false,
      ).paint(canvas, const Size(700, 55));
      expect(
        canvas.lines.length,
        tickGroups.length,
        reason: 'one painted line per captured tick, and no domain path.',
      );
      for (var i = 0; i < tickGroups.length; i++) {
        final expected = translateX(tickGroups[i]);
        final tickHeight = childOf(tickGroups[i], 'line').y2!;
        expect(
          canvas.lines[i].$1.dx,
          closeTo(expected, kOracleGeometryTolerance),
          reason:
              'tick $i sits at translate($expected,0) in the live SVG, so the '
              'painted line must start there — d3-axis/src/axis.js:98 adds the '
              '0.5 offset once.',
        );
        expect(
          canvas.lines[i].$1.dy,
          closeTo(0, kOracleGeometryTolerance),
          reason:
              'the captured line has no y1, so it starts on the axis itself.',
        );
        expect(
          canvas.lines[i].$2.dx,
          closeTo(expected, kOracleGeometryTolerance),
          reason: 'the captured line has no x2, so it is vertical.',
        );
        expect(
          canvas.lines[i].$2.dy,
          closeTo(tickHeight, kOracleGeometryTolerance),
          reason:
              'the captured line ends at y2 $tickHeight, which is the axis’s '
              'tickSizeInner below it.',
        );
      }
    });

    test('the painted label origin matches the captured text box', () {
      final canvas = _RecordingCanvas();
      final geometry = capturedGeometry();
      FluentAxisPainter(
        geometry: geometry,
        labelLayout: null,
        textStyles: FluentChartTextStyles.of(theme),
        colors: FluentChartColors.of(theme),
        measurer: _ReplayedMeasurer(<String, FluentChartTextMetrics>{
          for (final group in tickGroups)
            childOf(group, 'text').text!: _metricsOf(childOf(group, 'text')),
        }),
        isRtl: false,
      ).paint(canvas, const Size(700, 55));
      for (var i = 0; i < tickGroups.length; i++) {
        final text = childOf(tickGroups[i], 'text');
        final bbox = text.bbox!;
        // The bbox is in the tick group's own space, so the absolute origin adds
        // the group's translate.
        final expected = Offset(
          translateX(tickGroups[i]) + bbox.left,
          bbox.top,
        );
        expect(
          canvas.paragraphOffsets[i].dx,
          closeTo(expected.dx, kOracleGeometryTolerance),
          reason:
              'text-anchor is middle (d3-axis/src/axis.js:111), so a label of '
              'width ${bbox.width} centred on the tick starts at ${expected.dx}.',
        );
        expect(
          canvas.paragraphOffsets[i].dy,
          closeTo(expected.dy, kOracleGeometryTolerance),
          reason:
              'the captured text sits at y ${text.y} with dy 0.71em '
              '(d3-axis/src/axis.js:72) at font size 10, putting its baseline '
              '7.1 below the anchor and its box top at ${expected.dy}.',
        );
      }
    });
  });
}

/// The metrics Chrome recorded for one captured `text` element.
///
/// [OracleElement.bbox] is the box `getBBox()` returned in the tick group's
/// space and [OracleElement.y] is the SVG anchor, so the distance from the box
/// top to the alphabetic baseline is `y + 0.71 * fontSize - bbox.top` — 11.0
/// logical pixels for this story's 10px stack. Reading it back out of the
/// capture is what lets the painter be checked against the browser's own line
/// box without Segoe UI installed.
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
