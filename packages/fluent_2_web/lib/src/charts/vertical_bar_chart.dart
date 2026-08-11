import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import 'axis/axis_builders.dart' as builders;
import 'axis/axis_types.dart';
import 'axis/domain_range.dart';
import 'axis/tick_format.dart';
import 'cartesian/cartesian_chart.dart';
import 'cartesian/cartesian_chart_props.dart';
import 'cartesian/cartesian_layout.dart';
import 'cartesian/cartesian_series_delegate.dart';
import 'chrome/chart_popover.dart';
import 'chrome/legend.dart';
import 'internal/chart_colors.dart';
import 'internal/chart_text_measurer.dart';
import 'internal/chart_text_styles.dart';
import 'internal/chart_utils.dart';
import 'internal/d3/path_sink.dart' as d3;
import 'internal/d3/scale.dart';
import 'internal/d3/scale_linear.dart';
import 'internal/d3/shape_line_area.dart' as d3;
import 'model/bar_data.dart';
import 'model/chart_common.dart';
import 'model/chart_value.dart';
import 'model/line_options.dart';
import 'vertical_bar_chart_style.dart';

/// A Fluent 2 vertical bar chart, optionally overlaid with a single line.
///
/// Ports `VerticalBarChart.tsx`. Rendering, axis and legend chrome come from
/// [FluentCartesianChart]; this widget owns the data points, the legend
/// selection state and the hover/focus model.
class FluentVerticalBarChart extends StatefulWidget {
  /// Creates a vertical bar chart over [data].
  const FluentVerticalBarChart({
    super.key,
    required this.data,
    this.props = const FluentCartesianChartProps(),
    this.barWidth,
    this.maxBarWidth = 24,
    this.colors,
    this.chartTitle,
    this.lineLegendText,
    this.lineLegendColor,
    this.lineOptions,
    this.useSingleColor = false,
    this.culture,
    this.xAxisPadding,
    this.hideLabels = false,
    this.xAxisInnerPadding,
    this.xAxisOuterPadding,
    this.roundCorners = false,
    this.mode,
    this.xAxisCategoryOrder = FluentAxisCategoryOrder.defaultOrder,
    this.style,
    this.legendSelectionMode = FluentChartLegendSelectionMode.single,
    this.focusNode,
  });

  /// The bars, in author order.
  final List<FluentVerticalBarChartDataPoint> data;

  /// Shell configuration.
  final FluentCartesianChartProps props;

  /// `number | 'default' | 'auto'`; null resolves to 16.
  final Object? barWidth;

  /// Bar width ceiling — 24 (`VerticalBarChart.tsx:69`).
  final double maxBarWidth;

  /// Replaces the five default palette tokens.
  final List<Color>? colors;

  /// Human title, folded into the accessible description.
  final String? chartTitle;

  /// Legend title for the overlaid line.
  final String? lineLegendText;

  /// Overrides the line colour — the polyline's stroke, its dots' rings, and
  /// the legend swatch, all three (`VerticalBarChart.tsx:165`, `:214`, `:244`
  /// and `:826`).
  ///
  /// Null leaves each of them on its own default token, and upstream's two
  /// defaults disagree: the drawn line falls back to
  /// `colorPaletteYellowBackground1` and the swatch to
  /// `colorPaletteYellowForeground1`. See
  /// [FluentVerticalBarChartStyle.lineColor] and
  /// [FluentVerticalBarChartStyle.lineLegendSwatchColor].
  final Color? lineLegendColor;

  /// How the overlaid line is stroked.
  ///
  /// Only `lineBorderWidth` is read (`VerticalBarChart.tsx:186-188`), and only
  /// to size the halo drawn under the line at `3 + lineBorderWidth * 2`
  /// (`:199`); every other field is inert on this chart by upstream's design.
  final FluentLineOptions? lineOptions;

  /// Whether every bar takes a single colour.
  final bool useSingleColor;

  /// BCP-47 locale for popover formatting.
  ///
  /// ponytail: declared, not yet consumed. Upstream spends it only on
  /// `formatDateToLocaleString` for a *date* x value in the callout
  /// (`VerticalBarChart.tsx:466`), and the popover text is composed by
  /// [FluentVerticalBarChartDelegate.buildHitRegions], which prints the raw x.
  /// Wiring it is the same change every cartesian chart needs and is better
  /// made once.
  final String? culture;

  /// Legacy shorthand feeding both band paddings.
  final double? xAxisPadding;

  /// Whether bar labels are suppressed.
  final bool hideLabels;

  /// Band inner padding override.
  final double? xAxisInnerPadding;

  /// Band outer padding override.
  final double? xAxisOuterPadding;

  /// Whether bars get a 3px corner radius.
  final bool roundCorners;

  /// `'plotly'`, `'histogram'` or null.
  final String? mode;

  /// Ordering applied to a category x axis.
  final FluentAxisCategoryOrder xAxisCategoryOrder;

  /// Style override, highest precedence.
  final FluentVerticalBarChartStyle? style;

  /// Whether the legend allows more than one selection.
  final FluentChartLegendSelectionMode legendSelectionMode;

  /// The chart's single focus node.
  final FocusNode? focusNode;

  @override
  State<FluentVerticalBarChart> createState() => _FluentVerticalBarChartState();
}

class _FluentVerticalBarChartState extends State<FluentVerticalBarChart> {
  List<String> _selectedLegends = const <String>[];
  String? _activeLegend;
  Object? _activeXDataPoint;
  late final FluentChartTextMeasurer _measurer = FluentChartTextMeasurer();

  bool get _hasLine => widget.data.any(
    (FluentVerticalBarChartDataPoint p) => p.lineData != null,
  );

  /// Ports the emptiness test at `VerticalBarChart.tsx:1076-1078`.
  bool get _isEmpty =>
      widget.data.isEmpty ||
      (widget.data.every((FluentVerticalBarChartDataPoint p) => p.y == 0) &&
          !_hasLine);

