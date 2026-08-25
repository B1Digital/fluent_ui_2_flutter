// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fluent_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class FluentLocalizationsFa extends FluentLocalizations {
  FluentLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get close => 'بستن';

  @override
  String get dismiss => 'رد کردن';

  @override
  String get clear => 'پاک کردن';

  @override
  String get open => 'باز کردن';

  @override
  String get remove => 'حذف کردن';

  @override
  String get more => 'بیشتر';

  @override
  String get overflowMore => 'بیشتر';

  @override
  String get selectAllRows => 'انتخاب همه ردیف‌ها';

  @override
  String get selectRow => 'انتخاب ردیف';

  @override
  String get sort => 'مرتب‌سازی';

  @override
  String get sortedAscending => 'مرتب‌شده به‌صورت صعودی';

  @override
  String get sortedDescending => 'مرتب‌شده به‌صورت نزولی';

  @override
  String get previousSlide => 'اسلاید قبلی';

  @override
  String get nextSlide => 'اسلاید بعدی';

  @override
  String get startSlideShow => 'شروع نمایش خودکار اسلایدها';

  @override
  String get pauseSlideShow => 'توقف موقت نمایش خودکار اسلایدها';

  @override
  String slideOf(int index, int count) {
    return 'اسلاید $index از $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'مرحله $index از $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value از $max';
  }

  @override
  String get openCalendar => 'باز کردن تقویم';

  @override
  String get invalidDateFormat => 'قالب تاریخ نامعتبر است.';

  @override
  String get dateOutOfRange => 'تاریخ خارج از محدوده مجاز است.';

  @override
  String get fieldRequired => 'این فیلد الزامی است.';

  @override
  String get goToToday => 'رفتن به امروز';

  @override
  String get previousMonth => 'ماه قبل';

  @override
  String get nextMonth => 'ماه بعد';

  @override
  String get previousYear => 'سال قبل';

  @override
  String get nextYear => 'سال بعد';

  @override
  String get previousYearRange => 'محدوده سال قبل';

  @override
  String get nextYearRange => 'محدوده سال بعد';

  @override
  String monthPickerHeader(String caption) {
    return '$caption، تغییر سال';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption، تغییر ماه';
  }

  @override
  String selectedDate(String date) {
    return 'تاریخ انتخاب‌شده $date';
  }

  @override
  String todaysDate(String date) {
    return 'تاریخ امروز $date';
  }

  @override
  String weekNumber(String number) {
    return 'هفته $number';
  }

  @override
  String get chartNoData => 'نمودار داده‌ای برای نمایش ندارد';

  @override
  String get chartNoDataAvailable => 'داده‌ای موجود نیست';

  @override
  String get chartFallbackTitle => 'نمودار. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'محور $axis $subject را نشان می‌دهد. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y ثانویه';

  @override
  String get chartAxisCategories => 'دسته‌ها';

  @override
  String get chartAxisTime => 'زمان';

  @override
  String get chartAxisValues => 'مقادیر';

  @override
  String get chartLineLegendFallback => 'خط';

  @override
  String funnelChartDescription(int count) {
    return 'نمودار قیفی با $count بخش';
  }

  @override
  String donutChartDescription(int count) {
    return 'نمودار حلقه‌ای با $count بخش';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'نمودار عقربه‌ای با $count بخش. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'مقدار فعلی: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'مقدار فعلی $value است';
  }

  @override
  String gaugeMinValue(String value) {
    return 'کمترین مقدار: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'بیشترین مقدار: $value';
  }

  @override
  String get gaugeUnknownSegment => 'نامشخص';

  @override
  String ganttChartDescription(int count) {
    return 'نمودار گانت با $count نقطه داده. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'نمودار نقشه حرارتی با $count نقطه داده. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'نمودار قطبی با $count سری داده.';
  }

  @override
  String sparklineDescription(String label) {
    return 'ریزنمودار با برچسب $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'نمودار سنکی با $nodes گره و $links پیوند';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'از $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'گره $name با وزن $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'پیوند از $source به $target با وزن $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'نمودار میله‌ای عمودی با $count میله. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'نمودار میله‌ای عمودی با $count میله و 1 خط. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'نمودار میله‌ای عمودی با $count سری میله گروه‌بندی‌شده. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'نمودار میله‌ای عمودی با $count سری میله گروه‌بندی‌شده و $lines سری خط. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'نمودار میله‌ای عمودی با $count میله انباشته. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'نمودار میله‌ای عمودی با $count میله انباشته و $lines خط. ';
  }

  @override
  String get presenceAvailable => 'در دسترس';

  @override
  String get presenceAway => 'غایب';

  @override
  String get presenceBusy => 'مشغول';

  @override
  String get presenceDoNotDisturb => 'مزاحم نشوید';

  @override
  String get presenceBlocked => 'مسدود شده';

  @override
  String get presenceOffline => 'آفلاین';

  @override
  String get presenceOutOfOffice => 'خارج از دفتر';

  @override
  String get presenceUnknown => 'نامشخص';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status، خارج از دفتر';
  }
}

