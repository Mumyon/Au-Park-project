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
  static final String baseUrl = Platform.isAndroid
      ? 'http://10.0.2.2:8000/api/v1'
      : 'http://127.0.0.1:8000/api/v1';

  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) {
    return postJson('/auth/login', {
      'email': email,
      'password': password,
    });
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
    final response = await _client.delete(Uri.parse('$baseUrl/vehicles/$vehicleId'));
    if (response.statusCode != 204) {
      throw _errorFromResponse(response);
    }
  }

  Future<List<dynamic>> listParkingLots() {
    return getJsonList('/parking/lots');
  }

  Future<Map<String, dynamic>> registerPaymentMethod({
    required String userId,
    required String methodName,
    required String billingKey,
  }) {
    return postJson('/payments/methods', {
      'user_id': userId,
      'method_name': methodName,
      'billing_key': billingKey,
    });
  }

  Future<Map<String, dynamic>> getJson(String path) async {
    final response = await _client.get(Uri.parse('$baseUrl$path'));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeObject(response.body);
    }
    throw _errorFromResponse(response);
  }

  Future<List<dynamic>> getJsonList(String path) async {
    final response = await _client.get(Uri.parse('$baseUrl$path'));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded;
      }
      throw ApiException('Unexpected API response');
    }
    throw _errorFromResponse(response);
  }

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body) async {
    final response = await _client.post(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeObject(response.body);
    }
    throw _errorFromResponse(response);
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
    } catch (_) {
      // Ignore JSON parsing errors and fall through to the generic message.
    }
    return ApiException('API request failed', response.statusCode);
  }
}
