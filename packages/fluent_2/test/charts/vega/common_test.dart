import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2/src/charts/internal/vega/common.dart';
import 'package:fluent_2/src/charts/internal/vega/spec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the seven interpolate values that map, and the lossy monotone', () {
    expect(
      mapInterpolateToCurve('linear'),
      FluentLineCurve.linear,
      reason: 'VegaLiteSchemaAdapter.ts:638-640.',
    );
    expect(
      mapInterpolateToCurve('linear-closed'),
      FluentLineCurve.linear,
      reason: 'VegaLiteSchemaAdapter.ts:638-640.',
    );
    expect(
      mapInterpolateToCurve('step'),
      FluentLineCurve.step,
      reason: 'VegaLiteSchemaAdapter.ts:641-642.',
    );
    expect(
      mapInterpolateToCurve('step-before'),
      FluentLineCurve.stepBefore,
      reason: 'VegaLiteSchemaAdapter.ts:643-644.',
    );
    expect(
      mapInterpolateToCurve('step-after'),
      FluentLineCurve.stepAfter,
      reason: 'VegaLiteSchemaAdapter.ts:645-646.',
    );
    expect(
      mapInterpolateToCurve('natural'),
      FluentLineCurve.natural,
      reason: 'VegaLiteSchemaAdapter.ts:647-648.',
    );
    expect(
      mapInterpolateToCurve('monotone'),
      FluentLineCurve.linear,
      reason:
          'VegaLiteSchemaAdapter.ts:649-650 maps monotone to linear, losing '
          'the curve. // parity',
    );
    for (final unmapped in <String>['basis', 'cardinal', 'catmull-rom']) {
      expect(
        mapInterpolateToCurve(unmapped),
        FluentLineCurve.linear,
        reason: 'VegaLiteSchemaAdapter.ts:652-653 default arm for $unmapped.',
      );
    }
    expect(
      mapInterpolateToCurve(null),
      isNull,
      reason:
          'VegaLiteSchemaAdapter.ts:633-634: only an absent interpolate is '
          'undefined.',
    );
  });

  test(
    'zero false without an explicit domain pads the minimum by five percent',
    () {
      final bounds = extractYMinMax(
        <String, Object?>{
          'y': <String, Object?>{
            'field': 'v',
            'scale': <String, Object?>{'zero': false},
          },
        },
        <Map<String, Object?>>[
          <String, Object?>{'v': 10},
          <String, Object?>{'v': 20},
        ],
      );
      expect(
        bounds.min,
        closeTo(9.5, 1e-12),
        reason:
            'VegaLiteSchemaAdapter.ts:1063: dataMin - (dataMax - dataMin) * 0.05 '
            '= 10 - 0.5.',
      );
      expect(
        bounds.max,
        isNull,
        reason:
            'VegaLiteSchemaAdapter.ts:1064 returns only yMinValue, leaving the '
            'maximum to the chart. // parity',
      );
    },
  );

  test('an explicit domain wins outright', () {
    final bounds = extractYMinMax(
      <String, Object?>{
        'y': <String, Object?>{
          'field': 'v',
          'scale': <String, Object?>{
            'zero': false,
            'domain': <Object?>[0, 100],
          },
        },
      },
      <Map<String, Object?>>[
        <String, Object?>{'v': 10},
      ],
    );
    expect(bounds.min, 0, reason: 'VegaLiteSchemaAdapter.ts:1048-1052.');
    expect(bounds.max, 100, reason: 'VegaLiteSchemaAdapter.ts:1048-1052.');
  });

  test('no y scale at all leaves both bounds to the chart', () {
    final bounds = extractYMinMax(
      <String, Object?>{
        'y': <String, Object?>{'field': 'v'},
      },
      <Map<String, Object?>>[
        <String, Object?>{'v': 10},
      ],
    );
    expect(
      bounds.min,
      isNull,
      reason: 'VegaLiteSchemaAdapter.ts:1069 returns the empty object.',
    );
    expect(
      bounds.max,
      isNull,
      reason: 'VegaLiteSchemaAdapter.ts:1069 returns the empty object.',
    );
  });

  test('a log y scale surfaces as a log axis type', () {
    expect(
      extractYAxisType(<String, Object?>{
        'y': <String, Object?>{
          'scale': <String, Object?>{'type': 'log'},
        },
      }),
      FluentAxisScaleType.log,
      reason: 'VegaLiteSchemaAdapter.ts:1031-1033.',
    );
    expect(
      extractYAxisType(<String, Object?>{
        'y': <String, Object?>{
          'scale': <String, Object?>{'type': 'pow'},
        },
      }),
      isNull,
      reason:
          'VegaLiteSchemaAdapter.ts:1033 recognises log alone; pow renders '
          'linear. // parity',
    );
  });

  test('sort strings, arrays and objects all map onto a category order', () {
    expect(
      convertVegaSortToAxisCategoryOrder('ascending'),
      FluentAxisCategoryOrder.parse('category ascending'),
      reason: 'VegaLiteSchemaAdapter.ts:1101-1102.',
    );
    expect(
      convertVegaSortToAxisCategoryOrder('descending'),
      FluentAxisCategoryOrder.parse('category descending'),
      reason: 'VegaLiteSchemaAdapter.ts:1104-1105.',
    );
    expect(
      convertVegaSortToAxisCategoryOrder(<Object?>['b', 'a']),
      isA<FluentAxisCategoryOrderExplicit>().having(
        (order) => order.categories,
        'categories',
        <String>['b', 'a'],
      ),
      reason:
          'VegaLiteSchemaAdapter.ts:1111-1112 passes an array straight through. '
          'FluentAxisCategoryOrderExplicit carries no value equality, so the '
          'list is read off the instance rather than compared to a twin.',
    );
    expect(
      convertVegaSortToAxisCategoryOrder(<String, Object?>{
        'op': 'average',
        'order': 'descending',
      }),
      FluentAxisCategoryOrder.parse('mean descending'),
      reason:
          "VegaLiteSchemaAdapter.ts:1117 renames the 'average' op to 'mean'.",
    );
    expect(
      convertVegaSortToAxisCategoryOrder(<String, Object?>{'op': 'average'}),
      isNull,
      reason:
          'VegaLiteSchemaAdapter.ts:1116 requires both op and order to be '
          'truthy.',
    );
    expect(
      convertVegaSortToAxisCategoryOrder('-y'),
      isNull,
      reason:
          'VegaLiteSchemaAdapter.ts:1107: a field-name sort is unsupported. '
          '// parity',
    );
  });

  test(
    'a channel sort becomes that axis category order, and no sort becomes none',
    () {
      final orders = extractAxisCategoryOrderProps(<String, Object?>{
        'x': <String, Object?>{'field': 'a', 'sort': 'descending'},
        'y': <String, Object?>{'field': 'b'},
      });
      expect(
        orders.x,
        FluentAxisCategoryOrder.categoryDescending,
        reason: 'VegaLiteSchemaAdapter.ts:1138-1142.',
      );
      expect(
        orders.y,
        isNull,
        reason: 'VegaLiteSchemaAdapter.ts:1145 gates on a truthy sort.',
      );
    },
  );

  test(
    'titles read the title object and the axis title, and never the field name',
    () {
      final titles = getVegaLiteTitles(<String, Object?>{
        'mark': 'line',
        'title': <String, Object?>{'text': 'Chart'},
        'encoding': <String, Object?>{
          'x': <String, Object?>{
            'field': 'a',
            'axis': <String, Object?>{'title': 'Across'},
          },
          'y': <String, Object?>{'field': 'b'},
        },
      });
      expect(
        titles.chartTitle,
        'Chart',
        reason: 'VegaLiteSchemaAdapter.ts:2063 reads title.text.',
      );
      expect(
        titles.xAxisTitle,
        'Across',
        reason:
            'VegaLiteSchemaAdapter.ts:2125 falls through the absent channel '
            'title to the axis title.',
      );
      expect(
        titles.yAxisTitle,
        isNull,
        reason:
            'VegaLiteSchemaAdapter.ts:2126 is `encoding.y?.title ?? '
            'encoding.y?.axis?.title ?? undefined` — there is no field-name '
            'fallback, so a channel carrying only a field has no axis title. '
            '// parity',
      );
    },
  );

  test(
    'a string title is the chart title, and a channel title beats its axis title',
    () {
      final titles = getVegaLiteTitles(<String, Object?>{
        'mark': 'bar',
        'title': 'Plain',
        'encoding': <String, Object?>{
          'x': <String, Object?>{
            'field': 'a',
            'title': 'Channel',
            'axis': <String, Object?>{'title': 'Axis'},
          },
        },
      });
      expect(
        titles.chartTitle,
        'Plain',
        reason: 'VegaLiteSchemaAdapter.ts:2063: the string arm of spec.title.',
      );
      expect(
        titles.xAxisTitle,
        'Channel',
        reason: 'VegaLiteSchemaAdapter.ts:2125: the channel title comes first.',
      );
    },
  );

  test(
    'a spec that is neither a unit nor a layer carries no titles at all',
    () {
      expect(
        getVegaLiteTitles(<String, Object?>{'title': 'Dropped'}).chartTitle,
        isNull,
        reason:
            'VegaLiteSchemaAdapter.ts:2055-2056 returns the empty object when '
            'the spec normalises to no unit specs, taking the chart title with '
            'it. // parity',
      );
    },
  );

  test(
    'a d3 format specifier becomes a formatter, and an invalid one becomes null',
    () {
      expect(
        createValueFormatter(',.1f')!(1234.5),
        '1,234.5',
        reason: 'VegaLiteSchemaAdapter.ts:1076-1086.',
      );
      expect(
        createValueFormatter(null),
        isNull,
        reason: 'VegaLiteSchemaAdapter.ts:1077-1079.',
      );
      expect(
        createValueFormatter('not a spec'),
        isNull,
        reason:
            'VegaLiteSchemaAdapter.ts:1083-1085 catches the d3 throw and returns '
            'undefined.',
      );
    },
  );

  test(
    'a temporal value parses to a DateTime and a quantitative one is left alone',
    () {
      expect(
        parseVegaValue('2024-01-05', isTemporal: true),
        DateTime.parse('2024-01-05'),
        reason: 'VegaLiteSchemaAdapter.ts:611-616.',
      );
      expect(
        parseVegaValue('12', isTemporal: false),
        '12',
        reason:
            'VegaLiteSchemaAdapter.ts:619-623: only a `typeof value === '
            "'number'` survives as a number, so a numeric STRING stays the "
            'string `String(value)` returns. // parity',
      );
      expect(
        parseVegaValue(12, isTemporal: false),
        12,
        reason: 'VegaLiteSchemaAdapter.ts:619-620.',
      );
      expect(
        parseVegaValue('abc', isTemporal: false),
        'abc',
        reason: 'VegaLiteSchemaAdapter.ts:623 keeps a plain string.',
      );
      expect(
        parseVegaValue(null, isTemporal: true),
        '',
        reason:
            'VegaLiteSchemaAdapter.ts:607-608: a hole becomes the empty string, not '
            'null. // parity',
      );
      expect(
        parseVegaValue('not a date', isTemporal: true),
        'not a date',
        reason:
            'VegaLiteSchemaAdapter.ts:613-614 falls through when the date is '
            'invalid.',
      );
    },
  );

  test('a validation failure carries the long human-readable suggestion verbatim', () {
    expect(
      () => validateVegaDataArray(const <Map<String, Object?>>[], 'x', 'line'),
      throwsA(
        isA<VegaSpecException>().having(
          (e) => e.message,
          'message',
          'VegaLiteSchemaAdapter: Empty data array for line',
        ),
      ),
      reason:
          'VegaLiteSchemaAdapter.ts:890-892; the validation messages at '
          ':978-987 are genuinely good UX and are preserved word for word.',
    );
    expect(
      () => validateVegaDataArray(
        const <Map<String, Object?>>[
          <String, Object?>{'y': 1},
        ],
        'x',
        'line',
      ),
      throwsA(
        isA<VegaSpecException>().having(
          (e) => e.message,
          'message',
          "VegaLiteSchemaAdapter: No valid values found for field 'x' in line",
        ),
      ),
      reason: 'VegaLiteSchemaAdapter.ts:895-897.',
    );
    expect(
      () => validateVegaNoNestedArrays(const <Map<String, Object?>>[
        <String, Object?>{
          'x': <Object?>[1, 2],
        },
      ], 'x'),
      throwsA(
        isA<VegaSpecException>().having(
          (e) => e.message,
          'message',
          "VegaLiteSchemaAdapter: Nested arrays not supported for field 'x'. "
              'Use flat data structures only.',
        ),
      ),
      reason:
          'VegaLiteSchemaAdapter.ts:910-911 concatenates the two literals, '
          'full stop and space included.',
    );
    expect(
      () => validateVegaEncodingType(
        const <Map<String, Object?>>[
          <String, Object?>{'t': 'yesterday'},
        ],
        't',
        'temporal',
      ),
      throwsA(
        isA<VegaSpecException>().having(
          (e) => e.message,
          'message',
          "VegaLiteSchemaAdapter: Field 't' marked as temporal but contains "
              'invalid date values. The data contains strings that are not '
              'valid dates (e.g., "yesterday"). Ensure dates are in ISO format '
              '(YYYY-MM-DD) or valid date strings.',
        ),
      ),
      reason: 'VegaLiteSchemaAdapter.ts:977-987, both literals verbatim.',
    );
    expect(
      () => validateVegaEncodingType(
        const <Map<String, Object?>>[
          <String, Object?>{'t': 5},
        ],
        't',
        'temporal',
      ),
      throwsA(
        isA<VegaSpecException>().having(
          (e) => e.message,
          'message',
          "VegaLiteSchemaAdapter: Field 't' marked as temporal but contains "
              'invalid date values. The data contains numbers. Change the type '
              'to "quantitative" instead.',
        ),
      ),
      reason: 'VegaLiteSchemaAdapter.ts:979-980.',
    );
    expect(
      () => validateVegaEncodingType(
        const <Map<String, Object?>>[
          <String, Object?>{'q': <String, Object?>{}},
        ],
        'q',
        'quantitative',
      ),
      throwsA(
        isA<VegaSpecException>().having(
          (e) => e.message,
          'message',
          "VegaLiteSchemaAdapter: Field 'q' marked as quantitative but "
              'contains non-numeric values (object).',
        ),
      ),
      reason:
          'VegaLiteSchemaAdapter.ts:970-972: only a string is auto-corrected, '
          'every other type is fatal.',
    );
    expect(
      validateVegaEncodingType(
        const <Map<String, Object?>>[
          <String, Object?>{'q': true},
        ],
        'q',
        'quantitative',
      ),
      isNull,
      reason:
          'VegaLiteSchemaAdapter.ts:953 is `typeof !== \'number\' && '
          '!isFinite(Number(sampleValue))`, and Number(true) is a finite 1, so '
          'a boolean column declared quantitative passes validation and is '
          'neither corrected nor rejected. // parity',
    );
  });

  test(
    'a string column declared quantitative is corrected to nominal in place',
    () {
      final encoding = <String, Object?>{
        'x': <String, Object?>{'field': 'name', 'type': 'quantitative'},
      };
      final corrected = validateVegaEncodingType(
        const <Map<String, Object?>>[
          <String, Object?>{'name': 'Alpha'},
        ],
        'name',
        'quantitative',
        encoding: encoding,
        channelName: 'x',
      );
      expect(
        corrected,
        'nominal',
        reason: 'VegaLiteSchemaAdapter.ts:962-966 returns the corrected type.',
      );
      expect(
        (encoding['x']! as Map<String, Object?>)['type'],
        'nominal',
        reason:
            'VegaLiteSchemaAdapter.ts:962-963 mutates the encoding it was '
            'handed, which is why the caller passes the cloned spec.',
      );
    },
  );

  test('a nominal channel and an all-null column are both waved through', () {
    expect(
      validateVegaEncodingType(
        const <Map<String, Object?>>[
          <String, Object?>{'n': 'Alpha'},
        ],
        'n',
        'nominal',
      ),
      isNull,
      reason: 'VegaLiteSchemaAdapter.ts:941-942.',
    );
    expect(
      validateVegaEncodingType(
        const <Map<String, Object?>>[
          <String, Object?>{'q': 0},
        ],
        'q',
        'temporal',
      ),
      isNull,
      reason:
          'VegaLiteSchemaAdapter.ts:948-950: `!sampleValue`, so a sample of 0 '
          'skips validation entirely rather than failing as a date. // parity',
    );
  });

  test('the four-step x and y validation runs every check in order', () {
    expect(
      () => validateVegaXYEncodings(
        const <Map<String, Object?>>[
          <String, Object?>{'x': 'a', 'y': 1},
        ],
        'x',
        'missing',
        'nominal',
        'quantitative',
        'line',
      ),
      throwsA(
        isA<VegaSpecException>().having(
          (e) => e.message,
          'message',
          "VegaLiteSchemaAdapter: No valid values found for field 'missing' "
              'in line',
        ),
      ),
      reason:
          'VegaLiteSchemaAdapter.ts:1017-1018 validates the y field as well '
          'as the x field.',
    );
  });

  test(
    'the tick config reads x values and both tick counts, and drops a zero count',
    () {
      final config = extractTickConfig(<String, Object?>{
        'encoding': <String, Object?>{
          'x': <String, Object?>{
            'axis': <String, Object?>{
              'values': <Object?>[1, 2, 3],
              'tickCount': 4,
            },
          },
          'y': <String, Object?>{
            'axis': <String, Object?>{'tickCount': 0},
          },
        },
      });
      expect(config.tickValues, <Object>[
        1,
        2,
        3,
      ], reason: 'VegaLiteSchemaAdapter.ts:866-867.');
      expect(
        config.xAxisTickCount,
        4,
        reason: 'VegaLiteSchemaAdapter.ts:869-870.',
      );
      expect(
        config.yAxisTickCount,
        isNull,
        reason:
            'VegaLiteSchemaAdapter.ts:875 is a truthiness test, so a tickCount '
            'of 0 reads as absent rather than as "no ticks". // parity',
      );
    },
  );

  test('the tick config ignores a layer, reading spec.encoding alone', () {
    final config = extractTickConfig(<String, Object?>{
      'layer': <Object?>[
        <String, Object?>{
          'mark': 'line',
          'encoding': <String, Object?>{
            'x': <String, Object?>{
              'axis': <String, Object?>{'tickCount': 7},
            },
          },
        },
      ],
    });
    expect(
      config.xAxisTickCount,
      isNull,
      reason:
          'VegaLiteSchemaAdapter.ts:863 reads spec.encoding, not the '
          "normalised layer's. // parity",
    );
  });

  test(
    'mark properties come off the object form and never off the string form',
    () {
      final properties = getMarkProperties(<String, Object?>{
        'type': 'line',
        'color': '#ff0000',
        'interpolate': 'natural',
        'strokeWidth': 3,
        'strokeDash': <Object?>[4, 2],
        'point': true,
      });
      expect(
        properties.color,
        '#ff0000',
        reason: 'VegaLiteSchemaAdapter.ts:675.',
      );
      expect(
        properties.interpolate,
        'natural',
        reason: 'VegaLiteSchemaAdapter.ts:675.',
      );
      expect(
        properties.strokeWidth,
        3.0,
        reason: 'VegaLiteSchemaAdapter.ts:675.',
      );
      expect(properties.strokeDash, <double>[
        4,
        2,
      ], reason: 'VegaLiteSchemaAdapter.ts:675.');
      expect(properties.point, true, reason: 'VegaLiteSchemaAdapter.ts:675.');
      expect(
        getMarkProperties('line').color,
        isNull,
        reason: 'VegaLiteSchemaAdapter.ts:667-668: a string mark carries none.',
      );
    },
  );
}
