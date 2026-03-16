import '../services/api_client.dart';
import '../services/storage_service.dart';

class CourseMemo {
  final int courseId;
  final String courseName;
  final DateTime registeredDateTime;

  const CourseMemo({
    required this.courseId,
    required this.courseName,
    required this.registeredDateTime,
  });

  factory CourseMemo.fromJson(Map<String, dynamic> json) => CourseMemo(
        courseId: json['courseId'] as int,
        courseName: json['courseName'] as String,
        registeredDateTime:
            DateTime.parse(json['registeredDateTime'] as String),
      );
}

class CourseApi {
  static Future<List<CourseMemo>> getMonthlyCourses(String monthInfo) async {
    final token = await StorageService.getAccessToken();
    final data = await ApiClient.getList(
      '/courses/memos/month',
      queryParams: {'monthInfo': monthInfo},
      headers: {'Authorization': 'Bearer $token'},
    );
    return data
        .map((e) => CourseMemo.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
