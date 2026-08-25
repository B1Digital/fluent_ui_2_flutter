// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fluent_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Croatian (`hr`).
class FluentLocalizationsHr extends FluentLocalizations {
  FluentLocalizationsHr([String locale = 'hr']) : super(locale);

  @override
  String get close => 'Zatvori';

  @override
  String get dismiss => 'Odbaci';

  @override
  String get clear => 'Očisti';

  @override
  String get open => 'Otvori';

  @override
  String get remove => 'Ukloni';

  @override
  String get more => 'Više';

  @override
  String get overflowMore => 'više';

  @override
  String get selectAllRows => 'Odaberi sve retke';

  @override
  String get selectRow => 'Odaberi redak';

  @override
  String get sort => 'Sortiraj';

  @override
  String get sortedAscending => 'Sortirano uzlazno';

  @override
  String get sortedDescending => 'Sortirano silazno';

  @override
  String get previousSlide => 'Prethodni slajd';

  @override
  String get nextSlide => 'Sljedeći slajd';

  @override
  String get startSlideShow => 'Pokreni automatski prikaz slajdova';

  @override
  String get pauseSlideShow => 'Pauziraj automatski prikaz slajdova';

  @override
  String slideOf(int index, int count) {
    return 'Slajd $index od $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Korak $index od $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value od $max';
  }

  @override
  String get openCalendar => 'Otvori kalendar';

  @override
  String get invalidDateFormat => 'Neispravan format datuma.';

  @override
  String get dateOutOfRange => 'Datum je izvan dopuštenog raspona.';

  @override
  String get fieldRequired => 'Ovo je polje obavezno.';

  @override
  String get goToToday => 'Idi na današnji dan';

  @override
  String get previousMonth => 'Prethodni mjesec';

  @override
  String get nextMonth => 'Sljedeći mjesec';

  @override
  String get previousYear => 'Prethodna godina';

  @override
  String get nextYear => 'Sljedeća godina';

  @override
  String get previousYearRange => 'Prethodni raspon godina';

  @override
  String get nextYearRange => 'Sljedeći raspon godina';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, promijeni godinu';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, promijeni mjesec';
  }

  @override
  String selectedDate(String date) {
    return 'Odabrani datum $date';
  }

  @override
  String todaysDate(String date) {
    return 'Današnji datum $date';
  }

  @override
  String weekNumber(String number) {
    return 'Tjedan $number';
  }

  @override
  String get chartNoData => 'Grafikon nema podataka za prikaz';

  @override
  String get chartNoDataAvailable => 'Nema dostupnih podataka';

  @override
  String get chartFallbackTitle => 'Grafikon. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return '$axis os prikazuje $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'sekundarna Y';

  @override
  String get chartAxisCategories => 'kategorije';

  @override
  String get chartAxisTime => 'vrijeme';

  @override
  String get chartAxisValues => 'vrijednosti';

  @override
  String get chartLineLegendFallback => 'Linija';

  @override
  String funnelChartDescription(int count) {
    return 'Grafikon lijevka s $count segmenata';
  }

  @override
  String donutChartDescription(int count) {
    return 'Prstenasti grafikon s $count isječaka';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Grafikon mjerača s $count segmenata. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Trenutna vrijednost: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Trenutna vrijednost je $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Najmanja vrijednost: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Najveća vrijednost: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Nepoznato';

  @override
  String ganttChartDescription(int count) {
    return 'Ganttov grafikon s $count podatkovnih točaka. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Toplinska karta s $count podatkovnih točaka. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Polarni grafikon s $count nizova podataka.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Minigrafikon s oznakom $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Sankeyjev grafikon s $nodes čvorova i $links veza';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Od $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'čvor $name s težinom $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'veza od $source do $target s težinom $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Stupčasti grafikon s $count stupaca. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Stupčasti grafikon s $count stupaca i 1 linijom. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Stupčasti grafikon s $count grupiranih nizova stupaca. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Stupčasti grafikon s $count grupiranih nizova stupaca i $lines linijskih nizova. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Stupčasti grafikon s $count složenih stupaca. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Stupčasti grafikon s $count složenih stupaca i $lines linija. ';
  }

  @override
  String get presenceAvailable => 'Dostupno';

  @override
  String get presenceAway => 'Odsutno';

  @override
  String get presenceBusy => 'Zauzeto';

  @override
  String get presenceDoNotDisturb => 'Ne uznemiravaj';

  @override
  String get presenceBlocked => 'Blokirano';

  @override
  String get presenceOffline => 'Izvan mreže';

  @override
  String get presenceOutOfOffice => 'Izvan ureda';

  @override
  String get presenceUnknown => 'Nepoznato';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, izvan ureda';
  }
}

