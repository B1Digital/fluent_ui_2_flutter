import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

import '../internal/animated_style.dart';
import '../internal/interaction.dart';
import '../surfaces/divider.dart';
import 'nav_style.dart';

/// Row height and density. Figma ships this as two component sets rather than a
/// variant axis — `NavNode - medium` and `NavNode - small`.
enum FluentNavSize {
  /// 40 high rows, 48 high app item. The default.
  medium,

  /// 32 high rows, 40 high app item.
  small,
}

/// Which of the four Figma component sets a row is rendered from.
///
/// Every kind is the same two boxes — an outer frame holding the selection
/// indicator, and an inner `Button` frame holding the fill — so they share one
/// style and one builder, and differ only in the geometry table inside
/// [resolveFluentNavItemStyle].
enum FluentNavItemKind {
  /// `App item - medium` / `- small`: the product header at the top of the nav.
  /// Has no selection indicator and its own larger type ramp.
  appItem,

  /// `NavNode - *`, `Group=True`: a collapsible group header with a chevron.
  category,

  /// `NavNode - *`, `Group=False`: a leaf destination.
  item,

  /// `NavSubItem`: a leaf destination inside a category, indented to align its
  /// label with the category label above it.
  subItem,
}

/// The nav row surface fade.
///
/// `sharedNavStyles.styles.ts` `useRootDefaultClassName` declares
/// `transition-property: background`, `transition-duration: durationFaster`,
/// `transition-timing-function: curveLinear`. The curve is the reason this is
/// not [FluentMotionSpec.buttonSurface]: a Fluent button eases its hover fill,
/// a nav row does not.
const FluentMotionSpec fluentNavSurfaceMotion = FluentMotionSpec(
  duration: FluentDuration.faster,
  curve: FluentCurve.linear,
);

/// The category chevron rotating between collapsed and expanded.
///
/// `useNavCategoryItem.tsx` builds it with
/// `createPresenceComponentVariant(Rotate, { duration: motionTokens.durationFast,
/// easing: motionTokens.curveEasyEase, animateOpacity: false, outAngle: 0,
/// inAngle: 180 })` — 150ms, symmetric easing, half a turn, and explicitly no
/// opacity change. Different from [FluentMotionSpec.accordionChevron], which is
/// 200ms on a decelerating curve over a quarter turn.
const FluentMotionSpec fluentNavExpandIconMotion = FluentMotionSpec(
  duration: FluentDuration.fast,
  curve: FluentCurve.easyEase,
);

/// Requests that the focused category open.
///
/// Bound to `Right` in a left-to-right nav and `Left` in a right-to-left one.
class FluentNavExpandIntent extends Intent {
  /// Creates the intent.
  const FluentNavExpandIntent();
}

/// Requests that the focused category close.
///
/// Bound to `Left` in a left-to-right nav and `Right` in a right-to-left one.
class FluentNavCollapseIntent extends Intent {
  /// Creates the intent.
  const FluentNavCollapseIntent();
}

/// Requests that focus move [delta] rows through the nav.
///
/// Bound to `Up` and `Down`. Wrapping at both ends, because
/// `useNavDrawerBody.ts` configures its arrow navigation group with
/// `circular: true`.
class FluentNavMoveIntent extends Intent {
  /// Creates a move intent.
  const FluentNavMoveIntent(this.delta);

  /// How many rows to move, and in which direction. Negative is upward.
  final int delta;
}

/// Requests that focus move to the first or last row of the nav.
///
/// Bound to `Home` and `End`. Absolute, never wrapping — tabster does not
/// consult its cyclic flag on these two.
class FluentNavEdgeIntent extends Intent {
  /// Creates an edge intent.
  const FluentNavEdgeIntent({required this.last});

  /// Whether to move to the last row rather than the first.
  final bool last;
}

/// Everything needed to render one nav row, independent of kind and size.
///
/// The counterpart of `FluentButtonBaseState`. [buildFluentNavItem] takes this
/// rather than [FluentNavItemState], which is what makes "Fluent's state, my own
/// styling, Fluent's rendering" a supported path rather than a fork.
@immutable
class FluentNavItemBaseState {
  /// Creates a base state.
  const FluentNavItemBaseState({
    required this.enabled,
    required this.selected,
    required this.expanded,
    required this.expandable,
    required this.showIndicator,
    this.icon,
    this.selectedIcon,
    this.label,
    this.secondaryActions = const <Widget>[],
  });

  /// Whether the row responds to input.
  final bool enabled;

  /// Whether this row is the current destination. Figma's `Selected` axis.
  final bool selected;

  /// Whether the category below this header is open. Figma's `Open` axis.
  /// Always false for a row that cannot expand.
  final bool expanded;

  /// Whether this row carries a chevron and can be opened at all.
  final bool expandable;

  /// Whether the row reserves the leading selection-indicator column. False
  /// only for [FluentNavItemKind.appItem], which has no indicator in Figma.
  final bool showIndicator;

  /// Leading icon, if any.
  final Widget? icon;

  /// The icon to show while [selected], if any. Null leaves [icon] in place in
  /// every state, which is what every caller written before this slot existed
  /// gets. See [FluentNavItem.selectedIcon] for why this is a slot rather than
  /// something derived from [icon].
  final Widget? selectedIcon;

  /// The label, if any.
  final Widget? label;

  /// Trailing controls. Figma's `Secondary actions` axis; each is expected to
  /// be a 24-high icon button.
  final List<Widget> secondaryActions;
}

/// A nav row's fully resolved state, including the design axes.
///
/// The counterpart of `FluentButtonState`: base state plus exactly `kind` and
/// `size`.
@immutable
class FluentNavItemState extends FluentNavItemBaseState {
  /// Creates a resolved state.
  const FluentNavItemState({
    required super.enabled,
    required super.selected,
    required super.expanded,
    required super.expandable,
    required super.showIndicator,
    required this.kind,
    required this.size,
    super.icon,
    super.selectedIcon,
    super.label,
    super.secondaryActions,
  });

  /// Which component set this row is rendered from.
  final FluentNavItemKind kind;

  /// Row height and density.
  final FluentNavSize size;
}

