import 'package:fluent_2_core/fluent_2_core.dart';
// For clampDouble and listEquals, which widgets.dart does not re-export.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../internal/interaction.dart';
import '../internal/pointer_capture.dart';
import 'color_area.dart';
import 'color_picker.dart';
import 'color_slider_style.dart';

/// Which channel of a colour a rail edits. Upstream's `ColorChannel`, plus the
/// alpha channel its `AlphaSlider` splits into a separate component.
enum FluentColorChannel {
  /// The full 0…360 spectrum, red through red. The default.
  hue,

  /// Grey to the fully saturated hue, 0…100.
  saturation,

  /// Black to the fully bright colour, 0…100.
  value,

  /// Transparent to opaque, 0…100, over a checkerboard.
  ///
  /// Prefer `FluentAlphaSlider`, which is this channel with a name.
  alpha,
}

/// The light square of an alpha rail's checkerboard.
///
/// Deliberately theme-independent, exactly as upstream's PNG is — one image
/// serves light, dark and high contrast alike. A dark checker in a dark theme
/// would make low alpha read as "a dark colour" rather than "no colour".
///
/// ponytail: a top-level const, not a style field. There is nothing upstream to
/// inherit from, so three `WidgetStateProperty` knobs every caller leaves null
/// would be dead flexibility. If a design ever asks for a themed checkerboard,
/// the honest token pair is `neutralBackground1` / `neutralBackground3`, and it
/// is a deviation worth writing down.
const Color kFluentAlphaCheckerLight = FluentGrey.white;

/// The dark square of an alpha rail's checkerboard.
///
/// Decoded from Fabric's `transparent-pattern.png`; equal to
/// `FluentGrey.ramp[80]` by value, not by intent.
const Color kFluentAlphaCheckerDark = Color(0xFFCCCCCC);

/// Edge of one checkerboard square, in logical pixels. Upstream's PNG is a
/// 12 x 12 tile of four of them.
const double kFluentAlphaCheckerSquare = FluentSize.size60;

/// The edge a rail's minimum value sits against.
///
/// The bottom when [vertical] — Fluent's vertical sliders put the smallest
/// value at the bottom, which upstream gets from `writing-mode: vertical-lr`
/// plus `direction: rtl` on the native input. Otherwise the reading-order start
/// edge, mirrored by [textDirection].
///
/// The opposite edge is `-fluentColorRailAnchor(...)`, so one call places a
/// gradient, a thumb and a pointer alike.
Alignment fluentColorRailAnchor({
  required bool vertical,
  required TextDirection textDirection,
}) => vertical
    ? Alignment.bottomCenter
    : (textDirection == TextDirection.rtl
          ? Alignment.centerRight
          : Alignment.centerLeft);

/// Everything needed to paint a colour rail, independent of the design axes.
///
/// [buildFluentColorSlider] takes this rather than [FluentColorSliderState],
/// which is what makes "Fluent's state, my own styling, Fluent's rendering" a
/// supported path rather than a fork.
@immutable
class FluentColorSliderBaseState {
  /// Creates a base state.
  const FluentColorSliderBaseState({
    required this.color,
    required this.channel,
    required this.vertical,
    required this.transparency,
    required this.enabled,
  });

  /// The colour the rail is showing.
  final HSVColor color;

  /// Which channel this rail edits.
  final FluentColorChannel channel;

  /// Whether the rail runs bottom to top instead of start to end.
  final bool vertical;

  /// Whether an alpha rail counts transparency rather than opacity. Ignored on
  /// every other channel.
  final bool transparency;

  /// Whether the rail responds to input.
  final bool enabled;

  /// The channel's largest value: 360 degrees of hue, 100 percent of anything
  /// else. Upstream's `HUE_MAX` / `MAX`.
  double get maximum => channel == FluentColorChannel.hue ? 360 : 100;

  /// The channel's current value, in 0…[maximum]. This is the number a screen
  /// reader announces and the number a key press moves.
  ///
  /// An alpha rail in [transparency] mode counts down: 30 means 30% transparent,
  /// which is 70% opaque.
  double get channelValue => switch (channel) {
    FluentColorChannel.hue => color.hue.roundToDouble(),
    FluentColorChannel.saturation => (color.saturation * 100).roundToDouble(),
    FluentColorChannel.value => (color.value * 100).roundToDouble(),
    FluentColorChannel.alpha =>
      transparency
          ? 100 - (color.alpha * 100).roundToDouble()
          : (color.alpha * 100).roundToDouble(),
  };