/// The translations for Croatian, as used in Bosnia and Herzegovina (`hr_BA`).
class FluentLocalizationsHrBa extends FluentLocalizationsHr {
  FluentLocalizationsHrBa() : super('hr_BA');

  @override
  String get close => 'Zatvori';

  @override
  String get dismiss => 'Odbaci';

  @override
  String get clear => 'Očisti';

  @override
  String get open => 'Otvori';

  @override
  String get remove => 'Ukloni';

  @override
  String get more => 'Više';

  @override
  String get overflowMore => 'više';

  @override
  String get selectAllRows => 'Odaberi sve retke';

  @override
  String get selectRow => 'Odaberi redak';

  @override
  String get sort => 'Sortiraj';

  @override
  String get sortedAscending => 'Sortirano uzlazno';

  @override
  String get sortedDescending => 'Sortirano silazno';

  @override
  String get previousSlide => 'Prethodni slajd';

  @override
  String get nextSlide => 'Sljedeći slajd';

  @override
  String get startSlideShow => 'Pokreni automatski prikaz slajdova';

  @override
  String get pauseSlideShow => 'Pauziraj automatski prikaz slajdova';

  @override
  String slideOf(int index, int count) {
    return 'Slajd $index od $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Korak $index od $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value od $max';
  }

  @override
  String get openCalendar => 'Otvori kalendar';

  @override
  String get invalidDateFormat => 'Neispravan format datuma.';

  @override
  String get dateOutOfRange => 'Datum je izvan dopuštenog raspona.';

  @override
  String get fieldRequired => 'Ovo je polje obavezno.';

  @override
  String get goToToday => 'Idi na današnji dan';

  @override
  String get previousMonth => 'Prethodni mjesec';

  @override
  String get nextMonth => 'Sljedeći mjesec';

  @override
  String get previousYear => 'Prethodna godina';

  @override
  String get nextYear => 'Sljedeća godina';

  @override
  String get previousYearRange => 'Prethodni raspon godina';

  @override
  String get nextYearRange => 'Sljedeći raspon godina';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, promijeni godinu';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, promijeni mjesec';
  }

  @override
  String selectedDate(String date) {
    return 'Odabrani datum $date';
  }

  @override
  String todaysDate(String date) {
    return 'Današnji datum $date';
  }

  @override
  String weekNumber(String number) {
    return 'Tjedan $number';
  }

  @override
  String get chartNoData => 'Grafikon nema podataka za prikaz';

  @override
  String get chartNoDataAvailable => 'Nema dostupnih podataka';

  @override
  String get chartFallbackTitle => 'Grafikon. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return '$axis os prikazuje $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'sekundarna Y';

  @override
  String get chartAxisCategories => 'kategorije';

  @override
  String get chartAxisTime => 'vrijeme';

  @override
  String get chartAxisValues => 'vrijednosti';

  @override
  String get chartLineLegendFallback => 'Linija';

  @override
  String funnelChartDescription(int count) {
    return 'Grafikon lijevka s $count segmenata';
  }

  @override
  String donutChartDescription(int count) {
    return 'Prstenasti grafikon s $count isječaka';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Grafikon mjerača s $count segmenata. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Trenutna vrijednost: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Trenutna vrijednost je $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Najmanja vrijednost: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Najveća vrijednost: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Nepoznato';

  @override
  String ganttChartDescription(int count) {
    return 'Ganttov grafikon s $count podatkovnih točaka. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Toplinska karta s $count podatkovnih točaka. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Polarni grafikon s $count nizova podataka.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Minigrafikon s oznakom $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Sankeyjev grafikon s $nodes čvorova i $links veza';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Od $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'čvor $name s težinom $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'veza od $source do $target s težinom $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Stupčasti grafikon s $count stupaca. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Stupčasti grafikon s $count stupaca i 1 linijom. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Stupčasti grafikon s $count grupiranih nizova stupaca. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Stupčasti grafikon s $count grupiranih nizova stupaca i $lines linijskih nizova. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Stupčasti grafikon s $count složenih stupaca. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Stupčasti grafikon s $count složenih stupaca i $lines linija. ';
  }

  @override
  String get presenceAvailable => 'Dostupno';

  @override
  String get presenceAway => 'Odsutno';

  @override
  String get presenceBusy => 'Zauzeto';

  @override
  String get presenceDoNotDisturb => 'Ne uznemiravaj';

  @override
  String get presenceBlocked => 'Blokirano';

  @override
  String get presenceOffline => 'Izvan mreže';

  @override
  String get presenceOutOfOffice => 'Izvan ureda';

  @override
  String get presenceUnknown => 'Nepoznato';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, izvan ureda';
  }
}

