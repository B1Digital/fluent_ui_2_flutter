# fluent_2_mobile

Fluent 2 components for iOS and Android surfaces. Built on
[`fluent_2_core`](../fluent_2_core), which it re-exports — one import gets you
components *and* tokens.

```yaml
dependencies:
  fluent_2_mobile: ^0.0.1
```

```dart
import 'package:fluent_2_mobile/fluent_2_mobile.dart';

void main() => runApp(
  FluentApp(
    theme: FluentThemeData.light(),
    darkTheme: FluentThemeData.dark(),
    home: const Home(),
  ),
);
```

## Scope

This package owns the **touch** rendering of each component: larger hit targets,
the mobile type ramp, press states. `fluent_2_web` owns the pointer rendering of
the same components. They are separate widgets by design.

Mobile token ramps live in `fluent_2_core`, transcribed from `fluentui-apple`
(`GlobalTokens.swift`) and `fluentui-android` (`FluentGlobalTokens.kt`). iOS and
Android share this package; where their specs diverge, branch on
`defaultTargetPlatform` inside the component rather than splitting the package.

## Status

No widgets yet. The package is wired into the workspace and re-exports core.

## Adding a component

Same conventions as [`fluent_2_web`](../fluent_2_web/README.md#adding-a-component):
no Material, no hardcoded values, documented public API, `const` constructors,
accessibility from the start, one widget test per component. Minimum touch
target is 44pt (iOS) / 48dp (Android).
