import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The Divider docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Upstream frames every example in a 96px-tall `colorNeutralBackground1` box,
/// stacked with a 5px gap; that griffel layout is reproduced here as a
/// `ColoredBox` + `SizedBox` per example rather than copied as class names.
const DocsPage dividerPage = DocsPage(
  id: 'components-divider',
  title: 'Divider',
  description: 'A divider visually separates two pieces of content.',
  source: 'lib/pages/components_divider.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-divider--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-divider--vertical',
      title: 'Vertical',
      description: 'A divider can vertically separate two pieces of content.',
      builder: _vertical,
    ),
    DocsSection(
      id: 'components-divider--appearance',
      title: 'Appearance',
      description:
          'A divider can have a brand, subtle, or strong appearance. When not '
          'specified, it has its default experience.',
      builder: _appearance,
    ),
    DocsSection(
      id: 'components-divider--inset',
      title: 'Inset',
      description:
          'A divider can have its line inset from the edges of its container.',
      builder: _inset,
    ),
    DocsSection(
      id: 'components-divider--align-content',
      title: 'Align Content',
      description:
          'The label associated with the divider can be aligned at the start, '
          'center, or end of the divider line.',
      builder: _alignContent,
    ),
    DocsSection(
      id: 'components-divider--custom-styles',
      title: 'Custom Styles',
      description:
          'A divider can have custom styles applied to both the label and the '
          'line.',
      builder: _customStyles,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'child',
      type: 'Widget?',
      defaultValue: 'null',
      description:
          'The label sitting between the two rules. Null for a plain '
          'rule.',
    ),
    PropRow(
      name: 'icon',
      type: 'Widget?',
      defaultValue: 'null',
      description: 'Optional icon, placed before the label in reading order.',
    ),
    PropRow(
      name: 'appearance',
      type: 'FluentDividerAppearance',
      defaultValue: 'FluentDividerAppearance.standard',
      description: 'How strongly the rule and label read.',
    ),
    PropRow(
      name: 'alignment',
      type: 'FluentDividerAlignment',
      defaultValue: 'FluentDividerAlignment.center',
      description:
          'Where the label sits along the rule. Ignored when there is '
          'no label.',
    ),
    PropRow(
      name: 'vertical',
      type: 'bool',
      defaultValue: 'false',
      description:
          'Whether the rule runs top to bottom rather than left to right.',
    ),
    PropRow(
      name: 'inset',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether the whole divider is inset from its container.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentDividerStyle?',
      defaultValue: 'null',
      description:
          'Overrides layered over the theme defaults. Merged last, so it wins.',
    ),
  ],
);

// #docregion components-divider--default
Widget _default(BuildContext context) {
  final Color surface = FluentTheme.of(context).colors.neutralBackground1;

  Widget example(Widget divider) => ColoredBox(
    color: surface,
    child: SizedBox(height: 96, child: Center(child: divider)),
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: 5,
    children: <Widget>[
      example(const FluentDivider()),
      example(const FluentDivider(child: Text('Text'))),
    ],
  );
}
// #enddocregion components-divider--default

// #docregion components-divider--vertical
Widget _vertical(BuildContext context) {
  final Color surface = FluentTheme.of(context).colors.neutralBackground1;

  // Upstream gives each vertical divider `height: 100%`; a `FluentDivider` with
  // `vertical: true` already fills whatever height its parent bounds it to.
  Widget example(Widget divider) => ColoredBox(
    color: surface,
    child: SizedBox(height: 96, child: Center(child: divider)),
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: 5,
    children: <Widget>[
      example(const FluentDivider(vertical: true)),
      example(const FluentDivider(vertical: true, child: Text('Text'))),
    ],
  );
}
// #enddocregion components-divider--vertical

// #docregion components-divider--appearance
Widget _appearance(BuildContext context) {
  final Color surface = FluentTheme.of(context).colors.neutralBackground1;

  Widget example(Widget divider) => ColoredBox(
    color: surface,
    child: SizedBox(height: 96, child: Center(child: divider)),
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: 5,
    children: <Widget>[
      // React's `appearance="default"` is `FluentDividerAppearance.standard`:
      // `default` is a Dart reserved word.
      example(const FluentDivider(child: Text('(default)'))),
      example(
        const FluentDivider(
          appearance: FluentDividerAppearance.subtle,
          child: Text('subtle'),
        ),
      ),
      example(
        const FluentDivider(
          appearance: FluentDividerAppearance.brand,
          child: Text('brand'),
        ),
      ),
      example(
        const FluentDivider(
          appearance: FluentDividerAppearance.strong,
          child: Text('strong'),
        ),
      ),
    ],
  );
}
// #enddocregion components-divider--appearance

