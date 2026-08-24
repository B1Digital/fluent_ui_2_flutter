import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The Link docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage linkPage = DocsPage(
  id: 'components-link',
  title: 'Link',
  description:
      'Links allow users to navigate between different locations. They can be '
      'used as standalone controls or inline with text.',
  source: 'lib/pages/components_link.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-link--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-link--appearance',
      title: 'Appearance',
      builder: _appearance,
    ),
    DocsSection(
      id: 'components-link--inline',
      title: 'Inline',
      builder: _inline,
    ),
    DocsSection(
      id: 'components-link--disabled',
      title: 'Disabled',
      builder: _disabled,
    ),
    DocsSection(
      id: 'components-link--disabled-focusable',
      title: 'Disabled Focusable',
      builder: _disabledFocusable,
    ),
    DocsSection(
      id: 'components-link--as-button',
      title: 'As Button',
      description:
          'When the href property is not provided, the component is rendered '
          'as an html <button>',
      builder: _asButton,
    ),
    DocsSection(
      id: 'components-link--as-span',
      title: 'As Span',
      description:
          'A Link can be rendered as an html <span>, in which case it will '
          'have role="button" set. Links that render as a span wrap correctly '
          'between lines, behaving as inline elements as opposed to links '
          'rendered as buttons, which always behave as inline-block elements '
          'that do not wrap correctly.',
      builder: _asSpan,
    ),
  ],
  props: <PropRow>[
    PropRow(name: 'child', type: 'Widget', description: 'The link text.'),
    PropRow(
      name: 'onPressed',
      type: 'VoidCallback?',
      defaultValue: 'null',
      description:
          'Invoked on tap and on Space or Enter. Null disables the link.',
    ),
    PropRow(
      name: 'appearance',
      type: 'FluentLinkAppearance',
      defaultValue: 'FluentLinkAppearance.standard',
      description: 'Colour treatment.',
    ),
    PropRow(
      name: 'inline',
      type: 'bool',
      defaultValue: 'false',
      description:
          'Whether to underline at rest, for a link sitting inside prose.',
    ),
    PropRow(
      name: 'icon',
      type: 'Widget?',
      defaultValue: 'null',
      description: 'Optional trailing icon.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentLinkStyle?',
      defaultValue: 'null',
      description:
          'Overrides layered over the theme defaults. Merged last, so it wins.',
    ),
    PropRow(
      name: 'focusNode',
      type: 'FocusNode?',
      defaultValue: 'null',
      description: 'Focus node to use. One is created internally when omitted.',
    ),
    PropRow(
      name: 'autofocus',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether to take focus on mount.',
    ),
    PropRow(
      name: 'semanticLabel',
      type: 'String?',
      defaultValue: 'null',
      description:
          'Announced by assistive technology in place of the label text.',
    ),
  ],
);

// #docregion components-link--default
// FluentLink has no `href`: this package takes no URL-launcher dependency, so
// upstream's href="https://www.bing.com" becomes an onPressed the host app
// wires to its own navigation.
Widget _default(BuildContext context) =>
    FluentLink(onPressed: () {}, child: const Text('This is a link'));
// #enddocregion components-link--default

// #docregion components-link--appearance
// Upstream: <Link appearance="subtle" href="https://www.bing.com">. FluentLink
// has no `href`, so navigation is the caller's onPressed.
Widget _appearance(BuildContext context) => FluentLink(
  appearance: FluentLinkAppearance.subtle,
  onPressed: () {},
  child: const Text('Subtle link'),
);
// #enddocregion components-link--appearance

// #docregion components-link--inline
// A Flutter widget cannot sit inside a paragraph the way an <a> sits inside a
// <div>, so the link travels as a WidgetSpan baseline-aligned with the prose.
// href="https://www.bing.com" upstream; FluentLink navigates from onPressed.
Widget _inline(BuildContext context) => Text.rich(
  TextSpan(
    children: <InlineSpan>[
      const TextSpan(text: 'This is an '),
      WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: FluentLink(
          inline: true,
          onPressed: () {},
          child: const Text('inline link'),
        ),
      ),
      const TextSpan(text: ' used alongside other text'),
    ],
  ),
);
// #enddocregion components-link--inline

// #docregion components-link--disabled
// Upstream passes `disabled` alongside href="https://www.bing.com". FluentLink
// has no `disabled` flag — a null onPressed *is* the disabled state: the link
// stops reporting hover and press, refuses focus, and never fires.
Widget _disabled(BuildContext context) =>
    const FluentLink(child: Text('Disabled link'));
// #enddocregion components-link--disabled

// #docregion components-link--disabled-focusable
// FluentLink has no `disabledFocusable`: a disabled link refuses focus outright.
// A plain Focus node keeps it in the traversal order, which is the whole point
// of upstream's flag — a consistent tab order for keyboard and screen readers.
// href="https://www.bing.com" upstream.
Widget _disabledFocusable(BuildContext context) => const Focus(
  child: FluentLink(inline: true, child: Text('Disabled but still focusable')),
);
// #enddocregion components-link--disabled-focusable

// #docregion components-link--as-button
// Upstream switches element by whether `href` is present. FluentLink renders one
// way and always activates through onPressed, so there is nothing to switch.
Widget _asButton(BuildContext context) =>
    FluentLink(onPressed: () {}, child: const Text('Render as a button'));
// #enddocregion components-link--as-button

// #docregion components-link--as-span
// Upstream's point is that a span-rendered link rewraps mid-phrase. A Flutter
// WidgetSpan is an atomic inline box: the link's own text wraps inside it, but
// the box itself does not break across lines. Upstream's onClick raises
// alert("Link rendered as span"); a docs demo has no alert, so the tap is inert.
Widget _asSpan(BuildContext context) => SizedBox(
  width: 200,
  child: Text.rich(
    TextSpan(
      children: <InlineSpan>[
        const TextSpan(text: 'The following link renders as a span. '),
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: FluentLink(
            inline: true,
            onPressed: () {},
            child: const Text(
              'Links that render as a span wrap correctly between lines when '
              'their content is very long',
            ),
          ),
        ),
        const TextSpan(
          text: '. This is because they behave as regular inline elements.',
        ),
      ],
    ),
  ),
);
// #enddocregion components-link--as-span
