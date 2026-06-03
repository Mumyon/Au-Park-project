import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';

class ParkingHistoryScreen extends StatefulWidget {
  const ParkingHistoryScreen({super.key});

  @override
  State<ParkingHistoryScreen> createState() => _ParkingHistoryScreenState();
}

class _ParkingHistoryScreenState extends State<ParkingHistoryScreen> {
  final ApiClient _apiClient = ApiClient();
  List<Map<String, dynamic>> _historyData = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
  }

  Future<void> _loadPaymentHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';
      if (userId.isEmpty) {
        throw ApiException('로그인 정보가 없습니다.');
      }

      final payments = await _apiClient.listPayments(userId);
      if (!mounted) return;
      setState(() {
        _historyData = payments.whereType<Map<String, dynamic>>().toList();
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
        _errorMessage = '주차 이용 내역을 불러오지 못했습니다.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('주차 이용 내역', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            tooltip: '새로고침',
            onPressed: _loadPaymentHistory,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(primaryColor),
    );
  }

  Widget _buildBody(Color primaryColor) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
        ),
      );
    }

    if (_historyData.isEmpty) {
      return const Center(child: Text('아직 주차 이용 내역이 없습니다.'));
    }

    return RefreshIndicator(
      onRefresh: _loadPaymentHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _historyData.length,
        itemBuilder: (context, index) {
          return _buildHistoryCard(_historyData[index], primaryColor);
        },
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> data, Color primaryColor) {
    final entryAt = _parseDateTime(data['entry_at']);
    final exitAt = _parseDateTime(data['exit_at'] ?? data['paid_at']);
    final date = data['paid_date']?.toString() ?? _formatDate(exitAt ?? entryAt);
    final entryTime = _formatTime(entryAt);
    final exitTime = _formatTime(exitAt);
    final duration = _formatDuration(data['duration_minutes']);
    final price = _formatWon(data['amount']);
    final location = data['lot_name']?.toString() ?? '정문 제1주차장';
    final carNumber = data['plate_number']?.toString() ?? '차량 정보 없음';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(date, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('결제완료', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.local_parking, color: primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(location, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(carNumber, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('입차', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(entryTime, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const Icon(Icons.arrow_forward, color: Colors.grey, size: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('정산', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(exitTime, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('총 이용', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(duration, style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('결제 금액', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              Text(price, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}.$month.$day';
  }

  String _formatTime(DateTime? value) {
    if (value == null) return '-';
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDuration(dynamic value) {
    final minutes = value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours == 0) return '$remainingMinutes분';
    if (remainingMinutes == 0) return '$hours시간';
    return '$hours시간 $remainingMinutes분';
  }

  String _formatWon(dynamic value) {
    final amount = value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;
    final text = amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
    return '$text원';
  }
}
