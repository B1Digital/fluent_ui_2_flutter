import 'package:fluent_2_web/src/charts/internal/d3/scale_log.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_support.dart';

void main() {
  test('tickFormat BLANKS ticks whose mantissa exceeds k', () {
    // utilities.ts:294 and :876 test `defaultFormat?.(v) === ''` to decide
    // whether a log tick gets a label at all, so the blanking is behaviour,
    // not cosmetics.
    final s = scaleLog()..domainOf(<double>[1, 100000]);
    final f = s.tickFormat();
    final labelled = s.ticks().where((Object v) => f(v).isNotEmpty).length;
    expect(
      labelled,
      lessThan(s.ticks().length),
      reason:
          'd3-scale/src/log.js:117-122 — k = max(1, base * count / '
          'ticks().length), and any tick above it formats to ""',
    );
  });

  test('a negative domain reflects the transform', () {
    final s = scaleLog()
      ..domainOf(<double>[-100, -1])
      ..rangeOf(<double>[0, 100]);
    expect(s(-10), closeTo(50, 1e-9), reason: 'log.js:53-55, the reflect pair');
  });

  test('a non-positive input on a positive domain gives NaN, not null', () {
    final s = scaleLog()
      ..domainOf(<double>[1, 100])
      ..rangeOf(<double>[0, 100]);
    // The plan asserted `s(0)!.isInfinite` here. It is not: Math.log(0) is
    // -Infinity, but `d3-interpolate/src/number.js:3` then evaluates
    // `a * (1 - t) + b * t` at t = -Infinity, and both `0 * Infinity` and
    // `Infinity + -Infinity` are NaN. Checked against the pinned module —
    // `scaleLog().domain([1,100]).range([0,100])(0)` prints NaN in Node, for
    // range [10, 100] as well. What matters, and what the Scale contract
    // documents, is that the result is a number rather than null: the input
    // itself was numeric, so continuous.js:86 does not short-circuit.
    expect(
      s(0),
      isA<double>().having((double v) => v.isNaN, 'isNaN', isTrue),
      reason: 'Math.log(0) is -Infinity, which number.js:3 turns into NaN',
    );
    expect(s(-1)!.isNaN, isTrue, reason: 'Math.log(-1) is NaN');
  });

  test('nice snaps to whole decades', () {
    final s = scaleLog()..domainOf(<double>[2, 7000]);
    s.nice();
    expect(
      s.domain,
      orderedEquals(<Object>[1.0, 10000.0]),
      reason: 'log.js:126-129, pows(floor(logs(x))) and pows(ceil(logs(x)))',
    );
  });

  test('against the d3 golden corpus', () async {
    final corpus = await loadD3Golden();
    for (final c in goldenCases(corpus, 'scaleLog')) {
      final domain = jsNums(c['domain']).cast<double>();
      final s = scaleLog()
        ..domainOf(domain)
        ..rangeOf(<double>[0, 100]);
      final inputs = jsNums(c['atInputs']);
      for (var i = 0; i < inputs.length; i++) {
        expect(
          s(inputs[i]!),
          closeToJs((c['at']! as List<Object?>)[i]),
          reason: 'scaleLog $domain at ${inputs[i]}',
        );
      }
      expect(
        s.ticks().cast<double>(),
        orderedEquals(jsNums(c['ticks']).cast<double>()),
        reason: 'ticks() over $domain',
      );
      // 5 is the non-default tick count the generator also dumped: on
      // [1, 1e12] it drives the `j - i >= n` branch of log.js:104-106, which
      // the default count never reaches.
      expect(
        s.ticks(5).cast<double>(),
        orderedEquals(jsNums(c['ticks5']).cast<double>()),
        reason: 'ticks(5) over $domain',
      );
      final f = s.tickFormat();
      final want = (c['tickFormat']! as List<Object?>).cast<String>();
      final ticks = s.ticks();
      for (var i = 0; i < want.length; i++) {
        expect(f(ticks[i]), want[i], reason: 'tickFormat() of tick $i');
      }
      // The generator applies tickFormat(5) to the DEFAULT tick list, which is
      // also what log.js:120 divides by when it computes k, so both sides here
      // use `ticks` rather than `s.ticks(5)`.
      final f5 = s.tickFormat(5);
      final want5 = (c['tickFormat5']! as List<Object?>).cast<String>();
      for (var i = 0; i < want5.length; i++) {
        expect(f5(ticks[i]), want5[i], reason: 'tickFormat(5) of tick $i');
      }
      final niced = scaleLog()..domainOf(domain);
      niced.nice();
      expect(
        niced.domain.cast<double>(),
        orderedEquals(jsNums(c['niced']).cast<double>()),
        reason: 'nice() over $domain',
      );
    }
  });
}
