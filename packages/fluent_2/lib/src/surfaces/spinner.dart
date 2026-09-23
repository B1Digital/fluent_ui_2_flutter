import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/semantics.dart' show SemanticsRole;
import 'package:flutter/widgets.dart';

import '../internal/animated_style.dart';
import 'spinner_style.dart';

/// How a spinner's ring is coloured. Figma's `Style` axis.
enum FluentSpinnerAppearance {
  /// Brand tail on a light brand rail, for a spinner on a neutral surface.
  /// The default.
  primary,

  /// White tail on a translucent white rail, for a spinner on a brand or image
  /// surface. Its label is `neutralForegroundStaticInverted`, so it is legible
  /// on that surface rather than on the page behind it.
  subtle,
}

/// Ring diameter, thickness and type ramp. Figma's `Size` axis.
///
/// Eight steps, 16 to 44 in fours. Figma's `.SpinnerBase` set also contains
/// `<size> 01/02/03` variants; those are animation keyframes rather than sizes
/// and are deliberately absent here.
enum FluentSpinnerSize {
  /// 16 across. Figma calls this `X-Tiny` on `.SpinnerBase`.
  extraTiny,

  /// 20 across.
  tiny,

  /// 24 across. Figma calls this `X-Small` on `.SpinnerBase`.
  extraSmall,

  /// 28 across.
  small,

  /// 32 across. The default.
  medium,

  /// 36 across.
  large,

  /// 40 across. Figma calls this `X-Large` on `.SpinnerBase`.
  extraLarge,

  /// 44 across.
  huge,
}

/// Where the label sits relative to the ring. Figma's `Layout` axis.
enum FluentSpinnerLabelPosition {
  /// After the ring in reading order. The default.
  after,

  /// Before the ring in reading order.
  before,

  /// Above the ring.
  above,

  /// Below the ring.
  below,
}

/// One keyframe of the tail animation: where the arc starts and how far it
/// sweeps, both in radians.
///
/// Upstream builds the tail from conic-gradient wedges turning behind a mask,
/// but what shows at any instant is always one arc, so an angle pair is all
/// the painter needs. The conversion happens once, in
/// [FluentSpinnerMotion.tailKeyframes], rather than in the painter every frame.
@immutable
class FluentSpinnerTailKeyframe {
  /// Creates a keyframe.
  const FluentSpinnerTailKeyframe({required this.start, required this.sweep});

  /// Where the tail's trailing edge sits, in radians clockwise from 3 o'clock,
  /// before the ring's own rotation is added.
  final double start;

  /// How far the tail extends from [start], in radians. Always positive.
  final double sweep;

  @override
  bool operator ==(Object other) =>
      other is FluentSpinnerTailKeyframe &&
      other.start == start &&
      other.sweep == sweep;

  @override
  int get hashCode => Object.hash(start, sweep);

  @override
  String toString() => 'FluentSpinnerTailKeyframe($start, $sweep)';
}

/// The spinner's two concurrent animations, transcribed rather than invented.
///
/// A spinner is the only Fluent component whose motion is a looping keyframe
/// animation instead of a state transition, so it cannot go through
/// [FluentAnimatedStyle]. It gets a raw [AnimationController] instead — and
/// therefore has to honour [MediaQuery.disableAnimationsOf] itself, which
/// `FluentSpinner` does as upstream does under `prefers-reduced-motion`: the
/// ring keeps turning at [reducedRotation]'s slower pace while the tail stops
/// and paints [FluentSpinnerPose.reduced]'s fading arc.
///
/// Both animations run for the same 1.5s, which is why one controller drives
/// both.
///
/// ## Where the numbers come from
///
/// [rotation] and [tail] are the animations of `@fluentui/react-spinner`
/// 9.8.6's `useSpinnerBaseClassName` and `useSpinnerTailBaseClassName`
/// (`useSpinnerStyles.styles.ts`). Figma's `.SpinnerBase` set *appears* to
/// encode the tail keyframes as its `<size> 01/02/03` variants, but each is
/// identical to its base size — so the Figma file records the keyframes'
/// existence and nothing else.
abstract final class FluentSpinnerMotion {
  /// The whole ring turning once. Linear, so the rotation reads as constant.
  static const FluentMotionSpec rotation = FluentMotionSpec(
    duration: Duration(milliseconds: 1500),
    curve: FluentCurve.linear,
  );

