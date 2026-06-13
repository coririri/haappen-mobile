import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:haanppen_mobile/constants/api_constants.dart';
import 'auth_service.dart';
import 'storage_service.dart';

class ApiClient {
  static final _client = http.Client();

  static Uri _buildUri(String path, {Map<String, String>? queryParams}) {
    return Uri.parse('${ApiConstants.baseUrl}$path')
        .replace(queryParameters: queryParams);
  }

  static Map<String, String> _withUpdatedToken(
    Map<String, String> headers,
    String newToken,
  ) {
    if (!headers.containsKey('Authorization')) return headers;
    return {...headers, 'Authorization': 'Bearer $newToken'};
  }

  static Future<bool> _tryRefreshToken() async {
    final refreshToken = await StorageService.getRefreshToken();
    if (refreshToken == null) return false;
    try {
      final uri = _buildUri('/login/refresh');
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'refreshToken=$refreshToken',
        },
      );
      if (response.statusCode != 200) return false;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final newAccessToken = body['accessToken'] as String?;
      if (newAccessToken == null) return false;
      await StorageService.saveAccessToken(newAccessToken);
      final newSetCookie = response.headers['set-cookie'];
      if (newSetCookie != null) {
        final match = RegExp(r'refreshToken=([^;]+)').firstMatch(newSetCookie);
        final newRefreshToken = match?.group(1);
        if (newRefreshToken != null) {
          await StorageService.saveRefreshToken(newRefreshToken);
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> _handleResponse(http.Response response) {
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

  static Future<http.Response> postRaw(
    String path, {
    Map<String, dynamic> body = const {},
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path);
    return _client.post(
      uri,
      headers: {'Content-Type': 'application/json', ...?headers},
      body: body.isEmpty ? null : jsonEncode(body),
    );
  }

  static Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParams: queryParams);
    var reqHeaders = {'Content-Type': 'application/json', ...?headers};
    var response = await _client.get(uri, headers: reqHeaders);
    if (response.statusCode == 401 && await _tryRefreshToken()) {
      final newToken = await StorageService.getAccessToken();
      if (newToken != null) reqHeaders = _withUpdatedToken(reqHeaders, newToken);
      response = await _client.get(uri, headers: reqHeaders);
    }
    return _handleResponse(response);
  }

  static Future<List<dynamic>> getList(
    String path, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParams: queryParams);
    var reqHeaders = {'Content-Type': 'application/json', ...?headers};
    var response = await _client.get(uri, headers: reqHeaders);
    if (response.statusCode == 401 && await _tryRefreshToken()) {
      final newToken = await StorageService.getAccessToken();
      if (newToken != null) reqHeaders = _withUpdatedToken(reqHeaders, newToken);
      response = await _client.get(uri, headers: reqHeaders);
    }
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
    var reqHeaders = {'Content-Type': 'application/json', ...?headers};
    var response = await _client.delete(uri, headers: reqHeaders);
    if (response.statusCode == 401 && await _tryRefreshToken()) {
      final newToken = await StorageService.getAccessToken();
      if (newToken != null) reqHeaders = _withUpdatedToken(reqHeaders, newToken);
      response = await _client.delete(uri, headers: reqHeaders);
    }
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
    var reqHeaders = {'Content-Type': 'application/json', ...?headers};
    var response = await _client.post(
      uri,
      headers: reqHeaders,
      body: body.isEmpty ? null : jsonEncode(body),
    );
    if (response.statusCode == 401 && await _tryRefreshToken()) {
      final newToken = await StorageService.getAccessToken();
      if (newToken != null) reqHeaders = _withUpdatedToken(reqHeaders, newToken);
      response = await _client.post(
        uri,
        headers: reqHeaders,
        body: body.isEmpty ? null : jsonEncode(body),
      );
    }
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic> body = const {},
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParams: queryParams);
    var reqHeaders = {'Content-Type': 'application/json', ...?headers};
    var response = await _client.put(
      uri,
      headers: reqHeaders,
      body: body.isEmpty ? null : jsonEncode(body),
    );
    if (response.statusCode == 401 && await _tryRefreshToken()) {
      final newToken = await StorageService.getAccessToken();
      if (newToken != null) reqHeaders = _withUpdatedToken(reqHeaders, newToken);
      response = await _client.put(
        uri,
        headers: reqHeaders,
        body: body.isEmpty ? null : jsonEncode(body),
      );
    }
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic> body = const {},
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParams: queryParams);
    var reqHeaders = {'Content-Type': 'application/json', ...?headers};
    var response = await _client.patch(
      uri,
      headers: reqHeaders,
      body: body.isEmpty ? null : jsonEncode(body),
    );
    if (response.statusCode == 401 && await _tryRefreshToken()) {
      final newToken = await StorageService.getAccessToken();
      if (newToken != null) reqHeaders = _withUpdatedToken(reqHeaders, newToken);
      response = await _client.patch(
        uri,
        headers: reqHeaders,
        body: body.isEmpty ? null : jsonEncode(body),
      );
    }
    return _handleResponse(response);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({required this.statusCode, required this.message});
}
