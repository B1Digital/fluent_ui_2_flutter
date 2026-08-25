import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import 'internal/chart_text_styles.dart';

/// The visual configuration of a Fluent donut chart.
///
/// Shaped exactly like `FluentBadgeStyle`: every visual property is a
/// [WidgetStateProperty], every field is nullable and means "inherit", and the
/// resolution order is derived defaults → the nearest donut chart theme → the
/// widget's own style.
///
/// Upstream splits these literals across four files — `DonutChart.tsx` sizes
/// the plot, `Pie.tsx` lays the slices out, `Arc.tsx` draws one, and
/// `useArcStyles.styles.ts` paints it — so each field carries the rule it came
/// from.
@immutable
class FluentDonutChartStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentDonutChartStyle({
    this.arcStrokeWidth,
    this.focusRingWidth,
    this.dimmedOpacity,
    this.padAngle,
    this.cornerRadius,
    this.labelMarginHorizontal,
    this.labelMarginVertical,
    this.labelRadiusOffset,
    this.minLabelSweep,
    this.centreTextPadding,
    this.centreTextBaselineOffset,
    this.titleHeightMin,
    this.titleFontFallbackSize,
    this.legendGap,
    this.minDonutRadius,
    this.arcStrokeColor,
    this.focusRingColor,
    this.arcLabelTextStyle,
    this.centreValueTextStyle,
    this.titleTextStyle,
    this.titleBackgroundColor,
  });

  /// Width of the outline that separates one slice from its neighbour.
  ///
  /// `useArcStyles.styles.ts:22-31` declares a `stroke` but no `stroke-width`,
  /// so SVG's default of 1 applies.
  final WidgetStateProperty<double?>? arcStrokeWidth;

  /// Width of the keyboard focus ring drawn over the focused slice.
  ///
  /// `useArcStyles.styles.ts:34` — `strokeWidthThickest`, which is 4.
  final WidgetStateProperty<double?>? focusRingWidth;

  /// Opacity of a slice that a legend selection has left unhighlighted.
  ///
  /// `Arc.tsx:112-113`.
  final WidgetStateProperty<double?>? dimmedOpacity;

  /// Angular padding between slices, in radians.
  ///
  /// `Pie.tsx:98` — `.padAngle(0.02)` on the layout.
  final WidgetStateProperty<double?>? padAngle;

  /// Corner radius of a slice.
  ///
  /// Always 0. `DonutChart.types.ts:129` and `Arc.types.ts:112` declare a
  /// `roundCorners` prop, but neither `DonutChart` nor `Pie` forwards it, so
  /// `Arc.tsx:114` evaluates `props.roundCorners ? 3 : 0` against undefined on
  /// every render. The field exists so the dead prop stays visible rather than
  /// becoming a hard-coded zero somewhere in the painter.
  final WidgetStateProperty<double?>? cornerRadius;

  /// Horizontal space reserved for the arc labels, total across both sides.
  ///
  /// `DonutChart.tsx:332` — 80 when labels are shown, 0 when hidden.
  final WidgetStateProperty<double?>? labelMarginHorizontal;

  /// Vertical space reserved for the arc labels, total across both edges.
  ///
  /// `DonutChart.tsx:333` — 40 when labels are shown, 0 when hidden.
  final WidgetStateProperty<double?>? labelMarginVertical;

  /// How far outside the larger radius an arc label is placed.
  ///
  /// `Arc.tsx:79` — `max(innerRadius, outerRadius) + 2`.
  final WidgetStateProperty<double?>? labelRadiusOffset;

  /// The sweep, in radians, below which a slice's label is suppressed.
  ///
  /// `Arc.tsx:71` — under `PI / 12`, i.e. 15 degrees, no label is drawn.
  final WidgetStateProperty<double?>? minLabelSweep;

  /// Padding subtracted from the hole's diameter when wrapping the centre
  /// value.
  ///
  /// `Pie.tsx:24` wraps at `innerRadius * 2 - TEXT_PADDING`, and `TEXT_PADDING`
  /// is 5 (`Pie.tsx:14`).
  final WidgetStateProperty<double?>? centreTextPadding;

  /// Offset of the centre value's `dominant-baseline: middle` box below the
  /// centre of the donut.
  ///
  /// `Pie.tsx:107` — `y={5}`.
  final WidgetStateProperty<double?>? centreTextBaselineOffset;

  /// Floor on the vertical space a chart title occupies.
  ///
  /// `DonutChart.tsx:276-284` — `max(titleFontSize + CHART_TITLE_PADDING, 36)`.
  final WidgetStateProperty<double?>? titleHeightMin;

  /// The title font size assumed when the caller's title font declares none.
  ///
  /// `DonutChart.tsx:279` falls back to 13 when `titleFont.size` is not a
  /// number.
  final WidgetStateProperty<double?>? titleFontFallbackSize;

  /// Space between the donut and the legend below it.
  ///
  /// `useDonutChartStyles.styles.ts:42-45` — the legend container's
  /// `paddingTop: spacingVerticalL`, which is 16.
  final WidgetStateProperty<double?>? legendGap;

  /// The inner radius above which a centre value is shown at all.
  ///
  /// `utilities.ts:90` declares `MIN_DONUT_RADIUS = 1`, and
  /// `DonutChart.tsx:337-338` renders the centre value only when the inner
  /// radius exceeds it.
  final WidgetStateProperty<double?>? minDonutRadius;

  /// Colour of the outline between slices.
  ///
  /// `useArcStyles.styles.ts:25` — `colorNeutralBackground1`, so the gap reads
  /// as the page showing through rather than as a drawn line.
  final WidgetStateProperty<Color?>? arcStrokeColor;

  /// Colour of the keyboard focus ring.
  ///
  /// `useArcStyles.styles.ts:33` — `colorStrokeFocus2`.
  final WidgetStateProperty<Color?>? focusRingColor;

  /// Text style of the value drawn beside a slice.
  ///
  /// `useArcStyles.styles.ts:37-43` — `caption1Strong` filled with
  /// `colorNeutralForeground1`.
  final WidgetStateProperty<TextStyle?>? arcLabelTextStyle;

  /// Text style of the value drawn in the hole.
  ///
  /// `usePieStyles.styles.ts:22-26` — `title2`, which is 28/36 semibold,
  /// filled with `colorNeutralForeground1`.
  final WidgetStateProperty<TextStyle?>? centreValueTextStyle;

  /// Text style of the chart title.
  ///
  /// `useDonutChartStyles.styles.ts:47` — `getChartTitleStyles()`, which
  /// `FluentChartTextStyles.chartTitle` already resolves.
  final WidgetStateProperty<TextStyle?>? titleTextStyle;

  /// Fill of the rectangle `SVGTooltipText` paints behind the chart title.
  ///
  /// `useDonutChartStyles.styles.ts:48-53` — the `svgTooltip` slot, which
  /// `DonutChart.tsx:368` hands `ChartTitle` as its `tooltipClassName`, is
  /// `colorNeutralBackground1`. The Oracle B capture of
  /// `charts-donutchart--donut-chart-basic` records that rect as
  /// `rgb(255, 255, 255)` at y=-13, so it is drawn on every render and not
  /// only under a tooltip.
  final WidgetStateProperty<Color?>? titleBackgroundColor;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only [padAngle] keeps
  /// every resolved colour.
  FluentDonutChartStyle merge(FluentDonutChartStyle? other) {
    if (other == null) return this;
    return FluentDonutChartStyle(
      arcStrokeWidth: other.arcStrokeWidth ?? arcStrokeWidth,
      focusRingWidth: other.focusRingWidth ?? focusRingWidth,
      dimmedOpacity: other.dimmedOpacity ?? dimmedOpacity,
      padAngle: other.padAngle ?? padAngle,
      cornerRadius: other.cornerRadius ?? cornerRadius,
      labelMarginHorizontal:
          other.labelMarginHorizontal ?? labelMarginHorizontal,
      labelMarginVertical: other.labelMarginVertical ?? labelMarginVertical,
      labelRadiusOffset: other.labelRadiusOffset ?? labelRadiusOffset,
      minLabelSweep: other.minLabelSweep ?? minLabelSweep,
      centreTextPadding: other.centreTextPadding ?? centreTextPadding,
      centreTextBaselineOffset:
          other.centreTextBaselineOffset ?? centreTextBaselineOffset,
      titleHeightMin: other.titleHeightMin ?? titleHeightMin,
      titleFontFallbackSize:
          other.titleFontFallbackSize ?? titleFontFallbackSize,
      legendGap: other.legendGap ?? legendGap,
      minDonutRadius: other.minDonutRadius ?? minDonutRadius,
      arcStrokeColor: other.arcStrokeColor ?? arcStrokeColor,
      focusRingColor: other.focusRingColor ?? focusRingColor,
      arcLabelTextStyle: other.arcLabelTextStyle ?? arcLabelTextStyle,
      centreValueTextStyle: other.centreValueTextStyle ?? centreValueTextStyle,
      titleTextStyle: other.titleTextStyle ?? titleTextStyle,
      titleBackgroundColor: other.titleBackgroundColor ?? titleBackgroundColor,
    );
  }

  /// This style with the given properties replaced.
  FluentDonutChartStyle copyWith({
    WidgetStateProperty<double?>? arcStrokeWidth,
    WidgetStateProperty<double?>? focusRingWidth,
    WidgetStateProperty<double?>? dimmedOpacity,
    WidgetStateProperty<double?>? padAngle,
    WidgetStateProperty<double?>? cornerRadius,
    WidgetStateProperty<double?>? labelMarginHorizontal,
    WidgetStateProperty<double?>? labelMarginVertical,
    WidgetStateProperty<double?>? labelRadiusOffset,
    WidgetStateProperty<double?>? minLabelSweep,
    WidgetStateProperty<double?>? centreTextPadding,
    WidgetStateProperty<double?>? centreTextBaselineOffset,
    WidgetStateProperty<double?>? titleHeightMin,
    WidgetStateProperty<double?>? titleFontFallbackSize,
    WidgetStateProperty<double?>? legendGap,
    WidgetStateProperty<double?>? minDonutRadius,
    WidgetStateProperty<Color?>? arcStrokeColor,
    WidgetStateProperty<Color?>? focusRingColor,
    WidgetStateProperty<TextStyle?>? arcLabelTextStyle,
    WidgetStateProperty<TextStyle?>? centreValueTextStyle,
    WidgetStateProperty<TextStyle?>? titleTextStyle,
    WidgetStateProperty<Color?>? titleBackgroundColor,
  }) => FluentDonutChartStyle(
    arcStrokeWidth: arcStrokeWidth ?? this.arcStrokeWidth,
    focusRingWidth: focusRingWidth ?? this.focusRingWidth,
    dimmedOpacity: dimmedOpacity ?? this.dimmedOpacity,
    padAngle: padAngle ?? this.padAngle,
    cornerRadius: cornerRadius ?? this.cornerRadius,
    labelMarginHorizontal: labelMarginHorizontal ?? this.labelMarginHorizontal,
    labelMarginVertical: labelMarginVertical ?? this.labelMarginVertical,
    labelRadiusOffset: labelRadiusOffset ?? this.labelRadiusOffset,
    minLabelSweep: minLabelSweep ?? this.minLabelSweep,
    centreTextPadding: centreTextPadding ?? this.centreTextPadding,
    centreTextBaselineOffset:
        centreTextBaselineOffset ?? this.centreTextBaselineOffset,
    titleHeightMin: titleHeightMin ?? this.titleHeightMin,
    titleFontFallbackSize: titleFontFallbackSize ?? this.titleFontFallbackSize,
    legendGap: legendGap ?? this.legendGap,
    minDonutRadius: minDonutRadius ?? this.minDonutRadius,
    arcStrokeColor: arcStrokeColor ?? this.arcStrokeColor,
    focusRingColor: focusRingColor ?? this.focusRingColor,
    arcLabelTextStyle: arcLabelTextStyle ?? this.arcLabelTextStyle,
    centreValueTextStyle: centreValueTextStyle ?? this.centreValueTextStyle,
    titleTextStyle: titleTextStyle ?? this.titleTextStyle,
    titleBackgroundColor: titleBackgroundColor ?? this.titleBackgroundColor,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`. Use the constructor directly
  /// when a property genuinely differs per state.
  static FluentDonutChartStyle from({
    double? arcStrokeWidth,
    double? focusRingWidth,
    double? dimmedOpacity,
    double? padAngle,
    double? cornerRadius,
    double? labelMarginHorizontal,
    double? labelMarginVertical,
    double? labelRadiusOffset,
    double? minLabelSweep,
    double? centreTextPadding,
    double? centreTextBaselineOffset,
    double? titleHeightMin,
    double? titleFontFallbackSize,
    double? legendGap,
    double? minDonutRadius,
    Color? arcStrokeColor,
    Color? focusRingColor,
    TextStyle? arcLabelTextStyle,
    TextStyle? centreValueTextStyle,
    TextStyle? titleTextStyle,
    Color? titleBackgroundColor,
  }) => FluentDonutChartStyle(
    arcStrokeWidth: _all(arcStrokeWidth),
    focusRingWidth: _all(focusRingWidth),
    dimmedOpacity: _all(dimmedOpacity),
    padAngle: _all(padAngle),
    cornerRadius: _all(cornerRadius),
    labelMarginHorizontal: _all(labelMarginHorizontal),
    labelMarginVertical: _all(labelMarginVertical),
    labelRadiusOffset: _all(labelRadiusOffset),
    minLabelSweep: _all(minLabelSweep),
    centreTextPadding: _all(centreTextPadding),
    centreTextBaselineOffset: _all(centreTextBaselineOffset),
    titleHeightMin: _all(titleHeightMin),
    titleFontFallbackSize: _all(titleFontFallbackSize),
    legendGap: _all(legendGap),
    minDonutRadius: _all(minDonutRadius),
    arcStrokeColor: _all(arcStrokeColor),
    focusRingColor: _all(focusRingColor),
    arcLabelTextStyle: _all(arcLabelTextStyle),
    centreValueTextStyle: _all(centreValueTextStyle),
    titleTextStyle: _all(titleTextStyle),
    titleBackgroundColor: _all(titleBackgroundColor),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentDonutChartStyle &&
      other.arcStrokeWidth == arcStrokeWidth &&
      other.focusRingWidth == focusRingWidth &&
      other.dimmedOpacity == dimmedOpacity &&
      other.padAngle == padAngle &&
      other.cornerRadius == cornerRadius &&
      other.labelMarginHorizontal == labelMarginHorizontal &&
      other.labelMarginVertical == labelMarginVertical &&
      other.labelRadiusOffset == labelRadiusOffset &&
      other.minLabelSweep == minLabelSweep &&
      other.centreTextPadding == centreTextPadding &&
      other.centreTextBaselineOffset == centreTextBaselineOffset &&
      other.titleHeightMin == titleHeightMin &&
      other.titleFontFallbackSize == titleFontFallbackSize &&
      other.legendGap == legendGap &&
      other.minDonutRadius == minDonutRadius &&
      other.arcStrokeColor == arcStrokeColor &&
      other.focusRingColor == focusRingColor &&
      other.arcLabelTextStyle == arcLabelTextStyle &&
      other.centreValueTextStyle == centreValueTextStyle &&
      other.titleTextStyle == titleTextStyle &&
      other.titleBackgroundColor == titleBackgroundColor;

  // Twenty is exactly Object.hash's positional ceiling, and there are
  // twenty-one fields, so hashAll it is.
  @override
  int get hashCode => Object.hashAll(<Object?>[
    arcStrokeWidth,
    focusRingWidth,
    dimmedOpacity,
    padAngle,
    cornerRadius,
    labelMarginHorizontal,
    labelMarginVertical,
    labelRadiusOffset,
    minLabelSweep,
    centreTextPadding,
    centreTextBaselineOffset,
    titleHeightMin,
    titleFontFallbackSize,
    legendGap,
    minDonutRadius,
    arcStrokeColor,
    focusRingColor,
    arcLabelTextStyle,
    centreValueTextStyle,
    titleTextStyle,
    titleBackgroundColor,
  ]);
}

/// The derived defaults for a donut chart, before any theme or widget override.
///
/// Every literal here is transcribed from `DonutChart.tsx`, `Pie.tsx`,
/// `Arc.tsx` and their style files; the citing comment on each field of
/// [FluentDonutChartStyle] is the authority.
FluentDonutChartStyle resolveFluentDonutChartStyle(FluentThemeData theme) {
  final text = FluentChartTextStyles.of(theme);
  return FluentDonutChartStyle.from(
    // useArcStyles.styles.ts:22-31 — a stroke with no declared width, so SVG's
    // default of 1 applies.
    arcStrokeWidth: 1,
    arcStrokeColor: theme.colors.neutralBackground1,
    // useArcStyles.styles.ts:34 — strokeWidthThickest.
    focusRingWidth: 4,
    focusRingColor: theme.colors.strokeFocus2,
    // Arc.tsx:112-113.
    dimmedOpacity: 0.1,
    // Pie.tsx:98.
    padAngle: 0.02,
    // Arc.tsx:114 — roundCorners never reaches Arc, so this is always 0.
    cornerRadius: 0,
    // DonutChart.tsx:332-333.
    labelMarginHorizontal: 80,
    labelMarginVertical: 40,
    // Arc.tsx:79.
    labelRadiusOffset: 2,
    // Arc.tsx:71 — 15 degrees.
    minLabelSweep: math.pi / 12,
    // Pie.tsx:14,24 — TEXT_PADDING.
    centreTextPadding: 5,
    // Pie.tsx:107.
    centreTextBaselineOffset: 5,
    // DonutChart.tsx:281.
    titleHeightMin: 36,
    // DonutChart.tsx:279.
    titleFontFallbackSize: 13,
    // useDonutChartStyles.styles.ts:43 — legendContainer paddingTop
    // spacingVerticalL.
    legendGap: 16,
    // utilities.ts:90 — MIN_DONUT_RADIUS.
    minDonutRadius: 1,
    arcLabelTextStyle: theme.typography.caption1Strong.copyWith(
      color: theme.colors.neutralForeground1,
    ),
    centreValueTextStyle: theme.typography.title2.copyWith(
      color: theme.colors.neutralForeground1,
    ),
    titleTextStyle: text.chartTitle,
    // useDonutChartStyles.styles.ts:48-53 — the svgTooltip slot.
    titleBackgroundColor: theme.colors.neutralBackground1,
  );
}
