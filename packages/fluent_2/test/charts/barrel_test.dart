import 'dart:ui';

import 'package:fluent_2/fluent_2.dart';
import 'package:flutter_test/flutter_test.dart';

/// The barrel is the package's published surface, so the symbols stages 3 and 4
/// own are asserted to reach it through the single public import.
void main() {
  test('the stage 3 and 4 symbols are exported from the package barrel', () {
    expect(
      <Object>[
        FluentChartAxisType.numeric,
        const FluentChartMargins(),
        const FluentChartSemantics(),
        const FluentChartImageExportOptions(),
        FluentAxisScaleType.auto,
        FluentTickLayout.defaultLayout,
        FluentAxisCategoryOrder.defaultOrder,
        const FluentAxisConfig(),
        FluentLineCurve.linear,
        const FluentLineOptions(),
        const FluentChartXYPoint(x: 1, y: 1),
        const FluentChartDataPoint(),
        const FluentHeatMapChartData(
          legend: 'a',
          data: <FluentHeatMapChartDataPoint>[],
          value: 1,
        ),
        const FluentSankeyChartData(
          nodes: <FluentSankeyNode>[],
          links: <FluentSankeyLink>[],
        ),
        const FluentScatterPolarSeries(
          legend: 'a',
          data: <FluentPolarDataPoint>[],
        ),
        const FluentBarSeries(legend: 'a', data: <FluentDataPointV2>[]),
        const FluentChartAnnotation(
          text: 'a',
          coordinates: FluentPixelCoordinate(x: 0, y: 0),
        ),
        const FluentCustomizedCalloutData(
          x: 1,
          values: <FluentCustomizedCalloutDataPoint>[],
        ),
        FluentChartController(),
        FluentChartLegendShape.circle,
        FluentDataVizToken.color1,
        FluentDataVizPalette.next(0),
        FluentChartColors.of(
          FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
        ),
        FluentChartTextMeasurer(),
        FluentChartTextStyles.of(
          FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
        ),
        const FluentChartMarkSemantics(),
        kChartTitlePadding,
        kDefaultBarWidth,
      ],
      isNotEmpty,
      reason:
          'Every entry must resolve through `package:fluent_2/fluent_2.dart` '
          'alone; a missing barrel line is a compile error in this file.',
    );
  });

  test('the shared function helpers are exported too', () {
    expect(
      areArraysEqual(const <String>['a'], const <String>['a']),
      isTrue,
      reason: 'internal/chart_utils.dart is exported like every other file.',
    );
    expect(
      capitalizeLegendLabel('q1'),
      'Q1',
      reason: 'The legend capitalisation helper is public.',
    );
    expect(
      buildFluentCartesianChartDescription(
        l10n: fluentLocalizationsFallback,
        xAxisType: FluentChartAxisType.numeric,
        yAxisType: FluentChartAxisType.numeric,
        hasSecondaryScale: false,
      ),
      startsWith('Chart. '),
      reason: 'internal/chart_semantics.dart is exported.',
    );
    expect(
      fluentColorContrast(const Color(0xFF000000), const Color(0xFFFFFFFF)),
      closeTo(21, 1e-9),
      reason: 'internal/chart_colors.dart is exported.',
    );
    expect(
      isPlottable(1, 2),
      isTrue,
      reason: 'model/chart_value.dart is exported.',
    );
  });
}
