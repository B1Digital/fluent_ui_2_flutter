import 'package:fluent_2_web/src/charts/internal/d3/scale_linear.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_support.dart';

void main() {
  test('nice leaves an already-round fractional domain alone', () {
    final s = scaleLinear()..domainOf(<double>[0.1, 0.9]);
    s.nice();
    expect(
      s.domain,
      orderedEquals(<Object>[0.1, 0.9]),
      reason:
          'the step for [0.1, 0.9] at a count of 10 is the reciprocal -10, so '
          'linear.js:46-47 rounds both endpoints onto themselves and :38 exits '
          'on the second, repeated step. The plan asserted [0, 1] here, which '
          'neither d3 nor the corpus agrees with; corpus vector 6 of '
          '`scaleLinear` is the authority.',
    );
  });

  test('nice mutates the endpoints in place, keeping interior stops', () {
    final s = scaleLinear()..domainOf(<double>[0.1, 5, 9.9]);
    s.nice(5);
    final domain = s.domain.cast<double>();
    expect(
      domain[1],
      5.0,
      reason:
          'linear.js:39-40 writes only d[i0] and d[i1]; the middle stop of '
          'a polylinear domain survives untouched',
    );
    expect(domain.first, 0.0, reason: 'the low endpoint is floored');
    expect(domain.last, 10.0, reason: 'the high endpoint is ceiled');
  });

  test('nice on a descending domain nices the right ends', () {
    final s = scaleLinear()..domainOf(<double>[9.9, 0.1]);
    s.nice();
    expect(
      s.domain,
      orderedEquals(<Object>[10.0, 0.0]),
      reason: 'linear.js:31-34 swaps the indices, not the values',
    );
  });

  test('nice terminates on a degenerate domain and leaves it untouched', () {
    final s = scaleLinear()..domainOf(<double>[10, 10]);
    s.nice();
    expect(
      s.domain,
      orderedEquals(<Object>[10.0, 10.0]),
      reason:
          'a zero-width span gives an infinite increment, whose rounding turns '
          'both endpoints NaN; the next increment is NaN too, so linear.js:48 '
          'breaks and :54 returns the scale with the domain never reassigned. '
          'Unlike d3-array nice (ticks.dart), there is no isFinite guard.',
    );
  });

  test('ticks and tickFormat default to a count of 10', () {
    final s = scaleLinear()..domainOf(<double>[0, 1]);
    expect(s.ticks().length, 11, reason: 'linear.js:11, `count == null ? 10`');
    expect(s.tickFormat()(0.3), '0.3', reason: 'linear.js:16');
  });

  test('against the d3 golden corpus', () async {
    final corpus = await loadD3Golden();
    for (final c in goldenCases(corpus, 'scaleLinear')) {
      final domain = jsNums(c['domain']).cast<double>();
      final range = jsNums(c['range']).cast<double>();
      final s = scaleLinear()
        ..domainOf(domain)
        ..rangeOf(range);
      if (c.containsKey('atInputs')) {
        final inputs = jsNums(c['atInputs']);
        for (var i = 0; i < inputs.length; i++) {
          expect(
            s(inputs[i]!),
            closeToJs((c['at']! as List<Object?>)[i]),
            reason: 'scaleLinear $domain -> $range at ${inputs[i]}',
          );
        }
        final invertInputs = jsNums(c['invertInputs']);
        for (var i = 0; i < invertInputs.length; i++) {
          expect(
            s.invert(invertInputs[i]!),
            closeToJs((c['invert']! as List<Object?>)[i]),
            reason: 'invert(${invertInputs[i]})',
          );
        }
        final wantFormat = (c['tickFormat5']! as List<Object?>).cast<String>();
        final f = s.tickFormat(5);
        final ticks5 = s.ticks(5);
        for (var i = 0; i < wantFormat.length; i++) {
          expect(
            f(ticks5[i]),
            wantFormat[i],
            reason: 'tickFormat(5) of tick $i',
          );
        }
        expect(
          ticks5.cast<double>(),
          orderedEquals(jsNums(c['ticks5']).cast<double>()),
          reason: 'ticks(5) over $domain',
        );
      }
      if (c['ticks10'] != null) {
        expect(
          s.ticks().cast<double>(),
          orderedEquals(jsNums(c['ticks10']).cast<double>()),
          reason: 'ticks() over $domain',
        );
      }
      final niced = scaleLinear()
        ..domainOf(domain)
        ..rangeOf(range)
        ..nice();
      expect(
        niced.domain.cast<double>(),
        orderedEquals(jsNums(c['niced']).cast<double>()),
        reason: 'nice() over $domain',
      );
      if (c['niced5'] != null) {
        final niced5 = scaleLinear()
          ..domainOf(domain)
          ..rangeOf(range)
          ..nice(5);
        expect(
          niced5.domain.cast<double>(),
          orderedEquals(jsNums(c['niced5']).cast<double>()),
          reason: 'nice(5) over $domain',
        );
      }
    }
  });
}
