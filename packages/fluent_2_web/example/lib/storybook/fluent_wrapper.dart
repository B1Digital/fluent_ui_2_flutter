import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

/// Custom `wrapperBuilder` for [storybook_flutter] that renders every story
/// inside a real Fluent app shell instead of the default Material one.
///
/// `storybook_flutter`'s own chrome (sidebar, bottom plugin bar, knob panel)
/// stays Material, but each *story* mounts under [FluentApp], giving it the
/// Fluent font, theme, a Navigator for overlays, and light/dark theming.
///
/// [FluentApp] defaults to `FluentThemeMode.system`, which resolves brightness
/// from `MediaQuery.platformBrightnessOf`. [storybook_flutter]'s
/// `ThemeModePlugin` overrides exactly that MediaQuery value, so the bundled
/// light/dark toggle drives the Fluent theme for free.
Widget fluentWrapper(BuildContext _, Widget? child) {
  return FluentApp(
    title: 'Fluent 2 Storybook',
    themeMode: FluentThemeMode.system,
    debugShowCheckedModeBanner: false,
    home: Builder(
      builder: (context) {
        final theme = FluentTheme.of(context);
        return ColoredBox(
          color: theme.colors.neutralBackground1,
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    ),
  );
}
