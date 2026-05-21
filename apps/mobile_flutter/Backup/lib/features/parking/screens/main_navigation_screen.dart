import 'package:flutter/material.dart';
import 'home_screen.dart';
// TODO: 주차 정보 화면과 마이페이지 화면은 추후 연결할 예정입니다.
import 'parking_info_screen.dart';
import '../../payment/screens/my_page_screen.dart';  

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // 하단 탭을 눌렀을 때 보여줄 화면 목록
  final List<Widget> _widgetOptions = [
    const HomeScreen(), // 1. 실시간 혼잡도 화면
    const ParkingInfoScreen(), // 2. 주차 정보 화면
    const MyPageScreen(), // 🔥 3. 마이페이지 화면 연결 완료!
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50, // 전체 배경색을 아주 옅은 회색으로 설정
      
      // 🔥 AppBar 구성 (새로고침 버튼 포함)
      appBar: AppBar(
        backgroundColor: Colors.grey.shade50, // Scaffold 배경색과 통일
        title: const Text(
          'Au-Park', 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)
        ),
        centerTitle: true,
        elevation: 0,
        
        // 우측 상단 새로고침 버튼
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: () {
              // TODO: 나중에 실제 DB 데이터 새로고침 로직이 들어갈 자리
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('주차장 현황을 업데이트합니다.'), 
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          const SizedBox(width: 8), // 우측 여백
        ],
      ),
      
      // 현재 선택된 탭의 화면을 보여줌
      body: _widgetOptions.elementAt(_selectedIndex),
      
      // 하단 네비게이션 바
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '혼잡도'),
          BottomNavigationBarItem(icon: Icon(Icons.access_time), label: '주차 정보'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '마이페이지'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor, // 테마의 네이비 색상 적용
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
} 