// The Plotly scatter-trace core: one shared body behind three wrappers
// (`PlotlySchemaAdapter.ts:1979-2212`).
//
// FOUR CORRECTIONS to this task's Step 1 test, each forced by the shipped API
// rather than by preference:
//
//  1. `chart.supportNegativeData`, `chart.hideTickOverlap`, `chart.useUTC`,
//     `chart.showYAxisLables`, `chart.roundedTicks` and
//     `chart.showYAxisLablesTooltip` are not members of the three chart
//     widgets. Plan 09 task 18's own audit correction says so outright — every
//     axis setting lives on `FluentCartesianChartProps` — so they are asserted
//     through `props`. `supportNegativeData` is dropped entirely: no chart in
//     this package declares it, in props or anywhere else.
//  2. `chart.height` cannot be asserted at all. Plan 09 task 28 states that a
//     shell chart's height reaches it as an enclosing `SizedBox` sized from
//     `kPlotlyDefaultCellHeight`, which task 28 owns; the transformer returns
//     the bare chart. `PlotlySchemaAdapter.ts:2172`'s 350 is that table's
//     entry, not this file's.
//  3. `lineOptions` is NOT null on a text mode. `:2067-2083` spreads
//     `...(lineOptions ?? {})` and then always writes `mode`, so the object
//     survives with its stroke fields empty — and it must, because
//     `line_chart.dart:1336` reads `lineOptions.mode.text` to draw the point
//     labels at all. A null here would silently un-draw them.
//  4. `bars.single.startX` is asserted as `bars.single.data.single.startX`:
//     `FluentColorFillBar` holds a list of `FluentColorFillBarRange`
//     (`line_chart.dart:622-659`), matching upstream's `data: [{startX, endX}]`
//     at `:1973`.
import 'dart:ui' as ui;

