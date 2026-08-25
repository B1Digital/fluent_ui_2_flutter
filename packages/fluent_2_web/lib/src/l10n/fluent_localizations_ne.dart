// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fluent_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Nepali (`ne`).
class FluentLocalizationsNe extends FluentLocalizations {
  FluentLocalizationsNe([String locale = 'ne']) : super(locale);

  @override
  String get close => 'बन्द गर्नुहोस्';

  @override
  String get dismiss => 'खारेज गर्नुहोस्';

  @override
  String get clear => 'खाली गर्नुहोस्';

  @override
  String get open => 'खोल्नुहोस्';

  @override
  String get remove => 'हटाउनुहोस्';

  @override
  String get more => 'थप';

  @override
  String get overflowMore => 'थप';

  @override
  String get selectAllRows => 'सबै पङ्क्ति चयन गर्नुहोस्';

  @override
  String get selectRow => 'पङ्क्ति चयन गर्नुहोस्';

  @override
  String get sort => 'क्रमबद्ध गर्नुहोस्';

  @override
  String get sortedAscending => 'बढ्दो क्रममा क्रमबद्ध';

  @override
  String get sortedDescending => 'घट्दो क्रममा क्रमबद्ध';

  @override
  String get previousSlide => 'अघिल्लो स्लाइड';

  @override
  String get nextSlide => 'अर्को स्लाइड';

  @override
  String get startSlideShow => 'स्वचालित स्लाइड प्रदर्शन सुरु गर्नुहोस्';

  @override
  String get pauseSlideShow => 'स्वचालित स्लाइड प्रदर्शन रोक्नुहोस्';

  @override
  String slideOf(int index, int count) {
    return '$count मध्ये स्लाइड $index';
  }

  @override
  String stepOf(int index, int count) {
    return '$count मध्ये चरण $index';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$max मध्ये $value';
  }

  @override
  String get openCalendar => 'पात्रो खोल्नुहोस्';

  @override
  String get invalidDateFormat => 'अमान्य मिति ढाँचा।';

  @override
  String get dateOutOfRange => 'मिति अनुमत दायरा बाहिर छ।';

  @override
  String get fieldRequired => 'यो फिल्ड आवश्यक छ।';

  @override
  String get goToToday => 'आजमा जानुहोस्';

  @override
  String get previousMonth => 'अघिल्लो महिना';

  @override
  String get nextMonth => 'अर्को महिना';

  @override
  String get previousYear => 'अघिल्लो वर्ष';

  @override
  String get nextYear => 'अर्को वर्ष';

  @override
  String get previousYearRange => 'अघिल्लो वर्ष दायरा';

  @override
  String get nextYearRange => 'अर्को वर्ष दायरा';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, वर्ष परिवर्तन गर्नुहोस्';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, महिना परिवर्तन गर्नुहोस्';
  }

  @override
  String selectedDate(String date) {
    return 'चयन गरिएको मिति $date';
  }

  @override
  String todaysDate(String date) {
    return 'आजको मिति $date';
  }

  @override
  String weekNumber(String number) {
    return 'हप्ता $number';
  }

  @override
  String get chartNoData => 'ग्राफमा देखाउन कुनै डेटा छैन';

  @override
  String get chartNoDataAvailable => 'कुनै डेटा उपलब्ध छैन';

  @override
  String get chartFallbackTitle => 'चार्ट। ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return '$axis अक्षले $subject देखाउँछ। ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'द्वितीयक Y';

  @override
  String get chartAxisCategories => 'कोटिहरू';

  @override
  String get chartAxisTime => 'समय';

  @override
  String get chartAxisValues => 'मानहरू';

  @override
  String get chartLineLegendFallback => 'रेखा';

  @override
  String funnelChartDescription(int count) {
    return '$count खण्ड भएको फनेल चार्ट';
  }

  @override
  String donutChartDescription(int count) {
    return '$count टुक्रा भएको डोनट चार्ट';
  }

  @override
  String gaugeChartDescription(int count) {
    return '$count खण्ड भएको गेज चार्ट। ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'हालको मान: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'हालको मान $value हो';
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
    return '$count डेटा बिन्दु भएको ग्यान्ट चार्ट। ';
  }

  @override
  String heatMapChartDescription(int count) {
    return '$count डेटा बिन्दु भएको ताप मानचित्र चार्ट। ';
  }

  @override
  String polarChartDescription(int count) {
    return '$count डेटा शृङ्खला भएको ध्रुवीय चार्ट।';
  }

  @override
  String sparklineDescription(String label) {
    return '$label लेबल भएको स्पार्कलाइन';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return '$nodes नोड र $links लिङ्क भएको स्यान्की चार्ट';
  }

  @override
  String sankeyLinkFrom(String node) {
    return '$node बाट';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'तौल $weight भएको नोड $name';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'तौल $weight भएको $source बाट $target सम्मको लिङ्क';
  }

  @override
  String verticalBarChartDescription(int count) {
    return '$count बार भएको ठाडो बार चार्ट। ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return '$count बार र 1 रेखा भएको ठाडो बार चार्ट। ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return '$count समूहबद्ध बार शृङ्खला भएको ठाडो बार चार्ट। ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return '$count समूहबद्ध बार शृङ्खला र $lines रेखा शृङ्खला भएको ठाडो बार चार्ट। ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return '$count स्ट्याक गरिएको बार भएको ठाडो बार चार्ट। ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return '$count स्ट्याक गरिएको बार र $lines रेखा भएको ठाडो बार चार्ट। ';
  }

  @override
  String get presenceAvailable => 'उपलब्ध';

  @override
  String get presenceAway => 'टाढा';

  @override
  String get presenceBusy => 'व्यस्त';

  @override
  String get presenceDoNotDisturb => 'बाधा नपुर्याउनुहोस्';

  @override
  String get presenceBlocked => 'अवरुद्ध';

  @override
  String get presenceOffline => 'अफलाइन';

  @override
  String get presenceOutOfOffice => 'कार्यालय बाहिर';

  @override
  String get presenceUnknown => 'अज्ञात';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, कार्यालय बाहिर';
  }
}

