// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fluent_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Belarusian (`be`).
class FluentLocalizationsBe extends FluentLocalizations {
  FluentLocalizationsBe([String locale = 'be']) : super(locale);

  @override
  String get close => 'Закрыць';

  @override
  String get dismiss => 'Адхіліць';

  @override
  String get clear => 'Ачысціць';

  @override
  String get open => 'Адкрыць';

  @override
  String get remove => 'Выдаліць';

  @override
  String get more => 'Яшчэ';

  @override
  String get overflowMore => 'яшчэ';

  @override
  String get selectAllRows => 'Выбраць усе радкі';

  @override
  String get selectRow => 'Выбраць радок';

  @override
  String get sort => 'Сартаваць';

  @override
  String get sortedAscending => 'Сартавана па ўзрастанні';

  @override
  String get sortedDescending => 'Сартавана па спаданні';

  @override
  String get previousSlide => 'Папярэдні слайд';

  @override
  String get nextSlide => 'Наступны слайд';

  @override
  String get startSlideShow => 'Запусціць аўтаматычны паказ слайдаў';

  @override
  String get pauseSlideShow => 'Прыпыніць аўтаматычны паказ слайдаў';

  @override
  String slideOf(int index, int count) {
    return 'Слайд $index з $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Крок $index з $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value з $max';
  }

  @override
  String get openCalendar => 'Адкрыць каляндар';

  @override
  String get invalidDateFormat => 'Няправільны фармат даты.';

  @override
  String get dateOutOfRange =>
      'Дата выходзіць за межы дапушчальнага дыяпазону.';

  @override
  String get fieldRequired => 'Гэтае поле абавязковае.';

  @override
  String get goToToday => 'Перайсці да сённяшняга дня';

  @override
  String get previousMonth => 'Папярэдні месяц';

  @override
  String get nextMonth => 'Наступны месяц';

  @override
  String get previousYear => 'Папярэдні год';

  @override
  String get nextYear => 'Наступны год';

  @override
  String get previousYearRange => 'Папярэдні дыяпазон гадоў';

  @override
  String get nextYearRange => 'Наступны дыяпазон гадоў';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, змяніць год';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, змяніць месяц';
  }

  @override
  String selectedDate(String date) {
    return 'Выбраная дата $date';
  }

  @override
  String todaysDate(String date) {
    return 'Сённяшняя дата $date';
  }

  @override
  String weekNumber(String number) {
    return 'Тыдзень $number';
  }

  @override
  String get chartNoData => 'У графіка няма даных для адлюстравання';

  @override
  String get chartNoDataAvailable => 'Няма даступных даных';

  @override
  String get chartFallbackTitle => 'Дыяграма. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'Вось $axis паказвае $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'другасная Y';

  @override
  String get chartAxisCategories => 'катэгорыі';

  @override
  String get chartAxisTime => 'час';

  @override
  String get chartAxisValues => 'значэнні';

  @override
  String get chartLineLegendFallback => 'Лінія';

  @override
  String funnelChartDescription(int count) {
    return 'Варонкавая дыяграма з $count сегментамі';
  }

  @override
  String donutChartDescription(int count) {
    return 'Кальцавая дыяграма з $count сектарамі';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Дыяграма-індыкатар з $count сегментамі. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Бягучае значэнне: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Бягучае значэнне — $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Мінімальнае значэнне: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Максімальнае значэнне: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Невядома';

  @override
  String ganttChartDescription(int count) {
    return 'Дыяграма Ганта з $count пунктамі даных. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Цеплавая карта з $count пунктамі даных. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Палярная дыяграма з $count радамі даных.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Міні-дыяграма з подпісам $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Дыяграма Санкі з $nodes вузламі і $links сувязямі';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Ад $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'вузел $name з вагой $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'сувязь ад $source да $target з вагой $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Слупкавая дыяграма з $count слупкамі. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Слупкавая дыяграма з $count слупкамі і 1 лініяй. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Слупкавая дыяграма з $count згрупаванымі радамі слупкоў. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Слупкавая дыяграма з $count згрупаванымі радамі слупкоў і $lines радамі ліній. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Слупкавая дыяграма з $count слупкамі з накапленнем. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Слупкавая дыяграма з $count слупкамі з накапленнем і $lines лініямі. ';
  }

  @override
  String get presenceAvailable => 'Даступны';

  @override
  String get presenceAway => 'Адсутнічае';

  @override
  String get presenceBusy => 'Заняты';

  @override
  String get presenceDoNotDisturb => 'Не турбаваць';

  @override
  String get presenceBlocked => 'Заблакіравана';

  @override
  String get presenceOffline => 'Не ў сетцы';

  @override
  String get presenceOutOfOffice => 'Не на працы';

  @override
  String get presenceUnknown => 'Невядома';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, не на працы';
  }
}

