import 'package:flutter_test/flutter_test.dart';

import 'golden_support.dart';

void main() {
  test('the corpus is present and carries every section the kernel needs',
      () async {
    final corpus = await loadD3Golden();

    expect(
      corpus['meta'],
      isA<Map<String, dynamic>>(),
      reason: 'the corpus records the d3 versions it was generated from',
    );
    final versions = (corpus['meta'] as Map<String, dynamic>)['versions']!
        as Map<String, dynamic>;
    expect(
      versions['d3-array'],
      '3.2.4',
      reason: 'design spec §4.2 pins d3-array at 3.2.4',
    );
    expect(
      versions['d3-scale'],
      '4.0.2',
      reason: 'design spec §4.2 pins d3-scale at 4.0.2',
    );
    expect(
      versions['d3-sankey'],
      '0.12.3',
      reason: 'design spec §4.2 pins d3-sankey at 0.12.3',
    );

    for (final section in <String>[
      'ticks',
      'arrayStats',
      'format',
      'formatSpecifier',
      'precision',
      'color',
      'interpolate',
      'timeInterval',
      'timeTicks',
      'timeFormat',
      'scaleLinear',
      'scaleBand',
      'scaleLog',
      'scaleTime',
      'scaleTickFormat',
      'shape',
      'sankey',
      'bin',
    ]) {
      expect(
        corpus[section],
        isNotNull,
        reason: 'section "$section" must exist — a missing section reads as a '
            'passing test with no assertions',
      );
      expect(
        (corpus[section]! as List<Object?>).length,
        greaterThan(4),
        reason: 'section "$section" must carry more than a token case',
      );
    }
  });

  // Re-enabled by plan 01 Task 14, together with the `SvgPathSink` block in
  // `golden_support.dart`. `PathSink`, `tauEpsilon` and `pathEpsilon` do not
  // exist yet: the corpus lands before the first line of the Dart port
  // (design spec §4.2).
  /*
  test('SvgPathSink emits d3-path syntax', () {
    final sink = SvgPathSink()
      ..moveTo(64.5, 6)
      ..lineTo(680.5, 6)
      ..closePath();
    expect(
      sink.d,
      'M64.5,6L680.5,6Z',
      reason: 'd3-path/src/path.js:34,43,39 emit M/L/Z with no spaces and no '
          'trailing ".0" — Dart prints 6.0 where JS prints 6',
    );
  });
  */

  test('closeToJs treats the JSON NaN sentinel as NaN', () {
    expect(
      double.nan,
      closeToJs('NaN'),
      reason: 'JSON has no NaN literal, so the generator writes the string',
    );
  });
}
