// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fluent_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class FluentLocalizationsDe extends FluentLocalizations {
  FluentLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get close => 'Schließen';

  @override
  String get dismiss => 'Verwerfen';

  @override
  String get clear => 'Löschen';

  @override
  String get open => 'Öffnen';

  @override
  String get remove => 'Entfernen';

  @override
  String get more => 'Mehr';

  @override
  String get overflowMore => 'weitere';

  @override
  String get selectAllRows => 'Alle Zeilen auswählen';

  @override
  String get selectRow => 'Zeile auswählen';

  @override
  String get sort => 'Sortieren';

  @override
  String get sortedAscending => 'Aufsteigend sortiert';

  @override
  String get sortedDescending => 'Absteigend sortiert';

  @override
  String get previousSlide => 'Vorherige Folie';

  @override
  String get nextSlide => 'Nächste Folie';

  @override
  String get startSlideShow => 'Automatische Diashow starten';

  @override
  String get pauseSlideShow => 'Automatische Diashow anhalten';

  @override
  String slideOf(int index, int count) {
    return 'Folie $index von $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Schritt $index von $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value von $max';
  }

  @override
  String get openCalendar => 'Kalender öffnen';

  @override
  String get invalidDateFormat => 'Ungültiges Datumsformat.';

  @override
  String get dateOutOfRange =>
      'Das Datum liegt außerhalb des zulässigen Bereichs.';

  @override
  String get fieldRequired => 'Dieses Feld ist erforderlich.';

  @override
  String get goToToday => 'Zu heute wechseln';

  @override
  String get previousMonth => 'Vorheriger Monat';

  @override
  String get nextMonth => 'Nächster Monat';

  @override
  String get previousYear => 'Vorheriges Jahr';

  @override
  String get nextYear => 'Nächstes Jahr';

  @override
  String get previousYearRange => 'Vorheriger Jahresbereich';

  @override
  String get nextYearRange => 'Nächster Jahresbereich';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, Jahr ändern';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, Monat ändern';
  }

  @override
  String selectedDate(String date) {
    return 'Ausgewähltes Datum $date';
  }

  @override
  String todaysDate(String date) {
    return 'Heutiges Datum $date';
  }

  @override
  String weekNumber(String number) {
    return 'Woche $number';
  }

  @override
  String get chartNoData => 'Das Diagramm enthält keine Daten zur Anzeige';

  @override
  String get chartNoDataAvailable => 'Keine Daten verfügbar';

  @override
  String get chartFallbackTitle => 'Diagramm. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'Die $axis-Achse zeigt $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'sekundäre Y';

  @override
  String get chartAxisCategories => 'Kategorien';

  @override
  String get chartAxisTime => 'Zeit';

  @override
  String get chartAxisValues => 'Werte';

  @override
  String get chartLineLegendFallback => 'Linie';

  @override
  String funnelChartDescription(int count) {
    return 'Trichterdiagramm mit $count Segmenten';
  }

  @override
  String donutChartDescription(int count) {
    return 'Ringdiagramm mit $count Segmenten';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Messdiagramm mit $count Segmenten. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Aktueller Wert: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Der aktuelle Wert ist $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Minimalwert: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Maximalwert: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Unbekannt';

  @override
  String ganttChartDescription(int count) {
    return 'Gantt-Diagramm mit $count Datenpunkten. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Heatmap-Diagramm mit $count Datenpunkten. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Polardiagramm mit $count Datenreihen.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Sparkline mit Bezeichnung $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Sankey-Diagramm mit $nodes Knoten und $links Verbindungen';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Von $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'Knoten $name mit Gewichtung $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'Verbindung von $source nach $target mit Gewichtung $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Säulendiagramm mit $count Säulen. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Säulendiagramm mit $count Säulen und 1 Linie. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Säulendiagramm mit $count gruppierten Säulenreihen. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Säulendiagramm mit $count gruppierten Säulenreihen und $lines Linienreihen. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Säulendiagramm mit $count gestapelten Säulen. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Säulendiagramm mit $count gestapelten Säulen und $lines Linien. ';
  }

  @override
  String get presenceAvailable => 'Verfügbar';

  @override
  String get presenceAway => 'Abwesend';

  @override
  String get presenceBusy => 'Beschäftigt';

  @override
  String get presenceDoNotDisturb => 'Bitte nicht stören';

  @override
  String get presenceBlocked => 'Blockiert';

  @override
  String get presenceOffline => 'Offline';

  @override
  String get presenceOutOfOffice => 'Nicht im Büro';

  @override
  String get presenceUnknown => 'Unbekannt';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, nicht im Büro';
  }
}

