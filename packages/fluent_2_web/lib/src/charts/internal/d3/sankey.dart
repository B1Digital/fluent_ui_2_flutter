import 'dart:math' as math;

import 'array_stats.dart' as array;
import 'stable_sort.dart';

/// A node in a Sankey layout. Mutable, because the layout writes to it in
/// place, exactly as `d3-sankey` does.
class SankeyLayoutNode {
  /// Creates a node. [id] is whatever the caller keys links by; [fixedValue]
  /// overrides the computed throughput (`d3-sankey/src/sankey.js:151`).
  SankeyLayoutNode({this.id, this.fixedValue});

  /// The caller's identifier.
  final Object? id;

  /// An explicit throughput, or `null` to compute one.
  final double? fixedValue;

  /// The left edge.
  double x0 = 0;

  /// The right edge.
  double x1 = 0;

  /// The top edge.
  double y0 = 0;

  /// The bottom edge.
  double y1 = 0;

  /// The throughput.
  double value = 0;

  /// The node's position in the input list.
  int index = 0;

  /// The longest path from a source.
  int depth = 0;

  /// The longest path to a sink.
  int height = 0;

  /// The column this node was assigned to. `SankeyChart.tsx:167` reads it.
  int layer = 0;

  /// Links leaving this node.
  final List<SankeyLayoutLink> sourceLinks = <SankeyLayoutLink>[];

  /// Links arriving at this node.
  final List<SankeyLayoutLink> targetLinks = <SankeyLayoutLink>[];
}

/// A link in a Sankey layout. Mutable for the same reason as
/// [SankeyLayoutNode].
class SankeyLayoutLink {
  /// Creates a link.
  SankeyLayoutLink({
    required this.source,
    required this.target,
    required this.value,
  });

  /// The originating node.
  SankeyLayoutNode source;

  /// The destination node.
  SankeyLayoutNode target;

  /// The flow.
  double value;

  /// The ribbon's thickness.
  double width = 0;

  /// The centre of the ribbon at the source.
  double y0 = 0;

  /// The centre of the ribbon at the target.
  double y1 = 0;

  /// The link's position in the input list.
  int index = 0;
}

/// The result of a layout.
class SankeyGraph {
  /// Creates a graph.
  const SankeyGraph(this.nodes, this.links);

  /// The laid-out nodes, in input order.
  final List<SankeyLayoutNode> nodes;

  /// The laid-out links, in input order.
  final List<SankeyLayoutLink> links;
}

/// `d3-sankey/src/align.js:15-17` — sources sit at their depth, sinks at the
/// last column. `SankeyChart.tsx:339` uses this for LTR.
int sankeyJustify(SankeyLayoutNode node, int n) =>
    node.sourceLinks.isNotEmpty ? node.depth : n - 1;

/// `d3-sankey/src/align.js:11-13`. `SankeyChart.tsx:339` uses this for RTL.
int sankeyRight(SankeyLayoutNode node, int n) => n - 1 - node.height;

/// The Sankey layout (`d3-sankey/src/sankey.js:54-369`).
///
/// The upstream `nodeSort`, `linkSort`, `nodeId` and `size` accessors are not
/// ported: `SankeyChart.tsx:337-341` uses none of them, and every `sort`
/// branch upstream guards is therefore the `undefined` one.
class Sankey {
  /// Creates a layout with d3's defaults.
  Sankey();

  // The extent, `sankey.js:55` (`x0 = y0 = 0, x1 = y1 = 1`).
  double _x0 = 0;
  double _y0 = 0;
  double _x1 = 1;
  double _y1 = 1;

  // nodeWidth, `sankey.js:56`.
  double _dx = 24;

  // nodePadding and the padding in force, `sankey.js:57`. Upstream leaves `py`
  // undefined until either `nodePadding` or a layout sets it; 8 is what the
  // first layout would compute for it anyway on any extent that tall.
  double _dy = 8;
  double _py = 8;

  // The relaxation iteration count, `sankey.js:64`.
  int _iterations = 6;

  int Function(SankeyLayoutNode node, int n) _align = sankeyJustify;

