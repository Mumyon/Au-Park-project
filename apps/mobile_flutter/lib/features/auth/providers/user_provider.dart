import 'package:flutter/material.dart';

class UserProfile {
  String id;
  String name;
  String email;
  String department;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
  });
}

class UserProvider with ChangeNotifier {
  // 🔥 소속(department)의 기본값을 빈 값으로 변경했습니다.
  UserProfile _user = UserProfile(
    id: '',
    name: '사용자',
    email: '',
    department: '', 
  );

  UserProfile get user => _user;

  String get userId => _user.id;
  String get email => _user.email;

  void setUser({String id = '', required String name, required String email, required String department}) {
    _user = UserProfile(id: id, name: name, email: email, department: department);
    notifyListeners(); 
  }

  // 🔥 로그아웃 시에도 소속은 빈 값으로 청소합니다.
  void clearUser() {
    _user = UserProfile(
      id: '',
      name: '사용자',
      email: '',
      department: '', 
    );
    notifyListeners();
  }

  void updateProfile(String text, String text2) {}
}
