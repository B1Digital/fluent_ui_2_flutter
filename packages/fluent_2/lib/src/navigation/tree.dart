import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/semantics.dart' show SemanticsRole;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../inputs/checkbox.dart';
import '../inputs/radio.dart';
import '../internal/animated_style.dart';
import '../internal/focus_ring.dart';
import '../internal/interaction.dart';
import 'tree_style.dart';

/// How a tree row is filled. Figma's `Style` axis.
enum FluentTreeAppearance {
  /// `Neutral/Background/Subtle/*` — an opaque grey on hover and press. The
  /// default.
  subtle,

  /// `Neutral/Background/Subtle/Light alpha/*` — a translucent white, for a
  /// tree over an image or a coloured surface.
  subtleAlpha,

  /// `Neutral/Background/Transparent/*` — no fill in any state.
  transparent,
}

/// Row height and type ramp. Figma's `Size` axis.
enum FluentTreeSize {
  /// 24 high, `caption1` (12/16), 12px leading icon.
  small,

  /// 32 high, `body1` (14/20), 16px leading icon. The default.
  medium,
}

/// Whether rows carry a selection control, and how many may be chosen.
///
/// Mirrors upstream's `TreeProps['selectionMode']`, including which control is
/// rendered: `multiple` renders a [FluentCheckbox], `single` a [FluentRadio].
enum FluentTreeSelectionMode {
  /// No selection control. Rows may still be marked selected through
  /// `FluentTree.selectedItems`, which is what drives Figma's `Selected` state.
  /// The default.
  none,

  /// One row at a time, chosen with a [FluentRadio].
  single,

  /// Any number of rows, chosen with a [FluentCheckbox].
  multiple,
}

/// One node of a [FluentTree], and its subtree.
///
/// A plain data class rather than a widget: the ARIA-tree keyboard contract is
/// defined over the *flattened list of visible rows*, and deriving that list
/// from data is a fraction of the machinery it would take to discover it from
/// a widget subtree.
@immutable
class FluentTreeItem {
  /// Creates a node.
  const FluentTreeItem({
    required this.value,
    required this.label,
    this.icon,
    this.actions,
    this.searchLabel,
    this.children = const <FluentTreeItem>[],
    this.enabled = true,
  });

  /// Identity, used as the key in the open and selected sets. Compared with
  /// `==`, so it must be stable across rebuilds.
  final Object value;

  /// The row's label.
  final Widget label;

  /// Optional leading icon, drawn between the chevron and the label.
  final Widget? icon;

  /// Optional trailing controls. Figma's `Quick actions` slot, which holds a
  /// 24px subtle icon button — pass a `FluentButton.icon` to reproduce it.
  final Widget? actions;

  /// Plain text used for typeahead, since [label] is a widget and cannot be
  /// read. Null opts this row out of typeahead.
  final String? searchLabel;

  /// The subtree. Empty makes this a leaf, which draws no chevron and takes one
  /// extra indent step so its label lines up with its siblings'.
  final List<FluentTreeItem> children;

  /// Whether the row responds to input. Disabled is a real state: it swaps the
  /// whole colour ramp, refuses focus, and is skipped by the arrow keys.
  final bool enabled;

  /// Whether this node has a subtree.
  bool get isBranch => children.isNotEmpty;
}

/// Everything needed to render one tree row, independent of appearance and
/// size.
///
/// The Dart counterpart of upstream's `TreeItemLayoutState`.
/// [buildFluentTreeItem] takes this rather than [FluentTreeItemState], which is
/// what makes "Fluent's state, my own styling, Fluent's rendering" a supported
/// path rather than a fork.
@immutable
class FluentTreeItemBaseState {
  /// Creates a base state.
  const FluentTreeItemBaseState({
    required this.enabled,
    required this.level,
    required this.branch,
    required this.expanded,
    required this.selectionMode,
    required this.selected,
    this.icon,
    this.label,
    this.actions,
    this.onSelectionChanged,
  });

  /// Whether the row responds to input.
  final bool enabled;

  /// Depth in the tree, 1 for a root row. Both Figma's `Tree indentation`
  /// collection and upstream's `--fui-TreeItem--level` are 1-based.
  final int level;

  /// Whether this row has a subtree. Figma's `Leaf node` axis, inverted.
  final bool branch;

  /// Whether the subtree is open. Always false on a leaf.
  final bool expanded;

  /// Which selection control the row carries.
  final FluentTreeSelectionMode selectionMode;

  /// Whether the row is selected. Drives both the control and Figma's
  /// `Selected` state.
  final bool selected;

  /// Optional leading icon.
  final Widget? icon;

  /// The row's label.
  final Widget? label;

  /// Optional trailing controls.
  final Widget? actions;

