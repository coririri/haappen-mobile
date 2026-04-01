import 'package:flutter/material.dart';
import '../../widgets/main_header.dart';

class LessonOverviewPage extends StatelessWidget {
  const LessonOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const MainHeader(),
          const Expanded(child: Center(child: Text('강좌 목록'))),
        ],
      ),
    );
  }
}
