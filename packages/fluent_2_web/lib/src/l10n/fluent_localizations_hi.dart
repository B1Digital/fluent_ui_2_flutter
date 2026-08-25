// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fluent_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class FluentLocalizationsHi extends FluentLocalizations {
  FluentLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get close => 'बंद करें';

  @override
  String get dismiss => 'खारिज करें';

  @override
  String get clear => 'साफ़ करें';

  @override
  String get open => 'खोलें';

  @override
  String get remove => 'निकालें';

  @override
  String get more => 'अधिक';

  @override
  String get overflowMore => 'और';

  @override
  String get selectAllRows => 'सभी पंक्तियाँ चुनें';

  @override
  String get selectRow => 'पंक्ति चुनें';

  @override
  String get sort => 'क्रमबद्ध करें';

  @override
  String get sortedAscending => 'आरोही क्रम में क्रमबद्ध';

  @override
  String get sortedDescending => 'अवरोही क्रम में क्रमबद्ध';

  @override
  String get previousSlide => 'पिछली स्लाइड';

  @override
  String get nextSlide => 'अगली स्लाइड';

  @override
  String get startSlideShow => 'स्वचालित स्लाइड शो प्रारंभ करें';

  @override
  String get pauseSlideShow => 'स्वचालित स्लाइड शो रोकें';

  @override
  String slideOf(int index, int count) {
    return '$count में से स्लाइड $index';
  }

  @override
  String stepOf(int index, int count) {
    return '$count में से चरण $index';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$max में से $value';
  }

  @override
  String get openCalendar => 'कैलेंडर खोलें';

  @override
  String get invalidDateFormat => 'अमान्य दिनांक स्वरूप।';

  @override
  String get dateOutOfRange => 'दिनांक अनुमत श्रेणी से बाहर है।';

  @override
  String get fieldRequired => 'यह फ़ील्ड आवश्यक है।';

  @override
  String get goToToday => 'आज पर जाएँ';

  @override
  String get previousMonth => 'पिछला महीना';

  @override
  String get nextMonth => 'अगला महीना';

  @override
  String get previousYear => 'पिछला वर्ष';

  @override
  String get nextYear => 'अगला वर्ष';

  @override
  String get previousYearRange => 'पिछली वर्ष श्रेणी';

  @override
  String get nextYearRange => 'अगली वर्ष श्रेणी';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, वर्ष बदलें';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, महीना बदलें';
  }

  @override
  String selectedDate(String date) {
    return 'चयनित दिनांक $date';
  }

  @override
  String todaysDate(String date) {
    return 'आज का दिनांक $date';
  }

  @override
  String weekNumber(String number) {
    return 'सप्ताह $number';
  }

  @override
  String get chartNoData => 'ग्राफ़ में दिखाने के लिए कोई डेटा नहीं है';

  @override
  String get chartNoDataAvailable => 'कोई डेटा उपलब्ध नहीं';

  @override
  String get chartFallbackTitle => 'चार्ट। ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return '$axis अक्ष $subject दिखाता है। ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'द्वितीयक Y';

  @override
  String get chartAxisCategories => 'श्रेणियाँ';

  @override
  String get chartAxisTime => 'समय';

  @override
  String get chartAxisValues => 'मान';

  @override
  String get chartLineLegendFallback => 'रेखा';

  @override
  String funnelChartDescription(int count) {
    return '$count खंडों वाला फ़नल चार्ट';
  }

  @override
  String donutChartDescription(int count) {
    return '$count स्लाइस वाला डोनट चार्ट';
  }

  @override
  String gaugeChartDescription(int count) {
    return '$count खंडों वाला गेज चार्ट। ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'वर्तमान मान: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'वर्तमान मान $value है';
  }

  @override
  String gaugeMinValue(String value) {
    return 'न्यूनतम मान: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'अधिकतम मान: $value';
  }

  @override
  String get gaugeUnknownSegment => 'अज्ञात';

  @override
  String ganttChartDescription(int count) {
    return '$count डेटा बिंदुओं वाला गैंट चार्ट। ';
  }

  @override
  String heatMapChartDescription(int count) {
    return '$count डेटा बिंदुओं वाला हीट मैप चार्ट। ';
  }

  @override
  String polarChartDescription(int count) {
    return '$count डेटा शृंखलाओं वाला ध्रुवीय चार्ट।';
  }

  @override
  String sparklineDescription(String label) {
    return '$label लेबल वाली स्पार्कलाइन';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return '$nodes नोड और $links लिंक वाला सैंकी चार्ट';
  }

  @override
  String sankeyLinkFrom(String node) {
    return '$node से';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return '$weight भार वाला नोड $name';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return '$weight भार वाला $source से $target तक का लिंक';
  }

  @override
  String verticalBarChartDescription(int count) {
    return '$count बार वाला ऊर्ध्वाधर बार चार्ट। ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return '$count बार और 1 रेखा वाला ऊर्ध्वाधर बार चार्ट। ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return '$count समूहीकृत बार शृंखलाओं वाला ऊर्ध्वाधर बार चार्ट। ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return '$count समूहीकृत बार शृंखलाओं और $lines रेखा शृंखलाओं वाला ऊर्ध्वाधर बार चार्ट। ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return '$count स्टैक्ड बार वाला ऊर्ध्वाधर बार चार्ट। ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return '$count स्टैक्ड बार और $lines रेखाओं वाला ऊर्ध्वाधर बार चार्ट। ';
  }

  @override
  String get presenceAvailable => 'उपलब्ध';

  @override
  String get presenceAway => 'दूर';

  @override
  String get presenceBusy => 'व्यस्त';

  @override
  String get presenceDoNotDisturb => 'परेशान न करें';

  @override
  String get presenceBlocked => 'अवरोधित';

  @override
  String get presenceOffline => 'ऑफ़लाइन';

  @override
  String get presenceOutOfOffice => 'कार्यालय से बाहर';

  @override
  String get presenceUnknown => 'अज्ञात';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, कार्यालय से बाहर';
  }
}

