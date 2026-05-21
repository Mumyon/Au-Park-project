import 'package:flutter/material.dart';
import '../models/vehicle_model.dart'; // 방금 만든 모델 import

// ChangeNotifier를 상속받으면 데이터가 변할 때 화면에 알림을 줄 수 있습니다.
class VehicleProvider with ChangeNotifier {
  // 1. 진짜 차량 데이터들이 담길 리스트 (private 변수로 보호)
  List<VehicleModel> _vehicles = [];

  // 2. 외부 화면에서 데이터를 읽어갈 수 있도록 열어주는 통로(getter)
  List<VehicleModel> get vehicles => _vehicles;

  // 3. 앱 켤 때 테스트용 임시 데이터를 넣어주는 함수
  void loadDummyData() {
    _vehicles = [
      VehicleModel(id: '1', plateNumber: '12가 3456', isDefault: true),
    ];
    notifyListeners(); // 🔥 핵심: "데이터 바뀌었으니 화면들 다 새로고침 해!" 라고 방송함
  }

  // 4. 새로운 차량 추가 로직
  void addVehicle(String plateNumber, String ownerType) {
    final newVehicle = VehicleModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // 임시로 현재 시간 기반 ID 부여
      plateNumber: plateNumber,
      ownerType: ownerType,
    );
    _vehicles.add(newVehicle);
    notifyListeners(); // 🔥 추가됐다고 방송
  }

  // 5. 차량 삭제 로직
  void removeVehicle(String id) {
    _vehicles.removeWhere((vehicle) => vehicle.id == id);
    notifyListeners(); // 🔥 삭제됐다고 방송
  }
}