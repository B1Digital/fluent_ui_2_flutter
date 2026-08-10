import 'package:fluent_2_web/src/charts/internal/d3/js_math.dart' as d3;
import 'package:flutter_test/flutter_test.dart';

/// Pins plan 01's `jsNumberToString`, which reproduces JavaScript's
/// `String(number)`, against the two sites in this plan that rely on it:
/// `PolarChart.utils.ts:255-256` and `SankeyChart.tsx:614`.
///
/// It takes a `double`, so every call site in this plan converts: the polar
/// angle is already a double and Sankey's weight is a `num` from the data model.
void main() {
  test('integral doubles lose the .0 that Dart adds', () {
    expect(
      d3.jsNumberToString(45),
      '45',
      reason: 'PolarChart.utils.ts:256 renders `45°`, not `45.0°`',
    );
    expect(d3.jsNumberToString(0), '0', reason: 'zero has no fractional part');
    expect(
      d3.jsNumberToString(-0.0),
      '0',
      reason: 'JS String(-0) is "0"; Dart (-0.0).toStringAsFixed(0) is "-0"',
    );
    expect(d3.jsNumberToString(-135), '-135', reason: 'negative integral');
  });

  test('integral doubles pass straight through', () {
    expect(
      d3.jsNumberToString(7),
      '7',
      reason: 'an integral double is already exact',
    );
  });

  test('fractional values keep Dart shortest-round-trip, which matches JS', () {
    expect(d3.jsNumberToString(0.25), '0.25', reason: 'exact binary fraction');
    expect(
      d3.jsNumberToString(0.1 + 0.2),
      '0.30000000000000004',
      reason: 'both runtimes print the shortest round-tripping decimal',
    );
    expect(d3.jsNumberToString(-0.5), '-0.5', reason: 'negative fraction');
  });

  test('large integral values do not overflow a 64-bit int', () {
    expect(
      d3.jsNumberToString(1e20),
      '100000000000000000000',
      reason: '1e20 exceeds 2^53 so toInt() is unsafe; JS prints it in full',
    );
    expect(
      d3.jsNumberToString(1e21),
      '1e+21',
      reason: 'JS switches to exponential at 1e21 and so does Dart',
    );
  });

  test('non-finite values match the JS spellings', () {
    expect(
      d3.jsNumberToString(double.infinity),
      'Infinity',
      reason: 'JS spelling',
    );
    expect(d3.jsNumberToString(double.nan), 'NaN', reason: 'JS spelling');
  });
}
