import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../buttons/button.dart';
import '../buttons/button_style.dart';
import '../inputs/checkbox.dart';
import '../inputs/checkbox_style.dart';
import '../inputs/radio.dart';
import '../inputs/radio_style.dart';
import '../internal/focus_ring.dart';
import '../internal/interaction.dart';
import '../l10n/l10n.dart';
import 'data_grid_style.dart';

/// Row height and type ramp. Figma's four `DataGrid cell - *` component sets.
///
/// The four sets are separate components rather than one `Size` axis, which is
/// why [FluentDataGridSize.large] has a `Two line text` layout the others do
/// not and why `smaller` drops to the caption ramp while the other three stay
/// on body.
enum FluentDataGridSize {
  /// 24 high, caption type. Figma `DataGrid cell - Smaller`.
  smaller,

  /// 33 high, body type. Figma `DataGrid cell - Small`.
  small,

  /// 45 high, body type. The default. Figma `DataGrid cell - Medium`.
  medium,

  /// 59 high, body type, and the only size that draws a second line. Figma
  /// `DataGrid cell - Large`.
  large,
}

/// Which selection affordance the grid puts in its first column.
///
/// Named for Figma's `Layout` values on the cell sets — `Multi-select` draws a
/// checkbox, `Single select` a radio.
enum FluentDataGridSelectionMode {
  /// No selection column at all. The default.
  none,

  /// One row at a time, marked with a `FluentRadio`.
  single,

  /// Any number of rows, marked with a `FluentCheckbox`, and a select-all
  /// checkbox in the header.
  multiple,
}

/// Which way a sorted column is ordered.
enum FluentDataGridSortDirection {
  /// Smallest first. Draws `arrow_up_20_regular`.
  ascending,

  /// Largest first. Draws `arrow_down_20_regular`.
  descending,
}

/// How a selected row is filled.
///
/// The `DataGrid row` variable collection has six modes, which are these two
/// appearances crossed with rest and hover.
enum FluentDataGridSelectionAppearance {
  /// `Neutral/Background/Subtle/Selected`. Figma's `Selected` mode, and the
  /// default.
  neutral,

  /// `Brand/Background/2/Rest`. Figma's `Brand selected` mode.
  brand,
}

/// Header label weight. Figma's `Style` axis on `.Content header`.
enum FluentDataGridHeaderWeight {
  /// `body1`. Figma `Style=Regular`.
  regular,

  /// `body1Strong`. Figma `Style=Semibold`. The default.
  semibold,
}

/// Which of a cell's two type ramps its primary line takes. Figma's `Style`
/// axis on the four cell sets.
enum FluentDataGridCellEmphasis {
  /// `Primary text` — `Neutral/Foreground/1/*` on the body ramp. The default.
  primary,

  /// `Secondary text` — `Neutral/Foreground/2/*` on the caption ramp.
  secondary,

  /// No ramp at all: the cell's content is left exactly as passed.
  ///
  /// Figma's `Style=None`, which every `Single select`, `Multi-select` and
  /// `Cell actions` variant pins — those cells hold controls, not prose.
  none,
}

/// One column: its header, its width, and whether it can be sorted.
@immutable
class FluentDataGridColumn {
  /// Creates a column.
  const FluentDataGridColumn({
    required this.header,
    this.width,
    this.sortable = false,
  });

  /// The header label. Any widget; a `Text` in the ordinary case.
  final Widget header;

  /// A fixed width in logical pixels, or null to take an equal share of what
  /// the fixed columns leave.
  ///
  /// ponytail: there is no `flex` here because nothing in the Figma sets or in
  /// `useTableStyles.styles.ts` weights one column against another — every
  /// column is `flex: 1 1 0px`. Add one when a caller needs unequal shares that
  /// explicit widths cannot express.
  final double? width;

  /// Whether the header is an interactive sort control.
  final bool sortable;
}

/// One body row: its cells, whether it is selected, and what tapping it does.
///
/// A plain data class rather than a widget — the grid has to wrap every row in
/// its own interaction and focus machinery, so it needs the parts, not a
/// finished subtree.
@immutable
class FluentDataGridRow {
  /// Creates a row over [cells], one per column.
  const FluentDataGridRow({
    required this.cells,
    this.selected = false,
    this.onPressed,
    this.semanticLabel,
  });

  /// One widget per column, in column order. Normally
  /// [FluentDataGridCell]s.
  final List<Widget> cells;

  /// Whether the row paints the selected ramp.
  final bool selected;

  /// Invoked when the row is activated. Null leaves the row inert unless the
  /// grid is selectable, in which case the grid supplies its own handler.
  final VoidCallback? onPressed;

  /// Announced by assistive technology as the name of the row.
  final String? semanticLabel;
}

/// One row, already wrapped for interaction and focus by [FluentDataGrid].
///
/// The counterpart of `FluentToolbarBaseState.items`: [buildFluentDataGrid]
/// lays these out and paints their surfaces but does not build them, because
/// the focus nodes that make arrow navigation work have to outlive a build.
@immutable
class FluentDataGridRenderRow {
  /// Creates a render row.
  const FluentDataGridRenderRow({
    required this.cells,
    required this.selected,
    this.onPressed,
    this.semanticLabel,
  });

  /// The row's cells, one per rendered column — the selection column included
  /// when there is one.
  final List<Widget> cells;

  /// Whether the row resolves [WidgetState.selected].
  final bool selected;

  /// Invoked on tap. Null makes the row inert: no hover ramp, no cursor, no
  /// tap action in the semantics tree.
  final VoidCallback? onPressed;

  /// Announced by assistive technology.
  final String? semanticLabel;
}

/// Everything needed to render a data grid, independent of size.
///
/// The counterpart of `FluentButtonBaseState`. [buildFluentDataGrid] takes this
/// rather than [FluentDataGridState], which is what makes "Fluent's state, my
/// own styling, Fluent's rendering" a supported path rather than a fork.
@immutable
class FluentDataGridBaseState {
  /// Creates a base state.
  const FluentDataGridBaseState({
    required this.columnWidths,
    required this.rows,
    required this.enabled,
    this.headerCells,
    this.selectionColumnWidth,
  });

  /// One entry per data column: a fixed width, or null to take an equal share
  /// of what the fixed columns leave.
  final List<double?> columnWidths;

  /// The header row's cells, or null when the grid draws no header.
  ///
  /// Includes the leading selection cell when the grid is selectable, so its
  /// length matches every row's.
  final List<Widget>? headerCells;

  /// The body rows, already wrapped.
  final List<FluentDataGridRenderRow> rows;

  /// Whether the grid responds to input at all.
  final bool enabled;

