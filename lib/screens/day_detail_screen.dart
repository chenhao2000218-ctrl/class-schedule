import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/course.dart';
import '../models/time_slot.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';
import '../utils/theme.dart';
import 'course_edit_screen.dart';

/// 单日详情视图：iOS 分组列表风格
class DayDetailScreen extends StatelessWidget {
  final DateTime date;

  const DayDetailScreen({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final weekday = date.weekday;
        final courses = state.courses
            .where((c) => c.weekday == weekday)
            .toList()
          ..sort((a, b) => a.startSection.compareTo(b.startSection));

        final isToday = AppDateUtils.isSameDay(date, DateTime.now());

        return Scaffold(
          appBar: AppBar(
            title: Text(
                '${kWeekdays[weekday - 1]} ${isToday ? '(今天)' : ''}'),
          ),
          body: courses.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    return _buildCourseCard(context, course, state);
                  },
                ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today,
              size: 64, color: Colors.grey.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text('这一天没有课程',
              style: TextStyle(fontSize: 17, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCourseCard(
      BuildContext context, Course course, AppState state) {
    final gradient =
        kCourseGradients[course.colorIndex % kCourseGradients.length];
    final slots = state.settings.timeSlots;
    final startSlot = slots.firstWhere(
      (s) => s.section == course.startSection,
      orElse: () => TimeSlot(section: course.startSection, startTime: '08:00', endTime: '08:45'),
    );
    final endSlot = slots.firstWhere(
      (s) => s.section == course.endSection,
      orElse: () => TimeSlot(section: course.endSection, startTime: '08:00', endTime: '08:45'),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CourseEditScreen(course: course),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 左侧色条
                Container(
                  width: 4,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 14),
                // 课程信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${startSlot.startTime} - ${endSlot.endTime} · 第${course.startSection}-${course.endSection}节',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (course.classroom.isNotEmpty ||
                          course.teacher.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              if (course.classroom.isNotEmpty)
                                Icon(Icons.location_on,
                                    size: 13, color: Colors.grey[500]),
                              if (course.classroom.isNotEmpty)
                                const SizedBox(width: 3),
                              if (course.classroom.isNotEmpty)
                                Text(course.classroom,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600])),
                              if (course.classroom.isNotEmpty &&
                                  course.teacher.isNotEmpty)
                                const SizedBox(width: 12),
                              if (course.teacher.isNotEmpty)
                                Icon(Icons.person,
                                    size: 13, color: Colors.grey[500]),
                              if (course.teacher.isNotEmpty)
                                const SizedBox(width: 3),
                              if (course.teacher.isNotEmpty)
                                Text(course.teacher,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600])),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
