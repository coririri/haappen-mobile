import 'package:flutter/material.dart';
import '../../widgets/main_header.dart';

class QuestionDetailPage extends StatelessWidget {
  final String id;

  const QuestionDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const MainHeader(),
          Expanded(child: Center(child: Text('질문 상세: $id'))),
        ],
      ),
    );
  }
}