  /// Fixed width of the leading selection column, or null when there is none.
  final double? selectionColumnWidth;
}

/// A data grid's fully resolved state, including the design axis.
@immutable
class FluentDataGridState extends FluentDataGridBaseState {
  /// Creates a resolved state.
  const FluentDataGridState({
    required super.columnWidths,
    required super.rows,
    required super.enabled,
    required this.size,
    required this.selectionAppearance,
    required this.headerWeight,
    super.headerCells,
    super.selectionColumnWidth,
  });

  /// Row height and type ramp.
  final FluentDataGridSize size;

  /// How a selected row is filled.
  final FluentDataGridSelectionAppearance selectionAppearance;

  /// Header label weight.
  final FluentDataGridHeaderWeight headerWeight;
}

/// Builds the state a data grid will be styled and rendered from.
///
/// The first of the three-function recomposition contract.
FluentDataGridState resolveFluentDataGridState({
  required List<double?> columnWidths,
  required List<FluentDataGridRenderRow> rows,
  bool enabled = true,
  FluentDataGridSize size = FluentDataGridSize.medium,
  FluentDataGridSelectionAppearance selectionAppearance =
      FluentDataGridSelectionAppearance.neutral,
  FluentDataGridHeaderWeight headerWeight = FluentDataGridHeaderWeight.semibold,
  List<Widget>? headerCells,
  double? selectionColumnWidth,
}) => FluentDataGridState(
  columnWidths: columnWidths,
  rows: rows,
  enabled: enabled,
  size: size,
  selectionAppearance: selectionAppearance,
  headerWeight: headerWeight,
  headerCells: headerCells,
  selectionColumnWidth: selectionColumnWidth,
);

/// Selects a token for a body row, where **selected outranks hovered**.
///
/// `FluentStateColor.tokens` resolves hovered before selected, which is right
/// almost everywhere and wrong here: Figma's `DataGrid row` collection has a
/// distinct `Selected-hover` mode, and for the brand appearance it names a
/// *different* token from the plain `Hover` mode. Resolving hover first would
/// paint a hovered brand-selected row the neutral subtle hover.
///
/// Nothing is computed — every branch returns a token that was read off the
/// collection.
WidgetStateProperty<Color> _rowToken({
  required Color rest,
  required Color hover,
  required Color selected,
  required Color selectedHover,
  required Color disabled,
}) => WidgetStateProperty.resolveWith((states) {
  if (states.contains(WidgetState.disabled)) return disabled;
  if (states.contains(WidgetState.selected)) {
    return states.contains(WidgetState.hovered) ? selectedHover : selected;
  }
  if (states.contains(WidgetState.hovered)) return hover;
  return rest;
});

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axis. Every value comes from a Fluent token; nothing
/// here computes a colour.
///
/// Token sources are the four Figma `DataGrid cell - *` sets and the
/// `.Content header` set (page `8995:3`), extracted into
/// `test/fixtures/data_grid_cell_*.json` and `test/fixtures/data_grid_header.json`,
/// plus two component-scoped variable collections that carry the whole state
/// table:
///
/// | `DataGrid row` mode | background | divider | primary | secondary |
/// |---|---|---|---|---|
/// | Rest | `subtleBackground` | `neutralStroke2` | `neutralForeground1` | `neutralForeground2` |
/// | Hover | `subtleBackgroundHover` | `neutralStroke2` | `neutralForeground1Hover` | `neutralForeground2Hover` |
/// | Selected | `subtleBackgroundSelected` | `neutralStrokeOnBrand2` | `neutralForeground1Selected` | `neutralForeground2Selected` |
/// | Selected-hover | `subtleBackgroundHover` | `neutralStrokeOnBrand2` | `neutralForeground1Hover` | `neutralForeground2Hover` |
/// | Brand selected | `brandBackground2` | `neutralStrokeOnBrand2` | `neutralForeground1Selected` | `neutralForeground2Selected` |
/// | Brand selected hover | `brandBackground2Hover` | `neutralStrokeOnBrand2` | `neutralForeground1Hover` | `neutralForeground2Hover` |
///
/// `DataGrid header row` is the second collection and is a different shape
/// again — Rest, Hover and **Pressed**, with no selected mode at all.
///
/// Disabled has no Figma mode on either collection. It selects
/// `neutralForegroundDisabled` for both text ramps and holds the resting
/// surface, matching every other component in this port.
FluentDataGridStyle resolveFluentDataGridStyle(
  FluentDataGridState state,
  FluentThemeData theme,
) {
  final c = theme.colors;
  final t = theme.typography;

  final (selected, selectedHover) = switch (state.selectionAppearance) {
    FluentDataGridSelectionAppearance.neutral => (
      c.subtleBackgroundSelected,
      c.subtleBackgroundHover,
    ),
    FluentDataGridSelectionAppearance.brand => (
      c.brandBackground2,
      c.brandBackground2Hover,
    ),
  };

  // The one place Figma is not followed, and it is a high-contrast bug rather
  // than a taste call. `Neutral/Foreground/1/Selected` and `.../Hover` are the
  // **HighlightText** tokens in high contrast — black — and they are legible
  // only on a Highlight surface. `Neutral/Background/Subtle/Selected` IS
  // Highlight (`#1AEBFF`), so the neutral appearance keeps Figma's ramp intact.
  // `Brand/Background/2/Rest` is **Canvas** (`#000000`), so the same pair would
  // paint black on black and a brand-selected row would lose its text with the
  // rule and the layout both still perfectly correct. The brand appearance
  // therefore holds the Rest foreground through its two selected modes, which
  // is `#242424` on `#EBF3FC` in light and `#FFFFFF` on `#000000` in high
  // contrast. `data_grid_test.dart` asserts that no foreground in either
  // appearance ever resolves to the surface it paints on.
  final brandSelected =
      state.selectionAppearance == FluentDataGridSelectionAppearance.brand;

  // Height, type ramp, leading icon size and the selection column's inset.
  // Read straight off the four cell sets; the vertical halves of the selection
  // inset sum exactly to the row height at every size.
  final (
    height,
    primaryStyle,
    iconSize,
    selectionPadding,
  ) = switch (state.size) {
    FluentDataGridSize.smaller => (
      24.0,
      t.caption1,
      FluentSize.size160,
      const EdgeInsetsDirectional.fromSTEB(
        FluentSpacing.l,
        FluentSpacing.xs,
        FluentSpacing.s,
        FluentSpacing.xs,
      ),
    ),
    FluentDataGridSize.small => (
      33.0,
      t.body1,
      FluentSize.size160,
      const EdgeInsetsDirectional.fromSTEB(
        FluentSpacing.l,
        8,
        FluentSpacing.s,
        9,
      ),
    ),
    FluentDataGridSize.medium => (
      45.0,
      t.body1,
      FluentSize.size200,
      const EdgeInsetsDirectional.fromSTEB(
        FluentSpacing.l,
        14,
        FluentSpacing.s,
        15,
      ),
    ),
    FluentDataGridSize.large => (
      59.0,
      t.body1,
      FluentSize.size200,
      const EdgeInsetsDirectional.fromSTEB(
        FluentSpacing.l,
        21,
        FluentSpacing.s,
        22,
      ),
    ),
  };

  return FluentDataGridStyle(
    backgroundColor: _rowToken(
      rest: c.subtleBackground,
      hover: c.subtleBackgroundHover,
      selected: selected,
      selectedHover: selectedHover,
      // No Figma mode; the resting surface is held rather than dimmed, because
      // dimming a transparent token produces nothing at all.
      disabled: c.subtleBackground,
    ),
    headerBackgroundColor: FluentStateColor.tokens(
      rest: c.subtleBackground,
      hover: c.subtleBackgroundHover,
      pressed: c.subtleBackgroundPressed,
      disabled: c.subtleBackground,
    ),
    dividerColor: _rowToken(
      rest: c.neutralStroke2,
      hover: c.neutralStroke2,
      selected: c.neutralStrokeOnBrand2,
      selectedHover: c.neutralStrokeOnBrand2,
      disabled: c.neutralStroke2,
    ),
    dividerWidth: const WidgetStatePropertyAll<double?>(FluentStroke.thin),
    primaryForegroundColor: _rowToken(
      rest: c.neutralForeground1,
      hover: c.neutralForeground1Hover,
      selected: brandSelected
          ? c.neutralForeground1
          : c.neutralForeground1Selected,
      selectedHover: brandSelected
          ? c.neutralForeground1
          : c.neutralForeground1Hover,
      disabled: c.neutralForegroundDisabled,
    ),
    secondaryForegroundColor: _rowToken(
      rest: c.neutralForeground2,
      hover: c.neutralForeground2Hover,
      selected: brandSelected
          ? c.neutralForeground2
          : c.neutralForeground2Selected,
      selectedHover: brandSelected
          ? c.neutralForeground2
          : c.neutralForeground2Hover,
      disabled: c.neutralForegroundDisabled,
    ),
    headerForegroundColor: FluentStateColor.tokens(
      rest: c.neutralForeground1,
      hover: c.neutralForeground1Hover,
      pressed: c.neutralForeground1Pressed,
      disabled: c.neutralForegroundDisabled,
    ),
    primaryTextStyle: WidgetStatePropertyAll<TextStyle?>(primaryStyle),
    // `Secondary text` is 12/16 at every one of the four sizes, including
    // Smaller, where it therefore matches the primary ramp exactly.
    secondaryTextStyle: WidgetStatePropertyAll<TextStyle?>(t.caption1),
    headerTextStyle: WidgetStatePropertyAll<TextStyle?>(
      switch (state.headerWeight) {
        FluentDataGridHeaderWeight.regular => t.body1,
        FluentDataGridHeaderWeight.semibold => t.body1Strong,
      },
    ),
    cellPadding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsetsDirectional.only(start: FluentSpacing.s, end: FluentSpacing.l),
    ),
    selectionCellPadding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      selectionPadding,
    ),
    headerPadding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.symmetric(horizontal: FluentSpacing.s),
    ),
    gap: const WidgetStatePropertyAll<double?>(FluentSpacing.s),
    headerGap: const WidgetStatePropertyAll<double?>(FluentSpacing.xxs),
    rowHeight: WidgetStatePropertyAll<double?>(height),
    iconSize: WidgetStatePropertyAll<double?>(iconSize),
    // Figma squares the sort button off at 2 on all four sides around a 20
    // glyph; `resolveFluentButtonStyle` would draw the small size's horizontal
    // ramp and come out 36 wide. See doc/token-divergences.md.
    sortButtonPadding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.all(FluentSpacing.xxs),
    ),
    mouseCursor: const WidgetStatePropertyAll<MouseCursor?>(
      SystemMouseCursors.click,
    ),
  );
}

