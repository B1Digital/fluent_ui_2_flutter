// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fluent_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class FluentLocalizationsNl extends FluentLocalizations {
  FluentLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get close => 'Sluiten';

  @override
  String get dismiss => 'Negeren';

  @override
  String get clear => 'Wissen';

  @override
  String get open => 'Openen';

  @override
  String get remove => 'Verwijderen';

  @override
  String get more => 'Meer';

  @override
  String get overflowMore => 'meer';

  @override
  String get selectAllRows => 'Alle rijen selecteren';

  @override
  String get selectRow => 'Rij selecteren';

  @override
  String get sort => 'Sorteren';

  @override
  String get sortedAscending => 'Oplopend gesorteerd';

  @override
  String get sortedDescending => 'Aflopend gesorteerd';

  @override
  String get previousSlide => 'Vorige dia';

  @override
  String get nextSlide => 'Volgende dia';

  @override
  String get startSlideShow => 'Automatische diavoorstelling starten';

  @override
  String get pauseSlideShow => 'Automatische diavoorstelling onderbreken';

  @override
  String slideOf(int index, int count) {
    return 'Dia $index van $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Stap $index van $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value van $max';
  }

  @override
  String get openCalendar => 'Kalender openen';

  @override
  String get invalidDateFormat => 'Ongeldige datumnotatie.';

  @override
  String get dateOutOfRange => 'De datum valt buiten het toegestane bereik.';

  @override
  String get fieldRequired => 'Dit veld is verplicht.';

  @override
  String get goToToday => 'Ga naar vandaag';

  @override
  String get previousMonth => 'Vorige maand';

  @override
  String get nextMonth => 'Volgende maand';

  @override
  String get previousYear => 'Vorig jaar';

  @override
  String get nextYear => 'Volgend jaar';

  @override
  String get previousYearRange => 'Vorige reeks jaren';

  @override
  String get nextYearRange => 'Volgende reeks jaren';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, jaar wijzigen';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, maand wijzigen';
  }

  @override
  String selectedDate(String date) {
    return 'Geselecteerde datum $date';
  }

  @override
  String todaysDate(String date) {
    return 'Datum van vandaag $date';
  }

  @override
  String weekNumber(String number) {
    return 'Week $number';
  }

  @override
  String get chartNoData => 'Grafiek heeft geen gegevens om weer te geven';

  @override
  String get chartNoDataAvailable => 'Geen gegevens beschikbaar';

  @override
  String get chartFallbackTitle => 'Grafiek. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'De $axis-as geeft $subject weer. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'secundaire Y';

  @override
  String get chartAxisCategories => 'categorieën';

  @override
  String get chartAxisTime => 'tijd';

  @override
  String get chartAxisValues => 'waarden';

  @override
  String get chartLineLegendFallback => 'Lijn';

  @override
  String funnelChartDescription(int count) {
    return 'Trechtergrafiek met $count segmenten';
  }

  @override
  String donutChartDescription(int count) {
    return 'Ringdiagram met $count segmenten';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Meterdiagram met $count segmenten. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Huidige waarde: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Huidige waarde is $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Minimumwaarde: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Maximumwaarde: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Onbekend';

  @override
  String ganttChartDescription(int count) {
    return 'Gantt-diagram met $count gegevenspunten. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Heatmapdiagram met $count gegevenspunten. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Poolgrafiek met $count gegevensreeksen.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Sparkline met label $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Sankey-diagram met $nodes knooppunten en $links verbindingen';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Van $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'knooppunt $name met gewicht $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'verbinding van $source naar $target met gewicht $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Verticaal staafdiagram met $count staven. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Verticaal staafdiagram met $count staven en 1 lijn. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Verticaal staafdiagram met $count gegroepeerde staafreeksen. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Verticaal staafdiagram met $count gegroepeerde staafreeksen en $lines lijnreeksen. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Verticaal staafdiagram met $count gestapelde staven. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Verticaal staafdiagram met $count gestapelde staven en $lines lijnen. ';
  }

  @override
  String get presenceAvailable => 'Beschikbaar';

  @override
  String get presenceAway => 'Afwezig';

  @override
  String get presenceBusy => 'Bezet';

  @override
  String get presenceDoNotDisturb => 'Niet storen';

  @override
  String get presenceBlocked => 'Geblokkeerd';

  @override
  String get presenceOffline => 'Offline';

  @override
  String get presenceOutOfOffice => 'Niet op kantoor';

  @override
  String get presenceUnknown => 'Onbekend';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, niet op kantoor';
  }
}

