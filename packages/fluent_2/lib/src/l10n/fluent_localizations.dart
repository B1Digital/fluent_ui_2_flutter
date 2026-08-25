import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' as intl;

import 'fluent_localizations_ar.dart';
import 'fluent_localizations_be.dart';
import 'fluent_localizations_cs.dart';
import 'fluent_localizations_de.dart';
import 'fluent_localizations_el.dart';
import 'fluent_localizations_en.dart';
import 'fluent_localizations_es.dart';
import 'fluent_localizations_fa.dart';
import 'fluent_localizations_fil.dart';
import 'fluent_localizations_fr.dart';
import 'fluent_localizations_he.dart';
import 'fluent_localizations_hi.dart';
import 'fluent_localizations_hr.dart';
import 'fluent_localizations_hu.dart';
import 'fluent_localizations_id.dart';
import 'fluent_localizations_it.dart';
import 'fluent_localizations_ja.dart';
import 'fluent_localizations_ko.dart';
import 'fluent_localizations_ms.dart';
import 'fluent_localizations_ne.dart';
import 'fluent_localizations_nl.dart';
import 'fluent_localizations_pl.dart';
import 'fluent_localizations_pt.dart';
import 'fluent_localizations_ro.dart';
import 'fluent_localizations_ru.dart';
import 'fluent_localizations_ta.dart';
import 'fluent_localizations_th.dart';
import 'fluent_localizations_tr.dart';
import 'fluent_localizations_uk.dart';
import 'fluent_localizations_ur.dart';
import 'fluent_localizations_uz.dart';
import 'fluent_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of FluentLocalizations
/// returned by `FluentLocalizations.of(context)`.
///
/// Applications need to include `FluentLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'fluent_l10n/fluent_localizations.dart';
///
/// return FluentApp(
///   localizationsDelegates: <LocalizationsDelegate<dynamic>>[FluentLocalizations.delegate],
///   supportedLocales: FluentLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the FluentLocalizations.supportedLocales
/// property.
abstract class FluentLocalizations {
  FluentLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static FluentLocalizations? of(BuildContext context) {
    return Localizations.of<FluentLocalizations>(context, FluentLocalizations);
  }

