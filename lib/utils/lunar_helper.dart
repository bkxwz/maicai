import 'package:lunar/lunar.dart';

class LunarHelper {
  /// 获取农历日期字符串，如"农历二月初一"
  static String getLunarDate(DateTime dateTime) {
    final solar = Solar.fromDate(dateTime);
    final lunar = solar.getLunar();
    return '农历${lunar.getMonthInChinese()}月${lunar.getDayInChinese()}';
  }
  
  /// 获取完整日期显示，如"2026年3月27日 农历二月初一"
  static String getFullDateString(DateTime dateTime) {
    final lunarDate = getLunarDate(dateTime);
    return '${dateTime.year}年${dateTime.month}月${dateTime.day}日 $lunarDate';
  }
  
  /// 获取农历月
  static String getLunarMonth(DateTime dateTime) {
    final solar = Solar.fromDate(dateTime);
    final lunar = solar.getLunar();
    return lunar.getMonthInChinese();
  }
  
  /// 获取农历日
  static String getLunarDay(DateTime dateTime) {
    final solar = Solar.fromDate(dateTime);
    final lunar = solar.getLunar();
    return lunar.getDayInChinese();
  }
}
