import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import '../internal/chart_colors.dart';
import '../internal/chart_text_styles.dart';

/// Gap above the legend strip. `useLegendsStyles.styles.ts:10`.
const double kLegendContainerMarginTop = 8;

/// Inline-start inset of the legend strip. `useLegendsStyles.styles.ts:11`.
const double kLegendContainerMarginStart = 12;

/// Padding on all four sides of a legend row. `useLegendsStyles.styles.ts:12`,
/// applied at `:55`.
const double kLegendPadding = 8;

/// Height of one legend row. `useLegendsStyles.styles.ts:13`.
///
/// Consistent with the box model: 8 padding + 16 caption1 line height + 8.
const double kLegendHeight = 32;

/// Swatch border width. `useLegendsStyles.styles.ts:14`, applied at `:82`.
const double kLegendShapeBorder = 1;

/// Swatch size as the image exporter measures it.
///
/// `useLegendsStyles.styles.ts:19` is `12 + 1`; the comment at `:16-18` says the
/// shape is grown by the whole border because an SVG stroke straddles its path,
/// so the *filled* area stays at 12.
const double kLegendShapeSize = 13;

/// Gap between the swatch and the label. `useLegendsStyles.styles.ts:20`,
/// applied at `:81` and `:85`.
const double kLegendShapeMarginEnd = 8;

/// Label opacity when a legend is filtered out. `useLegendsStyles.styles.ts:21`,
/// applied at `Legends.tsx:306`.
const double kInactiveLegendTextOpacity = 0.67;

/// Swatch opacity when a legend is filtered out **under high contrast**.
///
/// `Legends.tsx:383`. Deliberately different from
/// [kInactiveLegendTextOpacity] — 0.6 against 0.67 — and the two must not be
/// collapsed.
const double kInactiveLegendSwatchOpacityHc = 0.6;

/// On-screen footprint of a legend swatch, in logical pixels.
///
/// Both upstream render paths occupy 14: the `<svg>` viewport is 14 wide
/// (`shape.tsx:39-40`, `:46-49`) and the fallback `div` is 12 of content plus
/// two 1px borders (`useLegendsStyles.styles.ts:80-82`). Only the synthesised
/// export legend uses [kLegendShapeSize] instead
/// (`image-export-utils.ts:333-336`), which is an upstream inconsistency the
/// export path keeps rather than a value to unify.
const double kLegendSwatchBoxSize = 12 + 2 * kLegendShapeBorder;

// AUDIT CORRECTION — `kMinLegendContainerHeight` (40, `CartesianChart.tsx:54`) is
// NOT declared here. Plan 03 Task 1 declares it in
// `lib/src/charts/axis/axis_types.dart` per contract §5.1, one stage earlier.
// Declaring it here too would export the same name from two barrel-exported
// libraries. Consumers write `import '../axis/axis_types.dart';`.

