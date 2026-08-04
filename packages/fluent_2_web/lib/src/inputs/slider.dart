import 'package:fluent_2_core/fluent_2_core.dart';
// For clampDouble, which widgets.dart does not re-export.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../internal/focus_ring.dart';
import '../internal/interaction.dart';
import 'slider_style.dart';

/// Thumb diameter and rail thickness. Figma's `Size` axis.
enum FluentSliderSize {
  /// 20 thumb on a 4 rail. The default.
  medium,

  /// 16 thumb on a 2 rail.
  small,
}

/// Everything needed to resolve a slider's style, independent of size.
///
/// The Dart counterpart of upstream's `SliderState` minus the design axis.
/// [buildFluentSlider] takes this rather than [FluentSliderState], which is
/// what makes "Fluent's state, my own styling, Fluent's rendering" a supported
/// path rather than a fork.
@immutable
class FluentSliderBaseState {
  /// Creates a base state.
  const FluentSliderBaseState({
    required this.value,
    required this.min,
    required this.max,
    required this.enabled,
    this.step,
  });

  /// The current value, in [min]…[max]. Values outside are clamped rather than
  /// overflowing the rail.
  final double value;

  /// The value at the start of the rail.
  final double min;

  /// The value at the end of the rail.
  final double max;

  /// The interval between selectable values, or null for a continuous slider.
  ///
  /// A stepped slider also draws a tick per interval, which is why this is
  /// state rather than styling.
  final double? step;

  /// Whether the slider responds to input.
  final bool enabled;

  /// [value] as a 0…1 position along the rail.
  ///
  /// A zero-width range reports 0 rather than dividing by it — a slider whose
  /// min equals its max has nowhere to be but the start.
  double get fraction =>
      max <= min ? 0 : clampDouble((value - min) / (max - min), 0, 1);

  /// How many intervals a stepped slider is divided into, or null when it is
  /// continuous.
  ///
  /// Null for a step that does not divide the range into at least one whole
  /// interval, because a partial tick would sit at a value the slider cannot
  /// take.
  int? get intervals {
    final size = step;
    if (size == null || size <= 0 || max <= min) return null;
    final count = (max - min) / size;
    return count < 1 ? null : count.round();
  }

  /// [value] snapped to the nearest [step], or unchanged when continuous.
  double snap(double raw) {
    final clamped = clampDouble(raw, min, max);
    final size = step;
    if (size == null || size <= 0) return clamped;
    return clampDouble(
      min + ((clamped - min) / size).roundToDouble() * size,
      min,
      max,
    );
  }
}

/// A slider's fully resolved state, including the design axis.
///
/// The counterpart of upstream's `SliderState`: base state plus exactly `size`.
@immutable
class FluentSliderState extends FluentSliderBaseState {
  /// Creates a resolved state.
  const FluentSliderState({
    required super.value,
    required super.min,
    required super.max,
    required super.enabled,
    required this.size,
    super.step,
  });

  /// Thumb diameter and rail thickness.
  final FluentSliderSize size;
}

