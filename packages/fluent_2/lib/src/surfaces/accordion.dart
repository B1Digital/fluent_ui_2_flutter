import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/widgets.dart';

import '../internal/animated_style.dart';
import '../internal/focus_ring.dart';
import '../internal/interaction.dart';
import 'accordion_style.dart';

/// Header height and type ramp. Figma's `Size` axis.
///
/// The four steps are upstream's `AccordionHeaderProps['size']` verbatim. Only
/// the label metrics and the minimum height change; nothing else in the header
/// is size-dependent.
/// Every step is 44 high in Figma — the header frame is a fixed 44 on all 24
/// variants — and only the label ramp step changes. React's
/// `buttonSmall: { minHeight: '32px' }` has no counterpart in the design file.
enum FluentAccordionSize {
  /// 44 high, `caption1` (12/16 regular on web).
  small,

  /// 44 high, `body1` (14/20 regular on web). The default.
  medium,

  /// 44 high, `subtitle2` (16/22 **semibold** on web).
  large,

  /// 44 high, `subtitle1` (20/26 **semibold** on web).
  extraLarge,
}

/// Which side of the header the chevron sits on. Figma's `Chevron` axis.
enum FluentAccordionExpandIconPosition {
  /// Before the label in reading order, pointing right when collapsed and down
  /// when expanded. The default.
  start,

  /// After the label in reading order, pushed to the trailing edge, pointing
  /// down when collapsed and up when expanded.
  end,
}

/// Everything needed to render one accordion item, independent of its size.
///
/// The Dart counterpart of upstream's `AccordionHeaderBaseState`.
/// [buildFluentAccordionItem] takes this rather than [FluentAccordionItemState],
/// which is what makes "Fluent's state, my own styling, Fluent's rendering" a
/// supported path rather than a fork.
@immutable
class FluentAccordionItemBaseState {
  /// Creates a base state.
  const FluentAccordionItemBaseState({
    required this.enabled,
    required this.expanded,
    required this.expandIconPosition,
    this.icon,
    this.header,
  });

  /// Whether the header responds to input.
  final bool enabled;

  /// Whether the panel is open. Figma's `Expanded` axis.
  final bool expanded;

  /// Which side the chevron sits on.
  final FluentAccordionExpandIconPosition expandIconPosition;

  /// Optional icon between the chevron and the label.
  final Widget? icon;

  /// The header label, if any.
  final Widget? header;
}

/// An accordion item's fully resolved state, including the design axes.
///
/// The counterpart of upstream's `AccordionHeaderState`: base state plus
/// exactly `size`.
@immutable
class FluentAccordionItemState extends FluentAccordionItemBaseState {
  /// Creates a resolved state.
  const FluentAccordionItemState({
    required super.enabled,
    required super.expanded,
    required super.expandIconPosition,
    required this.size,
    super.icon,
    super.header,
  });

  /// Header height and type ramp.
  final FluentAccordionSize size;
}

