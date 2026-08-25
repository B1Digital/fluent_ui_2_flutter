import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';
import '../shell/docs_metrics.dart';

/// The Colors theme page.
///
/// Upstream renders one filterable table: a row per alias token, and a filled
/// block of the resolved colour per theme with its hex printed on it. This is
/// the same table, computed from our own tokens — `FluentColorToken` has all
/// 228 and `FluentColors.resolve` answers for any variant, so the page stays
/// correct by construction rather than by transcription.
const DocsPage themeColorsPage = DocsPage(
  id: 'theme-colors',
  title: 'Colors',
  description: '',
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

/// Flex weights measured off the reference capture: a 336px token column, then
/// five 150px colour columns separated by a 14px gutter. The colour blocks have
/// hard edges in the PNG, so the 150 and the 14 are exact rather than sampled.
const int _nameFlex = 336;
const int _cellFlex = 150;
const double _gutter = 14;
const double _rowHeight = 56;

/// Left inset every column shares. The header labels, the token names and the
/// hex printed on each block all start 16px into their column, which is also
/// what lines the token names up with the filter button's icon above them.
const double _cellInset = 16;

/// The card the whole page sits on. Storybook's chrome is light-only, so this
/// is the light theme's surface rather than the selected variant's.
const Color _surface = Color(0xFFFFFFFF);

/// React's name for a token: ours with a `color` prefix.
String _reactName(FluentColorToken token) =>
    'color${token.name[0].toUpperCase()}${token.name.substring(1)}';

/// `#rrggbb`, or `#rrggbbaa` when the token carries alpha — several of the
/// `*Alpha` and shadow tokens do, and printing them opaque would be a lie.
String _hex(Color color) {
  final int argb = color.toARGB32();
  final String rgb = (argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
  final int alpha = argb >>> 24;
  if (alpha == 0xFF) {
    return '#$rgb';
  }
  return '#$rgb${alpha.toRadixString(16).padLeft(2, '0')}';
}

/// The token's family, taken from the leading lowercase run of its name:
/// `neutralForeground1` is Neutral, `statusDangerBorder1` is Status.
String _family(FluentColorToken token) {
  final String name = token.name;
  int end = 0;
  while (end < name.length) {
    final int unit = name.codeUnitAt(end);
    if (unit < 0x61 || unit > 0x7A) {
      break;
    }
    end++;
  }
  return '${name[0].toUpperCase()}${name.substring(1, end)}';
}

/// Every family present, alphabetically. Derived rather than listed so the
/// menu can never offer a family with no rows behind it.
final List<String> _families =
    FluentColorToken.values.map(_family).toSet().toList()..sort();

Widget _body(BuildContext context) => const _ColorTable();

class _ColorTable extends StatefulWidget {
  const _ColorTable();

  @override
  State<_ColorTable> createState() => _ColorTableState();
}

class _ColorTableState extends State<_ColorTable> {
  String _query = '';
  String? _familyFilter;

  bool _matches(FluentColorToken token) {
    if (_familyFilter != null && _family(token) != _familyFilter) {
      return false;
    }
    if (_query.isEmpty) {
      return true;
    }
    if (_reactName(token).toLowerCase().contains(_query)) {
      return true;
    }
    for (final (String _, FluentColors colors) in _columns) {
      if (_hex(colors.resolve(token)).contains(_query)) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: DocsMetrics.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              FluentMenu(
                items: <FluentMenuItem>[
                  FluentMenuItem(
                    label: const Text('All tokens'),
                    checked: _familyFilter == null,
                    onPressed: () => setState(() => _familyFilter = null),
                  ),
                  for (final String family in _families)
                    FluentMenuItem(
                      label: Text(family),
                      checked: _familyFilter == family,
                      onPressed: () => setState(() => _familyFilter = family),
                    ),
                ],
                builder: (BuildContext context, VoidCallback toggle) =>
                    FluentButton(
                      onPressed: toggle,
                      appearance: FluentButtonAppearance.transparent,
                      icon: fluentMenuChevron,
                      iconPosition: FluentButtonIconPosition.after,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(FluentIcons.filter_20_regular, size: 16),
                          const SizedBox(width: 6),
                          Text(_familyFilter ?? 'Filter'),
                        ],
                      ),
                    ),
              ),
              const SizedBox(width: 12),
              // A plain input, not a `FluentSearchBox`: the reference field is
              // 40px tall, carries no magnifier, and runs the full width of the
              // card — where a search box would draw the glyph and cap itself
              // at its 468px maximum.
              Expanded(
                child: FluentInput(
                  size: FluentInputSize.large,
                  placeholder: const Text('Search for tokens by name or color'),
                  onChanged: (String value) =>
                      setState(() => _query = value.trim().toLowerCase()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _HeaderRow(),
          for (final FluentColorToken token in FluentColorToken.values)
            if (_matches(token)) _TokenRow(token: token),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final TextStyle style = DocsMetrics.body.copyWith(
      fontSize: 16,
      height: 22 / 16,
      fontWeight: FontWeight.w600,
      color: DocsMetrics.headingText,
    );
    return DefaultTextStyle(
      style: style,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: _nameFlex,
              child: const Padding(
                padding: EdgeInsets.only(left: _cellInset),
                child: Text('Design Token'),
              ),
            ),
            for (final (String label, FluentColors _) in _columns) ...<Widget>[
              const SizedBox(width: _gutter),
              Expanded(
                flex: _cellFlex,
                child: Padding(
                  padding: const EdgeInsets.only(left: _cellInset),
                  child: Text(label),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TokenRow extends StatelessWidget {
  const _TokenRow({required this.token});

  final FluentColorToken token;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          flex: _nameFlex,
          child: SizedBox(
            height: _rowHeight,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: _cellInset),
                child: Text(
                  _reactName(token),
                  overflow: TextOverflow.ellipsis,
                  style: DocsMetrics.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
        for (final (String _, FluentColors colors) in _columns) ...<Widget>[
          const SizedBox(width: _gutter),
          Expanded(
            flex: _cellFlex,
            child: _Cell(color: colors.resolve(token)),
          ),
        ],
      ],
    );
  }
}

/// One filled block. Rows carry no vertical padding, so two blocks of the same
/// value in adjacent rows read as a single continuous band — which is the whole
/// point of the layout upstream chose.
class _Cell extends StatelessWidget {
  const _Cell({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    // The block is painted over the card, so an alpha token's readable
    // foreground follows the composite rather than the raw colour.
    final double luminance = Color.alphaBlend(
      color,
      _surface,
    ).computeLuminance();
    return Container(
      height: _rowHeight,
      color: color,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: _cellInset),
      child: Text(
        _hex(color),
        overflow: TextOverflow.ellipsis,
        style: DocsMetrics.body.copyWith(
          color: luminance > 0.179
              ? DocsMetrics.bodyText
              : const Color(0xFFFFFFFF),
        ),
      ),
    );
  }
}
