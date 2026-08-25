import 'package:fluent_2_core/fluent_2_core.dart';
// For clampDouble and listEquals, which widgets.dart does not re-export.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../internal/interaction.dart';
import '../internal/pointer_capture.dart';
import 'color_area_style.dart';
import 'color_picker.dart';

/// Everything needed to paint a colour area, independent of the design axis.
///
/// [buildFluentColorArea] takes this rather than [FluentColorAreaState], which
/// is what makes "Fluent's state, my own styling, Fluent's rendering" a
/// supported path rather than a fork.
@immutable
class FluentColorAreaBaseState {
  /// Creates a base state.
  const FluentColorAreaBaseState({required this.color, required this.enabled});

  /// The colour the square is showing. Its saturation and value place the
  /// thumb; its hue paints the square.
  final HSVColor color;

  /// Whether the area responds to input.
  final bool enabled;

  /// Where the thumb sits across the square, from 0 to 1.
  double get saturation => color.saturation;

  /// Where the thumb sits up the square, from 0 at the bottom to 1 at the top.
  double get value => color.value;

  /// The opaque hue the square is painted over — upstream's
  /// `hsl(h, 100%, 50%)`.
  ///
  /// Taken from [color]'s own hue, never from a [Color]: grey has no hue to
  /// recover, so a round trip through RGB would collapse it to red.
  Color get hueColor => HSVColor.fromAHSV(1, color.hue, 1, 1).toColor();

  /// The colour inside the thumb — upstream's `tinycolor(hsv).toRgbString()`,
  /// which drops alpha.
  Color get thumbColor =>
      HSVColor.fromAHSV(1, color.hue, color.saturation, color.value).toColor();

  /// The colour at normalised coordinates [x] across and [y] up, with the hue
  /// and alpha of [color] carried through untouched.
  ///
  /// Clamping and quantising both happen in [fluentColorFrom], so a coordinate
  /// off the edge of the square is a colour on its edge rather than an
  /// assertion.
  HSVColor colorAt(double x, double y) => fluentColorFrom(
    hue: color.hue,
    saturation: x,
    value: y,
    alpha: color.alpha,
  );
}

/// A colour area's fully resolved state, including the design axis.
@immutable
class FluentColorAreaState extends FluentColorAreaBaseState {
  /// Creates a resolved state.
  const FluentColorAreaState({
    required super.color,
    required super.enabled,
    required this.shape,
  });

  /// The corner treatment.
  final FluentColorPickerShape shape;
}

/// Builds the state a colour area will be styled and painted from.
///
/// The first of the three-function recomposition contract.
FluentColorAreaState resolveFluentColorAreaState({
  required HSVColor color,
  bool enabled = true,
  FluentColorPickerShape shape = FluentColorPickerShape.rounded,
}) => FluentColorAreaState(color: color, enabled: enabled, shape: shape);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axis. Every colour comes from a Fluent token; nothing
/// here computes one.
///
/// The oracle is upstream's `useColorAreaStyles.styles.ts`, not Figma: this is
/// a preview-tier component (`@fluentui/react-color-picker-preview`) with no
/// published Figma component set, so there is no `test/fixtures` entry to
/// assert against and inventing one would be inventing the design.
///
/// Two rules carry the whole focus treatment, because upstream's is the thumb's
/// own border thickening rather than a ring drawn outside it: the border goes
/// `strokeWidthThin` to `strokeWidthThick` and `colorNeutralForeground4` to
/// `colorStrokeFocus2`. The thumb grows from 22 to 24 as a result, and stays
/// centred on the colour — upstream's `translate(-50%, 50%)` cancels the
/// thumb's own size exactly, which is why it does not shift.
///
/// There is deliberately no disabled ramp. Upstream ships no disabled state for
/// any part of the colour picker, and there are no tokens for one; a disabled
/// area therefore paints exactly what an enabled one paints and simply stops
/// accepting input.
FluentColorAreaStyle resolveFluentColorAreaStyle(
  FluentColorAreaState state,
  FluentThemeData theme,
) {
  final c = theme.colors;
  return FluentColorAreaStyle(
    borderColor: FluentStateColor.tokens(rest: c.neutralStroke1),
    borderWidth: const WidgetStatePropertyAll<double?>(FluentStroke.thin),
    borderRadius: WidgetStatePropertyAll<BorderRadius?>(switch (state.shape) {
      FluentColorPickerShape.rounded => FluentRadius.allMedium,
      FluentColorPickerShape.square => BorderRadius.zero,
    }),
    // 300 x 300 including the border, upstream's `min-width` / `min-height`.
    minimumSize: const WidgetStatePropertyAll<Size?>(Size(300, 300)),
    // `margin-bottom: spacingVerticalSNudge`, which exists to leave room for
    // the thumb hanging below the square at value 0.
    margin: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.only(bottom: FluentSpacing.sNudge),
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
      SystemMouseCursors.basic,
    ),
  );
}

