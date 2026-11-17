import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/live_class_model.dart';
import 'api_service.dart';
import 'auth_service.dart';

class LiveClassService {
  Future<List<LiveClass>> fetchLiveClasses({String? courseId, String? scope}) async {
    final token = await AuthService.getToken();

    String url = '${ApiConfig.baseUrl}${ApiConfig.liveClassesEndpoint}';
    Map<String, String> queryParams = {};
    if (courseId != null) queryParams['courseId'] = courseId;
    if (scope != null) queryParams['scope'] = scope;

    if (queryParams.isNotEmpty) {
      url += '?' + Uri(queryParameters: queryParams).query;
    }

    final response = await http.get(
      Uri.parse(url),
      headers: ApiService.buildHeaders(token: token, includeJsonContentType: false),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return (data['liveClasses'] as List)
            .map((json) => LiveClass.fromJson(json))
            .toList();
      }
    }
    throw Exception(json.decode(response.body)['message'] ?? 'Failed to fetch live classes');
  }

  Future<Map<String, dynamic>> getJoinConfig(String classId) async {
    final token = await AuthService.getToken();

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.liveClassesEndpoint}/$classId/join-config'),
      headers: ApiService.buildHeaders(token: token, includeJsonContentType: false),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return data['config'];
      }
    }
    throw Exception(json.decode(response.body)['message'] ?? 'Failed to get join config');
  }

  Future<bool> markAttendance(String classId) async {
    final token = await AuthService.getToken();

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.liveClassesEndpoint}/$classId/attendance'),
      headers: ApiService.buildHeaders(token: token, includeJsonContentType: false),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return true;
    }
    return false;
  }

  Future<bool> createLiveClass(Map<String, dynamic> classData) async {
    final token = await AuthService.getToken();

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.liveClassesEndpoint}'),
      headers: ApiService.buildHeaders(token: token),
      body: json.encode(classData),
    );

    if (response.statusCode == 201) {
      return true;
    }
    throw Exception(json.decode(response.body)['message'] ?? 'Failed to create live class');
  }

  Future<bool> deleteLiveClass(String classId) async {
    final token = await AuthService.getToken();

    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.liveClassesEndpoint}/$classId'),
      headers: ApiService.buildHeaders(token: token, includeJsonContentType: false),
    );

    if (response.statusCode == 200) {
      return true;
    }
    throw Exception(json.decode(response.body)['message'] ?? 'Failed to delete live class');
  }
}
