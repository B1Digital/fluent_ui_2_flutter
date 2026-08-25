import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';
import '../shell/docs_metrics.dart';

/// The Shadows theme page.
///
/// Upstream's table is Shadow | Light | Dark | High Contrast, and every cell is
/// both the specimen and the caption: a box carrying the real `BoxShadow` pair,
/// with the CSS that pair resolves to printed inside it. The six neutral levels
/// come first, then the same six cast onto brand colour.
const DocsPage themeShadowsPage = DocsPage(
  id: 'theme-shadows',
  title: 'Shadows',
  description: '',
  source: 'lib/pages/theme_shadows.dart',
  sections: <DocsSection>[],
  body: _body,
);

/// Width of the leading `Shadow` column. Measured off the live page.
const double _labelWidth = 175;

/// Gutter between the three theme columns. There is none before the first.
const double _columnGap = 78;

/// The specimen box is exactly two lines of [_mono] tall.
const double _swatchHeight = 40;

/// Cells clear 40px above and below, giving upstream's 120px row pitch.
const EdgeInsets _cellPadding = EdgeInsets.symmetric(vertical: 40);

/// The header row's own padding. Its 20px line box sits 13px below the card's
/// padding box and clears 56px before the first specimen row — 89px in all
/// from the top of the content box to the top of the first row.
const EdgeInsets _headerPadding = EdgeInsets.only(top: 13, bottom: 56);

const TextStyle _mono = TextStyle(
  fontFamily: FluentFontFamily.monospace,
  fontFamilyFallback: FluentFontFamily.monospaceFallback,
  fontSize: 11,
  height: 20 / 11,
  leadingDistribution: TextLeadingDistribution.even,
);

Widget _body(BuildContext context) {
  final FluentColors colors = FluentTheme.of(context).colors;
  final List<(String, FluentThemeData)> themes = <(String, FluentThemeData)>[
    ('Light', FluentThemeData.light()),
    ('Dark', FluentThemeData.dark()),
    ('High Contrast', FluentThemeData.highContrast()),
  ];
  final TextStyle header = DocsMetrics.body.copyWith(
    fontSize: 16,
    height: 20 / 16,
    fontWeight: FontWeight.w600,
  );

  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: colors.neutralBackground1,
      border: Border.all(color: DocsMetrics.border),
      borderRadius: BorderRadius.circular(DocsMetrics.cardRadius),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: _headerPadding,
          child: _tableRow(_clipped('Shadow', header), <Widget>[
            for (final (String label, FluentThemeData _) in themes)
              _clipped(label, header),
          ]),
        ),
        // Neutral levels first, then the same six cast onto brand colour —
        // which is why the brand rows repeat the elevation list rather than
        // sitting beside it.
        for (final bool onBrand in <bool>[false, true])
          for (final FluentElevation level in FluentElevation.values)
            _tableRow(
              _clipped(
                onBrand ? '${level.name}Brand' : level.name,
                DocsMetrics.body,
              ),
              <Widget>[
                for (final (String _, FluentThemeData theme) in themes)
                  Padding(
                    padding: _cellPadding,
                    child: _Swatch(
                      shadows: onBrand
                          ? theme.brandShadow(level)
                          : theme.shadow(level),
                      onBrand: onBrand,
                    ),
                  ),
              ],
            ),
      ],
    ),
  );
}

/// One line of the table: a fixed label column, then three equal theme columns
/// separated by [_columnGap].
Widget _tableRow(Widget label, List<Widget> cells) => Row(
  children: <Widget>[
    SizedBox(width: _labelWidth, child: label),
    for (int i = 0; i < cells.length; i++) ...<Widget>[
      if (i > 0) const SizedBox(width: _columnGap),
      Expanded(child: cells[i]),
    ],
  ],
);

/// A single line that ellipsises rather than wrapping — the label column is a
/// fixed width and the specimen box a fixed height, so neither can grow.
Widget _clipped(String text, TextStyle style) =>
    Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);

/// The CSS `box-shadow` layer [shadow] resolves to, in upstream's notation —
/// a bare `0` for the zero offset, since CSS lengths of zero carry no unit.
String _css(BoxShadow shadow) {
  final double dy = shadow.offset.dy;
  return '0 ${dy == 0 ? '0' : '${dy.toStringAsFixed(0)}px'} '
      '${shadow.blurRadius.toStringAsFixed(0)}px '
      'rgba(0,0,0,${shadow.color.a.toStringAsFixed(2)})';
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.shadows, required this.onBrand});

  final List<BoxShadow> shadows;

  /// Brand specimens sit on brand colour, because that is the surface whose
  /// luminosity produced their heavier 30%/25% opacities.
  final bool onBrand;

  @override
  Widget build(BuildContext context) {
    final FluentColors colors = FluentTheme.of(context).colors;
    return Container(
      height: _swatchHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: onBrand ? FluentBrandRamp.teams[80] : colors.neutralBackground1,
        boxShadow: shadows,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final BoxShadow shadow in shadows)
            _clipped(
              _css(shadow),
              _mono.copyWith(
                color: onBrand
                    ? colors.neutralForegroundOnBrand
                    : DocsMetrics.bodyText,
              ),
            ),
        ],
      ),
    );
  }
}
