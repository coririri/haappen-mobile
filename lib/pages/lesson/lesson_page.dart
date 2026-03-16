import 'package:flutter/material.dart';
import '../../widgets/main_header.dart';

class LessonPage extends StatelessWidget {
  final int courseId;
  final String date;

  const LessonPage({
    super.key,
    required this.courseId,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const MainHeader(),
          Expanded(child: Center(child: Text('강의 (courseId: $courseId, date: $date)'))),
        ],
      ),
    );
  }
}
