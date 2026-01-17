import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _accessToken;
  String? _refreshToken;

  void setTokens(String accessToken, String refreshToken) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  Map<String, String> _getHeaders({bool includeAuth = false}) {
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (includeAuth && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    
    return headers;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginEndpoint),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Store tokens
        _accessToken = data['tokens']['access'];
        _refreshToken = data['tokens']['refresh'];
        return data;
      } else {
        throw Exception(data['errors']?.toString() ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<void> logout() async {
    try {
      if (_refreshToken != null) {
        await http.post(
          Uri.parse(ApiConfig.logoutEndpoint),
          headers: _getHeaders(includeAuth: true),
          body: jsonEncode({
            'refresh_token': _refreshToken,
          }),
        );
      }
    } finally {
      clearTokens();
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.profileEndpoint),
        headers: _getHeaders(includeAuth: true),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        throw Exception('Failed to fetch profile');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }
}
