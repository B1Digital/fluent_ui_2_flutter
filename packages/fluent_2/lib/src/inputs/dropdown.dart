import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../internal/anchor_metrics.dart';
import '../internal/animated_style.dart';
import '../internal/defer.dart';
import '../internal/input_modality.dart';
import '../internal/interaction.dart';
import 'dropdown_option.dart';
import 'dropdown_option_style.dart';
import 'dropdown_style.dart';
import 'input.dart';

/// `useDropdownStyles.styles.ts` — `minWidth: '250px'` on the trigger root, at
/// every size.
const double _triggerMinWidth = 250;

/// `useListboxStyles.styles.ts` — `minWidth: '160px'` on the popup, which only
/// bites once the trigger it matches is narrower than 160.
const double _listboxMinWidth = 160;

/// How a dropdown trigger is filled and outlined.
///
/// Names follow the Figma `Appearance` axis verbatim. Upstream calls
/// [FluentDropdownAppearance.transparent] `underline` and hyphenates the two
/// filled members; the values are identical.
enum FluentDropdownAppearance {
  /// Neutral fill, a border all round, and an accessible rule along the bottom.
  /// The default, and upstream's `outline`.
  outline,

  /// No fill and no border — only the bottom rule. Upstream's `underline`.
  transparent,

  /// `neutralBackground1` with no visible border and no bottom rule. Upstream's
  /// `filled-lighter`.
  fillLighter,

  /// `neutralBackground3` with no visible border and no bottom rule. Upstream's
  /// `filled-darker`.
  fillDarker,
}

/// Trigger height and type ramp. Figma's `Size` axis.
enum FluentDropdownSize {
  /// 24 high, caption type.
  small,

  /// 32 high, body type. The default.
  medium,

  /// 40 high, `body2` type.
  large,
}

/// The accent rule arriving as the dropdown takes focus or opens.
///
/// Transcribed from `useDropdownStyles.styles.ts`:
///
/// ```ts
/// ':focus-within::after': {
///   transform: 'scaleX(1)',
///   transitionProperty: 'transform',
///   transitionDuration: tokens.durationNormal,
///   transitionDelay: tokens.curveDecelerateMid,
/// }
/// ```
///
/// Upstream puts the curve in `transitionDelay` rather than
/// `transitionTimingFunction` — a cubic-bezier is not a valid delay value, so a
/// browser drops it and runs the transition linearly. The curve upstream
/// *names* is honoured here rather than the one it accidentally ships; a linear
/// accent is not a design decision anybody made.
///
/// The bar itself is [FluentInputFocusUnderline], whose spec carries the same
/// two tokens off the same `::after` rule — so this is an alias rather than a
/// second copy of them.
const FluentMotionSpec fluentDropdownAccentEnter =
    fluentInputFocusUnderlineEnter;

/// The accent rule collapsing as the dropdown closes.
///
/// `durationUltraFast` with `curveAccelerateMid`, from the same `::after` rule.
/// Four times faster than [fluentDropdownAccentEnter], which is upstream's
/// asymmetry, not a typo.
///
/// An alias of [fluentInputFocusUnderlineExit], for the reason given on
/// [fluentDropdownAccentEnter].
const FluentMotionSpec fluentDropdownAccentExit = fluentInputFocusUnderlineExit;

/// The chevron every Fluent dropdown trigger carries.
const IconData fluentDropdownChevron = FluentIcons.chevron_down_20_regular;

/// Everything needed to render a dropdown trigger, independent of the design
/// axes.
///
/// The counterpart of `FluentButtonBaseState`. [buildFluentDropdown] takes this
/// rather than [FluentDropdownState], which is what makes "Fluent's state, my
/// own styling, Fluent's rendering" a supported path rather than a fork.
@immutable
class FluentDropdownBaseState {
  /// Creates a base state.
  const FluentDropdownBaseState({
    required this.enabled,
    required this.open,
    required this.chevron,
    this.value,
    this.placeholder,
  });

  /// Whether the trigger responds to input.
  final bool enabled;

  /// Whether the popup is showing. Drives the accent rule exactly as keyboard
  /// focus does, because upstream's selector is `:focus-within` and an open
  /// dropdown always contains focus.
  final bool open;

  /// The chevron widget.
  final Widget chevron;

  /// The selected option's label, or null when nothing is selected.
  final Widget? value;

  /// What to show while [value] is null.
  final Widget? placeholder;
}

/// A dropdown's fully resolved state, including the design axes.
@immutable
class FluentDropdownState extends FluentDropdownBaseState {
  /// Creates a resolved state.
  const FluentDropdownState({
    required super.enabled,
    required super.open,
    required super.chevron,
    required this.appearance,
    required this.size,
    super.value,
    super.placeholder,
  });

  /// Fill and outline treatment.
  final FluentDropdownAppearance appearance;

  /// Height and type ramp.
  final FluentDropdownSize size;
}

