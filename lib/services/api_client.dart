import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:haanppen_mobile/constants/api_constants.dart';

class ApiClient {
  static final _client = http.Client();

  static Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        ...?headers,
      },
      body: jsonEncode(body),
    );

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
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
          statusCode: response.statusCode, message: '응답 데이터를 파싱하는 데 실패했습니다.');
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({required this.statusCode, required this.message});
}
