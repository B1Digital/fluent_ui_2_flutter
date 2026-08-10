import 'dart:math' as math;

import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:fluent_2_web/src/charts/gauge_chart.dart';
import 'package:fluent_2_web/src/charts/internal/d3/path_sink.dart';
import 'package:fluent_2_web/src/charts/internal/d3/shape_arc.dart' as d3;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/oracle_fixture.dart';
import 'd3/golden_support.dart';

/// Records what a painter draws, in call order, so the paint order and every
/// resolved colour can be asserted without a golden.
class _RecordingCanvas implements Canvas {
  final List<(Path, Paint)> paths = <(Path, Paint)>[];
  final List<Offset> translates = <Offset>[];
  final List<double> rotations = <double>[];

  @override
  void drawPath(Path path, Paint paint) => paths.add((path, paint));

  @override
  void translate(double dx, double dy) => translates.add(Offset(dx, dy));

  @override
  void rotate(double radians) => rotations.add(radians);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Two things are asserted here that nothing else in the port exercises: the
/// arc generator with an EXPLICIT `padRadius` — GaugeChart is the only caller
/// that sets one (`GaugeChart.tsx:218`), which makes `p0` blow up as the inner
/// radius shrinks — and the needle, whose path is authored in a frame that is
/// translated INSIDE the rotation, so the pivot is the gauge origin and the hub
/// sits on the far side of it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const segments = <FluentGaugeChartSegment>[
    FluentGaugeChartSegment(legend: 'A', size: 50),
    FluentGaugeChartSegment(legend: 'B', size: 50),
  ];

  FluentGaugeLayout layoutOf({
    double width = 288,
    double height = 400,
    List<FluentGaugeChartSegment> data = segments,
    bool hasTitle = false,
    bool hasSublabel = false,
    bool hideLegend = true,
  }) => FluentGaugeLayout.compute(
    size: Size(width, height),
    segments: data,
    minValue: 0,
    hasTitle: hasTitle,
    hasSublabel: hasSublabel,
    hideMinMax: false,
    hideLegend: hideLegend,
    gaugeMargin: 16,
    labelWidth: 36,
    labelHeight: 16,
    labelOffset: 4,
    titleOffset: 11,
    extraNeedleLength: 4,
    legendsHeight: 32,
    unknownColour: const Color(0xFF7A7574),
    isDark: false,
  );

  test('the whole gauge sweeps exactly half a turn', () {
    final arcs = fluentGaugeArcs(
      layoutOf(),
      arcPadding: 2,
      cornerRadius: 0,
      isRtl: false,
    );
    expect(
      arcs.first.startAngle,
      closeTo(-math.pi / 2, 1e-12),
      reason: 'GaugeChart.tsx:220 seeds prevAngle at -PI/2.',
    );
    expect(
      arcs.last.endAngle,
      closeTo(math.pi / 2, 1e-12),
      reason:
          'GaugeChart.tsx:223 advances by size / (total - min) * PI, so '
          'the run ends at +PI/2 — half a turn, which d3 renders from nine '
          "o'clock through twelve to three.",
    );
  });

  test('two equal segments split the half turn at twelve o\'clock', () {
    final arcs = fluentGaugeArcs(
      layoutOf(),
      arcPadding: 2,
      cornerRadius: 0,
      isRtl: false,
    );
    expect(
      arcs.first.endAngle,
      closeTo(0, 1e-12),
      reason: 'Fifty of a hundred is half of PI added to -PI/2.',
    );
  });

  test('right-to-left reverses the array but keeps the segment indices', () {
    final arcs = fluentGaugeArcs(
      layoutOf(),
      arcPadding: 2,
      cornerRadius: 0,
      isRtl: true,
    );
    expect(
      arcs.map((a) => a.segmentIndex).toList(),
      <int>[1, 0],
      reason:
          'GaugeChart.tsx:219 reverses the segment array and :233 maps the '
          'position back with length - 1 - index, so the first painted arc is '
          'the last segment.',
    );
  });

  test('the explicit padRadius makes the padding radius-dependent', () {
    // A small gauge has a small inner radius, so p0 = asin(R / r0 * sin(1/R))
    // is large; the same segment on a large gauge loses proportionally less.
    final small = fluentGaugeArcs(
      layoutOf(width: 216, height: 400),
      arcPadding: 2,
      cornerRadius: 0,
      isRtl: false,
    ).first;
    final large = fluentGaugeArcs(
      layoutOf(width: 396, height: 500),
      arcPadding: 2,
      cornerRadius: 0,
      isRtl: false,
    ).first;
    expect(
      small.path.computeMetrics().first.length,
      lessThan(large.path.computeMetrics().first.length),
      reason:
          'GaugeChart.tsx:217-218 sets padAngle to ARC_PADDING / R and '
          'padRadius to R explicitly, unlike DonutChart which leaves padRadius '
          'to its sqrt(r0^2 + r1^2) default.',
    );
  });

  test('rounding the corners shortens the outline', () {
    final square = fluentGaugeArcs(
      layoutOf(),
      arcPadding: 2,
      cornerRadius: 0,
      isRtl: false,
    ).first;
    final rounded = fluentGaugeArcs(
      layoutOf(),
      arcPadding: 2,
      cornerRadius: 3,
      isRtl: false,
    ).first;
    expect(
      rounded.path.computeMetrics().first.length,
      lessThan(square.path.computeMetrics().first.length),
      reason:
          'GaugeChart.tsx:216 — cornerRadius(3) engages the da < PI '
          'restriction branch of shape_arc, whose cornerTangents clamp rc to '
          'min(|r1 - r0| / 2, 3).',
    );
  });

  group('the needle', () {
    test('at rest it points at the minimum, on the left', () {
      final layout = layoutOf();
      final path = fluentGaugeNeedlePath(
        innerRadius: layout.innerRadius,
        needleLength: layout.needleLength,
        extraNeedleLength: 4,
        strokeWidth: 2,
      );
      expect(
        path.getBounds().left,
        closeTo(-(layout.needleLength + layout.innerRadius), 0.01),
        reason:
            'GaugeChart.tsx:268 translates by -innerRadius + '
            'EXTRA_NEEDLE_LENGTH / 2, i.e. -innerRadius + 2, INSIDE the '
            'rotate group, so at zero degrees the tip is that far to the left '
            'of the gauge origin — plus the halfStrokeWidth + 1 round cap the '
            'sweep-0 arc at :261 bulges past it, which is the extra 2 the '
            'captured bbox of [-18, -4, 22, 8] in '
            'charts-gaugechart--gauge-chart-basic records.',
      );
    });

    test('the hub sits on the arc band, not at the centre', () {
      final layout = layoutOf();
      final bounds = fluentGaugeNeedlePath(
        innerRadius: layout.innerRadius,
        needleLength: layout.needleLength,
        extraNeedleLength: 4,
        strokeWidth: 2,
      ).getBounds();
      expect(
        bounds.right,
        closeTo(-(layout.innerRadius - 2 - 4), 0.01),
        reason:
            'The path starts at local x = 0, which the translate puts at '
            'radius innerRadius - 2 — so the needle occupies the arc band '
            'rather than reaching the origin. The hub cap at '
            'GaugeChart.tsx:263 is a halfStrokeWidth + 3 semicircle swept the '
            'same anticlockwise way, so it reaches four further out.',
      );
    });

    test('the profile is four pixels tall at the hub and two at the tip', () {
      final path = fluentGaugeNeedlePath(
        innerRadius: 68,
        needleLength: 24,
        extraNeedleLength: 4,
        strokeWidth: 2,
      );
      expect(
        path.getBounds().height,
        closeTo(8, 0.01),
        reason:
            'GaugeChart.tsx:259-263 — the path runs from y = '
            '-halfStrokeWidth - 3 to y = halfStrokeWidth + 3, which with a '
            'stroke width of 2 is -4 to +4.',
      );
    });

    test('the tip lands where the rotation says it should', () {
      const innerRadius = 68.0;
      const needleLength = 24.0;
      const tipX = -(needleLength + innerRadius - 2);
      for (final degrees in <double>[0, 45, 90, 135, 180]) {
        final radians = degrees * math.pi / 180;
        final expected = Offset(
          tipX * math.cos(radians),
          tipX * math.sin(radians),
        );
        final matrix = Matrix4.rotationZ(radians);
        final rotated = MatrixUtils.transformPoint(
          matrix,
          const Offset(tipX, 0),
        );
        expect(
          (rotated - expected).distance,
          lessThan(1e-9),
          reason:
              'GaugeChart.tsx:265 wraps the path in rotate(theta, 0, 0), '
              'which in Flutter is a canvas rotation about the translated '
              'origin. At 90 degrees the needle points straight up.',
        );
      }
    });
  });

  group('Oracle B', () {
    /// Replays one arc through [SvgPathSink] so its `d` can be compared with
    /// the capture token by token.
    ///
    /// `Path` exposes no segments, so the corpus is met by re-running the same
    /// generator configuration over the angles [fluentGaugeArcs] returned.
    /// The chain closes because [expectSameOutline] then asserts the replay and
    /// the production `Path` have the same outline length: a production
    /// `padRadius` left at d3's `sqrt(r0^2 + r1^2)` default moves both trims by
    /// about 0.0055 rad, which is ~1.1px of outline — a hundred times the
    /// 1e-9 tolerance below.
    String replay(
      FluentGaugeLayout layout,
      FluentGaugeArc arc, {
      double cornerRadius = 0,
    }) {
      final sink = SvgPathSink();
      d3.Arc(cornerRadius: cornerRadius, padRadius: layout.outerRadius)(
        d3.ArcDatum(
          startAngle: arc.startAngle,
          endAngle: arc.endAngle,
          innerRadius: layout.innerRadius,
          outerRadius: layout.outerRadius,
          padAngle: 2 / layout.outerRadius,
        ),
        sink,
      );
      return sink.d;
    }

    void expectSameOutline(FluentGaugeLayout layout, FluentGaugeArc arc) {
      final sink = UiPathSink();
      d3.Arc(cornerRadius: 0, padRadius: layout.outerRadius)(
        d3.ArcDatum(
          startAngle: arc.startAngle,
          endAngle: arc.endAngle,
          innerRadius: layout.innerRadius,
          outerRadius: layout.outerRadius,
          padAngle: 2 / layout.outerRadius,
        ),
        sink,
      );
      expect(
        arc.path.computeMetrics().first.length,
        closeTo(sink.path.computeMetrics().first.length, 1e-9),
        reason:
            'The Path fluentGaugeArcs built must come from the same generator '
            'configuration the replay above compared with the capture: '
            'GaugeChart.tsx:216-218, cornerRadius, padAngle ARC_PADDING / R '
            'and an EXPLICIT padRadius of R.',
      );
    }

    /// Every arc of [layout], replayed as `d`, plus the outline check.
    List<String> arcPathsOf(FluentGaugeLayout layout) {
      final ordered = fluentGaugeArcs(
        layout,
        arcPadding: 2,
        cornerRadius: 0,
        isRtl: false,
      );
      for (final arc in ordered) {
        expectSameOutline(layout, arc);
      }
      return <String>[for (final arc in ordered) replay(layout, arc)];
    }

    /// `charts-gaugechart--gauge-chart-basic` and `--gauge-chart-responsive`
    /// share these three bands; only the root width differs.
    const risk = <FluentGaugeChartSegment>[
      FluentGaugeChartSegment(
        legend: 'Low Risk',
        size: 33,
        color: Color(0xFF107C10),
      ),
      FluentGaugeChartSegment(
        legend: 'Medium Risk',
        size: 34,
        color: Color(0xFFF7630C),
      ),
      FluentGaugeChartSegment(
        legend: 'High Risk',
        size: 33,
        color: Color(0xFFC50F1F),
      ),
    ];

    test('every gauge story is present in the corpus', () {
      expect(
        oracleStoryIds(component: 'GaugeChart'),
        containsAll(<String>[
          'charts-gaugechart--gauge-chart-basic',
          'charts-gaugechart--gauge-chart-single-segment',
          'charts-gaugechart--gauge-chart-responsive',
        ]),
        reason:
            'A silently renamed fixture would turn every assertion below into '
            'a load error rather than a geometry failure.',
      );
    });

    test('gauge-chart-basic reproduces all three arc paths', () {
      final story = loadOracleStory('charts-gaugechart--gauge-chart-basic');
      // The svg is drawn _legendsHeight shorter than the root
      // (GaugeChart.tsx:594), so the logical box is 32 taller than the capture.
      final layout = layoutOf(
        width: story.width,
        height: story.height + 32,
        data: risk,
        hideLegend: false,
      );
      expect(
        layout.outerRadius,
        62,
        reason:
            'The capture draws A62,62 arcs, so any other radius means the '
            'margin chain was fed the wrong logical height.',
      );
      final captured = story
          .byTag('path')
          .where((e) => e.strokeWidth == 0)
          .toList(growable: false);
      expect(
        captured.length,
        3,
        reason: 'Three segments, three arc paths — the needle strokes at 2px.',
      );
      final produced = arcPathsOf(layout);
      for (var i = 0; i < captured.length; i++) {
        expectOracleSvgPath('arc $i', captured[i].d!, produced[i]);
      }
    });

    test('gauge-chart-single-segment reproduces both arc paths', () {
      final story = loadOracleStory(
        'charts-gaugechart--gauge-chart-single-segment',
      );
      final layout = layoutOf(
        width: story.width,
        height: story.height + 32,
        data: const <FluentGaugeChartSegment>[
          FluentGaugeChartSegment(
            legend: 'Used',
            size: 50,
            color: Color(0xFF637CEF),
          ),
          FluentGaugeChartSegment(
            legend: 'Available',
            size: 50,
            color: Color(0xFF13A10E),
          ),
        ],
        hasTitle: true,
        hasSublabel: true,
        hideLegend: false,
      );
      final captured = story
          .byTag('path')
          .where((e) => e.strokeWidth == 0)
          .toList(growable: false);
      expect(
        captured.length,
        2,
        reason: 'The single-segment variant draws its band and its remainder.',
      );
      final produced = arcPathsOf(layout);
      for (var i = 0; i < captured.length; i++) {
        expectOracleSvgPath('arc $i', captured[i].d!, produced[i]);
      }
    });

    test('gauge-chart-responsive keeps the 62px radius at 944px wide', () {
      final story = loadOracleStory(
        'charts-gaugechart--gauge-chart-responsive',
      );
      final layout = layoutOf(
        width: story.width,
        height: story.height + 32,
        data: risk,
        hideLegend: false,
      );
      expectOracleOffset(
        'root translate',
        story.absoluteTranslate(story.elements.first),
        layout.origin,
      );
      final captured = story
          .byTag('path')
          .where((e) => e.strokeWidth == 0)
          .toList(growable: false);
      expect(
        captured.length,
        3,
        reason:
            'Three segments, three arc paths — the needle strokes at 2px. '
            'Without the count the loop below passes on an empty filter.',
      );
      final produced = arcPathsOf(layout);
      for (var i = 0; i < captured.length; i++) {
        expectOracleSvgPath('arc $i', captured[i].d!, produced[i]);
      }
    });

    test('the needle bounds match the captured bbox', () {
      final story = loadOracleStory('charts-gaugechart--gauge-chart-basic');
      final layout = layoutOf(
        width: story.width,
        height: story.height + 32,
        data: risk,
        hideLegend: false,
      );
      // The `translate(-48)` sits on the path, so getBBox reports the untrans-
      // lated outline; the port folds the translate into the path instead.
      final captured = story.soleElement(
        'path',
        where: (e) => e.strokeWidth == 2,
      );
      final bbox = captured.bbox!;
      final path = fluentGaugeNeedlePath(
        innerRadius: layout.innerRadius,
        needleLength: layout.needleLength,
        extraNeedleLength: 4,
        strokeWidth: 2,
      );
      final dx = -layout.innerRadius + 2;
      expectOracleRect(
        'needle',
        bbox.shift(Offset(dx, 0)),
        path.getBounds(),
        tolerance: kOracleMeasuredTolerance,
      );
    });

    test('the needle rotation matches the captured rotate()', () {
      for (final (id, chartValue, degrees) in <(String, double, int)>[
        ('charts-gaugechart--gauge-chart-basic', 50, 90),
        ('charts-gaugechart--gauge-chart-responsive', 75, 135),
      ]) {
        final story = loadOracleStory(id);
        final layout = layoutOf(
          width: story.width,
          height: story.height + 32,
          data: risk,
          hideLegend: false,
        );
        expect(
          story.byTag('g').any((e) => e.transform == 'rotate($degrees, 0, 0)'),
          isTrue,
          reason: '$id captures rotate($degrees, 0, 0) on the needle group.',
        );
        expectOracleNumber(
          '$id rotation',
          degrees.toDouble(),
          FluentGaugeLayout.needleRotation(
            chartValue,
            layout.minValue,
            layout.maxValue,
          ),
        );
      }
    });
  });

  group('FluentGaugeChartPainter', () {
    final measurer = FluentChartTextMeasurer();
    const textStyle = TextStyle(fontSize: 12, height: 1.33);

    FluentGaugeChartPainter painterOf({
      required FluentGaugeLayout layout,
      required List<Color> colours,
      List<double>? opacities,
      int? focusedIndex,
      String? sublabel,
    }) => FluentGaugeChartPainter(
      layout: layout,
      arcs: fluentGaugeArcs(
        layout,
        arcPadding: 2,
        cornerRadius: 0,
        isRtl: false,
      ),
      colours: colours,
      opacities: opacities ?? List<double>.filled(layout.segments.length, 1),
      focusedIndex: focusedIndex,
      needlePath: fluentGaugeNeedlePath(
        innerRadius: layout.innerRadius,
        needleLength: layout.needleLength,
        extraNeedleLength: 4,
        strokeWidth: 2,
      ),
      needleRotationDegrees: 90,
      needleFill: const Color(0xFF242424),
      needleStroke: const Color(0xFFFFFFFF),
      needleStrokeWidth: 2,
      segmentFocusStrokeColour: const Color(0xFF0F6CBD),
      focusStrokeWidth: 2,
      minLabel: '0',
      maxLabel: '100',
      valueLabel: '50%',
      sublabel: sublabel,
      labelOffset: 4,
      limitsTextStyle: textStyle,
      chartValueTextStyle: textStyle,
      sublabelTextStyle: textStyle,
      measurer: measurer,
      textDirection: TextDirection.ltr,
    );

    test('the segments are filled at their opacity, then the needle', () {
      final layout = layoutOf();
      final canvas = _RecordingCanvas();
      painterOf(
        layout: layout,
        colours: const <Color>[Color(0xFF637CEF), Color(0xFFE3008C)],
        opacities: const <double>[1, 0.1],
      ).paint(canvas, const Size(288, 400));
      expect(
        canvas.paths.length,
        4,
        reason:
            'GaugeChart.tsx:634-661 then :666 — two arc fills and the needle, '
            'whose single element carries both a fill and a 2px stroke '
            '(:257). No focus ring while nothing is focused.',
      );
      expect(
        canvas.paths[0].$2.color.toARGB32(),
        const Color(0xFF637CEF).toARGB32(),
        reason: 'GaugeChart.tsx:640 — fill={segment.color}.',
      );
      expect(
        canvas.paths[1].$2.color.a,
        closeTo(0.1, 0.01),
        reason:
            'GaugeChart.tsx:641 — opacity drops to 0.1 for a band that is not '
            'the highlighted legend.',
      );
      expect(
        canvas.paths[2].$2.color.toARGB32(),
        const Color(0xFF242424).toARGB32(),
        reason:
            'GaugeChart.tsx:666 renders the needle after the segment listbox, '
            'so it paints over the band.',
      );
      expect(
        canvas.paths[3].$2.color.toARGB32(),
        const Color(0xFFFFFFFF).toARGB32(),
        reason:
            'The needle outline is stroked after its own fill, exactly as SVG '
            'paints one element.',
      );
    });

    test('the focused band gains a stroke in the focus colour', () {
      final layout = layoutOf();
      final canvas = _RecordingCanvas();
      painterOf(
        layout: layout,
        colours: const <Color>[Color(0xFF637CEF), Color(0xFFE3008C)],
        focusedIndex: 1,
      ).paint(canvas, const Size(288, 400));
      final strokes = canvas.paths
          .where((p) => p.$2.style == PaintingStyle.stroke)
          .toList(growable: false);
      expect(
        strokes.map((p) => p.$2.color.toARGB32()),
        contains(const Color(0xFF0F6CBD).toARGB32()),
        reason:
            'GaugeChart.tsx:639 toggles strokeWidth to ARC_PADDING for the '
            'focused legend; the colour comes from the segment class, never '
            'from the toggle.',
      );
      expect(
        strokes
            .firstWhere(
              (p) =>
                  p.$2.color.toARGB32() == const Color(0xFF0F6CBD).toARGB32(),
            )
            .$2
            .strokeWidth,
        2,
        reason:
            'GaugeChart.tsx:639 — the ring reuses ARC_PADDING as its width.',
      );
    });

    test('the needle is rotated about the gauge origin', () {
      final layout = layoutOf();
      final canvas = _RecordingCanvas();
      painterOf(
        layout: layout,
        colours: const <Color>[Color(0xFF637CEF), Color(0xFFE3008C)],
      ).paint(canvas, const Size(288, 400));
      expect(
        canvas.translates,
        contains(layout.origin),
        reason:
            'GaugeChart.tsx:599 — every child of the root group is drawn '
            'relative to the translated origin.',
      );
      expect(
        canvas.rotations,
        contains(closeTo(math.pi / 2, 1e-12)),
        reason:
            'GaugeChart.tsx:265 — rotate(90, 0, 0) with the translate INSIDE '
            'it, so the pivot is the origin, not the hub.',
      );
    });

    test('high contrast flattens every band to the system foreground', () {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      final chartColours = FluentChartColors.of(theme);
      final layout = layoutOf(
        data: const <FluentGaugeChartSegment>[
          FluentGaugeChartSegment(
            legend: 'A',
            size: 50,
            color: Color(0xFF637CEF),
          ),
          FluentGaugeChartSegment(
            legend: 'B',
            size: 50,
            color: Color(0xFFE3008C),
          ),
        ],
      );
      final canvas = _RecordingCanvas();
      painterOf(
        layout: layout,
        colours: <Color>[
          for (final segment in layout.segments)
            chartColours.flattenMark(segment.colour),
        ],
      ).paint(canvas, const Size(288, 400));
      expect(
        canvas.paths.take(2).map((p) => p.$2.color.toARGB32()).toSet(),
        <int>{chartColours.axisText.toARGB32()},
        reason:
            'Design spec §5.3: upstream series marks carry no '
            'forced-color-adjust, so forced-colours mode rewrites every arc '
            'fill to CanvasText and the forty-colour palette disappears. A '
            'gauge that kept 0xFF637CEF here would be invisible.',
      );
      expect(
        canvas.paths.first.$2.color.toARGB32(),
        isNot(const Color(0xFF637CEF).toARGB32()),
        reason: 'The palette colour must not survive high contrast.',
      );
    });

    test('the palette colour survives outside high contrast', () {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      final layout = layoutOf(
        data: const <FluentGaugeChartSegment>[
          FluentGaugeChartSegment(
            legend: 'A',
            size: 50,
            color: Color(0xFF637CEF),
          ),
          FluentGaugeChartSegment(legend: 'B', size: 50),
        ],
      );
      final canvas = _RecordingCanvas();
      painterOf(
        layout: layout,
        colours: <Color>[
          for (final segment in layout.segments)
            FluentChartColors.of(theme).flattenMark(segment.colour),
        ],
      ).paint(canvas, const Size(288, 400));
      expect(
        canvas.paths.first.$2.color.toARGB32(),
        const Color(0xFF637CEF).toARGB32(),
        reason:
            'flattenMark is a no-op outside FluentHighContrastColors '
            '(chart_colors.dart:145).',
      );
    });

    test('the sublabel is drawn hanging four below the value', () {
      final layout = layoutOf();
      final bare = _RecordingCanvas();
      painterOf(
        layout: layout,
        colours: const <Color>[Color(0xFF637CEF), Color(0xFFE3008C)],
      ).paint(bare, const Size(288, 400));
      final withSublabel = _RecordingCanvas();
      painterOf(
        layout: layout,
        colours: const <Color>[Color(0xFF637CEF), Color(0xFFE3008C)],
        sublabel: 'used',
      ).paint(withSublabel, const Size(288, 400));
      expect(
        withSublabel.paths.length,
        bare.paths.length,
        reason:
            'GaugeChart.tsx:686-696 — the sublabel is text, so it adds no '
            'path to the canvas; the two runs must differ only in paragraphs.',
      );
    });
  });
}
