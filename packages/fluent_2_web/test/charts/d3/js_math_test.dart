import 'dart:math' as math;

import 'package:fluent_2_web/src/charts/internal/d3/js_math.dart' as d3;
import 'package:flutter_test/flutter_test.dart';

import 'golden_support.dart';

/// `e10`, `e5` and `e2` from `d3-array/src/ticks.js:1-3`.
final double _e10 = math.sqrt(50);
final double _e5 = math.sqrt(10);
final double _e2 = math.sqrt(2);

/// `Math.pow(10, e)` for the non-finite exponents `tickSpec` can produce:
/// `Math.log10(0)` is `-Infinity` and `Math.log10(-0.1)` is NaN, and JS raises
/// ten to both without complaint. [d3.pow10] takes an `int`, so the probe below
/// widens it here rather than in the library.
double _pow10Probe(double e) {
  if (e.isNaN) {
    return double.nan;
  }
  if (e.isInfinite) {
    return e.isNegative ? 0.0 : double.infinity;
  }
  return d3.pow10(e.toInt());
}

/// A local transcription of `tickSpec` (`d3-array/src/ticks.js:5-27`), present
/// only so that this file can diff [d3.log10] and [d3.pow10] against the
/// committed corpus. It is **not** the port — plan 01 Task 4 owns `ticks.dart`.
/// Both helpers are invisible on their own in the corpus, so the smallest
/// consumer that exposes them is reproduced here instead.
List<double> _tickSpecProbe(double start, double stop, double count) {
  final step = (stop - start) / math.max(0, count);
  final power = d3.log10(step).floorToDouble();
  final error = step / _pow10Probe(power);
  final factor = error >= _e10
      ? 10.0
      : error >= _e5
      ? 5.0
      : error >= _e2
      ? 2.0
      : 1.0;
  double i1;
  double i2;
  double inc;
  if (power < 0) {
    inc = _pow10Probe(-power) / factor;
    i1 = d3.jsRound(start * inc);
    i2 = d3.jsRound(stop * inc);
    if (i1 / inc < start) {
      i1 += 1;
    }
    if (i2 / inc > stop) {
      i2 -= 1;
    }
    inc = -inc;
  } else {
    inc = _pow10Probe(power) * factor;
    i1 = d3.jsRound(start / inc);
    i2 = d3.jsRound(stop / inc);
    if (i1 * inc < start) {
      i1 += 1;
    }
    if (i2 * inc > stop) {
      i2 -= 1;
    }
  }
  if (i2 < i1 && 0.5 <= count && count < 2) {
    return _tickSpecProbe(start, stop, count * 2);
  }
  return <double>[i1, i2, inc];
}

