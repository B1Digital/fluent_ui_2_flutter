import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';
import '../shell/docs_metrics.dart';

/// The Shadows theme page.
///
/// Upstream's table is Shadow | Light | Dark | High Contrast. Ours is the same,
/// rendered rather than described: each cell paints a real box with the real
/// `BoxShadow` list, because a shadow written as `0 2px 4px rgba(0,0,0,.14)` is
/// only meaningful once you can see it.
const DocsPage themeShadowsPage = DocsPage(
  id: 'theme-shadows',
  title: 'Shadows',
  description:
      'Elevation tokens. Each is a pair of shadows — a tight ambient one and a '
      'softer key one offset downward — so a surface reads as lifted rather '
      'than outlined.',
  source: 'lib/pages/theme_shadows.dart',
  sections: <DocsSection>[],
  body: _body,
);

Widget _body(BuildContext context) {
  final List<(String, FluentThemeData)> themes = <(String, FluentThemeData)>[
    ('Light', FluentThemeData.light()),
    ('Dark', FluentThemeData.dark()),
    ('High Contrast', FluentThemeData.highContrast()),
  ];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: DocsMetrics.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: DocsMetrics.border)),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Shadow',
                      style: DocsMetrics.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: DocsMetrics.headingText,
                      ),
                    ),
                  ),
                  for (final (String label, FluentThemeData _) in themes)
                    Expanded(
                      flex: 3,
                      child: Text(
                        label,
                        style: DocsMetrics.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: DocsMetrics.headingText,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            for (final FluentElevation level in FluentElevation.values)
              _ShadowRow(level: level, themes: themes),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Text(
        'Brand-tinted variants come from theme.brandShadow(level) with the same '
        'elevation values.',
        style: DocsMetrics.body,
      ),
    ],
  );
}

class _ShadowRow extends StatelessWidget {
  const _ShadowRow({required this.level, required this.themes});

  final FluentElevation level;
  final List<(String, FluentThemeData)> themes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: DocsMetrics.rule)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Text(
              level.name,
              style: const TextStyle(
                fontFamily: FluentFontFamily.monospace,
                fontFamilyFallback: FluentFontFamily.monospaceFallback,
                fontSize: 13,
                color: DocsMetrics.bodyText,
              ),
            ),
          ),
          for (final (String _, FluentThemeData theme) in themes)
            Expanded(
              flex: 3,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  // The swatch sits on the theme's own canvas, because a
                  // shadow's opacity is tuned for the surface beneath it and
                  // the dark ones vanish on white.
                  padding: const EdgeInsets.all(12),
                  color: theme.colors.neutralBackground3,
                  child: Container(
                    width: 72,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colors.neutralBackground1,
                      borderRadius: const BorderRadius.all(FluentRadius.medium),
                      boxShadow: theme.shadow(level),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
