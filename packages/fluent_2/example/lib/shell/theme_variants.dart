import 'package:fluent_2/fluent_2.dart';

/// The themes offered by the toolbar's Theme menu and the docs toolbar's
/// dropdown.
///
/// Exactly the Fluent addon's seven, in its order and under its labels
/// (`react-storybook-addon/src/theme.ts`; live menu `theme.popover0`). The
/// toolbar menu appends " (Default)" to [webLight] itself; the in-page dropdown
/// shows the plain label, as upstream's does.
///
/// `fluent_2_core` ships no named theme objects — [FluentThemeData] has
/// factories and [FluentBrandRamp] has ramps, and a "variant" is a pairing of
/// the two. This enum is that pairing, and it exists in the example rather than
/// the library because which combinations are worth showing is an editorial
/// question, not a design-system one.
enum ThemeVariant {
  /// `web-light`, the default.
  webLight('Web Light'),

  /// `web-dark`.
  webDark('Web Dark'),

  /// `teams-light`: Teams' brand ramp on the light neutral table.
  teamsLight('Teams Light'),

  /// `teams-dark`: Teams' dark table, which overrides 20 neutrals beyond a
  /// ramp swap.
  teamsDark('Teams Dark'),

  /// `teams-light-v21`: the 2021 Teams refresh ramp.
  teamsV21Light('Teams Light V2.1'),

  /// `teams-dark-v21`: the 2021 Teams refresh ramp, dark.
  teamsV21Dark('Teams Dark V2.1'),

  /// `teams-high-contrast`. Collapses 205 of the 228 alias tokens onto eight
  /// system colours and ignores brand ramps entirely.
  highContrast('Teams High Contrast');

  const ThemeVariant(this.label);

  /// The name the menu and the dropdown show.
  final String label;

  /// The theme this variant resolves to.
  ///
  /// Not cached: [FluentThemeData] is immutable and its factories are cheap
  /// table lookups, and holding seven live themes to avoid rebuilding one is
  /// the wrong trade.
  FluentThemeData get data => switch (this) {
    ThemeVariant.webLight => FluentThemeData.light(),
    ThemeVariant.webDark => FluentThemeData.dark(),
    ThemeVariant.teamsLight => FluentThemeData.light(
      brand: FluentBrandRamp.teams,
    ),
    ThemeVariant.teamsDark => FluentThemeData.teamsDark(),
    ThemeVariant.teamsV21Light => FluentThemeData.light(
      brand: FluentBrandRamp.teamsV21,
    ),
    ThemeVariant.teamsV21Dark => FluentThemeData.teamsDark(
      brand: FluentBrandRamp.teamsV21,
    ),
    ThemeVariant.highContrast => FluentThemeData.highContrast(),
  };
}