/// Builds the state a dropdown trigger will be styled and rendered from.
///
/// The first of the three-function recomposition contract.
FluentDropdownState resolveFluentDropdownState({
  bool enabled = true,
  bool open = false,
  FluentDropdownAppearance appearance = FluentDropdownAppearance.outline,
  FluentDropdownSize size = FluentDropdownSize.medium,
  Widget chevron = const Icon(fluentDropdownChevron),
  Widget? value,
  Widget? placeholder,
}) => FluentDropdownState(
  enabled: enabled,
  open: open,
  appearance: appearance,
  size: size,
  chevron: chevron,
  value: value,
  placeholder: placeholder,
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes. Every value comes from a Fluent token; nothing
/// here computes a colour.
///
/// Token sources are the Figma `Dropdown` set, extracted into
/// `test/fixtures/dropdown.json`. That set has **no State axis** — its 24
/// variants are `Appearance` x `Size` x `Expanded` only — so every hover,
/// pressed and disabled value below comes from `useDropdownStyles.styles.ts`
/// instead, and only the Rest column is design-verified.
///
/// Two things the fixture does settle, and they agree with upstream:
///
/// * the **bottom rule is two rules**. Every collapsed `Outline` and
///   `Transparent` variant carries a 1px `Neutral/Stroke/Accessible/Rest`
///   rectangle; every expanded variant of all four appearances replaces it with
///   a 2px `Brand/Stroke/Compound/Rest` one carrying the box's own bottom
///   corner radii. The filled appearances have no rule at all when collapsed.
/// * `Fill lighter` and `Fill darker` bind a **transparent** border rather than
///   none, which is what keeps them outlined in high contrast.
FluentDropdownStyle resolveFluentDropdownStyle(
  FluentDropdownState state,
  FluentThemeData theme,
) {
  final c = theme.colors;

  final background = switch (state.appearance) {
    FluentDropdownAppearance.outline ||
    FluentDropdownAppearance.fillLighter => FluentStateColor.tokens(
      rest: c.neutralBackground1,
      hover: c.neutralBackground1Hover,
      pressed: c.neutralBackground1Pressed,
      disabled: c.neutralBackgroundDisabled,
    ),
    FluentDropdownAppearance.fillDarker => FluentStateColor.tokens(
      rest: c.neutralBackground3,
      hover: c.neutralBackground3Hover,
      pressed: c.neutralBackground3Pressed,
      disabled: c.neutralBackgroundDisabled,
    ),
    FluentDropdownAppearance.transparent => FluentStateColor.tokens(
      rest: c.transparentBackground,
      hover: c.transparentBackgroundHover,
      pressed: c.transparentBackgroundPressed,
      disabled: c.transparentBackground,
    ),
  };

  // Transparent is the one appearance with no box border at all: Figma paints
  // no stroke on it, where the two filled appearances paint an invisible one.
  // The distinction is load-bearing — `transparentStrokeInteractive` turns
  // opaque in high contrast, and a fill-only trigger with no outline would
  // vanish into the surface there.
  final border = switch (state.appearance) {
    FluentDropdownAppearance.outline => FluentStateColor.tokens(
      rest: c.neutralStroke1,
      hover: c.neutralStroke1Hover,
      pressed: c.neutralStroke1Pressed,
      disabled: c.neutralStrokeDisabled,
    ),
    FluentDropdownAppearance.fillLighter ||
    FluentDropdownAppearance.fillDarker => FluentStateColor.tokens(
      rest: c.transparentStrokeInteractive,
      disabled: c.transparentStrokeDisabled,
    ),
    FluentDropdownAppearance.transparent => null,
  };

  final underline = switch (state.appearance) {
    FluentDropdownAppearance.outline ||
    FluentDropdownAppearance.transparent => FluentStateColor.tokens(
      rest: c.neutralStrokeAccessible,
      hover: c.neutralStrokeAccessibleHover,
      pressed: c.neutralStrokeAccessiblePressed,
      disabled: c.neutralStrokeDisabled,
    ),
    FluentDropdownAppearance.fillLighter ||
    FluentDropdownAppearance.fillDarker => null,
  };

  // Geometry, verbatim from the Figma `Input` instance under each variant. The
  // chevron slot's width is its own padding plus the glyph — 2 + 16 + 6 = 24 at
  // small, 2 + 20 + 10 = 32 at medium, 2 + 24 + 12 = 38 at large — and the
  // trigger's height is the glyph plus the slot's vertical inset.
  final (
    height,
    inset,
    chevronInset,
    chevronSize,
    textStyle,
  ) = switch (state.size) {
    FluentDropdownSize.small => (
      24.0,
      FluentSpacing.sNudge,
      FluentSpacing.xs,
      FluentSize.size160,
      theme.typography.caption1,
    ),
    FluentDropdownSize.medium => (
      32.0,
      FluentSpacing.mNudge,
      FluentSpacing.sNudge,
      FluentSize.size200,
      theme.typography.body1,
    ),
    FluentDropdownSize.large => (
      40.0,
      FluentSpacing.m,
      FluentSpacing.s,
      FluentSize.size240,
      theme.typography.body2,
    ),
  };

  return FluentDropdownStyle(
    backgroundColor: background,
    foregroundColor: FluentStateColor.tokens(
      rest: c.neutralForeground1,
      disabled: c.neutralForegroundDisabled,
    ),
    // Figma binds the trigger's own text to `Neutral/Foreground/4/Rest` in all
    // 24 variants — that text is the placeholder, and upstream's `.placeholder`
    // rule names the same token.
    placeholderColor: FluentStateColor.tokens(
      rest: c.neutralForeground4,
      disabled: c.neutralForegroundDisabled,
    ),
    borderColor: border,
    borderWidth: WidgetStatePropertyAll<double?>(
      border == null ? FluentStroke.none : FluentStroke.thin,
    ),
    borderRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allMedium,
    ),
    underlineColor: underline,
    accentColor: FluentStateColor.tokens(
      rest: c.compoundBrandStroke,
      hover: c.compoundBrandStrokeHover,
      pressed: c.compoundBrandStrokePressed,
      disabled: c.neutralStrokeDisabled,
    ),
    accentWidth: const WidgetStatePropertyAll<double?>(FluentStroke.thick),
    textStyle: WidgetStatePropertyAll<TextStyle?>(textStyle),
    padding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.symmetric(horizontal: inset),
    ),
    gap: const WidgetStatePropertyAll<double?>(FluentSpacing.mNudge),
    // Figma stops at the chevron's frame, so its tone is upstream's:
    // `useDropdownStyles.expandIcon` paints `colorNeutralStrokeAccessible`.
    chevronColor: FluentStateColor.tokens(
      rest: c.neutralStrokeAccessible,
      hover: c.neutralStrokeAccessibleHover,
      pressed: c.neutralStrokeAccessiblePressed,
      disabled: c.neutralForegroundDisabled,
    ),
    chevronSize: WidgetStatePropertyAll<double?>(chevronSize),
    chevronPadding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.fromLTRB(FluentSpacing.xxs, chevronInset, inset, chevronInset),
    ),
    // `useDropdownStyles.styles.ts` puts `minWidth: '250px'` on the root, and a
    // live probe reads 250 at all three sizes. Without it the trigger collapses
    // to its content, which is the most visible way this diverges from React.
    minimumSize: WidgetStatePropertyAll<Size?>(Size(_triggerMinWidth, height)),
    mouseCursor: const WidgetStatePropertyAll<MouseCursor?>(
      SystemMouseCursors.click,
    ),
    surfaceColor: FluentStateColor.tokens(rest: c.neutralBackground1),
    surfaceBorderColor: FluentStateColor.tokens(rest: c.transparentStroke),
    surfaceBorderWidth: const WidgetStatePropertyAll<double?>(
      FluentStroke.thin,
    ),
    // Figma binds `Corner-radius/Modal/Medium`; upstream's listbox states none
    // and inherits the popover surface's `borderRadiusMedium`. Same 4.
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
    // Deliberately null. Neither Figma nor `useListboxStyles.styles.ts` states
    // a maximum, because upstream's positioning layer writes one inline from
    // the space left below the trigger and recomputes it on every reposition.
    // `FluentDropdown` reproduces that at build time; a non-null value here —
    // or on `FluentDropdownTheme`, or on the widget's own `style` — is the
    // caller's override and wins.
    surfaceMaxHeight: null,
    // Figma stacks the popup flush against the trigger, but `useComboboxPositioning`
    // offsets it `{ crossAxis: 0, mainAxis: 2 }` and a live probe reads the 2px
    // gap. React wins: flush against the trigger reads as one merged surface.
    surfaceOffset: const WidgetStatePropertyAll<double?>(FluentSpacing.xxs),
  );
}

