import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/app_settings.dart';
import '../services/backup_service.dart';
import '../services/storage_service.dart';
import '../services/update_service.dart';
import 'schedule_settings_screen.dart';
import 'import_screen.dart';
import 'theme_screen.dart';
import 'holiday_screen.dart';

// 当前应用版本（与 pubspec.yaml 保持一致）
const String _currentVersion = '1.0.2+3';

/// 设置页面 - iOS 分组列表风格
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: Consumer<AppState>(
        builder: (context, state, _) {
          final settings = state.settings;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader('学期'),
              _buildGroup(context, [
                _buildNavigationRow(
                  icon: Icons.calendar_month,
                  title: '学期开始日期',
                  subtitle:
                      '${settings.semesterStart.year}-'
                      '${settings.semesterStart.month.toString().padLeft(2, '0')}-'
                      '${settings.semesterStart.day.toString().padLeft(2, '0')}',
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: settings.semesterStart,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      final monday = picked.subtract(
                          Duration(days: picked.weekday - 1));
                      await state.updateSettings(AppSettings(
                        semesterStart: monday,
                        totalWeeks: settings.totalWeeks,
                        colorSeed: settings.colorSeed,
                        themeMode: settings.themeMode,
                        defaultRemindMinutes: settings.defaultRemindMinutes,
                        showWeekend: settings.showWeekend,
                        timeSlots: settings.timeSlots,
                      ));
                    }
                  },
                ),
                _buildDivider(context),
                _buildNavigationRow(
                  icon: Icons.timer,
                  title: '作息时间',
                  subtitle: '${settings.timeSlots.length} 节课',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ScheduleSettingsScreen()),
                  ),
                ),
                _buildDivider(context),
                _buildSwitchRow(
                  icon: Icons.weekend,
                  title: '显示周末',
                  value: settings.showWeekend,
                  onChanged: (v) => state.updateSettings(AppSettings(
                    semesterStart: settings.semesterStart,
                    totalWeeks: settings.totalWeeks,
                    colorSeed: settings.colorSeed,
                    themeMode: settings.themeMode,
                    defaultRemindMinutes: settings.defaultRemindMinutes,
                    showWeekend: v,
                    timeSlots: settings.timeSlots,
                  )),
                ),
              ]),
              const SizedBox(height: 24),

              _buildSectionHeader('外观'),
              _buildGroup(context, [
                _buildNavigationRow(
                  icon: Icons.palette,
                  title: '主题与颜色',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ThemeScreen()),
                  ),
                ),
              ]),
              const SizedBox(height: 24),

              _buildSectionHeader('数据管理'),
              _buildGroup(context, [
                _buildNavigationRow(
                  icon: Icons.download,
                  title: '导入课表',
                  subtitle: 'ICS / JSON',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ImportScreen()),
                  ),
                ),
                _buildDivider(context),
                _buildNavigationRow(
                  icon: Icons.backup,
                  title: '导出 JSON 备份',
                  subtitle: '备份所有数据',
                  onTap: () async {
                    try {
                      final storage = StorageService();
                      await storage.init();
                      final backup = BackupService(storage);
                      await backup.shareBackup();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('备份已生成')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('导出失败: $e')),
                        );
                      }
                    }
                  },
                ),
                _buildDivider(context),
                _buildNavigationRow(
                  icon: Icons.beach_access,
                  title: '假期与调休',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HolidayScreen()),
                  ),
                ),
              ]),
              const SizedBox(height: 24),

              _buildSectionHeader('关于'),
              _buildGroup(context, [
                _buildNavigationRow(
                  icon: Icons.system_update,
                  title: '检查更新',
                  subtitle: '当前版本 $_currentVersion',
                  onTap: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('正在检查更新...')),
                    );
                    final info =
                        await UpdateService.checkUpdate(_currentVersion);
                    if (context.mounted) {
                      if (info != null) {
                        showUpdateBanner(context, info);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已是最新版本')),
                        );
                      }
                    }
                  },
                ),
                _buildDivider(context),
                _buildInfoRow(
                  icon: Icons.info_outline,
                  title: '课程表',
                  subtitle: '纯净无广告 · 数据本地存储',
                ),
              ]),
              const SizedBox(height: 100), // 底部留白，避免被悬浮底栏遮挡
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String text) => Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _buildGroup(BuildContext context, List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: children),
      );

  Widget _buildDivider(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 56),
        child: Divider(height: 1, color: Theme.of(context).dividerColor),
      );

  Widget _buildNavigationRow({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 22, color: Colors.grey[600]),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle,
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[500])),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: Colors.grey[400], size: 20),
              ],
            ),
          ),
        ),
      );

  Widget _buildSwitchRow({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Colors.grey[600]),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500)),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      );

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    String? subtitle,
  }) =>
      Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Colors.grey[600]),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey[500])),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}
