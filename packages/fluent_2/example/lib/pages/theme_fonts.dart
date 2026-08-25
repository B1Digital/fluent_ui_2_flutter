import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';
import '../shell/docs_metrics.dart';

/// The Fonts theme page: family, size, weight and line-height ramps.
const DocsPage themeFontsPage = DocsPage(
  id: 'theme-fonts',
  title: 'Fonts',
  description: '',
  source: 'lib/pages/theme_fonts.dart',
  sections: <DocsSection>[],
  body: _body,
);

/// Every preview renders in the base family, at the token under discussion.
const TextStyle _preview = TextStyle(
  fontFamily: FluentFontFamily.base,
  fontFamilyFallback: FluentFontFamily.baseFallback,
  color: DocsMetrics.bodyText,
  leadingDistribution: TextLeadingDistribution.even,
);

/// The stacks, spelled the way a CSS `font-family` declaration would be — which
/// is what upstream prints in this column.
String _stack(String family, List<String> fallback) =>
    <String>[family, ...fallback].join(', ');

const List<(String, double)> _sizes = <(String, double)>[
  ('fontSizeBase100', FluentFontSize.base100),
  ('fontSizeBase200', FluentFontSize.base200),
  ('fontSizeBase300', FluentFontSize.base300),
  ('fontSizeBase400', FluentFontSize.base400),
  ('fontSizeBase500', FluentFontSize.base500),
  ('fontSizeBase600', FluentFontSize.base600),
  ('fontSizeHero700', FluentFontSize.hero700),
  ('fontSizeHero800', FluentFontSize.hero800),
  ('fontSizeHero900', FluentFontSize.hero900),
  ('fontSizeHero1000', FluentFontSize.hero1000),
];

const List<(String, FontWeight)> _weights = <(String, FontWeight)>[
  ('fontWeightRegular', FluentFontWeight.regular),
  ('fontWeightMedium', FluentFontWeight.medium),
  ('fontWeightSemibold', FluentFontWeight.semibold),
  ('fontWeightBold', FluentFontWeight.bold),
];

const List<(String, double)> _lineHeights = <(String, double)>[
  ('lineHeightBase100', FluentLineHeight.base100),
  ('lineHeightBase200', FluentLineHeight.base200),
  ('lineHeightBase300', FluentLineHeight.base300),
  ('lineHeightBase400', FluentLineHeight.base400),
  ('lineHeightBase500', FluentLineHeight.base500),
  ('lineHeightBase600', FluentLineHeight.base600),
  ('lineHeightHero700', FluentLineHeight.hero700),
  ('lineHeightHero800', FluentLineHeight.hero800),
  ('lineHeightHero900', FluentLineHeight.hero900),
  ('lineHeightHero1000', FluentLineHeight.hero1000),
];

/// A group heading. [top] is 0 for the first group so the card opens flush.
Widget _heading(String title, {double top = 32}) => Padding(
  padding: EdgeInsets.only(top: top, bottom: 12),
  child: Text(title, style: DocsMetrics.h3),
);

/// Name on the left, preview on the right.
///
/// The name column is intrinsic rather than a fixed width: upstream sizes it to
/// the widest name *in that group*, which is why the previews start at a
/// different x under every heading.
Widget _rows(List<(String, Widget)> rows) => Table(
  columnWidths: const <int, TableColumnWidth>{
    0: IntrinsicColumnWidth(),
    1: FlexColumnWidth(),
  },
  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
  children: <TableRow>[
    for (final (String name, Widget preview) in rows)
      TableRow(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 5, 16, 5),
            child: Text(name, style: DocsMetrics.body, softWrap: false),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: preview,
          ),
        ],
      ),
  ],
);

Widget _body(BuildContext context) {
  final FluentColors colors = FluentTheme.of(context).colors;
  // The line-height band is a swatch of the token itself, so it takes a real
  // neutral surface rather than a chrome literal.
  final Color band = colors.neutralBackground4;

  return Container(
    decoration: BoxDecoration(
      color: colors.neutralBackground1,
      border: Border.all(color: DocsMetrics.border),
      borderRadius: BorderRadius.circular(16),
    ),
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _heading('Font family', top: 0),
        _rows(<(String, Widget)>[
          (
            'fontFamilyBase',
            Text(
              _stack(FluentFontFamily.base, FluentFontFamily.baseFallback),
              style: _preview.copyWith(fontSize: FluentFontSize.base300),
            ),
          ),
          (
            'fontFamilyMonospace',
            Text(
              _stack(
                FluentFontFamily.monospace,
                FluentFontFamily.monospaceFallback,
              ),
              style: _preview.copyWith(
                fontFamily: FluentFontFamily.monospace,
                fontFamilyFallback: FluentFontFamily.monospaceFallback,
                fontSize: FluentFontSize.base300,
              ),
            ),
          ),
          (
            'fontFamilyNumeric',
            Text(
              _stack(
                FluentFontFamily.numeric,
                FluentFontFamily.numericFallback,
              ),
              style: _preview.copyWith(
                fontFamily: FluentFontFamily.numeric,
                fontFamilyFallback: FluentFontFamily.numericFallback,
                fontSize: FluentFontSize.base300,
              ),
            ),
          ),
        ]),
        _heading('Font size'),
        _rows(<(String, Widget)>[
          for (final (String name, double size) in _sizes)
            (
              name,
              // Line height 1: this band measures the *size* token, so the box
              // is exactly one em tall. The row still can't go under 30px —
              // the name beside it is 14/20 in 5px padding.
              Text(name, style: _preview.copyWith(fontSize: size, height: 1)),
            ),
        ]),
        _heading('Font weight'),
        _rows(<(String, Widget)>[
          for (final (String name, FontWeight weight) in _weights)
            (
              name,
              Text(
                'Font weight $name',
                style: _preview.copyWith(
                  fontSize: FluentFontSize.base300,
                  fontWeight: weight,
                ),
              ),
            ),
        ]),
        _heading('Line height'),
        _rows(<(String, Widget)>[
          for (final (String name, double height) in _lineHeights)
            (
              name,
              // The band *is* the measurement: a 14px line in a box exactly one
              // line-height tall, which is what the token controls.
              Container(
                width: double.infinity,
                color: band,
                child: Text(
                  name,
                  style: _preview.copyWith(
                    fontSize: FluentFontSize.base300,
                    height: height / FluentFontSize.base300,
                  ),
                ),
              ),
            ),
        ]),
      ],
    ),
  );
}
