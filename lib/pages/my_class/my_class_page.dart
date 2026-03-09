import 'package:flutter/material.dart';
import '../../widgets/main_header.dart';

class MyClassPage extends StatelessWidget {
  final int classIndex;
  final int sortIndex;
  final String courseType;

  const MyClassPage({
    super.key,
    required this.classIndex,
    required this.sortIndex,
    required this.courseType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const MainHeader(),
          Expanded(
            child: Center(
              child: Text('내 강의실 (classIndex: $classIndex, sortIndex: $sortIndex, courseType: $courseType)'),
            ),
          ),
        ],
      ),
    );
  }
}
