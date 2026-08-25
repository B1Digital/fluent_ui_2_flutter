import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

/// The visual configuration of a heat-map chart.
///
/// Shaped like `FluentBadgeStyle`: every visual property is a
/// [WidgetStateProperty] so a Flutter developer already knows how to read and
/// override it. A cell resolves against one state — [WidgetState.disabled] for
/// a cell dimmed because another legend owns the highlight
/// (`HeatMapChart.tsx:128-131`).
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence: the theme-derived defaults from
/// [resolveFluentHeatMapChartStyle], the nearest [FluentHeatMapChartTheme],
/// then the widget's own style.
@immutable
class FluentHeatMapChartStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentHeatMapChartStyle({
    this.cellTextStyle,
    this.cellOpacity,
    this.popoverMaxWidth,
    this.contrastThreshold,
    this.placeholderText,
  });

  /// Type of the value drawn inside a cell — `body1Strong`, 14/20 semibold
  /// (`useHeatMapChartStyles.styles.ts:31-34`, which also sets
  /// `pointerEvents: none`; the cell's own hit region carries the pointer in
  /// this port).
  final WidgetStateProperty<TextStyle?>? cellTextStyle;

  /// Cell fill opacity. 1 while this cell's legend is highlighted or nothing
  /// is, 0.1 otherwise (`HeatMapChart.tsx:128-131`).
  final WidgetStateProperty<double?>? cellOpacity;

  /// Maximum width of the popover's content — 238
  /// (`useHeatMapChartStyles.styles.ts:35-37`).
  final WidgetStateProperty<double?>? popoverMaxWidth;

  /// Contrast ratio below which the cell text inverts to
  /// `colorNeutralBackground1` (`HeatMapChart.tsx:210-213`).
  ///
  /// 3 is the WCAG 2.1 minimum for large text and non-text contrast, not the
  /// 4.5 minimum for body text.
  final WidgetStateProperty<double?>? contrastThreshold;

  /// The text a synthesised cell carries where the data has no point
  /// (`HeatMapChart.tsx:255`).
  final WidgetStateProperty<String?>? placeholderText;

  /// This style with the non-null properties of [other] layered on top.
  FluentHeatMapChartStyle merge(FluentHeatMapChartStyle? other) {
    if (other == null) {
      return this;
    }
    return FluentHeatMapChartStyle(
      cellTextStyle: other.cellTextStyle ?? cellTextStyle,
      cellOpacity: other.cellOpacity ?? cellOpacity,
      popoverMaxWidth: other.popoverMaxWidth ?? popoverMaxWidth,
      contrastThreshold: other.contrastThreshold ?? contrastThreshold,
      placeholderText: other.placeholderText ?? placeholderText,
    );
  }

  /// This style with the given properties replaced.
  FluentHeatMapChartStyle copyWith({
    WidgetStateProperty<TextStyle?>? cellTextStyle,
    WidgetStateProperty<double?>? cellOpacity,
    WidgetStateProperty<double?>? popoverMaxWidth,
    WidgetStateProperty<double?>? contrastThreshold,
    WidgetStateProperty<String?>? placeholderText,
  }) => FluentHeatMapChartStyle(
    cellTextStyle: cellTextStyle ?? this.cellTextStyle,
    cellOpacity: cellOpacity ?? this.cellOpacity,
    popoverMaxWidth: popoverMaxWidth ?? this.popoverMaxWidth,
    contrastThreshold: contrastThreshold ?? this.contrastThreshold,
    placeholderText: placeholderText ?? this.placeholderText,
  );

  /// Convenience for the common case of one value across every state.
  static FluentHeatMapChartStyle from({
    TextStyle? cellTextStyle,
    double? cellOpacity,
    double? popoverMaxWidth,
    double? contrastThreshold,
    String? placeholderText,
  }) => FluentHeatMapChartStyle(
    cellTextStyle: _all(cellTextStyle),
    cellOpacity: _all(cellOpacity),
    popoverMaxWidth: _all(popoverMaxWidth),
    contrastThreshold: _all(contrastThreshold),
    placeholderText: _all(placeholderText),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentHeatMapChartStyle &&
      other.cellTextStyle == cellTextStyle &&
      other.cellOpacity == cellOpacity &&
      other.popoverMaxWidth == popoverMaxWidth &&
      other.contrastThreshold == contrastThreshold &&
      other.placeholderText == placeholderText;

  @override
  int get hashCode => Object.hash(
    cellTextStyle,
    cellOpacity,
    popoverMaxWidth,
    contrastThreshold,
    placeholderText,
  );
}

/// Supplies a [FluentHeatMapChartStyle] to the subtree.
class FluentHeatMapChartTheme extends InheritedTheme {
  /// Creates the theme.
  const FluentHeatMapChartTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style every descendant heat-map chart inherits.
  final FluentHeatMapChartStyle style;

  /// The nearest style, or null.
  static FluentHeatMapChartStyle? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FluentHeatMapChartTheme>()
      ?.style;

  @override
  bool updateShouldNotify(FluentHeatMapChartTheme oldWidget) =>
      oldWidget.style != style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentHeatMapChartTheme(style: style, child: child);
}

/// Derives the default heat-map style from [theme].
FluentHeatMapChartStyle resolveFluentHeatMapChartStyle(FluentThemeData theme) =>
    FluentHeatMapChartStyle(
      // useHeatMapChartStyles.styles.ts:32 spreads body1Strong verbatim; the
      // per-cell fill is computed against the cell colour, not carried here.
      cellTextStyle: WidgetStatePropertyAll<TextStyle?>(
        theme.typography.body1Strong,
      ),
      // HeatMapChart.tsx:129 — '1' unless another legend owns the highlight.
      cellOpacity: const WidgetStateProperty<double?>.fromMap(
        <WidgetStatesConstraint, double?>{
          WidgetState.disabled: 0.1,
          WidgetState.any: 1,
        },
      ),
      // useHeatMapChartStyles.styles.ts:36 — maxWidth: '238px'.
      popoverMaxWidth: const WidgetStatePropertyAll<double?>(238),
      // HeatMapChart.tsx:211 — `if (contrastRatio < 3)`.
      contrastThreshold: const WidgetStatePropertyAll<double?>(3),
      // HeatMapChart.tsx:255. US English, and a style token rather than a
      // message: what a placeholder cell actually announces comes from
      // `buildFluentHeatMapDataSet`, which `FluentHeatMapChart` calls with the
      // ambient localizations' wording.
      placeholderText: const WidgetStatePropertyAll<String?>(
        'No data available',
      ),
    );
