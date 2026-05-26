import 'package:flutter/material.dart';
import '../../../core/shared_data.dart';

class ParkingInfoScreen extends StatelessWidget {
  const ParkingInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('실시간 주차 정보', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: SharedData.isCurrentlyParked,
        builder: (context, isParked, child) {
          if (!isParked) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.no_sim_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    '현재 주차 이용 내역이 없습니다.',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text('현재 누적 주차 요금', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Text(
                        '3,500원',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                      ),
                      const SizedBox(height: 4),
                      const Text('기본 30분 1,000원 / 추가 10분 500원', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Text(
                  '상세 주차 정보',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.grey.shade300 : Colors.black54),
                ),
                const SizedBox(height: 12),

                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      ValueListenableBuilder<String>(
                        valueListenable: SharedData.vehicleNumber,
                        builder: (context, vehicleNum, child) {
                          return _buildInfoRow(
                            icon: Icons.directions_car_filled_outlined,
                            label: '이용 차량',
                            value: vehicleNum,
                            valueColor: Theme.of(context).primaryColor,
                          );
                        },
                      ),
                      _buildDivider(isDarkMode),
                      _buildInfoRow(
                        icon: Icons.location_on_outlined,
                        label: '주차 위치',
                        value: '정문 제1주차장 (A구역)',
                      ),
                      _buildDivider(isDarkMode),
                      _buildInfoRow(
                        icon: Icons.access_time,
                        label: '입차 시간',
                        value: '2026.05.21 10:30 AM',
                      ),
                      _buildDivider(isDarkMode),
                      _buildInfoRow(
                        icon: Icons.timer_outlined,
                        label: '이용 시간',
                        value: '1시간 20분째 이용 중',
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.build_circle_outlined, color: Colors.orange, size: 18),
                          SizedBox(width: 8),
                          Text('시연 제어판 (발표용)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('앱 상태를 주차 완료(출차) 상태로 가상 변경:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              SharedData.isCurrentlyParked.value = false;
                            },
                            child: const Text('출차 처리', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          )
                        ],
                      )
                    ],
                  ),
                )
              ], // 🔥 이 부분의 괄호 짝을 완벽하게 맞췄습니다!
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 22),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDarkMode) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 20,
      endIndent: 20,
      color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
    );
  }
}