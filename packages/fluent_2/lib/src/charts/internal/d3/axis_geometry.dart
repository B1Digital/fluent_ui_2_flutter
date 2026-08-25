import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'scale.dart';

/// Which edge an axis sits on (`d3-axis/src/axis.js:3-6`).
enum FluentAxisOrientation {
  /// Above the plot.
  top,

  /// To the right of the plot.
  right,

  /// Below the plot.
  bottom,

  /// To the left of the plot.
  left,
}

/// SVG `text-anchor`, re-expressed (`d3-axis/src/axis.js:111`).
enum FluentAxisTextAnchor {
  /// Left-aligned in LTR.
  start,

  /// Centred.
  middle,

  /// Right-aligned in LTR.
  end,
}

/// One tick's resolved geometry.
///
/// Only [final] fields and a `const` constructor, so instances are values. The
/// `@immutable` annotation that would document this lives in `package:meta` and
/// `package:flutter/foundation.dart`, and `internal/d3/` imports neither.
class FluentAxisTickGeometry {
  /// Creates a tick geometry.
  const FluentAxisTickGeometry({
    required this.value,
    required this.position,
    required this.lineStart,
    required this.lineEnd,
    required this.labelAnchor,
    required this.label,
    required this.textAlign,
    required this.baselineDyEm,
  });

  /// The domain value.
  final Object value;

  /// The tick's position along the axis, already carrying the crispness
  /// offset (`d3-axis/src/axis.js:98`).
  final double position;

  /// One end of the tick mark, on the axis line itself.
  final Offset lineStart;

  /// The other end, [FluentAxisGeometry.tickSizeInner] away from the axis in
  /// the [FluentAxisGeometry.k] direction (`d3-axis/src/axis.js:67`).
  final Offset lineEnd;

  /// Where the label's anchor sits, [FluentAxisGeometry.spacing] away from the
  /// axis in the [FluentAxisGeometry.k] direction (`d3-axis/src/axis.js:71`).
  final Offset labelAnchor;

  /// The label text.
  final String label;

  /// How the label aligns about [labelAnchor].
  final FluentAxisTextAnchor textAlign;

  /// The SVG `dy` in em (`d3-axis/src/axis.js:72`): 0.71 below, 0.32 at the
  /// sides, 0 above. Multiply by the font size to reach a pixel offset.
  final double baselineDyEm;
}

/// A pure re-derivation of the numbers `d3-axis` computes. **Not** a painter —
/// `axis/axis_painter.dart` consumes this.
///
/// Only [final] fields and a `const` constructor; see the note on
/// [FluentAxisTickGeometry] for why `@immutable` is absent.
class FluentAxisGeometry {
  /// Creates an axis geometry.
  ///
  /// [offset] is **required and has no default**: it is
  /// `devicePixelRatio > 1 ? 0.0 : 0.5` (`d3-axis/src/axis.js:38`), and design
  /// spec §5.5 forbids a call site silently picking one.
  const FluentAxisGeometry({
    required this.orientation,
    required this.scale,
    required this.tickValues,
    required this.tickLabels,
    required this.offset,
    // 6, 6 and 3 are d3's own defaults, at `d3-axis/src/axis.js:35-37`.
    this.tickSizeInner = 6,
    this.tickSizeOuter = 6,
    this.tickPadding = 3,
  });

  /// The edge this axis sits on.
  final FluentAxisOrientation orientation;

  /// The scale being drawn.
  final Scale scale;

  /// The domain values to draw ticks at.
  final List<Object> tickValues;

  /// The already-formatted labels, parallel to [tickValues].
  ///
  /// A value with no label at the same index takes the empty string rather
  /// than throwing: this getter runs inside `paint`.
  final List<String> tickLabels;

  /// The half-pixel crispness offset.
  final double offset;

  /// The inward tick length (`d3-axis/src/axis.js:35`).
  final double tickSizeInner;

  /// The outward tick length at the domain ends (`d3-axis/src/axis.js:36`).
  final double tickSizeOuter;

  /// The gap between a tick and its label (`d3-axis/src/axis.js:37`).
  final double tickPadding;

  /// `max(tickSizeInner, 0) + tickPadding` (`d3-axis/src/axis.js:46`).
  ///
  /// The floor at zero matters: a negative [tickSizeInner] draws the mark
  /// outward, and upstream still leaves the label [tickPadding] clear of the
  /// axis rather than pulling it back across.
  // 0.0, not 0: `math.max` would otherwise infer `num` and fail `strict-casts`.
  double get spacing => math.max(tickSizeInner, 0.0) + tickPadding;

