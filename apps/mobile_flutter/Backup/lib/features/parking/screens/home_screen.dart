import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 배경색을 MainNavigationScreen의 Scaffold 배경색과 맞추기 위해 투명하게 설정
    return Container(
      color: Colors.transparent, 
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '교내 주차장 실시간 현황',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '마지막 업데이트: 방금 전',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            
            // 각 주차장의 상태를 보여주는 카드 리스트
            _buildStatusCard('정문 제1주차장', 45, 100),
            const SizedBox(height: 16),
            _buildStatusCard('본관 주차장', 98, 100),
            const SizedBox(height: 16),
            _buildStatusCard('학생회관 주차장', 35, 50),
          ],
        ),
      ),
    );
  }

  // 주차장 혼잡도 카드 위젯
  Widget _buildStatusCard(String name, int current, int max) {
    // 혼잡도 계산 (0.0 ~ 1.0)
    double ratio = current / max;
    
    // 비율에 따른 상태 텍스트 및 색상 결정
    String statusText;
    Color statusColor; // 기준이 되는 진한 색
    
    if (ratio >= 0.9) {
      statusText = '혼잡';
      statusColor = Colors.red;
    } else if (ratio >= 0.7) {
      statusText = '보통';
      statusColor = Colors.orange.shade700; // 가독성을 위해 살짝 진한 오렌지
    } else {
      statusText = '여유';
      statusColor = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, // 카드는 흰색
        borderRadius: BorderRadius.circular(16),
        // 그림자를 더 부드럽게 수정
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              
              // 🔥 수정된 우측 상태 알림 배지 (색상을 연하게 변경)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  // 배경색은 기준 색상에 투명도를 많이 줌 (아주 연해짐)
                  color: statusColor.withValues(alpha: 0.1), 
                  borderRadius: BorderRadius.circular(6), // 모서리가 살짝 둥근 네모
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    // 글자 색상은 기준 색상으로 진하게
                    color: statusColor, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          
          // 게이지바 (모두 동일한 진회색으로 통일)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: Colors.grey.shade100, // 배경색을 더 연하게 수정
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade400), // 채워지는 색을 살짝 연한 회색으로 수정
            ),
          ),
          const SizedBox(height: 14),
          
          // 숫자 텍스트
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '$current',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
              ),
              Text(
                ' / $max 대',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}