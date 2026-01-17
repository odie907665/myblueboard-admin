import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _error;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.login(email, password);
      
      // Store tokens securely
      await _storage.write(
        key: 'access_token',
        value: response['tokens']['access'],
      );
      await _storage.write(
        key: 'refresh_token',
        value: response['tokens']['refresh'],
      );
      
      _user = response['user'];
      _isAuthenticated = true;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.logout();
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
      
      _isAuthenticated = false;
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkAuthStatus() async {
    final accessToken = await _storage.read(key: 'access_token');
    final refreshToken = await _storage.read(key: 'refresh_token');
    
    if (accessToken != null && refreshToken != null) {
      _apiService.setTokens(accessToken, refreshToken);
      
      try {
        final response = await _apiService.getProfile();
        _user = response['user'];
        _isAuthenticated = true;
      } catch (e) {
        // Token might be expired
        await logout();
      }
    }
    
    notifyListeners();
  }
}
