import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../internal/animated_style.dart';
import '../internal/input_modality.dart';
import '../internal/interaction.dart';
import '../l10n/l10n.dart';
import 'breadcrumb_style.dart';

/// Crumb height and type ramp. Figma's `Size` axis.
enum FluentBreadcrumbSize {
  /// 24 high, `caption1` type.
  small,

  /// 32 high, `body1` type. The default.
  medium,

  /// 40 high, `body2` type.
  large,
}

/// The chevron Figma draws between two crumbs, per size.
///
/// 12 / 16 / 20, which is both the Figma `Divider` frame and upstream's
/// `useBreadcrumbDividerStyles` (`fontSize: '12px' | '16px' | '20px'`).
IconData fluentBreadcrumbSeparatorIcon(FluentBreadcrumbSize size) =>
    switch (size) {
      FluentBreadcrumbSize.small => FluentIcons.chevron_right_12_regular,
      FluentBreadcrumbSize.medium => FluentIcons.chevron_right_16_regular,
      FluentBreadcrumbSize.large => FluentIcons.chevron_right_20_regular,
    };

/// The glyph on the overflow trigger, per size.
///
/// The Figma `Type=Overflow` variants hold a 20 / 20 / 24 icon slot — small and
/// medium genuinely share the 20, which is why this is a table and not the
/// crumb's own 12 / 16 / 20 icon ramp.
IconData fluentBreadcrumbOverflowIcon(FluentBreadcrumbSize size) =>
    switch (size) {
      FluentBreadcrumbSize.small ||
      FluentBreadcrumbSize.medium => FluentIcons.more_horizontal_20_regular,
      FluentBreadcrumbSize.large => FluentIcons.more_horizontal_24_regular,
    };

/// One entry in a breadcrumb trail.
///
/// Data, not a widget — the trail decides which entries are rendered inline,
/// which are folded into the overflow popup, and which one is the current page.
@immutable
class FluentBreadcrumbItem {
  /// Creates a crumb.
  const FluentBreadcrumbItem({
    required this.label,
    this.icon,
    this.onPressed,
    this.enabled = true,
    this.semanticLabel,
  });

  /// The crumb text.
  final Widget label;

  /// Optional leading icon. Figma's `Icon=ON` axis, which also tightens the
  /// crumb's leading inset.
  final Widget? icon;

  /// Invoked on tap and on Space or Enter.
  ///
  /// Ignored on the last crumb, which is the current page and is never
  /// interactive — upstream sets `aria-disabled` on it for the same reason.
  final VoidCallback? onPressed;

  /// Whether this crumb responds to input at all.
  ///
  /// False is a real state, not a treatment: the crumb stops reporting hover
  /// and press, refuses focus, and swaps to the disabled token ramp.
  final bool enabled;

  /// Announced by assistive technology in place of [label].
  final String? semanticLabel;
}

/// Everything needed to render one crumb, independent of the design axis.
///
/// The counterpart of `FluentButtonBaseState`. [buildFluentBreadcrumb] takes
/// this rather than [FluentBreadcrumbState], which is what makes "Fluent's
/// state, my own styling, Fluent's rendering" a supported path rather than a
/// fork.
@immutable
class FluentBreadcrumbBaseState {
  /// Creates a base state.
  const FluentBreadcrumbBaseState({
    required this.enabled,
    required this.current,
    required this.overflow,
    this.label,
    this.icon,
    this.separator,
  });

  /// Whether this crumb responds to input.
  final bool enabled;

  /// Whether this is the current page: semibold, and not interactive.
  ///
  /// Figma's `States=Current`. Upstream maps the same flag to
  /// `aria-current="page"` plus `aria-disabled`.
  final bool current;

  /// Whether this is the overflow trigger rather than a real crumb.
  ///
  /// Figma's `Type=Overflow`: a square, icon-only button with no label.
  final bool overflow;

  /// The crumb text. Null on the overflow trigger.
  final Widget? label;

  /// The leading icon, or the overflow glyph.
  final Widget? icon;

  /// The trailing chevron, or null on the last crumb.
  ///
  /// The separator belongs to the crumb, not to the trail: Figma nests the
  /// `Divider` frame inside `.Breadcrumb Item` and simply omits it on
  /// `States=Current`, which is why the trail's own `itemSpacing` is zero.
  final Widget? separator;
}

/// A crumb's fully resolved state, including the design axis.
///
/// The counterpart of `FluentButtonState`: base state plus exactly [size].
@immutable
class FluentBreadcrumbState extends FluentBreadcrumbBaseState {
  /// Creates a resolved state.
  const FluentBreadcrumbState({
    required super.enabled,
    required super.current,
    required super.overflow,
    required this.size,
    super.label,
    super.icon,
    super.separator,
  });

