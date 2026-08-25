import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import '../internal/focus_ring.dart';
import '../internal/interaction.dart';
import 'menu_item_style.dart';

/// What a row of a `FluentMenu` is.
///
/// The three shapes the Figma file ships: `Menu item` (a command),
/// `Menu section` with `Divider=False` (a caption), and the same set with
/// `Divider=True` (a rule).
enum FluentMenuItemType {
  /// An activatable row. The default.
  command,

  /// A non-interactive caption above a group of commands.
  header,

  /// A horizontal rule between groups.
  divider,
}

/// One row of a `FluentMenu`.
///
/// A plain description rather than a widget: the menu owns hover, press,
/// keyboard activity, the focus ring and the submenu chain, so an item only has
/// to say what it *is*.
///
/// ```dart
/// FluentMenuItem(
///   icon: const Icon(FluentIcons.cut_20_regular),
///   label: const Text('Cut'),
///   trailing: const Text('Ctrl+X'),
///   onPressed: () {},
/// )
/// ```
@immutable
class FluentMenuItem {
  /// Creates an activatable row.
  const FluentMenuItem({
    required this.label,
    this.icon,
    this.secondary,
    this.trailing,
    this.checked = false,
    this.selected = false,
    this.enabled = true,
    this.submenu = const <FluentMenuItem>[],
    this.onPressed,
    this.text,
  }) : type = FluentMenuItemType.command;

  /// Creates a non-interactive caption.
  ///
  /// Never activatable, never focusable, and skipped by keyboard navigation
  /// whatever [enabled] says — that flag only chooses between Figma's
  /// `Menu section` `State=Rest` and `State=Disabled` label tokens, for a
  /// caption over a group whose commands are all unavailable.
  const FluentMenuItem.header({
    required this.label,
    this.text,
    this.enabled = true,
  }) : type = FluentMenuItemType.header,
       icon = null,
       secondary = null,
       trailing = null,
       checked = false,
       selected = false,
       submenu = const <FluentMenuItem>[],
       onPressed = null;

  /// Creates a horizontal rule.
  const FluentMenuItem.divider()
    : type = FluentMenuItemType.divider,
      label = const SizedBox.shrink(),
      icon = null,
      secondary = null,
      trailing = null,
      checked = false,
      selected = false,
      enabled = false,
      submenu = const <FluentMenuItem>[],
      onPressed = null,
      text = null;

  /// What this row is.
  final FluentMenuItemType type;

  /// The row's primary line.
  final Widget label;

  /// Optional leading glyph, rendered at `iconSize`.
  ///
  /// Occupies the same slot as the checkmark, which is what upstream does: a
  /// menu shows one or the other, never both.
  final Widget? icon;

  /// Optional second line under [label], on the `caption2` ramp.
  final Widget? secondary;

  /// Optional trailing content — normally a keyboard shortcut.
  ///
  /// Rendered before the submenu chevron and on the label's own ramp.
  final Widget? trailing;

  /// Whether the checkmark glyph is painted.
  ///
  /// Figma's `State=Rest (Checked only)`. Independent of [selected]: a checked
  /// row keeps the resting fill.
  final bool checked;

  /// Whether the row paints Fluent's `Selected` fill.
  ///
  /// Figma's `State=Selected`, which is the only state in the set that binds
  /// `Neutral/Background/1/Selected`. Surfaces as [WidgetState.selected], and
  /// resolves *after* hover and press, so pointing at a selected row still
  /// shows the hover token.
  final bool selected;

  /// Whether the row responds to input.
  ///
  /// On a header this only picks the label token — see
  /// [FluentMenuItem.header]. A divider is always false and never reads it.
  final bool enabled;

  /// Rows of the submenu this one opens, or empty for a leaf.
  final List<FluentMenuItem> submenu;

  /// Invoked when the row is activated. Ignored when [submenu] is non-empty —
  /// such a row opens its submenu instead.
  final VoidCallback? onPressed;

  /// Plain text for typeahead.
  ///
  /// Optional because a [label] that is a `Text` already supplies it; pass this
  /// when the label is a glyph or a rich widget. It is **not** used as a
  /// semantic label — the label widget is already in the tree and naming it a
  /// second time makes a screen reader read the row twice.
  final String? text;

