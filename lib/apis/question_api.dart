import 'package:haanppen_mobile/models/question.dart';
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
}
