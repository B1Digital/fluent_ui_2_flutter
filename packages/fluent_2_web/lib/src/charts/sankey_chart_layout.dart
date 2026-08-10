import 'dart:math' as math;

import 'package:flutter/widgets.dart';

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
