import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/widgets.dart';
import 'package:storybook_flutter/storybook_flutter.dart';

/// The seven Theme tabs from `crawlers/.../out/side-menu.md`, rendered against
/// the real `fluent_2_core` design tokens.
List<Story> get themeStories => [
  Story(
    name: 'Theme/Colors',
    description:
        'The alias (semantic) color layer, resolved for the current '
        'light/dark theme and brand ramp.',
    builder: (context) => const _ColorsPage(),
  ),
  Story(
    name: 'Theme/Typography',
    description:
        'The web type ramp — the 18 Fluent 2 text styles with their '
        'font, size and line height.',
    builder: (context) => const _TypographyPage(),
  ),
  Story(
    name: 'Theme/Fonts',
    description: 'The Fluent font stacks and family tokens.',
    builder: (context) => const _FontsPage(),
  ),
  Story(
    name: 'Theme/Spacing',
    description: 'The web semantic spacing ramp (the `--spacing-*` tokens).',
    builder: (context) => const _SpacingPage(),
  ),
  Story(
    name: 'Theme/Border Radii',
    description: 'The corner radius ramp used across components.',
    builder: (context) => const _RadiiPage(),
  ),
  Story(
    name: 'Theme/Shadows',
    description: 'The elevation levels, resolved for the current brightness.',
    builder: (context) => const _ShadowsPage(),
  ),
  Story(
    name: 'Theme/Stroke Widths',
    description: 'The stroke (border) width ramp.',
    builder: (context) => const _StrokesPage(),
  ),
];

const _tokenName = FluentColorToken.values;

class _ColorsPage extends StatelessWidget {
  const _ColorsPage();

  @override
  Widget build(BuildContext context) {
    final colors = FluentTheme.of(context).colors;
    final tokens = _tokenName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Alias color tokens (${tokens.length})',
          style: FluentTheme.of(context).typography.title1,
        ),
        const SizedBox(height: 8),
        Text(
          'Swatches below are the raw resolved hexadecimal values for the '
          'current theme. Use the light/dark toggle in the bottom bar to '
          'compare palettes.',
          style: FluentTheme.of(context).typography.body1,
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final token in tokens)
              _ColorSwatch(
                swatchLabel: _labelForColorToken(token.name),
                color: colors.resolve(token),
              ),
          ],
        ),
      ],
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.swatchLabel, required this.color});

  final String swatchLabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final foreground = color.computeLuminance() > 0.5
        ? const Color(0xFF212121)
        : const Color(0xFFFFFFFF);
    final textStyle = FluentTheme.of(
      context,
    ).typography.caption1.copyWith(color: foreground);
    return Container(
      width: 128,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.all(FluentRadius.medium),
        border: Border.all(
          color: FluentTheme.of(context).colors.neutralStroke1,
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(swatchLabel, style: textStyle),
          const SizedBox(height: 4),
          Text(_hex(color), style: textStyle),
        ],
      ),
    );
  }

  static String _hex(Color color) {
    final value = (color.toARGB32() & 0xFFFFFF)
        .toRadixString(16)
        .padLeft(6, '0');
    return '#$value';
  }
}

class _TypographyPage extends StatelessWidget {
  const _TypographyPage();

  @override
  Widget build(BuildContext context) {
    final type = FluentTheme.of(context).typography;
    final styles = <(String, TextStyle)>[
      ('Caption 2', type.caption2),
      ('Caption 2 Strong', type.caption2Strong),
      ('Caption 1', type.caption1),
      ('Caption 1 Strong', type.caption1Strong),
      ('Caption 1 Stronger', type.caption1Stronger),
      ('Body 1', type.body1),
      ('Body 1 Strong', type.body1Strong),
      ('Body 1 Stronger', type.body1Stronger),
      ('Body 2', type.body2),
      ('Body 2 Strong', type.body2Strong),
      ('Subtitle 2', type.subtitle2),
      ('Subtitle 2 Stronger', type.subtitle2Stronger),
      ('Subtitle 1', type.subtitle1),
      ('Title 3', type.title3),
      ('Title 2', type.title2),
      ('Title 1', type.title1),
      ('Large Title', type.largeTitle),
      ('Display', type.display),
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (name, style) in styles)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$name — ${style.fontSize}px', style: type.caption1),
                const SizedBox(height: 4),
                Text('Fluent 2', style: style),
                const SizedBox(height: 16),
              ],
            ),
        ],
      ),
    );
  }
}

class _FontsPage extends StatelessWidget {
  const _FontsPage();