  /// Whether this row can be moved to and activated by the keyboard.
  bool get selectable =>
      type == FluentMenuItemType.command && enabled && !hasNoAction;

  /// Whether this row has neither a callback nor a submenu.
  bool get hasNoAction => onPressed == null && submenu.isEmpty;

  /// Whether this row opens a submenu.
  bool get hasSubmenu => submenu.isNotEmpty;
}

/// Everything needed to render one menu row, independent of its type.
///
/// The counterpart of `FluentButtonBaseState`. [buildFluentMenuItem] takes this
/// rather than [FluentMenuItemState], which is what makes "Fluent's state, my
/// own styling, Fluent's rendering" a supported path rather than a fork.
@immutable
class FluentMenuItemBaseState {
  /// Creates a base state.
  const FluentMenuItemBaseState({
    required this.enabled,
    required this.divider,
    required this.showCheckmark,
    required this.reserveLeading,
    required this.hasSubmenu,
    required this.label,
    this.icon,
    this.secondary,
    this.trailing,
  });

  /// Whether the row responds to input.
  final bool enabled;

  /// Whether this row is a rule rather than a row of content.
  ///
  /// Structural rather than stylistic, which is why it lives on the base state:
  /// a rule has no slots at all, so the renderer cannot infer it from a style.
  final bool divider;

  /// Whether the checkmark glyph is painted.
  final bool showCheckmark;

  /// Whether the leading slot is laid out even when nothing is painted.
  ///
  /// True for every command row that sits in a menu containing icons or
  /// checkmarks, so labels line up down the list — upstream hides the glyph
  /// with `visibility: hidden` for the same reason.
  final bool reserveLeading;

  /// Whether the submenu chevron is painted.
  final bool hasSubmenu;

  /// The primary line.
  final Widget label;

  /// The leading glyph, if any.
  final Widget? icon;

  /// The second line, if any.
  final Widget? secondary;

  /// The trailing content, if any.
  final Widget? trailing;
}

/// A menu row's fully resolved state, including the design axis.
@immutable
class FluentMenuItemState extends FluentMenuItemBaseState {
  /// Creates a resolved state.
  const FluentMenuItemState({
    required super.enabled,
    required super.divider,
    required super.showCheckmark,
    required super.reserveLeading,
    required super.hasSubmenu,
    required super.label,
    required this.type,
    super.icon,
    super.secondary,
    super.trailing,
  });

  /// What this row is.
  final FluentMenuItemType type;
}

/// Builds the state one menu row will be styled and rendered from.
///
/// The first of the three-function recomposition contract, and the only place
/// the leading slot is decided: a header and a rule have none, a command row
/// reserves one whenever the menu around it needs the column.
FluentMenuItemState resolveFluentMenuItemState({
  required Widget label,
  bool enabled = true,
  bool checked = false,
  bool hasSubmenu = false,
  bool reserveLeading = false,
  FluentMenuItemType type = FluentMenuItemType.command,
  Widget? icon,
  Widget? secondary,
  Widget? trailing,
}) {
  final command = type == FluentMenuItemType.command;
  return FluentMenuItemState(
    // Not gated on `command`: a header is inert but still has both of Figma's
    // `Menu section` label tokens to choose between.
    enabled: enabled,
    divider: type == FluentMenuItemType.divider,
    showCheckmark: checked && command,
    reserveLeading: command && (reserveLeading || icon != null || checked),
    hasSubmenu: hasSubmenu && command,
    label: label,
    type: type,
    icon: command ? icon : null,
    secondary: command ? secondary : null,
    trailing: command ? trailing : null,
  );
}

/// Every `Menu item` and `Menu section` variant is 32 tall. A
/// `Divider=True` section is 5 instead: the 1px rule plus [FluentSpacing.xxs]
/// above and below, which is the padding the divider branch of
/// [buildFluentMenuItem] applies rather than a minimum size.
const double _rowHeight = 32;

/// The glyph a checked row draws.
///
/// `Checkmark16Filled` — the Figma `Checkmark` instance is a 16 box around a
/// 12 x 9 tick, and upstream's `MenuItemCheckbox` renders the same icon.
const IconData fluentMenuCheckmark = FluentIcons.checkmark_16_filled;

