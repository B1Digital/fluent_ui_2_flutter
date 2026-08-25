// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fluent_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class FluentLocalizationsEn extends FluentLocalizations {
  FluentLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get close => 'Close';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get clear => 'Clear';

  @override
  String get open => 'Open';

  @override
  String get remove => 'Remove';

  @override
  String get more => 'More';

  @override
  String get overflowMore => 'more';

  @override
  String get selectAllRows => 'Select all rows';

  @override
  String get selectRow => 'Select row';

  @override
  String get sort => 'Sort';

  @override
  String get sortedAscending => 'Sorted ascending';

  @override
  String get sortedDescending => 'Sorted descending';

  @override
  String get previousSlide => 'Previous slide';

  @override
  String get nextSlide => 'Next slide';

  @override
  String get startSlideShow => 'Start automatic slide show';

  @override
  String get pauseSlideShow => 'Pause automatic slide show';

  @override
  String slideOf(int index, int count) {
    return 'Slide $index of $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Step $index of $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value of $max';
  }

  @override
  String get openCalendar => 'Open calendar';

  @override
  String get invalidDateFormat => 'Invalid date format.';

  @override
  String get dateOutOfRange => 'Date is out of the allowed range.';

  @override
  String get fieldRequired => 'This field is required.';

  @override
  String get goToToday => 'Go to today';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get previousYear => 'Previous year';

  @override
  String get nextYear => 'Next year';

  @override
  String get previousYearRange => 'Previous year range';

  @override
  String get nextYearRange => 'Next year range';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, change year';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, change month';
  }

  @override
  String selectedDate(String date) {
    return 'Selected date $date';
  }

  @override
  String todaysDate(String date) {
    return 'Today\'s date $date';
  }

  @override
  String weekNumber(String number) {
    return 'Week $number';
  }

  @override
  String get chartNoData => 'Graph has no data to display';

  @override
  String get chartNoDataAvailable => 'No data available';

  @override
  String get chartFallbackTitle => 'Chart. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'The $axis axis displays $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'secondary Y';

  @override
  String get chartAxisCategories => 'categories';

  @override
  String get chartAxisTime => 'time';

  @override
  String get chartAxisValues => 'values';

  @override
  String get chartLineLegendFallback => 'Line';

  @override
  String funnelChartDescription(int count) {
    return 'Funnel chart with $count segments';
  }

  @override
  String donutChartDescription(int count) {
    return 'Donut chart with $count slices';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Gauge chart with $count segments. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Current value: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Current value is $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Min value: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Max value: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Unknown';

  @override
  String ganttChartDescription(int count) {
    return 'Gantt chart with $count data points. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Heat map chart with $count data points. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Polar chart with $count data series.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Sparkline with label $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Sankey chart with $nodes nodes and $links links';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'From $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'node $name with weight $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'link from $source to $target with weight $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Vertical bar chart with $count bars. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Vertical bar chart with $count bars and 1 line. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Vertical bar chart with $count grouped bar series. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Vertical bar chart with $count grouped bar series and $lines line series. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Vertical bar chart with $count stacked bars. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Vertical bar chart with $count stacked bars and $lines lines. ';
  }

  @override
  String get presenceAvailable => 'Available';

  @override
  String get presenceAway => 'Away';

  @override
  String get presenceBusy => 'Busy';

  @override
  String get presenceDoNotDisturb => 'Do not disturb';

  @override
  String get presenceBlocked => 'Blocked';

  @override
  String get presenceOffline => 'Offline';

  @override
  String get presenceOutOfOffice => 'Out of office';

  @override
  String get presenceUnknown => 'Unknown';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status out of office';
  }
}

/// The translations for English, as used in Australia (`en_AU`).
class FluentLocalizationsEnAu extends FluentLocalizationsEn {
  FluentLocalizationsEnAu() : super('en_AU');

  @override
  String get close => 'Close';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get clear => 'Clear';

  @override
  String get open => 'Open';

  @override
  String get remove => 'Remove';

  @override
  String get more => 'More';

  @override
  String get overflowMore => 'more';

  @override
  String get selectAllRows => 'Select all rows';

  @override
  String get selectRow => 'Select row';

  @override
  String get sort => 'Sort';

  @override
  String get sortedAscending => 'Sorted ascending';

  @override
  String get sortedDescending => 'Sorted descending';

  @override
  String get previousSlide => 'Previous slide';

  @override
  String get nextSlide => 'Next slide';

  @override
  String get startSlideShow => 'Start automatic slide show';

  @override
  String get pauseSlideShow => 'Pause automatic slide show';

