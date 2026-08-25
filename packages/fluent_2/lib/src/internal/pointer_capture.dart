import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Reports a pointer position in the captured surface's own coordinates.
///
/// Called once on pointer-down and again for every move until release,
/// including moves that leave the surface — see [FluentPointerCapture].
typedef FluentPointerCaptureCallback = void Function(Offset localPosition);

/// Claims a pointer at the instant it goes down and tracks it until release,
/// wherever it travels.
///
/// ## What upstream does
///
/// Fluent's colour controls set `touch-action: none` on the root and
/// `pointer-events: none` on every part inside it. The root is therefore the
/// *only* drag surface: `mousedown` moves the value to the click point with no
/// thumb hit-test anywhere, and a `mousemove` listener on the document keeps
/// the value tracking after the pointer has left the element
/// (`useColorArea.ts`, `handleRootOnMouseDown`).
///
/// ## Why this is not a [GestureDetector]
///
/// A drag recogniser does not claim its pointer until the movement exceeds the
/// slop — 18 logical pixels for touch, and **one** for a precise pointer. Until
/// then an ancestor `Scrollable`, or a `SelectableRegion`'s pan, is still in
/// the arena and can win. A colour area's Y axis *is* a vertical drag and its
/// own docs page is a vertical scrollable, so that race is not theoretical: it
/// is the shape of a bug this repository has already shipped once, and a
/// `tester.tap` suite stayed green throughout, because a synthesised tap is
/// perfectly still while a real mouse always drifts.
///
/// Two pieces of the framework solve it exactly, with no private API:
///
/// * [EagerGestureRecognizer] resolves `accepted` from
///   `addAllowedPointer`, so the arena is swept while the pointer-down event is
///   still being dispatched — before any slop can accumulate, and therefore
///   before any competitor can win. Every other member is rejected.
/// * [Listener] is not arena-mediated at all, so it sees every pointer event
///   regardless. `GestureBinding` caches the hit-test path at pointer-down and
///   dispatches subsequent moves along it, which is what makes moves *outside*
///   the surface keep arriving. That is the document `mousemove` listener, for
///   free, and for touch and stylus as well as mouse.
///
/// ## Limits, deliberately
///
/// * Only the primary button claims the arena, so a right-click still reaches
///   whatever is behind it. Upstream's `onMouseDown` fires for any button;
///   scrubbing a colour with the right button while a context menu opens is not
///   behaviour worth reproducing.
/// * [EagerGestureRecognizer] overrides `addAllowedPointer` and not
///   `addAllowedPointerPanZoom`, so a trackpad two-finger pan over the surface
///   is never claimed and still scrolls the page. This is not literally
///   `touch-action: none`, and it is the behaviour you want.
/// * A zero-size box never hit-tests, so it reports nothing. Callers still
///   guard their own division: the surface can shrink between down and move.
///
/// While [enabled] is false nothing is mounted at all — not a disabled
/// recogniser, *nothing*. A recogniser left in place would claim every
/// pointer-down inside the box and reject the ancestor scrollable, so a
/// disabled control would silently make the page unscrollable through its own
/// rectangle while every "disabled ignores input" test stayed green.
class FluentPointerCapture extends StatelessWidget {
  /// Captures pointers over [child] and reports them to [onPointer].
  const FluentPointerCapture({
    super.key,
    required this.onPointer,
    required this.child,
    this.enabled = true,
  });

  /// Called with the pointer's position, local to [child], on down and on every
  /// move until release.
  final FluentPointerCaptureCallback onPointer;

  /// Whether to capture at all. False mounts neither the recogniser nor the
  /// listener, so pointers pass through to whatever is behind.
  final bool enabled;

  /// The surface being captured.
  final Widget child;

  /// [Listener] is not arena-mediated, so it is not button-filtered either —
  /// `allowedButtonsFilter` gates only the *claim*. Without the same test here
  /// a right-drag would still scrub the value while the arena, correctly, left
  /// it alone.
  void _report(PointerEvent event) {
    if (event.buttons != kPrimaryButton) return;
    onPointer(event.localPosition);
  }

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: <Type, GestureRecognizerFactory<GestureRecognizer>>{
        EagerGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
              () => EagerGestureRecognizer(
                allowedButtonsFilter: (buttons) => buttons == kPrimaryButton,
              ),
              (instance) {},
            ),
      },
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _report,
        onPointerMove: _report,
        child: child,
      ),
    );
  }
}
