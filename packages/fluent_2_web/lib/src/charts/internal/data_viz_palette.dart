import 'package:flutter/widgets.dart';

/// The 47 data-visualisation tokens a chart can name.
///
/// Ports the `DataVizPalette` object (`colors.ts:4-52`) — forty `qualitative.*`
/// entries followed by seven `semantic.*` entries, in that order. The ordinals
/// are load-bearing: `FluentDataVizPalette.tokenFromUpstreamName` indexes
/// [FluentDataVizToken.values] with the qualitative number.
enum FluentDataVizToken {
  /// `'qualitative.1'` — cornflower tint 10 (`colors.ts:63`).
  color1,

  /// `'qualitative.2'` — hot pink primary (`colors.ts:64`).
  color2,

  /// `'qualitative.3'` — teal tint 20 (`colors.ts:65`).
  color3,

  /// `'qualitative.4'` — orchid tint 10 (`colors.ts:66`).
  color4,

  /// `'qualitative.5'` — light green primary (`colors.ts:67`).
  color5,

  /// `'qualitative.6'` — light blue primary (`colors.ts:68`).
  color6,

  /// `'qualitative.7'` — pumpkin primary (`colors.ts:69`).
  color7,

  /// `'qualitative.8'` — lime shade 20 (`colors.ts:70`).
  color8,

  /// `'qualitative.9'` — lilac primary (`colors.ts:71`).
  color9,

  /// `'qualitative.10'` — gold shade 10 (`colors.ts:72`).
  color10,

  /// `'qualitative.11'` (`colors.ts:73`).
  color11,

  /// `'qualitative.12'` (`colors.ts:74`).
  color12,

  /// `'qualitative.13'` (`colors.ts:75`).
  color13,

  /// `'qualitative.14'` (`colors.ts:76`).
  color14,

  /// `'qualitative.15'` (`colors.ts:77`).
  color15,

  /// `'qualitative.16'` (`colors.ts:78`).
  color16,

  /// `'qualitative.17'` (`colors.ts:79`).
  color17,

  /// `'qualitative.18'` (`colors.ts:80`).
  color18,

  /// `'qualitative.19'` (`colors.ts:81`).
  color19,

  /// `'qualitative.20'` (`colors.ts:82`).
  color20,

  /// `'qualitative.21'` (`colors.ts:83`).
  color21,

  /// `'qualitative.22'` (`colors.ts:84`).
  color22,

  /// `'qualitative.23'` (`colors.ts:85`).
  color23,

  /// `'qualitative.24'` (`colors.ts:86`).
  color24,

  /// `'qualitative.25'` (`colors.ts:87`).
  color25,

  /// `'qualitative.26'` (`colors.ts:88`).
  color26,

  /// `'qualitative.27'` (`colors.ts:89`).
  color27,

  /// `'qualitative.28'` (`colors.ts:90`).
  color28,

  /// `'qualitative.29'` (`colors.ts:91`).
  color29,

  /// `'qualitative.30'` (`colors.ts:92`).
  color30,

  /// `'qualitative.31'` (`colors.ts:93`).
  color31,

  /// `'qualitative.32'` (`colors.ts:94`).
  color32,

  /// `'qualitative.33'` (`colors.ts:95`).
  color33,

  /// `'qualitative.34'` (`colors.ts:96`).
  color34,

  /// `'qualitative.35'` (`colors.ts:97`).
  color35,

  /// `'qualitative.36'` (`colors.ts:98`).
  color36,

  /// `'qualitative.37'` (`colors.ts:99`).
  color37,

  /// `'qualitative.38'` (`colors.ts:100`).
  color38,

  /// `'qualitative.39'` (`colors.ts:101`).
  color39,

  /// `'qualitative.40'` (`colors.ts:102`).
  color40,

  /// `'semantic.info'` (`colors.ts:106`).
  info,

  /// `'semantic.disabled'` (`colors.ts:107`).
  disabled,

  /// `'semantic.highError'` (`colors.ts:108`).
  highError,

  /// `'semantic.error'` (`colors.ts:109`).
  error,

  /// `'semantic.warning'` (`colors.ts:110`).
  warning,

  /// `'semantic.success'` (`colors.ts:111`).
  success,

  /// `'semantic.highSuccess'` (`colors.ts:112`).
  highSuccess,
}

/// The chart data-visualisation palette.
///
/// A verbatim transcription of `colors.ts:62-113`. The hexadecimals are written
/// out rather than looked up in `fluent_2_core`'s shared ramps for three
/// reasons: the frozen `next` and `resolve` signatures take no theme, so there
/// is nothing to look a ramp up on; two of the 47 entries have no
/// `fluent_2_core` equivalent at all (spec §5.8); and upstream itself writes the
/// literal with the ramp stop named in a trailing comment, which is what a
/// reviewer diffs against.
abstract final class FluentDataVizPalette {
  /// The length of the qualitative cycle. `colors.ts:120` derives it from the
  /// forty ramps at `:62-103`.
  static const int qualitativeCount = 40;