/// The visual configuration of a `FluentChartLegend`.
///
/// Shaped exactly like `FluentBadgeStyle`: every visual property is a
/// [WidgetStateProperty], every field is nullable and means "inherit".
/// Resolution order, lowest to highest: theme-derived defaults, then the
/// nearest `FluentChartLegendTheme`, then the widget's own `style`.
@immutable
class FluentChartLegendStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentChartLegendStyle({
    this.swatchSize,
    this.swatchBorderWidth,
    this.swatchMarginEnd,
    this.rowPadding,
    this.rowHeight,
    this.rowBorderRadius,
    this.labelTextStyle,
    this.dimmedSwatchColor,
    this.dimmedLabelOpacity,
    this.dimmedSwatchOpacity,
    this.containerMargin,
  });

  /// Edge length of the swatch box.
  final WidgetStateProperty<double?>? swatchSize;

  /// Border width drawn around a fallback rectangular swatch.
  final WidgetStateProperty<double?>? swatchBorderWidth;

  /// Gap between swatch and label.
  final WidgetStateProperty<double?>? swatchMarginEnd;

  /// Padding inside one legend row.
  final WidgetStateProperty<EdgeInsetsGeometry?>? rowPadding;

  /// Height of one legend row.
  final WidgetStateProperty<double?>? rowHeight;

  /// Corner radius of the row, which the focus ring is drawn concentric to.
  final WidgetStateProperty<BorderRadius?>? rowBorderRadius;

  /// Label text style.
  final WidgetStateProperty<TextStyle?>? labelTextStyle;

  /// Swatch fill when the legend is filtered out.
  final WidgetStateProperty<Color?>? dimmedSwatchColor;

  /// Label opacity when the legend is filtered out.
  final WidgetStateProperty<double?>? dimmedLabelOpacity;

  /// Swatch opacity when the legend is filtered out.
  final WidgetStateProperty<double?>? dimmedSwatchOpacity;

  /// Margin around the whole legend strip.
  final WidgetStateProperty<EdgeInsetsGeometry?>? containerMargin;

  /// This style with the non-null properties of [other] layered on top.
  FluentChartLegendStyle merge(FluentChartLegendStyle? other) {
    if (other == null) return this;
    return FluentChartLegendStyle(
      swatchSize: other.swatchSize ?? swatchSize,
      swatchBorderWidth: other.swatchBorderWidth ?? swatchBorderWidth,
      swatchMarginEnd: other.swatchMarginEnd ?? swatchMarginEnd,
      rowPadding: other.rowPadding ?? rowPadding,
      rowHeight: other.rowHeight ?? rowHeight,
      rowBorderRadius: other.rowBorderRadius ?? rowBorderRadius,
      labelTextStyle: other.labelTextStyle ?? labelTextStyle,
      dimmedSwatchColor: other.dimmedSwatchColor ?? dimmedSwatchColor,
      dimmedLabelOpacity: other.dimmedLabelOpacity ?? dimmedLabelOpacity,
      dimmedSwatchOpacity: other.dimmedSwatchOpacity ?? dimmedSwatchOpacity,
      containerMargin: other.containerMargin ?? containerMargin,
    );
  }

  /// This style with the given properties replaced.
  FluentChartLegendStyle copyWith({
    WidgetStateProperty<double?>? swatchSize,
    WidgetStateProperty<double?>? swatchBorderWidth,
    WidgetStateProperty<double?>? swatchMarginEnd,
    WidgetStateProperty<EdgeInsetsGeometry?>? rowPadding,
    WidgetStateProperty<double?>? rowHeight,
    WidgetStateProperty<BorderRadius?>? rowBorderRadius,
    WidgetStateProperty<TextStyle?>? labelTextStyle,
    WidgetStateProperty<Color?>? dimmedSwatchColor,
    WidgetStateProperty<double?>? dimmedLabelOpacity,
    WidgetStateProperty<double?>? dimmedSwatchOpacity,
    WidgetStateProperty<EdgeInsetsGeometry?>? containerMargin,
  }) => FluentChartLegendStyle(
    swatchSize: swatchSize ?? this.swatchSize,
    swatchBorderWidth: swatchBorderWidth ?? this.swatchBorderWidth,
    swatchMarginEnd: swatchMarginEnd ?? this.swatchMarginEnd,
    rowPadding: rowPadding ?? this.rowPadding,
    rowHeight: rowHeight ?? this.rowHeight,
    rowBorderRadius: rowBorderRadius ?? this.rowBorderRadius,
    labelTextStyle: labelTextStyle ?? this.labelTextStyle,
    dimmedSwatchColor: dimmedSwatchColor ?? this.dimmedSwatchColor,
    dimmedLabelOpacity: dimmedLabelOpacity ?? this.dimmedLabelOpacity,
    dimmedSwatchOpacity: dimmedSwatchOpacity ?? this.dimmedSwatchOpacity,
    containerMargin: containerMargin ?? this.containerMargin,
  );

  /// Convenience for the common case of one value across every state.
  static FluentChartLegendStyle from({
    double? swatchSize,
    double? swatchBorderWidth,
    double? swatchMarginEnd,
    EdgeInsetsGeometry? rowPadding,
    double? rowHeight,
    BorderRadius? rowBorderRadius,
    TextStyle? labelTextStyle,
    Color? dimmedSwatchColor,
    double? dimmedLabelOpacity,
    double? dimmedSwatchOpacity,
    EdgeInsetsGeometry? containerMargin,
  }) => FluentChartLegendStyle(
    swatchSize: _all(swatchSize),
    swatchBorderWidth: _all(swatchBorderWidth),
    swatchMarginEnd: _all(swatchMarginEnd),
    rowPadding: _all(rowPadding),
    rowHeight: _all(rowHeight),
    rowBorderRadius: _all(rowBorderRadius),
    labelTextStyle: _all(labelTextStyle),
    dimmedSwatchColor: _all(dimmedSwatchColor),
    dimmedLabelOpacity: _all(dimmedLabelOpacity),
    dimmedSwatchOpacity: _all(dimmedSwatchOpacity),
    containerMargin: _all(containerMargin),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentChartLegendStyle &&
      other.swatchSize == swatchSize &&
      other.swatchBorderWidth == swatchBorderWidth &&
      other.swatchMarginEnd == swatchMarginEnd &&
      other.rowPadding == rowPadding &&
      other.rowHeight == rowHeight &&
      other.rowBorderRadius == rowBorderRadius &&
      other.labelTextStyle == labelTextStyle &&
      other.dimmedSwatchColor == dimmedSwatchColor &&
      other.dimmedLabelOpacity == dimmedLabelOpacity &&
      other.dimmedSwatchOpacity == dimmedSwatchOpacity &&
      other.containerMargin == containerMargin;

  @override
  int get hashCode => Object.hash(
    swatchSize,
    swatchBorderWidth,
    swatchMarginEnd,
    rowPadding,
    rowHeight,
    rowBorderRadius,
    labelTextStyle,
    dimmedSwatchColor,
    dimmedLabelOpacity,
    dimmedSwatchOpacity,
    containerMargin,
  );
}

