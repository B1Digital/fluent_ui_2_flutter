import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:fluent_2_web/src/charts/chrome/legend_shape.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/oracle_fixture.dart';

/// `LegendShape` is `'default' | 'triangle' | keyof Points | keyof CustomPoints`
/// (`Legends.types.ts:269`), which resolves to ten distinct strings once the
/// duplicated `'triangle'` is collapsed.
void main() {
  group('FluentChartLegendShape', () {
    test('carries exactly the ten upstream shapes', () {
      expect(
        FluentChartLegendShape.values.length,
        10,
        reason:
            "Legends.types.ts:269 unions 'default', 'triangle', the eight "
            'Points members (utilities.ts:1713-1721) and the one CustomPoints '
            'member (:1723-1725); triangle appears twice and collapses.',
      );
    });

    test('orders the eight Points members at their upstream ordinals', () {
      // utilities.ts:1713-1721 — circle, square, triangle, diamond, pyramid,
      // hexagon, pentagon, octagon. ChartPopover.tsx:216 indexes this enum with
      // `index % 8`, so the order is behaviour, not decoration.
      expect(
        <FluentChartLegendShape>[
          FluentChartLegendShape.circle,
          FluentChartLegendShape.square,
          FluentChartLegendShape.triangle,
          FluentChartLegendShape.diamond,
          FluentChartLegendShape.pyramid,
          FluentChartLegendShape.hexagon,
          FluentChartLegendShape.pentagon,
          FluentChartLegendShape.octagon,
        ].map((shape) => shape.pointIndex).toList(),
        <int>[0, 1, 2, 3, 4, 5, 6, 7],
        reason: 'utilities.ts:1713-1721 assigns these implicit ordinals.',
      );
    });

    test('gives the two non-Points members a null point index', () {
      expect(
        FluentChartLegendShape.defaultShape.pointIndex,
        isNull,
        reason: "'default' is not a member of Points (utilities.ts:1713).",
      );
      expect(
        FluentChartLegendShape.dottedLine.pointIndex,
        isNull,
        reason: 'dottedLine lives in CustomPoints (utilities.ts:1723-1725).',
      );
    });
  });

  group('fluentChartLegendShapePath', () {
    test('square is the authored 1..12 box from shape.tsx:21', () {
      final path = fluentChartLegendShapePath(FluentChartLegendShape.square);
      expect(
        path.getBounds(),
        const Rect.fromLTRB(1, 1, 12, 12),
        reason:
            'shape.tsx:21 authors the square as M1 1 L12 1 L12 12 L1 12 L1 1 Z, '
            'so the bounds are exactly 1..12 on both axes before the viewBox shift.',
      );
    });

    test('circle spans the same 1..12 horizontal extent', () {
      final bounds = fluentChartLegendShapePath(
        FluentChartLegendShape.circle,
      ).getBounds();
      expect(
        bounds.left,
        moreOrLessEquals(1, epsilon: 0.001),
        reason: 'shape.tsx:20 starts the two arcs at x = 1.',
      );
      expect(
        bounds.right,
        moreOrLessEquals(12, epsilon: 0.001),
        reason: 'shape.tsx:20 ends the two arcs at x = 12.',
      );
    });

    test('triangle and pyramid share one path', () {
      expect(
        fluentChartLegendShapePath(FluentChartLegendShape.triangle).getBounds(),
        fluentChartLegendShapePath(FluentChartLegendShape.pyramid).getBounds(),
        reason:
            'shape.tsx:22-23 assigns the identical d string to both; only the '
            '180 degree rotation separates them.',
      );
    });

    test('dottedLine is three open dashes, not a closed figure', () {
      final path = fluentChartLegendShapePath(
        FluentChartLegendShape.dottedLine,
      );
      final metrics = path.computeMetrics().toList();
      expect(
        metrics.length,
        3,
        reason:
            'shape.tsx:29 is M0 6 H3 M5 6 H8 M10 6 H13 — three separate '
            'subpaths, so three path metrics.',
      );
      expect(
        path.getBounds(),
        const Rect.fromLTRB(0, 6, 13, 6),
        reason:
            'The dashes run from x = 0 to x = 13 on the single line y = 6, so '
            'the bounds are zero-height.',
      );
    });

    test('defaultShape has no path', () {
      expect(
        fluentChartLegendShapePath(
          FluentChartLegendShape.defaultShape,
        ).computeMetrics().isEmpty,
        isTrue,
        reason:
            'shape.tsx:34-36 falls through to a plain bordered div when the '
            'shape name is not one of the nine keys, so there is nothing to draw.',
      );
    });

    test('width ratios match pointTypes at utilities.ts:1747-1772', () {
      expect(
        kPointWidthRatios[FluentChartLegendShape.hexagon],
        2,
        reason: 'utilities.ts:1764 gives the hexagon a widthRatio of 2.',
      );
      expect(
        kPointWidthRatios[FluentChartLegendShape.pentagon],
        1.168,
        reason: 'utilities.ts:1767 gives the pentagon a widthRatio of 1.168.',
      );
      expect(
        kPointWidthRatios[FluentChartLegendShape.octagon],
        2.414,
        reason: 'utilities.ts:1770 gives the octagon a widthRatio of 2.414.',
      );
      expect(
        kPointWidthRatios[FluentChartLegendShape.circle],
        1,
        reason: 'utilities.ts:1749 gives the circle a widthRatio of 1.',
      );
      expect(
        kPointWidthRatios.containsKey(FluentChartLegendShape.dottedLine),
        isFalse,
        reason:
            'dottedLine is a CustomPoints member (utilities.ts:1724-1726) and '
            'has no pointTypes entry, so it must not appear in the table.',
      );
    });
  });

  group('fluentChartLegendShapePath against Oracle B', () {
    test('the corpus covers four of the nine authored shapes, no more', () {
      final swatches = legendShapeSvgs();
      expect(
        swatches.length,
        14,
        reason:
            'Five stories render a legend swatch as an svg: '
            'charts-legends--legends-basic and --legends-controlled contribute '
            'two each, charts-linechart--line-chart-gaps two, '
            'charts-scatterchart--scatter-chart-log-axis-example two and '
            'charts-vegadeclarativechart--default six. A drop here means the '
            'per-shape assertions below went vacuous.',
      );
      expect(
        swatches.map((swatch) => shapeOfCapturedPath(swatch.$2)).toSet(),
        <FluentChartLegendShape>{
          FluentChartLegendShape.circle,
          FluentChartLegendShape.diamond,
          FluentChartLegendShape.triangle,
          FluentChartLegendShape.dottedLine,
        },
        reason:
            'Only those four of shape.tsx:20-29 appear in the corpus. The '
            'square, pyramid, hexagon, pentagon and octagon paths are therefore '
            'hand-derived from the authored d strings and checked by the '
            'literal-bounds tests above, not against a capture.',
      );
    });

    test('every captured swatch path has the bounds Chromium measured', () {
      final swatches = legendShapeSvgs();
      var checked = 0;
      for (final (storyId, svg) in swatches) {
        final path = svg.elements.single;
        final shape = shapeOfCapturedPath(svg);
        expectOracleRect(
          '$storyId ${shape.name} getBBox',
          path.bbox!,
          fluentChartLegendShapePath(shape).getBounds(),
        );
        checked++;
      }
      expect(
        checked,
        14,
        reason:
            'All fourteen captured swatches must be compared; a filtered loop '
            'that checked none would otherwise pass.',
      );
    });

    test('the viewBox shifts user space by kLegendShapeViewBoxOrigin', () {
      final swatches = legendShapeSvgs();
      for (final (storyId, svg) in swatches) {
        expect(
          svg.viewBox,
          '-1 -1 14 14',
          reason:
              '$storyId: shape.tsx:41 authors viewBox="-1 -1 14 14" on every '
              'swatch svg.',
        );
        final ctm = svg.elements.single.ctm!;
        // ctm[4] and ctm[5] are the e and f translation components.
        expectOracleNumber(
          '$storyId swatch ctm.e',
          kLegendShapeViewBoxOrigin,
          ctm[4],
          tolerance: kOracleMeasuredTolerance,
        );
        expectOracleNumber(
          '$storyId swatch ctm.f',
          kLegendShapeViewBoxOrigin,
          ctm[5],
          tolerance: kOracleMeasuredTolerance,
        );
      }
      expect(swatches.length, 14, reason: 'Count guard for the loop above.');
    });

    test('an unrotated swatch renders at kLegendShapeViewportSize', () {
      final unrotated = legendShapeSvgs()
          .where(
            (swatch) =>
                shapeOfCapturedPath(swatch.$2) !=
                FluentChartLegendShape.diamond,
          )
          .toList();
      expect(
        unrotated.length,
        12,
        reason:
            'Two of the fourteen swatches are diamonds, whose CSS box is the '
            'rotated 14x14 square and so measures 14 * sqrt(2).',
      );
      for (final (storyId, svg) in unrotated) {
        expectOracleNumber(
          '$storyId swatch width',
          kLegendShapeViewportSize,
          svg.width,
          tolerance: kOracleMeasuredTolerance,
        );
        expectOracleNumber(
          '$storyId swatch height',
          kLegendShapeViewportSize,
          svg.height,
          tolerance: kOracleMeasuredTolerance,
        );
      }
    });
  });

  mainPart2();
  mainPart3();
}

