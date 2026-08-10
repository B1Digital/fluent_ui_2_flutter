import 'dart:math' as math;

import 'package:flutter/foundation.dart';
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

/// An annotation box after alignment and clamping.
@immutable
class FluentAnnotationBox {
  /// Creates a laid-out box.
  const FluentAnnotationBox({
    required this.rect,
    required this.displayPoint,
    required this.anchor,
  });

  /// Where the box is painted.
  final Rect rect;

  /// The box's reference point after clamping — where a connector starts.
  final Offset displayPoint;

  /// The datum, unchanged, so a later pass can still reach it.
  final Offset anchor;
}

/// Aligns and clamps an annotation box. `ChartAnnotationLayer.tsx:532-559`.
///
/// [measured] is the box's real size. Upstream falls back to
/// `layout.maxWidth ?? 180` and `60` (`:535-536`) because a hidden `div` cannot
/// be measured until after the first paint; Flutter measures synchronously, so
/// those defaults never bind — see the plan's recorded contract deviation.
///
/// This is where `clipToBounds`'s **second** meaning lives: `:544` selects the
/// clamping viewport with `!== false`, so a null flag clips the box to the plot
/// rect even though `:385` left the point alone
/// ([FluentChartAnnotationLayout.clampsViewport]).
FluentAnnotationBox fluentLayoutAnnotationBox({
  required FluentResolvedAnnotationPosition resolved,
  required Size measured,
  required FluentChartAnnotationLayout? layout,
  required FluentChartAnnotationContext context,
}) {
  // ChartAnnotationLayer.tsx:535-536.
  final width = math.max(measured.width, 1.0);
  final height = math.max(measured.height, 1.0);

  // ChartAnnotationLayer.tsx:538-539, with the :26-27 defaults.
  final offsetX = switch (layout?.align ?? FluentChartAnnotationAlign.center) {
    FluentChartAnnotationAlign.center => -width / 2,
    FluentChartAnnotationAlign.end => -width,
    FluentChartAnnotationAlign.start => 0.0,
  };
  final offsetY = switch (layout?.verticalAlign ??
      FluentChartAnnotationVerticalAlign.middle) {
    FluentChartAnnotationVerticalAlign.middle => -height / 2,
    FluentChartAnnotationVerticalAlign.bottom => -height,
    FluentChartAnnotationVerticalAlign.top => 0.0,
  };

  // ChartAnnotationLayer.tsx:541-542.
  final baseLeft = resolved.point.dx + offsetX;
  final baseTop = resolved.point.dy + offsetY;

  // ChartAnnotationLayer.tsx:544 — `!== false`, so a null flag still clips.
  final viewport = (layout?.clampsViewport ?? true)
      ? context.plotRect
      // :547-548 — the svgRect, whose origin is the svg's own.
      : Offset.zero & context.chartSize;

  // ChartAnnotationLayer.tsx:550-554 — clamping is skipped for a zero-size
  // viewport, and the upper bound is floored at the origin so a box larger than
  // the viewport pins rather than inverting.
  // The two maxima are hoisted, as :550-551 hoists maxTopLeftX/maxTopLeftY;
  // inline they would also infer as num from clamp's parameter type.
  final maxLeft = math.max(viewport.left, viewport.right - width);
  final maxTop = math.max(viewport.top, viewport.bottom - height);
  final left = viewport.width > 0
      ? baseLeft.clamp(viewport.left, maxLeft)
      : baseLeft;
  final top = viewport.height > 0
      ? baseTop.clamp(viewport.top, maxTop)
      : baseTop;

  return FluentAnnotationBox(
    rect: Rect.fromLTWH(left, top, width, height),
    // ChartAnnotationLayer.tsx:556-559 — undo the alignment offset so the
    // connector starts from the clamped box, not the original point.
    displayPoint: Offset(left - offsetX, top - offsetY),
    anchor: resolved.anchor,
  );
}

/// `clamp` (`ChartAnnotationLayer.tsx:257`).
///
/// `Math.max(min, Math.min(max, value))`, which — unlike Dart's `num.clamp` —
/// does not throw when [max] falls below [min]: the minimum simply wins. The
/// arrowhead clamp at `:690` depends on that, because a connector shorter than
/// ten pixels drives its distance bound under `MIN_ARROW_SIZE`.
double _clamp(double value, double min, double max) =>
    math.max(min, math.min(max, value));

/// The lengths of an SVG `stroke-dasharray`, or null for a solid line.
///
/// `ChartAnnotationLayer.tsx:780` hands the author's string straight to the
/// attribute; a [Canvas] has no dash support, so the string is parsed here into
/// the on/off run lengths [FluentChartAnnotationConnectorPainter] walks. SVG
/// separates the lengths by commas and/or whitespace and ignores an
/// unparseable list, drawing a solid line — the null below.
List<double>? _parseDashArray(String? dashArray) {
  if (dashArray == null) {
    return null;
  }
  final lengths = <double>[];
  for (final token in dashArray.split(RegExp('[,\\s]+'))) {
    if (token.isEmpty) {
      continue;
    }
    final length = double.tryParse(token);
    if (length == null || length < 0) {
      return null;
    }
    lengths.add(length);
  }
  return lengths.isEmpty ? null : lengths;
}

