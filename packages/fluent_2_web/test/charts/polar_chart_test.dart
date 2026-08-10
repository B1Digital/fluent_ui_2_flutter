import 'dart:math' as math;

import 'package:fluent_2_web/fluent_2_web.dart';
// `polar_chart.dart` is not barrel-exported yet — the integration task owns
// `lib/fluent_2_web.dart`, so the test reaches for the library directly, exactly
// as `polar_chart_scales_test.dart` does for the scales.
import 'package:fluent_2_web/src/charts/polar_chart.dart';
import 'package:fluent_2_web/src/charts/polar_chart_scales.dart';
import 'package:fluent_2_web/src/charts/polar_chart_style.dart';
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

  group('grid geometry', () {
    test('a numeric axis whose domain end is already a tick adds nothing', () {
      final layout = FluentPolarLayout.compute(
        size: const Size(400, 400),
        data: <FluentPolarSeries>[
          const FluentScatterPolarSeries(
            legend: 'A',
            data: <FluentPolarDataPoint>[
              FluentPolarDataPoint(r: 0, theta: 0),
              FluentPolarDataPoint(r: 100, theta: 90),
            ],
          ),
        ],
        margins: const FluentChartMargins(),
        hole: 0,
        direction: FluentPolarDirection.counterclockwise,
      );
      expect(
        layout.gridRingValues(),
        layout.radial.tickValues,
        reason:
            'PolarChart.tsx:280-286 — with innerRadius 0 and a niced domain whose '
            'ends coincide with the first and last tick, nothing is appended',
      );
    });

    test('a hole adds the domain start as an extra inner ring', () {
      final layout = FluentPolarLayout.compute(
        size: const Size(400, 400),
        data: <FluentPolarSeries>[
          const FluentScatterPolarSeries(
            legend: 'A',
            data: <FluentPolarDataPoint>[
              FluentPolarDataPoint(r: 3, theta: 0),
              FluentPolarDataPoint(r: 97, theta: 90),
            ],
          ),
        ],
        margins: const FluentChartMargins(),
        hole: 0.4,
        direction: FluentPolarDirection.counterclockwise,
      );
      expect(
        layout.gridRingValues().length,
        greaterThanOrEqualTo(layout.radial.tickValues.length),
        reason: 'PolarChart.tsx:280-282 pushes rDomain[0] when innerRadius > 0',
      );
      // A niced numeric domain starts exactly on its first tick, so the branch
      // above never fires for one. A date domain is compared by reference, so
      // it always does, and the hole is then the only thing that can add the
      // ring.
      FluentPolarLayout dated({required double hole}) =>
          FluentPolarLayout.compute(
            size: const Size(400, 400),
            data: <FluentPolarSeries>[
              FluentScatterPolarSeries(
                legend: 'A',
                data: <FluentPolarDataPoint>[
                  FluentPolarDataPoint(r: DateTime.utc(2020), theta: 0),
                  FluentPolarDataPoint(r: DateTime.utc(2024), theta: 90),
                ],
              ),
            ],
            margins: const FluentChartMargins(),
            hole: hole,
            direction: FluentPolarDirection.counterclockwise,
            useUtc: true,
          );
      expect(
        dated(hole: 0.4).gridRingValues().length,
        dated(hole: 0).gridRingValues().length + 1,
        reason:
            'PolarChart.tsx:280 gates the leading ring on innerRadius > 0, so '
            'the same axis gains exactly one ring once it has a hole',
      );
    });

    test('a date axis always appends the domain end', () {
      final layout = FluentPolarLayout.compute(
        size: const Size(400, 400),
        data: <FluentPolarSeries>[
          FluentScatterPolarSeries(
            legend: 'A',
            data: <FluentPolarDataPoint>[
              FluentPolarDataPoint(r: DateTime.utc(2020), theta: 0),
              FluentPolarDataPoint(r: DateTime.utc(2024), theta: 90),
            ],
          ),
        ],
        margins: const FluentChartMargins(),
        hole: 0,
        direction: FluentPolarDirection.counterclockwise,
        useUtc: true,
      );
      expect(
        layout.gridRingValues().length,
        layout.radial.tickValues.length + 1,
        reason:
            'PolarChart.tsx:284 compares with !==, which is reference identity for '
            'a Date, so a date axis always gains one extra outer ring',
      );
    });

    test('a circle ring is a full turn at the scaled radius', () {
      final layout = FluentPolarLayout.compute(
        size: const Size(400, 400),
        data: <FluentPolarSeries>[
          const FluentScatterPolarSeries(
            legend: 'A',
            data: <FluentPolarDataPoint>[
              FluentPolarDataPoint(r: 0, theta: 0),
              FluentPolarDataPoint(r: 100, theta: 90),
            ],
          ),
        ],
        margins: const FluentChartMargins(),
        hole: 0,
        direction: FluentPolarDirection.counterclockwise,
      );
      final path = layout.ringPath(50, FluentPolarShape.circle);
      expect(
        path.getBounds(),
        const Rect.fromLTRB(-50, -50, 50, 50),
        reason: 'PolarChart.tsx:307 centres the circle on the origin',
      );
    });

    test('a polygon ring has one vertex per angular tick', () {
      final layout = FluentPolarLayout.compute(
        size: const Size(400, 400),
        data: <FluentPolarSeries>[
          const FluentScatterPolarSeries(
            legend: 'A',
            data: <FluentPolarDataPoint>[
              FluentPolarDataPoint(r: 0, theta: 0),
              FluentPolarDataPoint(r: 100, theta: 90),
            ],
          ),
        ],
        margins: const FluentChartMargins(),
        hole: 0,
        direction: FluentPolarDirection.counterclockwise,
      );
      final path = layout.ringPath(50, FluentPolarShape.polygon);
      expect(
        path.computeMetrics().first.isClosed,
        isTrue,
        reason: 'PolarChart.tsx:301 appends Z',
      );
      expect(
        path.contains(const Offset(0, 0)),
        isTrue,
        reason: 'the octagon encloses the origin',
      );
      expect(
        path.contains(const Offset(49.9, 0)),
        isTrue,
        reason:
            'the tick at datum 0 normalises to 90 degrees, which pointRadial '
            'puts at three o\'clock, so the ray to that vertex stays inside all '
            'the way out to the radius',
      );
      // Halfway between the ticks at datum 0 and datum 45 the ring is a straight
      // chord, whose distance from the centre is 50 * cos(pi / 8) = 46.194.
      const bisector = math.pi / 8;
      expect(
        path.contains(
          Offset(49.9 * math.cos(bisector), 49.9 * math.sin(bisector)),
        ),
        isFalse,
        reason:
            'with eight vertices the flat between two ticks cuts the corner, so a '
            'point at the full radius is outside',
      );
    });

    test('spokes run from the hole to the outer ring at every angular tick', () {
      final layout = FluentPolarLayout.compute(
        size: const Size(400, 400),
        data: <FluentPolarSeries>[
          const FluentScatterPolarSeries(
            legend: 'A',
            data: <FluentPolarDataPoint>[
              FluentPolarDataPoint(r: 0, theta: 0),
              FluentPolarDataPoint(r: 100, theta: 90),
            ],
          ),
        ],
        margins: const FluentChartMargins(),
        hole: 0,
        direction: FluentPolarDirection.counterclockwise,
      );
      final spokes = layout.spokes();
      expect(
        spokes.length,
        8,
        reason: 'the default angular tick count is 8 (PolarChart.utils.ts:239)',
      );
      expect(
        spokes.first.$1,
        const Offset(0, 0),
        reason: 'PolarChart.tsx:312 starts every spoke at the inner radius',
      );
      expect(
        spokes.first.$2.dx,
        closeTo(layout.outerRadius, 1e-9),
        reason:
            'datum 0 counter-clockwise maps to 90 degrees, which pointRadial puts '
            'at three o\'clock',
      );
    });
  });

  group('series paths', () {
    FluentPolarLayout ringLayout(
      List<FluentPolarSeries> data, {
      double hole = 0,
    }) => FluentPolarLayout.compute(
      size: const Size(400, 400),
      data: data,
      margins: const FluentChartMargins(),
      hole: hole,
      direction: FluentPolarDirection.counterclockwise,
    );

    const square = <FluentPolarDataPoint>[
      FluentPolarDataPoint(r: 100, theta: 0),
      FluentPolarDataPoint(r: 100, theta: 90),
      FluentPolarDataPoint(r: 100, theta: 180),
      FluentPolarDataPoint(r: 100, theta: 270),
    ];

    test('an area with no curve set closes both rings', () {
      final layout = ringLayout(<FluentPolarSeries>[
        const FluentAreaPolarSeries(legend: 'A', data: square),
      ], hole: 0.5);
      final metrics = layout.areaPath(layout.series.first).computeMetrics();
      expect(
        metrics.map((m) => m.isClosed).toList(),
        <bool>[true, true],
        reason:
            'PolarChart.tsx:448 falls back to d3CurveLinearClosed, whose lineEnd '
            'closes on BOTH passes (d3-shape/src/curve/linearClosed.js:14), so '
            'the outer ring and the reversed inner ring are two closed contours',
      );
    });

    test('curve linear joins the two rings into a single contour', () {
      final layout = ringLayout(<FluentPolarSeries>[
        const FluentAreaPolarSeries(
          legend: 'A',
          data: square,
          lineOptions: FluentLineOptions(curve: FluentLineCurve.linear),
        ),
      ], hole: 0.5);
      expect(
        layout.areaPath(layout.series.first).computeMetrics().length,
        1,
        reason:
            'getCurveFactory (utilities.ts:2017) maps the explicit "linear" to '
            'the OPEN curveLinear, whose lineEnd closes only on the baseline '
            'pass (d3-shape/src/curve/linear.js:16), so the outer edge runs '
            'straight into the reversed inner edge as one sub-path — one '
            'contour where the omitted-curve fallback makes two',
      );
    });

    test('a gap breaks the area on the reverse baseline replay too', () {
      final layout = ringLayout(<FluentPolarSeries>[
        const FluentAreaPolarSeries(
          legend: 'A',
          data: <FluentPolarDataPoint>[
            FluentPolarDataPoint(r: 100, theta: 0),
            FluentPolarDataPoint(r: 100, theta: 45),
            FluentPolarDataPoint(r: double.nan, theta: 90),
            FluentPolarDataPoint(r: 100, theta: 180),
            FluentPolarDataPoint(r: 100, theta: 225),
          ],
        ),
      ], hole: 0.5);
      expect(
        layout.areaPath(layout.series.first).computeMetrics().length,
        4,
        reason:
            'PolarChart.tsx:450 sets .defined(isPlottable) on the areaRadial, and '
            'd3-shape/src/area.js:39-47 replays the baseline of each defined run '
            'in reverse, so two runs times two closed rings is four contours',
      );
    });

    test('the area inner edge follows the hole radius, not the data', () {
      final layout = ringLayout(<FluentPolarSeries>[
        const FluentAreaPolarSeries(legend: 'A', data: square),
      ], hole: 0.5);
      final bounds = layout.areaPath(layout.series.first).getBounds();
      expect(
        bounds.width,
        closeTo(2 * layout.outerRadius, 1e-6),
        reason:
            'PolarChart.tsx:445 pins innerRadius to the constant hole radius, so '
            'the outer ring still reaches the full radius',
      );
    });

    test('a non-plottable point splits the line into two sub-paths', () {
      final layout = ringLayout(<FluentPolarSeries>[
        const FluentLinePolarSeries(
          legend: 'L',
          data: <FluentPolarDataPoint>[
            FluentPolarDataPoint(r: 100, theta: 0),
            FluentPolarDataPoint(r: 100, theta: 90),
            FluentPolarDataPoint(r: double.nan, theta: 180),
            FluentPolarDataPoint(r: 100, theta: 225),
            FluentPolarDataPoint(r: 100, theta: 270),
          ],
        ),
      ]);
      expect(
        layout.linePath(layout.series.first).computeMetrics().length,
        2,
        reason:
            'PolarChart.tsx:473 sets .defined(isPlottable), which is live and must '
            'break the path rather than draw through the gap',
      );
    });

    test('an empty series yields an empty path rather than throwing', () {
      final layout = ringLayout(<FluentPolarSeries>[
        const FluentLinePolarSeries(
          legend: 'L',
          data: <FluentPolarDataPoint>[],
        ),
      ]);
      expect(
        layout.linePath(layout.series.first).computeMetrics().isEmpty,
        isTrue,
        reason: 'd3 emits null for an empty dataset; the port emits nothing',
      );
    });
  });

  group('FluentPolarSeriesPainter forced colours', () {
    // Two differently coloured series, one of each drawn kind, so a flattening
    // that only fires on one of them still shows up.
    const data = <FluentPolarSeries>[
      FluentAreaPolarSeries(
        legend: 'Area',
        color: Color(0xFF4F6BED),
        data: <FluentPolarDataPoint>[
          FluentPolarDataPoint(r: 100, theta: 0),
          FluentPolarDataPoint(r: 100, theta: 120),
          FluentPolarDataPoint(r: 100, theta: 240),
        ],
      ),
      FluentLinePolarSeries(
        legend: 'Line',
        color: Color(0xFFE3008C),
        data: <FluentPolarDataPoint>[
          FluentPolarDataPoint(r: 50, theta: 0),
          FluentPolarDataPoint(r: 80, theta: 120),
        ],
      ),
    ];

    _Recording paint(FluentThemeData theme) {
      final canvas = _Recording();
      FluentPolarSeriesPainter(
        layout: FluentPolarLayout.compute(
          size: const Size(400, 400),
          data: data,
          margins: const FluentChartMargins(),
          hole: 0,
          direction: FluentPolarDirection.counterclockwise,
        ),
        activeLegends: const <String>{},
        activePointId: '',
        style: resolveFluentPolarChartStyle(theme),
        states: const <WidgetState>{},
        colors: FluentChartColors.of(theme),
      ).paint(canvas, const Size(400, 400));
      return canvas;
    }

    test('the palette survives outside forced colours', () {
      final recorded = paint(
        FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      );
      expect(
        recorded.paths.map((c) => c.withValues(alpha: 1).toARGB32()).toList(),
        <int>[0xFF4F6BED, 0xFF4F6BED, 0xFFE3008C],
        reason:
            'PolarChart.tsx:456 and :479 paint the series colour untouched, so '
            'the area fill, its outline and the line all keep it',
      );
      expect(
        recorded.circles.every(
          (c) =>
              c.withValues(alpha: 1).toARGB32() == 0xFF4F6BED ||
              c.withValues(alpha: 1).toARGB32() == 0xFFE3008C,
        ),
        isTrue,
        reason: 'PolarChart.tsx:563 fills an inactive marker with point.color',
      );
    });

    test('every mark flattens under forced colours', () {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      final recorded = paint(theme);
      expect(
        recorded.paths.map((c) => c.withValues(alpha: 1).toARGB32()).toList(),
        <int>[
          theme.colors.neutralForeground1.toARGB32(),
          theme.colors.neutralBackground1.toARGB32(),
          theme.colors.neutralForeground1.toARGB32(),
        ],
        reason:
            'Spec 5.3 — the area fill and the standalone line flatten through '
            'flattenMark, while the area OUTLINE takes flattenMarkStroke so it '
            'stays visible against its own flattened fill',
      );
      expect(
        recorded.circles.map((c) => c.withValues(alpha: 1).toARGB32()).toSet(),
        <int>{theme.colors.neutralForeground1.toARGB32()},
        reason:
            'Spec 5.3 — every marker fill flattens to the one system colour, '
            'whatever palette slot its series drew',
      );
    });
  });
}

/// Records the colour of every mark the polar series painter draws.
///
/// [noSuchMethod] absorbs the rest of [Canvas]; the painter calls nothing else
/// these tests read.
class _Recording implements Canvas {
  /// The colour of every `drawPath`, in paint order.
  final List<Color> paths = <Color>[];

  /// The colour of every `drawCircle`, in paint order.
  final List<Color> circles = <Color>[];

  @override
  void drawPath(Path path, Paint paint) => paths.add(paint.color);

  @override
  void drawCircle(Offset c, double radius, Paint paint) =>
      circles.add(paint.color);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