  /// Invoked by the selection control with the next value. Null renders the
  /// control disabled.
  final ValueChanged<bool>? onSelectionChanged;

  /// The number of indent steps this row takes.
  ///
  /// A branch is indented by the levels above it; a leaf takes one step more,
  /// because it has no chevron to fill. Upstream writes exactly this as
  /// `calc(var(--level) * XXL)` for a leaf and `calc((var(--level) - 1) * XXL)`
  /// for a branch, and Figma's `tree-padding-left` / `treeleaf-padding-left`
  /// variables resolve to the same two ramps.
  int get indentSteps => branch ? level - 1 : level;
}

/// A tree row's fully resolved state, including the design axes.
///
/// The counterpart of upstream's `TreeItemLayoutState` plus the two axes the
/// `Tree` context supplies: `appearance` and `size`.
@immutable
class FluentTreeItemState extends FluentTreeItemBaseState {
  /// Creates a resolved state.
  const FluentTreeItemState({
    required super.enabled,
    required super.level,
    required super.branch,
    required super.expanded,
    required super.selectionMode,
    required super.selected,
    required this.appearance,
    required this.size,
    super.icon,
    super.label,
    super.actions,
    super.onSelectionChanged,
  });

  /// Fill treatment.
  final FluentTreeAppearance appearance;

  /// Row height and type ramp.
  final FluentTreeSize size;
}

