import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import '../buttons/button.dart';
import '../buttons/button_style.dart';
import '../internal/focus_ring.dart';
import '../internal/interaction.dart';
import '../l10n/l10n.dart';
import 'popover.dart';
import 'popover_style.dart';
import 'teaching_popover_style.dart';

/// How a teaching popover surface is filled. Figma's `Style` axis, verbatim.
///
/// Two members, not the three [FluentPopoverAppearance] has: the
/// `Teaching Popover` set ships `Default` and `Brand` only, and upstream's
/// `TeachingPopoverProps` likewise takes `appearance?: 'brand'`.
enum FluentTeachingPopoverAppearance {
  /// Neutral surface on the ambient background. The default.
  normal,

  /// Brand fill, with every slot flipped to its on-brand token.
  brand,
}

/// The dismiss glyph a teaching popover's header carries.
const IconData fluentTeachingPopoverDismissIcon =
    FluentIcons.dismiss_20_regular;

/// Multi-step state for a teaching popover's footer.
///
/// The Figma `.TeachingPopover - Footer` set's `Type` axis: `Single` is this
/// being null, `Multi` is it being present. Upstream splits the same two along
/// `TeachingPopoverFooter` and `TeachingPopoverCarouselFooter`.
@immutable
class FluentTeachingPopoverCarousel {
  /// Creates carousel state for a tour of [steps] pages.
  const FluentTeachingPopoverCarousel({
    required this.steps,
    required this.activeStep,
    this.onStepSelected,
    this.pageCount,
    this.stepSemanticLabel,
  });

  /// How many pages the tour has. One dot is drawn per page.
  final int steps;

  /// The page being shown, zero-based. Its dot is drawn as a pill.
  final int activeStep;

  /// Invoked with the page a dot selects. Null makes the dots inert — which is
  /// a real state, not a greyed-out one: they stop taking focus entirely.
  final ValueChanged<int>? onStepSelected;

  /// The "1 of 4" label beside the dots. Omit it to draw dots alone.
  ///
  /// A widget rather than a string because the wording is the caller's to
  /// localise; Fluent states only the ramp and the colour.
  final Widget? pageCount;

  /// Announced for the dot at the given zero-based index.
  ///
  /// Null takes `Step <n> of <steps>` from the ambient [FluentLocalizations].
  /// A dot is a shape with no text in it, so without a label it is invisible to
  /// assistive technology.
  final String Function(int index)? stepSemanticLabel;

  /// The label for the dot at [index].
  ///
  /// Only meaningful once [stepSemanticLabel] is filled in — which
  /// [FluentTeachingPopover] does through [localized] before rendering. Returns
  /// an empty string otherwise rather than inventing English.
  String labelFor(int index) => stepSemanticLabel?.call(index) ?? '';

  /// This carousel with [stepSemanticLabel] supplied from [l10n] when the
  /// caller named none.
  ///
  /// [buildFluentTeachingPopover] takes no [BuildContext] — the recomposition
  /// contract is a pure function of resolved state — so the wording is looked
  /// up one level up and folded in here.
  FluentTeachingPopoverCarousel localized(FluentLocalizations l10n) =>
      stepSemanticLabel != null
      ? this
      : FluentTeachingPopoverCarousel(
          steps: steps,
          activeStep: activeStep,
          onStepSelected: onStepSelected,
          pageCount: pageCount,
          // `index` is zero-based here and one-based in the announcement.
          stepSemanticLabel: (index) => l10n.stepOf(index + 1, steps),
        );
}

/// Everything needed to render a teaching popover's content, independent of
/// the design axis.
///
/// The counterpart of `FluentButtonBaseState`. [buildFluentTeachingPopover]
/// takes this rather than [FluentTeachingPopoverState], which is what makes
/// "Fluent's state, my own styling, Fluent's rendering" a supported path rather
/// than a fork.
@immutable
class FluentTeachingPopoverBaseState {
  /// Creates a base state.
  const FluentTeachingPopoverBaseState({
    required this.title,
    required this.body,
    required this.dismissSemanticLabel,
    this.header,
    this.media,
    this.onDismiss,
    this.primaryAction,
    this.secondaryAction,
    this.carousel,
  });

