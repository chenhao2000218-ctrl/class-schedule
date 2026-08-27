import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:icalendar_parser/icalendar_parser.dart';
import '../models/course.dart';
import '../models/time_slot.dart';

/// ICS 课表导入服务
/// 支持：1) 粘贴教务系统 ICS 链接  2) 本地 ICS 文件内容
class IcsService {
  /// 从 URL 下载并解析 ICS
  Future<List<Course>> importFromUrl(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('下载失败：HTTP ${response.statusCode}');
    }
    return parseIcs(response.body);
  }

  /// 从 ICS 文本内容解析课程
  List<Course> parseIcs(String icsContent) {
    final calendar = ICalendar.fromString(icsContent);
    final courses = <Course>[];
    final seen = <String>{}; // 去重

    for (final event in calendar.data) {
      if (event.type != 'VEVENT') continue;

      final summary = (event.data['summary'] ?? '').toString();
      final description = (event.data['description'] ?? '').toString();
      final location = (event.data['location'] ?? '').toString();
      final dtstart = event.data['dtstart'];
      final rrule = event.data['rrule'];

      if (dtstart == null) continue;
      DateTime startDate;
      if (dtstart is DateTime) {
        startDate = dtstart;
      } else {
        try {
          startDate = DateTime.parse(dtstart.toString());
        } catch (_) {
          continue;
        }
      }

      final weekday = startDate.weekday; // 1-7

      // 尝试从 RRULE 解析周范围
      List<int> weeks = List.generate(20, (i) => i + 1);
      WeekType weekType = WeekType.all;
      if (rrule != null) {
        final rruleStr = rrule.toString();
        // 解析 INTERVAL（单双周）
        if (rruleStr.contains('INTERVAL=2')) {
          weekType = startDate.day % 2 == 1 ? WeekType.odd : WeekType.even;
        }
        // 解析 COUNT 或 UNTIL
        final countMatch = RegExp(r'COUNT=(\d+)').firstMatch(rruleStr);
        if (countMatch != null) {
          final count = int.parse(countMatch.group(1)!);
          weeks = List.generate(count, (i) => i + 1);
        }
      }

      // 解析节次：从时间推算（默认作息）
      final slots = defaultTimeSlots();
      int startSection = 1;
      int endSection = 1;
      final startTime =
          '${startDate.hour.toString().padLeft(2, '0')}:${startDate.minute.toString().padLeft(2, '0')}';

      for (var i = 0; i < slots.length; i++) {
        if (slots[i].startTime == startTime) {
          startSection = slots[i].section;
          // 估算结束节次
          final dtend = event.data['dtend'];
          if (dtend != null) {
            DateTime endDate;
            if (dtend is DateTime) {
              endDate = dtend;
            } else {
              endDate = DateTime.parse(dtend.toString());
            }
            final endTime =
                '${endDate.hour.toString().padLeft(2, '0')}:${endDate.minute.toString().padLeft(2, '0')}';
            for (var j = i; j < slots.length; j++) {
              if (slots[j].endTime == endTime) {
                endSection = slots[j].section;
                break;
              }
            }
            if (endSection < startSection) endSection = startSection;
          }
          break;
        }
      }

      // 从描述中提取老师
      String teacher = '';
      final teacherMatch =
          RegExp(r'(?:教师|老师|授课教师)[：:\s]*([^\n\r,，]+)').firstMatch(description);
      if (teacherMatch != null) {
        teacher = teacherMatch.group(1)!.trim();
      }

      // 去重 key
      final key = '$summary-$weekday-$startSection-$startSection';
      if (seen.contains(key)) continue;
      seen.add(key);

      courses.add(Course(
        name: summary,
        teacher: teacher,
        classroom: location,
        weekday: weekday,
        startSection: startSection,
        endSection: endSection,
        weeks: weeks,
        weekType: weekType,
        remark: description.isNotEmpty ? description : '',
      ));
    }

    return courses;
  }
}
