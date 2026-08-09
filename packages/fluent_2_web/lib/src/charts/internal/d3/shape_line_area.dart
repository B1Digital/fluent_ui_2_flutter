import 'curves.dart';
import 'path_sink.dart';

/// Whether the datum at [i] should be drawn.
///
/// **Live, not dead.** Four upstream call sites override it, all with
/// `isPlottable` (`utilities.ts:2278`): `PolarChart.tsx:450`, `:473`,
/// `LineChart.tsx:678` and `:1326`. Hardcoding `true` draws one connected path
/// straight through every NaN gap.
typedef Defined<T> = bool Function(T d, int i, List<T> data);

/// d3's default predicate (`d3-shape/src/line.js:14`), which draws every datum.
///
/// Declared over `Object?` rather than a type parameter so that the tear-off is
/// a constant expression and can therefore be a default argument value; the
/// contravariance of function parameters makes it a `Defined<T>` for every `T`.
bool _alwaysDefined(Object? d, int i, List<Object?> data) => true;

/// Accessor for one coordinate.
///
/// The contract spells this function type inline on five fields across [Line],
/// [Area] and the radial generators; one name is the same type.
typedef Accessor<T> = double Function(T d, int i, List<T> data);

/// A line generator (`d3-shape/src/line.js:7-57`).
class Line<T> {
  /// Creates a line generator.
  Line({
    required this.x,
    required this.y,
    this.defined = _alwaysDefined,
    this.curve = curveLinear,
  });

  /// The x accessor.
  Accessor<T> x;

  /// The y accessor.
  Accessor<T> y;

  /// The gap predicate.
  Defined<T> defined;

  /// The curve factory.
  D3CurveFactory curve;

  /// Emits [data] into [sink].
  void call(List<T> data, PathSink sink) {
    final output = curve(sink);
    final n = data.length;
    var defined0 = false;
    // line.js:26 — the loop runs to n INCLUSIVE, so the trailing lineEnd fires.
    for (var i = 0; i <= n; i++) {
      final isDefined = i < n && defined(data[i], i, data);
      if (!isDefined == defined0) {
        defined0 = !defined0;
        if (defined0) {
          output.lineStart();
        } else {
          output.lineEnd();
        }
      }
      // `defined0` can only be set while `isDefined` held, which requires
      // i < n, so the index is always in range here (line.js:31).
      if (defined0) {
        final d = data[i];
        output.point(x(d, i, data), y(d, i, data));
      }
    }
  }
}

/// An area generator (`d3-shape/src/area.js:8-111`).
class Area<T> {
  /// Creates an area generator. [x1] and [y1] default to [x0] and [y0].
  Area({
    required this.x0,
    required this.y0,
    this.x1,
    this.y1,
    this.defined = _alwaysDefined,
    this.curve = curveLinear,
  });

  /// The baseline x accessor.
  Accessor<T> x0;

  /// The baseline y accessor.
  Accessor<T> y0;

  /// The topline x accessor; `null` reuses [x0].
  Accessor<T>? x1;

  /// The topline y accessor; `null` reuses [y0].
  Accessor<T>? y1;

  /// The gap predicate, honoured on the reverse replay as well.
  Defined<T> defined;

  /// The curve factory.
  D3CurveFactory curve;

  /// Emits [data] into [sink].
  ///
  /// The top edge is emitted forwards, then `lineEnd(); lineStart();` and the
  /// buffered baseline is replayed **in reverse through the same curve
  /// instance** (`d3-shape/src/area.js:39-47`). With `curveMonotoneX` or
  /// `curveBumpX` the baseline is therefore itself a curve, not a straight
  /// line — the single easiest thing in this port to get subtly wrong.
  void call(List<T> data, PathSink sink) {
    final output = curve(sink);
    final n = data.length;
    // The 0 is only a fill for `List.filled`; every slot read back below was
    // written first, on the same iteration that made `defined0` true
    // (`area.js:9`, where JavaScript leaves the holes undefined).
    final x0z = List<double>.filled(n, 0);
    final y0z = List<double>.filled(n, 0);
    var defined0 = false;
    // The index the current defined run started at (`area.js:31`), so the
    // reverse replay knows where to stop.
    var j = 0;
    for (var i = 0; i <= n; i++) {
      final isDefined = i < n && defined(data[i], i, data);
      if (!isDefined == defined0) {
        defined0 = !defined0;
        if (defined0) {
          j = i;
          output
            ..areaStart()
            ..lineStart();
        } else {
          output
            ..lineEnd()
            ..lineStart();
          for (var k = i - 1; k >= j; k--) {
            output.point(x0z[k], y0z[k]);
          }
          output
            ..lineEnd()
            ..areaEnd();
        }
      }
      if (defined0) {
        final d = data[i];
        x0z[i] = x0(d, i, data);
        y0z[i] = y0(d, i, data);
        output.point(
          x1 != null ? x1!(d, i, data) : x0z[i],
          y1 != null ? y1!(d, i, data) : y0z[i],
        );
      }
    }
  }
}
