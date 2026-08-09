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
}
