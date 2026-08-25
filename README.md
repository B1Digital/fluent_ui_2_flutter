<p align="center">
  <img src="assets/fluent_2_flutter.png" width="120" alt="Fluent 2 for Flutter" />
</p>

<h1 align="center">Fluent 2 for Flutter</h1>

<p align="center">
  <b>Microsoft's Fluent 2 design system, implemented for Flutter as a Dart pub workspace.</b><br />
  90+ components · 20 chart types · 135 locales · light, dark, Teams and high-contrast themes.
</p>

<p align="center">
  <a href="https://b1digital.github.io/fluent_ui_2_flutter/"><img src="https://img.shields.io/badge/live-showroom-0F6CBD?logo=googlechrome&logoColor=white" alt="live showroom" /></a>
  <a href="https://github.com/B1Digital/fluent_ui_2_flutter/actions"><img src="https://img.shields.io/github/actions/workflow/status/B1Digital/fluent_ui_2_flutter/test.yml?branch=main&label=CI" alt="CI" /></a>
  <a href="#-tests--coverage"><img src="https://img.shields.io/badge/coverage-92%25-107C10" alt="line coverage" /></a>
  <a href="#-tests--coverage"><img src="https://img.shields.io/badge/tests-7023-107C10" alt="tests" /></a>
  <img src="https://img.shields.io/badge/flutter-%E2%89%A53.41-02569B?logo=flutter&logoColor=white" alt="flutter" />
  <img src="https://img.shields.io/badge/material-free-107C10" alt="no material" />
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT" /></a>
</p>

<p align="center">
  <a href="https://b1digital.github.io/fluent_ui_2_flutter/"><b>▶ Open the live showroom</b></a>
  — the Fluent UI React v9 Storybook, rebuilt in Flutter and deployed on every push to <code>main</code>.
</p>

> **Zero Material / Cupertino**: This system replaces Material — it does not layer on top of it. No package in this repository imports `package:flutter/material.dart` or `package:flutter/cupertino.dart`. Everything is built strictly on `package:flutter/widgets.dart`.

---

## 🎨 Component Showcase

Real renders of the widgets in this repository, captured from the showroom in
both themes. Nothing below is a mockup.

| | Light | Dark |
| :-- | :---: | :---: |
| **Buttons** | ![](assets/previews/button.light.png) | ![](assets/previews/button.dark.png) |
| **Text inputs** | ![](assets/previews/input.light.png) | ![](assets/previews/input.dark.png) |
| **Selection controls** | ![](assets/previews/selection.light.png) | ![](assets/previews/selection.dark.png) |
| **Surfaces & people** | ![](assets/previews/surfaces.light.png) | ![](assets/previews/surfaces.dark.png) |
| **Navigation** | ![](assets/previews/navigation.light.png) | ![](assets/previews/navigation.dark.png) |
| **Menus & toolbars** | ![](assets/previews/menu.light.png) | ![](assets/previews/menu.dark.png) |
| **Data grid** | ![](assets/previews/data_grid.light.png) | ![](assets/previews/data_grid.dark.png) |
| **Calendar** | ![](assets/previews/calendar.light.png) | ![](assets/previews/calendar.dark.png) |
| **Status & progress** | ![](assets/previews/feedback.light.png) | ![](assets/previews/feedback.dark.png) |
| **Charts** | ![](assets/previews/charts.light.png) | ![](assets/previews/charts.dark.png) |
| **Bar charts & gauges** | ![](assets/previews/charts_bars.light.png) | ![](assets/previews/charts_bars.dark.png) |

<sub>Regenerate with `cd packages/fluent_2/example && flutter test tool/generate_previews.dart`.</sub>

---

## 📁 Workspace Layout

```text
packages/
  fluent_2_fonts/    conditional platform-font facade
  fluent_2_fonts_*/  separate Web, Windows, macOS, iOS, Android packages
  fluent_2_core/     tokens + theming + app shell   ← shared foundation
  fluent_2/          Fluent 2 components & widgets
```

Split by *surface*, not by component category — buttons/inputs/surfaces are folders inside a package. Surfaces are what actually diverge: a web button and its mobile variant are different widgets. Each UI package depends on `fluent_2_core` and re-exports it, so consumers need one import.

---

## 🚀 Quick Start & Usage

```dart
import 'package:fluent_2/fluent_2.dart';

void main() => runApp(
  FluentApp(
    theme: FluentThemeData.light(),
    darkTheme: FluentThemeData.dark(),
    themeMode: FluentThemeMode.system,
    home: const Home(),
  ),
);

// Anywhere below:
final theme = FluentTheme.of(context);
theme.colors.brandBackground;          // alias token
theme.typography.subtitle1;            // type ramp
theme.shadow(FluentElevation.shadow8); // two-layer elevation
FluentSpacing.l;                       // 16
FluentRadius.medium;                   // 4
FluentDuration.normal;                 // 200ms
FluentCurve.decelerateMid;             // entrance easing
```

