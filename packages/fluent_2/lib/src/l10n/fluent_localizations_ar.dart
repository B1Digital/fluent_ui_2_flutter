// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fluent_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class FluentLocalizationsAr extends FluentLocalizations {
  FluentLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get close => 'إغلاق';

  @override
  String get dismiss => 'تجاهل';

  @override
  String get clear => 'مسح';

  @override
  String get open => 'فتح';

  @override
  String get remove => 'إزالة';

  @override
  String get more => 'المزيد';

  @override
  String get overflowMore => 'إضافية';

  @override
  String get selectAllRows => 'تحديد كل الصفوف';

  @override
  String get selectRow => 'تحديد الصف';

  @override
  String get sort => 'فرز';

  @override
  String get sortedAscending => 'تم الفرز تصاعديًا';

  @override
  String get sortedDescending => 'تم الفرز تنازليًا';

  @override
  String get previousSlide => 'الشريحة السابقة';

  @override
  String get nextSlide => 'الشريحة التالية';

  @override
  String get startSlideShow => 'بدء عرض الشرائح التلقائي';

  @override
  String get pauseSlideShow => 'إيقاف عرض الشرائح التلقائي مؤقتًا';

  @override
  String slideOf(int index, int count) {
    return 'الشريحة $index من $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'الخطوة $index من $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value من $max';
  }

  @override
  String get openCalendar => 'فتح التقويم';

  @override
  String get invalidDateFormat => 'تنسيق التاريخ غير صالح.';

  @override
  String get dateOutOfRange => 'التاريخ خارج النطاق المسموح به.';

  @override
  String get fieldRequired => 'هذا الحقل مطلوب.';

  @override
  String get goToToday => 'الانتقال إلى اليوم';

  @override
  String get previousMonth => 'الشهر السابق';

  @override
  String get nextMonth => 'الشهر التالي';

  @override
  String get previousYear => 'السنة السابقة';

  @override
  String get nextYear => 'السنة التالية';

  @override
  String get previousYearRange => 'نطاق السنوات السابق';

  @override
  String get nextYearRange => 'نطاق السنوات التالي';

  @override
  String monthPickerHeader(String caption) {
    return '$caption، تغيير السنة';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption، تغيير الشهر';
  }

  @override
  String selectedDate(String date) {
    return 'التاريخ المحدد $date';
  }

  @override
  String todaysDate(String date) {
    return 'تاريخ اليوم $date';
  }

  @override
  String weekNumber(String number) {
    return 'الأسبوع $number';
  }

  @override
  String get chartNoData => 'لا يحتوي الرسم البياني على بيانات لعرضها';

  @override
  String get chartNoDataAvailable => 'لا تتوفر بيانات';

  @override
  String get chartFallbackTitle => 'مخطط. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'يعرض المحور $axis $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y الثانوي';

  @override
  String get chartAxisCategories => 'الفئات';

  @override
  String get chartAxisTime => 'الوقت';

  @override
  String get chartAxisValues => 'القيم';

  @override
  String get chartLineLegendFallback => 'خط';

  @override
  String funnelChartDescription(int count) {
    return 'مخطط قمعي به $count مقاطع';
  }

  @override
  String donutChartDescription(int count) {
    return 'مخطط دائري مجوف به $count شرائح';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'مخطط مقياس به $count مقاطع. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'القيمة الحالية: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'القيمة الحالية هي $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'الحد الأدنى للقيمة: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'الحد الأقصى للقيمة: $value';
  }

  @override
  String get gaugeUnknownSegment => 'غير معروف';

  @override
  String ganttChartDescription(int count) {
    return 'مخطط جانت به $count نقاط بيانات. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'مخطط خريطة حرارية به $count نقاط بيانات. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'مخطط قطبي به $count سلاسل بيانات.';
  }

  @override
  String sparklineDescription(String label) {
    return 'خط مؤشر بالتسمية $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'مخطط سانكي به $nodes عقد و$links روابط';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'من $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'عقدة $name بوزن $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'رابط من $source إلى $target بوزن $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'مخطط أعمدة به $count أعمدة. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'مخطط أعمدة به $count أعمدة وخط واحد. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'مخطط أعمدة به $count سلاسل أعمدة مجمعة. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'مخطط أعمدة به $count سلاسل أعمدة مجمعة و$lines سلاسل خطوط. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'مخطط أعمدة به $count أعمدة مكدسة. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'مخطط أعمدة به $count أعمدة مكدسة و$lines خطوط. ';
  }

  @override
  String get presenceAvailable => 'متاح';

  @override
  String get presenceAway => 'بالخارج';

  @override
  String get presenceBusy => 'مشغول';

  @override
  String get presenceDoNotDisturb => 'عدم الإزعاج';

  @override
  String get presenceBlocked => 'محظور';

  @override
  String get presenceOffline => 'غير متصل';

  @override
  String get presenceOutOfOffice => 'خارج المكتب';

  @override
  String get presenceUnknown => 'غير معروف';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status خارج المكتب';
  }
}

/// The translations for Arabic, as used in the United Arab Emirates (`ar_AE`).
class FluentLocalizationsArAe extends FluentLocalizationsAr {
  FluentLocalizationsArAe() : super('ar_AE');

  @override
  String get close => 'إغلاق';

  @override
  String get dismiss => 'تجاهل';

  @override
  String get clear => 'مسح';

  @override
  String get open => 'فتح';

  @override
  String get remove => 'إزالة';

  @override
  String get more => 'المزيد';

  @override
  String get overflowMore => 'إضافية';

  @override
  String get selectAllRows => 'تحديد كل الصفوف';

  @override
  String get selectRow => 'تحديد الصف';

  @override
  String get sort => 'فرز';

  @override
  String get sortedAscending => 'تم الفرز تصاعديًا';

  @override
  String get sortedDescending => 'تم الفرز تنازليًا';

  @override
  String get previousSlide => 'الشريحة السابقة';

  @override
  String get nextSlide => 'الشريحة التالية';

  @override
  String get startSlideShow => 'بدء عرض الشرائح التلقائي';

  @override
  String get pauseSlideShow => 'إيقاف عرض الشرائح التلقائي مؤقتًا';

  @override
  String slideOf(int index, int count) {
    return 'الشريحة $index من $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'الخطوة $index من $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value من $max';
  }

  @override
  String get openCalendar => 'فتح التقويم';

  @override
  String get invalidDateFormat => 'تنسيق التاريخ غير صالح.';

  @override
  String get dateOutOfRange => 'التاريخ خارج النطاق المسموح به.';

  @override
  String get fieldRequired => 'هذا الحقل مطلوب.';

  @override
  String get goToToday => 'الانتقال إلى اليوم';

  @override
  String get previousMonth => 'الشهر السابق';

  @override
  String get nextMonth => 'الشهر التالي';

  @override
  String get previousYear => 'السنة السابقة';

  @override
  String get nextYear => 'السنة التالية';

  @override
  String get previousYearRange => 'نطاق السنوات السابق';

  @override
  String get nextYearRange => 'نطاق السنوات التالي';

  @override
  String monthPickerHeader(String caption) {
    return '$caption، تغيير السنة';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption، تغيير الشهر';
  }

  @override
  String selectedDate(String date) {
    return 'التاريخ المحدد $date';
  }

  @override
  String todaysDate(String date) {
    return 'تاريخ اليوم $date';
  }

  @override
  String weekNumber(String number) {
    return 'الأسبوع $number';
  }

