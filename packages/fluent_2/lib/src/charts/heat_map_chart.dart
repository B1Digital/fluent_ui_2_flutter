import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import '../l10n/l10n.dart';
import 'axis/axis_builders.dart' as builders;
import 'axis/axis_types.dart';
import 'axis/domain_range.dart';
import 'axis/tick_format.dart';
import 'cartesian/cartesian_chart.dart';
import 'cartesian/cartesian_chart_props.dart';
import 'cartesian/cartesian_layout.dart';
import 'cartesian/cartesian_series_delegate.dart';
import 'chrome/chart_popover.dart';
import 'chrome/chart_title.dart';
import 'chrome/legend.dart';
import 'heat_map_chart_style.dart';
import 'internal/chart_colors.dart';
import 'internal/chart_text_measurer.dart';
import 'internal/chart_utils.dart';
import 'internal/d3/format.dart' as d3;
import 'internal/d3/js_math.dart' as d3;
import 'internal/d3/stable_sort.dart';
import 'internal/d3/time_format.dart' as d3;
import 'model/chart_common.dart';
import 'model/chart_value.dart';
import 'model/heatmap_data.dart';

/// One heat-map cell, matched or synthesised.
@immutable
class FluentHeatMapCell {
  /// Creates a cell.
  const FluentHeatMapCell({
    required this.x,
    required this.y,
    required this.value,
    required this.rectText,
    required this.legend,
    required this.isPlaceholder,
    this.ratio,
    this.descriptionMessage,
    this.onTap,
    this.semantics,
  });

  /// The formatted x label.
  final String x;

  /// The formatted y label.
  final String y;

  /// The cell value, `double.nan` for a placeholder.
  final double value;

  /// The painted text — a `num` or a [String]
  /// (`types/DataPoint.ts:855-858`).
  final Object rectText;

  /// The owning series legend, empty for a placeholder.
  final String legend;

  /// Whether this cell is a synthesised miss (`HeatMapChart.tsx:250-278`).
  final bool isPlaceholder;

  /// Optional numerator/denominator shown in the popover.
  final (double, double)? ratio;

  /// Optional trailing popover paragraph.
  final String? descriptionMessage;

  /// Tap handler.
  final VoidCallback? onTap;

  /// Accessible overrides.
  final FluentChartSemantics? semantics;
}

/// The reshaped heat-map grid.
@immutable
class FluentHeatMapDataSet {
  /// Creates a data set.
  const FluentHeatMapDataSet({
    required this.rows,
    required this.xAxisPoints,
    required this.yAxisPoints,
  });

  /// Cells keyed by formatted y label, then by formatted x label.
  final Map<String, Map<String, FluentHeatMapCell>> rows;

  /// Ordered, formatted x labels.
  final List<String> xAxisPoints;

  /// Ordered, formatted y labels.
  final List<String> yAxisPoints;

  /// The cell at ([x], [y]), or null when neither a match nor a placeholder
  /// exists.
  FluentHeatMapCell? cellAt(String x, String y) => rows[y]?[x];
}

