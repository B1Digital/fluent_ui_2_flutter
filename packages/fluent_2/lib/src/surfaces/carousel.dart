import 'dart:async';

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

import '../buttons/button.dart';
import '../buttons/button_style.dart';
import '../internal/animated_style.dart';
import '../internal/interaction.dart';
import '../l10n/l10n.dart';
import 'carousel_style.dart';

/// Where the nav strip sits relative to the slide. Figma's `Layout` axis.
enum FluentCarouselLayout {
  /// The strip floats over the bottom of the slide, on a translucent wash.
  overContent,

  /// The strip sits below the slide, on the page background. The default.
  outsideContent,
}

/// Where the previous/next chevrons sit. Figma's `Chevron placement` axis.
enum FluentCarouselChevronPlacement {
  /// Chevrons pushed to the carousel's left and right edges, indicator between
  /// them. The default.
  flexibleToEdges,

  /// Chevrons hugging the indicator, the three centred as one group.
  groupedToSteps,

  /// Chevrons flanking the slide, vertically centred on it; the indicator sits
  /// alone in the nav strip.
  centeredToContent,
}

/// What the indicator strip shows. Figma's `Nav Type` axis.
enum FluentCarouselNavType {
  /// A row of dots, the current one drawn as a pill. The default.
  steps,

  /// A row of image thumbnails, the current one larger.
  imagePreview,
}

/// Where the autoplay affordance lives. Figma's `Pause Button` axis.
enum FluentCarouselPauseButton {
  /// A play/pause button in the nav strip, before the previous chevron.
  inNav,

  /// No button; clicking the slide toggles autoplay. The default.
  onContentClick,
}

/// The slide transition.
///
/// **Transcribed, not chosen.** `react-carousel` declares no CSS transition and
/// references no `motionTokens` anywhere — `useCarouselStyles.styles.ts`,
/// `useCarouselSliderStyles.styles.ts` and `useCarouselNavButtonStyles.styles.ts`
/// are all pure layout. The slide is animated by embla-carousel instead:
/// `useEmblaCarousel.ts` passes `duration: motionDuration`, where
/// `motionDuration` defaults to **25**. That 25 is embla's own scroll-speed
/// unit, not milliseconds; embla's engine runs it at roughly ten times that in
/// milliseconds, so ~250ms — which is exactly [FluentDuration.gentle].
///
/// The curve is the one value with no upstream counterpart at all: embla eases
/// with a friction-based lerp rather than a cubic bezier. Fluent's nearest
/// category is the decelerating curve it already uses for a slide arriving, so
/// this pairs the transcribed duration with `FluentMotionSpec.slideEnter`'s
/// curve rather than inventing a third value. Figma states no motion for the
/// Carousel at all, so there is nothing for it to win against here.
const FluentMotionSpec fluentCarouselSlide = FluentMotionSpec(
  duration: FluentDuration.gentle,
  curve: FluentCurve.decelerateMid,
);

/// How long a slide is shown before autoplay advances.
///
/// `useCarousel.ts` — `autoplayInterval = 4000`.
const Duration fluentCarouselAutoplayInterval = Duration(milliseconds: 4000);

/// Everything needed to render a carousel, independent of the nav type.
///
/// The Dart counterpart of upstream's `CarouselState`. [buildFluentCarousel]
/// takes this rather than [FluentCarouselState], which is what makes "Fluent's
/// state, my own styling, Fluent's rendering" a supported path rather than a
/// fork.
///
/// [previews] is what decides between the two indicators, so nothing in
/// [buildFluentCarousel] has to read the `Nav Type` axis: null means dots, a
/// list means thumbnails.
@immutable
class FluentCarouselBaseState {
  /// Creates a base state.
  const FluentCarouselBaseState({
    required this.enabled,
    required this.count,
    required this.index,
    required this.viewport,
    required this.layout,
    required this.chevronPlacement,
    required this.previousLabel,
    required this.nextLabel,
    required this.stepLabel,
    this.header,
    this.previews,
    this.autoplayControl,
    this.onPrevious,
    this.onNext,
    this.onStepSelected,
  });

  /// Whether the carousel responds to input at all.
  final bool enabled;

