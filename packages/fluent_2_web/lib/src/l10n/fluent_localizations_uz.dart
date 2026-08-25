// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fluent_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class FluentLocalizationsUz extends FluentLocalizations {
  FluentLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get close => 'Yopish';

  @override
  String get dismiss => 'Rad etish';

  @override
  String get clear => 'Tozalash';

  @override
  String get open => 'Ochish';

  @override
  String get remove => 'Olib tashlash';

  @override
  String get more => 'Koʻproq';

  @override
  String get overflowMore => 'yana';

  @override
  String get selectAllRows => 'Barcha qatorlarni tanlash';

  @override
  String get selectRow => 'Qatorni tanlash';

  @override
  String get sort => 'Saralash';

  @override
  String get sortedAscending => 'Oʻsish tartibida saralangan';

  @override
  String get sortedDescending => 'Kamayish tartibida saralangan';

  @override
  String get previousSlide => 'Oldingi slayd';

  @override
  String get nextSlide => 'Keyingi slayd';

  @override
  String get startSlideShow => 'Avtomatik slayd-shouni boshlash';

  @override
  String get pauseSlideShow => 'Avtomatik slayd-shouni toʻxtatib turish';

  @override
  String slideOf(int index, int count) {
    return '$count slayddan $index-si';
  }

  @override
  String stepOf(int index, int count) {
    return '$count qadamdan $index-si';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$max dan $value';
  }

  @override
  String get openCalendar => 'Taqvimni ochish';

  @override
  String get invalidDateFormat => 'Sana formati notoʻgʻri.';

  @override
  String get dateOutOfRange => 'Sana ruxsat etilgan oraliqdan tashqarida.';

  @override
  String get fieldRequired => 'Bu maydonni toʻldirish shart.';

  @override
  String get goToToday => 'Bugunga oʻtish';

  @override
  String get previousMonth => 'Oldingi oy';

  @override
  String get nextMonth => 'Keyingi oy';

  @override
  String get previousYear => 'Oldingi yil';

  @override
  String get nextYear => 'Keyingi yil';

  @override
  String get previousYearRange => 'Oldingi yillar oraligʻi';

  @override
  String get nextYearRange => 'Keyingi yillar oraligʻi';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, yilni oʻzgartirish';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, oyni oʻzgartirish';
  }

  @override
  String selectedDate(String date) {
    return 'Tanlangan sana $date';
  }

  @override
  String todaysDate(String date) {
    return 'Bugungi sana $date';
  }

  @override
  String weekNumber(String number) {
    return '$number-hafta';
  }

  @override
  String get chartNoData => 'Grafikda koʻrsatish uchun maʼlumot yoʻq';

  @override
  String get chartNoDataAvailable => 'Maʼlumot mavjud emas';

  @override
  String get chartFallbackTitle => 'Diagramma. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return '$axis oʻqi ${subject}ni koʻrsatadi. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'ikkilamchi Y';

  @override
  String get chartAxisCategories => 'toifalar';

  @override
  String get chartAxisTime => 'vaqt';

  @override
  String get chartAxisValues => 'qiymatlar';

  @override
  String get chartLineLegendFallback => 'Chiziq';

  @override
  String funnelChartDescription(int count) {
    return '$count ta segmentga ega voronka diagrammasi';
  }

  @override
  String donutChartDescription(int count) {
    return '$count ta boʻlakka ega halqa diagrammasi';
  }

  @override
  String gaugeChartDescription(int count) {
    return '$count ta segmentga ega oʻlchagich diagrammasi. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Joriy qiymat: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Joriy qiymat $value ga teng';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Eng kichik qiymat: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Eng katta qiymat: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Nomaʼlum';

  @override
  String ganttChartDescription(int count) {
    return '$count ta maʼlumot nuqtasiga ega Gantt diagrammasi. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return '$count ta maʼlumot nuqtasiga ega issiqlik xaritasi diagrammasi. ';
  }

  @override
  String polarChartDescription(int count) {
    return '$count ta maʼlumotlar seriyasiga ega qutb diagrammasi.';
  }

  @override
  String sparklineDescription(String label) {
    return '$label yorligʻiga ega mini diagramma';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return '$nodes ta tugun va $links ta bogʻlanishga ega Sankey diagrammasi';
  }

  @override
  String sankeyLinkFrom(String node) {
    return '$node dan';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'vazni $weight boʻlgan $name tuguni';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'vazni $weight boʻlgan $source dan $target ga bogʻlanish';
  }

  @override
  String verticalBarChartDescription(int count) {
    return '$count ta ustunga ega vertikal ustunli diagramma. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return '$count ta ustun va 1 ta chiziqqa ega vertikal ustunli diagramma. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return '$count ta guruhlangan ustun seriyasiga ega vertikal ustunli diagramma. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return '$count ta guruhlangan ustun seriyasi va $lines ta chiziq seriyasiga ega vertikal ustunli diagramma. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return '$count ta toʻplangan ustunga ega vertikal ustunli diagramma. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return '$count ta toʻplangan ustun va $lines ta chiziqqa ega vertikal ustunli diagramma. ';
  }

  @override
  String get presenceAvailable => 'Boʻsh';

  @override
  String get presenceAway => 'Joyida yoʻq';

  @override
  String get presenceBusy => 'Band';

  @override
  String get presenceDoNotDisturb => 'Bezovta qilmang';

  @override
  String get presenceBlocked => 'Bloklangan';

  @override
  String get presenceOffline => 'Oflayn';

  @override
  String get presenceOutOfOffice => 'Ofisdan tashqarida';

  @override
  String get presenceUnknown => 'Nomaʼlum';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, ofisdan tashqarida';
  }
}

