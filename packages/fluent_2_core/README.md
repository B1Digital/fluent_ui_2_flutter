# fluent_2_core

Fluent 2 design tokens, theming and app shell for Flutter. The shared foundation
under every `fluent_2_*` UI package — depend on this directly only if you are
building your own component layer; otherwise use `fluent_2`, which re-exports
it.

```dart
import 'package:fluent_2_core/fluent_2_core.dart';

final theme = FluentTheme.of(context);
theme.colors.brandBackground;          // alias token
theme.typography.subtitle1;            // type ramp
theme.shadow(FluentElevation.shadow8); // two-layer elevation
FluentSpacing.l;                       // 16
FluentRadius.medium;                   // 4
FluentDuration.normal;                 // 200ms
FluentCurve.decelerateMid;             // entrance easing
```

## What's here

| Library | Contents |
|---|---|
| `src/app.dart` | `FluentApp` — the `MaterialApp` replacement |
| `src/theme.dart` | `FluentTheme`, `FluentThemeData`, `InheritedTheme` plumbing |
| `src/tokens/global_colors.dart` | Global color ramps |
| `src/tokens/alias_colors.dart` | Semantic aliases (`FluentColors`) |
| `src/tokens/brand_generator.dart` | Theme Designer port — ramp from one key color |
| `src/tokens/typography.dart` | Per-platform type ramps |
| `src/tokens/layout.dart` | Spacing, radius, stroke |
| `src/tokens/elevation.dart` | Two-layer shadow system |
| `src/tokens/motion.dart` | Durations and curves |
| `src/tokens/theme_variants.dart` | light / dark / teamsDark / highContrast |

`FluentThemeData` selects the current platform's typography ramp by default.
Use `fontPlatform` only to preview another surface:

```dart
final webPreview = FluentThemeData.light(
  fontPlatform: FluentFontPlatform.web,
);
```

`FluentApp` loads Selawik automatically on Web and Windows. `FluentFonts` is
re-exported by core for applications that need to preload it before `runApp`.

Token provenance, the brand-ramp algorithm and known upstream conflicts are
documented in the
[repository README](../../README.md).

## Overriding tokens

Every token is a virtual getter, so there is no `copyWith` plumbing — subclass:

```dart
class MyColors extends FluentColors {
  const MyColors();
  @override
  Color get brandBackground => const Color(0xFF7B2D8E);
}
```
