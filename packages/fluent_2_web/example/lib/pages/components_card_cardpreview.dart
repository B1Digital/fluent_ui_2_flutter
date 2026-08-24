import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The CardPreview docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage cardPreviewPage = DocsPage(
  id: 'components-card-cardpreview',
  folder: 'Card',
  title: 'CardPreview',
  description:
      "The CardPreview component, used inside of a Card, allows the user to "
      "better visualize what the card's contents are.",
  source: 'lib/pages/components_card_cardpreview.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-card-cardpreview--default',
      title: 'Default',
      builder: _default,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'preview',
      type: 'Widget?',
      defaultValue: 'null',
      description:
          "Media that bleeds to the card's edge, before every other slot.",
    ),
    PropRow(
      name: 'size',
      type: 'FluentCardSize',
      defaultValue: 'FluentCardSize.medium',
      description:
          'Inset, gap and corner radius. The preview is clipped to that radius.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentCardStyle?',
      defaultValue: 'null',
      description:
          'Overrides layered over the theme defaults. Merged last, so it wins.',
    ),
  ],
);

// #docregion components-card-cardpreview--default
// Upstream renders a bare `<CardPreview>` with its own `logo` slot. We have no
// `FluentCardPreview` widget: the preview is `FluentCard`'s `preview` slot,
// which already bleeds to the card's edge and clips to its corner radius, so
// the story is shown in the card that owns the slot and the logo is composed as
// a `Stack` overlay. `doc_template.png` and `docx.png` are not among the
// bundled storybook assets — `image.png` stands in for the document preview,
// and a document glyph for the Word logo.
Widget _default(BuildContext context) => const FluentCard(
  preview: Stack(
    children: <Widget>[
      Image(
        image: AssetImage('assets/storybook/image.png'),
        semanticLabel: 'Preview of a Word document ',
        width: 480,
        height: 240,
        fit: BoxFit.cover,
      ),
      Positioned(
        left: 12,
        bottom: 12,
        child: Icon(
          FluentIcons.document_20_regular,
          size: 32,
          semanticLabel: 'Microsoft Word logo',
        ),
      ),
    ],
  ),
);
// #enddocregion components-card-cardpreview--default
