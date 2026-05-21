import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vehicle_provider.dart';

class VehicleRegistrationScreen extends StatefulWidget {
  const VehicleRegistrationScreen({super.key});

  @override
  State<VehicleRegistrationScreen> createState() => _VehicleRegistrationScreenState();
}

class _VehicleRegistrationScreenState extends State<VehicleRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _plateController = TextEditingController();
  String _selectedOwner = '본인';

  // 번호판 유효성 검사 함수
  String? _validateLicensePlate(String? value) {
    if (value == null || value.isEmpty) {
      return '차량 번호를 입력해 주세요.';
    }
    final regExp = RegExp(r'^\d{2,3}[가-힣]\s?\d{4}$');
    if (!regExp.hasMatch(value)) {
      return '형식에 맞게 입력해 주세요. (예: 12가 3456 또는 123호 4567)';
    }
    return null;
  }

  // 차량 추가 바텀 시트 띄우기
  void _showAddVehicleSheet(VehicleProvider provider) {
    _plateController.clear();
    _selectedOwner = '본인';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            top: 24, left: 24, right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24, 
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('새 차량 등록', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                
                const Text('차량 번호', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _plateController,
                  validator: _validateLicensePlate,
                  decoration: InputDecoration(
                    hintText: '예) 123가 4567',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 20),

                const Text('차량 소유주 명의', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedOwner,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  items: ['본인', '가족', '법인/렌트'].map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() { _selectedOwner = newValue!; });
                  },
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // 🔥 Provider 방송국을 통해 데이터 추가 요청
                      provider.addVehicle(_plateController.text, _selectedOwner);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('차량이 성공적으로 등록되었습니다.')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    backgroundColor: const Color(0xFF003366),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('등록하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
    // 🔥 Provider 데이터 구독 (데이터가 변하면 이 build 함수가 자동으로 재실행됨)
    final vehicleProvider = Provider.of<VehicleProvider>(context);
    final vehiclesList = vehicleProvider.vehicles;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('차량 등록 / 관리', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('등록된 내 차량', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('총 ${vehiclesList.length}대', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: vehiclesList.isEmpty
                  ? Center(
                      child: Text('등록된 차량이 없습니다.\n아래 버튼을 눌러 추가해 주세요.',
                          textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, height: 1.5)),
                    )
                  : ListView.builder(
                      itemCount: vehiclesList.length,
                      itemBuilder: (context, index) {
                        final vehicle = vehiclesList[index]; // 이제 String이 아닌 고유 모델 객체입니다.
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                              child: const Icon(Icons.directions_car, color: Colors.black54),
                            ),
                            title: Text(vehicle.plateNumber, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () {
                                // 🔥 Provider 방송국을 통해 데이터 삭제 요청
                                vehicleProvider.removeVehicle(vehicle.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('차량이 삭제되었습니다.')),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showAddVehicleSheet(vehicleProvider),
                icon: const Icon(Icons.add),
                label: const Text('새 차량 추가하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: const Color(0xFF003366),
                  side: const BorderSide(color: Color(0xFF003366)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}