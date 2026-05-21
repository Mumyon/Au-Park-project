import 'package:flutter/material.dart';

class AppTheme {
  // ☀️ 라이트 모드 테마
  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF003366),
    scaffoldBackgroundColor: Colors.grey.shade50, // 라이트모드 기본 배경
    canvasColor: Colors.white,
    cardColor: Colors.white,
    
    // 🔘 라이트 모드 버튼 테마 지정
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF003366), // 짙은 남색 배경
        foregroundColor: Colors.white, // 흰색 글자 (무조건 보이게 강제)
        elevation: 0,
      ),
    ),
    
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
    ),
  );

  // 🌙 다크 모드 테마
  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF003366),
    scaffoldBackgroundColor: const Color(0xFF121212), // 다크모드 기본 배경 (어두운 회색)
    canvasColor: const Color(0xFF1E1E1E), // 컨테이너 등 기본 배경
    cardColor: const Color(0xFF1E1E1E),
    dividerColor: Colors.grey.shade800,
    
    // 🔘 다크 모드 버튼 테마 지정
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF003366), // 다크모드에서도 남색 유지하거나 취향껏 변경 가능
        foregroundColor: Colors.white, // 흰색 글자
        elevation: 0,
      ),
    ),
    
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  );
}