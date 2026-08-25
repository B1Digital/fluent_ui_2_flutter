// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fluent_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class FluentLocalizationsZh extends FluentLocalizations {
  FluentLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get close => '关闭';

  @override
  String get dismiss => '消除';

  @override
  String get clear => '清除';

  @override
  String get open => '打开';

  @override
  String get remove => '移除';

  @override
  String get more => '更多';

  @override
  String get overflowMore => '更多';

  @override
  String get selectAllRows => '选择所有行';

  @override
  String get selectRow => '选择行';

  @override
  String get sort => '排序';

  @override
  String get sortedAscending => '已按升序排序';

  @override
  String get sortedDescending => '已按降序排序';

  @override
  String get previousSlide => '上一张幻灯片';

  @override
  String get nextSlide => '下一张幻灯片';

  @override
  String get startSlideShow => '开始自动放映幻灯片';

  @override
  String get pauseSlideShow => '暂停自动放映幻灯片';

  @override
  String slideOf(int index, int count) {
    return '第 $index 张幻灯片，共 $count 张';
  }

  @override
  String stepOf(int index, int count) {
    return '第 $index 步，共 $count 步';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$max 中的 $value';
  }

  @override
  String get openCalendar => '打开日历';

  @override
  String get invalidDateFormat => '日期格式无效。';

  @override
  String get dateOutOfRange => '日期超出允许的范围。';

  @override
  String get fieldRequired => '此字段为必填项。';

  @override
  String get goToToday => '转到今天';

  @override
  String get previousMonth => '上个月';

  @override
  String get nextMonth => '下个月';

  @override
  String get previousYear => '上一年';

  @override
  String get nextYear => '下一年';

  @override
  String get previousYearRange => '上一个年份范围';

  @override
  String get nextYearRange => '下一个年份范围';

  @override
  String monthPickerHeader(String caption) {
    return '$caption，更改年份';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption，更改月份';
  }

  @override
  String selectedDate(String date) {
    return '所选日期 $date';
  }

  @override
  String todaysDate(String date) {
    return '今天的日期 $date';
  }

  @override
  String weekNumber(String number) {
    return '第 $number 周';
  }

  @override
  String get chartNoData => '图表没有可显示的数据';

  @override
  String get chartNoDataAvailable => '无可用数据';

  @override
  String get chartFallbackTitle => '图表。 ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return '$axis 轴显示$subject。 ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => '次要 Y';

  @override
  String get chartAxisCategories => '类别';

  @override
  String get chartAxisTime => '时间';

  @override
  String get chartAxisValues => '值';

  @override
  String get chartLineLegendFallback => '折线';

  @override
  String funnelChartDescription(int count) {
    return '包含 $count 个分段的漏斗图';
  }

  @override
  String donutChartDescription(int count) {
    return '包含 $count 个扇区的环形图';
  }

  @override
  String gaugeChartDescription(int count) {
    return '包含 $count 个分段的仪表图。 ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return '当前值：$value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return '当前值为 $value';
  }

  @override
  String gaugeMinValue(String value) {
    return '最小值：$value';
  }

  @override
  String gaugeMaxValue(String value) {
    return '最大值：$value';
  }

  @override
  String get gaugeUnknownSegment => '未知';

  @override
  String ganttChartDescription(int count) {
    return '包含 $count 个数据点的甘特图。 ';
  }

  @override
  String heatMapChartDescription(int count) {
    return '包含 $count 个数据点的热图。 ';
  }

  @override
  String polarChartDescription(int count) {
    return '包含 $count 个数据系列的极坐标图。';
  }

  @override
  String sparklineDescription(String label) {
    return '标签为 $label 的迷你图';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return '包含 $nodes 个节点和 $links 个链接的桑基图';
  }

  @override
  String sankeyLinkFrom(String node) {
    return '来自 $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return '节点 $name，权重为 $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return '从 $source 到 $target 的链接，权重为 $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return '包含 $count 个柱形的柱形图。 ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return '包含 $count 个柱形和 1 条折线的柱形图。 ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return '包含 $count 个分组柱形系列的柱形图。 ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return '包含 $count 个分组柱形系列和 $lines 个折线系列的柱形图。 ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return '包含 $count 个堆积柱形的柱形图。 ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return '包含 $count 个堆积柱形和 $lines 条折线的柱形图。 ';
  }

  @override
  String get presenceAvailable => '有空';

  @override
  String get presenceAway => '离开';

  @override
  String get presenceBusy => '忙碌';

  @override
  String get presenceDoNotDisturb => '请勿打扰';

  @override
  String get presenceBlocked => '已阻止';

  @override
  String get presenceOffline => '脱机';

  @override
  String get presenceOutOfOffice => '外出';

  @override
  String get presenceUnknown => '未知';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status，外出';
  }
}

/// The translations for Chinese, as used in China (`zh_CN`).
class FluentLocalizationsZhCn extends FluentLocalizationsZh {
  FluentLocalizationsZhCn() : super('zh_CN');

  @override
  String get close => '关闭';

  @override
  String get dismiss => '消除';

  @override
  String get clear => '清除';

  @override
  String get open => '打开';

  @override
  String get remove => '移除';

  @override
  String get more => '更多';

  @override
  String get overflowMore => '更多';

  @override
  String get selectAllRows => '选择所有行';

  @override
  String get selectRow => '选择行';

  @override
  String get sort => '排序';

  @override
  String get sortedAscending => '已按升序排序';

  @override
  String get sortedDescending => '已按降序排序';

  @override
  String get previousSlide => '上一张幻灯片';

  @override
  String get nextSlide => '下一张幻灯片';

  @override
  String get startSlideShow => '开始自动放映幻灯片';

  @override
  String get pauseSlideShow => '暂停自动放映幻灯片';

  @override
  String slideOf(int index, int count) {
    return '第 $index 张幻灯片，共 $count 张';
  }

  @override
  String stepOf(int index, int count) {
    return '第 $index 步，共 $count 步';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$max 中的 $value';
  }

  @override
  String get openCalendar => '打开日历';

  @override
  String get invalidDateFormat => '日期格式无效。';

  @override
  String get dateOutOfRange => '日期超出允许的范围。';

  @override
  String get fieldRequired => '此字段为必填项。';

  @override
  String get goToToday => '转到今天';

  @override
  String get previousMonth => '上个月';

  @override
  String get nextMonth => '下个月';

  @override
  String get previousYear => '上一年';

  @override
  String get nextYear => '下一年';

  @override
  String get previousYearRange => '上一个年份范围';

  @override
  String get nextYearRange => '下一个年份范围';

  @override
  String monthPickerHeader(String caption) {
    return '$caption，更改年份';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption，更改月份';
  }

  @override
  String selectedDate(String date) {
    return '所选日期 $date';
  }

  @override
  String todaysDate(String date) {
    return '今天的日期 $date';
  }

  @override
  String weekNumber(String number) {
    return '第 $number 周';
  }

  @override
  String get chartNoData => '图表没有可显示的数据';

  @override
  String get chartNoDataAvailable => '无可用数据';

  @override
  String get chartFallbackTitle => '图表。 ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return '$axis 轴显示$subject。 ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => '次要 Y';

