import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import 'internal/chart_text_styles.dart';

/// The visual configuration of a funnel chart.
///
/// Shaped exactly like every other `FluentXStyle` in the package: each property
/// is a [WidgetStateProperty], each is nullable and means "inherit", and
/// resolution runs lowest to highest precedence from the derived defaults of
/// [resolveFluentFunnelChartStyle], through the nearest theme, to the widget's
/// own `style`.
///
/// A funnel is not interactive as a whole, so in practice most properties
/// resolve to one value; the state-property shape is kept because one style
/// shape across the package is worth more than a per-component saving.
@immutable
class FluentFunnelChartStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentFunnelChartStyle({
    this.funnelWidthFactor,
    this.funnelHeightFactor,
    this.titleHeightMin,
    this.titleFontFallbackSize,
    this.titlePadding,
    this.minTextWidth,
    this.dimmedOpacity,
    this.intrinsicWidth,
    this.intrinsicHeight,
    this.titleBackgroundColor,
    this.titleTextStyle,
    this.segmentLabelTextStyle,
  });

  /// The fraction of the box width the funnel spans, centred.
  ///
  /// `FunnelChart.tsx:473` — `funnelWidth = width * 0.8`, with the remainder
  /// split evenly by `funnelOffsetX` at `:474`.
  final WidgetStateProperty<double?>? funnelWidthFactor;

  /// The fraction of the height below the title the funnel spans.
  ///
  /// `FunnelChart.tsx:278` — `funnelHeight = containerHeight * 0.8`, so the
  /// bottom fifth of the box is deliberately empty.
  final WidgetStateProperty<double?>? funnelHeightFactor;

  /// The height reserved above the funnel for the title.
  ///
  /// `FunnelChart.tsx:465-470` — `max(fontSize + CHART_TITLE_PADDING, 40)` when
  /// a title is set, and the literal `40` when it is not. The reservation is
  /// unconditional.
  final WidgetStateProperty<double?>? titleHeightMin;

  /// The title font size assumed when the caller supplies no numeric one.
  ///
  /// `FunnelChart.tsx:466-467` — the ternary falls back to `13`.
  final WidgetStateProperty<double?>? titleFontFallbackSize;

  /// The gap added to the title font size before the minimum is applied.
  ///
  /// `utilities/Common.styles.ts:10` — `CHART_TITLE_PADDING`.
  final WidgetStateProperty<double?>? titlePadding;

  /// The narrowest segment that still shows its value label.
  ///
  /// `funnelGeometry.ts:290` defaults `minTextWidth` to `24`, but both call
  /// sites — `FunnelChart.tsx:287` and `:348` — pass `16`, so `24` never
  /// reaches the gate.
  final WidgetStateProperty<double?>? minTextWidth;

  /// The opacity of a segment the legend has dimmed.
  ///
  /// `FunnelChart.tsx:302` and `:363-364` — the un-highlighted arm of both
  /// ternaries is `0.1`.
  final WidgetStateProperty<double?>? dimmedOpacity;

  /// The width used when the caller gives none.
  ///
  /// `FunnelChart.tsx:462` — `props.width || 350`.
  final WidgetStateProperty<double?>? intrinsicWidth;

  /// The height used when the caller gives none.
  ///
  /// `FunnelChart.tsx:463` — `props.height || 500`.
  final WidgetStateProperty<double?>? intrinsicHeight;

  /// The fill painted behind the title text.
  ///
  /// `useFunnelChartStyles.styles.ts:52-57` — the `svgTooltip` slot fills
  /// `colorNeutralBackground1`.
  final WidgetStateProperty<Color?>? titleBackgroundColor;

  /// The chart title's type.
  final WidgetStateProperty<TextStyle?>? titleTextStyle;

  /// The value label drawn on a segment.
  ///
  /// `useFunnelChartStyles.styles.ts:26-35` — the label inherits `.root`
  /// (`fontSizeBase300` at `fontWeightRegular`) because `_renderSegmentText` at
  /// `FunnelChart.tsx:191-227` emits a `<text>` with no className. The semibold
  /// `text` slot at `:41-47` is computed and applied to nothing.
  final WidgetStateProperty<TextStyle?>? segmentLabelTextStyle;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale.
  FluentFunnelChartStyle merge(FluentFunnelChartStyle? other) {
    if (other == null) return this;
    return FluentFunnelChartStyle(
      funnelWidthFactor: other.funnelWidthFactor ?? funnelWidthFactor,
      funnelHeightFactor: other.funnelHeightFactor ?? funnelHeightFactor,
      titleHeightMin: other.titleHeightMin ?? titleHeightMin,
      titleFontFallbackSize:
          other.titleFontFallbackSize ?? titleFontFallbackSize,
      titlePadding: other.titlePadding ?? titlePadding,
      minTextWidth: other.minTextWidth ?? minTextWidth,
      dimmedOpacity: other.dimmedOpacity ?? dimmedOpacity,
      intrinsicWidth: other.intrinsicWidth ?? intrinsicWidth,
      intrinsicHeight: other.intrinsicHeight ?? intrinsicHeight,
      titleBackgroundColor: other.titleBackgroundColor ?? titleBackgroundColor,
      titleTextStyle: other.titleTextStyle ?? titleTextStyle,
      segmentLabelTextStyle:
          other.segmentLabelTextStyle ?? segmentLabelTextStyle,
    );
  }

  /// This style with the given properties replaced.
  FluentFunnelChartStyle copyWith({
    WidgetStateProperty<double?>? funnelWidthFactor,
    WidgetStateProperty<double?>? funnelHeightFactor,
    WidgetStateProperty<double?>? titleHeightMin,
    WidgetStateProperty<double?>? titleFontFallbackSize,
    WidgetStateProperty<double?>? titlePadding,
    WidgetStateProperty<double?>? minTextWidth,
    WidgetStateProperty<double?>? dimmedOpacity,
    WidgetStateProperty<double?>? intrinsicWidth,
    WidgetStateProperty<double?>? intrinsicHeight,
    WidgetStateProperty<Color?>? titleBackgroundColor,
    WidgetStateProperty<TextStyle?>? titleTextStyle,
    WidgetStateProperty<TextStyle?>? segmentLabelTextStyle,
  }) => FluentFunnelChartStyle(
    funnelWidthFactor: funnelWidthFactor ?? this.funnelWidthFactor,
    funnelHeightFactor: funnelHeightFactor ?? this.funnelHeightFactor,
    titleHeightMin: titleHeightMin ?? this.titleHeightMin,
    titleFontFallbackSize: titleFontFallbackSize ?? this.titleFontFallbackSize,
    titlePadding: titlePadding ?? this.titlePadding,
    minTextWidth: minTextWidth ?? this.minTextWidth,
    dimmedOpacity: dimmedOpacity ?? this.dimmedOpacity,
    intrinsicWidth: intrinsicWidth ?? this.intrinsicWidth,
    intrinsicHeight: intrinsicHeight ?? this.intrinsicHeight,
    titleBackgroundColor: titleBackgroundColor ?? this.titleBackgroundColor,
    titleTextStyle: titleTextStyle ?? this.titleTextStyle,
    segmentLabelTextStyle: segmentLabelTextStyle ?? this.segmentLabelTextStyle,
  );

  /// Convenience for the common case of one value across every state.
  static FluentFunnelChartStyle from({
    double? funnelWidthFactor,
    double? funnelHeightFactor,
    double? titleHeightMin,
    double? titleFontFallbackSize,
    double? titlePadding,
    double? minTextWidth,
    double? dimmedOpacity,
    double? intrinsicWidth,
    double? intrinsicHeight,
    Color? titleBackgroundColor,
    TextStyle? titleTextStyle,
    TextStyle? segmentLabelTextStyle,
  }) => FluentFunnelChartStyle(
    funnelWidthFactor: _all(funnelWidthFactor),
    funnelHeightFactor: _all(funnelHeightFactor),
    titleHeightMin: _all(titleHeightMin),
    titleFontFallbackSize: _all(titleFontFallbackSize),
    titlePadding: _all(titlePadding),
    minTextWidth: _all(minTextWidth),
    dimmedOpacity: _all(dimmedOpacity),
    intrinsicWidth: _all(intrinsicWidth),
    intrinsicHeight: _all(intrinsicHeight),
    titleBackgroundColor: _all(titleBackgroundColor),
    titleTextStyle: _all(titleTextStyle),
    segmentLabelTextStyle: _all(segmentLabelTextStyle),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentFunnelChartStyle &&
      other.funnelWidthFactor == funnelWidthFactor &&
      other.funnelHeightFactor == funnelHeightFactor &&
      other.titleHeightMin == titleHeightMin &&
      other.titleFontFallbackSize == titleFontFallbackSize &&
      other.titlePadding == titlePadding &&
      other.minTextWidth == minTextWidth &&
      other.dimmedOpacity == dimmedOpacity &&
      other.intrinsicWidth == intrinsicWidth &&
      other.intrinsicHeight == intrinsicHeight &&
      other.titleBackgroundColor == titleBackgroundColor &&
      other.titleTextStyle == titleTextStyle &&
      other.segmentLabelTextStyle == segmentLabelTextStyle;

  @override
  int get hashCode => Object.hash(
    funnelWidthFactor,
    funnelHeightFactor,
    titleHeightMin,
    titleFontFallbackSize,
    titlePadding,
    minTextWidth,
    dimmedOpacity,
    intrinsicWidth,
    intrinsicHeight,
    titleBackgroundColor,
    titleTextStyle,
    segmentLabelTextStyle,
  );
}

