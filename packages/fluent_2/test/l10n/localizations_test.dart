import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every getter and every method on the catalogue, exercised through one
/// function so that a locale can be checked wholesale.
///
/// A message that came back empty is the failure this file exists to catch: a
/// dropped ARB key produces a class that still compiles, still resolves, and
/// announces nothing at all to a screen reader.
List<String> _everyMessage(FluentLocalizations l) => <String>[
  l.close,
  l.dismiss,
  l.clear,
  l.open,
  l.remove,
  l.more,
  l.overflowMore,
  l.selectAllRows,
  l.selectRow,
  l.sort,
  l.sortedAscending,
  l.sortedDescending,
  l.previousSlide,
  l.nextSlide,
  l.startSlideShow,
  l.pauseSlideShow,
  l.slideOf(1, 4),
  l.stepOf(1, 4),
  l.ratingValueOf('3', '5'),
  l.openCalendar,
  l.invalidDateFormat,
  l.dateOutOfRange,
  l.fieldRequired,
  l.goToToday,
  l.previousMonth,
  l.nextMonth,
  l.previousYear,
  l.nextYear,
  l.previousYearRange,
  l.nextYearRange,
  l.monthPickerHeader('March 2026'),
  l.yearPickerHeader('2026'),
  l.selectedDate('March 10, 2026'),
  l.todaysDate('March 10, 2026'),
  l.weekNumber('11'),
  l.chartNoData,
  l.chartNoDataAvailable,
  l.chartFallbackTitle,
  l.chartAxisDescription('X', 'categories'),
  l.chartAxisX,
  l.chartAxisY,
  l.chartAxisSecondaryY,
  l.chartAxisCategories,
  l.chartAxisTime,
  l.chartAxisValues,
  l.chartLineLegendFallback,
  l.funnelChartDescription(3),
  l.donutChartDescription(4),
  l.gaugeChartDescription(2),
  l.gaugeCurrentValue('50'),
  l.gaugeCurrentValueIs('50'),
  l.gaugeMinValue('0'),
  l.gaugeMaxValue('100'),
  l.gaugeUnknownSegment,
  l.ganttChartDescription(5),
  l.heatMapChartDescription(9),
  l.polarChartDescription(2),
  l.sparklineDescription('Revenue'),
  l.sankeyChartDescription(4, 3),
  l.sankeyLinkFrom('Alpha'),
  l.sankeyNodeDescription('Alpha', '12'),
  l.sankeyLinkDescription('Alpha', 'Beta', '12'),
  l.verticalBarChartDescription(6),
  l.verticalBarChartWithLineDescription(6),
  l.groupedVerticalBarChartDescription(3),
  l.groupedVerticalBarChartWithLinesDescription(3, 2),
  l.verticalStackedBarChartDescription(3),
  l.verticalStackedBarChartWithLinesDescription(3, 2),
  l.presenceAvailable,
  l.presenceAway,
  l.presenceBusy,
  l.presenceDoNotDisturb,
  l.presenceBlocked,
  l.presenceOffline,
  l.presenceOutOfOffice,
  l.presenceUnknown,
  l.presenceOutOfOfficeStatus('Busy'),
];

