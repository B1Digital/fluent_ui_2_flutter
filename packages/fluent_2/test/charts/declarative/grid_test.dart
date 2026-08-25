import 'package:fluent_2/src/charts/internal/plotly/grid.dart';
import 'package:fluent_2/src/charts/internal/plotly/json_guard.dart';
import 'package:fluent_2/src/charts/internal/plotly/router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const noTraces = <FluentPlotlyTraceInfo>[];

  test('a single plot short-circuits to one row and one column', () {
    final grid = getGridProperties(
      <String, Object?>{'data': <Object?>[]},
      isMultiPlot: false,
      traces: noTraces,
    );
    expect(grid.rowCount, 1, reason: 'PlotlySchemaAdapter.ts:3654-3659.');
    expect(grid.columnCount, 1, reason: 'PlotlySchemaAdapter.ts:3654-3659.');
    expect(
      grid.layout,
      isEmpty,
      reason: 'PlotlySchemaAdapter.ts:3658 returns an empty layout.',
    );
  });

  test('a multi-plot figure that solved no domain is not degenerate', () {
    final grid = getGridProperties(
      <String, Object?>{
        'data': <Object?>[],
        'layout': <String, Object?>{'title': 'no axes declared'},
      },
      isMultiPlot: true,
      traces: noTraces,
    );
    expect(
      grid.rowCount,
      1,
      reason:
          'PlotlySchemaAdapter.ts:3793 never runs with an empty domainY, so '
          'the count keeps the value :3654 seeded.',
    );
    expect(
      grid.columnCount,
      1,
      reason: 'PlotlySchemaAdapter.ts:3762 never runs either.',
    );
    expect(
      grid.isSingleRepeat,
      isFalse,
      reason:
          'PlotlySchemaAdapter.ts:3654-3655 seeds both templates to `1fr`, '
          'and only :3774 and :3807 overwrite them with `repeat(N, 1fr)`. '
          '`1fr` is NOT SINGLE_REPEAT (:103), so DeclarativeChart.tsx:513-514 '
          'does NOT collapse this figure — a distinction `rowCount == 1 && '
          'columnCount == 1` cannot draw, because both are 1 here too.',
    );
  });

  test('a solved one-by-one grid is degenerate', () {
    final grid = getGridProperties(
      <String, Object?>{
        'data': <Object?>[],
        'layout': <String, Object?>{
          'xaxis': <String, Object?>{
            'domain': <Object?>[0, 1],
            'anchor': 'y',
          },
          'yaxis': <String, Object?>{
            'domain': <Object?>[0, 1],
            'anchor': 'x',
          },
        },
      },
      isMultiPlot: true,
      traces: noTraces,
    );
    expect(
      grid.isSingleRepeat,
      isTrue,
      reason:
          'PlotlySchemaAdapter.ts:3774 and :3807 both format `repeat(1, 1fr)` '
          'from one unique interval, which is SINGLE_REPEAT at :103.',
    );
  });

  test('solving one axis and not the other is not degenerate', () {
    final grid = getGridProperties(
      <String, Object?>{
        'data': <Object?>[],
        'layout': <String, Object?>{
          'xaxis': <String, Object?>{
            'domain': <Object?>[0, 1],
            'anchor': 'y',
          },
        },
      },
      isMultiPlot: true,
      traces: noTraces,
    );
    expect(
      grid.isSingleRepeat,
      isFalse,
      reason:
          'PlotlySchemaAdapter.ts:3774 formats `repeat(1, 1fr)` for the one x '
          'interval while :3807 never runs and leaves `1fr`. '
          'DeclarativeChart.tsx:513-514 is an AND over both templates, so one '
          'match is not enough.',
    );
  });

  test('a 1x2 layout numbers its columns left to right', () {
    final grid = getGridProperties(
      <String, Object?>{
        'data': <Object?>[],
        'layout': <String, Object?>{
          'xaxis': <String, Object?>{
            'domain': <Object?>[0, 0.45],
            'anchor': 'y',
          },
          'xaxis2': <String, Object?>{
            'domain': <Object?>[0.55, 1],
            'anchor': 'y2',
          },
          'yaxis': <String, Object?>{
            'domain': <Object?>[0, 1],
            'anchor': 'x',
          },
          'yaxis2': <String, Object?>{
            'domain': <Object?>[0, 1],
            'anchor': 'x2',
          },
        },
      },
      isMultiPlot: true,
      traces: noTraces,
    );
    expect(
      grid.columnCount,
      2,
      reason: 'PlotlySchemaAdapter.ts:3774 counts unique x intervals.',
    );
    expect(
      grid.layout['x']!.column,
      1,
      reason: 'PlotlySchemaAdapter.ts:3777-3778, 1-based.',
    );
    expect(
      grid.layout['x2']!.column,
      2,
      reason: 'PlotlySchemaAdapter.ts:3777-3778.',
    );
  });

  test('rows are reversed because Plotly y is bottom-origin', () {
    final grid = getGridProperties(
      <String, Object?>{
        'data': <Object?>[],
        'layout': <String, Object?>{
          'xaxis': <String, Object?>{
            'domain': <Object?>[0, 1],
            'anchor': 'y',
          },
          'xaxis2': <String, Object?>{
            'domain': <Object?>[0, 1],
            'anchor': 'y2',
          },
          'yaxis': <String, Object?>{
            'domain': <Object?>[0, 0.45],
            'anchor': 'x',
          },
          'yaxis2': <String, Object?>{
            'domain': <Object?>[0.55, 1],
            'anchor': 'x2',
          },
        },
      },
      isMultiPlot: true,
      traces: noTraces,
    );
    expect(grid.rowCount, 2, reason: 'PlotlySchemaAdapter.ts:3805.');
    expect(
      grid.layout['x']!.row,
      2,
      reason:
          'PlotlySchemaAdapter.ts:3810: the y domain starting at 0 is the '
          'BOTTOM row, so its CSS row number is numberOfRows - rowIndex = '
          '2 - 0 = 2.',
    );
    expect(grid.layout['x2']!.row, 1, reason: 'PlotlySchemaAdapter.ts:3810.');
  });

  test('the interval starts are sorted as strings, not as numbers', () {
    final grid = getGridProperties(
      <String, Object?>{
        'data': <Object?>[],
        'layout': <String, Object?>{
          'xaxis': <String, Object?>{
            'domain': <Object?>[0.1, 0.4],
            'anchor': 'y',
          },
          'xaxis2': <String, Object?>{
            'domain': <Object?>[0.05, 0.09],
            'anchor': 'y2',
          },
          'yaxis': <String, Object?>{
            'domain': <Object?>[0, 1],
            'anchor': 'x',
          },
          'yaxis2': <String, Object?>{
            'domain': <Object?>[0, 1],
            'anchor': 'x2',
          },
        },
      },
      isMultiPlot: true,
      traces: noTraces,
    );
    // The plan asserted the opposite here — `x` first — on the reading that
    // `'0.1' < '0.05'` is false "at the third character". It is false, but the
    // comparison it decides is `'0.05' < '0.1'`, which is TRUE: the third
    // characters are `0` and `1`, and `0` is the smaller. `node -e
    // "[0.1,0.05].sort()"` prints `[0.05,0.1]`. For any pair of plain-decimal
    // fractions in [0, 1] the string order and the numeric order agree,
    // because every rendering shares the same one-digit integer part; this
    // case therefore pins ordering, and the next test pins the divergence.
    expect(
      grid.layout['x2']!.column,
      1,
      reason:
          'PlotlySchemaAdapter.ts:3772 sorts the starts, and 0.05 precedes '
          '0.1 under both a string and a numeric comparison.',
    );
    expect(
      grid.layout['x']!.column,
      2,
      reason: 'Same sort, PlotlySchemaAdapter.ts:3777-3778.',
    );
  });

  test('a start V8 renders in exponent form sorts after every 0.x start', () {
    final grid = getGridProperties(
      <String, Object?>{
        'data': <Object?>[],
        'layout': <String, Object?>{
          // 1e-7 is below the 1e-6 threshold at which V8 switches `String()`
          // to exponent notation, which is where a string sort and a numeric
          // sort finally disagree.
          'xaxis': <String, Object?>{
            'domain': <Object?>[1e-7, 0.4],
            'anchor': 'y',
          },
          'xaxis2': <String, Object?>{
            'domain': <Object?>[0.5, 1],
            'anchor': 'y2',
          },
          'yaxis': <String, Object?>{
            'domain': <Object?>[0, 1],
            'anchor': 'x',
          },
          'yaxis2': <String, Object?>{
            'domain': <Object?>[0, 1],
            'anchor': 'x2',
          },
        },
      },
      isMultiPlot: true,
      traces: noTraces,
    );
    expect(
      grid.layout['x']!.column,
      2,
      reason:
          'parity: PlotlySchemaAdapter.ts:3772 calls Array.prototype.sort() '
          'with no comparator, so the starts are compared as strings and '
          "'1e-7' sorts AFTER '0.5'. The leftmost sub-plot in the figure is "
          'therefore given the RIGHTMOST column, and a numeric sort here '
          'would put this chart in a different cell than the browser does.',
    );
    expect(
      grid.layout['x2']!.column,
      1,
      reason: 'Same lexicographic sort: 0.5 renders as the smaller string.',
    );
  });

  test('a mismatched x anchor throws with the upstream message', () {
    expect(
      () => getGridProperties(
        <String, Object?>{
          'data': <Object?>[],
          'layout': <String, Object?>{
            'xaxis2': <String, Object?>{
              'domain': <Object?>[0, 1],
              'anchor': 'y',
            },
          },
        },
        isMultiPlot: true,
        traces: noTraces,
      ),
      throwsA(
        isA<PlotlySchemaException>().having(
          (e) => e.message,
          'message',
          'Invalid layout: xaxis 2 anchor should be y1',
        ),
      ),
      reason: 'PlotlySchemaAdapter.ts:3670.',
    );
  });

  test('a mismatched y anchor throws with the upstream message', () {
    expect(
      () => getGridProperties(
        <String, Object?>{
          'data': <Object?>[],
          'layout': <String, Object?>{
            'yaxis3': <String, Object?>{
              'domain': <Object?>[0, 1],
              'anchor': 'x',
            },
          },
        },
        isMultiPlot: true,
        traces: noTraces,
      ),
      throwsA(
        isA<PlotlySchemaException>().having(
          (e) => e.message,
          'message',
          'Invalid layout: yaxis 3 anchor should be x1',
        ),
      ),
      reason:
          'PlotlySchemaAdapter.ts:3688. Index 2 against anchor index 0 misses '
          'both arms of the secondary-y escape at :3684.',
    );
  });

  test('the secondary-y special case does not throw', () {
    final grid = getGridProperties(
      <String, Object?>{
        'data': <Object?>[],
        'layout': <String, Object?>{
          'xaxis': <String, Object?>{
            'domain': <Object?>[0, 1],
            'anchor': 'y',
          },
          'yaxis': <String, Object?>{
            'domain': <Object?>[0, 1],
            'anchor': 'x',
          },
          'yaxis2': <String, Object?>{
            'domain': <Object?>[0, 1],
            'anchor': 'x',
            'side': 'right',
          },
        },
      },
      isMultiPlot: true,
      traces: noTraces,
    );
    expect(
      grid.columnCount,
      1,
      reason:
          'PlotlySchemaAdapter.ts:3684-3687 early-returns for a right-side '
          'yaxis2.',
    );
  });

  test('the secondary-y escape skips one key rather than the whole solve', () {
    final grid = getGridProperties(
      <String, Object?>{
        'data': <Object?>[],
        'layout': <String, Object?>{
          'xaxis': <String, Object?>{
            'domain': <Object?>[0, 0.45],
            'anchor': 'y',
          },
          'yaxis': <String, Object?>{
            'domain': <Object?>[0, 1],
            'anchor': 'x',
          },
          'yaxis2': <String, Object?>{
            'domain': <Object?>[0, 1],
            'anchor': 'x',
            'side': 'right',
          },
          'xaxis3': <String, Object?>{
            'domain': <Object?>[0.55, 1],
            'anchor': 'y3',
          },
          'yaxis3': <String, Object?>{
            'domain': <Object?>[0, 1],
            'anchor': 'x3',
          },
        },
      },
      isMultiPlot: true,
      traces: noTraces,
    );
    expect(
      grid.columnCount,
      2,
      reason:
          'parity: PlotlySchemaAdapter.ts:3686 returns from a forEach '
          'callback, so the returned object is discarded and only the '
          'yaxis2 key is skipped. Returning from the whole solver there '
          'would drop xaxis3 and leave one column.',
    );
    expect(
      grid.layout.keys,
      containsAll(<String>['x', 'x2']),
      reason:
          'The two surviving x intervals still take the :3676 cell names, '
          'and the skipped yaxis2 consumed no y slot: `x2` is xaxis3.',
    );
  });

  test('a non-plot trace takes its cell from series.domain, defaulting to '
      'the full square', () {
    final grid = getGridProperties(
      <String, Object?>{
        'data': <Object?>[
          <String, Object?>{
            'type': 'pie',
            'domain': <String, Object?>{
              'x': <Object?>[0, 0.5],
              'y': <Object?>[0, 1],
            },
          },
          <String, Object?>{'type': 'pie'},
        ],
      },
      isMultiPlot: true,
      traces: const <FluentPlotlyTraceInfo>[
        FluentPlotlyTraceInfo(index: 0, kind: FluentPlotlyChartKind.donut),
        FluentPlotlyTraceInfo(index: 1, kind: FluentPlotlyChartKind.donut),
      ],
    );
    expect(
      grid.layout.keys,
      containsAll(<String>['nonplot_1', 'nonplot_2']),
      reason:
          'PlotlySchemaAdapter.ts:3702-3718 keys non-plot cells with '
          'NON_PLOT_KEY_PREFIX.',
    );
    expect(
      grid.layout['nonplot_2']!.xDomain.end,
      1,
      reason:
          'PlotlySchemaAdapter.ts:3707 defaults a missing domain to [0, 1].',
    );
    expect(
      grid.layout['nonplot_1']!.xDomain.end,
      0.5,
      reason: 'PlotlySchemaAdapter.ts:3706-3707 reads the declared domain.',
    );
  });

  test('a non-plot cell is numbered past the cartesian axes it follows', () {
    final grid = getGridProperties(
      <String, Object?>{
        'data': <Object?>[
          <String, Object?>{'type': 'scatter'},
          <String, Object?>{'type': 'pie'},
        ],
        'layout': <String, Object?>{
          'xaxis': <String, Object?>{
            'domain': <Object?>[0, 1],
            'anchor': 'y',
          },
          'yaxis': <String, Object?>{
            'domain': <Object?>[0, 1],
            'anchor': 'x',
          },
        },
      },
      isMultiPlot: true,
      traces: const <FluentPlotlyTraceInfo>[
        FluentPlotlyTraceInfo(index: 0, kind: FluentPlotlyChartKind.line),
        FluentPlotlyTraceInfo(index: 1, kind: FluentPlotlyChartKind.donut),
      ],
    );
    expect(
      grid.layout.keys,
      containsAll(<String>['x', 'nonplot_1']),
      reason:
          'PlotlySchemaAdapter.ts:3708 subtracts cartesianDomains, so the '
          'first non-plot cell after one cartesian pair is nonplot_1, not '
          'nonplot_2.',
    );
  });

  test('a polar sub-plot takes its own layout key as its cell name', () {
    final grid = getGridProperties(
      <String, Object?>{
        'data': <Object?>[],
        'layout': <String, Object?>{
          'polar': <String, Object?>{
            'domain': <String, Object?>{
              'x': <Object?>[0, 0.45],
              'y': <Object?>[0, 1],
            },
          },
          'polar2': <String, Object?>{
            'domain': <String, Object?>{
              'x': <Object?>[0.55, 1],
              'y': <Object?>[0, 1],
            },
          },
        },
      },
      isMultiPlot: true,
      traces: noTraces,
    );
    expect(
      grid.layout['polar2']!.column,
      2,
      reason:
          'PlotlySchemaAdapter.ts:3722-3736 keys a polar cell by its raw '
          'layout key and feeds its domain through the same solver.',
    );
    expect(
      grid.layout['polar']!.row,
      1,
      reason:
          'PlotlySchemaAdapter.ts:3810 with one unique y interval: '
          '1 - 0 = 1.',
    );
  });

  test('a layout annotation attaches to the cell whose domains contain it', () {
    final grid = getGridProperties(
      <String, Object?>{
        'data': <Object?>[],
        'layout': <String, Object?>{
          'xaxis': <String, Object?>{
            'domain': <Object?>[0, 1],
            'anchor': 'y',
          },
          'yaxis': <String, Object?>{
            'domain': <Object?>[0, 1],
            'anchor': 'x',
          },
          'annotations': <Object?>[
            <String, Object?>{'x': 0.5, 'y': 0.5, 'text': 'across'},
            <String, Object?>{
              'x': 0.5,
              'y': 0.5,
              'text': 'up',
              'textangle': 90,
            },
          ],
        },
      },
      isMultiPlot: true,
      traces: noTraces,
    );
    expect(
      grid.layout['x']!.xAnnotation,
      'across',
      reason:
          'PlotlySchemaAdapter.ts:3752-3756: a textangle other than 90 is an '
          'x annotation.',
    );
    expect(
      grid.layout['x']!.yAnnotation,
      'up',
      reason:
          'PlotlySchemaAdapter.ts:3752-3754: textangle 90 is a y '
          'annotation.',
    );
  });

  test('an annotation outside every cell attaches to nothing', () {
    final grid = getGridProperties(
      <String, Object?>{
        'data': <Object?>[],
        'layout': <String, Object?>{
          'xaxis': <String, Object?>{
            'domain': <Object?>[0, 0.4],
            'anchor': 'y',
          },
          'yaxis': <String, Object?>{
            'domain': <Object?>[0, 1],
            'anchor': 'x',
          },
          'annotations': <Object?>[
            <String, Object?>{'x': 0.9, 'y': 0.5, 'text': 'stray'},
          ],
        },
      },
      isMultiPlot: true,
      traces: noTraces,
    );
    expect(
      grid.layout['x']!.xAnnotation,
      isNull,
      reason:
          'PlotlySchemaAdapter.ts:3749 skips an annotation whose yMatch is '
          '-1, and 0.9 is outside the only x domain.',
    );
  });

  group('plotlyNumberToString reproduces V8 String(number)', () {
    // Each expectation was read from `node -e "console.log(String(v))"`. A
    // list of pairs rather than a map, because 0.0 and -0.0 compare equal and
    // would collide as keys.
    const cases = <(double, String)>[
      (0, '0'),
      (1, '1'),
      (0.5, '0.5'),
      (0.45, '0.45'),
      (0.05, '0.05'),
      (0.09, '0.09'),
      (1e-7, '1e-7'),
      (-0.0, '0'),
      (0.1, '0.1'),
    ];
    for (final entry in cases) {
      test('${entry.$1} renders as ${entry.$2}', () {
        expect(
          plotlyNumberToString(entry.$1),
          entry.$2,
          reason:
              'PlotlySchemaAdapter.ts:3765 builds the dedup key and :3772 '
              'sorts from this rendering, so a Dart `1.0` or `-0` here would '
              'change which cell a chart lands in.',
        );
      });
    }
    test('the case table covers every rendering branch', () {
      expect(
        cases.length,
        9,
        reason:
            'Guards the loop above: integral, fractional, exponent and '
            'negative-zero forms are all present, and a silently emptied '
            'table would otherwise assert nothing.',
      );
    });
  });

  test('isNonPlotType names the seven upstream types it can spell', () {
    expect(
      <FluentPlotlyChartKind>[
        FluentPlotlyChartKind.donut,
        FluentPlotlyChartKind.sankey,
        FluentPlotlyChartKind.annotation,
        FluentPlotlyChartKind.table,
        FluentPlotlyChartKind.gauge,
      ].every(isNonPlotType),
      isTrue,
      reason:
          'PlotlySchemaAdapter.ts:3638 lists donut, sankey, pie, annotation, '
          'table, gauge and funnel; pie and funnel have no '
          'FluentPlotlyChartKind spelling.',
    );
    expect(
      <FluentPlotlyChartKind>[
        FluentPlotlyChartKind.line,
        FluentPlotlyChartKind.area,
        FluentPlotlyChartKind.scatter,
        FluentPlotlyChartKind.heatmap,
        FluentPlotlyChartKind.scatterPolar,
      ].any(isNonPlotType),
      isFalse,
      reason: 'Everything cartesian is laid out from an axis pair instead.',
    );
  });
}