  @override
  String get chartAxisCategories => '类别';

  @override
  String get chartAxisTime => '时间';

  @override
  String get chartAxisValues => '值';

  @override
  String get chartLineLegendFallback => '折线';

  @override
  String funnelChartDescription(int count) {
    return '包含 $count 个分段的漏斗图';
  }

  @override
  String donutChartDescription(int count) {
    return '包含 $count 个扇区的环形图';
  }

  @override
  String gaugeChartDescription(int count) {
    return '包含 $count 个分段的仪表图。 ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return '当前值：$value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return '当前值为 $value';
  }

  @override
  String gaugeMinValue(String value) {
    return '最小值：$value';
  }

  @override
  String gaugeMaxValue(String value) {
    return '最大值：$value';
  }

  @override
  String get gaugeUnknownSegment => '未知';

  @override
  String ganttChartDescription(int count) {
    return '包含 $count 个数据点的甘特图。 ';
  }

  @override
  String heatMapChartDescription(int count) {
    return '包含 $count 个数据点的热图。 ';
  }

  @override
  String polarChartDescription(int count) {
    return '包含 $count 个数据系列的极坐标图。';
  }

  @override
  String sparklineDescription(String label) {
    return '标签为 $label 的迷你图';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return '包含 $nodes 个节点和 $links 个链接的桑基图';
  }

  @override
  String sankeyLinkFrom(String node) {
    return '来自 $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return '节点 $name，权重为 $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return '从 $source 到 $target 的链接，权重为 $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return '包含 $count 个柱形的柱形图。 ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return '包含 $count 个柱形和 1 条折线的柱形图。 ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return '包含 $count 个分组柱形系列的柱形图。 ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return '包含 $count 个分组柱形系列和 $lines 个折线系列的柱形图。 ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return '包含 $count 个堆积柱形的柱形图。 ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return '包含 $count 个堆积柱形和 $lines 条折线的柱形图。 ';
  }

  @override
  String get presenceAvailable => '有空';

  @override
  String get presenceAway => '离开';

  @override
  String get presenceBusy => '忙碌';

  @override
  String get presenceDoNotDisturb => '请勿打扰';

  @override
  String get presenceBlocked => '已阻止';

  @override
  String get presenceOffline => '脱机';

  @override
  String get presenceOutOfOffice => '外出';

  @override
  String get presenceUnknown => '未知';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status，外出';
  }
}

/// The translations for Chinese, as used in Hong Kong (`zh_HK`).
class FluentLocalizationsZhHk extends FluentLocalizationsZh {
  FluentLocalizationsZhHk() : super('zh_HK');

  @override
  String get close => '關閉';

  @override
  String get dismiss => '關閉';

  @override
  String get clear => '清除';

  @override
  String get open => '開啟';

  @override
  String get remove => '移除';

  @override
  String get more => '更多';

  @override
  String get overflowMore => '更多';

  @override
  String get selectAllRows => '選取所有列';

  @override
  String get selectRow => '選取列';

  @override
  String get sort => '排序';

  @override
  String get sortedAscending => '已遞增排序';

  @override
  String get sortedDescending => '已遞減排序';

  @override
  String get previousSlide => '上一張投影片';

  @override
  String get nextSlide => '下一張投影片';

  @override
  String get startSlideShow => '開始自動投影片放映';

  @override
  String get pauseSlideShow => '暫停自動投影片放映';

  @override
  String slideOf(int index, int count) {
    return '第 $index 張投影片，共 $count 張';
  }

  @override
  String stepOf(int index, int count) {
    return '第 $index 個步驟，共 $count 個';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value，滿分 $max';
  }

  @override
  String get openCalendar => '開啟行事曆';

  @override
  String get invalidDateFormat => '日期格式無效。';

  @override
  String get dateOutOfRange => '日期超出允許的範圍。';

  @override
  String get fieldRequired => '此欄位為必填。';

  @override
  String get goToToday => '移至今天';

  @override
  String get previousMonth => '上個月';

  @override
  String get nextMonth => '下個月';

  @override
  String get previousYear => '上一年';

  @override
  String get nextYear => '下一年';

  @override
  String get previousYearRange => '上一個年份範圍';

  @override
  String get nextYearRange => '下一個年份範圍';

  @override
  String monthPickerHeader(String caption) {
    return '$caption，變更年份';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption，變更月份';
  }

  @override
  String selectedDate(String date) {
    return '選取的日期 $date';
  }

  @override
  String todaysDate(String date) {
    return '今天的日期 $date';
  }

  @override
  String weekNumber(String number) {
    return '第 $number 週';
  }

  @override
  String get chartNoData => '圖表沒有可顯示的資料';

  @override
  String get chartNoDataAvailable => '沒有可用的資料';

  @override
  String get chartFallbackTitle => '圖表。 ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return '$axis 軸顯示$subject。 ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => '次要 Y';

  @override
  String get chartAxisCategories => '類別';

  @override
  String get chartAxisTime => '時間';

  @override
  String get chartAxisValues => '數值';

  @override
  String get chartLineLegendFallback => '折線';

  @override
  String funnelChartDescription(int count) {
    return '漏斗圖，有 $count 個區段';
  }

  @override
  String donutChartDescription(int count) {
    return '環圈圖，有 $count 個扇形';
  }

  @override
  String gaugeChartDescription(int count) {
    return '量測計圖表，有 $count 個區段。 ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return '目前值：$value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return '目前值為 $value';
  }

  @override
  String gaugeMinValue(String value) {
    return '最小值：$value';
  }

  @override
  String gaugeMaxValue(String value) {
    return '最大值：$value';
  }

  @override
  String get gaugeUnknownSegment => '未知';

  @override
  String ganttChartDescription(int count) {
    return '甘特圖，有 $count 個資料點。 ';
  }

  @override
  String heatMapChartDescription(int count) {
    return '熱度圖，有 $count 個資料點。 ';
  }

  @override
  String polarChartDescription(int count) {
    return '極座標圖，有 $count 個資料數列。';
  }

  @override
  String sparklineDescription(String label) {
    return '走勢圖，標籤為 $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return '桑基圖，有 $nodes 個節點和 $links 個連結';
  }

  @override
  String sankeyLinkFrom(String node) {
    return '來自 $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return '節點 $name，權重為 $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return '從 $source 到 $target 的連結，權重為 $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return '直條圖，有 $count 個直條。 ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return '直條圖，有 $count 個直條和 1 條折線。 ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return '直條圖，有 $count 個群組直條數列。 ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return '直條圖，有 $count 個群組直條數列和 $lines 個折線數列。 ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return '直條圖，有 $count 個堆疊直條。 ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return '直條圖，有 $count 個堆疊直條和 $lines 條折線。 ';
  }

  @override
  String get presenceAvailable => '有空';

  @override
  String get presenceAway => '離開';

  @override
  String get presenceBusy => '忙碌';

  @override
  String get presenceDoNotDisturb => '請勿打擾';

  @override
  String get presenceBlocked => '已封鎖';

  @override
  String get presenceOffline => '離線';

  @override
  String get presenceOutOfOffice => '外出';