/// The translations for Hindi, as used in India (`hi_IN`).
class FluentLocalizationsHiIn extends FluentLocalizationsHi {
  FluentLocalizationsHiIn() : super('hi_IN');

  @override
  String get close => 'बंद करें';

  @override
  String get dismiss => 'खारिज करें';

  @override
  String get clear => 'साफ़ करें';

  @override
  String get open => 'खोलें';

  @override
  String get remove => 'निकालें';

  @override
  String get more => 'अधिक';

  @override
  String get overflowMore => 'और';

  @override
  String get selectAllRows => 'सभी पंक्तियाँ चुनें';

  @override
  String get selectRow => 'पंक्ति चुनें';

  @override
  String get sort => 'क्रमबद्ध करें';

  @override
  String get sortedAscending => 'आरोही क्रम में क्रमबद्ध';

  @override
  String get sortedDescending => 'अवरोही क्रम में क्रमबद्ध';

  @override
  String get previousSlide => 'पिछली स्लाइड';

  @override
  String get nextSlide => 'अगली स्लाइड';

  @override
  String get startSlideShow => 'स्वचालित स्लाइड शो प्रारंभ करें';

  @override
  String get pauseSlideShow => 'स्वचालित स्लाइड शो रोकें';

  @override
  String slideOf(int index, int count) {
    return '$count में से स्लाइड $index';
  }

  @override
  String stepOf(int index, int count) {
    return '$count में से चरण $index';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$max में से $value';
  }

  @override
  String get openCalendar => 'कैलेंडर खोलें';

  @override
  String get invalidDateFormat => 'अमान्य दिनांक स्वरूप।';

  @override
  String get dateOutOfRange => 'दिनांक अनुमत श्रेणी से बाहर है।';

  @override
  String get fieldRequired => 'यह फ़ील्ड आवश्यक है।';

  @override
  String get goToToday => 'आज पर जाएँ';

  @override
  String get previousMonth => 'पिछला महीना';

  @override
  String get nextMonth => 'अगला महीना';

