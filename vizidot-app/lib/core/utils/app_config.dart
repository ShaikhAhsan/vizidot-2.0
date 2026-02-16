import 'package:flutter_dotenv/flutter_dotenv.dart';

enum AppEnvironment { development, staging, production }

class AppConfig {
  final String baseUrl;
  final AppEnvironment environment;

  AppConfig({required this.baseUrl, required this.environment});

  /// Default base URL. For Android emulator set BASE_URL=http://10.0.2.2:8000 in .env
  /// so the app reaches the host machine. For physical device use your machine's IP (e.g. http://192.168.1.x:8000).
  factory AppConfig.fromEnv() {
    String env = 'development';
    String baseUrl = 'http://localhost:8000';
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