  @override
  String get presenceUnknown => '未知';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status，外出';
  }
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class FluentLocalizationsZhHans extends FluentLocalizationsZh {
  FluentLocalizationsZhHans() : super('zh_Hans');

  @override
  String get close => '关闭';

  @override
  String get dismiss => '消除';

  @override
  String get clear => '清除';

  @override
  String get open => '打开';

  @override
  String get remove => '移除';

  @override
  String get more => '更多';

  @override
  String get overflowMore => '更多';

  @override
  String get selectAllRows => '选择所有行';

  @override
  String get selectRow => '选择行';

  @override
  String get sort => '排序';

  @override
  String get sortedAscending => '已按升序排序';

  @override
  String get sortedDescending => '已按降序排序';

  @override
  String get previousSlide => '上一张幻灯片';

  @override
  String get nextSlide => '下一张幻灯片';

  @override
  String get startSlideShow => '开始自动放映幻灯片';

  @override
  String get pauseSlideShow => '暂停自动放映幻灯片';

  @override
  String slideOf(int index, int count) {
    return '第 $index 张幻灯片，共 $count 张';
  }

  @override
  String stepOf(int index, int count) {
    return '第 $index 步，共 $count 步';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$max 中的 $value';
  }

  @override
  String get openCalendar => '打开日历';

  @override
  String get invalidDateFormat => '日期格式无效。';

  @override
  String get dateOutOfRange => '日期超出允许的范围。';

  @override
  String get fieldRequired => '此字段为必填项。';

  @override
  String get goToToday => '转到今天';

  @override
  String get previousMonth => '上个月';

  @override
  String get nextMonth => '下个月';

  @override
  String get previousYear => '上一年';

  @override
  String get nextYear => '下一年';

  @override
  String get previousYearRange => '上一个年份范围';

  @override
  String get nextYearRange => '下一个年份范围';

  @override
  String monthPickerHeader(String caption) {
    return '$caption，更改年份';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption，更改月份';
  }

  @override
  String selectedDate(String date) {
    return '所选日期 $date';
  }

  @override
  String todaysDate(String date) {
    return '今天的日期 $date';
  }

  @override
  String weekNumber(String number) {
    return '第 $number 周';
  }

  @override
  String get chartNoData => '图表没有可显示的数据';

  @override
  String get chartNoDataAvailable => '无可用数据';

  @override
  String get chartFallbackTitle => '图表。 ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return '$axis 轴显示$subject。 ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => '次要 Y';

  @override
  String get chartAxisCategories => '类别';

  @override
  String get chartAxisTime => '时间';

  @override
  String get chartAxisValues => '值';

  @override
  String get chartLineLegendFallback => '折线';

  @override
  String funnelChartDescription(int count) {
    return '包含 $count 个分段的漏斗图';
  }

  @override
  String donutChartDescription(int count) {
    return '包含 $count 个扇区的环形图';
  }

  @override
  String gaugeChartDescription(int count) {
    return '包含 $count 个分段的仪表图。 ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return '当前值：$value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return '当前值为 $value';
  }

  @override
  String gaugeMinValue(String value) {
    return '最小值：$value';
  }

  @override
  String gaugeMaxValue(String value) {
    return '最大值：$value';
  }

  @override
  String get gaugeUnknownSegment => '未知';

  @override
  String ganttChartDescription(int count) {
    return '包含 $count 个数据点的甘特图。 ';
  }

  @override
  String heatMapChartDescription(int count) {
    return '包含 $count 个数据点的热图。 ';
  }

  @override
  String polarChartDescription(int count) {
    return '包含 $count 个数据系列的极坐标图。';
  }

  @override
  String sparklineDescription(String label) {
    return '标签为 $label 的迷你图';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return '包含 $nodes 个节点和 $links 个链接的桑基图';
  }

  @override
  String sankeyLinkFrom(String node) {
    return '来自 $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return '节点 $name，权重为 $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return '从 $source 到 $target 的链接，权重为 $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return '包含 $count 个柱形的柱形图。 ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return '包含 $count 个柱形和 1 条折线的柱形图。 ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return '包含 $count 个分组柱形系列的柱形图。 ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return '包含 $count 个分组柱形系列和 $lines 个折线系列的柱形图。 ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return '包含 $count 个堆积柱形的柱形图。 ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return '包含 $count 个堆积柱形和 $lines 条折线的柱形图。 ';
  }

  @override
  String get presenceAvailable => '有空';

  @override
  String get presenceAway => '离开';

  @override
  String get presenceBusy => '忙碌';

  @override
  String get presenceDoNotDisturb => '请勿打扰';

  @override
  String get presenceBlocked => '已阻止';

  @override
  String get presenceOffline => '脱机';

  @override
  String get presenceOutOfOffice => '外出';

  @override
  String get presenceUnknown => '未知';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status，外出';
  }
}

/// The translations for Chinese, as used in China, using the Han script (`zh_Hans_CN`).
class FluentLocalizationsZhHansCn extends FluentLocalizationsZh {
  FluentLocalizationsZhHansCn() : super('zh_Hans_CN');

  @override
  String get close => '关闭';

  @override
  String get dismiss => '消除';

  @override
  String get clear => '清除';

  @override
  String get open => '打开';

  @override
  String get remove => '移除';

  @override
  String get more => '更多';

  @override
  String get overflowMore => '更多';

  @override
  String get selectAllRows => '选择所有行';

  @override
  String get selectRow => '选择行';

  @override
  String get sort => '排序';

  @override
  String get sortedAscending => '已按升序排序';

  @override
  String get sortedDescending => '已按降序排序';

  @override
  String get previousSlide => '上一张幻灯片';

  @override
  String get nextSlide => '下一张幻灯片';

  @override
  String get startSlideShow => '开始自动放映幻灯片';

  @override
  String get pauseSlideShow => '暂停自动放映幻灯片';

  @override
  String slideOf(int index, int count) {
    return '第 $index 张幻灯片，共 $count 张';
  }

  @override
  String stepOf(int index, int count) {
    return '第 $index 步，共 $count 步';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$max 中的 $value';
  }

  @override
  String get openCalendar => '打开日历';

  @override
  String get invalidDateFormat => '日期格式无效。';

  @override
  String get dateOutOfRange => '日期超出允许的范围。';

  @override
  String get fieldRequired => '此字段为必填项。';

  @override
  String get goToToday => '转到今天';

  @override
  String get previousMonth => '上个月';

  @override
  String get nextMonth => '下个月';

  @override
  String get previousYear => '上一年';

  @override
  String get nextYear => '下一年';

  @override
  String get previousYearRange => '上一个年份范围';

  @override
  String get nextYearRange => '下一个年份范围';

  @override
  String monthPickerHeader(String caption) {
    return '$caption，更改年份';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption，更改月份';
  }

  @override
  String selectedDate(String date) {
    return '所选日期 $date';
  }

  @override
  String todaysDate(String date) {
    return '今天的日期 $date';
  }

  @override
  String weekNumber(String number) {
    return '第 $number 周';
  }

  @override
  String get chartNoData => '图表没有可显示的数据';

  @override
  String get chartNoDataAvailable => '无可用数据';

  @override
  String get chartFallbackTitle => '图表。 ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return '$axis 轴显示$subject。 ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => '次要 Y';

  @override
  String get chartAxisCategories => '类别';

