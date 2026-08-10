import 'dart:collection';

import 'package:flutter/widgets.dart';

import 'internal/d3/sankey.dart';
import 'sankey_chart_layout.dart';

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
}