/// Renders a data grid from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentDataGridBaseState] rather than [FluentDataGridState] on purpose: it
/// never reads the size, the selection appearance or the header weight, so a
/// consumer can supply their own style and still use Fluent's layout, row
/// surfaces and hover handling.
///
/// ## Motion: none, and that is the spec
///
/// `useTableRowStyles.styles.ts`, `useTableCellStyles.styles.ts` and
/// `useTableHeaderCellStyles.styles.ts` on `microsoft/fluentui@master` declare
/// **no transition, no animation and no `motionTokens` reference at all**. A
/// row's fill changes on the frame the pointer arrives, so this uses no
/// `FluentAnimatedStyle` and there is nothing for
/// `MediaQuery.disableAnimationsOf` to shorten — the grid is already correct
/// under reduced motion because it never moves. This is the
/// Checkbox/Tooltip/Toolbar category, not an omission.
///
/// [states] is the grid's own state set and is normally empty; it is honoured
/// so a caller passing a state-dependent style gets what they asked for. Each
/// row resolves its own set on top of it.
Widget buildFluentDataGrid(
  FluentDataGridBaseState state,
  FluentDataGridStyle style,
  Set<WidgetState> states,
) {
  final headerCells = state.headerCells;

  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      if (headerCells != null)
        _surface(
          state,
          style,
          <WidgetState>{...states, if (!state.enabled) WidgetState.disabled},
          headerCells,
          header: true,
        ),
      for (final row in state.rows)
        _InteractiveRow(state: state, style: style, grid: states, row: row),
    ],
  );
}

/// One row's painted surface: the fill, the rule beneath it, and the cells laid
/// out across the column widths.
Widget _surface(
  FluentDataGridBaseState state,
  FluentDataGridStyle style,
  Set<WidgetState> states,
  List<Widget> cells, {
  required bool header,
}) {
  final height = style.rowHeight?.resolve(states) ?? 0;
  final dividerWidth = style.dividerWidth?.resolve(states) ?? FluentStroke.none;
  final dividerColor = style.dividerColor?.resolve(states);
  final background = header
      ? style.headerBackgroundColor?.resolve(states)
      : style.backgroundColor?.resolve(states);

  // The selection column, when there is one, is the extra leading cell.
  final selectionWidth = state.selectionColumnWidth;
  final offset = cells.length - state.columnWidths.length;

  return DecoratedBox(
    decoration: BoxDecoration(
      color: background,
      // Figma aligns the stroke INSIDE the cell frame, so the rule overlaps the
      // last pixel of the row rather than adding to it — which is exactly what
      // a painted `Border` on a `DecoratedBox` does, since it never insets
      // layout. That is why `rowHeight` is the Figma frame height unmodified.
      border: dividerWidth > 0 && dividerColor != null
          ? Border(
              bottom: BorderSide(color: dividerColor, width: dividerWidth),
            )
          : null,
    ),
    child: SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (var i = 0; i < cells.length; i++)
            if (i < offset)
              SizedBox(width: selectionWidth, child: cells[i])
            else if (state.columnWidths[i - offset] != null)
              SizedBox(width: state.columnWidths[i - offset], child: cells[i])
            else
              Expanded(child: cells[i]),
        ],
      ),
    ),
  );
}