  @override
  String get chartAxisTime => '时间';

  @override
  String get chartAxisValues => '值';

  @override
  String get chartLineLegendFallback => '折线';

  @override
  String funnelChartDescription(int count) {
    return '包含 $count 个分段的漏斗图';
  }

  @override
  String donutChartDescription(int count) {
    return '包含 $count 个扇区的环形图';
  }

  @override
  String gaugeChartDescription(int count) {
    return '包含 $count 个分段的仪表图。 ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return '当前值：$value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return '当前值为 $value';
  }

  @override
  String gaugeMinValue(String value) {
    return '最小值：$value';
  }

  @override
  String gaugeMaxValue(String value) {
    return '最大值：$value';
  }

  @override
  String get gaugeUnknownSegment => '未知';

  @override
  String ganttChartDescription(int count) {
    return '包含 $count 个数据点的甘特图。 ';
  }

  @override
  String heatMapChartDescription(int count) {
    return '包含 $count 个数据点的热图。 ';
  }

  @override
  String polarChartDescription(int count) {
    return '包含 $count 个数据系列的极坐标图。';
  }

  @override
  String sparklineDescription(String label) {
    return '标签为 $label 的迷你图';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return '包含 $nodes 个节点和 $links 个链接的桑基图';
  }

  @override
  String sankeyLinkFrom(String node) {
    return '来自 $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return '节点 $name，权重为 $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return '从 $source 到 $target 的链接，权重为 $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return '包含 $count 个柱形的柱形图。 ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return '包含 $count 个柱形和 1 条折线的柱形图。 ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return '包含 $count 个分组柱形系列的柱形图。 ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return '包含 $count 个分组柱形系列和 $lines 个折线系列的柱形图。 ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return '包含 $count 个堆积柱形的柱形图。 ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return '包含 $count 个堆积柱形和 $lines 条折线的柱形图。 ';
  }

  @override
  String get presenceAvailable => '有空';

  @override
  String get presenceAway => '离开';

  @override
  String get presenceBusy => '忙碌';

  @override
  String get presenceDoNotDisturb => '请勿打扰';

  @override
  String get presenceBlocked => '已阻止';

  @override
  String get presenceOffline => '脱机';

  @override
  String get presenceOutOfOffice => '外出';

  @override
  String get presenceUnknown => '未知';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status，外出';
  }
}

/// The translations for Chinese, as used in Singapore, using the Han script (`zh_Hans_SG`).
class FluentLocalizationsZhHansSg extends FluentLocalizationsZh {
  FluentLocalizationsZhHansSg() : super('zh_Hans_SG');

  @override
  String get close => '关闭';

  @override
  String get dismiss => '消除';

  @override
  String get clear => '清除';

  @override
  String get open => '打开';

  @override
  String get remove => '移除';

  @override
  String get more => '更多';

  @override
  String get overflowMore => '更多';

  @override
  String get selectAllRows => '选择所有行';

  @override
  String get selectRow => '选择行';

  @override
  String get sort => '排序';

  @override
  String get sortedAscending => '已按升序排序';

  @override
  String get sortedDescending => '已按降序排序';

  @override
  String get previousSlide => '上一张幻灯片';

  @override
  String get nextSlide => '下一张幻灯片';

  @override
  String get startSlideShow => '开始自动放映幻灯片';

  @override
  String get pauseSlideShow => '暂停自动放映幻灯片';

  @override
  String slideOf(int index, int count) {
    return '第 $index 张幻灯片，共 $count 张';
  }

  @override
  String stepOf(int index, int count) {
    return '第 $index 步，共 $count 步';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$max 中的 $value';
  }

  @override
  String get openCalendar => '打开日历';

  @override
  String get invalidDateFormat => '日期格式无效。';

  @override
  String get dateOutOfRange => '日期超出允许的范围。';

  @override
  String get fieldRequired => '此字段为必填项。';

  @override
  String get goToToday => '转到今天';

  @override
  String get previousMonth => '上个月';

  @override
  String get nextMonth => '下个月';

  @override
  String get previousYear => '上一年';

  @override
  String get nextYear => '下一年';

  @override
  String get previousYearRange => '上一个年份范围';

  @override
  String get nextYearRange => '下一个年份范围';

  @override
  String monthPickerHeader(String caption) {
    return '$caption，更改年份';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption，更改月份';
  }

  @override
  String selectedDate(String date) {
    return '所选日期 $date';
  }

  @override
  String todaysDate(String date) {
    return '今天的日期 $date';
  }

  @override
  String weekNumber(String number) {
    return '第 $number 周';
  }

  @override
  String get chartNoData => '图表没有可显示的数据';

  @override
  String get chartNoDataAvailable => '无可用数据';

  @override
  String get chartFallbackTitle => '图表。 ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return '$axis 轴显示$subject。 ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => '次要 Y';

  @override
  String get chartAxisCategories => '类别';

  @override
  String get chartAxisTime => '时间';

  @override
  String get chartAxisValues => '值';

  @override
  String get chartLineLegendFallback => '折线';

  @override
  String funnelChartDescription(int count) {
    return '包含 $count 个分段的漏斗图';
  }

  @override
  String donutChartDescription(int count) {
    return '包含 $count 个扇区的环形图';
  }

  @override
  String gaugeChartDescription(int count) {
    return '包含 $count 个分段的仪表图。 ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return '当前值：$value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return '当前值为 $value';
  }

  @override
  String gaugeMinValue(String value) {
    return '最小值：$value';
  }

  @override
  String gaugeMaxValue(String value) {
    return '最大值：$value';
  }

  @override
  String get gaugeUnknownSegment => '未知';

  @override
  String ganttChartDescription(int count) {
    return '包含 $count 个数据点的甘特图。 ';
  }

  @override
  String heatMapChartDescription(int count) {
    return '包含 $count 个数据点的热图。 ';
  }

  @override
  String polarChartDescription(int count) {
    return '包含 $count 个数据系列的极坐标图。';
  }

  @override
  String sparklineDescription(String label) {
    return '标签为 $label 的迷你图';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return '包含 $nodes 个节点和 $links 个链接的桑基图';
  }

  @override
  String sankeyLinkFrom(String node) {
    return '来自 $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return '节点 $name，权重为 $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return '从 $source 到 $target 的链接，权重为 $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return '包含 $count 个柱形的柱形图。 ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return '包含 $count 个柱形和 1 条折线的柱形图。 ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return '包含 $count 个分组柱形系列的柱形图。 ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return '包含 $count 个分组柱形系列和 $lines 个折线系列的柱形图。 ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return '包含 $count 个堆积柱形的柱形图。 ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return '包含 $count 个堆积柱形和 $lines 条折线的柱形图。 ';
  }

  @override
  String get presenceAvailable => '有空';

  @override
  String get presenceAway => '离开';

  @override
  String get presenceBusy => '忙碌';

  @override
  String get presenceDoNotDisturb => '请勿打扰';

  @override
  String get presenceBlocked => '已阻止';

  @override
  String get presenceOffline => '脱机';

  @override
  String get presenceOutOfOffice => '外出';

