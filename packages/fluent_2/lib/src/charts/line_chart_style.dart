import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'internal/chart_text_styles.dart';

/// Opacity of a colour fill bar that carries a diagonal stripe pattern.
///
/// `_getColorFillBarOpacity` (`LineChart.tsx:1828-1830`) returns `1` for a
/// patterned bar and `0.4` for a plain one. Only the plain value varies with
/// legend selection, so the patterned value is a constant rather than a state
/// of [FluentLineChartStyle.fillBarOpacity].
const double kFluentLineFillBarPatternedOpacity = 1;

/// The visual configuration of a Fluent line chart.
///
/// Shaped like every other chart style in this package: every visual property
/// is a [WidgetStateProperty], every field is nullable and means "inherit", and
/// the resolution order is derived defaults → the nearest
/// `FluentLineChartTheme` → the widget's own style.
///
/// Three properties vary with [WidgetState.selected], which here means "this
/// series is the highlighted legend, or no legend is highlighted" — upstream's
/// `isLegendSelected` (`LineChart.tsx:804`, `:909`, `:1396-1398`). Everything
/// else is one value across every state.
@immutable
class FluentLineChartStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentLineChartStyle({
    this.strokeWidth,
    this.lineOpacity,
    this.pointOpacity,
    this.markerStrokeWidthEngineB,
    this.staticHighlightRadius,
    this.latchRadius,
    this.lineBorderColor,
    this.markerLabelStyle,
    this.markerLabelGap,
    this.hoverLineColor,
    this.hoverLineDashPattern,
    this.hoverLineTailOffset,
    this.fillBarYPadding,
    this.fillBarOpacity,
    this.stripeTileSize,
    this.stripeStrokeWidth,
    this.eventLabelHeight,
  });

  /// Stroke width of a series line when it carries no `lineOptions` of its own.
  /// `DEFAULT_LINE_STROKE_SIZE` is 4 (`LineChart.tsx:71`).
  final WidgetStateProperty<double?>? strokeWidth;

  /// Opacity of a series line: 1 when selected, 0.1 when a different legend is
  /// highlighted (`LineChart.tsx:1293-1307`).
  final WidgetStateProperty<double?>? lineOpacity;

  /// Opacity of a marker and its text label: 1 when selected, 0.01 otherwise
  /// (`LineChart.tsx:909`).
  ///
  /// Upstream dims to 0.01 rather than 0 so the circle keeps its hit area and
  /// its `role="img"` accessible name.
  final WidgetStateProperty<double?>? pointOpacity;

  /// Stroke width of a marker in the large-dataset ("engine B") render path,
  /// which strokes every point at 1 regardless of the line's own stroke width
  /// (`LineChart.tsx:803`).
  final WidgetStateProperty<double?>? markerStrokeWidthEngineB;

  /// Radius of the static highlight circle drawn under an active point
  /// (`LineChart.tsx:758`).
  final WidgetStateProperty<double?>? staticHighlightRadius;

  /// Radius of the invisible circle that latches the hover callout to the
  /// nearest point (`LineChart.tsx:1165`).
  final WidgetStateProperty<double?>? latchRadius;

  /// Colour of the border stroked behind a series line when
  /// `lineOptions.lineBorderWidth` is set. Upstream falls back to
  /// `tokens.colorNeutralBackground1` (`LineChart.tsx:712`).
  final WidgetStateProperty<Color?>? lineBorderColor;

  /// Text style of a marker's text-mode label
  /// (`getMarkerLabelStyle`, `Common.styles.ts:72-81`).
  final WidgetStateProperty<TextStyle?>? markerLabelStyle;

  /// Gap between a marker's radius and the baseline of its text label
  /// (`LineChart.tsx:929`).
  final WidgetStateProperty<double?>? markerLabelGap;

  /// Colour of the vertical hover line (`LineChart.tsx:1940`).
  ///
  /// Upstream hard-codes the literal `'#323130'` rather than a token, so it
  /// does not follow the theme.
  final WidgetStateProperty<Color?>? hoverLineColor;

  /// Dash pattern of the vertical hover line: `strokeDasharray='5,5'`
  /// (`LineChart.tsx:1943`).
  final WidgetStateProperty<List<double>?>? hoverLineDashPattern;

  /// Distance the vertical hover line stops short of the plot's bottom edge
  /// (`LineChart.tsx:1674`, `y2 = lineHeight - 5 - yScale(y)`).
  final WidgetStateProperty<double?>? hoverLineTailOffset;

  /// Vertical inset of a colour fill bar from the y extent of the data
  /// (`FILL_Y_PADDING`, `LineChart.tsx:1381`).
  final WidgetStateProperty<double?>? fillBarYPadding;

  /// Opacity of a plain colour fill bar: 0.4 when selected
  /// (`LineChart.tsx:1829`), 0.1 when a different legend is highlighted
  /// (`LineChart.tsx:1398`). A patterned bar uses
  /// [kFluentLineFillBarPatternedOpacity] instead.
  final WidgetStateProperty<double?>? fillBarOpacity;

  /// Edge length of the diagonal-stripe pattern tile
  /// (`LineChart.tsx:1422-1423`).
  final WidgetStateProperty<double?>? stripeTileSize;

  /// Stroke width of the diagonal stripes (`LineChart.tsx:1427`).
  final WidgetStateProperty<double?>? stripeStrokeWidth;

  /// Height reserved for the event annotation labels above the plot
  /// (`LineChart.tsx:165`).
  final WidgetStateProperty<double?>? eventLabelHeight;

  /// This style with the non-null properties of [other] layered on top.
  FluentLineChartStyle merge(FluentLineChartStyle? other) {
    if (other == null) {
      return this;
    }
    return FluentLineChartStyle(
      strokeWidth: other.strokeWidth ?? strokeWidth,
      lineOpacity: other.lineOpacity ?? lineOpacity,
      pointOpacity: other.pointOpacity ?? pointOpacity,
      markerStrokeWidthEngineB:
          other.markerStrokeWidthEngineB ?? markerStrokeWidthEngineB,
      staticHighlightRadius:
          other.staticHighlightRadius ?? staticHighlightRadius,
      latchRadius: other.latchRadius ?? latchRadius,
      lineBorderColor: other.lineBorderColor ?? lineBorderColor,
      markerLabelStyle: other.markerLabelStyle ?? markerLabelStyle,
      markerLabelGap: other.markerLabelGap ?? markerLabelGap,
      hoverLineColor: other.hoverLineColor ?? hoverLineColor,
      hoverLineDashPattern: other.hoverLineDashPattern ?? hoverLineDashPattern,
      hoverLineTailOffset: other.hoverLineTailOffset ?? hoverLineTailOffset,
      fillBarYPadding: other.fillBarYPadding ?? fillBarYPadding,
      fillBarOpacity: other.fillBarOpacity ?? fillBarOpacity,
      stripeTileSize: other.stripeTileSize ?? stripeTileSize,
      stripeStrokeWidth: other.stripeStrokeWidth ?? stripeStrokeWidth,
      eventLabelHeight: other.eventLabelHeight ?? eventLabelHeight,
    );
  }

  /// This style with the given properties replaced.
  FluentLineChartStyle copyWith({
    WidgetStateProperty<double?>? strokeWidth,
    WidgetStateProperty<double?>? lineOpacity,
    WidgetStateProperty<double?>? pointOpacity,
    WidgetStateProperty<double?>? markerStrokeWidthEngineB,
    WidgetStateProperty<double?>? staticHighlightRadius,
    WidgetStateProperty<double?>? latchRadius,
    WidgetStateProperty<Color?>? lineBorderColor,
    WidgetStateProperty<TextStyle?>? markerLabelStyle,
    WidgetStateProperty<double?>? markerLabelGap,
    WidgetStateProperty<Color?>? hoverLineColor,
    WidgetStateProperty<List<double>?>? hoverLineDashPattern,
    WidgetStateProperty<double?>? hoverLineTailOffset,
    WidgetStateProperty<double?>? fillBarYPadding,
    WidgetStateProperty<double?>? fillBarOpacity,
    WidgetStateProperty<double?>? stripeTileSize,
    WidgetStateProperty<double?>? stripeStrokeWidth,
    WidgetStateProperty<double?>? eventLabelHeight,
  }) => FluentLineChartStyle(
    strokeWidth: strokeWidth ?? this.strokeWidth,
    lineOpacity: lineOpacity ?? this.lineOpacity,
    pointOpacity: pointOpacity ?? this.pointOpacity,
    markerStrokeWidthEngineB:
        markerStrokeWidthEngineB ?? this.markerStrokeWidthEngineB,
    staticHighlightRadius: staticHighlightRadius ?? this.staticHighlightRadius,
    latchRadius: latchRadius ?? this.latchRadius,
    lineBorderColor: lineBorderColor ?? this.lineBorderColor,
    markerLabelStyle: markerLabelStyle ?? this.markerLabelStyle,
    markerLabelGap: markerLabelGap ?? this.markerLabelGap,
    hoverLineColor: hoverLineColor ?? this.hoverLineColor,
    hoverLineDashPattern: hoverLineDashPattern ?? this.hoverLineDashPattern,
    hoverLineTailOffset: hoverLineTailOffset ?? this.hoverLineTailOffset,
    fillBarYPadding: fillBarYPadding ?? this.fillBarYPadding,
    fillBarOpacity: fillBarOpacity ?? this.fillBarOpacity,
    stripeTileSize: stripeTileSize ?? this.stripeTileSize,
    stripeStrokeWidth: stripeStrokeWidth ?? this.stripeStrokeWidth,
    eventLabelHeight: eventLabelHeight ?? this.eventLabelHeight,
  );

  /// Convenience for the common case of one value across every state.
  static FluentLineChartStyle from({
    double? strokeWidth,
    double? lineOpacity,
    double? pointOpacity,
    double? markerStrokeWidthEngineB,
    double? staticHighlightRadius,
    double? latchRadius,
    Color? lineBorderColor,
    TextStyle? markerLabelStyle,
    double? markerLabelGap,
    Color? hoverLineColor,
    List<double>? hoverLineDashPattern,
    double? hoverLineTailOffset,
    double? fillBarYPadding,
    double? fillBarOpacity,
    double? stripeTileSize,
    double? stripeStrokeWidth,
    double? eventLabelHeight,
  }) => FluentLineChartStyle(
    strokeWidth: _all(strokeWidth),
    lineOpacity: _all(lineOpacity),
    pointOpacity: _all(pointOpacity),
    markerStrokeWidthEngineB: _all(markerStrokeWidthEngineB),
    staticHighlightRadius: _all(staticHighlightRadius),
    latchRadius: _all(latchRadius),
    lineBorderColor: _all(lineBorderColor),
    markerLabelStyle: _all(markerLabelStyle),
    markerLabelGap: _all(markerLabelGap),
    hoverLineColor: _all(hoverLineColor),
    hoverLineDashPattern: _all(hoverLineDashPattern),
    hoverLineTailOffset: _all(hoverLineTailOffset),
    fillBarYPadding: _all(fillBarYPadding),
    fillBarOpacity: _all(fillBarOpacity),
    stripeTileSize: _all(stripeTileSize),
    stripeStrokeWidth: _all(stripeStrokeWidth),
    eventLabelHeight: _all(eventLabelHeight),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  List<Object?> get _fields => <Object?>[
    strokeWidth,
    lineOpacity,
    pointOpacity,
    markerStrokeWidthEngineB,
    staticHighlightRadius,
    latchRadius,
    lineBorderColor,
    markerLabelStyle,
    markerLabelGap,
    hoverLineColor,
    hoverLineDashPattern,
    hoverLineTailOffset,
    fillBarYPadding,
    fillBarOpacity,
    stripeTileSize,
    stripeStrokeWidth,
    eventLabelHeight,
  ];

  @override
  bool operator ==(Object other) =>
      other is FluentLineChartStyle && listEquals(other._fields, _fields);

  @override
  int get hashCode => Object.hashAll(_fields);
}