  /// How many slides there are.
  final int count;

  /// The slide currently in view.
  final int index;

  /// The already-built slide viewport. Behaviour — paging, autoplay, drag —
  /// lives in [FluentCarousel]; this is only what gets painted.
  final Widget viewport;

  /// Where the nav strip sits.
  final FluentCarouselLayout layout;

  /// Where the chevrons sit.
  final FluentCarouselChevronPlacement chevronPlacement;

  /// Announced by assistive technology for the previous-slide chevron.
  final String previousLabel;

  /// Announced by assistive technology for the next-slide chevron.
  final String nextLabel;

  /// Announced by assistive technology for the step at a given index.
  final String Function(int index, int count) stepLabel;

  /// Optional title/description block above the slide.
  final Widget? header;

  /// Thumbnails for the image-preview indicator, one per slide. Null renders
  /// the dot indicator instead.
  final List<Widget>? previews;

  /// The already-built play/pause button, or null when the carousel has no
  /// autoplay affordance in the nav.
  final Widget? autoplayControl;

  /// Invoked by the previous chevron. Null disables it — which is a real state,
  /// not a paint job: at the first slide of a non-looping carousel it stops
  /// reporting hover, refuses focus, and never fires.
  final VoidCallback? onPrevious;

  /// Invoked by the next chevron. Null disables it.
  final VoidCallback? onNext;

  /// Invoked with the index of a tapped step. Null disables every step.
  final void Function(int index)? onStepSelected;
}

/// A carousel's fully resolved state, including the design axis.
///
/// The counterpart of upstream's resolved state: base state plus exactly
/// `navType`, which is the one axis that changes the size and radius table.
@immutable
class FluentCarouselState extends FluentCarouselBaseState {
  /// Creates a resolved state.
  const FluentCarouselState({
    required super.enabled,
    required super.count,
    required super.index,
    required super.viewport,
    required super.layout,
    required super.chevronPlacement,
    required super.previousLabel,
    required super.nextLabel,
    required super.stepLabel,
    required this.navType,
    super.header,
    super.previews,
    super.autoplayControl,
    super.onPrevious,
    super.onNext,
    super.onStepSelected,
  });

  /// Which indicator the strip shows.
  final FluentCarouselNavType navType;
}

