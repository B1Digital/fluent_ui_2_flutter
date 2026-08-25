import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/semantics.dart' show SemanticsRole;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../internal/animated_style.dart';
import '../internal/focus_ring.dart';
import '../internal/interaction.dart';
import 'tab_style.dart';

/// Which way a tab list runs.
///
/// Figma ships two component sets rather than one axis — `Horizontal Tab` and
/// `Vertical Tab` — and they disagree on more than direction: the selection
/// indicator moves from the bottom edge to the leading edge, and the padding
/// and indicator inset both change.
enum FluentTabOrientation {
  /// Tabs in a row, indicator along the bottom edge. The default.
  horizontal,

  /// Tabs in a column, indicator along the leading edge.
  vertical,
}

/// Tab height and type ramp. Figma's `Size` axis.
enum FluentTabSize {
  /// The default. 44 high horizontal, 32 vertical.
  medium,

  /// 32 high horizontal, 24 vertical.
  small,
}

/// Fill and shape treatment. Figma's `Style` axis.
enum FluentTabAppearance {
  /// No fill at rest, selection shown by the indicator bar. The default.
  transparent,

  /// Like [transparent] but with a neutral fill on hover and press.
  subtle,

  /// A pill with a brand fill when selected. No indicator bar.
  filledCircular,

  /// A pill with a light brand fill and a brand outline when selected. No
  /// indicator bar.
  subtleCircular,
}

/// Whether [appearance] is one of the two pill treatments.
bool _isPill(FluentTabAppearance appearance) =>
    appearance == FluentTabAppearance.filledCircular ||
    appearance == FluentTabAppearance.subtleCircular;

/// Everything needed to render a tab, independent of appearance and size.
///
/// The counterpart of `FluentButtonBaseState`. [buildFluentTab] takes this
/// rather than [FluentTabState], which is what makes "Fluent's state, my own
/// styling, Fluent's rendering" a supported path rather than a fork.
///
/// [orientation] is here rather than on [FluentTabState] because it is
/// structural: the renderer has to know which edge the indicator runs along,
/// the way a button's renderer has to know which side its icon sits on.
@immutable
class FluentTabBaseState {
  /// Creates a base state.
  const FluentTabBaseState({
    required this.enabled,
    required this.selected,
    required this.orientation,
    this.icon,
    this.label,
  });

  /// Whether the tab responds to input.
  final bool enabled;

  /// Whether this is the selected tab of its list.
  final bool selected;

  /// Which edge the selection indicator runs along.
  final FluentTabOrientation orientation;

  /// The icon, if any.
  final Widget? icon;

  /// The label, if any. A tab with no label is an icon-only tab.
  final Widget? label;

  /// Whether this renders as an icon-only tab.
  bool get iconOnly => label == null && icon != null;
}

/// A tab's fully resolved state, including the design axes.
@immutable
class FluentTabState extends FluentTabBaseState {
  /// Creates a resolved state.
  const FluentTabState({
    required super.enabled,
    required super.selected,
    required super.orientation,
    required this.size,
    required this.appearance,
    super.icon,
    super.label,
  });

  /// Height and type ramp.
  final FluentTabSize size;

  /// Fill and shape treatment.
  final FluentTabAppearance appearance;
}

