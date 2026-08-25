// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fluent_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Modern Greek (`el`).
class FluentLocalizationsEl extends FluentLocalizations {
  FluentLocalizationsEl([String locale = 'el']) : super(locale);

  @override
  String get close => 'Κλείσιμο';

  @override
  String get dismiss => 'Παράβλεψη';

  @override
  String get clear => 'Απαλοιφή';

  @override
  String get open => 'Άνοιγμα';

  @override
  String get remove => 'Κατάργηση';

  @override
  String get more => 'Περισσότερα';

  @override
  String get overflowMore => 'περισσότερα';

  @override
  String get selectAllRows => 'Επιλογή όλων των γραμμών';

  @override
  String get selectRow => 'Επιλογή γραμμής';

  @override
  String get sort => 'Ταξινόμηση';

  @override
  String get sortedAscending => 'Ταξινομημένο κατά αύξουσα σειρά';

  @override
  String get sortedDescending => 'Ταξινομημένο κατά φθίνουσα σειρά';

  @override
  String get previousSlide => 'Προηγούμενη διαφάνεια';

  @override
  String get nextSlide => 'Επόμενη διαφάνεια';

  @override
  String get startSlideShow => 'Έναρξη αυτόματης προβολής διαφανειών';

  @override
  String get pauseSlideShow => 'Παύση αυτόματης προβολής διαφανειών';

  @override
  String slideOf(int index, int count) {
    return 'Διαφάνεια $index από $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Βήμα $index από $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value από $max';
  }

  @override
  String get openCalendar => 'Άνοιγμα ημερολογίου';

  @override
  String get invalidDateFormat => 'Μη έγκυρη μορφή ημερομηνίας.';

  @override
  String get dateOutOfRange =>
      'Η ημερομηνία είναι εκτός του επιτρεπόμενου εύρους.';

  @override
  String get fieldRequired => 'Αυτό το πεδίο είναι υποχρεωτικό.';

  @override
  String get goToToday => 'Μετάβαση στη σημερινή ημέρα';

  @override
  String get previousMonth => 'Προηγούμενος μήνας';

  @override
  String get nextMonth => 'Επόμενος μήνας';

  @override
  String get previousYear => 'Προηγούμενο έτος';

  @override
  String get nextYear => 'Επόμενο έτος';

  @override
  String get previousYearRange => 'Προηγούμενο εύρος ετών';

  @override
  String get nextYearRange => 'Επόμενο εύρος ετών';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, αλλαγή έτους';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, αλλαγή μήνα';
  }

  @override
  String selectedDate(String date) {
    return 'Επιλεγμένη ημερομηνία $date';
  }

  @override
  String todaysDate(String date) {
    return 'Σημερινή ημερομηνία $date';
  }

  @override
  String weekNumber(String number) {
    return 'Εβδομάδα $number';
  }

  @override
  String get chartNoData => 'Το γράφημα δεν έχει δεδομένα για εμφάνιση';

  @override
  String get chartNoDataAvailable => 'Δεν υπάρχουν διαθέσιμα δεδομένα';

  @override
  String get chartFallbackTitle => 'Γράφημα. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'Ο άξονας $axis εμφανίζει $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'δευτερεύων Y';

  @override
  String get chartAxisCategories => 'κατηγορίες';

  @override
  String get chartAxisTime => 'χρόνο';

  @override
  String get chartAxisValues => 'τιμές';

  @override
  String get chartLineLegendFallback => 'Γραμμή';

  @override
  String funnelChartDescription(int count) {
    return 'Γράφημα χοάνης με $count τμήματα';
  }

  @override
  String donutChartDescription(int count) {
    return 'Γράφημα δακτυλίου με $count τμήματα';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Γράφημα μετρητή με $count τμήματα. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Τρέχουσα τιμή: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Η τρέχουσα τιμή είναι $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Ελάχιστη τιμή: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Μέγιστη τιμή: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Άγνωστο';

  @override
  String ganttChartDescription(int count) {
    return 'Γράφημα Gantt με $count σημεία δεδομένων. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Γράφημα χάρτη θερμότητας με $count σημεία δεδομένων. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Πολικό γράφημα με $count σειρές δεδομένων.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Γράφημα sparkline με ετικέτα $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Γράφημα Sankey με $nodes κόμβους και $links συνδέσεις';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Από $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'κόμβος $name με βάρος $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'σύνδεση από $source προς $target με βάρος $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Γράφημα στηλών με $count στήλες. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Γράφημα στηλών με $count στήλες και 1 γραμμή. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Γράφημα στηλών με $count ομαδοποιημένες σειρές στηλών. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Γράφημα στηλών με $count ομαδοποιημένες σειρές στηλών και $lines σειρές γραμμών. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Γράφημα στηλών με $count σωρευμένες στήλες. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Γράφημα στηλών με $count σωρευμένες στήλες και $lines γραμμές. ';
  }

  @override
  String get presenceAvailable => 'Διαθέσιμος';

  @override
  String get presenceAway => 'Λείπω';

  @override
  String get presenceBusy => 'Απασχολημένος';

  @override
  String get presenceDoNotDisturb => 'Μην ενοχλείτε';

  @override
  String get presenceBlocked => 'Αποκλεισμένος';

  @override
  String get presenceOffline => 'Χωρίς σύνδεση';

  @override
  String get presenceOutOfOffice => 'Εκτός γραφείου';

  @override
  String get presenceUnknown => 'Άγνωστο';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status εκτός γραφείου';
  }
}