/// The translations for Nepali, as used in India (`ne_IN`).
class FluentLocalizationsNeIn extends FluentLocalizationsNe {
  FluentLocalizationsNeIn() : super('ne_IN');

  @override
  String get close => 'बन्द गर्नुहोस्';

  @override
  String get dismiss => 'खारेज गर्नुहोस्';

  @override
  String get clear => 'खाली गर्नुहोस्';

  @override
  String get open => 'खोल्नुहोस्';

  @override
  String get remove => 'हटाउनुहोस्';

  @override
  String get more => 'थप';

  @override
  String get overflowMore => 'थप';

  @override
  String get selectAllRows => 'सबै पङ्क्ति चयन गर्नुहोस्';

  @override
  String get selectRow => 'पङ्क्ति चयन गर्नुहोस्';

  @override
  String get sort => 'क्रमबद्ध गर्नुहोस्';

  @override
  String get sortedAscending => 'बढ्दो क्रममा क्रमबद्ध';

  @override
  String get sortedDescending => 'घट्दो क्रममा क्रमबद्ध';

  @override
  String get previousSlide => 'अघिल्लो स्लाइड';

  @override
  String get nextSlide => 'अर्को स्लाइड';

  @override
  String get startSlideShow => 'स्वचालित स्लाइड प्रदर्शन सुरु गर्नुहोस्';

  @override
  String get pauseSlideShow => 'स्वचालित स्लाइड प्रदर्शन रोक्नुहोस्';

  @override
  String slideOf(int index, int count) {
    return '$count मध्ये स्लाइड $index';
  }

  @override
  String stepOf(int index, int count) {
    return '$count मध्ये चरण $index';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$max मध्ये $value';
  }

  @override
  String get openCalendar => 'पात्रो खोल्नुहोस्';

  @override
  String get invalidDateFormat => 'अमान्य मिति ढाँचा।';

  @override
  String get dateOutOfRange => 'मिति अनुमत दायरा बाहिर छ।';

  @override
  String get fieldRequired => 'यो फिल्ड आवश्यक छ।';

  @override
  String get goToToday => 'आजमा जानुहोस्';

  @override
  String get previousMonth => 'अघिल्लो महिना';

  @override
  String get nextMonth => 'अर्को महिना';

  @override
  String get previousYear => 'अघिल्लो वर्ष';

  @override
  String get nextYear => 'अर्को वर्ष';

  @override
  String get previousYearRange => 'अघिल्लो वर्ष दायरा';