  @override
  String get chartNoData => 'لا يحتوي الرسم البياني على بيانات لعرضها';

  @override
  String get chartNoDataAvailable => 'لا تتوفر بيانات';

  @override
  String get chartFallbackTitle => 'مخطط. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'يعرض المحور $axis $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y الثانوي';

  @override
  String get chartAxisCategories => 'الفئات';

  @override
  String get chartAxisTime => 'الوقت';

  @override
  String get chartAxisValues => 'القيم';

  @override
  String get chartLineLegendFallback => 'خط';

  @override
  String funnelChartDescription(int count) {
    return 'مخطط قمعي به $count مقاطع';
  }

  @override
  String donutChartDescription(int count) {
    return 'مخطط دائري مجوف به $count شرائح';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'مخطط مقياس به $count مقاطع. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'القيمة الحالية: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'القيمة الحالية هي $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'الحد الأدنى للقيمة: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'الحد الأقصى للقيمة: $value';
  }

  @override
  String get gaugeUnknownSegment => 'غير معروف';

  @override
  String ganttChartDescription(int count) {
    return 'مخطط جانت به $count نقاط بيانات. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'مخطط خريطة حرارية به $count نقاط بيانات. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'مخطط قطبي به $count سلاسل بيانات.';
  }

  @override
  String sparklineDescription(String label) {
    return 'خط مؤشر بالتسمية $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'مخطط سانكي به $nodes عقد و$links روابط';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'من $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'عقدة $name بوزن $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'رابط من $source إلى $target بوزن $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'مخطط أعمدة به $count أعمدة. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'مخطط أعمدة به $count أعمدة وخط واحد. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'مخطط أعمدة به $count سلاسل أعمدة مجمعة. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'مخطط أعمدة به $count سلاسل أعمدة مجمعة و$lines سلاسل خطوط. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'مخطط أعمدة به $count أعمدة مكدسة. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'مخطط أعمدة به $count أعمدة مكدسة و$lines خطوط. ';
  }

  @override
  String get presenceAvailable => 'متاح';

  @override
  String get presenceAway => 'بالخارج';

  @override
  String get presenceBusy => 'مشغول';

  @override
  String get presenceDoNotDisturb => 'عدم الإزعاج';

  @override
  String get presenceBlocked => 'محظور';

  @override
  String get presenceOffline => 'غير متصل';

  @override
  String get presenceOutOfOffice => 'خارج المكتب';

  @override
  String get presenceUnknown => 'غير معروف';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status خارج المكتب';
  }
}

/// The translations for Arabic, as used in Algeria (`ar_DZ`).
class FluentLocalizationsArDz extends FluentLocalizationsAr {
  FluentLocalizationsArDz() : super('ar_DZ');

  @override
  String get close => 'إغلاق';

  @override
  String get dismiss => 'تجاهل';

  @override
  String get clear => 'مسح';

  @override
  String get open => 'فتح';

  @override
  String get remove => 'إزالة';

  @override
  String get more => 'المزيد';

  @override
  String get overflowMore => 'إضافية';

  @override
  String get selectAllRows => 'تحديد كل الصفوف';

  @override
  String get selectRow => 'تحديد الصف';

  @override
  String get sort => 'فرز';

  @override
  String get sortedAscending => 'تم الفرز تصاعديًا';

  @override
  String get sortedDescending => 'تم الفرز تنازليًا';

  @override
  String get previousSlide => 'الشريحة السابقة';

  @override
  String get nextSlide => 'الشريحة التالية';

  @override
  String get startSlideShow => 'بدء عرض الشرائح التلقائي';

  @override
  String get pauseSlideShow => 'إيقاف عرض الشرائح التلقائي مؤقتًا';

  @override
  String slideOf(int index, int count) {
    return 'الشريحة $index من $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'الخطوة $index من $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value من $max';
  }

  @override
  String get openCalendar => 'فتح التقويم';

  @override
  String get invalidDateFormat => 'تنسيق التاريخ غير صالح.';

  @override
  String get dateOutOfRange => 'التاريخ خارج النطاق المسموح به.';

  @override
  String get fieldRequired => 'هذا الحقل مطلوب.';

  @override
  String get goToToday => 'الانتقال إلى اليوم';

  @override
  String get previousMonth => 'الشهر السابق';

  @override
  String get nextMonth => 'الشهر التالي';

  @override
  String get previousYear => 'السنة السابقة';

  @override
  String get nextYear => 'السنة التالية';

  @override
  String get previousYearRange => 'نطاق السنوات السابق';

  @override
  String get nextYearRange => 'نطاق السنوات التالي';

  @override
  String monthPickerHeader(String caption) {
    return '$caption، تغيير السنة';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption، تغيير الشهر';
  }

  @override
  String selectedDate(String date) {
    return 'التاريخ المحدد $date';
  }

  @override
  String todaysDate(String date) {
    return 'تاريخ اليوم $date';
  }

  @override
  String weekNumber(String number) {
    return 'الأسبوع $number';
  }

  @override
  String get chartNoData => 'لا يحتوي الرسم البياني على بيانات لعرضها';

  @override
  String get chartNoDataAvailable => 'لا تتوفر بيانات';

  @override
  String get chartFallbackTitle => 'مخطط. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'يعرض المحور $axis $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y الثانوي';

  @override
  String get chartAxisCategories => 'الفئات';

  @override
  String get chartAxisTime => 'الوقت';

  @override
  String get chartAxisValues => 'القيم';

  @override
  String get chartLineLegendFallback => 'خط';

  @override
  String funnelChartDescription(int count) {
    return 'مخطط قمعي به $count مقاطع';
  }

  @override
  String donutChartDescription(int count) {
    return 'مخطط دائري مجوف به $count شرائح';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'مخطط مقياس به $count مقاطع. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'القيمة الحالية: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'القيمة الحالية هي $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'الحد الأدنى للقيمة: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'الحد الأقصى للقيمة: $value';
  }

  @override
  String get gaugeUnknownSegment => 'غير معروف';

  @override
  String ganttChartDescription(int count) {
    return 'مخطط جانت به $count نقاط بيانات. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'مخطط خريطة حرارية به $count نقاط بيانات. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'مخطط قطبي به $count سلاسل بيانات.';
  }

  @override
  String sparklineDescription(String label) {
    return 'خط مؤشر بالتسمية $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'مخطط سانكي به $nodes عقد و$links روابط';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'من $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'عقدة $name بوزن $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'رابط من $source إلى $target بوزن $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'مخطط أعمدة به $count أعمدة. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'مخطط أعمدة به $count أعمدة وخط واحد. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'مخطط أعمدة به $count سلاسل أعمدة مجمعة. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'مخطط أعمدة به $count سلاسل أعمدة مجمعة و$lines سلاسل خطوط. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'مخطط أعمدة به $count أعمدة مكدسة. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'مخطط أعمدة به $count أعمدة مكدسة و$lines خطوط. ';
  }

  @override
  String get presenceAvailable => 'متاح';

  @override
  String get presenceAway => 'بالخارج';

  @override
  String get presenceBusy => 'مشغول';

  @override
  String get presenceDoNotDisturb => 'عدم الإزعاج';

  @override
  String get presenceBlocked => 'محظور';

  @override
  String get presenceOffline => 'غير متصل';

  @override
  String get presenceOutOfOffice => 'خارج المكتب';

  @override
  String get presenceUnknown => 'غير معروف';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status خارج المكتب';
  }
}

