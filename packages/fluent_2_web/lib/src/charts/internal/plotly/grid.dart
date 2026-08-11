/// The Plotly sub-plot grid solver.
///
/// Ports `PlotlySchemaAdapter.ts:3632-3830`. Four independent sources push
/// domain intervals into the same two lists — cartesian `xaxis*`/`yaxis*`
/// layout keys, non-plot traces' own `domain`, `polar*` sub-plots, and the
/// layout annotations that decorate whichever cell contains them — and the
/// lists are then deduplicated, sorted and turned into 1-based CSS grid
/// coordinates. Internal to the package: nothing here is barrel-exported.
library;

import 'package:flutter/foundation.dart';

import 'json_guard.dart';
import 'router.dart';

/// Prefix for the synthetic cell key a non-plot trace is given.
///
/// `NON_PLOT_KEY_PREFIX` at `PlotlySchemaAdapter.ts:102`.
const String kNonPlotKeyPrefix = 'nonplot_';

/// The CSS template a *solved* one-cell grid produces.
///
/// `SINGLE_REPEAT` at `PlotlySchemaAdapter.ts:103`. Read by
/// [FluentPlotlyGridProperties.isSingleRepeat], which is the port's spelling of
/// the degenerate-grid comparison at `DeclarativeChart.tsx:513-514`.
const String kSingleRepeat = 'repeat(1, 1fr)';

/// The CSS template `PlotlySchemaAdapter.ts:3654-3655` seeds both axes with.
///
/// It survives into the result whenever the matching guard at `:3762` or
/// `:3793` finds an empty domain list, and it is deliberately *not*
/// [kSingleRepeat]: an unsolved axis and an axis solved to exactly one interval
/// are the same shape but not the same string, and `:513-514` only collapses
/// the second.
const String _unsolvedTemplate = '1fr';

/// The cell key a trace with no explicit `xaxis` falls back to.
///
/// `DeclarativeChart.tsx:479-497` groups by `series.xaxis`, and the first
/// cartesian axis is named `x` rather than `x1` — the same naming
/// [getGridProperties] gives its first interval at
/// `PlotlySchemaAdapter.ts:3676`.
const String kDefaultXAxisKey = 'x';

/// A half-open-in-name-only `[start, end]` fraction of the plot area.
///
/// `DomainInterval` at `PlotlySchemaAdapter.ts:105-108`. Both bounds are
/// inclusive where an annotation is tested against them
/// (`PlotlySchemaAdapter.ts:3740`).
@immutable
class FluentPlotlyDomainInterval {
  /// Creates an interval.
  const FluentPlotlyDomainInterval({required this.start, required this.end});

  /// The lower bound, a fraction of the plot area.
  final double start;

  /// The upper bound, a fraction of the plot area.
  final double end;

  @override
  bool operator ==(Object other) =>
      other is FluentPlotlyDomainInterval &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'FluentPlotlyDomainInterval($start, $end)';
}

/// One grid cell: where it sits, what it spans, and what labels it.
///
/// `AxisProperties` at `PlotlySchemaAdapter.ts:114-121`.
@immutable
class FluentPlotlyAxisProperties {
  /// Creates a cell.
  const FluentPlotlyAxisProperties({
    required this.row,
    required this.column,
    required this.xDomain,
    required this.yDomain,
    this.xAnnotation,
    this.yAnnotation,
  });

  /// The 1-based CSS grid row, counted from the top.
  ///
  /// `-1` until the y pass at `PlotlySchemaAdapter.ts:3808-3822` fills it in,
  /// which it can only do for a cell the x pass already created; a cell named
  /// by a `yaxis` with no matching `xaxis` keeps the `-1` seeded at `:3784`.
  final int row;

  /// The 1-based CSS grid column, counted from the left.
  final int column;

  /// The layout annotation that labels this cell horizontally.
  final String? xAnnotation;

  /// The layout annotation that labels this cell vertically — the one whose
  /// `textangle` is 90 (`PlotlySchemaAdapter.ts:3753-3754`).
  final String? yAnnotation;

