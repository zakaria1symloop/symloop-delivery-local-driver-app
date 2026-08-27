import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    final url = '${ApiConfig.baseUrl}$endpoint';
    debugPrint('[API] GET $url');

    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        statusCode: 0,
        message: 'Impossible de se connecter au serveur',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Erreur de connexion: $e',
      );
    }
  }

  static Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final url = '${ApiConfig.baseUrl}$endpoint';
    debugPrint('[API] POST $url');
    if (body != null) debugPrint('[API] Body: ${jsonEncode(body)}');

    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('[API] Response: ${response.statusCode}');
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        statusCode: 0,
        message: 'Impossible de se connecter au serveur',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Erreur de connexion: $e',
      );
    }
  }

  static Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final url = '${ApiConfig.baseUrl}$endpoint';
    debugPrint('[API] PATCH $url');

    try {
      final headers = await _getHeaders();
      final response = await http
          .patch(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        statusCode: 0,
        message: 'Impossible de se connecter au serveur',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Erreur de connexion: $e',
      );
    }
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    final url = '${ApiConfig.baseUrl}$endpoint';
    debugPrint('[API] DELETE $url');

    try {
      final headers = await _getHeaders();
      final response = await http
          .delete(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        statusCode: 0,
        message: 'Impossible de se connecter au serveur',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Erreur de connexion: $e',
      );
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    debugPrint('============================================================');
    debugPrint('API ERROR - Status: ${response.statusCode}');
    debugPrint('Message: ${body['message']}');

    if (response.statusCode == 403) {
      final errorCode = body['error_code'] ?? 'UNKNOWN';
      final permissionRequired = body['permission_required'] ?? 'unknown';
      debugPrint('PERMISSION ERROR: $errorCode - $permissionRequired');
    }

    if (response.statusCode == 401) {
      debugPrint('AUTH ERROR - Token expired or invalid');
    }

    if (body['errors'] != null) {
      debugPrint('Errors: ${body['errors']}');
    }
    debugPrint('============================================================');

    throw ApiException(
      statusCode: response.statusCode,
      message: body['message'] ?? 'Une erreur est survenue',
      errors: body['errors'],
    );
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic errors;

  ApiException({
    required this.statusCode,
    required this.message,
    this.errors,
  });

  @override
  String toString() => message;

  bool get isAuthError => statusCode == 401;
  bool get isPermissionError => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode >= 500;
}
