# fluent_2_web Components Implementation Plan

> **For agentic workers:** Execute task-by-task; each step is a checkbox (`- [ ]`).

**Goal:** Ship every Fluent 2 web component in `packages/fluent_2_web` as raw Flutter widgets (zero Material/Cupertino), pixel-accurate to the official Microsoft Figma release, motion-accurate to `@fluentui/react-components`, and exposing the same three-tier extensibility ladder React v9 does — no less.

**Architecture:** Three layers. (1) `fluent_2_core` gains the token groups it never ported (status, shared palette, acrylic) plus per-token theme override so `FluentThemeOverride` matches React's `PartialTheme` semantics. (2) `fluent_2_web/lib/src/internal/` holds five shared primitives — slots, interaction state, focus ring, animated style, and the recomposition contract — locked and tested before any component exists. (3) Each component is a thin composition of three public, separable functions (`resolve*State` → `resolve*Style` → `build*`), mirroring React's `use*_unstable` / `use*Styles_unstable` / `render*_unstable` triple 1:1, so a consumer can substitute any one of them. Pixel fidelity is gated by JSON spec fixtures extracted from the Figma variables, not by golden images (Segoe UI does not exist in CI).

**Tech Stack:** Dart ^3.12.2, Flutter >=3.27.0, `package:flutter/widgets.dart` only, `fluentui_system_icons` (via core's barrel), melos workspace, `flutter_test`.

---

## Global Constraints

Every task inherits these. Violating any one fails the task.

- **No Material, no Cupertino, anywhere.** No `import 'package:flutter/material.dart'` or `cupertino.dart` in `lib/` or `test/`. Enforced by `melos run no-material`. Forbidden: `InkWell`, `Material`, `Scaffold`, `AppBar`, `TextField`, `Icons.*`, `Theme.of`. Use `GestureDetector`, `Listener`, `MouseRegion`, `FocusableActionDetector`, `EditableText`, `DecoratedBox`, `CustomPaint`, `IconTheme`, `DefaultTextStyle`, `Actions`, `Shortcuts`, `Overlay`, `Navigator`. Icons come from `FluentIcons.*`.
- **`melos run ci` is green after every task.** That is `analyze --fatal-infos` + `format --set-exit-if-changed` + `no-material` + `test`. No task is complete with a red CI.
- **No new dependencies.** Everything is achievable with the Flutter SDK plus what is already in `pubspec.yaml`.
- **Token names are upstream's, verbatim.** `neutralForeground2BrandHover`, `compoundBrandStrokePressed`. Never rename for prettiness — verbatim names are what make values checkable against `microsoft/fluentui` `packages/tokens/src/alias/*.ts`.
- **Interactive states are tokens, never opacity math.** Use `subtleBackgroundHover`, never `background.withOpacity(0.9)`. If you are computing a hover color you are using the wrong token.
- **Never hardcode `Colors.transparent` for a border or background.** In high contrast those tokens become opaque (`transparentStroke` → `canvasText`). Always go through the token.
- **Every component ships a test.** `packages/fluent_2_web/test/` must exist from Task 6 onward — `melos.yaml:28-29` filters the `test` script on `dirExists: test`, so an untested package is silently skipped by CI.
- **Reduced motion is honoured.** Every animation checks `MediaQuery.disableAnimationsOf(context)` and collapses to `Duration.zero`, mirroring upstream's `prefers-reduced-motion` clamp to `0.01ms`.
- **Figma wins over React on visuals; React wins on behaviour and motion.** Where they conflict, add an inline comment naming both and the resolution. Two known conflicts are already documented in Task 8 (focus ring) and Appendix B (Checkbox has no transitions).
- **Do not bundle Segoe UI.** `typography.dart:48` names the family as a string with fallbacks; that is deliberate and legally required. The font itself is under the Microsoft Fabric Assets License, not MIT.

---

### Task 1: Version control and license

The repo is **not currently a git repository** and `LICENSE` reads `TODO: Add your license here.`. A 104-component build without version control is not recoverable from a bad wave, and the port redistributes MIT-licensed token values which carries an attribution obligation.

**Files:**
- Create: `.gitignore`
- Modify: `LICENSE` (whole file)
- Create: `THIRD_PARTY_NOTICES.md`

- [ ] **Step 1: Initialise the repository.**
  ```bash
  cd /Users/alisinancobani/IdeaProjects/flutent_2_web
  git init
  ```
- [ ] **Step 2: Write `.gitignore`.**
  ```
  .dart_tool/
  .packages
  build/
  pubspec_overrides.yaml
  *.iml
  .idea/
  .DS_Store
  ```
- [ ] **Step 3: Replace `LICENSE`** with the MIT text, copyright the repository owner. Then create `THIRD_PARTY_NOTICES.md` recording the two upstream sources and their terms:
  ```markdown
  # Third-party notices

  ## microsoft/fluentui — MIT
  Design token values, component behaviour and motion specifications in this
  repository are derived from https://github.com/microsoft/fluentui, licensed MIT,
  Copyright (c) Microsoft Corporation. Full MIT text reproduced in LICENSE.

  The fluentui LICENSE carves out "the fonts and icons referenced in Fluent UI
  React", which are governed by the Microsoft Fabric Assets License
  (https://aka.ms/fluentui-assets-license) and are NOT redistributed here.
  Specifically: the Segoe UI font is referenced by family name only and is never
  bundled; no Microsoft product logos or MDL2 branded icons are included.

  ## microsoft/fluentui-system-icons — MIT
  Consumed via the `fluentui_system_icons` pub package. Unqualified MIT with no
  asset carve-out.
  ```
- [ ] **Step 4: Verify and commit.**
  ```bash
  melos run ci
  git add -A && git commit -m "chore: initialise repository, MIT license, third-party notices"
  ```
  Expect: `ci` green, one commit created.

> If the owner declines `git init`, drop Step 1/4's commit lines from every subsequent task and keep the rest. Every later task assumes commits are possible.

---

## Phase 0 — Core token gaps and per-token theme override

The Figma file carries 359 alias variables (light/dark) and 751 global variables. Core ported the neutral+brand aliases and the full global ramp, but four groups are missing entirely. Message bar, Badge, Toast, Persona, Avatar, Status indicator and Material acrylic cannot be built pixel-perfect until they land.

| Figma group | Count | Blocks |
|---|---|---|
| `Status/*` — Danger, Success, Severe, Warning, Available, Away, Oof | 41 | Message bar, Toast, Status indicator, ProgressBar states, Badge |
| `Palette/*` (49 families) + ` Global` `Colors/Shared` | ~150 + 588 | Avatar, Persona, Presence badge, Swatch picker, Tag |
| `Material/Acrylic/*` | 6 | Material acrylic, Popover/Menu/Drawer surfaces |
| `Shape/*` — `Button/Container`, `Badge/Small`, `Message bar/Container`, `Swatch/Default` | 8 | Radius resolution on those four |

### Task 2: Extract the missing token values from Figma

**Files:**
- Create: `tool/extract_figma_tokens.dart`
- Create: `packages/fluent_2_core/tool/figma_tokens.json` (generated artifact, committed)

**Interfaces:**
- Produces: `figma_tokens.json` — `{ "<collection>": { "<variable name>": { "<mode>": "#rrggbbaa" | number } } }`

- [ ] **Step 1: Extract via the Figma MCP.** Run one `use_figma` call per collection (file key `Heyk4N9SnwfIzupHlk3l7s`), resolving every variable's value in every mode. Collections needed: `Mode` (359 vars, modes Light/Dark), ` Global` (751), `Shape` (8). Script body:
  ```js
  const cols = await figma.variables.getLocalVariableCollectionsAsync();
  const c = cols.find(x => x.name === COLLECTION_NAME);
  const out = {};
  for (const id of c.variableIds) {
    const v = await figma.variables.getVariableByIdAsync(id);
    if (!v) continue;
    out[v.name] = {};
    for (const m of c.modes) {
      const raw = v.valuesByMode[m.modeId];
      if (raw && raw.type === 'VARIABLE_ALIAS') {
        const a = await figma.variables.getVariableByIdAsync(raw.id);
        out[v.name][m.name] = { alias: a ? a.name : raw.id };
      } else if (raw && typeof raw === 'object' && 'r' in raw) {
        const h = n => Math.round(n * 255).toString(16).padStart(2, '0');
        out[v.name][m.name] = '#' + h(raw.r) + h(raw.g) + h(raw.b) +
          (raw.a !== undefined && raw.a < 1 ? h(raw.a) : '');
      } else {
        out[v.name][m.name] = raw;
      }
    }
  }
  return out;
  ```
- [ ] **Step 2: Write the merged JSON** to `packages/fluent_2_core/tool/figma_tokens.json`. Resolve `alias` entries transitively against ` Global` so every leaf is a concrete hex or number.
- [ ] **Step 3: Assert completeness.** Confirm the file contains all four missing groups:
  ```bash
  cd packages/fluent_2_core && python3 -c "
  import json; d=json.load(open('tool/figma_tokens.json'))
  m=d['Mode']
  for p in ['Status/','Palette/','Material/Acrylic/']:
      n=len([k for k in m if k.startswith(p)]); print(p, n); assert n>0, p
  assert len(d['Shape'])==8
  print('OK')"
  ```
  Expect: `Status/ 41`, `Palette/ ~150`, `Material/Acrylic/ 6`, `OK`.
- [ ] **Step 4: Commit.**
  ```bash
  git add -A && git commit -m "chore(core): extract Fluent 2 Figma token values"
  ```

---

### Task 3: Port the status, palette, acrylic and shape tokens

**Files:**
- Create: `packages/fluent_2_core/lib/src/tokens/status_colors.dart`
- Create: `packages/fluent_2_core/lib/src/tokens/palette_colors.dart`
- Create: `packages/fluent_2_core/lib/src/tokens/materials.dart`
- Modify: `packages/fluent_2_core/lib/fluent_2_core.dart` (add exports)
- Test: `packages/fluent_2_core/test/status_palette_test.dart`

**Interfaces:**
- Consumes: `tool/figma_tokens.json` from Task 2.
- Produces: `FluentStatusColors`, `FluentPaletteColors`, `FluentPaletteFamily`, `FluentAcrylic`; `FluentColors.status`, `FluentColors.palette` getters.

- [ ] **Step 1: Write the failing test.**
  ```dart
  // packages/fluent_2_core/test/status_palette_test.dart
  import 'package:flutter/widgets.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:fluent_2_core/fluent_2_core.dart';

  void main() {
    test('status tokens resolve per brightness', () {
      const light = FluentStatusColors(brightness: Brightness.light);
      const dark = FluentStatusColors(brightness: Brightness.dark);
      expect(light.dangerBackground1, isNot(dark.dangerBackground1));
      expect(light.successForeground1, isA<Color>());
      expect(light.warningBackground3, isA<Color>());
      expect(light.severeForeground2, isA<Color>());
    });

    test('every palette family exposes the three-token set', () {
      for (final f in FluentPaletteFamily.values) {
        const p = FluentPaletteColors(brightness: Brightness.light);
        expect(p.background2(f), isA<Color>());
        expect(p.foreground2(f), isA<Color>());
        expect(p.borderActive(f), isA<Color>());
      }
      expect(FluentPaletteFamily.values.length, 49);
    });

    test('acrylic exposes primary and secondary tints', () {
      const a = FluentAcrylic(brightness: Brightness.light);
      expect(a.backgroundPrimary.a, lessThan(1.0));
      expect(a.backgroundSecondary, isA<Color>());
    });

    test('theme surfaces status and palette', () {
      final t = FluentThemeData.light();
      expect(t.colors.status.dangerBackground1, isA<Color>());
      expect(t.colors.palette.background2(FluentPaletteFamily.cranberry), isA<Color>());
    });
  }
  ```
- [ ] **Step 2: Run it, verify it fails.**
  ```bash
  cd packages/fluent_2_core && flutter test test/status_palette_test.dart
  ```
  Expect: compile failure — `FluentStatusColors` / `FluentPaletteFamily` / `FluentAcrylic` are undefined.
- [ ] **Step 3: Implement**, transcribing values from `figma_tokens.json`. Follow the existing `alias_colors.dart` shape exactly — one virtual getter per token, light and dark on one line:
  ```dart
  // status_colors.dart
  @immutable
  class FluentStatusColors {
    const FluentStatusColors({this.brightness = Brightness.light});
    final Brightness brightness;
    bool get _d => brightness == Brightness.dark;

    // Source: Figma `Mode` collection, Status/Danger/*; upstream alias/*Color.ts
    Color get dangerBackground1 => _d ? const Color(0xFF3B0509) : const Color(0xFFFDF3F4);
    Color get dangerBackground2 => _d ? const Color(0xFF8A2429) : const Color(0xFFF1BBBC);
    Color get dangerBackground3 => _d ? const Color(0xFFD13438) : const Color(0xFFC50F1F);
    Color get dangerForeground1 => _d ? const Color(0xFFD74553) : const Color(0xFFB10E1C);
    // ... all 41 Status tokens, values from figma_tokens.json
  }
  ```
  `FluentPaletteFamily` is a 49-value enum (`darkRed, cranberry, red, pumpkin, peach, marigold, gold, brass, brown, forest, seafoam, darkGreen, lightTeal, teal, steel, blue, royalBlue, cornflower, navy, lavender, purple, grape, lilac, pink, magenta, plum, beige, mink, platinum, anchor, green, darkOrange, yellow, berry, lightGreen, …`). `FluentPaletteColors` exposes `background2(family)`, `foreground2(family)`, `borderActive(family)` backed by a `const Map<FluentPaletteFamily, Color>` per token per brightness. Add `FluentStatusColors get status` and `FluentPaletteColors get palette` to `FluentColors`, both derived from `brightness`.
- [ ] **Step 4: Run it, verify it passes.**
  ```bash
  cd packages/fluent_2_core && flutter test
  ```
  Expect: all previous 27 tests plus the 4 new ones pass.
- [ ] **Step 5: Commit.**
  ```bash
  git add -A && git commit -m "feat(core): port status, palette and acrylic tokens"
  ```

---

### Task 4: Per-token theme override (`PartialTheme` parity)

React lets a consumer override **one** of ~467 tokens for **one** subtree via a nested `<FluentProvider theme={{colorBrandBackground: '#780510'}}>`, shallow-merged over the ancestor theme. Core today only offers `FluentThemeData.copyWith(colors:, typography:)` — wholesale replacement — and the doc comment at `alias_colors.dart:16-17` points users at subclassing, which cannot be expressed inline in a widget tree. This task closes that gap.

**Files:**
- Create: `packages/fluent_2_core/lib/src/tokens/color_token.dart`
- Modify: `packages/fluent_2_core/lib/src/tokens/alias_colors.dart` (every getter; add `overrides` field)
- Modify: `packages/fluent_2_core/lib/src/theme.dart` (add `FluentThemeOverride`)
- Create: `tool/add_token_overrides.dart` (one-shot codemod, committed for auditability)
- Test: `packages/fluent_2_core/test/theme_override_test.dart`

**Interfaces:**
- Produces: `enum FluentColorToken` (one value per alias getter); `FluentColors.overrides` field; `FluentColors.withOverrides(Map<FluentColorToken, Color>)`; `FluentThemeOverride` widget.
- Consumed by: every component in Phase 2+ indirectly via `FluentTheme.of(context)`.

- [ ] **Step 1: Write the failing test.**
  ```dart
  // packages/fluent_2_core/test/theme_override_test.dart
  import 'package:flutter/widgets.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:fluent_2_core/fluent_2_core.dart';

  void main() {
    testWidgets('overrides a single token for a subtree only', (tester) async {
      const magenta = Color(0xFF780510);
      late FluentThemeData outer;
      late FluentThemeData inner;

      await tester.pumpWidget(
        FluentTheme(
          data: FluentThemeData.light(),
          child: Builder(builder: (context) {
            outer = FluentTheme.of(context);
            return FluentThemeOverride(
              colors: const {FluentColorToken.brandBackground: magenta},
              child: Builder(builder: (context) {
                inner = FluentTheme.of(context);
                return const SizedBox();
              }),
            );
          }),
        ),
      );

      expect(inner.colors.brandBackground, magenta);
      expect(outer.colors.brandBackground, isNot(magenta));
      // untouched tokens still resolve from the base ramp
      expect(inner.colors.neutralForeground1, outer.colors.neutralForeground1);
    });

    testWidgets('nested overrides shallow-merge, inner wins', (tester) async {
      late FluentThemeData leaf;
      await tester.pumpWidget(
        FluentTheme(
          data: FluentThemeData.light(),
          child: FluentThemeOverride(
            colors: const {
              FluentColorToken.brandBackground: Color(0xFF111111),
              FluentColorToken.neutralForeground1: Color(0xFF222222),
            },
            child: FluentThemeOverride(
              colors: const {FluentColorToken.brandBackground: Color(0xFF333333)},
              child: Builder(builder: (context) {
                leaf = FluentTheme.of(context);
                return const SizedBox();
              }),
            ),
          ),
        ),
      );
      expect(leaf.colors.brandBackground, const Color(0xFF333333)); // inner wins
      expect(leaf.colors.neutralForeground1, const Color(0xFF222222)); // outer survives
    });

    test('every alias getter has a matching enum value', () {
      // guards the codemod: enum and getters must stay in lockstep
      expect(FluentColorToken.values.length, greaterThanOrEqualTo(180));
      const c = FluentColors();
      for (final t in FluentColorToken.values) {
        expect(c.resolve(t), isA<Color>(), reason: '${t.name} does not resolve');
      }
    });
  }
  ```
- [ ] **Step 2: Run it, verify it fails.**
  ```bash
  cd packages/fluent_2_core && flutter test test/theme_override_test.dart
  ```
  Expect: compile failure — `FluentThemeOverride`, `FluentColorToken`, `resolve` undefined.
- [ ] **Step 3: Implement.** Write `tool/add_token_overrides.dart`, a codemod that parses `alias_colors.dart`, emits `FluentColorToken` with one value per `Color get <name>`, and rewrites every getter body to route through an override lookup. Add to `FluentColors`:
  ```dart
  final Map<FluentColorToken, Color>? overrides;

  /// Override lookup. Preserves the one-line-per-token shape so every value
  /// stays checkable against upstream `alias/lightColor.ts`.
  @pragma('vm:prefer-inline')
  Color _o(FluentColorToken t, Color v) => overrides?[t] ?? v;

  /// Resolve any token by identity — the Dart analogue of `tokens[key]`.
  Color resolve(FluentColorToken t) => switch (t) {
    FluentColorToken.neutralForeground1 => neutralForeground1,
    // ... generated, one arm per token
  };

  FluentColors withOverrides(Map<FluentColorToken, Color> extra) => FluentColors(
    brightness: brightness,
    brand: brand,
    overrides: {...?overrides, ...extra},
  );
  ```
  Each getter becomes:
  ```dart
  Color get neutralForeground1 =>
      _o(FluentColorToken.neutralForeground1, _d ? _white : _g(14));
  ```
  The codemod must apply the same transform to `FluentTeamsDarkColors` and `FluentHighContrastColors` in `theme_variants.dart` — they override getters and would otherwise ignore overrides. Then in `theme.dart`:
  ```dart
  /// Overrides individual tokens for a subtree, shallow-merging over the
  /// ancestor theme. The counterpart of a nested `<FluentProvider theme={...}>`
  /// with a `PartialTheme` in Fluent React.
  class FluentThemeOverride extends StatelessWidget {
    const FluentThemeOverride({
      super.key,
      this.colors = const {},
      this.typography,
      required this.child,
    });

    final Map<FluentColorToken, Color> colors;
    final FluentTypography? typography;
    final Widget child;

    @override
    Widget build(BuildContext context) {
      final base = FluentTheme.of(context);
      if (colors.isEmpty && typography == null) return child;
      return FluentTheme(
        data: base.copyWith(
          colors: colors.isEmpty ? null : base.colors.withOverrides(colors),
          typography: typography,
        ),
        child: child,
      );
    }
  }
  ```
- [ ] **Step 4: Run it, verify it passes.**
  ```bash
  cd packages/fluent_2_core && flutter test && cd ../.. && melos run ci
  ```
  Expect: original 27 tests unchanged and green (they are the regression gate for the codemod), plus 3 new tests passing, `ci` green.
- [ ] **Step 5: Commit.**
  ```bash
  git add -A && git commit -m "feat(core): per-token theme override matching React PartialTheme"
  ```

---

## Phase 1 — Shared primitives

Five files, locked and tested before any component. This is the piece that decides whether the remaining 100+ components are consistent.

### Task 5: `FluentInteractive` — interaction state on `WidgetState`

**Design note — this replaces an earlier slots-API port.** The first draft ported
Fluent React's `FluentSlot` verbatim: a sealed class with `.child` / `.props` /
`.as` / `.builder`. It was faithful and wrong for this audience — Flutter
developers do not think in slots. The framework already provides the pieces:

| React lever | Flutter-idiomatic equivalent |
|---|---|
| `icon={<Foo/>}` shorthand | `Widget? icon` — a plain named parameter |
| `icon={{className, onClick}}` | `style:` — a `ButtonStyle`-shaped struct, merged last |
| `as="a"` (whitelisted) | a named constructor, `FluentButton.link(...)` |
| children-as-render-function | an `iconBuilder` callback parameter |
| `icon={null}` | `icon: null` |
| hover / pressed / disabled values | `WidgetStateProperty.resolveWith` |

**`WidgetState`, `WidgetStateProperty`, `WidgetStatePropertyAll` and
`WidgetStatesController` are all exported from `package:flutter/widgets.dart`** —
Flutter 3.22 moved the `MaterialState*` family down to the widgets layer and
renamed it exactly so non-Material libraries could use it. Verified against the
analyzer in this repo: no Material import, no `no-material` violation. Fluent's
`*Rest` / `*Hover` / `*Pressed` / `*Selected` / `*Disabled` token sets map onto
`WidgetState` one-for-one.

Nothing is lost against React parity — `.props` becomes a typed struct rather
than a callback, which is stricter — and the result is the API a Flutter
developer already knows from `ElevatedButton`.

**Files:**
- Create: `packages/fluent_2_web/lib/src/internal/interaction.dart`
- Create: `packages/fluent_2_web/test/internal/interaction_test.dart`

**Interfaces:**
- Produces: `FluentInteractive` (builder widget), `FluentStateColor`.
- Consumed by: every interactive component.

- [ ] **Step 1: Write the failing test.** Cover: hover enters and leaves; press
  and release; `disabled` suppressing hover, press and the callback; and
  focus-visible being **keyboard-only** — `FocusableActionDetector`'s
  `onShowFocusHighlight` is the framework's equivalent of upstream's
  keyborg-driven `data-fui-focus-visible` attribute, and a pointer-focused
  control must not show a ring.
- [ ] **Step 2: Run it, verify it fails.**
  `cd packages/fluent_2_web && flutter test test/internal/interaction_test.dart`
- [ ] **Step 3: Implement.**
  ```dart
  /// Resolves a Fluent token set across interaction states.
  ///
  /// Every Fluent component ships explicit *Hover / *Pressed / *Selected /
  /// *Disabled tokens, so this never computes a colour — it selects one.
  abstract final class FluentStateColor {
    static WidgetStateProperty<Color> tokens({
      required Color rest,
      Color? hover,
      Color? pressed,
      Color? selected,
      Color? disabled,
    }) => WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return disabled ?? rest;
      if (states.contains(WidgetState.pressed)) return pressed ?? rest;
      if (states.contains(WidgetState.hovered)) return hover ?? rest;
      if (states.contains(WidgetState.selected)) return selected ?? rest;
      return rest;
    });
  }
  ```
  `FluentInteractive` owns a `WidgetStatesController`, wires
  `FocusableActionDetector` (hover, focus, focus-highlight, shortcuts) and
  `Listener` (press), and hands the builder the live `Set<WidgetState>`. When
  `enabled` is false it adds `WidgetState.disabled`, clears the rest and skips
  the callback — never a visual-only grey-out.
- [ ] **Step 4: Run it, verify it passes.** Then `melos run ci`.
- [ ] **Step 5: Commit.**

---

### Task 6: *(merged into Task 5)*

Originally the interaction-state primitive. Once Task 5 stopped being a slots
port and became the interaction primitive itself — built on the framework's
`WidgetState` rather than a bespoke state class — the two tasks were the same
work. Numbering is left intact so later task references stay valid.

No separate style base class is planned: Material does not have one either
(`ButtonStyle`, `CardTheme`, `SliderThemeData` are independent), and an
abstraction with a single implementation is exactly what this codebase avoids.
Each component owns its `Fluent<Name>Style` with `copyWith` / `merge` / `lerp`,
and its `Fluent<Name>Theme` inherited override. The convention is fixed by the
Task 10 reference implementation and copied from there.

---

### Task 7: `FluentFocusRing`

**Design conflict, resolved toward Figma.** The Figma release draws two rings — an outer 2px stroke aligned `OUTSIDE` and an inner 1px stroke aligned `INSIDE`. React v9 draws **one** ring (`createFocusOutlineStyle.ts:104-107`: `::after`, `2px solid colorStrokeFocus2`, `borderRadiusMedium`, offset `-2px`); `colorStrokeFocus1` is unused in react-tabster, and the two-tone ring lives in Fluent web-components v3. This port targets the Figma release, so it draws two rings and `FluentFocusRing.singleRing` is provided for React-identical output.

**Files:**
- Create: `packages/fluent_2_web/lib/src/internal/focus_ring.dart`
- Create: `packages/fluent_2_web/test/internal/focus_ring_test.dart`

**Interfaces:**
- Consumes: `FluentInteractionState.focusVisible` (Task 6).
- Produces: `FluentFocusRing`, `FluentFocusRingPainter`.

- [ ] **Step 1: Write the failing test.**
  ```dart
  // packages/fluent_2_web/test/internal/focus_ring_test.dart
  import 'package:flutter/widgets.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:fluent_2_web/fluent_2_web.dart';

  void main() {
    testWidgets('paints nothing when not focus-visible', (tester) async {
      await tester.pumpWidget(const Directionality(
        textDirection: TextDirection.ltr,
        child: FluentFocusRing(
          visible: false,
          radius: FluentRadius.allMedium,
          child: SizedBox(width: 90, height: 32),
        ),
      ));
      final painter = tester.widget<CustomPaint>(find.byType(CustomPaint).first);
      expect((painter.foregroundPainter! as FluentFocusRingPainter).visible, isFalse);
    });

    testWidgets('two-tone ring inverts between light and dark', (tester) async {
      Future<FluentFocusRingPainter> ringFor(FluentThemeData theme) async {
        await tester.pumpWidget(FluentTheme(
          data: theme,
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: FluentFocusRing(
              visible: true,
              radius: FluentRadius.allMedium,
              child: SizedBox(width: 90, height: 32),
            ),
          ),
        ));
        return tester.widget<CustomPaint>(find.byType(CustomPaint).first)
            .foregroundPainter! as FluentFocusRingPainter;
      }

      final light = await ringFor(FluentThemeData.light());
      final dark = await ringFor(FluentThemeData.dark());
      expect(light.outer, isNot(dark.outer));
      expect(light.inner, isNot(dark.inner));
      expect(light.outer, dark.inner, reason: 'the two tones swap, they do not recolour');
      expect(light.outerWidth, 2.0);
      expect(light.innerWidth, 1.0);
    });

    testWidgets('high contrast keeps the ring opaque', (tester) async {
      await tester.pumpWidget(FluentTheme(
        data: FluentThemeData.highContrast(),
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: FluentFocusRing(
            visible: true,
            radius: FluentRadius.allMedium,
            child: SizedBox(width: 90, height: 32),
          ),
        ),
      ));
      final p = tester.widget<CustomPaint>(find.byType(CustomPaint).first)
          .foregroundPainter! as FluentFocusRingPainter;
      expect(p.outer.a, 1.0);
      expect(p.inner.a, 1.0);
    });
  }
  ```
- [ ] **Step 2: Run it, verify it fails.**
  ```bash
  cd packages/fluent_2_web && flutter test test/internal/focus_ring_test.dart
  ```
  Expect: compile failure — `FluentFocusRing` undefined.
- [ ] **Step 3: Implement** as a `CustomPaint` foreground painter. Outer stroke 2.0 painted on a rect inflated by 1.0 (stroke centred on the +2 boundary, giving Figma's `OUTSIDE` alignment); inner stroke 1.0 painted on a rect deflated by 0.5 (Figma's `INSIDE`). Radii adjust by the same deltas so corners stay concentric. Colours come from `theme.colors.strokeFocus2` (outer) and `strokeFocus1` (inner) — they already invert per brightness, which the test asserts. Expose `outer`, `inner`, `outerWidth`, `innerWidth`, `visible` as public fields for testability, and implement `shouldRepaint` against all five. `FluentFocusRing.singleRing` sets `innerWidth: 0` for React-identical output. No animation — upstream's ring appears instantly.
- [ ] **Step 4: Run it, verify it passes.**
  ```bash
  cd packages/fluent_2_web && flutter test test/internal/focus_ring_test.dart
  ```
  Expect: 3 tests pass.
- [ ] **Step 5: Commit.**
  ```bash
  git add -A && git commit -m "feat(web): FluentFocusRing two-tone focus indicator"
  ```

---

### Task 8: `FluentAnimatedStyle` — the motion primitive

Upstream animates state changes with a CSS `transition` on specific properties. This wraps that: implicitly tween a resolved style, honouring reduced motion.

**Files:**
- Create: `packages/fluent_2_web/lib/src/internal/animated_style.dart`
- Create: `packages/fluent_2_web/test/internal/animated_style_test.dart`

**Interfaces:**
- Produces: `FluentAnimatedStyle<T>`, `FluentMotionSpec`.
- Consumed by: every animated component.

- [ ] **Step 1: Write the failing test.**
  ```dart
  // packages/fluent_2_web/test/internal/animated_style_test.dart
  import 'package:flutter/widgets.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:fluent_2_web/fluent_2_web.dart';

  void main() {
    testWidgets('tweens colour over the spec duration', (tester) async {
      Widget build(Color c) => Directionality(
        textDirection: TextDirection.ltr,
        child: FluentAnimatedStyle<Color>(
          value: c,
          spec: const FluentMotionSpec(
            duration: FluentDuration.faster,
            curve: FluentCurve.easyEase,
          ),
          lerp: Color.lerp,
          builder: (context, v) => ColoredBox(key: const Key('box'), color: v!),
        ),
      );

      await tester.pumpWidget(build(const Color(0xFF000000)));
      await tester.pumpWidget(build(const Color(0xFFFFFFFF)));
      await tester.pump(const Duration(milliseconds: 50)); // half of 100ms
      final mid = tester.widget<ColoredBox>(find.byKey(const Key('box'))).color;
      expect(mid, isNot(const Color(0xFF000000)));
      expect(mid, isNot(const Color(0xFFFFFFFF)));
      await tester.pumpAndSettle();
      expect(tester.widget<ColoredBox>(find.byKey(const Key('box'))).color,
          const Color(0xFFFFFFFF));
    });

    testWidgets('reduced motion jumps instantly', (tester) async {
      Widget build(Color c) => MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: FluentAnimatedStyle<Color>(
            value: c,
            spec: const FluentMotionSpec(
              duration: FluentDuration.faster,
              curve: FluentCurve.easyEase,
            ),
            lerp: Color.lerp,
            builder: (context, v) => ColoredBox(key: const Key('box'), color: v!),
          ),
        ),
      );
      await tester.pumpWidget(build(const Color(0xFF000000)));
      await tester.pumpWidget(build(const Color(0xFFFFFFFF)));
      await tester.pump(Duration.zero);
      expect(tester.widget<ColoredBox>(find.byKey(const Key('box'))).color,
          const Color(0xFFFFFFFF));
    });
  }
  ```
- [ ] **Step 2: Run it, verify it fails.**
  ```bash
  cd packages/fluent_2_web && flutter test test/internal/animated_style_test.dart
  ```
  Expect: compile failure — `FluentAnimatedStyle` undefined.
- [ ] **Step 3: Implement.** `FluentMotionSpec` is `{Duration duration, Curve curve}` with named constants for the specs in Appendix B (`FluentMotionSpec.buttonSurface`, `.switchTrack`, `.switchThumb`, `.tabIndicator`, `.fade`, `.collapse`, `.scaleEnter`, `.scaleExit`, `.slideEnter`, `.slideExit`). `FluentAnimatedStyle<T>` is an `ImplicitlyAnimatedWidget` subclass driven by a caller-supplied `lerp`; `duration` resolves to `Duration.zero` when `MediaQuery.disableAnimationsOf(context)` is true.
- [ ] **Step 4: Run it, verify it passes.**
  ```bash
  cd packages/fluent_2_web && flutter test test/internal/animated_style_test.dart && cd ../.. && melos run ci
  ```
  Expect: 2 tests pass, `ci` green.
- [ ] **Step 5: Commit.**
  ```bash
  git add -A && git commit -m "feat(web): FluentAnimatedStyle motion primitive"
  ```

---

### Task 9: The spec-fixture harness

Pixel fidelity is proven by asserting resolved geometry and colour against numbers extracted from Figma. This is font-independent and runs offline, which golden images cannot do — Segoe UI is absent in CI.

**Files:**
- Create: `tool/extract_component_spec.dart`
- Create: `packages/fluent_2_web/test/support/spec_fixture.dart`
- Create: `packages/fluent_2_web/test/fixtures/README.md`

**Interfaces:**
- Produces, all from `test/support/spec_fixture.dart`:
  - `SpecFixture loadSpec(String component)` — reads `test/fixtures/<component>.json`
  - `void expectSpec(WidgetTester, Finder, SpecVariant)` — the geometry/colour matcher
  - `Color surfaceColorOf(WidgetTester tester, {Finder? of})` — resolved background of the
    nearest `DecoratedBox` under the target; used to assert motion mid-tween
  - `BorderRadius resolvedRadiusOf(WidgetTester tester, {Finder? of})` — same, for radius
  - `TextStyle resolvedTextStyleOf(WidgetTester tester, {Finder? of})` — font size and line
    height only; never the rendered glyph box
- Consumed by: every component test from Task 10 onward.

- [ ] **Step 1: Define and document the fixture format** in `test/fixtures/README.md`:
  ```json
  {
    "component": "Button",
    "figmaNodeId": "9026:430",
    "variants": [
      {
        "name": "Style=Primary, State=Rest, Size=Medium (Default), Layout=Icon and label (Default)",
        "props": {"style": "Primary", "state": "Rest", "size": "Medium", "layout": "IconAndLabel"},
        "size": {"w": 94, "h": 32},
        "padding": {"t": 6, "r": 12, "b": 6, "l": 12},
        "gap": 6,
        "radius": 4,
        "strokeWidth": 2,
        "fill": "#0F6CBD",
        "tokens": {
          "paddingLeft": "Spacing/Horizontal/M",
          "paddingTop": "Spacing/Vertical/SNudge",
          "itemSpacing": "Spacing/Horizontal/SNudge",
          "radius": "Button/Container",
          "fill": "Brand/Background/1/Rest"
        },
        "text": {"family": "Segoe UI", "style": "Semibold", "size": 14, "lineHeight": 20}
      }
    ]
  }
  ```
- [ ] **Step 2: Write `tool/extract_component_spec.dart`.** For a given component-set node id it walks every variant via `use_figma`, emitting the record above. The traversal script is the one already validated against Button:
  ```js
  const page = await figma.getNodeByIdAsync(PAGE_ID);
  await figma.setCurrentPageAsync(page);
  const set = await figma.getNodeByIdAsync(SET_ID);
  const out = [];
  for (const v of set.children) {
    const bv = {};
    for (const [k, ref] of Object.entries(v.boundVariables || {})) {
      const refs = Array.isArray(ref) ? ref : [ref];
      const names = [];
      for (const r of refs) {
        if (r && r.id) {
          const varo = await figma.variables.getVariableByIdAsync(r.id);
          names.push(varo ? varo.name : r.id);
        }
      }
      bv[k] = names;
    }
    out.push({
      name: v.name,
      size: {w: v.width, h: v.height},
      padding: {t: v.paddingTop, r: v.paddingRight, b: v.paddingBottom, l: v.paddingLeft},
      gap: v.itemSpacing, radius: v.cornerRadius, strokeWidth: v.strokeWeight,
      fills: v.fills, tokens: bv,
    });
  }
  return out;
  ```
- [ ] **Step 3: Write the matcher** in `test/support/spec_fixture.dart`:
  ```dart
  /// Asserts a rendered widget matches its Figma-extracted spec.
  ///
  /// Compares size, padding, gap, radius, stroke width and resolved fill.
  /// Text metrics are compared as font SIZE and LINE HEIGHT only — never the
  /// rendered glyph box, because Segoe UI is not installed in CI.
  void expectSpec(WidgetTester tester, Finder target, SpecVariant spec) { ... }
  ```
- [ ] **Step 4: Prove the harness on Button's Primary/Rest/Medium variant.**
  ```bash
  cd packages/fluent_2_web && flutter test test/support/
  ```
  Expect: harness self-test passes against the committed Button fixture.
- [ ] **Step 5: Commit.**
  ```bash
  git add -A && git commit -m "feat(web): Figma spec-fixture test harness"
  ```

---

## Phase 2 — Reference component

### Task 10: `FluentButton` — the recomposition contract, proven end to end

Button is the reference implementation. Every later component copies its file layout, its three-function split, and its test shape. **Do not start Phase 3 until this task is reviewed and merged.**

The three-function split mirrors React exactly. Upstream: `useButton_unstable(props, ref) → ButtonState`, `useButtonStyles_unstable(state) → ButtonState` (mutates `className` in place), `renderButton_unstable(state)` — and critically, **render is typed against `ButtonBaseState`** (`Omit<ButtonState, 'appearance'|'size'|'shape'>`), which is what makes "Fluent state + my styles + Fluent render" first-class. Dart mirrors that with an inheritance pair rather than mutation.

**Files:**
- Create: `packages/fluent_2_web/lib/src/buttons/button.dart`
- Create: `packages/fluent_2_web/lib/src/buttons/button_state.dart`
- Create: `packages/fluent_2_web/lib/src/buttons/button_style.dart`
- Modify: `packages/fluent_2_web/lib/fluent_2_web.dart` (export the above)
- Create: `packages/fluent_2_web/test/buttons/button_test.dart`
- Create: `packages/fluent_2_web/test/fixtures/button.json`

**Interfaces:**
- Consumes: `FluentSlot` (T5), `FluentInteraction` (T6), `FluentFocusRing` (T7), `FluentAnimatedStyle` (T8), `expectSpec` (T9).
- Produces, and every later component mirrors these names:
  - `FluentButtonBaseState` — no appearance/size/shape
  - `FluentButtonState extends FluentButtonBaseState` — adds `appearance`, `size`, `shape`
  - `FluentButtonStyle` with `merge(FluentButtonStyle?)` and `lerp(FluentButtonStyle?, double)`
  - `FluentButtonState resolveFluentButtonState({...})`
  - `FluentButtonStyle resolveFluentButtonStyle(FluentButtonState, FluentThemeData)`
  - `Widget buildFluentButton(FluentButtonBaseState, FluentButtonStyle)` — takes **base** state
  - `class FluentButton extends StatelessWidget` — thin composition of the three

- [ ] **Step 1: Extract the fixture.** Run `tool/extract_component_spec.dart` against set `9026:430` (150 variants: Style × State × Size × Layout) into `test/fixtures/button.json`.
- [ ] **Step 2: Write the failing test.**
  ```dart
  // packages/fluent_2_web/test/buttons/button_test.dart
  import 'package:flutter/widgets.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:fluent_2_web/fluent_2_web.dart';
  import '../support/spec_fixture.dart';

  void main() {
    final spec = loadSpec('button');

    testWidgets('every Figma variant matches its spec', (tester) async {
      for (final v in spec.variants) {
        await tester.pumpWidget(FluentApp(
          home: Center(child: FluentButton(
            appearance: v.appearance,
            size: v.size,
            icon: v.hasIcon ? const FluentSlot.child(Icon(FluentIcons.add_20_regular)) : null,
            onPressed: v.disabled ? null : () {},
            child: const Text('Button'),
          )),
        ));
        expectSpec(tester, find.byType(FluentButton), v);
      }
    });

    testWidgets('hover background animates over 100ms easyEase', (tester) async {
      // upstream: transitionProperty 'background, border, color',
      // durationFaster (100ms), curveEasyEase — useButtonStyles.styles.ts
      await tester.pumpWidget(FluentApp(
        home: Center(child: FluentButton(onPressed: () {}, child: const Text('B'))),
      ));
      final rest = surfaceColorOf(tester);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: tester.getCenter(find.byType(FluentButton)));
      addTearDown(mouse.removePointer);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(surfaceColorOf(tester), isNot(rest));      // mid-tween
      await tester.pumpAndSettle();
      expect(surfaceColorOf(tester),
          FluentThemeData.light().colors.neutralBackground1Hover);
    });

    testWidgets('recomposition: caller may substitute the style function',
        (tester) async {
      final state = resolveFluentButtonState(
        appearance: FluentButtonAppearance.primary,
        size: FluentButtonSize.medium,
        enabled: true,
      );
      final mine = resolveFluentButtonStyle(state, FluentThemeData.light())
          .merge(const FluentButtonStyle(radius: FluentRadius.allCircular));
      await tester.pumpWidget(FluentApp(
        home: Center(child: buildFluentButton(state, mine)),  // base state accepted
      ));
      expect(resolvedRadiusOf(tester), FluentRadius.allCircular);
    });

    testWidgets('slot builder escape hatch replaces the icon element',
        (tester) async {
      await tester.pumpWidget(FluentApp(
        home: Center(child: FluentButton(
          onPressed: () {},
          icon: FluentSlot.builder((context, props, child) =>
              SizedBox(key: const Key('mine'), width: props.size)),
          child: const Text('B'),
        )),
      ));
      expect(find.byKey(const Key('mine')), findsOneWidget);
    });

    testWidgets('subtree token override reaches the button', (tester) async {
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(FluentApp(
        home: FluentThemeOverride(
          colors: const {FluentColorToken.brandBackground: magenta},
          child: Center(child: FluentButton(
            appearance: FluentButtonAppearance.primary,
            onPressed: () {},
            child: const Text('B'),
          )),
        ),
      ));
      expect(surfaceColorOf(tester), magenta);
    });

    testWidgets('disabled is non-interactive, not just greyed', (tester) async {
      var fired = false;
      await tester.pumpWidget(FluentApp(
        home: Center(child: FluentButton(
          onPressed: null, child: const Text('B'))),
      ));
      await tester.tap(find.byType(FluentButton));
      expect(fired, isFalse);
    });
  }
  ```
- [ ] **Step 3: Run it, verify it fails.**
  ```bash
  cd packages/fluent_2_web && flutter test test/buttons/button_test.dart
  ```
  Expect: compile failure — `FluentButton` undefined.
- [ ] **Step 4: Implement** the three files. `button_state.dart` holds the base/full state pair, `button_style.dart` the style with `merge`/`lerp`, `button.dart` the three functions plus the `FluentButton` widget. `FluentButton.build` is only:
  ```dart
  @override
  Widget build(BuildContext context) {
    final state = resolveFluentButtonState(
      appearance: appearance, size: size, shape: shape,
      icon: icon, iconPosition: iconPosition,
      enabled: onPressed != null, child: child,
    );
    final resolved = resolveFluentButtonStyle(state, FluentTheme.of(context));
    // Consumer style merged LAST — upstream passes props.className as the final
    // mergeClasses argument, so whatever the caller supplies wins.
    return buildFluentButton(state, resolved.merge(style));
  }
  ```
- [ ] **Step 5: Run it, verify it passes.**
  ```bash
  cd packages/fluent_2_web && flutter test && cd ../.. && melos run ci
  ```
  Expect: all Button tests pass including all 150 fixture variants; `ci` green.
- [ ] **Step 6: Commit.**
  ```bash
  git add -A && git commit -m "feat(web): FluentButton — reference component and recomposition contract"
  ```

---

## Phase 3 — Component fan-out

104 component sets across 45 Figma pages. Dot-prefixed sets (`.RadioBase`, `.Selection`, `.Spin button stepper`) are internal subcomponents built as part of their parent's task, not as public widgets.

### The per-component task contract

Every component task in this phase is identical in shape. One agent per component, dispatched in waves; a component may only start once every component it consumes has merged.

**Files (substitute `<name>` and `<category>`):**
- Create: `packages/fluent_2_web/lib/src/<category>/<name>.dart`, `<name>_state.dart`, `<name>_style.dart`
- Modify: `packages/fluent_2_web/lib/fluent_2_web.dart` (exports)
- Create: `packages/fluent_2_web/test/<category>/<name>_test.dart`
- Create: `packages/fluent_2_web/test/fixtures/<name>.json`

**The agent prompt, verbatim:**

> Implement `Fluent<Name>` in `packages/fluent_2_web`, matching the official Microsoft Fluent 2 release.
>
> 1. **Read the reference first.** `packages/fluent_2_web/lib/src/buttons/button.dart`, `button_state.dart`, `button_style.dart` and `test/buttons/button_test.dart`. Your files mirror that structure exactly — same three-function split, same naming scheme, same test shape. Do not invent a different pattern.
> 2. **Extract the spec.** Run `tool/extract_component_spec.dart` against Figma file `Heyk4N9SnwfIzupHlk3l7s`, page `<pageNodeId>`, component set `<setNodeId>`. Commit the result as `test/fixtures/<name>.json`. Every variant in the set becomes a fixture row.
> 3. **Write the failing test first**, covering: every fixture variant via `expectSpec`; the motion spec from Appendix B (assert mid-tween and settled values, or assert *instant* change where the spec says no transition); the slot escape hatch on at least one slot; a subtree `FluentThemeOverride`; and disabled being non-interactive.
> 4. **Implement.** Constraints: no Material or Cupertino; interactive state comes from `FluentInteraction`; focus from `FluentFocusRing`; animation from `FluentAnimatedStyle`; every replaceable part is a `FluentSlot`; consumer `style` merges LAST. Reach for `CustomPaint` when painting beats widget composition — checkmarks, indicator rails, rating shapes, spinner arcs.
> 5. **Never compute a colour.** If you find yourself calling `withOpacity` or blending, you are using the wrong token — find the correct `*Hover`/`*Pressed`/`*Selected`/`*Disabled` alias.
> 6. **Verify.** `melos run ci` must be green. Report the variant count covered and any Figma-vs-React conflict you hit, with both values and your resolution.

**Acceptance gate (every task):** `melos run ci` green; fixture covers 100% of the set's variants; motion asserted against Appendix B; no `withOpacity` on a token; no hardcoded `Colors.transparent`.

---

### Wave 1 — Leaves (no component dependencies)

Dispatch all in parallel.

- [ ] **Task 11:** `Divider` — set `Divider` (6 variants), page `8911:3192`
- [ ] **Task 12:** `Label` — set `Label` (10), page `8934:5`
- [ ] **Task 13:** `Link` — set `Link` (15), page `8934:6`
- [ ] **Task 14:** `Badge` + `PresenceBadge` — sets `Badge` (112), `Presence Badge` (96), page `8911:3186`
- [ ] **Task 15:** `Skeleton` — set `Skeleton` (12), page `8934:14`. Motion: wave 3s ease-in-out infinite `translate(-100%)`→`translate(100%)`; pulse 1s ease-in-out infinite opacity 1→0.4→1
- [ ] **Task 16:** `Spinner` — sets `Spinner` (64), `.SpinnerBase` (32), page `8934:17`. Motion: 1.5s linear 0→360° ring plus a 1.5s `curveEasyEase` tail. `CustomPaint`
- [ ] **Task 17:** `ProgressBar` — sets `Static_ProgressBar` (10), `Animated_ProgressBar` (38), page `8934:12`. Motion: indeterminate 3000ms `curveLinear` infinite, translate −100%→300%
- [ ] **Task 18:** `Tooltip` — set `Tooltip` (3), page `8934:25`. **No motion** — upstream has none on master; the old slide path is deprecated
- [ ] **Task 19:** `MaterialAcrylic` — set `Material acrylic` (1), page `8994:47268`. `BackdropFilter` + the `Material/Acrylic/*` tokens from Task 3
- [ ] **Task 20:** `StatusIndicator` — set `.StatusIndicator` (48), page `8995:8`. Depends on Task 3 status tokens

### Wave 2 — Simple interactives (need Wave 1 + primitives)

- [ ] **Task 21:** `Checkbox` — set `Checkbox` (30), page `8911:3190`. **No transitions** — upstream `useCheckboxStyles.styles.ts` contains none; assert the change is instant. `CustomPaint` checkmark
- [ ] **Task 22:** `Radio` + `RadioGroup` — sets `Radio` (30), `RadioGroup` (3), `.RadioBase` (6), page `8934:13`
- [ ] **Task 23:** `Switch` — sets `Switch` (40), `.SwitchBase` (6), page `8934:18`. Motion: track `background, border, color` 200ms `curveEasyEase`; thumb `transform` 200ms `curveEasyEase`; travel `translateX(20)` medium, `translateX(16)` small
- [ ] **Task 24:** `Slider` — set `Slider` (10), page `8934:15`
- [ ] **Task 25:** `SplitButton` + `MenuButton` + `CompoundButton` — sets `Split button` (150), `Compound button` (75), `.Secondary action` (25), page `8911:3188`. Reuses Task 10
- [ ] **Task 26:** `Avatar` + `AvatarGroup` — sets `Avatar/Avatar` (39), `Avatar/Avatar group` (2), `Avatar/Avatar pie` (26), page `8911:3185`. Needs Task 3 palette tokens
- [ ] **Task 27:** `Swatch` + `SwatchPicker` — sets `Swatch` (48), `SwatchPicker` (14), page `8995:9`
- [ ] **Task 28:** `Rating` — set `Rating` (36), page `8995:6`. `CustomPaint` star/circle/square
- [ ] **Task 29:** `Tag` + `InteractionTag` — sets `Tag` (60), `Interaction tag` (168), plus 3 `.Secondary action` sets, page `8934:20`. Largest set in the file
- [ ] **Task 30:** `Card` — sets `Card` (28), `.Card header`/`footer`/`body`/`media`, page `8911:3189`
- [ ] **Task 31:** `Accordion` — set `Accordion` (24), page `8911:3184`. Motion: Collapse 200ms `curveEasyEaseMax`; chevron `transform` 200ms ease-out

### Wave 3 — Inputs (need Wave 2)

- [ ] **Task 32:** `Input` — set `Input` (84), page `8934:4`. `EditableText`
- [ ] **Task 33:** `Textarea` — sets `Textarea` (63), `.Text` (3), page `8934:21`
- [ ] **Task 34:** `SearchBox` — set `SearchBox` (36), page `8995:7`
- [ ] **Task 35:** `SpinButton` — sets `Spin button` (56), `.Spin button stepper` (8), page `8934:16`
- [ ] **Task 36:** `Field` — set `Field` (3), page `8911:3195`. Composes Label + Input
- [ ] **Task 37:** `InfoLabel` — sets `InfoLabel` (3), `.Info button` (15), page `8911:3196`
- [ ] **Task 38:** `Dropdown` — sets `Dropdown` (24), `.ListItem` (11), `List content` (2), page `8911:3194`
- [ ] **Task 39:** `MessageBar` — set `Message bar` (2), page `8934:8`. Needs Task 3 status tokens

### Wave 4 — Surfaces and overlays (need Wave 3)

- [ ] **Task 40:** `Popover` — set `Popover` (3), page `8934:11`. Motion: enter-only fade + direction-aware slide, 400ms `curveDecelerateMid`, distance 10px, **no exit animation**
- [ ] **Task 41:** `Menu` — sets `Menu/Menu` (2), `Menu item` (7), `Menu section` (3), `Menu split item` (7), `.Item split button` (5), page `8934:7`. Same motion as Popover
- [ ] **Task 42:** `Dialog` — set `Dialog` (4), page `8911:3191`. Motion: surface Scale `outScale 0.85`, 250ms, `decelerateMid` in / `accelerateMin` out; backdrop FadeRelaxed 250ms `curveEasyEase`
- [ ] **Task 43:** `Drawer` — sets `Drawer` (2), `.Overlay drawer` (3), `.Inline drawer` (9), `.Drawer header` (2), `.Drawer footer`, page `8911:3193`. Motion: size-keyed duration — small 250 / medium 300 / large 400 / full 500; `decelerateMid` in, `accelerateMin` out
- [ ] **Task 44:** `Toast` — loose component `Toast`, page `8934:22`. Motion: `CollapseDelayed`
- [ ] **Task 45:** `TeachingPopover` — sets `Teaching Popover` (2) + 2 footer sets, page `8995:11`. Inherits Popover's motion
- [ ] **Task 46:** `Tablist` + `Tab` — sets `Horizontal TabList` (12), `Vertical TabList` (12), `Horizontal Tab` (80), `Vertical Tab` (80), page `8934:19`. Motion: FLIP indicator, `transform` 300ms `curveDecelerateMax`, `transformOrigin` left (horizontal) / top (vertical)
- [ ] **Task 47:** `Toolbar` — set `Toolbar` (6), page `8934:24`
- [ ] **Task 48:** `Breadcrumb` — sets `Breadcrumb` (3), `.Breadcrumb Item` (51), page `8911:3187`

### Wave 5 — Composites (need Wave 4)

- [ ] **Task 49:** `Persona` — set `Persona` (16), page `8934:10`. Composes Avatar + PresenceBadge
- [ ] **Task 50:** `ListItem` — sets `ListItem` (40), `.Selection` (3), `.Selection (Small)` (3), page `8995:4`
- [ ] **Task 51:** `TagPicker` — sets `Tag picker/TagPicker` (72), `TagPicker/Item` (6), `TagPicker/Secondary action` (3), `TagPicker/Dropdown` (2), page `8995:10`
- [ ] **Task 52:** `Nav` — sets `NavNode - medium` (15), `NavNode - small` (15), `NavSubItem` (6), `App item - medium/small` (3+3), `.Chevron` (2), page `8995:5`
- [ ] **Task 53:** `Tree` — sets `Tree item` (60), `.Tree item chevron` (2), page `8934:23`
- [ ] **Task 54:** `DataGrid` — sets `DataGrid cell - Small/Smaller/Medium/Large` (7+7+7+8), `.Content header` (4), `.Cell action header` (2), page `8995:3`
- [ ] **Task 55:** `Carousel` — sets `Carousel` (15), `.CarouselNav` (4), `.Carousel steps` (5), `.Carousel step` (6), `.Carousel play control` (2), `.Images Preview Step` (2), page `8995:2`

### Task 56: Gallery example app

**Files:** create `example/` — a `FluentApp` with a nav listing every component, light/dark/high-contrast/Teams theme switching, and a live `FluentThemeOverride` token editor.

- [ ] **Step 1:** Scaffold `example/pubspec.yaml` depending on `fluent_2_web` via `resolution: workspace`.
- [ ] **Step 2:** One page per component, rendering every variant from its fixture.
- [ ] **Step 3:** Theme switcher exercising all four `FluentThemeData` constructors plus a brand-ramp picker fed by `FluentBrandRamp.fromKeyColor`.
- [ ] **Step 4:** `flutter run -d macos` in `example/` and confirm every page renders.
- [ ] **Step 5:** Commit.

---

## Appendix A — Extensibility parity checklist

Verify at the end of Phase 2 and again at the end of Phase 3. Every row must be demonstrable in a test.

| React v9 | Evidence | Flutter port | Status |
|---|---|---|---|
| `icon={<Foo/>}` shorthand renders inside the slot element | `slot.ts:82-106` `resolveShorthand` | `FluentSlot.child` | Task 5 |
| `icon={{...}}` props merge | `types.ts:138-157` | `FluentSlot.props` | Task 5 |
| `as="a"` restricted to whitelisted tags | `Button.types.ts:4-14` `Slot<'button','a'>` | `FluentSlot.as` + per-component whitelist enum | Task 5 |
| children-as-render-function escape hatch | `types.ts:16` `SlotRenderFunction` | `FluentSlot.builder` | Task 5 |
| `null` slot suppresses | `types.ts:138-157` | `null` slot | Task 5 |
| `className` merged last, consumer wins | `StylingComponents.mdx` "the latest wins" | `style` merged last in `build` | Task 10 |
| `useButton_unstable` | `useButton.ts` | `resolveFluentButtonState` | Task 10 |
| `useButtonStyles_unstable` | `useButtonStyles.styles.ts` | `resolveFluentButtonStyle` | Task 10 |
| `renderButton_unstable` typed against **base** state | `renderButton.tsx` | `buildFluentButton(FluentButtonBaseState, …)` | Task 10 |
| Skipping the styles hook is supported | base-state-hooks RFC | base state accepted by `build*` | Task 10 |
| Nested `FluentProvider` shallow-merges a `PartialTheme` | `useFluentProvider.ts` `shallowMerge` | `FluentThemeOverride` | Task 4 |
| Single-token override for a subtree | `createCSSRuleFromTheme` | `FluentColorToken` map | Task 4 |
| Custom brand ramp | `createLightTheme(brand)` | `FluentBrandRamp.fromKeyColor` (already shipped) | done |

## Appendix B — Motion specification

All values verbatim from `microsoft/fluentui@master`. Every entry clamps to `Duration.zero` under reduced motion.

| Component | Property | Duration | Curve |
|---|---|---|---|
| Button root | `background, border, color` | `durationFaster` 100ms | `curveEasyEase` (0.33,0,0.67,1) |
| Checkbox | — | **none — instant, deliberately** | — |
| Switch track | `background, border, color` | `durationNormal` 200ms | `curveEasyEase` |
| Switch thumb | `transform`, `translateX(20)` md / `(16)` sm | 200ms | `curveEasyEase` |
| Tab indicator | `transform` (FLIP offset+scale) | `durationSlow` 300ms | `curveDecelerateMax` (0.1,0.9,0.2,1) |
| Fade | opacity | 200ms both ways | `curveEasyEase` |
| Collapse | height | 200ms both ways | `curveEasyEaseMax` |
| Scale | scale | enter 250ms / exit 200ms | `decelerateMax` in / `accelerateMax` out |
| Slide | translate | 200ms both ways | `decelerateMid` in / `accelerateMid` out |
| Dialog surface | scale, `outScale 0.85` | 250ms | `decelerateMid` in / `accelerateMin` out |
| Dialog backdrop | opacity (FadeRelaxed) | 250ms | `curveEasyEase` |
| Drawer | translate | 250 / 300 / 400 / 500 by size | `decelerateMid` in / `accelerateMin` out |
| Popover, Menu | fade + 10px directional slide, **enter only** | `durationSlower` 400ms | `curveDecelerateMid` |
| Accordion panel | Collapse | 200ms | `curveEasyEaseMax` |
| Accordion chevron | `transform` | 200ms | ease-out |
| Toast | CollapseDelayed | 200ms | `curveEasyEaseMax` |
| Tooltip | — | **none on master** | — |
| Spinner | rotate 0→360° | 1.5s infinite | `curveLinear` (+ 1.5s `curveEasyEase` tail) |
| ProgressBar indeterminate | translate −100%→300% | 3000ms infinite | `curveLinear` |
| Skeleton wave | translate −100%→100% | 3s infinite | ease-in-out |
| Skeleton pulse | opacity 1→0.4→1 | 1s infinite | ease-in-out |

## Appendix C — Known upstream conflicts

1. **Focus ring.** Figma ships two rings (outer 2px `OUTSIDE`, inner 1px `INSIDE`); React v9 ships one (`createFocusOutlineStyle.ts:104-107`, 2px `colorStrokeFocus2`, radius 4, offset −2px). `colorStrokeFocus1` is unused in react-tabster; the two-tone ring lives in Fluent web-components v3. **Resolved toward Figma**; `FluentFocusRing.singleRing` gives React-identical output.
2. **Focus ring width.** Upstream hardcodes `'2px'` with `// FIXME: tokens.strokeWidthThick causes some weird bugs`. `strokeWidthThick` is also `2px`, so the port uses `FluentStroke.thick` and notes the upstream quirk.
3. **`borderRadiusCircular`.** Upstream `10000px`, core `9999`. Harmless; left as-is.
4. **`body2Strong`.** Does not exist upstream on web; aliased to `subtitle2`. Already documented in core.
5. **Web `subtitle1` line height.** The Community Figma token resolves to 28;
   the current Fluent Web typography table specifies 20/26. The
   platform-specific ramp follows the published platform table.
