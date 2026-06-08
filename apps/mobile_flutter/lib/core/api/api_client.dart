import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiClient {
  static const Duration _requestTimeout = Duration(seconds: 15);
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    return 'http://100.100.107.250:8000/api/v1';
  }

  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) {
    return postJson('/auth/login', {'email': email, 'password': password});
  }

  Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    required String name,
  }) {
    return postJson('/auth/signup', {
      'email': email,
      'password': password,
      'name': name,
    });
  }

  Future<Map<String, dynamic>> socialLogin({
    required String provider,
    required String token,
  }) {
    return postJson('/auth/social-login', {
      'provider': provider,
      'token': token,
    });
  }

  Future<Map<String, dynamic>> getUser(String userId) {
    return getJson('/users/$userId');
  }

  Future<List<dynamic>> listVehicles(String userId) {
    return getJsonList('/vehicles?user_id=$userId');
  }

  Future<Map<String, dynamic>> createVehicle({
    required String userId,
    required String plateNumber,
    String? nickname,
  }) {
    return postJson('/vehicles', {
      'user_id': userId,
      'plate_number': plateNumber,
      if (nickname != null) 'nickname': nickname,
    });
  }

  Future<void> deleteVehicle(String vehicleId) async {
    final response = await _send(
      () => _client.delete(Uri.parse('$baseUrl/vehicles/$vehicleId')),
    );
    if (response.statusCode != 204) {
      throw _errorFromResponse(response);
    }
  }

  Future<List<dynamic>> listParkingLots() {
    return getJsonList('/parking/lots');
  }

  Future<List<dynamic>> listParkingSlots(String lotId) {
    return getJsonList('/parking/lots/$lotId/slots');
  }

  Future<Map<String, dynamic>> requestPayment({
    required String userId,
    String? vehicleId,
    String? plateNumber,
    required int amount,
    required String description,
    String? lotId,
    String? lotName,
    DateTime? entryAt,
    DateTime? exitAt,
    int? durationMinutes,
    String? methodName,
  }) {
    return postJson('/payments/request', {
      'user_id': userId,
      if (vehicleId != null && vehicleId.isNotEmpty) 'vehicle_id': vehicleId,
      if (plateNumber != null && plateNumber.isNotEmpty)
        'plate_number': plateNumber,
      'amount': amount,
      'description': description,
      if (lotId != null) 'lot_id': lotId,
      if (lotName != null) 'lot_name': lotName,
      if (entryAt != null) 'entry_at': entryAt.toUtc().toIso8601String(),
      if (exitAt != null) 'exit_at': exitAt.toUtc().toIso8601String(),
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (methodName != null) 'method_name': methodName,
    });
  }

  Future<List<dynamic>> listPayments(String userId) {
    return getJsonList('/payments?user_id=$userId');
  }

  Future<Map<String, dynamic>> registerPaymentMethod({
    required String userId,
    required String methodName,
    required String billingKey,
    String? pgProvider,
    String? payMethod,
    String? impUid,
    String? merchantUid,
    String? customerUid,
    String? status,
  }) {
    return postJson('/payments/methods', {
      'user_id': userId,
      'method_name': methodName,
      'billing_key': billingKey,
      if (pgProvider != null) 'pg_provider': pgProvider,
      if (payMethod != null) 'pay_method': payMethod,
      if (impUid != null) 'imp_uid': impUid,
      if (merchantUid != null) 'merchant_uid': merchantUid,
      if (customerUid != null) 'customer_uid': customerUid,
      if (status != null) 'status': status,
    });
  }

  Future<Map<String, dynamic>> getJson(String path) async {
    final response = await _send(() => _client.get(Uri.parse('$baseUrl$path')));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeObject(response.body);
    }
    throw _errorFromResponse(response);
  }

  Future<List<dynamic>> getJsonList(String path) async {
    final response = await _send(() => _client.get(Uri.parse('$baseUrl$path')));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded;
      }
      throw ApiException('Unexpected API response');
    }
    throw _errorFromResponse(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _send(
      () => _client.post(
        Uri.parse('$baseUrl$path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeObject(response.body);
    }
    throw _errorFromResponse(response);
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(_requestTimeout);
    } on SocketException catch (error) {
      throw ApiException('서버 연결 실패: $baseUrl (${error.message})');
    } on HttpException catch (error) {
      throw ApiException('서버 통신 실패: $baseUrl (${error.message})');
    } on http.ClientException catch (error) {
      throw ApiException('서버 요청 실패: $baseUrl (${error.message})');
    } on TimeoutException {
      throw ApiException('서버 응답 시간 초과: $baseUrl');
    } catch (error) {
      throw ApiException('서버 요청 오류: $baseUrl ($error)');
    }
  }

  Map<String, dynamic> _decodeObject(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw ApiException('Unexpected API response');
  }

  ApiException _errorFromResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['detail'] != null) {
        return ApiException(decoded['detail'].toString(), response.statusCode);
      }
    } catch (_) {}
    return ApiException('API request failed', response.statusCode);
  }
}
