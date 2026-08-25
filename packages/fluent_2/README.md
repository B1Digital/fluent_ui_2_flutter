<p align="center">
  <img src="https://raw.githubusercontent.com/B1Digital/fluent_ui_2_flutter/main/assets/fluent_2_flutter.png" width="112" alt="Fluent 2 for Flutter" />
</p>

<h1 align="center">fluent_2</h1>

<p align="center">
  <b>Microsoft Fluent 2 for Flutter — web &amp; desktop.</b><br />
  90+ components, 20 chart types, 4 themes, 135 locales.<br />
  Built on <code>package:flutter/widgets.dart</code>. Zero Material. Zero Cupertino.
</p>

<p align="center">
  <a href="https://pub.dev/packages/fluent_2"><img src="https://img.shields.io/pub/v/fluent_2?logo=dart&color=0F6CBD&label=pub" alt="pub version" /></a>
  <a href="https://b1digital.github.io/fluent_ui_2_flutter/"><img src="https://img.shields.io/badge/live-showroom-0F6CBD?logo=googlechrome&logoColor=white" alt="live showroom" /></a>
  <a href="https://github.com/B1Digital/fluent_ui_2_flutter/actions"><img src="https://img.shields.io/github/actions/workflow/status/B1Digital/fluent_ui_2_flutter/test.yml?branch=main&label=CI" alt="CI" /></a>
  <img src="https://img.shields.io/badge/material-free-107C10" alt="no material" />
  <a href="https://github.com/B1Digital/fluent_ui_2_flutter/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT" /></a>
</p>

<p align="center">
  <a href="https://b1digital.github.io/fluent_ui_2_flutter/"><b>▶ Open the live showroom</b></a>
  &nbsp;·&nbsp;
  <a href="https://b1digital.github.io/fluent_ui_2_flutter/#/docs/components-button-button">Components</a>
  &nbsp;·&nbsp;
  <a href="https://b1digital.github.io/fluent_ui_2_flutter/#/docs/charts-linechart">Charts</a>
  &nbsp;·&nbsp;
  <a href="https://b1digital.github.io/fluent_ui_2_flutter/#/docs/theme-colors">Theme</a>
</p>

---

## Install

