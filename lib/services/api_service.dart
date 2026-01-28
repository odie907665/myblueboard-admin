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
    final headers = {'Content-Type': 'application/json'};

    if (includeAuth && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    return headers;
  }

  // Public method for other services to get authenticated headers
  Map<String, String> getAuthHeaders() {
    return _getHeaders(includeAuth: true);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginEndpoint),
        headers: _getHeaders(),
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Store tokens
        _accessToken = data['tokens']['access'];
        _refreshToken = data['tokens']['refresh'];
        return data;
      } else {
        final errorMsg =
            data['errors']?.toString() ??
            data['message']?.toString() ??
            'Login failed';
        throw Exception(errorMsg);
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
          body: jsonEncode({'refresh_token': _refreshToken}),
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
  Future<Map<String, dynamic>?> getDashboardStats({
    bool forceRefresh = false,
  }) async {
    try {
      final url = forceRefresh
          ? '${ApiConfig.dashboardStatsEndpoint}?refresh=true'
          : ApiConfig.dashboardStatsEndpoint;

      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(includeAuth: true),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data;
        }
      }
      return null;
    } catch (e) {
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

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> getClientAdmins(String schemaName) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.adminApiBase}/clients/$schemaName/admins/'),
        headers: _getHeaders(includeAuth: true),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['admins']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Update Client
  Future<bool> updateClient(
    String schemaName,
    Map<String, dynamic> clientData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.adminApiBase}/clients/$schemaName/update/'),
        headers: _getHeaders(includeAuth: true),
        body: json.encode(clientData),
      );

      print('Update client response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error updating client: $e');
      return false;
    }
  }

  // Update School
  Future<bool> updateSchool(
    String schemaName,
    Map<String, dynamic> schoolData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse(
          '${ApiConfig.adminApiBase}/clients/$schemaName/school/update/',
        ),
        headers: _getHeaders(includeAuth: true),
        body: json.encode(schoolData),
      );

      print('Update school response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error updating school: $e');
      return false;
    }
  }

  // Update App Settings
  Future<bool> updateAppSettings(
    String schemaName,
    Map<String, dynamic> settingsData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse(
          '${ApiConfig.adminApiBase}/clients/$schemaName/app-settings/update/',
        ),
        headers: _getHeaders(includeAuth: true),
        body: json.encode(settingsData),
      );

      print('Update app settings response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error updating app settings: $e');
      return false;
    }
  }

  // Send Email
  Future<bool> sendEmail({
    required List<String> toEmails,
    required String subject,
    required String body,
    String? replyTo,
    List<Map<String, String>>? attachments,
  }) async {
    try {
      final emailData = {
        'to_emails': toEmails,
        'subject': subject,
        'body': body,
        if (replyTo != null) 'reply_to': replyTo,
        if (attachments != null) 'attachments': attachments,
      };

      final response = await http.post(
        Uri.parse(ApiConfig.sendEmailEndpoint),
        headers: _getHeaders(includeAuth: true),
        body: json.encode(emailData),
      );

      print('Send email response: ${response.statusCode}');
      print('Send email body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error sending email: $e');
      return false;
    }
  }
}
