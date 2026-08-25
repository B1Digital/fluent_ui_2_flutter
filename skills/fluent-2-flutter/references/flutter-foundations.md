# Flutter foundations

## Contents

- Select the package
- Start an app
- Apply themes and tokens
- Compose controls
- Handle platform differences
- Test and validate
- Avoid common failures

## Select the package

| Need | Package |
| --- | --- |
| Themes, tokens, icons, typography, motion, or custom Fluent widgets | `fluent_2_core` |
| Web or desktop components with pointer, hover, focus, and compact density | `fluent_2` |

`fluent_2` re-exports core. Import it unless implementing a shared token-only
layer.

There is no separate mobile package. If a touch-oriented component is missing,
report the gap and either scope the work to web/desktop or compose from core and
raw Flutter primitives with explicit tests.

## Start an app

Official Fluent provider source:
https://fluent2.microsoft.design/components/web/react/core/fluentprovider/usage/

The web Fluent provider defines styles for an entire experience or overrides a
subtree. In this Flutter repository, `FluentApp` supplies the app-wide theme,
`FluentTheme` exposes it, and `FluentThemeOverride` applies a scoped override.
Keep one coherent semantic theme at the root and restrict subtree overrides to
deliberate embedded surfaces or brand/product contexts. Never hardcode values
inside a subtree merely to imitate provider behavior.

Use the Fluent app shell and themes:

```dart
import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

void main() {
  runApp(
    FluentApp(
      theme: FluentThemeData.light(),
      darkTheme: FluentThemeData.dark(),
      home: const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: Text('Fluent 2')),
      ),
    ),
  );
}
```

Inspect `FluentApp` before adding routing, localization, shortcuts, or navigator
configuration. Do not assume `MaterialApp` parameters exist.

## Apply themes and tokens

Read semantic values at build time:

```dart
Widget buildSurface(BuildContext context, Widget child) {
  final theme = FluentTheme.of(context);
  return DecoratedBox(
    decoration: BoxDecoration(
      color: theme.colors.neutralBackground1,
      borderRadius: FluentRadius.allMedium,
    ),
    child: DefaultTextStyle(
      style: theme.typography.body1.copyWith(
        color: theme.colors.neutralForeground1,
      ),
      child: child,
    ),
  );
}
```

Use `FluentThemeOverride` for a subtree-level semantic change. Inspect its
current constructor because override support can evolve independently from
`FluentThemeData`.

## Compose controls

Prefer the shipped widget when the coverage matrix marks it implemented:

```dart
FluentButton(
  appearance: FluentButtonAppearance.primary,
  onPressed: save,
  child: const Text('Save'),
)
```

Keep labels outside placeholders and pair a control with `FluentField` when it
needs a visible label, help text, or validation message:

```dart
const FluentField(
  label: Text('Display name'),
  child: FluentInput(
    placeholder: Text('Ada Lovelace'),
    semanticLabel: 'Display name',
  ),
)
```

For controlled overlays, own the open state and pass it back through the
component callback. Restore focus to the trigger when the component does not do
so automatically. Copy patterns from the corresponding gallery story instead
of guessing callback names.

### Own the state of every control

Every Fluent selection control is controlled-only. There is no `defaultChecked`
or `defaultValue`, and no uncontrolled mode to fall back on. The control renders
exactly the value passed to it and reports intent through its callback; it never
changes itself.

`FluentCheckbox`, `FluentSwitch`, `FluentRadio`, and `FluentRadioGroup` are
`StatelessWidget`, so this is structural rather than a convention. `FluentSlider`
and `FluentRating` are stateful, but only for hover and drag visuals — both read
`widget.value` and route every change through `onChanged`.

This is the most common porting mistake from React, where the same components
work uncontrolled by default. Wiring the callback but not storing the result
leaves a control that reports every tap and never moves:

```dart
// Wrong: onChanged fires, the checkbox never changes.
FluentCheckbox(checked: false, onChanged: (value) => report(value))

// Right: hold the value, pass it back down, rebuild.
// `checked` is `bool?` and `onChanged` is `ValueChanged<bool?>?`, so the
// field is nullable too — the third state is indeterminate, not "unset".
bool? _accepted;
FluentCheckbox(
  checked: _accepted,
  onChanged: (value) => setState(() => _accepted = value),
)
```

A control that looks frozen in a running app is this, not a styling bug.

## Handle platform differences

Check input capabilities and `defaultTargetPlatform` independently. A desktop
window can be narrow, and a web app can run on touch hardware.

- Web/desktop: preserve hover, secondary click where specified, keyboard
  traversal, visible focus, and compact density.
- iOS: use at least 44x44 targets, native back/navigation expectations, and
  platform text behavior.
- Android: use at least 48x48 targets, native back behavior, and Android
  accessibility expectations.
- Adaptive: share semantic state and data; allow separate renderers where
  geometry and behavior differ materially.

Do not import a nonexistent mobile component just because the official iOS or
Android Fluent library documents one.

## Test and validate

For each changed component, cover the applicable matrix:

| Area | Minimum checks |
| --- | --- |
| Rendering | light, dark, high contrast, disabled, selected/error/loading states |
| Input | pointer, keyboard, touch, Escape/back, RTL directional keys |
| Accessibility | semantic role/name/value/state, focus order, focus restoration |
| Layout | narrow width, large text, long localization, overflow |
| Motion | normal timing and disabled animations |
| API | constructor compiles against the current barrel |

In this repository, run:

```bash
dart format --set-exit-if-changed .
dart analyze --fatal-infos
flutter test
```

Prefer the repository-level `melos run ci` after targeted checks pass.

## Avoid common failures

- Do not use `Theme.of`, `Scaffold`, `InkWell`, `TextField`, or `Icons.*` in a
  package that forbids Material.
- Do not substitute `Cupertino` controls for unimplemented Fluent mobile
  controls when the package policy forbids Cupertino.
- Do not use `Color(0x...)`, arbitrary opacity, raw radii, or raw motion values
  when a token exists.
- Do not treat a placeholder as a label or a tooltip as an accessible name.
- Do not make the visual child of a split control one combined focus target.
- Do not dismiss an alert dialog through its scrim or silently steal focus for
  a non-modal surface.
- Do not add hover-only functionality; every action needs another input path.
- Do not copy a React prop name into Dart without verifying the constructor.