  /// Height and type ramp.
  final FluentBreadcrumbSize size;
}

/// Builds the state one crumb will be styled and rendered from.
///
/// Separated so a consumer can reuse Fluent's state resolution while
/// substituting their own styling — the first of the three-function
/// recomposition contract.
FluentBreadcrumbState resolveFluentBreadcrumbState({
  bool enabled = true,
  bool current = false,
  bool overflow = false,
  FluentBreadcrumbSize size = FluentBreadcrumbSize.medium,
  Widget? label,
  Widget? icon,
  Widget? separator,
}) => FluentBreadcrumbState(
  enabled: enabled,
  current: current,
  overflow: overflow,
  size: size,
  label: label,
  icon: icon,
  separator: separator,
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axis. Every value comes from a Fluent token; nothing
/// here computes a colour.
///
/// Token sources are the Figma `.Breadcrumb Item` set (node `9077:5740`, 51
/// variants over `Size` x `Type` x `States` x `Icon`), extracted into
/// `test/fixtures/breadcrumb.json` and asserted variant-by-variant in the
/// tests. The enclosing `Breadcrumb` set (`9077:5931`) contributes exactly one
/// number — `itemSpacing` bound to `Spacing/Horizontal/None` — because the
/// separator lives inside the crumb.
///
/// ## Why this is not `FluentButton(appearance: subtle)`
///
/// A crumb *is* a subtle button in both Figma and upstream
/// (`useBreadcrumbButton` returns `appearance: 'subtle', shape: 'rounded'`),
/// but five of its six styled properties diverge from
/// `resolveFluentButtonStyle`, so composing the button would mean overriding
/// almost all of it:
///
/// * the **icon** takes a brand ramp on hover and press while the **label**
///   holds at `Neutral/Foreground/2/Rest` — two ramps where a button has one;
/// * the leading inset shrinks when an icon is present (4 / 2 / 0 rather than
///   the trailing 8 / 6 / 6), so the horizontal padding is asymmetric;
/// * the type ramp is regular at every size and only the current crumb is
///   semibold, where a button is semibold throughout;
/// * `Neutral/Foreground/1/Pressed` is the pressed label, with no hover step;
/// * the horizontal padding ramp is 8 / 6 / 6, not the button's 16 / 12 / 8.
///
/// It is also not a `FluentLink`: Figma gives it a filled surface, a corner
/// radius and a focus ring, and never underlines it.
FluentBreadcrumbStyle resolveFluentBreadcrumbStyle(
  FluentBreadcrumbState state,
  FluentThemeData theme,
) {
  final c = theme.colors;

  // Geometry, verbatim from the `.Breadcrumb Item` set. `inset` is the crumb's
  // symmetric inset; `leadingInset` is what Figma binds on `paddingLeft` when
  // `Icon=ON`, which is a smaller stop because the glyph carries its own
  // optical margin.
  final (
    height,
    inset,
    verticalInset,
    leadingInset,
    gap,
    iconSize,
    separatorSize,
  ) = switch (state.size) {
    FluentBreadcrumbSize.small => (
      24.0,
      FluentSpacing.sNudge,
      FluentSpacing.xxs,
      FluentSpacing.none,
      FluentSpacing.none,
      FluentSize.size120,
      FluentSize.size120,
    ),
    FluentBreadcrumbSize.medium => (
      32.0,
      FluentSpacing.sNudge,
      FluentSpacing.sNudge,
      FluentSpacing.xxs,
      FluentSpacing.xxs,
      FluentSize.size160,
      FluentSize.size160,
    ),
    FluentBreadcrumbSize.large => (
      40.0,
      FluentSpacing.s,
      FluentSpacing.s,
      FluentSpacing.xs,
      FluentSpacing.xs,
      FluentSize.size200,
      FluentSize.size200,
    ),
  };

  // The overflow trigger is square-padded on all four sides and holds its own
  // glyph ramp: 20 at small and medium, 24 at large.
  final (overflowInset, overflowIconSize) = switch (state.size) {
    FluentBreadcrumbSize.small => (FluentSpacing.xxs, FluentSize.size200),
    FluentBreadcrumbSize.medium => (FluentSpacing.sNudge, FluentSize.size200),
    FluentBreadcrumbSize.large => (FluentSpacing.s, FluentSize.size240),
  };

  final (regular, strong) = switch (state.size) {
    FluentBreadcrumbSize.small => (
      theme.typography.caption1,
      theme.typography.caption1Strong,
    ),
    FluentBreadcrumbSize.medium => (
      theme.typography.body1,
      theme.typography.body1Strong,
    ),
    // 16/22 semibold is `subtitle2`, which is what upstream names for the large
    // current crumb too.
    FluentBreadcrumbSize.large => (
      theme.typography.body2,
      theme.typography.subtitle2,
    ),
  };

  final EdgeInsetsGeometry padding = state.overflow
      ? EdgeInsets.all(overflowInset)
      : EdgeInsets.fromLTRB(
          state.icon == null ? inset : leadingInset,
          verticalInset,
          inset,
          verticalInset,
        );

  return FluentBreadcrumbStyle(
    // Disabled binds the same token as Rest rather than a transparent literal:
    // Figma removes the disabled crumb's fill outright, and `subtleBackground`
    // is the token that renders as nothing in every theme *and* follows the
    // high-contrast override the way a hardcoded transparent colour would not.
    backgroundColor: FluentStateColor.tokens(
      rest: c.subtleBackground,
      hover: c.subtleBackgroundHover,
      pressed: c.subtleBackgroundPressed,
      disabled: c.subtleBackground,
    ),
    // No hover step, and that is Figma's reading rather than an omission: all
    // 51 variants bind `Neutral/Foreground/2/Rest` on the label in Rest, Hover
    // and Focused alike. Only press moves it.
    foregroundColor: FluentStateColor.tokens(
      rest: c.neutralForeground2,
      pressed: c.neutralForeground1Pressed,
      disabled: c.neutralForegroundDisabled,
    ),
    iconColor: FluentStateColor.tokens(
      rest: c.neutralForeground2,
      hover: c.neutralForeground2BrandHover,
      pressed: c.neutralForeground2BrandPressed,
      disabled: c.neutralForegroundDisabled,
    ),
    // The chevron never changes: every one of the 51 variants binds
    // `Neutral/Foreground/2/Rest` on it, disabled crumbs included. It separates
    // two crumbs rather than belonging to either.
    separatorColor: FluentStateColor.tokens(rest: c.neutralForeground2),
    // `Button/Container` -> the `Shape` collection's `Rounded` mode ->
    // `Corner radius/Medium`.
    borderRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allMedium,
    ),
    textStyle: WidgetStatePropertyAll<TextStyle?>(
      state.current ? strong : regular,
    ),
    padding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(padding),
    gap: WidgetStatePropertyAll<double?>(gap),
    iconSize: WidgetStatePropertyAll<double?>(
      state.overflow ? overflowIconSize : iconSize,
    ),
    separatorSize: WidgetStatePropertyAll<double?>(separatorSize),
    minimumSize: WidgetStatePropertyAll<Size?>(
      // Square at the same height for the overflow trigger, which is how Figma
      // draws it: 24, 32 and 40 on both axes.
      state.overflow ? Size(height, height) : Size(0, height),
    ),
    mouseCursor: const WidgetStatePropertyAll<MouseCursor?>(
      SystemMouseCursors.click,
    ),
    // The overflow popup has no Figma counterpart — the design file ships the
    // trigger only — so its surface takes the same tokens the rest of this
    // package's popups take, which is also what upstream's `MenuPopover` uses.
    surfaceColor: FluentStateColor.tokens(rest: c.neutralBackground1),
    surfaceBorderColor: FluentStateColor.tokens(rest: c.transparentStroke),
    surfaceBorderWidth: const WidgetStatePropertyAll<double?>(
      FluentStroke.thin,
    ),
    surfaceRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allMedium,
    ),
    surfacePadding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.all(FluentSpacing.xs),
    ),
    surfaceGap: const WidgetStatePropertyAll<double?>(FluentSpacing.xxs),
    surfaceShadow: WidgetStatePropertyAll<List<BoxShadow>?>(
      theme.shadow(FluentElevation.shadow16),
    ),
    // ponytail: no upstream maximum exists — the browser clamps to the viewport
    // through a positioning layer with no counterpart here. 300 keeps a long
    // trail on screen; override `surfaceMaxHeight` if it should grow further.
    surfaceMaxHeight: const WidgetStatePropertyAll<double?>(300),
    surfaceOffset: const WidgetStatePropertyAll<double?>(FluentSpacing.none),
  );
}