/// The translations for German, as used in Austria (`de_AT`).
class FluentLocalizationsDeAt extends FluentLocalizationsDe {
  FluentLocalizationsDeAt() : super('de_AT');

  @override
  String get close => 'Schließen';

  @override
  String get dismiss => 'Verwerfen';

  @override
  String get clear => 'Löschen';

  @override
  String get open => 'Öffnen';

  @override
  String get remove => 'Entfernen';

  @override
  String get more => 'Mehr';

  @override
  String get overflowMore => 'weitere';

  @override
  String get selectAllRows => 'Alle Zeilen auswählen';

  @override
  String get selectRow => 'Zeile auswählen';

  @override
  String get sort => 'Sortieren';

  @override
  String get sortedAscending => 'Aufsteigend sortiert';

  @override
  String get sortedDescending => 'Absteigend sortiert';

  @override
  String get previousSlide => 'Vorherige Folie';

  @override
  String get nextSlide => 'Nächste Folie';

  @override
  String get startSlideShow => 'Automatische Diashow starten';

  @override
  String get pauseSlideShow => 'Automatische Diashow anhalten';

  @override
  String slideOf(int index, int count) {
    return 'Folie $index von $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Schritt $index von $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value von $max';
  }

  @override
  String get openCalendar => 'Kalender öffnen';

  @override
  String get invalidDateFormat => 'Ungültiges Datumsformat.';

  @override
  String get dateOutOfRange =>
      'Das Datum liegt außerhalb des zulässigen Bereichs.';

  @override
  String get fieldRequired => 'Dieses Feld ist erforderlich.';

  @override
  String get goToToday => 'Zu heute wechseln';

  @override
  String get previousMonth => 'Vorheriger Monat';

  @override
  String get nextMonth => 'Nächster Monat';

  @override
  String get previousYear => 'Vorheriges Jahr';

  @override
  String get nextYear => 'Nächstes Jahr';

  @override
  String get previousYearRange => 'Vorheriger Jahresbereich';

  @override
  String get nextYearRange => 'Nächster Jahresbereich';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, Jahr ändern';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, Monat ändern';
  }

  @override
  String selectedDate(String date) {
    return 'Ausgewähltes Datum $date';
  }

  @override
  String todaysDate(String date) {
    return 'Heutiges Datum $date';
  }

  @override
  String weekNumber(String number) {
    return 'Woche $number';
  }

  @override
  String get chartNoData => 'Das Diagramm enthält keine Daten zur Anzeige';

  @override
  String get chartNoDataAvailable => 'Keine Daten verfügbar';

  @override
  String get chartFallbackTitle => 'Diagramm. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'Die $axis-Achse zeigt $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'sekundäre Y';

  @override
  String get chartAxisCategories => 'Kategorien';

  @override
  String get chartAxisTime => 'Zeit';

  @override
  String get chartAxisValues => 'Werte';

  @override
  String get chartLineLegendFallback => 'Linie';

  @override
  String funnelChartDescription(int count) {
    return 'Trichterdiagramm mit $count Segmenten';
  }

  @override
  String donutChartDescription(int count) {
    return 'Ringdiagramm mit $count Segmenten';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Messdiagramm mit $count Segmenten. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Aktueller Wert: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Der aktuelle Wert ist $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Minimalwert: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Maximalwert: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Unbekannt';

  @override
  String ganttChartDescription(int count) {
    return 'Gantt-Diagramm mit $count Datenpunkten. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Heatmap-Diagramm mit $count Datenpunkten. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Polardiagramm mit $count Datenreihen.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Sparkline mit Bezeichnung $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Sankey-Diagramm mit $nodes Knoten und $links Verbindungen';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Von $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'Knoten $name mit Gewichtung $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'Verbindung von $source nach $target mit Gewichtung $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Säulendiagramm mit $count Säulen. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Säulendiagramm mit $count Säulen und 1 Linie. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Säulendiagramm mit $count gruppierten Säulenreihen. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Säulendiagramm mit $count gruppierten Säulenreihen und $lines Linienreihen. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Säulendiagramm mit $count gestapelten Säulen. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Säulendiagramm mit $count gestapelten Säulen und $lines Linien. ';
  }

  @override
  String get presenceAvailable => 'Verfügbar';

  @override
  String get presenceAway => 'Abwesend';

  @override
  String get presenceBusy => 'Beschäftigt';

  @override
  String get presenceDoNotDisturb => 'Bitte nicht stören';

  @override
  String get presenceBlocked => 'Blockiert';

  @override
  String get presenceOffline => 'Offline';

  @override
  String get presenceOutOfOffice => 'Nicht im Büro';

  @override
  String get presenceUnknown => 'Unbekannt';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, nicht im Büro';
  }
}

