import 'package:fluent_2/src/charts/internal/d3/interpolate.dart' as d3;
import 'package:flutter_test/flutter_test.dart';

import 'golden_support.dart';

void main() {
  test('interpolateNumber is the exact d3 expression', () {
    final f = d3.interpolateNumber(0, 100);
    expect(f(0), 0.0, reason: 'd3-interpolate/src/number.js:3');
    expect(f(0.5), 50.0, reason: 'a * (1 - t) + b * t');
    expect(f(1), 100.0, reason: 'endpoint');
    expect(
      d3.interpolateNumber(0.1, 0.2)(1 / 3),
      0.1 * (1 - 1 / 3) + 0.2 * (1 / 3),
      reason: 'the form matters: a + t * (b - a) rounds differently',
    );
  });

  test('interpolateRgb emits rgb() strings at gamma 1', () {
    expect(
      d3.interpolateRgb('#000', '#fff')(0.5),
      'rgb(128, 128, 128)',
      reason:
          'rgb.js:6 fixes gamma at 1, so color.js:26-29 uses the linear '
          'branch and clampi rounds 127.5 up to 128',
    );
    expect(
      d3.interpolateRgb('rgba(255,0,0,1)', 'rgba(0,0,255,0)')(0.5),
      'rgba(255, 0, 0, 0.5)',
      // DEVIATION from plan 01 Task 10 Step 1, which expected
      // `rgba(128, 0, 128, 0.5)`. `d3-color/src/color.js:224-227` erases the
      // channels of a fully transparent colour, so the end colour parses as
      // Rgb(NaN, NaN, NaN, 0); each channel's `b - a` is then NaN, which is
      // falsy in JS, so `color.js:28` takes the constant branch and holds the
      // start channel. Only the opacity actually moves. Confirmed against the
      // pinned d3-interpolate 3.0.1 and against the `interpolate` corpus.
      reason: 'the opacity channel interpolates without gamma (rgb.js:13)',
    );
  });

  test('interpolateValue dispatches on the right-hand type', () {
    expect(
      d3.interpolateValue(0, 10)(0.5),
      10 * 0.5,
      reason: 'value.js:14 — a numeric b takes the number branch',
    );
    expect(
      d3.interpolateValue('#000', '#fff')(1),
      'rgb(255, 255, 255)',
      reason: 'value.js:15 — a parseable colour string takes the rgb branch',
    );
  });

  test('against the d3 golden corpus', () async {
    final corpus = await loadD3Golden();
    final cases = goldenCases(corpus, 'interpolate');
    expect(
      cases,
      isNotEmpty,
      reason: 'the corpus must actually have been read',
    );
    for (final c in cases) {
      const ts = <double>[0, 0.25, 0.5, 0.75, 1];
      if (c['kind'] == 'number') {
        final f = d3.interpolateNumber(jsNum(c['a'])!, jsNum(c['b'])!);
        final want = jsNums(c['out']);
        for (var i = 0; i < ts.length; i++) {
          expect(
            f(ts[i]),
            closeToJs(want[i]),
            reason: 'interpolateNumber(${c['a']}, ${c['b']})(${ts[i]})',
          );
        }
      } else {
        final f = d3.interpolateRgb(c['a']! as String, c['b']! as String);
        final want = (c['out']! as List<Object?>).cast<String>();
        for (var i = 0; i < ts.length; i++) {
          expect(
            f(ts[i]),
            want[i],
            reason: 'interpolateRgb("${c['a']}", "${c['b']}")(${ts[i]})',
          );
        }
      }
    }
  });
}