  /// The headline. `subtitle2` in every variant.
  final Widget title;

  /// The explanatory paragraph. `body1` in every variant.
  final Widget body;

  /// Announced for the dismiss button.
  final String dismissSemanticLabel;

  /// The small caption above the media — Figma's `Badge` slot. Optional.
  final Widget? header;

  /// The image or illustration between the header and the title. Optional, and
  /// drawn exactly as handed over: Figma's 288 x 90 placeholder is a stand-in
  /// for the caller's artwork, not a size this component imposes.
  final Widget? media;

  /// Invoked by the header's dismiss button. Null draws no dismiss button at
  /// all rather than a disabled one — Figma has no disabled variant of it.
  final VoidCallback? onDismiss;

  /// The confirming action, drawn first and closest to the centre. Normally a
  /// `FluentButton` with `FluentButtonAppearance.primary`.
  final Widget? primaryAction;

  /// The secondary action. Normally a `FluentButton` with the default
  /// `FluentButtonAppearance.secondary`.
  final Widget? secondaryAction;

  /// Multi-step tour state, or null for a single-step popover.
  final FluentTeachingPopoverCarousel? carousel;

  /// Whether anything is drawn below the body.
  bool get hasFooter =>
      primaryAction != null || secondaryAction != null || carousel != null;

  /// Whether anything is drawn above the title.
  bool get hasHeader => header != null || media != null || onDismiss != null;
}

/// A teaching popover's fully resolved state, including the design axis.
///
/// The counterpart of `FluentButtonState`: base state plus exactly
/// `appearance`.
@immutable
class FluentTeachingPopoverState extends FluentTeachingPopoverBaseState {
  /// Creates a resolved state.
  const FluentTeachingPopoverState({
    required super.title,
    required super.body,
    required super.dismissSemanticLabel,
    required this.appearance,
    super.header,
    super.media,
    super.onDismiss,
    super.primaryAction,
    super.secondaryAction,
    super.carousel,
  });

  /// Fill treatment.
  final FluentTeachingPopoverAppearance appearance;
}

/// Builds the state a teaching popover will be styled and rendered from.
///
/// The first of the three-function recomposition contract.
///
/// [l10n] supplies [dismissSemanticLabel] and the carousel's dot labels when
/// the caller names neither. Null takes [fluentLocalizationsFallback], which is
/// US English — [FluentTeachingPopover] passes the ambient catalogue instead.
FluentTeachingPopoverState resolveFluentTeachingPopoverState({
  required Widget title,
  required Widget body,
  FluentTeachingPopoverAppearance appearance =
      FluentTeachingPopoverAppearance.normal,
  String? dismissSemanticLabel,
  FluentLocalizations? l10n,
  Widget? header,
  Widget? media,
  VoidCallback? onDismiss,
  Widget? primaryAction,
  Widget? secondaryAction,
  FluentTeachingPopoverCarousel? carousel,
}) {
  // This is a plain function with no BuildContext, so the wording arrives as a
  // parameter: `FluentTeachingPopover` passes `fluentL10n(context)`, and a
  // hand-composed popover passes its own or takes US English.
  final messages = l10n ?? fluentLocalizationsFallback;
  return FluentTeachingPopoverState(
    appearance: appearance,
    title: title,
    body: body,
    dismissSemanticLabel: dismissSemanticLabel ?? messages.close,
    header: header,
    media: media,
    onDismiss: onDismiss,
    primaryAction: primaryAction,
    secondaryAction: secondaryAction,
    carousel: carousel?.localized(messages),
  );
}

/// Width of the content column. See [FluentTeachingPopoverStyle.contentWidth].
const double _contentWidth = 288;

