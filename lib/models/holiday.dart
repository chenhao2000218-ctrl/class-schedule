import 'course.dart';

/// 假期与调休
/// type=holiday: 假期，该日期自动隐藏课程
/// type=adjust: 调休日，该日期按 weekdayOverride 的星期来显示课程
class Holiday {
  String id;
  DateTime date; // 日期
  HolidayType type;
  String name; // 名称（如"国庆节"、"调休上周三课"）
  int? weekdayOverride; // 调休时替代的星期 1-7

  Holiday({
    String? id,
    required this.date,
    required this.type,
    this.name = '',
    this.weekdayOverride,
  }) : id = id ?? uuid();

  bool get isHoliday => type == HolidayType.holiday;
  bool get isAdjust => type == HolidayType.adjust;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'type': type.index,
        'name': name,
        'weekdayOverride': weekdayOverride,
      };

  factory Holiday.fromJson(Map<String, dynamic> json) => Holiday(
        id: json['id'],
        date: DateTime.parse(json['date']),
        type: HolidayType.values[json['type'] ?? 0],
        name: json['name'] ?? '',
        weekdayOverride: json['weekdayOverride'],
      );
}

enum HolidayType { holiday, adjust }