/// Renders a dropdown trigger from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentDropdownBaseState] rather than [FluentDropdownState] on purpose: it
/// never reads the appearance or the size, so a consumer can supply their own
/// style and still use Fluent's layout and accent animation. It renders the
/// trigger only — the popup is an [Overlay] concern, and its surface has its
/// own builder in [buildFluentDropdownSurface].
///
/// ## Motion
///
/// One thing animates, and it is the bottom accent rule: upstream's `::after`
/// is `transform: scaleX(0)` at rest and `scaleX(1)` under `:focus-within`, so
/// the brand rule grows from the centre outwards. See
/// [fluentDropdownAccentEnter] and [fluentDropdownAccentExit] for the two
/// durations. Nothing else moves — the fill, the border and the chevron all
/// change on the frame the pointer arrives, because `useDropdownStyles`
/// declares no transition on any of them.
///
/// [states] is the live interaction set from [FluentInteractive].
Widget buildFluentDropdown(
  FluentDropdownBaseState state,
  FluentDropdownStyle style,
  Set<WidgetState> states,
) {
  final radius = style.borderRadius?.resolve(states) ?? FluentRadius.allMedium;
  final borderWidth = style.borderWidth?.resolve(states) ?? FluentStroke.none;
  final borderColor = style.borderColor?.resolve(states);
  final underlineColor = style.underlineColor?.resolve(states);
  final accentColor = style.accentColor?.resolve(states);
  final accentWidth = style.accentWidth?.resolve(states) ?? FluentStroke.thick;
  final foreground = state.value == null
      ? style.placeholderColor?.resolve(states)
      : style.foregroundColor?.resolve(states);
  final textStyle = style.textStyle?.resolve(states);
  final padding = style.padding?.resolve(states) ?? EdgeInsets.zero;
  final gap = style.gap?.resolve(states) ?? FluentSpacing.mNudge;
  final chevronColor = style.chevronColor?.resolve(states);
  final chevronSize = style.chevronSize?.resolve(states) ?? FluentSize.size200;
  final chevronPadding =
      style.chevronPadding?.resolve(states) ?? EdgeInsets.zero;
  final minimumSize = style.minimumSize?.resolve(states) ?? Size.zero;

  Widget label = Padding(
    padding: padding,
    // heightFactor, or the Align fills the whole loose height it is offered and
    // a dropdown in a Column becomes as tall as the screen.
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      heightFactor: 1,
      child: state.value ?? state.placeholder ?? const SizedBox.shrink(),
    ),
  );
  if (textStyle != null || foreground != null) {
    label = DefaultTextStyle.merge(
      style: (textStyle ?? const TextStyle()).copyWith(color: foreground),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      child: label,
    );
  }

  final content = Row(
    children: <Widget>[
      Expanded(child: label),
      SizedBox(width: gap),
      Padding(
        padding: chevronPadding,
        child: IconTheme.merge(
          data: IconThemeData(color: chevronColor, size: chevronSize),
          child: state.chevron,
        ),
      ),
    ],
  );

  // The rule at rest, and the brand rule that grows over it. Figma draws both
  // as rules pinned to the bottom edge — 1px for the resting one, 2px for the
  // accent — and BOTH carry the box's bottom radii, so neither runs past the
  // curve at the ends.
  final rules = <Widget>[
    if (underlineColor != null)
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: SizedBox(
          height: FluentStroke.thin,
          // Rounded, not a bare rectangle. Upstream draws this as the field's
          // own `border-bottom`, so it follows the corner radius for free; we
          // draw it as a separate rule because Figma's `Thin underline` is its
          // own rect (the Transparent appearance has no border yet still shows
          // it) and Flutter asserts on a non-uniform border under a
          // borderRadius. FluentInputUnderline is how a 1px rule keeps a 4px
          // corner anyway.
          child: FluentInputUnderline(
            color: underlineColor,
            thickness: FluentStroke.thin,
            borderRadius: BorderRadius.only(
              bottomLeft: radius.bottomLeft,
              bottomRight: radius.bottomRight,
            ),
          ),
        ),
      ),
    if (accentColor != null)
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        height: accentWidth,
        child: FluentInputFocusUnderline(
          focused: state.open || states.contains(WidgetState.focused),
          color: accentColor,
          thickness: accentWidth,
          borderRadius: BorderRadius.only(
            bottomLeft: radius.bottomLeft,
            bottomRight: radius.bottomRight,
          ),
        ),
      ),
  ];

  return ConstrainedBox(
    constraints: BoxConstraints(
      minHeight: minimumSize.height,
      minWidth: minimumSize.width,
    ),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: style.backgroundColor?.resolve(states),
        borderRadius: radius,
        border: borderWidth > 0 && borderColor != null
            ? Border.all(color: borderColor, width: borderWidth)
            : null,
      ),
      child: Stack(children: <Widget>[content, ...rules]),
    ),
  );
}