/// Renders [painter] into a [kLegendShapeViewportSize] square and returns the
/// raw RGBA bytes, so a pixel can be asserted rather than a call log.
Future<ByteData> renderShape(FluentChartLegendShapePainter painter) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const size = Size(kLegendShapeViewportSize, kLegendShapeViewportSize);
  painter.paint(canvas, size);
  final image = await recorder.endRecording().toImage(
    kLegendShapeViewportSize.toInt(),
    kLegendShapeViewportSize.toInt(),
  );
  final data = await image.toByteData();
  image.dispose();
  return data!;
}

/// The packed ARGB of the device pixel ([x], [y]) inside the RGBA [data] a
/// [renderShape] call returned.
int argbAt(ByteData data, int x, int y) {
  final offset = (y * kLegendShapeViewportSize.toInt() + x) * 4;
  final r = data.getUint8(offset);
  final g = data.getUint8(offset + 1);
  final b = data.getUint8(offset + 2);
  final a = data.getUint8(offset + 3);
  return (a << 24) | (r << 16) | (g << 8) | b;
}

/// The [FluentChartLegendShapePainter] group, called from [main].
void mainPart2() {
  const fill = Color(0xFF0078D4);
  const stroke = Color(0xFF107C10);

  group('FluentChartLegendShapePainter', () {
    test(
      'the viewBox origin shifts the square one pixel down and right',
      () async {
        final data = await renderShape(
          const FluentChartLegendShapePainter(
            shape: FluentChartLegendShape.square,
            fill: fill,
            stroke: stroke,
            strokeWidth: 0,
          ),
        );
        expect(
          argbAt(data, 7, 7),
          fill.toARGB32(),
          reason:
              'The square covers user space 1..12; with the viewBox origin of '
              'shape.tsx:41 that is device 2..13, so the centre is filled.',
        );
        expect(
          argbAt(data, 0, 0),
          0x00000000,
          reason:
              'User-space (0, 0) maps to device (1, 1), so device (0, 0) is '
              'outside every authored shape and stays transparent.',
        );
      },
    );

    test('an unrotated shape reports zero rotation', () {
      expect(
        fluentChartLegendShapeRotation(FluentChartLegendShape.square),
        0,
        reason: 'shape.tsx:44 only rotates the diamond and the pyramid.',
      );
    });

    test('the diamond rotation matches the box Chromium measured', () {
      final diamonds = legendShapeSvgs()
          .where(
            (swatch) =>
                shapeOfCapturedPath(swatch.$2) ==
                FluentChartLegendShape.diamond,
          )
          .toList();
      expect(
        diamonds.length,
        2,
        reason:
            'charts-legends--legends-basic and --legends-controlled each render '
            'one diamond swatch; a drop here makes the loop below vacuous.',
      );
      for (final (storyId, svg) in diamonds) {
        // A kLegendShapeViewportSize square rotated by theta about any origin
        // has the axis-aligned extent size * (|cos theta| + |sin theta|); the
        // origin only moves it. So the captured 19.799 pins the angle the
        // painter applies — and nothing more, which is why the painter's
        // docstring still calls the origin unverified.
        final extent =
            kLegendShapeViewportSize *
            (math
                    .cos(
                      fluentChartLegendShapeRotation(
                        FluentChartLegendShape.diamond,
                      ),
                    )
                    .abs() +
                math
                    .sin(
                      fluentChartLegendShapeRotation(
                        FluentChartLegendShape.diamond,
                      ),
                    )
                    .abs());
        expectOracleNumber(
          '$storyId diamond swatch width',
          extent,
          svg.width,
          tolerance: kOracleMeasuredTolerance,
        );
        expectOracleNumber(
          '$storyId diamond swatch height',
          extent,
          svg.height,
          tolerance: kOracleMeasuredTolerance,
        );
      }
    });

    test('the pyramid rotates a half turn about the viewport corner', () async {
      final data = await renderShape(
        const FluentChartLegendShapePainter(
          shape: FluentChartLegendShape.pyramid,
          fill: fill,
          stroke: stroke,
          strokeWidth: 0,
        ),
      );
      final anyPainted = List<int>.generate(
        kLegendShapeViewportSize.toInt() * kLegendShapeViewportSize.toInt(),
        (i) => argbAt(
          data,
          i % kLegendShapeViewportSize.toInt(),
          i ~/ kLegendShapeViewportSize.toInt(),
        ),
      ).any((argb) => argb != 0x00000000);
      expect(
        anyPainted,
        isFalse,
        reason:
            'rotate(180, 0, 0) at shape.tsx:44 maps the triangle, which spans '
            'x 0..12 and y 0..10, into negative coordinates, so the whole '
            'pyramid falls outside the 14x14 viewport and nothing is drawn. '
            'This is upstream geometry, not a transcription error — see the '
            'Oracle B probe named in the painter docstring.',
      );
    });

    test('shouldRepaint tracks every input', () {
      const a = FluentChartLegendShapePainter(
        shape: FluentChartLegendShape.circle,
        fill: fill,
        stroke: stroke,
      );
      expect(
        a.shouldRepaint(
          const FluentChartLegendShapePainter(
            shape: FluentChartLegendShape.circle,
            fill: fill,
            stroke: stroke,
          ),
        ),
        isFalse,
        reason: 'Identical inputs must not force a repaint.',
      );
      expect(
        a.shouldRepaint(
          const FluentChartLegendShapePainter(
            shape: FluentChartLegendShape.circle,
            fill: stroke,
            stroke: stroke,
          ),
        ),
        isTrue,
        reason:
            'The fill is the dim indicator (Legends.tsx:390-416), so a change '
            'to it must repaint.',
      );
    });
  });
}

