import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/course.dart';
import '../models/time_slot.dart';
import '../models/app_settings.dart';

/// 桌面小组件数据共享服务
/// 通过 App Group 将课表数据写入 UserDefaults，供 iOS Widget 读取
class WidgetService {
  static const MethodChannel _channel =
      MethodChannel('com.example.classSchedule/widget');

  static const String _appGroup = 'group.com.example.classSchedule';

  /// 更新小组件数据
  /// 在课表数据变化时调用
  Future<void> updateWidgetData(
    List<Course> courses,
    List<TimeSlot> timeSlots,
    AppSettings settings, {
    int currentWeek = 1,
  }) async {
    try {
      final data = {
        'courses': courses
            .map((c) => {
                  'name': c.name,
                  'teacher': c.teacher,
                  'classroom': c.classroom,
                  'weekday': c.weekday,
                  'startSection': c.startSection,
                  'endSection': c.endSection,
                  'colorIndex': c.colorIndex,
                })
            .toList(),
        'currentWeek': currentWeek,
        'totalWeeks': settings.totalWeeks,
        'semesterStart': settings.semesterStart.toIso8601String(),
        'showWeekend': settings.showWeekend,
        'timeSlots': timeSlots
            .map((t) => {
                  'section': t.section,
                  'startTime': t.startTime,
                  'endTime': t.endTime,
                })
            .toList(),
      };

      final jsonStr = jsonEncode(data);
      await _channel.invokeMethod('updateWidgetData', {
        'appGroup': _appGroup,
        'key': 'widget_data',
        'value': jsonStr,
      });

      // 立即刷新小组件
      await _channel.invokeMethod('reloadWidgets', {'kind': 'ScheduleWidget'});
    } catch (_) {
      // 静默失败，不影响主应用
    }
  }
}
