import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();

  static const _keyAccessToken = 'accessToken';
  static const _keyUserName = 'userName';
  static const _keyRole = 'role';

  static Future<void> saveLoginData({
    required String accessToken,
    required String userName,
    required String role,
  }) async {
    await Future.wait([
      _storage.write(key: _keyAccessToken, value: accessToken),
      _storage.write(key: _keyUserName, value: userName),
      _storage.write(key: _keyRole, value: role),
    ]);
  }

  static Future<String?> getAccessToken() =>
      _storage.read(key: _keyAccessToken);

  static Future<String?> getUserName() =>
      _storage.read(key: _keyUserName);

  static Future<String?> getRole() =>
      _storage.read(key: _keyRole);

  static Future<void> clear() => _storage.deleteAll();
}
