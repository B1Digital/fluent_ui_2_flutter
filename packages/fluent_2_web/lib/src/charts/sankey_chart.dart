import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'chrome/chart_title.dart';
import 'internal/chart_text_measurer.dart';
import 'internal/d3/axis_geometry.dart';
import 'internal/d3/curves.dart';
import 'internal/d3/path_sink.dart';
import 'internal/d3/sankey.dart';
import 'internal/d3/shape_line_area.dart';
import 'internal/d3/stable_sort.dart' as d3;
import 'sankey_chart_layout.dart';
import 'sankey_chart_style.dart';

/// Which nodes and streams the pointer has lit up, and how they repaint.
///
/// Ports the four selection state variables (`SankeyChart.tsx:573-577`), the two
/// breadth-first walks (`:65-158`) and the seven resolver functions (`:520-531`,
/// `:933-991`) as one immutable value.
///
/// Sankey selection is node- and stream-scoped, not the legend-highlight model the
/// cartesian charts use: there is no series to highlight, so nothing here goes
/// through `isLegendHighlightedMulti`.
@immutable
class FluentSankeySelection {
  /// Creates a selection.
  const FluentSankeySelection({
    this.active = false,
    this.nodeIndices = const <int>{},
    this.linkIndices = const <int>{},
    this.selectedNode,
  });

  /// The selection produced by hovering [node] (`SankeyChart.tsx:874-889`).
  factory FluentSankeySelection.forNode(SankeyLayoutNode node) {
    final links = <SankeyLayoutLink>{};
    final queue = Queue<SankeyLayoutLink>();
    // `:82-96` — forward through every downstream link.
    for (final link in node.sourceLinks) {
      queue.add(link);
      links.add(link);
    }
    while (queue.isNotEmpty) {
      for (final link in queue.removeFirst().target.sourceLinks) {
        links.add(link);
        queue.add(link);
      }
    }
    // `:98-114` — then backward through every upstream link.
    for (final link in node.targetLinks) {
      queue.add(link);
      links.add(link);
    }
    while (queue.isNotEmpty) {
      for (final link in queue.removeFirst().source.targetLinks) {
        links.add(link);
        queue.add(link);
      }
    }
    final nodes = <int>{
      for (final link in links) ...<int>[link.target.index, link.source.index],
      // `:879` — the hovered node joins the set even with no links.
      node.index,
    };
    return FluentSankeySelection(
      active: true,
      nodeIndices: nodes,
      linkIndices: <int>{for (final link in links) link.index},
      selectedNode: node.index,
    );
  }

  /// The selection produced by hovering [link] (`SankeyChart.tsx:119-158`).
  ///
  /// Note that [selectedNode] deliberately stays null: that is what switches the
  /// stream border onto the gradient and drops the path's fill to
  /// [kSankeySelectedStreamOpacity].
  factory FluentSankeySelection.forLink(SankeyLayoutLink link) {
    final links = <SankeyLayoutLink>{link};
    final nodes = <SankeyLayoutNode>{};
    final queue = Queue<SankeyLayoutNode>()..add(link.source);
    while (queue.isNotEmpty) {
      final node = queue.removeFirst();
      nodes.add(node);
      for (final upstream in node.targetLinks) {
        queue.add(upstream.source);
        links.add(upstream);
      }
    }
    queue.add(link.target);
    while (queue.isNotEmpty) {
      final node = queue.removeFirst();
      nodes.add(node);
      for (final downstream in node.sourceLinks) {
        queue.add(downstream.target);
        links.add(downstream);
      }
    }
    return FluentSankeySelection(
      active: true,
      nodeIndices: <int>{for (final node in nodes) node.index},
      linkIndices: <int>{for (final selected in links) selected.index},
    );
  }

  /// Nothing selected — the idle state.
  static const FluentSankeySelection none = FluentSankeySelection();

  /// Whether anything is selected at all (`selectedState`).
  final bool active;

  /// Indices of the nodes in the selected sub-graph.
  final Set<int> nodeIndices;

  /// Indices of the links in the selected sub-graph.
  final Set<int> linkIndices;

  /// Index of the hovered node, or null when a stream was hovered instead.
  final int? selectedNode;

  /// `_fillNodeColors` (`SankeyChart.tsx:933-944`).
  Color nodeFill(int index, FluentSankeyLayoutResult layout) {
    if (!active) {
      return layout.nodeColors[index];
    }
    if (selectedNode != null && nodeIndices.contains(index)) {
      return layout.nodeColors[selectedNode!];
    }
    if (selectedNode == null) {
      return layout.nodeColors[index];
    }
    return kSankeyNonSelectedColor;
  }