/// Corner radius of a carousel dot's tap target, and of the focus ring drawn
/// around the dot itself.
///
/// Figma binds `button-corner-radius`, which resolves to
/// `Corner-radius/Button/Default` (4), and upstream's
/// `createCustomFocusIndicatorStyle` names `borderRadiusMedium` — the same 4.
const BorderRadius _dotTargetRadius = FluentRadius.allMedium;

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axis. Every colour comes from a Fluent token selected
/// through [FluentStateColor]; nothing here computes one.
///
/// Token sources are the Figma `Teaching Popover` set and the two
/// `.TeachingPopover - Footer` sets, extracted into
/// `test/fixtures/teaching_popover.json` and
/// `test/fixtures/teaching_popover_footer.json`.
///
/// Four values diverge from `react-teaching-popover`, and Figma wins in all
/// four — see `doc/token-divergences.md`.
FluentTeachingPopoverStyle resolveFluentTeachingPopoverStyle(
  FluentTeachingPopoverState state,
  FluentThemeData theme,
) {
  final c = theme.colors;
  final brand = state.appearance == FluentTeachingPopoverAppearance.brand;

  // Every text slot flips to the single on-brand token on the Brand variant;
  // Figma binds `Neutral/Foreground/On Brand/Rest` on the header, the title,
  // the body and the page count alike, where the neutral variant ramps them
  // 3 / 1 / 1 / 3.
  final onBrand = c.neutralForegroundOnBrand;

  return FluentTeachingPopoverStyle(
    contentWidth: const WidgetStatePropertyAll<double?>(_contentWidth),
    contentGap: const WidgetStatePropertyAll<double?>(FluentSpacing.m),
    headerGap: const WidgetStatePropertyAll<double?>(FluentSpacing.xxs),
    headerTextStyle: WidgetStatePropertyAll<TextStyle?>(
      theme.typography.caption1Strong,
    ),
    headerColor: FluentStateColor.tokens(
      rest: brand ? onBrand : c.neutralForeground3,
    ),
    // Figma stops at the dismiss button's frame, so the glyph's tone is
    // upstream's: `useTeachingPopoverHeaderStyles.dismissButton` states
    // `color: tokens.colorNeutralForeground2` outright rather than inheriting
    // the ambient tone, and a live probe of `.fui-TeachingPopoverHeader__
    // dismissButton` reads `rgb(66, 66, 66)` = #424242 = neutralForeground2.
    // Brand keeps `neutralForegroundOnBrand`, which has no second step.
    dismissColor: FluentStateColor.tokens(
      rest: brand ? onBrand : c.neutralForeground2,
      hover: brand ? onBrand : c.neutralForeground2Hover,
      pressed: brand ? onBrand : c.neutralForeground2Pressed,
    ),
    // Neutral takes the subtle ramp Figma binds. Brand cannot: the subtle
    // hover token is a light neutral, which on a brand fill would flash a grey
    // patch. Upstream gives the dismiss slot `colorTransparentBackground` with
    // no hover at all, and that is what the brand variant uses — still a real
    // token, so it turns opaque in high contrast rather than vanishing.
    dismissBackgroundColor: brand
        ? FluentStateColor.tokens(
            rest: c.transparentBackground,
            hover: c.transparentBackgroundHover,
            pressed: c.transparentBackgroundPressed,
          )
        : FluentStateColor.tokens(
            rest: c.subtleBackground,
            hover: c.subtleBackgroundHover,
            pressed: c.subtleBackgroundPressed,
          ),
    dismissPadding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.all(FluentSpacing.xxs),
    ),
    dismissIconSize: const WidgetStatePropertyAll<double?>(FluentSize.size200),
    dismissBorderRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allMedium,
    ),
    mainGap: const WidgetStatePropertyAll<double?>(FluentSpacing.s),
    titleTextStyle: WidgetStatePropertyAll<TextStyle?>(
      theme.typography.subtitle2,
    ),
    titleColor: FluentStateColor.tokens(
      rest: brand ? onBrand : c.neutralForeground1,
    ),
    bodyTextStyle: WidgetStatePropertyAll<TextStyle?>(theme.typography.body1),
    bodyColor: FluentStateColor.tokens(
      rest: brand ? onBrand : c.neutralForeground1,
    ),
    footerPadding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.only(top: FluentSpacing.m),
    ),
    footerGap: const WidgetStatePropertyAll<double?>(FluentSpacing.s),
    // Figma binds ONE token to both the selected pill and the unselected dot,
    // and React instead mixes 30% of `colorBrandBackground` into transparent
    // through CSS `color-mix`. A computed colour is not something this package
    // does, and it is not needed: the two states differ by shape — 16 x 8
    // against 8 x 8 — which is legible without a second tone and survives high
    // contrast, where a 30% tint would not.
    dotColor: FluentStateColor.tokens(
      rest: brand ? onBrand : c.brandForeground2,
    ),
    dotBackgroundColor: FluentStateColor.tokens(
      rest: c.transparentBackground,
      hover: c.transparentBackgroundHover,
      pressed: c.transparentBackgroundPressed,
    ),
    dotPadding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.symmetric(
        horizontal: FluentSpacing.xs,
        vertical: FluentSpacing.sNudge,
      ),
    ),
    dotBorderRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allCircular,
    ),
    dotSize: const WidgetStatePropertyAll<Size?>(
      Size.square(FluentSize.size80),
    ),
    activeDotSize: const WidgetStatePropertyAll<Size?>(
      Size(FluentSize.size160, FluentSize.size80),
    ),
    pageCountColor: FluentStateColor.tokens(
      rest: brand ? onBrand : c.neutralForeground3,
    ),
    // Null on neutral: Figma's two footer buttons there bind exactly what
    // `FluentButtonAppearance.primary` and `.secondary` already resolve to, so
    // an override would restate the button's own table.
    primaryButtonStyle: brand
        ? FluentButtonStyle(
            backgroundColor: FluentStateColor.tokens(rest: onBrand),
            // Figma binds `Brand/Foreground/On Light/Rest`; upstream's
            // `brandPrimary` rule says `colorBrandForeground1`, and ramps hover
            // and press through `colorCompoundBrandForeground1*`. Figma wins on
            // the rest tone, and its own ramp carries the other two.
            foregroundColor: FluentStateColor.tokens(
              rest: c.brandForegroundOnLight,
              hover: c.brandForegroundOnLightHover,
              pressed: c.brandForegroundOnLightPressed,
            ),
            borderWidth: const WidgetStatePropertyAll<double?>(
              FluentStroke.none,
            ),
          )
        : null,
    secondaryButtonStyle: brand
        ? FluentButtonStyle(
            backgroundColor: FluentStateColor.tokens(
              rest: c.brandBackground,
              hover: c.brandBackgroundHover,
              pressed: c.brandBackgroundPressed,
            ),
            foregroundColor: FluentStateColor.tokens(rest: onBrand),
            // Figma binds `Neutral/Stroke/on Brand/2/Rest`; upstream's
            // `brandSecondary` rule uses `colorNeutralForegroundOnBrand`. Both
            // are white in light mode; only Figma's is a stroke token.
            borderColor: FluentStateColor.tokens(rest: c.neutralStrokeOnBrand2),
            borderWidth: const WidgetStatePropertyAll<double?>(
              FluentStroke.thin,
            ),
          )
        : null,
  );
}

