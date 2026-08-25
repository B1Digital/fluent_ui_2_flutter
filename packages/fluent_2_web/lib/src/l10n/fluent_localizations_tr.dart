// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fluent_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class FluentLocalizationsTr extends FluentLocalizations {
  FluentLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get close => 'Kapat';

  @override
  String get dismiss => 'Kapat';

  @override
  String get clear => 'Temizle';

  @override
  String get open => 'Aç';

  @override
  String get remove => 'Kaldır';

  @override
  String get more => 'Daha fazla';

  @override
  String get overflowMore => 'daha';

  @override
  String get selectAllRows => 'Tüm satırları seç';

  @override
  String get selectRow => 'Satırı seç';

  @override
  String get sort => 'Sırala';

  @override
  String get sortedAscending => 'Artan düzende sıralandı';

  @override
  String get sortedDescending => 'Azalan düzende sıralandı';

  @override
  String get previousSlide => 'Önceki slayt';

  @override
  String get nextSlide => 'Sonraki slayt';

  @override
  String get startSlideShow => 'Otomatik slayt gösterisini başlat';

  @override
  String get pauseSlideShow => 'Otomatik slayt gösterisini duraklat';

  @override
  String slideOf(int index, int count) {
    return 'Slayt $index / $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Adım $index / $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$max üzerinden $value';
  }

  @override
  String get openCalendar => 'Takvimi aç';

  @override
  String get invalidDateFormat => 'Geçersiz tarih biçimi.';

  @override
  String get dateOutOfRange => 'Tarih izin verilen aralığın dışında.';

  @override
  String get fieldRequired => 'Bu alan zorunludur.';

  @override
  String get goToToday => 'Bugüne git';

  @override
  String get previousMonth => 'Önceki ay';

  @override
  String get nextMonth => 'Sonraki ay';

  @override
  String get previousYear => 'Önceki yıl';

  @override
  String get nextYear => 'Sonraki yıl';

  @override
  String get previousYearRange => 'Önceki yıl aralığı';

  @override
  String get nextYearRange => 'Sonraki yıl aralığı';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, yılı değiştir';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, ayı değiştir';
  }

  @override
  String selectedDate(String date) {
    return 'Seçili tarih $date';
  }

  @override
  String todaysDate(String date) {
    return 'Bugünün tarihi $date';
  }

  @override
  String weekNumber(String number) {
    return '$number. hafta';
  }

  @override
  String get chartNoData => 'Grafikte görüntülenecek veri yok';

  @override
  String get chartNoDataAvailable => 'Kullanılabilir veri yok';

  @override
  String get chartFallbackTitle => 'Grafik. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return '$axis ekseni $subject gösterir. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'ikincil Y';

  @override
  String get chartAxisCategories => 'kategorileri';

  @override
  String get chartAxisTime => 'zamanı';

  @override
  String get chartAxisValues => 'değerleri';

  @override
  String get chartLineLegendFallback => 'Çizgi';

  @override
  String funnelChartDescription(int count) {
    return '$count bölümlü huni grafiği';
  }

  @override
  String donutChartDescription(int count) {
    return '$count dilimli halka grafiği';
  }

  @override
  String gaugeChartDescription(int count) {
    return '$count bölümlü gösterge grafiği. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Geçerli değer: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Geçerli değer $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'En küçük değer: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'En büyük değer: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Bilinmiyor';

  @override
  String ganttChartDescription(int count) {
    return '$count veri noktalı Gantt grafiği. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return '$count veri noktalı ısı haritası grafiği. ';
  }

  @override
  String polarChartDescription(int count) {
    return '$count veri serili kutupsal grafik.';
  }

  @override
  String sparklineDescription(String label) {
    return '$label etiketli mini grafik';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return '$nodes düğüm ve $links bağlantı içeren Sankey grafiği';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Kaynak: $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return '$weight ağırlıklı $name düğümü';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return '$source kaynağından $target hedefine $weight ağırlıklı bağlantı';
  }

  @override
  String verticalBarChartDescription(int count) {
    return '$count çubuklu dikey çubuk grafiği. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return '$count çubuk ve 1 çizgi içeren dikey çubuk grafiği. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return '$count gruplandırılmış çubuk serisi içeren dikey çubuk grafiği. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return '$count gruplandırılmış çubuk serisi ve $lines çizgi serisi içeren dikey çubuk grafiği. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return '$count yığılmış çubuk içeren dikey çubuk grafiği. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return '$count yığılmış çubuk ve $lines çizgi içeren dikey çubuk grafiği. ';
  }

  @override
  String get presenceAvailable => 'Müsait';

  @override
  String get presenceAway => 'Uzakta';

  @override
  String get presenceBusy => 'Meşgul';

  @override
  String get presenceDoNotDisturb => 'Rahatsız etmeyin';

  @override
  String get presenceBlocked => 'Engellendi';

  @override
  String get presenceOffline => 'Çevrimdışı';

  @override
  String get presenceOutOfOffice => 'İş yerinde değil';

  @override
  String get presenceUnknown => 'Bilinmiyor';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, iş yerinde değil';
  }
}

