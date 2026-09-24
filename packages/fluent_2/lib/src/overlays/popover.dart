import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../internal/anchor_metrics.dart';
import '../internal/animated_style.dart';
import '../internal/defer.dart';
import '../internal/interaction.dart';
import '../internal/tap_group.dart';
import 'popover_style.dart';

/// How a popover surface is filled. Figma's `Style` axis, verbatim.
enum FluentPopoverAppearance {
  /// Neutral surface on the ambient background. The default.
  normal,

  /// Brand fill, for a promotional or onboarding message.
  brand,

  /// Inverted neutral fill — dark on light, light on dark.
  inverted,
}

/// Surface padding and arrow size.
///
/// Not a Figma variant axis: the `Popover` set has one axis, `Style`. The three
/// steps come from the `Popover size` variable collection, whose `Small`,
/// `Medium` and `Large` modes bind `Spacing/{M,L,XL}` on both axes — 12, 16 and
/// 20, exactly the three `padding` values in `usePopoverSurfaceStyles`.
enum FluentPopoverSize {
  /// 12 padding, 6-tall arrow.
  small,

  /// 16 padding, 8-tall arrow. The default.
  medium,

  /// 20 padding, 8-tall arrow.
  large,
}

/// Which side of its anchor a popover sits on.
///
/// Not a Figma variant axis either: the design file ships the four sides as
/// twelve hidden arrow layers inside every variant, and every one of them is
/// `visible: false` by default. `above` is upstream's default position.
enum FluentPopoverPosition {
  /// Above the anchor, arrow pointing down. The default.
  above,

  /// Below the anchor, arrow pointing up.
  below,

  /// Before the anchor in reading order, arrow pointing towards it.
  before,

  /// After the anchor in reading order, arrow pointing towards it.
  after,
}

/// Where along the anchor's edge the popover lines up.
///
/// The second half of upstream's `positioning` shorthand, and the reason Figma
/// draws three arrow layers per edge rather than one: `Top edge - left`,
/// `- middle` and `- right`.
enum FluentPopoverAlign {
  /// Leading edges flush — the top edge for a popover beside its anchor.
  start,

  /// Centred on the anchor. The default.
  center,

  /// Trailing edges flush.
  end,
}

/// How far the surface travels on entry, in logical pixels.
///
/// Upstream's `PopoverSurfaceMotion` takes `distance = 10` and multiplies the
/// positioning layer's direction vector by it. There is no token for the
/// number; it is a literal in that file, so it is transcribed as one here.
const double _slideDistance = 10;

/// Arrow base and height per size.
///
/// The height is upstream's `arrowHeights` — 6 / 8 / 8. The base is twice the
/// height, which is the ratio of the Figma arrow vector: every one of the twelve
/// hidden layers is a 16 x 8 unstroked triangle, and Figma has no size axis to
/// say otherwise.
const Map<FluentPopoverSize, Size> _arrowSizes = <FluentPopoverSize, Size>{
  FluentPopoverSize.small: Size(12, 6),
  FluentPopoverSize.medium: Size(16, 8),
  FluentPopoverSize.large: Size(16, 8),
};

/// Everything needed to render a popover surface, independent of the design
/// axes.
///
/// The counterpart of `FluentButtonBaseState`. [buildFluentPopover] takes this
/// rather than [FluentPopoverState], which is what makes "Fluent's state, my own
/// styling, Fluent's rendering" a supported path rather than a fork.
@immutable
class FluentPopoverBaseState {
  /// Creates a base state.
  const FluentPopoverBaseState({
    required this.position,
    required this.align,
    required this.withArrow,
    required this.content,
  });

  /// Which side of the anchor the surface sits on. Read by the renderer, since
  /// it decides where the arrow goes — it is geometry, not styling.
  final FluentPopoverPosition position;

  /// Where along that side the surface lines up. Decides which end of the
  /// surface the arrow is pinned to.
  final FluentPopoverAlign align;

  /// Whether the pointing arrow is drawn.
  final bool withArrow;

  /// The popover body.
  final Widget content;
}

/// A popover's fully resolved state, including the design axes.
///
/// The counterpart of `FluentButtonState`: base state plus exactly `appearance`
/// and `size`.
@immutable
class FluentPopoverState extends FluentPopoverBaseState {
  /// Creates a resolved state.
  const FluentPopoverState({
    required super.position,
    required super.align,
    required super.withArrow,
    required super.content,
    required this.appearance,
    required this.size,
  });

  /// Fill treatment.
  final FluentPopoverAppearance appearance;

  /// Padding and arrow ramp.
  final FluentPopoverSize size;
}

