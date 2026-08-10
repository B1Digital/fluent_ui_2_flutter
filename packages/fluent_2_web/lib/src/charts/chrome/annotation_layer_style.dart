import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import '../internal/chart_text_styles.dart';

/// Default opacity applied to an annotation's background.
/// `useChartAnnotationLayer.styles.ts:27`.
const double kAnnotationBackgroundOpacity = 0.8;

/// Padding inside an annotation box.
///
/// `useChartAnnotationLayer.styles.ts:102-105` sets all four sides explicitly.
/// The exported `DEFAULT_ANNOTATION_PADDING` string at `:28` is never read —
/// the class hard-codes the same numbers — so only these land.
const EdgeInsets kAnnotationPadding = EdgeInsets.symmetric(
  vertical: 4,
  horizontal: 8,
);

/// Gap between the annotation box and the start of its connector.
/// `useChartAnnotationLayer.styles.ts:29`.
const double kConnectorStartPadding = 12;

/// Gap between the connector's end and its anchor.
/// `useChartAnnotationLayer.styles.ts:30`.
const double kConnectorEndPadding = 0;

/// Connector line width. `useChartAnnotationLayer.styles.ts:31`.
const double kConnectorStrokeWidth = 2;

/// Smallest arrowhead. `ChartAnnotationLayer.tsx:30`.
const double kMinArrowSize = 6;

/// Largest arrowhead. `ChartAnnotationLayer.tsx:31`.
const double kMaxArrowSize = 24;

/// Arrowhead size as a fraction of the box's smaller side.
/// `ChartAnnotationLayer.tsx:32`.
const double kArrowSizeScale = 0.35;

/// Nesting cap in the inline markup parser. `ChartAnnotationLayer.tsx:33`.
const int kMaxSimpleMarkupDepth = 5;

/// Returns [color] carrying [opacity], or [color] unchanged when it is already
/// translucent and [preserveOriginalOpacity] holds.
///
/// Ports `applyOpacityToColor` (`useChartAnnotationLayer.styles.ts:34-59`).
/// Upstream parses a CSS string with `d3-color` and returns the input verbatim
/// when it will not parse; Dart already has a parsed [Color], so the
/// unparseable arm has no counterpart and the alpha channel is read directly.
///
/// [preserveOriginalOpacity] defaults to true, and
/// `ChartAnnotationLayer.tsx:497` passes `style.opacity == null` for it — so an
/// author who names an opacity always wins, while one who only names a
/// translucent colour keeps it.
Color? fluentApplyOpacityToColor(
  Color? color,
  double opacity, {
  bool preserveOriginalOpacity = true,
}) {
  if (color == null) {
    return null;
  }
  // useChartAnnotationLayer.styles.ts:50-55.
  if (preserveOriginalOpacity && color.a < 1) {
    return color;
  }
  // :57 — Math.max(0, Math.min(1, opacity)).
  return color.withValues(alpha: math.max(0, math.min(1, opacity)));
}

