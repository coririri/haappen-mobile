import 'package:haanppen_mobile/apis/media_api.dart';
import 'package:haanppen_mobile/models/question.dart';

class QuestionDetail {
  final int questionId;
  final String title;
  final String content;
  final List<String> imageUrls; // 전체 URL 변환 완료된 목록
  final List<String> rawImagePaths; // 서버 원본 경로 (수정 시 사용)
  final String registeredDateTime;
  final QuestionMember registeredMember;
  final QuestionMember? targetMember;
  final List<QuestionComment> comments;

  const QuestionDetail({
    required this.questionId,
    required this.title,
    required this.content,
    required this.imageUrls,
    required this.rawImagePaths,
    required this.registeredDateTime,
    required this.registeredMember,
    this.targetMember,
    required this.comments,
  });

  factory QuestionDetail.fromJson(Map<String, dynamic> json) {
    final rawPaths = (json['imageUrls'] as List<dynamic>)
        .map((e) => (e as Map<String, dynamic>)['imageUrl'] as String? ?? '')
        .where((p) => p.isNotEmpty)
        .toList();

    return QuestionDetail(
      questionId: json['questionId'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      rawImagePaths: rawPaths,
      imageUrls: rawPaths.map(MediaApi.imageUrl).toList(),
      registeredDateTime: json['registeredDateTime'] as String,
      registeredMember: QuestionMember.fromJson(
          json['registeredMember'] as Map<String, dynamic>),
      targetMember: json['targetMember'] != null
          ? QuestionMember.fromJson(
              json['targetMember'] as Map<String, dynamic>)
          : null,
      comments: (json['comments'] as List<dynamic>)
          .map((e) =>
              QuestionComment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class QuestionComment {
  final int commentId;
  final String content;
  final String registeredDateTime;
  final QuestionMember registeredMember;
  final List<String> imageUrls;
  final List<String> rawImagePaths;

  const QuestionComment({
    required this.commentId,
    required this.content,
    required this.registeredDateTime,
    required this.registeredMember,
    required this.imageUrls,
    required this.rawImagePaths,
  });

  factory QuestionComment.fromJson(Map<String, dynamic> json) {
    final rawPaths = (json['imageUrls'] as List<dynamic>? ?? [])
        .map((e) => (e as Map<String, dynamic>)['imageUrl'] as String? ?? '')
        .where((p) => p.isNotEmpty)
        .toList();

    return QuestionComment(
      commentId: json['commentId'] as int,
      content: json['content'] as String,
      registeredDateTime: json['registeredDateTime'] as String,
      registeredMember: QuestionMember.fromJson(
          json['registeredMember'] as Map<String, dynamic>),
      imageUrls: rawPaths.map(MediaApi.imageUrl).toList(),
      rawImagePaths: rawPaths,
    );
  }
}
