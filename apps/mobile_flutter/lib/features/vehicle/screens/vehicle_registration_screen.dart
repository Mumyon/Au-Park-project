import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// ⚠️ 본인의 폴더 구조에 맞게 경로 확인 필수!
import '../../../core/shared_data.dart';
import '../../auth/providers/user_provider.dart';

class VehicleRegistrationScreen extends StatefulWidget {
  const VehicleRegistrationScreen({super.key});

  @override
  State<VehicleRegistrationScreen> createState() => _VehicleRegistrationScreenState();
}

class _VehicleRegistrationScreenState extends State<VehicleRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleNumberController = TextEditingController();

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    super.dispose();
  }

  // 🚀 1. 서버에 차량 정보(등록 또는 삭제) 업데이트 요청 함수 (안전장치 추가)
  Future<bool> _updateVehicleOnServer(String vehicleNum) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // 🔥 1. 기본적으로 Provider에서 이메일 가져오기
    String userEmail = userProvider.email?.toString() ?? '';

    // 🔥 2. 백업 플랜: 핫리로드 등으로 데이터가 증발했다면 기기 캐시에서 끌어옵니다!
    if (userEmail.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      userEmail = prefs.getString('userEmail') ?? ''; 
    }

    // 🔥 3. 그래도 이메일이 없다면? 서버 통신 전에 앱에서 차단!
    if (userEmail.isEmpty) {
      _showSnackBar('⚠️ 내 정보가 유실되었습니다. 마이페이지에서 로그아웃 후 다시 로그인해주세요.', Colors.redAccent);
      return false;
    }

    try {
      final url = Uri.parse('http://10.0.2.2:3000/api/update-vehicle');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': userEmail, // 안전하게 확보한 이메일 전송!
          'registeredVehicle': vehicleNum,
        }),
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['success'] == true) {
        // 전역 상태 및 디바이스 로컬 캐시 최신화
        SharedData.vehicleNumber.value = vehicleNum;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('registeredVehicle', vehicleNum);
        return true;
      } else {
        _showSnackBar('❌ 실패: ${result['message']}', Colors.redAccent);
        return false;
      }
    } catch (e) {
      _showSnackBar('⚠️ 서버 통신 실패. 백엔드 서버 상태를 확인하세요.', Colors.orange);
      return false;
    }
  }

  // 편리한 스낵바 호출을 위한 헬퍼 함수
  void _showSnackBar(String message, [Color? bgColor]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 🔥 하단에서 스르륵 올라오는 차량 번호 입력창 (BottomSheet)
  void _showAddVehicleSheet(BuildContext context) {
    _vehicleNumberController.clear(); 

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 32,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('신규 차량 등록', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('주차 요금 자동 결제를 위한 차량 번호를 입력해주세요.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 24),
                
                TextFormField(
                  controller: _vehicleNumberController,
                  textInputAction: TextInputAction.done,
                  keyboardType: TextInputType.text, 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: '차량 번호',
                    hintText: '예: 12가1234 또는 123가1234',
                    prefixIcon: const Icon(Icons.directions_car_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    filled: true,
                    fillColor: Theme.of(sheetContext).cardColor,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '⚠️ 차량 번호를 입력해 주세요.';
                    }
                    String cleanedValue = value.replaceAll(' ', '');
                    final carNumberRegex = RegExp(r'^\d{2,3}[가-힣]\d{4}$');
                    
                    if (!carNumberRegex.hasMatch(cleanedValue)) {
                      return '⚠️ 올바른 번호판 형식이 아닙니다. (예: 123가1234)';
                    }
                    return null; 
                  },
                ),
                
                const SizedBox(height: 32),
                
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      String finalCarNumber = _vehicleNumberController.text.replaceAll(' ', '');
                      
                      // 로딩 인디케이터 표시
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(child: CircularProgressIndicator()),
                      );

                      // 🔥 백엔드 연동: 파이어베이스 서버 업데이트
                      bool isSuccess = await _updateVehicleOnServer(finalCarNumber);

                      if (!context.mounted) return;
                      Navigator.of(context, rootNavigator: true).pop(); // 로딩창 닫기

                      if (isSuccess) {
                        Navigator.pop(sheetContext); // 바텀시트 닫기
                        _showSnackBar('✅ $finalCarNumber 차량이 Au-Park 시스템에 등록되었습니다!', Colors.green);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('등록 완료', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 32), 
              ],
            ),
          ),
        );
      },
    );
  }

  // 🗑️ 차량 삭제(초기화) 기능
  Future<void> _deleteVehicle() async {
    // 삭제 전 로딩창 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // 🔥 백엔드 연동: 파이어베이스에 "등록된 차량 없음"으로 강제 업데이트
    bool isSuccess = await _updateVehicleOnServer("등록된 차량 없음");

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // 로딩창 닫기

    if (isSuccess) {
      _showSnackBar('🗑️ 차량 정보가 안전하게 삭제되었습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('차량 관리', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '등록된 차량 내역',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.grey.shade300 : Colors.black54),
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: ValueListenableBuilder<String>(
                valueListenable: SharedData.vehicleNumber,
                builder: (context, currentNumber, child) {
                  // 차량이 없을 때 텅 빈 화면
                  if (currentNumber == "등록된 차량 없음") {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_car_filled_outlined, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('등록된 차량이 없습니다.', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                          const SizedBox(height: 8),
                          Text('아래 버튼을 눌러 차량을 추가해 주세요.', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                        ],
                      ),
                    );
                  }

                  // 차량이 있을 때 예쁜 카드 형태
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.directions_car, color: primaryColor, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(currentNumber, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  const Text('주차 요금 자동 정산 차량', style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            // 등록된 차량 지우기 (휴지통) 버튼
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () {
                                // 삭제 전 물어보는 컨펌 다이얼로그 추가
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('차량 등록 해제', style: TextStyle(fontWeight: FontWeight.bold)),
                                    content: const Text('등록된 차량 정보를 삭제하시겠습니까?\n삭제 시 자동 결제 시스템이 일시 중단됩니다.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소', style: TextStyle(color: Colors.grey))),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _deleteVehicle();
                                        },
                                        child: const Text('삭제', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            
            // 🚀 맨 밑에 고정된 [신규 차량 추가하기] 버튼
            ElevatedButton.icon(
              onPressed: () => _showAddVehicleSheet(context),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('신규 차량 추가하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}