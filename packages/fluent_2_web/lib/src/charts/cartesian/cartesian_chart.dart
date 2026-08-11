import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../axis/axis_builders.dart';
import '../axis/axis_label_layout.dart';
import '../axis/axis_types.dart';
import '../chrome/annotation_layer.dart';
import '../chrome/chart_popover.dart';
import '../chrome/legend.dart';
import '../internal/chart_colors.dart';
import '../internal/chart_semantics.dart';
import '../internal/chart_text_measurer.dart';
import '../internal/chart_text_styles.dart';
import '../internal/chart_utils.dart';
import '../model/chart_value.dart';
import 'cartesian_chart_props.dart';
import 'cartesian_chart_style.dart';
import 'cartesian_layout.dart';
import 'cartesian_painter.dart';
import 'cartesian_series_delegate.dart';

/// The height a cartesian chart takes when its box gives it none.
///
/// `CartesianChart.tsx:516-519` falls back to 350 when the measured box is no
/// taller than the legend. Unbounded `maxHeight` is the Flutter analogue of
/// "the parent did not give me a usable height".
const double kFluentCartesianChartFallbackHeight = 350;

/// Applies a [FluentCartesianChartStyle] to every chart in a subtree.
class FluentCartesianChartTheme extends InheritedTheme {
  /// Applies [style] to every [FluentCartesianChart] in [child].
  const FluentCartesianChartTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the theme-derived defaults.
  final FluentCartesianChartStyle style;

  /// The nearest cartesian chart style, or null.
  static FluentCartesianChartStyle? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FluentCartesianChartTheme>()
      ?.style;

  @override
  bool updateShouldNotify(FluentCartesianChartTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentCartesianChartTheme(style: style, child: child);
}

/// The shared shell nine Fluent charts render through.
///
/// It measures its [BoxConstraints], solves the margins, builds the x axis and
/// the y axis or axes, resolves the x tick-label reserve, and hands the finished
/// [FluentCartesianLayout] to a [FluentCartesianSeriesDelegate] which paints the
/// marks. Upstream fuses those three concerns into one React function body that
/// writes the axes into the DOM and reads them back mid-render, converging over
/// two or three renders (`CartesianChart.tsx:89-128`); measuring with a
/// [FluentChartTextMeasurer] instead settles it in one.
class FluentCartesianChart extends StatefulWidget {
  /// Creates a cartesian chart over [delegate].
  const FluentCartesianChart({
    super.key,
    required this.delegate,
    required this.props,
    required this.legends,
    this.legendSelectionMode = FluentChartLegendSelectionMode.single,
    this.selectedLegends,
    this.onLegendChange,
    this.focusNode,
    this.onChartMouseLeave,
    this.overlayBuilder,
    this.onPointerMoveInPlot,
    this.style,
  });

  /// The chart that supplies the scales and paints the marks.
  final FluentCartesianSeriesDelegate delegate;

  /// The configuration bag.
  final FluentCartesianChartProps props;

  /// The legend entries. Upstream builds these in each chart and passes them to
  /// the shell as the opaque `legendBars` element (`CartesianChart.tsx:919`).
  final List<FluentChartLegendItem> legends;

  /// Whether one or several legends may be selected at a time.
  final FluentChartLegendSelectionMode legendSelectionMode;

  /// The selected legend titles, when the owner controls the selection.
  ///
  /// Non-null puts the legend row in controlled mode: it is drawn from this
  /// list and a click on a legend changes nothing here until the owner supplies
  /// a new list, exactly as `_isInControlledMode` at `Legends.tsx:205-209`
  /// governs the upstream row. Null leaves the selection to the shell's own
  /// state. The initial-value prop is a separate one upstream —
  /// `defaultSelectedLegends` (`Legends.types.ts:196-210`) — and this is not it.
  ///
  /// The declarative adapters own their selection so they can round-trip it
  /// through `onSchemaChange`, and upstream spreads it into every chart they
  /// render (`DeclarativeChart.tsx:411-415`).
  final List<String>? selectedLegends;