/// Builds the state a popover will be styled and rendered from.
///
/// Separated so a consumer can reuse Fluent's state resolution while
/// substituting their own styling — the first of the three-function
/// recomposition contract.
FluentPopoverState resolveFluentPopoverState({
  required Widget content,
  FluentPopoverAppearance appearance = FluentPopoverAppearance.normal,
  FluentPopoverSize size = FluentPopoverSize.medium,
  FluentPopoverPosition position = FluentPopoverPosition.above,
  FluentPopoverAlign align = FluentPopoverAlign.center,
  bool withArrow = false,
}) => FluentPopoverState(
  appearance: appearance,
  size: size,
  position: position,
  align: align,
  withArrow: withArrow,
  content: content,
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes. Every colour comes from a Fluent token selected
/// through [FluentStateColor]; nothing here computes one.
///
/// Token sources are the Figma `Popover` component set, extracted into
/// `test/fixtures/popover.json` and asserted variant-by-variant in the tests.
/// Two values diverge from `usePopoverSurfaceStyles.styles.ts`, and Figma wins
/// in both; each is noted at the branch it affects. The arrow inset follows
/// React.
FluentPopoverStyle resolveFluentPopoverStyle(
  FluentPopoverState state,
  FluentThemeData theme,
) {
  final c = theme.colors;

  // A popover surface has no interactive states at all — Figma ships one
  // variant per style and no Hover, Pressed or Disabled counterpart — so each
  // of these is a single-token set rather than a ramp.
  final (background, foreground, border) = switch (state.appearance) {
    FluentPopoverAppearance.normal => (
      c.neutralBackground1,
      c.neutralForeground1,
      // Transparent, not absent: this turns into canvasText in high contrast,
      // which is the only thing separating the surface from the page there.
      c.transparentStroke,
    ),
    FluentPopoverAppearance.brand => (
      c.brandBackground,
      c.neutralForegroundOnBrand,
      // Figma binds `Brand/Stroke/1/Rest`, an opaque brand tone, where React
      // keeps the shared `colorTransparentStroke` on all three appearances.
      c.brandStroke1,
    ),
    FluentPopoverAppearance.inverted => (
      // Figma binds `Neutral/Background/Inverted/Rest` (grey 16 in light),
      // React `colorNeutralBackgroundStatic` (grey 20). Inverted flips with the
      // theme where Static does not, so the foreground has to flip with it.
      c.neutralBackgroundInverted,
      c.neutralForegroundInverted,
      c.transparentStroke,
    ),
  };

  // Figma's `Popover size` collection binds the same spacing step to both axes
  // at every mode, which is why one number drives the whole inset.
  final inset = switch (state.size) {
    FluentPopoverSize.small => FluentSpacing.m,
    FluentPopoverSize.medium => FluentSpacing.l,
    FluentPopoverSize.large => FluentSpacing.xl,
  };

  return FluentPopoverStyle(
    backgroundColor: FluentStateColor.tokens(rest: background),
    foregroundColor: FluentStateColor.tokens(rest: foreground),
    borderColor: FluentStateColor.tokens(rest: border),
    borderWidth: const WidgetStatePropertyAll<double?>(FluentStroke.thin),
    borderRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allMedium,
    ),
    textStyle: WidgetStatePropertyAll<TextStyle?>(theme.typography.body1),
    padding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(EdgeInsets.all(inset)),
    arrowSize: WidgetStatePropertyAll<Size?>(_arrowSizes[state.size]),
    // React's `arrowPadding: 2 * popoverSurfaceBorderRadius` (usePopover.js:
    // 243, constants.js:9), which is 8. Figma pins `Top edge - left` at x = 16,
    // the surface inset, but upstream's arrow is never pinned: it points at the
    // trigger and only stops this far short of a corner, and the storybook
    // wins where the two disagree.
    arrowInset: WidgetStatePropertyAll<double?>(2 * FluentRadius.medium.x),
    // Zero in both directions. With an arrow, the arrow itself fills the gap,
    // which is exactly how Figma draws it — the arrow sits flush against the
    // surface at y = -8. Without one, upstream leaves the positioning offset
    // unset, and an unset offset is zero.
    offset: const WidgetStatePropertyAll<double?>(FluentSpacing.none),
    shadow: WidgetStatePropertyAll<List<BoxShadow>?>(
      theme.shadow(FluentElevation.shadow16),
    ),
  );
}

/// Renders a popover surface from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentPopoverBaseState] rather than [FluentPopoverState] on purpose: it
/// never reads the appearance or the size, so a consumer can supply their own
/// style and still use Fluent's rendering.
///
/// [states] is present for symmetry with the rest of the package. A popover
/// surface is never hovered, pressed or focused as a whole — its *content* may
/// be — so callers normally pass an empty set.
Widget buildFluentPopover(
  FluentPopoverBaseState state,
  FluentPopoverStyle style,
  Set<WidgetState> states,
) {
  final background = style.backgroundColor?.resolve(states);
  final foreground = style.foregroundColor?.resolve(states);
  final borderColor = style.borderColor?.resolve(states);
  final borderWidth = style.borderWidth?.resolve(states) ?? FluentStroke.none;
  final radius = style.borderRadius?.resolve(states) ?? FluentRadius.allMedium;
  final textStyle = style.textStyle?.resolve(states);
  final padding = style.padding?.resolve(states) ?? EdgeInsets.zero;
  final arrowSize =
      style.arrowSize?.resolve(states) ??
      _arrowSizes[FluentPopoverSize.medium]!;
  final arrowInset = style.arrowInset?.resolve(states) ?? FluentSpacing.l;

  var content = state.content;
  if (textStyle != null || foreground != null) {
    content = DefaultTextStyle.merge(
      style: (textStyle ?? const TextStyle()).copyWith(color: foreground),
      child: content,
    );
  }

  final decoration = BoxDecoration(
    color: background,
    borderRadius: radius,
    border: borderWidth > 0 && borderColor != null
        ? Border.all(color: borderColor, width: borderWidth)
        : null,
    boxShadow: style.shadow?.resolve(states),
  );
  final surface = DecoratedBox(
    decoration: decoration,
    // A CSS border takes layout space. `PopoverSurface`'s `1px solid
    // colorTransparentStroke` (usePopoverSurfaceStyles.styles.raw.js:20) sits
    // outside its padding, so content starts 17px in and the surface is 2px
    // wider and taller than content plus padding. `decoration.padding` is the
    // border's own dimensions, the inset `Container` adds for the same reason.
    child: Padding(
      padding: decoration.padding,
      child: Padding(padding: padding, child: content),
    ),
  );

  if (!state.withArrow) return surface;

  final vertical =
      state.position == FluentPopoverPosition.above ||
      state.position == FluentPopoverPosition.below;
  // [FluentPopoverAlign] is reading order, not geometry, so the inset that pins
  // the arrow to one end of a *horizontal* edge mirrors under [Directionality]
  // — `EdgeInsetsDirectional` does that for us. The vertical pair never
  // mirrors: top stays top in both directions, the same rule the arrow keys
  // follow in `inputs/slider.dart:700-716`.
  final arrow = Padding(
    padding: switch ((vertical, state.align)) {
      (_, FluentPopoverAlign.center) => EdgeInsets.zero,
      (true, FluentPopoverAlign.start) => EdgeInsetsDirectional.only(
        start: arrowInset,
      ),
      (true, FluentPopoverAlign.end) => EdgeInsetsDirectional.only(
        end: arrowInset,
      ),
      (false, FluentPopoverAlign.start) => EdgeInsets.only(top: arrowInset),
      (false, FluentPopoverAlign.end) => EdgeInsets.only(bottom: arrowInset),
    },
    child: _buildArrow(state.position, background, arrowSize),
  );

  final cross = switch (state.align) {
    FluentPopoverAlign.start => CrossAxisAlignment.start,
    FluentPopoverAlign.center => CrossAxisAlignment.center,
    FluentPopoverAlign.end => CrossAxisAlignment.end,
  };

  return switch (state.position) {
    FluentPopoverPosition.above => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: cross,
      children: <Widget>[surface, arrow],
    ),
    FluentPopoverPosition.below => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: cross,
      children: <Widget>[arrow, surface],
    ),
    FluentPopoverPosition.before => Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: cross,
      children: <Widget>[surface, arrow],
    ),
    FluentPopoverPosition.after => Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: cross,
      children: <Widget>[arrow, surface],
    ),
  };
}

