import 'dart:convert';
import 'dart:io';

import 'package:fluent_2_web/src/charts/axis/tick_format.dart';
import 'package:flutter_test/flutter_test.dart';

import '../oracle_b/oracle_b_corpus_test.dart' show corpusDirectory;

/// The SI decades `formatPrefix` can attach, keyed by the suffix character
/// (`d3-format/src/locale.js:134-141` picks one of them). `B` is not a d3
/// prefix: it is the `G` rename applied at `utilities.ts:230-232`, so it maps
/// to the same decade.
const Map<String, double> _siDecades = <String, double>{
  'k': 1e3,
  'M': 1e6,
  'G': 1e9,
  'B': 1e9,
  'T': 1e12,
  'P': 1e15,
};

/// A y-axis tick label that carries an SI prefix, with d3's U+2212 minus.
final RegExp _siLabel = RegExp('^−?[0-9]+(\\.[0-9]+)?[kMGBTP]\$');

/// The numeric value [label] was rendered from, to within the two decimals the
/// `.2~` precision keeps.
double _parseSiLabel(String label) {
  final decade = _siDecades[label.substring(label.length - 1)]!;
  final mantissa = label.substring(0, label.length - 1).replaceFirst('−', '-');
  return double.parse(mantissa) * decade;
}

/// Every distinct SI-prefixed label in the Oracle B corpus, paired with the
/// story it came from so a failure names its fixture.
///
/// `HeatMapChart` is excluded: its in-cell text is `dataPointObject.rectText`
/// (`HeatMapChart.tsx:245`), a string the story supplies, so its `244.0M`
/// carries an untrimmed zero this formatter would never emit. Every other
/// component's numeric SVG text goes through `defaultYAxisTickFormatter` or
/// `formatScientificLimitWidth`.
Map<String, String> _oracleSiLabels() {
  final labels = <String, String>{};
  for (final file in corpusDirectory().listSync().whereType<File>()) {
    if (!file.path.endsWith('.json') || file.path.endsWith('_manifest.json')) {
      continue;
    }
    final story = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    if (story['component'] == 'HeatMapChart') {
      continue;
    }
    for (final svg in (story['svgs'] as List<dynamic>)) {
      final elements =
          (svg as Map<String, dynamic>)['elements'] as List<dynamic>;
      for (final element in elements) {
        final text = ((element as Map<String, dynamic>)['text'] as String?)
            ?.trim();
        if (text != null && _siLabel.hasMatch(text)) {
          labels[text] = story['id'] as String;
        }
      }
    }
  }
  return labels;
}

void main() {
  group('yAxisTickFormatterInternal', () {
    test('uses an SI prefix with two significant decimals', () {
      expect(
        yAxisTickFormatterInternal(1234),
        '1.23k',
        reason:
            "utilities.ts:218 — formatPrefix('.2~', 1234) picks the k prefix.",
      );
    });

    test('drops insignificant trailing zeros', () {
      expect(
        yAxisTickFormatterInternal(25),
        '25',
        reason: "the '~' trim in '.2~f' removes the '.00' (utilities.ts:218).",
      );
      expect(
        yAxisTickFormatterInternal(12.345),
        '12.35',
        reason: 'two decimals, rounded, nothing to trim.',
      );
    });

    test('avoids SI notation below one', () {
      expect(
        yAxisTickFormatterInternal(0.5),
        '0.5',
        reason: "utilities.ts:220-222 switches to '.2~g' when |value| < 1.",
      );
      expect(
        yAxisTickFormatterInternal(0),
        '0',
        reason: 'zero takes the same branch.',
      );
    });

    test('renames giga to billion at 1e9', () {
      expect(
        yAxisTickFormatterInternal(1e9),
        '1B',
        reason: "utilities.ts:230-232 replaces 'G' with 'B' from 1e9 up.",
      );
    });

    test('drops to one decimal when width is limited', () {
      expect(
        yAxisTickFormatterInternal(1234, limitWidth: true),
        '1.2k',
        reason:
            "utilities.ts:223-225 uses '.1~' when limitWidth and |value| >= 1000.",
      );
      expect(
        yAxisTickFormatterInternal(999, limitWidth: true),
        '999',
        reason: 'the limitWidth branch needs |value| >= 1000.',
      );
    });

    test("emits d3's unicode minus, not an ASCII hyphen", () {
      expect(
        yAxisTickFormatterInternal(-0.5),
        '−0.5',
        reason:
            "d3-format 3.x's default locale sets minus to U+2212 "
            '(the cross-plan contract pins it as minusSign).',
      );
    });
  });

  test('defaultYAxisTickFormatter is the unlimited variant', () {
    expect(
      defaultYAxisTickFormatter(1234),
      yAxisTickFormatterInternal(1234),
      reason: 'utilities.ts:242-244 forwards with limitWidth left at false.',
    );
  });

  test('formatScientificLimitWidth is the limited variant', () {
    expect(
      formatScientificLimitWidth(1234),
      yAxisTickFormatterInternal(1234, limitWidth: true),
      reason: 'utilities.ts:1887-1889 forwards with limitWidth true.',
    );
  });

  group('against the Oracle B corpus', () {
    // Every SI label the live React charts rendered is a fixed point of this
    // formatter: feeding the value it encodes back in must reproduce it
    // character for character. That catches a wrong prefix decade, a missing
    // '~' trim, an ASCII hyphen for U+2212, and a mistaken threshold — none of
    // which a self-consistent hand-written expectation would notice.
    final labels = _oracleSiLabels();

    test('offers enough labels to be worth asserting against', () {
      // 116 distinct labels over 28 stories at the time of writing; 100 leaves
      // room for a recapture to drop a story without silently emptying this
      // group.
      expect(
        labels.length,
        greaterThanOrEqualTo(100),
        reason:
            'the corpus should carry the SI labels of 28 axis-bearing stories; '
            'a near-empty map means the text capture or the filter regressed.',
      );
    });

    for (final entry in labels.entries) {
      test('reproduces ${entry.key} from ${entry.value}', () {
        expect(
          defaultYAxisTickFormatter(_parseSiLabel(entry.key)),
          entry.key,
          reason:
              'the live implementation rendered ${entry.key} in '
              '${entry.value}; this port must render it identically.',
        );
      });
    }
  });
}