  @override
  String get presenceUnknown => '未知';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status，外出';
  }
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class FluentLocalizationsZhHant extends FluentLocalizationsZh {
  FluentLocalizationsZhHant() : super('zh_Hant');

  @override
  String get close => '關閉';

  @override
  String get dismiss => '關閉';

  @override
  String get clear => '清除';

  @override
  String get open => '開啟';

  @override
  String get remove => '移除';

  @override
  String get more => '更多';

  @override
  String get overflowMore => '更多';

  @override
  String get selectAllRows => '選取所有列';

  @override
  String get selectRow => '選取列';

  @override
  String get sort => '排序';

  @override
  String get sortedAscending => '已遞增排序';

  @override
  String get sortedDescending => '已遞減排序';

  @override
  String get previousSlide => '上一張投影片';

  @override
  String get nextSlide => '下一張投影片';

  @override
  String get startSlideShow => '開始自動投影片放映';

  @override
  String get pauseSlideShow => '暫停自動投影片放映';

  @override
  String slideOf(int index, int count) {
    return '第 $index 張投影片，共 $count 張';
  }

  @override
  String stepOf(int index, int count) {
    return '第 $index 個步驟，共 $count 個';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value，滿分 $max';
  }

  @override
  String get openCalendar => '開啟行事曆';

  @override
  String get invalidDateFormat => '日期格式無效。';

  @override
  String get dateOutOfRange => '日期超出允許的範圍。';

  @override
  String get fieldRequired => '此欄位為必填。';

  @override
  String get goToToday => '移至今天';

  @override
  String get previousMonth => '上個月';

  @override
  String get nextMonth => '下個月';

  @override
  String get previousYear => '上一年';

  @override
  String get nextYear => '下一年';

  @override
  String get previousYearRange => '上一個年份範圍';

  @override
  String get nextYearRange => '下一個年份範圍';

  @override
  String monthPickerHeader(String caption) {
    return '$caption，變更年份';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption，變更月份';
  }

  @override
  String selectedDate(String date) {
    return '選取的日期 $date';
  }

  @override
  String todaysDate(String date) {
    return '今天的日期 $date';
  }

  @override
  String weekNumber(String number) {
    return '第 $number 週';
  }

  @override
  String get chartNoData => '圖表沒有可顯示的資料';

  @override
  String get chartNoDataAvailable => '沒有可用的資料';

  @override
  String get chartFallbackTitle => '圖表。 ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return '$axis 軸顯示$subject。 ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => '次要 Y';

  @override
  String get chartAxisCategories => '類別';

  @override
  String get chartAxisTime => '時間';

  @override
  String get chartAxisValues => '數值';

  @override
  String get chartLineLegendFallback => '折線';

  @override
  String funnelChartDescription(int count) {
    return '漏斗圖，有 $count 個區段';
  }

  @override
  String donutChartDescription(int count) {
    return '環圈圖，有 $count 個扇形';
  }

  @override
  String gaugeChartDescription(int count) {
    return '量測計圖表，有 $count 個區段。 ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return '目前值：$value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return '目前值為 $value';
  }

  @override
  String gaugeMinValue(String value) {
    return '最小值：$value';
  }

  @override
  String gaugeMaxValue(String value) {
    return '最大值：$value';
  }

  @override
  String get gaugeUnknownSegment => '未知';

  @override
  String ganttChartDescription(int count) {
    return '甘特圖，有 $count 個資料點。 ';
  }

  @override
  String heatMapChartDescription(int count) {
    return '熱度圖，有 $count 個資料點。 ';
  }

  @override
  String polarChartDescription(int count) {
    return '極座標圖，有 $count 個資料數列。';
  }

  @override
  String sparklineDescription(String label) {
    return '走勢圖，標籤為 $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return '桑基圖，有 $nodes 個節點和 $links 個連結';
  }

  @override
  String sankeyLinkFrom(String node) {
    return '來自 $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return '節點 $name，權重為 $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return '從 $source 到 $target 的連結，權重為 $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return '直條圖，有 $count 個直條。 ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return '直條圖，有 $count 個直條和 1 條折線。 ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return '直條圖，有 $count 個群組直條數列。 ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return '直條圖，有 $count 個群組直條數列和 $lines 個折線數列。 ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return '直條圖，有 $count 個堆疊直條。 ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return '直條圖，有 $count 個堆疊直條和 $lines 條折線。 ';
  }

  @override
  String get presenceAvailable => '有空';

  @override
  String get presenceAway => '離開';

  @override
  String get presenceBusy => '忙碌';

  @override
  String get presenceDoNotDisturb => '請勿打擾';

  @override
  String get presenceBlocked => '已封鎖';

  @override
  String get presenceOffline => '離線';

  @override
  String get presenceOutOfOffice => '外出';

  @override
  String get presenceUnknown => '未知';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status，外出';
  }
}

/// The translations for Chinese, as used in Hong Kong, using the Han script (`zh_Hant_HK`).
class FluentLocalizationsZhHantHk extends FluentLocalizationsZh {
  FluentLocalizationsZhHantHk() : super('zh_Hant_HK');

  @override
  String get close => '關閉';

  @override
  String get dismiss => '關閉';

  @override
  String get clear => '清除';

  @override
  String get open => '開啟';

  @override
  String get remove => '移除';

  @override
  String get more => '更多';

  @override
  String get overflowMore => '更多';

  @override
  String get selectAllRows => '選取所有列';

  @override
  String get selectRow => '選取列';

  @override
  String get sort => '排序';

  @override
  String get sortedAscending => '已遞增排序';

  @override
  String get sortedDescending => '已遞減排序';

  @override
  String get previousSlide => '上一張投影片';

  @override
  String get nextSlide => '下一張投影片';

  @override
  String get startSlideShow => '開始自動投影片放映';

  @override
  String get pauseSlideShow => '暫停自動投影片放映';

  @override
  String slideOf(int index, int count) {
    return '第 $index 張投影片，共 $count 張';
  }

  @override
  String stepOf(int index, int count) {
    return '第 $index 個步驟，共 $count 個';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value，滿分 $max';
  }

  @override
  String get openCalendar => '開啟行事曆';

  @override
  String get invalidDateFormat => '日期格式無效。';

  @override
  String get dateOutOfRange => '日期超出允許的範圍。';

  @override
  String get fieldRequired => '此欄位為必填。';

  @override
  String get goToToday => '移至今天';

  @override
  String get previousMonth => '上個月';

  @override
  String get nextMonth => '下個月';

  @override
  String get previousYear => '上一年';

  @override
  String get nextYear => '下一年';

  @override
  String get previousYearRange => '上一個年份範圍';

  @override
  String get nextYearRange => '下一個年份範圍';

  @override
  String monthPickerHeader(String caption) {
    return '$caption，變更年份';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption，變更月份';
  }

  @override
  String selectedDate(String date) {
    return '選取的日期 $date';
  }

  @override
  String todaysDate(String date) {
    return '今天的日期 $date';
  }

  @override
  String weekNumber(String number) {
    return '第 $number 週';
  }

  @override
  String get chartNoData => '圖表沒有可顯示的資料';

  @override
  String get chartNoDataAvailable => '沒有可用的資料';

  @override
  String get chartFallbackTitle => '圖表。 ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return '$axis 軸顯示$subject。 ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => '次要 Y';