/// The translations for Arabic, as used in Egypt (`ar_EG`).
class FluentLocalizationsArEg extends FluentLocalizationsAr {
  FluentLocalizationsArEg() : super('ar_EG');

  @override
  String get close => 'إغلاق';

  @override
  String get dismiss => 'تجاهل';

  @override
  String get clear => 'مسح';

  @override
  String get open => 'فتح';

  @override
  String get remove => 'إزالة';

  @override
  String get more => 'المزيد';

  @override
  String get overflowMore => 'إضافية';

  @override
  String get selectAllRows => 'تحديد كل الصفوف';

  @override
  String get selectRow => 'تحديد الصف';

  @override
  String get sort => 'فرز';

  @override
  String get sortedAscending => 'تم الفرز تصاعديًا';

  @override
  String get sortedDescending => 'تم الفرز تنازليًا';

  @override
  String get previousSlide => 'الشريحة السابقة';

  @override
  String get nextSlide => 'الشريحة التالية';

  @override
  String get startSlideShow => 'بدء عرض الشرائح التلقائي';

  @override
  String get pauseSlideShow => 'إيقاف عرض الشرائح التلقائي مؤقتًا';

  @override
  String slideOf(int index, int count) {
    return 'الشريحة $index من $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'الخطوة $index من $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value من $max';
  }

  @override
  String get openCalendar => 'فتح التقويم';

  @override
  String get invalidDateFormat => 'تنسيق التاريخ غير صالح.';

  @override
  String get dateOutOfRange => 'التاريخ خارج النطاق المسموح به.';

  @override
  String get fieldRequired => 'هذا الحقل مطلوب.';

  @override
  String get goToToday => 'الانتقال إلى اليوم';

  @override
  String get previousMonth => 'الشهر السابق';

  @override
  String get nextMonth => 'الشهر التالي';

  @override
  String get previousYear => 'السنة السابقة';

  @override
  String get nextYear => 'السنة التالية';

  @override
  String get previousYearRange => 'نطاق السنوات السابق';

  @override
  String get nextYearRange => 'نطاق السنوات التالي';

  @override
  String monthPickerHeader(String caption) {
    return '$caption، تغيير السنة';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption، تغيير الشهر';
  }

  @override
  String selectedDate(String date) {
    return 'التاريخ المحدد $date';
  }

  @override
  String todaysDate(String date) {
    return 'تاريخ اليوم $date';
  }

  @override
  String weekNumber(String number) {
    return 'الأسبوع $number';
  }

  @override
  String get chartNoData => 'لا يحتوي الرسم البياني على بيانات لعرضها';

  @override
  String get chartNoDataAvailable => 'لا تتوفر بيانات';

  @override
  String get chartFallbackTitle => 'مخطط. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'يعرض المحور $axis $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y الثانوي';

  @override
  String get chartAxisCategories => 'الفئات';

  @override
  String get chartAxisTime => 'الوقت';

  @override
  String get chartAxisValues => 'القيم';

  @override
  String get chartLineLegendFallback => 'خط';

  @override
  String funnelChartDescription(int count) {
    return 'مخطط قمعي به $count مقاطع';
  }

  @override
  String donutChartDescription(int count) {
    return 'مخطط دائري مجوف به $count شرائح';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'مخطط مقياس به $count مقاطع. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'القيمة الحالية: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'القيمة الحالية هي $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'الحد الأدنى للقيمة: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'الحد الأقصى للقيمة: $value';
  }

  @override
  String get gaugeUnknownSegment => 'غير معروف';

  @override
  String ganttChartDescription(int count) {
    return 'مخطط جانت به $count نقاط بيانات. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'مخطط خريطة حرارية به $count نقاط بيانات. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'مخطط قطبي به $count سلاسل بيانات.';
  }

  @override
  String sparklineDescription(String label) {
    return 'خط مؤشر بالتسمية $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'مخطط سانكي به $nodes عقد و$links روابط';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'من $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'عقدة $name بوزن $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'رابط من $source إلى $target بوزن $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'مخطط أعمدة به $count أعمدة. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'مخطط أعمدة به $count أعمدة وخط واحد. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'مخطط أعمدة به $count سلاسل أعمدة مجمعة. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'مخطط أعمدة به $count سلاسل أعمدة مجمعة و$lines سلاسل خطوط. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'مخطط أعمدة به $count أعمدة مكدسة. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'مخطط أعمدة به $count أعمدة مكدسة و$lines خطوط. ';
  }

  @override
  String get presenceAvailable => 'متاح';

  @override
  String get presenceAway => 'بالخارج';

  @override
  String get presenceBusy => 'مشغول';

  @override
  String get presenceDoNotDisturb => 'عدم الإزعاج';

  @override
  String get presenceBlocked => 'محظور';

  @override
  String get presenceOffline => 'غير متصل';

  @override
  String get presenceOutOfOffice => 'خارج المكتب';

  @override
  String get presenceUnknown => 'غير معروف';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status خارج المكتب';
  }
}

/// The translations for Arabic, as used in Iraq (`ar_IQ`).
class FluentLocalizationsArIq extends FluentLocalizationsAr {
  FluentLocalizationsArIq() : super('ar_IQ');

  @override
  String get close => 'إغلاق';

  @override
  String get dismiss => 'تجاهل';

  @override
  String get clear => 'مسح';

  @override
  String get open => 'فتح';

  @override
  String get remove => 'إزالة';

  @override
  String get more => 'المزيد';

  @override
  String get overflowMore => 'إضافية';

  @override
  String get selectAllRows => 'تحديد كل الصفوف';

  @override
  String get selectRow => 'تحديد الصف';

  @override
  String get sort => 'فرز';

  @override
  String get sortedAscending => 'تم الفرز تصاعديًا';

  @override
  String get sortedDescending => 'تم الفرز تنازليًا';

  @override
  String get previousSlide => 'الشريحة السابقة';

  @override
  String get nextSlide => 'الشريحة التالية';

  @override
  String get startSlideShow => 'بدء عرض الشرائح التلقائي';

  @override
  String get pauseSlideShow => 'إيقاف عرض الشرائح التلقائي مؤقتًا';

  @override
  String slideOf(int index, int count) {
    return 'الشريحة $index من $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'الخطوة $index من $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value من $max';
  }

  @override
  String get openCalendar => 'فتح التقويم';

  @override
  String get invalidDateFormat => 'تنسيق التاريخ غير صالح.';

  @override
  String get dateOutOfRange => 'التاريخ خارج النطاق المسموح به.';

  @override
  String get fieldRequired => 'هذا الحقل مطلوب.';

  @override
  String get goToToday => 'الانتقال إلى اليوم';

  @override
  String get previousMonth => 'الشهر السابق';

  @override
  String get nextMonth => 'الشهر التالي';

  @override
  String get previousYear => 'السنة السابقة';

  @override
  String get nextYear => 'السنة التالية';

  @override
  String get previousYearRange => 'نطاق السنوات السابق';

  @override
  String get nextYearRange => 'نطاق السنوات التالي';

  @override
  String monthPickerHeader(String caption) {
    return '$caption، تغيير السنة';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption، تغيير الشهر';
  }

  @override
  String selectedDate(String date) {
    return 'التاريخ المحدد $date';
  }

  @override
  String todaysDate(String date) {
    return 'تاريخ اليوم $date';
  }

  @override
  String weekNumber(String number) {
    return 'الأسبوع $number';
  }