/// Builds the state a tab will be styled and rendered from.
///
/// The first of the three-function recomposition contract.
FluentTabState resolveFluentTabState({
  bool enabled = true,
  bool selected = false,
  FluentTabOrientation orientation = FluentTabOrientation.horizontal,
  FluentTabSize size = FluentTabSize.medium,
  FluentTabAppearance appearance = FluentTabAppearance.transparent,
  Widget? icon,
  Widget? label,
}) => FluentTabState(
  enabled: enabled,
  selected: selected,
  orientation: orientation,
  size: size,
  appearance: appearance,
  icon: icon,
  label: label,
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes. Every colour comes from a Fluent token; nothing
/// here computes one.
///
/// Token sources are the Figma `Horizontal Tab` (`9116:18470`) and
/// `Vertical Tab` (`9116:17973`) component sets, extracted into
/// `test/fixtures/tab.json` and `test/fixtures/vertical_tab.json` and asserted
/// variant-by-variant in the tests.
///
/// ## Why `selected` is branched on rather than resolved
///
/// Fluent's tab tables are two-dimensional: a selected pill hovers to
/// `Brand/Background/2/Hover` while an unselected one hovers to
/// `Neutral/Background/Subtle/Hover`. [FluentStateColor] resolves disabled,
/// then pressed, then hovered, then selected, so a single property cannot hold
/// both ramps — hovering would drop the selected one. Selection therefore picks
/// the ramp here, and [WidgetState.selected] is still reported in the live
/// state set so a caller's own override can key on it.
FluentTabStyle resolveFluentTabStyle(
  FluentTabState state,
  FluentThemeData theme,
) {
  final c = theme.colors;
  final pill = _isPill(state.appearance);
  final selected = state.selected;

  final background = switch (state.appearance) {
    // Disabled is deliberately omitted on the two flat appearances: Figma
    // paints no fill at all on their disabled variants, and falling back to
    // the appearance's own Rest token is the closest honest statement — both
    // are invisible, and both pick up the same high-contrast override.
    FluentTabAppearance.transparent => FluentStateColor.tokens(
      rest: c.transparentBackground,
      hover: c.transparentBackgroundHover,
      pressed: c.transparentBackgroundPressed,
    ),
    FluentTabAppearance.subtle => FluentStateColor.tokens(
      rest: c.subtleBackground,
      hover: c.subtleBackgroundHover,
      pressed: c.subtleBackgroundPressed,
    ),
    FluentTabAppearance.subtleCircular =>
      selected
          ? FluentStateColor.tokens(
              rest: c.brandBackground2,
              hover: c.brandBackground2Hover,
              pressed: c.brandBackground2Pressed,
              disabled: c.neutralBackgroundDisabled,
            )
          : FluentStateColor.tokens(
              rest: c.subtleBackground,
              hover: c.subtleBackgroundHover,
              pressed: c.subtleBackgroundPressed,
              disabled: c.neutralBackgroundDisabled,
            ),
    FluentTabAppearance.filledCircular =>
      selected
          ? FluentStateColor.tokens(
              rest: c.brandBackground,
              hover: c.brandBackgroundHover,
              pressed: c.brandBackgroundPressed,
              disabled: c.neutralBackgroundDisabled,
            )
          : FluentStateColor.tokens(
              rest: c.neutralBackground3,
              hover: c.neutralBackground3Hover,
              pressed: c.neutralBackground3Pressed,
              disabled: c.neutralBackgroundDisabled,
            ),
  };

  final unselectedForeground = FluentStateColor.tokens(
    rest: c.neutralForeground2,
    hover: c.neutralForeground2Hover,
    pressed: c.neutralForeground2Pressed,
    disabled: c.neutralForegroundDisabled,
  );

  final foreground = !selected
      ? unselectedForeground
      : switch (state.appearance) {
          FluentTabAppearance.transparent ||
          FluentTabAppearance.subtle => FluentStateColor.tokens(
            rest: c.neutralForeground1,
            hover: c.neutralForeground1Hover,
            pressed: c.neutralForeground1Pressed,
            disabled: c.neutralForegroundDisabled,
          ),
          FluentTabAppearance.subtleCircular => FluentStateColor.tokens(
            rest: c.brandForeground2,
            hover: c.brandForeground2Hover,
            pressed: c.brandForeground2Pressed,
            disabled: c.neutralForegroundDisabled,
          ),
          FluentTabAppearance.filledCircular => FluentStateColor.tokens(
            rest: c.neutralForegroundOnBrand,
            disabled: c.neutralForegroundDisabled,
          ),
        };

  // The glyph does not follow the label. On every selected variant except the
  // filled pill, Figma binds `Brand/Foreground/Compound/*` to the icon while
  // the label stays neutral or takes `Brand/Foreground/2/*`.
  final icon = !selected
      ? unselectedForeground
      : state.appearance == FluentTabAppearance.filledCircular
      ? FluentStateColor.tokens(
          rest: c.neutralForegroundOnBrand,
          disabled: c.neutralForegroundDisabled,
        )
      : FluentStateColor.tokens(
          rest: c.compoundBrandForeground1,
          hover: c.compoundBrandForeground1Hover,
          pressed: c.compoundBrandForeground1Pressed,
          disabled: c.neutralForegroundDisabled,
        );

  final (border, borderWidth) = switch ((state.appearance, selected)) {
    // Flat tabs are never outlined.
    (FluentTabAppearance.transparent, _) || (FluentTabAppearance.subtle, _) => (
      null,
      const WidgetStatePropertyAll<double?>(FluentStroke.none),
    ),
    (FluentTabAppearance.subtleCircular, true) => (
      FluentStateColor.tokens(
        rest: c.compoundBrandStroke,
        hover: c.compoundBrandStrokeHover,
        pressed: c.compoundBrandStrokePressed,
        disabled: c.neutralStrokeDisabled,
      ),
      const WidgetStatePropertyAll<double?>(FluentStroke.thin),
    ),
    // Unselected, an outline appears only under the pointer. A zero width
    // rather than a transparent token: a transparent stroke would turn opaque
    // in high contrast and outline every resting tab.
    (FluentTabAppearance.subtleCircular, false) => (
      FluentStateColor.tokens(
        rest: c.neutralStroke1,
        hover: c.neutralStroke1Hover,
        pressed: c.neutralStroke1Pressed,
        disabled: c.neutralStrokeDisabled,
      ),
      WidgetStateProperty.resolveWith<double?>(
        (states) =>
            !states.contains(WidgetState.disabled) &&
                (states.contains(WidgetState.pressed) ||
                    states.contains(WidgetState.hovered))
            ? FluentStroke.thin
            : FluentStroke.none,
      ),
    ),
    // The filled pill is outlined only while disabled, where its fill drops to
    // `Neutral/Background/Disabled` and the border is what still reads as a
    // control. Figma leaves the unselected filled pill bare in every state.
    (FluentTabAppearance.filledCircular, true) => (
      FluentStateColor.tokens(rest: c.neutralStrokeDisabled),
      WidgetStateProperty.resolveWith<double?>(
        (states) => states.contains(WidgetState.disabled)
            ? FluentStroke.thin
            : FluentStroke.none,
      ),
    ),
    (FluentTabAppearance.filledCircular, false) => (
      null,
      const WidgetStatePropertyAll<double?>(FluentStroke.none),
    ),
  };

  // Geometry, verbatim from the two Figma sets. The pill row is identical in
  // both orientations; only the flat row moves.
  final horizontal = state.orientation == FluentTabOrientation.horizontal;
  final (padding, gap, extent, iconSize, small) = switch ((
    pill,
    horizontal,
    state.size,
  )) {
    (false, true, FluentTabSize.medium) => (
      const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      FluentSpacing.sNudge,
      44.0,
      FluentSize.size200,
      false,
    ),
    (false, true, FluentTabSize.small) => (
      const EdgeInsets.all(FluentSpacing.sNudge),
      FluentSpacing.xxs,
      32.0,
      FluentSize.size200,
      false,
    ),
    (false, false, FluentTabSize.medium) => (
      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      FluentSpacing.sNudge,
      32.0,
      FluentSize.size200,
      false,
    ),
    (false, false, FluentTabSize.small) => (
      const EdgeInsets.symmetric(
        horizontal: FluentSpacing.sNudge,
        vertical: FluentSpacing.xxs,
      ),
      FluentSpacing.xxs,
      24.0,
      FluentSize.size200,
      false,
    ),
    (true, _, FluentTabSize.medium) => (
      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      FluentSpacing.sNudge,
      32.0,
      FluentSize.size200,
      false,
    ),
    (true, _, FluentTabSize.small) => (
      const EdgeInsets.symmetric(
        horizontal: FluentSpacing.s,
        vertical: FluentSpacing.xs,
      ),
      FluentSpacing.sNudge,
      24.0,
      FluentSize.size160,
      true,
    ),
  };

  // Only the small pill steps down the type ramp; a small flat tab keeps 14/20.
  final text = small
      ? (selected ? theme.typography.caption1Strong : theme.typography.caption1)
      : (selected ? theme.typography.body1Strong : theme.typography.body1);

  final indicatorInset = horizontal
      ? (state.size == FluentTabSize.medium ? FluentSpacing.m : FluentSpacing.s)
      : (state.size == FluentTabSize.medium
            ? FluentSpacing.s
            : FluentSpacing.xs);
  final indicatorThickness = horizontal && state.size == FluentTabSize.small
      ? FluentStroke.thick
      : FluentStroke.thicker;

  final indicator = pill
      ? null
      : selected
      ? FluentStateColor.tokens(
          rest: c.compoundBrandStroke,
          hover: c.compoundBrandStrokeHover,
          pressed: c.compoundBrandStrokePressed,
          disabled: c.neutralForegroundDisabled,
        )
      // Unselected, the bar is a hover affordance only: nothing at rest,
      // nothing while disabled.
      : WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.disabled)) return null;
          if (states.contains(WidgetState.pressed)) {
            return c.neutralStroke1Pressed;
          }
          if (states.contains(WidgetState.hovered)) {
            return c.neutralStroke1Hover;
          }
          return null;
        });

  return FluentTabStyle(
    backgroundColor: background,
    foregroundColor: foreground,
    iconColor: icon,
    borderColor: border,
    borderWidth: borderWidth,
    borderRadius: WidgetStatePropertyAll<BorderRadius?>(
      pill ? FluentRadius.allCircular : FluentRadius.allMedium,
    ),
    // React hard-codes `borderRadiusMedium` for the ring regardless of the
    // tab's own radius; a live probe of a focused flat tab reads `4px`.
    focusRingRadius: WidgetStatePropertyAll<BorderRadius?>(
      pill ? FluentRadius.allCircular : FluentRadius.allMedium,
    ),
    textStyle: WidgetStatePropertyAll<TextStyle?>(text),
    padding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(padding),
    gap: WidgetStatePropertyAll<double?>(gap),
    iconSize: WidgetStatePropertyAll<double?>(iconSize),
    minimumSize: WidgetStatePropertyAll<Size?>(Size(0, extent)),
    indicatorColor: indicator,
    indicatorThickness: WidgetStatePropertyAll<double?>(
      pill ? FluentStroke.none : indicatorThickness,
    ),
    indicatorInset: WidgetStatePropertyAll<double?>(indicatorInset),
    indicatorRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allCircular,
    ),
    mouseCursor: const WidgetStatePropertyAll<MouseCursor?>(
      SystemMouseCursors.click,
    ),
  );
}

