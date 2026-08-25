import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2/src/charts/internal/plotly/common.dart';
import 'package:fluent_2/src/charts/internal/plotly/transform_xy.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FluentHeatMapChart build(Map<String, Object?> input) =>
      transformPlotlyToHeatmap(
        input,
        isMultiPlot: false,
        colorMap: <String, String>{},
        colorwayType: FluentPlotlyColorway.byDefault,
        isDark: false,
      );

  test('the default colour domain is the three-point min, midpoint, max', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'heatmap',
          'x': <Object?>['a', 'b'],
          'y': <Object?>['p', 'q'],
          'z': <Object?>[
            <Object?>[0, 10],
            <Object?>[20, 40],
          ],
        },
      ],
    });
    expect(
      chart.domainValuesForColorScale,
      <double>[0, 20, 40],
      reason:
          'PlotlySchemaAdapter.ts:2563 builds [zMin, (zMax + zMin) / 2, '
          'zMax].',
    );
    expect(
      chart.rangeValuesForColorScale,
      <Color>[
        FluentDataVizPalette.resolve(FluentDataVizToken.color1),
        FluentDataVizPalette.resolve(FluentDataVizToken.color2),
        FluentDataVizPalette.resolve(FluentDataVizToken.color3),
      ],
      reason:
          'PlotlySchemaAdapter.ts:2564-2568 supplies exactly the first '
          'three DataViz colours, in that order.',
    );
    expect(
      chart.data.single.legend,
      '',
      reason:
          'PlotlySchemaAdapter.ts:2557 falls back to the empty string when '
          'the trace carries no name, and :2606 always builds exactly one '
          'series.',
    );
  });

  test('an explicit colorscale is remapped onto the data domain', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'heatmap',
          'x': <Object?>['a'],
          'y': <Object?>['p'],
          'z': <Object?>[
            <Object?>[10],
          ],
          'colorscale': <Object?>[
            <Object?>[0, '#000000'],
            <Object?>[1, '#ffffff'],
          ],
        },
      ],
    });
    expect(
      chart.domainValuesForColorScale,
      <double>[10, 10],
      reason:
          'PlotlySchemaAdapter.ts:2598 remaps stop[0] * (zMax - zMin) + '
          'zMin, and a single-cell figure has zMax == zMin so both stops '
          'collapse onto it.',
    );
    expect(
      chart.rangeValuesForColorScale,
      <Color>[const Color(0xFF000000), const Color(0xFFFFFFFF)],
      reason: 'PlotlySchemaAdapter.ts:2602 takes stop[1] as the colour.',
    );
  });

  test('generated y indices descend while x indices ascend', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'heatmap',
          'z': <Object?>[
            <Object?>[1, 2, 3],
            <Object?>[4, 5, 6],
          ],
        },
      ],
    });
    final points = chart.data.expand((d) => d.data).toList();
    expect(
      points.map((p) => p.y).toSet().toList(),
      <Object>[1, 0],
      reason: 'PlotlySchemaAdapter.ts:2532 generates y as yLen - 1 down to 0.',
    );
    expect(
      points.map((p) => p.x).toSet().toList(),
      <Object>[0, 1, 2],
      reason: 'PlotlySchemaAdapter.ts:2531 generates x as 0 up to xLen - 1.',
    );
    expect(
      points.where((p) => p.x == 0 && p.y == 1).map((p) => p.value).single,
      1,
      reason:
          'PlotlySchemaAdapter.ts:2537 reads z[yIdx][xIdx], so the '
          'top-origin row 0 keeps the value it had in the bottom-origin z.',
    );
  });

  test('the injected scalar defaults', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'heatmap',
          'x': <Object?>['a'],
          'y': <Object?>['p'],
          'z': <Object?>[
            <Object?>[1],
          ],
        },
      ],
    });
    expect(
      chart.props.hideLegend,
      isTrue,
      reason: 'PlotlySchemaAdapter.ts:2609.',
    );
    expect(
      chart.props.showYAxisLables,
      isTrue,
      reason: 'PlotlySchemaAdapter.ts:2610.',
    );
    expect(
      chart.sortAlphabetically,
      isFalse,
      reason:
          "PlotlySchemaAdapter.ts:2611 sends sortOrder: 'none', which "
          'HeatMapChart.tsx:648 reads as "do not sort" — '
          'heat_map_chart.dart:667 spells that as sortAlphabetically: false.',
    );
    expect(
      chart.props.hideTickOverlap,
      isTrue,
      reason: 'PlotlySchemaAdapter.ts:2614.',
    );
    expect(
      chart.props.noOfCharsToTruncate,
      20,
      reason: 'PlotlySchemaAdapter.ts:2615.',
    );
    expect(
      chart.props.showYAxisLablesTooltip,
      isTrue,
      reason: 'PlotlySchemaAdapter.ts:2616.',
    );
  });

  test('the diverging, sequential and sequential-minus selections', () {
    const diverging = '#111111';
    const sequential = '#222222';
    const sequentialMinus = '#333333';
    Map<String, Object?> figure(List<Object?> z) => <String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'heatmap',
          'z': <Object?>[z],
          'colorscale': <String, Object?>{
            'diverging': <Object?>[
              <Object?>[0, diverging],
            ],
            'sequential': <Object?>[
              <Object?>[0, sequential],
            ],
            'sequentialminus': <Object?>[
              <Object?>[0, sequentialMinus],
            ],
          },
        },
      ],
    };

    expect(
      build(figure(<Object?>[-1, 1])).rangeValuesForColorScale,
      <Color>[const Color(0xFF111111)],
      reason:
          'PlotlySchemaAdapter.ts:2584 — zMin < 0 && zMax > 0 is '
          'divergent.',
    );
    expect(
      build(figure(<Object?>[0, 5])).rangeValuesForColorScale,
      <Color>[const Color(0xFF222222)],
      reason:
          'PlotlySchemaAdapter.ts:2585 — zMin >= 0 is sequential, and 0 '
          'counts as entirely positive.',
    );
    expect(
      build(figure(<Object?>[-5, 0])).rangeValuesForColorScale,
      <Color>[const Color(0xFF333333)],
      reason: 'PlotlySchemaAdapter.ts:2586 — zMax <= 0 is sequentialminus.',
    );
    expect(
      build(figure(<Object?>[-1, 1])).domainValuesForColorScale,
      <double>[-1],
      reason:
          'PlotlySchemaAdapter.ts:2598 rescales the selected ramp onto the '
          "data's own extent, so stop 0 lands on zMin.",
    );
  });

  test('the colorscale falls back through the layout and the template', () {
    Map<String, Object?> figure(Map<String, Object?> layout) =>
        <String, Object?>{
          'data': <Object?>[
            <String, Object?>{
              'type': 'heatmap',
              'z': <Object?>[
                <Object?>[1],
              ],
            },
          ],
          'layout': layout,
        };
    List<Object?> ramp(String hex) => <Object?>[
      <Object?>[0, hex],
    ];

    expect(
      build(
        figure(<String, Object?>{'colorscale': ramp('#010101')}),
      ).rangeValuesForColorScale,
      <Color>[const Color(0xFF010101)],
      reason: 'PlotlySchemaAdapter.ts:2572, the second fallback.',
    );
    expect(
      build(
        figure(<String, Object?>{
          'coloraxis': <String, Object?>{'colorscale': ramp('#020202')},
        }),
      ).rangeValuesForColorScale,
      <Color>[const Color(0xFF020202)],
      reason: 'PlotlySchemaAdapter.ts:2573, the third.',
    );
    expect(
      build(
        figure(<String, Object?>{
          'template': <String, Object?>{
            'layout': <String, Object?>{'colorscale': ramp('#030303')},
          },
        }),
      ).rangeValuesForColorScale,
      <Color>[const Color(0xFF030303)],
      reason: 'PlotlySchemaAdapter.ts:2574, the fourth.',
    );
    expect(
      build(
        figure(<String, Object?>{
          'template': <String, Object?>{
            'data': <String, Object?>{
              'heatmap': <Object?>[
                <String, Object?>{'colorscale': ramp('#040404')},
              ],
            },
          },
        }),
      ).rangeValuesForColorScale,
      <Color>[const Color(0xFF040404)],
      reason:
          'PlotlySchemaAdapter.ts:2576, the sixth and last — reachable '
          'here but NOT upstream for a heatmap trace, because :2575 '
          'contributes the boolean `false` when the type test fails and '
          "JavaScript's ?? passes `false` straight through. Plan 09 task 24's "
          'Step 3 Dart writes the arm as a conditional yielding null, which '
          'revives the dead branch; this pins the plan, not upstream.',
    );
  });

  test('layout annotations are re-projected by rank and stripped of markup', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'heatmap',
          'z': <Object?>[
            <Object?>[5, 6],
          ],
        },
      ],
      'layout': <String, Object?>{
        'annotations': <Object?>[
          // The coordinates are 7 and 9, not 0 and 1: only their RANK among the
          // distinct annotation x values reaches the grid.
          <String, Object?>{'x': 9, 'y': 3, 'text': '<b>right</b>'},
          <String, Object?>{'x': 7, 'y': 3, 'text': 'left'},
          // Dropped: a secondary-axis reference (`:2427-2428`).
          <String, Object?>{'x': 7, 'y': 3, 'xref': 'x2', 'text': 'ignored'},
        ],
      },
    });
    final points = chart.data.single.data;
    expect(
      points.map((p) => p.rectText).toList(),
      <Object?>['left', 'right'],
      reason:
          'PlotlySchemaAdapter.ts:2443-2448 keys the grid by the rank of '
          'each distinct annotation coordinate, and :2432 runs the text '
          'through cleanText first, so the <b> wrapper is gone.',
    );
    expect(
      points.map((p) => p.value).toList(),
      <double>[5, 6],
      reason:
          'PlotlySchemaAdapter.ts:2545 — an annotation replaces the cell '
          'TEXT only, never the value the colour is interpolated from.',
    );
  });

  test('a histogram2d figure is binned, counted and normalised', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'histogram2d',
          'x': <Object?>['a', 'b', 'a'],
          'y': <Object?>['p', 'p', 'q'],
        },
      ],
    });
    final cells = <(Object, Object), double>{
      for (final point in chart.data.single.data)
        (point.x, point.y): point.value,
    };
    expect(
      cells,
      <(Object, Object), double>{
        ('a', 'p'): 1,
        ('a', 'q'): 1,
        ('b', 'p'): 1,
        ('b', 'q'): 0,
      },
      reason:
          'PlotlySchemaAdapter.ts:2456-2519 crosses the two string bin '
          'sets, and the default histfunc is a count (:3454), so the pair no '
          'observation reaches is 0 rather than absent.',
    );
    expect(
      chart.domainValuesForColorScale,
      <double>[0, 0.5, 1],
      reason:
          'PlotlySchemaAdapter.ts:2514-2517 tracks zMin and zMax over the '
          'binned cells, not over the raw z column.',
    );
  });

  test('cleanPlotlyText strips the four markup forms upstream strips', () {
    expect(
      cleanPlotlyText('&lt;b&gt;bold&lt;/b&gt;'),
      'bold',
      reason: 'PlotlySchemaAdapter.ts:2842, the entity-escaped tag pass.',
    );
    expect(
      cleanPlotlyText('<i>one</i><br>two'),
      'onetwo',
      reason:
          'PlotlySchemaAdapter.ts:2843-2844: the real-tag pass eats <i> '
          'and <br> alike, so the line break leaves no separator behind.',
    );
    expect(
      cleanPlotlyText(r'  a $x^2$ b  '),
      r'a $ b',
      reason:
          r'PlotlySchemaAdapter.ts:2845-2846 collapses a TeX span to a '
          'single dollar sign and then trims — upstream behaviour, not a typo.',
    );
  });

  testWidgets('a real FluentHeatMapChart consumes what the transformer built', (
    tester,
  ) async {
    // The grid a transformer nothing calls cannot be caught by a unit test on
    // its return value alone: this pumps the widget the transformer names and
    // reads the cells back off the delegate that paints them.
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'heatmap',
          // 'b' before 'a' on purpose: alphabetical sorting would swap them.
          'x': <Object?>['b', 'a'],
          'y': <Object?>['q', 'p'],
          'z': <Object?>[
            <Object?>[1, 2],
            <Object?>[3, 4],
          ],
        },
      ],
    });
    await tester.pumpWidget(
      FluentApp(
        theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
        home: Center(child: SizedBox(width: 480, height: 320, child: chart)),
      ),
    );

    final delegate =
        tester
                .widget<FluentCartesianChart>(find.byType(FluentCartesianChart))
                .delegate
            as FluentHeatMapChartDelegate;
    expect(
      delegate.dataSet.xAxisPoints,
      <String>['b', 'a'],
      reason:
          "PlotlySchemaAdapter.ts:2611's sortOrder: 'none' has to reach the "
          'painted grid, not merely the props bag — alphabetical sorting '
          'would answer [a, b] here (HeatMapChart.tsx:648).',
    );
    expect(
      delegate.dataSet.rows['p']!['a']!.value,
      4,
      reason:
          'PlotlySchemaAdapter.ts:2537 pairs z[yIdx][xIdx] with xData[xIdx] '
          'and yData[yIdx], so the second row and second column is 4.',
    );
    expect(
      delegate.domainValues,
      <double>[1, 2.5, 4],
      reason:
          'PlotlySchemaAdapter.ts:2563 — the colour scale the transformer '
          'derived is the one the delegate interpolates cell fills from.',
    );
  });
}
