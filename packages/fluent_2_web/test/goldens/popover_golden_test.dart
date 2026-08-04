import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// The surface is built through the recomposition contract rather than by
/// opening a `FluentPopover`: the real widget puts itself in an `Overlay`,
/// which paints outside the captured subtree. `buildFluentPopover` renders the
/// identical surface inline, which is what the image is for.
///
/// Rows one to three: appearance by arrow direction. Row four: the same three
/// appearances with no arrow. Row five: the size ramp. Row six: the three
/// alignments, which is where the arrow moves along the edge.
void main() {
  Widget surface({
    FluentPopoverAppearance appearance = FluentPopoverAppearance.normal,
    FluentPopoverSize size = FluentPopoverSize.medium,
    FluentPopoverPosition position = FluentPopoverPosition.above,
    FluentPopoverAlign align = FluentPopoverAlign.center,
    bool withArrow = true,
  }) => Builder(
    builder: (context) {
      final state = resolveFluentPopoverState(
        content: const SizedBox(width: 120, child: Text('Popover')),
        appearance: appearance,
        size: size,
        position: position,
        align: align,
        withArrow: withArrow,
      );
      return buildFluentPopover(
        state,
        resolveFluentPopoverStyle(state, FluentTheme.of(context)),
        const <WidgetState>{},
      );
    },
  );

  goldenGridTest(
    'popover',
    () => goldenGrid(<Widget>[
      for (final appearance in FluentPopoverAppearance.values)
        for (final position in FluentPopoverPosition.values)
          surface(appearance: appearance, position: position),
      for (final appearance in FluentPopoverAppearance.values)
        surface(appearance: appearance, withArrow: false),
      const SizedBox.shrink(),
      for (final size in FluentPopoverSize.values) surface(size: size),
      const SizedBox.shrink(),
      for (final align in FluentPopoverAlign.values) surface(align: align),
      const SizedBox.shrink(),
    ]),
  );
}
