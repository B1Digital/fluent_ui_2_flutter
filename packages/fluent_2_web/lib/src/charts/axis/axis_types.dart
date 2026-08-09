import 'package:flutter/foundation.dart';

import '../internal/d3/axis_geometry.dart' as d3;
import '../internal/d3/scale.dart' as d3;
import '../model/chart_common.dart';

/// The chart identities the axis builders branch on.
///
/// Ports `ChartTypes` (`utilities.ts:98-108`). Upstream declares the members in
/// the order `AreaChart, LineChart, VerticalBarChart, VerticalStackedBarChart,
/// GroupedVerticalBarChart, …`; the order below follows the cross-plan contract
/// instead. Nothing reads the ordinal — every upstream use is an identity
/// comparison such as `chartType === ChartTypes.GanttChart` — so the difference
/// is cosmetic and is recorded here so nobody "fixes" it back.
enum FluentChartType {
  /// `ChartTypes.AreaChart`.
  areaChart,

  /// `ChartTypes.LineChart`.
  lineChart,

  /// `ChartTypes.VerticalStackedBarChart`.
  verticalStackedBarChart,

  /// `ChartTypes.GroupedVerticalBarChart`.
  groupedVerticalBarChart,

  /// `ChartTypes.VerticalBarChart`.
  verticalBarChart,

  /// `ChartTypes.HeatMapChart`.
  heatMapChart,

  /// `ChartTypes.HorizontalBarChartWithAxis`.
  horizontalBarChartWithAxis,

  /// `ChartTypes.ScatterChart`.
  scatterChart,

  /// `ChartTypes.GanttChart`.
  ganttChart,
}

/// The smallest slack a bar chart leaves at each end of a band domain.
///
/// `MIN_DOMAIN_MARGIN` (`utilities.ts:89`). Re-declared as a file-local literal
/// by three charts (`GroupedVerticalBarChart.tsx:57`,
/// `VerticalBarChart.tsx:56`, `VerticalStackedBarChart.tsx:66`) and once more
/// anonymously by `CartesianChart.tsx:545`; declared once here.
const double kMinDomainMargin = 8;

/// The floor a donut's radius is clamped to. `MIN_DONUT_RADIUS`
/// (`utilities.ts:90`).
const double kMinDonutRadius = 1;

/// The reference date `generateDateTicks` falls back to when `tick0` is absent.
///
/// `DEFAULT_DATE_STRING` (`utilities.ts:91`). JavaScript parses a bare
/// `YYYY-MM-DD` as **UTC** midnight, so the Dart port must build it with
/// [DateTime.utc] rather than [DateTime.parse].
const String kDefaultDateString = '2000-01-01';

/// The per-line width a wrapped x label falls back to. `DEFAULT_WRAP_WIDTH`
/// (`utilities.ts:1110`).
const double kDefaultWrapWidth = 10;

// AUDIT CORRECTION — `kDefaultBarWidth` (16, `utilities.ts:1891`) and
// `kMinBarWidth` (1, `:1892`) are NOT declared here. Plan 02 declares both in
// `lib/src/charts/internal/chart_utils.dart:311` and `:316`, because
// `getBarWidth` consumes them at stage 4, one stage before this directory
// exists. Declaring them here as well would export the same name from two
// barrel-exported libraries and break `lib/fluent_2_web.dart`. The contract's
// §5.1 constant block is wrong on these two; the earlier owner wins. Any
// consumer writes `import '../internal/chart_utils.dart';`.

/// The default margin on a side that carries tick labels.
/// `DEFAULT_MARGIN_WITH_TICKS` (`CartesianChart.tsx:41`).
const double kDefaultMarginWithTicks = 40;

/// The default margin on a side that carries no tick labels.
/// `DEFAULT_MARGIN_NO_TICKS` (`CartesianChart.tsx:42`).
const double kDefaultMarginNoTicks = 20;

/// The extra horizontal margin a y-axis title claims.
/// `HORIZONTAL_MARGIN_FOR_YAXIS_TITLE` (`CartesianChart.tsx:38`).
const double kHorizontalMarginForYAxisTitle = 24;