/// Builds the state a nav row will be styled and rendered from.
///
/// Separated so a consumer can reuse Fluent's state resolution while
/// substituting their own styling — the first of the three-function
/// recomposition contract.
FluentNavItemState resolveFluentNavItemState({
  required FluentNavItemKind kind,
  bool enabled = true,
  bool selected = false,
  bool expanded = false,
  bool expandable = false,
  FluentNavSize size = FluentNavSize.medium,
  Widget? icon,
  Widget? selectedIcon,
  Widget? label,
  List<Widget> secondaryActions = const <Widget>[],
}) => FluentNavItemState(
  kind: kind,
  size: size,
  enabled: enabled,
  selected: selected,
  expanded: expandable && expanded,
  expandable: expandable,
  showIndicator: kind != FluentNavItemKind.appItem,
  icon: icon,
  selectedIcon: selectedIcon,
  label: label,
  secondaryActions: secondaryActions,
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes. Every colour is an explicitly named Fluent
/// token; nothing here computes one.
///
/// ## Where the numbers come from
///
/// The Figma `Nav` page (`8995:5`), pinned in `test/fixtures/nav_node.json`,
/// `nav_node_small.json`, `nav_sub_item.json`, `nav_app_item.json` and
/// `nav_app_item_small.json`.
///
/// * outer frame `Spacing/Horizontal/XS` (4) each side, indicator column 4 wide
///   with a `Spacing/Horizontal/XXS` (2) gap — reserved on every row so the
///   label does not shift when selection moves
/// * `Button` fill `Neutral/Background/4/{Rest,Hover,Pressed}`, radius
///   `Corner radius/Medium` (4), gap `Spacing/Horizontal/L` (16)
/// * label `Neutral/Foreground/1/*` semibold when selected,
///   `Neutral/Foreground/2/*` regular otherwise, both on the `body1` ramp
///   (14/20); the app item is `subtitle2` (16/22 semibold) in every state
/// * selection indicator `Brand/Foreground/Compound/Rest`, 4x20, radius 2
///
/// Where `microsoft/fluentui@master` disagrees, Figma used to win. That is now
/// reversed **for row height, and for row height only**: `@fluentui/react-nav`
/// 9.4.3 is the authority on the four `height` values in the geometry table
/// below. The reversal is deliberate and was made by the consuming app's owner,
/// who chose React as the single source of truth so the design system has one
/// authority to point at instead of two that quietly disagree.
///
/// The scope stops there. Padding, gaps, the sub-item indent, icon sizes, the
/// selection indicator, the type ramp and every colour token on this page are
/// still Figma's, and where React disagrees with them both readings stay called
/// out at the disagreement — see the surface motion curve, the small-density
/// padding and the leaf's trailing inset.
FluentNavItemStyle resolveFluentNavItemStyle(
  FluentNavItemState state,
  FluentThemeData theme,
) {
  final c = theme.colors;

  // Selection never changes the fill in Figma — every Selected=True variant
  // carries the same `Neutral/Background/4/*` token as its Selected=False
  // sibling — so `selected` is spelled out as equal to `rest` rather than
  // omitted, which would read as "not looked at".
  final background = FluentStateColor.tokens(
    rest: c.neutralBackground4,
    hover: c.neutralBackground4Hover,
    pressed: c.neutralBackground4Pressed,
    selected: c.neutralBackground4,
    disabled: c.neutralBackgroundDisabled,
  );

  // Selection swaps the whole token FAMILY rather than picking the Selected
  // member of one, which is why this branches on `state.selected` instead of
  // passing a `selected:` token. Figma models Selected as a variant axis for
  // exactly that reason.
  // The app item is on the strong family too — Figma binds
  // `Neutral/Foreground/1/*` on all three of its variants — even though it is
  // never "selected".
  final foreground = state.selected || state.kind == FluentNavItemKind.appItem
      ? FluentStateColor.tokens(
          rest: c.neutralForeground1,
          hover: c.neutralForeground1Hover,
          pressed: c.neutralForeground1Pressed,
          disabled: c.neutralForegroundDisabled,
        )
      : FluentStateColor.tokens(
          rest: c.neutralForeground2,
          hover: c.neutralForeground2Hover,
          pressed: c.neutralForeground2Pressed,
          disabled: c.neutralForegroundDisabled,
        );

  // A selected row paints its icon with the compound brand token while its
  // label stays neutral — Figma binds `Brand/Foreground/Compound/Rest` on the
  // icon vector of every Selected=True variant, in all three interaction
  // states. The app item is never selected and follows its label.
  final iconColor = state.selected && state.kind != FluentNavItemKind.appItem
      ? FluentStateColor.tokens(
          rest: c.compoundBrandForeground1,
          disabled: c.neutralForegroundDisabled,
        )
      : foreground;

  final appItem = state.kind == FluentNavItemKind.appItem;
  final small = state.size == FluentNavSize.small;

  // The geometry table. `padding`, `gap` and `iconSize` are verbatim from the
  // five Figma fixtures; `height` is React's, per the reversal documented
  // above. `padding` is the inner `Button` frame's; the vertical half only
  // matters for a row whose content is taller than the height, because the row
  // is centred inside `minimumSize`.
  //
  // React ships no `height` declaration anywhere in `@fluentui/react-nav`
  // 9.4.3 — every number below is what its padding plus `lineHeightBase300`
  // (20) resolves to, which is why they are literals here and not tokens:
  // 20 + 2x4 = 28 at small, 20 + 2x6 = 32 at medium. Figma's own 32/40 were 8
  // taller at every step.
  final (padding, gap, height, iconSize) = switch (state.kind) {
    // `useAppItemStyles.styles.ts` gives the app item one padding rule with no
    // density branch, so React renders it 38 high at BOTH sizes — the only row
    // whose height does not move with `state.size`. Figma drew 40/48.
    FluentNavItemKind.appItem when small => (
      const EdgeInsets.fromLTRB(
        FluentSpacing.mNudge + FluentSpacing.xs,
        FluentSpacing.s,
        FluentSpacing.sNudge,
        FluentSpacing.s,
      ),
      FluentSpacing.mNudge,
      38.0,
      FluentSize.size240,
    ),
    FluentNavItemKind.appItem => (
      const EdgeInsets.symmetric(
        horizontal: FluentSpacing.mNudge,
        vertical: FluentSpacing.s,
      ),
      FluentSpacing.s,
      38.0,
      FluentSize.size320,
    ),
    // `useNavCategoryItemStyles.styles.ts` — same padding rule as the leaf, so
    // the same 28/32. Figma drew 32/40.
    FluentNavItemKind.category => (
      EdgeInsets.fromLTRB(
        FluentSpacing.mNudge,
        small ? FluentSpacing.sNudge : FluentSpacing.mNudge,
        FluentSpacing.s,
        small ? FluentSpacing.sNudge : FluentSpacing.mNudge,
      ),
      FluentSpacing.l,
      small ? 28.0 : 32.0,
      FluentSize.size200,
    ),
    // `useNavItemStyles.styles.ts`. Figma drew 32/40.
    FluentNavItemKind.item => (
      const EdgeInsets.fromLTRB(
        FluentSpacing.mNudge,
        FluentSpacing.none,
        FluentSpacing.sNudge,
        FluentSpacing.none,
      ),
      FluentSpacing.l,
      small ? 28.0 : 32.0,
      FluentSize.size200,
    ),
    // The 46 is not a token: Figma writes it as a literal, and it is exactly
    // `paddingLeft` (10) + icon (20) + gap (16) of the row above, so a sub-item
    // label lines up with its category label rather than with its icon.
    //
    // Do NOT "fix" the 46 to React's `smallBase` (40) to match the height
    // reversal — that token is overridden downstream and
    // `useNavSubItemStyles.styles.ts` renders 46 at both densities too, so
    // changing it would INTRODUCE a 6px misalignment against both authorities
    // at once. Height is the only thing React won here.
    //
    // `useNavSubItemStyles.styles.ts` also branches on density, which this arm
    // did not: it was a flat 32 with no `small` case, so the small nav drew its
    // sub-items 4 taller than its leaves. Both authorities say it should track.
    FluentNavItemKind.subItem => (
      const EdgeInsets.fromLTRB(
        46,
        FluentSpacing.none,
        FluentSpacing.sNudge,
        FluentSpacing.none,
      ),
      FluentSpacing.l,
      small ? 28.0 : 32.0,
      FluentSize.size200,
    ),
  };

  final textStyle = appItem
      ? theme.typography.subtitle2
      : (state.selected
            ? theme.typography.body1Strong
            : theme.typography.body1);

  return FluentNavItemStyle(
    backgroundColor: background,
    foregroundColor: foreground,
    iconColor: iconColor,
    indicatorColor: FluentStateColor.tokens(
      rest: c.compoundBrandForeground1,
      disabled: c.neutralForegroundDisabled,
    ),
    textStyle: WidgetStatePropertyAll<TextStyle?>(textStyle),
    borderRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allMedium,
    ),
    indicatorRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allSmall,
    ),
    padding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(padding),
    outerPadding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      appItem
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: FluentSpacing.xs),
    ),
    gap: WidgetStatePropertyAll<double?>(gap),
    indicatorGap: const WidgetStatePropertyAll<double?>(FluentSpacing.xxs),
    indicatorSize: const WidgetStatePropertyAll<Size?>(
      Size(FluentSize.size40, FluentSize.size200),
    ),
    iconSize: WidgetStatePropertyAll<double?>(iconSize),
    minimumSize: WidgetStatePropertyAll<Size?>(Size(0, height)),
    mouseCursor: const WidgetStatePropertyAll<MouseCursor?>(
      SystemMouseCursors.click,
    ),
  );
}

