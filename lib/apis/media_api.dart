import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:haanppen_mobile/constants/api_constants.dart';
import 'package:haanppen_mobile/services/auth_service.dart';
import 'package:haanppen_mobile/services/storage_service.dart';

class MediaApi {
  /// 이미지를 S3에 업로드하고 서버에서 반환한 경로 문자열을 반환합니다.
  static Future<String> uploadImage(
      Uint8List bytes, String filename) async {
    final token = await StorageService.getAccessToken();
    final uri =
        Uri.parse('${ApiConstants.baseUrl}/media/image');

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: filename,
      ));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode >= 400) {
      if (streamed.statusCode == 401) AuthService.instance.logout();
      throw Exception('이미지 업로드 실패 (${streamed.statusCode})');
    }

    // 서버가 순수 문자열을 반환하는 경우 따옴표 제거
    return body.replaceAll('"', '').trim();
  }

  /// 서버에서 받은 경로로 전체 이미지 URL을 생성합니다.
  static String imageUrl(String path) =>
      '${ApiConstants.baseUrl}/media/$path';
}
