# fluent_2_web

Fluent 2 components for web and desktop surfaces. Built on
[`fluent_2_core`](../fluent_2_core), which it re-exports — one import gets you
components *and* tokens.

```yaml
dependencies:
  fluent_2_web: ^0.0.1
```

```dart
import 'package:fluent_2_web/fluent_2_web.dart';

void main() => runApp(
  FluentApp(
    theme: FluentThemeData.light(),
    darkTheme: FluentThemeData.dark(),
    home: const Home(),
  ),
);
```

## Scope

This package owns the **pointer** rendering of each component: web sizes and
densities, hover and focus affordances. `fluent_2_mobile` owns the touch
rendering of the same components. They are separate widgets — a web button and
a mobile button differ in more than a padding constant, so there is no shared
base class pretending otherwise.

Anything shared — tokens, `FluentTheme`, `FluentApp` — belongs in
`fluent_2_core`, never here.

## Status

No widgets yet. The package is wired into the workspace and re-exports core.

## Adding a component

```
lib/src/buttons/fluent_button.dart     one component per file
lib/fluent_2_web.dart                  export it here, alphabetically
```

Conventions, all of them enforced by `melos run ci`:

- **No Material.** Import `package:flutter/widgets.dart`. `melos run no-material`
  fails the build on `material.dart` or `cupertino.dart`.
- **No hardcoded values.** Every color, size, radius, duration and curve comes
  from a token: `FluentTheme.of(context).colors`, `FluentSpacing`,
  `FluentRadius`, `FluentDuration`, `FluentCurve`. A raw `Color(0xFF...)` or a
  bare `16` in a widget is a bug — if the token is missing, add it to core.
- **Document every public member.** `public_member_api_docs` is an *error* in
  the root `analysis_options.yaml`; undocumented public API does not compile in
  CI. Cite the Fluent spec on the class doc where a value is non-obvious.
- **`const` constructors.** Widgets take `const` constructors and `super`
  parameters; the lint set rejects the alternatives.
- **Accessibility is not optional.** Interactive components need a `Semantics`
  label, a keyboard focus path (`FocusableActionDetector`) and a visible focus
  indicator. This is the one area where "add it later" is not allowed.
- **A widget test per component.** Renders, responds to interaction, honours the
  theme. `melos run test`.
