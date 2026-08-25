import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2/src/charts/internal/plotly/color_adapter.dart';
import 'package:fluent_2/src/charts/internal/plotly/common.dart';
import 'package:fluent_2/src/charts/internal/plotly/transform_pie.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FluentDonutChart build(Map<String, Object?> input, {PlotlyColorMap? map}) =>
      transformPlotlyToDonut(
        input,
        isMultiPlot: false,
        colorMap: map ?? <String, String>{},
        colorwayType: FluentPlotlyColorway.byDefault,
        isDark: false,
      );

  test('slices sort descending by value and then reorder anticlockwise', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'pie',
          'labels': <Object?>['a', 'b', 'c'],
          'values': <Object?>[1, 3, 2],
        },
      ],
    });
    expect(
      chart.data.chartData!.map((d) => d.legend).toList(),
      <String>['b', 'a', 'c'],
      reason:
          'PlotlySchemaAdapter.ts:1320 sorts descending to [b, c, a], then '
          ':1360-1369 keeps the first and reverses the rest, giving [b, a, c].',
    );
  });

  test('invalid values are dropped before sorting', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'pie',
          'labels': <Object?>['a', 'b'],
          'values': <Object?>[1, null],
        },
      ],
    });
    expect(
      chart.data.chartData!.length,
      1,
      reason: 'PlotlySchemaAdapter.ts:1318 filters with isInvalidValue.',
    );
  });

  test('duplicate labels accumulate onto one slice', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'pie',
          'labels': <Object?>['a', 'a'],
          'values': <Object?>[1, 2],
        },
      ],
    });
    expect(
      chart.data.chartData!.single.data,
      3,
      reason:
          'PlotlySchemaAdapter.ts:1341-1342 adds into an existing legend rather '
          'than replacing it.',
    );
  });

  test(
    'the inner radius uses the 440x220 fallback box and the 80/80 margins',
    () {
      final chart = build(<String, Object?>{
        'data': <Object?>[
          <String, Object?>{
            'type': 'pie',
            'labels': <Object?>['a'],
            'values': <Object?>[1],
            'hole': 0.5,
          },
        ],
      });
      expect(
        chart.innerRadius,
        35,
        reason:
            'PlotlySchemaAdapter.ts:1347-1356: width 440, height 220, hideLabels '
            'false so donutMarginHorizontal 80 and donutMarginVertical '
            '40 + 40 = 80; min(440 - 80, 220 - 80) / 2 = 70; 0.5 * 70 = 35.',
      );
    },
  );

  test('no hole means the minimum donut radius, not zero', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'pie',
          'labels': <Object?>['a'],
          'values': <Object?>[1],
        },
      ],
    });
    expect(
      chart.innerRadius,
      kMinDonutRadius,
      reason:
          'PlotlySchemaAdapter.ts:1356 falls back to MIN_DONUT_RADIUS = 1 '
          '(utilities.ts:90).',
    );
  });

  test('textinfo controls both label visibility and percent mode', () {
    const cases = <String, ({bool hide, bool percent})>{
      'value': (hide: false, percent: false),
      'percent': (hide: false, percent: true),
      'label+percent': (hide: false, percent: true),
      'label': (hide: true, percent: false),
    };
    for (final entry in cases.entries) {
      final chart = build(<String, Object?>{
        'data': <Object?>[
          <String, Object?>{
            'type': 'pie',
            'labels': <Object?>['a'],
            'values': <Object?>[1],
            'textinfo': entry.key,
          },
        ],
      });
      expect(
        chart.hideLabels,
        entry.value.hide,
        reason: "PlotlySchemaAdapter.ts:1349-1351 for textinfo '${entry.key}'.",
      );
      expect(
        chart.showLabelsInPercent,
        entry.value.percent,
        reason: "PlotlySchemaAdapter.ts:1381-1383 for textinfo '${entry.key}'.",
      );
    }
  });

  test('a missing textinfo shows percentages and keeps the labels', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'pie',
          'labels': <Object?>['a'],
          'values': <Object?>[1],
        },
      ],
    });
    expect(
      chart.showLabelsInPercent,
      isTrue,
      reason:
          'PlotlySchemaAdapter.ts:1383 is the `: true` arm, which is the '
          'opposite of FluentDonutChart\'s own default (donut_chart.dart:470), '
          'so the transformer has to pass it explicitly.',
    );
    expect(
      chart.hideLabels,
      isFalse,
      reason: 'PlotlySchemaAdapter.ts:1351 is the `: false` arm.',
    );
  });

  test(
    'hiding labels halves the vertical margin and zeroes the horizontal one',
    () {
      final chart = build(<String, Object?>{
        'data': <Object?>[
          <String, Object?>{
            'type': 'pie',
            'labels': <Object?>['a'],
            'values': <Object?>[1],
            'hole': 1,
            'textinfo': 'label',
          },
        ],
      });
      expect(
        chart.innerRadius,
        90,
        reason:
            'PlotlySchemaAdapter.ts:1352-1355 with hideLabels true: margins 0 and '
            '40, so min(440 - 0, 220 - 40) / 2 = 90.',
      );
    },
  );

  test('the colour map is cleared before slice assignment', () {
    final map = <String, String>{'preexisting': '#123456'};
    build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'pie',
          'labels': <Object?>['a'],
          'values': <Object?>[1],
        },
      ],
    }, map: map);
    expect(
      map.containsKey('preexisting'),
      isFalse,
      reason:
          'PlotlySchemaAdapter.ts:1305 clears the map so getAllupLegendsProps, '
          'which ran first and populated it unsorted, does not fix the slice '
          'colours.',
    );
  });

  test(
    'marker colours win over the palette and stay attached to their label',
    () {
      final chart = build(<String, Object?>{
        'data': <Object?>[
          <String, Object?>{
            'type': 'pie',
            'labels': <Object?>['a', 'b'],
            'values': <Object?>[1, 5],
            'marker': <String, Object?>{
              'colors': <Object?>['#ff0000', '#00ff00'],
            },
          },
        ],
      });
      expect(
        chart.data.chartData!.first.color!.toARGB32(),
        const Color(0xFF00FF00).toARGB32(),
        reason:
            'PlotlySchemaAdapter.ts:1323-1333: the pair carries its colour '
            'through the descending sort, so b (value 5, colour #00ff00) is '
            'first.',
      );
    },
  );

  test('the sorted order flag and the fallback height are always set', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'pie',
          'labels': <Object?>['a'],
          'values': <Object?>[1],
        },
      ],
    });
    expect(
      chart.order,
      FluentDonutOrder.sorted,
      reason: 'PlotlySchemaAdapter.ts:1385.',
    );
    expect(chart.height, 220, reason: 'PlotlySchemaAdapter.ts:1348 and :1378.');
    expect(
      chart.width,
      isNull,
      reason:
          'PlotlySchemaAdapter.ts:1377 passes `input.layout?.width`, not the '
          '440 fallback the radius maths uses.',
    );
  });

  test('a layout with no title leaves the chart title unset', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'pie',
          'labels': <Object?>['a'],
          'values': <Object?>[1],
        },
      ],
    });
    expect(
      chart.data.chartTitle,
      isNull,
      reason:
          'getTitles returns \'\' for an absent title '
          '(PlotlySchemaAdapter.ts:177), which React renders as nothing because '
          'DonutChart.tsx:360 tests it for truthiness — donut_chart.dart:605 '
          'and :618 test for null instead, so an empty string would reserve '
          'title height and draw an empty title.',
    );
  });

  test('the layout title reaches the chart', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'pie',
          'labels': <Object?>['a'],
          'values': <Object?>[1],
        },
      ],
      'layout': <String, Object?>{
        'title': <String, Object?>{'text': 'Share'},
        'showlegend': false,
        'width': 300,
      },
    });
    expect(
      chart.data.chartTitle,
      'Share',
      reason: 'PlotlySchemaAdapter.ts:1357 and :1373.',
    );
    expect(
      chart.hideLegend,
      isTrue,
      reason: 'PlotlySchemaAdapter.ts:1376 — `showlegend === false`.',
    );
    expect(chart.width, 300, reason: 'PlotlySchemaAdapter.ts:1377.');
  });

  test('parseCssColour reads hex and rgb() specifiers', () {
    expect(
      parseCssColour('#ff0000').toARGB32(),
      const Color(0xFFFF0000).toARGB32(),
      reason: 'the three-channel hex form d3.color parses at color.js:204.',
    );
    expect(
      parseCssColour('rgb(0, 128, 255)').toARGB32(),
      const Color(0xFF0080FF).toARGB32(),
      reason: 'the functional form d3.color parses at color.js:209-210.',
    );
  });
}