/// Renders a tab from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentTabBaseState] rather than [FluentTabState] on purpose: it never reads
/// size or appearance, so a consumer can supply their own style and still use
/// Fluent's rendering, focus ring and indicator.
///
/// [states] is the live interaction set from [FluentInteractive], plus
/// [WidgetState.selected] when the tab is the selected one.
///
/// ## The indicator flip
///
/// [indicatorFlip], [indicatorTranslation] and [indicatorScale] are the three
/// numbers upstream writes into `--fui-Tab__indicator--offset` and
/// `--fui-Tab__indicator--scale`. The bar is placed at its *new* home and then
/// transformed back onto the outgoing tab's, so the whole movement is one
/// decelerating transform rather than a position tween. [indicatorFlip] runs
/// 0 → 1 and interpolates that transform back to the identity; passing null
/// paints the bar where it belongs with no transform at all, which is both the
/// resting case and the reduced-motion one.
Widget buildFluentTab(
  FluentTabBaseState state,
  FluentTabStyle style,
  Set<WidgetState> states, {
  Animation<double>? indicatorFlip,
  double indicatorTranslation = 0,
  double indicatorScale = 1,
}) {
  final horizontal = state.orientation == FluentTabOrientation.horizontal;
  final radius = style.borderRadius?.resolve(states) ?? FluentRadius.allMedium;
  final borderWidth = style.borderWidth?.resolve(states) ?? FluentStroke.none;
  final borderColor = style.borderColor?.resolve(states);
  final background = style.backgroundColor?.resolve(states);
  final foreground = style.foregroundColor?.resolve(states);
  final iconColor = style.iconColor?.resolve(states) ?? foreground;
  final padding = style.padding?.resolve(states) ?? EdgeInsets.zero;
  final gap = style.gap?.resolve(states) ?? FluentSpacing.sNudge;
  final iconSize = style.iconSize?.resolve(states) ?? FluentSize.size200;
  final minimumSize = style.minimumSize?.resolve(states) ?? Size.zero;
  final textStyle = style.textStyle?.resolve(states);

  final children = <Widget>[
    if (state.icon != null)
      IconTheme.merge(
        data: IconThemeData(color: iconColor, size: iconSize),
        child: state.icon!,
      ),
    // Figma wraps the label in a `Tab title` frame inset by
    // `Spacing/Horizontal/XXS` on both sides, on all 160 variants.
    if (state.label != null)
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: FluentSpacing.xxs),
        child: state.label,
      ),
  ];

  Widget content = Row(
    mainAxisSize: MainAxisSize.min,
    // Upstream centres a horizontal tab's content and starts a vertical one's
    // (`useTabStyles.styles.ts` vertical: `justifyContent: 'start'`), which
    // only shows once the list has stretched its tabs to a common width.
    mainAxisAlignment: horizontal
        ? MainAxisAlignment.center
        : MainAxisAlignment.start,
    spacing: state.icon != null && state.label != null ? gap : 0,
    children: children,
  );

  if (textStyle != null || foreground != null) {
    content = DefaultTextStyle.merge(
      style: (textStyle ?? const TextStyle()).copyWith(color: foreground),
      child: content,
    );
  }

  Widget surface = ConstrainedBox(
    constraints: BoxConstraints(
      minHeight: minimumSize.height,
      minWidth: minimumSize.width,
    ),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: radius,
        border: borderWidth > 0 && borderColor != null
            ? Border.all(color: borderColor, width: borderWidth)
            : null,
      ),
      child: Padding(padding: padding, child: content),
    ),
  );

  final indicatorColor = style.indicatorColor?.resolve(states);
  final thickness = style.indicatorThickness?.resolve(states) ?? 0;
  if (indicatorColor != null && thickness > 0) {
    final inset = style.indicatorInset?.resolve(states) ?? 0;
    Widget bar = DecoratedBox(
      decoration: BoxDecoration(
        color: indicatorColor,
        borderRadius:
            style.indicatorRadius?.resolve(states) ?? FluentRadius.allCircular,
      ),
    );

    if (indicatorFlip != null) {
      bar = AnimatedBuilder(
        animation: indicatorFlip,
        // The bar itself never depends on the animation, so it is built once
        // and handed in as `child` rather than rebuilt every frame.
        child: bar,
        builder: (context, child) {
          final remaining = 1 - indicatorFlip.value;
          final offset = indicatorTranslation * remaining;
          final scale = 1 + (indicatorScale - 1) * remaining;
          // Written entry by entry rather than through `translate`/`scale`,
          // which have shifted signatures across vector_math versions. This is
          // T * S: scale about the origin first, then shift.
          final matrix = Matrix4.identity();
          if (horizontal) {
            matrix
              ..setEntry(0, 0, scale)
              ..setEntry(0, 3, offset);
          } else {
            matrix
              ..setEntry(1, 1, scale)
              ..setEntry(1, 3, offset);
          }
          return Transform(
            // Upstream: `transform-origin: left` horizontally, `top`
            // vertically. Physical rather than directional, because the offset
            // is measured from physical layout positions.
            alignment: horizontal ? Alignment.centerLeft : Alignment.topCenter,
            transform: matrix,
            child: child,
          );
        },
      );
    }

    surface = Stack(
      children: <Widget>[
        surface,
        if (horizontal)
          Positioned(
            left: inset,
            right: inset,
            bottom: 0,
            height: thickness,
            child: bar,
          )
        else
          PositionedDirectional(
            start: 0,
            top: inset,
            bottom: inset,
            width: thickness,
            child: bar,
          ),
      ],
    );
  }

  return FluentFocusRing(
    visible: states.contains(WidgetState.focused),
    borderRadius: style.focusRingRadius?.resolve(states) ?? radius,
    child: surface,
  );
}

