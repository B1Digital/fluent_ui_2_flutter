import 'package:fluent_2_web/fluent_2_web.dart';
// `polar_chart.dart` is not barrel-exported yet — the integration task owns
// `lib/fluent_2_web.dart`, so the test reaches for the library directly, exactly
// as `polar_chart_scales_test.dart` does for the scales.
import 'package:fluent_2_web/src/charts/polar_chart.dart';
import 'package:fluent_2_web/src/charts/polar_chart_scales.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// `PolarChart.tsx:90-142` resolves sizing, colours and rendering order before any
/// painting happens, and every one of those steps is order-sensitive.
void main() {
  FluentPolarLayout layoutOf({
    Size size = const Size(400, 400),
    List<FluentPolarSeries>? data,
    FluentChartMargins margins = const FluentChartMargins(),
    double hole = 0,
    FluentPolarDirection direction = FluentPolarDirection.counterclockwise,
  }) => FluentPolarLayout.compute(
    size: size,
    data:
        data ??
        <FluentPolarSeries>[
          const FluentScatterPolarSeries(
            legend: 'A',
            data: <FluentPolarDataPoint>[
              FluentPolarDataPoint(r: 1, theta: 0),
              FluentPolarDataPoint(r: 2, theta: 90),
            ],
          ),
        ],
    margins: margins,
    hole: hole,
    direction: direction,
  );

  test('the default margins are the label box plus its offset', () {
    expect(
      kPolarDefaultMargins.left,
      46,
      reason: 'PolarChart.tsx:92 — LABEL_OFFSET 10 + LABEL_WIDTH 36',
    );
    expect(kPolarDefaultMargins.right, 46, reason: 'PolarChart.tsx:93');
    expect(
      kPolarDefaultMargins.top,
      26,
      reason: 'PolarChart.tsx:94 — LABEL_OFFSET 10 + LABEL_HEIGHT 16',
    );
    expect(kPolarDefaultMargins.bottom, 26, reason: 'PolarChart.tsx:95');
  });

  test('the outer radius is the smaller free half-axis', () {
    final layout = layoutOf(size: const Size(400, 300));
    expect(
      layout.outerRadius,
      closeTo(124, 1e-9),
      reason:
          'PolarChart.tsx:107 — min(400 - 92, 300 - 52) / 2 = min(308, 248) / 2',
    );
    expect(
      layout.centre,
      const Offset(200, 150),
      reason: 'PolarChart.tsx:652 translates to the svg centre',
    );
  });

  test('the hole is clamped to the unit interval and taken absolute', () {
    expect(
      layoutOf(hole: 0.5).innerRadius,
      closeTo(layoutOf().outerRadius * 0.5, 1e-9),
      reason: 'PolarChart.tsx:111',
    );
    expect(
      layoutOf(hole: -0.25).innerRadius,
      closeTo(layoutOf().outerRadius * 0.25, 1e-9),
      reason: 'Math.abs is applied before the clamp',
    );
    expect(
      layoutOf(hole: 4).innerRadius,
      closeTo(layoutOf().outerRadius, 1e-9),
      reason: 'Math.min(_, 1) caps the hole at the outer radius',
    );
  });

  test('a user margin overrides one side only', () {
    final layout = layoutOf(
      size: const Size(400, 400),
      margins: const FluentChartMargins(left: 0),
    );
    expect(
      layout.outerRadius,
      closeTo(174, 1e-9),
      reason:
          'PolarChart.tsx:96 spreads props.margins over the defaults, so only '
          'left changes: min(400 - 46, 400 - 52) / 2',
    );
  });

  test('colours are assigned in input order and shared by legend', () {
    final layout = layoutOf(
      data: <FluentPolarSeries>[
        const FluentScatterPolarSeries(
          legend: 'B',
          data: <FluentPolarDataPoint>[FluentPolarDataPoint(r: 1, theta: 0)],
        ),
        const FluentAreaPolarSeries(
          legend: 'A',
          data: <FluentPolarDataPoint>[FluentPolarDataPoint(r: 1, theta: 0)],
        ),
        const FluentLinePolarSeries(
          legend: 'B',
          data: <FluentPolarDataPoint>[FluentPolarDataPoint(r: 1, theta: 0)],
        ),
      ],
    );
    expect(
      layout.legendColors.keys.toList(),
      <String>['B', 'A'],
      reason:
          'PolarChart.tsx:612 reads Object.keys of the legend map, which is '
          'insertion order of first appearance — B was first in the input',
    );
    expect(
      layout.legendColors['B']!.toARGB32(),
      FluentDataVizPalette.next(0).toARGB32(),
      reason: 'PolarChart.tsx:123-125 — first wins, and B took palette index 0',
    );
    expect(
      layout.legendColors['A']!.toARGB32(),
      FluentDataVizPalette.next(1).toARGB32(),
      reason: 'the colour index advances once per auto-coloured series',
    );
  });

  test('an explicit series colour does not advance the palette index', () {
    final layout = layoutOf(
      data: <FluentPolarSeries>[
        const FluentScatterPolarSeries(
          legend: 'X',
          color: Color(0xFF102030),
          data: <FluentPolarDataPoint>[FluentPolarDataPoint(r: 1, theta: 0)],
        ),
        const FluentScatterPolarSeries(
          legend: 'Y',
          data: <FluentPolarDataPoint>[FluentPolarDataPoint(r: 1, theta: 0)],
        ),
      ],
    );
    expect(
      layout.legendColors['Y']!.toARGB32(),
      FluentDataVizPalette.next(0).toARGB32(),
      reason: 'PolarChart.tsx:123 — colorIndex++ only runs in the else branch',
    );
  });

  test('series paint in area, line, scatter order but keep input ties', () {
    final layout = layoutOf(
      data: <FluentPolarSeries>[
        const FluentScatterPolarSeries(
          legend: 'S',
          data: <FluentPolarDataPoint>[FluentPolarDataPoint(r: 1, theta: 0)],
        ),
        const FluentLinePolarSeries(
          legend: 'L',
          data: <FluentPolarDataPoint>[FluentPolarDataPoint(r: 1, theta: 0)],
        ),
        const FluentAreaPolarSeries(
          legend: 'A1',
          data: <FluentPolarDataPoint>[FluentPolarDataPoint(r: 1, theta: 0)],
        ),
        const FluentAreaPolarSeries(
          legend: 'A2',
          data: <FluentPolarDataPoint>[FluentPolarDataPoint(r: 1, theta: 0)],
        ),
      ],
    );
    expect(
      layout.series.map((s) => s.series.legend).toList(),
      <String>['A1', 'A2', 'L', 'S'],
      reason:
          'PolarChart.tsx:139-141 sorts by renderingOrder; the sort is stable so '
          'A1 stays ahead of A2',
    );
  });

  test('markers-only mode raises the minimum marker radius', () {
    final scatterOnly = layoutOf();
    expect(
      scatterOnly.markersOnly,
      isTrue,
      reason: 'PolarChart.tsx:522-525 — no area and no line series',
    );
    expect(
      scatterOnly.markers.first.radius,
      4,
      reason: 'PolarChart.tsx:542 uses MIN_MARKER_SIZE_PX_MARKERS_ONLY',
    );

    final withLine = layoutOf(
      data: <FluentPolarSeries>[
        const FluentLinePolarSeries(
          legend: 'L',
          data: <FluentPolarDataPoint>[
            FluentPolarDataPoint(r: 1, theta: 0),
            FluentPolarDataPoint(r: 2, theta: 90),
          ],
        ),
      ],
    );
    expect(
      withLine.markers.first.radius,
      2,
      reason: 'PolarChart.tsx:542 falls back to MIN_MARKER_SIZE_PX',
    );
  });

  test('marker sizes interpolate between the extent and the ceiling', () {
    final layout = layoutOf(
      data: <FluentPolarSeries>[
        const FluentScatterPolarSeries(
          legend: 'A',
          data: <FluentPolarDataPoint>[
            FluentPolarDataPoint(r: 1, theta: 0, markerSize: 0),
            FluentPolarDataPoint(r: 2, theta: 90, markerSize: 10),
          ],
        ),
      ],
    );
    expect(
      layout.markers[0].radius,
      closeTo(4, 1e-9),
      reason: 'PolarChart.tsx:545-548 — the minimum marker keeps minPx',
    );
    expect(
      layout.markers[1].radius,
      closeTo(16, 1e-9),
      reason: 'the maximum marker reaches MAX_MARKER_SIZE_PX',
    );
  });

  test('an unplottable point produces no marker at all', () {
    final layout = layoutOf(
      data: <FluentPolarSeries>[
        const FluentScatterPolarSeries(
          legend: 'A',
          data: <FluentPolarDataPoint>[
            FluentPolarDataPoint(r: 1, theta: 0),
            FluentPolarDataPoint(r: double.nan, theta: 90),
          ],
        ),
      ],
    );
    expect(
      layout.markers.length,
      1,
      reason: 'PolarChart.tsx:534-536 returns null for a non-plottable point',
    );
  });

  test('marker ids and aria strings follow the upstream shape', () {
    final layout = layoutOf();
    expect(
      layout.markers.first.id,
      '0-0',
      reason: r'PolarChart.tsx:540 — `${seriesIndex}-${pointIndex}`',
    );
    expect(
      layout.markers.first.semanticLabel,
      '1. A, 0°.',
      reason:
          'PolarChart.tsx:551-555 announces the RADIUS first even though the '
          'popover shows the angle on top',
    );
    expect(
      layout.markers.first.popoverXValue,
      '0°',
      reason: 'PolarChart.tsx:506 puts the angle in XValue',
    );
    expect(
      layout.markers.first.popoverYValue,
      '1',
      reason: 'PolarChart.tsx:509-511 puts the radius in YValue',
    );
  });

  test('the radial axis angle and tick sign follow the direction', () {
    final ccw = layoutOf();
    expect(
      ccw.radialAxisAngle,
      closeTo(1.5707963267948966, 1e-12),
      reason: 'PolarChart.tsx:339 — pi/2 when not clockwise',
    );
    expect(
      ccw.tickSign,
      1,
      reason: 'PolarChart.tsx:343 — pi/2 satisfies both epsilon comparisons',
    );

    final cw = layoutOf(direction: FluentPolarDirection.clockwise);
    expect(cw.radialAxisAngle, 0, reason: 'PolarChart.tsx:339');
    expect(
      cw.tickSign,
      -1,
      reason: 'zero fails the first comparison, so the sign flips',
    );
  });
}
