import 'time_slot.dart';

/// 应用全局设置
class AppSettings {
  DateTime semesterStart; // 学期开始日期（第1周周一）
  int totalWeeks; // 总周数
  int colorSeed; // 主题色种子（0-15）
  ThemeMode themeMode; // 主题模式
  int defaultRemindMinutes; // 默认提前提醒分钟数
  bool showWeekend; // 是否显示周末
  List<TimeSlot> timeSlots; // 作息时间

  AppSettings({
    DateTime? semesterStart,
    this.totalWeeks = 20,
    this.colorSeed = 0,
    this.themeMode = ThemeMode.system,
    this.defaultRemindMinutes = 10,
    this.showWeekend = true,
    List<TimeSlot>? timeSlots,
  })  : semesterStart = semesterStart ?? _defaultSemesterStart(),
        timeSlots = timeSlots ?? defaultTimeSlots();

  /// 默认学期开始：本周一
  static DateTime _defaultSemesterStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
  }

  Map<String, dynamic> toJson() => {
        'semesterStart': semesterStart.toIso8601String(),
        'totalWeeks': totalWeeks,
        'colorSeed': colorSeed,
        'themeMode': themeMode.index,
        'defaultRemindMinutes': defaultRemindMinutes,
        'showWeekend': showWeekend,
        'timeSlots': timeSlots.map((e) => e.toJson()).toList(),
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        semesterStart: json['semesterStart'] != null
            ? DateTime.parse(json['semesterStart'])
            : null,
        totalWeeks: json['totalWeeks'] ?? 20,
        colorSeed: json['colorSeed'] ?? 0,
        themeMode: ThemeMode.values[json['themeMode'] ?? 0],
        defaultRemindMinutes: json['defaultRemindMinutes'] ?? 10,
        showWeekend: json['showWeekend'] ?? true,
        timeSlots: json['timeSlots'] != null
            ? (json['timeSlots'] as List)
                .map((e) => TimeSlot.fromJson(e))
                .toList()
            : null,
      );
}

enum ThemeMode { system, light, dark }
