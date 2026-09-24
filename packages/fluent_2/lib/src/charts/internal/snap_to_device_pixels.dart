import 'package:flutter/rendering.dart' show RenderProxyBox;
import 'package:flutter/widgets.dart';

/// Paints its child moved onto the nearest whole device pixel, leaving its
/// layout where it is.
///
/// Chromium paints a box's background and border, and a replaced `<svg>`'s
/// content, from its pixel-snapped origin — `round(x)`, `round(y)` in device
/// space — while text keeps its fractional pen position. Both legend swatch
/// kinds are such boxes (`shape.tsx:35`, `:38`), and so is the same `<Shape>`
/// svg a chart popover row draws (`ChartPopover.tsx:211-217`), so upstream
/// draws every swatch on whole pixels even when the text before it has left it
/// at a fraction. Measured in Chrome, a rect, a line bar, a stripe and five of
/// the svg shapes placed at x .19, .33, .5, .625 and .75 each ink exactly the
/// columns of the rounded x — and at `--force-device-scale-factor=2`, the
/// columns of `round(2x)`: the device grid, not the CSS one. The text beside
/// it stays put, keeping Chromium's fractional pitch.
///
/// ponytail: the offset is taken at paint time, so a move that does not
/// repaint this box — an ancestor repaint boundary shifted as a layer, such as
/// a fractional scroll — keeps the previous snap until the next paint, a
/// sub-pixel shift. Upgrade path, if that ever shows: snap in a layer that
/// re-reads its global offset on composite.
class SnapToDevicePixels extends SingleChildRenderObjectWidget {
  /// Snaps [child] to the device pixels of the nearest [MediaQuery].
  const SnapToDevicePixels({super.key, super.child});

  @override
  RenderSnapToDevicePixels createRenderObject(BuildContext context) =>
      RenderSnapToDevicePixels(
        MediaQuery.maybeDevicePixelRatioOf(context) ?? 1,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSnapToDevicePixels renderObject,
  ) => renderObject.devicePixelRatio =
      MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;
}

/// The render object behind [SnapToDevicePixels].
class RenderSnapToDevicePixels extends RenderProxyBox {
  /// Snaps to a grid of [devicePixelRatio] pixels per logical pixel.
  RenderSnapToDevicePixels(this._devicePixelRatio);

  double _devicePixelRatio;

  /// The device pixels per logical pixel.
  set devicePixelRatio(double value) {
    if (value == _devicePixelRatio) return;
    _devicePixelRatio = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    final device = localToGlobal(Offset.zero) * _devicePixelRatio;
    // Mapped back through this box's transform rather than added as a global
    // delta, so the origin still lands on the device grid under an ancestor
    // scale. A singular transform maps it to the origin: no snap.
    final snapped = globalToLocal(
      Offset(device.dx.roundToDouble(), device.dy.roundToDouble()) /
          _devicePixelRatio,
    );
    context.paintChild(child, offset + snapped);
  }
}
