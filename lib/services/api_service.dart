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
      print('Attempting login to: ${ApiConfig.loginEndpoint}');
      final response = await http.post(
        Uri.parse(ApiConfig.loginEndpoint),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Store tokens
        _accessToken = data['tokens']['access'];
        _refreshToken = data['tokens']['refresh'];
        print('Login successful, tokens stored');
        return data;
      } else {
        final errorMsg = data['errors']?.toString() ?? data['message']?.toString() ?? 'Login failed';
        print('Login failed: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('Login error: $e');
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

  // Dashboard
  Future<Map<String, dynamic>?> getDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.dashboardStatsEndpoint),
        headers: _getHeaders(includeAuth: true),
      );

      print('Dashboard stats response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['stats'];
        }
      }
      return null;
    } catch (e) {
      print('Error fetching dashboard stats: $e');
      return null;
    }
  }

  // Clients
  Future<List<Map<String, dynamic>>> getClients() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.clientsEndpoint),
        headers: _getHeaders(includeAuth: true),
      );

      print('Clients response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['clients']);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching clients: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getClientSettings(String schemaName) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.adminApiBase}/clients/$schemaName/settings/'),
        headers: _getHeaders(includeAuth: true),
      );

      print('Client settings response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data;
        }
      }
      return null;
    } catch (e) {
      print('Error fetching client settings: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> getClientAdmins(String schemaName) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.adminApiBase}/clients/$schemaName/admins/'),
        headers: _getHeaders(includeAuth: true),
      );

      print('Client admins response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['admins']);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching client admins: $e');
      return null;
    }
  }
}