void main() {
  group('jsRound — JS rounds halves UP, Dart rounds them away from zero', () {
    test('positive halves agree with Dart', () {
      expect(d3.jsRound(0.5), 1.0, reason: 'Math.round(0.5) === 1');
      expect(d3.jsRound(2.5), 3.0, reason: 'Math.round(2.5) === 3');
    });

    test('negative halves do NOT agree with Dart', () {
      expect(
        (-0.5).round(),
        -1,
        reason: 'this is the Dart behaviour the helper exists to avoid',
      );
      expect(d3.jsRound(-0.5), 0.0, reason: 'Math.round(-0.5) === -0');
      expect(
        d3.jsRound(-0.5).isNegative,
        isTrue,
        reason:
            'Math.round(-0.5) is negative zero, and d3-format reads the '
            'sign of zero at locale.js:77',
      );
      expect(d3.jsRound(-2.5), -2.0, reason: 'Math.round(-2.5) === -2');
      expect(d3.jsRound(-1.5), -1.0, reason: 'Math.round(-1.5) === -1');
    });

    test('non-halves and non-finite values', () {
      expect(d3.jsRound(-0.3), 0.0, reason: 'Math.round(-0.3) === -0');
      expect(d3.jsRound(1.4999999999999998), 1.0, reason: 'below the tie');
      expect(d3.jsRound(double.nan).isNaN, isTrue, reason: 'Math.round(NaN)');
      expect(
        d3.jsRound(double.infinity),
        double.infinity,
        reason: 'Math.round(Infinity) === Infinity, and Dart round() throws',
      );
      expect(
        d3.jsRound(4503599627370497),
        4503599627370497,
        reason: 'above 2^52 every double is integral',
      );
    });
  });

  group('log10 is exact at decade boundaries', () {
    test('the naive formula is not', () {
      expect(
        math.log(1000) / math.ln10,
        isNot(3.0),
        reason:
            'this is the trap: it evaluates to 2.9999999999999996, so '
            'floor() gives 2 and every tick step is off by a decade',
      );
    });

    test('the helper is', () {
      for (var e = -20; e <= 20; e++) {
        expect(
          d3.log10(d3.pow10(e)),
          e.toDouble(),
          reason: 'Math.log10(1e$e) === $e',
        );
      }
    });

    test('non-decade inputs match the naive formula', () {
      expect(d3.log10(2), math.log(2) / math.ln10, reason: 'no snapping');
      expect(d3.log10(0), double.negativeInfinity, reason: 'Math.log10(0)');
      expect(d3.log10(-1).isNaN, isTrue, reason: 'Math.log10(-1) is NaN');
    });
  });

  group('pow10 is decimal-string construction, not math.pow', () {
    test('math.pow with int arguments is a different function entirely', () {
      expect(
        math.pow(10, 23),
        isNot(1e23),
        reason:
            'Dart math.pow(int, int) does exact integer arithmetic and '
            'returns 200376420520689664',
      );
    });

    test('the helper matches +("1e" + x)', () {
      expect(d3.pow10(23), 1e23, reason: 'log.js:24');
      expect(d3.pow10(-7), 1e-7, reason: 'log.js:24');
      expect(d3.pow10(0), 1.0, reason: 'log.js:24');
      expect(d3.pow10(400), double.infinity, reason: '+("1e400") is Infinity');
      expect(d3.pow10(-400), 0.0, reason: '+("1e-400") is 0');
    });
  });

  test('jsSign preserves signed zero and NaN', () {
    expect(d3.jsSign(3), 1.0, reason: 'Math.sign(3)');
    expect(d3.jsSign(-3), -1.0, reason: 'Math.sign(-3)');
    expect(d3.jsSign(0).isNegative, isFalse, reason: 'Math.sign(0) === 0');
    expect(d3.jsSign(-0.0).isNegative, isTrue, reason: 'Math.sign(-0) === -0');
    expect(d3.jsSign(double.nan).isNaN, isTrue, reason: 'Math.sign(NaN)');
  });

  test('jsNumberToString drops the ".0" Dart adds', () {
    expect(d3.jsNumberToString(6), '6', reason: 'Dart prints "6.0"');
    expect(d3.jsNumberToString(64.5), '64.5', reason: 'unchanged');
    expect(d3.jsNumberToString(-0.0), '0', reason: 'String(-0) === "0"');
    expect(d3.jsNumberToString(1e21), '1e+21', reason: 'String(1e21)');
    expect(d3.jsNumberToString(1e-7), '1e-7', reason: 'String(1e-7)');
    expect(d3.jsNumberToString(0.000001), '0.000001', reason: 'String(1e-6)');
    expect(d3.jsNumberToString(double.nan), 'NaN', reason: 'String(NaN)');
  });

  test('tau and halfPi', () {
    expect(d3.tau, 2 * math.pi, reason: 'd3-shape/src/math.js:12');
    expect(d3.halfPi, math.pi / 2, reason: 'd3-shape/src/math.js:11');
  });

  group('differential against the committed d3 corpus', () {
    test('log10 and pow10 reproduce every tickIncrement', () async {
      final corpus = await loadD3Golden();
      final cases = goldenCases(corpus, 'ticks');
      expect(
        cases,
        isNotEmpty,
        reason: 'the corpus must actually have been read',
      );
      for (final c in cases) {
        final start = jsNum(c['start'])!;
        final stop = jsNum(c['stop'])!;
        final count = jsNum(c['count'])!;
        // `tickIncrement` does not reverse a descending domain the way `ticks`
        // and `tickStep` do (`d3-array/src/ticks.js:45-48`), so a reversed case
        // legitimately reports NaN.
        expect(
          _tickSpecProbe(start, stop, count)[2],
          closeToJs(c['tickIncrement']),
          reason:
              'tickIncrement($start, $stop, $count) — a log10 that is not '
              'exact at a decade, or a pow10 built with math.pow, changes this',
        );
      }
    });

    test('log10 and pow10 agree with the decades d3-scale emitted', () async {
      final corpus = await loadD3Golden();
      // `scaleLog([1, 1e12]).ticks()` takes the `else` branch of
      // `d3-scale/src/log.js:102`, where the whole tick list is `pows(i)` for
      // consecutive integers — so the corpus records `+('1e' + i)` for every
      // decade from 1 to 1e12, produced by JS. Those are exactly the values the
      // naive `math.log(x) / math.ln10` gets wrong: it reads 1e12 as
      // 11.999999999999998.
      final decades = goldenCases(corpus, 'scaleLog')
          .map((c) => jsNums(c['ticks']))
          .firstWhere(
            (ticks) => ticks.length == 13,
            orElse: () => throw StateError('the 1..1e12 case has gone missing'),
          );
      for (var e = 0; e < decades.length; e++) {
        final tick = decades[e]!;
        expect(
          d3.pow10(e),
          tick,
          reason: 'pow10($e) must be bit-identical to the JS 1e$e',
        );
        expect(
          d3.log10(tick),
          e.toDouble(),
          reason:
              'log10(1e$e) must be exact, or log.js:87 and :102 pick the '
              'wrong decade and the whole axis shifts',
        );
      }
    });

    test(
      'jsNumberToString reproduces every number in the path corpus',
      () async {
        final corpus = await loadD3Golden();
        // Every number in a `d` string was written by JS string concatenation
        // (`d3-path/src/path.js:26-145`), so the corpus records String(number)
        // output directly.
        final pattern = RegExp(r'-?\d+(?:\.\d+)?(?:e[-+]?\d+)?');
        var checked = 0;
        for (final c in goldenCases(corpus, 'shape')) {
          for (final key in const <String>['d', 'arc']) {
            final value = c[key];
            if (value is! String) {
              continue;
            }
            for (final match in pattern.allMatches(value)) {
              final token = match.group(0)!;
              expect(
                d3.jsNumberToString(double.parse(token)),
                token,
                reason:
                    'String($token) round-trips; Dart would print '
                    '"${double.parse(token)}"',
              );
              checked++;
            }
          }
        }
        expect(
          checked,
          greaterThan(100),
          reason: 'the path corpus must actually have been walked',
        );
      },
    );
  });
}