/// Builds the state a slider will be styled and rendered from.
///
/// Separated so a consumer can reuse Fluent's state resolution while
/// substituting their own styling — the first of the three-function
/// recomposition contract.
FluentSliderState resolveFluentSliderState({
  required double value,
  double min = 0,
  double max = 100,
  double? step,
  bool enabled = true,
  FluentSliderSize size = FluentSliderSize.medium,
}) => FluentSliderState(
  value: value,
  min: min,
  max: max,
  step: step,
  enabled: enabled,
  size: size,
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axis. Every colour comes from a Fluent token; nothing
/// here computes one.
///
/// Every value below is the Figma `Slider` set (`test/fixtures/slider.json`,
/// 10 variants), asserted variant-by-variant in the tests. Figma's layer names
/// map onto these fields as: `Rail-fill` is [FluentSliderStyle.railColor],
/// `Track-fill` is [FluentSliderStyle.progressColor], `Thumb` is
/// [FluentSliderStyle.thumbInnerColor] plus its outline, and `Thumb-inner` is
/// [FluentSliderStyle.thumbColor].
///
/// Where Figma and upstream's `useSliderStyles.styles.ts` disagree, Figma wins:
///
/// * the disabled rail is `Neutral/Stroke/Transparent/Disabled/Rest`, not
///   `colorNeutralBackgroundDisabled` — a disabled rail is invisible except
///   where the progress covers it
/// * the disabled thumb outline is `Neutral/Stroke/Disabled/Rest`, not
///   `colorNeutralForegroundDisabled`
/// * the thumb outline is a flat 1 in both sizes, not `thumbSize * 0.05`
/// * the thumb's centre disc is 12 and 10 across, not `thumbSize * 0.3`
/// * the control is 24 high in **both** sizes; React's medium is 32
/// * the rail stops 8 short of each end in both sizes; React's grid insets it
///   by half a thumb
/// * the rail's corner radius is `Corner radius/Small`, and Figma paints no
///   outline on the rail at all
FluentSliderStyle resolveFluentSliderStyle(
  FluentSliderState state,
  FluentThemeData theme,
) {
  final c = theme.colors;

  final rail = FluentStateColor.tokens(
    rest: c.neutralStrokeAccessible,
    // Fully transparent in light, opaque in high contrast — which is why it is
    // this token and not `Colors.transparent`.
    disabled: c.transparentStrokeDisabled,
  );

  // The progress and the thumb's disc share one ramp: Figma paints `Track-fill`
  // and `Thumb-inner` with the same token in all ten variants.
  final progress = FluentStateColor.tokens(
    rest: c.compoundBrandBackground,
    hover: c.compoundBrandBackgroundHover,
    pressed: c.compoundBrandBackgroundPressed,
    disabled: c.neutralForegroundDisabled,
  );

  final thumbBorder = FluentStateColor.tokens(
    rest: c.neutralStroke1,
    disabled: c.neutralStrokeDisabled,
  );

  // thumbSize is the outer diameter: Figma's Thumb frame is 18 (14) with a 1px
  // OUTSIDE stroke, so it occupies 20 (16).
  final (thumbSize, railThickness, thumbInnerRadius) = switch (state.size) {
    FluentSliderSize.medium => (20.0, 4.0, 6.0),
    FluentSliderSize.small => (16.0, 2.0, 5.0),
  };

  return FluentSliderStyle(
    railColor: rail,
    progressColor: progress,
    // The ticks are drawn in the surface colour, so a stepped rail reads as
    // notched rather than striped. Figma's set has no stepped variant, so this
    // one value still comes from upstream.
    stepColor: FluentStateColor.tokens(rest: c.neutralBackground1),
    thumbColor: progress,
    thumbInnerColor: FluentStateColor.tokens(rest: c.neutralBackground1),
    thumbBorderColor: thumbBorder,
    railThickness: WidgetStatePropertyAll<double?>(railThickness),
    railInset: const WidgetStatePropertyAll<double?>(FluentSpacing.s),
    railRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allSmall,
    ),
    thumbSize: WidgetStatePropertyAll<double?>(thumbSize),
    thumbInnerRadius: WidgetStatePropertyAll<double?>(thumbInnerRadius),
    thumbBorderWidth: const WidgetStatePropertyAll<double?>(FluentStroke.thin),
    // Figma's frame: 120 wide, 24 high, in both sizes.
    minimumSize: const WidgetStatePropertyAll<Size?>(Size(120, 24)),
    mouseCursor: const WidgetStatePropertyAll<MouseCursor?>(
      SystemMouseCursors.click,
    ),
  );
}