/// The translations for Modern Greek, as used in Cyprus (`el_CY`).
class FluentLocalizationsElCy extends FluentLocalizationsEl {
  FluentLocalizationsElCy() : super('el_CY');

  @override
  String get close => 'Κλείσιμο';

  @override
  String get dismiss => 'Παράβλεψη';

  @override
  String get clear => 'Απαλοιφή';

  @override
  String get open => 'Άνοιγμα';

  @override
  String get remove => 'Κατάργηση';

  @override
  String get more => 'Περισσότερα';

  @override
  String get overflowMore => 'περισσότερα';

  @override
  String get selectAllRows => 'Επιλογή όλων των γραμμών';

  @override
  String get selectRow => 'Επιλογή γραμμής';

  @override
  String get sort => 'Ταξινόμηση';

  @override
  String get sortedAscending => 'Ταξινομημένο κατά αύξουσα σειρά';

  @override
  String get sortedDescending => 'Ταξινομημένο κατά φθίνουσα σειρά';

  @override
  String get previousSlide => 'Προηγούμενη διαφάνεια';

  @override
  String get nextSlide => 'Επόμενη διαφάνεια';

  @override
  String get startSlideShow => 'Έναρξη αυτόματης προβολής διαφανειών';

  @override
  String get pauseSlideShow => 'Παύση αυτόματης προβολής διαφανειών';

  @override
  String slideOf(int index, int count) {
    return 'Διαφάνεια $index από $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Βήμα $index από $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value από $max';
  }

  @override
  String get openCalendar => 'Άνοιγμα ημερολογίου';

  @override
  String get invalidDateFormat => 'Μη έγκυρη μορφή ημερομηνίας.';

  @override
  String get dateOutOfRange =>
      'Η ημερομηνία είναι εκτός του επιτρεπόμενου εύρους.';

  @override
  String get fieldRequired => 'Αυτό το πεδίο είναι υποχρεωτικό.';

  @override
  String get goToToday => 'Μετάβαση στη σημερινή ημέρα';

  @override
  String get previousMonth => 'Προηγούμενος μήνας';

  @override
  String get nextMonth => 'Επόμενος μήνας';

  @override
  String get previousYear => 'Προηγούμενο έτος';

  @override
  String get nextYear => 'Επόμενο έτος';

  @override
  String get previousYearRange => 'Προηγούμενο εύρος ετών';

