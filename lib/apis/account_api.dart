import '../services/api_client.dart';

class AccountInfo {
  final String userName;
  final String phoneNumber;

  const AccountInfo({required this.userName, required this.phoneNumber});

  factory AccountInfo.fromJson(Map<String, dynamic> json) {
    final userName = json['userName'];
    if (userName is! String) {
      throw const ApiException(statusCode: 0, message: '응답에서 이름을 찾을 수 없습니다.');
    }
    final phoneNumber = json['phoneNumber'];
    if (phoneNumber is! String) {
      throw const ApiException(statusCode: 0, message: '응답에서 전화번호를 찾을 수 없습니다.');
    }
    return AccountInfo(userName: userName, phoneNumber: phoneNumber);
  }
}

class AccountApi {
  static const _accountsMy = '/accounts/my';

  static Future<AccountInfo> getMyInfo({required String accessToken}) async {
    final data = await ApiClient.get(
      _accountsMy,
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    return AccountInfo.fromJson(data);
  }

  static Future<void> updateAccountInfo({
    required String accessToken,
    required String name,
    required String phoneNumber,
    required String password,
    required String newPassword,
  }) async {
    await ApiClient.patch(
      _accountsMy,
      body: {
        'phoneNumber': phoneNumber,
        'name': name,
        'prevPassword': password,
        'newPassword': newPassword,
      },
      headers: {'Authorization': 'Bearer $accessToken'},
    );
  }
}
