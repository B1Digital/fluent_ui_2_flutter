import 'dart:math' as math;

import 'js_math.dart';
import 'stable_sort.dart';

/// One computed slice, the object literal built at `d3-shape/src/pie.js:42-49`.
class PieArc {
  /// Creates a slice.
  const PieArc({
    required this.data,
    required this.index,
    required this.value,
    required this.startAngle,
    required this.endAngle,
    required this.padAngle,
  });

  /// The datum this slice came from (`d3-shape/src/pie.js:43`).
  final Object? data;

  /// The slice's position in the *sorted* order (`d3-shape/src/pie.js:44`).
  ///
  /// The returned list is in input order, so this is the only record of where
  /// a comparator moved the slice to.
  final int index;

  /// The raw value, as returned by `Pie.value` (`d3-shape/src/pie.js:45`).
  ///
  /// Non-positive values are reported unchanged even though they contribute no
  /// angle.
  final double value;

  /// The start angle in radians (`d3-shape/src/pie.js:46`).
  final double startAngle;

  /// The end angle in radians (`d3-shape/src/pie.js:47`).
  final double endAngle;

  /// The padding angle, identical on every slice (`d3-shape/src/pie.js:48`).
  final double padAngle;
}

/// The pie layout, a port of `d3-shape/src/pie.js:7-80`.
///
/// It turns a list of data into a list of angular spans that
/// [PieArc.startAngle] and [PieArc.endAngle] describe; drawing them is the
/// arc generator's job.
class Pie<T> {
  /// Creates a layout.
  ///
  /// Passing neither [sort] nor [sortValues] reproduces `.sort(null)`, which is
  /// what both upstream call sites use (`Pie.tsx:30` and `Pie.tsx:95` — the
  /// plan cites `:29` and `:94`, one line early) and which preserves input
  /// order: `pie.sort()` assigns `sortValues = null` as well
  /// (`d3-shape/src/pie.js:64`), so d3's descending default never runs.
  Pie({
    required this.value,
    this.sort,
    this.sortValues,
    this.startAngle = 0,
    this.endAngle = tau,
    this.padAngle = 0,
  });

  /// Extracts a slice's value (`d3-shape/src/pie.js:31`).
  final double Function(T d) value;

  /// Orders slices by datum (`d3-shape/src/pie.js:38`).
  ///
  /// Only consulted when [sortValues] is null, matching upstream's
  /// `else if`.
  final int Function(T a, T b)? sort;

  /// Orders slices by value (`d3-shape/src/pie.js:37`).
  ///
  /// d3 defaults this to descending; leaving both this and [sort] null — the
  /// upstream case — disables sorting entirely.
  final int Function(double a, double b)? sortValues;

  /// The angle the first slice starts at (`d3-shape/src/pie.js:23`).
  final double startAngle;

  /// The angle the last slice ends at (`d3-shape/src/pie.js:24`).
  final double endAngle;

  /// The gap between slices, capped at `|endAngle - startAngle| / n`
  /// (`d3-shape/src/pie.js:26`).
  final double padAngle;

  /// Computes the slices, returned in **input** order with the sorted position
  /// recorded on each [PieArc.index] (`d3-shape/src/pie.js:41-50`).
  List<PieArc> call(List<T> data) {
    final n = data.length;
    final values = List<double>.generate(n, (int i) => value(data[i]));
    // `pie.js:30-34` — only positive values enter the total, so a zero or
    // negative slice cannot shrink its siblings.
    var sum = 0.0;
    for (var i = 0; i < n; i++) {
      if (values[i] > 0) {
        sum += values[i];
      }
    }

    var index = List<int>.generate(n, (int i) => i);
    if (sortValues != null) {
      // `pie.js:37`. Array.prototype.sort is stable in every engine d3
      // supports, and Dart's List.sort is not, hence stableSort.
      index = stableSort(
        index,
        (int a, int b) => sortValues!(values[a], values[b]),
      );
    } else if (sort != null) {
      // `pie.js:38`.
      index = stableSort(index, (int a, int b) => sort!(data[a], data[b]));
    }

    // `pie.js:24` — the sweep is clamped to one full turn in either direction.
    final da = math.min(tau, math.max(-tau, endAngle - startAngle));
    // `pie.js:26`. Upstream divides by `n` unguarded, which yields Infinity for
    // empty data and lets Math.min pick padAngle; Dart's math.min propagates
    // the NaN that `0 / 0` would produce instead, so the empty case is taken
    // out explicitly. No slice exists to observe the difference.
    final p = n == 0 ? 0.0 : math.min(da.abs() / n, padAngle);
    // `pie.js:27` — the pad follows the sweep's direction.
    final pa = p * (da < 0 ? -1 : 1);
    // `pie.js:41` — the remaining angle after the pads, per unit of value.
    final k = sum != 0 ? (da - n * pa) / sum : 0.0;

    final arcs = List<PieArc?>.filled(n, null);
    var a0 = startAngle;
    for (var i = 0; i < n; i++) {
      final j = index[i];
      final v = values[j];
      // `pie.js:42` — `v > 0 ? v * k : 0`, so a non-positive slice is exactly
      // one pad wide rather than absent.
      final a1 = a0 + (v > 0 ? v * k : 0) + pa;
      arcs[j] = PieArc(
        data: data[j],
        index: i,
        value: v,
        startAngle: a0,
        endAngle: a1,
        padAngle: p,
      );
      a0 = a1;
    }
    return arcs.cast<PieArc>();
  }
}
