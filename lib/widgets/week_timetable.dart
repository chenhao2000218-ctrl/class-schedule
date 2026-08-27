import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/course.dart';
import '../models/holiday.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';
import '../utils/theme.dart';

/// 周课表视图组件（iOS 风格）
class WeekTimetable extends StatelessWidget {
  final int currentWeek;
  final void Function(Course)? onCourseTap;

  const WeekTimetable({
    super.key,
    required this.currentWeek,
    this.onCourseTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final settings = state.settings;
        final timeSlots = settings.timeSlots;
        final showWeekend = settings.showWeekend;
        final days = showWeekend ? 7 : 5;

        // 计算每节课的高度
        const headerHeight = 36.0;
        const timeColumnWidth = 48.0;
        final slotHeight = 56.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            children: [
              // 星期表头
              SizedBox(
                height: headerHeight,
                child: Row(
                  children: [
                    const SizedBox(width: timeColumnWidth),
                    ...List.generate(days, (i) {
                      final weekday = i + 1;
                      final isToday =
                          DateTime.now().weekday == weekday;
                      return Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                kWeekdays[weekday - 1],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isToday
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isToday
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey,
                                ),
                              ),
                              if (isToday)
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              // 课表主体
              ...List.generate(timeSlots.length, (slotIndex) {
                final slot = timeSlots[slotIndex];
                return SizedBox(
                  height: slotHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 时间列
                      SizedBox(
                        width: timeColumnWidth,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${slot.section}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              slot.startTime.substring(0, 5),
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 每天的课程
                      ...List.generate(days, (dayIndex) {
                        final weekday = dayIndex + 1;
                        // 查找该节次的课程
                        final course = state.courses.firstWhere(
                          (c) =>
                              c.weekday == weekday &&
                              c.startSection <= slot.section &&
                              c.endSection >= slot.section,
                          orElse: () => Course(
                            name: '',
                            teacher: '',
                            classroom: '',
                            weekday: weekday,
                            startSection: slot.section,
                            endSection: slot.section,
                          ),
                        );

                        // 只在课程的起始节次渲染课程块
                        if (course.name.isNotEmpty &&
                            course.startSection != slot.section) {
                          return Expanded(child: Container());
                        }

                        if (course.name.isEmpty) {
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        }

                        // 检查是否在当前周
                        final inWeek = course.weeks.contains(currentWeek);
                        final weekMatch = course.weekType == WeekType.all ||
                            (course.weekType == WeekType.odd &&
                                currentWeek % 2 == 1) ||
                            (course.weekType == WeekType.even &&
                                currentWeek % 2 == 0);

                        if (!inWeek || !weekMatch) {
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        }

                        // 计算课程块跨越的节次
                        final span = course.endSection - course.startSection + 1;
                        final gradient = kCourseGradients[
                            course.colorIndex % kCourseGradients.length];

                        return Expanded(
                          child: GestureDetector(
                            onTap: () => onCourseTap?.call(course),
                            child: AnimatedScale(
                              scale: 1.0,
                              duration: const Duration(milliseconds: 100),
                              curve: Curves.easeOut,
                              child: Container(
                                margin: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      gradient[0].withOpacity(0.9),
                                      gradient[1].withOpacity(0.95),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: gradient[1].withOpacity(0.25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(6),
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
                                      maxLines: span > 1 ? 3 : 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (span > 1) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        course.classroom,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color:
                                              Colors.white.withOpacity(0.85),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (course.teacher.isNotEmpty)
                                        Text(
                                          course.teacher,
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.white
                                                .withOpacity(0.7),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
