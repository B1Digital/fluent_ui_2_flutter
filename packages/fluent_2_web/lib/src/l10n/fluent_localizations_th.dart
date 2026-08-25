// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fluent_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class FluentLocalizationsTh extends FluentLocalizations {
  FluentLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get close => 'ปิด';

  @override
  String get dismiss => 'ปิด';

  @override
  String get clear => 'ล้าง';

  @override
  String get open => 'เปิด';

  @override
  String get remove => 'เอาออก';

  @override
  String get more => 'เพิ่มเติม';

  @override
  String get overflowMore => 'เพิ่มเติม';

  @override
  String get selectAllRows => 'เลือกแถวทั้งหมด';

  @override
  String get selectRow => 'เลือกแถว';

  @override
  String get sort => 'เรียงลำดับ';

  @override
  String get sortedAscending => 'เรียงลำดับจากน้อยไปมาก';

  @override
  String get sortedDescending => 'เรียงลำดับจากมากไปน้อย';

  @override
  String get previousSlide => 'สไลด์ก่อนหน้า';

  @override
  String get nextSlide => 'สไลด์ถัดไป';

  @override
  String get startSlideShow => 'เริ่มการนำเสนอภาพนิ่งอัตโนมัติ';

  @override
  String get pauseSlideShow => 'หยุดการนำเสนอภาพนิ่งอัตโนมัติชั่วคราว';

  @override
  String slideOf(int index, int count) {
    return 'สไลด์ $index จาก $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'ขั้นตอนที่ $index จาก $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value จาก $max';
  }

  @override
  String get openCalendar => 'เปิดปฏิทิน';

  @override
  String get invalidDateFormat => 'รูปแบบวันที่ไม่ถูกต้อง';

  @override
  String get dateOutOfRange => 'วันที่อยู่นอกช่วงที่อนุญาต';

  @override
  String get fieldRequired => 'จำเป็นต้องกรอกข้อมูลในฟิลด์นี้';

  @override
  String get goToToday => 'ไปที่วันนี้';

  @override
  String get previousMonth => 'เดือนก่อนหน้า';

  @override
  String get nextMonth => 'เดือนถัดไป';

  @override
  String get previousYear => 'ปีก่อนหน้า';

  @override
  String get nextYear => 'ปีถัดไป';

  @override
  String get previousYearRange => 'ช่วงปีก่อนหน้า';

  @override
  String get nextYearRange => 'ช่วงปีถัดไป';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, เปลี่ยนปี';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, เปลี่ยนเดือน';
  }

  @override
  String selectedDate(String date) {
    return 'วันที่ที่เลือก $date';
  }

  @override
  String todaysDate(String date) {
    return 'วันที่ของวันนี้ $date';
  }

  @override
  String weekNumber(String number) {
    return 'สัปดาห์ที่ $number';
  }

  @override
  String get chartNoData => 'กราฟไม่มีข้อมูลที่จะแสดง';

  @override
  String get chartNoDataAvailable => 'ไม่มีข้อมูล';

  @override
  String get chartFallbackTitle => 'แผนภูมิ ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'แกน $axis แสดง $subject ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y รอง';

  @override
  String get chartAxisCategories => 'หมวดหมู่';

  @override
  String get chartAxisTime => 'เวลา';

  @override
  String get chartAxisValues => 'ค่า';

  @override
  String get chartLineLegendFallback => 'เส้น';

  @override
  String funnelChartDescription(int count) {
    return 'แผนภูมิกรวยที่มี $count ส่วน';
  }

  @override
  String donutChartDescription(int count) {
    return 'แผนภูมิโดนัทที่มี $count ชิ้น';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'แผนภูมิเกจที่มี $count ส่วน ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'ค่าปัจจุบัน: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'ค่าปัจจุบันคือ $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'ค่าต่ำสุด: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'ค่าสูงสุด: $value';
  }

  @override
  String get gaugeUnknownSegment => 'ไม่ทราบ';

  @override
  String ganttChartDescription(int count) {
    return 'แผนภูมิแกนต์ที่มีจุดข้อมูล $count จุด ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'แผนภูมิแผนที่ความร้อนที่มีจุดข้อมูล $count จุด ';
  }

  @override
  String polarChartDescription(int count) {
    return 'แผนภูมิเชิงขั้วที่มีชุดข้อมูล $count ชุด';
  }

  @override
  String sparklineDescription(String label) {
    return 'สปาร์กไลน์ที่มีป้ายชื่อ $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'แผนภูมิแซงกีที่มี $nodes โหนดและ $links ลิงก์';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'จาก $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'โหนด $name ที่มีน้ำหนัก $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'ลิงก์จาก $source ไปยัง $target ที่มีน้ำหนัก $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'แผนภูมิแท่งแนวตั้งที่มี $count แท่ง ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'แผนภูมิแท่งแนวตั้งที่มี $count แท่งและ 1 เส้น ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'แผนภูมิแท่งแนวตั้งที่มีชุดข้อมูลแท่งแบบกลุ่ม $count ชุด ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'แผนภูมิแท่งแนวตั้งที่มีชุดข้อมูลแท่งแบบกลุ่ม $count ชุดและชุดข้อมูลเส้น $lines ชุด ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'แผนภูมิแท่งแนวตั้งที่มีแท่งแบบเรียงซ้อน $count แท่ง ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'แผนภูมิแท่งแนวตั้งที่มีแท่งแบบเรียงซ้อน $count แท่งและ $lines เส้น ';
  }

  @override
  String get presenceAvailable => 'พร้อมใช้งาน';

  @override
  String get presenceAway => 'ไม่อยู่';

  @override
  String get presenceBusy => 'ไม่ว่าง';

  @override
  String get presenceDoNotDisturb => 'ห้ามรบกวน';

  @override
  String get presenceBlocked => 'ถูกบล็อก';

  @override
  String get presenceOffline => 'ออฟไลน์';

  @override
  String get presenceOutOfOffice => 'ไม่อยู่ที่สำนักงาน';

  @override
  String get presenceUnknown => 'ไม่ทราบ';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status ไม่อยู่ที่สำนักงาน';
  }
}

