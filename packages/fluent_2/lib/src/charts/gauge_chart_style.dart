import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'internal/chart_text_styles.dart';

/// One row of the gauge's size table (`GaugeChart.tsx:35-42`).
///
/// The table is scanned from the largest entry down, and the first whose
/// [minRadius] the computed outer radius reaches supplies both the arc width
/// and the chart-value font size (`GaugeChart.tsx:167-180`). A gauge smaller
/// than the first entry falls back to it rather than to nothing.
@immutable
class FluentGaugeBreakpoint {
  /// Creates a breakpoint.
  const FluentGaugeBreakpoint({
    required this.minRadius,
    required this.arcWidth,
    required this.fontSize,
  });

  /// Smallest outer radius this row applies to.
  final double minRadius;

  /// Radial thickness of the arc band.
  final double arcWidth;

  /// Font size of the centred chart value.
  final double fontSize;
}

/// The six gauge breakpoints, in the order upstream declares them
/// (`GaugeChart.tsx:35-42`).
const List<FluentGaugeBreakpoint> kFluentGaugeBreakpoints =
    <FluentGaugeBreakpoint>[
      FluentGaugeBreakpoint(minRadius: 52, arcWidth: 12, fontSize: 20),
      FluentGaugeBreakpoint(minRadius: 70, arcWidth: 16, fontSize: 24),
      FluentGaugeBreakpoint(minRadius: 88, arcWidth: 20, fontSize: 32),
      FluentGaugeBreakpoint(minRadius: 106, arcWidth: 24, fontSize: 32),
      FluentGaugeBreakpoint(minRadius: 124, arcWidth: 28, fontSize: 40),
      FluentGaugeBreakpoint(minRadius: 142, arcWidth: 32, fontSize: 40),
    ];

