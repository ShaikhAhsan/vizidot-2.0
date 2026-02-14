import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/app_config.dart';
import '../constants/api_constants.dart';

/// Single HTTP client for all API calls. Uses [AppConfig.baseUrl] and optional auth.
/// See FLUTTER_API_GUIDE.md.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    this.authToken,
    this.timeout = const Duration(seconds: 15),
  });

  final String baseUrl;
  final String? authToken;
  final Duration timeout;

  String get _apiBase => '$baseUrl/${ApiConstants.apiVersion}';

  Map<String, String> _headers({bool useAuth = false}) {
    final map = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (useAuth && authToken != null && authToken!.isNotEmpty) {
      map['Authorization'] = 'Bearer $authToken';
    }
    return map;
  }

  /// GET request. [path] is the suffix (e.g. from ApiConstants); no leading slash.
  Future<http.Response> get(
    String path, {
    Map<String, String>? queryParams,
    bool useAuth = false,
  }) async {
    var uri = Uri.parse('$_apiBase/$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }
    return http
        .get(uri, headers: _headers(useAuth: useAuth))
        .timeout(timeout);
  }

  /// POST request. [path] suffix, [body] encoded as JSON.
  Future<http.Response> post(
    String path, {
    Map<String, dynamic>? body,
    bool useAuth = false,
  }) async {
    final uri = Uri.parse('$_apiBase/$path');
    return http
        .post(
          uri,
          headers: _headers(useAuth: useAuth),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(timeout);
  }

  /// PUT request.
  Future<http.Response> put(
    String path, {
    Map<String, dynamic>? body,
    bool useAuth = false,
  }) async {
    final uri = Uri.parse('$_apiBase/$path');
    return http
        .put(
          uri,
          headers: _headers(useAuth: useAuth),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(timeout);
  }

  /// DELETE request.
  Future<http.Response> delete(
    String path, {
    bool useAuth = false,
  }) async {
    final uri = Uri.parse('$_apiBase/$path');
    return http
        .delete(uri, headers: _headers(useAuth: useAuth))
        .timeout(timeout);
  }

  /// Parse standard success/error body. Returns (success, data map or null, error message).
  static (bool success, Map<String, dynamic>? data, String? error) parseResponse(
    http.Response response,
  ) {
    final body = response.body;
    if (body.isEmpty) {
      return (false, null, 'Empty response');
    }
    try {
      final map = jsonDecode(body) as Map<String, dynamic>;
      final success = map['success'] as bool? ?? false;
      final data = map['data'] as Map<String, dynamic>?;
      final error = map['error'] as String?;
      return (success, data, error);
    } catch (_) {
      return (false, null, 'Invalid JSON');
    }
  }
}
