// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fluent_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class FluentLocalizationsRu extends FluentLocalizations {
  FluentLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get close => 'Закрыть';

  @override
  String get dismiss => 'Отклонить';

  @override
  String get clear => 'Очистить';

  @override
  String get open => 'Открыть';

  @override
  String get remove => 'Удалить';

  @override
  String get more => 'Дополнительно';

  @override
  String get overflowMore => 'ещё';

  @override
  String get selectAllRows => 'Выбрать все строки';

  @override
  String get selectRow => 'Выбрать строку';

  @override
  String get sort => 'Сортировка';

  @override
  String get sortedAscending => 'Отсортировано по возрастанию';

  @override
  String get sortedDescending => 'Отсортировано по убыванию';

  @override
  String get previousSlide => 'Предыдущий слайд';

  @override
  String get nextSlide => 'Следующий слайд';

  @override
  String get startSlideShow => 'Запустить автоматический показ слайдов';

  @override
  String get pauseSlideShow => 'Приостановить автоматический показ слайдов';

  @override
  String slideOf(int index, int count) {
    return 'Слайд $index из $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Шаг $index из $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value из $max';
  }

  @override
  String get openCalendar => 'Открыть календарь';

  @override
  String get invalidDateFormat => 'Недопустимый формат даты.';

  @override
  String get dateOutOfRange => 'Дата вне допустимого диапазона.';

  @override
  String get fieldRequired => 'Это поле обязательно для заполнения.';

  @override
  String get goToToday => 'Перейти к сегодняшнему дню';

  @override
  String get previousMonth => 'Предыдущий месяц';

  @override
  String get nextMonth => 'Следующий месяц';

  @override
  String get previousYear => 'Предыдущий год';

  @override
  String get nextYear => 'Следующий год';

  @override
  String get previousYearRange => 'Предыдущий диапазон лет';

  @override
  String get nextYearRange => 'Следующий диапазон лет';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, изменить год';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, изменить месяц';
  }

  @override
  String selectedDate(String date) {
    return 'Выбранная дата $date';
  }

  @override
  String todaysDate(String date) {
    return 'Сегодняшняя дата $date';
  }

  @override
  String weekNumber(String number) {
    return 'Неделя $number';
  }

  @override
  String get chartNoData => 'На графике нет данных для отображения';

  @override
  String get chartNoDataAvailable => 'Нет данных';

  @override
  String get chartFallbackTitle => 'Диаграмма. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'Ось $axis отображает $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y (вспомогательная)';

  @override
  String get chartAxisCategories => 'категории';

  @override
  String get chartAxisTime => 'время';

  @override
  String get chartAxisValues => 'значения';

  @override
  String get chartLineLegendFallback => 'Линия';

  @override
  String funnelChartDescription(int count) {
    return 'Воронкообразная диаграмма с $count сегментами';
  }

  @override
  String donutChartDescription(int count) {
    return 'Кольцевая диаграмма с $count секторами';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Диаграмма-индикатор с $count сегментами. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Текущее значение: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Текущее значение — $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Минимальное значение: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Максимальное значение: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Неизвестно';

  @override
  String ganttChartDescription(int count) {
    return 'Диаграмма Ганта с $count точками данных. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Тепловая карта с $count точками данных. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Полярная диаграмма с $count рядами данных.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Спарклайн с меткой $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Диаграмма Санкея с $nodes узлами и $links связями';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'От $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'узел $name с весом $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'связь от $source к $target с весом $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Гистограмма с $count столбцами. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Гистограмма с $count столбцами и 1 линией. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Гистограмма с $count рядами сгруппированных столбцов. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Гистограмма с $count рядами сгруппированных столбцов и $lines рядами линий. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Гистограмма с $count столбцами с накоплением. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Гистограмма с $count столбцами с накоплением и $lines линиями. ';
  }

  @override
  String get presenceAvailable => 'Свободен';

  @override
  String get presenceAway => 'Нет на месте';

  @override
  String get presenceBusy => 'Занят';

  @override
  String get presenceDoNotDisturb => 'Не беспокоить';

  @override
  String get presenceBlocked => 'Заблокировано';

  @override
  String get presenceOffline => 'Не в сети';

  @override
  String get presenceOutOfOffice => 'Нет на работе';

  @override
  String get presenceUnknown => 'Неизвестно';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, нет на работе';
  }
}

/// The translations for Russian, as used in Belarus (`ru_BY`).
class FluentLocalizationsRuBy extends FluentLocalizationsRu {
  FluentLocalizationsRuBy() : super('ru_BY');

