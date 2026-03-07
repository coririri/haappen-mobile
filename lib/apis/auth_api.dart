import 'package:haanppen_mobile/services/api_client.dart';

class AuthApi {
  static const _login = '/login';

  static Future<String> login({
    required String id,
    required String password,
  }) async {
    final data = await ApiClient.post(
      _login,
      body: {'userPhoneNumber': id, 'password': password},
    );

    return data['accessToken'] as String;
  }
}
