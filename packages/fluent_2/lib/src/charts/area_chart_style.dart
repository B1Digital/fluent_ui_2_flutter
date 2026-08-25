import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import 'internal/chart_colors.dart';

/// The visual configuration of a Fluent area chart.
///
/// Shaped exactly like `FluentBadgeStyle`: every visual property is a
/// [WidgetStateProperty] so a Flutter developer already knows how to read and
/// override it, every field is nullable and means "inherit", and the resolution
/// order is derived defaults → the nearest [FluentAreaChartTheme] → the
/// widget's own style.
///
/// Three states carry meaning here, and they are the states upstream's own
/// opacity helpers branch on (`AreaChart.tsx:619-641`):
///
/// * [WidgetState.hovered] — this layer's legend is the highlighted one;
/// * [WidgetState.selected] — the popover is open;
/// * [WidgetState.disabled] — another legend owns the highlight.
@immutable
class FluentAreaChartStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentAreaChartStyle({
    this.lineStrokeWidth,
    this.areaOpacity,
    this.areaOpacityToZeroY,
    this.lineOpacityMultiStack,
    this.pointRadius,
    this.clickedPointRadius,
    this.singlePointRadius,
    this.singlePointStrokeWidth,
    this.pointStrokeWidth,
    this.activePointFillColor,
    this.hoverLineWidth,
    this.hoverLineDashPattern,
    this.hoverLineOpacity,
  });

  /// Stroke width of the line drawn along the top of each area. 3, unless the
  /// series' own `lineOptions` override it (`AreaChart.tsx:700`).
  final WidgetStateProperty<double?>? lineStrokeWidth;

  /// Fill opacity of an area. 0.7, dropping to 0.1 under
  /// [WidgetState.disabled] once another legend owns the highlight — upstream's
  /// `_getOpacity` (`AreaChart.tsx:619-626`).
  final WidgetStateProperty<double?>? areaOpacity;

  /// Element opacity of an area once the baseline is forced to zero.
  ///
  /// `layerOpacity = _shouldFillToZeroY() ? 0.8 : opacity[index]`
  /// (`AreaChart.tsx:685`), painted as the SVG `opacity` attribute over the
  /// separate `fill-opacity` of [areaOpacity] (`:731-732`).
  final WidgetStateProperty<double?>? areaOpacityToZeroY;

  /// Opacity of a layer's line while the chart is a multi-stack.
  ///
  /// Ports `_getLineOpacity` (`AreaChart.tsx:628-641`): 0.3 at rest, 1 while
  /// the popover is open ([WidgetState.selected]), and once anything is
  /// highlighted 0 for the highlighted legend ([WidgetState.hovered]) or 0.1
  /// for the others ([WidgetState.disabled]). The highlighted line is hidden
  /// deliberately — the fill carries the highlight.
  ///
  /// A single-stack chart ignores this and strokes at 1 (`:630`).
  final WidgetStateProperty<double?>? lineOpacityMultiStack;

  /// Radius of a marker circle, unless `pointOptions.r` overrides it. 8
  /// (`AreaChart.tsx:749`).
  final WidgetStateProperty<double?>? pointRadius;

  /// Radius of the nearest marker after it has been clicked. 1
  /// (`AreaChart.tsx:862`).
  final WidgetStateProperty<double?>? clickedPointRadius;

  /// Radius of the circle a one-point series is drawn as instead of an area. 6
  /// (`AreaChart.tsx:715`).
  final WidgetStateProperty<double?>? singlePointRadius;

  /// Stroke width of that one-point circle. 3 (`AreaChart.tsx:717`).
  final WidgetStateProperty<double?>? singlePointStrokeWidth;

  /// Stroke width of a marker circle. 3 (`AreaChart.tsx:780`).
  final WidgetStateProperty<double?>? pointStrokeWidth;

  /// Fill of the marker under the pointer: it inverts to the canvas colour
  /// rather than growing a ring (`AreaChart.tsx:647`,
  /// `tokens.colorNeutralBackground1`).
  final WidgetStateProperty<Color?>? activePointFillColor;

  /// Stroke width of the vertical hover rule. 1 (`AreaChart.tsx:835`).
  final WidgetStateProperty<double?>? hoverLineWidth;

  /// Dash pattern of the vertical hover rule. `strokeDasharray={5.5}` is a
  /// one-entry list, so the dash and the gap are both 5.5
  /// (`AreaChart.tsx:836`).
  final WidgetStateProperty<List<double>?>? hoverLineDashPattern;

  /// Opacity of the vertical hover rule. 0.5 (`AreaChart.tsx:838`).
  final WidgetStateProperty<double?>? hoverLineOpacity;

  /// This style with the non-null properties of [other] layered on top.
  FluentAreaChartStyle merge(FluentAreaChartStyle? other) {
    if (other == null) {
      return this;
    }
    return FluentAreaChartStyle(
      lineStrokeWidth: other.lineStrokeWidth ?? lineStrokeWidth,
      areaOpacity: other.areaOpacity ?? areaOpacity,
      areaOpacityToZeroY: other.areaOpacityToZeroY ?? areaOpacityToZeroY,
      lineOpacityMultiStack:
          other.lineOpacityMultiStack ?? lineOpacityMultiStack,
      pointRadius: other.pointRadius ?? pointRadius,
      clickedPointRadius: other.clickedPointRadius ?? clickedPointRadius,
      singlePointRadius: other.singlePointRadius ?? singlePointRadius,
      singlePointStrokeWidth:
          other.singlePointStrokeWidth ?? singlePointStrokeWidth,
      pointStrokeWidth: other.pointStrokeWidth ?? pointStrokeWidth,
      activePointFillColor: other.activePointFillColor ?? activePointFillColor,
      hoverLineWidth: other.hoverLineWidth ?? hoverLineWidth,
      hoverLineDashPattern: other.hoverLineDashPattern ?? hoverLineDashPattern,
      hoverLineOpacity: other.hoverLineOpacity ?? hoverLineOpacity,
    );
  }

  /// This style with the given properties replaced.
  FluentAreaChartStyle copyWith({
    WidgetStateProperty<double?>? lineStrokeWidth,
    WidgetStateProperty<double?>? areaOpacity,
    WidgetStateProperty<double?>? areaOpacityToZeroY,
    WidgetStateProperty<double?>? lineOpacityMultiStack,
    WidgetStateProperty<double?>? pointRadius,
    WidgetStateProperty<double?>? clickedPointRadius,
    WidgetStateProperty<double?>? singlePointRadius,
    WidgetStateProperty<double?>? singlePointStrokeWidth,
    WidgetStateProperty<double?>? pointStrokeWidth,
    WidgetStateProperty<Color?>? activePointFillColor,
    WidgetStateProperty<double?>? hoverLineWidth,
    WidgetStateProperty<List<double>?>? hoverLineDashPattern,
    WidgetStateProperty<double?>? hoverLineOpacity,
  }) => FluentAreaChartStyle(
    lineStrokeWidth: lineStrokeWidth ?? this.lineStrokeWidth,
    areaOpacity: areaOpacity ?? this.areaOpacity,
    areaOpacityToZeroY: areaOpacityToZeroY ?? this.areaOpacityToZeroY,
    lineOpacityMultiStack: lineOpacityMultiStack ?? this.lineOpacityMultiStack,
    pointRadius: pointRadius ?? this.pointRadius,
    clickedPointRadius: clickedPointRadius ?? this.clickedPointRadius,
    singlePointRadius: singlePointRadius ?? this.singlePointRadius,
    singlePointStrokeWidth:
        singlePointStrokeWidth ?? this.singlePointStrokeWidth,
    pointStrokeWidth: pointStrokeWidth ?? this.pointStrokeWidth,
    activePointFillColor: activePointFillColor ?? this.activePointFillColor,
    hoverLineWidth: hoverLineWidth ?? this.hoverLineWidth,
    hoverLineDashPattern: hoverLineDashPattern ?? this.hoverLineDashPattern,
    hoverLineOpacity: hoverLineOpacity ?? this.hoverLineOpacity,
  );

  /// Convenience for the common case of one value across every state.
  static FluentAreaChartStyle from({
    double? lineStrokeWidth,
    double? areaOpacity,
    double? areaOpacityToZeroY,
    double? lineOpacityMultiStack,
    double? pointRadius,
    double? clickedPointRadius,
    double? singlePointRadius,
    double? singlePointStrokeWidth,
    double? pointStrokeWidth,
    Color? activePointFillColor,
    double? hoverLineWidth,
    List<double>? hoverLineDashPattern,
    double? hoverLineOpacity,
  }) => FluentAreaChartStyle(
    lineStrokeWidth: _all(lineStrokeWidth),
    areaOpacity: _all(areaOpacity),
    areaOpacityToZeroY: _all(areaOpacityToZeroY),
    lineOpacityMultiStack: _all(lineOpacityMultiStack),
    pointRadius: _all(pointRadius),
    clickedPointRadius: _all(clickedPointRadius),
    singlePointRadius: _all(singlePointRadius),
    singlePointStrokeWidth: _all(singlePointStrokeWidth),
    pointStrokeWidth: _all(pointStrokeWidth),
    activePointFillColor: _all(activePointFillColor),
    hoverLineWidth: _all(hoverLineWidth),
    hoverLineDashPattern: _all(hoverLineDashPattern),
    hoverLineOpacity: _all(hoverLineOpacity),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentAreaChartStyle &&
      other.lineStrokeWidth == lineStrokeWidth &&
      other.areaOpacity == areaOpacity &&
      other.areaOpacityToZeroY == areaOpacityToZeroY &&
      other.lineOpacityMultiStack == lineOpacityMultiStack &&
      other.pointRadius == pointRadius &&
      other.clickedPointRadius == clickedPointRadius &&
      other.singlePointRadius == singlePointRadius &&
      other.singlePointStrokeWidth == singlePointStrokeWidth &&
      other.pointStrokeWidth == pointStrokeWidth &&
      other.activePointFillColor == activePointFillColor &&
      other.hoverLineWidth == hoverLineWidth &&
      other.hoverLineDashPattern == hoverLineDashPattern &&
      other.hoverLineOpacity == hoverLineOpacity;

  @override
  int get hashCode => Object.hash(
    lineStrokeWidth,
    areaOpacity,
    areaOpacityToZeroY,
    lineOpacityMultiStack,
    pointRadius,
    clickedPointRadius,
    singlePointRadius,
    singlePointStrokeWidth,
    pointStrokeWidth,
    activePointFillColor,
    hoverLineWidth,
    hoverLineDashPattern,
    hoverLineOpacity,
  );
}

