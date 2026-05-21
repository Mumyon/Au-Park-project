import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart'; // 🔥 테마 방송국 불러오기

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 방송국 구독
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('앱 설정', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('화면 설정', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          
          // 🔥 다크 모드 스위치 연동 완료!
          SwitchListTile(
            title: const Text('다크 모드', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            subtitle: const Text('어두운 테마로 눈의 피로를 줄입니다.'),
            value: themeProvider.isDarkMode, // 현재 방송국 데이터
            onChanged: (value) {
              themeProvider.toggleTheme(value); // 스위치 누르면 방송국에 업데이트 요청
            },
            activeColor: const Color(0xFF003366),
          ),
          
          const Divider(height: 40),
          
          const Text('알림 설정', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          SwitchListTile(
            title: const Text('주차 완료 알림 (준비중)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            value: true,
            onChanged: (value) {}, // 추후 구현
            activeColor: const Color(0xFF003366),
          ),
          SwitchListTile(
            title: const Text('자동 결제 알림 (준비중)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            value: true,
            onChanged: (value) {}, // 추후 구현
            activeColor: const Color(0xFF003366),
          ),
        ],
      ),
    );
  }
}