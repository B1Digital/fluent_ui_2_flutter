/// Sorts [input] with [compare], keeping equal elements in their input order,
/// and returns a new list.
///
/// Dart's `List.sort` is documented as not stable; V8's `Array.prototype.sort`
/// has been stable since ES2019. Three ported call sites tie routinely and
/// depend on the JavaScript behaviour:
///
/// * d3-sankey's `ascendingBreadth` comparator returns `0` whenever two nodes
///   share a `y0`, and it is applied to every column on both directions of all
///   six relaxation iterations (`d3-sankey/src/sankey.js:263,286`) — twelve
///   opportunities per layout for an unstable sort to shuffle the diagram.
/// * `sortAxisCategories` (`utilities.ts:2105`) sorts categories by an
///   aggregated value, where ties are common and the tie order is the axis
///   order the user sees.
/// * d3-shape's `pie` sorts arc indices by value (`d3-shape/src/pie.js:37`).
///
/// The implementation decorates with the input index and breaks ties on it,
/// which is what a stable sort is. [input] itself is never mutated: d3 sorts an
/// index array, and the sankey columns are re-sorted repeatedly over the same
/// node objects.
List<T> stableSort<T>(List<T> input, int Function(T a, T b) compare) {
  final indices = List<int>.generate(input.length, (int i) => i);
  indices.sort((int a, int b) {
    final ordering = compare(input[a], input[b]);
    return ordering != 0 ? ordering : a - b;
  });
  return List<T>.generate(
    indices.length,
    (int i) => input[indices[i]],
    growable: false,
  );
}