/// The visual configuration of a chart annotation layer.
@immutable
class FluentChartAnnotationLayerStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentChartAnnotationLayerStyle({
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.boxShadow,
    this.padding,
    this.textStyle,
    this.connectorStrokeColor,
    this.connectorStrokeWidth,
    this.connectorStartPadding,
    this.connectorEndPadding,
    this.focusBorderRadius,
  });

  /// Convenience for the common case of one value across every state.
  static FluentChartAnnotationLayerStyle from({
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
    EdgeInsetsGeometry? padding,
    TextStyle? textStyle,
    Color? connectorStrokeColor,
    double? connectorStrokeWidth,
    double? connectorStartPadding,
    double? connectorEndPadding,
    BorderRadius? focusBorderRadius,
  }) => FluentChartAnnotationLayerStyle(
    backgroundColor: _all(backgroundColor),
    borderColor: _all(borderColor),
    borderWidth: _all(borderWidth),
    borderRadius: _all(borderRadius),
    boxShadow: _all(boxShadow),
    padding: _all(padding),
    textStyle: _all(textStyle),
    connectorStrokeColor: _all(connectorStrokeColor),
    connectorStrokeWidth: _all(connectorStrokeWidth),
    connectorStartPadding: _all(connectorStartPadding),
    connectorEndPadding: _all(connectorEndPadding),
    focusBorderRadius: _all(focusBorderRadius),
  );

  /// Box fill, already carrying [kAnnotationBackgroundOpacity].
  final WidgetStateProperty<Color?>? backgroundColor;

  /// Box border colour.
  final WidgetStateProperty<Color?>? borderColor;

  /// Box border width.
  final WidgetStateProperty<double?>? borderWidth;

  /// Box corner radius.
  final WidgetStateProperty<BorderRadius?>? borderRadius;

  /// Box elevation.
  final WidgetStateProperty<List<BoxShadow>?>? boxShadow;

  /// Padding inside the box.
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;

  /// Annotation text style.
  final WidgetStateProperty<TextStyle?>? textStyle;

  /// Connector line colour.
  final WidgetStateProperty<Color?>? connectorStrokeColor;

  /// Connector line width.
  final WidgetStateProperty<double?>? connectorStrokeWidth;

  /// Gap between the box and the connector's start.
  final WidgetStateProperty<double?>? connectorStartPadding;

  /// Gap between the connector's end and the anchor.
  final WidgetStateProperty<double?>? connectorEndPadding;

  /// Radius the focus ring is drawn concentric to.
  final WidgetStateProperty<BorderRadius?>? focusBorderRadius;

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  /// This style with the non-null properties of [other] layered on top.
  FluentChartAnnotationLayerStyle merge(
    FluentChartAnnotationLayerStyle? other,
  ) {
    if (other == null) {
      return this;
    }
    return FluentChartAnnotationLayerStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      boxShadow: other.boxShadow ?? boxShadow,
      padding: other.padding ?? padding,
      textStyle: other.textStyle ?? textStyle,
      connectorStrokeColor: other.connectorStrokeColor ?? connectorStrokeColor,
      connectorStrokeWidth: other.connectorStrokeWidth ?? connectorStrokeWidth,
      connectorStartPadding:
          other.connectorStartPadding ?? connectorStartPadding,
      connectorEndPadding: other.connectorEndPadding ?? connectorEndPadding,
      focusBorderRadius: other.focusBorderRadius ?? focusBorderRadius,
    );
  }

  /// This style with the given properties replaced.
  FluentChartAnnotationLayerStyle copyWith({
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? borderColor,
    WidgetStateProperty<double?>? borderWidth,
    WidgetStateProperty<BorderRadius?>? borderRadius,
    WidgetStateProperty<List<BoxShadow>?>? boxShadow,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<TextStyle?>? textStyle,
    WidgetStateProperty<Color?>? connectorStrokeColor,
    WidgetStateProperty<double?>? connectorStrokeWidth,
    WidgetStateProperty<double?>? connectorStartPadding,
    WidgetStateProperty<double?>? connectorEndPadding,
    WidgetStateProperty<BorderRadius?>? focusBorderRadius,
  }) => merge(
    FluentChartAnnotationLayerStyle(
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      borderWidth: borderWidth,
      borderRadius: borderRadius,
      boxShadow: boxShadow,
      padding: padding,
      textStyle: textStyle,
      connectorStrokeColor: connectorStrokeColor,
      connectorStrokeWidth: connectorStrokeWidth,
      connectorStartPadding: connectorStartPadding,
      connectorEndPadding: connectorEndPadding,
      focusBorderRadius: focusBorderRadius,
    ),
  );

  @override
  bool operator ==(Object other) =>
      other is FluentChartAnnotationLayerStyle &&
      other.backgroundColor == backgroundColor &&
      other.borderColor == borderColor &&
      other.borderWidth == borderWidth &&
      other.borderRadius == borderRadius &&
      other.boxShadow == boxShadow &&
      other.padding == padding &&
      other.textStyle == textStyle &&
      other.connectorStrokeColor == connectorStrokeColor &&
      other.connectorStrokeWidth == connectorStrokeWidth &&
      other.connectorStartPadding == connectorStartPadding &&
      other.connectorEndPadding == connectorEndPadding &&
      other.focusBorderRadius == focusBorderRadius;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    borderColor,
    borderWidth,
    borderRadius,
    boxShadow,
    padding,
    textStyle,
    connectorStrokeColor,
    connectorStrokeWidth,
    connectorStartPadding,
    connectorEndPadding,
    focusBorderRadius,
  );
}

/// Resolves the theme-derived annotation layer defaults.
///
/// `hideDefaultStyles` selects `annotationNoDefaults`
/// (`useChartAnnotationLayer.styles.ts:129-131`), which is the base rule
/// *without* the shadow and border. That is a per-layer flag, not a style, so
/// the layer widget drops them rather than resolving a second style.
FluentChartAnnotationLayerStyle resolveFluentChartAnnotationLayerStyle(
  FluentThemeData theme,
) => FluentChartAnnotationLayerStyle(
  backgroundColor: WidgetStatePropertyAll<Color?>(
    // ChartAnnotationLayer.tsx:503.
    fluentApplyOpacityToColor(
      theme.colors.neutralBackground1,
      kAnnotationBackgroundOpacity,
    ),
  ),
  // useChartAnnotationLayer.styles.ts:127 — `1px solid colorNeutralStroke1`.
  borderColor: WidgetStatePropertyAll<Color?>(theme.colors.neutralStroke1),
  borderWidth: const WidgetStatePropertyAll<double?>(FluentStroke.thin),
  // useChartAnnotationLayer.styles.ts:106 — borderRadiusMedium.
  borderRadius: const WidgetStatePropertyAll<BorderRadius?>(
    FluentRadius.allMedium,
  ),
  // useChartAnnotationLayer.styles.ts:126 — shadow16.
  boxShadow: WidgetStatePropertyAll<List<BoxShadow>?>(
    theme.shadow(FluentElevation.shadow16),
  ),
  padding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
    kAnnotationPadding,
  ),
  // useChartAnnotationLayer.styles.ts:94 and :101 — caption1 at
  // colorNeutralForeground1, which the corpus confirms: every annotation
  // content div of `charts-linechart--line-chart-annotations-example` reports
  // `12px`/`400`, web caption1 (`typography.dart:135`). That is the
  // [FluentChartTextStyles.legendLabel] slot's value exactly; there is no
  // annotation slot, and `axisAnnotation` is the *axis* annotation
  // (caption2Strong, 10px semibold) belonging to a different upstream rule.
  textStyle: WidgetStatePropertyAll<TextStyle?>(
    FluentChartTextStyles.of(theme).legendLabel,
  ),
  // useChartAnnotationLayer.styles.ts:72.
  connectorStrokeColor: WidgetStatePropertyAll<Color?>(
    theme.colors.neutralForeground1,
  ),
  connectorStrokeWidth: const WidgetStatePropertyAll<double?>(
    kConnectorStrokeWidth,
  ),
  connectorStartPadding: const WidgetStatePropertyAll<double?>(
    kConnectorStartPadding,
  ),
  connectorEndPadding: const WidgetStatePropertyAll<double?>(
    kConnectorEndPadding,
  ),
  focusBorderRadius: const WidgetStatePropertyAll<BorderRadius?>(
    FluentRadius.allMedium,
  ),
);
