import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import 'internal/chart_text_styles.dart';

/// The visual configuration of a Fluent Vega-Lite declarative chart.
///
/// Shaped exactly like `FluentBadgeStyle`: every visual property is a
/// [WidgetStateProperty]. A declarative chart is not itself interactive — it
/// delegates every hover and selection state to the chart it routes to — so in
/// practice each property resolves to one value; the state-property shape is
/// kept for consistency with every other Fluent style class.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the defaults derived from the theme
/// 2. the nearest Vega declarative chart theme
/// 3. the widget's own style
@immutable
class FluentVegaDeclarativeChartStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentVegaDeclarativeChartStyle({
    this.concatGap,
    this.defaultSubChartHeight,
    this.errorTextStyle,
  });

  /// Convenience for the common case of one value across every state.
  static FluentVegaDeclarativeChartStyle from({
    double? concatGap,
    double? defaultSubChartHeight,
    TextStyle? errorTextStyle,
  }) => FluentVegaDeclarativeChartStyle(
    concatGap: _all(concatGap),
    defaultSubChartHeight: _all(defaultSubChartHeight),
    errorTextStyle: _all(errorTextStyle),
  );

  /// The gap between two cells of an `hconcat` or `vconcat` grid.
  ///
  /// `VegaDeclarativeChart.tsx:451` sets `gap: '16px'`. The Plotly grid at
  /// `DeclarativeChart.tsx:562-569` sets no gap at all, so the two components
  /// genuinely differ and this is not a shared token.
  final WidgetStateProperty<double?>? concatGap;

  /// The height a concat sub-chart falls back to.
  ///
  /// `VegaDeclarativeChart.tsx:456-461`: the top-level `height` wins, then the
  /// sub-spec's own, then 300. Only the last arm is configurable here — the
  /// first two come from the spec and are read by the widget.
  final WidgetStateProperty<double?>? defaultSubChartHeight;

  /// The text style of the error surface the error builder falls back to.
  ///
  /// Upstream re-throws instead (`VegaDeclarativeChart.tsx:523`). A throw inside
  /// a Flutter `build()` is a red screen for the whole application, which is a
  /// robustness regression rather than parity, so the message is rendered — see
  /// this wave's Global Constraints.
  final WidgetStateProperty<TextStyle?>? errorTextStyle;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only [concatGap] keeps
  /// every resolved text style.
  FluentVegaDeclarativeChartStyle merge(
    FluentVegaDeclarativeChartStyle? other,
  ) {
    if (other == null) return this;
    return FluentVegaDeclarativeChartStyle(
      concatGap: other.concatGap ?? concatGap,
      defaultSubChartHeight:
          other.defaultSubChartHeight ?? defaultSubChartHeight,
      errorTextStyle: other.errorTextStyle ?? errorTextStyle,
    );
  }

  /// This style with the given properties replaced.
  FluentVegaDeclarativeChartStyle copyWith({
    WidgetStateProperty<double?>? concatGap,
    WidgetStateProperty<double?>? defaultSubChartHeight,
    WidgetStateProperty<TextStyle?>? errorTextStyle,
  }) => FluentVegaDeclarativeChartStyle(
    concatGap: concatGap ?? this.concatGap,
    defaultSubChartHeight: defaultSubChartHeight ?? this.defaultSubChartHeight,
    errorTextStyle: errorTextStyle ?? this.errorTextStyle,
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentVegaDeclarativeChartStyle &&
      other.concatGap == concatGap &&
      other.defaultSubChartHeight == defaultSubChartHeight &&
      other.errorTextStyle == errorTextStyle;

  @override
  int get hashCode =>
      Object.hash(concatGap, defaultSubChartHeight, errorTextStyle);
}

/// Resolves a [FluentVegaDeclarativeChartStyle] from the theme, then layers
/// [themeStyle] and [widgetStyle] on top in that order.
///
/// Every property of the returned style is non-null, so callers never need a
/// second fallback.
FluentVegaDeclarativeChartStyle resolveFluentVegaDeclarativeChartStyle(
  FluentThemeData theme, {
  FluentVegaDeclarativeChartStyle? themeStyle,
  FluentVegaDeclarativeChartStyle? widgetStyle,
}) {
  final colors = theme.colors;
  final textStyles = FluentChartTextStyles.of(theme);
  final defaults = FluentVegaDeclarativeChartStyle.from(
    // `VegaDeclarativeChart.tsx:451`: `gap: '16px'`, a CSS pixel and so a
    // logical pixel here.
    concatGap: 16,
    // `VegaDeclarativeChart.tsx:461`: the last arm of the `defaultSubHeight`
    // chain.
    defaultSubChartHeight: 300,
    // No captured upstream colour: `VegaDeclarativeChart.tsx:523` re-throws
    // rather than rendering a message. The danger ramp is the Fluent slot for
    // one, and it is the same slot `resolveFluentDeclarativeChartStyle` picks.
    errorTextStyle: textStyles.chartTitle.copyWith(
      color: colors.statusDangerForeground1,
    ),
  );
  return defaults.merge(themeStyle).merge(widgetStyle);
}