  @override
  String get nextYearRange => 'Επόμενο εύρος ετών';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, αλλαγή έτους';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, αλλαγή μήνα';
  }

  @override
  String selectedDate(String date) {
    return 'Επιλεγμένη ημερομηνία $date';
  }

  @override
  String todaysDate(String date) {
    return 'Σημερινή ημερομηνία $date';
  }

  @override
  String weekNumber(String number) {
    return 'Εβδομάδα $number';
  }

  @override
  String get chartNoData => 'Το γράφημα δεν έχει δεδομένα για εμφάνιση';

  @override
  String get chartNoDataAvailable => 'Δεν υπάρχουν διαθέσιμα δεδομένα';

  @override
  String get chartFallbackTitle => 'Γράφημα. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'Ο άξονας $axis εμφανίζει $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'δευτερεύων Y';

  @override
  String get chartAxisCategories => 'κατηγορίες';

  @override
  String get chartAxisTime => 'χρόνο';

  @override
  String get chartAxisValues => 'τιμές';

  @override
  String get chartLineLegendFallback => 'Γραμμή';

  @override
  String funnelChartDescription(int count) {
    return 'Γράφημα χοάνης με $count τμήματα';
  }

  @override
  String donutChartDescription(int count) {
    return 'Γράφημα δακτυλίου με $count τμήματα';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Γράφημα μετρητή με $count τμήματα. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Τρέχουσα τιμή: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Η τρέχουσα τιμή είναι $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Ελάχιστη τιμή: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Μέγιστη τιμή: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Άγνωστο';

  @override
  String ganttChartDescription(int count) {
    return 'Γράφημα Gantt με $count σημεία δεδομένων. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Γράφημα χάρτη θερμότητας με $count σημεία δεδομένων. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Πολικό γράφημα με $count σειρές δεδομένων.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Γράφημα sparkline με ετικέτα $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Γράφημα Sankey με $nodes κόμβους και $links συνδέσεις';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Από $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'κόμβος $name με βάρος $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'σύνδεση από $source προς $target με βάρος $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Γράφημα στηλών με $count στήλες. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Γράφημα στηλών με $count στήλες και 1 γραμμή. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Γράφημα στηλών με $count ομαδοποιημένες σειρές στηλών. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Γράφημα στηλών με $count ομαδοποιημένες σειρές στηλών και $lines σειρές γραμμών. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Γράφημα στηλών με $count σωρευμένες στήλες. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Γράφημα στηλών με $count σωρευμένες στήλες και $lines γραμμές. ';
  }

  @override
  String get presenceAvailable => 'Διαθέσιμος';

  @override
  String get presenceAway => 'Λείπω';

  @override
  String get presenceBusy => 'Απασχολημένος';

  @override
  String get presenceDoNotDisturb => 'Μην ενοχλείτε';

  @override
  String get presenceBlocked => 'Αποκλεισμένος';

  @override
  String get presenceOffline => 'Χωρίς σύνδεση';

  @override
  String get presenceOutOfOffice => 'Εκτός γραφείου';

  @override
  String get presenceUnknown => 'Άγνωστο';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status εκτός γραφείου';
  }
}

/// The translations for Modern Greek, as used in Greece (`el_GR`).
class FluentLocalizationsElGr extends FluentLocalizationsEl {
  FluentLocalizationsElGr() : super('el_GR');

  @override
  String get close => 'Κλείσιμο';

  @override
  String get dismiss => 'Παράβλεψη';

  @override
  String get clear => 'Απαλοιφή';

  @override
  String get open => 'Άνοιγμα';

  @override
  String get remove => 'Κατάργηση';

  @override
  String get more => 'Περισσότερα';

  @override
  String get overflowMore => 'περισσότερα';

  @override
  String get selectAllRows => 'Επιλογή όλων των γραμμών';

  @override
  String get selectRow => 'Επιλογή γραμμής';

  @override
  String get sort => 'Ταξινόμηση';

  @override
  String get sortedAscending => 'Ταξινομημένο κατά αύξουσα σειρά';

  @override
  String get sortedDescending => 'Ταξινομημένο κατά φθίνουσα σειρά';

  @override
  String get previousSlide => 'Προηγούμενη διαφάνεια';

  @override
  String get nextSlide => 'Επόμενη διαφάνεια';

  @override
  String get startSlideShow => 'Έναρξη αυτόματης προβολής διαφανειών';

  @override
  String get pauseSlideShow => 'Παύση αυτόματης προβολής διαφανειών';

