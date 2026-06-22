import '../models/course.dart';
import '../models/workbook.dart';
import '../services/api_client.dart';
import '../services/storage_service.dart';

class WorkbookApi {
  static const _testPapers = '/test-papers';

  static Future<List<Course>> getWorkbookCourses() async {
    final token = await StorageService.getAccessToken();
    final data = await ApiClient.getList(
      _testPapers,
      headers: {'Authorization': 'Bearer $token'},
    );
    return data.map((e) {
      final json = e as Map<String, dynamic>;
      return Course(
        courseId: json['testPaperId'] as int,
        courseName: json['testPaperName'] as String,
        type: 'workbook',
        teacherName: json['teacherName'] as String?,
      );
    }).toList();
  }

  static Future<WorkbookLecture?> getWorkbookLecture(int testPaperId) async {
    final token = await StorageService.getAccessToken();
    try {
      final data = await ApiClient.get(
        '$_testPapers/$testPaperId/lecture',
        headers: {'Authorization': 'Bearer $token'},
      );
      return WorkbookLecture.fromJson(data);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }
}
