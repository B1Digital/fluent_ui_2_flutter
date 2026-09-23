import 'package:flutter/widgets.dart';

/// The backgrounds addon's two options, in its menu order.
///
/// Fluent sets no `parameters.backgrounds`, so Storybook's defaults apply:
/// `light` #F8F8F8 and `dark` #333, lowercase labels, no "none" entry (no
/// choice at all is the default, and "Reset background" returns to it).
/// Source: `sbsrc/code/core/src/backgrounds/defaults.ts:3-6`; live popover
/// `bg.popover0` swatches.
enum PreviewBackground {
  /// `light`, #F8F8F8.
  light('light', Color(0xFFF8F8F8)),

  /// `dark`, #333.
  dark('dark', Color(0xFF333333));

  const PreviewBackground(this.label, this.color);

  /// The menu label, exactly as upstream spells it.
  final String label;

  /// The band's fill while chosen.
  final Color color;
}

/// The analogue of Storybook's `.docs-story` box: paints the chosen
/// [background] and, when [grid] is on, the backgrounds addon's grid, both
/// UNDER [child].
///
/// Upstream both are CSS on `#anchor--<id> .docs-story` (backgrounds
/// `decorator.ts:49-53` colour, `:70-89` grid, colour tag first per
/// `utils.ts:60-66`). The story's own wrapper is an opaque nb2 box, so the
/// colour and the lines only show in the band around it; the host supplies
/// that inset in [child].
///
/// The grid is four `linear-gradient` layers under `background-blend-mode:
/// difference`: 1px rgb(130,130,130) lines, minor at .25 alpha every 20px from
/// the band's top-left, major at .5 every 100px from 20px. CSS blends those
/// layers with each other and with the element's own background colour, but
/// NOT with the page behind (an isolated group), so the painter does the same
/// in a `saveLayer`. Measured upstream and reproduced here: over a white page
/// with no background minor 223-224, major 160; over `dark` minor 57-58,
/// major 65.
///
/// A new colour fades in over 0.3s with CSS's default `ease`
/// (`transition: background-color 0.3s`). Reset snaps, because upstream
/// deletes the style element that carries the transition, and so does reduced
/// motion, which drops the transition upstream.
///
/// The lines are 1 logical pixel wide, so the band must start on a whole
/// device pixel to stay sharp; at a half-pixel offset each line smears over
/// two lighter columns.
class PreviewBand extends StatelessWidget {
  /// Paints [background] and the optional [grid] behind [child].
  const PreviewBand({
    super.key,
    required this.grid,
    required this.background,
    required this.child,
  });

  /// Whether the addon's grid is on.
  final bool grid;

  /// The chosen background; null is upstream's default of none (transparent).
  final PreviewBackground? background;

  /// The story, inset by the band, painted on top.
  final Widget child;

  static const Color _none = Color(0x00000000);

  @override
  Widget build(BuildContext context) {
    final Color? target = background?.color;
    final bool snap =
        target == null ||
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    return TweenAnimationBuilder<Color?>(
      tween: _CssColorTween(end: target ?? _none),
      duration: snap ? Duration.zero : const Duration(milliseconds: 300),
      curve: Curves.ease,
      builder: (BuildContext context, Color? fill, Widget? child) =>
          CustomPaint(
            painter: _BandPainter(fill: fill ?? _none, grid: grid),
            child: child,
          ),
      child: child,
    );
  }
}

/// CSS interpolates colours premultiplied (css-color-4, "Interpolating with
/// Alpha"), so fading in from "no background" is the target colour gaining
/// alpha. `Color.lerp` from transparent black would dip through grey: none →
/// `light` reads about 210 over white at 150ms, a visible flash.
class _CssColorTween extends ColorTween {
  _CssColorTween({super.end});

  @override
  Color? lerp(double t) {
    final Color? from = begin;
    final Color? to = end;
    // ponytail: only a fully transparent start is premultiplied; a fade from
    // none interrupted mid-way lerps straight, off by a few units for under
    // 300ms. Lerp premultiplied channels for every pair if that ever shows.
    if (from != null && to != null && from.a == 0) {
      return Color.lerp(to.withAlpha(0), to, t);
    }
    return super.lerp(t);
  }
}

class _BandPainter extends CustomPainter {
  const _BandPainter({required this.fill, required this.grid});

  final Color fill;
  final bool grid;

  static const Color _minor = Color.fromRGBO(130, 130, 130, 0.25);
  static const Color _major = Color.fromRGBO(130, 130, 130, 0.5);

  @override
  void paint(Canvas canvas, Size size) {
    final Rect band = Offset.zero & size;
    if (grid) {
      canvas.saveLayer(band, Paint());
    }
    if (fill.a > 0) {
      canvas.drawRect(band, Paint()..color = fill);
    }
    if (grid) {
      // Bottom layer first: CSS lists the major lines first, so they are on
      // top. 1px rects, not drawLine: a 1px stroke centred on a whole x
      // covers half of two pixels.
      _lines(canvas, size, 0, 20, _minor);
      _lines(canvas, size, 20, 100, _major);
      canvas.restore();
    }
  }

  /// Vertical then horizontal 1px lines at [start] + k·[step], blended
  /// `difference` with everything already in the layer.
  static void _lines(
    Canvas canvas,
    Size size,
    double start,
    double step,
    Color color,
  ) {
    final Paint paint = Paint()
      ..color = color
      ..blendMode = BlendMode.difference;
    for (double x = start; x < size.width; x += step) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 1, size.height), paint);
    }
    for (double y = start; y < size.height; y += step) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), paint);
    }
  }

  @override
  bool shouldRepaint(_BandPainter oldDelegate) =>
      fill != oldDelegate.fill || grid != oldDelegate.grid;
}