/// The thumb's content diameter, before its border. Upstream's
/// `--fui-Slider__thumb--size`, which is a content-box width.
const double kFluentColorThumbSize = 20;

double _thumbBorder(Set<WidgetState> states) =>
    states.contains(WidgetState.focused)
    ? FluentStroke.thick
    : FluentStroke.thin;

/// Paints a colour area from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentColorAreaBaseState] rather than [FluentColorAreaState] on purpose: it
/// never reads the shape axis — only the radius [style] resolved from it — so a
/// consumer can supply their own style and still use Fluent's painting.
///
/// The square takes the width it is given and falls back to its minimum, so it
/// lays out under a tight, a loose or an unbounded parent alike. Deliberately
/// no `SizedBox(width: double.infinity)`: that reports an infinite intrinsic
/// width, which breaks both the picker's own sizing and any unbounded parent —
/// a `FluentPopover`'s content, for one.
Widget buildFluentColorArea(
  FluentColorAreaBaseState state,
  FluentColorAreaStyle style,
  Set<WidgetState> states,
) {
  final minimumSize = style.minimumSize?.resolve(states) ?? Size.zero;
  return Padding(
    padding: style.margin?.resolve(states) ?? EdgeInsets.zero,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minimumSize.width,
        minHeight: minimumSize.height,
      ),
      child: _FluentColorAreaSurface(
        state: state,
        style: style,
        states: states,
      ),
    ),
  );
}

/// Reads the ambient directionality, which [buildFluentColorArea] has no
/// context for, and hands the painter everything already resolved.
class _FluentColorAreaSurface extends StatelessWidget {
  const _FluentColorAreaSurface({
    required this.state,
    required this.style,
    required this.states,
  });

  final FluentColorAreaBaseState state;
  final FluentColorAreaStyle style;
  final Set<WidgetState> states;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: FluentColorAreaPainter(
      saturation: state.saturation,
      value: state.value,
      hueColor: state.hueColor,
      thumbColor: state.thumbColor,
      textDirection: Directionality.of(context),
      borderColor: style.borderColor?.resolve(states),
      borderWidth: style.borderWidth?.resolve(states) ?? FluentStroke.none,
      borderRadius: style.borderRadius?.resolve(states) ?? BorderRadius.zero,
      thumbSize: style.thumbSize?.resolve(states) ?? 0,
      thumbBorderColor: style.thumbBorderColor?.resolve(states),
      thumbBorderWidth:
          style.thumbBorderWidth?.resolve(states) ?? FluentStroke.none,
      thumbInnerColor: style.thumbInnerColor?.resolve(states),
      thumbInnerWidth:
          style.thumbInnerWidth?.resolve(states) ?? FluentStroke.none,
      thumbShadow: style.thumbShadow?.resolve(states) ?? const <BoxShadow>[],
    ),
  );
}

/// Paints a colour area's gradients, border and thumb.
///
/// A painter rather than a stack of [DecoratedBox]es because there are three
/// overlapping fills and a thumb that deliberately hangs 10 logical pixels
/// outside the square: composing that would take four widgets, a [Stack] and a
/// `Clip.none` to produce fewer pixels. [CustomPaint] does not clip its
/// painter, so the overhang costs nothing.
///
/// Every input is a public field so tests can assert the resolved tokens
/// directly — a painted surface cannot be read back out of the widget tree.
class FluentColorAreaPainter extends CustomPainter {
  /// Creates a painter for already-resolved colours and geometry.
  const FluentColorAreaPainter({
    required this.saturation,
    required this.value,
    required this.hueColor,
    required this.thumbColor,
    required this.textDirection,
    required this.borderWidth,
    required this.borderRadius,
    required this.thumbSize,
    required this.thumbBorderWidth,
    required this.thumbInnerWidth,
    this.borderColor,
    this.thumbBorderColor,
    this.thumbInnerColor,
    this.thumbShadow = const <BoxShadow>[],
  });