/// The translations for Thai, as used in Thailand (`th_TH`).
class FluentLocalizationsThTh extends FluentLocalizationsTh {
  FluentLocalizationsThTh() : super('th_TH');

  @override
  String get close => 'ปิด';

  @override
  String get dismiss => 'ปิด';

  @override
  String get clear => 'ล้าง';

  @override
  String get open => 'เปิด';

  @override
  String get remove => 'เอาออก';

  @override
  String get more => 'เพิ่มเติม';

  @override
  String get overflowMore => 'เพิ่มเติม';

  @override
  String get selectAllRows => 'เลือกแถวทั้งหมด';

  @override
  String get selectRow => 'เลือกแถว';

  @override
  String get sort => 'เรียงลำดับ';

  @override
  String get sortedAscending => 'เรียงลำดับจากน้อยไปมาก';

  @override
  String get sortedDescending => 'เรียงลำดับจากมากไปน้อย';

  @override
  String get previousSlide => 'สไลด์ก่อนหน้า';

  @override
  String get nextSlide => 'สไลด์ถัดไป';

  @override
  String get startSlideShow => 'เริ่มการนำเสนอภาพนิ่งอัตโนมัติ';

  @override
  String get pauseSlideShow => 'หยุดการนำเสนอภาพนิ่งอัตโนมัติชั่วคราว';

  @override
  String slideOf(int index, int count) {
    return 'สไลด์ $index จาก $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'ขั้นตอนที่ $index จาก $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value จาก $max';
  }

  @override
  String get openCalendar => 'เปิดปฏิทิน';

  @override
  String get invalidDateFormat => 'รูปแบบวันที่ไม่ถูกต้อง';

  @override
  String get dateOutOfRange => 'วันที่อยู่นอกช่วงที่อนุญาต';

  @override
  String get fieldRequired => 'จำเป็นต้องกรอกข้อมูลในฟิลด์นี้';

  @override
  String get goToToday => 'ไปที่วันนี้';

  @override
  String get previousMonth => 'เดือนก่อนหน้า';

