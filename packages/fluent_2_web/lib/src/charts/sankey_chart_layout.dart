import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'internal/chart_text_measurer.dart';
import 'internal/chart_text_styles.dart';
import 'internal/d3/array_stats.dart' as d3;
import 'internal/d3/sankey.dart';
import 'model/sankey_data.dart';

/// Width of every node rectangle (`SankeyChart.tsx:62`).
const double kSankeyNodeWidth = 124;

/// Below this height a node draws no text at all (`SankeyChart.tsx:55`).
const double kSankeyMinHeightForType = 24;

/// Above this height the name and the weight take separate lines
/// (`SankeyChart.tsx:54`).
const double kSankeyMinHeightForDoubleLine = 36;

/// Fraction of the plot height reserved for inter-node padding
/// (`SankeyChart.tsx:23`).
const double kSankeyPaddingPercentage = 0.3;

/// Fill opacity of a stream in the hovered path when no node is selected
/// (`SankeyChart.tsx:58`).
const double kSankeySelectedStreamOpacity = 0.3;

/// Stroke opacity of a stream outside the hovered path (`SankeyChart.tsx:59`).
const double kSankeyNonSelectedStreamBorderOpacity = 0.5;

/// Stroke width of a node rectangle (`SankeyChart.tsx:817`).
const double kSankeyNodeStrokeWidth = 2;

/// Stroke width of a stream. The presentation attribute at `SankeyChart.tsx:764`
/// beats the inherited `strokeWidth: 3px` from `useSankeyChartStyles.styles.ts:33`.
const double kSankeyLinkStrokeWidth = 2;

/// Left and right margin (`SankeyChart.tsx:561`).
const double kSankeyMarginHorizontal = 48;

/// Bottom margin (`SankeyChart.tsx:561`).
const double kSankeyMarginBottom = 32;

/// Floor applied to the top margin, with or without a title
/// (`SankeyChart.tsx:554-560`).
const double kSankeyMinTitleHeight = 36;

/// Fill and stroke of everything outside the selection (`SankeyChart.tsx:40`).
const Color kSankeyNonSelectedColor = Color(0xFF757575);

/// Node text colour when the node is outside the selection.
///
/// Upstream calls it `DEFAULT_TEXT_COLOR` (`SankeyChart.tsx:60`), but
/// `nodeTextColor` (`:520-531`) reaches for it only on the negated branch.
const Color kSankeyDefaultTextColor = Color(0xFF323130);

/// Node text colour in the default and selected states.
///
/// Upstream calls it `NON_SELECTED_TEXT_COLOR` (`SankeyChart.tsx:61`); see
/// [kSankeyDefaultTextColor] for why the two names read backwards.
const Color kSankeyNonSelectedTextColor = Color(0xFFFFFFFF);

/// Fill given to a node that supplied only a border colour
/// (`SankeyChart.tsx:375`).
const Color kSankeyBorderOnlyFill = Color(0xFFF5F5F5);

/// The ten default fill and border pairs (`SankeyChart.tsx:41-52`).
const List<(Color, Color)> kSankeyDefaultNodeColors = <(Color, Color)>[
  (Color(0xFF00758F), Color(0xFF002E39)),
  (Color(0xFF77004D), Color(0xFF43002C)),
  (Color(0xFF4F6BED), Color(0xFF3B52B4)),
  (Color(0xFF937600), Color(0xFF6D5700)),
  (Color(0xFF286EA8), Color(0xFF00457E)),
  (Color(0xFFA43FB1), Color(0xFF7C158A)),
  (Color(0xFFCC3595), Color(0xFF7F215D)),
  (Color(0xFF0E7878), Color(0xFF004E4E)),
  (Color(0xFF8764B8), Color(0xFF4B3867)),
  (Color(0xFF9C663F), Color(0xFF6D4123)),
];

/// The value of a laid-out node, for [d3.sum].
double _nodeValue(Object? node, int index) => (node! as SankeyLayoutNode).value;

/// The height of a laid-out node, for [d3.sum].
double _nodeHeight(Object? node, int index) {
  final typed = node! as SankeyLayoutNode;
  return typed.y1 - typed.y0;
}

/// Groups the laid-out nodes by column (`SankeyChart.tsx:164-175`).
Map<int, List<SankeyLayoutNode>> groupSankeyNodesByColumn(
  List<SankeyLayoutNode> nodes,
) {
  final result = <int, List<SankeyLayoutNode>>{};
  for (final node in nodes) {
    result.putIfAbsent(node.layer, () => <SankeyLayoutNode>[]).add(node);
  }
  return result;
}

