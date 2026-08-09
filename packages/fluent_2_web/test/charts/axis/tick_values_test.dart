import 'package:fluent_2_web/src/charts/axis/tick_values.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('handleFloatingPointPrecisionError', () {
    test('snaps a value within 1e-6 of an integer', () {
      expect(
        handleFloatingPointPrecisionError(2.9999999),
        3,
        reason:
            'utilities.ts:651-654 — |n - round(n)| < 1e-6 snaps to the integer.',
      );
    });

    test('leaves a value outside the epsilon alone', () {
      expect(
        handleFloatingPointPrecisionError(2.99999),
        2.99999,
        reason: '1e-5 is outside the 1e-6 window at utilities.ts:653.',
      );
    });
  });

  group('isPowerOf10', () {
    test('is true at a decade', () {
      expect(
        isPowerOf10(100),
        isTrue,
        reason: 'log10(100) % 1 == 0 (utilities.ts:645-648).',
      );
      expect(isPowerOf10(1), isTrue, reason: 'log10(1) == 0.');
    });

    test('is false off a decade', () {
      expect(isPowerOf10(50), isFalse, reason: 'log10(50) % 1 == 0.69897.');
    });

    test('is false at zero and for negatives — NaN never equals 0', () {
      expect(
        isPowerOf10(0),
        isFalse,
        reason:
            'log10(0) is -Infinity, and -Infinity % 1 is NaN '
            '(utilities.ts:647).',
      );
      expect(
        isPowerOf10(-10),
        isFalse,
        reason: 'log10 of a negative is NaN, so the % 1 == 0 test fails.',
      );
    });
  });

  group('calculatePrecision', () {
    test('returns a negative precision for trailing zeros', () {
      expect(
        calculatePrecision(100),
        -2,
        reason: "utilities.ts:2541-2542 — group 1 of '100' is '00'.",
      );
      expect(calculatePrecision(20), -1, reason: "group 1 of '20' is '0'.");
    });

    test('returns a positive precision for decimals', () {
      expect(
        calculatePrecision(0.25),
        2,
        reason: "utilities.ts:2544 — group 2 of '0.25' is '25'.",
      );
      expect(calculatePrecision(0.1), 1, reason: "group 2 of '0.1' is '1'.");
    });

    test('returns 0 when neither group matches', () {
      expect(
        calculatePrecision(1),
        0,
        reason: "'1' has no trailing zeros and no decimal point.",
      );
      expect(
        calculatePrecision(7),
        0,
        reason: 'utilities.ts:2547 falls through to 0.',
      );
    });

    test('stringifies like JavaScript, not like Dart', () {
      expect(
        calculatePrecision(100.0),
        -2,
        reason:
            "Dart's 100.0.toString() is '100.0', which would match group 2 and "
            "return 1. JS String(100) is '100', so the port must strip the "
            'trailing .0 before running the regex.',
      );
    });

    test('accepts a string, as the upstream union does', () {
      expect(
        calculatePrecision('0.125'),
        3,
        reason: 'utilities.ts:2530 takes number | string.',
      );
    });
  });

  group('precisionRoundValue', () {
    test('rounds to a positive precision', () {
      expect(
        precisionRoundValue(1.2345, 2),
        1.23,
        reason: 'utilities.ts:2555-2558 — round(1.2345 * 100) / 100.',
      );
    });

    test('rounds to a negative precision', () {
      expect(
        precisionRoundValue(1234, -2),
        1200,
        reason: 'round(1234 * 0.01) / 0.01 == 12 / 0.01 == 1200.',
      );
    });

    test('rounds half-up, as JavaScript does', () {
      expect(
        precisionRoundValue(-0.5, 0),
        0,
        reason:
            'JS Math.round(-0.5) is -0, so the result is 0. Bare Dart '
            'round() would give -1 (spec section 8).',
      );
    });
  });
}
