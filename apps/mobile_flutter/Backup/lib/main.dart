import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
// 🔥 기존 LoginScreen 대신 SplashScreen을 import 합니다.
import 'features/splash/screens/splash_screen.dart'; 

void main() {
  runApp(const AuParkApp());
}

class AuParkApp extends StatelessWidget {
  const AuParkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Au-Park',
      theme: AppTheme.lightTheme,
      // 🔥 앱의 첫 화면을 스플래시 화면으로 지정!
      home: const SplashScreen(), 
      debugShowCheckedModeBanner: false,
    );
  }
}