import 'package:flutter_dotenv/flutter_dotenv.dart';

enum AppEnvironment { development, staging, production }

class AppConfig {
  final String baseUrl;
  final AppEnvironment environment;

  AppConfig({required this.baseUrl, required this.environment});

  factory AppConfig.fromEnv() {
    String env = 'development';
    String baseUrl = 'https://api.example.com';
    // Guard against DotEnv not being initialized or missing keys
    try {
      env = (dotenv.env['ENV'] ?? env).toLowerCase();
      baseUrl = dotenv.env['BASE_URL'] ?? baseUrl;
    } catch (_) {
      // Defaults will be used if dotenv isn't initialized
    }
    final environment = switch (env) {
      'prod' || 'production' => AppEnvironment.production,
      'stage' || 'staging' => AppEnvironment.staging,
      _ => AppEnvironment.development,
    };
    return AppConfig(baseUrl: baseUrl, environment: environment);
  }
}


