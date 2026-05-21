import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'parking_info_screen.dart';
import 'parking_status_screen.dart';
import '../../payment/screens/my_page_screen.dart';
import 'all_menu_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  // 🔥 홈 화면이 3번째(인덱스 2)로 이동했으므로, 앱 실행 시 기본 선택 값을 2로 변경합니다.
  int _selectedIndex = 2; 

  // 🔥 '홈' 화면을 3번째(정중앙) 자리에 배치합니다.
  final List<Widget> _screens = [
    const AllMenuScreen(),       // 0: 전체 메뉴
    const ParkingStatusScreen(), // 1: 주차 현황 (막대 게이지)
    const HomeScreen(),          // 2: 홈 (★ 정중앙 ★)
    const ParkingInfoScreen(),   // 3: 주차 정보
    const MyPageScreen(),        // 4: 마이페이지
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Au-Park', 
          style: TextStyle(fontWeight: FontWeight.w900, color: isDarkMode ? Colors.white : primaryColor, letterSpacing: -1)
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: Theme.of(context).cardColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed, // 5개 탭 고정
        selectedFontSize: 11,
        unselectedFontSize: 11,
        // 🔥 하단 탭 아이콘과 글자 순서도 화면 순서와 완벽하게 일치시킵니다.
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: '전체 메뉴'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '주차 현황'),
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: '홈'), // ★ 3번째 자리 ★
          BottomNavigationBarItem(icon: Icon(Icons.local_parking), label: '주차 정보'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '마이페이지'),
        ],
      ),
    );
  }
}