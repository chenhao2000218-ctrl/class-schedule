import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/app_state.dart';
import '../widgets/week_timetable.dart';
import '../utils/date_utils.dart';
import 'day_detail_screen.dart';
import 'course_edit_screen.dart';
import 'exam_screen.dart';
import 'homework_screen.dart';
import 'settings_screen.dart';

/// 主界面：底部导航 + 周课表
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _displayWeek = 1;
  bool _weekInitialized = false;
  final _screenshotCtrl = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentWeek = DateUtils.currentWeek(state.settings);
    if (!_weekInitialized && currentWeek > 0) {
      _weekInitialized = true;
      _displayWeek = currentWeek;
    }

    final pages = [
      _buildTimetablePage(state, currentWeek),
      const ExamScreen(),
      const HomeworkScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: '课表'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: '考试'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), label: '作业'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }

  /// 课表页面
  Widget _buildTimetablePage(AppState state, int currentWeek) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('课程表', style: TextStyle(fontSize: 20)),
            Text(
              '第 $_displayWeek 周${currentWeek == _displayWeek ? ' · 本周' : ''}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          // 周次选择
          PopupMenuButton<int>(
            icon: const Icon(Icons.swap_vert),
            itemBuilder: (ctx) => List.generate(
              state.settings.totalWeeks,
              (i) => PopupMenuItem(
                value: i + 1,
                child: Text('第 ${i + 1} 周${i + 1 == currentWeek ? ' (本周)' : ''}'),
              ),
            ),
            onSelected: (w) => setState(() => _displayWeek = w),
          ),
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: '回到本周',
            onPressed: () => setState(() => _displayWeek = currentWeek),
          ),
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: '导出分享图片',
            onPressed: _exportTimetableImage,
          ),
        ],
      ),
      body: Screenshot(
        controller: _screenshotCtrl,
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: WeekTimetable(
            currentWeek: _displayWeek,
            onCourseLongPress: (course) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CourseEditScreen(existingCourse: course),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CourseEditScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('添加课程'),
      ),
    );
  }

  /// 导出课表为图片并分享
  Future<void> _exportTimetableImage() async {
    try {
      final bytes = await _screenshotCtrl.capture();
      if (bytes == null) return;
      // 保存到相册
      await ImageGallerySaver.saveImage(bytes, name: '课表_第$_displayWeek周');
      // 分享
      await Share.shareXFiles(
        [XFile.fromData(bytes, name: 'timetable.png', mimeType: 'image/png')],
        text: '我的课程表 - 第 $_displayWeek 周',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }
}
