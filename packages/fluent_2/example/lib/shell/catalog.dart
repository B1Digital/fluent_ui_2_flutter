import 'package:flutter/widgets.dart';

/// One story section on a docs page: a heading, a sentence, and a demo.
///
/// [id] does triple duty — it is the anchor the "On this page" rail scrolls to,
/// the key the coverage contract joins on, *and* the `#docregion` marker that
/// delimits this section's source inside its own page file. One identifier
/// rather than three is the point: there is no pair to keep in sync, and
/// `storybook_contract_test` proves every one of them resolves.
@immutable
class DocsSection {
  /// Creates a section. [id] must match a `// #docregion <id>` in the page file.
  const DocsSection({
    required this.id,
    required this.title,
    required this.builder,
    this.description,
  });

  /// The upstream story id, e.g. `components-accordion--collapsible`.
  final String id;

  /// The rendered heading, verbatim from upstream — including its punctuation.
  /// Avatar really does title a section `Shape: square`.
  final String title;

  /// The sentence upstream prints under the heading, or null where it prints
  /// none. 444 of the 653 sections have one.
  final String? description;

  /// Builds the demo. Kept as a bare [WidgetBuilder] so a section can be a
  /// const tear-off of a top-level function and the whole catalog stays
  /// compile-time data.
  final WidgetBuilder builder;
}

/// One row of a props table.
@immutable
class PropRow {
  /// Creates a row.
  const PropRow({
    required this.name,
    required this.type,
    this.defaultValue,
    this.description,
  });

  /// The Dart parameter name.
  final String name;

  /// The Dart type, as written in the constructor.
  final String type;

  /// The default, or null when the parameter is required.
  final String? defaultValue;

  /// One line, lifted from the widget's dartdoc.
  final String? description;
}

/// One docs page: everything between the sidebar selection and the right rail.
@immutable
class DocsPage {
  /// Creates a page.
  const DocsPage({
    required this.id,
    required this.title,
    required this.description,
    required this.source,
    required this.sections,
    this.props = const <PropRow>[],
    this.body,
    this.folder,
    this.prose = const <ProseBlock>[],
    this.navTitle,
    this.markdown,
  });

  /// The upstream docs id with `--docs` stripped, e.g. `components-accordion`.
  /// This is the route segment, so it is also what a shared link contains.
  final String id;

  /// The `<h1>`.
  final String title;

  /// Overrides the sidebar label where it differs from the `<h1>`.
  ///
  /// Concepts/Introduction reads "Introduction" in the rail while its heading is
  /// the package's own name, so the two cannot be one field.
  final String? navTitle;

  /// What the sidebar actually prints.
  String get sidebarLabel => navTitle ?? title;

  /// The page's whole content, as a markdown document.
  ///
  /// The Concepts pages are prose end to end — tables, nested lists, emoji
  /// headings — so they carry their source and are rendered by the markdown
  /// viewer rather than decomposed into [prose] blocks a simpler renderer would
  /// flatten. When this is set it is also exactly what Copy Page hands over.
  final String? markdown;

  /// The paragraph under the toolbar row.
  final String description;

  /// The `rootBundle` key of this page's own source file, e.g.
  /// `lib/pages/components_accordion.dart`. Declared rather than derived
  /// because the asset key and the import path are only equal by convention,
  /// and `storybook_contract_test` would rather fail loudly than guess.
  final String source;

  /// Sections in upstream's declaration order — which is the order the real
  /// docs page renders them, not the alphabetical order `llms.txt` lists them.
  final List<DocsSection> sections;

  /// Our Dart constructor parameters.
  ///
  /// Upstream's table documents the React API, so reproducing it verbatim would
  /// be a pixel-accurate lie about what our widgets accept. The table chrome is
  /// upstream's; the rows are ours.
  final List<PropRow> props;

  /// Free-form content rendered in place of [sections].
  ///
  /// The seven Theme pages have no stories at all — upstream writes them as MDX
  /// token tables, not as a list of demos — so they supply a body instead.
  /// Component pages leave this null.
  final WidgetBuilder? body;

  /// The sidebar folder this page sits in, or null when it sits directly under
  /// its group.
  ///
  /// Upstream nests six of them — Badge, Button, Card, Carousel, Menu and Tag —
  /// because those components ship as a family rather than a single widget.
  /// Taken from the captured sidebar path (`Components/Badge/Counter Badge`).
  final String? folder;

  /// Headed guidance printed between the description and the sections.
  ///
  /// The chart pages carry seven of these — Layout, Content, Accessibility,
  /// Customizing the chart, Creating Date Objects, Do's, Don'ts — where a
  /// component page has a single sentence. Collapsing them into [description]
  /// turns a structured page into one 5,700-character paragraph, which is what
  /// the first capture did.
  final List<ProseBlock> prose;
}

/// One headed paragraph of guidance above a page's sections.
@immutable
class ProseBlock {
  /// Creates a block.
  const ProseBlock({required this.title, required this.body});

  /// The `###` heading, verbatim.
  final String title;

  /// The prose under it.
  final String body;
}

/// A top-level sidebar group: Theme, Components, Compat Components, Charts.
@immutable
class DocsGroup {
  /// Creates a group.
  const DocsGroup({required this.title, required this.pages});

  /// The group heading in the sidebar.
  final String title;

  /// Pages in sidebar order.
  final List<DocsPage> pages;
}
