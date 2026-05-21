import 'package:flutter/material.dart';

class ParkingStatusScreen extends StatelessWidget {
  const ParkingStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('실시간 주차 현황', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('마지막 업데이트: 방금 전', style: TextStyle(color: isDarkMode ? Colors.grey : Colors.grey.shade600)),
          const SizedBox(height: 24),
          _buildParkingCard(context, '정문 제1주차장', 45, 100, Colors.orange),
          const SizedBox(height: 16),
          _buildParkingCard(context, '본관 주차장', 98, 100, Colors.red),
          const SizedBox(height: 16),
          _buildParkingCard(context, '학생회관 주차장', 35, 50, Colors.green),
        ],
      ),
    );
  }

  Widget _buildParkingCard(BuildContext context, String name, int cur, int max, Color color) {
    final cardColor = Theme.of(context).cardColor;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(width: 5, height: 45, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                const SizedBox(height: 4),
                Text('현재 $cur대 / 총 $max대', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          Text('${((cur / max) * 100).toInt()}%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }
}