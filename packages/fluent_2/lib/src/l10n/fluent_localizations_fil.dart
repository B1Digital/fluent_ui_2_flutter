// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fluent_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Filipino Pilipino (`fil`).
class FluentLocalizationsFil extends FluentLocalizations {
  FluentLocalizationsFil([String locale = 'fil']) : super(locale);

  @override
  String get close => 'Isara';

  @override
  String get dismiss => 'I-dismiss';

  @override
  String get clear => 'I-clear';

  @override
  String get open => 'Buksan';

  @override
  String get remove => 'Alisin';

  @override
  String get more => 'Higit pa';

  @override
  String get overflowMore => 'pa';

  @override
  String get selectAllRows => 'Piliin ang lahat ng row';

  @override
  String get selectRow => 'Piliin ang row';

  @override
  String get sort => 'Pagbukud-bukurin';

  @override
  String get sortedAscending => 'Nakaayos nang pataas';

  @override
  String get sortedDescending => 'Nakaayos nang pababa';

  @override
  String get previousSlide => 'Nakaraang slide';

  @override
  String get nextSlide => 'Susunod na slide';

  @override
  String get startSlideShow => 'Simulan ang awtomatikong slide show';

  @override
  String get pauseSlideShow => 'I-pause ang awtomatikong slide show';

  @override
  String slideOf(int index, int count) {
    return 'Slide $index ng $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Hakbang $index ng $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value ng $max';
  }

  @override
  String get openCalendar => 'Buksan ang kalendaryo';

  @override
  String get invalidDateFormat => 'Di-wastong format ng petsa.';

  @override
  String get dateOutOfRange => 'Wala sa pinapayagang saklaw ang petsa.';

  @override
  String get fieldRequired => 'Kinakailangan ang field na ito.';

  @override
  String get goToToday => 'Pumunta sa ngayong araw';

  @override
  String get previousMonth => 'Nakaraang buwan';

  @override
  String get nextMonth => 'Susunod na buwan';

  @override
  String get previousYear => 'Nakaraang taon';

  @override
  String get nextYear => 'Susunod na taon';

  @override
  String get previousYearRange => 'Nakaraang saklaw ng taon';

  @override
  String get nextYearRange => 'Susunod na saklaw ng taon';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, baguhin ang taon';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, baguhin ang buwan';
  }

  @override
  String selectedDate(String date) {
    return 'Napiling petsa $date';
  }

  @override
  String todaysDate(String date) {
    return 'Petsa ngayong araw $date';
  }

  @override
  String weekNumber(String number) {
    return 'Linggo $number';
  }

  @override
  String get chartNoData => 'Walang data na maipapakita ang graph';

  @override
  String get chartNoDataAvailable => 'Walang available na data';

  @override
  String get chartFallbackTitle => 'Chart. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'Ipinapakita ng $axis axis ang $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'pangalawang Y';

  @override
  String get chartAxisCategories => 'mga kategorya';

  @override
  String get chartAxisTime => 'oras';

  @override
  String get chartAxisValues => 'mga halaga';

  @override
  String get chartLineLegendFallback => 'Linya';

  @override
  String funnelChartDescription(int count) {
    return 'Funnel chart na may $count segment';
  }

  @override
  String donutChartDescription(int count) {
    return 'Donut chart na may $count hiwa';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Gauge chart na may $count segment. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Kasalukuyang halaga: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Ang kasalukuyang halaga ay $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Pinakamababang halaga: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Pinakamataas na halaga: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Hindi alam';

  @override
  String ganttChartDescription(int count) {
    return 'Gantt chart na may $count data point. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Heat map chart na may $count data point. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Polar chart na may $count serye ng data.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Sparkline na may label na $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Sankey chart na may $nodes node at $links link';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Mula sa $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'node $name na may timbang na $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'link mula sa $source papuntang $target na may timbang na $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Vertical bar chart na may $count bar. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Vertical bar chart na may $count bar at 1 linya. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Vertical bar chart na may $count naka-grupong serye ng bar. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Vertical bar chart na may $count naka-grupong serye ng bar at $lines serye ng linya. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Vertical bar chart na may $count naka-stack na bar. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Vertical bar chart na may $count naka-stack na bar at $lines linya. ';
  }

  @override
  String get presenceAvailable => 'Available';

  @override
  String get presenceAway => 'Wala';

  @override
  String get presenceBusy => 'Abala';

  @override
  String get presenceDoNotDisturb => 'Huwag istorbohin';

  @override
  String get presenceBlocked => 'Naka-block';

  @override
  String get presenceOffline => 'Offline';

  @override
  String get presenceOutOfOffice => 'Wala sa opisina';

  @override
  String get presenceUnknown => 'Hindi alam';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, wala sa opisina';
  }
}