/// Renders a nav row from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentNavItemBaseState] rather than [FluentNavItemState] on purpose: it
/// never reads kind or size, so a consumer can supply their own style and still
/// use Fluent's rendering, focus ring and transitions.
///
/// [states] is the live interaction set from [FluentInteractive]. The surface
/// fill animates on [fluentNavSurfaceMotion] and the chevron rotates on
/// [fluentNavExpandIconMotion]; nothing else here transitions, because upstream
/// declares nothing else.
Widget buildFluentNavItem(
  FluentNavItemBaseState state,
  FluentNavItemStyle style,
  Set<WidgetState> states,
) {
  final radius = style.borderRadius?.resolve(states) ?? FluentRadius.allMedium;
  final foreground = style.foregroundColor?.resolve(states);
  final iconColor = style.iconColor?.resolve(states) ?? foreground;
  final padding = style.padding?.resolve(states) ?? EdgeInsets.zero;
  final outerPadding = style.outerPadding?.resolve(states) ?? EdgeInsets.zero;
  final gap = style.gap?.resolve(states) ?? FluentSpacing.l;
  final iconSize = style.iconSize?.resolve(states) ?? FluentSize.size200;
  final minimumSize = style.minimumSize?.resolve(states) ?? Size.zero;
  final textStyle = style.textStyle?.resolve(states);

  // Selection is read off the state rather than off [states] so the two
  // selection signals agree everywhere: the indicator below already reads
  // `state.selected`, and the static app-item path — a row with nothing to
  // invoke — builds with an empty interaction set, which carries no
  // `WidgetState.selected` to read.
  final selectedIcon = state.selectedIcon;
  final iconSlot = selectedIcon == null
      ? state.icon
      : _FluentNavIcon(
          // A `selectedIcon` with no `icon` is a caller error rather than a
          // state worth rendering, but the empty box keeps the crossfade
          // total instead of dropping the widget on the floor.
          icon: state.icon ?? const SizedBox.shrink(),
          selectedIcon: selectedIcon,
          selected: state.selected,
        );

  final children = <Widget>[
    if (iconSlot != null)
      IconTheme.merge(
        data: IconThemeData(color: iconColor, size: iconSize),
        child: iconSlot,
      ),
    Expanded(child: state.label ?? const SizedBox.shrink()),
    if (state.expandable)
      _FluentNavChevron(
        expanded: state.expanded,
        size: iconSize,
        color: iconColor,
      ),
    if (state.secondaryActions.isNotEmpty)
      IconTheme.merge(
        data: IconThemeData(color: foreground),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: state.secondaryActions,
        ),
      ),
  ];

  Widget content = Row(spacing: gap, children: children);

  if (textStyle != null || foreground != null) {
    content = DefaultTextStyle.merge(
      style: (textStyle ?? const TextStyle()).copyWith(color: foreground),
      child: content,
    );
  }

  // Hoisted out of the animation builder: nothing under here depends on the
  // tweened fill, so an identical instance short-circuits its own rebuild on
  // every frame of the transition.
  final body = ConstrainedBox(
    constraints: BoxConstraints(
      minHeight: minimumSize.height,
      minWidth: minimumSize.width,
    ),
    child: Padding(padding: padding, child: content),
  );

  // A nav row's ring is drawn INSIDE its own box, which is why this is a
  // foreground border rather than a `FluentFocusRing`: that widget paints its
  // 2px band outside the child. `sharedNavStyles.styles.ts`,
  // `useRootDefaultClassName`: `'&:focus-visible': { outline: strokeWidthThick
  // solid colorStrokeFocus2, outlineOffset: calc(strokeWidthThick * -1) }` —
  // the band occupies −2…0 on the row's own `borderRadiusMedium`, so it never
  // spills into the 2px gap between rows the way an outward ring would.
  final focusRing = states.contains(WidgetState.focused);

  Widget surface = FluentAnimatedStyle<Color>(
    value: style.backgroundColor?.resolve(states) ?? const Color(0x00000000),
    spec: fluentNavSurfaceMotion,
    lerp: fluentLerpColor,
    builder: (context, background) {
      final filled = DecoratedBox(
        decoration: BoxDecoration(color: background, borderRadius: radius),
        child: body,
      );
      if (!focusRing) return filled;
      return DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(
            color: FluentTheme.of(context).colors.strokeFocus2,
            width: FluentStroke.thick,
          ),
        ),
        child: filled,
      );
    },
  );

  if (state.showIndicator) {
    final indicatorSize =
        style.indicatorSize?.resolve(states) ??
        const Size(FluentSize.size40, FluentSize.size200);
    final indicatorColor = style.indicatorColor?.resolve(states);
    surface = Row(
      spacing: style.indicatorGap?.resolve(states) ?? FluentSpacing.xxs,
      children: <Widget>[
        SizedBox(
          width: indicatorSize.width,
          height: indicatorSize.height,
          // Upstream ramps `background: transparent ->
          // compoundBrandForeground1` over `navItemTokens.animationTokens` —
          // 100ms linear, which `fluentNavSurfaceMotion` already carries. The
          // bar does NOT travel between rows: React's indicator is a per-item
          // `::after` with no transform, so there is nothing to slide.
          //
          // The column is reserved whether or not it paints, so moving the
          // selection does not shift every label sideways. `withAlpha(0)` is
          // the keyframe's `transparent` endpoint, not a Fluent transparent
          // token — those turn opaque in high contrast, a literal zero alpha
          // does not — and `fluentLerpColor` moves alpha only when one end is
          // fully transparent, so the bar fades up without dragging through a
          // darker blue.
          child: indicatorColor == null
              ? null
              : FluentAnimatedStyle<Color>(
                  value: state.selected
                      ? indicatorColor
                      : indicatorColor.withAlpha(0),
                  spec: fluentNavSurfaceMotion,
                  lerp: fluentLerpColor,
                  builder: (context, color) => DecoratedBox(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius:
                          style.indicatorRadius?.resolve(states) ??
                          FluentRadius.allSmall,
                    ),
                  ),
                ),
        ),
        Expanded(child: surface),
      ],
    );
  }

  return Padding(padding: outerPadding, child: surface);
}

/// The regular-to-filled icon crossfade.
///
/// `useIconStyles` in `navItemStyles.styles.ts` gives the icon slot
/// `transitionProperty: opacity` over `durationFaster`, and React swaps the
/// glyph by swapping one class on one element — the filled variant is the same
/// node redrawn. Flutter's icon set ships regular and filled as two separate
/// `IconData`, so there is no class to swap and the second glyph has to be a
/// second widget. Two stacked opacities is the same fade with the same
/// endpoints.
///
/// The spec is [fluentNavSurfaceMotion] rather than a second constant: it is
/// already the nav's `durationFaster`, and upstream's icon transition names no
/// curve of its own to transcribe.
class _FluentNavIcon extends StatelessWidget {
  const _FluentNavIcon({
    required this.icon,
    required this.selectedIcon,
    required this.selected,
  });

  final Widget icon;
  final Widget selectedIcon;
  final bool selected;

