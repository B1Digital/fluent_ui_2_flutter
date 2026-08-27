import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/semantics.dart' show SemanticsRole;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../inputs/checkbox.dart';
import '../inputs/checkbox_style.dart';
import '../inputs/radio.dart';
import '../inputs/radio_style.dart';
import '../internal/focus_ring.dart';
import '../internal/interaction.dart';
import 'list_item_style.dart';

/// Row height and title type ramp. Figma's `Size` axis.
enum FluentListItemSize {
  /// 24 high on one line, 48 on two. `caption1` title on one line.
  small,

  /// 32 high on one line, 56 on two. The default. `body1` title.
  medium,
}

/// Which affordance a row draws for its selection, and therefore how the list
/// behaves. Figma's `.Selection` `Type` axis, plus [none].
///
/// The two selecting modes are not a styling choice: [checkbox] is a
/// multi-select list and [radio] a single-select one, exactly as the HTML
/// controls they compose imply.
enum FluentListSelection {
  /// No affordance. Rows still take the `Selected` fill when active, which is
  /// how Fluent draws a navigation list.
  none,

  /// A `FluentCheckbox`. Selecting is additive: any number of rows may be
  /// selected at once.
  checkbox,

  /// A `FluentRadio`. Selecting one row deselects the rest, and a selected row
  /// cannot be deselected by activating it again — the Fluent radio rule.
  radio,
}

/// Everything needed to render a list item, independent of its size.
///
/// The counterpart of `FluentButtonBaseState`. [buildFluentListItem] takes this
/// rather than [FluentListItemState], which is what makes "Fluent's state, my
/// own styling, Fluent's rendering" a supported path rather than a fork.
///
/// The selection affordance arrives here as a already-built [indicator] widget
/// for the same reason a button's icon does: the renderer places it and never
/// asks what it is.
@immutable
class FluentListItemBaseState {
  /// Creates a base state.
  const FluentListItemBaseState({
    required this.enabled,
    required this.selected,
    this.indicator,
    this.media,
    this.primary,
    this.secondary,
    this.tertiary,
    this.trailing,
  });

  /// Whether the row responds to input.
  final bool enabled;

  /// Whether the row is selected. Figma's `Active` axis, which moves both the
  /// fill and the title's weight.
  final bool selected;

  /// The selection affordance, already built and made inert. Null when the list
  /// is [FluentListSelection.none].
  final Widget? indicator;

  /// The leading media slot — an avatar, an icon, a thumbnail.
  final Widget? media;

  /// The title.
  final Widget? primary;

  /// The second line. Its presence is what makes this a two-line row, which is
  /// Figma's `ListItem type` axis.
  final Widget? secondary;

  /// Trailing metadata on the title's line — a timestamp, a count.
  final Widget? tertiary;

  /// Trailing controls, at the end of the row.
  final Widget? trailing;

  /// Whether this renders as a two-line row.
  ///
  /// Derived rather than a flag: Figma's `ListItem type` axis is exactly
  /// "is there a second line", and a `Two line` row with no second line has no
  /// meaning.
  bool get twoLine => secondary != null;
}

/// A list item's fully resolved state, including the design axis.
///
/// The counterpart of `FluentButtonState`: base state plus exactly `size`.
@immutable
class FluentListItemState extends FluentListItemBaseState {
  /// Creates a resolved state.
  const FluentListItemState({
    required super.enabled,
    required super.selected,
    required this.size,
    super.indicator,
    super.media,
    super.primary,
    super.secondary,
    super.tertiary,
    super.trailing,
  });

  /// Row height and title type ramp.
  final FluentListItemSize size;
}

