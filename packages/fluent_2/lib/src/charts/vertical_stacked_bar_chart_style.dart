import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import 'internal/chart_text_styles.dart';
import 'internal/data_viz_palette.dart';

/// The visual configuration of a vertical stacked bar chart.
///
/// Follows the `FluentBadgeStyle` template. A segment resolves against
/// [WidgetState.disabled] for the legend-dimmed case; an overlaid line's dots
/// resolve against [WidgetState.hovered] for the active x value.
///
/// Every property is nullable and means "inherit". Resolution order, lowest to
/// highest precedence: the theme-derived defaults from
/// [resolveFluentVerticalStackedBarChartStyle], the nearest chart theme, then
/// the widget's own `style`.
@immutable
class FluentVerticalStackedBarChartStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentVerticalStackedBarChartStyle({
    this.barOpacity,
    this.barCornerRadius,
    this.barMinimumHeight,
    this.barGapMax,
    this.stackCornerRadius,
    this.barLabelStyle,
    this.barLabelGapAbove,
    this.barLabelGapBelow,
    this.minBarLabelWidth,
    this.linePalette,
    this.lineStrokeWidth,
    this.lineDotRadius,
    this.lineDotStrokeWidth,
    this.lineDotFillColor,
  });

  /// Segment fill opacity: 1 highlighted, 0.1 dimmed
  /// (`VerticalStackedBarChart.tsx:1101`).
  final WidgetStateProperty<double?>? barOpacity;

  /// Corner radius of a segment rect when `roundCorners` is set — 3
  /// (`VerticalStackedBarChart.tsx:1102`, `rx = props.roundCorners ? 3 : 0`).
  final WidgetStateProperty<double?>? barCornerRadius;

  /// The floor a segment's drawn height is raised to, so a tiny value stays
  /// visible. Upstream's `barMinimumHeight` prop defaults to 0
  /// (`VerticalStackedBarChart.tsx:986`).
  final WidgetStateProperty<double?>? barMinimumHeight;

  /// Ceiling on the gap inserted between adjacent segments. Upstream's
  /// `barGapMax` prop defaults to 0, which disables gaps entirely
  /// (`VerticalStackedBarChart.tsx:815`).
  final WidgetStateProperty<double?>? barGapMax;

  /// Radius of the rounded cap drawn on the topmost segment of a stack.
  ///
  /// This is upstream's `barCornerRadius` prop, which defaults to 0
  /// (`VerticalStackedBarChart.tsx:986`) and shapes the arc path at
  /// `:1092-1098`. It is named apart from [barCornerRadius] because that one is
  /// the per-rect `rx`, a different literal on a different element.
  final WidgetStateProperty<double?>? stackCornerRadius;

  /// Stack-total label type — `caption1Strong` at `colorNeutralForeground1`
  /// (`getBarLabelStyle`, `utilities/Common.styles.ts:64-70`).
  final WidgetStateProperty<TextStyle?>? barLabelStyle;

  /// Baseline offset above a stack whose total is non-negative — 6
  /// (`VerticalStackedBarChart.tsx:1204`).
  final WidgetStateProperty<double?>? barLabelGapAbove;

  /// Baseline offset below a stack whose total is negative — 12
  /// (`VerticalStackedBarChart.tsx:1204`).
  final WidgetStateProperty<double?>? barLabelGapBelow;

  /// Stacks narrower than this carry no label — 16
  /// (`VerticalStackedBarChart.tsx:1200`).
  final WidgetStateProperty<double?>? minBarLabelWidth;

  /// The five fallback series colours, in upstream order
  /// (`VerticalStackedBarChart.tsx:316-322`).
  ///
  /// `// parity:` the order is `color6, color1, color5, color7, color10` — not
  /// the first five tokens, and not sorted.
  final WidgetStateProperty<List<Color>?>? linePalette;

  /// Stroke width of an overlaid line — 3
  /// (`VerticalStackedBarChart.tsx:617`).
  final WidgetStateProperty<double?>? lineStrokeWidth;

  /// Radius of an overlaid line's dot: 8 on the active x value, 0.3 elsewhere
  /// (`_getCircleOpacityAndRadius`, `VerticalStackedBarChart.tsx:687`, `:689`).
  ///
  /// The third arm of that function returns 0 for a dimmed dot, which is a
  /// function of the legend selection rather than of a widget state, so the
  /// delegate computes it rather than resolving it here.
  final WidgetStateProperty<double?>? lineDotRadius;

  /// Stroke width of an overlaid line's dot — 3
  /// (`VerticalStackedBarChart.tsx:649`).
  final WidgetStateProperty<double?>? lineDotStrokeWidth;

  /// Fill of an overlaid line's dot — `colorNeutralBackground1`
  /// (`VerticalStackedBarChart.tsx:648`).
  final WidgetStateProperty<Color?>? lineDotFillColor;

  /// This style with the non-null properties of [other] layered on top.
  FluentVerticalStackedBarChartStyle merge(
    FluentVerticalStackedBarChartStyle? other,
  ) {
    if (other == null) return this;
    return FluentVerticalStackedBarChartStyle(
      barOpacity: other.barOpacity ?? barOpacity,
      barCornerRadius: other.barCornerRadius ?? barCornerRadius,
      barMinimumHeight: other.barMinimumHeight ?? barMinimumHeight,
      barGapMax: other.barGapMax ?? barGapMax,
      stackCornerRadius: other.stackCornerRadius ?? stackCornerRadius,
      barLabelStyle: other.barLabelStyle ?? barLabelStyle,
      barLabelGapAbove: other.barLabelGapAbove ?? barLabelGapAbove,
      barLabelGapBelow: other.barLabelGapBelow ?? barLabelGapBelow,
      minBarLabelWidth: other.minBarLabelWidth ?? minBarLabelWidth,
      linePalette: other.linePalette ?? linePalette,
      lineStrokeWidth: other.lineStrokeWidth ?? lineStrokeWidth,
      lineDotRadius: other.lineDotRadius ?? lineDotRadius,
      lineDotStrokeWidth: other.lineDotStrokeWidth ?? lineDotStrokeWidth,
      lineDotFillColor: other.lineDotFillColor ?? lineDotFillColor,
    );
  }

  /// This style with the given properties replaced.
  FluentVerticalStackedBarChartStyle copyWith({
    WidgetStateProperty<double?>? barOpacity,
    WidgetStateProperty<double?>? barCornerRadius,
    WidgetStateProperty<double?>? barMinimumHeight,
    WidgetStateProperty<double?>? barGapMax,
    WidgetStateProperty<double?>? stackCornerRadius,
    WidgetStateProperty<TextStyle?>? barLabelStyle,
    WidgetStateProperty<double?>? barLabelGapAbove,
    WidgetStateProperty<double?>? barLabelGapBelow,
    WidgetStateProperty<double?>? minBarLabelWidth,
    WidgetStateProperty<List<Color>?>? linePalette,
    WidgetStateProperty<double?>? lineStrokeWidth,
    WidgetStateProperty<double?>? lineDotRadius,
    WidgetStateProperty<double?>? lineDotStrokeWidth,
    WidgetStateProperty<Color?>? lineDotFillColor,
  }) => FluentVerticalStackedBarChartStyle(
    barOpacity: barOpacity ?? this.barOpacity,
    barCornerRadius: barCornerRadius ?? this.barCornerRadius,
    barMinimumHeight: barMinimumHeight ?? this.barMinimumHeight,
    barGapMax: barGapMax ?? this.barGapMax,
    stackCornerRadius: stackCornerRadius ?? this.stackCornerRadius,
    barLabelStyle: barLabelStyle ?? this.barLabelStyle,
    barLabelGapAbove: barLabelGapAbove ?? this.barLabelGapAbove,
    barLabelGapBelow: barLabelGapBelow ?? this.barLabelGapBelow,
    minBarLabelWidth: minBarLabelWidth ?? this.minBarLabelWidth,
    linePalette: linePalette ?? this.linePalette,
    lineStrokeWidth: lineStrokeWidth ?? this.lineStrokeWidth,
    lineDotRadius: lineDotRadius ?? this.lineDotRadius,
    lineDotStrokeWidth: lineDotStrokeWidth ?? this.lineDotStrokeWidth,
    lineDotFillColor: lineDotFillColor ?? this.lineDotFillColor,
  );

  /// Convenience for the common case of one value across every state.
  static FluentVerticalStackedBarChartStyle from({
    double? barOpacity,
    double? barCornerRadius,
    double? barMinimumHeight,
    double? barGapMax,
    double? stackCornerRadius,
    TextStyle? barLabelStyle,
    double? barLabelGapAbove,
    double? barLabelGapBelow,
    double? minBarLabelWidth,
    List<Color>? linePalette,
    double? lineStrokeWidth,
    double? lineDotRadius,
    double? lineDotStrokeWidth,
    Color? lineDotFillColor,
  }) => FluentVerticalStackedBarChartStyle(
    barOpacity: _all(barOpacity),
    barCornerRadius: _all(barCornerRadius),
    barMinimumHeight: _all(barMinimumHeight),
    barGapMax: _all(barGapMax),
    stackCornerRadius: _all(stackCornerRadius),
    barLabelStyle: _all(barLabelStyle),
    barLabelGapAbove: _all(barLabelGapAbove),
    barLabelGapBelow: _all(barLabelGapBelow),
    minBarLabelWidth: _all(minBarLabelWidth),
    linePalette: _all(linePalette),
    lineStrokeWidth: _all(lineStrokeWidth),
    lineDotRadius: _all(lineDotRadius),
    lineDotStrokeWidth: _all(lineDotStrokeWidth),
    lineDotFillColor: _all(lineDotFillColor),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentVerticalStackedBarChartStyle &&
      other.barOpacity == barOpacity &&
      other.barCornerRadius == barCornerRadius &&
      other.barMinimumHeight == barMinimumHeight &&
      other.barGapMax == barGapMax &&
      other.stackCornerRadius == stackCornerRadius &&
      other.barLabelStyle == barLabelStyle &&
      other.barLabelGapAbove == barLabelGapAbove &&
      other.barLabelGapBelow == barLabelGapBelow &&
      other.minBarLabelWidth == minBarLabelWidth &&
      other.linePalette == linePalette &&
      other.lineStrokeWidth == lineStrokeWidth &&
      other.lineDotRadius == lineDotRadius &&
      other.lineDotStrokeWidth == lineDotStrokeWidth &&
      other.lineDotFillColor == lineDotFillColor;

  @override
  int get hashCode => Object.hash(
    barOpacity,
    barCornerRadius,
    barMinimumHeight,
    barGapMax,
    stackCornerRadius,
    barLabelStyle,
    barLabelGapAbove,
    barLabelGapBelow,
    minBarLabelWidth,
    linePalette,
    lineStrokeWidth,
    lineDotRadius,
    lineDotStrokeWidth,
    lineDotFillColor,
  );
}

