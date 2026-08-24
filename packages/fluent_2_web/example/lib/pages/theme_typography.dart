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
///
/// Eighteen rows, not upstream's seventeen: `body2Strong` has no web entry in
/// React's `typographyStyles`, so the captured page jumps straight from `body2`
/// to `subtitle2`. It is a real field here — aliased to `subtitle2` on the web
/// and Linux ramps, distinct on every other one — and this table renders the
/// live theme, so dropping it would leave a public style undocumented on web
/// and wrong everywhere else. The chrome is upstream's; the rows are ours.
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

/// Printed in the Tokens column when a resolved value sits on no published
/// stop. Exactly one row reaches it: the web ramp's `subtitle1` line height is
/// 26px by deliberate divergence from `lineHeightBase500`, which is 28px — see
/// the note in `FluentTypography._webLike`. Naming the 500 stop there would be
/// a lie about which value it carries.
const String _noToken = '—';

/// The global font-size ramp keyed by the value it carries, so a resolved
/// style can name the token it came from rather than have one guessed for it.
final Map<double, String> _fontSizeTokens = <double, String>{
  FluentFontSize.base100: 'fontSizeBase100',
  FluentFontSize.base200: 'fontSizeBase200',
  FluentFontSize.base300: 'fontSizeBase300',
  FluentFontSize.base400: 'fontSizeBase400',
  FluentFontSize.base500: 'fontSizeBase500',
  FluentFontSize.base600: 'fontSizeBase600',
  FluentFontSize.hero700: 'fontSizeHero700',
  FluentFontSize.hero800: 'fontSizeHero800',
  FluentFontSize.hero900: 'fontSizeHero900',
  FluentFontSize.hero1000: 'fontSizeHero1000',
};

/// The global line-height ramp, keyed the same way.
final Map<double, String> _lineHeightTokens = <double, String>{
  FluentLineHeight.base100: 'lineHeightBase100',
  FluentLineHeight.base200: 'lineHeightBase200',
  FluentLineHeight.base300: 'lineHeightBase300',
  FluentLineHeight.base400: 'lineHeightBase400',
  FluentLineHeight.base500: 'lineHeightBase500',
  FluentLineHeight.base600: 'lineHeightBase600',
  FluentLineHeight.hero700: 'lineHeightHero700',
  FluentLineHeight.hero800: 'lineHeightHero800',
  FluentLineHeight.hero900: 'lineHeightHero900',
  FluentLineHeight.hero1000: 'lineHeightHero1000',
};

String _weightToken(FontWeight? weight) => switch (weight) {
  FluentFontWeight.regular => 'fontWeightRegular',
  FluentFontWeight.medium => 'fontWeightMedium',
  FluentFontWeight.semibold => 'fontWeightSemibold',
  FluentFontWeight.bold => 'fontWeightBold',
  _ => _noToken,
};

/// Splits a ramp key at its camel-case and digit boundaries: `body1Strong`
/// becomes `Body 1 Strong`, which is what the specimen column prints.
final RegExp _wordBreak = RegExp(
  r'(?<=[a-z0-9])(?=[A-Z])|(?<=[a-zA-Z])(?=[0-9])',
);

String _specimenText(String key) => key
    .split(_wordBreak)
    .map((String word) => word[0].toUpperCase() + word.substring(1))
    .join(' ');

/// `TextStyle.height` is a multiplier; the token it came from is a pixel count.
/// Rounded because 20/14*14 does not always land back on 20 exactly.
double? _lineHeightOf(TextStyle style) {
  final double? size = style.fontSize;
  final double? factor = style.height;
  return size == null || factor == null
      ? null
      : (size * factor).roundToDouble();
}

/// Relative widths of Name / Tokens / Default Values / Example, measured off
/// the live page at a 1600px viewport.
const List<int> _columnFlex = <int>[155, 176, 195, 624];

Widget _tableRow(List<Widget> cells) => Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: <Widget>[
    for (final (int i, Widget cell) in cells.indexed)
      Expanded(flex: _columnFlex[i], child: cell),
  ],
);

/// A stack of single-line values, which is how the middle two columns read.
Widget _lines(List<String> values) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: <Widget>[
    for (final String value in values)
      Text(
        value,
        style: DocsMetrics.body,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
  ],
);