  @override
  String get chartNoData => 'لا يحتوي الرسم البياني على بيانات لعرضها';

  @override
  String get chartNoDataAvailable => 'لا تتوفر بيانات';

  @override
  String get chartFallbackTitle => 'مخطط. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'يعرض المحور $axis $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y الثانوي';

  @override
  String get chartAxisCategories => 'الفئات';

  @override
  String get chartAxisTime => 'الوقت';

  @override
  String get chartAxisValues => 'القيم';

  @override
  String get chartLineLegendFallback => 'خط';

  @override
  String funnelChartDescription(int count) {
    return 'مخطط قمعي به $count مقاطع';
  }

  @override
  String donutChartDescription(int count) {
    return 'مخطط دائري مجوف به $count شرائح';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'مخطط مقياس به $count مقاطع. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'القيمة الحالية: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'القيمة الحالية هي $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'الحد الأدنى للقيمة: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'الحد الأقصى للقيمة: $value';
  }

  @override
  String get gaugeUnknownSegment => 'غير معروف';

  @override
  String ganttChartDescription(int count) {
    return 'مخطط جانت به $count نقاط بيانات. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'مخطط خريطة حرارية به $count نقاط بيانات. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'مخطط قطبي به $count سلاسل بيانات.';
  }

  @override
  String sparklineDescription(String label) {
    return 'خط مؤشر بالتسمية $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'مخطط سانكي به $nodes عقد و$links روابط';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'من $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'عقدة $name بوزن $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'رابط من $source إلى $target بوزن $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'مخطط أعمدة به $count أعمدة. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'مخطط أعمدة به $count أعمدة وخط واحد. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'مخطط أعمدة به $count سلاسل أعمدة مجمعة. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'مخطط أعمدة به $count سلاسل أعمدة مجمعة و$lines سلاسل خطوط. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'مخطط أعمدة به $count أعمدة مكدسة. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'مخطط أعمدة به $count أعمدة مكدسة و$lines خطوط. ';
  }

  @override
  String get presenceAvailable => 'متاح';

  @override
  String get presenceAway => 'بالخارج';

  @override
  String get presenceBusy => 'مشغول';

  @override
  String get presenceDoNotDisturb => 'عدم الإزعاج';

  @override
  String get presenceBlocked => 'محظور';

  @override
  String get presenceOffline => 'غير متصل';

  @override
  String get presenceOutOfOffice => 'خارج المكتب';

  @override
  String get presenceUnknown => 'غير معروف';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status خارج المكتب';
  }
}

/// The translations for Arabic, as used in Jordan (`ar_JO`).
class FluentLocalizationsArJo extends FluentLocalizationsAr {
  FluentLocalizationsArJo() : super('ar_JO');

  @override
  String get close => 'إغلاق';

  @override
  String get dismiss => 'تجاهل';

  @override
  String get clear => 'مسح';

  @override
  String get open => 'فتح';

  @override
  String get remove => 'إزالة';

  @override
  String get more => 'المزيد';

  @override
  String get overflowMore => 'إضافية';

  @override
  String get selectAllRows => 'تحديد كل الصفوف';

  @override
  String get selectRow => 'تحديد الصف';

  @override
  String get sort => 'فرز';

  @override
  String get sortedAscending => 'تم الفرز تصاعديًا';

  @override
  String get sortedDescending => 'تم الفرز تنازليًا';

  @override
  String get previousSlide => 'الشريحة السابقة';

  @override
  String get nextSlide => 'الشريحة التالية';

  @override
  String get startSlideShow => 'بدء عرض الشرائح التلقائي';

  @override
  String get pauseSlideShow => 'إيقاف عرض الشرائح التلقائي مؤقتًا';

  @override
  String slideOf(int index, int count) {
    return 'الشريحة $index من $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'الخطوة $index من $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value من $max';
  }

  @override
  String get openCalendar => 'فتح التقويم';

  @override
  String get invalidDateFormat => 'تنسيق التاريخ غير صالح.';

  @override
  String get dateOutOfRange => 'التاريخ خارج النطاق المسموح به.';

  @override
  String get fieldRequired => 'هذا الحقل مطلوب.';

  @override
  String get goToToday => 'الانتقال إلى اليوم';

  @override
  String get previousMonth => 'الشهر السابق';

  @override
  String get nextMonth => 'الشهر التالي';

  @override
  String get previousYear => 'السنة السابقة';

  @override
  String get nextYear => 'السنة التالية';

  @override
  String get previousYearRange => 'نطاق السنوات السابق';

  @override
  String get nextYearRange => 'نطاق السنوات التالي';

  @override
  String monthPickerHeader(String caption) {
    return '$caption، تغيير السنة';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption، تغيير الشهر';
  }

  @override
  String selectedDate(String date) {
    return 'التاريخ المحدد $date';
  }

  @override
  String todaysDate(String date) {
    return 'تاريخ اليوم $date';
  }

  @override
  String weekNumber(String number) {
    return 'الأسبوع $number';
  }

  @override
  String get chartNoData => 'لا يحتوي الرسم البياني على بيانات لعرضها';

  @override
  String get chartNoDataAvailable => 'لا تتوفر بيانات';

  @override
  String get chartFallbackTitle => 'مخطط. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'يعرض المحور $axis $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y الثانوي';

  @override
  String get chartAxisCategories => 'الفئات';

  @override
  String get chartAxisTime => 'الوقت';

  @override
  String get chartAxisValues => 'القيم';

  @override
  String get chartLineLegendFallback => 'خط';

  @override
  String funnelChartDescription(int count) {
    return 'مخطط قمعي به $count مقاطع';
  }

  @override
  String donutChartDescription(int count) {
    return 'مخطط دائري مجوف به $count شرائح';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'مخطط مقياس به $count مقاطع. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'القيمة الحالية: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'القيمة الحالية هي $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'الحد الأدنى للقيمة: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'الحد الأقصى للقيمة: $value';
  }

  @override
  String get gaugeUnknownSegment => 'غير معروف';

  @override
  String ganttChartDescription(int count) {
    return 'مخطط جانت به $count نقاط بيانات. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'مخطط خريطة حرارية به $count نقاط بيانات. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'مخطط قطبي به $count سلاسل بيانات.';
  }

  @override
  String sparklineDescription(String label) {
    return 'خط مؤشر بالتسمية $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'مخطط سانكي به $nodes عقد و$links روابط';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'من $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'عقدة $name بوزن $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'رابط من $source إلى $target بوزن $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'مخطط أعمدة به $count أعمدة. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'مخطط أعمدة به $count أعمدة وخط واحد. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'مخطط أعمدة به $count سلاسل أعمدة مجمعة. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'مخطط أعمدة به $count سلاسل أعمدة مجمعة و$lines سلاسل خطوط. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'مخطط أعمدة به $count أعمدة مكدسة. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'مخطط أعمدة به $count أعمدة مكدسة و$lines خطوط. ';
  }

  @override
  String get presenceAvailable => 'متاح';

  @override
  String get presenceAway => 'بالخارج';

  @override
  String get presenceBusy => 'مشغول';

  @override
  String get presenceDoNotDisturb => 'عدم الإزعاج';

  @override
  String get presenceBlocked => 'محظور';

  @override
  String get presenceOffline => 'غير متصل';

  @override
  String get presenceOutOfOffice => 'خارج المكتب';

  @override
  String get presenceUnknown => 'غير معروف';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status خارج المكتب';
  }
}

