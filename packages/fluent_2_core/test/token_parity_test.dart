/// Every alias colour in this package, checked against Fluent UI React v9.
///
/// React is the source of truth for the colour layer, and nothing pinned that
/// until this file existed. It was written after a one-off diff found four
/// transcription slips that had shipped: the **dark** warning ramp had values
/// in the wrong slots — dark `WarningForeground3` held React's *light*
/// `WarningBorder1` value — and `statusSuccessForegroundInverted` was wrong in
/// both brightnesses. Nothing failed, because nothing was comparing.
///
/// The fixture is a machine-generated snapshot of the real React themes, not a
/// hand-maintained table; regenerate it with `node tool/dump_react_tokens.js`.
///
/// Three things are asserted, and the second is the one that earns this file:
///
/// 1. Every token with a React counterpart matches it.
/// 2. The **deliberate** divergences are pinned exactly. A divergence that
///    disappears fails just as loudly as one that appears — otherwise someone
///    diffing against React "fixes" the high contrast foregrounds back to
///    React's values and silently reintroduces black-on-black text.
/// 3. The Dart-only tokens are pinned, so adding one is a conscious act.
library;

import 'dart:convert';
import 'dart:io';

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tokens where this package deliberately differs from React, and why.
///
/// Keyed `<variant>.<reactTokenName>`. Every entry is a decision someone has
/// already made and written down; the value is the reason, printed on failure
/// so the next person does not have to re-derive it.
const Map<String, String> _deliberate = <String, String>{
  // React pairs `colorNeutralForegroundInverted: #000000` with
  // `colorNeutralBackgroundInverted: #000000` in high contrast — black on
  // black. Every inverted surface (tooltip, popover, teaching popover) renders
  // outlined but empty. High contrast has no notion of an inverted surface;
  // everything collapses onto the canvas pair, so the readable foreground is
  // `canvasText`. See `tokens/theme_variants.dart` for the full note.
  'highContrast.colorNeutralForegroundInverted': 'React is black-on-black',
  'highContrast.colorNeutralForegroundInvertedHover': 'React is black-on-black',
  'highContrast.colorNeutralForegroundInvertedPressed':
      'React is black-on-black',
  'highContrast.colorNeutralForegroundInvertedSelected':
      'React is black-on-black',
};

/// Tokens this package defines that React's theme has no counterpart for.
///
/// Not omissions. React sources these at component level from
/// `statusSharedColors` rather than promoting them to theme aliases; this
/// package needs them as real tokens because `FluentPresenceBadge` and the
/// severe status ramp are themeable here.
const Set<String> _dartOnly = <String>{
  'statusSevereBackground1',
  'statusSevereBackground2',
  'statusSevereBackground3',
  'statusSevereForeground1',
  'statusSevereForeground2',
  'statusSevereForeground3',
  'statusSevereForegroundInverted',
  'statusSevereBorder1',
  'statusSevereBorder2',
  'statusAvailableForeground3',
  'statusAwayBackground3',
  'statusOofForeground3',
};

void main() {
  final file = File('test/fixtures/react_tokens.json');
  final fixture = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final source = fixture['source'] as String;
  final themes = fixture['themes'] as Map<String, dynamic>;

  /// The React token name for a Dart enum member: `colorNeutralBackground1`.
  String reactName(String dart) =>
      'color${dart[0].toUpperCase()}${dart.substring(1)}';

  /// `#rrggbbaa`, the form the fixture is normalised to.
  String hex(Color c) {
    String b(double v) => (v * 255).round().toRadixString(16).padLeft(2, '0');
    return '#${b(c.r)}${b(c.g)}${b(c.b)}${b(c.a)}';
  }

  final variants = <String, FluentColors>{
    'webLight': const FluentColors(),
    'webDark': const FluentColors(brightness: Brightness.dark),
    'teamsDark': const FluentTeamsDarkColors(),
    'highContrast': const FluentHighContrastColors(),
  };

  test('the fixture covers every variant this package ships', () {
    expect(
      themes.keys.toSet(),
      variants.keys.toSet(),
      reason: 'regenerate with `node tool/dump_react_tokens.js`',
    );
  });

  for (final variant in variants.keys) {
    final dartColors = variants[variant]!;
    final react = (themes[variant] as Map<String, dynamic>)
        .cast<String, String>();

    group('$variant vs $source', () {
      test('every token with a React counterpart matches it', () {
        final drifted = <String>[];
        for (final token in FluentColorToken.values) {
          final key = reactName(token.name);
          final expected = react[key];
          if (expected == null) continue; // covered by the Dart-only test
          if (_deliberate.containsKey('$variant.$key')) continue;
          final actual = hex(dartColors.resolve(token));
          if (actual != expected) drifted.add('  $key: $actual != $expected');
        }
        expect(
          drifted,
          isEmpty,
          reason:
              'React is the source of truth for the colour layer. If upstream '
              'moved, regenerate the fixture with `node tool/dump_react_tokens.js` '
              'and review the diff; otherwise this is drift in '
              'tokens/alias_colors.dart:\n${drifted.join('\n')}',
        );
      });

      test('the deliberate divergences are exactly the pinned ones', () {
        // Both directions matter. An unlisted divergence is drift; a listed one
        // that has stopped diverging means someone matched React and undid a
        // decision — for the high contrast foregrounds that reintroduces black
        // text on a black surface, which no other test in this package sees.
        for (final entry in _deliberate.entries) {
          final parts = entry.key.split('.');
          if (parts.first != variant) continue;
          final token = FluentColorToken.values.firstWhere(
            (t) => reactName(t.name) == parts[1],
            orElse: () => throw StateError('unknown token ${parts[1]}'),
          );
          expect(
            hex(dartColors.resolve(token)),
            isNot(react[parts[1]]),
            reason:
                '${parts[1]} no longer diverges from React. That divergence was '
                'deliberate — ${entry.value}. Restore it, or delete the entry '
                'from _deliberate and say why in the changelog.',
          );
        }
      });
    });
  }

  test('the Dart-only tokens are exactly the pinned ones', () {
    final react = (themes['webLight'] as Map<String, dynamic>).keys.toSet();
    final only = FluentColorToken.values
        .map((t) => t.name)
        .where((n) => !react.contains(reactName(n)))
        .toSet();
    expect(
      only,
      _dartOnly,
      reason:
          'a token with no React counterpart is either a deliberate extension '
          '(add it to _dartOnly with a reason) or a misspelling that would '
          'otherwise never be compared against anything',
    );
  });
}
