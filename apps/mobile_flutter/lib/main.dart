import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart'; // 🔥 테마 방송국 불러오기
import 'features/splash/screens/splash_screen.dart';
import 'features/vehicle/providers/vehicle_provider.dart'; 
import 'features/auth/providers/user_provider.dart'; 

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VehicleProvider()..loadDummyData()),
        ChangeNotifierProvider(create: (_) => UserProvider()), 
        ChangeNotifierProvider(create: (_) => ThemeProvider()), // 🔥 테마 방송국 추가!
      ],
      child: const AuParkApp(),
    ),
  );
}

class AuParkApp extends StatelessWidget {
  const AuParkApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔥 실시간으로 다크 모드 켜졌는지 확인
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Au-Park',
      theme: AppTheme.lightTheme, // 기본 라이트 테마
      darkTheme: AppTheme.darkTheme, // 다크 테마
      // 스위치 상태에 따라 테마를 라이트/다크로 전환
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light, 
      home: const SplashScreen(), 
      debugShowCheckedModeBanner: false,
    );
  }
}