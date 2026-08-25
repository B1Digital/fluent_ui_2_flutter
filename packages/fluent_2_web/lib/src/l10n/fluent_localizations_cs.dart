// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fluent_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class FluentLocalizationsCs extends FluentLocalizations {
  FluentLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get close => 'Zavřít';

  @override
  String get dismiss => 'Zavřít';

  @override
  String get clear => 'Vymazat';

  @override
  String get open => 'Otevřít';

  @override
  String get remove => 'Odebrat';

  @override
  String get more => 'Více';

  @override
  String get overflowMore => 'další';

  @override
  String get selectAllRows => 'Vybrat všechny řádky';

  @override
  String get selectRow => 'Vybrat řádek';

  @override
  String get sort => 'Seřadit';

  @override
  String get sortedAscending => 'Seřazeno vzestupně';

  @override
  String get sortedDescending => 'Seřazeno sestupně';

  @override
  String get previousSlide => 'Předchozí snímek';

  @override
  String get nextSlide => 'Další snímek';

  @override
  String get startSlideShow => 'Spustit automatickou prezentaci';

  @override
  String get pauseSlideShow => 'Pozastavit automatickou prezentaci';

  @override
  String slideOf(int index, int count) {
    return 'Snímek $index z $count';
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
  String get openCalendar => 'Otevřít kalendář';

  @override
  String get invalidDateFormat => 'Neplatný formát data.';

  @override
  String get dateOutOfRange => 'Datum je mimo povolený rozsah.';

  @override
  String get fieldRequired => 'Toto pole je povinné.';

  @override
  String get goToToday => 'Přejít na dnešek';

  @override
  String get previousMonth => 'Předchozí měsíc';

  @override
  String get nextMonth => 'Další měsíc';

  @override
  String get previousYear => 'Předchozí rok';

  @override
  String get nextYear => 'Další rok';

  @override
  String get previousYearRange => 'Předchozí rozsah let';

  @override
  String get nextYearRange => 'Další rozsah let';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, změnit rok';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, změnit měsíc';
  }

  @override
  String selectedDate(String date) {
    return 'Vybrané datum $date';
  }

  @override
  String todaysDate(String date) {
    return 'Dnešní datum $date';
  }

  @override
  String weekNumber(String number) {
    return 'Týden $number';
  }

  @override
  String get chartNoData => 'Graf nemá žádná data k zobrazení';

  @override
  String get chartNoDataAvailable => 'Nejsou k dispozici žádná data';

  @override
  String get chartFallbackTitle => 'Graf. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'Osa $axis zobrazuje $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'sekundární Y';

  @override
  String get chartAxisCategories => 'kategorie';

  @override
  String get chartAxisTime => 'čas';

  @override
  String get chartAxisValues => 'hodnoty';

  @override
  String get chartLineLegendFallback => 'Čára';

  @override
  String funnelChartDescription(int count) {
    return 'Trychtýřový graf s $count segmenty';
  }

  @override
  String donutChartDescription(int count) {
    return 'Prstencový graf s $count výsečemi';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Měřicí graf s $count segmenty. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Aktuální hodnota: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Aktuální hodnota je $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Minimální hodnota: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Maximální hodnota: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Neznámé';

  @override
  String ganttChartDescription(int count) {
    return 'Ganttův diagram s $count datovými body. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Teplotní mapa s $count datovými body. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Polární graf s $count datovými řadami.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Minigraf s popiskem $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Sankeyův diagram s $nodes uzly a $links spojnicemi';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Z uzlu $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'uzel $name s váhou $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'spojnice z uzlu $source do uzlu $target s váhou $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Sloupcový graf s $count sloupci. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Sloupcový graf s $count sloupci a 1 čárou. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Sloupcový graf s $count seskupenými sloupcovými řadami. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Sloupcový graf s $count seskupenými sloupcovými řadami a $lines spojnicovými řadami. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Sloupcový graf s $count skládanými sloupci. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Sloupcový graf s $count skládanými sloupci a $lines čarami. ';
  }

  @override
  String get presenceAvailable => 'K dispozici';

  @override
  String get presenceAway => 'Pryč';

  @override
  String get presenceBusy => 'Zaneprázdněný';

  @override
  String get presenceDoNotDisturb => 'Nerušit';

  @override
  String get presenceBlocked => 'Blokováno';

  @override
  String get presenceOffline => 'Offline';

  @override
  String get presenceOutOfOffice => 'Mimo kancelář';

  @override
  String get presenceUnknown => 'Neznámý';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status mimo kancelář';
  }
}

