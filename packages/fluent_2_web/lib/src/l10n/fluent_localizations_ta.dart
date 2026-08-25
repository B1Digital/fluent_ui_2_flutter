// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fluent_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class FluentLocalizationsTa extends FluentLocalizations {
  FluentLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get close => 'மூடு';

  @override
  String get dismiss => 'நிராகரி';

  @override
  String get clear => 'அழி';

  @override
  String get open => 'திற';

  @override
  String get remove => 'அகற்று';

  @override
  String get more => 'மேலும்';

  @override
  String get overflowMore => 'மேலும்';

  @override
  String get selectAllRows => 'எல்லா வரிசைகளையும் தேர்ந்தெடு';

  @override
  String get selectRow => 'வரிசையைத் தேர்ந்தெடு';

  @override
  String get sort => 'வரிசைப்படுத்து';

  @override
  String get sortedAscending => 'ஏறுவரிசையில் வரிசைப்படுத்தப்பட்டது';

  @override
  String get sortedDescending => 'இறங்குவரிசையில் வரிசைப்படுத்தப்பட்டது';

  @override
  String get previousSlide => 'முந்தைய ஸ்லைடு';

  @override
  String get nextSlide => 'அடுத்த ஸ்லைடு';

  @override
  String get startSlideShow => 'தானியங்கு ஸ்லைடு காட்சியைத் தொடங்கு';

  @override
  String get pauseSlideShow => 'தானியங்கு ஸ்லைடு காட்சியை இடைநிறுத்து';

  @override
  String slideOf(int index, int count) {
    return '$count இல் $index ஆவது ஸ்லைடு';
  }

  @override
  String stepOf(int index, int count) {
    return '$count இல் $index ஆவது படி';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$max இல் $value';
  }

  @override
  String get openCalendar => 'நாள்காட்டியைத் திற';

  @override
  String get invalidDateFormat => 'தவறான தேதி வடிவம்.';

  @override
  String get dateOutOfRange => 'தேதி அனுமதிக்கப்பட்ட வரம்பிற்கு வெளியே உள்ளது.';

  @override
  String get fieldRequired => 'இந்தப் புலம் தேவை.';

  @override
  String get goToToday => 'இன்றைய தேதிக்குச் செல்';

  @override
  String get previousMonth => 'முந்தைய மாதம்';

  @override
  String get nextMonth => 'அடுத்த மாதம்';

  @override
  String get previousYear => 'முந்தைய ஆண்டு';

  @override
  String get nextYear => 'அடுத்த ஆண்டு';

  @override
  String get previousYearRange => 'முந்தைய ஆண்டு வரம்பு';

  @override
  String get nextYearRange => 'அடுத்த ஆண்டு வரம்பு';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, ஆண்டை மாற்று';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, மாதத்தை மாற்று';
  }

  @override
  String selectedDate(String date) {
    return 'தேர்ந்தெடுக்கப்பட்ட தேதி $date';
  }

  @override
  String todaysDate(String date) {
    return 'இன்றைய தேதி $date';
  }

  @override
  String weekNumber(String number) {
    return 'வாரம் $number';
  }

  @override
  String get chartNoData => 'வரைபடத்தில் காட்ட தரவு எதுவும் இல்லை';

  @override
  String get chartNoDataAvailable => 'தரவு எதுவும் இல்லை';

  @override
  String get chartFallbackTitle => 'விளக்கப்படம். ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return '$axis அச்சில் $subject காட்டப்படுகிறது. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'இரண்டாம் நிலை Y';

  @override
  String get chartAxisCategories => 'வகைகள்';

  @override
  String get chartAxisTime => 'நேரம்';

  @override
  String get chartAxisValues => 'மதிப்புகள்';

  @override
  String get chartLineLegendFallback => 'கோடு';

  @override
  String funnelChartDescription(int count) {
    return '$count பிரிவுகளைக் கொண்ட புனல் விளக்கப்படம்';
  }

  @override
  String donutChartDescription(int count) {
    return '$count பகுதிகளைக் கொண்ட வளைய விளக்கப்படம்';
  }

  @override
  String gaugeChartDescription(int count) {
    return '$count பிரிவுகளைக் கொண்ட அளவுமானி விளக்கப்படம். ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'தற்போதைய மதிப்பு: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'தற்போதைய மதிப்பு $value ஆகும்';
  }

  @override
  String gaugeMinValue(String value) {
    return 'குறைந்தபட்ச மதிப்பு: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'அதிகபட்ச மதிப்பு: $value';
  }

  @override
  String get gaugeUnknownSegment => 'தெரியாதது';

  @override
  String ganttChartDescription(int count) {
    return '$count தரவுப் புள்ளிகளைக் கொண்ட கான்ட் விளக்கப்படம். ';
  }

  @override
  String heatMapChartDescription(int count) {
    return '$count தரவுப் புள்ளிகளைக் கொண்ட வெப்ப வரைபடம். ';
  }

  @override
  String polarChartDescription(int count) {
    return '$count தரவுத் தொடர்களைக் கொண்ட துருவ விளக்கப்படம்.';
  }

  @override
  String sparklineDescription(String label) {
    return '$label லேபிளுடன் கூடிய ஸ்பார்க்லைன்';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return '$nodes கணுக்கள் மற்றும் $links இணைப்புகளைக் கொண்ட சான்கி விளக்கப்படம்';
  }

  @override
  String sankeyLinkFrom(String node) {
    return '$node இலிருந்து';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return '$weight எடை கொண்ட $name கணு';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return '$source இலிருந்து $target வரை $weight எடை கொண்ட இணைப்பு';
  }

  @override
  String verticalBarChartDescription(int count) {
    return '$count பட்டைகளைக் கொண்ட செங்குத்துப் பட்டை விளக்கப்படம். ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return '$count பட்டைகள் மற்றும் 1 கோடு கொண்ட செங்குத்துப் பட்டை விளக்கப்படம். ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return '$count தொகுக்கப்பட்ட பட்டைத் தொடர்களைக் கொண்ட செங்குத்துப் பட்டை விளக்கப்படம். ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return '$count தொகுக்கப்பட்ட பட்டைத் தொடர்கள் மற்றும் $lines கோட்டுத் தொடர்களைக் கொண்ட செங்குத்துப் பட்டை விளக்கப்படம். ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return '$count அடுக்கப்பட்ட பட்டைகளைக் கொண்ட செங்குத்துப் பட்டை விளக்கப்படம். ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return '$count அடுக்கப்பட்ட பட்டைகள் மற்றும் $lines கோடுகளைக் கொண்ட செங்குத்துப் பட்டை விளக்கப்படம். ';
  }

  @override
  String get presenceAvailable => 'கிடைக்கிறார்';

  @override
  String get presenceAway => 'வெளியில் உள்ளார்';

  @override
  String get presenceBusy => 'மும்முரமாக உள்ளார்';

  @override
  String get presenceDoNotDisturb => 'தொந்தரவு செய்ய வேண்டாம்';

  @override
  String get presenceBlocked => 'தடுக்கப்பட்டது';

  @override
  String get presenceOffline => 'ஆஃப்லைன்';

  @override
  String get presenceOutOfOffice => 'அலுவலகத்தில் இல்லை';

  @override
  String get presenceUnknown => 'தெரியவில்லை';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, அலுவலகத்தில் இல்லை';
  }
}

