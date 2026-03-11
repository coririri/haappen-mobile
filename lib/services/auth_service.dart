import 'package:flutter/foundation.dart';
import 'storage_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._();

  AuthService._();

  bool? _isLoggedIn;

  Future<bool> isAuthenticated() async {
    if (_isLoggedIn != null) return _isLoggedIn!;
    try {
      _isLoggedIn = (await StorageService.getAccessToken()) != null;
    } catch (_) {
      _isLoggedIn = false;
    }
    return _isLoggedIn!;
  }

  void setLoggedIn() {
    _isLoggedIn = true;
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    await StorageService.clear();
    notifyListeners();
  }
}