/// Builds the state a carousel will be styled and rendered from.
///
/// Separated so a consumer can reuse Fluent's state resolution while
/// substituting their own styling — the first of the three-function
/// recomposition contract.
///
/// [l10n] supplies [previousLabel], [nextLabel] and [stepLabel] when the caller
/// names none. Null takes [fluentLocalizationsFallback], which is US English —
/// [FluentCarousel] passes the ambient catalogue instead.
FluentCarouselState resolveFluentCarouselState({
  Widget viewport = const SizedBox.shrink(),
  bool enabled = true,
  int count = 0,
  int index = 0,
  FluentCarouselLayout layout = FluentCarouselLayout.outsideContent,
  FluentCarouselChevronPlacement chevronPlacement =
      FluentCarouselChevronPlacement.flexibleToEdges,
  FluentCarouselNavType navType = FluentCarouselNavType.steps,
  String? previousLabel,
  String? nextLabel,
  String Function(int index, int count)? stepLabel,
  FluentLocalizations? l10n,
  Widget? header,
  List<Widget>? previews,
  Widget? autoplayControl,
  VoidCallback? onPrevious,
  VoidCallback? onNext,
  void Function(int index)? onStepSelected,
}) {
  // This is a plain function with no BuildContext, so the wording arrives as a
  // parameter: `FluentCarousel` passes `fluentL10n(context)`, and a
  // hand-composed carousel passes its own or takes US English.
  final messages = l10n ?? fluentLocalizationsFallback;
  return FluentCarouselState(
    enabled: enabled,
    count: count,
    index: index,
    viewport: viewport,
    layout: layout,
    chevronPlacement: chevronPlacement,
    navType: navType,
    previousLabel: previousLabel ?? messages.previousSlide,
    nextLabel: nextLabel ?? messages.nextSlide,
    // `index` is zero-based here and one-based in the announcement.
    stepLabel:
        stepLabel ?? (index, count) => messages.slideOf(index + 1, count),
    header: header,
    previews: previews,
    autoplayControl: autoplayControl,
    onPrevious: onPrevious,
    onNext: onNext,
    onStepSelected: onStepSelected,
  );
}

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axis. Every value comes from a Fluent token; nothing
/// here computes a colour.
///
/// Token sources are the Figma `Carousel` page (`8995:2`), extracted into
/// `test/fixtures/carousel_step.json` and `test/fixtures/carousel_nav.json` and
/// asserted variant-by-variant in the tests.
FluentCarouselStyle resolveFluentCarouselStyle(
  FluentCarouselState state,
  FluentThemeData theme,
) {
  final c = theme.colors;

  // `.Carousel step` binds the mark to the component-scoped `Carousel nav
  // theme` collection. Its `Default` mode is what every shipped variant pins:
  // Rest/Hover/Pressed alias Neutral/Foreground/2/{Rest,Hover,Pressed}. The
  // collection's other two modes (`On brand`, `Brand`) have no counterpart on
  // the component set's axes — all 15 Carousel variants pin `Default` — so
  // they are deliberately not exposed as a Dart axis.
  final stepColor = FluentStateColor.tokens(
    rest: c.neutralForeground2,
    hover: c.neutralForeground2Hover,
    pressed: c.neutralForeground2Pressed,
    disabled: c.neutralForegroundDisabled,
  );

  // The 24x24 hit target. Never Colors.transparent: these four tokens turn
  // opaque in high contrast, which is the only thing outlining a step there.
  final stepBackground = FluentStateColor.tokens(
    rest: c.transparentBackground,
    hover: c.transparentBackgroundHover,
    pressed: c.transparentBackgroundPressed,
    selected: c.transparentBackgroundSelected,
    disabled: c.transparentBackground,
  );

  // Only the over-content strip is washed; the outside-content variants carry
  // no fill on the indicator at all.
  final indicatorBackground = state.layout == FluentCarouselLayout.overContent
      ? WidgetStatePropertyAll<Color?>(c.neutralBackgroundAlpha)
      : null;

  // The image-preview strip is a different size table from the dot strip, and
  // that is the whole of what the Nav Type axis changes.
  final (indicatorRadius, indicatorGap) = switch (state.navType) {
    FluentCarouselNavType.steps => (FluentRadius.allXLarge, FluentSpacing.none),
    FluentCarouselNavType.imagePreview => (
      const BorderRadius.all(FluentRadius.xxxxLarge),
      FluentSpacing.m,
    ),
  };

  return FluentCarouselStyle(
    stepColor: stepColor,
    stepBackgroundColor: stepBackground,
    stepBorderRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allMedium,
    ),
    stepPadding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.symmetric(
        horizontal: FluentSpacing.s,
        vertical: FluentSpacing.s,
      ),
    ),
    activeStepPadding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.symmetric(
        horizontal: FluentSpacing.xs,
        vertical: FluentSpacing.s,
      ),
    ),
    stepSize: const WidgetStatePropertyAll<Size?>(
      Size(FluentSize.size80, FluentSize.size80),
    ),
    activeStepSize: const WidgetStatePropertyAll<Size?>(
      Size(FluentSize.size160, FluentSize.size80),
    ),
    indicatorBackgroundColor: indicatorBackground,
    indicatorBorderRadius: WidgetStatePropertyAll<BorderRadius?>(
      indicatorRadius,
    ),
    previewSize: const WidgetStatePropertyAll<Size?>(
      Size(FluentSize.size400, FluentSize.size400),
    ),
    selectedPreviewSize: const WidgetStatePropertyAll<Size?>(
      Size(FluentSize.size480, FluentSize.size480),
    ),
    previewBorderRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allSmall,
    ),
    previewGap: WidgetStatePropertyAll<double?>(indicatorGap),
    navGap: const WidgetStatePropertyAll<double?>(FluentSpacing.m),
    controlGap: const WidgetStatePropertyAll<double?>(FluentSpacing.s),
    navSpacing: const WidgetStatePropertyAll<double?>(FluentSpacing.m),
    navInset: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.symmetric(horizontal: FluentSpacing.m),
    ),
    iconSize: const WidgetStatePropertyAll<double?>(FluentSize.size200),
  );
}

