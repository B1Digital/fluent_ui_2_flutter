// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fluent_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class FluentLocalizationsJa extends FluentLocalizations {
  FluentLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get close => '閉じる';

  @override
  String get dismiss => '閉じる';

  @override
  String get clear => 'クリア';

  @override
  String get open => '開く';

  @override
  String get remove => '削除';

  @override
  String get more => 'その他';

  @override
  String get overflowMore => '件';

  @override
  String get selectAllRows => 'すべての行を選択';

  @override
  String get selectRow => '行を選択';

  @override
  String get sort => '並べ替え';

  @override
  String get sortedAscending => '昇順に並べ替え済み';

  @override
  String get sortedDescending => '降順に並べ替え済み';

  @override
  String get previousSlide => '前のスライド';

  @override
  String get nextSlide => '次のスライド';

  @override
  String get startSlideShow => '自動スライド ショーを開始';

  @override
  String get pauseSlideShow => '自動スライド ショーを一時停止';

  @override
  String slideOf(int index, int count) {
    return 'スライド $index/$count';
  }

  @override
  String stepOf(int index, int count) {
    return 'ステップ $index/$count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$max 中 $value';
  }

  @override
  String get openCalendar => 'カレンダーを開く';

  @override
  String get invalidDateFormat => '日付の形式が正しくありません。';

  @override
  String get dateOutOfRange => '日付が指定可能な範囲外です。';

  @override
  String get fieldRequired => 'このフィールドは必須です。';

  @override
  String get goToToday => '今日に移動';

  @override
  String get previousMonth => '前の月';

  @override
  String get nextMonth => '次の月';

  @override
  String get previousYear => '前の年';

  @override
  String get nextYear => '次の年';

  @override
  String get previousYearRange => '前の年の範囲';

  @override
  String get nextYearRange => '次の年の範囲';

  @override
  String monthPickerHeader(String caption) {
    return '$caption、年を変更';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption、月を変更';
  }

  @override
  String selectedDate(String date) {
    return '選択された日付 $date';
  }

  @override
  String todaysDate(String date) {
    return '今日の日付 $date';
  }

  @override
  String weekNumber(String number) {
    return '第 $number 週';
  }

  @override
  String get chartNoData => 'グラフに表示するデータがありません';

  @override
  String get chartNoDataAvailable => 'データがありません';

  @override
  String get chartFallbackTitle => 'グラフ。 ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return '$axis 軸に $subject を表示。 ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => '第 2 Y';

  @override
  String get chartAxisCategories => 'カテゴリ';

  @override
  String get chartAxisTime => '時間';

  @override
  String get chartAxisValues => '値';

  @override
  String get chartLineLegendFallback => '折れ線';

  @override
  String funnelChartDescription(int count) {
    return '$count 個のセグメントを含むじょうごグラフ';
  }

  @override
  String donutChartDescription(int count) {
    return '$count 個のスライスを含むドーナツ グラフ';
  }

  @override
  String gaugeChartDescription(int count) {
    return '$count 個のセグメントを含むゲージ グラフ。 ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return '現在の値: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return '現在の値は $value';
  }

  @override
  String gaugeMinValue(String value) {
    return '最小値: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return '最大値: $value';
  }

  @override
  String get gaugeUnknownSegment => '不明';

  @override
  String ganttChartDescription(int count) {
    return '$count 個のデータ ポイントを含むガント チャート。 ';
  }

  @override
  String heatMapChartDescription(int count) {
    return '$count 個のデータ ポイントを含むヒート マップ グラフ。 ';
  }

  @override
  String polarChartDescription(int count) {
    return '$count 個のデータ系列を含む極座標グラフ。';
  }

  @override
  String sparklineDescription(String label) {
    return 'ラベル $label のスパークライン';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return '$nodes 個のノードと $links 個のリンクを含むサンキー グラフ';
  }

  @override
  String sankeyLinkFrom(String node) {
    return '$node から';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return '重み $weight のノード $name';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return '$source から $target への重み $weight のリンク';
  }

  @override
  String verticalBarChartDescription(int count) {
    return '$count 本の縦棒を含む縦棒グラフ。 ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return '$count 本の縦棒と 1 本の折れ線を含む縦棒グラフ。 ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return '$count 個のグループ化された縦棒系列を含む縦棒グラフ。 ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return '$count 個のグループ化された縦棒系列と $lines 個の折れ線系列を含む縦棒グラフ。 ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return '$count 本の積み上げ縦棒を含む縦棒グラフ。 ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return '$count 本の積み上げ縦棒と $lines 本の折れ線を含む縦棒グラフ。 ';
  }

  @override
  String get presenceAvailable => '連絡可能';

  @override
  String get presenceAway => '退席中';

  @override
  String get presenceBusy => '取り込み中';

  @override
  String get presenceDoNotDisturb => '応答不可';

  @override
  String get presenceBlocked => 'ブロック済み';

  @override
  String get presenceOffline => 'オフライン';

  @override
  String get presenceOutOfOffice => '外出中';

  @override
  String get presenceUnknown => '不明';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status (外出中)';
  }
}

