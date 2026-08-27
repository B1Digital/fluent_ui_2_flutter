import 'package:fluent_2_core/fluent_2_core.dart';
// For clampDouble, which widgets.dart re-exports the rest of foundation but
// not this one helper.
import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart' show SemanticsRole;
import 'package:flutter/widgets.dart';

import '../internal/animated_style.dart';
import '../internal/interaction.dart';
import 'progressbar_style.dart';

/// Bar height. Figma's `Size` axis.
enum FluentProgressBarSize {
  /// 2 high. The default.
  medium,

  /// 4 high.
  large,
}

/// Which colour family the filled portion takes. Figma's `State` axis.
///
/// Named `Status` rather than `State` because [FluentProgressBarState] is
/// already the resolved-state class the recomposition contract requires. This
/// axis is validation, not interaction: none of its values is a hover, a press
/// or a disabled treatment.
enum FluentProgressBarStatus {
  /// Brand colour. Figma calls this value `Default`, which is a Dart keyword.
  none,

  /// `Status/Success/Background/3/Rest`.
  success,

  /// `Status/Danger/Background/3/Rest`.
  error,

  /// `Status/Severe/Background/3/Rest`.
  ///
  /// Severe, not Warning — Figma binds the dark-orange Severe family here, and
  /// upstream agrees (`colorPaletteDarkOrangeBackground3`). See the note on
  /// [resolveFluentProgressBarStyle].
  warning,
}

/// Everything needed to resolve a progress bar's style, independent of size and
/// status.
///
/// The Dart counterpart of upstream's `ProgressBarState` minus the design axes.
/// [buildFluentProgressBar] takes this rather than [FluentProgressBarState],
/// which is what makes "Fluent's state, my own styling, Fluent's rendering" a
/// supported path rather than a fork.
@immutable
class FluentProgressBarBaseState {
  /// Creates a base state.
  const FluentProgressBarBaseState({this.value});

  /// How much of the bar is filled, from 0 to 1, or null for indeterminate.
  ///
  /// Values outside the range are clamped rather than overflowing the rail.
  final double? value;

  /// Whether this bar reports an unknown wait rather than a known fraction.
  bool get indeterminate => value == null;
}

/// A progress bar's fully resolved state, including the design axes.
///
/// The counterpart of upstream's `ProgressBarState`: base state plus exactly
/// `size` and `status`.
@immutable
class FluentProgressBarState extends FluentProgressBarBaseState {
  /// Creates a resolved state.
  const FluentProgressBarState({
    required this.size,
    required this.status,
    super.value,
  });

  /// Bar height.
  final FluentProgressBarSize size;

  /// Which colour family the filled portion takes.
  final FluentProgressBarStatus status;
}

/// Builds the state a progress bar will be styled and rendered from.
///
/// Separated so a consumer can reuse Fluent's state resolution while
/// substituting their own styling — the first of the three-function
/// recomposition contract.
FluentProgressBarState resolveFluentProgressBarState({
  double? value,
  FluentProgressBarSize size = FluentProgressBarSize.medium,
  FluentProgressBarStatus status = FluentProgressBarStatus.none,
}) => FluentProgressBarState(value: value, size: size, status: status);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes. Every value comes from a Fluent token; nothing
/// here computes a colour.
///
/// Token sources are the Figma `Static_ProgressBar` component set, extracted
/// into `test/fixtures/progressbar.json` and asserted variant-by-variant in the
/// tests. Two things the fixture cannot show, both asserted in the tests
/// instead:
///
/// * The indicator colour lives on the variant's `Track` child, and the
///   extractor reads the variant frame — whose own fill is the *rail*.
/// * [FluentProgressBarStatus.warning] binds `Status/Severe/Background/3/Rest`,
///   and core carries the Severe family only on the transcription layer
///   (`FluentColors.status`), never on the alias layer. So that one colour is
///   the exact Figma value but is **not** reachable by `FluentThemeOverride` and
///   does not swap in high contrast, unlike the other three. Substituting the
///   Warning family would be a near-miss — `#F7630C` against Figma's `#DA3B01`
///   — so the gap is carried rather than papered over.
FluentProgressBarStyle resolveFluentProgressBarStyle(
  FluentProgressBarState state,
  FluentThemeData theme,
) {
  final c = theme.colors;

  // Every one of these has a Rest variant only: Figma ships no Hover, Pressed,
  // Selected or Disabled progress bar. FluentStateColor.tokens is still the
  // right door — it makes "rest is the only token there is" explicit.
  final rail = FluentStateColor.tokens(rest: c.neutralBackground6);

  final indicator = FluentStateColor.tokens(
    rest: switch (state.status) {
      FluentProgressBarStatus.none => c.compoundBrandBackground,
      FluentProgressBarStatus.success => c.statusSuccessBackground3,
      FluentProgressBarStatus.error => c.statusDangerBackground3,
      FluentProgressBarStatus.warning => c.statusSevereBackground3,
    },
  );

  // Not decoration: `transparentStroke` resolves to canvasText in high
  // contrast, where the rail's own fill collapses to the canvas colour and this
  // outline is the only thing left holding the shape.
  final border = FluentStateColor.tokens(rest: c.transparentStroke);

  // Figma states the rail height as a raw number per size and binds no
  // variable, so these are numbers rather than a token lookup.
  final thickness = switch (state.size) {
    FluentProgressBarSize.medium => 2.0,
    FluentProgressBarSize.large => 4.0,
  };

  return FluentProgressBarStyle(
    railColor: rail,
    indicatorColor: indicator,
    borderColor: border,
    borderWidth: const WidgetStatePropertyAll<double?>(FluentStroke.thin),
    borderRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allCircular,
    ),
    thickness: WidgetStatePropertyAll<double?>(thickness),
  );
}