/// A body row: hover and press from [FluentInteractive], the selected flag from
/// the row itself, and the surface from [_surface].
class _InteractiveRow extends StatefulWidget {
  const _InteractiveRow({
    required this.state,
    required this.style,
    required this.grid,
    required this.row,
  });

  final FluentDataGridBaseState state;
  final FluentDataGridStyle style;
  final Set<WidgetState> grid;
  final FluentDataGridRenderRow row;

  @override
  State<_InteractiveRow> createState() => _InteractiveRowState();
}

class _InteractiveRowState extends State<_InteractiveRow> {
  /// The row reports hover and press but is never a focus stop: the grid's
  /// arrow navigation roves over CELLS, and a focusable row would put a second
  /// stop in front of every one of them.
  final FocusNode _node = FocusNode(
    canRequestFocus: false,
    skipTraversal: true,
    debugLabel: 'FluentDataGrid row (never focused)',
  );

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final style = widget.style;
    final row = widget.row;
    final enabled = state.enabled && row.onPressed != null;

    Widget paint(Set<WidgetState> live) {
      final resolved = <WidgetState>{
        ...widget.grid,
        ...live,
        if (row.selected) WidgetState.selected,
        if (!state.enabled) WidgetState.disabled,
      };
      return _FluentDataGridRowScope(
        states: resolved,
        style: style,
        child: _surface(state, style, resolved, row.cells, header: false),
      );
    }

    // Inert rows get no interaction surface at all, matching upstream: the
    // hover ramp lives in `rootInteractive`, which a non-interactive
    // `TableRow` never gets.
    final surface = enabled
        ? FluentInteractive(
            onPressed: row.onPressed,
            focusNode: _node,
            mouseCursor:
                style.mouseCursor?.resolve(const <WidgetState>{}) ??
                SystemMouseCursors.click,
            builder: (context, live, _) => paint(live),
          )
        : paint(const <WidgetState>{});

    return Semantics(
      container: true,
      selected: row.selected,
      label: row.semanticLabel,
      child: surface,
    );
  }
}

/// Carries the owning row's live state set and the resolved grid style down to
/// [FluentDataGridCell], so a cell can be written as
/// `FluentDataGridCell(child: Text('...'))` with no plumbing.
class _FluentDataGridRowScope extends InheritedWidget {
  const _FluentDataGridRowScope({
    required this.states,
    required this.style,
    required super.child,
  });

  final Set<WidgetState> states;
  final FluentDataGridStyle style;

  static _FluentDataGridRowScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_FluentDataGridRowScope>();

  @override
  bool updateShouldNotify(_FluentDataGridRowScope oldWidget) =>
      !setEquals<WidgetState>(states, oldWidget.states) ||
      style != oldWidget.style;
}

/// Overrides the data grid style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`. [FluentDataGridCell] reads it too, so restyling a
/// subtree restyles a cell that was built outside a grid.
class FluentDataGridTheme extends InheritedTheme {
  /// Applies [style] to every `FluentDataGrid` in [child].
  const FluentDataGridTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the size defaults.
  final FluentDataGridStyle style;

  /// The nearest data grid style, or null.
  static FluentDataGridStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentDataGridTheme>()?.style;

  @override
  bool updateShouldNotify(FluentDataGridTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentDataGridTheme(style: style, child: child);
}

/// One body cell.
///
/// Covers every `Layout` on the four Figma cell sets except the two selection
/// layouts, which [FluentDataGrid] builds itself because their inset differs:
///
/// * `Text` — [child] alone.
/// * `Two line text` — [child] over [secondary]. Figma draws it only at
///   [FluentDataGridSize.large]; nothing here forbids it at another size.
/// * `Link` — [child] is a `FluentLink`.
/// * `Cell actions` — [child] is a `Row` of `FluentButton.icon`s.
/// * `Swappable` — [child] is whatever you like. Figma's placeholder for this
///   layout is a brand-tinted rectangle reading "SWAP WITH CONTENT COMPONENT";
///   its 10/14 type is the *placeholder's*, not a cell ramp, and is not ported.
///
/// [leading] is the avatar, product icon or glyph slot the `Text` variants
/// draw. Icons in it are sized through [IconTheme] — 16 at
/// [FluentDataGridSize.smaller] and `small`, 20 at `medium` and `large`. An
/// avatar sizes itself; Figma's ramp is 20 / 24 / 32 / 32.
///
/// Placed inside a [FluentDataGrid] the cell picks up the owning row's live
/// state set, so its text follows the hover and selected ramps with no
/// plumbing. Outside one it resolves the resting tokens at
/// [FluentDataGridSize.medium].
class FluentDataGridCell extends StatelessWidget {
  /// Creates a cell.
  const FluentDataGridCell({
    super.key,
    this.child,
    this.secondary,
    this.leading,
    this.emphasis = FluentDataGridCellEmphasis.primary,
    this.size = FluentDataGridSize.medium,
    this.style,
  });

  /// The primary line, or the cell's whole content for the control layouts.
  final Widget? child;

  /// The second line. Figma's `Two line text` layout.
  final Widget? secondary;

  /// The avatar, product icon or glyph before the content.
  final Widget? leading;

  /// Which type ramp and colour [child] takes.
  final FluentDataGridCellEmphasis emphasis;

  /// Row height and type ramp. Ignored inside a [FluentDataGrid], which
  /// resolves the style once for the whole grid.
  final FluentDataGridSize size;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentDataGridStyle? style;

