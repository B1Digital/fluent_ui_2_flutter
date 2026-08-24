import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../docs_metrics.dart';

/// One row of a Theme page's token table.
@immutable
class TokenRow {
  /// Creates a row.
  const TokenRow({required this.name, this.preview, this.value});

  /// The token name, as the React Storybook prints it (`spacingHorizontalM`).
  ///
  /// Our Dart identifiers differ — `FluentSpacing.horizontal.m` — because the
  /// Dart tokens are nested rather than flattened into one namespace. The page
  /// shows upstream's name so the two are comparable at a glance; the code that
  /// produced the value is right beside it in the source.
  final String name;

  /// A visual rendering of the token, drawn at its own value where that means
  /// something (a 16px radius square, a 2px rule).
  final Widget? preview;

  /// The resolved value, e.g. `12px`.
  final String? value;
}

/// The table shape every Theme page uses.
class TokenTable extends StatelessWidget {
  /// Renders [rows] under an optional [title].
  const TokenTable({super.key, required this.rows, this.title});

  /// The rows, in order.
  final List<TokenRow> rows;

  /// A `###` heading above the table, matching upstream's grouping.
  final String? title;

  static const TextStyle _mono = TextStyle(
    fontFamily: FluentFontFamily.monospace,
    fontFamilyFallback: FluentFontFamily.monospaceFallback,
    fontSize: 13,
    height: 20 / 13,
    color: DocsMetrics.bodyText,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (title != null) ...<Widget>[
          const SizedBox(height: 32),
          Text(title!, style: DocsMetrics.h3),
          const SizedBox(height: 16),
        ],
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: DocsMetrics.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: <Widget>[
              for (int i = 0; i < rows.length; i += 1)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: i == rows.length - 1
                        ? null
                        : const Border(
                            bottom: BorderSide(color: DocsMetrics.rule),
                          ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        flex: 4,
                        child: Text(rows[i].name, style: _mono),
                      ),
                      Expanded(
                        flex: 5,
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: rows[i].preview ?? const SizedBox.shrink(),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(rows[i].value ?? '', style: _mono),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