  /// The horizontal extent this cell occupies.
  final FluentPlotlyDomainInterval xDomain;

  /// The vertical extent this cell occupies, in Plotly's bottom-origin space.
  final FluentPlotlyDomainInterval yDomain;

  @override
  bool operator ==(Object other) =>
      other is FluentPlotlyAxisProperties &&
      other.row == row &&
      other.column == column &&
      other.xAnnotation == xAnnotation &&
      other.yAnnotation == yAnnotation &&
      other.xDomain == xDomain &&
      other.yDomain == yDomain;

  @override
  int get hashCode =>
      Object.hash(row, column, xAnnotation, yAnnotation, xDomain, yDomain);

  @override
  String toString() =>
      'FluentPlotlyAxisProperties(row: $row, column: $column, '
      'xDomain: $xDomain, yDomain: $yDomain)';
}

/// The solved grid: its shape, and every cell in it by key.
///
/// `GridProperties` at `PlotlySchemaAdapter.ts:124-128`. Upstream carries the
/// two CSS template strings; the port carries the counts they were formatted
/// from, because Flutter lays the grid out itself — plus [isSingleRepeat],
/// which is the one thing those counts throw away.
@immutable
class FluentPlotlyGridProperties {
  /// Creates a grid.
  const FluentPlotlyGridProperties({
    required this.rowCount,
    required this.columnCount,
    required this.layout,
    required this.isSingleRepeat,
  });

  /// How many rows the grid has — `repeat(rowCount, 1fr)` upstream.
  final int rowCount;

  /// How many columns the grid has — `repeat(columnCount, 1fr)` upstream.
  final int columnCount;

  /// Every cell, keyed by `x`, `x2`… for a cartesian axis, `nonplot_1`… for a
  /// non-plot trace, and by the raw `polar*` key for a polar sub-plot.
  final Map<String, FluentPlotlyAxisProperties> layout;

  /// Whether BOTH CSS templates came out as [kSingleRepeat] — the degenerate
  /// grid `DeclarativeChart.tsx:510-515` collapses to a single plot.
  ///
  /// This is **not** `rowCount == 1 && columnCount == 1`. Upstream seeds both
  /// templates with [_unsolvedTemplate] at `PlotlySchemaAdapter.ts:3654-3655`
  /// and only overwrites them inside the `domainX.length > 0` / `domainY.length
  /// > 0` guards at `:3762` and `:3793`. A multi-plot figure that declares no
  /// `xaxis`/`yaxis`, no `polar*` sub-plot and no non-plot trace therefore ends
  /// with `1fr` on both axes — which fails `:513-514` and is NOT collapsed —
  /// while [rowCount] and [columnCount] are 1 exactly as they are for a solved
  /// one-by-one grid, which IS collapsed. The counts cannot separate the two
  /// cases; this flag is the bit they drop.
  final bool isSingleRepeat;

  @override
  String toString() =>
      'FluentPlotlyGridProperties($rowCount x $columnCount, '
      '${layout.length} cells)';
}

/// The kinds that occupy a grid cell without a cartesian axis pair.
///
/// `PlotlySchemaAdapter.ts:3637-3639` lists seven type *names*. The port
/// matches on the same names through [plotlyChartKindName] rather than on the
/// enum, so `pie` and `funnel` — which no [FluentPlotlyChartKind] currently
/// spells — stay in the list against the day the router grows them.
const Set<String> _nonPlotTypeNames = <String>{
  'donut',
  'sankey',
  'pie',
  'annotation',
  'table',
  'gauge',
  'funnel',
};

/// Whether [kind] is laid out from its own `domain` rather than from an axis
/// pair (`PlotlySchemaAdapter.ts:3637-3639`).
bool isNonPlotType(FluentPlotlyChartKind kind) =>
    _nonPlotTypeNames.contains(plotlyChartKindName(kind));