  static const LocalizationsDelegate<FluentLocalizations> delegate =
      _FluentLocalizationsDelegate();

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en', 'US'),
    Locale('ar'),
    Locale('ar', 'AE'),
    Locale('ar', 'DZ'),
    Locale('ar', 'EG'),
    Locale('ar', 'IQ'),
    Locale('ar', 'JO'),
    Locale('ar', 'KW'),
    Locale('ar', 'LB'),
    Locale('ar', 'MA'),
    Locale('ar', 'QA'),
    Locale('ar', 'SA'),
    Locale('ar', 'TN'),
    Locale('be'),
    Locale('be', 'BY'),
    Locale('cs'),
    Locale('cs', 'CZ'),
    Locale('de'),
    Locale('de', 'AT'),
    Locale('de', 'CH'),
    Locale('de', 'DE'),
    Locale('de', 'LI'),
    Locale('de', 'LU'),
    Locale('el'),
    Locale('el', 'CY'),
    Locale('el', 'GR'),
    Locale('en'),
    Locale('en', 'AU'),
    Locale('en', 'CA'),
    Locale('en', 'GB'),
    Locale('en', 'IE'),
    Locale('en', 'IN'),
    Locale('en', 'NZ'),
    Locale('en', 'SG'),
    Locale('en', 'ZA'),
    Locale('es'),
    Locale('es', 'AR'),
    Locale('es', 'BO'),
    Locale('es', 'CL'),
    Locale('es', 'CO'),
    Locale('es', 'CR'),
    Locale('es', 'DO'),
    Locale('es', 'EC'),
    Locale('es', 'ES'),
    Locale('es', 'GT'),
    Locale('es', 'MX'),
    Locale('es', 'PA'),
    Locale('es', 'PE'),
    Locale('es', 'PY'),
    Locale('es', 'US'),
    Locale('es', 'UY'),
    Locale('es', 'VE'),
    Locale('fa'),
    Locale('fa', 'AF'),
    Locale('fa', 'IR'),
    Locale('fil'),
    Locale('fil', 'PH'),
    Locale('fr'),
    Locale('fr', 'BE'),
    Locale('fr', 'CA'),
    Locale('fr', 'CH'),
    Locale('fr', 'FR'),
    Locale('fr', 'LU'),
    Locale('he'),
    Locale('he', 'IL'),
    Locale('hi'),
    Locale('hi', 'IN'),
    Locale('hr'),
    Locale('hr', 'BA'),
    Locale('hr', 'HR'),
    Locale('hu'),
    Locale('hu', 'HU'),
    Locale('id'),
    Locale('id', 'ID'),
    Locale('it'),
    Locale('it', 'CH'),
    Locale('it', 'IT'),
    Locale('ja'),
    Locale('ja', 'JP'),
    Locale('ko'),
    Locale('ko', 'KR'),
    Locale('ms'),
    Locale('ms', 'BN'),
    Locale('ms', 'MY'),
    Locale('ms', 'SG'),
    Locale('ne'),
    Locale('ne', 'IN'),
    Locale('ne', 'NP'),
    Locale('nl'),
    Locale('nl', 'BE'),
    Locale('nl', 'NL'),
    Locale('pl'),
    Locale('pl', 'PL'),
    Locale('pt'),
    Locale('pt', 'AO'),
    Locale('pt', 'BR'),
    Locale('pt', 'MZ'),
    Locale('pt', 'PT'),
    Locale('ro'),
    Locale('ro', 'MD'),
    Locale('ro', 'RO'),
    Locale('ru'),
    Locale('ru', 'BY'),
    Locale('ru', 'KG'),
    Locale('ru', 'KZ'),
    Locale('ru', 'RU'),
    Locale('ta'),
    Locale('ta', 'IN'),
    Locale('ta', 'LK'),
    Locale('ta', 'MY'),
    Locale('ta', 'SG'),
    Locale('th'),
    Locale('th', 'TH'),
    Locale('tr'),
    Locale('tr', 'CY'),
    Locale('tr', 'TR'),
    Locale('uk'),
    Locale('uk', 'UA'),
    Locale('ur'),
    Locale('ur', 'IN'),
    Locale('ur', 'PK'),
    Locale('uz'),
    Locale('uz', 'UZ'),
    Locale('zh'),
    Locale('zh', 'CN'),
    Locale('zh', 'HK'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(
      languageCode: 'zh',
      countryCode: 'CN',
      scriptCode: 'Hans',
    ),
    Locale.fromSubtags(
      languageCode: 'zh',
      countryCode: 'SG',
      scriptCode: 'Hans',
    ),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    Locale.fromSubtags(
      languageCode: 'zh',
      countryCode: 'HK',
      scriptCode: 'Hant',
    ),
    Locale.fromSubtags(
      languageCode: 'zh',
      countryCode: 'MO',
      scriptCode: 'Hant',
    ),
    Locale.fromSubtags(
      languageCode: 'zh',
      countryCode: 'TW',
      scriptCode: 'Hant',
    ),
    Locale('zh', 'SG'),
    Locale('zh', 'TW'),
  ];

  /// Accessible name of a control that closes a dialog, popover or calendar.
  ///
  /// In en_US, this message translates to:
  /// **'Close'**
  String get close;

  /// Accessible name of a control that dismisses a toast, tag or message bar.
  ///
  /// In en_US, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// Accessible name of a control that empties an input.
  ///
  /// In en_US, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Accessible name of a control that opens an input's picker surface.
  ///
  /// In en_US, this message translates to:
  /// **'Open'**
  String get open;

  /// Accessible name of a control that removes one selected item from a picker.
  ///
  /// In en_US, this message translates to:
  /// **'Remove'**
  String get remove;

  /// Accessible name of a breadcrumb's overflow trigger.
  ///
  /// In en_US, this message translates to:
  /// **'More'**
  String get more;

  /// Trailing word of a chart legend's overflow trigger, which reads '+3 more'. Lower case because it follows a number in the same phrase.
  ///
  /// In en_US, this message translates to:
  /// **'more'**
  String get overflowMore;

