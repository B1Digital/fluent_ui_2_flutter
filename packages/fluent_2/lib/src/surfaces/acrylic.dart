import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import 'acrylic_style.dart';

/// Where the hairline gradient starts, in the surface's own normalised box
/// space, and where it reaches its last stop.
///
/// Derived from the `gradientTransform` Figma stores on the Acrylic stroke,
/// recorded verbatim in `test/fixtures/acrylic.json`. Figma evaluates a linear
/// gradient in the node's normalised `[0,1]²` space, so its bands are
/// perpendicular to `(a, b)` **there** rather than on screen — which is why
/// these are unit-square coordinates fed through a scale matrix in
/// [FluentAcrylicStrokePainter.paint] rather than a plain `LinearGradient`,
/// whose `begin`/`end` alignments would make the bands perpendicular in
/// *device* space and skew the sheen on any non-square surface.
///
/// With `t(p) = a·pₓ + b·p_y + c` and `g = (a, b)`, the two ends are
/// `-c·g/|g|²` and `(1-c)·g/|g|²`.
const Offset _gradientFrom = Offset(0.057025630222199024, 0.046244683653122225);
const Offset _gradientTo = Offset(1.0354634671026226, 0.8397045378357835);

/// Stop 1 at 0, Stop 2 at the midpoint, Stop 3 at 1 — Figma's stop positions.
const List<double> _gradientStops = <double>[0, 0.5, 1];

/// Resolves the default acrylic style against [theme].
///
/// The first half of the recomposition contract, and the only place a token is
/// selected. Nothing here computes a colour: every value is a
/// `Material/Acrylic/*` token off `FluentColors.acrylic`, or — in high
/// contrast — a neutral token chosen for it.
///
/// ## High contrast is a real fallback, not a tint swap
///
/// Windows high contrast forbids translucency, and the acrylic tokens are not
/// merely wrong there, they are invisible: `Stroke/Stop 1` and `Stroke/Stop 3`
/// resolve to 20% black, which cannot be seen on the high contrast canvas.
/// Figma has no high contrast mode for the `Mode` collection to say otherwise,
/// so this port follows WinUI, which drops acrylic to a solid surface: no blur,
/// `neutralBackground1` for the fill and `neutralStroke1` for all three stops,
/// both of which resolve to opaque system colours. The Figma-vs-us difference
/// is recorded in `doc/token-divergences.md`.
///
/// The theme's palette identity is the signal — `MediaQuery.highContrastOf` is
/// the *platform* flag, and a caller who opts into
/// `FluentThemeData.highContrast` on a machine that has not is still asking for
/// a high contrast rendering.
FluentAcrylicSurfaceStyle resolveFluentAcrylicSurfaceStyle(
  FluentThemeData theme,
) {
  final c = theme.colors;
  final a = c.acrylic;
  final highContrast = c is FluentHighContrastColors;

  return FluentAcrylicSurfaceStyle.from(
    // Secondary sits on the blurred backdrop and Primary sits on Secondary.
    backgroundSecondary: highContrast
        ? c.neutralBackground1
        : a.backgroundSecondary,
    backgroundPrimary: highContrast
        ? c.transparentBackground
        : a.backgroundPrimary,
    // A RADIUS, halved into a sigma by the renderer. Zero here means "no
    // backdrop filter at all", not "a blur of nothing".
    backgroundBlur: highContrast ? 0 : a.backgroundBlur,
    strokeStop1: highContrast ? c.neutralStroke1 : a.strokeStop1,
    strokeStop2: highContrast ? c.neutralStroke1 : a.strokeStop2,
    strokeStop3: highContrast ? c.neutralStroke1 : a.strokeStop3,
    strokeWidth: FluentStroke.thin,
    // Figma binds the corners to the remote `material-radius` variable from the
    // MaterialShape collection; the shipped file resolves it to the None mode.
    // Pick another stop by overriding `borderRadius` on the style.
    borderRadius: BorderRadius.zero,
    padding: const EdgeInsets.all(FluentSpacing.l),
  );
}

