// Pixel parity for the two declarative charts — Plotly and Vega-Lite — against
// the live @fluentui/react-charts render.
//
// Both stories are schema browsers: a dropdown of many schemas, of which the
// reference captured whichever one the control starts on. Everything below is
// that initial schema, transcribed from the story's own source in
// `crawlers/storybooks-fluentui/out/stories/<story-id>.tsx`.
//
// See `support/react_parity.dart` for why text is masked and why the tolerance
// is not zero.
import 'dart:convert';

import 'package:fluent_2/src/charts/declarative_chart.dart';
import 'package:fluent_2/src/charts/vega_declarative_chart.dart';
import 'package:flutter/widgets.dart' show Offset, Size;
import 'package:flutter_test/flutter_test.dart';

import 'support/react_parity.dart';

/// `DEFAULT_SCHEMAS[0]` in charts-declarativechart--declarative-chart-basic-example.tsx,
/// the `areachart` entry, byte-for-byte as the story's own `JSON.parse`
/// argument. Kept as JSON rather than hand-lifted into Dart literals: the story
/// parses this exact string, so parsing it here cannot drift from it.
const String _areaChartSchemaJson =
    '{"visualizer":"plotly","data":[{"fill":"tonexty","line":{"color":"rg'
    'ba(255, 153, 51, 1.0)","width":"1.3"},"mode":"lines","name":"a","typ'
    'e":"scatter","x":[0,1,2,3,4,5,6,7,8,9],"y":[0.17048910089864067,0.05'
    '390702725063046,0.7560889217240573,0.7393313216390578,0.756297944367'
    '4754,0.983908108492343,0.4552096139092071,0.751939393026647,0.424416'
    '95150031034,0.6119820237450841],"fillcolor":"rgba(255, 153, 51, '
    '0.3)"},{"fill":"tonexty","line":{"color":"rgba(55, 128, 191, 1.0)","'
    'width":"1.3"},"mode":"lines","name":"b","type":"scatter","x":[0,1,2,'
    '3,4,5,6,7,8,9],"y":[1.0921498980687505,0.628379692444796,1.680438733'
    '3467445,1.1741874271317159,1.7098535938519392,1.0165440369832146,0.8'
    '201578488720772,1.019179653143562,0.5391840333768539,0.9023036941696'
    '878],"fillcolor":"rgba(55, 128, 191, '
    '0.3)"},{"fill":"tonexty","line":{"color":"rgba(50, 171, 96, 1.0)","w'
    'idth":"1.3"},"mode":"lines","name":"c","type":"scatter","x":[0,1,2,3'
    ',4,5,6,7,8,9],"y":[1.5084498776097979,1.0993096327196032,2.546888476'
    '3826125,1.3139261978658,1.7288516603693358,1.3500413551768342,1.4111'
    '774146124456,1.1245312639069405,1.4068617318281056,0.923649970148817'
    '1],"fillcolor":"rgba(50, 171, 96, '
    '0.3)"},{"fill":"tonexty","line":{"color":"rgba(128, 0, 128, 1.0)","w'
    'idth":"1.3"},"mode":"lines","name":"d","type":"scatter","x":[0,1,2,3'
    ',4,5,6,7,8,9],"y":[1.912915766078795,1.6450103381519354,3.5238669332'
    '41722,1.656799203492564,2.666064160881149,2.2985767814076814,1.64913'
    '00653173326,1.2880873970749964,2.192375146193222,1.6271909616796654]'
    ',"fillcolor":"rgba(128, 0, 128, 0.3)"}],"layout":{"legend":{"font":{'
    '"color":"#4D5663"},"bgcolor":"#F5F6F9"},"xaxis1":{"title":"","tickfo'
    'nt":{"color":"#4D5663"},"gridcolor":"#E1E5ED","titlefont":{"color":"'
    '#4D5663"},"zerolinecolor":"#E1E5ED"},"yaxis1":{"title":"","tickfont"'
    ':{"color":"#4D5663"},"zeroline":false,"gridcolor":"#E1E5ED","titlefo'
    'nt":{"color":"#4D5663"},"zerolinecolor":"#E1E5ED"},"plot_bgcolor":"#'
    'F5F6F9","paper_bgcolor":"#F5F6F9"},"frames":[],"selectedLegends":["a'
    '"]}';