/// The translations for Tamil, as used in India (`ta_IN`).
class FluentLocalizationsTaIn extends FluentLocalizationsTa {
  FluentLocalizationsTaIn() : super('ta_IN');

  @override
  String get close => 'மூடு';

  @override
  String get dismiss => 'நிராகரி';

  @override
  String get clear => 'அழி';

  @override
  String get open => 'திற';

  @override
  String get remove => 'அகற்று';

  @override
  String get more => 'மேலும்';

  @override
  String get overflowMore => 'மேலும்';

  @override
  String get selectAllRows => 'எல்லா வரிசைகளையும் தேர்ந்தெடு';

  @override
  String get selectRow => 'வரிசையைத் தேர்ந்தெடு';

  @override
  String get sort => 'வரிசைப்படுத்து';

  @override
  String get sortedAscending => 'ஏறுவரிசையில் வரிசைப்படுத்தப்பட்டது';

  @override
  String get sortedDescending => 'இறங்குவரிசையில் வரிசைப்படுத்தப்பட்டது';

  @override
  String get previousSlide => 'முந்தைய ஸ்லைடு';

  @override
  String get nextSlide => 'அடுத்த ஸ்லைடு';

  @override
  String get startSlideShow => 'தானியங்கு ஸ்லைடு காட்சியைத் தொடங்கு';

  @override
  String get pauseSlideShow => 'தானியங்கு ஸ்லைடு காட்சியை இடைநிறுத்து';

  @override
  String slideOf(int index, int count) {
    return '$count இல் $index ஆவது ஸ்லைடு';
  }

  @override
  String stepOf(int index, int count) {
    return '$count இல் $index ஆவது படி';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$max இல் $value';
  }

  @override
  String get openCalendar => 'நாள்காட்டியைத் திற';