/// The translations for Arabic, as used in Kuwait (`ar_KW`).
class FluentLocalizationsArKw extends FluentLocalizationsAr {
  FluentLocalizationsArKw() : super('ar_KW');

  @override
  String get close => 'إغلاق';

  @override
  String get dismiss => 'تجاهل';

  @override
  String get clear => 'مسح';

  @override
  String get open => 'فتح';

  @override
  String get remove => 'إزالة';

  @override
  String get more => 'المزيد';

  @override
  String get overflowMore => 'إضافية';

  @override
  String get selectAllRows => 'تحديد كل الصفوف';

  @override
  String get selectRow => 'تحديد الصف';

  @override
  String get sort => 'فرز';

  @override
  String get sortedAscending => 'تم الفرز تصاعديًا';

  @override
  String get sortedDescending => 'تم الفرز تنازليًا';

  @override
  String get previousSlide => 'الشريحة السابقة';

  @override
  String get nextSlide => 'الشريحة التالية';

  @override
  String get startSlideShow => 'بدء عرض الشرائح التلقائي';

  @override
  String get pauseSlideShow => 'إيقاف عرض الشرائح التلقائي مؤقتًا';

  @override
  String slideOf(int index, int count) {
    return 'الشريحة $index من $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'الخطوة $index من $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value من $max';
  }

  @override
  String get openCalendar => 'فتح التقويم';

  @override
  String get invalidDateFormat => 'تنسيق التاريخ غير صالح.';

  @override
  String get dateOutOfRange => 'التاريخ خارج النطاق المسموح به.';

  @override
  String get fieldRequired => 'هذا الحقل مطلوب.';

  @override
  String get goToToday => 'الانتقال إلى اليوم';

  @override
  String get previousMonth => 'الشهر السابق';

  @override
  String get nextMonth => 'الشهر التالي';

  @override
  String get previousYear => 'السنة السابقة';

  @override
  String get nextYear => 'السنة التالية';

  @override
  String get previousYearRange => 'نطاق السنوات السابق';

  @override
  String get nextYearRange => 'نطاق السنوات التالي';

  @override
  String monthPickerHeader(String caption) {
    return '$caption، تغيير السنة';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption، تغيير الشهر';
  }

  @override
  String selectedDate(String date) {
    return 'التاريخ المحدد $date';
  }

  @override
  String todaysDate(String date) {
    return 'تاريخ اليوم $date';
  }

  @override
  String weekNumber(String number) {
    return 'الأسبوع $number';
  }

  @override
  String get chartNoData => 'لا يحتوي الرسم البياني على بيانات لعرضها';

  @override
  String get chartNoDataAvailable => 'لا تتوفر بيانات';

  @override
  String get chartFallbackTitle => 'مخطط. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'يعرض المحور $axis $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y الثانوي';

  @override
  String get chartAxisCategories => 'الفئات';

  @override
  String get chartAxisTime => 'الوقت';

  @override
  String get chartAxisValues => 'القيم';

  @override
  String get chartLineLegendFallback => 'خط';

  @override
  String funnelChartDescription(int count) {
    return 'مخطط قمعي به $count مقاطع';
  }

  @override
  String donutChartDescription(int count) {
    return 'مخطط دائري مجوف به $count شرائح';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'مخطط مقياس به $count مقاطع. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'القيمة الحالية: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'القيمة الحالية هي $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'الحد الأدنى للقيمة: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'الحد الأقصى للقيمة: $value';
  }

  @override
  String get gaugeUnknownSegment => 'غير معروف';

  @override
  String ganttChartDescription(int count) {
    return 'مخطط جانت به $count نقاط بيانات. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'مخطط خريطة حرارية به $count نقاط بيانات. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'مخطط قطبي به $count سلاسل بيانات.';
  }

  @override
  String sparklineDescription(String label) {
    return 'خط مؤشر بالتسمية $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'مخطط سانكي به $nodes عقد و$links روابط';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'من $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'عقدة $name بوزن $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'رابط من $source إلى $target بوزن $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'مخطط أعمدة به $count أعمدة. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'مخطط أعمدة به $count أعمدة وخط واحد. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'مخطط أعمدة به $count سلاسل أعمدة مجمعة. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'مخطط أعمدة به $count سلاسل أعمدة مجمعة و$lines سلاسل خطوط. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'مخطط أعمدة به $count أعمدة مكدسة. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'مخطط أعمدة به $count أعمدة مكدسة و$lines خطوط. ';
  }

  @override
  String get presenceAvailable => 'متاح';

  @override
  String get presenceAway => 'بالخارج';

  @override
  String get presenceBusy => 'مشغول';

  @override
  String get presenceDoNotDisturb => 'عدم الإزعاج';

  @override
  String get presenceBlocked => 'محظور';

  @override
  String get presenceOffline => 'غير متصل';

  @override
  String get presenceOutOfOffice => 'خارج المكتب';

  @override
  String get presenceUnknown => 'غير معروف';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status خارج المكتب';
  }
}

/// The translations for Arabic, as used in Lebanon (`ar_LB`).
class FluentLocalizationsArLb extends FluentLocalizationsAr {
  FluentLocalizationsArLb() : super('ar_LB');

  @override
  String get close => 'إغلاق';

  @override
  String get dismiss => 'تجاهل';

  @override
  String get clear => 'مسح';

  @override
  String get open => 'فتح';

  @override
  String get remove => 'إزالة';

  @override
  String get more => 'المزيد';

  @override
  String get overflowMore => 'إضافية';

  @override
  String get selectAllRows => 'تحديد كل الصفوف';

  @override
  String get selectRow => 'تحديد الصف';

  @override
  String get sort => 'فرز';

  @override
  String get sortedAscending => 'تم الفرز تصاعديًا';

  @override
  String get sortedDescending => 'تم الفرز تنازليًا';

  @override
  String get previousSlide => 'الشريحة السابقة';

  @override
  String get nextSlide => 'الشريحة التالية';

  @override
  String get startSlideShow => 'بدء عرض الشرائح التلقائي';

  @override
  String get pauseSlideShow => 'إيقاف عرض الشرائح التلقائي مؤقتًا';

  @override
  String slideOf(int index, int count) {
    return 'الشريحة $index من $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'الخطوة $index من $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value من $max';
  }

  @override
  String get openCalendar => 'فتح التقويم';

  @override
  String get invalidDateFormat => 'تنسيق التاريخ غير صالح.';

  @override
  String get dateOutOfRange => 'التاريخ خارج النطاق المسموح به.';

  @override
  String get fieldRequired => 'هذا الحقل مطلوب.';

  @override
  String get goToToday => 'الانتقال إلى اليوم';

  @override
  String get previousMonth => 'الشهر السابق';

  @override
  String get nextMonth => 'الشهر التالي';

  @override
  String get previousYear => 'السنة السابقة';

  @override
  String get nextYear => 'السنة التالية';

  @override
  String get previousYearRange => 'نطاق السنوات السابق';

  @override
  String get nextYearRange => 'نطاق السنوات التالي';

  @override
  String monthPickerHeader(String caption) {
    return '$caption، تغيير السنة';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption، تغيير الشهر';
  }

  @override
  String selectedDate(String date) {
    return 'التاريخ المحدد $date';
  }

  @override
  String todaysDate(String date) {
    return 'تاريخ اليوم $date';
  }

  @override
  String weekNumber(String number) {
    return 'الأسبوع $number';
  }

