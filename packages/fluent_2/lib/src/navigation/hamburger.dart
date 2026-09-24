import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import '../buttons/button.dart';
import '../buttons/button_style.dart';

/// The button that opens and closes a nav.
///
/// Upstream's `Hamburger` is a `Button` and nothing more — `useHamburger.tsx`
/// is one call to `useButton_unstable` with `icon: <Navigation20Filled />` and
/// `appearance: 'transparent'`. It carries no toggle logic: the app owns
/// whether the nav is open, and in `Basic.stories.tsx` the same button appears
/// twice, once inside the drawer header to close and once in page content to
/// open.
///
/// ## Why there is no nav fill
///
/// `useHamburgerStyles.styles.ts` writes `navItemTokens.backgroundColor` /
/// `Hover` / `Pressed` onto the root, but merges them *before*
/// `state.root.className`, which already holds the transparent Button's own
/// classes — so in the rendered storybook the Button's `transparent` wins and
/// the fill never shows. The live `components-nav--basic` page measures
/// `rgba(0, 0, 0, 0)` at rest, on hover and on press; only the glyph moves,
/// `neutralForeground2` -> `neutralForeground2BrandHover` ->
/// `neutralForeground2BrandPressed`. That is exactly
/// [FluentButtonAppearance.transparent], so nothing is restated here.
///
/// ```dart
/// FluentHamburger(
///   onPressed: () => setState(() => open = !open),
///   expanded: open,
///   semanticLabel: open ? 'Collapse navigation' : 'Expand navigation',
/// )
/// ```
class FluentHamburger extends StatelessWidget {
  /// Creates a hamburger button.
  const FluentHamburger({
    super.key,
    required this.onPressed,
    required this.semanticLabel,
    this.expanded,
    this.size,
    this.style,
    this.focusNode,
    this.autofocus = false,
  });

  /// Invoked on tap and on Space or Enter.
  ///
  /// The button owns no state. Null disables it.
  final VoidCallback? onPressed;

  /// Announced by assistive technology.
  ///
  /// Upstream prescribes "Expand navigation" and "Collapse navigation".
  final String semanticLabel;

  /// Reported as `Semantics(expanded:)`, and only when non-null.
  ///
  /// Upstream's `Hamburger` sets no ARIA of its own. `NavAccessibility.md`
  /// puts `aria-expanded` on the consumer, and says it is needed for inline
  /// navs only — "this is not needed for overlay navs". Leaving this null is
  /// therefore the parity-correct default, not an omission.
  final bool? expanded;

  /// Height and glyph ramp. Null takes [FluentButton]'s own default.
  final FluentButtonSize? size;

  /// Overrides layered over the transparent button. Merged last, so it wins.
  final FluentButtonStyle? style;

  /// Focus node to use. One is created internally when omitted.
  final FocusNode? focusNode;

  /// Whether to take focus on mount.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final button = FluentButton.icon(
      icon: const Icon(FluentIcons.navigation_20_filled),
      semanticLabel: semanticLabel,
      onPressed: onPressed,
      appearance: FluentButtonAppearance.transparent,
      size: size ?? FluentButtonSize.medium,
      style: style,
      focusNode: focusNode,
      autofocus: autofocus,
    );

    if (expanded == null) return button;
    return Semantics(expanded: expanded, child: button);
  }
}