/// Renders a slider from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentSliderBaseState] rather than [FluentSliderState] on purpose: it never
/// reads the size axis, so a consumer can supply their own style and still use
/// Fluent's rendering and focus ring.
///
/// [states] is the live interaction set from [FluentInteractive]. It carries no
/// transition: upstream's styles file declares none anywhere, so hover, press
/// and disabled repaint on the frame they happen.
///
/// The rail expands to the width it is given, so it must be laid out inside
/// something with a bounded width.
Widget buildFluentSlider(
  FluentSliderBaseState state,
  FluentSliderStyle style,
  Set<WidgetState> states,
) {
  final minimumSize = style.minimumSize?.resolve(states) ?? Size.zero;
  return FluentFocusRing(
    visible: states.contains(WidgetState.focused),
    // Figma draws the ring on `Corner radius/Small`, and React agrees by a
    // different route: `.fui-Slider::after` carries a flat `border-radius: 4px`
    // on a box inset from the root, so its OUTER radius is 4 — which is what a
    // 2px ring concentric to a radius-2 component comes to.
    borderRadius: FluentRadius.allSmall,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minimumSize.width,
        minHeight: minimumSize.height,
      ),
      child: SizedBox(
        height: minimumSize.height,
        width: double.infinity,
        child: _FluentSliderSurface(state: state, style: style, states: states),
      ),
    ),
  );
}

/// Reads the ambient directionality, which [buildFluentSlider] has no context
/// for, and hands the painter everything already resolved.
class _FluentSliderSurface extends StatelessWidget {
  const _FluentSliderSurface({
    required this.state,
    required this.style,
    required this.states,
  });

  final FluentSliderBaseState state;
  final FluentSliderStyle style;
  final Set<WidgetState> states;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: FluentSliderPainter(
      fraction: state.fraction,
      intervals: state.intervals,
      textDirection: Directionality.of(context),
      railColor: style.railColor?.resolve(states),
      progressColor: style.progressColor?.resolve(states),
      stepColor: style.stepColor?.resolve(states),
      thumbColor: style.thumbColor?.resolve(states),
      thumbInnerColor: style.thumbInnerColor?.resolve(states),
      thumbBorderColor: style.thumbBorderColor?.resolve(states),
      railThickness: style.railThickness?.resolve(states) ?? 0,
      railInset: style.railInset?.resolve(states) ?? FluentSpacing.s,
      railRadius: style.railRadius?.resolve(states) ?? FluentRadius.allSmall,
      thumbSize: style.thumbSize?.resolve(states) ?? 0,
      thumbInnerRadius: style.thumbInnerRadius?.resolve(states) ?? 0,
      thumbBorderWidth:
          style.thumbBorderWidth?.resolve(states) ?? FluentStroke.none,
    ),
  );
}

/// Paints a slider's rail, progress, ticks and thumb.
///
/// A painter rather than a stack of [DecoratedBox]es because the parts overlap:
/// the progress is clipped to the rail's pill, the ticks are drawn over the
/// progress, and the thumb straddles the rail's edge. Composing that would take
/// four widgets and a [Stack] to produce fewer pixels.
///
/// Every input is a public field so tests can assert the resolved tokens
/// directly — a painted surface cannot be read back out of the widget tree.
class FluentSliderPainter extends CustomPainter {
  /// Creates a painter for already-resolved colours and geometry.
  const FluentSliderPainter({
    required this.fraction,
    required this.textDirection,
    required this.railThickness,
    required this.railInset,
    required this.railRadius,
    required this.thumbSize,
    required this.thumbInnerRadius,
    required this.thumbBorderWidth,
    this.intervals,
    this.railColor,
    this.progressColor,
    this.stepColor,
    this.thumbColor,
    this.thumbInnerColor,
    this.thumbBorderColor,
  });

  /// Where the thumb sits along the rail, from 0 to 1.
  final double fraction;

  /// How many intervals to tick, or null for a continuous rail.
  final int? intervals;

  /// Which end of the rail the minimum is at.
  final TextDirection textDirection;

  /// The unfilled part of the rail.
  final Color? railColor;

  /// The filled part of the rail.
  final Color? progressColor;

  /// The tick marks.
  final Color? stepColor;

  /// The thumb's centre disc.
  final Color? thumbColor;

  /// The ring between [thumbColor] and [thumbBorderColor].
  final Color? thumbInnerColor;

  /// The thumb's outline.
  final Color? thumbBorderColor;

  /// Rail height.
  final double railThickness;

  /// How far the rail stops short of each end of the control. The thumb's
  /// centre travels between the two insets, less one [thumbInnerRadius] at each
  /// end — upstream's `clamp(innerThumbRadius, progress, 100% - …)`.
  final double railInset;

  /// Rail corner radius.
  final BorderRadius railRadius;

