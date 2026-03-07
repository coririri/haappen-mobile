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

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 400) {
      throw ApiException(
        statusCode: response.statusCode,
        message: data['errorDescription'] as String? ?? data['message'] as String? ?? '요청에 실패했습니다.',
      );
    }

    return data;
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({required this.statusCode, required this.message});
}