  /// [rotation] under reduced motion: upstream stretches it to 1.8s rather
  /// than stopping it, and freezes the tail instead.
  static const FluentMotionSpec reducedRotation = FluentMotionSpec(
    duration: Duration(milliseconds: 1800),
    curve: FluentCurve.linear,
  );

  /// The tail growing and travelling along the track.
  ///
  /// The curve applies *within* each segment between consecutive
  /// [tailKeyframes], which is how CSS applies an `animation-timing-function`
  /// across a keyframe list.
  static const FluentMotionSpec tail = FluentMotionSpec(
    duration: Duration(milliseconds: 1500),
    curve: FluentCurve.easyEase,
  );

  /// The three keyframes of [tail], at 0%, 50% and 100% of the cycle.
  ///
  /// Upstream paints two 135° conic wedges, the tail's `::before` and
  /// `::after`, turning 0 → 105° → 0 and 0 → 225° → 0 inside a tail that
  /// turns -135° → 0 → 225°, all behind a mask hiding the tail's first 105°.
  /// All three share one eased value per half, so the visible arc's start and
  /// sweep are linear in it: from 12 o'clock, (-30°, 30°), (105°, 255°) and
  /// (330°, 30°). These are those, turned a quarter back to Flutter's
  /// 3 o'clock.
  ///
  /// The arc grows from 30° to 255° and shrinks back. The last start is the
  /// first plus a whole turn rather than the first itself, so 100% lands
  /// exactly where 0% begins and the cycle closes without a jump.
  static const List<FluentSpinnerTailKeyframe> tailKeyframes = [
    FluentSpinnerTailKeyframe(start: -2 * math.pi / 3, sweep: math.pi / 6),
    FluentSpinnerTailKeyframe(start: math.pi / 12, sweep: 17 * math.pi / 12),
    FluentSpinnerTailKeyframe(start: 4 * math.pi / 3, sweep: math.pi / 6),
  ];

  /// The tail as Figma draws it standing still: a quarter arc starting at
  /// 3 o'clock.
  ///
  /// Read off the `Tail` ellipse's `arcData` on every `.SpinnerBase` variant,
  /// and what [FluentSpinnerPose.resting] paints.
  static const double restingTailSweep = math.pi / 2;
}

/// Where the ring and its tail are at one instant.
///
/// Separated from the painter so the motion can be asserted as arithmetic
/// rather than by diffing pixels, and so a consumer driving the spinner from
/// their own controller can supply a pose directly.
@immutable
class FluentSpinnerPose {
  /// Creates a pose from explicit angles, in radians.
  const FluentSpinnerPose({
    required this.rotation,
    required this.tailStart,
    required this.tailSweep,
    this.tailFades = false,
  });

  /// The pose Figma draws: what a spinner built without an animation shows.
  static const FluentSpinnerPose resting = FluentSpinnerPose(
    rotation: 0,
    tailStart: 0,
    tailSweep: FluentSpinnerMotion.restingTailSweep,
  );

  /// The pose at [progress] through one 1.5s cycle, where 0 and 1 are the ends.
  ///
  /// The rotation is linear across the whole cycle; the tail eases
  /// independently within each half, between consecutive
  /// [FluentSpinnerMotion.tailKeyframes].
  factory FluentSpinnerPose.at(double progress) {
    final t = progress.clamp(0.0, 1.0);
    const keyframes = FluentSpinnerMotion.tailKeyframes;

    // Two segments across three keyframes. `t == 1` belongs to the second
    // segment's end, not to a third segment that does not exist.
    final segment = t < 0.5 ? 0 : 1;
    final eased = FluentSpinnerMotion.tail.curve.transform(
      ((t - segment * 0.5) * 2).clamp(0.0, 1.0),
    );
    final from = keyframes[segment];
    final to = keyframes[segment + 1];

    return FluentSpinnerPose(
      rotation: t * 2 * math.pi,
      tailStart: from.start + (to.start - from.start) * eased,
      tailSweep: from.sweep + (to.sweep - from.sweep) * eased,
    );
  }

  /// The pose at [progress] through one 1.8s reduced-motion turn.
  ///
  /// Upstream's `prefers-reduced-motion` rules stop the tail's animation and
  /// paint it as `conic-gradient(transparent 120deg, currentcolor 360deg)`
  /// behind its 105° mask, while the ring keeps turning. So only [rotation]
  /// moves; the tail is fixed from 30° to 270° (120° to 360° from 12 o'clock),
  /// fading in towards its leading end.
  factory FluentSpinnerPose.reduced(double progress) => FluentSpinnerPose(
    rotation: progress.clamp(0.0, 1.0) * 2 * math.pi,
    tailStart: math.pi / 6,
    tailSweep: 4 * math.pi / 3,
    tailFades: true,
  );