/// Ports `_createNewDataSet` (`HeatMapChart.tsx:466-590`) plus the ordering
/// pipeline at `:641-731`.
///
/// Upstream keys a mutable map, re-keys it with the formatted label while
/// leaving the original key in place (`:553-561`) and then walks it with an
/// index cursor that only advances on a match (`:197`). This port builds the
/// grid up front and looks cells up by key, which is observationally identical
/// and cannot mis-align — the cursor's only purpose was to avoid an O(n²) scan
/// over a list that was already sorted.
///
/// Upstream keys, sorts and only then formats, so both orderings run on the raw
/// value: a date or numeric axis on `+a - +b` over the epoch-millisecond or
/// numeric index key (`:645-646`, `:660-661`, built by `_getXIndex` at
/// `:358-368`), and a category axis on the raw label before any
/// `xAxisStringFormatter` sees it (`:648`). This port keys by the formatted
/// label — the grid is looked up by it — and carries the first raw value behind
/// each key so both comparisons are still made on the raw. The one surviving
/// difference is that two raws sharing a formatted label merge into one column
/// here and stay two upstream.
///
/// The axis type is derived here rather than passed in, mirroring `:744-746`:
/// it decides which of the two ordering paths an axis takes, and the delegate's
/// `xAxisType`/`yAxisType` are both `category` unconditionally because the band
/// scale is built from formatted strings whatever the data was.
FluentHeatMapDataSet buildFluentHeatMapDataSet({
  required List<FluentHeatMapChartData> data,
  required FluentAxisCategoryOrder? xAxisCategoryOrder,
  required FluentAxisCategoryOrder? yAxisCategoryOrder,
  required bool alphabeticalSort,
  String? xAxisDateFormat,
  String? yAxisDateFormat,
  String? xAxisNumberFormat,
  String? yAxisNumberFormat,
  String Function(String)? xAxisStringFormatter,
  String Function(String)? yAxisStringFormatter,
  String placeholderText = 'No data available',
}) {
  String formatKey(
    Object raw, {
    required String? dateFormat,
    required String? numberFormat,
    required String Function(String)? stringFormatter,
  }) {
    if (raw is DateTime) {
      // The '%b/%d' default at HeatMapChart.tsx:595.
      return d3.timeFormat(dateFormat ?? '%b/%d')(raw);
    }
    if (raw is num) {
      // The '.2~s' default at HeatMapChart.tsx:599.
      return d3.format(numberFormat ?? '.2~s')(raw);
    }
    return (stringFormatter ?? (String s) => s)(raw as String);
  }

  final rows = <String, Map<String, FluentHeatMapCell>>{};
  // `_mapCategoryToValues` (HeatMapChart.tsx:719-731). Dart maps enumerate in
  // insertion order, so `keys` is also upstream's `uniqueXPoints` /
  // `uniqueYPoints` key order (`:498-499`) and no separate list is needed.
  final xValues = <String, List<double>>{};
  final yValues = <String, List<double>>{};
  // The raw value behind each formatted key — upstream's `uniqueXPoints` /
  // `uniqueYPoints` key itself (`_getXIndex`, `:358-368`), which is what both
  // legacy comparators at `:641-668` sort on.
  final xRaw = <String, Object>{};
  final yRaw = <String, Object>{};

  // `_getXandY` (`:111-122`). The `return` inside its `forEach` continues the
  // loop rather than breaking it, so the probe is the LAST non-empty series'
  // first point; with no data at all it stays `''`, which `getTypeOfAxis`
  // reports as a category axis.
  Object xProbe = '';
  Object yProbe = '';
  for (final series in data) {
    if (series.data.isNotEmpty) {
      xProbe = series.data.first.x;
      yProbe = series.data.first.y;
    }
  }
  final xAxisType = chartAxisTypeOf(xProbe);
  final yAxisType = chartAxisTypeOf(yProbe);

  for (final series in data) {
    for (final point in series.data) {
      final xKey = formatKey(
        point.x,
        dateFormat: xAxisDateFormat,
        numberFormat: xAxisNumberFormat,
        stringFormatter: xAxisStringFormatter,
      );
      final yKey = formatKey(
        point.y,
        dateFormat: yAxisDateFormat,
        numberFormat: yAxisNumberFormat,
        stringFormatter: yAxisStringFormatter,
      );
      (xValues[xKey] ??= <double>[]).add(point.value);
      (yValues[yKey] ??= <double>[]).add(point.value);
      xRaw[xKey] ??= point.x;
      yRaw[yKey] ??= point.y;
      (rows[yKey] ??= <String, FluentHeatMapCell>{})[xKey] = FluentHeatMapCell(
        x: xKey,
        y: yKey,
        value: point.value,
        rectText: point.rectText ?? point.value,
        legend: series.legend,
        isPlaceholder: false,
        ratio: point.ratio,
        descriptionMessage: point.descriptionMessage,
        onTap: point.onClick,
        semantics: point.callOutSemantics,
      );
    }
  }

  List<String> order(
    Map<String, List<double>> values,
    Map<String, Object> raws,
    FluentChartAxisType axisType,
    FluentAxisCategoryOrder? categoryOrder,
  ) {
    // `_xAxisType.current === XAxisTypes.StringAxis && props.xAxisCategoryOrder
    // !== 'default'` (HeatMapChart.tsx:711-717). BOTH halves gate this branch:
    // a date or numeric axis never reaches `sortAxisCategories` at all, whatever
    // the order says.
    //
    // A null order is upstream's ABSENT prop, and `undefined !== 'default'` is
    // true — HeatMapChart's `props = { xAxisCategoryOrder: 'default', … }`
    // (`:49-56`) is a parameter default that only fires when React passes no
    // props object, which it never does. So an unset prop on a category axis
    // takes this branch, not the legacy `sortOrder` one below, and
    // `sortAxisCategories`' undefined arm hands back the keys in insertion
    // order.
    if (axisType == FluentChartAxisType.category &&
        (categoryOrder is! FluentAxisCategoryOrderPreset ||
            categoryOrder.upstreamName != 'default')) {
      return sortAxisCategories(values, categoryOrder);
    }
    // A stable sort is required so that a comparator returning 0 preserves
    // insertion order, which is how `sortOrder: 'none'` keeps it.
    return stableSort<String>(values.keys.toList(), (a, b) {
      if (axisType != FluentChartAxisType.category) {
        // `+a - +b` (`:645-646`) over the raw index key: epoch milliseconds on
        // a date axis, the number itself on a numeric one. Reproduced as a
        // subtraction, not a `compareTo`, so that a non-finite difference is
        // the 0 that `Array.prototype.sort` reads it as.
        final diff = _ordinalOf(raws[a]!) - _ordinalOf(raws[b]!);
        return diff.isNaN ? 0 : diff.sign.toInt();
      }
      // `sortOrder === 'none' ? 0 : a.toLowerCase() > b.toLowerCase() ? 1 : -1`
      // (`:648`), over the raw label — upstream formats only after this sort.
      if (!alphabeticalSort) {
        return 0;
      }
      return '${raws[a]}'.toLowerCase().compareTo('${raws[b]}'.toLowerCase()) >
              0
          ? 1
          : -1;
    });
  }

  final xAxisPoints = order(xValues, xRaw, xAxisType, xAxisCategoryOrder);
  final yAxisPoints = order(yValues, yRaw, yAxisType, yAxisCategoryOrder);

  for (final y in yAxisPoints) {
    final row = rows[y] ??= <String, FluentHeatMapCell>{};
    for (final x in xAxisPoints) {
      row[x] ??= FluentHeatMapCell(
        x: x,
        y: y,
        value: double.nan,
        // The literal at HeatMapChart.tsx:255, which the widget hands over
        // already localized.
        rectText: placeholderText,
        legend: '',
        isPlaceholder: true,
      );
    }
  }

  return FluentHeatMapDataSet(
    rows: rows,
    xAxisPoints: xAxisPoints,
    yAxisPoints: yAxisPoints,
  );
}

