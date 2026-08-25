import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The CardFooter docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage cardFooterPage = DocsPage(
  id: 'components-card-cardfooter',
  folder: 'Card',
  title: 'CardFooter',
  description:
      'The CardFooter component, used inside of a Card, uses a flex layout to '
      'organize actions the user can take with a Card, like sharing the '
      'contents or replying to a message.',
  source: 'lib/pages/components_card_cardfooter.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-card-cardfooter--default',
      title: 'Default',
      builder: _default,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'footer',
      type: 'Widget?',
      defaultValue: 'null',
      description: "The footer slot, inset by the card's padding.",
    ),
    PropRow(
      name: 'size',
      type: 'FluentCardSize',
      defaultValue: 'FluentCardSize.medium',
      description: 'Inset, gap and corner radius.',
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

// #docregion components-card-cardfooter--default
// Our card takes its footer as a plain widget slot — `FluentCard(footer: ...)`
// — so there is no separate FluentCardFooter widget to configure. Upstream's
// flex layout becomes a Row, and its `action` slot becomes the last child,
// pushed to the far end by a Spacer.
Widget _default(BuildContext context) => SizedBox(
  width: 300,
  child: Row(
    children: <Widget>[
      FluentButton(
        icon: const Icon(FluentIcons.arrow_reply_16_regular, size: 16),
        onPressed: () {},
        child: const Text('Reply'),
      ),
      const SizedBox(width: 8),
      FluentButton(
        icon: const Icon(FluentIcons.share_16_regular, size: 16),
        onPressed: () {},
        child: const Text('Share'),
      ),
      const Spacer(),
      FluentButton.icon(
        icon: const Icon(FluentIcons.more_horizontal_20_regular),
        semanticLabel: 'More options',
        appearance: FluentButtonAppearance.transparent,
        // Icon-only geometry, supplied here because FluentButton keeps its
        // width content-driven and has no icon-only branch (button.dart
        // reverts `useRootIconOnlyStyles` along with the 96px label floor it
        // belongs to). Figma's Button/icon-only Medium is a 32px square — a
        // 20px glyph on 6px of inset — where the labelled 12px inset makes
        // this button 44 wide, and those 12 pixels are exactly what a Reply,
        // a Share and an 8px gap leave the row short of the 300 the story
        // declares. Same override the split button's chevron half makes for
        // the same reason: that half is its own Figma component too.
        style: const FluentButtonStyle(
          padding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
            EdgeInsets.all(FluentSpacing.sNudge),
          ),
        ),
        onPressed: () {},
      ),
    ],
  ),
);
// #enddocregion components-card-cardfooter--default
