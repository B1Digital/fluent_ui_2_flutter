import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../catalog.dart';
import '../docs_metrics.dart';

/// The API table under a page's sections.
///
/// Upstream's table documents the React component's props. Ours documents the
/// Dart constructor, because a table that reproduced `as`, `focusgroup` and
/// `slot` would be pixel-accurate and wrong about every widget in this package.
/// The chrome is upstream's; the rows are ours.
class PropsTable extends StatelessWidget {
  /// Renders [rows].
  const PropsTable({super.key, required this.rows});

  /// The constructor parameters to document.
  final List<PropRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 48),
        Text('Props', style: DocsMetrics.h2),
        const SizedBox(height: 15),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: DocsMetrics.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: <Widget>[
              const _HeaderRow(),
              for (int i = 0; i < rows.length; i += 1)
                _BodyRow(row: rows[i], last: i == rows.length - 1),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final TextStyle style = DocsMetrics.body.copyWith(
      fontWeight: FontWeight.w600,
      color: DocsMetrics.headingText,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: DocsMetrics.border)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(flex: 3, child: Text('Name', style: style)),
          Expanded(flex: 6, child: Text('Description', style: style)),
          Expanded(flex: 3, child: Text('Default', style: style)),
        ],
      ),
    );
  }
}

class _BodyRow extends StatelessWidget {
  const _BodyRow({required this.row, required this.last});

  final PropRow row;
  final bool last;

  @override
  Widget build(BuildContext context) {
    const TextStyle mono = TextStyle(
      fontFamily: FluentFontFamily.monospace,
      fontFamilyFallback: FluentFontFamily.monospaceFallback,
      fontSize: 13,
      height: 20 / 13,
      color: DocsMetrics.bodyText,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: DocsMetrics.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(flex: 3, child: Text(row.name, style: mono)),
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (row.description != null)
                  Text(row.description!, style: DocsMetrics.body),
                Text(
                  row.type,
                  style: mono.copyWith(
                    color: DocsMetrics.bodyText.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 3, child: Text(row.defaultValue ?? '—', style: mono)),
        ],
      ),
    );
  }
}
