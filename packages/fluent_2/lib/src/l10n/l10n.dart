import 'package:flutter/widgets.dart';

import 'fluent_localizations.dart';
import 'fluent_localizations_en.dart';

/// The generated message catalogue, re-exported so that one import gives a
/// component both [fluentL10n] and the [FluentLocalizations] type its own
/// doc comments reference.
export 'fluent_localizations.dart';

/// The Fluent component strings in scope at [context].
///
/// Unlike `FluentLocalizations.of`, this never returns null: an application
/// that has not installed [FluentLocalizations.delegate] gets
/// [fluentLocalizationsFallback] rather than a crash. A design system is a
/// dependency, and a dependency may not make an application's accessibility
/// labels a startup requirement — it degrades to English and keeps rendering.
///
/// To get every other language, add the delegate:
///
/// ```dart
/// FluentApp(
///   localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
///     FluentLocalizations.delegate,
///   ],
///   supportedLocales: FluentLocalizations.supportedLocales,
///   home: const Home(),
/// )
/// ```
FluentLocalizations fluentL10n(BuildContext context) =>
    FluentLocalizations.of(context) ?? fluentLocalizationsFallback;

/// The English strings, used wherever no [FluentLocalizations.delegate] is in
/// scope.
///
/// Also the right argument for the handful of entry points that take strings
/// but are handed no [BuildContext] — see
/// `buildFluentCartesianChartDescription`.
final FluentLocalizations fluentLocalizationsFallback = FluentLocalizationsEn();