  @override
  Widget build(BuildContext context) => FluentAnimatedStyle<double>(
    value: selected ? 1 : 0,
    spec: fluentNavSurfaceMotion,
    lerp: lerpDouble,
    // Reduced motion is [FluentAnimatedStyle]'s job, so this lands on the
    // target opacity in one frame with nothing extra here.
    builder: (context, t) => Stack(
      alignment: AlignmentDirectional.center,
      children: <Widget>[
        // `Opacity(0)` stops painting but keeps its semantics node, so an icon
        // carrying a `semanticLabel` would otherwise be announced twice —
        // once by each glyph — for as long as the row is mounted.
        ExcludeSemantics(
          excluding: t == 1,
          child: Opacity(opacity: 1 - t, child: icon),
        ),
        ExcludeSemantics(
          excluding: t == 0,
          child: Opacity(opacity: t, child: selectedIcon),
        ),
      ],
    ),
  );
}

/// The rotating category chevron.
///
/// `ChevronDown20Regular` under a rotation, exactly as upstream does it: the
/// glyph never changes, only its angle, from 0 collapsed to half a turn open.
class _FluentNavChevron extends StatelessWidget {
  const _FluentNavChevron({
    required this.expanded,
    required this.size,
    required this.color,
  });

  final bool expanded;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    // Hoisted: the glyph does not depend on the angle.
    final icon = IconTheme.merge(
      data: IconThemeData(color: color, size: size),
      child: const Icon(FluentIcons.chevron_down_20_regular),
    );
    return FluentAnimatedStyle<double>(
      value: expanded ? 0.5 : 0,
      spec: fluentNavExpandIconMotion,
      lerp: lerpDouble,
      builder: (context, turns) =>
          Transform.rotate(angle: turns * 2 * math.pi, child: icon),
    );
  }
}

/// The collapsing sub-item group.
///
/// `useNavSubItemGroup.ts` wraps the group in `Collapse` from
/// `@fluentui/react-motion-components-preview` with `unmountOnExit: true`, whose
/// defaults are `durationNormal` (200ms) on `curveEasyEaseMax` animating height
/// and opacity together. All of that is reproduced here:
/// [FluentMotionSpec.collapse] is that duration and curve, the collapsed child
/// is not built at all, and reduced motion is handled by [FluentAnimatedStyle].
class _FluentNavGroup extends StatelessWidget {
  const _FluentNavGroup({required this.expanded, required this.child});

  final bool expanded;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // The `Spacing/Vertical/XXS` gap between the header and the group lives
    // here rather than on the parent Column: as Column `spacing` it would also
    // apply while the group is collapsed, and a closed category is exactly 40
    // high in Figma, not 42.
    final content = Padding(
      padding: const EdgeInsets.only(top: FluentSpacing.xxs),
      child: SizedBox(width: double.infinity, child: child),
    );
    return FluentAnimatedStyle<double>(
      value: expanded ? 1 : 0,
      spec: FluentMotionSpec.collapse,
      lerp: lerpDouble,
      builder: (context, value) => value <= 0
          ? const SizedBox.shrink()
          : ClipRect(
              child: Align(
                alignment: AlignmentDirectional.topStart,
                heightFactor: value.clamp(0, 1),
                child: Opacity(opacity: value.clamp(0, 1), child: content),
              ),
            ),
    );
  }
}

/// Overrides the nav row style for a subtree.
///
/// The middle rungs of the resolution order: theme defaults, then [style], then
/// the slot matching the row's own [FluentNavItemKind], then the widget's own
/// `style`. Placing this above a [FluentNav] restyles every row in it.
///
/// The kind slots exist because React styles the four sets through separate
/// hooks — `useNavItemStyles`, `useNavCategoryItemStyles`,
/// `useNavSubItemStyles` — so a consumer can restyle one without touching the
/// others. Without them, "make categories read differently from their children"
/// means passing `style:` to every widget by hand.
///
/// ```dart
/// FluentNavItemTheme(
///   style: everyRow,
///   categoryStyle: headersOnly,
///   child: FluentNav(children: <Widget>[…]),
/// )
/// ```
class FluentNavItemTheme extends InheritedTheme {
  /// Applies [style] and the kind slots to every nav row in [child].
  const FluentNavItemTheme({
    super.key,
    this.style,
    this.appItemStyle,
    this.categoryStyle,
    this.itemStyle,
    this.subItemStyle,
    required super.child,
  });

  /// The style layered over every kind's defaults.
  final FluentNavItemStyle? style;

  /// Layered over [style] for [FluentNavItemKind.appItem] rows.
  final FluentNavItemStyle? appItemStyle;

  /// Layered over [style] for [FluentNavItemKind.category] rows.
  final FluentNavItemStyle? categoryStyle;

  /// Layered over [style] for [FluentNavItemKind.item] rows.
  final FluentNavItemStyle? itemStyle;

  /// Layered over [style] for [FluentNavItemKind.subItem] rows.
  final FluentNavItemStyle? subItemStyle;

  FluentNavItemStyle? _forKind(FluentNavItemKind kind) {
    final slot = switch (kind) {
      FluentNavItemKind.appItem => appItemStyle,
      FluentNavItemKind.category => categoryStyle,
      FluentNavItemKind.item => itemStyle,
      FluentNavItemKind.subItem => subItemStyle,
    };
    if (slot == null) return style;
    // Per-property, so a slot that overrides only the fill keeps everything
    // else the catch-all resolved.
    return style?.merge(slot) ?? slot;
  }

  /// The nearest catch-all nav row style, or null.
  ///
  /// Deliberately unchanged in both signature and meaning: it returns [style]
  /// and ignores the kind slots, so no existing caller breaks. Use
  /// [maybeOfKind] for the full resolution.
  static FluentNavItemStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentNavItemTheme>()?.style;

  /// The nearest nav row style for [kind] — [style] with the matching slot
  /// layered over it — or null.
  static FluentNavItemStyle? maybeOfKind(
    BuildContext context,
    FluentNavItemKind kind,
  ) => context
      .dependOnInheritedWidgetOfExactType<FluentNavItemTheme>()
      ?._forKind(kind);

  @override
  bool updateShouldNotify(FluentNavItemTheme oldWidget) =>
      style != oldWidget.style ||
      appItemStyle != oldWidget.appItemStyle ||
      categoryStyle != oldWidget.categoryStyle ||
      itemStyle != oldWidget.itemStyle ||
      subItemStyle != oldWidget.subItemStyle;

  @override
  Widget wrap(BuildContext context, Widget child) => FluentNavItemTheme(
    style: style,
    appItemStyle: appItemStyle,
    categoryStyle: categoryStyle,
    itemStyle: itemStyle,
    subItemStyle: subItemStyle,
    child: child,
  );
}

/// Carries density, selection, the open set and the roving focus model down to
/// every row.
class _FluentNavScope extends InheritedWidget {
  const _FluentNavScope({
    required this.size,
    required this.tabbable,
    required this.tabStop,
    required this.selectedValue,
    required this.openCategories,
    required this.requestSelect,
    required this.requestToggle,
    required this.register,
    required this.unregister,
    required this.rowFocused,
    required super.child,
  });

  final FluentNavSize size;
  final bool tabbable;

  /// The gate that currently owns the nav's single tab stop, or null before
  /// the focus tree has been walked for the first time.
  final FocusNode? tabStop;

  final Object? selectedValue;
  final Set<Object> openCategories;
  final void Function(Object value) requestSelect;
  final void Function(Object value, {bool? open}) requestToggle;
  final void Function(FocusNode gate) register;
  final void Function(FocusNode gate, {required bool hadFocus}) unregister;
  final void Function(FocusNode gate) rowFocused;