  @override
  String get chartAxisCategories => '類別';

  @override
  String get chartAxisTime => '時間';

  @override
  String get chartAxisValues => '數值';

  @override
  String get chartLineLegendFallback => '折線';

  @override
  String funnelChartDescription(int count) {
    return '漏斗圖，有 $count 個區段';
  }

  @override
  String donutChartDescription(int count) {
    return '環圈圖，有 $count 個扇形';
  }

  @override
  String gaugeChartDescription(int count) {
    return '量測計圖表，有 $count 個區段。 ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return '目前值：$value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return '目前值為 $value';
  }

  @override
  String gaugeMinValue(String value) {
    return '最小值：$value';
  }

  @override
  String gaugeMaxValue(String value) {
    return '最大值：$value';
  }

  @override
  String get gaugeUnknownSegment => '未知';

  @override
  String ganttChartDescription(int count) {
    return '甘特圖，有 $count 個資料點。 ';
  }

  @override
  String heatMapChartDescription(int count) {
    return '熱度圖，有 $count 個資料點。 ';
  }

  @override
  String polarChartDescription(int count) {
    return '極座標圖，有 $count 個資料數列。';
  }

  @override
  String sparklineDescription(String label) {
    return '走勢圖，標籤為 $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return '桑基圖，有 $nodes 個節點和 $links 個連結';
  }

  @override
  String sankeyLinkFrom(String node) {
    return '來自 $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return '節點 $name，權重為 $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return '從 $source 到 $target 的連結，權重為 $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return '直條圖，有 $count 個直條。 ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return '直條圖，有 $count 個直條和 1 條折線。 ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return '直條圖，有 $count 個群組直條數列。 ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return '直條圖，有 $count 個群組直條數列和 $lines 個折線數列。 ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return '直條圖，有 $count 個堆疊直條。 ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return '直條圖，有 $count 個堆疊直條和 $lines 條折線。 ';
  }

  @override
  String get presenceAvailable => '有空';

  @override
  String get presenceAway => '離開';

  @override
  String get presenceBusy => '忙碌';

  @override
  String get presenceDoNotDisturb => '請勿打擾';

  @override
  String get presenceBlocked => '已封鎖';

  @override
  String get presenceOffline => '離線';

  @override
  String get presenceOutOfOffice => '外出';

  @override
  String get presenceUnknown => '未知';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status，外出';
  }
}

/// The translations for Chinese, as used in Macao, using the Han script (`zh_Hant_MO`).
class FluentLocalizationsZhHantMo extends FluentLocalizationsZh {
  FluentLocalizationsZhHantMo() : super('zh_Hant_MO');

  @override
  String get close => '關閉';

  @override
  String get dismiss => '關閉';

  @override
  String get clear => '清除';

  @override
  String get open => '開啟';

  @override
  String get remove => '移除';

  @override
  String get more => '更多';

  @override
  String get overflowMore => '更多';

  @override
  String get selectAllRows => '選取所有列';

  @override
  String get selectRow => '選取列';

  @override
  String get sort => '排序';

  @override
  String get sortedAscending => '已遞增排序';

  @override
  String get sortedDescending => '已遞減排序';

  @override
  String get previousSlide => '上一張投影片';

  @override
  String get nextSlide => '下一張投影片';

  @override
  String get startSlideShow => '開始自動投影片放映';

  @override
  String get pauseSlideShow => '暫停自動投影片放映';

  @override
  String slideOf(int index, int count) {
    return '第 $index 張投影片，共 $count 張';
  }

  @override
  String stepOf(int index, int count) {
    return '第 $index 個步驟，共 $count 個';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value，滿分 $max';
  }

  @override
  String get openCalendar => '開啟行事曆';

  @override
  String get invalidDateFormat => '日期格式無效。';

  @override
  String get dateOutOfRange => '日期超出允許的範圍。';

  @override
  String get fieldRequired => '此欄位為必填。';

  @override
  String get goToToday => '移至今天';

  @override
  String get previousMonth => '上個月';

  @override
  String get nextMonth => '下個月';

  @override
  String get previousYear => '上一年';

  @override
  String get nextYear => '下一年';

  @override
  String get previousYearRange => '上一個年份範圍';

  @override
  String get nextYearRange => '下一個年份範圍';

  @override
  String monthPickerHeader(String caption) {
    return '$caption，變更年份';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption，變更月份';
  }

  @override
  String selectedDate(String date) {
    return '選取的日期 $date';
  }

  @override
  String todaysDate(String date) {
    return '今天的日期 $date';
  }

  @override
  String weekNumber(String number) {
    return '第 $number 週';
  }

  @override
  String get chartNoData => '圖表沒有可顯示的資料';

  @override
  String get chartNoDataAvailable => '沒有可用的資料';

  @override
  String get chartFallbackTitle => '圖表。 ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return '$axis 軸顯示$subject。 ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => '次要 Y';

  @override
  String get chartAxisCategories => '類別';

  @override
  String get chartAxisTime => '時間';

  @override
  String get chartAxisValues => '數值';

  @override
  String get chartLineLegendFallback => '折線';

  @override
  String funnelChartDescription(int count) {
    return '漏斗圖，有 $count 個區段';
  }

  @override
  String donutChartDescription(int count) {
    return '環圈圖，有 $count 個扇形';
  }

  @override
  String gaugeChartDescription(int count) {
    return '量測計圖表，有 $count 個區段。 ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return '目前值：$value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return '目前值為 $value';
  }

  @override
  String gaugeMinValue(String value) {
    return '最小值：$value';
  }

  @override
  String gaugeMaxValue(String value) {
    return '最大值：$value';
  }

  @override
  String get gaugeUnknownSegment => '未知';

  @override
  String ganttChartDescription(int count) {
    return '甘特圖，有 $count 個資料點。 ';
  }

  @override
  String heatMapChartDescription(int count) {
    return '熱度圖，有 $count 個資料點。 ';
  }

  @override
  String polarChartDescription(int count) {
    return '極座標圖，有 $count 個資料數列。';
  }

  @override
  String sparklineDescription(String label) {
    return '走勢圖，標籤為 $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return '桑基圖，有 $nodes 個節點和 $links 個連結';
  }

  @override
  String sankeyLinkFrom(String node) {
    return '來自 $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return '節點 $name，權重為 $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return '從 $source 到 $target 的連結，權重為 $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return '直條圖，有 $count 個直條。 ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return '直條圖，有 $count 個直條和 1 條折線。 ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return '直條圖，有 $count 個群組直條數列。 ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return '直條圖，有 $count 個群組直條數列和 $lines 個折線數列。 ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return '直條圖，有 $count 個堆疊直條。 ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return '直條圖，有 $count 個堆疊直條和 $lines 條折線。 ';
  }

  @override
  String get presenceAvailable => '有空';

  @override
  String get presenceAway => '離開';

  @override
  String get presenceBusy => '忙碌';

  @override
  String get presenceDoNotDisturb => '請勿打擾';

  @override
  String get presenceBlocked => '已封鎖';

  @override
  String get presenceOffline => '離線';

  @override
  String get presenceOutOfOffice => '外出';

  @override
  String get presenceUnknown => '未知';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status，外出';
  }
}