/// Builds the state an accordion item will be styled and rendered from.
///
/// Separated so a consumer can reuse Fluent's state resolution while
/// substituting their own styling — the first of the three-function
/// recomposition contract.
FluentAccordionItemState resolveFluentAccordionItemState({
  bool enabled = true,
  bool expanded = false,
  FluentAccordionSize size = FluentAccordionSize.medium,
  FluentAccordionExpandIconPosition expandIconPosition =
      FluentAccordionExpandIconPosition.start,
  Widget? icon,
  Widget? header,
}) => FluentAccordionItemState(
  enabled: enabled,
  expanded: expanded,
  size: size,
  expandIconPosition: expandIconPosition,
  icon: icon,
  header: header,
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes. Every colour is an explicitly named Fluent
/// token; nothing here computes one.
///
/// ## Where the numbers come from
///
/// The Figma `Accordion` set (`9074:913`, 24 variants), pinned in
/// `test/fixtures/accordion.json`. Upstream
/// `useAccordionHeaderStyles.styles.ts` and `useAccordionPanelStyles.styles.ts`
/// were the original source and disagree in four places; Figma wins and both
/// values are recorded in `doc/token-divergences.md`.
///
/// * header fill `colorTransparentBackground` (Figma paints no fill at all),
///   label `Neutral/Foreground/1/Rest`, disabled label
///   `Neutral/Foreground/Disabled/Rest`, radius `Corner radius/Medium` (4)
/// * header padding `Spacing/Horizontal/MNudge` on **both** sides, on every
///   variant — React writes `0 spacingHorizontalM 0 spacingHorizontalMNudge`
///   plus two chevron-at-end overrides, none of which Figma has
/// * header height 44 on every size — React gives
///   [FluentAccordionSize.small] a 32px `minHeight` that Figma does not
/// * label ramp `caption1` / `body1` / `subtitle2` / `subtitle1`. React
///   overrides `body1`'s size in place and keeps the regular weight; Figma
///   binds `Typography/Weight/Semibold` on Large and Extra large, and
///   `Line height/200` (16) rather than 20 on Small
/// * chevron and icon gaps `Spacing/Horizontal/S` (8), chevron box 20
/// * panel inset `Spacing/Horizontal/M` each side **and**
///   `Spacing/Vertical/M` below — React's `margin: 0 spacingHorizontalM` has no
///   bottom
FluentAccordionItemStyle resolveFluentAccordionItemStyle(
  FluentAccordionItemState state,
  FluentThemeData theme,
) {
  final c = theme.colors;

  // Upstream declares only `colorTransparentBackground` on the header root and
  // no hover or pressed rule at all, so in light and dark every one of these
  // resolves to the same fully transparent value and the header is deliberately
  // flat. Naming the whole family rather than one token is still not a
  // decoration: `transparentBackgroundHover` and `transparentBackgroundPressed`
  // become the opaque system highlight in high contrast, which is where a flat
  // header would otherwise give a keyboard user no pointer feedback at all.
  final background = FluentStateColor.tokens(
    rest: c.transparentBackground,
    hover: c.transparentBackgroundHover,
    pressed: c.transparentBackgroundPressed,
    disabled: c.transparentBackground,
  );

  final foreground = FluentStateColor.tokens(
    rest: c.neutralForeground1,
    disabled: c.neutralForegroundDisabled,
  );

  // Four named ramp steps, not four size overrides on body1. Figma binds a
  // whole type style per size — including `Typography/Weight/Semibold` from
  // Large up — and each one lands exactly on a step of the web ramp, so the
  // platform ramps stay honoured instead of being overwritten with web pixels.
  final textStyle = switch (state.size) {
    FluentAccordionSize.small => theme.typography.caption1,
    FluentAccordionSize.medium => theme.typography.body1,
    FluentAccordionSize.large => theme.typography.subtitle2,
    FluentAccordionSize.extraLarge => theme.typography.subtitle1,
  };

  return FluentAccordionItemStyle(
    backgroundColor: background,
    foregroundColor: foreground,
    borderRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allMedium,
    ),
    textStyle: WidgetStatePropertyAll<TextStyle?>(textStyle),
    // Symmetric, and the same on every variant: Figma binds
    // `Spacing/Horizontal/MNudge` to both `paddingLeft` and `paddingRight` on
    // all 24 headers, so neither the chevron position nor the leading icon
    // moves it.
    padding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.symmetric(horizontal: FluentSpacing.mNudge),
    ),
    gap: const WidgetStatePropertyAll<double?>(FluentSpacing.s),
    expandIconSize: const WidgetStatePropertyAll<double?>(FluentSize.size200),
    minimumSize: const WidgetStatePropertyAll<Size?>(Size(0, 44)),
    panelPadding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsetsDirectional.only(
        start: FluentSpacing.m,
        end: FluentSpacing.m,
        bottom: FluentSpacing.m,
      ),
    ),
    mouseCursor: const WidgetStatePropertyAll<MouseCursor?>(
      SystemMouseCursors.click,
    ),
  );
}

