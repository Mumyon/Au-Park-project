import 'package:flutter/material.dart';

// 유저 데이터 틀(Model)을 파일 하나에 같이 간단하게 정의합니다.
class UserModel {
  final String name;
  final String department;

  UserModel({required this.name, required this.department});
}

// 유저 정보 방송국
class UserProvider with ChangeNotifier {
  // 초기 더미 데이터 (영진님의 실제 정보)
  UserModel _user = UserModel(name: '영진', department: '인공지능소프트웨어학과');

  UserModel get user => _user;

  // 정보 수정 로직
  void updateProfile(String newName, String newDepartment) {
    _user = UserModel(name: newName, department: newDepartment);
    notifyListeners(); // 🔥 "프로필 바뀌었어! 화면들 다 새로고침 해!" 라고 방송함
  }
}