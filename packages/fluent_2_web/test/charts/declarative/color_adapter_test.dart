import 'package:fluent_2_web/src/charts/internal/plotly/color_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'the first ten legends take the plotly-to-Fluent mapping in insertion order',
    () {
      final map = <String, String>{};
      final first = plotlyGetColor(
        'a',
        map,
        FluentPlotlyColorwayKind.plotly,
        isDark: false,
      );
      final second = plotlyGetColor(
        'b',
        map,
        FluentPlotlyColorwayKind.plotly,
        isDark: false,
      );
      expect(
        map.keys.toList(),
        <String>['a', 'b'],
        reason:
            'PlotlyColorAdapter.ts:127 assigns by Map size, so insertion order is the palette index.',
      );
      expect(
        first,
        isNot(second),
        reason:
            'PlotlyColorAdapter.ts:121-123 walks PLOTLY_FLUENTVIZ_COLORWAY_MAPPING by size.',
      );
      expect(
        plotlyGetColor(
          'a',
          map,
          FluentPlotlyColorwayKind.plotly,
          isDark: false,
        ),
        first,
        reason:
            'PlotlyColorAdapter.ts:131 returns the cached colour on a repeat lookup.',
      );
    },
  );

  test('past the tenth legend it falls through to the qualitative cycle', () {
    final map = <String, String>{};
    for (var i = 0; i < 10; i++) {
      plotlyGetColor(
        'l$i',
        map,
        FluentPlotlyColorwayKind.plotly,
        isDark: false,
      );
    }
    final eleventh = plotlyGetColor(
      'l10',
      map,
      FluentPlotlyColorwayKind.plotly,
      isDark: false,
    );
    expect(
      eleventh,
      isNotEmpty,
      reason:
          'PlotlyColorAdapter.ts:125 switches to getNextColor once size reaches 10.',
    );
  });

  test('a schema colourway matching plotly exactly is recognised', () {
    expect(
      getPlotlyColorwayKind(kDefaultPlotlyColorway),
      FluentPlotlyColorwayKind.plotly,
      reason:
          'PlotlyColorAdapter.ts:79-81 lower-cases and compares with areArraysEqual.',
    );
    expect(
      getPlotlyColorwayKind(<String>['#ABCDEF']),
      FluentPlotlyColorwayKind.others,
      reason: 'PlotlyColorAdapter.ts:82 default branch.',
    );
    expect(
      getPlotlyColorwayKind(null),
      FluentPlotlyColorwayKind.others,
      reason:
          'PlotlyColorAdapter.ts:72-74 treats a missing colourway as others.',
    );
  });

  test('only the default colourway type consults the schema colours', () {
    final map = <String, String>{};
    expect(
      extractColor(
        null,
        FluentPlotlyColorway.builtin,
        '#ff0000',
        map,
        isDark: false,
      ),
      isNull,
      reason:
          "PlotlyColorAdapter.ts:177-179 returns undefined unless colorwayType === 'default'.",
    );
  });

  test('resolveColor cycles a colour array with the modulo of its length', () {
    final map = <String, String>{};
    expect(
      resolveColor(
        <String>['#111111', '#222222'],
        3,
        'x',
        map,
        null,
        isDark: false,
      ),
      '#222222',
      reason: 'PlotlyColorAdapter.ts:194 indexes with index % length.',
    );
  });

  test(
    'getOpacity prefers the marker array, then the marker scalar, then the series',
    () {
      expect(
        getOpacity(<String, Object?>{
          'marker': <String, Object?>{
            'opacity': <Object?>[0.1, 0.2],
          },
        }, 3),
        0.2,
        reason: 'PlotlyColorAdapter.ts:206 indexes with index % length.',
      );
      expect(
        getOpacity(<String, Object?>{'opacity': 0.5}, 0),
        0.5,
        reason: 'PlotlyColorAdapter.ts:208 falls back to series.opacity.',
      );
      expect(
        getOpacity(const <String, Object?>{}, 0),
        1,
        reason: 'PlotlyColorAdapter.ts:208 defaults to 1.',
      );
    },
  );

  test('opacity is baked into an eight-digit hex, rounded the JavaScript way', () {
    expect(
      applyOpacityHex8('#336699', 0.5),
      '#33669980',
      reason:
          'd3-color formatHex8 emits Math.round(255 * opacity); 255 * 0.5 = 127.5 rounds '
          'half-UP to 128 = 0x80, where Dart round() would also give 128 but a negative '
          'half would differ — see internal/d3/js_math.dart.',
    );
    expect(
      applyOpacityHex8('#336699', 1),
      '#336699ff',
      reason:
          'Full opacity still emits eight digits (PlotlySchemaAdapter.ts:1472).',
    );
  });

  test('createColorScale remaps the colourscale stops onto the data domain', () {
    final scale = createColorScale(
      <String, Object?>{
        'coloraxis': <String, Object?>{
          'colorscale': <Object?>[
            <Object?>[0, '#000000'],
            <Object?>[1, '#ffffff'],
          ],
        },
      },
      <String, Object?>{
        'marker': <String, Object?>{
          'color': <Object?>[10, 20],
        },
      },
      null,
    );
    expect(
      scale!(15),
      'rgb(128, 128, 128)',
      reason:
          'PlotlyColorAdapter.ts:230-233 builds scaleLinear over dMin + pos * (dMax - dMin); '
          'd3-interpolate emits rgb() strings at gamma 1.',
    );
  });

  test('a three-stop colourscale interpolates per segment and extrapolates '
      'inside the end segment', () {
    // Three stops is the polylinear arm of `d3-scale/src/continuous.js:33-54`,
    // which the two-stop case above never reaches.
    final scale = createColorScale(
      <String, Object?>{
        'coloraxis': <String, Object?>{
          'colorscale': <Object?>[
            <Object?>[0, '#000000'],
            <Object?>[0.5, '#ff0000'],
            <Object?>[1, '#ffffff'],
          ],
        },
      },
      <String, Object?>{
        'marker': <String, Object?>{
          'color': <Object?>[0, 100],
        },
      },
      null,
    );
    expect(
      scale!(25),
      'rgb(128, 0, 0)',
      reason:
          'PlotlyColorAdapter.ts:230 puts the middle stop at 0 + 0.5 * 100 = 50, so 25 is '
          'halfway along the first segment only — a scale that ignored the middle stop '
          'would blend black towards white instead.',
    );
    expect(
      scale(-50),
      'rgb(0, 0, 0)',
      reason:
          'continuous.js:52 clamps the bisect to the first segment and extrapolates, so t '
          'is -1 and every channel clamps back to 0 (d3-color/src/color.js:292-294).',
    );
  });

  test('a donut colourway equal to Category10 is recognised as d3', () {
    // `PlotlyColorAdapter.ts:76` compares against D3_FLUENTVIZ_COLORWAY_MAPPING
    // — token names — so this arm is dead upstream; the port compares against
    // the hex table the arm was written for.
    expect(
      getPlotlyColorwayKind(kDefaultD3Colorway, isDonut: true),
      FluentPlotlyColorwayKind.d3,
      reason:
          'PlotlyColorAdapter.ts:76-78 is the only producer of the d3 kind, and '
          'PlotlyColorAdapter.ts:116-119 selects D3_FLUENTVIZ_COLORWAY_MAPPING without it.',
    );
    expect(
      getPlotlyColorwayKind(kDefaultD3Colorway),
      FluentPlotlyColorwayKind.others,
      reason: 'PlotlyColorAdapter.ts:76 gates the d3 arm on isDonut.',
    );
  });

  test('a zero marker opacity is falsy upstream and falls through', () {
    expect(
      getOpacity(<String, Object?>{
        'marker': <String, Object?>{'opacity': 0},
        'opacity': 0.25,
      }, 0),
      0.25,
      reason:
          'PlotlyColorAdapter.ts:204 gates on the truthiness of marker.opacity, and 0 is '
          'falsy in JavaScript, so the series opacity wins.',
    );
  });
}
