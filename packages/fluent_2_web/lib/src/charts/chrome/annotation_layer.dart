import 'package:flutter/widgets.dart';

import 'annotation_layer_style.dart';

/// One node of the annotation markup tree. `ChartAnnotationLayer.tsx:36-39`.
sealed class _MarkupNode {
  const _MarkupNode();
}

final class _MarkupText extends _MarkupNode {
  _MarkupText(this.content);

  String content;
}

final class _MarkupBreak extends _MarkupNode {
  const _MarkupBreak();
}

final class _MarkupElement extends _MarkupNode {
  _MarkupElement(this.tag);

  final String tag;
  final List<_MarkupNode> children = <_MarkupNode>[];
}

/// `ChartAnnotationLayer.tsx:48-53`. Note `nbsp` is U+00A0 at `:52`, not an
/// ordinary space.
const Map<String, String> _namedEntities = <String, String>{
  'amp': '&',
  'quot': '"',
  'apos': "'",
  'nbsp': '\u00a0',
};

/// `'<'.codePointAt(0)` and `'>'.codePointAt(0)`
/// (`ChartAnnotationLayer.tsx:34-35`).
const int _charCodeLessThan = 0x3c;
const int _charCodeGreaterThan = 0x3e;

/// The largest code point `String.fromCharCode` will accept.
const int _maxCodePoint = 0x10ffff;

/// `decodeSimpleMarkupInput` (`ChartAnnotationLayer.tsx:47-99`).
///
/// Two passes. The first decodes entities but deliberately re-emits `&lt;` and
/// `&gt;` — including numeric references that resolve to a chevron
/// (`:67-72`) — so no input can produce a raw chevron. The second then revives
/// exactly the `b`, `i` and `br` spellings the switch at `:82-97` lists, and
/// nothing else, so the re-escape bounds the tag vocabulary to those three.
String _decodeSimpleMarkupInput(String input) {
  final decoded = input.replaceAllMapped(
    // ChartAnnotationLayer.tsx:55.
    RegExp(r'&(#x?[0-9a-f]+|#\d+|[a-z][\w-]*);', caseSensitive: false),
    (match) {
      final entity = match.group(1)!.toLowerCase();
      if (entity == 'lt' || entity == 'gt') {
        // :57-59.
        return '&$entity;';
      }
      if (entity.startsWith('#')) {
        final isHex = entity.length > 1 && entity[1] == 'x';
        final digits = entity.substring(isHex ? 2 : 1);
        final codePoint = int.tryParse(digits, radix: isHex ? 16 : 10);
        // :64-66 — an unparseable reference is left as written. Dart's
        // tryParse also returns null where JavaScript would produce a number
        // too large to be a code point, and the range check below covers the
        // rest: upstream lets `String.fromCodePoint` throw there, which is not
        // worth reproducing for text a chart author may generate from data.
        if (codePoint == null || codePoint < 0 || codePoint > _maxCodePoint) {
          return match.group(0)!;
        }
        // :67-72 — the security property.
        if (codePoint == _charCodeLessThan) {
          return '&lt;';
        }
        if (codePoint == _charCodeGreaterThan) {
          return '&gt;';
        }
        return String.fromCharCode(codePoint);
      }
      // :75.
      return _namedEntities[entity] ?? match.group(0)!;
    },
  );

  return decoded.replaceAllMapped(
    // ChartAnnotationLayer.tsx:78.
    RegExp('&lt;([^;]+)&gt;', caseSensitive: false),
    (match) {
      // :79-80 — trim, collapse whitespace runs, lower-case.
      final normalised = match
          .group(1)!
          .trim()
          .replaceAll(RegExp(r'\s+'), ' ')
          .toLowerCase();
      return switch (normalised) {
        'b' => '<b>',
        '/b' => '</b>',
        'i' => '<i>',
        '/i' => '</i>',
        // :91-94 — three accepted spellings.
        'br' || 'br/' || 'br /' => '<br />',
        // :95-96.
        _ => match.group(0)!,
      };
    },
  );
}

/// `appendTextNode` (`ChartAnnotationLayer.tsx:101-112`).
void _appendText(List<_MarkupNode> nodes, String text) {
  if (text.isEmpty) {
    return;
  }
  final last = nodes.isEmpty ? null : nodes.last;
  if (last is _MarkupText) {
    last.content += text;
  } else {
    nodes.add(_MarkupText(text));
  }
}

/// `serializeSimpleMarkup` (`ChartAnnotationLayer.tsx:114-125`).
String _serialise(List<_MarkupNode> nodes) => nodes
    .map(
      (node) => switch (node) {
        _MarkupText() => node.content,
        _MarkupBreak() => '<br />',
        _MarkupElement() =>
          '<${node.tag}>${_serialise(node.children)}</${node.tag}>',
      },
    )
    .join();