  /// The saturation ramp: opaque white to transparent, across the square.
  ///
  /// The end stop is transparent **white**, not [Color] `0x00000000`. CSS
  /// interpolates gradients in premultiplied space and Flutter does not, so a
  /// transparent *black* stop drags the midpoint towards grey and lays a
  /// visible haze down the middle of the square — a ~30% error that survives a
  /// screenshot review because it still looks like a colour picker.
  ///
  /// ponytail: two consts and one test beat a comment nobody reads. If a future
  /// edit "simplifies" either of these to a transparency keyword, the ramp test
  /// in `test/inputs/color_area_test.dart` fails on the literal value.
  static const List<Color> saturationRamp = <Color>[
    Color(0xFFFFFFFF),
    Color(0x00FFFFFF),
  ];

  /// The value ramp: transparent to opaque black, down the square.
  ///
  /// Transparent **black** is correct here — the opposite stop is black, so
  /// premultiplied and unpremultiplied interpolation agree.
  static const List<Color> valueRamp = <Color>[
    Color(0x00000000),
    Color(0xFF000000),
  ];

  // Hoisted so the only per-frame allocation is the shader itself. A
  // LinearGradient is compile-time data here: neither ramp depends on the
  // colour, only on the reading direction.
  static const LinearGradient _saturationLtr = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: saturationRamp,
  );
  static const LinearGradient _saturationRtl = LinearGradient(
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
    colors: saturationRamp,
  );
  static const LinearGradient _value = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: valueRamp,
  );

  /// Where the thumb sits across the square, from 0 to 1.
  final double saturation;

  /// Where the thumb sits up the square, from 0 at the bottom to 1 at the top.
  final double value;

  /// The opaque hue under the two ramps.
  final Color hueColor;

  /// The colour inside the thumb.
  final Color thumbColor;

  /// Which edge saturation 0 sits against: the left in [TextDirection.ltr].
  final TextDirection textDirection;

  /// The square's outline.
  final Color? borderColor;

  /// Width of [borderColor], painted inside the square.
  final double borderWidth;

  /// The square's corner radius.
  final BorderRadius borderRadius;

  /// Thumb diameter, outline included.
  final double thumbSize;

  /// The thumb's outermost ring.
  final Color? thumbBorderColor;

  /// Width of [thumbBorderColor].
  final double thumbBorderWidth;

  /// The ring between [thumbBorderColor] and [thumbColor].
  final Color? thumbInnerColor;

  /// Width of [thumbInnerColor].
  final double thumbInnerWidth;

  /// The thumb's drop shadow.
  final List<BoxShadow> thumbShadow;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (rect.isEmpty) return;
    final rrect = borderRadius.toRRect(rect);
    final rtl = textDirection == TextDirection.rtl;

    canvas.save();
    canvas.clipRRect(rrect);
    // Upstream's CSS lists the layers topmost-first; this is that list reversed.
    canvas.drawRect(rect, Paint()..color = hueColor);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = (rtl ? _saturationRtl : _saturationLtr).createShader(rect),
    );
    canvas.drawRect(rect, Paint()..shader = _value.createShader(rect));
    canvas.restore();

    if (borderWidth > 0 && borderColor != null) {
      canvas.drawRRect(
        rrect.deflate(borderWidth / 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth
          ..color = borderColor!,
      );
    }

    // One frame of reference for the gradients, the thumb and the pointer: the
    // full outer box. Upstream uses three — the border box for the gradients,
    // the padding box for the thumb and `getBoundingClientRect` for the
    // pointer — which leaves the thumb up to a pixel off the colour under it.
    paintFluentColorThumb(
      canvas,
      centre: Offset(
        size.width * (rtl ? 1 - saturation : saturation),
        size.height * (1 - value),
      ),
      size: thumbSize,
      fill: thumbColor,
      borderColor: thumbBorderColor,
      borderWidth: thumbBorderWidth,
      innerColor: thumbInnerColor,
      innerWidth: thumbInnerWidth,
      shadow: thumbShadow,
    );
  }

  @override
  bool shouldRepaint(FluentColorAreaPainter oldDelegate) =>
      oldDelegate.saturation != saturation ||
      oldDelegate.value != value ||
      oldDelegate.hueColor != hueColor ||
      oldDelegate.thumbColor != thumbColor ||
      oldDelegate.textDirection != textDirection ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.borderWidth != borderWidth ||
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.thumbSize != thumbSize ||
      oldDelegate.thumbBorderColor != thumbBorderColor ||
      oldDelegate.thumbBorderWidth != thumbBorderWidth ||
      oldDelegate.thumbInnerColor != thumbInnerColor ||
      oldDelegate.thumbInnerWidth != thumbInnerWidth ||
      // A fresh List every build — `theme.shadow(...)` allocates one — so `==`
      // is identity here and would report "changed" forever, silently.
      !listEquals(oldDelegate.thumbShadow, thumbShadow);
}

