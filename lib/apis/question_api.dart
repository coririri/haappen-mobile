import 'package:haanppen_mobile/models/question.dart';
import 'package:haanppen_mobile/models/question_detail.dart';
import 'package:haanppen_mobile/models/teacher.dart';
import 'package:haanppen_mobile/services/api_client.dart';
import 'package:haanppen_mobile/services/storage_service.dart';

class QuestionApi {
  static Future<Map<String, dynamic>> _fetch(
      String path, int page, String searchValue) async {
    final token = await StorageService.getAccessToken();
    return ApiClient.get(
      path,
      queryParams: {
        'size': '8',
        'page': '$page',
        'sort': 'date,DESC',
        'title': searchValue,
      },
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<({List<Question> questions, QuestionPageInfo pageInfo})>
      getQuestions(int page, String searchValue) async {
    final res = await _fetch('/board/questions', page, searchValue);
    return _parse(res);
  }

  static Future<({List<Question> questions, QuestionPageInfo pageInfo})>
      getMyQuestions(int page, String searchValue) async {
    final res = await _fetch('/board/questions/my', page, searchValue);
    return _parse(res);
  }

  static ({List<Question> questions, QuestionPageInfo pageInfo}) _parse(
      Map<String, dynamic> res) {
    final rawList = res['data'] as List<dynamic>;
    final questions =
        rawList.map((e) => Question.fromJson(e as Map<String, dynamic>)).toList();
    final pageInfo = QuestionPageInfo.fromJson(
        res['pageInfo'] as Map<String, dynamic>);
    return (questions: questions, pageInfo: pageInfo);
  }

  static Future<List<Teacher>> getAllTeachers() async {
    final token = await StorageService.getAccessToken();
    final data = await ApiClient.getList(
      '/members/teachers/all',
      headers: {'Authorization': 'Bearer $token'},
    );
    return data.map((e) => Teacher.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> writeQuestion({
    required String title,
    required String content,
    required List<String> images,
    int? targetMemberId,
  }) async {
    final token = await StorageService.getAccessToken();
    await ApiClient.post(
      '/board/questions',
      body: {
        'title': title,
        'content': content,
        'images': images,
        'targetMemberId': targetMemberId,
      },
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<QuestionDetail> getQuestionDetail(int id) async {
    final token = await StorageService.getAccessToken();
    final res = await ApiClient.get(
      '/board/questions/$id',
      headers: {'Authorization': 'Bearer $token'},
    );
    return QuestionDetail.fromJson(res);
  }

  static Future<void> deleteQuestion(int id) async {
    final token = await StorageService.getAccessToken();
    await ApiClient.delete(
      '/board/questions/$id',
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<void> modifyQuestion({
    required int id,
    required String title,
    required String content,
    required List<String> existingImagePaths,
    required List<String> newImagePaths,
    int? targetMemberId,
  }) async {
    final token = await StorageService.getAccessToken();
    final body = <String, dynamic>{
      'questionId': id,
      'title': title,
      'content': content,
      'imageSources': [...existingImagePaths, ...newImagePaths],
    };
    if (targetMemberId != null && targetMemberId != -1) {
      body['targetMemberId'] = targetMemberId;
    }
    await ApiClient.put(
      '/board/questions',
      body: body,
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<void> writeComment({
    required int questionId,
    required String content,
    required List<String> images,
  }) async {
    final token = await StorageService.getAccessToken();
    await ApiClient.post(
      '/board/comments',
      body: {'questionId': questionId, 'content': content, 'images': images},
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<void> deleteComment(int commentId) async {
    final token = await StorageService.getAccessToken();
    await ApiClient.delete(
      '/board/comments/$commentId',
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<void> modifyComment({
    required int commentId,
    required String content,
    required List<String> existingImagePaths, // 기존 유지할 이미지 경로
    required List<String> newImagePaths,      // 새로 업로드된 이미지 경로
  }) async {
    final token = await StorageService.getAccessToken();
    await ApiClient.put(
      '/board/comments',
      body: {
        'commentId': commentId,
        'content': content,
        'imageSources': [...existingImagePaths, ...newImagePaths],
      },
      headers: {'Authorization': 'Bearer $token'},
    );
  }
}