/// `String(value)` as V8 renders it, for the values a Plotly domain can hold.
///
/// An integral double renders without a decimal point — `1`, not Dart's `1.0`
/// — and everything else takes Dart's shortest round-trip form, which agrees
/// with V8 across the whole of `[0, 1]` including the `1e-7` exponent form V8
/// switches to below `1e-6`. Both call sites need this: the dedup key at
/// `PlotlySchemaAdapter.ts:3765` is a template string, and
/// [_lexicographicSort] compares the same rendering.
String plotlyNumberToString(double value) {
  // 1e15 is the last magnitude at which every integral double survives
  // `toInt()`; above it, and for the non-integral case, Dart's own shortest
  // round-trip rendering is already what V8 prints.
  if (value == value.roundToDouble() && value.abs() < 1e15) {
    // `toInt()` rather than `toStringAsFixed(0)` because the latter renders
    // negative zero as `-0` where `String(-0)` is `0`.
    return value.toInt().toString();
  }
  return value.toString();
}

/// Sorts interval starts the way JavaScript's comparator-less
/// `Array.prototype.sort` does — as strings.
///
/// parity: `PlotlySchemaAdapter.ts:3772`, `:3803`. Across the plain-decimal
/// renderings a domain in `[0, 1]` normally produces, the string order and the
/// numeric order happen to agree, because every value shares the same
/// single-digit integer part. They part company as soon as V8 reaches for
/// exponent notation: `String(1e-7)` is `'1e-7'`, which sorts *after* `'0.5'`,
/// so a sub-plot pinned to the far left of the figure is given the rightmost
/// column. A numeric sort here would place that chart in a different grid cell
/// than the browser does, so the defect is reproduced rather than fixed.
List<double> _lexicographicSort(Iterable<double> starts) {
  final copy = starts.toList()
    ..sort((a, b) {
      final sa = plotlyNumberToString(a);
      final sb = plotlyNumberToString(b);
      return sa.compareTo(sb);
    });
  return copy;
}

/// One interval plus the grid cell it names.
///
/// `ExtDomainInterval` at `PlotlySchemaAdapter.ts:110-112`.
class _ExtInterval {
  const _ExtInterval({
    required this.start,
    required this.end,
    required this.cellName,
  });

  final double start;
  final double end;
  final String cellName;

  FluentPlotlyDomainInterval get interval =>
      FluentPlotlyDomainInterval(start: start, end: end);
}

/// `parseInt(key.replace(pattern, '') || '1', 10) - 1`
/// (`PlotlySchemaAdapter.ts:3632-3635`).
///
/// Returns `null` where `parseInt` would return `NaN`, so that the caller's
/// `index !== anchorIndex` test stays true for an unparsable key exactly as it
/// does for `NaN`. `replaceFirst` is JavaScript's string-pattern `replace`,
/// which replaces one occurrence.
int? _indexFromKey(String key, String pattern) {
  final stripped = key.replaceFirst(pattern, '');
  final normalized = stripped.isEmpty ? '1' : stripped;
  // `parseInt` reads a leading optional sign and the digits that follow it,
  // and ignores whatever trails them.
  final match = RegExp(r'^\s*[+-]?\d+').firstMatch(normalized);
  if (match == null) {
    return null;
  }
  return int.parse(match.group(0)!.trim()) - 1;
}

/// `${index + 1}` as the upstream template literal renders it, `NaN` included.
String _oneBased(int? index) => index == null ? 'NaN' : '${index + 1}';

/// A JSON number as a double, or `null` where the value is absent or is not a
/// number at all.
double? _asDouble(Object? value) => value is num ? value.toDouble() : null;

/// `axis?.domain ? axis.domain[i] : fallback` (`PlotlySchemaAdapter.ts:3674`).
///
/// A JavaScript array is truthy whatever its length, so a short `domain` there
/// yields `undefined` and every later comparison against it is false. The port
/// falls back to the same default the missing-`domain` branch uses, which is
/// the only reading of a short domain that keeps the interval ordered.
double _domainBound(Object? domain, int position, double fallback) {
  if (domain is! List<Object?> || position >= domain.length) {
    return fallback;
  }
  return _asDouble(domain[position]) ?? fallback;
}