  @override
  String get invalidDateFormat => 'தவறான தேதி வடிவம்.';

  @override
  String get dateOutOfRange => 'தேதி அனுமதிக்கப்பட்ட வரம்பிற்கு வெளியே உள்ளது.';

  @override
  String get fieldRequired => 'இந்தப் புலம் தேவை.';

  @override
  String get goToToday => 'இன்றைய தேதிக்குச் செல்';

  @override
  String get previousMonth => 'முந்தைய மாதம்';

  @override
  String get nextMonth => 'அடுத்த மாதம்';

  @override
  String get previousYear => 'முந்தைய ஆண்டு';

  @override
  String get nextYear => 'அடுத்த ஆண்டு';

  @override
  String get previousYearRange => 'முந்தைய ஆண்டு வரம்பு';

  @override
  String get nextYearRange => 'அடுத்த ஆண்டு வரம்பு';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, ஆண்டை மாற்று';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, மாதத்தை மாற்று';
  }

  @override
  String selectedDate(String date) {
    return 'தேர்ந்தெடுக்கப்பட்ட தேதி $date';
  }

  @override
  String todaysDate(String date) {
    return 'இன்றைய தேதி $date';
  }

  @override
  String weekNumber(String number) {
    return 'வாரம் $number';
  }

  @override
  String get chartNoData => 'வரைபடத்தில் காட்ட தரவு எதுவும் இல்லை';

  @override
  String get chartNoDataAvailable => 'தரவு எதுவும் இல்லை';

  @override
  String get chartFallbackTitle => 'விளக்கப்படம். ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return '$axis அச்சில் $subject காட்டப்படுகிறது. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'இரண்டாம் நிலை Y';

  @override
  String get chartAxisCategories => 'வகைகள்';

  @override
  String get chartAxisTime => 'நேரம்';

  @override
  String get chartAxisValues => 'மதிப்புகள்';

  @override
  String get chartLineLegendFallback => 'கோடு';

  @override
  String funnelChartDescription(int count) {
    return '$count பிரிவுகளைக் கொண்ட புனல் விளக்கப்படம்';
  }

  @override
  String donutChartDescription(int count) {
    return '$count பகுதிகளைக் கொண்ட வளைய விளக்கப்படம்';
  }

  @override
  String gaugeChartDescription(int count) {
    return '$count பிரிவுகளைக் கொண்ட அளவுமானி விளக்கப்படம். ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'தற்போதைய மதிப்பு: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'தற்போதைய மதிப்பு $value ஆகும்';
  }

  @override
  String gaugeMinValue(String value) {
    return 'குறைந்தபட்ச மதிப்பு: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'அதிகபட்ச மதிப்பு: $value';
  }

  @override
  String get gaugeUnknownSegment => 'தெரியாதது';

  @override
  String ganttChartDescription(int count) {
    return '$count தரவுப் புள்ளிகளைக் கொண்ட கான்ட் விளக்கப்படம். ';
  }

  @override
  String heatMapChartDescription(int count) {
    return '$count தரவுப் புள்ளிகளைக் கொண்ட வெப்ப வரைபடம். ';
  }

  @override
  String polarChartDescription(int count) {
    return '$count தரவுத் தொடர்களைக் கொண்ட துருவ விளக்கப்படம்.';
  }

  @override
  String sparklineDescription(String label) {
    return '$label லேபிளுடன் கூடிய ஸ்பார்க்லைன்';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return '$nodes கணுக்கள் மற்றும் $links இணைப்புகளைக் கொண்ட சான்கி விளக்கப்படம்';
  }

  @override
  String sankeyLinkFrom(String node) {
    return '$node இலிருந்து';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return '$weight எடை கொண்ட $name கணு';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return '$source இலிருந்து $target வரை $weight எடை கொண்ட இணைப்பு';
  }

  @override
  String verticalBarChartDescription(int count) {
    return '$count பட்டைகளைக் கொண்ட செங்குத்துப் பட்டை விளக்கப்படம். ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return '$count பட்டைகள் மற்றும் 1 கோடு கொண்ட செங்குத்துப் பட்டை விளக்கப்படம். ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return '$count தொகுக்கப்பட்ட பட்டைத் தொடர்களைக் கொண்ட செங்குத்துப் பட்டை விளக்கப்படம். ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return '$count தொகுக்கப்பட்ட பட்டைத் தொடர்கள் மற்றும் $lines கோட்டுத் தொடர்களைக் கொண்ட செங்குத்துப் பட்டை விளக்கப்படம். ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return '$count அடுக்கப்பட்ட பட்டைகளைக் கொண்ட செங்குத்துப் பட்டை விளக்கப்படம். ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return '$count அடுக்கப்பட்ட பட்டைகள் மற்றும் $lines கோடுகளைக் கொண்ட செங்குத்துப் பட்டை விளக்கப்படம். ';
  }

  @override
  String get presenceAvailable => 'கிடைக்கிறார்';

  @override
  String get presenceAway => 'வெளியில் உள்ளார்';

  @override
  String get presenceBusy => 'மும்முரமாக உள்ளார்';

  @override
  String get presenceDoNotDisturb => 'தொந்தரவு செய்ய வேண்டாம்';

  @override
  String get presenceBlocked => 'தடுக்கப்பட்டது';

  @override
  String get presenceOffline => 'ஆஃப்லைன்';

  @override
  String get presenceOutOfOffice => 'அலுவலகத்தில் இல்லை';

  @override
  String get presenceUnknown => 'தெரியவில்லை';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, அலுவலகத்தில் இல்லை';
  }
}

