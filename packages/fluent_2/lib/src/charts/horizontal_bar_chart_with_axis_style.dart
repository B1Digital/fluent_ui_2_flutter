import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import 'internal/chart_text_styles.dart';

/// The visual configuration of a horizontal bar chart with an axis.
///
/// Shaped exactly like `FluentBadgeStyle`: every visual property is a
/// [WidgetStateProperty] so a Flutter developer already knows how to read and
/// override it. A bar resolves against [WidgetState.disabled], which upstream
/// spells as "some other legend owns the highlight"
/// (`HorizontalBarChartWithAxis.tsx:489`).
@immutable
class FluentHorizontalBarChartWithAxisStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentHorizontalBarChartWithAxisStyle({
    this.barHeight,
    this.maxBarHeight,
    this.yAxisPadding,
    this.segmentGap,
    this.barCornerRadius,
    this.barOpacity,
    this.barLabelStyle,
    this.barLabelInset,
    this.minBarLabelHeight,
  });

  /// Height of one bar. `props.barHeight || 32`
  /// (`HorizontalBarChartWithAxis.tsx:111`). A string y axis replaces it with
  /// the band's own share of the plot when the caller gives none (`:544`).
  final WidgetStateProperty<double?>? barHeight;

  /// Upper bound on a computed bar height. Null, because upstream caps the
  /// horizontal bar nowhere — the vertical charts' `maxBarWidth` has no
  /// counterpart here. The slot exists so a Fluent caller can impose one.
  final WidgetStateProperty<double?>? maxBarHeight;

  /// Fraction of a band left as padding between categories.
  /// `props.yAxisPadding ?? 0.5` (`HorizontalBarChartWithAxis.tsx:77`).
  final WidgetStateProperty<double?>? yAxisPadding;

  /// Gap trimmed off a stacked segment so its neighbour stays visible. The
  /// literal 2 of `gapWidthLTR` / `gapWidthRTL`
  /// (`HorizontalBarChartWithAxis.tsx:438`, `:444`).
  final WidgetStateProperty<double?>? segmentGap;

  /// Corner radius of a bar when `roundCorners` is set — `rx={3}`
  /// (`HorizontalBarChartWithAxis.tsx:479`).
  final WidgetStateProperty<double?>? barCornerRadius;

  /// Bar fill opacity: 1 while highlighted, 0.1 once another legend owns the
  /// highlight (`HorizontalBarChartWithAxis.tsx:489`).
  final WidgetStateProperty<double?>? barOpacity;

  /// Type of the group's total label — `caption1Strong` at
  /// `colorNeutralForeground1`, stroked `CanvasText` under forced colours
  /// (`useHorizontalBarChartWithAxisStyles.styles.ts:44-50`).
  final WidgetStateProperty<TextStyle?>? barLabelStyle;

  /// Distance from the bar's trailing edge to the total label, the
  /// `translate(±4)` at `HorizontalBarChartWithAxis.tsx:803`.
  final WidgetStateProperty<double?>? barLabelInset;

  /// Bar height below which the total label is dropped —
  /// `_barHeight < 16` (`HorizontalBarChartWithAxis.tsx:794`).
  final WidgetStateProperty<double?>? minBarLabelHeight;

  /// Returns a style where each of [other]'s non-null properties wins.
  FluentHorizontalBarChartWithAxisStyle merge(
    FluentHorizontalBarChartWithAxisStyle? other,
  ) {
    if (other == null) {
      return this;
    }
    return FluentHorizontalBarChartWithAxisStyle(
      barHeight: other.barHeight ?? barHeight,
      maxBarHeight: other.maxBarHeight ?? maxBarHeight,
      yAxisPadding: other.yAxisPadding ?? yAxisPadding,
      segmentGap: other.segmentGap ?? segmentGap,
      barCornerRadius: other.barCornerRadius ?? barCornerRadius,
      barOpacity: other.barOpacity ?? barOpacity,
      barLabelStyle: other.barLabelStyle ?? barLabelStyle,
      barLabelInset: other.barLabelInset ?? barLabelInset,
      minBarLabelHeight: other.minBarLabelHeight ?? minBarLabelHeight,
    );
  }

  /// Returns a copy with the given properties replaced.
  FluentHorizontalBarChartWithAxisStyle copyWith({
    WidgetStateProperty<double?>? barHeight,
    WidgetStateProperty<double?>? maxBarHeight,
    WidgetStateProperty<double?>? yAxisPadding,
    WidgetStateProperty<double?>? segmentGap,
    WidgetStateProperty<double?>? barCornerRadius,
    WidgetStateProperty<double?>? barOpacity,
    WidgetStateProperty<TextStyle?>? barLabelStyle,
    WidgetStateProperty<double?>? barLabelInset,
    WidgetStateProperty<double?>? minBarLabelHeight,
  }) => FluentHorizontalBarChartWithAxisStyle(
    barHeight: barHeight ?? this.barHeight,
    maxBarHeight: maxBarHeight ?? this.maxBarHeight,
    yAxisPadding: yAxisPadding ?? this.yAxisPadding,
    segmentGap: segmentGap ?? this.segmentGap,
    barCornerRadius: barCornerRadius ?? this.barCornerRadius,
    barOpacity: barOpacity ?? this.barOpacity,
    barLabelStyle: barLabelStyle ?? this.barLabelStyle,
    barLabelInset: barLabelInset ?? this.barLabelInset,
    minBarLabelHeight: minBarLabelHeight ?? this.minBarLabelHeight,
  );

  /// Builds a style from plain values, lifting each into an all-states
  /// [WidgetStateProperty].
  static FluentHorizontalBarChartWithAxisStyle from({
    double? barHeight,
    double? maxBarHeight,
    double? yAxisPadding,
    double? segmentGap,
    double? barCornerRadius,
    double? barOpacity,
    TextStyle? barLabelStyle,
    double? barLabelInset,
    double? minBarLabelHeight,
  }) => FluentHorizontalBarChartWithAxisStyle(
    barHeight: _all(barHeight),
    maxBarHeight: _all(maxBarHeight),
    yAxisPadding: _all(yAxisPadding),
    segmentGap: _all(segmentGap),
    barCornerRadius: _all(barCornerRadius),
    barOpacity: _all(barOpacity),
    barLabelStyle: _all(barLabelStyle),
    barLabelInset: _all(barLabelInset),
    minBarLabelHeight: _all(minBarLabelHeight),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentHorizontalBarChartWithAxisStyle &&
      other.barHeight == barHeight &&
      other.maxBarHeight == maxBarHeight &&
      other.yAxisPadding == yAxisPadding &&
      other.segmentGap == segmentGap &&
      other.barCornerRadius == barCornerRadius &&
      other.barOpacity == barOpacity &&
      other.barLabelStyle == barLabelStyle &&
      other.barLabelInset == barLabelInset &&
      other.minBarLabelHeight == minBarLabelHeight;

  @override
  int get hashCode => Object.hash(
    barHeight,
    maxBarHeight,
    yAxisPadding,
    segmentGap,
    barCornerRadius,
    barOpacity,
    barLabelStyle,
    barLabelInset,
    minBarLabelHeight,
  );
}