/// Builds the state a list item will be styled and rendered from.
///
/// The first of the three-function recomposition contract.
FluentListItemState resolveFluentListItemState({
  bool enabled = true,
  bool selected = false,
  FluentListItemSize size = FluentListItemSize.medium,
  Widget? indicator,
  Widget? media,
  Widget? primary,
  Widget? secondary,
  Widget? tertiary,
  Widget? trailing,
}) => FluentListItemState(
  enabled: enabled,
  selected: selected,
  size: size,
  indicator: indicator,
  media: media,
  primary: primary,
  secondary: secondary,
  tertiary: tertiary,
  trailing: trailing,
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axis. Every colour comes from a Fluent token; nothing
/// here computes one.
///
/// Token sources are the Figma `ListItem` component set (`9328:24865`, page
/// `8995:4`), extracted into `test/fixtures/list_item.json` and asserted
/// variant-by-variant in the tests.
///
/// ## Why `selected` picks the ramp rather than only the token
///
/// Figma's `Active` axis moves two things at once: the fill goes to
/// `Neutral/Background/Subtle/Selected`, which [FluentStateColor] resolves from
/// [WidgetState.selected] directly, and the **type ramp steps to Semibold**,
/// which no `WidgetStateProperty` can express because it is not a state — it is
/// a variant. So the weight is branched on here and the fill is not.
///
/// ## Three divergences from Figma, all recorded in `doc/token-divergences.md`
///
/// * The title on the one-line variants binds `Neutral/Foreground/1/Rest` in
///   every state, and the two-line **medium** set binds
///   `Neutral/Foreground/2/Rest` for the title where the two-line **small** set
///   binds `Neutral/Foreground/1/*` with a full ramp. The small two-line
///   table is the internally consistent one — a title is `Foreground/1` and a
///   second line is `Foreground/2` — and it is the only one of the three that
///   states hover and pressed at all, so it wins.
/// * `Active=True` binds the *Rest* foreground tokens. Those resolve to the
///   same colour as `Neutral/Foreground/1/Selected` in light and dark, but in
///   **high contrast** the selected fill is the system Highlight and the Rest
///   foreground is HighlightText's inverse — white on cyan. The `*Selected`
///   foreground tokens are selected instead; they are byte-identical to Figma
///   for the title in both normal themes and readable in high contrast.
/// * The focus ring's inner tone. Figma's `Border-inner` binds
///   `Neutral/Background/1/Rest`; [FluentFocusRing] binds `strokeFocus1`, as it
///   does for every other component in this port. The two agree in light and
///   differ in dark.
FluentListItemStyle resolveFluentListItemStyle(
  FluentListItemState state,
  FluentThemeData theme,
) {
  final c = theme.colors;

  final background = FluentStateColor.tokens(
    rest: c.subtleBackground,
    hover: c.subtleBackgroundHover,
    pressed: c.subtleBackgroundPressed,
    selected: c.subtleBackgroundSelected,
    disabled: c.neutralBackgroundDisabled,
  );

  final primaryColor = FluentStateColor.tokens(
    rest: c.neutralForeground1,
    hover: c.neutralForeground1Hover,
    pressed: c.neutralForeground1Pressed,
    selected: c.neutralForeground1Selected,
    disabled: c.neutralForegroundDisabled,
  );
  final secondaryColor = FluentStateColor.tokens(
    rest: c.neutralForeground2,
    hover: c.neutralForeground2Hover,
    pressed: c.neutralForeground2Pressed,
    selected: c.neutralForeground2Selected,
    disabled: c.neutralForegroundDisabled,
  );
  final tertiaryColor = FluentStateColor.tokens(
    rest: c.neutralForeground3,
    hover: c.neutralForeground3Hover,
    pressed: c.neutralForeground3Pressed,
    selected: c.neutralForeground3Selected,
    disabled: c.neutralForegroundDisabled,
  );

  // Geometry, verbatim from the Figma set. The two-line row's content inset is
  // size-invariant — both sizes hold the same 48-high `.Persona Text Ramp`, and
  // only the row around it grows — while the one-line inset steps with the
  // size.
  //
  // `contentPadding` folds two Figma frames into one, because this port has one
  // widget where Figma has two: the `.Content Left` frame's own padding plus
  // the `Text wrapper`'s `Spacing/Horizontal/XXS` on each side. Small one line
  // is (top 4, right 4, bottom 4, left 0) + (2, 2) horizontally; medium is
  // (6, 0, 6, 0) + the same.
  final (height, contentPadding, mediaPadding, selectionInset) = switch ((
    state.size,
    state.twoLine,
  )) {
    (FluentListItemSize.small, false) => (
      24.0,
      const EdgeInsets.fromLTRB(2, FluentSpacing.xs, 6, FluentSpacing.xs),
      // The one-line media slot sits *inside* Figma's content frame, so the gap
      // to the title is that frame's `itemSpacing`: XS at small, None at
      // medium. (Two of the ten medium variants say XS instead — an authoring
      // wobble; the eight-variant majority is taken.)
      const EdgeInsets.only(right: FluentSpacing.xs),
      EdgeInsets.zero,
    ),
    (FluentListItemSize.medium, false) => (
      32.0,
      const EdgeInsets.fromLTRB(
        2,
        FluentSpacing.sNudge,
        2,
        FluentSpacing.sNudge,
      ),
      EdgeInsets.zero,
      const EdgeInsets.symmetric(vertical: FluentSpacing.xs),
    ),
    (FluentListItemSize.small, true) => (
      48.0,
      const EdgeInsets.fromLTRB(
        FluentSpacing.s,
        FluentSpacing.sNudge,
        FluentSpacing.xs,
        FluentSpacing.sNudge,
      ),
      const EdgeInsets.only(left: FluentSpacing.xxs),
      const EdgeInsets.symmetric(vertical: FluentSpacing.m),
    ),
    (FluentListItemSize.medium, true) => (
      56.0,
      const EdgeInsets.fromLTRB(
        FluentSpacing.s,
        FluentSpacing.sNudge,
        FluentSpacing.xs,
        FluentSpacing.sNudge,
      ),
      const EdgeInsets.only(left: FluentSpacing.xxs),
      const EdgeInsets.symmetric(vertical: FluentSpacing.l),
    ),
  };

  // The title is `caption1` only on the one-line SMALL row; every other variant
  // is `body1`. Active steps the whole row to Semibold — see the doc above.
  final strong = state.selected;
  final titleRamp = state.size == FluentListItemSize.small && !state.twoLine
      ? (strong ? theme.typography.caption1Strong : theme.typography.caption1)
      : (strong ? theme.typography.body1Strong : theme.typography.body1);
  final minorRamp = strong
      ? theme.typography.caption1Strong
      : theme.typography.caption1;

  // Figma's `Tertiary text` frame is `Spacing/*/XXS` all round on a one-line
  // row and vertical-only on a two-line one, where the gap to the title is the
  // `1st line` frame's `Spacing/Horizontal/S`. Folded into the left inset,
  // because a gap between two widgets and a left inset on the second are the
  // same pixels.
  final tertiaryPadding = state.twoLine
      ? const EdgeInsets.fromLTRB(FluentSpacing.s, FluentSpacing.xxs, 0, 2)
      : const EdgeInsets.all(FluentSpacing.xxs);

  return FluentListItemStyle(
    backgroundColor: background,
    primaryTextColor: primaryColor,
    secondaryTextColor: secondaryColor,
    tertiaryTextColor: tertiaryColor,
    primaryTextStyle: WidgetStatePropertyAll<TextStyle?>(titleRamp),
    secondaryTextStyle: WidgetStatePropertyAll<TextStyle?>(minorRamp),
    tertiaryTextStyle: WidgetStatePropertyAll<TextStyle?>(minorRamp),
    borderRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allMedium,
    ),
    padding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.only(right: FluentSpacing.s),
    ),
    contentPadding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(contentPadding),
    mediaPadding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(mediaPadding),
    tertiaryPadding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      tertiaryPadding,
    ),
    selectionPadding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      selectionInset,
    ),
    selectionSize: const WidgetStatePropertyAll<double?>(24),
    minimumSize: WidgetStatePropertyAll<Size?>(Size(0, height)),
    mouseCursor: const WidgetStatePropertyAll<MouseCursor?>(
      SystemMouseCursors.click,
    ),
  );
}

