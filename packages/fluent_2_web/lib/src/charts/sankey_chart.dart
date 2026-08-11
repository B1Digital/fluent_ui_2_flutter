import 'dart:collection';

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' show NumberFormat;

import 'chrome/axis_label_tooltip.dart';
import 'chrome/chart_popover.dart';
import 'chrome/chart_title.dart';
import 'chrome/legend.dart';
import 'internal/chart_colors.dart';
import 'internal/chart_text_measurer.dart';
import 'internal/d3/axis_geometry.dart';
import 'internal/d3/curves.dart';
import 'internal/d3/js_math.dart';
import 'internal/d3/path_sink.dart';
import 'internal/d3/sankey.dart';
import 'internal/d3/shape_line_area.dart';
import 'internal/d3/stable_sort.dart' as d3;
import 'internal/image_export.dart';
import 'model/sankey_data.dart';
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
///
/// **Forced colours.** Every mark colour goes through [colors], because a
/// sankey's ink is the ten hard-coded pairs of `SankeyChart.tsx:41-52` rather
/// than anything the theme resolves, and spec §5.3 flattens series marks under
/// high contrast. Which slot each mark takes is decided per mark:
///
/// * A node rectangle is a solid mark, so its fill takes
///   [FluentChartColors.flattenMark] and its border
///   [FluentChartColors.flattenMarkStroke] — the same pairing as every other
///   chart in the package. Upstream renders the same CanvasText fill: the
///   `<rect>` at `SankeyChart.tsx:811` carries its own `fill`, so the
///   `fill: 'Canvas'` of `useSankeyChartStyles.styles.ts:40-42` never reaches
///   it — that rule sits on the ancestor `<g>` at `SankeyChart.tsx:1172` and an
///   inherited value loses to a presentation attribute.
/// * A node's text takes [FluentChartColors.flattenMarkStroke] too, so it reads
///   against that flattened fill. `useSankeyChartStyles.styles.ts:46-50` forces
///   it to `CanvasText` instead — a rule that does reach the `<text>`
///   elements — which would paint white on white; spec §5.2 exempts
///   accessibility defects from bug fidelity, and Canvas is the other half of
///   the pair upstream's own `:40-42` was reaching for.
/// * A stream ribbon is hollow: its fill is `colorNeutralBackground1`
///   (`useSankeyChartStyles.styles.ts:31-37`), which the high-contrast palette
///   already resolves to Canvas — exactly what that rule's `:34-36` arm forces.
///   It is chrome, not ink, and is **not** flattened; `flattenMark` there would
///   paint every ribbon solid CanvasText and swallow the diagram. Only the fill
///   a selected stream takes from its own `color` (`SankeyChart.tsx:947-949`)
///   is ink, and that one flattens.
/// * A ribbon's border is therefore the only ink it has, so it takes
///   [FluentChartColors.flattenMark] and not the halo slot
///   [FluentChartColors.flattenMarkStroke]: Canvas would erase the streams
///   outright. Forced colours agrees — the `stroke` at `SankeyChart.tsx:763`
///   is a presentation attribute and is rewritten to CanvasText.
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
    required this.colors,
    required this.isRtl,
    this.chartTitle,
    this.titleFontSize,
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

  /// The theme's resolved chart colours, which is what flattens every mark
  /// under high contrast. See the class doc for the slot each mark takes.
  final FluentChartColors colors;

  /// Whether the node text is right-aligned (`SankeyChart.tsx:787`).
  final bool isRtl;

  /// Title drawn above the plot, or null.
  final String? chartTitle;

  /// Size of [chartTitle], which also places its baseline — upstream's
  /// `titleStyles.titleFont.size` (`SankeyChart.tsx:556`,
  /// `ChartTitle.tsx:83`). Null takes the theme's size and the literal 13 the
  /// placement falls back to, which are different numbers upstream too.
  final double? titleFontSize;

  void _paintLink(Canvas canvas, int index) {
    final link = layout.links[index];
    final path = sankeyLinkPath(link);
    final selected = selection.linkFill(index, layout);
    // The selected stream's own colour is ink and flattens; the default fill is
    // the surface the ribbon is cut out of and does not. See the class doc.
    final fill = selected != null
        ? colors.flattenMark(selected)
        : style.linkFillColor!.resolve(states)!;
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
      // stroke. Both stops are node ink (`:755-756`), so both flatten.
      final start = colors.flattenMark(layout.nodeColors[link.source.index]);
      final end = colors.flattenMark(layout.nodeColors[link.target.index]);
      if (start == end) {
        // Under high contrast the two stops land on one system colour, so the
        // gradient IS a flat stroke; a shader here would allocate a ramp to
        // interpolate a colour with itself. Two nodes that happen to share a
        // palette entry take the same short cut, and paint the same pixels.
        strokePaint.color = start.withValues(alpha: start.a * borderOpacity);
      } else {
        strokePaint.shader = LinearGradient(
          colors: <Color>[start, end],
        ).createShader(path.getBounds());
        // 0xFFFFFFFF is an opaque white the shader replaces outright; only the
        // alpha survives, and `_getOpacityStreamBorder` returns 1 on every arm
        // this branch is reachable from.
        strokePaint.color = const Color(
          0xFFFFFFFF,
        ).withValues(alpha: borderOpacity);
      }
    } else {
      // A ribbon's border is its only ink, so it takes the fill slot.
      final border = colors.flattenMark(selection.linkBorder(index, layout));
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
        ..color = colors.flattenMark(selection.nodeFill(index, layout)),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = style.nodeStrokeWidth!.resolve(states)!
        ..color = colors.flattenMarkStroke(selection.nodeBorder(index, layout)),
    );
    // `:823` — nothing is drawn below MIN_HEIGHT_FOR_TYPE.
    if (visual.height <= kSankeyMinHeightForType) {
      return;
    }

    // The stroke slot, so the text keeps its contrast against the fill above.
    final textColor = colors.flattenMarkStroke(selection.nodeTextColor(index));
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
        // `ChartTitle.tsx:106` passes the same font to
        // `getChartTitleInlineStyles`, whose `Common.styles.ts:113` writes it
        // over the class's size. A null size leaves the class alone, which is
        // what `copyWith` does with one.
        style: style.titleTextStyle!
            .resolve(states)!
            .copyWith(fontSize: titleFontSize),
        // `SankeyChart.tsx:1160-1166` passes no `y`, so the default of
        // `ChartTitle.tsx:80-87` places the baseline. 2 centres the title over
        // the container (`:1162`).
        anchor: Offset(
          layout.size.width / 2,
          fluentChartTitleDefaultY(titleFontSize),
        ),
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
      oldDelegate.colors != colors ||
      oldDelegate.isRtl != isRtl ||
      oldDelegate.chartTitle != chartTitle ||
      oldDelegate.titleFontSize != titleFontSize ||
      !identical(oldDelegate.visuals, visuals);
}