/// The glyph a row with a submenu draws at its trailing edge.
///
/// Figma's `Chevron` instance is 20 square, matching upstream's
/// `submenuIndicator` rule.
const IconData fluentMenuSubmenuChevron = FluentIcons.chevron_right_20_regular;

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axis. Every value comes from a Fluent token; nothing
/// here computes a colour.
///
/// Token sources are the Figma `Menu item` set (`9121:6483`, 7 variants,
/// extracted to `test/fixtures/menu_item.json`) and the `Menu section` set
/// (`9121:6394`, 3 variants, `test/fixtures/menu_section.json`), reconciled
/// against `useMenuItemStyles.styles.ts` and `useMenuGroupHeaderStyles`.
/// Four notes on that reconciliation:
///
/// * **Rest paints no fill.** Every non-interactive `Menu item` variant binds
///   `Neutral/Background/1/Rest`, which is the *surface's* own colour repeated
///   on the row rather than a fill of its own — upstream's root declares no
///   background until `:hover`. Read as silence: the row is
///   `transparentBackground` at rest and when disabled, and the menu surface
///   shows through.
/// * **The leading glyph goes brand on hover and press.** Figma binds the icon
///   vector to `Neutral/Foreground/2/Rest` at rest and
///   `Neutral/Foreground/Disabled/Rest` when disabled; its hover and pressed
///   variants bind `Brand/Foreground/Compound/{Hover,Pressed}` to the single
///   glyph layer, which this file reads as the checkmark rather than the icon
///   (there is no `Hover (Checked only)` variant to tell them apart). Either
///   reading rejects the label's ramp for the icon, so upstream wins:
///   `useMenuItemStyles.styles.ts` `:hover` sets the icon slot to
///   `colorNeutralForeground2BrandSelected`, and the live probe measures
///   `#0F6CBD` on the hovered row's icon. The submenu chevron is a different
///   slot upstream declares no colour for, so it stays on the label's ramp.
/// * **The checkmark is brand-compound.** `Brand/Foreground/Compound/{Rest,
///   Hover,Pressed}`, dropping to `Neutral/Foreground/Disabled/Rest` in both
///   disabled variants. That is a genuinely different ramp from the label's,
///   which is why [FluentMenuItemStyle.checkmarkColor] is its own property.
/// * **The secondary line follows React.** Figma's `Secondary text` layer is
///   hidden in all 7 variants and binds `Neutral/Foreground/2/**Hover**` — a
///   Rest variant cannot mean a hover token, so the layer is read as never
///   having been switched. `useMenuItemStyles` says `colorNeutralForeground3`,
///   with `colorNeutralForeground3Hover` and `colorNeutralForeground3Pressed`
///   on the root's `:hover` and `:hover:active` blocks, and that is what ships.
FluentMenuItemStyle resolveFluentMenuItemStyle(
  FluentMenuItemState state,
  FluentThemeData theme,
) {
  final c = theme.colors;

  final background = state.enabled
      ? FluentStateColor.tokens(
          rest: c.transparentBackground,
          hover: c.neutralBackground1Hover,
          pressed: c.neutralBackground1Pressed,
          selected: c.neutralBackground1Selected,
          disabled: c.transparentBackground,
        )
      : FluentStateColor.tokens(rest: c.transparentBackground);

  final foreground = state.enabled
      ? FluentStateColor.tokens(
          rest: c.neutralForeground2,
          hover: c.neutralForeground2Hover,
          pressed: c.neutralForeground2Pressed,
          selected: c.neutralForeground2Selected,
          disabled: c.neutralForegroundDisabled,
        )
      : FluentStateColor.tokens(rest: c.neutralForegroundDisabled);

  // Geometry, verbatim from the Figma frames. The row frame itself pads
  // nothing — `Spacing/*/None` on all four sides — and the inset lives on its
  // `Item content` child: 6 top, 6 left, 6 bottom, and only 2 on the right,
  // where the trailing `Text container` adds the missing 6 back. Upstream says
  // `spacingVerticalSNudge` on all four sides; Figma's asymmetry wins.
  final padding = switch (state.type) {
    FluentMenuItemType.command => const EdgeInsets.fromLTRB(
      FluentSpacing.sNudge,
      FluentSpacing.sNudge,
      FluentSpacing.xxs,
      FluentSpacing.sNudge,
    ),
    FluentMenuItemType.header => const EdgeInsets.symmetric(
      horizontal: FluentSpacing.sNudge,
      vertical: FluentSpacing.s,
    ),
    FluentMenuItemType.divider => const EdgeInsets.symmetric(
      vertical: FluentSpacing.xxs,
    ),
  };

  return FluentMenuItemStyle(
    backgroundColor: background,
    foregroundColor: foreground,
    iconColor: state.enabled
        ? FluentStateColor.tokens(
            rest: c.neutralForeground2,
            hover: c.neutralForeground2BrandSelected,
            pressed: c.neutralForeground2BrandSelected,
            selected: c.neutralForeground2Selected,
            disabled: c.neutralForegroundDisabled,
          )
        : FluentStateColor.tokens(rest: c.neutralForegroundDisabled),
    secondaryColor: state.enabled
        ? FluentStateColor.tokens(
            rest: c.neutralForeground3,
            hover: c.neutralForeground3Hover,
            pressed: c.neutralForeground3Pressed,
            disabled: c.neutralForegroundDisabled,
          )
        : FluentStateColor.tokens(rest: c.neutralForegroundDisabled),
    checkmarkColor: state.enabled
        ? FluentStateColor.tokens(
            rest: c.compoundBrandForeground1,
            hover: c.compoundBrandForeground1Hover,
            pressed: c.compoundBrandForeground1Pressed,
            selected: c.compoundBrandForeground1,
            disabled: c.neutralForegroundDisabled,
          )
        : FluentStateColor.tokens(rest: c.neutralForegroundDisabled),
    dividerColor: FluentStateColor.tokens(rest: c.neutralStroke2),
    dividerThickness: const WidgetStatePropertyAll<double?>(FluentStroke.thin),
    borderRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allMedium,
    ),
    textStyle: WidgetStatePropertyAll<TextStyle?>(switch (state.type) {
      // 12/16 at `Typography/Weight/Bold`, which is `caption1Stronger` — not
      // `caption1Strong`, whose weight is semibold.
      FluentMenuItemType.header => theme.typography.caption1Stronger,
      _ => theme.typography.body1,
    }),
    secondaryTextStyle: WidgetStatePropertyAll<TextStyle?>(
      theme.typography.caption2,
    ),
    padding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(padding),
    labelPadding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.symmetric(horizontal: FluentSpacing.xxs),
    ),
    gap: const WidgetStatePropertyAll<double?>(FluentSpacing.xs),
    iconSize: const WidgetStatePropertyAll<double?>(FluentSize.size200),
    checkmarkSize: const WidgetStatePropertyAll<double?>(FluentSize.size160),
    minimumSize: const WidgetStatePropertyAll<Size?>(Size(0, _rowHeight)),
    mouseCursor: const WidgetStatePropertyAll<MouseCursor?>(
      SystemMouseCursors.click,
    ),
  );
}

