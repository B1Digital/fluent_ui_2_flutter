import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// The panels are built through the recomposition contract rather than by
/// opening a `FluentDrawer`: the real widget puts an overlay drawer in an
/// `Overlay`, which paints outside the captured subtree, and it fills the whole
/// viewport. `buildFluentDrawer` renders the identical panel inline, which is
/// what the image is for.
///
/// Row one is the overlay drawer on each edge — shadowed, with the transparent
/// rule that only reads in high contrast. Row two is the inline drawer with and
/// without its `Neutral/Stroke/2` separator: flat, and visibly ruled.
///
/// Every cell is `small`; the size axis is width alone, and three 940-wide
/// panels would make an image nobody diffs.
void main() {
  const double cellHeight = 200;

  Widget panel({
    required FluentDrawerType type,
    required FluentDrawerPosition position,
    bool separator = false,
  }) => Builder(
    builder: (context) {
      final state = resolveFluentDrawerState(
        open: true,
        type: type,
        position: position,
        separator: separator,
        header: const <Widget>[Text('Header')],
        footer: const <Widget>[Text('Save'), Text('Cancel')],
        child: const Text('Body'),
      );
      return SizedBox(
        height: cellHeight,
        child: buildFluentDrawer(
          state,
          resolveFluentDrawerStyle(state, FluentTheme.of(context)),
          const <WidgetState>{},
        ),
      );
    },
  );

  goldenGridTest(
    'drawer',
    () => goldenGrid(<Widget>[
      panel(
        type: FluentDrawerType.overlay,
        position: FluentDrawerPosition.start,
      ),
      panel(type: FluentDrawerType.overlay, position: FluentDrawerPosition.end),
      panel(
        type: FluentDrawerType.inline,
        position: FluentDrawerPosition.start,
        separator: true,
      ),
      panel(
        type: FluentDrawerType.inline,
        position: FluentDrawerPosition.start,
      ),
    ], columns: 2),
  );
}
