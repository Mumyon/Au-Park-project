import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
// 🔥 탈퇴 기능을 위한 필수 패키지 추가
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/shared_data.dart'; 
import '../../auth/providers/user_provider.dart';
import '../../auth/screens/login_screen.dart'; 
import '../../vehicle/screens/vehicle_registration_screen.dart';
import '../../auth/screens/profile_detail_screen.dart';
import 'payment_method_screen.dart';
import 'parking_history_screen.dart';
import '../../support/screens/notice_screen.dart';
import '../../support/screens/faq_screen.dart';
import '../../support/screens/settings_screen.dart';

// 🚀 화면 켜질 때 상태를 업데이트하기 위해 StatefulWidget으로 변경!
class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {

  @override
  void initState() {
    super.initState();
    // 마이페이지가 열리자마자 저장소에서 진짜 카드 정보를 불러와 동기화합니다.
    _syncPaymentMethodFromStorage();
  }

  // 💾 기기 저장소를 확인해서 SharedData(전역 상태)를 덮어쓰는 함수
  Future<void> _syncPaymentMethodFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMethods = prefs.getString('saved_cards');
    final savedMainId = prefs.getString('main_card_id');

    if (savedMethods != null) {
      final List<dynamic> decoded = jsonDecode(savedMethods);
      final methods = List<Map<String, dynamic>>.from(decoded);
      
      if (methods.isNotEmpty) {
        final mainMethod = methods.firstWhere(
          (m) => m['id'] == savedMainId,
          orElse: () => methods[0],
        );
        // 저장된 진짜 카드 이름으로 업데이트!
        SharedData.paymentMethod.value = mainMethod['name'];
        return;
      }
    }
    // 저장된 카드가 없으면 깔끔하게 없음으로 처리
    SharedData.paymentMethod.value = '등록된 결제 수단 없음';
  }

  // ------------------------------------------------------------------------
  // 🚪 로그아웃 처리 함수
  // ------------------------------------------------------------------------
  Future<void> _handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('registeredVehicle');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    await prefs.remove('userDept');

    SharedData.vehicleNumber.value = "등록된 차량 없음";

    if (!context.mounted) return;
    
    Provider.of<UserProvider>(context, listen: false).clearUser();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false, 
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🔒 안전하게 로그아웃되었습니다.')),
    );
  }

  // ------------------------------------------------------------------------
  // ⚠️ 회원탈퇴 처리 함수 (DB 삭제 포함)
  // ------------------------------------------------------------------------
  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userEmail = userProvider.email;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('회원탈퇴', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          content: const Text('정말로 탈퇴하시겠습니까?\n등록된 차량 정보와 모든 데이터가 즉시 삭제되며 복구할 수 없습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext), // 취소
              child: const Text('취소', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // 다이얼로그 닫기
                
                // 로딩창 띄우기
                showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

                try {
                  // 1. 서버에 탈퇴 요청 보내기 (DB 삭제)
                  final url = Uri.parse('http://10.0.2.2:3000/api/deleteAccount');
                  await http.post(
                    url,
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({'email': userEmail}),
                  );

                  // 2. 구글 로그인 연동 해제
                  final GoogleSignIn googleSignIn = GoogleSignIn();
                  if (await googleSignIn.isSignedIn()) {
                    await googleSignIn.disconnect(); 
                  }

                  // 3. 기기 캐시 삭제 및 Provider 초기화
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  SharedData.vehicleNumber.value = "등록된 차량 없음";
                  
                  if (!context.mounted) return;
                  userProvider.clearUser();
                  Navigator.of(context, rootNavigator: true).pop(); // 로딩창 닫기

                  // 4. 로그인 화면으로 이동
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('안전하게 탈퇴 처리되었습니다.')));

                } catch (e) {
                  if (!context.mounted) return;
                  Navigator.of(context, rootNavigator: true).pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ 탈퇴 처리 중 오류가 발생했습니다.')));
                }
              },
              child: const Text('탈퇴하기', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final cardColor = Theme.of(context).cardColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark; 

    final userProfile = Provider.of<UserProvider>(context).user; 

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
                            userProfile.email.isEmpty ? "이메일 정보 없음" : userProfile.email,
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
            
            Text(
              '내 정보 관리', 
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
                  ValueListenableBuilder<String>(
                    valueListenable: SharedData.vehicleNumber,
                    builder: (context, vehicleNum, child) {
                      return _buildMenuTile(
                        context: context,
                        isDarkMode: isDarkMode, 
                        icon: Icons.directions_car_outlined, 
                        title: '차량 등록 / 관리', 
                        subtitle: vehicleNum, 
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VehicleRegistrationScreen())),
                      );
                    },
                  ),
                  Divider(height: 1, indent: 56, color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
                  
                  ValueListenableBuilder<String>(
                    valueListenable: SharedData.paymentMethod,
                    builder: (context, currentMethod, child) {
                      return _buildMenuTile(
                        context: context,
                        isDarkMode: isDarkMode,
                        icon: Icons.credit_card, 
                        title: '결제 수단 관리', 
                        subtitle: currentMethod, 
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentMethodScreen())),
                      );
                    },
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
            
            Text(
              '고객 지원', 
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

            // 🔥 하단 로그아웃 및 회원탈퇴 버튼 영역
            Column(
              children: [
                Center(
                  child: TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('로그아웃', style: TextStyle(fontWeight: FontWeight.bold)),
                            content: const Text('정말 로그아웃하시겠습니까?\n다음번 실행 시 다시 로그인해야 합니다.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('취소', style: TextStyle(color: Colors.grey)),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _handleLogout(context);
                                },
                                child: const Text('로그아웃', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Text('로그아웃', style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey, fontSize: 16)),
                  ),
                ),
                
                // 🔥 회원탈퇴 버튼 추가
                Center(
                  child: TextButton(
                    onPressed: () => _showDeleteAccountDialog(context),
                    child: Text(
                      '회원탈퇴', 
                      style: TextStyle(
                        color: Colors.redAccent.withValues(alpha: 0.8), 
                        fontSize: 14, 
                        decoration: TextDecoration.underline
                      )
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

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