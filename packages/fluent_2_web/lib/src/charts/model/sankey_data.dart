import 'package:flutter/widgets.dart';

/// One node of a Sankey diagram, as the caller supplies it.
///
/// Ports `SNodeExtra` (`types/DataPoint.ts:901-914`) minus its layout members.
/// `actualValue`, `layer` and the `x0`/`x1`/`y0`/`y1` box are outputs of the
/// layout pass and live on `SankeyLayoutNode` in `internal/d3/sankey.dart`, so
/// the input stays immutable. That closes the upstream `TODO` at
/// `SankeyChart.tsx:697-701` and is a recorded behaviour change.
@immutable
class FluentSankeyNode {
  /// Creates a node.
  const FluentSankeyNode({
    required this.nodeId,
    required this.name,
    this.color,
    this.borderColor,
  }) : assert(
         nodeId is num || nodeId is String,
         'types/DataPoint.ts:905 — `number | string`.',
       );

  /// A value unique among the diagram's nodes: a number or a string.
  ///
  /// Ports `nodeId` (`types/DataPoint.ts:905`).
  final Object nodeId;

  /// The name shown on the node.
  ///
  /// Ports `name` (`types/DataPoint.ts:909`).
  final String name;

  /// The node's fill. Null falls back to the data-visualisation palette.
  ///
  /// Ports the optional `color` (`types/DataPoint.ts:910`).
  final Color? color;

  /// The node's border. Null draws no border.
  ///
  /// Ports the optional `borderColor` (`types/DataPoint.ts:911`).
  final Color? borderColor;
}

/// One weighted link between two nodes.
///
/// Ports `SLinkExtra` (`types/DataPoint.ts:916-931`) minus `unnormalizedValue`
/// (`:929`), which the layout pass computes.
@immutable
class FluentSankeyLink {
  /// Creates a link.
  const FluentSankeyLink({
    required this.source,
    required this.target,
    required this.value,
    this.color,
  });

  /// The index of the source node within the diagram's node list.
  ///
  /// Ports `source` (`types/DataPoint.ts:920`), which is an index rather than a
  /// [FluentSankeyNode.nodeId].
  final int source;

  /// The index of the target node within the diagram's node list.
  ///
  /// Ports `target` (`types/DataPoint.ts:924`), likewise an index.
  final int target;

  /// The weight of the link, which sets its thickness.
  ///
  /// Ports `value` (`types/DataPoint.ts:928`).
  final double value;

  /// The link's fill. Null derives a gradient from the two endpoint colours.
  ///
  /// Ports the optional `color` (`types/DataPoint.ts:930`).
  final Color? color;
}

/// A whole Sankey diagram's input.
///
/// Ports `SankeyChartData` (`types/DataPoint.ts:896-899`).
@immutable
class FluentSankeyChartData {
  /// Creates a diagram.
  const FluentSankeyChartData({required this.nodes, required this.links});

  /// The nodes, in the order [FluentSankeyLink.source] and
  /// [FluentSankeyLink.target] index into.
  ///
  /// Ports `nodes` (`types/DataPoint.ts:897`).
  final List<FluentSankeyNode> nodes;

  /// The links between them.
  ///
  /// Ports `links` (`types/DataPoint.ts:898`).
  final List<FluentSankeyLink> links;
}
