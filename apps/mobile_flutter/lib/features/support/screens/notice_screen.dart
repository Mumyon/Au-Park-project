import 'package:flutter/material.dart';

class NoticeScreen extends StatelessWidget {
  const NoticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> notices = [
      {'title': '[안내] 학생회관 주차장 공사 안내', 'date': '2026.05.15', 'content': '학생회관 주차장 바닥 평탄화 및 도색 공사로 인해 5월 20일부터 22일까지 해당 주차장 이용이 전면 통제됩니다. 본관 주차장이나 정문 주차장을 이용해 주시기 바랍니다.'},
      {'title': '[업데이트] v1.0.1 자동 정산 시스템 안정화', 'date': '2026.05.10', 'content': '출차 시 간헐적으로 발생하던 정산 지연 현상을 개선했습니다. 앱을 최신 버전으로 업데이트해 주시기 바랍니다.'},
      {'title': '[오픈] Au-Park 안산대학교 주차 시스템 오픈', 'date': '2026.05.01', 'content': '무정차 주차 관제 시스템 Au-Park가 정식 오픈했습니다. 차량 번호와 결제 수단을 미리 등록하시면 출차 시 정산소를 거치지 않고 바로 나가실 수 있습니다.'},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('공지사항', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: ListView.separated(
        itemCount: notices.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
        itemBuilder: (context, index) {
          final notice = notices[index];
          return Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent), // 펼쳤을 때 생기는 위아래 선 제거
            child: ExpansionTile(
              title: Text(notice['title']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              subtitle: Text(notice['date']!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Text(notice['content']!, style: const TextStyle(height: 1.6, color: Colors.black87, fontSize: 14)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}