// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fluent_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class FluentLocalizationsUk extends FluentLocalizations {
  FluentLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get close => 'Закрити';

  @override
  String get dismiss => 'Відхилити';

  @override
  String get clear => 'Очистити';

  @override
  String get open => 'Відкрити';

  @override
  String get remove => 'Видалити';

  @override
  String get more => 'Більше';

  @override
  String get overflowMore => 'ще';

  @override
  String get selectAllRows => 'Вибрати всі рядки';

  @override
  String get selectRow => 'Вибрати рядок';

  @override
  String get sort => 'Сортувати';

  @override
  String get sortedAscending => 'Відсортовано за зростанням';

  @override
  String get sortedDescending => 'Відсортовано за спаданням';

  @override
  String get previousSlide => 'Попередній слайд';

  @override
  String get nextSlide => 'Наступний слайд';

  @override
  String get startSlideShow => 'Запустити автоматичний показ слайдів';

  @override
  String get pauseSlideShow => 'Призупинити автоматичний показ слайдів';

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
  String get openCalendar => 'Відкрити календар';

  @override
  String get invalidDateFormat => 'Неправильний формат дати.';

  @override
  String get dateOutOfRange => 'Дата виходить за межі дозволеного діапазону.';

  @override
  String get fieldRequired => 'Це поле обов’язкове.';

  @override
  String get goToToday => 'Перейти до сьогоднішнього дня';

  @override
  String get previousMonth => 'Попередній місяць';

  @override
  String get nextMonth => 'Наступний місяць';

  @override
  String get previousYear => 'Попередній рік';

  @override
  String get nextYear => 'Наступний рік';

  @override
  String get previousYearRange => 'Попередній діапазон років';

  @override
  String get nextYearRange => 'Наступний діапазон років';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, змінити рік';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, змінити місяць';
  }

  @override
  String selectedDate(String date) {
    return 'Вибрана дата $date';
  }

  @override
  String todaysDate(String date) {
    return 'Сьогоднішня дата $date';
  }

  @override
  String weekNumber(String number) {
    return 'Тиждень $number';
  }

  @override
  String get chartNoData => 'Графік не має даних для відображення';

  @override
  String get chartNoDataAvailable => 'Немає доступних даних';

  @override
  String get chartFallbackTitle => 'Діаграма. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'Вісь $axis відображає $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y (додаткова)';

  @override
  String get chartAxisCategories => 'категорії';

  @override
  String get chartAxisTime => 'час';

  @override
  String get chartAxisValues => 'значення';

  @override
  String get chartLineLegendFallback => 'Лінія';

  @override
  String funnelChartDescription(int count) {
    return 'Лійкова діаграма з $count сегментами';
  }

  @override
  String donutChartDescription(int count) {
    return 'Кільцева діаграма з $count секторами';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Індикаторна діаграма з $count сегментами. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Поточне значення: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Поточне значення — $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Мінімальне значення: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Максимальне значення: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Невідомо';

  @override
  String ganttChartDescription(int count) {
    return 'Діаграма Ганта з $count точками даних. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Теплова карта з $count точками даних. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Полярна діаграма з $count рядами даних.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Спарклайн із міткою $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Діаграма Санкі з $nodes вузлами та $links зв’язками';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Від $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'вузол $name з вагою $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'зв’язок від $source до $target з вагою $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Вертикальна стовпчаста діаграма з $count стовпцями. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Вертикальна стовпчаста діаграма з $count стовпцями та 1 лінією. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Вертикальна стовпчаста діаграма з $count згрупованими рядами стовпців. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Вертикальна стовпчаста діаграма з $count згрупованими рядами стовпців і $lines рядами ліній. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Вертикальна стовпчаста діаграма з $count стовпцями з накопиченням. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Вертикальна стовпчаста діаграма з $count стовпцями з накопиченням та $lines лініями. ';
  }

  @override
  String get presenceAvailable => 'Доступний';

  @override
  String get presenceAway => 'Не на місці';

  @override
  String get presenceBusy => 'Зайнятий';

  @override
  String get presenceDoNotDisturb => 'Не турбувати';

  @override
  String get presenceBlocked => 'Заблоковано';

  @override
  String get presenceOffline => 'Не в мережі';

  @override
  String get presenceOutOfOffice => 'Не в офісі';

  @override
  String get presenceUnknown => 'Невідомо';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, не в офісі';
  }
}

