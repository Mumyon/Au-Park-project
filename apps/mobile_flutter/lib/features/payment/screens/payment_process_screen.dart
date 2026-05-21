import 'package:flutter/material.dart';
import 'package:iamport_flutter/iamport_payment.dart';
import 'package:iamport_flutter/model/payment_data.dart';

class PaymentProcessScreen extends StatelessWidget {
  const PaymentProcessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return IamportPayment(
      appBar: AppBar(
        title: const Text('포트원 테스트 결제', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 0,
      ),
      // 결제창이 뜨기 전에 보여줄 로딩 화면
      initialChild: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('안전한 결제 환경을 불러오는 중입니다...', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
      // 🔥 포트원 관리자 페이지에서 발급받는 '가맹점 식별코드' (테스트용 공용 코드 사용)
      userCode: 'imp52504302', 
      // 🔥 결제할 데이터 세팅
      data: PaymentData(
        pg: 'html5_inicis', // PG사 (KG이니시스)
        payMethod: 'card',  // 결제수단 (신용카드)
        name: 'Au-Park 주차 요금 테스트', // 결제창에 뜰 상품명
        merchantUid: 'mid_${DateTime.now().millisecondsSinceEpoch}', // 고유 주문번호 (임의 생성)
        amount: 100, // 결제 금액 (100원)
        buyerName: '영진', // 구매자 이름
        buyerTel: '010-1234-5678', // 구매자 전화번호
        buyerEmail: 'youngjin@ansan.ac.kr',
        appScheme: 'aupark', // 결제 후 앱으로 돌아오기 위한 스키마
      ),
      // 🔥 결제가 끝나면 실행될 함수
      callback: (Map<String, String> result) {
        // 성공 여부 판별 (포트원에서 'true' 또는 'false'를 문자로 보내줌)
        bool isSuccess = result['imp_success'] == 'true';
        
        // 결제 완료 후 마이페이지로 돌려보내기 전에 결과창 띄우기
        Navigator.pop(context); // 결제창 닫기
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isSuccess ? '결제가 완료되었습니다! 💳' : '결제를 취소했거나 실패했습니다.'),
            backgroundColor: isSuccess ? Colors.green : Colors.red,
          ),
        );
      },
    );
  }
}