/// Reads the catalogue that a subtree scoped to [locale] resolves to.
Future<FluentLocalizations> _resolve(
  WidgetTester tester,
  Locale locale, {
  bool withDelegate = true,
}) async {
  late FluentLocalizations resolved;
  await tester.pumpWidget(
    FluentApp(
      locale: locale,
      localizationsDelegates: withDelegate
          ? const <LocalizationsDelegate<dynamic>>[FluentLocalizations.delegate]
          : const <LocalizationsDelegate<dynamic>>[],
      supportedLocales: withDelegate
          ? FluentLocalizations.supportedLocales
          : <Locale>[locale],
      home: Builder(
        builder: (context) {
          resolved = fluentL10n(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return resolved;
}

void main() {
  group('the message catalogue', () {
    test('ships every locale the delegate claims', () {
      expect(
        FluentLocalizations.supportedLocales,
        hasLength(135),
        reason:
            'l10n/ holds one ARB per supported locale. A locale added there '
            'without regenerating, or regenerated without being added, shows '
            'up here first.',
      );
      expect(
        FluentLocalizations.supportedLocales.first,
        const Locale('en', 'US'),
        reason:
            'l10n.yaml pins en_US as the preferred locale, so it leads the '
            'list and is what a device with no match resolves to.',
      );
    });

    test('every locale answers every message with something', () {
      final empty = <String>[];
      for (final locale in FluentLocalizations.supportedLocales) {
        final messages = _everyMessage(lookupFluentLocalizations(locale));
        for (var i = 0; i < messages.length; i++) {
          if (messages[i].trim().isEmpty) empty.add('$locale [$i]');
        }
      }
      expect(
        empty,
        isEmpty,
        reason:
            'An empty message is an unlabelled control. Every one of these '
            'strings is read aloud and nothing else names the affordance.',
      );
    });

    test('every locale keeps the placeholders its message needs', () {
      final wrong = <String>[];
      for (final locale in FluentLocalizations.supportedLocales) {
        final l = lookupFluentLocalizations(locale);
        // One representative of each arity. A translation that dropped a
        // placeholder loses the value the sentence is about.
        if (!l.slideOf(2, 7).contains('2') || !l.slideOf(2, 7).contains('7')) {
          wrong.add('$locale slideOf');
        }
        if (!l.sankeyLinkDescription('A', 'B', 'C').contains('A') ||
            !l.sankeyLinkDescription('A', 'B', 'C').contains('B') ||
            !l.sankeyLinkDescription('A', 'B', 'C').contains('C')) {
          wrong.add('$locale sankeyLinkDescription');
        }
        if (!l.weekNumber('11').contains('11')) {
          wrong.add('$locale weekNumber');
        }
      }
      expect(wrong, isEmpty);
    });

    test('the trailing space that joins two clauses survives translation', () {
      // `buildFluentCartesianChartDescription` concatenates clauses without
      // separators of its own, so the space lives inside the message. A
      // translation that trimmed it runs two sentences together.
      final missing = <String>[];
      for (final locale in FluentLocalizations.supportedLocales) {
        final l = lookupFluentLocalizations(locale);
        if (!l.chartFallbackTitle.endsWith(' ')) {
          missing.add('$locale chartFallbackTitle');
        }
        if (!l.chartAxisDescription('X', 'values').endsWith(' ')) {
          missing.add('$locale chartAxisDescription');
        }
        if (!l.ganttChartDescription(3).endsWith(' ')) {
          missing.add('$locale ganttChartDescription');
        }
      }
      expect(missing, isEmpty);
    });
  });

  group('resolution', () {
    testWidgets('a country-qualified locale gets its own catalogue', (
      tester,
    ) async {
      expect(
        (await _resolve(tester, const Locale('de', 'DE'))).close,
        'Schließen',
      );
      expect(
        (await _resolve(tester, const Locale('de', 'CH'))).close,
        'Schliessen',
        reason: 'Swiss Standard German has no eszett.',
      );
      expect(
        (await _resolve(
          tester,
          const Locale('en', 'GB'),
        )).donutChartDescription(4),
        'Doughnut chart with 4 slices',
      );
      expect(
        (await _resolve(
          tester,
          const Locale('en', 'US'),
        )).donutChartDescription(4),
        'Donut chart with 4 slices',
      );
    });

    testWidgets('a bare language locale falls back to its base file', (
      tester,
    ) async {
      expect((await _resolve(tester, const Locale('tr'))).close, isNotEmpty);
      expect(
        (await _resolve(tester, const Locale('tr'))).close,
        (await _resolve(tester, const Locale('tr', 'TR'))).close,
      );
    });

    testWidgets('an unlisted country resolves to the language', (tester) async {
      // `cs_SK` is not shipped; Flutter's resolver matches on language and
      // lands on `cs`, which is exactly why the base files exist.
      expect(
        (await _resolve(tester, const Locale('cs', 'SK'))).close,
        (await _resolve(tester, const Locale('cs'))).close,
      );
    });

    testWidgets('no delegate still renders, in English', (tester) async {
      final l = await _resolve(
        tester,
        const Locale('de', 'DE'),
        withDelegate: false,
      );
      expect(
        l.close,
        'Close',
        reason:
            'A design system may not make an application crash for not having '
            'installed its delegate. It degrades to English.',
      );
      expect(identical(l, fluentLocalizationsFallback), isTrue);
    });
  });

  group('components read the catalogue', () {
    testWidgets('a dialog names its close button in the ambient locale', (
      tester,
    ) async {
      await tester.pumpWidget(
        const FluentApp(
          locale: Locale('tr', 'TR'),
          localizationsDelegates: <LocalizationsDelegate<dynamic>>[
            FluentLocalizations.delegate,
          ],
          supportedLocales: FluentLocalizations.supportedLocales,
          home: FluentDialog(
            open: true,
            title: Text('Başlık'),
            content: Text('İçerik'),
            child: SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final turkish = lookupFluentLocalizations(const Locale('tr', 'TR')).close;
      expect(find.bySemanticsLabel(turkish), findsOneWidget);
      expect(find.bySemanticsLabel('Close'), findsNothing);
    });

    testWidgets('an explicit label still wins over the catalogue', (
      tester,
    ) async {
      await tester.pumpWidget(
        const FluentApp(
          locale: Locale('tr', 'TR'),
          localizationsDelegates: <LocalizationsDelegate<dynamic>>[
            FluentLocalizations.delegate,
          ],
          supportedLocales: FluentLocalizations.supportedLocales,
          home: FluentDialog(
            open: true,
            closeButtonSemanticLabel: 'Kapat pencereyi',
            title: Text('Başlık'),
            content: Text('İçerik'),
            child: SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Kapat pencereyi'), findsOneWidget);
    });

    testWidgets('a calendar takes its chrome from the catalogue', (
      tester,
    ) async {
      await tester.pumpWidget(
        FluentApp(
          locale: const Locale('fr', 'FR'),
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            FluentLocalizations.delegate,
          ],
          supportedLocales: FluentLocalizations.supportedLocales,
          home: FluentCalendar(
            value: DateTime(2026, 3, 10),
            onSelectDate: (_) {},
            showGoToToday: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final french = lookupFluentLocalizations(const Locale('fr', 'FR'));
      expect(find.text(french.goToToday), findsOneWidget);
      expect(find.bySemanticsLabel(french.previousMonth), findsOneWidget);
    });

    testWidgets('presence status names come from the catalogue', (
      tester,
    ) async {
      final italian = lookupFluentLocalizations(const Locale('it', 'IT'));
      expect(
        fluentPresenceStatusLabel(
          FluentPresenceStatus.busy,
          outOfOffice: false,
          l10n: italian,
        ),
        italian.presenceBusy,
      );
      expect(
        fluentPresenceStatusLabel(
          FluentPresenceStatus.busy,
          outOfOffice: true,
          l10n: italian,
        ),
        italian.presenceOutOfOfficeStatus(italian.presenceBusy),
        reason: 'The flag wraps the status rather than replacing it.',
      );
      expect(
        fluentPresenceStatusLabel(
          FluentPresenceStatus.outOfOffice,
          outOfOffice: true,
          l10n: italian,
        ),
        italian.presenceOutOfOffice,
        reason: 'Out of office out of office would say it twice.',
      );
    });
  });
}