/// Renders a list item from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentListItemBaseState] rather than [FluentListItemState] on purpose: it
/// never reads the size, so a consumer can supply their own style and still use
/// Fluent's layout, focus ring and text ramps.
///
/// **Nothing animates, deliberately.** `useListItemStyles.styles.ts` and
/// `useListStyles.styles.ts` on `microsoft/fluentui@master` declare no
/// `transition`, no `animation` and no `motionTokens` reference at all, so the
/// fill changes on the frame the pointer arrives. This is the Checkbox/Tooltip
/// category rather than an omission, and it also makes the component trivially
/// correct under `MediaQuery.disableAnimationsOf`: there is no animation to
/// shorten.
///
/// [states] is the live interaction set from [FluentInteractive], plus
/// [WidgetState.selected] when the row is selected.
Widget buildFluentListItem(
  FluentListItemBaseState state,
  FluentListItemStyle style,
  Set<WidgetState> states,
) {
  final radius = style.borderRadius?.resolve(states) ?? FluentRadius.allMedium;
  final background = style.backgroundColor?.resolve(states);
  final padding = style.padding?.resolve(states) ?? EdgeInsets.zero;
  final contentPadding =
      style.contentPadding?.resolve(states) ?? EdgeInsets.zero;
  final mediaPadding = style.mediaPadding?.resolve(states) ?? EdgeInsets.zero;
  final tertiaryPadding =
      style.tertiaryPadding?.resolve(states) ?? EdgeInsets.zero;
  final selectionPadding =
      style.selectionPadding?.resolve(states) ?? EdgeInsets.zero;
  final selectionSize = style.selectionSize?.resolve(states) ?? 24;
  final minimumSize = style.minimumSize?.resolve(states) ?? Size.zero;

  Widget? line(
    Widget? child,
    WidgetStateProperty<TextStyle?>? textStyle,
    WidgetStateProperty<Color?>? color,
  ) {
    if (child == null) return null;
    return DefaultTextStyle.merge(
      style: (textStyle?.resolve(states) ?? const TextStyle()).copyWith(
        color: color?.resolve(states),
      ),
      child: child,
    );
  }

  final primary = line(
    state.primary,
    style.primaryTextStyle,
    style.primaryTextColor,
  );
  final secondary = line(
    state.secondary,
    style.secondaryTextStyle,
    style.secondaryTextColor,
  );
  final tertiary = line(
    state.tertiary,
    style.tertiaryTextStyle,
    style.tertiaryTextColor,
  );

  // Where the trailing metadata sits is structural, not stylistic, so it is
  // read off the base state rather than the size: Figma keeps it beside the
  // title *inside* the `1st line` frame on a two-line row, and hangs it off the
  // variant frame as a sibling of the content on a one-line one. The two are
  // not interchangeable — nested, its own `Spacing/*/XXS` inset would stack on
  // the content's and make a 24-high row 28.
  final inlineTertiary = state.twoLine ? tertiary : null;
  final asideTertiary = state.twoLine ? null : tertiary;

  final titleLine = Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: <Widget>[
      if (primary != null) Expanded(child: primary),
      if (inlineTertiary != null)
        Padding(padding: tertiaryPadding, child: inlineTertiary),
    ],
  );

  final content = Padding(
    padding: contentPadding,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[titleLine, ?secondary],
    ),
  );

  final row = Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: <Widget>[
      if (state.indicator != null)
        Padding(
          padding: selectionPadding,
          child: SizedBox.square(
            dimension: selectionSize,
            child: state.indicator,
          ),
        ),
      if (state.media != null)
        Padding(padding: mediaPadding, child: state.media),
      Expanded(child: content),
      if (asideTertiary != null)
        Padding(padding: tertiaryPadding, child: asideTertiary),
      ?state.trailing,
    ],
  );

  return FluentFocusRing(
    visible: states.contains(WidgetState.focused),
    borderRadius: radius,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: minimumSize.height,
        minWidth: minimumSize.width,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(color: background, borderRadius: radius),
        child: Padding(padding: padding, child: row),
      ),
    ),
  );
}