/// The translations for German, as used in Switzerland (`de_CH`).
class FluentLocalizationsDeCh extends FluentLocalizationsDe {
  FluentLocalizationsDeCh() : super('de_CH');

  @override
  String get close => 'Schliessen';

  @override
  String get dismiss => 'Verwerfen';

  @override
  String get clear => 'Löschen';

  @override
  String get open => 'Öffnen';

  @override
  String get remove => 'Entfernen';

  @override
  String get more => 'Mehr';

  @override
  String get overflowMore => 'weitere';

  @override
  String get selectAllRows => 'Alle Zeilen auswählen';

  @override
  String get selectRow => 'Zeile auswählen';

  @override
  String get sort => 'Sortieren';

  @override
  String get sortedAscending => 'Aufsteigend sortiert';

  @override
  String get sortedDescending => 'Absteigend sortiert';

  @override
  String get previousSlide => 'Vorherige Folie';

  @override
  String get nextSlide => 'Nächste Folie';

  @override
  String get startSlideShow => 'Automatische Diashow starten';

  @override
  String get pauseSlideShow => 'Automatische Diashow anhalten';

  @override
  String slideOf(int index, int count) {
    return 'Folie $index von $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Schritt $index von $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value von $max';
  }

  @override
  String get openCalendar => 'Kalender öffnen';

  @override
  String get invalidDateFormat => 'Ungültiges Datumsformat.';

  @override
  String get dateOutOfRange =>
      'Das Datum liegt ausserhalb des zulässigen Bereichs.';

  @override
  String get fieldRequired => 'Dieses Feld ist erforderlich.';

  @override
  String get goToToday => 'Zu heute wechseln';

  @override
  String get previousMonth => 'Vorheriger Monat';

  @override
  String get nextMonth => 'Nächster Monat';

  @override
  String get previousYear => 'Vorheriges Jahr';

  @override
  String get nextYear => 'Nächstes Jahr';

  @override
  String get previousYearRange => 'Vorheriger Jahresbereich';

