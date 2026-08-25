import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2/src/charts/internal/plotly/common.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the six dash presets carry their exact stroke arrays', () {
    expect(
      kDashOptions['dashdot']!.strokeDasharray,
      '5, 5, 1, 5',
      reason: 'PlotlySchemaAdapter.ts:156.',
    );
    expect(
      kDashOptions['dot']!.strokeLinecap,
      'round',
      reason: 'PlotlySchemaAdapter.ts:139.',
    );
    expect(
      kDashOptions['solid']!.strokeDasharray,
      '0',
      reason: 'PlotlySchemaAdapter.ts:168.',
    );
    expect(
      kDashOptions.keys,
      <String>['dot', 'dash', 'longdash', 'dashdot', 'longdashdot', 'solid'],
      reason:
          'PlotlySchemaAdapter.ts:136-173 declares exactly these six, in '
          'this order.',
    );
    for (final entry in kDashOptions.entries) {
      expect(
        entry.value.strokeWidth,
        '2',
        reason: 'Every preset sets strokeWidth 2.',
      );
      expect(
        entry.value.lineBorderWidth,
        '4',
        reason: 'Every preset sets lineBorderWidth 4.',
      );
    }
  });

  test('a dash name flows through getLineOptions onto the line', () {
    final options = getLineOptions(<String, Object?>{'dash': 'longdashdot'});
    expect(
      options!.strokeDasharray,
      '10, 5, 1, 5',
      reason:
          'PlotlySchemaAdapter.ts:3338-3340 spreads the preset onto the '
          'options, and :162 is the preset.',
    );
    expect(
      options.strokeLinecap,
      StrokeCap.butt,
      reason: "PlotlySchemaAdapter.ts:163 is 'butt'.",
    );
    expect(
      options.strokeWidth,
      2,
      reason: 'PlotlySchemaAdapter.ts:165 as a number.',
    );
    expect(
      options.lineBorderWidth,
      4,
      reason: 'PlotlySchemaAdapter.ts:164 as a number.',
    );
    expect(
      getLineOptions(<String, Object?>{'dash': 'squiggle'})!.strokeDasharray,
      isNull,
      reason:
          'PlotlySchemaAdapter.ts:3339 spreads `dashOptions[line.dash]`, '
          'which is undefined for an unknown name, and spreading undefined '
          'adds nothing.',
    );
  });

  test('a spline shape becomes a cardinal curve with the smoothing-derived '
      'tension', () {
    final options = getLineOptions(<String, Object?>{'shape': 'spline'});
    expect(
      options!.curve,
      isNotNull,
      reason:
          'PlotlySchemaAdapter.ts:3344-3346 with smoothing defaulting to 1, so '
          'tension is 1 - 1 / 1.3 = 0.23076923076923073.',
    );
    expect(
      options.curve,
      FluentLineCurve.natural,
      reason:
          'FluentLineCurve is frozen contract with five arms and no '
          'tension-carrying cardinal, so the port lands on the nearest smooth '
          'interpolation; see the deviation note on getLineOptions.',
    );
  });

  test('the three step shapes map onto the three step curves', () {
    expect(
      getLineOptions(<String, Object?>{'shape': 'hv'})!.curve,
      FluentLineCurve.stepAfter,
      reason: 'PlotlySchemaAdapter.ts:3348.',
    );
    expect(
      getLineOptions(<String, Object?>{'shape': 'vh'})!.curve,
      FluentLineCurve.stepBefore,
      reason: 'PlotlySchemaAdapter.ts:3351.',
    );
    expect(
      getLineOptions(<String, Object?>{'shape': 'hvh'})!.curve,
      FluentLineCurve.step,
      reason: 'PlotlySchemaAdapter.ts:3354.',
    );
    expect(
      getLineOptions(<String, Object?>{})!.curve,
      FluentLineCurve.linear,
      reason: 'PlotlySchemaAdapter.ts:3357 default branch.',
    );
  });

  test('a null line yields no options at all', () {
    expect(
      getLineOptions(null),
      isNull,
      reason: 'PlotlySchemaAdapter.ts:3333-3335.',
    );
  });

  test('a bare %{text} template with a percent suffix gets one decimal '
      'place', () {
    expect(
      formatTextWithTemplate(0.5, '%{text}%'),
      '0.5%',
      reason:
          'PlotlySchemaAdapter.ts:433-435 uses toFixed(1) when the suffix '
          'starts with %.',
    );
    expect(
      formatTextWithTemplate(3, '%{text} kg'),
      '3 kg',
      reason:
          'PlotlySchemaAdapter.ts:438 interpolates the number itself, and '
          'JavaScript prints an integral double without a fractional part.',
    );
  });

  test('a d3 format specifier is applied and the suffix appended', () {
    expect(
      formatTextWithTemplate(1234.5, r'%{text:,.1f} units'),
      '1,234.5 units',
      reason: 'PlotlySchemaAdapter.ts:441-445.',
    );
  });

  test('an unparseable specifier falls back to the extracted precision', () {
    expect(
      formatTextWithTemplate(0.25, r'%{text:.3f%}'),
      '25.000%',
      reason:
          r'PlotlySchemaAdapter.ts:446-456 extracts precision from '
          r'/\.(\d+)[f%]/ and multiplies by 100 when the spec contains a '
          'percent sign. `.3f%` names two type characters, so the port refuses '
          'it at d3/format_spec.dart:86-89.',
    );
    expect(
      formatTextWithTemplate(0.25, r'%{text:.3zzz%}'),
      '25.00%',
      reason:
          r'PlotlySchemaAdapter.ts:448-449: the precision regex needs a digit '
          r'run followed by f or %, `.3z` supplies neither, so the default 2 '
          'binds.',
    );
    expect(
      formatTextWithTemplate(0.25, r'%{text:zzz}'),
      '0.25',
      reason:
          'PlotlySchemaAdapter.ts:456 is the non-percentage arm of the '
          'same fallback: precision 2 and no suffix.',
    );
  });

  test('a non-numeric value ignores the template entirely', () {
    expect(
      formatTextWithTemplate('abc', r'%{text:.1f}'),
      'abc',
      reason: 'PlotlySchemaAdapter.ts:416-419.',
    );
    expect(
      formatTextWithTemplate('7 apples', r'%{text:.1f}'),
      '7.0',
      reason:
          'PlotlySchemaAdapter.ts:416 uses parseFloat, which keeps the '
          'leading number and drops the rest.',
    );
    expect(
      formatTextWithTemplate(0.5, null),
      '0.5',
      reason: 'PlotlySchemaAdapter.ts:413-415.',
    );
    expect(
      formatTextWithTemplate(0.5, 'no placeholder here'),
      '0.5',
      reason: 'PlotlySchemaAdapter.ts:460 falls out of the match.',
    );
  });

  test(
    'an array template is indexed, and an out-of-range index empties it',
    () {
      expect(
        formatTextWithTemplate(0.5, <String>[
          r'%{text:.0%}',
          r'%{text:.2%}',
        ], 1),
        '50.00%',
        reason: 'PlotlySchemaAdapter.ts:420 picks textTemplate[index].',
      );
      expect(
        formatTextWithTemplate(0.5, <String>[r'%{text:.0%}'], 9),
        '0.5',
        reason:
            "PlotlySchemaAdapter.ts:420 falls back to '' past the end, which "
            'matches nothing and returns the raw value at :460.',
      );
    },
  );

  test('getBarProps clamps an out-of-range bargap to the plotly default', () {
    final props = getBarProps(const <Object?>[], <String, Object?>{
      'bargap': 5,
    });
    expect(
      props.xAxisInnerPadding,
      0.2,
      reason:
          'PlotlySchemaAdapter.ts:3896-3900 clamps to 0.2, plotly.js '
          'layout_defaults.js#L58.',
    );
    expect(
      props.xAxisOuterPadding,
      closeTo(0.1, 1e-12),
      reason: 'PlotlySchemaAdapter.ts:3931 halves the inner padding.',
    );
    expect(props.maxBarWidth, 1000, reason: 'PlotlySchemaAdapter.ts:3930.');
    expect(props.barWidth, 'auto', reason: 'PlotlySchemaAdapter.ts:3929.');
  });

  test('an explicit trace width overrides bargap and clamps to 0..1', () {
    final props = getBarProps(
      <Object?>[
        <String, Object?>{'type': 'bar', 'width': 1.4},
      ],
      <String, Object?>{'bargap': 0.5},
    );
    expect(
      props.xAxisInnerPadding,
      0,
      reason:
          'PlotlySchemaAdapter.ts:3912-3914: padding = clamp(1 - 1.4, 0, '
          '1) = 0.',
    );
  });

  test('an array of widths takes the maximum across every bar trace', () {
    final props = getBarProps(<Object?>[
      <String, Object?>{
        'type': 'bar',
        'width': <Object?>[0.4, 0.6],
      },
      <String, Object?>{'type': 'scatter', 'width': 0.9},
    ], null);
    expect(
      props.xAxisInnerPadding,
      closeTo(0.4, 1e-12),
      reason:
          'PlotlySchemaAdapter.ts:3903-3911 flattens the widths of bar '
          'traces only, so the scatter width is ignored and max is 0.6.',
    );
  });

  test('no bargap and no widths yields an empty props record', () {
    final props = getBarProps(const <Object?>[], null);
    expect(
      props.isEmpty,
      isTrue,
      reason: 'PlotlySchemaAdapter.ts:3917-3919 returns {}.',
    );
  });

  test('the horizontal branch reports a bar-height cap instead', () {
    final props = getBarProps(const <Object?>[], <String, Object?>{
      'bargap': 0.3,
    }, isHorizontal: true);
    expect(
      props.maxBarHeight,
      1000,
      reason: 'PlotlySchemaAdapter.ts:3922-3925.',
    );
    expect(props.yAxisPadding, 0.3, reason: 'PlotlySchemaAdapter.ts:3924.');
    expect(
      props.maxBarWidth,
      isNull,
      reason:
          'PlotlySchemaAdapter.ts:3921-3926 returns the horizontal slice '
          'only.',
    );
  });

  test('getTitles reads the string and object forms of every title', () {
    final plain = getTitles(<String, Object?>{
      'title': 'Sales',
      'xaxis': <String, Object?>{'title': 'Month'},
      'yaxis': <String, Object?>{
        'title': <String, Object?>{'text': 'Revenue'},
      },
    });
    expect(
      plain.chartTitle,
      'Sales',
      reason: 'PlotlySchemaAdapter.ts:177 takes a string title as it stands.',
    );
    expect(
      plain.xAxisTitle,
      'Month',
      reason: 'PlotlySchemaAdapter.ts:193 string form.',
    );
    expect(
      plain.yAxisTitle,
      'Revenue',
      reason: 'PlotlySchemaAdapter.ts:194 object form.',
    );
    expect(
      plain.titleStyle,
      isNull,
      reason:
          'PlotlySchemaAdapter.ts:192 omits titleStyles when the record is '
          'empty, and a string title contributes none of its four members.',
    );

    final empty = getTitles(null);
    expect(
      empty.chartTitle,
      '',
      reason: "PlotlySchemaAdapter.ts:177 falls back to ''.",
    );
    expect(
      empty.xAxisTitle,
      '',
      reason: "PlotlySchemaAdapter.ts:193 falls back to ''.",
    );
  });

  test('getTitles keeps the font and anchors of an object title', () {
    final titles = getTitles(<String, Object?>{
      'title': <String, Object?>{
        'text': 'Sales',
        'font': <String, Object?>{'size': 18},
        'xanchor': 'left',
      },
    });
    expect(
      titles.chartTitle,
      'Sales',
      reason: 'PlotlySchemaAdapter.ts:177 object form.',
    );
    expect(titles.titleStyle!.font, <String, Object?>{
      'size': 18,
    }, reason: 'PlotlySchemaAdapter.ts:178 and :184.');
    expect(
      titles.titleStyle!.xAnchor,
      'left',
      reason: 'PlotlySchemaAdapter.ts:179 and :185.',
    );
    expect(
      titles.titleStyle!.yAnchor,
      isNull,
      reason: 'PlotlySchemaAdapter.ts:186 omits an absent anchor.',
    );
  });

  test('getTitles reads the secondary y-axis title off yaxis2', () {
    expect(
      getTitles(<String, Object?>{
        'yaxis2': <String, Object?>{'title': 'Rate'},
      }).secondaryYAxisTitle,
      'Rate',
      reason: 'PlotlySchemaAdapter.ts:344-346 string form.',
    );
    expect(
      getTitles(<String, Object?>{
        'yaxis2': <String, Object?>{
          'title': <String, Object?>{'text': 'Rate'},
        },
      }).secondaryYAxisTitle,
      'Rate',
      reason: 'PlotlySchemaAdapter.ts:347-348 object form.',
    );
    expect(
      getTitles(<String, Object?>{}).secondaryYAxisTitle,
      isNull,
      reason: 'PlotlySchemaAdapter.ts:349 leaves it undefined.',
    );
  });

  test('correctYearMonth walks backwards and drops a year at each wrap', () {
    final year = DateTime.now().year;
    expect(
      correctYearMonth(<Object?>['Dec', 'Jan', 'Feb']),
      <Object?>['Dec 01, ${year - 1}', 'Jan 01, $year', 'Feb 01, $year'],
      reason:
          'PlotlySchemaAdapter.ts:277-290: December precedes January, so '
          'the earlier entry moves to the previous year while the run that '
          'ascends keeps the present one.',
    );
    expect(
      correctYearMonth(<Object?>['January', 'not a month']),
      <Object?>['January 01, $year', null],
      reason:
          'PlotlySchemaAdapter.ts:269-272 maps an unparseable entry to '
          'null and :291-296 keeps it null.',
    );
    expect(
      () => correctYearMonth(<Object?>[
        <Object?>['Jan'],
      ]),
      throwsA(isA<ArgumentError>()),
      reason: 'PlotlySchemaAdapter.ts:266-268 refuses a 2-D array.',
    );
  });

  // The five `resolveXAxisPoint` assertions that stood here went with the
  // function: it had no caller in lib/ and none upstream either, where
  // `PlotlySchemaAdapter.ts:368` is the only occurrence of the name.

  test('flattenObject joins nested keys with dots and stops at arrays and '
      'dates', () {
    final date = DateTime.utc(2020);
    expect(
      flattenObject(<String, Object?>{
        'a': <String, Object?>{
          'b': 1,
          'c': <String, Object?>{'d': 2},
        },
        'e': <Object?>[1, 2],
        'f': date,
        'g': null,
      }),
      <String, Object?>{
        'a.b': 1,
        'a.c.d': 2,
        'e': <Object?>[1, 2],
        'f': date,
        'g': null,
      },
      reason:
          'PlotlySchemaAdapter.ts:528-533 recurses into plain objects only '
          '— an array, a Date and a null are leaves.',
    );
    expect(
      flattenObject(<String, Object?>{
        'b': <String, Object?>{'c': 1},
      }, 'a'),
      <String, Object?>{'a.b.c': 1},
      reason: 'PlotlySchemaAdapter.ts:525 prefixes the key.',
    );
  });
}
