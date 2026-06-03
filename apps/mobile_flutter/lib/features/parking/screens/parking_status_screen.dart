import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';

class ParkingStatusScreen extends StatefulWidget {
  const ParkingStatusScreen({super.key});

  @override
  State<ParkingStatusScreen> createState() => _ParkingStatusScreenState();
}

class _ParkingStatusScreenState extends State<ParkingStatusScreen> {
  final ApiClient _apiClient = ApiClient();
  List<Map<String, dynamic>> _lots = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadParkingLots();
  }

  Future<void> _loadParkingLots() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final lots = await _apiClient.listParkingLots();
      if (!mounted) return;
      setState(() {
        _lots = lots.whereType<Map<String, dynamic>>().toList();
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '주차 현황 정보를 불러오지 못했습니다.';
        _isLoading = false;
      });
    }
  }

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
          
          // 🔥 마지막 업데이트 텍스트와 새로고침 버튼을 한 줄에 배치 (우측 끝 정렬)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '마지막 업데이트: 방금 전', 
                style: TextStyle(
                  fontSize: 14, 
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600
                ),
              ),
              // 🔄 새로고침 아이콘 버튼 추가
              IconButton(
                icon: Icon(Icons.refresh, color: Theme.of(context).primaryColor, size: 22),
                onPressed: () async {
                  await _loadParkingLots();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('주차 현황 정보를 새로고침했습니다. 🔄'),
                      duration: Duration(milliseconds: 800), // 빠르게 사라지도록 설정
                    ),
                  );
                },
                constraints: const BoxConstraints(), // 버튼 주변 불필요한 공백 제거
                padding: EdgeInsets.zero, // 텍스트와 높낮이를 딱 맞추기 위해 패딩 제로화
              ),
            ],
          ),
          const SizedBox(height: 20), // 레이아웃 균형을 위해 공백 소폭 조정
          
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent))),
            )
          else if (_lots.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(child: Text('등록된 주차장이 없습니다.')),
            )
          else
            ..._lots.map((lot) {
              final total = lot['total_slots'] as int? ?? 0;
              final available = lot['available_slots'] as int? ?? 0;
              final occupied = (total - available).clamp(0, total).toInt();
              final color = available == 0
                  ? Colors.red
                  : available <= (total * 0.3)
                      ? Colors.orange
                      : Colors.green;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildParkingCard(
                  context,
                  lot['name'] ?? lot['id'] ?? '주차장',
                  occupied,
                  total == 0 ? 1 : total,
                  color,
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildParkingCard(BuildContext context, String name, int cur, int max, Color color) {
    final cardColor = Theme.of(context).cardColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.02), 
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
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
