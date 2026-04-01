class Category {
  final int categoryId;
  final String categoryName;

  const Category({required this.categoryId, required this.categoryName});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        categoryId: json['categoryId'] as int,
        categoryName: json['categoryName'] as String,
      );
}

class LessonCategoryInfo {
  final String parentCategoryName;
  final String categoryName;

  const LessonCategoryInfo({
    required this.parentCategoryName,
    required this.categoryName,
  });

  factory LessonCategoryInfo.fromJson(Map<String, dynamic> json) =>
      LessonCategoryInfo(
        parentCategoryName: json['parentCategoryName'] as String? ?? '',
        categoryName: json['categoryName'] as String? ?? '',
      );
}

class CourseOverview {
  final int courseId;
  final String courseName;
  final String? imageSrc;
  final String teacherName;
  final LessonCategoryInfo lessonCategoryInfo;

  const CourseOverview({
    required this.courseId,
    required this.courseName,
    this.imageSrc,
    required this.teacherName,
    required this.lessonCategoryInfo,
  });

  factory CourseOverview.fromJson(Map<String, dynamic> json) => CourseOverview(
        courseId: json['courseId'] as int,
        courseName: json['courseName'] as String,
        imageSrc: json['imageSrc'] as String?,
        teacherName:
            (json['teacherPreview'] as Map<String, dynamic>?)?['teacherName']
                    as String? ??
                '',
        lessonCategoryInfo: LessonCategoryInfo.fromJson(
            json['lessonCategoryInfo'] as Map<String, dynamic>? ?? {}),
      );
}
