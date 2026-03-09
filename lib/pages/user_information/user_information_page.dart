import 'package:flutter/material.dart';
import '../../widgets/main_header.dart';

class UserInformationPage extends StatelessWidget {
  const UserInformationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          MainHeader(),
          Expanded(child: Center(child: Text('사용자 정보 수정'))),
        ],
      ),
    );
  }
}
