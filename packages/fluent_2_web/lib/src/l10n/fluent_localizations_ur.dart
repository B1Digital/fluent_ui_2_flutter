// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fluent_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class FluentLocalizationsUr extends FluentLocalizations {
  FluentLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get close => 'بند کریں';

  @override
  String get dismiss => 'برخاست کریں';

  @override
  String get clear => 'صاف کریں';

  @override
  String get open => 'کھولیں';

  @override
  String get remove => 'ہٹائیں';

  @override
  String get more => 'مزید';

  @override
  String get overflowMore => 'مزید';

  @override
  String get selectAllRows => 'تمام قطاریں منتخب کریں';

  @override
  String get selectRow => 'قطار منتخب کریں';

  @override
  String get sort => 'ترتیب دیں';

  @override
  String get sortedAscending => 'صعودی ترتیب شدہ';

  @override
  String get sortedDescending => 'نزولی ترتیب شدہ';

  @override
  String get previousSlide => 'پچھلی سلائیڈ';

  @override
  String get nextSlide => 'اگلی سلائیڈ';

  @override
  String get startSlideShow => 'خودکار سلائیڈ شو شروع کریں';

  @override
  String get pauseSlideShow => 'خودکار سلائیڈ شو موقوف کریں';

  @override
  String slideOf(int index, int count) {
    return '$count میں سے سلائیڈ $index';
  }

  @override
  String stepOf(int index, int count) {
    return '$count میں سے مرحلہ $index';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$max میں سے $value';
  }

  @override
  String get openCalendar => 'کیلنڈر کھولیں';

  @override
  String get invalidDateFormat => 'تاریخ کا فارمیٹ غلط ہے۔';

  @override
  String get dateOutOfRange => 'تاریخ مجاز حد سے باہر ہے۔';

  @override
  String get fieldRequired => 'یہ فیلڈ درکار ہے۔';

  @override
  String get goToToday => 'آج پر جائیں';

  @override
  String get previousMonth => 'پچھلا مہینہ';

  @override
  String get nextMonth => 'اگلا مہینہ';

  @override
  String get previousYear => 'پچھلا سال';

  @override
  String get nextYear => 'اگلا سال';

  @override
  String get previousYearRange => 'سالوں کی پچھلی حد';

  @override
  String get nextYearRange => 'سالوں کی اگلی حد';

  @override
  String monthPickerHeader(String caption) {
    return '$caption، سال تبدیل کریں';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption، مہینہ تبدیل کریں';
  }

  @override
  String selectedDate(String date) {
    return 'منتخب کردہ تاریخ $date';
  }

  @override
  String todaysDate(String date) {
    return 'آج کی تاریخ $date';
  }

  @override
  String weekNumber(String number) {
    return 'ہفتہ $number';
  }

  @override
  String get chartNoData => 'گراف میں دکھانے کے لیے کوئی ڈیٹا نہیں ہے';

  @override
  String get chartNoDataAvailable => 'کوئی ڈیٹا دستیاب نہیں';

  @override
  String get chartFallbackTitle => 'چارٹ۔ ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return '$axis محور $subject دکھاتا ہے۔ ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'ثانوی Y';

  @override
  String get chartAxisCategories => 'زمرے';

  @override
  String get chartAxisTime => 'وقت';

  @override
  String get chartAxisValues => 'اقدار';

  @override
  String get chartLineLegendFallback => 'لکیر';

  @override
  String funnelChartDescription(int count) {
    return 'فنل چارٹ جس میں $count حصے ہیں';
  }

  @override
  String donutChartDescription(int count) {
    return 'ڈونٹ چارٹ جس میں $count ٹکڑے ہیں';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'گیج چارٹ جس میں $count حصے ہیں۔ ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'موجودہ قدر: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'موجودہ قدر $value ہے';
  }

  @override
  String gaugeMinValue(String value) {
    return 'کم از کم قدر: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'زیادہ سے زیادہ قدر: $value';
  }

  @override
  String get gaugeUnknownSegment => 'نامعلوم';

  @override
  String ganttChartDescription(int count) {
    return 'گانٹ چارٹ جس میں $count ڈیٹا پوائنٹس ہیں۔ ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'ہیٹ میپ چارٹ جس میں $count ڈیٹا پوائنٹس ہیں۔ ';
  }

  @override
  String polarChartDescription(int count) {
    return 'قطبی چارٹ جس میں $count ڈیٹا سیریز ہیں۔';
  }

  @override
  String sparklineDescription(String label) {
    return 'اسپارک لائن جس کا لیبل $label ہے';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'سینکی چارٹ جس میں $nodes نوڈز اور $links روابط ہیں';
  }

  @override
  String sankeyLinkFrom(String node) {
    return '$node سے';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'نوڈ $name جس کا وزن $weight ہے';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return '$source سے $target تک ربط جس کا وزن $weight ہے';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'عمودی بار چارٹ جس میں $count بارز ہیں۔ ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'عمودی بار چارٹ جس میں $count بارز اور 1 لکیر ہے۔ ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'عمودی بار چارٹ جس میں $count گروپ شدہ بار سیریز ہیں۔ ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'عمودی بار چارٹ جس میں $count گروپ شدہ بار سیریز اور $lines لکیر سیریز ہیں۔ ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'عمودی بار چارٹ جس میں $count اسٹیکڈ بارز ہیں۔ ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'عمودی بار چارٹ جس میں $count اسٹیکڈ بارز اور $lines لکیریں ہیں۔ ';
  }

  @override
  String get presenceAvailable => 'دستیاب';

  @override
  String get presenceAway => 'دور';

  @override
  String get presenceBusy => 'مصروف';

  @override
  String get presenceDoNotDisturb => 'پریشان نہ کریں';

  @override
  String get presenceBlocked => 'مسدود';

  @override
  String get presenceOffline => 'آف لائن';

  @override
  String get presenceOutOfOffice => 'دفتر سے باہر';

  @override
  String get presenceUnknown => 'نامعلوم';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status، دفتر سے باہر';
  }
}