/// Overrides the list item style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// list's `style`, then the item's own `style`.
class FluentListItemTheme extends InheritedTheme {
  /// Applies [style] to every [FluentListItem] in [child].
  const FluentListItemTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the size defaults.
  final FluentListItemStyle style;

  /// The nearest list item style, or null.
  static FluentListItemStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentListItemTheme>()?.style;

  @override
  bool updateShouldNotify(FluentListItemTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentListItemTheme(style: style, child: child);
}

/// Moves keyboard focus by [delta] rows, skipping disabled ones.
class FluentListMoveIntent extends Intent {
  /// Creates an intent to move focus by [delta].
  const FluentListMoveIntent(this.delta);

  /// How many rows to move by. Negative moves towards the first row.
  final int delta;
}

/// Moves keyboard focus to the first or last enabled row.
class FluentListEdgeIntent extends Intent {
  /// Creates an intent to jump to an end of the list.
  const FluentListEdgeIntent({required this.last});

  /// Whether to jump to the last row rather than the first.
  final bool last;
}

/// Everything a [FluentListItem] needs from the list it sits in.
class _FluentListScope extends InheritedWidget {
  const _FluentListScope({
    required this.size,
    required this.selection,
    required this.selectedValues,
    required this.onToggle,
    required this.listStyle,
    required this.focusNodeFor,
    required super.child,
  });

