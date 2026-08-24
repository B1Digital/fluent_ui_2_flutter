import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';
import '../shell/docs_metrics.dart';

/// The Typography theme page.
const DocsPage themeTypographyPage = DocsPage(
  id: 'theme-typography',
  title: 'Typography',
  description:
      'Typography style is represented by a set of tokens instead of an '
      'individual token. The tokens are used to create and share a consistent '
      'look and feel.',
  source: 'lib/pages/theme_typography.dart',
  sections: <DocsSection>[],
  body: _body,
);

/// The ramp in ascending size order, paired with the accessor that produces it.
/// Written out because `FluentTypography` exposes 18 named fields rather than a
/// map, so there is nothing to iterate.
List<(String, TextStyle)> _ramp(FluentTypography t) => <(String, TextStyle)>[
  ('caption2', t.caption2),
  ('caption2Strong', t.caption2Strong),
  ('caption1', t.caption1),
  ('caption1Strong', t.caption1Strong),
  ('caption1Stronger', t.caption1Stronger),
  ('body1', t.body1),
  ('body1Strong', t.body1Strong),
  ('body1Stronger', t.body1Stronger),
  ('body2', t.body2),
  ('body2Strong', t.body2Strong),
  ('subtitle2', t.subtitle2),
  ('subtitle2Stronger', t.subtitle2Stronger),
  ('subtitle1', t.subtitle1),
  ('title3', t.title3),
  ('title2', t.title2),
  ('title1', t.title1),
  ('largeTitle', t.largeTitle),
  ('display', t.display),
];

Widget _body(BuildContext context) {
  final FluentTypography type = FluentTheme.of(context).typography;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text('How to use', style: DocsMetrics.h3),
      const SizedBox(height: 12),
      Text(
        'Reach for a style rather than a raw size: '
        'Text(\'…\', style: FluentTheme.of(context).typography.body1Strong). '
        'The styles arrive pre-painted with neutralForeground1, so text picks '
        'up the right colour without being told.',
        style: DocsMetrics.body,
      ),
      const SizedBox(height: 32),
      Text('The ramp', style: DocsMetrics.h3),
      const SizedBox(height: 16),
      DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: DocsMetrics.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: <Widget>[
            for (final (String name, TextStyle style) in _ramp(type))
              _Specimen(name: name, style: style),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Text(
        'subtitle1 has a 26px line height here where React ships 28. That is '
        'deliberate — fluent_2_core follows the published Fluent 2 docs table, '
        'which disagrees with the shipped TypeScript on this one row.',
        style: DocsMetrics.body,
      ),
    ],
  );
}

class _Specimen extends StatelessWidget {
  const _Specimen({required this.name, required this.style});

  final String name;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: DocsMetrics.rule)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Text(
              name,
              style: const TextStyle(
                fontFamily: FluentFontFamily.monospace,
                fontFamilyFallback: FluentFontFamily.monospaceFallback,
                fontSize: 13,
                color: DocsMetrics.bodyText,
              ),
            ),
          ),
          Expanded(flex: 7, child: Text('Fluent 2', style: style)),
          Expanded(
            flex: 2,
            child: Text(
              '${style.fontSize?.toStringAsFixed(0)}'
              '/'
              '${((style.fontSize ?? 0) * (style.height ?? 1)).toStringAsFixed(0)}'
              ' · ${style.fontWeight?.value}',
              style: const TextStyle(
                fontFamily: FluentFontFamily.monospace,
                fontFamilyFallback: FluentFontFamily.monospaceFallback,
                fontSize: 12,
                color: DocsMetrics.bodyText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
