import 'package:flutter/material.dart';
import '../../parking/screens/main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 🔥 자동 로그인 체크 상태를 저장할 변수
  bool _isAutoLogin = false;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. 로고 및 타이틀
                Icon(Icons.local_parking, size: 80, color: primaryColor),
                const SizedBox(height: 16),
                Text(
                  'Au-Park',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryColor),
                ),
                const SizedBox(height: 8),
                const Text(
                  '안산대학교 무정차 자동 정산 시스템',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 48),

                // 2. 입력창
                TextField(
                  decoration: InputDecoration(
                    labelText: '아이디/이메일',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                
                // 🔥 3. 추가된 자동 로그인 영역
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _isAutoLogin,
                        activeColor: primaryColor, // 체크되었을 때 메인 네비 색상으로 변경
                        onChanged: (value) {
                          setState(() {
                            _isAutoLogin = value ?? false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        // 글자를 눌러도 체크박스가 토글되도록 편의성 제공
                        setState(() {
                          _isAutoLogin = !_isAutoLogin;
                        });
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          '자동 로그인',
                          style: TextStyle(color: Colors.black87, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 4. 로그인 버튼
                ElevatedButton(
                  onPressed: () {
                    // 🔥 로그인 버튼을 누르면 메인 화면으로 이동하도록 수정
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('로그인', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                
                const SizedBox(height: 16),

                // 5. 아이디/비밀번호 찾기, 회원가입
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {},
                      child: const Text('아이디 찾기', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ),
                    const Text('|', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    TextButton(
                      onPressed: () {},
                      child: const Text('비밀번호 찾기', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ),
                    const Text('|', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    TextButton(
                      onPressed: () {},
                      child: Text('회원가입', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // 6. 소셜 로그인 구분선
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('또는 소셜 계정으로 로그인', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                  ],
                ),
                const SizedBox(height: 24),

                // 7. 소셜 로그인 버튼들
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSocialImageButton('assets/images/kakao.png', const Color(0xFFFEE500)), 
                    _buildSocialImageButton('assets/images/google.png', Colors.white), 
                    _buildSocialIconButton(Icons.apple, Colors.black, Colors.white), 
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 이미지를 사용하는 소셜 버튼 (카카오, 구글용)
  Widget _buildSocialImageButton(String imagePath, Color bgColor) {
    return _buildBaseSocialButton(
      bgColor: bgColor,
      child: Image.asset(
        imagePath,
        width: 32,
        height: 32,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) => const Text('IMG', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  // 아이콘을 사용하는 소셜 버튼 (애플용)
  Widget _buildSocialIconButton(IconData icon, Color bgColor, Color iconColor) {
    return _buildBaseSocialButton(
      bgColor: bgColor,
      child: Icon(icon, color: iconColor, size: 28),
    );
  }

  // 공통 뼈대
  Widget _buildBaseSocialButton({required Color bgColor, required Widget child}) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: bgColor == Colors.white ? Border.all(color: Colors.grey.shade300) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}