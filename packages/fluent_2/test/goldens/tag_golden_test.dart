import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Two grids, because the two components diverge exactly where a regression
/// would hide: the inert tag holds one fill across rest, hover and press, while
/// the interaction tag ramps both of its halves independently.
///
/// The cell order is the legend — the placeholder test font draws every glyph
/// as the same box, so captions would be noise.
void main() {
  goldenGridTest(
    'tag',
    () => goldenGrid(columns: 3, <Widget>[
      // Appearance × selected × disabled.
      for (final appearance in FluentTagAppearance.values)
        FluentTag(appearance: appearance, child: const Text('Tag')),
      for (final appearance in FluentTagAppearance.values)
        FluentTag(
          appearance: appearance,
          selected: true,
          child: const Text('Tag'),
        ),
      for (final appearance in FluentTagAppearance.values)
        FluentTag(
          appearance: appearance,
          enabled: false,
          child: const Text('Tag'),
        ),
      // The size ramp, each with the dismiss glyph that ramp also sizes.
      for (final size in FluentTagSize.values)
        FluentTag(size: size, onDismiss: () {}, child: const Text('Tag')),
      // Leading media, the two-line medium layout, and both at once.
      const FluentTag(icon: SizedBox.square(dimension: 20), child: Text('Tag')),
      const FluentTag(secondaryChild: Text('Second'), child: Text('Tag')),
      FluentTag(
        icon: const SizedBox.square(dimension: 20),
        secondaryChild: const Text('Second'),
        onDismiss: () {},
        child: const Text('Tag'),
      ),
    ]),
  );

  goldenGridTest(
    'interaction_tag',
    () => goldenGrid(columns: 3, <Widget>[
      for (final appearance in FluentTagAppearance.values)
        FluentInteractionTag(
          appearance: appearance,
          onPressed: () {},
          child: const Text('Tag'),
        ),
      for (final appearance in FluentTagAppearance.values)
        FluentInteractionTag(
          appearance: appearance,
          selected: true,
          onPressed: () {},
          child: const Text('Tag'),
        ),
      // Dismissible: the seam, the two radii and the fixed dismiss half.
      for (final appearance in FluentTagAppearance.values)
        FluentInteractionTag(
          appearance: appearance,
          onPressed: () {},
          onDismiss: () {},
          child: const Text('Tag'),
        ),
      for (final appearance in FluentTagAppearance.values)
        FluentInteractionTag(
          appearance: appearance,
          selected: true,
          onPressed: () {},
          onDismiss: () {},
          child: const Text('Tag'),
        ),
      // The size ramp, then disabled, then the two-line medium layout.
      for (final size in FluentTagSize.values)
        FluentInteractionTag(
          size: size,
          onPressed: () {},
          onDismiss: () {},
          child: const Text('Tag'),
        ),
      const FluentInteractionTag(child: Text('Tag')),
      const FluentInteractionTag(onDismiss: null, child: Text('Tag')),
      FluentInteractionTag(
        icon: const SizedBox.square(dimension: 20),
        secondaryChild: const Text('Second'),
        onPressed: () {},
        onDismiss: () {},
        child: const Text('Tag'),
      ),
    ]),
  );
}