/// Overrides the colour-area style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`.
class FluentColorAreaTheme extends InheritedTheme {
  /// Applies [style] to every [FluentColorArea] in [child].
  const FluentColorAreaTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the shape defaults.
  final FluentColorAreaStyle style;

  /// The nearest colour-area style, or null.
  static FluentColorAreaStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentColorAreaTheme>()?.style;

  @override
  bool updateShouldNotify(FluentColorAreaTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentColorAreaTheme(style: style, child: child);
}

/// Moves the colour by one keyboard step on one or both axes.
class _AdjustColorAreaIntent extends Intent {
  const _AdjustColorAreaIntent(this.dx, this.dy);

  /// Saturation travel in steps: -1, 0 or 1.
  final int dx;

  /// Value travel in steps: -1, 0 or 1.
  final int dy;
}

/// A Fluent 2 colour area: a two-dimensional saturation and brightness square.
///
/// ```dart
/// FluentColorArea(
///   color: colour,
///   onChanged: (next) => setState(() => colour = next),
///   saturationLabel: 'Saturation',
///   brightnessLabel: 'Brightness',
/// )
/// ```
///
/// Inside a [FluentColorPicker] both arguments can be dropped — the colour and
/// the callback come from the picker:
///
/// ```dart
/// FluentColorPicker(
///   color: colour,
///   onColorChanged: (next) => setState(() => colour = next),
///   children: const <Widget>[
///     FluentColorArea(
///       saturationLabel: 'Saturation',
///       brightnessLabel: 'Brightness',
///     ),
///   ],
/// )
/// ```
///
/// Controlled, like every other Flutter input: it never holds the colour, it
/// reports the one the gesture or key landed on and rebuilds when the caller
/// passes it back. Hue and alpha travel through untouched — this square edits
/// exactly two of the four channels.
///
/// ## The whole square is the drag surface
///
/// A press anywhere moves the colour there immediately, and tracking continues
/// after the pointer leaves the square, exactly as upstream's `mousedown` plus
/// document `mousemove` does. That means a drag starting on a colour area never
/// scrolls the page around it, on any device — see `FluentPointerCapture` for
/// why that is claimed at pointer-down rather than after the drag slop.
///
/// ## Keyboard
///
/// Arrow keys move one percent. Left and right are the saturation axis, up and
/// down the brightness axis; on an RTL page the saturation axis is mirrored,
/// paint and arrows together. Upstream instead moves a roving `tabIndex`
/// between two hidden range inputs, so only one axis answers the arrows at a
/// time; here both do, and there is one focus stop instead of two.
///
/// Customisation follows the same three rungs as every other component here.
/// [style] is merged last and wins; [FluentColorAreaTheme] restyles a subtree;
/// and for anything further, [resolveFluentColorAreaState],
/// [resolveFluentColorAreaStyle] and [buildFluentColorArea] are public so any
/// one of them can be replaced without forking this widget.
class FluentColorArea extends StatefulWidget {
  /// Creates a colour area.
  ///
  /// [color] and [onChanged] fall back to the enclosing [FluentColorPicker];
  /// at least one of the two sources must supply a colour.
  const FluentColorArea({
    super.key,
    required this.saturationLabel,
    required this.brightnessLabel,
    this.color,
    this.onChanged,
    this.shape,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.semanticFormatter,
  });

