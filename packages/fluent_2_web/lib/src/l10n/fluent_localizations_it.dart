// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fluent_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class FluentLocalizationsIt extends FluentLocalizations {
  FluentLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get close => 'Chiudi';

  @override
  String get dismiss => 'Ignora';

  @override
  String get clear => 'Cancella';

  @override
  String get open => 'Apri';

  @override
  String get remove => 'Rimuovi';

  @override
  String get more => 'Altro';

  @override
  String get overflowMore => 'altri';

  @override
  String get selectAllRows => 'Seleziona tutte le righe';

  @override
  String get selectRow => 'Seleziona riga';

  @override
  String get sort => 'Ordina';

  @override
  String get sortedAscending => 'Ordinamento crescente';

  @override
  String get sortedDescending => 'Ordinamento decrescente';

  @override
  String get previousSlide => 'Diapositiva precedente';

  @override
  String get nextSlide => 'Diapositiva successiva';

  @override
  String get startSlideShow => 'Avvia presentazione automatica';

  @override
  String get pauseSlideShow => 'Sospendi presentazione automatica';

  @override
  String slideOf(int index, int count) {
    return 'Diapositiva $index di $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Passaggio $index di $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value di $max';
  }

  @override
  String get openCalendar => 'Apri calendario';

  @override
  String get invalidDateFormat => 'Formato data non valido.';

  @override
  String get dateOutOfRange =>
      'La data non rientra nell\'intervallo consentito.';

  @override
  String get fieldRequired => 'Questo campo è obbligatorio.';

  @override
  String get goToToday => 'Vai a oggi';

  @override
  String get previousMonth => 'Mese precedente';

  @override
  String get nextMonth => 'Mese successivo';

  @override
  String get previousYear => 'Anno precedente';

  @override
  String get nextYear => 'Anno successivo';

  @override
  String get previousYearRange => 'Intervallo di anni precedente';

  @override
  String get nextYearRange => 'Intervallo di anni successivo';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, cambia anno';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, cambia mese';
  }

  @override
  String selectedDate(String date) {
    return 'Data selezionata $date';
  }

  @override
  String todaysDate(String date) {
    return 'Data odierna $date';
  }

  @override
  String weekNumber(String number) {
    return 'Settimana $number';
  }

  @override
  String get chartNoData => 'Il grafico non contiene dati da visualizzare';

  @override
  String get chartNoDataAvailable => 'Nessun dato disponibile';

  @override
  String get chartFallbackTitle => 'Grafico. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'L\'asse $axis visualizza $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y secondario';

  @override
  String get chartAxisCategories => 'categorie';

  @override
  String get chartAxisTime => 'tempo';

  @override
  String get chartAxisValues => 'valori';

  @override
  String get chartLineLegendFallback => 'Linea';

  @override
  String funnelChartDescription(int count) {
    return 'Grafico a imbuto con $count segmenti';
  }

  @override
  String donutChartDescription(int count) {
    return 'Grafico a ciambella con $count sezioni';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Grafico a indicatore con $count segmenti. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Valore corrente: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Il valore corrente è $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Valore minimo: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Valore massimo: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Sconosciuto';

  @override
  String ganttChartDescription(int count) {
    return 'Grafico Gantt con $count punti dati. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Grafico mappa termica con $count punti dati. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Grafico polare con $count serie di dati.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Sparkline con etichetta $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Grafico Sankey con $nodes nodi e $links collegamenti';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Da $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'nodo $name con peso $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'collegamento da $source a $target con peso $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Grafico a barre verticali con $count barre. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Grafico a barre verticali con $count barre e 1 linea. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Grafico a barre verticali con $count serie di barre raggruppate. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Grafico a barre verticali con $count serie di barre raggruppate e $lines serie di linee. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Grafico a barre verticali con $count barre in pila. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Grafico a barre verticali con $count barre in pila e $lines linee. ';
  }

  @override
  String get presenceAvailable => 'Disponibile';

  @override
  String get presenceAway => 'Assente';

  @override
  String get presenceBusy => 'Occupato';

  @override
  String get presenceDoNotDisturb => 'Non disturbare';

  @override
  String get presenceBlocked => 'Bloccato';

  @override
  String get presenceOffline => 'Non in linea';

  @override
  String get presenceOutOfOffice => 'Fuori sede';

  @override
  String get presenceUnknown => 'Sconosciuto';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status fuori sede';
  }
}

