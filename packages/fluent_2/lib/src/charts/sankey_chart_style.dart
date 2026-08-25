import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import 'internal/chart_text_styles.dart';
import 'sankey_chart_layout.dart';

/// The visual configuration of a Sankey chart.
///
/// Every visual property is a [WidgetStateProperty], so a Flutter developer
/// already knows how to read and override it. Every field is nullable and means
/// "inherit". Resolution order, lowest to highest precedence: the theme-derived
/// defaults from [resolveFluentSankeyChartStyle], the nearest
/// [FluentSankeyChartTheme], then the widget's own style.
@immutable
class FluentSankeyChartStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentSankeyChartStyle({
    this.linkFillColor,
    this.linkStrokeWidth,
    this.nodeStrokeWidth,
    this.nonSelectedColor,
    this.nodeTextColor,
    this.nonSelectedNodeTextColor,
    this.nameTextStyle,
    this.weightTextStyle,
    this.weightMeasurementTextStyle,
    this.titleTextStyle,
    this.titleBackgroundColor,
    this.tooltipTextStyle,
    this.tooltipBackgroundColor,
  });

  /// Fill of a stream while nothing is selected — `colorNeutralBackground1`
  /// (`useSankeyChartStyles.styles.ts:32`).
  ///
  /// The `fill` attribute at `SankeyChart.tsx:762` is `_fillStreamColors`,
  /// which returns undefined outside the selected state
  /// (`SankeyChart.tsx:946-950`), so the group's class wins.
  final WidgetStateProperty<Color?>? linkFillColor;

  /// Stroke width of a stream's border — 2.
  ///
  /// The `strokeWidth="2"` presentation attribute (`SankeyChart.tsx:764`)
  /// overrides the `strokeWidth: '3px'` of the class
  /// (`useSankeyChartStyles.styles.ts:33`).
  final WidgetStateProperty<double?>? linkStrokeWidth;

  /// Stroke width of a node's border — 2 (`SankeyChart.tsx:817`).
  final WidgetStateProperty<double?>? nodeStrokeWidth;

  /// Colour of every node and stream that a selection has greyed out —
  /// `#757575` (`SankeyChart.tsx:40`).
  final WidgetStateProperty<Color?>? nonSelectedColor;

  /// Colour of the name and weight drawn on a node in the default and selected
  /// states — white (`SankeyChart.tsx:61`).
  ///
  /// See [kSankeyNonSelectedTextColor] for why the upstream constant names read
  /// backwards from the states they serve.
  final WidgetStateProperty<Color?>? nodeTextColor;

  /// Colour of the text on a node that a selection has greyed out — `#323130`
  /// (`SankeyChart.tsx:60`).
  final WidgetStateProperty<Color?>? nonSelectedNodeTextColor;

  /// Type of a node's name — 10px at normal weight
  /// (`SankeyChart.tsx:833, 836`).
  ///
  /// `fontWeight="regular"` is not a valid CSS keyword, so the browser
  /// discards it and the text renders at the inherited normal weight.
  final WidgetStateProperty<TextStyle?>? nameTextStyle;

  /// Type of a node's weight — 14px bold (`SankeyChart.tsx:850, 853`).
  final WidgetStateProperty<TextStyle?>? weightTextStyle;

  /// Type the weight is *measured* in while the name budget is computed —
  /// body1 at normal weight (`SankeyChart.tsx:622`).
  ///
  /// `// parity:` upstream appends the measurement `tspan` with no font
  /// override, so it inherits the root's body1 while the painted weight is
  /// 14px bold. The measurement therefore under-reports and every short node's
  /// name budget is a few pixels too generous. Kept, so the port lays out the
  /// same text as upstream.
  final WidgetStateProperty<TextStyle?>? weightMeasurementTextStyle;

  /// Type of the chart title — `getChartTitleStyles()`
  /// (`useSankeyChartStyles.styles.ts:63`, `utilities/Common.styles.ts:83-91`).
  final WidgetStateProperty<TextStyle?>? titleTextStyle;

  /// Fill of the backing rectangle behind a truncated title's tooltip —
  /// `colorNeutralBackground1` (`useSankeyChartStyles.styles.ts:64-65`, the
  /// `svgTooltip` slot handed to `ChartTitle` at `SankeyChart.tsx:1166`).
  final WidgetStateProperty<Color?>? titleBackgroundColor;

  /// Type of the node-name tooltip — `getTooltipStyle()`
  /// (`useSankeyChartStyles.styles.ts:44`, `utilities/Common.styles.ts:36-49`).
  final WidgetStateProperty<TextStyle?>? tooltipTextStyle;

  /// Background of the node-name tooltip — `colorNeutralBackground1`
  /// (`utilities/Common.styles.ts:44`).
  final WidgetStateProperty<Color?>? tooltipBackgroundColor;

  /// This style with the non-null properties of [other] layered on top.
  FluentSankeyChartStyle merge(FluentSankeyChartStyle? other) {
    if (other == null) {
      return this;
    }
    return FluentSankeyChartStyle(
      linkFillColor: other.linkFillColor ?? linkFillColor,
      linkStrokeWidth: other.linkStrokeWidth ?? linkStrokeWidth,
      nodeStrokeWidth: other.nodeStrokeWidth ?? nodeStrokeWidth,
      nonSelectedColor: other.nonSelectedColor ?? nonSelectedColor,
      nodeTextColor: other.nodeTextColor ?? nodeTextColor,
      nonSelectedNodeTextColor:
          other.nonSelectedNodeTextColor ?? nonSelectedNodeTextColor,
      nameTextStyle: other.nameTextStyle ?? nameTextStyle,
      weightTextStyle: other.weightTextStyle ?? weightTextStyle,
      weightMeasurementTextStyle:
          other.weightMeasurementTextStyle ?? weightMeasurementTextStyle,
      titleTextStyle: other.titleTextStyle ?? titleTextStyle,
      titleBackgroundColor: other.titleBackgroundColor ?? titleBackgroundColor,
      tooltipTextStyle: other.tooltipTextStyle ?? tooltipTextStyle,
      tooltipBackgroundColor:
          other.tooltipBackgroundColor ?? tooltipBackgroundColor,
    );
  }

  /// This style with the given properties replaced.
  FluentSankeyChartStyle copyWith({
    WidgetStateProperty<Color?>? linkFillColor,
    WidgetStateProperty<double?>? linkStrokeWidth,
    WidgetStateProperty<double?>? nodeStrokeWidth,
    WidgetStateProperty<Color?>? nonSelectedColor,
    WidgetStateProperty<Color?>? nodeTextColor,
    WidgetStateProperty<Color?>? nonSelectedNodeTextColor,
    WidgetStateProperty<TextStyle?>? nameTextStyle,
    WidgetStateProperty<TextStyle?>? weightTextStyle,
    WidgetStateProperty<TextStyle?>? weightMeasurementTextStyle,
    WidgetStateProperty<TextStyle?>? titleTextStyle,
    WidgetStateProperty<Color?>? titleBackgroundColor,
    WidgetStateProperty<TextStyle?>? tooltipTextStyle,
    WidgetStateProperty<Color?>? tooltipBackgroundColor,
  }) => FluentSankeyChartStyle(
    linkFillColor: linkFillColor ?? this.linkFillColor,
    linkStrokeWidth: linkStrokeWidth ?? this.linkStrokeWidth,
    nodeStrokeWidth: nodeStrokeWidth ?? this.nodeStrokeWidth,
    nonSelectedColor: nonSelectedColor ?? this.nonSelectedColor,
    nodeTextColor: nodeTextColor ?? this.nodeTextColor,
    nonSelectedNodeTextColor:
        nonSelectedNodeTextColor ?? this.nonSelectedNodeTextColor,
    nameTextStyle: nameTextStyle ?? this.nameTextStyle,
    weightTextStyle: weightTextStyle ?? this.weightTextStyle,
    weightMeasurementTextStyle:
        weightMeasurementTextStyle ?? this.weightMeasurementTextStyle,
    titleTextStyle: titleTextStyle ?? this.titleTextStyle,
    titleBackgroundColor: titleBackgroundColor ?? this.titleBackgroundColor,
    tooltipTextStyle: tooltipTextStyle ?? this.tooltipTextStyle,
    tooltipBackgroundColor:
        tooltipBackgroundColor ?? this.tooltipBackgroundColor,
  );

  /// Convenience for the common case of one value across every state.
  static FluentSankeyChartStyle from({
    Color? linkFillColor,
    double? linkStrokeWidth,
    double? nodeStrokeWidth,
    Color? nonSelectedColor,
    Color? nodeTextColor,
    Color? nonSelectedNodeTextColor,
    TextStyle? nameTextStyle,
    TextStyle? weightTextStyle,
    TextStyle? weightMeasurementTextStyle,
    TextStyle? titleTextStyle,
    Color? titleBackgroundColor,
    TextStyle? tooltipTextStyle,
    Color? tooltipBackgroundColor,
  }) => FluentSankeyChartStyle(
    linkFillColor: _all(linkFillColor),
    linkStrokeWidth: _all(linkStrokeWidth),
    nodeStrokeWidth: _all(nodeStrokeWidth),
    nonSelectedColor: _all(nonSelectedColor),
    nodeTextColor: _all(nodeTextColor),
    nonSelectedNodeTextColor: _all(nonSelectedNodeTextColor),
    nameTextStyle: _all(nameTextStyle),
    weightTextStyle: _all(weightTextStyle),
    weightMeasurementTextStyle: _all(weightMeasurementTextStyle),
    titleTextStyle: _all(titleTextStyle),
    titleBackgroundColor: _all(titleBackgroundColor),
    tooltipTextStyle: _all(tooltipTextStyle),
    tooltipBackgroundColor: _all(tooltipBackgroundColor),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentSankeyChartStyle &&
      other.linkFillColor == linkFillColor &&
      other.linkStrokeWidth == linkStrokeWidth &&
      other.nodeStrokeWidth == nodeStrokeWidth &&
      other.nonSelectedColor == nonSelectedColor &&
      other.nodeTextColor == nodeTextColor &&
      other.nonSelectedNodeTextColor == nonSelectedNodeTextColor &&
      other.nameTextStyle == nameTextStyle &&
      other.weightTextStyle == weightTextStyle &&
      other.weightMeasurementTextStyle == weightMeasurementTextStyle &&
      other.titleTextStyle == titleTextStyle &&
      other.titleBackgroundColor == titleBackgroundColor &&
      other.tooltipTextStyle == tooltipTextStyle &&
      other.tooltipBackgroundColor == tooltipBackgroundColor;

  @override
  int get hashCode => Object.hash(
    linkFillColor,
    linkStrokeWidth,
    nodeStrokeWidth,
    nonSelectedColor,
    nodeTextColor,
    nonSelectedNodeTextColor,
    nameTextStyle,
    weightTextStyle,
    weightMeasurementTextStyle,
    titleTextStyle,
    titleBackgroundColor,
    tooltipTextStyle,
    tooltipBackgroundColor,
  );
}

