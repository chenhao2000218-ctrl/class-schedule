import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/app_settings.dart';
import '../utils/constants.dart';

/// 主题设置页面：深色/浅色模式 + 自定义主题色
class ThemeScreen extends StatelessWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final settings = state.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('主题与外观')),
      body: ListView(
        children: [
          // 主题模式
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('显示模式',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('跟随系统'),
            value: ThemeMode.system,
            groupValue: settings.themeMode,
            onChanged: (v) =>
                state.updateTheme(v!, settings.colorSeed),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('浅色模式'),
            value: ThemeMode.light,
            groupValue: settings.themeMode,
            onChanged: (v) =>
                state.updateTheme(v!, settings.colorSeed),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('深色模式'),
            value: ThemeMode.dark,
            groupValue: settings.themeMode,
            onChanged: (v) =>
                state.updateTheme(v!, settings.colorSeed),
          ),
          const Divider(),
          // 主题色
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('主题色',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: List.generate(kThemeColors.length, (i) {
                final selected = settings.colorSeed == i;
                return GestureDetector(
                  onTap: () => state.updateTheme(settings.themeMode, i),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: kThemeColors[i],
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(color: Colors.black, width: 3)
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