  /// Called with the complete new selection whenever a legend is clicked.
  ///
  /// Fires in both modes, because `_onClick` calls `props.onChange`
  /// unconditionally at `Legends.tsx:250`. The titles are the only argument:
  /// upstream also passes the event and the clicked legend, and
  /// `DeclarativeChart.tsx:396-401` — the only consumer — drops both.
  final void Function(List<String> selectedLegends)? onLegendChange;

  /// One focus node for the whole plot.
  ///
  /// A roving index over the delegate's hit regions lives in the state and
  /// drives a single [Semantics] label. Minting a focusable box per data point
  /// is a layout and performance problem on a 500-point series, and canvas text
  /// produces no semantics node at all — design spec section 5.7.
  final FocusNode? focusNode;

  /// Called when the pointer leaves the chart, legend included
  /// (`CartesianChart.tsx:749`).
  final VoidCallback? onChartMouseLeave;

  /// A widget layer mounted over the painted marks and under the popover.
  ///
  /// `EventsAnnotation` renders inside the series `<g>` as dashed lines plus
  /// label boxes that wrap their text against a measured width
  /// (`LineChart.tsx:1954-1961`, `eventAnnotation/Textbox.tsx:21-49`). Wrapping
  /// and laying out text is what a widget already does, so the band is a widget
  /// layer here rather than more painting; the paint order is unchanged. The
  /// builder is handed the same [FluentCartesianChildContext] and
  /// [FluentCartesianLayout] the delegate painted with, because
  /// `chartYTop = margins.top + eventLabelHeight` and `scale={props.xScale}`
  /// both come from them (`:1957-1959`).
  final Widget Function(
    BuildContext context,
    FluentCartesianChildContext childContext,
    FluentCartesianLayout layout,
  )?
  overlayBuilder;

  /// Called for every pointer move inside the plot, with the position local to
  /// the chart and the resolved scales.
  ///
  /// Hit regions serve the charts that hover a mark. AreaChart instead inverts
  /// the pointer's x through the scale and bisects its first series to find the
  /// nearest x (`AreaChart.tsx:185-192`), which no region can express, so the
  /// shell reports the raw position and leaves the resolution to the chart.
  /// Bound to pointer movement only, like upstream's `onMouseMove` and
  /// `onMouseOver` pair (`:703-705`).
  final void Function(Offset local, FluentCartesianChildContext childContext)?
  onPointerMoveInPlot;

  /// Style overrides layered over the theme-derived defaults.
  final FluentCartesianChartStyle? style;

  @override
  State<FluentCartesianChart> createState() => _FluentCartesianChartState();
}

/// Everything one solve produces.
class _CartesianGeometry {
  _CartesianGeometry({
    required this.layout,
    required this.xAxis,
    required this.yAxisPrimary,
    required this.yAxisSecondary,
    required this.xLabelLayout,
    required this.axisData,
  });

  final FluentCartesianLayout layout;
  final FluentAxisSpec xAxis;
  final FluentAxisSpec yAxisPrimary;
  final FluentAxisSpec? yAxisSecondary;
  final FluentXAxisLabelLayout? xLabelLayout;
  final FluentAxisData axisData;
}

class _FluentCartesianChartState extends State<FluentCartesianChart> {
  final FluentChartTextMeasurer _measurer = FluentChartTextMeasurer();

  /// The selection while [FluentCartesianChart.selectedLegends] is null.
  List<String> _selectedLegends = const <String>[];
  FocusNode? _internalFocusNode;
  List<FluentChartHitRegion> _regions = const <FluentChartHitRegion>[];
  int _focusedIndex = -1;
  int _hoveredIndex = -1;
  Offset _pointer = Offset.zero;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  /// `Legends.tsx:208` — a supplied selection is authoritative, so it wins over
  /// anything a click recorded here.
  ///
  /// ponytail: a chart that stops being controlled keeps the last controlled
  /// list rather than resetting, where upstream's effect would rewrite the
  /// internal map from an absent prop and clear it (`Legends.tsx:75-90`). No
  /// caller toggles the prop between null and non-null; if one ever does, clear
  /// `_selectedLegends` in `didUpdateWidget`.
  List<String> get _effectiveSelectedLegends =>
      widget.selectedLegends ?? _selectedLegends;