  @override
  String get nextYearRange => 'Nächster Jahresbereich';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, Jahr ändern';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, Monat ändern';
  }

  @override
  String selectedDate(String date) {
    return 'Ausgewähltes Datum $date';
  }

  @override
  String todaysDate(String date) {
    return 'Heutiges Datum $date';
  }

  @override
  String weekNumber(String number) {
    return 'Woche $number';
  }

  @override
  String get chartNoData => 'Das Diagramm enthält keine Daten zur Anzeige';

  @override
  String get chartNoDataAvailable => 'Keine Daten verfügbar';

  @override
  String get chartFallbackTitle => 'Diagramm. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'Die $axis-Achse zeigt $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'sekundäre Y';

  @override
  String get chartAxisCategories => 'Kategorien';

  @override
  String get chartAxisTime => 'Zeit';

  @override
  String get chartAxisValues => 'Werte';

  @override
  String get chartLineLegendFallback => 'Linie';

  @override
  String funnelChartDescription(int count) {
    return 'Trichterdiagramm mit $count Segmenten';
  }

  @override
  String donutChartDescription(int count) {
    return 'Ringdiagramm mit $count Segmenten';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Messdiagramm mit $count Segmenten. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Aktueller Wert: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Der aktuelle Wert ist $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Minimalwert: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Maximalwert: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Unbekannt';

  @override
  String ganttChartDescription(int count) {
    return 'Gantt-Diagramm mit $count Datenpunkten. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Heatmap-Diagramm mit $count Datenpunkten. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Polardiagramm mit $count Datenreihen.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Sparkline mit Bezeichnung $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Sankey-Diagramm mit $nodes Knoten und $links Verbindungen';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Von $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'Knoten $name mit Gewichtung $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'Verbindung von $source nach $target mit Gewichtung $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Säulendiagramm mit $count Säulen. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Säulendiagramm mit $count Säulen und 1 Linie. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Säulendiagramm mit $count gruppierten Säulenreihen. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Säulendiagramm mit $count gruppierten Säulenreihen und $lines Linienreihen. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Säulendiagramm mit $count gestapelten Säulen. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Säulendiagramm mit $count gestapelten Säulen und $lines Linien. ';
  }

  @override
  String get presenceAvailable => 'Verfügbar';

  @override
  String get presenceAway => 'Abwesend';

  @override
  String get presenceBusy => 'Beschäftigt';

  @override
  String get presenceDoNotDisturb => 'Bitte nicht stören';

  @override
  String get presenceBlocked => 'Blockiert';

  @override
  String get presenceOffline => 'Offline';

  @override
  String get presenceOutOfOffice => 'Nicht im Büro';

  @override
  String get presenceUnknown => 'Unbekannt';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, nicht im Büro';
  }
}

/// The translations for German, as used in Germany (`de_DE`).
class FluentLocalizationsDeDe extends FluentLocalizationsDe {
  FluentLocalizationsDeDe() : super('de_DE');

  @override
  String get close => 'Schließen';

  @override
  String get dismiss => 'Verwerfen';

  @override
  String get clear => 'Löschen';

  @override
  String get open => 'Öffnen';

  @override
  String get remove => 'Entfernen';

  @override
  String get more => 'Mehr';

  @override
  String get overflowMore => 'weitere';

  @override
  String get selectAllRows => 'Alle Zeilen auswählen';

  @override
  String get selectRow => 'Zeile auswählen';

  @override
  String get sort => 'Sortieren';

  @override
  String get sortedAscending => 'Aufsteigend sortiert';

  @override
  String get sortedDescending => 'Absteigend sortiert';

  @override
  String get previousSlide => 'Vorherige Folie';

  @override
  String get nextSlide => 'Nächste Folie';

  @override
  String get startSlideShow => 'Automatische Diashow starten';

  @override
  String get pauseSlideShow => 'Automatische Diashow anhalten';

  @override
  String slideOf(int index, int count) {
    return 'Folie $index von $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Schritt $index von $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value von $max';
  }

  @override
  String get openCalendar => 'Kalender öffnen';

  @override
  String get invalidDateFormat => 'Ungültiges Datumsformat.';

  @override
  String get dateOutOfRange =>
      'Das Datum liegt außerhalb des zulässigen Bereichs.';

  @override
  String get fieldRequired => 'Dieses Feld ist erforderlich.';

  @override
  String get goToToday => 'Zu heute wechseln';

  @override
  String get previousMonth => 'Vorheriger Monat';

  @override
  String get nextMonth => 'Nächster Monat';

  @override
  String get previousYear => 'Vorheriges Jahr';

  @override
  String get nextYear => 'Nächstes Jahr';

  @override
  String get previousYearRange => 'Vorheriger Jahresbereich';

