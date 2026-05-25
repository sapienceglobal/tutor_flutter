import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  static const String apiKey = "bumpicare_flutter_2025_secure_key_xyz123abc456";

  // Helper method to get headers
  static Map<String, String> _getHeaders({String? token}) {
    final headers = {'Content-Type': 'application/json', 'x-api-key': apiKey};

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

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
    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw ApiException(
        message: data['message'] ?? 'Something went wrong',
        featureLocked: data['featureLocked'] == true,
        creditExhausted: data['creditExhausted'] == true,
        data: data,
      );
    }
  }
}

class ApiException implements Exception {
  final String message;
  final bool featureLocked;
  final bool creditExhausted;
  final dynamic data;

  ApiException({
    required this.message,
    this.featureLocked = false,
    this.creditExhausted = false,
    this.data,
  });

  @override
  String toString() => message;
}
