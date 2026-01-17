class ApiConfig {
  // Change this to your actual backend URL
  static const String baseUrl = 'http://localhost:8000';  // For local dev
  // static const String baseUrl = 'https://myblueboard.com';  // For production
  
  // Admin API endpoints
  static const String adminApiBase = '$baseUrl/api/admin';
  static const String loginEndpoint = '$adminApiBase/auth/login/';
  static const String logoutEndpoint = '$adminApiBase/auth/logout/';
  static const String profileEndpoint = '$adminApiBase/auth/profile/';
}
