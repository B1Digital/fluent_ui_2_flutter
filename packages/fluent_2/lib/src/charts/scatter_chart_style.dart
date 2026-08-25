import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import 'internal/chart_colors.dart';
import 'internal/chart_text_styles.dart';

/// The visual configuration of a `FluentScatterChart`.
///
/// Shaped exactly like `FluentBadgeStyle`: every visual property is a
/// [WidgetStateProperty] so a Flutter developer already knows how to read and
/// override it. A scatter marker resolves against three states —
/// [WidgetState.hovered] for the active point, [WidgetState.focused] for the
/// keyboard-focused one and [WidgetState.disabled] for a marker dimmed by a
/// legend selection.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence: the theme-derived defaults from
/// [resolveFluentScatterChartStyle], the nearest [FluentScatterChartTheme],
/// then the widget's own style.
@immutable
class FluentScatterChartStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentScatterChartStyle({
    this.markerRadius,
    this.markerOpacity,
    this.markerStrokeWidth,
    this.activeMarkerFillColor,
    this.markerLabelStyle,
    this.markerLabelGap,
    this.markerLabelMinGap,
    this.hoverLineColor,
    this.hoverLineDashPattern,
    this.hoverLineWidth,
  });

  /// Marker radius when the point carries no `markerSize`.
  ///
  /// Resolves to 4 normally and 6 when hovered, which are ScatterChart's own
  /// overrides of `calculateMarkerRadius`'s 3.5 / 5.5 defaults
  /// (`ScatterChart.tsx:427-428`).
  final WidgetStateProperty<double?>? markerRadius;

  /// Marker fill and stroke opacity. 1 when its legend is selected, 0.1
  /// otherwise (`ScatterChart.tsx:473`).
  final WidgetStateProperty<double?>? markerOpacity;

  /// Circle stroke width. Upstream sets no `stroke-width` attribute alongside
  /// its `stroke` (`ScatterChart.tsx:475`), so the SVG default of 1 applies —
  /// which is what every captured story resolves to.
  final WidgetStateProperty<double?>? markerStrokeWidth;

  /// Fill used while a marker is active — the marker inverts to the canvas
  /// colour rather than growing a ring (`ScatterChart.tsx:356-358`).
  final WidgetStateProperty<Color?>? activeMarkerFillColor;

  /// Text style for a point's `text` label (`Common.styles.ts:72-81`, body1 at
  /// `colorNeutralForeground1`, `CanvasText` under high contrast).
  final WidgetStateProperty<TextStyle?>? markerLabelStyle;

  /// Gap added to the marker radius before placing the label baseline. 12
  /// (`ScatterChart.tsx:484`).
  final WidgetStateProperty<double?>? markerLabelGap;

  /// Floor for the label offset regardless of radius. 16
  /// (`ScatterChart.tsx:484`).
  final WidgetStateProperty<double?>? markerLabelMinGap;

  /// Colour of the vertical hover rule. Upstream hard-codes `#323130` rather
  /// than reading a token (`ScatterChart.tsx:756`).
  final WidgetStateProperty<Color?>? hoverLineColor;

  /// Dash pattern of the vertical hover rule, `5,5`
  /// (`ScatterChart.tsx:759`).
  final WidgetStateProperty<List<double>?>? hoverLineDashPattern;

  /// Stroke width of the vertical hover rule. SVG default 1, since
  /// `ScatterChart.tsx:750-759` declares no `stroke-width`.
  final WidgetStateProperty<double?>? hoverLineWidth;

  /// Returns a style where each of [other]'s non-null properties wins.
  FluentScatterChartStyle merge(FluentScatterChartStyle? other) {
    if (other == null) {
      return this;
    }
    return FluentScatterChartStyle(
      markerRadius: other.markerRadius ?? markerRadius,
      markerOpacity: other.markerOpacity ?? markerOpacity,
      markerStrokeWidth: other.markerStrokeWidth ?? markerStrokeWidth,
      activeMarkerFillColor:
          other.activeMarkerFillColor ?? activeMarkerFillColor,
      markerLabelStyle: other.markerLabelStyle ?? markerLabelStyle,
      markerLabelGap: other.markerLabelGap ?? markerLabelGap,
      markerLabelMinGap: other.markerLabelMinGap ?? markerLabelMinGap,
      hoverLineColor: other.hoverLineColor ?? hoverLineColor,
      hoverLineDashPattern: other.hoverLineDashPattern ?? hoverLineDashPattern,
      hoverLineWidth: other.hoverLineWidth ?? hoverLineWidth,
    );
  }

  /// Returns a copy with the given properties replaced.
  FluentScatterChartStyle copyWith({
    WidgetStateProperty<double?>? markerRadius,
    WidgetStateProperty<double?>? markerOpacity,
    WidgetStateProperty<double?>? markerStrokeWidth,
    WidgetStateProperty<Color?>? activeMarkerFillColor,
    WidgetStateProperty<TextStyle?>? markerLabelStyle,
    WidgetStateProperty<double?>? markerLabelGap,
    WidgetStateProperty<double?>? markerLabelMinGap,
    WidgetStateProperty<Color?>? hoverLineColor,
    WidgetStateProperty<List<double>?>? hoverLineDashPattern,
    WidgetStateProperty<double?>? hoverLineWidth,
  }) => FluentScatterChartStyle(
    markerRadius: markerRadius ?? this.markerRadius,
    markerOpacity: markerOpacity ?? this.markerOpacity,
    markerStrokeWidth: markerStrokeWidth ?? this.markerStrokeWidth,
    activeMarkerFillColor: activeMarkerFillColor ?? this.activeMarkerFillColor,
    markerLabelStyle: markerLabelStyle ?? this.markerLabelStyle,
    markerLabelGap: markerLabelGap ?? this.markerLabelGap,
    markerLabelMinGap: markerLabelMinGap ?? this.markerLabelMinGap,
    hoverLineColor: hoverLineColor ?? this.hoverLineColor,
    hoverLineDashPattern: hoverLineDashPattern ?? this.hoverLineDashPattern,
    hoverLineWidth: hoverLineWidth ?? this.hoverLineWidth,
  );

  /// Builds a style from plain values, lifting each into an all-states
  /// [WidgetStateProperty].
  static FluentScatterChartStyle from({
    double? markerRadius,
    double? markerOpacity,
    double? markerStrokeWidth,
    Color? activeMarkerFillColor,
    TextStyle? markerLabelStyle,
    double? markerLabelGap,
    double? markerLabelMinGap,
    Color? hoverLineColor,
    List<double>? hoverLineDashPattern,
    double? hoverLineWidth,
  }) => FluentScatterChartStyle(
    markerRadius: _all(markerRadius),
    markerOpacity: _all(markerOpacity),
    markerStrokeWidth: _all(markerStrokeWidth),
    activeMarkerFillColor: _all(activeMarkerFillColor),
    markerLabelStyle: _all(markerLabelStyle),
    markerLabelGap: _all(markerLabelGap),
    markerLabelMinGap: _all(markerLabelMinGap),
    hoverLineColor: _all(hoverLineColor),
    hoverLineDashPattern: _all(hoverLineDashPattern),
    hoverLineWidth: _all(hoverLineWidth),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentScatterChartStyle &&
      other.markerRadius == markerRadius &&
      other.markerOpacity == markerOpacity &&
      other.markerStrokeWidth == markerStrokeWidth &&
      other.activeMarkerFillColor == activeMarkerFillColor &&
      other.markerLabelStyle == markerLabelStyle &&
      other.markerLabelGap == markerLabelGap &&
      other.markerLabelMinGap == markerLabelMinGap &&
      other.hoverLineColor == hoverLineColor &&
      other.hoverLineDashPattern == hoverLineDashPattern &&
      other.hoverLineWidth == hoverLineWidth;

  @override
  int get hashCode => Object.hash(
    markerRadius,
    markerOpacity,
    markerStrokeWidth,
    activeMarkerFillColor,
    markerLabelStyle,
    markerLabelGap,
    markerLabelMinGap,
    hoverLineColor,
    hoverLineDashPattern,
    hoverLineWidth,
  );
}

