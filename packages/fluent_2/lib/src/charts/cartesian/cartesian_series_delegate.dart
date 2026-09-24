import 'package:flutter/widgets.dart';

import '../axis/axis_types.dart';
import '../chrome/chart_popover.dart';
import '../internal/chart_colors.dart';
import '../internal/d3/scale.dart' as d3;
import '../model/chart_common.dart';
import '../model/chart_value.dart';
import 'cartesian_layout.dart';

/// One interactive area over the plot: a bar, a marker, a band, a cell.
///
/// Regions are what the roving keyboard index walks and what pointer hover
/// hit-tests against, so a chart declares them once instead of minting a
/// focusable widget per data point — design spec section 5.7.
@immutable
class FluentChartHitRegion {
  /// Creates a hit region.
  const FluentChartHitRegion({
    required this.bounds,
    required this.index,
    required this.legend,
    required this.popoverData,
    this.semanticsLabel,
    this.onActivate,
    this.popoverAnchor,
    this.hitTest,
    this.focusable = true,
    this.followsPointer,
  });

  /// The area, in plot coordinates.
  ///
  /// Also where a keyboard stop centres its popover, so a region with a
  /// [hitTest] keeps the mark's own box here.
  final Rect bounds;

  /// The region's position in the chart's own ordering, used by the roving
  /// index and by `aria-posinset`-style narration.
  final int index;

  /// The legend this region belongs to, so the legend highlight predicates can
  /// dim it.
  final String legend;

  /// What the popover shows when this region is hovered or focused, or null
  /// for a mark that opens none.
  ///
  /// A hover on such a mark still closes whatever popover is open: upstream's
  /// bar handlers run `setPopoverOpen(_noLegendHighlighted() ||
  /// _legendHighlighted(point.legend))` on entering a bar
  /// (`VerticalBarChart.tsx:479`, `GroupedVerticalBarChart.tsx:971`), so a bar
  /// another legend has dimmed shuts the callout rather than being a gap.
  final FluentChartPopoverData? popoverData;

  /// The narration for this region. Canvas-drawn text produces no semantics
  /// node at all, so a chart that wants narration must supply it here.
  final String? semanticsLabel;

  /// What a click or an Enter/Space on this region runs.
  ///
  /// Upstream hangs `onClick` off the mark itself and only when the caller
  /// supplied a handler, so a screen reader announces a mark as clickable
  /// exactly when it is (`LineChart.tsx:1697-1706`). A region is what the shell
  /// hit-tests first, so every `onDataPointClick` and `onBarClick` the models
  /// declare is dead until the region carries it. A mark with no box of its
  /// own — a line's stroke — goes through
  /// [FluentCartesianSeriesDelegate.activationAt] instead.
  final VoidCallback? onActivate;

  /// The mark the popover positions against, in plot coordinates, when it is
  /// not [bounds] — LineChart's 11px active marker inside its wider latch
  /// (`LineChart.tsx:1674-1676`, `:1888-1892`).
  ///
  /// Null anchors the popover to the pointer, or to [bounds] under
  /// `FluentCartesianChartProps.popoverAnchorsToRegion`.
  final Rect? popoverAnchor;

  /// Whether a pointer at a position in plot coordinates is on the mark, when
  /// the mark is not the whole of [bounds]; null hit-tests [bounds].
  ///
  /// SVG hit-tests the painted shape, so a `<circle>` is hovered and clicked
  /// as a circle and not as the square around it (`ScatterChart.tsx:445-466`),
  /// and a line point's target can take in the stroke leaving it.
  final bool Function(Offset position)? hitTest;

  /// Whether the roving keyboard index stops on this region.
  ///
  /// A mark another legend has dimmed takes no tab stop upstream
  /// (`tabIndex={shouldHighlight ? 0 : undefined}`, `VerticalBarChart.tsx:682`,
  /// `LineChart.tsx:592`), while its `onClick` stays on it, so a pointer can
  /// still click what the keyboard skips.
  final bool focusable;

  /// Whether the popover's anchor follows the pointer as it moves inside this
  /// region, or null to take the chart's
  /// `FluentCartesianChartProps.popoverFollowsPointer`.
  ///
  /// VerticalStackedBarChart's stacks and segments listen to `onMouseMove`
  /// while its line points only listen to `onMouseOver`
  /// (`VerticalStackedBarChart.tsx:622`, `:644`), so a callout opened on a dot
  /// stays where the pointer came in.
  final bool? followsPointer;

  /// Whether a pointer at [position], in plot coordinates, is on this region.
  bool contains(Offset position) =>
      hitTest?.call(position) ?? bounds.contains(position);

  /// [popoverData], [onActivate] and [hitTest] are deliberately excluded: all
  /// three carry closures — [FluentChartPopoverData.customContentBuilder] and
  /// the two callbacks themselves — minted afresh on every build, so folding
  /// them in would make every region unequal to its own rebuild and defeat the
  /// point of comparing regions at all.
  @override
  bool operator ==(Object other) =>
      other is FluentChartHitRegion &&
      other.bounds == bounds &&
      other.index == index &&
      other.legend == legend &&
      other.semanticsLabel == semanticsLabel &&
      other.popoverAnchor == popoverAnchor &&
      other.focusable == focusable &&
      other.followsPointer == followsPointer;