/// Renders a progress bar from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentProgressBarBaseState] rather than [FluentProgressBarState] on purpose:
/// it never reads size or status, so a consumer can supply their own style and
/// still use Fluent's rendering and its indeterminate sweep.
///
/// [states] is a live interaction set for consumers that drive one; a plain
/// [FluentProgressBar] passes an empty set, because Fluent gives a progress bar
/// no interaction states.
///
/// The rail expands to the width it is given, so it must be laid out inside
/// something with a bounded width.
Widget buildFluentProgressBar(
  FluentProgressBarBaseState state,
  FluentProgressBarStyle style,
  Set<WidgetState> states,
) {
  final radius =
      style.borderRadius?.resolve(states) ?? FluentRadius.allCircular;
  final thickness = style.thickness?.resolve(states) ?? 0;
  final borderWidth = style.borderWidth?.resolve(states) ?? FluentStroke.none;
  final borderColor = style.borderColor?.resolve(states);

  final indicator = DecoratedBox(
    decoration: BoxDecoration(
      color: style.indicatorColor?.resolve(states),
      borderRadius: radius,
    ),
  );

  final value = state.value;
  final Widget content = value == null
      ? FractionallySizedBox(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: _indeterminateWidthFactor,
          heightFactor: 1,
          // The feathered ends are Figma's `Gradient mask` layer, applied to the
          // solid token fill rather than baked into it — which is why the
          // indicator's colour stays exactly one token deep.
          child: _IndeterminateSweep(
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: _indeterminateMask.createShader,
              child: indicator,
            ),
          ),
        )
      : FractionallySizedBox(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: clampDouble(value, 0, 1),
          heightFactor: 1,
          child: indicator,
        );

  return SizedBox(
    height: thickness,
    width: double.infinity,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: style.railColor?.resolve(states),
        borderRadius: radius,
      ),
      // A foreground decoration, so the outline stays visible where the
      // indicator covers it. On a 2px bar a background border would be painted
      // over along the whole filled portion, and high contrast is precisely
      // where that must not happen.
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: borderWidth > 0 && borderColor != null
              ? Border.all(color: borderColor, width: borderWidth)
              : null,
        ),
        child: ClipRRect(borderRadius: radius, child: content),
      ),
    ),
  );
}

/// The indeterminate bar's share of the rail.
///
/// Figma draws a fixed 164 inside a 492 rail on every indeterminate variant;
/// upstream writes it as `33.33%`.
const double _indeterminateWidthFactor = 1 / 3;

/// The alpha ramp of Figma's `Gradient mask` layer, which sits under the solid
/// indicator as a real Figma mask (`isMask: true`).
///
/// These are mask stops, not colours: they carry no bound variable in Figma and
/// only their alpha is read, because [BlendMode.dstIn] multiplies the child by
/// the shader's alpha and discards its RGB.
const LinearGradient _indeterminateMask = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: <Color>[Color(0x00FFFFFF), Color(0xFFFFFFFF), Color(0x00FFFFFF)],
  stops: <double>[0, 0.5364583, 1],
);

/// Slides its child across the rail forever, honouring reduced motion.
///
/// A raw [AnimationController] rather than [FluentAnimatedStyle], because this
/// is not a transition towards a new value — it is an infinite loop with no
/// target — so the implicit-animation family does not apply.
class _IndeterminateSweep extends StatefulWidget {
  const _IndeterminateSweep({required this.child});

  final Widget child;

  @override
  State<_IndeterminateSweep> createState() => _IndeterminateSweepState();
}

class _IndeterminateSweepState extends State<_IndeterminateSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: FluentProgressBar.indeterminateMotion.duration,
  );

  bool _reducedMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (_reducedMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The offset in bar-width units, matching upstream's `translateX(…%)` and
  /// Figma's four `Animated_ProgressBar` keyframes: -100%, 0, 200%, 300%.
  double get _translation {
    // Reduced motion leaves the untransformed position, exactly as CSS does
    // when the animation is dropped — and that is where the static Figma
    // Indeterminate variant draws the bar, so nothing goes invisible.
    if (_reducedMotion) return 0;
    final t = FluentProgressBar.indeterminateMotion.curve.transform(
      _controller.value,
    );
    return -1 + 4 * t;
  }

  @override
  Widget build(BuildContext context) {
    // Upstream flips the sweep with the reading direction; the bar has to leave
    // by the edge it is travelling towards.
    final sign = Directionality.of(context) == TextDirection.rtl ? -1 : 1;
    return AnimatedBuilder(
      animation: _controller,
      // Hoisted out of the builder: the child does not depend on the offset, so
      // an identical instance short-circuits its own rebuild every frame.
      child: widget.child,
      builder: (context, child) => FractionalTranslation(
        translation: Offset(sign * _translation, 0),
        child: child,
      ),
    );
  }
}

