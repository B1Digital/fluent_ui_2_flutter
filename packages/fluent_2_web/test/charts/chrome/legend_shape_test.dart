import 'package:fluent_2_web/src/charts/chrome/legend_shape.dart';
import 'package:flutter_test/flutter_test.dart';

/// `LegendShape` is `'default' | 'triangle' | keyof Points | keyof CustomPoints`
/// (`Legends.types.ts:269`), which resolves to ten distinct strings once the
/// duplicated `'triangle'` is collapsed.
void main() {
  group('FluentChartLegendShape', () {
    test('carries exactly the ten upstream shapes', () {
      expect(
        FluentChartLegendShape.values.length,
        10,
        reason:
            "Legends.types.ts:269 unions 'default', 'triangle', the eight "
            'Points members (utilities.ts:1713-1721) and the one CustomPoints '
            'member (:1723-1725); triangle appears twice and collapses.',
      );
    });

    test('orders the eight Points members at their upstream ordinals', () {
      // utilities.ts:1713-1721 — circle, square, triangle, diamond, pyramid,
      // hexagon, pentagon, octagon. ChartPopover.tsx:216 indexes this enum with
      // `index % 8`, so the order is behaviour, not decoration.
      expect(
        <FluentChartLegendShape>[
          FluentChartLegendShape.circle,
          FluentChartLegendShape.square,
          FluentChartLegendShape.triangle,
          FluentChartLegendShape.diamond,
          FluentChartLegendShape.pyramid,
          FluentChartLegendShape.hexagon,
          FluentChartLegendShape.pentagon,
          FluentChartLegendShape.octagon,
        ].map((shape) => shape.pointIndex).toList(),
        <int>[0, 1, 2, 3, 4, 5, 6, 7],
        reason: 'utilities.ts:1713-1721 assigns these implicit ordinals.',
      );
    });

    test('gives the two non-Points members a null point index', () {
      expect(
        FluentChartLegendShape.defaultShape.pointIndex,
        isNull,
        reason: "'default' is not a member of Points (utilities.ts:1713).",
      );
      expect(
        FluentChartLegendShape.dottedLine.pointIndex,
        isNull,
        reason: 'dottedLine lives in CustomPoints (utilities.ts:1723-1725).',
      );
    });
  });
}
