import 'package:flutter/painting.dart';

/// A [BoxDecoration] whose [boxShadow] paints the way CSS `box-shadow` does:
/// outside the box only.
///
/// [BoxDecoration] draws each shadow as a blurred, filled copy of the box
/// *under* the box. An opaque [color] hides that, which is why a menu or a card
/// never shows it. A transparent or translucent box does: light-theme
/// `shadow16` on a box with no fill washes its whole inside to about 76% of
/// whatever is behind it. Upstream writes `boxShadow: tokens.shadow16` on
/// elements with no background all the time, and the browser shows the page
/// through them untouched.
///
/// Use this wherever upstream shadows an element that has no opaque background.
/// Everything except the shadows is painted exactly as [BoxDecoration] paints
/// it. The shadows follow CSS rather than [BoxShadow.toPaint]:
///
///  * they are clipped to outside the decoration's shape, the border box;
///  * the blur's standard deviation is half of [BoxShadow.blurRadius], as the
///    CSS spec defines it, not [Shadow.convertRadiusToSigma]; and
///  * the first shadow in the list paints on top, as in CSS, where
///    [BoxDecoration] puts the last one on top.
///
/// [BoxShadow.spreadRadius] inflates the box without growing its corner radii,
/// as [BoxDecoration] does, whereas CSS grows them by the spread.
/// [BoxShadow.blurStyle] is ignored, because CSS has no equivalent.
class FluentBoxDecoration extends BoxDecoration {
  /// Creates a decoration whose shadows stay outside the box.
  const FluentBoxDecoration({
    super.color,
    super.image,
    super.border,
    super.borderRadius,
    super.boxShadow,
    super.gradient,
    super.backgroundBlendMode,
    super.shape,
  });

  // ponytail: copyWith and lerp are inherited and return a plain BoxDecoration,
  // so an AnimatedContainer tweening between two of these washes grey mid-way.
  // Override both once something animates one.

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _FluentBoxDecorationPainter(this, onChanged);
}

class _FluentBoxDecorationPainter extends BoxPainter {
  _FluentBoxDecorationPainter(this._decoration, VoidCallback? onChanged)
    : _body = BoxDecoration(
        color: _decoration.color,
        image: _decoration.image,
        border: _decoration.border,
        borderRadius: _decoration.borderRadius,
        gradient: _decoration.gradient,
        backgroundBlendMode: _decoration.backgroundBlendMode,
        shape: _decoration.shape,
      ).createBoxPainter(onChanged),
      super(onChanged);

  final FluentBoxDecoration _decoration;

  /// Paints everything in the decoration except the shadows.
  final BoxPainter _body;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final rect = offset & configuration.size!;
    final textDirection = configuration.textDirection ?? TextDirection.ltr;
    final shadows = _decoration.boxShadow ?? const <BoxShadow>[];
    if (shadows.isNotEmpty) {
      canvas.save();
      // An opaque fill hides whatever lies under it anyway, and a clip there
      // would only leave a lighter anti-aliased seam along the edge.
      final color = _decoration.color;
      final opaque =
          color != null &&
          color.a == 1 &&
          _decoration.gradient == null &&
          _decoration.backgroundBlendMode == null;
      if (!opaque) {
        // The clip only has to cover what the shadows can reach: each one's
        // offset, spread box plus three standard deviations of blur.
        var reach = rect;
        for (final shadow in shadows) {
          reach = reach.expandToInclude(
            rect
                .shift(shadow.offset)
                .inflate(shadow.spreadRadius + shadow.blurRadius * 1.5),
          );
        }
        canvas.clipPath(
          Path()
            ..fillType = PathFillType.evenOdd
            ..addRect(reach)
            ..addPath(_decoration.getClipPath(rect, textDirection), Offset.zero),
        );
      }
      // CSS paints the first shadow on top, so draw the list back to front.
      for (final shadow in shadows.reversed) {
        final paint = Paint()..color = shadow.color;
        if (shadow.blurRadius > 0) {
          paint.maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            shadow.blurRadius / 2,
          );
        }
        assert(() {
          // As in BoxShadow.toPaint: goldens get solid, version-proof shadows.
          if (debugDisableShadows) paint.maskFilter = null;
          return true;
        }());
        canvas.drawPath(
          _decoration.getClipPath(
            rect.shift(shadow.offset).inflate(shadow.spreadRadius),
            textDirection,
          ),
          paint,
        );
      }
      canvas.restore();
    }
    _body.paint(canvas, offset, configuration);
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }
}
