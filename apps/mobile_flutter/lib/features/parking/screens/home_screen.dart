import 'package:flutter/material.dart';
import '../../../core/shared_data.dart'; 
import '../../vehicle/screens/vehicle_registration_screen.dart';
import '../../payment/screens/payment_method_screen.dart';
import '../../payment/screens/parking_history_screen.dart';
import '../../support/screens/notice_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _processDirectPayment(BuildContext context, String cardName) {
    Navigator.pop(context); 

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('안전하게 결제하는 중...', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); 

      final currentVehicle = SharedData.vehicleNumber.value;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $cardName(으)로 [$currentVehicle] 정산이 완료되었습니다! (차단기 개방)'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // 결제가 완료되면 하드웨어 연동 전 임시로 주차 상태를 false로 변경해줍니다.
      SharedData.isCurrentlyParked.value = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            
            // 🔥 핵심: 주차 상태(isCurrentlyParked)를 감지하여 화면을 갈아끼우는 곳
            ValueListenableBuilder<bool>(
              valueListenable: SharedData.isCurrentlyParked,
              builder: (context, isParked, child) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isParked 
                      ? ValueListenableBuilder<String>(
                          key: const ValueKey('parked'),
                          valueListenable: SharedData.vehicleNumber,
                          builder: (context, currentVehicleNumber, child) {
                            return _buildActiveParkingCard(context, currentVehicleNumber);
                          },
                        )
                      : _buildNotParkingState(context), // 주차 중이 아닐 때의 화면
                );
              },
            ),

            const SizedBox(height: 32),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                '빠른 바로가기',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,     
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: [
                  _buildServiceIcon(
                    context: context,
                    icon: Icons.directions_car,
                    label: '차량 등록',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const VehicleRegistrationScreen()));
                    },
                  ),
                  _buildServiceIcon(
                    context: context,
                    icon: Icons.credit_card,
                    label: '결제 수단',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentMethodScreen()));
                    },
                  ),
                  _buildServiceIcon(
                    context: context,
                    icon: Icons.campaign_outlined,
                    label: '공지사항',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const NoticeScreen()));
                    },
                  ),
                  _buildServiceIcon(
                    context: context,
                    icon: Icons.receipt_long_outlined,
                    label: '이용 내역',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ParkingHistoryScreen()));
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 🚨 개발/테스트용 임시 버튼: DB 연동 전까지 주차 상태를 강제로 바꿔볼 수 있습니다.
            Center(
              child: TextButton.icon(
                onPressed: () {
                  SharedData.isCurrentlyParked.value = !SharedData.isCurrentlyParked.value;
                }, 
                icon: const Icon(Icons.swap_horiz, color: Colors.grey),
                label: const Text('개발용: 주차 상태 강제 전환', style: TextStyle(color: Colors.grey)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 🔴 [상태 1] 주차 중이 아닐 때 보여줄 텅 빈 화면 (버튼 제거 버전)
  Widget _buildNotParkingState(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      key: const ValueKey('not_parked'),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05), blurRadius: 20, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.local_parking, size: 48, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          const Text('현재 이용 중인 주차장이 없습니다.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            '차량이 스마트 존에 입차되면\n자동으로 현황판이 표시됩니다.', 
            textAlign: TextAlign.center, 
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500, height: 1.4)
          ),
        ],
      ),
    );
  }

  // 🟢 [상태 2] 주차 중일 때 보여줄 화려한 현황판 카드
  Widget _buildActiveParkingCard(BuildContext context, String vehicleNum) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.local_parking, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('주차 이용 중', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(20)),
                child: const Text('입차됨', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 24),
          
          const Text('정문 제1주차장', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('차량 번호: $vehicleNum', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('입차 시간: 10:30 AM', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('현재 요금 ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  Text('3,500원', style: TextStyle(color: Colors.yellowAccent, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          ElevatedButton(
            onPressed: () {
              final currentVehicle = SharedData.vehicleNumber.value;
    
              if (currentVehicle == "등록된 차량 없음" || currentVehicle.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⚠️ 먼저 차량을 등록해야 사전 정산이 가능합니다.'),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (BuildContext context) {
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('결제 수단 선택', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('[$currentVehicle] 차량의 주차 요금 3,500원이 자동 결제됩니다.', style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 24),
                        
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.credit_card, color: Colors.blue, size: 32),
                          title: const Text('신한카드 (Deep Dream)', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('****-****-****-1234'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _processDirectPayment(context, '신한카드'),
                        ),
                        const Divider(),
                        
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.account_balance_wallet, color: Colors.yellow, size: 32),
                          title: const Text('카카오페이', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('간편결제'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _processDirectPayment(context, '카카오페이'),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              );
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('사전 정산하기', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
    );
  }

  // 빠른 메뉴 아이콘 헬퍼 함수
  Widget _buildServiceIcon({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDarkMode ? Colors.white : Theme.of(context).primaryColor;
    final bgColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.15)
        : Theme.of(context).primaryColor.withValues(alpha: 0.1);
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return InkWell(
      onTap: onTap, 
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor, 
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 6), 
          Text(
            label, 
            style: TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}