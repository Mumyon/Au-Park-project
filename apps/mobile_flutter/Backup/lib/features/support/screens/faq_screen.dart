import 'package:flutter/material.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> faqs = [
      {'q': '결제 수단을 등록하지 않으면 출차가 안 되나요?', 'a': '출차 자체는 가능하지만, 정산소 기기에서 직접 카드를 꽂고 결제해야 하므로 시간이 소요됩니다. 미리 등록하시면 하이패스처럼 바로 통과하실 수 있습니다.'},
      {'q': '차량 번호판 인식이 안 되면 어떻게 하나요?', 'a': '우천이나 폭설 등 기상 악화로 번호판 인식이 실패할 경우, 차단기 앞의 호출 버튼을 눌러 관리실에 문의해 주시면 즉시 조치해 드립니다.'},
      {'q': '가족 차량을 제 계정에 등록해도 되나요?', 'a': '네, 가능합니다. 차량 등록 화면에서 소유주 명의를 "가족"으로 선택하시고 등록하시면 본인의 결제 수단으로 요금이 정산됩니다.'},
      {'q': '할인권(웹할인)은 어떻게 적용하나요?', 'a': '학과 사무실이나 방문 부서에서 차량 번호로 웹할인을 넣어주시면, 앱의 예상 요금에 자동으로 할인이 적용되어 남은 금액만 결제됩니다.'},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('자주 묻는 질문 (FAQ)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: ListView.builder(
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          final faq = faqs[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                iconColor: Theme.of(context).primaryColor,
                title: Row(
                  children: [
                    Text('Q. ', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                    Expanded(child: Text(faq['q']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                  ],
                ),
                childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('A. ', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                      Expanded(child: Text(faq['a']!, style: const TextStyle(height: 1.5, color: Colors.black87, fontSize: 14))),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}