import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/biometric_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final BiometricService _biometricService = BiometricService();

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

  // Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    return await _biometricService.isBiometricAvailable();
  }

  // Check if biometric login is enabled
  Future<bool> isBiometricEnabled() async {
    return await _biometricService.isBiometricEnabled();
  }

  // Attempt biometric login
  Future<bool> loginWithBiometric() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check if credentials are saved
      final credentials = await _biometricService.getSavedCredentials();
      if (credentials == null) {
        _error = 'No saved credentials found';
        return false;
      }

      // Authenticate with biometrics
      final authenticated = await _biometricService.authenticate();
      if (!authenticated) {
        _error = 'Biometric authentication failed';
        return false;
      }

      // Login with saved credentials
      await login(
        credentials['email']!,
        credentials['password']!,
        saveBiometric: false,
      );
      return _isAuthenticated;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(
    String email,
    String password, {
    bool saveBiometric = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.login(email, password);

      // Store tokens in memory
      _accessToken = response['tokens']['access'];
      _refreshToken = response['tokens']['refresh'];
      _apiService.setTokens(_accessToken!, _refreshToken!);

      _user = response['user'];
      _isAuthenticated = true;
      _error = null;

      // Save biometric credentials if requested
      if (saveBiometric) {
        await _biometricService.enableBiometric(email, password);
      }
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
      _accessToken = null;
      _refreshToken = null;

      _isAuthenticated = false;
      _user = null;

      // Optionally clear biometric data on logout
      // await _biometricService.disableBiometric();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Disable biometric authentication
  Future<void> disableBiometric() async {
    await _biometricService.disableBiometric();
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
