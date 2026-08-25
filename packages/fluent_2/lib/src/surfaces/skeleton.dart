import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import '../internal/animated_style.dart';
import 'skeleton_style.dart';

/// Corner treatment. Figma's `Shape` axis.
enum FluentSkeletonShape {
  /// `FluentRadius.medium`. The default.
  rectangle,

  /// `FluentRadius.circular`. Fully rounded ends — a skeleton that is not
  /// square therefore reads as a stadium, because Figma binds
  /// `Corner radius/Circular` rather than describing a true circle.
  circle,
}

/// The loop a skeleton runs while content is pending.
///
/// Figma's `Animated` axis is a boolean — `True` is [wave], `False` is [none].
/// [pulse] has no Figma variant; it is upstream's second animation and is
/// carried here because the two are alternatives, not a default and a fallback.
enum FluentSkeletonAnimation {
  /// A highlight band sweeping across the surface. The default, and Figma's
  /// `Animated=True`.
  wave,

  /// The whole surface fading between full and 40% opacity.
  pulse,

  /// No animation. Figma's `Animated=False`, which is *not* a flat surface: it
  /// still draws the highlight band, centred and still.
  none,
}

/// Everything needed to render a skeleton, independent of its shape.
///
/// The counterpart of `FluentButtonBaseState`. [buildFluentSkeleton] takes this
/// rather than [FluentSkeletonState], which is what makes "Fluent's state, my
/// own styling, Fluent's rendering" a supported path rather than a fork.
@immutable
class FluentSkeletonBaseState {
  /// Creates a base state.
  const FluentSkeletonBaseState({required this.animation});

  /// The loop to run. Drives behaviour, not token selection — which is why it
  /// lives here rather than on [FluentSkeletonState].
  final FluentSkeletonAnimation animation;
}

/// A skeleton's fully resolved state, including the design axes.
///
/// The counterpart of `FluentButtonState`: base state plus exactly `shape`.
@immutable
class FluentSkeletonState extends FluentSkeletonBaseState {
  /// Creates a resolved state.
  const FluentSkeletonState({required super.animation, required this.shape});

  /// Corner treatment.
  final FluentSkeletonShape shape;
}

/// Builds the state a skeleton will be styled and rendered from.
///
/// Separated so a consumer can reuse Fluent's state resolution while
/// substituting their own styling — the first of the three-function
/// recomposition contract.
FluentSkeletonState resolveFluentSkeletonState({
  FluentSkeletonShape shape = FluentSkeletonShape.rectangle,
  FluentSkeletonAnimation animation = FluentSkeletonAnimation.wave,
}) => FluentSkeletonState(shape: shape, animation: animation);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes. Every colour comes from a Fluent token; nothing
/// here computes one — the band is a gradient *between* two tokens, exactly as
/// upstream writes it as a `linear-gradient` between `colorNeutralStencil1` and
/// `colorNeutralStencil2`.
///
/// Token sources are the Figma `Skeleton` component set, extracted into
/// `test/fixtures/skeleton.json` and asserted variant-by-variant in the tests.
///
/// The two durations are literals rather than ramp stops on purpose: upstream
/// specifies 3s and 1s, and `FluentDuration` tops out at 500ms, so there is no
/// token to select. `Curves.easeInOut` is likewise the exact CSS `ease-in-out`
/// upstream names, not the nearest Fluent curve — `FluentCurve.easyEase` is a
/// different cubic.
FluentSkeletonStyle resolveFluentSkeletonStyle(
  FluentSkeletonState state,
  FluentThemeData theme,
) {
  final c = theme.colors;

  final radius = switch (state.shape) {
    // Figma's five animated rectangles store a stale radius of 0 against a
    // remote `Corner-radius/Image/Default` variable whose mode does not resolve
    // in that file; the variable itself resolves to 4, and the static rectangle
    // stores 4. See the divergence test in test/surfaces/skeleton_test.dart.
    FluentSkeletonShape.rectangle => FluentRadius.allMedium,
    FluentSkeletonShape.circle => FluentRadius.allCircular,
  };

  return FluentSkeletonStyle(
    backgroundColor: WidgetStatePropertyAll<Color?>(c.neutralStencil1),
    waveColor: WidgetStatePropertyAll<Color?>(c.neutralStencil2),
    borderRadius: WidgetStatePropertyAll<BorderRadius?>(radius),
    motion: switch (state.animation) {
      FluentSkeletonAnimation.wave ||
      FluentSkeletonAnimation.none => const FluentMotionSpec(
        duration: Duration(seconds: 3),
        curve: Curves.easeInOut,
      ),
      FluentSkeletonAnimation.pulse => const FluentMotionSpec(
        duration: Duration(seconds: 1),
        curve: Curves.easeInOut,
      ),
    },
  );
}

