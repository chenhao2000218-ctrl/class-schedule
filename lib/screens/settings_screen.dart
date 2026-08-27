import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/app_settings.dart';
import '../services/backup_service.dart';
import '../services/storage_service.dart';
import 'schedule_settings_screen.dart';
import 'import_screen.dart';
import 'theme_screen.dart';
import 'holiday_screen.dart';

/// 设置页面
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final settings = state.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          // 学期设置
          _buildSectionHeader('学期'),
          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: const Text('学期开始日期'),
            subtitle: Text(
              '${settings.semesterStart.year}-'
              '${settings.semesterStart.month.toString().padLeft(2, '0')}-'
              '${settings.semesterStart.day.toString().padLeft(2, '0')} '
              '(第1周周一)',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: settings.semesterStart,
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (picked != null) {
                // 调整到周一
                final monday = picked.subtract(Duration(days: picked.weekday - 1));
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
          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text('作息时间'),
            subtitle: Text('${settings.timeSlots.length} 节课'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScheduleSettingsScreen()),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.weekend),
            title: const Text('显示周末'),
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

          // 外观
          _buildSectionHeader('外观'),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('主题与颜色'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ThemeScreen()),
            ),
          ),

          // 数据管理
          _buildSectionHeader('数据管理'),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('导入课表 (ICS / JSON)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ImportScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('导出 JSON 备份'),
            subtitle: const Text('备份所有课程、考试、作业数据'),
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
          ListTile(
            leading: const Icon(Icons.beach_access),
            title: const Text('假期与调休'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HolidayScreen()),
            ),
          ),

          // 关于
          _buildSectionHeader('关于'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('课程表'),
            subtitle: Text('纯净无广告 · 数据本地存储 · 保护隐私'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}