---

## 🎨 Theming & Brand Ramps

Brand ramps are **generated from one key color**, not hand-picked — a Dart port of the Theme Designer algorithm (two quadratic beziers through CIE Lab, black → key color → white, sampled against a per-hue lightness table, then chroma-snapped into the sRGB gamut):

```dart
FluentThemeData.light(
  brand: FluentBrandRamp.fromKeyColor(
    const Color(0xFF7B2D8E),
    vibrancy: 0.5,    // both bezier control points; null = upstream 2/3 & 1/3
    hueTorsion: 0.2,  // rotate through neighbouring hues (-0.5…0.5)
  ),
);
```

**The generator does not reproduce Microsoft's shipped ramps.** Feeding it `#0F6CBD` matches 0 of `brandWeb`'s 16 stops, and your key color does not land on stop 80 — the lightness ladder comes from the hue table, not from the key color. `brandWeb` is hand-authored. So both exist, and the divergence is asserted in a test rather than hidden:

- `FluentBrandRamp.fromKeyColor(...)` — your own brand
- `FluentBrandRamp.web / .teams / .teamsV21 / .office / .communicationBlue` — verbatim upstream constants, for fidelity to Microsoft's real themes

The port is verified by a golden test against values captured from executing the upstream TypeScript: all 16 shades match byte for byte.

Prebuilt variants:

```dart
FluentThemeData.light();          FluentThemeData.dark();
FluentThemeData.teamsDark();      // own token table, not dark + Teams ramp
FluentThemeData.highContrast();   // 8 Windows system colors, no brand
```

Override individual tokens by subclassing `FluentColors` — every token is a virtual getter, so there is no `copyWith` plumbing:

```dart
class MyColors extends FluentColors {
  const MyColors();
  @override
  Color get brandBackground => const Color(0xFF7B2D8E);
}
```

---

## 📊 Token Sources

`fluent2.microsoft.design` publishes prose and images — `/design-tokens`, `/material` and `/motion` contain **zero numeric values**, and `/color` has no hex codes. Every value here is transcribed from the authoritative source:

| Area | Source |
|---|---|
| Colors, typography, spacing, radius, stroke, motion | `microsoft/fluentui` → `packages/tokens/src` |
| iOS ramps | `microsoft/fluentui-apple` → `GlobalTokens.swift` |
| Android ramps | `microsoft/fluentui-android` → `FluentGlobalTokens.kt` |
| Elevation luminosity equation | `fluent2.microsoft.design/elevation` |
| Acrylic constants | `microsoft/microsoft-ui-xaml` → `AcrylicBrush` |
| Brand ramp generator, 360-row hue table | `microsoft/fluentui` → `react-components/theme-designer/src` |

The Storybook at `storybooks.fluentui.dev` is also a client-rendered shell — its `index.json` lists stories but holds no token data, and the Theme docs pages are empty `<Story />` wrappers.

The type ramp follows the current Fluent 2 typography tables independently for Web, Windows, macOS, iOS, and Android. Use `fontPlatform` to preview a different ramp; otherwise `FluentThemeData` selects the build's platform automatically.

---

## 🌍 Localization

Every string `fluent_2` puts in front of a user — accessibility labels, calendar chrome, chart descriptions, date-picker validation — comes from an ARB message catalogue, in **135 locales**. Nothing is hardcoded English.

```dart
FluentApp(
  localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
    FluentLocalizations.delegate,
  ],
  supportedLocales: FluentLocalizations.supportedLocales,
  home: const Home(),
)
```

Install nothing and components still render: `fluentL10n(context)` falls back to `fluentLocalizationsFallback` (US English) rather than throwing. A design system may not make an application's accessibility labels a startup requirement.

Every locale carries a country code — `en_US`, `en_GB`, `de_DE`, `de_CH`, `pt_BR`, `pt_PT`, `zh_Hans_CN`, `zh_Hant_TW` — with a bare-language file behind each as the fallback Flutter resolves to for an unlisted country.