/// The translations for Uzbek, as used in Uzbekistan (`uz_UZ`).
class FluentLocalizationsUzUz extends FluentLocalizationsUz {
  FluentLocalizationsUzUz() : super('uz_UZ');

  @override
  String get close => 'Yopish';

  @override
  String get dismiss => 'Rad etish';

  @override
  String get clear => 'Tozalash';

  @override
  String get open => 'Ochish';

  @override
  String get remove => 'Olib tashlash';

  @override
  String get more => 'Koʻproq';

  @override
  String get overflowMore => 'yana';

  @override
  String get selectAllRows => 'Barcha qatorlarni tanlash';

  @override
  String get selectRow => 'Qatorni tanlash';

  @override
  String get sort => 'Saralash';

  @override
  String get sortedAscending => 'Oʻsish tartibida saralangan';

  @override
  String get sortedDescending => 'Kamayish tartibida saralangan';

  @override
  String get previousSlide => 'Oldingi slayd';

  @override
  String get nextSlide => 'Keyingi slayd';

  @override
  String get startSlideShow => 'Avtomatik slayd-shouni boshlash';

  @override
  String get pauseSlideShow => 'Avtomatik slayd-shouni toʻxtatib turish';

  @override
  String slideOf(int index, int count) {
    return '$count slayddan $index-si';
  }

  @override
  String stepOf(int index, int count) {
    return '$count qadamdan $index-si';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$max dan $value';
  }

  @override
  String get openCalendar => 'Taqvimni ochish';

  @override
  String get invalidDateFormat => 'Sana formati notoʻgʻri.';

  @override
  String get dateOutOfRange => 'Sana ruxsat etilgan oraliqdan tashqarida.';

  @override
  String get fieldRequired => 'Bu maydonni toʻldirish shart.';

  @override
  String get goToToday => 'Bugunga oʻtish';

  @override
  String get previousMonth => 'Oldingi oy';

  @override
  String get nextMonth => 'Keyingi oy';

  @override
  String get previousYear => 'Oldingi yil';

  @override
  String get nextYear => 'Keyingi yil';

  @override
  String get previousYearRange => 'Oldingi yillar oraligʻi';

  @override
  String get nextYearRange => 'Keyingi yillar oraligʻi';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, yilni oʻzgartirish';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, oyni oʻzgartirish';
  }

  @override
  String selectedDate(String date) {
    return 'Tanlangan sana $date';
  }

  @override
  String todaysDate(String date) {
    return 'Bugungi sana $date';
  }

  @override
  String weekNumber(String number) {
    return '$number-hafta';
  }

  @override
  String get chartNoData => 'Grafikda koʻrsatish uchun maʼlumot yoʻq';

  @override
  String get chartNoDataAvailable => 'Maʼlumot mavjud emas';

  @override
  String get chartFallbackTitle => 'Diagramma. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return '$axis oʻqi ${subject}ni koʻrsatadi. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'ikkilamchi Y';

  @override
  String get chartAxisCategories => 'toifalar';

  @override
  String get chartAxisTime => 'vaqt';

  @override
  String get chartAxisValues => 'qiymatlar';

  @override
  String get chartLineLegendFallback => 'Chiziq';

  @override
  String funnelChartDescription(int count) {
    return '$count ta segmentga ega voronka diagrammasi';
  }

  @override
  String donutChartDescription(int count) {
    return '$count ta boʻlakka ega halqa diagrammasi';
  }

  @override
  String gaugeChartDescription(int count) {
    return '$count ta segmentga ega oʻlchagich diagrammasi. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Joriy qiymat: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Joriy qiymat $value ga teng';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Eng kichik qiymat: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Eng katta qiymat: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Nomaʼlum';

  @override
  String ganttChartDescription(int count) {
    return '$count ta maʼlumot nuqtasiga ega Gantt diagrammasi. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return '$count ta maʼlumot nuqtasiga ega issiqlik xaritasi diagrammasi. ';
  }

  @override
  String polarChartDescription(int count) {
    return '$count ta maʼlumotlar seriyasiga ega qutb diagrammasi.';
  }

  @override
  String sparklineDescription(String label) {
    return '$label yorligʻiga ega mini diagramma';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return '$nodes ta tugun va $links ta bogʻlanishga ega Sankey diagrammasi';
  }

  @override
  String sankeyLinkFrom(String node) {
    return '$node dan';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'vazni $weight boʻlgan $name tuguni';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'vazni $weight boʻlgan $source dan $target ga bogʻlanish';
  }

  @override
  String verticalBarChartDescription(int count) {
    return '$count ta ustunga ega vertikal ustunli diagramma. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return '$count ta ustun va 1 ta chiziqqa ega vertikal ustunli diagramma. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return '$count ta guruhlangan ustun seriyasiga ega vertikal ustunli diagramma. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return '$count ta guruhlangan ustun seriyasi va $lines ta chiziq seriyasiga ega vertikal ustunli diagramma. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return '$count ta toʻplangan ustunga ega vertikal ustunli diagramma. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return '$count ta toʻplangan ustun va $lines ta chiziqqa ega vertikal ustunli diagramma. ';
  }

  @override
  String get presenceAvailable => 'Boʻsh';

  @override
  String get presenceAway => 'Joyida yoʻq';

  @override
  String get presenceBusy => 'Band';

  @override
  String get presenceDoNotDisturb => 'Bezovta qilmang';

  @override
  String get presenceBlocked => 'Bloklangan';

  @override
  String get presenceOffline => 'Oflayn';

  @override
  String get presenceOutOfOffice => 'Ofisdan tashqarida';

  @override
  String get presenceUnknown => 'Nomaʼlum';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, ofisdan tashqarida';
  }
}
