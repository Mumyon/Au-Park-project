import 'dart:io';

class SocialAuthConfig {
  SocialAuthConfig._();

  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '567977676527-nf0pd2g5ajppspljfnqmmvv9n8oreprc.apps.googleusercontent.com',
  );

  static const String googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );

  static const String kakaoNativeAppKey = String.fromEnvironment(
    'KAKAO_NATIVE_APP_KEY',
  );

  static const String naverClientId = String.fromEnvironment('NAVER_CLIENT_ID');

  static String? get googleClientId {
    if (Platform.isIOS) return _emptyToNull(googleIosClientId);
    return null;
  }

  static String? get googleSignInServerClientId {
    if (Platform.isAndroid) return _emptyToNull(googleServerClientId);
    return null;
  }

  static bool get canUseGoogle {
    if (!supportsGooglePlatform) return false;
    if (Platform.isAndroid) {
      return googleServerClientId.isNotEmpty;
    }
    if (Platform.isIOS) {
      return true;
    }
    return false;
  }

  static bool get canUseKakao {
    return supportsKakaoPlatform && kakaoNativeAppKey.isNotEmpty;
  }

  static bool get canUseNaver {
    return supportsNaverPlatform && naverClientId.isNotEmpty;
  }

  static bool get supportsKakaoPlatform {
    return Platform.isAndroid || Platform.isIOS;
  }

  static bool get supportsNaverPlatform {
    return Platform.isAndroid || Platform.isIOS;
  }

  static bool get supportsGooglePlatform {
    return Platform.isAndroid || Platform.isIOS;
  }

  static String? _emptyToNull(String value) {
    return value.isEmpty ? null : value;
  }
}
