import 'package:fluent_2/src/charts/internal/plotly/predicates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a number is never a date', () {
    expect(
      isPlotlyDate(1700000000000),
      isFalse,
      reason:
          'PlotlySchemaConverter.ts:47-49 refuses numbers because milliseconds and plain '
          'numbers are indistinguishable without context.',
    );
  });

  test(
    'a string parsing to year 2000 or 2001 without a four-digit year is not a date',
    () {
      expect(
        isPlotlyDate('Jan 5'),
        isFalse,
        reason:
            'PlotlySchemaConverter.ts:55-59 rejects the implicit-year fallback.',
      );
      expect(
        isPlotlyDate('2001-01-05'),
        isTrue,
        reason:
            'PlotlySchemaConverter.ts:56 keeps it when a four-digit year is present.',
      );
    },
  );

  test('isYear accepts integers in 1900..2100 inclusive and nothing else', () {
    expect(
      isPlotlyYear(1900),
      isTrue,
      reason: 'PlotlySchemaConverter.ts:96 lower bound.',
    );
    expect(
      isPlotlyYear(2100),
      isTrue,
      reason: 'PlotlySchemaConverter.ts:96 upper bound.',
    );
    expect(
      isPlotlyYear(1899),
      isFalse,
      reason: 'PlotlySchemaConverter.ts:96 lower bound is exclusive below.',
    );
    expect(
      isPlotlyYear(2000.5),
      isFalse,
      reason: 'PlotlySchemaConverter.ts:96 requires an integer.',
    );
    expect(
      isPlotlyYear('1999'),
      isTrue,
      reason: 'PlotlySchemaConverter.ts:95 parses numeric strings.',
    );
  });

  test(
    'isMonth matches long and short English month names case-insensitively',
    () {
      expect(
        isPlotlyMonth('january'),
        isTrue,
        reason: 'PlotlySchemaConverter.ts:84-85.',
      );
      expect(
        isPlotlyMonth('SEP'),
        isTrue,
        reason: 'PlotlySchemaConverter.ts:81 short form.',
      );
      expect(
        isPlotlyMonth('Janua'),
        isFalse,
        reason: 'PlotlySchemaConverter.ts:83-88 requires an exact match.',
      );
      expect(
        isPlotlyMonth(1),
        isFalse,
        reason: 'PlotlySchemaConverter.ts:65-67 requires a string.',
      );
    },
  );

  test('array predicates accept nulls and recurse into 2-D arrays', () {
    expect(
      isNumberArray(<Object?>[1, '2', null]),
      isTrue,
      reason:
          'PlotlySchemaConverter.ts:130-134 admits numeric strings and null.',
    );
    expect(
      isNumberArray(<Object?>[
        <Object?>[1, 2],
        <Object?>[3, 4],
      ]),
      isTrue,
      reason:
          'PlotlySchemaConverter.ts:114-117 handles the 2-D case with every/every.',
    );
    expect(
      isNumberArray(<Object?>[]),
      isFalse,
      reason: 'PlotlySchemaConverter.ts:110-112 rejects the empty array.',
    );
  });

  test('isObjectArray excludes lists', () {
    expect(
      isObjectArray(<Object?>[
        <String, Object?>{'a': 1},
      ]),
      isTrue,
      reason: 'PlotlySchemaConverter.ts:156 requires a non-array object.',
    );
    expect(
      isObjectArray(<Object?>[
        <Object?>[1],
      ]),
      isFalse,
      reason: 'PlotlySchemaConverter.ts:156 excludes arrays.',
    );
  });

  test('getAxisIds and getAxisKey follow the xN/yN convention', () {
    expect(
      getAxisIds(<String, Object?>{'xaxis': 'x3', 'yaxis': 'y'}),
      (x: 3, y: 1),
      reason:
          'PlotlySchemaConverter.ts:653-666 defaults a bare axis name to 1.',
    );
    expect(
      getAxisKey('y', 1),
      'yaxis',
      reason: 'PlotlySchemaConverter.ts:670 drops the 1.',
    );
    expect(
      getAxisKey('y', 2),
      'yaxis2',
      reason: 'PlotlySchemaConverter.ts:670 keeps 2 and above.',
    );
  });

  test('isScatterAreaChart is fill-or-stackgroup', () {
    expect(
      isScatterAreaChart(<String, Object?>{'stackgroup': 'a'}),
      isTrue,
      reason: 'PlotlySchemaConverter.ts:674.',
    );
    expect(
      isScatterAreaChart(<String, Object?>{'fill': 'tonextx'}),
      isFalse,
      reason:
          "PlotlySchemaConverter.ts:674 only accepts 'tonexty' and 'tozeroy'.",
    );
  });

  test('isInvalidValue covers null, absent and non-finite numbers', () {
    expect(
      isInvalidValue(null),
      isTrue,
      reason: 'PlotlySchemaConverter.ts:173.',
    );
    expect(
      isInvalidValue(double.nan),
      isTrue,
      reason: 'PlotlySchemaConverter.ts:173 !isFinite.',
    );
    expect(
      isInvalidValue(0),
      isFalse,
      reason: 'PlotlySchemaConverter.ts:173 keeps zero.',
    );
  });

  // --- Beyond the plan's Step 1: the corners the router actually leans on ---
  // Each of these is a documented deviation from the pasted Step 3 block, so
  // each carries a test that dies if the deviation is reverted.

  test('the Plotly aliases are the model predicates, not a second copy', () {
    expect(
      isPlotlyNumber('0x10'),
      isTrue,
      reason:
          "PlotlySchemaConverter.ts:41 is `isFinite(value)`, and JS `Number('0x10')` is 16. "
          'model/chart_value.dart:75 uses num.tryParse, which reads hex the same way; the '
          "plan's double.tryParse would have returned null and mis-typed the axis.",
    );
    expect(
      isPlotlyNumber('12abc'),
      isFalse,
      reason:
          'PlotlySchemaConverter.ts:41 pairs parseFloat with isFinite precisely so trailing '
          'rubbish is refused, per model/chart_value.dart:66-71.',
    );
    expect(
      isPlotlyDate(DateTime.utc(2020)),
      isTrue,
      reason:
          'model/chart_value.dart:89 admits an already-parsed DateTime; a sanitised schema '
          'can hold one once a caller has decoded it.',
    );
  });

  test('getAxisIds ignores an axis reference naming the other letter', () {
    expect(
      getAxisIds(<String, Object?>{'xaxis': 'y3', 'yaxis': 'x2'}),
      (x: 1, y: 1),
      reason:
          r'PlotlySchemaConverter.ts:654 tests /^x\d+$/ against xaxis and :659 tests '
          r'/^y\d+$/ against yaxis, so a cross-named reference matches neither and falls '
          'back to 1.',
    );
    expect(
      getAxisIds(<String, Object?>{'xaxis': 'x99999999999999999999'}),
      (x: 1, y: 1),
      reason:
          'A digit run wider than 64 bits makes int.parse throw, which would abort routing '
          'on hostile JSON; int.tryParse falls back to the same default as an unmatched '
          'reference.',
    );
  });

  test('an empty stackgroup is falsy, as in JavaScript', () {
    expect(
      isScatterAreaChart(<String, Object?>{'stackgroup': ''}),
      isFalse,
      reason:
          'PlotlySchemaConverter.ts:674 reads `!!data.stackgroup`, and the empty string is '
          'falsy — the same JS-truthiness rule axis_builders.dart:951 applies to useUTC.',
    );
  });

  test('isArrayOfType survives a ragged 2-D array', () {
    expect(
      isNumberArray(<Object?>[
        <Object?>[1, 2],
        3,
      ]),
      isFalse,
      reason:
          'PlotlySchemaConverter.ts:116 calls innerArray.every unguarded and throws on a '
          'non-array row. The port returns false instead: this is untrusted JSON, and a '
          'throw here would take down the whole schema conversion.',
    );
  });
}