  /// The node width (`d3-sankey/src/sankey.js:56`, default 24).
  /// `SankeyChart.tsx:337` sets 124.
  double get nodeWidthValue => _dx;

  /// The requested node padding (`d3-sankey/src/sankey.js:57`, default 8).
  double get nodePaddingValue => _dy;

  /// The relaxation iteration count (`d3-sankey/src/sankey.js:64`, default 6).
  int get iterationsValue => _iterations;

  /// The padding actually in force after the last layout
  /// (`d3-sankey/src/sankey.js:235`). `SankeyChart.tsx:260-272`'s
  /// `adjustPadding` reads it back.
  double get currentNodePadding => _py;

  /// Sets the node width.
  Sankey nodeWidth(double dx) {
    _dx = dx;
    return this;
  }

  /// Sets the node padding.
  Sankey nodePadding(double dy) {
    _dy = _py = dy;
    return this;
  }

  /// Sets the layout rectangle (`d3-sankey/src/sankey.js:118-120`).
  Sankey extentOf(double x0, double y0, double x1, double y1) {
    _x0 = x0;
    _y0 = y0;
    _x1 = x1;
    _y1 = y1;
    return this;
  }

  /// Sets the relaxation iteration count.
  Sankey iterations(int n) {
    _iterations = n;
    return this;
  }

  /// Sets the column-assignment function.
  Sankey nodeAlign(int Function(SankeyLayoutNode node, int n) align) {
    _align = align;
    return this;
  }

  /// Lays out [nodes] and [links] in place and returns them
  /// (`d3-sankey/src/sankey.js:66-75`).
  SankeyGraph call(List<SankeyLayoutNode> nodes, List<SankeyLayoutLink> links) {
    _computeNodeLinks(nodes, links);
    _computeNodeValues(nodes);
    _computeNodeDepths(nodes);
    _computeNodeHeights(nodes);
    _computeNodeBreadths(nodes);
    _computeLinkBreadths(nodes);
    return SankeyGraph(nodes, links);
  }

  /// `d3-sankey/src/sankey.js:126-147`.
  ///
  /// The `nodeById` lookup upstream resolves string endpoints; here the caller
  /// hands over node objects, so only the indexing and the back-links remain.
  void _computeNodeLinks(
    List<SankeyLayoutNode> nodes,
    List<SankeyLayoutLink> links,
  ) {
    for (var i = 0; i < nodes.length; i++) {
      nodes[i].index = i;
      nodes[i].sourceLinks.clear();
      nodes[i].targetLinks.clear();
    }
    for (var i = 0; i < links.length; i++) {
      final link = links[i]..index = i;
      link.source.sourceLinks.add(link);
      link.target.targetLinks.add(link);
    }
  }

  /// `d3-sankey/src/sankey.js:149-155`.
  void _computeNodeValues(List<SankeyLayoutNode> nodes) {
    for (final node in nodes) {
      node.value =
          node.fixedValue ??
          math.max(
            array.sum(
              node.sourceLinks,
              accessor: (Object? d, int _) => (d! as SankeyLayoutLink).value,
            ),
            array.sum(
              node.targetLinks,
              accessor: (Object? d, int _) => (d! as SankeyLayoutLink).value,
            ),
          );
    }
  }

  /// `d3-sankey/src/sankey.js:157-173`.
  void _computeNodeDepths(List<SankeyLayoutNode> nodes) {
    final n = nodes.length;
    var current = <SankeyLayoutNode>{...nodes};
    var next = <SankeyLayoutNode>{};
    var x = 0;
    while (current.isNotEmpty) {
      for (final node in current) {
        node.depth = x;
        for (final link in node.sourceLinks) {
          next.add(link.target);
        }
      }
      if (++x > n) {
        throw StateError('circular link');
      }
      current = next;
      next = <SankeyLayoutNode>{};
    }
  }

  /// `d3-sankey/src/sankey.js:175-191`.
  void _computeNodeHeights(List<SankeyLayoutNode> nodes) {
    final n = nodes.length;
    var current = <SankeyLayoutNode>{...nodes};
    var next = <SankeyLayoutNode>{};
    var x = 0;
    while (current.isNotEmpty) {
      for (final node in current) {
        node.height = x;
        for (final link in node.targetLinks) {
          next.add(link.source);
        }
      }
      if (++x > n) {
        throw StateError('circular link');
      }
      current = next;
      next = <SankeyLayoutNode>{};
    }
  }

