import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 스위치 상태값을 저장할 변수들
  bool _pushNotice = true;
  bool _pushEntryExit = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('앱 설정', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 20, top: 24, bottom: 8),
            child: Text('알림 설정', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Container(
            color: Colors.white,
            child: Column(
              children: [
                SwitchListTile(
                  activeColor: Theme.of(context).primaryColor,
                  title: const Text('공지사항 및 이벤트 알림', style: TextStyle(fontSize: 15)),
                  value: _pushNotice,
                  onChanged: (value) => setState(() => _pushNotice = value),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  activeColor: Theme.of(context).primaryColor,
                  title: const Text('입/출차 및 자동 결제 알림', style: TextStyle(fontSize: 15)),
                  subtitle: const Text('앱을 꺼둬도 스마트폰 푸시로 알려줍니다.', style: TextStyle(fontSize: 12)),
                  value: _pushEntryExit,
                  onChanged: (value) => setState(() => _pushEntryExit = value),
                ),
              ],
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.only(left: 20, top: 32, bottom: 8),
            child: Text('앱 정보', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Container(
            color: Colors.white,
            child: Column(
              children: [
                ListTile(
                  title: const Text('버전 정보', style: TextStyle(fontSize: 15)),
                  trailing: const Text('v1.0.0 (최신)', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('서비스 이용약관', style: TextStyle(fontSize: 15)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('개인정보 처리방침', style: TextStyle(fontSize: 15)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          // 회원 탈퇴 (무서운 버튼이라 빨간색 처리)
          TextButton(
            onPressed: () {},
            child: const Text('회원 탈퇴', style: TextStyle(color: Colors.redAccent, decoration: TextDecoration.underline)),
          )
        ],
      ),
    );
  }
}