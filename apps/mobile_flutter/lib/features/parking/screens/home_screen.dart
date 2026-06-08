import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';
import '../../../core/shared_data.dart';
import '../../auth/providers/user_provider.dart';
import '../../payment/screens/parking_history_screen.dart';
import '../../payment/screens/payment_method_screen.dart';
import '../../support/screens/notice_screen.dart';
import '../../vehicle/providers/vehicle_provider.dart';
import '../../vehicle/screens/vehicle_registration_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const String _lotId = 'lot-main';
  static const String _lotName = '정문 제1주차장';
  static const Duration _syncInterval = Duration(seconds: 3);

  final ApiClient _apiClient = ApiClient();
  Timer? _syncTimer;
  bool _syncInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncActiveParkingSession();
    });
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      _syncActiveParkingSession();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncActiveParkingSession();
    }
  }

  Future<void> _syncActiveParkingSession() async {
    if (_syncInProgress || !mounted) {
      return;
    }
    _syncInProgress = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) {
        return;
      }
      final providerUserId = Provider.of<UserProvider>(
        context,
        listen: false,
      ).userId;
      final userId = providerUserId.isNotEmpty
          ? providerUserId
          : prefs.getString('userId') ?? '';
      if (userId.isEmpty) {
        SharedData.isCurrentlyParked.value = false;
        return;
      }

      final session = await _apiClient.getActiveParkingSession(userId);
      if (!mounted) {
        return;
      }
      if (session == null) {
        SharedData.isCurrentlyParked.value = false;
        SharedData.parkingTotalFee.value = 0;
        SharedData.parkingBaseFee.value = 0;
        SharedData.parkingAdditionalFee.value = 0;
        SharedData.parkingPrepaidAmount.value = 0;
        SharedData.parkingOutstandingFee.value = 0;
        return;
      }

      final sessionData = session['session'];
      if (sessionData is! Map<String, dynamic>) {
        throw ApiException('Unexpected active parking response');
      }
      final plateNumber = sessionData['plate_number']?.toString().trim() ?? '';
      final entryAt = DateTime.tryParse(
        sessionData['entry_at']?.toString() ?? '',
      );
      if (plateNumber.isNotEmpty) {
        SharedData.vehicleNumber.value = plateNumber;
      }
      if (entryAt != null) {
        SharedData.parkingEntryAt.value = entryAt.toLocal();
      }
      SharedData.parkingTotalFee.value =
          (session['total_fee'] as num?)?.toInt() ?? 0;
      SharedData.parkingBaseFee.value =
          (session['base_fee'] as num?)?.toInt() ?? 0;
      SharedData.parkingAdditionalFee.value =
          (session['additional_fee'] as num?)?.toInt() ?? 0;
      SharedData.parkingPrepaidAmount.value =
          (session['prepaid_amount'] as num?)?.toInt() ?? 0;
      SharedData.parkingOutstandingFee.value =
          (session['outstanding_fee'] as num?)?.toInt() ?? 0;
      SharedData.isCurrentlyParked.value = true;
    } on ApiException catch (error) {
      debugPrint('Active parking sync failed: ${error.message}');
    } catch (error) {
      debugPrint('Active parking sync failed: $error');
    } finally {
      _syncInProgress = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _processDirectPayment({
    required BuildContext parentContext,
    required BuildContext sheetContext,
    required String cardName,
  }) async {
    final navigator = Navigator.of(parentContext, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(parentContext);
    final currentVehicle = SharedData.vehicleNumber.value;
    final entryAt = SharedData.parkingEntryAt.value;
    final exitAt = DateTime.now();
    final durationMinutes = exitAt
        .difference(entryAt)
        .inMinutes
        .clamp(0, 1000000)
        .toInt();
    final parkingFee = SharedData.parkingOutstandingFee.value;

    Navigator.of(sheetContext).pop();

    showDialog(
      context: parentContext,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) {
        return const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    '안전하게 결제하는 중...',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      await Future.delayed(const Duration(seconds: 2));
      final prefs = await SharedPreferences.getInstance();
      final providerUserId = Provider.of<UserProvider>(
        parentContext,
        listen: false,
      ).userId;
      final userId = providerUserId.isNotEmpty
          ? providerUserId
          : prefs.getString('userId') ?? '';
      final vehicles = Provider.of<VehicleProvider>(
        parentContext,
        listen: false,
      ).vehicles;
      final matchedVehicles = vehicles.where(
        (vehicle) => vehicle.plateNumber == currentVehicle,
      );
      final matchedVehicle = matchedVehicles.isEmpty
          ? null
          : matchedVehicles.first;

      if (userId.isEmpty) {
        throw Exception('Missing user id');
      }

      final payment = await ApiClient().requestPayment(
        userId: userId,
        vehicleId: matchedVehicle?.id,
        plateNumber: currentVehicle,
        amount: parkingFee,
        description: '${_formatDate(exitAt)} 주차 정산',
        lotId: _lotId,
        lotName: _lotName,
        entryAt: entryAt,
        exitAt: exitAt,
        durationMinutes: durationMinutes,
        methodName: cardName,
      );

      debugPrint('Payment completed: $payment');
      final paidAmount = (payment['amount'] as num?)?.toInt() ?? parkingFee;
      SharedData.parkingPrepaidAmount.value += paidAmount;
      SharedData.parkingOutstandingFee.value = 0;

      if (navigator.canPop()) {
        navigator.pop();
      }

      await _syncActiveParkingSession();

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '✅ $cardName(으)로 [$currentVehicle] ${_formatDuration(durationMinutes)} 이용료 ${_formatWon(paidAmount)}이 사전 정산되었습니다.',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (navigator.canPop()) {
        navigator.pop();
      }

      messenger.showSnackBar(
        const SnackBar(
          content: Text('❌ 결제 중 오류가 발생했습니다. 다시 시도해주세요.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            ValueListenableBuilder<bool>(
              valueListenable: SharedData.isCurrentlyParked,
              builder: (context, isParked, child) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isParked
                      ? ValueListenableBuilder<String>(
                          key: const ValueKey('parked'),
                          valueListenable: SharedData.vehicleNumber,
                          builder: (context, currentVehicleNumber, child) {
                            return _buildActiveParkingCard(
                              context,
                              currentVehicleNumber,
                            );
                          },
                        )
                      : _buildNotParkingState(context),
                );
              },
            ),
            const SizedBox(height: 32),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                '빠른 바로가기',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: [
                  _buildServiceIcon(
                    context: context,
                    icon: Icons.directions_car,
                    label: '차량 등록',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const VehicleRegistrationScreen(),
                        ),
                      );
                    },
                  ),
                  _buildServiceIcon(
                    context: context,
                    icon: Icons.credit_card,
                    label: '결제 수단',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PaymentMethodScreen(),
                        ),
                      );
                    },
                  ),

                  _buildServiceIcon(
                    context: context,
                    icon: Icons.receipt_long_outlined,
                    label: '이용 내역',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ParkingHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  _buildServiceIcon(
                    context: context,
                    icon: Icons.campaign_outlined,
                    label: '공지사항',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NoticeScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton.icon(
                onPressed: _syncActiveParkingSession,
                icon: const Icon(Icons.refresh, color: Colors.grey),
                label: const Text(
                  '주차 상태 새로고침',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNotParkingState(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      key: const ValueKey('not_parked'),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_parking,
              size: 48,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '현재 이용 중인 주차장이 없습니다.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '차량이 스마트 존에 입차되면\n자동으로 현황판이 표시됩니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveParkingCard(BuildContext context, String vehicleNum) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.local_parking,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '주차 이용 중',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '입차됨',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            '정문 제1주차장',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<DateTime>(
            valueListenable: SharedData.parkingEntryAt,
            builder: (context, entryAt, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '차량 번호: $vehicleNum',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '입차 시간: ${_formatClock(entryAt)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  _buildFeeSummary(),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _showPaymentSheet(context),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              '사전 정산하기',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPaymentSheet(BuildContext context) async {
    final currentVehicle = SharedData.vehicleNumber.value;
    final parkingFee = SharedData.parkingOutstandingFee.value;

    if (currentVehicle == '등록된 차량 없음' || currentVehicle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ 먼저 차량을 등록해야 사전 정산이 가능합니다.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (parkingFee <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('현재 추가로 정산할 요금이 없습니다.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final parentContext = context;

    await _syncPaymentMethodFromStorage();

    showModalBottomSheet(
      context: parentContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext sheetContext) {
        return ValueListenableBuilder<String>(
          valueListenable: SharedData.paymentMethod,
          builder: (builderContext, paymentName, child) {
            final trimmedPaymentName = paymentName.trim();

            final hasPaymentMethod =
                trimmedPaymentName.isNotEmpty &&
                trimmedPaymentName != '등록된 결제 수단 없음';

            final isDarkMode =
                Theme.of(builderContext).brightness == Brightness.dark;

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '사전 정산 결제',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '[$currentVehicle] 차량의 주차 요금 ${_formatWon(parkingFee)}을 정산합니다.',
                    style: const TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 24),

                  if (hasPaymentMethod) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.credit_card,
                        color: Colors.blueAccent,
                        size: 36,
                      ),
                      title: Text(
                        trimmedPaymentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: const Text('현재 주 결제 수단'),
                      trailing: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                      onTap: () => _processDirectPayment(
                        parentContext: parentContext,
                        sheetContext: sheetContext,
                        cardName: trimmedPaymentName,
                      ),
                    ),

                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: () => _processDirectPayment(
                        parentContext: parentContext,
                        sheetContext: sheetContext,
                        cardName: trimmedPaymentName,
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        backgroundColor: Theme.of(builderContext).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        '${_formatWon(parkingFee)} 결제하기',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                            size: 28,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '등록된 주 결제 수단이 없습니다.\n자동 정산을 위해 카드를 먼저 등록해주세요.',
                              style: TextStyle(height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);

                        Navigator.push(
                          parentContext,
                          MaterialPageRoute(
                            builder: (context) => const PaymentMethodScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_card),
                      label: const Text(
                        '결제 수단 등록하러 가기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        backgroundColor: isDarkMode
                            ? Colors.grey.shade700
                            : Colors.black87,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFeeSummary() {
    return ValueListenableBuilder<int>(
      valueListenable: SharedData.parkingOutstandingFee,
      builder: (context, outstandingFee, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildFeeLine('기본요금', SharedData.parkingBaseFee.value),
            _buildFeeLine('추가요금', SharedData.parkingAdditionalFee.value),
            if (SharedData.parkingPrepaidAmount.value > 0)
              _buildFeeLine(
                '정산 완료',
                SharedData.parkingPrepaidAmount.value,
                color: Colors.white70,
              ),
            const SizedBox(height: 3),
            const Text(
              '현재 미정산',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
            Text(
              _formatWon(outstandingFee),
              style: const TextStyle(
                color: Colors.yellowAccent,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeeLine(String label, int amount, {Color color = Colors.white}) {
    return Text(
      '$label ${_formatWon(amount)}',
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildServiceIcon({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDarkMode
        ? Colors.white
        : Theme.of(context).primaryColor;
    final bgColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.15)
        : Theme.of(context).primaryColor.withValues(alpha: 0.1);
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _syncPaymentMethodFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMethods = prefs.getString('saved_cards');
    final savedMainId = prefs.getString('main_card_id');

    if (savedMethods == null) {
      SharedData.paymentMethod.value = '등록된 결제 수단 없음';
      return;
    }

    final decoded = jsonDecode(savedMethods);
    if (decoded is! List || decoded.isEmpty) {
      SharedData.paymentMethod.value = '등록된 결제 수단 없음';
      return;
    }

    final methods = decoded
        .whereType<Map>()
        .map((method) => Map<String, dynamic>.from(method))
        .toList();
    final mainMethod = methods.firstWhere(
      (method) => method['id'] == savedMainId,
      orElse: () => methods.first,
    );
    SharedData.paymentMethod.value =
        mainMethod['name']?.toString() ?? '등록된 결제 수단 없음';
  }

  String _formatClock(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours == 0) return '$remainingMinutes분';
    if (remainingMinutes == 0) return '$hours시간';
    return '$hours시간 $remainingMinutes분';
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}.$month.$day';
  }

  String _formatWon(int amount) {
    final text = amount.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
    return '$text원';
  }
}
