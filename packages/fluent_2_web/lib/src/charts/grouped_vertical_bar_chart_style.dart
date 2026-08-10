import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import 'internal/chart_text_styles.dart';

/// The visual configuration of a Fluent grouped vertical bar chart.
///
/// Same shape as every other chart style here: each visual property is a
/// [WidgetStateProperty], each field is nullable and means "inherit", and the
/// resolution order is [resolveFluentGroupedVerticalBarChartStyle] → the
/// nearest chart theme → the widget's own style.
///
/// Two of the properties carry both arms of an upstream ternary rather than a
/// single value, so they are the only ones a painter must resolve against a
/// real state set — see [barOpacity] and [lineDotRadius].
@immutable
class FluentGroupedVerticalBarChartStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentGroupedVerticalBarChartStyle({
    this.barOpacity,
    this.barCornerRadius,
    this.barLabelStyle,
    this.barLabelGapAbove,
    this.barLabelGapBelow,
    this.minBarLabelWidth,
    this.lineStrokeWidth,
    this.lineDotRadius,
    this.lineDotStrokeWidth,
    this.lineDotFillColor,
    this.lineBorderColor,
  });

  /// Opacity of a bar rect.
  ///
  /// `GroupedVerticalBarChart.tsx:552-553` is
  /// `isLegendActive ? '' : '0.1'` — an empty string is no `opacity`
  /// attribute at all, hence 1. The default resolves 0.1 for
  /// [WidgetState.disabled], which is how a bar dimmed by another legend's
  /// highlight is spelled here.
  final WidgetStateProperty<double?>? barOpacity;

  /// Corner radius of a bar rect when `roundCorners` is on
  /// (`GroupedVerticalBarChart.tsx:588`). Upstream's `rx` is 3, or 0 when the
  /// prop is off — the prop, not this style, chooses between them.
  final WidgetStateProperty<double?>? barCornerRadius;

  /// Text style of a bar label (`utilities/Common.styles.ts:64-70`, resolved
  /// by `FluentChartTextStyles.barLabel`).
  final WidgetStateProperty<TextStyle?>? barLabelStyle;

  /// Gap between the top of a positive bar and its label's baseline
  /// (`GroupedVerticalBarChart.tsx:607` and `:625`, both `- 6`).
  final WidgetStateProperty<double?>? barLabelGapAbove;

  /// Gap between the bottom of a negative bar and its label's baseline
  /// (`GroupedVerticalBarChart.tsx:607` and `:625`, both `+ 12`).
  final WidgetStateProperty<double?>? barLabelGapBelow;

  /// Narrowest bar that still gets a total label
  /// (`GroupedVerticalBarChart.tsx:620` — `Math.ceil(_barWidth) >= 16`).
  final WidgetStateProperty<double?>? minBarLabelWidth;

  /// Stroke width of a line series overlaid on the bars
  /// (`GroupedVerticalBarChart.tsx:852`, the fallback behind
  /// `lineOptions.strokeWidth`).
  final WidgetStateProperty<double?>? lineStrokeWidth;

  /// Radius of a line series' point marker.
  ///
  /// `GroupedVerticalBarChart.tsx:870` is
  /// `shouldHighlight && isLinePointActive ? 8 : 0.3` — the idle marker is not
  /// hidden, it is drawn sub-pixel. The default resolves 8 for
  /// [WidgetState.selected] and 0.3 otherwise.
  final WidgetStateProperty<double?>? lineDotRadius;

  /// Stroke width of a line series' point marker
  /// (`GroupedVerticalBarChart.tsx:873`).
  final WidgetStateProperty<double?>? lineDotStrokeWidth;

  /// Fill of a line series' point marker
  /// (`GroupedVerticalBarChart.tsx:871` — `colorNeutralBackground1`).
  final WidgetStateProperty<Color?>? lineDotFillColor;

  /// Colour of the halo stroked under a line series
  /// (`GroupedVerticalBarChart.tsx:836` — `colorNeutralBackground1`, behind
  /// `lineOptions.lineBorderColor`).
  final WidgetStateProperty<Color?>? lineBorderColor;

  /// This style with the non-null properties of [other] layered on top.
  FluentGroupedVerticalBarChartStyle merge(
    FluentGroupedVerticalBarChartStyle? other,
  ) {
    if (other == null) {
      return this;
    }
    return FluentGroupedVerticalBarChartStyle(
      barOpacity: other.barOpacity ?? barOpacity,
      barCornerRadius: other.barCornerRadius ?? barCornerRadius,
      barLabelStyle: other.barLabelStyle ?? barLabelStyle,
      barLabelGapAbove: other.barLabelGapAbove ?? barLabelGapAbove,
      barLabelGapBelow: other.barLabelGapBelow ?? barLabelGapBelow,
      minBarLabelWidth: other.minBarLabelWidth ?? minBarLabelWidth,
      lineStrokeWidth: other.lineStrokeWidth ?? lineStrokeWidth,
      lineDotRadius: other.lineDotRadius ?? lineDotRadius,
      lineDotStrokeWidth: other.lineDotStrokeWidth ?? lineDotStrokeWidth,
      lineDotFillColor: other.lineDotFillColor ?? lineDotFillColor,
      lineBorderColor: other.lineBorderColor ?? lineBorderColor,
    );
  }

  /// This style with the given properties replaced.
  FluentGroupedVerticalBarChartStyle copyWith({
    WidgetStateProperty<double?>? barOpacity,
    WidgetStateProperty<double?>? barCornerRadius,
    WidgetStateProperty<TextStyle?>? barLabelStyle,
    WidgetStateProperty<double?>? barLabelGapAbove,
    WidgetStateProperty<double?>? barLabelGapBelow,
    WidgetStateProperty<double?>? minBarLabelWidth,
    WidgetStateProperty<double?>? lineStrokeWidth,
    WidgetStateProperty<double?>? lineDotRadius,
    WidgetStateProperty<double?>? lineDotStrokeWidth,
    WidgetStateProperty<Color?>? lineDotFillColor,
    WidgetStateProperty<Color?>? lineBorderColor,
  }) => FluentGroupedVerticalBarChartStyle(
    barOpacity: barOpacity ?? this.barOpacity,
    barCornerRadius: barCornerRadius ?? this.barCornerRadius,
    barLabelStyle: barLabelStyle ?? this.barLabelStyle,
    barLabelGapAbove: barLabelGapAbove ?? this.barLabelGapAbove,
    barLabelGapBelow: barLabelGapBelow ?? this.barLabelGapBelow,
    minBarLabelWidth: minBarLabelWidth ?? this.minBarLabelWidth,
    lineStrokeWidth: lineStrokeWidth ?? this.lineStrokeWidth,
    lineDotRadius: lineDotRadius ?? this.lineDotRadius,
    lineDotStrokeWidth: lineDotStrokeWidth ?? this.lineDotStrokeWidth,
    lineDotFillColor: lineDotFillColor ?? this.lineDotFillColor,
    lineBorderColor: lineBorderColor ?? this.lineBorderColor,
  );

  /// Convenience for the common case of one value across every state.
  static FluentGroupedVerticalBarChartStyle from({
    double? barOpacity,
    double? barCornerRadius,
    TextStyle? barLabelStyle,
    double? barLabelGapAbove,
    double? barLabelGapBelow,
    double? minBarLabelWidth,
    double? lineStrokeWidth,
    double? lineDotRadius,
    double? lineDotStrokeWidth,
    Color? lineDotFillColor,
    Color? lineBorderColor,
  }) => FluentGroupedVerticalBarChartStyle(
    barOpacity: _all(barOpacity),
    barCornerRadius: _all(barCornerRadius),
    barLabelStyle: _all(barLabelStyle),
    barLabelGapAbove: _all(barLabelGapAbove),
    barLabelGapBelow: _all(barLabelGapBelow),
    minBarLabelWidth: _all(minBarLabelWidth),
    lineStrokeWidth: _all(lineStrokeWidth),
    lineDotRadius: _all(lineDotRadius),
    lineDotStrokeWidth: _all(lineDotStrokeWidth),
    lineDotFillColor: _all(lineDotFillColor),
    lineBorderColor: _all(lineBorderColor),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentGroupedVerticalBarChartStyle &&
      other.barOpacity == barOpacity &&
      other.barCornerRadius == barCornerRadius &&
      other.barLabelStyle == barLabelStyle &&
      other.barLabelGapAbove == barLabelGapAbove &&
      other.barLabelGapBelow == barLabelGapBelow &&
      other.minBarLabelWidth == minBarLabelWidth &&
      other.lineStrokeWidth == lineStrokeWidth &&
      other.lineDotRadius == lineDotRadius &&
      other.lineDotStrokeWidth == lineDotStrokeWidth &&
      other.lineDotFillColor == lineDotFillColor &&
      other.lineBorderColor == lineBorderColor;

  @override
  int get hashCode => Object.hash(
    barOpacity,
    barCornerRadius,
    barLabelStyle,
    barLabelGapAbove,
    barLabelGapBelow,
    minBarLabelWidth,
    lineStrokeWidth,
    lineDotRadius,
    lineDotStrokeWidth,
    lineDotFillColor,
    lineBorderColor,
  );
}