/// Container width used when the chart is given an unbounded constraint
/// (`SankeyChart.tsx:572`).
const double kSankeyDefaultWidth = 912;

/// Container height used when the chart is given an unbounded constraint
/// (`SankeyChart.tsx:571`).
const double kSankeyDefaultHeight = 468;

/// How the chart reacts when its container is narrower than its minimum width.
enum FluentSankeyReflowMode {
  /// Squash the diagram into whatever width there is. The upstream default.
  none,

  /// Keep the minimum width and scroll horizontally
  /// (`useSankeyChartStyles.styles.ts:86`).
  minWidth,
}

/// A Fluent 2 sankey diagram.
///
/// Ports `SankeyChart` (`SankeyChart.tsx:543-1200`). `width`, `height`,
/// `className`, `pathColor` and `enableReflow` are omitted: all five are dead
/// upstream (`:36-48`). `parentRef` and `shouldResize` are replaced by the
/// widget's own [BoxConstraints].
class FluentSankeyChart extends StatefulWidget {
  /// Creates a sankey chart.
  const FluentSankeyChart({
    required this.data,
    super.key,
    this.chartTitle,
    this.titleFontSize,
    this.hideTitle = false,
    this.colorsForNodes,
    this.borderColorsForNodes,
    this.numberFormat,
    this.linkFromLabel = 'From {0}',
    this.emptySemanticLabel = 'Graph has no data to display',
    this.nodeSemanticLabel = 'node {0} with weight {1}',
    this.linkSemanticLabel = 'link from {0} to {1} with weight {2}',
    this.reflowMode = FluentSankeyReflowMode.none,
    this.controller,
    this.style,
  });

