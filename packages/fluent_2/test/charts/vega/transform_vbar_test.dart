import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2/src/charts/internal/vega/transform_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FluentVerticalBarChart build(
    List<Object?> values, {
    Map<String, Object?>? colorEncoding,
  }) => transformVegaToVerticalBar(
    <String, Object?>{
      'mark': 'bar',
      'data': <String, Object?>{'values': values},
      'encoding': <String, Object?>{
        'x': <String, Object?>{'field': 'c', 'type': 'nominal'},
        'y': <String, Object?>{'field': 'v', 'type': 'quantitative'},
        // `use_null_aware_elements`, an error in this workspace, rejects the
        // plan's `if (colorEncoding != null)` spelling.
        'color': ?colorEncoding,
      },
    },
    <String, String>{},
    isDark: false,
  );

  List<Object?> categories(int n) => <Object?>[
    for (var i = 0; i < n; i++) <String, Object?>{'c': 'cat$i', 'v': i},
  ];

  test('the injected scalar defaults', () {
    final chart = build(categories(3));
    expect(chart.roundCorners, isTrue, reason: 'ts:2314.');
    expect(chart.props.hideTickOverlap, isTrue, reason: 'ts:2316.');
    expect(
      // `FluentTickLayout` lives on `FluentAxisConfig.tickLayout`
      // (`model/chart_common.dart`, plan 02 task 4). There is no
      // `FluentVerticalBarChart.xAxisTickLayout` and no
      // `FluentCartesianChartProps.tickLayout` — the only route is `props.xAxis`.
      chart.props.xAxis!.tickLayout,
      FluentTickLayout.auto,
      reason: "ts:2318 sets xAxis.tickLayout to 'auto'.",
    );
  });

  test('the truncation ladder has three rungs', () {
    expect(
      chart20(build(categories(21))),
      6,
      reason: 'ts:2305-2306: more than 20 categories.',
    );
    expect(
      chart20(build(categories(15))),
      10,
      reason: 'ts:2305-2306: more than 10 categories.',
    );
    expect(
      chart20(build(categories(5))),
      20,
      reason: 'ts:2306: DEFAULT_TRUNCATE_CHARS.',
    );
  });

  test('a string x wraps its labels, a numeric one does not', () {
    // The plan's Step 1 wrote `build(...).wrapXAxisLables`. There is no such
    // field on `FluentVerticalBarChart`: `wrapXAxisLables` is a
    // `FluentCartesianChartProps` member (`cartesian_chart_props.dart:200`),
    // read by the shell at `cartesian_chart.dart:626` and `:730`.
    expect(
      build(categories(3)).props.wrapXAxisLables,
      isTrue,
      reason: "ts:2315 tests typeof barData[0]?.x === 'string'.",
    );
    // The other half of the title is NOT the numeric x the plan's name implies:
    // `:2278` stringifies a number BEFORE `:2315` reads `barData[0].x`, so a
    // quantitative x wraps too. A `Date` is the value that survives `:2278`
    // unconverted, and it is the only non-empty bar list that answers false.
    expect(
      transformVegaToVerticalBar(
        <String, Object?>{
          'mark': 'bar',
          'data': <String, Object?>{
            'values': <Object?>[
              <String, Object?>{'c': DateTime.utc(2024), 'v': 1},
            ],
          },
          'encoding': <String, Object?>{
            'x': <String, Object?>{'field': 'c', 'type': 'temporal'},
            'y': <String, Object?>{'field': 'v', 'type': 'quantitative'},
          },
        },
        <String, String>{},
        isDark: false,
      ).props.wrapXAxisLables,
      isFalse,
      reason: 'ts:2315: a Date x is not a string, so the labels do not wrap.',
    );
  });

  test(
    'with no colour field the legend is hidden and every bar is labelled Bar',
    () {
      final chart = build(categories(3));
      expect(
        chart.props.hideLegend,
        isTrue,
        reason: 'ts:2325 hides the legend when no colour field exists.',
      );
      expect(
        chart.data.first.legend,
        'Bar',
        reason: "ts:2185, :2258 use the literal string 'Bar'.",
      );
    },
  );

  test(
    'a colour field un-hides the legend unless the encoding disables it',
    () {
      final coloured = build(
        <Object?>[
          <String, Object?>{'c': 'a', 'v': 1, 'g': 'north'},
          <String, Object?>{'c': 'b', 'v': 2, 'g': 'south'},
        ],
        colorEncoding: <String, Object?>{'field': 'g', 'type': 'nominal'},
      );
      expect(
        coloured.props.hideLegend,
        isFalse,
        reason:
            'ts:2325: `!colorField` is false, and `legend.disable` is absent.',
      );
      expect(
        coloured.data.map((d) => d.legend).toList(),
        <String>['north', 'south'],
        reason: 'ts:2254-2256 takes the legend from the colour column.',
      );
      expect(
        build(
          <Object?>[
            <String, Object?>{'c': 'a', 'v': 1, 'g': 'north'},
          ],
          colorEncoding: <String, Object?>{
            'field': 'g',
            'type': 'nominal',
            'legend': <String, Object?>{'disable': true},
          },
        ).props.hideLegend,
        isTrue,
        reason: 'ts:2325: `encoding.color?.legend?.disable ?? false`.',
      );
    },
  );

  test('a numeric x is stringified to force categorical positioning', () {
    final chart = transformVegaToVerticalBar(
      <String, Object?>{
        'mark': 'bar',
        'data': <String, Object?>{
          'values': <Object?>[
            <String, Object?>{'c': 2020, 'v': 1},
            <String, Object?>{'c': 2021, 'v': 2},
          ],
        },
        'encoding': <String, Object?>{
          'x': <String, Object?>{'field': 'c', 'type': 'quantitative'},
          'y': <String, Object?>{'field': 'v', 'type': 'quantitative'},
        },
      },
      <String, String>{},
      isDark: false,
    );
    expect(
      chart.data.first.x,
      '2020',
      reason:
          'ts:2278 stringifies a numeric x so the bar chart lays it out as a '
          'band.',
    );
  });

  test('a non-numeric y silently falls back to a per-category count', () {
    final chart = transformVegaToVerticalBar(
      <String, Object?>{
        'mark': 'bar',
        'data': <String, Object?>{
          'values': <Object?>[
            <String, Object?>{'c': 'a', 'v': 'x'},
            <String, Object?>{'c': 'a', 'v': 'y'},
            <String, Object?>{'c': 'b', 'v': 'z'},
          ],
        },
        'encoding': <String, Object?>{
          'x': <String, Object?>{'field': 'c', 'type': 'nominal'},
          'y': <String, Object?>{'field': 'v', 'type': 'quantitative'},
        },
      },
      <String, String>{},
      isDark: false,
    );
    expect(
      chart.data.map((d) => d.y).toList(),
      <double>[2, 1],
      reason:
          'ts:2214-2235 counts rows per category rather than failing. '
          '// parity',
    );
    expect(
      chart.data.map((d) => d.legend).toList(),
      <String>['a', 'b'],
      reason:
          "ts:2220 makes the x value the legend on this branch, not 'Bar' — "
          'the one place the two branches disagree.',
    );
  });

  test('a y aggregate takes the aggregate branch', () {
    final chart = transformVegaToVerticalBar(
      <String, Object?>{
        'mark': 'bar',
        'data': <String, Object?>{
          'values': <Object?>[
            <String, Object?>{'c': 'a', 'v': 1},
            <String, Object?>{'c': 'a', 'v': 3},
            <String, Object?>{'c': 'b', 'v': 10},
          ],
        },
        'encoding': <String, Object?>{
          'x': <String, Object?>{'field': 'c', 'type': 'nominal'},
          'y': <String, Object?>{
            'field': 'v',
            'type': 'quantitative',
            'aggregate': 'sum',
          },
        },
      },
      <String, String>{},
      isDark: false,
    );
    expect(
      chart.data.map((d) => d.y).toList(),
      <double>[4, 10],
      reason: 'ts:2162-2163 sums per category before any bar is built.',
    );
    expect(
      chart.data.map((d) => d.legend).toList(),
      <String>['Bar', 'Bar'],
      reason:
          'ts:2185: with no colour field the aggregate branch labels every bar '
          "'Bar', so the whole series shares one colour.",
    );
  });

  test('an x encoding is required unless the y channel aggregates', () {
    expect(
      () => transformVegaToVerticalBar(
        <String, Object?>{
          'mark': 'bar',
          'data': <String, Object?>{
            'values': <Object?>[
              <String, Object?>{'v': 1},
            ],
          },
          'encoding': <String, Object?>{
            'y': <String, Object?>{'field': 'v', 'type': 'quantitative'},
          },
        },
        <String, String>{},
        isDark: false,
      ),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('x encoding is required for bar charts'),
        ),
      ),
      reason: 'ts:2156-2158, message verbatim.',
    );
  });

  test('the titles, tick config and y bounds reach the props', () {
    final chart = transformVegaToVerticalBar(
      <String, Object?>{
        'mark': 'bar',
        'title': 'Sales',
        'data': <String, Object?>{
          'values': <Object?>[
            <String, Object?>{'c': 'a', 'v': 1},
          ],
        },
        'encoding': <String, Object?>{
          'x': <String, Object?>{
            'field': 'c',
            'type': 'nominal',
            'title': 'Category',
            'axis': <String, Object?>{'tickCount': 3},
          },
          'y': <String, Object?>{
            'field': 'v',
            'type': 'quantitative',
            'title': 'Value',
            'scale': <String, Object?>{
              'domain': <Object?>[2, 10],
              'type': 'log',
            },
            'axis': <String, Object?>{'format': '.2f'},
          },
        },
      },
      <String, String>{},
      isDark: false,
    );
    expect(chart.chartTitle, 'Sales', reason: 'ts:2310.');
    expect(chart.props.xAxisTitle, 'Category', reason: 'ts:2311.');
    expect(chart.props.yAxisTitle, 'Value', reason: 'ts:2312.');
    expect(chart.props.xAxisTickCount, 3, reason: 'ts:2332-2333.');
    expect(chart.props.yMinValue, 2, reason: 'ts:2320.');
    expect(chart.props.yMaxValue, 10, reason: 'ts:2321.');
    expect(chart.props.yScaleType, FluentAxisScaleType.log, reason: 'ts:2322.');
    expect(
      chart.props.yAxisTickFormat!(1.5),
      '1.50',
      reason:
          'ts:2319 spreads the d3 format SPEC; the port stores the resolved '
          'formatter, because `FluentCartesianChartProps.yAxisTickFormat` is '
          '`String Function(double)`.',
    );
    expect(
      chart.data.first.barLabel,
      '1.00',
      reason: 'ts:2285 labels the bar with the same formatter.',
    );
    expect(
      chart.data.first.yAxisCalloutData,
      '1.00',
      reason: 'ts:2285 sets the callout reading from it too.',
    );
  });

  test('a sort on x reaches the chart, not the props bag', () {
    final chart = transformVegaToVerticalBar(
      <String, Object?>{
        'mark': 'bar',
        'data': <String, Object?>{
          'values': <Object?>[
            <String, Object?>{'c': 'a', 'v': 1},
          ],
        },
        'encoding': <String, Object?>{
          'x': <String, Object?>{
            'field': 'c',
            'type': 'nominal',
            'sort': 'descending',
          },
          'y': <String, Object?>{'field': 'v', 'type': 'quantitative'},
        },
      },
      <String, String>{},
      isDark: false,
    );
    expect(
      chart.xAxisCategoryOrder,
      FluentAxisCategoryOrder.categoryDescending,
      reason:
          'ts:2323 spreads the order into the props object; in this port only '
          'the WIDGET field is read (`vertical_bar_chart.dart:216`).',
    );
  });

  test('an invalid row is dropped rather than plotted', () {
    final chart = transformVegaToVerticalBar(
      <String, Object?>{
        'mark': 'bar',
        'data': <String, Object?>{
          'values': <Object?>[
            <String, Object?>{'c': 'a', 'v': 1},
            <String, Object?>{'c': null, 'v': 2},
            <String, Object?>{'c': 'c', 'v': null},
          ],
        },
        'encoding': <String, Object?>{
          'x': <String, Object?>{'field': 'c', 'type': 'nominal'},
          'y': <String, Object?>{'field': 'v', 'type': 'quantitative'},
        },
      },
      <String, String>{},
      isDark: false,
    );
    expect(
      chart.data.map((d) => d.x).toList(),
      <String>['a'],
      reason: 'ts:2250-2252 skips a row whose x or y is invalid.',
    );
  });
}

int chart20(FluentVerticalBarChart chart) => chart.props.noOfCharsToTruncate;
