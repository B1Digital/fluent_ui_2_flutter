import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

/// Draws Fluent's keyboard focus ring around [child] without affecting layout.
///
/// ## One ring
///
/// React v9 draws exactly one: `react-tabster`'s `createFocusOutlineStyle`
/// emits a single `::after` pseudo-element, 2px solid `colorStrokeFocus2` at
/// offset -2px, and never references `colorStrokeFocus1` at all. Probing
/// `storybooks.fluentui.dev` confirms it on every component that has a ring —
/// Checkbox, Radio, Switch, Slider, Accordion and InfoButton all resolve to
/// `border: 2px solid` `strokeFocus2` at `inset: -2px`, and Tab to the same
/// 2px ring expressed as a spread shadow.
///
/// Figma is **not** uniform, which is why this file used to claim otherwise:
/// `tab`, `vertical_tab` and `list_item` carry a single `Neutral/Stroke/Focus/2`
/// stroke, while `checkbox`, `radio`, `switch`, `slider`, `breadcrumb`,
/// `dropdown_option` and `info_button` add a second `Focus/1` stroke inside it.
/// So Figma and React agree on one ring for the first group and disagree for the
/// second; this port follows React throughout, and [FluentFocusRing.twoTone]
/// keeps Figma's double ring reachable.
///
/// The tones are inverses — `strokeFocus1` is white on light and black on dark,
/// `strokeFocus2` the reverse — so the second ring exists upstream to survive an
/// unknown backdrop. Dropping it is safe here only because `strokeFocus2` is
/// resolved from the theme, and high contrast substitutes a system colour.
///
/// ## No animation
///
/// Upstream has no transition on focus, so neither does this: the ring appears
/// on the frame focus arrives. That also makes it trivially correct under
/// `MediaQuery.disableAnimationsOf` — there is no animation to shorten.
class FluentFocusRing extends StatelessWidget {
  /// Draws React v9's ring: 2px `strokeFocus2` outside, nothing inside.
  const FluentFocusRing({
    super.key,
    required this.visible,
    required this.child,
    this.borderRadius = FluentRadius.allMedium,
  }) : innerWidth = FluentStroke.none;

  /// Draws Figma's two-tone ring: 2px `strokeFocus2` outside, 1px
  /// `strokeFocus1` inside.
  ///
  /// For a component sitting on a backdrop that `strokeFocus2` alone cannot be
  /// trusted to contrast with, and for anyone deliberately matching Figma.
  const FluentFocusRing.twoTone({
    super.key,
    required this.visible,
    required this.child,
    this.borderRadius = FluentRadius.allMedium,
  }) : innerWidth = FluentStroke.thin;

  /// Whether the ring is drawn.
  ///
  /// Drive this from `WidgetState.focused`, which means *keyboard-visible*
  /// focus. Focus arriving by pointer must not raise a ring on any Fluent
  /// platform.
  final bool visible;

  /// The component's own corner radius. Both rings are drawn concentric to it.
  ///
  /// Defaults to [FluentRadius.allMedium], matching React's hard-coded
  /// `borderRadiusMedium`.
  final BorderRadius borderRadius;

  /// The component the ring surrounds. Never repositioned or resized.
  final Widget child;

  /// Width of the inner ring: [FluentStroke.none], or [FluentStroke.thin] for
  /// [FluentFocusRing.twoTone].
  final double innerWidth;

  @override
  Widget build(BuildContext context) {
    final colors = FluentTheme.of(context).colors;
    // The painter is always attached, even while invisible, so that gaining
    // focus repaints rather than rebuilding the child's element subtree.
    return CustomPaint(
      foregroundPainter: FluentFocusRingPainter(
        visible: visible,
        outer: colors.strokeFocus2,
        inner: colors.strokeFocus1,
        borderRadius: borderRadius,
        innerWidth: innerWidth,
      ),
      child: child,
    );
  }
}

/// Paints [FluentFocusRing]'s two rings.
///
/// A foreground painter rather than nested [DecoratedBox]es for two reasons: a
/// ring must not change the component's size, and the outer ring has to paint
/// *outside* the child's bounds, which a decoration cannot do.
///
/// Every input is a public field so tests can assert the tones and widths
/// directly instead of diffing pixels.
class FluentFocusRingPainter extends CustomPainter {
  /// Creates a painter for the given tones and widths.
  const FluentFocusRingPainter({
    required this.visible,
    required this.outer,
    required this.inner,
    required this.borderRadius,
    this.outerWidth = FluentStroke.thick,
    this.innerWidth = FluentStroke.none,
  });

  /// Whether anything is painted at all.
  final bool visible;

  /// Outer ring colour. `strokeFocus2` — never derived from [inner].
  final Color outer;

  /// Inner ring colour. `strokeFocus1` — never derived from [outer].
  final Color inner;

  /// The component's corner radius, before the per-ring adjustment.
  final BorderRadius borderRadius;

  /// Outer ring width. [FluentStroke.thick] (2) per Figma and React alike.
  final double outerWidth;

  /// Inner ring width. [FluentStroke.none] (0), or [FluentStroke.thin] (1) for
  /// Figma's second tone.
  final double innerWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (!visible) return;
    final rect = Offset.zero & size;

    // A stroke is centred on its path, so strokeAlign OUTSIDE for a width-w
    // stroke is the same path inflated by w/2, and INSIDE is deflated by w/2.
    // The radii shift by the same delta, which is what keeps the two arcs
    // concentric instead of merely nested — so a width-w ring around a radius-r
    // component has an OUTER corner radius of r + w.
    //
    // That matches the `box-shadow: 0 0 0 2px` idiom Tab and Button use, where
    // CSS grows the shadow's corner radius by the spread. Components on
    // `createFocusOutlineStyle` instead get a `::after` box at inset -2px
    // carrying a flat `border-radius: 4px`, i.e. an outer radius of 4 whatever
    // the component's own is; pass [borderRadius] two smaller to hit it.
    _ring(canvas, rect, outer, outerWidth, outerWidth / 2);
    _ring(canvas, rect, inner, innerWidth, -innerWidth / 2);
  }

  void _ring(
    Canvas canvas,
    Rect rect,
    Color color,
    double width,
    double delta,
  ) {
    if (width <= 0) return;
    canvas.drawRRect(
      _shift(borderRadius, delta).toRRect(rect.inflate(delta)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = color,
    );
  }

  static BorderRadius _shift(BorderRadius radius, double delta) =>
      BorderRadius.only(
        topLeft: _shiftCorner(radius.topLeft, delta),
        topRight: _shiftCorner(radius.topRight, delta),
        bottomLeft: _shiftCorner(radius.bottomLeft, delta),
        bottomRight: _shiftCorner(radius.bottomRight, delta),
      );

  // Clamped at zero: a square corner stays square when the inner ring pulls the
  // radius below zero, rather than inverting the arc.
  static Radius _shiftCorner(Radius radius, double delta) => Radius.elliptical(
    math.max(0, radius.x + delta),
    math.max(0, radius.y + delta),
  );

  @override
  bool shouldRepaint(FluentFocusRingPainter oldDelegate) =>
      oldDelegate.visible != visible ||
      oldDelegate.outer != outer ||
      oldDelegate.inner != inner ||
      oldDelegate.outerWidth != outerWidth ||
      oldDelegate.innerWidth != innerWidth ||
      oldDelegate.borderRadius != borderRadius;
}
