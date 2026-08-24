import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';
import '../shell/docs_metrics.dart';
import '../shell/widgets/token_table.dart';

/// The Spacing theme page.
///
/// Upstream splits the ramp into Vertical and Horizontal tables. Ours carries
/// the same split even though `FluentSpacing.vertical` and
/// `.horizontal` currently resolve to identical values — the two axes are
/// separate tokens precisely so one can move without the other, and collapsing
/// them here would hide that.
const DocsPage themeSpacingPage = DocsPage(
  id: 'theme-spacing',
  title: 'Spacing',
  description:
      'Spacing tokens describe the gaps between elements. Vertical and '
      'horizontal are separate ramps so a layout can breathe differently along '
      'each axis.',
  source: 'lib/pages/theme_spacing.dart',
  sections: <DocsSection>[],
  body: _body,
);

/// The ramp, in upstream's order. `FluentSpacing` is a set of `static const`
/// doubles with no reflection over them, so the names are written out.
const List<(String, double)> _ramp = <(String, double)>[
  ('None', FluentSpacing.none),
  ('XXS', FluentSpacing.xxs),
  ('XS', FluentSpacing.xs),
  ('SNudge', FluentSpacing.sNudge),
  ('S', FluentSpacing.s),
  ('MNudge', FluentSpacing.mNudge),
  ('M', FluentSpacing.m),
  ('L', FluentSpacing.l),
  ('XL', FluentSpacing.xl),
  ('XXL', FluentSpacing.xxl),
  ('XXXL', FluentSpacing.xxxl),
];

Widget _body(BuildContext context) {
  final Color brand = FluentTheme.of(context).colors.brandBackground;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      for (final String axis in <String>['Vertical', 'Horizontal'])
        TokenTable(
          title: axis,
          rows: <TokenRow>[
            for (final (String name, double value) in _ramp)
              TokenRow(
                name: 'spacing$axis$name',
                // `none` and `xxs` would be invisible at their own size, so the
                // bar has a floor. The number beside it is the truth.
                preview: Container(
                  width: axis == 'Horizontal' ? (value < 2 ? 2 : value) : 24,
                  height: axis == 'Horizontal' ? 20 : (value < 2 ? 2 : value),
                  color: brand,
                ),
                value: '${value.toStringAsFixed(0)}px',
              ),
          ],
        ),
      const SizedBox(height: 16),
      Text(
        'In Dart these are FluentSpacing.vertical.<name> and '
        'FluentSpacing.horizontal.<name>; the flattened names above are the '
        'ones the React tokens use.',
        style: DocsMetrics.body,
      ),
    ],
  );
}
