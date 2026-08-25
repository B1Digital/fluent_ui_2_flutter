import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../docs_metrics.dart';

/// Renders the markdown upstream actually writes in its docs prose.
///
/// The captured text is markdown, not plain text: descriptions carry `**bold**`,
/// `` `code` ``, `[links](url)`, `- ` bullets and the odd `#### ` sub-heading.
/// Printing it raw is the difference between a paragraph and a paragraph with
/// asterisks in it.
///
/// Deliberately not a markdown *parser* — there is no nesting, no tables and no
/// block quotes in this corpus. It handles the four inline forms and two block
/// forms that appear, and anything else falls through as text, which is the
/// correct failure mode for a docs page.
class DocsProse extends StatelessWidget {
  /// Renders [text] in [style], defaulting to body copy.
  const DocsProse(this.text, {super.key, this.style});

  /// The markdown source.
  final String text;

  /// Base style; inline spans layer on top of it.
  final TextStyle? style;

  static const TextStyle _code = TextStyle(
    fontFamily: FluentFontFamily.monospace,
    fontFamilyFallback: FluentFontFamily.monospaceFallback,
    fontSize: 13,
  );

  /// Splits into blocks on real newlines.
  ///
  /// Bullets and `####` sub-headings are only recognised at the start of a
  /// line. An earlier version searched for the markers anywhere, which read the
  /// hyphen in "x-axis labels - it should start" as a bullet — markdown is
  /// line-oriented and so is this.
  static List<String> _blocks(String source) => source
      .split('\n')
      .map((String l) => l.trim())
      .where((String l) => l.isNotEmpty)
      .toList();

  static final RegExp _inline = RegExp(
    r'\*\*(.+?)\*\*|`(.+?)`|\[(.+?)\]\((.+?)\)',
    dotAll: true,
  );

  static List<InlineSpan> _spans(String line, TextStyle base) {
    final List<InlineSpan> out = <InlineSpan>[];
    int cursor = 0;
    for (final RegExpMatch m in _inline.allMatches(line)) {
      if (m.start > cursor) {
        out.add(TextSpan(text: line.substring(cursor, m.start)));
      }
      if (m.group(1) != null) {
        out.add(
          TextSpan(
            text: m.group(1),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        );
      } else if (m.group(2) != null) {
        out.add(TextSpan(text: m.group(2), style: _code));
      } else {
        // The link target is dropped rather than made clickable: every one of
        // them points into Microsoft's own repository, and a docs page that
        // silently navigates away from the showroom is worse than one that
        // shows the words.
        out.add(
          TextSpan(
            text: m.group(3),
            style: TextStyle(color: DocsMetrics.railActive),
          ),
        );
      }
      cursor = m.end;
    }
    if (cursor < line.length) {
      out.add(TextSpan(text: line.substring(cursor)));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle base = style ?? DocsMetrics.body;
    final List<String> blocks = _blocks(text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final String block in blocks)
          if (block.startsWith('### ') || block.startsWith('#### '))
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 6),
              child: Text(
                block.substring(block.startsWith('#### ') ? 5 : 4),
                style: base.copyWith(
                  fontWeight: FontWeight.w600,
                  color: DocsMetrics.headingText,
                ),
              ),
            )
          else if (block.startsWith('- '))
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('•  ', style: base),
                  Expanded(
                    child: Text.rich(
                      TextSpan(children: _spans(block.substring(2), base)),
                      style: base,
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text.rich(
                TextSpan(children: _spans(block, base)),
                style: base,
              ),
            ),
      ],
    );
  }
}
