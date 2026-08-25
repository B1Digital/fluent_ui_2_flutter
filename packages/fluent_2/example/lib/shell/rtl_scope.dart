import 'package:flutter/widgets.dart';

/// A [Directionality] that survives the hop into an [Overlay].
///
/// The docs toolbar's LTR/RTL switch has to reach everything a preview renders,
/// including the popovers, menus, dialogs, drawers and tooltips that render
/// into the app's overlay rather than in place.
///
/// Theme already crosses that boundary for free. Every overlay in
/// `fluent_2` calls `InheritedTheme.capture(from:, to:)` before inserting
/// its entry, and `FluentTheme extends InheritedTheme` with `wrap` implemented,
/// so the captured themes are rebuilt around the overlay child.
/// [Directionality] is *not* an [InheritedTheme] — it is a plain
/// [InheritedWidget] — so it is not captured, and an RTL preview would spawn an
/// LTR menu.
///
/// Wrapping it in something that *is* an [InheritedTheme] is the whole fix.
class RtlScope extends InheritedTheme {
  /// Wraps [child] in [textDirection], capturably.
  RtlScope({super.key, required this.textDirection, required Widget child})
    : super(
        child: Directionality(textDirection: textDirection, child: child),
      );

  /// The direction applied to [child] and to anything it pushes into an overlay.
  final TextDirection textDirection;

  @override
  bool updateShouldNotify(RtlScope oldWidget) =>
      oldWidget.textDirection != textDirection;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      RtlScope(textDirection: textDirection, child: child);
}
