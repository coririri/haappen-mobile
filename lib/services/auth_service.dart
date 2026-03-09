import 'package:flutter/foundation.dart';
import 'storage_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._();

  AuthService._();

  Future<void> logout() async {
    await StorageService.clear();
    notifyListeners();
  }
}