/// Renders one menu row from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentMenuItemBaseState] rather than [FluentMenuItemState] on purpose: it
/// never reads the type, so a consumer can supply their own style and still use
/// Fluent's layout, checkmark slot and focus ring.
///
/// **Nothing animates.** `useMenuItemStyles.styles.ts` contains no `transition`,
/// no `animation` and no `motionTokens` reference at all: a row's fill changes
/// on the frame the pointer arrives. That also makes it trivially correct under
/// `MediaQuery.disableAnimationsOf` — there is no animation to shorten. The
/// menu *surface* does animate; see `FluentMenu`.
///
/// [states] is the live interaction set from [FluentInteractive], with
/// [WidgetState.focused] set by the menu on the *active* row — the one the
/// arrow keys have moved to.
Widget buildFluentMenuItem(
  FluentMenuItemBaseState state,
  FluentMenuItemStyle style,
  Set<WidgetState> states,
) {
  final radius = style.borderRadius?.resolve(states) ?? FluentRadius.allMedium;
  final minimumSize = style.minimumSize?.resolve(states) ?? Size.zero;
  final padding = style.padding?.resolve(states) ?? EdgeInsets.zero;

  if (state.divider) {
    final thickness =
        style.dividerThickness?.resolve(states) ?? FluentStroke.thin;
    return Padding(
      padding: padding,
      child: SizedBox(
        height: thickness,
        child: ColoredBox(
          color: style.dividerColor?.resolve(states) ?? const Color(0x00000000),
        ),
      ),
    );
  }

  final background = style.backgroundColor?.resolve(states);
  final foreground = style.foregroundColor?.resolve(states);
  final iconColor = style.iconColor?.resolve(states);
  final checkmarkColor = style.checkmarkColor?.resolve(states);
  final secondaryColor = style.secondaryColor?.resolve(states);
  final textStyle = style.textStyle?.resolve(states);
  final secondaryTextStyle = style.secondaryTextStyle?.resolve(states);
  final labelPadding = style.labelPadding?.resolve(states) ?? EdgeInsets.zero;
  final gap = style.gap?.resolve(states) ?? FluentSpacing.xs;
  final iconSize = style.iconSize?.resolve(states) ?? FluentSize.size200;
  final checkmarkSize =
      style.checkmarkSize?.resolve(states) ?? FluentSize.size160;

  // One slot, whichever glyph goes in it: upstream shows the icon or the
  // checkmark, never both, and the slot is laid out either way so that labels
  // keep a single column down the list.
  Widget? leading;
  if (state.showCheckmark) {
    leading = SizedBox.square(
      dimension: iconSize,
      child: Center(
        child: Icon(
          fluentMenuCheckmark,
          size: checkmarkSize,
          color: checkmarkColor,
        ),
      ),
    );
  } else if (state.icon != null) {
    leading = SizedBox.square(
      dimension: iconSize,
      child: IconTheme.merge(
        data: IconThemeData(color: iconColor, size: iconSize),
        child: state.icon!,
      ),
    );
  } else if (state.reserveLeading) {
    leading = SizedBox.square(dimension: iconSize);
  }

  final secondary = state.secondary;
  Widget label = Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      DefaultTextStyle.merge(
        style: (textStyle ?? const TextStyle()).copyWith(color: foreground),
        child: state.label,
      ),
      if (secondary != null)
        DefaultTextStyle.merge(
          style: (secondaryTextStyle ?? const TextStyle()).copyWith(
            color: secondaryColor,
          ),
          child: secondary,
        ),
    ],
  );
  label = Padding(padding: labelPadding, child: label);

  final trailing = state.trailing;
  final row = Row(
    // `useRootBaseStyles` is `alignItems: 'start'`: on a row tall enough to
    // show it — one with a secondary line — the glyph and the label sit at the
    // top of the content column rather than in the middle of it. Every slot of
    // a single-line row is 20 tall, so the two agree there.
    //
    // ponytail: upstream pulls the trailing slot and the chevron back with
    // `alignSelf: center` on multiline rows only. Flutter has no per-child
    // cross-axis alignment on a `Row`, and the intersection — a multiline row
    // that also carries a shortcut — is rare enough not to be worth an
    // `IntrinsicHeight` on every row.
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: gap,
    children: <Widget>[
      ?leading,
      Expanded(child: label),
      if (trailing != null)
        DefaultTextStyle.merge(
          style: (textStyle ?? const TextStyle()).copyWith(color: foreground),
          child: Padding(padding: labelPadding, child: trailing),
        ),
      // The chevron is `submenuIndicator`, a slot upstream declares no colour
      // for, so it inherits the root's `currentColor` — the label's ramp, not
      // the icon's.
      if (state.hasSubmenu)
        Icon(fluentMenuSubmenuChevron, size: iconSize, color: foreground),
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

/// Overrides the menu row style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `itemStyle`. An [InheritedTheme], so it survives the hop into
/// the [Overlay] the menu is rendered in.
class FluentMenuItemTheme extends InheritedTheme {
  /// Applies [style] to every `FluentMenu` row in [child].
  const FluentMenuItemTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the type defaults.
  final FluentMenuItemStyle style;

  /// The nearest menu row style, or null.
  static FluentMenuItemStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentMenuItemTheme>()?.style;

  @override
  bool updateShouldNotify(FluentMenuItemTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentMenuItemTheme(style: style, child: child);
}