  /// `_fillNodeBorder` (`SankeyChart.tsx:963-972`).
  ///
  /// Every arm but one returns the node's own border, which is why an excluded node
  /// keeps its coloured outline over a grey fill.
  Color nodeBorder(int index, FluentSankeyLayoutResult layout) {
    if (active && nodeIndices.contains(index) && selectedNode != null) {
      return layout.nodeBorderColors[selectedNode!];
    }
    return layout.nodeBorderColors[index];
  }

  /// `_fillStreamColors` (`SankeyChart.tsx:946-950`).
  ///
  /// Returns null in every state the shipped stories reach, which is what makes the
  /// stream inherit `colorNeutralBackground1` from its group.
  Color? linkFill(int index, FluentSankeyLayoutResult layout) {
    if (active && linkIndices.contains(index)) {
      return layout.data.links[index].color;
    }
    return null;
  }

  /// `_fillStreamBorder` (`SankeyChart.tsx:952-961`), flat-colour arm.
  Color linkBorder(int index, FluentSankeyLayoutResult layout) {
    if (active && linkIndices.contains(index) && selectedNode != null) {
      return layout.nodeBorderColors[selectedNode!];
    }
    return kSankeyNonSelectedColor;
  }

  /// Whether the stream border paints the per-link gradient instead of a flat colour
  /// (`SankeyChart.tsx:957`).
  bool linkUsesGradient(int index) =>
      active && linkIndices.contains(index) && selectedNode == null;

  /// `_getOpacityStream` (`SankeyChart.tsx:974-983`).
  double linkFillOpacity(int index) {
    if (active && linkIndices.contains(index) && selectedNode == null) {
      return kSankeySelectedStreamOpacity;
    }
    // `:982` — REST_STREAM_OPACITY, fully opaque.
    return 1;
  }

  /// `_getOpacityStreamBorder` (`SankeyChart.tsx:985-991`).
  double linkBorderOpacity(int index) =>
      active && !linkIndices.contains(index) && selectedNode == null
      ? kSankeyNonSelectedStreamBorderOpacity
      // `:990` — NON_SELECTED_OPACITY, which is 1.
      : 1;

  /// `nodeTextColor` (`SankeyChart.tsx:520-531`).
  ///
  /// The upstream expression is a triple negation; expanded, only a node that is
  /// excluded from an active node-hover selection gets the dark colour.
  Color nodeTextColor(int index) {
    final light =
        !active ||
        (nodeIndices.contains(index) && selectedNode != null) ||
        selectedNode == null;
    return light ? kSankeyNonSelectedTextColor : kSankeyDefaultTextColor;
  }

  @override
  bool operator ==(Object other) =>
      other is FluentSankeySelection &&
      other.active == active &&
      other.selectedNode == selectedNode &&
      setEquals(other.nodeIndices, nodeIndices) &&
      setEquals(other.linkIndices, linkIndices);

  @override
  int get hashCode => Object.hash(
    active,
    selectedNode,
    Object.hashAllUnordered(nodeIndices),
    Object.hashAllUnordered(linkIndices),
  );
}

/// One entry in the paint and focus order.
@immutable
class FluentSankeyDomItem {
  /// Creates an ordering entry.
  const FluentSankeyDomItem({
    required this.layer,
    required this.isNode,
    required this.index,
  });

  /// Column the entry belongs to — a link takes its source node's layer.
  final int layer;

  /// Whether [index] addresses a node or a link.
  final bool isNode;

  /// Index into [FluentSankeyLayoutResult.nodes] or
  /// [FluentSankeyLayoutResult.links].
  final int index;
}

