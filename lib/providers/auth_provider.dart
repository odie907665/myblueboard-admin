import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _error;
  String? _accessToken;
  String? _refreshToken;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('AuthProvider: Starting login...');
      final response = await _apiService.login(email, password);
      
      print('AuthProvider: Login response received');
      print('AuthProvider: User data: ${response['user']}');
      print('AuthProvider: Has tokens: ${response['tokens'] != null}');
      
      // Store tokens in memory
      _accessToken = response['tokens']['access'];
      _refreshToken = response['tokens']['refresh'];
      _apiService.setTokens(_accessToken!, _refreshToken!);
      
      _user = response['user'];
      _isAuthenticated = true;
      _error = null;
      
      print('AuthProvider: Login successful, isAuthenticated = $_isAuthenticated');
    } catch (e) {
      print('AuthProvider: Login error: $e');
      _error = e.toString();
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
      print('AuthProvider: notifyListeners called');
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.logout();
      _accessToken = null;
      _refreshToken = null;
      
      _isAuthenticated = false;
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkAuthStatus() async {
    // Since we're storing tokens in memory, they'll be lost on app restart
    // This is fine for development
    if (_accessToken != null && _refreshToken != null) {
      _apiService.setTokens(_accessToken!, _refreshToken!);
      
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