  @override
  String slideOf(int index, int count) {
    return 'Slide $index of $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Step $index of $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value of $max';
  }

  @override
  String get openCalendar => 'Open calendar';

  @override
  String get invalidDateFormat => 'Invalid date format.';

  @override
  String get dateOutOfRange => 'Date is out of the allowed range.';

  @override
  String get fieldRequired => 'This field is required.';

  @override
  String get goToToday => 'Go to today';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get previousYear => 'Previous year';

  @override
  String get nextYear => 'Next year';

  @override
  String get previousYearRange => 'Previous year range';

  @override
  String get nextYearRange => 'Next year range';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, change year';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, change month';
  }

  @override
  String selectedDate(String date) {
    return 'Selected date $date';
  }

  @override
  String todaysDate(String date) {
    return 'Today\'s date $date';
  }

  @override
  String weekNumber(String number) {
    return 'Week $number';
  }

  @override
  String get chartNoData => 'Graph has no data to display';

  @override
  String get chartNoDataAvailable => 'No data available';

  @override
  String get chartFallbackTitle => 'Chart. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'The $axis axis displays $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'secondary Y';

  @override
  String get chartAxisCategories => 'categories';

  @override
  String get chartAxisTime => 'time';

  @override
  String get chartAxisValues => 'values';

  @override
  String get chartLineLegendFallback => 'Line';

  @override
  String funnelChartDescription(int count) {
    return 'Funnel chart with $count segments';
  }

  @override
  String donutChartDescription(int count) {
    return 'Doughnut chart with $count slices';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Gauge chart with $count segments. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Current value: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Current value is $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Min value: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Max value: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Unknown';

  @override
  String ganttChartDescription(int count) {
    return 'Gantt chart with $count data points. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Heat map chart with $count data points. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Polar chart with $count data series.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Sparkline with label $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Sankey chart with $nodes nodes and $links links';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'From $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'node $name with weight $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'link from $source to $target with weight $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Vertical bar chart with $count bars. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Vertical bar chart with $count bars and 1 line. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Vertical bar chart with $count grouped bar series. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Vertical bar chart with $count grouped bar series and $lines line series. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Vertical bar chart with $count stacked bars. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Vertical bar chart with $count stacked bars and $lines lines. ';
  }

  @override
  String get presenceAvailable => 'Available';

  @override
  String get presenceAway => 'Away';

  @override
  String get presenceBusy => 'Busy';

  @override
  String get presenceDoNotDisturb => 'Do not disturb';

  @override
  String get presenceBlocked => 'Blocked';

  @override
  String get presenceOffline => 'Offline';

  @override
  String get presenceOutOfOffice => 'Out of office';

  @override
  String get presenceUnknown => 'Unknown';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status out of office';
  }
}

/// The translations for English, as used in Canada (`en_CA`).
class FluentLocalizationsEnCa extends FluentLocalizationsEn {
  FluentLocalizationsEnCa() : super('en_CA');

  @override
  String get close => 'Close';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get clear => 'Clear';

  @override
  String get open => 'Open';

  @override
  String get remove => 'Remove';

  @override
  String get more => 'More';

  @override
  String get overflowMore => 'more';

  @override
  String get selectAllRows => 'Select all rows';

  @override
  String get selectRow => 'Select row';

  @override
  String get sort => 'Sort';

  @override
  String get sortedAscending => 'Sorted ascending';

  @override
  String get sortedDescending => 'Sorted descending';

  @override
  String get previousSlide => 'Previous slide';

  @override
  String get nextSlide => 'Next slide';

  @override
  String get startSlideShow => 'Start automatic slide show';

  @override
  String get pauseSlideShow => 'Pause automatic slide show';

  @override
  String slideOf(int index, int count) {
    return 'Slide $index of $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Step $index of $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value of $max';
  }

  @override
  String get openCalendar => 'Open calendar';

  @override
  String get invalidDateFormat => 'Invalid date format.';

  @override
  String get dateOutOfRange => 'Date is out of the allowed range.';

  @override
  String get fieldRequired => 'This field is required.';

  @override
  String get goToToday => 'Go to today';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get previousYear => 'Previous year';

  @override
  String get nextYear => 'Next year';

  @override
  String get previousYearRange => 'Previous year range';

