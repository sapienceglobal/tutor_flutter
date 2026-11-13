import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/certificate_model.dart';
import 'auth_service.dart';

class CertificateService {
  Future<List<Certificate>> fetchMyCertificates() async {
    final token = await AuthService.getToken();
    final apiKey = await AuthService.getApiKey();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/certificates/my-certificates'),
      headers: {
        'Authorization': 'Bearer $token',
        'x-api-key': apiKey ?? '',
      },
    );

    if (response.statusCode == 200) {
      final data = ApiConfig.normalizeMediaUrlsDeep(json.decode(response.body));
      if (data['success'] && data['data'] != null) {
        return (data['data'] as List)
            .map((json) => Certificate.fromJson(json))
            .toList();
      }
    }
    throw Exception('Failed to fetch certificates');
  }

  Future<List<InProgressCourse>> fetchInProgressCourses() async {
    final token = await AuthService.getToken();
    final apiKey = await AuthService.getApiKey();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/courses/in-progress'),
      headers: {
        'Authorization': 'Bearer $token',
        'x-api-key': apiKey ?? '',
      },
    );

    if (response.statusCode == 200) {
      final data = ApiConfig.normalizeMediaUrlsDeep(json.decode(response.body));
      if (data['courses'] != null) {
        return (data['courses'] as List)
            .map((json) => InProgressCourse.fromJson(json))
            .where((c) => c.progress < 100)
            .toList();
      }
    }
    return []; // Optional feature, handle gracefully
  }
}
