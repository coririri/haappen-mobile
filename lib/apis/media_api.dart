import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
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

    final ext = filename.split('.').last.toLowerCase();
    final mimeType = switch (ext) {
      'jpg' || 'jpeg' => MediaType('image', 'jpeg'),
      'png' => MediaType('image', 'png'),
      'gif' => MediaType('image', 'gif'),
      'webp' => MediaType('image', 'webp'),
      _ => MediaType('image', 'jpeg'),
    };

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: filename,
        contentType: mimeType,
      ));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode >= 400) {
      if (streamed.statusCode == 401) AuthService.instance.logout();
      throw Exception('이미지 업로드 실패 (${streamed.statusCode})');
    }

    // 서버가 {"imageUrl": "..."} 형태로 반환하는 경우 파싱
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['imageUrl'] is String) {
        return decoded['imageUrl'] as String;
      }
    } catch (_) {}
    // 순수 문자열 반환인 경우 따옴표 제거
    return body.replaceAll('"', '').trim();
  }

  /// 모바일에서는 크롭 후 bytes 반환, 웹에서는 그대로 반환.
  /// 크롭을 취소하면 null 반환.
  static Future<Uint8List?> readWithCrop(XFile file) async {
    if (!kIsWeb) {
      final cropped = await ImageCropper().cropImage(
        sourcePath: file.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: '이미지 편집',
            toolbarColor: const Color(0xFF3B82F6),
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: '이미지 편집'),
        ],
      );
      if (cropped == null) return null;
      return cropped.readAsBytes();
    }
    return file.readAsBytes();
  }

  /// 서버에서 받은 경로로 전체 이미지 URL을 생성합니다.
  static String imageUrl(String path) =>
      '${ApiConstants.baseUrl}/media/$path';
}