/// The translations for Italian, as used in Switzerland (`it_CH`).
class FluentLocalizationsItCh extends FluentLocalizationsIt {
  FluentLocalizationsItCh() : super('it_CH');

  @override
  String get close => 'Chiudi';

  @override
  String get dismiss => 'Ignora';

  @override
  String get clear => 'Cancella';

  @override
  String get open => 'Apri';

  @override
  String get remove => 'Rimuovi';

  @override
  String get more => 'Altro';

  @override
  String get overflowMore => 'altri';

  @override
  String get selectAllRows => 'Seleziona tutte le righe';

  @override
  String get selectRow => 'Seleziona riga';

  @override
  String get sort => 'Ordina';

  @override
  String get sortedAscending => 'Ordinamento crescente';

  @override
  String get sortedDescending => 'Ordinamento decrescente';

  @override
  String get previousSlide => 'Diapositiva precedente';

  @override
  String get nextSlide => 'Diapositiva successiva';

  @override
  String get startSlideShow => 'Avvia presentazione automatica';

  @override
  String get pauseSlideShow => 'Sospendi presentazione automatica';

  @override
  String slideOf(int index, int count) {
    return 'Diapositiva $index di $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Passaggio $index di $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value di $max';
  }

  @override
  String get openCalendar => 'Apri calendario';

  @override
  String get invalidDateFormat => 'Formato data non valido.';

  @override
  String get dateOutOfRange =>
      'La data non rientra nell\'intervallo consentito.';

  @override
  String get fieldRequired => 'Questo campo è obbligatorio.';

  @override
  String get goToToday => 'Vai a oggi';

  @override
  String get previousMonth => 'Mese precedente';

  @override
  String get nextMonth => 'Mese successivo';

  @override
  String get previousYear => 'Anno precedente';

  @override
  String get nextYear => 'Anno successivo';

  @override
  String get previousYearRange => 'Intervallo di anni precedente';

  @override
  String get nextYearRange => 'Intervallo di anni successivo';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, cambia anno';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, cambia mese';
  }

  @override
  String selectedDate(String date) {
    return 'Data selezionata $date';
  }

  @override
  String todaysDate(String date) {
    return 'Data odierna $date';
  }

  @override
  String weekNumber(String number) {
    return 'Settimana $number';
  }

  @override
  String get chartNoData => 'Il grafico non contiene dati da visualizzare';

  @override
  String get chartNoDataAvailable => 'Nessun dato disponibile';

  @override
  String get chartFallbackTitle => 'Grafico. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'L\'asse $axis visualizza $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y secondario';

  @override
  String get chartAxisCategories => 'categorie';

  @override
  String get chartAxisTime => 'tempo';

  @override
  String get chartAxisValues => 'valori';

  @override
  String get chartLineLegendFallback => 'Linea';

  @override
  String funnelChartDescription(int count) {
    return 'Grafico a imbuto con $count segmenti';
  }

  @override
  String donutChartDescription(int count) {
    return 'Grafico a ciambella con $count sezioni';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Grafico a indicatore con $count segmenti. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Valore corrente: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Il valore corrente è $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Valore minimo: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Valore massimo: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Sconosciuto';

  @override
  String ganttChartDescription(int count) {
    return 'Grafico Gantt con $count punti dati. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Grafico mappa termica con $count punti dati. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Grafico polare con $count serie di dati.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Sparkline con etichetta $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Grafico Sankey con $nodes nodi e $links collegamenti';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Da $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'nodo $name con peso $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'collegamento da $source a $target con peso $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Grafico a barre verticali con $count barre. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Grafico a barre verticali con $count barre e 1 linea. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Grafico a barre verticali con $count serie di barre raggruppate. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Grafico a barre verticali con $count serie di barre raggruppate e $lines serie di linee. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Grafico a barre verticali con $count barre in pila. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Grafico a barre verticali con $count barre in pila e $lines linee. ';
  }

  @override
  String get presenceAvailable => 'Disponibile';

  @override
  String get presenceAway => 'Assente';

  @override
  String get presenceBusy => 'Occupato';

  @override
  String get presenceDoNotDisturb => 'Non disturbare';

  @override
  String get presenceBlocked => 'Bloccato';

  @override
  String get presenceOffline => 'Non in linea';

  @override
  String get presenceOutOfOffice => 'Fuori sede';

  @override
  String get presenceUnknown => 'Sconosciuto';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status fuori sede';
  }
}