/// Renders a carousel from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentCarouselBaseState] rather than [FluentCarouselState] on purpose: it
/// never reads the nav type, because [FluentCarouselBaseState.previews] already
/// says which indicator to draw.
///
/// [states] is the carousel container's own state set — in practice
/// `{WidgetState.disabled}` or empty. The per-step hover and press states are
/// resolved by each step's own `FluentButton`, not here.
///
/// The viewport must be given a bounded height by its parent, exactly as any
/// other Flutter viewport is.
Widget buildFluentCarousel(
  FluentCarouselBaseState state,
  FluentCarouselStyle style,
  Set<WidgetState> states,
) {
  final navGap = style.navGap?.resolve(states) ?? FluentSpacing.m;
  final controlGap = style.controlGap?.resolve(states) ?? FluentSpacing.s;
  final navSpacing = style.navSpacing?.resolve(states) ?? FluentSpacing.m;
  final navInset = style.navInset?.resolve(states) ?? EdgeInsets.zero;
  final iconSize = style.iconSize?.resolve(states) ?? FluentSize.size200;
  final indicatorBackground = style.indicatorBackgroundColor?.resolve(states);
  final indicatorRadius =
      style.indicatorBorderRadius?.resolve(states) ?? BorderRadius.zero;
  final previewGap = style.previewGap?.resolve(states) ?? FluentSpacing.none;

  final previews = state.previews;
  Widget indicator = Row(
    mainAxisSize: MainAxisSize.min,
    spacing: previews == null ? FluentSpacing.none : previewGap,
    children: <Widget>[
      for (var i = 0; i < state.count; i++)
        FluentCarouselStep(
          selected: i == state.index,
          semanticLabel: state.stepLabel(i, state.count),
          preview: previews == null ? null : previews[i],
          onPressed: state.onStepSelected == null
              ? null
              : () => state.onStepSelected!(i),
          style: style,
        ),
    ],
  );

  if (indicatorBackground != null) {
    indicator = DecoratedBox(
      decoration: BoxDecoration(
        color: indicatorBackground,
        borderRadius: indicatorRadius,
      ),
      child: indicator,
    );
  }

  final previous = _FluentCarouselNavButton(
    icon: FluentIcons.chevron_left_20_regular,
    semanticLabel: state.previousLabel,
    onPressed: state.onPrevious,
    iconSize: iconSize,
  );
  final next = _FluentCarouselNavButton(
    icon: FluentIcons.chevron_right_20_regular,
    semanticLabel: state.nextLabel,
    onPressed: state.onNext,
    iconSize: iconSize,
  );

  final autoplayControl = state.autoplayControl;
  final leading = autoplayControl == null
      ? previous
      : Row(
          mainAxisSize: MainAxisSize.min,
          spacing: controlGap,
          children: <Widget>[autoplayControl, previous],
        );

  // The strip carries its own alignment so the two layouts below can place it
  // identically: grouped and centred hug and centre, flexible fills the width.
  final strip = switch (state.chevronPlacement) {
    FluentCarouselChevronPlacement.groupedToSteps => Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: navGap,
        children: <Widget>[leading, indicator, next],
      ),
    ),
    FluentCarouselChevronPlacement.flexibleToEdges => Padding(
      padding: navInset,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[leading, indicator, next],
      ),
    ),
    FluentCarouselChevronPlacement.centeredToContent => Center(
      child: indicator,
    ),
  };

  // Centred-to-content flanks the slide instead of the strip. Figma lets those
  // chevrons hang outside the variant frame in the `outsideContent` layout; a
  // row keeps them inside the carousel's own box, so nothing overflows.
  var body = state.viewport;
  if (state.chevronPlacement ==
      FluentCarouselChevronPlacement.centeredToContent) {
    body = switch (state.layout) {
      FluentCarouselLayout.outsideContent => Row(
        spacing: navGap,
        children: <Widget>[
          Center(child: leading),
          Expanded(child: body),
          Center(child: next),
        ],
      ),
      FluentCarouselLayout.overContent => Stack(
        children: <Widget>[
          body,
          Positioned.directional(
            textDirection: TextDirection.ltr,
            start: navGap,
            top: 0,
            bottom: 0,
            child: Center(child: leading),
          ),
          Positioned.directional(
            textDirection: TextDirection.ltr,
            end: navGap,
            top: 0,
            bottom: 0,
            child: Center(child: next),
          ),
        ],
      ),
    };
  }

  final header = state.header;
  // The slide is a viewport, so it takes the height the carousel was given
  // minus the header and the nav strip. That is why a carousel must be handed a
  // bounded height, exactly as any other Flutter viewport must.
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      if (header != null)
        Padding(
          padding: EdgeInsets.only(bottom: navSpacing),
          child: header,
        ),
      Expanded(
        child: switch (state.layout) {
          FluentCarouselLayout.overContent => Stack(
            children: <Widget>[
              body,
              Positioned(left: 0, right: 0, bottom: navSpacing, child: strip),
            ],
          ),
          FluentCarouselLayout.outsideContent => body,
        },
      ),
      if (state.layout == FluentCarouselLayout.outsideContent) ...<Widget>[
        SizedBox(height: navSpacing),
        strip,
      ],
    ],
  );
}