/// Renders an acrylic surface from a resolved [style].
///
/// The second half of the recomposition contract. Takes only a style and an
/// interaction set, so a consumer can keep Fluent's rendering — the blur
/// arithmetic, the paint order, the gradient hairline — while supplying their
/// own tokens.
///
/// [states] is accepted because [FluentAcrylicSurfaceStyle] is
/// [WidgetStateProperty]-shaped like every other Fluent style. Acrylic itself
/// resolves the same in every state: Figma's `Material acrylic` set has one
/// variant and no State axis, so pass `const <WidgetState>{}` unless you are
/// deliberately driving the material from a parent control's states.
Widget buildFluentAcrylicSurface(
  FluentAcrylicSurfaceStyle style,
  Set<WidgetState> states, {
  Widget? child,
}) {
  final radius = style.borderRadius?.resolve(states) ?? BorderRadius.zero;
  final blur = style.backgroundBlur?.resolve(states) ?? 0;
  final strokeWidth = style.strokeWidth?.resolve(states) ?? FluentStroke.none;
  final padding = style.padding?.resolve(states) ?? EdgeInsets.zero;

  // Two translucent paints do not commute, so the nesting is the spec: Figma
  // paints `fills` in array order with the last on top, which puts Primary
  // over Secondary.
  Widget content = DecoratedBox(
    decoration: BoxDecoration(
      color: style.backgroundSecondary?.resolve(states),
      borderRadius: radius,
    ),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: style.backgroundPrimary?.resolve(states),
        borderRadius: radius,
      ),
      child: Padding(padding: padding, child: child),
    ),
  );

  content = CustomPaint(
    foregroundPainter: FluentAcrylicStrokePainter(
      stop1: style.strokeStop1?.resolve(states),
      stop2: style.strokeStop2?.resolve(states),
      stop3: style.strokeStop3?.resolve(states),
      borderRadius: radius,
      strokeWidth: strokeWidth,
    ),
    child: content,
  );

  if (blur > 0) {
    // `backgroundBlur` is a blur RADIUS, as Figma and CSS `filter: blur()`
    // state it. `ImageFilter.blur` takes a Gaussian sigma, and sigma is half
    // the radius — passing the token straight through doubles the blur.
    content = BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: blur / 2, sigmaY: blur / 2),
      child: content,
    );
  }

  // The clip is not decoration: a BackdropFilter samples everything behind it
  // and has to be bounded, and the corner radius has to cut the content too.
  return ClipRRect(borderRadius: radius, child: content);
}

/// Paints the acrylic hairline: a three-stop linear gradient stroked inside the
/// surface's own corner radius.
///
/// A painter rather than `BoxDecoration.border`, which takes a single [Color]
/// per side and so cannot express Figma's gradient stroke at all.
///
/// Every input is a public field so tests can assert the three tones and the
/// width directly instead of diffing pixels.
class FluentAcrylicStrokePainter extends CustomPainter {
  /// Creates a painter for the given stops, radius and width.
  const FluentAcrylicStrokePainter({
    required this.stop1,
    required this.stop2,
    required this.stop3,
    required this.borderRadius,
    this.strokeWidth = FluentStroke.thin,
  });

  /// Gradient position 0. `Material/Acrylic/Stroke/Stop 1`.
  final Color? stop1;

  /// Gradient position 0.5. `Material/Acrylic/Stroke/Stop 2`.
  final Color? stop2;

  /// Gradient position 1. `Material/Acrylic/Stroke/Stop 3`.
  final Color? stop3;

  /// The surface's corner radius. The stroke is concentric with it.
  final BorderRadius borderRadius;

  /// Hairline width. [FluentStroke.thin] per Figma's `Stroke width/Thin`
  /// binding; [FluentStroke.none] paints nothing.
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final one = stop1;
    final two = stop2;
    final three = stop3;
    if (strokeWidth <= 0 || one == null || two == null || three == null) return;