  @override
  String get close => 'Закрыть';

  @override
  String get dismiss => 'Отклонить';

  @override
  String get clear => 'Очистить';

  @override
  String get open => 'Открыть';

  @override
  String get remove => 'Удалить';

  @override
  String get more => 'Дополнительно';

  @override
  String get overflowMore => 'ещё';

  @override
  String get selectAllRows => 'Выбрать все строки';

  @override
  String get selectRow => 'Выбрать строку';

  @override
  String get sort => 'Сортировка';

  @override
  String get sortedAscending => 'Отсортировано по возрастанию';

  @override
  String get sortedDescending => 'Отсортировано по убыванию';

  @override
  String get previousSlide => 'Предыдущий слайд';

  @override
  String get nextSlide => 'Следующий слайд';

  @override
  String get startSlideShow => 'Запустить автоматический показ слайдов';

  @override
  String get pauseSlideShow => 'Приостановить автоматический показ слайдов';

  @override
  String slideOf(int index, int count) {
    return 'Слайд $index из $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Шаг $index из $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value из $max';
  }

  @override
  String get openCalendar => 'Открыть календарь';

  @override
  String get invalidDateFormat => 'Недопустимый формат даты.';

  @override
  String get dateOutOfRange => 'Дата вне допустимого диапазона.';

  @override
  String get fieldRequired => 'Это поле обязательно для заполнения.';

  @override
  String get goToToday => 'Перейти к сегодняшнему дню';

  @override
  String get previousMonth => 'Предыдущий месяц';

  @override
  String get nextMonth => 'Следующий месяц';

  @override
  String get previousYear => 'Предыдущий год';

  @override
  String get nextYear => 'Следующий год';

  @override
  String get previousYearRange => 'Предыдущий диапазон лет';

  @override
  String get nextYearRange => 'Следующий диапазон лет';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, изменить год';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, изменить месяц';
  }

  @override
  String selectedDate(String date) {
    return 'Выбранная дата $date';
  }

  @override
  String todaysDate(String date) {
    return 'Сегодняшняя дата $date';
  }

  @override
  String weekNumber(String number) {
    return 'Неделя $number';
  }

  @override
  String get chartNoData => 'На графике нет данных для отображения';

  @override
  String get chartNoDataAvailable => 'Нет данных';

  @override
  String get chartFallbackTitle => 'Диаграмма. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'Ось $axis отображает $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y (вспомогательная)';

  @override
  String get chartAxisCategories => 'категории';

  @override
  String get chartAxisTime => 'время';

  @override
  String get chartAxisValues => 'значения';

  @override
  String get chartLineLegendFallback => 'Линия';

  @override
  String funnelChartDescription(int count) {
    return 'Воронкообразная диаграмма с $count сегментами';
  }

  @override
  String donutChartDescription(int count) {
    return 'Кольцевая диаграмма с $count секторами';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Диаграмма-индикатор с $count сегментами. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Текущее значение: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Текущее значение — $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Минимальное значение: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Максимальное значение: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Неизвестно';

  @override
  String ganttChartDescription(int count) {
    return 'Диаграмма Ганта с $count точками данных. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Тепловая карта с $count точками данных. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Полярная диаграмма с $count рядами данных.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Спарклайн с меткой $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Диаграмма Санкея с $nodes узлами и $links связями';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'От $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'узел $name с весом $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'связь от $source к $target с весом $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Гистограмма с $count столбцами. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Гистограмма с $count столбцами и 1 линией. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Гистограмма с $count рядами сгруппированных столбцов. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Гистограмма с $count рядами сгруппированных столбцов и $lines рядами линий. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Гистограмма с $count столбцами с накоплением. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Гистограмма с $count столбцами с накоплением и $lines линиями. ';
  }

  @override
  String get presenceAvailable => 'Свободен';

  @override
  String get presenceAway => 'Нет на месте';

  @override
  String get presenceBusy => 'Занят';

  @override
  String get presenceDoNotDisturb => 'Не беспокоить';

  @override
  String get presenceBlocked => 'Заблокировано';

  @override
  String get presenceOffline => 'Не в сети';

  @override
  String get presenceOutOfOffice => 'Нет на работе';

  @override
  String get presenceUnknown => 'Неизвестно';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, нет на работе';
  }
}

