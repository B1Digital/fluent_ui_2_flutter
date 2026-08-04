import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import '../internal/interaction.dart';
import 'card_style.dart';

/// How a card is filled and outlined.
///
/// Names and defaults follow the Figma `Style` axis verbatim.
enum FluentCardAppearance {
  /// Neutral fill on an elevated surface. The default.
  filled,

  /// The same treatment one step down the neutral background ramp, for a card
  /// sitting on a `neutralBackground1` page.
  filledAlternative,

  /// Transparent fill with a visible border and no elevation.
  outline,

  /// No border and no elevation; the fill appears only on hover.
  subtle,
}

/// Which axis the slots are laid out along. Figma's `Layout` axis.
enum FluentCardOrientation {
  /// Preview above the slots. The default.
  vertical,

  /// Preview before the slots, everything centred on the cross axis.
  horizontal,
}

/// Card inset, gap and corner radius. Figma's `Card padding` collection.
///
/// One value drives the inset *and* the gap at every step, because upstream
/// drives both from a single CSS variable.
enum FluentCardSize {
  /// 8 inset, `FluentRadius.small`.
  small,

  /// 12 inset, `FluentRadius.medium`. The default.
  medium,

  /// 16 inset, `FluentRadius.large`.
  large,
}

/// Everything needed to render a card, independent of appearance and size.
///
/// The Dart counterpart of upstream's `CardState` minus its styling axes.
/// [buildFluentCard] takes this rather than [FluentCardState], which is what
/// makes "Fluent's state, my own styling, Fluent's rendering" a supported path
/// rather than a fork.
@immutable
class FluentCardBaseState {
  /// Creates a base state.
  const FluentCardBaseState({
    required this.enabled,
    required this.interactive,
    required this.selected,
    required this.orientation,
    this.preview,
    this.header,
    this.body,
    this.footer,
  });

  /// Whether the card responds to input at all.
  ///
  /// False means *disabled* — a real state with its own tokens. It is not the
  /// same claim as [interactive] being false, which means the card was never
  /// given anything to do.
  final bool enabled;

  /// Whether the card was given an `onPressed`.
  ///
  /// Upstream calls this `interactive`, and it gates the hover and pressed
  /// tokens: an inert card keeps its resting fill under the pointer.
  final bool interactive;

  /// Whether the card is currently selected.
  final bool selected;

  /// Which axis the slots are laid out along.
  final FluentCardOrientation orientation;

  /// Media that bleeds to the card's edge, before every other slot.
  final Widget? preview;

  /// Title area, inset by the card's padding.
  final Widget? header;

  /// Main content, inset by the card's padding.
  final Widget? body;

  /// Action area, inset by the card's padding.
  final Widget? footer;
}

/// A card's fully resolved state, including the design axes.
///
/// The counterpart of upstream's `CardState`: base state plus exactly
/// `appearance` and `size`.
@immutable
class FluentCardState extends FluentCardBaseState {
  /// Creates a resolved state.
  const FluentCardState({
    required super.enabled,
    required super.interactive,
    required super.selected,
    required super.orientation,
    required this.appearance,
    required this.size,
    super.preview,
    super.header,
    super.body,
    super.footer,
  });

  /// Fill, outline and elevation treatment.
  final FluentCardAppearance appearance;

  /// Inset, gap and corner radius.
  final FluentCardSize size;
}