/// Renders an accordion item's **header** from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentAccordionItemBaseState] rather than [FluentAccordionItemState] on
/// purpose: it never reads the size axis, so a consumer can supply their own
/// style and still use Fluent's rendering, focus ring and chevron animation.
///
/// The header only, not the panel: the panel must stay outside the interactive
/// surface, because clicking inside an open panel must not collapse it.
/// [FluentAccordionItem] composes the two.
///
/// [states] is the live interaction set from [FluentInteractive].
///
/// The chevron rotates on [FluentMotionSpec.accordionChevron]; nothing else
/// here transitions, because upstream declares no transition on the header
/// root. A themed hover fill therefore lands on the next frame rather than
/// tweening, which is upstream's behaviour and not an omission.
Widget buildFluentAccordionItem(
  FluentAccordionItemBaseState state,
  FluentAccordionItemStyle style,
  Set<WidgetState> states,
) {
  final radius = style.borderRadius?.resolve(states) ?? FluentRadius.allMedium;
  final background = style.backgroundColor?.resolve(states);
  final foreground = style.foregroundColor?.resolve(states);
  final padding = style.padding?.resolve(states) ?? EdgeInsets.zero;
  final gap = style.gap?.resolve(states) ?? FluentSpacing.s;
  final iconSize = style.expandIconSize?.resolve(states) ?? FluentSize.size200;
  final minimumSize = style.minimumSize?.resolve(states) ?? Size.zero;
  final textStyle = style.textStyle?.resolve(states);

  final chevron = _FluentAccordionChevron(
    expanded: state.expanded,
    position: state.expandIconPosition,
    size: iconSize,
    color: foreground,
  );

  final label = Expanded(child: state.header ?? const SizedBox.shrink());

  final leading = state.icon == null
      ? null
      : IconTheme.merge(
          data: IconThemeData(color: foreground, size: iconSize),
          child: state.icon!,
        );

  // Row `spacing` rather than per-slot padding: upstream's three gaps
  // (expandIconStart paddingRight, icon paddingRight, expandIconEnd
  // paddingLeft) are all spacingHorizontalS, so one value reproduces all three.
  Widget content = Row(
    spacing: gap,
    children: switch (state.expandIconPosition) {
      FluentAccordionExpandIconPosition.start => <Widget>[
        chevron,
        ?leading,
        label,
      ],
      FluentAccordionExpandIconPosition.end => <Widget>[
        ?leading,
        label,
        chevron,
      ],
    },
  );

  if (textStyle != null || foreground != null) {
    content = DefaultTextStyle.merge(
      style: (textStyle ?? const TextStyle()).copyWith(color: foreground),
      child: content,
    );
  }

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
        child: Padding(padding: padding, child: content),
      ),
    ),
  );
}

/// The rotating chevron.
///
/// `ChevronRightRegular` under a [Transform], exactly as upstream does it: the
/// glyph never changes, only its rotation. Upstream writes
/// `transition: transform 200ms ease-out` inline in `useAccordionHeader.tsx`.
class _FluentAccordionChevron extends StatelessWidget {
  const _FluentAccordionChevron({
    required this.expanded,
    required this.position,
    required this.size,
    required this.color,
  });

  final bool expanded;
  final FluentAccordionExpandIconPosition position;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    // Upstream rotates a right-pointing chevron by 0/90/-90 degrees, and uses
    // 180 for the collapsed start position in RTL. `chevron_right_20_regular`
    // carries `matchTextDirection`, so the glyph is already mirrored in RTL and
    // the extra 180 would double-flip it: negating the turn is the same result
    // with the mirroring left to the framework.
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final turns = switch (position) {
      FluentAccordionExpandIconPosition.start => expanded ? 0.25 : 0.0,
      FluentAccordionExpandIconPosition.end => expanded ? -0.25 : 0.25,
    };

    final icon = IconTheme.merge(
      data: IconThemeData(color: color, size: size),
      child: const Icon(FluentIcons.chevron_right_20_regular),
    );

    return FluentAnimatedStyle<double>(
      value: rtl ? -turns : turns,
      spec: FluentMotionSpec.accordionChevron,
      lerp: lerpDouble,
      builder: (context, value) =>
          Transform.rotate(angle: value * 2 * math.pi, child: icon),
    );
  }
}

/// The collapsing panel.
///
/// Upstream wraps the panel in `Collapse` from
/// `@fluentui/react-motion-components-preview`, whose defaults are
/// `durationNormal` (200ms) on `curveEasyEaseMax`, animating height and opacity
/// together, with `unmountOnExit`. All four are reproduced here:
/// [FluentMotionSpec.collapse] is that duration and curve, the collapsed child
/// is not built at all, and reduced motion is handled by [FluentAnimatedStyle].
class _FluentAccordionPanel extends StatelessWidget {
  const _FluentAccordionPanel({required this.expanded, required this.child});

  final bool expanded;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Hoisted out of the builder: it does not depend on the animated value, so
    // an identical instance short-circuits its own rebuild every frame.
    //
    // The width is pinned because [Align] hands its child loose constraints,
    // which would let the panel hug its content. Upstream's panel is a block
    // `div` and fills the accordion's width, so this one does too.
    final content = SizedBox(width: double.infinity, child: child);
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

/// Overrides the accordion item style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`. Placing it above a `FluentAccordion` restyles every
/// item in it.
class FluentAccordionItemTheme extends InheritedTheme {
  /// Applies [style] to every [FluentAccordionItem] in [child].
  const FluentAccordionItemTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the size defaults.
  final FluentAccordionItemStyle style;

