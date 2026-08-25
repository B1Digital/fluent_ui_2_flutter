// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fluent_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class FluentLocalizationsId extends FluentLocalizations {
  FluentLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get close => 'Tutup';

  @override
  String get dismiss => 'Abaikan';

  @override
  String get clear => 'Kosongkan';

  @override
  String get open => 'Buka';

  @override
  String get remove => 'Hapus';

  @override
  String get more => 'Lainnya';

  @override
  String get overflowMore => 'lainnya';

  @override
  String get selectAllRows => 'Pilih semua baris';

  @override
  String get selectRow => 'Pilih baris';

  @override
  String get sort => 'Urutkan';

  @override
  String get sortedAscending => 'Diurutkan naik';

  @override
  String get sortedDescending => 'Diurutkan turun';

  @override
  String get previousSlide => 'Slide sebelumnya';

  @override
  String get nextSlide => 'Slide berikutnya';

  @override
  String get startSlideShow => 'Mulai peragaan slide otomatis';

  @override
  String get pauseSlideShow => 'Jeda peragaan slide otomatis';

  @override
  String slideOf(int index, int count) {
    return 'Slide $index dari $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Langkah $index dari $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value dari $max';
  }

  @override
  String get openCalendar => 'Buka kalender';

  @override
  String get invalidDateFormat => 'Format tanggal tidak valid.';

  @override
  String get dateOutOfRange => 'Tanggal berada di luar rentang yang diizinkan.';

  @override
  String get fieldRequired => 'Bidang ini wajib diisi.';

  @override
  String get goToToday => 'Ke hari ini';

  @override
  String get previousMonth => 'Bulan sebelumnya';

  @override
  String get nextMonth => 'Bulan berikutnya';

  @override
  String get previousYear => 'Tahun sebelumnya';

  @override
  String get nextYear => 'Tahun berikutnya';

  @override
  String get previousYearRange => 'Rentang tahun sebelumnya';

  @override
  String get nextYearRange => 'Rentang tahun berikutnya';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, ubah tahun';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, ubah bulan';
  }

  @override
  String selectedDate(String date) {
    return 'Tanggal yang dipilih $date';
  }

  @override
  String todaysDate(String date) {
    return 'Tanggal hari ini $date';
  }

  @override
  String weekNumber(String number) {
    return 'Minggu $number';
  }

  @override
  String get chartNoData => 'Grafik tidak memiliki data untuk ditampilkan';

  @override
  String get chartNoDataAvailable => 'Tidak ada data tersedia';

  @override
  String get chartFallbackTitle => 'Bagan. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'Sumbu $axis menampilkan $subject. ';
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
  String get chartAxisTime => 'waktu';

  @override
  String get chartAxisValues => 'nilai';

  @override
  String get chartLineLegendFallback => 'Garis';

  @override
  String funnelChartDescription(int count) {
    return 'Bagan corong dengan $count segmen';
  }

  @override
  String donutChartDescription(int count) {
    return 'Bagan donat dengan $count irisan';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Bagan pengukur dengan $count segmen. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Nilai saat ini: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Nilai saat ini adalah $value';
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
    return 'Bagan Gantt dengan $count titik data. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Bagan peta panas dengan $count titik data. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Bagan polar dengan $count seri data.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Sparkline dengan label $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Bagan Sankey dengan $nodes simpul dan $links tautan';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Dari $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'simpul $name dengan bobot $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'tautan dari $source ke $target dengan bobot $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Bagan batang vertikal dengan $count batang. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Bagan batang vertikal dengan $count batang dan 1 garis. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Bagan batang vertikal dengan $count seri batang berkelompok. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Bagan batang vertikal dengan $count seri batang berkelompok dan $lines seri garis. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Bagan batang vertikal dengan $count batang bertumpuk. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Bagan batang vertikal dengan $count batang bertumpuk dan $lines garis. ';
  }

  @override
  String get presenceAvailable => 'Tersedia';

  @override
  String get presenceAway => 'Tidak di tempat';

  @override
  String get presenceBusy => 'Sibuk';

  @override
  String get presenceDoNotDisturb => 'Jangan ganggu';

  @override
  String get presenceBlocked => 'Diblokir';

  @override
  String get presenceOffline => 'Offline';

  @override
  String get presenceOutOfOffice => 'Di luar kantor';

  @override
  String get presenceUnknown => 'Tidak diketahui';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status di luar kantor';
  }
}