  /// Nodes and links.
  final FluentSankeyChartData data;

  /// Title drawn above the diagram (`SankeyChart.tsx:1159-1161`).
  final String? chartTitle;

  /// Title font size, which also sets the top margin (`SankeyChart.tsx:556`).
  final double? titleFontSize;

  /// Whether the title is suppressed. Upstream spells this `hideLegend`
  /// (`SankeyChart.tsx:1159`) even though the chart has no legend.
  final bool hideTitle;

  /// Node fills. Used only together with [borderColorsForNodes].
  final List<Color>? colorsForNodes;

  /// Node borders. Used only together with [colorsForNodes].
  final List<Color>? borderColorsForNodes;

  /// Formatter for every weight. Null renders `value.toString()`
  /// (`SankeyChart.tsx:612-614`).
  final NumberFormat? numberFormat;

  /// Template for the popover's description line (`SankeyChart.tsx:1036`).
  final String linkFromLabel;

  /// Announced when there is nothing to draw (`SankeyChart.tsx:1047`).
  final String emptySemanticLabel;

  /// Template for a node's label (`SankeyChart.tsx:1045`).
  final String nodeSemanticLabel;

  /// Template for a stream's label (`SankeyChart.tsx:1044`).
  final String linkSemanticLabel;

  /// Behaviour when the container is narrower than the diagram's minimum width.
  final FluentSankeyReflowMode reflowMode;

  /// Imperative handle exposing `toImage`. Ports `componentRef`
  /// (`SankeyChart.tsx:548`).
  final FluentChartController? controller;

  /// Style override, layered over the theme's.
  final FluentSankeyChartStyle? style;

  @override
  State<FluentSankeyChart> createState() => FluentSankeyChartState();
}

/// State of a [FluentSankeyChart].
///
/// Public so that a `GlobalKey<FluentSankeyChartState>` can reach the layout and
/// the selection, which is what upstream's `componentRef`
/// (`SankeyChart.tsx:548`) exposes.
class FluentSankeyChartState extends State<FluentSankeyChart> {
  final FluentChartTextMeasurer _measurer = FluentChartTextMeasurer();
  final GlobalKey _boundaryKey = GlobalKey();
  FluentSankeySelection _selection = FluentSankeySelection.none;
  FluentSankeyLayoutResult? _layout;
  List<FluentSankeyNodeVisual> _visuals = const <FluentSankeyNodeVisual>[];
  List<FluentSankeyDomItem> _order = const <FluentSankeyDomItem>[];
  FluentChartPopoverData? _popover;
  Offset _popoverAnchor = Offset.zero;
  String? _tooltipName;

  /// The layout the chart last painted.
  FluentSankeyLayoutResult get layout => _layout!;

  /// The node text visuals the chart last painted.
  List<FluentSankeyNodeVisual> get visuals => _visuals;

  /// The current selection.
  FluentSankeySelection get selection => _selection;

  @override
  void dispose() {
    widget.controller?.detach();
    _measurer.invalidate();
    super.dispose();
  }

  /// `_formatNumber` (`SankeyChart.tsx:610-617`).
  String _formatNumber(double value) => widget.numberFormat != null
      ? widget.numberFormat!.format(value)
      : jsNumberToString(value);

