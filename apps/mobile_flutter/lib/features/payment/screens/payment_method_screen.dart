import 'package:flutter/material.dart';
import 'package:iamport_flutter/iamport_payment.dart';
import 'package:iamport_flutter/model/payment_data.dart';

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  // 🔥 등록된 카드 및 결제수단 리스트 (기본값 세팅)
  List<Map<String, String>> registeredMethods = [
    {'name': '신한카드 (끝자리: 1234)', 'type': 'card'},
  ];

  // 🗑️ 결제 수단 삭제 함수
  void _deletePaymentMethod(int index) {
    final deletedName = registeredMethods[index]['name'];
    setState(() {
      registeredMethods.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🗑️ $deletedName 수단이 삭제되었습니다.'),
        duration: const Duration(milliseconds: 1000),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ➕ 결제 수단 로컬 리스트에 추가 함수
  void _addPaymentMethod(String name, String type) {
    setState(() {
      registeredMethods.add({
        'name': name,
        'type': type,
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ $name이(가) 성공적으로 등록되었습니다!'),
        backgroundColor: Colors.green,
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 포트원 실제 결제창 호출 함수
  void _startPortOnePayment({
    required BuildContext context,
    required String pgCode,
    required String payMethod,
    required String pgName,
    required bool isBilling,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IamportPayment(
          appBar: AppBar(
            title: Text('$pgName 등록 (포트원)', style: const TextStyle(color: Colors.black87)),
            backgroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.black87),
            elevation: 0,
          ),
          initialChild: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('안전 결제창을 불러오는 중입니다...', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
          userCode: 'imp77826283', 
          
          data: PaymentData(
            pg: pgCode, 
            payMethod: payMethod, 
            name: 'Au-Park 주차 결제수단 등록 테스트',
            merchantUid: 'mid_${DateTime.now().millisecondsSinceEpoch}',
            amount: 100, 
            customerUid: isBilling ? 'user_youngjin_001' : null, 
            buyerName: '영진(테스트)',
            buyerTel: '010-1234-5678',
            buyerEmail: 'youngjin@ansan.ac.kr',
            appScheme: 'aupark', 
          ),
          
          callback: (Map<String, String> result) {
            Navigator.pop(context);
            if (result['imp_success'] == 'true') {
              // 실제 결제창 성공 시 리스트에 추가 작동
              _addPaymentMethod('$pgName 등록완료', pgCode.contains('tosspay') ? 'toss' : 'kakao');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ 결제 실패: ${result['error_msg'] ?? '알 수 없는 오류'}'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  // 하단 결제 수단 선택창 (BottomSheet)
  void _showPaymentSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('결제 수단 선택', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                
                // 1. 카카오페이 실제 연동 버튼
                ListTile(
                  leading: const Icon(Icons.chat_bubble, color: Colors.amber, size: 28),
                  title: const Text('카카오페이 (실제 포트원 연동)', style: TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(context);
                    _startPortOnePayment(
                      context: context,
                      pgCode: 'kakaopay',
                      payMethod: 'card', 
                      pgName: '카카오페이',
                      isBilling: true,
                    );
                  },
                ),
                Divider(color: Colors.grey.shade200, height: 1),
                
                // 2. 토스페이 실제 연동 버튼
                ListTile(
                  leading: const Icon(Icons.water_drop, color: Colors.blueAccent, size: 28),
                  title: const Text('토스페이 (실제 포트원 연동)', style: TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(context);
                    _startPortOnePayment(
                      context: context,
                      pgCode: 'tosspay_v2.tosstest',
                      payMethod: 'tosspay', 
                      pgName: '토스페이',
                      isBilling: false,
                    );
                  },
                ),
                Divider(color: Colors.grey.shade200, height: 1),

                // 🔥 3. 시뮬레이터 전용 가상 등록 버튼 (발표 및 데모용 패스웨이)
                ListTile(
                  leading: Icon(Icons.add_task_rounded, color: Theme.of(context).primaryColor, size: 28),
                  title: Text(
                    '시뮬레이터 전용 즉시 등록 (테스트용)', 
                    style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)
                  ),
                  subtitle: const Text('실제 PG창을 거치지 않고 가상 카드를 즉시 추가합니다.'),
                  onTap: () {
                    Navigator.pop(context);
                    // 가상 카드 추가 테스트 작동
                    int nextNum = registeredMethods.length + 1;
                    _addPaymentMethod('테스트 카드 $nextNum (등록완료)', 'mock');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('결제 수단 관리', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '등록된 결제 수단', 
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.grey.shade300 : Colors.black54)
            ),
            const SizedBox(height: 16),
            
            // 리스트 상태에 따라 동적으로 화면 렌더링
            if (registeredMethods.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    '등록된 결제 수단이 없습니다.\n아래 버튼을 눌러 결제 수단을 추가해 주세요.', 
                    style: TextStyle(color: Colors.grey.shade500, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: registeredMethods.length,
                  itemBuilder: (context, index) {
                    return _buildCardTile(
                      index: index, 
                      cardName: registeredMethods[index]['name']!, 
                      type: registeredMethods[index]['type']!,
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),
            
            ElevatedButton.icon(
              onPressed: () => _showPaymentSelector(context),
              icon: const Icon(Icons.add_card),
              label: const Text('새 결제 수단 추가하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.grey),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '등록하신 결제 수단은 출차 시 자동 정산을 위해 사용되며, 포트원(PortOne)의 안전한 보안 시스템을 통해 암호화되어 관리됩니다.',
                      style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.5),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // 디자인 컴포넌트: 카드 타일 위젯
  Widget _buildCardTile({required int index, required String cardName, required String type}) {
    IconData cardIcon = Icons.credit_card;
    Color iconColor = Theme.of(context).primaryColor;

    if (type == 'kakao') {
      cardIcon = Icons.chat_bubble;
      iconColor = Colors.amber;
    } else if (type == 'toss') {
      cardIcon = Icons.water_drop;
      iconColor = Colors.blueAccent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        // ignore: deprecated_member_use
        border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(cardIcon, color: iconColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cardName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                if (index == 0) const SizedBox(height: 4),
                if (index == 0)
                  const Text('기본 결제 수단', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
          // 🗑️ 오른쪽 끝 삭제 버튼 고유 인덱스 매칭 연동 완료
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 24),
            onPressed: () => _deletePaymentMethod(index),
          ),
        ],
      ),
    );
  }
}