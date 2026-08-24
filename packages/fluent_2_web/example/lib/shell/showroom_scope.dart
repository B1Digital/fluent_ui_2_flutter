import 'package:flutter/widgets.dart';

import 'theme_variants.dart';

/// How wide the preview is allowed to be.
///
/// Upstream's "Change the size of the preview" — the small down-arrow between
/// the outline toggle and the theme menu.
enum PreviewViewport {
  /// No constraint; the preview fills the pane.
  responsive('Responsive', null),

  /// A phone.
  small('Small mobile', 360),

  /// A large phone.
  large('Large mobile', 414),

  /// A tablet.
  tablet('Tablet', 834);

  const PreviewViewport(this.label, this.width);

  /// The menu label.
  final String label;

  /// The cap, or null for responsive.
  final double? width;
}

/// Everything the shell toolbar drives, plus the theme and direction the docs
/// toolbar shares with it.
///
/// This sits *above* `FluentApp`, which is what makes it work. `FluentApp`'s own
/// `builder:` runs above the app's `Navigator`, and every overlay in
/// `fluent_2_web` resolves against that `Navigator`'s `Overlay` — so anything
/// placed in `builder:` cannot host story content, and anything placed inside a
/// route cannot be seen by a sibling route. An ancestor of the whole app is
/// visible to both, and survives navigation without a save/restore dance.
class ShowroomScope extends InheritedWidget {
  /// Provides shell state to [child].
  const ShowroomScope({
    super.key,
    required this.variant,
    required this.textDirection,
    required this.grid,
    required this.background,
    required this.outlines,
    required this.viewport,
    required this.locked,
    required this.fullScreen,
    required this.sidebarVisible,
    required this.onVariantChanged,
    required this.onTextDirectionChanged,
    required this.onToggleGrid,
    required this.onToggleBackground,
    required this.onToggleOutlines,
    required this.onViewportChanged,
    required this.onToggleLocked,
    required this.onToggleFullScreen,
    required this.onToggleSidebar,
    required super.child,
  });

  /// The theme previews render in. The chrome ignores this — see `DocsMetrics`.
  final ThemeVariant variant;

  /// The direction previews render in.
  final TextDirection textDirection;

  /// Whether a measuring grid is drawn behind previews.
  final bool grid;

  /// Whether previews paint the theme surface behind the story.
  final bool background;

  /// Whether previews outline their content boxes.
  final bool outlines;

  /// The preview width cap.
  final PreviewViewport viewport;

  /// Whether previews ignore pointer input.
  ///
  /// Upstream's button here toggles React strict mode, which has no Flutter
  /// counterpart. Freezing interaction is the nearest thing the control can
  /// honestly do: it lets a demo be inspected without being driven.
  final bool locked;

  /// Whether the chrome is hidden and only the content shows.
  final bool fullScreen;

  /// Whether the sidebar is on screen.
  final bool sidebarVisible;

  /// Called by the theme menu.
  final ValueChanged<ThemeVariant> onVariantChanged;

  /// Called by the direction menu.
  final ValueChanged<TextDirection> onTextDirectionChanged;

  /// Toggles [grid].
  final VoidCallback onToggleGrid;

  /// Toggles [background].
  final VoidCallback onToggleBackground;

  /// Toggles [outlines].
  final VoidCallback onToggleOutlines;

  /// Called by the viewport menu.
  final ValueChanged<PreviewViewport> onViewportChanged;

  /// Toggles [locked].
  final VoidCallback onToggleLocked;

  /// Toggles [fullScreen].
  final VoidCallback onToggleFullScreen;

  /// Toggles [sidebarVisible].
  final VoidCallback onToggleSidebar;

  /// The nearest scope. Asserts rather than returning null: there is exactly one
  /// of these, at the root, and a missing one is a wiring bug rather than a
  /// state a caller should handle.
  static ShowroomScope of(BuildContext context) {
    final ShowroomScope? scope = context
        .dependOnInheritedWidgetOfExactType<ShowroomScope>();
    assert(scope != null, 'No ShowroomScope above this widget');
    return scope!;
  }

  @override
  bool updateShouldNotify(ShowroomScope oldWidget) =>
      oldWidget.variant != variant ||
      oldWidget.textDirection != textDirection ||
      oldWidget.grid != grid ||
      oldWidget.background != background ||
      oldWidget.outlines != outlines ||
      oldWidget.viewport != viewport ||
      oldWidget.locked != locked ||
      oldWidget.fullScreen != fullScreen ||
      oldWidget.sidebarVisible != sidebarVisible;
}
