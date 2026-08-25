import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import '../buttons/button.dart';
import '../buttons/button_style.dart';
import '../internal/interaction.dart';

/// The button that opens and closes a nav.
///
/// Upstream's `Hamburger` is a `Button` and nothing more — `useHamburger.tsx`
/// is one call to `useButton_unstable` with `icon: <Navigation20Filled />` and
/// `appearance: 'transparent'`. It carries no toggle logic: the app owns
/// whether the nav is open, and in `Basic.stories.tsx` the same button appears
/// twice, once inside the drawer header to close and once in page content to
/// open.
///
/// ## Why the fill is restated rather than inherited
///
/// `useHamburgerStyles.styles.ts` sets `appearance: 'transparent'` and then
/// overrides the background straight back to `colorNeutralBackground4` /
/// `4Hover` / `4Pressed`, so the button vanishes into the nav surface. This
/// package's [FluentButtonAppearance.transparent] means something else — no
/// fill in any state, and a brand-tinted label on hover — so reproducing
/// upstream's end state means naming those three tokens here.
///
/// The consequence is worth knowing: this button reads as a filled chip on any
/// surface that is not the nav. Override [style] when placing one in page
/// content.
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

  /// Overrides layered over the nav fill. Merged last, so it wins.
  final FluentButtonStyle? style;

  /// Focus node to use. One is created internally when omitted.
  final FocusNode? focusNode;

  /// Whether to take focus on mount.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final c = FluentTheme.of(context).colors;

    // `navItemTokens` in `useHamburgerStyles.styles.ts`. Spelled out per state
    // rather than passed as a single colour, because the hover and pressed
    // members are what make the button track the nav rows beside it.
    final fill = FluentButtonStyle(
      backgroundColor: FluentStateColor.tokens(
        rest: c.neutralBackground4,
        hover: c.neutralBackground4Hover,
        pressed: c.neutralBackground4Pressed,
        disabled: c.neutralBackgroundDisabled,
      ),
    );

    final button = FluentButton.icon(
      icon: const Icon(FluentIcons.navigation_20_filled),
      semanticLabel: semanticLabel,
      onPressed: onPressed,
      appearance: FluentButtonAppearance.transparent,
      size: size ?? FluentButtonSize.medium,
      style: fill.merge(style),
      focusNode: focusNode,
      autofocus: autofocus,
    );

    if (expanded == null) return button;
    return Semantics(expanded: expanded, child: button);
  }
}
