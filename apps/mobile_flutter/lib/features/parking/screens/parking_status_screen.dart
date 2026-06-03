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
  Map<String, List<Map<String, dynamic>>> _slotsByLot = {};
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
      final parsedLots = lots.whereType<Map<String, dynamic>>().toList();
      final slotEntries = await Future.wait(
        parsedLots.map((lot) async {
          final lotId = lot['id']?.toString();
          if (lotId == null) return MapEntry('', <Map<String, dynamic>>[]);
          final slots = await _apiClient.listParkingSlots(lotId);
          return MapEntry(lotId, slots.whereType<Map<String, dynamic>>().toList());
        }),
      );
      if (!mounted) return;
      setState(() {
        _lots = parsedLots;
        _slotsByLot = Map.fromEntries(slotEntries.where((entry) => entry.key.isNotEmpty));
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('실시간 주차 현황', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
                      Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_seat,
                size: 18,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              const SizedBox(width: 6),
              Text(
                '좌석 현황 보기',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
              IconButton(
                tooltip: '새로고침',
                icon: Icon(Icons.refresh, color: theme.primaryColor, size: 22),
                onPressed: () async {
                  await _loadParkingLots();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('주차 현황 정보를 새로고침했습니다.'),
                      duration: Duration(milliseconds: 800),
                    ),
                  );
                },
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 20),
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
              final lotId = lot['id']?.toString();
              final slots = lotId == null ? <Map<String, dynamic>>[] : _slotsByLot[lotId] ?? [];
              final total = slots.isEmpty ? (lot['total_slots'] as int? ?? 0) : slots.length;
              final occupied = slots.isEmpty
                  ? ((total - (lot['available_slots'] as int? ?? 0)).clamp(0, total)).toInt()
                  : slots.where(_isOccupiedSlot).length;
              final available = slots.isEmpty
                  ? (lot['available_slots'] as int? ?? 0)
                  : slots.where(_isEmptySlot).length;
              final color = available == 0
                  ? Colors.red
                  : available <= (total * 0.3)
                      ? Colors.orange
                      : Colors.green;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildParkingCard(
                  context,
                  lot,
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

  Widget _buildParkingCard(BuildContext context, Map<String, dynamic> lot, String name, int cur, int max, Color color) {
    final cardColor = Theme.of(context).cardColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showParkingSeatDialog(lot),
        child: Container(
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${((cur / max) * 100).toInt()}%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text('좌석 보기', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showParkingSeatDialog(Map<String, dynamic> lot) async {
    final lotId = lot['id']?.toString();
    if (lotId == null) return;

    final lotName = lot['name']?.toString() ?? lotId;
    final slotsFuture = _apiClient.listParkingSlots(lotId).then(
      (slots) => slots.whereType<Map<String, dynamic>>().toList(),
    );

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$lotName 좌석 현황'),
          content: SizedBox(
            width: double.maxFinite,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: slotsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return const SizedBox(
                    height: 160,
                    child: Center(child: Text('좌석 정보를 불러오지 못했습니다.', style: TextStyle(color: Colors.redAccent))),
                  );
                }

                final slots = snapshot.data ?? [];
                if (slots.isEmpty) {
                  return const SizedBox(
                    height: 160,
                    child: Center(child: Text('표시할 좌석 정보가 없습니다.')),
                  );
                }

                final available = slots.where(_isEmptySlot).length;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('사용 가능 $available면 · 총 ${slots.length}면', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 14),
                    _buildEntranceLine(context),
                    const SizedBox(height: 14),
                    ..._groupSlotsByRow(slots).entries.map((entry) => _buildSeatRow(entry.key, entry.value)),
                    const SizedBox(height: 14),
                    _buildLegend(),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEntranceLine(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: const Text('입구', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSeatRow(String row, List<Map<String, dynamic>> rowSlots) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(row, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 10,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 0.86,
              ),
              itemCount: rowSlots.length,
              itemBuilder: (context, index) => _buildSeatTile(rowSlots[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatTile(Map<String, dynamic> slot) {
    final status = slot['status']?.toString() ?? 'empty';
    final label = slot['label']?.toString() ?? slot['id']?.toString() ?? '';
    final isEmpty = status == 'empty';
    final isDisabled = status == 'disabled';
    final color = isDisabled
        ? Colors.grey.shade400
        : isEmpty
            ? Colors.green
            : Colors.redAccent;
    final textColor = isEmpty || status == 'occupied' ? Colors.white : Colors.grey.shade800;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.replaceAll(RegExp(r'[^A-Z0-9]'), ''),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor),
        maxLines: 1,
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        _buildLegendItem(Colors.green, '가능'),
        const SizedBox(width: 14),
        _buildLegendItem(Colors.redAccent, '사용 중'),
        const SizedBox(width: 14),
        _buildLegendItem(Colors.grey.shade400, '불가'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupSlotsByRow(List<Map<String, dynamic>> slots) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final slot in slots) {
      final row = slot['row']?.toString() ?? _rowFromLabel(slot);
      grouped.putIfAbsent(row, () => []).add(slot);
    }

    for (final rowSlots in grouped.values) {
      rowSlots.sort((a, b) => _slotColumn(a).compareTo(_slotColumn(b)));
    }

    return Map.fromEntries(grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }

  String _rowFromLabel(Map<String, dynamic> slot) {
    final label = slot['label']?.toString() ?? slot['id']?.toString() ?? 'A';
    return label.isEmpty ? 'A' : label.substring(0, 1).toUpperCase();
  }

  int _slotColumn(Map<String, dynamic> slot) {
    final column = slot['column'];
    if (column is int) return column;
    final label = slot['label']?.toString() ?? slot['id']?.toString() ?? '';
    final match = RegExp(r'\d+').firstMatch(label);
    return int.tryParse(match?.group(0) ?? '') ?? 0;
  }

  bool _isEmptySlot(Map<String, dynamic> slot) {
    return slot['status']?.toString() == 'empty';
  }

  bool _isOccupiedSlot(Map<String, dynamic> slot) {
    return slot['status']?.toString() == 'occupied';
  }
}
