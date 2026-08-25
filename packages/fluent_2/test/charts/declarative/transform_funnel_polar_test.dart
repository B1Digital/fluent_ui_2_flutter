import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2/src/charts/internal/plotly/transform_pie.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FluentFunnelChart funnel(Map<String, Object?> input) =>
      transformPlotlyToFunnel(
        input,
        isMultiPlot: false,
        colorMap: <String, String>{},
        colorwayType: FluentPlotlyColorway.byDefault,
        isDark: false,
      );

  FluentPolarChart polar(Map<String, Object?> input) => transformPlotlyToPolar(
    input,
    isMultiPlot: false,
    colorMap: <String, String>{},
    colorwayType: FluentPlotlyColorway.byDefault,
    isDark: false,
  );

  test('the funnel orientation is inverted relative to Plotly', () {
    expect(
      funnel(<String, Object?>{
        'data': <Object?>[
          <String, Object?>{
            'type': 'funnel',
            'orientation': 'v',
            'y': <Object?>['a'],
            'x': <Object?>[1],
          },
        ],
      }).orientation,
      // PLAN CORRECTION: the plan's Step 1 expects the string 'horizontal'.
      // FluentFunnelChart.orientation is the FluentFunnelOrientation enum
      // (`funnel_chart.dart:21-29`, `:745`), so the enum arm of the same name
      // is what upstream's string maps onto.
      FluentFunnelOrientation.horizontal,
      reason:
          "PlotlySchemaAdapter.ts:3171 maps orientation 'v' to "
          "'horizontal'. // parity",
    );
    expect(
      funnel(<String, Object?>{
        'data': <Object?>[
          <String, Object?>{
            'type': 'funnel',
            'orientation': 'h',
            'y': <Object?>['a'],
            'x': <Object?>[1],
          },
        ],
      }).orientation,
      FluentFunnelOrientation.vertical,
      reason: 'PlotlySchemaAdapter.ts:3171.',
    );
  });

  test(
    'an unnamed STACKED funnel trace falls back to a one-based category',
    () {
      // PLAN CORRECTION: the plan's Step 1 test asserted that an unnamed
      // NON-stacked funnel gives stages `Category 1` / `Category 2`, citing
      // PlotlySchemaAdapter.ts:3082. `:3082` is `series.name || \`Category
      // ${seriesIdx + 1}\`` inside the `if (isStacked)` arm that opens at
      // `:3078`, and it names the SERIES, not the stage. The non-stacked arm
      // (`:3126-3162`) has no fallback at all: `:3157` writes the raw label
      // through. So the plan's expectation cannot be produced by a faithful
      // transcription of `:3060-3175`, and the behaviour `:3082` really has is
      // asserted here instead.
      final chart = funnel(<String, Object?>{
        'data': <Object?>[
          <String, Object?>{
            'type': 'funnel',
            'y': <Object?>['a', 'b'],
            'x': <Object?>[3, 2],
          },
          <String, Object?>{
            'type': 'funnel',
            'y': <Object?>['a', 'b'],
            'x': <Object?>[1, 1],
          },
        ],
      });
      expect(
        chart.data.map((d) => d.subValues!.map((s) => s.category).toList()),
        <List<String>>[
          <String>['Category 1', 'Category 2'],
          <String>['Category 1', 'Category 2'],
        ],
        reason: 'PlotlySchemaAdapter.ts:3082.',
      );
    },
  );

  test('a non-stacked funnel with null labels swaps the two roles', () {
    // `getCategoriesAndValues` (`:3018-3057`) with no declared orientation
    // takes `'h'` (`:3022`). `isStringArray` accepts null
    // (`predicates.dart:118-119`, `PlotlySchemaConverter.ts:147-150`), so a
    // `[null, null]` y IS a string array and a numeric x IS a number array:
    // `:3042-3043` therefore keeps y as the categories and x as the values.
    final chart = funnel(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'funnel',
          'y': <Object?>[null, null],
          'x': <Object?>[3, 1],
        },
      ],
    });
    expect(
      chart.data.map((d) => d.stage).toList(),
      <String>['null', 'null'],
      reason:
          'PlotlySchemaAdapter.ts:3157 writes the raw label through; the '
          'port stringifies it because FluentFunnelDataPoint.stage is a '
          'non-nullable `num | String` (funnel_chart.dart:66-68).',
    );
    expect(
      chart.data.map((d) => d.value).toList(),
      <double>[3, 1],
      reason: 'PlotlySchemaAdapter.ts:3152 — `Number(values[i])`.',
    );
  });

  test('a non-stacked funnel drops a stage whose value is not a number', () {
    final chart = funnel(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'funnel',
          'y': <Object?>['a', 'b', 'c'],
          'x': <Object?>[3, 'oops', 1],
        },
      ],
    });
    expect(
      chart.data.map((d) => d.stage).toList(),
      <String>['a', 'c'],
      reason:
          'PlotlySchemaAdapter.ts:3153-3155 — `isNaN(Number(...))` returns '
          'early, so the stage is never pushed.',
    );
  });

  test('stacked detection needs more than one trace and multi-entry labels and '
      'values', () {
    final chart = funnel(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'funnel',
          'name': 's1',
          'y': <Object?>['a', 'b'],
          'x': <Object?>[3, 2],
        },
        <String, Object?>{
          'type': 'funnel',
          'name': 's2',
          'y': <Object?>['a', 'b'],
          'x': <Object?>[1, 1],
        },
      ],
    });
    expect(
      // PLAN CORRECTION: the plan's Step 1 reads `chart.isStacked`.
      // FluentFunnelChart has no such prop — the widget derives it from the
      // data with `isFluentStackedFunnelData` (`funnel_chart.dart:97-98`,
      // `:807`), which is the same all-or-nothing `subValues` test upstream
      // runs at `FunnelChart.tsx:310-312`. That derivation is what the
      // transformer has to satisfy, so it is what is asserted.
      isFluentStackedFunnelData(chart.data),
      isTrue,
      reason:
          'PlotlySchemaAdapter.ts:3070-3076 requires data.length > 1 and every '
          'trace to have more than one label and value.',
    );
    expect(
      chart.data.map((d) => d.subValues!.map((s) => s.category).toList()),
      <List<String>>[
        <String>['s1', 's2'],
        <String>['s1', 's2'],
      ],
      reason:
          'PlotlySchemaAdapter.ts:3110-3122 merges the second trace into '
          'the stages the first one created.',
    );
  });

  test('a single trace is never stacked, however many entries it has', () {
    final chart = funnel(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'funnel',
          'y': <Object?>['a', 'b'],
          'x': <Object?>[3, 2],
        },
      ],
    });
    expect(
      isFluentStackedFunnelData(chart.data),
      isFalse,
      reason: 'PlotlySchemaAdapter.ts:3071 — `input.data.length > 1`.',
    );
  });

  testWidgets('a transformed funnel figure mounts and paints its stages', (
    tester,
  ) async {
    final chart = funnel(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'funnel',
          'y': <Object?>['Visited', 'Signed', 'Paid'],
          'x': <Object?>[100, 60, 20],
        },
      ],
      'layout': <String, Object?>{'title': 'Conversion'},
    });
    await tester.pumpWidget(
      FluentApp(
        theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
        home: Center(child: SizedBox(width: 400, height: 300, child: chart)),
      ),
    );
    // Single-word stages: the legend title-cases every word it draws, so a
    // two-word stage would be looked up under a name the transformer never
    // produced.
    for (final stage in const <String>['Visited', 'Signed', 'Paid']) {
      expect(
        find.text(stage),
        findsOneWidget,
        reason:
            'the transformed stages have to reach a real paint, not merely a '
            'props bag: PlotlySchemaAdapter.ts:3156-3160.',
      );
    }
    expect(
      chart.chartTitle,
      'Conversion',
      reason: 'PlotlySchemaAdapter.ts:3164, :3168.',
    );
  });

  test('theta unit conversion covers radians, gradians and degrees', () {
    double firstTheta(String? unit) =>
        // PLAN CORRECTION: the plan's Step 1 reads `.points`.
        // FluentPolarSeries names the point list `data`
        // (`model/polar_data.dart:124`).
        polar(<String, Object?>{
              'data': <Object?>[
                <String, Object?>{
                  'type': 'scatterpolar',
                  'theta': <Object?>[1],
                  'r': <Object?>[1],
                  'thetaunit': ?unit,
                },
              ],
            }).data.single.data.single.theta
            as double;

    expect(
      firstTheta('radians'),
      closeTo(57.29577951308232, 1e-9),
      reason: 'PlotlySchemaAdapter.ts:3243-3244: theta * 180 / pi.',
    );
    expect(
      firstTheta('gradians'),
      closeTo(0.9, 1e-12),
      reason: 'PlotlySchemaAdapter.ts:3245-3246.',
    );
    expect(
      firstTheta(null),
      1,
      reason: 'PlotlySchemaAdapter.ts:3247 default is degrees.',
    );
  });

  test('a non-numeric theta is passed through as a category', () {
    final chart = polar(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'scatterpolar',
          'theta': <Object?>['north'],
          'r': <Object?>[1],
          'thetaunit': 'radians',
        },
      ],
    });
    expect(
      chart.data.single.data.single.theta,
      'north',
      reason:
          'PlotlySchemaAdapter.ts:3241-3248 converts only a numeric theta; '
          'anything else is cast to string untouched, so the radian '
          'conversion never touches a category.',
    );
  });

  test('the polar trace kind follows fill and mode', () {
    FluentPolarSeries seriesOf(Map<String, Object?> trace) =>
        polar(<String, Object?>{
          'data': <Object?>[
            <String, Object?>{
              'type': 'scatterpolar',
              'theta': <Object?>[0],
              'r': <Object?>[1],
              ...trace,
            },
          ],
        }).data.single;

    expect(
      seriesOf(<String, Object?>{'fill': 'toself'}),
      isA<FluentAreaPolarSeries>(),
      reason: "PlotlySchemaAdapter.ts:3192 — 'toself' and 'tonext' are areas.",
    );
    expect(
      seriesOf(<String, Object?>{'mode': 'lines+markers'}),
      isA<FluentLinePolarSeries>(),
      reason: 'PlotlySchemaAdapter.ts:3193, :3259.',
    );
    expect(
      seriesOf(<String, Object?>{'mode': 'markers'}),
      isA<FluentScatterPolarSeries>(),
      reason: 'PlotlySchemaAdapter.ts:3263-3267 — the neither-arm.',
    );
    expect(
      seriesOf(<String, Object?>{}),
      isA<FluentLinePolarSeries>(),
      reason: 'PlotlySchemaAdapter.ts:3193 — an undefined mode is a line.',
    );
  });

  test('a polar point whose r or theta is invalid is dropped', () {
    final chart = polar(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'scatterpolar',
          'theta': <Object?>[0, 90, null, 270],
          'r': <Object?>[1, null, 3, 4],
        },
      ],
    });
    expect(
      chart.data.single.data.map((p) => p.theta).toList(),
      <double>[0, 270],
      reason:
          'PlotlySchemaAdapter.ts:3235-3237 drops the point when either '
          'coordinate is invalid.',
    );
  });

  test('a non-polar trace contributes no series', () {
    expect(
      polar(<String, Object?>{
        'data': <Object?>[
          <String, Object?>{
            'type': 'scatter',
            'x': <Object?>[0],
            'y': <Object?>[1],
          },
        ],
      }).data,
      isEmpty,
      reason: 'PlotlySchemaAdapter.ts:3191 runs only for a scatterpolar trace.',
    );
  });

  test('the polar default height', () {
    expect(
      polar(<String, Object?>{
        'data': <Object?>[
          <String, Object?>{
            'type': 'scatterpolar',
            'theta': <Object?>[0],
            'r': <Object?>[1],
          },
        ],
      }).height,
      400,
      reason: 'PlotlySchemaAdapter.ts:3275.',
    );
  });

  test('the polar axis props reach the chart', () {
    final chart = polar(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'scatterpolar',
          'theta': <Object?>[0],
          'r': <Object?>[1],
        },
      ],
      'layout': <String, Object?>{
        'polar': <String, Object?>{
          'radialaxis': <String, Object?>{
            'range': <Object?>[0, 10],
          },
          'angularaxis': <String, Object?>{
            'thetaunit': 'radians',
            'direction': 'clockwise',
          },
        },
      },
    });
    expect(
      chart.radialAxis!.rangeEnd,
      10,
      reason:
          'PlotlySchemaAdapter.ts:3277 spreads getPolarAxisProps, whose '
          ':4351 carries the declared range.',
    );
    expect(
      chart.angularUnit,
      FluentPolarAngularUnit.radians,
      reason: 'PlotlySchemaAdapter.ts:4355.',
    );
    expect(
      chart.direction,
      FluentPolarDirection.clockwise,
      reason: 'PlotlySchemaAdapter.ts:4356.',
    );
  });

  testWidgets('a transformed polar figure mounts and lists its series', (
    tester,
  ) async {
    final chart = polar(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'scatterpolar',
          'name': 'Wind',
          'mode': 'lines',
          'theta': <Object?>[0, 90, 180, 270],
          'r': <Object?>[1, 2, 3, 4],
        },
      ],
      'layout': <String, Object?>{'showlegend': true},
    });
    await tester.pumpWidget(
      FluentApp(
        theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
        // 400 is :3275's own height default; the width matches it so the
        // projection is a circle rather than an ellipse.
        home: Center(child: SizedBox(width: 400, height: 400, child: chart)),
      ),
    );
    expect(
      find.text('Wind'),
      findsOneWidget,
      reason:
          'the transformed series has to reach a real layout pass, not '
          'merely a props bag: the legend name comes from '
          'PlotlySchemaAdapter.ts:3185 and :3189.',
    );
  });

  test('an annotation-only chart passes the layout paper colours straight '
      'through', () {
    final chart = transformPlotlyToAnnotationOnly(
      <String, Object?>{
        'data': <Object?>[],
        'layout': <String, Object?>{
          'width': 300,
          'height': 200,
          'paper_bgcolor': '#ff0000',
          'meta': <String, Object?>{'description': 'a description'},
          'annotations': <Object?>[
            <String, Object?>{
              'text': 'hi',
              'x': 0.5,
              'y': 0.5,
              'xref': 'paper',
              'yref': 'paper',
            },
          ],
        },
      },
      isMultiPlot: false,
      colorMap: <String, String>{},
      colorwayType: FluentPlotlyColorway.byDefault,
      isDark: false,
    );
    expect(
      chart.width,
      300,
      reason:
          'PlotlySchemaAdapter.ts:1245-1280 '
          'pass-through.',
    );
    expect(
      // PLAN CORRECTION: the plan's Step 1 reads `backgroundColor` and
      // `semanticLabel`. FluentAnnotationOnlyChart names the two props after
      // the upstream ones it carries — `paperBackgroundColor` (`:1268`,
      // `annotation_only_chart.dart:94`) and `description` (`:1259`,
      // `:84`).
      chart.paperBackgroundColor!.toARGB32(),
      const Color(0xFFFF0000).toARGB32(),
      reason: 'PlotlySchemaAdapter.ts:1245-1280 forwards paper_bgcolor.',
    );
    expect(
      chart.description,
      'a description',
      reason:
          'PlotlySchemaAdapter.ts:1245-1280 forwards layout.meta.'
          'description.',
    );
    expect(
      chart.annotations,
      hasLength(1),
      reason: 'One layout annotation survives.',
    );
  });

  test('a multi-plot annotation-only chart keeps no annotations', () {
    expect(
      transformPlotlyToAnnotationOnly(
        <String, Object?>{
          'data': <Object?>[],
          'layout': <String, Object?>{
            'annotations': <Object?>[
              <String, Object?>{
                'text': 'hi',
                'x': 0.5,
                'y': 0.5,
                'xref': 'paper',
                'yref': 'paper',
              },
            ],
          },
        },
        isMultiPlot: true,
        colorMap: <String, String>{},
        colorwayType: FluentPlotlyColorway.byDefault,
        isDark: false,
      ).annotations,
      isEmpty,
      reason:
          'PlotlySchemaAdapter.ts:1252 forwards isMultiPlot to '
          'getChartAnnotationsFromLayout, which empties at :1081.',
    );
  });

  test('the annotation-only margin maps l/r/t/b onto the four sides', () {
    final chart = transformPlotlyToAnnotationOnly(
      <String, Object?>{
        'data': <Object?>[],
        'layout': <String, Object?>{
          'margin': <String, Object?>{'l': 1, 'r': 2, 't': 3, 'b': 4},
        },
      },
      isMultiPlot: false,
      colorMap: <String, String>{},
      colorwayType: FluentPlotlyColorway.byDefault,
      isDark: false,
    );
    expect(
      <double?>[
        chart.margin!.left,
        chart.margin!.right,
        chart.margin!.top,
        chart.margin!.bottom,
      ],
      <double>[1, 2, 3, 4],
      reason:
          'PlotlySchemaAdapter.ts:1278 forwards layout.margin, which '
          'AnnotationOnlyChart.tsx:19-22 reads as t/r/b/l.',
    );
  });

  testWidgets('a transformed annotation-only figure mounts and paints its '
      'text', (tester) async {
    final chart = transformPlotlyToAnnotationOnly(
      <String, Object?>{
        'data': <Object?>[],
        'layout': <String, Object?>{
          'width': 300,
          'height': 200,
          'annotations': <Object?>[
            <String, Object?>{
              'text': 'the only content',
              'x': 0.5,
              'y': 0.5,
              'xref': 'paper',
              'yref': 'paper',
            },
          ],
        },
      },
      isMultiPlot: false,
      colorMap: <String, String>{},
      colorwayType: FluentPlotlyColorway.byDefault,
      isDark: false,
    );
    await tester.pumpWidget(
      FluentApp(
        theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
        home: Center(child: SizedBox(width: 300, height: 200, child: chart)),
      ),
    );
    expect(
      find.text('the only content'),
      findsOneWidget,
      reason:
          'the transformed annotation has to reach a real paint, not '
          'merely a props bag: PlotlySchemaAdapter.ts:1252.',
    );
  });
}