  /// Announced by assistive technology as the name of the horizontal axis.
  ///
  /// Required, not optional: a two-dimensional control that announces two bare
  /// percentages tells a screen-reader user nothing. Upstream's own stories set
  /// `aria-label` on both hidden inputs for the same reason.
  final String saturationLabel;

  /// Announced by assistive technology as the name of the vertical axis.
  final String brightnessLabel;

  /// The colour to show. Falls back to the enclosing picker's.
  final HSVColor? color;

  /// Called with the colour a gesture or a key landed on. Falls back to the
  /// enclosing picker's callback; null from both disables the area.
  final ValueChanged<HSVColor>? onChanged;

  /// The corner treatment. Falls back to the enclosing picker's, then rounded.
  final FluentColorPickerShape? shape;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentColorAreaStyle? style;

  /// Focus node to use. One is created internally when omitted.
  final FocusNode? focusNode;

  /// Whether to take focus on mount.
  final bool autofocus;

  /// Formats the announced value of one axis.
  ///
  /// Takes the whole colour, not one axis's number, because both of upstream's
  /// stories announce *both* channels plus a colour name from either axis —
  /// `Saturation 50, Brightness: 90, olivedrab`. Defaults to that axis's
  /// percentage.
  final String Function(HSVColor color, Axis axis)? semanticFormatter;

  @override
  State<FluentColorArea> createState() => _FluentColorAreaState();
}

class _FluentColorAreaState extends State<FluentColorArea> {
  /// One keyboard press of travel, as a fraction of the axis. Upstream's
  /// `deltaX / 100`.
  static const double _keyStep = 0.01;

  late HSVColor _color;
  ValueChanged<HSVColor>? _onChanged;
  late EdgeInsets _margin;

  bool get _enabled => _onChanged != null;

  FluentColorAreaBaseState get _base =>
      FluentColorAreaBaseState(color: _color, enabled: _enabled);

  String _format(HSVColor color, Axis axis) =>
      widget.semanticFormatter?.call(color, axis) ??
      ((axis == Axis.horizontal ? color.saturation : color.value) * 100)
          .round()
          .toString();

  void _report(HSVColor next) {
    if (next != _color) _onChanged!.call(next);
  }

  /// Turns a pointer position, local to the padded box, into a colour.
  ///
  /// The margin is part of this widget's box but not part of the square, so it
  /// comes off both the offset and the extent before normalising.
  void _reportAt(Offset local) {
    final box = context.size;
    if (box == null) return;
    final width = box.width - _margin.horizontal;
    final height = box.height - _margin.vertical;
    if (width <= 0 || height <= 0) return;

    var x = clampDouble((local.dx - _margin.left) / width, 0, 1);
    final y = clampDouble(1 - (local.dy - _margin.top) / height, 0, 1);
    if (Directionality.of(context) == TextDirection.rtl) x = 1 - x;
    _report(_base.colorAt(x, y));
  }

  void _adjust(_AdjustColorAreaIntent intent) {
    // Arrow keys are reading-order: on an RTL square the left arrow raises
    // saturation, because saturation 0 is on the right and the paint is
    // mirrored with it.
    final sign = Directionality.of(context) == TextDirection.rtl ? -1 : 1;
    _report(
      _base.colorAt(
        _color.saturation + sign * intent.dx * _keyStep,
        _color.value + intent.dy * _keyStep,
      ),
    );
  }