/// The wave band's left edge at [t], as a multiple of the skeleton's own width.
///
/// [t] is a position along the loop, already eased — not a raw clock fraction.
///
/// Transcribed from the five Figma `Frame` keyframes, which are the animation
/// sampled rather than a widget property: over a 132-wide component the
/// `Shimmer` layer sits at 0, -132, -264, -396 and +132, i.e. -3W to +W in even
/// steps. The two extremes are exactly the positions at which the 3W-wide band
/// falls entirely outside the clip, which is also where Figma's own keyframes
/// carry a mis-bound highlight colour nobody ever saw.
///
/// Upstream states the same sweep as `translate(-100%)` to `translate(100%)`.
double fluentSkeletonWaveOffset(double t) => -3 + 4 * t;

/// The pulse's opacity at [t], a raw fraction of the 1s loop.
///
/// Upstream, verbatim: opacity 1 to 0.4 to 1 on `ease-in-out`. CSS eases
/// between each pair of keyframes rather than across the whole loop, so the
/// curve is applied to each half of the triangle rather than to [t].
double fluentSkeletonPulseOpacity(double t) =>
    1 - 0.6 * Curves.easeInOut.transform(1 - (2 * t - 1).abs());

/// The band Figma draws on `Animated=True`: three times the component's width,
/// with a plateau of highlight between two transparent ends.
const List<double> _waveBandStops = <double>[
  0,
  0.3385416567325592,
  0.5,
  0.6510416865348816,
  1,
];

/// The band Figma draws on `Animated=False`: exactly the component's width,
/// peaking at the centre.
const List<double> _stillBandStops = <double>[0, 0.5, 1];

/// Paints a skeleton: the stencil surface, plus the highlight band clipped to
/// it.
///
/// A [CustomPainter] rather than a stack of [ClipRRect], [Transform] and
/// [DecoratedBox]: the band is three times wider than what is visible and moves
/// every frame, so painting it is one `drawRect` against a shader where widget
/// composition would relayout a subtree sixty times a second.
///
/// Every input is a public field so tests can assert the resolved tokens and
/// band geometry directly instead of diffing pixels.
class FluentSkeletonPainter extends CustomPainter {
  /// Creates a painter for the given tokens and band geometry.
  const FluentSkeletonPainter({
    required this.backgroundColor,
    required this.waveColor,
    required this.borderRadius,
    required this.bandWidthFactor,
    required this.bandOffsetFactor,
    required this.bandStops,
  });

  /// The stencil surface. `neutralStencil1`.
  final Color backgroundColor;

  /// The highlight the band carries. `neutralStencil2`, or null to paint no
  /// band at all — which is what a pulse skeleton does.
  final Color? waveColor;

  /// Corner radius. The band is clipped to it, so a circular skeleton shimmers
  /// inside its own outline.
  final BorderRadius borderRadius;

  /// The band's width as a multiple of the surface's. 3 while sweeping, 1 while
  /// still.
  final double bandWidthFactor;

  /// The band's left edge as a multiple of the surface's width. See
  /// [fluentSkeletonWaveOffset].
  final double bandOffsetFactor;