/// The translations for Urdu, as used in India (`ur_IN`).
class FluentLocalizationsUrIn extends FluentLocalizationsUr {
  FluentLocalizationsUrIn() : super('ur_IN');

  @override
  String get close => 'بند کریں';

  @override
  String get dismiss => 'برخاست کریں';

  @override
  String get clear => 'صاف کریں';

  @override
  String get open => 'کھولیں';

  @override
  String get remove => 'ہٹائیں';

  @override
  String get more => 'مزید';

  @override
  String get overflowMore => 'مزید';

  @override
  String get selectAllRows => 'تمام قطاریں منتخب کریں';

  @override
  String get selectRow => 'قطار منتخب کریں';

  @override
  String get sort => 'ترتیب دیں';

  @override
  String get sortedAscending => 'صعودی ترتیب شدہ';

  @override
  String get sortedDescending => 'نزولی ترتیب شدہ';

  @override
  String get previousSlide => 'پچھلی سلائیڈ';

  @override
  String get nextSlide => 'اگلی سلائیڈ';

  @override
  String get startSlideShow => 'خودکار سلائیڈ شو شروع کریں';

  @override
  String get pauseSlideShow => 'خودکار سلائیڈ شو موقوف کریں';

  @override
  String slideOf(int index, int count) {
    return '$count میں سے سلائیڈ $index';
  }

  @override
  String stepOf(int index, int count) {
    return '$count میں سے مرحلہ $index';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$max میں سے $value';
  }

  @override
  String get openCalendar => 'کیلنڈر کھولیں';

  @override
  String get invalidDateFormat => 'تاریخ کا فارمیٹ غلط ہے۔';

  @override
  String get dateOutOfRange => 'تاریخ مجاز حد سے باہر ہے۔';

  @override
  String get fieldRequired => 'یہ فیلڈ درکار ہے۔';

  @override
  String get goToToday => 'آج پر جائیں';

  @override
  String get previousMonth => 'پچھلا مہینہ';

  @override
  String get nextMonth => 'اگلا مہینہ';

  @override
  String get previousYear => 'پچھلا سال';

  @override
  String get nextYear => 'اگلا سال';

  @override
  String get previousYearRange => 'سالوں کی پچھلی حد';

  @override
  String get nextYearRange => 'سالوں کی اگلی حد';

  @override
  String monthPickerHeader(String caption) {
    return '$caption، سال تبدیل کریں';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption، مہینہ تبدیل کریں';
  }

  @override
  String selectedDate(String date) {
    return 'منتخب کردہ تاریخ $date';
  }

  @override
  String todaysDate(String date) {
    return 'آج کی تاریخ $date';
  }

  @override
  String weekNumber(String number) {
    return 'ہفتہ $number';
  }

  @override
  String get chartNoData => 'گراف میں دکھانے کے لیے کوئی ڈیٹا نہیں ہے';

  @override
  String get chartNoDataAvailable => 'کوئی ڈیٹا دستیاب نہیں';

