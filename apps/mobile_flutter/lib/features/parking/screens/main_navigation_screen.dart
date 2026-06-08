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
  int _selectedIndex = 2; // 홈 화면 기본값 (정중앙)
  
  // 🔥 화면을 드래그해서 넘길 수 있게 해주는 컨트롤러 추가
  late PageController _pageController;

  final List<Widget> _screens = [
    const AllMenuScreen(),
    const ParkingStatusScreen(),
    const HomeScreen(),
    const ParkingInfoScreen(),
    const MyPageScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // 시작할 때 3번째 화면(인덱스 2)부터 보여주도록 컨트롤러 설정
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    // 메모리 누수 방지를 위해 화면이 꺼질 때 컨트롤러 종료
    _pageController.dispose();
    super.dispose();
  }

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
      // 🔥 PageView를 사용해 좌우 드래그 스와이프 기능 적용
      body: PageView(
        controller: _pageController,
        // 화면을 손가락으로 밀어서 넘겼을 때 하단 탭 번호도 같이 바꿔주는 기능
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          // 하단 탭을 눌렀을 때도 화면이 스르륵 이동하도록 연동
          setState(() => _selectedIndex = index);
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        backgroundColor: Theme.of(context).cardColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '정보'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '주차 현황'),
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.car_rental), label: '주차 정보'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '마이페이지'),
        ],
      ),
    );
  }
}