import 'package:fluent_2_web/src/charts/internal/d3/scale_continuous.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_support.dart';

void main() {
  test('a degenerate domain maps everything to the range midpoint', () {
    final s = ScaleContinuous()
      ..domainOf(<double>[10, 10])
      ..rangeOf(<double>[0, 100]);
    expect(
      s(10),
      50.0,
      reason:
          'd3-scale/src/continuous.js:15 — normalize returns a constant '
          '0.5 when the domain span is zero, so the output is the midpoint, '
          'not NaN and not the range start',
    );
    expect(s(999), 50.0, reason: 'the constant does not read its input');
  });

  test('a NaN domain span yields NaN, not 0.5', () {
    final s = ScaleContinuous()
      ..domainOf(<double>[double.nan, 1])
      ..rangeOf(<double>[0, 100]);
    expect(
      s(0.5)!.isNaN,
      isTrue,
      reason: 'continuous.js:15 — `constant(isNaN(b) ? NaN : 0.5)`',
    );
  });

  test('bimap handles a descending domain by swapping both sides', () {
    final s = ScaleContinuous()
      ..domainOf(<double>[100, 0])
      ..rangeOf(<double>[0, 500]);
    expect(s(100), 0.0, reason: 'continuous.js:28');
    expect(s(0), 500.0, reason: 'continuous.js:28');
    expect(s(75), 125.0, reason: 'linear between them');
  });

  test('polymap bisects a three-stop domain', () {
    final s = ScaleContinuous()
      ..domainOf(<double>[0, 10, 100])
      ..rangeOf(<double>[0, 50, 100]);
    expect(s(5), 25.0, reason: 'continuous.js:45-53, first segment');
    expect(s(55), 75.0, reason: 'second segment');
  });

  test("a non-numeric input returns null, matching d3's unknown", () {
    final s = ScaleContinuous()
      ..domainOf(<double>[0, 1])
      ..rangeOf(<double>[0, 1]);
    expect(
      s('x'),
      isNull,
      reason: 'continuous.js:86 returns `unknown`, which is undefined here',
    );
  });

  test('invert round-trips', () {
    final s = ScaleContinuous()
      ..domainOf(<double>[0, 200])
      ..rangeOf(<double>[500, 0]);
    expect(s.invert(250), 100.0, reason: 'continuous.js:90');
  });

  test('matches the d3 scaleLinear corpus for call and invert', () async {
    final corpus = await loadD3Golden();
    var asserted = 0;
    for (final c in goldenCases(corpus, 'scaleLinear')) {
      final s = ScaleContinuous()
        ..domainOf(jsNums(c['domain']).cast<double>())
        ..rangeOf(jsNums(c['range']).cast<double>());
      if (c.containsKey('at')) {
        final at = c['at']! as List<Object?>;
        final inputs = jsNums(c['atInputs']).cast<double>();
        for (var i = 0; i < inputs.length; i++) {
          expect(
            s(inputs[i]),
            closeToJs(at[i]),
            reason:
                'scaleLinear domain ${c['domain']} range ${c['range']} at '
                '${inputs[i]}',
          );
          asserted++;
        }
      }
      if (c.containsKey('invert')) {
        final inverted = c['invert']! as List<Object?>;
        final inputs = jsNums(c['invertInputs']).cast<double>();
        for (var i = 0; i < inputs.length; i++) {
          expect(
            s.invert(inputs[i]),
            closeToJs(inverted[i]),
            reason:
                'scaleLinear domain ${c['domain']} range ${c['range']} '
                'invert ${inputs[i]}',
          );
          asserted++;
        }
      }
    }
    // 5 of the 9 corpus cases carry `at`/`invert`; the remaining four only
    // exercise ticks and nice, which belong to `scale_linear.dart`.
    expect(
      asserted,
      60,
      reason: 'every at/invert vector in the scaleLinear section must be read',
    );
  });
}
