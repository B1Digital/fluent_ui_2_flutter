import 'package:flutter/widgets.dart';

import '../internal/d3/scale.dart';
import '../model/chart_annotation.dart';
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

/// The geometry an annotation layer resolves its coordinates against.
///
/// Ports `ChartAnnotationContext` (`ChartAnnotationLayer.types.ts:15-31`).
/// `svgRect` becomes [chartSize] and `plotRect` a [Rect].
@immutable
class FluentChartAnnotationContext {
  /// Creates a context.
  const FluentChartAnnotationContext({
    required this.plotRect,
    required this.chartSize,
    required this.isRtl,
    this.xScale,
    this.yScalePrimary,
    this.yScaleSecondary,
  });

  /// The plotting area, in chart coordinates
  /// (`ChartAnnotationLayer.types.ts:17`).
  final Rect plotRect;

  /// The whole chart's size, used as the clamping viewport when an annotation
  /// opts out of the plot bounds (`ChartAnnotationLayer.types.ts:19`).
  final Size chartSize;

  /// Whether the chart is laid out right-to-left
  /// (`ChartAnnotationLayer.types.ts:21`).
  final bool isRtl;

  /// The x scale, or null when the chart has none
  /// (`ChartAnnotationLayer.types.ts:24`).
  final Scale? xScale;

  /// The primary y scale (`ChartAnnotationLayer.types.ts:27`).
  final Scale? yScalePrimary;

  /// The secondary y scale, for annotations that name it
  /// (`ChartAnnotationLayer.types.ts:30`).
  final Scale? yScaleSecondary;
}

/// An annotation's datum anchor and its box's reference point.
///
/// Ports `ResolvedAnnotationPosition` — what `resolveCoordinates` returns
/// (`ChartAnnotationLayer.tsx:390-393`).
@immutable
class FluentResolvedAnnotationPosition {
  /// Creates a resolved position.
  const FluentResolvedAnnotationPosition({
    required this.anchor,
    required this.point,
  });

  /// The datum itself. The connector is always drawn to this
  /// (`ChartAnnotationLayer.tsx:380`).
  final Offset anchor;

  /// The box's reference point: the anchor plus the layout offsets, optionally
  /// clamped (`ChartAnnotationLayer.tsx:382-388`).
  final Offset point;
}

/// Scales [value], centring it on its band when [scale] has a bandwidth.
///
/// `normalizeBandOffset` (`ChartAnnotationLayer.tsx:243-255`). Returns null for
/// anything that does not scale to a finite number, which drops the whole
/// annotation at the call site rather than drawing it at NaN.
double? fluentAnnotationBandOffset(Scale? scale, Object? value) {
  // `scale?.(value as never)` at :247. A null value cannot reach a Dart Scale,
  // whose `call` takes a non-nullable Object, and is the `typeof position !==
  // 'number'` case at :248 either way.
  if (scale == null || value == null) {
    return null;
  }
  final position = scale(value);
  // :248-250 — a band-scale miss and a non-numeric continuous input are both
  // null here, and only a log scale's negative input is NaN.
  if (position == null || position.isNaN) {
    return null;
  }
  // :251-253. Upstream branches on `typeof scale.bandwidth === 'function'`,
  // which is the band scales; a continuous Scale reports a bandwidth of 0
  // (`scale.dart`'s contract, `scale_continuous.dart:143`), so adding half of
  // it unconditionally is the same arithmetic without the type test.
  return position + scale.bandwidth / 2;
}