/// Builds the state a card will be styled and rendered from.
///
/// Separated so a consumer can reuse Fluent's state resolution while
/// substituting their own styling — the first of the three-function
/// recomposition contract.
FluentCardState resolveFluentCardState({
  bool enabled = true,
  bool interactive = false,
  bool selected = false,
  FluentCardAppearance appearance = FluentCardAppearance.filled,
  FluentCardOrientation orientation = FluentCardOrientation.vertical,
  FluentCardSize size = FluentCardSize.medium,
  Widget? preview,
  Widget? header,
  Widget? body,
  Widget? footer,
}) => FluentCardState(
  enabled: enabled,
  interactive: interactive,
  selected: selected,
  appearance: appearance,
  orientation: orientation,
  size: size,
  preview: preview,
  header: header,
  body: body,
  footer: footer,
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes. Every value comes from a Fluent token; nothing
/// here computes a colour.
///
/// Two things are branched on the state rather than expressed as a
/// [WidgetStateProperty], because upstream branches on them too:
///
/// * **Selection outranks hover.** `filledInteractiveSelected` re-declares the
///   Selected fill inside its own `:hover` block, so a hovered selected card
///   stays Selected. [FluentStateColor] resolves hover before selected, so a
///   selected card gets the Selected token in every non-disabled slot instead.
/// * **An inert card has no hover.** Upstream only merges the interactive
///   class set when `interactive || selectable`, so a plain card's hover and
///   pressed values are its resting ones.
FluentCardStyle resolveFluentCardStyle(
  FluentCardState state,
  FluentThemeData theme,
) {
  final c = theme.colors;

  // (rest, hover, pressed, selected) per appearance, straight from
  // `useCardStyles.styles.ts`.
  final (
    restFill,
    hoverFill,
    pressedFill,
    selectedFill,
  ) = switch (state.appearance) {
    FluentCardAppearance.filled => (
      c.neutralBackground1,
      c.neutralBackground1Hover,
      c.neutralBackground1Pressed,
      c.neutralBackground1Selected,
    ),
    FluentCardAppearance.filledAlternative => (
      c.neutralBackground2,
      c.neutralBackground2Hover,
      c.neutralBackground2Pressed,
      c.neutralBackground2Selected,
    ),
    // Figma binds `Neutral/Background/Transparent/Rest` on all four states of
    // the Outline card, not the Hover/Pressed/Selected members of that family.
    // The distinction is invisible in light and dark — every one of them is
    // fully transparent — but in high contrast the three interactive ones turn
    // OPAQUE highlight, which would flood an outline card and hide its content.
    // Outline signals state through its border; upstream's Hover/Pressed/
    // Selected fills are the divergence.
    FluentCardAppearance.outline => (
      c.transparentBackground,
      c.transparentBackground,
      c.transparentBackground,
      c.transparentBackground,
    ),
    FluentCardAppearance.subtle => (
      c.subtleBackground,
      c.subtleBackgroundHover,
      c.subtleBackgroundPressed,
      c.subtleBackgroundSelected,
    ),
  };

  // Only `filled-alternative` moves down the Foreground 2 ramp; the other three
  // all take Foreground 1, which is why this cannot share the block above.
  final (
    hoverText,
    selectedText,
  ) = state.appearance == FluentCardAppearance.filledAlternative
      ? (c.neutralForeground2Hover, c.neutralForeground2Selected)
      : (c.neutralForeground1Hover, c.neutralForeground1Selected);

  // Only `outline` draws a visible resting border. The other three still draw
  // one: `transparentStrokeInteractive` is invisible in light and dark but
  // turns opaque in high contrast, where it is the card's only outline. Figma
  // names the *Interactive* member on every non-outline state, not the plain
  // `transparentStroke` upstream reaches for — they part company in high
  // contrast, where Interactive is the highlight colour and the plain one is
  // the text colour.
  final (
    restStroke,
    hoverStroke,
    pressedStroke,
  ) = state.appearance == FluentCardAppearance.outline
      ? (c.neutralStroke1, c.neutralStroke1Hover, c.neutralStroke1Pressed)
      : (
          c.transparentStrokeInteractive,
          c.transparentStrokeInteractive,
          c.transparentStrokeInteractive,
        );

  // Disabled is uniform across appearances, except that `outline` keeps its
  // transparent fill and stays flat.
  final outline = state.appearance == FluentCardAppearance.outline;
  final disabledFill = outline
      ? c.transparentBackground
      : c.neutralBackgroundDisabled;
  // Only `outline` shows a border when disabled. Figma keeps the other three on
  // the transparent family — `Neutral/Stroke/Transparent/Disabled/Rest` — where
  // upstream's `disabledStyles` paints the visible `neutralStrokeDisabled` grey
  // on every appearance.
  final disabledStroke = outline
      ? c.neutralStrokeDisabled
      : c.transparentStrokeDisabled;

  final elevated =
      state.appearance == FluentCardAppearance.filled ||
      state.appearance == FluentCardAppearance.filledAlternative;

  // An inert card never sees hover or pressed, so naming its resting token for
  // those slots states the intent rather than relying on the state set.
  final hovered = state.interactive;

  final background = state.selected
      ? FluentStateColor.tokens(
          rest: selectedFill,
          hover: selectedFill,
          pressed: selectedFill,
          selected: selectedFill,
          disabled: disabledFill,
        )
      : FluentStateColor.tokens(
          rest: restFill,
          hover: hovered ? hoverFill : restFill,
          pressed: hovered ? pressedFill : restFill,
          selected: selectedFill,
          disabled: disabledFill,
        );

  final foreground = state.selected
      ? FluentStateColor.tokens(
          rest: selectedText,
          hover: selectedText,
          pressed: selectedText,
          selected: selectedText,
          disabled: c.neutralForegroundDisabled,
        )
      : FluentStateColor.tokens(
          rest: c.neutralForeground1,
          hover: hovered ? hoverText : c.neutralForeground1,
          pressed: hovered ? hoverText : c.neutralForeground1,
          selected: selectedText,
          disabled: c.neutralForegroundDisabled,
        );

  final border = state.selected
      ? FluentStateColor.tokens(
          rest: c.neutralStroke1Selected,
          hover: c.neutralStroke1Selected,
          pressed: c.neutralStroke1Selected,
          selected: c.neutralStroke1Selected,
          disabled: disabledStroke,
        )
      : FluentStateColor.tokens(
          rest: restStroke,
          hover: hovered ? hoverStroke : restStroke,
          pressed: hovered ? pressedStroke : restStroke,
          selected: c.neutralStroke1Selected,
          disabled: disabledStroke,
        );

  // Geometry. Upstream drives the inset and the gap from one CSS variable, so
  // the two are the same number at every size.
  final (inset, radius) = switch (state.size) {
    FluentCardSize.small => (FluentSpacing.s, FluentRadius.allSmall),
    FluentCardSize.medium => (FluentSpacing.m, FluentRadius.allMedium),
    FluentCardSize.large => (FluentSpacing.l, FluentRadius.allLarge),
  };

  final resting = elevated ? theme.shadow(FluentElevation.shadow4) : null;

  return FluentCardStyle(
    backgroundColor: background,
    foregroundColor: foreground,
    borderColor: border,
    borderWidth: const WidgetStatePropertyAll<double?>(FluentStroke.thin),
    borderRadius: WidgetStatePropertyAll<BorderRadius?>(radius),
    padding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(EdgeInsets.all(inset)),
    gap: WidgetStatePropertyAll<double?>(inset),
    shadow: WidgetStateProperty.resolveWith((states) {
      // A disabled card keeps its resting elevation. Figma's Disabled variants
      // carry the same shadow4 effect style as their Rest siblings, where
      // upstream's `disabledStyles` drops every card to shadow2.
      if (states.contains(WidgetState.disabled)) return resting;
      if (elevated && hovered && states.contains(WidgetState.hovered)) {
        return theme.shadow(FluentElevation.shadow8);
      }
      return resting;
    }),
    mouseCursor: const WidgetStatePropertyAll<MouseCursor?>(
      SystemMouseCursors.click,
    ),
  );
}

/// Renders a card from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentCardBaseState] rather than [FluentCardState] on purpose: it never
/// reads the appearance or size, so a consumer can supply their own style and
/// still use Fluent's slot layout, clipping and focus ring.
///
/// [states] is the live interaction set from [FluentInteractive].
///
/// Nothing here animates. Upstream's card styles declare no `transition` on the
/// root or on any slot, so hover, press and selection land on the frame they
/// happen — see the test that asserts the first frame is already the target.
Widget buildFluentCard(
  FluentCardBaseState state,
  FluentCardStyle style,
  Set<WidgetState> states,
) {
  final radius = style.borderRadius?.resolve(states) ?? FluentRadius.allMedium;
  final borderWidth = style.borderWidth?.resolve(states) ?? FluentStroke.none;
  final borderColor = style.borderColor?.resolve(states);
  final foreground = style.foregroundColor?.resolve(states);
  final padding = style.padding?.resolve(states) ?? EdgeInsets.zero;
  final gap = style.gap?.resolve(states) ?? FluentSpacing.m;
  final vertical = state.orientation == FluentCardOrientation.vertical;

  final slots = <Widget>[
    if (state.header != null) state.header!,
    if (state.body != null) state.body!,
    if (state.footer != null) state.footer!,
  ];

  // The padded group and the preview's full bleed are one arrangement, not two:
  // upstream pads the card and then cancels that padding on the preview with a
  // negative margin of the same size. Padding only the group is the same
  // geometry with nothing to cancel — and the gap between the preview and the
  // first padded slot falls out of the group's own leading inset.
  final children = <Widget>[
    if (state.preview != null) state.preview!,
    if (slots.isNotEmpty)
      Padding(
        padding: padding,
        child: vertical
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: gap,
                children: slots,
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: gap,
                children: slots,
              ),
      ),
  ];

  // `stretch` on the vertical axis is what makes the preview span the card
  // edge to edge, and it is also the honest port: upstream's card is a block
  // element, so it fills the width it is given rather than hugging its content.
  // A vertical card therefore needs a bounded width, exactly as a `<div>` does.
  Widget content = vertical
      ? Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        )
      : Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: children,
        );

  if (foreground != null) {
    content = DefaultTextStyle.merge(
      // Colour only. Upstream sets no font on the card root — the slots keep
      // whatever type ramp they were given.
      style: TextStyle(color: foreground),
      child: IconTheme.merge(
        data: IconThemeData(color: foreground),
        child: content,
      ),
    );
  }

  // The card is the one component whose focus ring is drawn INSIDE its own box,
  // which is why this is a border rather than a `FluentFocusRing`: that widget
  // paints its 2px band outside the child, and here the band belongs at −2…0.
  //
  // `useCardStyles.styles.ts` L34-38 hands `createFocusOutlineStyle` an
  // `outlineOffset: '-2px'` on top of the helper's own −2px, so
  // `getOutlinePosition` resolves to `calc(0px - 2px - -2px)` = 0 — probing
  // `components-card-card--focus-mode` gives a 396x356 `::after` inside a
  // 400x360 card. Figma agrees on the geometry: its `Focus ring` frame is drawn
  // at the component's own size, never inflated.
  //
  // Reusing the appearance border's slot is also what upstream does: the
  // `::after` is opaque and 2px wide, so it completely covers the card's 1px
  // resting border for as long as focus is on it.
  final focusRing = states.contains(WidgetState.focused);

  return Builder(
    builder: (context) => DecoratedBox(
      decoration: BoxDecoration(
        color: style.backgroundColor?.resolve(states),
        borderRadius: radius,
        boxShadow: style.shadow?.resolve(states),
      ),
      child: DecoratedBox(
        // Foreground, so the border never consumes layout: content starts at
        // `padding` from the outer edge, matching Figma's border-box. It is
        // also what lets the preview bleed underneath the border rather than
        // stopping at it — upstream's reason for using an `::after` element.
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: focusRing
              ? Border.all(
                  color: FluentTheme.of(context).colors.strokeFocus2,
                  width: FluentStroke.thick,
                )
              : borderWidth > 0 && borderColor != null
              ? Border.all(color: borderColor, width: borderWidth)
              : null,
        ),
        child: ClipRRect(borderRadius: radius, child: content),
      ),
    ),
  );
}