  @override
  Widget build(BuildContext context) {
    final type = FluentTheme.of(context).typography;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Font stacks', style: type.title1),
        const SizedBox(height: 8),
        Text('Base: ${FluentFontFamily.base}', style: type.body1),
        const SizedBox(height: 4),
        Text('Monospace: ${FluentFontFamily.monospace}', style: type.body1),
        const SizedBox(height: 4),
        Text('Numeric: ${FluentFontFamily.numeric}', style: type.body1),
        const SizedBox(height: 24),
        Text(
          'Body (base)',
          style: type.body1.copyWith(fontFamily: FluentFontFamily.base),
        ),
        const SizedBox(height: 8),
        Text(
          'Monospace',
          style: type.body1.copyWith(fontFamily: FluentFontFamily.monospace),
        ),
      ],
    );
  }
}

class _SpacingPage extends StatelessWidget {
  const _SpacingPage();

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final bars = <(String, double)>[
      ('none', FluentSpacing.none),
      ('xxs', FluentSpacing.xxs),
      ('xs', FluentSpacing.xs),
      ('sNudge', FluentSpacing.sNudge),
      ('s', FluentSpacing.s),
      ('mNudge', FluentSpacing.mNudge),
      ('m', FluentSpacing.m),
      ('l', FluentSpacing.l),
      ('xl', FluentSpacing.xl),
      ('xxl', FluentSpacing.xxl),
      ('xxxl', FluentSpacing.xxxl),
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (name, value) in bars)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(name, style: theme.typography.body1),
                  ),
                  Container(
                    width: value < 2 ? 4 : value,
                    height: 20,
                    color: theme.colors.brandBackground,
                  ),
                  const SizedBox(width: 8),
                  Text('$value', style: theme.typography.body2),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RadiiPage extends StatelessWidget {
  const _RadiiPage();

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final radii = <(String, Radius)>[
      ('none', FluentRadius.none),
      ('small (2)', FluentRadius.small),
      ('medium (4)', FluentRadius.medium),
      ('large (6)', FluentRadius.large),
      ('xLarge (8)', FluentRadius.xLarge),
      ('xxLarge (12)', FluentRadius.xxLarge),
      ('xxxLarge (16)', FluentRadius.xxxLarge),
      ('xxxxLarge (24)', FluentRadius.xxxxLarge),
      ('circular', FluentRadius.circular),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        for (final (name, radius) in radii)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: theme.colors.brandBackground,
                  borderRadius: BorderRadius.all(radius),
                ),
              ),
              const SizedBox(height: 8),
              Text(name, style: theme.typography.caption1),
            ],
          ),
      ],
    );
  }
}

class _ShadowsPage extends StatelessWidget {
  const _ShadowsPage();

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        for (final level in FluentElevation.values)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 96,
                decoration: BoxDecoration(
                  color: theme.colors.neutralBackground2,
                  borderRadius: BorderRadius.all(FluentRadius.large),
                  boxShadow: theme.shadow(level),
                ),
              ),
              const SizedBox(height: 8),
              Text(level.name, style: theme.typography.caption1),
            ],
          ),
      ],
    );
  }
}

class _StrokesPage extends StatelessWidget {
  const _StrokesPage();

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final strokes = <(String, double)>[
      ('none', FluentStroke.none),
      ('hairline', FluentStroke.hairline),
      ('thin', FluentStroke.thin),
      ('width15', FluentStroke.width15),
      ('thick', FluentStroke.thick),
      ('thicker', FluentStroke.thicker),
      ('thickest', FluentStroke.thickest),
      ('width60', FluentStroke.width60),
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (name, width) in strokes)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(name, style: theme.typography.body1),
                  ),
                  Expanded(
                    child: Container(
                      height: width < 0.75 ? 1 : width,
                      color: width == 0
                          ? Colors.transparent
                          : theme.colors.neutralStroke1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 48,
                    child: Text('$width', style: theme.typography.body2),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

String _labelForColorToken(String name) {
  final buffer = StringBuffer();
  for (final part in _splitCamel(name)) {
    buffer
      ..write(part[0].toUpperCase())
      ..write(part.substring(1))
      ..write(' ');
  }
  return buffer.toString().trim();
}

List<String> _splitCamel(String input) {
  final parts = <String>[];
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final char = String.fromCharCode(rune);
    if (char.codeUnitAt(0) >= 65 &&
        char.codeUnitAt(0) <= 90 &&
        buffer.isNotEmpty) {
      parts.add(buffer.toString());
      buffer.clear();
    }
    buffer.write(char);
  }
  if (buffer.isNotEmpty) parts.add(buffer.toString());
  return parts;
}