  @override
  Widget build(BuildContext context) {
    final scope = _FluentDataGridRowScope.maybeOf(context);
    final states = scope?.states ?? const <WidgetState>{};
    final resolved =
        (scope?.style ??
                resolveFluentDataGridStyle(
                  resolveFluentDataGridState(
                    columnWidths: const <double?>[],
                    rows: const <FluentDataGridRenderRow>[],
                    size: size,
                  ),
                  FluentTheme.of(context),
                ).merge(FluentDataGridTheme.maybeOf(context)))
            .merge(style);

    final padding = resolved.cellPadding?.resolve(states) ?? EdgeInsets.zero;
    final gap = resolved.gap?.resolve(states) ?? FluentSpacing.s;
    final iconSize = resolved.iconSize?.resolve(states) ?? FluentSize.size200;

    final (textStyle, foreground) = switch (emphasis) {
      FluentDataGridCellEmphasis.primary => (
        resolved.primaryTextStyle?.resolve(states),
        resolved.primaryForegroundColor?.resolve(states),
      ),
      FluentDataGridCellEmphasis.secondary => (
        resolved.secondaryTextStyle?.resolve(states),
        resolved.secondaryForegroundColor?.resolve(states),
      ),
      FluentDataGridCellEmphasis.none => (null, null),
    };

    var primary = child;
    if (primary != null && (textStyle != null || foreground != null)) {
      primary = DefaultTextStyle.merge(
        style: (textStyle ?? const TextStyle()).copyWith(color: foreground),
        child: primary,
      );
    }

    final second = secondary;
    final content = second == null
        ? primary
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ?primary,
              DefaultTextStyle.merge(
                style:
                    (resolved.secondaryTextStyle?.resolve(states) ??
                            const TextStyle())
                        .copyWith(
                          color: resolved.secondaryForegroundColor?.resolve(
                            states,
                          ),
                        ),
                child: second,
              ),
            ],
          );

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        // Figma insets the content frame asymmetrically — 5 above and 8 below a
        // 20px line in a 33 row, so the glyphs sit 1.5 above centre. That is a
        // compensation for Figma's text-box metrics, the same one
        // `FluentAccordion` declines to port from its `Text-offset` wrapper:
        // Flutter's line box, with an explicit `TextStyle.height`, already
        // centres the way the browser does. The content is centred.
        spacing: leading == null ? 0 : gap,
        children: <Widget>[
          if (leading != null)
            IconTheme.merge(
              data: IconThemeData(size: iconSize, color: foreground),
              child: leading!,
            ),
          if (content != null) Flexible(child: content),
        ],
      ),
    );
  }
}

/// Moves the roving cell focus by a number of rows and columns.
///
/// Public so an app can rebind the grid keys — or bind more of them — without
/// forking [FluentDataGrid].
class FluentDataGridMoveIntent extends Intent {
  /// Creates an intent to move the roving cell focus.
  const FluentDataGridMoveIntent({this.rows = 0, this.columns = 0, this.end});

  /// How many rows to move. Negative walks towards the header.
  final int rows;

  /// How many columns to move. Negative walks towards the leading edge. In an
  /// RTL subtree the horizontal arrows are swapped before this is dispatched.
  final int columns;

  /// When set, jump to the first (`false`) or last (`true`) stop on the axis
  /// named by whichever of [rows] and [columns] is non-zero, ignoring its
  /// magnitude. This is Home and End.
  final bool? end;
}

/// A Fluent 2 data grid: a header row over body rows, with sorting, row
/// selection and arrow-key navigation.
///
/// ```dart
/// FluentDataGrid(
///   selectionMode: FluentDataGridSelectionMode.multiple,
///   sortColumn: 0,
///   sortDirection: FluentDataGridSortDirection.ascending,
///   onSort: (column) => setState(() => _sort = column),
///   onSelectionChanged: (selected) => setState(() => _selected = selected),
///   selectedRows: _selected,
///   columns: const <FluentDataGridColumn>[
///     FluentDataGridColumn(header: Text('File'), sortable: true),
///     FluentDataGridColumn(header: Text('Author'), width: 160),
///   ],
///   rows: const <FluentDataGridRow>[
///     FluentDataGridRow(
///       cells: <Widget>[
///         FluentDataGridCell(child: Text('Report.docx')),
///         FluentDataGridCell(
///           child: Text('Ada'),
///           emphasis: FluentDataGridCellEmphasis.secondary,
///         ),
///       ],
///     ),
///   ],
/// )
/// ```
///
/// ## Keyboard: one tab stop, arrows inside
///
/// The whole grid is a single stop in the Tab order. Arrow keys move a roving
/// focus between **cells**; Home and End jump to the first and last cell of the
/// row; Control-Home and Control-End to the first and last cell of the grid.
/// Neither axis wraps — a grid is a plane, and wrapping from the end of one row
/// to the start of the next reads as a jump.
///
/// A cell's stop is its own focusable descendant when it has one — the
/// selection checkbox, a link, a sortable header — so those controls keep their
/// own focus ring and their own Space and Enter handling. A cell with nothing
/// focusable in it takes focus itself and draws the ring around the cell, so
/// navigation never dead-ends in a column of plain text.
///
/// Tab moves *out* of the grid. While a cell holds the roving index its own
/// descendants are traversable, so a `Cell actions` cell holding three buttons
/// exposes all three to Tab before the grid is left. That is the same roving
/// tabindex `FluentToolbar` implements.
///
/// Escape is deliberately **not** handled: a grid has nothing to dismiss, so
/// the key travels on to whatever dialog or drawer contains it.
///
/// ## Selection
///
/// [selectionMode] adds a leading column: a `FluentCheckbox` per row plus a
/// tri-state select-all in the header for
/// [FluentDataGridSelectionMode.multiple], a `FluentRadio` for
/// [FluentDataGridSelectionMode.single]. Both are the real components with
/// their indicator margin zeroed, because Figma's selection cell is the bare
/// 16px indicator inside the cell's own 16 / 8 inset — the sum is the 40-wide
/// column Figma draws.
///
/// Selection is controlled: [selectedRows] is the truth and
/// [onSelectionChanged] reports the next value. A selectable row is also
/// activatable by tap, so clicking anywhere in the row toggles it.
///
/// ## Motion
///
/// None. See [buildFluentDataGrid].
///
/// ## Not implemented
///
/// Stated plainly rather than half-built, because none of it appears in the
/// Figma sets:
///
/// * **Virtualisation.** Every row is built. Upstream ships this as a separate
///   `DataGridBody` render-prop over `react-window`; wrap the grid in a scroll
///   view and page your own data.
/// * **Column resizing.** No drag handle, no `columnSizingOptions`. Set
///   [FluentDataGridColumn.width] or let the flexes share the space.
/// * **Column drag-reorder.** No `DataGridHeaderCell` drag affordance exists in
///   the file.
/// * **Row hover quick-actions.** The `DataGrid row` collection has a
///   `Quick actions` boolean that reveals the trailing action buttons on hover
///   and selection. Put a `Cell actions` cell in the row and it is always
///   visible; the reveal is not modelled.
/// * **Sub-rows / grouping.** Neither is in the file.
///
/// Customisation follows the usual three rungs. [style] is merged last and
/// wins; [FluentDataGridTheme] restyles a subtree; and for anything further,
/// [resolveFluentDataGridState], [resolveFluentDataGridStyle] and
/// [buildFluentDataGrid] are public so any one of them can be replaced without
/// forking this widget.
class FluentDataGrid extends StatefulWidget {
  /// Creates a data grid over [columns] and [rows].
  const FluentDataGrid({
    super.key,
    required this.columns,
    required this.rows,
    this.size = FluentDataGridSize.medium,
    this.selectionMode = FluentDataGridSelectionMode.none,
    this.selectionAppearance = FluentDataGridSelectionAppearance.neutral,
    this.headerWeight = FluentDataGridHeaderWeight.semibold,
    this.selectedRows = const <int>{},
    this.onSelectionChanged,
    this.sortColumn,
    this.sortDirection,
    this.onSort,
    this.showHeader = true,
    this.enabled = true,
    this.style,
    this.semanticLabel,
    this.selectAllSemanticLabel,
    this.selectRowSemanticLabel,
  });