  @override
  void dispose() {
    _measurer.invalidate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isEmpty) {
      // `Semantics` has no const constructor, so the child carries the const.
      return Semantics(
        container: true,
        liveRegion: true,
        label: 'Graph has no data to display',
        child: const SizedBox.shrink(),
      );
    }
    final theme = FluentTheme.of(context);
    final style = resolveFluentVerticalBarChartStyle(
      theme,
    ).merge(FluentVerticalBarChartTheme.maybeOf(context)).merge(widget.style);
    return FluentCartesianChart(
      focusNode: widget.focusNode,
      legendSelectionMode: widget.legendSelectionMode,
      // The shell owns the selection, so nothing is seeded back into it; the
      // state below exists only to dim the delegate's marks.
      selectedLegends: null,
      onLegendChange: (selected) => setState(() => _selectedLegends = selected),
      props: widget.props.copyWith(
        chartTitleForSemantics: _semanticTitle(),
        // `VerticalBarChart.tsx:1181-1184`. The explicit JSX prop sits after
        // the `{...props}` spread at `:1157`, so the chart always wins and a
        // caller cannot set this on a vertical bar chart.
        //
        // This one flag stands in for two upstream `isScalePaddingDefined`
        // sites: `:1183` here, and `:595`, which guards `.nice()` on
        // VerticalBarChart's own numeric `xBarScale`. The port has no private
        // x scale — the delegate reads the shell's — and the shell nices on
        // exactly this flag (`axis_builders.dart:89`), so the two collapse.
        showRoundOffXTickValues:
            !isScalePaddingDefined(
              widget.xAxisInnerPadding,
              widget.xAxisPadding,
            ) &&
            widget.mode != 'histogram',
      ),
      legends: _legends(style),
      delegate: FluentVerticalBarChartDelegate(
        points: widget.data,
        style: style,
        colors: FluentChartColors.of(theme),
        measurer: _measurer,
        textStyles: FluentChartTextStyles.of(theme),
        selectedLegends: _selectedLegends,
        activeLegend: _activeLegend,
        activeXDataPoint: _activeXDataPoint,
        barWidthProp: widget.barWidth,
        maxBarWidth: widget.maxBarWidth,
        useSingleColor: widget.useSingleColor,
        hideLabels: widget.hideLabels,
        roundCorners: widget.roundCorners,
        mode: widget.mode,
        colorsOverride: widget.colors,
        lineLegendText: widget.lineLegendText,
        lineLegendColor: widget.lineLegendColor,
        lineOptions: widget.lineOptions,
        xAxisInnerPadding: widget.xAxisInnerPadding,
        xAxisOuterPadding: widget.xAxisOuterPadding,
        xAxisPadding: widget.xAxisPadding,
        xAxisCategoryOrder: widget.xAxisCategoryOrder,
      ),
      onChartMouseLeave: () => setState(() => _activeXDataPoint = null),
    );
  }

  /// `_getChartTitle` (`VerticalBarChart.tsx:1066-1074`).
  String _semanticTitle() {
    final prefix = widget.chartTitle == null ? '' : '${widget.chartTitle}. ';
    return '${prefix}Vertical bar chart with ${widget.data.length} bars'
        '${_hasLine ? ' and 1 line' : ''}. ';
  }

  /// `_getLegendData` (`VerticalBarChart.tsx:824-863`).
  List<FluentChartLegendItem> _legends(FluentVerticalBarChartStyle style) {
    final bars = <FluentChartLegendItem>[];
    final seen = <String>{};
    final yMax = widget.data
        .map((FluentVerticalBarChartDataPoint p) => p.y)
        .reduce(math.max);
    for (var i = 0; i < widget.data.length; i++) {
      final legend = widget.data[i].legend;
      if (legend == null || !seen.add(legend)) {
        continue;
      }
      bars.add(
        FluentChartLegendItem(
          title: legend,
          color:
              widget.data[i].color ??
              FluentVerticalBarChartGeometry.colourFor(
                widget.data[i].y,
                palette:
                    widget.colors ?? style.palette!.resolve(<WidgetState>{})!,
                yMax: yMax,
              ),
          // `hoverAction` runs `_handleChartMouseLeave()` before
          // `_onLegendHover` (`VerticalBarChart.tsx:838-841`), which is what
          // drops the active x point.
          onHoverAction: () => setState(() {
            _activeXDataPoint = null;
            _activeLegend = legend;
          }),
          onMouseOutAction: ({required bool isLegendFocused}) =>
              setState(() => _activeLegend = null),
        ),
      );
    }
    if (_hasLine && widget.lineLegendText != null) {
      // `unshift` at VerticalBarChart.tsx:862 — the line legend leads.
      bars.insert(
        0,
        FluentChartLegendItem(
          title: widget.lineLegendText!,
          color:
              widget.lineLegendColor ??
              style.lineLegendSwatchColor!.resolve(<WidgetState>{})!,
          isLineLegendInBarChart: true,
          onHoverAction: () => setState(() {
            _activeXDataPoint = null;
            _activeLegend = widget.lineLegendText;
          }),
          onMouseOutAction: ({required bool isLegendFocused}) =>
              setState(() => _activeLegend = null),
        ),
      );
    }
    return bars;
  }
}

/// One resolved vertical bar.
@immutable
class FluentVerticalBarRect {
  /// Creates a bar rect.
  const FluentVerticalBarRect({
    required this.rect,
    required this.colour,
    required this.opacity,
    required this.index,
    required this.isNegative,
    required this.labelAnchor,
  });

  /// The bar's rectangle in plot coordinates.
  final Rect rect;

  /// Resolved fill.
  final Color colour;

  /// 1 highlighted, 0.1 dimmed.
  final double opacity;

  /// Index of the source data point.
  final int index;

  /// Whether the bar hangs below the baseline.
  final bool isNegative;

  /// Where the bar's label baseline sits, already offset by 6 above or 12
  /// below (`VerticalBarChart.tsx:965`).
  final Offset labelAnchor;
}