  @override
  String get nextYearRange => 'Nächster Jahresbereich';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, Jahr ändern';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, Monat ändern';
  }

  @override
  String selectedDate(String date) {
    return 'Ausgewähltes Datum $date';
  }

  @override
  String todaysDate(String date) {
    return 'Heutiges Datum $date';
  }

  @override
  String weekNumber(String number) {
    return 'Woche $number';
  }

  @override
  String get chartNoData => 'Das Diagramm enthält keine Daten zur Anzeige';

  @override
  String get chartNoDataAvailable => 'Keine Daten verfügbar';

  @override
  String get chartFallbackTitle => 'Diagramm. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'Die $axis-Achse zeigt $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'sekundäre Y';

  @override
  String get chartAxisCategories => 'Kategorien';

  @override
  String get chartAxisTime => 'Zeit';

  @override
  String get chartAxisValues => 'Werte';

  @override
  String get chartLineLegendFallback => 'Linie';

  @override
  String funnelChartDescription(int count) {
    return 'Trichterdiagramm mit $count Segmenten';
  }

  @override
  String donutChartDescription(int count) {
    return 'Ringdiagramm mit $count Segmenten';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Messdiagramm mit $count Segmenten. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Aktueller Wert: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Der aktuelle Wert ist $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Minimalwert: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Maximalwert: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Unbekannt';

  @override
  String ganttChartDescription(int count) {
    return 'Gantt-Diagramm mit $count Datenpunkten. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Heatmap-Diagramm mit $count Datenpunkten. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Polardiagramm mit $count Datenreihen.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Sparkline mit Bezeichnung $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Sankey-Diagramm mit $nodes Knoten und $links Verbindungen';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Von $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'Knoten $name mit Gewichtung $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'Verbindung von $source nach $target mit Gewichtung $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Säulendiagramm mit $count Säulen. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Säulendiagramm mit $count Säulen und 1 Linie. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Säulendiagramm mit $count gruppierten Säulenreihen. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Säulendiagramm mit $count gruppierten Säulenreihen und $lines Linienreihen. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Säulendiagramm mit $count gestapelten Säulen. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Säulendiagramm mit $count gestapelten Säulen und $lines Linien. ';
  }

  @override
  String get presenceAvailable => 'Verfügbar';

  @override
  String get presenceAway => 'Abwesend';

  @override
  String get presenceBusy => 'Beschäftigt';

  @override
  String get presenceDoNotDisturb => 'Bitte nicht stören';

  @override
  String get presenceBlocked => 'Blockiert';

  @override
  String get presenceOffline => 'Offline';

  @override
  String get presenceOutOfOffice => 'Nicht im Büro';

  @override
  String get presenceUnknown => 'Unbekannt';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, nicht im Büro';
  }
}

/// The translations for German, as used in Liechtenstein (`de_LI`).
class FluentLocalizationsDeLi extends FluentLocalizationsDe {
  FluentLocalizationsDeLi() : super('de_LI');

  @override
  String get close => 'Schliessen';

  @override
  String get dismiss => 'Verwerfen';

  @override
  String get clear => 'Löschen';

  @override
  String get open => 'Öffnen';

  @override
  String get remove => 'Entfernen';

  @override
  String get more => 'Mehr';

  @override
  String get overflowMore => 'weitere';

  @override
  String get selectAllRows => 'Alle Zeilen auswählen';

  @override
  String get selectRow => 'Zeile auswählen';

  @override
  String get sort => 'Sortieren';

  @override
  String get sortedAscending => 'Aufsteigend sortiert';

  @override
  String get sortedDescending => 'Absteigend sortiert';

  @override
  String get previousSlide => 'Vorherige Folie';

  @override
  String get nextSlide => 'Nächste Folie';

  @override
  String get startSlideShow => 'Automatische Diashow starten';

  @override
  String get pauseSlideShow => 'Automatische Diashow anhalten';

  @override
  String slideOf(int index, int count) {
    return 'Folie $index von $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Schritt $index von $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value von $max';
  }

  @override
  String get openCalendar => 'Kalender öffnen';

  @override
  String get invalidDateFormat => 'Ungültiges Datumsformat.';

