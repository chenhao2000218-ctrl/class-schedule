import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'screens/home_screen.dart';
import 'utils/theme.dart';
import 'models/app_settings.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ClassScheduleApp());
}

class ClassScheduleApp extends StatelessWidget {
  const ClassScheduleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: Consumer<AppState>(
        builder: (context, state, _) {
          final settings = state.settings;
          final brightness = _resolveBrightness(settings.themeMode, context);

          return MaterialApp(
            title: '课程表',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.build(settings.colorSeed, Brightness.light),
            darkTheme: AppTheme.build(settings.colorSeed, Brightness.dark),
            themeMode: _toMaterialThemeMode(settings.themeMode),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }

  Brightness _resolveBrightness(ThemeMode mode, BuildContext context) {
    switch (mode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return MediaQuery.of(context).platformBrightness;
    }
  }

  ThemeMode _toMaterialThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return ThemeMode.light;
      case ThemeMode.dark:
        return ThemeMode.dark;
      case ThemeMode.system:
        return ThemeMode.system;
    }
  }
}