  @override
  String get nextYearRange => 'Next year range';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, change year';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, change month';
  }

  @override
  String selectedDate(String date) {
    return 'Selected date $date';
  }

  @override
  String todaysDate(String date) {
    return 'Today\'s date $date';
  }

  @override
  String weekNumber(String number) {
    return 'Week $number';
  }

  @override
  String get chartNoData => 'Graph has no data to display';

  @override
  String get chartNoDataAvailable => 'No data available';

  @override
  String get chartFallbackTitle => 'Chart. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'The $axis axis displays $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'secondary Y';

  @override
  String get chartAxisCategories => 'categories';

  @override
  String get chartAxisTime => 'time';

  @override
  String get chartAxisValues => 'values';

  @override
  String get chartLineLegendFallback => 'Line';

  @override
  String funnelChartDescription(int count) {
    return 'Funnel chart with $count segments';
  }

  @override
  String donutChartDescription(int count) {
    return 'Donut chart with $count slices';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Gauge chart with $count segments. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Current value: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Current value is $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Min value: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Max value: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Unknown';

  @override
  String ganttChartDescription(int count) {
    return 'Gantt chart with $count data points. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Heat map chart with $count data points. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Polar chart with $count data series.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Sparkline with label $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Sankey chart with $nodes nodes and $links links';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'From $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'node $name with weight $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'link from $source to $target with weight $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Vertical bar chart with $count bars. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Vertical bar chart with $count bars and 1 line. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Vertical bar chart with $count grouped bar series. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Vertical bar chart with $count grouped bar series and $lines line series. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Vertical bar chart with $count stacked bars. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Vertical bar chart with $count stacked bars and $lines lines. ';
  }

  @override
  String get presenceAvailable => 'Available';

  @override
  String get presenceAway => 'Away';

  @override
  String get presenceBusy => 'Busy';

  @override
  String get presenceDoNotDisturb => 'Do not disturb';

  @override
  String get presenceBlocked => 'Blocked';

  @override
  String get presenceOffline => 'Offline';

  @override
  String get presenceOutOfOffice => 'Out of office';

  @override
  String get presenceUnknown => 'Unknown';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status out of office';
  }
}

/// The translations for English, as used in the United Kingdom (`en_GB`).
class FluentLocalizationsEnGb extends FluentLocalizationsEn {
  FluentLocalizationsEnGb() : super('en_GB');

  @override
  String get close => 'Close';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get clear => 'Clear';

  @override
  String get open => 'Open';

  @override
  String get remove => 'Remove';

  @override
  String get more => 'More';

  @override
  String get overflowMore => 'more';

  @override
  String get selectAllRows => 'Select all rows';

  @override
  String get selectRow => 'Select row';

  @override
  String get sort => 'Sort';

  @override
  String get sortedAscending => 'Sorted ascending';

  @override
  String get sortedDescending => 'Sorted descending';

  @override
  String get previousSlide => 'Previous slide';

  @override
  String get nextSlide => 'Next slide';

  @override
  String get startSlideShow => 'Start automatic slide show';

  @override
  String get pauseSlideShow => 'Pause automatic slide show';

  @override
  String slideOf(int index, int count) {
    return 'Slide $index of $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Step $index of $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value of $max';
  }

  @override
  String get openCalendar => 'Open calendar';

  @override
  String get invalidDateFormat => 'Invalid date format.';

  @override
  String get dateOutOfRange => 'Date is out of the allowed range.';

  @override
  String get fieldRequired => 'This field is required.';

  @override
  String get goToToday => 'Go to today';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get previousYear => 'Previous year';

  @override
  String get nextYear => 'Next year';

  @override
  String get previousYearRange => 'Previous year range';

  @override
  String get nextYearRange => 'Next year range';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, change year';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, change month';
  }

  @override
  String selectedDate(String date) {
    return 'Selected date $date';
  }

  @override
  String todaysDate(String date) {
    return 'Today\'s date $date';
  }

  @override
  String weekNumber(String number) {
    return 'Week $number';
  }

  @override
  String get chartNoData => 'Graph has no data to display';

  @override
  String get chartNoDataAvailable => 'No data available';

  @override
  String get chartFallbackTitle => 'Chart. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'The $axis axis displays $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'secondary Y';

  @override
  String get chartAxisCategories => 'categories';

  @override
  String get chartAxisTime => 'time';

  @override
  String get chartAxisValues => 'values';

  @override
  String get chartLineLegendFallback => 'Line';

  @override
  String funnelChartDescription(int count) {
    return 'Funnel chart with $count segments';
  }

  @override
  String donutChartDescription(int count) {
    return 'Doughnut chart with $count slices';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Gauge chart with $count segments. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Current value: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Current value is $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Min value: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Max value: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Unknown';

  @override
  String ganttChartDescription(int count) {
    return 'Gantt chart with $count data points. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Heat map chart with $count data points. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Polar chart with $count data series.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Sparkline with label $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Sankey chart with $nodes nodes and $links links';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'From $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'node $name with weight $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'link from $source to $target with weight $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Vertical bar chart with $count bars. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Vertical bar chart with $count bars and 1 line. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Vertical bar chart with $count grouped bar series. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Vertical bar chart with $count grouped bar series and $lines line series. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Vertical bar chart with $count stacked bars. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Vertical bar chart with $count stacked bars and $lines lines. ';
  }

  @override
  String get presenceAvailable => 'Available';

  @override
  String get presenceAway => 'Away';

  @override
  String get presenceBusy => 'Busy';

  @override
  String get presenceDoNotDisturb => 'Do not disturb';

  @override
  String get presenceBlocked => 'Blocked';

  @override
  String get presenceOffline => 'Offline';

  @override
  String get presenceOutOfOffice => 'Out of office';

  @override
  String get presenceUnknown => 'Unknown';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status out of office';
  }
}

