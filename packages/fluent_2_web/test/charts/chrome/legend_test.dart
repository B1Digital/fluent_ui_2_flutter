import 'package:fluent_2_web/src/charts/chrome/legend.dart';
import 'package:fluent_2_web/src/charts/internal/chart_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // capitalizeLegendLabel is plan 02's, in internal/chart_utils.dart. These
  // four expectations re-pin it here because the legend is one of its two
  // callers and spec §5.4's export parity depends on both agreeing.
  group('capitalizeLegendLabel', () {
    test('uppercases the first letter of each word, leaving the rest alone', () {
      expect(
        capitalizeLegendLabel('first series'),
        'First Series',
        reason:
            'useLegendsStyles.styles.ts:56 is the only text-transform in the '
            'package and Flutter has no equivalent, so the label is '
            'capitalised in Dart before it is painted.',
      );
      expect(
        capitalizeLegendLabel('foo BAR'),
        'Foo BAR',
        reason:
            'CSS capitalize only touches the first letter of a word; it never '
            'lowercases the remainder.',
      );
    });

    test('is a no-op on an empty string', () {
      expect(
        capitalizeLegendLabel(''),
        '',
        reason: 'An empty legend title must survive unchanged.',
      );
    });

    test('treats every run of whitespace as one boundary', () {
      expect(
        capitalizeLegendLabel('a  b'),
        'A  B',
        reason:
            'Two spaces are two whitespace characters, and the letter after '
            'the last of them starts the word.',
      );
    });
  });

  group('nextFluentChartLegendSelection', () {
    test('single select toggles off on re-click', () {
      expect(
        nextFluentChartLegendSelection(
          <String>{'a'},
          'a',
          mode: FluentChartLegendSelectionMode.single,
          legendCount: 3,
        ),
        isEmpty,
        reason:
            'Legends.tsx:238 returns {} when the clicked legend was already '
            'the selected one.',
      );
    });

    test('single select replaces rather than accumulates', () {
      expect(
        nextFluentChartLegendSelection(
          <String>{'a'},
          'b',
          mode: FluentChartLegendSelectionMode.single,
          legendCount: 3,
        ),
        <String>{'b'},
        reason: 'Legends.tsx:238 returns {[title]: true}, discarding the rest.',
      );
    });

    test('multi select clears everything once all are selected', () {
      expect(
        nextFluentChartLegendSelection(
          <String>{'a', 'b'},
          'c',
          mode: FluentChartLegendSelectionMode.multiple,
          legendCount: 3,
        ),
        isEmpty,
        reason:
            'Legends.tsx:225-227 canonicalises "all selected" as "none '
            'selected", so selecting the last one empties the set.',
      );
    });

    test('multi select removes an already-selected legend', () {
      expect(
        nextFluentChartLegendSelection(
          <String>{'a', 'b'},
          'b',
          mode: FluentChartLegendSelectionMode.multiple,
          legendCount: 3,
        ),
        <String>{'a'},
        reason: 'Legends.tsx:218-221 deletes the key when it is already set.',
      );
    });

    test('does not mutate its input', () {
      final current = <String>{'a'};
      nextFluentChartLegendSelection(
        current,
        'b',
        mode: FluentChartLegendSelectionMode.multiple,
        legendCount: 3,
      );
      expect(
        current,
        <String>{'a'},
        reason:
            'Legends.tsx:217 spreads into a fresh object; a mutating port would '
            'break the controlled-mode comparison at :247.',
      );
    });
  });

  group('FluentChartLegendItem', () {
    test('defaults match Legend at Legends.types.ts:68-123', () {
      const item = FluentChartLegendItem(title: 'a', color: Color(0xFF0078D4));
      expect(
        item.stripePattern,
        isFalse,
        reason:
            'Legends.types.ts:107 declares stripePattern optional, so falsy.',
      );
      expect(
        item.isLineLegendInBarChart,
        isFalse,
        reason: 'Legends.types.ts:112 declares it optional, so falsy.',
      );
      expect(
        item.shape,
        isNull,
        reason:
            'A null shape falls through to the plain bordered rectangle at '
            'shape.tsx:35, which is the default swatch.',
      );
    });
  });
}