  /// `d3-sankey/src/sankey.js:193-209`.
  List<List<SankeyLayoutNode>> _computeNodeLayers(
    List<SankeyLayoutNode> nodes,
  ) {
    // + 1, `sankey.js:194`: depths are zero-based, so the column count is one
    // more than the deepest.
    final x =
        array
            .max<num>(
              nodes,
              accessor: (Object? d, int _) => (d! as SankeyLayoutNode).depth,
            )!
            .toInt() +
        1;
    final kx = (_x1 - _x0 - _dx) / (x - 1);
    final columns = List<List<SankeyLayoutNode>>.generate(
      x,
      (int _) => <SankeyLayoutNode>[],
      growable: false,
    );
    for (final node in nodes) {
      // 0 and x - 1, `sankey.js:197`: an alignment may report a column outside
      // the range, and it is clamped rather than rejected.
      final i = math.max(0, math.min(x - 1, _align(node, x)));
      node
        ..layer = i
        ..x0 = _x0 + i * kx
        ..x1 = _x0 + i * kx + _dx;
      columns[i].add(node);
    }
    return columns;
  }

  /// `d3-sankey/src/sankey.js:211-231`.
  void _initializeNodeBreadths(List<List<SankeyLayoutNode>> columns) {
    final ky = array
        .min<num>(
          columns,
          accessor: (Object? c, int _) {
            final column = c! as List<SankeyLayoutNode>;
            // - 1 gaps between n nodes, `sankey.js:212`.
            return (_y1 - _y0 - (column.length - 1) * _py) /
                array.sum(
                  column,
                  accessor: (Object? d, int _) =>
                      (d! as SankeyLayoutNode).value,
                );
          },
        )!
        .toDouble();
    for (final nodes in columns) {
      var y = _y0;
      for (final node in nodes) {
        node
          ..y0 = y
          ..y1 = y + node.value * ky;
        y = node.y1 + _py;
        for (final link in node.sourceLinks) {
          link.width = link.value * ky;
        }
      }
      // + 1, `sankey.js:222`: the slack is shared out over the gaps above,
      // between and below the column's nodes.
      y = (_y1 - y + _py) / (nodes.length + 1);
      for (var i = 0; i < nodes.length; i++) {
        // + 1, `sankey.js:225-226`: the node at index 0 gets one share.
        nodes[i]
          ..y0 += y * (i + 1)
          ..y1 += y * (i + 1);
      }
      _reorderLinks(nodes);
    }
  }

  /// `d3-sankey/src/sankey.js:233-243`.
  void _computeNodeBreadths(List<SankeyLayoutNode> nodes) {
    final columns = _computeNodeLayers(nodes);
    // - 1, `sankey.js:235`: as in [_initializeNodeBreadths], n nodes leave
    // n - 1 gaps to spend the extent on.
    _py = math.min(
      _dy,
      (_y1 - _y0) /
          (array
                  .max<num>(
                    columns,
                    accessor: (Object? c, int _) =>
                        (c! as List<SankeyLayoutNode>).length,
                  )!
                  .toDouble() -
              1),
    );
    _initializeNodeBreadths(columns);
    for (var i = 0; i < _iterations; i++) {
      // 0.99 and the beta schedule, `sankey.js:238-239`: the relaxation step
      // decays while the collision resolution firms up.
      //
      // `math.pow(0.99, 3)` is one ulp below V8's `Math.pow(0.99, 3)`
      // (`0x3FEF0BDC0871F059` against `…5A`; V8 is correctly rounded at every
      // exponent up to 40, Dart's libm call is not). Alpha scales every
      // relaxation step, but the collision passes clamp the columns back onto
      // the extent and all six golden vectors — including the 32-iteration one
      // — match exactly either way. Should a sub-ulp sankey mismatch ever turn
      // up, this is the line to suspect: a correctly-rounded 0.99^i in
      // double-double arithmetic removes it.
      final alpha = math.pow(0.99, i).toDouble();
      final beta = math.max(1 - alpha, (i + 1) / _iterations);
      _relaxRightToLeft(columns, alpha, beta);
      _relaxLeftToRight(columns, alpha, beta);
    }
  }

