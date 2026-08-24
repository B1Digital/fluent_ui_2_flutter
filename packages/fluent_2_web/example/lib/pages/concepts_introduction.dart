import '../shell/catalog.dart';

/// The Introduction page.\n///\n/// Upstream titles this with the React package name and version; ours names\n/// the package a reader of this showroom actually consumes.
const DocsPage introductionPage = DocsPage(
  id: 'concepts-introduction',
  navTitle: 'Introduction',
  title: 'Fluent 2 Flutter',
  description: '',
  source: 'lib/pages/concepts_introduction.dart',
  sections: <DocsSection>[],
  markdown: _markdown,
);

/// The page's source, as upstream publishes it.
const String _markdown =
    '# Fluent 2 Flutter\n'
    '\n'
    '## What\'s new\n'
    '\n'
    'Lightweight components for smaller bundle size and '
    'faster performance.\n'
    '\n'
    'New tokens system for frictionless cohesion across OS '
    'themes.\n'
    '\n'
    'New assets to level up Teams add-ins and M365 '
    'experiences.\n'
    '\n'
    '### Overview\n'
    '\n'
    'Fluent UI React Components is a set of UI components and '
    'utilities resulting from an effort to converge the set '
    'of React based component libraries in production today: '
    '`@fluentui/react` and `@fluentui/react-northstar`.\n'
    '\n'
    'Each component is designed to adhere to the following '
    'standards:\n'
    '\n'
    '-   **Customizable**: Fluent-styled components by '
    'default, but easy to integrate your own brand and theme\n'
    '-   **Performance**: Optimized for render performance\n'
    '-   **Bundle size**: Refactored and slimmed down '
    'components that allow you to include the packages and '
    'dependencies you need\n'
    '-   **Accessibility**: WCAG 2.1 compliant and tested by '
    'trusted testers\n'
    '-   **Design to Code**: Stay up to date with Fluent '
    'Design Language changes via Design Tokens\n'
    '\n'
    '## Questions?\n'
    '\n'
    'Reach out to the Fluent UI React team on '
    '[GitHub](https://github.com/microsoft/fluentui)\n'
    '\n';
