/// Maximum nesting depth a Plotly schema may reach.
///
/// `PlotlySchemaConverter.ts:176` sets `MAX_DEPTH = 15`;
/// `VegaDeclarativeChart.tsx:43` repeats the same constant so the two adapters
/// agree.
const int kPlotlyMaxJsonDepth = 15;

/// Raised when a schema is malformed, unsupported or unsafe.
///
/// Upstream throws bare `Error`s; the port carries a single named type so the
/// widget's `errorBuilder` can distinguish schema failure from a programming
/// mistake.
class PlotlySchemaException implements Exception {
  /// Creates an exception carrying [message].
  const PlotlySchemaException(this.message);

  /// The human-readable reason, formatted to match upstream's text where
  /// upstream has text worth preserving.
  final String message;

  @override
  String toString() => 'PlotlySchemaException: $message';
}

const Map<String, String> _entities = <String, String>{
  '&': '&amp;',
  '<': '&lt;',
  '>': '&gt;',
  '"': '&quot;',
  "'": '&#39;',
};

/// HTML-entity-encodes [value].
///
/// `PlotlySchemaAdapter.ts:542-548` encodes annotation text before it reaches
/// the DOM. The ampersand is replaced first so an already-encoded entity is
/// not double-decoded on the way back.
String encodePlotlyHtmlEntities(String value) {
  var out = value.replaceAll('&', '&amp;');
  for (final entry in _entities.entries) {
    if (entry.key == '&') {
      continue;
    }
    out = out.replaceAll(entry.key, entry.value);
  }
  return out;
}

/// Reverses [encodePlotlyHtmlEntities].
///
/// Required because Flutter's `Text` renders `&lt;` literally where the DOM
/// renders `<`. Ampersand is decoded last, for the same reason it is encoded
/// first.
String decodePlotlyHtmlEntities(String value) {
  var out = value;
  for (final entry in _entities.entries) {
    if (entry.key == '&') {
      continue;
    }
    out = out.replaceAll(entry.value, entry.key);
  }
  return out.replaceAll('&amp;', '&');
}

/// Throws when [value] nests deeper than [kPlotlyMaxJsonDepth].
///
/// hardened: `PlotlySchemaConverter.ts:177-195` checks the depth *while* it
/// rewrites, so a document that is too deep has already been partly mutated by
/// the time it throws. This version only reads, which is what lets
/// [sanitizePlotlyJson] leave a rejected document untouched.
///
/// parity: the recursion descends lists as well as maps because upstream's
/// `for (const key in ...)` at `:183` enumerates array indices too. It is a
/// type test here rather than a `typeof === 'object'` because Dart maps and
/// lists share no supertype worth testing for.
void validatePlotlyJsonDepth(Object? value, [int depth = 0]) {
  if (depth > kPlotlyMaxJsonDepth) {
    throw const PlotlySchemaException('Maximum json depth exceeded');
  }
  // hardened: `Map<Object?, Object?>` rather than `Map<String, Object?>`. Map
  // is covariant in its type arguments, so the narrow test matches every
  // string-keyed map but silently skips a `Map<dynamic, dynamic>` — which is
  // what an untyped caller's `{}` literal is — leaving it unmeasured and, in
  // `_sanitize` below, unescaped. Same reasoning for `List<Object?>`.
  if (value is Map<Object?, Object?>) {
    for (final child in value.values) {
      validatePlotlyJsonDepth(child, depth + 1);
    }
  } else if (value is List<Object?>) {
    for (final child in value) {
      validatePlotlyJsonDepth(child, depth + 1);
    }
  }
}

/// Returns a deep copy of [value] with every string HTML-entity-encoded.
///
/// hardened, three ways, against `PlotlySchemaConverter.ts:177-195`: the copy
/// is fresh rather than an in-place rewrite of the caller's object; the escape
/// set covers `&`, `"` and `'` as well as `<` and `>`; and the depth check runs
/// to completion before any escaping, so a rejected document is untouched.
///
/// The fresh copy is also what defuses a `__proto__` key: upstream's
/// `jsonObject[key] = ...` at `:186-188` is a JavaScript [[Set]], which for
/// that key hits the `Object.prototype` accessor instead of writing a property
/// — dropping the escaped string, or re-parenting the node when the value is an
/// object. A Dart map key is only ever data.
Object? sanitizePlotlyJson(Object? value) {
  validatePlotlyJsonDepth(value);
  return _sanitize(value);
}

Object? _sanitize(Object? value) {
  if (value is String) {
    return encodePlotlyHtmlEntities(value);
  }
  if (value is Map<Object?, Object?>) {
    // Keys are Plotly property names, matched literally by the converter, and
    // upstream escapes only values (`PlotlySchemaConverter.ts:185-186`).
    // Escaping them here would break every lookup. They are normalised to
    // String so the result is the `Map<String, Object?>` the converter reads.
    return <String, Object?>{
      for (final entry in value.entries) '${entry.key}': _sanitize(entry.value),
    };
  }
  if (value is List<Object?>) {
    return <Object?>[for (final child in value) _sanitize(child)];
  }
  return value;
}

/// The protocols a chart may link to (`isSafeUrl.ts:1`).
const Set<String> _allowedUrlSchemes = <String>{
  'http',
  'https',
  'mailto',
  'tel',
  'ftp',
};

/// Control, whitespace and invisible separators an attacker uses to break up a
/// scheme name (`isSafeUrl.ts:11`).
final RegExp _urlNoise = RegExp(r'[\x00-\x1f\x7f\s\u200b-\u200d\u2060\ufeff]+');

final RegExp _urlScheme = RegExp(
  r'^([a-z][a-z0-9+.\-]*):',
  caseSensitive: false,
);

/// Whether [href] may be navigated to.
///
/// hardened against `isSafeUrl.ts:12-15`, which returns `true` for anything
/// without a scheme and therefore admits `//evil.example`, a protocol-relative
/// URL that inherits the page's scheme. Here a leading `//` is rejected and
/// everything else scheme-less is treated as a same-origin relative path.
bool isSafePlotlyUrl(String href) {
  final normalised = href.replaceAll(_urlNoise, '');
  // hardened: the WHATWG URL parser folds a backslash onto a forward slash for
  // every special scheme, so `\\evil.example` and `/\evil.example` reach the
  // same host as `//evil.example`. Folding before the test closes all four
  // spellings at once; a leading single `\` folds to an absolute same-origin
  // path, which is harmless.
  if (normalised.replaceAll(r'\', '/').startsWith('//')) {
    return false;
  }
  final match = _urlScheme.firstMatch(normalised);
  if (match == null) {
    return true;
  }
  return _allowedUrlSchemes.contains(match.group(1)!.toLowerCase());
}