/// Overrides the tab style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// list's `style`, then the tab's own `style`.
class FluentTabTheme extends InheritedTheme {
  /// Applies [style] to every [FluentTab] in [child].
  const FluentTabTheme({super.key, required this.style, required super.child});

  /// The style layered over the appearance and size defaults.
  final FluentTabStyle style;

  /// The nearest tab style, or null.
  static FluentTabStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentTabTheme>()?.style;

  @override
  bool updateShouldNotify(FluentTabTheme oldWidget) => style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentTabTheme(style: style, child: child);
}

/// Moves the selection by [delta] tabs, skipping disabled ones.
class FluentTabMoveIntent extends Intent {
  /// Creates an intent to move the selection by [delta].
  const FluentTabMoveIntent(this.delta);

  /// How many tabs to move by. Negative moves towards the first tab.
  final int delta;
}

/// Moves the selection to the first or last enabled tab.
class FluentTabEdgeIntent extends Intent {
  /// Creates an intent to jump to an end of the list.
  const FluentTabEdgeIntent({required this.last});

  /// Whether to jump to the last tab rather than the first.
  final bool last;
}

/// The FLIP in flight, as the list hands it to the selected tab.
@immutable
class _TabFlip {
  const _TabFlip({
    required this.value,
    required this.animation,
    required this.translation,
    required this.scale,
  });