  /// Thumb diameter, outline included.
  final double thumbSize;

  /// Radius of the thumb's centre disc.
  final double thumbInnerRadius;

  /// Thumb outline width.
  final double thumbBorderWidth;

  @override
  void paint(Canvas canvas, Size size) {
    // Figma's `Rail` frame insets its fill by `Spacing/Horizontal/S` at each
    // end, in both sizes — not by half a thumb, which is what upstream's
    // `1fr calc(100% - thumbSize) 1fr` grid produces.
    final rail = Rect.fromLTWH(
      railInset,
      (size.height - railThickness) / 2,
      (size.width - 2 * railInset).clamp(0, double.infinity),
      railThickness,
    );
    if (rail.width <= 0) return;
    final pill = railRadius.toRRect(rail);
    final rtl = textDirection == TextDirection.rtl;

    if (railColor != null) {
      canvas.drawRRect(pill, Paint()..color = railColor!);
    }

    canvas.save();
    canvas.clipRRect(pill);

    final filled = rail.width * fraction;
    if (progressColor != null && filled > 0) {
      canvas.drawRect(
        rtl
            ? Rect.fromLTWH(rail.right - filled, rail.top, filled, rail.height)
            : Rect.fromLTWH(rail.left, rail.top, filled, rail.height),
        Paint()..color = progressColor!,
      );
    }

    // Upstream draws these as a 1px-per-period repeating gradient, so a tick
    // marks the END of each interval and the last one lands on the rail's far
    // edge.
    final ticks = intervals;
    if (ticks != null && stepColor != null) {
      final period = rail.width / ticks;
      final paint = Paint()..color = stepColor!;
      for (var i = 1; i <= ticks; i++) {
        final edge = rtl ? rail.right - i * period : rail.left + i * period;
        canvas.drawRect(
          Rect.fromLTWH(
            rtl ? edge : edge - FluentStroke.thin,
            rail.top,
            FluentStroke.thin,
            rail.height,
          ),
          paint,
        );
      }
    }
    canvas.restore();

    final thumbRadius = thumbSize / 2;
    // Upstream clamps the thumb's own position — and only that; the progress
    // fill still starts at the rail's end — with
    // `clamp(innerThumbRadius, progress, calc(100% - innerThumbRadius))`, so
    // the thumb never travels closer than one centre-disc radius to either end
    // of the rail. Without it a medium thumb at either extreme is centred on
    // the rail's end and hangs 2 outside the control's own box.
    final travel = clampDouble(thumbInnerRadius, 0, rail.width / 2);
    final centre = Offset(
      clampDouble(
        rtl
            ? rail.right - rail.width * fraction
            : rail.left + rail.width * fraction,
        rail.left + travel,
        rail.right - travel,
      ),
      size.height / 2,
    );
    if (thumbInnerColor != null) {
      canvas.drawCircle(centre, thumbRadius, Paint()..color = thumbInnerColor!);
    }
    if (thumbColor != null) {
      canvas.drawCircle(centre, thumbInnerRadius, Paint()..color = thumbColor!);
    }
    if (thumbBorderWidth > 0 && thumbBorderColor != null) {
      canvas.drawCircle(
        centre,
        thumbRadius - thumbBorderWidth / 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = thumbBorderWidth
          ..color = thumbBorderColor!,
      );
    }
  }

  @override
  bool shouldRepaint(FluentSliderPainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.intervals != intervals ||
      oldDelegate.textDirection != textDirection ||
      oldDelegate.railColor != railColor ||
      oldDelegate.progressColor != progressColor ||
      oldDelegate.stepColor != stepColor ||
      oldDelegate.thumbColor != thumbColor ||
      oldDelegate.thumbInnerColor != thumbInnerColor ||
      oldDelegate.thumbBorderColor != thumbBorderColor ||
      oldDelegate.railThickness != railThickness ||
      oldDelegate.railInset != railInset ||
      oldDelegate.railRadius != railRadius ||
      oldDelegate.thumbSize != thumbSize ||
      oldDelegate.thumbInnerRadius != thumbInnerRadius ||
      oldDelegate.thumbBorderWidth != thumbBorderWidth;
}

/// Overrides the slider style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`.
class FluentSliderTheme extends InheritedTheme {
  /// Applies [style] to every [FluentSlider] in [child].
  const FluentSliderTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the size defaults.
  final FluentSliderStyle style;