/// Lifts every node worth less than one percent of its column to one percent, then
/// rescales the column so the total stays at 100.
///
/// Ports `adjustOnePercentHeightNodes` (`SankeyChart.tsx:180-216`) and
/// `changeColumnValue` (`:221-237`). [nodeValues] and [linkValues] are the values read
/// straight after the first layout pass, indexed by `node.index` and `link.index`;
/// [actualValues] and [unnormalisedValues] are written in place.
///
/// `// ponytail:` upstream keys its value maps by node id, so two parallel links between
/// the same pair of nodes collapse onto one entry (`:308-324`). Indexing by
/// `link.index` keeps them apart. That is a fix, not a divergence in any shipped story.
void adjustSankeyOnePercentHeightNodes({
  required Map<int, List<SankeyLayoutNode>> columns,
  required List<double> nodeValues,
  required List<double> linkValues,
  required List<double> actualValues,
  required List<double?> unnormalisedValues,
}) {
  // `:185-188` walks `Object.values`, which enumerates integer-like keys ascending.
  // `// ponytail:` iterating the sorted keys is the same walk and cannot throw on a
  // column index the layout never filled.
  final keys = columns.keys.toList()..sort();
  for (final key in keys) {
    final column = columns[key]!;
    final columnValue = d3.sum(column, accessor: _nodeValue);
    // 0.01 is one percent, `:190`.
    final onePercent = 0.01 * columnValue;
    var totalPercentage = 0.0;
    for (final node in column) {
      final value = nodeValues[node.index];
      // 100 converts the fraction to a percentage, `:194`.
      final nodePercentage = value / columnValue * 100;
      actualValues[node.index] = value;
      // 1 is the one-percent floor, `:197`.
      if (nodePercentage < 1) {
        node.value = onePercent;
        totalPercentage += 1;
      } else {
        totalPercentage += nodePercentage;
      }
    }
    // `:205` — a zero total is guarded so the ratio stays 1.
    final scalingRatio = totalPercentage != 0 ? totalPercentage / 100 : 1.0;
    // `:206` — only an overflowing column is rescaled.
    if (scalingRatio <= 1) {
      continue;
    }
    for (final node in column) {
      final normalised = node.value = node.value / scalingRatio;
      _changeColumnValue(
        node,
        nodeValues[node.index],
        normalised,
        linkValues,
        unnormalisedValues,
      );
    }
  }
}

/// Rescales a node's links to match its normalised value (`SankeyChart.tsx:221-237`).
void _changeColumnValue(
  SankeyLayoutNode node,
  double originalNodeValue,
  double normalisedNodeValue,
  List<double> linkValues,
  List<double?> unnormalisedValues,
) {
  void update(SankeyLayoutLink link) {
    final value = linkValues[link.index];
    unnormalisedValues[link.index] = value;
    final linkRatio = value / originalNodeValue;
    // `:233` — the link never shrinks, only grows to its share of the new node value.
    link.value = math.max(normalisedNodeValue * linkRatio, link.value);
  }

  node.sourceLinks.forEach(update);
  node.targetLinks.forEach(update);
}

/// Tightens the layout's node padding when a column is sparse.
///
/// Ports `adjustPadding` (`SankeyChart.tsx:260-272`). Note the division by
/// `column.length - 1`: a single-node column divides by zero, and `min(8, Infinity)`
/// leaves the default padding untouched — reproduce, do not guard.
void adjustSankeyPadding(
  Sankey sankey,
  double height,
  Map<int, List<SankeyLayoutNode>> columns,
) {
  var padding = sankey.currentNodePadding;
  final minPadding = kSankeyPaddingPercentage * height;
  for (final column in columns.values) {
    final totalPaddingInColumn = height - d3.sum(column, accessor: _nodeHeight);
    if (minPadding < totalPaddingInColumn) {
      // 1 is the gap count, one fewer than the node count (`:268`).
      padding = math.min(padding, minPadding / (column.length - 1));
    }
  }
  sankey.nodePadding(padding);
}