  /// How far the whole ring has turned, in radians clockwise.
  final double rotation;

  /// Where the tail's trailing edge sits before [rotation] is added, in
  /// radians clockwise from 3 o'clock.
  final double tailStart;

  /// How far the tail extends from [tailStart], in radians.
  final double tailSweep;

  /// Whether the tail fades from clear at its trailing edge to solid at its
  /// leading one, rather than painting solid throughout.
  final bool tailFades;

  @override
  bool operator ==(Object other) =>
      other is FluentSpinnerPose &&
      other.rotation == rotation &&
      other.tailStart == tailStart &&
      other.tailSweep == tailSweep &&
      other.tailFades == tailFades;

  @override
  int get hashCode => Object.hash(rotation, tailStart, tailSweep, tailFades);

  @override
  String toString() =>
      'FluentSpinnerPose(rotation: $rotation, tailStart: $tailStart, '
      'tailSweep: $tailSweep, tailFades: $tailFades)';
}

/// Paints the spinner's track and tail.
///
/// A [CustomPainter] rather than widget composition because there is no widget
/// that draws a partial ring: an arc with a stroke is two `drawArc` calls, and
/// composing it out of `ClipPath` and `DecoratedBox` would cost a repaint of
/// the whole subtree on every one of the 90 frames a cycle takes.
///
/// Every input is a public field so tests can assert the resolved colours and
/// angles directly instead of diffing pixels.
class FluentSpinnerPainter extends CustomPainter {
  /// Creates a painter for the given colours, thickness and pose.
  const FluentSpinnerPainter({
    required this.trackColor,
    required this.indicatorColor,
    required this.strokeWidth,
    required this.pose,
    this.textDirection = TextDirection.ltr,
  });

  /// The full-circle rail.
  final Color trackColor;

  /// The moving arc drawn over the rail.
  final Color indicatorColor;

  /// Thickness of both, in logical pixels.
  final double strokeWidth;

  /// Where the tail currently is.
  final FluentSpinnerPose pose;

  /// Which way the ring turns. Right-to-left mirrors the whole drawing, so the
  /// ring turns anticlockwise, as upstream's does under `dir="rtl"`.
  final TextDirection textDirection;

  /// How far the whole ring has turned, in radians. Convenience for [pose].
  double get rotation => pose.rotation;

  /// Where the tail starts, before [rotation]. Convenience for [pose].
  double get tailStart => pose.tailStart;

  /// How far the tail extends. Convenience for [pose].
  double get tailSweep => pose.tailSweep;

  @override
  void paint(Canvas canvas, Size size) {
    // The stroke is centred on the path, so the circle is inset by half the
    // width, plus the half pixel by which upstream's ring mask — a
    // radial-gradient whose edges fade over 1px — stops short of the box.
    final radius =
        math.min(size.width, size.height) / 2 - strokeWidth / 2 - 0.5;
    if (radius <= 0) return;
    final center = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final rtl = textDirection == TextDirection.rtl;
    final start = rotation + tailStart;
    // Mirroring about the vertical axis takes an angle θ to π − θ, so the arc
    // [start, start + sweep] becomes [π − start − sweep, π − start].
    final arcStart = rtl ? math.pi - start - tailSweep : start;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = trackColor,
    );

    final tail = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      // Upstream cuts both ends with conic-gradient hard stops, which are
      // radial lines: on a circle, exactly a butt cap. Figma rounds the Tail
      // ellipse's corners (`Corner radius/Medium`); the shipped component's
      // flat ends win.
      ..strokeCap = StrokeCap.butt
      ..color = indicatorColor;
    if (pose.tailFades) {
      // CSS interpolates the gradient premultiplied, so its clear end keeps the
      // indicator's hue instead of fading through transparent black. Solid is
      // the leading end, which mirroring moves to the arc's start.
      // The sweep wraps from 2π back to 0, and antialiased pixels either side
      // of the wrap clamp to opposite ends of the gradient; parked mid-gap, the
      // wrap lies where nothing is drawn, so each edge blends to its own end.
      final clear = indicatorColor.withAlpha(0);
      final gap = (2 * math.pi - tailSweep) / 2;
      tail
        ..color = const Color(0xFF000000)
        ..shader = SweepGradient(
          startAngle: gap,
          endAngle: gap + tailSweep,
          colors: rtl ? [indicatorColor, clear] : [clear, indicatorColor],
          transform: GradientRotation(arcStart - gap),
        ).createShader(rect);
    }

