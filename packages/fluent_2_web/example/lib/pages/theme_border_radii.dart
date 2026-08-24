import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';
import '../shell/docs_metrics.dart';
import '../shell/widgets/token_table.dart';

/// The Border Radii theme page.
const DocsPage themeBorderRadiiPage = DocsPage(
  id: 'theme-border-radii',
  title: 'Border Radii',
  description:
      'Corner radius tokens. A component names the shape it wants rather than '
      'a number, so rounding stays consistent across the system.',
  source: 'lib/pages/theme_border_radii.dart',
  sections: <DocsSection>[],
  body: _body,
);

/// Upstream's names beside ours. React flattens the ramp past XLarge into
/// `borderRadius2XLarge`..`6XLarge`; ours spells them `xxLarge`..`xxxxxxLarge`.
/// Both are listed because the page exists to make the two comparable.
const List<(String, String, Radius)> _ramp = <(String, String, Radius)>[
  ('borderRadiusNone', 'FluentRadius.none', FluentRadius.none),
  ('borderRadiusSmall', 'FluentRadius.small', FluentRadius.small),
  ('borderRadiusMedium', 'FluentRadius.medium', FluentRadius.medium),
  ('borderRadiusLarge', 'FluentRadius.large', FluentRadius.large),
  ('borderRadiusXLarge', 'FluentRadius.xLarge', FluentRadius.xLarge),
  ('borderRadius2XLarge', 'FluentRadius.xxLarge', FluentRadius.xxLarge),
  ('borderRadius3XLarge', 'FluentRadius.xxxLarge', FluentRadius.xxxLarge),
  ('borderRadius4XLarge', 'FluentRadius.xxxxLarge', FluentRadius.xxxxLarge),
  ('borderRadius5XLarge', 'FluentRadius.xxxxxLarge', FluentRadius.xxxxxLarge),
  ('borderRadius6XLarge', 'FluentRadius.xxxxxxLarge', FluentRadius.xxxxxxLarge),
  ('borderRadiusCircular', 'FluentRadius.circular', FluentRadius.circular),
];

Widget _body(BuildContext context) {
  final Color brand = FluentTheme.of(context).colors.brandBackground;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      TokenTable(
        rows: <TokenRow>[
          for (final (String name, String _, Radius radius) in _ramp)
            TokenRow(
              name: name,
              preview: Container(
                width: 64,
                height: 40,
                decoration: BoxDecoration(
                  color: brand,
                  borderRadius: BorderRadius.all(radius),
                ),
              ),
              // `circular` is 9999 here where React writes 10000. Both mean
              // "as round as the box allows"; printing our number keeps the
              // page honest about what the code does.
              value: radius == FluentRadius.circular
                  ? '9999px'
                  : '${radius.x.toStringAsFixed(0)}px',
            ),
        ],
      ),
      const SizedBox(height: 16),
      Text(
        'Dart names differ past XLarge: borderRadius2XLarge is '
        'FluentRadius.xxLarge, and so on up to FluentRadius.xxxxxxLarge.',
        style: DocsMetrics.body,
      ),
    ],
  );
}
