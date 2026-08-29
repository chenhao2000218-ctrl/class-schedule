import 'package:flutter/material.dart';
import 'constants.dart';

/// iOS 原生风格主题系统
/// 遵循 Apple Human Interface Guidelines + Liquid Glass 设计语言
class AppTheme {
  static const _fontFallback = <String>[
    'PingFang SC',
    'Microsoft YaHei',
    'Noto Sans CJK SC',
    'Noto Sans SC',
    'Source Han Sans SC',
    'sans-serif',
  ];

  static const _baseTextTheme = TextTheme(
    bodyLarge: TextStyle(fontSize: 17, fontFamilyFallback: _fontFallback),
    bodyMedium: TextStyle(fontSize: 15, fontFamilyFallback: _fontFallback),
    titleLarge: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      fontFamilyFallback: _fontFallback,
    ),
    titleMedium: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      fontFamilyFallback: _fontFallback,
    ),
    titleSmall: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      fontFamilyFallback: _fontFallback,
    ),
  );

  /// 浅色主题
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: kThemeColors[0],
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamilyFallback: _fontFallback,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF2F2F7), // iOS 分组背景
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF2F2F7).withOpacity( 0.8),
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF007AFF)),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF007AFF), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 15),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFF007AFF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.2),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF007AFF),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w400),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return const Color(0xFF34C759);
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return const Color(0xFF34C759).withOpacity(0.5);
          return Colors.grey.withOpacity( 0.3);
        }),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xF8FFFFFF), // 半透明白色（玻璃感）
        selectedItemColor: Color(0xFF007AFF),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyle(fontSize: 10),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E5EA),
        thickness: 0.5,
      ),
      textTheme: _baseTextTheme.apply(
        bodyColor: Colors.black,
        displayColor: Colors.black,
      ),
    );
  }

  /// 深色主题
  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: kThemeColors[0],
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamilyFallback: _fontFallback,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF000000), // iOS 深色纯黑
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF000000).withOpacity( 0.8),
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0A84FF)),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: const Color(0xFF1C1C1E), // iOS 深色分组卡片
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1C1C1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0A84FF), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 15),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFF0A84FF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF0A84FF),
          textStyle: const TextStyle(fontSize: 17),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return const Color(0xFF30D158);
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return const Color(0xFF30D158).withOpacity(0.5);
          return Colors.grey.withOpacity( 0.3);
        }),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xF01C1C1E), // 半透明深色（玻璃感）
        selectedItemColor: Color(0xFF0A84FF),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF38383A),
        thickness: 0.5,
      ),
      textTheme: _baseTextTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );
  }
}

/// iOS 系统颜色（浅色模式）
class IOSColors {
  static const blue = Color(0xFF007AFF);
  static const green = Color(0xFF34C759);
  static const red = Color(0xFFFF3B30);
  static const orange = Color(0xFFFF9500);
  static const yellow = Color(0xFFFFCC00);
  static const purple = Color(0xFFAF52DE);
  static const gray = Color(0xFF8E8E93);
  static const groupBackground = Color(0xFFF2F2F7);
  static const separator = Color(0xFFE5E5EA);
}

/// 课程块渐变色（iOS 风格，柔和半透明）
const List<List<Color>> kCourseGradients = [
  [Color(0xFF5AC8FA), Color(0xFF007AFF)], // 蓝
  [Color(0xFFBF5AF2), Color(0xFFAF52DE)], // 紫
  [Color(0xFF30D158), Color(0xFF34C759)], // 绿
  [Color(0xFFFF9F0A), Color(0xFFFF9500)], // 橙
  [Color(0xFFFFD60A), Color(0xFFFFCC00)], // 黄
  [Color(0xFF64D2FF), Color(0xFF5AC8FA)], // 青
  [Color(0xFFFF6482), Color(0xFFFF2D55)], // 粉红
  [Color(0xFFA8A8A8), Color(0xFF8E8E93)], // 灰
];