/// The translations for English, as used in Ireland (`en_IE`).
class FluentLocalizationsEnIe extends FluentLocalizationsEn {
  FluentLocalizationsEnIe() : super('en_IE');

  @override
  String get close => 'Close';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get clear => 'Clear';

  @override
  String get open => 'Open';

  @override
  String get remove => 'Remove';

  @override
  String get more => 'More';

  @override
  String get overflowMore => 'more';

  @override
  String get selectAllRows => 'Select all rows';

  @override
  String get selectRow => 'Select row';

  @override
  String get sort => 'Sort';

  @override
  String get sortedAscending => 'Sorted ascending';

  @override
  String get sortedDescending => 'Sorted descending';

  @override
  String get previousSlide => 'Previous slide';

  @override
  String get nextSlide => 'Next slide';

  @override
  String get startSlideShow => 'Start automatic slide show';

  @override
  String get pauseSlideShow => 'Pause automatic slide show';

  @override
  String slideOf(int index, int count) {
    return 'Slide $index of $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Step $index of $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value of $max';
  }

  @override
  String get openCalendar => 'Open calendar';

  @override
  String get invalidDateFormat => 'Invalid date format.';

  @override
  String get dateOutOfRange => 'Date is out of the allowed range.';

  @override
  String get fieldRequired => 'This field is required.';

  @override
  String get goToToday => 'Go to today';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get previousYear => 'Previous year';

  @override
  String get nextYear => 'Next year';

  @override
  String get previousYearRange => 'Previous year range';

  @override
  String get nextYearRange => 'Next year range';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, change year';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, change month';
  }

  @override
  String selectedDate(String date) {
    return 'Selected date $date';
  }

  @override
  String todaysDate(String date) {
    return 'Today\'s date $date';
  }

  @override
  String weekNumber(String number) {
    return 'Week $number';
  }

  @override
  String get chartNoData => 'Graph has no data to display';

  @override
  String get chartNoDataAvailable => 'No data available';

  @override
  String get chartFallbackTitle => 'Chart. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'The $axis axis displays $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'secondary Y';

  @override
  String get chartAxisCategories => 'categories';

  @override
  String get chartAxisTime => 'time';

  @override
  String get chartAxisValues => 'values';

  @override
  String get chartLineLegendFallback => 'Line';

  @override
  String funnelChartDescription(int count) {
    return 'Funnel chart with $count segments';
  }

  @override
  String donutChartDescription(int count) {
    return 'Doughnut chart with $count slices';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Gauge chart with $count segments. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Current value: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Current value is $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Min value: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Max value: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Unknown';

  @override
  String ganttChartDescription(int count) {
    return 'Gantt chart with $count data points. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Heat map chart with $count data points. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Polar chart with $count data series.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Sparkline with label $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Sankey chart with $nodes nodes and $links links';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'From $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'node $name with weight $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'link from $source to $target with weight $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Vertical bar chart with $count bars. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Vertical bar chart with $count bars and 1 line. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Vertical bar chart with $count grouped bar series. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Vertical bar chart with $count grouped bar series and $lines line series. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Vertical bar chart with $count stacked bars. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Vertical bar chart with $count stacked bars and $lines lines. ';
  }

  @override
  String get presenceAvailable => 'Available';

  @override
  String get presenceAway => 'Away';

  @override
  String get presenceBusy => 'Busy';

  @override
  String get presenceDoNotDisturb => 'Do not disturb';

  @override
  String get presenceBlocked => 'Blocked';

  @override
  String get presenceOffline => 'Offline';

  @override
  String get presenceOutOfOffice => 'Out of office';

  @override
  String get presenceUnknown => 'Unknown';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status out of office';
  }
}

