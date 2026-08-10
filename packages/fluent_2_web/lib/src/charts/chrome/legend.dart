import 'package:fluent_2_core/fluent_2_core.dart';
// `listEquals` is not in the `show` list `widgets.dart` re-exports foundation
// with, so it has to be imported directly.
import 'package:flutter/foundation.dart';
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
        child: MouseRegion(
          // FluentInteractive folds hover into its WidgetState set and reports
          // nothing outward (internal/interaction.dart:206-208). A legend hover
          // is a side effect on the plot, not a visual state on this row, so it
          // is observed here rather than by extending a widget every button in
          // the package depends on.
          onEnter: (_) => onHighlightChanged?.call(true),
          onExit: (_) => onHighlightChanged?.call(false),
          child: Focus(
            // Legends.tsx:316-319 — onFocus is onMouseOver and onBlur is
            // onMouseOut, so keyboard traversal highlights the series exactly as
            // a pointer hover does. This node must not steal focus from the
            // FluentInteractive below it, and onFocusChange on a non-focusable
            // node still reports descendant focus, which is what carries the
            // row's own focus through to the chart.
            canRequestFocus: false,
            skipTraversal: skipTraversal,
            onFocusChange: (hasFocus) => onHighlightChanged?.call(hasFocus),
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

/// Applies a [FluentChartLegendStyle] to every [FluentChartLegend] below it.
class FluentChartLegendTheme extends InheritedTheme {
  /// Applies [style] to every legend in [child].
  const FluentChartLegendTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the theme-derived defaults.
  final FluentChartLegendStyle style;

  /// The nearest legend style, or null.
  static FluentChartLegendStyle? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FluentChartLegendTheme>()
      ?.style;

  @override
  bool updateShouldNotify(FluentChartLegendTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentChartLegendTheme(style: style, child: child);
}

/// The Fluent 2 chart legend: a horizontal strip of selectable series markers.
///
/// Ports `Legends` (`Legends.tsx`). It is one of the twenty user-facing chart
/// components and is also rendered by the cartesian shell for the nine charts
/// that use it.
///
/// Two upstream behaviours are worth naming because they surprise readers:
/// selecting *every* legend in multi-select mode clears the selection
/// (`Legends.tsx:225-227`), and hovering a legend highlights the series exactly
/// as focusing it does (`:316-319`).
class FluentChartLegend extends StatefulWidget {
  /// Creates a legend strip.
  const FluentChartLegend({
    super.key,
    required this.legends,
    // Legends.tsx:101 — canSelectMultipleLegends defaults to false.
    this.selectionMode = FluentChartLegendSelectionMode.single,
    // Legends.tsx:101 — allowFocusOnLegends defaults to true.
    this.allowFocusOnLegends = true,
    this.centerLegends = false,
    this.enabledWrapLines = false,
    // Legends.tsx:108 — `props.overflowText ? props.overflowText : 'more'`.
    this.overflowText = 'more',
    this.selectedLegends,
    this.defaultSelectedLegends,
    this.onChange,
    this.shape,
    this.style,
  });

  /// The rows, in order.
  final List<FluentChartLegendItem> legends;

  /// Whether one legend or several may be selected at once.
  final FluentChartLegendSelectionMode selectionMode;

  /// Whether the rows are reachable by keyboard and carry listbox semantics.
  /// `Legends.tsx:270`.
  final bool allowFocusOnLegends;

  /// Whether each line of legends is centred in the strip. `Legends.tsx:115`.
  final bool centerLegends;

  /// Whether rows wrap onto further lines instead of collapsing into an
  /// overflow menu. `Legends.tsx:109`.
  final bool enabledWrapLines;

  /// The word in the overflow trigger's `+{n} {overflowText}` label.
  /// `OverflowMenu.tsx:16`.
  final String overflowText;

  /// Controlled selection. Supplying it makes the widget controlled
  /// (`Legends.tsx:207-209`) and the parent owns every change.
  final List<String>? selectedLegends;

  /// Initial selection for the uncontrolled case. `Legends.tsx:76`.
  final List<String>? defaultSelectedLegends;

  /// Fired with the new selection and the row that caused it.
  /// `Legends.tsx:250`.
  final void Function(List<String> selected, FluentChartLegendItem? current)?
  onChange;

  /// Overrides every per-item shape when set. `Legends.tsx:192`.
  final FluentChartLegendShape? shape;

  /// The highest-precedence style layer.
  final FluentChartLegendStyle? style;

  @override
  State<FluentChartLegend> createState() => _FluentChartLegendState();
}

class _FluentChartLegendState extends State<FluentChartLegend> {
  Set<String> _selected = <String>{};

  /// The hovered or focused legend, or the empty string when there is none —
  /// the same sentinel `Legends.tsx:49` uses, which `:407` then tests for.
  String _activeLegend = '';

  final List<FocusNode> _nodes = <FocusNode>[];
  int _focusedIndex = 0;

  @override
  void initState() {
    super.initState();
    _seedSelection();
    _syncNodes();
  }

  @override
  void didUpdateWidget(FluentChartLegend oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Legends.tsx:91-97 re-runs the seeding effect whenever any of the
    // selection props changes, so a controlled parent swapping the array resets
    // the internal state. `// parity:` — reproduced, including the reset.
    if (!listEquals(widget.selectedLegends, oldWidget.selectedLegends) ||
        !listEquals(
          widget.defaultSelectedLegends,
          oldWidget.defaultSelectedLegends,
        ) ||
        widget.selectionMode != oldWidget.selectionMode) {
      _seedSelection();
    }
    _syncNodes();
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _seedSelection() {
    final initial = widget.selectedLegends ?? widget.defaultSelectedLegends;
    _selected = initial == null ? <String>{} : Set<String>.of(initial);
  }

  void _syncNodes() {
    while (_nodes.length < widget.legends.length) {
      _nodes.add(FocusNode(debugLabel: 'FluentChartLegend'));
    }
    while (_nodes.length > widget.legends.length) {
      _nodes.removeLast().dispose();
    }
    if (_focusedIndex >= _nodes.length) _focusedIndex = 0;
  }

  bool get _isControlled => widget.selectedLegends != null;

  void _handlePressed(int index) {
    final item = widget.legends[index];
    final next = nextFluentChartLegendSelection(
      _selected,
      item.title,
      mode: widget.selectionMode,
      legendCount: widget.legends.length,
    );
    // Legends.tsx:247-249 — only the uncontrolled case updates itself.
    if (!_isControlled) setState(() => _selected = next);
    widget.onChange?.call(next.toList(growable: false), item);
    // Legends.tsx:251 — the row's own action runs last.
    item.onAction?.call();
  }

  void _handleHighlight(int index, {required bool highlighted}) {
    final item = widget.legends[index];
    if (highlighted) {
      // Legends.tsx:254-259 — the active legend is only recorded when the item
      // actually supplies a hover action.
      if (item.onHoverAction == null) return;
      setState(() => _activeLegend = item.title);
      item.onHoverAction!.call();
    } else {
      if (item.onMouseOutAction == null) return;
      setState(() => _activeLegend = '');
      item.onMouseOutAction!.call(isLegendFocused: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final style = resolveFluentChartLegendStyle(
      theme,
    ).merge(FluentChartLegendTheme.maybeOf(context)).merge(widget.style);

    final rows = <Widget>[
      for (var index = 0; index < widget.legends.length; index++)
        FluentChartLegendRow(
          key: ValueKey<String>(widget.legends[index].title),
          item: widget.legends[index],
          shapeOverride: widget.shape,
          dimmed: fluentChartLegendIsDimmed(
            widget.legends[index].title,
            selectedLegends: _selected,
            activeLegend: _activeLegend,
          ),
          selected: _selected.contains(widget.legends[index].title),
          indexInList: index,
          listLength: widget.legends.length,
          style: style,
          focusNode: _nodes[index],
          skipTraversal: !widget.allowFocusOnLegends || index != _focusedIndex,
          onPressed: () => _handlePressed(index),
          onHighlightChanged: (highlighted) =>
              _handleHighlight(index, highlighted: highlighted),
        ),
    ];

    return Padding(
      padding: style.containerMargin!.resolve(<WidgetState>{})!,
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        // Legends.tsx:124 — the listbox is labelled 'Legends', and only when
        // allowFocusOnLegends is set does the role appear at all (:122).
        label: widget.allowFocusOnLegends ? 'Legends' : null,
        child: Wrap(
          alignment: widget.centerLegends
              ? WrapAlignment.center
              : WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: rows,
        ),
      ),
    );
  }
}