/// The translations for Ukrainian, as used in Ukraine (`uk_UA`).
class FluentLocalizationsUkUa extends FluentLocalizationsUk {
  FluentLocalizationsUkUa() : super('uk_UA');

  @override
  String get close => 'Закрити';

  @override
  String get dismiss => 'Відхилити';

  @override
  String get clear => 'Очистити';

  @override
  String get open => 'Відкрити';

  @override
  String get remove => 'Видалити';

  @override
  String get more => 'Більше';

  @override
  String get overflowMore => 'ще';

  @override
  String get selectAllRows => 'Вибрати всі рядки';

  @override
  String get selectRow => 'Вибрати рядок';

  @override
  String get sort => 'Сортувати';

  @override
  String get sortedAscending => 'Відсортовано за зростанням';

  @override
  String get sortedDescending => 'Відсортовано за спаданням';

  @override
  String get previousSlide => 'Попередній слайд';

  @override
  String get nextSlide => 'Наступний слайд';

  @override
  String get startSlideShow => 'Запустити автоматичний показ слайдів';

  @override
  String get pauseSlideShow => 'Призупинити автоматичний показ слайдів';

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
  String get openCalendar => 'Відкрити календар';

  @override
  String get invalidDateFormat => 'Неправильний формат дати.';

  @override
  String get dateOutOfRange => 'Дата виходить за межі дозволеного діапазону.';

  @override
  String get fieldRequired => 'Це поле обов’язкове.';

  @override
  String get goToToday => 'Перейти до сьогоднішнього дня';

  @override
  String get previousMonth => 'Попередній місяць';

  @override
  String get nextMonth => 'Наступний місяць';

  @override
  String get previousYear => 'Попередній рік';

  @override
  String get nextYear => 'Наступний рік';

  @override
  String get previousYearRange => 'Попередній діапазон років';

  @override
  String get nextYearRange => 'Наступний діапазон років';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, змінити рік';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, змінити місяць';
  }

  @override
  String selectedDate(String date) {
    return 'Вибрана дата $date';
  }

  @override
  String todaysDate(String date) {
    return 'Сьогоднішня дата $date';
  }

  @override
  String weekNumber(String number) {
    return 'Тиждень $number';
  }

  @override
  String get chartNoData => 'Графік не має даних для відображення';

  @override
  String get chartNoDataAvailable => 'Немає доступних даних';

  @override
  String get chartFallbackTitle => 'Діаграма. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'Вісь $axis відображає $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y (додаткова)';

  @override
  String get chartAxisCategories => 'категорії';

  @override
  String get chartAxisTime => 'час';

  @override
  String get chartAxisValues => 'значення';

  @override
  String get chartLineLegendFallback => 'Лінія';

  @override
  String funnelChartDescription(int count) {
    return 'Лійкова діаграма з $count сегментами';
  }

  @override
  String donutChartDescription(int count) {
    return 'Кільцева діаграма з $count секторами';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Індикаторна діаграма з $count сегментами. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Поточне значення: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Поточне значення — $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Мінімальне значення: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Максимальне значення: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Невідомо';

  @override
  String ganttChartDescription(int count) {
    return 'Діаграма Ганта з $count точками даних. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Теплова карта з $count точками даних. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Полярна діаграма з $count рядами даних.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Спарклайн із міткою $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Діаграма Санкі з $nodes вузлами та $links зв’язками';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Від $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'вузол $name з вагою $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'зв’язок від $source до $target з вагою $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Вертикальна стовпчаста діаграма з $count стовпцями. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Вертикальна стовпчаста діаграма з $count стовпцями та 1 лінією. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Вертикальна стовпчаста діаграма з $count згрупованими рядами стовпців. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Вертикальна стовпчаста діаграма з $count згрупованими рядами стовпців і $lines рядами ліній. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Вертикальна стовпчаста діаграма з $count стовпцями з накопиченням. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Вертикальна стовпчаста діаграма з $count стовпцями з накопиченням та $lines лініями. ';
  }

  @override
  String get presenceAvailable => 'Доступний';

  @override
  String get presenceAway => 'Не на місці';

  @override
  String get presenceBusy => 'Зайнятий';

  @override
  String get presenceDoNotDisturb => 'Не турбувати';

  @override
  String get presenceBlocked => 'Заблоковано';

  @override
  String get presenceOffline => 'Не в мережі';

  @override
  String get presenceOutOfOffice => 'Не в офісі';

  @override
  String get presenceUnknown => 'Невідомо';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, не в офісі';
  }
}