  @override
  String slideOf(int index, int count) {
    return 'Διαφάνεια $index από $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Βήμα $index από $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value από $max';
  }

  @override
  String get openCalendar => 'Άνοιγμα ημερολογίου';

  @override
  String get invalidDateFormat => 'Μη έγκυρη μορφή ημερομηνίας.';

  @override
  String get dateOutOfRange =>
      'Η ημερομηνία είναι εκτός του επιτρεπόμενου εύρους.';

  @override
  String get fieldRequired => 'Αυτό το πεδίο είναι υποχρεωτικό.';

  @override
  String get goToToday => 'Μετάβαση στη σημερινή ημέρα';

  @override
  String get previousMonth => 'Προηγούμενος μήνας';

  @override
  String get nextMonth => 'Επόμενος μήνας';

  @override
  String get previousYear => 'Προηγούμενο έτος';

  @override
  String get nextYear => 'Επόμενο έτος';

  @override
  String get previousYearRange => 'Προηγούμενο εύρος ετών';

  @override
  String get nextYearRange => 'Επόμενο εύρος ετών';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, αλλαγή έτους';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, αλλαγή μήνα';
  }

  @override
  String selectedDate(String date) {
    return 'Επιλεγμένη ημερομηνία $date';
  }

  @override
  String todaysDate(String date) {
    return 'Σημερινή ημερομηνία $date';
  }

  @override
  String weekNumber(String number) {
    return 'Εβδομάδα $number';
  }

  @override
  String get chartNoData => 'Το γράφημα δεν έχει δεδομένα για εμφάνιση';

  @override
  String get chartNoDataAvailable => 'Δεν υπάρχουν διαθέσιμα δεδομένα';

  @override
  String get chartFallbackTitle => 'Γράφημα. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'Ο άξονας $axis εμφανίζει $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'δευτερεύων Y';

  @override
  String get chartAxisCategories => 'κατηγορίες';

  @override
  String get chartAxisTime => 'χρόνο';

  @override
  String get chartAxisValues => 'τιμές';

  @override
  String get chartLineLegendFallback => 'Γραμμή';

  @override
  String funnelChartDescription(int count) {
    return 'Γράφημα χοάνης με $count τμήματα';
  }

  @override
  String donutChartDescription(int count) {
    return 'Γράφημα δακτυλίου με $count τμήματα';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Γράφημα μετρητή με $count τμήματα. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Τρέχουσα τιμή: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Η τρέχουσα τιμή είναι $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Ελάχιστη τιμή: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Μέγιστη τιμή: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Άγνωστο';

  @override
  String ganttChartDescription(int count) {
    return 'Γράφημα Gantt με $count σημεία δεδομένων. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Γράφημα χάρτη θερμότητας με $count σημεία δεδομένων. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Πολικό γράφημα με $count σειρές δεδομένων.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Γράφημα sparkline με ετικέτα $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Γράφημα Sankey με $nodes κόμβους και $links συνδέσεις';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Από $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'κόμβος $name με βάρος $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'σύνδεση από $source προς $target με βάρος $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Γράφημα στηλών με $count στήλες. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Γράφημα στηλών με $count στήλες και 1 γραμμή. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Γράφημα στηλών με $count ομαδοποιημένες σειρές στηλών. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Γράφημα στηλών με $count ομαδοποιημένες σειρές στηλών και $lines σειρές γραμμών. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Γράφημα στηλών με $count σωρευμένες στήλες. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Γράφημα στηλών με $count σωρευμένες στήλες και $lines γραμμές. ';
  }

  @override
  String get presenceAvailable => 'Διαθέσιμος';

  @override
  String get presenceAway => 'Λείπω';

  @override
  String get presenceBusy => 'Απασχολημένος';

  @override
  String get presenceDoNotDisturb => 'Μην ενοχλείτε';

  @override
  String get presenceBlocked => 'Αποκλεισμένος';

  @override
  String get presenceOffline => 'Χωρίς σύνδεση';

  @override
  String get presenceOutOfOffice => 'Εκτός γραφείου';

  @override
  String get presenceUnknown => 'Άγνωστο';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status εκτός γραφείου';
  }
}
