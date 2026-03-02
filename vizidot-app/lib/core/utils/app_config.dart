import 'package:flutter_dotenv/flutter_dotenv.dart';

enum AppEnvironment { development, staging, production }

class AppConfig {
  final String baseUrl;
  final AppEnvironment environment;
  /// Non-expiring token for API testing in dev; null in production. Set TEST_ACCESS_TOKEN in .env to override.
  final String? testAccessToken;

  AppConfig({
    required this.baseUrl,
    required this.environment,
    this.testAccessToken,
  });

  /// Default base URL. For Android emulator set BASE_URL=http://10.0.2.2:8000 in .env
  /// so the app reaches the host machine. For physical device use your machine's IP (e.g. http://192.168.1.x:8000).
  factory AppConfig.fromEnv() {
    String env = 'development';
    // String baseUrl = 'http://localhost:8000';
    String baseUrl = 'http://109.106.244.241:9000';

    String? testToken;
    try {
      env = (dotenv.env['ENV'] ?? env).toLowerCase();
      baseUrl = dotenv.env['BASE_URL'] ?? baseUrl;
      testToken = dotenv.env['TEST_ACCESS_TOKEN']?.trim();
    } catch (_) {
      // Defaults will be used if dotenv isn't initialized
    }
    final environment = switch (env) {
      'prod' || 'production' => AppEnvironment.production,
      'stage' || 'staging' => AppEnvironment.staging,
      _ => AppEnvironment.development,
    };
    // Only allow test token in non-production; default in dev so APIs work without login
    final effectiveTestToken = environment == AppEnvironment.production
        ? null
        : (testToken?.isNotEmpty == true ? testToken! : 'test-token-no-expire');
    return AppConfig(
      baseUrl: baseUrl,
      environment: environment,
      testAccessToken: effectiveTestToken,
    );
  }
}


