import 'dart:math' as math;

import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:fluent_2_web/src/charts/polar_chart_scales.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/oracle_fixture.dart';

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

  group('createPolarRadialScale', () {
    test('a category axis uses a band scale with paddingInner 1', () {
      final radial = createPolarRadialScale(
        FluentPolarScaleKind.category,
        <Object>['a', 'b', 'c'],
        <double>[0, 100],
      );
      expect(
        radial.radiusOf('a'),
        closeTo(0, 1e-9),
        reason:
            'PolarChart.utils.ts:51-54 — paddingInner 1 with paddingOuter 0 gives '
            'step = (outer - inner) / (n - 1), so category 0 sits on the inner ring',
      );
      expect(
        radial.radiusOf('b'),
        closeTo(50, 1e-9),
        reason: 'category 1 sits one step out',
      );
      expect(
        radial.radiusOf('c'),
        closeTo(100, 1e-9),
        reason: 'the last category lands exactly on the outer radius',
      );
      expect(
        radial.scale.bandwidth,
        closeTo(0, 1e-9),
        reason: 'paddingInner 1 leaves no band width at all',
      );
      expect(
        radial.tickLabels,
        <String>['a', 'b', 'c'],
        reason: 'PolarChart.utils.ts:55-61 falls back to the domain values',
      );
    });

    test('explicit tickValues plus tickText relabel a category axis', () {
      final radial = createPolarRadialScale(
        FluentPolarScaleKind.category,
        <Object>['a', 'b'],
        <double>[0, 100],
        tickValues: <Object>['a', 'b'],
        tickText: <String>['One', 'Two'],
      );
      expect(
        radial.tickLabels,
        <String>['One', 'Two'],
        reason: 'PolarChart.utils.ts:57-59 requires BOTH arrays to be present',
      );
    });

    test('tickText alone is ignored without tickValues', () {
      final radial = createPolarRadialScale(
        FluentPolarScaleKind.category,
        <Object>['a', 'b'],
        <double>[0, 100],
        tickText: <String>['One', 'Two'],
      );
      expect(
        radial.tickLabels,
        <String>['a', 'b'],
        reason: 'the guard at :57 tests Array.isArray(opts.tickValues) first',
      );
    });

    test('a linear axis is niced and defaults to four ticks', () {
      final radial = createPolarRadialScale(
        FluentPolarScaleKind.linear,
        <Object>[0, 93],
        <double>[0, 100],
      );
      expect(
        radial.scale.domain,
        <Object>[0, 100],
        reason: 'PolarChart.utils.ts:74 calls nice() before tick generation',
      );
      expect(
        radial.tickValues,
        <Object>[0, 20, 40, 60, 80, 100],
        reason:
            'tickCount defaults to 4 (PolarChart.utils.ts:76); d3 tickIncrement(0, '
            '100, 4) has a raw step of 25, whose error 2.5 sits between e2 = sqrt(2) '
            'and e5 = sqrt(10), so the factor is 2 and the step 20 — six ticks, not '
            'the five a naive 100 / 4 would give (`d3-array/src/ticks.js:9`)',
      );
      expect(
        radial.tickLabels.first,
        '0',
        reason: 'formatToLocaleString renders the first tick without grouping',
      );
    });

    test('a d3 format string overrides the locale formatter', () {
      final radial = createPolarRadialScale(
        FluentPolarScaleKind.linear,
        <Object>[0, 1],
        <double>[0, 100],
        tickFormat: '.2f',
      );
      expect(
        radial.tickLabels.first,
        '0.00',
        reason:
            'PolarChart.utils.ts:116-118 applies d3Format when a string is given',
      );
    });

    test('a log axis blanks the ticks d3 would blank', () {
      final radial = createPolarRadialScale(
        FluentPolarScaleKind.log,
        <Object>[1, 1000],
        <double>[0, 100],
      );
      expect(
        radial.tickLabels.where((l) => l.isEmpty),
        isNotEmpty,
        reason:
            "PolarChart.utils.ts:120 returns an empty string whenever the scale's "
            'own tickFormat blanks the value, which is how log sub-ticks are hidden',
      );
      expect(
        radial.tickLabels.contains('10'),
        isTrue,
        reason: 'decade boundaries always keep their label',
      );
    });

    test('tickStep replaces the generated tick values', () {
      final radial = createPolarRadialScale(
        FluentPolarScaleKind.linear,
        <Object>[0, 10],
        <double>[0, 100],
        tickStep: 5,
        tick0: 0,
      );
      expect(
        radial.tickValues,
        <Object>[0, 5, 10],
        reason:
            'PolarChart.utils.ts:122-129 routes through generateNumericTicks',
      );
    });

    test('a date axis formats through the multi-level options', () {
      final radial = createPolarRadialScale(
        FluentPolarScaleKind.date,
        <Object>[DateTime.utc(2020), DateTime.utc(2024)],
        <double>[0, 100],
        useUtc: true,
      );
      expect(
        radial.tickValues.every((v) => v is DateTime),
        isTrue,
        reason: 'a date scale ticks in DateTime',
      );
      expect(
        radial.tickLabels.first.isNotEmpty,
        isTrue,
        reason: 'PolarChart.utils.ts:105 always produces a localised string',
      );
    });

    test('a d3 time format string wins when no culture is supplied', () {
      final radial = createPolarRadialScale(
        FluentPolarScaleKind.date,
        <Object>[DateTime.utc(2020), DateTime.utc(2021)],
        <double>[0, 100],
        useUtc: true,
        tickFormat: '%Y',
      );
      expect(
        radial.tickLabels.first,
        '2020',
        reason:
            'PolarChart.utils.ts:98-104 uses d3UtcFormat when culture is invalid',
      );
    });

    test('the default radial tick count is four', () {
      expect(kPolarRadialTickCount, 4, reason: 'PolarChart.utils.ts:76');
    });
  });

  group('createPolarAngularScale', () {
    test('a numeric axis ticks every 45 degrees by default', () {
      final angular = createPolarAngularScale(
        FluentPolarScaleKind.linear,
        <Object>[0, 360],
      );
      expect(
        angular.tickValues,
        <Object>[0, 45, 90, 135, 180, 225, 270, 315],
        reason:
            'PolarChart.utils.ts:239 — d3Range(0, 360, 360 / (tickCount ?? 8))',
      );
      expect(
        angular.tickLabels.first,
        '0°',
        reason: 'formatAngle in degrees (PolarChart.utils.ts:231)',
      );
    });

    test('the numeric scale ignores its domain and maps raw degrees', () {
      final angular = createPolarAngularScale(
        FluentPolarScaleKind.linear,
        <Object>[10, 20],
      );
      expect(
        angular.radiansOf(0),
        closeTo(math.pi / 2, 1e-12),
        reason:
            'PolarChart.utils.ts:242 feeds the raw value straight into '
            'normalizeAngle; the domain is only used to pick the scale kind',
      );
      expect(
        angular.radiansOf(90),
        closeTo(0, 1e-12),
        reason: '450 - 90 = 360 folds to 0 radians',
      );
    });

    test('clockwise keeps the datum degrees', () {
      final angular = createPolarAngularScale(
        FluentPolarScaleKind.linear,
        <Object>[0, 360],
        direction: FluentPolarDirection.clockwise,
      );
      expect(
        angular.radiansOf(90),
        closeTo(math.pi / 2, 1e-12),
        reason: 'PolarChart.utils.ts:186 passes clockwise degrees through',
      );
    });

    test('a category axis spreads the domain over a full turn', () {
      final angular = createPolarAngularScale(
        FluentPolarScaleKind.category,
        <Object>['n', 'e', 's', 'w'],
      );
      expect(
        angular.radiansOf('n'),
        closeTo(math.pi / 2, 1e-12),
        reason:
            'PolarChart.utils.ts:208-217 — period is 360 / 4 and index 0 is at '
            'datum 0 degrees, which counter-clockwise puts at 90',
      );
      expect(
        angular.radiansOf('e'),
        closeTo(0, 1e-12),
        reason: 'index 1 sits at datum 90, which folds to 0',
      );
      expect(
        angular.tickLabels,
        <String>['n', 'e', 's', 'w'],
        reason: 'a category axis labels with the domain values',
      );
    });

    test('radians relabel the same tick values', () {
      final angular = createPolarAngularScale(
        FluentPolarScaleKind.linear,
        <Object>[0, 360],
        tickCount: 4,
        unit: FluentPolarAngularUnit.radians,
      );
      expect(
        angular.tickValues,
        <Object>[0, 90, 180, 270],
        reason: 'tick values stay in degrees regardless of the unit',
      );
      expect(
        angular.tickLabels,
        <String>['0π', '0.5π', '1π', '1.5π'],
        reason: 'PolarChart.utils.ts:255 divides by 180 before appending pi',
      );
    });

    test('tickStep in radians is converted back to degrees', () {
      final angular = createPolarAngularScale(
        FluentPolarScaleKind.linear,
        <Object>[0, 360],
        unit: FluentPolarAngularUnit.radians,
        tickStep: math.pi / 2,
        tick0: 0,
      );
      expect(
        angular.tickValues.map((v) => (v as num).round()).toList(),
        <int>[0, 90, 180, 270],
        reason:
            'PolarChart.utils.ts:234-237 generates over [0, 2pi - EPSILON] then '
            'maps each value back through radToDeg',
      );
    });

    test('a d3 format string overrides formatAngle', () {
      final angular = createPolarAngularScale(
        FluentPolarScaleKind.linear,
        <Object>[0, 360],
        tickCount: 2,
        tickFormat: '.1f',
      );
      expect(angular.tickLabels, <String>[
        '0.0',
        '180.0',
      ], reason: 'PolarChart.utils.ts:228-230');
    });

    test('the default angular tick count is eight', () {
      expect(kPolarAngularTickCount, 8, reason: 'PolarChart.utils.ts:239');
    });

    test('the captured spokes sit at the angles a category axis computes', () {
      final story = loadOracleStory('charts-polarchart--polar-chart-basic');
      // The only captured PolarChart story: six subjects on the angular axis,
      // drawn counter-clockwise, which is the upstream default.
      const subjects = <Object>[
        'Math',
        'Chinese',
        'English',
        'Geography',
        'Physics',
        'History',
      ];

      // A spoke is `M0,0 L<x>,<y>` — four numbers, the first pair at the pole.
      // The six of them share one `<g>`, which is what separates them from the
      // radial axis line, drawn identically under a different parent. SVG y
      // grows downward, so a spoke at screen angle theta ends at
      // (r cos theta, -r sin theta); atan2 returns (-pi, pi] and the folding
      // below brings that into the [0, 2pi) the scale produces.
      final byParent = <int, List<double>>{};
      for (final path in story.byTag('path')) {
        final numbers = svgPathNumbers(path.d ?? '');
        if (numbers.length != 4 || numbers[0] != 0 || numbers[1] != 0) {
          continue;
        }
        final theta = math.atan2(-numbers[3], numbers[2]);
        (byParent[path.parent] ??= <double>[]).add(
          (theta % (2 * math.pi) + 2 * math.pi) % (2 * math.pi),
        );
      }
      final spokes = byParent.values
          .where((group) => group.length == subjects.length)
          .toList();
      expect(
        spokes,
        hasLength(1),
        reason:
            'exactly one <g> of the capture holds one spoke per category; a '
            'different count means the selection above matched the wrong nodes',
      );

      final angular = createPolarAngularScale(
        FluentPolarScaleKind.category,
        subjects,
      );
      for (var i = 0; i < subjects.length; i++) {
        expectOracleNumber(
          'spoke ${subjects[i]}',
          spokes.single[i],
          angular.radiansOf(subjects[i]),
          tolerance: kOracleGeometryTolerance,
        );
      }
    });
  });
}
