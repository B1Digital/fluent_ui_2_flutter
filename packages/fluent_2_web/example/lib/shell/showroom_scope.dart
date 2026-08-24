import 'package:flutter/widgets.dart';

import 'theme_variants.dart';

/// The toolbar state every docs page reads: which theme variant previews render
/// in, and which way round they run.
///
/// This sits *above* `FluentApp`, which is what makes it work. `FluentApp`'s own
/// `builder:` runs above the app's `Navigator`, and every overlay in
/// `fluent_2_web` resolves against that `Navigator`'s `Overlay` — so anything
/// placed in `builder:` cannot host story content, and anything placed inside a
/// route cannot be seen by a sibling route. An ancestor of the whole app is
/// visible to both, and survives navigation without a save/restore dance.
class ShowroomScope extends InheritedWidget {
  /// Provides toolbar state to [child].
  const ShowroomScope({
    super.key,
    required this.variant,
    required this.textDirection,
    required this.onVariantChanged,
    required this.onTextDirectionChanged,
    required super.child,
  });

  /// The theme previews render in. The chrome ignores this — see
  /// `DocsMetrics`.
  final ThemeVariant variant;

  /// The direction previews render in.
  final TextDirection textDirection;

  /// Called by the toolbar's Theme dropdown.
  final ValueChanged<ThemeVariant> onVariantChanged;

  /// Called by the toolbar's LTR/RTL switch.
  final ValueChanged<TextDirection> onTextDirectionChanged;

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
      oldWidget.variant != variant || oldWidget.textDirection != textDirection;
}
