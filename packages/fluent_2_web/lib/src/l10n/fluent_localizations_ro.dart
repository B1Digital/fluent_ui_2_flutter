// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fluent_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Romanian Moldavian Moldovan (`ro`).
class FluentLocalizationsRo extends FluentLocalizations {
  FluentLocalizationsRo([String locale = 'ro']) : super(locale);

  @override
  String get close => 'Închidere';

  @override
  String get dismiss => 'Ignorare';

  @override
  String get clear => 'Golire';

  @override
  String get open => 'Deschidere';

  @override
  String get remove => 'Eliminare';

  @override
  String get more => 'Mai multe';

  @override
  String get overflowMore => 'altele';

  @override
  String get selectAllRows => 'Selectare toate rândurile';

  @override
  String get selectRow => 'Selectare rând';

  @override
  String get sort => 'Sortare';

  @override
  String get sortedAscending => 'Sortat ascendent';

  @override
  String get sortedDescending => 'Sortat descendent';

  @override
  String get previousSlide => 'Diapozitivul anterior';

  @override
  String get nextSlide => 'Diapozitivul următor';

  @override
  String get startSlideShow => 'Pornire expunere automată de diapozitive';

  @override
  String get pauseSlideShow => 'Întrerupere expunere automată de diapozitive';

  @override
  String slideOf(int index, int count) {
    return 'Diapozitivul $index din $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Pasul $index din $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value din $max';
  }

  @override
  String get openCalendar => 'Deschidere calendar';

  @override
  String get invalidDateFormat => 'Format de dată nevalid.';

  @override
  String get dateOutOfRange => 'Data este în afara intervalului permis.';

  @override
  String get fieldRequired => 'Acest câmp este obligatoriu.';

  @override
  String get goToToday => 'Salt la ziua de azi';

  @override
  String get previousMonth => 'Luna anterioară';

  @override
  String get nextMonth => 'Luna următoare';

  @override
  String get previousYear => 'Anul anterior';

  @override
  String get nextYear => 'Anul următor';

  @override
  String get previousYearRange => 'Intervalul de ani anterior';

  @override
  String get nextYearRange => 'Intervalul de ani următor';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, modificare an';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, modificare lună';
  }

  @override
  String selectedDate(String date) {
    return 'Data selectată $date';
  }

  @override
  String todaysDate(String date) {
    return 'Data de azi $date';
  }

  @override
  String weekNumber(String number) {
    return 'Săptămâna $number';
  }

  @override
  String get chartNoData => 'Graficul nu are date de afișat';

  @override
  String get chartNoDataAvailable => 'Nu există date disponibile';

  @override
  String get chartFallbackTitle => 'Diagramă. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'Axa $axis afișează $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y secundară';

  @override
  String get chartAxisCategories => 'categorii';

  @override
  String get chartAxisTime => 'timpul';

  @override
  String get chartAxisValues => 'valori';

  @override
  String get chartLineLegendFallback => 'Linie';

  @override
  String funnelChartDescription(int count) {
    return 'Diagramă pâlnie cu $count segmente';
  }

  @override
  String donutChartDescription(int count) {
    return 'Diagramă inelară cu $count felii';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Diagramă indicator cu $count segmente. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Valoare curentă: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Valoarea curentă este $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Valoare minimă: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Valoare maximă: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Necunoscut';

  @override
  String ganttChartDescription(int count) {
    return 'Diagramă Gantt cu $count puncte de date. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Hartă termică cu $count puncte de date. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Diagramă polară cu $count serii de date.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Sparkline cu eticheta $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Diagramă Sankey cu $nodes noduri și $links legături';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'De la $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'nodul $name cu ponderea $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'legătură de la $source la $target cu ponderea $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Diagramă cu bare verticale având $count bare. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Diagramă cu bare verticale având $count bare și 1 linie. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Diagramă cu bare verticale având $count serii de bare grupate. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Diagramă cu bare verticale având $count serii de bare grupate și $lines serii de linii. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Diagramă cu bare verticale având $count bare stivuite. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Diagramă cu bare verticale având $count bare stivuite și $lines linii. ';
  }

  @override
  String get presenceAvailable => 'Disponibil';

  @override
  String get presenceAway => 'Plecat';

  @override
  String get presenceBusy => 'Ocupat';

  @override
  String get presenceDoNotDisturb => 'Nu deranjați';

  @override
  String get presenceBlocked => 'Blocat';

  @override
  String get presenceOffline => 'Offline';

  @override
  String get presenceOutOfOffice => 'În afara biroului';

  @override
  String get presenceUnknown => 'Necunoscut';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, în afara biroului';
  }
}