/// Renders one crumb from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentBreadcrumbBaseState] rather than [FluentBreadcrumbState] on purpose:
/// it never reads the size, so a consumer can supply their own style and still
/// use Fluent's layout, focus ring and surface animation.
///
/// ## Motion
///
/// Exactly one thing animates, and it is the crumb's fill.
/// `useBreadcrumbStyles.styles.ts`, `useBreadcrumbButtonStyles.styles.ts` and
/// `useBreadcrumbDividerStyles.styles.ts` declare **no** transition, animation
/// or `motionTokens` reference between them — but `useBreadcrumbButton` returns
/// `appearance: 'subtle'` and the crumb is rendered through the Button styles,
/// whose root transitions `background`, `border` and `color` at
/// `durationFaster` on `curveEasyEase`. So the surface inherits
/// [FluentMotionSpec.buttonSurface] and nothing else moves: the separator, the
/// type ramp and the overflow popup all change on the frame the input arrives.
///
/// [FluentAnimatedStyle] clamps that transition to zero under
/// [MediaQuery.disableAnimationsOf], so reduced motion lands the fill on its
/// target immediately.
///
/// [states] is the live interaction set from [FluentInteractive].
Widget buildFluentBreadcrumb(
  FluentBreadcrumbBaseState state,
  FluentBreadcrumbStyle style,
  Set<WidgetState> states,
) {
  final radius = style.borderRadius?.resolve(states) ?? FluentRadius.allMedium;
  final foreground = style.foregroundColor?.resolve(states);
  final iconColor = style.iconColor?.resolve(states);
  final separatorColor = style.separatorColor?.resolve(states);
  final textStyle = style.textStyle?.resolve(states);
  final padding = style.padding?.resolve(states) ?? EdgeInsets.zero;
  final gap = style.gap?.resolve(states) ?? FluentSpacing.none;
  final iconSize = style.iconSize?.resolve(states) ?? FluentSize.size160;
  final separatorSize =
      style.separatorSize?.resolve(states) ?? FluentSize.size160;
  final minimumSize = style.minimumSize?.resolve(states) ?? Size.zero;

  final icon = state.icon;
  final label = state.label;

  Widget content = Row(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    spacing: icon != null && label != null ? gap : 0,
    children: <Widget>[
      if (icon != null)
        IconTheme.merge(
          data: IconThemeData(color: iconColor, size: iconSize),
          child: icon,
        ),
      ?label,
    ],
  );

  if (textStyle != null || foreground != null) {
    content = DefaultTextStyle.merge(
      style: (textStyle ?? const TextStyle()).copyWith(color: foreground),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      child: content,
    );
  }

  // A crumb's ring is drawn INSIDE its own box, which is why this is a
  // foreground border rather than a `FluentFocusRing`: that widget paints its
  // 2px band outside the child. `BreadcrumbButton` composes
  // `useButtonStyles_unstable`, whose focus indicator is a 1px
  // `colorStrokeFocus2` border plus `boxShadow: 0 0 0 1px colorStrokeFocus2
  // inset` — 2px of `strokeFocus2` running from the box edge inward, with the
  // outline itself set to `colorTransparentStroke` so nothing shows outside.
  // Figma's own `Focus ring` frame is likewise drawn at the crumb's size (37x32
  // inside a 37x32 button), not inflated.
  final focusRing = states.contains(WidgetState.focused);

  final surface = FluentAnimatedStyle<Color>(
    value: style.backgroundColor?.resolve(states) ?? const Color(0x00000000),
    spec: FluentMotionSpec.buttonSurface,
    lerp: fluentLerpColor,
    builder: (context, background) {
      final Widget filled = ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: minimumSize.height,
          minWidth: minimumSize.width,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(color: background, borderRadius: radius),
          child: Padding(padding: padding, child: content),
        ),
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

  final separator = state.separator;
  if (separator == null) return surface;

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      surface,
      // The chevron is announced by nobody: it is punctuation between two
      // crumbs, and a screen reader already has the list structure.
      ExcludeSemantics(
        child: SizedBox.square(
          dimension: separatorSize,
          child: IconTheme.merge(
            data: IconThemeData(color: separatorColor, size: separatorSize),
            child: separator,
          ),
        ),
      ),
    ],
  );
}