/// The translations for Tamil, as used in Sri Lanka (`ta_LK`).
class FluentLocalizationsTaLk extends FluentLocalizationsTa {
  FluentLocalizationsTaLk() : super('ta_LK');

  @override
  String get close => 'மூடு';

  @override
  String get dismiss => 'நிராகரி';

  @override
  String get clear => 'அழி';

  @override
  String get open => 'திற';

  @override
  String get remove => 'அகற்று';

  @override
  String get more => 'மேலும்';

  @override
  String get overflowMore => 'மேலும்';

  @override
  String get selectAllRows => 'எல்லா வரிசைகளையும் தேர்ந்தெடு';

  @override
  String get selectRow => 'வரிசையைத் தேர்ந்தெடு';

  @override
  String get sort => 'வரிசைப்படுத்து';

  @override
  String get sortedAscending => 'ஏறுவரிசையில் வரிசைப்படுத்தப்பட்டது';

  @override
  String get sortedDescending => 'இறங்குவரிசையில் வரிசைப்படுத்தப்பட்டது';

  @override
  String get previousSlide => 'முந்தைய ஸ்லைடு';

  @override
  String get nextSlide => 'அடுத்த ஸ்லைடு';

  @override
  String get startSlideShow => 'தானியங்கு ஸ்லைடு காட்சியைத் தொடங்கு';

  @override
  String get pauseSlideShow => 'தானியங்கு ஸ்லைடு காட்சியை இடைநிறுத்து';

  @override
  String slideOf(int index, int count) {
    return '$count இல் $index ஆவது ஸ்லைடு';
  }

  @override
  String stepOf(int index, int count) {
    return '$count இல் $index ஆவது படி';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$max இல் $value';
  }

  @override
  String get openCalendar => 'நாள்காட்டியைத் திற';

  @override
  String get invalidDateFormat => 'தவறான தேதி வடிவம்.';

  @override
  String get dateOutOfRange => 'தேதி அனுமதிக்கப்பட்ட வரம்பிற்கு வெளியே உள்ளது.';

  @override
  String get fieldRequired => 'இந்தப் புலம் தேவை.';

  @override
  String get goToToday => 'இன்றைய தேதிக்குச் செல்';

  @override
  String get previousMonth => 'முந்தைய மாதம்';

  @override
  String get nextMonth => 'அடுத்த மாதம்';

  @override
  String get previousYear => 'முந்தைய ஆண்டு';

  @override
  String get nextYear => 'அடுத்த ஆண்டு';

  @override
  String get previousYearRange => 'முந்தைய ஆண்டு வரம்பு';