/// Renders a teaching popover's content from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentTeachingPopoverBaseState] rather than [FluentTeachingPopoverState] on
/// purpose: it never reads the appearance, so a consumer can supply their own
/// style and still use Fluent's layout.
///
/// This is the **content only**. The surface it sits on — fill, border, radius,
/// padding, shadow, arrow — is [buildFluentPopover]'s, which is why a teaching
/// popover has no surface tokens of its own to disagree about.
///
/// [states] is present for symmetry with the rest of the package. The content
/// as a whole is never hovered, pressed or focused — its dismiss button and its
/// carousel dots are, and they run their own [FluentInteractive] — so callers
/// normally pass an empty set.
Widget buildFluentTeachingPopover(
  FluentTeachingPopoverBaseState state,
  FluentTeachingPopoverStyle style,
  Set<WidgetState> states,
) {
  final width = style.contentWidth?.resolve(states) ?? _contentWidth;
  final contentGap = style.contentGap?.resolve(states) ?? FluentSpacing.m;
  final mainGap = style.mainGap?.resolve(states) ?? FluentSpacing.s;

  final blocks = <Widget>[
    if (state.hasHeader) _buildHeaderBlock(state, style, states),
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: mainGap,
      children: <Widget>[
        _text(state.title, style.titleTextStyle, style.titleColor, states),
        _text(state.body, style.bodyTextStyle, style.bodyColor, states),
      ],
    ),
    if (state.hasFooter)
      Padding(
        padding: style.footerPadding?.resolve(states) ?? EdgeInsets.zero,
        child: _buildFooter(state, style, states),
      ),
  ];

  // ponytail: a fixed width, not a minimum. Figma states 288 and upstream
  // states `minWidth: 320px`, which grows; matching the growth needs an
  // IntrinsicWidth, and an intrinsic pass measures the body copy at its
  // longest unbroken line — so the popover would stop wrapping at 288 and
  // stretch to the width of the sentence. If a caller ever needs a wider
  // teaching popover, `style.contentWidth` is the knob.
  return SizedBox(
    width: width,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: contentGap,
      children: blocks,
    ),
  );
}

