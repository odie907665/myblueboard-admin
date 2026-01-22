import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _savedEmailKey = 'saved_email';
  static const String _savedPasswordKey = 'saved_password';

  // Check if device supports biometrics
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheckBiometrics && isDeviceSupported;
    } catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  // Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  // Authenticate using biometrics
  Future<bool> authenticate() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your admin account',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      print('Error during authentication: $e');
      return false;
    }
  }

  // Check if biometric login is enabled
  Future<bool> isBiometricEnabled() async {
    final String? enabled = await _secureStorage.read(
      key: _biometricEnabledKey,
    );
    return enabled == 'true';
  }

  // Enable biometric login and save credentials
  Future<void> enableBiometric(String email, String password) async {
    await _secureStorage.write(key: _biometricEnabledKey, value: 'true');
    await _secureStorage.write(key: _savedEmailKey, value: email);
    await _secureStorage.write(key: _savedPasswordKey, value: password);
  }

  // Disable biometric login and clear credentials
  Future<void> disableBiometric() async {
    await _secureStorage.delete(key: _biometricEnabledKey);
    await _secureStorage.delete(key: _savedEmailKey);
    await _secureStorage.delete(key: _savedPasswordKey);
  }

  // Get saved credentials (only if biometric is enabled)
  Future<Map<String, String>?> getSavedCredentials() async {
    final bool isEnabled = await isBiometricEnabled();
    if (!isEnabled) return null;

    final String? email = await _secureStorage.read(key: _savedEmailKey);
    final String? password = await _secureStorage.read(key: _savedPasswordKey);

    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }

    return null;
  }

  // Check if user has saved credentials
  Future<bool> hasSavedCredentials() async {
    final credentials = await getSavedCredentials();
    return credentials != null;
  }
}