  /// Accessible name of the checkbox in a data grid's header row.
  ///
  /// In en_US, this message translates to:
  /// **'Select all rows'**
  String get selectAllRows;

  /// Accessible name of the checkbox in a data grid's body row.
  ///
  /// In en_US, this message translates to:
  /// **'Select row'**
  String get selectRow;

  /// Accessible name of an unsorted column's sort button in a data grid.
  ///
  /// In en_US, this message translates to:
  /// **'Sort'**
  String get sort;

  /// Accessible name of the sort button on a column sorted smallest first.
  ///
  /// In en_US, this message translates to:
  /// **'Sorted ascending'**
  String get sortedAscending;

  /// Accessible name of the sort button on a column sorted largest first.
  ///
  /// In en_US, this message translates to:
  /// **'Sorted descending'**
  String get sortedDescending;

  /// Accessible name of a carousel's back chevron.
  ///
  /// In en_US, this message translates to:
  /// **'Previous slide'**
  String get previousSlide;

  /// Accessible name of a carousel's forward chevron.
  ///
  /// In en_US, this message translates to:
  /// **'Next slide'**
  String get nextSlide;

  /// Accessible name of a carousel's play button.
  ///
  /// In en_US, this message translates to:
  /// **'Start automatic slide show'**
  String get startSlideShow;

  /// Accessible name of a carousel's pause button.
  ///
  /// In en_US, this message translates to:
  /// **'Pause automatic slide show'**
  String get pauseSlideShow;

  /// Accessible name of one dot in a carousel's indicator.
  ///
  /// In en_US, this message translates to:
  /// **'Slide {index} of {count}'**
  String slideOf(int index, int count);

  /// Accessible name of one dot in a teaching popover's step indicator.
  ///
  /// In en_US, this message translates to:
  /// **'Step {index} of {count}'**
  String stepOf(int index, int count);

  /// Announced value of a rating control, such as '3 of 5'.
  ///
  /// In en_US, this message translates to:
  /// **'{value} of {max}'**
  String ratingValueOf(String value, String max);

  /// Accessible name of a date picker's calendar button.
  ///
  /// In en_US, this message translates to:
  /// **'Open calendar'**
  String get openCalendar;

  /// Validation message shown when typed text is not a date.
  ///
  /// In en_US, this message translates to:
  /// **'Invalid date format.'**
  String get invalidDateFormat;

  /// Validation message shown when a date falls outside the allowed bounds.
  ///
  /// In en_US, this message translates to:
  /// **'Date is out of the allowed range.'**
  String get dateOutOfRange;

  /// Validation message shown when a required field is left empty.
  ///
  /// In en_US, this message translates to:
  /// **'This field is required.'**
  String get fieldRequired;

  /// Label of the link that returns a calendar to the current month.
  ///
  /// In en_US, this message translates to:
  /// **'Go to today'**
  String get goToToday;

  /// Accessible name of the back chevron in a calendar's month view.
  ///
  /// In en_US, this message translates to:
  /// **'Previous month'**
  String get previousMonth;

  /// Accessible name of the forward chevron in a calendar's month view.
  ///
  /// In en_US, this message translates to:
  /// **'Next month'**
  String get nextMonth;

  /// Accessible name of the back chevron in a calendar's year view.
  ///
  /// In en_US, this message translates to:
  /// **'Previous year'**
  String get previousYear;

  /// Accessible name of the forward chevron in a calendar's year view.
  ///
  /// In en_US, this message translates to:
  /// **'Next year'**
  String get nextYear;

  /// Accessible name of the back chevron in a calendar's decade view.
  ///
  /// In en_US, this message translates to:
  /// **'Previous year range'**
  String get previousYearRange;

  /// Accessible name of the forward chevron in a calendar's decade view.
  ///
  /// In en_US, this message translates to:
  /// **'Next year range'**
  String get nextYearRange;

  /// Accessible name of the caption button in a calendar's month view, which switches to the year view.
  ///
  /// In en_US, this message translates to:
  /// **'{caption}, change year'**
  String monthPickerHeader(String caption);

  /// Accessible name of the caption button in a calendar's year view, which switches back to the month view.
  ///
  /// In en_US, this message translates to:
  /// **'{caption}, change month'**
  String yearPickerHeader(String caption);

