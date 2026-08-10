import 'package:fluent_2_core/fluent_2_core.dart';
// `listEquals` is not in the `show` list `widgets.dart` re-exports foundation
// with, so it has to be imported directly.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'
    show KeyDownEvent, KeyEvent, KeyRepeatEvent, LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

import '../../buttons/button.dart';
import '../../internal/focus_ring.dart';
import '../../internal/interaction.dart';
import '../../overlays/menu.dart';
import '../../overlays/menu_item.dart';
import '../internal/chart_text_measurer.dart';
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
//
// Three things about the overflow menu this port cannot reproduce faithfully:
//
// * Whether activating a checkbox row closes the menu is governed by
//   `@fluentui/react-menu` and `persistOnItemClick` is never passed
//   (`OverflowMenu.tsx:58`), so upstream's behaviour is **UNKNOWN from this
//   tree**. `FluentMenu` always closes on activation (`menu.dart:516`), which
//   makes a multi-select legend awkward — every pick reopens the menu. Fixing it
//   means a `persistOnItemClick` flag on `FluentMenu`, which is another task's
//   file. Reported rather than forked.
// * The overflow rows forward hover and focus to the legend's highlight
//   handlers upstream (`OverflowMenu.tsx:42-45`). `FluentMenuItem` has no hover
//   or focus callback, so that highlight is dropped. Upgrade path: one
//   `onHoverChanged` field on the existing `FluentMenuItem` model.
// * `OverflowMenu.tsx:39` passes `checkmark={null}` and renders the whole legend
//   row — swatch included — as the menu row's content. `FluentMenuItem` paints
//   the checkmark in the very slot an icon would take (`menu_item.dart:476-491`)
//   and the checkmark wins, so the swatch cannot ride along; the checkmark
//   carries the selection instead. `// ponytail:` — the label plus a checkmark
//   is the smallest thing that still tells the reader which series is which and
//   which are selected. Upgrade path: the same `icon`/`checkmark` split
//   upstream has, if a second widget ever needs it.

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

/// Laid-out width of one legend row, in logical pixels.
///
/// The same arithmetic `cloneLegendsToSVG` uses
/// (`image-export-utils.ts:313-315`): padding, swatch, gap, measured text,
/// padding — except the swatch is [kLegendSwatchBoxSize], because that is the
/// on-screen footprint, where the exporter substitutes [kLegendShapeSize].
/// `charts-legends--legends-overflow` settles which: its swatch boxes are 14
/// wide and its row pitch is the label plus 38.
///
/// The label is title-cased before it is measured. `measureTextWithDOM` copies
/// `text-transform` (`utilities.ts:2137-2144`) while the canvas measurer at
/// `:1265` does not, so upstream measures the legend post-capitalisation and
/// axis labels pre-capitalisation. This is the legend path.
double fluentChartLegendRowWidth(
  String title,
  TextStyle style,
  FluentChartTextMeasurer measurer,
) =>
    kLegendPadding +
    kLegendSwatchBoxSize +
    kLegendShapeMarginEnd +
    measurer.width(capitalizeLegendLabel(title), style) +
    kLegendPadding;