/// The translations for Russian, as used in Kyrgyzstan (`ru_KG`).
class FluentLocalizationsRuKg extends FluentLocalizationsRu {
  FluentLocalizationsRuKg() : super('ru_KG');

  @override
  String get close => 'Закрыть';

  @override
  String get dismiss => 'Отклонить';

  @override
  String get clear => 'Очистить';

  @override
  String get open => 'Открыть';

  @override
  String get remove => 'Удалить';

  @override
  String get more => 'Дополнительно';

  @override
  String get overflowMore => 'ещё';

  @override
  String get selectAllRows => 'Выбрать все строки';

  @override
  String get selectRow => 'Выбрать строку';

  @override
  String get sort => 'Сортировка';

  @override
  String get sortedAscending => 'Отсортировано по возрастанию';

  @override
  String get sortedDescending => 'Отсортировано по убыванию';

  @override
  String get previousSlide => 'Предыдущий слайд';

  @override
  String get nextSlide => 'Следующий слайд';

  @override
  String get startSlideShow => 'Запустить автоматический показ слайдов';

  @override
  String get pauseSlideShow => 'Приостановить автоматический показ слайдов';

  @override
  String slideOf(int index, int count) {
    return 'Слайд $index из $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Шаг $index из $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value из $max';
  }

  @override
  String get openCalendar => 'Открыть календарь';

  @override
  String get invalidDateFormat => 'Недопустимый формат даты.';

  @override
  String get dateOutOfRange => 'Дата вне допустимого диапазона.';

  @override
  String get fieldRequired => 'Это поле обязательно для заполнения.';

  @override
  String get goToToday => 'Перейти к сегодняшнему дню';

  @override
  String get previousMonth => 'Предыдущий месяц';

  @override
  String get nextMonth => 'Следующий месяц';

  @override
  String get previousYear => 'Предыдущий год';

  @override
  String get nextYear => 'Следующий год';

  @override
  String get previousYearRange => 'Предыдущий диапазон лет';

  @override
  String get nextYearRange => 'Следующий диапазон лет';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, изменить год';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, изменить месяц';
  }

  @override
  String selectedDate(String date) {
    return 'Выбранная дата $date';
  }

  @override
  String todaysDate(String date) {
    return 'Сегодняшняя дата $date';
  }

  @override
  String weekNumber(String number) {
    return 'Неделя $number';
  }

  @override
  String get chartNoData => 'На графике нет данных для отображения';

  @override
  String get chartNoDataAvailable => 'Нет данных';

  @override
  String get chartFallbackTitle => 'Диаграмма. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'Ось $axis отображает $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y (вспомогательная)';

  @override
  String get chartAxisCategories => 'категории';

  @override
  String get chartAxisTime => 'время';

  @override
  String get chartAxisValues => 'значения';

  @override
  String get chartLineLegendFallback => 'Линия';

  @override
  String funnelChartDescription(int count) {
    return 'Воронкообразная диаграмма с $count сегментами';
  }

  @override
  String donutChartDescription(int count) {
    return 'Кольцевая диаграмма с $count секторами';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Диаграмма-индикатор с $count сегментами. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Текущее значение: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Текущее значение — $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Минимальное значение: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Максимальное значение: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Неизвестно';

  @override
  String ganttChartDescription(int count) {
    return 'Диаграмма Ганта с $count точками данных. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Тепловая карта с $count точками данных. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Полярная диаграмма с $count рядами данных.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Спарклайн с меткой $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Диаграмма Санкея с $nodes узлами и $links связями';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'От $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'узел $name с весом $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'связь от $source к $target с весом $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Гистограмма с $count столбцами. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Гистограмма с $count столбцами и 1 линией. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Гистограмма с $count рядами сгруппированных столбцов. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Гистограмма с $count рядами сгруппированных столбцов и $lines рядами линий. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Гистограмма с $count столбцами с накоплением. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Гистограмма с $count столбцами с накоплением и $lines линиями. ';
  }

  @override
  String get presenceAvailable => 'Свободен';

  @override
  String get presenceAway => 'Нет на месте';

  @override
  String get presenceBusy => 'Занят';

  @override
  String get presenceDoNotDisturb => 'Не беспокоить';

  @override
  String get presenceBlocked => 'Заблокировано';

  @override
  String get presenceOffline => 'Не в сети';

  @override
  String get presenceOutOfOffice => 'Нет на работе';

  @override
  String get presenceUnknown => 'Неизвестно';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, нет на работе';
  }
}