  /// Announced for a calendar's selected day cell.
  ///
  /// In en_US, this message translates to:
  /// **'Selected date {date}'**
  String selectedDate(String date);

  /// Announced for a calendar's cell for the current day.
  ///
  /// In en_US, this message translates to:
  /// **'Today\'s date {date}'**
  String todaysDate(String date);

  /// Announced for a calendar's week-number cell, which draws the bare number.
  ///
  /// In en_US, this message translates to:
  /// **'Week {number}'**
  String weekNumber(String number);

  /// Announced in place of a chart that was given no data.
  ///
  /// In en_US, this message translates to:
  /// **'Graph has no data to display'**
  String get chartNoData;

  /// Drawn in a chart cell or table that has no value for that position.
  ///
  /// In en_US, this message translates to:
  /// **'No data available'**
  String get chartNoDataAvailable;

  /// Opens a cartesian chart's description when the caller gave no title. The trailing space separates it from the sentence that follows.
  ///
  /// In en_US, this message translates to:
  /// **'Chart. '**
  String get chartFallbackTitle;

  /// One clause of a cartesian chart's description. The trailing space separates it from the next clause.
  ///
  /// In en_US, this message translates to:
  /// **'The {axis} axis displays {subject}. '**
  String chartAxisDescription(String axis, String subject);

  /// Names the horizontal axis inside chartAxisDescription.
  ///
  /// In en_US, this message translates to:
  /// **'X'**
  String get chartAxisX;

  /// Names the vertical axis inside chartAxisDescription.
  ///
  /// In en_US, this message translates to:
  /// **'Y'**
  String get chartAxisY;

  /// Names the second vertical axis inside chartAxisDescription. Lower case because it appears mid-sentence.
  ///
  /// In en_US, this message translates to:
  /// **'secondary Y'**
  String get chartAxisSecondaryY;

  /// What a band axis displays, used as chartAxisDescription's subject.
  ///
  /// In en_US, this message translates to:
  /// **'categories'**
  String get chartAxisCategories;

  /// What a date axis displays, used as chartAxisDescription's subject.
  ///
  /// In en_US, this message translates to:
  /// **'time'**
  String get chartAxisTime;

  /// What a numeric axis displays, used as chartAxisDescription's subject.
  ///
  /// In en_US, this message translates to:
  /// **'values'**
  String get chartAxisValues;

  /// Stands in for an untitled line series in a bar chart's callout.
  ///
  /// In en_US, this message translates to:
  /// **'Line'**
  String get chartLineLegendFallback;

  /// Accessible description of a funnel chart.
  ///
  /// In en_US, this message translates to:
  /// **'Funnel chart with {count} segments'**
  String funnelChartDescription(int count);

  /// Accessible description of a donut chart.
  ///
  /// In en_US, this message translates to:
  /// **'Donut chart with {count} slices'**
  String donutChartDescription(int count);

  /// Accessible description of a gauge chart. The trailing space matches the upstream string.
  ///
  /// In en_US, this message translates to:
  /// **'Gauge chart with {count} segments. '**
  String gaugeChartDescription(int count);

  /// Accessible name of a gauge's needle.
  ///
  /// In en_US, this message translates to:
  /// **'Current value: {value}'**
  String gaugeCurrentValue(String value);

  /// Heading of a gauge's hover callout.
  ///
  /// In en_US, this message translates to:
  /// **'Current value is {value}'**
  String gaugeCurrentValueIs(String value);

  /// Accessible name of a gauge's lower limit.
  ///
  /// In en_US, this message translates to:
  /// **'Min value: {value}'**
  String gaugeMinValue(String value);

  /// Accessible name of a gauge's upper limit.
  ///
  /// In en_US, this message translates to:
  /// **'Max value: {value}'**
  String gaugeMaxValue(String value);

  /// Legend of the band a gauge appends to fill the gap up to its maximum.
  ///
  /// In en_US, this message translates to:
  /// **'Unknown'**
  String get gaugeUnknownSegment;

  /// Accessible description of a Gantt chart. The trailing space matches the upstream string.
  ///
  /// In en_US, this message translates to:
  /// **'Gantt chart with {count} data points. '**
  String ganttChartDescription(int count);