/// The translations for English, as used in India (`en_IN`).
class FluentLocalizationsEnIn extends FluentLocalizationsEn {
  FluentLocalizationsEnIn() : super('en_IN');

  @override
  String get close => 'Close';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get clear => 'Clear';

  @override
  String get open => 'Open';

  @override
  String get remove => 'Remove';

  @override
  String get more => 'More';

  @override
  String get overflowMore => 'more';

  @override
  String get selectAllRows => 'Select all rows';

  @override
  String get selectRow => 'Select row';

  @override
  String get sort => 'Sort';

  @override
  String get sortedAscending => 'Sorted ascending';

  @override
  String get sortedDescending => 'Sorted descending';

  @override
  String get previousSlide => 'Previous slide';

  @override
  String get nextSlide => 'Next slide';

  @override
  String get startSlideShow => 'Start automatic slide show';

  @override
  String get pauseSlideShow => 'Pause automatic slide show';

  @override
  String slideOf(int index, int count) {
    return 'Slide $index of $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Step $index of $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value of $max';
  }

  @override
  String get openCalendar => 'Open calendar';

  @override
  String get invalidDateFormat => 'Invalid date format.';

  @override
  String get dateOutOfRange => 'Date is out of the allowed range.';

  @override
  String get fieldRequired => 'This field is required.';

  @override
  String get goToToday => 'Go to today';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get previousYear => 'Previous year';

  @override
  String get nextYear => 'Next year';

  @override
  String get previousYearRange => 'Previous year range';

  @override
  String get nextYearRange => 'Next year range';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, change year';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, change month';
  }

  @override
  String selectedDate(String date) {
    return 'Selected date $date';
  }

  @override
  String todaysDate(String date) {
    return 'Today\'s date $date';
  }

  @override
  String weekNumber(String number) {
    return 'Week $number';
  }

  @override
  String get chartNoData => 'Graph has no data to display';

  @override
  String get chartNoDataAvailable => 'No data available';

  @override
  String get chartFallbackTitle => 'Chart. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'The $axis axis displays $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'secondary Y';

  @override
  String get chartAxisCategories => 'categories';

  @override
  String get chartAxisTime => 'time';

  @override
  String get chartAxisValues => 'values';

  @override
  String get chartLineLegendFallback => 'Line';

  @override
  String funnelChartDescription(int count) {
    return 'Funnel chart with $count segments';
  }

  @override
  String donutChartDescription(int count) {
    return 'Doughnut chart with $count slices';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Gauge chart with $count segments. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Current value: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Current value is $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Min value: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Max value: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Unknown';

  @override
  String ganttChartDescription(int count) {
    return 'Gantt chart with $count data points. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Heat map chart with $count data points. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Polar chart with $count data series.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Sparkline with label $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Sankey chart with $nodes nodes and $links links';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'From $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'node $name with weight $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'link from $source to $target with weight $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Vertical bar chart with $count bars. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Vertical bar chart with $count bars and 1 line. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Vertical bar chart with $count grouped bar series. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Vertical bar chart with $count grouped bar series and $lines line series. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Vertical bar chart with $count stacked bars. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Vertical bar chart with $count stacked bars and $lines lines. ';
  }

  @override
  String get presenceAvailable => 'Available';

  @override
  String get presenceAway => 'Away';

  @override
  String get presenceBusy => 'Busy';

  @override
  String get presenceDoNotDisturb => 'Do not disturb';

  @override
  String get presenceBlocked => 'Blocked';

  @override
  String get presenceOffline => 'Offline';

  @override
  String get presenceOutOfOffice => 'Out of office';

  @override
  String get presenceUnknown => 'Unknown';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status out of office';
  }
}

/// The translations for English, as used in New Zealand (`en_NZ`).
class FluentLocalizationsEnNz extends FluentLocalizationsEn {
  FluentLocalizationsEnNz() : super('en_NZ');

  @override
  String get close => 'Close';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get clear => 'Clear';

  @override
  String get open => 'Open';

  @override
  String get remove => 'Remove';

  @override
  String get more => 'More';

  @override
  String get overflowMore => 'more';

  @override
  String get selectAllRows => 'Select all rows';

  @override
  String get selectRow => 'Select row';

  @override
  String get sort => 'Sort';

  @override
  String get sortedAscending => 'Sorted ascending';

  @override
  String get sortedDescending => 'Sorted descending';

  @override
  String get previousSlide => 'Previous slide';

  @override
  String get nextSlide => 'Next slide';

  @override
  String get startSlideShow => 'Start automatic slide show';

  @override
  String get pauseSlideShow => 'Pause automatic slide show';