  @override
  String get dateOutOfRange =>
      'Das Datum liegt ausserhalb des zulässigen Bereichs.';

  @override
  String get fieldRequired => 'Dieses Feld ist erforderlich.';

  @override
  String get goToToday => 'Zu heute wechseln';

  @override
  String get previousMonth => 'Vorheriger Monat';

  @override
  String get nextMonth => 'Nächster Monat';

  @override
  String get previousYear => 'Vorheriges Jahr';

  @override
  String get nextYear => 'Nächstes Jahr';

  @override
  String get previousYearRange => 'Vorheriger Jahresbereich';

  @override
  String get nextYearRange => 'Nächster Jahresbereich';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, Jahr ändern';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, Monat ändern';
  }

  @override
  String selectedDate(String date) {
    return 'Ausgewähltes Datum $date';
  }

  @override
  String todaysDate(String date) {
    return 'Heutiges Datum $date';
  }

  @override
  String weekNumber(String number) {
    return 'Woche $number';
  }

  @override
  String get chartNoData => 'Das Diagramm enthält keine Daten zur Anzeige';

  @override
  String get chartNoDataAvailable => 'Keine Daten verfügbar';

  @override
  String get chartFallbackTitle => 'Diagramm. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'Die $axis-Achse zeigt $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'sekundäre Y';

  @override
  String get chartAxisCategories => 'Kategorien';

  @override
  String get chartAxisTime => 'Zeit';

  @override
  String get chartAxisValues => 'Werte';

  @override
  String get chartLineLegendFallback => 'Linie';

  @override
  String funnelChartDescription(int count) {
    return 'Trichterdiagramm mit $count Segmenten';
  }

  @override
  String donutChartDescription(int count) {
    return 'Ringdiagramm mit $count Segmenten';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Messdiagramm mit $count Segmenten. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Aktueller Wert: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Der aktuelle Wert ist $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Minimalwert: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Maximalwert: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Unbekannt';

  @override
  String ganttChartDescription(int count) {
    return 'Gantt-Diagramm mit $count Datenpunkten. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Heatmap-Diagramm mit $count Datenpunkten. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Polardiagramm mit $count Datenreihen.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Sparkline mit Bezeichnung $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Sankey-Diagramm mit $nodes Knoten und $links Verbindungen';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Von $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'Knoten $name mit Gewichtung $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'Verbindung von $source nach $target mit Gewichtung $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Säulendiagramm mit $count Säulen. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Säulendiagramm mit $count Säulen und 1 Linie. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Säulendiagramm mit $count gruppierten Säulenreihen. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Säulendiagramm mit $count gruppierten Säulenreihen und $lines Linienreihen. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Säulendiagramm mit $count gestapelten Säulen. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Säulendiagramm mit $count gestapelten Säulen und $lines Linien. ';
  }

  @override
  String get presenceAvailable => 'Verfügbar';

  @override
  String get presenceAway => 'Abwesend';

  @override
  String get presenceBusy => 'Beschäftigt';

  @override
  String get presenceDoNotDisturb => 'Bitte nicht stören';

  @override
  String get presenceBlocked => 'Blockiert';

  @override
  String get presenceOffline => 'Offline';

  @override
  String get presenceOutOfOffice => 'Nicht im Büro';

  @override
  String get presenceUnknown => 'Unbekannt';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, nicht im Büro';
  }
}

/// The translations for German, as used in Luxembourg (`de_LU`).
class FluentLocalizationsDeLu extends FluentLocalizationsDe {
  FluentLocalizationsDeLu() : super('de_LU');

  @override
  String get close => 'Schließen';

  @override
  String get dismiss => 'Verwerfen';

  @override
  String get clear => 'Löschen';

  @override
  String get open => 'Öffnen';

  @override
  String get remove => 'Entfernen';

  @override
  String get more => 'Mehr';

  @override
  String get overflowMore => 'weitere';

  @override
  String get selectAllRows => 'Alle Zeilen auswählen';

  @override
  String get selectRow => 'Zeile auswählen';

  @override
  String get sort => 'Sortieren';