  final Object value;
  final Animation<double> animation;
  final double translation;
  final double scale;
}

/// Everything a [FluentTab] needs from the list it sits in.
class _FluentTabScope extends InheritedWidget {
  const _FluentTabScope({
    required this.orientation,
    required this.size,
    required this.appearance,
    required this.selectedValue,
    required this.onSelect,
    required this.listStyle,
    required this.flip,
    required this.focusNodeFor,
    required super.child,
  });

  final FluentTabOrientation orientation;
  final FluentTabSize size;
  final FluentTabAppearance appearance;
  final Object? selectedValue;
  final void Function(Object value)? onSelect;
  final FluentTabStyle? listStyle;
  final _TabFlip? flip;
  final FocusNode Function(Object value) focusNodeFor;

  static _FluentTabScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_FluentTabScope>();
    assert(
      scope != null,
      'FluentTab must be given to a FluentTabList, which is what owns the '
      'selection, the keyboard handling and the indicator animation.',
    );
    return scope!;
  }

  @override
  bool updateShouldNotify(_FluentTabScope oldWidget) =>
      orientation != oldWidget.orientation ||
      size != oldWidget.size ||
      appearance != oldWidget.appearance ||
      selectedValue != oldWidget.selectedValue ||
      onSelect != oldWidget.onSelect ||
      listStyle != oldWidget.listStyle ||
      flip != oldWidget.flip;
}

