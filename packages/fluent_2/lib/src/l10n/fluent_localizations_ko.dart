// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fluent_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class FluentLocalizationsKo extends FluentLocalizations {
  FluentLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get close => '닫기';

  @override
  String get dismiss => '해제';

  @override
  String get clear => '지우기';

  @override
  String get open => '열기';

  @override
  String get remove => '제거';

  @override
  String get more => '더 보기';

  @override
  String get overflowMore => '개 더';

  @override
  String get selectAllRows => '모든 행 선택';

  @override
  String get selectRow => '행 선택';

  @override
  String get sort => '정렬';

  @override
  String get sortedAscending => '오름차순으로 정렬됨';

  @override
  String get sortedDescending => '내림차순으로 정렬됨';

  @override
  String get previousSlide => '이전 슬라이드';

  @override
  String get nextSlide => '다음 슬라이드';

  @override
  String get startSlideShow => '자동 슬라이드 쇼 시작';

  @override
  String get pauseSlideShow => '자동 슬라이드 쇼 일시 중지';

  @override
  String slideOf(int index, int count) {
    return '슬라이드 $count개 중 $index번째';
  }

  @override
  String stepOf(int index, int count) {
    return '$count단계 중 $index단계';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$max 중 $value';
  }

  @override
  String get openCalendar => '달력 열기';

  @override
  String get invalidDateFormat => '날짜 형식이 잘못되었습니다.';

  @override
  String get dateOutOfRange => '날짜가 허용된 범위를 벗어났습니다.';

  @override
  String get fieldRequired => '이 필드는 필수입니다.';

  @override
  String get goToToday => '오늘로 이동';

  @override
  String get previousMonth => '이전 달';

  @override
  String get nextMonth => '다음 달';

  @override
  String get previousYear => '이전 연도';

  @override
  String get nextYear => '다음 연도';

  @override
  String get previousYearRange => '이전 연도 범위';

  @override
  String get nextYearRange => '다음 연도 범위';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, 연도 변경';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, 월 변경';
  }

  @override
  String selectedDate(String date) {
    return '선택한 날짜 $date';
  }

  @override
  String todaysDate(String date) {
    return '오늘 날짜 $date';
  }

  @override
  String weekNumber(String number) {
    return '$number주차';
  }

  @override
  String get chartNoData => '그래프에 표시할 데이터가 없습니다';

  @override
  String get chartNoDataAvailable => '사용할 수 있는 데이터 없음';

  @override
  String get chartFallbackTitle => '차트. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return '$axis축에 $subject 표시. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => '보조 Y';

  @override
  String get chartAxisCategories => '범주';

  @override
  String get chartAxisTime => '시간';

  @override
  String get chartAxisValues => '값';

  @override
  String get chartLineLegendFallback => '꺾은선';

  @override
  String funnelChartDescription(int count) {
    return '세그먼트 $count개가 있는 깔때기형 차트';
  }

  @override
  String donutChartDescription(int count) {
    return '조각 $count개가 있는 도넛형 차트';
  }

  @override
  String gaugeChartDescription(int count) {
    return '세그먼트 $count개가 있는 계기 차트. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return '현재 값: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return '현재 값은 $value';
  }

  @override
  String gaugeMinValue(String value) {
    return '최소값: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return '최대값: $value';
  }

  @override
  String get gaugeUnknownSegment => '알 수 없음';

  @override
  String ganttChartDescription(int count) {
    return '데이터 요소 $count개가 있는 간트 차트. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return '데이터 요소 $count개가 있는 히트 맵 차트. ';
  }

  @override
  String polarChartDescription(int count) {
    return '데이터 계열 $count개가 있는 극좌표 차트.';
  }

  @override
  String sparklineDescription(String label) {
    return '레이블이 $label인 스파크라인';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return '노드 $nodes개와 링크 $links개가 있는 생키 차트';
  }

  @override
  String sankeyLinkFrom(String node) {
    return '$node에서';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return '가중치가 $weight인 노드 $name';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return '$source에서 $target까지 가중치 $weight의 링크';
  }

  @override
  String verticalBarChartDescription(int count) {
    return '막대 $count개가 있는 세로 막대형 차트. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return '막대 $count개와 선 1개가 있는 세로 막대형 차트. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return '그룹화된 막대 계열 $count개가 있는 세로 막대형 차트. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return '그룹화된 막대 계열 $count개와 꺾은선 계열 $lines개가 있는 세로 막대형 차트. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return '누적 막대 $count개가 있는 세로 막대형 차트. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return '누적 막대 $count개와 선 $lines개가 있는 세로 막대형 차트. ';
  }

  @override
  String get presenceAvailable => '대화 가능';

  @override
  String get presenceAway => '자리 비움';

  @override
  String get presenceBusy => '다른 용무 중';

  @override
  String get presenceDoNotDisturb => '방해 금지';

  @override
  String get presenceBlocked => '차단됨';

  @override
  String get presenceOffline => '오프라인';

  @override
  String get presenceOutOfOffice => '부재 중';

  @override
  String get presenceUnknown => '알 수 없음';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, 부재 중';
  }
}

