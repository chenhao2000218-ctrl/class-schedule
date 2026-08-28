import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/course.dart';
import '../models/holiday.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';
import '../utils/theme.dart';

/// 周课表视图组件（支持双指缩放）
class WeekTimetable extends StatefulWidget {
  final int currentWeek;
  final void Function(Course)? onCourseTap;

  const WeekTimetable({
    super.key,
    required this.currentWeek,
    this.onCourseTap,
  });

  @override
  State<WeekTimetable> createState() => _WeekTimetableState();
}

class _WeekTimetableState extends State<WeekTimetable> {
  final TransformationController _transformController =
      TransformationController();
  double _currentScale = 1.0;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final settings = state.settings;
        final timeSlots = settings.timeSlots;
        final showWeekend = settings.showWeekend;
        final days = showWeekend ? 7 : 5;

        const headerHeight = 36.0;
        const timeColumnWidth = 48.0;
        final slotHeight = 56.0 * _currentScale;

        final contentWidth =
            MediaQuery.of(context).size.width - 32 - timeColumnWidth;
        final totalHeight =
            headerHeight + timeSlots.length * slotHeight + 16;

        return InteractiveViewer(
          transformationController: _transformController,
          minScale: 0.8,
          maxScale: 2.0,
          panEnabled: true,
          scaleEnabled: true,
          onInteractionEnd: (details) {
            setState(() {
              _currentScale = _transformController.value.getMaxScaleOnAxis();
              if (_currentScale < 0.8) _currentScale = 0.8;
              if (_currentScale > 2.0) _currentScale = 2.0;
            });
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: SizedBox(
              width: contentWidth + timeColumnWidth,
              height: totalHeight,
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

                            final inWeek =
                                course.weeks.contains(widget.currentWeek);
                            final weekMatch =
                                course.weekType == WeekType.all ||
                                    (course.weekType == WeekType.odd &&
                                        widget.currentWeek % 2 == 1) ||
                                    (course.weekType == WeekType.even &&
                                        widget.currentWeek % 2 == 0);

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

                            final span = course.endSection -
                                course.startSection +
                                1;
                            final gradient = kCourseGradients[
                                course.colorIndex %
                                    kCourseGradients.length];

                            return Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    widget.onCourseTap?.call(course),
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
                                        color: gradient[1]
                                            .withOpacity(0.25),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        course.name,
                                        style: TextStyle(
                                          fontSize:
                                              11 * _currentScale.clamp(0.8, 1.2),
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
                                            fontSize: 10 *
                                                _currentScale.clamp(0.8, 1.2),
                                            color: Colors.white
                                                .withOpacity(0.85),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (course.teacher.isNotEmpty)
                                          Text(
                                            course.teacher,
                                            style: TextStyle(
                                              fontSize: 9 *
                                                  _currentScale
                                                      .clamp(0.8, 1.2),
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
                            );
                          }),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