  @override
  String get nextYearRange => 'அடுத்த ஆண்டு வரம்பு';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, ஆண்டை மாற்று';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, மாதத்தை மாற்று';
  }

  @override
  String selectedDate(String date) {
    return 'தேர்ந்தெடுக்கப்பட்ட தேதி $date';
  }

  @override
  String todaysDate(String date) {
    return 'இன்றைய தேதி $date';
  }

  @override
  String weekNumber(String number) {
    return 'வாரம் $number';
  }

  @override
  String get chartNoData => 'வரைபடத்தில் காட்ட தரவு எதுவும் இல்லை';

  @override
  String get chartNoDataAvailable => 'தரவு எதுவும் இல்லை';

  @override
  String get chartFallbackTitle => 'விளக்கப்படம். ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return '$axis அச்சில் $subject காட்டப்படுகிறது. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'இரண்டாம் நிலை Y';

  @override
  String get chartAxisCategories => 'வகைகள்';

  @override
  String get chartAxisTime => 'நேரம்';

  @override
  String get chartAxisValues => 'மதிப்புகள்';

  @override
  String get chartLineLegendFallback => 'கோடு';

  @override
  String funnelChartDescription(int count) {
    return '$count பிரிவுகளைக் கொண்ட புனல் விளக்கப்படம்';
  }

  @override
  String donutChartDescription(int count) {
    return '$count பகுதிகளைக் கொண்ட வளைய விளக்கப்படம்';
  }

  @override
  String gaugeChartDescription(int count) {
    return '$count பிரிவுகளைக் கொண்ட அளவுமானி விளக்கப்படம். ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'தற்போதைய மதிப்பு: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'தற்போதைய மதிப்பு $value ஆகும்';
  }

  @override
  String gaugeMinValue(String value) {
    return 'குறைந்தபட்ச மதிப்பு: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'அதிகபட்ச மதிப்பு: $value';
  }

  @override
  String get gaugeUnknownSegment => 'தெரியாதது';

  @override
  String ganttChartDescription(int count) {
    return '$count தரவுப் புள்ளிகளைக் கொண்ட கான்ட் விளக்கப்படம். ';
  }

  @override
  String heatMapChartDescription(int count) {
    return '$count தரவுப் புள்ளிகளைக் கொண்ட வெப்ப வரைபடம். ';
  }

  @override
  String polarChartDescription(int count) {
    return '$count தரவுத் தொடர்களைக் கொண்ட துருவ விளக்கப்படம்.';
  }

  @override
  String sparklineDescription(String label) {
    return '$label லேபிளுடன் கூடிய ஸ்பார்க்லைன்';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return '$nodes கணுக்கள் மற்றும் $links இணைப்புகளைக் கொண்ட சான்கி விளக்கப்படம்';
  }

  @override
  String sankeyLinkFrom(String node) {
    return '$node இலிருந்து';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return '$weight எடை கொண்ட $name கணு';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return '$source இலிருந்து $target வரை $weight எடை கொண்ட இணைப்பு';
  }

  @override
  String verticalBarChartDescription(int count) {
    return '$count பட்டைகளைக் கொண்ட செங்குத்துப் பட்டை விளக்கப்படம். ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return '$count பட்டைகள் மற்றும் 1 கோடு கொண்ட செங்குத்துப் பட்டை விளக்கப்படம். ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return '$count தொகுக்கப்பட்ட பட்டைத் தொடர்களைக் கொண்ட செங்குத்துப் பட்டை விளக்கப்படம். ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return '$count தொகுக்கப்பட்ட பட்டைத் தொடர்கள் மற்றும் $lines கோட்டுத் தொடர்களைக் கொண்ட செங்குத்துப் பட்டை விளக்கப்படம். ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return '$count அடுக்கப்பட்ட பட்டைகளைக் கொண்ட செங்குத்துப் பட்டை விளக்கப்படம். ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return '$count அடுக்கப்பட்ட பட்டைகள் மற்றும் $lines கோடுகளைக் கொண்ட செங்குத்துப் பட்டை விளக்கப்படம். ';
  }

  @override
  String get presenceAvailable => 'கிடைக்கிறார்';

  @override
  String get presenceAway => 'வெளியில் உள்ளார்';

  @override
  String get presenceBusy => 'மும்முரமாக உள்ளார்';

  @override
  String get presenceDoNotDisturb => 'தொந்தரவு செய்ய வேண்டாம்';

  @override
  String get presenceBlocked => 'தடுக்கப்பட்டது';

  @override
  String get presenceOffline => 'ஆஃப்லைன்';

  @override
  String get presenceOutOfOffice => 'அலுவலகத்தில் இல்லை';

  @override
  String get presenceUnknown => 'தெரியவில்லை';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, அலுவலகத்தில் இல்லை';
  }
}

/// The translations for Tamil, as used in Malaysia (`ta_MY`).
class FluentLocalizationsTaMy extends FluentLocalizationsTa {
  FluentLocalizationsTaMy() : super('ta_MY');

  @override
  String get close => 'மூடு';

  @override
  String get dismiss => 'நிராகரி';

  @override
  String get clear => 'அழி';

  @override
  String get open => 'திற';

  @override
  String get remove => 'அகற்று';

  @override
  String get more => 'மேலும்';

  @override
  String get overflowMore => 'மேலும்';

  @override
  String get selectAllRows => 'எல்லா வரிசைகளையும் தேர்ந்தெடு';

  @override
  String get selectRow => 'வரிசையைத் தேர்ந்தெடு';

  @override
  String get sort => 'வரிசைப்படுத்து';

  @override
  String get sortedAscending => 'ஏறுவரிசையில் வரிசைப்படுத்தப்பட்டது';