  @override
  String get nextMonth => 'เดือนถัดไป';

  @override
  String get previousYear => 'ปีก่อนหน้า';

  @override
  String get nextYear => 'ปีถัดไป';

  @override
  String get previousYearRange => 'ช่วงปีก่อนหน้า';

  @override
  String get nextYearRange => 'ช่วงปีถัดไป';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, เปลี่ยนปี';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, เปลี่ยนเดือน';
  }

  @override
  String selectedDate(String date) {
    return 'วันที่ที่เลือก $date';
  }

  @override
  String todaysDate(String date) {
    return 'วันที่ของวันนี้ $date';
  }

  @override
  String weekNumber(String number) {
    return 'สัปดาห์ที่ $number';
  }

  @override
  String get chartNoData => 'กราฟไม่มีข้อมูลที่จะแสดง';

  @override
  String get chartNoDataAvailable => 'ไม่มีข้อมูล';

  @override
  String get chartFallbackTitle => 'แผนภูมิ ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'แกน $axis แสดง $subject ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y รอง';

  @override
  String get chartAxisCategories => 'หมวดหมู่';

  @override
  String get chartAxisTime => 'เวลา';

  @override
  String get chartAxisValues => 'ค่า';

  @override
  String get chartLineLegendFallback => 'เส้น';

  @override
  String funnelChartDescription(int count) {
    return 'แผนภูมิกรวยที่มี $count ส่วน';
  }

  @override
  String donutChartDescription(int count) {
    return 'แผนภูมิโดนัทที่มี $count ชิ้น';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'แผนภูมิเกจที่มี $count ส่วน ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'ค่าปัจจุบัน: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'ค่าปัจจุบันคือ $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'ค่าต่ำสุด: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'ค่าสูงสุด: $value';
  }

  @override
  String get gaugeUnknownSegment => 'ไม่ทราบ';

  @override
  String ganttChartDescription(int count) {
    return 'แผนภูมิแกนต์ที่มีจุดข้อมูล $count จุด ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'แผนภูมิแผนที่ความร้อนที่มีจุดข้อมูล $count จุด ';
  }

  @override
  String polarChartDescription(int count) {
    return 'แผนภูมิเชิงขั้วที่มีชุดข้อมูล $count ชุด';
  }

  @override
  String sparklineDescription(String label) {
    return 'สปาร์กไลน์ที่มีป้ายชื่อ $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'แผนภูมิแซงกีที่มี $nodes โหนดและ $links ลิงก์';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'จาก $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'โหนด $name ที่มีน้ำหนัก $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'ลิงก์จาก $source ไปยัง $target ที่มีน้ำหนัก $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'แผนภูมิแท่งแนวตั้งที่มี $count แท่ง ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'แผนภูมิแท่งแนวตั้งที่มี $count แท่งและ 1 เส้น ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'แผนภูมิแท่งแนวตั้งที่มีชุดข้อมูลแท่งแบบกลุ่ม $count ชุด ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'แผนภูมิแท่งแนวตั้งที่มีชุดข้อมูลแท่งแบบกลุ่ม $count ชุดและชุดข้อมูลเส้น $lines ชุด ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'แผนภูมิแท่งแนวตั้งที่มีแท่งแบบเรียงซ้อน $count แท่ง ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'แผนภูมิแท่งแนวตั้งที่มีแท่งแบบเรียงซ้อน $count แท่งและ $lines เส้น ';
  }

  @override
  String get presenceAvailable => 'พร้อมใช้งาน';

  @override
  String get presenceAway => 'ไม่อยู่';

  @override
  String get presenceBusy => 'ไม่ว่าง';

  @override
  String get presenceDoNotDisturb => 'ห้ามรบกวน';

  @override
  String get presenceBlocked => 'ถูกบล็อก';

  @override
  String get presenceOffline => 'ออฟไลน์';

  @override
  String get presenceOutOfOffice => 'ไม่อยู่ที่สำนักงาน';

  @override
  String get presenceUnknown => 'ไม่ทราบ';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status ไม่อยู่ที่สำนักงาน';
  }
}
