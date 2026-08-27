import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/course.dart';
import '../models/time_slot.dart';
import '../models/exam.dart';

/// 本地通知服务：上课提醒、考试提醒
class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _notifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    _initialized = true;
  }

  /// 为课程安排下周提醒（仅安排未来7天，避免通知过多）
  Future<void> scheduleCourseReminders(
    List<Course> courses,
    List<TimeSlot> timeSlots,
    DateTime semesterStart,
  ) async {
    await _notifications.cancelAll();

    final now = DateTime.now();
    for (final course in courses) {
      if (course.remindMinutes <= 0) continue;

      // 找到对应节次的时间
      final slot = timeSlots.firstWhere(
        (s) => s.section == course.startSection,
        orElse: () => TimeSlot(section: 1, startTime: '08:00', endTime: '08:45'),
      );
      final startParts = slot.startTime.split(':');
      final hour = int.parse(startParts[0]);
      final minute = int.parse(startParts[1]);

      // 安排未来14天内的提醒
      for (int dayOffset = 0; dayOffset < 14; dayOffset++) {
        final date = now.add(Duration(days: dayOffset));
        if (date.weekday != course.weekday) continue;

        final week = _weekOfDate(date, semesterStart);
        if (!course.hasClassOnWeek(week)) continue;

        final classTime =
            DateTime(date.year, date.month, date.day, hour, minute);
        final remindTime =
            classTime.subtract(Duration(minutes: course.remindMinutes));
        if (remindTime.isBefore(now)) continue;

        final tzTime = tz.TZDateTime.from(remindTime, tz.local);
        final id = _hashCode('${course.id}_$dayOffset');

        await _notifications.zonedSchedule(
          id,
          '即将上课：${course.name}',
          '${course.teacher.isNotEmpty ? course.teacher + ' · ' : ''}'
              '${course.classroom.isNotEmpty ? course.classroom : ''}'
              ' · ${slot.startTime} 上课',
          tzTime,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'course_reminder',
              '上课提醒',
              channelDescription: '课程开始前提醒',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  /// 安排考试提醒
  Future<void> scheduleExamReminders(List<Exam> exams) async {
    final now = DateTime.now();
    for (final exam in exams) {
      if (!exam.remind) continue;
      final remindTime = exam.dateTime.subtract(const Duration(hours: 2));
      if (remindTime.isBefore(now)) continue;

      final tzTime = tz.TZDateTime.from(remindTime, tz.local);
      final id = _hashCode('exam_${exam.id}');

      await _notifications.zonedSchedule(
        id,
        '考试提醒：${exam.courseName}',
        '${exam.examName} · ${exam.location} · '
            '${exam.dateTime.month}/${exam.dateTime.day} '
            '${exam.dateTime.hour.toString().padLeft(2, '0')}:'
            '${exam.dateTime.minute.toString().padLeft(2, '0')}',
        tzTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'exam_reminder',
            '考试提醒',
            channelDescription: '考试开始前提醒',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  /// 取消所有通知
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  int _weekOfDate(DateTime date, DateTime semesterStart) {
    final diff = date.difference(semesterStart).inDays;
    if (diff < 0) return 0;
    return (diff ~/ 7) + 1;
  }

  int _hashCode(String s) {
    int hash = 0;
    for (final c in s.codeUnits) {
      hash = (hash * 31 + c) & 0x7fffffff;
    }
    return hash;
  }
}