/// Every `fui-legend__shape` svg in the Oracle B corpus, paired with the story
/// that rendered it.
///
/// Reached through [OracleStory.svgs] rather than [OracleStory.primary]: the
/// swatch svgs are 14 pixels wide and `primary` is the widest svg, so it is
/// always the chart.
List<(String, OracleSvg)> legendShapeSvgs() {
  final found = <(String, OracleSvg)>[];
  for (final id in oracleStoryIds()) {
    for (final svg in loadOracleStory(id).svgs) {
      if (svg.slot == 'fui-legend__shape') {
        found.add((id, svg));
      }
    }
  }
  return found;
}

/// The [FluentChartLegendShape] whose `pointPath` entry (`shape.tsx:19-30`)
/// [svg] rendered.
///
/// Identified by the authored `d` string rather than by the story, so a
/// re-capture that changes which chart carries which swatch does not silently
/// compare the wrong shape. Whitespace is collapsed because upstream authors
/// double spaces inside three of the nine strings (`shape.tsx:20-21`, `:24`).
FluentChartLegendShape shapeOfCapturedPath(OracleSvg svg) {
  final d = svg.elements.single.d!.replaceAll(RegExp(r'\s+'), ' ').trim();
  final shape = kAuthoredLegendShapePaths[d];
  if (shape == null) {
    throw StateError(
      'The captured swatch path "$d" is not one of the nine strings '
      'shape.tsx:19-30 authors. Either upstream changed a path or the '
      'transcription in kAuthoredLegendShapePaths drifted.',
    );
  }
  return shape;
}