  @override
  String get sortedAscending => 'Aufsteigend sortiert';

  @override
  String get sortedDescending => 'Absteigend sortiert';

  @override
  String get previousSlide => 'Vorherige Folie';

  @override
  String get nextSlide => 'Nächste Folie';

  @override
  String get startSlideShow => 'Automatische Diashow starten';

  @override
  String get pauseSlideShow => 'Automatische Diashow anhalten';

  @override
  String slideOf(int index, int count) {
    return 'Folie $index von $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Schritt $index von $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value von $max';
  }

  @override
  String get openCalendar => 'Kalender öffnen';

  @override
  String get invalidDateFormat => 'Ungültiges Datumsformat.';

  @override
  String get dateOutOfRange =>
      'Das Datum liegt außerhalb des zulässigen Bereichs.';

  @override
  String get fieldRequired => 'Dieses Feld ist erforderlich.';

  @override
  String get goToToday => 'Zu heute wechseln';

  @override
  String get previousMonth => 'Vorheriger Monat';

  @override
  String get nextMonth => 'Nächster Monat';

  @override
  String get previousYear => 'Vorheriges Jahr';

  @override
  String get nextYear => 'Nächstes Jahr';

  @override
  String get previousYearRange => 'Vorheriger Jahresbereich';

  @override
  String get nextYearRange => 'Nächster Jahresbereich';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, Jahr ändern';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, Monat ändern';
  }

  @override
  String selectedDate(String date) {
    return 'Ausgewähltes Datum $date';
  }

  @override
  String todaysDate(String date) {
    return 'Heutiges Datum $date';
  }

  @override
  String weekNumber(String number) {
    return 'Woche $number';
  }

  @override
  String get chartNoData => 'Das Diagramm enthält keine Daten zur Anzeige';

  @override
  String get chartNoDataAvailable => 'Keine Daten verfügbar';

  @override
  String get chartFallbackTitle => 'Diagramm. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'Die $axis-Achse zeigt $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'sekundäre Y';

  @override
  String get chartAxisCategories => 'Kategorien';

  @override
  String get chartAxisTime => 'Zeit';

  @override
  String get chartAxisValues => 'Werte';

  @override
  String get chartLineLegendFallback => 'Linie';

  @override
  String funnelChartDescription(int count) {
    return 'Trichterdiagramm mit $count Segmenten';
  }

  @override
  String donutChartDescription(int count) {
    return 'Ringdiagramm mit $count Segmenten';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Messdiagramm mit $count Segmenten. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Aktueller Wert: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Der aktuelle Wert ist $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Minimalwert: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Maximalwert: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Unbekannt';

  @override
  String ganttChartDescription(int count) {
    return 'Gantt-Diagramm mit $count Datenpunkten. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Heatmap-Diagramm mit $count Datenpunkten. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Polardiagramm mit $count Datenreihen.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Sparkline mit Bezeichnung $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Sankey-Diagramm mit $nodes Knoten und $links Verbindungen';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Von $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'Knoten $name mit Gewichtung $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'Verbindung von $source nach $target mit Gewichtung $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Säulendiagramm mit $count Säulen. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Säulendiagramm mit $count Säulen und 1 Linie. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Säulendiagramm mit $count gruppierten Säulenreihen. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Säulendiagramm mit $count gruppierten Säulenreihen und $lines Linienreihen. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Säulendiagramm mit $count gestapelten Säulen. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Säulendiagramm mit $count gestapelten Säulen und $lines Linien. ';
  }

  @override
  String get presenceAvailable => 'Verfügbar';

  @override
  String get presenceAway => 'Abwesend';

  @override
  String get presenceBusy => 'Beschäftigt';

  @override
  String get presenceDoNotDisturb => 'Bitte nicht stören';

  @override
  String get presenceBlocked => 'Blockiert';

  @override
  String get presenceOffline => 'Offline';

  @override
  String get presenceOutOfOffice => 'Nicht im Büro';

  @override
  String get presenceUnknown => 'Unbekannt';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, nicht im Büro';
  }
}