/// The translations for Turkish, as used in Cyprus (`tr_CY`).
class FluentLocalizationsTrCy extends FluentLocalizationsTr {
  FluentLocalizationsTrCy() : super('tr_CY');

  @override
  String get close => 'Kapat';

  @override
  String get dismiss => 'Kapat';

  @override
  String get clear => 'Temizle';

  @override
  String get open => 'Aç';

  @override
  String get remove => 'Kaldır';

  @override
  String get more => 'Daha fazla';

  @override
  String get overflowMore => 'daha';

  @override
  String get selectAllRows => 'Tüm satırları seç';

  @override
  String get selectRow => 'Satırı seç';

  @override
  String get sort => 'Sırala';

  @override
  String get sortedAscending => 'Artan düzende sıralandı';

  @override
  String get sortedDescending => 'Azalan düzende sıralandı';

  @override
  String get previousSlide => 'Önceki slayt';

  @override
  String get nextSlide => 'Sonraki slayt';

  @override
  String get startSlideShow => 'Otomatik slayt gösterisini başlat';

  @override
  String get pauseSlideShow => 'Otomatik slayt gösterisini duraklat';

  @override
  String slideOf(int index, int count) {
    return 'Slayt $index / $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Adım $index / $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$max üzerinden $value';
  }

  @override
  String get openCalendar => 'Takvimi aç';

  @override
  String get invalidDateFormat => 'Geçersiz tarih biçimi.';

  @override
  String get dateOutOfRange => 'Tarih izin verilen aralığın dışında.';

  @override
  String get fieldRequired => 'Bu alan zorunludur.';

  @override
  String get goToToday => 'Bugüne git';

  @override
  String get previousMonth => 'Önceki ay';

  @override
  String get nextMonth => 'Sonraki ay';

  @override
  String get previousYear => 'Önceki yıl';

  @override
  String get nextYear => 'Sonraki yıl';

  @override
  String get previousYearRange => 'Önceki yıl aralığı';

  @override
  String get nextYearRange => 'Sonraki yıl aralığı';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, yılı değiştir';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, ayı değiştir';
  }

  @override
  String selectedDate(String date) {
    return 'Seçili tarih $date';
  }

  @override
  String todaysDate(String date) {
    return 'Bugünün tarihi $date';
  }

  @override
  String weekNumber(String number) {
    return '$number. hafta';
  }

  @override
  String get chartNoData => 'Grafikte görüntülenecek veri yok';

  @override
  String get chartNoDataAvailable => 'Kullanılabilir veri yok';

  @override
  String get chartFallbackTitle => 'Grafik. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return '$axis ekseni $subject gösterir. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'ikincil Y';

  @override
  String get chartAxisCategories => 'kategorileri';

  @override
  String get chartAxisTime => 'zamanı';

  @override
  String get chartAxisValues => 'değerleri';

  @override
  String get chartLineLegendFallback => 'Çizgi';

  @override
  String funnelChartDescription(int count) {
    return '$count bölümlü huni grafiği';
  }

  @override
  String donutChartDescription(int count) {
    return '$count dilimli halka grafiği';
  }

  @override
  String gaugeChartDescription(int count) {
    return '$count bölümlü gösterge grafiği. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Geçerli değer: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Geçerli değer $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'En küçük değer: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'En büyük değer: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Bilinmiyor';

  @override
  String ganttChartDescription(int count) {
    return '$count veri noktalı Gantt grafiği. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return '$count veri noktalı ısı haritası grafiği. ';
  }

  @override
  String polarChartDescription(int count) {
    return '$count veri serili kutupsal grafik.';
  }

  @override
  String sparklineDescription(String label) {
    return '$label etiketli mini grafik';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return '$nodes düğüm ve $links bağlantı içeren Sankey grafiği';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Kaynak: $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return '$weight ağırlıklı $name düğümü';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return '$source kaynağından $target hedefine $weight ağırlıklı bağlantı';
  }

  @override
  String verticalBarChartDescription(int count) {
    return '$count çubuklu dikey çubuk grafiği. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return '$count çubuk ve 1 çizgi içeren dikey çubuk grafiği. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return '$count gruplandırılmış çubuk serisi içeren dikey çubuk grafiği. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return '$count gruplandırılmış çubuk serisi ve $lines çizgi serisi içeren dikey çubuk grafiği. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return '$count yığılmış çubuk içeren dikey çubuk grafiği. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return '$count yığılmış çubuk ve $lines çizgi içeren dikey çubuk grafiği. ';
  }

  @override
  String get presenceAvailable => 'Müsait';

  @override
  String get presenceAway => 'Uzakta';

  @override
  String get presenceBusy => 'Meşgul';

  @override
  String get presenceDoNotDisturb => 'Rahatsız etmeyin';

  @override
  String get presenceBlocked => 'Engellendi';

  @override
  String get presenceOffline => 'Çevrimdışı';

  @override
  String get presenceOutOfOffice => 'İş yerinde değil';

  @override
  String get presenceUnknown => 'Bilinmiyor';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, iş yerinde değil';
  }
}

