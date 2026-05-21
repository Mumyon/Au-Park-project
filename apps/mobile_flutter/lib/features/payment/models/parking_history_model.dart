class ParkingHistoryModel {
  final String id;
  final String date;        // 이용 날짜 (예: 2026.05.18)
  final String location;    // 주차장 이름 (예: 본관 주차장)
  final String carNumber;   // 차량 번호
  final String entryTime;   // 입차 시간
  final String exitTime;    // 출차 시간
  final String duration;    // 총 이용 시간
  final int price;          // 결제 금액 (계산을 위해 int로 받음)
  final String status;      // 상태 (결제완료, 미납 등)

  ParkingHistoryModel({
    required this.id,
    required this.date,
    required this.location,
    required this.carNumber,
    required this.entryTime,
    required this.exitTime,
    required this.duration,
    required this.price,
    this.status = '결제완료',
  });

  factory ParkingHistoryModel.fromJson(Map<String, dynamic> json) {
    return ParkingHistoryModel(
      id: json['id'] ?? '',
      date: json['date'] ?? '',
      location: json['location'] ?? '',
      carNumber: json['carNumber'] ?? '',
      entryTime: json['entryTime'] ?? '',
      exitTime: json['exitTime'] ?? '',
      duration: json['duration'] ?? '',
      price: json['price'] ?? 0,
      status: json['status'] ?? '결제완료',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'location': location,
      'carNumber': carNumber,
      'entryTime': entryTime,
      'exitTime': exitTime,
      'duration': duration,
      'price': price,
      'status': status,
    };
  }
}