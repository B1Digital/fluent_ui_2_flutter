import 'package:fluent_2_web/src/charts/axis/tick_format.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/oracle_fixture.dart';

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
  for (final id in oracleStoryIds()) {
    final story = loadOracleStory(id);
    if (story.component == 'HeatMapChart') {
      continue;
    }
    for (final svg in story.svgs) {
      for (final element in svg.elements) {
        final text = element.text?.trim();
        if (text != null && _siLabel.hasMatch(text)) {
          labels[text] = story.id;
        }
      }
    }
  }
  return labels;
}

/// A tick label rendered from the abbreviated-month plus two-digit-day bag,
/// which is `D_W` at `chart-utilities/formatter.ts:235-239`.
final RegExp _shortMonthDayLabel = RegExp(r'^[A-Z][a-z]{2} [0-9]{2}$');

/// Every distinct `MMM dd` tick label in the Oracle B corpus, paired with the
/// story it came from so a failure names its fixture.
///
/// These are what the live React charts put on a date x-axis once
/// `createDateXAxis` (`utilities.ts:515`) has picked the `D_W` bag, so they
/// pin the field order and the zero padding that
/// [FluentDateTimeFormatOptions.pattern] has to reproduce — a self-consistent
/// `04 Mar` or `Mar 4` would satisfy a hand-written expectation but not these.
Map<String, String> _oracleShortMonthDayLabels() {
  final labels = <String, String>{};
  for (final id in oracleStoryIds()) {
    final story = loadOracleStory(id);
    for (final svg in story.svgs) {
      for (final element in svg.elements) {
        final text = element.text?.trim();
        if (text != null && _shortMonthDayLabel.hasMatch(text)) {
          labels[text] = story.id;
        }
      }
    }
  }
  return labels;
}