Widget _rampRow(String key, TextStyle style) {
  final double? size = style.fontSize;
  final double? lineHeight = _lineHeightOf(style);
  final String family = <String>[
    "'${style.fontFamily ?? DocsMetrics.fontFamily}'",
    ...?style.fontFamilyFallback,
  ].join(', ');

  return _tableRow(<Widget>[
    _lines(<String>[key]),
    _lines(<String>[
      'fontFamilyBase',
      size == null ? _noToken : _fontSizeTokens[size] ?? _noToken,
      _weightToken(style.fontWeight),
      lineHeight == null ? _noToken : _lineHeightTokens[lineHeight] ?? _noToken,
    ]),
    _lines(<String>[
      'fontFamily: $family',
      'fontSize: ${size?.toStringAsFixed(0) ?? _noToken}px',
      'fontWeight: ${style.fontWeight?.value ?? _noToken}',
      'lineHeight: ${lineHeight?.toStringAsFixed(0) ?? _noToken}px',
    ]),
    Text(
      _specimenText(key),
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  ]);
}

Widget _callout() {
  final TextStyle line = DocsMetrics.body.copyWith(
    fontSize: 16,
    height: 28 / 16,
    fontWeight: FontWeight.w700,
    color: DocsMetrics.headingText,
  );

  return Padding(
    padding: const EdgeInsets.only(left: 40),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text.rich(
          const TextSpan(
            children: <InlineSpan>[
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: _InfoGlyph(),
              ),
              TextSpan(text: '  '),
              TextSpan(
                text:
                    'This page guides you on how to fully leverage the '
                    'tokens to create a consistent typography system.',
              ),
            ],
          ),
          style: line,
        ),
        Text.rich(
          const TextSpan(
            children: <InlineSpan>[
              TextSpan(
                text:
                    'To take full advantage of the typography system, you '
                    'should also read the ',
              ),
              // Storybook's link blue, which is the same value the sidebar
              // paints its selection in. Not interactive here: the shell owns
              // navigation and a body has no route to hand it.
              TextSpan(
                text: 'Text component documentation',
                style: TextStyle(
                  color: DocsMetrics.sidebarSelected,
                  decoration: TextDecoration.underline,
                  decorationColor: DocsMetrics.sidebarSelected,
                ),
              ),
              TextSpan(text: '.'),
            ],
          ),
          style: line,
        ),
      ],
    ),
  );
}

Widget _body(BuildContext context) {
  final List<(String, TextStyle)> ramp = _ramp(
    FluentTheme.of(context).typography,
  );
  final TextStyle header = DocsMetrics.body.copyWith(
    fontSize: 16,
    height: 20 / 16,
    fontWeight: FontWeight.w700,
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      _callout(),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: FluentTheme.of(context).colors.neutralBackground1,
          border: Border.all(color: DocsMetrics.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _tableRow(<Widget>[
              Text('Name', style: header),
              Text('Tokens', style: header),
              Text('Default Values', style: header),
              Text('Example', style: header),
            ]),
            const SizedBox(height: 26),
            for (final (int i, (String, TextStyle) entry) in ramp.indexed)
              Padding(
                padding: EdgeInsets.only(bottom: i == ramp.length - 1 ? 0 : 24),
                child: _rampRow(entry.$1, entry.$2),
              ),
          ],
        ),
      ),
    ],
  );
}

/// The ℹ️ the callout opens with, drawn rather than typed: the glyph is a
/// colour emoji, and whether one renders at all depends on a font the host
/// happens to ship. Twenty-one logical pixels, matching the reference.
class _InfoGlyph extends StatelessWidget {
  const _InfoGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 21,
      height: 21,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFFA8C0D6), Color(0xFF617D96)],
        ),
      ),
      child: const Text(
        'i',
        style: TextStyle(
          fontFamily: DocsMetrics.fontFamily,
          fontFamilyFallback: DocsMetrics.fontFamilyFallback,
          fontSize: 15,
          height: 1,
          fontWeight: FontWeight.w700,
          color: Color(0xFFFFFFFF),
        ),
      ),
    );
  }
}
