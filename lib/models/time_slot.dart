/// 作息时间配置：每节课的开始和结束时间
class TimeSlot {
  int section; // 节次，从1开始
  String startTime; // "HH:mm"
  String endTime; // "HH:mm"

  TimeSlot({required this.section, required this.startTime, required this.endTime});

  Map<String, dynamic> toJson() => {
        'section': section,
        'startTime': startTime,
        'endTime': endTime,
      };

  factory TimeSlot.fromJson(Map<String, dynamic> json) => TimeSlot(
        section: json['section'],
        startTime: json['startTime'],
        endTime: json['endTime'],
      );

  TimeSlot copyWith({int? section, String? startTime, String? endTime}) =>
      TimeSlot(
        section: section ?? this.section,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
      );
}

/// 默认作息时间（大学常见作息）
List<TimeSlot> defaultTimeSlots() => [
      TimeSlot(section: 1, startTime: '08:00', endTime: '08:45'),
      TimeSlot(section: 2, startTime: '08:55', endTime: '09:40'),
      TimeSlot(section: 3, startTime: '10:00', endTime: '10:45'),
      TimeSlot(section: 4, startTime: '10:55', endTime: '11:40'),
      TimeSlot(section: 5, startTime: '14:00', endTime: '14:45'),
      TimeSlot(section: 6, startTime: '14:55', endTime: '15:40'),
      TimeSlot(section: 7, startTime: '16:00', endTime: '16:45'),
      TimeSlot(section: 8, startTime: '16:55', endTime: '17:40'),
      TimeSlot(section: 9, startTime: '19:00', endTime: '19:45'),
      TimeSlot(section: 10, startTime: '19:55', endTime: '20:40'),
    ];
