import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course.dart';
import '../models/exam.dart';
import '../models/homework.dart';
import '../models/holiday.dart';
import '../models/app_settings.dart';

/// 本地存储服务：所有数据以 JSON 存在 SharedPreferences 中，不上传云端
class StorageService {
  static const _kCourses = 'courses';
  static const _kExams = 'exams';
  static const _kHomeworks = 'homeworks';
  static const _kHolidays = 'holidays';
  static const _kSettings = 'settings';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ===== 课程 =====
  List<Course> loadCourses() {
    final data = _prefs.getString(_kCourses);
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => Course.fromJson(e)).toList();
  }

  Future<void> saveCourses(List<Course> courses) async {
    await _prefs.setString(
      _kCourses,
      jsonEncode(courses.map((e) => e.toJson()).toList()),
    );
  }

  // ===== 考试 =====
  List<Exam> loadExams() {
    final data = _prefs.getString(_kExams);
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => Exam.fromJson(e)).toList();
  }

  Future<void> saveExams(List<Exam> exams) async {
    await _prefs.setString(
      _kExams,
      jsonEncode(exams.map((e) => e.toJson()).toList()),
    );
  }

  // ===== 作业 =====
  List<Homework> loadHomeworks() {
    final data = _prefs.getString(_kHomeworks);
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => Homework.fromJson(e)).toList();
  }

  Future<void> saveHomeworks(List<Homework> homeworks) async {
    await _prefs.setString(
      _kHomeworks,
      jsonEncode(homeworks.map((e) => e.toJson()).toList()),
    );
  }

  // ===== 假期调休 =====
  List<Holiday> loadHolidays() {
    final data = _prefs.getString(_kHolidays);
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => Holiday.fromJson(e)).toList();
  }

  Future<void> saveHolidays(List<Holiday> holidays) async {
    await _prefs.setString(
      _kHolidays,
      jsonEncode(holidays.map((e) => e.toJson()).toList()),
    );
  }

  // ===== 设置 =====
  AppSettings loadSettings() {
    final data = _prefs.getString(_kSettings);
    if (data == null) return AppSettings();
    return AppSettings.fromJson(jsonDecode(data));
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _prefs.setString(_kSettings, jsonEncode(settings.toJson()));
  }

  /// 导出全部数据为 JSON 字符串（用于备份）
  String exportAll() {
    return jsonEncode({
      'version': 1,
      'exportTime': DateTime.now().toIso8601String(),
      'courses': loadCourses().map((e) => e.toJson()).toList(),
      'exams': loadExams().map((e) => e.toJson()).toList(),
      'homeworks': loadHomeworks().map((e) => e.toJson()).toList(),
      'holidays': loadHolidays().map((e) => e.toJson()).toList(),
      'settings': loadSettings().toJson(),
    });
  }

  /// 从 JSON 字符串恢复全部数据
  Future<void> importAll(String jsonStr) async {
    final data = jsonDecode(jsonStr);
    if (data['courses'] != null) {
      await saveCourses(
          (data['courses'] as List).map((e) => Course.fromJson(e)).toList());
    }
    if (data['exams'] != null) {
      await saveExams(
          (data['exams'] as List).map((e) => Exam.fromJson(e)).toList());
    }
    if (data['homeworks'] != null) {
      await saveHomeworks(
          (data['homeworks'] as List).map((e) => Homework.fromJson(e)).toList());
    }
    if (data['holidays'] != null) {
      await saveHolidays(
          (data['holidays'] as List).map((e) => Holiday.fromJson(e)).toList());
    }
    if (data['settings'] != null) {
      await saveSettings(AppSettings.fromJson(data['settings']));
    }
  }
}
