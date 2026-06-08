import 'package:flutter/material.dart';

class SharedData {
  static final ValueNotifier<String> vehicleNumber = ValueNotifier<String>(
    "등록된 차량 없음",
  );

  static final ValueNotifier<bool> isCurrentlyParked = ValueNotifier<bool>(
    false,
  );

  static final ValueNotifier<String> paymentMethod = ValueNotifier<String>(
    "등록된 결제 수단 없음",
  );

  static final ValueNotifier<DateTime> parkingEntryAt = ValueNotifier<DateTime>(
    DateTime.now(),
  );

  static final ValueNotifier<int> parkingTotalFee = ValueNotifier<int>(0);

  static final ValueNotifier<int> parkingBaseFee = ValueNotifier<int>(0);

  static final ValueNotifier<int> parkingAdditionalFee = ValueNotifier<int>(0);

  static final ValueNotifier<int> parkingPrepaidAmount = ValueNotifier<int>(0);

  static final ValueNotifier<int> parkingOutstandingFee = ValueNotifier<int>(0);
}
