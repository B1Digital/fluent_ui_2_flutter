import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// The surface is built through the recomposition contract rather than by
/// hovering a `FluentTooltip`: the real widget puts itself in an `Overlay`,
/// which paints outside the captured subtree. `buildFluentTooltip` renders the
/// identical surface inline, which is what the image is for.
///
/// Row per appearance, one cell per arrow direction. Final row: the same three
/// appearances without an arrow.
void main() {
  Widget surface(
    FluentTooltipAppearance appearance,
    FluentTooltipPosition position, {
    bool withArrow = true,
  }) => Builder(
    builder: (context) {
      final state = resolveFluentTooltipState(
        content: const Text('Tooltip'),
        appearance: appearance,
        position: position,
        withArrow: withArrow,
      );
      return buildFluentTooltip(
        state,
        resolveFluentTooltipStyle(state, FluentTheme.of(context)),
        const <WidgetState>{},
      );
    },
  );

  goldenGridTest(
    'tooltip',
    () => goldenGrid(<Widget>[
      for (final appearance in FluentTooltipAppearance.values)
        for (final position in FluentTooltipPosition.values)
          surface(appearance, position),
      for (final appearance in FluentTooltipAppearance.values)
        surface(appearance, FluentTooltipPosition.above, withArrow: false),
    ]),
  );
}