/// The derived defaults for a grouped vertical bar chart.
///
/// Every literal is transcribed from `GroupedVerticalBarChart.tsx`; the citing
/// comment on each field of [FluentGroupedVerticalBarChartStyle] is the
/// authority.
FluentGroupedVerticalBarChartStyle resolveFluentGroupedVerticalBarChartStyle(
  FluentThemeData theme,
) {
  final text = FluentChartTextStyles.of(theme);
  final background1 = theme.colors.neutralBackground1;
  return FluentGroupedVerticalBarChartStyle.from(
    // GroupedVerticalBarChart.tsx:588 — rx when roundCorners is on.
    barCornerRadius: 3,
    barLabelStyle: text.barLabel,
    // GroupedVerticalBarChart.tsx:607, :625.
    barLabelGapAbove: 6,
    barLabelGapBelow: 12,
    // GroupedVerticalBarChart.tsx:620.
    minBarLabelWidth: 16,
    // GroupedVerticalBarChart.tsx:852.
    lineStrokeWidth: 3,
    // GroupedVerticalBarChart.tsx:873.
    lineDotStrokeWidth: 3,
    // GroupedVerticalBarChart.tsx:871.
    lineDotFillColor: background1,
    // GroupedVerticalBarChart.tsx:836.
    lineBorderColor: background1,
  ).copyWith(
    // GroupedVerticalBarChart.tsx:552-553 — no attribute when active, 0.1
    // when another legend is highlighted.
    barOpacity: WidgetStateProperty.resolveWith<double?>(
      (states) => states.contains(WidgetState.disabled) ? 0.1 : 1,
    ),
    // GroupedVerticalBarChart.tsx:870 — 8 for the active point, else a 0.3
    // marker that stays in the hit path without being visible.
    lineDotRadius: WidgetStateProperty.resolveWith<double?>(
      (states) => states.contains(WidgetState.selected) ? 8 : 0.3,
    ),
  );
}
