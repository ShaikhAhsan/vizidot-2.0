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

/// When true, app joins with empty token (for testing when Agora project is in "testing mode").
/// Set AGORA_EMPTY_TOKEN=true in app .env to verify guest join works; then fix certificate and remove this.
bool get agoraUseEmptyToken {
  try {
    final v = dotenv.env['AGORA_EMPTY_TOKEN']?.trim().toLowerCase();
    return v == 'true' || v == '1';
  } catch (_) {
    return false;
  }
}


String get appIdAppCertificate {
  return '45ceab6ba69b4576a4cd5cc30c726b40';
}