  /// The columns, in order.
  final List<FluentDataGridColumn> columns;

  /// The body rows, in order. Each holds one cell per column.
  final List<FluentDataGridRow> rows;

  /// Row height and type ramp.
  final FluentDataGridSize size;

  /// Which selection affordance the leading column holds, if any.
  final FluentDataGridSelectionMode selectionMode;

  /// How a selected row is filled.
  final FluentDataGridSelectionAppearance selectionAppearance;

  /// Header label weight.
  final FluentDataGridHeaderWeight headerWeight;

  /// Indices of the selected rows. Selection is controlled: this is the truth,
  /// and the grid never mutates it.
  ///
  /// For [FluentDataGridSelectionMode.single] only the lowest index is
  /// honoured, matching a radio group.
  final Set<int> selectedRows;

  /// Reports the next selection. Null leaves the selection column read-only.
  final ValueChanged<Set<int>>? onSelectionChanged;

  /// Index of the sorted column, or null when nothing is sorted.
  final int? sortColumn;

  /// Which way [sortColumn] is ordered. Null draws no arrow.
  final FluentDataGridSortDirection? sortDirection;

  /// Invoked with a column index when its sort control is activated. Null
  /// leaves every header inert, whatever [FluentDataGridColumn.sortable] says.
  final ValueChanged<int>? onSort;

  /// Whether the header row is drawn at all.
  final bool showHeader;

  /// Whether the grid responds to input.
  ///
  /// False is a real state, not a visual treatment: rows stop reporting hover
  /// and press, the selection controls refuse focus and never fire, and both
  /// text ramps swap to `neutralForegroundDisabled` wholesale.
  final bool enabled;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentDataGridStyle? style;

  /// Announced by assistive technology as the name of the grid.
  final String? semanticLabel;

  /// Announced for the header's select-all checkbox.
  ///
  /// Null takes the wording from the ambient [FluentLocalizations], which falls
  /// back to English when no delegate is installed. The same is true of
  /// [selectRowSemanticLabel].
  final String? selectAllSemanticLabel;

  /// Announced for a row's selection control. The row number is appended.
  final String? selectRowSemanticLabel;

  @override
  State<FluentDataGrid> createState() => _FluentDataGridState();
}

class _FluentDataGridState extends State<FluentDataGrid> {
  /// One handle per cell, `[row][column]`. Row 0 is the header when there is
  /// one. None of these takes focus itself: they exist so the grid can find a
  /// cell's own focusable descendant and gate its subtree out of Tab.
  final List<List<FocusNode>> _wrappers = <List<FocusNode>>[];

  /// The stop of last resort for a cell holding nothing focusable.
  final List<List<FocusNode>> _fallbacks = <List<FocusNode>>[];

  /// Whether cell `[r][c]` still needs its fallback stop.
  ///
  /// Starts true everywhere and is settled after the first frame, because "does
  /// this cell hold anything focusable" cannot be answered before the focus
  /// tree exists. Starting true rather than false is deliberate: a grid of
  /// plain text would otherwise have zero tab stops on its very first frame and
  /// be unreachable by keyboard.
  final List<List<bool>> _needsFallback = <List<bool>>[];

  int _row = 0;
  int _column = 0;

  bool get _hasHeader => widget.showHeader;

  int get _rowCount => widget.rows.length + (_hasHeader ? 1 : 0);

  int get _columnCount =>
      widget.columns.length +
      (widget.selectionMode == FluentDataGridSelectionMode.none ? 0 : 1);

  @override
  void initState() {
    super.initState();
    _syncNodes();
    WidgetsBinding.instance.addPostFrameCallback((_) => _settleFallbacks());
  }

  @override
  void didUpdateWidget(FluentDataGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncNodes();
    WidgetsBinding.instance.addPostFrameCallback((_) => _settleFallbacks());
  }

  @override
  void dispose() {
    for (final row in _wrappers) {
      for (final node in row) {
        node.dispose();
      }
    }
    for (final row in _fallbacks) {
      for (final node in row) {
        node.dispose();
      }
    }
    super.dispose();
  }

  void _syncNodes() {
    void resize(List<List<FocusNode>> grid, String label) {
      while (grid.length > _rowCount) {
        for (final node in grid.removeLast()) {
          node.dispose();
        }
      }
      while (grid.length < _rowCount) {
        grid.add(<FocusNode>[]);
      }
      for (var r = 0; r < grid.length; r++) {
        while (grid[r].length > _columnCount) {
          grid[r].removeLast().dispose();
        }
        while (grid[r].length < _columnCount) {
          grid[r].add(FocusNode(debugLabel: '$label $r,${grid[r].length}'));
        }
      }
    }

    resize(_wrappers, 'FluentDataGrid cell');
    resize(_fallbacks, 'FluentDataGrid cell fallback');
    while (_needsFallback.length > _rowCount) {
      _needsFallback.removeLast();
    }
    while (_needsFallback.length < _rowCount) {
      _needsFallback.add(<bool>[]);
    }
    for (final row in _needsFallback) {
      while (row.length > _columnCount) {
        row.removeLast();
      }
      while (row.length < _columnCount) {
        row.add(true);
      }
    }
    if (_row >= _rowCount) _row = 0;
    if (_column >= _columnCount) _column = 0;
  }

