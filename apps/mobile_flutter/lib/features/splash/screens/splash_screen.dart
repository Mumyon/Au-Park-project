import 'package:flutter/material.dart';
import 'dart:async'; // Timer를 사용하기 위해 필요
import '../../auth/screens/login_screen.dart'; // 이동할 로그인 화면 import

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  // 2초 뒤에 로그인 화면으로 넘어가는 함수
  void _navigateToLogin() {
    Timer(const Duration(seconds: 2), () {
      // pushReplacement를 쓰면 뒤로가기를 눌렀을 때 다시 로딩 화면으로 오지 않음
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: primaryColor, // 배경을 네이비 톤으로 꽉 채움
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 앱 로고
            const Icon(
              Icons.local_parking, 
              size: 100, 
              color: Colors.white
            ),
            const SizedBox(height: 24),
            
            // 앱 이름
            const Text(
              'Au-Park',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2.0, // 글자 간격을 살짝 넓혀서 고급스럽게
              ),
            ),
            const SizedBox(height: 16),
            
            // 앱 서브 타이틀
            Text(
              '안산대학교 스마트 주차 관제 시스템',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            
            const SizedBox(height: 60),
            
            // 로딩 빙글빙글 애니메이션
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}