/// One axis of one coordinate, in the space that axis names.
///
/// `resolveAxisCoordinate` (`ChartAnnotationLayer.tsx:284-309`), which delegates
/// its `data` case to `resolveDataCoordinate` (`:261-282`).
double? _resolveAxis(
  FluentCoordinateSpace space,
  Object? value,
  FluentChartAnnotationContext context, {
  required bool isX,
  FluentAnnotationYAxis yAxis = FluentAnnotationYAxis.primary,
}) {
  switch (space) {
    case FluentCoordinateSpace.data:
      // :268-270 and :276-279 — no scale, no annotation.
      final scale = isX
          ? context.xScale
          : (yAxis == FluentAnnotationYAxis.secondary
                ? context.yScaleSecondary
                : context.yScalePrimary);
      if (scale == null) {
        return null;
      }
      // :272 and :280 — a Date is scaled by its epoch milliseconds.
      final parsed = value is DateTime ? value.millisecondsSinceEpoch : value;
      return fluentAnnotationBandOffset(scale, parsed);
    case FluentCoordinateSpace.relative:
      // :295-297.
      if (value is! num || value.isNaN) {
        return null;
      }
      // :298-300.
      return isX
          ? context.plotRect.left + context.plotRect.width * value
          : context.plotRect.top + context.plotRect.height * value;
    case FluentCoordinateSpace.pixel:
      // :302-304.
      if (value is! num || value.isNaN) {
        return null;
      }
      // :305.
      return isX ? context.plotRect.left + value : context.plotRect.top + value;
  }
}

/// Resolves [annotation]'s anchor and box reference point, or null to skip it.
///
/// `resolveCoordinates` (`ChartAnnotationLayer.tsx:353-394`). Returning null
/// drops the annotation entirely, which is what upstream does when either axis
/// fails to resolve (`:376-378`).
///
/// The `clipToBounds` clamp applied here is the **first** of its two meanings:
/// `:385` clamps the anchor-derived point only when the flag is truthy. The
/// second — selecting the viewport for the box clamp with `!== false` at
/// `:544` — lives in the layout step, and `null` behaves differently from both
/// `true` and `false`; [FluentChartAnnotationLayout.clampsAnchor] and
/// [FluentChartAnnotationLayout.clampsViewport] are the two readings.
FluentResolvedAnnotationPosition? resolveFluentAnnotationCoordinates(
  FluentChartAnnotation annotation,
  FluentChartAnnotationContext context,
) {
  final coordinates = annotation.coordinates;
  // `getCoordinateDescriptor` (:334-351). A sealed class makes the `default`
  // arm at :348-349 unreachable, so there is no null descriptor to guard.
  final (xSpace, ySpace, x, y, yAxis) = switch (coordinates) {
    // :336-337.
    FluentDataCoordinate() => (
      FluentCoordinateSpace.data,
      FluentCoordinateSpace.data,
      coordinates.x,
      coordinates.y,
      coordinates.yAxis,
    ),
    // :338-339.
    FluentRelativeCoordinate() => (
      FluentCoordinateSpace.relative,
      FluentCoordinateSpace.relative,
      coordinates.x,
      coordinates.y,
      FluentAnnotationYAxis.primary,
    ),
    // :340-341.
    FluentPixelCoordinate() => (
      FluentCoordinateSpace.pixel,
      FluentCoordinateSpace.pixel,
      coordinates.x,
      coordinates.y,
      FluentAnnotationYAxis.primary,
    ),
    // :342-347.
    FluentMixedCoordinate() => (
      coordinates.xSpace,
      coordinates.ySpace,
      coordinates.x,
      coordinates.y,
      coordinates.yAxis,
    ),
  };

  // :371 — the x axis never reads the yAxis selector.
  final anchorX = _resolveAxis(xSpace, x, context, isX: true);
  // :372-374.
  final anchorY = _resolveAxis(ySpace, y, context, isX: false, yAxis: yAxis);
  // :376-378.
  if (anchorX == null || anchorY == null) {
    return null;
  }

  final layout = annotation.layout;
  // :380.
  final anchor = Offset(anchorX, anchorY);
  // :368-369 and :382-383.
  var left = anchorX + (layout?.offsetX ?? 0);
  var top = anchorY + (layout?.offsetY ?? 0);

  // :385 — TRUTHY only, which is what clampsAnchor reads.
  if (layout?.clampsAnchor ?? false) {
    // :386-387.
    left = left.clamp(context.plotRect.left, context.plotRect.right);
    top = top.clamp(context.plotRect.top, context.plotRect.bottom);
  }

  // :390-393.
  return FluentResolvedAnnotationPosition(
    anchor: anchor,
    point: Offset(left, top),
  );
}
