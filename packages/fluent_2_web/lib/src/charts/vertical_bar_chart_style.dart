import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import 'internal/chart_colors.dart';
import 'internal/chart_text_styles.dart';

/// The visual configuration of a `FluentVerticalBarChart`.
///
/// Shaped exactly like `FluentBadgeStyle`: every visual property is a
/// [WidgetStateProperty]. Bars resolve against [WidgetState.disabled] for the
/// legend-dimmed case; the overlaid line's dots resolve against
/// [WidgetState.hovered] (or [WidgetState.focused]) for the active x value.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence: the theme-derived defaults from
/// [resolveFluentVerticalBarChartStyle], the nearest
/// [FluentVerticalBarChartTheme], then the widget's own style.
@immutable
class FluentVerticalBarChartStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentVerticalBarChartStyle({
    this.palette,
    this.singleColor,
    this.barOpacity,
    this.barCornerRadius,
    this.barLabelStyle,
    this.barLabelGapAbove,
    this.barLabelGapBelow,
    this.minBarLabelWidth,
    this.lineColor,
    this.lineLegendSwatchColor,
    this.lineStrokeWidth,
    this.lineDotRadius,
    this.lineDotFillColor,
  });

  /// The colour ramp a bar's y value is interpolated through.
  ///
  /// Defaults to the five tokens at `VerticalBarChart.tsx:306-312`, in source
  /// order. Upstream builds a `scaleLinear<string>()` over CSS
  /// custom-property *strings*, so d3 silently selects `interpolateString`
  /// rather than `interpolateRgb`; this port resolves the tokens to concrete
  /// colours first and then interpolates in sRGB, which is what the browser
  /// ends up painting anyway.
  final WidgetStateProperty<List<Color>?>? palette;

  /// Fallback used when `useSingleColor` is set and no palette was supplied —
  /// `colorPaletteBlueBackground2` (`VerticalBarChart.tsx:404`).
  final WidgetStateProperty<Color?>? singleColor;

  /// Bar fill opacity: 1 highlighted, 0.1 dimmed
  /// (`VerticalBarChart.tsx:683`).
  final WidgetStateProperty<double?>? barOpacity;

  /// Corner radius applied when `roundCorners` is set — 3
  /// (`VerticalBarChart.tsx:684`).
  final WidgetStateProperty<double?>? barCornerRadius;

  /// Bar label text style — `caption1Strong` at `colorNeutralForeground1`
  /// (`utilities/Common.styles.ts:64-70`).
  final WidgetStateProperty<TextStyle?>? barLabelStyle;

  /// Baseline offset above a positive bar — 6
  /// (`VerticalBarChart.tsx:965`).
  final WidgetStateProperty<double?>? barLabelGapAbove;

  /// Baseline offset below a negative bar — 12
  /// (`VerticalBarChart.tsx:965`).
  final WidgetStateProperty<double?>? barLabelGapBelow;

  /// Bars narrower than this carry no label — 16
  /// (`VerticalBarChart.tsx:950`).
  final WidgetStateProperty<double?>? minBarLabelWidth;

  /// Colour of the overlaid line (`VerticalBarChart.tsx:165`).
  final WidgetStateProperty<Color?>? lineColor;

  /// Colour of the line's legend swatch, which upstream resolves from a
  /// different token than the line itself (`VerticalBarChart.tsx:826`).
  /// Reproduced deliberately.
  final WidgetStateProperty<Color?>? lineLegendSwatchColor;

  /// Line stroke width — 3 (`VerticalBarChart.tsx:213`).
  final WidgetStateProperty<double?>? lineStrokeWidth;

  /// Radius of a line dot: 8 at the active x, 0.3 elsewhere so the dot stays
  /// focusable (`VerticalBarChart.tsx:278`, `:282`).
  final WidgetStateProperty<double?>? lineDotRadius;

  /// Line dot fill — `colorNeutralBackground1`
  /// (`VerticalBarChart.tsx:245`).
  final WidgetStateProperty<Color?>? lineDotFillColor;

  /// Returns a style where each of [other]'s non-null properties wins.
  FluentVerticalBarChartStyle merge(FluentVerticalBarChartStyle? other) {
    if (other == null) {
      return this;
    }
    return FluentVerticalBarChartStyle(
      palette: other.palette ?? palette,
      singleColor: other.singleColor ?? singleColor,
      barOpacity: other.barOpacity ?? barOpacity,
      barCornerRadius: other.barCornerRadius ?? barCornerRadius,
      barLabelStyle: other.barLabelStyle ?? barLabelStyle,
      barLabelGapAbove: other.barLabelGapAbove ?? barLabelGapAbove,
      barLabelGapBelow: other.barLabelGapBelow ?? barLabelGapBelow,
      minBarLabelWidth: other.minBarLabelWidth ?? minBarLabelWidth,
      lineColor: other.lineColor ?? lineColor,
      lineLegendSwatchColor:
          other.lineLegendSwatchColor ?? lineLegendSwatchColor,
      lineStrokeWidth: other.lineStrokeWidth ?? lineStrokeWidth,
      lineDotRadius: other.lineDotRadius ?? lineDotRadius,
      lineDotFillColor: other.lineDotFillColor ?? lineDotFillColor,
    );
  }

  /// Returns a copy with the given properties replaced.
  FluentVerticalBarChartStyle copyWith({
    WidgetStateProperty<List<Color>?>? palette,
    WidgetStateProperty<Color?>? singleColor,
    WidgetStateProperty<double?>? barOpacity,
    WidgetStateProperty<double?>? barCornerRadius,
    WidgetStateProperty<TextStyle?>? barLabelStyle,
    WidgetStateProperty<double?>? barLabelGapAbove,
    WidgetStateProperty<double?>? barLabelGapBelow,
    WidgetStateProperty<double?>? minBarLabelWidth,
    WidgetStateProperty<Color?>? lineColor,
    WidgetStateProperty<Color?>? lineLegendSwatchColor,
    WidgetStateProperty<double?>? lineStrokeWidth,
    WidgetStateProperty<double?>? lineDotRadius,
    WidgetStateProperty<Color?>? lineDotFillColor,
  }) => FluentVerticalBarChartStyle(
    palette: palette ?? this.palette,
    singleColor: singleColor ?? this.singleColor,
    barOpacity: barOpacity ?? this.barOpacity,
    barCornerRadius: barCornerRadius ?? this.barCornerRadius,
    barLabelStyle: barLabelStyle ?? this.barLabelStyle,
    barLabelGapAbove: barLabelGapAbove ?? this.barLabelGapAbove,
    barLabelGapBelow: barLabelGapBelow ?? this.barLabelGapBelow,
    minBarLabelWidth: minBarLabelWidth ?? this.minBarLabelWidth,
    lineColor: lineColor ?? this.lineColor,
    lineLegendSwatchColor: lineLegendSwatchColor ?? this.lineLegendSwatchColor,
    lineStrokeWidth: lineStrokeWidth ?? this.lineStrokeWidth,
    lineDotRadius: lineDotRadius ?? this.lineDotRadius,
    lineDotFillColor: lineDotFillColor ?? this.lineDotFillColor,
  );

  /// Builds a style from plain values, one value across every state.
  static FluentVerticalBarChartStyle from({
    List<Color>? palette,
    Color? singleColor,
    double? barOpacity,
    double? barCornerRadius,
    TextStyle? barLabelStyle,
    double? barLabelGapAbove,
    double? barLabelGapBelow,
    double? minBarLabelWidth,
    Color? lineColor,
    Color? lineLegendSwatchColor,
    double? lineStrokeWidth,
    double? lineDotRadius,
    Color? lineDotFillColor,
  }) => FluentVerticalBarChartStyle(
    palette: _all(palette),
    singleColor: _all(singleColor),
    barOpacity: _all(barOpacity),
    barCornerRadius: _all(barCornerRadius),
    barLabelStyle: _all(barLabelStyle),
    barLabelGapAbove: _all(barLabelGapAbove),
    barLabelGapBelow: _all(barLabelGapBelow),
    minBarLabelWidth: _all(minBarLabelWidth),
    lineColor: _all(lineColor),
    lineLegendSwatchColor: _all(lineLegendSwatchColor),
    lineStrokeWidth: _all(lineStrokeWidth),
    lineDotRadius: _all(lineDotRadius),
    lineDotFillColor: _all(lineDotFillColor),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentVerticalBarChartStyle &&
      other.palette == palette &&
      other.singleColor == singleColor &&
      other.barOpacity == barOpacity &&
      other.barCornerRadius == barCornerRadius &&
      other.barLabelStyle == barLabelStyle &&
      other.barLabelGapAbove == barLabelGapAbove &&
      other.barLabelGapBelow == barLabelGapBelow &&
      other.minBarLabelWidth == minBarLabelWidth &&
      other.lineColor == lineColor &&
      other.lineLegendSwatchColor == lineLegendSwatchColor &&
      other.lineStrokeWidth == lineStrokeWidth &&
      other.lineDotRadius == lineDotRadius &&
      other.lineDotFillColor == lineDotFillColor;

  @override
  int get hashCode => Object.hash(
    palette,
    singleColor,
    barOpacity,
    barCornerRadius,
    barLabelStyle,
    barLabelGapAbove,
    barLabelGapBelow,
    minBarLabelWidth,
    lineColor,
    lineLegendSwatchColor,
    lineStrokeWidth,
    lineDotRadius,
    lineDotFillColor,
  );
}