/// The translations for Chinese, as used in Taiwan, using the Han script (`zh_Hant_TW`).
class FluentLocalizationsZhHantTw extends FluentLocalizationsZh {
  FluentLocalizationsZhHantTw() : super('zh_Hant_TW');

  @override
  String get close => '關閉';

  @override
  String get dismiss => '關閉';

  @override
  String get clear => '清除';

  @override
  String get open => '開啟';

  @override
  String get remove => '移除';

  @override
  String get more => '更多';

  @override
  String get overflowMore => '更多';

  @override
  String get selectAllRows => '選取所有列';

  @override
  String get selectRow => '選取列';

  @override
  String get sort => '排序';

  @override
  String get sortedAscending => '已遞增排序';

  @override
  String get sortedDescending => '已遞減排序';

  @override
  String get previousSlide => '上一張投影片';

  @override
  String get nextSlide => '下一張投影片';

  @override
  String get startSlideShow => '開始自動投影片放映';

  @override
  String get pauseSlideShow => '暫停自動投影片放映';

  @override
  String slideOf(int index, int count) {
    return '第 $index 張投影片，共 $count 張';
  }

  @override
  String stepOf(int index, int count) {
    return '第 $index 個步驟，共 $count 個';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value，滿分 $max';
  }

  @override
  String get openCalendar => '開啟行事曆';

  @override
  String get invalidDateFormat => '日期格式無效。';

  @override
  String get dateOutOfRange => '日期超出允許的範圍。';

  @override
  String get fieldRequired => '此欄位為必填。';

  @override
  String get goToToday => '移至今天';

  @override
  String get previousMonth => '上個月';

  @override
  String get nextMonth => '下個月';

  @override
  String get previousYear => '上一年';

  @override
  String get nextYear => '下一年';

  @override
  String get previousYearRange => '上一個年份範圍';

  @override
  String get nextYearRange => '下一個年份範圍';

  @override
  String monthPickerHeader(String caption) {
    return '$caption，變更年份';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption，變更月份';
  }

  @override
  String selectedDate(String date) {
    return '選取的日期 $date';
  }

  @override
  String todaysDate(String date) {
    return '今天的日期 $date';
  }

  @override
  String weekNumber(String number) {
    return '第 $number 週';
  }

  @override
  String get chartNoData => '圖表沒有可顯示的資料';

  @override
  String get chartNoDataAvailable => '沒有可用的資料';

  @override
  String get chartFallbackTitle => '圖表。 ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return '$axis 軸顯示$subject。 ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => '次要 Y';

  @override
  String get chartAxisCategories => '類別';

  @override
  String get chartAxisTime => '時間';

  @override
  String get chartAxisValues => '數值';

  @override
  String get chartLineLegendFallback => '折線';

  @override
  String funnelChartDescription(int count) {
    return '漏斗圖，有 $count 個區段';
  }

  @override
  String donutChartDescription(int count) {
    return '環圈圖，有 $count 個扇形';
  }

  @override
  String gaugeChartDescription(int count) {
    return '量測計圖表，有 $count 個區段。 ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return '目前值：$value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return '目前值為 $value';
  }

  @override
  String gaugeMinValue(String value) {
    return '最小值：$value';
  }

  @override
  String gaugeMaxValue(String value) {
    return '最大值：$value';
  }

  @override
  String get gaugeUnknownSegment => '未知';

  @override
  String ganttChartDescription(int count) {
    return '甘特圖，有 $count 個資料點。 ';
  }

  @override
  String heatMapChartDescription(int count) {
    return '熱度圖，有 $count 個資料點。 ';
  }

  @override
  String polarChartDescription(int count) {
    return '極座標圖，有 $count 個資料數列。';
  }

  @override
  String sparklineDescription(String label) {
    return '走勢圖，標籤為 $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return '桑基圖，有 $nodes 個節點和 $links 個連結';
  }

  @override
  String sankeyLinkFrom(String node) {
    return '來自 $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return '節點 $name，權重為 $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return '從 $source 到 $target 的連結，權重為 $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return '直條圖，有 $count 個直條。 ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return '直條圖，有 $count 個直條和 1 條折線。 ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return '直條圖，有 $count 個群組直條數列。 ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return '直條圖，有 $count 個群組直條數列和 $lines 個折線數列。 ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return '直條圖，有 $count 個堆疊直條。 ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return '直條圖，有 $count 個堆疊直條和 $lines 條折線。 ';
  }

  @override
  String get presenceAvailable => '有空';

  @override
  String get presenceAway => '離開';

  @override
  String get presenceBusy => '忙碌';

  @override
  String get presenceDoNotDisturb => '請勿打擾';

  @override
  String get presenceBlocked => '已封鎖';

  @override
  String get presenceOffline => '離線';

  @override
  String get presenceOutOfOffice => '外出';

  @override
  String get presenceUnknown => '未知';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status，外出';
  }
}

/// The translations for Chinese, as used in Singapore (`zh_SG`).
class FluentLocalizationsZhSg extends FluentLocalizationsZh {
  FluentLocalizationsZhSg() : super('zh_SG');

  @override
  String get close => '关闭';

  @override
  String get dismiss => '消除';

  @override
  String get clear => '清除';

  @override
  String get open => '打开';

  @override
  String get remove => '移除';

  @override
  String get more => '更多';

  @override
  String get overflowMore => '更多';

  @override
  String get selectAllRows => '选择所有行';

  @override
  String get selectRow => '选择行';

  @override
  String get sort => '排序';

  @override
  String get sortedAscending => '已按升序排序';

  @override
  String get sortedDescending => '已按降序排序';

  @override
  String get previousSlide => '上一张幻灯片';

  @override
  String get nextSlide => '下一张幻灯片';

  @override
  String get startSlideShow => '开始自动放映幻灯片';

  @override
  String get pauseSlideShow => '暂停自动放映幻灯片';

  @override
  String slideOf(int index, int count) {
    return '第 $index 张幻灯片，共 $count 张';
  }

  @override
  String stepOf(int index, int count) {
    return '第 $index 步，共 $count 步';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$max 中的 $value';
  }

  @override
  String get openCalendar => '打开日历';

  @override
  String get invalidDateFormat => '日期格式无效。';

  @override
  String get dateOutOfRange => '日期超出允许的范围。';

  @override
  String get fieldRequired => '此字段为必填项。';

  @override
  String get goToToday => '转到今天';

  @override
  String get previousMonth => '上个月';

  @override
  String get nextMonth => '下个月';

  @override
  String get previousYear => '上一年';

  @override
  String get nextYear => '下一年';

  @override
  String get previousYearRange => '上一个年份范围';

  @override
  String get nextYearRange => '下一个年份范围';

  @override
  String monthPickerHeader(String caption) {
    return '$caption，更改年份';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption，更改月份';
  }

  @override
  String selectedDate(String date) {
    return '所选日期 $date';
  }

  @override
  String todaysDate(String date) {
    return '今天的日期 $date';
  }

  @override
  String weekNumber(String number) {
    return '第 $number 周';
  }

  @override
  String get chartNoData => '图表没有可显示的数据';

  @override
  String get chartNoDataAvailable => '无可用数据';