/// Renders the overflow popup surface [child] sits on.
///
/// Separate from [buildFluentBreadcrumb] because the two are rendered into
/// different branches of the tree: the trail into the caller's subtree, this
/// into the [Overlay]. Both read the same [FluentBreadcrumbStyle].
Widget buildFluentBreadcrumbSurface(
  FluentBreadcrumbStyle style,
  Set<WidgetState> states,
  Widget child,
) {
  final radius = style.surfaceRadius?.resolve(states) ?? FluentRadius.allMedium;
  final borderWidth =
      style.surfaceBorderWidth?.resolve(states) ?? FluentStroke.none;
  final borderColor = style.surfaceBorderColor?.resolve(states);
  final maxHeight = style.surfaceMaxHeight?.resolve(states) ?? double.infinity;

  return ConstrainedBox(
    constraints: BoxConstraints(maxHeight: maxHeight),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: style.surfaceColor?.resolve(states),
        borderRadius: radius,
        border: borderWidth > 0 && borderColor != null
            ? Border.all(color: borderColor, width: borderWidth)
            : null,
        boxShadow: style.surfaceShadow?.resolve(states),
      ),
      child: Padding(
        padding: style.surfacePadding?.resolve(states) ?? EdgeInsets.zero,
        child: child,
      ),
    ),
  );
}