  @override
  String get chartFallbackTitle => 'چارٹ۔ ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return '$axis محور $subject دکھاتا ہے۔ ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'ثانوی Y';

  @override
  String get chartAxisCategories => 'زمرے';

  @override
  String get chartAxisTime => 'وقت';

  @override
  String get chartAxisValues => 'اقدار';

  @override
  String get chartLineLegendFallback => 'لکیر';

  @override
  String funnelChartDescription(int count) {
    return 'فنل چارٹ جس میں $count حصے ہیں';
  }

  @override
  String donutChartDescription(int count) {
    return 'ڈونٹ چارٹ جس میں $count ٹکڑے ہیں';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'گیج چارٹ جس میں $count حصے ہیں۔ ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'موجودہ قدر: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'موجودہ قدر $value ہے';
  }

  @override
  String gaugeMinValue(String value) {
    return 'کم از کم قدر: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'زیادہ سے زیادہ قدر: $value';
  }

  @override
  String get gaugeUnknownSegment => 'نامعلوم';

  @override
  String ganttChartDescription(int count) {
    return 'گانٹ چارٹ جس میں $count ڈیٹا پوائنٹس ہیں۔ ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'ہیٹ میپ چارٹ جس میں $count ڈیٹا پوائنٹس ہیں۔ ';
  }

  @override
  String polarChartDescription(int count) {
    return 'قطبی چارٹ جس میں $count ڈیٹا سیریز ہیں۔';
  }

  @override
  String sparklineDescription(String label) {
    return 'اسپارک لائن جس کا لیبل $label ہے';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'سینکی چارٹ جس میں $nodes نوڈز اور $links روابط ہیں';
  }

  @override
  String sankeyLinkFrom(String node) {
    return '$node سے';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'نوڈ $name جس کا وزن $weight ہے';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return '$source سے $target تک ربط جس کا وزن $weight ہے';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'عمودی بار چارٹ جس میں $count بارز ہیں۔ ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'عمودی بار چارٹ جس میں $count بارز اور 1 لکیر ہے۔ ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'عمودی بار چارٹ جس میں $count گروپ شدہ بار سیریز ہیں۔ ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'عمودی بار چارٹ جس میں $count گروپ شدہ بار سیریز اور $lines لکیر سیریز ہیں۔ ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'عمودی بار چارٹ جس میں $count اسٹیکڈ بارز ہیں۔ ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'عمودی بار چارٹ جس میں $count اسٹیکڈ بارز اور $lines لکیریں ہیں۔ ';
  }

  @override
  String get presenceAvailable => 'دستیاب';

  @override
  String get presenceAway => 'دور';

  @override
  String get presenceBusy => 'مصروف';

  @override
  String get presenceDoNotDisturb => 'پریشان نہ کریں';

  @override
  String get presenceBlocked => 'مسدود';

  @override
  String get presenceOffline => 'آف لائن';

  @override
  String get presenceOutOfOffice => 'دفتر سے باہر';

  @override
  String get presenceUnknown => 'نامعلوم';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status، دفتر سے باہر';
  }
}

/// The translations for Urdu, as used in Pakistan (`ur_PK`).
class FluentLocalizationsUrPk extends FluentLocalizationsUr {
  FluentLocalizationsUrPk() : super('ur_PK');

  @override
  String get close => 'بند کریں';

  @override
  String get dismiss => 'برخاست کریں';

  @override
  String get clear => 'صاف کریں';

  @override
  String get open => 'کھولیں';

  @override
  String get remove => 'ہٹائیں';

  @override
  String get more => 'مزید';

  @override
  String get overflowMore => 'مزید';

  @override
  String get selectAllRows => 'تمام قطاریں منتخب کریں';

  @override
  String get selectRow => 'قطار منتخب کریں';

  @override
  String get sort => 'ترتیب دیں';

  @override
  String get sortedAscending => 'صعودی ترتیب شدہ';

  @override
  String get sortedDescending => 'نزولی ترتیب شدہ';

  @override
  String get previousSlide => 'پچھلی سلائیڈ';

  @override
  String get nextSlide => 'اگلی سلائیڈ';

  @override
  String get startSlideShow => 'خودکار سلائیڈ شو شروع کریں';

  @override
  String get pauseSlideShow => 'خودکار سلائیڈ شو موقوف کریں';

  @override
  String slideOf(int index, int count) {
    return '$count میں سے سلائیڈ $index';
  }

  @override
  String stepOf(int index, int count) {
    return '$count میں سے مرحلہ $index';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$max میں سے $value';
  }

