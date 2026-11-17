import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'api_service.dart';
import 'auth_service.dart';

class ReportService {
  Future<Map<String, dynamic>> getStudentSummary() async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/reports/student/summary'),
      headers: ApiService.buildHeaders(token: token, includeJsonContentType: false),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load analytics');
  }

  Future<Map<String, dynamic>> getTutorReportsSummary() async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/tutor/dashboard/reports/summary'),
      headers: ApiService.buildHeaders(token: token, includeJsonContentType: false),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load tutor reports');
  }
}
