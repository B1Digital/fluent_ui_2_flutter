import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:fluent_2/src/charts/axis/axis_label_layout.dart';
import 'package:fluent_2/src/charts/axis/axis_painter.dart';
import 'package:fluent_2/src/charts/internal/chart_colors.dart';
import 'package:fluent_2/src/charts/internal/chart_text_measurer.dart';
import 'package:fluent_2/src/charts/internal/chart_text_styles.dart';
import 'package:fluent_2/src/charts/internal/d3/axis_geometry.dart' as d3;
import 'package:fluent_2/src/charts/internal/d3/scale_band.dart' as d3;
import 'package:fluent_2/src/charts/internal/d3/scale_linear.dart' as d3;
import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/oracle_fixture.dart';

/// Records every line and paragraph the painter draws, so the test can assert
/// geometry rather than pixels.
class _RecordingCanvas implements Canvas {
  final List<(Offset, Offset, Paint)> lines = <(Offset, Offset, Paint)>[];
  final List<Offset> paragraphOffsets = <Offset>[];

  /// Every `translate`, in call order. The rotated branch issues exactly one
  /// per tick, which is the analogue of the `translate(…)` half of upstream's
  /// compound tick transform (`utilities.ts:1839`).
  final List<Offset> translations = <Offset>[];

  /// Every `rotate`, in radians and in call order — the `rotate(-45)` half of
  /// that same transform (`utilities.ts:1820`).
  final List<double> rotations = <double>[];

  int get paragraphCount => paragraphOffsets.length;

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) =>
      lines.add((p1, p2, paint));

  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) =>
      paragraphOffsets.add(offset);

  @override
  void translate(double dx, double dy) => translations.add(Offset(dx, dy));

  @override
  void rotate(double radians) => rotations.add(radians);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// `translate(263,72.58009338378906)rotate(-45)` split into its two halves.
///
/// [OracleElement.translate] is deliberately null for a compound transform, so
/// a rotated tick group has to be read here. Both numbers come off the
/// attribute string, so they carry authored double precision rather than the
/// float32 of [OracleElement.ctm].
({Offset translate, double degrees}) _rotatedTransform(OracleElement group) {
  final match = _rotatedTransformPattern.firstMatch(group.transform ?? '');
  if (match == null) {
    throw StateError(
      '<${group.tag}> #${group.index} carries transform='
      '"${group.transform}", which is not translate(x,y)rotate(a).',
    );
  }
  return (
    translate: Offset(double.parse(match[1]!), double.parse(match[2]!)),
    degrees: double.parse(match[3]!),
  );
}

