/// The nesting-depth ceiling for an incoming Vega-Lite spec
/// (`VegaDeclarativeChart.tsx:43`).
///
/// Deliberately the same number as the Plotly adapter's `kPlotlyMaxJsonDepth`,
/// and for the same reason upstream gives at `:41`: an attacker-supplied spec
/// must not be able to exhaust the stack.
const int kVegaMaxJsonDepth = 15;

/// Raised for a spec this port refuses to read.
class VegaSpecException implements Exception {
  /// Creates an exception carrying [message].
  const VegaSpecException(this.message);

  /// The failure, phrased exactly as upstream phrases it so a consumer matching
  /// on the string keeps working.
  final String message;

  @override
  String toString() => message;
}

/// Rejects a spec nested deeper than [kVegaMaxJsonDepth]
/// (`VegaDeclarativeChart.tsx:49-58`).
///
/// Both maps and lists are descended. That is parity rather than hardening:
/// `:53` tests `typeof value === 'object'`, which is true of an array, and
/// `:54` enumerates `Object.keys`, which for an array is its indices — so a
/// chain of arrays is already counted upstream.
///
/// [depth] is the caller's current level and defaults to the root, so the
/// public call form is `validateVegaJsonDepth(value)`; the recursion needs the
/// counter, and a private helper would only duplicate the two type tests.
void validateVegaJsonDepth(Object? value, [int depth = 0]) {
  if (depth > kVegaMaxJsonDepth) {
    // `VegaDeclarativeChart.tsx:51`, message verbatim.
    throw const VegaSpecException(
      'VegaDeclarativeChart: Maximum JSON depth exceeded',
    );
  }
  if (value is Map<String, Object?>) {
    for (final child in value.values) {
      validateVegaJsonDepth(child, depth + 1);
    }
  } else if (value is List<Object?>) {
    for (final child in value) {
      validateVegaJsonDepth(child, depth + 1);
    }
  }
}

/// A deep copy of [spec], safe to mutate.
///
/// hardened: `autoCorrectEncodingTypes` mutates its argument in place
/// (`VegaLiteSchemaAdapter.ts:1553-1627`) and rewrites data rows at
/// `:1606-1610`. Upstream hands it the caller's own object, so rendering a
/// chart silently edits the caller's spec — a Flutter widget that mutated its
/// own immutable constructor argument would be a genuine defect, not parity.
/// Every entry point clones first.
///
/// Anything that is neither a map nor a list is copied by reference, which is
/// the same reachability upstream's spread has, and is safe for the scalars,
/// `DateTime`s and `Duration`s a decoded spec holds because they are immutable.
Map<String, Object?> deepCloneVegaSpec(Map<String, Object?> spec) =>
    _cloneNode(spec)! as Map<String, Object?>;

Object? _cloneNode(Object? node) {
  if (node is Map<String, Object?>) {
    return <String, Object?>{
      for (final entry in node.entries) entry.key: _cloneNode(entry.value),
    };
  }
  if (node is List<Object?>) {
    return <Object?>[for (final child in node) _cloneNode(child)];
  }
  return node;
}

/// The mark type, whether the mark is a bare string or a `{type: …}` object
/// (`VegaLiteSchemaAdapter.ts:95-100`).
///
/// Returns null for an absent mark; upstream's `!mark` test at `:96` also
/// treats the empty string as absent.
String? getMarkType(Object? mark) {
  if (mark == null || mark == '') {
    return null;
  }
  if (mark is String) {
    return mark;
  }
  if (mark is Map<String, Object?>) {
    final type = mark['type'];
    return type is String ? type : null;
  }
  return null;
}

/// True for a layered spec (`VegaLiteSchemaAdapter.ts:81-83`).
///
/// An empty `layer` array is **not** a layer spec, which is what stops a
/// normalisation of `{layer: []}` returning a list of zero charts.
bool isVegaLayerSpec(Map<String, Object?> spec) {
  final layer = spec['layer'];
  return layer is List<Object?> && layer.isNotEmpty;
}

/// True for a single unit spec (`VegaLiteSchemaAdapter.ts:88-90`).
///
/// Both `mark` and `encoding` must be present; a spec with only a mark is not a
/// unit spec and normalises to nothing.
bool isVegaUnitSpec(Map<String, Object?> spec) =>
    spec['mark'] != null && spec['encoding'] != null;

/// The inline rows of a dataset (`VegaLiteSchemaAdapter.ts:141-163`).
///
/// A `url` or a `name` yields the empty list, exactly as upstream's two `TODO`s
/// do at `:150-160`. Keeping that behaviour is deliberate: a chart widget must
/// not perform network I/O during `build`.
List<Map<String, Object?>> extractVegaDataValues(Object? data) {
  if (data is! Map<String, Object?>) {
    return const <Map<String, Object?>>[];
  }
  final values = data['values'];
  if (values is List<Object?>) {
    return <Map<String, Object?>>[
      for (final row in values)
        if (row is Map<String, Object?>) row,
    ];
  }
  // `:150-160`: a remote url and a named dataset both fall through to empty.
  return const <Map<String, Object?>>[];
}
