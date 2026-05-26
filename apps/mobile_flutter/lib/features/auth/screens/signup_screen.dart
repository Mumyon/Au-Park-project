import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _vehicleController = TextEditingController(); // 차량번호 컨트롤러
  
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _vehicleController.dispose();
    super.dispose();
  }

  // ✅ 서버와 통신하는 회원가입 로직
  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      // 로딩창 띄우기
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final url = Uri.parse('http://10.0.2.2:3000/api/signup');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': _emailController.text.trim(),
            'password': _passwordController.text.trim(),
            'name': _nameController.text.trim(),
            // 🔥 차량 번호 전송 (입력 안 했으면 기본값으로 셋팅)
            'registeredVehicle': _vehicleController.text.trim().isEmpty 
                ? "등록된 차량 없음" 
                : _vehicleController.text.trim(),
          }),
        );

        if (!mounted) return;
        Navigator.pop(context); // 로딩창 닫기

        final result = jsonDecode(response.body);

        if (response.statusCode == 201 && result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🎉 가입 성공! 이제 로그인해주세요.'), backgroundColor: Colors.green),
          );
          Navigator.pop(context); // 가입 성공 시 로그인 화면으로 복귀
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ 실패: ${result['message']}'), backgroundColor: Colors.redAccent),
          );
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ 서버와 통신 불가. 서버 연결 상태를 확인하세요.'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(title: const Text('회원가입', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey, // 폼 키 등록 (유효성 검사용)
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('새로운 시작, Au-Park', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('회원이 되어 스마트한 주차 서비스를 이용해 보세요.', style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 40),

                // 1. 이름 입력
                TextFormField(
                  controller: _nameController,
                  decoration: _buildInputDecoration('이름', Icons.person_outline),
                  validator: (value) => value == null || value.isEmpty ? '이름을 입력해주세요.' : null,
                ),
                const SizedBox(height: 16),

                // 2. 이메일 입력
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _buildInputDecoration('이메일 주소', Icons.email_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty) return '이메일을 입력해주세요.';
                    if (!value.contains('@')) return '올바른 이메일 형식이 아닙니다.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 3. 비밀번호 입력 (영문+숫자 정규식 추가)
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: _buildInputDecoration('비밀번호', Icons.lock_outline).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return '비밀번호를 입력해주세요.';
                    if (value.length < 6) return '비밀번호는 6자 이상이어야 합니다.';
                    
                    // 영문자와 숫자가 각각 1개 이상 포함되고, 영문/숫자로만 이루어졌는지 검사
                    final RegExp passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]+$');
                    if (!passwordRegex.hasMatch(value)) {
                      return '비밀번호는 영문자와 숫자 조합으로만 만들어주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 4. 비밀번호 확인
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isPasswordVisible,
                  decoration: _buildInputDecoration('비밀번호 확인', Icons.lock_reset_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty) return '비밀번호를 다시 한 번 입력해주세요.';
                    if (value != _passwordController.text) return '비밀번호가 일치하지 않습니다.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 5. 차량번호 입력 (선택사항, 정규식 검증 추가)
                TextFormField(
                  controller: _vehicleController,
                  decoration: _buildInputDecoration('차량번호 (선택)', Icons.directions_car_outlined).copyWith(
                    helperText: '예: 12가 3456 또는 123하4567',
                  ),
                  validator: (value) {
                    // 선택사항이므로 비어있으면 무사 통과
                    if (value == null || value.trim().isEmpty) return null;

                    // 한국 차량번호 양식 검사
                    final RegExp vehicleRegex = RegExp(r'^\d{2,3}[가-힣]\s?\d{4}$');
                    if (!vehicleRegex.hasMatch(value.trim())) {
                      return '올바른 차량번호 양식이 아닙니다. (예: 12가 3456)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // 6. 가입 버튼
                ElevatedButton(
                  onPressed: _handleSignup,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('회원가입 완료', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 24),
                
                // 7. 로그인 화면으로 돌아가기
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('이미 계정이 있으신가요?'),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('로그인하기', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      filled: true,
      fillColor: Theme.of(context).cardColor,
    );
  }
}