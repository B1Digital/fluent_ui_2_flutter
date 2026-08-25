# Sources and provenance

Use Microsoft sources for Fluent product intent and accessibility. Use the
checked-out Dart source for Flutter API truth. Do not mirror entire source pages
into this skill; retain concise paraphrases and direct links.

## Source priority

1. Component-specific Fluent 2 usage page for use, behavior, layout,
   accessibility, and content.
2. Fluent 2 design-language pages for cross-component rules.
3. Current Flutter public barrels, constructors, tests, and gallery stories.
4. Platform-native guidance when Fluent explicitly delegates to iOS, Android,
   Windows, or the web platform.

When sources disagree, document the difference. Do not silently select the
easier implementation.

## Design-language sources

| Topic | Official source |
| --- | --- |
| What's new | <https://fluent2.microsoft.design/get-started/whatisnew/> |
| Start designing | <https://fluent2.microsoft.design/get-started/design/> |
| Start developing | <https://fluent2.microsoft.design/get-started/develop/> |
| Design principles | <https://fluent2.microsoft.design/design-principles/> |
| Design tokens | <https://fluent2.microsoft.design/design-tokens/> |
| Color | <https://fluent2.microsoft.design/color/> |
| Typography | <https://fluent2.microsoft.design/typography/> |
| Layout | <https://fluent2.microsoft.design/layout/> |
| Shapes | <https://fluent2.microsoft.design/shapes/> |
| Elevation | <https://fluent2.microsoft.design/elevation/> |
| Material | <https://fluent2.microsoft.design/material/> |
| Motion | <https://fluent2.microsoft.design/motion/> |
| Iconography | <https://fluent2.microsoft.design/iconography/> |
| Accessibility | <https://fluent2.microsoft.design/accessibility/> |
| Content design | <https://fluent2.microsoft.design/content-design/> |
| Handoffs | <https://fluent2.microsoft.design/handoffs/> |
| Onboarding | <https://fluent2.microsoft.design/onboarding/> |
| Wait UX | <https://fluent2.microsoft.design/wait-ux/> |

## Component indexes

| Surface | Official source |
| --- | --- |
| Web | <https://fluent2.microsoft.design/components/web/react/> |
| iOS | <https://fluent2.microsoft.design/components/ios/> |
| Android | <https://fluent2.microsoft.design/components/android/> |
| Windows | <https://fluent2.microsoft.design/components/windows/> |
| React Native | <https://fluent2.microsoft.design/components/react-native/> |

Every web-core component entry in `widget-coverage.json` maps to a component
reference that cites its exact `/usage/` page. The validator checks all 47 URLs,
their Flutter mapping, and their presence in the live-source manifest. A route
in the sitemap is not considered covered merely because its component name
appears in a table.

## AI and content-engineering sources

| Topic | Official source |
| --- | --- |
| Responsible AI | <https://fluent2.microsoft.design/responsible-AI/> |
| AI harm | <https://fluent2.microsoft.design/ai-harm/> |
| Content engineering | <https://fluent2.microsoft.design/content-engineering/> |
| System prompt engineering | <https://fluent2.microsoft.design/content-engineering/system-prompt-engineering/> |
| Evaluating output quality | <https://fluent2.microsoft.design/content-engineering/evaluating-output-quality/> |

The source manifest tracks the complete two-page Working with AI family and all
15 Content Engineering pages, including every prompt-design and evaluation
subpage.

The route snapshot in `source-manifest.json` is generated from
<https://fluent2.microsoft.design/sitemap-index.xml>. At the 2026-08-04 crawl,
the explicit design-language set contained all 8 requested pages, the UX
framework set contained all 6 requested pages, Working with AI contained 2
pages, Content Engineering contained 15 pages, and the component sets contained
47 web-core pages, 14 web AI pages, 12 iOS pages, and 5 Android pages.

## Flutter sources

- Root workspace: `pubspec.yaml`
- Core public API: `packages/fluent_2_core/lib/fluent_2_core.dart`
- Web public API: `packages/fluent_2/lib/fluent_2.dart`
- Executable examples: `packages/fluent_2/example/lib/stories/`
- Behavior tests: `packages/fluent_2/test/`

## Refresh policy

Run `node scripts/crawl-fluent2.mjs --write`, review the route diff, then update
the component, AI, prompt, and evaluation references plus the coverage matrix.
Run `node scripts/audit-widget-coverage.mjs` afterward. Never accept a changed
count without identifying the added, removed, or renamed route and adding
deliberate guidance for it.