/// The pointing arrow for a surface on [side] of its anchor, filled [color].
///
/// Shared by [buildFluentPopover], which stacks it against the surface in a Row
/// or Column, and by [FluentPopover], which places it against the trigger.
/// Figma leaves the arrow unstroked and unshadowed even where the surface has
/// both, so it is a bare filled triangle.
Widget _buildArrow(FluentPopoverPosition side, Color? color, Size size) {
  final vertical =
      side == FluentPopoverPosition.above ||
      side == FluentPopoverPosition.below;
  // A [Builder] only so the painter can be handed a direction: whatever places
  // the arrow is direction-aware and a Path is not, and [buildFluentPopover]
  // takes no `BuildContext` (teaching_popover.dart and chart_popover.dart both
  // call it), so the apex is mirrored by hand here.
  return Builder(
    builder: (context) => CustomPaint(
      size: vertical ? size : size.flipped,
      painter: FluentPopoverArrowPainter(
        color: color ?? const Color(0x00000000),
        position: side,
        // maybeOf: a centred `above`/`below` surface is a plain [Column] and
        // imposes no direction requirement of its own, so refusing to build
        // one outside a [Directionality] would be a new constraint on a
        // public function. LTR is what such a tree renders as anyway.
        textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      ),
    ),
  );
}

/// Paints the popover's pointing arrow.
///
/// A [CustomPainter] rather than a rotated box: the shape is three points and a
/// fill, and Figma stores it as a single vector path per direction rather than
/// as one path plus a transform.
///
/// Every input is a public field so tests can assert the tone and direction
/// directly instead of diffing pixels.
class FluentPopoverArrowPainter extends CustomPainter {
  /// Creates a painter for the given fill and direction.
  const FluentPopoverArrowPainter({
    required this.color,
    required this.position,
    required this.textDirection,
  });

  /// The arrow fill — always the surface's own background token.
  final Color color;

  /// Which side of the anchor the surface is on. The arrow points the other
  /// way, towards the anchor.
  final FluentPopoverPosition position;

  /// The reading direction the surface is laid out in.
  ///
  /// [FluentPopoverPosition.before] and [FluentPopoverPosition.after] name the
  /// side in *reading* order, so which physical way the apex points is only
  /// settled here; `above` and `below` never mirror. Passed in rather than read
  /// from an ancestor because a painter has no context of its own — the same
  /// arrangement as `FluentSliderPainter` at `inputs/slider.dart:306`.
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    // The apex sits at the arrow box's trailing edge for `before` — pointing
    // away from the surface, at the anchor — and at its leading edge for
    // `after`. In RTL both are the opposite physical edge.
    final leading = textDirection == TextDirection.rtl ? size.width : 0.0;
    final trailing = size.width - leading;

    final path = Path();
    switch (position) {
      case FluentPopoverPosition.above:
        path
          ..moveTo(0, 0)
          ..lineTo(size.width, 0)
          ..lineTo(size.width / 2, size.height);
      case FluentPopoverPosition.below:
        path
          ..moveTo(size.width / 2, 0)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height);
      case FluentPopoverPosition.before:
        path
          ..moveTo(leading, 0)
          ..lineTo(trailing, size.height / 2)
          ..lineTo(leading, size.height);
      case FluentPopoverPosition.after:
        path
          ..moveTo(trailing, 0)
          ..lineTo(leading, size.height / 2)
          ..lineTo(trailing, size.height);
    }
    canvas.drawPath(path..close(), Paint()..color = color);
  }

  @override
  bool shouldRepaint(FluentPopoverArrowPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.position != position ||
      oldDelegate.textDirection != textDirection;
}

