import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import 'api_client.dart';

/// Flag for whether an API requires auth token.
/// - [public]: no token (e.g. artist profile, health).
/// - [private]: use token (e.g. follow artist, user profile).
enum ApiVisibility {
  public,
  private,
}

/// Base class for all API calls. Logs each request as cURL and response.
/// Subclasses (e.g. [MusicApi]) call [execute] with [ApiVisibility.public] or
/// [ApiVisibility.private] per endpoint. Do not use [BaseApi] directly; use a subclass.
/// See [FLUTTER_API_GUIDE.md].
class BaseApi {
  BaseApi({
    required this.baseUrl,
    this.authToken,
    this.timeout = const Duration(seconds: 15),
    this.debugPrintRequest = true,
  }) : _client = ApiClient(
          baseUrl: baseUrl,
          authToken: authToken,
          timeout: timeout,
        );

  final String baseUrl;
  final String? authToken;
  final Duration timeout;
  final bool debugPrintRequest;
  final ApiClient _client;

  String get _apiBase => '$baseUrl/${ApiConstants.apiVersion}';

  Map<String, String> _headers({required bool useAuth}) {
    final map = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (useAuth && authToken != null && authToken!.isNotEmpty) {
      map['Authorization'] = 'Bearer $authToken';
    }
    return map;
  }

  /// Executes request. [visibility]: [ApiVisibility.public] = no token,
  /// [ApiVisibility.private] = use token. Logs cURL and response when [debugPrintRequest] is true.
  /// Subclasses use this for every API call.
  Future<http.Response> execute(
    String method,
    String path, {
    Map<String, String>? queryParams,
    Map<String, dynamic>? body,
    ApiVisibility visibility = ApiVisibility.public,
  }) async {
    final useAuth = visibility == ApiVisibility.private;
    var uri = Uri.parse('$_apiBase/$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }
    final headers = _headers(useAuth: useAuth);
    final bodyStr = body != null ? jsonEncode(body) : null;

    if (debugPrintRequest) {
      _printCurl(method, uri.toString(), headers, bodyStr);
    }

    Future<http.Response> future;
    switch (method.toUpperCase()) {
      case 'GET':
        future = _client.get(path, queryParams: queryParams, useAuth: useAuth);
        break;
      case 'POST':
        future = _client.post(path, body: body, useAuth: useAuth);
        break;
      case 'PUT':
        future = _client.put(path, body: body, useAuth: useAuth);
        break;
      case 'DELETE':
        future = _client.delete(path, useAuth: useAuth);
        break;
      default:
        future = _client.get(path, queryParams: queryParams, useAuth: useAuth);
    }

    final response = await future;
    if (debugPrintRequest) {
      _printResponse(response);
    }
    return response;
  }

  void _printCurl(String method, String url, Map<String, String> headers, String? bodyStr) {
    // Print one line at a time so the full curl is visible (debugPrint truncates).
    final parts = <String>[
      "curl -X $method '$url'",
      ...headers.entries.map((e) => "-H '${e.key}: ${e.value}'"),
    ];
    if (bodyStr != null && bodyStr.isNotEmpty) {
      final escaped = bodyStr.replaceAll("'", r"'\''");
      parts.add("-d '$escaped'");
    }
    for (var i = 0; i < parts.length; i++) {
      final line = parts[i] + (i < parts.length - 1 ? ' \\' : '');
      // ignore: avoid_print
      print('flutter: $line');
    }
  }

  void _printResponse(http.Response response) {
    // ignore: avoid_print
    print('flutter: Response: ${response.statusCode}');
    final bodyStr = response.body.isEmpty
        ? '(empty)'
        : _formatBody(response.body);
    for (final line in bodyStr.split('\n')) {
      // ignore: avoid_print
      print('flutter: $line');
    }
  }

  String _formatBody(String body) {
    try {
      final decoded = jsonDecode(body);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return body;
    }
  }
}
