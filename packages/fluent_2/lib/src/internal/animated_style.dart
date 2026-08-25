import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

/// One component's transition: how long, and on what easing.
///
/// Fluent has no single global transition. Each component names its own
/// duration and curve in its own `use*Styles` file, and the values genuinely
/// differ — a button surface settles in 100ms while a popover takes 400ms to
/// arrive. The constants below are those pairs transcribed from
/// `microsoft/fluentui` master. Treat them as transcription rather than taste:
/// change one only when upstream changes.
///
/// Two components deliberately have **no** spec here, because upstream gives
/// them none:
///
/// * **Checkbox** — its styles file contains no transition at all. The
///   indicator swaps instantly, and that is a decision rather than an
///   oversight: a checkbox has to read as committed the moment it is clicked.
/// * **Tooltip** — likewise none on master; it appears and disappears.
///
/// Neither is an omission waiting to be "improved" with [fade].
@immutable
final class FluentMotionSpec {
  /// Creates a spec from an explicit duration and curve.
  ///
  /// Prefer one of the named constants — a bespoke pair is a claim about
  /// upstream that nothing in this package can check.
  const FluentMotionSpec({required this.duration, required this.curve});

  /// How long the transition runs, before reduced motion is taken into
  /// account. See [FluentAnimatedStyle], which clamps this to
  /// [Duration.zero] when animations are disabled.
  final Duration duration;

  /// The easing applied across [duration].
  final Curve curve;

  /// Button `background`, `border` and `color`.
  ///
  /// Upstream's `useRootStyles` transitions exactly those three properties, so
  /// a hover or press repaint is the only thing this spec ever drives. Nothing
  /// about a button's geometry animates.
  static const FluentMotionSpec buttonSurface = FluentMotionSpec(
    duration: FluentDuration.faster,
    curve: FluentCurve.easyEase,
  );

  /// Switch track colour between checked and unchecked.
  static const FluentMotionSpec switchTrack = FluentMotionSpec(
    duration: FluentDuration.normal,
    curve: FluentCurve.easyEase,
  );

  /// Switch thumb travel.
  ///
  /// Upstream transitions `transform` only — the thumb slides, it does not
  /// resize or recolour on the way across.
  static const FluentMotionSpec switchThumb = FluentMotionSpec(
    duration: FluentDuration.normal,
    curve: FluentCurve.easyEase,
  );

  /// Tab selection indicator sliding between tabs.
  ///
  /// Upstream animates this as a FLIP: the indicator is placed at its new home
  /// and then transformed back to the old offset and scale, so the whole
  /// movement is one decelerating `transform`. Decelerate curves are for things
  /// arriving, which is what the indicator is doing at its destination.
  static const FluentMotionSpec tabIndicator = FluentMotionSpec(
    duration: FluentDuration.slow,
    curve: FluentCurve.decelerateMax,
  );

  /// Opacity in and out. Symmetric upstream — one spec covers both directions.
  static const FluentMotionSpec fade = FluentMotionSpec(
    duration: FluentDuration.normal,
    curve: FluentCurve.easyEase,
  );

  /// Height or width collapse, both directions.
  ///
  /// Uses the sharper `easyEaseMax` rather than [fade]'s `easyEase`: a size
  /// change reads as sluggish at the gentler easing because the content around
  /// it is being pushed the whole time.
  static const FluentMotionSpec collapse = FluentMotionSpec(
    duration: FluentDuration.normal,
    curve: FluentCurve.easyEaseMax,
  );

  /// Scale on entrance. Longer than [scaleExit], as entrances always are.
  static const FluentMotionSpec scaleEnter = FluentMotionSpec(
    duration: FluentDuration.gentle,
    curve: FluentCurve.decelerateMax,
  );

  /// Scale on exit. Accelerating, so the element leaves rather than fades away.
  static const FluentMotionSpec scaleExit = FluentMotionSpec(
    duration: FluentDuration.normal,
    curve: FluentCurve.accelerateMax,
  );

  /// Slide on entrance.
  static const FluentMotionSpec slideEnter = FluentMotionSpec(
    duration: FluentDuration.normal,
    curve: FluentCurve.decelerateMid,
  );

