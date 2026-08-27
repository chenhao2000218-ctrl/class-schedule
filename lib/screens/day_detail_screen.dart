import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/course.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';
import 'course_edit_screen.dart';

/// 单日详情视图：展示某一天的所有课程
class DayDetailScreen extends StatefulWidget {
  final DateTime? date;
  const DayDetailScreen({super.key, this.date});

  @override
  State<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends State<DayDetailScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.date ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final courses = state.coursesForDate(_selectedDate);
    final timeSlots = state.settings.timeSlots;

    return Scaffold(
      appBar: AppBar(
        title: Text(DateUtils.formatDate(_selectedDate)),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 日期切换
          _buildDateSelector(),
          const Divider(height: 1),
          // 课程列表
          Expanded(
            child: courses.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_available, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('今天没有课程', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: courses.length,
                    itemBuilder: (ctx, i) => _buildCourseCard(courses[i], timeSlots),
                  ),
          ),
        ],
      ),
    );
  }

  /// 日期切换条
  Widget _buildDateSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() =>
                _selectedDate = _selectedDate.subtract(const Duration(days: 1))),
          ),
          Text(
            kWeekdays[_selectedDate.weekday - 1],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() =>
                _selectedDate = _selectedDate.add(const Duration(days: 1))),
          ),
        ],
      ),
    );
  }

  /// 课程卡片
  Widget _buildCourseCard(Course course, List timeSlots) {
    TimeSlot? startSlot;
    TimeSlot? endSlot;
    for (final s in timeSlots) {
      if (s.section == course.startSection) startSlot = s;
      if (s.section == course.endSection) endSlot = s;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CourseEditScreen(existingCourse: course),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 左侧时间
              SizedBox(
                width: 60,
                child: Column(
                  children: [
                    Text(
                      startSlot?.startTime ?? '',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const Text('|', style: TextStyle(color: Colors.grey)),
                    Text(
                      endSlot?.endTime ?? '',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // 颜色条
              Container(
                width: 4,
                height: 50,
                decoration: BoxDecoration(
                  color: kCourseColors[course.colorIndex % kCourseColors.length],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // 课程信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    if (course.teacher.isNotEmpty || course.classroom.isNotEmpty)
                      Text(
                        '${course.teacher}${course.teacher.isNotEmpty && course.classroom.isNotEmpty ? ' · ' : ''}${course.classroom}',
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    if (course.weekType.name != 'all')
                      Text(
                        course.weekType == WeekType.odd ? '单周' : '双周',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