    canvas.drawArc(rect, arcStart, tailSweep, false, tail);
  }

  @override
  bool shouldRepaint(FluentSpinnerPainter oldDelegate) =>
      oldDelegate.trackColor != trackColor ||
      oldDelegate.indicatorColor != indicatorColor ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.pose != pose ||
      oldDelegate.textDirection != textDirection;
}

/// Everything needed to render a spinner, independent of appearance and size.
///
/// The Dart counterpart of upstream's `SpinnerState` minus its design axes.
/// [buildFluentSpinner] takes this rather than [FluentSpinnerState], which is
/// what makes "Fluent's state, my own styling, Fluent's rendering" a supported
/// path rather than a fork.
@immutable
class FluentSpinnerBaseState {
  /// Creates a base state.
  const FluentSpinnerBaseState({required this.labelPosition, this.label});

  /// Where the label sits relative to the ring.
  final FluentSpinnerLabelPosition labelPosition;

  /// The label, if any. A spinner with no label is a bare ring.
  final Widget? label;
}

/// A spinner's fully resolved state, including the design axes.
@immutable
class FluentSpinnerState extends FluentSpinnerBaseState {
  /// Creates a resolved state.
  const FluentSpinnerState({
    required super.labelPosition,
    required this.appearance,
    required this.size,
    super.label,
  });

  /// Ring and label colouring.
  final FluentSpinnerAppearance appearance;

  /// Diameter, thickness and type ramp.
  final FluentSpinnerSize size;
}