  @override
  String slideOf(int index, int count) {
    return 'Slide $index of $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Step $index of $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value of $max';
  }

  @override
  String get openCalendar => 'Open calendar';

  @override
  String get invalidDateFormat => 'Invalid date format.';

  @override
  String get dateOutOfRange => 'Date is out of the allowed range.';

  @override
  String get fieldRequired => 'This field is required.';

  @override
  String get goToToday => 'Go to today';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get previousYear => 'Previous year';

  @override
  String get nextYear => 'Next year';

  @override
  String get previousYearRange => 'Previous year range';

  @override
  String get nextYearRange => 'Next year range';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, change year';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, change month';
  }

  @override
  String selectedDate(String date) {
    return 'Selected date $date';
  }

  @override
  String todaysDate(String date) {
    return 'Today\'s date $date';
  }

  @override
  String weekNumber(String number) {
    return 'Week $number';
  }

  @override
  String get chartNoData => 'Graph has no data to display';

  @override
  String get chartNoDataAvailable => 'No data available';

  @override
  String get chartFallbackTitle => 'Chart. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'The $axis axis displays $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'secondary Y';

  @override
  String get chartAxisCategories => 'categories';

  @override
  String get chartAxisTime => 'time';

  @override
  String get chartAxisValues => 'values';

  @override
  String get chartLineLegendFallback => 'Line';

  @override
  String funnelChartDescription(int count) {
    return 'Funnel chart with $count segments';
  }

  @override
  String donutChartDescription(int count) {
    return 'Doughnut chart with $count slices';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Gauge chart with $count segments. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Current value: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Current value is $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Min value: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Max value: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Unknown';

  @override
  String ganttChartDescription(int count) {
    return 'Gantt chart with $count data points. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Heat map chart with $count data points. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Polar chart with $count data series.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Sparkline with label $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Sankey chart with $nodes nodes and $links links';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'From $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'node $name with weight $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'link from $source to $target with weight $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Vertical bar chart with $count bars. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Vertical bar chart with $count bars and 1 line. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Vertical bar chart with $count grouped bar series. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Vertical bar chart with $count grouped bar series and $lines line series. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Vertical bar chart with $count stacked bars. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Vertical bar chart with $count stacked bars and $lines lines. ';
  }

  @override
  String get presenceAvailable => 'Available';

  @override
  String get presenceAway => 'Away';

  @override
  String get presenceBusy => 'Busy';

  @override
  String get presenceDoNotDisturb => 'Do not disturb';

  @override
  String get presenceBlocked => 'Blocked';

  @override
  String get presenceOffline => 'Offline';

  @override
  String get presenceOutOfOffice => 'Out of office';

  @override
  String get presenceUnknown => 'Unknown';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status out of office';
  }
}

/// The translations for English, as used in Singapore (`en_SG`).
class FluentLocalizationsEnSg extends FluentLocalizationsEn {
  FluentLocalizationsEnSg() : super('en_SG');

  @override
  String get close => 'Close';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get clear => 'Clear';

  @override
  String get open => 'Open';

  @override
  String get remove => 'Remove';

  @override
  String get more => 'More';

  @override
  String get overflowMore => 'more';

  @override
  String get selectAllRows => 'Select all rows';

  @override
  String get selectRow => 'Select row';

  @override
  String get sort => 'Sort';

  @override
  String get sortedAscending => 'Sorted ascending';

  @override
  String get sortedDescending => 'Sorted descending';

  @override
  String get previousSlide => 'Previous slide';

  @override
  String get nextSlide => 'Next slide';

  @override
  String get startSlideShow => 'Start automatic slide show';

  @override
  String get pauseSlideShow => 'Pause automatic slide show';

  @override
  String slideOf(int index, int count) {
    return 'Slide $index of $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Step $index of $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value of $max';
  }

  @override
  String get openCalendar => 'Open calendar';

  @override
  String get invalidDateFormat => 'Invalid date format.';

  @override
  String get dateOutOfRange => 'Date is out of the allowed range.';

  @override
  String get fieldRequired => 'This field is required.';

  @override
  String get goToToday => 'Go to today';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get previousYear => 'Previous year';

  @override
  String get nextYear => 'Next year';

  @override
  String get previousYearRange => 'Previous year range';

