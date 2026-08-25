// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fluent_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class FluentLocalizationsPl extends FluentLocalizations {
  FluentLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get close => 'Zamknij';

  @override
  String get dismiss => 'Odrzuć';

  @override
  String get clear => 'Wyczyść';

  @override
  String get open => 'Otwórz';

  @override
  String get remove => 'Usuń';

  @override
  String get more => 'Więcej';

  @override
  String get overflowMore => 'więcej';

  @override
  String get selectAllRows => 'Zaznacz wszystkie wiersze';

  @override
  String get selectRow => 'Zaznacz wiersz';

  @override
  String get sort => 'Sortuj';

  @override
  String get sortedAscending => 'Posortowano rosnąco';

  @override
  String get sortedDescending => 'Posortowano malejąco';

  @override
  String get previousSlide => 'Poprzedni slajd';

  @override
  String get nextSlide => 'Następny slajd';

  @override
  String get startSlideShow => 'Rozpocznij automatyczny pokaz slajdów';

  @override
  String get pauseSlideShow => 'Wstrzymaj automatyczny pokaz slajdów';

  @override
  String slideOf(int index, int count) {
    return 'Slajd $index z $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Krok $index z $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value z $max';
  }

  @override
  String get openCalendar => 'Otwórz kalendarz';

  @override
  String get invalidDateFormat => 'Nieprawidłowy format daty.';

  @override
  String get dateOutOfRange => 'Data jest poza dozwolonym zakresem.';

  @override
  String get fieldRequired => 'To pole jest wymagane.';

  @override
  String get goToToday => 'Przejdź do dzisiaj';

  @override
  String get previousMonth => 'Poprzedni miesiąc';

  @override
  String get nextMonth => 'Następny miesiąc';

  @override
  String get previousYear => 'Poprzedni rok';

  @override
  String get nextYear => 'Następny rok';

  @override
  String get previousYearRange => 'Poprzedni zakres lat';

  @override
  String get nextYearRange => 'Następny zakres lat';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, zmień rok';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, zmień miesiąc';
  }

  @override
  String selectedDate(String date) {
    return 'Wybrana data $date';
  }

  @override
  String todaysDate(String date) {
    return 'Dzisiejsza data $date';
  }

  @override
  String weekNumber(String number) {
    return 'Tydzień $number';
  }

  @override
  String get chartNoData => 'Wykres nie ma danych do wyświetlenia';

  @override
  String get chartNoDataAvailable => 'Brak dostępnych danych';

  @override
  String get chartFallbackTitle => 'Wykres. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'Oś $axis przedstawia $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'pomocnicza Y';

  @override
  String get chartAxisCategories => 'kategorie';

  @override
  String get chartAxisTime => 'czas';

  @override
  String get chartAxisValues => 'wartości';

  @override
  String get chartLineLegendFallback => 'Linia';

  @override
  String funnelChartDescription(int count) {
    return 'Wykres lejkowy z $count segmentami';
  }

  @override
  String donutChartDescription(int count) {
    return 'Wykres pierścieniowy z $count wycinkami';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Wykres wskaźnikowy z $count segmentami. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Bieżąca wartość: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Bieżąca wartość to $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Wartość minimalna: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Wartość maksymalna: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Nieznane';

  @override
  String ganttChartDescription(int count) {
    return 'Wykres Gantta z $count punktami danych. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Mapa cieplna z $count punktami danych. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Wykres biegunowy z $count seriami danych.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Wykres przebiegu w czasie z etykietą $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Wykres Sankeya z $nodes węzłami i $links połączeniami';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Od $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'węzeł $name o wadze $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'połączenie od $source do $target o wadze $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Pionowy wykres słupkowy z $count słupkami. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Pionowy wykres słupkowy z $count słupkami i 1 linią. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Pionowy wykres słupkowy z $count grupowanymi seriami słupków. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Pionowy wykres słupkowy z $count grupowanymi seriami słupków i $lines seriami liniowymi. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Pionowy wykres słupkowy z $count skumulowanymi słupkami. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Pionowy wykres słupkowy z $count skumulowanymi słupkami i $lines liniami. ';
  }

  @override
  String get presenceAvailable => 'Dostępny';

  @override
  String get presenceAway => 'Nieobecny';

  @override
  String get presenceBusy => 'Zajęty';

  @override
  String get presenceDoNotDisturb => 'Nie przeszkadzać';

  @override
  String get presenceBlocked => 'Zablokowany';

  @override
  String get presenceOffline => 'Offline';

  @override
  String get presenceOutOfOffice => 'Poza biurem';

  @override
  String get presenceUnknown => 'Nieznany';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, poza biurem';
  }
}