  /// Accessible description of a heat map chart. The trailing space matches the upstream string.
  ///
  /// In en_US, this message translates to:
  /// **'Heat map chart with {count} data points. '**
  String heatMapChartDescription(int count);

  /// Accessible description of a polar chart.
  ///
  /// In en_US, this message translates to:
  /// **'Polar chart with {count} data series.'**
  String polarChartDescription(int count);

  /// Accessible description of a sparkline.
  ///
  /// In en_US, this message translates to:
  /// **'Sparkline with label {label}'**
  String sparklineDescription(String label);

  /// Accessible description of a Sankey chart.
  ///
  /// In en_US, this message translates to:
  /// **'Sankey chart with {nodes} nodes and {links} links'**
  String sankeyChartDescription(int nodes, int links);

  /// Heading of a Sankey link's callout.
  ///
  /// In en_US, this message translates to:
  /// **'From {node}'**
  String sankeyLinkFrom(String node);

  /// Accessible description of one Sankey node. Lower case because it is joined into a longer sentence.
  ///
  /// In en_US, this message translates to:
  /// **'node {name} with weight {weight}'**
  String sankeyNodeDescription(String name, String weight);

  /// Accessible description of one Sankey link. Lower case because it is joined into a longer sentence.
  ///
  /// In en_US, this message translates to:
  /// **'link from {source} to {target} with weight {weight}'**
  String sankeyLinkDescription(String source, String target, String weight);

  /// Accessible description of a vertical bar chart with no line overlay. The trailing space matches the upstream string.
  ///
  /// In en_US, this message translates to:
  /// **'Vertical bar chart with {count} bars. '**
  String verticalBarChartDescription(int count);

  /// Accessible description of a vertical bar chart carrying a line overlay. Upstream never counts past one here.
  ///
  /// In en_US, this message translates to:
  /// **'Vertical bar chart with {count} bars and 1 line. '**
  String verticalBarChartWithLineDescription(int count);

  /// Accessible description of a grouped vertical bar chart with no line series.
  ///
  /// In en_US, this message translates to:
  /// **'Vertical bar chart with {count} grouped bar series. '**
  String groupedVerticalBarChartDescription(int count);

  /// Accessible description of a grouped vertical bar chart carrying line series.
  ///
  /// In en_US, this message translates to:
  /// **'Vertical bar chart with {count} grouped bar series and {lines} line series. '**
  String groupedVerticalBarChartWithLinesDescription(int count, int lines);

  /// Accessible description of a vertical stacked bar chart with no line series.
  ///
  /// In en_US, this message translates to:
  /// **'Vertical bar chart with {count} stacked bars. '**
  String verticalStackedBarChartDescription(int count);

  /// Accessible description of a vertical stacked bar chart carrying line series. Upstream does not pluralise 'lines'.
  ///
  /// In en_US, this message translates to:
  /// **'Vertical bar chart with {count} stacked bars and {lines} lines. '**
  String verticalStackedBarChartWithLinesDescription(int count, int lines);

  /// Accessible name of a presence badge showing the person is reachable.
  ///
  /// In en_US, this message translates to:
  /// **'Available'**
  String get presenceAvailable;

  /// Accessible name of a presence badge showing the person has stepped away.
  ///
  /// In en_US, this message translates to:
  /// **'Away'**
  String get presenceAway;

  /// Accessible name of a presence badge showing the person is busy.
  ///
  /// In en_US, this message translates to:
  /// **'Busy'**
  String get presenceBusy;

  /// Accessible name of a presence badge showing the person does not want to be interrupted.
  ///
  /// In en_US, this message translates to:
  /// **'Do not disturb'**
  String get presenceDoNotDisturb;

  /// Accessible name of a presence badge showing the person is blocked.
  ///
  /// In en_US, this message translates to:
  /// **'Blocked'**
  String get presenceBlocked;

  /// Accessible name of a presence badge showing the person is not signed in.
  ///
  /// In en_US, this message translates to:
  /// **'Offline'**
  String get presenceOffline;