  /// `-1` above and to the left, `+1` below and to the right
  /// (`d3-axis/src/axis.js:39`).
  int get k =>
      orientation == FluentAxisOrientation.top ||
          orientation == FluentAxisOrientation.left
      ? -1
      : 1;

  /// Whether the axis runs left to right, so that a tick's position is an `x`.
  ///
  /// `d3-axis/src/axis.js:41` picks `translateX` for exactly these two.
  bool get _horizontal =>
      orientation == FluentAxisOrientation.top ||
      orientation == FluentAxisOrientation.bottom;

  /// Where a tick for [value] sits, before the crispness offset is added.
  ///
  /// For a band scale this is `scale(v) + max(0, bandwidth - 2 * offset) / 2`
  /// (`d3-axis/src/axis.js:21-25`) — **not** `scale(v) + bandwidth / 2`, which
  /// it equals only when [offset] is zero.
  ///
  /// Returns NaN when [scale] returns null, because upstream coerces with
  /// `+scale(d)` (`axis.js:18` and `:24`) and JavaScript turns `undefined` into
  /// NaN. `axis.js:82` then filters on `isFinite`, so a band-domain miss must
  /// stay a number rather than becoming an exception.
  ///
  /// `axis.js:23` additionally rounds the centring offset when the band scale
  /// has `round()` enabled. [Scale] exposes no `round`, and both upstream
  /// cartesian call sites leave it off, so that branch is omitted.
  // ponytail: no round() branch; add it if a call site ever needs a rounded
  // band scale.
  double positionOf(Object value) {
    final base = scale(value) ?? double.nan;
    if (scale.bandwidth == 0) {
      return base;
    }
    // 2 because the offset is taken off both edges of the band.
    return base + math.max(0.0, scale.bandwidth - offset * 2) / 2;
  }

  /// Every tick's geometry (`d3-axis/src/axis.js:96-105`).
  List<FluentAxisTickGeometry> get ticks {
    final result = <FluentAxisTickGeometry>[];
    for (var i = 0; i < tickValues.length; i++) {
      final value = tickValues[i];
      // axis.js:98 — the offset is added ONCE here. Not halved.
      final position = positionOf(value) + offset;
      final mark = k * tickSizeInner;
      final anchor = k * spacing;
      result.add(
        FluentAxisTickGeometry(
          value: value,
          position: position,
          lineStart: _horizontal ? Offset(position, 0) : Offset(0, position),
          lineEnd: _horizontal
              ? Offset(position, mark)
              : Offset(mark, position),
          labelAnchor: _horizontal
              ? Offset(position, anchor)
              : Offset(anchor, position),
          label: i < tickLabels.length ? tickLabels[i] : '',
          textAlign: switch (orientation) {
            // axis.js:111.
            FluentAxisOrientation.right => FluentAxisTextAnchor.start,
            FluentAxisOrientation.left => FluentAxisTextAnchor.end,
            _ => FluentAxisTextAnchor.middle,
          },
          baselineDyEm: switch (orientation) {
            // axis.js:72 — "0em", "0.71em" and "0.32em".
            FluentAxisOrientation.top => 0.0,
            FluentAxisOrientation.bottom => 0.71,
            _ => 0.32,
          },
        ),
      );
    }
    return result;
  }

  /// The four points of the domain path (`d3-axis/src/axis.js:92-94`).
  ///
  /// Upstream hides this with CSS, so nothing paints it; it is kept because it
  /// is the cheapest single assertion against an Oracle B capture — the
  /// AreaChart basic story renders `M64.5,6V0.5H680.5V6`.
  List<Offset> get domainPath {
    final r = scale.range;
    // axis.js:48-49 — the offset lands on both ends of the range, not the span.
    final range0 = r.first + offset;
    final range1 = r.last + offset;
    final outer = k * tickSizeOuter;
    if (_horizontal) {
      // axis.js:94 — M range0,k*outer V offset H range1 V k*outer.
      return <Offset>[
        Offset(range0, outer),
        Offset(range0, offset),
        Offset(range1, offset),
        Offset(range1, outer),
      ];
    }
    // axis.js:93 — M k*outer,range0 H offset V range1 H k*outer.
    return <Offset>[
      Offset(outer, range0),
      Offset(offset, range0),
      Offset(offset, range1),
      Offset(outer, range1),
    ];
  }
}