/// The translations for Romanian Moldavian Moldovan, as used in Moldova (`ro_MD`).
class FluentLocalizationsRoMd extends FluentLocalizationsRo {
  FluentLocalizationsRoMd() : super('ro_MD');

  @override
  String get close => 'Închidere';

  @override
  String get dismiss => 'Ignorare';

  @override
  String get clear => 'Golire';

  @override
  String get open => 'Deschidere';

  @override
  String get remove => 'Eliminare';

  @override
  String get more => 'Mai multe';

  @override
  String get overflowMore => 'altele';

  @override
  String get selectAllRows => 'Selectare toate rândurile';

  @override
  String get selectRow => 'Selectare rând';

  @override
  String get sort => 'Sortare';

  @override
  String get sortedAscending => 'Sortat ascendent';

  @override
  String get sortedDescending => 'Sortat descendent';

  @override
  String get previousSlide => 'Diapozitivul anterior';

  @override
  String get nextSlide => 'Diapozitivul următor';

  @override
  String get startSlideShow => 'Pornire expunere automată de diapozitive';

  @override
  String get pauseSlideShow => 'Întrerupere expunere automată de diapozitive';

  @override
  String slideOf(int index, int count) {
    return 'Diapozitivul $index din $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Pasul $index din $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value din $max';
  }

  @override
  String get openCalendar => 'Deschidere calendar';

  @override
  String get invalidDateFormat => 'Format de dată nevalid.';

  @override
  String get dateOutOfRange => 'Data este în afara intervalului permis.';

  @override
  String get fieldRequired => 'Acest câmp este obligatoriu.';

  @override
  String get goToToday => 'Salt la ziua de azi';

  @override
  String get previousMonth => 'Luna anterioară';

  @override
  String get nextMonth => 'Luna următoare';

  @override
  String get previousYear => 'Anul anterior';

  @override
  String get nextYear => 'Anul următor';

  @override
  String get previousYearRange => 'Intervalul de ani anterior';

  @override
  String get nextYearRange => 'Intervalul de ani următor';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, modificare an';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, modificare lună';
  }

  @override
  String selectedDate(String date) {
    return 'Data selectată $date';
  }

  @override
  String todaysDate(String date) {
    return 'Data de azi $date';
  }

  @override
  String weekNumber(String number) {
    return 'Săptămâna $number';
  }

  @override
  String get chartNoData => 'Graficul nu are date de afișat';

  @override
  String get chartNoDataAvailable => 'Nu există date disponibile';

  @override
  String get chartFallbackTitle => 'Diagramă. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'Axa $axis afișează $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y secundară';

  @override
  String get chartAxisCategories => 'categorii';

  @override
  String get chartAxisTime => 'timpul';

  @override
  String get chartAxisValues => 'valori';

  @override
  String get chartLineLegendFallback => 'Linie';

  @override
  String funnelChartDescription(int count) {
    return 'Diagramă pâlnie cu $count segmente';
  }

  @override
  String donutChartDescription(int count) {
    return 'Diagramă inelară cu $count felii';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Diagramă indicator cu $count segmente. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Valoare curentă: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Valoarea curentă este $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Valoare minimă: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Valoare maximă: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Necunoscut';

  @override
  String ganttChartDescription(int count) {
    return 'Diagramă Gantt cu $count puncte de date. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Hartă termică cu $count puncte de date. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Diagramă polară cu $count serii de date.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Sparkline cu eticheta $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Diagramă Sankey cu $nodes noduri și $links legături';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'De la $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'nodul $name cu ponderea $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'legătură de la $source la $target cu ponderea $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Diagramă cu bare verticale având $count bare. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Diagramă cu bare verticale având $count bare și 1 linie. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Diagramă cu bare verticale având $count serii de bare grupate. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Diagramă cu bare verticale având $count serii de bare grupate și $lines serii de linii. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Diagramă cu bare verticale având $count bare stivuite. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Diagramă cu bare verticale având $count bare stivuite și $lines linii. ';
  }

  @override
  String get presenceAvailable => 'Disponibil';

  @override
  String get presenceAway => 'Plecat';

  @override
  String get presenceBusy => 'Ocupat';

  @override
  String get presenceDoNotDisturb => 'Nu deranjați';

  @override
  String get presenceBlocked => 'Blocat';

  @override
  String get presenceOffline => 'Offline';

  @override
  String get presenceOutOfOffice => 'În afara biroului';

  @override
  String get presenceUnknown => 'Necunoscut';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, în afara biroului';
  }
}