/// The translations for Russian, as used in Kazakhstan (`ru_KZ`).
class FluentLocalizationsRuKz extends FluentLocalizationsRu {
  FluentLocalizationsRuKz() : super('ru_KZ');

  @override
  String get close => 'Закрыть';

  @override
  String get dismiss => 'Отклонить';

  @override
  String get clear => 'Очистить';

  @override
  String get open => 'Открыть';

  @override
  String get remove => 'Удалить';

  @override
  String get more => 'Дополнительно';

  @override
  String get overflowMore => 'ещё';

  @override
  String get selectAllRows => 'Выбрать все строки';

  @override
  String get selectRow => 'Выбрать строку';

  @override
  String get sort => 'Сортировка';

  @override
  String get sortedAscending => 'Отсортировано по возрастанию';

  @override
  String get sortedDescending => 'Отсортировано по убыванию';

  @override
  String get previousSlide => 'Предыдущий слайд';

  @override
  String get nextSlide => 'Следующий слайд';

  @override
  String get startSlideShow => 'Запустить автоматический показ слайдов';

  @override
  String get pauseSlideShow => 'Приостановить автоматический показ слайдов';

  @override
  String slideOf(int index, int count) {
    return 'Слайд $index из $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Шаг $index из $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value из $max';
  }

  @override
  String get openCalendar => 'Открыть календарь';

  @override
  String get invalidDateFormat => 'Недопустимый формат даты.';

  @override
  String get dateOutOfRange => 'Дата вне допустимого диапазона.';

  @override
  String get fieldRequired => 'Это поле обязательно для заполнения.';

  @override
  String get goToToday => 'Перейти к сегодняшнему дню';

  @override
  String get previousMonth => 'Предыдущий месяц';

  @override
  String get nextMonth => 'Следующий месяц';

  @override
  String get previousYear => 'Предыдущий год';

  @override
  String get nextYear => 'Следующий год';

  @override
  String get previousYearRange => 'Предыдущий диапазон лет';

  @override
  String get nextYearRange => 'Следующий диапазон лет';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, изменить год';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, изменить месяц';
  }

  @override
  String selectedDate(String date) {
    return 'Выбранная дата $date';
  }

  @override
  String todaysDate(String date) {
    return 'Сегодняшняя дата $date';
  }

  @override
  String weekNumber(String number) {
    return 'Неделя $number';
  }

  @override
  String get chartNoData => 'На графике нет данных для отображения';

  @override
  String get chartNoDataAvailable => 'Нет данных';

  @override
  String get chartFallbackTitle => 'Диаграмма. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'Ось $axis отображает $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y (вспомогательная)';

  @override
  String get chartAxisCategories => 'категории';

  @override
  String get chartAxisTime => 'время';

  @override
  String get chartAxisValues => 'значения';

  @override
  String get chartLineLegendFallback => 'Линия';

  @override
  String funnelChartDescription(int count) {
    return 'Воронкообразная диаграмма с $count сегментами';
  }

  @override
  String donutChartDescription(int count) {
    return 'Кольцевая диаграмма с $count секторами';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Диаграмма-индикатор с $count сегментами. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Текущее значение: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Текущее значение — $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Минимальное значение: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Максимальное значение: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Неизвестно';

  @override
  String ganttChartDescription(int count) {
    return 'Диаграмма Ганта с $count точками данных. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Тепловая карта с $count точками данных. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Полярная диаграмма с $count рядами данных.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Спарклайн с меткой $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Диаграмма Санкея с $nodes узлами и $links связями';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'От $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'узел $name с весом $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'связь от $source к $target с весом $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Гистограмма с $count столбцами. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Гистограмма с $count столбцами и 1 линией. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Гистограмма с $count рядами сгруппированных столбцов. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Гистограмма с $count рядами сгруппированных столбцов и $lines рядами линий. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Гистограмма с $count столбцами с накоплением. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Гистограмма с $count столбцами с накоплением и $lines линиями. ';
  }

  @override
  String get presenceAvailable => 'Свободен';

  @override
  String get presenceAway => 'Нет на месте';

  @override
  String get presenceBusy => 'Занят';

  @override
  String get presenceDoNotDisturb => 'Не беспокоить';

  @override
  String get presenceBlocked => 'Заблокировано';

  @override
  String get presenceOffline => 'Не в сети';

  @override
  String get presenceOutOfOffice => 'Нет на работе';

  @override
  String get presenceUnknown => 'Неизвестно';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, нет на работе';
  }
}

