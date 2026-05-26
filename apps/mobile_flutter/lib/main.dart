import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/shared_data.dart';
import 'core/theme/theme_provider.dart';
import 'features/vehicle/providers/vehicle_provider.dart';
import 'features/auth/providers/user_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/parking/screens/main_navigation_screen.dart'; // 실제 경로에 맞게 수정

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  // 1. 저장된 차량 번호 복구
  if (isLoggedIn) {
    SharedData.vehicleNumber.value = prefs.getString('registeredVehicle') ?? "등록된 차량 없음";
  }

  // 2. 저장된 프로필 정보 복구 (없으면 안산대 인공지능소프트웨어과 영진님 정보로 기본 세팅)
  final String savedName = prefs.getString('userName') ?? "이영진";
  final String savedEmail = prefs.getString('userEmail') ?? "youngjin@ansan.ac.kr";
  final String savedDept = prefs.getString('userDept') ?? "인공지능소프트웨어과";

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VehicleProvider()..loadDummyData()),
        // 🔥 앱 시작과 동시에 복구된 유저 정보를 프로바이더에 꽂아줍니다!
        ChangeNotifierProvider(
          create: (_) => UserProvider()..setUser(name: savedName, email: savedEmail, department: savedDept),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: AuParkApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class AuParkApp extends StatelessWidget {
  final bool isLoggedIn;
  
  const AuParkApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Au-Park',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF003366),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF003366),
          primary: const Color(0xFF003366),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      home: isLoggedIn ? const MainNavigationScreen() : const LoginScreen(),
    );
  }
}