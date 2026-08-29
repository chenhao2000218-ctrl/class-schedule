import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'screens/home_screen.dart';
import 'utils/theme.dart';
import 'models/app_settings.dart';
import 'dart:ui' as ui;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 预热中文字体，避免首帧乱码
  _preloadFonts();
  runApp(const ClassScheduleApp());
}

/// 预热中文字体，强制 Flutter 加载系统中文字体到缓存
Future<void> _preloadFonts() async {
  // 渲染一段中文文本到离屏画布，触发字体加载
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const textStyle = TextStyle(
    fontSize: 20,
    fontFamilyFallback: ['PingFang SC', 'Microsoft YaHei', 'sans-serif'],
  );
  const textSpan = TextSpan(
    text: '课程表考试设置星期一星期二星期三星期四星期五星期六星期日',
    style: textStyle,
  );
  final textPainter = TextPainter(
    text: textSpan,
    textDirection: TextDirection.ltr,
  )..layout();
  textPainter.paint(canvas, Offset.zero);
  recorder.endRecording();
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

          return MaterialApp(
            title: '课程表',
            debugShowCheckedModeBanner: false,
            locale: const Locale('zh', 'CN'),
            supportedLocales: const [
              Locale('zh', 'CN'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            // 强制所有文字使用中文字体 fallback
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.noScaling,
                ),
                child: DefaultTextStyle(
                  style: DefaultTextStyle.of(context).style.copyWith(
                    fontFamilyFallback: const [
                      'PingFang SC',
                      'Microsoft YaHei',
                      'Noto Sans CJK SC',
                      'sans-serif',
                    ],
                  ),
                  child: child!,
                ),
              );
            },
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: _toMaterialThemeMode(settings.themeMode),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }

  ThemeMode _toMaterialThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}
