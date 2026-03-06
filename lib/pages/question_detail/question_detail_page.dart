import 'package:flutter/material.dart';

class QuestionDetailPage extends StatelessWidget {
  final String id;

  const QuestionDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('질문 상세: $id')),
    );
  }
}
