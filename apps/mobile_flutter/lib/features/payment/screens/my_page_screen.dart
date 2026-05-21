import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../vehicle/providers/vehicle_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../vehicle/screens/vehicle_registration_screen.dart';
import '../../auth/screens/profile_detail_screen.dart';
import 'payment_method_screen.dart';
import 'parking_history_screen.dart';
import '../../support/screens/notice_screen.dart';
import '../../support/screens/faq_screen.dart';
import '../../support/screens/settings_screen.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final cardColor = Theme.of(context).cardColor;
    // 🔥 다크모드 감지
    final isDarkMode = Theme.of(context).brightness == Brightness.dark; 

    final registeredVehicles = Provider.of<VehicleProvider>(context).vehicles;
    final userProfile = Provider.of<UserProvider>(context).user; 

    String vehicleSubtitle;
    if (registeredVehicles.isEmpty) {
      vehicleSubtitle = '등록된 차량이 없습니다.';
    } else if (registeredVehicles.length == 1) {
      vehicleSubtitle = '현재 등록: ${registeredVehicles.first.plateNumber}';
    } else {
      vehicleSubtitle = '현재 등록: ${registeredVehicles.first.plateNumber} 외 ${registeredVehicles.length - 1}대';
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '마이페이지', 
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 24),
            
            // 1. 프로필 요약 카드
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileDetailScreen()),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: Colors.white, size: 36),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${userProfile.name} 님',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userProfile.department,
                            style: const TextStyle(fontSize: 14, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // 2. 주요 관리 메뉴 목록
            Text(
              '내 정보 관리', 
              // 🔥 다크모드일 때 훨씬 밝은 흰색/회색으로 강제 지정
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white70 : Colors.black54)
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  _buildMenuTile(
                    context: context,
                    isDarkMode: isDarkMode, // 🔥 다크모드 상태 넘겨주기
                    icon: Icons.directions_car_outlined, 
                    title: '차량 등록 / 관리', 
                    subtitle: vehicleSubtitle, 
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VehicleRegistrationScreen())),
                  ),
                  Divider(height: 1, indent: 56, color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
                  _buildMenuTile(
                    context: context,
                    isDarkMode: isDarkMode,
                    icon: Icons.credit_card, 
                    title: '결제 수단 관리', 
                    subtitle: '신한카드 등록됨',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentMethodScreen())),
                  ),
                  Divider(height: 1, indent: 56, color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
                  _buildMenuTile(
                    context: context,
                    isDarkMode: isDarkMode,
                    icon: Icons.receipt_long_outlined, 
                    title: '주차 이용 내역', 
                    subtitle: null,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ParkingHistoryScreen())),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // 3. 고객지원 및 기타 설정
            Text(
              '고객 지원', 
              // 🔥 다크모드일 때 훨씬 밝은 흰색/회색으로 강제 지정
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white70 : Colors.black54)
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  _buildMenuTile(
                    context: context,
                    isDarkMode: isDarkMode,
                    icon: Icons.campaign_outlined, 
                    title: '공지사항', 
                    subtitle: null,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NoticeScreen())),
                  ),
                  Divider(height: 1, indent: 56, color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
                  _buildMenuTile(
                    context: context,
                    isDarkMode: isDarkMode,
                    icon: Icons.help_outline, 
                    title: '자주 묻는 질문 (FAQ)', 
                    subtitle: null,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FaqScreen())),
                  ),
                  Divider(height: 1, indent: 56, color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
                  _buildMenuTile(
                    context: context,
                    isDarkMode: isDarkMode,
                    icon: Icons.settings_outlined, 
                    title: '앱 설정', 
                    subtitle: null,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Center(
              child: TextButton(
                onPressed: () {},
                child: Text('로그아웃', style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey, fontSize: 16, decoration: TextDecoration.underline)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 🔥 타일 내부 글자들도 다크모드에 맞춰 색상 변경되도록 업데이트
  Widget _buildMenuTile({
    required BuildContext context, 
    required bool isDarkMode,
    required IconData icon, 
    required String title, 
    String? subtitle, 
    VoidCallback? onTap
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor, size: 28),
      title: Text(
        title, 
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white : Colors.black87)
      ),
      subtitle: subtitle != null 
          ? Text(subtitle, style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey, fontSize: 13)) 
          : null,
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: isDarkMode ? Colors.grey.shade600 : Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      onTap: onTap,
    );
  }
}