/// The translations for Czech, as used in the Czechia Czech Republic (`cs_CZ`).
class FluentLocalizationsCsCz extends FluentLocalizationsCs {
  FluentLocalizationsCsCz() : super('cs_CZ');

  @override
  String get close => 'Zavřít';

  @override
  String get dismiss => 'Zavřít';

  @override
  String get clear => 'Vymazat';

  @override
  String get open => 'Otevřít';

  @override
  String get remove => 'Odebrat';

  @override
  String get more => 'Více';

  @override
  String get overflowMore => 'další';

  @override
  String get selectAllRows => 'Vybrat všechny řádky';

  @override
  String get selectRow => 'Vybrat řádek';

  @override
  String get sort => 'Seřadit';

  @override
  String get sortedAscending => 'Seřazeno vzestupně';

  @override
  String get sortedDescending => 'Seřazeno sestupně';

  @override
  String get previousSlide => 'Předchozí snímek';

  @override
  String get nextSlide => 'Další snímek';

  @override
  String get startSlideShow => 'Spustit automatickou prezentaci';

  @override
  String get pauseSlideShow => 'Pozastavit automatickou prezentaci';

  @override
  String slideOf(int index, int count) {
    return 'Snímek $index z $count';
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
  String get openCalendar => 'Otevřít kalendář';

  @override
  String get invalidDateFormat => 'Neplatný formát data.';

  @override
  String get dateOutOfRange => 'Datum je mimo povolený rozsah.';

  @override
  String get fieldRequired => 'Toto pole je povinné.';

  @override
  String get goToToday => 'Přejít na dnešek';

  @override
  String get previousMonth => 'Předchozí měsíc';

  @override
  String get nextMonth => 'Další měsíc';

  @override
  String get previousYear => 'Předchozí rok';

  @override
  String get nextYear => 'Další rok';

  @override
  String get previousYearRange => 'Předchozí rozsah let';

  @override
  String get nextYearRange => 'Další rozsah let';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, změnit rok';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, změnit měsíc';
  }

  @override
  String selectedDate(String date) {
    return 'Vybrané datum $date';
  }

  @override
  String todaysDate(String date) {
    return 'Dnešní datum $date';
  }

  @override
  String weekNumber(String number) {
    return 'Týden $number';
  }

  @override
  String get chartNoData => 'Graf nemá žádná data k zobrazení';

  @override
  String get chartNoDataAvailable => 'Nejsou k dispozici žádná data';

  @override
  String get chartFallbackTitle => 'Graf. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'Osa $axis zobrazuje $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'sekundární Y';

  @override
  String get chartAxisCategories => 'kategorie';

  @override
  String get chartAxisTime => 'čas';

  @override
  String get chartAxisValues => 'hodnoty';

  @override
  String get chartLineLegendFallback => 'Čára';

  @override
  String funnelChartDescription(int count) {
    return 'Trychtýřový graf s $count segmenty';
  }

  @override
  String donutChartDescription(int count) {
    return 'Prstencový graf s $count výsečemi';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Měřicí graf s $count segmenty. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Aktuální hodnota: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Aktuální hodnota je $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Minimální hodnota: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Maximální hodnota: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Neznámé';

  @override
  String ganttChartDescription(int count) {
    return 'Ganttův diagram s $count datovými body. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Teplotní mapa s $count datovými body. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Polární graf s $count datovými řadami.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Minigraf s popiskem $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Sankeyův diagram s $nodes uzly a $links spojnicemi';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Z uzlu $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'uzel $name s váhou $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'spojnice z uzlu $source do uzlu $target s váhou $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Sloupcový graf s $count sloupci. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Sloupcový graf s $count sloupci a 1 čárou. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Sloupcový graf s $count seskupenými sloupcovými řadami. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Sloupcový graf s $count seskupenými sloupcovými řadami a $lines spojnicovými řadami. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Sloupcový graf s $count skládanými sloupci. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Sloupcový graf s $count skládanými sloupci a $lines čarami. ';
  }

  @override
  String get presenceAvailable => 'K dispozici';

  @override
  String get presenceAway => 'Pryč';

  @override
  String get presenceBusy => 'Zaneprázdněný';

  @override
  String get presenceDoNotDisturb => 'Nerušit';

  @override
  String get presenceBlocked => 'Blokováno';

  @override
  String get presenceOffline => 'Offline';

  @override
  String get presenceOutOfOffice => 'Mimo kancelář';

  @override
  String get presenceUnknown => 'Neznámý';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status mimo kancelář';
  }
}