/// `pointPath` (`shape.tsx:19-30`) inverted: authored `d` string to the shape
/// that owns it, whitespace collapsed.
///
/// `pyramid` is absent because `shape.tsx:23` gives it the triangle's exact
/// string, so the mapping is not injective and only one of the two can be
/// recovered from a capture.
const Map<String, FluentChartLegendShape>
kAuthoredLegendShapePaths = <String, FluentChartLegendShape>{
  // shape.tsx:20.
  'M1 6 A5 5 0 1 0 12 6 M1 6 A5 5 0 0 1 12 6': FluentChartLegendShape.circle,
  // shape.tsx:21.
  'M1 1 L12 1 L12 12 L1 12 L1 1 Z': FluentChartLegendShape.square,
  // shape.tsx:22-23 — shared with the pyramid.
  'M6 10L8.74228e-07 -1.04907e-06L12 0L6 10Z': FluentChartLegendShape.triangle,
  // shape.tsx:24.
  'M2 2 L10 2 L10 10 L2 10 L2 2 Z': FluentChartLegendShape.diamond,
  // shape.tsx:25.
  'M9 0H3L0 5L3 10H9L12 5L9 0Z': FluentChartLegendShape.hexagon,
  // shape.tsx:26.
  'M6.06061 0L0 4.21277L2.30303 11H9.69697L12 4.21277L6.06061 0Z':
      FluentChartLegendShape.pentagon,
  // shape.tsx:27-28.
  'M7.08333 0H2.91667L0 2.91667V7.08333L2.91667 10H7.08333L10 7.08333V2.91667L7.08333 0Z':
      FluentChartLegendShape.octagon,
  // shape.tsx:29.
  'M0 6 H3 M5 6 H8 M10 6 H13': FluentChartLegendShape.dottedLine,
};