/// Overrides the carousel style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`.
class FluentCarouselTheme extends InheritedTheme {
  /// Applies [style] to every [FluentCarousel] in [child].
  const FluentCarouselTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the nav-type defaults.
  final FluentCarouselStyle style;

  /// The nearest carousel style, or null.
  static FluentCarouselStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentCarouselTheme>()?.style;

  @override
  bool updateShouldNotify(FluentCarouselTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentCarouselTheme(style: style, child: child);
}

/// One indicator step: a dot, a pill when current, or an image thumbnail.
///
/// A thin composition over [FluentButton] rather than a second interaction
/// surface. The button supplies the 24x24 hit target, the transparent state
/// ramp, the focus ring, keyboard activation and button semantics; this widget
/// supplies the mark and the Figma token table for it.
///
/// The mark reads its colour from the ambient [IconTheme], which is how
/// `buildFluentButton` hands the resolved foreground to an icon — so hover and
/// press ramp the dot without this widget tracking any state of its own.
class FluentCarouselStep extends StatelessWidget {
  /// Creates a step.
  const FluentCarouselStep({
    super.key,
    required this.selected,
    required this.semanticLabel,
    this.onPressed,
    this.preview,
    this.style,
  });

  /// Whether this step's slide is the one in view.
  final bool selected;

  /// Announced by assistive technology. A step has no text of its own.
  final String semanticLabel;

  /// Invoked on tap and on Space or Enter. Null disables the step.
  final VoidCallback? onPressed;

  /// The thumbnail for the image-preview indicator. Null draws a dot or pill.
  final Widget? preview;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentCarouselStyle? style;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveFluentCarouselStyle(
      resolveFluentCarouselState(
        navType: preview == null
            ? FluentCarouselNavType.steps
            : FluentCarouselNavType.imagePreview,
      ),
      FluentTheme.of(context),
    ).merge(FluentCarouselTheme.maybeOf(context)).merge(style);

    const rest = <WidgetState>{};
    final Widget mark;
    final EdgeInsetsGeometry padding;
    if (preview == null) {
      final size = selected
          ? resolved.activeStepSize?.resolve(rest)
          : resolved.stepSize?.resolve(rest);
      padding =
          (selected
              ? resolved.activeStepPadding?.resolve(rest)
              : resolved.stepPadding?.resolve(rest)) ??
          EdgeInsets.zero;
      mark = _FluentCarouselMark(
        size: size ?? Size.zero,
        borderRadius: FluentRadius.allCircular,
      );
    } else {
      final size =
          (selected
              ? resolved.selectedPreviewSize?.resolve(rest)
              : resolved.previewSize?.resolve(rest)) ??
          Size.zero;
      padding = EdgeInsets.zero;
      mark = ClipRRect(
        borderRadius:
            resolved.previewBorderRadius?.resolve(rest) ?? BorderRadius.zero,
        child: SizedBox.fromSize(size: size, child: preview),
      );
    }