/// The translations for Korean, as used in Republic of Korea (`ko_KR`).
class FluentLocalizationsKoKr extends FluentLocalizationsKo {
  FluentLocalizationsKoKr() : super('ko_KR');

  @override
  String get close => '닫기';

  @override
  String get dismiss => '해제';

  @override
  String get clear => '지우기';

  @override
  String get open => '열기';

  @override
  String get remove => '제거';

  @override
  String get more => '더 보기';

  @override
  String get overflowMore => '개 더';

  @override
  String get selectAllRows => '모든 행 선택';

  @override
  String get selectRow => '행 선택';

  @override
  String get sort => '정렬';

  @override
  String get sortedAscending => '오름차순으로 정렬됨';

  @override
  String get sortedDescending => '내림차순으로 정렬됨';

  @override
  String get previousSlide => '이전 슬라이드';

  @override
  String get nextSlide => '다음 슬라이드';

  @override
  String get startSlideShow => '자동 슬라이드 쇼 시작';

  @override
  String get pauseSlideShow => '자동 슬라이드 쇼 일시 중지';

  @override
  String slideOf(int index, int count) {
    return '슬라이드 $count개 중 $index번째';
  }

  @override
  String stepOf(int index, int count) {
    return '$count단계 중 $index단계';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$max 중 $value';
  }

  @override
  String get openCalendar => '달력 열기';

  @override
  String get invalidDateFormat => '날짜 형식이 잘못되었습니다.';

  @override
  String get dateOutOfRange => '날짜가 허용된 범위를 벗어났습니다.';

  @override
  String get fieldRequired => '이 필드는 필수입니다.';

  @override
  String get goToToday => '오늘로 이동';

  @override
  String get previousMonth => '이전 달';

  @override
  String get nextMonth => '다음 달';

  @override
  String get previousYear => '이전 연도';

  @override
  String get nextYear => '다음 연도';

  @override
  String get previousYearRange => '이전 연도 범위';

  @override
  String get nextYearRange => '다음 연도 범위';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, 연도 변경';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, 월 변경';
  }

  @override
  String selectedDate(String date) {
    return '선택한 날짜 $date';
  }

  @override
  String todaysDate(String date) {
    return '오늘 날짜 $date';
  }

  @override
  String weekNumber(String number) {
    return '$number주차';
  }

  @override
  String get chartNoData => '그래프에 표시할 데이터가 없습니다';

  @override
  String get chartNoDataAvailable => '사용할 수 있는 데이터 없음';

  @override
  String get chartFallbackTitle => '차트. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return '$axis축에 $subject 표시. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => '보조 Y';

  @override
  String get chartAxisCategories => '범주';

  @override
  String get chartAxisTime => '시간';

  @override
  String get chartAxisValues => '값';

  @override
  String get chartLineLegendFallback => '꺾은선';

  @override
  String funnelChartDescription(int count) {
    return '세그먼트 $count개가 있는 깔때기형 차트';
  }

  @override
  String donutChartDescription(int count) {
    return '조각 $count개가 있는 도넛형 차트';
  }

  @override
  String gaugeChartDescription(int count) {
    return '세그먼트 $count개가 있는 계기 차트. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return '현재 값: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return '현재 값은 $value';
  }

  @override
  String gaugeMinValue(String value) {
    return '최소값: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return '최대값: $value';
  }

  @override
  String get gaugeUnknownSegment => '알 수 없음';

  @override
  String ganttChartDescription(int count) {
    return '데이터 요소 $count개가 있는 간트 차트. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return '데이터 요소 $count개가 있는 히트 맵 차트. ';
  }

  @override
  String polarChartDescription(int count) {
    return '데이터 계열 $count개가 있는 극좌표 차트.';
  }

  @override
  String sparklineDescription(String label) {
    return '레이블이 $label인 스파크라인';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return '노드 $nodes개와 링크 $links개가 있는 생키 차트';
  }

  @override
  String sankeyLinkFrom(String node) {
    return '$node에서';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return '가중치가 $weight인 노드 $name';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return '$source에서 $target까지 가중치 $weight의 링크';
  }

  @override
  String verticalBarChartDescription(int count) {
    return '막대 $count개가 있는 세로 막대형 차트. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return '막대 $count개와 선 1개가 있는 세로 막대형 차트. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return '그룹화된 막대 계열 $count개가 있는 세로 막대형 차트. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return '그룹화된 막대 계열 $count개와 꺾은선 계열 $lines개가 있는 세로 막대형 차트. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return '누적 막대 $count개가 있는 세로 막대형 차트. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return '누적 막대 $count개와 선 $lines개가 있는 세로 막대형 차트. ';
  }

  @override
  String get presenceAvailable => '대화 가능';

  @override
  String get presenceAway => '자리 비움';

  @override
  String get presenceBusy => '다른 용무 중';

  @override
  String get presenceDoNotDisturb => '방해 금지';

  @override
  String get presenceBlocked => '차단됨';

  @override
  String get presenceOffline => '오프라인';

  @override
  String get presenceOutOfOffice => '부재 중';

  @override
  String get presenceUnknown => '알 수 없음';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, 부재 중';
  }
}
