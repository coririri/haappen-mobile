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

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final accessToken = json['accessToken'];
    if (accessToken is! String) {
      throw const ApiException(statusCode: 0, message: '응답에서 액세스 토큰을 찾을 수 없습니다.');
    }
    final userName = json['userName'];
    if (userName is! String) {
      throw const ApiException(statusCode: 0, message: '응답에서 사용자 이름을 찾을 수 없습니다.');
    }
    final role = json['role'];
    if (role is! String) {
      throw const ApiException(statusCode: 0, message: '응답에서 권한 정보를 찾을 수 없습니다.');
    }
    return LoginResponse(accessToken: accessToken, userName: userName, role: role);
  }
}

class AuthApi {
  static const _login = '/login';
  static const _passwordVerification = '/accounts/password/verification';

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

  static Future<void> sendPasswordResetCode({
    required String phoneNumber,
  }) async {
    await ApiClient.post(
      _passwordVerification,
      queryParams: {'phoneNumber': phoneNumber},
    );
  }

  static Future<String> verifyPasswordCode({
    required String phoneNumber,
    required String code,
  }) async {
    final data = await ApiClient.put(
      _passwordVerification,
      queryParams: {'phoneNumber': phoneNumber, 'verificationCode': code},
    );

    final password = data['changedPassword'];
    if (password is! String) {
      throw const ApiException(statusCode: 0, message: '응답에서 비밀번호를 찾을 수 없습니다.');
    }

    return password;
  }
}
