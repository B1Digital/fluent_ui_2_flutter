import 'package:fluent_2_web/src/charts/model/chart_value.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FluentChartAxisType', () {
    test('collapses XAxisTypes and YAxisType at their shared ordinals', () {
      // utilities.ts:110-114 and :116-120 declare byte-identical enums.
      expect(
        FluentChartAxisType.values,
        <FluentChartAxisType>[
          FluentChartAxisType.numeric,
          FluentChartAxisType.date,
          FluentChartAxisType.category,
        ],
        reason:
            'NumericAxis 0, DateAxis 1, StringAxis 2 (utilities.ts:110-120).',
      );
    });
  });

  group('chartAxisTypeOf', () {
    test('maps a String to category', () {
      expect(
        chartAxisTypeOf('Jan'),
        FluentChartAxisType.category,
        reason: "utilities.ts:1689 case 'string'.",
      );
    });
    test('maps a num to numeric', () {
      expect(
        chartAxisTypeOf(7),
        FluentChartAxisType.numeric,
        reason: "utilities.ts:1691 case 'number'.",
      );
      expect(
        chartAxisTypeOf(7.5),
        FluentChartAxisType.numeric,
        reason: 'A Dart double is a JS number.',
      );
    });
    test('falls through to date for anything else', () {
      expect(
        chartAxisTypeOf(DateTime(2024)),
        FluentChartAxisType.date,
        reason: 'utilities.ts:1693 default.',
      );
      expect(
        chartAxisTypeOf(const <int>[]),
        FluentChartAxisType.date,
        reason:
            'The `default:` arm swallows every non-string non-number, which is '
            'a defect reproduced verbatim (utilities.ts:1693).',
      );
    });
  });

  group('isInvalidChartValue', () {
    test('is true for null', () {
      expect(
        isInvalidChartValue(null),
        isTrue,
        reason: 'PlotlySchemaConverter.ts:172 `value === null`.',
      );
    });
    test('is true for NaN and for either infinity', () {
      expect(
        isInvalidChartValue(double.nan),
        isTrue,
        reason: '!isFinite(NaN).',
      );
      expect(
        isInvalidChartValue(double.infinity),
        isTrue,
        reason: '!isFinite(Infinity).',
      );
      expect(
        isInvalidChartValue(double.negativeInfinity),
        isTrue,
        reason: '!isFinite(-Infinity).',
      );
    });
    test('is FALSE for the empty string', () {
      expect(
        isInvalidChartValue(''),
        isFalse,
        reason:
            'PlotlySchemaConverter.ts:172 tests only undefined, null and a '
            'non-finite number. The cross-plan contract prose claiming an '
            'empty-string arm has no source behind it.',
      );
    });
    test('is false for a finite number and for a DateTime', () {
      expect(isInvalidChartValue(0), isFalse, reason: '0 is finite.');
      expect(
        isInvalidChartValue(DateTime(2024)),
        isFalse,
        reason: 'A Date is neither null nor a non-finite number.',
      );
    });
  });

  group('isPlottable', () {
    test('requires both coordinates to be valid', () {
      expect(isPlottable(1, 2), isTrue, reason: 'utilities.ts:2279.');
      expect(isPlottable(double.nan, 2), isFalse, reason: 'x invalid.');
      expect(isPlottable(1, null), isFalse, reason: 'y invalid.');
    });
  });

  group('isNumberLike', () {
    test('parses a leading float out of a string, like parseFloat', () {
      expect(
        isNumberLike('12.5'),
        isTrue,
        reason: 'PlotlySchemaConverter.ts:41 parseFloat succeeds.',
      );
      expect(
        isNumberLike('12abc'),
        isFalse,
        reason:
            'parseFloat("12abc") is 12, but the second half of '
            'PlotlySchemaConverter.ts:41 is isFinite("12abc"), and isFinite '
            'coerces with Number(), which yields NaN for trailing rubbish.',
      );
      expect(
        isNumberLike('abc'),
        isFalse,
        reason: 'parseFloat returns NaN (PlotlySchemaConverter.ts:41).',
      );
      expect(isNumberLike(3), isTrue, reason: 'A num is a number.');
      expect(isNumberLike(null), isFalse, reason: 'parseFloat(null) is NaN.');
      expect(
        isNumberLike(double.infinity),
        isFalse,
        reason: 'isFinite(Infinity) is false.',
      );
    });
  });

  group('isDateLike', () {
    test('rejects anything number-like before parsing', () {
      expect(
        isDateLike('2024'),
        isFalse,
        reason:
            'PlotlySchemaConverter.ts:47-49 returns early for a number-like '
            'value, because milliseconds and a year are indistinguishable.',
      );
    });
    test('accepts a full ISO date', () {
      expect(
        isDateLike('2024-03-05'),
        isTrue,
        reason: 'Parses, and the input carries a four-digit year.',
      );
    });
    test('rejects a bare month name, which JS parses into year 2001', () {
      expect(
        isDateLike('March'),
        isFalse,
        reason:
            'PlotlySchemaConverter.ts:55-58 — no four-digit year in the input '
            'and the parsed year is 2000 or 2001.',
      );
    });
    test('rejects an unparseable string', () {
      expect(
        isDateLike('not a date'),
        isFalse,
        reason: 'PlotlySchemaConverter.ts:51-53 NaN guard.',
      );
    });
  });
}