/// The number `+raw` coerces to in `_getXIndex`/`_getYIndex`'s index key
/// (`HeatMapChart.tsx:358-380`): epoch milliseconds for a date, the value for a
/// number, and `NaN` for anything else — which only a category axis produces,
/// and a category axis never reaches this.
double _ordinalOf(Object raw) => switch (raw) {
  final DateTime d => d.millisecondsSinceEpoch.toDouble(),
  final num n => n.toDouble(),
  _ => double.nan,
};

/// The heat-map colour ramp.
///
/// Ports `_getColorScale` (`HeatMapChart.tsx:351-356`): a `scaleLinear` whose
/// range is colour strings, which d3 dispatches to `interpolateRgb` (gamma 1),
/// piecewise for more than two stops and **unclamped**, so values outside the
/// domain extrapolate rather than saturate.
Color fluentHeatMapColourAt(
  double value, {
  required List<double> domain,
  required List<Color> range,
}) {
  if (range.isEmpty) {
    return const Color(0x00000000);
  }
  if (range.length == 1 || domain.length < 2) {
    return range.first;
  }
  var i = 1;
  while (i < domain.length - 1 && value > domain[i]) {
    i++;
  }
  final span = domain[i] - domain[i - 1];
  final t = span == 0 ? 0.0 : (value - domain[i - 1]) / span;
  final a = range[i - 1];
  final b = range[math.min(i, range.length - 1)];
  // Unclamped lerp: t may fall outside [0, 1], so the clamp is on the channel
  // and not on t. `roundToDouble` rounds half away from zero, which is what
  // JavaScript's `Math.round` does for the non-negative channels d3-color
  // serialises.
  double channel(double lo, double hi) =>
      (lo + (hi - lo) * t).clamp(0, 255).roundToDouble();
  return Color.fromARGB(
    255,
    channel(a.r * 255, b.r * 255).toInt(),
    channel(a.g * 255, b.g * 255).toInt(),
    channel(a.b * 255, b.b * 255).toInt(),
  );
}