/// Pure layout maths for the vertical bar chart.
///
/// Split out from the delegate so every literal below is asserted without a
/// canvas. Ports `VerticalBarChart.tsx:398-413`, `:626-632` and `:976-1064`.
abstract final class FluentVerticalBarChartGeometry {
  /// Ports `_calculateMinBarHeight` (`VerticalBarChart.tsx:626-632`).
  ///
  /// The result is a *pixel floor*: a bar shorter than this is stretched up to
  /// it so a tiny value stays visible. Note the ratio is against 100, not
  /// against the plot height, so it scales with the y range.
  ///
  /// [yBarScale] is the scale `_getScales` builds at
  /// `VerticalBarChart.tsx:584-586` — the data domain onto `[0, plotHeight]`,
  /// so it answers in pixels. Upstream feeds it a *magnitude* rather than a
  /// domain value, which for a domain that does not start at 0 extrapolates;
  /// that is reproduced, not corrected.
  static double minBarHeight({
    required double yMin,
    required double yMax,
    required double yReferencePoint,
    required Scale yBarScale,
  }) {
    // VerticalBarChart.tsx:627-630. The 0 is upstream's own `yMax < 0`.
    final maxHeightFromBaseline = yMax < 0
        ? (yMin - yReferencePoint).abs()
        : math.max(
            (yMax - yReferencePoint).abs(),
            (yMin - yReferencePoint).abs(),
          );
    // 100.0 is upstream's literal divisor at :631, not a percentage of
    // anything.
    return (yBarScale(maxHeightFromBaseline)! / 100.0).ceilToDouble();
  }

  /// Ports `_getDomainMargins` (`VerticalBarChart.tsx:976-1064`).
  ///
  /// Returns both outputs because upstream writes `_barWidth` and
  /// `_domainMargin` into the same closure and the two are mutually dependent:
  /// the bar width comes from the bandwidth, the bandwidth from the margin.
  ///
  /// [isOuterPaddingDefined] is `isScalePaddingDefined(props.xAxisOuterPadding,
  /// props.xAxisPadding)` (`:995`), hoisted to a flag because [outerPadding]
  /// alone cannot tell an explicit 0 from an absent value. [longestLabelWidth]
  /// is `calculateLongestLabelWidth(uniqueX)` (`:1020`), hoisted because it
  /// needs a text measurer this pure function must not own.
  static ({double barWidth, double domainMargin}) solveDomainMargin({
    required FluentChartAxisType xAxisType,
    required int uniqueXCount,
    required double containerWidth,
    required FluentChartMargins margins,
    required Object? barWidthProp,
    required double? maxBarWidth,
    required double innerPadding,
    required double outerPadding,
    required bool isOuterPaddingDefined,
    required String? mode,
    required double longestLabelWidth,
    required List<Object> sortedXValues,
  }) {
    // VerticalBarChart.tsx:977.
    var domainMargin = kMinDomainMargin;
    var barWidth = getBarWidth(barWidthProp, maxBarWidth, mode: mode);
    // vbc-utils.ts:46 via VerticalBarChart.tsx:990 — the two
    // MIN_DOMAIN_MARGINs are subtracted up front.
    final totalWidth = calcTotalWidth(
      containerWidth,
      margins,
      kMinDomainMargin,
    );

    if (xAxisType == FluentChartAxisType.category) {
      if (isOuterPaddingDefined) {
        // VerticalBarChart.tsx:996 — xAxisOuterPadding now does this job.
        domainMargin = 0;
      } else if (barWidthProp != 'auto' && mode != 'histogram') {
        // VerticalBarChart.tsx:1000.
        barWidth = getBarWidth(barWidthProp, maxBarWidth);
        final requiredWidth = calcRequiredWidth(
          barWidth,
          uniqueXCount,
          innerPadding,
        );
        // VerticalBarChart.tsx:1004-1006.
        if (totalWidth >= requiredWidth) {
          domainMargin = kMinDomainMargin + (totalWidth - requiredWidth) / 2;
        }
      } else if ((mode == 'plotly' || mode == 'histogram') &&
          uniqueXCount > 1) {
        // VerticalBarChart.tsx:1010-1025. The 1 is upstream's own
        // `uniqueX.length > 1`.
        final bandwidth = calcBandwidth(totalWidth, uniqueXCount, innerPadding);
        barWidth = getBarWidth(
          barWidthProp,
          maxBarWidth,
          adjustedValue: bandwidth,
          mode: mode,
        );
        final requiredWidth = calcRequiredWidth(
          barWidth,
          uniqueXCount,
          innerPadding,
        );
        final margin1 = (totalWidth - requiredWidth) / 2;
        // `Number.POSITIVE_INFINITY` at VerticalBarChart.tsx:1015, the seed a
        // `Math.min` fold needs.
        var margin2 = double.infinity;
        if (mode != 'histogram') {
          // +20 is the label breathing room at VerticalBarChart.tsx:1020.
          final step = longestLabelWidth + 20;
          margin2 = (totalWidth - (uniqueXCount - innerPadding) * step) / 2;
        }
        // VerticalBarChart.tsx:1025. The 0 is upstream's own floor.
        domainMargin =
            kMinDomainMargin + math.max(0.0, math.min(margin1, margin2));
      }
    } else {
      if (mode == 'histogram') {
        // VerticalBarChart.tsx:1030-1034. `props.maxBarWidth!` is asserted
        // non-null upstream; the fallback keeps a null caller off a crash.
        domainMargin += math.max(
          0.0,
          (totalWidth -
                  calcRequiredWidth(
                    maxBarWidth ?? kDefaultBarWidth,
                    uniqueXCount,
                    innerPadding,
                  )) /
              2,
        );
      }
      // VerticalBarChart.tsx:1045-1054.
      barWidth = getBarWidth(
        barWidthProp,
        maxBarWidth,
        adjustedValue: calculateAppropriateBarWidth(
          sortedXValues,
          calcTotalWidth(containerWidth, margins, domainMargin),
          innerPadding,
        ),
        mode: mode,
      );
      // parity: VerticalBarChart.tsx:1055-1056 are two identical lines, so the
      // margin grows by a whole bar width, not half of one. Oracle B pins that
      // for a chart in no mode — charts-verticalbarchart--vertical-bar-dynamic
      // solves 12 = 8 + 4 against a 4px bar, not 8 + 2 — so it is reproduced.
      domainMargin += barWidth / 2;
      // // parity break: VerticalBarChart.tsx:1056, in histogram mode only.
      //
      // The bars sit centred on the range ends, so n of them at a width of w
      // occupy `(n - 1) * w` of range plus a half-bar overhang at each end.
      // That is the geometry `calculateAppropriateBarWidth` is derived for
      // (`vbc-utils.ts:36-38` and the RFC it cites), and it is what the
      // histogram arm above reserves: it centres `calcRequiredWidth(
      // maxBarWidth, n, innerPadding)` of width and then solves w back out of
      // exactly that. Taking the inset twice spends one bar width the reserve
      // does not have, leaving `(n - 2) * w` of range — every histogram's bars
      // overlap their neighbours, and a TWO-bin histogram gets nothing: at
      // n = 2 the range is 0 and both bin centres map to one pixel.
      //
      // Two bins is what the shipped Plotly route produces from an `xbins`
      // figure (`PlotlySchemaAdapter.ts:1834` binning, `:1876` plotting each
      // bar at its bin centre), so this is not a corner. None of the eleven
      // captured VerticalBarChart stories is a histogram, so no oracle pins
      // upstream's arithmetic here, and the line above keeps every capture that
      // does. Delete this guard and the two histogram assertions in
      // test/charts/vertical_bar_chart_test.dart fail.
      if (mode != 'histogram') {
        domainMargin += barWidth / 2;
      }
    }
    return (barWidth: barWidth, domainMargin: domainMargin);
  }