/// Supplies a [FluentScatterChartStyle] to the subtree.
class FluentScatterChartTheme extends InheritedTheme {
  /// Creates the theme.
  const FluentScatterChartTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style every descendant scatter chart inherits.
  final FluentScatterChartStyle style;

  /// The nearest style, or null.
  static FluentScatterChartStyle? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FluentScatterChartTheme>()
      ?.style;

  @override
  bool updateShouldNotify(FluentScatterChartTheme oldWidget) =>
      oldWidget.style != style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentScatterChartTheme(style: style, child: child);
}

/// Derives the default scatter style from [theme].
FluentScatterChartStyle resolveFluentScatterChartStyle(FluentThemeData theme) {
  final colors = FluentChartColors.of(theme);
  final textStyles = FluentChartTextStyles.of(theme);
  return FluentScatterChartStyle(
    // 4 normally, 6 while active (`ScatterChart.tsx:427-428`).
    markerRadius: WidgetStateProperty<double?>.fromMap(
      <WidgetStatesConstraint, double?>{
        WidgetState.hovered | WidgetState.focused: 6,
        WidgetState.any: 4,
      },
    ),
    // 0.1 once another legend owns the highlight (`ScatterChart.tsx:473`).
    markerOpacity: const WidgetStateProperty<double?>.fromMap(
      <WidgetStatesConstraint, double?>{
        WidgetState.disabled: 0.1,
        WidgetState.any: 1,
      },
    ),
    // SVG's implicit stroke-width, since upstream sets none.
    markerStrokeWidth: const WidgetStatePropertyAll<double?>(1),
    activeMarkerFillColor: WidgetStatePropertyAll<Color?>(colors.surface),
    markerLabelStyle: WidgetStatePropertyAll<TextStyle?>(
      textStyles.markerLabel,
    ),
    // `Math.max(circleRadius + 12, 16)` (`ScatterChart.tsx:484`).
    markerLabelGap: const WidgetStatePropertyAll<double?>(12),
    markerLabelMinGap: const WidgetStatePropertyAll<double?>(16),
    // parity: ScatterChart.tsx:756 hard-codes this hex rather than a token.
    hoverLineColor: const WidgetStatePropertyAll<Color?>(Color(0xFF323130)),
    hoverLineDashPattern: const WidgetStatePropertyAll<List<double>?>(<double>[
      5,
      5,
    ]),
    hoverLineWidth: const WidgetStatePropertyAll<double?>(1),
  );
}