  /// `updatePosition` (`SankeyChart.tsx:1023-1032`) — a 1px dead zone.
  void _updateAnchor(Offset next) {
    // 1 is upstream's movement threshold (`:1024`).
    if ((next - _popoverAnchor).distance > 1) {
      _popoverAnchor = next;
    }
  }

  void _closeCallout() {
    _popover = null;
    _updateAnchor(Offset.zero);
  }

  void _onHover(Offset local) {
    final l = _layout;
    if (l == null) {
      return;
    }
    // Reverse paint order: whatever was drawn last is on top.
    for (final item in _order.reversed) {
      if (item.isNode) {
        final node = l.nodes[item.index];
        final rect = Rect.fromLTRB(node.x0, node.y0, node.x1, node.y1);
        if (!rect.contains(local)) {
          continue;
        }
        setState(() {
          _closeCallout();
          _selection = FluentSankeySelection.forNode(node);
          _updateAnchor(local);
          // `:885` — only a node shorter than MIN_HEIGHT_FOR_TYPE gets a
          // callout.
          if (node.y1 - node.y0 < kSankeyMinHeightForType) {
            _popover = FluentChartPopoverData(
              xValue: l.data.nodes[item.index].name,
              color: l.nodeColors[item.index],
              yValue: _formatNumber(l.nodeActualValues[item.index]),
            );
          }
          _tooltipName = _visuals[item.index].trimmed
              ? l.data.nodes[item.index].name
              : null;
        });
        return;
      }
      final link = l.links[item.index];
      if (!sankeyLinkPath(link).contains(local)) {
        continue;
      }
      setState(() {
        _closeCallout();
        _selection = FluentSankeySelection.forLink(link);
        _updateAnchor(local);
        // `:667-673` — target name on top, unnormalised weight below, source in
        // the description line.
        _popover = FluentChartPopoverData(
          xValue: l.data.nodes[link.target.index].name,
          color: l.nodeColors[link.source.index],
          yValue: _formatNumber(l.linkUnnormalisedValues[item.index]),
          descriptionMessage: formatSankeyTemplate(
            widget.linkFromLabel,
            <Object?>[l.data.nodes[link.source.index].name],
          ),
        );
        _tooltipName = null;
      });
      return;
    }
    if (_selection.active || _popover != null || _tooltipName != null) {
      setState(_clearHover);
    }
  }

  void _clearHover() {
    _selection = FluentSankeySelection.none;
    _closeCallout();
    _tooltipName = null;
  }