  @override
  String get chartFallbackTitle => '图表。 ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return '$axis 轴显示$subject。 ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => '次要 Y';

  @override
  String get chartAxisCategories => '类别';

  @override
  String get chartAxisTime => '时间';

  @override
  String get chartAxisValues => '值';

  @override
  String get chartLineLegendFallback => '折线';

  @override
  String funnelChartDescription(int count) {
    return '包含 $count 个分段的漏斗图';
  }

  @override
  String donutChartDescription(int count) {
    return '包含 $count 个扇区的环形图';
  }

  @override
  String gaugeChartDescription(int count) {
    return '包含 $count 个分段的仪表图。 ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return '当前值：$value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return '当前值为 $value';
  }

  @override
  String gaugeMinValue(String value) {
    return '最小值：$value';
  }

  @override
  String gaugeMaxValue(String value) {
    return '最大值：$value';
  }

  @override
  String get gaugeUnknownSegment => '未知';

  @override
  String ganttChartDescription(int count) {
    return '包含 $count 个数据点的甘特图。 ';
  }

  @override
  String heatMapChartDescription(int count) {
    return '包含 $count 个数据点的热图。 ';
  }

  @override
  String polarChartDescription(int count) {
    return '包含 $count 个数据系列的极坐标图。';
  }

  @override
  String sparklineDescription(String label) {
    return '标签为 $label 的迷你图';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return '包含 $nodes 个节点和 $links 个链接的桑基图';
  }

  @override
  String sankeyLinkFrom(String node) {
    return '来自 $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return '节点 $name，权重为 $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return '从 $source 到 $target 的链接，权重为 $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return '包含 $count 个柱形的柱形图。 ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return '包含 $count 个柱形和 1 条折线的柱形图。 ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return '包含 $count 个分组柱形系列的柱形图。 ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return '包含 $count 个分组柱形系列和 $lines 个折线系列的柱形图。 ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return '包含 $count 个堆积柱形的柱形图。 ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return '包含 $count 个堆积柱形和 $lines 条折线的柱形图。 ';
  }

  @override
  String get presenceAvailable => '有空';

  @override
  String get presenceAway => '离开';

  @override
  String get presenceBusy => '忙碌';

  @override
  String get presenceDoNotDisturb => '请勿打扰';

  @override
  String get presenceBlocked => '已阻止';

  @override
  String get presenceOffline => '脱机';

  @override
  String get presenceOutOfOffice => '外出';

  @override
  String get presenceUnknown => '未知';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status，外出';
  }
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class FluentLocalizationsZhTw extends FluentLocalizationsZh {
  FluentLocalizationsZhTw() : super('zh_TW');

  @override
  String get close => '關閉';

  @override
  String get dismiss => '關閉';

  @override
  String get clear => '清除';

  @override
  String get open => '開啟';

  @override
  String get remove => '移除';

  @override
  String get more => '更多';

  @override
  String get overflowMore => '更多';

  @override
  String get selectAllRows => '選取所有列';

  @override
  String get selectRow => '選取列';

  @override
  String get sort => '排序';

  @override
  String get sortedAscending => '已遞增排序';

  @override
  String get sortedDescending => '已遞減排序';

  @override
  String get previousSlide => '上一張投影片';

  @override
  String get nextSlide => '下一張投影片';

  @override
  String get startSlideShow => '開始自動投影片放映';

  @override
  String get pauseSlideShow => '暫停自動投影片放映';

  @override
  String slideOf(int index, int count) {
    return '第 $index 張投影片，共 $count 張';
  }

  @override
  String stepOf(int index, int count) {
    return '第 $index 個步驟，共 $count 個';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value，滿分 $max';
  }

  @override
  String get openCalendar => '開啟行事曆';

  @override
  String get invalidDateFormat => '日期格式無效。';

  @override
  String get dateOutOfRange => '日期超出允許的範圍。';

  @override
  String get fieldRequired => '此欄位為必填。';

  @override
  String get goToToday => '移至今天';

  @override
  String get previousMonth => '上個月';

  @override
  String get nextMonth => '下個月';

  @override
  String get previousYear => '上一年';

  @override
  String get nextYear => '下一年';

  @override
  String get previousYearRange => '上一個年份範圍';

  @override
  String get nextYearRange => '下一個年份範圍';

  @override
  String monthPickerHeader(String caption) {
    return '$caption，變更年份';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption，變更月份';
  }

  @override
  String selectedDate(String date) {
    return '選取的日期 $date';
  }

  @override
  String todaysDate(String date) {
    return '今天的日期 $date';
  }

  @override
  String weekNumber(String number) {
    return '第 $number 週';
  }

  @override
  String get chartNoData => '圖表沒有可顯示的資料';

  @override
  String get chartNoDataAvailable => '沒有可用的資料';

  @override
  String get chartFallbackTitle => '圖表。 ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return '$axis 軸顯示$subject。 ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => '次要 Y';

  @override
  String get chartAxisCategories => '類別';

  @override
  String get chartAxisTime => '時間';

  @override
  String get chartAxisValues => '數值';

  @override
  String get chartLineLegendFallback => '折線';

  @override
  String funnelChartDescription(int count) {
    return '漏斗圖，有 $count 個區段';
  }

  @override
  String donutChartDescription(int count) {
    return '環圈圖，有 $count 個扇形';
  }

  @override
  String gaugeChartDescription(int count) {
    return '量測計圖表，有 $count 個區段。 ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return '目前值：$value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return '目前值為 $value';
  }

  @override
  String gaugeMinValue(String value) {
    return '最小值：$value';
  }

  @override
  String gaugeMaxValue(String value) {
    return '最大值：$value';
  }

  @override
  String get gaugeUnknownSegment => '未知';

  @override
  String ganttChartDescription(int count) {
    return '甘特圖，有 $count 個資料點。 ';
  }

  @override
  String heatMapChartDescription(int count) {
    return '熱度圖，有 $count 個資料點。 ';
  }

  @override
  String polarChartDescription(int count) {
    return '極座標圖，有 $count 個資料數列。';
  }

  @override
  String sparklineDescription(String label) {
    return '走勢圖，標籤為 $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return '桑基圖，有 $nodes 個節點和 $links 個連結';
  }

  @override
  String sankeyLinkFrom(String node) {
    return '來自 $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return '節點 $name，權重為 $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return '從 $source 到 $target 的連結，權重為 $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return '直條圖，有 $count 個直條。 ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return '直條圖，有 $count 個直條和 1 條折線。 ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return '直條圖，有 $count 個群組直條數列。 ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return '直條圖，有 $count 個群組直條數列和 $lines 個折線數列。 ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return '直條圖，有 $count 個堆疊直條。 ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return '直條圖，有 $count 個堆疊直條和 $lines 條折線。 ';
  }

  @override
  String get presenceAvailable => '有空';

  @override
  String get presenceAway => '離開';

  @override
  String get presenceBusy => '忙碌';

  @override
  String get presenceDoNotDisturb => '請勿打擾';

  @override
  String get presenceBlocked => '已封鎖';

  @override
  String get presenceOffline => '離線';

  @override
  String get presenceOutOfOffice => '外出';

  @override
  String get presenceUnknown => '未知';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status，外出';
  }
}
