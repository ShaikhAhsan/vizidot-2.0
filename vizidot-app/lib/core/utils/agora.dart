import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Agora App ID. Set AGORA_APP_ID in .env to override; otherwise uses fallback (dev/test).
String get appId =>
    dotenv.env['AGORA_APP_ID']?.trim() ?? 'd712240792a64c689a1a7cd748681ff2';

