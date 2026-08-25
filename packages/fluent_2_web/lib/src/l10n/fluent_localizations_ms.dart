// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fluent_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malay (`ms`).
class FluentLocalizationsMs extends FluentLocalizations {
  FluentLocalizationsMs([String locale = 'ms']) : super(locale);

  @override
  String get close => 'Tutup';

  @override
  String get dismiss => 'Ketepikan';

  @override
  String get clear => 'Kosongkan';

  @override
  String get open => 'Buka';

  @override
  String get remove => 'Alih keluar';

  @override
  String get more => 'Lagi';

  @override
  String get overflowMore => 'lagi';

  @override
  String get selectAllRows => 'Pilih semua baris';

  @override
  String get selectRow => 'Pilih baris';

  @override
  String get sort => 'Isih';

  @override
  String get sortedAscending => 'Diisih menaik';

  @override
  String get sortedDescending => 'Diisih menurun';

  @override
  String get previousSlide => 'Slaid sebelumnya';

  @override
  String get nextSlide => 'Slaid seterusnya';

  @override
  String get startSlideShow => 'Mulakan tayangan slaid automatik';

  @override
  String get pauseSlideShow => 'Jeda tayangan slaid automatik';

  @override
  String slideOf(int index, int count) {
    return 'Slaid $index daripada $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Langkah $index daripada $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value daripada $max';
  }

  @override
  String get openCalendar => 'Buka kalendar';

  @override
  String get invalidDateFormat => 'Format tarikh tidak sah.';

  @override
  String get dateOutOfRange => 'Tarikh berada di luar julat yang dibenarkan.';

  @override
  String get fieldRequired => 'Medan ini diperlukan.';

  @override
  String get goToToday => 'Pergi ke hari ini';

  @override
  String get previousMonth => 'Bulan sebelumnya';

  @override
  String get nextMonth => 'Bulan seterusnya';

  @override
  String get previousYear => 'Tahun sebelumnya';

  @override
  String get nextYear => 'Tahun seterusnya';

  @override
  String get previousYearRange => 'Julat tahun sebelumnya';

  @override
  String get nextYearRange => 'Julat tahun seterusnya';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, tukar tahun';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, tukar bulan';
  }

  @override
  String selectedDate(String date) {
    return 'Tarikh dipilih $date';
  }

  @override
  String todaysDate(String date) {
    return 'Tarikh hari ini $date';
  }

  @override
  String weekNumber(String number) {
    return 'Minggu $number';
  }

  @override
  String get chartNoData => 'Graf tiada data untuk dipaparkan';

  @override
  String get chartNoDataAvailable => 'Tiada data tersedia';

  @override
  String get chartFallbackTitle => 'Carta. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'Paksi $axis memaparkan $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y sekunder';

  @override
  String get chartAxisCategories => 'kategori';

  @override
  String get chartAxisTime => 'masa';

  @override
  String get chartAxisValues => 'nilai';

  @override
  String get chartLineLegendFallback => 'Garisan';

  @override
  String funnelChartDescription(int count) {
    return 'Carta corong dengan $count segmen';
  }

  @override
  String donutChartDescription(int count) {
    return 'Carta donat dengan $count hirisan';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Carta tolok dengan $count segmen. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Nilai semasa: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Nilai semasa ialah $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Nilai minimum: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Nilai maksimum: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Tidak diketahui';

  @override
  String ganttChartDescription(int count) {
    return 'Carta Gantt dengan $count titik data. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Carta peta haba dengan $count titik data. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Carta polar dengan $count siri data.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Garis percikan dengan label $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Carta Sankey dengan $nodes nod dan $links pautan';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Daripada $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'nod $name dengan berat $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'pautan daripada $source ke $target dengan berat $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Carta bar menegak dengan $count bar. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Carta bar menegak dengan $count bar dan 1 garisan. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Carta bar menegak dengan $count siri bar berkumpulan. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Carta bar menegak dengan $count siri bar berkumpulan dan $lines siri garisan. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Carta bar menegak dengan $count bar bertindan. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Carta bar menegak dengan $count bar bertindan dan $lines garisan. ';
  }

  @override
  String get presenceAvailable => 'Tersedia';

  @override
  String get presenceAway => 'Tiada di tempat';

  @override
  String get presenceBusy => 'Sibuk';

  @override
  String get presenceDoNotDisturb => 'Jangan ganggu';

  @override
  String get presenceBlocked => 'Disekat';

  @override
  String get presenceOffline => 'Luar talian';

  @override
  String get presenceOutOfOffice => 'Di luar pejabat';

  @override
  String get presenceUnknown => 'Tidak diketahui';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status di luar pejabat';
  }
}

