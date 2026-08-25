import 'catalog.dart';

/// Serialises a page back to the markdown it was built from.
///
/// Upstream's "Copy Page" and "View as Markdown" both hand over the same
/// document — the `llms/<page>.txt` file its docs are generated from. Ours
/// rebuilds that document from the catalog instead of shipping a second copy of
/// it, so the two cannot disagree.
String pageAsMarkdown(DocsPage page) {
  // A page that *is* a markdown document hands over its own source rather than
  // a reconstruction of it.
  final String? source = page.markdown;
  if (source != null) {
    return source;
  }

  final StringBuffer out = StringBuffer()
    ..writeln('# ${page.title}')
    ..writeln();

  if (page.description.isNotEmpty) {
    out
      ..writeln(page.description)
      ..writeln();
  }

  for (final ProseBlock block in page.prose) {
    out
      ..writeln('## ${block.title}')
      ..writeln()
      ..writeln(block.body)
      ..writeln();
  }

  if (page.props.isNotEmpty) {
    out
      ..writeln('## Props')
      ..writeln()
      ..writeln('| Name | Type | Default | Description |')
      ..writeln('|------|------|---------|-------------|');
    for (final PropRow row in page.props) {
      out.writeln(
        '| `${row.name}` '
        '| `${row.type}` '
        '| ${row.defaultValue == null ? '—' : '`${row.defaultValue}`'} '
        '| ${row.description ?? ''} |',
      );
    }
    out.writeln();
  }

  if (page.sections.isNotEmpty) {
    out
      ..writeln('## Examples')
      ..writeln();
    for (final DocsSection section in page.sections) {
      out
        ..writeln('### ${section.title}')
        ..writeln();
      if (section.description != null) {
        out
          ..writeln(section.description)
          ..writeln();
      }
    }
  }

  return out.toString();
}