/// The extra vertical margin an x-axis title claims.
/// `VERTICAL_MARGIN_FOR_XAXIS_TITLE` (`CartesianChart.tsx:39`).
const double kVerticalMarginForXAxisTitle = 20;

/// The gap between an axis title and the axis itself. `AXIS_TITLE_PADDING`
/// (`CartesianChart.tsx:40`).
const double kAxisTitlePadding = 8;

/// The height the legend strip is guaranteed. `minLegendContainerHeight`
/// (`CartesianChart.tsx:54`).
const double kMinLegendContainerHeight = 40;

/// The padding added to the longest numeric x label before the tick count is
/// reduced (`utilities.ts:298`).
const int kHideTickOverlapNumericPad = 20;

/// The padding added to the longest date x label before the tick count is
/// reduced (`utilities.ts:519`). Twice the numeric pad, deliberately.
const int kHideTickOverlapDatePad = 40;

/// The gap the band anti-collision sweep leaves between two kept labels
/// (`utilities.ts:616`).
const double kBandSweepGap = 10;

/// The ceiling `hideTickOverlap` clamps the reduced tick count to
/// (`utilities.ts:300`, `:521`).
const int kHideTickOverlapMaxTicks = 10;

/// A resolved domain and range pair for one axis.
///
/// Ports `IDomainNRange` (`utilities.ts:164-169`). The domain endpoints are
/// [Object] because they are a [num] on a numeric axis, a [DateTime] on a date
/// axis and an unused `0` on a band axis.
@immutable
class FluentChartDomainRange {
  /// Creates a domain and range pair.
  const FluentChartDomainRange({
    required this.dStartValue,
    required this.dEndValue,
    required this.rStartValue,
    required this.rEndValue,
  });

  /// The first domain endpoint. [num] or [DateTime].
  final Object dStartValue;

  /// The second domain endpoint. [num] or [DateTime].
  final Object dEndValue;

  /// The first range endpoint, in logical pixels.
  final double rStartValue;

  /// The second range endpoint, in logical pixels.
  final double rEndValue;
}

/// A numeric extent, as the `{ startValue, endValue }` bag upstream returns
/// from every `find*MinMaxOfY` (`utilities.ts:1591-1678`).
@immutable
class FluentChartMinMax {
  /// Creates a numeric extent.
  const FluentChartMinMax({required this.startValue, required this.endValue});

  /// The lower endpoint. May be [double.nan] when every value was filtered
  /// out, reproducing TypeScript's `d3Min(values)!` on an empty array.
  final double startValue;

  /// The upper endpoint, with the same not-a-number caveat as [startValue].
  final double endValue;
}

/// Everything a builder resolved for one axis, in place of upstream's DOM
/// mutation plus a bare scale return.
@immutable
class FluentAxisSpec {
  /// Creates a resolved axis description.
  const FluentAxisSpec({
    required this.scale,
    required this.tickValues,
    required this.tickLabels,
    required this.orientation,
    required this.tickSizeInner,
    required this.tickSizeOuter,
    required this.tickPadding,
  });

  /// The scale the marks are drawn through.
  final d3.Scale scale;

  /// The domain values a tick is drawn at. [num], [DateTime] or [String].
  final List<Object> tickValues;

  /// The rendered label for each entry of [tickValues], same length and order.
  final List<String> tickLabels;

  /// Which edge the axis sits on.
  final d3.FluentAxisOrientation orientation;

  /// The tick line length. A negative value is a gridline spanning the plot
  /// (`utilities.ts:308-310`, `:850`, `:989`).
  final double tickSizeInner;

  /// The end-cap length of the domain path. Upstream hides the path with CSS
  /// (`useCartesianChartStyles.styles.ts:73-75`) but the value is kept so the
  /// SVG-geometry oracle can assert it.
  final double tickSizeOuter;

  /// The gap between the tick line and its label.
  final double tickPadding;
}

/// The caller-supplied tick overrides. Ports `ITickParams`
/// (`utilities.ts:189-192`).
@immutable
class FluentTickParams {
  /// Creates a tick override bag.
  const FluentTickParams({this.tickValues, this.tickFormat});

  /// Explicit tick values, which win over every generated set.
  final List<Object>? tickValues;

  /// A d3-format specifier for numeric axes, or a strftime specifier for date
  /// axes.
  final String? tickFormat;
}