/// Supplies a [FluentVerticalBarChartStyle] to the subtree.
class FluentVerticalBarChartTheme extends InheritedTheme {
  /// Creates the theme.
  const FluentVerticalBarChartTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The inherited style.
  final FluentVerticalBarChartStyle style;

  /// The nearest style, or null.
  static FluentVerticalBarChartStyle? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FluentVerticalBarChartTheme>()
      ?.style;

  @override
  bool updateShouldNotify(FluentVerticalBarChartTheme oldWidget) =>
      oldWidget.style != style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentVerticalBarChartTheme(style: style, child: child);
}

/// Derives the default vertical-bar style from [theme].
FluentVerticalBarChartStyle resolveFluentVerticalBarChartStyle(
  FluentThemeData theme,
) {
  final palette = theme.colors.palette;
  final colors = FluentChartColors.of(theme);
  final textStyles = FluentChartTextStyles.of(theme);
  return FluentVerticalBarChartStyle(
    // The five tokens at VerticalBarChart.tsx:306-312, in source order.
    palette: WidgetStatePropertyAll<List<Color>?>(<Color>[
      palette.foreground2Rest(FluentPaletteFamily.blue),
      palette.foreground2Rest(FluentPaletteFamily.cornflower),
      palette.foreground2Rest(FluentPaletteFamily.darkGreen),
      palette.foreground2Rest(FluentPaletteFamily.navy),
      palette.foreground2Rest(FluentPaletteFamily.darkOrange),
    ]),
    // VerticalBarChart.tsx:404 — colorPaletteBlueBackground2.
    singleColor: WidgetStatePropertyAll<Color?>(
      palette.background2Rest(FluentPaletteFamily.blue),
    ),
    // VerticalBarChart.tsx:683 — `opacity={shouldHighlight ? 1 : 0.1}`.
    barOpacity: const WidgetStateProperty<double?>.fromMap(
      <WidgetStatesConstraint, double?>{
        WidgetState.disabled: 0.1,
        WidgetState.any: 1,
      },
    ),
    // VerticalBarChart.tsx:684 — `rx={props.roundCorners ? 3 : 0}`.
    barCornerRadius: const WidgetStatePropertyAll<double?>(3),
    barLabelStyle: WidgetStatePropertyAll<TextStyle?>(textStyles.barLabel),
    // VerticalBarChart.tsx:965 — `y={isNegativeBar ? yPoint + 12 : yPoint - 6}`.
    barLabelGapAbove: const WidgetStatePropertyAll<double?>(6),
    barLabelGapBelow: const WidgetStatePropertyAll<double?>(12),
    // VerticalBarChart.tsx:950 — `_barWidth < 16` suppresses the label.
    minBarLabelWidth: const WidgetStatePropertyAll<double?>(16),
    // parity: VerticalBarChart.tsx:165 vs :826 — the line and its legend
    // swatch resolve from two different yellow tokens. The palette maps carry
    // every yellow slot, so neither lookup can miss.
    lineColor: WidgetStatePropertyAll<Color?>(
      palette.background1Rest(FluentPaletteFamily.yellow),
    ),
    lineLegendSwatchColor: WidgetStatePropertyAll<Color?>(
      palette.foreground1Rest(FluentPaletteFamily.yellow),
    ),
    // VerticalBarChart.tsx:213 — `strokeWidth={3}` on the line path.
    lineStrokeWidth: const WidgetStatePropertyAll<double?>(3),
    // VerticalBarChart.tsx:278 and :282.
    lineDotRadius: WidgetStateProperty<double?>.fromMap(
      <WidgetStatesConstraint, double?>{
        WidgetState.hovered | WidgetState.focused: 8,
        WidgetState.any: 0.3,
      },
    ),
    // VerticalBarChart.tsx:245 — colorNeutralBackground1, which
    // FluentChartColors already resolves as the chart surface.
    lineDotFillColor: WidgetStatePropertyAll<Color?>(colors.surface),
  );
}
