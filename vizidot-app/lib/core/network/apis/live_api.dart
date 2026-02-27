import 'dart:convert';

import '../base_api.dart';
import '../api_client.dart';
import '../../constants/api_constants.dart';

/// API for live streaming (Agora RTC token). Token endpoint is public.
class LiveApi extends BaseApi {
  LiveApi({
    required super.baseUrl,
    super.authToken,
    super.timeout,
    super.debugPrintRequest,
  });

  /// GET /api/v1/live/rtc-token?channelName=&role=publisher|audience&uid=0
  /// Returns Agora RTC token (or null if server has no certificate — use empty token in app).
  Future<RtcTokenResult?> getRtcToken({
    required String channelName,
    String role = 'audience',
    int uid = 0,
  }) async {
    try {
      final response = await execute(
        'GET',
        ApiConstants.liveRtcTokenPath,
        queryParams: {
          'channelName': channelName,
          'role': role,
          'uid': uid.toString(),
        },
        visibility: ApiVisibility.public,
      );
      if (response.statusCode != 200) return null;
      final map = jsonDecode(response.body) as Map<String, dynamic>?;
      if (map == null || ((map['success'] as bool? )!= true)) return null;
      final data = map['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      final token = data['token'] as String?;
      return RtcTokenResult(
        token: token,
        appId: data['appId'] as String?,
        channelName: data['channelName'] as String? ?? channelName,
        uid: data['uid'] as int? ?? uid,
        role: data['role'] as String? ?? role,
      );
    } catch (_) {
      return null;
    }
  }
}

class RtcTokenResult {
  RtcTokenResult({
    this.token,
    this.appId,
    this.channelName,
    this.uid,
    this.role,
  });
  final String? token;
  final String? appId;
  final String? channelName;
  final int? uid;
  final String? role;
}