  @override
  String get chartNoData => 'لا يحتوي الرسم البياني على بيانات لعرضها';

  @override
  String get chartNoDataAvailable => 'لا تتوفر بيانات';

  @override
  String get chartFallbackTitle => 'مخطط. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'يعرض المحور $axis $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y الثانوي';

  @override
  String get chartAxisCategories => 'الفئات';

  @override
  String get chartAxisTime => 'الوقت';

  @override
  String get chartAxisValues => 'القيم';

  @override
  String get chartLineLegendFallback => 'خط';

  @override
  String funnelChartDescription(int count) {
    return 'مخطط قمعي به $count مقاطع';
  }

  @override
  String donutChartDescription(int count) {
    return 'مخطط دائري مجوف به $count شرائح';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'مخطط مقياس به $count مقاطع. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'القيمة الحالية: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'القيمة الحالية هي $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'الحد الأدنى للقيمة: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'الحد الأقصى للقيمة: $value';
  }

  @override
  String get gaugeUnknownSegment => 'غير معروف';

  @override
  String ganttChartDescription(int count) {
    return 'مخطط جانت به $count نقاط بيانات. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'مخطط خريطة حرارية به $count نقاط بيانات. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'مخطط قطبي به $count سلاسل بيانات.';
  }

  @override
  String sparklineDescription(String label) {
    return 'خط مؤشر بالتسمية $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'مخطط سانكي به $nodes عقد و$links روابط';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'من $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'عقدة $name بوزن $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'رابط من $source إلى $target بوزن $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'مخطط أعمدة به $count أعمدة. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'مخطط أعمدة به $count أعمدة وخط واحد. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'مخطط أعمدة به $count سلاسل أعمدة مجمعة. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'مخطط أعمدة به $count سلاسل أعمدة مجمعة و$lines سلاسل خطوط. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'مخطط أعمدة به $count أعمدة مكدسة. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'مخطط أعمدة به $count أعمدة مكدسة و$lines خطوط. ';
  }

  @override
  String get presenceAvailable => 'متاح';

  @override
  String get presenceAway => 'بالخارج';

  @override
  String get presenceBusy => 'مشغول';

  @override
  String get presenceDoNotDisturb => 'عدم الإزعاج';

  @override
  String get presenceBlocked => 'محظور';

  @override
  String get presenceOffline => 'غير متصل';

  @override
  String get presenceOutOfOffice => 'خارج المكتب';

  @override
  String get presenceUnknown => 'غير معروف';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status خارج المكتب';
  }
}

/// The translations for Arabic, as used in Morocco (`ar_MA`).
class FluentLocalizationsArMa extends FluentLocalizationsAr {
  FluentLocalizationsArMa() : super('ar_MA');

  @override
  String get close => 'إغلاق';

  @override
  String get dismiss => 'تجاهل';

  @override
  String get clear => 'مسح';

  @override
  String get open => 'فتح';

  @override
  String get remove => 'إزالة';

  @override
  String get more => 'المزيد';

  @override
  String get overflowMore => 'إضافية';

  @override
  String get selectAllRows => 'تحديد كل الصفوف';

  @override
  String get selectRow => 'تحديد الصف';

  @override
  String get sort => 'فرز';

  @override
  String get sortedAscending => 'تم الفرز تصاعديًا';

  @override
  String get sortedDescending => 'تم الفرز تنازليًا';

  @override
  String get previousSlide => 'الشريحة السابقة';

  @override
  String get nextSlide => 'الشريحة التالية';

  @override
  String get startSlideShow => 'بدء عرض الشرائح التلقائي';

  @override
  String get pauseSlideShow => 'إيقاف عرض الشرائح التلقائي مؤقتًا';

  @override
  String slideOf(int index, int count) {
    return 'الشريحة $index من $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'الخطوة $index من $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value من $max';
  }

  @override
  String get openCalendar => 'فتح التقويم';

  @override
  String get invalidDateFormat => 'تنسيق التاريخ غير صالح.';

  @override
  String get dateOutOfRange => 'التاريخ خارج النطاق المسموح به.';

  @override
  String get fieldRequired => 'هذا الحقل مطلوب.';

  @override
  String get goToToday => 'الانتقال إلى اليوم';

  @override
  String get previousMonth => 'الشهر السابق';

  @override
  String get nextMonth => 'الشهر التالي';

  @override
  String get previousYear => 'السنة السابقة';

  @override
  String get nextYear => 'السنة التالية';

  @override
  String get previousYearRange => 'نطاق السنوات السابق';

  @override
  String get nextYearRange => 'نطاق السنوات التالي';

  @override
  String monthPickerHeader(String caption) {
    return '$caption، تغيير السنة';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption، تغيير الشهر';
  }

  @override
  String selectedDate(String date) {
    return 'التاريخ المحدد $date';
  }

  @override
  String todaysDate(String date) {
    return 'تاريخ اليوم $date';
  }

  @override
  String weekNumber(String number) {
    return 'الأسبوع $number';
  }

  @override
  String get chartNoData => 'لا يحتوي الرسم البياني على بيانات لعرضها';

  @override
  String get chartNoDataAvailable => 'لا تتوفر بيانات';

  @override
  String get chartFallbackTitle => 'مخطط. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'يعرض المحور $axis $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y الثانوي';

  @override
  String get chartAxisCategories => 'الفئات';

  @override
  String get chartAxisTime => 'الوقت';

  @override
  String get chartAxisValues => 'القيم';

  @override
  String get chartLineLegendFallback => 'خط';

  @override
  String funnelChartDescription(int count) {
    return 'مخطط قمعي به $count مقاطع';
  }

  @override
  String donutChartDescription(int count) {
    return 'مخطط دائري مجوف به $count شرائح';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'مخطط مقياس به $count مقاطع. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'القيمة الحالية: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'القيمة الحالية هي $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'الحد الأدنى للقيمة: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'الحد الأقصى للقيمة: $value';
  }

  @override
  String get gaugeUnknownSegment => 'غير معروف';

  @override
  String ganttChartDescription(int count) {
    return 'مخطط جانت به $count نقاط بيانات. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'مخطط خريطة حرارية به $count نقاط بيانات. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'مخطط قطبي به $count سلاسل بيانات.';
  }

  @override
  String sparklineDescription(String label) {
    return 'خط مؤشر بالتسمية $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'مخطط سانكي به $nodes عقد و$links روابط';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'من $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'عقدة $name بوزن $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'رابط من $source إلى $target بوزن $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'مخطط أعمدة به $count أعمدة. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'مخطط أعمدة به $count أعمدة وخط واحد. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'مخطط أعمدة به $count سلاسل أعمدة مجمعة. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'مخطط أعمدة به $count سلاسل أعمدة مجمعة و$lines سلاسل خطوط. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'مخطط أعمدة به $count أعمدة مكدسة. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'مخطط أعمدة به $count أعمدة مكدسة و$lines خطوط. ';
  }

  @override
  String get presenceAvailable => 'متاح';

  @override
  String get presenceAway => 'بالخارج';

  @override
  String get presenceBusy => 'مشغول';

  @override
  String get presenceDoNotDisturb => 'عدم الإزعاج';

  @override
  String get presenceBlocked => 'محظور';

  @override
  String get presenceOffline => 'غير متصل';

  @override
  String get presenceOutOfOffice => 'خارج المكتب';

  @override
  String get presenceUnknown => 'غير معروف';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status خارج المكتب';
  }
}

