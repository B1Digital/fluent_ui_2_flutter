import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Two grids.
///
/// **info_label** — one row per size: plain, required, disabled. Glyphs are
/// placeholder boxes, so what this regresses is the seam between the two slots:
/// the trigger's box against the label's line box, the zero gap between them,
/// and the disabled foreground reaching both.
///
/// **info_button** — one row per size, one cell per Figma `State`. The states
/// are passed to `buildFluentInfoButton` directly rather than simulated, which
/// is the only way to get Pressed and Selected into a still image, and puts all
/// 15 variants of the `.Info button` set in one PNG per theme.
void main() {
  /// One trigger, rendered in an explicit interaction state.
  Widget trigger(FluentInfoButtonSize size, Set<WidgetState> states) => Builder(
    builder: (context) {
      final state = resolveFluentInfoButtonState(
        size: size,
        info: const Text('Info'),
      );
      return buildFluentInfoButton(
        state,
        resolveFluentInfoButtonStyle(state, FluentTheme.of(context)),
        states,
      );
    },
  );

  goldenGridTest(
    'info_label',
    () => goldenGrid(columns: 3, <Widget>[
      for (final size in FluentLabelSize.values)
        FluentInfoLabel(
          size: size,
          infoSemanticLabel: 'More information',
          info: const Text('Info'),
          child: const Text('Label'),
        ),
      for (final size in FluentLabelSize.values)
        FluentInfoLabel(
          size: size,
          required: true,
          weight: FluentLabelWeight.semibold,
          infoSemanticLabel: 'More information',
          info: const Text('Info'),
          child: const Text('Label'),
        ),
      for (final size in FluentLabelSize.values)
        FluentInfoLabel(
          size: size,
          disabled: true,
          infoSemanticLabel: 'More information',
          info: const Text('Info'),
          child: const Text('Label'),
        ),
    ]),
  );

  goldenGridTest(
    'info_button',
    () => goldenGrid(columns: 5, <Widget>[
      for (final size in FluentInfoButtonSize.values) ...<Widget>[
        trigger(size, const <WidgetState>{}),
        trigger(size, const <WidgetState>{WidgetState.hovered}),
        trigger(size, const <WidgetState>{WidgetState.pressed}),
        trigger(size, const <WidgetState>{WidgetState.selected}),
        trigger(size, const <WidgetState>{WidgetState.focused}),
      ],
      // The disabled ramp has no Figma variant; it is here so a regression in
      // the one state the design file does not draw is still visible.
      for (final size in FluentInfoButtonSize.values)
        trigger(size, const <WidgetState>{WidgetState.disabled}),
    ]),
  );
}