  /// Turns off the fallback stop for every cell that turned out to hold a
  /// focusable of its own, so a checkbox column has one stop per cell rather
  /// than two.
  void _settleFallbacks() {
    if (!mounted) return;
    var changed = false;
    for (var r = 0; r < _wrappers.length; r++) {
      for (var c = 0; c < _wrappers[r].length; c++) {
        final own = _wrappers[r][c].descendants.any(
          (node) => node.canRequestFocus && !identical(node, _fallbacks[r][c]),
        );
        if (_needsFallback[r][c] == !own) continue;
        _needsFallback[r][c] = !own;
        changed = true;
      }
    }
    if (changed) setState(() {});
  }

  /// The node arrow navigation should land on for cell `[r][c]`.
  ///
  /// The cell's own focusable descendant when it has one — so a checkbox, link
  /// or sort button keeps its ring and its key handling — and the fallback
  /// otherwise, so a column of plain text is still reachable.
  FocusNode? _stop(int r, int c) {
    if (r < 0 || r >= _wrappers.length) return null;
    if (c < 0 || c >= _wrappers[r].length) return null;
    final fallback = _fallbacks[r][c];
    for (final node in _wrappers[r][c].descendants) {
      if (!node.canRequestFocus) continue;
      if (identical(node, fallback)) continue;
      return node;
    }
    return fallback.canRequestFocus ? fallback : null;
  }

  void _moveTo(int r, int c) {
    final target = _stop(r, c);
    if (target == null) return;
    target.requestFocus();
    if (r != _row || c != _column) setState(() => (_row = r, _column = c));
  }

  void _handle(FluentDataGridMoveIntent intent) {
    final end = intent.end;
    if (end != null) {
      if (intent.columns != 0) {
        _moveTo(_row, end ? _columnCount - 1 : 0);
      } else {
        _moveTo(end ? _rowCount - 1 : 0, _column);
      }
      return;
    }
    _moveTo(
      (_row + intent.rows).clamp(0, _rowCount - 1),
      (_column + intent.columns).clamp(0, _columnCount - 1),
    );
  }

  void _handleFocusChange(int r, int c, {required bool hasFocus}) {
    if (hasFocus && (r != _row || c != _column) && mounted) {
      setState(() => (_row = r, _column = c));
    }
  }

  /// Wraps one cell in its roving handle and its fallback stop.
  Widget _wrap(int r, int c, Widget cell) => Focus(
    focusNode: _wrappers[r][c],
    // A handle, not a stop: never focusable itself, and it hides its subtree
    // from Tab unless it holds the roving index. One traversable subtree at a
    // time is what a roving tabindex *is*.
    canRequestFocus: false,
    skipTraversal: true,
    descendantsAreTraversable: r == _row && c == _column,
    onFocusChange: (value) => _handleFocusChange(r, c, hasFocus: value),
    child: Focus(
      focusNode: _fallbacks[r][c],
      // Live only for a cell that holds nothing focusable of its own. It is
      // then a real Tab stop as well as an arrow stop — but only one at a
      // time, because the handle above gates every inactive cell's subtree out
      // of the traversal.
      canRequestFocus: _needsFallback[r][c],
      skipTraversal: !_needsFallback[r][c],
      child: Builder(
        builder: (context) => FluentFocusRing(
          visible: _fallbacks[r][c].hasPrimaryFocus,
          borderRadius: BorderRadius.zero,
          child: cell,
        ),
      ),
    ),
  );

  void _toggleRow(int index, {required bool selected}) {
    final callback = widget.onSelectionChanged;
    if (callback == null) return;
    if (widget.selectionMode == FluentDataGridSelectionMode.single) {
      callback(selected ? <int>{index} : <int>{});
      return;
    }
    final next = Set<int>.of(widget.selectedRows);
    if (selected) {
      next.add(index);
    } else {
      next.remove(index);
    }
    callback(next);
  }

  /// Null when some but not all rows are selected — the checkbox's mixed value.
  bool? get _selectAllValue {
    if (widget.rows.isEmpty) return false;
    final count = widget.selectedRows
        .where((i) => i >= 0 && i < widget.rows.length)
        .length;
    if (count == 0) return false;
    if (count == widget.rows.length) return true;
    return null;
  }

