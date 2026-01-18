import 'environment.dart';

class ApiConfig {
  // Get base URL from environment configuration
  static String get baseUrl => EnvironmentConfig.baseUrl;
  
  // Admin API endpoints using signup schema
  static String get adminApiBase => '$baseUrl/api/admin';
  static String get loginEndpoint => '$adminApiBase/auth/login/';
  static String get logoutEndpoint => '$adminApiBase/auth/logout/';
  static String get profileEndpoint => '$adminApiBase/auth/profile/';
  static String get dashboardStatsEndpoint => '$adminApiBase/dashboard/stats/';
  
  // Additional admin endpoints
  static String get usersEndpoint => '$adminApiBase/users/';
  static String get clientsEndpoint => '$adminApiBase/clients/';
  static String get accountsEndpoint => '$adminApiBase/accounts/';
}