/// Assigns a fill and a border to every node.
///
/// Ports `assignNodeColors` (`SankeyChart.tsx:353-379`). The cycle index advances for
/// **every** node, including the ones that supplied their own colours, so a partially
/// coloured graph does not fall back onto a contiguous palette run.
({List<Color> fills, List<Color> borders}) assignSankeyNodeColors(
  List<FluentSankeyNode> nodes, {
  List<Color>? colorsForNodes,
  List<Color>? borderColorsForNodes,
}) {
  // `:360-366` — a custom palette needs BOTH lists or neither is used.
  final useCustom = colorsForNodes != null && borderColorsForNodes != null;
  final colors = useCustom
      ? colorsForNodes
      : <Color>[for (final pair in kSankeyDefaultNodeColors) pair.$1];
  final borders = useCustom
      ? borderColorsForNodes
      : <Color>[for (final pair in kSankeyDefaultNodeColors) pair.$2];
  final fillOut = <Color>[];
  final borderOut = <Color>[];
  var currentIndex = 0;
  for (final node in nodes) {
    if (node.color == null && node.borderColor == null) {
      fillOut.add(colors[currentIndex]);
      borderOut.add(borders[currentIndex]);
    } else if (node.color != null && node.borderColor == null) {
      fillOut.add(node.color!);
      borderOut.add(kSankeyNonSelectedColor);
    } else if (node.borderColor != null && node.color == null) {
      fillOut.add(kSankeyBorderOnlyFill);
      borderOut.add(node.borderColor!);
    } else {
      fillOut.add(node.color!);
      borderOut.add(node.borderColor!);
    }
    // 1 advances the cycle for every node, coloured or not (`:377`).
    currentIndex = (currentIndex + 1) % colors.length;
  }
  return (fills: fillOut, borders: borderOut);
}

/// Minimum width the chart needs to show [columnCount] node columns
/// (`SankeyChart.tsx:1012-1021`).
double calculateSankeyChartMinWidth(int columnCount) =>
    kSankeyMarginHorizontal +
    kSankeyMarginHorizontal +
    columnCount * kSankeyNodeWidth +
    // The minimum column gap is half a node width, and there is one fewer gap
    // than there are columns (`:1019`).
    (columnCount - 1) * (kSankeyNodeWidth / 2);

/// Height the chart reserves above the plot for its title.
///
/// Ports `SankeyChart.tsx:554-560`: a title costs its font size plus
/// `CHART_TITLE_PADDING`, floored at 36; no title still reserves 36.
double sankeyTitleHeight({String? chartTitle, double? titleFontSize}) =>
    chartTitle != null
    // 13 is upstream's fallback title size (`SankeyChart.tsx:556`).
    ? math.max(
        (titleFontSize ?? 13) + kChartTitlePadding,
        kSankeyMinTitleHeight,
      )
    : kSankeyMinTitleHeight;

/// The solved sankey layout: node and link geometry plus the derived values.
@immutable
class FluentSankeyLayoutResult {
  /// Creates a layout result. Prefer [computeFluentSankeyLayout].
  const FluentSankeyLayoutResult({
    required this.data,
    required this.nodes,
    required this.links,
    required this.nodeActualValues,
    required this.linkUnnormalisedValues,
    required this.nodeColors,
    required this.nodeBorderColors,
    required this.columnCount,
    required this.size,
    required this.titleHeight,
  });

  /// The caller's data, for names and ids. Indexed by [SankeyLayoutNode.index].
  final FluentSankeyChartData data;

  /// The laid-out nodes, in input order.
  final List<SankeyLayoutNode> nodes;

  /// The laid-out links, in input order.
  final List<SankeyLayoutLink> links;

  /// Pre-normalisation node weights, indexed by node index
  /// (`SankeyChart.tsx:249-251`).
  final List<double> nodeActualValues;

  /// Pre-normalisation link weights, indexed by link index
  /// (`SankeyChart.tsx:244-248`).
  final List<double> linkUnnormalisedValues;

  /// Fill colour per node index.
  final List<Color> nodeColors;

  /// Border colour per node index.
  final List<Color> nodeBorderColors;

  /// Number of node columns, which drives the minimum reflow width.
  final int columnCount;

  /// The container size the layout was solved against.
  final Size size;

  /// Top margin, which is the title's reserved band.
  final double titleHeight;

  /// Whether there is nothing to draw (`SankeyChart.tsx:675-678`).
  bool get isEmpty => nodes.isEmpty || links.isEmpty;
}