  /// Slide on exit.
  static const FluentMotionSpec slideExit = FluentMotionSpec(
    duration: FluentDuration.normal,
    curve: FluentCurve.accelerateMid,
  );

  /// Popover surface arriving.
  ///
  /// Enter only: upstream ships no exit transition for popovers, so a dismissed
  /// popover is simply gone on the next frame. Do not pair this with
  /// [scaleExit] to "finish" it — the asymmetry is upstream's.
  static const FluentMotionSpec popover = FluentMotionSpec(
    duration: FluentDuration.slower,
    curve: FluentCurve.decelerateMid,
  );

  /// Accordion chevron rotating between collapsed and expanded.
  ///
  /// Upstream writes a raw `ease-out` here rather than a curve token —
  /// `useAccordionHeader.tsx` sets
  /// `transition: transform ${motionTokens.durationNormal}ms ease-out` inline.
  /// CSS `ease-out` is `cubic-bezier(0, 0, 0.58, 1)`: it starts at full speed
  /// and decelerates, with no ease-in phase at all.
  ///
  /// [FluentCurve.decelerateMin] `(0.33, 0, 0.1, 1)` is the ramp's nearest
  /// match. [FluentCurve.easyEase] `(0.33, 0, 0.67, 1)` is symmetric, so it
  /// eases *in* as well and lags the browser badly: sampled at a third of the
  /// way through, `ease-out` is 50% done, `decelerateMin` 63%, `easyEase` only
  /// 27%. A symmetric curve is the wrong category for a one-way decelerating
  /// rotation, not merely a few milliseconds off.
  static const FluentMotionSpec accordionChevron = FluentMotionSpec(
    duration: FluentDuration.normal,
    curve: FluentCurve.decelerateMin,
  );

  @override
  bool operator ==(Object other) =>
      other is FluentMotionSpec &&
      other.duration == duration &&
      other.curve == curve;

  @override
  int get hashCode => Object.hash(duration, curve);

  @override
  String toString() => 'FluentMotionSpec($duration, $curve)';
}

/// Interpolates between two style values.
///
/// Shaped like the framework's own static lerps — [Color.lerp],
/// `BorderRadius.lerp`, `EdgeInsets.lerp` — nullable in and nullable out, so
/// they can be passed by tear-off with no adapter in between.
typedef FluentLerp<T> = T? Function(T? a, T? b, double t);

/// Builds the visuals for the current interpolated value.
typedef FluentAnimatedStyleBuilder<T> =
    Widget Function(BuildContext context, T value);

/// Animates one style value towards a new target, honouring reduced motion.
///
/// A member of the [ImplicitlyAnimatedWidget] family, generic over the value
/// and driven by a caller-supplied [lerp], so any component style can tween
/// without a bespoke widget per type:
///
/// ```dart
/// FluentAnimatedStyle<Color>(
///   value: resolved,
///   spec: FluentMotionSpec.buttonSurface,
///   lerp: Color.lerp,
///   builder: (context, color) => ColoredBox(color: color, child: label),
/// )
/// ```
///
/// Retargeting mid-flight continues from the current interpolated value rather
/// than restarting from the previous target — inherited from
/// [AnimatedWidgetBaseState], and the reason a control whose hover flickers
/// does not flicker back to its rest colour on every change.
///
/// ## Reduced motion
///
/// The effective duration is [Duration.zero] whenever
/// [MediaQuery.disableAnimationsOf] is true, which is this package's port of
/// upstream's `prefers-reduced-motion` clamp. It is not optional and it is not
/// per-component: every Fluent transition goes through here, so honouring it
/// once is what makes the whole system honest.
///
/// The builder rebuilds on every frame of an animation. Hoist any subtree that
/// does not depend on the value into a variable outside the builder; an
/// identical widget instance short-circuits its own rebuild, which is why this
/// widget has no separate `child` slot.
class FluentAnimatedStyle<T extends Object> extends ImplicitlyAnimatedWidget {
  /// Creates an implicitly animated style value.
  ///
  /// Not `const`: [ImplicitlyAnimatedWidget] takes a duration and curve, and
  /// reading them off [spec] is a field access, which a const initialiser
  /// cannot do.
  FluentAnimatedStyle({
    super.key,
    required this.value,
    required this.spec,
    required this.lerp,
    required this.builder,
  }) : super(duration: spec.duration, curve: spec.curve);

