/// 课程数据模型
class Course {
  String id;
  String name; // 课程名称
  String teacher; // 授课老师
  String classroom; // 教室
  int weekday; // 星期几 1-7（周一到周日）
  int startSection; // 开始节次（从1开始）
  int endSection; // 结束节次
  List<int> weeks; // 上课周范围，如 [1,2,3,...,16]
  WeekType weekType; // 单周/双周/全部
  String remark; // 备注
  int colorIndex; // 主题色索引
  int remindMinutes; // 提前提醒分钟数，0表示不提醒

  Course({
    String? id,
    required this.name,
    this.teacher = '',
    this.classroom = '',
    required this.weekday,
    required this.startSection,
    required this.endSection,
    List<int>? weeks,
    this.weekType = WeekType.all,
    this.remark = '',
    this.colorIndex = 0,
    this.remindMinutes = 0,
  })  : id = id ?? uuid(),
        weeks = weeks ?? List.generate(20, (i) => i + 1);

  /// 判断某周是否上课
  bool hasClassOnWeek(int week) {
    if (!weeks.contains(week)) return false;
    switch (weekType) {
      case WeekType.all:
        return true;
      case WeekType.odd:
        return week % 2 == 1;
      case WeekType.even:
        return week % 2 == 0;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'teacher': teacher,
        'classroom': classroom,
        'weekday': weekday,
        'startSection': startSection,
        'endSection': endSection,
        'weeks': weeks,
        'weekType': weekType.index,
        'remark': remark,
        'colorIndex': colorIndex,
        'remindMinutes': remindMinutes,
      };

  factory Course.fromJson(Map<String, dynamic> json) => Course(
        id: json['id'],
        name: json['name'],
        teacher: json['teacher'] ?? '',
        classroom: json['classroom'] ?? '',
        weekday: json['weekday'],
        startSection: json['startSection'],
        endSection: json['endSection'],
        weeks: List<int>.from(json['weeks'] ?? []),
        weekType: WeekType.values[json['weekType'] ?? 0],
        remark: json['remark'] ?? '',
        colorIndex: json['colorIndex'] ?? 0,
        remindMinutes: json['remindMinutes'] ?? 0,
      );

  Course copyWith({
    String? name,
    String? teacher,
    String? classroom,
    int? weekday,
    int? startSection,
    int? endSection,
    List<int>? weeks,
    WeekType? weekType,
    String? remark,
    int? colorIndex,
    int? remindMinutes,
  }) =>
      Course(
        id: id,
        name: name ?? this.name,
        teacher: teacher ?? this.teacher,
        classroom: classroom ?? this.classroom,
        weekday: weekday ?? this.weekday,
        startSection: startSection ?? this.startSection,
        endSection: endSection ?? this.endSection,
        weeks: weeks ?? this.weeks,
        weekType: weekType ?? this.weekType,
        remark: remark ?? this.remark,
        colorIndex: colorIndex ?? this.colorIndex,
        remindMinutes: remindMinutes ?? this.remindMinutes,
      );
}

enum WeekType { all, odd, even }

/// 简易 UUID 生成（避免额外依赖）
String uuid() {
  final now = DateTime.now().microsecondsSinceEpoch;
  return '${now.toRadixString(16)}_${now % 10000}';
}
