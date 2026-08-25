import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';
import 'package:markdown/markdown.dart' as md;

import '../../pages.dart';
import '../catalog.dart';
import '../docs_metrics.dart';
import '../page_markdown.dart';
import 'selectable.dart';

/// Renders a page's markdown on a bare page, in its own browser tab.
///
/// The parsing is `package:markdown`, which is pure Dart — the rendering is
/// here, so the document picks up the Fluent type ramp and no Material widget
/// arrives with it. Everything on the page is selectable.
class MarkdownView extends StatelessWidget {
  /// Shows the markdown for the page with id [pageId].
  const MarkdownView({super.key, required this.pageId});

  /// The page to serialise and render.
  final String pageId;

  @override
  Widget build(BuildContext context) {
    final DocsPage? page = pageById(pageId);
    return ColoredBox(
      color: DocsMetrics.canvas,
      child: Selectable(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: page == null
                  ? Text('No page "$pageId".', style: DocsMetrics.body)
                  : MarkdownBody(source: pageAsMarkdown(page)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders CommonMark with Fluent's type ramp.
///
/// Handles the block forms this corpus actually contains — headings,
/// paragraphs, bullet and ordered lists, fenced code, tables, blockquotes and
/// rules — plus the inline forms. Anything unrecognised falls through as its
/// own text, which is the right failure mode for a document viewer.
class MarkdownBody extends StatelessWidget {
  /// Renders [source].
  const MarkdownBody({
    super.key,
    required this.source,
    this.skipLeadingHeading = false,
  });

  /// The markdown document.
  final String source;

  /// Drops a leading `# ` heading.
  ///
  /// A docs page already draws the document's title as its `<h1>`, so rendering
  /// the source's own first heading underneath would print it twice. The
  /// standalone markdown tab keeps it, because there is nothing above it.
  final bool skipLeadingHeading;

  static const TextStyle _code = TextStyle(
    fontFamily: FluentFontFamily.monospace,
    fontFamilyFallback: FluentFontFamily.monospaceFallback,
    fontSize: 13,
    height: 19 / 13,
  );

  static TextStyle _headingStyle(int level) => switch (level) {
    1 => DocsMetrics.h1,
    2 => DocsMetrics.h2,
    3 => DocsMetrics.h3,
    _ => DocsMetrics.body.copyWith(
      fontWeight: FontWeight.w600,
      color: DocsMetrics.headingText,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final List<md.Node> nodes = md.Document(
      extensionSet: md.ExtensionSet.gitHubWeb,
    ).parse(source);
    if (skipLeadingHeading &&
        nodes.isNotEmpty &&
        nodes.first is md.Element &&
        (nodes.first as md.Element).tag == 'h1') {
      nodes.removeAt(0);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[for (final md.Node node in nodes) _block(node)],
    );
  }

  Widget _block(md.Node node) {
    if (node is! md.Element) {
      final String text = node.textContent.trim();
      return text.isEmpty
          ? const SizedBox.shrink()
          : Text(text, style: DocsMetrics.body);
    }

    switch (node.tag) {
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        final int level = int.parse(node.tag.substring(1));
        return Padding(
          padding: EdgeInsets.only(top: level <= 2 ? 32 : 24, bottom: 12),
          child: Text.rich(
            _inline(node.children, _headingStyle(level)),
            style: _headingStyle(level),
          ),
        );

      case 'p':
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text.rich(
            _inline(node.children, DocsMetrics.body),
            style: DocsMetrics.body,
          ),
        );

      case 'ul':
      case 'ol':
        final List<md.Element> items = (node.children ?? <md.Node>[])
            .whereType<md.Element>()
            .where((md.Element e) => e.tag == 'li')
            .toList();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final (int i, md.Element item) in items.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        node.tag == 'ol' ? '${i + 1}.  ' : '•  ',
                        style: DocsMetrics.body,
                      ),
                      Expanded(
                        child: Text.rich(
                          _inline(_undent(item.children), DocsMetrics.body),
                          style: DocsMetrics.body,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );

      case 'pre':
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5),
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  _unescape(node.textContent).trimRight(),
                  style: _code.copyWith(color: DocsMetrics.bodyText),
                ),
              ),
            ),
          ),
        );

      case 'blockquote':
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: DocsMetrics.border, width: 3),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (final md.Node child in node.children ?? <md.Node>[])
                    _block(child),
                ],
              ),
            ),
          ),
        );

      case 'hr':
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: ColoredBox(
            color: DocsMetrics.rule,
            child: SizedBox(height: 1, width: double.infinity),
          ),
        );

      case 'table':
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _table(node),
        );

      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (final md.Node child in node.children ?? <md.Node>[])
              _block(child),
          ],
        );
    }
  }

  /// A pipe table, laid out with `Table` so the columns line up the way the
  /// pipes promise.
  Widget _table(md.Element node) {
    final List<md.Element> rows = <md.Element>[];
    for (final md.Node part in node.children ?? <md.Node>[]) {
      if (part is md.Element && (part.tag == 'thead' || part.tag == 'tbody')) {
        rows.addAll(
          (part.children ?? <md.Node>[]).whereType<md.Element>().where(
            (md.Element e) => e.tag == 'tr',
          ),
        );
      }
    }
    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: DocsMetrics.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Table(
        border: TableBorder.symmetric(
          inside: const BorderSide(color: DocsMetrics.rule),
        ),
        defaultVerticalAlignment: TableCellVerticalAlignment.top,
        children: <TableRow>[
          for (final md.Element row in rows)
            TableRow(
              children: <Widget>[
                for (final md.Element cell
                    in (row.children ?? <md.Node>[]).whereType<md.Element>())
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Text.rich(
                      _inline(
                        cell.children,
                        cell.tag == 'th'
                            ? DocsMetrics.body.copyWith(
                                fontWeight: FontWeight.w600,
                                color: DocsMetrics.headingText,
                              )
                            : DocsMetrics.body,
                      ),
                      style: DocsMetrics.body,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  /// `package:markdown` HTML-escapes text nodes as it parses, because its own
  /// output target is HTML. We render to widgets, so the entities have to come
  /// back out or a `List<Widget>` reads as `List&lt;Widget&gt;`.
  static String _unescape(String text) => text
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&amp;', '&');

  /// Flattens inline nodes into one span tree.
  /// Drops the indent `package:markdown` leaves on a list item's first line.
  ///
  /// CommonMark says a marker followed by one to four spaces starts its content
  /// after them, so `-   **Customizable**: …` is the label. The parser only eats
  /// ONE, and hands back the other two as a leading `md.Text('  ')` — so every
  /// bullet on the Concepts pages rendered two spaces past its own bullet, out
  /// of line with itself and with the prose around it. Fixed here rather than by
  /// respacing those two documents: the markdown is captured upstream content,
  /// and the next capture would bring the indent straight back.
  List<md.Node>? _undent(List<md.Node>? nodes) {
    if (nodes == null || nodes.isEmpty) return nodes;
    final md.Node first = nodes.first;
    if (first is! md.Text) return nodes;
    final String trimmed = first.text.trimLeft();
    if (trimmed == first.text) return nodes;
    return <md.Node>[
      if (trimmed.isNotEmpty) md.Text(trimmed),
      ...nodes.skip(1),
    ];
  }

  TextSpan _inline(List<md.Node>? nodes, TextStyle base) {
    final List<InlineSpan> spans = <InlineSpan>[];

    void walk(List<md.Node>? children, TextStyle style) {
      for (final md.Node node in children ?? <md.Node>[]) {
        if (node is md.Text) {
          spans.add(TextSpan(text: _unescape(node.text), style: style));
          continue;
        }
        if (node is! md.Element) {
          continue;
        }
        switch (node.tag) {
          case 'strong':
            walk(node.children, style.copyWith(fontWeight: FontWeight.w600));
          case 'em':
            walk(node.children, style.copyWith(fontStyle: FontStyle.italic));
          case 'code':
            spans.add(
              TextSpan(
                text: _unescape(node.textContent),
                style: style.merge(_code).copyWith(color: DocsMetrics.bodyText),
              ),
            );
          case 'a':
            // Rendered, not clickable: every link in this corpus points into
            // Microsoft's own repository, and a document viewer that navigates
            // away from itself is a surprise, not a feature.
            walk(node.children, style.copyWith(color: DocsMetrics.railActive));
          case 'br':
            spans.add(const TextSpan(text: '\n'));
          default:
            walk(node.children, style);
        }
      }
    }

    walk(nodes, base);
    return TextSpan(children: spans);
  }
}