/// The caption row and the media under it — Figma's `Header + Content` frame.
Widget _buildHeaderBlock(
  FluentTeachingPopoverBaseState state,
  FluentTeachingPopoverStyle style,
  Set<WidgetState> states,
) {
  final row = <Widget>[
    Expanded(
      child: state.header == null
          ? const SizedBox.shrink()
          : _text(
              state.header!,
              style.headerTextStyle,
              style.headerColor,
              states,
            ),
    ),
    if (state.onDismiss != null) _buildDismiss(state, style, states),
  ];

  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: style.headerGap?.resolve(states) ?? FluentSpacing.xxs,
    children: <Widget>[
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: row),
      if (state.media != null) state.media!,
    ],
  );
}

/// The header's trailing dismiss button.
///
/// Built inline rather than from a `FluentButton`: Figma draws a 24-square
/// target around a 20 glyph, where the button ramp's smallest medium is 32 and
/// its icon-only inset is 8.
Widget _buildDismiss(
  FluentTeachingPopoverBaseState state,
  FluentTeachingPopoverStyle style,
  Set<WidgetState> states,
) {
  final padding = style.dismissPadding?.resolve(states) ?? EdgeInsets.zero;
  final radius =
      style.dismissBorderRadius?.resolve(states) ?? FluentRadius.allMedium;
  final size = style.dismissIconSize?.resolve(states) ?? FluentSize.size200;

  return Semantics(
    button: true,
    label: state.dismissSemanticLabel,
    child: FluentInteractive(
      onPressed: state.onDismiss,
      builder: (context, buttonStates, _) => FluentFocusRing(
        visible: buttonStates.contains(WidgetState.focused),
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: style.dismissBackgroundColor?.resolve(buttonStates),
            borderRadius: radius,
          ),
          child: Padding(
            padding: padding,
            child: IconTheme.merge(
              data: IconThemeData(
                color: style.dismissColor?.resolve(buttonStates),
                size: size,
              ),
              child: const Icon(fluentTeachingPopoverDismissIcon),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The action row, with or without the carousel between its two buttons.
Widget _buildFooter(
  FluentTeachingPopoverBaseState state,
  FluentTeachingPopoverStyle style,
  Set<WidgetState> states,
) {
  final gap = style.footerGap?.resolve(states) ?? FluentSpacing.s;

  final primary = state.primaryAction == null
      ? null
      : _themedButton(state.primaryAction!, style.primaryButtonStyle);
  final secondary = state.secondaryAction == null
      ? null
      : _themedButton(state.secondaryAction!, style.secondaryButtonStyle);

  final carousel = state.carousel;
  if (carousel == null) {
    // Figma's `Type=Single` frame right-aligns its row and puts the primary
    // button FIRST, which is also the order `renderTeachingPopoverFooter`
    // emits. The two agree, unusual as the reading order looks.
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      spacing: gap,
      children: <Widget>[?primary, ?secondary],
    );
  }

  // `Type=Multi` is space-between: back, the dots, next. With no secondary
  // action the dots take the leading edge, which is upstream's `offset` layout
  // (`& :first-child { margin-inline-end: auto }`).
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    spacing: gap,
    children: <Widget>[
      ?secondary,
      _buildCarousel(carousel, style, states),
      ?primary,
    ],
  );
}

/// Applies the appearance's button overrides to one footer action.
///
/// A [FluentButtonTheme] rather than a wrapper widget, so the override reaches
/// a `FluentButton` however deeply the caller has wrapped it, and so the
/// caller's own `style` still wins over both.
Widget _themedButton(Widget action, FluentButtonStyle? style) =>
    style == null ? action : FluentButtonTheme(style: style, child: action);

/// The dot strip and its page count — Figma's `Pagination` frame.
Widget _buildCarousel(
  FluentTeachingPopoverCarousel carousel,
  FluentTeachingPopoverStyle style,
  Set<WidgetState> states,
) {
  final pageCount = carousel.pageCount;
  return Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: <Widget>[
      // No gap: Figma's `Pagination` frame has itemSpacing 0 and the dots are
      // held apart by their own 4-wide padding. React's nav uses a 4 gap on top
      // of unpadded dots, which halves the distance between them.
      for (var i = 0; i < carousel.steps; i++)
        _buildDot(carousel, i, style, states),
      if (pageCount != null)
        _text(pageCount, style.bodyTextStyle, style.pageCountColor, states),
    ],
  );
}

/// One carousel dot: an 8-square circle, or a 16 x 8 pill when it is active.
Widget _buildDot(
  FluentTeachingPopoverCarousel carousel,
  int index,
  FluentTeachingPopoverStyle style,
  Set<WidgetState> states,
) {
  final selected = index == carousel.activeStep;
  final size = selected
      ? style.activeDotSize?.resolve(states) ??
            const Size(FluentSize.size160, FluentSize.size80)
      : style.dotSize?.resolve(states) ?? const Size.square(FluentSize.size80);
  final radius =
      style.dotBorderRadius?.resolve(states) ?? FluentRadius.allCircular;
  final onSelected = carousel.onStepSelected;

  return Semantics(
    button: true,
    selected: selected,
    inMutuallyExclusiveGroup: true,
    label: carousel.labelFor(index),
    child: FluentInteractive(
      onPressed: onSelected == null ? null : () => onSelected(index),
      builder: (context, dotStates, _) => DecoratedBox(
        decoration: BoxDecoration(
          color: style.dotBackgroundColor?.resolve(dotStates),
          borderRadius: _dotTargetRadius,
        ),
        child: Padding(
          padding: style.dotPadding?.resolve(states) ?? EdgeInsets.zero,
          // Inside the padding, not around it. Upstream puts
          // `createCustomFocusIndicatorStyle` on the dot element itself at
          // `outline-offset: 0`, so the ring hugs the 16 x 8 pill (a 20 x 12
          // outer edge) rather than the tap target Figma draws around it. Wrap
          // the target instead and the ring reads as a 28 x 24 box with the
          // dot floating in the middle of it.
          child: FluentFocusRing(
            visible: dotStates.contains(WidgetState.focused),
            borderRadius: _dotTargetRadius,
            child: SizedBox.fromSize(
              size: size,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: style.dotColor?.resolve(dotStates),
                  borderRadius: radius,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Wraps one text slot in its own ramp and tone.
Widget _text(
  Widget child,
  WidgetStateProperty<TextStyle?>? textStyle,
  WidgetStateProperty<Color?>? color,
  Set<WidgetState> states,
) {
  final resolved = textStyle?.resolve(states);
  final tone = color?.resolve(states);
  if (resolved == null && tone == null) return child;
  return DefaultTextStyle.merge(
    style: (resolved ?? const TextStyle()).copyWith(color: tone),
    child: child,
  );
}

/// Overrides the teaching popover content style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`. Restyling the *surface* is [FluentPopoverTheme]'s job,
/// and it reaches a teaching popover the same way.
class FluentTeachingPopoverTheme extends InheritedTheme {
  /// Applies [style] to every [FluentTeachingPopover] in [child].
  const FluentTeachingPopoverTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the appearance defaults.
  final FluentTeachingPopoverStyle style;

  /// The nearest teaching popover style, or null.
  static FluentTeachingPopoverStyle? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FluentTeachingPopoverTheme>()
      ?.style;

  @override
  bool updateShouldNotify(FluentTeachingPopoverTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentTeachingPopoverTheme(style: style, child: child);
}

/// A Fluent 2 teaching popover.
///
/// ```dart
/// FluentTeachingPopover(
///   open: _open,
///   onOpenChanged: (open) => setState(() => _open = open),
///   header: const Text('New'),
///   title: const Text('Pin your favourites'),
///   body: const Text('Anything you pin shows up here first.'),
///   primaryAction: FluentButton(
///     appearance: FluentButtonAppearance.primary,
///     onPressed: () => setState(() => _open = false),
///     child: const Text('Got it'),
///   ),
///   child: FluentButton(
///     onPressed: () => setState(() => _open = !_open),
///     child: const Text('Show'),
///   ),
/// )
/// ```
///
/// A richer [FluentPopover]: same surface, same anchoring, same entrance, with
/// a caption, an optional image, a headline, a paragraph and a footer of one or
/// two actions — plus, for a multi-step tour, a strip of carousel dots between
/// them.
///
/// Pass `onOpenChanged: null` to disable it. That is a real state, not a visual
/// treatment: nothing reaches the [Overlay] at all, an already-open surface is
/// torn down, and [open] is ignored. It is [FluentPopover]'s behaviour,
/// unchanged.
///
/// ## What this widget does *not* own
///
/// Anchoring, dismissal, focus and motion are all [FluentPopover]'s:
///
/// * Escape closes it, a pointer landing outside closes it, and focus returns
///   to whatever held it when the popover opened.
/// * The content sits in a [FocusScope] with `autofocus`, so Tab cycles within
///   the surface.
/// * The entrance is `FluentMotionSpec.popover` — 400ms on `decelerateMid`,
///   enter only, and instant under [MediaQuery.disableAnimationsOf]. See
///   [FluentPopoverEntrance].
/// * The surface's fill, border, radius, padding, shadow and arrow come from
///   [resolveFluentPopoverStyle] and are overridden through [popoverStyle].
///
/// ## Customisation
///
/// Two style rungs, because there are two components. [style] and
/// [FluentTeachingPopoverTheme] restyle the content; [popoverStyle] and
/// [FluentPopoverTheme] restyle the surface. For anything further,
/// [resolveFluentTeachingPopoverState], [resolveFluentTeachingPopoverStyle] and
/// [buildFluentTeachingPopover] are public so any one of them can be replaced
/// without forking this widget.
class FluentTeachingPopover extends StatelessWidget {
  /// Anchors a teaching popover to [child].
  const FluentTeachingPopover({
    super.key,
    required this.child,
    required this.title,
    required this.body,
    required this.open,
    this.onOpenChanged,
    this.appearance = FluentTeachingPopoverAppearance.normal,
    this.position = FluentPopoverPosition.below,
    this.align = FluentPopoverAlign.center,
    this.withArrow = true,
    this.header,
    this.media,
    this.onDismiss,
    this.dismissSemanticLabel,
    this.primaryAction,
    this.secondaryAction,
    this.carousel,
    this.style,
    this.popoverStyle,
    this.semanticLabel,
  });

  /// The trigger. Rendered in place; the surface is anchored to it.
  final Widget child;

  /// The headline.
  final Widget title;

  /// The explanatory paragraph.
  final Widget body;

  /// Whether the surface is showing.
  ///
  /// Controlled, for the reason [FluentPopover.open] gives: a teaching popover
  /// is opened by something the caller owns and closed by both sides, so one
  /// source of truth is the only arrangement that cannot disagree with itself.
  final bool open;

  /// Reports every open and close — Escape, an outside tap, the dismiss button.
  /// Null disables the popover.
  final ValueChanged<bool>? onOpenChanged;

  /// Fill treatment.
  final FluentTeachingPopoverAppearance appearance;

  /// Which side of [child] the surface sits on.
  final FluentPopoverPosition position;

  /// Where along that side the surface lines up.
  final FluentPopoverAlign align;

  /// Whether to draw the pointing arrow.
  ///
  /// Defaults to true, unlike [FluentPopover]: `useTeachingPopover.ts` states
  /// `withArrow: props.withArrow ?? true`, and a live probe of
  /// `components-teachingpopover--default` renders one without being asked.
  /// Figma agrees far enough — `teaching_popover.json` ships a *visible*
  /// `Top edge - left` arrow part on both variants, where the plain Popover set
  /// ships all twelve of its arrow layers hidden.
  final bool withArrow;

  /// The small caption above the media. Optional.
  final Widget? header;

  /// The image or illustration between the caption and the title. Optional.
  final Widget? media;

  /// Invoked by the header's dismiss button, in addition to `onOpenChanged`
  /// being called with false. Null draws no dismiss button at all.
  final VoidCallback? onDismiss;

  /// Announced for the dismiss button, which has no text of its own.
  ///
  /// Null takes the wording from the ambient [FluentLocalizations], which falls
  /// back to English when no delegate is installed.
  final String? dismissSemanticLabel;

  /// The confirming action. Normally a `FluentButton` with
  /// `FluentButtonAppearance.primary`.
  final Widget? primaryAction;

  /// The secondary action. Normally a default-appearance `FluentButton`.
  final Widget? secondaryAction;

  /// Multi-step tour state, or null for a single-step popover.
  final FluentTeachingPopoverCarousel? carousel;

  /// Content overrides layered over the theme defaults. Merged last, so it
  /// wins.
  final FluentTeachingPopoverStyle? style;

  /// Surface overrides, passed straight through to [FluentPopover.style].
  final FluentPopoverStyle? popoverStyle;

  /// Announced by assistive technology when the surface appears.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final close = onOpenChanged;
    final l10n = fluentL10n(context);
    final state = resolveFluentTeachingPopoverState(
      appearance: appearance,
      title: title,
      body: body,
      dismissSemanticLabel: dismissSemanticLabel,
      l10n: l10n,
      header: header,
      media: media,
      // The dismiss button always closes; `onDismiss` is the caller's hook on
      // top of that, and its presence is what decides the button exists at all.
      onDismiss: onDismiss == null || close == null
          ? null
          : () {
              onDismiss!();
              close(false);
            },
      primaryAction: primaryAction,
      secondaryAction: secondaryAction,
      carousel: carousel,
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentTeachingPopoverStyle(
      state,
      FluentTheme.of(context),
    ).merge(FluentTeachingPopoverTheme.maybeOf(context)).merge(style);

    return FluentPopover(
      open: open,
      onOpenChanged: onOpenChanged,
      appearance: switch (appearance) {
        FluentTeachingPopoverAppearance.normal =>
          FluentPopoverAppearance.normal,
        FluentTeachingPopoverAppearance.brand => FluentPopoverAppearance.brand,
      },
      position: position,
      align: align,
      withArrow: withArrow,
      style: popoverStyle,
      semanticLabel: semanticLabel,
      content: buildFluentTeachingPopover(
        state,
        resolved,
        const <WidgetState>{},
      ),
      child: child,
    );
  }
}
