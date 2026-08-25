import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

/// The visual configuration of a Gantt chart.
///
/// `useGanttChartStyles` (`useGanttChartStyles.styles.ts`) is inert upstream —
/// every class name it returns resolves to the empty string — so nothing here
/// is inherited from it. Every literal below is a constant in
/// `GanttChart.tsx` itself.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence: the derived defaults from
/// [resolveFluentGanttChartStyle], the nearest chart theme, then the widget's
/// own `style`.
@immutable
class FluentGanttChartStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentGanttChartStyle({
    this.barHeight,
    this.maxBarHeight,
    this.minBarHeight,
    this.minBarWidth,
    this.barCornerRadius,
    this.barOpacity,
    this.yAxisPadding,
  });

  /// An explicit bar height, replacing the solved one outright.
  ///
  /// `GanttChart.tsx:336-340` takes `props.barHeight` only when it is a
  /// number, so the resolved default leaves this null and the auto solve runs.
  final WidgetStateProperty<double?>? barHeight;

  /// The ceiling every bar height is clamped to — 24
  /// (`GanttChart.tsx:41`, defaulted again at `:45`).
  final WidgetStateProperty<double?>? maxBarHeight;

  /// The floor every bar height is clamped to — `MIN_BAR_HEIGHT`, 1
  /// (`GanttChart.tsx:42`).
  final WidgetStateProperty<double?>? minBarHeight;

  /// The width a zero-length span still paints — 2
  /// (`GanttChart.tsx:417`).
  final WidgetStateProperty<double?>? minBarWidth;

  /// The corner radius of a rounded bar — 3 (`GanttChart.tsx:419`).
  final WidgetStateProperty<double?>? barCornerRadius;

  /// A bar's opacity: 1 highlighted, 0.1 dimmed (`GanttChart.tsx:421`).
  ///
  /// The dimmed value is keyed on [WidgetState.disabled], which is the state a
  /// legend filter puts a series into.
  final WidgetStateProperty<double?>? barOpacity;

  /// The band padding of a category y axis — `1 / 2` (`GanttChart.tsx:117`).
  final WidgetStateProperty<double?>? yAxisPadding;

  /// This style with the non-null properties of [other] layered on top.
  FluentGanttChartStyle merge(FluentGanttChartStyle? other) {
    if (other == null) return this;
    return FluentGanttChartStyle(
      barHeight: other.barHeight ?? barHeight,
      maxBarHeight: other.maxBarHeight ?? maxBarHeight,
      minBarHeight: other.minBarHeight ?? minBarHeight,
      minBarWidth: other.minBarWidth ?? minBarWidth,
      barCornerRadius: other.barCornerRadius ?? barCornerRadius,
      barOpacity: other.barOpacity ?? barOpacity,
      yAxisPadding: other.yAxisPadding ?? yAxisPadding,
    );
  }

  /// This style with the given properties replaced.
  FluentGanttChartStyle copyWith({
    WidgetStateProperty<double?>? barHeight,
    WidgetStateProperty<double?>? maxBarHeight,
    WidgetStateProperty<double?>? minBarHeight,
    WidgetStateProperty<double?>? minBarWidth,
    WidgetStateProperty<double?>? barCornerRadius,
    WidgetStateProperty<double?>? barOpacity,
    WidgetStateProperty<double?>? yAxisPadding,
  }) => FluentGanttChartStyle(
    barHeight: barHeight ?? this.barHeight,
    maxBarHeight: maxBarHeight ?? this.maxBarHeight,
    minBarHeight: minBarHeight ?? this.minBarHeight,
    minBarWidth: minBarWidth ?? this.minBarWidth,
    barCornerRadius: barCornerRadius ?? this.barCornerRadius,
    barOpacity: barOpacity ?? this.barOpacity,
    yAxisPadding: yAxisPadding ?? this.yAxisPadding,
  );

  /// Convenience for the common case of one value across every state.
  static FluentGanttChartStyle from({
    double? barHeight,
    double? maxBarHeight,
    double? minBarHeight,
    double? minBarWidth,
    double? barCornerRadius,
    double? barOpacity,
    double? yAxisPadding,
  }) => FluentGanttChartStyle(
    barHeight: _all(barHeight),
    maxBarHeight: _all(maxBarHeight),
    minBarHeight: _all(minBarHeight),
    minBarWidth: _all(minBarWidth),
    barCornerRadius: _all(barCornerRadius),
    barOpacity: _all(barOpacity),
    yAxisPadding: _all(yAxisPadding),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentGanttChartStyle &&
      other.barHeight == barHeight &&
      other.maxBarHeight == maxBarHeight &&
      other.minBarHeight == minBarHeight &&
      other.minBarWidth == minBarWidth &&
      other.barCornerRadius == barCornerRadius &&
      other.barOpacity == barOpacity &&
      other.yAxisPadding == yAxisPadding;

  @override
  int get hashCode => Object.hash(
    barHeight,
    maxBarHeight,
    minBarHeight,
    minBarWidth,
    barCornerRadius,
    barOpacity,
    yAxisPadding,
  );
}

/// The derived defaults for a Gantt chart.
///
/// // ponytail: [theme] is taken for signature parity with every other
/// `resolveFluentXStyle`, and is genuinely unread — a Gantt bar carries no
/// text and no chrome colour of its own, and its fill comes from the data
/// point or from the shared data-visualisation palette.
FluentGanttChartStyle resolveFluentGanttChartStyle(FluentThemeData theme) =>
    FluentGanttChartStyle.from(
      // GanttChart.tsx:41 and :45 — DEFAULT_BAR_HEIGHT doubles as the ceiling.
      maxBarHeight: 24,
      // GanttChart.tsx:42 — MIN_BAR_HEIGHT.
      minBarHeight: 1,
      // GanttChart.tsx:417 — Math.max(|end - start|, 2).
      minBarWidth: 2,
      // GanttChart.tsx:419 — rx={props.roundCorners ? 3 : 0}.
      barCornerRadius: 3,
      // GanttChart.tsx:117 — getScalePadding(props.yAxisPadding, undefined, 1/2).
      yAxisPadding: 0.5,
    ).copyWith(
      // GanttChart.tsx:421 — opacity={shouldHighlight ? 1 : 0.1}.
      barOpacity: const WidgetStateProperty<double?>.fromMap(
        <WidgetStatesConstraint, double?>{
          WidgetState.disabled: 0.1,
          WidgetState.any: 1,
        },
      ),
    );
