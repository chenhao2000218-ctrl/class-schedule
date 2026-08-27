import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/course.dart';
import '../models/time_slot.dart';
import '../models/app_settings.dart';
import '../utils/date_utils.dart';

/// 桌面小组件数据服务
/// 通过 App Group 共享目录将今日课程数据写入 JSON，供 iOS WidgetKit 读取
class WidgetService {
  // iOS App Group ID，需与 Xcode 中配置一致
  static const String appGroupId = 'group.com.example.classschedule';

  /// 更新小组件数据：写入今日课程列表到共享目录
  Future<void> updateWidgetData(
    List<Course> courses,
    List<TimeSlot> timeSlots,
    AppSettings settings,
  ) async {
    final now = DateTime.now();
    final currentWeek = DateUtils.currentWeek(settings);

    // 获取今日课程（考虑假期和调休）
    final todayCourses = courses
        .where((c) =>
            c.weekday == now.weekday && c.hasClassOnWeek(currentWeek))
        .toList()
      ..sort((a, b) => a.startSection.compareTo(b.startSection));

    // 转换为小组件可用的精简数据
    final widgetData = {
      'date': DateUtils.formatDate(now),
      'week': currentWeek,
      'courses': todayCourses.map((c) {
        final slot = timeSlots.firstWhere(
          (s) => s.section == c.startSection,
          orElse: () =>
              TimeSlot(section: 1, startTime: '08:00', endTime: '08:45'),
        );
        return {
          'name': c.name,
          'teacher': c.teacher,
          'classroom': c.classroom,
          'startTime': slot.startTime,
          'endTime': timeSlots
                  .firstWhere(
                    (s) => s.section == c.endSection,
                    orElse: () => slot,
                  )
                  .endTime,
          'color': c.colorIndex,
        };
      }).toList(),
    };

    try {
      final directory = await getApplicationSupportDirectory();
      // iOS: 通过 App Group 共享
      // 实际路径由原生层决定，这里写入应用沙盒，原生层通过 App Group 桥接
      final file = File('${directory.path}/widget_data.json');
      await file.writeAsString(jsonEncode(widgetData));
    } catch (_) {
      // 小组件数据更新失败不影响主应用
    }
  }
}