/// The translations for Belarusian, as used in Belarus (`be_BY`).
class FluentLocalizationsBeBy extends FluentLocalizationsBe {
  FluentLocalizationsBeBy() : super('be_BY');

  @override
  String get close => 'Закрыць';

  @override
  String get dismiss => 'Адхіліць';

  @override
  String get clear => 'Ачысціць';

  @override
  String get open => 'Адкрыць';

  @override
  String get remove => 'Выдаліць';

  @override
  String get more => 'Яшчэ';

  @override
  String get overflowMore => 'яшчэ';

  @override
  String get selectAllRows => 'Выбраць усе радкі';

  @override
  String get selectRow => 'Выбраць радок';

  @override
  String get sort => 'Сартаваць';

  @override
  String get sortedAscending => 'Сартавана па ўзрастанні';

  @override
  String get sortedDescending => 'Сартавана па спаданні';

  @override
  String get previousSlide => 'Папярэдні слайд';

  @override
  String get nextSlide => 'Наступны слайд';

  @override
  String get startSlideShow => 'Запусціць аўтаматычны паказ слайдаў';

  @override
  String get pauseSlideShow => 'Прыпыніць аўтаматычны паказ слайдаў';

  @override
  String slideOf(int index, int count) {
    return 'Слайд $index з $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Крок $index з $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value з $max';
  }

  @override
  String get openCalendar => 'Адкрыць каляндар';

  @override
  String get invalidDateFormat => 'Няправільны фармат даты.';

  @override
  String get dateOutOfRange =>
      'Дата выходзіць за межы дапушчальнага дыяпазону.';

  @override
  String get fieldRequired => 'Гэтае поле абавязковае.';

  @override
  String get goToToday => 'Перайсці да сённяшняга дня';

  @override
  String get previousMonth => 'Папярэдні месяц';

  @override
  String get nextMonth => 'Наступны месяц';

  @override
  String get previousYear => 'Папярэдні год';

  @override
  String get nextYear => 'Наступны год';

  @override
  String get previousYearRange => 'Папярэдні дыяпазон гадоў';

  @override
  String get nextYearRange => 'Наступны дыяпазон гадоў';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, змяніць год';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, змяніць месяц';
  }

  @override
  String selectedDate(String date) {
    return 'Выбраная дата $date';
  }

  @override
  String todaysDate(String date) {
    return 'Сённяшняя дата $date';
  }

  @override
  String weekNumber(String number) {
    return 'Тыдзень $number';
  }

  @override
  String get chartNoData => 'У графіка няма даных для адлюстравання';

  @override
  String get chartNoDataAvailable => 'Няма даступных даных';

  @override
  String get chartFallbackTitle => 'Дыяграма. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'Вось $axis паказвае $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'другасная Y';

  @override
  String get chartAxisCategories => 'катэгорыі';

  @override
  String get chartAxisTime => 'час';

  @override
  String get chartAxisValues => 'значэнні';

  @override
  String get chartLineLegendFallback => 'Лінія';

  @override
  String funnelChartDescription(int count) {
    return 'Варонкавая дыяграма з $count сегментамі';
  }

  @override
  String donutChartDescription(int count) {
    return 'Кальцавая дыяграма з $count сектарамі';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Дыяграма-індыкатар з $count сегментамі. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Бягучае значэнне: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Бягучае значэнне — $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Мінімальнае значэнне: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Максімальнае значэнне: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Невядома';

  @override
  String ganttChartDescription(int count) {
    return 'Дыяграма Ганта з $count пунктамі даных. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Цеплавая карта з $count пунктамі даных. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Палярная дыяграма з $count радамі даных.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Міні-дыяграма з подпісам $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Дыяграма Санкі з $nodes вузламі і $links сувязямі';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Ад $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'вузел $name з вагой $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'сувязь ад $source да $target з вагой $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Слупкавая дыяграма з $count слупкамі. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Слупкавая дыяграма з $count слупкамі і 1 лініяй. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Слупкавая дыяграма з $count згрупаванымі радамі слупкоў. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Слупкавая дыяграма з $count згрупаванымі радамі слупкоў і $lines радамі ліній. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Слупкавая дыяграма з $count слупкамі з накапленнем. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Слупкавая дыяграма з $count слупкамі з накапленнем і $lines лініямі. ';
  }

  @override
  String get presenceAvailable => 'Даступны';

  @override
  String get presenceAway => 'Адсутнічае';

  @override
  String get presenceBusy => 'Заняты';

  @override
  String get presenceDoNotDisturb => 'Не турбаваць';

  @override
  String get presenceBlocked => 'Заблакіравана';

  @override
  String get presenceOffline => 'Не ў сетцы';

  @override
  String get presenceOutOfOffice => 'Не на працы';

  @override
  String get presenceUnknown => 'Невядома';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, не на працы';
  }
}