  static _FluentNavScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_FluentNavScope>();
    assert(
      scope != null,
      'Nav rows must be placed inside a FluentNav, which owns the density, the '
      'selected value and the open set.',
    );
    return scope!;
  }

  // The three callbacks are omitted on purpose: they are bound to
  // `_FluentNavState` and never change identity for a given nav.
  @override
  bool updateShouldNotify(_FluentNavScope oldWidget) =>
      size != oldWidget.size ||
      tabbable != oldWidget.tabbable ||
      tabStop != oldWidget.tabStop ||
      selectedValue != oldWidget.selectedValue ||
      !setEquals(openCategories, oldWidget.openCategories) ||
      requestSelect != oldWidget.requestSelect ||
      requestToggle != oldWidget.requestToggle;
}

/// A Fluent 2 side navigation.
///
/// ```dart
/// FluentNav(
///   defaultSelectedValue: 'home',
///   children: const <Widget>[
///     FluentNavAppItem(icon: Icon(FluentIcons.person_circle_32_regular),
///         child: Text('Contoso')),
///     FluentNavDivider(),
///     FluentNavItem(value: 'home', icon: Icon(FluentIcons.home_20_regular),
///         child: Text('Home')),
///     FluentNavCategory(
///       value: 'reports',
///       child: Text('Reports'),
///       children: <Widget>[
///         FluentNavSubItem(value: 'weekly', child: Text('Weekly')),
///       ],
///     ),
///   ],
/// )
/// ```
///
/// Pass [selectedValue] and [openCategories] to own that state yourself; leave
/// them null and the nav keeps its own, seeded from [defaultSelectedValue] and
/// [defaultOpenCategories]. [onSelect] and [onOpenChange] report the value the
/// nav is moving to in both cases.
///
/// ## Keyboard
///
/// `Up` and `Down` move focus between rows, wrapping at both ends; `Home` and
/// `End` jump to the first and last row without wrapping; `Enter` and `Space`
/// activate the focused row. On a category header, `Right` opens and `Left`
/// closes, mirrored in a right-to-left nav — those two live on the header
/// rather than on the nav, so they never shadow anything elsewhere.
///
/// Unless [tabbable] is set, the whole nav is a single tab stop: Tab enters at
/// the row that last held focus and Tab again leaves. Rows that cannot take
/// focus — disabled ones, a static [FluentNavAppItem], a [FluentNavDivider],
/// a [FluentNavSectionHeader] — are skipped structurally rather than by
/// declaration.
///
/// This reproduces upstream's `useArrowNavigationGroup({ axis: 'vertical',
/// circular: true, tabbable })`, with three recorded divergences:
///
/// * Upstream installs that group on `NavDrawerBody`, not on `Nav`, so its bare
///   `Nav` has no arrow navigation at all. This widget carries it, because it
///   is the only nav container this package ships.
/// * `PageUp` and `PageDown` are not bound. Tabster implements them as a
///   viewport-visibility walk; a nav hugs its height and has no viewport.
/// * `secondaryActions` are reached by Tab within the focused row rather than
///   by `Down`. Upstream has no analogue — an HTML nav item cannot nest a
///   button — and making them arrow stops would tie the press count to how many
///   icon buttons a row happens to carry.
///
/// Tabster can enter a group at a row flagged as its default; whether Fluent
/// flags the selected item is unverified, so this widget enters at the first
/// reachable row.
///
/// The nav fills the width it is given and hugs its height. Fluent's own drawer
/// is 260 wide — see `FluentNavDrawer`.
class FluentNav extends StatefulWidget {
  /// Creates a nav over [children].
  const FluentNav({
    super.key,
    required this.children,
    this.size = FluentNavSize.medium,
    this.tabbable = false,
    this.selectedValue,
    this.defaultSelectedValue,
    this.onSelect,
    this.openCategories,
    this.defaultOpenCategories = const <Object>{},
    this.onOpenChange,
    this.semanticLabel,
  });

  /// The rows, in order.
  final List<Widget> children;

  /// Row height and density.
  final FluentNavSize size;

  /// Whether every row is a tab stop, rather than the nav being one.
  ///
  /// False — the default, and what `useNav.ts` hardcodes — makes the whole nav
  /// a single tab stop: Tab enters at the row that last had focus and Tab again
  /// leaves the nav. True restores a stop per row, matching upstream's
  /// `tabbable` prop: *"The component uses arrow navigation by default. Setting
  /// this to true enables tab AND arrow navigation."*
  ///
  /// The arrow keys and `Home`/`End` behave identically either way. Tabster
  /// reads this flag in exactly one place, and so does this widget.
  final bool tabbable;

  /// The selected row's value, when the caller owns it.
  final Object? selectedValue;

  /// The initially selected value while uncontrolled.
  final Object? defaultSelectedValue;

  /// Called with the value the nav is moving to, before it is applied.
  final ValueChanged<Object>? onSelect;

  /// The open category set, when the caller owns it.
  final Set<Object>? openCategories;

  /// The initially open categories while uncontrolled.
  final Set<Object> defaultOpenCategories;

  /// Called with the open set the nav is moving to, before it is applied.
  final ValueChanged<Set<Object>>? onOpenChange;

  /// Announced by assistive technology as the name of this navigation region.
  final String? semanticLabel;

  @override
  State<FluentNav> createState() => _FluentNavState();
}

class _FluentNavState extends State<FluentNav> {
  late Object? _uncontrolledSelected = widget.defaultSelectedValue;
  late Set<Object> _uncontrolledOpen = <Object>{
    ...widget.defaultOpenCategories,
  };

  /// The nav's own node, whose descendants are the gates. Never focusable
  /// itself — it is a handle for walking the focus tree in order.
  final FocusNode _nav = FocusNode(debugLabel: 'FluentNav');

  final Set<FocusNode> _gates = <FocusNode>{};

  /// The gate holding the nav's single tab stop. Null until the first
  /// post-frame settle, which is also the one frame in which every row stays
  /// traversable — see the gate expression in `_FluentNavRowState.build`.
  FocusNode? _tabStop;

  bool _settleScheduled = false;

  @override
  void dispose() {
    _nav.dispose();
    super.dispose();
  }

  /// The gates in focus-tree order. Derived live on every read rather than
  /// cached, so a collapsed category's sub-items drop out by themselves.
  Iterable<FocusNode> get _rows => _nav.descendants.where(_gates.contains);

  /// The row's own focusable node.
  ///
  /// Null for a static app item, which builds no `FluentInteractive` at all,
  /// and null for a disabled row, whose detector refuses focus — which is what
  /// makes both skippable without the nav having to be told which is which.
  FocusNode? _focusable(FocusNode gate) {
    for (final node in gate.descendants) {
      if (node.canRequestFocus) return node;
    }
    return null;
  }

  List<FocusNode> get _reachable => <FocusNode>[
    for (final gate in _rows)
      if (_focusable(gate) != null) gate,
  ];

  void _register(FocusNode gate) {
    _gates.add(gate);
    _scheduleSettle();
  }

