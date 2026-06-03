import 'package:flutter/material.dart';

class AllMenuScreen extends StatelessWidget {
  const AllMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('전체 서비스', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildMenuSection('주차장 이용', [
            _buildMenuItem(Icons.search, '주차장 찾기'),
            _buildMenuItem(Icons.history, '주차 이용 내역'),
          ]),
          const SizedBox(height: 32),
          _buildMenuSection('결제 및 혜택', [
            _buildMenuItem(Icons.credit_card, '결제 수단 관리'),
            _buildMenuItem(Icons.confirmation_num_outlined, '할인 쿠폰'),
            _buildMenuItem(Icons.stars_outlined, 'Au-Park 포인트'),
          ]),
        ],
      ),
    );
  }

  Widget _buildMenuSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        ...items,
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, size: 24),
      title: Text(label, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      contentPadding: EdgeInsets.zero,
      onTap: () {},
    );
  }
}
