import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_client.dart';
import '../base_api.dart';
import '../../constants/api_constants.dart';

/// Device/FCM API: register device, logout device, fetch tokens for push.
class DeviceApi extends BaseApi {
  DeviceApi({
    required super.baseUrl,
    super.authToken,
    super.timeout,
    super.debugPrintRequest,
  });

  /// POST /api/v1/device/register. Auth required.
  Future<bool> register({
    required String deviceId,
    required String platform,
    String? fcmToken,
    String? deviceName,
  }) async {
    try {
      final body = <String, dynamic>{
        'device_id': deviceId,
        'platform': platform,
      };
      if (fcmToken != null && fcmToken.isNotEmpty) body['fcm_token'] = fcmToken;
      if (deviceName != null && deviceName.isNotEmpty) body['device_name'] = deviceName;
      final response = await execute(
        'POST',
        ApiConstants.deviceRegisterPath,
        body: body,
        visibility: ApiVisibility.private,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// POST /api/v1/device/logout. Auth required.
  Future<bool> logout({required String deviceId}) async {
    try {
      final response = await execute(
        'POST',
        ApiConstants.deviceLogoutPath,
        body: {'device_id': deviceId},
        visibility: ApiVisibility.private,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// GET /api/v1/device/tokens?userIds=1,2,3. Auth required.
  /// Returns map of userId (string) -> list of FCM tokens.
  Future<Map<String, List<String>>?> getTokens(List<int> userIds) async {
    if (userIds.isEmpty) return {};
    try {
      final response = await execute(
        'GET',
        ApiConstants.deviceTokensPath,
        queryParams: {'userIds': userIds.join(',')},
        visibility: ApiVisibility.private,
      );
      if (response.statusCode != 200) return null;
      final body = response.body;
      if (body.isEmpty) return null;
      final decoded = jsonDecode(body) as Map<String, dynamic>?;
      final data = decoded?['data'] as Map<String, dynamic>?;
      final tokensByUser = data?['tokensByUser'] as Map<String, dynamic>?;
      if (tokensByUser == null) return null;
      final result = <String, List<String>>{};
      for (final entry in tokensByUser.entries) {
        final list = entry.value;
        if (list is List) {
          result[entry.key] = list.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
        }
      }
      return result;
    } catch (_) {
      return null;
    }
  }
}