/// The derived defaults for a vertical stacked bar chart.
FluentVerticalStackedBarChartStyle resolveFluentVerticalStackedBarChartStyle(
  FluentThemeData theme,
) {
  final textStyles = FluentChartTextStyles.of(theme);
  return FluentVerticalStackedBarChartStyle(
    // VerticalStackedBarChart.tsx:1101 — `opacity={shouldHighlight ? 1 : 0.1}`.
    barOpacity: const WidgetStateProperty<double?>.fromMap(
      <WidgetStatesConstraint, double?>{
        WidgetState.disabled: 0.1,
        WidgetState.any: 1,
      },
    ),
    // VerticalStackedBarChart.tsx:1102.
    barCornerRadius: const WidgetStatePropertyAll<double?>(3),
    // VerticalStackedBarChart.tsx:986 — the destructured prop defaults.
    barMinimumHeight: const WidgetStatePropertyAll<double?>(0),
    stackCornerRadius: const WidgetStatePropertyAll<double?>(0),
    // VerticalStackedBarChart.tsx:815.
    barGapMax: const WidgetStatePropertyAll<double?>(0),
    barLabelStyle: WidgetStatePropertyAll<TextStyle?>(textStyles.barLabel),
    // VerticalStackedBarChart.tsx:1204 — `yPoint - 6` and `… + 12`.
    barLabelGapAbove: const WidgetStatePropertyAll<double?>(6),
    barLabelGapBelow: const WidgetStatePropertyAll<double?>(12),
    // VerticalStackedBarChart.tsx:1200 — `_barWidth >= 16`.
    minBarLabelWidth: const WidgetStatePropertyAll<double?>(16),
    // VerticalStackedBarChart.tsx:316-322, in source order.
    linePalette: WidgetStatePropertyAll<List<Color>?>(<Color>[
      FluentDataVizPalette.resolve(FluentDataVizToken.color6),
      FluentDataVizPalette.resolve(FluentDataVizToken.color1),
      FluentDataVizPalette.resolve(FluentDataVizToken.color5),
      FluentDataVizPalette.resolve(FluentDataVizToken.color7),
      FluentDataVizPalette.resolve(FluentDataVizToken.color10),
    ]),
    // VerticalStackedBarChart.tsx:617.
    lineStrokeWidth: const WidgetStatePropertyAll<double?>(3),
    // VerticalStackedBarChart.tsx:687 and :689.
    lineDotRadius: WidgetStateProperty<double?>.fromMap(
      <WidgetStatesConstraint, double?>{
        WidgetState.hovered | WidgetState.focused: 8,
        WidgetState.any: 0.3,
      },
    ),
    // VerticalStackedBarChart.tsx:649.
    lineDotStrokeWidth: const WidgetStatePropertyAll<double?>(3),
    // VerticalStackedBarChart.tsx:648.
    lineDotFillColor: WidgetStatePropertyAll<Color?>(
      theme.colors.neutralBackground1,
    ),
  );
}
