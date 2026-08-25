import 'package:fluent_2/src/charts/internal/vega/routing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, Object?> spec({
    Object? mark = 'bar',
    Map<String, Object?>? encoding,
    List<Object?>? values,
    List<Object?>? layer,
  }) => <String, Object?>{
    if (layer == null) 'mark': mark,
    'layer': ?layer,
    'encoding': ?encoding,
    'data': <String, Object?>{'values': values ?? <Object?>[]},
  };

  test(
    'a quantitative x holding a non-numeric string is corrected to nominal',
    () {
      final s = spec(
        encoding: <String, Object?>{
          'x': <String, Object?>{'field': 'a', 'type': 'quantitative'},
        },
        values: <Object?>[
          <String, Object?>{'a': 'hello'},
        ],
      );
      autoCorrectEncodingTypes(s);
      expect(
        ((s['encoding']! as Map<String, Object?>)['x']!
            as Map<String, Object?>)['type'],
        'nominal',
        reason: 'VegaLiteSchemaAdapter.ts:1570-1572.',
      );
    },
  );

  test('a quantitative x holding a numeric string is left alone', () {
    final s = spec(
      encoding: <String, Object?>{
        'x': <String, Object?>{'field': 'a', 'type': 'quantitative'},
      },
      values: <Object?>[
        <String, Object?>{'a': '12'},
      ],
    );
    autoCorrectEncodingTypes(s);
    expect(
      ((s['encoding']! as Map<String, Object?>)['x']!
          as Map<String, Object?>)['type'],
      'quantitative',
      reason:
          "VegaLiteSchemaAdapter.ts:1570 tests !isFinite(Number(sample)), and Number('12') "
          'is finite.',
    );
  });

  test(
    'an unparseable temporal becomes quantitative for a number and nominal otherwise',
    () {
      final numeric = spec(
        encoding: <String, Object?>{
          'x': <String, Object?>{'field': 'a', 'type': 'temporal'},
        },
        values: <Object?>[
          <String, Object?>{'a': 5},
        ],
      );
      autoCorrectEncodingTypes(numeric);
      expect(
        ((numeric['encoding']! as Map<String, Object?>)['x']!
            as Map<String, Object?>)['type'],
        'quantitative',
        reason: 'VegaLiteSchemaAdapter.ts:1578-1580.',
      );

      final text = spec(
        encoding: <String, Object?>{
          'x': <String, Object?>{'field': 'a', 'type': 'temporal'},
        },
        values: <Object?>[
          <String, Object?>{'a': 'not a date'},
        ],
      );
      autoCorrectEncodingTypes(text);
      expect(
        ((text['encoding']! as Map<String, Object?>)['x']!
            as Map<String, Object?>)['type'],
        'nominal',
        reason: 'VegaLiteSchemaAdapter.ts:1578-1580.',
      );
    },
  );

  test('a y object with exactly one numeric key REWRITES every data row', () {
    final s = spec(
      encoding: <String, Object?>{
        'y': <String, Object?>{'field': 'v', 'type': 'quantitative'},
      },
      values: <Object?>[
        <String, Object?>{
          'v': <String, Object?>{'label': 'a', 'amount': 7},
        },
        <String, Object?>{
          'v': <String, Object?>{'label': 'b', 'amount': 9},
        },
      ],
    );
    autoCorrectEncodingTypes(s);
    final rows =
        (s['data']! as Map<String, Object?>)['values']! as List<Object?>;
    expect(
      (rows.first! as Map<String, Object?>)['v'],
      7,
      reason:
          'VegaLiteSchemaAdapter.ts:1599-1612 rewrites the row in place and keeps the type '
          'quantitative.',
    );
    expect(
      ((s['encoding']! as Map<String, Object?>)['y']!
          as Map<String, Object?>)['type'],
      'quantitative',
      reason:
          'VegaLiteSchemaAdapter.ts:1611 comment: the type is deliberately not changed.',
    );
  });

  test(
    'a y object with two numeric keys becomes nominal and leaves the rows alone',
    () {
      final s = spec(
        encoding: <String, Object?>{
          'y': <String, Object?>{'field': 'v', 'type': 'quantitative'},
        },
        values: <Object?>[
          <String, Object?>{
            'v': <String, Object?>{'a': 1, 'b': 2},
          },
        ],
      );
      autoCorrectEncodingTypes(s);
      expect(
        ((s['encoding']! as Map<String, Object?>)['y']!
            as Map<String, Object?>)['type'],
        'nominal',
        reason: 'VegaLiteSchemaAdapter.ts:1613-1614.',
      );
    },
  );

  test('the routing cascade, in its documented order', () {
    FluentVegaChartKind route(Map<String, Object?> s) =>
        getVegaChartType(s).kind;

    expect(
      route(
        spec(
          layer: <Object?>[
            <String, Object?>{'mark': 'bar'},
            <String, Object?>{'mark': 'line'},
          ],
        ),
      ),
      FluentVegaChartKind.stackedBar,
      reason:
          'VegaLiteSchemaAdapter.ts:1653-1667: a bar plus line layer is a stacked bar.',
    );
    expect(
      route(
        spec(
          mark: 'arc',
          encoding: <String, Object?>{
            'theta': <String, Object?>{'field': 't'},
            'radius': <String, Object?>{'field': 'r'},
          },
        ),
      ),
      FluentVegaChartKind.polar,
      reason: 'VegaLiteSchemaAdapter.ts:1677.',
    );
    expect(
      route(
        spec(
          mark: 'arc',
          encoding: <String, Object?>{
            'theta': <String, Object?>{'field': 't'},
          },
        ),
      ),
      FluentVegaChartKind.donut,
      reason: 'VegaLiteSchemaAdapter.ts:1682.',
    );
    expect(
      route(
        spec(
          mark: 'rect',
          encoding: <String, Object?>{
            'x': <String, Object?>{'field': 'a'},
            'y': <String, Object?>{'field': 'b'},
            'color': <String, Object?>{'field': 'c'},
          },
        ),
      ),
      FluentVegaChartKind.heatmap,
      reason: 'VegaLiteSchemaAdapter.ts:1692.',
    );
    expect(
      route(
        spec(
          encoding: <String, Object?>{
            'x': <String, Object?>{'field': 'a', 'bin': true},
          },
        ),
      ),
      FluentVegaChartKind.histogram,
      reason:
          'VegaLiteSchemaAdapter.ts:1698-1700, checked before every other bar branch.',
    );
    expect(
      route(
        spec(
          encoding: <String, Object?>{
            'x': <String, Object?>{'field': 'a', 'type': 'quantitative'},
            'y': <String, Object?>{'field': 'b', 'type': 'nominal'},
          },
        ),
      ),
      FluentVegaChartKind.horizontalBar,
      reason: 'VegaLiteSchemaAdapter.ts:1705-1708.',
    );
    expect(
      route(
        spec(
          encoding: <String, Object?>{
            'x': <String, Object?>{'field': 'a', 'type': 'nominal'},
            'color': <String, Object?>{'field': 'c'},
            'xOffset': <String, Object?>{'field': 'c'},
          },
        ),
      ),
      FluentVegaChartKind.groupedBar,
      reason: 'VegaLiteSchemaAdapter.ts:1710-1715.',
    );
    expect(
      route(
        spec(
          encoding: <String, Object?>{
            'x': <String, Object?>{'field': 'a', 'type': 'nominal'},
            'color': <String, Object?>{'field': 'c'},
          },
        ),
      ),
      FluentVegaChartKind.stackedBar,
      reason: 'VegaLiteSchemaAdapter.ts:1716.',
    );
    expect(
      route(
        spec(
          encoding: <String, Object?>{
            'x': <String, Object?>{'field': 'a', 'type': 'nominal'},
          },
          values: <Object?>[
            <String, Object?>{'a': 'p'},
            <String, Object?>{'a': 'p'},
          ],
        ),
      ),
      FluentVegaChartKind.stackedBar,
      reason:
          'VegaLiteSchemaAdapter.ts:1719-1726: duplicate x values imply a stack.',
    );
    expect(
      route(
        spec(
          encoding: <String, Object?>{
            'x': <String, Object?>{'field': 'a', 'type': 'nominal'},
          },
          values: <Object?>[
            <String, Object?>{'a': 'p'},
            <String, Object?>{'a': 'q'},
          ],
        ),
      ),
      FluentVegaChartKind.bar,
      reason: 'VegaLiteSchemaAdapter.ts:1727.',
    );
    for (final mark in <String>['point', 'circle', 'square', 'tick']) {
      expect(
        route(spec(mark: mark)),
        FluentVegaChartKind.scatter,
        reason: 'VegaLiteSchemaAdapter.ts:1734 for mark $mark.',
      );
    }
    expect(
      route(spec(mark: 'area')),
      FluentVegaChartKind.area,
      reason: 'ts:1730.',
    );
    expect(
      route(spec(mark: 'trail')),
      FluentVegaChartKind.line,
      reason: 'ts:1739.',
    );
    expect(
      route(spec(mark: 'errorbar')),
      FluentVegaChartKind.line,
      reason: 'ts:1744.',
    );
    expect(
      route(spec(mark: 'errorband')),
      FluentVegaChartKind.line,
      reason: 'ts:1744.',
    );
    expect(
      route(spec(mark: 'anything-else')),
      FluentVegaChartKind.line,
      reason: 'ts:1748.',
    );
  });

  test(
    'routing runs auto-correction first, so a corrected type changes the route',
    () {
      final s = spec(
        encoding: <String, Object?>{
          'x': <String, Object?>{'field': 'a', 'type': 'quantitative'},
          'y': <String, Object?>{'field': 'b', 'type': 'nominal'},
        },
        values: <Object?>[
          <String, Object?>{'a': 'text', 'b': 'p'},
        ],
      );
      expect(
        getVegaChartType(s).kind,
        FluentVegaChartKind.bar,
        reason:
            'VegaLiteSchemaAdapter.ts:1650 corrects x to nominal FIRST, so the '
            'isYNominal && !isXNominal test at :1705 no longer holds and the route is a plain bar '
            'rather than a horizontal one.',
      );
    },
  );

  test('a layered spec normalises to one unit spec per layer', () {
    final units = normalizeVegaSpec(<String, Object?>{
      'layer': <Object?>[
        <String, Object?>{
          'mark': 'bar',
          'encoding': <String, Object?>{
            'y': <String, Object?>{'field': 'own'},
          },
        },
        <String, Object?>{
          'mark': 'line',
          'data': <String, Object?>{'values': <Object?>[]},
        },
      ],
      'data': <String, Object?>{
        'values': <Object?>[
          <String, Object?>{'a': 1},
        ],
      },
      'encoding': <String, Object?>{
        'x': <String, Object?>{'field': 'shared'},
        'y': <String, Object?>{'field': 'shared-y'},
      },
    });
    expect(
      units.length,
      2,
      reason: 'VegaLiteSchemaAdapter.ts:578 maps over every layer.',
    );
    expect(
      (units.first['encoding']! as Map<String, Object?>)['x'],
      <String, Object?>{'field': 'shared'},
      reason:
          'VegaLiteSchemaAdapter.ts:582 spreads the shared encoding into each '
          'layer.',
    );
    expect(
      (units.first['encoding']! as Map<String, Object?>)['y'],
      <String, Object?>{'field': 'own'},
      reason:
          "VegaLiteSchemaAdapter.ts:583 spreads the layer's own encoding "
          'second, so it wins per key.',
    );
    expect(
      units.first['data'],
      <String, Object?>{
        'values': <Object?>[
          <String, Object?>{'a': 1},
        ],
      },
      reason:
          'VegaLiteSchemaAdapter.ts:580 falls back to the shared data for a '
          'layer that declares none.',
    );
    expect(
      units[1]['data'],
      <String, Object?>{'values': <Object?>[]},
      reason:
          "VegaLiteSchemaAdapter.ts:580 keeps a layer's own data when it has "
          'one, even an empty one.',
    );
  });

  test('a unit spec normalises to exactly mark, encoding and data', () {
    final units = normalizeVegaSpec(<String, Object?>{
      'mark': 'bar',
      'encoding': <String, Object?>{
        'x': <String, Object?>{'field': 'a'},
      },
      'data': <String, Object?>{'values': <Object?>[]},
      'transform': <Object?>[
        <String, Object?>{'filter': 'datum.a > 0'},
      ],
    });
    expect(
      units.single.keys.toList(),
      <String>['mark', 'encoding', 'data'],
      reason:
          'VegaLiteSchemaAdapter.ts:590-596 rebuilds the unit spec from three '
          'keys, so `transform` is dropped on this path.',
    );
  });

  test(
    'a spec that is neither layered nor a unit spec normalises to nothing',
    () {
      expect(
        normalizeVegaSpec(<String, Object?>{'mark': 'bar'}),
        isEmpty,
        reason:
            'VegaLiteSchemaAdapter.ts:600 — isUnitSpec (`:88-90`) needs an '
            'encoding as well as a mark, so a spec with only a mark renders '
            'nothing rather than throwing.',
      );
      expect(
        normalizeVegaSpec(<String, Object?>{'layer': <Object?>[]}),
        isEmpty,
        reason:
            'isLayerSpec (`:81-83`) rejects an empty layer array, so `{layer: '
            '[]}` reaches `:600` rather than returning a list of zero charts '
            'from `:578`.',
      );
    },
  );
}