  /// The nearest slider style, or null.
  static FluentSliderStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentSliderTheme>()?.style;

  @override
  bool updateShouldNotify(FluentSliderTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentSliderTheme(style: style, child: child);
}

/// Moves the value by one keyboard step, or to an end of the range.
class _AdjustSliderIntent extends Intent {
  const _AdjustSliderIntent.by(this.steps) : toEnd = false;
  const _AdjustSliderIntent.toEnd(this.steps) : toEnd = true;

  /// Direction of travel: -1 or 1.
  final int steps;

  /// Whether to jump to the end rather than move one step.
  final bool toEnd;
}

/// A Fluent 2 slider.
///
/// ```dart
/// FluentSlider(
///   value: volume,
///   onChanged: (next) => setState(() => volume = next),
/// )
/// ```
///
/// Controlled, like every other Flutter input: it never holds the value, it
/// reports the one the gesture or key landed on and rebuilds when the caller
/// passes it back.
///
/// Pass `onChanged: null` to disable it — disabled is a real state here, not a
/// visual treatment: the slider stops reporting hover and press, refuses focus,
/// ignores drags and keys, and announces itself as disabled.
///
/// [step] switches the rail from continuous to stepped: values snap to the
/// interval and a tick is drawn per interval. Keyboard travel is one [step], or
/// one unit when the slider is continuous, matching the native range input.
///
/// The rail expands to the width it is given, so give it a bounded one.
///
/// Customisation follows the same three rungs as every other component here.
/// [style] is merged last and wins; [FluentSliderTheme] restyles a subtree; and
/// for anything further, [resolveFluentSliderState], [resolveFluentSliderStyle]
/// and [buildFluentSlider] are public so any one of them can be replaced
/// without forking this widget.
class FluentSlider extends StatefulWidget {
  /// Creates a slider. Omit [onChanged] to disable it.
  const FluentSlider({
    super.key,
    required this.value,
    this.onChanged,
    this.min = 0,
    this.max = 100,
    this.step,
    this.size = FluentSliderSize.medium,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    this.semanticFormatter,
  });

  /// The current value. Clamped into [min]…[max] for rendering.
  final double value;

  /// Called with the value a drag or a key landed on. Null disables the slider.
  final ValueChanged<double>? onChanged;

  /// The value at the start of the rail.
  final double min;

  /// The value at the end of the rail.
  final double max;

  /// The interval between selectable values. Null leaves the rail continuous
  /// and unticked.
  final double? step;

  /// Thumb diameter and rail thickness.
  final FluentSliderSize size;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentSliderStyle? style;

  /// Focus node to use. One is created internally when omitted.
  final FocusNode? focusNode;

  /// Whether to take focus on mount.
  final bool autofocus;

  /// Announced by assistive technology alongside the value.
  ///
  /// A slider with no label announces a bare number, which tells a screen
  /// reader user nothing about what it controls.
  final String? semanticLabel;

  /// Formats a value for assistive technology.
  ///
  /// Defaults to a plain number with no trailing zeros. Supply one whenever the
  /// value has a unit — "40 percent" is an announcement, "40" is a guess.
  final String Function(double value)? semanticFormatter;

  @override
  State<FluentSlider> createState() => _FluentSliderState();
}

class _FluentSliderState extends State<FluentSlider> {
  /// One keyboard press of travel. The native range input steps by 1 when no
  /// step is given, so this does too.
  double get _keyStep => widget.step ?? 1;

  FluentSliderBaseState get _base => FluentSliderBaseState(
    value: widget.value,
    min: widget.min,
    max: widget.max,
    step: widget.step,
    enabled: widget.onChanged != null,
  );

  String _format(double value) =>
      widget.semanticFormatter?.call(value) ??
      (value == value.roundToDouble()
          ? value.round().toString()
          : value.toStringAsFixed(2));

