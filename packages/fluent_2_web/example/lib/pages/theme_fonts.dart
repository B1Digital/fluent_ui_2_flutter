import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';
import '../shell/docs_metrics.dart';
import '../shell/widgets/token_table.dart';

/// The Fonts theme page: family, size, weight and line-height ramps.
const DocsPage themeFontsPage = DocsPage(
  id: 'theme-fonts',
  title: 'Fonts',
  description:
      'The primitive type tokens. Typography styles are built from these; a '
      'component should normally reach for a style rather than a raw size.',
  source: 'lib/pages/theme_fonts.dart',
  sections: <DocsSection>[],
  body: _body,
);

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

const List<(String, FontWeight)> _weights = <(String, FontWeight)>[
  ('fontWeightRegular', FluentFontWeight.regular),
  ('fontWeightMedium', FluentFontWeight.medium),
  ('fontWeightSemibold', FluentFontWeight.semibold),
  ('fontWeightBold', FluentFontWeight.bold),
];

Widget _body(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      TokenTable(
        title: 'Font family',
        rows: <TokenRow>[
          TokenRow(
            name: 'fontFamilyBase',
            preview: const Text(
              'Fluent 2',
              style: TextStyle(fontFamily: FluentFontFamily.base, fontSize: 16),
            ),
            value: FluentFontFamily.base,
          ),
          TokenRow(
            name: 'fontFamilyMonospace',
            preview: const Text(
              'Fluent 2',
              style: TextStyle(
                fontFamily: FluentFontFamily.monospace,
                fontFamilyFallback: FluentFontFamily.monospaceFallback,
                fontSize: 16,
              ),
            ),
            value: FluentFontFamily.monospace,
          ),
          TokenRow(
            name: 'fontFamilyNumeric',
            preview: const Text(
              '0123456789',
              style: TextStyle(
                fontFamily: FluentFontFamily.numeric,
                fontFamilyFallback: FluentFontFamily.numericFallback,
                fontSize: 16,
              ),
            ),
            value: FluentFontFamily.numeric,
          ),
        ],
      ),
      TokenTable(
        title: 'Font size',
        rows: <TokenRow>[
          for (final (String name, double size) in _sizes)
            TokenRow(
              name: name,
              preview: Text('Fluent 2', style: TextStyle(fontSize: size)),
              value: '${size.toStringAsFixed(0)}px',
            ),
        ],
      ),
      TokenTable(
        title: 'Line height',
        rows: <TokenRow>[
          for (final (String name, double height) in _lineHeights)
            TokenRow(name: name, value: '${height.toStringAsFixed(0)}px'),
        ],
      ),
      TokenTable(
        title: 'Font weight',
        rows: <TokenRow>[
          for (final (String name, FontWeight weight) in _weights)
            TokenRow(
              name: name,
              preview: Text(
                'Fluent 2',
                style: TextStyle(fontSize: 16, fontWeight: weight),
              ),
              value: '${weight.value}',
            ),
        ],
      ),
      const SizedBox(height: 16),
      Text(
        'Segoe UI is not redistributable, so the base family resolves to '
        'Selawik — the metric-compatible open substitute this design system '
        'ships. Sizes and line heights are unchanged.',
        style: DocsMetrics.body,
      ),
    ],
  );
}
