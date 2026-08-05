import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

const Locale _enUS = Locale('en', 'US');
const Locale _enGB = Locale('en', 'GB');
const Locale _deDE = Locale('de', 'DE');

Future<void> _pump(
  WidgetTester tester, {
  Locale? locale,
  DateTime? value,
  bool allowTextInput = false,
  ValueChanged<DateTime?>? onSelectDate,
}) async {
  await tester.pumpWidget(
    FluentApp(
      theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      home: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 300,
          child: FluentDatePicker(
            today: DateTime(2026, 3, 10),
            locale: locale,
            value: value,
            allowTextInput: allowTextInput,
            openOnClick: false,
            onSelectDate: onSelectDate ?? (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String _fieldText(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText)).controller.text;

void main() {
  // intl compiles in en_US only; every other locale is data that has to be
  // loaded first. This is the call an application makes too.
  setUpAll(initializeDateFormatting);

  group('fluentIntlFormatDate', () {
    test('renders the locale short date', () {
      final date = DateTime(2026, 12, 31);
      expect(fluentIntlFormatDate(_enUS)(date), '12/31/2026');
      expect(fluentIntlFormatDate(_deDE)(date), '31.12.2026');
    });

    test('an explicit pattern wins over the locale default', () {
      expect(
        fluentIntlFormatDate(_enUS, pattern: 'yyyy-MM-dd')(
          DateTime(2026, 3, 5),
        ),
        '2026-03-05',
      );
    });
  });

  group('fluentIntlParseDate', () {
    test('reads the locale order, not a fixed one', () {
      // The whole point: the same eight characters are two different days.
      expect(fluentIntlParseDate(_enUS)('6/12/2026'), DateTime(2026, 6, 12));
      expect(fluentIntlParseDate(_enGB)('6/12/2026'), DateTime(2026, 12, 6));
    });

    test('an impossible day is null, not rolled into the next month', () {
      expect(fluentIntlParseDate(_enUS)('2/30/2026'), isNull);
    });

    test('garbage and empty text are null', () {
      expect(fluentIntlParseDate(_enUS)('not a date'), isNull);
      expect(fluentIntlParseDate(_enUS)('   '), isNull);
    });

    test('ISO-8601 is accepted as the machine fallback', () {
      expect(fluentIntlParseDate(_deDE)('2026-12-31'), DateTime(2026, 12, 31));
    });
  });

  group('fluentCalendarStrings', () {
    test('carries the locale month and day names', () {
      final strings = fluentCalendarStrings(_deDE);
      expect(strings.months.first, 'Januar');
      expect(strings.months.length, 12);
      expect(strings.shortMonths.length, 12);
      // CLDR order — Sunday first — which is the order the grid indexes by.
      expect(strings.days.first, 'Sonntag');
      expect(strings.shortDays.length, 7);
    });

    test('takes the untranslatable chrome from its template', () {
      const template = FluentCalendarStrings(
        months: <String>[],
        shortMonths: <String>[],
        days: <String>[],
        shortDays: <String>[],
        goToToday: 'Heute',
      );
      final strings = fluentCalendarStrings(_deDE, template: template);
      expect(strings.goToToday, 'Heute');
      expect(strings.months.first, 'Januar');
    });
  });

  group('fluentCalendarDateFormatter', () {
    test('renders captions through the locale', () {
      final formatter = fluentCalendarDateFormatter(_deDE);
      const strings = FluentCalendarStrings.english;
      expect(
        formatter.formatMonthYear(DateTime(2026, 3, 10), strings),
        'März 2026',
      );
      expect(formatter.formatDay(DateTime(2026, 3, 10)), '10');
    });
  });

  group('FluentDatePicker — locale', () {
    testWidgets('a locale formats the field', (tester) async {
      await _pump(tester, locale: _deDE, value: DateTime(2026, 12, 31));
      expect(_fieldText(tester), '31.12.2026');
    });

    testWidgets('no locale keeps the English default', (tester) async {
      await _pump(tester, value: DateTime(2026, 12, 31));
      expect(_fieldText(tester), '12/31/2026');
    });

    testWidgets('a locale parses typed text', (tester) async {
      DateTime? selected;
      await _pump(
        tester,
        locale: _deDE,
        allowTextInput: true,
        onSelectDate: (date) => selected = date,
      );

      await tester.enterText(find.byType(EditableText), '31.12.2026');
      // Settle first: the picker tracks "focus was inside" from a post-frame
      // callback, so blurring in the same frame as the focus never registers as
      // a departure and nothing commits.
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      expect(selected, DateTime(2026, 12, 31));
    });

    testWidgets('changing the locale reformats the field', (tester) async {
      await _pump(tester, locale: _enUS, value: DateTime(2026, 12, 31));
      expect(_fieldText(tester), '12/31/2026');

      await _pump(tester, locale: _deDE, value: DateTime(2026, 12, 31));
      expect(_fieldText(tester), '31.12.2026');
    });

    testWidgets('the ambient Localizations locale is used when none is set', (
      tester,
    ) async {
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          locale: _deDE,
          supportedLocales: const <Locale>[_enUS, _deDE],
          home: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 300,
              child: FluentDatePicker(
                today: DateTime(2026, 3, 10),
                value: DateTime(2026, 12, 31),
                onSelectDate: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_fieldText(tester), '31.12.2026');
    });

    testWidgets('an explicit locale beats the ambient one', (tester) async {
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          locale: _deDE,
          supportedLocales: const <Locale>[_enUS, _deDE],
          home: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 300,
              child: FluentDatePicker(
                today: DateTime(2026, 3, 10),
                locale: _enUS,
                value: DateTime(2026, 12, 31),
                onSelectDate: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_fieldText(tester), '12/31/2026');
    });

    testWidgets('the calendar caption is localized', (tester) async {
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 300,
              child: FluentDatePicker(
                today: DateTime(2026, 3, 10),
                locale: _deDE,
                onSelectDate: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(FluentDatePicker));
      await tester.pumpAndSettle();

      expect(find.text('März 2026'), findsOneWidget);
    });
  });
}