/// Builds the state a spinner will be styled and rendered from.
///
/// Separated so a consumer can reuse Fluent's state resolution while
/// substituting their own styling — the first of the three-function
/// recomposition contract.
FluentSpinnerState resolveFluentSpinnerState({
  FluentSpinnerAppearance appearance = FluentSpinnerAppearance.primary,
  FluentSpinnerSize size = FluentSpinnerSize.medium,
  FluentSpinnerLabelPosition labelPosition = FluentSpinnerLabelPosition.after,
  Widget? label,
}) => FluentSpinnerState(
  appearance: appearance,
  size: size,
  labelPosition: labelPosition,
  label: label,
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes. Every colour comes from a Fluent token; nothing
/// here computes one.
///
/// Token sources are the Figma `Spinner` and `.SpinnerBase` component sets,
/// extracted into `test/fixtures/spinner.json` and
/// `test/fixtures/spinner_base.json` and asserted variant-by-variant in the
/// tests.
FluentSpinnerStyle resolveFluentSpinnerStyle(
  FluentSpinnerState state,
  FluentThemeData theme,
) {
  final c = theme.colors;

  // Figma binds these three on the Track ellipse, the Tail ellipse and the
  // label TEXT of each Spinner variant.
  final (track, indicator, label) = switch (state.appearance) {
    FluentSpinnerAppearance.primary => (
      c.brandStroke2Contrast,
      c.brandStroke1,
      c.neutralForeground1,
    ),
    FluentSpinnerAppearance.subtle => (
      c.neutralStrokeAlpha2,
      c.neutralStrokeOnBrand2,
      c.neutralForegroundStaticInverted,
    ),
  };

  // Geometry, verbatim from the Figma .SpinnerBase set. Thickness there is
  // authored as an integer-percent `innerRadius`, so the rendered values land
  // 0.04 either side of the stroke ramp; the ramp stop is what ships. See
  // doc/token-divergences.md for extraTiny, the one that misses by more.
  final (diameter, strokeWidth, textStyle) = switch (state.size) {
    FluentSpinnerSize.extraTiny => (
      16.0,
      FluentStroke.thick,
      theme.typography.body1,
    ),
    FluentSpinnerSize.tiny => (
      20.0,
      FluentStroke.thick,
      theme.typography.body1,
    ),
    FluentSpinnerSize.extraSmall => (
      24.0,
      FluentStroke.thick,
      theme.typography.body1,
    ),
    FluentSpinnerSize.small => (
      28.0,
      FluentStroke.thick,
      theme.typography.body1,
    ),
    FluentSpinnerSize.medium => (
      32.0,
      FluentStroke.thicker,
      theme.typography.subtitle2,
    ),
    FluentSpinnerSize.large => (
      36.0,
      FluentStroke.thicker,
      theme.typography.subtitle2,
    ),
    FluentSpinnerSize.extraLarge => (
      40.0,
      FluentStroke.thicker,
      theme.typography.subtitle2,
    ),
    FluentSpinnerSize.huge => (
      44.0,
      FluentStroke.thickest,
      theme.typography.subtitle1,
    ),
  };

  return FluentSpinnerStyle(
    trackColor: WidgetStatePropertyAll<Color?>(track),
    indicatorColor: WidgetStatePropertyAll<Color?>(indicator),
    labelColor: WidgetStatePropertyAll<Color?>(label),
    strokeWidth: WidgetStatePropertyAll<double?>(strokeWidth),
    diameter: WidgetStatePropertyAll<double?>(diameter),
    textStyle: WidgetStatePropertyAll<TextStyle?>(textStyle),
    // Figma expresses the gap as padding on the Label frame rather than as
    // auto-layout item spacing, bound to `Spacing/Horizontal/S` on every one of
    // the 64 variants — the vertical layouts included.
    gap: const WidgetStatePropertyAll<double?>(FluentSpacing.s),
  );
}

/// Renders a spinner from a resolved [state], [style] and [pose].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentSpinnerBaseState] rather than [FluentSpinnerState] on purpose: it
/// never reads appearance or size, so a consumer can supply their own style and
/// still use Fluent's rendering and layout.
///
/// [states] is present for symmetry with every other Fluent component and is
/// resolved against, but `FluentSpinner` always passes the empty set — see the
/// note on [FluentSpinnerStyle].
///
/// [pose] defaults to [FluentSpinnerPose.resting], so a caller driving the
/// animation themselves opts in rather than out.
Widget buildFluentSpinner(
  FluentSpinnerBaseState state,
  FluentSpinnerStyle style,
  Set<WidgetState> states, {
  FluentSpinnerPose pose = FluentSpinnerPose.resting,
}) {
  final diameter = style.diameter?.resolve(states) ?? 32.0;
  final strokeWidth =
      style.strokeWidth?.resolve(states) ?? FluentStroke.thicker;
  final gap = style.gap?.resolve(states) ?? FluentSpacing.s;
  final labelColor = style.labelColor?.resolve(states);
  final textStyle = style.textStyle?.resolve(states);

  // A layer of its own: the ring repaints every frame, and without a boundary
  // each frame would repaint everything up to the page's nearest one.
  final ring = RepaintBoundary(
    child: SizedBox(
      width: diameter,
      height: diameter,
      // Direction is read here rather than taken as a parameter, so a spinner
      // composed from this function still mirrors under right-to-left.
      child: Builder(
        builder: (context) => CustomPaint(
          painter: FluentSpinnerPainter(
            trackColor:
                style.trackColor?.resolve(states) ?? const Color(0x00000000),
            indicatorColor:
                style.indicatorColor?.resolve(states) ??
                const Color(0x00000000),
            strokeWidth: strokeWidth,
            pose: pose,
            textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
          ),
        ),
      ),
    ),
  );

  final label = state.label;
  if (label == null) return ring;

  var content = label;
  if (textStyle != null || labelColor != null) {
    content = DefaultTextStyle.merge(
      style: (textStyle ?? const TextStyle()).copyWith(color: labelColor),
      child: content,
    );
  }

  return switch (state.labelPosition) {
    FluentSpinnerLabelPosition.after => Row(
      mainAxisSize: MainAxisSize.min,
      spacing: gap,
      children: [ring, content],
    ),
    FluentSpinnerLabelPosition.before => Row(
      mainAxisSize: MainAxisSize.min,
      spacing: gap,
      children: [content, ring],
    ),
    FluentSpinnerLabelPosition.above => Column(
      mainAxisSize: MainAxisSize.min,
      spacing: gap,
      children: [content, ring],
    ),
    FluentSpinnerLabelPosition.below => Column(
      mainAxisSize: MainAxisSize.min,
      spacing: gap,
      children: [ring, content],
    ),
  };
}

/// Overrides the spinner style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`.
class FluentSpinnerTheme extends InheritedTheme {
  /// Applies [style] to every `FluentSpinner` in [child].
  const FluentSpinnerTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the appearance and size defaults.
  final FluentSpinnerStyle style;

  /// The nearest spinner style, or null.
  static FluentSpinnerStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentSpinnerTheme>()?.style;

  @override
  bool updateShouldNotify(FluentSpinnerTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentSpinnerTheme(style: style, child: child);
}

/// A Fluent 2 spinner: an indeterminate progress indicator.
///
/// ```dart
/// const FluentSpinner(
///   size: FluentSpinnerSize.large,
///   label: Text('Loading your files'),
/// )
/// ```
///
/// A spinner is output, not a control. It has no interaction states, no focus
/// and no disabled rendering — the Figma set carries no `State` axis — so there
/// is nothing to press and nothing to disable. Use it to say work is happening
/// when you cannot say how much is left; use a progress bar when you can.
///
/// ## Motion
///
/// Two 1.5s animations run together off one controller: the ring turns once,
/// linearly, while the tail grows from 30° to 255° and back through
/// [FluentSpinnerMotion.tailKeyframes] on `curveEasyEase`. Under a
/// right-to-left [Directionality] the drawing mirrors and the ring turns
/// anticlockwise. Under [MediaQuery.disableAnimationsOf] it does what upstream
/// does under `prefers-reduced-motion`: the tail stops growing and shrinking
/// and holds [FluentSpinnerPose.reduced]'s fading arc, and the ring keeps
/// turning, at [FluentSpinnerMotion.reducedRotation]'s slower 1.8s — so the
/// indicator still reads as working without the tail's darting.
///
/// ## Customisation
///
/// The same three rungs as every other Fluent component. [style] is merged last
/// and wins; [FluentSpinnerTheme] restyles a subtree; and for anything further,
/// [resolveFluentSpinnerState], [resolveFluentSpinnerStyle] and
/// [buildFluentSpinner] are public so any one of them can be replaced without
/// forking this widget.
class FluentSpinner extends StatefulWidget {
  /// Creates a spinner with an optional [label].
  const FluentSpinner({
    super.key,
    this.label,
    this.appearance = FluentSpinnerAppearance.primary,
    this.size = FluentSpinnerSize.medium,
    this.labelPosition = FluentSpinnerLabelPosition.after,
    this.style,
    this.semanticLabel,
  });

  /// The visible label. Null for a bare ring.
  final Widget? label;

  /// Ring and label colouring.
  final FluentSpinnerAppearance appearance;

  /// Diameter, thickness and type ramp.
  final FluentSpinnerSize size;

  /// Where [label] sits relative to the ring.
  final FluentSpinnerLabelPosition labelPosition;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentSpinnerStyle? style;

  /// Announced by assistive technology.
  ///
  /// Worth setting on a spinner with no visible [label]: a bare ring is
  /// invisible to a screen reader, and "Loading" is the whole message.
  final String? semanticLabel;

  @override
  State<FluentSpinner> createState() => _FluentSpinnerState();
}

class _FluentSpinnerState extends State<FluentSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: FluentSpinnerMotion.rotation.duration,
  );
  bool _reducedMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (reducedMotion == _reducedMotion && _controller.isAnimating) return;
    // Handled here rather than in initState so flipping the preference
    // mid-life is honoured. Reduced motion slows the ring rather than stopping
    // it, as upstream does; a new duration only takes effect on a new repeat.
    _reducedMotion = reducedMotion;
    _controller
      ..duration =
          (reducedMotion
                  ? FluentSpinnerMotion.reducedRotation
                  : FluentSpinnerMotion.rotation)
              .duration
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = resolveFluentSpinnerState(
      appearance: widget.appearance,
      size: widget.size,
      labelPosition: widget.labelPosition,
      label: widget.label,
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentSpinnerStyle(
      state,
      FluentTheme.of(context),
    ).merge(FluentSpinnerTheme.maybeOf(context)).merge(widget.style);

    final spinner = AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => buildFluentSpinner(
        state,
        resolved,
        const <WidgetState>{},
        pose: _reducedMotion
            ? FluentSpinnerPose.reduced(_controller.value)
            : FluentSpinnerPose.at(_controller.value),
      ),
    );

    return Semantics(
      label: widget.semanticLabel,
      // Upstream's `role="progressbar"` on an indeterminate spinner, which is
      // what Flutter's own indeterminate indicator uses
      // (`material/progress_indicator.dart:155`). It is the one status-family
      // role that does not collide with `liveRegion`
      // (`semantics.dart:186` — `_noCheckRequired`).
      role: SemanticsRole.loadingSpinner,
      liveRegion: true,
      child: spinner,
    );
  }
}
