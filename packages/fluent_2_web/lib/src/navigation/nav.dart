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
/// Where `microsoft/fluentui@master` disagrees, Figma wins and both readings
/// are called out in the comment at the disagreement — see the surface motion
/// curve, the small-density padding and the leaf's trailing inset.
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

  // The geometry table, verbatim from the five fixtures. `padding` is the inner
  // `Button` frame's; the vertical half only matters for a row whose content is
  // taller than the fixed height, because the row is centred inside
  // `minimumSize`.
  final (padding, gap, height, iconSize) = switch (state.kind) {
    FluentNavItemKind.appItem when small => (
      const EdgeInsets.fromLTRB(
        FluentSpacing.mNudge + FluentSpacing.xs,
        FluentSpacing.s,
        FluentSpacing.sNudge,
        FluentSpacing.s,
      ),
      FluentSpacing.mNudge,
      40.0,
      FluentSize.size240,
    ),
    FluentNavItemKind.appItem => (
      const EdgeInsets.symmetric(
        horizontal: FluentSpacing.mNudge,
        vertical: FluentSpacing.s,
      ),
      FluentSpacing.s,
      48.0,
      FluentSize.size320,
    ),
    FluentNavItemKind.category => (
      EdgeInsets.fromLTRB(
        FluentSpacing.mNudge,
        small ? FluentSpacing.sNudge : FluentSpacing.mNudge,
        FluentSpacing.s,
        small ? FluentSpacing.sNudge : FluentSpacing.mNudge,
      ),
      FluentSpacing.l,
      small ? 32.0 : 40.0,
      FluentSize.size200,
    ),
    FluentNavItemKind.item => (
      const EdgeInsets.fromLTRB(
        FluentSpacing.mNudge,
        FluentSpacing.none,
        FluentSpacing.sNudge,
        FluentSpacing.none,
      ),
      FluentSpacing.l,
      small ? 32.0 : 40.0,
      FluentSize.size200,
    ),
    // The 46 is not a token: Figma writes it as a literal, and it is exactly
    // `paddingLeft` (10) + icon (20) + gap (16) of the row above, so a sub-item
    // label lines up with its category label rather than with its icon.
    FluentNavItemKind.subItem => (
      const EdgeInsets.fromLTRB(
        46,
        FluentSpacing.none,
        FluentSpacing.sNudge,
        FluentSpacing.none,
      ),
      FluentSpacing.l,
      32.0,
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

  final children = <Widget>[
    if (state.icon != null)
      IconTheme.merge(
        data: IconThemeData(color: iconColor, size: iconSize),
        child: state.icon!,
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
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`. Placing it above a [FluentNav] restyles every row in
/// it.
class FluentNavItemTheme extends InheritedTheme {
  /// Applies [style] to every nav row in [child].
  const FluentNavItemTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the kind and size defaults.
  final FluentNavItemStyle style;

  /// The nearest nav row style, or null.
  static FluentNavItemStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentNavItemTheme>()?.style;

  @override
  bool updateShouldNotify(FluentNavItemTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentNavItemTheme(style: style, child: child);
}

/// Carries density, selection and the open set down to every row.
class _FluentNavScope extends InheritedWidget {
  const _FluentNavScope({
    required this.size,
    required this.selectedValue,
    required this.openCategories,
    required this.requestSelect,
    required this.requestToggle,
    required super.child,
  });

  final FluentNavSize size;
  final Object? selectedValue;
  final Set<Object> openCategories;
  final void Function(Object value) requestSelect;
  final void Function(Object value, {bool? open}) requestToggle;

  static _FluentNavScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_FluentNavScope>();
    assert(
      scope != null,
      'Nav rows must be placed inside a FluentNav, which owns the density, the '
      'selected value and the open set.',
    );
    return scope!;
  }

  @override
  bool updateShouldNotify(_FluentNavScope oldWidget) =>
      size != oldWidget.size ||
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
/// Up and Down move focus between rows, which is the framework's own
/// directional traversal rather than a bespoke roving index — a nav is a plain
/// vertical list of focusables and needs nothing more. `Enter` and `Space`
/// activate the focused row. On a category header, `Right` opens and `Left`
/// closes, mirrored in a right-to-left nav. Those two are the only bindings
/// this widget installs, and they sit on the header rather than on the nav, so
/// they never shadow directional traversal anywhere else.
///
/// The nav fills the width it is given and hugs its height. Fluent's own drawer
/// is 260 wide.
class FluentNav extends StatefulWidget {
  /// Creates a nav over [children].
  const FluentNav({
    super.key,
    required this.children,
    this.size = FluentNavSize.medium,
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
      selectedValue: _selected,
      openCategories: _open,
      requestSelect: _requestSelect,
      requestToggle: _requestToggle,
      child: FocusTraversalGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          // `Spacing/Vertical/XXS`, the gap Figma puts between every nav row.
          spacing: FluentSpacing.xxs,
          children: widget.children,
        ),
      ),
    ),
  );
}

/// The shared plumbing of every interactive nav row: interaction, semantics and
/// the three-function pipeline.
class _FluentNavRow extends StatelessWidget {
  const _FluentNavRow({
    required this.kind,
    required this.onPressed,
    required this.enabled,
    required this.selected,
    required this.expanded,
    required this.expandable,
    required this.label,
    this.icon,
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
  final List<Widget> secondaryActions;
  final FluentNavItemStyle? style;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final state = resolveFluentNavItemState(
      kind: kind,
      size: _FluentNavScope.of(context).size,
      enabled: enabled,
      selected: selected,
      expanded: expanded,
      expandable: expandable,
      icon: icon,
      label: label,
      secondaryActions: secondaryActions,
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentNavItemStyle(
      state,
      FluentTheme.of(context),
    ).merge(FluentNavItemTheme.maybeOf(context)).merge(style);

    // Upstream ships `AppItemStatic` for a header that is only a label: no
    // hover, no press, no focus, and — the part that matters — *not* disabled.
    // A row with nothing to invoke takes that path rather than being painted in
    // the disabled tokens, which is what a null `onPressed` means everywhere
    // else in this package.
    if (onPressed == null && enabled) {
      return buildFluentNavItem(state, resolved, const <WidgetState>{});
    }

    return Semantics(
      button: true,
      enabled: enabled,
      selected: state.showIndicator ? selected : null,
      expanded: expandable ? expanded : null,
      child: FluentInteractive(
        enabled: enabled,
        onPressed: enabled ? onPressed : null,
        focusNode: focusNode,
        autofocus: autofocus,
        mouseCursor:
            resolved.mouseCursor?.resolve(const <WidgetState>{}) ??
            SystemMouseCursors.click,
        builder: (context, states, _) => buildFluentNavItem(
          state,
          resolved,
          // Selection is not an interaction state, so FluentInteractive does
          // not report it; it is folded in here so a themed `selected:` token
          // resolves the way a caller would expect.
          selected ? <WidgetState>{...states, WidgetState.selected} : states,
        ),
      ),
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
/// `body1Strong`.
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