/// Plays Fluent's popover entrance over [child]: a fade plus a
/// direction-aware slide, once, on the frame the widget is inserted.
///
/// ## Enter only
///
/// Transcribed from `PopoverSurfaceMotion.ts`, which is
/// `createPresenceComponent` with `enter: [fadeAtom, slideAtom]` and a literal
/// `exit: []` under the comment *"No exit animation — the surface unmounts
/// immediately on close."* Both atoms take `duration = motionTokens
/// .durationSlower` and `easing = motionTokens.curveDecelerateMid`, which is
/// [FluentMotionSpec.popover]. Do not pair this with an exit: the asymmetry is
/// upstream's, and the deprecated `createSlideStyles` it replaced says the same
/// thing.
///
/// The slide starts 10 logical pixels towards the anchor and settles at zero,
/// which is what upstream's positioning direction vector times `distance = 10`
/// resolves to on each of the four sides. [FluentPopoverPosition.before] and
/// [FluentPopoverPosition.after] are reading-order sides, so their vector is
/// read off the ambient [Directionality] — upstream's `getPositionTransform`
/// flips on `dir` for the same reason.
///
/// ## Reduced motion
///
/// Under [MediaQuery.disableAnimationsOf] the duration collapses to
/// [Duration.zero], so the first painted frame is already the end state — fully
/// opaque and unshifted — and no ticker is ever scheduled. Upstream does the
/// same thing through a `@media(prefers-reduced-motion)` block that drops the
/// slide keyframe and clamps the duration to 1ms.
class FluentPopoverEntrance extends StatelessWidget {
  /// Wraps [child] in the popover entrance for a surface on [position].
  const FluentPopoverEntrance({
    super.key,
    required this.position,
    required this.child,
    this.reducedMotion,
  });

  /// Which side of the anchor the surface sits on. Decides which way the slide
  /// comes from: the surface always starts nearer the anchor.
  final FluentPopoverPosition position;

  /// The surface to animate.
  final Widget child;

  /// Overrides [MediaQuery.disableAnimationsOf].
  ///
  /// Exists because an entrance played inside an [Overlay] is outside the
  /// subtree that asked for it: a `MediaQuery` wrapping the trigger does not
  /// enclose the overlay, so `FluentPopover` reads the flag at the trigger and
  /// hands it across the boundary the same way it hands the theme across. Null
  /// reads the ambient value, which is what a directly-embedded entrance wants.
  final bool? reducedMotion;

  @override
  Widget build(BuildContext context) {
    // `before`/`after` are reading-order sides, so the vector towards the
    // anchor mirrors with the direction — `overlays/menu.dart:738-746` flips a
    // submenu's slide the same way. The vertical pair never mirrors.
    final beside = Directionality.maybeOf(context) == TextDirection.rtl
        ? -_slideDistance
        : _slideDistance;
    final from = switch (position) {
      FluentPopoverPosition.above => const Offset(0, _slideDistance),
      FluentPopoverPosition.below => const Offset(0, -_slideDistance),
      FluentPopoverPosition.before => Offset(beside, 0),
      FluentPopoverPosition.after => Offset(-beside, 0),
    };

    // TweenAnimationBuilder rather than an AnimationController of our own: it
    // runs exactly once, from `begin` to `end`, on the frame it is inserted,
    // which is the whole of an enter-only motion. A zero duration lands on the
    // end value inside `initState` with no ticker started at all.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: (reducedMotion ?? MediaQuery.disableAnimationsOf(context))
          ? Duration.zero
          : FluentMotionSpec.popover.duration,
      curve: FluentMotionSpec.popover.curve,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: from * (1 - t), child: child),
      ),
      child: child,
    );
  }
}

/// Overrides the popover style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`.
class FluentPopoverTheme extends InheritedTheme {
  /// Applies [style] to every [FluentPopover] in [child].
  const FluentPopoverTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the appearance and size defaults.
  final FluentPopoverStyle style;

  /// The nearest popover style, or null.
  static FluentPopoverStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentPopoverTheme>()?.style;

  @override
  bool updateShouldNotify(FluentPopoverTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentPopoverTheme(style: style, child: child);
}

/// A Fluent 2 popover: a light-dismiss surface anchored to a trigger.
///
/// ```dart
/// FluentPopover(
///   open: _open,
///   onOpenChanged: (open) => setState(() => _open = open),
///   withArrow: true,
///   content: const Text('Anything at all goes in here.'),
///   child: FluentButton(
///     onPressed: () => setState(() => _open = !_open),
///     child: const Text('Show'),
///   ),
/// )
/// ```
///
/// The foundation of the overlay family — Menu and TeachingPopover are this
/// surface with a different body — so the three things it has to get right are
/// anchoring, dismissal and focus return.
///
/// Pass `onOpenChanged: null` to disable it. That is a real state, not a visual
/// treatment: nothing reaches the [Overlay] at all, an already-open surface is
/// torn down, and [open] is ignored.
///
/// ## Positioning
///
/// The surface is placed by an [OverlayEntry] anchored with
/// [CompositedTransformFollower], so it escapes any ancestor clip or overflow
/// and follows the trigger as it moves. `FluentTheme` is an [InheritedTheme],
/// and the themes between this widget and the overlay are captured on the way
/// in, so tokens resolve against the trigger's theme rather than the app root's.
///
/// [position] and [align] together are upstream's `positioning` shorthand, and
/// the reason Figma draws twelve hidden arrow layers rather than four. Both are
/// stated in reading order, so both mirror under [Directionality]. The overlay
/// is a different branch of the tree and `InheritedTheme.capture` cannot carry
/// that one — [Directionality] is a plain [InheritedWidget], not an
/// [InheritedTheme] — so the trigger's direction is read here and re-established
/// inside the entry, the way `overlays/drawer.dart` does it.
///
/// ## Dismissal and focus
///
/// Escape closes it, a pointer landing anywhere outside closes it, and either
/// way focus returns to whatever held it when the popover opened — normally the
/// trigger. The content sits in a [FocusScope] with `autofocus`, so Tab cycles
/// within the surface rather than walking off into the page behind it, which is
/// upstream's `trapFocus` behaviour.
///
/// Nothing is drawn over the page while the surface is up, deliberately. A
/// click on a control behind an open popover dismisses the popover *and*
/// presses that control, hover still tracks, and the page still scrolls —
/// which is what upstream's document-level `useOnClickOutside` gives React.
/// [child] is in the same tap-region group as the surface, so a trigger that
/// toggles closes the popover exactly once instead of closing it here and
/// reopening it in its own handler; a trigger that only ever *opens* does not
/// dismiss at all, which is `usePopoverTrigger`'s behaviour too.
///
/// ## Dismissing by pointer needs a [TapRegionSurface]
///
/// An open surface is dismissed by a tap outside it via [TapRegion], which does
/// nothing without a [TapRegionSurface] above it. [WidgetsApp] installs one
/// (`widgets/app.dart:1836`) and `FluentApp` wraps [WidgetsApp], so an ordinary
/// app — and the widget tests — are covered. A popover mounted under a bare
/// [Overlay] with no [WidgetsApp] anywhere above it silently loses outside-tap
/// dismissal; Escape still closes it.
///
/// ## Motion
///
/// Entrance only, and it is [FluentMotionSpec.popover]. See
/// [FluentPopoverEntrance] for the transcription and for what reduced motion
/// does to it. A closing popover is simply gone on the next frame.
///
/// Customisation follows the same three rungs as the rest of the package.
/// [style] is merged last and wins; [FluentPopoverTheme] restyles a subtree; and
/// [resolveFluentPopoverState], [resolveFluentPopoverStyle] and
/// [buildFluentPopover] are public so any one of them can be replaced without
/// forking this widget.
class FluentPopover extends StatefulWidget {
  /// Anchors a popover showing [content] to [child].
  const FluentPopover({
    super.key,
    required this.child,
    required this.content,
    required this.open,
    this.onOpenChanged,
    this.appearance = FluentPopoverAppearance.normal,
    this.size = FluentPopoverSize.medium,
    this.position = FluentPopoverPosition.above,
    this.align = FluentPopoverAlign.center,
    this.withArrow = false,
    this.style,
    this.semanticLabel,
  });

