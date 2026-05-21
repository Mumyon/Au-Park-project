import 'package:flutter/material.dart';

class ParkingInfoScreen extends StatelessWidget {
  const ParkingInfoScreen({super.key});

  // 결제 바텀 시트를 띄우는 함수
  void _showPaymentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 내용에 맞게 높이 조절
      backgroundColor: Colors.transparent, // 모서리 둥글게 하기 위해 투명 처리
      builder: (context) => const PaymentSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    // 배경색을 옅은 회색으로 맞춤
    return Container(
      color: Colors.transparent,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '이용 중인 주차 정보', 
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 24),
            
            // 메인 주차 정보 카드
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 차량 번호 표시 섹션
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      '12가 3456', 
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 상태 메시지
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text('자동 결제 시스템 작동 중', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(height: 1),
                  ),
                  
                  // 주차 상세 정보
                  _buildInfoDetail('주차 위치', '본관 주차장'),
                  const SizedBox(height: 16),
                  _buildInfoDetail('입차 시간', '오후 08:52'),
                  const SizedBox(height: 16),
                  _buildInfoDetail('경과 시간', '01시간 32분'),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Divider(height: 1, color: Colors.grey.shade300),
                  ),
                  
                  // 요금 정보
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('실시간 예상 요금', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('5,000원', style: TextStyle(fontSize: 26, color: primaryColor, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // 즉시 결제 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showPaymentSheet(context),
                      icon: const Icon(Icons.credit_card, color: Colors.white),
                      label: const Text('즉시 정산하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // 안내 문구 영역
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.black54, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '결제 수단이 등록되어 있으면 출차 시 자동으로 정산됩니다. 미리 정산을 원하시면 위 버튼을 눌러주세요.',
                      style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 상세 정보 텍스트 한 줄을 만들어주는 함수
  Widget _buildInfoDetail(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 15, color: Colors.black54)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
      ],
    );
  }
}

// ----------------------------------------------------------------
// 팝업으로 올라오는 결제 바텀 시트
// ----------------------------------------------------------------
class PaymentSheet extends StatelessWidget {
  const PaymentSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min, // 내용물 크기만큼만 높이 차지
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 바텀 시트 상단 손잡이(핸들) 모양
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const Text('주차 요금 정산', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            
            // 결제 요약 박스
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _buildSheetInfoRow('차량 번호', '12가 3456'),
                  const SizedBox(height: 12),
                  _buildSheetInfoRow('이용 시간', '01시간 32분'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1),
                  ),
                  _buildSheetInfoRow('최종 결제 금액', '5,000원', isBold: true, valueColor: primaryColor),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            const Text('결제 수단 선택', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            
            // 결제 수단 리스트 (테스트용)
            _buildPaymentMethod(Icons.credit_card, '신한카드 (**** 1234)', true, primaryColor),
            _buildPaymentMethod(Icons.account_balance_wallet, '카카오페이', false, primaryColor),
            
            const SizedBox(height: 32),
            
            // 최종 결제 버튼
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // 시트 닫기
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('결제가 완료되었습니다.'), backgroundColor: Colors.green),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                elevation: 0,
              ),
              child: const Text('5,000원 결제하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetInfoRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 15)),
        Text(
          value, 
          style: TextStyle(
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w600, 
            fontSize: isBold ? 20 : 16,
            color: valueColor ?? Colors.black87,
          )
        ),
      ],
    );
  }

  Widget _buildPaymentMethod(IconData icon, String label, bool isSelected, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade300, width: isSelected ? 2 : 1),
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? primaryColor.withValues(alpha: 0.05) : Colors.white,
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? primaryColor : Colors.grey),
        title: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        trailing: isSelected ? Icon(Icons.check_circle, color: primaryColor) : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}