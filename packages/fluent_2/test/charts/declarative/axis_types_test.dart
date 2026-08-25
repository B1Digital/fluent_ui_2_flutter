import 'package:fluent_2/src/charts/internal/plotly/axis.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a bare trace anchors to xaxis and yaxis', () {
    final axes = getAxisObjects(<Object?>[
      <String, Object?>{
        'type': 'scatter',
        'x': <Object?>[1],
        'y': <Object?>[2],
      },
    ], null);
    expect(
      axes.map((a) => a.key).toSet(),
      <String>{'xaxis', 'yaxis'},
      reason:
          'PlotlySchemaAdapter.ts:4107-4139 defaults a trace to axis 1 on both '
          'letters.',
    );
  });

  test('a secondary y axis is collected under yaxis2', () {
    final axes = getAxisObjects(
      <Object?>[
        <String, Object?>{
          'type': 'scatter',
          'yaxis': 'y2',
          'x': <Object?>[1],
          'y': <Object?>[2],
        },
      ],
      <String, Object?>{
        'yaxis2': <String, Object?>{'side': 'right'},
      },
    );
    expect(
      axes.any((a) => a.key == 'yaxis2'),
      isTrue,
      reason:
          'PlotlySchemaAdapter.ts:4130 sorts the collected y ids so yaxis2 is '
          'kept distinct.',
    );
  });

  test('a declared layout axis type wins over inference', () {
    final axes = getAxisObjects(
      <Object?>[
        <String, Object?>{
          'type': 'bar',
          'x': <Object?>[1, 2],
          'y': <Object?>[1, 2],
        },
      ],
      <String, Object?>{
        'xaxis': <String, Object?>{'type': 'category'},
      },
    );
    final x = axes.firstWhere((a) => a.key == 'xaxis');
    expect(
      getAxisType(<Object?>[
        <String, Object?>{
          'type': 'bar',
          'x': <Object?>[1, 2],
          'y': <Object?>[1, 2],
        },
      ], x),
      FluentPlotlyAxisType.category,
      reason:
          'PlotlySchemaAdapter.ts:4146-4148 returns the declared type '
          'unchanged.',
    );
  });

  test('an inferred date axis is recognised from the data', () {
    final axes = getAxisObjects(<Object?>[
      <String, Object?>{
        'type': 'scatter',
        'x': <Object?>['2024-01-01', '2024-02-01'],
        'y': <Object?>[1, 2],
      },
    ], null);
    final x = axes.firstWhere((a) => a.key == 'xaxis');
    expect(
      getAxisType(<Object?>[
        <String, Object?>{
          'type': 'scatter',
          'x': <Object?>['2024-01-01', '2024-02-01'],
          'y': <Object?>[1, 2],
        },
      ], x),
      FluentPlotlyAxisType.date,
      reason:
          'PlotlySchemaAdapter.ts:4166-4168 infers date from isDateArray, '
          'after the numeric arm at :4163-4165 has declined.',
    );
  });

  test('a missing axis object reads as a category axis', () {
    expect(
      getAxisType(const <Object?>[], null),
      FluentPlotlyAxisType.category,
      reason:
          'PlotlySchemaAdapter.ts:4142-4144 guards a falsy ax before touching '
          'ax.type, which getAxisObjects can produce for an empty group.',
    );
  });

  test('an ISO date without a timezone parses as local, not UTC', () {
    final parsed = parseLocalDate('2024-03-05');
    expect(
      parsed!.isUtc,
      isFalse,
      reason:
          'PlotlySchemaAdapter.ts:4220-4232 constructs a local Date from the '
          'ISO components, which is why the adapters pass useUTC: false '
          '(PlotlySchemaAdapter.ts:2175).',
    );
    expect(parsed.year, 2024, reason: 'Year component.');
    expect(parsed.month, 3, reason: 'Month component, one-based in Dart.');
    expect(parsed.day, 5, reason: 'Day component.');
  });

  test('a trailing Z is stripped so the instant is read as local', () {
    expect(
      isoDateRegex.firstMatch('2024-03-05T00:00:00Z')?.group(6),
      'Z',
      reason:
          'PlotlySchemaAdapter.ts:4209 admits the Z suffix as group 6 of '
          'isoDateRegex, which is what :4226 tests.',
    );
    expect(
      parseLocalDate('2024-03-05T00:00:00Z')!.isUtc,
      isFalse,
      reason:
          'PlotlySchemaAdapter.ts:4226-4227 replaces the Z before calling new '
          'Date, so the instant is local. This is the whole purpose of '
          'parseLocalDate: the formatters run with useUTC false '
          '(PlotlySchemaAdapter.ts:2175). The plan Step 1 test asserted isUtc '
          'isTrue, which is neither upstream nor the plan Step 3 code.',
    );
  });

  test(
    'the linear resolver coerces numeric strings and passes numbers through',
    () {
      final resolve = getAxisValueResolver(FluentPlotlyAxisType.linear);
      expect(
        resolve('12.5'),
        12.5,
        reason: 'PlotlySchemaAdapter.ts:4184-4186 linear branch.',
      );
      expect(
        resolve(7),
        7.0,
        reason:
            'PlotlySchemaAdapter.ts:4186 unary + on a number is the number, so '
            'the value survives unchanged.',
      );
      expect(
        resolve('abc'),
        isNull,
        reason: 'A non-numeric value on a linear axis is dropped.',
      );
    },
  );

  test('the log resolver shares the linear arm', () {
    expect(
      getAxisValueResolver(FluentPlotlyAxisType.log)('12.5'),
      12.5,
      reason:
          'PlotlySchemaAdapter.ts:4184-4186 falls through from log into the '
          'linear case, so the two coerce identically.',
    );
  });

  test('the category resolver stringifies everything', () {
    final resolve = getAxisValueResolver(FluentPlotlyAxisType.category);
    expect(
      resolve(3),
      '3',
      reason: 'PlotlySchemaAdapter.ts:4197-4198 category branch.',
    );
  });

  test('the multicategory resolver drops every value', () {
    expect(
      getAxisValueResolver(FluentPlotlyAxisType.multicategory)('a'),
      isNull,
      reason:
          'PlotlySchemaAdapter.ts:4200-4201, the default arm of the switch, '
          'which multicategory is the only declared type to reach.',
    );
  });

  test('a date axis without a date parser reads a date-only string as UTC', () {
    final resolved = getAxisValueResolver(FluentPlotlyAxisType.date)(
      '2024-03-05',
    );
    expect(
      (resolved! as DateTime).isUtc,
      isTrue,
      reason:
          'PlotlySchemaAdapter.ts:4174 falls back to bare new Date when no '
          'dateParser is given (the call sites at :1405, :2003 and :3186), and '
          'JavaScript reads a date-only ISO string as UTC midnight.',
    );
  });

  test('a date axis given parseLocalDate reads the same string as local', () {
    final resolved = getAxisValueResolver(
      FluentPlotlyAxisType.date,
      dateParser: parseLocalDate,
    )('2024-03-05');
    expect(
      (resolved! as DateTime).isUtc,
      isFalse,
      reason:
          'PlotlySchemaAdapter.ts:2307 is the one call site that passes '
          'parseLocalDate, and :4224-4225 appends T00:00 so the instant is '
          'local — the divergence from the bare new Date path is load-bearing.',
    );
  });

  test('a date axis resolves a number as milliseconds since the epoch', () {
    final resolved = getAxisValueResolver(FluentPlotlyAxisType.date)(0);
    expect(
      (resolved! as DateTime).millisecondsSinceEpoch,
      0,
      reason:
          'PlotlySchemaAdapter.ts:4189-4190 passes +value to new Date, which '
          'reads a number as epoch milliseconds.',
    );
  });

  test('an invalid value is dropped on every axis type', () {
    for (final type in FluentPlotlyAxisType.values) {
      expect(
        getAxisValueResolver(type)(null),
        isNull,
        reason:
            'PlotlySchemaAdapter.ts:4179-4181 returns null for an invalid '
            'value before the switch on $type is reached.',
      );
    }
  });
}