/// Overrides the breadcrumb style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`.
class FluentBreadcrumbTheme extends InheritedTheme {
  /// Applies [style] to every [FluentBreadcrumb] in [child].
  const FluentBreadcrumbTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the size defaults.
  final FluentBreadcrumbStyle style;

  /// The nearest breadcrumb style, or null.
  static FluentBreadcrumbStyle? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FluentBreadcrumbTheme>()
      ?.style;

  @override
  bool updateShouldNotify(FluentBreadcrumbTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentBreadcrumbTheme(style: style, child: child);
}

/// Moves the active row of an open overflow popup by [delta].
class FluentBreadcrumbMoveIntent extends Intent {
  /// Creates an intent to move the active row.
  const FluentBreadcrumbMoveIntent(this.delta);

  /// How many rows to move. Negative walks towards the top of the list.
  final int delta;
}

/// Opens the overflow popup, or activates its active row when already open.
class FluentBreadcrumbActivateIntent extends Intent {
  /// Creates an activation intent.
  const FluentBreadcrumbActivateIntent();
}

/// How [FluentBreadcrumb] splits a trail that is too long to show whole.
///
/// The port of upstream's `partitionBreadcrumbItems`: the first crumb stays
/// pinned, the tail stays visible, and everything between them folds into the
/// overflow popup.
@immutable
class FluentBreadcrumbPartition {
  /// Splits [items] so that at most [maxDisplayedItems] stay inline.
  ///
  /// A non-positive or large enough [maxDisplayedItems] leaves the trail whole
  /// and [overflow] empty.
  factory FluentBreadcrumbPartition(
    List<FluentBreadcrumbItem> items, {
    int? maxDisplayedItems,
  }) {
    final max = maxDisplayedItems;
    if (max == null || max <= 0 || items.length <= max) {
      return FluentBreadcrumbPartition._(items, const <FluentBreadcrumbItem>[]);
    }
    // ponytail: upstream's `overflowIndex` is pinned at its default of 1 — the
    // first crumb is the root and is the one worth keeping. Widen this to a
    // parameter if a caller ever needs two pinned crumbs.
    const pinned = 1;
    if (max == pinned) {
      return FluentBreadcrumbPartition._(
        items.sublist(0, pinned),
        items.sublist(pinned),
      );
    }
    final tail = items.length - (max - pinned);
    return FluentBreadcrumbPartition._(<FluentBreadcrumbItem>[
      ...items.sublist(0, pinned),
      ...items.sublist(tail),
    ], items.sublist(pinned, tail));
  }

  const FluentBreadcrumbPartition._(this.displayed, this.overflow);

  /// The crumbs rendered inline, in order. The overflow trigger, when there is
  /// one, sits after the first of them.
  final List<FluentBreadcrumbItem> displayed;

