import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

// ⚠️ 본인의 폴더 구조에 맞게 경로 확인 필수!
import '../../../core/api/api_client.dart';
import 'signup_screen.dart';
import '../../parking/screens/main_navigation_screen.dart';
import '../../../core/shared_data.dart';
import '../providers/user_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final ApiClient _apiClient = ApiClient();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isAutoLoginChecked = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------------
  // ✅ 1. 이메일 (일반) 로그인
  // ------------------------------------------------------------------------
  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('⚠️ 이메일과 비밀번호를 모두 입력해주세요.')));
      return;
    }

    var loadingDialogOpen = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    loadingDialogOpen = true;

    try {
      final result = await _apiClient.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;
      // 🔥 팀킬 방지: 앱 화면이 아닌 팝업(Loading)만 정확히 닫기!
      if (loadingDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
        loadingDialogOpen = false;
      }

      // 로그인 성공 시!
      if (result['access_token'] != null && result['user_id'] != null) {
        final user = await _apiClient.getUser(result['user_id']);
        await _finishLogin(
          userId: result['user_id'],
          name: user['name'] ?? '사용자',
          email: user['email'] ?? _emailController.text.trim(),
          vehicleNumber: '등록된 차량 없음',
        );
      } else {
        // 실패 (비밀번호 틀림 등)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ 실패: 로그인 실패'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (loadingDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 실패: ${e.message}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // 🔥 에러 시에도 팝업만 정확히 닫기!
      if (loadingDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ 서버 접속 실패. 서버 상태를 확인해주세요.')),
      );
    }
  }

  // ------------------------------------------------------------------------
  // ✅ 2. 구글 연동 로그인
  // ------------------------------------------------------------------------
  Future<void> _handleGoogleLogin() async {
    var loadingDialogOpen = false;

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut(); // 계정 선택 창 강제 호출
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) return;
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('⚠️ 구글 ID 토큰을 받을 수 없습니다.')),
          );
        }
        return;
      }

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      loadingDialogOpen = true;

      final result = await _apiClient.socialLogin(
        provider: 'google',
        token: idToken,
      );

      if (!mounted) return;
      // 🔥 팀킬 방지: 앱 화면이 아닌 팝업(Loading)만 정확히 닫기!
      if (loadingDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
        loadingDialogOpen = false;
      }
      // 서버 통신 성공 시!
      if (result['access_token'] != null && result['user_id'] != null) {
        final user = await _apiClient.getUser(result['user_id']);
        await _finishLogin(
          userId: result['user_id'],
          name: user['name'] ?? googleUser.displayName ?? '구글 유저',
          email: user['email'] ?? googleUser.email,
          vehicleNumber: '등록된 차량 없음',
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('❌ 구글 로그인 실패: 토큰 검증 실패')));
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (loadingDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ 구글 로그인 실패: ${e.message}')));
    } catch (e) {
      if (!mounted) return;
      // 🔥 에러 시에도 팝업만 정확히 닫기!
      if (loadingDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ 구글 로그인 에러 (서버 연결을 확인하세요)')),
      );
    }
  }

  void _showProviderSetupMessage(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$provider 로그인은 앱 키와 SDK 설정 후 연결할 수 있습니다.')),
    );
  }

  Future<void> _finishLogin({
    required String userId,
    required String name,
    required String email,
    required String vehicleNumber,
  }) async {
    SharedData.vehicleNumber.value = vehicleNumber;

    Provider.of<UserProvider>(
      context,
      listen: false,
    ).setUser(id: userId, name: name, email: email, department: '');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
    await prefs.setString('registeredVehicle', vehicleNumber);
    await prefs.setString('userName', name);
    await prefs.setString('userEmail', email);
    await prefs.setString('userDept', '');

    if (_isAutoLoginChecked) {
      await prefs.setBool('isLoggedIn', true);
    } else {
      await prefs.setBool('isLoggedIn', false);
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.local_parking, size: 80, color: primaryColor),
                const SizedBox(height: 16),
                const Text(
                  'Au-Park',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '스마트 주차의 새로운 시작',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 48),

                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: '이메일',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _isAutoLoginChecked,
                        activeColor: primaryColor,
                        onChanged: (value) {
                          setState(() {
                            _isAutoLoginChecked = value ?? false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isAutoLoginChecked = !_isAutoLoginChecked;
                        });
                      },
                      child: Text(
                        '자동 로그인',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    '로그인',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        '비밀번호 찾기',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const Text('|', style: TextStyle(color: Colors.grey)),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignupScreen(),
                        ),
                      ),
                      child: Text(
                        '회원가입',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                Row(
                  children: [
                    Expanded(
                      child: Divider(color: Colors.grey.shade300, thickness: 1),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '또는 간편 로그인',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: Colors.grey.shade300, thickness: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialButton(
                      bgColor: const Color(0xFFFEE500),
                      onTap: () => _showProviderSetupMessage('카카오'),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Image.asset('assets/images/kakao.png'),
                      ),
                    ),
                    const SizedBox(width: 24),
                    _buildSocialButton(
                      bgColor: Colors.white,
                      isBorder: true,
                      onTap: _handleGoogleLogin,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Image.asset('assets/images/google.png'),
                      ),
                    ),
                    const SizedBox(width: 24),
                    _buildSocialButton(
                      bgColor: const Color(0xFF03C75A),
                      onTap: () => _showProviderSetupMessage('네이버'),
                      child: const Text(
                        'N',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
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

  Widget _buildSocialButton({
    required Widget child,
    required Color bgColor,
    required VoidCallback onTap,
    bool isBorder = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: isBorder
              ? Border.all(color: Colors.grey.shade300, width: 1)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}
