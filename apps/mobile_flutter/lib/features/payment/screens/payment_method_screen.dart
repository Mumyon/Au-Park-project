import 'package:flutter/material.dart';
import 'package:iamport_flutter/iamport_payment.dart';
import 'package:iamport_flutter/model/payment_data.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api_client.dart';
import '../../../core/shared_data.dart'; // ⚠️ 경로 확인 필수!

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  final ApiClient _apiClient = ApiClient();
  List<Map<String, dynamic>> registeredMethods = [];
  String _mainMethodId = '';

  @override
  void initState() {
    super.initState();
    // 🚀 화면이 켜질 때 로컬 저장소에서 카드를 불러옵니다!
    _loadSavedPaymentMethods();
  }

  // 💾 1. 기기 저장소에서 카드 리스트 불러오기
  Future<void> _loadSavedPaymentMethods() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMethods = prefs.getString('saved_cards');
    final savedMainId = prefs.getString('main_card_id');

    if (savedMethods != null) {
      setState(() {
        // JSON 문자열을 다시 리스트로 변환
        registeredMethods = List<Map<String, dynamic>>.from(jsonDecode(savedMethods));
        _mainMethodId = savedMainId ?? '';
      });
    }
    _updateSharedData();
  }

  // 💾 2. 기기 저장소에 카드 리스트 저장하기 (추가/삭제할 때마다 호출)
  Future<void> _savePaymentMethods() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_cards', jsonEncode(registeredMethods));
    await prefs.setString('main_card_id', _mainMethodId);
  }

  // 🔄 전역 상태에 주 결제수단 이름 동기화
  void _updateSharedData() {
    if (registeredMethods.isEmpty) {
      SharedData.paymentMethod.value = '등록된 결제 수단 없음';
      return;
    }
    final mainMethod = registeredMethods.firstWhere(
      (m) => m['id'] == _mainMethodId, 
      orElse: () => registeredMethods[0]
    );
    SharedData.paymentMethod.value = mainMethod['name'];
  }

  // 🗑️ 결제 수단 삭제 함수
  void _deletePaymentMethod(int index) {
    final deletedName = registeredMethods[index]['name'];
    final deletedId = registeredMethods[index]['id'];

    setState(() {
      registeredMethods.removeAt(index);
      if (_mainMethodId == deletedId && registeredMethods.isNotEmpty) {
        _mainMethodId = registeredMethods[0]['id'];
      } else if (registeredMethods.isEmpty) {
        _mainMethodId = '';
      }
    });
    
    _savePaymentMethods(); // 💾 삭제 후 저장
    _updateSharedData();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🗑️ $deletedName 수단이 삭제되었습니다.'),
        duration: const Duration(milliseconds: 1000),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ➕ 결제 수단 추가 함수
  void _addPaymentMethod(String name, String type) async {
    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString('userId') ?? "";
    final String mockBillingKey = "test_billing_key_${DateTime.now().millisecondsSinceEpoch}";

    if (userId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ 로그인 정보가 없습니다. 다시 로그인해주세요.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      await _apiClient.registerPaymentMethod(
        userId: userId,
        methodName: name,
        billingKey: mockBillingKey,
      );

      setState(() {
        final newId = DateTime.now().millisecondsSinceEpoch.toString();
        registeredMethods.add({
          'id': newId,
          'name': name,
          'type': type,
        });
        if (registeredMethods.length == 1) {
          _mainMethodId = newId;
        }
      });
      
      _savePaymentMethods(); // 💾 추가 후 영구 저장!
      _updateSharedData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $name이(가) 성공적으로 등록되었습니다!'),
            backgroundColor: Colors.green,
            duration: const Duration(milliseconds: 2000),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${e.message}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print("❌ 서버 전송 에러: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ 서버와 연결할 수 없습니다.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _startPortOnePayment({
    required BuildContext context,
    required String pgCode,
    required String payMethod,
    required String pgName,
    required bool isBilling,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IamportPayment(
          appBar: AppBar(
            title: Text('$pgName 등록 (포트원)', style: const TextStyle(color: Colors.black87)),
            backgroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.black87),
            elevation: 0,
          ),
          initialChild: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('안전 결제창을 불러오는 중입니다...', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
          userCode: 'imp68124833', // 무조건 열리는 공용 마스터키
          data: PaymentData(
            pg: pgCode, 
            payMethod: payMethod, 
            name: 'Au-Park 주차 결제수단 등록 테스트',
            merchantUid: 'mid_${DateTime.now().millisecondsSinceEpoch}',
            amount: 100, 
            customerUid: isBilling ? 'user_youngjin_001' : null, 
            buyerName: '영진(테스트)',
            buyerTel: '010-1234-5678',
            buyerEmail: 'youngjin@ansan.ac.kr',
            appScheme: 'aupark', 
          ),
          callback: (Map<String, String> result) {
            Navigator.pop(context);
            if (result['imp_success'] == 'true') {
              _addPaymentMethod('$pgName 연동 완료', 'card');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ 결제 실패: ${result['error_msg'] ?? '알 수 없는 오류'}'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  void _showPaymentSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('결제 수단 추가', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('자동 정산에 사용할 카드를 등록하세요.', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.payment, color: Colors.teal, size: 36),
                  title: const Text('신용/체크카드 등록', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('화면 안에서 카드 정보를 직접 입력하여 연동'),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(context);
                    _startPortOnePayment(
                      context: context, 
                      pgCode: 'html5_inicis', 
                      payMethod: 'card', 
                      pgName: '일반 신용카드',
                      isBilling: false, 
                    );
                  },
                ),
                const Divider(),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.credit_card, color: Theme.of(context).primaryColor, size: 36),
                  title: Text('테스트 카드 즉시 등록 (추천)', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                  subtitle: const Text('PG창 호출 없이 1초 만에 가상 카드 추가'),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(context);
                    int nextNum = registeredMethods.length + 1;
                    _addPaymentMethod('테스트 카드 $nextNum', 'card');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('결제 수단 관리', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('자동 정산 결제 수단', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.grey.shade300 : Colors.black54)),
            const SizedBox(height: 8),
            const Text('출차 시 주차 요금이 주 결제 수단으로 자동 결제됩니다.', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 24),
            
            if (registeredMethods.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    '등록된 결제 수단이 없습니다.\n아래 버튼을 눌러 추가해 주세요.', 
                    style: TextStyle(color: Colors.grey.shade500, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: registeredMethods.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final method = registeredMethods[index];
                    return _buildPremiumCardTile(index: index, method: method);
                  },
                ),
              ),

            const SizedBox(height: 20),
            
            ElevatedButton.icon(
              onPressed: () => _showPaymentSelector(context),
              icon: const Icon(Icons.add),
              label: const Text('새 결제 수단 추가하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.security, size: 20, color: Colors.grey),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '등록하신 결제 수단은 포트원(PortOne)의 안전한 보안 시스템을 통해 암호화되어 안전하게 관리됩니다.',
                      style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.5),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // ✨ 프리미엄 실물 카드 디자인 컴포넌트
  Widget _buildPremiumCardTile({required int index, required Map<String, dynamic> method}) {
    final String cardName = method['name'];
    final String cardId = method['id'];
    final bool isMain = cardId == _mainMethodId;
    
    Color bgColor = const Color(0xFF1E3A8A); 
    Color textColor = Colors.white;
    IconData cardIcon = Icons.credit_card;
    Color iconColor = Colors.white;

    return GestureDetector(
      onTap: () {
        setState(() => _mainMethodId = cardId);
        _savePaymentMethods(); // 💾 주 결제 수단 바꿨을 때도 영구 저장!
        _updateSharedData();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: isMain 
              ? Border.all(color: Theme.of(context).primaryColor, width: 3) 
              : Border.all(color: Colors.transparent, width: 3),
          boxShadow: [
            if (isMain) 
              BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))
            else
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
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
                    Icon(cardIcon, color: iconColor, size: 24),
                    const SizedBox(width: 12),
                    Text(cardName, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                InkWell(
                  onTap: () => _deletePaymentMethod(index),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('**** **** **** 1234', style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 16, letterSpacing: 2)),
                if (isMain)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: textColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                    child: Text('주 결제 수단', style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