  @override
  String get sortedDescending => 'இறங்குவரிசையில் வரிசைப்படுத்தப்பட்டது';

  @override
  String get previousSlide => 'முந்தைய ஸ்லைடு';

  @override
  String get nextSlide => 'அடுத்த ஸ்லைடு';

  @override
  String get startSlideShow => 'தானியங்கு ஸ்லைடு காட்சியைத் தொடங்கு';

  @override
  String get pauseSlideShow => 'தானியங்கு ஸ்லைடு காட்சியை இடைநிறுத்து';

  @override
  String slideOf(int index, int count) {
    return '$count இல் $index ஆவது ஸ்லைடு';
  }

  @override
  String stepOf(int index, int count) {
    return '$count இல் $index ஆவது படி';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$max இல் $value';
  }

  @override
  String get openCalendar => 'நாள்காட்டியைத் திற';

  @override
  String get invalidDateFormat => 'தவறான தேதி வடிவம்.';

  @override
  String get dateOutOfRange => 'தேதி அனுமதிக்கப்பட்ட வரம்பிற்கு வெளியே உள்ளது.';

  @override
  String get fieldRequired => 'இந்தப் புலம் தேவை.';

  @override
  String get goToToday => 'இன்றைய தேதிக்குச் செல்';

  @override
  String get previousMonth => 'முந்தைய மாதம்';

  @override
  String get nextMonth => 'அடுத்த மாதம்';

  @override
  String get previousYear => 'முந்தைய ஆண்டு';

  @override
  String get nextYear => 'அடுத்த ஆண்டு';

  @override
  String get previousYearRange => 'முந்தைய ஆண்டு வரம்பு';

  @override
  String get nextYearRange => 'அடுத்த ஆண்டு வரம்பு';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, ஆண்டை மாற்று';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, மாதத்தை மாற்று';
  }

  @override
  String selectedDate(String date) {
    return 'தேர்ந்தெடுக்கப்பட்ட தேதி $date';
  }

  @override
  String todaysDate(String date) {
    return 'இன்றைய தேதி $date';
  }

  @override
  String weekNumber(String number) {
    return 'வாரம் $number';
  }

  @override
  String get chartNoData => 'வரைபடத்தில் காட்ட தரவு எதுவும் இல்லை';

  @override
  String get chartNoDataAvailable => 'தரவு எதுவும் இல்லை';

  @override
  String get chartFallbackTitle => 'விளக்கப்படம். ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return '$axis அச்சில் $subject காட்டப்படுகிறது. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'இரண்டாம் நிலை Y';

  @override
  String get chartAxisCategories => 'வகைகள்';

  @override
  String get chartAxisTime => 'நேரம்';

  @override
  String get chartAxisValues => 'மதிப்புகள்';

  @override
  String get chartLineLegendFallback => 'கோடு';

  @override
  String funnelChartDescription(int count) {
    return '$count பிரிவுகளைக் கொண்ட புனல் விளக்கப்படம்';
  }

  @override
  String donutChartDescription(int count) {
    return '$count பகுதிகளைக் கொண்ட வளைய விளக்கப்படம்';
  }

  @override
  String gaugeChartDescription(int count) {
    return '$count பிரிவுகளைக் கொண்ட அளவுமானி விளக்கப்படம். ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'தற்போதைய மதிப்பு: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'தற்போதைய மதிப்பு $value ஆகும்';
  }

  @override
  String gaugeMinValue(String value) {
    return 'குறைந்தபட்ச மதிப்பு: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'அதிகபட்ச மதிப்பு: $value';
  }

  @override
  String get gaugeUnknownSegment => 'தெரியாதது';

  @override
  String ganttChartDescription(int count) {
    return '$count தரவுப் புள்ளிகளைக் கொண்ட கான்ட் விளக்கப்படம். ';
  }

  @override
  String heatMapChartDescription(int count) {
    return '$count தரவுப் புள்ளிகளைக் கொண்ட வெப்ப வரைபடம். ';
  }

  @override
  String polarChartDescription(int count) {
    return '$count தரவுத் தொடர்களைக் கொண்ட துருவ விளக்கப்படம்.';
  }

  @override
  String sparklineDescription(String label) {
    return '$label லேபிளுடன் கூடிய ஸ்பார்க்லைன்';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return '$nodes கணுக்கள் மற்றும் $links இணைப்புகளைக் கொண்ட சான்கி விளக்கப்படம்';
  }

  @override
  String sankeyLinkFrom(String node) {
    return '$node இலிருந்து';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return '$weight எடை கொண்ட $name கணு';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return '$source இலிருந்து $target வரை $weight எடை கொண்ட இணைப்பு';
  }

  @override
  String verticalBarChartDescription(int count) {
    return '$count பட்டைகளைக் கொண்ட செங்குத்துப் பட்டை விளக்கப்படம். ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return '$count பட்டைகள் மற்றும் 1 கோடு கொண்ட செங்குத்துப் பட்டை விளக்கப்படம். ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return '$count தொகுக்கப்பட்ட பட்டைத் தொடர்களைக் கொண்ட செங்குத்துப் பட்டை விளக்கப்படம். ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return '$count தொகுக்கப்பட்ட பட்டைத் தொடர்கள் மற்றும் $lines கோட்டுத் தொடர்களைக் கொண்ட செங்குத்துப் பட்டை விளக்கப்படம். ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return '$count அடுக்கப்பட்ட பட்டைகளைக் கொண்ட செங்குத்துப் பட்டை விளக்கப்படம். ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return '$count அடுக்கப்பட்ட பட்டைகள் மற்றும் $lines கோடுகளைக் கொண்ட செங்குத்துப் பட்டை விளக்கப்படம். ';
  }

  @override
  String get presenceAvailable => 'கிடைக்கிறார்';

  @override
  String get presenceAway => 'வெளியில் உள்ளார்';

  @override
  String get presenceBusy => 'மும்முரமாக உள்ளார்';

  @override
  String get presenceDoNotDisturb => 'தொந்தரவு செய்ய வேண்டாம்';

  @override
  String get presenceBlocked => 'தடுக்கப்பட்டது';

  @override
  String get presenceOffline => 'ஆஃப்லைன்';

  @override
  String get presenceOutOfOffice => 'அலுவலகத்தில் இல்லை';

  @override
  String get presenceUnknown => 'தெரியவில்லை';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, அலுவலகத்தில் இல்லை';
  }
}

