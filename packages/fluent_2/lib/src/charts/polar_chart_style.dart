import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import 'internal/chart_text_styles.dart';

/// Half the horizontal margin reserved for a radial tick label
/// (`PolarChart.tsx:39`).
const double kPolarLabelWidth = 36;

/// Height reserved for an angular tick label (`PolarChart.tsx:40`).
const double kPolarLabelHeight = 16;

/// Gap between the outer ring and a tick label (`PolarChart.tsx:41`).
const double kPolarLabelOffset = 10;

/// Length of a radial tick mark (`PolarChart.tsx:42`).
const double kPolarTickSize = 6;

/// Floor applied to the measured legend strip height (`PolarChart.tsx:38`).
const double kPolarLegendHeight = 32;

/// Edge length used when the chart is given an unbounded constraint.
///
/// `PolarChart.tsx:54-55` initialises both container dimensions to 200 and only
/// replaces them once the DOM has been measured, so 200 is the size upstream
/// paints when it has nothing to measure.
const double kPolarDefaultSize = 200;

/// The visual configuration of a `FluentPolarChart`.
///
/// Shaped exactly like `FluentBadgeStyle`: every visual property is a
/// [WidgetStateProperty]. Resolution order, lowest to highest precedence: the
/// defaults derived from the theme by [resolveFluentPolarChartStyle], then the
/// nearest [FluentPolarChartTheme], then the widget's own style.
@immutable
class FluentPolarChartStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentPolarChartStyle({
    this.gridLineColor,
    this.gridLineWidth,
    this.gridLineInnerOpacity,
    this.gridLineOuterOpacity,
    this.tickLabelStyle,
    this.areaFillOpacity,
    this.dimmedOpacity,
    this.lineStrokeWidth,
    this.activeMarkerFill,
    this.activeMarkerStrokeWidth,
    this.minMarkerRadius,
    this.minMarkerRadiusMarkersOnly,
    this.maxMarkerRadius,
    this.tickSize,
    this.labelOffset,
  });

  /// A style whose every property resolves to one constant value.
  static FluentPolarChartStyle from({
    Color? gridLineColor,
    double? gridLineWidth,
    double? gridLineInnerOpacity,
    double? gridLineOuterOpacity,
    TextStyle? tickLabelStyle,
    double? areaFillOpacity,
    double? dimmedOpacity,
    double? lineStrokeWidth,
    Color? activeMarkerFill,
    double? activeMarkerStrokeWidth,
    double? minMarkerRadius,
    double? minMarkerRadiusMarkersOnly,
    double? maxMarkerRadius,
    double? tickSize,
    double? labelOffset,
  }) => FluentPolarChartStyle(
    gridLineColor: WidgetStatePropertyAll<Color?>(gridLineColor),
    gridLineWidth: WidgetStatePropertyAll<double?>(gridLineWidth),
    gridLineInnerOpacity: WidgetStatePropertyAll<double?>(gridLineInnerOpacity),
    gridLineOuterOpacity: WidgetStatePropertyAll<double?>(gridLineOuterOpacity),
    tickLabelStyle: WidgetStatePropertyAll<TextStyle?>(tickLabelStyle),
    areaFillOpacity: WidgetStatePropertyAll<double?>(areaFillOpacity),
    dimmedOpacity: WidgetStatePropertyAll<double?>(dimmedOpacity),
    lineStrokeWidth: WidgetStatePropertyAll<double?>(lineStrokeWidth),
    activeMarkerFill: WidgetStatePropertyAll<Color?>(activeMarkerFill),
    activeMarkerStrokeWidth: WidgetStatePropertyAll<double?>(
      activeMarkerStrokeWidth,
    ),
    minMarkerRadius: WidgetStatePropertyAll<double?>(minMarkerRadius),
    minMarkerRadiusMarkersOnly: WidgetStatePropertyAll<double?>(
      minMarkerRadiusMarkersOnly,
    ),
    maxMarkerRadius: WidgetStatePropertyAll<double?>(maxMarkerRadius),
    tickSize: WidgetStatePropertyAll<double?>(tickSize),
    labelOffset: WidgetStatePropertyAll<double?>(labelOffset),
  );

  /// Stroke of every ring, spoke and axis line
  /// (`usePolarChartStyles.styles.ts:38`).
  final WidgetStateProperty<Color?>? gridLineColor;

  /// Stroke width of every grid line (`usePolarChartStyles.styles.ts:39`).
  final WidgetStateProperty<double?>? gridLineWidth;

  /// Opacity of an inner ring or spoke (`usePolarChartStyles.styles.ts:43`).
  final WidgetStateProperty<double?>? gridLineInnerOpacity;

  /// Opacity of the outermost ring and the radial axis
  /// (`usePolarChartStyles.styles.ts:47`).
  final WidgetStateProperty<double?>? gridLineOuterOpacity;

  /// Tick label text style — `caption2Strong`
  /// (`usePolarChartStyles.styles.ts:51`).
  final WidgetStateProperty<TextStyle?>? tickLabelStyle;

  /// Fill opacity of a highlighted area series (`PolarChart.tsx:457`).
  final WidgetStateProperty<double?>? areaFillOpacity;

  /// Opacity every dimmed mark drops to
  /// (`PolarChart.tsx:457`, `:480`, `:566`).
  final WidgetStateProperty<double?>? dimmedOpacity;

  /// Stroke width of a line series when `lineOptions.strokeWidth` is absent
  /// (`PolarChart.tsx:481`).
  final WidgetStateProperty<double?>? lineStrokeWidth;

  /// Fill of the marker under the cursor (`PolarChart.tsx:563`).
  final WidgetStateProperty<Color?>? activeMarkerFill;

  /// Stroke width of the marker under the cursor (`PolarChart.tsx:565`).
  final WidgetStateProperty<double?>? activeMarkerStrokeWidth;

  /// Marker radius floor when the chart also draws lines or areas
  /// (`PolarChart.tsx:43`).
  final WidgetStateProperty<double?>? minMarkerRadius;

  /// Marker radius floor when the chart draws markers only
  /// (`PolarChart.tsx:45`).
  final WidgetStateProperty<double?>? minMarkerRadiusMarkersOnly;

  /// Marker radius ceiling (`PolarChart.tsx:44`).
  final WidgetStateProperty<double?>? maxMarkerRadius;

  /// Length of a radial tick mark (`PolarChart.tsx:42`).
  final WidgetStateProperty<double?>? tickSize;

  /// Gap between a tick mark and its label (`PolarChart.tsx:41`).
  final WidgetStateProperty<double?>? labelOffset;

  /// This style with the non-null properties of [other] layered on top.
  FluentPolarChartStyle merge(FluentPolarChartStyle? other) {
    if (other == null) {
      return this;
    }
    return FluentPolarChartStyle(
      gridLineColor: other.gridLineColor ?? gridLineColor,
      gridLineWidth: other.gridLineWidth ?? gridLineWidth,
      gridLineInnerOpacity: other.gridLineInnerOpacity ?? gridLineInnerOpacity,
      gridLineOuterOpacity: other.gridLineOuterOpacity ?? gridLineOuterOpacity,
      tickLabelStyle: other.tickLabelStyle ?? tickLabelStyle,
      areaFillOpacity: other.areaFillOpacity ?? areaFillOpacity,
      dimmedOpacity: other.dimmedOpacity ?? dimmedOpacity,
      lineStrokeWidth: other.lineStrokeWidth ?? lineStrokeWidth,
      activeMarkerFill: other.activeMarkerFill ?? activeMarkerFill,
      activeMarkerStrokeWidth:
          other.activeMarkerStrokeWidth ?? activeMarkerStrokeWidth,
      minMarkerRadius: other.minMarkerRadius ?? minMarkerRadius,
      minMarkerRadiusMarkersOnly:
          other.minMarkerRadiusMarkersOnly ?? minMarkerRadiusMarkersOnly,
      maxMarkerRadius: other.maxMarkerRadius ?? maxMarkerRadius,
      tickSize: other.tickSize ?? tickSize,
      labelOffset: other.labelOffset ?? labelOffset,
    );
  }

  /// A copy with the given properties replaced.
  FluentPolarChartStyle copyWith({
    WidgetStateProperty<Color?>? gridLineColor,
    WidgetStateProperty<double?>? gridLineWidth,
    WidgetStateProperty<double?>? gridLineInnerOpacity,
    WidgetStateProperty<double?>? gridLineOuterOpacity,
    WidgetStateProperty<TextStyle?>? tickLabelStyle,
    WidgetStateProperty<double?>? areaFillOpacity,
    WidgetStateProperty<double?>? dimmedOpacity,
    WidgetStateProperty<double?>? lineStrokeWidth,
    WidgetStateProperty<Color?>? activeMarkerFill,
    WidgetStateProperty<double?>? activeMarkerStrokeWidth,
    WidgetStateProperty<double?>? minMarkerRadius,
    WidgetStateProperty<double?>? minMarkerRadiusMarkersOnly,
    WidgetStateProperty<double?>? maxMarkerRadius,
    WidgetStateProperty<double?>? tickSize,
    WidgetStateProperty<double?>? labelOffset,
  }) => FluentPolarChartStyle(
    gridLineColor: gridLineColor ?? this.gridLineColor,
    gridLineWidth: gridLineWidth ?? this.gridLineWidth,
    gridLineInnerOpacity: gridLineInnerOpacity ?? this.gridLineInnerOpacity,
    gridLineOuterOpacity: gridLineOuterOpacity ?? this.gridLineOuterOpacity,
    tickLabelStyle: tickLabelStyle ?? this.tickLabelStyle,
    areaFillOpacity: areaFillOpacity ?? this.areaFillOpacity,
    dimmedOpacity: dimmedOpacity ?? this.dimmedOpacity,
    lineStrokeWidth: lineStrokeWidth ?? this.lineStrokeWidth,
    activeMarkerFill: activeMarkerFill ?? this.activeMarkerFill,
    activeMarkerStrokeWidth:
        activeMarkerStrokeWidth ?? this.activeMarkerStrokeWidth,
    minMarkerRadius: minMarkerRadius ?? this.minMarkerRadius,
    minMarkerRadiusMarkersOnly:
        minMarkerRadiusMarkersOnly ?? this.minMarkerRadiusMarkersOnly,
    maxMarkerRadius: maxMarkerRadius ?? this.maxMarkerRadius,
    tickSize: tickSize ?? this.tickSize,
    labelOffset: labelOffset ?? this.labelOffset,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FluentPolarChartStyle &&
          other.gridLineColor == gridLineColor &&
          other.gridLineWidth == gridLineWidth &&
          other.gridLineInnerOpacity == gridLineInnerOpacity &&
          other.gridLineOuterOpacity == gridLineOuterOpacity &&
          other.tickLabelStyle == tickLabelStyle &&
          other.areaFillOpacity == areaFillOpacity &&
          other.dimmedOpacity == dimmedOpacity &&
          other.lineStrokeWidth == lineStrokeWidth &&
          other.activeMarkerFill == activeMarkerFill &&
          other.activeMarkerStrokeWidth == activeMarkerStrokeWidth &&
          other.minMarkerRadius == minMarkerRadius &&
          other.minMarkerRadiusMarkersOnly == minMarkerRadiusMarkersOnly &&
          other.maxMarkerRadius == maxMarkerRadius &&
          other.tickSize == tickSize &&
          other.labelOffset == labelOffset;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    gridLineColor,
    gridLineWidth,
    gridLineInnerOpacity,
    gridLineOuterOpacity,
    tickLabelStyle,
    areaFillOpacity,
    dimmedOpacity,
    lineStrokeWidth,
    activeMarkerFill,
    activeMarkerStrokeWidth,
    minMarkerRadius,
    minMarkerRadiusMarkersOnly,
    maxMarkerRadius,
    tickSize,
    labelOffset,
  ]);
}

