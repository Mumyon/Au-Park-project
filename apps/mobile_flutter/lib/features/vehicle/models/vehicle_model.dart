class VehicleModel {
  final String id;           // 데이터베이스 고유 ID
  final String plateNumber;  // 차량 번호 (예: 12가 3456)
  final String ownerType;    // 명의 (본인, 가족, 법인/렌트)
  final bool isDefault;      // 대표(기본) 차량 여부

  VehicleModel({
    required this.id,
    required this.plateNumber,
    this.ownerType = '본인',
    this.isDefault = false,
  });

  // 1. 서버(DB)에서 JSON 데이터를 받아와서 Flutter 객체로 변환하는 마법의 주문
  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] ?? '',
      plateNumber: json['plateNumber'] ?? '',
      ownerType: json['ownerType'] ?? '본인',
      isDefault: json['isDefault'] ?? false,
    );
  }

  // 2. 반대로 Flutter 객체를 JSON으로 변환해서 서버로 보낼 때 사용
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plateNumber': plateNumber,
      'ownerType': ownerType,
      'isDefault': isDefault,
    };
  }
}