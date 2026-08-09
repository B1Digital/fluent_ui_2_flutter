import 'package:fluent_2_web/src/charts/internal/d3/scale_band.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_support.dart';

void main() {
  test('padding(p) sets inner to min(1, p) AND outer to p, unclamped', () {
    final s = scaleBand()
      ..domainOf(<Object>['a', 'b', 'c'])
      ..rangeOf(<double>[0, 300])
      ..padding(1.4);
    expect(
      s.paddingInnerValue,
      1.0,
      reason:
          'd3-scale/src/band.js:59 — `paddingInner = Math.min(1, '
          'paddingOuter = +_)`, so the outer keeps the raw 1.4',
    );
    expect(s.paddingOuterValue, 1.4, reason: 'band.js:59, unclamped');
  });

  test('a domain miss returns null and does NOT grow the domain', () {
    final s = scaleBand()
      ..domainOf(<Object>['a', 'b'])
      ..rangeOf(<double>[0, 100]);
    expect(
      s('zzz'),
      isNull,
      reason:
          'd3-scale/src/ordinal.js grows an implicit domain; this port '
          'refuses, because a mistyped category silently reflowing the axis '
          'is worse than a null the caller must handle',
    );
    expect(
      s.domain.length,
      2,
      reason: 'the miss must not have appended anything',
    );
  });

  test('the step, start shift and bandwidth formulas', () {
    final s = scaleBand()
      ..domainOf(<Object>['a', 'b', 'c'])
      ..rangeOf(<double>[0, 300])
      ..paddingInner(0.5)
      ..paddingOuter(0.5);
    // step = 300 / max(1, 3 - 0.5 + 0.5 * 2) = 300 / 3.5
    expect(s.step, closeTo(300 / 3.5, 1e-12), reason: 'band.js:25');
    expect(
      s.bandwidth,
      closeTo(300 / 3.5 * 0.5, 1e-12),
      reason: 'band.js:28, step * (1 - paddingInner)',
    );
  });

  test('align is clamped to 0..1', () {
    final s = scaleBand()..align(5);
    expect(s.alignValue, 1.0, reason: 'band.js:71, max(0, min(1, _))');
  });

  test('a reversed range reverses the positions', () {
    final s = scaleBand()
      ..domainOf(<Object>['a', 'b'])
      ..rangeOf(<double>[300, 0]);
    expect(s('a')! > s('b')!, isTrue, reason: 'band.js:31 reverses the values');
  });

  test('against the d3 golden corpus', () async {
    final corpus = await loadD3Golden();
    for (final c in goldenCases(corpus, 'scaleBand')) {
      final s = scaleBand()
        ..domainOf((c['domain']! as List<Object?>).cast<String>())
        ..rangeOf(jsNums(c['range']).cast<double>());
      if (c.containsKey('padding')) {
        s.padding(jsNum(c['padding'])!);
        expect(
          s.paddingInnerValue,
          closeToJs(c['paddingInner']),
          reason: 'padding(${c['padding']}) inner',
        );
        expect(
          s.paddingOuterValue,
          closeToJs(c['paddingOuter']),
          reason: 'padding(${c['padding']}) outer',
        );
      } else {
        s
          ..paddingInner(jsNum(c['paddingInner'])!)
          ..paddingOuter(jsNum(c['paddingOuter'])!)
          ..align(jsNum(c['align'])!);
        final inputs = (c['atInputs']! as List<Object?>).cast<String>();
        final at = (c['at']! as List<Object?>).toList(growable: false);
        for (var i = 0; i < inputs.length; i++) {
          expect(
            s(inputs[i]),
            closeToJs(at[i]),
            reason: 'scaleBand domain ${c['domain']} at "${inputs[i]}"',
          );
        }
      }
      expect(s.bandwidth, closeToJs(c['bandwidth']), reason: 'bandwidth');
      expect(s.step, closeToJs(c['step']), reason: 'step');
    }
  });
}