/// The derived defaults for a line chart, before any theme or widget override.
///
/// Every literal here is transcribed from `LineChart.tsx` and
/// `Common.styles.ts`; the citing comment on each field of
/// [FluentLineChartStyle] is the authority.
FluentLineChartStyle resolveFluentLineChartStyle(FluentThemeData theme) =>
    FluentLineChartStyle.from(
      // LineChart.tsx:71 — DEFAULT_LINE_STROKE_SIZE.
      strokeWidth: 4,
      // LineChart.tsx:803.
      markerStrokeWidthEngineB: 1,
      // LineChart.tsx:758.
      staticHighlightRadius: 5.5,
      // LineChart.tsx:1165.
      latchRadius: 8,
      lineBorderColor: theme.colors.neutralBackground1,
      markerLabelStyle: FluentChartTextStyles.of(theme).markerLabel,
      // LineChart.tsx:929.
      markerLabelGap: 12,
      // LineChart.tsx:1940 — the literal '#323130', not a token.
      hoverLineColor: const Color(0xFF323130),
      // LineChart.tsx:1943 — strokeDasharray='5,5'.
      hoverLineDashPattern: const <double>[5, 5],
      // LineChart.tsx:1674.
      hoverLineTailOffset: 5,
      // LineChart.tsx:1381 — FILL_Y_PADDING.
      fillBarYPadding: 3,
      // LineChart.tsx:1422-1423 — the pattern tile is 16 by 16.
      stripeTileSize: 16,
      // LineChart.tsx:1427.
      stripeStrokeWidth: 1.25,
      // LineChart.tsx:165.
      eventLabelHeight: 36,
    ).copyWith(
      // The three selection-dependent properties. `WidgetState.selected` is
      // upstream's `isLegendSelected`.
      lineOpacity: const WidgetStateProperty<double?>.fromMap(
        <WidgetStatesConstraint, double?>{
          // LineChart.tsx:1293-1306 — the undimmed line is fully opaque.
          WidgetState.selected: 1,
          // LineChart.tsx:1307 — a line dimmed by another legend.
          WidgetState.any: 0.1,
        },
      ),
      pointOpacity: const WidgetStateProperty<double?>.fromMap(
        <WidgetStatesConstraint, double?>{
          // LineChart.tsx:909.
          WidgetState.selected: 1,
          WidgetState.any: 0.01,
        },
      ),
      fillBarOpacity: const WidgetStateProperty<double?>.fromMap(
        <WidgetStatesConstraint, double?>{
          // LineChart.tsx:1829 — a plain, undimmed colour fill bar.
          WidgetState.selected: 0.4,
          // LineChart.tsx:1398.
          WidgetState.any: 0.1,
        },
      ),
    );
