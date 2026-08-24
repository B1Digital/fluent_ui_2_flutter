import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';
import '../shell/docs_metrics.dart';

/// The Colors theme page.
///
/// Upstream renders one row per alias token with a swatch and a hex per theme:
/// Design Token, Light, Dark, Teams Light, Teams Dark, Teams High Contrast.
/// This is the same table, computed from our own tokens — `FluentColorToken`
/// has all 228 and `FluentColors.resolve` answers for any variant, so the page
/// stays correct by construction rather than by transcription.
const DocsPage themeColorsPage = DocsPage(
  id: 'theme-colors',
  title: 'Colors',
  description:
      'Color tokens are the semantic layer of the palette: a component names '
      'the role it needs and the theme decides the value. The table below '
      'resolves every alias token against each shipped theme.',
  source: 'lib/pages/theme_colors.dart',
  sections: <DocsSection>[],
  body: _body,
);

/// The themes upstream's table columns name, in its order.
const List<(String, FluentColors)> _columns = <(String, FluentColors)>[
  ('Light', FluentColors()),
  ('Dark', FluentColors(brightness: Brightness.dark)),
  ('Teams Light', FluentColors(brand: FluentBrandRamp.teams)),
  ('Teams Dark', FluentTeamsDarkColors()),
  ('Teams High Contrast', FluentHighContrastColors()),
];

Widget _body(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        '${FluentColorToken.values.length} alias tokens',
        style: DocsMetrics.h3,
      ),
      const SizedBox(height: 16),
      DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: DocsMetrics.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: <Widget>[
            const _HeaderRow(),
            for (final FluentColorToken token in FluentColorToken.values)
              _TokenRow(token: token),
          ],
        ),
      ),
    ],
  );
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: DocsMetrics.border)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(flex: 4, child: Text('Design Token', style: style)),
          for (final (String label, FluentColors _) in _columns)
            Expanded(flex: 3, child: Text(label, style: style)),
        ],
      ),
    );
  }
}

class _TokenRow extends StatelessWidget {
  const _TokenRow({required this.token});

  final FluentColorToken token;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: DocsMetrics.rule)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Text(
              // Upstream prints React's name, which is ours with a `color`
              // prefix.
              'color${token.name[0].toUpperCase()}${token.name.substring(1)}',
              style: const TextStyle(
                fontFamily: FluentFontFamily.monospace,
                fontFamilyFallback: FluentFontFamily.monospaceFallback,
                fontSize: 12,
                height: 18 / 12,
                color: DocsMetrics.bodyText,
              ),
            ),
          ),
          for (final (String _, FluentColors colors) in _columns)
            Expanded(flex: 3, child: _Swatch(color: colors.resolve(token))),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color});

  final Color color;

  /// `#rrggbb`, or `#rrggbbaa` when the token carries alpha — several of the
  /// `*Alpha` and shadow tokens do, and printing them opaque would be a lie.
  String get _hex {
    final int argb = color.toARGB32();
    final String rgb = (argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
    final int alpha = argb >>> 24;
    if (alpha == 0xFF) {
      return '#$rgb';
    }
    return '#$rgb${alpha.toRadixString(16).padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: DocsMetrics.border),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            _hex,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: FluentFontFamily.monospace,
              fontFamilyFallback: FluentFontFamily.monospaceFallback,
              fontSize: 12,
              height: 18 / 12,
              color: DocsMetrics.bodyText,
            ),
          ),
        ),
      ],
    );
  }
}
