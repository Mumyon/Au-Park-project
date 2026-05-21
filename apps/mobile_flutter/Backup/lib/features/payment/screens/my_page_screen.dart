import 'package:flutter/material.dart';
import '../../vehicle/screens/vehicle_registration_screen.dart';
import 'payment_method_screen.dart';
import 'parking_history_screen.dart';
import '../../support/screens/notice_screen.dart';
import '../../support/screens/faq_screen.dart';
import '../../support/screens/settings_screen.dart';
import '../../auth/screens/profile_detail_screen.dart';

// 🔥 갔다 돌아왔을 때 새로고침을 반영하기 위해 StatefulWidget으로 변경
class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    // 🔥 차량 등록 화면의 static 리스트를 실시간으로 읽어와 자막 생성
    final registeredVehicles = VehicleRegistrationScreen.vehicles;
    String vehicleSubtitle;

    if (registeredVehicles.isEmpty) {
      vehicleSubtitle = '등록된 차량이 없습니다.';
    } else if (registeredVehicles.length == 1) {
      vehicleSubtitle = '현재 등록: ${registeredVehicles.first}';
    } else {
      // 2대 이상일 경우 '첫 번째 차량 번호 외 N대' 형태로 노출 (편의성 디테일)
      vehicleSubtitle = '현재 등록: ${registeredVehicles.first} 외 ${registeredVehicles.length - 1}대';
    }

    return Container(
      color: Colors.transparent,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '마이페이지', 
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 24),
            
            // 1. 프로필 요약 카드 (클릭 가능하도록 InkWell 추가)
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '영진 님',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '인공지능소프트웨어학과',
                            style: TextStyle(fontSize: 14, color: Colors.white70),
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
            const Text('내 정보 관리', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  // 차량 등록 / 관리 메뉴
                  _buildMenuTile(
                    icon: Icons.directions_car_outlined, 
                    title: '차량 등록 / 관리', 
                    subtitle: vehicleSubtitle, // 🔥 동적으로 변경된 자막 적용
                    onTap: () async {
                      // 🔥 await를 붙여서 화면이 닫힐 때까지 기다립니다.
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const VehicleRegistrationScreen()),
                      );
                      // 🔥 차량 관리 화면에서 다시 돌아오는 순간 setState가 실행되면서 마이페이지 UI를 다시 그립니다.
                      setState(() {});
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildMenuTile(
                    icon: Icons.credit_card, 
                    title: '결제 수단 관리', 
                    subtitle: '신한카드 등록됨',
                    onTap: () {
                      // 🔥 결제 수단 관리 화면으로 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PaymentMethodScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildMenuTile(
                    icon: Icons.receipt_long_outlined, 
                    title: '주차 이용 내역', 
                    subtitle: null,
                    onTap: () {
                      // 🔥 주차 이용 내역 화면으로 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ParkingHistoryScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // 3. 고객지원 및 기타 설정
            const Text('고객 지원', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  // (마이페이지 코드 아래쪽의 고객지원 섹션 수정)
                  _buildMenuTile(
                    icon: Icons.campaign_outlined, 
                    title: '공지사항', 
                    subtitle: null,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const NoticeScreen()));
                    }
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildMenuTile(
                    icon: Icons.help_outline, 
                    title: '자주 묻는 질문 (FAQ)', 
                    subtitle: null,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const FaqScreen()));
                    }
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildMenuTile(
                    icon: Icons.settings_outlined, 
                    title: '앱 설정', 
                    subtitle: null,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                    }
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Center(
              child: TextButton(
                onPressed: () {},
                child: const Text('로그아웃', style: TextStyle(color: Colors.grey, fontSize: 16, decoration: TextDecoration.underline)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({required IconData icon, required String title, String? subtitle, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF003366), size: 28),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      onTap: onTap,
    );
  }
}