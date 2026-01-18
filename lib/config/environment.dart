enum Environment {
  dev,
  prod,
}

class EnvironmentConfig {
  // Change this to switch between dev and prod
  static const Environment current = Environment.dev;
  
  static String get baseUrl {
    switch (current) {
      case Environment.dev:
        return 'http://signup.app.local:8000';
      case Environment.prod:
        return 'https://signup.myblueboard.com';
    }
  }
  
  static String get environmentName {
    switch (current) {
      case Environment.dev:
        return 'Development';
      case Environment.prod:
        return 'Production';
    }
  }
  
  static bool get isDev => current == Environment.dev;
  static bool get isProd => current == Environment.prod;
}
