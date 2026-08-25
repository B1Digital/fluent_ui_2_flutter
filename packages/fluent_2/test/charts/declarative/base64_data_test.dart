import 'dart:convert';
import 'dart:typed_data';

import 'package:fluent_2/src/charts/internal/plotly/base64_data.dart';
import 'package:fluent_2/src/charts/internal/plotly/json_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String encodeF8(List<double> values) =>
      base64Encode(Float64List.fromList(values).buffer.asUint8List());

  test('decodes an f8 payload to doubles', () {
    final decoded = decodeBase64Fields(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'y': <String, Object?>{
            'bdata': encodeF8(<double>[1.5, -2.25]),
            'dtype': 'f8',
          },
        },
      ],
    });
    final trace =
        (decoded['data']! as List<Object?>).first! as Map<String, Object?>;
    expect(
      trace['y'],
      <double>[1.5, -2.25],
      reason: "DecodeBase64Data.ts:56-57 maps dtype 'f8' onto Float64Array.",
    );
  });

  test('decodes i2 to 16-bit signed ints', () {
    final bytes = Int16List.fromList(<int>[-1, 300]).buffer.asUint8List();
    final decoded = decodeBdataNode(<String, Object?>{
      'bdata': base64Encode(bytes),
      'dtype': 'i2',
    });
    expect(
      decoded,
      <int>[-1, 300],
      reason: "DecodeBase64Data.ts:64-65 maps dtype 'i2' onto Int16Array.",
    );
  });

  test('reshapes a flat payload with a two-dimensional shape', () {
    expect(
      reshapeArray(<double>[1, 2, 3, 4, 5, 6], <int>[2, 3]),
      <List<double>>[
        <double>[1, 2, 3],
        <double>[4, 5, 6],
      ],
      reason: 'DecodeBase64Data.ts:85-91 slices row by row for a 2-D shape.',
    );
  });

  test('parses a comma-separated shape string when JSON parsing fails', () {
    final decoded = decodeBdataNode(<String, Object?>{
      'bdata': base64Encode(
        Float64List.fromList(<double>[1, 2, 3, 4]).buffer.asUint8List(),
      ),
      'dtype': 'f8',
      'shape': '2, 2',
    });
    expect(
      decoded,
      <List<double>>[
        <double>[1, 2],
        <double>[3, 4],
      ],
      reason:
          'DecodeBase64Data.ts:131-136 falls back to comma-splitting when '
          'JSON.parse throws.',
    );
  });

  test('leaves a non-base64 bdata untouched', () {
    const node = <String, Object?>{'bdata': 'not base64!!', 'dtype': 'f8'};
    expect(
      decodeBdataNode(node),
      node,
      reason: 'DecodeBase64Data.ts:116 only decodes when isBase64 passes.',
    );
  });

  test('pads a base64 string whose length is not a multiple of four', () {
    final raw = base64Encode(
      Int8List.fromList(<int>[7]).buffer.asUint8List(),
    ).replaceAll('=', '');
    expect(
      decodeBdataNode(<String, Object?>{'bdata': raw, 'dtype': 'i1'}),
      <int>[7],
      reason:
          'DecodeBase64Data.ts:4-7 pads to a multiple of four before decoding.',
    );
  });

  test('throws when the payload length does not fill whole elements', () {
    // Seven bytes cannot be read as 64-bit floats. `new Float64Array(buffer)`
    // raises a RangeError inside the try at DecodeBase64Data.ts:53-77, which
    // upstream rethrows as `Failed to decode base64 value` at :76. Dart's
    // Float64List.view instead keeps the whole elements that fit and drops the
    // rest, returning [], so the port checks the length itself; this assertion
    // is what pins that it does.
    final seven = Uint8List.fromList(<int>[1, 2, 3, 4, 5, 6, 7]);
    expect(
      () => decodeBdataNode(<String, Object?>{
        'bdata': base64Encode(seven),
        'dtype': 'f8',
      }),
      throwsA(isA<PlotlySchemaException>()),
      reason:
          'DecodeBase64Data.ts:75-77 converts any decode failure into a throw.',
    );
  });

  test('renders an unrecognised dtype as the comma-joined bytes', () {
    expect(
      decodeBdataNode(<String, Object?>{
        'bdata': base64Encode(Uint8List.fromList(<int>[1, 2, 3])),
        'dtype': 'unknown',
      }),
      '1,2,3',
      reason:
          "DecodeBase64Data.ts:68-73 falls back to the byte array's own "
          'toString, which for a JavaScript TypedArray is the comma-joined '
          'elements.',
    );
  });

  test('decodes bdata nested below a non-data key', () {
    final decoded = decodeBdataNode(<String, Object?>{
      'marker': <String, Object?>{
        'color': <String, Object?>{
          'bdata': base64Encode(
            Int8List.fromList(<int>[3, 4]).buffer.asUint8List(),
          ),
          'dtype': 'i1',
        },
      },
    });
    expect(
      decoded,
      <String, Object?>{
        'marker': <String, Object?>{
          'color': <int>[3, 4],
        },
      },
      reason: 'DecodeBase64Data.ts:149-156 recurses into every remaining key.',
    );
  });

  test('leaves layout alone and replaces only data', () {
    final schema = <String, Object?>{
      'data': <Object?>[],
      'layout': <String, Object?>{
        'annotations': <Object?>[
          <String, Object?>{
            'bdata': encodeF8(<double>[1]),
            'dtype': 'f8',
          },
        ],
      },
    };
    final decoded = decodeBase64Fields(schema);
    expect(
      decoded['layout'],
      schema['layout'],
      reason: 'DecodeBase64Data.ts:160-164 assigns only the data key.',
    );
  });
}