  void _unregister(FocusNode gate, {required bool hadFocus}) {
    _gates.remove(gate);
    if (identical(gate, _tabStop)) _tabStop = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _settle();
      if (!hadFocus) return;
      // The row that held focus is gone, and there is no FocusScope inside the
      // nav to catch it — so without this, focus lands on the route's scope and
      // leaves the nav entirely. Wrapping the nav in a FocusScope is not the
      // alternative: `FocusTraversalPolicy.next` works within `nearestScope`,
      // so Tab from the last row would cycle back in rather than leaving.
      final stop = _tabStop;
      if (stop == null) return;
      final node = _focusable(stop);
      if (node != null) {
        FocusTraversalPolicy.defaultTraversalRequestFocusCallback(node);
      }
    });
  }

  /// Registration happens inside this widget's own build, so the tab stop can
  /// never be settled synchronously — `setState` on that path asserts.
  void _scheduleSettle() {
    if (_settleScheduled) return;
    _settleScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _settleScheduled = false;
      _settle();
    });
  }

  /// Parks the tab stop on a row that can actually receive it.
  ///
  /// Without this a nav opening with a divider, a section header or a disabled
  /// row would have zero tab stops instead of one.
  void _settle() {
    if (!mounted) return;
    final stop = _tabStop;
    if (stop == null || !_gates.contains(stop) || _focusable(stop) == null) {
      final rows = _reachable;
      final next = rows.isEmpty ? null : rows.first;
      if (next != stop) setState(() => _tabStop = next);
    }
    _unlatch();
  }

  /// Clears the `skipTraversal` the tab stop's own row latched onto its node
  /// while its gate was shut.
  ///
  /// `Focus.skipTraversal` falls back to `focusNode.skipTraversal` when the
  /// widget passes none — and *that* getter is derived: it reports true while
  /// any ancestor has `descendantsAreTraversable: false`. A row built on
  /// `FocusableActionDetector` passes none, so the first shut gate makes the
  /// row write the derived true back onto its own node as a hard flag, and the
  /// row then stays out of the Tab order for good, gate or no gate. One
  /// assignment per settle undoes it, and the row's next build writes the
  /// cleared value straight back, so it sticks.
  void _unlatch() {
    final stop = _tabStop;
    if (stop != null) _focusable(stop)?.skipTraversal = false;
  }

  /// Keeps the roving index on whichever row the user actually reached, so a
  /// click and an arrow press leave the nav in the same state.
  void _rowFocused(FocusNode gate) {
    if (!mounted || identical(gate, _tabStop)) return;
    setState(() => _tabStop = gate);
    _scheduleSettle();
  }

  void _move(int delta) {
    final rows = _reachable;
    if (rows.isEmpty) return;
    final current = _tabStop == null ? -1 : rows.indexOf(_tabStop!);
    // Dart's `%` is non-negative for a positive divisor, so one expression
    // covers both directions — this is `circular: true` from
    // `useNavDrawerBody.ts`, and the same modulo walk as FluentToolbar._seek.
    final next = current < 0
        ? (delta > 0 ? 0 : rows.length - 1)
        : (current + delta) % rows.length;
    _focusRow(rows[next]);
  }

  void _edge({required bool last}) {
    final rows = _reachable;
    if (rows.isEmpty) return;
    _focusRow(last ? rows.last : rows.first);
  }

  void _focusRow(FocusNode gate) {
    final node = _focusable(gate);
    if (node == null) return;
    // Through the traversal callback rather than `node.requestFocus()`, so
    // `Scrollable.ensureVisible` still runs — a nav is routinely placed in a
    // scroller, and a bare requestFocus silently loses scroll-into-view there.
    FocusTraversalPolicy.defaultTraversalRequestFocusCallback(node);
    if (identical(gate, _tabStop)) return;
    setState(() => _tabStop = gate);
    // The row that just gained the stop has to be un-latched once the frame
    // that reopens its gate has been built — see [_unlatch].
    _scheduleSettle();
  }

  /// `Home` and `End` mean top and bottom rather than start and end, and
  /// vertical arrows are not mirrored in any locale, so unlike the category's
  /// own bindings this map needs no `Directionality` branch.
  static const Map<ShortcutActivator, Intent>
  _shortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.arrowUp): FluentNavMoveIntent(-1),
    SingleActivator(LogicalKeyboardKey.arrowDown): FluentNavMoveIntent(1),
    SingleActivator(LogicalKeyboardKey.home): FluentNavEdgeIntent(last: false),
    SingleActivator(LogicalKeyboardKey.end): FluentNavEdgeIntent(last: true),
  };

  Object? get _selected => widget.selectedValue ?? _uncontrolledSelected;

  Set<Object> get _open => widget.openCategories ?? _uncontrolledOpen;

  void _requestSelect(Object value) {
    if (value == _selected) return;
    widget.onSelect?.call(value);
    if (widget.selectedValue == null) {
      setState(() => _uncontrolledSelected = value);
    }
  }

  void _requestToggle(Object value, {bool? open}) {
    final next = <Object>{..._open};
    if (open ?? !next.contains(value)) {
      next.add(value);
    } else {
      next.remove(value);
    }
    if (setEquals(next, _open)) return;
    widget.onOpenChange?.call(next);
    if (widget.openCategories == null) {
      setState(() => _uncontrolledOpen = next);
    }
  }

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: true,
    label: widget.semanticLabel,
    child: _FluentNavScope(
      size: widget.size,
      tabbable: widget.tabbable,
      tabStop: _tabStop,
      selectedValue: _selected,
      openCategories: _open,
      requestSelect: _requestSelect,
      requestToggle: _requestToggle,
      register: _register,
      unregister: _unregister,
      rowFocused: _rowFocused,
      // Shortcuts and Actions must be siblings on the same path, and outside
      // any FocusScope: ShortcutManager resolves the action from
      // `primaryFocus`, not from the Shortcuts context, so an Actions that is
      // not an ancestor of the rows yields null and the whole model silently
      // degrades to directional traversal with no error.
      child: Shortcuts(
        shortcuts: _shortcuts,
        child: Actions(
          actions: <Type, Action<Intent>>{
            FluentNavMoveIntent: CallbackAction<FluentNavMoveIntent>(
              onInvoke: (intent) {
                _move(intent.delta);
                return null;
              },
            ),
            FluentNavEdgeIntent: CallbackAction<FluentNavEdgeIntent>(
              onInvoke: (intent) {
                _edge(last: intent.last);
                return null;
              },
            ),
          },
          // No FocusTraversalGroup: the only thing one bought here was
          // `ReadingOrderTraversalPolicy`'s directional mixin, and `Up`/`Down`
          // are bound above. A non-const wrapper would also rebuild its policy
          // on every selection change and category toggle, throwing away the
          // mixin's hysteresis history each time.
          child: Focus(
            focusNode: _nav,
            canRequestFocus: false,
            skipTraversal: true,
            includeSemantics: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              // `Spacing/Vertical/XXS`, the gap Figma puts between every nav
              // row.
              spacing: FluentSpacing.xxs,
              children: widget.children,
            ),
          ),
        ),
      ),
    ),
  );
}

/// The shared plumbing of every interactive nav row: interaction, semantics and
/// the three-function pipeline.
class _FluentNavRow extends StatefulWidget {
  const _FluentNavRow({
    required this.kind,
    required this.onPressed,
    required this.enabled,
    required this.selected,
    required this.expanded,
    required this.expandable,
    required this.label,
    this.icon,
    this.selectedIcon,
    this.secondaryActions = const <Widget>[],
    this.style,
    this.focusNode,
    this.autofocus = false,
  });

  final FluentNavItemKind kind;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool selected;
  final bool expanded;
  final bool expandable;
  final Widget label;
  final Widget? icon;
  final Widget? selectedIcon;
  final List<Widget> secondaryActions;
  final FluentNavItemStyle? style;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<_FluentNavRow> createState() => _FluentNavRowState();
}

class _FluentNavRowState extends State<_FluentNavRow> {
  /// This row's handle in the nav's roving model. It never takes focus itself;
  /// it exists so the nav can find the row's own focusable descendant and can
  /// gate the row's subtree out of the Tab order.
  final FocusNode _gate = FocusNode(debugLabel: 'FluentNav row');

  _FluentNavScope? _scope;

