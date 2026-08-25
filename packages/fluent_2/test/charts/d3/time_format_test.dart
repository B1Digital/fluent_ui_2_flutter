import 'package:fluent_2/src/charts/internal/d3/time_format.dart' as d3;
import 'package:flutter_test/flutter_test.dart';

import 'golden_support.dart';

void main() {
  final probe = DateTime.utc(2024, 1, 1, 12, 34, 56, 789);

  test('the default locale is en-US with d3\'s exact composites', () {
    expect(
      d3.defaultTimeLocale.dateTime,
      '%x, %X',
      reason: 'd3-time-format/src/defaultLocale.js:10',
    );
    expect(
      d3.defaultTimeLocale.date,
      '%-m/%-d/%Y',
      reason: 'defaultLocale.js:11',
    );
    expect(
      d3.defaultTimeLocale.time,
      '%-I:%M:%S %p',
      reason: 'defaultLocale.js:12',
    );
    expect(d3.defaultTimeLocale.periods, <String>[
      'AM',
      'PM',
    ], reason: 'defaultLocale.js:13');
    expect(
      d3.defaultTimeLocale.shortMonths.first,
      'Jan',
      reason: 'defaultLocale.js:17',
    );
  });

  test('pad modifiers', () {
    expect(d3.utcFormat('%d')(probe), '01', reason: 'default pad is "0"');
    expect(d3.utcFormat('%-d')(probe), '1', reason: 'pads["-"] is ""');
    expect(d3.utcFormat('%_d')(probe), ' 1', reason: 'pads["_"] is a space');
    expect(
      d3.utcFormat('%e')(probe),
      ' 1',
      reason: 'locale.js:57 — "e" defaults to a space pad, not a zero',
    );
    expect(d3.utcFormat('%0e')(probe), '01', reason: 'explicit zero pad');
  });

  test('the recursive composites', () {
    expect(
      d3.utcFormat('%c')(probe),
      '1/1/2024, 12:34:56 PM',
      reason:
          'locale.js:165 defers %c to newFormat(locale.dateTime), which is '
          '"%x, %X" and recurses again',
    );
    expect(d3.utcFormat('%x')(probe), '1/1/2024', reason: 'locale.js:163');
    expect(d3.utcFormat('%X')(probe), '12:34:56 PM', reason: 'locale.js:164');
  });

  test('%Z is +0000 for a UTC formatter regardless of the machine zone', () {
    expect(
      d3.utcFormat('%Z')(probe),
      '+0000',
      reason: 'locale.js:683 formatUTCZone is a constant',
    );
  });

  test('a literal percent and unknown directives', () {
    expect(d3.utcFormat('%%')(probe), '%', reason: 'locale.js:687');
    expect(
      d3.utcFormat('%Ω')(probe),
      'Ω',
      reason:
          'locale.js:58 — an unrecognised directive pushes the character '
          'itself, so the percent silently vanishes',
    );
  });

  test('a custom locale is honoured', () {
    final locale = d3.timeFormatLocale(
      const d3.TimeLocaleDefinition(
        dateTime: '%A %e %B %Y à %X',
        date: '%d/%m/%Y',
        time: '%H:%M:%S',
        periods: <String>['AM', 'PM'],
        days: <String>[
          'dimanche',
          'lundi',
          'mardi',
          'mercredi',
          'jeudi',
          'vendredi',
          'samedi',
        ],
        shortDays: <String>[
          'dim.',
          'lun.',
          'mar.',
          'mer.',
          'jeu.',
          'ven.',
          'sam.',
        ],
        months: <String>[
          'janvier',
          'février',
          'mars',
          'avril',
          'mai',
          'juin',
          'juillet',
          'août',
          'septembre',
          'octobre',
          'novembre',
          'décembre',
        ],
        shortMonths: <String>[
          'janv.',
          'févr.',
          'mars',
          'avr.',
          'mai',
          'juin',
          'juil.',
          'août',
          'sept.',
          'oct.',
          'nov.',
          'déc.',
        ],
      ),
    );
    expect(
      locale.utcFormat('%B')(probe),
      'janvier',
      reason: 'utilities.ts:475 feeds a user TimeLocaleDefinition through here',
    );
    expect(
      locale.utcFormat('%x')(probe),
      '01/01/2024',
      reason: 'the custom date composite',
    );
  });

  test(
    'against the d3 golden corpus — every directive over every probe',
    () async {
      final corpus = await loadD3Golden();
      for (final c in goldenCases(corpus, 'timeFormat')) {
        final specifier = c['specifier']! as String;
        final inputs = (c['inputs']! as List<Object?>).cast<int>();
        final want = (c['utc']! as List<Object?>).cast<String>();
        final f = d3.utcFormat(specifier);
        for (var i = 0; i < inputs.length; i++) {
          final date = DateTime.fromMillisecondsSinceEpoch(
            inputs[i],
            isUtc: true,
          );
          expect(
            f(date),
            want[i],
            reason: 'utcFormat("$specifier") applied to $date',
          );
        }
      }
    },
  );
}