  /// Where the thumb sits along the rail, from 0 at the anchor edge to 1.
  double get fraction => clampDouble(channelValue / maximum, 0, 1);

  /// The colour to report when this channel moves to [next], in 0…[maximum].
  ///
  /// Every other channel travels through untouched, and [fluentColorFrom] does
  /// the clamping — so a hue of 361 is a hue of 360 rather than an assertion.
  HSVColor colorAt(double next) => switch (channel) {
    FluentColorChannel.hue => fluentColorFrom(
      hue: next,
      saturation: color.saturation,
      value: color.value,
      alpha: color.alpha,
    ),
    FluentColorChannel.saturation => fluentColorFrom(
      hue: color.hue,
      saturation: next / 100,
      value: color.value,
      alpha: color.alpha,
    ),
    FluentColorChannel.value => fluentColorFrom(
      hue: color.hue,
      saturation: color.saturation,
      value: next / 100,
      alpha: color.alpha,
    ),
    FluentColorChannel.alpha => fluentColorFrom(
      hue: color.hue,
      saturation: color.saturation,
      value: color.value,
      alpha: (transparency ? 100 - next : next) / 100,
    ),
  };

  /// The colour at full saturation and brightness — upstream's
  /// `hsl(h, 100%, 50%)`, which ends the saturation and value ramps.
  Color get hueColor => HSVColor.fromAHSV(1, color.hue, 1, 1).toColor();

  /// The current colour with its alpha discarded.
  Color get opaqueColor =>
      HSVColor.fromAHSV(1, color.hue, color.saturation, color.value).toColor();

  /// The rail's gradient stops, from the anchor edge outwards.
  ///
  /// Fresh every call, so a painter holding this must compare it with
  /// `listEquals` rather than `==`.
  List<Color> get railColors => switch (channel) {
    FluentColorChannel.hue => FluentColorSliderPainter.hueRamp,
    // #808080 is a raw literal upstream, not a token. It happens to equal
    // FluentGrey.ramp[50]; that is a coincidence of value, not of intent.
    FluentColorChannel.saturation => <Color>[const Color(0xFF808080), hueColor],
    FluentColorChannel.value => <Color>[const Color(0xFF000000), hueColor],
    // The transparent stop must carry the opaque colour's RGB. Flutter
    // interpolates unpremultiplied, so a transparent *black* stop would drag
    // the ramp towards grey instead of fading cleanly.
    FluentColorChannel.alpha =>
      transparency
          ? <Color>[opaqueColor, opaqueColor.withAlpha(0)]
          : <Color>[opaqueColor.withAlpha(0), opaqueColor],
  };

  /// The colour inside the thumb, composited over [surface].
  ///
  /// A hue thumb shows the pure hue; a saturation or value thumb shows the
  /// colour itself. Only an alpha thumb is translucent, and upstream paints it
  /// over the thumb's own opaque fill — not over the rail's checkerboard —
  /// which is what [surface] is.
  Color thumbColorOver(Color surface) => switch (channel) {
    FluentColorChannel.hue => hueColor,
    FluentColorChannel.saturation || FluentColorChannel.value => opaqueColor,
    FluentColorChannel.alpha => Color.alphaBlend(color.toColor(), surface),
  };
}

/// A rail's fully resolved state, including the design axis.
@immutable
class FluentColorSliderState extends FluentColorSliderBaseState {
  /// Creates a resolved state.
  const FluentColorSliderState({
    required super.color,
    required super.channel,
    required super.vertical,
    required super.transparency,
    required super.enabled,
    required this.shape,
  });

  /// The corner treatment.
  final FluentColorPickerShape shape;
}