  @override
  String get nextYearRange => 'अर्को वर्ष दायरा';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, वर्ष परिवर्तन गर्नुहोस्';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, महिना परिवर्तन गर्नुहोस्';
  }

  @override
  String selectedDate(String date) {
    return 'चयन गरिएको मिति $date';
  }

  @override
  String todaysDate(String date) {
    return 'आजको मिति $date';
  }

  @override
  String weekNumber(String number) {
    return 'हप्ता $number';
  }

  @override
  String get chartNoData => 'ग्राफमा देखाउन कुनै डेटा छैन';

  @override
  String get chartNoDataAvailable => 'कुनै डेटा उपलब्ध छैन';

  @override
  String get chartFallbackTitle => 'चार्ट। ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return '$axis अक्षले $subject देखाउँछ। ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'द्वितीयक Y';

  @override
  String get chartAxisCategories => 'कोटिहरू';

  @override
  String get chartAxisTime => 'समय';

  @override
  String get chartAxisValues => 'मानहरू';

  @override
  String get chartLineLegendFallback => 'रेखा';

  @override
  String funnelChartDescription(int count) {
    return '$count खण्ड भएको फनेल चार्ट';
  }

  @override
  String donutChartDescription(int count) {
    return '$count टुक्रा भएको डोनट चार्ट';
  }

  @override
  String gaugeChartDescription(int count) {
    return '$count खण्ड भएको गेज चार्ट। ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'हालको मान: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'हालको मान $value हो';
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
    return '$count डेटा बिन्दु भएको ग्यान्ट चार्ट। ';
  }

  @override
  String heatMapChartDescription(int count) {
    return '$count डेटा बिन्दु भएको ताप मानचित्र चार्ट। ';
  }

  @override
  String polarChartDescription(int count) {
    return '$count डेटा शृङ्खला भएको ध्रुवीय चार्ट।';
  }

  @override
  String sparklineDescription(String label) {
    return '$label लेबल भएको स्पार्कलाइन';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return '$nodes नोड र $links लिङ्क भएको स्यान्की चार्ट';
  }

  @override
  String sankeyLinkFrom(String node) {
    return '$node बाट';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'तौल $weight भएको नोड $name';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'तौल $weight भएको $source बाट $target सम्मको लिङ्क';
  }

  @override
  String verticalBarChartDescription(int count) {
    return '$count बार भएको ठाडो बार चार्ट। ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return '$count बार र 1 रेखा भएको ठाडो बार चार्ट। ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return '$count समूहबद्ध बार शृङ्खला भएको ठाडो बार चार्ट। ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return '$count समूहबद्ध बार शृङ्खला र $lines रेखा शृङ्खला भएको ठाडो बार चार्ट। ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return '$count स्ट्याक गरिएको बार भएको ठाडो बार चार्ट। ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return '$count स्ट्याक गरिएको बार र $lines रेखा भएको ठाडो बार चार्ट। ';
  }

  @override
  String get presenceAvailable => 'उपलब्ध';

  @override
  String get presenceAway => 'टाढा';

  @override
  String get presenceBusy => 'व्यस्त';

  @override
  String get presenceDoNotDisturb => 'बाधा नपुर्याउनुहोस्';

  @override
  String get presenceBlocked => 'अवरुद्ध';

  @override
  String get presenceOffline => 'अफलाइन';

  @override
  String get presenceOutOfOffice => 'कार्यालय बाहिर';

  @override
  String get presenceUnknown => 'अज्ञात';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, कार्यालय बाहिर';
  }
}

/// The translations for Nepali, as used in Nepal (`ne_NP`).
class FluentLocalizationsNeNp extends FluentLocalizationsNe {
  FluentLocalizationsNeNp() : super('ne_NP');

  @override
  String get close => 'बन्द गर्नुहोस्';

  @override
  String get dismiss => 'खारेज गर्नुहोस्';

  @override
  String get clear => 'खाली गर्नुहोस्';

  @override
  String get open => 'खोल्नुहोस्';

  @override
  String get remove => 'हटाउनुहोस्';

  @override
  String get more => 'थप';

  @override
  String get overflowMore => 'थप';

  @override
  String get selectAllRows => 'सबै पङ्क्ति चयन गर्नुहोस्';

  @override
  String get selectRow => 'पङ्क्ति चयन गर्नुहोस्';

  @override
  String get sort => 'क्रमबद्ध गर्नुहोस्';

  @override
  String get sortedAscending => 'बढ्दो क्रममा क्रमबद्ध';

  @override
  String get sortedDescending => 'घट्दो क्रममा क्रमबद्ध';

  @override
  String get previousSlide => 'अघिल्लो स्लाइड';

  @override
  String get nextSlide => 'अर्को स्लाइड';

  @override
  String get startSlideShow => 'स्वचालित स्लाइड प्रदर्शन सुरु गर्नुहोस्';

  @override
  String get pauseSlideShow => 'स्वचालित स्लाइड प्रदर्शन रोक्नुहोस्';