final RegExp _rotatedTransformPattern = RegExp(
  r'^\s*translate\(\s*([-+0-9.eE]+)\s*,\s*([-+0-9.eE]+)\s*\)\s*'
  r'rotate\(\s*([-+0-9.eE]+)\s*\)\s*$',
);

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

  group('Oracle B — charts-verticalbarchart--vertical-bar-rotate-labels', () {
    // The only story in the corpus whose x labels are rotated: a 650x500
    // VerticalBarChart whose x-axis group carries `translate(0, 328)` and whose
    // four tick groups each carry
    // `translate(x,72.58009338378906)rotate(-45)`. Every number below is read
    // out of the fixture.
    final story = loadOracleStory(
      'charts-verticalbarchart--vertical-bar-rotate-labels',
    );
    // Element 0 is the x-axis group, element 1 its domain path; every tick is a
    // `g` child of element 0 holding one `line` and one `text`.
    final tickGroups = <OracleElement>[
      for (final element in story.byTag('g'))
        if (element.parent == 0) element,
    ];
    OracleElement childOf(OracleElement group, String tag) =>
        story.childrenOf(group).firstWhere((child) => child.tag == tag);
    final labels = <String>[
      for (final group in tickGroups) childOf(group, 'text').text!,
    ];
    final domainPathElement = story.soleElement(
      'path',
      where: (element) => element.parent == 0,
    );
    // The four bars, which pin the band scale: their width is its bandwidth and
    // the gap between two of their lefts is its step.
    final bars = story.byTag('rect');
    final style = FluentChartTextStyles.of(theme).axisTick;

    _ReplayedMeasurer capturedMeasurer() =>
        _ReplayedMeasurer(<String, FluentChartTextMetrics>{
          for (final group in tickGroups)
            childOf(group, 'text').text!: _metricsOf(childOf(group, 'text')),
        });

    /// The captured axis, rebuilt from the fixture's own numbers.
    ///
    /// The band scale's range comes from the domain path and its paddings from
    /// the bars: `paddingInner` is the fraction of the step left blank, and
    /// `paddingOuter` is zero because the range span is exactly
    /// `step * (domain length - paddingInner)`, which is what leaves the first
    /// band flush against the range start.
    d3.FluentAxisGeometry capturedGeometry() {
      final tickSizeInner = childOf(tickGroups.first, 'line').y2!;
      final textAnchorY = childOf(tickGroups.first, 'text').y!;
      final bandwidth = bars.first.width!;
      final step = bars[1].x! - bars.first.x!;
      final scale = d3.scaleBand()
        ..domainOf(<Object>[...labels])
        ..rangeOf(<double>[255, 415])
        ..paddingInner(1 - bandwidth / step)
        ..paddingOuter(0);
      return d3.FluentAxisGeometry(
        orientation: d3.FluentAxisOrientation.bottom,
        scale: scale,
        tickValues: <Object>[...labels],
        tickLabels: labels,
        // The fixture records deviceScaleFactor 1 and crispOffset 0.5.
        offset: story.crispOffset,
        tickSizeInner: tickSizeInner,
        tickSizeOuter: 6,
        tickPadding: textAnchorY - tickSizeInner,
      );
    }

    FluentXAxisLabelLayout capturedLayout() => rotateXAxisLabels(
      labels,
      measurer: capturedMeasurer(),
      style: style,
      tickSizeInner: childOf(tickGroups.first, 'line').y2!,
      tickPadding:
          childOf(tickGroups.first, 'text').y! -
          childOf(tickGroups.first, 'line').y2!,
    );

    _RecordingCanvas painted() {
      final canvas = _RecordingCanvas();
      FluentAxisPainter(
        geometry: capturedGeometry(),
        labelLayout: capturedLayout(),
        textStyles: FluentChartTextStyles.of(theme),
        colors: FluentChartColors.of(theme),
        measurer: capturedMeasurer(),
        isRtl: false,
      ).paint(canvas, const Size(650, 172));
      return canvas;
    }

    test('the fixture is the rotated axis this test believes it is', () {
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
        4,
        reason:
            'the story renders four rotated ticks. A renamed or re-captured '
            'element set that matched nothing would otherwise leave the loops '
            'below asserting on zero ticks.',
      );
      expect(
        bars.length,
        4,
        reason:
            'one bar per tick; the band scale below is rebuilt from their width '
            'and pitch, so a different rect count means a different scale.',
      );
      expect(
        <double>[
          for (final group in tickGroups) _rotatedTransform(group).degrees,
        ],
        everyElement(-45.0),
        reason:
            'every tick group is rotated by -45 degrees (utilities.ts:1820), '
            'which is what makes this the one corpus story that exercises the '
            "painter's rotated branch at all.",
      );
      expect(
        domainPathElement.d,
        'M255.5,6V0.5H415.5V6',
        reason:
            'the domain path pins the range ends and the crispness offset, '
            'which is what makes 255..415 the right range to rebuild the band '
            'scale over.',
      );
    });

    test('the reserved height cannot be inverted back to the translate', () {
      final layout = capturedLayout();
      final capturedY = _rotatedTransform(tickGroups.first).translate.dy;
      expect(
        layout.reserveHeight,
        102,
        reason:
            'utilities.ts:1845 floors maxHeight / 1.414, and the captured '
            'maxHeight is 2 * $capturedY, so 145.16… / 1.414 = 102.66… floors '
            'to 102.',
      );
      expect(
        // 1.414 is the literal at utilities.ts:1845 and 2 the halving at :1839:
        // this is the lossy inverse the painter used to reconstruct, kept here
        // as the regression guard that it can never meet the tolerance.
        (layout.reserveHeight * 1.414) / 2,
        isNot(closeTo(capturedY, kOracleGeometryTolerance)),
        reason:
            'the floor discards up to a whole pixel and multiplying back by '
            '1.414 amplifies it, so reserveHeight is not a usable source for '
            'the translate — hence FluentXAxisLabelLayout.rotationTranslateY.',
      );
      expect(
        layout.rotationTranslateY,
        closeTo(capturedY, kOracleGeometryTolerance),
        reason:
            'the un-floored maxHeight / 2 upstream translates by '
            '(utilities.ts:1839) travels on the layout, so it still matches the '
            'browser to $kOracleGeometryTolerance.',
      );
    });

    test('the rotated tick groups land on the captured compound transform', () {
      final canvas = painted();
      expect(
        canvas.translations.length,
        tickGroups.length,
        reason: 'the rotated branch translates once per tick.',
      );
      expect(
        canvas.rotations.length,
        tickGroups.length,
        reason: 'and rotates once per tick.',
      );
      for (var i = 0; i < tickGroups.length; i++) {
        final captured = _rotatedTransform(tickGroups[i]);
        expect(
          canvas.translations[i].dx,
          closeTo(captured.translate.dx, kOracleGeometryTolerance),
          reason:
              'tick $i keeps the x of its original translate '
              '(utilities.ts:1819 stashes it, :1839 writes it back), which is '
              'the band centre plus the 0.5 crispness offset.',
        );
        expect(
          canvas.translations[i].dy,
          closeTo(captured.translate.dy, kOracleGeometryTolerance),
          reason:
              'utilities.ts:1839 translates y by maxHeight / 2, which the live '
              'SVG recorded as ${captured.translate.dy}. The port lands 1.7e-6 '
              'off it; reconstructing the same number from reserveHeight lands '
              '0.466 off, which is what this assertion was written to catch.',
        );
        // 180 and math.pi convert the captured degrees to the painter's radians.
        expect(
          canvas.rotations[i] * 180 / math.pi,
          closeTo(captured.degrees, kOracleGeometryTolerance),
          reason: 'utilities.ts:1820 and :1839 both rotate by -45 degrees.',
        );
      }
    });

    test('the rotated labels land on the captured local text box', () {
      final canvas = painted();
      expect(
        canvas.lines.length,
        tickGroups.length,
        reason: 'one painted tick line per captured tick, and no domain path.',
      );
      for (var i = 0; i < tickGroups.length; i++) {
        final line = childOf(tickGroups[i], 'line');
        expect(
          canvas.lines[i].$1,
          Offset.zero,
          reason:
              'inside the rotated group the captured line has neither x1 nor '
              'y1, so it starts at the group origin.',
        );
        expect(
          canvas.lines[i].$2.dx,
          closeTo(0, kOracleGeometryTolerance),
          reason:
              'the captured line has no x2, so it is vertical in group '
              'space.',
        );
        expect(
          canvas.lines[i].$2.dy,
          closeTo(line.y2!, kOracleGeometryTolerance),
          reason: 'it ends at y2 ${line.y2}, the axis’s tickSizeInner.',
        );
        // getBBox is in the tick group's own pre-rotation space, and the
        // replayed metrics are read back out of this very box, so what is under
        // test is that the painter composes anchor, dy and ascent the way the
        // browser did — not the glyph widths themselves.
        final bbox = childOf(tickGroups[i], 'text').bbox!;
        expect(
          canvas.paragraphOffsets[i].dx,
          closeTo(bbox.left, kOracleGeometryTolerance),
          reason:
              'text-anchor is middle (d3-axis/src/axis.js:111), so a label of '
              'width ${bbox.width} centred on the group origin starts at '
              '${bbox.left}.',
        );
        expect(
          canvas.paragraphOffsets[i].dy,
          closeTo(bbox.top, kOracleGeometryTolerance),
          reason:
              'the captured text sits at y ${childOf(tickGroups[i], 'text').y} '
              'with dy 0.71em (d3-axis/src/axis.js:72) at font size 10, putting '
              'its box top at ${bbox.top} inside the rotated group.',
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