  /// Ports `_createColors` (`VerticalBarChart.tsx:398-413`).
  ///
  /// Divergence, recorded: upstream builds `scaleLinear<string>()` whose range
  /// is CSS custom-property *strings*, which `d3-color` cannot parse, so d3
  /// falls back to `interpolateString` — an interpolation over the digits
  /// inside the token names, which the browser then resolves. Because Flutter
  /// has no CSS variables, this port resolves the tokens to concrete colours
  /// first and interpolates in sRGB, matching what the browser actually
  /// paints for the single-stop case and every stop boundary.
  static Color colourFor(
    double y, {
    required List<Color> palette,
    required double yMax,
  }) {
    // VerticalBarChart.tsx:399 — an increment of 1 collapses the domain, so a
    // ramp of one entry is constant. The 1 is upstream's own `length <= 1`.
    if (palette.length <= 1) {
      return palette.isEmpty ? const Color(0x00000000) : palette.first;
    }
    final increment = 1 / (palette.length - 1);
    // VerticalBarChart.tsx:407-410.
    final domain = <double>[
      for (var i = 0; i < palette.length; i++) increment * i * yMax,
    ];
    // d3-scale/src/continuous.js clamps nothing, but the range here is a
    // colour list, so beyond either end d3 returns the end stop.
    if (y <= domain.first) {
      return palette.first;
    }
    if (y >= domain.last) {
      return palette.last;
    }
    // 1 is the first interior stop: every y here is above domain.first.
    for (var i = 1; i < domain.length; i++) {
      if (y <= domain[i]) {
        final span = domain[i] - domain[i - 1];
        // The 0 keeps a zero-width segment off a division by zero, which
        // `yMax == 0` produces.
        final t = span == 0 ? 0.0 : (y - domain[i - 1]) / span;
        return Color.lerp(palette[i - 1], palette[i], t)!;
      }
    }
    return palette.last;
  }
}

/// Renders `VerticalBarChartDataPoint`s into the shared cartesian shell.
///
/// Ports `VerticalBarChart.tsx` (1212 lines). The y scale used for the bars is
/// a **magnitude** scale — `scaleLinear().domain([_yMin, _yMax]).range([0,
/// plotH])` (`:584-586`) — not the shell's position scale, so `yBarScale(v)` is
/// a height and every bar top is derived from `containerHeight -
/// margins.bottom`.
class FluentVerticalBarChartDelegate extends FluentCartesianSeriesDelegate {
  /// Creates a delegate over [points].
  const FluentVerticalBarChartDelegate({
    required this.points,
    required this.style,
    required this.colors,
    required this.measurer,
    required this.textStyles,
    required this.selectedLegends,
    this.activeLegend,
    this.activeXDataPoint,
    this.barWidthProp,
    this.maxBarWidth = 24,
    this.useSingleColor = false,
    this.hideLabels = false,
    this.roundCorners = false,
    this.mode,
    this.colorsOverride,
    this.lineLegendText,
    this.lineLegendColor,
    this.lineOptions,
    // The two band paddings are stored raw and resolved by [innerPadding] and
    // [outerPadding]; the shell reads the resolved overrides below. A named
    // parameter cannot be a private initialising formal, hence the explicit
    // assignment — the same shape GroupedVerticalBarChart uses.
    double? xAxisInnerPadding,
    double? xAxisOuterPadding,
    this.xAxisPadding,
    this.xAxisCategoryOrder = FluentAxisCategoryOrder.defaultOrder,
    this.yAxisTickFormat,
    // ignore: prefer_initializing_formals
  }) : _xAxisInnerPadding = xAxisInnerPadding,
       // ignore: prefer_initializing_formals
       _xAxisOuterPadding = xAxisOuterPadding;

  /// The data points, in author order.
  final List<FluentVerticalBarChartDataPoint> points;

  /// The resolved style.
  final FluentVerticalBarChartStyle style;

  /// Resolved chart colours, carrying the high-contrast flattening.
  final FluentChartColors colors;

  /// The chart subtree's single text measurer.
  final FluentChartTextMeasurer measurer;

  /// Resolved chart text styles.
  final FluentChartTextStyles textStyles;

  /// Legend titles selected by the user.
  final List<String> selectedLegends;

  /// Legend title currently hovered.
  final String? activeLegend;

  /// The x value whose line dot is enlarged.
  final Object? activeXDataPoint;

