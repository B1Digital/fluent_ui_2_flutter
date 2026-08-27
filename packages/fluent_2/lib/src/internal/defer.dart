import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Overlay bookkeeping that has to wait for the current build to finish.
///
/// Deliberately not exported: this is plumbing shared by the widgets that own
/// an [OverlayEntry], not part of the package's surface.
extension FluentDeferOverlay on State {
  /// Runs [action] now, unless a build is in flight.
  ///
  /// Inserting, removing or invalidating an [OverlayEntry] is a `setState` on
  /// the [Overlay], which sits in a different branch of the tree and has usually
  /// already been built by the time this widget rebuilds. Calling it straight
  /// from `didUpdateWidget`, `didChangeDependencies` or `build` therefore
  /// asserts.
  ///
  /// The deferred call is dropped if the widget is gone by the time the frame
  /// ends — the overlay it was going to touch has been torn down with it.
  void deferOrRun(VoidCallback action) {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) action();
      });
      return;
    }
    action();
  }
}
