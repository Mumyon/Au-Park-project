import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  // 기본값은 라이트 모드 (false)
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  // 스위치를 껐다 켤 때 실행될 함수
  void toggleTheme(bool value) {
    _isDarkMode = value;
    notifyListeners(); // 🔥 "테마 바뀌었어! 앱 전체 색상 다 바꿔!" 라고 방송함
  }
}