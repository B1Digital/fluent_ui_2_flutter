import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

/// The visual configuration of a Fluent sparkline.
///
/// Shaped exactly like `FluentBadgeStyle`: every visual property is a
/// [WidgetStateProperty], every field is nullable and means "inherit", and the
/// resolution order is derived defaults → the nearest sparkline theme → the
/// widget's own style.
///
/// A sparkline is not interactive upstream — `Sparkline.tsx:88` attaches no
/// hover, click or selection handler, and the only affordance is the single tab
/// stop at `Sparkline.tsx:119` — so in practice every property resolves to one
/// value. The state-property shape is kept for consistency with the other
/// nineteen charts.
@immutable
class FluentSparklineStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentSparklineStyle({
    this.lineStrokeWidth,
    this.areaFillOpacity,
    this.topMargin,
    this.minRenderSize,
    this.labelDx,
    this.labelBaselineFromBottom,
    this.labelTextStyle,
    this.lineColor,
  });

  /// Stroke width of the line path. Upstream hard-codes 2
  /// (`Sparkline.tsx:94`).
  final WidgetStateProperty<double?>? lineStrokeWidth;

  /// Opacity of the area fill. Upstream hard-codes 0.2
  /// (`Sparkline.tsx:101`). The area is painted *after* the line, so it tints
  /// the lower half of the stroke; that order is reproduced.
  final WidgetStateProperty<double?>? areaFillOpacity;

  /// Space reserved above the plot, in logical pixels. Upstream's margin is
  /// `{top: 2, right: 0, bottom: 0, left: 0}` (`Sparkline.tsx:21-26`); only the
  /// top is non-zero, so only the top is modelled.
  final WidgetStateProperty<double?>? topMargin;

  /// Below this size the plot is not drawn at all. Upstream gates the chart
  /// svg on `width >= 50 && height >= 16` (`Sparkline.tsx:114`); the value
  /// label still renders below that threshold.
  final WidgetStateProperty<Size?>? minRenderSize;

  /// Horizontal inset of the value label from the leading edge. Upstream
  /// anchors it at `x="0%"` with `dx={8}` (`Sparkline.tsx:128`).
  final WidgetStateProperty<double?>? labelDx;

  /// Distance from the bottom edge to the value label's alphabetic baseline.
  /// Upstream is `y="100%" dy={-5}` (`Sparkline.tsx:128`), so at the default
  /// height of 20 the baseline sits at 15.
  final WidgetStateProperty<double?>? labelBaselineFromBottom;

  /// Text style of the value label. Upstream is `typographyStyles.caption1`
  /// filled with `colorNeutralForeground1`
  /// (`useSparklineStyles.styles.ts:23-27`).
  final WidgetStateProperty<TextStyle?>? labelTextStyle;

  /// Overrides the series colour for both the line and the area.
  ///
  /// Null means "use the series' own colour". Upstream has no fallback at all:
  /// `Sparkline.tsx:95` passes `data.lineChartData[0].color` straight through,
  /// so a series without a colour strokes with `undefined`. This override
  /// exists so a caller can supply one without mutating the data.
  final WidgetStateProperty<Color?>? lineColor;

  /// This style with the non-null properties of [other] layered on top.
  FluentSparklineStyle merge(FluentSparklineStyle? other) {
    if (other == null) {
      return this;
    }
    return FluentSparklineStyle(
      lineStrokeWidth: other.lineStrokeWidth ?? lineStrokeWidth,
      areaFillOpacity: other.areaFillOpacity ?? areaFillOpacity,
      topMargin: other.topMargin ?? topMargin,
      minRenderSize: other.minRenderSize ?? minRenderSize,
      labelDx: other.labelDx ?? labelDx,
      labelBaselineFromBottom:
          other.labelBaselineFromBottom ?? labelBaselineFromBottom,
      labelTextStyle: other.labelTextStyle ?? labelTextStyle,
      lineColor: other.lineColor ?? lineColor,
    );
  }

  /// This style with the given properties replaced.
  FluentSparklineStyle copyWith({
    WidgetStateProperty<double?>? lineStrokeWidth,
    WidgetStateProperty<double?>? areaFillOpacity,
    WidgetStateProperty<double?>? topMargin,
    WidgetStateProperty<Size?>? minRenderSize,
    WidgetStateProperty<double?>? labelDx,
    WidgetStateProperty<double?>? labelBaselineFromBottom,
    WidgetStateProperty<TextStyle?>? labelTextStyle,
    WidgetStateProperty<Color?>? lineColor,
  }) => FluentSparklineStyle(
    lineStrokeWidth: lineStrokeWidth ?? this.lineStrokeWidth,
    areaFillOpacity: areaFillOpacity ?? this.areaFillOpacity,
    topMargin: topMargin ?? this.topMargin,
    minRenderSize: minRenderSize ?? this.minRenderSize,
    labelDx: labelDx ?? this.labelDx,
    labelBaselineFromBottom:
        labelBaselineFromBottom ?? this.labelBaselineFromBottom,
    labelTextStyle: labelTextStyle ?? this.labelTextStyle,
    lineColor: lineColor ?? this.lineColor,
  );

  /// Convenience for the common case of one value across every state.
  static FluentSparklineStyle from({
    double? lineStrokeWidth,
    double? areaFillOpacity,
    double? topMargin,
    Size? minRenderSize,
    double? labelDx,
    double? labelBaselineFromBottom,
    TextStyle? labelTextStyle,
    Color? lineColor,
  }) => FluentSparklineStyle(
    lineStrokeWidth: _all(lineStrokeWidth),
    areaFillOpacity: _all(areaFillOpacity),
    topMargin: _all(topMargin),
    minRenderSize: _all(minRenderSize),
    labelDx: _all(labelDx),
    labelBaselineFromBottom: _all(labelBaselineFromBottom),
    labelTextStyle: _all(labelTextStyle),
    lineColor: _all(lineColor),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentSparklineStyle &&
      other.lineStrokeWidth == lineStrokeWidth &&
      other.areaFillOpacity == areaFillOpacity &&
      other.topMargin == topMargin &&
      other.minRenderSize == minRenderSize &&
      other.labelDx == labelDx &&
      other.labelBaselineFromBottom == labelBaselineFromBottom &&
      other.labelTextStyle == labelTextStyle &&
      other.lineColor == lineColor;

  @override
  int get hashCode => Object.hash(
    lineStrokeWidth,
    areaFillOpacity,
    topMargin,
    minRenderSize,
    labelDx,
    labelBaselineFromBottom,
    labelTextStyle,
    lineColor,
  );
}

/// The derived defaults for a sparkline, before any theme or widget override.
///
/// Every literal here is transcribed from `Sparkline.tsx` and
/// `useSparklineStyles.styles.ts`; the citing comment on each field of
/// [FluentSparklineStyle] is the authority.
FluentSparklineStyle resolveFluentSparklineStyle(FluentThemeData theme) =>
    FluentSparklineStyle.from(
      // Sparkline.tsx:94.
      lineStrokeWidth: 2,
      // Sparkline.tsx:101.
      areaFillOpacity: 0.2,
      // Sparkline.tsx:21-26 — margin.top.
      topMargin: 2,
      // Sparkline.tsx:114 — the render gate.
      minRenderSize: const Size(50, 16),
      // Sparkline.tsx:128 — dx.
      labelDx: 8,
      // Sparkline.tsx:128 — dy, measured up from y="100%".
      labelBaselineFromBottom: 5,
      labelTextStyle: theme.typography.caption1.copyWith(
        color: theme.colors.neutralForeground1,
      ),
    );