/// The translations for Malay, as used in Brunei Darussalam (`ms_BN`).
class FluentLocalizationsMsBn extends FluentLocalizationsMs {
  FluentLocalizationsMsBn() : super('ms_BN');

  @override
  String get close => 'Tutup';

  @override
  String get dismiss => 'Ketepikan';

  @override
  String get clear => 'Kosongkan';

  @override
  String get open => 'Buka';

  @override
  String get remove => 'Alih keluar';

  @override
  String get more => 'Lagi';

  @override
  String get overflowMore => 'lagi';

  @override
  String get selectAllRows => 'Pilih semua baris';

  @override
  String get selectRow => 'Pilih baris';

  @override
  String get sort => 'Isih';

  @override
  String get sortedAscending => 'Diisih menaik';

  @override
  String get sortedDescending => 'Diisih menurun';

  @override
  String get previousSlide => 'Slaid sebelumnya';

  @override
  String get nextSlide => 'Slaid seterusnya';

  @override
  String get startSlideShow => 'Mulakan tayangan slaid automatik';

  @override
  String get pauseSlideShow => 'Jeda tayangan slaid automatik';

  @override
  String slideOf(int index, int count) {
    return 'Slaid $index daripada $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Langkah $index daripada $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value daripada $max';
  }

  @override
  String get openCalendar => 'Buka kalendar';

  @override
  String get invalidDateFormat => 'Format tarikh tidak sah.';

  @override
  String get dateOutOfRange => 'Tarikh berada di luar julat yang dibenarkan.';

  @override
  String get fieldRequired => 'Medan ini diperlukan.';

  @override
  String get goToToday => 'Pergi ke hari ini';

  @override
  String get previousMonth => 'Bulan sebelumnya';

  @override
  String get nextMonth => 'Bulan seterusnya';

  @override
  String get previousYear => 'Tahun sebelumnya';

  @override
  String get nextYear => 'Tahun seterusnya';

  @override
  String get previousYearRange => 'Julat tahun sebelumnya';

  @override
  String get nextYearRange => 'Julat tahun seterusnya';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, tukar tahun';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, tukar bulan';
  }

  @override
  String selectedDate(String date) {
    return 'Tarikh dipilih $date';
  }

  @override
  String todaysDate(String date) {
    return 'Tarikh hari ini $date';
  }

  @override
  String weekNumber(String number) {
    return 'Minggu $number';
  }

  @override
  String get chartNoData => 'Graf tiada data untuk dipaparkan';

  @override
  String get chartNoDataAvailable => 'Tiada data tersedia';

  @override
  String get chartFallbackTitle => 'Carta. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'Paksi $axis memaparkan $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y sekunder';

  @override
  String get chartAxisCategories => 'kategori';

  @override
  String get chartAxisTime => 'masa';

  @override
  String get chartAxisValues => 'nilai';

  @override
  String get chartLineLegendFallback => 'Garisan';

  @override
  String funnelChartDescription(int count) {
    return 'Carta corong dengan $count segmen';
  }

  @override
  String donutChartDescription(int count) {
    return 'Carta donat dengan $count hirisan';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Carta tolok dengan $count segmen. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Nilai semasa: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Nilai semasa ialah $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Nilai minimum: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Nilai maksimum: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Tidak diketahui';

  @override
  String ganttChartDescription(int count) {
    return 'Carta Gantt dengan $count titik data. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Carta peta haba dengan $count titik data. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Carta polar dengan $count siri data.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Garis percikan dengan label $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Carta Sankey dengan $nodes nod dan $links pautan';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Daripada $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'nod $name dengan berat $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'pautan daripada $source ke $target dengan berat $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Carta bar menegak dengan $count bar. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Carta bar menegak dengan $count bar dan 1 garisan. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Carta bar menegak dengan $count siri bar berkumpulan. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Carta bar menegak dengan $count siri bar berkumpulan dan $lines siri garisan. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Carta bar menegak dengan $count bar bertindan. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Carta bar menegak dengan $count bar bertindan dan $lines garisan. ';
  }

  @override
  String get presenceAvailable => 'Tersedia';

  @override
  String get presenceAway => 'Tiada di tempat';

  @override
  String get presenceBusy => 'Sibuk';

  @override
  String get presenceDoNotDisturb => 'Jangan ganggu';

  @override
  String get presenceBlocked => 'Disekat';

  @override
  String get presenceOffline => 'Luar talian';

  @override
  String get presenceOutOfOffice => 'Di luar pejabat';

  @override
  String get presenceUnknown => 'Tidak diketahui';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status di luar pejabat';
  }
}