/// One placed cell: the band rect, the colours it resolved to, and the cell.
///
/// Upstream's `<g>` carries the opacity while its `<rect>` carries the fill and
/// its `<text>` the foreground (`HeatMapChart.tsx:216-249`), so all four travel
/// together.
typedef FluentHeatMapCellGeometry = ({
  Rect rect,
  Color fill,
  Color foreground,
  double opacity,
  FluentHeatMapCell cell,
});

/// Renders heat-map cells into the shared cartesian shell.
///
/// Ports `HeatMapChart.tsx` (824 lines). Both axes are band scales at padding
/// 0.02; the y range is reversed, which `ScaleBand` handles by swapping start
/// and stop and reversing the emitted values.
class FluentHeatMapChartDelegate extends FluentCartesianSeriesDelegate {
  /// Creates a delegate.
  const FluentHeatMapChartDelegate({
    required this.dataSet,
    required this.style,
    required this.colors,
    required this.measurer,
    required this.domainValues,
    required this.rangeValues,
    required this.selectedLegend,
    this.activeLegend,
    this.culture,
  });

  /// The reshaped grid.
  final FluentHeatMapDataSet dataSet;

  /// The resolved style.
  final FluentHeatMapChartStyle style;

  /// Resolved chart colours.
  final FluentChartColors colors;

  /// The chart subtree's single text measurer.
  final FluentChartTextMeasurer measurer;

  /// Colour-scale domain stops.
  final List<double> domainValues;

  /// Colour-scale range stops.
  final List<Color> rangeValues;

  /// The selected legend, empty for none — HeatMap uses the single-select
  /// highlight model (`HeatMapChart.tsx:608-610`).
  final String selectedLegend;

  /// The hovered legend, empty for none.
  final String? activeLegend;

  /// BCP-47 locale for cell text.
  @override
  final String? culture;

  @override
  FluentChartType get chartType => FluentChartType.heatMapChart;

  @override
  FluentChartAxisType get xAxisType => FluentChartAxisType.category;

  @override
  FluentChartAxisType get yAxisType => FluentChartAxisType.category;

  @override
  List<String>? get datasetForXAxisDomain => dataSet.xAxisPoints;

  @override
  List<String>? get stringDatasetForYAxisDomain => dataSet.yAxisPoints;