void main() {
  setUpAll(loadParityFonts);

  testWidgets('DeclarativeChartBasicExample', (tester) async {
    // The story's initial state, from its own effects:
    //   * `showMore` starts false, so `options` is `DEFAULT_OPTIONS` and
    //     `applySelection(DEFAULT_OPTIONS[0])` selects `areachart` (:255-259);
    //   * `applySelection` sets `selectedLegends` from the schema's own
    //     `selectedLegends`, i.e. `["a"]` (:248-250), which `:365-370` then
    //     spreads back into the schema it hands the chart;
    //   * `fluentDataVizColorPalette` starts `"default"` (:184-185), which is
    //     `FluentPlotlyColorway.byDefault` and the widget's own default.
    final schema = jsonDecode(_areaChartSchemaJson) as Map<String, Object?>;

    await expectReactParity(
      tester,
      'charts-declarativechart--declarative-chart-basic-example',
      FluentDeclarativeChart(
        chartSchema: FluentPlotlySchema(
          plotlySchema: schema,
          selectedLegends: const <String>['a'],
        ),
      ),
      // Measured 0.032% — 104 of 327,332 unmasked pixels, down from 32.408%
      // (and from 37.309% before the y domain was fixed elsewhere).
      //
      // What closed: the unselected-series dimming. `selectedLegends` is
      // `["a"]`, so upstream paints series `a` at fill opacity 0.7 and
      // `b`/`c`/`d` at 0.1, and this port painted all four at 0.7 because
      // `transformPlotlyToArea` had nowhere to forward the selection to —
      // `FluentAreaChart` declared no `selectedLegends` parameter. It has one
      // now, `DeclarativeChart.tsx:598-603`'s spread reaches the single-plot
      // path, and the four fills, the four top edges and three of the four
      // legend swatches all land within a level per channel.
      //
      // The 104 that remain are all in one place, and none of them is in the
      // plot: they are the 1px outline of the two dimmed legend swatches, at
      // (135..149, 327..340) and (180..194, 327..340).
      //
      // NOT an opacity bug, though it reads like one. `dimmedSwatchOpacity`
      // resolves to 1 outside high contrast (`legend_style.dart:271-275`), so
      // the `Opacity` wrapping the swatch is a no-op here, and the border is
      // already taken from `item.color` rather than the dimmed fill
      // (`chrome/legend.dart`, the `Border.all` in `_buildSwatch`). The proof
      // is a single pixel: at (142, 327) — the middle of the top border, where
      // coverage is whole — the port reads (55,128,191), upstream's colour
      // exactly. Only the border's END columns are partial: x=135 reads
      // (202,222,238) and x=136 (107,161,208), which is one 1px stroke spread
      // across two columns by a left edge at x≈135.26. Chromium snaps a border
      // box to whole device pixels and Skia antialiases the true fractional
      // one, so this is the same subpixel residual the legends and polar
      // stories record — visible here only because a dimmed swatch is the one
      // case where the border shows against a white fill instead of against
      // its own colour. The SELECTED swatch, filled solid, is pixel-identical
      // at 90..103 in both. Nothing to fix.
      maxMismatch: 0.052,
    );
  });

  testWidgets('VegaDeclarativeChartDefault', (tester) async {
    // `ALL_SCHEMAS`' first key, `adCtrScatter`, which is what
    // `DEFAULT_SCHEMAS[0]` resolves to and what `selectedChart` starts as
    // (charts-vegadeclarativechart--default.tsx:1324-1326). `width` and
    // `height` are the two Input controls' initial 600 and 400
    // (`:1330-1331`), spread over the parsed schema at `:1691`.
    final spec = <String, Object?>{
      r'$schema': 'https://vega.github.io/schema/vega-lite/v5.json',
      'description': 'Ad click-through rate analysis',
      'data': <String, Object?>{
        'values': <Object?>[
          <String, Object?>{
            'impressions': 50000,
            'clicks': 1250,
            'campaign': 'Summer Sale',
            'ctr': 2.5,
          },
          <String, Object?>{
            'impressions': 75000,
            'clicks': 2625,
            'campaign': 'Back to School',
            'ctr': 3.5,
          },
          <String, Object?>{
            'impressions': 120000,
            'clicks': 3600,
            'campaign': 'Holiday Special',
            'ctr': 3.0,
          },
          <String, Object?>{
            'impressions': 45000,
            'clicks': 1800,
            'campaign': 'Flash Deal',
            'ctr': 4.0,
          },
          <String, Object?>{
            'impressions': 90000,
            'clicks': 3150,
            'campaign': 'Spring Collection',
            'ctr': 3.5,
          },
          <String, Object?>{
            'impressions': 60000,
            'clicks': 1440,
            'campaign': 'Clearance',
            'ctr': 2.4,
          },
          <String, Object?>{
            'impressions': 100000,
            'clicks': 4500,
            'campaign': 'Black Friday',
            'ctr': 4.5,
          },
        ],
      },
      'mark': 'point',
      'encoding': <String, Object?>{
        'x': <String, Object?>{
          'field': 'impressions',
          'type': 'quantitative',
          'axis': <String, Object?>{'title': 'Impressions', 'format': ',.0f'},
        },
        'y': <String, Object?>{
          'field': 'ctr',
          'type': 'quantitative',
          'axis': <String, Object?>{'title': 'Click-Through Rate (%)'},
        },
        'size': <String, Object?>{
          'field': 'clicks',
          'type': 'quantitative',
          'legend': <String, Object?>{'title': 'Total Clicks'},
          'scale': <String, Object?>{
            'range': <Object?>[100, 1000],
          },
        },
        'color': <String, Object?>{
          'field': 'ctr',
          'type': 'quantitative',
          'scale': <String, Object?>{'scheme': 'blues'},
          'legend': null,
        },
        'tooltip': <Object?>[
          <String, Object?>{'field': 'campaign', 'type': 'nominal'},
          <String, Object?>{
            'field': 'impressions',
            'type': 'quantitative',
            'format': ',.0f',
          },
          <String, Object?>{
            'field': 'clicks',
            'type': 'quantitative',
            'format': ',.0f',
          },
          <String, Object?>{
            'field': 'ctr',
            'type': 'quantitative',
            'format': '.1f',
            'title': 'CTR %',
          },
        ],
      },
      'title': 'Ad Performance - CTR Analysis',
      'width': 600,
      'height': 400,
    };

    await expectReactParity(
      tester,
      'charts-vegadeclarativechart--default',
      FluentVegaDeclarativeChart(
        chartSchema: FluentVegaSchema(vegaLiteSpec: spec),
      ),
      // Measured 0.224% — 446 of 199,098 unmasked pixels, down from 12.515%.
      //
      // What closed: the `height: 400` above. Upstream ignores it for a `point`
      // mark — `transformVegaLiteToScatterChartProps` (`:3191-3231`) returns no
      // dimensions at all, unlike stacked bar (`:2712`) and heatmap (`:3510`),
      // and `ScatterChart.tsx:137-139` says so outright — so the container div
      // keeps `withResponsiveContainer`'s `height: 100%`, `_fitParentContainer`
      // (`CartesianChart.tsx:514-519`) falls back to 350 and takes the 40px
      // legend strip out of it. Oracle B records exactly that: svg 600x310,
      // legend root 580x32 eight pixels below it. This port sized EVERY kind
      // from `spec['height']`, so the cell was 400 tall, the lifted legend row
      // went under it and the whole thing overflowed its box by 89 px. The cell
      // is now sized only for the kinds whose transformer forwards a size, and
      // the lifted row is `Flexible`-fed the way the shell's own row is, which
      // gives 311 + 40 against upstream's 310 + 8 + 32.
      //
      // 0.224% since, closing the legend permutation the earlier measurement
      // predicted plus two things it had not spotted. All three:
      //
      //   * The series order. Upstream walks the grouped object with
      //     `Object.keys` (`:3120`), which hoists the integer-like keys "3" and
      //     "4" ahead of the rest in ascending order — 3, 4, 2.5, 3.5, 2.4, 4.5
      //     — where a Dart map is insertion-ordered and gave 2.5, 3.5, 3, 4,
      //     2.4, 4.5. The palette is handed out in that order, so four of the
      //     six series were painted in the wrong colour. `jsObjectKeys` in
      //     `internal/vega/js_value.dart` now states that enumeration rule
      //     once; `transform_bar.dart:1275` and `transform_other.dart:247`
      //     record the same divergence and can adopt it.
      //   * The legend was LIFTED on this path at all. `:494` renders the
      //     shared `<Legends>` inside the concat branch only, and `:472` is the
      //     sole writer of the `_hideLegend` flag `:238` reads, so a single
      //     spec keeps the chart's own legend. Upstream's is the ScatterChart's
      //     — circular swatches (`ScatterChart.tsx:279`), left-aligned at x 29,
      //     in series order. The port drew a centred strip of square swatches
      //     at x 136 in first-seen order instead.
      //   * The harness, see `logicalSize` below.
      //
      // COST, deliberate: the lifted row was how a legend selection round-tripped
      // through `onSchemaChange` for a single spec, because only `FluentAreaChart`
      // and `FluentPolarChart` take `selectedLegends`. Upstream gets that for free
      // by spreading `legendProps` into the chart it renders (`:243`); closing it
      // here is the parameter on eight widgets plus a pass-through in eleven
      // transformers. Parity is restored and the round-trip is not — file it.
      // 1.370% since, and 0.590 of the drop was the harness rather than this
      // chart: Oracle B puts the root box at y 339.5, height 350, so the
      // screenshot spans 351 rows for a 350px box and Chromium rounds the
      // origin UP to the second of them. The harness used to size the chart to
      // the PNG, which both stretched it by a row and started it one row high.
      logicalSize: const Size(600, 350),
      logicalOffset: const Offset(0, 1),
      maxMismatch: 0.25,
    );
    // The overflow that used to be asserted here is gone: `takeException`
    // returns null now, and a rendered chart that silently overflows its own
    // box would fail the comparison above long before it reached 2.16%.
    expect(tester.takeException(), isNull);
  });
}
