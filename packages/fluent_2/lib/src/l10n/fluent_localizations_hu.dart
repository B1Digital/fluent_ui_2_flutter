// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fluent_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class FluentLocalizationsHu extends FluentLocalizations {
  FluentLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get close => 'Bezárás';

  @override
  String get dismiss => 'Elvetés';

  @override
  String get clear => 'Törlés';

  @override
  String get open => 'Megnyitás';

  @override
  String get remove => 'Eltávolítás';

  @override
  String get more => 'Továbbiak';

  @override
  String get overflowMore => 'további';

  @override
  String get selectAllRows => 'Az összes sor kijelölése';

  @override
  String get selectRow => 'Sor kijelölése';

  @override
  String get sort => 'Rendezés';

  @override
  String get sortedAscending => 'Növekvő sorrendbe rendezve';

  @override
  String get sortedDescending => 'Csökkenő sorrendbe rendezve';

  @override
  String get previousSlide => 'Előző dia';

  @override
  String get nextSlide => 'Következő dia';

  @override
  String get startSlideShow => 'Automatikus diavetítés indítása';

  @override
  String get pauseSlideShow => 'Automatikus diavetítés szüneteltetése';

  @override
  String slideOf(int index, int count) {
    return '$index. dia, összesen $count';
  }

  @override
  String stepOf(int index, int count) {
    return '$index. lépés, összesen $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value / $max';
  }

  @override
  String get openCalendar => 'Naptár megnyitása';

  @override
  String get invalidDateFormat => 'Érvénytelen dátumformátum.';

  @override
  String get dateOutOfRange => 'A dátum kívül esik a megengedett tartományon.';

  @override
  String get fieldRequired => 'A mező kitöltése kötelező.';

  @override
  String get goToToday => 'Ugrás a mai napra';

  @override
  String get previousMonth => 'Előző hónap';

  @override
  String get nextMonth => 'Következő hónap';

  @override
  String get previousYear => 'Előző év';

  @override
  String get nextYear => 'Következő év';

  @override
  String get previousYearRange => 'Előző évtartomány';

  @override
  String get nextYearRange => 'Következő évtartomány';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, év módosítása';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, hónap módosítása';
  }

  @override
  String selectedDate(String date) {
    return 'Kijelölt dátum: $date';
  }

  @override
  String todaysDate(String date) {
    return 'Mai dátum: $date';
  }

  @override
  String weekNumber(String number) {
    return '$number. hét';
  }

  @override
  String get chartNoData => 'A diagram nem tartalmaz megjeleníthető adatot';

  @override
  String get chartNoDataAvailable => 'Nincs elérhető adat';

  @override
  String get chartFallbackTitle => 'Diagram. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'A(z) $axis tengely a következőt jeleníti meg: $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'másodlagos Y';

  @override
  String get chartAxisCategories => 'kategóriák';

  @override
  String get chartAxisTime => 'idő';

  @override
  String get chartAxisValues => 'értékek';

  @override
  String get chartLineLegendFallback => 'Vonal';

  @override
  String funnelChartDescription(int count) {
    return 'Tölcsérdiagram $count szegmenssel';
  }

  @override
  String donutChartDescription(int count) {
    return 'Perecdiagram $count szelettel';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Mérőműszer-diagram $count szegmenssel. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Aktuális érték: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Az aktuális érték $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Minimális érték: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Maximális érték: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Ismeretlen';

  @override
  String ganttChartDescription(int count) {
    return 'Gantt-diagram $count adatponttal. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Hőtérkép-diagram $count adatponttal. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Polárdiagram $count adatsorral.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Minidiagram $label címkével';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Sankey-diagram $nodes csomóponttal és $links kapcsolattal';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Innen: $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'csomópont: $name, súlya: $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'kapcsolat innen: $source, ide: $target, súlya: $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Oszlopdiagram $count oszloppal. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Oszlopdiagram $count oszloppal és 1 vonallal. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Oszlopdiagram $count csoportosított oszlopadatsorral. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Oszlopdiagram $count csoportosított oszlopadatsorral és $lines vonaladatsorral. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Oszlopdiagram $count halmozott oszloppal. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Oszlopdiagram $count halmozott oszloppal és $lines vonallal. ';
  }

  @override
  String get presenceAvailable => 'Elérhető';

  @override
  String get presenceAway => 'Nincs a gépnél';

  @override
  String get presenceBusy => 'Elfoglalt';

  @override
  String get presenceDoNotDisturb => 'Ne zavarjanak';

  @override
  String get presenceBlocked => 'Blokkolva';

  @override
  String get presenceOffline => 'Offline';

  @override
  String get presenceOutOfOffice => 'Házon kívül';

  @override
  String get presenceUnknown => 'Ismeretlen';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, házon kívül';
  }
}

