import 'package:flutter/material.dart';
import 'payment_process_screen.dart'; // 🔥 추가

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  // 등록된 카드 목록 (테스트용 임시 데이터)
  final List<Map<String, dynamic>> _cards = [
    {
      'company': '신한카드',
      'number': '**** **** **** 1234',
      'color1': const Color(0xFF1E3C72),
      'color2': const Color(0xFF2A5298),
      'isDefault': true, // 기본 결제 수단
    },
    {
      'company': '국민카드',
      'number': '**** **** **** 5678',
      'color1': const Color(0xFF564C47),
      'color2': const Color(0xFF72655F),
      'isDefault': false,
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('결제 수단 관리', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '주차 요금 자동 정산을 위한\n결제 수단을 관리하세요.',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.4),
            ),
            const SizedBox(height: 32),

            // 등록된 카드 리스트 렌더링
            ..._cards.asMap().entries.map((entry) {
              int index = entry.key;
              var card = entry.value;
              return _buildCreditCard(card, index);
            }),

            const SizedBox(height: 24),

            // 카드 추가 버튼 (점선 테두리 디자인)
            InkWell(
              onTap: () {
                // 🔥 임시 스낵바를 지우고, 진짜 포트원 결제 화면으로 이동시킵니다!
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PaymentProcessScreen()),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid), // 나중에 점선 패키지로 교체 가능
                ),
                child: Column(
                  children: [
                    Icon(Icons.add_circle_outline, size: 32, color: Colors.grey.shade600),
                    const SizedBox(height: 8),
                    Text('새로운 결제 수단 추가', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 진짜 신용카드처럼 보이는 UI 위젯
  Widget _buildCreditCard(Map<String, dynamic> card, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [card['color1'], card['color2']], // 카드별 고유 색상 그라데이션
        ),
        boxShadow: [
          BoxShadow(
            color: card['color1'].withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 카드 배경 무늬 (투명한 원)
          Positioned(
            right: -40,
            bottom: -40,
            child: Container(
              width: 150, height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          
          // 카드 내용물
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      card['company'],
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    if (card['isDefault'])
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                        child: const Text('기본 결제', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                // IC칩 아이콘 모양
                Container(
                  width: 40, height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      card['number'],
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'Courier', letterSpacing: 2),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onPressed: () {
                        // TODO: 카드 삭제 또는 기본수단 변경 옵션 띄우기
                      },
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}