| Language | Locales |
|---|---|
| Arabic | `ar` · `ar_SA` `ar_AE` `ar_EG` `ar_MA` `ar_DZ` `ar_IQ` `ar_JO` `ar_KW` `ar_LB` `ar_QA` `ar_TN` |
| Belarusian | `be` · `be_BY` |
| Croatian | `hr` · `hr_HR` `hr_BA` |
| Czech | `cs` · `cs_CZ` |
| Dutch | `nl` · `nl_NL` `nl_BE` |
| English | `en` · `en_US` `en_GB` `en_CA` `en_AU` `en_NZ` `en_IE` `en_ZA` `en_IN` `en_SG` |
| Filipino (Tagalog) | `fil` · `fil_PH` |
| French | `fr` · `fr_FR` `fr_CA` `fr_BE` `fr_CH` `fr_LU` |
| German | `de` · `de_DE` `de_AT` `de_CH` `de_LI` `de_LU` |
| Greek | `el` · `el_GR` `el_CY` |
| Hebrew | `he` · `he_IL` |
| Hindi | `hi` · `hi_IN` |
| Hungarian | `hu` · `hu_HU` |
| Indonesian | `id` · `id_ID` |
| Italian | `it` · `it_IT` `it_CH` |
| Japanese | `ja` · `ja_JP` |
| Korean | `ko` · `ko_KR` |
| Malay | `ms` · `ms_MY` `ms_BN` `ms_SG` |
| Nepali | `ne` · `ne_NP` `ne_IN` |
| Persian | `fa` · `fa_IR` `fa_AF` |
| Polish | `pl` · `pl_PL` |
| Portuguese | `pt` · `pt_BR` `pt_PT` `pt_AO` `pt_MZ` |
| Romanian | `ro` · `ro_RO` `ro_MD` |
| Russian | `ru` · `ru_RU` `ru_BY` `ru_KZ` `ru_KG` |
| Spanish | `es` · `es_ES` `es_MX` `es_AR` `es_CO` `es_CL` `es_PE` `es_VE` `es_US` `es_UY` `es_EC` `es_CR` `es_DO` `es_GT` `es_PA` `es_PY` `es_BO` |
| Tamil | `ta` · `ta_IN` `ta_LK` `ta_SG` `ta_MY` |
| Thai | `th` · `th_TH` |
| Turkish | `tr` · `tr_TR` `tr_CY` |
| Ukrainian | `uk` · `uk_UA` |
| Urdu | `ur` · `ur_PK` `ur_IN` |
| Uzbek | `uz` · `uz_UZ` |
| Chinese (Simplified) | `zh` · `zh_Hans` `zh_Hans_CN` `zh_Hans_SG` `zh_CN` `zh_SG` |
| Chinese (Traditional) | `zh_Hant` `zh_Hant_TW` `zh_Hant_HK` `zh_Hant_MO` `zh_TW` `zh_HK` |

Month and weekday names are **not** in the catalogue — they come from `intl`'s CLDR data through `FluentCalendarStrings.of(context)`. That needs `initializeDateFormatting('<locale>')` first; without it the chrome is still translated and the names stay English, because guessing a date format is worse than an untranslated month.

### Editing a message

`packages/fluent_2/l10n/` holds one ARB per locale, but only **36** are written by hand — the sources listed in `tool/expand_l10n_locales.dart`. The rest are country copies of those. Edit a source, then:

```bash
melos run gen-l10n        # expand → flutter gen-l10n → strip Material → format
```

`flutter gen-l10n` emits an import of `flutter_localizations`, which re-exports `GlobalMaterialLocalizations`; `tool/strip_l10n_material.dart` removes it, and `melos run no-material` fails the build if it ever comes back.

---

## 🛠️ CLI Commands

```bash
flutter pub get          # pub workspace handles resolution
melos run ci             # analyze + format + no-material + chart-invariants + test
melos run test
melos run coverage       # the same suites, with --coverage
melos run gen-l10n       # regenerate the 135-locale message catalogue
```

---

## 🧪 Tests & Coverage

**5,426 tests. 91.5 % line coverage.** `melos run coverage` runs the same suites
as `melos run test` with `--coverage`; the two library packages' LCOV files are
checked in, so the report can be re-derived — or rendered as HTML — without
running the suite:

```bash
melos run coverage    # writes packages/*/coverage/lcov.info
genhtml packages/fluent_2/coverage/lcov.info -o packages/fluent_2/coverage/html
```

| Package | Tests | Lines covered | Line coverage | Report |
| :-- | --: | --: | --: | :-- |
| `fluent_2` | 5,374 | 49,214 / 53,481 | **92.0 %** | [`coverage/lcov.info`](packages/fluent_2/coverage/lcov.info) |
| `fluent_2_core` | 67 | 1,322 / 1,823 | **72.5 %** | [`coverage/lcov.info`](packages/fluent_2_core/coverage/lcov.info) |
| `fluent_2/example` | 1,582 | — | — | showroom contract tests, no library code |
| **Workspace** | **7,023** | **50,536 / 55,304** | **91.4 %** | |

15,072 of those covered lines are the generated 135-locale message catalogue,
which is exhaustive by construction. **Excluding `lib/src/l10n/`, `fluent_2`
sits at 88.9 % (34,143 / 38,409)** — that is the number worth watching.