/// The translations for Arabic, as used in Qatar (`ar_QA`).
class FluentLocalizationsArQa extends FluentLocalizationsAr {
  FluentLocalizationsArQa() : super('ar_QA');

  @override
  String get close => 'إغلاق';

  @override
  String get dismiss => 'تجاهل';

  @override
  String get clear => 'مسح';

  @override
  String get open => 'فتح';

  @override
  String get remove => 'إزالة';

  @override
  String get more => 'المزيد';

  @override
  String get overflowMore => 'إضافية';

  @override
  String get selectAllRows => 'تحديد كل الصفوف';

  @override
  String get selectRow => 'تحديد الصف';

  @override
  String get sort => 'فرز';

  @override
  String get sortedAscending => 'تم الفرز تصاعديًا';

  @override
  String get sortedDescending => 'تم الفرز تنازليًا';

  @override
  String get previousSlide => 'الشريحة السابقة';

  @override
  String get nextSlide => 'الشريحة التالية';

  @override
  String get startSlideShow => 'بدء عرض الشرائح التلقائي';

  @override
  String get pauseSlideShow => 'إيقاف عرض الشرائح التلقائي مؤقتًا';

  @override
  String slideOf(int index, int count) {
    return 'الشريحة $index من $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'الخطوة $index من $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value من $max';
  }

  @override
  String get openCalendar => 'فتح التقويم';

  @override
  String get invalidDateFormat => 'تنسيق التاريخ غير صالح.';

  @override
  String get dateOutOfRange => 'التاريخ خارج النطاق المسموح به.';

  @override
  String get fieldRequired => 'هذا الحقل مطلوب.';

  @override
  String get goToToday => 'الانتقال إلى اليوم';

  @override
  String get previousMonth => 'الشهر السابق';

  @override
  String get nextMonth => 'الشهر التالي';

  @override
  String get previousYear => 'السنة السابقة';

  @override
  String get nextYear => 'السنة التالية';

  @override
  String get previousYearRange => 'نطاق السنوات السابق';

  @override
  String get nextYearRange => 'نطاق السنوات التالي';

  @override
  String monthPickerHeader(String caption) {
    return '$caption، تغيير السنة';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption، تغيير الشهر';
  }

  @override
  String selectedDate(String date) {
    return 'التاريخ المحدد $date';
  }

  @override
  String todaysDate(String date) {
    return 'تاريخ اليوم $date';
  }

  @override
  String weekNumber(String number) {
    return 'الأسبوع $number';
  }

  @override
  String get chartNoData => 'لا يحتوي الرسم البياني على بيانات لعرضها';

  @override
  String get chartNoDataAvailable => 'لا تتوفر بيانات';

  @override
  String get chartFallbackTitle => 'مخطط. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'يعرض المحور $axis $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y الثانوي';

  @override
  String get chartAxisCategories => 'الفئات';

  @override
  String get chartAxisTime => 'الوقت';

  @override
  String get chartAxisValues => 'القيم';

  @override
  String get chartLineLegendFallback => 'خط';

  @override
  String funnelChartDescription(int count) {
    return 'مخطط قمعي به $count مقاطع';
  }

  @override
  String donutChartDescription(int count) {
    return 'مخطط دائري مجوف به $count شرائح';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'مخطط مقياس به $count مقاطع. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'القيمة الحالية: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'القيمة الحالية هي $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'الحد الأدنى للقيمة: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'الحد الأقصى للقيمة: $value';
  }

  @override
  String get gaugeUnknownSegment => 'غير معروف';

  @override
  String ganttChartDescription(int count) {
    return 'مخطط جانت به $count نقاط بيانات. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'مخطط خريطة حرارية به $count نقاط بيانات. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'مخطط قطبي به $count سلاسل بيانات.';
  }

  @override
  String sparklineDescription(String label) {
    return 'خط مؤشر بالتسمية $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'مخطط سانكي به $nodes عقد و$links روابط';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'من $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'عقدة $name بوزن $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'رابط من $source إلى $target بوزن $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'مخطط أعمدة به $count أعمدة. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'مخطط أعمدة به $count أعمدة وخط واحد. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'مخطط أعمدة به $count سلاسل أعمدة مجمعة. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'مخطط أعمدة به $count سلاسل أعمدة مجمعة و$lines سلاسل خطوط. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'مخطط أعمدة به $count أعمدة مكدسة. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'مخطط أعمدة به $count أعمدة مكدسة و$lines خطوط. ';
  }

  @override
  String get presenceAvailable => 'متاح';

  @override
  String get presenceAway => 'بالخارج';

  @override
  String get presenceBusy => 'مشغول';

  @override
  String get presenceDoNotDisturb => 'عدم الإزعاج';

  @override
  String get presenceBlocked => 'محظور';

  @override
  String get presenceOffline => 'غير متصل';

  @override
  String get presenceOutOfOffice => 'خارج المكتب';

  @override
  String get presenceUnknown => 'غير معروف';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status خارج المكتب';
  }
}

/// The translations for Arabic, as used in Saudi Arabia (`ar_SA`).
class FluentLocalizationsArSa extends FluentLocalizationsAr {
  FluentLocalizationsArSa() : super('ar_SA');

  @override
  String get close => 'إغلاق';

  @override
  String get dismiss => 'تجاهل';

  @override
  String get clear => 'مسح';

  @override
  String get open => 'فتح';

  @override
  String get remove => 'إزالة';

  @override
  String get more => 'المزيد';

  @override
  String get overflowMore => 'إضافية';

  @override
  String get selectAllRows => 'تحديد كل الصفوف';

  @override
  String get selectRow => 'تحديد الصف';

  @override
  String get sort => 'فرز';

  @override
  String get sortedAscending => 'تم الفرز تصاعديًا';

  @override
  String get sortedDescending => 'تم الفرز تنازليًا';

  @override
  String get previousSlide => 'الشريحة السابقة';

  @override
  String get nextSlide => 'الشريحة التالية';

  @override
  String get startSlideShow => 'بدء عرض الشرائح التلقائي';

  @override
  String get pauseSlideShow => 'إيقاف عرض الشرائح التلقائي مؤقتًا';

  @override
  String slideOf(int index, int count) {
    return 'الشريحة $index من $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'الخطوة $index من $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value من $max';
  }

  @override
  String get openCalendar => 'فتح التقويم';

  @override
  String get invalidDateFormat => 'تنسيق التاريخ غير صالح.';

  @override
  String get dateOutOfRange => 'التاريخ خارج النطاق المسموح به.';

  @override
  String get fieldRequired => 'هذا الحقل مطلوب.';

  @override
  String get goToToday => 'الانتقال إلى اليوم';

  @override
  String get previousMonth => 'الشهر السابق';

  @override
  String get nextMonth => 'الشهر التالي';

  @override
  String get previousYear => 'السنة السابقة';

  @override
  String get nextYear => 'السنة التالية';

  @override
  String get previousYearRange => 'نطاق السنوات السابق';

  @override
  String get nextYearRange => 'نطاق السنوات التالي';

  @override
  String monthPickerHeader(String caption) {
    return '$caption، تغيير السنة';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption، تغيير الشهر';
  }

  @override
  String selectedDate(String date) {
    return 'التاريخ المحدد $date';
  }

  @override
  String todaysDate(String date) {
    return 'تاريخ اليوم $date';
  }

  @override
  String weekNumber(String number) {
    return 'الأسبوع $number';
  }

