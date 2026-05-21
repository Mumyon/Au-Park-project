import 'package:flutter/material.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add_alt_1, size: 80, color: Theme.of(context).primaryColor),
            const SizedBox(height: 20),
            const Text(
              '회원가입 화면 (준비 중)', 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 10),
            const Text(
              '나중에 Firebase와 연동될 예정입니다!', 
              style: TextStyle(color: Colors.grey)
            ),
          ],
        ),
      ),
    );
  }
}