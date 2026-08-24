import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';
import '../shell/docs_metrics.dart';
import '../shell/widgets/token_table.dart';

/// The Stroke Widths theme page.
const DocsPage themeStrokeWidthsPage = DocsPage(
  id: 'theme-stroke-widths',
  title: 'Stroke Widths',
  description:
      'Border and divider thicknesses. Keeping them on a ramp is what stops a '
      'focus ring, a card outline and a table rule from each picking their own '
      'hairline.',
  source: 'lib/pages/theme_stroke_widths.dart',
  sections: <DocsSection>[],
  body: _body,
);

/// React's web set is the four named below. `FluentStroke` also carries `none`,
/// `hairline`, `width15` and `width60` for the mobile surfaces, which is why
/// this list is written out rather than iterated.
const List<(String, double)> _ramp = <(String, double)>[
  ('strokeWidthThin', FluentStroke.thin),
  ('strokeWidthThick', FluentStroke.thick),
  ('strokeWidthThicker', FluentStroke.thicker),
  ('strokeWidthThickest', FluentStroke.thickest),
];

/// Present in `fluent_2_core` but not in React's web token set.
const List<(String, double)> _extra = <(String, double)>[
  ('FluentStroke.none', FluentStroke.none),
  ('FluentStroke.hairline', FluentStroke.hairline),
  ('FluentStroke.width15', FluentStroke.width15),
  ('FluentStroke.width60', FluentStroke.width60),
];

Widget _body(BuildContext context) {
  final Color stroke = FluentTheme.of(context).colors.neutralStroke1;
  Widget rule(double width) => Container(
    height: width == 0 ? 1 : width,
    width: 180,
    color: width == 0 ? const Color(0x00000000) : stroke,
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      TokenTable(
        rows: <TokenRow>[
          for (final (String name, double width) in _ramp)
            TokenRow(name: name, preview: rule(width), value: '${width}px'),
        ],
      ),
      TokenTable(
        title: 'Beyond the web set',
        rows: <TokenRow>[
          for (final (String name, double width) in _extra)
            TokenRow(name: name, preview: rule(width), value: '${width}px'),
        ],
      ),
      const SizedBox(height: 16),
      Text(
        'The second table has no React counterpart; those stops exist for the '
        'mobile surfaces, where a hairline is a real measurement rather than a '
        'rounding artefact.',
        style: DocsMetrics.body,
      ),
    ],
  );
}
