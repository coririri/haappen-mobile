import '../services/api_client.dart';
import '../services/storage_service.dart';

class NoticeBanner {
  final int bannerId;
  final String bannerContent;

  const NoticeBanner({required this.bannerId, required this.bannerContent});

  factory NoticeBanner.fromJson(Map<String, dynamic> json) => NoticeBanner(
        bannerId: json['bannerId'] as int,
        bannerContent: json['bannerContent'] as String,
      );
}

class NoticeBannerApi {
  static Future<List<NoticeBanner>> getNoticeBanners() async {
    final token = await StorageService.getAccessToken();
    final data = await ApiClient.getList(
      '/banners',
      headers: {'Authorization': 'Bearer $token'},
    );
    return data.map((e) => NoticeBanner.fromJson(e as Map<String, dynamic>)).toList();
  }
}