/// How many rows stay in the listbox before the rest collapse into the menu.
///
/// `useOverflowMenu` (`@fluentui/react-overflow`) is not in the extracted
/// source, so its measurement is **UNKNOWN from that tree**; only its
/// configuration is knowable. This computes the count from measured widths on
/// the single line the strip occupies, reserving [triggerWidth] because the
/// trigger is a sibling of the listbox and shares the line
/// (`Legends.tsx:135`).
///
/// ponytail: one line, no gap term — upstream's flex line has no gap either
/// (`Legends.tsx:129-133`), and `charts-legends--legends-overflow` confirms it:
/// its swatch pitch is exactly one row width. The remaining uncertainty is the
/// trigger, whose rendered width that capture does not record. Probe that
/// settles it: capture the story at a sequence of widths with Oracle B and
/// compare the visible count.
int fluentChartLegendVisibleCount(
  List<double> rowWidths,
  double available,
  double triggerWidth,
) {
  var total = 0.0;
  for (final width in rowWidths) {
    total += width;
  }
  // OverflowMenu.tsx:18-20 renders nothing at all when nothing overflows, so
  // the trigger costs nothing in that case.
  if (total <= available) return rowWidths.length;

  final budget = available - triggerWidth;
  var fitted = 0;
  var running = 0.0;
  for (final width in rowWidths) {
    running += width;
    if (running > budget) break;
    fitted++;
  }
  // A bare "+n more" with no visible legend has no context; keep one row.
  return fitted == 0 ? 1 : fitted;
}