  /// Accessible name of a presence badge showing the person is away from work.
  ///
  /// In en_US, this message translates to:
  /// **'Out of office'**
  String get presenceOutOfOffice;

  /// Accessible name of a presence badge whose status is not known.
  ///
  /// In en_US, this message translates to:
  /// **'Unknown'**
  String get presenceUnknown;

  /// Accessible name of a presence badge carrying the out-of-office flag on top of another status, e.g. 'Busy out of office'.
  ///
  /// In en_US, this message translates to:
  /// **'{status} out of office'**
  String presenceOutOfOfficeStatus(String status);
}

class _FluentLocalizationsDelegate
    extends LocalizationsDelegate<FluentLocalizations> {
  const _FluentLocalizationsDelegate();

  @override
  Future<FluentLocalizations> load(Locale locale) {
    return SynchronousFuture<FluentLocalizations>(
      lookupFluentLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'be',
    'cs',
    'de',
    'el',
    'en',
    'es',
    'fa',
    'fil',
    'fr',
    'he',
    'hi',
    'hr',
    'hu',
    'id',
    'it',
    'ja',
    'ko',
    'ms',
    'ne',
    'nl',
    'pl',
    'pt',
    'ro',
    'ru',
    'ta',
    'th',
    'tr',
    'uk',
    'ur',
    'uz',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_FluentLocalizationsDelegate old) => false;
}

FluentLocalizations lookupFluentLocalizations(Locale locale) {
  // Lookup logic when language+script+country codes are specified.
  switch (locale.toString()) {
    case 'zh_Hans_CN':
      return FluentLocalizationsZhHansCn();
    case 'zh_Hans_SG':
      return FluentLocalizationsZhHansSg();
    case 'zh_Hant_HK':
      return FluentLocalizationsZhHantHk();
    case 'zh_Hant_MO':
      return FluentLocalizationsZhHantMo();
    case 'zh_Hant_TW':
      return FluentLocalizationsZhHantTw();
  }

  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return FluentLocalizationsZhHans();
          case 'Hant':
            return FluentLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'ar':
      {
        switch (locale.countryCode) {
          case 'AE':
            return FluentLocalizationsArAe();
          case 'DZ':
            return FluentLocalizationsArDz();
          case 'EG':
            return FluentLocalizationsArEg();
          case 'IQ':
            return FluentLocalizationsArIq();
          case 'JO':
            return FluentLocalizationsArJo();
          case 'KW':
            return FluentLocalizationsArKw();
          case 'LB':
            return FluentLocalizationsArLb();
          case 'MA':
            return FluentLocalizationsArMa();
          case 'QA':
            return FluentLocalizationsArQa();
          case 'SA':
            return FluentLocalizationsArSa();
          case 'TN':
            return FluentLocalizationsArTn();
        }
        break;
      }
    case 'be':
      {
        switch (locale.countryCode) {
          case 'BY':
            return FluentLocalizationsBeBy();
        }
        break;
      }
    case 'cs':
      {
        switch (locale.countryCode) {
          case 'CZ':
            return FluentLocalizationsCsCz();
        }
        break;
      }
    case 'de':
      {
        switch (locale.countryCode) {
          case 'AT':
            return FluentLocalizationsDeAt();
          case 'CH':
            return FluentLocalizationsDeCh();
          case 'DE':
            return FluentLocalizationsDeDe();
          case 'LI':
            return FluentLocalizationsDeLi();
          case 'LU':
            return FluentLocalizationsDeLu();
        }
        break;
      }
    case 'el':
      {
        switch (locale.countryCode) {
          case 'CY':
            return FluentLocalizationsElCy();
          case 'GR':
            return FluentLocalizationsElGr();
        }
        break;
      }
    case 'en':
      {
        switch (locale.countryCode) {
          case 'AU':
            return FluentLocalizationsEnAu();
          case 'CA':
            return FluentLocalizationsEnCa();
          case 'GB':
            return FluentLocalizationsEnGb();
          case 'IE':
            return FluentLocalizationsEnIe();
          case 'IN':
            return FluentLocalizationsEnIn();
          case 'NZ':
            return FluentLocalizationsEnNz();
          case 'SG':
            return FluentLocalizationsEnSg();
          case 'US':
            return FluentLocalizationsEnUs();
          case 'ZA':
            return FluentLocalizationsEnZa();
        }
        break;
      }
    case 'es':
      {
        switch (locale.countryCode) {
          case 'AR':
            return FluentLocalizationsEsAr();
          case 'BO':
            return FluentLocalizationsEsBo();
          case 'CL':
            return FluentLocalizationsEsCl();
          case 'CO':
            return FluentLocalizationsEsCo();
          case 'CR':
            return FluentLocalizationsEsCr();
          case 'DO':
            return FluentLocalizationsEsDo();
          case 'EC':
            return FluentLocalizationsEsEc();
          case 'ES':
            return FluentLocalizationsEsEs();
          case 'GT':
            return FluentLocalizationsEsGt();
          case 'MX':
            return FluentLocalizationsEsMx();
          case 'PA':
            return FluentLocalizationsEsPa();
          case 'PE':
            return FluentLocalizationsEsPe();
          case 'PY':
            return FluentLocalizationsEsPy();
          case 'US':
            return FluentLocalizationsEsUs();
          case 'UY':
            return FluentLocalizationsEsUy();
          case 'VE':
            return FluentLocalizationsEsVe();
        }
        break;
      }
    case 'fa':
      {
        switch (locale.countryCode) {
          case 'AF':
            return FluentLocalizationsFaAf();
          case 'IR':
            return FluentLocalizationsFaIr();
        }
        break;
      }
    case 'fil':
      {
        switch (locale.countryCode) {
          case 'PH':
            return FluentLocalizationsFilPh();
        }
        break;
      }
    case 'fr':
      {
        switch (locale.countryCode) {
          case 'BE':
            return FluentLocalizationsFrBe();
          case 'CA':
            return FluentLocalizationsFrCa();
          case 'CH':
            return FluentLocalizationsFrCh();
          case 'FR':
            return FluentLocalizationsFrFr();
          case 'LU':
            return FluentLocalizationsFrLu();
        }
        break;
      }
    case 'he':
      {
        switch (locale.countryCode) {
          case 'IL':
            return FluentLocalizationsHeIl();
        }
        break;
      }
    case 'hi':
      {
        switch (locale.countryCode) {
          case 'IN':
            return FluentLocalizationsHiIn();
        }
        break;
      }
    case 'hr':
      {
        switch (locale.countryCode) {
          case 'BA':
            return FluentLocalizationsHrBa();
          case 'HR':
            return FluentLocalizationsHrHr();
        }
        break;
      }
    case 'hu':
      {
        switch (locale.countryCode) {
          case 'HU':
            return FluentLocalizationsHuHu();
        }
        break;
      }
    case 'id':
      {
        switch (locale.countryCode) {
          case 'ID':
            return FluentLocalizationsIdId();
        }
        break;
      }
    case 'it':
      {
        switch (locale.countryCode) {
          case 'CH':
            return FluentLocalizationsItCh();
          case 'IT':
            return FluentLocalizationsItIt();
        }
        break;
      }
    case 'ja':
      {
        switch (locale.countryCode) {
          case 'JP':
            return FluentLocalizationsJaJp();
        }
        break;
      }
    case 'ko':
      {
        switch (locale.countryCode) {
          case 'KR':
            return FluentLocalizationsKoKr();
        }
        break;
      }
    case 'ms':
      {
        switch (locale.countryCode) {
          case 'BN':
            return FluentLocalizationsMsBn();
          case 'MY':
            return FluentLocalizationsMsMy();
          case 'SG':
            return FluentLocalizationsMsSg();
        }
        break;
      }
    case 'ne':
      {
        switch (locale.countryCode) {
          case 'IN':
            return FluentLocalizationsNeIn();
          case 'NP':
            return FluentLocalizationsNeNp();
        }
        break;
      }
    case 'nl':
      {
        switch (locale.countryCode) {
          case 'BE':
            return FluentLocalizationsNlBe();
          case 'NL':
            return FluentLocalizationsNlNl();
        }
        break;
      }
    case 'pl':
      {
        switch (locale.countryCode) {
          case 'PL':
            return FluentLocalizationsPlPl();
        }
        break;
      }
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'AO':
            return FluentLocalizationsPtAo();
          case 'BR':
            return FluentLocalizationsPtBr();
          case 'MZ':
            return FluentLocalizationsPtMz();
          case 'PT':
            return FluentLocalizationsPtPt();
        }
        break;
      }
    case 'ro':
      {
        switch (locale.countryCode) {
          case 'MD':
            return FluentLocalizationsRoMd();
          case 'RO':
            return FluentLocalizationsRoRo();
        }
        break;
      }
    case 'ru':
      {
        switch (locale.countryCode) {
          case 'BY':
            return FluentLocalizationsRuBy();
          case 'KG':
            return FluentLocalizationsRuKg();
          case 'KZ':
            return FluentLocalizationsRuKz();
          case 'RU':
            return FluentLocalizationsRuRu();
        }
        break;
      }
    case 'ta':
      {
        switch (locale.countryCode) {
          case 'IN':
            return FluentLocalizationsTaIn();
          case 'LK':
            return FluentLocalizationsTaLk();
          case 'MY':
            return FluentLocalizationsTaMy();
          case 'SG':
            return FluentLocalizationsTaSg();
        }
        break;
      }
    case 'th':
      {
        switch (locale.countryCode) {
          case 'TH':
            return FluentLocalizationsThTh();
        }
        break;
      }
    case 'tr':
      {
        switch (locale.countryCode) {
          case 'CY':
            return FluentLocalizationsTrCy();
          case 'TR':
            return FluentLocalizationsTrTr();
        }
        break;
      }
    case 'uk':
      {
        switch (locale.countryCode) {
          case 'UA':
            return FluentLocalizationsUkUa();
        }
        break;
      }
    case 'ur':
      {
        switch (locale.countryCode) {
          case 'IN':
            return FluentLocalizationsUrIn();
          case 'PK':
            return FluentLocalizationsUrPk();
        }
        break;
      }
    case 'uz':
      {
        switch (locale.countryCode) {
          case 'UZ':
            return FluentLocalizationsUzUz();
        }
        break;
      }
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'CN':
            return FluentLocalizationsZhCn();
          case 'HK':
            return FluentLocalizationsZhHk();
          case 'SG':
            return FluentLocalizationsZhSg();
          case 'TW':
            return FluentLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return FluentLocalizationsAr();
    case 'be':
      return FluentLocalizationsBe();
    case 'cs':
      return FluentLocalizationsCs();
    case 'de':
      return FluentLocalizationsDe();
    case 'el':
      return FluentLocalizationsEl();
    case 'en':
      return FluentLocalizationsEn();
    case 'es':
      return FluentLocalizationsEs();
    case 'fa':
      return FluentLocalizationsFa();
    case 'fil':
      return FluentLocalizationsFil();
    case 'fr':
      return FluentLocalizationsFr();
    case 'he':
      return FluentLocalizationsHe();
    case 'hi':
      return FluentLocalizationsHi();
    case 'hr':
      return FluentLocalizationsHr();
    case 'hu':
      return FluentLocalizationsHu();
    case 'id':
      return FluentLocalizationsId();
    case 'it':
      return FluentLocalizationsIt();
    case 'ja':
      return FluentLocalizationsJa();
    case 'ko':
      return FluentLocalizationsKo();
    case 'ms':
      return FluentLocalizationsMs();
    case 'ne':
      return FluentLocalizationsNe();
    case 'nl':
      return FluentLocalizationsNl();
    case 'pl':
      return FluentLocalizationsPl();
    case 'pt':
      return FluentLocalizationsPt();
    case 'ro':
      return FluentLocalizationsRo();
    case 'ru':
      return FluentLocalizationsRu();
    case 'ta':
      return FluentLocalizationsTa();
    case 'th':
      return FluentLocalizationsTh();
    case 'tr':
      return FluentLocalizationsTr();
    case 'uk':
      return FluentLocalizationsUk();
    case 'ur':
      return FluentLocalizationsUr();
    case 'uz':
      return FluentLocalizationsUz();
    case 'zh':
      return FluentLocalizationsZh();
  }

  throw FlutterError(
    'FluentLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
