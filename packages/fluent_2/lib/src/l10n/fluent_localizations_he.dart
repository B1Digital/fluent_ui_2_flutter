// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fluent_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class FluentLocalizationsHe extends FluentLocalizations {
  FluentLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get close => 'סגור';

  @override
  String get dismiss => 'התעלם';

  @override
  String get clear => 'נקה';

  @override
  String get open => 'פתח';

  @override
  String get remove => 'הסר';

  @override
  String get more => 'עוד';

  @override
  String get overflowMore => 'נוספים';

  @override
  String get selectAllRows => 'בחר את כל השורות';

  @override
  String get selectRow => 'בחר שורה';

  @override
  String get sort => 'מיין';

  @override
  String get sortedAscending => 'ממוין בסדר עולה';

  @override
  String get sortedDescending => 'ממוין בסדר יורד';

  @override
  String get previousSlide => 'השקופית הקודמת';

  @override
  String get nextSlide => 'השקופית הבאה';

  @override
  String get startSlideShow => 'הפעל מצגת אוטומטית';

  @override
  String get pauseSlideShow => 'השהה מצגת אוטומטית';

  @override
  String slideOf(int index, int count) {
    return 'שקופית $index מתוך $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'שלב $index מתוך $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value מתוך $max';
  }

  @override
  String get openCalendar => 'פתח לוח שנה';

  @override
  String get invalidDateFormat => 'תבנית תאריך לא חוקית.';

  @override
  String get dateOutOfRange => 'התאריך מחוץ לטווח המותר.';

  @override
  String get fieldRequired => 'שדה זה הוא שדה חובה.';

  @override
  String get goToToday => 'עבור להיום';

  @override
  String get previousMonth => 'החודש הקודם';

  @override
  String get nextMonth => 'החודש הבא';

  @override
  String get previousYear => 'השנה הקודמת';

  @override
  String get nextYear => 'השנה הבאה';

  @override
  String get previousYearRange => 'טווח השנים הקודם';

  @override
  String get nextYearRange => 'טווח השנים הבא';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, שינוי שנה';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, שינוי חודש';
  }

  @override
  String selectedDate(String date) {
    return 'תאריך נבחר $date';
  }

  @override
  String todaysDate(String date) {
    return 'תאריך היום $date';
  }

  @override
  String weekNumber(String number) {
    return 'שבוע $number';
  }

  @override
  String get chartNoData => 'לגרף אין נתונים להצגה';

  @override
  String get chartNoDataAvailable => 'אין נתונים זמינים';

  @override
  String get chartFallbackTitle => 'תרשים. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'ציר $axis מציג $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y משני';

  @override
  String get chartAxisCategories => 'קטגוריות';

  @override
  String get chartAxisTime => 'זמן';

  @override
  String get chartAxisValues => 'ערכים';

  @override
  String get chartLineLegendFallback => 'קו';

  @override
  String funnelChartDescription(int count) {
    return 'תרשים משפך עם $count מקטעים';
  }

  @override
  String donutChartDescription(int count) {
    return 'תרשים טבעת עם $count פלחים';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'תרשים מד עם $count מקטעים. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'ערך נוכחי: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'הערך הנוכחי הוא $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'ערך מינימלי: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'ערך מקסימלי: $value';
  }

  @override
  String get gaugeUnknownSegment => 'לא ידוע';

  @override
  String ganttChartDescription(int count) {
    return 'תרשים גאנט עם $count נקודות נתונים. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'מפת חום עם $count נקודות נתונים. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'תרשים קוטבי עם $count סדרות נתונים.';
  }

  @override
  String sparklineDescription(String label) {
    return 'גרף זעיר עם התווית $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'תרשים סנקי עם $nodes צמתים ו-$links קישורים';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'מ-$node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'צומת $name במשקל $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'קישור מ-$source אל $target במשקל $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'תרשים עמודות עם $count עמודות. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'תרשים עמודות עם $count עמודות וקו אחד. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'תרשים עמודות עם $count סדרות עמודות מקובצות. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'תרשים עמודות עם $count סדרות עמודות מקובצות ו-$lines סדרות קווים. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'תרשים עמודות עם $count עמודות מוערמות. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'תרשים עמודות עם $count עמודות מוערמות ו-$lines קווים. ';
  }

  @override
  String get presenceAvailable => 'זמין';

  @override
  String get presenceAway => 'לא נמצא';

  @override
  String get presenceBusy => 'לא פנוי';

  @override
  String get presenceDoNotDisturb => 'נא לא להפריע';

  @override
  String get presenceBlocked => 'חסום';

  @override
  String get presenceOffline => 'לא מקוון';

  @override
  String get presenceOutOfOffice => 'מחוץ למשרד';

  @override
  String get presenceUnknown => 'לא ידוע';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, מחוץ למשרד';
  }
}