/// The translations for Turkish, as used in Turkey (`tr_TR`).
class FluentLocalizationsTrTr extends FluentLocalizationsTr {
  FluentLocalizationsTrTr() : super('tr_TR');

  @override
  String get close => 'Kapat';

  @override
  String get dismiss => 'Kapat';

  @override
  String get clear => 'Temizle';

  @override
  String get open => 'Aç';

  @override
  String get remove => 'Kaldır';

  @override
  String get more => 'Daha fazla';

  @override
  String get overflowMore => 'daha';

  @override
  String get selectAllRows => 'Tüm satırları seç';

  @override
  String get selectRow => 'Satırı seç';

  @override
  String get sort => 'Sırala';

  @override
  String get sortedAscending => 'Artan düzende sıralandı';

  @override
  String get sortedDescending => 'Azalan düzende sıralandı';

  @override
  String get previousSlide => 'Önceki slayt';

  @override
  String get nextSlide => 'Sonraki slayt';

  @override
  String get startSlideShow => 'Otomatik slayt gösterisini başlat';

  @override
  String get pauseSlideShow => 'Otomatik slayt gösterisini duraklat';

  @override
  String slideOf(int index, int count) {
    return 'Slayt $index / $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Adım $index / $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$max üzerinden $value';
  }

  @override
  String get openCalendar => 'Takvimi aç';

  @override
  String get invalidDateFormat => 'Geçersiz tarih biçimi.';

  @override
  String get dateOutOfRange => 'Tarih izin verilen aralığın dışında.';

  @override
  String get fieldRequired => 'Bu alan zorunludur.';

  @override
  String get goToToday => 'Bugüne git';

  @override
  String get previousMonth => 'Önceki ay';

  @override
  String get nextMonth => 'Sonraki ay';

  @override
  String get previousYear => 'Önceki yıl';

  @override
  String get nextYear => 'Sonraki yıl';

  @override
  String get previousYearRange => 'Önceki yıl aralığı';

  @override
  String get nextYearRange => 'Sonraki yıl aralığı';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, yılı değiştir';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, ayı değiştir';
  }

  @override
  String selectedDate(String date) {
    return 'Seçili tarih $date';
  }

  @override
  String todaysDate(String date) {
    return 'Bugünün tarihi $date';
  }

  @override
  String weekNumber(String number) {
    return '$number. hafta';
  }

  @override
  String get chartNoData => 'Grafikte görüntülenecek veri yok';

  @override
  String get chartNoDataAvailable => 'Kullanılabilir veri yok';

  @override
  String get chartFallbackTitle => 'Grafik. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return '$axis ekseni $subject gösterir. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'ikincil Y';

  @override
  String get chartAxisCategories => 'kategorileri';

  @override
  String get chartAxisTime => 'zamanı';

  @override
  String get chartAxisValues => 'değerleri';

  @override
  String get chartLineLegendFallback => 'Çizgi';

  @override
  String funnelChartDescription(int count) {
    return '$count bölümlü huni grafiği';
  }

  @override
  String donutChartDescription(int count) {
    return '$count dilimli halka grafiği';
  }

  @override
  String gaugeChartDescription(int count) {
    return '$count bölümlü gösterge grafiği. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Geçerli değer: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Geçerli değer $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'En küçük değer: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'En büyük değer: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Bilinmiyor';

  @override
  String ganttChartDescription(int count) {
    return '$count veri noktalı Gantt grafiği. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return '$count veri noktalı ısı haritası grafiği. ';
  }

  @override
  String polarChartDescription(int count) {
    return '$count veri serili kutupsal grafik.';
  }

  @override
  String sparklineDescription(String label) {
    return '$label etiketli mini grafik';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return '$nodes düğüm ve $links bağlantı içeren Sankey grafiği';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Kaynak: $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return '$weight ağırlıklı $name düğümü';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return '$source kaynağından $target hedefine $weight ağırlıklı bağlantı';
  }

  @override
  String verticalBarChartDescription(int count) {
    return '$count çubuklu dikey çubuk grafiği. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return '$count çubuk ve 1 çizgi içeren dikey çubuk grafiği. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return '$count gruplandırılmış çubuk serisi içeren dikey çubuk grafiği. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return '$count gruplandırılmış çubuk serisi ve $lines çizgi serisi içeren dikey çubuk grafiği. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return '$count yığılmış çubuk içeren dikey çubuk grafiği. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return '$count yığılmış çubuk ve $lines çizgi içeren dikey çubuk grafiği. ';
  }

  @override
  String get presenceAvailable => 'Müsait';

  @override
  String get presenceAway => 'Uzakta';

  @override
  String get presenceBusy => 'Meşgul';

  @override
  String get presenceDoNotDisturb => 'Rahatsız etmeyin';

  @override
  String get presenceBlocked => 'Engellendi';

  @override
  String get presenceOffline => 'Çevrimdışı';

  @override
  String get presenceOutOfOffice => 'İş yerinde değil';

  @override
  String get presenceUnknown => 'Bilinmiyor';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, iş yerinde değil';
  }
}