/// The translations for Russian, as used in Russian Federation (`ru_RU`).
class FluentLocalizationsRuRu extends FluentLocalizationsRu {
  FluentLocalizationsRuRu() : super('ru_RU');

  @override
  String get close => 'Закрыть';

  @override
  String get dismiss => 'Отклонить';

  @override
  String get clear => 'Очистить';

  @override
  String get open => 'Открыть';

  @override
  String get remove => 'Удалить';

  @override
  String get more => 'Дополнительно';

  @override
  String get overflowMore => 'ещё';

  @override
  String get selectAllRows => 'Выбрать все строки';

  @override
  String get selectRow => 'Выбрать строку';

  @override
  String get sort => 'Сортировка';

  @override
  String get sortedAscending => 'Отсортировано по возрастанию';

  @override
  String get sortedDescending => 'Отсортировано по убыванию';

  @override
  String get previousSlide => 'Предыдущий слайд';

  @override
  String get nextSlide => 'Следующий слайд';

  @override
  String get startSlideShow => 'Запустить автоматический показ слайдов';

  @override
  String get pauseSlideShow => 'Приостановить автоматический показ слайдов';

  @override
  String slideOf(int index, int count) {
    return 'Слайд $index из $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Шаг $index из $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value из $max';
  }

  @override
  String get openCalendar => 'Открыть календарь';

  @override
  String get invalidDateFormat => 'Недопустимый формат даты.';

  @override
  String get dateOutOfRange => 'Дата вне допустимого диапазона.';

  @override
  String get fieldRequired => 'Это поле обязательно для заполнения.';

  @override
  String get goToToday => 'Перейти к сегодняшнему дню';

  @override
  String get previousMonth => 'Предыдущий месяц';

  @override
  String get nextMonth => 'Следующий месяц';

  @override
  String get previousYear => 'Предыдущий год';

  @override
  String get nextYear => 'Следующий год';

  @override
  String get previousYearRange => 'Предыдущий диапазон лет';

  @override
  String get nextYearRange => 'Следующий диапазон лет';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, изменить год';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, изменить месяц';
  }

  @override
  String selectedDate(String date) {
    return 'Выбранная дата $date';
  }

  @override
  String todaysDate(String date) {
    return 'Сегодняшняя дата $date';
  }

  @override
  String weekNumber(String number) {
    return 'Неделя $number';
  }

  @override
  String get chartNoData => 'На графике нет данных для отображения';

  @override
  String get chartNoDataAvailable => 'Нет данных';

  @override
  String get chartFallbackTitle => 'Диаграмма. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'Ось $axis отображает $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y (вспомогательная)';

  @override
  String get chartAxisCategories => 'категории';

  @override
  String get chartAxisTime => 'время';

  @override
  String get chartAxisValues => 'значения';

  @override
  String get chartLineLegendFallback => 'Линия';

  @override
  String funnelChartDescription(int count) {
    return 'Воронкообразная диаграмма с $count сегментами';
  }

  @override
  String donutChartDescription(int count) {
    return 'Кольцевая диаграмма с $count секторами';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Диаграмма-индикатор с $count сегментами. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Текущее значение: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Текущее значение — $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Минимальное значение: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Максимальное значение: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Неизвестно';

  @override
  String ganttChartDescription(int count) {
    return 'Диаграмма Ганта с $count точками данных. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Тепловая карта с $count точками данных. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Полярная диаграмма с $count рядами данных.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Спарклайн с меткой $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Диаграмма Санкея с $nodes узлами и $links связями';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'От $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'узел $name с весом $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'связь от $source к $target с весом $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Гистограмма с $count столбцами. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Гистограмма с $count столбцами и 1 линией. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Гистограмма с $count рядами сгруппированных столбцов. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Гистограмма с $count рядами сгруппированных столбцов и $lines рядами линий. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Гистограмма с $count столбцами с накоплением. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Гистограмма с $count столбцами с накоплением и $lines линиями. ';
  }

  @override
  String get presenceAvailable => 'Свободен';

  @override
  String get presenceAway => 'Нет на месте';

  @override
  String get presenceBusy => 'Занят';

  @override
  String get presenceDoNotDisturb => 'Не беспокоить';

  @override
  String get presenceBlocked => 'Заблокировано';

  @override
  String get presenceOffline => 'Не в сети';

  @override
  String get presenceOutOfOffice => 'Нет на работе';

  @override
  String get presenceUnknown => 'Неизвестно';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, нет на работе';
  }
}
