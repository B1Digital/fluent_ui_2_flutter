import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:fluent_2_web/src/charts/internal/vega/transform_line.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, Object?> lineSpec({
    Object? mark = 'line',
    Map<String, Object?>? extra,
  }) => <String, Object?>{
    'mark': mark,
    'data': <String, Object?>{
      'values': <Object?>[
        <String, Object?>{'x': 1, 'y': 10},
        <String, Object?>{'x': 2, 'y': 20},
      ],
    },
    'encoding': <String, Object?>{
      'x': <String, Object?>{'field': 'x', 'type': 'quantitative'},
      'y': <String, Object?>{'field': 'y', 'type': 'quantitative'},
    },
    ...?extra,
  };

  FluentLineChart line(Map<String, Object?> spec) =>
      transformVegaToLine(spec, <String, String>{}, isDark: false);

  test('points are hidden unless the spec layers a point mark over a line '
      'mark', () {
    expect(
      line(lineSpec()).data.lineChartData!.single.hideInactiveDots,
      isTrue,
      reason:
          'VegaLiteSchemaAdapter.ts:1770-1772, :1861: shouldShowPoints requires '
          'BOTH a point layer and a line layer, and :1861 inverts it.',
    );
    expect(
      line(<String, Object?>{
        'layer': <Object?>[
          <String, Object?>{'mark': 'line'},
          <String, Object?>{'mark': 'point'},
        ],
        'data': <String, Object?>{
          'values': <Object?>[
            <String, Object?>{'x': 1, 'y': 10},
          ],
        },
        'encoding': <String, Object?>{
          'x': <String, Object?>{'field': 'x', 'type': 'quantitative'},
          'y': <String, Object?>{'field': 'y', 'type': 'quantitative'},
        },
      }).data.lineChartData!.single.hideInactiveDots,
      isFalse,
      reason: 'VegaLiteSchemaAdapter.ts:1770-1772.',
    );
  });

  test('a point-only layer wins the primary-spec search over a rect fill '
      'layer', () {
    final chart = line(<String, Object?>{
      'layer': <Object?>[
        // A colour-fill rect layer, which carries no y field of its own and
        // must not become the primary spec (`VegaLiteSchemaAdapter.ts:1515`).
        <String, Object?>{
          'mark': 'rect',
          'encoding': <String, Object?>{
            'x': <String, Object?>{'datum': 1},
          },
        },
        <String, Object?>{'mark': 'line'},
      ],
      'data': <String, Object?>{
        'values': <Object?>[
          <String, Object?>{'x': 1, 'y': 10},
          <String, Object?>{'x': 2, 'y': 20},
        ],
      },
      'encoding': <String, Object?>{
        'x': <String, Object?>{'field': 'x', 'type': 'quantitative'},
        'y': <String, Object?>{'field': 'y', 'type': 'quantitative'},
      },
    });
    expect(
      chart.data.lineChartData!.single.data,
      hasLength(2),
      reason:
          'VegaLiteSchemaAdapter.ts:1516-1523: the line layer is found before '
          'the field-encoding fallback, so the rect layer never supplies the '
          'data.',
    );
  });

  test('only the TOP-LEVEL transforms are applied, never the layer own '
      'ones', () {
    final chart = line(<String, Object?>{
      'mark': 'line',
      'transform': <Object?>[
        <String, Object?>{'filter': 'datum.y > 10'},
      ],
      'data': <String, Object?>{
        'values': <Object?>[
          <String, Object?>{'x': 1, 'y': 10},
          <String, Object?>{'x': 2, 'y': 20},
        ],
      },
      'encoding': <String, Object?>{
        'x': <String, Object?>{'field': 'x', 'type': 'quantitative'},
        'y': <String, Object?>{'field': 'y', 'type': 'quantitative'},
      },
    });
    expect(
      chart.data.lineChartData!.single.data,
      hasLength(1),
      reason:
          'VegaLiteSchemaAdapter.ts:1776 applies `spec.transform` — and only '
          'that one, unlike initializeTransformContext at :1170-1173, which '
          'also applies the layer own transform.',
    );
  });

  test('a rule reference line spans the full x extent and defaults to the '
      'plotly red', () {
    final chart = line(<String, Object?>{
      'layer': <Object?>[
        <String, Object?>{'mark': 'line'},
        <String, Object?>{
          'mark': 'rule',
          'encoding': <String, Object?>{
            'y': <String, Object?>{'datum': 15},
          },
        },
      ],
      'data': <String, Object?>{
        'values': <Object?>[
          <String, Object?>{'x': 1, 'y': 10},
          <String, Object?>{'x': 5, 'y': 20},
        ],
      },
      'encoding': <String, Object?>{
        'x': <String, Object?>{'field': 'x', 'type': 'quantitative'},
        'y': <String, Object?>{'field': 'y', 'type': 'quantitative'},
      },
    });
    final rule = chart.data.lineChartData!.firstWhere(
      (series) => series.legend == 'y=15',
    );
    expect(
      rule.data,
      hasLength(2),
      reason:
          'VegaLiteSchemaAdapter.ts:1928-1931 emits two points, at xMin and '
          'xMax.',
    );
    expect(
      <Object>[
        for (final point in rule.data) (point as FluentLineChartDataPoint).x,
      ],
      <Object>[1, 5],
      reason:
          'VegaLiteSchemaAdapter.ts:1890-1892 reduces over the ALREADY-MAPPED '
          'x values of every series.',
    );
    expect(
      rule.color!.toARGB32(),
      const Color(0xFFD62728).toARGB32(),
      reason: "VegaLiteSchemaAdapter.ts:1907 defaults a rule to '#d62728'.",
    );
    expect(
      chart.data.lineChartData!.last.hideInactiveDots,
      isTrue,
      reason:
          'VegaLiteSchemaAdapter.ts:1933 always hides dots on a reference '
          'line.',
    );
  });

  test('a companion text layer at the same y renames the reference line', () {
    final chart = line(<String, Object?>{
      'layer': <Object?>[
        <String, Object?>{'mark': 'line'},
        <String, Object?>{
          'mark': 'rule',
          'encoding': <String, Object?>{
            'y': <String, Object?>{'datum': 15},
          },
        },
        <String, Object?>{
          'mark': 'text',
          'encoding': <String, Object?>{
            'y': <String, Object?>{'datum': 15},
            'text': <String, Object?>{'value': 'Target'},
          },
        },
      ],
      'data': <String, Object?>{
        'values': <Object?>[
          <String, Object?>{'x': 1, 'y': 10},
        ],
      },
      'encoding': <String, Object?>{
        'x': <String, Object?>{'field': 'x', 'type': 'quantitative'},
        'y': <String, Object?>{'field': 'y', 'type': 'quantitative'},
      },
    });
    expect(
      chart.data.lineChartData!.last.legend,
      'Target',
      reason:
          'VegaLiteSchemaAdapter.ts:1910-1916: the text layer datum/value wins '
          r'over the `y=${yDatum}` fallback.',
    );
  });

  test('a vertical rule with no y datum is skipped', () {
    final chart = line(<String, Object?>{
      'layer': <Object?>[
        <String, Object?>{'mark': 'line'},
        <String, Object?>{
          'mark': 'rule',
          'encoding': <String, Object?>{
            'x': <String, Object?>{'datum': 2},
          },
        },
      ],
      'data': <String, Object?>{
        'values': <Object?>[
          <String, Object?>{'x': 1, 'y': 10},
        ],
      },
      'encoding': <String, Object?>{
        'x': <String, Object?>{'field': 'x', 'type': 'quantitative'},
        'y': <String, Object?>{'field': 'y', 'type': 'quantitative'},
      },
    });
    expect(
      chart.data.lineChartData,
      hasLength(1),
      reason:
          'VegaLiteSchemaAdapter.ts:1902-1904 returns early, so only the '
          'annotation extractor ever sees a vertical rule.',
    );
  });

  test('a nominal y axis is projected onto integer indices with half-unit '
      'padding', () {
    final chart = line(<String, Object?>{
      'mark': 'line',
      'data': <String, Object?>{
        'values': <Object?>[
          <String, Object?>{'x': 1, 'y': 'low'},
          <String, Object?>{'x': 2, 'y': 'high'},
        ],
      },
      'encoding': <String, Object?>{
        'x': <String, Object?>{'field': 'x', 'type': 'quantitative'},
        'y': <String, Object?>{'field': 'y', 'type': 'nominal'},
      },
    });
    expect(chart.props.yAxisTickValues, <Object>[
      0,
      1,
    ], reason: 'VegaLiteSchemaAdapter.ts:1969.');
    expect(
      chart.props.yMinValue,
      -0.5,
      reason: 'VegaLiteSchemaAdapter.ts:1971.',
    );
    expect(
      chart.props.yMaxValue,
      1.5,
      reason: 'VegaLiteSchemaAdapter.ts:1972: n - 0.5 with n = 2.',
    );
    expect(
      chart.props.yAxisTickFormat!(0),
      'low',
      reason:
          'VegaLiteSchemaAdapter.ts:1970 maps the index back to the label, '
          'falling back to String(v).',
    );
    expect(
      chart.props.yAxisTickFormat!(7),
      '7',
      reason:
          'VegaLiteSchemaAdapter.ts:1970: an index outside the label list '
          'falls back to String(val).',
    );
  });

  test('a d3 format on the y axis becomes the tick formatter when the axis is '
      'not nominal', () {
    final chart = line(
      lineSpec(
        extra: <String, Object?>{
          'encoding': <String, Object?>{
            'x': <String, Object?>{'field': 'x', 'type': 'quantitative'},
            'y': <String, Object?>{
              'field': 'y',
              'type': 'quantitative',
              'axis': <String, Object?>{'format': '.1f'},
            },
          },
        },
      ),
    );
    expect(
      chart.props.yAxisTickFormat!(10),
      '10.0',
      reason:
          'VegaLiteSchemaAdapter.ts:1873 and :1958 forward `axis.format` as '
          'the y tick format.',
    );
  });

  test('an ordinal x axis supplies its own tick values ahead of an explicit '
      'axis.values', () {
    final chart = line(<String, Object?>{
      'mark': 'line',
      'data': <String, Object?>{
        'values': <Object?>[
          <String, Object?>{'x': 'a', 'y': 10},
          <String, Object?>{'x': 'b', 'y': 20},
        ],
      },
      'encoding': <String, Object?>{
        'x': <String, Object?>{
          'field': 'x',
          'type': 'ordinal',
          'axis': <String, Object?>{
            'values': <Object?>[99],
          },
        },
        'y': <String, Object?>{'field': 'y', 'type': 'quantitative'},
      },
    });
    expect(
      chart.props.tickValues,
      <Object>['a', 'b'],
      reason:
          'VegaLiteSchemaAdapter.ts:1877 is `ordinalLabels || '
          'encoding.x.axis.values`, so the generated labels win.',
    );
  });

  test('an x axis title lands on the x axis rather than overwriting the '
      'narration title', () {
    final chart = line(
      lineSpec(
        extra: <String, Object?>{
          'title': 'Revenue',
          'encoding': <String, Object?>{
            'x': <String, Object?>{
              'field': 'x',
              'type': 'quantitative',
              'axis': <String, Object?>{'title': 'Quarter'},
            },
            'y': <String, Object?>{'field': 'y', 'type': 'quantitative'},
          },
        },
      ),
    );
    expect(
      chart.props.xAxisTitle,
      'Quarter',
      reason:
          'VegaLiteSchemaAdapter.ts:1955 spreads `{ chartTitle: xAxisTitle }` '
          'where :1956 spreads `{ yAxisTitle }`; the port assigns xAxisTitle, '
          'hardened at the site.',
    );
    expect(
      chart.data.chartTitle,
      'Revenue',
      reason: 'VegaLiteSchemaAdapter.ts:1867, :1946-1949.',
    );
  });

  test('a legend disable flag hides the legend', () {
    expect(
      line(
        lineSpec(
          extra: <String, Object?>{
            'encoding': <String, Object?>{
              'x': <String, Object?>{'field': 'x', 'type': 'quantitative'},
              'y': <String, Object?>{'field': 'y', 'type': 'quantitative'},
              'color': <String, Object?>{
                'field': 'c',
                'legend': <String, Object?>{'disable': true},
              },
            },
          },
        ),
      ).props.hideLegend,
      isTrue,
      reason: 'VegaLiteSchemaAdapter.ts:1975.',
    );
    expect(
      line(lineSpec()).props.hideLegend,
      isFalse,
      reason: 'VegaLiteSchemaAdapter.ts:1975 falls back to false.',
    );
  });

  test('a mark object contributes curve, dash and width line options', () {
    final chart = line(
      lineSpec(
        mark: <String, Object?>{
          'type': 'line',
          'interpolate': 'step-after',
          'strokeDash': <Object?>[4, 2],
          'strokeWidth': 3,
        },
      ),
    );
    final options = chart.data.lineChartData!.single.lineOptions!;
    expect(
      options.curve,
      FluentLineCurve.stepAfter,
      reason: 'VegaLiteSchemaAdapter.ts:1843, :1847-1849.',
    );
    expect(
      options.strokeDasharray,
      '4 2',
      reason:
          'VegaLiteSchemaAdapter.ts:1851 joins with a SPACE, the SVG '
          'stroke-dasharray syntax.',
    );
    expect(
      options.strokeWidth,
      3,
      reason: 'VegaLiteSchemaAdapter.ts:1853-1855.',
    );
  });

  test('a bare string mark contributes no line options at all', () {
    expect(
      line(lineSpec()).data.lineChartData!.single.lineOptions,
      isNull,
      reason:
          'VegaLiteSchemaAdapter.ts:1862 spreads `lineOptions` only when the '
          'object has keys, so an empty one must not override the chart own '
          'defaults.',
    );
  });

  test('a stroke width of zero is dropped, because upstream tests it for '
      'truthiness', () {
    expect(
      line(
        lineSpec(mark: <String, Object?>{'type': 'line', 'strokeWidth': 0}),
      ).data.lineChartData!.single.lineOptions,
      isNull,
      reason: 'VegaLiteSchemaAdapter.ts:1853 is `if (markProps.strokeWidth)`.',
    );
  });

  test('a spec with no unit specs and one with no x or y field both throw', () {
    expect(
      () => line(<String, Object?>{'data': <String, Object?>{}}),
      throwsA(
        isA<Object>().having(
          (error) => error.toString(),
          'message',
          contains('No valid unit specs found'),
        ),
      ),
      reason: 'VegaLiteSchemaAdapter.ts:1759-1761, message verbatim.',
    );
    expect(
      () => line(<String, Object?>{
        'mark': 'line',
        'data': <String, Object?>{
          'values': <Object?>[
            <String, Object?>{'x': 1, 'y': 2},
          ],
        },
        'encoding': <String, Object?>{
          'x': <String, Object?>{'field': 'x', 'type': 'quantitative'},
        },
      }),
      throwsA(
        isA<Object>().having(
          (error) => error.toString(),
          'message',
          contains('requires both x and y encodings'),
        ),
      ),
      reason: 'VegaLiteSchemaAdapter.ts:1798-1800, message verbatim.',
    );
  });

  test('the area transformer picks its mode from the stack configuration', () {
    FluentAreaChart area(
      Map<String, Object?> yExtra, {
      bool withColour = false,
    }) => transformVegaToArea(
      <String, Object?>{
        'mark': 'area',
        'data': <String, Object?>{
          'values': <Object?>[
            <String, Object?>{'x': 1, 'y': 10, 'c': 'g'},
          ],
        },
        'encoding': <String, Object?>{
          'x': <String, Object?>{'field': 'x', 'type': 'quantitative'},
          'y': <String, Object?>{
            'field': 'y',
            'type': 'quantitative',
            ...yExtra,
          },
          if (withColour)
            'color': <String, Object?>{'field': 'c', 'type': 'nominal'},
        },
      },
      <String, String>{},
      isDark: false,
    );
    expect(
      area(<String, Object?>{'stack': 'zero'}).mode,
      FluentAreaChartMode.toNextY,
      reason:
          "VegaLiteSchemaAdapter.ts:3047-3050: a stack of 'zero' is stacked.",
    );
    expect(
      area(<String, Object?>{'stack': null}).mode,
      FluentAreaChartMode.toZeroY,
      reason:
          'VegaLiteSchemaAdapter.ts:3047-3050: a null stack with no colour '
          'encoding is not stacked.',
    );
    expect(
      area(<String, Object?>{}, withColour: true).mode,
      FluentAreaChartMode.toNextY,
      reason:
          'VegaLiteSchemaAdapter.ts:3047: an ABSENT stack with a colour '
          'encoding stacks, because `undefined !== null` in JavaScript.',
    );
    expect(
      area(<String, Object?>{'stack': null}, withColour: true).mode,
      FluentAreaChartMode.toZeroY,
      reason:
          'VegaLiteSchemaAdapter.ts:3047: an EXPLICIT `stack: null` beats the '
          'colour encoding, which is why key presence and key absence must be '
          'told apart.',
    );
  });

  test('the area transformer carries the line transformer data and props '
      'through unchanged', () {
    final chart = transformVegaToArea(
      <String, Object?>{
        'mark': 'area',
        'title': 'Traffic',
        'data': <String, Object?>{
          'values': <Object?>[
            <String, Object?>{'x': 1, 'y': 10},
            <String, Object?>{'x': 2, 'y': 20},
          ],
        },
        'encoding': <String, Object?>{
          'x': <String, Object?>{'field': 'x', 'type': 'quantitative'},
          'y': <String, Object?>{
            'field': 'y',
            'type': 'quantitative',
            'axis': <String, Object?>{'title': 'Hits'},
          },
        },
      },
      <String, String>{},
      isDark: false,
    );
    expect(
      chart.data.chartTitle,
      'Traffic',
      reason: 'VegaLiteSchemaAdapter.ts:3035 spreads the line props whole.',
    );
    expect(
      chart.props.yAxisTitle,
      'Hits',
      reason: 'VegaLiteSchemaAdapter.ts:1956, reached through :3035.',
    );
    expect(
      chart.data.lineChartData!.single.data,
      hasLength(2),
      reason: 'VegaLiteSchemaAdapter.ts:3035.',
    );
  });
}
