/// The shape a legend swatch and a popover swatch are drawn with.
///
/// Ports `LegendShape` (`Legends.types.ts:269`), which is the union of the
/// literals `'default'` and `'triangle'` with the keys of `Points`
/// (`utilities.ts:1713-1721`) and `CustomPoints` (`:1723-1725`). `'triangle'`
/// appears on both sides of that union, so the ten Dart values below are the
/// complete set.
///
/// The painter, the path builder and the stripe painter for these shapes are
/// added to this file at stage 6; the enum lives here from stage 3 because four
/// `model/` files carry a `legendShape` field.
enum FluentChartLegendShape {
  /// `'default'` — the filled rectangle every chart falls back to.
  defaultShape(null),

  /// `'triangle'` — the standalone literal at `Legends.types.ts:269`, distinct
  /// from `Points.triangle` only in that a chart may name it without the
  /// `Points` table being consulted.
  triangle(2),

  /// `Points.circle` (`utilities.ts:1714`).
  circle(0),

  /// `Points.square` (`utilities.ts:1715`).
  square(1),

  /// `Points.diamond` (`utilities.ts:1717`).
  diamond(3),

  /// `Points.pyramid` (`utilities.ts:1718`).
  pyramid(4),

  /// `Points.hexagon` (`utilities.ts:1719`).
  hexagon(5),

  /// `Points.pentagon` (`utilities.ts:1720`).
  pentagon(6),

  /// `Points.octagon` (`utilities.ts:1721`).
  octagon(7),

  /// `CustomPoints.dottedLine` (`utilities.ts:1724`).
  dottedLine(null);

  const FluentChartLegendShape(this.pointIndex);

  /// This shape's ordinal in upstream's `Points` enum, or null when it is not a
  /// member of it.
  ///
  /// `ChartPopover.tsx:216` selects a swatch with `Points[index % 8]`, so the
  /// ordinals are load-bearing and cannot be renumbered.
  final int? pointIndex;
}