/// `parseSimpleMarkup` (`ChartAnnotationLayer.tsx:127-208`).
List<_MarkupNode> _parse(String input) {
  // :128-130.
  if (input.isEmpty) {
    return <_MarkupNode>[];
  }
  final decoded = _decodeSimpleMarkupInput(input);
  final root = <_MarkupNode>[];
  // :134 — the sentinel frame stands for the root, so depth is length - 1.
  final stack = <_MarkupElement?>[null];
  List<_MarkupNode> current() => stack.last?.children ?? root;

  var lastIndex = 0;
  // :136.
  for (final match in RegExp(
    r'<\/?([a-z]+)\s*\/?\s*>',
    caseSensitive: false,
  ).allMatches(decoded)) {
    final full = match.group(0)!;
    final tag = match.group(1)!.toLowerCase();
    final isClosing = full.startsWith('</');
    final isSelfClosing = RegExp(r'\/\s*>$').hasMatch(full);

    _appendText(current(), decoded.substring(lastIndex, match.start));
    lastIndex = match.end;

    // :149-152.
    if (tag == 'br' && !isClosing) {
      current().add(const _MarkupBreak());
      continue;
    }
    // :154.
    if ((tag == 'b' || tag == 'i') && !isSelfClosing) {
      if (isClosing) {
        if (stack.length > 1 && stack.last?.tag == tag) {
          stack.removeLast();
        } else {
          // :160 — an unmatched closer is literal.
          _appendText(current(), full);
        }
      } else {
        // :163-166.
        if (stack.length - 1 >= kMaxSimpleMarkupDepth) {
          _appendText(current(), full);
          continue;
        }
        final element = _MarkupElement(tag);
        current().add(element);
        stack.add(element);
      }
      continue;
    }
    // :178 — any other tag is literal text.
    _appendText(current(), full);
  }
  // :181.
  _appendText(current(), decoded.substring(lastIndex));

  // :183-205 — every unclosed element is removed from its parent and written
  // back out as literal text, closing tag included.
  while (stack.length > 1) {
    final unclosed = stack.removeLast()!;
    final parent = stack.last?.children ?? root;
    parent.remove(unclosed);
    _appendText(
      parent,
      '<${unclosed.tag}>${_serialise(unclosed.children)}</${unclosed.tag}>',
    );
  }
  return root;
}

/// `renderSimpleMarkupNodeList` (`ChartAnnotationLayer.tsx:223-237`).
List<InlineSpan> _toSpans(List<_MarkupNode> nodes, TextStyle style) {
  return <InlineSpan>[
    for (final node in nodes)
      switch (node) {
        _MarkupText() => TextSpan(text: node.content, style: style),
        // :232 renders <br />; a newline inside a TextSpan is the same break
        // for a widget that wraps.
        _MarkupBreak() => TextSpan(text: '\n', style: style),
        // :235 — b becomes strong, i becomes em.
        _MarkupElement() => _emphasised(node, style),
      },
  ];
}

/// One `strong` or `em` element and its subtree
/// (`ChartAnnotationLayer.tsx:235-236`).
TextSpan _emphasised(_MarkupElement node, TextStyle style) {
  final emphasised = node.tag == 'b'
      ? style.copyWith(fontWeight: FontWeight.bold)
      : style.copyWith(fontStyle: FontStyle.italic);
  return TextSpan(
    style: emphasised,
    children: _toSpans(node.children, emphasised),
  );
}

/// `simpleMarkupNodesToPlainText` (`ChartAnnotationLayer.tsx:210-221`).
String _plain(List<_MarkupNode> nodes) => nodes
    .map(
      (node) => switch (node) {
        _MarkupText() => node.content,
        _MarkupBreak() => '\n',
        _MarkupElement() => _plain(node.children),
      },
    )
    .join();

/// Parses an annotation's `b` / `i` / `br` markup into spans over [base].
///
/// Ports `parseSimpleMarkup` and `renderSimpleMarkup`
/// (`ChartAnnotationLayer.tsx:127-241`). Those three tags are the whole
/// supported vocabulary; anything else is emitted as literal text, and a
/// chevron arriving through a numeric entity is re-escaped so it can only ever
/// reach that same three-name allowlist (`:67-72`).
List<InlineSpan> parseFluentAnnotationMarkup(String text, TextStyle base) =>
    _toSpans(_parse(text), base);

/// The annotation's text with markup removed and `br` turned into a newline.
///
/// `simpleMarkupNodesToPlainText` (`ChartAnnotationLayer.tsx:210-221`), used as
/// the default accessible label at `:658`.
String fluentAnnotationPlainText(String text) => _plain(_parse(text));