/// The translations for Indonesian, as used in Indonesia (`id_ID`).
class FluentLocalizationsIdId extends FluentLocalizationsId {
  FluentLocalizationsIdId() : super('id_ID');

  @override
  String get close => 'Tutup';

  @override
  String get dismiss => 'Abaikan';

  @override
  String get clear => 'Kosongkan';

  @override
  String get open => 'Buka';

  @override
  String get remove => 'Hapus';

  @override
  String get more => 'Lainnya';

  @override
  String get overflowMore => 'lainnya';

  @override
  String get selectAllRows => 'Pilih semua baris';

  @override
  String get selectRow => 'Pilih baris';

  @override
  String get sort => 'Urutkan';

  @override
  String get sortedAscending => 'Diurutkan naik';

  @override
  String get sortedDescending => 'Diurutkan turun';

  @override
  String get previousSlide => 'Slide sebelumnya';

  @override
  String get nextSlide => 'Slide berikutnya';

  @override
  String get startSlideShow => 'Mulai peragaan slide otomatis';

  @override
  String get pauseSlideShow => 'Jeda peragaan slide otomatis';

  @override
  String slideOf(int index, int count) {
    return 'Slide $index dari $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Langkah $index dari $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value dari $max';
  }

  @override
  String get openCalendar => 'Buka kalender';

  @override
  String get invalidDateFormat => 'Format tanggal tidak valid.';

  @override
  String get dateOutOfRange => 'Tanggal berada di luar rentang yang diizinkan.';

  @override
  String get fieldRequired => 'Bidang ini wajib diisi.';

  @override
  String get goToToday => 'Ke hari ini';

  @override
  String get previousMonth => 'Bulan sebelumnya';

  @override
  String get nextMonth => 'Bulan berikutnya';

  @override
  String get previousYear => 'Tahun sebelumnya';

  @override
  String get nextYear => 'Tahun berikutnya';

  @override
  String get previousYearRange => 'Rentang tahun sebelumnya';

  @override
  String get nextYearRange => 'Rentang tahun berikutnya';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, ubah tahun';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, ubah bulan';
  }

  @override
  String selectedDate(String date) {
    return 'Tanggal yang dipilih $date';
  }

  @override
  String todaysDate(String date) {
    return 'Tanggal hari ini $date';
  }

  @override
  String weekNumber(String number) {
    return 'Minggu $number';
  }

  @override
  String get chartNoData => 'Grafik tidak memiliki data untuk ditampilkan';

  @override
  String get chartNoDataAvailable => 'Tidak ada data tersedia';

  @override
  String get chartFallbackTitle => 'Bagan. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'Sumbu $axis menampilkan $subject. ';
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
  String get chartAxisTime => 'waktu';

  @override
  String get chartAxisValues => 'nilai';

  @override
  String get chartLineLegendFallback => 'Garis';

  @override
  String funnelChartDescription(int count) {
    return 'Bagan corong dengan $count segmen';
  }

  @override
  String donutChartDescription(int count) {
    return 'Bagan donat dengan $count irisan';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Bagan pengukur dengan $count segmen. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Nilai saat ini: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Nilai saat ini adalah $value';
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
    return 'Bagan Gantt dengan $count titik data. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Bagan peta panas dengan $count titik data. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Bagan polar dengan $count seri data.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Sparkline dengan label $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Bagan Sankey dengan $nodes simpul dan $links tautan';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Dari $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'simpul $name dengan bobot $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'tautan dari $source ke $target dengan bobot $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Bagan batang vertikal dengan $count batang. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Bagan batang vertikal dengan $count batang dan 1 garis. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Bagan batang vertikal dengan $count seri batang berkelompok. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Bagan batang vertikal dengan $count seri batang berkelompok dan $lines seri garis. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Bagan batang vertikal dengan $count batang bertumpuk. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Bagan batang vertikal dengan $count batang bertumpuk dan $lines garis. ';
  }

  @override
  String get presenceAvailable => 'Tersedia';

  @override
  String get presenceAway => 'Tidak di tempat';

  @override
  String get presenceBusy => 'Sibuk';

  @override
  String get presenceDoNotDisturb => 'Jangan ganggu';

  @override
  String get presenceBlocked => 'Diblokir';

  @override
  String get presenceOffline => 'Offline';

  @override
  String get presenceOutOfOffice => 'Di luar kantor';

  @override
  String get presenceUnknown => 'Tidak diketahui';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status di luar kantor';
  }
}
