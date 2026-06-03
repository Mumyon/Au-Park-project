import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/shared_data.dart';
import '../models/vehicle_model.dart';

// ChangeNotifier를 상속받으면 데이터가 변할 때 화면에 알림을 줄 수 있습니다.
class VehicleProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<VehicleModel> _vehicles = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<VehicleModel> get vehicles => _vehicles;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadForUser(String userId) async {
    if (userId.isEmpty) {
      _vehicles = [];
      _syncSharedVehicleNumber();
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _apiClient.listVehicles(userId);
      _vehicles = data
          .whereType<Map<String, dynamic>>()
          .map(VehicleModel.fromJson)
          .toList();
      _syncSharedVehicleNumber();
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '차량 정보를 불러오지 못했습니다.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<VehicleModel?> addVehicle(String userId, String plateNumber, String ownerType) async {
    try {
      final data = await _apiClient.createVehicle(
        userId: userId,
        plateNumber: plateNumber,
        nickname: ownerType,
      );
      final newVehicle = VehicleModel.fromJson(data);
      _vehicles.add(newVehicle);
      _syncSharedVehicleNumber();
      notifyListeners();
      return newVehicle;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '차량 등록에 실패했습니다.';
    }
    notifyListeners();
    return null;
  }

  void addLocalVehicle(VehicleModel newVehicle) {
    _vehicles.add(newVehicle);
    _syncSharedVehicleNumber();
    notifyListeners();
  }

  Future<bool> removeVehicle(String id) async {
    try {
      await _apiClient.deleteVehicle(id);
      _vehicles.removeWhere((vehicle) => vehicle.id == id);
      _syncSharedVehicleNumber();
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '차량 삭제에 실패했습니다.';
    }
    notifyListeners();
    return false;
  }

  void _syncSharedVehicleNumber() {
    SharedData.vehicleNumber.value =
        _vehicles.isEmpty ? '등록된 차량 없음' : _vehicles.first.plateNumber;
  }
}