/// The paint order, which is also the focus order.
///
/// Ports `SankeyChart.tsx:1094-1127`. Nodes are ordered by `(x0, y0)`, links by
/// `(source.x0, y0)`, and the merged list by layer with nodes ahead of links —
/// that last rule is what stops a skip-layer link painting over a node. Every
/// sort goes through [d3.stableSort] because the upstream comparators return 0
/// for ties and V8's sort has been stable since ES2019.
///
/// Upstream sorts the `nodes` and `links` arrays in place and then indexes the
/// sorted arrays (`:1130-1131`, `:1173`); carrying the original index in
/// [FluentSankeyDomItem.index] is the same walk without mutating the layout.
List<FluentSankeyDomItem> sankeyDomOrder(FluentSankeyLayoutResult layout) {
  final nodeIndices = d3.stableSort<int>(
    List<int>.generate(layout.nodes.length, (i) => i),
    (a, b) {
      final na = layout.nodes[a];
      final nb = layout.nodes[b];
      if (na.x0 != nb.x0) {
        return na.x0.compareTo(nb.x0);
      }
      return na.y0.compareTo(nb.y0);
    },
  );
  final linkIndices = d3.stableSort<int>(
    List<int>.generate(layout.links.length, (i) => i),
    (a, b) {
      final la = layout.links[a];
      final lb = layout.links[b];
      if (la.source.x0 != lb.source.x0) {
        return la.source.x0.compareTo(lb.source.x0);
      }
      return la.y0.compareTo(lb.y0);
    },
  );
  final items = <FluentSankeyDomItem>[
    for (final i in nodeIndices)
      FluentSankeyDomItem(layer: layout.nodes[i].layer, isNode: true, index: i),
    for (final i in linkIndices)
      FluentSankeyDomItem(
        layer: layout.links[i].source.layer,
        isNode: false,
        index: i,
      ),
  ];
  return d3.stableSort<FluentSankeyDomItem>(items, (a, b) {
    if (a.layer != b.layer) {
      return a.layer - b.layer;
    }
    // `:1120-1123` — the string comparison 'node' > 'link' returns -1, so a
    // node sorts ahead of a link in the same column. 1 and -1 are the
    // comparator's own return values.
    if (a.isNode && !b.isNode) {
      return -1;
    }
    if (!a.isNode && b.isNode) {
      return 1;
    }
    return 0;
  });
}

/// The ribbon of one stream.
///
/// Ports `linkToDataPoints` (`SankeyChart.tsx:504-512`) fed through the area
/// generator at `:514-518`. Only the two-point case is ever exercised, so the
/// emitted path is one cubic out, a straight edge across the target node, one
/// cubic back and a close.
///
/// `.curve(d3CurveBasis)` at `SankeyChart.tsx:518` is a misleading local alias:
/// `:12` imports it as `curveBumpX as d3CurveBasis`, so the curve is [curveBumpX]
/// and not `curveBasis`, which would interpolate neither end point and detach the
/// ribbon from both node rectangles. Confirmed against the twenty captured stream
/// paths of `charts-sankeychart--sankey-chart-basic` and `--sankey-chart-inbox`,
/// whose control points all sit on the horizontal midpoint.
Path sankeyLinkPath(SankeyLayoutLink link) {
  // 0.5 splits the band evenly above and below the centre line (`:505`).
  final halfWidth = link.width * 0.5;
  final points = <(double x, double y0, double y1)>[
    (link.source.x1, link.y0 + halfWidth, link.y0 - halfWidth),
    (link.target.x0, link.y1 + halfWidth, link.y1 - halfWidth),
  ];
  final sink = UiPathSink();
  Area<(double, double, double)>(
    x0: (d, i, data) => d.$1,
    y0: (d, i, data) => d.$2,
    y1: (d, i, data) => d.$3,
    curve: curveBumpX,
  )(points, sink);
  return sink.path;
}

/// Paints the whole sankey diagram: streams, node rectangles, node text and the
/// title.
class FluentSankeyChartPainter extends CustomPainter {
  /// Creates a sankey painter.
  FluentSankeyChartPainter({
    required this.layout,
    required this.visuals,
    required this.order,
    required this.selection,
    required this.style,
    required this.states,
    required this.measurer,
    required this.isRtl,
    this.chartTitle,
  });

  /// The solved layout.
  final FluentSankeyLayoutResult layout;

  /// Text visuals per node index.
  final List<FluentSankeyNodeVisual> visuals;

  /// Paint order.
  final List<FluentSankeyDomItem> order;

  /// Current selection.
  final FluentSankeySelection selection;

  /// Resolved style.
  final FluentSankeyChartStyle style;

  /// States the style properties resolve against.
  final Set<WidgetState> states;

  /// Text measurer, shared with the truncation pass.
  final FluentChartTextMeasurer measurer;

  /// Whether the node text is right-aligned (`SankeyChart.tsx:787`).
  final bool isRtl;

  /// Title drawn above the plot, or null.
  final String? chartTitle;

