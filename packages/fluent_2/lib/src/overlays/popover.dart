import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../internal/animated_style.dart';
import '../internal/interaction.dart';
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
/// Three values diverge from `usePopoverSurfaceStyles.styles.ts`, and Figma
/// wins in all three; each is noted at the branch it affects.
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
    // Figma pins `Top edge - left` at x = 16 on a 282-wide medium surface, and
    // `Top edge - right` at 250 — the same 16 in from either edge, which is the
    // surface's own horizontal inset. React instead uses `arrowPadding: 2 *
    // popoverSurfaceBorderRadius`, which is 8. Figma wins.
    arrowInset: WidgetStatePropertyAll<double?>(inset),
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

  final surface = DecoratedBox(
    decoration: BoxDecoration(
      color: background,
      borderRadius: radius,
      border: borderWidth > 0 && borderColor != null
          ? Border.all(color: borderColor, width: borderWidth)
          : null,
      boxShadow: style.shadow?.resolve(states),
    ),
    child: Padding(padding: padding, child: content),
  );

  if (!state.withArrow) return surface;

  // Figma leaves the arrow unstroked and unshadowed even where the surface has
  // both, so it is a bare filled triangle.
  final vertical =
      state.position == FluentPopoverPosition.above ||
      state.position == FluentPopoverPosition.below;
  final arrow = Padding(
    padding: switch ((vertical, state.align)) {
      (_, FluentPopoverAlign.center) => EdgeInsets.zero,
      (true, FluentPopoverAlign.start) => EdgeInsets.only(left: arrowInset),
      (true, FluentPopoverAlign.end) => EdgeInsets.only(right: arrowInset),
      (false, FluentPopoverAlign.start) => EdgeInsets.only(top: arrowInset),
      (false, FluentPopoverAlign.end) => EdgeInsets.only(bottom: arrowInset),
    },
    child: CustomPaint(
      size: vertical ? arrowSize : Size(arrowSize.height, arrowSize.width),
      painter: FluentPopoverArrowPainter(
        color: background ?? const Color(0x00000000),
        position: state.position,
      ),
    ),
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
  });

  /// The arrow fill — always the surface's own background token.
  final Color color;

  /// Which side of the anchor the surface is on. The arrow points the other
  /// way, towards the anchor.
  final FluentPopoverPosition position;

  @override
  void paint(Canvas canvas, Size size) {
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
          ..moveTo(0, 0)
          ..lineTo(size.width, size.height / 2)
          ..lineTo(0, size.height);
      case FluentPopoverPosition.after:
        path
          ..moveTo(size.width, 0)
          ..lineTo(0, size.height / 2)
          ..lineTo(size.width, size.height);
    }
    canvas.drawPath(path..close(), Paint()..color = color);
  }

  @override
  bool shouldRepaint(FluentPopoverArrowPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.position != position;
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
/// resolves to on each of the four sides.
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
    final from = switch (position) {
      FluentPopoverPosition.above => const Offset(0, _slideDistance),
      FluentPopoverPosition.below => const Offset(0, -_slideDistance),
      FluentPopoverPosition.before => const Offset(_slideDistance, 0),
      FluentPopoverPosition.after => const Offset(-_slideDistance, 0),
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
/// the reason Figma draws twelve hidden arrow layers rather than four.
///
/// ## Dismissal and focus
///
/// Escape closes it, a pointer landing anywhere outside closes it, and either
/// way focus returns to whatever held it when the popover opened — normally the
/// trigger. The content sits in a [FocusScope] with `autofocus`, so Tab cycles
/// within the surface rather than walking off into the page behind it, which is
/// upstream's `trapFocus` behaviour.
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

  bool get _enabled => widget.onOpenChanged != null;

  bool get _shouldShow => widget.open && _enabled;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Resolved here rather than in the overlay's builder: the overlay sits
    // outside this subtree, so a FluentThemeOverride or FluentPopoverTheme
    // wrapping the trigger would otherwise be invisible to it.
    _theme = FluentTheme.of(context);
    _themeStyle = FluentPopoverTheme.maybeOf(context);
    // Same reason, and MediaQuery is not an InheritedTheme, so it cannot ride
    // along with the capture below.
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    _deferOrRun(_sync);
  }

  @override
  void didUpdateWidget(FluentPopover oldWidget) {
    super.didUpdateWidget(oldWidget);
    _deferOrRun(_sync);
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

  /// Runs [action] now, unless a build is in flight.
  ///
  /// Inserting, removing or invalidating an [OverlayEntry] is a `setState` on
  /// the [Overlay], which sits in a different branch of the tree and has already
  /// been built by the time this widget rebuilds. Doing it from
  /// [didUpdateWidget] or [didChangeDependencies] would therefore assert.
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
    _entry = OverlayEntry(builder: (_) => captured.wrap(_buildSurface()));
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
    _entry = null;
    entry
      ..remove()
      ..dispose();

    // Focus return. Guarded on the node still being usable: the trigger may
    // have been removed from the tree along with the popover that closed it.
    final restore = _restore;
    _restore = null;
    if (restore != null && restore.context != null && restore.canRequestFocus) {
      restore.requestFocus();
    }
  }

  void _close() => widget.onOpenChanged?.call(false);

  Widget _buildSurface() {
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
    final edge = switch (widget.align) {
      FluentPopoverAlign.start => -1.0,
      FluentPopoverAlign.center => 0.0,
      FluentPopoverAlign.end => 1.0,
    };
    final (target, follower, shift) = switch (widget.position) {
      FluentPopoverPosition.above => (
        Alignment(edge, -1),
        Alignment(edge, 1),
        Offset(0, -offset),
      ),
      FluentPopoverPosition.below => (
        Alignment(edge, 1),
        Alignment(edge, -1),
        Offset(0, offset),
      ),
      FluentPopoverPosition.before => (
        Alignment(-1, edge),
        Alignment(1, edge),
        Offset(-offset, 0),
      ),
      FluentPopoverPosition.after => (
        Alignment(1, edge),
        Alignment(-1, edge),
        Offset(offset, 0),
      ),
    };

    return Stack(
      children: <Widget>[
        // A pointer landing anywhere else dismisses. Nothing is painted, so
        // this is invisible; it exists because a click on inert scenery moves
        // no focus and would otherwise leave the popover open.
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
            targetAnchor: target,
            followerAnchor: follower,
            offset: shift,
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
                child: FluentPopoverEntrance(
                  position: widget.position,
                  reducedMotion: _reducedMotion,
                  // container, so the surface lands on a node of its own
                  // rather than merging into the overlay; explicitChildNodes,
                  // so a labelled popover still exposes its content separately
                  // instead of flattening it into the label.
                  child: Semantics(
                    container: true,
                    explicitChildNodes: true,
                    label: widget.semanticLabel,
                    child: buildFluentPopover(state, style, states),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) =>
      CompositedTransformTarget(link: _link, child: widget.child);
}
