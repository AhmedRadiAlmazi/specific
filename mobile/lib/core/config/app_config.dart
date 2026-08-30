// App Configuration — مشروع «مُعين» (Mouin)
// Production Hardening & Multi-Environment Support

enum AppEnvironment { development, staging, production }

class AppConfig {
  static const String appName = 'مُعين (Mouin)';
  static const String appVersion = '1.0.0';
  
  static AppEnvironment currentEnvironment = AppEnvironment.development;

  static String get apiBaseUrl {
    switch (currentEnvironment) {
      case AppEnvironment.production:
        return 'https://api.mouin.app/api/v1';
      case AppEnvironment.staging:
        return 'https://staging-api.mouin.app/api/v1';
      case AppEnvironment.development:
        return 'http://127.0.0.1:8000/api/v1';
    }
  }

  static const Duration requestTimeout = Duration(seconds: 15);
  static const int syncBatchSize = 50;
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // Production Security Guards
  static bool get isProduction => currentEnvironment == AppEnvironment.production;
}
