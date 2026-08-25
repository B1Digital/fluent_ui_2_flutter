import 'package:fluent_2/fluent_2.dart';

/// The themes offered by the docs toolbar's Theme dropdown.
///
/// `fluent_2_core` ships no named theme objects — [FluentThemeData] has
/// factories and [FluentBrandRamp] has ramps, and a "variant" is a pairing of
/// the two. This enum is that pairing, and it exists in the example rather than
/// the library because which combinations are worth showing is an editorial
/// question, not a design-system one.
enum ThemeVariant {
  /// The default web theme.
  webLight('Web Light'),

  /// The default web theme, dark.
  webDark('Web Dark'),

  /// Teams' brand ramp on the light neutral table.
  teamsLight('Teams Light'),

  /// Teams' dark table, which overrides 20 neutrals beyond a ramp swap.
  teamsDark('Teams Dark'),

  /// The 2021 Teams refresh ramp.
  teamsV21Light('Teams V21 Light'),

  /// The 2021 Teams refresh ramp, dark.
  teamsV21Dark('Teams V21 Dark'),

  /// Office orange.
  officeLight('Office Light'),

  /// Office orange, dark.
  officeDark('Office Dark'),

  /// Windows high contrast. Collapses 205 of the 228 alias tokens onto eight
  /// system colours and ignores brand ramps entirely.
  highContrast('High Contrast');

  const ThemeVariant(this.label);

  /// The name the dropdown shows.
  final String label;

  /// The theme this variant resolves to.
  ///
  /// Not cached: [FluentThemeData] is immutable and its factories are cheap
  /// table lookups, and holding nine live themes to avoid rebuilding one is the
  /// wrong trade.
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
    ThemeVariant.officeLight => FluentThemeData.light(
      brand: FluentBrandRamp.office,
    ),
    ThemeVariant.officeDark => FluentThemeData.dark(
      brand: FluentBrandRamp.office,
    ),
    ThemeVariant.highContrast => FluentThemeData.highContrast(),
  };
}