/// The translations for Polish, as used in Poland (`pl_PL`).
class FluentLocalizationsPlPl extends FluentLocalizationsPl {
  FluentLocalizationsPlPl() : super('pl_PL');

  @override
  String get close => 'Zamknij';

  @override
  String get dismiss => 'Odrzuć';

  @override
  String get clear => 'Wyczyść';

  @override
  String get open => 'Otwórz';

  @override
  String get remove => 'Usuń';

  @override
  String get more => 'Więcej';

  @override
  String get overflowMore => 'więcej';

  @override
  String get selectAllRows => 'Zaznacz wszystkie wiersze';

  @override
  String get selectRow => 'Zaznacz wiersz';

  @override
  String get sort => 'Sortuj';

  @override
  String get sortedAscending => 'Posortowano rosnąco';

  @override
  String get sortedDescending => 'Posortowano malejąco';

  @override
  String get previousSlide => 'Poprzedni slajd';

  @override
  String get nextSlide => 'Następny slajd';

  @override
  String get startSlideShow => 'Rozpocznij automatyczny pokaz slajdów';

  @override
  String get pauseSlideShow => 'Wstrzymaj automatyczny pokaz slajdów';

  @override
  String slideOf(int index, int count) {
    return 'Slajd $index z $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Krok $index z $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value z $max';
  }

  @override
  String get openCalendar => 'Otwórz kalendarz';

  @override
  String get invalidDateFormat => 'Nieprawidłowy format daty.';

  @override
  String get dateOutOfRange => 'Data jest poza dozwolonym zakresem.';

  @override
  String get fieldRequired => 'To pole jest wymagane.';

  @override
  String get goToToday => 'Przejdź do dzisiaj';

  @override
  String get previousMonth => 'Poprzedni miesiąc';

  @override
  String get nextMonth => 'Następny miesiąc';

  @override
  String get previousYear => 'Poprzedni rok';

  @override
  String get nextYear => 'Następny rok';

  @override
  String get previousYearRange => 'Poprzedni zakres lat';

  @override
  String get nextYearRange => 'Następny zakres lat';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, zmień rok';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, zmień miesiąc';
  }

  @override
  String selectedDate(String date) {
    return 'Wybrana data $date';
  }

  @override
  String todaysDate(String date) {
    return 'Dzisiejsza data $date';
  }

  @override
  String weekNumber(String number) {
    return 'Tydzień $number';
  }

  @override
  String get chartNoData => 'Wykres nie ma danych do wyświetlenia';

  @override
  String get chartNoDataAvailable => 'Brak dostępnych danych';

  @override
  String get chartFallbackTitle => 'Wykres. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'Oś $axis przedstawia $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'pomocnicza Y';

  @override
  String get chartAxisCategories => 'kategorie';

  @override
  String get chartAxisTime => 'czas';

  @override
  String get chartAxisValues => 'wartości';

  @override
  String get chartLineLegendFallback => 'Linia';

  @override
  String funnelChartDescription(int count) {
    return 'Wykres lejkowy z $count segmentami';
  }

  @override
  String donutChartDescription(int count) {
    return 'Wykres pierścieniowy z $count wycinkami';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Wykres wskaźnikowy z $count segmentami. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Bieżąca wartość: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Bieżąca wartość to $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Wartość minimalna: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Wartość maksymalna: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Nieznane';

  @override
  String ganttChartDescription(int count) {
    return 'Wykres Gantta z $count punktami danych. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Mapa cieplna z $count punktami danych. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Wykres biegunowy z $count seriami danych.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Wykres przebiegu w czasie z etykietą $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Wykres Sankeya z $nodes węzłami i $links połączeniami';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Od $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'węzeł $name o wadze $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'połączenie od $source do $target o wadze $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Pionowy wykres słupkowy z $count słupkami. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Pionowy wykres słupkowy z $count słupkami i 1 linią. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Pionowy wykres słupkowy z $count grupowanymi seriami słupków. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Pionowy wykres słupkowy z $count grupowanymi seriami słupków i $lines seriami liniowymi. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Pionowy wykres słupkowy z $count skumulowanymi słupkami. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Pionowy wykres słupkowy z $count skumulowanymi słupkami i $lines liniami. ';
  }

  @override
  String get presenceAvailable => 'Dostępny';

  @override
  String get presenceAway => 'Nieobecny';

  @override
  String get presenceBusy => 'Zajęty';

  @override
  String get presenceDoNotDisturb => 'Nie przeszkadzać';

  @override
  String get presenceBlocked => 'Zablokowany';

  @override
  String get presenceOffline => 'Offline';

  @override
  String get presenceOutOfOffice => 'Poza biurem';

  @override
  String get presenceUnknown => 'Nieznany';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, poza biurem';
  }
}
