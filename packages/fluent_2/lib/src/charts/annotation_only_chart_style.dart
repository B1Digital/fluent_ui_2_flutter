import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentAnnotationOnlyChart`.
///
/// The chart is a shell: it paints nothing itself and delegates every mark to
/// `FluentChartAnnotationLayer`. This style therefore carries only the shell's
/// own frame — the gap, the content radius, the two background layers and the
/// title type.
@immutable
class FluentAnnotationOnlyChartStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentAnnotationOnlyChartStyle({
    this.rowGap,
    this.contentRadius,
    this.defaultHeight,
    this.fallbackWidth,
    this.paperBackgroundColor,
    this.plotBackgroundColor,
    this.foregroundColor,
    this.titleTextStyle,
  });

  /// Vertical gap between the title and the content box
  /// (`useAnnotationOnlyChartStyles.styles.ts:11`).
  final WidgetStateProperty<double?>? rowGap;

  /// Corner radius of the content box — `borderRadiusMedium`, 4
  /// (`useAnnotationOnlyChartStyles.styles.ts:20`).
  final WidgetStateProperty<double?>? contentRadius;

  /// Height used when the caller gives none
  /// (`AnnotationOnlyChart.tsx:11`).
  final WidgetStateProperty<double?>? defaultHeight;

  /// Width used when neither a prop nor a measurement is available
  /// (`AnnotationOnlyChart.tsx:12`, applied at `:91`). In Flutter a
  /// `LayoutBuilder` always has a width, so this only surfaces under
  /// unbounded horizontal constraints.
  final WidgetStateProperty<double?>? fallbackWidth;

  /// Outer background — the "paper"
  /// (`useAnnotationOnlyChartStyles.styles.ts:12`).
  final WidgetStateProperty<Color?>? paperBackgroundColor;

  /// Inner background — the "plot", transparent by default
  /// (`useAnnotationOnlyChartStyles.styles.ts:19`).
  final WidgetStateProperty<Color?>? plotBackgroundColor;

  /// Default text colour for annotation content
  /// (`useAnnotationOnlyChartStyles.styles.ts:13`).
  final WidgetStateProperty<Color?>? foregroundColor;

  /// Title type. The `.title` rule adds only `text-align: center`
  /// (`useAnnotationOnlyChartStyles.styles.ts:23-25`), so the family and size
  /// come from the root's `body1`.
  final WidgetStateProperty<TextStyle?>? titleTextStyle;

  /// Convenience for the common case of one value across every state.
  static FluentAnnotationOnlyChartStyle from({
    double? rowGap,
    double? contentRadius,
    double? defaultHeight,
    double? fallbackWidth,
    Color? paperBackgroundColor,
    Color? plotBackgroundColor,
    Color? foregroundColor,
    TextStyle? titleTextStyle,
  }) => FluentAnnotationOnlyChartStyle(
    rowGap: _all(rowGap),
    contentRadius: _all(contentRadius),
    defaultHeight: _all(defaultHeight),
    fallbackWidth: _all(fallbackWidth),
    paperBackgroundColor: _all(paperBackgroundColor),
    plotBackgroundColor: _all(plotBackgroundColor),
    foregroundColor: _all(foregroundColor),
    titleTextStyle: _all(titleTextStyle),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  /// This style with the non-null properties of [other] layered on top.
  FluentAnnotationOnlyChartStyle merge(FluentAnnotationOnlyChartStyle? other) {
    if (other == null) {
      return this;
    }
    return FluentAnnotationOnlyChartStyle(
      rowGap: other.rowGap ?? rowGap,
      contentRadius: other.contentRadius ?? contentRadius,
      defaultHeight: other.defaultHeight ?? defaultHeight,
      fallbackWidth: other.fallbackWidth ?? fallbackWidth,
      paperBackgroundColor: other.paperBackgroundColor ?? paperBackgroundColor,
      plotBackgroundColor: other.plotBackgroundColor ?? plotBackgroundColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      titleTextStyle: other.titleTextStyle ?? titleTextStyle,
    );
  }

  /// This style with the given properties replaced.
  FluentAnnotationOnlyChartStyle copyWith({
    WidgetStateProperty<double?>? rowGap,
    WidgetStateProperty<double?>? contentRadius,
    WidgetStateProperty<double?>? defaultHeight,
    WidgetStateProperty<double?>? fallbackWidth,
    WidgetStateProperty<Color?>? paperBackgroundColor,
    WidgetStateProperty<Color?>? plotBackgroundColor,
    WidgetStateProperty<Color?>? foregroundColor,
    WidgetStateProperty<TextStyle?>? titleTextStyle,
  }) => FluentAnnotationOnlyChartStyle(
    rowGap: rowGap ?? this.rowGap,
    contentRadius: contentRadius ?? this.contentRadius,
    defaultHeight: defaultHeight ?? this.defaultHeight,
    fallbackWidth: fallbackWidth ?? this.fallbackWidth,
    paperBackgroundColor: paperBackgroundColor ?? this.paperBackgroundColor,
    plotBackgroundColor: plotBackgroundColor ?? this.plotBackgroundColor,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    titleTextStyle: titleTextStyle ?? this.titleTextStyle,
  );

  @override
  bool operator ==(Object other) =>
      other is FluentAnnotationOnlyChartStyle &&
      other.rowGap == rowGap &&
      other.contentRadius == contentRadius &&
      other.defaultHeight == defaultHeight &&
      other.fallbackWidth == fallbackWidth &&
      other.paperBackgroundColor == paperBackgroundColor &&
      other.plotBackgroundColor == plotBackgroundColor &&
      other.foregroundColor == foregroundColor &&
      other.titleTextStyle == titleTextStyle;

  @override
  int get hashCode => Object.hash(
    rowGap,
    contentRadius,
    defaultHeight,
    fallbackWidth,
    paperBackgroundColor,
    plotBackgroundColor,
    foregroundColor,
    titleTextStyle,
  );
}

/// The derived defaults for an annotation-only chart.
FluentAnnotationOnlyChartStyle resolveFluentAnnotationOnlyChartStyle(
  FluentThemeData theme,
) => FluentAnnotationOnlyChartStyle.from(
  // useAnnotationOnlyChartStyles.styles.ts:11.
  rowGap: 8,
  // useAnnotationOnlyChartStyles.styles.ts:20 — borderRadiusMedium.
  contentRadius: 4,
  // AnnotationOnlyChart.tsx:11.
  defaultHeight: 650,
  // AnnotationOnlyChart.tsx:12.
  fallbackWidth: 400,
  paperBackgroundColor: theme.colors.neutralBackground1,
  // useAnnotationOnlyChartStyles.styles.ts:19.
  plotBackgroundColor: const Color(0x00000000),
  foregroundColor: theme.colors.neutralForeground1,
  titleTextStyle: theme.typography.body1.copyWith(
    color: theme.colors.neutralForeground1,
  ),
);
