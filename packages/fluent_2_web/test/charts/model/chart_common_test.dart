import 'package:fluent_2_web/src/charts/model/chart_common.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FluentChartMargins', () {
    test('leaves every side null by default', () {
      const margins = FluentChartMargins();
      expect(
        margins.left,
        isNull,
        reason: 'DataPoint.ts:37-54 — all optional.',
      );
      expect(margins.right, isNull, reason: 'All four sides are optional.');
      expect(margins.top, isNull, reason: 'All four sides are optional.');
      expect(margins.bottom, isNull, reason: 'All four sides are optional.');
    });

    test('copyWith replaces only the named sides', () {
      const margins = FluentChartMargins(
        left: 40,
        right: 20,
        top: 20,
        bottom: 35,
      );
      final copy = margins.copyWith(left: 8);
      expect(copy.left, 8, reason: 'left was named.');
      expect(copy.right, 20, reason: 'right was not named.');
      expect(copy.top, 20, reason: 'top was not named.');
      expect(copy.bottom, 35, reason: 'bottom was not named.');
    });

    test('mirrored swaps left and right and leaves top and bottom alone', () {
      const margins = FluentChartMargins(
        left: 40,
        right: 20,
        top: 5,
        bottom: 35,
      );
      final mirrored = margins.mirrored;
      expect(
        mirrored.left,
        20,
        reason:
            'The RTL swap at step 4 of the margin solve exchanges the two '
            'horizontal sides (spec 3.3).',
      );
      expect(mirrored.right, 40, reason: 'The swap is symmetric.');
      expect(mirrored.top, 5, reason: 'Vertical sides do not mirror.');
      expect(mirrored.bottom, 35, reason: 'Vertical sides do not mirror.');
    });

    test('mirrored carries a null through', () {
      const margins = FluentChartMargins(right: 20);
      final mirrored = margins.mirrored;
      expect(mirrored.left, 20, reason: 'right moved to left.');
      expect(
        mirrored.right,
        isNull,
        reason: 'left was null, so right becomes null.',
      );
    });

    test('mergeOverride lets the other side win field by field', () {
      const computed = FluentChartMargins(
        left: 40,
        right: 20,
        top: 20,
        bottom: 35,
      );
      const user = FluentChartMargins(left: 8, bottom: 60);
      final merged = computed.mergeOverride(user);
      expect(
        merged.left,
        8,
        reason: r'`{...computed, ...props.margins}` — the user value wins.',
      );
      expect(merged.bottom, 60, reason: 'The user value wins.');
      expect(merged.right, 20, reason: 'The user left this side unset.');
      expect(merged.top, 20, reason: 'The user left this side unset.');
    });

    test('mergeOverride with null returns an equal value', () {
      const computed = FluentChartMargins(left: 40, right: 20);
      expect(
        computed.mergeOverride(null),
        computed,
        reason: 'No override object means nothing to spread over.',
      );
    });

    test('is a value type', () {
      const a = FluentChartMargins(left: 40, right: 20, top: 20, bottom: 35);
      const b = FluentChartMargins(left: 40, right: 20, top: 20, bottom: 35);
      const c = FluentChartMargins(left: 41, right: 20, top: 20, bottom: 35);
      expect(a, b, reason: 'Equal field by field.');
      expect(a.hashCode, b.hashCode, reason: 'Equal values hash alike.');
      expect(a, isNot(c), reason: 'left differs.');
    });
  });

  group('FluentChartSemantics', () {
    test('carries the three aria fields and nothing else', () {
      const semantics = FluentChartSemantics(
        label: 'Revenue',
        labelledBy: 'title-1',
        describedBy: 'desc-1',
      );
      expect(semantics.label, 'Revenue', reason: 'DataPoint.ts:591 ariaLabel.');
      expect(
        semantics.labelledBy,
        'title-1',
        reason: 'DataPoint.ts:596 ariaLabelledBy.',
      );
      expect(
        semantics.describedBy,
        'desc-1',
        reason: 'DataPoint.ts:601 ariaDescribedBy.',
      );
    });
    test('defaults every field to null', () {
      const semantics = FluentChartSemantics();
      expect(semantics.label, isNull, reason: 'All three are optional.');
      expect(semantics.labelledBy, isNull, reason: 'All three are optional.');
      expect(semantics.describedBy, isNull, reason: 'All three are optional.');
    });
  });

  group('FluentChartImageExportOptions', () {
    test('defaults scale to 1 and the background to transparent', () {
      const options = FluentChartImageExportOptions();
      expect(
        options.scale,
        1,
        reason: 'image-export-utils.ts reads `opts?.scale ?? 1`.',
      );
      expect(
        options.background.toARGB32(),
        0x00000000,
        reason:
            "ImageExportOptions.background is optional and upstream's default "
            'is a transparent canvas (DataPoint.ts:844-849).',
      );
      expect(options.width, isNull, reason: 'width is optional.');
      expect(options.height, isNull, reason: 'height is optional.');
    });
  });

  group('FluentAxisScaleType', () {
    test("renames 'default' to auto because default is a Dart keyword", () {
      expect(
        FluentAxisScaleType.values,
        <FluentAxisScaleType>[
          FluentAxisScaleType.auto,
          FluentAxisScaleType.log,
        ],
        reason: "DataPoint.ts:1085 — 'default' | 'log'.",
      );
    });
  });

  group('FluentTickLayout', () {
    test("renames 'default' to defaultLayout and keeps the two arms", () {
      expect(
        FluentTickLayout.values,
        <FluentTickLayout>[
          FluentTickLayout.defaultLayout,
          FluentTickLayout.auto,
        ],
        reason:
            "CartesianChart.types.ts:537 — 'default' | 'auto'. `default` is a "
            'Dart keyword.',
      );
    });
  });

  group('FluentAxisConfig', () {
    test('accepts a numeric tickStep', () {
      const config = FluentAxisConfig(tickStep: 2);
      expect(config.tickStep, 2, reason: 'DataPoint.ts:1114 number arm.');
    });
    test("accepts the 'L<f>' and 'M<n>' string forms", () {
      const linear = FluentAxisConfig(tickStep: 'L0.5');
      const monthly = FluentAxisConfig(tickStep: 'M3');
      expect(
        linear.tickStep,
        'L0.5',
        reason: 'DataPoint.ts:1104 log linear-spacing form.',
      );
      expect(monthly.tickStep, 'M3', reason: 'DataPoint.ts:1110 monthly form.');
    });
    test('rejects a tickStep that is neither a num nor a String', () {
      expect(
        () => FluentAxisConfig(tickStep: DateTime(2024)),
        throwsA(isA<AssertionError>()),
        reason: 'DataPoint.ts:1114 is `number | string`.',
      );
    });
    test('rejects a tick0 that is neither a num nor a DateTime', () {
      expect(
        () => FluentAxisConfig(tick0: 'x'),
        throwsA(isA<AssertionError>()),
        reason: 'DataPoint.ts:1123 is `number | Date`.',
      );
    });
    test('defaults tickLayout to defaultLayout', () {
      const config = FluentAxisConfig();
      expect(
        config.tickLayout,
        FluentTickLayout.defaultLayout,
        reason: "CartesianChart.types.ts:536 documents `@default 'default'`.",
      );
    });
    test('carries an auto tickLayout, as both declarative adapters set it', () {
      const config = FluentAxisConfig(tickLayout: FluentTickLayout.auto);
      expect(
        config.tickLayout,
        FluentTickLayout.auto,
        reason:
            'PlotlySchemaAdapter.ts:3977-3979 and VegaLiteSchemaAdapter.ts:2721 '
            "both write `xAxis: { tickLayout: 'auto' }`.",
      );
    });
  });
}
