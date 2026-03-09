import 'package:flutter/material.dart';
import '../../widgets/main_header.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          MainHeader(),
          Expanded(child: Center(child: Text('메인 페이지'))),
        ],
      ),
    );
  }
}
