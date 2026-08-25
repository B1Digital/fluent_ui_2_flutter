import 'package:fluent_2_web/src/charts/internal/chart_semantics.dart';
import 'package:fluent_2_web/src/charts/model/chart_common.dart';
import 'package:fluent_2_web/src/charts/model/chart_value.dart';
import 'package:fluent_2_web/src/l10n/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FluentChartMarkSemantics.from', () {
    test('is focusable by default', () {
      final semantics = FluentChartMarkSemantics.from(null);
      expect(
        semantics.focusable,
        isTrue,
        reason: 'utilities.ts:1783 isDataFocusable defaults to true.',
      );
      expect(semantics.label, isNull, reason: 'No props and no fallback.');
    });

    test('prefers the props label over the fallback', () {
      final semantics = FluentChartMarkSemantics.from(
        const FluentChartSemantics(label: 'Q1 revenue'),
        fallbackLabel: 'Q1, 42',
      );
      expect(
        semantics.label,
        'Q1 revenue',
        reason: "utilities.ts:1795 `'aria-label': accessibleData.ariaLabel`.",
      );
    });

    test('falls back when the props carry no label', () {
      final semantics = FluentChartMarkSemantics.from(
        const FluentChartSemantics(describedBy: 'desc-1'),
        fallbackLabel: 'Q1, 42',
      );
      expect(
        semantics.label,
        'Q1, 42',
        reason:
            'A canvas-drawn mark produces no semantics node of its own, so the '
            'label has to be supplied explicitly either way (spec 5.7).',
      );
      expect(
        semantics.hint,
        'desc-1',
        reason:
            'aria-describedby (utilities.ts:1797) becomes the Flutter hint. '
            'aria-labelledby has no Flutter analogue and is dropped.',
      );
    });
  });

  group('buildFluentCartesianChartDescription', () {
    test('describes both axes by their type when neither is titled', () {
      expect(
        buildFluentCartesianChartDescription(
          l10n: fluentLocalizationsFallback,
          xAxisType: FluentChartAxisType.category,
          yAxisType: FluentChartAxisType.numeric,
          hasSecondaryScale: false,
        ),
        'Chart. The X axis displays categories. The Y axis displays values. ',
        reason:
            'CartesianChart.tsx:552-561 with the :563-574 axis clauses: '
            "StringAxis maps to 'categories' and NumericAxis to 'values'.",
      );
    });

    test("maps a date axis to 'time'", () {
      expect(
        buildFluentCartesianChartDescription(
          l10n: fluentLocalizationsFallback,
          xAxisType: FluentChartAxisType.date,
          yAxisType: FluentChartAxisType.numeric,
          hasSecondaryScale: false,
        ),
        'Chart. The X axis displays time. The Y axis displays values. ',
        reason: 'CartesianChart.tsx:569-570.',
      );
    });

    test('prefers an axis title over the type word', () {
      expect(
        buildFluentCartesianChartDescription(
          l10n: fluentLocalizationsFallback,
          xAxisTitle: 'Month',
          yAxisTitle: 'Revenue',
          xAxisType: FluentChartAxisType.category,
          yAxisType: FluentChartAxisType.numeric,
          hasSecondaryScale: false,
        ),
        'Chart. The X axis displays Month. The Y axis displays Revenue. ',
        reason: 'CartesianChart.tsx:566 `axisTitle || ...`.',
      );
    });

    test('appends a secondary clause only when there is a secondary scale', () {
      expect(
        buildFluentCartesianChartDescription(
          l10n: fluentLocalizationsFallback,
          xAxisType: FluentChartAxisType.numeric,
          yAxisType: FluentChartAxisType.numeric,
          secondaryYAxisTitle: 'Rate',
          hasSecondaryScale: true,
        ),
        'Chart. The X axis displays values. The Y axis displays values. '
        'The secondary Y axis displays Rate. ',
        reason: 'CartesianChart.tsx:557-559.',
      );
      expect(
        buildFluentCartesianChartDescription(
          l10n: fluentLocalizationsFallback,
          xAxisType: FluentChartAxisType.numeric,
          yAxisType: FluentChartAxisType.numeric,
          secondaryYAxisTitle: 'Rate',
          hasSecondaryScale: false,
        ).contains('secondary'),
        isFalse,
        reason:
            'CartesianChart.tsx:557 gates the clause on secondaryYScaleOptions, '
            'not on the title.',
      );
    });

    test('runs a real title straight into the first clause, with no '
        'separator', () {
      expect(
        buildFluentCartesianChartDescription(
          l10n: fluentLocalizationsFallback,
          chartTitle: 'Revenue',
          xAxisType: FluentChartAxisType.numeric,
          yAxisType: FluentChartAxisType.numeric,
          hasSecondaryScale: false,
        ),
        'RevenueThe X axis displays values. The Y axis displays values. ',
        reason:
            '// parity: CartesianChart.tsx:554 concatenates '
            "`props.chartTitle || 'Chart. '` with the axis clauses, so only the "
            'fallback carries a trailing separator.',
      );
    });
  });
}
