import 'package:flutter/material.dart';

class UserProfile {
  String name;
  String email;
  String department;

  UserProfile({
    required this.name,
    required this.email,
    required this.department,
  });
}

class UserProvider with ChangeNotifier {
  // 🔥 소속(department)의 기본값을 빈 값으로 변경했습니다.
  UserProfile _user = UserProfile(
    name: '사용자',
    email: '',
    department: '', 
  );

  UserProfile get user => _user;

  Object? get email => null;

  void setUser({required String name, required String email, required String department}) {
    _user = UserProfile(name: name, email: email, department: department);
    notifyListeners(); 
  }

  // 🔥 로그아웃 시에도 소속은 빈 값으로 청소합니다.
  void clearUser() {
    _user = UserProfile(
      name: '사용자',
      email: '',
      department: '', 
    );
    notifyListeners();
  }

  void updateProfile(String text, String text2) {}
}