import 'dart:async';
import 'package:dio/dio.dart' as dio;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  final dio.Dio _dio;
  
  static const _prefsTokenKey = 'api_token';
  static const _prefsUsernameKey = 'api_username';
  static const _prefsRoleKey = 'api_role';
  static const _prefsUserIdKey = 'api_user_id';

  AuthService(this._dio);

  String? _token;
  String? _currentUsername;
  String? _currentRole;
  int? _currentUserId;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_prefsTokenKey);
    _currentUsername = prefs.getString(_prefsUsernameKey);
    _currentRole = prefs.getString(_prefsRoleKey);
    _currentUserId = prefs.getInt(_prefsUserIdKey);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) await prefs.setString(_prefsTokenKey, _token!);
    if (_currentUsername != null) await prefs.setString(_prefsUsernameKey, _currentUsername!);
    if (_currentRole != null) await prefs.setString(_prefsRoleKey, _currentRole!);
    if (_currentUserId != null) await prefs.setInt(_prefsUserIdKey, _currentUserId!);
  }

  Future<void> logout() async {
    _token = null;
    _currentUsername = null;
    _currentRole = null;
    _currentUserId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsTokenKey);
    await prefs.remove(_prefsUsernameKey);
    await prefs.remove(_prefsRoleKey);
    await prefs.remove(_prefsUserIdKey);
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/users/auth/login',
        data: {'username': username, 'password': password},
      );
      final authMap = response.data;
      final token = authMap['access_token']?.toString();
      if (token != null) {
        _token = token;
      }
      final user = authMap['user'];
      if (user is Map<String, dynamic>) {
        _currentUsername = user['username']?.toString() ?? username;
        _currentRole = user['role']?.toString() ?? 'doctor';
        _currentUserId = user['id'] is int ? user['id'] : int.tryParse(user['id'].toString());
      }
      await _persist();
      return authMap;
    } on dio.DioException catch (e) {
      if (e.response?.statusCode == 401) throw Exception('Credenciales inválidas');
      throw Exception('Error al iniciar sesión: ${e.message}');
    }
  }

  Future<User> getMe() async {
    try {
      final response = await _dio.get('/users/me');
      final user = User.fromJson(response.data);
      _currentUserId = user.id;
      _currentUsername = user.username;
      _currentRole = user.role;
      await _persist();
      return user;
    } catch (e) {
      throw Exception('Error al obtener perfil');
    }
  }

  String? get token => _token;
  String? get currentUsername => _currentUsername;
  String? get currentRole => _currentRole;
  int? get currentUserId => _currentUserId;
}