  /// The bare 16px indicator: Figma's selection cell is the indicator alone
  /// inside the cell's own inset, so the component's own 8px margin and 32px
  /// floor are zeroed rather than a checkbox being redrawn here.
  static const FluentCheckboxStyle _bareCheckbox = FluentCheckboxStyle(
    indicatorMargin: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.zero,
    ),
    minimumSize: WidgetStatePropertyAll<Size?>(Size.zero),
  );

  static const FluentRadioStyle _bareRadio = FluentRadioStyle(
    indicatorPadding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.zero,
    ),
  );

  Widget _selectionCell(FluentDataGridStyle style, Widget control) => Padding(
    padding:
        style.selectionCellPadding?.resolve(const <WidgetState>{}) ??
        EdgeInsets.zero,
    child: Align(alignment: AlignmentDirectional.topStart, child: control),
  );

  Widget _headerCell(
    FluentDataGridStyle style,
    int index,
    FluentDataGridColumn column,
  ) {
    final states = <WidgetState>{if (!widget.enabled) WidgetState.disabled};
    final padding = style.headerPadding?.resolve(states) ?? EdgeInsets.zero;
    final gap = style.headerGap?.resolve(states) ?? FluentSpacing.xxs;
    final textStyle = style.headerTextStyle?.resolve(states);
    final foreground = style.headerForegroundColor?.resolve(states);
    final sortable = column.sortable && widget.onSort != null && widget.enabled;
    final direction = widget.sortColumn == index ? widget.sortDirection : null;

    return Semantics(
      header: true,
      child: Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: gap,
          children: <Widget>[
            Flexible(
              child: DefaultTextStyle.merge(
                style: (textStyle ?? const TextStyle()).copyWith(
                  color: foreground,
                ),
                child: column.header,
              ),
            ),
            if (sortable)
              FluentButton.icon(
                appearance: FluentButtonAppearance.transparent,
                size: FluentButtonSize.small,
                // Figma's own sort affordance is a Transparent / Small /
                // Icon-only Button instance holding a 20px arrow, squared off
                // at 2 rather than taking the button's horizontal ramp.
                style: FluentButtonStyle(
                  padding: style.sortButtonPadding,
                  minimumSize: const WidgetStatePropertyAll<Size?>(Size.zero),
                ),
                semanticLabel: switch (direction) {
                  null => fluentL10n(context).sort,
                  FluentDataGridSortDirection.ascending => fluentL10n(
                    context,
                  ).sortedAscending,
                  FluentDataGridSortDirection.descending => fluentL10n(
                    context,
                  ).sortedDescending,
                },
                icon: Icon(
                  direction == FluentDataGridSortDirection.descending
                      ? FluentIcons.arrow_down_20_regular
                      : FluentIcons.arrow_up_20_regular,
                  size: FluentSize.size200,
                ),
                onPressed: () => widget.onSort!(index),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectable = widget.selectionMode != FluentDataGridSelectionMode.none;
    final interactive = selectable && widget.onSelectionChanged != null;

    final state = resolveFluentDataGridState(
      columnWidths: <double?>[for (final c in widget.columns) c.width],
      rows: const <FluentDataGridRenderRow>[],
      enabled: widget.enabled,
      size: widget.size,
      selectionAppearance: widget.selectionAppearance,
      headerWeight: widget.headerWeight,
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final style = resolveFluentDataGridStyle(
      state,
      FluentTheme.of(context),
    ).merge(FluentDataGridTheme.maybeOf(context)).merge(widget.style);

    // Figma's selection column is 16 + 16 + 8 = 40 at every size.
    final selectionPadding =
        (style.selectionCellPadding?.resolve(const <WidgetState>{}) ??
                EdgeInsets.zero)
            .resolve(Directionality.of(context));
    final selectionWidth = selectable
        ? selectionPadding.horizontal + FluentSize.size160
        : null;

    List<Widget>? headerCells;
    if (_hasHeader) {
      headerCells = <Widget>[
        if (selectable)
          _wrap(
            0,
            0,
            _selectionCell(
              style,
              widget.selectionMode == FluentDataGridSelectionMode.multiple
                  ? FluentCheckbox(
                      checked: _selectAllValue,
                      style: _bareCheckbox,
                      semanticLabel:
                          widget.selectAllSemanticLabel ??
                          fluentL10n(context).selectAllRows,
                      onChanged: interactive
                          ? (value) => widget.onSelectionChanged!(
                              value ?? false
                                  ? <int>{
                                      for (
                                        var i = 0;
                                        i < widget.rows.length;
                                        i++
                                      )
                                        i,
                                    }
                                  : <int>{},
                            )
                          : null,
                    )
                  // Single select has no select-all: a radio group cannot
                  // express "all". Figma's `.Content header` `Layout=Selection`
                  // variant draws a checkbox and nothing else, so the slot is
                  // simply empty here.
                  : const SizedBox.shrink(),
            ),
          ),
        for (var i = 0; i < widget.columns.length; i++)
          _wrap(
            0,
            i + (selectable ? 1 : 0),
            _headerCell(style, i, widget.columns[i]),
          ),
      ];
    }

    final rowOffset = _hasHeader ? 1 : 0;
    final renderRows = <FluentDataGridRenderRow>[
      for (var r = 0; r < widget.rows.length; r++)
        FluentDataGridRenderRow(
          selected: widget.selectedRows.contains(r),
          semanticLabel: widget.rows[r].semanticLabel,
          onPressed:
              widget.rows[r].onPressed ??
              (interactive
                  ? () => _toggleRow(
                      r,
                      selected: !widget.selectedRows.contains(r),
                    )
                  : null),
          cells: <Widget>[
            if (selectable)
              _wrap(
                r + rowOffset,
                0,
                _selectionCell(style, switch (widget.selectionMode) {
                  FluentDataGridSelectionMode.multiple => FluentCheckbox(
                    checked: widget.selectedRows.contains(r),
                    style: _bareCheckbox,
                    semanticLabel:
                        '${widget.selectRowSemanticLabel ?? fluentL10n(context).selectRow} '
                        '${r + 1}',
                    onChanged: interactive
                        ? (value) => _toggleRow(r, selected: value ?? false)
                        : null,
                  ),
                  FluentDataGridSelectionMode.single => FluentRadio<int>(
                    value: r,
                    groupValue: widget.selectedRows.isEmpty
                        ? null
                        : widget.selectedRows.reduce((a, b) => a < b ? a : b),
                    style: _bareRadio,
                    semanticLabel:
                        '${widget.selectRowSemanticLabel ?? fluentL10n(context).selectRow} '
                        '${r + 1}',
                    onChanged: interactive
                        ? (value) => _toggleRow(value, selected: true)
                        : null,
                  ),
                  FluentDataGridSelectionMode.none => const SizedBox.shrink(),
                }),
              ),
            for (var c = 0; c < widget.rows[r].cells.length; c++)
              _wrap(
                r + rowOffset,
                c + (selectable ? 1 : 0),
                widget.rows[r].cells[c],
              ),
          ],
        ),
    ];

    final resolvedState = FluentDataGridState(
      columnWidths: state.columnWidths,
      rows: renderRows,
      enabled: widget.enabled,
      size: widget.size,
      selectionAppearance: widget.selectionAppearance,
      headerWeight: widget.headerWeight,
      headerCells: headerCells,
      selectionColumnWidth: selectionWidth,
    );

    // Arrow keys are physical; the column list is logical. In an RTL subtree
    // the two disagree, and it is the arrows that must bend.
    final rtl = Directionality.of(context) == TextDirection.rtl;

    return Semantics(
      container: true,
      label: widget.semanticLabel,
      child: Shortcuts(
        shortcuts: <ShortcutActivator, Intent>{
          const SingleActivator(LogicalKeyboardKey.arrowRight):
              FluentDataGridMoveIntent(columns: rtl ? -1 : 1),
          const SingleActivator(LogicalKeyboardKey.arrowLeft):
              FluentDataGridMoveIntent(columns: rtl ? 1 : -1),
          const SingleActivator(LogicalKeyboardKey.arrowDown):
              const FluentDataGridMoveIntent(rows: 1),
          const SingleActivator(LogicalKeyboardKey.arrowUp):
              const FluentDataGridMoveIntent(rows: -1),
          const SingleActivator(LogicalKeyboardKey.home):
              const FluentDataGridMoveIntent(columns: 1, end: false),
          const SingleActivator(LogicalKeyboardKey.end):
              const FluentDataGridMoveIntent(columns: 1, end: true),
          const SingleActivator(LogicalKeyboardKey.home, control: true):
              const FluentDataGridMoveIntent(rows: 1, end: false),
          const SingleActivator(LogicalKeyboardKey.end, control: true):
              const FluentDataGridMoveIntent(rows: 1, end: true),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            FluentDataGridMoveIntent: CallbackAction<FluentDataGridMoveIntent>(
              onInvoke: (intent) {
                _handle(intent);
                return null;
              },
            ),
          },
          child: buildFluentDataGrid(
            resolvedState,
            style,
            const <WidgetState>{},
          ),
        ),
      ),
    );
  }
}
