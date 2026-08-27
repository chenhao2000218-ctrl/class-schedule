import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/course.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';

/// 周课表视图组件
class WeekTimetable extends StatelessWidget {
  final int currentWeek;
  final VoidCallback? onCourseTap;
  final Function(Course)? onCourseLongPress;

  const WeekTimetable({
    super.key,
    required this.currentWeek,
    this.onCourseTap,
    this.onCourseLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final settings = state.settings;
    final timeSlots = settings.timeSlots;
    final showWeekend = settings.showWeekend;
    final dayCount = showWeekend ? 7 : 5;

    // 计算本周日期
    final now = DateTime.now();
    final monday = DateUtils.mondayOf(now);

    return Column(
      children: [
        // 星期表头
        _buildHeader(context, monday, dayCount),
        // 课表主体
        Expanded(
          child: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左侧节次时间列
                _buildTimeColumn(timeSlots),
                // 右侧课程网格
                Expanded(
                  child: _buildCourseGrid(
                    context,
                    state,
                    monday,
                    dayCount,
                    timeSlots.length,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 星期表头
  Widget _buildHeader(BuildContext context, DateTime monday, int dayCount) {
    final today = DateTime.now();
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // 左侧占位（对齐时间列）
          const SizedBox(width: 48),
          ...List.generate(dayCount, (i) {
            final date = monday.add(Duration(days: i));
            final isToday = DateUtils.isSameDay(date, today);
            return Expanded(
              child: Column(
                children: [
                  Text(
                    kWeekdaysShort[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isToday
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isToday
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 左侧节次时间列
  Widget _buildTimeColumn(List timeSlots) {
    return SizedBox(
      width: 48,
      child: Column(
        children: timeSlots.map<Widget>((slot) {
          return Container(
            height: 64,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${slot.section}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  slot.startTime,
                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 课程网格
  Widget _buildCourseGrid(
    BuildContext context,
    AppState state,
    DateTime monday,
    int dayCount,
    int maxSections,
  ) {
    final settings = state.settings;
    final week = currentWeek;

    return Column(
      children: List.generate(maxSections, (sectionIdx) {
        final section = sectionIdx + 1;
        return SizedBox(
          height: 64,
          child: Row(
            children: List.generate(dayCount, (dayIdx) {
              final weekday = dayIdx + 1;
              final date = monday.add(Duration(days: dayIdx));

              // 检查假期
              final isHoliday = state.holidays.any((h) =>
                  h.isHoliday && DateUtils.isSameDay(h.date, date));

              // 检查调休
              Holiday? adjust;
              for (final h in state.holidays) {
                if (h.isAdjust && DateUtils.isSameDay(h.date, date)) {
                  adjust = h;
                  break;
                }
              }
              final effectiveWeekday =
                  adjust != null && adjust.weekdayOverride != null
                      ? adjust.weekdayOverride!
                      : weekday;

              // 查找从本节开始的课程
              final course = state.courses.firstWhere(
                (c) =>
                    c.weekday == effectiveWeekday &&
                    c.startSection == section &&
                    c.hasClassOnWeek(week),
                orElse: () => Course(
                  name: '',
                  weekday: 0,
                  startSection: 0,
                  endSection: 0,
                ),
              );

              // 如果是某课程的中间节次，返回空（已被上面的课程块覆盖）
              final isPartOfBigger = state.courses.any((c) =>
                  c.weekday == effectiveWeekday &&
                  c.startSection < section &&
                  c.endSection >= section &&
                  c.hasClassOnWeek(week));

              if (isHoliday) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Center(
                      child: Text('休',
                          style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ),
                  ),
                );
              }

              if (course.name.isEmpty || isPartOfBigger) {
                return Expanded(child: Container());
              }

              final span = course.endSection - course.startSection + 1;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onCourseTap?.call(),
                  onLongPress: () => onCourseLongPress?.call(course),
                  child: Container(
                    height: 64.0 * span,
                    margin: const EdgeInsets.all(1),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: kCourseColors[
                              course.colorIndex % kCourseColors.length]
                          .withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.name,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: span >= 2 ? 3 : 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (span >= 2) ...[
                          const SizedBox(height: 2),
                          if (course.classroom.isNotEmpty)
                            Text(
                              course.classroom,
                              style: const TextStyle(
                                  fontSize: 9, color: Colors.white70),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (course.teacher.isNotEmpty)
                            Text(
                              course.teacher,
                              style: const TextStyle(
                                  fontSize: 9, color: Colors.white70),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}