/// The translations for Persian, as used in Afghanistan (`fa_AF`).
class FluentLocalizationsFaAf extends FluentLocalizationsFa {
  FluentLocalizationsFaAf() : super('fa_AF');

  @override
  String get close => 'بستن';

  @override
  String get dismiss => 'رد کردن';

  @override
  String get clear => 'پاک کردن';

  @override
  String get open => 'باز کردن';

  @override
  String get remove => 'حذف کردن';

  @override
  String get more => 'بیشتر';

  @override
  String get overflowMore => 'بیشتر';

  @override
  String get selectAllRows => 'انتخاب همه ردیف‌ها';

  @override
  String get selectRow => 'انتخاب ردیف';

  @override
  String get sort => 'مرتب‌سازی';

  @override
  String get sortedAscending => 'مرتب‌شده به‌صورت صعودی';

  @override
  String get sortedDescending => 'مرتب‌شده به‌صورت نزولی';

  @override
  String get previousSlide => 'اسلاید قبلی';

  @override
  String get nextSlide => 'اسلاید بعدی';

  @override
  String get startSlideShow => 'شروع نمایش خودکار اسلایدها';

  @override
  String get pauseSlideShow => 'توقف موقت نمایش خودکار اسلایدها';

  @override
  String slideOf(int index, int count) {
    return 'اسلاید $index از $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'مرحله $index از $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value از $max';
  }

  @override
  String get openCalendar => 'باز کردن تقویم';

  @override
  String get invalidDateFormat => 'قالب تاریخ نامعتبر است.';

  @override
  String get dateOutOfRange => 'تاریخ خارج از محدوده مجاز است.';

  @override
  String get fieldRequired => 'این فیلد الزامی است.';

  @override
  String get goToToday => 'رفتن به امروز';

  @override
  String get previousMonth => 'ماه قبل';

  @override
  String get nextMonth => 'ماه بعد';

  @override
  String get previousYear => 'سال قبل';

  @override
  String get nextYear => 'سال بعد';

  @override
  String get previousYearRange => 'محدوده سال قبل';

  @override
  String get nextYearRange => 'محدوده سال بعد';

  @override
  String monthPickerHeader(String caption) {
    return '$caption، تغییر سال';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption، تغییر ماه';
  }

  @override
  String selectedDate(String date) {
    return 'تاریخ انتخاب‌شده $date';
  }

  @override
  String todaysDate(String date) {
    return 'تاریخ امروز $date';
  }

  @override
  String weekNumber(String number) {
    return 'هفته $number';
  }

  @override
  String get chartNoData => 'نمودار داده‌ای برای نمایش ندارد';

  @override
  String get chartNoDataAvailable => 'داده‌ای موجود نیست';

  @override
  String get chartFallbackTitle => 'نمودار. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'محور $axis $subject را نشان می‌دهد. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y ثانویه';

  @override
  String get chartAxisCategories => 'دسته‌ها';

  @override
  String get chartAxisTime => 'زمان';

  @override
  String get chartAxisValues => 'مقادیر';

  @override
  String get chartLineLegendFallback => 'خط';

  @override
  String funnelChartDescription(int count) {
    return 'نمودار قیفی با $count بخش';
  }

  @override
  String donutChartDescription(int count) {
    return 'نمودار حلقه‌ای با $count بخش';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'نمودار عقربه‌ای با $count بخش. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'مقدار فعلی: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'مقدار فعلی $value است';
  }

  @override
  String gaugeMinValue(String value) {
    return 'کمترین مقدار: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'بیشترین مقدار: $value';
  }

  @override
  String get gaugeUnknownSegment => 'نامشخص';

  @override
  String ganttChartDescription(int count) {
    return 'نمودار گانت با $count نقطه داده. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'نمودار نقشه حرارتی با $count نقطه داده. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'نمودار قطبی با $count سری داده.';
  }

  @override
  String sparklineDescription(String label) {
    return 'ریزنمودار با برچسب $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'نمودار سنکی با $nodes گره و $links پیوند';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'از $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'گره $name با وزن $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'پیوند از $source به $target با وزن $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'نمودار میله‌ای عمودی با $count میله. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'نمودار میله‌ای عمودی با $count میله و 1 خط. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'نمودار میله‌ای عمودی با $count سری میله گروه‌بندی‌شده. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'نمودار میله‌ای عمودی با $count سری میله گروه‌بندی‌شده و $lines سری خط. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'نمودار میله‌ای عمودی با $count میله انباشته. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'نمودار میله‌ای عمودی با $count میله انباشته و $lines خط. ';
  }

  @override
  String get presenceAvailable => 'در دسترس';

  @override
  String get presenceAway => 'غایب';

  @override
  String get presenceBusy => 'مشغول';

  @override
  String get presenceDoNotDisturb => 'مزاحم نشوید';

  @override
  String get presenceBlocked => 'مسدود شده';

  @override
  String get presenceOffline => 'آفلاین';

  @override
  String get presenceOutOfOffice => 'خارج از دفتر';

  @override
  String get presenceUnknown => 'نامشخص';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status، خارج از دفتر';
  }
}

