import 'package:flutter/material.dart';

class ParkingInfoScreen extends StatelessWidget {
  const ParkingInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final cardColor = Theme.of(context).cardColor; // 🔥 다크/라이트 자동 변환 박스 색상
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent, // 네비게이션 배경 동기화
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '실시간 주차 정보', 
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 24),

            // 🚗 현재 주차 상태 카드 상자
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor, // 🔥 흰색 고정 해제
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('현재 주차 차량', style: TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w500)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          '입차 완료', 
                          style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold)
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '12가 3456', 
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)
                    ),
                  ),
                  const Divider(height: 40),
                  
                  // 주차 상세 내역 로우들
                  _buildInfoRow('주차 위치', '본관 정면 주차장', isDarkMode),
                  const SizedBox(height: 16),
                  _buildInfoRow('입차 시간', '2026.05.20 13:14', isDarkMode),
                  const SizedBox(height: 16),
                  _buildInfoRow('이용 시간', '1시간 14분째', isDarkMode),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('현재 주차 요금', style: TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w500)),
                      Text(
                        '3,500원', 
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: primaryColor)
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 안내 사항 상자
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: primaryColor, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '정산 후 15분 이내에 출차하지 않을 경우 추가 요금이 발생할 수 있습니다.',
                      style: TextStyle(
                        fontSize: 13, 
                        color: isDarkMode ? Colors.grey.shade400 : Colors.black54, 
                        height: 1.4
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),

            // 🔥 즉시 정산하기 버튼 (라이트/다크 무조건 뚜렷하게 선명화)
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('출차 전 즉시 정산 요청이 전송되었습니다. 💳')),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: primaryColor, // 선명한 남색
                foregroundColor: Colors.white, // 흰색 글자 고정
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text(
                '즉시 정산하기', 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w500)),
        Text(
          value, 
          style: TextStyle(
            fontSize: 16, 
            fontWeight: FontWeight.w600, 
            color: isDarkMode ? Colors.white.withValues(alpha: 0.9) : Colors.black87
          )
        ),
      ],
    );
  }
}