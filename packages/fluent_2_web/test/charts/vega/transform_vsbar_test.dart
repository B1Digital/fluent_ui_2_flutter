import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:fluent_2_web/src/charts/internal/vega/transform_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FluentVerticalStackedBarChart build(Map<String, Object?> spec) =>
      transformVegaToStackedBar(spec, <String, String>{}, isDark: false);

  final stacked = <String, Object?>{
    'mark': 'bar',
    'data': <String, Object?>{
      'values': <Object?>[
        <String, Object?>{'c': 'a', 'g': 'p', 'v': 1},
        <String, Object?>{'c': 'a', 'g': 'q', 'v': 2},
        <String, Object?>{'c': 'b', 'g': 'p', 'v': 3},
      ],
    },
    'encoding': <String, Object?>{
      'x': <String, Object?>{'field': 'c', 'type': 'nominal'},
      'y': <String, Object?>{'field': 'v', 'type': 'quantitative'},
      'color': <String, Object?>{'field': 'g', 'type': 'nominal'},
    },
  };

  test('the injected scalar defaults', () {
    final chart = build(stacked);
    expect(chart.roundCorners, isTrue, reason: 'ts:2715.');
    expect(chart.barGapMax, 2, reason: 'ts:2717.');
    expect(chart.props.showYAxisLables, isTrue, reason: 'ts:2714.');
    expect(chart.props.hideTickOverlap, isTrue, reason: 'ts:2716.');
    expect(chart.props.noOfCharsToTruncate, 20, reason: 'ts:2718.');
    expect(chart.props.showYAxisLablesTooltip, isTrue, reason: 'ts:2719.');
    expect(
      chart.props.wrapXAxisLables,
      isTrue,
      reason: 'ts:2720; xAxisPoint is a String here.',
    );
    expect(
      chart.props.xAxis!.tickLayout,
      FluentTickLayout.auto,
      reason: 'ts:2721.',
    );
  });

  test(
    'the stacked-bar height default is 350 and it is exported for the widget '
    'to apply',
    () {
      expect(
        kVegaStackedBarDefaultHeight,
        350,
        reason:
            'ts:2712 falls back to DEFAULT_CHART_HEIGHT (ts:74). '
            'FluentVerticalStackedBarChart is a shell chart with no height '
            'parameter, so the constant is exported here and task 52 applies '
            'it as the cell SizedBox.',
      );
    },
  );

  test('bars stack per x value in colour-field order', () {
    final chart = build(stacked);
    expect(
      chart.data.first.chartData.map((d) => d.legend).toList(),
      <String>['p', 'q'],
      reason: 'ts:2349-2540 groups by x then by the colour field.',
    );
  });

  test('the chart title and both category orders land on the widget', () {
    final chart = build(<String, Object?>{
      ...stacked,
      'title': 'Stacks',
      'encoding': <String, Object?>{
        'x': <String, Object?>{
          'field': 'c',
          'type': 'nominal',
          'sort': 'descending',
        },
        'y': <String, Object?>{
          'field': 'v',
          'type': 'quantitative',
          'sort': 'ascending',
        },
        'color': <String, Object?>{'field': 'g', 'type': 'nominal'},
      },
    });
    expect(
      chart.chartTitle,
      'Stacks',
      reason:
          'ts:2707 spreads chartTitle beside the axis titles; the plan block '
          'omitted it.',
    );
    expect(
      chart.xAxisCategoryOrder,
      FluentAxisCategoryOrder.categoryDescending,
      reason:
          'ts:2727. vertical_stacked_bar_chart.dart:1340 hands '
          '`widget.xAxisCategoryOrder` to the delegate and never reads '
          '`props.xAxisCategoryOrder`, so the order must land on the widget.',
    );
    expect(
      chart.yAxisCategoryOrder,
      FluentAxisCategoryOrder.categoryAscending,
      reason:
          'ts:2727, and vertical_stacked_bar_chart.dart:1341 for the y '
          'half of the same pair.',
    );
  });

  test('a line layer overlays with a triangle swatch', () {
    final chart = build(<String, Object?>{
      'layer': <Object?>[
        <String, Object?>{'mark': 'bar'},
        <String, Object?>{
          'mark': 'line',
          'encoding': <String, Object?>{
            'y': <String, Object?>{'field': 'w', 'type': 'quantitative'},
          },
        },
      ],
      'data': <String, Object?>{
        'values': <Object?>[
          <String, Object?>{'c': 'a', 'v': 1, 'w': 9},
          <String, Object?>{'c': 'b', 'v': 3, 'w': 7},
        ],
      },
      'encoding': <String, Object?>{
        'x': <String, Object?>{'field': 'c', 'type': 'nominal'},
        'y': <String, Object?>{'field': 'v', 'type': 'quantitative'},
      },
    });
    expect(
      chart.data.first.lineData!.single.legendShape,
      FluentChartLegendShape.triangle,
      reason: "ts:2595 sets legendShape to 'triangle' on the line overlay.",
    );
    expect(
      chart.data.first.lineData!.single.legend,
      'Line 1',
      reason:
          "ts:2542 uses 'Line' when a colour field exists and `Line \${i + 1}` "
          'otherwise.',
    );
  });

  test(
    'a secondary y axis needs independent resolution AND a different field',
    () {
      Map<String, Object?> spec({required String lineField, Object? resolve}) =>
          <String, Object?>{
            'layer': <Object?>[
              <String, Object?>{'mark': 'bar'},
              <String, Object?>{
                'mark': 'line',
                'encoding': <String, Object?>{
                  'y': <String, Object?>{
                    'field': lineField,
                    'type': 'quantitative',
                  },
                },
              },
            ],
            'resolve': ?resolve,
            'data': <String, Object?>{
              'values': <Object?>[
                <String, Object?>{'c': 'a', 'v': 1, 'w': 900},
              ],
            },
            'encoding': <String, Object?>{
              'x': <String, Object?>{'field': 'c', 'type': 'nominal'},
              'y': <String, Object?>{'field': 'v', 'type': 'quantitative'},
            },
          };

      expect(
        build(
          spec(
            lineField: 'w',
            resolve: <String, Object?>{
              'scale': <String, Object?>{'y': 'independent'},
            },
          ),
        ).props.secondaryYScaleOptions,
        isNotNull,
        reason: 'ts:2588-2589.',
      );
      expect(
        build(spec(lineField: 'w')).props.secondaryYScaleOptions,
        isNull,
        reason: 'ts:2588-2589 requires the independent resolve.',
      );
      expect(
        build(
          spec(
            lineField: 'v',
            resolve: <String, Object?>{
              'scale': <String, Object?>{'y': 'independent'},
            },
          ),
        ).props.secondaryYScaleOptions,
        isNull,
        reason: 'ts:2589 also requires lineYField != yField.',
      );
    },
  );

  test('the bar layer is primary, a point is a line, and both transform lists '
      'run on each', () {
    // Four categories and three filters. The top-level one drops `b`; the
    // point layer's own drops `d`; the bar layer's own drops `c`. So the bars
    // are a and d, the line points are a and c, and every group is attributable
    // to exactly one pass.
    final chart = build(<String, Object?>{
      'layer': <Object?>[
        <String, Object?>{
          'mark': 'point',
          'transform': <Object?>[
            <String, Object?>{'filter': "datum.c !== 'd'"},
          ],
          'encoding': <String, Object?>{
            'y': <String, Object?>{'field': 'w', 'type': 'quantitative'},
          },
        },
        <String, Object?>{
          'mark': 'bar',
          'transform': <Object?>[
            <String, Object?>{'filter': "datum.c !== 'c'"},
          ],
        },
      ],
      'transform': <Object?>[
        <String, Object?>{'filter': "datum.c !== 'b'"},
      ],
      'data': <String, Object?>{
        'values': <Object?>[
          <String, Object?>{'c': 'a', 'v': 1, 'w': 9},
          <String, Object?>{'c': 'b', 'v': 2, 'w': 8},
          <String, Object?>{'c': 'c', 'v': 3, 'w': 7},
          <String, Object?>{'c': 'd', 'v': 4, 'w': 6},
        ],
      },
      'encoding': <String, Object?>{
        'x': <String, Object?>{'field': 'c', 'type': 'nominal'},
        'y': <String, Object?>{'field': 'v', 'type': 'quantitative'},
      },
    });
    expect(
      chart.data.map((g) => g.xAxisPoint).toList(),
      <String>['a', 'd', 'c'],
      reason:
          'ts:2368 makes the BAR layer primary though it is layer one, and '
          'ts:2371-2372 run the top-level transform then that layer own — so '
          'the stacks are a and d, in that order. ts:2360-2363 count a `point` '
          'mark as a line layer, and ts:2527-2530 run both lists over it too, '
          'so its surviving c point appends a third group at ts:2557-2563. '
          'Dropping any one of those four passes changes this list.',
    );
    expect(
      chart.data.last.chartData,
      isEmpty,
      reason:
          "ts:2372: the bar layer's own filter removed c from the stacks, and "
          'ts:2559 still created the group for the point.',
    );
    expect(
      chart.data[1].lineData,
      isEmpty,
      reason:
          "ts:2529: the point layer's own filter removed d, so the group the "
          'bar pass made for it carries no line point.',
    );
  });

  test('a rule mark is replicated onto every x point', () {
    final chart = build(<String, Object?>{
      'layer': <Object?>[
        <String, Object?>{'mark': 'bar'},
        <String, Object?>{
          'mark': 'rule',
          'encoding': <String, Object?>{
            'y': <String, Object?>{'datum': 2},
          },
        },
      ],
      'data': <String, Object?>{
        'values': <Object?>[
          <String, Object?>{'c': 'a', 'v': 1},
          <String, Object?>{'c': 'b', 'v': 3},
        ],
      },
      'encoding': <String, Object?>{
        'x': <String, Object?>{'field': 'c', 'type': 'nominal'},
        'y': <String, Object?>{'field': 'v', 'type': 'quantitative'},
      },
    });
    expect(
      chart.data.every((g) => g.lineData!.any((l) => l.legend == '2')),
      isTrue,
      reason:
          'ts:2644-2652 replicate the flat reference line across every group. '
          "The legend is ts:2639-2641's `ruleText` — String(yDatum) with no "
          "companion text layer, so '2' — NOT the `Reference_0` at ts:2620, "
          'which is only the colour-map key.',
    );
  });
}