    return FluentButton.icon(
      icon: mark,
      semanticLabel: semanticLabel,
      onPressed: onPressed,
      // Transparent is the appearance whose background ramp Figma binds on the
      // step frame. Its brand-on-hover foreground table is overridden below,
      // because a step's mark stays neutral.
      appearance: FluentButtonAppearance.transparent,
      style: FluentButtonStyle(
        backgroundColor: resolved.stepBackgroundColor,
        foregroundColor: resolved.stepColor,
        borderRadius: resolved.stepBorderRadius,
        padding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(padding),
        minimumSize: const WidgetStatePropertyAll<Size?>(Size.zero),
      ),
    );
  }
}

/// The dot or pill itself, coloured from the ambient [IconTheme].
class _FluentCarouselMark extends StatelessWidget {
  const _FluentCarouselMark({required this.size, required this.borderRadius});

  final Size size;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
    size: size,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: IconTheme.of(context).color,
        borderRadius: borderRadius,
      ),
    ),
  );
}

/// A 24x24 chevron or autoplay button.
///
/// `FluentButton.icon` with Figma's icon-only inset. The button's own small
/// ramp keeps the horizontal padding at 8, which is a pre-existing divergence
/// recorded in `doc/token-divergences.md`; the carousel's nav is 24 square in
/// every one of the four `.CarouselNav` variants, so the inset is overridden
/// here rather than left to drift.
class _FluentCarouselNavButton extends StatelessWidget {
  const _FluentCarouselNavButton({
    required this.icon,
    required this.semanticLabel,
    required this.iconSize,
    this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final double iconSize;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => FluentButton.icon(
    icon: Icon(icon),
    semanticLabel: semanticLabel,
    onPressed: onPressed,
    appearance: FluentButtonAppearance.subtle,
    size: FluentButtonSize.small,
    style: FluentButtonStyle(
      padding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
        EdgeInsets.all(FluentSpacing.xxs),
      ),
      iconSize: WidgetStatePropertyAll<double?>(iconSize),
      minimumSize: const WidgetStatePropertyAll<Size?>(
        Size(FluentSize.size240, FluentSize.size240),
      ),
    ),
  );
}

/// A Fluent 2 carousel: slides with previous/next chevrons, a step indicator
/// and optional autoplay.
///
/// ```dart
/// SizedBox(
///   height: 245,
///   child: FluentCarousel(
///     slides: <Widget>[for (final image in images) image],
///     autoplay: true,
///   ),
/// )
/// ```
///
/// The slide viewport is a viewport like any other, so **the carousel must be
/// given a bounded height** by its parent.
///
/// ## Autoplay
///
/// Autoplay pauses while the pointer is over the carousel and while focus is
/// anywhere inside it, and does not run at all under
/// [MediaQuery.disableAnimationsOf] — content that advances itself past a
/// reader who asked for reduced motion is an accessibility failure, not a
/// nicety. [FluentCarouselPauseButton.inNav] adds an explicit play/pause
/// button; the default [FluentCarouselPauseButton.onContentClick] toggles it by
/// clicking the slide.
///
/// ## State
///
/// Uncontrolled: the carousel owns the current index, because autoplay has to
/// advance it. [onIndexChanged] reports every change, whoever caused it.
class FluentCarousel extends StatefulWidget {
  /// Creates a carousel over [slides].
  const FluentCarousel({
    super.key,
    required this.slides,
    this.previews,
    this.header,
    this.initialIndex = 0,
    this.onIndexChanged,
    this.enabled = true,
    this.loop = false,
    this.autoplay = false,
    this.autoplayInterval = fluentCarouselAutoplayInterval,
    this.layout = FluentCarouselLayout.outsideContent,
    this.chevronPlacement = FluentCarouselChevronPlacement.flexibleToEdges,
    this.pauseButton = FluentCarouselPauseButton.onContentClick,
    this.style,
    this.semanticLabel,
    this.previousLabel,
    this.nextLabel,
    this.playLabel,
    this.pauseLabel,
    this.stepLabel,
  });

  /// The slides, in order. One page each.
  final List<Widget> slides;