/// Applies a [FluentAreaChartStyle] to every area chart below it.
class FluentAreaChartTheme extends InheritedTheme {
  /// Applies [style] to every area chart in `child`.
  const FluentAreaChartTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the derived defaults.
  final FluentAreaChartStyle style;

  /// The nearest area-chart style, or null.
  static FluentAreaChartStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentAreaChartTheme>()?.style;

  @override
  bool updateShouldNotify(FluentAreaChartTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentAreaChartTheme(style: style, child: child);
}

/// The derived defaults for an area chart, before any theme or widget
/// override.
///
/// Every literal here is transcribed from `AreaChart.tsx`; the citing comment
/// on each field of [FluentAreaChartStyle] is the authority.
FluentAreaChartStyle resolveFluentAreaChartStyle(FluentThemeData theme) {
  final colors = FluentChartColors.of(theme);
  return FluentAreaChartStyle(
    // AreaChart.tsx:700.
    lineStrokeWidth: const WidgetStatePropertyAll<double?>(3),
    // `_legendHighlighted(legend) || _noLegendHighlighted() ? 0.7 : 0.1`
    // (`AreaChart.tsx:623`).
    areaOpacity: const WidgetStateProperty<double?>.fromMap(
      <WidgetStatesConstraint, double?>{
        WidgetState.disabled: 0.1,
        WidgetState.any: 0.7,
      },
    ),
    // AreaChart.tsx:685.
    areaOpacityToZeroY: const WidgetStatePropertyAll<double?>(0.8),
    // AreaChart.tsx:632-637. The highlighted branch is checked first because
    // `:636` overwrites the popover-open value at `:634`.
    lineOpacityMultiStack: const WidgetStateProperty<double?>.fromMap(
      <WidgetStatesConstraint, double?>{
        WidgetState.hovered: 0,
        WidgetState.disabled: 0.1,
        WidgetState.selected: 1,
        WidgetState.any: 0.3,
      },
    ),
    // AreaChart.tsx:749.
    pointRadius: const WidgetStatePropertyAll<double?>(8),
    // AreaChart.tsx:862.
    clickedPointRadius: const WidgetStatePropertyAll<double?>(1),
    // AreaChart.tsx:715.
    singlePointRadius: const WidgetStatePropertyAll<double?>(6),
    // AreaChart.tsx:717.
    singlePointStrokeWidth: const WidgetStatePropertyAll<double?>(3),
    // AreaChart.tsx:780.
    pointStrokeWidth: const WidgetStatePropertyAll<double?>(3),
    // AreaChart.tsx:647 — colorNeutralBackground1, the chart's own surface.
    activePointFillColor: WidgetStatePropertyAll<Color?>(colors.surface),
    // AreaChart.tsx:835.
    hoverLineWidth: const WidgetStatePropertyAll<double?>(1),
    // AreaChart.tsx:836 — a single-entry dash array repeats as dash and gap.
    hoverLineDashPattern: const WidgetStatePropertyAll<List<double>?>(<double>[
      5.5,
    ]),
    // AreaChart.tsx:838.
    hoverLineOpacity: const WidgetStatePropertyAll<double?>(0.5),
  );
}
