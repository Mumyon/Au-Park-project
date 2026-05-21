import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // 부모 Scaffold 색상을 따라가도록 투명하게 설정
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔥 검색창 제거됨. 상단 간격을 위해 SizedBox 추가
            const SizedBox(height: 30), 

            // 메인 서비스 그리드 (아이콘 4개)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(), // 내부 스크롤 방지
                crossAxisCount: 4,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                children: [
                  _buildServiceIcon(context, Icons.directions_car, '차량 등록'),
                  _buildServiceIcon(context, Icons.payment, '즉시 결제'),
                  _buildServiceIcon(context, Icons.map, '주차 지도'),
                  _buildServiceIcon(context, Icons.history, '이용 내역'),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // 🔥 하단 실시간 주차 현황 리스트 제거됨
          ],
        ),
      ),
    );
  }

  // 🔥 오버플로우 에러를 해결하기 위해 수정한 아이콘 위젯
  Widget _buildServiceIcon(BuildContext context, IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            // 🔥 'withValues' 파란 잔소리가 뜨지 않도록 최신 문법으로 적용
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1), 
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor, size: 28),
        ),
        // 🔥 이전 10에서 간격을 2로 줄였습니다. 이제 글자가 칸을 벗어나지 않습니다.
        const SizedBox(height: 2), 
        Text(
          label, 
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center, // 두 줄이 되어도 가운데 정렬
        ),
      ],
    );
  }
}