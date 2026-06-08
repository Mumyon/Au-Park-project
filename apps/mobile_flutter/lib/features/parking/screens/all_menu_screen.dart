import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AllMenuScreen extends StatelessWidget {
  const AllMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '정보',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildMenuSection('안산대 홈페이지 안내', [
            _buildMenuItem(
              Icons.search,
              '안산대 대표 홈페이지',
              url: 'https://www.ansan.ac.kr/www',
            ),
            _buildMenuItem(
              Icons.history,
              '안산대 주차 안내',
              url: 'https://www.ansan.ac.kr/www/content/158',
            ),
          ]),
          const SizedBox(height: 32),
          _buildMenuSection('개발자 정보', [
            _buildMenuItem(Icons.phone_android, '앱 정보'),
            _buildMenuItem(Icons.support_agent, '개발자 정보'),
          ]),
        ],
      ),
    );
  }

  Widget _buildMenuSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        ...items,
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String label, {String? url}) {
    return ListTile(
      leading: Icon(icon, size: 24),
      title: Text(label, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      contentPadding: EdgeInsets.zero,
      onTap: url == null ? null : () => _openUrl(url),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