  @override
  void didUpdateWidget(FluentCartesianChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The measurer's cache key includes the resolved style, so a theme swap
    // does not poison it; a font-scale change still can.
    _measurer.invalidate();
  }

  @override
  void dispose() {
    _internalFocusNode?.dispose();
    super.dispose();
  }

  /// Circular left/right traversal over the delegate's hit regions.
  ///
  /// `useArrowNavigationGroup({ circular: true, axis: 'horizontal' })`
  /// (`CartesianChart.tsx:87`). Only the horizontal pair is bound: the source
  /// tree does not contain `@fluentui/react-tabster`, so whether Up and Down
  /// are swallowed there is unknown, and letting them fall through to an
  /// enclosing scroller is the behaviour that cannot trap a keyboard user.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _regions.isEmpty) {
      return KeyEventResult.ignored;
    }
    final step = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowRight => 1,
      LogicalKeyboardKey.arrowLeft => -1,
      _ => 0,
    };
    if (step == 0) {
      return KeyEventResult.ignored;
    }
    final count = _regions.length;
    setState(() {
      _focusedIndex = _focusedIndex < 0
          ? (step > 0 ? 0 : count - 1)
          : (_focusedIndex + step + count) % count;
    });
    return KeyEventResult.handled;
  }

  /// The region under [position], or -1.
  ///
  /// Walks backwards so a region painted later wins an overlap, matching the
  /// SVG hit-testing upstream relies on.
  int _regionAt(Offset position) {
    for (var i = _regions.length - 1; i >= 0; i--) {
      if (_regions[i].bounds.contains(position)) return i;
    }
    return -1;
  }

  void _onPointer(Offset position) {
    final index = _regionAt(position);
    // Only HorizontalBarChartWithAxis closes the callout when the pointer
    // leaves a mark (`HorizontalBarChartWithAxis.tsx:266-268`). Every other
    // per-mark leave handler is an empty stub — `VerticalBarChart.tsx:496-498`,
    // `VerticalStackedBarChart.tsx:802-804`, `HeatMapChart.tsx:166-168` — so
    // nothing fires in the gaps and the callout stays exactly where the last
    // mark left it, anchor included.
    if (index == -1 && !widget.props.closePopoverOnRegionExit) {
      return;
    }
    if (index == _hoveredIndex && position == _pointer) return;
    setState(() {
      _hoveredIndex = index;
      _pointer = position;
    });
  }

  /// Merges regions that share an index into one, in first-seen order.
  ///
  /// `isCalloutForStack` moves `tabIndex`, `aria-label` and every pointer
  /// handler off each rect and onto the stack's `<g>`
  /// (`VerticalStackedBarChart.tsx:1141-1153`), so the group is one stop over
  /// the union of its segments. The first region of each index wins the popover
  /// data and the narration, which is where a group-mode chart puts its
  /// stack-wide values (`:1146`, `:281-292`).
  static List<FluentChartHitRegion> _coalesceRegionsByIndex(
    List<FluentChartHitRegion> regions,
  ) {
    final merged = <int, FluentChartHitRegion>{};
    for (final region in regions) {
      final existing = merged[region.index];
      merged[region.index] = existing == null
          ? region
          : FluentChartHitRegion(
              bounds: existing.bounds.expandToInclude(region.bounds),
              index: existing.index,
              legend: existing.legend,
              popoverData: existing.popoverData,
              semanticsLabel: existing.semanticsLabel,
            );
    }
    return merged.values.toList(growable: false);
  }

  /// The popover layer: the built-in body, or the caller's.
  Widget _popoverLayer(FluentChartHitRegion active, Offset anchor) {
    final builder = widget.props.popoverBuilder;
    if (builder == null) {
      return FluentChartPopover(data: active.popoverData, anchor: anchor);
    }
    // `ChartPopover.tsx:54` renders `customizedCallout` in place of both
    // default bodies, inside a `PopoverSurface` that also supplies the 20px
    // offset at `:48`.
    // ponytail: the offset is reproduced but the surface's edge flipping is
    // not, because `FluentChartPopover`'s constructor is `{data, anchor, style}`
    // with no content slot to hand a custom body to. If a caller's body
    // overflows the right edge, replace this `Positioned` with a
    // `CustomSingleChildLayout` that measures the child first.
    return Stack(
      children: <Widget>[
        Positioned(
          left: anchor.dx + 20,
          top: anchor.dy + 20,
          child: builder(context),
        ),
      ],
    );
  }

  void _clearHover() {
    if (_hoveredIndex == -1) return;
    setState(() => _hoveredIndex = -1);
  }

  void _onFocusChange({required bool hasFocus}) {
    if (!hasFocus && _focusedIndex != -1) {
      setState(() => _focusedIndex = -1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final style = resolveFluentCartesianChartStyle(
      theme,
    ).merge(FluentCartesianChartTheme.maybeOf(context)).merge(widget.style);
    final colors = FluentChartColors.of(theme);
    final textStyles = FluentChartTextStyles.of(theme);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    // `MediaQuery.maybeOf` rather than `devicePixelRatioOf`, so a chart mounted
    // without an app shell still paints instead of throwing.
    final ratio = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1;
    // `offset = devicePixelRatio > 1 ? 0 : 0.5` (`d3-axis/src/axis.js:38`).
    final crispOffset = ratio > 1 ? 0.0 : 0.5;
    // `CartesianChart.tsx:912` gates the row on `!hideLegend`; an empty legend
    // list is gated too, because upstream's `legendBars` element is then empty
    // and collapses to no height, while a Flutter `Padding` would not.
    final showLegend = !widget.props.hideLegend && widget.legends.isNotEmpty;

    return MouseRegion(
      onExit: (_) => widget.onChartMouseLeave?.call(),
      child: LayoutBuilder(
        builder: (context, constraints) => SizedBox(
          height: constraints.hasBoundedHeight
              ? null
              : kFluentCartesianChartFallbackHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: _buildPlot(
                  style: style,
                  colors: colors,
                  textStyles: textStyles,
                  isRtl: isRtl,
                  crispOffset: crispOffset,
                ),
              ),
              if (showLegend)
                Padding(
                  padding:
                      style.legendRowPadding?.resolve(const <WidgetState>{}) ??
                      EdgeInsets.zero,
                  // The shell's gap is `legendRowPadding` above — upstream's
                  // `legendContainer` rule, `marginTop: spacingVerticalS` and
                  // `marginLeft: spacingHorizontalXL`
                  // (`useCartesianChartStyles.styles.ts:103-104`). The legend
                  // itself contributes none, so the strip reserves 8 + 32 = 40
                  // exactly as `CartesianChart.tsx:505-508` computes it.
                  child: FluentChartLegend(
                    legends: widget.legends,
                    selectionMode: widget.legendSelectionMode,
                    selectedLegends: _effectiveSelectedLegends,
                    onChange: (selected, _) {
                      // `Legends.tsx:248-249` — the internal store only moves
                      // in uncontrolled mode …
                      if (widget.selectedLegends == null) {
                        setState(() => _selectedLegends = selected);
                      }
                      // … but `:250` reports either way.
                      widget.onLegendChange?.call(selected);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlot({
    required FluentCartesianChartStyle style,
    required FluentChartColors colors,
    required FluentChartTextStyles textStyles,
    required bool isRtl,
    required double crispOffset,
  }) => LayoutBuilder(
    builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      // `enableFirstRenderOptimization` skips the whole solve while the box has
      // no usable size (`CartesianChart.tsx:190-191`). A degenerate box is
      // skipped either way — there is nothing to divide a range by.
      if (size.width <= 0 || size.height <= 0 || !size.isFinite) {
        return const SizedBox.expand();
      }
      final geometry = _solve(size: size, isRtl: isRtl, textStyles: textStyles);

      if (widget.props.reflowMode == FluentChartReflowMode.minWidth) {
        final minWidth = _minChartWidth(
          geometry: geometry,
          textStyles: textStyles,
        );
        if (minWidth > size.width) {
          final wide = Size(minWidth, size.height);
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox.fromSize(
              size: wide,
              child: _paint(
                geometry: _solve(
                  size: wide,
                  isRtl: isRtl,
                  textStyles: textStyles,
                ),
                size: wide,
                style: style,
                colors: colors,
                textStyles: textStyles,
                crispOffset: crispOffset,
              ),
            ),
          );
        }
      }

      return _paint(
        geometry: geometry,
        size: size,
        style: style,
        colors: colors,
        textStyles: textStyles,
        crispOffset: crispOffset,
      );
    },
  );

  Widget _paint({
    required _CartesianGeometry geometry,
    required Size size,
    required FluentCartesianChartStyle style,
    required FluentChartColors colors,
    required FluentChartTextStyles textStyles,
    required double crispOffset,
  }) {
    final childContext = FluentCartesianChildContext(
      xScale: geometry.xAxis.scale,
      yScalePrimary: geometry.yAxisPrimary.scale,
      yScaleSecondary: geometry.yAxisSecondary?.scale,
      containerWidth: geometry.layout.size.width,
      containerHeight: geometry.layout.size.height,
    );
    final regions = widget.delegate.buildHitRegions(
      childContext,
      geometry.layout,
    );
    _regions =
        widget.props.hitRegionGranularity == FluentChartHitGranularity.group
        ? _coalesceRegionsByIndex(regions)
        : regions;
    if (_hoveredIndex >= _regions.length) {
      _hoveredIndex = -1;
    }

    final description = buildFluentCartesianChartDescription(
      // `props.chartTitle || 'Chart. '` (`CartesianChart.tsx:553`). Each chart
      // composes its own count sentence and passes it down, so the prop wins
      // over the delegate's own title.
      chartTitle:
          widget.props.chartTitleForSemantics ?? widget.delegate.chartTitle,
      xAxisTitle: widget.props.xAxisTitle,
      xAxisType: widget.delegate.xAxisType,
      yAxisTitle: widget.props.yAxisTitle,
      yAxisType: widget.delegate.yAxisType,
      secondaryYAxisTitle: widget.props.secondaryYAxisTitle,
      hasSecondaryScale: widget.props.secondaryYScaleOptions != null,
    );
    final focused = _focusedIndex >= 0 && _focusedIndex < _regions.length
        ? _regions[_focusedIndex]
        : null;
    // Keyboard focus and pointer hover feed the same popover; focus wins,
    // because a keyboard user cannot also be hovering.
    final hovered = _hoveredIndex >= 0 && _hoveredIndex < _regions.length
        ? _regions[_hoveredIndex]
        : null;
    final active = focused ?? hovered;
    // A keyboard stop has no pointer, and GroupedVerticalBarChart hands
    // `Popover` the hovered bar element itself (`.tsx:437`, `:970`) where every
    // other chart builds a virtual element at the cursor
    // (`ChartPopover.tsx:23-40`).
    final anchorsToRegion =
        focused != null || widget.props.popoverAnchorsToRegion;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _onKey,
      onFocusChange: (hasFocus) => _onFocusChange(hasFocus: hasFocus),
      child: Semantics(
        container: true,
        label: focused?.semanticsLabel ?? description,
        child: Stack(
          children: <Widget>[
            MouseRegion(
              onHover: (event) {
                widget.onPointerMoveInPlot?.call(
                  event.localPosition,
                  childContext,
                );
                _onPointer(event.localPosition);
              },
              onExit: (_) => _clearHover(),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) => _onPointer(details.localPosition),
                child: CustomPaint(
                  size: size,
                  painter: FluentCartesianChartPainter(
                    layout: geometry.layout,
                    delegate: widget.delegate,
                    xAxis: geometry.xAxis,
                    yAxisPrimary: geometry.yAxisPrimary,
                    yAxisSecondary: geometry.yAxisSecondary,
                    xLabelLayout: geometry.xLabelLayout,
                    style: style,
                    colors: colors,
                    textStyles: textStyles,
                    measurer: _measurer,
                    crispOffset: crispOffset,
                    props: widget.props,
                  ),
                ),
              ),
            ),
            // Inside the series `<g>` upstream (`LineChart.tsx:1954`), so above
            // the marks and below both the annotation layer and the callout.
            if (widget.overlayBuilder != null)
              Positioned.fill(
                child: widget.overlayBuilder!(
                  context,
                  childContext,
                  geometry.layout,
                ),
              ),
            if (widget.props.annotations.isNotEmpty)
              // The layer is pointer-transparent by default
              // (`useCartesianChartStyles.styles.ts:109-111`).
              Positioned.fill(
                child: FluentChartAnnotationLayer(
                  annotations: widget.props.annotations,
                  context: FluentChartAnnotationContext(
                    plotRect: geometry.layout.plotRect,
                    chartSize: geometry.layout.size,
                    isRtl: geometry.layout.isRtl,
                    xScale: geometry.xAxis.scale,
                    yScalePrimary: geometry.yAxisPrimary.scale,
                    yScaleSecondary: geometry.yAxisSecondary?.scale,
                  ),
                ),
              ),
            if (active != null && !widget.props.hideTooltip)
              // The popover anchors to a zero-size virtual point at the cursor,
              // exactly as `ChartPopover.tsx:23-40` builds a
              // `PositioningVirtualElement` from `props.clickPosition`. It is
              // given the whole plot to place itself in.
              Positioned.fill(
                child: IgnorePointer(
                  // The container Semantics above has no explicit child nodes,
                  // so the popover's own text would be absorbed into its label
                  // and narrate the focused mark's values a second time. The
                  // hit region's `semanticsLabel` is the one narration.
                  child: ExcludeSemantics(
                    child: _popoverLayer(
                      active,
                      anchorsToRegion ? active.bounds.center : _pointer,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// `_calculateChartMinWidth` (`CartesianChart.tsx:534-550`).
  ///
  /// Upstream guards this with `_isFirstRender` because its tick labels only
  /// exist after a render; here they come from the solve that just ran, so the
  /// widened chart is re-solved in the same frame.
  double _minChartWidth({
    required _CartesianGeometry geometry,
    required FluentChartTextStyles textStyles,
  }) {
    final labels = geometry.xAxis.tickLabels;
    // "Adding 10px for padding on both sides" (`CartesianChart.tsx:535-536`).
    final labelWidth =
        calcMaxLabelWidthWithTransform(
          labels,
          wrapXAxisLabels: widget.props.wrapXAxisLables,
          rotateXAxisLabels: widget.props.rotateXAxisLables,
          showXAxisLabelsTooltip: widget.props.showXAxisLablesTooltip,
          xAxisType: widget.delegate.xAxisType,
          noOfCharsToTruncate: widget.props.noOfCharsToTruncate,
          style: textStyles.axisTick,
          measurer: _measurer,
        ) +
        10;
    final margins = geometry.layout.margins;
    var minWidth =
        (margins.left ?? 0) +
        (margins.right ?? 0) +
        labelWidth * (labels.length - 1);
    // The three vertical bar charts reserve one domain margin per side
    // (`CartesianChart.tsx:540-547`); `minDomainMargin` is a local 8 there and
    // `MIN_DOMAIN_MARGIN` at `utilities.ts:89`.
    if (widget.delegate.chartType == FluentChartType.groupedVerticalBarChart ||
        widget.delegate.chartType == FluentChartType.verticalBarChart ||
        widget.delegate.chartType == FluentChartType.verticalStackedBarChart) {
      minWidth += kMinDomainMargin * 2;
    }
    return minWidth;
  }

  /// Solves the geometry, twice when the left margin depends on the y tick
  /// labels.
  ///
  /// Upstream keeps `startFromX` in React state, so the left margin lands on
  /// render 2 (`CartesianChart.tsx:91-98`, `:120-127`, `:375`). The tick labels
  /// depend only on the y domain, tick count and rounding — never on the
  /// margins — so a second solve inside the same build reaches upstream's
  /// settled answer without a visible frame of the wrong one.
  _CartesianGeometry _solve({
    required Size size,
    required bool isRtl,
    required FluentChartTextStyles textStyles,
  }) {
    var geometry = _buildOnce(
      size: size,
      isRtl: isRtl,
      textStyles: textStyles,
      startFromX: 0,
    );
    if (widget.props.showYAxisLables) {
      final labels = geometry.axisData.yAxisTickText.map(
        (label) => widget.props.showYAxisLablesTooltip
            // `CartesianChart.tsx:152-153`.
            ? truncateString(label, widget.props.noOfCharsToTruncate)
            : label,
      );
      final startFromX = _measurer.longestWidth(labels, textStyles.axisTick);
      if (startFromX > 0) {
        geometry = _buildOnce(
          size: size,
          isRtl: isRtl,
          textStyles: textStyles,
          startFromX: startFromX,
        );
      }
    }
    return geometry;
  }

  _CartesianGeometry _buildOnce({
    required Size size,
    required bool isRtl,
    required FluentChartTextStyles textStyles,
    required double startFromX,
  }) {
    final props = widget.props;
    final delegate = widget.delegate;
    final margins = FluentCartesianMarginSolver.solve(
      props: props,
      startFromX: startFromX,
      isRtl: isRtl,
    );

    final xParams = FluentXAxisParams(
      domainNRangeValues: delegate.resolveXDomainRange(
        margins: delegate.domainMargins(size.width, margins) ?? margins,
        containerWidth: size.width,
        isRtl: isRtl,
        barWidth: delegate.barWidth,
        tickValues: props.tickValues,
      ),
      // parity: CartesianChart.tsx:209 subtracts a reserve that is still zero.
      containerHeight: size.height,
      containerWidth: size.width,
      margins: margins,
      showRoundOffXTickValues: props.showRoundOffXTickValues,
      xAxistickSize: props.xAxistickSize,
      tickPadding: props.resolvedXAxisTickPadding,
      xAxisCount: props.xAxisTickCount,
      xAxisPadding: delegate.xAxisPadding,
      xAxisInnerPadding: delegate.xAxisInnerPadding,
      xAxisOuterPadding: delegate.xAxisOuterPadding,
      // `CartesianChart.tsx:220` reads `props.xAxis?.tickLayout`; the delegate
      // hook is the fallback for a chart that sets it in code instead.
      hideTickOverlap: props.resolveHideTickOverlap(
        props.xAxis?.tickLayout ?? delegate.xAxisTickLayout,
      ),
      calcMaxLabelWidth: (labels) => calcMaxLabelWidthWithTransform(
        labels,
        wrapXAxisLabels: props.wrapXAxisLables,
        rotateXAxisLabels: props.rotateXAxisLables,
        showXAxisLabelsTooltip: props.showXAxisLablesTooltip,
        xAxisType: delegate.xAxisType,
        noOfCharsToTruncate: props.noOfCharsToTruncate,
        style: textStyles.axisTick,
        measurer: _measurer,
      ),
      xMinValue: props.xMinValue,
      xMaxValue: props.xMaxValue,
      tickStep: props.xAxis?.tickStep,
      tick0: props.xAxis?.tick0,
      tickText: props.xAxis?.tickText,
      // `:282`. Same bag as the three above; the delegate hook is the fallback.
      tickLayout: props.xAxis?.tickLayout ?? delegate.xAxisTickLayout,
    );

    final xAxis = switch (delegate.xAxisType) {
      FluentChartAxisType.date => createDateXAxis(
        xParams,
        delegate.tickParams,
        culture: delegate.culture,
        options: props.dateLocalizeOptions,
        timeFormatLocale: props.timeFormatLocale,
        customDateTimeFormatter: props.customDateTimeFormatter,
        useUtc: props.useUTC,
        chartType: delegate.chartType,
      ),
      FluentChartAxisType.category => createStringXAxis(
        xParams,
        delegate.tickParams,
        delegate.datasetForXAxisDomain ?? const <String>[],
        culture: delegate.culture,
      ),
      // `default:` in the switch at `CartesianChart.tsx:269-277` is numeric.
      FluentChartAxisType.numeric => createNumericXAxis(
        xParams,
        delegate.tickParams,
        delegate.chartType,
        culture: delegate.culture,
        scaleType: props.xScaleType,
      ),
    };

    final xLabelLayout = solveFluentCartesianXAxisLabels(
      props: props,
      xAxis: xAxis,
      xAxisType: delegate.xAxisType,
      // `:385`. Same resolution as the x params above.
      tickLayout: props.xAxis?.tickLayout ?? delegate.xAxisTickLayout,
      datasetForXAxisDomain: delegate.datasetForXAxisDomain,
      containerWidth: size.width,
      marginBottom: margins.bottom ?? 0,
      textStyle: textStyles.axisTick,
      measurer: _measurer,
    );
    final reserve = xLabelLayout?.reserveHeight ?? 0;

    final axisData = FluentAxisData();
    final yParams = FluentYAxisParams(
      margins: delegate.yDomainMargins(size.height) ?? margins,
      containerWidth: size.width,
      // `CartesianChart.tsx:298` — the REAL reserve, unlike the x params above.
      containerHeight: size.height - reserve,
      yAxisTickFormat: props.yAxisTickFormat,
      yAxisTickCount: props.yAxisTickCount,
      // `CartesianChart.tsx:311` passes it to both axis builds. Threaded
      // through the params bag rather than the delegate contract — see
      // [FluentYAxisParams.roundedTicks].
      roundedTicks: props.roundedTicks,
      yMinValue: props.yMinValue,
      yMaxValue: props.yMaxValue,
      // Hard-coded 10 at `CartesianChart.tsx:304`, overriding the 12 the
      // builder destructures at `utilities.ts:808`.
      //
      // parity: eventLabelHeight is deliberately NOT passed. `YAxisParams` at
      // `CartesianChart.tsx:295-312` omits both `eventAnnotationProps` and
      // `eventLabelHeight`, and no other caller sets them, so the reserve at
      // `utilities.ts:848` is dead upstream and the event labels overlap the
      // plot. `FluentCartesianChartProps.eventLabelHeight` documents it.
      tickPadding: 10,
      maxOfYVal: delegate.maxOfYVal ?? 0,
      yMinMaxValues: delegate.resolveYMinMax(),
      yAxisPadding: delegate.yAxisPadding ?? 0,
      tickValues: props.yAxisTickValues,
      tickStep: props.yAxis?.tickStep,
      tick0: props.yAxis?.tick0,
      tickText: props.yAxis?.tickText,
    );

    FluentAxisSpec? ySecondary;
    FluentAxisSpec yPrimary;
    if (delegate.yAxisType == FluentChartAxisType.category) {
      yPrimary = delegate.createStringYAxis(
        yParams,
        delegate.stringDatasetForYAxisDomain ?? const <String>[],
        axisData,
        isRtl: isRtl,
      );
    } else {
      final secondaryOptions = props.secondaryYScaleOptions;
      if (secondaryOptions != null) {
        // Built FIRST (`CartesianChart.tsx:351`), so the shared axisData ends
        // up holding the primary's values.
        ySecondary = delegate.createYAxis(
          FluentYAxisParams(
            // `:338` — the plain margins, never the y domain margins.
            margins: margins,
            containerWidth: size.width,
            containerHeight: size.height - reserve,
            yAxisTickFormat: props.yAxisTickFormat,
            yAxisTickCount: props.yAxisTickCount,
            roundedTicks: props.roundedTicks,
            yMinValue: secondaryOptions.yMinValue,
            yMaxValue: secondaryOptions.yMaxValue,
            tickPadding: 10,
            yMinMaxValues: delegate.resolveYMinMax(useSecondaryYScale: true),
            yAxisPadding: delegate.yAxisPadding ?? 0,
          ),
          axisData,
          isRtl: isRtl,
          isIntegralDataset: delegate.isIntegralDataset,
          useSecondaryYScale: true,
        );
      }
      yPrimary = delegate.createYAxis(
        yParams,
        axisData,
        isRtl: isRtl,
        isIntegralDataset: delegate.isIntegralDataset,
      );
    }

    return _CartesianGeometry(
      layout: FluentCartesianLayout.resolve(
        size: size,
        margins: margins,
        xAxisLabelReserve: reserve,
        isRtl: isRtl,
        startFromX: startFromX,
      ),
      xAxis: xAxis,
      yAxisPrimary: yPrimary,
      yAxisSecondary: ySecondary,
      xLabelLayout: xLabelLayout,
      axisData: axisData,
    );
  }
}