/// One tab of a [FluentTabList].
///
/// ```dart
/// FluentTab<String>(
///   value: 'home',
///   icon: const Icon(FluentIcons.home_20_regular),
///   child: const Text('Home'),
/// )
/// ```
///
/// A tab is inert on its own: selection, keyboard handling and the indicator
/// animation all belong to the list, and it reads them from the nearest
/// [FluentTabList] ancestor. Constructing one outside a list asserts.
///
/// Pass `enabled: false` to disable it — a real state, not a visual treatment:
/// the tab stops reporting hover and press, refuses focus, is skipped by arrow
/// navigation, and cannot be selected.
class FluentTab<T extends Object> extends StatelessWidget {
  /// Creates a tab with an optional [icon] and a [child] label.
  const FluentTab({
    super.key,
    required this.value,
    this.child,
    this.icon,
    this.enabled = true,
    this.style,
    this.semanticLabel,
  }) : assert(
         child != null || icon != null,
         'A tab needs a label, an icon, or both.',
       );

  /// Identifies this tab within its list. Compared with `==`.
  final T value;

  /// The label. Null for an icon-only tab, which should then carry a
  /// [semanticLabel].
  final Widget? child;

  /// Optional leading icon.
  final Widget? icon;

  /// Whether the tab can be selected.
  final bool enabled;

  /// Overrides layered over the list's style. Merged last, so it wins.
  final FluentTabStyle? style;

  /// Announced by assistive technology. Required in practice for an icon-only
  /// tab, which has no text to announce.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scope = _FluentTabScope.of(context);
    final selected = scope.selectedValue == value;
    final live = enabled && scope.onSelect != null;

    final state = resolveFluentTabState(
      enabled: live,
      selected: selected,
      orientation: scope.orientation,
      size: scope.size,
      appearance: scope.appearance,
      icon: icon,
      label: child,
    );

    // Lowest to highest: defaults, subtree theme, the list's style, then this
    // tab's own.
    final resolved = resolveFluentTabStyle(state, FluentTheme.of(context))
        .merge(FluentTabTheme.maybeOf(context))
        .merge(scope.listStyle)
        .merge(style);

    final flip = scope.flip;
    final flipping = selected && flip != null && flip.value == value;

    return MergeSemantics(
      child: Semantics(
        role: SemanticsRole.tab,
        selected: selected,
        enabled: live,
        label: semanticLabel,
        child: FluentInteractive(
          onPressed: live ? () => scope.onSelect!(value) : null,
          enabled: live,
          focusNode: scope.focusNodeFor(value),
          mouseCursor:
              resolved.mouseCursor?.resolve(const <WidgetState>{}) ??
              SystemMouseCursors.click,
          builder: (context, states, _) => buildFluentTab(
            state,
            resolved,
            selected ? <WidgetState>{...states, WidgetState.selected} : states,
            indicatorFlip: flipping ? flip.animation : null,
            indicatorTranslation: flipping ? flip.translation : 0,
            indicatorScale: flipping ? flip.scale : 1,
          ),
        ),
      ),
    );
  }
}

/// A Fluent 2 tab list.
///
/// ```dart
/// FluentTabList<String>(
///   selectedValue: selected,
///   onSelect: (value) => setState(() => selected = value),
///   tabs: const <FluentTab<String>>[
///     FluentTab<String>(value: 'home', child: Text('Home')),
///     FluentTab<String>(value: 'files', child: Text('Files')),
///   ],
/// )
/// ```
///
/// ## Keyboard
///
/// Arrow keys along the list's own axis move the selection — Fluent selects on
/// arrow rather than only moving focus — and `Home` and `End` jump to the first
/// and last enabled tab. Disabled tabs are skipped and the ends wrap, which is
/// upstream's `useArrowNavigationGroup({ circular: true })`. In a right-to-left
/// horizontal list the arrows are mirrored.
///
/// ## The indicator
///
/// The selection bar animates as a FLIP: it is placed on the newly selected tab
/// and transformed back onto the outgoing one, then released, so the movement
/// is one decelerating `transform` over
/// [FluentMotionSpec.tabIndicator] — 300ms on `curveDecelerateMax`, which is
/// `useTabAnimatedIndicator.styles.ts` verbatim. Under
/// [MediaQuery.disableAnimationsOf] the bar is simply drawn in its new place,
/// matching upstream's `prefers-reduced-motion` rule, which drops the
/// transition entirely.
class FluentTabList<T extends Object> extends StatefulWidget {
  /// Creates a tab list.
  const FluentTabList({
    super.key,
    required this.tabs,
    this.selectedValue,
    this.onSelect,
    this.orientation = FluentTabOrientation.horizontal,
    this.size = FluentTabSize.medium,
    this.appearance = FluentTabAppearance.transparent,
    this.style,
    this.semanticLabel,
  });