  void _paintLink(Canvas canvas, int index) {
    final link = layout.links[index];
    final path = sankeyLinkPath(link);
    final fill =
        selection.linkFill(index, layout) ??
        style.linkFillColor!.resolve(states)!;
    final fillOpacity = selection.linkFillOpacity(index);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.fill
        ..color = fill.withValues(alpha: fill.a * fillOpacity),
    );
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.linkStrokeWidth!.resolve(states)!;
    final borderOpacity = selection.linkBorderOpacity(index);
    if (selection.linkUsesGradient(index)) {
      // `SankeyChart.tsx:753-758` — a per-link horizontal gradient from the
      // source node's colour to the target node's, which only ever reaches the
      // stroke.
      strokePaint.shader = LinearGradient(
        colors: <Color>[
          layout.nodeColors[link.source.index],
          layout.nodeColors[link.target.index],
        ],
      ).createShader(path.getBounds());
      // 0xFFFFFFFF is an opaque white the shader replaces outright; only the
      // alpha survives, and `_getOpacityStreamBorder` returns 1 on every arm
      // this branch is reachable from.
      strokePaint.color = const Color(
        0xFFFFFFFF,
      ).withValues(alpha: borderOpacity);
    } else {
      final border = selection.linkBorder(index, layout);
      strokePaint.color = border.withValues(alpha: border.a * borderOpacity);
    }
    canvas.drawPath(path, strokePaint);
  }

  void _paintNode(Canvas canvas, int index) {
    final node = layout.nodes[index];
    final visual = visuals[index];
    final rect = Rect.fromLTWH(
      node.x0,
      node.y0,
      node.x1 - node.x0,
      visual.height,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..style = PaintingStyle.fill
        ..color = selection.nodeFill(index, layout),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = style.nodeStrokeWidth!.resolve(states)!
        ..color = selection.nodeBorder(index, layout),
    );
    // `:823` — nothing is drawn below MIN_HEIGHT_FOR_TYPE.
    if (visual.height <= kSankeyMinHeightForType) {
      return;
    }

    final textColor = selection.nodeTextColor(index);
    final nameStyle = style.nameTextStyle!
        .resolve(states)!
        .copyWith(color: textColor);
    final weightStyle = style.weightTextStyle!
        .resolve(states)!
        .copyWith(color: textColor);
    // `:830-831` — dy 1.2em and dx 0.4em at font-size 10 are 12px and 4px.
    _paintText(
      canvas,
      visual.name,
      nameStyle,
      Offset(node.x0 + 4, node.y0 + 12),
    );
    final tooTall = visual.height > kSankeyMinHeightForDoubleLine;
    // `:845-848` — a tall node stacks the weight under the name at dy 2em (28px
    // at font-size 14) and dx 0.4em (5.6px); a short one right-aligns it on the
    // same line at dy 1em (14px), 8px in from the right edge (`:845`).
    _paintText(
      canvas,
      visual.weightText,
      weightStyle,
      tooTall
          ? Offset(node.x0 + 5.6, node.y0 + 28)
          : Offset(node.x1 - visual.weightOffset - 8, node.y0 + 14),
    );
  }

  /// Draws [text] with its ALPHABETIC baseline at [baseline], which is what an
  /// SVG `<text y=…>` does.
  void _paintText(
    Canvas canvas,
    String text,
    TextStyle textStyle,
    Offset baseline,
  ) {
    if (text.isEmpty) {
      return;
    }
    final metrics = measurer.measure(text, textStyle);
    final painter = measurer.layoutPainter(text, textStyle);
    // `:832` — text-anchor is 'end' under RTL, 'start' otherwise.
    final dx = isRtl ? -metrics.width : 0.0;
    painter.paint(
      canvas,
      Offset(baseline.dx + dx, baseline.dy - metrics.ascent),
    );
    painter.dispose();
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final item in order) {
      if (item.isNode) {
        _paintNode(canvas, item.index);
      } else {
        _paintLink(canvas, item.index);
      }
    }
    if (chartTitle != null) {
      // `:1159-1167` — centred, with the SVGTooltipText backing rectangle.
      FluentChartTitlePainter(
        text: chartTitle!,
        style: style.titleTextStyle!.resolve(states)!,
        // `ChartTitle.tsx:78-86` — max(13 + 8, 20 - 8) = 21 by default. 2
        // centres the title over the container.
        anchor: Offset(layout.size.width / 2, 21),
        textAnchor: FluentAxisTextAnchor.middle,
        baseline: FluentChartTitleBaseline.alphabetic,
        // 0 — the title is never rotated.
        rotationRadians: 0,
        showBackground: true,
        backgroundColor: style.titleBackgroundColor!.resolve(states)!,
        measurer: measurer,
      ).paint(canvas, size);
    }
  }

  @override
  bool shouldRepaint(FluentSankeyChartPainter oldDelegate) =>
      oldDelegate.layout != layout ||
      oldDelegate.selection != selection ||
      oldDelegate.style != style ||
      oldDelegate.isRtl != isRtl ||
      oldDelegate.chartTitle != chartTitle ||
      !identical(oldDelegate.visuals, visuals);
}