/// Runs the whole upstream layout pipeline.
///
/// Ports `_normalizeSankeyData` (`SankeyChart.tsx:681-731`). The order matters:
/// the d3 layout runs (`:695`), the one-percent normalisation rewrites node and
/// link values (`:714`), the padding is retuned (`:715`), and then the layout
/// runs a **second** time (`:719`). Upstream's comment at `:716-718` says the
/// second pass is what makes links hoverable; in fact it is also what makes the
/// lifted values reach the geometry, because `_computeNodeValues` recomputes
/// every node weight from its links.
FluentSankeyLayoutResult computeFluentSankeyLayout({
  required FluentSankeyChartData data,
  required Size size,
  required double titleHeight,
  required bool isRtl,
  List<Color>? colorsForNodes,
  List<Color>? borderColorsForNodes,
}) {
  final colours = assignSankeyNodeColors(
    data.nodes,
    colorsForNodes: colorsForNodes,
    borderColorsForNodes: borderColorsForNodes,
  );
  if (data.nodes.isEmpty || data.links.isEmpty) {
    return FluentSankeyLayoutResult(
      data: data,
      nodes: const <SankeyLayoutNode>[],
      links: const <SankeyLayoutLink>[],
      nodeActualValues: const <double>[],
      linkUnnormalisedValues: const <double>[],
      nodeColors: colours.fills,
      nodeBorderColors: colours.borders,
      columnCount: 0,
      size: size,
      titleHeight: titleHeight,
    );
  }

  // `:286-299` — upstream clones the caller's data; here the layout objects are
  // new by construction, so the caller's immutable model is never touched.
  final nodes = <SankeyLayoutNode>[
    for (final node in data.nodes) SankeyLayoutNode(id: node.nodeId),
  ];
  final links = <SankeyLayoutLink>[
    for (final link in data.links)
      SankeyLayoutLink(
        source: nodes[link.source],
        target: nodes[link.target],
        value: link.value,
      ),
  ];

  // `:336-342` — the margins are fixed and not overridable by props.
  final sankey = Sankey()
    ..nodeWidth(kSankeyNodeWidth)
    ..extentOf(
      kSankeyMarginHorizontal,
      titleHeight,
      size.width - kSankeyMarginHorizontal,
      size.height - kSankeyMarginBottom,
    )
    ..nodeAlign(isRtl ? sankeyRight : sankeyJustify);

  sankey(nodes, links);

  final columns = groupSankeyNodesByColumn(nodes);
  final columnCount = columns.length;
  // `:712-713` — capture the post-first-pass values before anything mutates
  // them.
  final nodeValues = <double>[for (final node in nodes) node.value];
  final linkValues = <double>[for (final link in links) link.value];
  final actualValues = List<double>.filled(nodes.length, 0);
  final unnormalised = List<double?>.filled(links.length, null);

  adjustSankeyOnePercentHeightNodes(
    columns: columns,
    nodeValues: nodeValues,
    linkValues: linkValues,
    actualValues: actualValues,
    unnormalisedValues: unnormalised,
  );
  // `:715` passes the container height minus the margins, NOT the plot height
  // the layout returned. Reproduced verbatim.
  adjustSankeyPadding(
    sankey,
    size.height - titleHeight - kSankeyMarginBottom,
    columns,
  );
  sankey(nodes, links);

  return FluentSankeyLayoutResult(
    data: data,
    nodes: nodes,
    links: links,
    nodeActualValues: actualValues,
    // `:245-247` — `if (!link.unnormalizedValue)`, so a link the normalisation
    // never touched keeps its own value.
    linkUnnormalisedValues: <double>[
      for (var i = 0; i < links.length; i++) unnormalised[i] ?? linkValues[i],
    ],
    nodeColors: colours.fills,
    nodeBorderColors: colours.borders,
    columnCount: columnCount,
    size: size,
    titleHeight: titleHeight,
  );
}

/// Matches a `{0}`-style placeholder (`utilities/string.ts:5`).
final RegExp _formatRegExp = RegExp(r'\{\d+\}');

/// Substitutes `{0}`-style placeholders (`utilities/string.ts:21-37`).
///
/// A missing or null argument becomes the empty string, exactly as `:30-32` does.
String formatSankeyTemplate(
  String template,
  List<Object?> values,
) => template.replaceAllMapped(_formatRegExp, (match) {
  final token = match.group(0)!;
  // The braces are stripped by `FORMAT_ARGS_REGEX` (`utilities/string.ts:2`);
  // 1 drops the leading `{` and the end bound drops the trailing `}`.
  final index = int.parse(token.substring(1, token.length - 1));
  if (index < 0 || index >= values.length) {
    return '';
  }
  return values[index]?.toString() ?? '';
});

/// The ellipsis appended to a truncated node name (`SankeyChart.tsx:347`).
const String kSankeyEllipsis = '...';