  /// Thumbnails for the image-preview indicator, one per slide.
  ///
  /// Non-null selects [FluentCarouselNavType.imagePreview]; null keeps the dot
  /// indicator. Must be the same length as [slides].
  final List<Widget>? previews;

  /// Optional title/description block above the slides.
  final Widget? header;

  /// The slide shown on mount.
  final int initialIndex;

  /// Invoked whenever the current slide changes — by chevron, by step, by drag
  /// or by autoplay.
  final ValueChanged<int>? onIndexChanged;

  /// Whether the carousel responds to input. False disables every control.
  final bool enabled;

  /// Whether the chevrons wrap around at the ends.
  ///
  /// False — upstream's `circular` default — disables the previous chevron on
  /// the first slide and the next chevron on the last, and stops autoplay at
  /// the end rather than restarting it.
  final bool loop;

  /// Whether the slides advance on their own.
  final bool autoplay;

  /// How long each slide is shown. Upstream's `autoplayInterval`, 4000ms.
  final Duration autoplayInterval;

  /// Where the nav strip sits.
  final FluentCarouselLayout layout;

  /// Where the chevrons sit.
  final FluentCarouselChevronPlacement chevronPlacement;

  /// Where the autoplay affordance lives.
  final FluentCarouselPauseButton pauseButton;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentCarouselStyle? style;

  /// Announced by assistive technology for the carousel as a whole.
  final String? semanticLabel;

  /// Announced for the previous-slide chevron.
  ///
  /// Null takes the wording from the ambient [FluentLocalizations], which falls
  /// back to English when no delegate is installed. The same is true of
  /// [nextLabel], [playLabel], [pauseLabel] and [stepLabel].
  final String? previousLabel;

  /// Announced for the next-slide chevron.
  final String? nextLabel;

  /// Announced for the autoplay button while paused.
  final String? playLabel;

  /// Announced for the autoplay button while playing.
  final String? pauseLabel;

  /// Announced for the step at a given index.
  final String Function(int index, int count)? stepLabel;

