import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

class AuthUser {
  final String id;
  final String name;
  final String phone;
  final String role;

  AuthUser({required this.id, required this.name, required this.phone, required this.role});

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
        id: j['id']?.toString() ?? j['_id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        phone: j['phone']?.toString() ?? '',
        role: j['role']?.toString() ?? 'passenger',
      );
}

class AuthService {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<AuthUser?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null) return null;
    return AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  static Future<bool> isLoggedIn() async {
    final t = await getToken();
    return t != null && t.isNotEmpty;
  }

  static Future<void> _saveSession(String token, AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode({
      'id': user.id,
      'name': user.name,
      'phone': user.phone,
      'role': user.role,
    }));
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  static Future<AuthUser> login(String phone, String password) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'password': password}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message']?.toString() ?? 'Login failed');
    }
    final user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
    await _saveSession(data['token'] as String, user);
    return user;
  }

  static Future<AuthUser> register({
    required String name,
    required String phone,
    required String password,
    String? email,
  }) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'password': password,
        if (email != null && email.isNotEmpty) 'email': email,
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 201 || data['success'] != true) {
      throw Exception(data['message']?.toString() ?? 'Registration failed');
    }
    final user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
    await _saveSession(data['token'] as String, user);
    return user;
  }

  static Future<Map<String, String>> authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