```yaml
dependencies:
  fluent_2: ^0.0.1
```

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
```

One import gets you components *and* tokens — `fluent_2` re-exports `fluent_2_core`.

---

## Showcase

Every image below is a real render of the widgets in this package, captured from the
showroom in both themes. Nothing here is a mockup.

### Buttons

| Light | Dark |
| :---: | :---: |
| ![Buttons light](https://raw.githubusercontent.com/B1Digital/fluent_ui_2_flutter/main/assets/previews/button.light.png) | ![Buttons dark](https://raw.githubusercontent.com/B1Digital/fluent_ui_2_flutter/main/assets/previews/button.dark.png) |

### Text inputs

| Light | Dark |
| :---: | :---: |
| ![Inputs light](https://raw.githubusercontent.com/B1Digital/fluent_ui_2_flutter/main/assets/previews/input.light.png) | ![Inputs dark](https://raw.githubusercontent.com/B1Digital/fluent_ui_2_flutter/main/assets/previews/input.dark.png) |

### Selection controls

| Light | Dark |
| :---: | :---: |
| ![Selection light](https://raw.githubusercontent.com/B1Digital/fluent_ui_2_flutter/main/assets/previews/selection.light.png) | ![Selection dark](https://raw.githubusercontent.com/B1Digital/fluent_ui_2_flutter/main/assets/previews/selection.dark.png) |

### Surfaces &amp; people

| Light | Dark |
| :---: | :---: |
| ![Surfaces light](https://raw.githubusercontent.com/B1Digital/fluent_ui_2_flutter/main/assets/previews/surfaces.light.png) | ![Surfaces dark](https://raw.githubusercontent.com/B1Digital/fluent_ui_2_flutter/main/assets/previews/surfaces.dark.png) |

### Navigation

| Light | Dark |
| :---: | :---: |
| ![Navigation light](https://raw.githubusercontent.com/B1Digital/fluent_ui_2_flutter/main/assets/previews/navigation.light.png) | ![Navigation dark](https://raw.githubusercontent.com/B1Digital/fluent_ui_2_flutter/main/assets/previews/navigation.dark.png) |

### Menus &amp; toolbars

| Light | Dark |
| :---: | :---: |
| ![Menu light](https://raw.githubusercontent.com/B1Digital/fluent_ui_2_flutter/main/assets/previews/menu.light.png) | ![Menu dark](https://raw.githubusercontent.com/B1Digital/fluent_ui_2_flutter/main/assets/previews/menu.dark.png) |

### Data grid

| Light | Dark |
| :---: | :---: |
| ![Data grid light](https://raw.githubusercontent.com/B1Digital/fluent_ui_2_flutter/main/assets/previews/data_grid.light.png) | ![Data grid dark](https://raw.githubusercontent.com/B1Digital/fluent_ui_2_flutter/main/assets/previews/data_grid.dark.png) |

### Calendar

| Light | Dark |
| :---: | :---: |
| ![Calendar light](https://raw.githubusercontent.com/B1Digital/fluent_ui_2_flutter/main/assets/previews/calendar.light.png) | ![Calendar dark](https://raw.githubusercontent.com/B1Digital/fluent_ui_2_flutter/main/assets/previews/calendar.dark.png) |

### Status &amp; progress

| Light | Dark |
| :---: | :---: |
| ![Feedback light](https://raw.githubusercontent.com/B1Digital/fluent_ui_2_flutter/main/assets/previews/feedback.light.png) | ![Feedback dark](https://raw.githubusercontent.com/B1Digital/fluent_ui_2_flutter/main/assets/previews/feedback.dark.png) |

### Charts

A full port of the Fluent UI React **charting** library — axes, legends, callouts,
annotations, and a declarative (Plotly-schema) entry point included.

| Light | Dark |
| :---: | :---: |
| ![Charts light](https://raw.githubusercontent.com/B1Digital/fluent_ui_2_flutter/main/assets/previews/charts.light.png) | ![Charts dark](https://raw.githubusercontent.com/B1Digital/fluent_ui_2_flutter/main/assets/previews/charts.dark.png) |
| ![Bar charts light](https://raw.githubusercontent.com/B1Digital/fluent_ui_2_flutter/main/assets/previews/charts_bars.light.png) | ![Bar charts dark](https://raw.githubusercontent.com/B1Digital/fluent_ui_2_flutter/main/assets/previews/charts_bars.dark.png) |

---

## What's in the box

| | |
| :-- | :-- |
| **Buttons** | Button · CompoundButton · MenuButton · SplitButton · ToggleButton |
| **Inputs** | Input · Textarea · SearchBox · SpinButton · Dropdown · Dropdown options · Slider · Switch · Checkbox · Radio + RadioGroup · Rating · SwatchPicker · TagPicker · Field · Label · InfoLabel · InfoButton · Link |
| **Date &amp; time** | Calendar · DatePicker · TimePicker |
| **Surfaces** | Card (header/footer/preview) · Accordion · Acrylic · Avatar · AvatarGroup · Badge · CounterBadge · PresenceBadge · Persona · Carousel · Divider · ProgressBar · Skeleton · Spinner · StatusIndicator · Tag · InteractionTag · Tooltip · MessageBar |
| **Navigation** | Nav · NavDrawer · TabList · Breadcrumb · Tree · Toolbar · ListItem · DataGrid · Hamburger |
| **Overlays** | Dialog · Drawer · Menu · MenuItem · Popover · TeachingPopover · Toast + Toaster |
| **Charts** | Area · Line · VerticalBar · GroupedVerticalBar · VerticalStackedBar · HorizontalBar · HorizontalBarWithAxis · Donut · Funnel · Gauge · Gantt · HeatMap · Polar · Sankey · Scatter · Sparkline · ChartTable · Declarative (Plotly schema) · Vega declarative · Annotation layers |

Every component ships a companion `*Style` class, so a widget can be restyled
without a fork and without a `copyWith` chain.

---

## Theming

Four ready themes, and brand ramps generated from a single key colour — a Dart
port of Microsoft's Theme Designer algorithm (two quadratic béziers through CIE
Lab, sampled against a per-hue lightness table, chroma-snapped into sRGB).

```dart
FluentThemeData.light();        FluentThemeData.dark();
FluentThemeData.teamsDark();    // own token table, not dark + Teams ramp
FluentThemeData.highContrast(); // 8 Windows system colours, no brand ramp

