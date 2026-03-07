import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:haanppen_mobile/constants/api_constants.dart';

class ApiClient {
  static final _client = http.Client();

  static Uri _buildUri(String path, {Map<String, String>? queryParams}) {
    return Uri.parse('${ApiConstants.baseUrl}$path')
        .replace(queryParameters: queryParams);
  }

  static Future<Map<String, dynamic>> _handleResponse(http.Response response) {
    if (response.statusCode >= 400) {
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
      return Future.value(jsonDecode(response.body) as Map<String, dynamic>);
    } catch (_) {
      throw ApiException(
          statusCode: response.statusCode, message: '응답 데이터를 파싱하는 데 실패했습니다.');
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
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({required this.statusCode, required this.message});
}