/// Builds the state a tree row will be styled and rendered from.
///
/// Separated so a consumer can reuse Fluent's state resolution while
/// substituting their own styling — the first of the three-function
/// recomposition contract.
FluentTreeItemState resolveFluentTreeItemState({
  bool enabled = true,
  int level = 1,
  bool branch = false,
  bool expanded = false,
  bool selected = false,
  FluentTreeSelectionMode selectionMode = FluentTreeSelectionMode.none,
  FluentTreeAppearance appearance = FluentTreeAppearance.subtle,
  FluentTreeSize size = FluentTreeSize.medium,
  Widget? icon,
  Widget? label,
  Widget? actions,
  ValueChanged<bool>? onSelectionChanged,
}) => FluentTreeItemState(
  enabled: enabled,
  level: level,
  branch: branch,
  // A leaf can never be open, whatever the caller passed: there is nothing to
  // open, and a stale `true` would rotate a chevron that is not drawn.
  expanded: branch && expanded,
  selectionMode: selectionMode,
  selected: selected,
  appearance: appearance,
  size: size,
  icon: icon,
  label: label,
  actions: actions,
  onSelectionChanged: onSelectionChanged,
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes. Every colour is an explicitly named Fluent
/// token; nothing here computes one.
///
/// ## Where the numbers come from
///
/// The Figma `Tree item` set (page `8934:23`, set `9064:1572`, 60 variants over
/// `Style` x `Size` x `State` x `Leaf node`), pinned in
/// `test/fixtures/tree.json`, cross-read against
/// `useTreeItemLayoutStyles.styles.ts` and `useTreeStyles.styles.ts`.
///
/// * row fill per appearance: `Neutral/Background/Subtle/*`,
///   `Neutral/Background/Subtle/Light alpha/*`, or
///   `Neutral/Background/Transparent/*`. Rest is the fully transparent
///   `subtleBackground` in the first two, so the tree shows the surface behind
///   it until it is hovered.
/// * label and leading icon `Neutral/Foreground/2/*`, chevron
///   `Neutral/Foreground/3/*`, both disabled to
///   `Neutral/Foreground/Disabled/Rest`
/// * row radius `Corner radius/Medium` (4), right inset
///   `Spacing/Horizontal/S` (8), indent 24 per level
/// * row height 32 medium / 24 small, label `body1` / `caption1`, leading icon
///   16 / 12, chevron 12 in both, chevron column 24 in both
/// * inner vertical inset `Spacing/Vertical/SNudge` (6) medium,
///   `Spacing/Vertical/XS` (4) small; icon-to-label gap
///   `Spacing/Horizontal/XS` (4); label inset `Spacing/Horizontal/XXS` (2)
///
/// Four values disagree with React and are resolved toward Figma; see the class
/// doc on [FluentTree].
FluentTreeItemStyle resolveFluentTreeItemStyle(
  FluentTreeItemState state,
  FluentThemeData theme,
) {
  final c = theme.colors;

  // Disabled is the same token on all three appearances: Figma binds
  // `Neutral/Background/Subtle/Rest` on the two Subtle styles and
  // `Neutral/Background/Transparent/Rest` on Transparent, and both are the
  // fully transparent stop of their family. Naming the family rather than one
  // token still matters: in high contrast the *interactive* transparent tokens
  // become the opaque system highlight, and the Rest ones do not — which is
  // exactly the distinction a disabled row needs.
  final background = switch (state.appearance) {
    FluentTreeAppearance.subtle => FluentStateColor.tokens(
      rest: c.subtleBackground,
      hover: c.subtleBackgroundHover,
      pressed: c.subtleBackgroundPressed,
      selected: c.subtleBackgroundSelected,
      disabled: c.subtleBackground,
    ),
    FluentTreeAppearance.subtleAlpha => FluentStateColor.tokens(
      rest: c.subtleBackground,
      hover: c.subtleBackgroundLightAlphaHover,
      pressed: c.subtleBackgroundLightAlphaPressed,
      selected: c.subtleBackgroundLightAlphaSelected,
      disabled: c.subtleBackground,
    ),
    FluentTreeAppearance.transparent => FluentStateColor.tokens(
      rest: c.transparentBackground,
      hover: c.transparentBackgroundHover,
      pressed: c.transparentBackgroundPressed,
      selected: c.transparentBackgroundSelected,
      disabled: c.transparentBackground,
    ),
  };

  final foreground = FluentStateColor.tokens(
    rest: c.neutralForeground2,
    hover: c.neutralForeground2Hover,
    pressed: c.neutralForeground2Pressed,
    selected: c.neutralForeground2Selected,
    disabled: c.neutralForegroundDisabled,
  );

  // A separate ramp, not a tint of the label's: the chevron is one step quieter
  // in every state, and lands on the same disabled token.
  final expandIcon = FluentStateColor.tokens(
    rest: c.neutralForeground3,
    hover: c.neutralForeground3Hover,
    pressed: c.neutralForeground3Pressed,
    selected: c.neutralForeground3Selected,
    disabled: c.neutralForegroundDisabled,
  );

  final (
    textStyle,
    height,
    iconSize,
    inset,
    actionsInset,
  ) = switch (state.size) {
    FluentTreeSize.small => (
      theme.typography.caption1,
      24.0,
      FluentSize.size120,
      FluentSpacing.xs,
      FluentSpacing.none,
    ),
    FluentTreeSize.medium => (
      theme.typography.body1,
      32.0,
      FluentSize.size160,
      FluentSpacing.sNudge,
      FluentSpacing.xs,
    ),
  };

  return FluentTreeItemStyle(
    backgroundColor: background,
    foregroundColor: foreground,
    expandIconColor: expandIcon,
    borderRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allMedium,
    ),
    textStyle: WidgetStatePropertyAll<TextStyle?>(textStyle),
    // `Spacing/Horizontal/S` on the trailing edge and nothing on the leading
    // one — the leading inset is the level indent, added by the row. Vertical
    // padding is zero on the frame, on all 60 variants; the row height comes
    // from `innerPadding` instead.
    padding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsetsDirectional.only(end: FluentSpacing.s),
    ),
    innerPadding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsetsDirectional.symmetric(vertical: inset),
    ),
    contentPadding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsetsDirectional.symmetric(horizontal: FluentSpacing.xxs),
    ),
    actionsPadding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsetsDirectional.symmetric(vertical: actionsInset),
    ),
    gap: const WidgetStatePropertyAll<double?>(FluentSpacing.xs),
    iconSize: WidgetStatePropertyAll<double?>(iconSize),
    expandIconSize: const WidgetStatePropertyAll<double?>(FluentSize.size120),
    expandIconExtent: const WidgetStatePropertyAll<double?>(FluentSpacing.xxl),
    indent: const WidgetStatePropertyAll<double?>(FluentSpacing.xxl),
    rowGap: const WidgetStatePropertyAll<double?>(FluentSpacing.xxs),
    minimumSize: WidgetStatePropertyAll<Size?>(Size(0, height)),
    mouseCursor: const WidgetStatePropertyAll<MouseCursor?>(
      SystemMouseCursors.click,
    ),
  );
}