  /// The trigger. Rendered in place; the surface is anchored to it.
  final Widget child;

  /// The popover body.
  final Widget content;

  /// Whether the surface is showing.
  ///
  /// Controlled on purpose: a popover is opened by something the caller owns —
  /// a button's `onPressed`, a row's selection — and closed by this widget as
  /// well as by that same caller, so a single source of truth is the only
  /// arrangement that cannot disagree with itself.
  final bool open;

  /// Reports every open and close this widget performs — Escape, an outside
  /// tap. Null disables the popover.
  final ValueChanged<bool>? onOpenChanged;

  /// Fill treatment.
  final FluentPopoverAppearance appearance;

  /// Padding and arrow ramp.
  final FluentPopoverSize size;

  /// Which side of [child] the surface sits on.
  final FluentPopoverPosition position;

  /// Where along that side the surface lines up.
  final FluentPopoverAlign align;

  /// Whether to draw the pointing arrow.
  ///
  /// Defaults to false, matching both React and the Figma file, where all
  /// twelve arrow layers ship hidden.
  final bool withArrow;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentPopoverStyle? style;

  /// Announced by assistive technology when the surface appears.
  ///
  /// The surface is a semantics node of its own; this names it. Pass it
  /// whenever the content alone does not say what the popover is for.
  final String? semanticLabel;

  @override
  State<FluentPopover> createState() => _FluentPopoverState();
}

class _FluentPopoverState extends State<FluentPopover> {
  final LayerLink _link = LayerLink();
  final FocusScopeNode _scope = FocusScopeNode(debugLabel: 'FluentPopover');
  OverlayEntry? _entry;
  FocusNode? _restore;

  late FluentThemeData _theme;
  FluentPopoverStyle? _themeStyle;
  bool _reducedMotion = false;
  TextDirection _direction = TextDirection.ltr;

  bool get _enabled => widget.onOpenChanged != null;

  bool get _shouldShow => widget.open && _enabled;

  /// The enclosing popover chain's tap group, when this one is nested.
  Object? _inheritedGroup;

  /// The group this popover's trigger and surface both register in.
  Object get _tapGroup => _inheritedGroup ?? this;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Resolved here rather than in the overlay's builder: the overlay sits
    // outside this subtree, so a FluentThemeOverride or FluentPopoverTheme
    // wrapping the trigger would otherwise be invisible to it.
    _theme = FluentTheme.of(context);
    _themeStyle = FluentPopoverTheme.maybeOf(context);
    // A popover opened from inside another popover's surface joins that
    // popover's tap group instead of starting its own — see [FluentTapGroup].
    // Read at the trigger, where the enclosing surface is an ancestor; the
    // OverlayEntry inherits nothing.
    _inheritedGroup = FluentTapGroup.maybeOf(context);
    // Same reason, and neither of these is an InheritedTheme, so neither rides
    // along with the `InheritedTheme.capture` in [_show] — they have to be read
    // here, at the trigger, and handed across the boundary by hand.
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    // Without this an RTL subtree would open its popover at the physical left,
    // because the OverlayEntry's ancestors are the Navigator's, not ours.
    // `overlays/drawer.dart:755` documents and fixes exactly this.
    _direction = Directionality.of(context);
    deferOrRun(_sync);
  }

  @override
  void didUpdateWidget(FluentPopover oldWidget) {
    super.didUpdateWidget(oldWidget);
    deferOrRun(_sync);
  }

  @override
  void dispose() {
    _entry
      ?..remove()
      ..dispose();
    _entry = null;
    _scope.dispose();
    super.dispose();
  }

  void _sync() {
    if (_shouldShow) {
      _show();
    } else {
      _hide();
    }
    _entry?.markNeedsBuild();
  }

