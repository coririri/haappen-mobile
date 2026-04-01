import '../models/course.dart';
import '../models/lesson_detail.dart';
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

  static Future<List<Course>> getOwnCourses() async {
    final token = await StorageService.getAccessToken();
    final data = await ApiClient.getList(
      '/courses/my',
      headers: {'Authorization': 'Bearer $token'},
    );
    return data
        .map((e) => Course.fromJson(e as Map<String, dynamic>, 'offline'))
        .toList();
  }

  static Future<List<Course>> getOwnOnlineCourses() async {
    final token = await StorageService.getAccessToken();
    final data = await ApiClient.getList(
      '/online-courses/my',
      headers: {'Authorization': 'Bearer $token'},
    );
    return data
        .map((e) => Course.fromJson(e as Map<String, dynamic>, 'online'))
        .toList();
  }

  static Future<({List<Lesson> lessons, LessonPageInfo pageInfo})>
      getLessonsByClassId({
    required int courseId,
    required int sortIndex,
    required bool sortAsc,
    required int page,
  }) async {
    final token = await StorageService.getAccessToken();
    final direction = sortAsc ? 'ASC' : 'DESC';
    final sort = sortIndex == 0 ? 'targetDate,$direction' : 'title,$direction';
    final res = await ApiClient.get(
      '/courses/$courseId/memos',
      queryParams: {'sort': sort, 'page': '$page', 'size': '8'},
      headers: {'Authorization': 'Bearer $token'},
    );
    final rawList = res['data'] as List<dynamic>;
    final lessons =
        rawList.map((e) => Lesson.fromJson(e as Map<String, dynamic>)).toList();
    final pageInfo =
        LessonPageInfo.fromJson(res['pageInfo'] as Map<String, dynamic>);
    return (lessons: lessons, pageInfo: pageInfo);
  }

  static Future<OnlineLessonInfo> getOnlineLessonDetail(
      int onlineCourseId) async {
    final token = await StorageService.getAccessToken();
    final res = await ApiClient.get(
      '/online-courses/lesson/$onlineCourseId',
      headers: {'Authorization': 'Bearer $token'},
    );
    return OnlineLessonInfo.fromJson(res);
  }

  static Future<LessonDetail> getLessonByDateAndCourse({
    required int courseId,
    required String localDate,
  }) async {
    final token = await StorageService.getAccessToken();
    final res = await ApiClient.get(
      '/courses/memos',
      queryParams: {'courseId': '$courseId', 'localDate': localDate},
      headers: {'Authorization': 'Bearer $token'},
    );
    return LessonDetail.fromJson(res);
  }
}
