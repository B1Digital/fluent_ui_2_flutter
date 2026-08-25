import 'package:flutter/widgets.dart';

/// The gap between the chart's outer box and its plot area, in logical pixels.
///
/// Ports `Margins` (`types/DataPoint.ts:37-54`). Upstream documents defaults of
/// left 40, right 20, top 20, bottom 35 on `IMargins` (`utilities.ts:141-162`),
/// but the defaults are applied by each chart's margin solve rather than by the
/// type, so every side stays null here.
///
/// This lives in `model/` and not in `axis/` or `cartesian/` because `margins`
/// is a public prop on every upstream chart, so the data model owns it and both
/// solvers import it.
@immutable
class FluentChartMargins {
  /// Creates a margin set. An omitted side is decided by the margin solve.
  const FluentChartMargins({this.left, this.right, this.top, this.bottom});

  /// The gap on the physical left edge.
  final double? left;

  /// The gap on the physical right edge.
  final double? right;

  /// The gap above the plot area.
  final double? top;

  /// The gap below the plot area.
  final double? bottom;

  /// This margin set with the named sides replaced.
  FluentChartMargins copyWith({
    double? left,
    double? right,
    double? top,
    double? bottom,
  }) => FluentChartMargins(
    left: left ?? this.left,
    right: right ?? this.right,
    top: top ?? this.top,
    bottom: bottom ?? this.bottom,
  );

  /// This margin set with [left] and [right] exchanged.
  ///
  /// Applied at step 4 of the five-step margin solve, **before** the user's own
  /// margins are merged over the result (spec section 3.3), so a right-to-left
  /// chart mirrors the computed reservation but honours an explicit user value
  /// on the side the user named.
  FluentChartMargins get mirrored =>
      FluentChartMargins(left: right, right: left, top: top, bottom: bottom);