  @override
  String slideOf(int index, int count) {
    return '$count मध्ये स्लाइड $index';
  }

  @override
  String stepOf(int index, int count) {
    return '$count मध्ये चरण $index';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$max मध्ये $value';
  }

  @override
  String get openCalendar => 'पात्रो खोल्नुहोस्';

  @override
  String get invalidDateFormat => 'अमान्य मिति ढाँचा।';

  @override
  String get dateOutOfRange => 'मिति अनुमत दायरा बाहिर छ।';

  @override
  String get fieldRequired => 'यो फिल्ड आवश्यक छ।';

  @override
  String get goToToday => 'आजमा जानुहोस्';

  @override
  String get previousMonth => 'अघिल्लो महिना';

  @override
  String get nextMonth => 'अर्को महिना';

  @override
  String get previousYear => 'अघिल्लो वर्ष';

  @override
  String get nextYear => 'अर्को वर्ष';

  @override
  String get previousYearRange => 'अघिल्लो वर्ष दायरा';

  @override
  String get nextYearRange => 'अर्को वर्ष दायरा';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, वर्ष परिवर्तन गर्नुहोस्';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, महिना परिवर्तन गर्नुहोस्';
  }

  @override
  String selectedDate(String date) {
    return 'चयन गरिएको मिति $date';
  }

  @override
  String todaysDate(String date) {
    return 'आजको मिति $date';
  }

  @override
  String weekNumber(String number) {
    return 'हप्ता $number';
  }

  @override
  String get chartNoData => 'ग्राफमा देखाउन कुनै डेटा छैन';

  @override
  String get chartNoDataAvailable => 'कुनै डेटा उपलब्ध छैन';

  @override
  String get chartFallbackTitle => 'चार्ट। ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return '$axis अक्षले $subject देखाउँछ। ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'द्वितीयक Y';

  @override
  String get chartAxisCategories => 'कोटिहरू';

  @override
  String get chartAxisTime => 'समय';

  @override
  String get chartAxisValues => 'मानहरू';

  @override
  String get chartLineLegendFallback => 'रेखा';

  @override
  String funnelChartDescription(int count) {
    return '$count खण्ड भएको फनेल चार्ट';
  }

  @override
  String donutChartDescription(int count) {
    return '$count टुक्रा भएको डोनट चार्ट';
  }

  @override
  String gaugeChartDescription(int count) {
    return '$count खण्ड भएको गेज चार्ट। ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'हालको मान: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'हालको मान $value हो';
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
    return '$count डेटा बिन्दु भएको ग्यान्ट चार्ट। ';
  }

  @override
  String heatMapChartDescription(int count) {
    return '$count डेटा बिन्दु भएको ताप मानचित्र चार्ट। ';
  }

  @override
  String polarChartDescription(int count) {
    return '$count डेटा शृङ्खला भएको ध्रुवीय चार्ट।';
  }

  @override
  String sparklineDescription(String label) {
    return '$label लेबल भएको स्पार्कलाइन';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return '$nodes नोड र $links लिङ्क भएको स्यान्की चार्ट';
  }

  @override
  String sankeyLinkFrom(String node) {
    return '$node बाट';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'तौल $weight भएको नोड $name';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'तौल $weight भएको $source बाट $target सम्मको लिङ्क';
  }

  @override
  String verticalBarChartDescription(int count) {
    return '$count बार भएको ठाडो बार चार्ट। ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return '$count बार र 1 रेखा भएको ठाडो बार चार्ट। ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return '$count समूहबद्ध बार शृङ्खला भएको ठाडो बार चार्ट। ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return '$count समूहबद्ध बार शृङ्खला र $lines रेखा शृङ्खला भएको ठाडो बार चार्ट। ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return '$count स्ट्याक गरिएको बार भएको ठाडो बार चार्ट। ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return '$count स्ट्याक गरिएको बार र $lines रेखा भएको ठाडो बार चार्ट। ';
  }

  @override
  String get presenceAvailable => 'उपलब्ध';

  @override
  String get presenceAway => 'टाढा';

  @override
  String get presenceBusy => 'व्यस्त';

  @override
  String get presenceDoNotDisturb => 'बाधा नपुर्याउनुहोस्';

  @override
  String get presenceBlocked => 'अवरुद्ध';

  @override
  String get presenceOffline => 'अफलाइन';

  @override
  String get presenceOutOfOffice => 'कार्यालय बाहिर';

  @override
  String get presenceUnknown => 'अज्ञात';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, कार्यालय बाहिर';
  }
}