/// Renders one tree row from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentTreeItemBaseState] rather than [FluentTreeItemState] on purpose: it
/// never reads appearance or size, so a consumer can supply their own style and
/// still use Fluent's rendering, focus ring and chevron animation.
///
/// Only the chevron animates. Upstream's `useTreeItemLayoutStyles` declares no
/// `transition` at all on the row, so hover and press land on the next frame;
/// `TreeItemChevron.tsx` writes
/// `transform ${durationNormal}ms ${curveEasyEaseMax}` inline, which is exactly
/// [FluentMotionSpec.collapse]'s pair.
///
/// [states] is the live interaction set from [FluentInteractive].
Widget buildFluentTreeItem(
  FluentTreeItemBaseState state,
  FluentTreeItemStyle style,
  Set<WidgetState> states,
) {
  final radius = style.borderRadius?.resolve(states) ?? FluentRadius.allMedium;
  final background = style.backgroundColor?.resolve(states);
  final foreground = style.foregroundColor?.resolve(states);
  final chevronColor = style.expandIconColor?.resolve(states);
  final padding = style.padding?.resolve(states) ?? EdgeInsetsDirectional.zero;
  final innerPadding = style.innerPadding?.resolve(states) ?? EdgeInsets.zero;
  final contentPadding =
      style.contentPadding?.resolve(states) ?? EdgeInsets.zero;
  final actionsPadding =
      style.actionsPadding?.resolve(states) ?? EdgeInsets.zero;
  final gap = style.gap?.resolve(states) ?? FluentSpacing.xs;
  final iconSize = style.iconSize?.resolve(states) ?? FluentSize.size160;
  final chevronSize =
      style.expandIconSize?.resolve(states) ?? FluentSize.size120;
  final chevronExtent =
      style.expandIconExtent?.resolve(states) ?? FluentSpacing.xxl;
  final indent = style.indent?.resolve(states) ?? FluentSpacing.xxl;
  final minimumSize = style.minimumSize?.resolve(states) ?? Size.zero;
  final textStyle = style.textStyle?.resolve(states);

  final selector = switch (state.selectionMode) {
    FluentTreeSelectionMode.none => null,
    // ExcludeFocus, not a disabled control: upstream gives the selector
    // `tabIndex: -1` so the tree stays a single tab stop and the arrow keys own
    // the traversal. It is still operable by pointer.
    FluentTreeSelectionMode.multiple => ExcludeFocus(
      child: FluentCheckbox(
        checked: state.selected,
        onChanged: state.onSelectionChanged == null
            ? null
            : (value) => state.onSelectionChanged!(value ?? false),
      ),
    ),
    FluentTreeSelectionMode.single => ExcludeFocus(
      child: FluentRadio<bool>(
        value: true,
        groupValue: state.selected,
        disabled: state.onSelectionChanged == null,
        onChanged: (_) => state.onSelectionChanged?.call(!state.selected),
      ),
    ),
  };

  final leading = SizedBox(
    width: chevronExtent,
    child: state.branch
        ? _FluentTreeChevron(
            expanded: state.expanded,
            size: chevronSize,
            color: chevronColor,
          )
        : null,
  );

  // Figma's `Start content`: the vertical inset that sets the row height, and
  // the one gap that separates selector, icon and label.
  Widget content = Row(
    spacing: gap,
    children: <Widget>[
      ?selector,
      if (state.icon != null)
        IconTheme.merge(
          data: IconThemeData(color: foreground, size: iconSize),
          child: state.icon!,
        ),
      Expanded(
        child: Padding(
          padding: contentPadding,
          child: state.label ?? const SizedBox.shrink(),
        ),
      ),
    ],
  );

  if (textStyle != null || foreground != null) {
    content = DefaultTextStyle.merge(
      style: (textStyle ?? const TextStyle()).copyWith(color: foreground),
      child: content,
    );
  }
  content = Padding(padding: innerPadding, child: content);

  return FluentFocusRing(
    visible: states.contains(WidgetState.focused),
    borderRadius: radius,
    child: ConstrainedBox(
      constraints: BoxConstraints(minHeight: minimumSize.height),
      child: DecoratedBox(
        decoration: BoxDecoration(color: background, borderRadius: radius),
        child: Padding(
          // The indent is folded into the row's own padding rather than drawn
          // as a leading spacer, because that is what Figma measures: the
          // variant frame's `paddingLeft` *is* the indent, bound to
          // `tree-padding-left`.
          padding: padding.add(
            EdgeInsetsDirectional.only(start: indent * state.indentSteps),
          ),
          child: Row(
            children: <Widget>[
              leading,
              Expanded(child: content),
              if (state.actions != null)
                Padding(padding: actionsPadding, child: state.actions!),
            ],
          ),
        ),
      ),
    ),
  );
}

/// The rotating chevron.
///
/// `ChevronRight12Regular` under a [Transform], exactly as
/// `TreeItemChevron.tsx` does it: the glyph never changes, only its rotation.
///
/// Figma instead ships two glyphs — a 4.5x8 right-pointing vector for
/// `Expanded=False` and an 8x4.5 down-pointing one for `Expanded=True`. They
/// are the same shape a quarter turn apart, so a rotation reproduces both
/// endpoints and, unlike a glyph swap, can be animated.
class _FluentTreeChevron extends StatelessWidget {
  const _FluentTreeChevron({
    required this.expanded,
    required this.size,
    required this.color,
  });