  @override
  int get hashCode => Object.hash(
    bounds,
    index,
    legend,
    semanticsLabel,
    popoverAnchor,
    focusable,
    followsPointer,
  );
}

/// The five values upstream's render prop hands each chart
/// (`CartesianChart.types.ts:569-579`, populated at
/// `CartesianChart.tsx:436-441`).
///
/// `optimizeLargeData` is the sixth field of that interface and is never
/// populated, which makes `LineChart.tsx:1945` a dead branch; it is not ported.
@immutable
class FluentCartesianChildContext {
  /// Creates a child context.
  const FluentCartesianChildContext({
    required this.xScale,
    required this.yScalePrimary,
    required this.containerWidth,
    required this.containerHeight,
    this.yScaleSecondary,
  });

  /// The x scale, shared between the axis and the series.
  final d3.Scale xScale;

  /// The primary y scale.
  final d3.Scale yScalePrimary;

  /// The secondary y scale, or null when no secondary axis exists.
  final d3.Scale? yScaleSecondary;

  /// The full plot width.
  final double containerWidth;

  /// The full plot height.
  ///
  /// This is the **unreduced** height: upstream passes `containerHeight` to
  /// `children()` at `CartesianChart.tsx:440` while passing
  /// `containerHeight - _removalValueForTextTuncate` to the axis params at
  /// `:209`. The asymmetry is reproduced — read
  /// [FluentCartesianLayout.plotContentHeight] for the reduced value.
  final double containerHeight;
}

/// The chart-supplied half of the shell.
///
/// Upstream is a React render prop plus four factory props on
/// `ModifiedCartesianChartProps`. Inverting it into a delegate keeps the
/// geometry solve in one place and the series painting in another, and it makes
/// a chart testable by feeding its delegate a [FluentCartesianLayout] with
/// nothing mounted — design spec section 3.3.
///
/// A concrete delegate normally holds the chart's own points *and* the handful
/// of `FluentCartesianChartProps` values its axis build interprets — the scale
/// types among them.
///
/// `roundedTicks` is deliberately **not** one of them. It used to be described
/// here as the delegate's to read, and the result was that no delegate read it:
/// the shell did not forward it, `createNumericYAxis` took an argument nobody
/// passed, and every chart silently took the unrounded arm. It now travels on
/// [FluentYAxisParams], which the shell fills and every delegate already hands
/// straight to the builder, so no delegate can drop it again.
abstract class FluentCartesianSeriesDelegate {
  /// Allows const subclasses.
  const FluentCartesianSeriesDelegate();

  /// Which of the nine shell consumers this is (`ChartTypes`,
  /// `utilities.ts:98-108`). Selects the gridline and band-width special cases.
  FluentChartType get chartType;

  /// The x-axis kind, which selects the x builder
  /// (`CartesianChart.tsx:237-278`).
  FluentChartAxisType get xAxisType;

  /// The y-axis kind. [FluentChartAxisType.category] routes to
  /// [createStringYAxis] (`CartesianChart.tsx:321`).
  FluentChartAxisType get yAxisType;

  /// `getDomainNRangeValues` (`CartesianChart.tsx:193-202`).
  FluentChartDomainRange resolveXDomainRange({
    required FluentChartMargins margins,
    required double containerWidth,
    required bool isRtl,
    required double? barWidth,
    required List<Object>? tickValues,
  });

  /// `getMinMaxOfYAxis` (`CartesianChart.tsx:306`, `:347`).
  FluentChartMinMax resolveYMinMax({bool useSecondaryYScale = false});

  /// `createYAxis` (`CartesianChart.tsx:351`, `:363`).
  ///
  /// Called twice when a secondary scale exists — secondary first, primary
  /// second — both writing into the same [FluentAxisData], so it ends up
  /// holding the **primary**'s values.
  FluentAxisSpec createYAxis(
    FluentYAxisParams params,
    FluentAxisData axisData, {
    required bool isRtl,
    required bool isIntegralDataset,
    bool useSecondaryYScale = false,
  });

  /// `createStringYAxis` (`CartesianChart.tsx:322-329`).
  FluentAxisSpec createStringYAxis(
    FluentYAxisParams params,
    List<String> dataPoints,
    FluentAxisData axisData, {
    required bool isRtl,
  });

  /// Adjusted margins for the x domain solve, or null to use the shell's
  /// (`CartesianChart.tsx:195`).
  ///
  /// [margins] is what the shell has just solved. Upstream reads it off a
  /// closure the chart filled from the `getmargins` callback one statement
  /// earlier (`CartesianChart.tsx:180`, `VerticalBarChart.tsx:326-328`), so a
  /// domain-margin solve that ignored it would drop the y-tick allowance out of
  /// the left margin it is supposed to widen.
  FluentChartMargins? domainMargins(
    double containerWidth,
    FluentChartMargins margins,
  ) => null;

