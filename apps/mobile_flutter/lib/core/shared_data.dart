import 'package:flutter/material.dart';

class SharedData {
  static final ValueNotifier<String> vehicleNumber = ValueNotifier<String>("등록된 차량 없음");

  static final ValueNotifier<bool> isCurrentlyParked = ValueNotifier<bool>(true);

  static final ValueNotifier<String> paymentMethod = ValueNotifier<String>("등록된 결제 수단 없음");

  static final ValueNotifier<DateTime> parkingEntryAt = ValueNotifier<DateTime>(
    DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
  );
}