  final bool expanded;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    // `chevron_right_12_regular` carries `matchTextDirection`, so the glyph is
    // already mirrored in RTL; negating the turn keeps the open chevron
    // pointing down rather than up, with the mirroring left to the framework.
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final turns = expanded ? 0.25 : 0.0;

    final icon = IconTheme.merge(
      data: IconThemeData(color: color, size: size),
      child: const Icon(FluentIcons.chevron_right_12_regular),
    );

    return FluentAnimatedStyle<double>(
      value: rtl ? -turns : turns,
      // durationNormal on curveEasyEaseMax — the pair `TreeItemChevron.tsx`
      // writes inline, and the same pair `FluentMotionSpec.collapse` already
      // carries. Reused rather than restated so there is one place to change.
      spec: FluentMotionSpec.collapse,
      lerp: lerpDouble,
      builder: (context, value) =>
          Transform.rotate(angle: value * 2 * math.pi, child: icon),
    );
  }
}

/// Overrides the tree row style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`.
class FluentTreeItemTheme extends InheritedTheme {
  /// Applies [style] to every row of every [FluentTree] in [child].
  const FluentTreeItemTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the appearance and size defaults.
  final FluentTreeItemStyle style;

  /// The nearest tree row style, or null.
  static FluentTreeItemStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentTreeItemTheme>()?.style;

  @override
  bool updateShouldNotify(FluentTreeItemTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentTreeItemTheme(style: style, child: child);
}

/// Moves focus [delta] rows through the visible list.
class FluentTreeMoveIntent extends Intent {
  /// Creates a move intent. Negative goes up.
  const FluentTreeMoveIntent(this.delta);

  /// How many visible rows to move by.
  final int delta;
}

/// Moves focus to the first or last visible row.
class FluentTreeEdgeIntent extends Intent {
  /// Creates an edge intent.
  const FluentTreeEdgeIntent({required this.last});

  /// Whether to go to the last row rather than the first.
  final bool last;
}

/// Opens the focused branch, or descends into it when it is already open.
class FluentTreeExpandIntent extends Intent {
  /// Creates an expand intent.
  const FluentTreeExpandIntent();
}

/// Closes the focused branch, or ascends to its parent when it is already
/// closed.
class FluentTreeCollapseIntent extends Intent {
  /// Creates a collapse intent.
  const FluentTreeCollapseIntent();
}

/// One visible row: an item plus the position the tree gives it.
@immutable
class _Row {
  const _Row({required this.item, required this.level, required this.parent});

  final FluentTreeItem item;
  final int level;
  final Object? parent;
}

/// A Fluent 2 tree: nested, expandable rows with one indent step per level.
///
/// ```dart
/// FluentTree(
///   items: const <FluentTreeItem>[
///     FluentTreeItem(
///       value: 'src',
///       label: Text('src'),
///       children: <FluentTreeItem>[
///         FluentTreeItem(value: 'main', label: Text('main.dart')),
///       ],
///     ),
///   ],
/// )
/// ```
///
/// ## Keyboard
///
/// The whole tree is one tab stop, as ARIA requires; inside it the arrow keys
/// own the traversal.
///
/// | Key | Effect |
/// |---|---|
/// | Up / Down | previous / next **visible** row, skipping disabled ones |
/// | Right | open a closed branch; descend into an open one |
/// | Left | close an open branch; otherwise move to the parent row |
/// | Home / End | first / last visible row |
/// | Space / Enter | toggle a branch; invoke [onInvoke] |
/// | printable keys | typeahead over [FluentTreeItem.searchLabel] |
///
/// ## Where the values disagree with React
///
/// Figma wins in all four, and both values are stated here rather than only in
/// `doc/token-divergences.md`, because each one is small enough to look like a
/// typo:
///
/// * **Leading icon.** React sets `fontSize: fontSizeBase500` — 20 at every
///   size. Figma draws **16** medium and **12** small.
/// * **Icon-to-label gap.** React ramps it (`XS` medium, `XXS` small). Figma
///   binds `Spacing/Horizontal/XS` (4) on both.
/// * **Trailing inset.** React gives `TreeItem` `paddingRight: none` and pads
///   the `actions` slot instead. Figma puts `Spacing/Horizontal/S` (8) on the
///   row frame, on all 60 variants.
/// * **Selected.** React has no selected rule on the row at all — selection is
///   the checkbox's job. Figma ships a whole `Selected` state, which is what
///   [selectedItems] drives through [WidgetState.selected].
///
/// One Figma authoring slip is *not* copied: the two `Style=Transparent,
/// Size=Medium, State=Disabled` variants carry **no fill node at all**, while
/// their Small twins bind `Neutral/Background/Transparent/Rest`. The Small
/// reading is used, since "no fill" and "the transparent token" differ in high
/// contrast and only one of them is stated twice.
class FluentTree extends StatefulWidget {
  /// Creates a tree over [items].
  const FluentTree({
    super.key,
    required this.items,
    this.appearance = FluentTreeAppearance.subtle,
    this.size = FluentTreeSize.medium,
    this.selectionMode = FluentTreeSelectionMode.none,
    this.openItems,
    this.defaultOpenItems = const <Object>{},
    this.onOpenChange,
    this.selectedItems = const <Object>{},
    this.onSelectionChange,
    this.onInvoke,
    this.style,
    this.semanticLabel,
  });