/// Truncates [text] so that it fits [budget], appending [kSankeyEllipsis].
///
/// Ports `truncateText` (`SankeyChart.tsx:389-419`): characters are appended one at
/// a time and the loop stops as soon as the accumulated width reaches
/// `budget - ellipsisWidth`, at which point the last character is dropped and the
/// ellipsis appended. Linear, like upstream — the TODO at `:403` about a binary
/// search is not taken, because matching the exact stop index matters more than the
/// constant factor.
///
/// `// ponytail:` upstream's first render finds no `.nodeName` element, so
/// `getComputedTextLength` returns undefined, `fitsWithinNode` returns false
/// (`:439-445`) and the truncation loop never breaks — the untruncated name ships on
/// pass one (`SankeyChart.tsx:395, 404-416`). That is an artefact of injecting a
/// measurement node into a live DOM; a `TextPainter` measures synchronously and has
/// no equivalent state, so reproducing it would mean deliberately flashing an
/// overlong name on first paint. Fixed, not reproduced.
String truncateSankeyText(
  String text,
  double budget, {
  required FluentChartTextMeasurer measurer,
  required TextStyle style,
}) {
  if (measurer.width(text, style) <= budget) {
    return text;
  }
  final ellipsisWidth = measurer.width(kSankeyEllipsis, style);
  final buffer = StringBuffer();
  var line = '';
  for (var i = 0; i < text.length; i++) {
    buffer.write(text[i]);
    line = buffer.toString();
    if (measurer.width(line, style) >= budget - ellipsisWidth) {
      // `:411-412` — the character that crossed the budget is dropped again.
      return line.substring(0, line.length - 1) + kSankeyEllipsis;
    }
  }
  return line;
}

/// The text a node draws, plus the derived offsets the painter needs.
@immutable
class FluentSankeyNodeVisual {
  /// Creates a node's text visuals.
  const FluentSankeyNodeVisual({
    required this.name,
    required this.trimmed,
    required this.height,
    required this.weightOffset,
    required this.weightText,
    required this.semanticLabel,
  });

  /// The possibly truncated node name.
  final String name;

  /// Whether [name] ends in an ellipsis, which is what gates the hover tooltip
  /// (`SankeyChart.tsx:650`).
  final bool trimmed;

  /// Height of the node rectangle, floored at zero (`SankeyChart.tsx:630`).
  final double height;

  /// Measured width of the weight string, which positions it on a short node
  /// (`SankeyChart.tsx:658, 844`). Zero on a tall node.
  final double weightOffset;

  /// The weight as drawn (`SankeyChart.tsx:855`).
  final String weightText;

  /// Screen-reader label for the node rectangle (`SankeyChart.tsx:1055`).
  final String semanticLabel;
}

/// Computes the text visuals for every node.
///
/// Ports `_computeNodeAttributes` (`SankeyChart.tsx:619-665`). The name budget is
/// `NODE_WIDTH - 8` less the padding: 8 on a tall node, and `8 + 6 + weightWidth` on
/// a short one, where the weight is measured at [weightMeasurementStyle].
List<FluentSankeyNodeVisual> computeSankeyNodeVisuals({
  required FluentSankeyLayoutResult layout,
  required FluentChartTextMeasurer measurer,
  required TextStyle nameStyle,
  required TextStyle weightMeasurementStyle,
  required String Function(double value) formatNumber,
  required String Function(String name, String weight) nodeSemanticLabel,
}) {
  final result = <FluentSankeyNodeVisual>[];
  for (var i = 0; i < layout.nodes.length; i++) {
    final node = layout.nodes[i];
    final height = math.max(node.y1 - node.y0, 0.0);
    final actualValue = layout.nodeActualValues[i];
    final formatted = formatNumber(actualValue);
    // `:631` — 8px of left margin inside the rectangle.
    var padding = 8.0;
    var weightOffset = 0.0;
    if (height < kSankeyMinHeightForDoubleLine) {
      // `:638` — 6px of breathing room between the name and the weight.
      padding += 6;
      weightOffset = measurer.width(formatted, weightMeasurementStyle);
      padding += weightOffset;
    }
    // `:647-649` — 124 - 8 = 116 is the rectangle width the truncation works
    // against, and `truncateText` subtracts the padding from it (`:391`).
    final name = truncateSankeyText(
      layout.data.nodes[i].name,
      kSankeyNodeWidth - 8 - padding,
      measurer: measurer,
      style: nameStyle,
    );
    result.add(
      FluentSankeyNodeVisual(
        name: name,
        trimmed: name.endsWith(kSankeyEllipsis),
        height: height,
        weightOffset: weightOffset,
        // `:855` — a falsy 0 bypasses the formatter entirely.
        weightText: actualValue != 0 ? formatted : '0',
        semanticLabel: nodeSemanticLabel(layout.data.nodes[i].name, formatted),
      ),
    );
  }
  return result;
}