  /// The stream's screen-reader label (`SankeyChart.tsx:1048-1053`).
  String _linkSemanticLabel(FluentSankeyLayoutResult solved, int index) {
    final link = solved.links[index];
    return formatSankeyTemplate(widget.linkSemanticLabel, <Object?>[
      solved.data.nodes[link.source.index].name,
      solved.data.nodes[link.target.index].name,
      _formatNumber(solved.linkUnnormalisedValues[index]),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final style = resolveFluentSankeyChartStyle(
      theme,
    ).merge(FluentSankeyChartTheme.maybeOf(context)).merge(widget.style);
    const states = <WidgetState>{};
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    if (widget.data.nodes.isEmpty || widget.data.links.isEmpty) {
      // `:1197` — a zero-opacity alert region, nothing painted.
      return Semantics(
        container: true,
        liveRegion: true,
        label: widget.emptySemanticLabel,
        child: const SizedBox.shrink(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : kSankeyDefaultWidth;
        final height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : kSankeyDefaultHeight;
        final titleHeight = sankeyTitleHeight(
          chartTitle: widget.hideTitle ? null : widget.chartTitle,
          titleFontSize: widget.titleFontSize,
        );
        var size = Size(available, height);
        var solved = computeFluentSankeyLayout(
          data: widget.data,
          size: size,
          titleHeight: titleHeight,
          isRtl: isRtl,
          colorsForNodes: widget.colorsForNodes,
          borderColorsForNodes: widget.borderColorsForNodes,
        );
        if (widget.reflowMode == FluentSankeyReflowMode.minWidth) {
          // `:590-592` needs the column count, which only the first pass knows.
          // Upstream has the same chicken-and-egg and starts from 0; solving
          // twice is deterministic instead of settling over two frames.
          final minWidth = calculateSankeyChartMinWidth(solved.columnCount);
          if (minWidth > available) {
            size = Size(minWidth, height);
            solved = computeFluentSankeyLayout(
              data: widget.data,
              size: size,
              titleHeight: titleHeight,
              isRtl: isRtl,
              colorsForNodes: widget.colorsForNodes,
              borderColorsForNodes: widget.borderColorsForNodes,
            );
          }
        }
        _layout = solved;
        _visuals = computeSankeyNodeVisuals(
          layout: solved,
          measurer: _measurer,
          nameStyle: style.nameTextStyle!.resolve(states)!,
          weightMeasurementStyle: style.weightMeasurementTextStyle!.resolve(
            states,
          )!,
          formatNumber: _formatNumber,
          nodeSemanticLabel: (name, weight) => formatSankeyTemplate(
            widget.nodeSemanticLabel,
            <Object?>[name, weight],
          ),
        );
        _order = sankeyDomOrder(solved);
        // `hooks.ts:23-41`, but `SankeyChart.tsx:548` calls
        // `useImageExport(props.componentRef, true, false)`, hard-coding
        // `hideLegends: true` — the chart has no legend to synthesise, so the
        // export is the bare diagram.
        widget.controller?.attach(
          FluentChartImageExporter(
            boundaryKey: _boundaryKey,
            legends: const <FluentChartLegendItem>[],
            measurer: _measurer,
          ),
        );

        final canvas = Semantics(
          container: true,
          // `:1157`.
          label:
              'Sankey chart with ${solved.nodes.length} nodes and '
              '${solved.links.length} links',
          // `:1172` and `:1178` give every node and stream its own node, whose
          // labels the painter cannot carry.
          hint: <String>[
            for (final visual in _visuals) visual.semanticLabel,
            for (var i = 0; i < solved.links.length; i++)
              _linkSemanticLabel(solved, i),
          ].join('. '),
          child: MouseRegion(
            onHover: (event) => _onHover(event.localPosition),
            onExit: (_) => setState(_clearHover),
            child: Stack(
              children: <Widget>[
                CustomPaint(
                  size: size,
                  painter: FluentSankeyChartPainter(
                    layout: solved,
                    visuals: _visuals,
                    order: _order,
                    selection: _selection,
                    style: style,
                    states: states,
                    measurer: _measurer,
                    colors: FluentChartColors.of(theme),
                    isRtl: isRtl,
                    chartTitle: widget.hideTitle ? null : widget.chartTitle,
                    titleFontSize: widget.titleFontSize,
                  ),
                ),
                if (_popover != null)
                  FluentChartPopover(data: _popover!, anchor: _popoverAnchor),
                // `:994-1004` — the full name only when the drawn one was
                // trimmed.
                if (_tooltipName != null)
                  Positioned(
                    left: _popoverAnchor.dx,
                    // 28 lifts the tooltip clear of the pointer, the same gap
                    // `useSankeyChartStyles.styles.ts:47` gives the label div.
                    top: _popoverAnchor.dy - 28,
                    child: FluentAxisLabelTooltip(
                      fullText: _tooltipName!,
                      renderedText: '',
                      child: const SizedBox.shrink(),
                    ),
                  ),
              ],
            ),
          ),
        );

        // Inside the scroller, not around it, so the export is the whole
        // diagram rather than the slice the viewport happens to show.
        final boundary = RepaintBoundary(
          key: _boundaryKey,
          child: SizedBox.fromSize(size: size, child: canvas),
        );
        return widget.reflowMode == FluentSankeyReflowMode.minWidth
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: boundary,
              )
            : boundary;
      },
    );
  }
}