/// Supplies a [FluentHorizontalBarChartWithAxisStyle] to the subtree.
class FluentHorizontalBarChartWithAxisTheme extends InheritedTheme {
  /// Creates the theme.
  const FluentHorizontalBarChartWithAxisTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style every descendant horizontal bar chart with an axis inherits.
  final FluentHorizontalBarChartWithAxisStyle style;

  /// The nearest style, or null.
  static FluentHorizontalBarChartWithAxisStyle? maybeOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<
            FluentHorizontalBarChartWithAxisTheme
          >()
          ?.style;

  @override
  bool updateShouldNotify(FluentHorizontalBarChartWithAxisTheme oldWidget) =>
      oldWidget.style != style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentHorizontalBarChartWithAxisTheme(style: style, child: child);
}

/// Derives the default horizontal-bar-with-axis style from [theme].
FluentHorizontalBarChartWithAxisStyle
resolveFluentHorizontalBarChartWithAxisStyle(FluentThemeData theme) {
  final textStyles = FluentChartTextStyles.of(theme);
  return FluentHorizontalBarChartWithAxisStyle(
    // `props.barHeight || 32` (`HorizontalBarChartWithAxis.tsx:111`).
    barHeight: const WidgetStatePropertyAll<double?>(32),
    // Deliberately unset: upstream imposes no cap.
    // `props.yAxisPadding ?? 0.5` (`HorizontalBarChartWithAxis.tsx:77`).
    yAxisPadding: const WidgetStatePropertyAll<double?>(0.5),
    // The gap literal of `gapWidthLTR` (`HorizontalBarChartWithAxis.tsx:438`).
    segmentGap: const WidgetStatePropertyAll<double?>(2),
    // `rx={props.roundCorners ? 3 : 0}` (`HorizontalBarChartWithAxis.tsx:479`).
    barCornerRadius: const WidgetStatePropertyAll<double?>(3),
    // 0.1 once another legend owns the highlight
    // (`HorizontalBarChartWithAxis.tsx:489`).
    barOpacity: const WidgetStateProperty<double?>.fromMap(
      <WidgetStatesConstraint, double?>{
        WidgetState.disabled: 0.1,
        WidgetState.any: 1,
      },
    ),
    // `useHorizontalBarChartWithAxisStyles.styles.ts:44-50`.
    barLabelStyle: WidgetStatePropertyAll<TextStyle?>(textStyles.barLabel),
    // `translate(±4)` (`HorizontalBarChartWithAxis.tsx:803`).
    barLabelInset: const WidgetStatePropertyAll<double?>(4),
    // `_barHeight < 16` (`HorizontalBarChartWithAxis.tsx:794`).
    minBarLabelHeight: const WidgetStatePropertyAll<double?>(16),
  );
}
