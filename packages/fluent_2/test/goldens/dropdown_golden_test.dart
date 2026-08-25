import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// The trigger grid is `Appearance` x `Size`; the popup is captured separately
/// because an open dropdown lives in the [Overlay], which sits above the
/// RepaintBoundary these images are cropped to. Rendering the surface through
/// its own builder captures the same pixels without an overlay.
void main() {
  Widget trigger(
    FluentDropdownAppearance appearance,
    FluentDropdownSize size, {
    String? value,
  }) => SizedBox(
    width: 200,
    child: FluentDropdown<String>(
      appearance: appearance,
      size: size,
      value: value,
      placeholder: const Text('Select'),
      options: const <FluentDropdownOption<String>>[
        FluentDropdownOption<String>(value: 'osl', label: Text('Oslo')),
      ],
      onChanged: (_) {},
    ),
  );

  goldenGridTest(
    'dropdown',
    () => goldenGrid(<Widget>[
      for (final appearance in FluentDropdownAppearance.values)
        for (final size in FluentDropdownSize.values) trigger(appearance, size),
      trigger(
        FluentDropdownAppearance.outline,
        FluentDropdownSize.medium,
        value: 'osl',
      ),
      // Disabled is a real state, not a treatment: it swaps the whole ramp.
      const SizedBox(
        width: 200,
        child: FluentDropdown<String>(
          placeholder: Text('Select'),
          options: <FluentDropdownOption<String>>[],
        ),
      ),
    ], columns: 3),
  );

  goldenGridTest(
    'dropdown',
    suffix: '.list',
    () => Builder(
      builder: (context) {
        final theme = FluentTheme.of(context);
        final style = resolveFluentDropdownStyle(
          resolveFluentDropdownState(),
          theme,
        );

        Widget row(
          String label, {
          bool selected = false,
          bool enabled = true,
          Set<WidgetState> states = const <WidgetState>{},
          FluentDropdownOptionType type = FluentDropdownOptionType.singleSelect,
        }) {
          final state = resolveFluentDropdownOptionState(
            label: Text(label),
            selected: selected,
            enabled: enabled,
            type: type,
          );
          return buildFluentDropdownOption(
            state,
            resolveFluentDropdownOptionStyle(state, theme),
            states,
          );
        }

        return SizedBox(
          width: 240,
          child: buildFluentDropdownSurface(
            style,
            const <WidgetState>{},
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: style.surfaceGap!.resolve(const <WidgetState>{})!,
              children: <Widget>[
                row('Header', type: FluentDropdownOptionType.header),
                row('Rest'),
                row('Selected', selected: true),
                row(
                  'Hovered',
                  states: const <WidgetState>{WidgetState.hovered},
                ),
                row(
                  'Pressed',
                  states: const <WidgetState>{WidgetState.pressed},
                ),
                row('Active', states: const <WidgetState>{WidgetState.focused}),
                row('Disabled', enabled: false),
              ],
            ),
          ),
        );
      },
    ),
  );
}