  @override
  String get nextYearRange => 'Next year range';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, change year';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, change month';
  }

  @override
  String selectedDate(String date) {
    return 'Selected date $date';
  }

  @override
  String todaysDate(String date) {
    return 'Today\'s date $date';
  }

  @override
  String weekNumber(String number) {
    return 'Week $number';
  }

  @override
  String get chartNoData => 'Graph has no data to display';

  @override
  String get chartNoDataAvailable => 'No data available';

  @override
  String get chartFallbackTitle => 'Chart. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'The $axis axis displays $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'secondary Y';

  @override
  String get chartAxisCategories => 'categories';

  @override
  String get chartAxisTime => 'time';

  @override
  String get chartAxisValues => 'values';

  @override
  String get chartLineLegendFallback => 'Line';

  @override
  String funnelChartDescription(int count) {
    return 'Funnel chart with $count segments';
  }

  @override
  String donutChartDescription(int count) {
    return 'Doughnut chart with $count slices';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Gauge chart with $count segments. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Current value: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Current value is $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Min value: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Max value: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Unknown';

  @override
  String ganttChartDescription(int count) {
    return 'Gantt chart with $count data points. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Heat map chart with $count data points. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Polar chart with $count data series.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Sparkline with label $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Sankey chart with $nodes nodes and $links links';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'From $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'node $name with weight $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'link from $source to $target with weight $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Vertical bar chart with $count bars. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Vertical bar chart with $count bars and 1 line. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Vertical bar chart with $count grouped bar series. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Vertical bar chart with $count grouped bar series and $lines line series. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Vertical bar chart with $count stacked bars. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Vertical bar chart with $count stacked bars and $lines lines. ';
  }

  @override
  String get presenceAvailable => 'Available';

  @override
  String get presenceAway => 'Away';

  @override
  String get presenceBusy => 'Busy';

  @override
  String get presenceDoNotDisturb => 'Do not disturb';

  @override
  String get presenceBlocked => 'Blocked';

  @override
  String get presenceOffline => 'Offline';

  @override
  String get presenceOutOfOffice => 'Out of office';

  @override
  String get presenceUnknown => 'Unknown';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status out of office';
  }
}

/// The translations for English, as used in the United States (`en_US`).
class FluentLocalizationsEnUs extends FluentLocalizationsEn {
  FluentLocalizationsEnUs() : super('en_US');

  @override
  String get close => 'Close';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get clear => 'Clear';

  @override
  String get open => 'Open';

  @override
  String get remove => 'Remove';

  @override
  String get more => 'More';

  @override
  String get overflowMore => 'more';

  @override
  String get selectAllRows => 'Select all rows';

  @override
  String get selectRow => 'Select row';

  @override
  String get sort => 'Sort';

  @override
  String get sortedAscending => 'Sorted ascending';

  @override
  String get sortedDescending => 'Sorted descending';

  @override
  String get previousSlide => 'Previous slide';

  @override
  String get nextSlide => 'Next slide';

  @override
  String get startSlideShow => 'Start automatic slide show';

  @override
  String get pauseSlideShow => 'Pause automatic slide show';

  @override
  String slideOf(int index, int count) {
    return 'Slide $index of $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Step $index of $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value of $max';
  }

  @override
  String get openCalendar => 'Open calendar';

  @override
  String get invalidDateFormat => 'Invalid date format.';

  @override
  String get dateOutOfRange => 'Date is out of the allowed range.';

  @override
  String get fieldRequired => 'This field is required.';

  @override
  String get goToToday => 'Go to today';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get previousYear => 'Previous year';

  @override
  String get nextYear => 'Next year';

  @override
  String get previousYearRange => 'Previous year range';

  @override
  String get nextYearRange => 'Next year range';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, change year';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, change month';
  }

  @override
  String selectedDate(String date) {
    return 'Selected date $date';
  }

  @override
  String todaysDate(String date) {
    return 'Today\'s date $date';
  }

  @override
  String weekNumber(String number) {
    return 'Week $number';
  }

  @override
  String get chartNoData => 'Graph has no data to display';

  @override
  String get chartNoDataAvailable => 'No data available';

  @override
  String get chartFallbackTitle => 'Chart. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'The $axis axis displays $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'secondary Y';

  @override
  String get chartAxisCategories => 'categories';

  @override
  String get chartAxisTime => 'time';

  @override
  String get chartAxisValues => 'values';

  @override
  String get chartLineLegendFallback => 'Line';

  @override
  String funnelChartDescription(int count) {
    return 'Funnel chart with $count segments';
  }

  @override
  String donutChartDescription(int count) {
    return 'Donut chart with $count slices';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Gauge chart with $count segments. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Current value: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Current value is $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Min value: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Max value: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Unknown';

  @override
  String ganttChartDescription(int count) {
    return 'Gantt chart with $count data points. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Heat map chart with $count data points. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Polar chart with $count data series.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Sparkline with label $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Sankey chart with $nodes nodes and $links links';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'From $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'node $name with weight $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'link from $source to $target with weight $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Vertical bar chart with $count bars. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Vertical bar chart with $count bars and 1 line. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Vertical bar chart with $count grouped bar series. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Vertical bar chart with $count grouped bar series and $lines line series. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Vertical bar chart with $count stacked bars. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Vertical bar chart with $count stacked bars and $lines lines. ';
  }

  @override
  String get presenceAvailable => 'Available';

  @override
  String get presenceAway => 'Away';

  @override
  String get presenceBusy => 'Busy';

  @override
  String get presenceDoNotDisturb => 'Do not disturb';

  @override
  String get presenceBlocked => 'Blocked';

  @override
  String get presenceOffline => 'Offline';

  @override
  String get presenceOutOfOffice => 'Out of office';

  @override
  String get presenceUnknown => 'Unknown';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status out of office';
  }
}