  /// `d3-sankey/src/sankey.js:13-15`.
  ///
  /// The JS comparator returns a double; V8's sort treats a NaN result as
  /// "equal", which is what the `0` fallback reproduces.
  static int _ascendingBreadth(SankeyLayoutNode a, SankeyLayoutNode b) {
    final d = a.y0 - b.y0;
    if (d < 0) {
      return -1;
    }
    if (d > 0) {
      return 1;
    }
    return 0;
  }

  /// `d3-sankey/src/sankey.js:5-7`.
  static int _ascendingSourceBreadth(SankeyLayoutLink a, SankeyLayoutLink b) {
    final byNode = _ascendingBreadth(a.source, b.source);
    return byNode != 0 ? byNode : a.index - b.index;
  }

  /// `d3-sankey/src/sankey.js:9-11`.
  static int _ascendingTargetBreadth(SankeyLayoutLink a, SankeyLayoutLink b) {
    final byNode = _ascendingBreadth(a.target, b.target);
    return byNode != 0 ? byNode : a.index - b.index;
  }

  /// Writes [sorted] back over [target].
  ///
  /// [stableSort] returns a new list where d3 sorts in place, and every other
  /// reference — a node's link lists, a column of [_computeNodeLayers] — has to
  /// see the new order.
  static void _replaceAll<T>(List<T> target, List<T> sorted) {
    target
      ..clear()
      ..addAll(sorted);
  }

  /// `d3-sankey/src/sankey.js:246-266`.
  void _relaxLeftToRight(
    List<List<SankeyLayoutNode>> columns,
    double alpha,
    double beta,
  ) {
    // From 1, `sankey.js:247`: the first column has no incoming links.
    for (var i = 1; i < columns.length; i++) {
      final column = columns[i];
      for (final target in column) {
        var y = 0.0;
        var w = 0.0;
        for (final link in target.targetLinks) {
          final v = link.value * (target.layer - link.source.layer);
          y += _targetTop(link.source, target) * v;
          w += v;
        }
        // Negated, `sankey.js:257`: a NaN weight must fall through too.
        if (!(w > 0)) {
          continue;
        }
        final dy = (y / w - target.y0) * alpha;
        target
          ..y0 += dy
          ..y1 += dy;
        _reorderNodeLinks(target);
      }
      _replaceAll(column, stableSort(column, _ascendingBreadth));
      _resolveCollisions(column, beta);
    }
  }

  /// `d3-sankey/src/sankey.js:269-289`.
  void _relaxRightToLeft(
    List<List<SankeyLayoutNode>> columns,
    double alpha,
    double beta,
  ) {
    // - 2, `sankey.js:270`: the last column has no outgoing links.
    for (var i = columns.length - 2; i >= 0; i--) {
      final column = columns[i];
      for (final source in column) {
        var y = 0.0;
        var w = 0.0;
        for (final link in source.sourceLinks) {
          final v = link.value * (link.target.layer - source.layer);
          y += _sourceTop(source, link.target) * v;
          w += v;
        }
        // As in [_relaxLeftToRight] (`sankey.js:280`).
        if (!(w > 0)) {
          continue;
        }
        final dy = (y / w - source.y0) * alpha;
        source
          ..y0 += dy
          ..y1 += dy;
        _reorderNodeLinks(source);
      }
      _replaceAll(column, stableSort(column, _ascendingBreadth));
      _resolveCollisions(column, beta);
    }
  }

  /// `d3-sankey/src/sankey.js:291-298`.
  void _resolveCollisions(List<SankeyLayoutNode> nodes, double alpha) {
    // >> 1, `sankey.js:292`: the median node holds still and the rest are
    // pushed away from it.
    final i = nodes.length >> 1;
    final subject = nodes[i];
    _bottomToTop(nodes, subject.y0 - _py, i - 1, alpha);
    _topToBottom(nodes, subject.y1 + _py, i + 1, alpha);
    _bottomToTop(nodes, _y1, nodes.length - 1, alpha);
    _topToBottom(nodes, _y0, 0, alpha);
  }