/// The translations for Dutch Flemish, as used in Belgium (`nl_BE`).
class FluentLocalizationsNlBe extends FluentLocalizationsNl {
  FluentLocalizationsNlBe() : super('nl_BE');

  @override
  String get close => 'Sluiten';

  @override
  String get dismiss => 'Negeren';

  @override
  String get clear => 'Wissen';

  @override
  String get open => 'Openen';

  @override
  String get remove => 'Verwijderen';

  @override
  String get more => 'Meer';

  @override
  String get overflowMore => 'meer';

  @override
  String get selectAllRows => 'Alle rijen selecteren';

  @override
  String get selectRow => 'Rij selecteren';

  @override
  String get sort => 'Sorteren';

  @override
  String get sortedAscending => 'Oplopend gesorteerd';

  @override
  String get sortedDescending => 'Aflopend gesorteerd';

  @override
  String get previousSlide => 'Vorige dia';

  @override
  String get nextSlide => 'Volgende dia';

  @override
  String get startSlideShow => 'Automatische diavoorstelling starten';

  @override
  String get pauseSlideShow => 'Automatische diavoorstelling onderbreken';

  @override
  String slideOf(int index, int count) {
    return 'Dia $index van $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Stap $index van $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value van $max';
  }

  @override
  String get openCalendar => 'Kalender openen';

  @override
  String get invalidDateFormat => 'Ongeldige datumnotatie.';

  @override
  String get dateOutOfRange => 'De datum valt buiten het toegestane bereik.';

  @override
  String get fieldRequired => 'Dit veld is verplicht.';

  @override
  String get goToToday => 'Ga naar vandaag';

  @override
  String get previousMonth => 'Vorige maand';

  @override
  String get nextMonth => 'Volgende maand';

  @override
  String get previousYear => 'Vorig jaar';

  @override
  String get nextYear => 'Volgend jaar';

  @override
  String get previousYearRange => 'Vorige reeks jaren';

  @override
  String get nextYearRange => 'Volgende reeks jaren';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, jaar wijzigen';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, maand wijzigen';
  }

  @override
  String selectedDate(String date) {
    return 'Geselecteerde datum $date';
  }

  @override
  String todaysDate(String date) {
    return 'Datum van vandaag $date';
  }

  @override
  String weekNumber(String number) {
    return 'Week $number';
  }

  @override
  String get chartNoData => 'Grafiek heeft geen gegevens om weer te geven';

  @override
  String get chartNoDataAvailable => 'Geen gegevens beschikbaar';

  @override
  String get chartFallbackTitle => 'Grafiek. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'De $axis-as geeft $subject weer. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'secundaire Y';

  @override
  String get chartAxisCategories => 'categorieën';

  @override
  String get chartAxisTime => 'tijd';

  @override
  String get chartAxisValues => 'waarden';

  @override
  String get chartLineLegendFallback => 'Lijn';

  @override
  String funnelChartDescription(int count) {
    return 'Trechtergrafiek met $count segmenten';
  }

  @override
  String donutChartDescription(int count) {
    return 'Ringdiagram met $count segmenten';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Meterdiagram met $count segmenten. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Huidige waarde: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Huidige waarde is $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Minimumwaarde: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Maximumwaarde: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Onbekend';

  @override
  String ganttChartDescription(int count) {
    return 'Gantt-diagram met $count gegevenspunten. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Heatmapdiagram met $count gegevenspunten. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Poolgrafiek met $count gegevensreeksen.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Sparkline met label $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Sankey-diagram met $nodes knooppunten en $links verbindingen';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Van $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'knooppunt $name met gewicht $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'verbinding van $source naar $target met gewicht $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Verticaal staafdiagram met $count staven. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Verticaal staafdiagram met $count staven en 1 lijn. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Verticaal staafdiagram met $count gegroepeerde staafreeksen. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Verticaal staafdiagram met $count gegroepeerde staafreeksen en $lines lijnreeksen. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Verticaal staafdiagram met $count gestapelde staven. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Verticaal staafdiagram met $count gestapelde staven en $lines lijnen. ';
  }

  @override
  String get presenceAvailable => 'Beschikbaar';

  @override
  String get presenceAway => 'Afwezig';

  @override
  String get presenceBusy => 'Bezet';

  @override
  String get presenceDoNotDisturb => 'Niet storen';

  @override
  String get presenceBlocked => 'Geblokkeerd';

  @override
  String get presenceOffline => 'Offline';

  @override
  String get presenceOutOfOffice => 'Niet op kantoor';

  @override
  String get presenceUnknown => 'Onbekend';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, niet op kantoor';
  }
}

