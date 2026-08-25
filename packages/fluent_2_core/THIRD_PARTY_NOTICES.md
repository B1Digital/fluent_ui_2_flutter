# Third-party notices

This project is an independent Flutter implementation of Microsoft's Fluent 2
design system. It is not affiliated with, endorsed by, or supported by
Microsoft Corporation.

## microsoft/fluentui — MIT

Design token values, component behaviour and motion specifications in this
repository are derived from <https://github.com/microsoft/fluentui>, in
particular `packages/tokens/src/` (global and alias token layers) and
`packages/react-components/` (component behaviour, interaction states and CSS
transition specifications).

> MIT License
>
> Copyright (c) Microsoft Corporation.
>
> Permission is hereby granted, free of charge, to any person obtaining a copy
> of this software and associated documentation files (the "Software"), to deal
> in the Software without restriction, including without limitation the rights
> to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
> copies of the Software, and to permit persons to whom the Software is
> furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in
> all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
> IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
> FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
> AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
> LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
> OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
> THE SOFTWARE.

### Asset carve-out — important

The `microsoft/fluentui` LICENSE explicitly excludes "the fonts and icons
referenced in Fluent UI React" from that MIT grant. Those assets are governed
by the **Microsoft Fabric Assets License**
(<https://aka.ms/fluentui-assets-license>), a narrow, revocable,
non-transferable grant that covers the Segoe font family, Microsoft Office
icons, and Microsoft Fabric / MDL2 icons.

**No asset covered by the Fabric Assets License is redistributed by this
project:**

- **Segoe UI is not bundled or selected by the implementation.** Figma fixture
  metadata still records that upstream family name as design provenance. The
  implementation uses Selawik, distributed separately under the SIL Open Font
  License 1.1 described below.
- No Microsoft product logos are included.
- No MDL2 branded icons are included.

"Fluent", "Fluent 2", "Segoe" and "Microsoft" are trademarks of Microsoft
Corporation. Their use here is nominative — to identify the design system this
project implements — and does not imply endorsement.

## Selawik — SIL Open Font License 1.1

The `fluent_2_fonts_web` and `fluent_2_fonts_windows` packages each contain
Selawik Light, Semilight, Regular, Semibold, and Bold as the open-source
substitute for Segoe UI. Platform-specific asset filters bundle only the
target's copy. Regular, Semibold, and Bold load by default; Light and Semilight
remain opt-in package files.

Copyright 2015, Microsoft Corporation (www.microsoft.com), with Reserved Font
Name Selawik. All Rights Reserved. Selawik is a trademark of Microsoft
Corporation in the United States and/or other countries.

The complete SIL Open Font License 1.1 is distributed at
`packages/fluent_2_fonts_web/LICENSE` and
`packages/fluent_2_fonts_windows/LICENSE`.

## microsoft/fluentui-system-icons — MIT

The icon set is consumed via the `fluentui_system_icons` pub package, which
wraps <https://github.com/microsoft/fluentui-system-icons>. That repository is
under unqualified MIT with no asset carve-out.

> MIT License
>
> Copyright (c) 2020 Microsoft Corporation.
>
> Permission is hereby granted, free of charge, to any person obtaining a copy
> of this software and associated documentation files (the "Software"), to deal
> in the Software without restriction, including without limitation the rights
> to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
> copies of the Software, and to permit persons to whom the Software is
> furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in
> all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
> IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
> FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
> AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
> LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
> OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
> THE SOFTWARE.
