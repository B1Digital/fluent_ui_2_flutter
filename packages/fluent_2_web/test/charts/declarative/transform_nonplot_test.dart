import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:fluent_2_web/src/charts/internal/plotly/color_adapter.dart';
import 'package:fluent_2_web/src/charts/internal/plotly/transform_pie.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FluentSankeyChart sankey(Map<String, Object?> input) =>
      transformPlotlyToSankey(
        input,
        isMultiPlot: false,
        colorMap: <String, String>{},
        colorwayType: FluentPlotlyColorway.byDefault,
        isDark: false,
      );
  FluentGaugeChart gauge(Map<String, Object?> input) => transformPlotlyToGauge(
    input,
    isMultiPlot: false,
    colorMap: <String, String>{},
    colorwayType: FluentPlotlyColorway.byDefault,
    isDark: false,
  );
  FluentChartTable table(Map<String, Object?> input) =>
      transformPlotlyToChartTable(
        input,
        isMultiPlot: false,
        colorMap: <String, String>{},
        colorwayType: FluentPlotlyColorway.byDefault,
        isDark: false,
      );

  test('sankey drops self-links and negative endpoints', () {
    final chart = sankey(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'sankey',
          'node': <String, Object?>{
            'label': <Object?>['a', 'b'],
          },
          'link': <String, Object?>{
            'source': <Object?>[0, 1, -1],
            'target': <Object?>[1, 1, 0],
            'value': <Object?>[5, 5, 5],
          },
        },
      ],
    });
    expect(
      chart.data.links,
      hasLength(1),
      reason:
          'PlotlySchemaAdapter.ts:2644 keeps only source >= 0 && target >= 0 '
          '&& source != target.',
    );
    expect(
      <int>[chart.data.links.single.source, chart.data.links.single.target],
      <int>[0, 1],
      reason: 'the survivor is the first triple, PlotlySchemaAdapter.ts:2637.',
    );
    expect(
      chart.data.nodes.map((n) => n.name).toList(),
      <String>['a', 'b'],
      reason:
          'PlotlySchemaAdapter.ts:2662-2676 makes one node per label, in '
          'schema order, with the index as its nodeId.',
    );
  });

  test('a sankey link whose value is not finite is dropped', () {
    final chart = sankey(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'sankey',
          'node': <String, Object?>{
            'label': <Object?>['a', 'b'],
          },
          'link': <String, Object?>{
            'source': <Object?>[0, 0],
            'target': <Object?>[1, 1],
            'value': <Object?>[null, 7],
          },
        },
      ],
    });
    expect(
      chart.data.links.map((l) => l.value).toList(),
      <double>[7],
      reason:
          'PlotlySchemaAdapter.ts:2633 nulls out a triple whose value, source '
          'or target is an invalid value, and :2644 filters those nulls out.',
    );
  });

  testWidgets('a transformed sankey figure mounts and lays itself out', (
    tester,
  ) async {
    final chart = sankey(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'sankey',
          'node': <String, Object?>{
            'label': <Object?>['Inbox', 'Archive', 'Deleted'],
          },
          'link': <String, Object?>{
            'source': <Object?>[0, 0],
            'target': <Object?>[1, 2],
            'value': <Object?>[70, 30],
          },
        },
      ],
      'layout': <String, Object?>{'title': 'Mail'},
    });
    await tester.pumpWidget(
      FluentApp(
        theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
        // 912x468 are the upstream container defaults
        // (`SankeyChart.tsx:571-572`); :2709's 468 is the same number.
        home: Center(child: SizedBox(width: 912, height: 468, child: chart)),
      ),
    );
    expect(
      tester
          .widgetList<Semantics>(find.byType(Semantics))
          .any(
            (s) =>
                s.properties.label == 'Sankey chart with 3 nodes and 2 links',
          ),
      isTrue,
      reason:
          'the transformed graph has to reach a real layout pass, not merely '
          'a props bag: three labels at PlotlySchemaAdapter.ts:2662 and two '
          'surviving links at :2644.',
    );
    expect(
      chart.chartTitle,
      'Mail',
      reason: 'PlotlySchemaAdapter.ts:2701 spreads getTitles onto data.',
    );
  });

  test('a gauge without steps splits into a Current and a Target segment', () {
    final chart = gauge(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'indicator',
          'mode': 'gauge+number',
          'value': 30,
          'gauge': <String, Object?>{
            'axis': <String, Object?>{
              'range': <Object?>[0, 100],
            },
          },
        },
      ],
    });
    expect(
      chart.segments.map((s) => s.legend).toList(),
      <String>['Current', 'Target'],
      reason: 'PlotlySchemaAdapter.ts:2752-2769.',
    );
    expect(
      chart.segments.last.size,
      70,
      reason: 'PlotlySchemaAdapter.ts:2766: (range[1] ?? 100) - (value ?? 0).',
    );
  });

  test(
    'the Current segment reproduces the nullish-coalescing precedence bug',
    () {
      final chart = gauge(<String, Object?>{
        'data': <Object?>[
          <String, Object?>{
            'type': 'indicator',
            'mode': 'gauge+number',
            'value': 30,
            'gauge': <String, Object?>{
              'axis': <String, Object?>{
                'range': <Object?>[10, 100],
              },
            },
          },
        ],
      });
      expect(
        chart.segments.first.size,
        30,
        reason:
            'parity: PlotlySchemaAdapter.ts:2755 reads `firstData.value ?? 0 - '
            'range[0]`, and JavaScript binds `-` tighter than `??`, so the '
            'range start is never subtracted from a present value. The '
            'correct-looking 20 would be a divergence.',
      );
    },
  );

  test(
    'an absent value takes the negated range start, which is the same bug',
    () {
      final chart = gauge(<String, Object?>{
        'data': <Object?>[
          <String, Object?>{
            'type': 'indicator',
            'mode': 'gauge+number',
            'gauge': <String, Object?>{
              'axis': <String, Object?>{
                'range': <Object?>[10, 100],
              },
            },
          },
        ],
      });
      expect(
        chart.segments.first.size,
        -10,
        reason:
            'the other arm of PlotlySchemaAdapter.ts:2755: with no value the '
            'expression is `0 - range[0]`, so the segment size goes negative. '
            'GaugeChart.tsx:189 clamps it at paint time; the transformer does '
            'not.',
      );
    },
  );

  test('gauge steps become one segment each, with the fallback legend', () {
    final chart = gauge(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'indicator',
          'mode': 'gauge+number',
          'value': 55,
          'gauge': <String, Object?>{
            'steps': <Object?>[
              <String, Object?>{
                'range': <Object?>[0, 40],
                'name': 'Low',
              },
              <String, Object?>{
                'range': <Object?>[40, 100],
              },
            ],
          },
        },
      ],
    });
    expect(
      chart.segments.map((s) => s.legend).toList(),
      <String>['Low', 'Segment 2'],
      reason:
          'PlotlySchemaAdapter.ts:2737: `step.name || `Segment \${index + 1}`` '
          '— a one-based ordinal, not a zero-based one.',
    );
    expect(
      chart.segments.map((s) => s.size).toList(),
      <double>[40, 60],
      reason: 'PlotlySchemaAdapter.ts:2748: range[1] - range[0].',
    );
    expect(
      chart.variant,
      FluentGaugeChartVariant.multipleSegments,
      reason:
          "PlotlySchemaAdapter.ts:2833 sends 'multiple-segments' when "
          'gauge.steps.length is truthy.',
    );
  });

  test(
    'the delta sublabel uses the two triangle glyphs with a single space',
    () {
      final up = gauge(<String, Object?>{
        'data': <Object?>[
          <String, Object?>{
            'type': 'indicator',
            'mode': 'gauge+number',
            'value': 30,
            'delta': <String, Object?>{'reference': 20},
          },
        ],
      });
      expect(
        up.sublabel,
        '▲ 10',
        reason:
            'PlotlySchemaAdapter.ts:2776, U+25B2 BLACK UP-POINTING TRIANGLE '
            'plus one space.',
      );
      final down = gauge(<String, Object?>{
        'data': <Object?>[
          <String, Object?>{
            'type': 'indicator',
            'mode': 'gauge+number',
            'value': 10,
            'delta': <String, Object?>{'reference': 20},
          },
        ],
      });
      expect(
        down.sublabel,
        '▼ 10',
        reason:
            'PlotlySchemaAdapter.ts:2794, U+25BC and the absolute difference.',
      );
    },
  );

  test('a delta reference of 0 declares no sublabel at all', () {
    final chart = gauge(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'indicator',
          'mode': 'gauge+number',
          'value': 30,
          'delta': <String, Object?>{'reference': 0},
        },
      ],
    });
    expect(
      chart.sublabel,
      isNull,
      reason:
          'PlotlySchemaAdapter.ts:2773 gates on the truthiness of '
          '`delta.reference`, so a reference of 0 skips the whole block.',
    );
  });

  test('the gauge defaults', () {
    final chart = gauge(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'indicator',
          'mode': 'gauge+number',
          'value': 1,
        },
      ],
    });
    expect(chart.height, 220, reason: 'PlotlySchemaAdapter.ts:2830.');
    expect(chart.roundCorners, isTrue, reason: 'PlotlySchemaAdapter.ts:2835.');
    expect(
      chart.variant,
      FluentGaugeChartVariant.singleSegment,
      reason:
          'PlotlySchemaAdapter.ts:2833 selects on gauge.steps.length; the '
          "port's enum spells 'single-segment' as "
          'FluentGaugeChartVariant.singleSegment.',
    );
    expect(
      chart.maxValue,
      isNull,
      reason:
          'PlotlySchemaAdapter.ts:2827 sends undefined unless range[1] is '
          'literally a number, so a gauge with no axis declares no maximum.',
    );
  });

  testWidgets('a transformed gauge paints its sublabel and its value', (
    tester,
  ) async {
    final chart = gauge(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'indicator',
          'mode': 'gauge+number',
          'value': 30,
          'delta': <String, Object?>{'reference': 20},
          'gauge': <String, Object?>{
            'axis': <String, Object?>{
              'range': <Object?>[0, 100],
            },
          },
        },
      ],
    });
    await tester.pumpWidget(
      FluentApp(
        theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
        home: Center(child: SizedBox(width: 480, height: 320, child: chart)),
      ),
    );
    expect(
      find.text('▲ 10'),
      findsOneWidget,
      reason:
          'the sublabel built at PlotlySchemaAdapter.ts:2776 has to reach the '
          'painted chart, not merely the props bag (GaugeChart.tsx:685-693).',
    );
    expect(
      find.text('30'),
      findsOneWidget,
      reason:
          "PlotlySchemaAdapter.ts:2828's chartValueFormat is "
          '`() => value.toString()`, so the centred value reads 30 rather '
          'than the default 30%.',
    );
  });

  test('a chart table takes its font size from the layout font', () {
    final chart = table(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'table',
          'header': <String, Object?>{
            'values': <Object?>['h1', 'h2'],
          },
          'cells': <String, Object?>{
            'values': <Object?>[
              <Object?>['a'],
              <Object?>['b'],
            ],
          },
        },
      ],
      'layout': <String, Object?>{
        'font': <String, Object?>{'size': 17},
      },
    });
    expect(
      chart.headers.map((h) => h.value).toList(),
      <String>['h1', 'h2'],
      reason: 'PlotlySchemaAdapter.ts:3008 with :2921-2928.',
    );
    expect(
      chart.headers.map((h) => h.textStyle?.fontSize).toList(),
      <double>[17, 17],
      reason:
          'PlotlySchemaAdapter.ts:2983-2987 copies layout.font.size onto '
          'styles.root.fontSize; the port has no root slot, so the cascade '
          'lands on every cell that declares no size of its own.',
    );
  });

  test('a chart table transposes its columns into rows', () {
    final chart = table(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'table',
          'header': <String, Object?>{
            'values': <Object?>['h1', 'h2'],
          },
          'cells': <String, Object?>{
            'values': <Object?>[
              <Object?>['a1', 'a2'],
              <Object?>['b1', 'b2'],
            ],
            'prefix': '<',
            'suffix': '>',
          },
        },
      ],
    });
    expect(
      chart.rows!.map((r) => r.map((c) => c.value).toList()).toList(),
      <List<Object?>>[
        <Object?>['<a1>', '<b1>'],
        <Object?>['<a2>', '<b2>'],
      ],
      reason:
          'PlotlySchemaAdapter.ts:2952-2953 walks row index over columns[0] '
          'and column index over columns, and :2873 wraps every formatted '
          'value in the prefix and suffix.',
    );
  });

  test('a numeric cell is formatted by the column format specifier', () {
    final chart = table(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'table',
          'header': <String, Object?>{
            'values': <Object?>['n'],
          },
          'cells': <String, Object?>{
            'values': <Object?>[
              <Object?>[1234.5678, 2],
            ],
            'format': <Object?>['.2f'],
          },
        },
      ],
    });
    expect(
      chart.rows!.map((r) => r.single.value).toList(),
      <Object?>['1234.57', '2.00'],
      reason:
          'PlotlySchemaAdapter.ts:2858 takes format[colIndex] out of the '
          'array and :2865 applies d3Format to it.',
    );
  });

  test('markup and maths are stripped out of every cell', () {
    final chart = table(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'table',
          'header': <String, Object?>{
            'values': <Object?>['<b>bold</b> head'],
          },
          'cells': <String, Object?>{
            'values': <Object?>[
              <Object?>['one<br>two'],
            ],
          },
        },
      ],
    });
    expect(
      chart.headers.single.value,
      'bold head',
      reason:
          'PlotlySchemaAdapter.ts:2928 runs cleanText over every header, and '
          ':2843 drops the tags while keeping their contents.',
    );
    expect(
      chart.rows!.single.single.value,
      'onetwo',
      reason:
          'PlotlySchemaAdapter.ts:2955 runs the same cleanText over every '
          'string cell, and :2843-2844 remove <br> twice over.',
    );
  });

  test('per-cell font and fill colours reach the cell', () {
    final chart = table(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'table',
          'header': <String, Object?>{
            'values': <Object?>['h1'],
            'font': <String, Object?>{
              'color': <Object?>['#ff0000'],
              'size': <Object?>[21],
            },
            'fill': <String, Object?>{
              'color': <Object?>['#00ff00'],
            },
          },
          'cells': <String, Object?>{
            'values': <Object?>[
              <Object?>['a'],
            ],
          },
        },
      ],
      'layout': <String, Object?>{
        'font': <String, Object?>{'size': 17},
      },
    });
    expect(
      chart.headers.single.textStyle?.color,
      const Color(0xFFFF0000),
      reason:
          'PlotlySchemaAdapter.ts:2933 and :2941 put header.font.color on the '
          "header cell's own style.",
    );
    expect(
      chart.headers.single.backgroundColor,
      const Color(0xFF00FF00),
      reason: 'PlotlySchemaAdapter.ts:2935 and :2943.',
    );
    expect(
      chart.headers.single.textStyle?.fontSize,
      21,
      reason:
          "PlotlySchemaAdapter.ts:2942's per-cell fontSize is an inline style "
          "and wins over the root's 17, exactly as CSS specificity gives.",
    );
  });

  testWidgets('a transformed chart table paints its header and its body', (
    tester,
  ) async {
    final chart = table(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'table',
          'header': <String, Object?>{
            'values': <Object?>['Name', 'Count'],
          },
          'cells': <String, Object?>{
            'values': <Object?>[
              <Object?>['Inbox'],
              <Object?>['70'],
            ],
          },
        },
      ],
    });
    await tester.pumpWidget(
      FluentApp(
        theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
        home: Center(child: SizedBox(width: 480, height: 320, child: chart)),
      ),
    );
    for (final label in <String>['Name', 'Count', 'Inbox', '70']) {
      expect(
        find.text(label),
        findsOneWidget,
        reason:
            'the transformed header row (PlotlySchemaAdapter.ts:3008) and the '
            'transposed body (:2952) both have to reach a painted Table.',
      );
    }
  });
}