/// The `domain` sub-map of a trace or a polar layout, or `null`.
Map<String, Object?>? _domainMap(Object? owner) {
  if (owner is! Map<String, Object?>) {
    return null;
  }
  final domain = owner['domain'];
  return domain is Map<String, Object?> ? domain : null;
}

/// Solves the sub-plot grid for [schema].
///
/// `getGridProperties` at `PlotlySchemaAdapter.ts:3641-3830`. [traces] must be
/// indexed against `schema['data']` as it stands, which is what
/// `DeclarativeChart.tsx:372-380` re-indexes it to be. A malformed layout
/// raises [PlotlySchemaException].
FluentPlotlyGridProperties getGridProperties(
  Map<String, Object?> schema, {
  required bool isMultiPlot,
  required List<FluentPlotlyTraceInfo> traces,
}) {
  final domainX = <_ExtInterval>[];
  final domainY = <_ExtInterval>[];
  // Keyed by index into `domainY`, per `PlotlySchemaAdapter.ts:3749-3757`. A
  // present key with a null value is upstream's `undefined` text, which reads
  // back the same as an absent key.
  final xAnnotations = <int, String?>{};
  final yAnnotations = <int, String?>{};
  var rowCount = 1;
  var columnCount = 1;
  final gridLayout = <String, FluentPlotlyAxisProperties>{};

  // `:3657-3659`: a single plot is one cell and carries no layout at all. It
  // returns the two seeds untouched, so it is not `SINGLE_REPEAT` either —
  // moot at `DeclarativeChart.tsx:512`, which tests `isMultiPlot` first, and
  // recorded rather than rounded off so this stays a transcription.
  if (!isMultiPlot) {
    return FluentPlotlyGridProperties(
      rowCount: rowCount,
      columnCount: columnCount,
      layout: gridLayout,
      isSingleRepeat: false,
    );
  }

  final rawLayout = schema['layout'];
  final layout = rawLayout is Map<String, Object?> ? rawLayout : null;

  // `:3663-3699`: the cartesian axes, in layout key order.
  if (layout != null && layout.isNotEmpty) {
    for (final key in layout.keys) {
      if (key.startsWith('xaxis')) {
        final index = _indexFromKey(key, 'xaxis');
        final axis = layout[key];
        final rawAnchor = axis is Map<String, Object?> ? axis['anchor'] : null;
        final anchor = rawAnchor is String ? rawAnchor : 'y';
        final anchorIndex = _indexFromKey(anchor, 'y');
        if (index == null || index != anchorIndex) {
          // `:3670`.
          throw PlotlySchemaException(
            'Invalid layout: xaxis ${_oneBased(index)} anchor should be '
            'y${_oneBased(anchorIndex)}',
          );
        }
        final domain = axis is Map<String, Object?> ? axis['domain'] : null;
        domainX.add(
          _ExtInterval(
            start: _domainBound(domain, 0, 0),
            end: _domainBound(domain, 1, 1),
            // `:3676`: the first cell is `x`, the second `x2`, and so on.
            cellName: 'x${domainX.isEmpty ? '' : domainX.length + 1}',
          ),
        );
      } else if (key.startsWith('yaxis')) {
        final index = _indexFromKey(key, 'yaxis');
        final axis = layout[key];
        final rawAnchor = axis is Map<String, Object?> ? axis['anchor'] : null;
        final anchor = rawAnchor is String ? rawAnchor : 'x';
        final anchorIndex = _indexFromKey(anchor, 'x');
        if (index == null || index != anchorIndex) {
          final yaxis2 = layout['yaxis2'];
          final side = yaxis2 is Map<String, Object?> ? yaxis2['side'] : null;
          if ((index == 1 && anchorIndex == 0) || side == 'right') {
            // parity: `:3684-3687` writes `return { templateRows,
            // templateColumns }` inside a `forEach` callback, so the returned
            // object is discarded and only *this* key is skipped — the
            // secondary y axis contributes no row, and the rest of the layout
            // is still solved. Returning from the whole function here would
            // drop every cell of a two-axis figure.
            continue;
          }
          // `:3688`.
          throw PlotlySchemaException(
            'Invalid layout: yaxis ${_oneBased(index)} anchor should be '
            'x${_oneBased(anchorIndex)}',
          );
        }
        final domain = axis is Map<String, Object?> ? axis['domain'] : null;
        domainY.add(
          _ExtInterval(
            start: _domainBound(domain, 0, 0),
            end: _domainBound(domain, 1, 1),
            // `:3694`: the y intervals take the *same* `x`-prefixed cell names,
            // which is how the two passes below meet on one cell.
            cellName: 'x${domainY.isEmpty ? '' : domainY.length + 1}',
          ),
        );
      }
    }
  }

  // `:3701`: "Assuming that the number of x and y axes is the same".
  final cartesianDomains = domainX.length;

  // `:3702-3718`: a non-plot trace brings its own domain.
  final rawData = schema['data'];
  final data = rawData is List<Object?> ? rawData : const <Object?>[];
  for (var index = 0; index < traces.length; index++) {
    if (!isNonPlotType(traces[index].kind)) {
      continue;
    }
    // Upstream indexes `data` by the loop position, not by `trace.index`,
    // because the caller has already reduced `data` to the valid traces
    // (`DeclarativeChart.tsx:372-380`). Out of range is a `TypeError`
    // upstream; here it reads as an absent domain.
    final series = index < data.length ? data[index] : null;
    final domain = _domainMap(series);
    domainX.add(
      _ExtInterval(
        start: _domainBound(domain?['x'], 0, 0),
        end: _domainBound(domain?['x'], 1, 1),
        cellName: '$kNonPlotKeyPrefix${domainX.length - cartesianDomains + 1}',
      ),
    );
    domainY.add(
      _ExtInterval(
        start: _domainBound(domain?['y'], 0, 0),
        end: _domainBound(domain?['y'], 1, 1),
        cellName: '$kNonPlotKeyPrefix${domainY.length - cartesianDomains + 1}',
      ),
    );
  }

  if (layout != null && layout.isNotEmpty) {
    // `:3721-3737`: a polar sub-plot occupies a cell keyed by its own layout
    // key, `polar`, `polar2`…
    for (final key in layout.keys) {
      if (!key.startsWith('polar')) {
        continue;
      }
      final domain = _domainMap(layout[key]);
      domainX.add(
        _ExtInterval(
          start: _domainBound(domain?['x'], 0, 0),
          end: _domainBound(domain?['x'], 1, 1),
          cellName: key,
        ),
      );
      domainY.add(
        _ExtInterval(
          start: _domainBound(domain?['y'], 0, 0),
          end: _domainBound(domain?['y'], 1, 1),
          cellName: key,
        ),
      );
    }

    // `:3738-3759`: an annotation labels the first cell whose x *and* y
    // intervals both contain it, and its index into `domainY` is what the two
    // passes below look it up by.
    final rawAnnotations = layout['annotations'];
    if (rawAnnotations is List<Object?>) {
      for (final rawAnnotation in rawAnnotations) {
        if (rawAnnotation is! Map<String, Object?>) {
          continue;
        }
        final x = _asDouble(rawAnnotation['x']);
        final y = _asDouble(rawAnnotation['y']);
        if (x == null || y == null) {
          // Every comparison against `undefined` is false in JavaScript, so an
          // annotation without both coordinates matches nothing.
          continue;
        }
        final xMatches = <int>{
          for (var i = 0; i < domainX.length; i++)
            if (x >= domainX[i].start && x <= domainX[i].end) i,
        };
        var yMatch = -1;
        for (var yIndex = 0; yIndex < domainY.length; yIndex++) {
          if (xMatches.contains(yIndex) &&
              y >= domainY[yIndex].start &&
              y <= domainY[yIndex].end) {
            yMatch = yIndex;
            break;
          }
        }
        if (yMatch == -1) {
          continue;
        }
        final rawText = rawAnnotation['text'];
        final text = rawText is String ? rawText : null;
        final textangle = rawAnnotation['textangle'];
        // `:3753`: a strict `=== 90`, so the string `'90'` is an x annotation.
        if (textangle is num && textangle == 90) {
          yAnnotations[yMatch] = text;
        } else {
          xAnnotations[yMatch] = text;
        }
      }
    }
  }

  // `:3762-3792`: columns, left to right.
  if (domainX.isNotEmpty) {
    final uniqueXIntervals = <String, _ExtInterval>{};
    for (final interval in domainX) {
      final key =
          '${plotlyNumberToString(interval.start)}-'
          '${plotlyNumberToString(interval.end)}';
      uniqueXIntervals.putIfAbsent(key, () => interval);
    }
    final sortedXStart = _lexicographicSort(
      uniqueXIntervals.values.map((interval) => interval.start),
    );
    columnCount = sortedXStart.length;

    for (var index = 0; index < domainX.length; index++) {
      final interval = domainX[index];
      final columnIndex = sortedXStart.indexOf(interval.start);
      gridLayout[interval.cellName] = FluentPlotlyAxisProperties(
        // `:3784`: seeded, and filled in by the y pass below.
        row: -1,
        // `:3778`: column numbers are 1-based.
        column: columnIndex + 1,
        xAnnotation: xAnnotations[index],
        xDomain: interval.interval,
        // `:3788`: the default y domain for an x-axis cell.
        yDomain: const FluentPlotlyDomainInterval(start: 0, end: 1),
      );
    }
  }

  // `:3793-3823`: rows, top to bottom.
  if (domainY.isNotEmpty) {
    final uniqueYIntervals = <String, _ExtInterval>{};
    for (final interval in domainY) {
      final key =
          '${plotlyNumberToString(interval.start)}-'
          '${plotlyNumberToString(interval.end)}';
      uniqueYIntervals.putIfAbsent(key, () => interval);
    }
    final sortedYStart = _lexicographicSort(
      uniqueYIntervals.values.map((interval) => interval.start),
    );
    rowCount = sortedYStart.length;

    for (var index = 0; index < domainY.length; index++) {
      final interval = domainY[index];
      final rowIndex = sortedYStart.indexOf(interval.start);
      // Plotly's y domain is bottom-origin and CSS grid is top-origin, so the
      // row index is inverted (`PlotlySchemaAdapter.ts:3810`).
      final rowNumber = rowCount - rowIndex;

      final cell = gridLayout[interval.cellName];
      if (cell == null) {
        continue;
      }
      gridLayout[interval.cellName] = FluentPlotlyAxisProperties(
        row: rowNumber,
        column: cell.column,
        xAnnotation: cell.xAnnotation,
        yAnnotation: yAnnotations[index],
        xDomain: cell.xDomain,
        yDomain: interval.interval,
      );
    }
  }

  // `:3774` and `:3807` format the two templates, but only from inside the
  // `:3762` and `:3793` guards — an empty domain list leaves the `:3654-3655`
  // seed in place.
  final templateColumns = domainX.isEmpty
      ? _unsolvedTemplate
      : 'repeat($columnCount, 1fr)';
  final templateRows = domainY.isEmpty
      ? _unsolvedTemplate
      : 'repeat($rowCount, 1fr)';

  return FluentPlotlyGridProperties(
    rowCount: rowCount,
    columnCount: columnCount,
    layout: gridLayout,
    // `DeclarativeChart.tsx:513-514`, both templates, verbatim.
    isSingleRepeat:
        templateRows == kSingleRepeat && templateColumns == kSingleRepeat,
  );
}