  final FluentListItemSize size;
  final FluentListSelection selection;
  final Set<Object> selectedValues;
  final void Function(Object value)? onToggle;
  final FluentListItemStyle? listStyle;
  final FocusNode Function(Object value) focusNodeFor;

  static _FluentListScope of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_FluentListScope>();
    assert(
      scope != null,
      'FluentListItem must be given to a FluentList, which is what owns the '
      'selection, the keyboard handling and the roving focus.',
    );
    return scope!;
  }

  @override
  bool updateShouldNotify(_FluentListScope oldWidget) =>
      size != oldWidget.size ||
      selection != oldWidget.selection ||
      !setEquals(selectedValues, oldWidget.selectedValues) ||
      onToggle != oldWidget.onToggle ||
      listStyle != oldWidget.listStyle;

  static bool setEquals(Set<Object> a, Set<Object> b) =>
      a.length == b.length && a.every(b.contains);
}

/// Strips a composed control of everything the row already owns.
///
/// The selection affordance is a *display* of the row's state, not a second
/// control: Figma's `.Selection` is a 24x24 frame the row drives. Composing the
/// real `FluentCheckbox`/`FluentRadio` and then removing its focus stop, its
/// hit test and its semantics node is what keeps one tab stop, one tap target
/// and one announcement per row while still getting Fluent's own indicator
/// geometry, token table and glyph.
Widget _inert(Widget child) => ExcludeSemantics(
  child: ExcludeFocus(child: IgnorePointer(child: child)),
);

/// One row of a [FluentList].
///
/// ```dart
/// FluentListItem<String>(
///   value: 'ada',
///   media: const FluentAvatar(name: 'Ada Lovelace'),
///   child: const Text('Ada Lovelace'),
///   secondary: const Text('Analytical engine'),
///   tertiary: const Text('09:41'),
/// )
/// ```
///
/// A row is inert on its own: selection, keyboard handling and focus all belong
/// to the list, and it reads them from the nearest [FluentList] ancestor.
/// Constructing one outside a list asserts.
///
/// Passing [secondary] is what makes the row two-line — Figma's
/// `ListItem type` axis is exactly "is there a second line".
///
/// Pass `enabled: false` to disable it — a real state, not a visual treatment:
/// the row stops reporting hover and press, refuses focus, is skipped by arrow
/// navigation, and cannot be selected.
class FluentListItem<T extends Object> extends StatelessWidget {
  /// Creates a row.
  const FluentListItem({
    super.key,
    required this.value,
    this.child,
    this.secondary,
    this.tertiary,
    this.media,
    this.trailing,
    this.enabled = true,
    this.style,
    this.semanticLabel,
  });

  /// Identifies this row within its list. Compared with `==`.
  final T value;

  /// The title.
  final Widget? child;

  /// The second line. Its presence makes this a two-line row.
  final Widget? secondary;

  /// Trailing metadata on the title's line — a timestamp, a count.
  final Widget? tertiary;

  /// The leading media slot, after the selection affordance.
  final Widget? media;

  /// Trailing controls at the end of the row.
  ///
  /// These are *inside* the row's tap target, so anything interactive here
  /// should be its own focusable widget; the row will not swallow its taps.
  final Widget? trailing;

  /// Whether the row can be selected.
  final bool enabled;

  /// Overrides layered over the list's style. Merged last, so it wins.
  final FluentListItemStyle? style;

  /// Announced by assistive technology in place of the row's own text.
  final String? semanticLabel;