  /// `number | 'default' | 'auto'` (`VerticalBarChart.types.ts`).
  final Object? barWidthProp;

  /// Bar width ceiling — 24 (`VerticalBarChart.tsx:69`).
  final double maxBarWidth;

  /// Whether every bar takes the palette's first colour.
  final bool useSingleColor;

  /// Whether bar labels are suppressed.
  final bool hideLabels;

  /// Whether bars get a 3px corner radius.
  final bool roundCorners;

  /// `'plotly'`, `'histogram'` or null.
  final String? mode;

  /// A caller-supplied ramp that replaces the five default tokens.
  final List<Color>? colorsOverride;

  /// Legend title for the overlaid line, if any.
  final String? lineLegendText;

  /// `props.lineLegendColor` — the ink of the line **and** of its dots' rings
  /// (`VerticalBarChart.tsx:165` destructures it once and spends it at `:214`
  /// and `:244`). Null falls back to [FluentVerticalBarChartStyle.lineColor],
  /// which carries upstream's `tokens.colorPaletteYellowBackground1` default.
  final Color? lineLegendColor;

  /// `props.lineOptions`; only `lineBorderWidth` is read
  /// (`VerticalBarChart.tsx:186-188`).
  final FluentLineOptions? lineOptions;

  /// Legacy shorthand feeding both paddings.
  @override
  final double? xAxisPadding;

  /// Band inner padding as the caller gave it, before [innerPadding] resolves
  /// it. Kept raw because an explicit 0 and an absent value make different
  /// charts — see [isScalePaddingDefined].
  final double? _xAxisInnerPadding;

  /// Band outer padding as the caller gave it. Raw for the same reason.
  final double? _xAxisOuterPadding;

  /// The inner padding the **shell's** band scale is built with.
  ///
  /// Resolved, not raw. `VerticalBarChart.tsx:1177-1180` spreads
  /// `_xAxisInnerPadding` and `_xAxisOuterPadding` into `CartesianChart` — and
  /// only for a string axis, hence the guard — so the band scale is padded with
  /// the same numbers `_getDomainMargins` sized the range against. Handing the
  /// raw null instead lets `createStringXAxis` fall back to its own
  /// `xAxisPadding = 0.1` (`utilities.ts:574`, spent at `:585-586` and ported at
  /// `axis_builders.dart:396-401`), and the bars then no longer fill the range
  /// the domain margin centred them in.
  @override
  double? get xAxisInnerPadding => xAxisType == FluentChartAxisType.category
      ? innerPadding
      : _xAxisInnerPadding;

  /// The outer padding the shell's band scale is built with. See
  /// [xAxisInnerPadding].
  @override
  double? get xAxisOuterPadding => xAxisType == FluentChartAxisType.category
      ? outerPadding
      : _xAxisOuterPadding;

  /// Ordering applied to a category x axis.
  final FluentAxisCategoryOrder xAxisCategoryOrder;

  /// Caller-supplied y tick formatter, reused for bar labels.
  final String Function(double value)? yAxisTickFormat;

  @override
  FluentChartType get chartType => FluentChartType.verticalBarChart;

  @override
  FluentChartAxisType get xAxisType => points.isEmpty
      // parity: VerticalBarChart.tsx:1102-1112 falls back to a category axis.
      ? FluentChartAxisType.category
      : getTypeOfAxis(points.first.x, isXAxis: true);

  @override
  FluentChartAxisType get yAxisType => FluentChartAxisType.numeric;

  /// Resolved inner padding: 2/3 on a category axis, 1/2 otherwise, 0 in
  /// histogram mode (`VerticalBarChart.tsx:315-322`).
  double get innerPadding => mode == 'histogram'
      ? 0
      : getScalePadding(
          _xAxisInnerPadding,
          xAxisPadding,
          xAxisType == FluentChartAxisType.category ? 2 / 3 : 1 / 2,
        );

  /// Resolved outer padding, default 0 (`:323`).
  double get outerPadding =>
      getScalePadding(_xAxisOuterPadding, xAxisPadding, 0);

  List<Color> get _palette =>
      colorsOverride ?? style.palette!.resolve(<WidgetState>{})!;

  /// The domain the **bars** are measured against.
  ///
  /// `_yMax = Math.max(d3Max(...), props.yMaxValue || 0)` and the mirroring
  /// `_yMin` (`VerticalBarChart.tsx:1124-1125`): both ends are clamped through
  /// zero, so an all-positive series still measures from a zero baseline. This
  /// is **not** [resolveYMinMax], which feeds the y axis and stays the raw data
  /// extent (`utilities.ts:1633-1654`).
  ///
  /// Pinned by Oracle B: `charts-verticalbarchart--vertical-bar-default` has a
  /// data minimum of 10000, and its bars are only reproducible from a domain
  /// starting at 0.
  FluentChartMinMax get barDomain {
    final raw = resolveYMinMax();
    // The 0 is upstream's own `props.yMinValue || 0` / `yMaxValue || 0`.
    return FluentChartMinMax(
      startValue: math.min(raw.startValue, 0),
      endValue: math.max(raw.endValue, 0),
    );
  }

  @override
  FluentChartDomainRange resolveXDomainRange({
    required FluentChartMargins margins,
    required double containerWidth,
    required bool isRtl,
    required double? barWidth,
    required List<Object>? tickValues,
  }) => switch (xAxisType) {
    FluentChartAxisType.numeric => domainRangeOfVerticalNumeric(
      points,
      margins,
      containerWidth,
      isRtl: isRtl,
    ),
    FluentChartAxisType.date =>
      domainRangeOfDateForAreaLineScatterVerticalBarCharts(
        points,
        margins,
        containerWidth,
        isRtl: isRtl,
        tickValues: tickValues?.whereType<DateTime>().toList() ?? _noDates,
        chartType: FluentChartType.verticalBarChart,
      ),
    FluentChartAxisType.category => domainRangeOfXStringAxis(
      margins,
      containerWidth,
      isRtl: isRtl,
    ),
  };

  static const List<DateTime> _noDates = <DateTime>[];