  /// Whether this row, or anything inside it, currently holds focus.
  ///
  /// Tracked rather than read from the node at dispose time: by then the
  /// descendant that actually held focus may already have detached, and
  /// `FocusNode.hasFocus` would answer false.
  bool _hasFocus = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Idempotent: the scope widget is rebuilt on every selection change, and
    // registering into a Set costs nothing when the gate is already there.
    _scope = _FluentNavScope.of(context)..register(_gate);
  }

  @override
  void dispose() {
    _scope?.unregister(_gate, hadFocus: _hasFocus || _gate.hasFocus);
    _gate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = _FluentNavScope.of(context);

    final state = resolveFluentNavItemState(
      kind: widget.kind,
      size: scope.size,
      enabled: widget.enabled,
      selected: widget.selected,
      expanded: widget.expanded,
      expandable: widget.expandable,
      icon: widget.icon,
      selectedIcon: widget.selectedIcon,
      label: widget.label,
      secondaryActions: widget.secondaryActions,
    );

    // Lowest to highest: defaults, subtree theme, kind slot, then the caller's
    // own style.
    final resolved = resolveFluentNavItemStyle(state, FluentTheme.of(context))
        .merge(FluentNavItemTheme.maybeOfKind(context, widget.kind))
        .merge(widget.style);

    final Widget row;
    if (widget.onPressed == null && widget.enabled) {
      // Upstream ships `AppItemStatic` for a header that is only a label: no
      // hover, no press, no focus, and — the part that matters — *not*
      // disabled. A row with nothing to invoke takes that path rather than
      // being painted in the disabled tokens.
      row = buildFluentNavItem(state, resolved, const <WidgetState>{});
    } else {
      row = Semantics(
        button: true,
        enabled: widget.enabled,
        selected: state.showIndicator ? widget.selected : null,
        expanded: widget.expandable ? widget.expanded : null,
        child: FluentInteractive(
          enabled: widget.enabled,
          onPressed: widget.enabled ? widget.onPressed : null,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          mouseCursor:
              resolved.mouseCursor?.resolve(const <WidgetState>{}) ??
              SystemMouseCursors.click,
          builder: (context, states, _) => buildFluentNavItem(
            state,
            resolved,
            // Selection is not an interaction state, so FluentInteractive does
            // not report it; it is folded in here so a themed `selected:` token
            // resolves the way a caller would expect.
            widget.selected
                ? <WidgetState>{...states, WidgetState.selected}
                : states,
          ),
        ),
      );
    }

    return Focus(
      focusNode: _gate,
      // A handle, not a stop. `skipTraversal` is derived from ancestors'
      // `descendantsAreTraversable`, and the framework guarantees a skipped
      // node "may still be focused explicitly" — which is what keeps
      // `autofocus:` and a caller's own `focusNode.requestFocus()` working on a
      // row that does not hold the roving index.
      canRequestFocus: false,
      skipTraversal: true,
      // Load-bearing. `Focus` otherwise injects a
      // `Semantics(focusable:, focused:)` node, and this package asserts exact
      // semantics trees for nav rows.
      includeSemantics: false,
      descendantsAreTraversable:
          scope.tabbable ||
          // One frame only: before the focus tree exists nothing can be
          // settled, so the nav degrades to a stop per row rather than to none.
          scope.tabStop == null ||
          identical(scope.tabStop, _gate),
      onFocusChange: (hasFocus) {
        _hasFocus = hasFocus;
        if (hasFocus) scope.rowFocused(_gate);
      },
      child: row,
    );
  }
}

/// The product header at the top of a [FluentNav].
///
/// Figma's `App item - medium` / `- small`. Not a destination: it carries no
/// selection indicator, is never selected, and its label stays on the
/// `subtitle2` ramp in every state.
///
/// Omitting [onPressed] makes it upstream's `AppItemStatic` — a label with no
/// hover, no press and no focus. That is *not* the same as `enabled: false`,
/// which paints the disabled tokens.
class FluentNavAppItem extends StatelessWidget {
  /// Creates an app item.
  const FluentNavAppItem({
    super.key,
    required this.child,
    this.icon,
    this.onPressed,
    this.enabled = true,
    this.style,
    this.focusNode,
    this.autofocus = false,
  });

  /// The product name.
  final Widget child;

  /// The product logo. 32 in medium density, 24 in small.
  final Widget? icon;

  /// Invoked on tap and on Space or Enter.
  final VoidCallback? onPressed;

  /// Whether the row responds to input.
  final bool enabled;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentNavItemStyle? style;

  /// Focus node to use. One is created internally when omitted.
  final FocusNode? focusNode;

  /// Whether to take focus on mount.
  final bool autofocus;

  @override
  Widget build(BuildContext context) => _FluentNavRow(
    kind: FluentNavItemKind.appItem,
    onPressed: onPressed,
    enabled: enabled,
    selected: false,
    expanded: false,
    expandable: false,
    label: child,
    icon: icon,
    style: style,
    focusNode: focusNode,
    autofocus: autofocus,
  );
}

/// A leaf destination in a [FluentNav].
///
/// Figma's `NavNode - *`, `Group=False`. Selecting it raises the brand-coloured
/// indicator in the reserved leading column and swaps the label to
/// `body1Strong` — and, if [selectedIcon] is supplied, crossfades the icon to
/// its filled variant.
///
/// Pass `enabled: false` to disable it — disabled is a real state here, not a
/// visual treatment: the row stops reporting hover and press, refuses focus,
/// and cannot be selected by pointer or keyboard.
class FluentNavItem extends StatelessWidget {
  /// Creates a destination identified by [value].
  const FluentNavItem({
    super.key,
    required this.value,
    required this.child,
    this.icon,
    this.selectedIcon,
    this.secondaryActions = const <Widget>[],
    this.enabled = true,
    this.onPressed,
    this.style,
    this.focusNode,
    this.autofocus = false,
  });

  /// Identifies this row in the nav's selection. Anything with a stable `==`.
  final Object value;

  /// The label.
  final Widget child;

  /// Leading icon.
  final Widget? icon;

  /// The icon shown while this row is selected, crossfading from [icon] over
  /// `durationFaster`. Leave it null and [icon] stays put in every state.
  ///
  /// **[NEW API], not a literal port.** `useIconStyles` crossfades a selected
  /// row's icon from the regular glyph to the **filled** one — a second,
  /// non-typographic selection signal alongside the indicator and the
  /// `body1Strong` label. React gets it by swapping a class on one element;
  /// Flutter's icon set splits the two variants into separate `IconData`, so
  /// the filled glyph cannot be derived from the regular one and the caller
  /// has to supply it:
  ///
  /// ```dart
  /// FluentNavItem(
  ///   value: 'home',
  ///   icon: const Icon(FluentIcons.home_20_regular),
  ///   selectedIcon: const Icon(FluentIcons.home_20_filled),
  ///   child: const Text('Home'),
  /// )
  /// ```
  final Widget? selectedIcon;

  /// Trailing controls, each expected to be a 24-high icon button — compose
  /// `FluentButton.icon` with `FluentButtonSize.small` rather than rolling one.
  final List<Widget> secondaryActions;

  /// Whether the row responds to input.
  final bool enabled;

  /// Called in addition to selecting the row.
  final VoidCallback? onPressed;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentNavItemStyle? style;

  /// Focus node to use. One is created internally when omitted.
  final FocusNode? focusNode;

  /// Whether to take focus on mount.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final scope = _FluentNavScope.of(context);
    return _FluentNavRow(
      kind: FluentNavItemKind.item,
      onPressed: () {
        scope.requestSelect(value);
        onPressed?.call();
      },
      enabled: enabled,
      selected: scope.selectedValue == value,
      expanded: false,
      expandable: false,
      label: child,
      icon: icon,
      selectedIcon: selectedIcon,
      secondaryActions: secondaryActions,
      style: style,
      focusNode: focusNode,
      autofocus: autofocus,
    );
  }
}