  // The two band paddings the shell hard-codes for HeatMap upstream
  // (`HeatMapChart.tsx:807-808`). They are delegate PULL-HOOKS, not
  // `FluentCartesianChartProps` fields — the props bag declares neither and its
  // `copyWith` accepts neither. The shell reads them at
  // `xAxisPadding: delegate.xAxisPadding` and
  // `yAxisPadding: delegate.yAxisPadding ?? 0`.
  @override
  double? get xAxisPadding => 0.02;

  @override
  double? get yAxisPadding => 0.02;

  @override
  FluentChartDomainRange resolveXDomainRange({
    required FluentChartMargins margins,
    required double containerWidth,
    required bool isRtl,
    required double? barWidth,
    required List<Object>? tickValues,
  }) => domainRangeOfXStringAxis(margins, containerWidth, isRtl: isRtl);

  @override
  FluentChartMinMax resolveYMinMax({bool useSecondaryYScale = false}) =>
      // `getMinMaxOfYAxis: () => ({ startValue: 0, endValue: 0 })`
      // (`HeatMapChart.tsx:804`).
      const FluentChartMinMax(startValue: 0, endValue: 0);

  @override
  FluentAxisSpec createYAxis(
    FluentYAxisParams params,
    FluentAxisData axisData, {
    required bool isRtl,
    required bool isIntegralDataset,
    bool useSecondaryYScale = false,
  }) =>
      // Handed to the shell but never invoked, because yAxisType is category
      // (`HeatMapChart.tsx:799` still passes `createYAxis={createNumericYAxis}`
      // alongside the string builder).
      builders.createNumericYAxis(
        params,
        axisData,
        isRtl: isRtl,
        isIntegralDataset: isIntegralDataset,
        chartType: FluentChartType.heatMapChart,
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
    chartType: FluentChartType.heatMapChart,
  );

  /// Ports `_getOpacity` (`HeatMapChart.tsx:128-131`).
  double opacityFor(String legend) {
    final none =
        selectedLegend.isEmpty &&
        (activeLegend == null || activeLegend!.isEmpty);
    return none ||
            isLegendHighlightedSingle(
              legend,
              selectedLegend: selectedLegend,
              activeLegend: activeLegend,
            )
        ? 1
        : style.cellOpacity!.resolve(<WidgetState>{WidgetState.disabled})!;
  }

  /// Whether a cell of [legend] may open the popover.
  ///
  /// `setPopoverOpen(selectedLegend === '' || selectedLegend === data.legend)`
  /// (`HeatMapChart.tsx:139`, `:154`). Note this reads the **selection** alone,
  /// where [opacityFor] also reads the hover, so a hover-dimmed cell still
  /// opens its popover.
  bool opensPopoverFor(String legend) =>
      selectedLegend.isEmpty || selectedLegend == legend;

  /// Resolves every cell, top row first.
  List<FluentHeatMapCellGeometry> cellsFor(
    FluentCartesianChildContext context,
  ) {
    final baseForeground = colors.axisText;
    final threshold = style.contrastThreshold!.resolve(<WidgetState>{})!;
    final out = <FluentHeatMapCellGeometry>[];
    // `slice().reverse()` at HeatMapChart.tsx:186 puts the top row first.
    for (final y in dataSet.yAxisPoints.reversed) {
      for (final x in dataSet.xAxisPoints) {
        final cell = dataSet.cellAt(x, y);
        if (cell == null) {
          continue;
        }
        final left = context.xScale(x);
        final top = context.yScalePrimary(y);
        if (left == null || top == null) {
          continue;
        }
        final fill = cell.isPlaceholder
            // The miss rect is literally `fill="transparent"` (`:273`).
            ? const Color(0x00000000)
            : colors.flattenMark(
                fluentHeatMapColourAt(
                  cell.value,
                  domain: domainValues,
                  range: rangeValues,
                ),
              );
        var foreground = baseForeground;
        if (!cell.isPlaceholder &&
            fluentColorContrast(baseForeground, fill) < threshold) {
          // `_getInvertedTextColor` (`:174-176`) maps colorNeutralForeground1
          // to colorNeutralBackground1, which is the slot
          // `FluentChartColors.surface` already holds — the same pair
          // `fluentInvertedTextColor` would return for `colors.axisText`.
          foreground = colors.surface;
        }
        assert(() {
          // ignore: avoid_print
          print(
            'PROBE yrange=${context.yScalePrimary.range} '
            'xrange=${context.xScale.range} '
            'bh=${context.yScalePrimary.bandwidth}',
          );
          return true;
        }());
        out.add((
          rect: Rect.fromLTWH(
            left,
            top,
            context.xScale.bandwidth,
            context.yScalePrimary.bandwidth,
          ),
          fill: fill,
          foreground: foreground,
          // parity: the miss `<g>` carries NO fillOpacity (`:262-277`), so a
          // dimmed legend leaves the placeholders at full strength.
          opacity: cell.isPlaceholder ? 1 : opacityFor(cell.legend),
          cell: cell,
        ));
      }
    }
    return out;
  }

