import 'package:fluent_2_web/src/charts/internal/d3/stable_sort.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Item = ({String key, int seq});

void main() {
  // 40 elements: below Dart's insertion-sort cutoff a merge sort happens to be
  // stable, so a short list proves nothing.
  List<_Item> sample() => <_Item>[
        for (var i = 0; i < 40; i++)
          (key: <String>['b', 'a', 'a', 'c'][i % 4], seq: i),
      ];

  int byKey(_Item a, _Item b) => a.key.compareTo(b.key);

  test('Dart List.sort is unstable — this is the reason the helper exists', () {
    final direct = sample()..sort(byKey);
    final stable = stableSort(sample(), byKey);
    expect(
      direct.map((_Item e) => e.seq).toList(),
      isNot(stable.map((_Item e) => e.seq).toList()),
      reason: 'if this ever starts passing, Dart has become stable and the '
          'helper can be deleted — until then d3-sankey needs it',
    );
  });

  test('ties keep their input order', () {
    final sorted = stableSort(sample(), byKey);
    final aSeqs = sorted
        .where((_Item e) => e.key == 'a')
        .map((_Item e) => e.seq)
        .toList();
    expect(
      aSeqs,
      orderedEquals(<int>[...aSeqs]..sort()),
      reason: 'V8 has sorted stably since ES2019, and d3-sankey ties on '
          'ascendingBreadth twelve times per layout (sankey.js:263,286)',
    );
  });

  test('the input list is not mutated', () {
    final input = sample();
    final before = input.map((_Item e) => e.seq).toList();
    stableSort(input, byKey);
    expect(
      input.map((_Item e) => e.seq).toList(),
      before,
      reason: 'd3 sorts an index array, never the caller List, and the sankey '
          'columns are re-sorted twelve times over the same node objects',
    );
  });

  test('an empty and a single-element list survive', () {
    expect(stableSort(<_Item>[], byKey), isEmpty, reason: 'no comparator call');
    final one = sample().take(1).toList();
    expect(stableSort(one, byKey).single.seq, 0, reason: 'unchanged');
  });
}