// POST-FREEZE RE-HOME — `enum FluentTickLayout { defaultLayout, auto }` is NOT
// declared here. It moved to `lib/src/charts/model/chart_common.dart:165`
// because `FluentAxisConfig` gained a `tickLayout` field
// (`CartesianChart.types.ts:527-537`) and `model/` lands at stage 3, before
// `axis/` at stage 5, so `model/` cannot import `axis/`. This file already
// imports `../model/chart_common.dart` above, so `FluentTickLayout` resolves
// with no new import and no `show`. Do not redeclare it: plan 02 exports
// `chart_common.dart` and this plan exports `axis_types.dart`, so two
// declarations are an ambiguous export in `lib/fluent_2_web.dart` and
// `dart analyze --fatal-infos` fails on both sides.

/// The x-axis builder input. Ports `IXAxisParams` (`utilities.ts:171-188`),
/// with the DOM handle (`xAxisElement`) dropped.
@immutable
class FluentXAxisParams {
  /// Creates an x-axis builder input.
  const FluentXAxisParams({
    required this.domainNRangeValues,
    required this.containerHeight,
    required this.containerWidth,
    required this.margins,
    this.showRoundOffXTickValues = false,
    // The tick line length upstream destructures (`utilities.ts:266`).
    this.xAxistickSize = 6,
    // The tick-to-label gap upstream destructures (`utilities.ts:267`).
    this.tickPadding = 10,
    this.xAxisCount,
    this.xAxisPadding,
    this.xAxisInnerPadding,
    this.xAxisOuterPadding,
    this.hideTickOverlap = false,
    this.calcMaxLabelWidth,
    this.xMinValue,
    this.xMaxValue,
    this.tickStep,
    this.tick0,
    this.tickText,
    this.tickLayout = FluentTickLayout.defaultLayout,
  });

  /// The pre-resolved domain and range, produced by `domain_range.dart`.
  final FluentChartDomainRange domainNRangeValues;

  /// The plot height the gridline override measures against.
  final double containerHeight;

  /// The plot width the band anti-collision sweep measures against.
  final double containerWidth;

  /// The resolved margins.
  final FluentChartMargins margins;

  /// Whether the numeric scale is passed through `nice()` (`utilities.ts:283`).
  /// The destructured default is `false`, but `CartesianChart.tsx:212` passes
  /// `?? true`, so every shell-driven numeric x axis is niced.
  final bool showRoundOffXTickValues;

  /// The tick line length. Destructures to `6` (`utilities.ts:266`, `:455`,
  /// `:572`) even though `CartesianChart.types.ts:316` documents `10`.
  final double xAxistickSize;

  /// The gap between tick and label. Destructures to `10` on numeric and band
  /// axes (`utilities.ts:267`, `:573`) and to `6` on the date axis (`:454`).
  final double tickPadding;

  /// The requested tick count, defaulting to `6` inside the builder
  /// (`utilities.ts:285`, `:470`).
  final int? xAxisCount;

  /// The shorthand band padding applied to both sides when neither
  /// [xAxisInnerPadding] nor [xAxisOuterPadding] is given. Defaults to `0.1`
  /// inside `createStringXAxis` (`utilities.ts:574`).
  final double? xAxisPadding;

  /// The band inner padding.
  final double? xAxisInnerPadding;

  /// The band outer padding.
  final double? xAxisOuterPadding;

  /// Whether the tick count is reduced until labels stop colliding
  /// (`utilities.ts:296-301`, `:518-522`, `:595-621`).
  final bool hideTickOverlap;

  /// Measures the widest of a label set. Wired to
  /// `calcMaxLabelWidthWithTransform` (`CartesianChart.tsx:576-612`).
  final double Function(List<String> labels)? calcMaxLabelWidth;

  /// A user floor for the numeric domain; it can only widen it
  /// (`utilities.ts:278` uses `Math.min`).
  final double? xMinValue;

  /// A user ceiling for the numeric domain; it can only widen it
  /// (`utilities.ts:279` uses `Math.max`).
  final double? xMaxValue;

  /// The tick spacing. [num] for a linear step, `'L<f>'` for a log step or
  /// `'M<n>'` for a month step (`utilities.ts:2465-2521`).
  final Object? tickStep;

