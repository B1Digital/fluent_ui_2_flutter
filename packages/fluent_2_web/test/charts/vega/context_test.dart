import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:fluent_2_web/src/charts/internal/vega/context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, Object?> withTimeUnit(String unit) => <String, Object?>{
    'mark': 'bar',
    'data': <String, Object?>{
      'values': <Object?>[
        <String, Object?>{'d': '2024-05-15T13:00:00', 'v': 1},
        <String, Object?>{'d': '2024-05-16T14:00:00', 'v': 3},
      ],
    },
    'encoding': <String, Object?>{
      'x': <String, Object?>{
        'field': 'd',
        'type': 'temporal',
        'timeUnit': unit,
      },
      'y': <String, Object?>{'field': 'v', 'type': 'quantitative'},
    },
  };

  test('the five timeUnit keys', () {
    expect(
      initializeTransformContext(withTimeUnit('year')).data.first['d'],
      '2024',
      reason: 'ts:1216-1217: String(getFullYear()).',
    );
    expect(
      initializeTransformContext(withTimeUnit('quarter')).data.first['d'],
      'Q2',
      reason:
          r'ts:1219-1220: `Q${floor(month / 3) + 1}`; May is month index 4, '
          'so Q2.',
    );
    expect(
      initializeTransformContext(withTimeUnit('month')).data.first['d'],
      'May',
      reason: "ts:1223 hard-codes the 'en' locale for the short month name.",
    );
    expect(
      initializeTransformContext(withTimeUnit('day')).data.first['d'],
      '15',
      reason: 'ts:1225-1226: String(getDate()), the day of the month.',
    );
    expect(
      initializeTransformContext(withTimeUnit('hours')).data.first['d'],
      '13',
      reason: 'ts:1228-1229: String(getHours()).',
    );
  });

  test('a timeUnit forces the x type to ordinal and drops the aggregate', () {
    final context = initializeTransformContext(withTimeUnit('year'));
    expect(
      (context.encoding['x']! as Map<String, Object?>)['type'],
      'ordinal',
      reason: 'ts:1252.',
    );
    expect(
      (context.encoding['x']! as Map<String, Object?>).containsKey('timeUnit'),
      isFalse,
      reason: 'ts:1253 deletes the timeUnit once applied.',
    );
  });

  test('a timeUnit with a y field aggregates with the mean by default', () {
    final context = initializeTransformContext(<String, Object?>{
      'mark': 'bar',
      'data': <String, Object?>{
        'values': <Object?>[
          <String, Object?>{'d': '2024-01-01', 'v': 2},
          <String, Object?>{'d': '2024-06-01', 'v': 4},
        ],
      },
      'encoding': <String, Object?>{
        'x': <String, Object?>{
          'field': 'd',
          'type': 'temporal',
          'timeUnit': 'year',
        },
        'y': <String, Object?>{'field': 'v', 'type': 'quantitative'},
      },
    });
    expect(
      context.data.single['v'],
      3,
      reason:
          "ts:1206 defaults the aggregate to 'mean' when a y field is present.",
    );
  });

  test(
    'a conditional colour materialises a synthetic field and replaces the encoding',
    () {
      final context = initializeTransformContext(<String, Object?>{
        'mark': 'bar',
        'data': <String, Object?>{
          'values': <Object?>[
            <String, Object?>{'x': 'a', 'v': 5},
            <String, Object?>{'x': 'b', 'v': 15},
          ],
        },
        'encoding': <String, Object?>{
          'x': <String, Object?>{'field': 'x', 'type': 'nominal'},
          'y': <String, Object?>{'field': 'v', 'type': 'quantitative'},
          'color': <String, Object?>{
            'condition': <String, Object?>{
              'test': 'datum.v > 10',
              'value': '#ff0000',
            },
            'value': '#0000ff',
          },
        },
      });
      expect(
        context.data.map((r) => r['__conditional_color__']).toList(),
        <Object?>['#0000ff', '#ff0000'],
        reason: 'ts:1183-1190, :1186 evaluates the test per row.',
      );
      expect(
        (context.encoding['color']! as Map<String, Object?>)['field'],
        '__conditional_color__',
        reason: 'ts:1193-1198 replaces the whole colour encoding.',
      );
      expect(
        context.colorField,
        '__conditional_color__',
        reason:
            'ts:1281 reads the field off the rewritten encoding, so the '
            'materialised column is what a transformer groups by.',
      );
    },
  );

  test('a conditional colour with no fallback value uses the grey default', () {
    final context = initializeTransformContext(<String, Object?>{
      'mark': 'bar',
      'data': <String, Object?>{
        'values': <Object?>[
          <String, Object?>{'x': 'a', 'v': 5},
        ],
      },
      'encoding': <String, Object?>{
        'x': <String, Object?>{'field': 'x', 'type': 'nominal'},
        'y': <String, Object?>{'field': 'v', 'type': 'quantitative'},
        'color': <String, Object?>{
          'condition': <String, Object?>{
            'test': 'datum.v > 10',
            'value': '#ff0000',
          },
        },
      },
    });
    expect(
      context.data.single['__conditional_color__'],
      '#999',
      reason: "ts:1180 falls back to the literal '#999'.",
    );
  });

  test(
    'a text mark layer becomes a text annotation with the documented id',
    () {
      final annotations = extractVegaAnnotations(<String, Object?>{
        'layer': <Object?>[
          <String, Object?>{'mark': 'line'},
          <String, Object?>{
            'mark': 'text',
            'encoding': <String, Object?>{
              'x': <String, Object?>{'datum': 3},
              'y': <String, Object?>{'datum': 4},
              'text': <String, Object?>{'value': 'peak'},
            },
          },
        ],
      });
      expect(
        annotations.single.id,
        'text-annotation-1',
        reason: 'ts:706 uses the layer index.',
      );
      expect(annotations.single.text, 'peak', reason: 'ts:707.');
    },
  );

  test(
    'a text mark anchored at a zero datum survives the falsy coordinate chain',
    () {
      final annotations = extractVegaAnnotations(<String, Object?>{
        'layer': <Object?>[
          <String, Object?>{
            'mark': 'text',
            'encoding': <String, Object?>{
              'x': <String, Object?>{'datum': 0},
              'y': <String, Object?>{'datum': 0},
              'text': <String, Object?>{'value': 'origin'},
            },
          },
        ],
      });
      expect(
        annotations.single.coordinates,
        isA<FluentDataCoordinate>()
            .having((c) => c.x, 'x', 0)
            .having((c) => c.y, 'y', 0),
        reason:
            'ts:700-704 keeps the annotation when the coordinate is merely '
            'DEFINED — `xValue !== undefined || encoding.x.datum !== undefined` — '
            'so a 0 that the `||` chain at :697 drops still anchors it at :710.',
      );
    },
  );

  test('a rule mark defaults to black at stroke width one', () {
    final annotations = extractVegaAnnotations(<String, Object?>{
      'layer': <Object?>[
        <String, Object?>{
          'mark': 'rule',
          'encoding': <String, Object?>{
            'y': <String, Object?>{'datum': 10},
          },
        },
      ],
    });
    expect(annotations.single.id, 'rule-h-0', reason: 'ts:743.');
    expect(
      annotations.single.style!.borderColor!.toARGB32(),
      0xFF000000,
      reason: "ts:722 defaults a string mark's colour to '#000', opaque black.",
    );
    expect(annotations.single.style!.borderWidth, 1, reason: 'ts:723.');
  });

  test(
    'a rule takes its label from a companion text layer at the same value',
    () {
      final annotations = extractVegaAnnotations(<String, Object?>{
        'layer': <Object?>[
          <String, Object?>{
            'mark': 'rule',
            'encoding': <String, Object?>{
              'y': <String, Object?>{'datum': 10},
            },
          },
          <String, Object?>{
            'mark': 'text',
            'encoding': <String, Object?>{
              'x': <String, Object?>{'datum': 0},
              'y': <String, Object?>{'datum': 10},
              'text': <String, Object?>{'value': 'threshold'},
            },
          },
        ],
      });
      expect(
        annotations.first.text,
        'threshold',
        reason:
            'ts:730-740 searches the other layers for a text mark at the same y.',
      );
    },
  );

  test('a rect layer with x and x2 becomes a colour-fill bar', () {
    final bars = extractVegaColorFillBars(
      <String, Object?>{
        'layer': <Object?>[
          <String, Object?>{
            'mark': 'rect',
            'encoding': <String, Object?>{
              'x': <String, Object?>{'datum': 1},
              'x2': <String, Object?>{'datum': 5},
            },
          },
        ],
      },
      <String, String>{},
      isDark: false,
    );
    expect(bars.single.legend, 'region-0', reason: 'ts:810.');
    expect(bars.single.applyPattern, isFalse, reason: 'ts:840.');
  });
}
