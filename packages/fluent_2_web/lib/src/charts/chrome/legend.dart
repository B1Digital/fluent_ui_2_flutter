import 'package:flutter/widgets.dart';

import '../internal/chart_utils.dart';
import 'legend_shape.dart';

/// Whether a legend strip allows one selection or several.
///
/// `Legends.tsx:101` defaults `canSelectMultipleLegends` to `false`, so
/// [FluentChartLegendSelectionMode.single] is the default.
enum FluentChartLegendSelectionMode {
  /// One legend at a time. Clicking the selected one clears the selection
  /// (`Legends.tsx:237-239`).
  single,

  /// Any number at once, with "all selected" canonicalised to "none selected"
  /// (`Legends.tsx:225-227`).
  multiple,
}

/// One row of a `FluentChartLegend`.
///
/// Ports `Legend` (`Legends.types.ts:68-123`). `nativeButtonProps` is dropped:
/// it is commented out at its only construction site (`Legends.tsx:175-186`).
@immutable
class FluentChartLegendItem {
  /// Creates one legend row.
  const FluentChartLegendItem({
    required this.title,
    required this.color,
    this.shape,
    this.opacity,
    this.stripePattern = false,
    this.isLineLegendInBarChart = false,
    this.onAction,
    this.onHoverAction,
    this.onMouseOutAction,
    this.annotationBuilder,
  });

  /// The label. Title-cased by [capitalizeLegendLabel] before it is measured or
  /// painted, matching `useLegendsStyles.styles.ts:56`.
  final String title;

  /// The series colour. Also the swatch border colour, which is never dimmed
  /// (`Legends.tsx:366`).
  final Color color;

  /// Marker to draw, or null for the plain bordered rectangle.
  final FluentChartLegendShape? shape;

  /// Swatch opacity carried through from the series. `Legends.types.ts:97`.
  final double? opacity;

  /// Whether the swatch is filled with the diagonal stripe pattern instead of a
  /// flat colour. `Legends.tsx:297`, `:379-381`.
  final bool stripePattern;

  /// Whether this row represents a line overlaid on a bar chart, which renders
  /// as a 4px bar rather than a 12px square. `Legends.tsx:296`, `:376`.
  final bool isLineLegendInBarChart;

  /// Fired after the selection has been updated. `Legends.tsx:251`.
  final VoidCallback? onAction;

  /// Fired on pointer-enter **and** on focus — `Legends.tsx:316` and `:318`
  /// wire both to the same handler, so keyboard focus highlights the series
  /// exactly as a hover does.
  final VoidCallback? onHoverAction;

  /// Fired on pointer-exit (`Legends.tsx:317`) and on blur (`:319`).
  ///
  /// Named-argument form because `avoid_positional_boolean_parameters` is in
  /// force and the upstream signature is
  /// `(isLegendFocused?: boolean) => void` (`Legends.types.ts:87`).
  final void Function({required bool isLegendFocused})? onMouseOutAction;

  /// Extra content rendered beside the row.
  ///
  /// `Legends.tsx:163` renders it **only** in the wrapped-lines branch and
  /// silently drops it in overflow mode. `// parity:` — reproduced.
  final WidgetBuilder? annotationBuilder;
}

// Title-casing lives in `../internal/chart_utils.dart` as
// `capitalizeLegendLabel`, landed by plan 02. It is imported here rather than
// redeclared: it has two callers — this file and `internal/image_export.dart` —
// and spec §5.4's parity claim only holds if the exported legend strip and the
// on-screen legend capitalise identically.

/// The selection set after [title] is activated.
///
/// Ports `_getNewSelectedLegendsForMultiselect` (`Legends.tsx:216-230`) and
/// `_getNewSelectedLegendsForSingleSelect` (`:237-239`). Pure and non-mutating,
/// because `Legends.tsx:247` compares the result against the previous state to
/// decide whether the component is controlled.
Set<String> nextFluentChartLegendSelection(
  Set<String> current,
  String title, {
  required FluentChartLegendSelectionMode mode,
  required int legendCount,
}) {
  if (mode == FluentChartLegendSelectionMode.single) {
    // Legends.tsx:238.
    return current.contains(title) ? <String>{} : <String>{title};
  }
  final next = Set<String>.of(current);
  if (!next.remove(title)) {
    next.add(title);
    // Legends.tsx:225-227 — "all selected" is canonicalised as "none selected".
    if (next.length == legendCount) {
      return <String>{};
    }
  }
  return next;
}