/// Supplies a [FluentPolarChartStyle] to the polar charts beneath it.
class FluentPolarChartTheme extends InheritedTheme {
  /// Creates a polar chart theme.
  const FluentPolarChartTheme({
    required this.style,
    required super.child,
    super.key,
  });

  /// The style every descendant polar chart inherits.
  final FluentPolarChartStyle style;

  /// The nearest ancestor style, or null when there is none.
  static FluentPolarChartStyle? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FluentPolarChartTheme>()
      ?.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentPolarChartTheme(style: style, child: child);

  @override
  bool updateShouldNotify(FluentPolarChartTheme oldWidget) =>
      oldWidget.style != style;
}

/// The defaults derived from [theme], before any theme or widget override.
///
/// Transcribes `usePolarChartStyles.styles.ts:36-53` plus the module constants
/// at `PolarChart.tsx:38-45` and the inline opacities at `:457`, `:480` and
/// `:566`.
FluentPolarChartStyle resolveFluentPolarChartStyle(FluentThemeData theme) =>
    FluentPolarChartStyle.from(
      gridLineColor: theme.colors.neutralForeground1,
      gridLineWidth: 1,
      gridLineInnerOpacity: 0.2,
      gridLineOuterOpacity: 1,
      tickLabelStyle: FluentChartTextStyles.of(theme).axisTick,
      areaFillOpacity: 0.7,
      dimmedOpacity: 0.1,
      lineStrokeWidth: 3,
      activeMarkerFill: theme.colors.neutralBackground1,
      activeMarkerStrokeWidth: 2,
      minMarkerRadius: 2,
      minMarkerRadiusMarkersOnly: 4,
      maxMarkerRadius: 16,
      tickSize: kPolarTickSize,
      labelOffset: kPolarLabelOffset,
    );