  @override
  FluentChartMinMax resolveYMinMax({bool useSecondaryYScale = false}) =>
      findVerticalNumericMinMaxOfY(
        points,
        useSecondaryYScale: useSecondaryYScale,
      );

  @override
  FluentAxisSpec createYAxis(
    FluentYAxisParams params,
    FluentAxisData axisData, {
    required bool isRtl,
    required bool isIntegralDataset,
    bool useSecondaryYScale = false,
  }) => builders.createNumericYAxis(
    params,
    axisData,
    isRtl: isRtl,
    isIntegralDataset: isIntegralDataset,
    chartType: FluentChartType.verticalBarChart,
    useSecondaryYScale: useSecondaryYScale,
  );

  @override
  FluentAxisSpec createStringYAxis(
    FluentYAxisParams params,
    List<String> dataPoints,
    FluentAxisData axisData, {
    required bool isRtl,
  }) => builders.createStringYAxis(
    params,
    dataPoints,
    axisData,
    isRtl: isRtl,
    chartType: FluentChartType.verticalBarChart,
  );

  @override
  List<String>? get datasetForXAxisDomain =>
      xAxisType == FluentChartAxisType.category ? orderedCategories : null;

  /// Every distinct x value, in first-appearance order.
  ///
  /// Ports the `mapX` walk at `VerticalBarChart.tsx:979-987`, which keys a
  /// [DateTime] by `getTime()` and everything else by the JS object-key
  /// coercion of the value itself. That coercion is reproduced with string
  /// interpolation rather than corrected, so — as upstream — a chart mixing
  /// `1` and `'1'` counts one unique x, not two.
  List<Object> get uniqueXValues {
    final seen = <Object>{};
    final unique = <Object>[];
    for (final point in points) {
      final key = point.x is DateTime
          ? (point.x as DateTime).millisecondsSinceEpoch
          : '${point.x}';
      if (seen.add(key)) {
        unique.add(point.x);
      }
    }
    return unique;
  }

  /// `_getDomainMargins(containerWidth)` bound to this delegate's own props
  /// (`VerticalBarChart.tsx:976-1064`).
  ///
  /// [margins] are the shell's, which upstream reads off the closure the
  /// `getmargins` callback filled (`CartesianChart.tsx:180`).
  ///
  /// Returns the bar width too, because upstream's `_domainMargin` and
  /// `_barWidth` are written together and [barsFor] needs the second for a
  /// numeric or date axis — `_createNumericBars` and `_createDateBars` read
  /// `_barWidth` at `:656` and `:778` without recomputing it, unlike
  /// `_createStringBars` at `:722`.
  ({double barWidth, double domainMargin}) solveDomainMargin(
    double containerWidth,
    FluentChartMargins margins,
  ) {
    final unique = uniqueXValues;
    return FluentVerticalBarChartGeometry.solveDomainMargin(
      xAxisType: xAxisType,
      uniqueXCount: unique.length,
      containerWidth: containerWidth,
      margins: margins,
      barWidthProp: barWidthProp,
      maxBarWidth: maxBarWidth,
      innerPadding: innerPadding,
      outerPadding: outerPadding,
      // `VerticalBarChart.tsx:993`, one of upstream's four
      // `isScalePaddingDefined` sites. Reads the RAW padding: the resolved
      // [outerPadding] is 0 whether the caller named 0 or named nothing, and
      // telling those apart is the whole point of the helper.
      isOuterPaddingDefined: isScalePaddingDefined(
        _xAxisOuterPadding,
        xAxisPadding,
      ),
      mode: mode,
      // `calculateLongestLabelWidth(uniqueX)` (`:1020`) is read only inside the
      // string-axis arm, so the measure is skipped on the other two rather than
      // paid on every solve.
      longestLabelWidth: xAxisType == FluentChartAxisType.category
          ? measurer.longestWidth(
              unique.map((value) => '$value'),
              textStyles.axisTick,
            )
          : 0,
      sortedXValues: unique,
    );
  }

  @override
  FluentChartMargins? domainMargins(
    double containerWidth,
    FluentChartMargins margins,
  ) {
    final margin = solveDomainMargin(containerWidth, margins).domainMargin;
    // `{...margins, left: …, right: …}` (`VerticalBarChart.tsx:1059-1064`) —
    // top and bottom pass through untouched.
    return margins.copyWith(
      left: (margins.left ?? 0) + margin,
      right: (margins.right ?? 0) + margin,
    );
  }

  /// The band domain, ordered per [xAxisCategoryOrder]
  /// (`VerticalBarChart.tsx:1128-1140`).
  List<String> get orderedCategories {
    if (xAxisCategoryOrder != FluentAxisCategoryOrder.defaultOrder) {
      return sortAxisCategories(<String, List<double>>{
        for (final point in points)
          if (point.x is String) '${point.x}': <double>[point.y],
      }, xAxisCategoryOrder);
    }
    return <String>{
      for (final point in points) '${point.x}',
    }.toList(growable: false);
  }