  /// The affordance for [selection], composed from the existing controls and
  /// made inert.
  ///
  /// Both are restyled to Figma's `.Selection` box: a 24x24 frame is
  /// `Spacing/*/XS` around a 16 indicator, where both controls default to the
  /// 8 margin that makes them 32 — which would overflow a 24-high small row.
  Widget? _indicator(FluentListSelection selection, bool selected, bool live) =>
      switch (selection) {
        FluentListSelection.none => null,
        FluentListSelection.checkbox => _inert(
          FluentCheckbox(
            checked: selected,
            // Non-null so the control paints its enabled ramp; never invoked,
            // because `_inert` removes its hit test and its focus stop.
            onChanged: live ? (_) {} : null,
            style: const FluentCheckboxStyle(
              indicatorMargin: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
                EdgeInsets.all(FluentSpacing.xs),
              ),
              minimumSize: WidgetStatePropertyAll<Size?>(Size.square(24)),
            ),
          ),
        ),
        FluentListSelection.radio => _inert(
          FluentRadio<bool>(
            value: true,
            groupValue: selected,
            onChanged: live ? (_) {} : null,
            disabled: !live,
            style: const FluentRadioStyle(
              indicatorPadding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
                EdgeInsets.all(FluentSpacing.xs),
              ),
            ),
          ),
        ),
      };

  @override
  Widget build(BuildContext context) {
    final scope = _FluentListScope.of(context);
    final selected = scope.selectedValues.contains(value);
    final live = enabled && scope.onToggle != null;

    final state = resolveFluentListItemState(
      enabled: enabled,
      selected: selected,
      size: scope.size,
      indicator: _indicator(scope.selection, selected, live),
      media: media,
      primary: child,
      secondary: secondary,
      tertiary: tertiary,
      trailing: trailing,
    );

    // Lowest to highest: defaults, subtree theme, the list's style, then this
    // row's own.
    final resolved = resolveFluentListItemStyle(state, FluentTheme.of(context))
        .merge(FluentListItemTheme.maybeOf(context))
        .merge(scope.listStyle)
        .merge(style);

    return MergeSemantics(
      child: Semantics(
        role: SemanticsRole.listItem,
        selected: selected,
        enabled: live,
        label: semanticLabel,
        child: FluentInteractive(
          onPressed: live ? () => scope.onToggle!(value) : null,
          enabled: live,
          focusNode: scope.focusNodeFor(value),
          mouseCursor:
              resolved.mouseCursor?.resolve(const <WidgetState>{}) ??
              SystemMouseCursors.click,
          builder: (context, states, _) {
            // A row in a read-only list is not *disabled*, it is merely not a
            // control: `enabled` is the item's own flag and it alone selects
            // the disabled token ramp. `FluentInteractive` reports disabled
            // whenever it has no callback, which is exactly the read-only
            // case, so that report is dropped here.
            final visual = <WidgetState>{
              ...states,
              if (selected) WidgetState.selected,
            };
            if (enabled) visual.remove(WidgetState.disabled);
            return buildFluentListItem(state, resolved, visual);
          },
        ),
      ),
    );
  }
}

/// A Fluent 2 list: the rows, and the selection they share.
///
/// ```dart
/// FluentList<String>(
///   selection: FluentListSelection.checkbox,
///   selectedValues: selected,
///   onSelectionChange: (values) => setState(() => selected = values),
///   items: const <FluentListItem<String>>[
///     FluentListItem<String>(value: 'a', child: Text('First')),
///     FluentListItem<String>(value: 'b', child: Text('Second')),
///   ],
/// )
/// ```
///
/// ## Keyboard: one tab stop, arrows inside
///
/// The whole list is a single stop in the Tab order — the WAI-ARIA
/// composite-widget rule the `SemanticsRole.list` of `listItem`s below is held
/// to. Tab moves in and straight back out, and the index is remembered, so
/// Tabbing away and back returns to the row you left.
///
/// Arrow up and down move **focus**, and `Home` and `End` jump to the first and
/// last enabled row. `Space` — and `Enter`, and a tap — toggle the focused
/// row's selection. Moving and selecting are separate here, unlike
/// `FluentTabList` where an arrow selects: a multi-select list has to let you
/// travel past a row without taking it.
///
/// Disabled rows are skipped and the ends do not wrap.
///
/// ## The list paints nothing
///
/// It has no style struct and no theme of its own for the same reason
/// upstream's `useListStyles.styles.ts` binds no token: its entire contribution
/// is a column and a reset. Every pixel belongs to the rows.
class FluentList<T extends Object> extends StatefulWidget {
  /// Creates a list.
  const FluentList({
    super.key,
    required this.items,
    this.selectedValues = const <Never>{},
    this.onSelectionChange,
    this.selection = FluentListSelection.none,
    this.size = FluentListItemSize.medium,
    this.style,
    this.semanticLabel,
  });

