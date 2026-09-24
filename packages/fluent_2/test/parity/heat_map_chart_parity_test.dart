// Pixel parity for HeatMapChart's custom-accessibility story, against the live
// @fluentui/react-charts render.
//
// Every input below is transcribed from the story's own source, recovered from
// the storybook runtime by `capture_png.mjs` into
// `crawlers/storybooks-fluentui/out/stories/<story-id>.tsx`. Nothing here is
// invented or rounded. HeatMapChartBasic lives in
// `horizontal_bar_and_heat_map_parity_test.dart`.
//
// See `support/react_parity.dart` for why text is masked and why the tolerance
// is not zero.
import 'dart:math' as math;

import 'package:fluent_2/src/charts/heat_map_chart.dart';
import 'package:fluent_2/src/charts/internal/data_viz_palette.dart';
import 'package:fluent_2/src/charts/model/heatmap_data.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/react_parity.dart';

const _yPoint = <String>['CHN', 'IND', 'USA', 'IDN', 'PAK'];
const _xPoint = <String>['1980', '1990', '2000', '2010', '2020'];
const _dataMatrix = <List<double>>[
  <double>[
    818315000,
    981235000,
    1135185000,
    1262645000,
    1337705000,
    1411100000,
  ],
  <double>[557501301, 696828385, 870452165, 1059633675, 1240613620, 1396387127],
  <double>[205052000, 227225000, 249623000, 282162411, 309327143, 331511512],
  <double>[115228394, 148177096, 182159874, 214072421, 244016173, 271857970],
  <double>[59290872, 80624057, 115414069, 154369924, 194454498, 227196741],
];

/// `getRectText`: d3 `formatPrefix(".1", value)(value)` with `k` and `G`
/// respelled `K` and `B`. Every value here is 1e7..1e10, so the prefix is `M`
/// or `G`, and `.1` is a fixed one-decimal mantissa (`toFixed(1)`).
String _rectText(double value) {
  final exponent = (math.log(value) / math.ln10).floor() ~/ 3 * 3;
  final prefix = switch (exponent) {
    3 => 'K',
    6 => 'M',
    9 => 'B',
    _ => throw StateError('no prefix transcribed for 1e$exponent'),
  };
  return '${(value / math.pow(10, exponent)).toStringAsFixed(1)}$prefix';
}

/// `getDataPoints`: every cell after the first column whose value passes
/// [filter], row-major. `descriptionMessage` and `callOutAccessibilityData`
/// reach only the popover and the semantics tree, which no screenshot shows.
List<FluentHeatMapChartDataPoint> _dataPoints(bool Function(double) filter) =>
    <FluentHeatMapChartDataPoint>[
      for (var ri = 0; ri < _dataMatrix.length; ri++)
        for (var ci = 1; ci < _dataMatrix[ri].length; ci++)
          if (filter(_dataMatrix[ri][ci]))
            FluentHeatMapChartDataPoint(
              x: _xPoint[ci - 1],
              y: _yPoint[ri],
              value: _dataMatrix[ri][ci] / 1e6,
              rectText: _rectText(_dataMatrix[ri][ci]),
            ),
    ];

void main() {
  setUpAll(loadParityFonts);

  test('_rectText matches d3 formatPrefix', () {
    // Recomputed with d3-format 3 against the story's own matrix.
    expect(_rectText(981235000), '981.2M');
    expect(_rectText(80624057), '80.6M');
    expect(_rectText(1135185000), '1.1B');
    expect(_rectText(1396387127), '1.4B');
  });

  testWidgets('HeatMapChartCustomAccessibility', (tester) async {
    // `const HeatMapData` in
    // charts-heatmapchart--heat-map-chart-custom-accessibility.tsx.
    final data = <FluentHeatMapChartData>[
      FluentHeatMapChartData(
        value: 250,
        legend: '< 500M',
        data: _dataPoints((value) => value < 5e8),
      ),
      FluentHeatMapChartData(
        value: 750,
        legend: '500M - 1B',
        data: _dataPoints((value) => value >= 5e8 && value <= 1e9),
      ),
      FluentHeatMapChartData(
        value: 1250,
        legend: '> 1B',
        data: _dataPoints((value) => value > 1e9),
      ),
    ];

    await expectReactParity(
      tester,
      'charts-heatmapchart--heat-map-chart-custom-accessibility',
      FluentHeatMapChart(
        data: data,
        // The sliders start at 450 x 350, the box mounted below; the chart
        // reads its size from its constraints. The story passes no `culture`.
        chartTitle: 'Heat map chart custom accessibility example',
        xAxisStringFormatter: (point) => 'FY $point',
        domainValuesForColorScale: const <double>[0, 1500],
        rangeValuesForColorScale: <Color>[
          FluentDataVizPalette.resolve(FluentDataVizToken.color3),
          FluentDataVizPalette.resolve(FluentDataVizToken.color10),
        ],
        // `reflowProps={{mode: 'min-width'}}` has no port equivalent and is
        // inert at a static clip, as in HeatMapChartBasic.
      ),
      // Oracle B puts the chart wrapper at y 125.21875, height 310 + legend, so
      // the 351-row capture holds a 350px box — the same fractional origin as
      // HeatMapChartBasic; see `logicalSize` in `support/react_parity.dart`.
      logicalSize: const Size(450, 350),
      // Measured 0.050% — 64 of 126,820 px, aligned. Every cell, gridline and
      // row boundary lands on the capture. 56 px are the edge columns of the
      // second and third legend swatches, which Chromium snaps to whole pixels
      // (x 107.69 paints 108-121) where the port antialiases the fraction; the
      // other 8 are glyph fringe of the cell labels outside the text mask.
      maxMismatch: 0.06,
    );
  });
}