  /// The root nodes.
  final List<FluentTreeItem> items;

  /// Fill treatment, applied to every row.
  final FluentTreeAppearance appearance;

  /// Row height and type ramp, applied to every row.
  final FluentTreeSize size;

  /// Which selection control the rows carry.
  final FluentTreeSelectionMode selectionMode;

  /// The open set. Non-null makes the tree controlled; the widget then never
  /// changes it itself and [onOpenChange] must be handled.
  final Set<Object>? openItems;

  /// The initial open set for an uncontrolled tree.
  final Set<Object> defaultOpenItems;

  /// Reports the next open set. Required when [openItems] is non-null.
  final ValueChanged<Set<Object>>? onOpenChange;

  /// The selected set, driving both the selection control and the `Selected`
  /// token ramp.
  final Set<Object> selectedItems;

  /// Reports the next selected set. Null renders the selection control
  /// disabled.
  final ValueChanged<Set<Object>>? onSelectionChange;

  /// Invoked when a row is activated by click, Space or Enter, in addition to
  /// whatever the activation did to the open set.
  final ValueChanged<Object>? onInvoke;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentTreeItemStyle? style;

  /// Announced by assistive technology as the name of the tree.
  final String? semanticLabel;

  @override
  State<FluentTree> createState() => _FluentTreeState();
}

class _FluentTreeState extends State<FluentTree> {
  final Map<Object, FocusNode> _nodes = <Object, FocusNode>{};
  late Set<Object> _uncontrolledOpen = <Object>{...widget.defaultOpenItems};

  /// The row the single tab stop lands on. Rebuilt against the visible list on
  /// every build, so a collapse that hides the active row moves it rather than
  /// stranding the tab stop inside a closed branch.
  Object? _active;

  /// Typeahead buffer, and the frame timestamp it last grew on.
  ///
  /// Timed off `WidgetsBinding.instance.currentSystemFrameTimeStamp` rather than
  /// `DateTime.now()`: the frame clock is the one a widget test drives, so the
  /// 500ms reset is assertable instead of being a real-time race.
  String _typed = '';
  Duration _typedAt = Duration.zero - _typeaheadWindow;

  /// Upstream's `nextTypeAheadElement` resets after 500ms of no typing.
  static const Duration _typeaheadWindow = Duration(milliseconds: 500);

  Set<Object> get _open => widget.openItems ?? _uncontrolledOpen;

