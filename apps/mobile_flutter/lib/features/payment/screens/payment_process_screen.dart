import 'package:flutter/material.dart';
import 'package:iamport_flutter/iamport_payment.dart';
import 'package:iamport_flutter/model/payment_data.dart';
import '../../../core/shared_data.dart';

class PaymentProcessScreen extends StatelessWidget {
  const PaymentProcessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 현재 등록된 차량 번호 가져오기
    final currentVehicle = SharedData.vehicleNumber.value;

    return IamportPayment(
      appBar: AppBar(
        title: const Text('주차 요금 사전 정산', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      // 결제창이 뜨기 전 잠깐 보여줄 로딩 화면
      initialChild: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('안전하게 결제 정보를 불러오는 중입니다...', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
      // 가맹점 식별코드 (포트원 공용 테스트 코드입니다)
      userCode: 'imp14397622',
      // 결제 데이터 세팅
      data: PaymentData(
        pg: 'html5_inicis', // PG사 (이니시스 테스트)
        payMethod: 'card',  // 결제수단 (신용카드)
        name: 'Au-Park 사전 정산 ($currentVehicle)', // 주문명
        merchantUid: 'mid_${DateTime.now().millisecondsSinceEpoch}', // 고유 주문번호
        amount: 1000, // 결제 금액 (테스트용 1000원)
        buyerName: 'Au-Park 사용자',
        buyerTel: '010-1234-5678',
        appScheme: 'aupark', // 앱으로 다시 돌아오기 위한 스킴 (AndroidManifest에 등록한 이름)
      ),
      // 결제가 끝나면 실행될 로직
      callback: (Map<String, String> result) {
        // 뒤로 가기(홈 화면으로 복귀)
        Navigator.pop(context);

        // 결제 성공 여부에 따라 알림창 띄우기
        if (result['imp_success'] == 'true') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ [$currentVehicle] 차량의 정산이 완료되었습니다! (차단기 개방)'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ 결제 실패: ${result['error_msg'] ?? '알 수 없는 오류'}'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }
}