// #docregion components-divider--inset
Widget _inset(BuildContext context) {
  final Color surface = FluentTheme.of(context).colors.neutralBackground1;

  Widget example(Widget divider) => ColoredBox(
    color: surface,
    child: SizedBox(height: 96, child: Center(child: divider)),
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: 5,
    children: <Widget>[
      example(const FluentDivider(inset: true)),
      example(const FluentDivider(inset: true, child: Text('Text'))),
      example(const FluentDivider(inset: true, vertical: true)),
      example(
        const FluentDivider(inset: true, vertical: true, child: Text('Text')),
      ),
    ],
  );
}
// #enddocregion components-divider--inset

// #docregion components-divider--align-content
Widget _alignContent(BuildContext context) {
  final Color surface = FluentTheme.of(context).colors.neutralBackground1;

  Widget example(Widget divider) => ColoredBox(
    color: surface,
    child: SizedBox(height: 96, child: Center(child: divider)),
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: 5,
    children: <Widget>[
      example(
        const FluentDivider(
          alignment: FluentDividerAlignment.start,
          child: Text('start'),
        ),
      ),
      example(
        const FluentDivider(
          alignment: FluentDividerAlignment.center,
          child: Text('center (default)'),
        ),
      ),
      example(
        const FluentDivider(
          alignment: FluentDividerAlignment.end,
          child: Text('end'),
        ),
      ),
      example(
        const FluentDivider(
          alignment: FluentDividerAlignment.start,
          vertical: true,
          child: Text('start'),
        ),
      ),
      example(
        const FluentDivider(
          alignment: FluentDividerAlignment.center,
          vertical: true,
          child: Text('center (default)'),
        ),
      ),
      example(
        const FluentDivider(
          alignment: FluentDividerAlignment.end,
          vertical: true,
          child: Text('end'),
        ),
      ),
    ],
  );
}
// #enddocregion components-divider--align-content

// #docregion components-divider--custom-styles
Widget _customStyles(BuildContext context) {
  final FluentColors colors = FluentTheme.of(context).colors;
  final Color surface = colors.neutralBackground1;

  Widget example(Widget divider) => ColoredBox(
    color: surface,
    child: SizedBox(height: 96, child: Center(child: divider)),
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: 5,
    children: <Widget>[
      example(
        const SizedBox(
          width: 200,
          // The label carries its own width. FluentDivider hands its content
          // unbounded horizontal constraints — the content sits between two
          // flexible rules but is not itself flexible — so an unbounded label
          // takes its full intrinsic width and overflows the 200px box rather
          // than wrapping inside it the way CSS flex-shrink does upstream.
          // 176 is the 200 less the divider's 24px of content padding.
          child: FluentDivider(
            child: SizedBox(width: 176, child: Text('Custom width (200px)')),
          ),
        ),
      ),
      // Upstream's taller, unpainted frame for the vertical example.
      SizedBox(
        height: 192,
        child: Center(
          child: SizedBox(
            height: 50,
            child: FluentDivider(
              vertical: true,
              child: const Text('Custom height (50px)'),
            ),
          ),
        ),
      ),
      example(
        FluentDivider(
          style: FluentDividerStyle.from(
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: const Text('Custom font (14px bold)'),
        ),
      ),
      example(
        FluentDivider(
          // `tokens.colorPaletteRedBorder2` is Figma `Palette/Red/Stroke/2/Rest`.
          style: FluentDividerStyle.from(
            lineColor: colors.palette.stroke2Rest(FluentPaletteFamily.red),
          ),
          child: const Text(
            'Custom line color (tokens.colorPaletteRedBorder2)',
          ),
        ),
      ),
      example(
        FluentDivider(
          // `FluentDividerStyle` sets a rule's thickness but not its dash
          // pattern, so the 2px lands and the dashes do not.
          style: FluentDividerStyle.from(lineThickness: 2),
          child: const Text('Custom line style (2px dashed)'),
        ),
      ),
    ],
  );
}

// #enddocregion components-divider--custom-styles
