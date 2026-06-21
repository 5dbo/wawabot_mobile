import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _user = _authService.getCurrentUser();
    _authService.authStateChanges.listen((event) {
      _user = event.session?.user;
      notifyListeners();
    });
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.signIn(email, password);
      _user = response.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.signUp(email, password);
      _user = response.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _errorMessage = null;
    notifyListeners();
  }

  String _extractErrorMessage(Object error) {
    // If it's already an AuthException with a user-friendly message, use it directly
    if (error is AuthException) {
      return error.message;
    }

    final msg = error.toString();

    // Strip the 'Exception: ' prefix added by AuthService
    if (msg.startsWith('Exception: ')) {
      return msg.substring('Exception: '.length);
    }

    // Try to extract Supabase Auth error from nested exception
    if (msg.contains('AuthException')) {
      final start = msg.indexOf('AuthException');
      final colonIdx = msg.indexOf(':', start);
      if (colonIdx != -1) {
        return msg.substring(colonIdx + 1).trim();
      }
      final end = msg.indexOf(')', start);
      if (end != -1) return msg.substring(start, end + 1);
      return msg.substring(start);
    }

    return msg;
  }
}
