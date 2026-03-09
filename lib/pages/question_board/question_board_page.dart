import 'package:flutter/material.dart';
import '../../widgets/main_header.dart';

class QuestionBoardPage extends StatelessWidget {
  const QuestionBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          MainHeader(),
          Expanded(child: Center(child: Text('질문게시판 목록'))),
        ],
      ),
    );
  }
}
