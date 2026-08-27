import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  /// Login with email and password
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await ApiService.post(
      ApiConfig.login,
      body: {
        'email': email,
        'password': password,
      },
    );

    if (response['success'] == true && response['data'] != null) {
      final data = response['data'];
      if (data['token'] != null) {
        await ApiService.setToken(data['token']);
      }
      return {
        'success': true,
        'user': data['user'],
        'token': data['token'],
      };
    }

    return response;
  }

  /// Logout current user
  static Future<void> logout() async {
    try {
      await ApiService.post(ApiConfig.logout);
    } finally {
      await ApiService.removeToken();
    }
  }

  /// Get current authenticated user
  static Future<User?> getCurrentUser() async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        debugPrint('[AUTH] No token stored');
        return null;
      }

      final response = await ApiService.get(ApiConfig.me);

      if (response['success'] == true && response['data'] != null) {
        final userData = response['data']['user'];
        if (userData != null) {
          return User.fromJson(userData);
        }
      }
    } catch (e) {
      debugPrint('[AUTH] getCurrentUser error: $e');
      await ApiService.removeToken();
    }
    return null;
  }

  /// Check if user is logged in with a valid token
  static Future<bool> isLoggedIn() async {
    final token = await ApiService.getToken();
    if (token == null) return false;
    final user = await getCurrentUser();
    return user != null;
  }
}