  /// The target. Changing it starts a transition from wherever the last one
  /// had got to.
  final T value;

  /// The upstream transition this value follows.
  final FluentMotionSpec spec;

  /// Interpolates between two values of [T]. Usually a static tear-off such as
  /// `Color.lerp`.
  final FluentLerp<T> lerp;

  /// Builds the subtree from the current interpolated value.
  final FluentAnimatedStyleBuilder<T> builder;

  @override
  AnimatedWidgetBaseState<FluentAnimatedStyle<T>> createState() =>
      _FluentAnimatedStyleState<T>();
}

class _FluentAnimatedStyleState<T extends Object>
    extends AnimatedWidgetBaseState<FluentAnimatedStyle<T>> {
  _LerpTween<T>? _tween;
  bool _reducedMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    // Also covers reduced motion being switched on mid-animation: whatever is
    // in flight lands on this frame rather than finishing at full length.
    _applyReducedMotion();
  }

  @override
  void didUpdateWidget(FluentAnimatedStyle<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Must run *after* super, which resets the controller's duration from
    // widget.duration and starts the transition. Clamping before it would be
    // overwritten. Nothing has been painted in between — didUpdateWidget runs
    // ahead of build — so the jump costs no intermediate frame.
    _applyReducedMotion();
  }

  void _applyReducedMotion() {
    if (!_reducedMotion) return;
    controller.duration = Duration.zero;
    // Setting `value` stops the ticker as well as jumping, so nothing is left
    // scheduled. The duration above is belt and braces: it keeps the controller
    // truthful for anything that reads it.
    if (controller.isAnimating) controller.value = controller.upperBound;
  }

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    // Kept in step so a caller that swaps in a different lerp is honoured; the
    // tween object itself is reused across updates.
    _tween?.interpolate = widget.lerp;
    _tween =
        visitor(
              _tween,
              widget.value,
              (dynamic value) =>
                  _LerpTween<T>(begin: value as T, interpolate: widget.lerp),
            )
            as _LerpTween<T>?;
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _tween!.evaluate(animation));
}

/// A [Tween] that defers to a supplied lerp, so `T` needs no `lerp` of its own
/// and no per-type Tween subclass has to exist.
class _LerpTween<T extends Object> extends Tween<T> {
  _LerpTween({required super.begin, required this.interpolate});

  /// Mutable so [_FluentAnimatedStyleState.forEachTween] can refresh it —
  /// the framework constructs a tween once and reuses it for the widget's life.
  FluentLerp<T> interpolate;

  @override
  T lerp(double t) => interpolate(begin, end, t) as T;
}

/// Interpolates two colours the way a CSS transition does.
///
/// Flutter's [Color.lerp] interpolates channels directly rather than in
/// premultiplied alpha space, so a fully transparent endpoint drags its RGB
/// through the tween. Fluent's `transparentBackground` is transparent *black*
/// (matching upstream's CSS `transparent`, which is `rgba(0,0,0,0)`), so a
/// subtle or transparent surface fading up to an opaque grey passes through
/// visibly darker greys on the way. Browsers show no such fringe.
///
/// When one endpoint is fully transparent this adopts the other's RGB so only
/// alpha moves — the same result as premultiplying, without the round trip.
/// Components animating a surface colour should use this rather than
/// [Color.lerp].
Color? fluentLerpColor(Color? a, Color? b, double t) {
  var from = a;
  var to = b;
  if (from != null && to != null) {
    if (from.a == 0 && to.a != 0) {
      from = to.withValues(alpha: 0);
    } else if (to.a == 0 && from.a != 0) {
      to = from.withValues(alpha: 0);
    }
  }
  return Color.lerp(from, to, t);
}
