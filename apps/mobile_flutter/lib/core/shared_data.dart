import 'package:flutter/material.dart';

class SharedData {
  // 🚗 등록된 차량 번호 관리
  static final ValueNotifier<String> vehicleNumber = ValueNotifier<String>("등록된 차량 없음");
  
  // 🅿️ 주차 여부 관리
  static final ValueNotifier<bool> isCurrentlyParked = ValueNotifier<bool>(true);

  // 💳 등록된 대표 결제 수단 관리 (기본값 설정)
  static final ValueNotifier<String> paymentMethod = ValueNotifier<String>("등록된 결제 수단 없음");
}