/// Renders the popup surface [child] sits on.
///
/// Separate from [buildFluentDropdown] because the two are rendered into
/// different branches of the tree: the trigger into the caller's subtree, this
/// into the [Overlay]. Both read the same [FluentDropdownStyle].
Widget buildFluentDropdownSurface(
  FluentDropdownStyle style,
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

/// Overrides the dropdown style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`.
class FluentDropdownTheme extends InheritedTheme {
  /// Applies [style] to every `FluentDropdown` in [child].
  const FluentDropdownTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the appearance and size defaults.
  final FluentDropdownStyle style;

  /// The nearest dropdown style, or null.
  static FluentDropdownStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentDropdownTheme>()?.style;

  @override
  bool updateShouldNotify(FluentDropdownTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentDropdownTheme(style: style, child: child);
}

/// Moves the active option by [delta] rows, opening the popup if it is closed.
class FluentDropdownMoveIntent extends Intent {
  /// Creates an intent to move the active option.
  const FluentDropdownMoveIntent(this.delta);

  /// How many rows to move. Negative walks towards the top of the list.
  final int delta;
}

/// Jumps the active option to the first or last selectable row.
class FluentDropdownEdgeIntent extends Intent {
  /// Creates an intent to jump to an end of the list.
  const FluentDropdownEdgeIntent({required this.last});

  /// Whether to jump to the last row rather than the first.
  final bool last;
}

/// Opens the popup, or commits the active option when it is already open.
class FluentDropdownActivateIntent extends Intent {
  /// Creates an activation intent.
  const FluentDropdownActivateIntent();
}

/// A Fluent 2 single-select dropdown.
///
/// ```dart
/// FluentDropdown<String>(
///   value: city,
///   placeholder: const Text('Pick a city'),
///   options: const [
///     FluentDropdownOption(value: 'lis', label: Text('Lisbon')),
///     FluentDropdownOption(value: 'osl', label: Text('Oslo')),
///   ],
///   onChanged: (value) => setState(() => city = value),
/// )
/// ```
///
/// Pass `onChanged: null` to disable it — disabled is a real state here, not a
/// visual treatment: the trigger stops reporting hover and press, refuses
/// focus, never opens, and swaps to the disabled token ramp.
///
/// ## Single select only
///
/// Multi-select is **not modelled**. Figma's `.ListItem` set has a
/// `Type=Multi select` variant whose leading slot is a checkbox rather than a
/// checkmark, and upstream's `Dropdown` takes `multiselect` with an array
/// value; neither is ported. [value] is one option's value or null.
///
/// ## Keyboard
///
/// | Key | Closed | Open |
/// |---|---|---|
/// | Down / Up | opens, active on the selected option | moves the active option |
/// | Home / End | opens, active on the first / last option | jumps to first / last |
/// | Enter / Space | opens | selects the active option and closes |
/// | Escape | — | closes, nothing selected |
/// | Tab | moves on | closes, then moves on |
///
/// Focus never leaves the trigger while the popup is open — the rows are
/// deliberately outside the traversal order, so "focus returns to the trigger
/// on close" is structural rather than something this widget has to remember to
/// do. The active row is marked with [WidgetState.focused] all the same,
/// because that is what keyboard-visible focus *means* to the user.
///
/// ## Dismissing by pointer needs a [TapRegionSurface]
///
/// An open popup is dismissed by a tap outside it via [TapRegion], which does
/// nothing without a [TapRegionSurface] above it. [WidgetsApp] installs one
/// (`widgets/app.dart:1836`) and `FluentApp` wraps [WidgetsApp], so an ordinary
/// app — and the widget tests — are covered. A dropdown mounted under a bare
/// [Overlay] with no [WidgetsApp] anywhere above it silently loses outside-tap
/// dismissal; Escape, Tab and choosing a row still close it.
///
/// Nothing is drawn over the page while the popup is up, deliberately. A click
/// on a control behind an open popup dismisses the popup *and* presses that
/// control, hover still tracks, and the page still scrolls — which is what
/// upstream's document-level `useOnClickOutside` gives React.
///
/// Customisation follows the usual three rungs. [style] is merged last and
/// wins; [FluentDropdownTheme] restyles a subtree; and for anything further,
/// [resolveFluentDropdownState], [resolveFluentDropdownStyle] and
/// [buildFluentDropdown] are public so any one of them can be replaced without
/// forking this widget. Rows follow the same three rungs through [optionStyle]
/// and [FluentDropdownOptionTheme].
class FluentDropdown<T> extends StatefulWidget {
  /// Creates a dropdown over [options].
  const FluentDropdown({
    super.key,
    required this.options,
    this.value,
    this.onChanged,
    this.placeholder,
    this.appearance = FluentDropdownAppearance.outline,
    this.size = FluentDropdownSize.medium,
    this.style,
    this.optionStyle,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  /// The rows the popup shows, in order. Headers are included here.
  final List<FluentDropdownOption<T>> options;

  /// The selected value, or null for none.
  ///
  /// A value with no matching option renders as the placeholder rather than
  /// throwing — a list that changes under a stale value is a normal state, not
  /// a programming error.
  final T? value;

  /// Invoked with the chosen value. Null disables the dropdown.
  final ValueChanged<T>? onChanged;

  /// What the trigger shows while [value] selects nothing.
  final Widget? placeholder;

  /// Fill and outline treatment.
  final FluentDropdownAppearance appearance;

  /// Height and type ramp.
  final FluentDropdownSize size;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentDropdownStyle? style;

  /// Row overrides layered over the theme defaults. Merged last, so it wins.
  final FluentDropdownOptionStyle? optionStyle;

  /// Focus node to use. One is created internally when omitted.
  final FocusNode? focusNode;

  /// Whether to take focus on mount.
  final bool autofocus;

  /// Announced by assistive technology alongside the selected value.
  final String? semanticLabel;

  @override
  State<FluentDropdown<T>> createState() => _FluentDropdownState<T>();
}

class _FluentDropdownState<T> extends State<FluentDropdown<T>> {
  final LayerLink _link = LayerLink();
  final Map<int, GlobalKey> _rowKeys = <int, GlobalKey>{};
  OverlayEntry? _entry;
  FocusNode? _internalNode;
  int? _active;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalNode ??= FocusNode());

  bool get _enabled => widget.onChanged != null;

  bool get _open => _entry != null;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The popup builds from *this* State's context but lives in the Overlay's
    // branch of the tree, so nothing rebuilds it when a dependency here moves.
    // Two visible bugs came out of that: the max height was measured once at
    // open and never again, so resizing the window left the list running off
    // the screen; and a `FluentThemeOverride` swapped under a const subtree
    // left the open popup painting the old tokens. `FluentInfoButton` already
    // does this.
    deferOrRun(() => _entry?.markNeedsBuild());
  }

  @override
  void didUpdateWidget(FluentDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChange);
      _focusNode.addListener(_handleFocusChange);
    }
    if (!_enabled) {
      deferOrRun(_close);
    } else if (_open) {
      // Deferred for the same reason the close above is: `didUpdateWidget` runs
      // inside the parent's build, and the entry lives in the Overlay's branch,
      // which that build has already passed. A parent that rebuilds while the
      // popup is up — anything driving the list from its own state — would
      // otherwise trip "markNeedsBuild() called during build".
      deferOrRun(() => _entry?.markNeedsBuild());
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _entry
      ?..remove()
      ..dispose();
    _entry = null;
    _internalNode?.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    // Tab, or a click on something else, takes focus away; the popup must not
    // outlive it.
    if (!_focusNode.hasFocus && _open) deferOrRun(_close);
  }

  int? get _selectedIndex {
    for (var i = 0; i < widget.options.length; i++) {
      final option = widget.options[i];
      if (!option.isHeader && option.value == widget.value) return i;
    }
    return null;
  }

  bool _selectable(int index) {
    final option = widget.options[index];
    return option.enabled && !option.isHeader;
  }

  /// The first selectable row at or after [from], walking by [delta].
  int? _seek(int from, int delta) {
    for (var i = from; i >= 0 && i < widget.options.length; i += delta) {
      if (_selectable(i)) return i;
    }
    return null;
  }

  void _openPopup({int? active}) {
    if (_open || !_enabled) return;
    final overlay = Overlay.of(context, debugRequiredFor: widget);
    // FluentTheme is an InheritedTheme, so this carries it — and any other
    // InheritedTheme between here and the overlay, including
    // FluentDropdownOptionTheme — across the boundary.
    final captured = InheritedTheme.capture(from: context, to: overlay.context);
    _active = active ?? _selectedIndex ?? _seek(0, 1);
    _entry = OverlayEntry(builder: (_) => captured.wrap(_buildPopup()));
    overlay.insert(_entry!);
    setState(() {});
    _revealActive();
  }

  void _close() {
    final entry = _entry;
    if (entry == null) return;
    _entry = null;
    _active = null;
    _rowKeys.clear();
    entry
      ..remove()
      ..dispose();
    if (mounted) setState(() {});
  }

  void _toggle() {
    if (_open) {
      _close();
      return;
    }
    // Focus the trigger before opening. Arrow handling lives in this widget's
    // Shortcuts, and the rows are deliberately outside the traversal order, so
    // focus has to be HERE for the keyboard to reach the popup at all. Opening
    // by pointer used to leave focus wherever it was, which left the list
    // stranded on whichever row `_openPopup` seeded — the selected one.
    // Upstream gets this free: its trigger is a real `<button>`, and a browser
    // focuses a button on mousedown.
    _focusNode.requestFocus();
    _openPopup();
  }

  void _select(int index) {
    final option = widget.options[index];
    _close();
    widget.onChanged!(option.value);
  }

  void _setActive(int? index) {
    if (index == null || index == _active) return;
    _active = index;
    _entry?.markNeedsBuild();
    _revealActive();
  }

  /// Scrolls the active row into view on the next frame, once the popup has
  /// rebuilt and the row's element exists.
  void _revealActive() {
    final index = _active;
    if (index == null) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final target = _rowKeys[index]?.currentContext;
      if (target != null) Scrollable.ensureVisible(target, alignment: 0.5);
    });
  }

  void _move(int delta) {
    if (!_open) {
      _openPopup(active: _selectedIndex ?? _seek(delta > 0 ? 0 : _last, delta));
      return;
    }
    final from = (_active ?? (delta > 0 ? -1 : widget.options.length)) + delta;
    _setActive(_seek(from, delta));
  }

  int get _last => widget.options.length - 1;

  void _edge({required bool last}) {
    final target = last ? _seek(_last, -1) : _seek(0, 1);
    if (!_open) {
      _openPopup(active: target);
      return;
    }
    _setActive(target);
  }

  void _activate() {
    if (!_open) {
      _openPopup();
      return;
    }
    final index = _active;
    if (index != null && _selectable(index)) {
      _select(index);
    } else {
      _close();
    }
  }

  FluentDropdownStyle _resolvedStyle(FluentDropdownState state) =>
      resolveFluentDropdownStyle(
        state,
        FluentTheme.of(context),
      ).merge(FluentDropdownTheme.maybeOf(context)).merge(widget.style);

  FluentDropdownState _state() {
    final selected = _selectedIndex;
    return resolveFluentDropdownState(
      enabled: _enabled,
      open: _open,
      appearance: widget.appearance,
      size: widget.size,
      value: selected == null ? null : widget.options[selected].label,
      placeholder: widget.placeholder,
    );
  }

  Widget _buildPopup() {
    final style = _resolvedStyle(_state());
    const surfaceStates = <WidgetState>{};
    final gap = style.surfaceGap?.resolve(surfaceStates) ?? FluentSpacing.xxs;
    final offset = style.surfaceOffset?.resolve(surfaceStates) ?? 0;

    // Upstream's positioning layer writes `max-height` inline from the space
    // left below the trigger and recomputes it on every reposition; a fixed
    // number would clip a long list on a tall screen and overflow a short one.
    // The popup opens under the trigger, so it starts at the trigger's bottom
    // edge plus the 2px gap.
    //
    // Measured off the trigger's render box rather than the leader layer — see
    // [fluentAnchorRect] for why the layer lies once the page has scrolled.
    final anchor = fluentAnchorRect(context);
    final surfaceStyle = style.surfaceMaxHeight != null
        ? style
        : style.copyWith(
            surfaceMaxHeight: WidgetStatePropertyAll<double?>(
              math.max(
                MediaQuery.sizeOf(context).height -
                    (anchor?.bottom ?? 0) -
                    offset,
                0,
              ),
            ),
          );
    final optionThemeStyle = FluentDropdownOptionTheme.maybeOf(context);
    final theme = FluentTheme.of(context);

    final rows = <Widget>[
      for (var i = 0; i < widget.options.length; i++) ...<Widget>[
        // `useOptionGroupStyles.styles.ts` — every `OptionGroup` but the last
        // draws `borderBottom: strokeWidthThin solid colorNeutralStroke2`
        // below itself, with `paddingBottom: spacingHorizontalXS` (4) above the
        // rule and `marginBottom: spacingVerticalXS` (4) below it. That
        // pseudo-element is itself a flex item, so those 4s stack ON TOP of the
        // list's own `rowGap: spacingHorizontalXXS` (2) rather than absorbing
        // it: the real gap is 6 above and 6 below. A group starts at a header
        // here, so the rule goes before every header that is not the first row,
        // and 4 of inset plus the Column's 2 of gap reproduces the 6.
        //
        // ponytail: the rule spans the content width. Upstream's `margin: 0
        // -4px` bleeds it across the surface padding, which Flutter cannot
        // express as a negative inset — an `OverflowBox` sized from
        // `_link.leaderSize` would, if the 4 either side ever shows.
        if (i > 0 && widget.options[i].isHeader)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: FluentSpacing.xs),
            child: SizedBox(
              height: FluentStroke.thin,
              child: ColoredBox(color: theme.colors.neutralStroke2),
            ),
          ),
        KeyedSubtree(
          key: _rowKeys.putIfAbsent(i, GlobalKey.new),
          child: _buildRow(i, theme, optionThemeStyle),
        ),
      ],
    ];

    return Positioned(
      left: 0,
      top: 0,
      child: CompositedTransformFollower(
        link: _link,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        offset: Offset(0, offset),
        // Same group as the trigger, so a pointer landing on a row — or on the
        // padding between rows — is "inside" and does not dismiss. Orthogonal
        // to the ExcludeFocus below: that governs traversal, this governs taps.
        child: TapRegion(
          groupId: this,
          // Upstream positions the listbox with `matchTargetSize: 'width'`,
          // and Figma draws it exactly as wide as the trigger — but
          // `useListboxStyles` also floors it at `minWidth: 160px`, which
          // only shows once the trigger is narrower than that.
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: _listboxMinWidth),
            child: SizedBox(
              width: _link.leaderSize?.width,
              // The rows are outside the traversal order on purpose: focus
              // stays on the trigger the whole time the popup is open, which
              // is what makes "focus returns to the trigger on close"
              // structural.
              child: ExcludeFocus(
                child: buildFluentDropdownSurface(
                  surfaceStyle,
                  surfaceStates,
                  SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: gap,
                      children: rows,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(
    int index,
    FluentThemeData theme,
    FluentDropdownOptionStyle? themeStyle,
  ) {
    final option = widget.options[index];
    final state = resolveFluentDropdownOptionState(
      label: option.label,
      enabled: option.enabled,
      selected: !option.isHeader && option.value == widget.value,
      type: option.type,
    );
    final style = resolveFluentDropdownOptionStyle(
      state,
      theme,
    ).merge(themeStyle).merge(widget.optionStyle);

    if (option.isHeader) {
      return Semantics(
        header: true,
        child: buildFluentDropdownOption(state, style, const <WidgetState>{}),
      );
    }

    final row = FluentInteractive(
      enabled: option.enabled,
      onPressed: option.enabled ? () => _select(index) : null,
      mouseCursor:
          style.mouseCursor?.resolve(const <WidgetState>{}) ??
          SystemMouseCursors.click,
      builder: (context, states, _) => ValueListenableBuilder<bool>(
        valueListenable: FluentInputModality.keyboard,
        builder: (context, keyboard, _) =>
            buildFluentDropdownOption(state, style, <WidgetState>{
              ...states,
              // The active row is where the keyboard is, even though the
              // framework's focus never leaves the trigger. `_active` is set by
              // hover too, so on its own it means "active descendant" —
              // upstream's `data-activedescendant`. The ring belongs to its
              // focus-visible sibling, which is this AND.
              if (index == _active && keyboard) WidgetState.focused,
            }),
      ),
    );

    return Semantics(
      button: true,
      selected: state.selected,
      enabled: option.enabled,
      inMutuallyExclusiveGroup: true,
      label: option.text,
      child: row,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _state();
    final style = _resolvedStyle(state);

    final trigger = FluentInteractive(
      // Tapping an open trigger closes it; it never commits, because a pointer
      // user has not chosen anything yet. Enter and Space go through
      // FluentDropdownActivateIntent below instead, which does commit.
      onPressed: _enabled ? _toggle : null,
      enabled: _enabled,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      mouseCursor:
          style.mouseCursor?.resolve(const <WidgetState>{}) ??
          SystemMouseCursors.click,
      builder: (context, states, _) =>
          buildFluentDropdown(state, style, states),
    );

    // No `value:` here on purpose. The selected option's own label is already
    // in the tree and merges into this node, so announcing it a second time as
    // a semantic value made a screen reader say it twice — the same call
    // Material's own dropdown makes.
    return Semantics(
      button: true,
      enabled: _enabled,
      expanded: _open,
      label: widget.semanticLabel,
      child: TapRegion(
        groupId: this,
        // Registered only while the popup is up, so nothing is listening for
        // outside taps the rest of the time.
        //
        // This replaced a full-screen `HitTestBehavior.opaque` barrier drawn
        // over the page. The barrier swallowed the click that dismissed: a
        // button behind an open popup needed two clicks, hover never reached
        // it, and a wheel event never reached the enclosing Scrollable.
        // Upstream's `useOnClickOutside` is a document-level listener — the
        // click dismisses AND lands — and a TapRegion group is the same shape.
        //
        // Known cost: `RenderTapRegionSurface` "does not participate in the
        // gesture disambiguation system" (`widgets/tap_region.dart:189-193`),
        // so a pointer-down outside that turns into a drag-scroll counts as an
        // outside tap and dismisses. That is touch and trackpad only — the
        // wheel is not a pointer-down, and `FluentScrollBehavior` deliberately
        // keeps the mouse out of `dragDevices`. Left as is; the browser does
        // the same thing.
        onTapOutside: _open ? (_) => _close() : null,
        child: CompositedTransformTarget(
          link: _link,
          // Bound here rather than on the focus node so they sit *below* the
          // app's own Enter/Space -> ActivateIntent mapping and above the
          // trigger's, which is the only way Enter can mean "commit the active
          // option" while a tap still only toggles.
          child: Shortcuts(
            shortcuts: const <ShortcutActivator, Intent>{
              SingleActivator(LogicalKeyboardKey.arrowDown):
                  FluentDropdownMoveIntent(1),
              SingleActivator(LogicalKeyboardKey.arrowUp):
                  FluentDropdownMoveIntent(-1),
              SingleActivator(LogicalKeyboardKey.home):
                  FluentDropdownEdgeIntent(last: false),
              SingleActivator(LogicalKeyboardKey.end): FluentDropdownEdgeIntent(
                last: true,
              ),
              SingleActivator(LogicalKeyboardKey.enter):
                  FluentDropdownActivateIntent(),
              SingleActivator(LogicalKeyboardKey.space):
                  FluentDropdownActivateIntent(),
            },
            child: Actions(
              actions: <Type, Action<Intent>>{
                FluentDropdownMoveIntent:
                    CallbackAction<FluentDropdownMoveIntent>(
                      onInvoke: (intent) {
                        _move(intent.delta);
                        return null;
                      },
                    ),
                FluentDropdownEdgeIntent:
                    CallbackAction<FluentDropdownEdgeIntent>(
                      onInvoke: (intent) {
                        _edge(last: intent.last);
                        return null;
                      },
                    ),
                FluentDropdownActivateIntent:
                    CallbackAction<FluentDropdownActivateIntent>(
                      onInvoke: (_) {
                        _activate();
                        return null;
                      },
                    ),
                // Only enabled while the popup is open, so Escape still reaches
                // whatever an ancestor does with it when there is nothing to
                // dismiss here.
                DismissIntent: _DismissDropdownAction<T>(this),
              },
              child: trigger,
            ),
          ),
        ),
      ),
    );
  }
}

/// Closes the popup on Escape, and only while there is one to close.
class _DismissDropdownAction<T> extends Action<DismissIntent> {
  _DismissDropdownAction(this.state);

  final _FluentDropdownState<T> state;

  @override
  bool isEnabled(DismissIntent intent) => state._open;

  @override
  Object? invoke(DismissIntent intent) {
    state._close();
    return null;
  }
}