  /// The nearest accordion item style, or null.
  static FluentAccordionItemStyle? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FluentAccordionItemTheme>()
      ?.style;

  @override
  bool updateShouldNotify(FluentAccordionItemTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentAccordionItemTheme(style: style, child: child);
}

/// Carries the open set and the toggle request down to every item.
class _FluentAccordionScope extends InheritedWidget {
  const _FluentAccordionScope({
    required this.openItems,
    required this.requestToggle,
    required super.child,
  });

  final Set<Object> openItems;
  final void Function(Object value) requestToggle;

  static _FluentAccordionScope of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_FluentAccordionScope>();
    assert(
      scope != null,
      'FluentAccordionItem must be placed inside a FluentAccordion, which owns '
      'the open set and decides what a toggle does.',
    );
    return scope!;
  }

  @override
  bool updateShouldNotify(_FluentAccordionScope oldWidget) =>
      !setEquals(openItems, oldWidget.openItems) ||
      requestToggle != oldWidget.requestToggle;
}

/// A Fluent 2 accordion: a stack of headers, each revealing a panel.
///
/// ```dart
/// FluentAccordion(
///   multiple: true,
///   defaultOpenItems: const <Object>{'shipping'},
///   children: const <Widget>[
///     FluentAccordionItem(
///       value: 'shipping',
///       header: Text('Shipping'),
///       child: Text('Arrives in three days.'),
///     ),
///   ],
/// )
/// ```
///
/// Expansion follows upstream's rules exactly, and the two flags are
/// independent:
///
/// * [multiple] false, [collapsible] false — one panel open at a time, and once
///   one is open it cannot be closed except by opening another. The default.
/// * [multiple] false, [collapsible] true — one panel open at a time, and the
///   open one can be closed.
/// * [multiple] true, [collapsible] false — any number open, but the last open
///   panel cannot be closed.
/// * [multiple] true, [collapsible] true — any number open, including none.
///
/// Pass [openItems] to control the set yourself; leave it null and the widget
/// keeps its own, seeded from [defaultOpenItems]. [onToggle] reports the set the
/// accordion is moving to in both cases.
///
/// The accordion fills the width it is given and hugs its height, because a
/// Fluent header is a full-width row. Give it a bounded width — a `Column`, a
/// `SizedBox`, an `Expanded`.
class FluentAccordion extends StatefulWidget {
  /// Creates an accordion over [children], which are normally
  /// [FluentAccordionItem]s.
  const FluentAccordion({
    super.key,
    required this.children,
    this.multiple = false,
    this.collapsible = false,
    this.openItems,
    this.defaultOpenItems = const <Object>{},
    this.onToggle,
  });

  /// The items, in order.
  final List<Widget> children;

  /// Whether more than one panel may be open at once.
  final bool multiple;

  /// Whether the last open panel may be closed, leaving none open.
  final bool collapsible;

  /// The open set, when the caller owns it. Null leaves the accordion
  /// uncontrolled.
  final Set<Object>? openItems;

  /// The initial open set while uncontrolled. Ignored once [openItems] is
  /// given.
  final Set<Object> defaultOpenItems;

  /// Called with the set the accordion is moving to, before it is applied.
  final ValueChanged<Set<Object>>? onToggle;

  @override
  State<FluentAccordion> createState() => _FluentAccordionState();
}

class _FluentAccordionState extends State<FluentAccordion> {
  late Set<Object> _uncontrolled = <Object>{
    // Upstream's `initializeUncontrolledOpenItems`: a single-expansion
    // accordion keeps only the first of several defaults rather than opening
    // two panels it can never close.
    if (widget.defaultOpenItems.isNotEmpty && !widget.multiple)
      widget.defaultOpenItems.first
    else
      ...widget.defaultOpenItems,
  };

  Set<Object> get _openItems => widget.openItems ?? _uncontrolled;

  /// Upstream's `updateOpenItems`, transcribed.
  Set<Object> _next(Object value) {
    final open = _openItems;
    if (widget.multiple) {
      if (!open.contains(value)) return <Object>{...open, value};
      if (open.length > 1 || widget.collapsible) {
        return <Object>{...open}..remove(value);
      }
      return open;
    }
    if (open.length == 1 && open.first == value) {
      return widget.collapsible ? <Object>{} : open;
    }
    return <Object>{value};
  }