/// A resolved connector line and its arrowheads.
@immutable
class FluentChartAnnotationConnectorGeometry {
  /// Creates a resolved connector.
  const FluentChartAnnotationConnectorGeometry({
    required this.start,
    required this.end,
    required this.strokeColor,
    required this.strokeWidth,
    required this.dashArray,
    required this.arrow,
    required this.markerSize,
    required this.markerStrokeWidth,
  });

  /// Where the line leaves the annotation box.
  final Offset start;

  /// Where the line meets the datum.
  final Offset end;

  /// Line colour.
  final Color strokeColor;

  /// Line width.
  final double strokeWidth;

  /// Dash pattern, or null for a solid line.
  final List<double>? dashArray;

  /// Which ends carry an arrowhead.
  final FluentChartAnnotationArrowHead arrow;

  /// Arrowhead edge length.
  final double markerSize;

  /// Arrowhead outline width.
  final double markerStrokeWidth;

  @override
  bool operator ==(Object other) =>
      other is FluentChartAnnotationConnectorGeometry &&
      other.start == start &&
      other.end == end &&
      other.strokeColor == strokeColor &&
      other.strokeWidth == strokeWidth &&
      listEquals(other.dashArray, dashArray) &&
      other.arrow == arrow &&
      other.markerSize == markerSize &&
      other.markerStrokeWidth == markerStrokeWidth;

  @override
  int get hashCode => Object.hash(
    start,
    end,
    strokeColor,
    strokeWidth,
    Object.hashAll(dashArray ?? const <double>[]),
    arrow,
    markerSize,
    markerStrokeWidth,
  );
}

/// Pass one of the connector geometry: push a box off its own anchor.
///
/// `ChartAnnotationLayer.tsx:561-594`, which runs **before** the connector is
/// emitted, so a box sitting on top of its datum is moved far enough away for
/// an arrowhead to fit.
///
/// Upstream reuses the alignment offsets and the clamped viewport it computed
/// for the first placement (`:579-592`), which is exactly what
/// [fluentLayoutAnnotationBox] recomputes from [layout] and [box]'s own size —
/// so the desired display point is simply re-laid out here.
FluentAnnotationBox fluentPushOffAnnotationBox(
  FluentAnnotationBox box,
  FluentChartAnnotationConnector connector, {
  required FluentChartAnnotationLayout? layout,
  required FluentChartAnnotationContext context,
}) {
  // ChartAnnotationLayer.tsx:564-565 — the 6 is a local literal, distinct from
  // MIN_ARROW_SIZE despite sharing its value.
  const minArrowClearance = 6.0;
  final minDistance = math.max(
    connector.startPadding + connector.endPadding + minArrowClearance,
    connector.startPadding,
  );

  // ChartAnnotationLayer.tsx:567-569 — measured from the anchor outwards.
  final delta = box.displayPoint - box.anchor;
  final distance = delta.distance;
  // :571.
  if (distance >= minDistance) {
    return box;
  }

  // ChartAnnotationLayer.tsx:572-574 — straight up when the two coincide.
  final unit = distance == 0
      ? const Offset(0, -1)
      : Offset(delta.dx / distance, delta.dy / distance);
  // :576-577.
  final desired = box.anchor + unit * minDistance;

  // :579-592 — the desired display point is re-aligned, re-clamped, and the
  // display point read back off the clamped box.
  return fluentLayoutAnnotationBox(
    resolved: FluentResolvedAnnotationPosition(
      anchor: box.anchor,
      point: desired,
    ),
    measured: box.rect.size,
    layout: layout,
    context: context,
  );
}

/// Pass two: the line itself. `ChartAnnotationLayer.tsx:670-714`.
FluentChartAnnotationConnectorGeometry fluentAnnotationConnector({
  required FluentAnnotationBox box,
  required FluentChartAnnotationConnector connector,
  required Color defaultStrokeColor,
}) {
  // ChartAnnotationLayer.tsx:680-684.
  final delta = box.anchor - box.displayPoint;
  // :682 — `|| 1` guards the unit vector.
  final distance = delta.distance == 0 ? 1.0 : delta.distance;
  final unit = Offset(delta.dx / distance, delta.dy / distance);

  // ChartAnnotationLayer.tsx:686-690.
  final sizeBasis = math.max(1.0, math.min(box.rect.width, box.rect.height));
  final proportional = sizeBasis * kArrowSizeScale;
  final maxByPadding = connector.startPadding > 0
      ? connector.startPadding * 1.25
      : kMaxArrowSize;
  final maxByDistance = distance * 0.6;
  final markerSize = _clamp(
    proportional,
    kMinArrowSize,
    math.min(kMaxArrowSize, math.min(maxByPadding, maxByDistance)),
  );

  return FluentChartAnnotationConnectorGeometry(
    // ChartAnnotationLayer.tsx:693-696.
    start: box.displayPoint + unit * connector.startPadding,
    // :698-701.
    end: box.anchor - unit * connector.endPadding,
    // :674 — `getDefaultConnectorStrokeColor()` is the theme-resolved default.
    strokeColor: connector.strokeColor ?? defaultStrokeColor,
    strokeWidth: connector.strokeWidth,
    dashArray: _parseDashArray(connector.dashArray),
    arrow: connector.arrow,
    markerSize: markerSize,
    // ChartAnnotationLayer.tsx:691.
    markerStrokeWidth: _clamp(connector.strokeWidth, 1, markerSize / 2),
  );
}