    final rect = Offset.zero & size;
    // Figma aligns this stroke INSIDE, and a stroke is centred on its path, so
    // the path is the box deflated by half the width.
    canvas.drawRRect(
      borderRadius.toRRect(rect.deflate(strokeWidth / 2)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..shader = ui.Gradient.linear(
          _gradientFrom,
          _gradientTo,
          <Color>[one, two, three],
          _gradientStops,
          TileMode.clamp,
          // Maps the unit square the gradient is defined in onto the surface,
          // which is what makes the bands land where Figma puts them rather
          // than where a device-space gradient would.
          Float64List.fromList(<double>[
            size.width, 0, 0, 0, //
            0, size.height, 0, 0, //
            0, 0, 1, 0, //
            0, 0, 0, 1,
          ]),
        ),
    );
  }

  @override
  bool shouldRepaint(FluentAcrylicStrokePainter oldDelegate) =>
      oldDelegate.stop1 != stop1 ||
      oldDelegate.stop2 != stop2 ||
      oldDelegate.stop3 != stop3 ||
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.strokeWidth != strokeWidth;
}

/// Overrides the acrylic style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`.
class FluentAcrylicSurfaceTheme extends InheritedTheme {
  /// Applies [style] to every `FluentAcrylicSurface` in [child].
  const FluentAcrylicSurfaceTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the theme defaults.
  final FluentAcrylicSurfaceStyle style;

  /// The nearest acrylic style, or null.
  static FluentAcrylicSurfaceStyle? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FluentAcrylicSurfaceTheme>()
      ?.style;

  @override
  bool updateShouldNotify(FluentAcrylicSurfaceTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentAcrylicSurfaceTheme(style: style, child: child);
}

/// The Fluent 2 Acrylic material: a blurred backdrop under two translucent
/// tints, edged with a gradient hairline.
///
/// ```dart
/// FluentAcrylicSurface(
///   style: FluentAcrylicSurfaceStyle.from(
///     borderRadius: FluentRadius.allXLarge,
///   ),
///   child: const Text('Behind me, the world is out of focus'),
/// )
/// ```
///
/// Named `FluentAcrylicSurface` rather than `FluentAcrylic` because
/// `FluentAcrylic` is already the *token* class in `fluent_2_core`, which this
/// widget reads through `FluentColors.acrylic`.
///
/// ## Not a control
///
/// A material has no interaction states. There is no `onPressed`, no focus
/// node, no hover or pressed token, and therefore no disabled state to model —
/// disabling a surface is the job of whatever control is placed on it. Pointer
/// events pass straight through to the content.
///
/// It also has no transition. Figma specifies none for the material and
/// upstream ships no acrylic component at all, so a change of theme or style
/// lands on the next frame — the same deliberate instantaneity `FluentMotionSpec`
/// documents for Checkbox and Tooltip.
///
/// ## Cost
///
/// [BackdropFilter] forces a `saveLayer` over everything behind the surface,
/// which is why the blur is dropped rather than set to zero when a style asks
/// for none. Prefer one large acrylic surface to many small ones.
///
/// Customisation follows the usual three rungs. [style] is merged last and
/// wins; [FluentAcrylicSurfaceTheme] restyles a subtree; and for anything
/// further, [resolveFluentAcrylicSurfaceStyle] and [buildFluentAcrylicSurface]
/// are public so either can be replaced without forking this widget.
class FluentAcrylicSurface extends StatelessWidget {
  /// Creates an acrylic surface around an optional [child].
  const FluentAcrylicSurface({super.key, this.child, this.style});

  /// The content, inset by the style's padding and painted over both tints.
  final Widget? child;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentAcrylicSurfaceStyle? style;

  @override
  Widget build(BuildContext context) {
    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentAcrylicSurfaceStyle(
      FluentTheme.of(context),
    ).merge(FluentAcrylicSurfaceTheme.maybeOf(context)).merge(style);

    return buildFluentAcrylicSurface(
      resolved,
      const <WidgetState>{},
      child: child,
    );
  }
}
