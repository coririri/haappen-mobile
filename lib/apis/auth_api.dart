import 'package:haanppen_mobile/services/api_client.dart';

class LoginResponse {
  final String accessToken;
  final String userName;
  final String role;

  const LoginResponse({
    required this.accessToken,
    required this.userName,
    required this.role,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        accessToken: json['accessToken'] as String,
        userName: json['userName'] as String,
        role: json['role'] as String,
      );
}

class AuthApi {
  static const _login = '/login';

  static Future<LoginResponse> login({
    required String id,
    required String password,
  }) async {
    final data = await ApiClient.post(
      _login,
      body: {'userPhoneNumber': id, 'password': password},
    );

    return LoginResponse.fromJson(data);
  }
}