/// Margin around one row in the wrapped-lines layout.
///
/// `useLegendsStyles.styles.ts:125` — `margin: 4px` on `legendContainer`, which
/// exists only in that branch (`Legends.tsx:159`). Doubles as the annotation gap
/// (`:130`). Declared here rather than in `legend_style.dart` because only this
/// layout reads it; it is not a style slot.
const double kLegendWrappedContainerMargin = 4;

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

    // The roving flag has to land on the node [FluentInteractive] actually
    // focuses: `FocusNode.skipTraversal` is only inherited downwards through an
    // ancestor's `descendantsAreTraversable`, so setting it on the wrapper below
    // would leave every row in the Tab order. Written here rather than as
    // `descendantsAreTraversable: false` on that wrapper because
    // `FocusableActionDetector` passes no `skipTraversal` of its own, which
    // makes its `Focus` read the derived value and write it back onto the node
    // as a hard flag — the latch `FluentNav._unlatch` exists to undo. Assigning
    // the node directly is idempotent under that write-back, so there is
    // nothing to undo.
    focusNode.skipTraversal = skipTraversal;

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
    // shape.tsx:34 dispatches on the shape alone, before anything else: a key
    // of `pointPath` renders the `<svg>` at :37, and only a miss falls through
    // to the `classNameForNonSvg` div at :35. The stripe pattern is a `content`
    // declaration on that div (Legends.tsx:379-381), so it is unreachable for
    // the eight Points shapes — the dispatch has to come first here too.
    if (shape != null && shape != FluentChartLegendShape.defaultShape) {
      return CustomPaint(
        painter: FluentChartLegendShapePainter(
          shape: shape,
          fill: fill,
          // Legends.tsx:366 — never dimmed.
          stroke: item.color,
        ),
      );
    }
    // shape.tsx:35 — the fallback rectangle. It carries
    // `useLegendsStyles.styles.ts:82` `border: 1px solid` unconditionally,
    // coloured from `legend.color` (Legends.tsx:378), which is never dimmed.
    // Legends.tsx:377 blanks only the *background colour* for a stripe
    // pattern, so a striped swatch is this same bordered box with the stripes
    // painted into it — without the border a dimmed striped swatch is filled
    // with the page background and vanishes.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: item.stripePattern ? null : fill,
        border: Border.all(
          color: item.color,
          width: style.swatchBorderWidth!.resolve(<WidgetState>{})!,
        ),
      ),
      child: item.stripePattern
          ? CustomPaint(painter: FluentChartStripePainter(color: fill))
          : null,
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
///
/// The strip is one tab stop with a roving index inside it: Left, Right, Home
/// and End move between rows and the last row reached keeps the stop
/// (`useArrowNavigationGroup({axis: 'horizontal', memorizeCurrent: true})`,
/// `Legends.tsx:52`). Wrapping at both ends, and the absence of typeahead or
/// Escape-to-exit, are `@fluentui/react-tabster` defaults rather than anything
/// this tree states — that package is not in the extracted source. Probe that
/// settles it: drive `charts-legends--legends-basic` and record the focus order
/// for each key.
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

  /// Owned by the state rather than built per frame so its cache survives a
  /// rebuild — the overflow branch measures every label on every layout.
  final FluentChartTextMeasurer _measurer = FluentChartTextMeasurer();

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

  void _moveFocus(int delta) {
    if (_nodes.isEmpty) return;
    // Wrapping in both directions. tabster's arrow navigation group is
    // circular by default; the option is not passed at Legends.tsx:52 and
    // @fluentui/react-tabster is not in the extracted source, so this is
    // derived from its documented default rather than ported.
    // Dart's `%` is non-negative for a positive divisor, so one expression
    // covers both directions — the same modulo walk as FluentToolbar._seek.
    setState(() => _focusedIndex = (_focusedIndex + delta) % _nodes.length);
    _nodes[_focusedIndex].requestFocus();
  }

  void _focusEdge({required bool last}) {
    if (_nodes.isEmpty) return;
    setState(() => _focusedIndex = last ? _nodes.length - 1 : 0);
    _nodes[_focusedIndex].requestFocus();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    // Arrow keys are physical; the legend list is logical. In an RTL subtree the
    // two disagree, and it is the arrows that must bend.
    final rtl = Directionality.of(context) == TextDirection.rtl;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowRight:
        _moveFocus(rtl ? -1 : 1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        _moveFocus(rtl ? 1 : -1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.home:
        _focusEdge(last: false);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.end:
        _focusEdge(last: true);
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  void _handleHighlight(int index, {required bool highlighted}) {
    // Keeps the memorised stop on whichever row the user actually reached, so a
    // click, a Tab and an arrow press all leave the strip in the same state.
    // Guarded on the node because this callback is also the pointer-hover path,
    // and a hover must not move the tab stop.
    if (highlighted && _focusedIndex != index && _nodes[index].hasFocus) {
      setState(() => _focusedIndex = index);
    }
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

  /// Every row, wrapping onto further lines, each beside its annotation.
  ///
  /// `Legends.tsx:142-169` — no overflow menu exists in this branch at all.
  Widget _buildWrapped(List<Widget> rows) => Wrap(
    alignment: widget.centerLegends
        ? WrapAlignment.center
        : WrapAlignment.start,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: <Widget>[
      for (var index = 0; index < rows.length; index++)
        Padding(
          // useLegendsStyles.styles.ts:125 — `margin: 4px` on legendContainer,
          // which charts-legends--legends-wrap-lines captures as an 8px gap
          // between adjacent containers.
          padding: const EdgeInsets.all(kLegendWrappedContainerMargin),
          child: widget.legends[index].annotationBuilder == null
              ? rows[index]
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  // useLegendsStyles.styles.ts:127-131 — flex, centred, 4px gap.
                  children: <Widget>[
                    rows[index],
                    const SizedBox(width: kLegendWrappedContainerMargin),
                    Builder(builder: widget.legends[index].annotationBuilder!),
                  ],
                ),
        ),
    ],
  );

  /// One line of rows, with the tail collapsed into a menu.
  ///
  /// `Legends.tsx:111-140`. The annotation slot does not exist here, which is
  /// upstream's own asymmetry (`:129-133` against `:159-164`).
  Widget _buildOverflow(
    List<Widget> rows,
    FluentChartLegendStyle style,
    FluentThemeData theme,
  ) {
    final labelStyle = style.labelTextStyle!.resolve(<WidgetState>{})!;
    // FluentButton medium sets body1Strong (button.dart:264) and 12 of padding
    // each side (:257) inside a 1px secondary border (:280-282).
    final triggerStyle = theme.typography.body1Strong;
    return LayoutBuilder(
      builder: (context, constraints) {
        final widths = <double>[
          for (final item in widget.legends)
            fluentChartLegendRowWidth(item.title, labelStyle, _measurer),
        ];
        // The trigger reads `+{n} {overflowText}`; its widest form is the whole
        // list in the menu, so measure that (OverflowMenu.tsx:16).
        final triggerWidth =
            _measurer.width(
              _triggerLabel(widget.legends.length),
              triggerStyle,
            ) +
            2 * (FluentSpacing.m + FluentStroke.thin);
        final visible = fluentChartLegendVisibleCount(
          widths,
          constraints.maxWidth,
          triggerWidth,
        );
        final overflowing = visible < rows.length;
        final strip = ConstraintsTransformBox(
          constraintsTransform: ConstraintsTransformBox.maxWidthUnconstrained,
          // useLegendsStyles.styles.ts:44 is `whiteSpace: nowrap` and the
          // resizable area is capped at 800 (`:116`): an over-long strip is cut
          // off, never wrapped. hardEdge is that. It matters because
          // [fluentChartLegendVisibleCount] keeps one row even when one row does
          // not fit — without the clip that row would report a layout overflow.
          clipBehavior: Clip.hardEdge,
          alignment: AlignmentDirectional.centerStart,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: rows.take(visible).toList(growable: false),
          ),
        );
        return Row(
          mainAxisSize: MainAxisSize.min,
          // Legends.tsx:115 — `textAlign: center` when centerLegends is set.
          mainAxisAlignment: widget.centerLegends
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: <Widget>[
            // Only the rows give way. The trigger keeps its full width, because
            // a clipped trigger is an unreachable menu: at 148px with one 133px
            // row the button landed outside the clip and stopped hit-testing.
            // Flexible is safe here only because `overflowing` implies the line
            // is bounded — a `Flexible` under unbounded width is an error.
            if (overflowing) Flexible(child: strip) else strip,
            if (overflowing)
              // The overflow trigger is deliberately a SIBLING of the listbox
              // (Legends.tsx:116-120) so a menu button is never a listbox
              // child.
              FluentMenu(
                // MenuList carries the same 'Legends' name as the listbox
                // (OverflowMenu.tsx:64).
                semanticLabel: 'Legends',
                items: <FluentMenuItem>[
                  for (var index = visible; index < rows.length; index++)
                    FluentMenuItem(
                      // The checkmark stands in for upstream's aria-checked
                      // row; see the note at the top of this file.
                      checked: _selected.contains(widget.legends[index].title),
                      label: Text(
                        capitalizeLegendLabel(widget.legends[index].title),
                      ),
                      onPressed: () => _handlePressed(index),
                    ),
                ],
                builder: (context, toggle) => FluentButton(
                  onPressed: toggle,
                  child: Text(_triggerLabel(rows.length - visible)),
                ),
              ),
          ],
        );
      },
    );
  }

  /// `+{n} {overflowText}` — `OverflowMenu.tsx:16`.
  String _triggerLabel(int count) => '+$count ${widget.overflowText}';

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
      child: Focus(
        canRequestFocus: false,
        // useFocusableGroup() at Legends.tsx:51 is called with no options, so
        // no tabBehavior is specified; @fluentui/react-tabster is not in the
        // extracted source and its concrete bindings are UNKNOWN from that
        // tree. Left, Right, Home and End are what the configuration states.
        // ponytail: no typeahead, no Escape-to-exit. Probe that settles it —
        // drive `charts-legends--legends-basic` under Oracle B and record the
        // focus order for each key.
        onKeyEvent: _handleKey,
        child: Semantics(
          container: true,
          explicitChildNodes: true,
          // Legends.tsx:124 — the listbox is labelled 'Legends', and only when
          // allowFocusOnLegends is set does the role appear at all (:122).
          label: widget.allowFocusOnLegends ? 'Legends' : null,
          // Legends.tsx:109 — the two layouts are mutually exclusive.
          child: widget.enabledWrapLines
              ? _buildWrapped(rows)
              : _buildOverflow(rows, style, theme),
        ),
      ),
    );
  }
}
