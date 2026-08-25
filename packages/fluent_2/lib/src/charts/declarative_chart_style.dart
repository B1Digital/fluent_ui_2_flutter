import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import 'internal/chart_text_styles.dart';

/// The visual configuration of a Fluent declarative chart.
///
/// Shaped exactly like `FluentBadgeStyle`: every visual property is a
/// [WidgetStateProperty], so a Flutter developer already knows how to read and
/// override it. A declarative chart is not itself interactive — it delegates
/// every hover and selection state to the chart it routes to — so in practice
/// each property here resolves to one value. The state-property shape is kept
/// anyway, for the same reason every other Fluent style class keeps it.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the defaults derived from the theme
/// 2. the nearest declarative chart theme
/// 3. the widget's own style
@immutable
class FluentDeclarativeChartStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentDeclarativeChartStyle({
    this.titleTextStyle,
    this.titleBottomSpacing,
    this.errorTextStyle,
    this.exportBackgroundColor,
    this.exportScale,
  });

  /// Convenience for the common case of one value across every state.
  static FluentDeclarativeChartStyle from({
    TextStyle? titleTextStyle,
    double? titleBottomSpacing,
    TextStyle? errorTextStyle,
    Color? exportBackgroundColor,
    double? exportScale,
  }) => FluentDeclarativeChartStyle(
    titleTextStyle: _all(titleTextStyle),
    titleBottomSpacing: _all(titleBottomSpacing),
    errorTextStyle: _all(errorTextStyle),
    exportBackgroundColor: _all(exportBackgroundColor),
    exportScale: _all(exportScale),
  );

  /// The multi-plot title above the grid (`DeclarativeChart.tsx:549-555`).
  ///
  /// Only drawn when the figure resolved to more than one plot
  /// (`DeclarativeChart.tsx:561`); a single plot puts its title inside the chart
  /// instead.
  final WidgetStateProperty<TextStyle?>? titleTextStyle;

  /// Space between that title and the grid.
  ///
  /// `DeclarativeChart.tsx:553` sets `marginBottom: tokens.spacingVerticalS`,
  /// which Fluent 2 defines as 8 logical pixels.
  final WidgetStateProperty<double?>? titleBottomSpacing;

  /// The text style of the error surface the error builder falls back to.
  ///
  /// Upstream throws instead (`DeclarativeChart.tsx:364`, `:370`). A thrown
  /// exception inside a Flutter `build()` takes down the whole app, so this port
  /// renders rather than throws — see this wave's Global Constraints.
  final WidgetStateProperty<TextStyle?>? errorTextStyle;

  /// The background painted behind an exported image
  /// (`DeclarativeChart.tsx:440` resolves `colorNeutralBackground1` out of the
  /// live CSS variables before handing it to the exporter).
  final WidgetStateProperty<Color?>? exportBackgroundColor;

  /// The pixel-density multiplier for an exported image.
  ///
  /// `DeclarativeChart.tsx:439-443` spreads the caller's options **after** the
  /// defaults, so 5 is a fallback that any explicit `scale` replaces outright —
  /// it is not a floor.
  final WidgetStateProperty<double?>? exportScale;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only [exportScale] keeps
  /// every resolved text style.
  FluentDeclarativeChartStyle merge(FluentDeclarativeChartStyle? other) {
    if (other == null) return this;
    return FluentDeclarativeChartStyle(
      titleTextStyle: other.titleTextStyle ?? titleTextStyle,
      titleBottomSpacing: other.titleBottomSpacing ?? titleBottomSpacing,
      errorTextStyle: other.errorTextStyle ?? errorTextStyle,
      exportBackgroundColor:
          other.exportBackgroundColor ?? exportBackgroundColor,
      exportScale: other.exportScale ?? exportScale,
    );
  }

  /// This style with the given properties replaced.
  FluentDeclarativeChartStyle copyWith({
    WidgetStateProperty<TextStyle?>? titleTextStyle,
    WidgetStateProperty<double?>? titleBottomSpacing,
    WidgetStateProperty<TextStyle?>? errorTextStyle,
    WidgetStateProperty<Color?>? exportBackgroundColor,
    WidgetStateProperty<double?>? exportScale,
  }) => FluentDeclarativeChartStyle(
    titleTextStyle: titleTextStyle ?? this.titleTextStyle,
    titleBottomSpacing: titleBottomSpacing ?? this.titleBottomSpacing,
    errorTextStyle: errorTextStyle ?? this.errorTextStyle,
    exportBackgroundColor: exportBackgroundColor ?? this.exportBackgroundColor,
    exportScale: exportScale ?? this.exportScale,
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentDeclarativeChartStyle &&
      other.titleTextStyle == titleTextStyle &&
      other.titleBottomSpacing == titleBottomSpacing &&
      other.errorTextStyle == errorTextStyle &&
      other.exportBackgroundColor == exportBackgroundColor &&
      other.exportScale == exportScale;

  @override
  int get hashCode => Object.hash(
    titleTextStyle,
    titleBottomSpacing,
    errorTextStyle,
    exportBackgroundColor,
    exportScale,
  );
}

/// Resolves a [FluentDeclarativeChartStyle] from the theme, then layers
/// [themeStyle] and [widgetStyle] on top in that order.
///
/// Every property of the returned style is non-null, so callers never need a
/// second fallback.
FluentDeclarativeChartStyle resolveFluentDeclarativeChartStyle(
  FluentThemeData theme, {
  FluentDeclarativeChartStyle? themeStyle,
  FluentDeclarativeChartStyle? widgetStyle,
}) {
  final colors = theme.colors;
  final textStyles = FluentChartTextStyles.of(theme);
  final defaults = FluentDeclarativeChartStyle.from(
    // `DeclarativeChart.tsx:550-551`: the caption1 ramp at
    // `colorNeutralForeground1`. The shared `FluentChartTextStyles.chartTitle`
    // slot is used instead of caption1 directly, so that a declarative chart's
    // multi-plot title matches the in-chart titles it sits above; that slot is
    // caption2Strong (`utilities/Common.styles.ts:83-91`), which is one ramp
    // smaller than upstream's caption1 here. Only the colour is restated,
    // because the slot is shared.
    titleTextStyle: textStyles.chartTitle.copyWith(
      color: colors.neutralForeground1,
    ),
    // `DeclarativeChart.tsx:553`: `spacingVerticalS` is 8 logical pixels.
    titleBottomSpacing: 8,
    errorTextStyle: textStyles.chartTitle.copyWith(
      color: colors.statusDangerForeground1,
    ),
    // `DeclarativeChart.tsx:440`.
    exportBackgroundColor: colors.neutralBackground1,
    // `DeclarativeChart.tsx:441`.
    exportScale: 5,
  );
  return defaults.merge(themeStyle).merge(widgetStyle);
}