/// The translations for Hebrew, as used in Israel (`he_IL`).
class FluentLocalizationsHeIl extends FluentLocalizationsHe {
  FluentLocalizationsHeIl() : super('he_IL');

  @override
  String get close => 'סגור';

  @override
  String get dismiss => 'התעלם';

  @override
  String get clear => 'נקה';

  @override
  String get open => 'פתח';

  @override
  String get remove => 'הסר';

  @override
  String get more => 'עוד';

  @override
  String get overflowMore => 'נוספים';

  @override
  String get selectAllRows => 'בחר את כל השורות';

  @override
  String get selectRow => 'בחר שורה';

  @override
  String get sort => 'מיין';

  @override
  String get sortedAscending => 'ממוין בסדר עולה';

  @override
  String get sortedDescending => 'ממוין בסדר יורד';

  @override
  String get previousSlide => 'השקופית הקודמת';

  @override
  String get nextSlide => 'השקופית הבאה';

  @override
  String get startSlideShow => 'הפעל מצגת אוטומטית';

  @override
  String get pauseSlideShow => 'השהה מצגת אוטומטית';

  @override
  String slideOf(int index, int count) {
    return 'שקופית $index מתוך $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'שלב $index מתוך $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value מתוך $max';
  }

  @override
  String get openCalendar => 'פתח לוח שנה';

  @override
  String get invalidDateFormat => 'תבנית תאריך לא חוקית.';

  @override
  String get dateOutOfRange => 'התאריך מחוץ לטווח המותר.';

  @override
  String get fieldRequired => 'שדה זה הוא שדה חובה.';

  @override
  String get goToToday => 'עבור להיום';

  @override
  String get previousMonth => 'החודש הקודם';

  @override
  String get nextMonth => 'החודש הבא';

  @override
  String get previousYear => 'השנה הקודמת';

  @override
  String get nextYear => 'השנה הבאה';

  @override
  String get previousYearRange => 'טווח השנים הקודם';

  @override
  String get nextYearRange => 'טווח השנים הבא';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, שינוי שנה';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, שינוי חודש';
  }

  @override
  String selectedDate(String date) {
    return 'תאריך נבחר $date';
  }

  @override
  String todaysDate(String date) {
    return 'תאריך היום $date';
  }

  @override
  String weekNumber(String number) {
    return 'שבוע $number';
  }

  @override
  String get chartNoData => 'לגרף אין נתונים להצגה';

  @override
  String get chartNoDataAvailable => 'אין נתונים זמינים';

  @override
  String get chartFallbackTitle => 'תרשים. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'ציר $axis מציג $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y משני';

  @override
  String get chartAxisCategories => 'קטגוריות';

  @override
  String get chartAxisTime => 'זמן';

  @override
  String get chartAxisValues => 'ערכים';

  @override
  String get chartLineLegendFallback => 'קו';

  @override
  String funnelChartDescription(int count) {
    return 'תרשים משפך עם $count מקטעים';
  }

  @override
  String donutChartDescription(int count) {
    return 'תרשים טבעת עם $count פלחים';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'תרשים מד עם $count מקטעים. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'ערך נוכחי: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'הערך הנוכחי הוא $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'ערך מינימלי: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'ערך מקסימלי: $value';
  }

  @override
  String get gaugeUnknownSegment => 'לא ידוע';

  @override
  String ganttChartDescription(int count) {
    return 'תרשים גאנט עם $count נקודות נתונים. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'מפת חום עם $count נקודות נתונים. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'תרשים קוטבי עם $count סדרות נתונים.';
  }

  @override
  String sparklineDescription(String label) {
    return 'גרף זעיר עם התווית $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'תרשים סנקי עם $nodes צמתים ו-$links קישורים';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'מ-$node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'צומת $name במשקל $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'קישור מ-$source אל $target במשקל $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'תרשים עמודות עם $count עמודות. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'תרשים עמודות עם $count עמודות וקו אחד. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'תרשים עמודות עם $count סדרות עמודות מקובצות. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'תרשים עמודות עם $count סדרות עמודות מקובצות ו-$lines סדרות קווים. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'תרשים עמודות עם $count עמודות מוערמות. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'תרשים עמודות עם $count עמודות מוערמות ו-$lines קווים. ';
  }

  @override
  String get presenceAvailable => 'זמין';

  @override
  String get presenceAway => 'לא נמצא';

  @override
  String get presenceBusy => 'לא פנוי';

  @override
  String get presenceDoNotDisturb => 'נא לא להפריע';

  @override
  String get presenceBlocked => 'חסום';

  @override
  String get presenceOffline => 'לא מקוון';

  @override
  String get presenceOutOfOffice => 'מחוץ למשרד';

  @override
  String get presenceUnknown => 'לא ידוע';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, מחוץ למשרד';
  }
}