  @override
  void paintSeries(
    Canvas canvas,
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
    FluentChartColors colours,
  ) {
    final base = style.cellTextStyle!.resolve(<WidgetState>{})!;
    for (final placed in cellsFor(context)) {
      canvas.drawRect(
        placed.rect,
        Paint()
          ..color = placed.fill.withValues(
            alpha: placed.fill.a * placed.opacity,
          ),
      );
      if (placed.cell.isPlaceholder) {
        // No text at all on a miss (`HeatMapChart.tsx:262-277`).
        continue;
      }
      final text = formatToLocaleString(placed.cell.rectText, culture: culture);
      // Measured in the uncoloured style: the fill never moves a glyph, and
      // keying the cache on it would mint an entry per opacity.
      final metrics = measurer.measure(text, base);
      final painter = measurer.layoutPainter(
        text,
        base.copyWith(
          color: placed.foreground.withValues(alpha: placed.opacity),
        ),
      );
      // `dominantBaseline="middle"` and `textAnchor="middle"` about the band
      // centre (`:236-245`). `middle` is the midpoint of the alphabetic
      // baseline and the x-height, not the em box, so the offset comes from
      // the metrics rather than from half the height.
      painter.paint(
        canvas,
        Offset(
          placed.rect.center.dx - metrics.width / 2,
          placed.rect.center.dy +
              fluentChartBaselineOffset(
                FluentChartTitleBaseline.middle,
                metrics,
              ) -
              metrics.ascent,
        ),
      );
      painter.dispose();
    }
  }

  @override
  List<FluentChartHitRegion> buildHitRegions(
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
  ) {
    final regions = <FluentChartHitRegion>[];
    for (final placed in cellsFor(context)) {
      // A cell whose legend is not the selected one neither opens the popover
      // (`:154`) nor keeps its tab stop (`tabIndex={… ? 0 : -1}`, `:224` and
      // `:262`), so it is not a region at all.
      //
      // parity: the tab-stop predicate is the fuller `_legendHighlighted() ||
      // _noLegendHighlighted()`, which also drops the stop while another
      // legend is merely HOVERED. Hovering a legend with the keyboard already
      // inside the plot is the only case the two disagree on, and dropping a
      // focused cell out from under the roving index there would be worse than
      // the divergence.
      if (!opensPopoverFor(placed.cell.legend)) {
        continue;
      }
      regions.add(
        FluentChartHitRegion(
          bounds: placed.rect,
          // The emission order, which is the DOM order the arrow navigation
          // group walks (`:279-288`).
          index: regions.length,
          legend: placed.cell.legend,
          popoverData: FluentChartPopoverData(
            legend: placed.cell.legend,
            // NaN falls back to the plain foreground (`HeatMapChart.tsx:156`).
            color: placed.cell.value.isNaN ? colors.axisText : placed.fill,
            yValue: _rectTextOf(placed.cell),
            ratio: placed.cell.ratio,
            descriptionMessage: placed.cell.descriptionMessage ?? '',
          ),
          semanticsLabel:
              placed.cell.semantics?.label ?? _ariaLabelOf(placed.cell),
        ),
      );
    }
    return regions;
  }