  @override
  State<FluentCarousel> createState() => _FluentCarouselState();
}

class _FluentCarouselState extends State<FluentCarousel> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;
  Timer? _timer;
  bool _hovered = false;
  bool _focused = false;
  bool _playing = true;
  bool _reducedMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Read here, not in build: this is also what makes reduced motion switched
    // on mid-run stop the timer rather than let one more slide through.
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    _restartTimer();
  }

  @override
  void didUpdateWidget(FluentCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= widget.slides.length) {
      _index = widget.slides.isEmpty ? 0 : widget.slides.length - 1;
    }
    _restartTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Whether the slides should currently be advancing on their own.
  ///
  /// Reduced motion is not "animate faster" here — it is off entirely.
  bool get _autoplaying =>
      widget.autoplay &&
      widget.enabled &&
      _playing &&
      !_hovered &&
      !_focused &&
      !_reducedMotion &&
      widget.slides.length > 1 &&
      (widget.loop || _index < widget.slides.length - 1);

  void _restartTimer() {
    _timer?.cancel();
    if (!_autoplaying) return;
    _timer = Timer(widget.autoplayInterval, _next);
  }

  void _setPaused(void Function() mutate) {
    setState(mutate);
    _restartTimer();
  }

  void _goTo(int index) {
    if (index == _index || index < 0 || index >= widget.slides.length) return;
    if (_reducedMotion) {
      _controller.jumpToPage(index);
    } else {
      unawaited(
        _controller.animateToPage(
          index,
          duration: fluentCarouselSlide.duration,
          curve: fluentCarouselSlide.curve,
        ),
      );
    }
    _onIndex(index);
  }

  void _onIndex(int index) {
    if (index == _index) return;
    setState(() => _index = index);
    widget.onIndexChanged?.call(index);
    _restartTimer();
  }

  void _previous() {
    final count = widget.slides.length;
    _goTo(_index == 0 ? (widget.loop ? count - 1 : 0) : _index - 1);
  }

  void _next() {
    final count = widget.slides.length;
    _goTo(_index == count - 1 ? (widget.loop ? 0 : _index) : _index + 1);
  }

  bool get _canGoBack =>
      widget.enabled && widget.slides.length > 1 && (widget.loop || _index > 0);

  bool get _canGoForward =>
      widget.enabled &&
      widget.slides.length > 1 &&
      (widget.loop || _index < widget.slides.length - 1);

  @override
  Widget build(BuildContext context) {
    final count = widget.slides.length;

    Widget viewport = PageView.builder(
      controller: _controller,
      itemCount: count,
      onPageChanged: _onIndex,
      physics: widget.enabled ? null : const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => widget.slides[index],
    );

    if (widget.autoplay &&
        widget.pauseButton == FluentCarouselPauseButton.onContentClick) {
      viewport = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.enabled
            ? () => _setPaused(() => _playing = !_playing)
            : null,
        child: viewport,
      );
    }

    final l10n = fluentL10n(context);
    final state = resolveFluentCarouselState(
      enabled: widget.enabled,
      count: count,
      index: _index,
      viewport: viewport,
      header: widget.header,
      layout: widget.layout,
      chevronPlacement: widget.chevronPlacement,
      navType: widget.previews == null
          ? FluentCarouselNavType.steps
          : FluentCarouselNavType.imagePreview,
      previews: widget.previews,
      previousLabel: widget.previousLabel ?? l10n.previousSlide,
      nextLabel: widget.nextLabel ?? l10n.nextSlide,
      // `index` is zero-based here and one-based in the announcement.
      stepLabel:
          widget.stepLabel ?? (index, count) => l10n.slideOf(index + 1, count),
      autoplayControl:
          widget.autoplay &&
              widget.pauseButton == FluentCarouselPauseButton.inNav
          ? _FluentCarouselNavButton(
              icon: _playing
                  ? FluentIcons.pause_20_regular
                  : FluentIcons.play_20_regular,
              semanticLabel: _playing
                  ? widget.pauseLabel ?? l10n.pauseSlideShow
                  : widget.playLabel ?? l10n.startSlideShow,
              iconSize: FluentSize.size200,
              onPressed: widget.enabled
                  ? () => _setPaused(() => _playing = !_playing)
                  : null,
            )
          : null,
      onPrevious: _canGoBack ? _previous : null,
      onNext: _canGoForward ? _next : null,
      onStepSelected: widget.enabled && count > 1 ? _goTo : null,
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentCarouselStyle(
      state,
      FluentTheme.of(context),
    ).merge(FluentCarouselTheme.maybeOf(context)).merge(widget.style);

    final rendered = buildFluentCarousel(state, resolved, <WidgetState>{
      if (!widget.enabled) WidgetState.disabled,
    });

    // Actions above Shortcuts, and neither inside a FocusScope: an Action is
    // looked up from the focused node upwards, so it has to be an ancestor of
    // whichever nav button currently holds focus.
    return Semantics(
      container: true,
      label: widget.semanticLabel,
      child: Actions(
        actions: <Type, Action<Intent>>{
          _PreviousSlideIntent: CallbackAction<_PreviousSlideIntent>(
            onInvoke: (_) {
              if (_canGoBack) _previous();
              return null;
            },
          ),
          _NextSlideIntent: CallbackAction<_NextSlideIntent>(
            onInvoke: (_) {
              if (_canGoForward) _next();
              return null;
            },
          ),
        },
        child: Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.arrowLeft):
                _PreviousSlideIntent(),
            SingleActivator(LogicalKeyboardKey.arrowRight): _NextSlideIntent(),
          },
          child: Focus(
            canRequestFocus: false,
            skipTraversal: true,
            onFocusChange: (value) => _setPaused(() => _focused = value),
            child: MouseRegion(
              onEnter: (_) => _setPaused(() => _hovered = true),
              onExit: (_) => _setPaused(() => _hovered = false),
              child: rendered,
            ),
          ),
        ),
      ),
    );
  }
}

/// Moves to the previous slide. Bound to the left arrow.
class _PreviousSlideIntent extends Intent {
  const _PreviousSlideIntent();
}

/// Moves to the next slide. Bound to the right arrow.
class _NextSlideIntent extends Intent {
  const _NextSlideIntent();
}