/// The translations for English, as used in South Africa (`en_ZA`).
class FluentLocalizationsEnZa extends FluentLocalizationsEn {
  FluentLocalizationsEnZa() : super('en_ZA');

  @override
  String get close => 'Close';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get clear => 'Clear';

  @override
  String get open => 'Open';

  @override
  String get remove => 'Remove';

  @override
  String get more => 'More';

  @override
  String get overflowMore => 'more';

  @override
  String get selectAllRows => 'Select all rows';

  @override
  String get selectRow => 'Select row';

  @override
  String get sort => 'Sort';

  @override
  String get sortedAscending => 'Sorted ascending';

  @override
  String get sortedDescending => 'Sorted descending';

  @override
  String get previousSlide => 'Previous slide';

  @override
  String get nextSlide => 'Next slide';

  @override
  String get startSlideShow => 'Start automatic slide show';

  @override
  String get pauseSlideShow => 'Pause automatic slide show';

  @override
  String slideOf(int index, int count) {
    return 'Slide $index of $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Step $index of $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value of $max';
  }

  @override
  String get openCalendar => 'Open calendar';

  @override
  String get invalidDateFormat => 'Invalid date format.';

  @override
  String get dateOutOfRange => 'Date is out of the allowed range.';

  @override
  String get fieldRequired => 'This field is required.';

  @override
  String get goToToday => 'Go to today';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get previousYear => 'Previous year';

  @override
  String get nextYear => 'Next year';

  @override
  String get previousYearRange => 'Previous year range';

  @override
  String get nextYearRange => 'Next year range';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, change year';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, change month';
  }

  @override
  String selectedDate(String date) {
    return 'Selected date $date';
  }

  @override
  String todaysDate(String date) {
    return 'Today\'s date $date';
  }

  @override
  String weekNumber(String number) {
    return 'Week $number';
  }

  @override
  String get chartNoData => 'Graph has no data to display';

  @override
  String get chartNoDataAvailable => 'No data available';

  @override
  String get chartFallbackTitle => 'Chart. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'The $axis axis displays $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'secondary Y';

  @override
  String get chartAxisCategories => 'categories';

  @override
  String get chartAxisTime => 'time';

  @override
  String get chartAxisValues => 'values';

  @override
  String get chartLineLegendFallback => 'Line';

  @override
  String funnelChartDescription(int count) {
    return 'Funnel chart with $count segments';
  }

  @override
  String donutChartDescription(int count) {
    return 'Doughnut chart with $count slices';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Gauge chart with $count segments. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Current value: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Current value is $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Min value: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Max value: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Unknown';

  @override
  String ganttChartDescription(int count) {
    return 'Gantt chart with $count data points. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Heat map chart with $count data points. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Polar chart with $count data series.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Sparkline with label $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Sankey chart with $nodes nodes and $links links';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'From $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'node $name with weight $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'link from $source to $target with weight $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Vertical bar chart with $count bars. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Vertical bar chart with $count bars and 1 line. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Vertical bar chart with $count grouped bar series. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Vertical bar chart with $count grouped bar series and $lines line series. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Vertical bar chart with $count stacked bars. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Vertical bar chart with $count stacked bars and $lines lines. ';
  }

  @override
  String get presenceAvailable => 'Available';

  @override
  String get presenceAway => 'Away';

  @override
  String get presenceBusy => 'Busy';

  @override
  String get presenceDoNotDisturb => 'Do not disturb';

  @override
  String get presenceBlocked => 'Blocked';

  @override
  String get presenceOffline => 'Offline';

  @override
  String get presenceOutOfOffice => 'Out of office';

  @override
  String get presenceUnknown => 'Unknown';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status out of office';
  }
}