/// The translations for Tamil, as used in Singapore (`ta_SG`).
class FluentLocalizationsTaSg extends FluentLocalizationsTa {
  FluentLocalizationsTaSg() : super('ta_SG');

  @override
  String get close => 'மூடு';

  @override
  String get dismiss => 'நிராகரி';

  @override
  String get clear => 'அழி';

  @override
  String get open => 'திற';

  @override
  String get remove => 'அகற்று';

  @override
  String get more => 'மேலும்';

  @override
  String get overflowMore => 'மேலும்';

  @override
  String get selectAllRows => 'எல்லா வரிசைகளையும் தேர்ந்தெடு';

  @override
  String get selectRow => 'வரிசையைத் தேர்ந்தெடு';

  @override
  String get sort => 'வரிசைப்படுத்து';

  @override
  String get sortedAscending => 'ஏறுவரிசையில் வரிசைப்படுத்தப்பட்டது';

  @override
  String get sortedDescending => 'இறங்குவரிசையில் வரிசைப்படுத்தப்பட்டது';

  @override
  String get previousSlide => 'முந்தைய ஸ்லைடு';

  @override
  String get nextSlide => 'அடுத்த ஸ்லைடு';

  @override
  String get startSlideShow => 'தானியங்கு ஸ்லைடு காட்சியைத் தொடங்கு';

  @override
  String get pauseSlideShow => 'தானியங்கு ஸ்லைடு காட்சியை இடைநிறுத்து';

  @override
  String slideOf(int index, int count) {
    return '$count இல் $index ஆவது ஸ்லைடு';
  }

  @override
  String stepOf(int index, int count) {
    return '$count இல் $index ஆவது படி';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$max இல் $value';
  }

  @override
  String get openCalendar => 'நாள்காட்டியைத் திற';

  @override
  String get invalidDateFormat => 'தவறான தேதி வடிவம்.';

  @override
  String get dateOutOfRange => 'தேதி அனுமதிக்கப்பட்ட வரம்பிற்கு வெளியே உள்ளது.';

  @override
  String get fieldRequired => 'இந்தப் புலம் தேவை.';

  @override
  String get goToToday => 'இன்றைய தேதிக்குச் செல்';

  @override
  String get previousMonth => 'முந்தைய மாதம்';

  @override
  String get nextMonth => 'அடுத்த மாதம்';

  @override
  String get previousYear => 'முந்தைய ஆண்டு';

  @override
  String get nextYear => 'அடுத்த ஆண்டு';

  @override
  String get previousYearRange => 'முந்தைய ஆண்டு வரம்பு';

