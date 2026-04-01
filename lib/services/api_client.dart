import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:haanppen_mobile/constants/api_constants.dart';
import 'auth_service.dart';

class ApiClient {
  static final _client = http.Client();

  static Uri _buildUri(String path, {Map<String, String>? queryParams}) {
    return Uri.parse('${ApiConstants.baseUrl}$path')
        .replace(queryParameters: queryParams);
  }

  static Future<Map<String, dynamic>> _handleResponse(http.Response response) {
    if (response.statusCode >= 400) {
      if (response.statusCode == 401) {
        AuthService.instance.logout();
      }
      String message = '요청에 실패했습니다.';
      try {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        message = errorData['errorDescription'] as String? ??
            errorData['message'] as String? ??
            message;
      } catch (_) {}
      throw ApiException(statusCode: response.statusCode, message: message);
    }

    if (response.body.isEmpty) return Future.value(<String, dynamic>{});
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return Future.value(decoded);
      return Future.value(<String, dynamic>{});
    } catch (e) {
      throw ApiException(
          statusCode: response.statusCode, message: '응답 데이터 파싱에 실패했습니다: $e');
    }
  }

  static Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParams: queryParams);
    final response = await _client.get(
      uri,
      headers: {'Content-Type': 'application/json', ...?headers},
    );
    return _handleResponse(response);
  }

  static Future<List<dynamic>> getList(
    String path, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParams: queryParams);
    final response = await _client.get(
      uri,
      headers: {'Content-Type': 'application/json', ...?headers},
    );
    if (response.statusCode >= 400) {
      if (response.statusCode == 401) AuthService.instance.logout();
      String message = '요청에 실패했습니다.';
      try {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        message = errorData['errorDescription'] as String? ??
            errorData['message'] as String? ??
            message;
      } catch (_) {}
      throw ApiException(statusCode: response.statusCode, message: message);
    }
    try {
      return jsonDecode(response.body) as List<dynamic>;
    } catch (_) {
      throw ApiException(
          statusCode: response.statusCode, message: '응답 데이터를 파싱하는 데 실패했습니다.');
    }
  }

  static Future<void> delete(
    String path, {
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path);
    final response = await _client.delete(
      uri,
      headers: {'Content-Type': 'application/json', ...?headers},
    );
    if (response.statusCode >= 400) {
      if (response.statusCode == 401) AuthService.instance.logout();
      String message = '요청에 실패했습니다.';
      try {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        message = errorData['errorDescription'] as String? ??
            errorData['message'] as String? ??
            message;
      } catch (_) {}
      throw ApiException(statusCode: response.statusCode, message: message);
    }
  }

  static Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic> body = const {},
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParams: queryParams);
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json', ...?headers},
      body: body.isEmpty ? null : jsonEncode(body),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic> body = const {},
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParams: queryParams);
    final response = await _client.put(
      uri,
      headers: {'Content-Type': 'application/json', ...?headers},
      body: body.isEmpty ? null : jsonEncode(body),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic> body = const {},
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParams: queryParams);
    final response = await _client.patch(
      uri,
      headers: {'Content-Type': 'application/json', ...?headers},
      body: body.isEmpty ? null : jsonEncode(body),
    );
    return _handleResponse(response);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({required this.statusCode, required this.message});
}