  /// `${data.rectText}` (`HeatMapChart.tsx:141`), which for the numeric case is
  /// JavaScript's own number-to-string and not a locale format.
  static String _rectTextOf(FluentHeatMapCell cell) {
    final text = cell.rectText;
    return text is num ? d3.jsNumberToString(text.toDouble()) : '$text';
  }

  /// Ports `_getAriaLabel` (`HeatMapChart.tsx:620-632`).
  static String _ariaLabelOf(FluentHeatMapCell cell) {
    final ratio = cell.ratio;
    final zValue = ratio != null
        ? '${d3.jsNumberToString(ratio.$1)}/${d3.jsNumberToString(ratio.$2)}'
        : _rectTextOf(cell);
    final description = cell.descriptionMessage;
    return '${cell.x}, ${cell.y}. ${cell.legend}, $zValue.'
        '${description == null || description.isEmpty ? '' : ' $description.'}';
  }
}

/// A Fluent 2 heat-map chart.
///
/// Ports `HeatMapChart.tsx`. Both axes are categorical; the cell fill comes
/// from a caller-supplied colour ramp and the cell text flips to the inverse
/// foreground whenever the contrast falls below three.
class FluentHeatMapChart extends StatefulWidget {
  /// Creates a heat map over [data].
  const FluentHeatMapChart({
    super.key,
    required this.data,
    required this.domainValuesForColorScale,
    required this.rangeValuesForColorScale,
    this.props = const FluentCartesianChartProps(),
    this.chartTitle,
    this.xAxisDateFormatString,
    this.yAxisDateFormatString,
    this.xAxisNumberFormatString,
    this.yAxisNumberFormatString,
    this.xAxisStringFormatter,
    this.yAxisStringFormatter,
    this.culture,
    this.sortAlphabetically = true,
    this.style,
    this.focusNode,
  });

  /// One entry per legend.
  final List<FluentHeatMapChartData> data;

  /// Colour-scale domain stops.
  final List<double> domainValuesForColorScale;

  /// Colour-scale range stops; must be the same length as the domain.
  final List<Color> rangeValuesForColorScale;

  /// Shell configuration.
  final FluentCartesianChartProps props;

  /// Human title, folded into the accessible description. Never painted
  /// (`HeatMapChart.tsx:635-639`).
  final String? chartTitle;

  /// strftime pattern for a date x key — `'%b/%d'` by default.
  final String? xAxisDateFormatString;

  /// strftime pattern for a date y key — `'%b/%d'` by default.
  final String? yAxisDateFormatString;

  /// d3 number format for a numeric x key — `'.2~s'` by default.
  final String? xAxisNumberFormatString;

  /// d3 number format for a numeric y key — `'.2~s'` by default.
  final String? yAxisNumberFormatString;

  /// Applied to a string x key after sorting.
  final String Function(String)? xAxisStringFormatter;

  /// Applied to a string y key after sorting.
  final String Function(String)? yAxisStringFormatter;

  /// BCP-47 locale for cell text and popover values.
  final String? culture;

  /// Whether category labels sort alphabetically. False reproduces
  /// `sortOrder: 'none'`, which keeps insertion order.
  final bool sortAlphabetically;

  /// Style override, highest precedence.
  final FluentHeatMapChartStyle? style;

  /// The chart's single focus node.
  final FocusNode? focusNode;

  @override
  State<FluentHeatMapChart> createState() => _FluentHeatMapChartState();
}

class _FluentHeatMapChartState extends State<FluentHeatMapChart> {
  String _selectedLegend = '';
  String _activeLegend = '';
  final FluentChartTextMeasurer _measurer = FluentChartTextMeasurer();
  late FluentHeatMapDataSet _dataSet;