import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:fluent_2_web/src/charts/internal/plotly/transform_xy.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FluentLineChart line(Map<String, Object?> input) => transformPlotlyToLine(
    input,
    isMultiPlot: false,
    colorMap: <String, String>{},
    colorwayType: FluentPlotlyColorway.byDefault,
    isDark: false,
  );

  FluentAreaChart area(Map<String, Object?> input) => transformPlotlyToArea(
    input,
    isMultiPlot: false,
    colorMap: <String, String>{},
    colorwayType: FluentPlotlyColorway.byDefault,
    isDark: false,
  );

  FluentScatterChart scatter(Map<String, Object?> input) =>
      transformPlotlyToScatter(
        input,
        isMultiPlot: false,
        colorMap: <String, String>{},
        colorwayType: FluentPlotlyColorway.byDefault,
        isDark: false,
      );

  final basic = <String, Object?>{
    'data': <Object?>[
      <String, Object?>{
        'type': 'scatter',
        'mode': 'lines',
        'name': 's1',
        'x': <Object?>[1, 2, 3],
        'y': <Object?>[4, 5, 6],
      },
    ],
  };

  test('the injected scalar defaults', () {
    final chart = line(basic);
    expect(
      chart.props.hideTickOverlap,
      isTrue,
      reason: 'PlotlySchemaAdapter.ts:2173.',
    );
    expect(
      chart.props.useUTC,
      isFalse,
      reason:
          'PlotlySchemaAdapter.ts:2175; parseLocalDate builds local dates so '
          'the axis must not re-interpret them as UTC.',
    );
    expect(
      chart.props.showYAxisLables,
      isTrue,
      reason: 'PlotlySchemaAdapter.ts:2177.',
    );
    expect(
      chart.props.roundedTicks,
      isTrue,
      reason: 'PlotlySchemaAdapter.ts:2178.',
    );
    expect(
      chart.data.lineChartData!.single.legend,
      's1',
      reason:
          'PlotlySchemaAdapter.ts:2020 reads the legend out of getLegendProps, '
          'which returns `data[0].name` for a single trace '
          '(PlotlySchemaAdapter.ts:3572).',
    );
  });

  test('optimizeLargeData flips above one thousand points', () {
    final small = line(basic);
    expect(
      small.optimizeLargeData,
      isFalse,
      reason:
          'PlotlySchemaAdapter.ts:2176 requires strictly more than 1000 points.',
    );
    final big = line(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'scatter',
          'mode': 'lines',
          // 1001 is the smallest count that clears the `> 1000` test.
          'x': <Object?>[for (var i = 0; i < 1001; i++) i],
          'y': <Object?>[for (var i = 0; i < 1001; i++) i],
        },
      ],
    });
    expect(
      big.optimizeLargeData,
      isTrue,
      reason: 'PlotlySchemaAdapter.ts:2176.',
    );
  });

  test('a dashed line carries its dash options through to the series', () {
    final chart = line(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'scatter',
          'mode': 'lines',
          'name': 's1',
          'x': <Object?>[1, 2],
          'y': <Object?>[1, 2],
          'line': <String, Object?>{'dash': 'dashdot'},
        },
      ],
    });
    expect(
      chart.data.lineChartData!.single.lineOptions!.strokeDasharray,
      '5, 5, 1, 5',
      reason: 'PlotlySchemaAdapter.ts:3339 spreads dashOptions[line.dash].',
    );
  });

  test('a text mode keeps the mode but drops the stroke options', () {
    final chart = line(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'scatter',
          'mode': 'lines+text',
          'name': 's1',
          'x': <Object?>[1, 2],
          'y': <Object?>[1, 2],
          'line': <String, Object?>{'dash': 'dot'},
        },
      ],
    });
    final options = chart.data.lineChartData!.single.lineOptions;
    expect(
      options!.strokeDasharray,
      isNull,
      reason:
          'PlotlySchemaAdapter.ts:2034 skips getLineOptions when the mode '
          'contains text, so nothing from dashOptions reaches the series.',
    );
    expect(
      options.mode!.text,
      isTrue,
      reason:
          'PlotlySchemaAdapter.ts:2069 writes `mode` onto the spread '
          'regardless, '
          'and line_chart.dart:1336 reads it to draw the point labels.',
    );
  });

  test('an area trace chooses tozeroy only when fill says so', () {
    FluentAreaChart withFill(String? fill) => area(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'scatter',
          'mode': 'lines',
          'fill': ?fill,
          'x': <Object?>[1, 2],
          'y': <Object?>[1, 2],
        },
      ],
    });
    expect(
      withFill('tozeroy').mode,
      FluentAreaChartMode.toZeroY,
      reason: 'PlotlySchemaAdapter.ts:2031.',
    );
    expect(
      withFill('tonexty').mode,
      FluentAreaChartMode.toNextY,
      reason: 'PlotlySchemaAdapter.ts:2031.',
    );
    expect(
      withFill(null).mode,
      FluentAreaChartMode.toNextY,
      reason: 'PlotlySchemaAdapter.ts:2031 default arm.',
    );
  });

  test('a scatter chart adds the y-axis label tooltip the other two do not', () {
    final chart = scatter(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'scatter',
          'mode': 'markers',
          'x': <Object?>[1, 2],
          'y': <Object?>[1, 2],
        },
      ],
    });
    expect(
      chart.props.showYAxisLablesTooltip,
      isTrue,
      reason:
          'PlotlySchemaAdapter.ts:2201; the line and area transformers omit it.',
    );
    expect(
      chart.data.scatterChartData,
      isNotNull,
      reason:
          'PlotlySchemaAdapter.ts:2196 hands the scatter branch '
          'scatterChartProps, built at :2162-2164.',
    );
    expect(
      line(basic).props.showYAxisLablesTooltip,
      isFalse,
      reason:
          'PlotlySchemaAdapter.ts:2199 gates the tooltip on isScatterChart.',
    );
  });

  test('a pinned y range reaches a line chart but never an area chart', () {
    final schema = <String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'scatter',
          'mode': 'lines',
          'x': <Object?>[1, 2],
          'y': <Object?>[1, 2],
        },
      ],
      'layout': <String, Object?>{
        'xaxis': <String, Object?>{
          'range': <Object?>[0, 8],
        },
        'yaxis': <String, Object?>{
          'range': <Object?>[-3, 30],
        },
      },
    };
    final lineChart = line(schema);
    final areaChart = area(schema);
    expect(
      lineChart.props.yMinValue,
      -3,
      reason: 'PlotlySchemaAdapter.ts:2150 and :2198.',
    );
    expect(
      lineChart.props.yMaxValue,
      30,
      reason: 'PlotlySchemaAdapter.ts:2150 and :2198.',
    );
    expect(
      areaChart.props.yMaxValue,
      isNot(30),
      reason:
          'PlotlySchemaAdapter.ts:2188-2193 returns commonProps alone, so the '
          'area branch never sees the y range. // parity',
    );
    expect(
      areaChart.props.xMaxValue,
      8,
      reason:
          'PlotlySchemaAdapter.ts:2179 puts the x range in commonProps, so the '
          'area branch does get that one.',
    );
  });

  test('with no pinned range the y bounds come from the data', () {
    final chart = line(basic);
    expect(
      (chart.props.yMinValue, chart.props.yMaxValue),
      (4, 6),
      reason:
          'PlotlySchemaAdapter.ts:2151-2154 falls back to findNumericMinMaxOfY '
          'over the built series, whose y column is 4, 5, 6.',
    );
  });

  test('a layout line shape becomes a colour-fill bar', () {
    final bars = mapColorFillBars(<String, Object?>{
      'shapes': <Object?>[
        <String, Object?>{
          'type': 'rect',
          'x0': 1,
          'x1': 2,
          'fillcolor': '#ff0000',
        },
      ],
    });
    expect(
      bars!.single.data.single.startX,
      1,
      reason: 'PlotlySchemaAdapter.ts:1959-1977 reads x0/x1 from rect shapes.',
    );
    expect(
      bars.single.color,
      const Color(0xFFFF0000),
      reason: 'PlotlySchemaAdapter.ts:1972 keeps the shape fillcolor.',
    );
  });

  test('a rect shape with a string edge drops every bar', () {
    final bars = mapColorFillBars(<String, Object?>{
      'shapes': <Object?>[
        <String, Object?>{
          'type': 'rect',
          'x0': 1,
          'x1': 2,
          'fillcolor': '#ff0000',
        },
        <String, Object?>{
          'type': 'rect',
          'x0': 'Mon',
          'x1': 'Tue',
          'fillcolor': '#00ff00',
        },
      ],
    });
    expect(
      bars,
      isNull,
      reason:
          'PlotlySchemaAdapter.ts:1967-1970 maps a string edge to null and '
          ':2208 drops the WHOLE list when it contains one.',
    );
  });

  test('the colour-fill bars reach the line chart and not the scatter one', () {
    final schema = <String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'scatter',
          'mode': 'lines',
          'x': <Object?>[1, 2],
          'y': <Object?>[1, 2],
        },
      ],
      'layout': <String, Object?>{
        'shapes': <Object?>[
          <String, Object?>{
            'type': 'rect',
            'x0': 1,
            'x1': 2,
            'fillcolor': '#ff0000',
          },
        ],
      },
    };
    expect(
      line(schema).colorFillBars.single.data.single.endX,
      2,
      reason: 'PlotlySchemaAdapter.ts:2205-2209.',
    );
    expect(
      scatter(schema).data.scatterChartData,
      isNotNull,
      reason:
          'PlotlySchemaAdapter.ts:2205 gates colorFillBars on !isScatterChart, '
          'and FluentScatterChart takes no such parameter — the guard is the '
          "port's type system.",
    );
  });

  test('a layout line shape becomes a reference series', () {
    final chart = line(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'scatter',
          'mode': 'lines',
          'x': <Object?>[1, 2],
          'y': <Object?>[1, 2],
        },
      ],
      'layout': <String, Object?>{
        'shapes': <Object?>[
          <String, Object?>{
            'type': 'line',
            'x0': 1,
            'x1': 2,
            'y0': 5,
            'y1': 5,
            'line': <String, Object?>{'color': '#0000ff'},
          },
        ],
      },
    });
    expect(
      chart.data.lineChartData!.length,
      2,
      reason:
          'PlotlySchemaAdapter.ts:2158-2160 concatenates the lineShape series '
          'built at :2095-2148 onto the trace series.',
    );
    expect(
      chart.data.lineChartData!.last.legend,
      'Reference_0',
      reason: 'PlotlySchemaAdapter.ts:2139.',
    );
  });

  test('an invalid y splits one trace into two contiguous series', () {
    final chart = line(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'scatter',
          'mode': 'lines',
          'name': 's1',
          'x': <Object?>[1, 2, 3, 4],
          'y': <Object?>[1, null, 3, 4],
        },
      ],
    });
    expect(
      chart.data.lineChartData!.map((series) => series.data.length).toList(),
      <int>[1, 2],
      reason:
          'PlotlySchemaAdapter.ts:2037-2038 maps every range getValidXYRanges '
          '(:3600-3630) returns into its own series, so the hole at index 1 '
          'ends the first run and starts a second at index 2.',
    );
  });

  test('a scatterpolar trace populates the mode and the four polar fields', () {
    final polar = <String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'scatterpolar',
          'mode': 'lines',
          'name': 'p1',
          'x': <Object?>[1, 2],
          'y': <Object?>[1, 2],
          'fill': 'toself',
          '__axisLabel': <Object?>['alpha', 'beta'],
        },
      ],
      'layout': <String, Object?>{
        'polar': <String, Object?>{
          'angularaxis': <String, Object?>{
            'direction': 'clockwise',
            // 90 degrees, the quarter turn scatterpolar-utils.tsx:36 converts
            // to radians.
            'rotation': 90,
          },
        },
        // The projected origin the pre-transform injects
        // (`PlotlySchemaAdapter.ts:2074`).
        '__polarOriginX': 12.5,
      },
    };
    final series = line(polar).data.lineChartData!.single;
    expect(
      series.lineOptions!.mode!.upstreamName,
      'scatterpolar',
      reason:
          'PlotlySchemaAdapter.ts:2069 substitutes the literal scatterpolar '
          'for the trace mode, and line_chart.dart:825 reads exactly that to '
          'decide the chart is polar.',
    );
    expect(
      series.lineOptions!.fill,
      'toself',
      reason:
          'PlotlySchemaAdapter.ts:2080; line_chart.dart:1650 closes and fills '
          'the path from it.',
    );
    expect(
      series.polarLineOptions!.direction,
      'clockwise',
      reason: 'PlotlySchemaAdapter.ts:2075.',
    );
    expect(
      series.polarLineOptions!.rotation,
      90,
      reason: 'PlotlySchemaAdapter.ts:2076.',
    );
    expect(
      series.polarLineOptions!.originXOffset,
      12.5,
      reason: 'PlotlySchemaAdapter.ts:2074.',
    );
    expect(
      series.polarLineOptions!.axisLabel,
      <String>['alpha', 'beta'],
      reason: 'PlotlySchemaAdapter.ts:2077-2079.',
    );
    expect(
      scatter(polar).data.scatterChartData!.single.polarLineOptions!.direction,
      'clockwise',
      reason:
          'scatter_chart.dart:471 reads the same bag off FluentScatterChart'
          'Series, so the scatter wrapper must populate it too.',
    );
  });

  test('an unusable angular direction is normalised away', () {
    final series = line(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'scatterpolar',
          'mode': 'lines',
          'x': <Object?>[1, 2],
          'y': <Object?>[1, 2],
        },
      ],
      'layout': <String, Object?>{
        'polar': <String, Object?>{
          'angularaxis': <String, Object?>{'direction': 'widdershins'},
        },
      },
    }).data.lineChartData!.single;
    expect(
      series.polarLineOptions!.direction,
      isNull,
      reason:
          'scatterpolar-utils.tsx:80-83 keeps only the two known directions, '
          'and FluentPolarLineOptions asserts the same set '
          '(polar_data.dart:74-80).',
    );
  });

  test('a cartesian trace carries no polar bag at all', () {
    expect(
      line(basic).data.lineChartData!.single.polarLineOptions,
      isNull,
      reason:
          'PlotlySchemaAdapter.ts:2072-2082 spreads the four polar members '
          'only when the trace type is scatterpolar.',
    );
  });

  test('a secondary y trace lands on the secondary scale', () {
    final chart = line(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'scatter',
          'mode': 'lines',
          'name': 's1',
          'x': <Object?>[1, 2],
          'y': <Object?>[1, 2],
        },
        <String, Object?>{
          'type': 'scatter',
          'mode': 'lines',
          'name': 's2',
          'yaxis': 'y2',
          'x': <Object?>[1, 2],
          'y': <Object?>[10, 20],
        },
      ],
      'layout': <String, Object?>{
        'yaxis2': <String, Object?>{'side': 'right', 'title': 'right axis'},
      },
    });
    expect(
      chart.data.lineChartData!.last.useSecondaryYScale,
      isTrue,
      reason: 'PlotlySchemaAdapter.ts:2084 and :300-302.',
    );
    expect(
      chart.props.secondaryYAxisTitle,
      'right axis',
      reason: 'PlotlySchemaAdapter.ts:304-355 getSecondaryYAxisValues.',
    );
    expect(
      (
        chart.props.secondaryYScaleOptions!.yMinValue,
        chart.props.secondaryYScaleOptions!.yMaxValue,
      ),
      (10, 20),
      reason:
          'PlotlySchemaAdapter.ts:316-317 takes the min and max of that '
          "trace's own y column, and :330-337 leaves them alone because every "
          'secondary trace is a plain scatter.',
    );
  });

  test('a category x axis produces scatter points inside a line series', () {
    final chart = line(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'scatter',
          'mode': 'lines',
          'x': <Object?>['Mon', 'Tue'],
          'y': <Object?>[1, 2],
        },
      ],
    });
    expect(
      chart.data.lineChartData!.single.data.first,
      isA<FluentScatterChartDataPoint>().having((point) => point.x, 'x', 'Mon'),
      reason:
          'PlotlySchemaAdapter.ts:2055 writes the resolved x straight onto a '
          'LineChartPoints datum, whose x is `number | Date` '
          '(types/DataPoint.ts:340). FluentLineChartSeries.data is the union '
          'upstream declares at types/DataPoint.ts:492, so a category x takes '
          'the scatter arm rather than tripping the line point assertion.',
    );
  });

  testWidgets(
    'a transformed scatterpolar figure draws its category ring when mounted',
    (tester) async {
      Map<String, Object?> figure({
        required bool withLabels,
      }) => <String, Object?>{
        'data': <Object?>[
          <String, Object?>{
            'type': 'scatterpolar',
            'mode': 'lines',
            'name': 'p1',
            // A closed unit triangle in projected cartesian coordinates,
            // which is what the pre-transform hands this function.
            'x': <Object?>[0, 0.5, -0.5, 0],
            'y': <Object?>[1, -0.5, -0.5, 1],
            'fill': 'toself',
            if (withLabels) '__axisLabel': <Object?>['alpha', 'beta', 'gamma'],
          },
        ],
        'layout': <String, Object?>{
          'polar': <String, Object?>{
            'angularaxis': <String, Object?>{
              'direction': 'clockwise',
              'rotation': 90,
            },
          },
          '__polarOriginX': 0,
        },
      };

      Future<int> paragraphsFor({required bool withLabels}) async {
        await tester.pumpWidget(
          FluentApp(
            theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
            home: Center(
              child: SizedBox(
                // A square big enough for the ring to be placed inside the
                // plot area rather than clipped to nothing.
                width: 400,
                height: 400,
                child: line(figure(withLabels: withLabels)),
              ),
            ),
          ),
        );
        final plot = find
            .descendant(
              of: find.byType(FluentCartesianChart),
              matching: find.byType(CustomPaint),
            )
            .first;
        final recorder = _ParagraphCounter();
        tester
            .widget<CustomPaint>(plot)
            .painter!
            .paint(recorder, tester.getSize(plot));
        return recorder.paragraphs;
      }

      final withLabels = await paragraphsFor(withLabels: true);
      final without = await paragraphsFor(withLabels: false);
      expect(
        withLabels - without,
        3,
        reason:
            'the three __axisLabel entries this transformer copies onto '
            'FluentPolarLineOptions (PlotlySchemaAdapter.ts:2077-2079) are '
            'what '
            'scatterpolar-utils.tsx:26 rings around the trace, and '
            'line_chart.dart:1077 is the call that places them. If this is 0 '
            'the polar bag is being built and never read.',
      );
    },
  );

  test('the y callout text is formatted from the axis tick format', () {
    final chart = line(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'scatter',
          'mode': 'lines',
          'x': <Object?>[1],
          'y': <Object?>[0.25],
        },
      ],
      'layout': <String, Object?>{
        'yaxis': <String, Object?>{'tickformat': '.1%'},
      },
    });
    final point =
        chart.data.lineChartData!.single.data.single
            as FluentLineChartDataPoint;
    expect(
      point.yAxisCalloutText,
      '25.0%',
      reason:
          'PlotlySchemaAdapter.ts:2064 calls getFormattedCalloutYData (:253-'
          '261), which runs the y value through d3.format(yaxis.tickformat).',
    );
  });
}

/// Counts the paragraphs a painter draws, which is what a `<text>` node is once
/// `TextPainter.paint` bottoms out.
class _ParagraphCounter implements Canvas {
  int paragraphs = 0;

  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) => paragraphs++;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