/// Builds the state a rail will be styled and painted from.
///
/// The first of the three-function recomposition contract.
FluentColorSliderState resolveFluentColorSliderState({
  required HSVColor color,
  FluentColorChannel channel = FluentColorChannel.hue,
  bool vertical = false,
  bool transparency = false,
  bool enabled = true,
  FluentColorPickerShape shape = FluentColorPickerShape.rounded,
}) => FluentColorSliderState(
  color: color,
  channel: channel,
  vertical: vertical,
  transparency: transparency,
  enabled: enabled,
  shape: shape,
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes. Every colour comes from a Fluent token; nothing
/// here computes one.
///
/// The oracle is upstream's `useColorSliderStyles.styles.ts` and
/// `useAlphaSliderStyles.styles.ts`, not Figma: this is a preview-tier
/// component with no published Figma component set.
///
/// Two rules carry the whole focus treatment — upstream's
/// `input:focus-visible ~ .thumb` swaps the thumb's own border to
/// `strokeWidthThick` `colorStrokeFocus2`, which grows it from 22 to 24 without
/// moving its centre.
///
/// There is deliberately no disabled ramp: upstream ships no disabled state for
/// any part of the colour picker, so a disabled rail paints what an enabled one
/// paints and simply stops accepting input.
FluentColorSliderStyle resolveFluentColorSliderStyle(
  FluentColorSliderState state,
  FluentThemeData theme,
) {
  final c = theme.colors;
  return FluentColorSliderStyle(
    railThickness: const WidgetStatePropertyAll<double?>(20),
    railRadius: WidgetStatePropertyAll<BorderRadius?>(switch (state.shape) {
      FluentColorPickerShape.rounded => FluentRadius.allMedium,
      FluentColorPickerShape.square => BorderRadius.zero,
    }),
    // `colorTransparentStroke` and not a transparent literal: it is invisible
    // on an ordinary surface and a real edge under forced colours, which is the
    // only place a hue rail has an outline at all. An alpha rail draws a
    // visible one so the checkerboard reads as part of the control.
    railBorderColor: FluentStateColor.tokens(
      rest: state.channel == FluentColorChannel.alpha
          ? c.neutralStroke1
          : c.transparentStroke,
    ),
    railBorderWidth: const WidgetStatePropertyAll<double?>(FluentStroke.thin),
    minimumSize: WidgetStatePropertyAll<Size?>(
      state.vertical ? const Size(20, 280) : const Size(200, 32),
    ),
    thumbSize: WidgetStateProperty.resolveWith<double?>(
      (states) => kFluentColorThumbSize + 2 * _thumbBorder(states),
    ),
    thumbBorderColor: WidgetStateProperty.resolveWith<Color?>(
      (states) => states.contains(WidgetState.focused)
          ? c.strokeFocus2
          : c.neutralForeground4,
    ),
    thumbBorderWidth: WidgetStateProperty.resolveWith<double?>(_thumbBorder),
    thumbInnerColor: FluentStateColor.tokens(rest: c.neutralBackground1),
    thumbInnerWidth: const WidgetStatePropertyAll<double?>(FluentStroke.thick),
    thumbShadow: WidgetStatePropertyAll<List<BoxShadow>?>(
      theme.shadow(FluentElevation.shadow4),
    ),
    mouseCursor: const WidgetStatePropertyAll<MouseCursor?>(
      SystemMouseCursors.click,
    ),
  );
}

double _thumbBorder(Set<WidgetState> states) =>
    states.contains(WidgetState.focused)
    ? FluentStroke.thick
    : FluentStroke.thin;

/// Paints a rail from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentColorSliderBaseState] rather than [FluentColorSliderState] on
/// purpose: it never reads the shape axis — only the radius [style] resolved
/// from it — so a consumer can supply their own style and still use Fluent's
/// painting.
///
/// A horizontal rail takes the width it is given and is 32 tall; a vertical one
/// takes the height it is given and is 20 wide. Both fall back to their
/// minimum, so they lay out under a tight, a loose or an unbounded parent
/// alike — deliberately no `SizedBox(width: double.infinity)`, which would
/// report an infinite intrinsic size and break both.
Widget buildFluentColorSlider(
  FluentColorSliderBaseState state,
  FluentColorSliderStyle style,
  Set<WidgetState> states,
) {
  final minimumSize = style.minimumSize?.resolve(states) ?? Size.zero;
  return ConstrainedBox(
    constraints: BoxConstraints(
      minWidth: minimumSize.width,
      minHeight: minimumSize.height,
    ),
    child: _FluentColorSliderSurface(
      state: state,
      style: style,
      states: states,
    ),
  );
}

/// Reads the ambient directionality, which [buildFluentColorSlider] has no
/// context for, and hands the painter everything already resolved.
class _FluentColorSliderSurface extends StatelessWidget {
  const _FluentColorSliderSurface({
    required this.state,
    required this.style,
    required this.states,
  });

  final FluentColorSliderBaseState state;
  final FluentColorSliderStyle style;
  final Set<WidgetState> states;

  @override
  Widget build(BuildContext context) {
    final thumbInnerColor = style.thumbInnerColor?.resolve(states);
    return CustomPaint(
      painter: FluentColorSliderPainter(
        fraction: state.fraction,
        railColors: state.railColors,
        checkered: state.channel == FluentColorChannel.alpha,
        vertical: state.vertical,
        anchor: fluentColorRailAnchor(
          vertical: state.vertical,
          textDirection: Directionality.of(context),
        ),
        thumbColor: state.thumbColorOver(
          thumbInnerColor ?? kFluentAlphaCheckerLight,
        ),
        railThickness: style.railThickness?.resolve(states) ?? 0,
        railRadius: style.railRadius?.resolve(states) ?? BorderRadius.zero,
        railBorderColor: style.railBorderColor?.resolve(states),
        railBorderWidth:
            style.railBorderWidth?.resolve(states) ?? FluentStroke.none,
        thumbSize: style.thumbSize?.resolve(states) ?? 0,
        thumbBorderColor: style.thumbBorderColor?.resolve(states),
        thumbBorderWidth:
            style.thumbBorderWidth?.resolve(states) ?? FluentStroke.none,
        thumbInnerColor: thumbInnerColor,
        thumbInnerWidth:
            style.thumbInnerWidth?.resolve(states) ?? FluentStroke.none,
        thumbShadow: style.thumbShadow?.resolve(states) ?? const <BoxShadow>[],
      ),
    );
  }
}

/// Paints a rail's checkerboard, gradient, border and thumb.
///
/// A painter rather than a stack of [DecoratedBox]es because the thumb hangs 11
/// logical pixels past each end of the rail on purpose, and because the alpha
/// rail is a gradient over a checkerboard: composing that would take a [Stack],
/// a `Clip.none` and three render objects to produce fewer pixels.
/// [CustomPaint] does not clip its painter, so the overhang costs nothing.
///
/// Every input is a public field so tests can assert the resolved tokens
/// directly — a painted surface cannot be read back out of the widget tree.
class FluentColorSliderPainter extends CustomPainter {
  /// Creates a painter for already-resolved colours and geometry.
  const FluentColorSliderPainter({
    required this.fraction,
    required this.railColors,
    required this.checkered,
    required this.vertical,
    required this.anchor,
    required this.thumbColor,
    required this.railThickness,
    required this.railRadius,
    required this.railBorderWidth,
    required this.thumbSize,
    required this.thumbBorderWidth,
    required this.thumbInnerWidth,
    this.railBorderColor,
    this.thumbBorderColor,
    this.thumbInnerColor,
    this.thumbShadow = const <BoxShadow>[],
  });

  /// The hue ramp, in ascending hue: 0, 60, 120, 180, 240, 300, 360.
  ///
  /// Upstream writes the same seven stops *descending* — red, fuchsia, blue,
  /// aqua, lime, yellow, red — and reverses them with a `-90deg` gradient
  /// angle. Written ascending here, the direction is carried by [anchor]
  /// instead, so one stop list covers horizontal, vertical and RTL alike.
  static const List<Color> hueRamp = <Color>[
    Color(0xFFFF0000),
    Color(0xFFFFFF00),
    Color(0xFF00FF00),
    Color(0xFF00FFFF),
    Color(0xFF0000FF),
    Color(0xFFFF00FF),
    Color(0xFFFF0000),
  ];

  /// Where the thumb sits along the rail, from 0 at [anchor] to 1.
  final double fraction;

  /// The rail's gradient stops, from [anchor] outwards.
  final List<Color> railColors;

  /// Whether to lay a checkerboard under the gradient, so a translucent ramp
  /// reads as transparency rather than as a colour.
  final bool checkered;

  /// Whether the rail runs bottom to top instead of start to end.
  final bool vertical;

  /// The edge the rail's minimum sits against.
  final Alignment anchor;

  /// The colour inside the thumb.
  final Color thumbColor;

  /// Rail depth across the control.
  final double railThickness;

  /// The rail's corner radius.
  final BorderRadius railRadius;

  /// The rail's outline.
  final Color? railBorderColor;

  /// Width of [railBorderColor], painted inside the rail.
  final double railBorderWidth;

  /// Thumb diameter, outline included.
  final double thumbSize;

  /// The thumb's outermost ring.
  final Color? thumbBorderColor;

  /// Width of [thumbBorderColor].
  final double thumbBorderWidth;

  /// The ring between [thumbBorderColor] and [thumbColor], and the thumb's own
  /// fill under a translucent colour.
  final Color? thumbInnerColor;

  /// Width of [thumbInnerColor].
  final double thumbInnerWidth;

  /// The thumb's drop shadow.
  final List<BoxShadow> thumbShadow;

  /// The rail's rectangle inside a control of [size]: full length, centred
  /// across.
  Rect railRect(Size size) => vertical
      ? Rect.fromLTWH(
          (size.width - railThickness) / 2,
          0,
          railThickness,
          size.height,
        )
      : Rect.fromLTWH(
          0,
          (size.height - railThickness) / 2,
          size.width,
          railThickness,
        );

  /// The thumb's centre inside a control of [size].
  ///
  /// There is no half-thumb inset: [fraction] 0 puts the centre on the rail's
  /// anchor edge and the thumb hangs half its width outside, which is exactly
  /// what upstream's `1fr 100% 1fr` grid plus `translateX(-50%)` produces — and
  /// what makes hue 0 sit on the first pixel of the gradient.
  Offset thumbCentre(Size size) {
    final rail = railRect(size);
    if (vertical) {
      return Offset(rail.center.dx, rail.bottom - rail.height * fraction);
    }
    final fromStart = anchor.x < 0;
    return Offset(
      fromStart
          ? rail.left + rail.width * fraction
          : rail.right - rail.width * fraction,
      rail.center.dy,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rail = railRect(size);
    if (rail.isEmpty) return;
    final rrect = railRadius.toRRect(rail);

    canvas.save();
    canvas.clipRRect(rrect);
    if (checkered) _paintCheckerboard(canvas, rail);
    canvas.drawRect(
      rail,
      Paint()
        ..shader = LinearGradient(
          begin: anchor,
          end: -anchor,
          colors: railColors,
        ).createShader(rail),
    );
    canvas.restore();

    if (railBorderWidth > 0 && railBorderColor != null) {
      canvas.drawRRect(
        rrect.deflate(railBorderWidth / 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = railBorderWidth
          ..color = railBorderColor!,
      );
    }

    paintFluentColorThumb(
      canvas,
      centre: thumbCentre(size),
      size: thumbSize,
      fill: thumbColor,
      borderColor: thumbBorderColor,
      borderWidth: thumbBorderWidth,
      innerColor: thumbInnerColor,
      innerWidth: thumbInnerWidth,
      shadow: thumbShadow,
    );
  }

  /// Draws upstream's `transparent-pattern.png` rather than fetching it.
  ///
  /// The PNG is a 12 x 12 tile of four 6-pixel squares, `#CCCCCC` at the
  /// top-left. Two colours and about thirty rectangles reproduce it at any
  /// device pixel ratio with no asset, no decode and no network — a
  /// `NetworkImage` would make this package fail offline and make every golden
  /// non-deterministic.
  void _paintCheckerboard(Canvas canvas, Rect rail) {
    canvas.drawRect(rail, Paint()..color = kFluentAlphaCheckerLight);
    final paint = Paint()..color = kFluentAlphaCheckerDark;
    const square = kFluentAlphaCheckerSquare;
    final rows = (rail.height / square).ceil();
    final columns = (rail.width / square).ceil();
    for (var row = 0; row < rows; row += 1) {
      for (var column = row.isEven ? 0 : 1; column < columns; column += 2) {
        canvas.drawRect(
          Rect.fromLTWH(
            rail.left + column * square,
            rail.top + row * square,
            square,
            square,
          ).intersect(rail),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(FluentColorSliderPainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.checkered != checkered ||
      oldDelegate.vertical != vertical ||
      oldDelegate.anchor != anchor ||
      oldDelegate.thumbColor != thumbColor ||
      oldDelegate.railThickness != railThickness ||
      oldDelegate.railRadius != railRadius ||
      oldDelegate.railBorderColor != railBorderColor ||
      oldDelegate.railBorderWidth != railBorderWidth ||
      oldDelegate.thumbSize != thumbSize ||
      oldDelegate.thumbBorderColor != thumbBorderColor ||
      oldDelegate.thumbBorderWidth != thumbBorderWidth ||
      oldDelegate.thumbInnerColor != thumbInnerColor ||
      oldDelegate.thumbInnerWidth != thumbInnerWidth ||
      // Both of these are a fresh List every build — `railColors` is a getter
      // and `theme.shadow(...)` allocates — so `==` is identity here and would
      // report "changed" forever, silently.
      !listEquals(oldDelegate.railColors, railColors) ||
      !listEquals(oldDelegate.thumbShadow, thumbShadow);
}

/// Overrides the rail style for a subtree, for both colour and alpha sliders.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`.
class FluentColorSliderTheme extends InheritedTheme {
  /// Applies [style] to every [FluentColorSlider] and [FluentAlphaSlider] in
  /// [child].
  const FluentColorSliderTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the channel and shape defaults.
  final FluentColorSliderStyle style;

  /// The nearest rail style, or null.
  static FluentColorSliderStyle? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FluentColorSliderTheme>()
      ?.style;

  @override
  bool updateShouldNotify(FluentColorSliderTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentColorSliderTheme(style: style, child: child);
}

/// Moves the channel by one keyboard step, or to an end of its range.
class _AdjustColorSliderIntent extends Intent {
  const _AdjustColorSliderIntent.by(this.steps) : toEnd = false;
  const _AdjustColorSliderIntent.toEnd(this.steps) : toEnd = true;

  /// Direction of travel: -1 or 1.
  final int steps;

  /// Whether to jump to an end rather than move one step.
  final bool toEnd;
}

/// A Fluent 2 colour slider: one channel of a colour on a gradient rail.
///
/// ```dart
/// FluentColorSlider(
///   color: colour,
///   onChanged: (next) => setState(() => colour = next),
///   semanticLabel: 'Hue',
/// )
/// ```
///
/// Inside a [FluentColorPicker] the colour and the callback come from the
/// picker, so `const FluentColorSlider(semanticLabel: 'Hue')` is enough.
///
/// Controlled, like every other Flutter input: it never holds the colour, it
/// reports the one the gesture or key landed on and rebuilds when the caller
/// passes it back. Every channel it does not edit travels through untouched.
///
/// ## The whole rail is the drag surface
///
/// A press anywhere moves the value there immediately, and tracking continues
/// after the pointer leaves the rail — see `FluentPointerCapture`. The thumb is
/// never hit-tested; there is nothing to grab and nothing to miss.
///
/// ## Keyboard
///
/// Arrow keys move one unit — one degree of hue, one percent of anything else —
/// and Home and End jump to the ends. Up and right increase; on an RTL page
/// left and right swap, because the rail is mirrored with the reading order. A
/// vertical rail puts its minimum at the bottom, as Fluent's vertical sliders
/// do.
///
/// Customisation follows the same three rungs as every other component here.
/// [style] is merged last and wins; [FluentColorSliderTheme] restyles a
/// subtree; and for anything further, [resolveFluentColorSliderState],
/// [resolveFluentColorSliderStyle] and [buildFluentColorSlider] are public so
/// any one of them can be replaced without forking this widget.
class FluentColorSlider extends StatefulWidget {
  /// Creates a rail. Defaults to the hue channel.
  ///
  /// [color] and [onChanged] fall back to the enclosing [FluentColorPicker];
  /// at least one of the two sources must supply a colour.
  const FluentColorSlider({
    super.key,
    required this.semanticLabel,
    this.color,
    this.onChanged,
    this.channel = FluentColorChannel.hue,
    this.vertical = false,
    this.transparency = false,
    this.shape,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.semanticFormatter,
  });

  /// Announced by assistive technology as the rail's name.
  ///
  /// Required, not optional: a rail with no label announces a bare number,
  /// which tells a screen-reader user nothing about which channel moved.
  /// Upstream's own stories set `aria-label` on every one.
  final String semanticLabel;

  /// The colour to show. Falls back to the enclosing picker's.
  final HSVColor? color;

  /// Called with the colour a gesture or a key landed on. Falls back to the
  /// enclosing picker's callback; null from both disables the rail.
  final ValueChanged<HSVColor>? onChanged;

  /// Which channel this rail edits.
  ///
  /// [FluentColorChannel.alpha] works, but [FluentAlphaSlider] is the name for
  /// it — that is the widget upstream publishes, and the one whose defaults are
  /// right.
  final FluentColorChannel channel;

  /// Whether to run the rail bottom to top, smallest value at the bottom.
  final bool vertical;

  /// Whether an alpha rail counts transparency rather than opacity.
  ///
  /// **Read only when [channel] is [FluentColorChannel.alpha]**, and set
  /// through [FluentAlphaSlider] in practice. It lives here rather than only on
  /// that widget because the alpha rail *is* this widget: upstream's
  /// `AlphaSlider` styles hook ends by calling the `ColorSlider`'s, and its
  /// slots are a type alias for the `ColorSlider`'s.
  final bool transparency;

  /// The corner treatment. Falls back to the enclosing picker's, then rounded.
  final FluentColorPickerShape? shape;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentColorSliderStyle? style;

  /// Focus node to use. One is created internally when omitted.
  final FocusNode? focusNode;

  /// Whether to take focus on mount.
  final bool autofocus;

  /// Formats the announced value, which is in the channel's own units —
  /// degrees for hue, percent for everything else.
  ///
  /// Defaults to a plain number. Supply one whenever the unit matters:
  /// "120 degrees, lime" is an announcement, "120" is a guess.
  final String Function(double value)? semanticFormatter;

  @override
  State<FluentColorSlider> createState() => _FluentColorSliderState();
}

class _FluentColorSliderState extends State<FluentColorSlider> {
  /// One key press of travel. A native range input steps by 1, so this does
  /// too — one degree of hue, one percent of anything else.
  static const double _keyStep = 1;

  late HSVColor _color;
  ValueChanged<HSVColor>? _onChanged;

  bool get _enabled => _onChanged != null;

  FluentColorSliderBaseState get _base => FluentColorSliderBaseState(
    color: _color,
    channel: widget.channel,
    vertical: widget.vertical,
    transparency: widget.transparency,
    enabled: _enabled,
  );

  String _format(double value) =>
      widget.semanticFormatter?.call(value) ?? value.round().toString();

  void _report(double next) {
    final colour = _base.colorAt(next);
    if (colour != _color) _onChanged!.call(colour);
  }

  /// Turns a pointer position, local to the control, into a channel value.
  void _reportAt(Offset local) {
    final box = context.size;
    if (box == null) return;
    final extent = widget.vertical ? box.height : box.width;
    if (extent <= 0) return;

    final base = _base;
    final along = widget.vertical
        ? 1 - local.dy / extent
        : (Directionality.of(context) == TextDirection.rtl
              ? 1 - local.dx / extent
              : local.dx / extent);
    _report(clampDouble(along, 0, 1) * base.maximum);
  }

  void _adjust(_AdjustColorSliderIntent intent) {
    // Arrow keys are reading-order, not value-order: on an RTL rail the left
    // arrow increases, because the minimum is on the right. A vertical rail is
    // never mirrored — its minimum is at the bottom in both directions.
    final sign =
        !widget.vertical && Directionality.of(context) == TextDirection.rtl
        ? -intent.steps
        : intent.steps;
    final base = _base;
    _report(
      intent.toEnd
          ? (sign > 0 ? base.maximum : 0)
          : base.channelValue + sign * _keyStep,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final scope = FluentColorPickerScope.maybeOf(context);
    assert(
      widget.color != null || scope != null,
      'FluentColorSlider needs a colour: pass one, or put it inside a '
      'FluentColorPicker.',
    );

    _color = widget.color ?? scope?.color ?? kFluentColorPickerInitialColor;
    _onChanged = widget.onChanged ?? scope?.onColorChanged;
    final shape =
        widget.shape ?? scope?.shape ?? FluentColorPickerShape.rounded;

    final state = resolveFluentColorSliderState(
      color: _color,
      channel: widget.channel,
      vertical: widget.vertical,
      transparency: widget.transparency,
      enabled: _enabled,
      shape: shape,
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentColorSliderStyle(
      state,
      theme,
    ).merge(FluentColorSliderTheme.maybeOf(context)).merge(widget.style);

    final base = _base;
    final rail = FluentInteractive(
      // FluentInteractive treats a null callback as disabled, and a rail has no
      // activation gesture of its own — Space and Enter do nothing to a native
      // range input either. The no-op is what marks it enabled.
      onPressed: _enabled ? () {} : null,
      enabled: _enabled,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      mouseCursor:
          resolved.mouseCursor?.resolve(const <WidgetState>{}) ??
          SystemMouseCursors.click,
      builder: (context, states, _) => FluentPointerCapture(
        enabled: _enabled,
        onPointer: _reportAt,
        // Moving the thumb re-records this subtree only, instead of every
        // paragraph on the page above it.
        child: RepaintBoundary(
          child: buildFluentColorSlider(state, resolved, states),
        ),
      ),
    );

    return Semantics(
      slider: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      value: _format(base.channelValue),
      increasedValue: _format(
        clampDouble(base.channelValue + _keyStep, 0, base.maximum),
      ),
      decreasedValue: _format(
        clampDouble(base.channelValue - _keyStep, 0, base.maximum),
      ),
      onIncrease: _enabled ? () => _report(base.channelValue + _keyStep) : null,
      onDecrease: _enabled ? () => _report(base.channelValue - _keyStep) : null,
      // Above FluentInteractive, so these beat the app-level arrow bindings
      // that would otherwise move focus off the rail.
      child: Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.arrowLeft):
              _AdjustColorSliderIntent.by(-1),
          SingleActivator(LogicalKeyboardKey.arrowDown):
              _AdjustColorSliderIntent.by(-1),
          SingleActivator(LogicalKeyboardKey.arrowRight):
              _AdjustColorSliderIntent.by(1),
          SingleActivator(LogicalKeyboardKey.arrowUp):
              _AdjustColorSliderIntent.by(1),
          SingleActivator(LogicalKeyboardKey.home):
              _AdjustColorSliderIntent.toEnd(-1),
          SingleActivator(LogicalKeyboardKey.end):
              _AdjustColorSliderIntent.toEnd(1),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            _AdjustColorSliderIntent: CallbackAction<_AdjustColorSliderIntent>(
              onInvoke: (intent) {
                if (_enabled) _adjust(intent);
                return null;
              },
            ),
          },
          child: rail,
        ),
      ),
    );
  }
}

/// A Fluent 2 alpha slider: the alpha channel of a colour, over a
/// checkerboard.
///
/// ```dart
/// FluentAlphaSlider(
///   color: colour,
///   onChanged: (next) => setState(() => colour = next),
///   semanticLabel: 'Alpha',
/// )
/// ```
///
/// [FluentColorSlider] on [FluentColorChannel.alpha], which is what it is
/// upstream too: `useAlphaSliderStyles_unstable` ends by calling
/// `useColorSliderStyles_unstable`, and `AlphaSliderSlots` is a type alias for
/// `ColorSliderSlots`. Everything the colour slider documents applies here.
///
/// Set [transparency] to count *down*: an alpha slider at 30 with transparency
/// on means "30% transparent", which is a colour at 70% opacity, and the rail
/// fades the other way to match.
class FluentAlphaSlider extends StatelessWidget {
  /// Creates an alpha rail.
  ///
  /// [color] and [onChanged] fall back to the enclosing [FluentColorPicker];
  /// at least one of the two sources must supply a colour.
  const FluentAlphaSlider({
    super.key,
    required this.semanticLabel,
    this.color,
    this.onChanged,
    this.vertical = false,
    this.transparency = false,
    this.shape,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.semanticFormatter,
  });

  /// Announced by assistive technology as the rail's name.
  final String semanticLabel;

  /// The colour to show. Falls back to the enclosing picker's.
  final HSVColor? color;

  /// Called with the colour a gesture or a key landed on. Falls back to the
  /// enclosing picker's callback; null from both disables the rail.
  final ValueChanged<HSVColor>? onChanged;

  /// Whether to run the rail bottom to top, most transparent at the bottom.
  final bool vertical;

  /// Whether the rail counts transparency rather than opacity.
  ///
  /// With this off, 100 is fully opaque. With it on, 100 is fully transparent
  /// and the gradient runs the other way.
  final bool transparency;

  /// The corner treatment. Falls back to the enclosing picker's, then rounded.
  final FluentColorPickerShape? shape;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentColorSliderStyle? style;

  /// Focus node to use. One is created internally when omitted.
  final FocusNode? focusNode;

  /// Whether to take focus on mount.
  final bool autofocus;

  /// Formats the announced value, which is a percentage.
  final String Function(double value)? semanticFormatter;

  @override
  Widget build(BuildContext context) => FluentColorSlider(
    semanticLabel: semanticLabel,
    color: color,
    onChanged: onChanged,
    channel: FluentColorChannel.alpha,
    vertical: vertical,
    transparency: transparency,
    shape: shape,
    style: style,
    focusNode: focusNode,
    autofocus: autofocus,
    semanticFormatter: semanticFormatter,
  );
}