  @override
  String get previousYear => 'पिछला वर्ष';

  @override
  String get nextYear => 'अगला वर्ष';

  @override
  String get previousYearRange => 'पिछली वर्ष श्रेणी';

  @override
  String get nextYearRange => 'अगली वर्ष श्रेणी';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, वर्ष बदलें';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, महीना बदलें';
  }

  @override
  String selectedDate(String date) {
    return 'चयनित दिनांक $date';
  }

  @override
  String todaysDate(String date) {
    return 'आज का दिनांक $date';
  }

  @override
  String weekNumber(String number) {
    return 'सप्ताह $number';
  }

  @override
  String get chartNoData => 'ग्राफ़ में दिखाने के लिए कोई डेटा नहीं है';

  @override
  String get chartNoDataAvailable => 'कोई डेटा उपलब्ध नहीं';

  @override
  String get chartFallbackTitle => 'चार्ट। ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return '$axis अक्ष $subject दिखाता है। ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'द्वितीयक Y';

  @override
  String get chartAxisCategories => 'श्रेणियाँ';

  @override
  String get chartAxisTime => 'समय';

  @override
  String get chartAxisValues => 'मान';

  @override
  String get chartLineLegendFallback => 'रेखा';

  @override
  String funnelChartDescription(int count) {
    return '$count खंडों वाला फ़नल चार्ट';
  }

  @override
  String donutChartDescription(int count) {
    return '$count स्लाइस वाला डोनट चार्ट';
  }

  @override
  String gaugeChartDescription(int count) {
    return '$count खंडों वाला गेज चार्ट। ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'वर्तमान मान: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'वर्तमान मान $value है';
  }

  @override
  String gaugeMinValue(String value) {
    return 'न्यूनतम मान: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'अधिकतम मान: $value';
  }

  @override
  String get gaugeUnknownSegment => 'अज्ञात';

  @override
  String ganttChartDescription(int count) {
    return '$count डेटा बिंदुओं वाला गैंट चार्ट। ';
  }

  @override
  String heatMapChartDescription(int count) {
    return '$count डेटा बिंदुओं वाला हीट मैप चार्ट। ';
  }

  @override
  String polarChartDescription(int count) {
    return '$count डेटा शृंखलाओं वाला ध्रुवीय चार्ट।';
  }

  @override
  String sparklineDescription(String label) {
    return '$label लेबल वाली स्पार्कलाइन';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return '$nodes नोड और $links लिंक वाला सैंकी चार्ट';
  }

  @override
  String sankeyLinkFrom(String node) {
    return '$node से';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return '$weight भार वाला नोड $name';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return '$weight भार वाला $source से $target तक का लिंक';
  }

  @override
  String verticalBarChartDescription(int count) {
    return '$count बार वाला ऊर्ध्वाधर बार चार्ट। ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return '$count बार और 1 रेखा वाला ऊर्ध्वाधर बार चार्ट। ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return '$count समूहीकृत बार शृंखलाओं वाला ऊर्ध्वाधर बार चार्ट। ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return '$count समूहीकृत बार शृंखलाओं और $lines रेखा शृंखलाओं वाला ऊर्ध्वाधर बार चार्ट। ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return '$count स्टैक्ड बार वाला ऊर्ध्वाधर बार चार्ट। ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return '$count स्टैक्ड बार और $lines रेखाओं वाला ऊर्ध्वाधर बार चार्ट। ';
  }

  @override
  String get presenceAvailable => 'उपलब्ध';

  @override
  String get presenceAway => 'दूर';

  @override
  String get presenceBusy => 'व्यस्त';

  @override
  String get presenceDoNotDisturb => 'परेशान न करें';

  @override
  String get presenceBlocked => 'अवरोधित';

  @override
  String get presenceOffline => 'ऑफ़लाइन';

  @override
  String get presenceOutOfOffice => 'कार्यालय से बाहर';

  @override
  String get presenceUnknown => 'अज्ञात';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, कार्यालय से बाहर';
  }
}