  /// Gradient stops across the band. The first and last carry
  /// [backgroundColor]; every stop between them carries [waveColor], so the
  /// band fades in and out of the surface rather than ending on an edge.
  final List<double> bandStops;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);
    canvas.drawRRect(rrect, Paint()..color = backgroundColor);

    final highlight = waveColor;
    if (highlight == null || size.isEmpty) return;

    final band = Rect.fromLTWH(
      bandOffsetFactor * size.width,
      0,
      bandWidthFactor * size.width,
      size.height,
    );
    canvas
      ..save()
      ..clipRRect(rrect)
      ..drawRect(
        band,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: <Color>[
              for (var i = 0; i < bandStops.length; i++)
                i == 0 || i == bandStops.length - 1
                    ? backgroundColor
                    : highlight,
            ],
            stops: bandStops,
          ).createShader(band),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(FluentSkeletonPainter oldDelegate) =>
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.waveColor != waveColor ||
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.bandWidthFactor != bandWidthFactor ||
      oldDelegate.bandOffsetFactor != bandOffsetFactor ||
      // Lists compare by identity, so an equal-but-distinct list repaints. Over
      // -painting is free here; under-painting would freeze the wave.
      oldDelegate.bandStops != bandStops;
}

/// Renders a skeleton from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentSkeletonBaseState] rather than [FluentSkeletonState] on purpose: it
/// never reads the shape, so a consumer can supply their own style and still
/// use Fluent's rendering and its reduced-motion handling.
///
/// [states] is accepted for symmetry with every other `buildFluent*` and is
/// passed straight to the style's properties. A skeleton reports no interaction
/// state of its own, so in practice this is always empty.
///
/// The returned widget owns the loop. `FluentAnimatedStyle` deliberately does
/// not: it is an [ImplicitlyAnimatedWidget], which transitions to a target and
/// stops, and a skeleton never arrives anywhere.
Widget buildFluentSkeleton(
  FluentSkeletonBaseState state,
  FluentSkeletonStyle style,
  Set<WidgetState> states,
) => _FluentSkeletonSurface(state: state, style: style, states: states);

class _FluentSkeletonSurface extends StatefulWidget {
  const _FluentSkeletonSurface({
    required this.state,
    required this.style,
    required this.states,
  });

  final FluentSkeletonBaseState state;
  final FluentSkeletonStyle style;
  final Set<WidgetState> states;

  @override
  State<_FluentSkeletonSurface> createState() => _FluentSkeletonSurfaceState();
}

class _FluentSkeletonSurfaceState extends State<_FluentSkeletonSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  late final Animation<double> _pulse = _controller.drive(
    const _PulseOpacity(),
  );
  bool _reducedMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The one place reduced motion is honoured. FluentAnimatedStyle clamps its
    // duration instead; a repeating loop has no end frame to clamp to, so it
    // must not start at all.
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    _sync();
  }

  @override
  void didUpdateWidget(_FluentSkeletonSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Whether the loop should be running at all.
  bool get _running {
    final duration = widget.style.motion?.duration;
    return !_reducedMotion &&
        widget.state.animation != FluentSkeletonAnimation.none &&
        duration != null &&
        duration > Duration.zero;
  }

  void _sync() {
    if (!_running) {
      _controller
        ..stop()
        ..value = 0;
      return;
    }
    final duration = widget.style.motion!.duration;
    if (_controller.duration != duration) {
      _controller
        ..stop()
        ..duration = duration;
    }
    if (!_controller.isAnimating) _controller.repeat();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style;
    final states = widget.states;
    final animation = widget.state.animation;
    final pulsing = animation == FluentSkeletonAnimation.pulse;
    // A wave that is not running falls back to Figma's own Animated=False
    // rendering rather than to an arbitrary frozen frame of the sweep.
    final sweeping = animation == FluentSkeletonAnimation.wave && _running;
    final curve = style.motion?.curve ?? Curves.linear;

    final background =
        style.backgroundColor?.resolve(states) ?? const Color(0x00000000);
    final radius =
        style.borderRadius?.resolve(states) ?? FluentRadius.allMedium;

    return FadeTransition(
      opacity: pulsing && _running
          ? _pulse
          : const AlwaysStoppedAnimation<double>(1),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          // Fills whatever the parent allows; `FluentSkeleton` tightens the
          // axes the caller pinned.
          size: Size.infinite,
          painter: FluentSkeletonPainter(
            backgroundColor: background,
            waveColor: pulsing ? null : style.waveColor?.resolve(states),
            borderRadius: radius,
            bandWidthFactor: sweeping ? 3 : 1,
            bandOffsetFactor: sweeping
                ? fluentSkeletonWaveOffset(curve.transform(_controller.value))
                : 0,
            bandStops: sweeping ? _waveBandStops : _stillBandStops,
          ),
        ),
      ),
    );
  }
}

