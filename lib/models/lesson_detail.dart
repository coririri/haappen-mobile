class AttachmentView {
  final int attachmentId;
  final String fileName;
  final String mediaSource;

  const AttachmentView({
    required this.attachmentId,
    required this.fileName,
    required this.mediaSource,
  });

  factory AttachmentView.fromJson(Map<String, dynamic> json) => AttachmentView(
        attachmentId: json['attachmentId'] as int,
        fileName: json['fileName'] as String,
        mediaSource: json['mediaSource'] as String,
      );
}

class MemoMedia {
  final int memoMediaId;
  final String mediaName;
  final String mediaSource;
  final int mediaSequence;
  final String title;
  final List<AttachmentView> attachmentViews;

  const MemoMedia({
    required this.memoMediaId,
    required this.mediaName,
    required this.mediaSource,
    required this.mediaSequence,
    required this.title,
    required this.attachmentViews,
  });

  factory MemoMedia.fromJson(Map<String, dynamic> json) => MemoMedia(
        memoMediaId: json['memoMediaId'] as int,
        mediaName: json['mediaName'] as String,
        mediaSource: json['mediaSource'] as String,
        mediaSequence: json['mediaSequence'] as int,
        title: json['title'] as String? ?? '',
        attachmentViews: (json['attachmentViews'] as List<dynamic>? ?? [])
            .map((e) => AttachmentView.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class LessonDetail {
  final int memoId;
  final String progressed;
  final String homework;
  final List<MemoMedia> memoMediaViews;

  const LessonDetail({
    required this.memoId,
    required this.progressed,
    required this.homework,
    required this.memoMediaViews,
  });

  factory LessonDetail.fromJson(Map<String, dynamic> json) => LessonDetail(
        memoId: json['memoId'] as int,
        progressed: json['progressed'] as String? ?? '',
        homework: json['homework'] as String? ?? '',
        memoMediaViews: (json['memoMediaViews'] as List<dynamic>? ?? [])
            .map((e) => MemoMedia.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
