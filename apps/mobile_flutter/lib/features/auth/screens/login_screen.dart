import 'package:flutter/material.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ⚠️ 본인의 폴더 구조에 맞게 경로 확인 필수!
import '../../../core/api/api_client.dart';
import '../../../core/auth/social_auth_config.dart';
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
  bool _isKakaoSdkReady = false;

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
          accessToken: result['access_token']?.toString(),
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
      debugPrint('Email login error: ${e.runtimeType} $e');
      // 🔥 에러 시에도 팝업만 정확히 닫기!
      if (loadingDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('⚠️ 로그인 에러: ${e.runtimeType} $e')));
    }
  }

  // ------------------------------------------------------------------------
  // ✅ 2. 구글 연동 로그인
  // ------------------------------------------------------------------------
  Future<void> _handleGoogleLogin() async {
    if (!SocialAuthConfig.canUseGoogle) {
      _showSocialConfigMessage('구글');
      return;
    }

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: SocialAuthConfig.googleClientId,
        serverClientId: SocialAuthConfig.googleSignInServerClientId,
      );
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

      await _loginWithSocialToken(
        provider: 'google',
        token: idToken,
        fallbackName: googleUser.displayName ?? '구글 유저',
        fallbackEmail: googleUser.email,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ 구글 서버 인증 실패: ${e.message}')));
    } catch (e) {
      if (!mounted) return;
      debugPrint('Google login error: ${e.runtimeType} $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ 구글 로그인 에러: ${e.runtimeType} $e')),
      );
    }
  }

  Future<void> _handleKakaoLogin() async {
    if (!SocialAuthConfig.canUseKakao) {
      _showSocialConfigMessage('카카오');
      return;
    }

    try {
      await _ensureKakaoSdkReady();
      final OAuthToken token = await isKakaoTalkInstalled()
          ? await UserApi.instance.loginWithKakaoTalk()
          : await UserApi.instance.loginWithKakaoAccount();

      await _loginWithSocialToken(provider: 'kakao', token: token.accessToken);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ 카카오 서버 인증 실패: ${e.message}')));
    } catch (e) {
      if (!mounted) return;
      debugPrint('Kakao login error: ${e.runtimeType} $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ 카카오 로그인 에러: ${e.runtimeType} $e')),
      );
    }
  }

  Future<void> _handleNaverLogin() async {
    if (!SocialAuthConfig.canUseNaver) {
      _showSocialConfigMessage('네이버');
      return;
    }

    try {
      final result = await FlutterNaverLogin.logIn();
      final accessToken = result.accessToken?.accessToken;

      if (!_isNaverLoggedIn(result.status) ||
          accessToken == null ||
          accessToken.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorMessage ?? '❌ 네이버 로그인 실패')),
        );
        return;
      }

      await _loginWithSocialToken(
        provider: 'naver',
        token: accessToken,
        fallbackName: result.account?.name ?? result.account?.nickname,
        fallbackEmail: result.account?.email,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ 네이버 서버 인증 실패: ${e.message}')));
    } catch (e) {
      if (!mounted) return;
      debugPrint('Naver login error: ${e.runtimeType} $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ 네이버 로그인 에러: ${e.runtimeType} $e')),
      );
    }
  }

  Future<void> _ensureKakaoSdkReady() async {
    if (_isKakaoSdkReady) return;

    await KakaoSdk.init(nativeAppKey: SocialAuthConfig.kakaoNativeAppKey);
    _isKakaoSdkReady = true;
  }

  bool _isNaverLoggedIn(Object status) {
    return status.toString().split('.').last == 'loggedIn';
  }

  void _showSocialConfigMessage(String providerName) {
    if (providerName == '구글' && !SocialAuthConfig.supportsGooglePlatform) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('구글 로그인은 Android/iOS 앱에서 지원됩니다.')),
      );
      return;
    }

    if (providerName == '카카오' && !SocialAuthConfig.supportsKakaoPlatform) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카카오 로그인은 Android/iOS 앱에서 지원됩니다.')),
      );
      return;
    }

    if (providerName == '네이버' && !SocialAuthConfig.supportsNaverPlatform) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네이버 로그인은 Android/iOS 앱에서 지원됩니다.')),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$providerName 로그인 설정값이 필요합니다.')));
  }

  Future<void> _loginWithSocialToken({
    required String provider,
    required String token,
    String? fallbackName,
    String? fallbackEmail,
  }) async {
    var loadingDialogOpen = false;
    final providerName = _socialProviderName(provider);

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    loadingDialogOpen = true;

    try {
      final result = await _apiClient.socialLogin(
        provider: provider,
        token: token,
      );

      if (!mounted) return;

      if (result['access_token'] != null && result['user_id'] != null) {
        final user = await _apiClient.getUser(result['user_id']);
        if (!mounted) return;

        if (loadingDialogOpen) {
          Navigator.of(context, rootNavigator: true).pop();
          loadingDialogOpen = false;
        }

        await _finishLogin(
          userId: result['user_id'],
          name: user['name'] ?? fallbackName ?? '$providerName 유저',
          email: user['email'] ?? fallbackEmail ?? '',
          vehicleNumber: '등록된 차량 없음',
          accessToken: result['access_token']?.toString(),
        );
      } else {
        if (loadingDialogOpen) {
          Navigator.of(context, rootNavigator: true).pop();
          loadingDialogOpen = false;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $providerName 로그인 실패: 토큰 검증 실패')),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (loadingDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ $providerName 로그인 실패: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('$providerName social login error: ${e.runtimeType} $e');
      if (loadingDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ $providerName 로그인 에러: ${e.runtimeType} $e')),
      );
    }
  }

  String _socialProviderName(String provider) {
    switch (provider) {
      case 'google':
        return '구글';
      case 'kakao':
        return '카카오';
      case 'naver':
        return '네이버';
      default:
        return provider;
    }
  }

  Future<void> _finishLogin({
    required String userId,
    required String name,
    required String email,
    required String vehicleNumber,
    String? accessToken,
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
    if (accessToken != null && accessToken.isNotEmpty) {
      await prefs.setString('accessToken', accessToken);
    } else {
      await prefs.remove('accessToken');
    }

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
                      onTap: _handleKakaoLogin,
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
                      onTap: _handleNaverLogin,
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