  @override
  String get nextYearRange => 'அடுத்த ஆண்டு வரம்பு';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, ஆண்டை மாற்று';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, மாதத்தை மாற்று';
  }

  @override
  String selectedDate(String date) {
    return 'தேர்ந்தெடுக்கப்பட்ட தேதி $date';
  }

  @override
  String todaysDate(String date) {
    return 'இன்றைய தேதி $date';
  }

  @override
  String weekNumber(String number) {
    return 'வாரம் $number';
  }

  @override
  String get chartNoData => 'வரைபடத்தில் காட்ட தரவு எதுவும் இல்லை';

  @override
  String get chartNoDataAvailable => 'தரவு எதுவும் இல்லை';

  @override
  String get chartFallbackTitle => 'விளக்கப்படம். ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return '$axis அச்சில் $subject காட்டப்படுகிறது. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'இரண்டாம் நிலை Y';

  @override
  String get chartAxisCategories => 'வகைகள்';

  @override
  String get chartAxisTime => 'நேரம்';

  @override
  String get chartAxisValues => 'மதிப்புகள்';

  @override
  String get chartLineLegendFallback => 'கோடு';

  @override
  String funnelChartDescription(int count) {
    return '$count பிரிவுகளைக் கொண்ட புனல் விளக்கப்படம்';
  }

  @override
  String donutChartDescription(int count) {
    return '$count பகுதிகளைக் கொண்ட வளைய விளக்கப்படம்';
  }

  @override
  String gaugeChartDescription(int count) {
    return '$count பிரிவுகளைக் கொண்ட அளவுமானி விளக்கப்படம். ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'தற்போதைய மதிப்பு: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'தற்போதைய மதிப்பு $value ஆகும்';
  }

  @override
  String gaugeMinValue(String value) {
    return 'குறைந்தபட்ச மதிப்பு: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'அதிகபட்ச மதிப்பு: $value';
  }

  @override
  String get gaugeUnknownSegment => 'தெரியாதது';

  @override
  String ganttChartDescription(int count) {
    return '$count தரவுப் புள்ளிகளைக் கொண்ட கான்ட் விளக்கப்படம். ';
  }

  @override
  String heatMapChartDescription(int count) {
    return '$count தரவுப் புள்ளிகளைக் கொண்ட வெப்ப வரைபடம். ';
  }

  @override
  String polarChartDescription(int count) {
    return '$count தரவுத் தொடர்களைக் கொண்ட துருவ விளக்கப்படம்.';
  }

  @override
  String sparklineDescription(String label) {
    return '$label லேபிளுடன் கூடிய ஸ்பார்க்லைன்';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return '$nodes கணுக்கள் மற்றும் $links இணைப்புகளைக் கொண்ட சான்கி விளக்கப்படம்';
  }

  @override
  String sankeyLinkFrom(String node) {
    return '$node இலிருந்து';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return '$weight எடை கொண்ட $name கணு';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return '$source இலிருந்து $target வரை $weight எடை கொண்ட இணைப்பு';
  }

  @override
  String verticalBarChartDescription(int count) {
    return '$count பட்டைகளைக் கொண்ட செங்குத்துப் பட்டை விளக்கப்படம். ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return '$count பட்டைகள் மற்றும் 1 கோடு கொண்ட செங்குத்துப் பட்டை விளக்கப்படம். ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return '$count தொகுக்கப்பட்ட பட்டைத் தொடர்களைக் கொண்ட செங்குத்துப் பட்டை விளக்கப்படம். ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return '$count தொகுக்கப்பட்ட பட்டைத் தொடர்கள் மற்றும் $lines கோட்டுத் தொடர்களைக் கொண்ட செங்குத்துப் பட்டை விளக்கப்படம். ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return '$count அடுக்கப்பட்ட பட்டைகளைக் கொண்ட செங்குத்துப் பட்டை விளக்கப்படம். ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return '$count அடுக்கப்பட்ட பட்டைகள் மற்றும் $lines கோடுகளைக் கொண்ட செங்குத்துப் பட்டை விளக்கப்படம். ';
  }

  @override
  String get presenceAvailable => 'கிடைக்கிறார்';

  @override
  String get presenceAway => 'வெளியில் உள்ளார்';

  @override
  String get presenceBusy => 'மும்முரமாக உள்ளார்';

  @override
  String get presenceDoNotDisturb => 'தொந்தரவு செய்ய வேண்டாம்';

  @override
  String get presenceBlocked => 'தடுக்கப்பட்டது';

  @override
  String get presenceOffline => 'ஆஃப்லைன்';

  @override
  String get presenceOutOfOffice => 'அலுவலகத்தில் இல்லை';

  @override
  String get presenceUnknown => 'தெரியவில்லை';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, அலுவலகத்தில் இல்லை';
  }
}
