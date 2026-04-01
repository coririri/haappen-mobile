import 'package:flutter/material.dart';
import 'package:haanppen_mobile/widgets/main_header.dart';

class OnlineLessonPage extends StatelessWidget {
  final int onlineCourseId;
  final int videoId;
  final String courseName;

  const OnlineLessonPage({
    super.key,
    required this.onlineCourseId,
    required this.videoId,
    required this.courseName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const MainHeader(),
          Expanded(
            child: Center(
              child: Text('온라인 강의 (courseId: $onlineCourseId, videoId: $videoId)'),
            ),
          ),
        ],
      ),
    );
  }
}