  /// The crumbs folded into the overflow popup, in order. Empty when the whole
  /// trail fits.
  final List<FluentBreadcrumbItem> overflow;
}

/// A Fluent 2 breadcrumb trail.
///
/// ```dart
/// FluentBreadcrumb(
///   items: <FluentBreadcrumbItem>[
///     FluentBreadcrumbItem(
///       label: const Text('Home'),
///       icon: const Icon(FluentIcons.home_20_regular),
///       onPressed: () => go('/'),
///     ),
///     FluentBreadcrumbItem(
///       label: const Text('Reports'),
///       onPressed: () => go('/reports'),
///     ),
///     const FluentBreadcrumbItem(label: Text('Q3')),
///   ],
/// )
/// ```
///
/// The **last** crumb is the current page: it is drawn semibold, it carries no
/// separator, it refuses focus and its `onPressed` is never called — matching
/// upstream, which puts `aria-current="page"` and `aria-disabled` on it. Every
/// other crumb is a link.
///
/// ## Truncation
///
/// Set [maxDisplayedItems] to fold the middle of a long trail behind an
/// overflow trigger. The first crumb stays pinned and the tail stays visible,
/// which is upstream's `partitionBreadcrumbItems` with its default
/// `overflowIndex`; [FluentBreadcrumbPartition] is public so the same split can
/// be computed without rendering anything.
///
/// The overflow popup is an [OverlayEntry] anchored with
/// [CompositedTransformFollower], so it escapes any ancestor clip. `FluentTheme`
/// is an [InheritedTheme] and the themes between this widget and the overlay are
/// captured on the way in, so a `FluentThemeOverride` or a
/// [FluentBreadcrumbTheme] wrapping the trail reaches the popup's rows too.
///
/// ## Keyboard
///
/// | Key | Trail | Overflow trigger, closed | Overflow trigger, open |
/// |---|---|---|---|
/// | Tab | moves between crumbs | moves on | closes, then moves on |
/// | Enter / Space | follows the crumb | opens | follows the active row |
/// | Down / Up | — | opens | moves the active row |
/// | Escape | — | — | closes, focus stays on the trigger |
///
/// Focus never enters the popup: the rows are deliberately outside the
/// traversal order, so "focus returns to the trigger on close" is structural
/// rather than something this widget has to remember to do. The active row is
/// still marked [WidgetState.focused], because that is what keyboard-visible
/// focus *means* to the user. There is no Tab trap — a menu is not a dialog.
///
/// Customisation follows the usual three rungs. [style] is merged last and
/// wins; [FluentBreadcrumbTheme] restyles a subtree; and
/// [resolveFluentBreadcrumbState], [resolveFluentBreadcrumbStyle] and
/// [buildFluentBreadcrumb] are public so any one of them can be replaced
/// without forking this widget.
class FluentBreadcrumb extends StatefulWidget {
  /// Creates a trail over [items]. The last is the current page.
  const FluentBreadcrumb({
    super.key,
    required this.items,
    this.size = FluentBreadcrumbSize.medium,
    this.maxDisplayedItems,
    this.style,
    this.semanticLabel,
  });

  /// The trail, root first. The last entry is the current page.
  final List<FluentBreadcrumbItem> items;

  /// Height and type ramp.
  final FluentBreadcrumbSize size;

  /// How many crumbs may stay inline before the middle folds into the overflow
  /// popup. Null shows the whole trail.
  final int? maxDisplayedItems;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentBreadcrumbStyle? style;

  /// Announced by assistive technology for the trail as a whole.
  ///
  /// The counterpart of upstream's `<nav aria-label>`. Defaults to nothing,
  /// because a page with one trail needs no label to disambiguate it.
  final String? semanticLabel;

  @override
  State<FluentBreadcrumb> createState() => _FluentBreadcrumbState();
}

class _FluentBreadcrumbState extends State<FluentBreadcrumb> {
  final LayerLink _link = LayerLink();
  final FocusNode _overflowFocus = FocusNode(debugLabel: 'FluentBreadcrumb');
  OverlayEntry? _entry;
  int? _active;

  bool get _open => _entry != null;

  FluentBreadcrumbPartition get _partition => FluentBreadcrumbPartition(
    widget.items,
    maxDisplayedItems: widget.maxDisplayedItems,
  );

  @override
  void initState() {
    super.initState();
    _overflowFocus.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(FluentBreadcrumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_open) {
      if (_partition.overflow.isEmpty) {
        _deferOrRun(_close);
      } else {
        _entry!.markNeedsBuild();
      }
    }
  }

  @override
  void dispose() {
    _overflowFocus
      ..removeListener(_handleFocusChange)
      ..dispose();
    _entry
      ?..remove()
      ..dispose();
    _entry = null;
    super.dispose();
  }