/// The translations for Malay, as used in Malaysia (`ms_MY`).
class FluentLocalizationsMsMy extends FluentLocalizationsMs {
  FluentLocalizationsMsMy() : super('ms_MY');

  @override
  String get close => 'Tutup';

  @override
  String get dismiss => 'Ketepikan';

  @override
  String get clear => 'Kosongkan';

  @override
  String get open => 'Buka';

  @override
  String get remove => 'Alih keluar';

  @override
  String get more => 'Lagi';

  @override
  String get overflowMore => 'lagi';

  @override
  String get selectAllRows => 'Pilih semua baris';

  @override
  String get selectRow => 'Pilih baris';

  @override
  String get sort => 'Isih';

  @override
  String get sortedAscending => 'Diisih menaik';

  @override
  String get sortedDescending => 'Diisih menurun';

  @override
  String get previousSlide => 'Slaid sebelumnya';

  @override
  String get nextSlide => 'Slaid seterusnya';

  @override
  String get startSlideShow => 'Mulakan tayangan slaid automatik';

  @override
  String get pauseSlideShow => 'Jeda tayangan slaid automatik';

  @override
  String slideOf(int index, int count) {
    return 'Slaid $index daripada $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Langkah $index daripada $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value daripada $max';
  }

  @override
  String get openCalendar => 'Buka kalendar';

  @override
  String get invalidDateFormat => 'Format tarikh tidak sah.';

  @override
  String get dateOutOfRange => 'Tarikh berada di luar julat yang dibenarkan.';

  @override
  String get fieldRequired => 'Medan ini diperlukan.';

  @override
  String get goToToday => 'Pergi ke hari ini';

  @override
  String get previousMonth => 'Bulan sebelumnya';

  @override
  String get nextMonth => 'Bulan seterusnya';

  @override
  String get previousYear => 'Tahun sebelumnya';

  @override
  String get nextYear => 'Tahun seterusnya';

  @override
  String get previousYearRange => 'Julat tahun sebelumnya';

  @override
  String get nextYearRange => 'Julat tahun seterusnya';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, tukar tahun';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, tukar bulan';
  }

  @override
  String selectedDate(String date) {
    return 'Tarikh dipilih $date';
  }

  @override
  String todaysDate(String date) {
    return 'Tarikh hari ini $date';
  }

  @override
  String weekNumber(String number) {
    return 'Minggu $number';
  }

  @override
  String get chartNoData => 'Graf tiada data untuk dipaparkan';

  @override
  String get chartNoDataAvailable => 'Tiada data tersedia';

  @override
  String get chartFallbackTitle => 'Carta. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'Paksi $axis memaparkan $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y sekunder';

  @override
  String get chartAxisCategories => 'kategori';

  @override
  String get chartAxisTime => 'masa';

  @override
  String get chartAxisValues => 'nilai';

  @override
  String get chartLineLegendFallback => 'Garisan';

  @override
  String funnelChartDescription(int count) {
    return 'Carta corong dengan $count segmen';
  }

  @override
  String donutChartDescription(int count) {
    return 'Carta donat dengan $count hirisan';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Carta tolok dengan $count segmen. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Nilai semasa: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Nilai semasa ialah $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Nilai minimum: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Nilai maksimum: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Tidak diketahui';

  @override
  String ganttChartDescription(int count) {
    return 'Carta Gantt dengan $count titik data. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Carta peta haba dengan $count titik data. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Carta polar dengan $count siri data.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Garis percikan dengan label $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Carta Sankey dengan $nodes nod dan $links pautan';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Daripada $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'nod $name dengan berat $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'pautan daripada $source ke $target dengan berat $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Carta bar menegak dengan $count bar. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Carta bar menegak dengan $count bar dan 1 garisan. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Carta bar menegak dengan $count siri bar berkumpulan. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Carta bar menegak dengan $count siri bar berkumpulan dan $lines siri garisan. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Carta bar menegak dengan $count bar bertindan. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Carta bar menegak dengan $count bar bertindan dan $lines garisan. ';
  }

  @override
  String get presenceAvailable => 'Tersedia';

  @override
  String get presenceAway => 'Tiada di tempat';

  @override
  String get presenceBusy => 'Sibuk';

  @override
  String get presenceDoNotDisturb => 'Jangan ganggu';

  @override
  String get presenceBlocked => 'Disekat';

  @override
  String get presenceOffline => 'Luar talian';

  @override
  String get presenceOutOfOffice => 'Di luar pejabat';

  @override
  String get presenceUnknown => 'Tidak diketahui';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status di luar pejabat';
  }
}