/// The translations for Croatian, as used in Croatia (`hr_HR`).
class FluentLocalizationsHrHr extends FluentLocalizationsHr {
  FluentLocalizationsHrHr() : super('hr_HR');

  @override
  String get close => 'Zatvori';

  @override
  String get dismiss => 'Odbaci';

  @override
  String get clear => 'Očisti';

  @override
  String get open => 'Otvori';

  @override
  String get remove => 'Ukloni';

  @override
  String get more => 'Više';

  @override
  String get overflowMore => 'više';

  @override
  String get selectAllRows => 'Odaberi sve retke';

  @override
  String get selectRow => 'Odaberi redak';

  @override
  String get sort => 'Sortiraj';

  @override
  String get sortedAscending => 'Sortirano uzlazno';

  @override
  String get sortedDescending => 'Sortirano silazno';

  @override
  String get previousSlide => 'Prethodni slajd';

  @override
  String get nextSlide => 'Sljedeći slajd';

  @override
  String get startSlideShow => 'Pokreni automatski prikaz slajdova';

  @override
  String get pauseSlideShow => 'Pauziraj automatski prikaz slajdova';

  @override
  String slideOf(int index, int count) {
    return 'Slajd $index od $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Korak $index od $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value od $max';
  }

  @override
  String get openCalendar => 'Otvori kalendar';

  @override
  String get invalidDateFormat => 'Neispravan format datuma.';

  @override
  String get dateOutOfRange => 'Datum je izvan dopuštenog raspona.';

  @override
  String get fieldRequired => 'Ovo je polje obavezno.';

  @override
  String get goToToday => 'Idi na današnji dan';

  @override
  String get previousMonth => 'Prethodni mjesec';

  @override
  String get nextMonth => 'Sljedeći mjesec';

  @override
  String get previousYear => 'Prethodna godina';

  @override
  String get nextYear => 'Sljedeća godina';

  @override
  String get previousYearRange => 'Prethodni raspon godina';

  @override
  String get nextYearRange => 'Sljedeći raspon godina';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, promijeni godinu';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, promijeni mjesec';
  }

  @override
  String selectedDate(String date) {
    return 'Odabrani datum $date';
  }

  @override
  String todaysDate(String date) {
    return 'Današnji datum $date';
  }

  @override
  String weekNumber(String number) {
    return 'Tjedan $number';
  }

  @override
  String get chartNoData => 'Grafikon nema podataka za prikaz';

  @override
  String get chartNoDataAvailable => 'Nema dostupnih podataka';

  @override
  String get chartFallbackTitle => 'Grafikon. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return '$axis os prikazuje $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'sekundarna Y';

  @override
  String get chartAxisCategories => 'kategorije';

  @override
  String get chartAxisTime => 'vrijeme';

  @override
  String get chartAxisValues => 'vrijednosti';

  @override
  String get chartLineLegendFallback => 'Linija';

  @override
  String funnelChartDescription(int count) {
    return 'Grafikon lijevka s $count segmenata';
  }

  @override
  String donutChartDescription(int count) {
    return 'Prstenasti grafikon s $count isječaka';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Grafikon mjerača s $count segmenata. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Trenutna vrijednost: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Trenutna vrijednost je $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Najmanja vrijednost: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Najveća vrijednost: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Nepoznato';

  @override
  String ganttChartDescription(int count) {
    return 'Ganttov grafikon s $count podatkovnih točaka. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Toplinska karta s $count podatkovnih točaka. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Polarni grafikon s $count nizova podataka.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Minigrafikon s oznakom $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Sankeyjev grafikon s $nodes čvorova i $links veza';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Od $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'čvor $name s težinom $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'veza od $source do $target s težinom $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Stupčasti grafikon s $count stupaca. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Stupčasti grafikon s $count stupaca i 1 linijom. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Stupčasti grafikon s $count grupiranih nizova stupaca. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Stupčasti grafikon s $count grupiranih nizova stupaca i $lines linijskih nizova. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Stupčasti grafikon s $count složenih stupaca. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Stupčasti grafikon s $count složenih stupaca i $lines linija. ';
  }

  @override
  String get presenceAvailable => 'Dostupno';

  @override
  String get presenceAway => 'Odsutno';

  @override
  String get presenceBusy => 'Zauzeto';

  @override
  String get presenceDoNotDisturb => 'Ne uznemiravaj';

  @override
  String get presenceBlocked => 'Blokirano';

  @override
  String get presenceOffline => 'Izvan mreže';

  @override
  String get presenceOutOfOffice => 'Izvan ureda';

  @override
  String get presenceUnknown => 'Nepoznato';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, izvan ureda';
  }
}
