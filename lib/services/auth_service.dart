import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AuthResponse> signUp(String email, String password) async {
    try {
      return await _supabase.auth.signUp(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw AuthException(
        _extractSupabaseErrorMessage(e)
       // e.statusCode,
      );
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  Future<AuthResponse> signIn(String email, String password) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw AuthException(
        _extractSupabaseErrorMessage(e)
       // e.statusCode,
      );
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  /// Extracts a user-friendly message from a Supabase AuthException.
  String _extractSupabaseErrorMessage(AuthException e) {
    final rawMessage = e.message;

    // Map common Supabase error messages to user-friendly Chinese text
    if (rawMessage.contains('Invalid login credentials') ||
        rawMessage.contains('invalid_credentials')) {
      return '邮箱或密码错误，请检查后重试';
    }
    if (rawMessage.contains('Email not confirmed') ||
        rawMessage.contains('email_not_confirmed')) {
      return '邮箱尚未验证，请先点击验证邮件中的链接';
    }
    if (rawMessage.contains('User already registered') ||
        rawMessage.contains('user_already_exists')) {
      return '该邮箱已被注册，请直接登录或使用其他邮箱';
    }
    if (rawMessage.contains('Password')) {
      return '密码不符合要求，密码长度至少为6位';
    }
    if (rawMessage.contains('rate limit') ||
        rawMessage.contains('too_many_requests')) {
      return '操作过于频繁，请稍后再试';
    }
    if (rawMessage.contains('network') ||
        rawMessage.contains('timeout') ||
        rawMessage.contains('connection')) {
      return '网络连接失败，请检查网络后重试';
    }

    return rawMessage;
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