/// Overrides the card style for a subtree.
///
/// The counterpart of Material's `CardTheme`, and the middle rung of the
/// resolution order: theme defaults, then this, then the widget's own `style`.
class FluentCardTheme extends InheritedTheme {
  /// Applies [style] to every `FluentCard` in [child].
  const FluentCardTheme({super.key, required this.style, required super.child});

  /// The style layered over the appearance and size defaults.
  final FluentCardStyle style;

  /// The nearest card style, or null.
  static FluentCardStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentCardTheme>()?.style;

  @override
  bool updateShouldNotify(FluentCardTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentCardTheme(style: style, child: child);
}

/// A Fluent 2 card: a container that groups a preview, a header, a body and a
/// footer onto one elevated surface.
///
/// ```dart
/// FluentCard(
///   preview: Image.asset('cover.png'),
///   header: const Text('Weekly report'),
///   footer: FluentButton(onPressed: () {}, child: const Text('Open')),
///   onPressed: () {},
///   child: const Text('Revenue is up 4% week over week.'),
/// )
/// ```
///
/// ## Interactive or inert
///
/// A card is **interactive** when given an [onPressed] and **inert** otherwise,
/// and the two are genuinely different components rather than one with a
/// callback attached: an inert card reports no hover, takes no focus and raises
/// no focus ring, exactly as upstream only merges its interactive class set
/// when the card is clickable or selectable.
///
/// [disabled] is a third thing again, and orthogonal to both. It is a real
/// state with its own tokens — a disabled card refuses focus and never invokes
/// [onPressed] — which is why it is a flag rather than "pass a null callback".
/// An inert card can be disabled too, and looks it.
///
/// ## Slots
///
/// [preview] bleeds to the card's edge and is clipped to its corner radius;
/// [header], [child] and [footer] are inset by the card's padding, in that
/// order along [orientation]'s axis. The slots are plain widgets: Fluent's own
/// `CardHeader` grid is a composition concern, not something this widget
/// imposes.
///
/// A vertical card **fills the width it is given** rather than hugging its
/// content, because upstream's is a block element and because a preview cannot
/// bleed to an edge the card has not claimed. Give it a bounded width — a
/// `SizedBox`, an `Expanded`, a grid cell — exactly as you would a `<div>`.
///
/// ## Customisation
///
/// The same three rungs Microsoft documents for the React original. [style] is
/// merged last and wins; [FluentCardTheme] restyles a subtree; and for anything
/// further, [resolveFluentCardState], [resolveFluentCardStyle] and
/// [buildFluentCard] are public so any one of them can be replaced without
/// forking this widget.
class FluentCard extends StatelessWidget {
  /// Creates a card. Every slot is optional.
  const FluentCard({
    super.key,
    this.child,
    this.preview,
    this.header,
    this.footer,
    this.onPressed,
    this.selected = false,
    this.disabled = false,
    this.appearance = FluentCardAppearance.filled,
    this.orientation = FluentCardOrientation.vertical,
    this.size = FluentCardSize.medium,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  /// The body slot, inset by the card's padding.
  final Widget? child;

  /// Media that bleeds to the card's edge, before every other slot.
  final Widget? preview;

  /// The header slot, inset by the card's padding.
  final Widget? header;

  /// The footer slot, inset by the card's padding.
  final Widget? footer;

  /// Invoked on tap and on Space or Enter.
  ///
  /// Null makes the card inert: no hover, no focus, no ring. That is not the
  /// same as [disabled], which is a state the card visibly reports.
  final VoidCallback? onPressed;

  /// Whether the card is selected, which selects Fluent's real `*Selected`
  /// tokens and outranks hover, as it does upstream.
  final bool selected;

  /// Whether the card is disabled.
  ///
  /// A disabled card refuses focus, never invokes [onPressed] and paints the
  /// disabled tokens. Orthogonal to [onPressed]: an inert card can be disabled.
  final bool disabled;

  /// Fill, outline and elevation treatment.
  final FluentCardAppearance appearance;

  /// Which axis the slots are laid out along.
  final FluentCardOrientation orientation;

  /// Inset, gap and corner radius.
  final FluentCardSize size;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentCardStyle? style;

  /// Focus node to use. One is created internally when omitted. Ignored by an
  /// inert card, which takes no focus.
  final FocusNode? focusNode;

  /// Whether to take focus on mount.
  final bool autofocus;

  /// Announced by assistive technology.
  ///
  /// A card is a container of arbitrary widgets, so there is no label to infer.
  /// Supply one whenever the card is interactive.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final interactive = onPressed != null;
    final state = resolveFluentCardState(
      enabled: !disabled,
      interactive: interactive,
      selected: selected,
      appearance: appearance,
      orientation: orientation,
      size: size,
      preview: preview,
      header: header,
      body: child,
      footer: footer,
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentCardStyle(
      state,
      FluentTheme.of(context),
    ).merge(FluentCardTheme.maybeOf(context)).merge(style);

    // An inert card is built directly rather than through FluentInteractive,
    // which would report it as `disabled` for want of a callback. Inert and
    // disabled are different states and must not collapse into one.
    final card = interactive
        ? FluentInteractive(
            onPressed: onPressed,
            enabled: !disabled,
            focusNode: focusNode,
            autofocus: autofocus,
            mouseCursor:
                resolved.mouseCursor?.resolve(const <WidgetState>{}) ??
                SystemMouseCursors.click,
            builder: (context, states, _) => buildFluentCard(
              state,
              resolved,
              selected
                  ? <WidgetState>{...states, WidgetState.selected}
                  : states,
            ),
          )
        : buildFluentCard(state, resolved, <WidgetState>{
            if (disabled) WidgetState.disabled,
            if (selected) WidgetState.selected,
          });

    if (!interactive) {
      return semanticLabel == null
          ? card
          : Semantics(label: semanticLabel, child: card);
    }

    return Semantics(
      button: true,
      enabled: !disabled,
      // Announced only when true: an ordinary clickable card is not a member of
      // a selection group, and saying "not selected" on every one is noise.
      selected: selected ? true : null,
      label: semanticLabel,
      child: card,
    );
  }
}