/// Resolves the theme-derived legend defaults.
///
/// The legend deliberately does **not** collapse its palette under high
/// contrast: `Legends.tsx:382` pairs the `forced-color-adjust: none` of
/// `useLegendsStyles.styles.ts:62` with a background-image trick precisely so
/// the swatch keeps its series colour where the series marks themselves are
/// flattened by the browser (spec §5.3). Only the dim *opacity* changes there.
FluentChartLegendStyle resolveFluentChartLegendStyle(FluentThemeData theme) {
  final chartColors = FluentChartColors.of(theme);
  return FluentChartLegendStyle(
    swatchSize: const WidgetStatePropertyAll<double?>(kLegendSwatchBoxSize),
    swatchBorderWidth: const WidgetStatePropertyAll<double?>(
      kLegendShapeBorder,
    ),
    swatchMarginEnd: const WidgetStatePropertyAll<double?>(
      kLegendShapeMarginEnd,
    ),
    rowPadding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.all(kLegendPadding),
    ),
    rowHeight: const WidgetStatePropertyAll<double?>(kLegendHeight),
    // useLegendsStyles.styles.ts:54 kills the Button's own border but leaves
    // its radius; FluentFocusRing already defaults to borderRadiusMedium, which
    // is what react-tabster's ::after box uses.
    rowBorderRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allMedium,
    ),
    labelTextStyle: WidgetStatePropertyAll<TextStyle?>(
      FluentChartTextStyles.of(theme).legendLabel,
    ),
    dimmedSwatchColor: WidgetStatePropertyAll<Color?>(
      theme.colors.neutralBackground1,
    ),
    dimmedLabelOpacity: const WidgetStatePropertyAll<double?>(
      kInactiveLegendTextOpacity,
    ),
    // 1 is "no dimming": outside high contrast the swatch is dimmed by swapping
    // its fill for the page background (Legends.tsx:400, :412), not by opacity.
    dimmedSwatchOpacity: WidgetStatePropertyAll<double?>(
      chartColors.isHighContrast ? kInactiveLegendSwatchOpacityHc : 1,
    ),
    // Zero, because upstream's `fui-legend__root` rule carries no margin at
    // all: it sets `whiteSpace`, `width` and `alignItems` and nothing else
    // (`useLegendsStyles.styles.ts:40-47`). [kLegendContainerMarginTop] and
    // [kLegendContainerMarginStart] exist beside it for
    // `image-export-utils.ts:305-306`, which draws the strip into an SVG and
    // has no CSS box to inherit — `internal/image_export.dart` reads them
    // directly for the same reason.
    //
    // The gap a legend appears to have on screen belongs to whichever chart
    // mounts it, and each one differs: the cartesian shell gives 8 top / 20
    // start (`useCartesianChartStyles.styles.ts:102-105`), DonutChart and
    // HorizontalBarChart 16 top (`paddingTop: spacingVerticalL`), and Gauge,
    // Polar and Funnel none. Defaulting to the export constants charged every
    // one of them an extra 8 and 12 that upstream never applies.
    containerMargin: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.zero,
    ),
  );
}