  void _show() {
    if (_entry != null) return;
    final overlay = Overlay.of(context, debugRequiredFor: widget);
    // Captured before the scope takes focus, so closing can hand it back.
    _restore = FocusManager.instance.primaryFocus;
    // FluentTheme is an InheritedTheme, so this carries it — and any other
    // InheritedTheme between here and the overlay — across the boundary.
    final captured = InheritedTheme.capture(from: context, to: overlay.context);
    _entry = OverlayEntry(
      builder: (_) => captured.wrap(_buildSurface(overlay)),
    );
    overlay.insert(_entry!);

    // Focus moves into the surface, which is upstream's `findFirstFocusable` +
    // `activateModal`. Deferred one frame because the scope node is not
    // attached until the overlay has built, and `autofocus` alone would not do
    // it: autofocus only applies when nothing in the enclosing scope holds
    // focus, and the trigger normally does.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && _entry != null) _scope.requestFocus();
    });
  }

  void _hide() {
    final entry = _entry;
    if (entry == null) return;
    // Read before the teardown, because removing the entry unmounts the scope
    // and drops its focus. Restore only when the surface was the thing holding
    // focus: now that no barrier is drawn over the page, an outside tap lands
    // on whatever is behind and focuses it, and handing focus back to the
    // trigger would undo the click the user just made.
    // `inputs/date_picker.dart:1119-1123` guards the identical teardown the
    // same way.
    final wasInside = _scope.hasFocus;
    _entry = null;
    entry
      ..remove()
      ..dispose();

    // Focus return. Guarded on the node still being usable: the trigger may
    // have been removed from the tree along with the popover that closed it.
    final restore = _restore;
    _restore = null;
    if (wasInside &&
        restore != null &&
        restore.context != null &&
        restore.canRequestFocus) {
      restore.requestFocus();
    }
  }

  void _close() => widget.onOpenChanged?.call(false);

  Widget _buildSurface(OverlayState overlay) {
    final state = resolveFluentPopoverState(
      appearance: widget.appearance,
      size: widget.size,
      position: widget.position,
      align: widget.align,
      withArrow: widget.withArrow,
      content: widget.content,
    );
    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final style = resolveFluentPopoverStyle(
      state,
      _theme,
    ).merge(_themeStyle).merge(widget.style);

    const states = <WidgetState>{};
    final offset = style.offset?.resolve(states) ?? FluentSpacing.none;

    // The trigger in the overlay's coordinates, from its last layout — the
    // entry is only ever built after the trigger has been laid out, because
    // `_sync` runs deferred. Screen rects on both sides because a LeaderLayer
    // offset is layer-local (see [fluentAnchorRect]).
    // ponytail: measured as the entry builds, like FluentTooltip's. The
    // follower keeps the surface glued to a trigger that moves afterwards, but
    // flip and shift are only re-decided when the entry rebuilds, so a popover
    // left open while its trigger scrolls to an edge is not pushed back in, and
    // a scaled ancestor leaves the edge clamp off. Upgrade path: measure in the
    // trigger's local space during layout rather than here at build time.
    final anchor = fluentAnchorRect(context);
    final origin = fluentAnchorRect(overlay.context)?.topLeft;
    // No geometry means an unpainted trigger, and `showWhenUnlinked: false`
    // hides the surface of an unpainted leader anyway.
    final target = anchor == null || origin == null
        ? Rect.zero
        : anchor.shift(-origin);

    // The arrow is laid out as the surface's sibling rather than inside
    // `buildFluentPopover`'s Row/Column, because where it goes is only known
    // once the surface has been measured.
    final surface = FluentPopoverBaseState(
      position: state.position,
      align: state.align,
      withArrow: false,
      content: state.content,
    );
    final background = style.backgroundColor?.resolve(states);
    final arrowSize =
        style.arrowSize?.resolve(states) ??
        _arrowSizes[FluentPopoverSize.medium]!;
    final arrowPadding =
        style.arrowInset?.resolve(states) ?? 2 * FluentRadius.medium.x;

    // Re-established rather than inherited: the entry builds under the
    // Navigator's Overlay, so the trigger's own [Directionality] never reaches
    // it. Everything below it — the layout's `before`/`after`, the arrow's
    // apex, the entrance slide, and the caller's own content — reads it.
    return Directionality(
      textDirection: _direction,
      // Filling the overlay hands the layout the overlay's size on every pass.
      // The follower's default top-left anchors put its origin on the trigger's
      // top-left, and the offset takes it back to the overlay's, so the layout
      // box lies over the overlay and places in overlay coordinates. It has to
      // cover the surface rather than hang off the trigger: a RenderBox only
      // hit-tests children inside its own bounds, and a surface above or
      // before its trigger would otherwise sit at a negative offset, where
      // every tap on it read as an outside tap. The box still moves with the
      // trigger, so a scrolled surface stays inside it.
      child: Positioned.fill(
        child: CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          offset: -target.topLeft,
          // Same group as the trigger, so a pointer landing on the surface — or
          // back on the trigger — is "inside" and does not dismiss.
          //
          // `deferToChild` is enough, and is load-bearing rather than lazy:
          // `RenderTapRegionSurface` classifies by hit-test path
          // (`widgets/tap_region.dart:320-338`), and the surface's own
          // [DecoratedBox] is what puts this region on that path —
          // `RenderDecoratedBox.hitTestSelf` defers to `BoxDecoration.hitTest`,
          // so the whole rounded rect answers, padding included. The clipped
          // corners fall outside it and dismiss, which is what a browser does
          // with a border-radius too. The layout box itself fills the overlay
          // but hit-tests only its children, so the empty rest of it is
          // outside.
          child: TapRegion(
            groupId: _tapGroup,
            // Published to everything inside the surface, so a popover opened
            // from in here adopts this chain's group rather than starting its
            // own — without it, merely opening a nested popover read as an
            // outside tap out here and collapsed the whole chain.
            child: FluentTapGroup(
              groupId: _tapGroup,
              // Escape. Bound here rather than on the trigger so it is live only
              // while there is something to dismiss, leaving Escape to whatever
              // an ancestor does with it the rest of the time. Outside the
              // FocusScope, not inside it: an Actions lookup walks up from the
              // focused node's own context, and when the scope itself holds the
              // focus — which it does whenever the content has nothing focusable
              // — that context is the FocusScope's, above anything nested under
              // it.
              child: Actions(
                actions: <Type, Action<Intent>>{
                  DismissIntent: CallbackAction<DismissIntent>(
                    onInvoke: (_) {
                      _close();
                      return null;
                    },
                  ),
                },
                child: FocusScope(
                  node: _scope,
                  // ponytail: the slide comes from the preferred side, not the
                  // one the layout lands on — the side is only known in layout,
                  // after this is built. A flipped popover therefore settles
                  // its 10px from the far side. Upgrade path: hand the landed
                  // side to the entrance through the layout, as the arrow gets
                  // it.
                  child: FluentPopoverEntrance(
                    position: widget.position,
                    reducedMotion: _reducedMotion,
                    child: CustomMultiChildLayout(
                      delegate: _FluentPopoverLayout(
                        target: target,
                        position: widget.position,
                        align: widget.align,
                        direction: _direction,
                        offset: offset,
                        arrowSize: arrowSize,
                        arrowPadding: arrowPadding,
                      ),
                      children: <Widget>[
                        LayoutId(
                          id: _PopoverSlot.surface,
                          // container, so the surface lands on a node of its
                          // own rather than merging into the overlay;
                          // explicitChildNodes, so a labelled popover still
                          // exposes its content separately instead of
                          // flattening it into the label.
                          child: Semantics(
                            container: true,
                            explicitChildNodes: true,
                            label: widget.semanticLabel,
                            child: buildFluentPopover(surface, style, states),
                          ),
                        ),
                        if (widget.withArrow)
                          LayoutId(
                            id: _PopoverSlot.arrow,
                            child: LayoutBuilder(
                              builder: (context, constraints) => _buildArrow(
                                (constraints as _SideConstraints).side,
                                background,
                                arrowSize,
                              ),
                            ),
                          ),
                      ],
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

  @override
  Widget build(BuildContext context) => TapRegion(
    groupId: _tapGroup,
    // Registered only while the surface is up, so nothing is listening for
    // outside taps the rest of the time.
    //
    // This replaced a full-screen `HitTestBehavior.opaque` barrier drawn over
    // the page. The barrier swallowed the click that dismissed: a button behind
    // an open popover needed two clicks, hover never reached it, and a wheel
    // event never reached the enclosing Scrollable. Upstream's
    // `useOnClickOutside` is a document-level listener — the click dismisses AND
    // lands — and a TapRegion group is the same shape.
    //
    // Known cost: `RenderTapRegionSurface` "does not participate in the gesture
    // disambiguation system" (`widgets/tap_region.dart:189-193`), so a
    // pointer-down outside that turns into a drag-scroll counts as an outside
    // tap and dismisses. That is touch and trackpad only — the wheel is not a
    // pointer-down, and `FluentScrollBehavior` deliberately keeps the mouse out
    // of `dragDevices`. Left as is; the browser does the same thing.
    onTapOutside: _shouldShow ? (_) => _close() : null,
    child: CompositedTransformTarget(link: _link, child: widget.child),
  );
}

/// The two things [_FluentPopoverLayout] places.
enum _PopoverSlot { surface, arrow }

/// Tight constraints that also name the side the surface landed on.
///
/// That side is only known in layout — flipping needs the surface's measured
/// size — but [FluentPopoverArrowPainter] takes it at build time. A
/// [LayoutBuilder] is the framework's sanctioned way to build during layout,
/// and it rebuilds exactly when its constraints stop comparing equal, so the
/// side rides on them: the same side costs nothing, a flip rebuilds the arrow
/// once, inside the same pass. `FluentTooltip` carries its side the same way.
class _SideConstraints extends BoxConstraints {
  _SideConstraints(this.side, Size size) : super.tight(size);

  final FluentPopoverPosition side;

  @override
  bool operator ==(Object other) =>
      other is _SideConstraints && other.side == side && super == other;

  @override
  int get hashCode => Object.hash(super.hashCode, side);
}

/// Places the surface on its preferred side of the trigger, flipping and
/// shifting it to stay inside the overlay, with the arrow between the two.
///
/// Upstream's `usePopover.js:240-255` hands react-positioning a placement and
/// `arrowPadding: 2 * popoverSurfaceBorderRadius`, adds the arrow's height to
/// the offset, and never pins, so floating-ui runs `flip` then `shift`
/// (`usePositioningOptions.js:79-122`) against the clipping ancestors with no
/// padding. The same rules `FluentTooltip` follows:
///
/// - **Flip.** `fallbackStrategy: 'bestFit'` (`middleware/flip.js:21`): a side
///   that cannot hold the surface plus its offset gives way to the opposite
///   side when that side has more room, and otherwise stays put.
/// - **Shift.** Along the trigger's edge only, until the surface is inside,
///   flush with the boundary; one too big for the overlay starts at 0.
/// - **Arrow.** Centred on the *trigger* (floating-ui `arrow.ts`), kept
///   [arrowPadding] from the surface's corners, and drawn for the side the
///   surface landed on.
///
/// The box fills the overlay and the follower lays it over the overlay, so every
/// position is in overlay coordinates.
///
/// ponytail: an aligned placement flips its side but never its alignment,
/// where floating-ui's `flipAlignment` would also try `bottom-end` for a
/// `bottom-start` that overflows; the shift already keeps it inside.
class _FluentPopoverLayout extends MultiChildLayoutDelegate {
  _FluentPopoverLayout({
    required this.target,
    required this.position,
    required this.align,
    required this.direction,
    required this.offset,
    required this.arrowSize,
    required this.arrowPadding,
  });

  /// The trigger, in overlay coordinates, as of the last build.
  final Rect target;

  /// The preferred side.
  final FluentPopoverPosition position;

  /// Where along the trigger's edge the surface lines up before any shift.
  final FluentPopoverAlign align;

  /// What `before`/`after` and `start`/`end` resolve against.
  final TextDirection direction;

  /// The gap between the trigger and the arrow's tip — or the surface, without
  /// an arrow.
  final double offset;

  /// The arrow's box pointing up or down; transposed for a side one.
  final Size arrowSize;

  /// How close the arrow may come to the surface's corners.
  final double arrowPadding;

  AxisDirection _physical(FluentPopoverPosition side) => switch (side) {
    FluentPopoverPosition.above => AxisDirection.up,
    FluentPopoverPosition.below => AxisDirection.down,
    FluentPopoverPosition.before =>
      direction == TextDirection.rtl ? AxisDirection.right : AxisDirection.left,
    FluentPopoverPosition.after =>
      direction == TextDirection.rtl ? AxisDirection.left : AxisDirection.right,
  };

  @override
  void performLayout(Size size) {
    final surface = layoutChild(
      _PopoverSlot.surface,
      BoxConstraints.loose(size),
    );
    final hasArrow = hasChild(_PopoverSlot.arrow);
    final vertical =
        position == FluentPopoverPosition.above ||
        position == FluentPopoverPosition.below;
    final arrow = !hasArrow
        ? Size.zero
        : vertical
        ? arrowSize
        : arrowSize.flipped;

    // Flip: the room between the trigger and the overlay edge on each side,
    // against what the placement needs there. The need is the same on either
    // side, so `bestFit`'s least overflow is simply the most room.
    double room(AxisDirection side) => switch (side) {
      AxisDirection.up => target.top,
      AxisDirection.down => size.height - target.bottom,
      AxisDirection.left => target.left,
      AxisDirection.right => size.width - target.right,
    };
    final need =
        offset +
        (vertical
            ? surface.height + arrow.height
            : surface.width + arrow.width);
    final opposite = switch (position) {
      FluentPopoverPosition.above => FluentPopoverPosition.below,
      FluentPopoverPosition.below => FluentPopoverPosition.above,
      FluentPopoverPosition.before => FluentPopoverPosition.after,
      FluentPopoverPosition.after => FluentPopoverPosition.before,
    };
    final preferredRoom = room(_physical(position));
    final side =
        preferredRoom < need && room(_physical(opposite)) > preferredRoom
        ? opposite
        : position;

    // Main axis: the arrow's tip `offset` off the trigger, the surface behind.
    final (arrowMain, surfaceMain) = switch (_physical(side)) {
      AxisDirection.up => (
        target.top - offset - arrow.height,
        target.top - offset - arrow.height - surface.height,
      ),
      AxisDirection.down => (
        target.bottom + offset,
        target.bottom + offset + arrow.height,
      ),
      AxisDirection.left => (
        target.left - offset - arrow.width,
        target.left - offset - arrow.width - surface.width,
      ),
      AxisDirection.right => (
        target.right + offset,
        target.right + offset + arrow.width,
      ),
    };

    // Cross axis: aligned in reading order along a horizontal edge, never
    // mirrored along a vertical one, then shifted inside the overlay with no
    // padding — floating-ui's `clamp(min, v, max)` is `max(min, min(v, max))`,
    // so a surface bigger than the overlay starts at 0.
    final rtl = direction == TextDirection.rtl;
    final (lead, length, trail, extent) = vertical
        ? (target.left, surface.width, target.right, size.width)
        : (target.top, surface.height, target.bottom, size.height);
    final aligned = switch (align) {
      FluentPopoverAlign.center => (lead + trail) / 2 - length / 2,
      FluentPopoverAlign.start when vertical && rtl => trail - length,
      FluentPopoverAlign.start => lead,
      FluentPopoverAlign.end when vertical && rtl => lead,
      FluentPopoverAlign.end => trail - length,
    };
    final cross = math.max(0.0, math.min(aligned, extent - length));

    // Arrow: centred on the trigger, kept inside the surface — floating-ui
    // `arrow.ts`, down to trimming the padding on a surface too small to
    // honour it.
    final tip = vertical ? arrow.width : arrow.height;
    final padding = math.min(arrowPadding, length / 2 - tip / 2 - 1);
    final arrowCross =
        cross +
        math.max(
          padding,
          math.min(
            (lead + trail) / 2 - cross - tip / 2,
            length - tip - padding,
          ),
        );

    positionChild(
      _PopoverSlot.surface,
      vertical ? Offset(cross, surfaceMain) : Offset(surfaceMain, cross),
    );
    if (hasArrow) {
      layoutChild(_PopoverSlot.arrow, _SideConstraints(side, arrow));
      positionChild(
        _PopoverSlot.arrow,
        vertical
            ? Offset(arrowCross, arrowMain)
            : Offset(arrowMain, arrowCross),
      );
    }
  }

  @override
  bool shouldRelayout(_FluentPopoverLayout oldDelegate) =>
      oldDelegate.target != target ||
      oldDelegate.position != position ||
      oldDelegate.align != align ||
      oldDelegate.direction != direction ||
      oldDelegate.offset != offset ||
      oldDelegate.arrowSize != arrowSize ||
      oldDelegate.arrowPadding != arrowPadding;
}