  @override
  void dispose() {
    for (final node in _nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  FocusNode _nodeFor(Object value) =>
      _nodes.putIfAbsent(value, () => FocusNode(debugLabel: 'FluentTree'));

  /// The visible rows, in traversal order: an item, then its subtree if open.
  List<_Row> _visible() {
    final rows = <_Row>[];
    void walk(List<FluentTreeItem> items, int level, Object? parent) {
      for (final item in items) {
        rows.add(_Row(item: item, level: level, parent: parent));
        if (item.isBranch && _open.contains(item.value)) {
          walk(item.children, level + 1, item.value);
        }
      }
    }

    walk(widget.items, 1, null);
    return rows;
  }

  void _setOpen(Set<Object> next) {
    widget.onOpenChange?.call(next);
    if (widget.openItems == null) {
      setState(() => _uncontrolledOpen = next);
    }
  }

  void _toggle(FluentTreeItem item) {
    if (!item.isBranch) return;
    final next = <Object>{..._open};
    if (!next.remove(item.value)) next.add(item.value);
    _setOpen(next);
  }

  void _setSelected(FluentTreeItem item, {required bool selected}) {
    final handler = widget.onSelectionChange;
    if (handler == null) return;
    final next = switch (widget.selectionMode) {
      // Single selection replaces rather than accumulates, which is the whole
      // difference between a radio and a checkbox.
      FluentTreeSelectionMode.single =>
        selected ? <Object>{item.value} : <Object>{},
      // Parenthesised deliberately: `..` binds looser than `?:`, so
      // `cond ? a : b..remove(x)` removes from whichever branch was taken —
      // which silently emptied the multi-select set.
      _ =>
        selected
            ? <Object>{...widget.selectedItems, item.value}
            : (<Object>{...widget.selectedItems}..remove(item.value)),
    };
    handler(next);
  }

  void _focus(Object value) {
    setState(() => _active = value);
    _nodeFor(value).requestFocus();
  }

  int _activeIndex(List<_Row> rows) {
    final index = rows.indexWhere((row) => row.item.value == _active);
    if (index >= 0) return index;
    return rows.indexWhere((row) => row.item.enabled);
  }

  void _move(int delta) {
    final rows = _visible();
    if (rows.isEmpty) return;
    var index = _activeIndex(rows);
    // With nothing focused, an arrow enters the tree from the near end.
    if (index < 0) index = delta > 0 ? -1 : rows.length;
    for (
      var next = index + delta;
      next >= 0 && next < rows.length;
      next += delta
    ) {
      if (rows[next].item.enabled) {
        _focus(rows[next].item.value);
        return;
      }
    }
  }

  void _edge({required bool last}) {
    final rows = _visible();
    for (final row in last ? rows.reversed : rows) {
      if (row.item.enabled) {
        _focus(row.item.value);
        return;
      }
    }
  }

  void _expand() {
    final rows = _visible();
    final index = _activeIndex(rows);
    if (index < 0) return;
    final row = rows[index];
    if (!row.item.isBranch) return;
    if (!_open.contains(row.item.value)) {
      _toggle(row.item);
      return;
    }
    // Already open: Right descends to the first enabled child.
    for (final child in row.item.children) {
      if (child.enabled) {
        _focus(child.value);
        return;
      }
    }
  }

  void _collapse() {
    final rows = _visible();
    final index = _activeIndex(rows);
    if (index < 0) return;
    final row = rows[index];
    if (row.item.isBranch && _open.contains(row.item.value)) {
      _toggle(row.item);
      return;
    }
    final parent = row.parent;
    if (parent != null) _focus(parent);
  }

  /// Typeahead: jump to the next enabled row whose [FluentTreeItem.searchLabel]
  /// starts with what has been typed, wrapping past the active row.
  KeyEventResult _typeahead(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final character = event.character;
    if (character == null || character.trim().isEmpty) {
      return KeyEventResult.ignored;
    }
    if (HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isAltPressed) {
      return KeyEventResult.ignored;
    }

    final now = WidgetsBinding.instance.currentSystemFrameTimeStamp;
    _typed = now - _typedAt > _typeaheadWindow ? character : _typed + character;
    _typedAt = now;

    final rows = _visible();
    if (rows.isEmpty) return KeyEventResult.ignored;
    final start = math.max(_activeIndex(rows), 0);
    final prefix = _typed.toLowerCase();
    for (var offset = 1; offset <= rows.length; offset++) {
      final row = rows[(start + offset) % rows.length];
      final label = row.item.searchLabel?.toLowerCase();
      if (row.item.enabled && label != null && label.startsWith(prefix)) {
        _focus(row.item.value);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  static const Map<ShortcutActivator, Intent>
  _shortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.arrowUp): FluentTreeMoveIntent(-1),
    SingleActivator(LogicalKeyboardKey.arrowDown): FluentTreeMoveIntent(1),
    SingleActivator(LogicalKeyboardKey.arrowRight): FluentTreeExpandIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft): FluentTreeCollapseIntent(),
    SingleActivator(LogicalKeyboardKey.home): FluentTreeEdgeIntent(last: false),
    SingleActivator(LogicalKeyboardKey.end): FluentTreeEdgeIntent(last: true),
  };

  @override
  Widget build(BuildContext context) {
    final rows = _visible();
    final rtl = Directionality.of(context) == TextDirection.rtl;

    // The tab stop is recomputed here rather than only on key presses, so a
    // subtree closing over the active row hands the stop to the first row that
    // is still visible instead of leaving it nowhere.
    final active =
        rows.any((row) => row.item.value == _active && row.item.enabled)
        ? _active
        : rows
              .cast<_Row?>()
              .firstWhere((row) => row!.item.enabled, orElse: () => null)
              ?.item
              .value;

    final theme = FluentTheme.of(context);
    final rowGap =
        resolveFluentTreeItemStyle(
              resolveFluentTreeItemState(
                appearance: widget.appearance,
                size: widget.size,
              ),
              theme,
            )
            .merge(FluentTreeItemTheme.maybeOf(context))
            .merge(widget.style)
            .rowGap
            ?.resolve(const <WidgetState>{}) ??
        FluentSpacing.xxs;

    return Shortcuts(
      shortcuts: _shortcuts,
      // Actions sits outside any FocusScope and above every row, so an intent
      // raised on a focused row finds it by walking up the focus chain.
      child: Actions(
        actions: <Type, Action<Intent>>{
          FluentTreeMoveIntent: CallbackAction<FluentTreeMoveIntent>(
            onInvoke: (intent) {
              _move(intent.delta);
              return null;
            },
          ),
          FluentTreeEdgeIntent: CallbackAction<FluentTreeEdgeIntent>(
            onInvoke: (intent) {
              _edge(last: intent.last);
              return null;
            },
          ),
          // Mirrored in RTL: Right must still mean "further into the tree",
          // which is leftwards when the tree itself reads right to left.
          FluentTreeExpandIntent: CallbackAction<FluentTreeExpandIntent>(
            onInvoke: (_) {
              rtl ? _collapse() : _expand();
              return null;
            },
          ),
          FluentTreeCollapseIntent: CallbackAction<FluentTreeCollapseIntent>(
            onInvoke: (_) {
              rtl ? _expand() : _collapse();
              return null;
            },
          ),
        },
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onKeyEvent: _typeahead,
          child: Semantics(
            role: SemanticsRole.list,
            container: true,
            explicitChildNodes: true,
            label: widget.semanticLabel,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: rowGap,
              children: <Widget>[
                for (final row in rows)
                  _FluentTreeRow(
                    key: ValueKey<Object>(row.item.value),
                    row: row,
                    appearance: widget.appearance,
                    size: widget.size,
                    selectionMode: widget.selectionMode,
                    selected: widget.selectedItems.contains(row.item.value),
                    expanded: _open.contains(row.item.value),
                    listStyle: widget.style,
                    focusNode: _nodeFor(row.item.value),
                    tabStop: row.item.value == active,
                    onSelectionChanged: widget.onSelectionChange == null
                        ? null
                        : (value) => _setSelected(row.item, selected: value),
                    onPressed: row.item.enabled
                        ? () {
                            _focus(row.item.value);
                            _toggle(row.item);
                            widget.onInvoke?.call(row.item.value);
                          }
                        : null,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One rendered row: interaction, semantics and the resolved style.
class _FluentTreeRow extends StatelessWidget {
  const _FluentTreeRow({
    super.key,
    required this.row,
    required this.appearance,
    required this.size,
    required this.selectionMode,
    required this.selected,
    required this.expanded,
    required this.listStyle,
    required this.focusNode,
    required this.tabStop,
    required this.onSelectionChanged,
    required this.onPressed,
  });

  final _Row row;
  final FluentTreeAppearance appearance;
  final FluentTreeSize size;
  final FluentTreeSelectionMode selectionMode;
  final bool selected;
  final bool expanded;
  final FluentTreeItemStyle? listStyle;
  final FocusNode focusNode;
  final bool tabStop;
  final ValueChanged<bool>? onSelectionChanged;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // Roving tab index: exactly one row is reachable by Tab, and the arrow keys
    // move it. Without this the tree would be N tab stops, which is the single
    // most common way an ARIA tree is got wrong.
    focusNode.skipTraversal = !tabStop;

    final item = row.item;
    final state = resolveFluentTreeItemState(
      enabled: item.enabled,
      level: row.level,
      branch: item.isBranch,
      expanded: expanded,
      selected: selected,
      selectionMode: selectionMode,
      appearance: appearance,
      size: size,
      icon: item.icon,
      label: item.label,
      actions: item.actions,
      onSelectionChanged: item.enabled ? onSelectionChanged : null,
    );

    final resolved = resolveFluentTreeItemStyle(
      state,
      FluentTheme.of(context),
    ).merge(FluentTreeItemTheme.maybeOf(context)).merge(listStyle);

    return Semantics(
      role: SemanticsRole.listItem,
      // Flutter's engine has no `tree`/`treeitem` role and no `aria-level`, so
      // the depth rides on `identifier` — the one channel that survives to the
      // platform and can be asserted in a test. `expanded` and `selected` do
      // have first-class support and are used as such.
      identifier: 'fluent-tree-item-level-${row.level}',
      expanded: item.isBranch ? expanded : null,
      selected: selectionMode == FluentTreeSelectionMode.none && !selected
          ? null
          : selected,
      enabled: item.enabled,
      child: FluentInteractive(
        onPressed: onPressed,
        enabled: item.enabled,
        focusNode: focusNode,
        mouseCursor:
            resolved.mouseCursor?.resolve(const <WidgetState>{}) ??
            SystemMouseCursors.click,
        builder: (context, states, _) => buildFluentTreeItem(
          state,
          resolved,
          // Selected is a design state here, not something the pointer sets, so
          // it is folded into the set the style resolves against.
          selected ? <WidgetState>{...states, WidgetState.selected} : states,
        ),
      ),
    );
  }
}