  /// One axis, as a slider node. Two of these sit over the square, which is
  /// upstream's pair of hidden range inputs.
  Widget _axis(Axis axis, String label) {
    final increased = axis == Axis.horizontal
        ? _base.colorAt(_color.saturation + _keyStep, _color.value)
        : _base.colorAt(_color.saturation, _color.value + _keyStep);
    final decreased = axis == Axis.horizontal
        ? _base.colorAt(_color.saturation - _keyStep, _color.value)
        : _base.colorAt(_color.saturation, _color.value - _keyStep);
    return Positioned.fill(
      child: Semantics(
        slider: true,
        enabled: _enabled,
        label: label,
        value: _format(_color, axis),
        increasedValue: _format(increased, axis),
        decreasedValue: _format(decreased, axis),
        onIncrease: _enabled ? () => _report(increased) : null,
        onDecrease: _enabled ? () => _report(decreased) : null,
        // A childless SizedBox has no `hitTestSelf` and no children, so it is
        // already invisible to the pointer and the surface underneath answers
        // every press. Deliberately NOT wrapped in an IgnorePointer: that sets
        // `blockUserActions` on the semantics node, which would leave both
        // axes announced and neither adjustable.
        child: const SizedBox.expand(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final scope = FluentColorPickerScope.maybeOf(context);
    assert(
      widget.color != null || scope != null,
      'FluentColorArea needs a colour: pass one, or put it inside a '
      'FluentColorPicker.',
    );

    _color = widget.color ?? scope?.color ?? kFluentColorPickerInitialColor;
    _onChanged = widget.onChanged ?? scope?.onColorChanged;
    final shape =
        widget.shape ?? scope?.shape ?? FluentColorPickerShape.rounded;

    final state = resolveFluentColorAreaState(
      color: _color,
      enabled: _enabled,
      shape: shape,
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentColorAreaStyle(
      state,
      theme,
    ).merge(FluentColorAreaTheme.maybeOf(context)).merge(widget.style);

    _margin =
        (resolved.margin?.resolve(const <WidgetState>{}) ?? EdgeInsets.zero)
            .resolve(Directionality.of(context));

    final Widget surface = Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.arrowLeft): _AdjustColorAreaIntent(
          -1,
          0,
        ),
        SingleActivator(LogicalKeyboardKey.arrowRight): _AdjustColorAreaIntent(
          1,
          0,
        ),
        SingleActivator(LogicalKeyboardKey.arrowUp): _AdjustColorAreaIntent(
          0,
          1,
        ),
        SingleActivator(LogicalKeyboardKey.arrowDown): _AdjustColorAreaIntent(
          0,
          -1,
        ),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _AdjustColorAreaIntent: CallbackAction<_AdjustColorAreaIntent>(
            onInvoke: (intent) {
              if (_enabled) _adjust(intent);
              return null;
            },
          ),
        },
        child: FluentInteractive(
          // FluentInteractive treats a null callback as disabled, and a colour
          // area has no activation gesture of its own — the eager pointer
          // capture below beats its tap recognizer anyway. The no-op is what
          // marks it enabled.
          onPressed: _enabled ? () {} : null,
          enabled: _enabled,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          mouseCursor:
              resolved.mouseCursor?.resolve(const <WidgetState>{}) ??
              SystemMouseCursors.basic,
          builder: (context, states, _) => FluentPointerCapture(
            enabled: _enabled,
            onPointer: _reportAt,
            // Moving the thumb re-records this subtree only, instead of every
            // paragraph on the page above it.
            child: RepaintBoundary(
              child: buildFluentColorArea(state, resolved, states),
            ),
          ),
        ),
      ),
    );

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Stack(
        // Passthrough, not the default loose: a Stack normally loosens the
        // constraints it hands its non-positioned child, which would drop a
        // square inside a tight 420 slot back to its own 300 minimum.
        fit: StackFit.passthrough,
        children: <Widget>[
          // Not Positioned: the Stack sizes to this child. With every child
          // positioned it would take `constraints.biggest`, which is infinite
          // height inside any scroll view — including the one every showroom
          // page is built from.
          //
          // ExcludeSemantics because FluentInteractive publishes a tap action
          // whenever it is enabled, which would put a third, spurious
          // activatable node beside the two axes.
          ExcludeSemantics(child: surface),
          _axis(Axis.horizontal, widget.saturationLabel),
          _axis(Axis.vertical, widget.brightnessLabel),
        ],
      ),
    );
  }
}
