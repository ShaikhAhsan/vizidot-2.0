import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Agora App ID.
/// - Preferred: set AGORA_APP_ID in .env (Flutter).
/// - Fallback: use built-in dev/test App ID when dotenv is not initialized or key is missing.
String get appId {
  try {
    final value = dotenv.env['AGORA_APP_ID'];
    if (value != null && value.trim().isNotEmpty) {
      return value.trim();
    }
  } catch (_) {
    // DotEnv not initialized (e.g. .env asset missing or load failed). Fall through to fallback.
  }
  return 'd712240792a64c689a1a7cd748681ff2';
}

