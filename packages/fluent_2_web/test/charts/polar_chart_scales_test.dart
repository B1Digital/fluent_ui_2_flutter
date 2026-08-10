import 'dart:math' as math;

import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:fluent_2_web/src/charts/polar_chart_scales.dart';
import 'package:flutter_test/flutter_test.dart';

/// `getScaleType` (`PolarChart.utils.ts:136-154`) inspects only `values[0]`, and
/// `getContinuousScaleDomain` (`:156-179`) forces 0 into every linear domain.
void main() {
  test('only the first value decides the scale kind', () {
    expect(
      polarScaleTypeOf(<Object?>[1, 'a', DateTime(2020)]),
      FluentPolarScaleKind.linear,
      reason: 'PolarChart.utils.ts:144 tests typeof values[0] only',
    );
    expect(
      polarScaleTypeOf(<Object?>['a', 1, 2]),
      FluentPolarScaleKind.category,
      reason: 'a leading string makes the whole axis categorical',
    );
    expect(
      polarScaleTypeOf(<Object?>[DateTime(2020), 1]),
      FluentPolarScaleKind.date,
      reason: 'PolarChart.utils.ts:150 tests instanceof Date',
    );
    expect(
      polarScaleTypeOf(<Object?>[]),
      FluentPolarScaleKind.category,
      reason: 'an empty list leaves the default of category',
    );
  });

  test('log only applies when the axis supports it', () {
    expect(
      polarScaleTypeOf(
        <Object?>[1, 10],
        scaleType: FluentAxisScaleType.log,
        supportsLog: true,
      ),
      FluentPolarScaleKind.log,
      reason: 'PolarChart.utils.ts:145 — the radial axis passes supportsLog',
    );
    expect(
      polarScaleTypeOf(<Object?>[1, 10], scaleType: FluentAxisScaleType.log),
      FluentPolarScaleKind.linear,
      reason: 'the angular axis omits supportsLog, so log is ignored',
    );
  });

  test('a linear domain always contains zero', () {
    expect(
      polarContinuousDomain(FluentPolarScaleKind.linear, <Object?>[4, 9]),
      <Object>[0, 9],
      reason: 'PolarChart.utils.ts:165-167 extends the extent with 0',
    );
    expect(
      polarContinuousDomain(FluentPolarScaleKind.linear, <Object?>[-4, -1]),
      <Object>[-4, 0],
      reason: 'the same rule applies below the axis',
    );
  });

  test('a log domain drops non-positive values and never gains zero', () {
    expect(
      polarContinuousDomain(FluentPolarScaleKind.log, <Object?>[0, 1, 100]),
      <Object>[1, 100],
      reason:
          'isValidDomainValue (utilities.ts:2273) rejects <= 0 on a log scale, '
          'and :165 only forces 0 into a linear domain',
    );
  });

  test('rangeStart and rangeEnd override the computed extent', () {
    expect(
      polarContinuousDomain(
        FluentPolarScaleKind.linear,
        <Object?>[4, 9],
        rangeStart: 2,
        rangeEnd: 20,
      ),
      <Object>[2, 20],
      reason: 'PolarChart.utils.ts:168-173',
    );
  });

  test('an unusable extent collapses to an empty domain', () {
    expect(
      polarContinuousDomain(FluentPolarScaleKind.log, <Object?>[0, -1]),
      isEmpty,
      reason:
          'PolarChart.utils.ts:175-177 returns [] when either end is invalid',
    );
  });

  test('counter-clockwise folds the angle through 450 degrees', () {
    expect(
      normalizePolarAngle(0, FluentPolarDirection.counterclockwise),
      90,
      reason: 'PolarChart.utils.ts:186 — (450 - 0) % 360',
    );
    expect(
      normalizePolarAngle(90, FluentPolarDirection.counterclockwise),
      0,
      reason: '450 - 90 = 360, which folds to 0',
    );
    expect(
      normalizePolarAngle(180, FluentPolarDirection.counterclockwise),
      270,
      reason: '450 - 180 = 270',
    );
    expect(
      normalizePolarAngle(90, FluentPolarDirection.clockwise),
      90,
      reason: 'clockwise passes the datum degrees through unchanged',
    );
    expect(
      normalizePolarAngle(-90, FluentPolarDirection.clockwise),
      270,
      reason: 'the double modulo keeps the result in [0, 360)',
    );
  });

  test('degree and radian labels round to six decimal places', () {
    expect(
      formatPolarAngle(45, FluentPolarAngularUnit.degrees),
      '45°',
      reason: 'PolarChart.utils.ts:256',
    );
    expect(
      formatPolarAngle(90, FluentPolarAngularUnit.radians),
      '0.5π',
      reason: 'PolarChart.utils.ts:255 divides by 180 and appends pi',
    );
    expect(
      formatPolarAngle(1 / 3, FluentPolarAngularUnit.degrees),
      '0.333333°',
      reason: 'precisionRound(v, 6) (utilities.ts:2555-2558)',
    );
    expect(
      formatPolarAngle('North', FluentPolarAngularUnit.degrees),
      'North',
      reason: 'PolarChart.utils.ts:252 passes a string through untouched',
    );
  });

  test('degrees and radians round-trip', () {
    expect(
      polarDegreesToRadians(180),
      closeTo(math.pi, 1e-12),
      reason: 'PolarChart.utils.ts:181',
    );
    expect(
      polarRadiansToDegrees(math.pi),
      closeTo(180, 1e-12),
      reason: 'PolarChart.utils.ts:183',
    );
  });

  test('the epsilon is the one the tick anchors compare against', () {
    expect(kPolarEpsilon, 1e-6, reason: 'PolarChart.utils.ts:28');
  });
}