/// The translations for Filipino Pilipino, as used in Philippines (`fil_PH`).
class FluentLocalizationsFilPh extends FluentLocalizationsFil {
  FluentLocalizationsFilPh() : super('fil_PH');

  @override
  String get close => 'Isara';

  @override
  String get dismiss => 'I-dismiss';

  @override
  String get clear => 'I-clear';

  @override
  String get open => 'Buksan';

  @override
  String get remove => 'Alisin';

  @override
  String get more => 'Higit pa';

  @override
  String get overflowMore => 'pa';

  @override
  String get selectAllRows => 'Piliin ang lahat ng row';

  @override
  String get selectRow => 'Piliin ang row';

  @override
  String get sort => 'Pagbukud-bukurin';

  @override
  String get sortedAscending => 'Nakaayos nang pataas';

  @override
  String get sortedDescending => 'Nakaayos nang pababa';

  @override
  String get previousSlide => 'Nakaraang slide';

  @override
  String get nextSlide => 'Susunod na slide';

  @override
  String get startSlideShow => 'Simulan ang awtomatikong slide show';

  @override
  String get pauseSlideShow => 'I-pause ang awtomatikong slide show';

  @override
  String slideOf(int index, int count) {
    return 'Slide $index ng $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Hakbang $index ng $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value ng $max';
  }

  @override
  String get openCalendar => 'Buksan ang kalendaryo';

  @override
  String get invalidDateFormat => 'Di-wastong format ng petsa.';

  @override
  String get dateOutOfRange => 'Wala sa pinapayagang saklaw ang petsa.';

  @override
  String get fieldRequired => 'Kinakailangan ang field na ito.';

  @override
  String get goToToday => 'Pumunta sa ngayong araw';

  @override
  String get previousMonth => 'Nakaraang buwan';

  @override
  String get nextMonth => 'Susunod na buwan';

  @override
  String get previousYear => 'Nakaraang taon';

  @override
  String get nextYear => 'Susunod na taon';

  @override
  String get previousYearRange => 'Nakaraang saklaw ng taon';

  @override
  String get nextYearRange => 'Susunod na saklaw ng taon';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, baguhin ang taon';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, baguhin ang buwan';
  }

  @override
  String selectedDate(String date) {
    return 'Napiling petsa $date';
  }

  @override
  String todaysDate(String date) {
    return 'Petsa ngayong araw $date';
  }

  @override
  String weekNumber(String number) {
    return 'Linggo $number';
  }

  @override
  String get chartNoData => 'Walang data na maipapakita ang graph';

  @override
  String get chartNoDataAvailable => 'Walang available na data';

  @override
  String get chartFallbackTitle => 'Chart. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'Ipinapakita ng $axis axis ang $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'pangalawang Y';

  @override
  String get chartAxisCategories => 'mga kategorya';

  @override
  String get chartAxisTime => 'oras';

  @override
  String get chartAxisValues => 'mga halaga';

  @override
  String get chartLineLegendFallback => 'Linya';

  @override
  String funnelChartDescription(int count) {
    return 'Funnel chart na may $count segment';
  }

  @override
  String donutChartDescription(int count) {
    return 'Donut chart na may $count hiwa';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Gauge chart na may $count segment. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Kasalukuyang halaga: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'Ang kasalukuyang halaga ay $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Pinakamababang halaga: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Pinakamataas na halaga: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Hindi alam';

  @override
  String ganttChartDescription(int count) {
    return 'Gantt chart na may $count data point. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Heat map chart na may $count data point. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Polar chart na may $count serye ng data.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Sparkline na may label na $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Sankey chart na may $nodes node at $links link';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Mula sa $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'node $name na may timbang na $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'link mula sa $source papuntang $target na may timbang na $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Vertical bar chart na may $count bar. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Vertical bar chart na may $count bar at 1 linya. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Vertical bar chart na may $count naka-grupong serye ng bar. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Vertical bar chart na may $count naka-grupong serye ng bar at $lines serye ng linya. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Vertical bar chart na may $count naka-stack na bar. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Vertical bar chart na may $count naka-stack na bar at $lines linya. ';
  }

  @override
  String get presenceAvailable => 'Available';

  @override
  String get presenceAway => 'Wala';

  @override
  String get presenceBusy => 'Abala';

  @override
  String get presenceDoNotDisturb => 'Huwag istorbohin';

  @override
  String get presenceBlocked => 'Naka-block';

  @override
  String get presenceOffline => 'Offline';

  @override
  String get presenceOutOfOffice => 'Wala sa opisina';

  @override
  String get presenceUnknown => 'Hindi alam';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, wala sa opisina';
  }
}