/// Supplies a [FluentSankeyChartStyle] to the subtree.
class FluentSankeyChartTheme extends InheritedTheme {
  /// Creates the theme.
  const FluentSankeyChartTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style every descendant Sankey chart inherits.
  final FluentSankeyChartStyle style;

  /// The nearest style, or null.
  static FluentSankeyChartStyle? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FluentSankeyChartTheme>()
      ?.style;

  @override
  bool updateShouldNotify(FluentSankeyChartTheme oldWidget) =>
      oldWidget.style != style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentSankeyChartTheme(style: style, child: child);
}

/// The defaults derived from [theme], before any theme or widget override.
///
/// Transcribes `useSankeyChartStyles.styles.ts:31-65`, the inline presentation
/// attributes at `SankeyChart.tsx:764`, `:817` and `:826-856`, and the tooltip
/// rule at `utilities/Common.styles.ts:36-49`.
FluentSankeyChartStyle resolveFluentSankeyChartStyle(FluentThemeData theme) {
  final text = FluentChartTextStyles.of(theme);
  final body = theme.typography.body1;
  return FluentSankeyChartStyle.from(
    // `useSankeyChartStyles.styles.ts:32` — the stream fill is inherited from
    // the group, because `_fillStreamColors` (`SankeyChart.tsx:946-950`)
    // returns undefined in the default state.
    linkFillColor: theme.colors.neutralBackground1,
    linkStrokeWidth: kSankeyLinkStrokeWidth,
    nodeStrokeWidth: kSankeyNodeStrokeWidth,
    nonSelectedColor: kSankeyNonSelectedColor,
    nodeTextColor: kSankeyNonSelectedTextColor,
    nonSelectedNodeTextColor: kSankeyDefaultTextColor,
    // `SankeyChart.tsx:836` — 10px, and `:833`'s invalid "regular" resolves to
    // normal.
    nameTextStyle: body.copyWith(fontSize: 10, fontWeight: FontWeight.normal),
    // `SankeyChart.tsx:850, 853` — 14px bold.
    weightTextStyle: body.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
    // `SankeyChart.tsx:622` — measured with NO font override, so body1 regular.
    weightMeasurementTextStyle: body,
    titleTextStyle: text.chartTitle,
    titleBackgroundColor: theme.colors.neutralBackground1,
    tooltipTextStyle: text.tooltip,
    tooltipBackgroundColor: theme.colors.neutralBackground1,
  );
}