  @override
  String get chartNoData => 'لا يحتوي الرسم البياني على بيانات لعرضها';

  @override
  String get chartNoDataAvailable => 'لا تتوفر بيانات';

  @override
  String get chartFallbackTitle => 'مخطط. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'يعرض المحور $axis $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y الثانوي';

  @override
  String get chartAxisCategories => 'الفئات';

  @override
  String get chartAxisTime => 'الوقت';

  @override
  String get chartAxisValues => 'القيم';

  @override
  String get chartLineLegendFallback => 'خط';

  @override
  String funnelChartDescription(int count) {
    return 'مخطط قمعي به $count مقاطع';
  }

  @override
  String donutChartDescription(int count) {
    return 'مخطط دائري مجوف به $count شرائح';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'مخطط مقياس به $count مقاطع. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'القيمة الحالية: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'القيمة الحالية هي $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'الحد الأدنى للقيمة: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'الحد الأقصى للقيمة: $value';
  }

  @override
  String get gaugeUnknownSegment => 'غير معروف';

  @override
  String ganttChartDescription(int count) {
    return 'مخطط جانت به $count نقاط بيانات. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'مخطط خريطة حرارية به $count نقاط بيانات. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'مخطط قطبي به $count سلاسل بيانات.';
  }

  @override
  String sparklineDescription(String label) {
    return 'خط مؤشر بالتسمية $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'مخطط سانكي به $nodes عقد و$links روابط';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'من $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'عقدة $name بوزن $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'رابط من $source إلى $target بوزن $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'مخطط أعمدة به $count أعمدة. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'مخطط أعمدة به $count أعمدة وخط واحد. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'مخطط أعمدة به $count سلاسل أعمدة مجمعة. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'مخطط أعمدة به $count سلاسل أعمدة مجمعة و$lines سلاسل خطوط. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'مخطط أعمدة به $count أعمدة مكدسة. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'مخطط أعمدة به $count أعمدة مكدسة و$lines خطوط. ';
  }

  @override
  String get presenceAvailable => 'متاح';

  @override
  String get presenceAway => 'بالخارج';

  @override
  String get presenceBusy => 'مشغول';

  @override
  String get presenceDoNotDisturb => 'عدم الإزعاج';

  @override
  String get presenceBlocked => 'محظور';

  @override
  String get presenceOffline => 'غير متصل';

  @override
  String get presenceOutOfOffice => 'خارج المكتب';

  @override
  String get presenceUnknown => 'غير معروف';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status خارج المكتب';
  }
}

/// The translations for Arabic, as used in Tunisia (`ar_TN`).
class FluentLocalizationsArTn extends FluentLocalizationsAr {
  FluentLocalizationsArTn() : super('ar_TN');

  @override
  String get close => 'إغلاق';

  @override
  String get dismiss => 'تجاهل';

  @override
  String get clear => 'مسح';

  @override
  String get open => 'فتح';

  @override
  String get remove => 'إزالة';

  @override
  String get more => 'المزيد';

  @override
  String get overflowMore => 'إضافية';

  @override
  String get selectAllRows => 'تحديد كل الصفوف';

  @override
  String get selectRow => 'تحديد الصف';

  @override
  String get sort => 'فرز';

  @override
  String get sortedAscending => 'تم الفرز تصاعديًا';

  @override
  String get sortedDescending => 'تم الفرز تنازليًا';

  @override
  String get previousSlide => 'الشريحة السابقة';

  @override
  String get nextSlide => 'الشريحة التالية';

  @override
  String get startSlideShow => 'بدء عرض الشرائح التلقائي';

  @override
  String get pauseSlideShow => 'إيقاف عرض الشرائح التلقائي مؤقتًا';

  @override
  String slideOf(int index, int count) {
    return 'الشريحة $index من $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'الخطوة $index من $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value من $max';
  }

  @override
  String get openCalendar => 'فتح التقويم';

  @override
  String get invalidDateFormat => 'تنسيق التاريخ غير صالح.';

  @override
  String get dateOutOfRange => 'التاريخ خارج النطاق المسموح به.';

  @override
  String get fieldRequired => 'هذا الحقل مطلوب.';

  @override
  String get goToToday => 'الانتقال إلى اليوم';

  @override
  String get previousMonth => 'الشهر السابق';

  @override
  String get nextMonth => 'الشهر التالي';

  @override
  String get previousYear => 'السنة السابقة';

  @override
  String get nextYear => 'السنة التالية';

  @override
  String get previousYearRange => 'نطاق السنوات السابق';

  @override
  String get nextYearRange => 'نطاق السنوات التالي';

  @override
  String monthPickerHeader(String caption) {
    return '$caption، تغيير السنة';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption، تغيير الشهر';
  }

  @override
  String selectedDate(String date) {
    return 'التاريخ المحدد $date';
  }

  @override
  String todaysDate(String date) {
    return 'تاريخ اليوم $date';
  }

  @override
  String weekNumber(String number) {
    return 'الأسبوع $number';
  }

  @override
  String get chartNoData => 'لا يحتوي الرسم البياني على بيانات لعرضها';

  @override
  String get chartNoDataAvailable => 'لا تتوفر بيانات';

  @override
  String get chartFallbackTitle => 'مخطط. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'يعرض المحور $axis $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y الثانوي';

  @override
  String get chartAxisCategories => 'الفئات';

  @override
  String get chartAxisTime => 'الوقت';

  @override
  String get chartAxisValues => 'القيم';

  @override
  String get chartLineLegendFallback => 'خط';

  @override
  String funnelChartDescription(int count) {
    return 'مخطط قمعي به $count مقاطع';
  }

  @override
  String donutChartDescription(int count) {
    return 'مخطط دائري مجوف به $count شرائح';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'مخطط مقياس به $count مقاطع. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'القيمة الحالية: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'القيمة الحالية هي $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'الحد الأدنى للقيمة: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'الحد الأقصى للقيمة: $value';
  }

  @override
  String get gaugeUnknownSegment => 'غير معروف';

  @override
  String ganttChartDescription(int count) {
    return 'مخطط جانت به $count نقاط بيانات. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'مخطط خريطة حرارية به $count نقاط بيانات. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'مخطط قطبي به $count سلاسل بيانات.';
  }

  @override
  String sparklineDescription(String label) {
    return 'خط مؤشر بالتسمية $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'مخطط سانكي به $nodes عقد و$links روابط';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'من $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'عقدة $name بوزن $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'رابط من $source إلى $target بوزن $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'مخطط أعمدة به $count أعمدة. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'مخطط أعمدة به $count أعمدة وخط واحد. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'مخطط أعمدة به $count سلاسل أعمدة مجمعة. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'مخطط أعمدة به $count سلاسل أعمدة مجمعة و$lines سلاسل خطوط. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'مخطط أعمدة به $count أعمدة مكدسة. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'مخطط أعمدة به $count أعمدة مكدسة و$lines خطوط. ';
  }

  @override
  String get presenceAvailable => 'متاح';

  @override
  String get presenceAway => 'بالخارج';

  @override
  String get presenceBusy => 'مشغول';

  @override
  String get presenceDoNotDisturb => 'عدم الإزعاج';

  @override
  String get presenceBlocked => 'محظور';

  @override
  String get presenceOffline => 'غير متصل';

  @override
  String get presenceOutOfOffice => 'خارج المكتب';

  @override
  String get presenceUnknown => 'غير معروف';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status خارج المكتب';
  }
}