  /// The tick anchor. [num] on a numeric axis, [DateTime] on a date axis.
  final Object? tick0;

  /// Explicit label overrides, indexed positionally.
  final List<String>? tickText;

  /// Which label-layout strategy applies.
  final FluentTickLayout tickLayout;
}

/// The y-axis builder input. Ports `IYAxisParams` (`utilities.ts:194-214`),
/// with the DOM handle dropped.
@immutable
class FluentYAxisParams {
  /// Creates a y-axis builder input.
  const FluentYAxisParams({
    required this.margins,
    required this.containerWidth,
    required this.containerHeight,
    // The empty extent upstream destructures (`utilities.ts:801`).
    this.yMinMaxValues = const FluentChartMinMax(startValue: 0, endValue: 0),
    // No user ceiling (`utilities.ts:803`).
    this.yMaxValue = 0,
    // No user floor (`utilities.ts:804`).
    this.yMinValue = 0,
    // The tick-to-label gap upstream destructures (`utilities.ts:808`).
    this.tickPadding = 12,
    // No chart-computed ceiling (`utilities.ts:809`).
    this.maxOfYVal = 0,
    // The target interval count upstream destructures (`utilities.ts:811`).
    this.yAxisTickCount = 4,
    this.yAxisTickFormat,
    // No band padding (`utilities.ts:964`).
    this.yAxisPadding = 0,
    this.tickValues,
    this.eventLabelHeight,
    this.tickStep,
    this.tick0,
    this.tickText,
  });

  /// The resolved margins.
  final FluentChartMargins margins;

  /// The plot width the full-width gridline measures against.
  final double containerWidth;

  /// The plot height the range is derived from.
  final double containerHeight;

  /// The data extent, as produced by a `find*MinMaxOfY`
  /// (`utilities.ts:801`).
  final FluentChartMinMax yMinMaxValues;

  /// A user ceiling for the domain (`utilities.ts:803`).
  final double yMaxValue;

  /// A user floor for the domain (`utilities.ts:804`).
  final double yMinValue;

  /// The gap between tick and label. Destructures to `12`
  /// (`utilities.ts:808`), but `CartesianChart.tsx:304` always passes `10`, so
  /// `10` is the effective value in every shell-driven chart.
  final double tickPadding;

  /// A chart-computed ceiling that wins over [yMinMaxValues]
  /// (`utilities.ts:809`).
  final double maxOfYVal;

  /// The target interval count handed to `prepareDatapoints`
  /// (`utilities.ts:811`).
  final int yAxisTickCount;

  /// A label override: either a `String Function(Object value, int index)` or a
  /// d3-format specifier [String] (`utilities.ts:865-877`).
  final Object? yAxisTickFormat;

  /// The band padding for the string y axes (`utilities.ts:964`).
  final double yAxisPadding;

  /// Explicit tick values, which win over the generated set.
  final List<Object>? tickValues;

  /// The height reserved above the plot for event-annotation labels
  /// (`utilities.ts:847`). Upstream gates this on `eventAnnotationProps` being
  /// present; the Dart port folds the gate into nullability, which is what
  /// `LineChart.tsx:165,179-181` produces anyway.
  // ponytail: one nullable field instead of a flag plus a height.
  final double? eventLabelHeight;

  /// The tick spacing, as on [FluentXAxisParams.tickStep].
  final Object? tickStep;

  /// The tick anchor, as on [FluentXAxisParams.tick0].
  final Object? tick0;

  /// Explicit label overrides, indexed positionally.
  final List<String>? tickText;
}

/// The mutable bag the y-axis builders write their resolved domain and labels
/// into.
///
/// Ports `IAxisData` (`utilities.ts:136-139`). Deliberately mutable: the shell
/// creates one instance and calls the builder twice — once for the primary
/// scale and once for the secondary — so the object ends up holding whichever
/// axis ran last (`CartesianChart.tsx:320-345`).
class FluentAxisData {
  /// The resolved y domain (`utilities.ts:889`).
  List<double> yAxisDomainValues = <double>[];

  /// The rendered y tick labels (`utilities.ts:890`).
  List<String> yAxisTickText = <String>[];
}
