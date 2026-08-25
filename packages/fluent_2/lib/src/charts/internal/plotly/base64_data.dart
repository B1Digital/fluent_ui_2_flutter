import 'dart:convert';
import 'dart:typed_data';

import 'json_guard.dart';

/// The character set `isBase64` accepts (`DecodeBase64Data.ts:20`).
final RegExp _base64Body = RegExp(r'^[A-Za-z0-9+/]+={0,2}$');

/// Pads [s] to a multiple of four with `=` (`DecodeBase64Data.ts:4-7`).
String _addPadding(String s) => s + '=' * ((4 - (s.length % 4)) % 4);

/// Whether [s] is a base64 payload (`DecodeBase64Data.ts:9-31`).
bool _isBase64(String s) {
  final padded = s.length % 4 != 0 ? _addPadding(s) : s;
  if (!_base64Body.hasMatch(padded)) {
    return false;
  }
  try {
    base64Decode(padded);
    return true;
  } on FormatException {
    return false;
  }
}

/// Decodes one base64 payload according to its Plotly `dtype`.
///
/// The dtype table is `DecodeBase64Data.ts:55-74` verbatim, including its own
/// admission at `:59` that `i8` is read as 32-bit because `BigInt64Array` was
/// unavailable. Reproduced: a genuine 64-bit payload therefore decodes to twice
/// as many wrong numbers, which is upstream behaviour every fixture already
/// encodes. // parity: DecodeBase64Data.ts:59
///
/// A payload whose length does not fill whole elements makes the corresponding
/// `new Float64Array(buffer)` raise a `RangeError`, which `:75-77` rethrows as
/// `Failed to decode base64 value`. Dart's `TypedData.view` does not: it takes
/// as many whole elements as fit and drops the remainder, so seven bytes read
/// as `f8` come back as an empty list rather than an error. [_requireWhole]
/// restores the upstream throw, because silently returning short data from an
/// untrusted document is the worse of the two.
Object _decodeTyped(Uint8List bytes, String dtype) {
  final buffer = bytes.buffer;
  final offset = bytes.offsetInBytes;
  final available = buffer.lengthInBytes - offset;
  switch (dtype) {
    case 'f8':
      _requireWhole(available, Float64List.bytesPerElement);
      return Float64List.view(buffer, offset).toList();
    case 'i8':
    case 'i4':
      _requireWhole(available, Int32List.bytesPerElement);
      return Int32List.view(buffer, offset).toList();
    case 'u8':
      _requireWhole(available, Uint32List.bytesPerElement);
      return Uint32List.view(buffer, offset).toList();
    case 'i2':
      _requireWhole(available, Int16List.bytesPerElement);
      return Int16List.view(buffer, offset).toList();
    case 'i1':
      // One byte per element, so no length can be partial.
      return Int8List.view(buffer, offset).toList();
    default:
      // `DecodeBase64Data.ts:68-73` falls back to the byte array's own
      // `toString`. A JavaScript `Uint8Array` stringifies as its comma-joined
      // elements, where Dart's would bracket and space them, so the join is
      // written out rather than delegated.
      return bytes.join(',');
  }
}

/// Throws unless [available] bytes divide into whole [bytesPerElement] units.
void _requireWhole(int available, int bytesPerElement) {
  if (available % bytesPerElement != 0) {
    throw const PlotlySchemaException('Failed to decode base64 value');
  }
}

/// Reshapes a flat [data] list into [shape] (`DecodeBase64Data.ts:81-101`).
///
/// A one-dimensional shape returns the list unchanged; two dimensions slice row
/// by row; anything deeper recurses on `data.length / shape.first` chunks.
Object reshapeArray(List<num> data, List<int> shape) {
  if (shape.length <= 1) {
    return data;
  }
  if (shape.length == 2) {
    final rows = shape[0];
    final cols = shape[1];
    return <List<num>>[
      for (var r = 0; r < rows; r++) data.sublist(r * cols, (r + 1) * cols),
    ];
  }
  final dim = shape.first;
  final step = data.length ~/ dim;
  return <Object>[
    for (var i = 0; i < dim; i++)
      reshapeArray(data.sublist(i * step, (i + 1) * step), shape.sublist(1)),
  ];
}

/// [values] as ints, or null if any entry is not a number.
///
/// Upstream's `isArrayOrTypedArray` check at `DecodeBase64Data.ts:128` and
/// `:142` only asks whether the shape is an array, so a `["a"]` shape reaches
/// `reshapeArray` and slices on `NaN`. Refusing it here leaves the payload flat
/// instead, which is the same outcome without the arithmetic.
List<int>? _toIntList(List<Object?> values) {
  final out = <int>[];
  for (final value in values) {
    if (value is! num) {
      return null;
    }
    out.add(value.toInt());
  }
  return out;
}

/// Reads a `shape` field, which arrives as a list or as a string
/// (`DecodeBase64Data.ts:119-139`).
List<int>? _parseShape(Object? shape) {
  if (shape is List<Object?>) {
    return _toIntList(shape);
  }
  if (shape is! String) {
    return null;
  }
  try {
    final parsed = jsonDecode(shape);
    if (parsed is List<Object?>) {
      return _toIntList(parsed);
    }
  } on FormatException {
    // Falls through to the comma-separated form (`DecodeBase64Data.ts:131-136`).
  }
  final parts = shape
      .split(',')
      .map((part) => num.tryParse(part.trim()))
      .toList();
  return parts.any((value) => value == null)
      ? null
      : <int>[for (final value in parts) value!.toInt()];
}

/// Decodes one node of a Plotly figure, recursing into maps and lists.
///
/// A map carrying a base64 `bdata` string becomes the decoded array, reshaped
/// when a usable `shape` is present (`DecodeBase64Data.ts:104-157`).
Object? decodeBdataNode(Object? node) {
  if (node is List<Object?>) {
    return <Object?>[for (final item in node) decodeBdataNode(item)];
  }
  if (node is! Map<String, Object?>) {
    return node;
  }

  final bdata = node['bdata'];
  if (bdata is String && _isBase64(bdata)) {
    final dtype = node['dtype'];
    // `:117` defaults a missing dtype to `utf-8`, which the dtype table does
    // not name and which therefore takes its stringifying fallback.
    final decoded = _decodeTyped(
      base64Decode(_addPadding(bdata)),
      dtype is String ? dtype : 'utf-8',
    );
    final shape = _parseShape(node['shape']);
    if (decoded is List<num> && shape != null && shape.isNotEmpty) {
      return reshapeArray(decoded, shape);
    }
    return decoded;
  }

  return <String, Object?>{
    for (final entry in node.entries) entry.key: decodeBdataNode(entry.value),
  };
}

/// Decodes every base64 `bdata` field under `schema['data']`.
///
/// `DecodeBase64Data.ts:160-164` touches only the `data` key, never `layout`.
Map<String, Object?> decodeBase64Fields(Map<String, Object?> schema) =>
    <String, Object?>{...schema, 'data': decodeBdataNode(schema['data'])};