FluentThemeData.light(
  brand: FluentBrandRamp.fromKeyColor(
    const Color(0xFF7B2D8E),
    vibrancy: 0.5,   // both bézier control points
    hueTorsion: 0.2, // rotate through neighbouring hues (-0.5…0.5)
  ),
);
```

Verbatim upstream ramps are there too, for fidelity to Microsoft's shipped
themes: `FluentBrandRamp.web`, `.teams`, `.teamsV21`, `.office`,
`.communicationBlue`.

Tokens, not magic numbers:

```dart
final theme = FluentTheme.of(context);
theme.colors.brandBackground;           // alias token
theme.typography.subtitle1;             // type ramp
theme.shadow(FluentElevation.shadow8);  // two-layer elevation
FluentSpacing.l;                        // 16
FluentRadius.medium;                    // 4
FluentDuration.normal;                  // 200ms
FluentCurve.decelerateMid;              // entrance easing
```

---

## Accessibility, i18n, RTL

- **Keyboard first.** Every interactive component has a focus path
  (`FocusableActionDetector`) and a visible focus indicator.
- **Screen readers.** Semantics labels on every control, including per-chart
  descriptions and data tables behind each visualisation.
- **High contrast.** A first-class theme, covered by its own golden images —
  not an afterthought.
- **135 locales, 32 languages**, generated from ARB and checked in, so the
  published package needs no build step.
- **RTL** is a layout mode, not a mirror hack: Arabic, Hebrew, Persian and Urdu
  are part of the test matrix.

```dart
FluentApp(
  supportedLocales: FluentLocalizations.supportedLocales,
  localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
    FluentLocalizations.delegate,
  ],
);
```

---

## How the fidelity is proven

| Question | Answered by |
| :-- | :-- |
| Does it match the Figma spec? | Numeric fixtures — resolved sizes, paddings, radii, strokes and ARGB fills compared to values extracted from the Fluent 2 Figma file. |
| Did it change since last commit? | 261 golden images: one per component per theme, light / dark / high contrast. |
| Does it match Fluent UI React v9? | Story-for-story parity with the React Storybook — 89 documented pages, rebuilt as the showroom you can open above. |
| Is Material creeping back in? | `melos run no-material` fails the build on any `material.dart` or `cupertino.dart` import. |

---

## Example

The `example/` directory is the showroom itself — a hand-written clone of the
Fluent UI React v9 Storybook, deployed on every push to `main`:

**<https://b1digital.github.io/fluent_ui_2_flutter/>**

```sh
cd example
flutter run -d chrome
```

---

## Related packages

| Package | Purpose |
| :-- | :-- |
| [`fluent_2_core`](https://pub.dev/packages/fluent_2_core) | Tokens, theming, `FluentApp` — shared foundation, re-exported here. |
| [`fluent_2_fonts`](https://pub.dev/packages/fluent_2_fonts) | Platform font facade; open-source Selawik on Web and Windows. |

---

## License

MIT © ICITECH Teknoloji A.Ş. Fluent 2 is a design system by Microsoft; this is an
independent Flutter implementation and is not affiliated with or endorsed by
Microsoft.