  /// The tabs, in reading order.
  final List<FluentTab<T>> tabs;

  /// The selected tab's value, or null when nothing is selected.
  final T? selectedValue;

  /// Invoked with the newly selected value. Null disables every tab.
  final ValueChanged<T>? onSelect;

  /// Which way the list runs.
  final FluentTabOrientation orientation;

  /// Height and type ramp for every tab.
  final FluentTabSize size;

  /// Fill and shape treatment for every tab.
  final FluentTabAppearance appearance;

  /// Overrides layered over the theme defaults for every tab. A tab's own
  /// `style` is merged after this one.
  final FluentTabStyle? style;

  /// Announced by assistive technology as the name of the tab list.
  final String? semanticLabel;

  @override
  State<FluentTabList<T>> createState() => _FluentTabListState<T>();
}

class _FluentTabListState<T extends Object> extends State<FluentTabList<T>>
    with SingleTickerProviderStateMixin {
  final Map<Object, GlobalKey> _keys = <Object, GlobalKey>{};
  final Map<Object, FocusNode> _focusNodes = <Object, FocusNode>{};

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: FluentMotionSpec.tabIndicator.duration,
  );
  late final Animation<double> _flipAnimation = CurvedAnimation(
    parent: _controller,
    curve: FluentMotionSpec.tabIndicator.curve,
  );

  _TabFlip? _flip;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener(_onFlipStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (_reducedMotion && _flip != null) {
      // Reduced motion switched on mid-flight: land now rather than finish.
      _controller.stop();
      setState(() => _flip = null);
    }
  }

  @override
  void didUpdateWidget(FluentTabList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _prune();
    final from = oldWidget.selectedValue;
    final to = widget.selectedValue;
    if (from == to || from == null || to == null) return;
    // The outgoing tab is still laid out from the previous frame, so its rect
    // can be read now; the incoming one cannot be until this frame is done.
    final outgoing = _extentOf(from);
    if (outgoing != null) _scheduleFlip(outgoing, to);
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_onFlipStatus)
      ..dispose();
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _onFlipStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _flip != null && mounted) {
      setState(() => _flip = null);
    }
  }

  void _prune() {
    final live = <Object>{for (final tab in widget.tabs) tab.value};
    _keys.removeWhere((value, _) => !live.contains(value));
    for (final value in _focusNodes.keys.toList()) {
      if (!live.contains(value)) _focusNodes.remove(value)!.dispose();
    }
  }

  GlobalKey _keyFor(Object value) => _keys.putIfAbsent(value, GlobalKey.new);

  FocusNode _focusNodeFor(Object value) =>
      _focusNodes.putIfAbsent(value, () => FocusNode(debugLabel: 'FluentTab'));

  /// The tab's start and length along the list's own axis, in global
  /// coordinates, or null when it is not laid out.
  (double, double)? _extentOf(Object value) {
    final box = _keys[value]?.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    final origin = box.localToGlobal(Offset.zero);
    return widget.orientation == FluentTabOrientation.horizontal
        ? (origin.dx, box.size.width)
        : (origin.dy, box.size.height);
  }

  double get _indicatorInset {
    final style = resolveFluentTabStyle(
      resolveFluentTabState(
        selected: true,
        orientation: widget.orientation,
        size: widget.size,
        appearance: widget.appearance,
      ),
      FluentTheme.of(context),
    ).merge(FluentTabTheme.maybeOf(context)).merge(widget.style);
    return style.indicatorInset?.resolve(const <WidgetState>{}) ?? 0;
  }

  void _scheduleFlip((double, double) outgoing, T to) {
    // Upstream clamps the transition to 0.01ms under prefers-reduced-motion,
    // which is a jump. Not starting the controller at all is the same picture
    // with no frame scheduled.
    if (_reducedMotion) return;
    // Measured synchronously off the previous frame's layout, which already
    // holds both tabs at the positions the flip needs — selection changes a
    // tab's paint, not its box. Deferring to addPostFrameCallback let one
    // frame paint the bar already at its destination, which reads as a flash
    // before the flip runs.
    final incoming = _extentOf(to);
    if (incoming == null) return;
    final inset = _indicatorInset;
    final fromLength = outgoing.$2 - 2 * inset;
    final toLength = incoming.$2 - 2 * inset;
    if (fromLength <= 0 || toLength <= 0) return;
    // No setState: this runs from didUpdateWidget, so a rebuild is already in
    // flight and marking dirty again would be an error.
    _flip = _TabFlip(
      value: to,
      animation: _flipAnimation,
      translation: outgoing.$1 - incoming.$1,
      scale: fromLength / toLength,
    );
    _controller.forward(from: 0);
  }

  void _select(T value) {
    widget.onSelect?.call(value);
    _focusNodeFor(value).requestFocus();
  }

  void _move(int delta) {
    final tabs = widget.tabs;
    var index = tabs.indexWhere((tab) => tab.value == widget.selectedValue);
    // With nothing selected, an arrow enters the list from the near end.
    if (index < 0) index = delta > 0 ? -1 : tabs.length;
    // The ends wrap: upstream's `useTabList` builds its arrow handling with
    // `useArrowNavigationGroup({ circular: true, ... })`, and a live probe of
    // components-tablist--appearance walks index 3 -> 0 on ArrowRight. One lap
    // at most — a list with no other enabled tab has nowhere to go.
    for (var step = 1; step <= tabs.length; step++) {
      final next = (index + delta * step) % tabs.length;
      if (next == index) break;
      if (tabs[next].enabled) {
        _select(tabs[next].value);
        return;
      }
    }
  }

  void _edge({required bool last}) {
    final tabs = last ? widget.tabs.reversed : widget.tabs;
    for (final tab in tabs) {
      if (tab.enabled) {
        _select(tab.value);
        return;
      }
    }
  }

  Map<ShortcutActivator, Intent> get _shortcuts =>
      widget.orientation == FluentTabOrientation.horizontal
      ? const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.arrowLeft): FluentTabMoveIntent(
            -1,
          ),
          SingleActivator(LogicalKeyboardKey.arrowRight): FluentTabMoveIntent(
            1,
          ),
          SingleActivator(LogicalKeyboardKey.home): FluentTabEdgeIntent(
            last: false,
          ),
          SingleActivator(LogicalKeyboardKey.end): FluentTabEdgeIntent(
            last: true,
          ),
        }
      : const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.arrowUp): FluentTabMoveIntent(-1),
          SingleActivator(LogicalKeyboardKey.arrowDown): FluentTabMoveIntent(1),
          SingleActivator(LogicalKeyboardKey.home): FluentTabEdgeIntent(
            last: false,
          ),
          SingleActivator(LogicalKeyboardKey.end): FluentTabEdgeIntent(
            last: true,
          ),
        };

  @override
  Widget build(BuildContext context) {
    final horizontal = widget.orientation == FluentTabOrientation.horizontal;
    // Only the pill appearances space their tabs; the flat ones butt together
    // so the indicator reads as one rule under the whole list.
    final gap = _isPill(widget.appearance)
        ? (widget.size == FluentTabSize.medium
              ? FluentSpacing.s
              : FluentSpacing.sNudge)
        : FluentSpacing.none;

    final children = <Widget>[
      for (final tab in widget.tabs)
        KeyedSubtree(key: _keyFor(tab.value), child: tab),
    ];

    final Widget row = horizontal
        ? Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: gap,
            children: children,
          )
        // A vertical list stretches its tabs to one common width:
        // `useTabListStyles.styles.ts` sets `vertical: { alignItems:
        // 'stretch' }`, and a probe of components-tablist--vertical measures
        // all four tabs at 97.94 despite their different labels. IntrinsicWidth
        // is what gives the column the shrink-to-widest box a CSS flex column
        // has — stretch alone would take the whole incoming width.
        : IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: gap,
              children: children,
            ),
          );

    return Shortcuts(
      shortcuts: _shortcuts,
      child: Actions(
        actions: <Type, Action<Intent>>{
          FluentTabMoveIntent: CallbackAction<FluentTabMoveIntent>(
            onInvoke: (intent) {
              final mirrored =
                  horizontal && Directionality.of(context) == TextDirection.rtl;
              _move(mirrored ? -intent.delta : intent.delta);
              return null;
            },
          ),
          FluentTabEdgeIntent: CallbackAction<FluentTabEdgeIntent>(
            onInvoke: (intent) {
              _edge(last: intent.last);
              return null;
            },
          ),
        },
        child: _FluentTabScope(
          orientation: widget.orientation,
          size: widget.size,
          appearance: widget.appearance,
          selectedValue: widget.selectedValue,
          // Routed through _select rather than straight to the callback so a
          // pointer selection also moves focus onto the tab, the way clicking
          // a button does in a browser. The ring does not appear: focus
          // arriving by pointer never raises WidgetState.focused.
          onSelect: widget.onSelect == null
              ? null
              : (value) => _select(value as T),
          listStyle: widget.style,
          flip: _flip,
          focusNodeFor: _focusNodeFor,
          child: Semantics(
            role: SemanticsRole.tabBar,
            container: true,
            explicitChildNodes: true,
            label: widget.semanticLabel,
            child: row,
          ),
        ),
      ),
    );
  }
}
