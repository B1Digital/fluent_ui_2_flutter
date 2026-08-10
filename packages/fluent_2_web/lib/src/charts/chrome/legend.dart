import 'package:flutter/widgets.dart';

import '../../internal/focus_ring.dart';
import '../../internal/interaction.dart';
import '../internal/chart_utils.dart';
import 'legend_shape.dart';
import 'legend_style.dart';

// Two upstream expressions have no Dart counterpart and are deliberately not
// ported rather than reproduced as dead code:
//
// * `Legends.tsx:298` and `:378` both read
//   `legend.color ? legend.color : tokens.colorNeutralStroke1`.
//   `FluentChartLegendItem.color` is non-nullable, so the `neutralStroke1` arm
//   is unreachable here.
// * `aria-setsize` (`Legends.tsx:345`) has no `SemanticsProperties` field in
//   Flutter 3.44 — `IndexedSemantics` covers `aria-posinset` and nothing covers
//   the set size. [FluentChartLegendRow.listLength] therefore carries the
//   number for the day the framework gains one, and is not read today.

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

/// Whether [title]'s swatch and label are drawn in their dimmed treatment.
///
/// Ports `_getColor` (`Legends.tsx:390-416`) as a predicate: the colour choice
/// itself lives in the style, but the *decision* is shared by the swatch fill,
/// the label opacity and the high-contrast swatch opacity, which upstream
/// re-derives by comparing the returned colour against
/// `tokens.colorNeutralBackground1` at `:306` and `:383`. Comparing colours to
/// discover intent is fragile in Dart, where a series may legitimately be that
/// colour, so the predicate is computed once and passed down.
///
/// [activeLegend] is the empty string when nothing is hovered, matching the
/// initial state at `Legends.tsx:49`.
bool fluentChartLegendIsDimmed(
  String title, {
  required Set<String> selectedLegends,
  required String activeLegend,
}) {
  // Legends.tsx:393 — the selection branch is tested first and never falls
  // through, so a selected legend stays lit while a different one is hovered.
  if (selectedLegends.isNotEmpty) return !selectedLegends.contains(title);
  // Legends.tsx:407 — `activeLegend === title || activeLegend === ''`.
  return activeLegend.isNotEmpty && activeLegend != title;
}

/// Height of a legend swatch that stands for a line drawn over a bar chart.
///
/// `Legends.tsx:296` and `:376` both set the swatch height to `4px` when
/// `isLineLegendInBarChart` is set, against `12px` otherwise — and 12 is the
/// *content* box, which [kLegendSwatchBoxSize] grows by the border.
const double kLegendLineInBarHeight = 4;

/// One row of the legend strip: swatch, then title-cased label.
///
/// Built from [FluentInteractive] and [FluentFocusRing] rather than
/// `FluentButton`. `useLegendsStyles.styles.ts:48-74` overrides three of the
/// four things `FluentButton`'s appearance/size tuple decides — `border: none`
/// at `:54` kills the outline border, `padding: 8px` at `:55` replaces `h8/v2`,
/// and `min-width: 0` at `:59` removes the 64px floor — leaving exactly
/// `FluentInteractive + FluentFocusRing + Row`, which is what this builds.
class FluentChartLegendRow extends StatelessWidget {
  /// Creates one legend row.
  const FluentChartLegendRow({
    super.key,
    required this.item,
    required this.shapeOverride,
    required this.dimmed,
    required this.selected,
    required this.indexInList,
    required this.listLength,
    required this.style,
    required this.focusNode,
    required this.skipTraversal,
    this.onPressed,
    this.onHighlightChanged,
  });

  /// The legend this row represents.
  final FluentChartLegendItem item;

  /// `LegendsProps.shape` (`Legends.tsx:192`), which overrides every per-item
  /// shape when it is set.
  final FluentChartLegendShape? shapeOverride;

  /// Whether the row is in its filtered-out treatment.
  final bool dimmed;

  /// Whether the row is part of the current selection. Drives `aria-selected`
  /// (`Legends.tsx:341`).
  final bool selected;

