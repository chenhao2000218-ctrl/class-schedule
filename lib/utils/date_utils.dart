import '../models/app_settings.dart';

/// 日期工具类
class AppDateUtils {
  /// 获取某日期是学期第几周（从1开始）
  static int weekOfDate(DateTime date, DateTime semesterStart) {
    final diff = date.difference(semesterStart).inDays;
    if (diff < 0) return 0;
    return (diff ~/ 7) + 1;
  }

  /// 获取某周的周一日期
  static DateTime mondayOfWeek(int week, DateTime semesterStart) {
    return semesterStart.add(Duration(days: (week - 1) * 7));
  }

  /// 获取某日期所在周的周一
  static DateTime mondayOf(DateTime date) {
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday - 1));
  }

  /// 判断两个日期是否同一天
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 格式化日期为 yyyy-MM-dd
  static String formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  /// 格式化日期时间
  static String formatDateTime(DateTime dt) {
    return '${formatDate(dt)} ${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  /// 解析 "HH:mm" 为今天的 DateTime
  static DateTime parseTime(String timeStr, {DateTime? base}) {
    final parts = timeStr.split(':');
    final b = base ?? DateTime.now();
    return DateTime(b.year, b.month, b.day, int.parse(parts[0]), int.parse(parts[1]));
  }

  /// 获取当前学期周次
  static int currentWeek(AppSettings settings) {
    return weekOfDate(DateTime.now(), settings.semesterStart);
  }
}