  /// Runs [action] now, unless a build is in flight.
  ///
  /// Inserting or removing an [OverlayEntry] is a `setState` on the [Overlay],
  /// which sits in a different branch of the tree and has usually been built by
  /// the time this widget rebuilds.
  void _deferOrRun(VoidCallback action) {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) action();
      });
      return;
    }
    action();
  }

  void _handleFocusChange() {
    // Tab, or a click on something else, takes focus away; the popup must not
    // outlive it.
    if (!_overflowFocus.hasFocus && _open) _deferOrRun(_close);
  }

  void _openPopup({int? active}) {
    if (_open || _partition.overflow.isEmpty) return;
    final overlay = Overlay.of(context, debugRequiredFor: widget);
    // FluentTheme is an InheritedTheme, so this carries it — and any other
    // InheritedTheme between here and the overlay, FluentBreadcrumbTheme
    // included — across the boundary.
    final captured = InheritedTheme.capture(from: context, to: overlay.context);
    _active = active;
    _entry = OverlayEntry(builder: (_) => captured.wrap(_buildPopup()));
    overlay.insert(_entry!);
    setState(() {});
  }

  void _close() {
    final entry = _entry;
    if (entry == null) return;
    _entry = null;
    _active = null;
    entry
      ..remove()
      ..dispose();
    if (mounted) setState(() {});
  }

  void _toggle() => _open ? _close() : _openPopup();

  void _select(FluentBreadcrumbItem item) {
    _close();
    if (item.enabled) item.onPressed?.call();
  }

  /// The first selectable row at or after [from], walking by [delta].
  int? _seek(int from, int delta) {
    final rows = _partition.overflow;
    for (var i = from; i >= 0 && i < rows.length; i += delta) {
      if (rows[i].enabled) return i;
    }
    return null;
  }

  void _move(int delta) {
    if (!_open) {
      _openPopup(
        active: _seek(delta > 0 ? 0 : _partition.overflow.length - 1, delta),
      );
      return;
    }
    final from =
        (_active ?? (delta > 0 ? -1 : _partition.overflow.length)) + delta;
    final next = _seek(from, delta);
    if (next == null || next == _active) return;
    _active = next;
    _entry?.markNeedsBuild();
  }

  void _activate() {
    if (!_open) {
      _openPopup();
      return;
    }
    final index = _active;
    final rows = _partition.overflow;
    if (index != null && index < rows.length && rows[index].enabled) {
      _select(rows[index]);
    } else {
      _close();
    }
  }

  FluentBreadcrumbStyle _styleFor(FluentBreadcrumbState state) =>
      resolveFluentBreadcrumbStyle(
        state,
        FluentTheme.of(context),
      ).merge(FluentBreadcrumbTheme.maybeOf(context)).merge(widget.style);

  FluentBreadcrumbState _overflowState() => resolveFluentBreadcrumbState(
    overflow: true,
    size: widget.size,
    icon: Icon(fluentBreadcrumbOverflowIcon(widget.size)),
    separator: Icon(fluentBreadcrumbSeparatorIcon(widget.size)),
  );

  Widget _buildCrumb(FluentBreadcrumbItem item, {required bool current}) {
    final state = resolveFluentBreadcrumbState(
      enabled: !current && item.enabled && item.onPressed != null,
      current: current,
      size: widget.size,
      label: item.semanticLabel == null
          ? item.label
          : ExcludeSemantics(child: item.label),
      icon: item.icon,
      // The current crumb ends the trail, so it carries no chevron. That is the
      // whole reason the trail's own itemSpacing is zero in Figma.
      separator: current
          ? null
          : Icon(fluentBreadcrumbSeparatorIcon(widget.size)),
    );
    final style = _styleFor(state);

    if (current) {
      // Not a link and not a button: the current page is a marker. `selected`
      // is the nearest Flutter semantic to `aria-current="page"`.
      return Semantics(
        container: true,
        selected: true,
        label: item.semanticLabel,
        child: buildFluentBreadcrumb(state, style, const <WidgetState>{}),
      );
    }

    return Semantics(
      link: true,
      enabled: state.enabled,
      label: item.semanticLabel,
      child: FluentInteractive(
        enabled: state.enabled,
        onPressed: state.enabled ? item.onPressed : null,
        mouseCursor:
            style.mouseCursor?.resolve(const <WidgetState>{}) ??
            SystemMouseCursors.click,
        builder: (context, states, _) =>
            buildFluentBreadcrumb(state, style, states),
      ),
    );
  }

  Widget _buildOverflowTrigger() {
    final state = _overflowState();
    final style = _styleFor(state);

    final trigger = FluentInteractive(
      onPressed: _toggle,
      focusNode: _overflowFocus,
      mouseCursor:
          style.mouseCursor?.resolve(const <WidgetState>{}) ??
          SystemMouseCursors.click,
      builder: (context, states, _) =>
          buildFluentBreadcrumb(state, style, states),
    );

    return Semantics(
      button: true,
      expanded: _open,
      label: fluentL10n(context).more,
      child: CompositedTransformTarget(
        link: _link,
        // Bound here rather than on the focus node so they sit below the app's
        // own Enter/Space -> ActivateIntent mapping and above the trigger's,
        // which is the only way Enter can mean "follow the active row" while a
        // tap still only toggles.
        child: Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.arrowDown):
                FluentBreadcrumbMoveIntent(1),
            SingleActivator(LogicalKeyboardKey.arrowUp):
                FluentBreadcrumbMoveIntent(-1),
            SingleActivator(LogicalKeyboardKey.enter):
                FluentBreadcrumbActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space):
                FluentBreadcrumbActivateIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              FluentBreadcrumbMoveIntent:
                  CallbackAction<FluentBreadcrumbMoveIntent>(
                    onInvoke: (intent) {
                      _move(intent.delta);
                      return null;
                    },
                  ),
              FluentBreadcrumbActivateIntent:
                  CallbackAction<FluentBreadcrumbActivateIntent>(
                    onInvoke: (_) {
                      _activate();
                      return null;
                    },
                  ),
              // Only enabled while the popup is open, so Escape still reaches
              // whatever an ancestor does with it when there is nothing to
              // dismiss here.
              DismissIntent: _DismissOverflowAction(this),
            },
            child: trigger,
          ),
        ),
      ),
    );
  }

  Widget _buildPopup() {
    final style = _styleFor(_overflowState());
    const surfaceStates = <WidgetState>{};
    final gap = style.surfaceGap?.resolve(surfaceStates) ?? FluentSpacing.xxs;
    final offset = style.surfaceOffset?.resolve(surfaceStates) ?? 0;
    final rows = _partition.overflow;

    return Stack(
      children: <Widget>[
        // A pointer landing anywhere else dismisses. Nothing is painted, so
        // this is invisible; it exists because a click on inert scenery moves
        // no focus and would otherwise leave the popup open.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _close,
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          child: CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: Offset(0, offset),
            // The rows are outside the traversal order on purpose: focus stays
            // on the trigger the whole time the popup is open, which is what
            // makes "focus returns to the trigger on close" structural.
            child: ExcludeFocus(
              // The popup hugs its widest row rather than matching the
              // trigger, which is 24-40 wide and would clip every label.
              // IntrinsicWidth is what bounds the stretch below.
              child: IntrinsicWidth(
                child: buildFluentBreadcrumbSurface(
                  style,
                  surfaceStates,
                  SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: gap,
                      children: <Widget>[
                        for (var i = 0; i < rows.length; i++)
                          _buildRow(i, rows),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(int index, List<FluentBreadcrumbItem> rows) {
    final item = rows[index];
    final state = resolveFluentBreadcrumbState(
      enabled: item.enabled && item.onPressed != null,
      size: widget.size,
      label: item.semanticLabel == null
          ? item.label
          : ExcludeSemantics(child: item.label),
      icon: item.icon,
    );
    final style = _styleFor(state);

    return Semantics(
      link: true,
      enabled: state.enabled,
      label: item.semanticLabel,
      child: FluentInteractive(
        enabled: state.enabled,
        onPressed: state.enabled ? () => _select(item) : null,
        mouseCursor:
            style.mouseCursor?.resolve(const <WidgetState>{}) ??
            SystemMouseCursors.click,
        builder: (context, states, _) => ValueListenableBuilder<bool>(
          valueListenable: FluentInputModality.keyboard,
          builder: (context, keyboard, _) =>
              buildFluentBreadcrumb(state, style, <WidgetState>{
                ...states,
                // The active row is where the keyboard is, even though the
                // framework's focus never leaves the trigger. `_active` is set
                // by hover too, so on its own it means "active descendant" —
                // upstream's `data-activedescendant`. The ring belongs to its
                // focus-visible sibling, which is this AND.
                if (index == _active && keyboard) WidgetState.focused,
              }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final partition = _partition;
    final displayed = partition.displayed;
    final last = displayed.length - 1;

    final children = <Widget>[
      for (var i = 0; i < displayed.length; i++) ...<Widget>[
        _buildCrumb(displayed[i], current: i == last),
        // The overflow trigger takes the place of the crumbs it swallowed,
        // which is directly after the pinned root.
        if (i == 0 && partition.overflow.isNotEmpty) _buildOverflowTrigger(),
      ],
    ];

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.semanticLabel,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        // Figma binds `Spacing/Horizontal/None` on the `Breadcrumb` frame: the
        // separator is inside the crumb, so the trail itself adds nothing.
        spacing: FluentSpacing.none,
        children: children,
      ),
    );
  }
}

/// Closes the overflow popup on Escape, and only while there is one to close.
class _DismissOverflowAction extends Action<DismissIntent> {
  _DismissOverflowAction(this.state);

  final _FluentBreadcrumbState state;

  @override
  bool isEnabled(DismissIntent intent) => state._open;

  @override
  Object? invoke(DismissIntent intent) {
    state._close();
    return null;
  }
}