/// The translations for Hungarian, as used in Hungary (`hu_HU`).
class FluentLocalizationsHuHu extends FluentLocalizationsHu {
  FluentLocalizationsHuHu() : super('hu_HU');

  @override
  String get close => 'Bezárás';

  @override
  String get dismiss => 'Elvetés';

  @override
  String get clear => 'Törlés';

  @override
  String get open => 'Megnyitás';

  @override
  String get remove => 'Eltávolítás';

  @override
  String get more => 'Továbbiak';

  @override
  String get overflowMore => 'további';

  @override
  String get selectAllRows => 'Az összes sor kijelölése';

  @override
  String get selectRow => 'Sor kijelölése';

  @override
  String get sort => 'Rendezés';

  @override
  String get sortedAscending => 'Növekvő sorrendbe rendezve';

  @override
  String get sortedDescending => 'Csökkenő sorrendbe rendezve';

  @override
  String get previousSlide => 'Előző dia';

  @override
  String get nextSlide => 'Következő dia';

  @override
  String get startSlideShow => 'Automatikus diavetítés indítása';

  @override
  String get pauseSlideShow => 'Automatikus diavetítés szüneteltetése';

  @override
  String slideOf(int index, int count) {
    return '$index. dia, összesen $count';
  }

  @override
  String stepOf(int index, int count) {
    return '$index. lépés, összesen $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value / $max';
  }

  @override
  String get openCalendar => 'Naptár megnyitása';

  @override
  String get invalidDateFormat => 'Érvénytelen dátumformátum.';

  @override
  String get dateOutOfRange => 'A dátum kívül esik a megengedett tartományon.';

  @override
  String get fieldRequired => 'A mező kitöltése kötelező.';

  @override
  String get goToToday => 'Ugrás a mai napra';

  @override
  String get previousMonth => 'Előző hónap';

  @override
  String get nextMonth => 'Következő hónap';

  @override
  String get previousYear => 'Előző év';

  @override
  String get nextYear => 'Következő év';

  @override
  String get previousYearRange => 'Előző évtartomány';

  @override
  String get nextYearRange => 'Következő évtartomány';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, év módosítása';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, hónap módosítása';
  }

  @override
  String selectedDate(String date) {
    return 'Kijelölt dátum: $date';
  }

  @override
  String todaysDate(String date) {
    return 'Mai dátum: $date';
  }

  @override
  String weekNumber(String number) {
    return '$number. hét';
  }

  @override
  String get chartNoData => 'A diagram nem tartalmaz megjeleníthető adatot';

  @override
  String get chartNoDataAvailable => 'Nincs elérhető adat';

  @override
  String get chartFallbackTitle => 'Diagram. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'A(z) $axis tengely a következőt jeleníti meg: $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'másodlagos Y';

  @override
  String get chartAxisCategories => 'kategóriák';

  @override
  String get chartAxisTime => 'idő';

  @override
  String get chartAxisValues => 'értékek';

  @override
  String get chartLineLegendFallback => 'Vonal';

  @override
  String funnelChartDescription(int count) {
    return 'Tölcsérdiagram $count szegmenssel';
  }

  @override
  String donutChartDescription(int count) {
    return 'Perecdiagram $count szelettel';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Mérőműszer-diagram $count szegmenssel. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Aktuális érték: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Az aktuális érték $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Minimális érték: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Maximális érték: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Ismeretlen';

  @override
  String ganttChartDescription(int count) {
    return 'Gantt-diagram $count adatponttal. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Hőtérkép-diagram $count adatponttal. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Polárdiagram $count adatsorral.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Minidiagram $label címkével';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Sankey-diagram $nodes csomóponttal és $links kapcsolattal';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Innen: $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'csomópont: $name, súlya: $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'kapcsolat innen: $source, ide: $target, súlya: $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Oszlopdiagram $count oszloppal. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Oszlopdiagram $count oszloppal és 1 vonallal. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Oszlopdiagram $count csoportosított oszlopadatsorral. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Oszlopdiagram $count csoportosított oszlopadatsorral és $lines vonaladatsorral. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Oszlopdiagram $count halmozott oszloppal. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Oszlopdiagram $count halmozott oszloppal és $lines vonallal. ';
  }

  @override
  String get presenceAvailable => 'Elérhető';

  @override
  String get presenceAway => 'Nincs a gépnél';

  @override
  String get presenceBusy => 'Elfoglalt';

  @override
  String get presenceDoNotDisturb => 'Ne zavarjanak';

  @override
  String get presenceBlocked => 'Blokkolva';

  @override
  String get presenceOffline => 'Offline';

  @override
  String get presenceOutOfOffice => 'Házon kívül';

  @override
  String get presenceUnknown => 'Ismeretlen';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, házon kívül';
  }
}