/// The translations for Romanian Moldavian Moldovan, as used in Romania (`ro_RO`).
class FluentLocalizationsRoRo extends FluentLocalizationsRo {
  FluentLocalizationsRoRo() : super('ro_RO');

  @override
  String get close => 'Închidere';

  @override
  String get dismiss => 'Ignorare';

  @override
  String get clear => 'Golire';

  @override
  String get open => 'Deschidere';

  @override
  String get remove => 'Eliminare';

  @override
  String get more => 'Mai multe';

  @override
  String get overflowMore => 'altele';

  @override
  String get selectAllRows => 'Selectare toate rândurile';

  @override
  String get selectRow => 'Selectare rând';

  @override
  String get sort => 'Sortare';

  @override
  String get sortedAscending => 'Sortat ascendent';

  @override
  String get sortedDescending => 'Sortat descendent';

  @override
  String get previousSlide => 'Diapozitivul anterior';

  @override
  String get nextSlide => 'Diapozitivul următor';

  @override
  String get startSlideShow => 'Pornire expunere automată de diapozitive';

  @override
  String get pauseSlideShow => 'Întrerupere expunere automată de diapozitive';

  @override
  String slideOf(int index, int count) {
    return 'Diapozitivul $index din $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Pasul $index din $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value din $max';
  }

  @override
  String get openCalendar => 'Deschidere calendar';

  @override
  String get invalidDateFormat => 'Format de dată nevalid.';

  @override
  String get dateOutOfRange => 'Data este în afara intervalului permis.';

  @override
  String get fieldRequired => 'Acest câmp este obligatoriu.';

  @override
  String get goToToday => 'Salt la ziua de azi';

  @override
  String get previousMonth => 'Luna anterioară';

  @override
  String get nextMonth => 'Luna următoare';

  @override
  String get previousYear => 'Anul anterior';

  @override
  String get nextYear => 'Anul următor';

  @override
  String get previousYearRange => 'Intervalul de ani anterior';

  @override
  String get nextYearRange => 'Intervalul de ani următor';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, modificare an';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, modificare lună';
  }

  @override
  String selectedDate(String date) {
    return 'Data selectată $date';
  }

  @override
  String todaysDate(String date) {
    return 'Data de azi $date';
  }

  @override
  String weekNumber(String number) {
    return 'Săptămâna $number';
  }

  @override
  String get chartNoData => 'Graficul nu are date de afișat';

  @override
  String get chartNoDataAvailable => 'Nu există date disponibile';

  @override
  String get chartFallbackTitle => 'Diagramă. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'Axa $axis afișează $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y secundară';

  @override
  String get chartAxisCategories => 'categorii';

  @override
  String get chartAxisTime => 'timpul';

  @override
  String get chartAxisValues => 'valori';

  @override
  String get chartLineLegendFallback => 'Linie';

  @override
  String funnelChartDescription(int count) {
    return 'Diagramă pâlnie cu $count segmente';
  }

  @override
  String donutChartDescription(int count) {
    return 'Diagramă inelară cu $count felii';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Diagramă indicator cu $count segmente. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Valoare curentă: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Valoarea curentă este $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Valoare minimă: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Valoare maximă: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Necunoscut';

  @override
  String ganttChartDescription(int count) {
    return 'Diagramă Gantt cu $count puncte de date. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Hartă termică cu $count puncte de date. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Diagramă polară cu $count serii de date.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Sparkline cu eticheta $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Diagramă Sankey cu $nodes noduri și $links legături';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'De la $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'nodul $name cu ponderea $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'legătură de la $source la $target cu ponderea $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Diagramă cu bare verticale având $count bare. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Diagramă cu bare verticale având $count bare și 1 linie. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Diagramă cu bare verticale având $count serii de bare grupate. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Diagramă cu bare verticale având $count serii de bare grupate și $lines serii de linii. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Diagramă cu bare verticale având $count bare stivuite. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Diagramă cu bare verticale având $count bare stivuite și $lines linii. ';
  }

  @override
  String get presenceAvailable => 'Disponibil';

  @override
  String get presenceAway => 'Plecat';

  @override
  String get presenceBusy => 'Ocupat';

  @override
  String get presenceDoNotDisturb => 'Nu deranjați';

  @override
  String get presenceBlocked => 'Blocat';

  @override
  String get presenceOffline => 'Offline';

  @override
  String get presenceOutOfOffice => 'În afara biroului';

  @override
  String get presenceUnknown => 'Necunoscut';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, în afara biroului';
  }
}