  /// The rows, in reading order.
  final List<FluentListItem<T>> items;

  /// The values currently selected.
  ///
  /// Always a set, even in [FluentListSelection.radio] mode, where it holds at
  /// most one value — so a caller can switch modes without changing its state
  /// shape.
  final Set<T> selectedValues;

  /// Invoked with the whole new selection. Null makes every row inert.
  final ValueChanged<Set<T>>? onSelectionChange;

  /// Which affordance each row draws, and therefore whether selecting is
  /// additive.
  final FluentListSelection selection;

  /// Row height and title type ramp for every row.
  final FluentListItemSize size;

  /// Overrides layered over the theme defaults for every row. A row's own
  /// `style` is merged after this one.
  final FluentListItemStyle? style;

  /// Announced by assistive technology as the name of the list.
  final String? semanticLabel;

  @override
  State<FluentList<T>> createState() => _FluentListState<T>();
}

class _FluentListState<T extends Object> extends State<FluentList<T>> {
  final Map<Object, FocusNode> _focusNodes = <Object, FocusNode>{};

  /// The row focus last reached. Only a *preference*: [_tabStop] is what
  /// actually holds the stop, and it re-parks whenever this row has gone away
  /// or been disabled.
  Object? _roving;

  @override
  void didUpdateWidget(FluentList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final live = <Object>{for (final item in widget.items) item.value};
    for (final value in _focusNodes.keys.toList()) {
      if (!live.contains(value)) _focusNodes.remove(value)!.dispose();
    }
    // Disabling or removing the row that held the stop moves it, and the row
    // that gains it has to be un-latched once the frame that reopens its gate
    // has been built. See [_unlatch].
    _scheduleUnlatch();
  }

