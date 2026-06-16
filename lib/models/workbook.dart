class WorkbookVideo {
  final String fileName;
  final String path;
  final int runtimeDuration;

  const WorkbookVideo({
    required this.fileName,
    required this.path,
    required this.runtimeDuration,
  });

  int get problemNumber {
    final name = fileName.endsWith('.mp4')
        ? fileName.substring(0, fileName.length - 4)
        : fileName;
    return int.tryParse(name) ?? 0;
  }

  factory WorkbookVideo.fromJson(Map<String, dynamic> json) => WorkbookVideo(
        fileName: json['fileName'] as String,
        path: json['path'] as String,
        runtimeDuration: (json['runtimeDuration'] as num).toInt(),
      );
}

class WorkbookLecture {
  final int lectureId;
  final int testPaperId;
  final String testPaperName;
  final String lectureName;
  final String? description;
  final List<WorkbookVideo> videos;

  const WorkbookLecture({
    required this.lectureId,
    required this.testPaperId,
    required this.testPaperName,
    required this.lectureName,
    this.description,
    required this.videos,
  });

  factory WorkbookLecture.fromJson(Map<String, dynamic> json) => WorkbookLecture(
        lectureId: json['lectureId'] as int,
        testPaperId: json['testPaperId'] as int,
        testPaperName: json['testPaperName'] as String,
        lectureName: json['lectureName'] as String,
        description: json['description'] as String?,
        videos: (json['videos'] as List<dynamic>)
            .map((e) => WorkbookVideo.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
