import 'package:fluent_2_web/src/charts/internal/d3/bin.dart' as d3;
import 'package:fluent_2_web/src/charts/internal/plotly/bins.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a string array bins into single-category groups by default', () {
    final bins = createBins(<Object?>['a', 'b', 'a', 'c']);
    expect(
      bins,
      <List<String>>[
        <String>['a'],
        <String>['b'],
        <String>['c'],
      ],
      reason:
          'PlotlySchemaAdapter.ts:3402-3407 dedupes then slices with step 1.',
    );
  });

  test('an explicit binSize groups categories', () {
    final bins = createBins(<Object?>['a', 'b', 'c', 'd'], binSize: 2);
    expect(bins, <List<String>>[
      <String>['a', 'b'],
      <String>['c', 'd'],
    ], reason: 'PlotlySchemaAdapter.ts:3405-3407 with step 2.');
  });

  test('a numeric array uses a niced scale domain', () {
    final bins = createBins(<Object?>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    expect(
      bins,
      isNotEmpty,
      reason:
          'PlotlySchemaAdapter.ts:3410-3413 builds the domain from a niced '
          'scaleLinear.',
    );
  });

  test('an explicit binSize drops the degenerate final bin', () {
    final bins = createBins(
      <Object?>[0, 1, 2, 3, 4],
      binStart: 0,
      binEnd: 4,
      binSize: 1,
    );
    expect(
      bins.length,
      4,
      reason:
          'PlotlySchemaAdapter.ts:3434-3438 slices off the final bin, whose x0 '
          'and x1 both equal maxVal, so the previous bin becomes the inclusive '
          'last one.',
    );
  });

  test('findBinIndex closes the last numeric bin on the right', () {
    final bins = createBins(
      <Object?>[0, 1, 2, 3, 4],
      binStart: 0,
      binEnd: 4,
      binSize: 1,
    );
    expect(
      findBinIndex(bins, 4, isString: false),
      3,
      reason:
          'PlotlySchemaAdapter.ts:3375-3379 uses <= for the final bin and < '
          'elsewhere.',
    );
    expect(
      findBinIndex(bins, null, isString: false),
      -1,
      reason: 'PlotlySchemaAdapter.ts:3369-3371.',
    );
  });

  test('the five histfunc modes', () {
    expect(
      calculateHistFunc(null, <double>[1, 2, 3]),
      3,
      reason: 'PlotlySchemaAdapter.ts:3454 count.',
    );
    expect(
      calculateHistFunc('sum', <double>[1, 2, 3]),
      6,
      reason: 'PlotlySchemaAdapter.ts:3446.',
    );
    expect(
      calculateHistFunc('avg', <double>[1, 2, 3]),
      2,
      reason: 'PlotlySchemaAdapter.ts:3448.',
    );
    expect(
      calculateHistFunc('avg', <double>[]),
      0,
      reason: 'PlotlySchemaAdapter.ts:3448 empty guard.',
    );
    expect(
      calculateHistFunc('min', <double>[3, 1]),
      1,
      reason: 'PlotlySchemaAdapter.ts:3450.',
    );
    expect(
      calculateHistFunc('max', <double>[3, 1]),
      3,
      reason: 'PlotlySchemaAdapter.ts:3452.',
    );
  });

  test('the five histnorm modes, each with its zero guard', () {
    expect(
      calculateHistNorm(null, 5, 10, 2),
      5,
      reason: 'PlotlySchemaAdapter.ts:3475.',
    );
    expect(
      calculateHistNorm('percent', 5, 10, 2),
      50,
      reason: 'PlotlySchemaAdapter.ts:3467.',
    );
    expect(
      calculateHistNorm('percent', 5, 0, 2),
      0,
      reason: 'PlotlySchemaAdapter.ts:3467 zero total.',
    );
    expect(
      calculateHistNorm('probability', 5, 10, 2),
      0.5,
      reason: 'PlotlySchemaAdapter.ts:3469.',
    );
    expect(
      calculateHistNorm('density', 5, 10, 2),
      2.5,
      reason: 'PlotlySchemaAdapter.ts:3471.',
    );
    expect(
      calculateHistNorm('density', 5, 10, 0),
      0,
      reason: 'PlotlySchemaAdapter.ts:3471 zero dx.',
    );
    expect(
      calculateHistNorm('probability density', 5, 10, 2),
      0.25,
      reason: 'PlotlySchemaAdapter.ts:3473.',
    );
  });

  // Beyond the plan's list: the two accessors and the numeric-bin geometry the
  // histogram transformers read, and the string arm of `findBinIndex`.
  test('getBinSize and getBinCenter read the bin edges', () {
    final bins = createBins(
      <Object?>[0, 1, 2, 3, 4],
      binStart: 0,
      binEnd: 4,
      binSize: 1,
    );
    final first = bins.first as d3.Bin;
    expect(
      getBinSize(first),
      1,
      reason: 'PlotlySchemaAdapter.ts:3382-3384 is x1 - x0, and binSize is 1.',
    );
    expect(
      getBinCenter(first),
      0.5,
      reason: 'PlotlySchemaAdapter.ts:3386-3388 is (x1 + x0) / 2 over [0, 1).',
    );
  });

  test('findBinIndex searches a string bin by membership', () {
    final bins = createBins(<Object?>['a', 'b', 'c', 'd'], binSize: 2);
    expect(
      findBinIndex(bins, 'c', isString: true),
      1,
      reason:
          "PlotlySchemaAdapter.ts:3374 uses `bin.includes`, and 'c' is in "
          'the second group.',
    );
    expect(
      findBinIndex(bins, 'z', isString: true),
      -1,
      reason: 'PlotlySchemaAdapter.ts:3374, findIndex answers -1 on no match.',
    );
  });

  test('an empty or non-list input bins into nothing', () {
    expect(
      createBins(<Object?>[]),
      isEmpty,
      reason: 'PlotlySchemaAdapter.ts:3397-3399 guards length 0.',
    );
    expect(
      createBins(null),
      isEmpty,
      reason: 'PlotlySchemaAdapter.ts:3397-3399 guards a falsy data.',
    );
  });
}