/// The derived defaults for a funnel chart.
FluentFunnelChartStyle resolveFluentFunnelChartStyle(FluentThemeData theme) {
  final text = FluentChartTextStyles.of(theme);
  return FluentFunnelChartStyle.from(
    // FunnelChart.tsx:473 and :278.
    funnelWidthFactor: 0.8,
    funnelHeightFactor: 0.8,
    // FunnelChart.tsx:465-470 — reserved whether or not a title is drawn.
    titleHeightMin: 40,
    // FunnelChart.tsx:466-467.
    titleFontFallbackSize: 13,
    // Common.styles.ts:10 — CHART_TITLE_PADDING, already transcribed.
    titlePadding: kChartTitlePadding,
    // funnelGeometry.ts:290 defaults to 24; FunnelChart.tsx:287 and :348 both
    // pass 16, so 16 is the only value that ever reaches the gate.
    minTextWidth: 16,
    // FunnelChart.tsx:302, :363-364.
    dimmedOpacity: 0.1,
    // FunnelChart.tsx:462-463.
    intrinsicWidth: 350,
    intrinsicHeight: 500,
    titleBackgroundColor: theme.colors.neutralBackground1,
    titleTextStyle: text.chartTitle,
    // useFunnelChartStyles.styles.ts:26-35 — the label inherits .root, because
    // _renderSegmentText emits no className. The semibold `text` slot is dead.
    segmentLabelTextStyle: theme.typography.body1,
  );
}
