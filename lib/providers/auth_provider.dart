import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String? get error => _error;

  /// Check if user is already authenticated (on app start)
  Future<void> checkAuthStatus() async {
    debugPrint('[AUTH] Checking auth status...');
    _isLoading = true;
    notifyListeners();

    try {
      _user = await AuthService.getCurrentUser().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('[AUTH] Timeout checking auth');
          return null;
        },
      );
      debugPrint('[AUTH] User: ${_user != null ? _user!.fullName : "null"}');
    } catch (e) {
      _user = null;
      debugPrint('[AUTH] Auth check error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await AuthService.login(email, password);

      if (response['success'] == true) {
        _user = User.fromJson(response['user']);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Erreur de connexion';
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Erreur de connexion au serveur';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Logout current user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await AuthService.logout();
    } finally {
      _user = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
