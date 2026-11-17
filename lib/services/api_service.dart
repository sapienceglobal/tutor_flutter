import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  static const String apiKey = "bumpicare_flutter_2025_secure_key_xyz123abc456";

  static String? _workspaceType;
  static String? _workspaceInstituteId;
  static String? _workspaceTutorId;

  static void setWorkspaceHeaders({
    required String type,
    String? instituteId,
    String? tutorId,
  }) {
    _workspaceType = type;
    _workspaceInstituteId = (type == 'institute' && instituteId != null && instituteId.isNotEmpty)
        ? instituteId
        : null;
    _workspaceTutorId = (type == 'private_tutor' && tutorId != null && tutorId.isNotEmpty)
        ? tutorId
        : null;
  }

  static void clearWorkspaceHeaders() {
    _workspaceType = null;
    _workspaceInstituteId = null;
    _workspaceTutorId = null;
  }

  static Map<String, String> get workspaceHeaders {
    final map = <String, String>{};
    if (_workspaceType != null && _workspaceType!.isNotEmpty) {
      map['X-Workspace-Type'] = _workspaceType!;
    }
    if (_workspaceInstituteId != null && _workspaceInstituteId!.isNotEmpty) {
      map['X-Institute-Id'] = _workspaceInstituteId!;
    }
    if (_workspaceTutorId != null && _workspaceTutorId!.isNotEmpty) {
      map['X-Tutor-Id'] = _workspaceTutorId!;
    }
    return map;
  }

  static Map<String, String> buildHeaders({
    String? token,
    bool includeJsonContentType = true,
  }) {
    final headers = <String, String>{
      'x-api-key': apiKey,
      'x-client-platform': 'mobile',
      ...workspaceHeaders,
    };

    if (includeJsonContentType) {
      headers['Content-Type'] = 'application/json';
    }

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // Helper method to get headers
  static Map<String, String> _getHeaders({String? token}) =>
      buildHeaders(token: token);

  // Common wrapper to handle logs and exceptions
  static Future<Map<String, dynamic>> _call(Future<http.Response> Function() call) async {
    try {
      final response = await call();
      return _handleResponse(response);
    } catch (e) {
      print("Network error: $e");
      if (e is ApiException) rethrow;
      throw Exception('Network error: $e');
    }
  }

  // GET
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    String? token,
    Map<String, String>? queryParams,
  }) async {
    String url = '${ApiConfig.baseUrl}$endpoint';
    if (queryParams != null && queryParams.isNotEmpty) {
      final query = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      url = '$url?$query';
    }
    return _call(() => http.get(Uri.parse(url), headers: _getHeaders(token: token)));
  }

  // POST
  static Future<Map<String, dynamic>> post(
    String endpoint, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    return _call(() => http.post(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: _getHeaders(token: token),
      body: jsonEncode(body),
    ));
  }

  // PUT 
  static Future<Map<String, dynamic>> put(
    String endpoint, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    return _call(() => http.put(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: _getHeaders(token: token),
      body: jsonEncode(body),
    ));
  }

  // PATCH
  static Future<Map<String, dynamic>> patch(
    String endpoint, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    return _call(() => http.patch(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: _getHeaders(token: token),
      body: jsonEncode(body),
    ));
  }

  // DELETE
  static Future<Map<String, dynamic>> delete(
    String endpoint, {
    String? token,
  }) async {
    return _call(() => http.delete(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: _getHeaders(token: token),
    ));
  }

  // RESPONSE HANDLER
  static Map<String, dynamic> _handleResponse(http.Response response) {
    final rawData = jsonDecode(response.body);
    final data = ApiConfig.normalizeMediaUrlsDeep(rawData) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw ApiException(
        message: data['message'] ?? 'Something went wrong',
        featureLocked: data['featureLocked'] == true,
        creditExhausted: data['creditExhausted'] == true,
        code: data['code']?.toString(),
        statusCode: response.statusCode,
        data: data,
      );
    }
  }
}

class ApiException implements Exception {
  final String message;
  final bool featureLocked;
  final bool creditExhausted;
  final String? code;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    this.featureLocked = false,
    this.creditExhausted = false,
    this.code,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => message;
}
