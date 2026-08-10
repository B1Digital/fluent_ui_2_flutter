import 'dart:math' as math;

import 'package:fluent_2_web/src/charts/internal/d3/curves.dart';
import 'package:fluent_2_web/src/charts/internal/scatter_polar.dart';
import 'package:flutter_test/flutter_test.dart';

/// `LineChart.tsx:1318` gates the fill on `data.length >= 3`, and
/// `scatterpolar-utils.tsx:38-63` places one label per equal angular slot,
/// dropping any that lands within 40px of one already placed.
void main() {
  test('fewer than three points paint no fill at all', () {
    expect(
      scatterPolarFillPath(
        points: const <Offset>[Offset(0, 0), Offset(10, 10)],
        curve: curveLinear,
      ),
      isNull,
      reason: 'LineChart.tsx:1318 requires _points[i].data.length >= 3',
    );
  });

  test('three points close the path with Z', () {
    final path = scatterPolarFillPath(
      points: const <Offset>[Offset(0, 0), Offset(10, 0), Offset(10, 10)],
      curve: curveLinear,
    );
    expect(path, isNotNull, reason: 'three points clear the >= 3 gate');
    expect(
      path!.contains(const Offset(8, 2)),
      isTrue,
      reason: 'LineChart.tsx:1334 appends Z, so the interior is filled',
    );
    expect(
      path.contains(const Offset(1, 8)),
      isFalse,
      reason: 'the point sits outside the closed triangle',
    );
  });

  test('non-finite points break the path, honouring defined()', () {
    final path = scatterPolarFillPath(
      points: const <Offset>[
        Offset(0, 0),
        Offset(10, 0),
        Offset(double.nan, 5),
        Offset(10, 10),
        Offset(0, 10),
      ],
      curve: curveLinear,
    );
    expect(
      path!.computeMetrics().length,
      2,
      reason:
          'isPlottable (utilities.ts:2278) makes the NaN undefined, which splits '
          'the line into two sub-paths',
    );
  });

  test('constant fill paint values come from LineChart.tsx:1336-1339', () {
    expect(kScatterPolarFillOpacity, 0.5, reason: 'LineChart.tsx:1336');
    expect(kScatterPolarFillStrokeWidth, 2, reason: 'LineChart.tsx:1338');
    expect(kScatterPolarFillStrokeOpacity, 0.8, reason: 'LineChart.tsx:1339');
  });

  test('labels sit at equal angles counter-clockwise by default', () {
    double identity(double v) => v * 100;
    final labels = scatterPolarCategoryLabels(
      labels: const <String>['a', 'b', 'c', 'd'],
      xScale: identity,
      yScale: identity,
      minPixelGap: 0,
    );
    expect(labels.length, 4, reason: 'no gap filtering at minPixelGap 0');
    expect(
      labels[0].position.dx,
      closeTo(70, 1e-9),
      reason: 'scatterpolar-utils.tsx:41 — cos(0) * 0.7 scaled by 100',
    );
    expect(
      labels[1].position.dy,
      closeTo(70, 1e-9),
      reason: 'counter-clockwise multiplier +1 puts index 1 at pi/2',
    );
  });

  test('clockwise flips the angular sweep', () {
    double identity(double v) => v * 100;
    final labels = scatterPolarCategoryLabels(
      labels: const <String>['a', 'b', 'c', 'd'],
      xScale: identity,
      yScale: identity,
      direction: 'clockwise',
      minPixelGap: 0,
    );
    expect(
      labels[1].position.dy,
      closeTo(-70, 1e-9),
      reason: 'scatterpolar-utils.tsx:35 sets dirMultiplier to -1',
    );
  });

  test('rotation and originXOffset shift the ring', () {
    double identity(double v) => v * 100;
    final labels = scatterPolarCategoryLabels(
      labels: const <String>['a', 'b'],
      xScale: identity,
      yScale: identity,
      rotationDegrees: 90,
      originXOffset: 1,
      minPixelGap: 0,
    );
    expect(
      labels[0].position.dx,
      closeTo(0.7 * math.cos(math.pi / 2) * 100 - 50, 1e-9),
      reason: 'scatterpolar-utils.tsx:41 subtracts originXOffset / 2',
    );
  });

  test('labels closer than the gap are dropped, the first always kept', () {
    double squash(double v) => v;
    final labels = scatterPolarCategoryLabels(
      labels: const <String>['a', 'b', 'c'],
      xScale: squash,
      yScale: squash,
      minPixelGap: 40,
    );
    expect(
      labels.length,
      1,
      reason:
          'scatterpolar-utils.tsx:47 keeps a label only when the list is empty '
          'or it clears every placed position by minPixelGap',
    );
  });
}