/// A destination nested inside a [FluentNavCategory].
///
/// Figma's `NavSubItem`. Always 32 high whatever the nav density, and indented
/// 46 so its label lines up with the category label above rather than with the
/// category icon.
class FluentNavSubItem extends StatelessWidget {
  /// Creates a sub-item identified by [value].
  const FluentNavSubItem({
    super.key,
    required this.value,
    required this.child,
    this.secondaryActions = const <Widget>[],
    this.enabled = true,
    this.onPressed,
    this.style,
    this.focusNode,
    this.autofocus = false,
  });

  /// Identifies this row in the nav's selection.
  final Object value;

  /// The label.
  final Widget child;

  /// Trailing controls, each expected to be a 24-high icon button.
  final List<Widget> secondaryActions;

  /// Whether the row responds to input.
  final bool enabled;

  /// Called in addition to selecting the row.
  final VoidCallback? onPressed;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentNavItemStyle? style;

  /// Focus node to use. One is created internally when omitted.
  final FocusNode? focusNode;

  /// Whether to take focus on mount.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final scope = _FluentNavScope.of(context);
    return _FluentNavRow(
      kind: FluentNavItemKind.subItem,
      onPressed: () {
        scope.requestSelect(value);
        onPressed?.call();
      },
      enabled: enabled,
      selected: scope.selectedValue == value,
      expanded: false,
      expandable: false,
      label: child,
      secondaryActions: secondaryActions,
      style: style,
      focusNode: focusNode,
      autofocus: autofocus,
    );
  }
}

/// A collapsible group of [FluentNavSubItem]s.
///
/// Figma's `NavNode - *`, `Group=True`. The header toggles the group; the group
/// itself collapses on [FluentMotionSpec.collapse] and is not built while
/// closed, matching upstream's `unmountOnExit`.
///
/// `Right` opens the group and `Left` closes it while the header has focus,
/// mirrored under [TextDirection.rtl]. Both bindings live on the header, so
/// they never shadow directional focus traversal elsewhere in the nav.
class FluentNavCategory extends StatelessWidget {
  /// Creates a category identified by [value].
  const FluentNavCategory({
    super.key,
    required this.value,
    required this.child,
    required this.children,
    this.icon,
    this.selectedIcon,
    this.enabled = true,
    this.style,
    this.focusNode,
    this.autofocus = false,
  });

  /// Identifies this category in the nav's open set.
  final Object value;

  /// The header label.
  final Widget child;

  /// The sub-items, revealed while the category is open.
  final List<Widget> children;

  /// Leading icon.
  final Widget? icon;

  /// The icon shown while the header is selected. See
  /// [FluentNavItem.selectedIcon] — same [NEW API] slot, same `useIconStyles`
  /// crossfade, and the same rule that null changes nothing.
  ///
  /// A category counts as selected only while it is **closed**, so this reads
  /// as filled exactly when the indicator is up, not whenever the group is
  /// open. [FluentNavSubItem] takes no icon at all — neither React nor this
  /// port gives it one — so there is nothing to swap a level down.
  final Widget? selectedIcon;

  /// Whether the header responds to input.
  final bool enabled;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentNavItemStyle? style;

  /// Focus node to use. One is created internally when omitted.
  final FocusNode? focusNode;

  /// Whether to take focus on mount.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final scope = _FluentNavScope.of(context);
    final expanded = scope.openCategories.contains(value);
    final rtl = Directionality.of(context) == TextDirection.rtl;

    final header = _FluentNavRow(
      kind: FluentNavItemKind.category,
      onPressed: () => scope.requestToggle(value),
      enabled: enabled,
      // Figma marks a category Selected only while it is closed — an open
      // category delegates the indicator to whichever sub-item is current.
      selected: !expanded && scope.selectedValue == value,
      expanded: expanded,
      expandable: true,
      label: child,
      icon: icon,
      selectedIcon: selectedIcon,
      style: style,
      focusNode: focusNode,
      autofocus: autofocus,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Shortcuts and Actions wrap the header, never the whole nav: bound on
        // the nav they would swallow Left and Right for every row.
        Shortcuts(
          shortcuts: <ShortcutActivator, Intent>{
            SingleActivator(
              rtl
                  ? LogicalKeyboardKey.arrowLeft
                  : LogicalKeyboardKey.arrowRight,
            ): const FluentNavExpandIntent(),
            SingleActivator(
              rtl
                  ? LogicalKeyboardKey.arrowRight
                  : LogicalKeyboardKey.arrowLeft,
            ): const FluentNavCollapseIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              FluentNavExpandIntent: CallbackAction<FluentNavExpandIntent>(
                onInvoke: (_) {
                  if (enabled) scope.requestToggle(value, open: true);
                  return null;
                },
              ),
              FluentNavCollapseIntent: CallbackAction<FluentNavCollapseIntent>(
                onInvoke: (_) {
                  if (enabled) scope.requestToggle(value, open: false);
                  return null;
                },
              ),
            },
            child: header,
          ),
        ),
        _FluentNavGroup(
          expanded: expanded,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: FluentSpacing.xxs,
            children: children,
          ),
        ),
      ],
    );
  }
}

/// A rule between two groups of nav rows.
///
/// Upstream's `NavDivider` is a plain `Divider` with a 4px margin above and
/// below and nothing else, so this composes [FluentDivider] rather than drawing
/// a second hairline of its own.
class FluentNavDivider extends StatelessWidget {
  /// Creates a nav divider.
  const FluentNavDivider({super.key, this.appearance});

  /// How strongly the rule reads. Defaults to [FluentDivider]'s own default.
  final FluentDividerAppearance? appearance;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: FluentSpacing.xs),
    child: FluentDivider(
      appearance: appearance ?? FluentDividerAppearance.standard,
    ),
  );
}

/// A non-interactive grouping label in a [FluentNav].
///
/// Upstream's `NavSectionHeader` renders an `h3` carrying `caption1Strong`,
/// `marginInlineStart: 10px` and `marginBlock: 8px` — and nothing else.
/// `useNavSectionHeaderStyles.styles.ts` is three declarations long, and
/// `NavSectionHeader.types.ts` declares no props at all. Unlike
/// [FluentNavCategory] it does not collapse, take an icon, or accept selection.
///
/// Unlike [FluentNavItem] and its siblings, this does **not** require a
/// [FluentNav] ancestor. It never reads the nav's scope, so it is usable in any
/// nav-shaped list.
///
/// The colour is inherited rather than set, because upstream declares none.
/// Inside a `FluentNavDrawer` that resolves to `neutralForeground1`, which the
/// drawer pushes down through its own `DefaultTextStyle`.
class FluentNavSectionHeader extends StatelessWidget {
  /// Creates a section header labelled [child].
  const FluentNavSectionHeader({super.key, required this.child});

  /// The label.
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    // Upstream hardcodes `h3` in `useNavSectionHeader.ts`. Flutter has no
    // heading `SemanticsRole`, so the level travels on `headingLevel` instead.
    // This is the first use of that API in this package; the choice is
    // deliberate, and sets the precedent for any other header-ish widget here.
    headingLevel: 3,
    child: Padding(
      // `marginInlineStart: 10px` and `marginBlock: 8px`, with no inline-end
      // margin — the label runs to the panel's own gutter.
      padding: const EdgeInsetsDirectional.fromSTEB(
        FluentSpacing.mNudge,
        FluentSpacing.s,
        FluentSpacing.none,
        FluentSpacing.s,
      ),
      child: DefaultTextStyle.merge(
        style: FluentTheme.of(context).typography.caption1Strong,
        child: child,
      ),
    ),
  );
}