/// The visual configuration of a gauge chart.
@immutable
class FluentGaugeChartStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentGaugeChartStyle({
    this.gaugeMargin,
    this.labelWidth,
    this.labelHeight,
    this.labelOffset,
    this.titleOffset,
    this.extraNeedleLength,
    this.arcPadding,
    this.cornerRadius,
    this.dimmedOpacity,
    this.needleStrokeWidth,
    this.legendsHeight,
    this.chartValueInset,
    this.intrinsicWidth,
    this.intrinsicHeight,
    this.needleFill,
    this.needleStroke,
    this.segmentFocusStrokeColor,
    this.unknownSegmentColor,
    this.limitsTextStyle,
    this.chartValueTextStyle,
    this.sublabelTextStyle,
    this.titleTextStyle,
  });

  /// Space between the gauge and every edge of its box. `GaugeChart.tsx:28`.
  final WidgetStateProperty<double?>? gaugeMargin;

  /// Width reserved for each of the min and max labels.
  /// `GaugeChart.tsx:29`.
  final WidgetStateProperty<double?>? labelWidth;

  /// Height reserved for the title and for the sublabel.
  /// `GaugeChart.tsx:30`.
  final WidgetStateProperty<double?>? labelHeight;

  /// Gap between the arc and the min, max and sublabel text.
  /// `GaugeChart.tsx:31`.
  final WidgetStateProperty<double?>? labelOffset;

  /// Gap between the arc and the chart title. `GaugeChart.tsx:32`.
  final WidgetStateProperty<double?>? titleOffset;

  /// How far the needle overshoots the arc band. `GaugeChart.tsx:33`.
  final WidgetStateProperty<double?>? extraNeedleLength;

  /// Gap between neighbouring segments, and the focused segment's stroke
  /// width. `GaugeChart.tsx:34`, applied as a stroke at `:643`.
  final WidgetStateProperty<double?>? arcPadding;

  /// Radius of a rounded segment corner. `GaugeChart.tsx:216` —
  /// `.cornerRadius(roundCorners ? 3 : 0)`. Unlike `DonutChart` this prop is
  /// live.
  final WidgetStateProperty<double?>? cornerRadius;

  /// Opacity of a segment dimmed by a legend highlight elsewhere.
  /// `GaugeChart.tsx:646`.
  final WidgetStateProperty<double?>? dimmedOpacity;

  /// Width of the needle's outline. `GaugeChart.tsx:251` — the literal 2, and
  /// every needle path radius derives from half of it.
  final WidgetStateProperty<double?>? needleStrokeWidth;

  /// Height of the legend strip below the gauge. `GaugeChart.tsx:119` — 32
  /// unless `hideLegend`.
  final WidgetStateProperty<double?>? legendsHeight;

  /// How much narrower than the inner diameter the chart value may be before
  /// it truncates. `GaugeChart.tsx:681` — `innerRadius * 2 - 24`.
  final WidgetStateProperty<double?>? chartValueInset;

  /// Width of the gauge itself, before margins. `GaugeChart.tsx:126`.
  final WidgetStateProperty<double?>? intrinsicWidth;

  /// Height of the gauge itself, before margins and the legend strip.
  /// `GaugeChart.tsx:127`.
  final WidgetStateProperty<double?>? intrinsicHeight;

  /// Needle fill. `useGaugeChartStyles.styles.ts:63`.
  final WidgetStateProperty<Color?>? needleFill;

  /// Needle outline, which separates it from the arc beneath.
  /// `useGaugeChartStyles.styles.ts:64`.
  final WidgetStateProperty<Color?>? needleStroke;

  /// Focus outline drawn around the focused segment.
  /// `useGaugeChartStyles.styles.ts:73-76` always sets the colour; only the
  /// width toggles, at `GaugeChart.tsx:643`.
  final WidgetStateProperty<Color?>? segmentFocusStrokeColor;

  /// Fill of the auto-appended `Unknown` segment that pads a gauge whose
  /// segments fall short of its maximum. See
  /// [resolveFluentGaugeChartStyle] for why this diverges from upstream.
  final WidgetStateProperty<Color?>? unknownSegmentColor;

  /// The min and max labels flanking the arc.
  /// `useGaugeChartStyles.styles.ts:47-51`.
  final WidgetStateProperty<TextStyle?>? limitsTextStyle;

  /// The centred chart value. `useGaugeChartStyles.styles.ts:52-56` — the size
  /// comes from the breakpoint at paint time (`GaugeChart.tsx:678`), so only
  /// the weight and colour are fixed here.
  final WidgetStateProperty<TextStyle?>? chartValueTextStyle;

  /// The sublabel below the chart value.
  /// `useGaugeChartStyles.styles.ts:57-61`.
  final WidgetStateProperty<TextStyle?>? sublabelTextStyle;

  /// The chart title above the arc. `useGaugeChartStyles.styles.ts:72`.
  final WidgetStateProperty<TextStyle?>? titleTextStyle;

  /// This style with the non-null properties of [other] layered on top.
  FluentGaugeChartStyle merge(FluentGaugeChartStyle? other) {
    if (other == null) return this;
    return FluentGaugeChartStyle(
      gaugeMargin: other.gaugeMargin ?? gaugeMargin,
      labelWidth: other.labelWidth ?? labelWidth,
      labelHeight: other.labelHeight ?? labelHeight,
      labelOffset: other.labelOffset ?? labelOffset,
      titleOffset: other.titleOffset ?? titleOffset,
      extraNeedleLength: other.extraNeedleLength ?? extraNeedleLength,
      arcPadding: other.arcPadding ?? arcPadding,
      cornerRadius: other.cornerRadius ?? cornerRadius,
      dimmedOpacity: other.dimmedOpacity ?? dimmedOpacity,
      needleStrokeWidth: other.needleStrokeWidth ?? needleStrokeWidth,
      legendsHeight: other.legendsHeight ?? legendsHeight,
      chartValueInset: other.chartValueInset ?? chartValueInset,
      intrinsicWidth: other.intrinsicWidth ?? intrinsicWidth,
      intrinsicHeight: other.intrinsicHeight ?? intrinsicHeight,
      needleFill: other.needleFill ?? needleFill,
      needleStroke: other.needleStroke ?? needleStroke,
      segmentFocusStrokeColor:
          other.segmentFocusStrokeColor ?? segmentFocusStrokeColor,
      unknownSegmentColor: other.unknownSegmentColor ?? unknownSegmentColor,
      limitsTextStyle: other.limitsTextStyle ?? limitsTextStyle,
      chartValueTextStyle: other.chartValueTextStyle ?? chartValueTextStyle,
      sublabelTextStyle: other.sublabelTextStyle ?? sublabelTextStyle,
      titleTextStyle: other.titleTextStyle ?? titleTextStyle,
    );
  }

  /// This style with the given properties replaced.
  ///
  /// Twenty-two named parameters, one per field, in declaration order.
  FluentGaugeChartStyle copyWith({
    WidgetStateProperty<double?>? gaugeMargin,
    WidgetStateProperty<double?>? labelWidth,
    WidgetStateProperty<double?>? labelHeight,
    WidgetStateProperty<double?>? labelOffset,
    WidgetStateProperty<double?>? titleOffset,
    WidgetStateProperty<double?>? extraNeedleLength,
    WidgetStateProperty<double?>? arcPadding,
    WidgetStateProperty<double?>? cornerRadius,
    WidgetStateProperty<double?>? dimmedOpacity,
    WidgetStateProperty<double?>? needleStrokeWidth,
    WidgetStateProperty<double?>? legendsHeight,
    WidgetStateProperty<double?>? chartValueInset,
    WidgetStateProperty<double?>? intrinsicWidth,
    WidgetStateProperty<double?>? intrinsicHeight,
    WidgetStateProperty<Color?>? needleFill,
    WidgetStateProperty<Color?>? needleStroke,
    WidgetStateProperty<Color?>? segmentFocusStrokeColor,
    WidgetStateProperty<Color?>? unknownSegmentColor,
    WidgetStateProperty<TextStyle?>? limitsTextStyle,
    WidgetStateProperty<TextStyle?>? chartValueTextStyle,
    WidgetStateProperty<TextStyle?>? sublabelTextStyle,
    WidgetStateProperty<TextStyle?>? titleTextStyle,
  }) => merge(
    FluentGaugeChartStyle(
      gaugeMargin: gaugeMargin,
      labelWidth: labelWidth,
      labelHeight: labelHeight,
      labelOffset: labelOffset,
      titleOffset: titleOffset,
      extraNeedleLength: extraNeedleLength,
      arcPadding: arcPadding,
      cornerRadius: cornerRadius,
      dimmedOpacity: dimmedOpacity,
      needleStrokeWidth: needleStrokeWidth,
      legendsHeight: legendsHeight,
      chartValueInset: chartValueInset,
      intrinsicWidth: intrinsicWidth,
      intrinsicHeight: intrinsicHeight,
      needleFill: needleFill,
      needleStroke: needleStroke,
      segmentFocusStrokeColor: segmentFocusStrokeColor,
      unknownSegmentColor: unknownSegmentColor,
      limitsTextStyle: limitsTextStyle,
      chartValueTextStyle: chartValueTextStyle,
      sublabelTextStyle: sublabelTextStyle,
      titleTextStyle: titleTextStyle,
    ),
  );

  /// Convenience for the common case of one value across every state.
  static FluentGaugeChartStyle from({
    double? gaugeMargin,
    double? labelWidth,
    double? labelHeight,
    double? labelOffset,
    double? titleOffset,
    double? extraNeedleLength,
    double? arcPadding,
    double? cornerRadius,
    double? dimmedOpacity,
    double? needleStrokeWidth,
    double? legendsHeight,
    double? chartValueInset,
    double? intrinsicWidth,
    double? intrinsicHeight,
    Color? needleFill,
    Color? needleStroke,
    Color? segmentFocusStrokeColor,
    Color? unknownSegmentColor,
    TextStyle? limitsTextStyle,
    TextStyle? chartValueTextStyle,
    TextStyle? sublabelTextStyle,
    TextStyle? titleTextStyle,
  }) => FluentGaugeChartStyle(
    gaugeMargin: _all(gaugeMargin),
    labelWidth: _all(labelWidth),
    labelHeight: _all(labelHeight),
    labelOffset: _all(labelOffset),
    titleOffset: _all(titleOffset),
    extraNeedleLength: _all(extraNeedleLength),
    arcPadding: _all(arcPadding),
    cornerRadius: _all(cornerRadius),
    dimmedOpacity: _all(dimmedOpacity),
    needleStrokeWidth: _all(needleStrokeWidth),
    legendsHeight: _all(legendsHeight),
    chartValueInset: _all(chartValueInset),
    intrinsicWidth: _all(intrinsicWidth),
    intrinsicHeight: _all(intrinsicHeight),
    needleFill: _all(needleFill),
    needleStroke: _all(needleStroke),
    segmentFocusStrokeColor: _all(segmentFocusStrokeColor),
    unknownSegmentColor: _all(unknownSegmentColor),
    limitsTextStyle: _all(limitsTextStyle),
    chartValueTextStyle: _all(chartValueTextStyle),
    sublabelTextStyle: _all(sublabelTextStyle),
    titleTextStyle: _all(titleTextStyle),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  List<Object?> get _fields => <Object?>[
    gaugeMargin,
    labelWidth,
    labelHeight,
    labelOffset,
    titleOffset,
    extraNeedleLength,
    arcPadding,
    cornerRadius,
    dimmedOpacity,
    needleStrokeWidth,
    legendsHeight,
    chartValueInset,
    intrinsicWidth,
    intrinsicHeight,
    needleFill,
    needleStroke,
    segmentFocusStrokeColor,
    unknownSegmentColor,
    limitsTextStyle,
    chartValueTextStyle,
    sublabelTextStyle,
    titleTextStyle,
  ];

  @override
  bool operator ==(Object other) =>
      other is FluentGaugeChartStyle && listEquals(other._fields, _fields);

  // Twenty-two fields exceed Object.hash's twenty-argument ceiling.
  @override
  int get hashCode => Object.hashAll(_fields);
}

