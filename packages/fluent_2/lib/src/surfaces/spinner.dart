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
/// Upstream expresses these as `strokeDasharray` and `strokeDashoffset` on an
/// SVG circle; a Flutter arc wants an angle pair, so the conversion happens
/// once, here, rather than in the painter every frame.
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
/// `FluentSpinner` does by never starting the controller and painting
/// [FluentSpinnerPose.resting].
///
/// Both animations run for the same 1.5s, which is why one controller drives
/// both.
///
/// ## Where the numbers come from
///
/// [rotation] and [tail] are upstream's `spinner` and `spinner-tail`
/// `@keyframes`. Figma's `.SpinnerBase` set *appears* to encode the tail
/// keyframes as its `<size> 01/02/03` variants, but all four variants in each
/// size group carry identical arc geometry — so the Figma file records the
/// keyframes' existence and nothing else. The values below are upstream's;
/// `doc/token-divergences.md` has the note.
abstract final class FluentSpinnerMotion {
  /// The whole ring turning once. Linear, so the rotation reads as constant.
  static const FluentMotionSpec rotation = FluentMotionSpec(
    duration: Duration(milliseconds: 1500),
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
  /// Converted from upstream's `strokeDasharray` / `strokeDashoffset` triple —
  /// `(1, 150) @ 0`, `(90, 150) @ -35`, `(90, 150) @ -124` — over the
  /// 124-unit circumference that upstream's own final offset implies. A dash
  /// length becomes [FluentSpinnerTailKeyframe.sweep] and a negative offset
  /// becomes [FluentSpinnerTailKeyframe.start], both scaled by `2π / 124`.
  static const List<FluentSpinnerTailKeyframe> tailKeyframes = [
    FluentSpinnerTailKeyframe(start: 0, sweep: 2 * math.pi * 1 / 124),
    FluentSpinnerTailKeyframe(
      start: 2 * math.pi * 35 / 124,
      sweep: 2 * math.pi * 90 / 124,
    ),
    FluentSpinnerTailKeyframe(
      start: 2 * math.pi * 124 / 124,
      sweep: 2 * math.pi * 90 / 124,
    ),
  ];

  /// The tail as Figma draws it standing still: a quarter arc starting at
  /// 3 o'clock.
  ///
  /// Read off the `Tail` ellipse's `arcData` on every `.SpinnerBase` variant,
  /// and what [FluentSpinnerPose.resting] paints under reduced motion.
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
  });

  /// The pose Figma draws, and the one painted when animations are disabled.
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

  /// How far the whole ring has turned, in radians clockwise.
  final double rotation;

  /// Where the tail's trailing edge sits before [rotation] is added, in
  /// radians clockwise from 3 o'clock.
  final double tailStart;

  /// How far the tail extends from [tailStart], in radians.
  final double tailSweep;

  @override
  bool operator ==(Object other) =>
      other is FluentSpinnerPose &&
      other.rotation == rotation &&
      other.tailStart == tailStart &&
      other.tailSweep == tailSweep;

  @override
  int get hashCode => Object.hash(rotation, tailStart, tailSweep);

  @override
  String toString() =>
      'FluentSpinnerPose(rotation: $rotation, tailStart: $tailStart, '
      'tailSweep: $tailSweep)';
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
  });

  /// The full-circle rail.
  final Color trackColor;

  /// The moving arc drawn over the rail.
  final Color indicatorColor;

  /// Thickness of both, in logical pixels.
  final double strokeWidth;

  /// Where the tail currently is.
  final FluentSpinnerPose pose;

  /// How far the whole ring has turned, in radians. Convenience for [pose].
  double get rotation => pose.rotation;

  /// Where the tail starts, before [rotation]. Convenience for [pose].
  double get tailStart => pose.tailStart;

  /// How far the tail extends. Convenience for [pose].
  double get tailSweep => pose.tailSweep;

  @override
  void paint(Canvas canvas, Size size) {
    // The stroke is centred on the path, so the circle has to be inset by half
    // the width or the ring would paint outside the box the layout reserved.
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    if (radius <= 0) return;
    final center = size.center(Offset.zero);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = trackColor,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      rotation + tailStart,
      tailSweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        // Figma binds the Tail ellipse's cornerRadius to `Corner radius/Medium`
        // (4), which on a 2–4px ring clamps to half the thickness — exactly a
        // round cap.
        ..strokeCap = StrokeCap.round
        ..color = indicatorColor,
    );
  }

  @override
  bool shouldRepaint(FluentSpinnerPainter oldDelegate) =>
      oldDelegate.trackColor != trackColor ||
      oldDelegate.indicatorColor != indicatorColor ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.pose != pose;
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

  final ring = SizedBox(
    width: diameter,
    height: diameter,
    child: CustomPaint(
      painter: FluentSpinnerPainter(
        trackColor:
            style.trackColor?.resolve(states) ?? const Color(0x00000000),
        indicatorColor:
            style.indicatorColor?.resolve(states) ?? const Color(0x00000000),
        strokeWidth: strokeWidth,
        pose: pose,
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
/// linearly, while the tail grows and travels through
/// [FluentSpinnerMotion.tailKeyframes] on `curveEasyEase`. Under
/// [MediaQuery.disableAnimationsOf] the controller never starts and the ring
/// holds [FluentSpinnerPose.resting], the pose Figma draws — so reduced motion
/// gets a legible static indicator rather than a blank box.
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
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    // Not merely paused: a stopped controller schedules no ticks at all, so a
    // page full of spinners costs nothing when animations are off. Handled here
    // rather than in initState so flipping the preference mid-life is honoured.
    if (_reducedMotion) {
      _controller
        ..stop()
        ..value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
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

    final spinner = _reducedMotion
        ? buildFluentSpinner(state, resolved, const <WidgetState>{})
        : AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => buildFluentSpinner(
              state,
              resolved,
              const <WidgetState>{},
              pose: FluentSpinnerPose.at(_controller.value),
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
