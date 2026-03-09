import 'package:flutter/material.dart';
import '../../widgets/main_header.dart';

class LessonOverviewPage extends StatelessWidget {
  const LessonOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          MainHeader(),
          Expanded(child: Center(child: Text('강의 개요'))),
        ],
      ),
    );
  }
}