  void _report(double raw) {
    final next = _base.snap(raw);
    if (next != widget.value) widget.onChanged!.call(next);
  }

  /// Turns a pointer x, local to the control's own box, into a value.
  ///
  /// [railInset] is where the rail starts, so it is also where the thumb's
  /// centre starts — the pointer maps onto the rail, not onto the box.
  void _reportAt(double dx, double railInset) {
    final width = context.size?.width ?? 0;
    final track = width - 2 * railInset;
    if (track <= 0) return;
    var t = clampDouble((dx - railInset) / track, 0, 1);
    if (Directionality.of(context) == TextDirection.rtl) t = 1 - t;
    _report(widget.min + t * (widget.max - widget.min));
  }

  void _adjust(_AdjustSliderIntent intent) {
    // Arrow keys are reading-order, not value-order: on an RTL rail the left
    // arrow increases, because the minimum is on the right.
    final sign = Directionality.of(context) == TextDirection.rtl
        ? -intent.steps
        : intent.steps;
    _report(
      intent.toEnd
          ? (sign > 0 ? widget.max : widget.min)
          : widget.value + sign * _keyStep,
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onChanged != null;
    final state = resolveFluentSliderState(
      value: widget.value,
      min: widget.min,
      max: widget.max,
      step: widget.step,
      enabled: enabled,
      size: widget.size,
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentSliderStyle(
      state,
      FluentTheme.of(context),
    ).merge(FluentSliderTheme.maybeOf(context)).merge(widget.style);

    final railInset =
        resolved.railInset?.resolve(const <WidgetState>{}) ?? FluentSpacing.s;

    final slider = FluentInteractive(
      // FluentInteractive treats a null callback as disabled, and a slider has
      // no activation gesture of its own — Space and Enter do nothing to a
      // native range input either. The no-op is what marks it enabled.
      onPressed: enabled ? () {} : null,
      enabled: enabled,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      mouseCursor:
          resolved.mouseCursor?.resolve(const <WidgetState>{}) ??
          SystemMouseCursors.click,
      builder: (context, states, _) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Deeper than FluentInteractive's own tap recognizer, so it wins the
        // arena: a tap on the rail jumps the thumb there rather than doing
        // nothing.
        onTapDown: enabled
            ? (details) => _reportAt(details.localPosition.dx, railInset)
            : null,
        onHorizontalDragStart: enabled
            ? (details) => _reportAt(details.localPosition.dx, railInset)
            : null,
        onHorizontalDragUpdate: enabled
            ? (details) => _reportAt(details.localPosition.dx, railInset)
            : null,
        child: buildFluentSlider(state, resolved, states),
      ),
    );

    return Semantics(
      slider: true,
      enabled: enabled,
      label: widget.semanticLabel,
      value: _format(clampDouble(widget.value, widget.min, widget.max)),
      increasedValue: _format(_base.snap(widget.value + _keyStep)),
      decreasedValue: _format(_base.snap(widget.value - _keyStep)),
      onIncrease: enabled ? () => _report(widget.value + _keyStep) : null,
      onDecrease: enabled ? () => _report(widget.value - _keyStep) : null,
      // Above FluentInteractive, so these beat the app-level arrow bindings
      // that would otherwise move focus off the slider.
      child: Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.arrowLeft): _AdjustSliderIntent.by(
            -1,
          ),
          SingleActivator(LogicalKeyboardKey.arrowDown): _AdjustSliderIntent.by(
            -1,
          ),
          SingleActivator(LogicalKeyboardKey.arrowRight):
              _AdjustSliderIntent.by(1),
          SingleActivator(LogicalKeyboardKey.arrowUp): _AdjustSliderIntent.by(
            1,
          ),
          SingleActivator(LogicalKeyboardKey.home): _AdjustSliderIntent.toEnd(
            -1,
          ),
          SingleActivator(LogicalKeyboardKey.end): _AdjustSliderIntent.toEnd(1),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            _AdjustSliderIntent: CallbackAction<_AdjustSliderIntent>(
              onInvoke: (intent) {
                if (enabled) _adjust(intent);
                return null;
              },
            ),
          },
          child: slider,
        ),
      ),
    );
  }
}