/// The month number [label]'s abbreviation stands for, using the same
/// abbreviations `package:intl`'s en-US symbols do.
int _monthOf(String label) =>
    const <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ].indexOf(label.substring(0, 3)) +
    1;

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

  group('formatToLocaleString', () {
    test('does not group below ten thousand', () {
      expect(
        formatToLocaleString(1234, culture: 'en_US'),
        '1234',
        reason:
            'chart-utilities/formatter.ts:39 — useGrouping is |data| >= 10000, '
            'not >= 1000.',
      );
    });

    test('groups from ten thousand up', () {
      expect(
        formatToLocaleString(12345, culture: 'en_US'),
        '12,345',
        reason: 'formatter.ts:39-40.',
      );
    });

    test('snaps a floating-point artefact before formatting', () {
      expect(
        formatToLocaleString(2.9999999, culture: 'en_US'),
        '3',
        reason:
            'formatter.ts:40 routes through handleFloatingPointPrecisionError.',
      );
    });

    test('formats a numeric string like a number', () {
      expect(
        formatToLocaleString('12345', culture: 'en_US'),
        '12,345',
        reason: 'formatter.ts:41-45 parses a numeric string first.',
      );
    });

    test('passes an empty string, null and NaN straight through', () {
      expect(formatToLocaleString(''), '', reason: 'formatter.ts:35.');
      expect(
        formatToLocaleString(null),
        '',
        reason: 'null renders as nothing.',
      );
      expect(
        formatToLocaleString(double.nan),
        'NaN',
        reason: 'formatter.ts:35 returns NaN unchanged.',
      );
    });

    test('leaves a non-numeric string alone', () {
      expect(
        formatToLocaleString('Monday'),
        'Monday',
        reason: 'formatter.ts:49 returns the data unchanged.',
      );
    });
  });

  group('formatDateToLocaleString', () {
    test('uses the default option bag when none is supplied', () {
      expect(
        formatDateToLocaleString(
          DateTime.utc(2020, 3, 4, 5, 6, 7),
          culture: 'en_US',
          useUtc: true,
          showTZname: false,
        ),
        '03/04/2020, 05:06:07 AM',
        reason:
            'formatter.ts:53-62 — DEFAULT_DATE_TIME_FORMAT_OPTION is numeric '
            'year, 2-digit month/day/hour/minute/second, hour12 true.',
      );
    });

    test('honours a supplied option bag', () {
      expect(
        formatDateToLocaleString(
          DateTime.utc(2020, 3, 4),
          culture: 'en_US',
          useUtc: true,
          showTZname: false,
          options: const FluentDateTimeFormatOptions(
            month: FluentDateTimeField.short,
            day: FluentDateTimeField.twoDigit,
          ),
        ),
        'Mar 04',
        reason:
            'formatter.ts:235-239 — the D_W bag is month short plus 2-digit '
            'day.',
      );
    });

    test('appends a short zone name when asked', () {
      expect(
        formatDateToLocaleString(
          DateTime.utc(2020, 3, 4),
          culture: 'en_US',
          useUtc: true,
          options: const FluentDateTimeFormatOptions(
            year: FluentDateTimeField.numeric,
          ),
        ),
        '2020 UTC',
        reason:
            'formatter.ts:89-91 adds timeZoneName short; createDateXAxis:515 is '
            'the one caller that passes false.',
      );
    });
  });

  group('formatDateToLocaleString against the Oracle B corpus', () {
    final labels = _oracleShortMonthDayLabels();

    test('offers enough labels to be worth asserting against', () {
      // 11 distinct labels over charts-linechart--line-chart-gaps and
      // charts-scatterchart--scatter-chart-date at the time of writing; 10
      // leaves room for a recapture to shift one tick without silently
      // emptying this group.
      expect(
        labels.length,
        greaterThanOrEqualTo(10),
        reason:
            'the corpus should carry the date-axis tick labels of the two '
            'date-scaled stories; a near-empty map means the text capture or '
            'the filter regressed.',
      );
    });

    for (final entry in labels.entries) {
      test('reproduces ${entry.key} from ${entry.value}', () {
        // The year is not recoverable from a 'MMM dd' label and does not reach
        // the output, so 2020 stands in; it is a leap year, which keeps a
        // captured 'Feb 29' constructible.
        expect(
          formatDateToLocaleString(
            DateTime.utc(
              2020,
              _monthOf(entry.key),
              int.parse(entry.key.substring(4)),
            ),
            culture: 'en_US',
            useUtc: true,
            showTZname: false,
            options: const FluentDateTimeFormatOptions(
              month: FluentDateTimeField.short,
              day: FluentDateTimeField.twoDigit,
            ),
          ),
          entry.key,
          reason:
              'the live implementation rendered ${entry.key} in '
              '${entry.value}; this port must render it identically.',
        );
      });
    }
  });

  group('getDateFormatLevel', () {
    test('is 7 for a year boundary', () {
      expect(
        getDateFormatLevel(DateTime.utc(2020), useUtc: true),
        7,
        reason:
            'utilities.ts:427 — nothing floors below it, so the default '
            'wins.',
      );
    });

    test('is 6 for a month boundary inside a year', () {
      expect(
        getDateFormatLevel(DateTime.utc(2020, 3), useUtc: true),
        6,
        reason: 'utilities.ts:426 — timeYear(d) < d but timeMonth(d) == d.',
      );
    });

    test('is 5 for a week boundary that is not a month boundary', () {
      expect(
        getDateFormatLevel(DateTime.utc(2020, 1, 12), useUtc: true),
        5,
        reason:
            '2020-01-12 is a Sunday, so timeWeek(d) == d and the day rule at '
            'utilities.ts:424 fails while the week rule at :425 passes.',
      );
    });

    test('is 4 for a mid-week day', () {
      expect(
        getDateFormatLevel(DateTime.utc(2020, 1, 15), useUtc: true),
        4,
        reason: 'utilities.ts:424 — both timeMonth(d) < d and timeWeek(d) < d.',
      );
    });

    test('is 3 for a whole hour inside a day', () {
      expect(
        getDateFormatLevel(DateTime.utc(2020, 1, 15, 10), useUtc: true),
        3,
        reason: 'utilities.ts:423 — timeDay(d) < d, and the finer rules fail.',
      );
    });

    test('is 2 for a whole minute inside an hour', () {
      expect(
        getDateFormatLevel(DateTime.utc(2020, 1, 1, 10, 30), useUtc: true),
        2,
        reason: 'utilities.ts:422 — timeHour(d) < d, and the finer rules fail.',
      );
    });

    test('is 1 for a whole second inside a minute', () {
      expect(
        getDateFormatLevel(DateTime.utc(2020, 1, 1, 10, 30, 15), useUtc: true),
        1,
        reason: 'utilities.ts:421 — timeMinute(d) < d, and :420 fails.',
      );
    });

    test('is 0 for a sub-second instant', () {
      expect(
        getDateFormatLevel(
          DateTime.utc(2020, 1, 1, 0, 0, 0, 250),
          useUtc: true,
        ),
        0,
        reason: 'utilities.ts:420 — timeSecond(d) < d.',
      );
    });

    test('reads the local intervals when useUtc is false', () {
      // A local midnight is a day boundary in local time whatever the zone, so
      // this holds without pinning the test host's zone. Only the day rule and
      // coarser can fire, so anything above 3 proves the local branch of
      // utilities.ts:411-417 was taken rather than the UTC one, which would see
      // a non-zero UTC hour in every zone but UTC itself.
      final local = DateTime(2020, 1, 15);
      expect(
        getDateFormatLevel(local),
        greaterThan(3),
        reason:
            'utilities.ts:411-417 selects the local intervals when useUTC is '
            'falsy, and local midnight floors to itself under timeDay.',
      );
    });
  });

  group('multiLevelD3DateFormat', () {
    test('returns the millisecond format on the diagonal', () {
      expect(
        multiLevelD3DateFormat(0, 0),
        '.%L',
        reason: 'utilities.ts:357 — MS.',
      );
    });

    test('returns the day format on the diagonal', () {
      expect(
        multiLevelD3DateFormat(4, 4),
        '%a %d',
        reason: 'utilities.ts:383 — D.',
      );
    });

    test('spans days to years with the locale date', () {
      expect(
        multiLevelD3DateFormat(4, 7),
        '%x',
        reason: 'utilities.ts:386 — D_W_M_Y.',
      );
    });

    test('spans minutes to years with date plus 12-hour time', () {
      expect(
        multiLevelD3DateFormat(2, 7),
        '%x, %-I:%M %p',
        reason: 'utilities.ts:377 — MIN_H_D_W_M_Y.',
      );
    });

    test('returns the year format at the far corner', () {
      expect(
        multiLevelD3DateFormat(7, 7),
        '%Y',
        reason: 'utilities.ts:392 — Y.',
      );
    });

    test('falls back to %c below the diagonal', () {
      expect(
        multiLevelD3DateFormat(5, 4),
        '%c',
        reason:
            'utilities.ts:395-403 — every cell left of the diagonal is DEFAULT.',
      );
    });

    test('is total over every level pair', () {
      var cells = 0;
      for (var start = 0; start < 8; start++) {
        for (var end = 0; end < 8; end++) {
          expect(
            multiLevelD3DateFormat(start, end),
            isNotEmpty,
            reason:
                'utilities.ts:394-404 fills all 64 cells, so no lookup may '
                'return an empty specifier.',
          );
          cells++;
        }
      }
      expect(
        cells,
        64,
        reason: 'the 8x8 table at utilities.ts:394-404 has 64 cells.',
      );
    });
  });

  group('multiLevelDateTimeFormatOptions', () {
    test('returns the default bag when the start level is missing', () {
      expect(
        multiLevelDateTimeFormatOptions(null, 3).pattern,
        kDefaultDateTimeFormatOptions.pattern,
        reason:
            'chart-utilities/formatter.ts:280-282 guards an absent start '
            'level.',
      );
    });

    test('returns the default bag when the start level is out of range', () {
      expect(
        multiLevelDateTimeFormatOptions(8, 8).pattern,
        kDefaultDateTimeFormatOptions.pattern,
        reason: 'formatter.ts:280-282 also guards startLevel >= 8.',
      );
    });

    test('collapses to the diagonal when the end level is lower', () {
      expect(
        multiLevelDateTimeFormatOptions(2, 1).pattern,
        multiLevelDateTimeFormatOptions(2, 2).pattern,
        reason: 'formatter.ts:284-286 falls back to [startLevel][startLevel].',
      );
    });

    test('clamps an end level past the table to the last column', () {
      expect(
        multiLevelDateTimeFormatOptions(2, 99).pattern,
        multiLevelDateTimeFormatOptions(2, 7).pattern,
        reason: 'formatter.ts:288-290 clamps to the final column.',
      );
    });

    test('gives the day cell month-short plus two-digit day', () {
      final bag = multiLevelDateTimeFormatOptions(4, 5);
      expect(
        bag.month,
        FluentDateTimeField.short,
        reason: 'formatter.ts:237 — D_W is month short.',
      );
      expect(
        bag.day,
        FluentDateTimeField.twoDigit,
        reason: "formatter.ts:238 — D_W is day '2-digit'.",
      );
      expect(bag.year, isNull, reason: 'D_W carries no year.');
    });

    test('gives the month cell a long month name', () {
      expect(
        multiLevelDateTimeFormatOptions(6, 6).month,
        FluentDateTimeField.long,
        reason: "formatter.ts:252-255 — M is month 'long'.",
      );
    });
  });

  group('multiLevelDateTimeFormatOptions against the Oracle B corpus', () {
    // The day-to-week cell is the one this table hands createDateXAxis for the
    // date-scaled stories (utilities.ts:515 formats each tick with the bag),
    // so the labels the live React charts actually rendered pin it. A wrong
    // cell — the weekday-bearing D at [4][4], say, or the slash-joined
    // D_W_M_Y at [4][7] — would still satisfy a hand-written expectation.
    final labels = _oracleShortMonthDayLabels();

    test('offers enough labels to be worth asserting against', () {
      // 10 leaves room for a recapture to shift one tick without silently
      // emptying this group; see the count guard on the formatDateToLocaleString
      // corpus group above for the figure at the time of writing.
      expect(
        labels.length,
        greaterThanOrEqualTo(10),
        reason:
            'the corpus should carry the date-axis tick labels of the two '
            'date-scaled stories; a near-empty map means the text capture or '
            'the filter regressed.',
      );
    });

    for (final entry in labels.entries) {
      test('the [4][5] cell reproduces ${entry.key} from ${entry.value}', () {
        // As above, the year does not reach the output, so the leap year 2020
        // stands in and keeps a captured 'Feb 29' constructible.
        expect(
          formatDateToLocaleString(
            DateTime.utc(
              2020,
              _monthOf(entry.key),
              int.parse(entry.key.substring(4)),
            ),
            culture: 'en_US',
            useUtc: true,
            showTZname: false,
            options: multiLevelDateTimeFormatOptions(4, 5),
          ),
          entry.key,
          reason:
              'the live implementation rendered ${entry.key} in '
              '${entry.value}; the bag this table returns for a day-to-week '
              'tick span must render it identically.',
        );
      });
    }
  });
}