  /// Resolves every bar for [context].
  List<FluentVerticalBarRect> barsFor(
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
  ) {
    if (points.isEmpty) {
      return const <FluentVerticalBarRect>[];
    }
    final minMax = barDomain;
    final yBarScale = _magnitudeScale(layout, minMax);
    // `_yMax < 0 ? _yMax : 0` (VerticalBarChart.tsx:638).
    final yReference = minMax.endValue < 0 ? minMax.endValue : 0.0;
    final floor = FluentVerticalBarChartGeometry.minBarHeight(
      yMin: minMax.startValue,
      yMax: minMax.endValue,
      yReferencePoint: yReference,
      yBarScale: yBarScale,
    );
    final baseline =
        layout.size.height -
        (layout.margins.bottom ?? 0) -
        yBarScale(yReference)!;
    final isBand = xAxisType == FluentChartAxisType.category;
    // VerticalBarChart.tsx:722 re-derives the width from the live bandwidth;
    // the numeric and date creators keep the one `_getDomainMargins` solved at
    // `:1045-1053`, which is the only place `calculateAppropriateBarWidth`
    // runs. [layout] carries the shell's own margins, so the solve here sees
    // exactly what the shell handed `domainMargins`.
    final barWidth = isBand
        ? getBarWidth(
            barWidthProp,
            maxBarWidth,
            adjustedValue: context.xScale.bandwidth,
            mode: mode,
          )
        : solveDomainMargin(layout.size.width, layout.margins).barWidth;
    final dim = style.barOpacity!.resolve(<WidgetState>{WidgetState.disabled})!;
    final full = style.barOpacity!.resolve(<WidgetState>{})!;
    final gapAbove = style.barLabelGapAbove!.resolve(<WidgetState>{})!;
    final gapBelow = style.barLabelGapBelow!.resolve(<WidgetState>{})!;

    final out = <FluentVerticalBarRect>[];
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      var height = yBarScale(point.y)! - yBarScale(yReference)!;
      final isNegative = height < 0;
      height = height.abs();
      if (height == 0) {
        // parity: VerticalBarChart.tsx:648-651 renders an empty fragment, so
        // the bar is absent from the DOM entirely, not merely zero-height.
        continue;
      }
      final adjusted = height <= floor ? floor : height;
      final top = isNegative ? baseline : baseline - adjusted;
      final left = isBand
          ? context.xScale(point.x)! +
                0.5 * (context.xScale.bandwidth - barWidth)
          : context.xScale(point.x)! - barWidth / 2;
      final highlighted =
          isLegendHighlightedMulti(
            point.legend ?? '',
            selectedLegends: selectedLegends,
            activeLegend: activeLegend,
          ) ||
          // `_noLegendHighlighted` (`VerticalBarChart.tsx:915-917`), whose
          // activeLegend arm is an emptiness test rather than a null test.
          (selectedLegends.isEmpty &&
              (activeLegend == null || activeLegend!.isEmpty));
      out.add(
        FluentVerticalBarRect(
          rect: Rect.fromLTWH(left, top, barWidth, adjusted),
          colour: colors.flattenMark(
            point.color != null && !useSingleColor
                ? point.color!
                : useSingleColor
                ? (colorsOverride?.firstOrNull ??
                      style.singleColor!.resolve(<WidgetState>{})!)
                : FluentVerticalBarChartGeometry.colourFor(
                    point.y,
                    palette: _palette,
                    yMax: minMax.endValue,
                  ),
          ),
          opacity: highlighted ? full : dim,
          index: i,
          isNegative: isNegative,
          // `yPoint` is `containerHeight - bottom - (isNegative ?
          // -adjustedBarHeight : adjustedBarHeight) - yBarScale(ref)`
          // (`VerticalBarChart.tsx:658-663`), which for a negative bar is the
          // rect's BOTTOM, not its top; `:965` then offsets it by 12.
          labelAnchor: Offset(
            left + barWidth / 2,
            isNegative ? top + adjusted + gapBelow : top - gapAbove,
          ),
        ),
      );
    }
    return out;
  }

  /// Whether [bar]'s label is painted.
  ///
  /// Ports `_renderBarLabel`'s guard (`VerticalBarChart.tsx:950`): suppressed
  /// when labels are hidden, when the bar is under 16px wide, or when another
  /// legend owns the highlight.
  bool shouldPaintLabel(FluentVerticalBarRect bar) =>
      !hideLabels &&
      bar.rect.width >= style.minBarLabelWidth!.resolve(<WidgetState>{})! &&
      bar.opacity == style.barOpacity!.resolve(<WidgetState>{})!;

  /// The text drawn over [bar] (`VerticalBarChart.tsx:955-960`).
  String labelFor(FluentVerticalBarRect bar) {
    final point = points[bar.index];
    return point.barLabel ??
        (yAxisTickFormat?.call(point.y) ?? formatScientificLimitWidth(point.y));
  }

  List<FluentVerticalBarChartDataPoint> get _withLine => points
      .where((FluentVerticalBarChartDataPoint p) => p.lineData != null)
      .toList(growable: false);

  /// The overlaid line's path, or null when no point carries `lineData`.
  Path? linePathFor(FluentCartesianChildContext context) {
    final withLine = _withLine;
    if (withLine.isEmpty) {
      return null;
    }
    final sink = d3.UiPathSink();
    // Default curveLinear — VerticalBarChart never sets a curve (`:182`).
    d3.Line<FluentVerticalBarChartDataPoint>(
      x: (FluentVerticalBarChartDataPoint p, int i, _) => _lineX(context, p),
      y: (FluentVerticalBarChartDataPoint p, int i, _) => _lineY(context, p),
    )(withLine, sink);
    return sink.path;
  }

  /// The overlaid line's dot centres.
  List<Offset> lineDotsFor(FluentCartesianChildContext context) => <Offset>[
    for (final point in _withLine)
      Offset(_lineX(context, point), _lineY(context, point)),
  ];

  double _lineX(
    FluentCartesianChildContext context,
    FluentVerticalBarChartDataPoint p,
  ) => xAxisType == FluentChartAxisType.category
      // `xScale(d.x) + 0.5 * xScale.bandwidth()` (`:184`).
      ? context.xScale(p.x)! + 0.5 * context.xScale.bandwidth
      : context.xScale(p.x)!;

  double _lineY(
    FluentCartesianChildContext context,
    FluentVerticalBarChartDataPoint p,
  ) => (p.lineData!.useSecondaryYScale && context.yScaleSecondary != null
      ? context.yScaleSecondary!(p.lineData!.y)
      : context.yScalePrimary(p.lineData!.y))!;

  Scale _magnitudeScale(
    FluentCartesianLayout layout,
    FluentChartMinMax minMax,
  ) => scaleLinear()
    ..domainOf(<double>[minMax.startValue, minMax.endValue])
    ..rangeOf(<double>[
      0,
      layout.size.height -
          (layout.margins.bottom ?? 0) -
          (layout.margins.top ?? 0),
    ]);

  @override
  void paintSeries(
    Canvas canvas,
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
    FluentChartColors colours,
  ) {
    // 0 is upstream's own `rx={props.roundCorners ? 3 : 0}` (`:684`).
    final radius = roundCorners
        ? style.barCornerRadius!.resolve(<WidgetState>{})!
        : 0.0;
    final labelStyle = style.barLabelStyle!.resolve(<WidgetState>{})!;
    for (final bar in barsFor(context, layout)) {
      final paint = Paint()..color = bar.colour.withValues(alpha: bar.opacity);
      if (radius > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(bar.rect, Radius.circular(radius)),
          paint,
        );
      } else {
        canvas.drawRect(bar.rect, paint);
      }
      if (!shouldPaintLabel(bar)) {
        continue;
      }
      final text = labelFor(bar);
      // `text-anchor: middle` on an alphabetic baseline (`:963-969`).
      final painter = measurer.layoutPainter(text, labelStyle);
      final metrics = measurer.measure(text, labelStyle);
      painter.paint(
        canvas,
        Offset(
          bar.labelAnchor.dx - metrics.width / 2,
          bar.labelAnchor.dy - metrics.ascent,
        ),
      );
      painter.dispose();
    }
    _paintLine(canvas, context);
  }

  void _paintLine(Canvas canvas, FluentCartesianChildContext context) {
    final path = linePathFor(context);
    if (path == null) {
      return;
    }
    final lineHighlighted =
        lineLegendText == null ||
        isLegendHighlightedMulti(
          lineLegendText!,
          selectedLegends: selectedLegends,
          activeLegend: activeLegend,
        ) ||
        (selectedLegends.isEmpty &&
            (activeLegend == null || activeLegend!.isEmpty));
    final opacity = lineHighlighted
        ? style.barOpacity!.resolve(<WidgetState>{})!
        : style.barOpacity!.resolve(<WidgetState>{WidgetState.disabled})!;
    final strokeWidth = style.lineStrokeWidth!.resolve(<WidgetState>{})!;
    // `const { lineLegendColor = tokens.colorPaletteYellowBackground1 } = props`
    // (`VerticalBarChart.tsx:165`). One value, spent on the polyline at `:214`
    // and on every dot ring at `:244` — reading the token straight left the
    // line painted in the fallback even when the caller named a colour.
    final rawLineColour =
        lineLegendColor ?? style.lineColor!.resolve(<WidgetState>{})!;
    // The line is a series mark, so its stroke flattens to the system
    // foreground under forced colours (design spec section 5.3).
    final lineColour = colors.flattenMark(rawLineColour);
    final dotFill = style.lineDotFillColor!.resolve(<WidgetState>{})!;
    // `lineBorderWidth` is parsed with `Number.parseFloat` off a
    // `string | number` and guarded `> 0` (`VerticalBarChart.tsx:186-190`), so
    // an absent or zero width draws no halo at all.
    final border = lineOptions?.lineBorderWidth ?? 0;
    if (border > 0) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          // `strokeWidth={3 + lineBorderWidth * 2}` (`:199`): the 3 is the
          // line's own width and the 2 is the two sides it has to clear.
          ..strokeWidth = strokeWidth + border * 2
          ..strokeCap = StrokeCap.square
          // `classes.lineBorder` is `stroke: tokens.colorNeutralBackground1`,
          // and `Canvas` under forced colours
          // (`useVerticalBarChartStyles.styles.ts:36-41`) — the same token and
          // the same flattening as the dot fill below.
          ..color = colors
              .flattenMarkStroke(dotFill)
              .withValues(alpha: opacity),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        // strokeWidth 3, strokeLinecap "square" (`VerticalBarChart.tsx:213`).
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.square
        ..color = lineColour.withValues(alpha: opacity),
    );
    // `stroke={lineLegendColor}` on the dot too (`VerticalBarChart.tsx:244`),
    // so the ring is the same ink as the line. It takes the stroke flattening
    // rather than the mark one because the ring is what separates the dot from
    // the line beneath it, and both flattened to CanvasText would merge.
    final haloColour = colors.flattenMarkStroke(rawLineColour);
    final withLine = _withLine;
    final dots = lineDotsFor(context);
    for (var i = 0; i < dots.length; i++) {
      final active = activeXDataPoint == withLine[i].x;
      final r = style.lineDotRadius!.resolve(
        active ? <WidgetState>{WidgetState.hovered} : <WidgetState>{},
      )!;
      // 0 is `_getCircleVisibilityAndRadius`'s hidden radius (`:296`).
      if (r == 0) {
        continue;
      }
      canvas
        ..drawCircle(dots[i], r, Paint()..color = dotFill)
        ..drawCircle(
          dots[i],
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..color = haloColour.withValues(alpha: opacity),
        );
    }
  }

  @override
  List<FluentChartHitRegion> buildHitRegions(
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
  ) => <FluentChartHitRegion>[
    for (final bar in barsFor(context, layout))
      FluentChartHitRegion(
        bounds: bar.rect,
        index: bar.index,
        legend: points[bar.index].legend ?? '',
        popoverData: FluentChartPopoverData(
          xValue:
              points[bar.index].xAxisCalloutData ?? '${points[bar.index].x}',
          legend: points[bar.index].legend,
          color: bar.colour,
          yValue:
              points[bar.index].yAxisCalloutData ?? '${points[bar.index].y}',
        ),
        semanticsLabel: semanticsLabelFor(points[bar.index]),
      ),
  ];

  /// `_getAriaLabel` (`VerticalBarChart.tsx:922-940`).
  String semanticsLabelFor(FluentVerticalBarChartDataPoint p) {
    final label = p.callOutSemantics?.label;
    if (label != null) {
      return label;
    }
    final buffer = StringBuffer('${p.x}. ');
    if (p.legend != null) {
      buffer.write('${p.legend}, ');
    }
    buffer.write('${p.y}.');
    final lineData = p.lineData;
    if (lineData != null) {
      // The literal 'Line' fallback at VerticalBarChart.tsx:931.
      buffer.write(
        ' ${lineLegendText ?? 'Line'}, '
        '${lineData.yAxisCalloutData ?? lineData.y}.',
      );
    }
    return buffer.toString();
  }
}