  /// This margin set with every non-null side of [other] laid over it.
  ///
  /// The Dart spelling of `{...computed, ...props.margins}`: a side the caller
  /// left null keeps the computed value.
  FluentChartMargins mergeOverride(FluentChartMargins? other) {
    if (other == null) return this;
    return FluentChartMargins(
      left: other.left ?? left,
      right: other.right ?? right,
      top: other.top ?? top,
      bottom: other.bottom ?? bottom,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FluentChartMargins &&
      other.left == left &&
      other.right == right &&
      other.top == top &&
      other.bottom == bottom;

  @override
  int get hashCode => Object.hash(left, right, top, bottom);
}

/// The accessible naming a chart, a data point or a callout carries.
///
/// Ports `AccessibilityProps` (`types/DataPoint.ts:588-603`). The two `*By`
/// fields hold DOM element ids upstream; they are carried through so a caller
/// porting an existing configuration loses nothing, and the mark-level
/// semantics adapter decides what a Flutter `Semantics` node can actually do
/// with them.
@immutable
class FluentChartSemantics {
  /// Creates an accessible naming set.
  const FluentChartSemantics({this.label, this.labelledBy, this.describedBy});

  /// `aria-label` (`types/DataPoint.ts:591`).
  final String? label;

  /// `aria-labelledby` (`types/DataPoint.ts:596`).
  final String? labelledBy;

  /// `aria-describedby` (`types/DataPoint.ts:601`).
  final String? describedBy;
}

/// What `toImage` should produce.
///
/// Ports `ImageExportOptions` (`types/DataPoint.ts:844-849`).
@immutable
class FluentChartImageExportOptions {
  /// Creates an export request.
  const FluentChartImageExportOptions({
    this.width,
    this.height,
    this.scale = 1,
    this.background = const Color(0x00000000),
  });

  /// Target width in logical pixels, or null to use the chart's own width.
  final double? width;

  /// Target height in logical pixels, or null to use the chart's own height.
  final double? height;

  /// Device-pixel multiplier applied to the capture.
  ///
  /// 1 is upstream's fallback; `image-export-utils.ts:426-427` then applies the
  /// x and y scales **independently**, so a non-square [width]/[height] pair
  /// distorts the output. That is parity, not a bug to fix (spec section 5.4).
  final double scale;

  /// The colour painted behind the chart before capture. Transparent by
  /// default, spelled `0x00000000` because upstream leaves `background`
  /// unset and captures onto a transparent canvas.
  final Color background;
}

/// The imperative handle a chart exposes for image export.
///
/// Replaces the `Chart` interface (`types/DataPoint.ts:836-839`). Upstream's
/// `chartContainer` field is a DOM node with no Flutter analogue and is
/// dropped; what callers actually use it for is [toImage].
abstract interface class FluentChartHandle {
  /// Renders the chart to a `data:image/png;base64,…` string.
  Future<String> toImage([
    FluentChartImageExportOptions options =
        const FluentChartImageExportOptions(),
  ]);
}

/// Which scale an axis is built with.
///
/// Ports `AxisScaleType` (`types/DataPoint.ts:1085`). Upstream's `'default'`
/// becomes [auto] because `default` is a Dart keyword.
enum FluentAxisScaleType {
  /// `'default'` — linear, band or time, chosen from the data type.
  auto,

  /// `'log'` — base-10 logarithmic. Numeric axes on LineChart and ScatterChart
  /// only (`types/DataPoint.ts:1081-1083`).
  log,
}

/// How the x-axis tick labels are laid out.
///
/// Ports the `'default' | 'auto'` union on the x-axis prop
/// (`CartesianChart.types.ts:537`). It lives here rather than in
/// `axis/axis_types.dart` because both [FluentAxisConfig] in `model/` and the
/// x-axis parameters in `axis/` carry it, and `axis/` imports `model/` and
/// never the reverse.
enum FluentTickLayout {
  /// `'default'` — labels are drawn as measured, and overlapping ones are
  /// hidden rather than reflowed. Renamed because `default` is a Dart keyword.
  defaultLayout,

  /// `'auto'` — labels are wrapped, truncated and staggered across alternating
  /// levels to fit the available space (`CartesianChart.types.ts:530-533`).
  auto,
}

/// Explicit tick placement for one axis.
///
/// Ports `AxisProps` (`types/DataPoint.ts:1092-1130`) plus the one member
/// upstream intersects onto its x-axis prop rather than declaring on
/// `AxisProps`: `tickLayout` (`CartesianChart.types.ts:527-537`). Dart has no
/// intersection types, so [tickLayout] sits on this class for both axes; a y
/// axis is bare `AxisProps` upstream (`CartesianChart.types.ts:543`) and leaves
/// it at its default.
@immutable
class FluentAxisConfig {
  /// Creates a tick configuration.
  const FluentAxisConfig({
    this.tickStep,
    this.tick0,
    this.tickText,
    this.tickLayout = FluentTickLayout.defaultLayout,
  }) : assert(
         tickStep == null || tickStep is num || tickStep is String,
         'tickStep is `number | string` (types/DataPoint.ts:1114). The string '
         "arms are 'L<f>' for a linearly spaced log axis and 'M<n>' for a "
         'monthly date axis.',
       ),
       assert(
         tick0 == null || tick0 is num || tick0 is DateTime,
         'tick0 is `number | Date` (types/DataPoint.ts:1123).',
       );

  /// The step between ticks: a positive number, `'L<f>'`, or `'M<n>'`.
  final Object? tickStep;

  /// The reference value ticks are laid out from: a number or a [DateTime].
  final Object? tick0;

  /// Replacement label text, one entry per tick value.
  final List<String>? tickText;

  /// How this axis lays its tick labels out (`CartesianChart.types.ts:537`).
  ///
  /// Only the x axis honours it: `CartesianChart.tsx:220` forces
  /// `hideTickOverlap` off when it is [FluentTickLayout.auto], `:282` switches
  /// the label solver to the wrap-truncate-stagger path, and `:385` turns on
  /// the label tooltip. Both declarative adapters set it for a category x axis
  /// (`PlotlySchemaAdapter.ts:3977-3979`, `VegaLiteSchemaAdapter.ts:2318`,
  /// `:2721`); no upstream call site sets it on a y axis.
  final FluentTickLayout tickLayout;
}

/// How the categories on a band axis are ordered.
///
/// Ports `AxisCategoryOrder` (`types/DataPoint.ts:953-973`), which is a union of
/// sixteen string literals and a `string[]`. A sealed hierarchy rather than an
/// enum, because the `string[]` arm carries data.
sealed class FluentAxisCategoryOrder {
  /// Allows subclasses to be const.
  const FluentAxisCategoryOrder();

  /// The `string[]` arm: the caller names the order outright.
  const factory FluentAxisCategoryOrder.explicit(List<String> categories) =
      FluentAxisCategoryOrderExplicit;

  /// `'default'` — the ordering that predates custom ordering. Some charts treat
  /// it exactly as [data] (`types/DataPoint.ts:936-937`).
  static const FluentAxisCategoryOrder defaultOrder =
      FluentAxisCategoryOrderPreset('default');

  /// `'data'` — the order the categories arrive in.
  static const FluentAxisCategoryOrder data = FluentAxisCategoryOrderPreset(
    'data',
  );

  /// `'category ascending'` — alphanumeric.
  static const FluentAxisCategoryOrder categoryAscending =
      FluentAxisCategoryOrderPreset('category ascending');

  /// `'category descending'` — reverse alphanumeric.
  static const FluentAxisCategoryOrder categoryDescending =
      FluentAxisCategoryOrderPreset('category descending');

  /// `'total ascending'` — by the sum of each category's values.
  static const FluentAxisCategoryOrder totalAscending =
      FluentAxisCategoryOrderPreset('total ascending');

  /// `'total descending'` — by the sum of each category's values, reversed.
  static const FluentAxisCategoryOrder totalDescending =
      FluentAxisCategoryOrderPreset('total descending');

  /// `'min ascending'` — by each category's smallest value.
  static const FluentAxisCategoryOrder minAscending =
      FluentAxisCategoryOrderPreset('min ascending');

  /// `'min descending'` — by each category's smallest value, reversed.
  static const FluentAxisCategoryOrder minDescending =
      FluentAxisCategoryOrderPreset('min descending');

  /// `'max ascending'` — by each category's largest value.
  static const FluentAxisCategoryOrder maxAscending =
      FluentAxisCategoryOrderPreset('max ascending');

  /// `'max descending'` — by each category's largest value, reversed.
  static const FluentAxisCategoryOrder maxDescending =
      FluentAxisCategoryOrderPreset('max descending');

  /// `'sum ascending'` — identical to [totalAscending] upstream
  /// (`utilities.ts:2087-2088` maps both to `d3Sum`).
  static const FluentAxisCategoryOrder sumAscending =
      FluentAxisCategoryOrderPreset('sum ascending');

  /// `'sum descending'` — identical to [totalDescending].
  static const FluentAxisCategoryOrder sumDescending =
      FluentAxisCategoryOrderPreset('sum descending');

  /// `'mean ascending'` — by each category's arithmetic mean.
  static const FluentAxisCategoryOrder meanAscending =
      FluentAxisCategoryOrderPreset('mean ascending');

  /// `'mean descending'` — by each category's arithmetic mean, reversed.
  static const FluentAxisCategoryOrder meanDescending =
      FluentAxisCategoryOrderPreset('mean descending');

  /// `'median ascending'` — by each category's median.
  static const FluentAxisCategoryOrder medianAscending =
      FluentAxisCategoryOrderPreset('median ascending');

  /// `'median descending'` — by each category's median, reversed.
  static const FluentAxisCategoryOrder medianDescending =
      FluentAxisCategoryOrderPreset('median descending');

  /// The preset [value] names, or null when it names none.
  ///
  /// `VegaLiteSchemaAdapter.ts:1119` assembles `'${op} ${order}'` at runtime, so
  /// the string form has to resolve back to a preset.
  static FluentAxisCategoryOrder? parse(String value) => switch (value) {
    'default' => defaultOrder,
    'data' => data,
    'category ascending' => categoryAscending,
    'category descending' => categoryDescending,
    'total ascending' => totalAscending,
    'total descending' => totalDescending,
    'min ascending' => minAscending,
    'min descending' => minDescending,
    'max ascending' => maxAscending,
    'max descending' => maxDescending,
    'sum ascending' => sumAscending,
    'sum descending' => sumDescending,
    'mean ascending' => meanAscending,
    'mean descending' => meanDescending,
    'median ascending' => medianAscending,
    'median descending' => medianDescending,
    _ => null,
  };
}

/// One of the sixteen string-literal orderings.
final class FluentAxisCategoryOrderPreset extends FluentAxisCategoryOrder {
  /// Creates a preset carrying its exact upstream literal.
  const FluentAxisCategoryOrderPreset(this.upstreamName);

  /// The literal as it appears in `types/DataPoint.ts:953-973`.
  ///
  /// `sortAxisCategories` matches it against
  /// `(category|total|sum|min|max|mean|median) (ascending|descending)`
  /// (`utilities.ts:2044`), so the string, not the Dart identifier, is what
  /// drives the sort.
  final String upstreamName;
}

/// The `string[]` arm: an explicit category order.
final class FluentAxisCategoryOrderExplicit extends FluentAxisCategoryOrder {
  /// Creates an explicit ordering.
  const FluentAxisCategoryOrderExplicit(this.categories);

  /// The categories, in the order they should appear.
  ///
  /// `sortAxisCategories` (`utilities.ts:2053-2072`) emits the entries of this
  /// list that the data actually contains, deduplicated, then appends every
  /// remaining data category in enumeration order.
  final List<String> categories;
}