/// The [FluentChartStripePainter] group, called from [main].
void mainPart3() {
  const stripe = Color(0xFFD13438);

  group('the out-of-order legend stripe gradient', () {
    test('the phase runs along the 135 degree gradient axis', () {
      expect(
        fluentChartStripePhase(Offset.zero),
        0,
        reason:
            'For a 135deg CSS gradient the line starts at the top-left corner, '
            'so the origin is phase 0.',
      );
      expect(
        fluentChartStripePhase(const Offset(5, 0)),
        moreOrLessEquals(3.5355, epsilon: 0.001),
        reason:
            'The unit vector of a 135deg gradient is (sin135, -cos135) = '
            '(0.7071, 0.7071) in screen coordinates, so the phase at (5, 0) is '
            '5 * 0.7071 = 3.5355.',
      );
      expect(
        fluentChartStripePhase(const Offset(0, 5)),
        moreOrLessEquals(3.5355, epsilon: 0.001),
        reason: 'The axis is symmetric in x and y at 135 degrees.',
      );
    });

    test('CSS clamping puts the colour band at 3..4, not 1..4', () {
      expect(
        kStripeColourStart,
        3,
        reason:
            'Legends.tsx:300 writes `transparent 3px, COLOR 1px, COLOR 4px`. '
            'CSS clamps every stop to at least its predecessor, so the 1px '
            'stop becomes 3px and the colour begins at 3, not 1.',
      );
      expect(
        kStripePeriod,
        4,
        reason:
            'The last stop of the repeating gradient is 4px, which is the '
            'repeat period (Legends.tsx:300).',
      );
    });

    test('paints the 3..4 band and leaves 0..3 clear', () async {
      final data = await renderStripe(
        const FluentChartStripePainter(color: stripe),
      );

      expect(
        argbAt(data, 5, 0),
        stripe.toARGB32(),
        reason:
            'Phase at (5, 0) is 3.54, inside the clamped 3..4 colour band, so '
            'the pixel takes the legend colour.',
      );
      expect(
        argbAt(data, 2, 0),
        0x00000000,
        reason:
            'Phase at (2, 0) is 1.41, inside the transparent 0..3 band. A '
            'naive port of the literal stops would have coloured it, because '
            'the source says the colour starts at 1px.',
      );
      expect(
        argbAt(data, 6, 0),
        0x00000000,
        reason:
            'Phase at (6, 0) is 4.24, which is 0.24 into the next period and '
            'therefore transparent again — the period is 4, not 5.',
      );
    });
  });
}

/// Renders [painter] into a [kLegendShapeViewportSize] square and returns the
/// raw RGBA bytes, so [argbAt] can read a single device pixel back.
Future<ByteData> renderStripe(FluentChartStripePainter painter) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const size = Size(kLegendShapeViewportSize, kLegendShapeViewportSize);
  painter.paint(canvas, size);
  final image = await recorder.endRecording().toImage(
    kLegendShapeViewportSize.toInt(),
    kLegendShapeViewportSize.toInt(),
  );
  final data = await image.toByteData();
  image.dispose();
  return data!;
}