/// The translations for Japanese, as used in Japan (`ja_JP`).
class FluentLocalizationsJaJp extends FluentLocalizationsJa {
  FluentLocalizationsJaJp() : super('ja_JP');

  @override
  String get close => '閉じる';

  @override
  String get dismiss => '閉じる';

  @override
  String get clear => 'クリア';

  @override
  String get open => '開く';

  @override
  String get remove => '削除';

  @override
  String get more => 'その他';

  @override
  String get overflowMore => '件';

  @override
  String get selectAllRows => 'すべての行を選択';

  @override
  String get selectRow => '行を選択';

  @override
  String get sort => '並べ替え';

  @override
  String get sortedAscending => '昇順に並べ替え済み';

  @override
  String get sortedDescending => '降順に並べ替え済み';

  @override
  String get previousSlide => '前のスライド';

  @override
  String get nextSlide => '次のスライド';

  @override
  String get startSlideShow => '自動スライド ショーを開始';

  @override
  String get pauseSlideShow => '自動スライド ショーを一時停止';

  @override
  String slideOf(int index, int count) {
    return 'スライド $index/$count';
  }

  @override
  String stepOf(int index, int count) {
    return 'ステップ $index/$count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$max 中 $value';
  }

  @override
  String get openCalendar => 'カレンダーを開く';

  @override
  String get invalidDateFormat => '日付の形式が正しくありません。';

  @override
  String get dateOutOfRange => '日付が指定可能な範囲外です。';

  @override
  String get fieldRequired => 'このフィールドは必須です。';

  @override
  String get goToToday => '今日に移動';

  @override
  String get previousMonth => '前の月';

  @override
  String get nextMonth => '次の月';

  @override
  String get previousYear => '前の年';

  @override
  String get nextYear => '次の年';

  @override
  String get previousYearRange => '前の年の範囲';

  @override
  String get nextYearRange => '次の年の範囲';

  @override
  String monthPickerHeader(String caption) {
    return '$caption、年を変更';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption、月を変更';
  }

  @override
  String selectedDate(String date) {
    return '選択された日付 $date';
  }

  @override
  String todaysDate(String date) {
    return '今日の日付 $date';
  }

  @override
  String weekNumber(String number) {
    return '第 $number 週';
  }

  @override
  String get chartNoData => 'グラフに表示するデータがありません';

  @override
  String get chartNoDataAvailable => 'データがありません';

  @override
  String get chartFallbackTitle => 'グラフ。 ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return '$axis 軸に $subject を表示。 ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => '第 2 Y';

  @override
  String get chartAxisCategories => 'カテゴリ';

  @override
  String get chartAxisTime => '時間';

  @override
  String get chartAxisValues => '値';

  @override
  String get chartLineLegendFallback => '折れ線';

  @override
  String funnelChartDescription(int count) {
    return '$count 個のセグメントを含むじょうごグラフ';
  }

  @override
  String donutChartDescription(int count) {
    return '$count 個のスライスを含むドーナツ グラフ';
  }

  @override
  String gaugeChartDescription(int count) {
    return '$count 個のセグメントを含むゲージ グラフ。 ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return '現在の値: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return '現在の値は $value';
  }

  @override
  String gaugeMinValue(String value) {
    return '最小値: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return '最大値: $value';
  }

  @override
  String get gaugeUnknownSegment => '不明';

  @override
  String ganttChartDescription(int count) {
    return '$count 個のデータ ポイントを含むガント チャート。 ';
  }

  @override
  String heatMapChartDescription(int count) {
    return '$count 個のデータ ポイントを含むヒート マップ グラフ。 ';
  }

  @override
  String polarChartDescription(int count) {
    return '$count 個のデータ系列を含む極座標グラフ。';
  }

  @override
  String sparklineDescription(String label) {
    return 'ラベル $label のスパークライン';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return '$nodes 個のノードと $links 個のリンクを含むサンキー グラフ';
  }

  @override
  String sankeyLinkFrom(String node) {
    return '$node から';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return '重み $weight のノード $name';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return '$source から $target への重み $weight のリンク';
  }

  @override
  String verticalBarChartDescription(int count) {
    return '$count 本の縦棒を含む縦棒グラフ。 ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return '$count 本の縦棒と 1 本の折れ線を含む縦棒グラフ。 ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return '$count 個のグループ化された縦棒系列を含む縦棒グラフ。 ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return '$count 個のグループ化された縦棒系列と $lines 個の折れ線系列を含む縦棒グラフ。 ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return '$count 本の積み上げ縦棒を含む縦棒グラフ。 ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return '$count 本の積み上げ縦棒と $lines 本の折れ線を含む縦棒グラフ。 ';
  }

  @override
  String get presenceAvailable => '連絡可能';

  @override
  String get presenceAway => '退席中';

  @override
  String get presenceBusy => '取り込み中';

  @override
  String get presenceDoNotDisturb => '応答不可';

  @override
  String get presenceBlocked => 'ブロック済み';

  @override
  String get presenceOffline => 'オフライン';

  @override
  String get presenceOutOfOffice => '外出中';

  @override
  String get presenceUnknown => '不明';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status (外出中)';
  }
}