/// The translations for Dutch Flemish, as used in Netherlands (`nl_NL`).
class FluentLocalizationsNlNl extends FluentLocalizationsNl {
  FluentLocalizationsNlNl() : super('nl_NL');

  @override
  String get close => 'Sluiten';

  @override
  String get dismiss => 'Negeren';

  @override
  String get clear => 'Wissen';

  @override
  String get open => 'Openen';

  @override
  String get remove => 'Verwijderen';

  @override
  String get more => 'Meer';

  @override
  String get overflowMore => 'meer';

  @override
  String get selectAllRows => 'Alle rijen selecteren';

  @override
  String get selectRow => 'Rij selecteren';

  @override
  String get sort => 'Sorteren';

  @override
  String get sortedAscending => 'Oplopend gesorteerd';

  @override
  String get sortedDescending => 'Aflopend gesorteerd';

  @override
  String get previousSlide => 'Vorige dia';

  @override
  String get nextSlide => 'Volgende dia';

  @override
  String get startSlideShow => 'Automatische diavoorstelling starten';

  @override
  String get pauseSlideShow => 'Automatische diavoorstelling onderbreken';

  @override
  String slideOf(int index, int count) {
    return 'Dia $index van $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Stap $index van $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value van $max';
  }

  @override
  String get openCalendar => 'Kalender openen';

  @override
  String get invalidDateFormat => 'Ongeldige datumnotatie.';

  @override
  String get dateOutOfRange => 'De datum valt buiten het toegestane bereik.';

  @override
  String get fieldRequired => 'Dit veld is verplicht.';

  @override
  String get goToToday => 'Ga naar vandaag';

  @override
  String get previousMonth => 'Vorige maand';

  @override
  String get nextMonth => 'Volgende maand';

  @override
  String get previousYear => 'Vorig jaar';

  @override
  String get nextYear => 'Volgend jaar';

  @override
  String get previousYearRange => 'Vorige reeks jaren';

  @override
  String get nextYearRange => 'Volgende reeks jaren';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, jaar wijzigen';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, maand wijzigen';
  }

  @override
  String selectedDate(String date) {
    return 'Geselecteerde datum $date';
  }

  @override
  String todaysDate(String date) {
    return 'Datum van vandaag $date';
  }

  @override
  String weekNumber(String number) {
    return 'Week $number';
  }

  @override
  String get chartNoData => 'Grafiek heeft geen gegevens om weer te geven';

  @override
  String get chartNoDataAvailable => 'Geen gegevens beschikbaar';

  @override
  String get chartFallbackTitle => 'Grafiek. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'De $axis-as geeft $subject weer. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'secundaire Y';

  @override
  String get chartAxisCategories => 'categorieën';

  @override
  String get chartAxisTime => 'tijd';

  @override
  String get chartAxisValues => 'waarden';

  @override
  String get chartLineLegendFallback => 'Lijn';

  @override
  String funnelChartDescription(int count) {
    return 'Trechtergrafiek met $count segmenten';
  }

  @override
  String donutChartDescription(int count) {
    return 'Ringdiagram met $count segmenten';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Meterdiagram met $count segmenten. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Huidige waarde: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Huidige waarde is $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Minimumwaarde: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Maximumwaarde: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Onbekend';

  @override
  String ganttChartDescription(int count) {
    return 'Gantt-diagram met $count gegevenspunten. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Heatmapdiagram met $count gegevenspunten. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Poolgrafiek met $count gegevensreeksen.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Sparkline met label $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Sankey-diagram met $nodes knooppunten en $links verbindingen';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Van $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'knooppunt $name met gewicht $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'verbinding van $source naar $target met gewicht $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Verticaal staafdiagram met $count staven. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Verticaal staafdiagram met $count staven en 1 lijn. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Verticaal staafdiagram met $count gegroepeerde staafreeksen. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Verticaal staafdiagram met $count gegroepeerde staafreeksen en $lines lijnreeksen. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Verticaal staafdiagram met $count gestapelde staven. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Verticaal staafdiagram met $count gestapelde staven en $lines lijnen. ';
  }

  @override
  String get presenceAvailable => 'Beschikbaar';

  @override
  String get presenceAway => 'Afwezig';

  @override
  String get presenceBusy => 'Bezet';

  @override
  String get presenceDoNotDisturb => 'Niet storen';

  @override
  String get presenceBlocked => 'Geblokkeerd';

  @override
  String get presenceOffline => 'Offline';

  @override
  String get presenceOutOfOffice => 'Niet op kantoor';

  @override
  String get presenceUnknown => 'Onbekend';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, niet op kantoor';
  }
}