/// Overrides the progress bar style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`.
class FluentProgressBarTheme extends InheritedTheme {
  /// Applies [style] to every [FluentProgressBar] in [child].
  const FluentProgressBarTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the size and status defaults.
  final FluentProgressBarStyle style;

  /// The nearest progress bar style, or null.
  static FluentProgressBarStyle? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FluentProgressBarTheme>()
      ?.style;

  @override
  bool updateShouldNotify(FluentProgressBarTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentProgressBarTheme(style: style, child: child);
}

/// A Fluent 2 progress bar.
///
/// ```dart
/// FluentProgressBar(value: 0.4, semanticLabel: 'Uploading')
/// ```
///
/// [value] is the whole determinate/indeterminate switch: `null` means the wait
/// is of unknown length and the bar sweeps; `0` to `1` fills that fraction.
/// There is no separate mode flag, because the two are never both meaningful.
///
/// The bar expands to the width it is given, so give it a bounded one.
///
/// Fluent gives a progress bar **no interaction states** — no hover, no press,
/// no focus ring, and no disabled variant. It is not focusable and it never
/// consumes a pointer. [FluentProgressBarStatus] is validation, not
/// interaction.
///
/// Customisation follows the same three rungs as every other component here.
/// [style] is merged last and wins; [FluentProgressBarTheme] restyles a subtree;
/// and for anything further, [resolveFluentProgressBarState],
/// [resolveFluentProgressBarStyle] and [buildFluentProgressBar] are public so
/// any one of them can be replaced without forking this widget.
class FluentProgressBar extends StatelessWidget {
  /// Creates a progress bar. Omit [value] for an indeterminate one.
  const FluentProgressBar({
    super.key,
    this.value,
    this.size = FluentProgressBarSize.medium,
    this.status = FluentProgressBarStatus.none,
    this.style,
    this.semanticLabel,
  });

  /// The indeterminate sweep: 3000ms, linear, repeating forever, translating
  /// the bar from -100% to 300% of its own width.
  ///
  /// A bespoke [FluentMotionSpec] rather than one of the named constants,
  /// because upstream gives this animation its own timing — it is a loop, not a
  /// transition, and none of the shared specs describes it.
  static const FluentMotionSpec indeterminateMotion = FluentMotionSpec(
    duration: Duration(milliseconds: 3000),
    curve: FluentCurve.linear,
  );

  /// How much of the bar is filled, from 0 to 1. Null means indeterminate.
  final double? value;

  /// Bar height.
  final FluentProgressBarSize size;

  /// Which colour family the filled portion takes.
  final FluentProgressBarStatus status;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentProgressBarStyle? style;

  /// Announced by assistive technology alongside the percentage.
  ///
  /// A progress bar with no label announces a bare number, which tells a screen
  /// reader user nothing about what is progressing.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final state = resolveFluentProgressBarState(
      value: value,
      size: size,
      status: status,
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentProgressBarStyle(
      state,
      FluentTheme.of(context),
    ).merge(FluentProgressBarTheme.maybeOf(context)).merge(style);

    final progress = value;
    return Semantics(
      label: semanticLabel,
      // Determinate only. `SemanticsRole.progressBar` requires a value inside a
      // min/max range and throws without one (`semantics.dart:209-247`), and an
      // indeterminate bar has no value to give.
      role: progress == null ? null : SemanticsRole.progressBar,
      // A bare `50` is uninterpretable without the range it sits in. Flutter's
      // own bar reports the same 0-100 scale
      // (`material/progress_indicator.dart:156-157`).
      minValue: progress == null ? null : '0',
      maxValue: progress == null ? null : '100',
      // Null while indeterminate: announcing 0% would be a claim about progress
      // that has not been made.
      //
      // No `%` suffix, which this used to carry. At the package's Flutter
      // floor the role check parses the value with a bare `double.parse` and
      // reports `must be valid numbers` on anything else (3.41.0
      // `semantics.dart:228`); 3.47 relaxed that to accept a percent sign, but
      // the floor is what ships. The role plus the 0-100 range is what makes a
      // platform announce a percentage now, so nothing is lost.
      value: progress == null
          ? null
          : '${(clampDouble(progress, 0, 1) * 100).round()}',
      // Empty, not the ambient set: nothing above a progress bar should be able
      // to repaint it as hovered or pressed by accident.
      child: buildFluentProgressBar(state, resolved, const <WidgetState>{}),
    );
  }
}