  /// The forty qualitative ramps, in upstream order.
  ///
  /// Index 0 is the light value, index 1 the dark value where one exists. The
  /// trailing comment on each row is upstream's own annotation of which shared
  /// ramp stop the literal equals.
  static const List<List<Color>> _qualitative = <List<Color>>[
    <Color>[Color(0xFF637CEF)], // :63  cornflower.tint10
    <Color>[Color(0xFFE3008C)], // :64  hotPink.primary
    <Color>[Color(0xFF2AA0A4)], // :65  teal.tint20
    <Color>[Color(0xFF9373C0)], // :66  orchid.tint10
    <Color>[Color(0xFF13A10E)], // :67  lightGreen.primary
    <Color>[Color(0xFF3A96DD)], // :68  lightBlue.primary
    <Color>[Color(0xFFCA5010)], // :69  pumpkin.primary
    <Color>[Color(0xFF57811B)], // :70  lime.shade20
    <Color>[Color(0xFFB146C2)], // :71  lilac.primary
    <Color>[Color(0xFFAE8C00)], // :72  gold.shade10
    <Color>[Color(0xFF3C51B4), Color(0xFF93A4F4)], // :73  cornflower 20/30
    <Color>[Color(0xFFAD006A), Color(0xFFEE5FB7)], // :74  hotPink 20/30
    <Color>[Color(0xFF026467), Color(0xFF4CB4B7)], // :75  teal 20/30
    <Color>[Color(0xFF674C8C), Color(0xFFA083C9)], // :76  orchid 20/20
    <Color>[Color(0xFF0E7A0B), Color(0xFF27AC22)], // :77  lightGreen 20/10
    <Color>[Color(0xFF2C72A8), Color(0xFF4FA1E1)], // :78  lightBlue 20/10
    <Color>[Color(0xFF9A3D0C), Color(0xFFD77440)], // :79  pumpkin 20/20
    <Color>[Color(0xFF405F14), Color(0xFF73AA24)], // :80  lime 30/primary
    <Color>[Color(0xFF863593), Color(0xFFC36BD1)], // :81  lilac 20/20
    // :82 — the light value is '#6d5700'. fluent_2_core's gold.shade30 is
    // 0xFF6C5700, one unit of red away, so this entry cannot be aliased to the
    // generated token and is written out. Spec §5.8.
    <Color>[Color(0xFF6D5700), Color(0xFFD0B232)],
    <Color>[Color(0xFF4F6BED)], // :83  cornflower.primary
    <Color>[Color(0xFFEA38A6)], // :84  hotPink.tint20
    <Color>[Color(0xFF038387)], // :85  teal.primary
    <Color>[Color(0xFF8764B8)], // :86  orchid.primary
    <Color>[Color(0xFF11910D)], // :87  lightGreen.shade10
    <Color>[Color(0xFF3487C7)], // :88  lightBlue.shade10
    <Color>[Color(0xFFD06228)], // :89  pumpkin.tint10
    <Color>[Color(0xFF689920)], // :90  lime.shade10
    <Color>[Color(0xFFBA58C9)], // :91  lilac.tint10
    <Color>[Color(0xFF937700), Color(0xFFC19C00)], // :92  gold 20/primary
    <Color>[Color(0xFF2C3C85), Color(0xFFC8D1FA)], // :93  cornflower 30/40
    <Color>[Color(0xFF7F004E), Color(0xFFF7ADDA)], // :94  hotPink 30/40
    <Color>[Color(0xFF02494C), Color(0xFF9BD9DB)], // :95  teal 30/40
    <Color>[Color(0xFF4C3867), Color(0xFFB29AD4)], // :96  orchid 30/30
    <Color>[Color(0xFF0B5A08), Color(0xFFA7E3A5)], // :97  lightGreen 30/40
    <Color>[Color(0xFF20547C), Color(0xFF83BDEB)], // :98  lightBlue 30/30
    <Color>[Color(0xFF712D09), Color(0xFFDF8E64)], // :99  pumpkin 30/30
    <Color>[Color(0xFF23330B), Color(0xFFA4CC6C)], // :100 lime 40/30
    <Color>[Color(0xFF63276D), Color(0xFFCF87DA)], // :101 lilac 30/30
    <Color>[Color(0xFF3A2F00), Color(0xFFDAC157)], // :102 gold 40/30
  ];

  /// Picks the theme-appropriate entry from one ramp.
  ///
  /// Ports `getThemeSpecificColor` (`colors.ts:123-132`): index 1 for a dark
  /// theme, falling back to index 0 when the ramp has only one entry.
  static Color _themeSpecific(List<Color> ramp, {required bool isDark}) {
    // colors.ts:126 `Number(isDarkTheme)` — false is 0, true is 1.
    final index = isDark ? 1 : 0;
    return index < ramp.length ? ramp[index] : ramp[0];
  }

  /// The qualitative colour at [index], offset by [offset], cycling at
  /// [qualitativeCount].
  ///
  /// Ports `getNextColor` (`colors.ts:134-137`).
  ///
  /// [isDark] defaults to false and every imperatively mounted chart leaves it
  /// so, exactly as upstream does — only the two declarative adapters pass a
  /// real value, through `fluentChartIsDarkTheme` (spec §5.8).
  ///
  /// `// parity:` a negative `index + offset` throws upstream, because
  /// `QUALITATIVE_COLORS[-1]` is `undefined` and `getThemeSpecificColor` then
  /// reads `.length` off it. Dart's `%` would wrap silently instead, so the
  /// assert below keeps the failure visible in debug builds.
  static Color next(int index, {int offset = 0, bool isDark = false}) {
    assert(
      index + offset >= 0,
      'colors.ts:135 indexes an array directly, so a negative index throws '
      'upstream rather than wrapping.',
    );
    return _themeSpecific(
      _qualitative[(index + offset) % qualitativeCount],
      isDark: isDark,
    );
  }
}