/// Draws every annotation connector line and arrowhead.
///
/// Replaces the SVG `<marker>` defs at `ChartAnnotationLayer.tsx:726-758`.
/// Those use `markerUnits="userSpaceOnUse"` with `orient="auto"`, `refY` at
/// half the size and `refX` at the size for an end marker and zero for a start
/// one — so in both cases the triangle's *tip* lands on the line's vertex and
/// the body extends back along the line. That is what the triangle below
/// reproduces.
class FluentChartAnnotationConnectorPainter extends CustomPainter {
  /// Creates a painter for [connectors].
  const FluentChartAnnotationConnectorPainter({required this.connectors});

  /// The resolved connectors, in annotation order.
  final List<FluentChartAnnotationConnectorGeometry> connectors;

  @override
  void paint(Canvas canvas, Size size) {
    for (final connector in connectors) {
      final paint = Paint()
        ..color = connector.strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = connector.strokeWidth
        // ChartAnnotationLayer.tsx:781 — `strokeLinecap="round"`.
        ..strokeCap = StrokeCap.round;

      final dash = connector.dashArray;
      if (dash == null || dash.isEmpty) {
        canvas.drawLine(connector.start, connector.end, paint);
      } else {
        _drawDashed(canvas, connector.start, connector.end, dash, paint);
      }

      final direction = connector.end - connector.start;
      final length = direction.distance == 0 ? 1.0 : direction.distance;
      final unit = Offset(direction.dx / length, direction.dy / length);

      // ChartAnnotationLayer.tsx:764-769.
      if (connector.arrow == FluentChartAnnotationArrowHead.end ||
          connector.arrow == FluentChartAnnotationArrowHead.both) {
        _drawArrow(canvas, connector, tip: connector.end, unit: unit);
      }
      if (connector.arrow == FluentChartAnnotationArrowHead.start ||
          connector.arrow == FluentChartAnnotationArrowHead.both) {
        _drawArrow(canvas, connector, tip: connector.start, unit: -unit);
      }
    }
  }

  void _drawArrow(
    Canvas canvas,
    FluentChartAnnotationConnectorGeometry connector, {
    required Offset tip,
    required Offset unit,
  }) {
    final size = connector.markerSize;
    // ChartAnnotationLayer.tsx:728-732 — the end marker's path is
    // `M0 0 L size size/2 L0 size Z` with refX = size and refY = size / 2, so
    // the tip is at the vertex and the base is one size back along the line,
    // half a size either side of it. The start marker (`:731`) is the same
    // triangle mirrored against refX = 0, which is this triangle with the unit
    // vector negated.
    final back = tip - unit * size;
    final normal = Offset(-unit.dy, unit.dx) * (size / 2);
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(back.dx + normal.dx, back.dy + normal.dy)
      ..lineTo(back.dx - normal.dx, back.dy - normal.dy)
      ..close();
    canvas
      ..drawPath(path, Paint()..color = connector.strokeColor)
      // ChartAnnotationLayer.tsx:746-752 — the marker is filled AND stroked,
      // with round caps and joins, which visibly rounds the tip.
      ..drawPath(
        path,
        Paint()
          ..color = connector.strokeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = connector.markerStrokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
  }

  void _drawDashed(
    Canvas canvas,
    Offset start,
    Offset end,
    List<double> pattern,
    Paint paint,
  ) {
    final total = (end - start).distance;
    if (total == 0) {
      return;
    }
    final unit = (end - start) / total;
    var travelled = 0.0;
    var index = 0;
    var drawing = true;
    while (travelled < total) {
      final step = math.min(pattern[index % pattern.length], total - travelled);
      if (drawing) {
        canvas.drawLine(
          start + unit * travelled,
          start + unit * (travelled + step),
          paint,
        );
      }
      // A zero-length run would otherwise spin here; SVG treats an all-zero
      // dasharray as a solid line, and a single zero as a gapless one.
      if (step == 0) {
        canvas.drawLine(start + unit * travelled, end, paint);
        return;
      }
      travelled += step;
      index++;
      drawing = !drawing;
    }
  }

  @override
  bool shouldRepaint(FluentChartAnnotationConnectorPainter oldDelegate) =>
      !listEquals(oldDelegate.connectors, connectors);
}