  /// Zero-based position, reported through [IndexedSemantics]. Upstream's
  /// `aria-posinset` is `index + 1` (`Legends.tsx:346`); the Dart side stays
  /// zero-based and the platform adds one.
  final int indexInList;

  /// Size of the **full** legend list, including any rows in the overflow menu
  /// (`Legends.tsx:345`).
  ///
  /// Not read: Flutter has no `aria-setsize` counterpart. See the note at the
  /// top of this file.
  final int listLength;

  /// Resolved visual configuration.
  final FluentChartLegendStyle style;

  /// This row's focus node, owned by the parent so the roving index can move
  /// focus without rebuilding.
  final FocusNode focusNode;

  /// Whether Tab skips this row. True for every row except the memorised one,
  /// which is what makes the strip a single tab stop
  /// (`useArrowNavigationGroup({ memorizeCurrent: true })`, `Legends.tsx:52`).
  final bool skipTraversal;

  /// Invoked on tap and on Space or Enter.
  final VoidCallback? onPressed;

  /// Invoked with true on pointer-enter **or** focus and false on pointer-exit
  /// or blur. `Legends.tsx:316-319` wires both pairs to the same handlers.
  final ValueChanged<bool>? onHighlightChanged;

  @override
  Widget build(BuildContext context) {
    const states = <WidgetState>{};
    final swatchSize = style.swatchSize!.resolve(states)!;
    final marginEnd = style.swatchMarginEnd!.resolve(states)!;
    final padding = style.rowPadding!.resolve(states)!;
    final radius = style.rowBorderRadius!.resolve(states)!;
    final labelStyle = style.labelTextStyle!.resolve(states)!;
    final fill = dimmed
        ? style.dimmedSwatchColor!.resolve(states)!
        : item.color;
    final labelOpacity = dimmed
        ? style.dimmedLabelOpacity!.resolve(states)!
        : 1.0;
    final swatchOpacity = dimmed
        ? style.dimmedSwatchOpacity!.resolve(states)!
        : 1.0;

    // Legends.tsx:376 — a line legend inside a bar chart is a 4px bar.
    final swatchHeight = item.isLineLegendInBarChart
        ? kLegendLineInBarHeight
        : swatchSize;
    final label = capitalizeLegendLabel(item.title);

    return IndexedSemantics(
      index: indexInList,
      child: Semantics(
        container: true,
        button: true,
        selected: selected,
        // Legends.tsx:343 — aria-label is the title, which overrides the
        // element's own text content for a screen reader. excludeSemantics
        // reproduces that override instead of announcing the label twice.
        label: label,
        excludeSemantics: true,
        child: FluentInteractive(
          focusNode: focusNode,
          onPressed: onPressed,
          builder: (context, interactionStates, child) => FluentFocusRing(
            visible: interactionStates.contains(WidgetState.focused),
            borderRadius: radius,
            child: Padding(padding: padding, child: child!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Opacity(
                opacity: swatchOpacity,
                child: SizedBox(
                  key: const ValueKey<String>('legend-swatch'),
                  width: swatchSize,
                  height: swatchHeight,
                  child: _buildSwatch(fill: fill),
                ),
              ),
              SizedBox(width: marginEnd),
              Opacity(
                opacity: labelOpacity,
                child: Text(label, style: labelStyle, maxLines: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwatch({required Color fill}) {
    final shape = shapeOverride ?? item.shape;
    if (item.stripePattern) {
      // Legends.tsx:297 blanks the flat background when a stripe pattern is
      // set, so the stripes are the whole fill.
      return CustomPaint(painter: FluentChartStripePainter(color: fill));
    }
    if (shape == null || shape == FluentChartLegendShape.defaultShape) {
      // shape.tsx:35 — the fallback bordered rectangle.
      return DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          border: Border.all(
            color: item.color,
            width: style.swatchBorderWidth!.resolve(<WidgetState>{})!,
          ),
        ),
      );
    }
    return CustomPaint(
      painter: FluentChartLegendShapePainter(
        shape: shape,
        fill: fill,
        // Legends.tsx:366 — never dimmed.
        stroke: item.color,
      ),
    );
  }
}