/// The translations for Persian, as used in Islamic Republic of Iran (`fa_IR`).
class FluentLocalizationsFaIr extends FluentLocalizationsFa {
  FluentLocalizationsFaIr() : super('fa_IR');

  @override
  String get close => 'بستن';

  @override
  String get dismiss => 'رد کردن';

  @override
  String get clear => 'پاک کردن';

  @override
  String get open => 'باز کردن';

  @override
  String get remove => 'حذف کردن';

  @override
  String get more => 'بیشتر';

  @override
  String get overflowMore => 'بیشتر';

  @override
  String get selectAllRows => 'انتخاب همه ردیف‌ها';

  @override
  String get selectRow => 'انتخاب ردیف';

  @override
  String get sort => 'مرتب‌سازی';

  @override
  String get sortedAscending => 'مرتب‌شده به‌صورت صعودی';

  @override
  String get sortedDescending => 'مرتب‌شده به‌صورت نزولی';

  @override
  String get previousSlide => 'اسلاید قبلی';

  @override
  String get nextSlide => 'اسلاید بعدی';

  @override
  String get startSlideShow => 'شروع نمایش خودکار اسلایدها';

  @override
  String get pauseSlideShow => 'توقف موقت نمایش خودکار اسلایدها';

  @override
  String slideOf(int index, int count) {
    return 'اسلاید $index از $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'مرحله $index از $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value از $max';
  }

  @override
  String get openCalendar => 'باز کردن تقویم';

  @override
  String get invalidDateFormat => 'قالب تاریخ نامعتبر است.';

  @override
  String get dateOutOfRange => 'تاریخ خارج از محدوده مجاز است.';

  @override
  String get fieldRequired => 'این فیلد الزامی است.';

  @override
  String get goToToday => 'رفتن به امروز';

  @override
  String get previousMonth => 'ماه قبل';

  @override
  String get nextMonth => 'ماه بعد';

  @override
  String get previousYear => 'سال قبل';

  @override
  String get nextYear => 'سال بعد';

  @override
  String get previousYearRange => 'محدوده سال قبل';

  @override
  String get nextYearRange => 'محدوده سال بعد';

  @override
  String monthPickerHeader(String caption) {
    return '$caption، تغییر سال';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption، تغییر ماه';
  }

  @override
  String selectedDate(String date) {
    return 'تاریخ انتخاب‌شده $date';
  }

  @override
  String todaysDate(String date) {
    return 'تاریخ امروز $date';
  }

  @override
  String weekNumber(String number) {
    return 'هفته $number';
  }

  @override
  String get chartNoData => 'نمودار داده‌ای برای نمایش ندارد';

  @override
  String get chartNoDataAvailable => 'داده‌ای موجود نیست';

  @override
  String get chartFallbackTitle => 'نمودار. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'محور $axis $subject را نشان می‌دهد. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y ثانویه';

  @override
  String get chartAxisCategories => 'دسته‌ها';

  @override
  String get chartAxisTime => 'زمان';

  @override
  String get chartAxisValues => 'مقادیر';

  @override
  String get chartLineLegendFallback => 'خط';

  @override
  String funnelChartDescription(int count) {
    return 'نمودار قیفی با $count بخش';
  }

  @override
  String donutChartDescription(int count) {
    return 'نمودار حلقه‌ای با $count بخش';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'نمودار عقربه‌ای با $count بخش. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'مقدار فعلی: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'مقدار فعلی $value است';
  }

  @override
  String gaugeMinValue(String value) {
    return 'کمترین مقدار: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'بیشترین مقدار: $value';
  }

  @override
  String get gaugeUnknownSegment => 'نامشخص';

  @override
  String ganttChartDescription(int count) {
    return 'نمودار گانت با $count نقطه داده. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'نمودار نقشه حرارتی با $count نقطه داده. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'نمودار قطبی با $count سری داده.';
  }

  @override
  String sparklineDescription(String label) {
    return 'ریزنمودار با برچسب $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'نمودار سنکی با $nodes گره و $links پیوند';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'از $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'گره $name با وزن $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'پیوند از $source به $target با وزن $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'نمودار میله‌ای عمودی با $count میله. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'نمودار میله‌ای عمودی با $count میله و 1 خط. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'نمودار میله‌ای عمودی با $count سری میله گروه‌بندی‌شده. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'نمودار میله‌ای عمودی با $count سری میله گروه‌بندی‌شده و $lines سری خط. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'نمودار میله‌ای عمودی با $count میله انباشته. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'نمودار میله‌ای عمودی با $count میله انباشته و $lines خط. ';
  }

  @override
  String get presenceAvailable => 'در دسترس';

  @override
  String get presenceAway => 'غایب';

  @override
  String get presenceBusy => 'مشغول';

  @override
  String get presenceDoNotDisturb => 'مزاحم نشوید';

  @override
  String get presenceBlocked => 'مسدود شده';

  @override
  String get presenceOffline => 'آفلاین';

  @override
  String get presenceOutOfOffice => 'خارج از دفتر';

  @override
  String get presenceUnknown => 'نامشخص';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status، خارج از دفتر';
  }
}
