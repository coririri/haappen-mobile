class Course {
  final int courseId;
  final String courseName;
  final String type; // 'offline' | 'online'
  final String? teacherName;

  const Course({
    required this.courseId,
    required this.courseName,
    required this.type,
    this.teacherName,
  });

  factory Course.fromJson(Map<String, dynamic> json, String type) => Course(
        courseId: json['courseId'] as int,
        courseName: json['courseName'] as String,
        type: type,
        teacherName:
            (json['teacherPreview'] as Map<String, dynamic>?)?['teacherName']
                as String?,
      );
}

class Lesson {
  final int memoId;
  final String progressed;
  final String targetDate;

  const Lesson({
    required this.memoId,
    required this.progressed,
    required this.targetDate,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
        memoId: json['memoId'] as int,
        progressed: json['progressed'] as String,
        targetDate: json['targetDate'] as String,
      );
}

class LessonPageInfo {
  final int totalItemSize;
  final int currentPage;
  final int pageSize;

  const LessonPageInfo({
    required this.totalItemSize,
    required this.currentPage,
    required this.pageSize,
  });

  factory LessonPageInfo.fromJson(Map<String, dynamic> json) => LessonPageInfo(
        totalItemSize: json['totalItemSize'] as int,
        currentPage: json['currentPage'] as int,
        pageSize: json['pageSize'] as int,
      );
}

class OnlineLessonInfo {
  final String title;
  final String lessonDesc;
  final String lessonRange;
  final List<OnlineVideo> videos;

  const OnlineLessonInfo({
    required this.title,
    required this.lessonDesc,
    required this.lessonRange,
    required this.videos,
  });

  factory OnlineLessonInfo.fromJson(Map<String, dynamic> json) =>
      OnlineLessonInfo(
        title: json['title'] as String? ?? '',
        lessonDesc: json['lessonDesc'] as String? ?? '',
        lessonRange: json['lessonRange'] as String? ?? '',
        videos: (json['onlineVideoDetails'] as List<dynamic>? ?? [])
            .map((e) => OnlineVideo.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class AttachmentDetail {
  final int attachmentId;
  final String attachmentTitle;
  final String url;

  const AttachmentDetail({
    required this.attachmentId,
    required this.attachmentTitle,
    required this.url,
  });

  factory AttachmentDetail.fromJson(Map<String, dynamic> json) =>
      AttachmentDetail(
        attachmentId: json['attachmentId'] as int,
        attachmentTitle: json['attachmentTitle'] as String,
        url: json['url'] as String,
      );
}

class OnlineVideo {
  final int videoId;
  final int videoSequence;
  final String mediaName;
  final String mediaSrc;
  final int? duration;
  final List<AttachmentDetail> attachmentDetails;

  const OnlineVideo({
    required this.videoId,
    required this.videoSequence,
    required this.mediaName,
    required this.mediaSrc,
    this.duration,
    this.attachmentDetails = const [],
  });

  factory OnlineVideo.fromJson(Map<String, dynamic> json) => OnlineVideo(
        videoId: json['videoId'] as int,
        videoSequence: json['videoSequence'] as int,
        mediaName: json['mediaName'] as String,
        mediaSrc: json['mediaSrc'] as String? ?? '',
        duration: json['duration'] as int?,
        attachmentDetails:
            (json['attachmentDetails'] as List<dynamic>? ?? [])
                .map((e) => AttachmentDetail.fromJson(e as Map<String, dynamic>))
                .toList(),
      );
}
