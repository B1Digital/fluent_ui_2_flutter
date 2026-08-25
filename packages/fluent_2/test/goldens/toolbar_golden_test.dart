import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// One row per `Size`, static then floating — the whole six-variant Figma set,
/// plus a row showing a disabled item and the divider between groups.
void main() {
  Widget button(IconData icon, {bool enabled = true}) => FluentButton.icon(
    icon: Icon(icon, size: 20),
    semanticLabel: icon.toString(),
    appearance: FluentButtonAppearance.subtle,
    onPressed: enabled ? () {} : null,
  );

  Widget toolbar(FluentToolbarSize size, FluentToolbarType type) =>
      FluentToolbar(
        size: size,
        type: type,
        items: <Widget>[
          button(FluentIcons.text_bold_20_regular),
          button(FluentIcons.text_italic_20_regular),
          const FluentToolbarDivider(),
          button(FluentIcons.link_20_regular),
          button(FluentIcons.delete_20_regular, enabled: false),
        ],
      );

  goldenGridTest(
    'toolbar',
    () => goldenGrid(columns: 2, <Widget>[
      for (final size in FluentToolbarSize.values)
        for (final type in FluentToolbarType.values) toolbar(size, type),
    ]),
    surfaceSize: const Size(900, 700),
  );

  // Nothing on a toolbar animates, so the reduced-motion image must be the
  // ordinary one. A diff here means a transition crept in.
  goldenGridTest(
    'toolbar',
    () => goldenGrid(columns: 2, <Widget>[
      for (final size in FluentToolbarSize.values)
        for (final type in FluentToolbarType.values) toolbar(size, type),
    ]),
    surfaceSize: const Size(900, 700),
    reducedMotion: true,
    suffix: '.reduced_motion',
  );
}