  @override
  String get openCalendar => 'کیلنڈر کھولیں';

  @override
  String get invalidDateFormat => 'تاریخ کا فارمیٹ غلط ہے۔';

  @override
  String get dateOutOfRange => 'تاریخ مجاز حد سے باہر ہے۔';

  @override
  String get fieldRequired => 'یہ فیلڈ درکار ہے۔';

  @override
  String get goToToday => 'آج پر جائیں';

  @override
  String get previousMonth => 'پچھلا مہینہ';

  @override
  String get nextMonth => 'اگلا مہینہ';

  @override
  String get previousYear => 'پچھلا سال';

  @override
  String get nextYear => 'اگلا سال';

  @override
  String get previousYearRange => 'سالوں کی پچھلی حد';

  @override
  String get nextYearRange => 'سالوں کی اگلی حد';

  @override
  String monthPickerHeader(String caption) {
    return '$caption، سال تبدیل کریں';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption، مہینہ تبدیل کریں';
  }

  @override
  String selectedDate(String date) {
    return 'منتخب کردہ تاریخ $date';
  }

  @override
  String todaysDate(String date) {
    return 'آج کی تاریخ $date';
  }

  @override
  String weekNumber(String number) {
    return 'ہفتہ $number';
  }

  @override
  String get chartNoData => 'گراف میں دکھانے کے لیے کوئی ڈیٹا نہیں ہے';

  @override
  String get chartNoDataAvailable => 'کوئی ڈیٹا دستیاب نہیں';

  @override
  String get chartFallbackTitle => 'چارٹ۔ ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return '$axis محور $subject دکھاتا ہے۔ ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'ثانوی Y';

  @override
  String get chartAxisCategories => 'زمرے';

  @override
  String get chartAxisTime => 'وقت';

  @override
  String get chartAxisValues => 'اقدار';

  @override
  String get chartLineLegendFallback => 'لکیر';

  @override
  String funnelChartDescription(int count) {
    return 'فنل چارٹ جس میں $count حصے ہیں';
  }

  @override
  String donutChartDescription(int count) {
    return 'ڈونٹ چارٹ جس میں $count ٹکڑے ہیں';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'گیج چارٹ جس میں $count حصے ہیں۔ ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'موجودہ قدر: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'موجودہ قدر $value ہے';
  }

  @override
  String gaugeMinValue(String value) {
    return 'کم از کم قدر: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'زیادہ سے زیادہ قدر: $value';
  }

  @override
  String get gaugeUnknownSegment => 'نامعلوم';

  @override
  String ganttChartDescription(int count) {
    return 'گانٹ چارٹ جس میں $count ڈیٹا پوائنٹس ہیں۔ ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'ہیٹ میپ چارٹ جس میں $count ڈیٹا پوائنٹس ہیں۔ ';
  }

  @override
  String polarChartDescription(int count) {
    return 'قطبی چارٹ جس میں $count ڈیٹا سیریز ہیں۔';
  }

  @override
  String sparklineDescription(String label) {
    return 'اسپارک لائن جس کا لیبل $label ہے';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'سینکی چارٹ جس میں $nodes نوڈز اور $links روابط ہیں';
  }

  @override
  String sankeyLinkFrom(String node) {
    return '$node سے';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'نوڈ $name جس کا وزن $weight ہے';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return '$source سے $target تک ربط جس کا وزن $weight ہے';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'عمودی بار چارٹ جس میں $count بارز ہیں۔ ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'عمودی بار چارٹ جس میں $count بارز اور 1 لکیر ہے۔ ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'عمودی بار چارٹ جس میں $count گروپ شدہ بار سیریز ہیں۔ ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'عمودی بار چارٹ جس میں $count گروپ شدہ بار سیریز اور $lines لکیر سیریز ہیں۔ ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'عمودی بار چارٹ جس میں $count اسٹیکڈ بارز ہیں۔ ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'عمودی بار چارٹ جس میں $count اسٹیکڈ بارز اور $lines لکیریں ہیں۔ ';
  }

  @override
  String get presenceAvailable => 'دستیاب';

  @override
  String get presenceAway => 'دور';

  @override
  String get presenceBusy => 'مصروف';

  @override
  String get presenceDoNotDisturb => 'پریشان نہ کریں';

  @override
  String get presenceBlocked => 'مسدود';

  @override
  String get presenceOffline => 'آف لائن';

  @override
  String get presenceOutOfOffice => 'دفتر سے باہر';

  @override
  String get presenceUnknown => 'نامعلوم';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status، دفتر سے باہر';
  }
}
