import 'package:flutter/widgets.dart';

import 'theme_variants.dart';
import 'widgets/preview_band.dart';

/// Everything the shell toolbar drives: Storybook's globals, one copy for the
/// whole app.
///
/// The docs toolbar's Theme dropdown and RTL switch write the same [variant]
/// and [textDirection] the toolbar does, both ways, and every value outlives
/// navigation — upstream's in-page ThemePicker and DirSwitch set the same
/// globals as the toolbar, and sidebar navigation keeps them (live
/// `sync.inpageTheme`, `sync.inpageDir`, `_tbfix_fc_nav.mjs`).
///
/// This sits *above* `FluentApp`, which is what makes it work. `FluentApp`'s own
/// `builder:` runs above the app's `Navigator`, and every overlay in
/// `fluent_2` resolves against that `Navigator`'s `Overlay` — so anything
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
    required this.strictMode,
    required this.sidebarVisible,
    required this.onVariantChanged,
    required this.onTextDirectionChanged,
    required this.onToggleGrid,
    required this.onBackgroundChanged,
    required this.onToggleOutlines,
    required this.onToggleStrictMode,
    required this.onToggleSidebar,
    required super.child,
  });

  /// The theme previews render in. The chrome ignores this — see `DocsMetrics`.
  final ThemeVariant variant;

  /// The direction previews render in.
  final TextDirection textDirection;

  /// Whether the backgrounds addon's grid is drawn in the preview band.
  final bool grid;

  /// The preview band's colour; null is upstream's default of none.
  final PreviewBackground? background;

  /// Whether every box in each story is outlined.
  final bool outlines;

  /// Upstream's "Toggle React Strict mode". React's dev-only double render has
  /// no Flutter counterpart; the one effect the live site shows — every story
  /// remounting on each toggle — is what previews do with it.
  final bool strictMode;

  /// Whether the sidebar is on screen.
  final bool sidebarVisible;

  /// Upstream's full screen, `!navShown && !panelShown` (`layout.ts:146-148`).
  /// The showroom has no addons panel, so it is the hidden sidebar and
  /// nothing else.
  bool get fullScreen => !sidebarVisible;

  /// Called by both Theme controls.
  final ValueChanged<ThemeVariant> onVariantChanged;

  /// Called by the Direction control and the RTL switch.
  final ValueChanged<TextDirection> onTextDirectionChanged;

  /// Toggles [grid].
  final VoidCallback onToggleGrid;

  /// Sets [background]. Null is "Reset background", which ALSO turns [grid]
  /// off: upstream resets the whole `backgrounds` global, grid included
  /// (`backgrounds/components/Tool.tsx:111`, `update(undefined)`).
  final ValueChanged<PreviewBackground?> onBackgroundChanged;

  /// Toggles [outlines].
  final VoidCallback onToggleOutlines;

  /// Toggles [strictMode].
  final VoidCallback onToggleStrictMode;

  /// Toggles [sidebarVisible], and so [fullScreen].
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
      oldWidget.strictMode != strictMode ||
      oldWidget.sidebarVisible != sidebarVisible;
}