  // Not initState: the placeholder text comes from the ambient localizations,
  // and reading an inherited widget there is not allowed. This also rebuilds
  // the set when the locale changes under a running chart.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rebuild();
  }

  @override
  void didUpdateWidget(FluentHeatMapChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data ||
        oldWidget.sortAlphabetically != widget.sortAlphabetically ||
        oldWidget.props.xAxisCategoryOrder != widget.props.xAxisCategoryOrder ||
        oldWidget.props.yAxisCategoryOrder != widget.props.yAxisCategoryOrder) {
      _rebuild();
    }
  }

  void _rebuild() {
    _dataSet = buildFluentHeatMapDataSet(
      data: widget.data,
      xAxisCategoryOrder: widget.props.xAxisCategoryOrder,
      yAxisCategoryOrder: widget.props.yAxisCategoryOrder,
      alphabeticalSort: widget.sortAlphabetically,
      xAxisDateFormat: widget.xAxisDateFormatString,
      yAxisDateFormat: widget.yAxisDateFormatString,
      xAxisNumberFormat: widget.xAxisNumberFormatString,
      yAxisNumberFormat: widget.yAxisNumberFormatString,
      xAxisStringFormatter: widget.xAxisStringFormatter,
      yAxisStringFormatter: widget.yAxisStringFormatter,
      placeholderText: fluentL10n(context).chartNoDataAvailable,
    );
  }

  @override
  void dispose() {
    _measurer.invalidate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      // `_isChartEmpty` renders an `role="alert"` div in place of the shell
      // (`HeatMapChart.tsx:820`).
      return Semantics(
        liveRegion: true,
        label: fluentL10n(context).chartNoData,
        child: const SizedBox.shrink(),
      );
    }
    final theme = FluentTheme.of(context);
    final style = resolveFluentHeatMapChartStyle(
      theme,
    ).merge(FluentHeatMapChartTheme.maybeOf(context)).merge(widget.style);
    final pointCount = widget.data.fold<int>(
      0,
      (acc, series) => acc + series.data.length,
    );
    return FluentCartesianChart(
      focusNode: widget.focusNode,
      legendSelectionMode: FluentChartLegendSelectionMode.single,
      props: widget.props.copyWith(
        // The hard-coded shell tick size at HeatMapChart.tsx:806. The two band
        // paddings from the same block are NOT props — they are delegate
        // pull-hooks, overridden on FluentHeatMapChartDelegate above.
        xAxistickSize: 0,
        // `_getChartTitle` (`:635-639`).
        chartTitleForSemantics:
            '${widget.chartTitle == null ? '' : '${widget.chartTitle}. '}'
            '${fluentL10n(context).heatMapChartDescription(pointCount)}',
      ),
      legends: <FluentChartLegendItem>[
        for (final series in widget.data)
          FluentChartLegendItem(
            title: series.legend,
            // The swatch uses the SERIES-level value (`HeatMapChart.tsx:334`).
            color: fluentHeatMapColourAt(
              series.value,
              domain: widget.domainValuesForColorScale,
              range: widget.rangeValuesForColorScale,
            ),
            // `_onLegendClick` (`:314-323`) toggles the single selection.
            onAction: () => setState(
              () => _selectedLegend = _selectedLegend == series.legend
                  ? ''
                  : series.legend,
            ),
            onHoverAction: () => setState(() => _activeLegend = series.legend),
            onMouseOutAction: ({required bool isLegendFocused}) =>
                setState(() => _activeLegend = ''),
          ),
      ],
      delegate: FluentHeatMapChartDelegate(
        dataSet: _dataSet,
        style: style,
        colors: FluentChartColors.of(theme),
        measurer: _measurer,
        domainValues: widget.domainValuesForColorScale,
        rangeValues: widget.rangeValuesForColorScale,
        selectedLegend: _selectedLegend,
        activeLegend: _activeLegend,
        culture: widget.culture,
      ),
    );
  }
}