  /// Adjusted margins for the primary y solve, or null to use the shell's
  /// (`CartesianChart.tsx:296`). The **secondary** axis never gets these
  /// (`:338`); that asymmetry is upstream's and is reproduced.
  FluentChartMargins? yDomainMargins(double containerHeight) => null;

  /// The band domain for a categorical x axis (`CartesianChart.tsx:264`).
  List<String>? get datasetForXAxisDomain => null;

  /// The band domain for a categorical y axis (`CartesianChart.tsx:324`).
  List<String>? get stringDatasetForYAxisDomain => null;

  /// AreaChart's precomputed y ceiling (`CartesianChart.tsx:305`).
  double? get maxOfYVal => null;

  /// Whether every y value is a whole number.
  ///
  /// `CartesianChart.tsx:66-68` computes `!points.some(p => p.y % 1 !== 0)` off
  /// the raw points, which only the chart can see. An empty series is integral,
  /// so the default is true.
  bool get isIntegralDataset => true;

  /// The bar width the x domain solve is given (`CartesianChart.tsx:200`).
  double? get barWidth => null;

  /// Explicit tick values and format handed to the x builders
  /// (`CartesianChart.tsx:239-267`).
  FluentTickParams get tickParams => const FluentTickParams();

  /// Fallback for `props.xAxis?.tickLayout` (`CartesianChart.tsx:220`, `:282`,
  /// `:385`).
  ///
  /// `FluentAxisConfig.tickLayout` is the primary source and the shell resolves
  /// `props.xAxis?.tickLayout ?? delegate.xAxisTickLayout` at all three sites,
  /// so a caller — or a declarative adapter, which sets
  /// `xAxis: FluentAxisConfig(tickLayout: FluentTickLayout.auto)` for every
  /// category x axis — wins. This hook stays for a chart that hardcodes the
  /// layout in Dart rather than taking it as a prop.
  FluentTickLayout get xAxisTickLayout => FluentTickLayout.defaultLayout;

  /// Shorthand band padding for the x axis (`CartesianChart.tsx:216`).
  double? get xAxisPadding => null;

  /// Inner band padding for the x axis (`CartesianChart.tsx:217`).
  double? get xAxisInnerPadding => null;

  /// Outer band padding for the x axis (`CartesianChart.tsx:218`).
  double? get xAxisOuterPadding => null;

  /// Band padding for a categorical y axis (`CartesianChart.tsx:310`).
  double? get yAxisPadding => null;

  /// BCP 47 tag used when formatting tick labels (`CartesianChart.tsx:169`).
  String? get culture => null;

  /// The narration prefix. Upstream uses `props.chartTitle` **only** for the
  /// SVG `aria-label` (`CartesianChart.tsx:554`) and never draws it; charts
  /// compose it themselves, e.g. `LineChart.tsx:1843-1846`.
  String? get chartTitle => null;

  /// Paints the marks.
  ///
  /// Strictly more information than upstream's `children(ChildProps)`: the
  /// layout arrives with the context, so no chart needs the `getmargins`
  /// closure-mutation side channel.
  void paintSeries(
    Canvas canvas,
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
    FluentChartColors colors,
  );

  /// The interactive areas over the plot, in paint order.
  List<FluentChartHitRegion> buildHitRegions(
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
  );

  /// The position in [regions] of the region a pointer hovering [position],
  /// in plot coordinates, shows the popover of, -1 over none, or null to
  /// hover the topmost region that [FluentChartHitRegion.contains] it.
  ///
  /// [regions] is what [buildHitRegions] last returned for [context], merged
  /// under `FluentChartHitGranularity.group`.
  ///
  /// A chart overrides this when what a hover shows is not what lies under
  /// the pointer. LineChart's segments hover their start point
  /// (`LineChart.tsx:1251-1278`), which no region can say without being a
  /// keyboard stop and a click target as well. The shell asks this on the
  /// same event it reports through `FluentCartesianChart.onPointerMoveInPlot`,
  /// of the delegate that built [regions], so the popover and the chart's own
  /// hover state move together.
  int? hoveredRegionAt(
    FluentCartesianChildContext context,
    List<FluentChartHitRegion> regions,
    Offset position,
  ) => null;

  /// What a click at [position], in plot coordinates, runs when it lands in
  /// none of the [buildHitRegions]; null runs nothing.
  ///
  /// For a clickable mark that is no box: LineChart's stroke, which upstream
  /// makes clickable by spreading `onLineClick` onto the `<path>` and `<line>`
  /// it draws (`LineChart.tsx:731`, `:1287`). A region is also a roving stop
  /// and a popover; this is the click alone, so the keyboard does not reach
  /// it.
  VoidCallback? activationAt(
    FluentCartesianChildContext context,
    Offset position,
  ) => null;
}
