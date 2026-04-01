import '../models/lesson_overview.dart';
import '../services/api_client.dart';
import '../services/storage_service.dart';

class LessonOverviewApi {
  static Future<Map<String, String>> _authHeader() async {
    final token = await StorageService.getAccessToken();
    return {'Authorization': 'Bearer $token'};
  }

  static Future<List<Category>> getRootCategories() async {
    final data = await ApiClient.getList(
      '/online-courses/category/root',
      headers: await _authHeader(),
    );
    return data
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Category>> getSubCategories(int categoryId) async {
    final data = await ApiClient.getList(
      '/online-courses/category/$categoryId',
      headers: await _authHeader(),
    );
    return data
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<CourseOverview>> getCoursesByCategory(
      int categoryId) async {
    final data = await ApiClient.getList(
      '/online-courses/categories/$categoryId',
      headers: await _authHeader(),
    );
    return data
        .map((e) => CourseOverview.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