  void _requestToggle(Object value) {
    final next = _next(value);
    if (setEquals(next, _openItems)) return;
    widget.onToggle?.call(next);
    if (widget.openItems == null) setState(() => _uncontrolled = next);
  }

  @override
  Widget build(BuildContext context) => _FluentAccordionScope(
    openItems: _openItems,
    requestToggle: _requestToggle,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widget.children,
    ),
  );
}

/// One header-and-panel pair inside a [FluentAccordion].
///
/// [value] identifies the item in the accordion's open set and must be unique
/// within one accordion; anything with a stable `==` will do.
///
/// Pass `enabled: false` to disable it — disabled is a real state here, not a
/// visual treatment: the header stops reporting hover and press, refuses focus,
/// and cannot be toggled by pointer or keyboard.
///
/// ## The header has no hover fill
///
/// Upstream's `useAccordionHeaderStyles` sets `colorTransparentBackground` on
/// the header root and declares no `:hover` or `:active` rule at all, so a
/// Fluent accordion header is flat in light and dark. That is reproduced rather
/// than improved. High contrast is the exception, where Fluent's transparent
/// hover and pressed tokens resolve to the opaque system highlight and the
/// header does react.
///
/// Figma agrees. Its `Accordion` set has 24 variants over `Size`, `State`,
/// `Expanded` and `Chevron`, and the `State` axis offers only `Rest` and
/// `Disabled` — there is no Hover or Pressed variant to paint, and the header
/// frame carries no fill at all in either state. [FluentAccordionItemTheme]
/// applies one in a line for anyone who wants the feedback anyway.
///
/// Customisation follows the same three rungs as every other component. [style]
/// is merged last and wins; [FluentAccordionItemTheme] restyles a subtree; and
/// for anything further, [resolveFluentAccordionItemState],
/// [resolveFluentAccordionItemStyle] and [buildFluentAccordionItem] are public
/// so any one of them can be replaced without forking this widget.
class FluentAccordionItem extends StatelessWidget {
  /// Creates an item whose [header] toggles [child].
  const FluentAccordionItem({
    super.key,
    required this.value,
    required this.header,
    required this.child,
    this.icon,
    this.size = FluentAccordionSize.medium,
    this.expandIconPosition = FluentAccordionExpandIconPosition.start,
    this.enabled = true,
    this.style,
    this.focusNode,
    this.autofocus = false,
  });

  /// Identifies this item in the accordion's open set.
  final Object value;

  /// The header label.
  final Widget header;

  /// The panel content, revealed while the item is expanded.
  final Widget child;

  /// Optional icon between the chevron and the label.
  final Widget? icon;

  /// Header height and type ramp.
  final FluentAccordionSize size;

  /// Which side of the header the chevron sits on.
  final FluentAccordionExpandIconPosition expandIconPosition;

  /// Whether the header responds to input.
  final bool enabled;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentAccordionItemStyle? style;

  /// Focus node to use. One is created internally when omitted.
  final FocusNode? focusNode;

  /// Whether to take focus on mount.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final scope = _FluentAccordionScope.of(context);
    final expanded = scope.openItems.contains(value);

    final state = resolveFluentAccordionItemState(
      enabled: enabled,
      expanded: expanded,
      size: size,
      expandIconPosition: expandIconPosition,
      icon: icon,
      header: header,
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentAccordionItemStyle(
      state,
      FluentTheme.of(context),
    ).merge(FluentAccordionItemTheme.maybeOf(context)).merge(style);

    final panelPadding =
        resolved.panelPadding?.resolve(const <WidgetState>{}) ??
        EdgeInsets.zero;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          button: true,
          enabled: enabled,
          expanded: expanded,
          child: FluentInteractive(
            enabled: enabled,
            onPressed: enabled ? () => scope.requestToggle(value) : null,
            focusNode: focusNode,
            autofocus: autofocus,
            mouseCursor:
                resolved.mouseCursor?.resolve(const <WidgetState>{}) ??
                SystemMouseCursors.click,
            builder: (context, states, _) =>
                buildFluentAccordionItem(state, resolved, states),
          ),
        ),
        _FluentAccordionPanel(
          expanded: expanded,
          child: Padding(padding: panelPadding, child: child),
        ),
      ],
    );
  }
}