| Area — `fluent_2/lib/src/` | Lines covered | Line coverage |
| :-- | --: | --: |
| `l10n` *(generated)* | 15,071 / 15,072 | 100.0 % |
| `overlays` | 2,295 / 2,438 | 94.1 % |
| `internal` | 262 / 280 | 93.6 % |
| `navigation` | 2,696 / 2,909 | 92.7 % |
| `charts` | 18,763 / 20,316 | 92.4 % |
| `buttons` | 500 / 564 | 88.7 % |
| `surfaces` | 3,035 / 3,669 | 82.7 % |
| `inputs` | 6,592 / 8,233 | 80.1 % |

Line coverage is the floor, not the claim — a widget that renders is not a
widget that renders *correctly*. What the percentage does not show:

- **264 golden images** under `test/goldens/`, one per component per theme.
- **90 React reference PNGs** in `test/fixtures/charts/react_png/`, captured from
  the upstream Fluent UI Storybook; the parity suite renders the Flutter chart
  against each one and asserts a per-pixel difference budget.
- **Numeric spec fixtures** — token, geometry and layout values transcribed from
  the Fluent spec and asserted directly, so a chart's margins are pinned to the
  same numbers upstream solves for.
- **`melos run no-material` and `melos run chart-invariants`**, which fail the
  build on a Material import or a broken single-owner rule — invariants a test
  file cannot express.

CI (`.github/workflows/test.yml`) runs `melos run ci` on every push and pull
request; it runs the suite without `--coverage`, so the table above is refreshed
by hand from `melos run coverage`.

---

## 🤖 Agent Skill Integration

Install the repository's Fluent 2 Flutter guidance with the open Agent Skills CLI. The skill uses the portable `SKILL.md` format, so the same source works with Claude Code, Cursor, Codex, and every other harness recognized by the CLI:

```bash
npx skills add B1Digital/fluent_ui_2_flutter \
  --skill fluent-2-flutter \
  --agent '*'
```

To install only selected integrations, use `--agent claude-code cursor codex`. For local development, replace the repository name with `.`.

Without the CLI, download the skill folder straight from GitHub:

```bash
# Claude Code: ~/.claude/skills — Cursor: ~/.cursor/skills — Codex: ~/.codex/skills
mkdir -p ~/.claude/skills && curl -L https://github.com/B1Digital/fluent_ui_2_flutter/archive/refs/heads/main.tar.gz \
  | tar -xz -C ~/.claude/skills --strip-components=2 'fluent_ui_2_flutter-main/skills/fluent-2-flutter'
```

A harness that implements the Agent Skills standard can also load `skills/fluent-2-flutter/SKILL.md` directly. The optional `agents/openai.yaml` adds Codex UI metadata; it does not replace or restrict the portable skill.

---

## 🚦 Package Status

- **`fluent_2_fonts`**: Selects the platform package and supplies the open-source Selawik substitute for Segoe UI on Web and Windows. Apple and Android builds use native system families.
- **`fluent_2_core`**: Supplies shared tokens, elevation models, typography, and themes.
- **`fluent_2`**: Contains the current web and desktop component implementation and gallery.

---

## 🧩 Adding a Component

```text
packages/fluent_2/lib/src/buttons/fluent_button.dart   one component per file
packages/fluent_2/lib/fluent_2.dart                export it here, alphabetically
```

Conventions, all of them enforced by `melos run ci`:

- **No Material.** Import `package:flutter/widgets.dart`. `melos run no-material` fails the build on `material.dart` or `cupertino.dart`.
- **No hardcoded values.** Every color, size, radius, duration and curve comes from a token: `FluentTheme.of(context).colors`, `FluentSpacing`, `FluentRadius`, `FluentDuration`, `FluentCurve`. A raw `Color(0xFF...)` or a bare `16` in a widget is a bug — if the token is missing, add it to core.
- **Document every public member.** `public_member_api_docs` is an *error* in the root `analysis_options.yaml`; undocumented public API does not compile in CI. Cite the Fluent spec on the class doc where a value is non-obvious.
- **`const` constructors.** Widgets take `const` constructors and `super` parameters; the lint set rejects the alternatives.
- **Accessibility is not optional.** Interactive components need a `Semantics` label, a keyboard focus path (`FocusableActionDetector`) and a visible focus indicator. This is the one area where "add it later" is not allowed.
- **A widget test per component.** Renders, responds to interaction, honours the theme — plus a golden image per theme, and a numeric spec fixture where a Figma value exists.

---

## 🖼️ Regenerating the README Previews

The showcase images are real renders, produced from the showroom's own story
sections with the Selawik and Fluent icon fonts loaded:

```sh
cd packages/fluent_2/example
flutter test tool/generate_previews.dart   # writes assets/previews/*.png
```

Edit the `_previews` list in `tool/generate_previews.dart` to change which
sections each image stacks.