/// Maps the raw loop position onto [fluentSkeletonPulseOpacity].
class _PulseOpacity extends Animatable<double> {
  const _PulseOpacity();

  @override
  double transform(double t) => fluentSkeletonPulseOpacity(t);
}

/// Overrides the skeleton style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`.
class FluentSkeletonTheme extends InheritedTheme {
  /// Applies [style] to every [FluentSkeleton] in [child].
  const FluentSkeletonTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the shape and animation defaults.
  final FluentSkeletonStyle style;

  /// The nearest skeleton style, or null.
  static FluentSkeletonStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentSkeletonTheme>()?.style;

  @override
  bool updateShouldNotify(FluentSkeletonTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentSkeletonTheme(style: style, child: child);
}

/// A Fluent 2 skeleton: the placeholder shown where content has not arrived.
///
/// ```dart
/// const FluentSkeleton(height: 20)
/// ```
///
/// Sizing follows the parent. Omit [width] or [height] and the skeleton fills
/// the space available on that axis, which is what a placeholder standing in
/// for a paragraph or an avatar slot wants; pin an axis whose parent is
/// unbounded, exactly as you would for any other expanding widget.
///
/// A skeleton is decorative, not interactive: it takes no callback, refuses no
/// focus because it never has any, and has no disabled state to speak of. Give
/// it a [semanticLabel] when nothing else in the view announces that content is
/// loading.
///
/// Both animations stop dead under `MediaQuery.disableAnimationsOf` — a
/// perpetually moving placeholder is exactly what reduced motion exists to
/// suppress. The wave then renders as Figma's `Animated=False` variant and the
/// pulse holds at full opacity.
///
/// Customisation follows the same three rungs as every other component.
/// [style] is merged last and wins; [FluentSkeletonTheme] restyles a subtree;
/// and for anything further, [resolveFluentSkeletonState],
/// [resolveFluentSkeletonStyle] and [buildFluentSkeleton] are public so any one
/// of them can be replaced without forking this widget.
class FluentSkeleton extends StatelessWidget {
  /// Creates a skeleton.
  const FluentSkeleton({
    super.key,
    this.shape = FluentSkeletonShape.rectangle,
    this.animation = FluentSkeletonAnimation.wave,
    this.width,
    this.height,
    this.style,
    this.semanticLabel,
  });

  /// Corner treatment.
  final FluentSkeletonShape shape;

  /// The loop to run while content is pending.
  final FluentSkeletonAnimation animation;

  /// Width, or null to fill the space available.
  final double? width;

  /// Height, or null to fill the space available.
  final double? height;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentSkeletonStyle? style;

  /// Announced by assistive technology.
  ///
  /// Null by default: several skeletons usually stand in for one pending
  /// region, and announcing each of them is noise. Label the region, or label
  /// one skeleton.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final state = resolveFluentSkeletonState(
      shape: shape,
      animation: animation,
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentSkeletonStyle(
      state,
      FluentTheme.of(context),
    ).merge(FluentSkeletonTheme.maybeOf(context)).merge(style);

    return Semantics(
      label: semanticLabel,
      child: SizedBox(
        width: width,
        height: height,
        child: buildFluentSkeleton(state, resolved, const <WidgetState>{}),
      ),
    );
  }
}
