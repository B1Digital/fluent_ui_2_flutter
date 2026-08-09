/// One stacked value: its baseline, its top, and the row it came from
/// (`d3-shape/src/stack.js:29`).
class StackPoint {
  /// Creates a stacked value.
  const StackPoint(this.lo, this.hi, this.data);

  /// The baseline.
  final double lo;

  /// The top.
  final double hi;

  /// The source row. `AreaChart.tsx:317-319` reads `d.data.xVal` off it.
  final Object data;
}

double _defaultStackValue(Object d, String key) =>
    (d as Map<String, Object?>)[key]! as double;

/// Stacks [keys] over [data] (`d3-shape/src/stack.js:22-39`).
///
/// Only `offsetNone` and `orderNone` are ported: `AreaChart.tsx:312` is the
/// single call site and sets neither `.order` nor `.offset`.
List<List<StackPoint>> stack(
  List<Object> data,
  List<String> keys, {
  double Function(Object d, String key) value = _defaultStackValue,
}) {
  final n = keys.length;
  final m = data.length;
  // `stack.js:29` seeds every pair as `[0, +value(d, key)]`.
  final los = List<List<double>>.generate(
    n,
    (int _) => List<double>.filled(m, 0),
  );
  final his = List<List<double>>.generate(
    n,
    (int i) => List<double>.generate(m, (int j) => value(data[j], keys[i])),
  );

  // offset/none.js:3-8 — each series is lifted onto the one before it. The
  // carry reads the previous series' TOP unless that is NaN, in which case it
  // reads its BOTTOM. The loop starts at series 1 because series 0 keeps the
  // zero baseline seeded above.
  for (var i = 1; i < n; i++) {
    for (var j = 0; j < m; j++) {
      final previousHi = his[i - 1][j];
      los[i][j] = previousHi.isNaN ? los[i - 1][j] : previousHi;
      his[i][j] += los[i][j];
    }
  }

  return List<List<StackPoint>>.generate(
    n,
    (int i) => List<StackPoint>.generate(
      m,
      (int j) => StackPoint(los[i][j], his[i][j], data[j]),
      growable: false,
    ),
    growable: false,
  );
}