/// The derived defaults for a gauge chart.
FluentGaugeChartStyle resolveFluentGaugeChartStyle(FluentThemeData theme) {
  final text = FluentChartTextStyles.of(theme);
  return FluentGaugeChartStyle.from(
    // GaugeChart.tsx:28-34.
    gaugeMargin: 16,
    labelWidth: 36,
    labelHeight: 16,
    labelOffset: 4,
    titleOffset: 11,
    extraNeedleLength: 4,
    arcPadding: 2,
    // GaugeChart.tsx:216 — live here, unlike DonutChart.
    cornerRadius: 3,
    // GaugeChart.tsx:646.
    dimmedOpacity: 0.1,
    // GaugeChart.tsx:251.
    needleStrokeWidth: 2,
    // GaugeChart.tsx:119.
    legendsHeight: 32,
    // GaugeChart.tsx:681.
    chartValueInset: 24,
    // GaugeChart.tsx:126-127 — the seed sizes, kept as the intrinsic minimum.
    intrinsicWidth: 140,
    intrinsicHeight: 70,
    needleFill: theme.colors.neutralForeground1,
    needleStroke: theme.colors.neutralBackground1,
    segmentFocusStrokeColor: theme.colors.strokeFocus2,
    // GaugeChart.tsx:208 assigns the raw string 'neutralLight', which is not a
    // legal CSS colour, so the browser paints the filler black. Black is
    // invisible on a dark surface, so this resolves a real token instead.
    // ponytail: fixed, not reproduced — an invisible segment is an
    // accessibility loss, which design spec section 5.2 exempts.
    unknownSegmentColor: theme.colors.neutralBackground4,
    limitsTextStyle: theme.typography.caption1Strong.copyWith(
      color: theme.colors.neutralForeground1,
    ),
    chartValueTextStyle: TextStyle(
      // GaugeChart.tsx:678 sets the size from the breakpoint at paint time;
      // the weight is the only thing the class fixes.
      fontWeight: FluentFontWeight.semibold,
      color: theme.colors.neutralForeground1,
    ),
    sublabelTextStyle: theme.typography.caption1Strong.copyWith(
      color: theme.colors.neutralForeground1,
    ),
    titleTextStyle: text.chartTitle,
  );
}
