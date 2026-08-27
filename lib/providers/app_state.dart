import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/exam.dart';
import '../models/homework.dart';
import '../models/holiday.dart';
import '../models/time_slot.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';

/// 全局应用状态
class AppState extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final NotificationService _notifications = NotificationService();
  final WidgetService _widgetService = WidgetService();

  List<Course> _courses = [];
  List<Exam> _exams = [];
  List<Homework> _homeworks = [];
  List<Holiday> _holidays = [];
  AppSettings _settings = AppSettings();
  bool _loaded = false;
  int _currentWeek = 1;

  List<Course> get courses => List.unmodifiable(_courses);
  List<Exam> get exams => List.unmodifiable(_exams);
  List<Homework> get homeworks => List.unmodifiable(_homeworks);
  List<Holiday> get holidays => List.unmodifiable(_holidays);
  AppSettings get settings => _settings;
  bool get loaded => _loaded;
  int get currentWeek => _currentWeek;

  /// 初始化：加载本地数据 + 初始化通知
  Future<void> init() async {
    await _storage.init();
    await _notifications.init();
    _courses = _storage.loadCourses();
    _exams = _storage.loadExams();
    _homeworks = _storage.loadHomeworks();
    _holidays = _storage.loadHolidays();
    _settings = _storage.loadSettings();
    _loaded = true;
    _currentWeek = _weekOfDate(DateTime.now());
    if (_currentWeek < 1) _currentWeek = 1;
    if (_currentWeek > _settings.totalWeeks) _currentWeek = _settings.totalWeeks;
    notifyListeners();
    await _refreshRemindersAndWidget();
  }

  // ===== 课程操作 =====
  Future<void> addCourse(Course course) async {
    _courses.add(course);
    await _persistCourses();
  }

  Future<void> updateCourse(Course course) async {
    final idx = _courses.indexWhere((c) => c.id == course.id);
    if (idx >= 0) {
      _courses[idx] = course;
      await _persistCourses();
    }
  }

  Future<void> deleteCourse(String id) async {
    _courses.removeWhere((c) => c.id == id);
    // 同时删除关联作业
    _homeworks.removeWhere((h) => h.courseId == id);
    await _persistCourses();
    await _storage.saveHomeworks(_homeworks);
  }

  /// 批量导入课程（ICS）
  Future<int> importCourses(List<Course> newCourses) async {
    int count = 0;
    for (final c in newCourses) {
      // 简单去重
      final exists = _courses.any((e) =>
          e.name == c.name &&
          e.weekday == c.weekday &&
          e.startSection == c.startSection);
      if (!exists) {
        _courses.add(c);
        count++;
      }
    }
    await _persistCourses();
    return count;
  }

  /// 获取某天的课程（考虑假期/调休）
  List<Course> coursesForDate(DateTime date) {
    // 检查是否假期
    final isHoliday = _holidays.any(
      (h) => _isSameDay(h.date, date) && h.isHoliday,
    );
    if (isHoliday) return [];

    // 检查调休
    Holiday? adjust;
    for (final h in _holidays) {
      if (_isSameDay(h.date, date) && h.isAdjust) {
        adjust = h;
        break;
      }
    }
    final effectiveWeekday =
        adjust != null && adjust.weekdayOverride != null
            ? adjust.weekdayOverride!
            : date.weekday;

    final week = _weekOfDate(date);
    return _courses
        .where((c) =>
            c.weekday == effectiveWeekday && c.hasClassOnWeek(week))
        .toList()
      ..sort((a, b) => a.startSection.compareTo(b.startSection));
  }

  // ===== 考试操作 =====
  Future<void> addExam(Exam exam) async {
    _exams.add(exam);
    await _storage.saveExams(_exams);
    await _refreshRemindersAndWidget();
    notifyListeners();
  }

  Future<void> updateExam(Exam exam) async {
    final idx = _exams.indexWhere((e) => e.id == exam.id);
    if (idx >= 0) {
      _exams[idx] = exam;
      await _storage.saveExams(_exams);
      notifyListeners();
    }
  }

  Future<void> deleteExam(String id) async {
    _exams.removeWhere((e) => e.id == id);
    await _storage.saveExams(_exams);
    notifyListeners();
  }

  // ===== 作业操作 =====
  List<Homework> homeworksForCourse(String courseId) =>
      _homeworks.where((h) => h.courseId == courseId).toList();

  Future<void> addHomework(Homework hw) async {
    _homeworks.add(hw);
    await _storage.saveHomeworks(_homeworks);
    notifyListeners();
  }

  Future<void> toggleHomework(String id) async {
    final idx = _homeworks.indexWhere((h) => h.id == id);
    if (idx >= 0) {
      _homeworks[idx].completed = !_homeworks[idx].completed;
      await _storage.saveHomeworks(_homeworks);
      notifyListeners();
    }
  }

  Future<void> deleteHomework(String id) async {
    _homeworks.removeWhere((h) => h.id == id);
    await _storage.saveHomeworks(_homeworks);
    notifyListeners();
  }

  // ===== 假期调休操作 =====
  Future<void> addHoliday(Holiday holiday) async {
    _holidays.add(holiday);
    await _storage.saveHolidays(_holidays);
    notifyListeners();
  }

  Future<void> deleteHoliday(String id) async {
    _holidays.removeWhere((h) => h.id == id);
    await _storage.saveHolidays(_holidays);
    notifyListeners();
  }

  // ===== 设置操作 =====
  Future<void> updateSettings(AppSettings settings) async {
    _settings = settings;
    await _storage.saveSettings(_settings);
    await _refreshRemindersAndWidget();
    notifyListeners();
  }

  Future<void> updateTheme(AppThemeMode mode, int colorSeed) async {
    _settings = AppSettings(
      semesterStart: _settings.semesterStart,
      totalWeeks: _settings.totalWeeks,
      colorSeed: colorSeed,
      themeMode: mode,
      defaultRemindMinutes: _settings.defaultRemindMinutes,
      showWeekend: _settings.showWeekend,
      timeSlots: _settings.timeSlots,
    );
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> updateTimeSlots(List<TimeSlot> slots) async {
    _settings = AppSettings(
      semesterStart: _settings.semesterStart,
      totalWeeks: _settings.totalWeeks,
      colorSeed: _settings.colorSeed,
      themeMode: _settings.themeMode,
      defaultRemindMinutes: _settings.defaultRemindMinutes,
      showWeekend: _settings.showWeekend,
      timeSlots: slots,
    );
    await _storage.saveSettings(_settings);
    await _refreshRemindersAndWidget();
    notifyListeners();
  }

  // ===== 内部方法 =====
  Future<void> _persistCourses() async {
    await _storage.saveCourses(_courses);
    await _refreshRemindersAndWidget();
    notifyListeners();
  }

  Future<void> _refreshRemindersAndWidget() async {
    await _notifications.scheduleCourseReminders(
      _courses,
      _settings.timeSlots,
      _settings.semesterStart,
    );
    await _notifications.scheduleExamReminders(_exams);
    await _widgetService.updateWidgetData(
      _courses,
      _settings.timeSlots,
      _settings,
    );
  }

  int _weekOfDate(DateTime date) {
    final diff = date.difference(_settings.semesterStart).inDays;
    if (diff < 0) return 0;
    return (diff ~/ 7) + 1;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// 设置当前查看的周
  void setWeek(int week) {
    if (week < 1 || week > _settings.totalWeeks) return;
    _currentWeek = week;
    notifyListeners();
  }

  /// 获取当前周某星期的日期
  DateTime dateForWeekday(int weekday) {
    final weekStart = _settings.semesterStart.add(
      Duration(days: (_currentWeek - 1) * 7),
    );
    return weekStart.add(Duration(days: weekday - 1));
  }
}