/// The translations for Malay, as used in Singapore (`ms_SG`).
class FluentLocalizationsMsSg extends FluentLocalizationsMs {
  FluentLocalizationsMsSg() : super('ms_SG');

  @override
  String get close => 'Tutup';

  @override
  String get dismiss => 'Ketepikan';

  @override
  String get clear => 'Kosongkan';

  @override
  String get open => 'Buka';

  @override
  String get remove => 'Alih keluar';

  @override
  String get more => 'Lagi';

  @override
  String get overflowMore => 'lagi';

  @override
  String get selectAllRows => 'Pilih semua baris';

  @override
  String get selectRow => 'Pilih baris';

  @override
  String get sort => 'Isih';

  @override
  String get sortedAscending => 'Diisih menaik';

  @override
  String get sortedDescending => 'Diisih menurun';

  @override
  String get previousSlide => 'Slaid sebelumnya';

  @override
  String get nextSlide => 'Slaid seterusnya';

  @override
  String get startSlideShow => 'Mulakan tayangan slaid automatik';

  @override
  String get pauseSlideShow => 'Jeda tayangan slaid automatik';

  @override
  String slideOf(int index, int count) {
    return 'Slaid $index daripada $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Langkah $index daripada $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value daripada $max';
  }

  @override
  String get openCalendar => 'Buka kalendar';

  @override
  String get invalidDateFormat => 'Format tarikh tidak sah.';

  @override
  String get dateOutOfRange => 'Tarikh berada di luar julat yang dibenarkan.';

  @override
  String get fieldRequired => 'Medan ini diperlukan.';

  @override
  String get goToToday => 'Pergi ke hari ini';

  @override
  String get previousMonth => 'Bulan sebelumnya';

  @override
  String get nextMonth => 'Bulan seterusnya';

  @override
  String get previousYear => 'Tahun sebelumnya';

  @override
  String get nextYear => 'Tahun seterusnya';

  @override
  String get previousYearRange => 'Julat tahun sebelumnya';

  @override
  String get nextYearRange => 'Julat tahun seterusnya';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, tukar tahun';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, tukar bulan';
  }

  @override
  String selectedDate(String date) {
    return 'Tarikh dipilih $date';
  }

  @override
  String todaysDate(String date) {
    return 'Tarikh hari ini $date';
  }

  @override
  String weekNumber(String number) {
    return 'Minggu $number';
  }

  @override
  String get chartNoData => 'Graf tiada data untuk dipaparkan';

  @override
  String get chartNoDataAvailable => 'Tiada data tersedia';

  @override
  String get chartFallbackTitle => 'Carta. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'Paksi $axis memaparkan $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y sekunder';

  @override
  String get chartAxisCategories => 'kategori';

  @override
  String get chartAxisTime => 'masa';

  @override
  String get chartAxisValues => 'nilai';

  @override
  String get chartLineLegendFallback => 'Garisan';

  @override
  String funnelChartDescription(int count) {
    return 'Carta corong dengan $count segmen';
  }

  @override
  String donutChartDescription(int count) {
    return 'Carta donat dengan $count hirisan';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Carta tolok dengan $count segmen. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Nilai semasa: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Nilai semasa ialah $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Nilai minimum: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Nilai maksimum: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Tidak diketahui';

  @override
  String ganttChartDescription(int count) {
    return 'Carta Gantt dengan $count titik data. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Carta peta haba dengan $count titik data. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Carta polar dengan $count siri data.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Garis percikan dengan label $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Carta Sankey dengan $nodes nod dan $links pautan';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Daripada $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'nod $name dengan berat $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'pautan daripada $source ke $target dengan berat $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Carta bar menegak dengan $count bar. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Carta bar menegak dengan $count bar dan 1 garisan. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Carta bar menegak dengan $count siri bar berkumpulan. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Carta bar menegak dengan $count siri bar berkumpulan dan $lines siri garisan. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Carta bar menegak dengan $count bar bertindan. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Carta bar menegak dengan $count bar bertindan dan $lines garisan. ';
  }

  @override
  String get presenceAvailable => 'Tersedia';

  @override
  String get presenceAway => 'Tiada di tempat';

  @override
  String get presenceBusy => 'Sibuk';

  @override
  String get presenceDoNotDisturb => 'Jangan ganggu';

  @override
  String get presenceBlocked => 'Disekat';

  @override
  String get presenceOffline => 'Luar talian';

  @override
  String get presenceOutOfOffice => 'Di luar pejabat';

  @override
  String get presenceUnknown => 'Tidak diketahui';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status di luar pejabat';
  }
}
