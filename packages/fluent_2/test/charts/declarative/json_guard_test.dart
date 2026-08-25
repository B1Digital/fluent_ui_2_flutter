import 'package:fluent_2/src/charts/internal/plotly/json_guard.dart';
import 'package:flutter_test/flutter_test.dart';

/// One more level than [kPlotlyMaxJsonDepth] allows, so the leaf is reached at
/// depth 16 and `depth > 15` is true exactly once
/// (`PlotlySchemaConverter.ts:178`).
const int _tooDeep = 16;

/// The deepest document the guard must accept: the leaf sits at depth 15, and
/// `15 > 15` is false (`PlotlySchemaConverter.ts:176,178`).
const int _deepestAllowed = 15;

void main() {
  test('escapes the five HTML-significant characters, ampersand first', () {
    expect(
      sanitizePlotlyJson(<String, Object?>{'t': '<a href="x">&\'</a>'}),
      <String, Object?>{
        't': '&lt;a href=&quot;x&quot;&gt;&amp;&#39;&lt;/a&gt;',
      },
      reason:
          'hardened: PlotlySchemaConverter.ts:186 escapes only < and >, which '
          'lets an attacker smuggle an attribute break through a quote. The '
          'five-character set is upstream\'s own, at '
          'PlotlySchemaAdapter.ts:542-548.',
    );
  });

  test('does not mutate the caller map', () {
    final input = <String, Object?>{'t': '<b>'};
    sanitizePlotlyJson(input);
    expect(
      input['t'],
      '<b>',
      reason:
          'hardened: PlotlySchemaConverter.ts:186 assigns back into the caller '
          'object.',
    );
  });

  test('sanitises a map whose key type is not String', () {
    expect(
      sanitizePlotlyJson(<Object?, Object?>{'t': '<b>'}),
      <String, Object?>{'t': '&lt;b&gt;'},
      reason:
          'hardened: a Map with non-String type arguments is not a '
          'Map<String, Object?>, so a type test written that narrowly would '
          'return the untrusted map unescaped and unmeasured.',
    );
  });

  test('escapes a payload hidden under a prototype-pollution key', () {
    expect(
      sanitizePlotlyJson(<String, Object?>{
        '__proto__': <String, Object?>{'text': '<img onerror=x>'},
        'constructor': '<b>',
      }),
      <String, Object?>{
        '__proto__': <String, Object?>{'text': '&lt;img onerror=x&gt;'},
        'constructor': '&lt;b&gt;',
      },
      reason:
          'hardened: PlotlySchemaConverter.ts:186-188 writes the escaped value '
          'back with `jsonObject[key] = ...`, and for the own `__proto__` key '
          'JSON.parse creates that is a [[Set]] onto the Object.prototype '
          'accessor, not a data write — so the escaped string is silently '
          'dropped and an object value re-parents the node instead. Building a '
          'fresh Map makes every key ordinary data.',
    );
  });

  test(
    'rejects a document deeper than 15 without having rewritten anything',
    () {
      Object? nested = 'leaf';
      for (var i = 0; i < _tooDeep; i++) {
        nested = <String, Object?>{'k': nested};
      }
      expect(
        () => validatePlotlyJsonDepth(nested),
        throwsA(isA<PlotlySchemaException>()),
        reason: 'PlotlySchemaConverter.ts:178-180 throws past MAX_DEPTH = 15.',
      );
    },
  );

  test('accepts a document exactly at the depth limit', () {
    Object? nested = 'leaf';
    for (var i = 0; i < _deepestAllowed; i++) {
      nested = <String, Object?>{'k': nested};
    }
    expect(
      () => validatePlotlyJsonDepth(nested),
      returnsNormally,
      reason:
          'PlotlySchemaConverter.ts:178 throws on `depth > MAX_DEPTH`, not on '
          'equality; a guard that also rejects this one is off by one and '
          'would reject real schemas.',
    );
  });

  test('counts list nesting toward the depth budget', () {
    Object? nested = 'leaf';
    for (var i = 0; i < _tooDeep; i++) {
      nested = <Object?>[nested];
    }
    expect(
      () => validatePlotlyJsonDepth(nested),
      throwsA(isA<PlotlySchemaException>()),
      reason:
          'parity: `for (const key in ...)` at PlotlySchemaConverter.ts:183 '
          'enumerates array indices as well as object keys, so upstream does '
          'descend arrays and a port that skipped them would let an array '
          'chain exhaust the stack.',
    );
  });

  test('rejects a scheme-less protocol-relative URL', () {
    for (final href in <String>[
      '//evil.example/x',
      r'\\evil.example\x',
      r'/\evil.example',
    ]) {
      expect(
        isSafePlotlyUrl(href),
        isFalse,
        reason:
            'hardened: isSafeUrl.ts:12-15 returns true whenever no scheme is '
            'present, which admits the protocol-relative $href — it inherits '
            'https and leaks the referrer, and the browser URL parser folds a '
            'backslash pair onto the same target.',
      );
    }
  });

  test('rejects javascript: however it is obfuscated', () {
    for (final href in <String>[
      'javascript:alert(1)',
      'java\x00script:alert(1)',
      ' JaVaScRiPt:x',
      'data:text/html,x',
    ]) {
      expect(
        isSafePlotlyUrl(href),
        isFalse,
        reason:
            'isSafeUrl.ts:11 strips control and invisible characters before '
            'testing; the allowlist is http/https/mailto/tel/ftp '
            '(isSafeUrl.ts:1). Failed on $href.',
      );
    }
  });

  test('accepts the five allowed protocols and a bare relative path', () {
    for (final href in <String>[
      'http://a',
      'https://a',
      'mailto:a@b',
      'tel:+1',
      'ftp://a',
      'a/b.png',
    ]) {
      expect(
        isSafePlotlyUrl(href),
        isTrue,
        reason: 'isSafeUrl.ts:1 allowlist. Failed on $href.',
      );
    }
  });

  test('round-trips entity encoding, which Flutter Text cannot parse', () {
    expect(
      decodePlotlyHtmlEntities(encodePlotlyHtmlEntities('a<b&c')),
      'a<b&c',
      reason:
          'PlotlySchemaAdapter.ts:542-548 entity-encodes annotation text for '
          'the DOM; Flutter renders entities literally so the port must decode '
          'again.',
    );
  });

  test('round-trips text that already looks like an entity', () {
    expect(
      decodePlotlyHtmlEntities(encodePlotlyHtmlEntities('&lt;')),
      '&lt;',
      reason:
          'PlotlySchemaAdapter.ts:544 replaces & first so an existing entity '
          'becomes &amp;lt;; decoding & last is what makes that reversible '
          'rather than collapsing it to a literal <.',
    );
  });
}