  /// `d3-sankey/src/sankey.js:301-308`.
  void _topToBottom(
    List<SankeyLayoutNode> nodes,
    double startY,
    int startIndex,
    double alpha,
  ) {
    var y = startY;
    for (var i = startIndex; i < nodes.length; i++) {
      final node = nodes[i];
      final dy = (y - node.y0) * alpha;
      // 1e-6, sankey.js:305 — anything smaller is left alone.
      if (dy > 1e-6) {
        node
          ..y0 += dy
          ..y1 += dy;
      }
      y = node.y1 + _py;
    }
  }

  /// `d3-sankey/src/sankey.js:311-318`.
  void _bottomToTop(
    List<SankeyLayoutNode> nodes,
    double startY,
    int startIndex,
    double alpha,
  ) {
    var y = startY;
    for (var i = startIndex; i >= 0; i--) {
      final node = nodes[i];
      final dy = (node.y1 - y) * alpha;
      // As in [_topToBottom] (`sankey.js:315`).
      if (dy > 1e-6) {
        node
          ..y0 -= dy
          ..y1 -= dy;
      }
      y = node.y0 - _py;
    }
  }

  /// `d3-sankey/src/sankey.js:320-329`.
  void _reorderNodeLinks(SankeyLayoutNode node) {
    for (final link in node.targetLinks) {
      _replaceAll(
        link.source.sourceLinks,
        stableSort(link.source.sourceLinks, _ascendingTargetBreadth),
      );
    }
    for (final link in node.sourceLinks) {
      _replaceAll(
        link.target.targetLinks,
        stableSort(link.target.targetLinks, _ascendingSourceBreadth),
      );
    }
  }

  /// `d3-sankey/src/sankey.js:331-338`.
  void _reorderLinks(List<SankeyLayoutNode> nodes) {
    for (final node in nodes) {
      _replaceAll(
        node.sourceLinks,
        stableSort(node.sourceLinks, _ascendingTargetBreadth),
      );
      _replaceAll(
        node.targetLinks,
        stableSort(node.targetLinks, _ascendingSourceBreadth),
      );
    }
  }

  /// `d3-sankey/src/sankey.js:341-352`.
  double _targetTop(SankeyLayoutNode source, SankeyLayoutNode target) {
    // / 2, `sankey.js:342`: the ribbons are centred on the node.
    var y = source.y0 - (source.sourceLinks.length - 1) * _py / 2;
    for (final link in source.sourceLinks) {
      if (identical(link.target, target)) {
        break;
      }
      y += link.width + _py;
    }
    for (final link in target.targetLinks) {
      if (identical(link.source, source)) {
        break;
      }
      y -= link.width;
    }
    return y;
  }

  /// `d3-sankey/src/sankey.js:355-366`.
  double _sourceTop(SankeyLayoutNode source, SankeyLayoutNode target) {
    // As in [_targetTop] (`sankey.js:356`).
    var y = target.y0 - (target.targetLinks.length - 1) * _py / 2;
    for (final link in target.targetLinks) {
      if (identical(link.source, source)) {
        break;
      }
      y += link.width + _py;
    }
    for (final link in source.sourceLinks) {
      if (identical(link.target, target)) {
        break;
      }
      y -= link.width;
    }
    return y;
  }

  /// `d3-sankey/src/sankey.js:39-52`.
  void _computeLinkBreadths(List<SankeyLayoutNode> nodes) {
    for (final node in nodes) {
      var y0 = node.y0;
      var y1 = node.y0;
      for (final link in node.sourceLinks) {
        // / 2, `sankey.js:44`: the endpoint is the ribbon's centre line.
        link.y0 = y0 + link.width / 2;
        y0 += link.width;
      }
      for (final link in node.targetLinks) {
        // As above (`sankey.js:48`).
        link.y1 = y1 + link.width / 2;
        y1 += link.width;
      }
    }
  }
}
