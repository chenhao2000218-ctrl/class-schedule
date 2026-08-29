import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/update_service.dart';
import '../widgets/week_timetable.dart';
import '../widgets/glass_widgets.dart';
import 'day_detail_screen.dart';
import 'exam_screen.dart';
import 'settings_screen.dart';
import 'course_edit_screen.dart';

// 当前应用版本（与 pubspec.yaml 保持一致）
const String _currentVersion = '1.0.6';
// 显示用版本号
String get _displayVersion => _currentVersion;

/// 主界面：悬浮胶囊玻璃底栏 + 平滑切换动画
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _prevIndex = 0;

  final _pages = const [
    _ScheduleTab(),
    ExamScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // 启动后延迟2秒检查更新（避免影响首屏渲染）
    Future.delayed(const Duration(seconds: 2), _checkUpdate);
  }

  Future<void> _checkUpdate() async {
    final info = await UpdateService.checkUpdate(_currentVersion);
    if (info != null && mounted) {
      showUpdateBanner(context, info);
    }
  }

  void _switchTab(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _prevIndex = _currentIndex;
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 页面切换：平滑滑动 + 淡入淡出
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final direction = _currentIndex > _prevIndex ? 1.0 : -1.0;
              return SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(direction * 0.25, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: FadeTransition(
                  opacity: Tween<double>(begin: 0.6, end: 1.0)
                      .animate(animation),
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey<int>(_currentIndex),
              child: _pages[_currentIndex],
            ),
          ),
          // 悬浮胶囊玻璃底栏
          Positioned(
            left: 16,
            right: 16,
            bottom: 50,
            child: _buildBottomBar(),
          ),
        ],
      ),
    );
  }

  /// 底部导航栏：胶囊形选中指示器平滑滑动
  Widget _buildBottomBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const tabCount = 3;
    const inset = 3.0; // 统一内缩（约1mm）

    return GlassPillBar(
      padding: const EdgeInsets.symmetric(
        horizontal: inset,
        vertical: inset,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / tabCount;
          const indicatorHeight = 60.0;

          return SizedBox(
            height: indicatorHeight,
            child: Stack(
              children: [
                // 蓝色胶囊选中指示器 - 平滑滑动
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  left: _currentIndex * tabWidth,
                  top: 0,
                  width: tabWidth,
                  child: Container(
                    height: indicatorHeight,
                    alignment: Alignment.center,
                    child: Container(
                      width: tabWidth - inset * 2,
                      height: indicatorHeight,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.18)
                            : const Color(0xFF007AFF).withOpacity(0.15),
                        // 完全胶囊圆角 = 高度/2，与底栏形状一致
                        borderRadius:
                            BorderRadius.circular(indicatorHeight / 2),
                      ),
                    ),
                  ),
                ),
                // Tab 按钮层
                Row(
                  children: [
                    _buildTabItem(0, Icons.calendar_today, '课表', tabWidth),
                    _buildTabItem(1, Icons.assignment, '考试', tabWidth),
                    _buildTabItem(
                        2, Icons.settings_outlined, '设置', tabWidth),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabItem(
      int index, IconData icon, String label, double tabWidth) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _switchTab(index),
      child: SizedBox(
        width: tabWidth,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: Icon(
                icon,
                size: 22,
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF007AFF))
                    : Colors.grey,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF007AFF))
                    : Colors.grey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

/// 课表 Tab
class _ScheduleTab extends StatefulWidget {
  const _ScheduleTab();

  @override
  State<_ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<_ScheduleTab> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('课程表'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            actions: [
              // 右上角玻璃悬浮添加按钮
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GlassCircleButton(
                  icon: Icons.add,
                  size: 40,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CourseEditScreen(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  _buildWeekSelector(state),
                  Expanded(
                    child: WeekTimetable(
                      currentWeek: state.currentWeek,
                      onCourseTap: (course) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DayDetailScreen(
                              date: state.dateForWeekday(course.weekday),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              // 右下角玻璃悬浮考试按钮（仅课表页显示）
              Positioned(
                right: 16,
                bottom: 90,
                child: GlassPillButton(
                  icon: Icons.assignment,
                  label: '考试',
                  onPressed: () {
                    final homeState =
                        context.findAncestorStateOfType<_HomeScreenState>();
                    homeState?._switchTab(1);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeekSelector(AppState state) {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 22),
            onPressed: state.currentWeek > 1
                ? () => state.setWeek(state.currentWeek - 1)
                : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => state.setWeek(state.currentWeek),
              child: Center(
                child: Text(
                  '第 ${state.currentWeek} 周',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 22),
            onPressed: state.currentWeek < state.settings.totalWeeks
                ? () => state.setWeek(state.currentWeek + 1)
                : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ],
      ),
    );
  }
}