  @override
  void dispose() {
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  FocusNode _focusNodeFor(Object value) => _focusNodes.putIfAbsent(
    value,
    () => FocusNode(debugLabel: 'FluentListItem'),
  );

  /// The value of the row that owns the list's single tab stop.
  ///
  /// [_roving] when that row is still there and still live, and the first live
  /// row otherwise. That fallback is not a nicety: without it a list opening on
  /// a disabled first row would have zero tab stops, and disabling the row
  /// holding the stop would strand the whole control outside the Tab order.
  Object? get _tabStop {
    // A list with no callback has no live row, and a control nobody can operate
    // is not a tab stop.
    if (widget.onSelectionChange == null) return null;
    for (final item in widget.items) {
      if (item.enabled && item.value == _roving) return item.value;
    }
    for (final item in widget.items) {
      if (item.enabled) return item.value;
    }
    return null;
  }

  /// Keeps the roving index on whichever row the *keyboard* actually reached,
  /// so an arrow press and a Tab round trip agree on where the list is. A tap
  /// does not move it: [_toggle] never requests focus — unlike
  /// `_FluentTabListState._select`, which does — so a pointer selection leaves
  /// the keyboard's place where it was.
  void _rowFocused(Object value, {required bool hasFocus}) {
    if (!hasFocus || !mounted || value == _roving) return;
    setState(() => _roving = value);
    _scheduleUnlatch();
  }

  void _scheduleUnlatch() =>
      WidgetsBinding.instance.addPostFrameCallback((_) => _unlatch());

  /// Clears the `skipTraversal` the row holding the stop latched onto its own
  /// node while its gate was shut.
  ///
  /// `Focus.skipTraversal` falls back to `focusNode.skipTraversal` when the
  /// widget passes none — and *that* getter is derived
  /// (`focus_manager.dart:489`): it reports true while any ancestor has
  /// `descendantsAreTraversable: false`. A row is built on
  /// `FocusableActionDetector`, which passes none, so any rebuild under a shut
  /// gate writes the derived true back onto the row's own node as a hard flag
  /// (`focus_scope.dart:663`) and the row then stays out of the Tab order for
  /// good, gate or no gate. One assignment per move undoes it, and the row's
  /// next build writes the cleared value straight back, so it sticks.
  /// `_FluentNavState._unlatch` and `_FluentToolbarState._unlatch` are the same
  /// fix for the same framework behaviour.
  void _unlatch() {
    if (!mounted) return;
    final stop = _tabStop;
    if (stop != null) _focusNodes[stop]?.skipTraversal = false;
  }

  void _toggle(T value) {
    final callback = widget.onSelectionChange;
    if (callback == null) return;
    // Radio is single-select and cannot be un-selected by re-activating, which
    // is the Fluent radio rule; checkbox and the affordance-less list are both
    // additive toggles.
    if (widget.selection == FluentListSelection.radio) {
      callback(<T>{value});
      return;
    }
    final next = <T>{...widget.selectedValues};
    if (!next.remove(value)) next.add(value);
    callback(next);
  }

  /// The index of the row that currently holds focus, or -1.
  int get _focusedIndex => widget.items.indexWhere(
    (item) => _focusNodes[item.value]?.hasFocus ?? false,
  );

  void _move(int delta) {
    final items = widget.items;
    var index = _focusedIndex;
    // With nothing focused, an arrow enters the list from the near end.
    if (index < 0) index = delta > 0 ? -1 : items.length;
    for (
      var next = index + delta;
      next >= 0 && next < items.length;
      next += delta
    ) {
      if (items[next].enabled) {
        _focusNodeFor(items[next].value).requestFocus();
        return;
      }
    }
  }

  void _edge({required bool last}) {
    for (final item in last ? widget.items.reversed : widget.items) {
      if (item.enabled) {
        _focusNodeFor(item.value).requestFocus();
        return;
      }
    }
  }

  static const Map<ShortcutActivator, Intent>
  _shortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.arrowUp): FluentListMoveIntent(-1),
    SingleActivator(LogicalKeyboardKey.arrowDown): FluentListMoveIntent(1),
    SingleActivator(LogicalKeyboardKey.home): FluentListEdgeIntent(last: false),
    SingleActivator(LogicalKeyboardKey.end): FluentListEdgeIntent(last: true),
  };

  @override
  Widget build(BuildContext context) {
    final stop = _tabStop;
    return Shortcuts(
      shortcuts: _shortcuts,
      // Deliberately outside any FocusScope: an Actions that sits *inside* one
      // never sees an intent raised by a sibling scope, and Escape and the
      // arrows then silently do nothing.
      child: Actions(
        actions: <Type, Action<Intent>>{
          FluentListMoveIntent: CallbackAction<FluentListMoveIntent>(
            onInvoke: (intent) {
              _move(intent.delta);
              return null;
            },
          ),
          FluentListEdgeIntent: CallbackAction<FluentListEdgeIntent>(
            onInvoke: (intent) {
              _edge(last: intent.last);
              return null;
            },
          ),
        },
        child: _FluentListScope(
          size: widget.size,
          selection: widget.selection,
          selectedValues: widget.selectedValues,
          onToggle: widget.onSelectionChange == null
              ? null
              : (value) => _toggle(value as T),
          listStyle: widget.style,
          focusNodeFor: _focusNodeFor,
          child: Semantics(
            role: SemanticsRole.list,
            container: true,
            explicitChildNodes: true,
            label: widget.semanticLabel,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final item in widget.items)
                  // One traversable subtree at a time — that is what a roving
                  // tabindex *is*. A handle, not a stop: it never takes focus
                  // itself, and it gates only *traversal*, so the arrows' own
                  // requestFocus still reaches a row whose gate is shut.
                  // Semantics are left off it for the same reason — it is not a
                  // control, and `explicitChildNodes` above would otherwise
                  // wrap every row in a second, empty node.
                  Focus(
                    canRequestFocus: false,
                    skipTraversal: true,
                    descendantsAreTraversable: item.value == stop,
                    includeSemantics: false,
                    onFocusChange: (value) =>
                        _rowFocused(item.value, hasFocus: value),
                    child: item,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