/// The translations for Italian, as used in Italy (`it_IT`).
class FluentLocalizationsItIt extends FluentLocalizationsIt {
  FluentLocalizationsItIt() : super('it_IT');

  @override
  String get close => 'Chiudi';

  @override
  String get dismiss => 'Ignora';

  @override
  String get clear => 'Cancella';

  @override
  String get open => 'Apri';

  @override
  String get remove => 'Rimuovi';

  @override
  String get more => 'Altro';

  @override
  String get overflowMore => 'altri';

  @override
  String get selectAllRows => 'Seleziona tutte le righe';

  @override
  String get selectRow => 'Seleziona riga';

  @override
  String get sort => 'Ordina';

  @override
  String get sortedAscending => 'Ordinamento crescente';

  @override
  String get sortedDescending => 'Ordinamento decrescente';

  @override
  String get previousSlide => 'Diapositiva precedente';

  @override
  String get nextSlide => 'Diapositiva successiva';

  @override
  String get startSlideShow => 'Avvia presentazione automatica';

  @override
  String get pauseSlideShow => 'Sospendi presentazione automatica';

  @override
  String slideOf(int index, int count) {
    return 'Diapositiva $index di $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Passaggio $index di $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value di $max';
  }

  @override
  String get openCalendar => 'Apri calendario';

  @override
  String get invalidDateFormat => 'Formato data non valido.';

  @override
  String get dateOutOfRange =>
      'La data non rientra nell\'intervallo consentito.';

  @override
  String get fieldRequired => 'Questo campo è obbligatorio.';

  @override
  String get goToToday => 'Vai a oggi';

  @override
  String get previousMonth => 'Mese precedente';

  @override
  String get nextMonth => 'Mese successivo';

  @override
  String get previousYear => 'Anno precedente';

  @override
  String get nextYear => 'Anno successivo';

  @override
  String get previousYearRange => 'Intervallo di anni precedente';

  @override
  String get nextYearRange => 'Intervallo di anni successivo';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, cambia anno';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, cambia mese';
  }

  @override
  String selectedDate(String date) {
    return 'Data selezionata $date';
  }

  @override
  String todaysDate(String date) {
    return 'Data odierna $date';
  }

  @override
  String weekNumber(String number) {
    return 'Settimana $number';
  }

  @override
  String get chartNoData => 'Il grafico non contiene dati da visualizzare';

  @override
  String get chartNoDataAvailable => 'Nessun dato disponibile';

  @override
  String get chartFallbackTitle => 'Grafico. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'L\'asse $axis visualizza $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y secondario';

  @override
  String get chartAxisCategories => 'categorie';

  @override
  String get chartAxisTime => 'tempo';

  @override
  String get chartAxisValues => 'valori';

  @override
  String get chartLineLegendFallback => 'Linea';

  @override
  String funnelChartDescription(int count) {
    return 'Grafico a imbuto con $count segmenti';
  }

  @override
  String donutChartDescription(int count) {
    return 'Grafico a ciambella con $count sezioni';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Grafico a indicatore con $count segmenti. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Valore corrente: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Il valore corrente è $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Valore minimo: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Valore massimo: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Sconosciuto';

  @override
  String ganttChartDescription(int count) {
    return 'Grafico Gantt con $count punti dati. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Grafico mappa termica con $count punti dati. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Grafico polare con $count serie di dati.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Sparkline con etichetta $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Grafico Sankey con $nodes nodi e $links collegamenti';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Da $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'nodo $name con peso $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'collegamento da $source a $target con peso $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Grafico a barre verticali con $count barre. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Grafico a barre verticali con $count barre e 1 linea. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Grafico a barre verticali con $count serie di barre raggruppate. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Grafico a barre verticali con $count serie di barre raggruppate e $lines serie di linee. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Grafico a barre verticali con $count barre in pila. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Grafico a barre verticali con $count barre in pila e $lines linee. ';
  }

  @override
  String get presenceAvailable => 'Disponibile';

  @override
  String get presenceAway => 'Assente';

  @override
  String get presenceBusy => 'Occupato';

  @override
  String get presenceDoNotDisturb => 'Non disturbare';

  @override
  String get presenceBlocked => 'Bloccato';

  @override
  String get presenceOffline => 'Non in linea';

  @override
  String get presenceOutOfOffice => 'Fuori sede';

  @override
  String get presenceUnknown => 'Sconosciuto';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status fuori sede';
  }
}
